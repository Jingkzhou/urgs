"""Condition dependency helpers for indirect lineage parsing."""

from typing import Dict, List

from sqlglot import exp


class IndirectFlowConditionHelperMixin:
    def _is_inside_subquery(self, col: exp.Column, scope_expression) -> bool:
        curr = col.parent
        while curr and curr is not scope_expression:
            if isinstance(curr, exp.Subquery):
                return True
            curr = curr.parent
        return False

    def _extract_filter_subquery_dependencies(
        self, stmt, target_info, source_file, stmt_sql: str = None
    ) -> List[Dict]:
        from sqlglot.optimizer.scope import build_scope

        deps = []
        seen = set()
        for container in list(stmt.find_all(exp.Where)) + list(stmt.find_all(exp.Having)):
            for select in self._filter_subquery_selects(container):
                scope = build_scope(select)
                if not scope:
                    continue
                expressions = list(select.expressions)
                if select.args.get("where"):
                    expressions.append(select.args["where"])
                if select.args.get("having"):
                    expressions.append(select.args["having"])
                for expression in expressions:
                    for source_table, source_column in sorted(
                        self._resolve_expression_to_physical_refs(expression, scope)
                    ):
                        key = (
                            source_table,
                            source_column,
                            target_info["table"],
                            self._safe_sql(expression),
                        )
                        if key in seen:
                            continue
                        seen.add(key)
                        deps.append({
                            "source_table": source_table,
                            "source_column": source_column,
                            "target_table": target_info["table"],
                            "target_column": "*",
                            "dependency_type": "fdr",
                            "neo4j_type": "FILTERS",
                            "context": "WHERE_SUBQUERY" if isinstance(container, exp.Where) else "HAVING_SUBQUERY",
                            "lineage_origin": "filter_subquery",
                            "relation_level": "column",
                            "source_file": source_file,
                            "snippet": stmt_sql,
                            "sourceExpression": self._safe_sql(expression),
                            "source_expression": self._safe_sql(expression),
                            "targetExpression": self._safe_sql(container),
                            "target_expression": self._safe_sql(container),
                        })
        return deps

    def _filter_subquery_selects(self, container) -> List[exp.Select]:
        selects = []
        for subquery in container.find_all(exp.Subquery):
            if isinstance(subquery.this, exp.Select):
                selects.append(subquery.this)
        for exists in container.find_all(exp.Exists):
            if isinstance(exists.this, exp.Select):
                selects.append(exists.this)
        return selects

    def _extract_having_dependencies(
        self, stmt, target_info, source_file, stmt_sql: str = None
    ) -> List[Dict]:
        from sqlglot.optimizer.scope import build_scope

        root = build_scope(stmt)
        if not root:
            return []

        deps = []
        seen = set()
        for scope in root.traverse():
            if not isinstance(scope.expression, exp.Select):
                continue
            having = scope.expression.args.get("having")
            if not having:
                continue
            for col in having.find_all(exp.Column):
                if self._is_inside_subquery(col, having):
                    continue
                refs = self._projection_alias_refs(col.name, scope) if not col.table else set()
                if not refs:
                    refs = self._resolve_column_to_physical_refs(col, scope, having)
                for source_table, source_column in sorted(refs):
                    key = (source_table, source_column, target_info["table"], self._safe_sql(having))
                    if key in seen:
                        continue
                    seen.add(key)
                    deps.append({
                        "source_table": source_table,
                        "source_column": source_column,
                        "target_table": target_info["table"],
                        "target_column": "*",
                        "dependency_type": "fdr",
                        "neo4j_type": "FILTERS",
                        "context": "HAVING",
                        "lineage_origin": "having",
                        "relation_level": "column",
                        "source_file": source_file,
                        "snippet": stmt_sql,
                        "sourceExpression": self._safe_sql(col),
                        "source_expression": self._safe_sql(col),
                        "targetExpression": self._safe_sql(having),
                        "target_expression": self._safe_sql(having),
                    })
        return deps

    def _extract_clause_alias_dependencies(
        self, stmt, target_info, source_file, stmt_sql: str = None
    ) -> List[Dict]:
        from sqlglot.optimizer.scope import build_scope

        root = build_scope(stmt)
        if not root:
            return []

        specs = [
            ("group", "GROUP_BY", "GROUPS"),
            ("order", "ORDER_BY", "ORDERS"),
            ("sort", "SORT_BY", "ORDERS"),
            ("distribute", "DISTRIBUTE_BY", "DISTRIBUTES"),
            ("cluster", "CLUSTER_BY", "CLUSTERS"),
        ]
        deps = []
        seen = set()
        for scope in root.traverse():
            if not isinstance(scope.expression, exp.Select):
                continue
            for arg_name, context, neo4j_type in specs:
                clause = scope.expression.args.get(arg_name)
                if not clause:
                    continue
                for col in clause.find_all(exp.Column):
                    if col.table or self._is_inside_subquery(col, clause):
                        continue
                    refs = self._projection_alias_refs(col.name, scope)
                    if not refs:
                        continue
                    for source_table, source_column in sorted(refs):
                        key = (
                            source_table,
                            source_column,
                            target_info["table"],
                            context,
                            self._safe_sql(clause),
                        )
                        if key in seen:
                            continue
                        seen.add(key)
                        deps.append({
                            "source_table": source_table,
                            "source_column": source_column,
                            "target_table": target_info["table"],
                            "target_column": "*",
                            "dependency_type": "fdr",
                            "neo4j_type": neo4j_type,
                            "context": context,
                            "lineage_origin": "clause_alias",
                            "relation_level": "column",
                            "source_file": source_file,
                            "snippet": stmt_sql,
                            "sourceExpression": self._safe_sql(col),
                            "source_expression": self._safe_sql(col),
                            "targetExpression": self._safe_sql(clause),
                            "target_expression": self._safe_sql(clause),
                        })
                for literal in clause.find_all(exp.Literal):
                    refs = self._projection_position_refs(literal, scope)
                    if not refs:
                        continue
                    for source_table, source_column in sorted(refs):
                        key = (
                            source_table,
                            source_column,
                            target_info["table"],
                            context,
                            self._safe_sql(clause),
                        )
                        if key in seen:
                            continue
                        seen.add(key)
                        deps.append({
                            "source_table": source_table,
                            "source_column": source_column,
                            "target_table": target_info["table"],
                            "target_column": "*",
                            "dependency_type": "fdr",
                            "neo4j_type": neo4j_type,
                            "context": context,
                            "lineage_origin": "clause_position",
                            "relation_level": "column",
                            "source_file": source_file,
                            "snippet": stmt_sql,
                            "sourceExpression": self._safe_sql(literal),
                            "source_expression": self._safe_sql(literal),
                            "targetExpression": self._safe_sql(clause),
                            "target_expression": self._safe_sql(clause),
                        })
        return deps

    def _projection_alias_refs(self, column_name: str, scope):
        if not isinstance(getattr(scope, "expression", None), exp.Select):
            return set()
        refs = set()
        for projection in scope.expression.expressions:
            output_name = self._projection_output_name(projection)
            if output_name and output_name.upper() == column_name.upper():
                refs.update(self._resolve_expression_to_physical_refs(projection, scope))
        return refs

    def _projection_position_refs(self, literal, scope):
        if not isinstance(getattr(scope, "expression", None), exp.Select):
            return set()
        if literal.args.get("is_string"):
            return set()
        try:
            position = int(literal.this)
        except (TypeError, ValueError):
            return set()
        index = position - 1
        if index < 0 or index >= len(scope.expression.expressions):
            return set()
        return self._resolve_expression_to_physical_refs(
            scope.expression.expressions[index],
            scope,
        )

    def _extract_join_using_dependencies(
        self, stmt, target_info, source_file, stmt_sql: str = None
    ) -> List[Dict]:
        from sqlglot.optimizer.scope import build_scope

        scope = build_scope(stmt)
        if not scope or not isinstance(scope.expression, exp.Select):
            return []

        deps = []
        seen = set()
        for join in scope.expression.find_all(exp.Join):
            using_columns = join.args.get("using") or []
            if not using_columns:
                continue

            right_alias = self._join_source_alias(join, scope)
            if not right_alias:
                continue
            right_source = self._resolve_scope_source(scope, right_alias)
            left_sources = self._join_left_sources(scope, right_alias)
            if not right_source or not left_sources:
                continue

            for using_column in using_columns:
                column_name = using_column.name
                refs = set()
                refs.update(self._resolve_column_from_source_refs(column_name, right_source))
                for _, left_source in left_sources:
                    refs.update(self._resolve_column_from_source_refs(column_name, left_source))

                for source_table, source_column in sorted(refs):
                    key = (
                        source_table,
                        source_column,
                        target_info["table"],
                        column_name,
                        self._safe_sql(join),
                    )
                    if key in seen:
                        continue
                    seen.add(key)
                    deps.append({
                        "source_table": source_table,
                        "source_column": source_column,
                        "target_table": target_info["table"],
                        "target_column": "*",
                        "dependency_type": "join",
                        "neo4j_type": "JOINS",
                        "context": "JOIN_USING",
                        "lineage_origin": "join_using",
                        "relation_level": "column",
                        "source_file": source_file,
                        "snippet": stmt_sql,
                        "sourceExpression": column_name,
                        "source_expression": column_name,
                        "targetExpression": self._safe_sql(join),
                        "target_expression": self._safe_sql(join),
                    })
        return deps

    def _join_left_sources(self, scope, right_alias: str):
        left_sources = []
        for alias, source in scope.sources.items():
            if alias == right_alias:
                break
            if not self._is_lateral_scope(source):
                left_sources.append((alias, source))
        return left_sources

    def _join_source_alias(self, join, scope) -> str:
        join_source = join.this
        for alias, source in scope.sources.items():
            if source is join_source:
                return alias
        if isinstance(join_source, exp.Table):
            join_table_name = self._get_full_table_name(join_source)
            for alias, source in scope.sources.items():
                if isinstance(source, exp.Table) and self._get_full_table_name(source) == join_table_name:
                    return alias
        return ""
