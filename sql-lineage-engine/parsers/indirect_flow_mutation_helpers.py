"""SQLGlot helpers for mutations whose lineage is not represented by a SELECT scope."""

from typing import Dict, List, Optional, Set, Tuple

from sqlglot import exp


class IndirectFlowMutationHelperMixin:
    """Extract direct and control lineage for UPDATE, MERGE, and INSERT ALL/FIRST."""

    def _extract_mutation_dependencies(
        self, stmt, source_file: str, stmt_sql: str
    ) -> Optional[List[Dict]]:
        if isinstance(stmt, exp.Merge):
            return self._extract_merge_dependencies(stmt, source_file, stmt_sql)
        if isinstance(stmt, exp.Update):
            return self._extract_update_dependencies(stmt, source_file, stmt_sql)
        multitable_type = getattr(exp, "MultitableInserts", None)
        if multitable_type is not None and isinstance(stmt, multitable_type):
            return self._extract_multitable_insert_dependencies(
                stmt, source_file, stmt_sql
            )
        return None

    def _extract_merge_dependencies(self, stmt, source_file, stmt_sql) -> List[Dict]:
        target = stmt.this if isinstance(stmt.this, exp.Table) else stmt.find(exp.Table)
        using = stmt.args.get("using")
        if not target or not using:
            return []

        target_table = self._get_full_table_name(target)
        target_aliases = {
            value.upper()
            for value in (target.alias_or_name, target.name)
            if value
        }
        source_alias = (using.alias_or_name or "").upper()
        source_table = (
            self._get_full_table_name(using) if isinstance(using, exp.Table) else None
        )
        source_scope = self._build_query_scope(
            using.this if isinstance(using, exp.Subquery) else None
        )

        def source_refs(expression, include_target=False):
            refs = set()
            if not expression:
                return refs
            for column in expression.find_all(exp.Column):
                qualifier = (column.table or "").upper()
                if qualifier and qualifier in target_aliases:
                    if include_target:
                        refs.add((target_table, column.name))
                    continue
                if source_table and (not qualifier or qualifier == source_alias):
                    refs.add((source_table, column.name))
                    continue
                if source_scope is not None and (not qualifier or qualifier == source_alias):
                    refs.update(
                        self._resolve_projected_column_refs(column.name, source_scope)
                    )
            return refs

        dependencies = []
        on_expression = stmt.args.get("on")
        for source_table_name, source_column in sorted(source_refs(on_expression)):
            dependencies.append(
                self._mutation_dependency(
                    source_table_name,
                    source_column,
                    target_table,
                    "*",
                    "join",
                    "JOINS",
                    "MERGE_ON",
                    "merge_on",
                    source_file,
                    stmt_sql,
                    on_expression,
                    on_expression,
                )
            )

        whens = stmt.args.get("whens")
        for mutation_index, when in enumerate(
            getattr(whens, "expressions", []) or []
        ):
            branch = when.args.get("then")
            if isinstance(branch, exp.Update):
                for assignment in branch.expressions:
                    if not isinstance(assignment, exp.EQ):
                        continue
                    target_column = getattr(assignment.this, "name", None)
                    if not target_column:
                        continue
                    for source_table_name, source_column in sorted(
                        source_refs(assignment.expression, include_target=True)
                    ):
                        dependencies.append(
                            self._mutation_dependency(
                                source_table_name,
                                source_column,
                                target_table,
                                target_column,
                                "fdd",
                                "DERIVES_TO",
                                "MERGE_UPDATE",
                                "merge_update",
                                source_file,
                                stmt_sql,
                                assignment.expression,
                                assignment.this,
                                mutation_index,
                            )
                        )
            elif isinstance(branch, exp.Insert):
                target_columns = list(getattr(branch.this, "expressions", []) or [])
                values = branch.expression
                value_expressions = []
                if isinstance(values, exp.Values) and values.expressions:
                    value_expressions = list(values.expressions[0].expressions)
                elif isinstance(values, exp.Tuple):
                    value_expressions = list(values.expressions)
                for index, value_expression in enumerate(value_expressions):
                    if index < len(target_columns):
                        target_column = target_columns[index].name
                    else:
                        target_column = self._target_column_by_metadata(
                            target_table, index
                        ) or self._projection_output_name(value_expression)
                    if not target_column:
                        continue
                    for source_table_name, source_column in sorted(
                        source_refs(value_expression, include_target=True)
                    ):
                        dependencies.append(
                            self._mutation_dependency(
                                source_table_name,
                                source_column,
                                target_table,
                                target_column,
                                "fdd",
                                "DERIVES_TO",
                                "MERGE_INSERT",
                                "merge_insert",
                                source_file,
                                stmt_sql,
                                value_expression,
                                target_columns[index]
                                if index < len(target_columns)
                                else target_column,
                                mutation_index,
                            )
                        )

            condition = self._mutation_branch_condition(when)
            for source_table_name, source_column in sorted(source_refs(condition)):
                dependencies.append(
                    self._mutation_dependency(
                        source_table_name,
                        source_column,
                        target_table,
                        "*",
                        "fdr",
                        "FILTERS",
                        "MERGE_WHEN",
                        "merge_when",
                        source_file,
                        stmt_sql,
                        condition,
                        branch,
                        mutation_index,
                    )
                )

        # Predicates inside a USING subquery control every MERGE branch.
        if source_scope is not None and isinstance(source_scope.expression, exp.Select):
            where = source_scope.expression.args.get("where")
            if where:
                refs = self._resolve_expression_to_physical_refs(where.this, source_scope)
                for source_table_name, source_column in sorted(refs):
                    dependencies.append(
                        self._mutation_dependency(
                            source_table_name,
                            source_column,
                            target_table,
                            "*",
                            "fdr",
                            "FILTERS",
                            "MERGE_USING_WHERE",
                            "merge_using_where",
                            source_file,
                            stmt_sql,
                            where,
                            stmt,
                        )
                    )
        return dependencies

    def _extract_multitable_insert_dependencies(
        self, stmt, source_file, stmt_sql
    ) -> List[Dict]:
        source_query = stmt.args.get("source")
        source_scope = self._build_query_scope(source_query)
        if source_scope is None:
            return []

        dependencies = []
        for mutation_index, conditional in enumerate(stmt.expressions):
            insert = conditional.this
            if not isinstance(insert, exp.Insert):
                continue
            target = self._get_insert_target_table(insert)
            if not target:
                continue
            target_table = self._get_full_table_name(target)
            target_columns = self._get_insert_columns(insert)
            values = insert.expression
            value_expressions = []
            if isinstance(values, exp.Values) and values.expressions:
                value_expressions = list(values.expressions[0].expressions)

            for index, value_expression in enumerate(value_expressions):
                target_column = target_columns.get(index)
                if not target_column:
                    target_column = self._target_column_by_metadata(
                        target_table, index
                    ) or self._projection_output_name(value_expression)
                if not target_column:
                    continue
                refs = self._resolve_source_output_expression_refs(
                    value_expression, source_scope
                )
                for source_table_name, source_column in sorted(refs):
                    dependencies.append(
                        self._mutation_dependency(
                            source_table_name,
                            source_column,
                            target_table,
                            target_column,
                            "fdd",
                            "DERIVES_TO",
                            "INSERT_ALL",
                            "multitable_insert",
                            source_file,
                            stmt_sql,
                            value_expression,
                            target_column,
                            mutation_index,
                        )
                    )

            condition = conditional.args.get("expression")
            refs = self._resolve_source_output_expression_refs(condition, source_scope)
            for source_table_name, source_column in sorted(refs):
                dependencies.append(
                    self._mutation_dependency(
                        source_table_name,
                        source_column,
                        target_table,
                        "*",
                        "fdr",
                        "FILTERS",
                        "INSERT_ALL_WHEN",
                        "multitable_insert_when",
                        source_file,
                        stmt_sql,
                        condition,
                        target,
                        mutation_index,
                    )
                )
        return dependencies

    def _extract_update_dependencies(self, stmt, source_file, stmt_sql) -> List[Dict]:
        target = stmt.this if isinstance(stmt.this, exp.Table) else stmt.find(exp.Table)
        if not target:
            return []
        target_table = self._get_full_table_name(target)
        target_aliases = {
            value.upper()
            for value in (target.alias_or_name, target.name)
            if value
        }
        aliases = self._physical_table_aliases(stmt, target)
        dependencies = []

        for mutation_index, assignment in enumerate(stmt.expressions):
            if not isinstance(assignment, exp.EQ):
                continue
            target_column = getattr(assignment.this, "name", None)
            if not target_column:
                continue
            refs = self._update_value_refs(
                assignment.expression,
                aliases,
                target_table,
                target_aliases,
            )
            for source_table_name, source_column in sorted(refs):
                dependencies.append(
                    self._mutation_dependency(
                        source_table_name,
                        source_column,
                        target_table,
                        target_column,
                        "fdd",
                        "DERIVES_TO",
                        "UPDATE_SET",
                        "update_set",
                        source_file,
                        stmt_sql,
                        assignment.expression,
                        assignment.this,
                        mutation_index,
                    )
                )

        where = stmt.args.get("where")
        if where:
            refs = self._physical_column_refs(
                where,
                aliases,
                target_table,
                target_aliases,
                include_target=True,
            )
            for source_table_name, source_column in sorted(refs):
                dependencies.append(
                    self._mutation_dependency(
                        source_table_name,
                        source_column,
                        target_table,
                        "*",
                        "fdr",
                        "FILTERS",
                        "UPDATE_WHERE",
                        "update_where",
                        source_file,
                        stmt_sql,
                        where,
                        stmt,
                    )
                )
        return dependencies

    def _update_value_refs(
        self, expression, aliases, target_table, target_aliases
    ) -> Set[Tuple[str, str]]:
        refs = set()
        subqueries = list(expression.find_all(exp.Subquery))
        for subquery in subqueries:
            scope = self._build_query_scope(subquery.this)
            if scope is None or not isinstance(scope.expression, exp.Select):
                continue
            for projection in scope.expression.expressions:
                refs.update(
                    self._resolve_expression_to_physical_refs(projection, scope)
                )

        # Resolve columns outside scalar subqueries (e.g. SET total = total + delta).
        for column in expression.find_all(exp.Column):
            if any(column.find_ancestor(exp.Subquery) is subquery for subquery in subqueries):
                continue
            refs.update(
                self._physical_column_ref(
                    column,
                    aliases,
                    target_table,
                    target_aliases,
                    include_target=True,
                )
            )
        return refs

    def _resolve_source_output_expression_refs(self, expression, source_scope):
        refs = set()
        if not expression:
            return refs
        for column in expression.find_all(exp.Column):
            projected = self._resolve_projected_column_refs(column.name, source_scope)
            if projected:
                refs.update(projected)
            else:
                refs.update(
                    self._resolve_column_to_physical_refs(
                        column, source_scope, expression
                    )
                )
        return refs

    def _physical_column_refs(
        self,
        expression,
        aliases,
        target_table,
        target_aliases,
        include_target,
    ):
        refs = set()
        for column in expression.find_all(exp.Column):
            refs.update(
                self._physical_column_ref(
                    column,
                    aliases,
                    target_table,
                    target_aliases,
                    include_target,
                )
            )
        return refs

    def _physical_column_ref(
        self,
        column,
        aliases,
        target_table,
        target_aliases,
        include_target,
    ):
        qualifier = (column.table or "").upper()
        if qualifier in target_aliases or (not qualifier and not aliases):
            return {(target_table, column.name)} if include_target else set()
        source_table = aliases.get(qualifier)
        if source_table:
            return {(source_table, column.name)}
        return set()

    def _physical_table_aliases(self, expression, excluded_table=None):
        aliases = {}
        excluded_name = (
            self._get_full_table_name(excluded_table).upper()
            if excluded_table is not None
            else None
        )
        for table in expression.find_all(exp.Table):
            table_name = self._get_full_table_name(table)
            if excluded_name and table_name.upper() == excluded_name:
                continue
            for alias in (table.alias_or_name, table.name):
                if alias:
                    aliases[alias.upper()] = table_name
        return aliases

    @staticmethod
    def _mutation_branch_condition(when):
        for key in ("condition", "source", "expression", "this"):
            value = when.args.get(key)
            if isinstance(value, exp.Expression):
                return value
        return None

    @staticmethod
    def _build_query_scope(query):
        if query is None:
            return None
        from sqlglot.optimizer.scope import build_scope

        if isinstance(query, exp.Subquery):
            query = query.this
        return build_scope(query)

    def _mutation_dependency(
        self,
        source_table,
        source_column,
        target_table,
        target_column,
        dependency_type,
        neo4j_type,
        context,
        lineage_origin,
        source_file,
        stmt_sql,
        source_expression,
        target_expression,
        mutation_index=0,
    ):
        return {
            "source_table": source_table,
            "source_column": source_column,
            "target_table": target_table,
            "target_column": target_column,
            "dependency_type": dependency_type,
            "neo4j_type": neo4j_type,
            "context": context,
            "lineage_origin": lineage_origin,
            "relation_level": "column",
            "source_file": source_file,
            "snippet": stmt_sql,
            "mutationIndex": mutation_index,
            "mutation_index": mutation_index,
            "sourceExpression": self._safe_sql(source_expression),
            "source_expression": self._safe_sql(source_expression),
            "targetExpression": self._safe_sql(target_expression),
            "target_expression": self._safe_sql(target_expression),
        }
