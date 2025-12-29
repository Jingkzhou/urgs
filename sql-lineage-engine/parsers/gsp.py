import os
import glob
import jpype
import logging
import re
import json
from typing import List, Dict, Any
from utils.normalize import normalize_table_name

# GSP 关系类型到 Neo4j 关系类型的映射
RELATION_TYPE_MAP = {
    "fdd": "DERIVES_TO",      # 直接数据流 (SELECT)
    "fdr": "FILTERS",         # 间接数据流 (WHERE/HAVING/GROUP BY)
    "join": "JOINS",          # JOIN 条件
    "call": "CALLS",          # 函数调用
    "er": "REFERENCES",       # 实体关系
}

# Regex patterns and helpers from main_to_csv.py
_FULLWIDTH_TRANS = str.maketrans({
    '（': '(',
    '）': ')',
    '，': ',',
    '。': '.',
})

def _strip_inline_comment(line: str) -> str:
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
            if ch == '-' and i + 1 < length and line[i + 1] == '-':
                return line[:i]
            if ch == '#' and line[:i].strip() == '':
                return line[:i]
        i += 1
    return line

def preprocess_sql(sql_content: str) -> str:
    if not sql_content:
        return ""
    sql_content = sql_content.translate(_FULLWIDTH_TRANS)
    sql_content = re.sub(r'/\*.*?\*/', '', sql_content, flags=re.DOTALL)
    sql_content = re.sub(r'\bNOLOGGING\b', '', sql_content, flags=re.IGNORECASE)

    lines = []
    for raw in sql_content.splitlines():
        stripped = raw.strip()
        if not stripped:
            continue
        if stripped.startswith('#'):
            continue
        cleaned = _strip_inline_comment(raw).strip()
        if cleaned:
            lines.append(cleaned)
    return "\n".join(lines)

