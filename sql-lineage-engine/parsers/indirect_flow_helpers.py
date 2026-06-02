"""Helper mixin for sqlglot-based indirect lineage parsing."""

import re
from typing import Dict, List, Set, Tuple

from sqlglot import exp

from .indirect_flow_condition_helpers import IndirectFlowConditionHelperMixin


class IndirectFlowHelperMixin(IndirectFlowConditionHelperMixin):
    def _window_projection_alias(self, col: exp.Column, scope_expression):
        curr = col.parent
        seen_window = False
        while curr and curr is not scope_expression:
            if isinstance(curr, exp.Window):
                seen_window = True
            if seen_window and isinstance(curr, exp.Alias):
                return curr
            curr = curr.parent
        return None

    def _query_transform_target_column(self, col: exp.Column, projection_item) -> str:
        if not isinstance(projection_item, exp.QueryTransform):
            return None
        schema = projection_item.args.get("schema")
        output_columns = schema.expressions if schema else []
        if not output_columns:
            return None
        for index, expression in enumerate(projection_item.expressions):
            if expression is col and index < len(output_columns):
                return output_columns[index].name
        return None

    def _is_window_partition_column(self, col: exp.Column, scope_expression) -> bool:
        curr = col
        path = {curr}
        while curr and curr is not scope_expression:
            parent = curr.parent
            if isinstance(parent, exp.Window):
                for partition_expr in parent.args.get("partition_by") or []:
                    if partition_expr in path:
                        return True
            curr = parent
            if curr is not None:
                path.add(curr)
        return False

    def _is_inside_lateral(self, col: exp.Column, scope_expression) -> bool:
        curr = col.parent
        while curr and curr is not scope_expression:
            if isinstance(curr, exp.Lateral):
                return True
            curr = curr.parent
        return False

    def _extract_set_operation_star_dependencies(
        self, stmt, target_info, source_file, stmt_sql: str = None
    ) -> List[Dict]:
        deps = []
        expression = stmt.expression if isinstance(stmt, exp.Insert) else stmt
        if expression is None:
            return deps

        for set_operation in self._iter_set_operations(expression):
            left_select = set_operation.this
            right_select = set_operation.args.get("expression")
            if not isinstance(left_select, exp.Select) or not isinstance(right_select, exp.Select):
                continue
            if not any(isinstance(item, exp.Star) for item in right_select.expressions):
                continue

            source_tables = self._single_table_from_select(right_select)
            if len(source_tables) != 1:
                continue

            source_table = source_tables[0]
            source_columns = self._projection_names(left_select)
            target_columns = self._projection_names(left_select, target_info)
            for index, target_column in enumerate(target_columns):
                if not target_column:
                    continue
                source_column = source_columns[index] if index < len(source_columns) else target_column
                if not source_column:
                    source_column = target_column
                deps.append({
                    "source_table": source_table,
                    "source_column": source_column,
                    "target_table": target_info["table"],
                    "target_column": target_column,
                    "dependency_type": "fdr",
                    "neo4j_type": "FILTERS",
                    "context": "SET_OPERATION",
                    "lineage_origin": "set_operation",
                    "relation_level": "set_operation",
                    "source_file": source_file,
                    "snippet": stmt_sql,
                    "projectionIndex": index,
                    "projection_index": index,
                    "sourceExpression": source_column,
                    "source_expression": source_column,
                    "targetExpression": target_column,
                    "target_expression": target_column,
                })
        return deps

    def _extract_set_operation_direct_dependencies(
        self, stmt, target_info, source_file, stmt_sql: str = None
    ) -> List[Dict]:
        expression = stmt.expression if isinstance(stmt, exp.Insert) else stmt
        if not self._is_set_operation(expression):
            return []

        from sqlglot.optimizer.scope import build_scope

        selects = self._iter_set_operation_selects(expression)
        if not selects:
            return []

        target_columns = self._set_operation_target_columns(selects[0], target_info)
        deps = []
        for select in selects:
            branch_scope = build_scope(select)
            if not branch_scope:
                continue
            expanded_index = 0
            for index, projection in enumerate(select.expressions):
                if self._is_star_projection(projection):
                    source = self._star_projection_source(projection, branch_scope)
                    groups = self._expand_star_source_ref_groups(source) if source else []
                    for _, refs in groups:
                        if expanded_index >= len(target_columns) or not target_columns[expanded_index]:
                            expanded_index += 1
                            continue
                        for source_table, source_column in sorted(refs):
                            deps.append({
                                "source_table": source_table,
                                "source_column": source_column,
                                "target_table": target_info["table"],
                                "target_column": target_columns[expanded_index],
                                "dependency_type": "fdd",
                                "neo4j_type": "DERIVES_TO",
                                "context": "SET_OPERATION_SELECT",
                                "lineage_origin": "set_operation",
                                "relation_level": "column",
                                "source_file": source_file,
                                "snippet": stmt_sql,
                                "projectionIndex": expanded_index,
                                "projection_index": expanded_index,
                                "sourceExpression": self._safe_sql(projection),
                                "source_expression": self._safe_sql(projection),
                                "targetExpression": target_columns[expanded_index],
                                "target_expression": target_columns[expanded_index],
                            })
                        expanded_index += 1
                    continue

                if expanded_index >= len(target_columns) or not target_columns[expanded_index]:
                    expanded_index += 1
                    continue
                refs = self._resolve_expression_to_physical_refs(projection, branch_scope)
                for source_table, source_column in sorted(refs):
                    deps.append({
                        "source_table": source_table,
                        "source_column": source_column,
                        "target_table": target_info["table"],
                        "target_column": target_columns[expanded_index],
                        "dependency_type": "fdd",
                        "neo4j_type": "DERIVES_TO",
                        "context": "SET_OPERATION_SELECT",
                        "lineage_origin": "set_operation",
                        "relation_level": "column",
                        "source_file": source_file,
                        "snippet": stmt_sql,
                        "projectionIndex": expanded_index,
                        "projection_index": expanded_index,
                        "sourceExpression": self._safe_sql(projection),
                        "source_expression": self._safe_sql(projection),
                        "targetExpression": target_columns[expanded_index],
                        "target_expression": target_columns[expanded_index],
                    })
                expanded_index += 1
        return deps

    def _set_operation_target_columns(self, first_select, target_info=None) -> List[str]:
        target_columns = (target_info or {}).get("columns") or {}
        if target_columns:
            return [
                target_columns[index]
                for index in range(max(target_columns.keys()) + 1)
                if index in target_columns
            ]
        return self._projection_names(first_select, target_info)

    def _extract_select_star_dependencies(
        self, stmt, target_info, source_file, stmt_sql: str = None
    ) -> List[Dict]:
        from sqlglot.optimizer.scope import build_scope

        scope = build_scope(stmt)
        if not scope:
            return []
        expression = scope.expression
        if not isinstance(expression, exp.Select):
            return []

        deps = []
        target_index = 0
        for projection in expression.expressions:
            if not self._is_star_projection(projection):
                target_index += 1
                continue

            source = self._star_projection_source(projection, scope)
            if not source:
                continue

            output_groups = self._expand_star_source_ref_groups(source)
            if not output_groups:
                continue

            for output_column, refs in output_groups:
                target_column = self._star_target_column(
                    target_info, target_index, output_column
                )
                for source_table, source_column in sorted(refs):
                    deps.append({
                        "source_table": source_table,
                        "source_column": source_column,
                        "target_table": target_info["table"],
                        "target_column": target_column,
                        "dependency_type": "fdd",
                        "neo4j_type": "DERIVES_TO",
                        "context": "SELECT",
                        "lineage_origin": "star_projection",
                        "relation_level": "column",
                        "source_file": source_file,
                        "snippet": stmt_sql,
                        "projectionIndex": target_index,
                        "projection_index": target_index,
                        "sourceExpression": self._safe_sql(projection),
                        "source_expression": self._safe_sql(projection),
                        "targetExpression": target_column,
                        "target_expression": target_column,
                        "metadataMatched": True,
                        "validation_note": "Expanded star projection using metadata fields",
                    })
                target_index += 1
        return deps

    def _iter_set_operations(self, expression):
        if isinstance(expression, (exp.Except, exp.Intersect, exp.Union)):
            yield expression
        for child in expression.args.values():
            if isinstance(child, list):
                for item in child:
                    if isinstance(item, exp.Expression):
                        yield from self._iter_set_operations(item)
            elif isinstance(child, exp.Expression):
                yield from self._iter_set_operations(child)

    def _projection_names(self, select, target_info=None) -> List[str]:
        names = []
        target_columns = (target_info or {}).get("columns") or {}
        for index, projection in enumerate(select.expressions):
            if target_columns and index in target_columns:
                names.append(target_columns[index])
                continue
            output_name = self._projection_output_name(projection)
            names.append(output_name if output_name and output_name != "*" else None)
        return names

    def _resolve_unqualified_lateral_column_refs(
        self, column_name: str, scope
    ) -> Set[Tuple[str, str]]:
        refs = set()
        for source in scope.sources.values():
            if self._is_lateral_scope(source):
                refs.update(self._resolve_lateral_column_refs(column_name, source))
        return refs

    def _physical_tables_excluding_laterals(self, scope) -> Set[str]:
        tables = set()
        for source in scope.sources.values():
            if self._is_lateral_scope(source):
                continue
            tables.update(self._resolve_source_to_physical(source))
        return tables

    def _resolve_lateral_column_refs(self, column_name: str, lateral_scope) -> Set[Tuple[str, str]]:
        lateral = lateral_scope.expression
        output_names = self._lateral_output_names(lateral)
        if column_name.upper() not in {output_name.upper() for output_name in output_names}:
            return set()
        stack_refs = self._resolve_stack_lateral_refs(column_name, lateral, lateral_scope)
        if stack_refs is not None:
            return stack_refs
        return self._resolve_expression_to_physical_refs(lateral.this, lateral_scope)

    def _resolve_stack_lateral_refs(self, column_name: str, lateral, lateral_scope):
        function = lateral.this if lateral else None
        if not isinstance(function, exp.Anonymous):
            return None
        if str(function.this).lower() != "stack":
            return None

        output_names = self._lateral_output_names(lateral)
        try:
            output_index = [name.upper() for name in output_names].index(column_name.upper())
        except ValueError:
            return set()
        output_count = len(output_names)
        if output_count == 0:
            return set()

        refs = set()
        for index, expression in enumerate(function.expressions[1:]):
            if index % output_count == output_index:
                refs.update(self._resolve_expression_to_physical_refs(expression, lateral_scope))
        return refs

    def _lateral_output_names(self, lateral) -> List[str]:
        alias = lateral.args.get("alias") if lateral else None
        if not alias:
            return []
        columns = alias.args.get("columns") or []
        names = [column.name for column in columns if getattr(column, "name", None)]
        if names:
            return names
        alias_name = getattr(alias, "name", None)
        return [alias_name] if alias_name else []

    def _resolve_set_operation_column_refs(self, column_name: str, source_scope) -> Set[Tuple[str, str]]:
        """Resolve a derived UNION column to every branch projection at the same position."""
        selects = self._iter_set_operation_selects(source_scope.expression)
        if not selects:
            return set()

        first_select = selects[0]
        matching_indexes = [
            index
            for index, projection in enumerate(first_select.expressions)
            if (self._projection_output_name(projection) or "").upper() == column_name.upper()
        ]
        if not matching_indexes:
            return set()

        from sqlglot.optimizer.scope import build_scope

        refs = set()
        for index in matching_indexes:
            for select in selects:
                if index >= len(select.expressions):
                    continue
                branch_scope = build_scope(select)
                if not branch_scope:
                    continue
                refs.update(
                    self._resolve_expression_to_physical_refs(
                        select.expressions[index],
                        branch_scope,
                    )
                )
        return refs

    def _iter_set_operation_selects(self, expression) -> List[exp.Select]:
        if isinstance(expression, exp.Select):
            return [expression]
        if isinstance(expression, exp.Union):
            return (
                self._iter_set_operation_selects(expression.this)
                + self._iter_set_operation_selects(expression.expression)
            )
        if isinstance(expression, (exp.Except, exp.Intersect)):
            return self._iter_set_operation_selects(expression.this)
        return []

    def _is_set_operation(self, expression) -> bool:
        return isinstance(expression, (exp.Union, exp.Except, exp.Intersect))

    def _is_star_projection(self, projection) -> bool:
        if isinstance(projection, exp.Star):
            return True
        if isinstance(projection, exp.Column) and projection.name == "*":
            return True
        return False

    def _resolve_star_projection_column_refs(
        self, column_name: str, projection, source_scope
    ) -> Set[Tuple[str, str]]:
        if not self._is_star_projection(projection):
            return set()

        source = self._star_projection_source(projection, source_scope)
        if not source:
            return set()

        star_groups = self._expand_star_source_ref_groups(source)
        alias_columns = self._source_alias_columns(source_scope)
        if alias_columns and len(alias_columns) == len(star_groups):
            star_groups = [
                (alias_columns[index], refs)
                for index, (_, refs) in enumerate(star_groups)
            ]

        for output_name, refs in star_groups:
            if output_name.upper() == column_name.upper():
                return refs

        refs = set()
        for table_name in self._resolve_source_to_physical(source):
            try:
                validation = self.resolver.validate_column(table_name, column_name)
            except Exception:
                validation = {}

            if validation.get("exists") is False:
                continue
            refs.add((table_name, column_name))
        return refs

    def _expanded_projection_index(self, select, projection_index: int, scope) -> int:
        expanded_index = 0
        for projection in select.expressions[:projection_index]:
            if not self._is_star_projection(projection):
                expanded_index += 1
                continue

            source = self._star_projection_source(projection, scope)
            groups = self._expand_star_source_ref_groups(source) if source else []
            expanded_index += len(groups) if groups else 1
        return expanded_index

    def _star_projection_source(self, projection, scope):
        table_alias = getattr(projection, "table", None)
        if table_alias:
            return self._resolve_scope_source(scope, table_alias)

        sources = [
            source
            for source in scope.sources.values()
            if not self._is_lateral_scope(source)
        ]
        return sources[0] if len(sources) == 1 else None

    def _metadata_fields(self, table_name: str) -> List[str]:
        try:
            return list(self.resolver.get_table_fields(table_name) or [])
        except Exception:
            return []

    def _expand_star_source_ref_groups(self, source) -> List[Tuple[str, Set[Tuple[str, str]]]]:
        if self._is_scope(source) and isinstance(source.expression, exp.Select):
            groups = []
            for index, projection in enumerate(source.expression.expressions):
                if self._is_star_projection(projection):
                    nested_source = self._star_projection_source(projection, source)
                    if nested_source:
                        groups.extend(self._expand_star_source_ref_groups(nested_source))
                    continue

                output_name = self._source_scope_output_name(projection, index, source)
                refs = self._resolve_expression_to_physical_refs(projection, source)
                if output_name and refs:
                    groups.append((output_name, refs))
            alias_columns = self._source_alias_columns(source)
            if alias_columns and len(alias_columns) == len(groups):
                groups = [
                    (alias_columns[index], refs)
                    for index, (_, refs) in enumerate(groups)
                ]
            return groups

        physical_tables = self._resolve_source_to_physical(source)
        if len(physical_tables) != 1:
            return []

        source_table = next(iter(physical_tables))
        return [
            (field, {(source_table, field)})
            for field in self._metadata_fields(source_table)
        ]

    def _source_scope_output_name(self, projection, index: int, source_scope) -> str:
        alias_columns = self._source_alias_columns(source_scope)
        if index < len(alias_columns):
            return alias_columns[index]
        return self._projection_output_name(projection)

    def _source_alias_columns(self, source_scope) -> List[str]:
        expression = getattr(source_scope, "expression", None)
        parent = getattr(expression, "parent", None)
        if not isinstance(parent, (exp.CTE, exp.Subquery)):
            return []
        alias = parent.args.get("alias")
        columns = alias.args.get("columns") if alias else []
        columns = columns or []
        return [column.name for column in columns if getattr(column, "name", None)]

    def _star_target_column(self, target_info, index: int, source_column: str) -> str:
        target_columns = (target_info or {}).get("columns") or {}
        if index in target_columns:
            return target_columns[index]
        target_column = self._target_column_by_metadata(target_info["table"], index)
        return target_column or source_column

    def _is_lateral_scope(self, source) -> bool:
        return self._is_scope(source) and isinstance(source.expression, exp.Lateral)

    def _get_insert_target_table(self, insert_stmt: exp.Insert):
        target = insert_stmt.this
        if isinstance(target, exp.Schema):
            target = target.this
        return target if isinstance(target, exp.Table) else None

    def _get_insert_columns(self, insert_stmt: exp.Insert) -> Dict[int, str]:
        """Get target column mapping for INSERT statements."""
        columns = {}
        schema = insert_stmt.find(exp.Schema)
        if schema:
            for i, col in enumerate(schema.expressions):
                if isinstance(col, exp.Column):
                    columns[i] = col.name
                elif hasattr(col, "name"):
                    columns[i] = col.name
            target_table = schema.this
            partition = target_table.args.get("partition") if isinstance(target_table, exp.Table) else None
            if partition:
                next_index = len(columns)
                for partition_expr in partition.expressions:
                    if isinstance(partition_expr, exp.EQ):
                        continue
                    if isinstance(partition_expr, exp.Column):
                        columns[next_index] = partition_expr.name
                        next_index += 1
        else:
            target_table = self._get_insert_target_table(insert_stmt)
            dynamic_partitions = self._dynamic_partition_columns(target_table)
            select_exprs = insert_stmt.expression.expressions if isinstance(insert_stmt.expression, exp.Select) else []
            start_index = len(select_exprs) - len(dynamic_partitions)
            if start_index >= 0:
                for offset, partition_name in enumerate(dynamic_partitions):
                    columns[start_index + offset] = partition_name
        return columns

    def _dynamic_partition_columns(self, target_table) -> List[str]:
        partition = target_table.args.get("partition") if isinstance(target_table, exp.Table) else None
        if not partition:
            return []
        return [
            partition_expr.name
            for partition_expr in partition.expressions
            if isinstance(partition_expr, exp.Column)
        ]

    def _normalize_hive_insert_syntax(self, sql: str) -> str:
        if self.dialect not in ["hive", "spark"]:
            return sql
        return re.sub(
            r"(?is)(\bPARTITION\s*\([^)]*\))\s+IF\s+NOT\s+EXISTS\b",
            r"\1",
            sql,
        )

    def _is_hive_mti(self, sql: str) -> bool:
        """Detect Hive multi-table insert syntax: FROM source INSERT ... SELECT ..."""
        return bool(
            re.search(
                r"(?is)^\s*FROM\s+.+?\bINSERT\s+(?:INTO|OVERWRITE)\s+(?:TABLE\s+)?",
                sql,
            )
        )

    def _convert_mti_to_cte(self, sql: str) -> List[str]:
        """
        Convert Hive Multi-Table Insert to multiple CTE-based statements.
        """
        match = re.search(r"(?i)\s+INSERT\s+(?:INTO|OVERWRITE)\s+(?:TABLE\s+)?", sql)
        if not match:
            return [sql]

        split_index = match.start()
        from_part = sql[:split_index].strip()
        inserts_part = sql[split_index:].strip()

        if not from_part.upper().startswith("FROM"):
            return [sql]

        from_body = from_part[4:].strip()
        cte_def = from_body
        alias = "source_view"

        last_space = from_body.rfind(" ")
        if last_space != -1:
            candidate_alias = from_body[last_space + 1:]
            if re.match(r"^[a-zA-Z0-9_$]+$", candidate_alias):
                alias = candidate_alias
                cte_def = from_body[:last_space].strip()

        if not cte_def.startswith("("):
            cte_def = f"(SELECT * FROM {cte_def})"

        parts = re.split(
            r"(?i)(INSERT\s+(?:INTO|OVERWRITE)\s+(?:TABLE\s+)?)",
            inserts_part,
        )

        statements = []
        current_stmt = ""
        start_idx = 1 if len(parts) > 1 else 0

        for i in range(start_idx, len(parts)):
            p = parts[i]
            if re.match(r"(?i)INSERT\s+(?:INTO|OVERWRITE)\s+(?:TABLE\s+)?", p):
                if current_stmt:
                    statements.append(current_stmt)
                current_stmt = p
            else:
                current_stmt += p
        if current_stmt:
            statements.append(current_stmt)

        final_sqls = []
        for stmt in statements:
            stmt = stmt.strip()
            if stmt.endswith(";"):
                stmt = stmt[:-1]
            if not re.search(r"(?i)\bFROM\b", stmt):
                stmt = self._append_mti_source(stmt, alias)
            final_sqls.append(f"WITH {alias} AS {cte_def} {stmt}")

        return final_sqls

    def _append_mti_source(self, stmt: str, alias: str) -> str:
        """Insert the implicit Hive MTI source before WHERE/GROUP/HAVING clauses."""
        clause_match = re.search(
            r"(?i)\b(WHERE|GROUP\s+BY|HAVING|ORDER\s+BY|SORT\s+BY|DISTRIBUTE\s+BY|CLUSTER\s+BY|LIMIT|UNION|EXCEPT|INTERSECT)\b",
            stmt,
        )
        if clause_match:
            return (
                f"{stmt[:clause_match.start()].rstrip()} FROM {alias} "
                f"{stmt[clause_match.start():].lstrip()}"
            )
        return f"{stmt} FROM {alias}"
