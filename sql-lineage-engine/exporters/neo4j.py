from neo4j import GraphDatabase
import sys
import time
from config.settings import settings

# GSP 关系类型到 Neo4j 关系类型的映射
RELATION_TYPE_MAP = {
    "fdd": "DERIVES_TO",      # 直接数据流 (SELECT)
    "fdr": "FILTERS",         # 间接数据流 (WHERE/HAVING/GROUP BY)
    "join": "JOINS",          # JOIN 条件
    "call": "CALLS",          # 函数调用
    "er": "REFERENCES",       # 实体关系
    "CASE_WHEN": "CASE_WHEN", # Case When
}

# 所有血缘关系类型
ALL_LINEAGE_RELATION_TYPES = ["DERIVES_TO", "FILTERS", "JOINS", "GROUPS", "ORDERS", "CALLS", "REFERENCES", "CASE_WHEN"]


class Neo4jClient:
    def __init__(self, uri=None, username=None, password=None):
        self.uri = uri or settings.NEO4J_URI
        self.username = username or settings.NEO4J_USERNAME
        self.password = password or settings.NEO4J_PASSWORD
        self.driver = GraphDatabase.driver(self.uri, auth=(self.username, self.password))

    def close(self):
        self.driver.close()
    
    def ensure_indexes(self):
        """
        确保所有必要的索引已创建。
        应在首次连接或数据导入前调用。
        索引会显著提升查询性能。
        """
        index_statements = [
            # Table 节点唯一性约束（MERGE 操作会利用约束快速定位）
            "CREATE CONSTRAINT constraint_table_name IF NOT EXISTS FOR (t:Table) REQUIRE t.name IS UNIQUE",
            # Column 节点复合唯一性约束 (name + table)
            "CREATE CONSTRAINT constraint_column_name_table IF NOT EXISTS FOR (c:Column) REQUIRE (c.name, c.table) IS UNIQUE",
            # Column 单字段索引（用于按 table 查询）
            "CREATE INDEX idx_column_table IF NOT EXISTS FOR (c:Column) ON (c.table)",
            # LineageVersion 节点唯一性约束
            "CREATE CONSTRAINT constraint_version_id IF NOT EXISTS FOR (v:LineageVersion) REQUIRE v.id IS UNIQUE",
            "CREATE INDEX idx_version_created IF NOT EXISTS FOR (v:LineageVersion) ON (v.createdAt)",
        ]
        
        with self.driver.session() as session:
            for stmt in index_statements:
                try:
                    session.run(stmt)
                except Exception as e:
                    # 索引可能已存在，忽略错误
                    print(f"  索引创建跳过 (可能已存在): {e}")
            print("✓ Neo4j 索引检查完成")
    
    # ================================
    # 版本管理相关方法
    # ================================
    
    def create_lineage_version(self, version_id: str, repo_id: str = None, 
                             commit_sha: str = None, ref: str = None,
                             source_directory: str = None, description: str = None):
        """
        创建血缘版本节点。
        
        Args:
            version_id: 版本标识
            repo_id: 仓库 ID
            commit_sha: 提交 SHA
            ref: Git 引用
            source_directory: 来源目录
            description: 描述
        """
        with self.driver.session() as session:
            session.run(
                """
                MERGE (v:LineageVersion {id: $version_id})
                SET v.createdAt = datetime(),
                    v.repoId = $repo_id,
                    v.commitSha = $commit_sha,
                    v.ref = $ref,
                    v.sourceDirectory = $source_directory,
                    v.description = $description
                """,
                version_id=version_id,
                repo_id=repo_id,
                commit_sha=commit_sha,
                ref=ref,
                source_directory=source_directory,
                description=description
            )
    
    def get_lineage_versions(self):
        """
        获取所有血缘版本列表。
        """
        with self.driver.session() as session:
            result = session.run(
                """
                MATCH (v:LineageVersion)
                RETURN v.id as id, v.createdAt as createdAt, 
                       v.sourceDirectory as sourceDirectory, v.description as description
                ORDER BY v.createdAt DESC
                """
            )
            return [dict(r) for r in result]

    def clear_all_lineage_data(self):
        """
        清除所有血缘相关数据，包括：
        - Table 节点
        - Column 节点
        - LineageVersion 节点
        - 所有血缘关系边
        
        使用批量删除以避免大数据量时事务超时
        """
        print("正在清除血缘数据...")
        with self.driver.session() as session:
            # 使用 CALL IN TRANSACTIONS 批量删除，避免大数据量时内存溢出
            # 每批删除 10000 个节点/关系
            
            # 1. 批量删除 Column 节点（会自动删除相关关系）
            session.run("""
                CALL {
                    MATCH (c:Column)
                    RETURN c
                    LIMIT 10000
                }
                CALL {
                    WITH c
                    DETACH DELETE c
                } IN TRANSACTIONS OF 10000 ROWS
            """)
            print("  - Column 节点已清除")
            
            # 2. 批量删除 Table 节点
            session.run("""
                CALL {
                    MATCH (t:Table)
                    RETURN t
                    LIMIT 10000
                }
                CALL {
                    WITH t
                    DETACH DELETE t
                } IN TRANSACTIONS OF 10000 ROWS
            """)
            print("  - Table 节点已清除")
            
            # 3. 删除 LineageVersion 节点
            session.run("MATCH (v:LineageVersion) DETACH DELETE v")
            print("  - LineageVersion 节点已清除")
            
            print("✓ 血缘数据清除完成")

    def clear_lineage_by_repo_files(self, repo_id: str, files: list):
        """
        清除指定仓库和文件列表相关的旧血缘关系。
        仅删除该仓库下，sourceFiles 包含在 files 列表中的关系。
        """
        if not repo_id or not files:
            return

        print(f"正在清除仓库 {repo_id} 中 {len(files)} 个文件的旧血缘数据...")
        with self.driver.session() as session:
            # 批量删除关系
            # 逻辑：查找具有指定 repoId 且 sourceFiles 与当前文件列表有交集的关系
            # 注意：这里假设关系上的 sourceFiles 是相对路径，files 传入的也必须是相对路径
            
            # 由于 Cypher 列表操作性能，分批处理文件列表
            batch_size = 1000
            for i in range(0, len(files), batch_size):
                file_batch = files[i:i + batch_size]
                
                # 删除 Column 级别的关系
                session.run("""
                    MATCH ()-[r]->()
                    WHERE r.repoId = $repoId
                    AND ANY(f IN r.sourceFiles WHERE f IN $files)
                    DELETE r
                """, repoId=repo_id, files=file_batch)
                
            print(f"  - 相关血缘关系已清除")

    def create_lineage(self, source_table: str, target_table: str):
        """
        Create a lineage relationship between two tables.
        """
        # 统一转换为大写
        source_table = (source_table or "").upper()
        target_table = (target_table or "").upper()
        
        with self.driver.session() as session:
            session.execute_write(self._create_and_link_tables, source_table, target_table)

    @staticmethod
    def _create_and_link_tables(tx, source_name, target_name):
        query = (
            "MERGE (s:Table {name: $source_name}) "
            "MERGE (t:Table {name: $target_name}) "
            "MERGE (s)-[:DERIVES_TO]->(t)"
        )
        tx.run(query, source_name=source_name, target_name=target_name)

    def create_lineage_batch(self, relationships: list):
        """
        Batch create table-level lineage.
        relationships: list of dicts with keys: source, target
        """
        if not relationships:
            return
            
        with self.driver.session() as session:
            # 优化：增加批次大小到 2000
            batch_size = 2000
            total = len(relationships)
            for i in range(0, total, batch_size):
                 chunk = relationships[i:i + batch_size]
                 try:
                     session.execute_write(self._create_tables_batch, chunk)
                 except Exception as e:
                     print(f"\n    Error in table batch {i//batch_size}: {e}")

                 # Progress Log - 每 5000 条或最后一批打印一次
                 processed = min(i + batch_size, total)
                 if processed % 5000 == 0 or processed == total:
                     sys.stdout.write(f"\r    Processed {processed}/{total} table relationships...")
                     sys.stdout.flush()
            print("") # Newline after done

    @staticmethod
    def _create_tables_batch(tx, relationships):
         # Normalize
         normalized = []
         for r in relationships:
             s = (r.get("source") or "").upper()
             t = (r.get("target") or "").upper()
             if s and t:
                 normalized.append({"source": s, "target": t})
         
         if not normalized:
             return

         query = (
             "UNWIND $batch as rel "
             "MERGE (s:Table {name: rel.source}) "
             "MERGE (t:Table {name: rel.target}) "
             "MERGE (s)-[:DERIVES_TO]->(t)"
         )
         tx.run(query, batch=normalized)

    def create_column_lineage(self, dependencies: list):
        """
        Create lineage relationships between columns in batch.
        dependencies: list of dicts with keys: source_table, source_column, target_table, target_column
        """
        if not dependencies:
            return
        
        # 分批处理以避免事务超时
        batch_size = 2000
        total = len(dependencies)
        
        with self.driver.session() as session:
            for i in range(0, total, batch_size):
                chunk = dependencies[i:i + batch_size]
                try:
                    session.execute_write(self._create_and_link_columns_batch, chunk)
                except Exception as e:
                    print(f"\n    Error in column lineage batch {i//batch_size}: {e}")
                
                # Progress Log
                processed = min(i + batch_size, total)
                if processed % 5000 == 0 or processed == total:
                    sys.stdout.write(f"\r    Processed {processed}/{total} column dependencies...")
                    sys.stdout.flush()
            
            if total > 0:
                print("")

    @staticmethod
    def _create_and_link_columns_batch(tx, dependencies):
        # 预处理：统一转换为大写
        normalized_deps = [{
            "source_table": (d.get("source_table") or "").upper(),
            "source_column": (d.get("source_column") or "").upper(),
            "target_table": (d.get("target_table") or "").upper(),
            "target_column": (d.get("target_column") or "").upper()
        } for d in dependencies]
        
        query = (
            "UNWIND $batch AS dep "
            "MERGE (st:Table {name: dep.source_table}) "
            "MERGE (tt:Table {name: dep.target_table}) "
            "MERGE (sc:Column {name: dep.source_column, table: dep.source_table}) "
            "MERGE (sc)-[:BELONGS_TO]->(st) "
            "MERGE (tc:Column {name: dep.target_column, table: dep.target_table}) "
            "MERGE (tc)-[:BELONGS_TO]->(tt) "
            "MERGE (sc)-[:DERIVES_TO]->(tc)"
        )
        tx.run(query, batch=normalized_deps)
    
    def create_column_lineage_v2(self, dependencies: list, version: str, repo_id: str = None):
        """
        创建带版本的字段级血缘关系 (Batch Optimized).
        Args:
            dependencies: 依赖列表
            version: 版本ID
            repo_id: 仓库ID (用于隔离和清除)
        """
        if not dependencies:
            return
        
        # Split into Direct and Indirect
        direct_items = []
        indirect_items = []
        
        for dep in dependencies:
             # Normalize
            source_table = (dep.get("source_table") or "").upper()
            source_column = (dep.get("source_column") or "").upper()
            target_table = (dep.get("target_table") or "").upper()
            target_column = (dep.get("target_column") or "").upper()
            
            if not source_table or not source_column or not target_table:
                continue

            item = {
                "source_table": source_table,
                "source_column": source_column,
                "target_table": target_table,
                "target_column": target_column,
                "source_file": dep.get("source_file"),
                "dependency_type": dep.get("dependency_type", "fdd"),
                "snippet": dep.get("snippet"),
                "version": version,
                "repo_id": repo_id
            }
            
            # Neo4j Relation Type lookup
            item["neo4j_rel_type"] = RELATION_TYPE_MAP.get(item["dependency_type"], "DERIVES_TO")

            if target_column in ["*", "", None]:
                 indirect_items.append(item)
            else:
                 direct_items.append(item)
        
        # Helper to process batches by type
        def process_by_type(items, batch_func):
            # Group by neo4j_rel_type
            grouped = {}
            for item in items:
                rtype = item["neo4j_rel_type"]
                if rtype not in grouped:
                    grouped[rtype] = []
                grouped[rtype].append(item)
            
            # 增加批次大小到 2000 以提升性能
            batch_size = 2000
            for rtype, group_items in grouped.items():
                total = len(group_items)
                print(f"  - Processing items of type {rtype} (Total: {total})...")
                
                # 复用同一个 session 以减少连接开销
                with self.driver.session() as session:
                    for i in range(0, total, batch_size):
                        chunk = group_items[i:i + batch_size]
                        # Execute with specific method
                        try:
                            session.execute_write(batch_func, chunk, rtype)
                        except Exception as e:
                            print(f"\n    Error in batch {i//batch_size}: {e}")
                        
                        # Progress Log - 每 5000 条或最后一批打印一次
                        processed = min(i + batch_size, total)
                        if processed % 5000 == 0 or processed == total:
                            sys.stdout.write(f"\r    Processed {processed}/{total}...")
                            sys.stdout.flush()
                
                print(" Done.")

        # 1. Process Direct Lineage
        if direct_items:
            print(f"Processing {len(direct_items)} direct column dependencies...", flush=True)
            process_by_type(direct_items, self._create_direct_column_batch_safe)

        # 2. Process Indirect Lineage
        if indirect_items:
            print(f"Processing {len(indirect_items)} indirect column dependencies...", flush=True)
            process_by_type(indirect_items, self._create_indirect_column_batch_safe)

    @staticmethod
    def _create_direct_column_batch_safe(tx, batch, rel_type):
        # Safe version where rel_type is constant for the batch
        query = f"""
        UNWIND $batch AS item
        MERGE (st:Table {{name: item.source_table}})
        MERGE (tt:Table {{name: item.target_table}})
        MERGE (sc:Column {{name: item.source_column, table: item.source_table}})
        MERGE (sc)-[:BELONGS_TO]->(st)
        MERGE (tc:Column {{name: item.target_column, table: item.target_table}})
        MERGE (tc)-[:BELONGS_TO]->(tt)
        MERGE (sc)-[r:{rel_type}]->(tc)
        SET r.version = item.version,
            r.repoId = item.repo_id,
            r.type = item.dependency_type,
            r.isIndirect = false,
            r.snippet = CASE WHEN item.snippet IS NOT NULL THEN item.snippet ELSE r.snippet END,
            r.createdAt = CASE WHEN r.createdAt IS NULL THEN datetime() ELSE r.createdAt END,
            r.sourceFiles = CASE 
                WHEN r.sourceFiles IS NULL THEN [item.source_file]
                WHEN item.source_file IS NULL THEN r.sourceFiles
                WHEN NOT item.source_file IN r.sourceFiles THEN r.sourceFiles + [item.source_file]
                ELSE r.sourceFiles
            END
        """
        tx.run(query, batch=batch)

    @staticmethod
    def _create_indirect_column_batch_safe(tx, batch, rel_type):
        query = f"""
        UNWIND $batch AS item
        MERGE (st:Table {{name: item.source_table}})
        MERGE (tt:Table {{name: item.target_table}})
        MERGE (sc:Column {{name: item.source_column, table: item.source_table}})
        MERGE (sc)-[:BELONGS_TO]->(st)
        MERGE (sc)-[r:{rel_type}]->(tt)
        SET r.version = item.version,
            r.repoId = item.repo_id,
            r.type = item.dependency_type,
            r.isIndirect = true,
            r.snippet = CASE WHEN item.snippet IS NOT NULL THEN item.snippet ELSE r.snippet END,
            r.createdAt = CASE WHEN r.createdAt IS NULL THEN datetime() ELSE r.createdAt END,
            r.sourceFiles = CASE 
                WHEN r.sourceFiles IS NULL THEN [item.source_file]
                WHEN item.source_file IS NULL THEN r.sourceFiles
                WHEN NOT item.source_file IN r.sourceFiles THEN r.sourceFiles + [item.source_file]
                ELSE r.sourceFiles
            END
        """
        tx.run(query, batch=batch)

    def get_column_upstream(self, table: str, column: str):
        """
        Trace upstream sources for a column.
        """
        with self.driver.session() as session:
            result = session.run(
                "MATCH (sc:Column)-[:DERIVES_TO*]->(tc:Column {name: $col, table: $table}) "
                "RETURN DISTINCT sc.name as column, sc.table as table",
                col=column, table=table
            )
            return [{"table": r["table"], "column": r["column"]} for r in result]

    def get_column_downstream(self, table: str, column: str):
        """
        Trace downstream impacts of a column.
        """
        with self.driver.session() as session:
            result = session.run(
                "MATCH (sc:Column {name: $col, table: $table})-[:DERIVES_TO*]->(tc:Column) "
                "RETURN DISTINCT tc.name as column, tc.table as table",
                col=column, table=table
            )
            return [{"table": r["table"], "column": r["column"]} for r in result]

    def create_report_lineage(self, item: dict):
        """
        Create lineage for report/indicator.
        """
        with self.driver.session() as session:
            if item["type"] == "indicator":
                session.execute_write(self._create_indicator, item)
            elif item["type"] == "chart_usage":
                session.execute_write(self._create_report_usage, item)

    @staticmethod
    def _create_indicator(tx, item):
        # Create Indicator node
        tx.run(
            "MERGE (i:Indicator {name: $name}) "
            "SET i.logic = $logic, i.report = $report",
            name=item["name"], logic=item.get("logic"), report=item["report"]
        )
        # Link to Source Column
        if item.get("source_table") and item.get("source_column"):
            tx.run(
                "MATCH (c:Column {name: $col, table: $table}) "
                "MATCH (i:Indicator {name: $name}) "
                "MERGE (c)-[:CONTRIBUTES_TO]->(i)",
                col=item["source_column"], table=item["source_table"], name=item["name"]
            )

    @staticmethod
    def _create_report_usage(tx, item):
        # Create Report node
        tx.run("MERGE (r:Report {name: $name})", name=item["report"])
        
        # Link Source Column to Report
        if item.get("source_table") and item.get("source_column"):
            tx.run(
                "MATCH (c:Column {name: $col, table: $table}) "
                "MATCH (r:Report {name: $report}) "
                "MERGE (c)-[:USED_IN]->(r)",
                col=item["source_column"], table=item["source_table"], report=item["report"]
            )

    def query_upstream(self, table_name: str):
        """
        Find upstream tables for a given table.
        """
        with self.driver.session() as session:
            result = session.run(
                "MATCH (s:Table)-[:DERIVES_TO*]->(t:Table {name: $name}) RETURN DISTINCT s.name",
                name=table_name
            )
            return [record["s.name"] for record in result]

    def query_downstream(self, table_name: str):
        """
        Find downstream tables for a given table.
        """
        with self.driver.session() as session:
            result = session.run(
                "MATCH (s:Table {name: $name})-[:DERIVES_TO*]->(t:Table) RETURN DISTINCT t.name",
                name=table_name
            )
            return [record["t.name"] for record in result]

    def get_graph_data(self, start_node_name: str, depth: int = 2):
        """
        Get graph data (nodes and edges) for visualization starting from a node.
        """
        with self.driver.session() as session:
            # Query for both Table and Column nodes
            query = (
                f"MATCH path = (n {{name: $name}})-[:DERIVES_TO|CASE_WHEN|BELONGS_TO*1..{depth}]-(m) "
                "RETURN path"
            )
            result = session.run(query, name=start_node_name)
            
            nodes = []
            edges = []
            seen_nodes = set()
            seen_edges = set()
            
            for record in result:
                path = record["path"]
                for node in path.nodes:
                    if node.element_id not in seen_nodes:
                        nodes.append({
                            "id": node.element_id,
                            "labels": list(node.labels),
                            "properties": dict(node)
                        })
                        seen_nodes.add(node.element_id)
                for rel in path.relationships:
                    if rel.element_id not in seen_edges:
                        edges.append({
                            "id": rel.element_id,
                            "source": rel.start_node.element_id,
                            "target": rel.end_node.element_id,
                            "type": rel.type,
                            "properties": dict(rel)
                        })
                        seen_edges.add(rel.element_id)
                        
            return {"nodes": nodes, "edges": edges}
    
    # ================================
    # 影响分析相关方法
    # ================================
    
    def get_impact_analysis(self, table: str, column: str, version: str = None, 
                           depth: int = 5, relation_types: list = None):
        """
        获取影响分析结果 - 返回所有类型的下游依赖。
        
        Args:
            table: 表名
            column: 字段名
            version: 可选，指定版本
            depth: 追溯深度，默认 5
            relation_types: 可选，指定关系类型列表，默认所有类型
        
        Returns:
            包含 nodes 和 edges 的字典
        """
        if relation_types is None:
            relation_types = ALL_LINEAGE_RELATION_TYPES
        
        # 构建关系类型字符串
        rel_types_str = "|".join(relation_types)
        
        with self.driver.session() as session:
            # 构建 Cypher 查询
            version_filter = ""
            if version:
                version_filter = f"WHERE ALL(rel IN relationships(path) WHERE rel.version = $version)"
            
            query = f"""
                MATCH path = (c:Column {{name: $column, table: $table}})-[:{rel_types_str}*1..{depth}]->(downstream:Column)
                {version_filter}
                RETURN path
            """
            
            result = session.run(query, column=column, table=table, version=version)
            
            nodes = []
            edges = []
            seen_nodes = set()
            seen_edges = set()
            
            for record in result:
                path = record["path"]
                for node in path.nodes:
                    if node.element_id not in seen_nodes:
                        nodes.append({
                            "id": node.element_id,
                            "labels": list(node.labels),
                            "properties": dict(node)
                        })
                        seen_nodes.add(node.element_id)
                for rel in path.relationships:
                    if rel.element_id not in seen_edges:
                        edges.append({
                            "id": rel.element_id,
                            "source": rel.start_node.element_id,
                            "target": rel.end_node.element_id,
                            "type": rel.type,
                            "properties": dict(rel)
                        })
                        seen_edges.add(rel.element_id)
            
            return {"nodes": nodes, "edges": edges}
    
    def get_column_upstream_v2(self, table: str, column: str, version: str = None,
                               only_fdd: bool = True):
        """
        追溯字段的上游来源（血缘追溯）。
        
        Args:
            table: 表名
            column: 字段名
            version: 可选，指定版本
            only_fdd: 是否只查询直接数据流 (fdd)，默认 True
        """
        rel_types = ["DERIVES_TO", "CASE_WHEN"] if only_fdd else ALL_LINEAGE_RELATION_TYPES
        rel_types_str = "|".join(rel_types)
        
        with self.driver.session() as session:
            version_filter = ""
            if version:
                version_filter = "AND r.version = $version"
            
            query = f"""
                MATCH (sc:Column)-[r:{rel_types_str}*]->(tc:Column {{name: $col, table: $table}})
                {version_filter}
                RETURN DISTINCT sc.name as column, sc.table as table, 
                       [rel in r | type(rel)] as relationTypes
            """
            
            result = session.run(query, col=column, table=table, version=version)
            return [dict(r) for r in result]
    
    def get_column_downstream_v2(self, table: str, column: str, version: str = None,
                                 only_fdd: bool = False):
        """
        追溯字段的下游影响（影响分析）。
        
        Args:
            table: 表名
            column: 字段名
            version: 可选，指定版本
            only_fdd: 是否只查询直接数据流 (fdd)，默认 False（影响分析需要所有类型）
        """
        rel_types = ["DERIVES_TO", "CASE_WHEN"] if only_fdd else ALL_LINEAGE_RELATION_TYPES
        rel_types_str = "|".join(rel_types)
        
        with self.driver.session() as session:
            version_filter = ""
            if version:
                version_filter = "AND ALL(rel in r WHERE rel.version = $version)"
            
            query = f"""
                MATCH (sc:Column {{name: $col, table: $table}})-[r:{rel_types_str}*]->(tc:Column)
                {version_filter}
                RETURN DISTINCT tc.name as column, tc.table as table,
                       [rel in r | type(rel)] as relationTypes
            """
            
            result = session.run(query, col=column, table=table, version=version)
            return [dict(r) for r in result]

