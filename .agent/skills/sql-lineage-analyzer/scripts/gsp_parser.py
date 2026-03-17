#!/usr/bin/env python3
"""
GSP 引擎封装 - 基于 General SQL Parser (Java) 的血缘解析

通过 JPype 调用 GSP JAR 进行深度 SQL 血缘分析。
移植自 sql-lineage-engine/parsers/gsp.py
"""

import os
import glob
import logging
import re
import json
from typing import List, Dict, Any

try:
    import jpype
except ImportError:
    jpype = None

from normalize import normalize_table_name

# GSP 关系类型到 Neo4j 关系类型的映射
RELATION_TYPE_MAP = {
    "fdd": "DERIVES_TO",  # 直接数据流 (SELECT)
    "fdr": "FILTERS",  # 间接数据流 (WHERE/HAVING/GROUP BY)
    "join": "JOINS",  # JOIN 条件
    "call": "CALLS",  # 函数调用
    "er": "REFERENCES",  # 实体关系
}

# 全角转半角映射
_FULLWIDTH_TRANS = str.maketrans(
    {
        "（": "(",
        "）": ")",
        "，": ",",
        "。": ".",
    }
)


def _strip_inline_comment(line: str) -> str:
    """移除行内注释，保留字符串内的 -- 和 #"""
    in_single = False
    in_double = False
    i = 0
    length = len(line)
    while i < length:
        ch = line[i]
        if ch == "'" and not in_double:
            if in_single and i + 1 < length and line[i + 1] == "'":
                i += 2
                continue
            in_single = not in_single
            i += 1
            continue
        if ch == '"' and not in_single:
            if in_double and i + 1 < length and line[i + 1] == '"':
                i += 2
                continue
            in_double = not in_double
            i += 1
            continue
        if not in_single and not in_double:
            if ch == "-" and i + 1 < length and line[i + 1] == "-":
                return line[:i]
            if ch == "#" and line[:i].strip() == "":
                return line[:i]
        i += 1
    return line


def preprocess_sql(sql_content: str) -> str:
    """
    GSP 输入预处理：
    1. 全角转半角
    2. 移除块注释
    3. 移除 NOLOGGING 关键字
    4. 移除空行和行注释
    """
    if not sql_content:
        return ""
    sql_content = sql_content.translate(_FULLWIDTH_TRANS)
    sql_content = re.sub(r"/\*.*?\*/", "", sql_content, flags=re.DOTALL)
    sql_content = re.sub(r"\bNOLOGGING\b", "", sql_content, flags=re.IGNORECASE)

    lines = []
    for raw in sql_content.splitlines():
        stripped = raw.strip()
        if not stripped:
            continue
        if stripped.startswith("#"):
            continue
        cleaned = _strip_inline_comment(raw).strip()
        if cleaned:
            lines.append(cleaned)
    return "\n".join(lines)


