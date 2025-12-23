import logging
import sqlglot
from sqlglot import exp, optimizer
from typing import List, Dict, Any, Optional, Set

class SelectLineageParser:
    def __init__(self, dialect: str = "oracle"):
        self.dialect = dialect

    def parse(self, sql: str, source_file: str = None) -> List[Dict[str, Any]]:
        dependencies = []
        try:
            # removing comments
            import re
            sql = re.sub(r'/\*.*?\*/', '', sql, flags=re.DOTALL)
            sql = re.sub(r'--.*?$', '', sql, flags=re.MULTILINE)

            statements = sqlglot.parse(sql, dialect=self.dialect)
            for stmt in statements:
                if not stmt: continue
                
                # We only care about INSERT ... SELECT statements for column lineage
                if isinstance(stmt, exp.Insert):
                    deps = self._analyze_insert(stmt, source_file)
                    dependencies.extend(deps)
                    
        except Exception as e:
            logging.warning(f"SelectParsr failed: {e}")
            
        return dependencies

    def _analyze_insert(self, stmt: exp.Insert, source_file: str) -> List[Dict]:
        deps = []
        
        # 1. Identify Target Table and Columns
        target_table_node = stmt.find(exp.Table)
        if not target_table_node:
            return []
        
        target_table = self._get_full_name(target_table_node)
        
        # Get target columns from INSERT INTO table (col1, col2)
        # Note: If no columns specified, this is harder, but usually they are there.
        target_columns = []
        if isinstance(stmt.this, exp.Schema):
             # INSERT INTO table (col1, col2) ...
             for col in stmt.this.expressions:
                 if isinstance(col, exp.Identifier):
                     target_columns.append(col.this)
        
        # 2. Identify Source SELECT
        select_node = stmt.find(exp.Select)
        if not select_node:
            return []
            
        # 3. Map Target Cols to Source Exprs
        # expressions in SELECT list
        source_exprs = select_node.expressions
        
        if len(target_columns) > 0 and len(source_exprs) != len(target_columns):
             logging.warning(f"Column count mismatch: Target {len(target_columns)} vs Source {len(source_exprs)}")
             # Try best effort? 
             pass
             
        # Resolve aliases for this scope
        # We need a robust alias resolver that handles subqueries.
        # For now, let's use a simplified approach: recursively trace each expression
        
        for i, expr in enumerate(source_exprs):
            if i >= len(target_columns): break
            
            target_col = target_columns[i]
            
            # Trace origin of expr
            sources = self._trace_expression(expr, select_node)
            
            for src_table, src_col in sources:
                deps.append({
                    "target_table": target_table,
                    "target_column": target_col,
                    "source_table": src_table,
                    "source_column": src_col,
                    "dependency_type": "fdd", # Field Direct Dependency
                    "source_file": source_file
                })
                
        return deps

    def _trace_expression(self, expr, scope) -> Set[tuple]:
        """
        Trace an expression back to its physical source columns.
        Returns set of (table, column).
        """
        sources = set()
        
        # 1. Base case: Column reference
        if isinstance(expr, exp.Column):
            table_alias = expr.table
            col_name = expr.name
            
            # Resolve table alias
            real_sources = self._resolve_alias(table_alias, scope)
            
            for source_table, source_node in real_sources:
                if source_node is None:
                    # It's a physical table
                    sources.add((source_table, col_name))
                elif isinstance(source_node, (exp.Subquery, exp.Select)):
                    # It's a subquery, need to trace recursively
                    # Find the column in the subquery's SELECT list
                    sub_expr = self._find_column_in_subquery(col_name, source_node)
                    if sub_expr:
                        sources.update(self._trace_expression(sub_expr, source_node))
            
            return sources

        # 2. Recursive cases: Functions, Operations, Aliases
        if isinstance(expr, exp.Alias):
            return self._trace_expression(expr.this, scope)
            
        # Traverse children
        for child in expr.args.values():
            if isinstance(child, list):
                for item in child:
                    if isinstance(item, exp.Expression):
                        sources.update(self._trace_expression(item, scope))
            elif isinstance(child, exp.Expression):
                 sources.update(self._trace_expression(child, scope))
                 
        return sources

    def _resolve_alias(self, alias: str, scope: exp.Select) -> List[tuple]:
        """
        Resolve a table alias to (table_name, subquery_node).
        If subquery_node is None, it's a physical table.
        """
        if not alias:
            # Implicit alias... complex. Assume querying FROM directly.
            # Simplified: look at first FROM/JOIN
            pass 

        # Check FROM
        from_clause = scope.args.get("from")
        if from_clause:
            for item in from_clause.this.find_all(exp.Table, exp.Subquery):
                node_alias = item.alias or item.name # For Table, name is default alias?. No.
                if isinstance(item, exp.Table) and (item.alias == alias or item.name == alias):
                     return [(self._get_full_name(item), None)]
                if isinstance(item, exp.Subquery) and item.alias == alias:
                     return [("SUBQUERY", item.this)] # item.this is the inner SELECT

        # Check JOINs
        for join in scope.args.get("joins", []):
             item = join.this
             if isinstance(item, exp.Table) and (item.alias == alias or item.name == alias):
                 return [(self._get_full_name(item), None)]
             if isinstance(item, exp.Subquery) and item.alias == alias:
                 return [("SUBQUERY", item.this)]
                 
        return []

    def _find_column_in_subquery(self, col_name: str, subquery: exp.Select):
        # Handle SELECT *
        # This is hard without schema. But if we see SELECT *, we might assume pass-through?
        # But for specific columns:
        
        for expr in subquery.expressions:
            # Check explicit alias
            if isinstance(expr, exp.Alias) and expr.alias == col_name:
                return expr.this
            # Check implicit name (column)
            if isinstance(expr, exp.Column) and expr.name == col_name:
                return expr
                
        # If SELECT * present, and we didn't find specific alias... 
        # We assume it passes through. But tracing "passes through" requires knowing which table it came from inside.
        # This is the "SELECT X.*" case.
        for expr in subquery.expressions:
            if isinstance(expr, exp.Star):
                # Just return a dummy Column that forces recursion into the Star's table?
                # If Star has table (X.*), trace X.
                if isinstance(expr, exp.Column): # sqlglot parses T.* as Column(this=Star, table=T) sometimes? No, checking docs.
                    pass
                # A simple Star means all tables.
                # A Star with table (T.*) means table T.
                
                # Handling "SELECT X.* ... WHERE X.N=1"
                # If we are looking for COL1, and we have X.*, we assume COL1 comes from X.
                # So we pretend we found "X.COL1"
                if hasattr(expr, "table") and expr.table:
                    return exp.Column(this=exp.Identifier(this=col_name, quoted=False), table=exp.Identifier(this=expr.table, quoted=False))
                elif isinstance(expr, exp.Star):
                     # Global star. Which table? We don't know without schema.
                     # Heuristic: Pick first table in FROM?
                     pass
        
        return None

    def _get_full_name(self, table: exp.Table) -> str:
        parts = []
        if table.db: parts.append(table.db)
        parts.append(table.name)
        return ".".join(parts).upper()
