"""
Indirect Flow Parser - 使用 sqlglot 提取间接数据流依赖

补充 GSP 的不足，提取：
- WHERE/HAVING 条件中的字段引用 (fdr)
- JOIN ON 条件中的字段引用 (join)
- GROUP BY 子句中的字段引用 (fdr)
- ORDER BY 子句中的字段引用 (fdr)
"""

import sqlglot
from sqlglot import exp
from typing import List, Dict, Any, Set, Optional
import logging


class IndirectFlowParser:
    """
    从 SQL 中提取间接数据流依赖：
    - WHERE/HAVING 条件
    - JOIN 条件
    - GROUP BY / ORDER BY 子句
    """
    
    # 方言映射
    DIALECT_MAP = {
        "mysql": "mysql",
        "postgresql": "postgres", 
        "postgres": "postgres",
        "oracle": "oracle",
        "sqlserver": "tsql",
        "hive": "hive",
        "spark": "spark",
        "presto": "presto",
        "trino": "trino",
        "bigquery": "bigquery",
        "snowflake": "snowflake",
    }
    
    def __init__(self, dialect: str = "mysql"):
        self.dialect = self.DIALECT_MAP.get(dialect.lower(), None)
    
    def parse(self, sql: str, source_file: str = None) -> List[Dict[str, Any]]:
        """解析 SQL 并使用 Scope 提取间接依赖关系。"""
        from sqlglot.optimizer.scope import build_scope
        import re
        
        dependencies = []
        
        # 首先移除所有路径的注释
        cleaned_sql = re.sub(r'/\*.*?\*/', '', sql, flags=re.DOTALL)
        cleaned_sql = re.sub(r'--.*?$', '', cleaned_sql, flags=re.MULTILINE)
        cleaned_sql = cleaned_sql.strip()
        
        # 检查输入是否通过像是单个 DML 语句
        # 如果是，跳过基于正则的提取，直接解析 (除非是 MTI)
        is_single_dml = bool(re.match(r'(?i)^\s*(INSERT|SELECT|CREATE)', cleaned_sql))
        
        if is_single_dml:
            # Check for MTI even if it looks like single DML (starts with FROM)
            if re.match(r'(?i)^\s*FROM\s+.*\bINSERT\s+INTO', cleaned_sql, re.DOTALL):
                 sql_statements = self._convert_mti_to_cte(cleaned_sql)
            else:
                 sql_statements = [cleaned_sql]
        else:
            sql_statements = self._extract_dml_statements(sql)
            
        self.local_table_registry = {} 

        for stmt_sql in sql_statements:
            try:
                # 解析单条语句
                statements = sqlglot.parse(stmt_sql, dialect=self.dialect)
                
                for stmt in statements:
                    if stmt is None: continue
                    
                    if isinstance(stmt, exp.Create):
                        self._register_ctas(stmt)
                    
                    target_info = self._get_target_table(stmt)
                    if not target_info:
                        continue
                        
                    # 构建作用域树
                    root = build_scope(stmt)
                    if not root:
                        continue
                        
                    # 遍历作用域（包括根节点）
                    # 注意：traverse() 返回生成器。通常 traverse 会生成所有作用域。
                    # 遍历作用域（包括根节点）
                    # Custom traversal to ensure all connected scopes (including CTEs/sources) are visited
                    all_scopes = self._traverse_all_scopes(root)
                    for scope in all_scopes:
                        # Pass the SQL statement for snippet storage
                        dependencies.extend(self._process_scope(scope, target_info, source_file, stmt_sql, stmt_obj=stmt))
                        
            except Exception as e:
                logging.debug(f"sqlglot parse error: {e}")
                continue
            
        return dependencies



    def _traverse_all_scopes(self, root):
        """Recursively collect all reachable scopes."""
        from sqlglot.optimizer.scope import Scope
        
        seen = set()
        scopes = []
        
        def walk(scope):
            if not isinstance(scope, Scope):
                return
            if id(scope) in seen: 
                return
            seen.add(id(scope))
            scopes.append(scope)
            
            # Traverse sources
            for source in scope.sources.values():
                if isinstance(source, Scope):
                    walk(source)
                    
            # Traverse CTEs (if any, depending on sqlglot version/structure)
            if hasattr(scope, 'cte_scopes'):
                for cte in scope.cte_scopes:
                    walk(cte)
            # Also explicit check for ctes list in some versions
            if hasattr(scope, 'ctes') and isinstance(scope.ctes, list):
                for cte in scope.ctes:
                    if isinstance(cte, Scope):
                        walk(cte)

            # Fallback to standard traverse just in case we miss something and it helps?
            # But standard traverse might reinvoke walk... avoid loop.
            
        walk(root)
        return scopes

    def _process_scope(self, scope, target_info, source_file, stmt_sql: str = None, stmt_obj=None) -> List[Dict]:
        deps = []
        
        # Determine if this scope corresponds to the direct source of the INSERT/CTAS
        is_top_level = False
        if stmt_obj:
             if isinstance(stmt_obj, exp.Insert) and scope.expression == stmt_obj.expression:
                 is_top_level = True
             elif isinstance(stmt_obj, exp.Create) and scope.expression == stmt_obj.expression:
                 is_top_level = True
        if not scope.expression:
            return deps
            
        target_table = target_info["table"]
        
        # 映射上下文类型
        context_map = {
            exp.Where: ("fdr", "FILTERS", "WHERE"),
            exp.Join: ("join", "JOINS", "JOIN"),
            exp.Group: ("fdr", "GROUPS", "GROUP_BY"),
            exp.Order: ("fdr", "ORDERS", "ORDER_BY"),
            exp.Having: ("fdr", "FILTERS", "HAVING"),
            exp.Case: ("CASE_WHEN", "CASE_WHEN", "CASE_WHEN"), # 支持 CASE WHEN
            exp.If: ("CASE_WHEN", "CASE_WHEN", "CASE_WHEN"),   # 支持 IF() 函数
            exp.Select: ("fdd", "DERIVES_TO", "SELECT"),       # 支持直接流 (SELECT)
        }
            
        for col in scope.columns:
            # 1. 确定上下文
            context_found = None
            context_name = "unknown"
            dep_type = "fdr" # default
            neo4j_type = "RELATED_TO"
            specific_target_column = "*"

            # 向上遍历以查找不同的上下文
            curr = col
            while curr and curr is not scope.expression:
                ancestor = curr.parent
                if type(ancestor) in context_map:
                    # CASE/IF 的细化处理
                    # 仅当在条件部分（'this'）时才视为 'CASE_WHEN'
                    if isinstance(ancestor, (exp.Case, exp.If)):
                        is_condition = False
                        if isinstance(ancestor, exp.If) and curr == ancestor.this:
                            is_condition = True
                        elif isinstance(ancestor, exp.Case) and curr == ancestor.this:
                            is_condition = True
                        
                        if not is_condition:
                            # 它在 THEN/ELSE/默认部分（结果）
                            # 跳过此上下文将其视为透明，允许它向上冒泡到 SELECT
                            curr = ancestor
                            continue

                    dep_type, neo4j_type, context_name = context_map[type(ancestor)]
                    context_found = (dep_type, neo4j_type, context_name)
                    break
                curr = ancestor
            
            # 如果未找到特定上下文，但范围是 Select，这意味着它在投影列表中
            if not context_found and isinstance(scope.expression, exp.Select):
                context_found = ("fdd", "DERIVES_TO", "SELECT")

            # Additional Check: If it's a CASE/IF, try to find the target column alias
                
            dep_type, neo4j_type, context_name = context_found
            
            # ===== 关键修改：跳过 SELECT 上下文（直接数据流），让 GSP 处理 =====
            # GSP 对嵌套查询的列映射更精确，sqlglot 只负责间接数据流
            if context_name == "SELECT":
                # 只有当它是顶层 SELECT（直接对应 INSERT 的结构）时，才尝试处理
                # 如果是子查询，则跳过，避免错误的列位置映射
                if not is_top_level:
                    continue
            
            # 额外检查：如果是 CASE/IF，尝试查找目标列别名
            if context_name == "CASE_WHEN":
                # Traverse up from the 'ancestor' (the Case node) to find Alias
                curr = ancestor
                while curr and curr is not scope.expression:
                    if isinstance(curr, exp.Alias):
                        specific_target_column = curr.alias
                        break
                    curr = curr.parent

            # INSERT ... SELECT 的全局位置映射
            # 如果我们要了解目标表结构 (target_info)，我们应该将投影索引映射到目标列
            # 这适用于任何上下文（SELECT、CASE_WHEN 等），只要它是投影的一部分
            if target_info and is_top_level:
                # 查找此列属于哪个投影项
                curr = col
                projection_item = None
                
                # 向上移动以查找 Select 语句的直接子项
                # 我们需要小心不要越过 scope.expression
                while curr.parent and curr.parent is not scope.expression:
                     curr = curr.parent
                
                projection_item = curr
                
                # 检查此项是否在 SELECT 列表中
                try:
                    if isinstance(scope.expression, exp.Select):
                        # 注意：表达式可能很大，但通常是 SELECT 列表
                        if projection_item in scope.expression.expressions:
                            idx = scope.expression.expressions.index(projection_item)
                            
                            # 1. 尝试位置映射 (INSERT INTO t (c1, c2) ...)
                            if target_info.get("columns") and idx in target_info["columns"]:
                                specific_target_column = target_info["columns"][idx]
                except ValueError:
                    pass

            # 如果仍然是 *，则针对 SELECT 上下文的回退（例如 create table as select .. alias）
            # 注意：上面现在跳过了 SELECT 上下文，这里保留用于 CASE_WHEN 等。
            if specific_target_column == "*" and not target_info:
                 # 如果不是 INSERT 的别名逻辑（上面已经处理了一些，但为了安全起见）
                 # 查找此列属于哪个投影项
                curr = col
                while curr.parent and curr.parent is not scope.expression:
                     curr = curr.parent
                if isinstance(curr, exp.Alias):
                     specific_target_column = curr.alias
                elif isinstance(curr, exp.Column):
                     specific_target_column = curr.name
            
            # 解析物理来源
            physical_tables = self._resolve_column_to_physical(col, scope)
            
            for table_name in physical_tables:
                deps.append({
                    "source_table": table_name,
                    "source_column": col.name,
                    "target_table": target_table,
                    "target_column": specific_target_column, # 使用解析后的目标
                    "dependency_type": dep_type,
                    "neo4j_type": neo4j_type,
                    "context": context_name,
                    "source_file": source_file,
                    "snippet": stmt_sql  # 存储完整的 SQL 语句
                })
             
        return deps

    def _resolve_column_to_physical(self, col: exp.Column, scope) -> Set[str]:
        """使用 Scope 将列解析为其物理源表。"""
        tables = set()
        
        table_alias = col.table
        
        # 如果找到显式别名
        if table_alias:
            source = scope.sources.get(table_alias)
            # 不区分大小写的回退
            if not source:
                for alias, src in scope.sources.items():
                    if alias.upper() == table_alias.upper():
                        source = src
                        break
            
            if source:
                tables.update(self._resolve_source_to_physical(source))
        else:
            # 无别名：如果 Scope 只有 1 个来源，则使用它
            if len(scope.sources) == 1:
                source = list(scope.sources.values())[0]
                tables.update(self._resolve_source_to_physical(source))
            # 否则是模糊的还是本地列引用？跳过还是尝试匹配？
            # 没有 schema，我们无法确定裸列属于哪个表。
            # 我们跳过以避免误报。

        return tables

    def _resolve_source_to_physical(self, source) -> Set[str]:
        """递归地将 Scope/表源解析为物理表名。"""
        tables = set()
        
        if isinstance(source, exp.Table):
            tables.add(self._get_full_table_name(source))
            
        elif type(source).__name__ == 'Scope': # Scope 对象
             # 递归进入子查询源
             for sub_source in source.sources.values():
                 tables.update(self._resolve_source_to_physical(sub_source))
                 
        elif hasattr(source, 'expression') and isinstance(source.expression, exp.Table):
             tables.add(self._get_full_table_name(source.expression))
             
        elif hasattr(source, 'this') and isinstance(source.this, exp.Table): # Alias(Table) 对象
             tables.add(self._get_full_table_name(source.this))

        return tables
    
    def _register_ctas(self, stmt):
        """解析 CTAS 语句并注册本地表"""
        # 提取表名
        table_node = stmt.find(exp.Table)
        if not table_node:
            return
            
        table_name = self._get_full_table_name(table_node)
        
        # 提取 SELECT 部分的源表
        select_node = stmt.find(exp.Select)
        if select_node:
            source_tables = self._find_source_tables(select_node)
            self.local_table_registry[table_name] = source_tables
            # 同时也处理不带 schema 的情况（如果创建时带 schema 但使用时不带）
            if "." in table_name:
                short_name = table_name.split(".")[-1]
                if short_name not in self.local_table_registry:
                    self.local_table_registry[short_name] = source_tables

    def _find_source_tables(self, node) -> Set[str]:
        """递归查找节点内部引用的所有真实表名"""
        tables = set()
        
        # 如果节点本身是 Table
        if isinstance(node, exp.Table):
            tables.add(self._get_full_table_name(node))
            return tables
            
        for table in node.find_all(exp.Table):
             tables.add(self._get_full_table_name(table))
             
        return tables

    def _extract_dml_statements(self, sql: str) -> List[str]:
        """
        从 SQL 脚本中提取 INSERT/SELECT 和 CREATE TABLE AS 语句。
        """
        import re
        
        # 移除注释
        sql = re.sub(r'/\*.*?\*/', '', sql, flags=re.DOTALL)
        sql = re.sub(r'--.*?$', '', sql, flags=re.MULTILINE)
        
        statements = []
        
        if re.match(r'(?i)^\s*FROM\s+.*\bINSERT\s+INTO', sql, re.DOTALL):
             return self._convert_mti_to_cte(sql)
        
        # 1. 提取 CREATE TABLE AS SELECT
        # 支持反引号 table 或 "table"
        ctas_pattern = r'(CREATE\s+TABLE\s+(?:[\w.]+|`[^`]+`|"[^"]+")\s+AS\s+SELECT\s+.+?(?:;|$))'
        ctas_stmts = re.findall(ctas_pattern, sql, re.IGNORECASE | re.DOTALL)
        statements.extend(ctas_stmts)

        # 2. 提取 INSERT INTO ... SELECT
        # 支持反引号 table 或 "table"
        insert_pattern = r'(INSERT\s+INTO\s+(?:[\w.]+|`[^`]+`|"[^"]+").*?SELECT\s+.+?)(?:;|\Z)'
        insert_stmts = re.findall(insert_pattern, sql, re.IGNORECASE | re.DOTALL)
        statements.extend(insert_stmts)
        
        if statements:
            return statements
        
        # 如果没有找到明确的 DML，返回原始 SQL 尝试解析
        if not statements:
            # 尝试检测 Hive Multi-Table Insert (FROM ... INSERT ...)
            if re.search(r'(?i)^\s*FROM\s+.*\bINSERT\s+INTO', sql, re.DOTALL):
                return self._convert_mti_to_cte(sql)
            return [sql]
            
        return statements

    def _convert_mti_to_cte(self, sql: str) -> List[str]:
        """
        Convert Hive Multi-Table Insert to multiple CTE-based statements
        Format: FROM (src) q INSERT INTO t1... INSERT INTO t2...
        To: WITH q AS (src) INSERT INTO t1...; WITH q AS (src) INSERT INTO t2...;
        """
        import re
        
        # Regex to find the start of the first INSERT
        match = re.search(r'(?i)\s+INSERT\s+INTO\s+', sql)
        if not match:
            return [sql]
            
        split_index = match.start()
        from_part = sql[:split_index].strip()
        inserts_part = sql[split_index:].strip()
        
        # 1. Parse FROM part
        if not from_part.upper().startswith("FROM"):
            return [sql]
            
        from_body = from_part[4:].strip()
        
        # Detect alias
        # Logic: FROM (...) alias OR FROM table alias
        # We assume the standard format used by our generator: FROM (...) alias
        cte_def = from_body
        alias = "source_view"
        
        # Simple heuristic for alias: last word after matching parens? 
        # But from_body might be complex.
        # Let's try to find the last space.
        last_space = from_body.rfind(' ')
        if last_space != -1:
             # Check if the part after space is a valid identifier and not a keyword
             candidate_alias = from_body[last_space+1:]
             # If it doesn't contain ')' and is alphanumeric
             if re.match(r'^[a-zA-Z0-9_$]+$', candidate_alias):
                 alias = candidate_alias
                 cte_def = from_body[:last_space].strip()

        # 2. Split INSERT part
        # Split by "INSERT INTO" but keep delimiter
        parts = re.split(r'(?i)(INSERT\s+INTO\s+)', inserts_part)
        
        statements = []
        current_stmt = ""
        # parts[0] is usually empty or whitespace if input started with INSERT INTO
        start_idx = 1 if len(parts) > 1 else 0
        
        for i in range(start_idx, len(parts)):
            p = parts[i]
            if re.match(r'(?i)INSERT\s+INTO\s+', p):
                if current_stmt:
                    statements.append(current_stmt)
                current_stmt = p
            else:
                current_stmt += p
        if current_stmt:
            statements.append(current_stmt)
            
        # 3. Construct final statements
        final_sqls = []
        for stmt in statements:
            stmt = stmt.strip()
            if stmt.endswith(";"):
                stmt = stmt[:-1]
                
            # Append " FROM alias" if not present (Hive MTI implies it)
            # Be careful not to append if it already has FROM (e.g. subquery usage)
            # our generator produces `SELECT *` or `SELECT col...` without FROM
            if not re.search(r'(?i)\bFROM\b', stmt):
                stmt = f"{stmt} FROM {alias}"
            
            full_sql = f"WITH {alias} AS {cte_def} {stmt}"
            final_sqls.append(full_sql)
            
        return final_sqls
    
    def _get_target_table(self, stmt) -> Optional[Dict[str, str]]:
        """获取目标表信息 (INSERT INTO / CREATE TABLE AS)"""
        # INSERT INTO
        if isinstance(stmt, exp.Insert):
            table = stmt.find(exp.Table)
            if table:
                return {
                    "table": self._get_full_table_name(table),
                    "columns": self._get_insert_columns(stmt)
                }
        # CREATE TABLE AS SELECT (可以视为目标表)
        elif isinstance(stmt, exp.Create):
            table = stmt.find(exp.Table)
            if table:
                return {
                    "table": self._get_full_table_name(table),
                    "columns": {} 
                }
        return None
    
    def _get_full_table_name(self, table: exp.Table) -> str:
        """获取完整表名 (schema.table)"""
        parts = []
        if table.catalog:
            parts.append(table.catalog)
        if table.db:
            parts.append(table.db)
        parts.append(table.name)
        return ".".join(parts)
    
    def _get_insert_columns(self, insert_stmt: exp.Insert) -> Dict[int, str]:
        """获取 INSERT 语句的目标列映射 (index -> column_name)"""
        columns = {}
        schema = insert_stmt.find(exp.Schema)
        if schema:
            for i, col in enumerate(schema.expressions):
                if isinstance(col, exp.Column):
                    columns[i] = col.name
                elif hasattr(col, 'name'):
                    columns[i] = col.name
        return columns

