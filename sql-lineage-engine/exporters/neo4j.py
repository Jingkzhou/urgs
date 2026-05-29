from neo4j import GraphDatabase
import sys
import time
from config.settings import settings
from utils.lineage_identity import (
    normalize_sql_for_hash,
    parser_statement_uid,
    relation_uid,
    scoped_statement_uid,
    statement_hash,
)

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

    @staticmethod
    def _normalize_sql_for_statement_hash(sql: str) -> str:
        return normalize_sql_for_hash(sql)

    @classmethod
    def _statement_hash(cls, sql: str) -> str:
        return statement_hash(sql)

    @staticmethod
    def _first_value(values):
        if isinstance(values, list):
            return values[0] if values else None
        return values

    def _statement_identity_for_item(self, item: dict, version: str = None, repo_id: str = None) -> tuple[str, str]:
        snippet = item.get("snippet") or item.get("sql")
        statement_index = item.get("statementIndex")
        if statement_index is None:
            statement_index = item.get("statement_index")
        source_file = (
            item.get("source_file")
            or item.get("sourceFile")
            or self._first_value(item.get("source_files"))
            or self._first_value(item.get("sourceFiles"))
        )
        parser_uid = (
            item.get("parserStatementUid")
            or item.get("parser_statement_uid")
            or item.get("statementUid")
            or item.get("statement_uid")
            or parser_statement_uid(source_file, statement_index or 0, snippet or "")
        )
        return parser_uid, scoped_statement_uid(version, repo_id, parser_uid)
    
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
            "CREATE CONSTRAINT constraint_sql_statement_uid IF NOT EXISTS FOR (s:SqlStatement) REQUIRE s.statementUid IS UNIQUE",
            "CREATE CONSTRAINT constraint_lineage_fact_uid IF NOT EXISTS FOR (f:LineageFact) REQUIRE f.relationUid IS UNIQUE",
            "CREATE INDEX idx_sql_statement_version IF NOT EXISTS FOR (s:SqlStatement) ON (s.version)",
            "CREATE INDEX idx_lineage_fact_statement_uid IF NOT EXISTS FOR (f:LineageFact) ON (f.statementUid)",
            "CREATE INDEX idx_lineage_fact_version IF NOT EXISTS FOR (f:LineageFact) ON (f.version)",
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
            session.run("""
                MATCH (f:LineageFact)
                DETACH DELETE f
            """)
            session.run("""
                MATCH (s:SqlStatement)
                DETACH DELETE s
            """)
            
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
        智能删除逻辑：
        - 从关系的 sourceFiles 中移除当前文件
        - 只有当 sourceFiles 为空时才删除整条关系
        - 如果还有其他文件，则保留关系并更新 sourceFiles
        """
        if not repo_id or not files:
            return

        print(f"正在清除仓库 {repo_id} 中 {len(files)} 个文件的旧血缘数据...")
        with self.driver.session() as session:
            # 由于 Cypher 列表操作性能，分批处理文件列表
            batch_size = 1000
            for i in range(0, len(files), batch_size):
                file_batch = files[i:i + batch_size]
                session.run("""
                    MATCH (f:LineageFact)
                    WHERE f.repoId = $repoId
                      AND ANY(file IN coalesce(f.sourceFiles, []) WHERE file IN $files)
                    DETACH DELETE f
                """, repoId=repo_id, files=file_batch)
                session.run("""
                    MATCH (s:SqlStatement)
                    WHERE s.repoId = $repoId
                      AND ANY(file IN coalesce(s.sourceFiles, []) WHERE file IN $files)
                    DETACH DELETE s
                """, repoId=repo_id, files=file_batch)
                
                # 智能删除：先过滤 sourceFiles，再根据结果决定删除或更新
                session.run("""
                    MATCH ()-[r]->()
                    WHERE r.repoId = $repoId
                    AND ANY(f IN r.sourceFiles WHERE f IN $files)
                    WITH r, [f IN r.sourceFiles WHERE NOT f IN $files] AS remainingFiles
                    FOREACH (_ IN CASE WHEN size(remainingFiles) = 0 THEN [1] ELSE [] END |
                        DELETE r
                    )
                    FOREACH (_ IN CASE WHEN size(remainingFiles) > 0 THEN [1] ELSE [] END |
                        SET r.sourceFiles = remainingFiles
                    )
                """, repoId=repo_id, files=file_batch)
                
            # 2. 清理不再参与任何血缘边的 Column 和 Table 节点。
            # Column 只剩 BELONGS_TO 时也应删除，否则旧假字段会挂在表下面。
            print(f"  - 清理不再关联任何血缘的孤立节点...")
            session.run("""
                MATCH (c:Column)
                WHERE NOT EXISTS {
                    MATCH (c)-[r]-()
                    WHERE type(r) <> 'BELONGS_TO'
                }
                DETACH DELETE c
            """)
            session.run("""
                MATCH (t:Table)
                WHERE NOT (t)-[]-()
                DELETE t
            """)
                
            print(f"  - 相关血缘关系已智能清除（保留多文件关系）")

    def clear_lineage_by_version(self, version: str):
        """Clear lineage relationships for one analysis version."""
        if not version:
            return

        print(f"正在清除版本 {version} 的旧血缘关系...")
        with self.driver.session() as session:
            session.run(
                """
                MATCH (f:LineageFact)
                WHERE f.version = $version
                DETACH DELETE f
                """,
                version=version,
            )
            session.run(
                """
                MATCH (s:SqlStatement)
                WHERE s.version = $version
                DETACH DELETE s
                """,
                version=version,
            )
            session.run(
                """
                MATCH ()-[r]->()
                WHERE r.version = $version
                DELETE r
                """,
                version=version,
            )
            session.run(
                """
                MATCH (c:Column)
                WHERE NOT EXISTS {
                    MATCH (c)-[r]-()
                    WHERE type(r) <> 'BELONGS_TO'
                }
                DETACH DELETE c
                """
            )
            session.run(
                """
                MATCH (t:Table)
                WHERE NOT (t)-[]-()
                DELETE t
                """
            )
        print("✓ 指定版本血缘清除完成")


    def create_lineage(self, source_table: str, target_table: str, relationship: dict = None,
                       version: str = None, repo_id: str = None):
        """
        创建两个表之间的血缘关系。
        """
        item = dict(relationship or {})
        item["source"] = source_table
        item["target"] = target_table
        self.create_lineage_batch([item], version=version, repo_id=repo_id)

    @staticmethod
    def _as_clean_list(value):
        if value is None:
            return []
        values = value if isinstance(value, list) else [value]
        return [str(item) for item in values if item not in (None, "")]

    def _normalize_table_relationships(self, relationships: list, version: str = None, repo_id: str = None):
        normalized = []
        for rel in relationships:
            source = (rel.get("source") or rel.get("source_table") or "").upper()
            target = (rel.get("target") or rel.get("target_table") or "").upper()
            if not source or not target:
                continue

            dependency_type = rel.get("dependency_type") or rel.get("type") or "fdd"
            neo4j_rel_type = rel.get("neo4j_type") or RELATION_TYPE_MAP.get(dependency_type, "DERIVES_TO")
            if neo4j_rel_type not in ALL_LINEAGE_RELATION_TYPES:
                neo4j_rel_type = "DERIVES_TO"

            source_columns = self._as_clean_list(
                rel.get("sourceColumns") or rel.get("source_columns") or rel.get("source_column")
            )
            target_columns = self._as_clean_list(
                rel.get("targetColumns") or rel.get("target_columns") or rel.get("target_column")
            )
            source_files = self._as_clean_list(
                rel.get("sourceFiles") or rel.get("source_files") or rel.get("source_file") or rel.get("sourceFile")
            )
            relation_level = rel.get("relation_level") or rel.get("relationLevel") or "table_fallback"
            confidence = rel.get("confidence") or ("LOW" if relation_level == "table_fallback" else "MEDIUM")
            lineage_origin = rel.get("lineage_origin") or rel.get("lineageOrigin") or "table_parser"
            snippet = rel.get("snippet") or rel.get("sql")
            normalized_snippet = self._normalize_sql_for_statement_hash(snippet)
            statement_hash = rel.get("statementHash") or rel.get("statement_hash") or self._statement_hash(snippet)
            parser_statement_uid_value, statement_uid = self._statement_identity_for_item(rel, version, repo_id)
            normalized_for_uid = {
                "statementUid": statement_uid,
                "relationType": neo4j_rel_type,
                "sourceTable": source,
                "targetTable": target,
                "projectionIndex": rel.get("projectionIndex") if rel.get("projectionIndex") is not None else rel.get("projection_index"),
                "sourceExpression": rel.get("sourceExpression") or rel.get("source_expression"),
                "targetExpression": rel.get("targetExpression") or rel.get("target_expression"),
            }
            parser_relation_uid = rel.get("parserRelationUid") or rel.get("parser_relation_uid") or rel.get("relationUid") or rel.get("relation_uid")
            scoped_relation_uid = relation_uid(version, repo_id, normalized_for_uid)

            normalized.append({
                "source": source,
                "target": target,
                "dependency_type": dependency_type,
                "neo4j_rel_type": neo4j_rel_type,
                "snippet": snippet,
                "normalized_snippet": normalized_snippet,
                "statement_hash": statement_hash,
                "parser_statement_uid": parser_statement_uid_value,
                "statement_uid": statement_uid,
                "parser_relation_uid": parser_relation_uid,
                "relation_uid": scoped_relation_uid,
                "source_files": source_files,
                "source_columns": source_columns,
                "target_columns": target_columns,
                "version": version or rel.get("version"),
                "repo_id": repo_id or rel.get("repo_id") or rel.get("repoId"),
                "statement_index": rel.get("statementIndex") if rel.get("statementIndex") is not None else rel.get("statement_index"),
                "projection_index": rel.get("projectionIndex") if rel.get("projectionIndex") is not None else rel.get("projection_index"),
                "source_expression": rel.get("sourceExpression") or rel.get("source_expression"),
                "target_expression": rel.get("targetExpression") or rel.get("target_expression"),
                "relation_level": relation_level,
                "relation_levels": self._as_clean_list(rel.get("relationLevels") or rel.get("relation_levels"))
                    or [relation_level],
                "lineage_origin": lineage_origin,
                "lineage_origins": self._as_clean_list(rel.get("lineageOrigins") or rel.get("lineage_origins"))
                    or [lineage_origin],
                "confidence": confidence,
                "validation_note": rel.get("validation_note") or rel.get("validationNote"),
                "ambiguity_code": rel.get("ambiguityCode") or rel.get("ambiguity_code"),
                "metadata_matched": rel.get("metadataMatched") if rel.get("metadataMatched") is not None else rel.get("metadata_matched"),
                "metadata_pack_hash": rel.get("metadataPackHash") or rel.get("metadata_pack_hash"),
            })
        return normalized

    def create_lineage_batch(self, relationships: list, version: str = None, repo_id: str = None):
        """
        批量创建表级血缘。
        relationships: 包含 source 和 target 键的字典列表
        """
        normalized = self._normalize_table_relationships(relationships, version=version, repo_id=repo_id)
        if not normalized:
            return

        grouped = {}
        for rel in normalized:
            grouped.setdefault(rel["neo4j_rel_type"], []).append(rel)

        with self.driver.session() as session:
            # 优化：增加批次大小到 2000
            batch_size = 2000
            total_all = len(normalized)
            processed_all = 0
            for rel_type, group in grouped.items():
                total = len(group)
                for i in range(0, total, batch_size):
                    chunk = group[i:i + batch_size]
                    try:
                        session.execute_write(self._create_tables_batch, chunk, rel_type)
                    except Exception as e:
                        print(f"\n    Error in table batch {i//batch_size} ({rel_type}): {e}")

                    # Progress Log - 每 5000 条或最后一批打印一次
                    processed_all += len(chunk)
                    if processed_all % 5000 == 0 or processed_all == total_all:
                        sys.stdout.write(f"\r    Processed {processed_all}/{total_all} table relationships...")
                        sys.stdout.flush()
            print("") # Newline after done
            for i in range(0, len(normalized), batch_size):
                session.execute_write(self._create_lineage_facts_batch, normalized[i:i + batch_size])

    @staticmethod
    def _create_tables_batch(tx, relationships, rel_type):
        query = f"""
        UNWIND $batch AS item
        MERGE (s:Table {{name: item.source}})
        MERGE (t:Table {{name: item.target}})
        MERGE (s)-[r:{rel_type}]->(t)
        SET r.version = CASE WHEN item.version IS NOT NULL THEN item.version ELSE r.version END,
            r.repoId = CASE WHEN item.repo_id IS NOT NULL THEN item.repo_id ELSE r.repoId END,
            r.type = item.dependency_type,
            r.relationLevel = item.relation_level,
            r.isTableFallback = CASE WHEN item.relation_level = 'table_fallback' THEN true ELSE coalesce(r.isTableFallback, false) END,
            r.hasTableFallback = coalesce(r.hasTableFallback, false) OR item.relation_level = 'table_fallback',
            r.lineageOrigin = item.lineage_origin,
            r.confidence = item.confidence,
            r.validationNote = CASE WHEN item.validation_note IS NOT NULL THEN item.validation_note ELSE r.validationNote END,
            r.ambiguityCode = CASE WHEN item.ambiguity_code IS NOT NULL THEN item.ambiguity_code ELSE r.ambiguityCode END,
            r.metadataMatched = CASE WHEN item.metadata_matched IS NOT NULL THEN item.metadata_matched ELSE r.metadataMatched END,
            r.metadataPackHash = CASE WHEN item.metadata_pack_hash IS NOT NULL THEN item.metadata_pack_hash ELSE r.metadataPackHash END,
            r.statementUid = CASE WHEN item.statement_uid IS NOT NULL THEN item.statement_uid ELSE r.statementUid END,
            r.relationUid = CASE WHEN item.relation_uid IS NOT NULL THEN item.relation_uid ELSE r.relationUid END,
            r.projectionIndex = CASE WHEN item.projection_index IS NOT NULL THEN item.projection_index ELSE r.projectionIndex END,
            r.sourceExpression = CASE WHEN item.source_expression IS NOT NULL THEN item.source_expression ELSE r.sourceExpression END,
            r.targetExpression = CASE WHEN item.target_expression IS NOT NULL THEN item.target_expression ELSE r.targetExpression END,
            r.snippet = CASE
                WHEN item.snippet IS NOT NULL AND trim(item.snippet) <> '' THEN item.snippet
                ELSE r.snippet
            END,
            r.normalizedSnippet = CASE
                WHEN item.normalized_snippet IS NOT NULL AND trim(item.normalized_snippet) <> '' THEN item.normalized_snippet
                ELSE r.normalizedSnippet
            END,
            r.statementHash = CASE
                WHEN item.statement_hash IS NOT NULL AND trim(item.statement_hash) <> '' THEN item.statement_hash
                ELSE r.statementHash
            END,
            r.snippets = CASE
                WHEN item.snippet IS NULL OR trim(item.snippet) = '' THEN coalesce(r.snippets, [])
                WHEN item.statement_hash IS NOT NULL AND trim(item.statement_hash) <> ''
                     AND item.statement_hash IN coalesce(r.statementHashes, []) THEN coalesce(r.snippets, [])
                WHEN item.snippet IN coalesce(r.snippets, []) THEN coalesce(r.snippets, [])
                ELSE coalesce(r.snippets, []) + item.snippet
            END,
            r.normalizedSnippets = CASE
                WHEN item.normalized_snippet IS NULL OR trim(item.normalized_snippet) = '' THEN coalesce(r.normalizedSnippets, [])
                WHEN item.statement_hash IS NOT NULL AND trim(item.statement_hash) <> ''
                     AND item.statement_hash IN coalesce(r.statementHashes, []) THEN coalesce(r.normalizedSnippets, [])
                WHEN item.normalized_snippet IN coalesce(r.normalizedSnippets, []) THEN coalesce(r.normalizedSnippets, [])
                ELSE coalesce(r.normalizedSnippets, []) + item.normalized_snippet
            END,
            r.statementHashes = CASE
                WHEN item.statement_hash IS NULL OR trim(item.statement_hash) = '' THEN coalesce(r.statementHashes, [])
                WHEN item.statement_hash IN coalesce(r.statementHashes, []) THEN coalesce(r.statementHashes, [])
                ELSE coalesce(r.statementHashes, []) + item.statement_hash
            END,
            r.statementUids = CASE
                WHEN item.statement_uid IS NULL OR trim(item.statement_uid) = '' THEN coalesce(r.statementUids, [])
                WHEN item.statement_uid IN coalesce(r.statementUids, []) THEN coalesce(r.statementUids, [])
                ELSE coalesce(r.statementUids, []) + item.statement_uid
            END,
            r.relationUids = CASE
                WHEN item.relation_uid IS NULL OR trim(item.relation_uid) = '' THEN coalesce(r.relationUids, [])
                WHEN item.relation_uid IN coalesce(r.relationUids, []) THEN coalesce(r.relationUids, [])
                ELSE coalesce(r.relationUids, []) + item.relation_uid
            END,
            r.createdAt = CASE WHEN r.createdAt IS NULL THEN datetime() ELSE r.createdAt END,
            r.relationLevels = reduce(levels = coalesce(r.relationLevels, []), level IN item.relation_levels |
                CASE WHEN level IN levels THEN levels ELSE levels + level END),
            r.lineageOrigins = reduce(origins = coalesce(r.lineageOrigins, []), origin IN item.lineage_origins |
                CASE WHEN origin IN origins THEN origins ELSE origins + origin END),
            r.sourceFiles = CASE
                WHEN size(item.source_files) = 0 THEN coalesce(r.sourceFiles, [])
                ELSE reduce(files = coalesce(r.sourceFiles, []), file IN item.source_files |
                    CASE WHEN file IN files THEN files ELSE files + file END)
            END,
            r.sourceColumns = CASE
                WHEN size(item.source_columns) = 0 THEN coalesce(r.sourceColumns, [])
                ELSE reduce(columns = coalesce(r.sourceColumns, []), column IN item.source_columns |
                    CASE WHEN column IN columns THEN columns ELSE columns + column END)
            END,
            r.targetColumns = CASE
                WHEN size(item.target_columns) = 0 THEN coalesce(r.targetColumns, [])
                ELSE reduce(columns = coalesce(r.targetColumns, []), column IN item.target_columns |
                    CASE WHEN column IN columns THEN columns ELSE columns + column END)
            END
        """
        tx.run(query, batch=relationships)

    @staticmethod
    def _create_lineage_facts_batch(tx, facts):
        query = """
        UNWIND $batch AS item
        WITH item,
             coalesce(item.source_table, item.source, '') AS sourceTable,
             coalesce(item.target_table, item.target, '') AS targetTable,
             coalesce(item.source_column, '') AS sourceColumn,
             coalesce(item.target_column, '') AS targetColumn,
             CASE
                WHEN item.source_files IS NOT NULL THEN item.source_files
                WHEN item.source_file IS NULL THEN []
                ELSE [item.source_file]
             END AS sourceFiles
        WHERE item.relation_uid IS NOT NULL AND trim(item.relation_uid) <> ''
          AND sourceTable <> '' AND targetTable <> ''
        MERGE (stmt:SqlStatement {statementUid: item.statement_uid})
        SET stmt.parserStatementUid = item.parser_statement_uid,
            stmt.statementHash = item.statement_hash,
            stmt.statementIndex = item.statement_index,
            stmt.sqlText = item.snippet,
            stmt.normalizedSnippet = item.normalized_snippet,
            stmt.version = item.version,
            stmt.repoId = item.repo_id,
            stmt.sourceFiles = sourceFiles,
            stmt.createdAt = CASE WHEN stmt.createdAt IS NULL THEN datetime() ELSE stmt.createdAt END,
            stmt.updatedAt = datetime()
        MERGE (fact:LineageFact {relationUid: item.relation_uid})
        SET fact.parserRelationUid = item.parser_relation_uid,
            fact.statementUid = item.statement_uid,
            fact.parserStatementUid = item.parser_statement_uid,
            fact.statementHash = item.statement_hash,
            fact.statementIndex = item.statement_index,
            fact.relationType = item.neo4j_rel_type,
            fact.dependencyType = item.dependency_type,
            fact.sourceTable = sourceTable,
            fact.sourceColumn = sourceColumn,
            fact.targetTable = targetTable,
            fact.targetColumn = targetColumn,
            fact.projectionIndex = item.projection_index,
            fact.sourceExpression = item.source_expression,
            fact.targetExpression = item.target_expression,
            fact.context = item.context,
            fact.lineageOrigin = item.lineage_origin,
            fact.relationLevel = item.relation_level,
            fact.confidence = item.confidence,
            fact.validationNote = item.validation_note,
            fact.ambiguityCode = item.ambiguity_code,
            fact.metadataMatched = item.metadata_matched,
            fact.metadataPackHash = item.metadata_pack_hash,
            fact.isExpanded = item.is_expanded,
            fact.version = item.version,
            fact.repoId = item.repo_id,
            fact.sourceFiles = sourceFiles,
            fact.snippet = item.snippet,
            fact.normalizedSnippet = item.normalized_snippet,
            fact.createdAt = CASE WHEN fact.createdAt IS NULL THEN datetime() ELSE fact.createdAt END,
            fact.updatedAt = datetime()
        MERGE (fact)-[:IN_STATEMENT]->(stmt)
        MERGE (st:Table {name: sourceTable})
        MERGE (tt:Table {name: targetTable})
        FOREACH (_ IN CASE WHEN sourceColumn <> '' THEN [1] ELSE [] END |
            MERGE (sc:Column {name: sourceColumn, table: sourceTable})
            MERGE (sc)-[:BELONGS_TO]->(st)
            MERGE (fact)-[:FROM_COLUMN]->(sc)
        )
        FOREACH (_ IN CASE WHEN sourceColumn = '' THEN [1] ELSE [] END |
            MERGE (fact)-[:FROM_TABLE]->(st)
        )
        FOREACH (_ IN CASE WHEN targetColumn <> '' THEN [1] ELSE [] END |
            MERGE (tc:Column {name: targetColumn, table: targetTable})
            MERGE (tc)-[:BELONGS_TO]->(tt)
            MERGE (fact)-[:TO_COLUMN]->(tc)
        )
        FOREACH (_ IN CASE WHEN targetColumn = '' THEN [1] ELSE [] END |
            MERGE (fact)-[:TO_TABLE]->(tt)
        )
        """
        tx.run(query, batch=facts)

    def create_column_lineage(self, dependencies: list):
        """
        批量创建字段级血缘关系。
        dependencies: 包含 source_table, source_column, target_table, target_column 键的字典列表
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
                
                # 进度日志
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
        
        # 分为直接血缘和间接血缘
        direct_items = []
        indirect_items = []
        skipped_missing_source_columns = 0
        
        for dep in dependencies:
            if self._is_missing_source_column_dependency(dep):
                skipped_missing_source_columns += 1
                continue

            # 归一化处理
            source_table = (dep.get("source_table") or "").upper()
            source_column = (dep.get("source_column") or "").upper()
            target_table = (dep.get("target_table") or "").upper()
            target_column = (dep.get("target_column") or "").upper()
            
            if not source_table or not source_column or not target_table:
                continue

            snippet = dep.get("snippet")
            normalized_snippet = self._normalize_sql_for_statement_hash(snippet)
            statement_hash = dep.get("statementHash") or dep.get("statement_hash") or self._statement_hash(snippet)
            parser_statement_uid_value, statement_uid = self._statement_identity_for_item(dep, version, repo_id)
            projection_index = dep.get("projectionIndex") if dep.get("projectionIndex") is not None else dep.get("projection_index")
            source_expression = dep.get("sourceExpression") or dep.get("source_expression")
            target_expression = dep.get("targetExpression") or dep.get("target_expression")

            item = {
                "source_table": source_table,
                "source_column": source_column,
                "target_table": target_table,
                "target_column": target_column,
                "source_file": dep.get("source_file"),
                "dependency_type": dep.get("dependency_type", "fdd"),
                "snippet": snippet,
                "normalized_snippet": normalized_snippet,
                "statement_hash": statement_hash,
                "parser_statement_uid": parser_statement_uid_value,
                "statement_uid": statement_uid,
                "version": version,
                "repo_id": repo_id,
                "statement_index": dep.get("statementIndex") if dep.get("statementIndex") is not None else dep.get("statement_index"),
                "projection_index": projection_index,
                "source_expression": source_expression,
                "target_expression": target_expression,
                "context": dep.get("context"),
                "lineage_origin": dep.get("lineage_origin") or dep.get("lineageOrigin") or "column_parser",
                "relation_level": dep.get("relation_level") or dep.get("relationLevel") or "",
                "confidence": dep.get("confidence", "MEDIUM"),
                "validation_note": dep.get("validation_note"),
                "ambiguity_code": dep.get("ambiguityCode") or dep.get("ambiguity_code"),
                "metadata_matched": dep.get("metadataMatched") if dep.get("metadataMatched") is not None else dep.get("metadata_matched"),
                "metadata_pack_hash": dep.get("metadataPackHash") or dep.get("metadata_pack_hash"),
                "is_expanded": dep.get("is_expanded", False)
            }
            
            # 查找 Neo4j 关系类型，优先保留解析器已经细分出的 GROUPS/ORDERS 等类型。
            neo4j_rel_type = dep.get("neo4j_type") or RELATION_TYPE_MAP.get(item["dependency_type"], "DERIVES_TO")
            if neo4j_rel_type not in ALL_LINEAGE_RELATION_TYPES:
                neo4j_rel_type = "DERIVES_TO"
            item["neo4j_rel_type"] = neo4j_rel_type
            uid_input = {
                "statementUid": statement_uid,
                "relationType": neo4j_rel_type,
                "sourceTable": source_table,
                "sourceColumn": source_column,
                "targetTable": target_table,
                "targetColumn": target_column,
                "projectionIndex": projection_index,
                "sourceExpression": source_expression,
                "targetExpression": target_expression,
            }
            item["parser_relation_uid"] = dep.get("parserRelationUid") or dep.get("parser_relation_uid") or dep.get("relationUid") or dep.get("relation_uid")
            item["relation_uid"] = relation_uid(version, repo_id, uid_input)

            if target_column in ["*", "", None]:
                indirect_items.append(item)
            else:
                direct_items.append(item)

        if skipped_missing_source_columns:
            print(f"跳过 {skipped_missing_source_columns} 条源字段未通过 metadata 校验的字段依赖。", flush=True)
        
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

        # 1. 直接处理直接血缘
        if direct_items:
            print(f"正在处理 {len(direct_items)} 条直接字段依赖...", flush=True)
            process_by_type(direct_items, self._create_direct_column_batch_safe)

        # 2. 处理间接血缘
        if indirect_items:
            print(f"正在处理 {len(indirect_items)} 条间接字段依赖...", flush=True)
            process_by_type(indirect_items, self._create_indirect_column_batch_safe)

        fact_items = direct_items + indirect_items
        if fact_items:
            batch_size = 2000
            with self.driver.session() as session:
                for i in range(0, len(fact_items), batch_size):
                    session.execute_write(self._create_lineage_facts_batch, fact_items[i:i + batch_size])

    @staticmethod
    def _is_missing_source_column_dependency(dep: dict) -> bool:
        ambiguity_code = (dep.get("ambiguityCode") or dep.get("ambiguity_code") or "").upper()
        if ambiguity_code == "MISSING_SOURCE_COLUMN":
            return True
        source_exists = dep.get("sourceColumnExists")
        if source_exists is None:
            source_exists = dep.get("source_column_exists")
        return source_exists is False

    @staticmethod
    def _create_direct_column_batch_safe(tx, batch, rel_type):
        # 安全版本，其中 rel_type 在批次中是常量
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
            r.confidence = item.confidence,
            r.validationNote = item.validation_note,
            r.ambiguityCode = item.ambiguity_code,
            r.metadataMatched = item.metadata_matched,
            r.metadataPackHash = item.metadata_pack_hash,
            r.isExpanded = item.is_expanded,
            r.statementUid = item.statement_uid,
            r.relationUid = item.relation_uid,
            r.projectionIndex = item.projection_index,
            r.sourceExpression = item.source_expression,
            r.targetExpression = item.target_expression,
            r.context = item.context,
            r.lineageOrigin = item.lineage_origin,
            r.relationLevel = item.relation_level,
            r.snippet = CASE WHEN item.snippet IS NOT NULL THEN item.snippet ELSE r.snippet END,
            r.normalizedSnippet = CASE
                WHEN item.normalized_snippet IS NOT NULL AND trim(item.normalized_snippet) <> '' THEN item.normalized_snippet
                ELSE r.normalizedSnippet
            END,
            r.statementHash = CASE
                WHEN item.statement_hash IS NOT NULL AND trim(item.statement_hash) <> '' THEN item.statement_hash
                ELSE r.statementHash
            END,
            r.snippets = CASE
                WHEN item.snippet IS NULL OR trim(item.snippet) = '' THEN coalesce(r.snippets, [])
                WHEN item.statement_hash IS NOT NULL AND trim(item.statement_hash) <> ''
                     AND item.statement_hash IN coalesce(r.statementHashes, []) THEN coalesce(r.snippets, [])
                WHEN item.snippet IN coalesce(r.snippets, []) THEN coalesce(r.snippets, [])
                ELSE coalesce(r.snippets, []) + item.snippet
            END,
            r.normalizedSnippets = CASE
                WHEN item.normalized_snippet IS NULL OR trim(item.normalized_snippet) = '' THEN coalesce(r.normalizedSnippets, [])
                WHEN item.statement_hash IS NOT NULL AND trim(item.statement_hash) <> ''
                     AND item.statement_hash IN coalesce(r.statementHashes, []) THEN coalesce(r.normalizedSnippets, [])
                WHEN item.normalized_snippet IN coalesce(r.normalizedSnippets, []) THEN coalesce(r.normalizedSnippets, [])
                ELSE coalesce(r.normalizedSnippets, []) + item.normalized_snippet
            END,
            r.statementHashes = CASE
                WHEN item.statement_hash IS NULL OR trim(item.statement_hash) = '' THEN coalesce(r.statementHashes, [])
                WHEN item.statement_hash IN coalesce(r.statementHashes, []) THEN coalesce(r.statementHashes, [])
                ELSE coalesce(r.statementHashes, []) + item.statement_hash
            END,
            r.statementUids = CASE
                WHEN item.statement_uid IS NULL OR trim(item.statement_uid) = '' THEN coalesce(r.statementUids, [])
                WHEN item.statement_uid IN coalesce(r.statementUids, []) THEN coalesce(r.statementUids, [])
                ELSE coalesce(r.statementUids, []) + item.statement_uid
            END,
            r.relationUids = CASE
                WHEN item.relation_uid IS NULL OR trim(item.relation_uid) = '' THEN coalesce(r.relationUids, [])
                WHEN item.relation_uid IN coalesce(r.relationUids, []) THEN coalesce(r.relationUids, [])
                ELSE coalesce(r.relationUids, []) + item.relation_uid
            END,
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
            r.confidence = item.confidence,
            r.validationNote = item.validation_note,
            r.ambiguityCode = item.ambiguity_code,
            r.metadataMatched = item.metadata_matched,
            r.metadataPackHash = item.metadata_pack_hash,
            r.isExpanded = item.is_expanded,
            r.statementUid = item.statement_uid,
            r.relationUid = item.relation_uid,
            r.projectionIndex = item.projection_index,
            r.sourceExpression = item.source_expression,
            r.targetExpression = item.target_expression,
            r.context = item.context,
            r.lineageOrigin = item.lineage_origin,
            r.relationLevel = item.relation_level,
            r.snippet = CASE WHEN item.snippet IS NOT NULL THEN item.snippet ELSE r.snippet END,
            r.normalizedSnippet = CASE
                WHEN item.normalized_snippet IS NOT NULL AND trim(item.normalized_snippet) <> '' THEN item.normalized_snippet
                ELSE r.normalizedSnippet
            END,
            r.statementHash = CASE
                WHEN item.statement_hash IS NOT NULL AND trim(item.statement_hash) <> '' THEN item.statement_hash
                ELSE r.statementHash
            END,
            r.snippets = CASE
                WHEN item.snippet IS NULL OR trim(item.snippet) = '' THEN coalesce(r.snippets, [])
                WHEN item.statement_hash IS NOT NULL AND trim(item.statement_hash) <> ''
                     AND item.statement_hash IN coalesce(r.statementHashes, []) THEN coalesce(r.snippets, [])
                WHEN item.snippet IN coalesce(r.snippets, []) THEN coalesce(r.snippets, [])
                ELSE coalesce(r.snippets, []) + item.snippet
            END,
            r.normalizedSnippets = CASE
                WHEN item.normalized_snippet IS NULL OR trim(item.normalized_snippet) = '' THEN coalesce(r.normalizedSnippets, [])
                WHEN item.statement_hash IS NOT NULL AND trim(item.statement_hash) <> ''
                     AND item.statement_hash IN coalesce(r.statementHashes, []) THEN coalesce(r.normalizedSnippets, [])
                WHEN item.normalized_snippet IN coalesce(r.normalizedSnippets, []) THEN coalesce(r.normalizedSnippets, [])
                ELSE coalesce(r.normalizedSnippets, []) + item.normalized_snippet
            END,
            r.statementHashes = CASE
                WHEN item.statement_hash IS NULL OR trim(item.statement_hash) = '' THEN coalesce(r.statementHashes, [])
                WHEN item.statement_hash IN coalesce(r.statementHashes, []) THEN coalesce(r.statementHashes, [])
                ELSE coalesce(r.statementHashes, []) + item.statement_hash
            END,
            r.statementUids = CASE
                WHEN item.statement_uid IS NULL OR trim(item.statement_uid) = '' THEN coalesce(r.statementUids, [])
                WHEN item.statement_uid IN coalesce(r.statementUids, []) THEN coalesce(r.statementUids, [])
                ELSE coalesce(r.statementUids, []) + item.statement_uid
            END,
            r.relationUids = CASE
                WHEN item.relation_uid IS NULL OR trim(item.relation_uid) = '' THEN coalesce(r.relationUids, [])
                WHEN item.relation_uid IN coalesce(r.relationUids, []) THEN coalesce(r.relationUids, [])
                ELSE coalesce(r.relationUids, []) + item.relation_uid
            END,
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
        追溯字段的上游来源。
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
        追溯字段的下游影响。
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
        为报表/指标创建血缘。
        """
        with self.driver.session() as session:
            if item["type"] == "indicator":
                session.execute_write(self._create_indicator, item)
            elif item["type"] == "chart_usage":
                session.execute_write(self._create_report_usage, item)

    @staticmethod
    def _create_indicator(tx, item):
        # 创建指标节点
        tx.run(
            "MERGE (i:Indicator {name: $name}) "
            "SET i.logic = $logic, i.report = $report",
            name=item["name"], logic=item.get("logic"), report=item["report"]
        )
        # 链接到源字段
        if item.get("source_table") and item.get("source_column"):
            tx.run(
                "MATCH (c:Column {name: $col, table: $table}) "
                "MATCH (i:Indicator {name: $name}) "
                "MERGE (c)-[:CONTRIBUTES_TO]->(i)",
                col=item["source_column"], table=item["source_table"], name=item["name"]
            )

    @staticmethod
    def _create_report_usage(tx, item):
        # 创建报表节点
        tx.run("MERGE (r:Report {name: $name})", name=item["report"])
        
        # 将源字段链接到报表
        if item.get("source_table") and item.get("source_column"):
            tx.run(
                "MATCH (c:Column {name: $col, table: $table}) "
                "MATCH (r:Report {name: $report}) "
                "MERGE (c)-[:USED_IN]->(r)",
                col=item["source_column"], table=item["source_table"], report=item["report"]
            )

    def query_upstream(self, table_name: str):
        """
        查找给定表的上游表。
        """
        with self.driver.session() as session:
            result = session.run(
                "MATCH (s:Table)-[:DERIVES_TO*]->(t:Table {name: $name}) RETURN DISTINCT s.name",
                name=table_name
            )
            return [record["s.name"] for record in result]

    def query_downstream(self, table_name: str):
        """
        查找给定表的下游表。
        """
        with self.driver.session() as session:
            result = session.run(
                "MATCH (s:Table {name: $name})-[:DERIVES_TO*]->(t:Table) RETURN DISTINCT t.name",
                name=table_name
            )
            return [record["t.name"] for record in result]

    def get_graph_data(self, start_node_name: str, depth: int = 2):
        """
        获取起始于某个节点的图数据（节点和边），用于可视化。
        """
        with self.driver.session() as session:
            # 同时查询 Table 和 Column 节点
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