class GSPParser:
    def __init__(self):
        self._start_jvm()

    def _start_jvm(self):
        if jpype.isJVMStarted():
            return

        curdir = os.path.abspath(os.path.dirname(__file__))
        jar_dir = os.path.join(curdir, 'jar')
        project_jars = glob.glob(os.path.join(jar_dir, '*.jar'))
        
        # Add JAXB jars for Java 11+ runtimes (required since javax.xml.bind is removed from JDK)
        jaxb_jars = [
            "/usr/share/java/jaxb-api.jar",
            "/usr/share/java/jaxb-core.jar",
            "/usr/share/java/jaxb-impl.jar",
            "/usr/share/java/jaxb-runtime.jar",
        ]
        for jar in jaxb_jars:
            if os.path.exists(jar):
                project_jars.append(jar)
        
        logging.info(f"Looking for JARs in: {jar_dir}")
        if not project_jars:
            logging.error(f"No JARs found in {jar_dir}! Current directory files: {os.listdir(curdir)}")
            return

        logging.info(f"Found JARs: {[os.path.basename(j) for j in project_jars]}")
        classpath = os.pathsep.join(project_jars)
        
        # Try to find Java 8 specifically as GSP might depend on it (JAXB)
        java_home = "/Users/work/Library/Java/JavaVirtualMachines/corretto-1.8.0_392/Contents/Home"
        if os.path.exists(java_home):
            os.environ['JAVA_HOME'] = java_home
            logging.info(f"Setting JAVA_HOME to {java_home}")
            try:
                jvm_path = jpype.getDefaultJVMPath()
            except:
                 pass
        
        try:
            if not 'jvm_path' in locals() or not jvm_path:
                jvm_path = jpype.getDefaultJVMPath()
        except Exception as e:
            logging.error(f"Failed to find JVM: {e}")
            raise

        jvm_args = [
            "-ea",
            f"-Djava.class.path={classpath}",
            "-Djava.awt.headless=true",
            "-Xss256k",
            "-Xmx512m",
            "-XX:ParallelGCThreads=2",
            "-XX:CICompilerCount=2"
        ]
        
        logging.info(f"Starting JVM with args: {' '.join(jvm_args)}")
        try:
            jpype.startJVM(jvm_path, *jvm_args)
            logging.info("JVM started successfully in process %s", os.getpid())
        except Exception as e:
            logging.error(f"Failed to start JVM in process {os.getpid()}: {e}")
            raise

    def parse(self, sql: str, db_type: str = "mysql", source_file: str = None) -> Dict[str, Any]:
        """
        Parse SQL using GSP and return lineage info.
        
        Args:
            sql: SQL string to parse
            db_type: SQL dialect (default: mysql)
            source_file: Path to the source SQL file (for lineage tracking)
        """
        if not jpype.isJVMStarted():
            self._start_jvm()

        if not jpype.isThreadAttachedToJVM():
            jpype.attachThreadToJVM()

        # Preprocess
        cleaned_sql = preprocess_sql(sql)
        
        # Check length limit (10k chars for lite version)
        if len(cleaned_sql) > 10000:
            logging.debug("SQL length > 10000, GSP Lite may fail. Consider splitting.")
            # For now, we try to parse it. If it fails, we might need to implement the splitting logic
            # but splitting logic requires handling multiple result sets which is complex to aggregate 
            # into a single "sources/targets" list without more logic.
            # Given the user wants to replace the logic, they might expect the splitting.
            # But for a single 'parse' call returning a dict, let's try direct parsing first.

        try:
            TGSqlParser = jpype.JClass("gudusoft.gsqlparser.TGSqlParser")
            DataFlowAnalyzer = jpype.JClass("gudusoft.gsqlparser.dlineage.DataFlowAnalyzer")
            JSON = jpype.JClass("gudusoft.gsqlparser.util.json.JSON")
            EDbVendor = jpype.JClass("gudusoft.gsqlparser.EDbVendor")
            
            vendor = self._get_vendor(db_type, EDbVendor)
            
            dlineage = DataFlowAnalyzer(cleaned_sql, vendor, True) # simple=True
            
            # Configure options to enable all relationship types
            try:
                dlineage.setShowCallRelation(True)
                dlineage.setShowIndirectRelation(True)  # 启用 fdr (间接数据流)
                dlineage.setShowJoinRelation(True)      # 启用 JOIN 关系
            except Exception:
                # GSP Lite 版本可能不支持这些选项，静默忽略
                pass
            
            # Note: Previously we used a context manager to suppress stderr using os.dup2.
            # However, os.dup2 is not thread-safe and caused deadlocks in the parallel engine.
            # We removed it to ensure stability.
            dlineage.generateDataFlow()

            dataflow = dlineage.getDataFlow()
            
            if not dataflow:
                return {"error": "Failed to generate dataflow"}
                
            # Get JSON model
            model = DataFlowAnalyzer.getSqlflowJSONModel(dataflow, vendor)
            json_str = str(JSON.toJSONString(model))
            
            result = json.loads(json_str)
            
            # Extract sources and targets from the GSP JSON model
            # The model structure is complex. We need to map it to {sources: [], targets: []}
            # GSP JSON usually has "dbObjects" and "relationships".
            
            return self._map_to_lineage_format(result, cleaned_sql, source_file)

        except Exception as e:
            logging.error(f"GSP Parse Error: {e}")
            return {"error": str(e)}

    def _get_vendor(self, db_type: str, EDbVendor):
        db_type = db_type.lower()
        if db_type == "mysql": return EDbVendor.dbvmysql
        if db_type == "hive": return EDbVendor.dbvhive
        if db_type == "oracle": return EDbVendor.dbvoracle
        if db_type == "postgresql": return EDbVendor.dbvpostgresql
        if db_type == "sqlserver": return EDbVendor.dbvsqlserver
        if db_type == "gbase": return EDbVendor.dbvoracle
        return EDbVendor.dbvmysql

    def _map_to_lineage_format(self, gsp_json: Dict, sql: str, source_file: str = None) -> Dict[str, Any]:
        """
        Map GSP JSON output to a standardized lineage format.
        
        Args:
            gsp_json: Raw JSON from GSP parser
            sql: Original SQL string
            source_file: Path to the source SQL file
        """
        sources = set()
        targets = set()
        relations = []
        
        # GSP JSON structure:
        # { "dlineage": { "dbobjs": [ ... ], "relationships": [ ... ] } }
        
        dlineage = gsp_json.get("dlineage", {})
        if not dlineage:
             # Maybe it's at root?
             dlineage = gsp_json
        
        relationships = dlineage.get("relationships", [])
        
        # Extract all relationship types (not just fdd)
        for rel in relationships:
            rel_type = rel.get("type", "fdd")
            
            # Check target
            target = rel.get("target", {})
            target_name = None
            target_column = None
            if target:
                # Prioritize table name
                target_name = target.get("parentName")
                target_name = normalize_table_name(target_name) if target_name else None
                target_column = target.get("column")
                if not target_name:
                     # Check if it is a table itself (generic object)
                     target_name = target.get("name")
                     target_name = normalize_table_name(target_name) if target_name else None
            
            if target_name and target_name.upper() != "TABLE":
                 targets.add(target_name)
            
            # Check sources
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
                        # Map GSP type to Neo4j relation type
                        neo4j_type = RELATION_TYPE_MAP.get(rel_type, "DERIVES_TO")
                        
                        relations.append({
                            "source": src_name,
                            "source_column": src_column,
                            "target": target_name,
                            "target_column": target_column,
                            "type": rel_type,             # 原始 GSP 类型
                            "neo4j_type": neo4j_type,     # 映射后的 Neo4j 关系类型
                            "source_file": source_file    # 来源文件
                        })
        
        return {
            "sources": list(sources),
            "targets": list(targets),
            "relationships": relations,
            "sql": sql,
            "source_file": source_file,
            "gsp_json": gsp_json  # Keep raw for debugging or advanced usage
        }
