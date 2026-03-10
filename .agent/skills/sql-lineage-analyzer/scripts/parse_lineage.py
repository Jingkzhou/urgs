#!/usr/bin/env python3
"""
SQL 血缘解析器 - 双引擎架构 (GSP + sqlglot)

移植自 sql-lineage-engine，提供完整的表级和字段级血缘分析能力。
支持 MySQL, Oracle, Hive, GBase, SparkSQL, PostgreSQL, SQLServer

用法:
    python parse_lineage.py <sql_file> [dialect] [--column] [--json]

    dialect: mysql (默认), oracle, hive, gbase, postgresql, sqlserver
    --column: 输出字段级血缘（默认输出表级）
    --json:   输出原始 JSON（默认美化输出）
"""

import json
import sys
import os
import re
import logging
import hashlib
from typing import List, Dict, Any, Set, Tuple
from dataclasses import dataclass, field, asdict

# 将 scripts 目录加入 sys.path 以支持同级导入
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from splitter import SqlSplitter
from normalize import normalize_table_name
from gsp_parser import GSPParser
from indirect_flow_parser import IndirectFlowParser

# 抑制 sqlglot 警告
logging.getLogger("sqlglot").setLevel(logging.ERROR)


class LineageParser:
    """
    双引擎血缘解析器

    架构:
    - GSP (核心引擎): 深度血缘提取，支持复杂存储过程
    - sqlglot (辅助引擎): 方言探测、间接依赖提取、GSP 失败降级
    """

    def __init__(self, dialect: str = "mysql", default_schema: str = None):
        self.dialect = dialect
        self.default_schema = default_schema
        self.parser = GSPParser()
        self.indirect_parser = IndirectFlowParser(dialect)

    def parse(self, sql: str, source_file: str = None) -> Dict[str, Any]:
        """
        解析 SQL 并提取表级血缘信息。

        Args:
            sql: SQL 字符串
            source_file: 源 SQL 文件路径

        Returns:
            包含 sources, targets, relationships, statements 的字典
        """
        # 自动方言探测
        current_dialect = self.dialect
        detected_dialect = self._detect_dialect(sql)
        detected_switch = False
        if current_dialect == "mysql" and detected_dialect:
            current_dialect = detected_dialect
            detected_switch = True

        statements = SqlSplitter.split(sql)
        sources = set()
        targets = set()
        relations = []
        gsp_json_list = []
        detailed_statements = []

        # ===== 1. 直接依赖 (GSP) =====
        for stmt in statements:
            stmts_to_process = [stmt]

            # Level 1: 大语句/存储过程预处理
            if len(stmt) > 10000:
                proc_stmts = SqlSplitter.extract_procedure_body(stmt)
                if proc_stmts != [stmt]:
                    stmts_to_process = proc_stmts
                else:
                    stmts_to_process = SqlSplitter.smart_split(stmt)

            for sub_stmt in stmts_to_process:
                # Level 2: 二次降噪
                final_sub_stmts = [sub_stmt]
                is_huge = False
                if len(sub_stmt) > 10000:
                    cleaned_stmt = SqlSplitter.remove_comments(sub_stmt)
                    if len(cleaned_stmt) <= 10000:
                        final_sub_stmts = [cleaned_stmt]
                    else:
                        final_sub_stmts = SqlSplitter.smart_split(cleaned_stmt)
                        if (
                            len(final_sub_stmts) == 1
                            and len(final_sub_stmts[0]) > 10000
                        ):
                            is_huge = True

                for final_stmt in final_sub_stmts:
                    # 清理 INSERT INTO TABLE -> INSERT INTO
                    final_stmt = re.sub(
                        r"(?i)(INSERT\s+INTO\s+)TABLE\s+", r"\1", final_stmt
                    )

                    result = self.parser.parse(final_stmt, current_dialect, source_file)

                    # 超大语句 GSP 失败时使用正则降级
                    if is_huge and not result.get("targets"):
                        fallback_result = self._extract_lineage_fallback(final_stmt)
                        if fallback_result["targets"]:
                            result["sources"] = list(
                                set(
                                    result.get("sources", [])
                                    + fallback_result["sources"]
                                )
                            )
                            result["targets"] = list(
                                set(
                                    result.get("targets", [])
                                    + fallback_result["targets"]
                                )
                            )
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

                    # 提取结果
                    if "sources" in result and result["sources"]:
                        sources.update(result["sources"])
                        stmt_info["sources"] = result["sources"]
                        has_lineage = True
                    if "targets" in result and result["targets"]:
                        targets.update(result["targets"])
                        stmt_info["targets"] = result["targets"]
                        has_lineage = True
                    if "relationships" in result and result["relationships"]:
                        relations.extend(result["relationships"])
                        stmt_info["relationships"] = result["relationships"]
                        has_lineage = True

                    if has_lineage:
                        if "gsp_json" in result:
                            gsp_json_list.append(result["gsp_json"])
                        detailed_statements.append(stmt_info)

        # ===== 2. 间接依赖 (sqlglot) =====
        try:
            indirect_parser_to_use = self.indirect_parser
            if detected_switch:
                indirect_parser_to_use = IndirectFlowParser(current_dialect)

            indirect_deps = indirect_parser_to_use.parse(sql, source_file)
            for dep in indirect_deps:
                dep_target = normalize_table_name(dep["target_table"])
                dep_source = normalize_table_name(dep["source_table"])
                relations.append(
                    {
                        "target_table": dep_target,
                        "target_column": dep["target_column"],
                        "source_table": dep_source,
                        "source_column": dep["source_column"],
                        "dependency_type": dep["dependency_type"],
                        "source_file": dep.get("source_file"),
                        "source": dep_source,
                        "target": dep_target,
                    }
                )
                sources.add(dep_source)
                targets.add(dep_target)
        except Exception as e:
            logging.warning(f"Indirect flow parsing failed: {e}")

        # ===== 2.5. CTE 解析与物理表替换 =====
        cte_registry = self._build_cte_registry(sql, current_dialect)
        if cte_registry:
            sources, targets, relations, detailed_statements = (
                self._resolve_cte_in_table_results(
                    sources, targets, relations, detailed_statements, cte_registry
                )
            )

        # ===== 3. Schema 回退与应用 =====
        schema_to_apply = self.default_schema
        if not schema_to_apply and source_file:
            try:
                parent_dir = os.path.dirname(source_file)
                dir_name = os.path.basename(parent_dir)
                schema_to_apply = dir_name
                if dir_name.lower() in ["sql", "ddl", "dml", "scripts", "bin"]:
                    grandparent_dir = os.path.dirname(parent_dir)
                    schema_to_apply = os.path.basename(grandparent_dir)
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

            sources = {apply_schema(s) for s in sources}
            targets = {apply_schema(t) for t in targets}
            for rel in relations:
                for key in ["source", "target", "source_table", "target_table"]:
                    if key in rel:
                        rel[key] = apply_schema(rel[key])
            for stmt in detailed_statements:
                if "sources" in stmt:
                    stmt["sources"] = [apply_schema(s) for s in stmt["sources"]]
                if "targets" in stmt:
                    stmt["targets"] = [apply_schema(t) for t in stmt["targets"]]

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
        获取字段级血缘。

        Returns:
            [{source_table, source_column, target_table, target_column, dependency_type, source_file}, ...]
        """
        current_dialect = self.dialect
        detected_dialect = self._detect_dialect(sql)
        detected_switch = False
        if current_dialect == "mysql" and detected_dialect:
            current_dialect = detected_dialect
            detected_switch = True

        statements = SqlSplitter.split(sql)
        dependencies = []

        for stmt in statements:
            stmts_to_process = [stmt]

            is_procedure = bool(re.search(r"(?i)CREATE\s+.*?PROCEDURE", stmt))
            if is_procedure or len(stmt) > 10000:
                proc_stmts = SqlSplitter.extract_procedure_body(stmt)
                if proc_stmts != [stmt]:
                    stmts_to_process = proc_stmts
                elif len(stmt) > 10000:
                    stmts_to_process = SqlSplitter.smart_split(stmt)

            for sub_stmt in stmts_to_process:
                final_sub_stmts = [sub_stmt]
                if len(sub_stmt) > 10000:
                    cleaned_stmt = SqlSplitter.remove_comments(sub_stmt)
                    if len(cleaned_stmt) <= 10000:
                        final_sub_stmts = [cleaned_stmt]
                    else:
                        final_sub_stmts = SqlSplitter.smart_split(cleaned_stmt)

                for final_stmt in final_sub_stmts:
                    final_stmt = re.sub(
                        r"(?i)(INSERT\s+INTO\s+)TABLE\s+", r"\1", final_stmt
                    )

                    # 1. 间接依赖 (sqlglot)
                    try:
                        indirect_parser_to_use = self.indirect_parser
                        if detected_switch:
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
                                    "snippet": dep.get("snippet"),
                                }
                            )
                    except Exception:
                        pass

                    # 2. 直接依赖 (GSP)
                    result = self.parser.parse(final_stmt, current_dialect, source_file)
                    gsp_json = result.get("gsp_json")
                    if not gsp_json:
                        continue

                    dlineage = gsp_json.get("dlineage", {})
                    if not dlineage:
                        dlineage = gsp_json
                    relationships = dlineage.get("relationships", [])

                    for rel in relationships:
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
                                    "dependency_type": rel_type,
                                    "source_file": source_file,
                                    "snippet": final_stmt,
                                }
                            )

        # CTE 解析
        cte_registry = self._build_cte_registry(sql, current_dialect)
        if cte_registry:
            dependencies = self._resolve_cte_in_column_results(
                dependencies, cte_registry
            )

        # Schema 回退
        schema_to_apply = self.default_schema
        if not schema_to_apply and source_file:
            try:
                parent_dir = os.path.dirname(source_file)
                dir_name = os.path.basename(parent_dir)
                schema_to_apply = dir_name
                if dir_name.lower() in ["sql", "ddl", "dml", "scripts", "bin"]:
                    schema_to_apply = os.path.basename(os.path.dirname(parent_dir))
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

            for dep in dependencies:
                dep["target_table"] = apply_schema(dep["target_table"])
                dep["source_table"] = apply_schema(dep["source_table"])

        return dependencies

    # ==================== 方言探测 ====================

    def _detect_dialect(self, sql: str) -> str:
        """启发式方言探测，返回 'oracle', 'hive', 或 None"""
        sql_upper = sql.upper()

        oracle_keywords = [
            r"\bNVL\s*\(",
            r"\bDECODE\s*\(",
            r"\bTO_CHAR\s*\(",
            r"\bTO_DATE\s*\(",
            r"\bSYSDATE\b",
            r"\bFROM\s+DUAL\b",
            r"CREATE\s+(?:OR\s+REPLACE\s+)?PROCEDURE",
            r"\bVARCHAR2\b",
            r"\bDBMS_OUTPUT\b",
            r"\bBEGIN\s*$",
            r"\bEND\s*;\s*$",
        ]
        for pattern in oracle_keywords:
            if re.search(pattern, sql_upper):
                return "oracle"

        hive_keywords = [
            r"\bPARTITIONED\s+BY\b",
            r"\bCLUSTERED\s+BY\b",
            r"\bROW\s+FORMAT\b",
            r"\bSTORED\s+AS\b",
            r"\bLATERAL\s+VIEW\b",
            r"\bEXPLODE\s*\(",
            r"\bASC\s+NULLS\s+(?:FIRST|LAST)\b",
            r"(?s)^\s*FROM\s+.*\bINSERT\s+INTO\b",
        ]
        for pattern in hive_keywords:
            if re.search(pattern, sql_upper):
                return "hive"

        return None

    # ==================== CTE 解析 ====================

    def _build_cte_registry(self, sql: str, dialect: str = None) -> Dict[str, Dict]:
        """构建 CTE 别名到物理表/列的映射。"""
        try:
            import sqlglot
            from sqlglot import exp
        except ImportError:
            return {}

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
                ctes = stmt.find_all(exp.CTE)
                for cte in ctes:
                    alias = cte.alias
                    if not alias:
                        continue
                    alias_upper = alias.upper()

                    physical_tables = set()
                    cte_body = cte.this
                    if cte_body:
                        for table in cte_body.find_all(exp.Table):
                            parts = []
                            if table.catalog:
                                parts.append(table.catalog)
                            if table.db:
                                parts.append(table.db)
                            parts.append(table.name)
                            full_name = ".".join(parts)
                            if full_name.upper() not in registry:
                                physical_tables.add(full_name)

                    column_map = {}
                    if cte_body and isinstance(cte_body, exp.Select):
                        for expr_node in cte_body.expressions:
                            if isinstance(expr_node, exp.Alias):
                                out_col = expr_node.alias.upper()
                                inner = expr_node.this
                            elif isinstance(expr_node, exp.Column):
                                out_col = expr_node.name.upper()
                                inner = expr_node
                            else:
                                continue

                            source_cols = []
                            for col_ref in (
                                [inner]
                                if isinstance(inner, exp.Column)
                                else inner.find_all(exp.Column)
                            ):
                                src_table = col_ref.table or ""
                                src_col = col_ref.name
                                resolved_table = self._resolve_cte_table_alias(
                                    src_table, cte_body, physical_tables
                                )
                                source_cols.append((resolved_table, src_col.upper()))

                            if source_cols:
                                column_map[out_col] = source_cols

                    # 嵌套 CTE 展开
                    expanded_tables = set()
                    for pt in physical_tables:
                        pt_upper = pt.upper()
                        if pt_upper in registry:
                            expanded_tables.update(
                                registry[pt_upper]["physical_tables"]
                            )
                        else:
                            expanded_tables.add(pt)

                    expanded_column_map = {}
                    for out_col, src_list in column_map.items():
                        expanded_sources = []
                        for src_table, src_col in src_list:
                            src_upper = src_table.upper()
                            if src_upper in registry and src_col in registry[
                                src_upper
                            ].get("column_map", {}):
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
        """将 SELECT 中的表别名解析为物理表名。"""
        if not alias:
            if len(physical_tables) == 1:
                return next(iter(physical_tables))
            return ""

        try:
            from sqlglot import exp

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
        self, sources, targets, relations, detailed_statements, cte_registry
    ):
        """在表级血缘结果中将 CTE 别名替换为物理表名。"""
        new_sources = set()
        for s in sources:
            s_norm = normalize_table_name(s)
            s_upper = s_norm.upper()
            if s_upper in cte_registry:
                new_sources.update(cte_registry[s_upper]["physical_tables"])
            else:
                new_sources.add(s)

        new_targets = set()
        for t in targets:
            t_norm = normalize_table_name(t)
            t_upper = t_norm.upper()
            if t_upper in cte_registry:
                new_targets.update(cte_registry[t_upper]["physical_tables"])
            else:
                new_targets.add(t)

        new_relations = []
        for rel in relations:
            rel = dict(rel)
            for key in ["source", "source_table"]:
                if key in rel:
                    val_upper = (rel[key] or "").upper()
                    if val_upper in cte_registry:
                        phys = cte_registry[val_upper]["physical_tables"]
                        rel[key] = next(iter(phys)) if phys else rel[key]
            for key in ["target", "target_table"]:
                if key in rel:
                    val_upper = (rel[key] or "").upper()
                    if val_upper in cte_registry:
                        phys = cte_registry[val_upper]["physical_tables"]
                        rel[key] = next(iter(phys)) if phys else rel[key]
            new_relations.append(rel)

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
        """在字段级血缘结果中将 CTE 别名替换为物理表+列名。"""
        resolved = []
        for dep in dependencies:
            dep = dict(dep)
            src_table = (dep.get("source_table") or "").upper()
            src_col = (dep.get("source_column") or "").upper()

            if src_table in cte_registry:
                cte_info = cte_registry[src_table]
                column_map = cte_info.get("column_map", {})
                if src_col in column_map:
                    for phys_table, phys_col in column_map[src_col]:
                        new_dep = dict(dep)
                        new_dep["source_table"] = phys_table
                        new_dep["source_column"] = phys_col
                        resolved.append(new_dep)
                else:
                    phys_tables = cte_info.get("physical_tables", set())
                    if phys_tables:
                        dep["source_table"] = next(iter(phys_tables))
                    resolved.append(dep)
            else:
                resolved.append(dep)

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

    # ==================== 正则降级 ====================

    def _extract_lineage_fallback(self, sql: str) -> Dict[str, Any]:
        """GSP 失败时的正则降级方案，仅提供表级血缘。"""
        sources = set()
        targets = set()
        relations = []

        target_matches = re.finditer(
            r"(?i)INSERT\s+INTO\s+(?:TABLE\s+)?([a-zA-Z0-9_$.]+)", sql
        )
        for m in target_matches:
            targets.add(m.group(1))

        matches = re.finditer(r"(?i)\b(?:FROM|JOIN)\s+([a-zA-Z0-9_$.]+)", sql)
        for m in matches:
            src = m.group(1)
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

        for tgt in targets:
            for src in sources:
                relations.append({"source": src, "target": tgt, "type": "fdd"})

        return {
            "sources": list(sources),
            "targets": list(targets),
            "relationships": relations,
            "fallback": True,
        }


# ==================== 增量比对 ====================


def compare_lineage(old_result: Dict, new_result: Dict) -> Dict:
    """
    比较两个表级血缘结果，返回差异。

    Args:
        old_result: 旧版本 parse() 输出
        new_result: 新版本 parse() 输出

    Returns:
        差异描述字典
    """
    old_sources = set(old_result.get("sources", []))
    new_sources = set(new_result.get("sources", []))
    old_targets = set(old_result.get("targets", []))
    new_targets = set(new_result.get("targets", []))

    return {
        "added_sources": list(new_sources - old_sources),
        "removed_sources": list(old_sources - new_sources),
        "added_targets": list(new_targets - old_targets),
        "removed_targets": list(old_targets - new_targets),
        "target_changed": old_targets != new_targets,
    }


# ==================== CLI 入口 ====================


def main():
    """命令行入口"""
    if len(sys.argv) < 2:
        print("用法: python parse_lineage.py <sql_file> [dialect] [--column] [--json]")
        print("方言: mysql (默认), oracle, hive, gbase, postgresql, sqlserver")
        print("选项:")
        print("  --column  输出字段级血缘")
        print("  --json    输出原始 JSON")
        sys.exit(1)

    sql_file = sys.argv[1]
    dialect = "mysql"
    column_mode = False

    for arg in sys.argv[2:]:
        if arg == "--column":
            column_mode = True
        elif arg == "--json":
            pass  # JSON 是默认输出
        elif not arg.startswith("--"):
            dialect = arg

    # 读取 SQL 文件（尝试多种编码）
    sql_content = None
    encodings_to_try = ["utf-8", "gbk", "gb2312", "gb18030", "latin-1"]
    for encoding in encodings_to_try:
        try:
            with open(sql_file, "r", encoding=encoding) as f:
                sql_content = f.read()
            break
        except UnicodeDecodeError:
            continue

    if sql_content is None:
        print(
            f"错误: 无法读取文件 {sql_file}（尝试编码: {encodings_to_try}）",
            file=sys.stderr,
        )
        sys.exit(1)

    parser = LineageParser(dialect=dialect)

    if column_mode:
        result = parser.get_column_lineage(sql_content, source_file=sql_file)
        print(json.dumps(result, ensure_ascii=False, indent=2))
    else:
        result = parser.parse(sql_content, source_file=sql_file)
        # 输出简化版（不含 gsp_json 原始数据）
        output = {
            "sources": result["sources"],
            "targets": result["targets"],
            "relationships": [
                {k: v for k, v in r.items() if k != "gsp_json"}
                for r in result["relationships"]
            ],
            "source_file": result["source_file"],
        }
        print(json.dumps(output, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
