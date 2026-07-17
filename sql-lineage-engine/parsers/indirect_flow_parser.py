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
from typing import List, Dict, Any, Set, Optional, Tuple
import logging
from .indirect_flow_helpers import IndirectFlowHelperMixin
from .indirect_flow_mutation_helpers import IndirectFlowMutationHelperMixin
from utils.dialect_registry import resolve_dialect_profile
from utils.dialect_preprocessor import preprocess_for_sqlglot
from utils.lineage_identity import parser_statement_uid, statement_hash
from utils.splitter import SqlSplitter


class IndirectFlowParser(IndirectFlowMutationHelperMixin, IndirectFlowHelperMixin):
    """
    从 SQL 中提取间接数据流依赖：
    - WHERE/HAVING 条件
    - JOIN 条件
    - GROUP BY / ORDER BY 子句
    """
    
    def __init__(self, dialect: str = "mysql", resolver=None):
        self.dialect_profile = resolve_dialect_profile(dialect)
        self.dialect_name = self.dialect_profile.name
        self.dialect = self.dialect_profile.sqlglot_dialect
        if resolver is not None:
            self.resolver = resolver
        else:
            from utils.metadata_resolver import MetadataResolver
            self.resolver = MetadataResolver()
        self.local_table_registry = {}
        self._last_resolution = {}
    
    def parse(self, sql: str, source_file: str = None) -> List[Dict[str, Any]]:
        """解析 SQL 并使用 Scope 提取间接依赖关系。"""
        from sqlglot.optimizer.scope import build_scope
        import re

        dependencies = []
        
        # 首先移除注释，同时保留引号和 Oracle q-quote 内的文本。
        cleaned_sql = SqlSplitter.remove_comments(sql).strip()
        
        # 检查输入是否通过像是单个 DML 语句
        # 如果是，跳过基于正则的提取，直接解析 (除非是 MTI)
        is_single_dml = bool(re.match(r'(?i)^\s*(WITH|INSERT|SELECT|CREATE)', cleaned_sql))
        
        if is_single_dml:
            # Check for MTI even if it looks like single DML (starts with FROM)
            if self._is_hive_mti(cleaned_sql):
                 sql_statements = self._convert_mti_to_cte(cleaned_sql)
            else:
                 sql_statements = [cleaned_sql]
        else:
            sql_statements = self._extract_dml_statements(sql)

        statement_index = 0
        for stmt_sql in sql_statements:
            try:
                original_stmt_sql = stmt_sql
                parser_sql = self._normalize_hive_insert_syntax(stmt_sql)
                parser_sql = preprocess_for_sqlglot(
                    parser_sql, self.dialect_name
                )
                stmt_meta = {
                    "statementHash": statement_hash(original_stmt_sql),
                    "statement_hash": statement_hash(original_stmt_sql),
                    "parserStatementUid": parser_statement_uid(source_file, statement_index, original_stmt_sql),
                    "statementUid": parser_statement_uid(source_file, statement_index, original_stmt_sql),
                    "statement_uid": parser_statement_uid(source_file, statement_index, original_stmt_sql),
                    "statementIndex": statement_index,
                    "statement_index": statement_index,
                }
                statement_index += 1
                # 解析单条语句
                statements = sqlglot.parse(parser_sql, dialect=self.dialect)
                
                for stmt in statements:
                    if stmt is None: continue
                    
                    if isinstance(stmt, exp.Create):
                        self._register_ctas(stmt)

                    mutation_deps = self._extract_mutation_dependencies(
                        stmt, source_file, original_stmt_sql
                    )
                    if mutation_deps is not None:
                        for dep in mutation_deps:
                            dep.update(stmt_meta)
                        dependencies.extend(mutation_deps)
                        continue
                    
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
                        scope_deps = self._process_scope(scope, target_info, source_file, original_stmt_sql, stmt_obj=stmt)
                        for dep in scope_deps:
                            dep.update(stmt_meta)
                        dependencies.extend(scope_deps)
                    star_deps = self._extract_set_operation_star_dependencies(
                        stmt, target_info, source_file, original_stmt_sql
                    )
                    for dep in star_deps:
                        dep.update(stmt_meta)
                    dependencies.extend(star_deps)
                    set_direct_deps = self._extract_set_operation_direct_dependencies(
                        stmt, target_info, source_file, original_stmt_sql
                    )
                    for dep in set_direct_deps:
                        dep.update(stmt_meta)
                    dependencies.extend(set_direct_deps)
                    star_select_deps = self._extract_select_star_dependencies(
                        stmt, target_info, source_file, original_stmt_sql
                    )
                    for dep in star_select_deps:
                        dep.update(stmt_meta)
                    dependencies.extend(star_select_deps)
                    filter_subquery_deps = self._extract_filter_subquery_dependencies(
                        stmt, target_info, source_file, original_stmt_sql
                    )
                    for dep in filter_subquery_deps:
                        dep.update(stmt_meta)
                    dependencies.extend(filter_subquery_deps)
                    having_deps = self._extract_having_dependencies(
                        stmt, target_info, source_file, original_stmt_sql
                    )
                    for dep in having_deps:
                        dep.update(stmt_meta)
                    dependencies.extend(having_deps)
                    clause_alias_deps = self._extract_clause_alias_dependencies(
                        stmt, target_info, source_file, original_stmt_sql
                    )
                    for dep in clause_alias_deps:
                        dep.update(stmt_meta)
                    dependencies.extend(clause_alias_deps)
                    join_using_deps = self._extract_join_using_dependencies(
                        stmt, target_info, source_file, original_stmt_sql
                    )
                    for dep in join_using_deps:
                        dep.update(stmt_meta)
                    dependencies.extend(join_using_deps)
                        
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
            # Set operations keep their branch scopes outside ``sources``. The standard
            # traversal is therefore still required for UNION/EXCEPT/INTERSECT branches.
            
        walk(root)
        for nested_scope in root.traverse():
            walk(nested_scope)
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
        if isinstance(scope.expression, exp.Lateral):
            return deps
            
        target_table = target_info["table"]
        
        # 映射上下文类型
        context_map = {
            exp.Where: ("fdr", "FILTERS", "WHERE"),
            exp.Join: ("join", "JOINS", "JOIN"),
            exp.Group: ("fdr", "GROUPS", "GROUP_BY"),
            exp.Order: ("fdr", "ORDERS", "ORDER_BY"),
            exp.Sort: ("fdr", "ORDERS", "SORT_BY"),
            exp.Distribute: ("fdr", "DISTRIBUTES", "DISTRIBUTE_BY"),
            exp.Cluster: ("fdr", "CLUSTERS", "CLUSTER_BY"),
            exp.Having: ("fdr", "FILTERS", "HAVING"),
            exp.Case: ("CASE_WHEN", "CASE_WHEN", "CASE_WHEN"), # 支持 CASE WHEN
            exp.If: ("CASE_WHEN", "CASE_WHEN", "CASE_WHEN"),   # 支持 IF() 函数
            exp.Select: ("fdd", "DERIVES_TO", "SELECT"),       # 支持直接流 (SELECT)
        }
        clause_context_types = {
            exp.Where,
            exp.Join,
            exp.Group,
            exp.Order,
            exp.Sort,
            exp.Distribute,
            exp.Cluster,
            exp.Having,
        }
            
        for col in scope.columns:
            if self._is_inside_lateral(col, scope.expression):
                continue
            if self._is_inside_subquery(col, scope.expression):
                if not col.table or not self._resolve_scope_source(scope, col.table):
                    continue

            # 1. 确定上下文
            context_found = None
            context_name = "unknown"
            dep_type = "fdr" # default
            neo4j_type = "RELATED_TO"
            specific_target_column = "*"
            target_resolution_note = None
            target_metadata_matched = False
            projection_item = None
            projection_index = None

            # 向上遍历以查找不同的上下文
            curr = col
            while curr and curr is not scope.expression:
                ancestor = curr.parent
                if isinstance(ancestor, exp.Connect):
                    start_expression = ancestor.args.get("start")
                    is_start_with = bool(
                        start_expression
                        and any(
                            candidate is col
                            for candidate in start_expression.find_all(exp.Column)
                        )
                    )
                    if is_start_with:
                        context_found = ("fdr", "FILTERS", "START_WITH")
                    else:
                        context_found = ("join", "JOINS", "CONNECT_BY")
                    dep_type, neo4j_type, context_name = context_found
                    break
                if type(ancestor) in context_map:
                    # CASE/IF 的细化处理
                    # 仅当在条件部分（'this'）时才视为 'CASE_WHEN'
                    if isinstance(ancestor, (exp.Case, exp.If)):
                        is_condition = False
                        if isinstance(ancestor, exp.If) and curr == ancestor.this:
                            is_condition = True
                        elif isinstance(ancestor, exp.Case) and curr == ancestor.this:
                            is_condition = True

                        if is_condition:
                            outer = ancestor.parent
                            while outer and outer is not scope.expression:
                                if type(outer) in clause_context_types:
                                    context_found = context_map[type(outer)]
                                    dep_type, neo4j_type, context_name = context_found
                                    break
                                outer = outer.parent
                            if context_found:
                                break
                        
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
                
                # 向上移动以查找 Select 语句的直接子项
                # 我们需要小心不要越过 scope.expression
                while curr.parent and curr.parent is not scope.expression:
                     curr = curr.parent
                
                projection_item = curr
                
                # 检查此项是否在 SELECT 列表中
                try:
                    if isinstance(scope.expression, exp.Select):
                        # 注意：表达式可能很大，但通常是 SELECT 列表
                        idx = next(
                            (
                                i
                                for i, expr in enumerate(scope.expression.expressions)
                                if expr is projection_item
                            ),
                            None,
                        )
                        if idx is not None:
                            projection_index = self._expanded_projection_index(
                                scope.expression, idx, scope
                            )
                            # 1. 尝试位置映射 (INSERT INTO t (c1, c2) ...)
                            target_columns = target_info.get("columns") or {}
                            if projection_index in target_columns:
                                specific_target_column = target_columns[projection_index]
                            else:
                                inferred_column = self._target_column_by_metadata(
                                    target_table, projection_index
                                )
                                if inferred_column:
                                    specific_target_column = inferred_column
                                    target_resolution_note = (
                                        f"Target column inferred by metadata position {projection_index + 1}"
                                    )
                                    target_metadata_matched = True
                                elif context_name == "SELECT":
                                    projection_name = self._projection_output_name(projection_item)
                                    if projection_name and projection_name != "*":
                                        specific_target_column = projection_name
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

            window_projection = self._window_projection_alias(col, scope.expression)
            if window_projection is not None:
                projection_item = window_projection
                specific_target_column = window_projection.alias
                if context_name == "SELECT" and self._is_window_partition_column(col, scope.expression):
                    dep_type = "fdr"
                    neo4j_type = "GROUPS"
                    context_name = "WINDOW_PARTITION"
            transform_target_column = self._query_transform_target_column(col, projection_item)
            if transform_target_column:
                specific_target_column = transform_target_column

            # 解析物理来源。对子查询派生列（如 ROW_NUMBER() AS RN）必须返回
            # 派生表达式内部引用的真实字段，不能把外层别名 RN 当成物理字段。
            physical_refs = set()
            if context_name in {
                "GROUP_BY",
                "HAVING",
                "ORDER_BY",
                "SORT_BY",
                "DISTRIBUTE_BY",
                "CLUSTER_BY",
            } and not col.table:
                physical_refs = self._projection_alias_refs(col.name, scope)
            if not physical_refs:
                physical_refs = self._resolve_column_to_physical_refs(col, scope, projection_item)
            resolution = getattr(self, "_last_resolution", {}) or {}
            
            for table_name, source_column in sorted(physical_refs):
                dep = {
                    "source_table": table_name,
                    "source_column": source_column,
                    "target_table": target_table,
                    "target_column": specific_target_column, # 使用解析后的目标
                    "dependency_type": resolution.get("dependency_type") or dep_type,
                    "neo4j_type": resolution.get("neo4j_type") or neo4j_type,
                    "context": context_name,
                    "source_file": source_file,
                    "snippet": stmt_sql,  # 存储完整的 SQL 语句
                    "projectionIndex": projection_index,
                    "projection_index": projection_index,
                    "sourceExpression": self._safe_sql(col),
                    "source_expression": self._safe_sql(col),
                    "targetExpression": self._safe_sql(projection_item) if projection_item is not None else specific_target_column,
                    "target_expression": self._safe_sql(projection_item) if projection_item is not None else specific_target_column,
                }
                if resolution.get("confidence"):
                    dep["confidence"] = resolution.get("confidence")
                if resolution.get("validation_note"):
                    dep["validation_note"] = resolution.get("validation_note")
                if resolution.get("ambiguityCode"):
                    dep["ambiguityCode"] = resolution.get("ambiguityCode")
                if "metadataMatched" in resolution:
                    dep["metadataMatched"] = resolution.get("metadataMatched")
                if target_resolution_note:
                    dep["validation_note"] = self._join_notes(
                        dep.get("validation_note"),
                        target_resolution_note,
                    )
                    if target_metadata_matched and "metadataMatched" not in dep:
                        dep["metadataMatched"] = True
                deps.append(dep)
             
        return deps

    def _target_column_by_metadata(self, table_name: str, index: int) -> Optional[str]:
        if index is None or index < 0:
            return None
        try:
            fields = self.resolver.get_table_fields(table_name)
        except Exception:
            return None
        if index < len(fields):
            return fields[index]
        return None

    def _join_notes(self, *notes) -> str:
        clean = [str(note) for note in notes if note]
        return "; ".join(dict.fromkeys(clean))

    def _single_table_from_select(self, select) -> List[str]:
        if list(select.find_all(exp.Subquery)):
            return []
        tables = list(select.find_all(exp.Table))
        if len(tables) != 1:
            return []
        return [self._get_full_table_name(tables[0])]

    def _resolve_column_to_physical(self, col: exp.Column, scope, context_expression=None) -> Set[str]:
        """使用 Scope 将列解析为其物理源表。"""
        return {table_name for table_name, _ in self._resolve_column_to_physical_refs(col, scope, context_expression)}

    def _resolve_column_to_physical_refs(
        self, col: exp.Column, scope, context_expression=None
    ) -> Set[Tuple[str, str]]:
        """Resolve a SQL column to physical (table, column) pairs."""
        refs = set()
        self._last_resolution = {}

        if (
            self.dialect == "oracle"
            and not col.table
            and col.name.upper() in {"ROWNUM", "ROWID", "LEVEL"}
        ):
            self._last_resolution = {
                "confidence": "HIGH",
                "validation_note": f"Oracle pseudocolumn {col.name} is not a physical field",
                "ambiguityCode": "GENERATED_PSEUDOCOLUMN",
                "metadataMatched": False,
            }
            return refs
        
        table_alias = col.table
        
        # 如果找到显式别名
        if table_alias:
            source = self._resolve_scope_source(scope, table_alias)
            if source:
                refs.update(self._resolve_column_from_source_refs(col.name, source))
            elif self.dialect in ["hive", "spark"]:
                lateral_refs = self._resolve_lateral_qualifier_refs(table_alias, scope)
                if lateral_refs:
                    refs.update(lateral_refs)
                    return refs
                physical_tables = self._physical_tables_excluding_laterals(scope)
                if len(physical_tables) == 1:
                    refs.update((table_name, table_alias) for table_name in physical_tables)
        else:
            # 无别名：如果 Scope 只有 1 个来源，则使用它
            if len(scope.sources) == 1:
                source = list(scope.sources.values())[0]
                refs.update(self._resolve_column_from_source_refs(col.name, source))
            # 否则如果有多个来源，调用 MetadataResolver 查询表字段进行推断
            elif len(scope.sources) > 1:
                lateral_refs = self._resolve_unqualified_lateral_column_refs(
                    col.name, scope
                )
                if lateral_refs:
                    refs.update(lateral_refs)
                    return refs

                possible_tables = set()
                # 获取所有来源物理表
                for src in scope.sources.values():
                    possible_tables.update(self._resolve_source_to_physical(src))

                # 在这些可能物理表中查找该列
                matched_tables = set()
                for pt in possible_tables:
                    try:
                        val = self.resolver.validate_column(pt, col.name)
                        # 只有明确存在（HIGH）才加入，MEDIUM 且无 exists 标志视为不可达
                        if val.get("exists") is True and val.get("confidence") in ["HIGH", "MEDIUM"]:
                            matched_tables.add(pt)
                    except Exception:
                        pass  # API 不可达，跳过此表，不做推断

                if len(matched_tables) == 1:
                    self._last_resolution = {
                        "confidence": "HIGH",
                        "validation_note": f"Metadata resolved unqualified column {col.name}",
                        "metadataMatched": True,
                    }
                    refs.update((table_name, col.name) for table_name in matched_tables)
                elif len(matched_tables) > 1:
                    self._last_resolution = {
                        "confidence": "LOW",
                        "validation_note": (
                            f"Unqualified column {col.name} matched multiple source tables: "
                            + ", ".join(sorted(matched_tables))
                        ),
                        "ambiguityCode": "AMBIGUOUS_COLUMN",
                        "dependency_type": "er",
                        "neo4j_type": "REFERENCES",
                        "metadataMatched": True,
                    }
                    refs.update((table_name, col.name) for table_name in matched_tables)
                else:
                    physical_tables = self._physical_tables_excluding_laterals(scope)
                    if len(physical_tables) == 1:
                        refs.update((table_name, col.name) for table_name in physical_tables)
                    else:
                        refs.update(self._resolve_unqualified_column_by_context_refs(
                            col, scope, context_expression
                        ))
                # else: 无法确定来源，不产生血缘（避免假阳性）

        return refs

    def _resolve_scope_source(self, scope, table_alias: str):
        source = scope.sources.get(table_alias)
        if source:
            return source
        for alias, src in scope.sources.items():
            if alias.upper() == table_alias.upper():
                return src
        return None

    def _resolve_unqualified_column_by_context(self, col: exp.Column, scope, context_expression) -> Set[str]:
        """Resolve unqualified columns only when the surrounding expression has one clear alias."""
        return {
            table_name
            for table_name, _ in self._resolve_unqualified_column_by_context_refs(
                col, scope, context_expression
            )
        }

    def _resolve_unqualified_column_by_context_refs(
        self, col: exp.Column, scope, context_expression
    ) -> Set[Tuple[str, str]]:
        """Resolve unqualified columns only when the surrounding expression has one clear alias."""
        if context_expression is None:
            return set()

        aliases = {
            candidate.table
            for candidate in context_expression.find_all(exp.Column)
            if candidate is not col and candidate.table
        }
        if len(aliases) != 1:
            return set()

        alias = next(iter(aliases))
        source = self._resolve_scope_source(scope, alias)
        if not source:
            return set()
        return self._resolve_column_from_source_refs(col.name, source)

    def _resolve_column_from_source(self, column_name: str, source) -> Set[str]:
        """Resolve a column through a physical table or a subquery projection."""
        return {
            table_name
            for table_name, _ in self._resolve_column_from_source_refs(column_name, source)
        }

    def _resolve_column_from_source_refs(self, column_name: str, source) -> Set[Tuple[str, str]]:
        """Resolve a column through a physical table or a subquery projection."""
        if self._is_scope(source):
            if isinstance(source.expression, exp.Lateral):
                return self._resolve_lateral_column_refs(column_name, source)
            if isinstance(source.expression, exp.Select):
                return self._resolve_projected_column_refs(column_name, source)
            if self._is_set_operation(source.expression):
                return self._resolve_set_operation_column_refs(column_name, source)
        return {
            (table_name, column_name)
            for table_name in self._resolve_source_to_physical(source)
        }

    def _resolve_projected_column(self, column_name: str, source_scope) -> Set[str]:
        return {
            table_name
            for table_name, _ in self._resolve_projected_column_refs(column_name, source_scope)
        }

    def _resolve_projected_column_refs(self, column_name: str, source_scope) -> Set[Tuple[str, str]]:
        for index, projection in enumerate(source_scope.expression.expressions):
            star_refs = self._resolve_star_projection_column_refs(
                column_name, projection, source_scope
            )
            if star_refs:
                return star_refs
            output_name = self._source_scope_output_name(
                projection, index, source_scope
            )
            if output_name and output_name.upper() == column_name.upper():
                return self._resolve_expression_to_physical_refs(projection, source_scope)
        return set()

    def _projection_output_name(self, projection) -> str:
        if isinstance(projection, exp.Alias):
            return projection.alias
        if isinstance(projection, exp.Column):
            return projection.name
        return getattr(projection, "alias_or_name", "") or ""

    def _resolve_expression_to_physical(self, expression, scope) -> Set[str]:
        return {
            table_name
            for table_name, _ in self._resolve_expression_to_physical_refs(expression, scope)
        }

    def _resolve_expression_to_physical_refs(self, expression, scope) -> Set[Tuple[str, str]]:
        inner = expression.this if isinstance(expression, exp.Alias) else expression
        if isinstance(inner, exp.Case):
            value_expressions = [
                branch.args.get("true")
                for branch in inner.args.get("ifs") or []
                if branch.args.get("true") is not None
            ]
            if inner.args.get("default") is not None:
                value_expressions.append(inner.args.get("default"))
            columns = [
                column
                for value_expression in value_expressions
                for column in (
                    [value_expression]
                    if isinstance(value_expression, exp.Column)
                    else list(value_expression.find_all(exp.Column))
                )
            ]
        elif isinstance(inner, exp.If):
            value_expressions = [
                value_expression
                for value_expression in (
                    inner.args.get("true"),
                    inner.args.get("false"),
                )
                if value_expression is not None
            ]
            columns = [
                column
                for value_expression in value_expressions
                for column in (
                    [value_expression]
                    if isinstance(value_expression, exp.Column)
                    else list(value_expression.find_all(exp.Column))
                )
            ]
        else:
            columns = [inner] if isinstance(inner, exp.Column) else list(inner.find_all(exp.Column))
        refs = set()
        for source_col in columns:
            refs.update(self._resolve_column_to_physical_refs(source_col, scope, expression))
        return refs

    @staticmethod
    def _is_scope(source) -> bool:
        return type(source).__name__ == 'Scope' or hasattr(source, 'expression')

    def _safe_sql(self, expression) -> str:
        if expression is None:
            return ""
        try:
            return expression.sql(dialect=self.dialect)
        except Exception:
            return str(expression)

    def _resolve_source_to_physical(self, source) -> Set[str]:
        """递归地将 Scope/表源解析为物理表名。"""
        tables = set()
        
        if isinstance(source, exp.Table):
            table_name = self._get_full_table_name(source)
            registry_key = self._lookup_local_table_key(table_name)
            if registry_key:
                tables.update(self.local_table_registry.get(registry_key, set()))
            else:
                tables.add(table_name)
            
        elif type(source).__name__ == 'Scope': # Scope 对象
             if self._is_set_operation(source.expression):
                 for select in self._iter_set_operation_selects(source.expression):
                     from sqlglot.optimizer.scope import build_scope

                     branch_scope = build_scope(select)
                     if branch_scope:
                         tables.update(self._resolve_source_to_physical(branch_scope))
             else:
                 # 递归进入子查询源
                 for sub_source in source.sources.values():
                     tables.update(self._resolve_source_to_physical(sub_source))
                 
        elif hasattr(source, 'expression') and isinstance(source.expression, exp.Table):
             tables.add(self._get_full_table_name(source.expression))
             
        elif hasattr(source, 'this') and isinstance(source.this, exp.Table): # Alias(Table) 对象
             tables.add(self._get_full_table_name(source.this))

        return tables

    def _lookup_local_table_key(self, table_name: str) -> Optional[str]:
        if not table_name:
            return None
        candidates = [table_name]
        if "." in table_name:
            candidates.append(table_name.split(".")[-1])
        for candidate in candidates:
            for key in self.local_table_registry.keys():
                if key.upper() == candidate.upper():
                    return key
        return None
    
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
        
        if re.match(r'(?i)^\s*WITH\b', sql):
            return [sql.strip()]

        if self._is_hive_mti(sql):
             return self._convert_mti_to_cte(sql)
        
        # 1. 提取 CREATE TABLE AS SELECT
        # 支持反引号 table 或 "table"
        ctas_pattern = r'(CREATE\s+TABLE\s+(?:[\w.]+|`[^`]+`|"[^"]+")\s+AS\s+SELECT\s+.+?(?:;|$))'
        ctas_stmts = re.findall(ctas_pattern, sql, re.IGNORECASE | re.DOTALL)
        statements.extend(ctas_stmts)

        # 2. 提取 INSERT INTO ... SELECT
        # 支持反引号 table 或 "table"
        insert_pattern = r'(INSERT\s+(?:INTO|OVERWRITE)\s+(?:TABLE\s+)?(?:[\w.]+|`[^`]+`|"[^"]+").*?SELECT\s+.+?)(?:;|\Z)'
        insert_stmts = re.findall(insert_pattern, sql, re.IGNORECASE | re.DOTALL)
        statements.extend(insert_stmts)
        
        if statements:
            return statements
        
        # 如果没有找到明确的 DML，返回原始 SQL 尝试解析
        if not statements:
            # 尝试检测 Hive Multi-Table Insert (FROM ... INSERT ...)
            if self._is_hive_mti(sql):
                return self._convert_mti_to_cte(sql)
            return [sql]
            
        return statements

    def _get_target_table(self, stmt) -> Optional[Dict[str, str]]:
        """获取目标表信息 (INSERT INTO / CREATE TABLE AS)"""
        # INSERT INTO
        if isinstance(stmt, exp.Insert):
            table = self._get_insert_target_table(stmt)
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
