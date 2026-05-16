from typing import List, Dict, Any, Set, Tuple
from .gsp import GSPParser
from .indirect_flow_parser import IndirectFlowParser
from utils.splitter import SqlSplitter
from utils.metadata_resolver import MetadataResolver
import logging
import re

# Suppress sqlglot warnings for unsupported syntax (like CALL)
logging.getLogger("sqlglot").setLevel(logging.ERROR)


class LineageParser:
    def __init__(self, dialect: str = "mysql", default_schema: str = None):
        self.dialect = dialect
        self.default_schema = default_schema
        self.parser = GSPParser()
        self.resolver = MetadataResolver()
        self.indirect_parser = IndirectFlowParser(dialect, resolver=self.resolver)  # 注入共享实例

    def parse(self, sql: str, source_file: str = None) -> Dict[str, Any]:
        """
        Parse SQL and extract lineage information using GSP.

        Args:
            sql: SQL string to parse
            source_file: Path to the source SQL file (for lineage tracking)

        Returns:
            Dictionary containing source tables, target tables, and column dependencies.
        """
        # Try direct parsing first if small enough, or if no semicolon logic is desired by default
        # But per requirements we want to support large SQL.
        # Safest is to always split, or split if length > threshold.
        # Let's split always for "script" support.

        # Auto-detect dialect if default 'mysql' is used but content looks like specific dialect
        from utils.dialect_detector import detect_dialect

        current_dialect = self.dialect
        detected_dialect = detect_dialect(sql)
        detected_switch = False

        if current_dialect == "mysql" and detected_dialect:
            import logging

            current_dialect = detected_dialect
            detected_switch = True

        statements = SqlSplitter.split(sql)
        sources = set()
        targets = set()
        relations = []

        # Import normalization utility
        from utils.normalize import normalize_table_name

        # ===== 1. Direct Dependencies (GSP) - Run First =====
        gsp_json_list = []
        detailed_statements = []
        gsp_tables = set()  # 用于存储 GSP 识别的表名（标准化后）
        import re

        # Aggregate results
        for stmt in statements:
            stmts_to_process = [stmt]

            # Level 1: Check for large procedure or large statement
            if len(stmt) > 10000:
                # Try procedure split first
                proc_stmts = SqlSplitter.extract_procedure_body(stmt)
                if proc_stmts != [stmt]:
                    stmts_to_process = proc_stmts
                else:
                    # Fallback: Try smart_split
                    stmts_to_process = SqlSplitter.smart_split(stmt)

            for sub_stmt in stmts_to_process:
                # Level 2: Check if sub-statement is still large
                final_sub_stmts = [sub_stmt]
                is_huge = False
                if len(sub_stmt) > 10000:
                    # Try stripping comments first to reduce size
                    cleaned_stmt = SqlSplitter.remove_comments(sub_stmt)
                    if len(cleaned_stmt) <= 10000:
                        final_sub_stmts = [cleaned_stmt]
                    else:
                        # Still too large, try splitting with smart_split again on cleaned stmt
                        final_sub_stmts = SqlSplitter.smart_split(cleaned_stmt)

                        # If still huge (single item which is huge), mark it for fallback
                        if (
                            len(final_sub_stmts) == 1
                            and len(final_sub_stmts[0]) > 10000
                        ):
                            is_huge = True

                for final_stmt in final_sub_stmts:
                    # Pre-processing: Remove "TABLE" keyword from "INSERT INTO TABLE"
                    final_stmt = re.sub(
                        r"(?i)(INSERT\s+INTO\s+)TABLE\s+", r"\1", final_stmt
                    )

                    result = self.parser.parse(final_stmt, current_dialect, source_file)

                    # Check if GSP failed to produce lineage for a huge statement
                    if is_huge and not result.get("targets"):
                        # Fallback to Regex
                        fallback_result = self._extract_lineage_fallback(final_stmt)
                        if fallback_result["targets"]:
                            # Merge fallback result
                            lineage_found = True
                            if fallback_result["sources"]:
                                result["sources"] = list(
                                    set(
                                        result.get("sources", [])
                                        + fallback_result["sources"]
                                    )
                                )
                            if fallback_result["targets"]:
                                result["targets"] = list(
                                    set(
                                        result.get("targets", [])
                                        + fallback_result["targets"]
                                    )
                                )
                            if fallback_result["relationships"]:
                                result["relationships"] = (
                                    result.get("relationships", [])
                                    + fallback_result["relationships"]
                                )

                    has_lineage = False
                    stmt_info = {
                        "sql": final_stmt,
                        "sources": [],
                        "targets": [],
                        "relationships": [],
                        "gsp_json": result.get("gsp_json"),
                    }

                    # Extract sources/targets/relationships
                    if "sources" in result and result["sources"]:
                        sources.update(result["sources"])
                        gsp_tables.update(result["sources"])  # 记录 GSP 表名
                        stmt_info["sources"] = result["sources"]
                        has_lineage = True
                    if "targets" in result and result["targets"]:
                        targets.update(result["targets"])
                        gsp_tables.update(result["targets"])  # 记录 GSP 表名
                        stmt_info["targets"] = result["targets"]
                        has_lineage = True
                    if "relationships" in result and result["relationships"]:
                        for rel in result["relationships"]:
                            rel.setdefault("source_file", source_file)
                            rel.setdefault("snippet", final_stmt)
                            rel.setdefault("lineage_origin", "gsp_table")
                            rel.setdefault("relation_level", "table_evidence")
                            rel.setdefault("confidence", "MEDIUM")
                        relations.extend(result["relationships"])
                        stmt_info["relationships"] = result["relationships"]
                        has_lineage = True

                    # Only add to detailed output if lineage exists
                    if has_lineage:
                        if "gsp_json" in result:
                            gsp_json_list.append(result["gsp_json"])
                        detailed_statements.append(stmt_info)

        # ===== 2. Indirect Dependencies (SQLGlot) - Run After GSP =====
        try:
            # Use dynamic parser if dialect override occurred
            indirect_parser_to_use = self.indirect_parser
            if detected_switch:
                from .indirect_flow_parser import IndirectFlowParser

                indirect_parser_to_use = IndirectFlowParser(current_dialect)

            indirect_deps = indirect_parser_to_use.parse(sql, source_file)
            for dep in indirect_deps:
                # 标准化 sqlglot 输出的表名
                dep_target = normalize_table_name(dep["target_table"])
                dep_source = normalize_table_name(dep["source_table"])

                # 添加关系，使用标准化后的表名
                relations.append(
                    {
                        "target_table": dep_target,
                        "target_column": dep["target_column"],
                        "source_table": dep_source,
                        "source_column": dep["source_column"],
                        "dependency_type": dep["dependency_type"],
                        "source_file": dep.get("source_file"),
                        "snippet": dep.get("snippet"),
                        "lineage_origin": "sqlglot_table",
                        "relation_level": "table_from_column",
                        "confidence": dep.get("confidence", "MEDIUM"),
                        "validation_note": dep.get("validation_note"),
                        # Normalize for compatibility
                        "source": dep_source,
                        "target": dep_target,
                    }
                )

                # 添加到 sources/targets（标准化后）
                sources.add(dep_source)
                targets.add(dep_target)
        except Exception as e:
            import logging

            logging.warning(f"Indirect flow parsing failed: {e}")

        # ===== 2.5. CTE Resolution - Resolve CTE aliases to physical tables =====
        # Must run AFTER indirect parsing because GSP may return empty for CTE queries,
        # and the CTE alias references come from the sqlglot indirect parser.
        cte_registry = self._build_cte_registry(sql, current_dialect)
        if cte_registry:
            sources, targets, relations, detailed_statements = (
                self._resolve_cte_in_table_results(
                    sources, targets, relations, detailed_statements, cte_registry
                )
            )

        # ===== 3. Schema Fallback & Application =====
        # Determine actual schema to apply
        schema_to_apply = self.default_schema
        is_explicit = bool(self.default_schema)

        if not schema_to_apply and source_file:
            # Automatic directory-based fallback
            try:
                parent_dir = os.path.dirname(source_file)
                dir_name = os.path.basename(parent_dir)

                schema_to_apply = dir_name
                # User rule: If parent dir looks like a type indicator, go up
                if dir_name.lower() in ["sql", "ddl", "dml", "scripts", "bin"]:
                    grandparent_dir = os.path.dirname(parent_dir)
                    schema_to_apply = os.path.basename(grandparent_dir)

                # For automatic fallback, apply exclusion list
                if schema_to_apply.lower() in [
                    "mysql",
                    "hive",
                    "oracle",
                    "tests",
                    "bin",
                    ".",
                    "test",
                    "",
                ]:
                    schema_to_apply = None
            except Exception:
                schema_to_apply = None

        # Apply the schema if we have one (either explicit or valid fallback)
        if schema_to_apply:

            def apply_schema(table_name):
                if not table_name or table_name == "UNKNOWN":
                    return table_name
                # Skip if already has schema
                if "." in table_name:
                    return table_name
                # Skip special tables
                if table_name.upper() in ["DUAL"]:
                    return table_name
                return f"{schema_to_apply}.{table_name}"

            # Apply to global sets
            sources = {apply_schema(s) for s in sources}
            targets = {apply_schema(t) for t in targets}

            # Apply to relationships
            for rel in relations:
                if "source" in rel:
                    rel["source"] = apply_schema(rel["source"])
                if "target" in rel:
                    rel["target"] = apply_schema(rel["target"])
                if "source_table" in rel:
                    rel["source_table"] = apply_schema(rel["source_table"])
                if "target_table" in rel:
                    rel["target_table"] = apply_schema(rel["target_table"])

            # Apply to detailed statements (IMPORTANT: this was missing before)
            for stmt in detailed_statements:
                if "sources" in stmt:
                    stmt["sources"] = [apply_schema(s) for s in stmt["sources"]]
                if "targets" in stmt:
                    stmt["targets"] = [apply_schema(t) for t in stmt["targets"]]
                if "relationships" in stmt:
                    for rel in stmt["relationships"]:
                        if "source" in rel:
                            rel["source"] = apply_schema(rel["source"])
                        if "target" in rel:
                            rel["target"] = apply_schema(rel["target"])

        return {
            "sources": list(sources),
            "targets": list(targets),
            "relationships": relations,
            "statements": detailed_statements,
            "source_file": source_file,
            "gsp_json": gsp_json_list,
        }

    def get_column_lineage(
        self, sql: str, source_file: str = None
    ) -> List[Dict[str, str]]:
        """
        Get column-level lineage from SQL using GSP.

        Args:
            sql: SQL string to parse
            source_file: Path to the source SQL file (for lineage tracking)

        Returns:
            List of dependencies with all relationship types:
            [{source_table, source_column, target_table, target_column, dependency_type, source_file}, ...]
        """
        # Import normalization utility
        from utils.normalize import normalize_table_name

        # Auto-detect dialect if default 'mysql' is used but content looks like specific dialect
        from utils.dialect_detector import detect_dialect

        current_dialect = self.dialect
        detected_dialect = detect_dialect(sql)
        detected_switch = False

        if current_dialect == "mysql" and detected_dialect:
            import logging

            current_dialect = detected_dialect
            detected_switch = True

        statements = SqlSplitter.split(sql)
        dependencies = []

        import re

        for stmt in statements:
            stmts_to_process = [stmt]

            # Level 1: Check for stored procedure OR large statement
            # Always try to extract procedure body if it looks like a stored procedure
            # Handle: CREATE PROCEDURE, CREATE OR REPLACE PROCEDURE, CREATE DEFINER=... PROCEDURE
            is_procedure = bool(re.search(r"(?i)CREATE\s+.*?PROCEDURE", stmt))

            if is_procedure or len(stmt) > 10000:
                proc_stmts = SqlSplitter.extract_procedure_body(stmt)
                if proc_stmts != [stmt]:
                    stmts_to_process = proc_stmts
                elif len(stmt) > 10000:
                    stmts_to_process = SqlSplitter.smart_split(stmt)

            for sub_stmt in stmts_to_process:
                # Level 2: Check if sub-statement is still large
                final_sub_stmts = [sub_stmt]
                if len(sub_stmt) > 10000:
                    cleaned_stmt = SqlSplitter.remove_comments(sub_stmt)
                    if len(cleaned_stmt) <= 10000:
                        final_sub_stmts = [cleaned_stmt]
                    else:
                        final_sub_stmts = SqlSplitter.smart_split(cleaned_stmt)

                for final_stmt in final_sub_stmts:
                    # Pre-processing: Remove "TABLE" keyword from "INSERT INTO TABLE"
                    final_stmt = re.sub(
                        r"(?i)(INSERT\s+INTO\s+)TABLE\s+", r"\1", final_stmt
                    )

                    # 1. Indirect Dependencies (SQLGlot) - Run on final clean statement
                    try:
                        # Use dynamic parser if dialect override occurred
                        indirect_parser_to_use = self.indirect_parser
                        if detected_switch:
                            from .indirect_flow_parser import IndirectFlowParser

                            indirect_parser_to_use = IndirectFlowParser(current_dialect)

                        indirect_deps = indirect_parser_to_use.parse(
                            final_stmt, source_file
                        )
                        for dep in indirect_deps:
                            dependencies.append(
                                {
                                    "target_table": dep["target_table"],
                                    "target_column": dep["target_column"],
                                    "source_table": dep["source_table"],
                                    "source_column": dep["source_column"],
                                    "dependency_type": dep["dependency_type"],
                                    "source_file": dep.get("source_file"),
                                    "snippet": dep.get(
                                        "snippet"
                                    ),  # Pass through the SQL snippet
                                }
                            )
                    except Exception as e:
                        pass

                    # 2. Direct Dependencies (GSP)
                    result = self.parser.parse(final_stmt, current_dialect, source_file)
                    gsp_json = result.get("gsp_json")
                    if not gsp_json:
                        continue

                    dlineage = gsp_json.get("dlineage", {})
                    if not dlineage:
                        dlineage = gsp_json
                    relationships = dlineage.get("relationships", [])

                    for rel in relationships:
                        # 提取所有类型的关系，不仅限于 fdd
                        rel_type = rel.get("type", "fdd")

                        target = rel.get("target", {})
                        rel_sources = rel.get("sources", [])

                        target_table = target.get("parentName", "UNKNOWN")
                        target_table = (
                            normalize_table_name(target_table)
                            if target_table and target_table != "UNKNOWN"
                            else target_table
                        )
                        target_column = target.get("column", "UNKNOWN")

                        # Filter out TABLE level relationships (where column is unknown/empty)
                        if target_column in ["UNKNOWN", "", None]:
                            continue

                        for src in rel_sources:
                            source_table = src.get("parentName", "UNKNOWN")
                            source_table = (
                                normalize_table_name(source_table)
                                if source_table and source_table != "UNKNOWN"
                                else source_table
                            )
                            source_column = src.get("column", "UNKNOWN")

                            dependencies.append(
                                {
                                    "target_table": target_table,
                                    "target_column": target_column,
                                    "source_table": source_table,
                                    "source_column": source_column,
                                    "dependency_type": rel_type,  # 原始 GSP 类型
                                    "source_file": source_file,  # 来源文件
                                    "snippet": final_stmt,  # 添加 SQL 片段
                                }
                            )

        # ===== 2.5. CTE Resolution - Resolve CTE aliases to physical tables =====
        cte_registry = self._build_cte_registry(sql, current_dialect)
        if cte_registry:
            dependencies = self._resolve_cte_in_column_results(
                dependencies, cte_registry
            )

        # ===== 3. Metadata Validation & Star Expansion =====
        final_dependencies = []
        for dep in dependencies:
            src_table = dep["source_table"]
            src_col = dep["source_column"]
            tgt_table = dep["target_table"]
            tgt_col = dep["target_column"]

            # 3.1 Handle Star Expansion (Source Column is *)
            if src_col == "*":
                fields = self.resolver.get_table_fields(src_table)
                if fields:
                    for f_name in fields:
                        # Create a new dependency for each field
                        new_dep = dep.copy()
                        new_dep["source_column"] = f_name
                        new_dep["is_expanded"] = True

                        # Validate the newly created source and target (if target is not unknown)
                        # Confidence
                        val_res = self.resolver.validate_column(src_table, f_name)
                        new_dep["confidence"] = val_res.get("confidence", "MEDIUM")
                        new_dep["validation_note"] = val_res.get("note")
                        final_dependencies.append(new_dep)
                    continue  # Skip the original '*' dependency

            # 3.2 Regular Validation & Confidence Calculation
            # Validate Source
            src_val = self.resolver.validate_column(src_table, src_col)
            # Validate Target (only if it's a real column, not UNKNOWN or *)
            tgt_val = {"confidence": "HIGH"}
            if tgt_col and tgt_col not in ["UNKNOWN", "*"]:
                tgt_val = self.resolver.validate_column(tgt_table, tgt_col)

            # Final confidence is the minimum of src and tgt
            conf_map = {"HIGH": 3, "MEDIUM": 2, "LOW": 1}
            src_score = conf_map.get(src_val["confidence"], 2)
            tgt_score = conf_map.get(tgt_val["confidence"], 2)

            min_score = min(src_score, tgt_score)
            final_conf = (
                "HIGH" if min_score == 3 else ("MEDIUM" if min_score == 2 else "LOW")
            )

            dep["confidence"] = final_conf
            dep["validation_note"] = (
                f"Src: {src_val.get('note') or 'OK'}; Tgt: {tgt_val.get('note') or 'OK'}"
            )
            final_dependencies.append(dep)

        # ===== Schema Fallback & Application =====
        schema_to_apply = self.default_schema
        is_explicit = bool(self.default_schema)

        if not schema_to_apply and source_file:
            try:
                parent_dir = os.path.dirname(source_file)
                dir_name = os.path.basename(parent_dir)

                schema_to_apply = dir_name
                # User rule: If parent is type folder, go up one more
                if dir_name.lower() in ["sql", "ddl", "dml", "scripts", "bin"]:
                    grandparent_dir = os.path.dirname(parent_dir)
                    schema_to_apply = os.path.basename(grandparent_dir)

                # Exclusion check for automatic fallback
                if schema_to_apply.lower() in [
                    "mysql",
                    "hive",
                    "oracle",
                    "tests",
                    "bin",
                    ".",
                    "test",
                    "",
                ]:
                    schema_to_apply = None
            except Exception:
                schema_to_apply = None

        if schema_to_apply:

            def apply_schema(table_name):
                if not table_name or table_name == "UNKNOWN":
                    return table_name
                if "." in table_name:
                    return table_name
                if table_name.upper() in ["DUAL"]:
                    return table_name
                return f"{schema_to_apply}.{table_name}"

            for dep in final_dependencies:
                dep["target_table"] = apply_schema(dep["target_table"])
                dep["source_table"] = apply_schema(dep["source_table"])

        return final_dependencies

    # ============================================================
    # CTE Resolution Methods
    # ============================================================

    def _build_cte_registry(self, sql: str, dialect: str = None) -> Dict[str, Dict]:
        """
        使用 sqlglot 解析 SQL 中的 CTE 定义，构建 CTE 别名到物理表/列的映射。

        返回格式:
        {
            "cte_alias": {
                "physical_tables": {"schema.table", ...},
                "column_map": {
                    "cte_col_name": [("source_table", "source_column"), ...],
                    ...
                }
            }
        }
        """
        try:
            import sqlglot
            from sqlglot import exp
        except ImportError:
            return {}

        # 快速检查是否包含 WITH 关键字
        if not re.search(r"(?i)\bWITH\b", sql):
            return {}

        dialect_map = {
            "mysql": "mysql",
            "oracle": "oracle",
            "hive": "hive",
            "spark": "spark",
            "postgresql": "postgres",
        }
        sg_dialect = dialect_map.get((dialect or self.dialect).lower())

        registry = {}
        try:
            statements = sqlglot.parse(sql, dialect=sg_dialect)
            for stmt in statements:
                if stmt is None:
                    continue
                # 查找所有 CTE
                ctes = stmt.find_all(exp.CTE)
                for cte in ctes:
                    alias = cte.alias
                    if not alias:
                        continue
                    alias_upper = alias.upper()

                    # 提取 CTE 体中的物理表
                    physical_tables = set()
                    cte_body = cte.this  # CTE 的 SELECT 语句
                    if cte_body:
                        for table in cte_body.find_all(exp.Table):
                            parts = []
                            if table.catalog:
                                parts.append(table.catalog)
                            if table.db:
                                parts.append(table.db)
                            parts.append(table.name)
                            full_name = ".".join(parts)
                            # 排除引用其他 CTE 的情况（如果已在 registry 中）
                            if full_name.upper() not in registry:
                                physical_tables.add(full_name)

                    # 构建列映射：CTE 的 SELECT 列 -> 源表列
                    column_map = {}
                    if cte_body and isinstance(cte_body, exp.Select):
                        for expr_node in cte_body.expressions:
                            # 获取输出列名
                            if isinstance(expr_node, exp.Alias):
                                out_col = expr_node.alias.upper()
                                inner = expr_node.this
                            elif isinstance(expr_node, exp.Column):
                                out_col = expr_node.name.upper()
                                inner = expr_node
                            else:
                                continue

                            # 追踪内部表达式中的所有列引用
                            source_cols = []
                            for col_ref in (
                                [inner]
                                if isinstance(inner, exp.Column)
                                else inner.find_all(exp.Column)
                            ):
                                src_table = col_ref.table or ""
                                src_col = col_ref.name
                                # 解析表别名到物理表
                                resolved_table = self._resolve_cte_table_alias(
                                    src_table, cte_body, physical_tables
                                )
                                source_cols.append((resolved_table, src_col.upper()))

                            if source_cols:
                                column_map[out_col] = source_cols

                    # 处理嵌套 CTE：如果物理表中包含已注册的 CTE 别名，递归展开
                    expanded_tables = set()
                    for pt in physical_tables:
                        pt_upper = pt.upper()
                        if pt_upper in registry:
                            expanded_tables.update(
                                registry[pt_upper]["physical_tables"]
                            )
                        else:
                            expanded_tables.add(pt)

                    # 展开 column_map 中引用其他 CTE 的情况
                    expanded_column_map = {}
                    for out_col, src_list in column_map.items():
                        expanded_sources = []
                        for src_table, src_col in src_list:
                            src_upper = src_table.upper()
                            if src_upper in registry and src_col in registry[
                                src_upper
                            ].get("column_map", {}):
                                # 递归展开
                                expanded_sources.extend(
                                    registry[src_upper]["column_map"][src_col]
                                )
                            else:
                                expanded_sources.append((src_table, src_col))
                        expanded_column_map[out_col] = expanded_sources

                    registry[alias_upper] = {
                        "physical_tables": expanded_tables,
                        "column_map": expanded_column_map,
                    }
        except Exception as e:
            logging.debug(f"CTE registry build failed: {e}")

        return registry

    def _resolve_cte_table_alias(
        self, alias: str, select_stmt, physical_tables: set
    ) -> str:
        """
        将 SELECT 中的表别名解析为物理表名。
        例如: SELECT A.COL FROM ODS.ORDERS A => alias 'A' -> 'ODS.ORDERS'
        """
        if not alias:
            # 无别名，如果只有一个物理表就返回它
            if len(physical_tables) == 1:
                return next(iter(physical_tables))
            return ""

        try:
            from sqlglot import exp

            # 在 FROM 和 JOIN 中查找别名匹配
            for table in select_stmt.find_all(exp.Table):
                table_alias = table.alias
                if table_alias and table_alias.upper() == alias.upper():
                    parts = []
                    if table.catalog:
                        parts.append(table.catalog)
                    if table.db:
                        parts.append(table.db)
                    parts.append(table.name)
                    return ".".join(parts)
        except Exception:
            pass

        return alias

    def _resolve_cte_in_table_results(
        self,
        sources: set,
        targets: set,
        relations: list,
        detailed_statements: list,
        cte_registry: dict,
    ) -> Tuple[set, set, list, list]:
        """
        在表级血缘结果中将 CTE 别名替换为物理表名。
        当CTE对应多个物理表时，展开为多条关系记录。
        """
        from utils.normalize import normalize_table_name

        def resolve_table(table_name: str) -> set:
            """将表名解析为物理表集合（如果是 CTE 别名则展开）"""
            t_norm = normalize_table_name(table_name)
            t_upper = t_norm.upper()
            if t_upper in cte_registry and cte_registry[t_upper]["physical_tables"]:
                return cte_registry[t_upper]["physical_tables"]
            return {table_name}

        # 展开 sources（CTE 别名 → 物理表集合）
        new_sources = set()
        for s in sources:
            new_sources.update(resolve_table(s))

        # targets 通常不是 CTE，但保持一致处理
        new_targets = set()
        for t in targets:
            new_targets.update(resolve_table(t))

        # 展开 relations：一条记录可能扩展为多条
        new_relations = []
        for rel in relations:
            rel = dict(rel)
            src_tables = resolve_table(rel.get("source_table") or rel.get("source", ""))
            tgt_tables = resolve_table(rel.get("target_table") or rel.get("target", ""))

            for src in src_tables:
                for tgt in tgt_tables:
                    new_rel = dict(rel)
                    if "source_table" in new_rel:
                        new_rel["source_table"] = src
                    if "source" in new_rel:
                        new_rel["source"] = src
                    if "target_table" in new_rel:
                        new_rel["target_table"] = tgt
                    if "target" in new_rel:
                        new_rel["target"] = tgt
                    new_relations.append(new_rel)

        # 替换 detailed_statements（保持原有逻辑，只取第一个物理表）
        for stmt in detailed_statements:
            stmt["sources"] = [
                (
                    next(iter(cte_registry[s.upper()]["physical_tables"]))
                    if s.upper() in cte_registry
                    and cte_registry[s.upper()]["physical_tables"]
                    else s
                )
                for s in stmt.get("sources", [])
            ]

        return new_sources, new_targets, new_relations, detailed_statements

    def _resolve_cte_in_column_results(
        self, dependencies: list, cte_registry: dict
    ) -> list:
        """
        在字段级血缘结果中将 CTE 别名替换为物理表+列名。

        例如: monthly_stats.CUSTOMER_ID -> ODS.ORDERS.CUSTOMER_ID
        通过 CTE 的 column_map 追溯。
        """
        resolved = []
        for dep in dependencies:
            dep = dict(dep)  # 复制
            src_table = (dep.get("source_table") or "").upper()
            src_col = (dep.get("source_column") or "").upper()

            if src_table in cte_registry:
                cte_info = cte_registry[src_table]
                column_map = cte_info.get("column_map", {})

                if src_col in column_map:
                    # 有精确列映射 -> 展开
                    for phys_table, phys_col in column_map[src_col]:
                        new_dep = dict(dep)
                        new_dep["source_table"] = phys_table
                        new_dep["source_column"] = phys_col
                        resolved.append(new_dep)
                else:
                    # 列不在映射中（可能是 * 或计算列），回退到物理表
                    phys_tables = cte_info.get("physical_tables", set())
                    if phys_tables:
                        dep["source_table"] = next(iter(phys_tables))
                    resolved.append(dep)
            else:
                resolved.append(dep)

        # 同样处理 target（罕见但可能）
        final = []
        for dep in resolved:
            dep = dict(dep)
            tgt_table = (dep.get("target_table") or "").upper()
            if tgt_table in cte_registry:
                phys = cte_registry[tgt_table].get("physical_tables", set())
                if phys:
                    dep["target_table"] = next(iter(phys))
            final.append(dep)

        return final

    def _extract_lineage_fallback(self, sql: str) -> Dict[str, Any]:
        """
        Fallback lineage extraction using regex for cases where GSP fails (e.g. huge SQL).
        Only provides Table-Level lineage.
        """
        import re

        sources = set()
        targets = set()
        relations = []

        # 1. Find Target Tables (INSERT INTO table)
        # Handle "INSERT INTO TABLE table" (already sanitized usually, but regex can handle optional TABLE)
        # Match table name: alphanumeric, _, ., $
        # Use finditer to support Multi-Table Insert (multiple INSERT INTO in one statement)
        target_matches = re.finditer(
            r"(?i)INSERT\s+INTO\s+(?:TABLE\s+)?([a-zA-Z0-9_$.]+)", sql
        )
        for m in target_matches:
            targets.add(m.group(1))

        # 2. Find Source Tables (FROM/JOIN table)
        # Exclude keyword "SELECT" (e.g. FROM (SELECT...))
        # This is basic and might match false positives like aliases if they look like tables, or schemas.
        # But for fallback it's acceptable.

        # Regex explanation:
        # \b(?:FROM|JOIN)\s+ : match FROM or JOIN word
        # (?:(?P<db>\w+)\.)? : optional db prefix
        # (?P<table>[a-zA-Z0-9_$]+) : table name
        # We iterate all matches.

        # Simply find words after FROM/JOIN
        # Be careful of subqueries starting with (

        matches = re.finditer(r"(?i)\b(?:FROM|JOIN)\s+([a-zA-Z0-9_$.]+)", sql)
        for m in matches:
            src = m.group(1)
            # Filter obvious keywords or non-tables
            if src.upper() in [
                "SELECT",
                "LATERAL",
                "UNNEST",
                "VALUES",
                "(",
                "partition",
            ]:
                continue
            if src.startswith("("):
                continue
            sources.add(src)

        # 3. Create relationships
        for tgt in targets:
            for src in sources:
                relations.append({
                    "source": src,
                    "target": tgt,
                    "type": "fdd",
                    "snippet": sql,
                    "lineage_origin": "regex_fallback",
                    "relation_level": "table_fallback",
                    "confidence": "LOW",
                    "validation_note": "Regex fallback table lineage; column-level evidence was unavailable.",
                })

        return {
            "sources": list(sources),
            "targets": list(targets),
            "relationships": relations,
            "fallback": True,
        }