class GSPParser:
    """GSP (General SQL Parser) 引擎封装"""

    def __init__(self):
        if jpype is None:
            logging.warning("jpype 未安装，GSP 解析不可用。运行: pip install jpype1")
            return
        self._start_jvm()

    def _start_jvm(self):
        if jpype is None or jpype.isJVMStarted():
            return

        # 查找 JAR 文件：优先在技能的 assets/jar 目录，其次在传统路径
        curdir = os.path.dirname(os.path.abspath(__file__))
        skill_jar_dir = os.path.join(curdir, "..", "assets", "jar")
        legacy_jar_dir = os.path.join(curdir, "jar")

        jar_dir = None
        for candidate in [skill_jar_dir, legacy_jar_dir]:
            candidate = os.path.normpath(candidate)
            if os.path.isdir(candidate) and glob.glob(os.path.join(candidate, "*.jar")):
                jar_dir = candidate
                break

        if not jar_dir:
            logging.error(
                f"No JAR directory found. Checked: {skill_jar_dir}, {legacy_jar_dir}"
            )
            return

        project_jars = glob.glob(os.path.join(jar_dir, "*.jar"))
        if not project_jars:
            logging.error(f"No JARs found in {jar_dir}")
            return

        classpath = os.pathsep.join(project_jars)

        # 系统 JAXB JAR（for Java 11+）
        system_jar_dir = "/usr/share/java"
        if os.path.isdir(system_jar_dir):
            system_jars = glob.glob(os.path.join(system_jar_dir, "*.jar"))
            jaxb_jars = [
                j
                for j in system_jars
                if "jaxb" in os.path.basename(j).lower()
                or "activation" in os.path.basename(j).lower()
            ]
            if jaxb_jars:
                classpath = classpath + os.pathsep + os.pathsep.join(jaxb_jars)

        # 尝试查找 Java 8
        java_home_candidates = [
            "/Users/work/Library/Java/JavaVirtualMachines/corretto-1.8.0_392/Contents/Home",
            os.environ.get("JAVA_HOME", ""),
        ]
        for java_home in java_home_candidates:
            if java_home and os.path.exists(java_home):
                os.environ["JAVA_HOME"] = java_home
                break

        try:
            jvm_path = jpype.getDefaultJVMPath()
        except Exception as e:
            logging.error(f"Failed to find JVM: {e}")
            raise

        jvm_args = ["-ea", f"-Djava.class.path={classpath}", "-Djava.awt.headless=true"]

        logging.debug(f"Starting JVM with classpath: {classpath}")
        jpype.startJVM(jvm_path, *jvm_args)

    def parse(
        self, sql: str, db_type: str = "mysql", source_file: str = None
    ) -> Dict[str, Any]:
        """
        使用 GSP 解析 SQL 并返回血缘信息。

        Args:
            sql: SQL 字符串
            db_type: SQL 方言 (mysql, oracle, hive, postgresql, sqlserver, gbase)
            source_file: 源 SQL 文件路径

        Returns:
            标准化的血缘字典
        """
        if jpype is None or not jpype.isJVMStarted():
            return {"error": "JVM not started or jpype not available"}

        # 预处理
        cleaned_sql = preprocess_sql(sql)

        if len(cleaned_sql) > 10000:
            logging.debug("SQL length > 10000, GSP Lite may fail. Consider splitting.")

        try:
            TGSqlParser = jpype.JClass("gudusoft.gsqlparser.TGSqlParser")
            DataFlowAnalyzer = jpype.JClass(
                "gudusoft.gsqlparser.dlineage.DataFlowAnalyzer"
            )
            JSON = jpype.JClass("gudusoft.gsqlparser.util.json.JSON")
            EDbVendor = jpype.JClass("gudusoft.gsqlparser.EDbVendor")

            vendor = self._get_vendor(db_type, EDbVendor)
            dlineage = DataFlowAnalyzer(cleaned_sql, vendor, True)

            # 启用所有关系类型
            try:
                dlineage.setShowCallRelation(True)
                dlineage.setShowIndirectRelation(True)
                dlineage.setShowJoinRelation(True)
            except Exception:
                pass

            # 抑制 stderr 输出
            import sys
            from contextlib import contextmanager

            @contextmanager
            def suppress_stderr():
                null_fds = [os.open(os.devnull, os.O_RDWR) for _ in range(2)]
                save_fds = [os.dup(1), os.dup(2)]
                try:
                    os.dup2(null_fds[1], 2)
                    yield
                finally:
                    os.dup2(save_fds[0], 1)
                    os.dup2(save_fds[1], 2)
                    for fd in null_fds + save_fds:
                        os.close(fd)

            try:
                with suppress_stderr():
                    dlineage.generateDataFlow()
            except Exception:
                dlineage.generateDataFlow()

            dataflow = dlineage.getDataFlow()
            if not dataflow:
                return {"error": "Failed to generate dataflow"}

            model = DataFlowAnalyzer.getSqlflowJSONModel(dataflow, vendor)
            json_str = str(JSON.toJSONString(model))
            result = json.loads(json_str)

            return self._map_to_lineage_format(result, cleaned_sql, source_file)

        except Exception as e:
            logging.error(f"GSP Parse Error: {e}")
            return {"error": str(e)}

    def _get_vendor(self, db_type: str, EDbVendor):
        db_type = db_type.lower()
        if db_type == "mysql":
            return EDbVendor.dbvmysql
        if db_type == "hive":
            return EDbVendor.dbvhive
        if db_type == "oracle":
            return EDbVendor.dbvoracle
        if db_type == "postgresql":
            return EDbVendor.dbvpostgresql
        if db_type == "sqlserver":
            return EDbVendor.dbvsqlserver
        if db_type == "gbase":
            return EDbVendor.dbvoracle
        return EDbVendor.dbvmysql

    def _map_to_lineage_format(
        self, gsp_json: Dict, sql: str, source_file: str = None
    ) -> Dict[str, Any]:
        """将 GSP JSON 输出映射为标准化血缘格式。"""
        sources = set()
        targets = set()
        relations = []

        dlineage = gsp_json.get("dlineage", {})
        if not dlineage:
            dlineage = gsp_json

        relationships = dlineage.get("relationships", [])

        for rel in relationships:
            rel_type = rel.get("type", "fdd")

            target = rel.get("target", {})
            target_name = None
            target_column = None
            if target:
                target_name = target.get("parentName")
                target_name = normalize_table_name(target_name) if target_name else None
                target_column = target.get("column")
                if not target_name:
                    target_name = target.get("name")
                    target_name = (
                        normalize_table_name(target_name) if target_name else None
                    )

            if target_name and target_name.upper() != "TABLE":
                targets.add(target_name)

            rel_sources = rel.get("sources", [])
            for src in rel_sources:
                src_name = src.get("parentName")
                src_name = normalize_table_name(src_name) if src_name else None
                src_column = src.get("column")
                if not src_name:
                    src_name = src.get("name")
                    src_name = normalize_table_name(src_name) if src_name else None

                if src_name:
                    sources.add(src_name)
                    if target_name and target_name.upper() != "TABLE":
                        neo4j_type = RELATION_TYPE_MAP.get(rel_type, "DERIVES_TO")
                        relations.append(
                            {
                                "source": src_name,
                                "source_column": src_column,
                                "target": target_name,
                                "target_column": target_column,
                                "type": rel_type,
                                "neo4j_type": neo4j_type,
                                "source_file": source_file,
                            }
                        )

        return {
            "sources": list(sources),
            "targets": list(targets),
            "relationships": relations,
            "sql": sql,
            "source_file": source_file,
            "gsp_json": gsp_json,
        }
