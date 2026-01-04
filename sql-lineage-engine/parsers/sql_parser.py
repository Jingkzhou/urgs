from typing import List, Dict, Any
from .gsp import GSPParser
from .indirect_flow_parser import IndirectFlowParser
from utils.splitter import SqlSplitter
import logging

# Suppress sqlglot warnings for unsupported syntax (like CALL)
logging.getLogger("sqlglot").setLevel(logging.ERROR)

class LineageParser:
    def __init__(self, dialect: str = "mysql", default_schema: str = None):
        self.dialect = dialect
        self.default_schema = default_schema
        self.parser = GSPParser()
        self.indirect_parser = IndirectFlowParser(dialect)  # sqlglot 补充解析器

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
        current_dialect = self.dialect
        detected_dialect = self._detect_dialect(sql)
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
                         if len(final_sub_stmts) == 1 and len(final_sub_stmts[0]) > 10000:
                             is_huge = True
                 
                 for final_stmt in final_sub_stmts:
                     # Pre-processing: Remove "TABLE" keyword from "INSERT INTO TABLE"
                     final_stmt = re.sub(r'(?i)(INSERT\s+INTO\s+)TABLE\s+', r'\1', final_stmt)
                     
                     result = self.parser.parse(final_stmt, current_dialect, source_file)
                     
                     # Check if GSP failed to produce lineage for a huge statement
                     if is_huge and not result.get("targets"):
                          # Fallback to Regex
                          fallback_result = self._extract_lineage_fallback(final_stmt)
                          if fallback_result["targets"]:
                              # Merge fallback result
                              lineage_found = True
                              if fallback_result["sources"]: result["sources"] = list(set(result.get("sources",[]) + fallback_result["sources"]))
                              if fallback_result["targets"]: result["targets"] = list(set(result.get("targets",[]) + fallback_result["targets"]))
                              if fallback_result["relationships"]: result["relationships"] = result.get("relationships",[]) + fallback_result["relationships"]
                     
                     has_lineage = False
                     stmt_info = {
                         "sql": final_stmt,
                         "sources": [],
                         "targets": [],
                         "relationships": [],
                         "gsp_json": result.get("gsp_json")
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
                relations.append({
                    "target_table": dep_target,
                    "target_column": dep["target_column"],
                    "source_table": dep_source,
                    "source_column": dep["source_column"],
                    "dependency_type": dep["dependency_type"],
                    "source_file": dep.get("source_file"),
                    # Normalize for compatibility
                    "source": dep_source,
                    "target": dep_target
                })
                
                # 添加到 sources/targets（标准化后）
                sources.add(dep_source)
                targets.add(dep_target)
        except Exception as e:
            import logging
            logging.warning(f"Indirect flow parsing failed: {e}")
        
        # ===== 3. Schema Fallback (Directory Based) =====
        # If source_file provided, use parent directory as default schema
        import os
        if source_file:
            # Logic:
            # 1. 尝试获取父目录 (Level 1)
            # 2. 如果父目录名是通用类型 (sql, ddl 等)，则向上取一级 (Level 2)
            try:
                if self.default_schema:
                    default_schema = self.default_schema
                else:
                    parent_dir = os.path.dirname(source_file)
                    dir_name = os.path.basename(parent_dir)
                    
                    default_schema = dir_name
                    # User rule: "向上 2 级是用户名 ... 上一级用来区分sql还是 DD"
                    # If parent dir looks like a type indicator, go up
                    if dir_name.lower() in ["sql", "ddl", "dml", "scripts", "bin"]:
                        grandparent_dir = os.path.dirname(parent_dir)
                        default_schema = os.path.basename(grandparent_dir)
                
                # Avoid using common directory names as schema (like 'mysql', 'tests')
                # Add more exclusions as needed
                if default_schema.lower() not in ["mysql", "hive", "oracle", "tests", "bin", ".", "test"]:
                     
                     def apply_schema(table_name):
                         if not table_name: return table_name
                         # Skip if already has schema
                         if "." in table_name: return table_name
                         # Skip special tables
                         if table_name.upper() in ["DUAL"]: return table_name
                         
                         return f"{default_schema}.{table_name}"
                     
                     # Update sources
                     sources = {apply_schema(s) for s in sources}
                     
                     # Update targets
                     targets = {apply_schema(t) for t in targets}
                     
                     # Update relationships
                     for rel in relations:
                         # Update simple fields
                         if "source" in rel: rel["source"] = apply_schema(rel["source"])
                         if "target" in rel: rel["target"] = apply_schema(rel["target"])
                         if "source_table" in rel: rel["source_table"] = apply_schema(rel["source_table"])
                         if "target_table" in rel: rel["target_table"] = apply_schema(rel["target_table"])
            except Exception as e:
                import logging
                logging.warning(f"Schema fallback failed: {e}")

        return {
            "sources": list(sources), 
            "targets": list(targets),
            "relationships": relations,
            "statements": detailed_statements,
            "source_file": source_file,
            "gsp_json": gsp_json_list 
        }

    def _detect_dialect(self, sql: str) -> str:
        """
        Heuristic to detect SQL dialect (Oracle/Gbase, Hive, etc.)
        Returns 'oracle', 'hive', or None (keep default).
        """
        import re
        sql_upper = sql.upper()
        
        # 1. Oracle / GBase (PL/SQL features)
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
            r"\bEND\s*;\s*$"
        ]
        for pattern in oracle_keywords:
            if re.search(pattern, sql_upper):
                return "oracle"

        # 2. Hive / SparkSQL (Big Data features)
        hive_keywords = [
            r"\bPARTITIONED\s+BY\b",
            r"\bCLUSTERED\s+BY\b",
            r"\bROW\s+FORMAT\b",
            r"\bSTORED\s+AS\b",
            r"\bLATERAL\s+VIEW\b",
            r"\bEXPLODE\s*\(",
            r"\bASC\s+NULLS\s+(?:FIRST|LAST)\b",
            r"(?s)^\s*FROM\s+.*\bINSERT\s+INTO\b"  # Hive Multi-Table Insert syntax
        ]
        for pattern in hive_keywords:
            if re.search(pattern, sql_upper):
                return "hive"
                
        return None

    def get_column_lineage(self, sql: str, source_file: str = None) -> List[Dict[str, str]]:
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
        current_dialect = self.dialect
        detected_dialect = self._detect_dialect(sql)
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
             is_procedure = bool(re.search(r'(?i)CREATE\s+.*?PROCEDURE', stmt))
             
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
                     final_stmt = re.sub(r'(?i)(INSERT\s+INTO\s+)TABLE\s+', r'\1', final_stmt)
                     
                     # 1. Indirect Dependencies (SQLGlot) - Run on final clean statement
                     try:
                         # Use dynamic parser if dialect override occurred
                         indirect_parser_to_use = self.indirect_parser
                         if detected_switch:
                              from .indirect_flow_parser import IndirectFlowParser
                              indirect_parser_to_use = IndirectFlowParser(current_dialect)
            
                         indirect_deps = indirect_parser_to_use.parse(final_stmt, source_file)
                         for dep in indirect_deps:
                             dependencies.append({
                                 "target_table": dep["target_table"],
                                 "target_column": dep["target_column"],
                                 "source_table": dep["source_table"],
                                 "source_column": dep["source_column"],
                                 "dependency_type": dep["dependency_type"],
                                 "source_file": dep.get("source_file"),
                                 "snippet": dep.get("snippet")  # Pass through the SQL snippet
                             })
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
                        target_table = normalize_table_name(target_table) if target_table and target_table != "UNKNOWN" else target_table
                        target_column = target.get("column", "UNKNOWN")
                        
                        # Filter out TABLE level relationships (where column is unknown/empty)
                        if target_column in ["UNKNOWN", "", None]:
                            continue

                        for src in rel_sources:
                            source_table = src.get("parentName", "UNKNOWN")
                            source_table = normalize_table_name(source_table) if source_table and source_table != "UNKNOWN" else source_table
                            source_column = src.get("column", "UNKNOWN")
                            
                            dependencies.append({
                                "target_table": target_table,
                                "target_column": target_column,
                                "source_table": source_table,
                                "source_column": source_column,
                                "dependency_type": rel_type,    # 原始 GSP 类型
                                "source_file": source_file,     # 来源文件
                                "snippet": final_stmt           # 添加 SQL 片段
                            })
        
        # ===== Schema Fallback (Directory Based) =====
        import os
        if source_file:
             try:
                if self.default_schema:
                    default_schema = self.default_schema
                else:
                    parent_dir = os.path.dirname(source_file)
                    dir_name = os.path.basename(parent_dir)
                    
                    default_schema = dir_name
                    # User rule: If parent is type folder, go up one more
                    if dir_name.lower() in ["sql", "ddl", "dml", "scripts", "bin"]:
                        grandparent_dir = os.path.dirname(parent_dir)
                        default_schema = os.path.basename(grandparent_dir)
                
                if default_schema.lower() not in ["mysql", "hive", "oracle", "tests", "bin", ".", "test"]:
                     def apply_schema(table_name):
                         if not table_name or table_name == "UNKNOWN": return table_name
                         if "." in table_name: return table_name
                         if table_name.upper() in ["DUAL"]: return table_name
                         return f"{default_schema}.{table_name}"
                     
                     for dep in dependencies:
                         dep["target_table"] = apply_schema(dep["target_table"])
                         dep["source_table"] = apply_schema(dep["source_table"])
             except Exception:
                 pass
                    
        return dependencies

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
        target_matches = re.finditer(r"(?i)INSERT\s+INTO\s+(?:TABLE\s+)?([a-zA-Z0-9_$.]+)", sql)
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
            if src.upper() in ["SELECT", "LATERAL", "UNNEST", "VALUES", "(", "partition"]: 
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
                    "type": "fdd"
                })
                
        return {
            "sources": list(sources),
            "targets": list(targets),
            "relationships": relations,
            "fallback": True
        }
