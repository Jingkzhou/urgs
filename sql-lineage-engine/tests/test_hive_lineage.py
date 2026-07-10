"""Hive SQL lineage regression tests."""

from unittest.mock import patch

from parsers.indirect_flow_parser import IndirectFlowParser


def test_hive_mti_overwrite_partition_resolves_source_and_projection_columns(mock_metadata_resolver):
    """Hive FROM ... INSERT OVERWRITE ... PARTITION should resolve implicit source."""
    sql = """
    FROM (
      SELECT id, amount, dt
        FROM ods.orders
       WHERE dt = '20260101'
    ) src
    INSERT OVERWRITE TABLE dwd.order_summary PARTITION (dt)
    SELECT id, sum(amount) AS total_amount, dt
     GROUP BY id, dt
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.orders", "amount", "dwd.order_summary", "total_amount", "fdd", "SELECT") in actual
    assert ("ods.orders", "dt", "dwd.order_summary", "*", "fdr", "WHERE") in actual
    assert ("ods.orders", "id", "dwd.order_summary", "*", "fdr", "GROUP_BY") in actual


def test_hive_mti_multiple_insert_branches_from_table_source(mock_metadata_resolver):
    """Hive MTI table source should expand multiple INTO/OVERWRITE branches."""
    sql = """
    FROM ods.orders src
    INSERT OVERWRITE TABLE dwd.order_summary
    SELECT src.id, src.amount
    INSERT INTO TABLE dwd.order_dt
    SELECT src.id, src.dt
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
        )
        for dep in deps
    }

    assert ("ods.orders", "amount", "dwd.order_summary", "amount", "fdd") in actual
    assert ("ods.orders", "dt", "dwd.order_dt", "dt", "fdd") in actual


def test_hive_lateral_view_explode_maps_output_to_input_column(mock_metadata_resolver):
    """Hive LATERAL VIEW output column should trace back to UDTF input column."""
    sql = """
    INSERT OVERWRITE TABLE dwd.item_fact
    SELECT id, item
      FROM ods.orders
     LATERAL VIEW explode(items) e AS item
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
        )
        for dep in deps
    }

    assert ("ods.orders", "id", "dwd.item_fact", "id", "fdd") in actual
    assert ("ods.orders", "items", "dwd.item_fact", "item", "fdd") in actual
    assert ("ods.orders", "items", "dwd.item_fact", "*", "fdd") not in actual


def test_hive_lateral_view_stack_maps_outputs_by_position(mock_metadata_resolver):
    """Hive stack output columns should map only to expressions in the same position."""
    sql = """
    INSERT OVERWRITE TABLE dwd.stack_fact
    SELECT id, key, val
      FROM ods.orders
     LATERAL VIEW stack(2, 'a', amount, 'b', discount) s AS key, val
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
        )
        for dep in deps
    }

    assert ("ods.orders", "amount", "dwd.stack_fact", "val", "fdd") in actual
    assert ("ods.orders", "discount", "dwd.stack_fact", "val", "fdd") in actual
    assert ("ods.orders", "amount", "dwd.stack_fact", "key", "fdd") not in actual
    assert ("ods.orders", "discount", "dwd.stack_fact", "key", "fdd") not in actual


def test_hive_struct_field_access_maps_to_struct_root_column(mock_metadata_resolver):
    """Hive struct.field access should map to the struct root column."""
    sql = """
    INSERT OVERWRITE TABLE dwd.user_fact
    SELECT user.id AS user_id, user.name AS user_name
      FROM ods.events
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("sourceExpression"),
        )
        for dep in deps
    }

    assert ("ods.events", "user", "dwd.user_fact", "user_id", "fdd", "user.id") in actual
    assert ("ods.events", "user", "dwd.user_fact", "user_name", "fdd", "user.name") in actual


def test_hive_with_insert_keeps_cte_scope_for_physical_lineage(mock_metadata_resolver):
    """Hive WITH ... INSERT must preserve CTE definitions during DML extraction."""
    sql = """
    WITH base AS (
      SELECT id, amount, dt
        FROM ods.orders
       WHERE dt = '20260101'
    )
    INSERT OVERWRITE TABLE dwd.order_summary
    SELECT id, sum(amount) AS total_amount
      FROM base
     GROUP BY id
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.orders", "amount", "dwd.order_summary", "total_amount", "fdd", "SELECT") in actual
    assert ("ods.orders", "dt", "dwd.order_summary", "*", "fdr", "WHERE") in actual
    assert not any(dep.get("source_table") == "base" for dep in deps)


def test_hive_cte_column_aliases_resolve_by_position(mock_metadata_resolver):
    """Hive CTE column aliases should map back to the CTE select projections."""
    sql = """
    WITH base(order_id, amt) AS (
      SELECT id, amount
        FROM ods.orders
    )
    INSERT OVERWRITE TABLE dwd.orders
    SELECT order_id, amt
      FROM base
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.orders", "id", "dwd.orders", "order_id", "fdd", "SELECT") in actual
    assert ("ods.orders", "amount", "dwd.orders", "amt", "fdd", "SELECT") in actual
    assert not any(dep.get("source_table") == "base" for dep in deps)


def test_hive_cte_column_aliases_resolve_select_star_by_position(mock_metadata_resolver):
    """Hive CTE aliases over SELECT * should map to physical columns by position."""
    sql = """
    WITH base(order_id, amt, ds) AS (
      SELECT *
        FROM ods.orders
    )
    INSERT OVERWRITE TABLE dwd.orders (order_id, amt, ds)
    SELECT order_id, amt, ds
      FROM base
    """

    with patch(
        "utils.metadata_resolver.MetadataResolver.get_table_fields",
        return_value=["id", "amount", "dt"],
    ):
        deps = IndirectFlowParser("hive").parse(sql)

    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.orders", "id", "dwd.orders", "order_id", "fdd", "SELECT") in actual
    assert ("ods.orders", "amount", "dwd.orders", "amt", "fdd", "SELECT") in actual
    assert ("ods.orders", "dt", "dwd.orders", "ds", "fdd", "SELECT") in actual
    assert not any(dep.get("source_table") == "base" for dep in deps)


def test_hive_subquery_column_aliases_resolve_by_position(mock_metadata_resolver):
    """Hive derived-table column aliases should map back to subquery projections."""
    sql = """
    INSERT OVERWRITE TABLE dwd.orders
    SELECT order_id, amt
      FROM (
        SELECT id, amount
          FROM ods.orders
      ) base(order_id, amt)
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.orders", "id", "dwd.orders", "order_id", "fdd", "SELECT") in actual
    assert ("ods.orders", "amount", "dwd.orders", "amt", "fdd", "SELECT") in actual
    assert not any(dep.get("source_table") == "base" for dep in deps)


def test_hive_insert_union_all_maps_each_branch_to_target_columns(mock_metadata_resolver):
    """Hive INSERT ... UNION ALL should map every branch by projection position."""
    sql = """
    INSERT OVERWRITE TABLE dwd.all_orders
    SELECT id, amount FROM ods.web_orders
    UNION ALL
    SELECT id, amount FROM ods.app_orders
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.web_orders", "amount", "dwd.all_orders", "amount", "fdd", "SET_OPERATION_SELECT") in actual
    assert ("ods.app_orders", "amount", "dwd.all_orders", "amount", "fdd", "SET_OPERATION_SELECT") in actual
    assert len([dep for dep in deps if dep.get("dependency_type") == "fdd"]) == 4


def test_hive_insert_union_all_star_maps_each_branch_to_target_columns(mock_metadata_resolver):
    """Hive UNION ALL SELECT * branches should expand direct column lineage."""
    sql = """
    INSERT OVERWRITE TABLE dwd.all_orders (id, amount, dt)
    SELECT * FROM ods.web_orders
    UNION ALL
    SELECT * FROM ods.app_orders
    """

    def fake_fields(table_name):
        return {
            "ods.web_orders": ["id", "amount", "dt"],
            "ods.app_orders": ["id", "amount", "dt"],
        }.get(table_name, [])

    with patch(
        "utils.metadata_resolver.MetadataResolver.get_table_fields",
        side_effect=fake_fields,
    ):
        deps = IndirectFlowParser("hive").parse(sql)

    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.web_orders", "id", "dwd.all_orders", "id", "fdd", "SET_OPERATION_SELECT") in actual
    assert ("ods.web_orders", "amount", "dwd.all_orders", "amount", "fdd", "SET_OPERATION_SELECT") in actual
    assert ("ods.web_orders", "dt", "dwd.all_orders", "dt", "fdd", "SET_OPERATION_SELECT") in actual
    assert ("ods.app_orders", "id", "dwd.all_orders", "id", "fdd", "SET_OPERATION_SELECT") in actual
    assert ("ods.app_orders", "amount", "dwd.all_orders", "amount", "fdd", "SET_OPERATION_SELECT") in actual
    assert ("ods.app_orders", "dt", "dwd.all_orders", "dt", "fdd", "SET_OPERATION_SELECT") in actual


def test_hive_window_order_by_maps_to_window_output_column(mock_metadata_resolver):
    """Hive window ORDER/PARTITION fields should affect the window output column."""
    sql = """
    INSERT OVERWRITE TABLE dwd.order_rank
    SELECT id,
           row_number() OVER (PARTITION BY user_id ORDER BY amount DESC) AS rn
      FROM ods.orders
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
            dep.get("neo4j_type"),
        )
        for dep in deps
    }

    assert ("ods.orders", "amount", "dwd.order_rank", "rn", "fdr", "ORDER_BY", "ORDERS") in actual
    assert ("ods.orders", "amount", "dwd.order_rank", "*", "fdr", "ORDER_BY", "ORDERS") not in actual
    assert ("ods.orders", "user_id", "dwd.order_rank", "rn", "fdr", "WINDOW_PARTITION", "GROUPS") in actual


def test_hive_sort_distribute_cluster_by_are_indirect_dependencies(mock_metadata_resolver):
    """Hive SORT/DISTRIBUTE/CLUSTER BY fields should be indirect target dependencies."""
    samples = [
        (
            """
            INSERT OVERWRITE TABLE dwd.orders_sorted
            SELECT id, amount FROM ods.orders SORT BY user_id
            """,
            "dwd.orders_sorted",
            "SORT_BY",
            "ORDERS",
        ),
        (
            """
            INSERT OVERWRITE TABLE dwd.orders_dist
            SELECT id, amount FROM ods.orders DISTRIBUTE BY user_id
            """,
            "dwd.orders_dist",
            "DISTRIBUTE_BY",
            "DISTRIBUTES",
        ),
        (
            """
            INSERT OVERWRITE TABLE dwd.orders_cluster
            SELECT id, amount FROM ods.orders CLUSTER BY user_id
            """,
            "dwd.orders_cluster",
            "CLUSTER_BY",
            "CLUSTERS",
        ),
    ]

    for sql, target_table, context, neo4j_type in samples:
        deps = IndirectFlowParser("hive").parse(sql)
        actual = {
            (
                dep.get("source_table"),
                dep.get("source_column"),
                dep.get("target_table"),
                dep.get("target_column"),
                dep.get("dependency_type"),
                dep.get("context"),
                dep.get("neo4j_type"),
            )
            for dep in deps
        }

        assert ("ods.orders", "user_id", target_table, "*", "fdr", context, neo4j_type) in actual
        assert ("ods.orders", "user_id", target_table, "*", "fdd", "SELECT", "DERIVES_TO") not in actual


def test_hive_where_in_subquery_uses_subquery_source_as_filter_dependency(mock_metadata_resolver):
    """Hive IN subquery fields should not be resolved against the outer source."""
    sql = """
    INSERT OVERWRITE TABLE dwd.orders
    SELECT id
      FROM ods.orders
     WHERE id IN (SELECT order_id FROM ods.blacklist)
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.blacklist", "order_id", "dwd.orders", "*", "fdr", "WHERE_SUBQUERY") in actual
    assert ("ods.orders", "order_id", "dwd.orders", "*", "fdd", "SELECT") not in actual


def test_hive_exists_subquery_condition_adds_inner_filter_dependency(mock_metadata_resolver):
    """Hive EXISTS subquery predicates should include inner physical sources."""
    sql = """
    INSERT OVERWRITE TABLE dwd.orders
    SELECT id
      FROM ods.orders o
     WHERE EXISTS (
       SELECT 1
         FROM ods.blacklist b
        WHERE b.order_id = o.id
     )
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.blacklist", "order_id", "dwd.orders", "*", "fdr", "WHERE_SUBQUERY") in actual
    assert ("ods.orders", "id", "dwd.orders", "*", "fdr", "WHERE") in actual


def test_hive_having_aggregate_adds_filter_dependency(mock_metadata_resolver):
    """Hive HAVING aggregate expressions should create filter dependencies."""
    sql = """
    INSERT OVERWRITE TABLE dwd.user_summary
    SELECT user_id, sum(amount) AS total_amount
      FROM ods.orders
     GROUP BY user_id
    HAVING sum(amount) > 100
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.orders", "amount", "dwd.user_summary", "*", "fdr", "HAVING") in actual
    assert ("ods.orders", "user_id", "dwd.user_summary", "*", "fdr", "GROUP_BY") in actual


def test_hive_group_by_alias_resolves_to_projection_source(mock_metadata_resolver):
    """Hive GROUP BY aliases should resolve to the aliased projection source."""
    sql = """
    INSERT OVERWRITE TABLE dwd.orders
    SELECT user_id AS uid, sum(amount) AS total
      FROM ods.orders
     GROUP BY uid
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.orders", "user_id", "dwd.orders", "*", "fdr", "GROUP_BY") in actual
    assert ("ods.orders", "uid", "dwd.orders", "*", "fdr", "GROUP_BY") not in actual


def test_hive_order_sort_distribute_cluster_aliases_are_indirect_dependencies(mock_metadata_resolver):
    """Hive ordering/distribution aliases should resolve to projection sources."""
    samples = [
        (
            """
            INSERT OVERWRITE TABLE dwd.orders
            SELECT id, amount AS amt FROM ods.orders ORDER BY amt
            """,
            "amount",
            "ORDER_BY",
            "ORDERS",
        ),
        (
            """
            INSERT OVERWRITE TABLE dwd.orders
            SELECT id, amount AS amt FROM ods.orders SORT BY amt
            """,
            "amount",
            "SORT_BY",
            "ORDERS",
        ),
        (
            """
            INSERT OVERWRITE TABLE dwd.orders
            SELECT id, user_id AS uid FROM ods.orders DISTRIBUTE BY uid
            """,
            "user_id",
            "DISTRIBUTE_BY",
            "DISTRIBUTES",
        ),
        (
            """
            INSERT OVERWRITE TABLE dwd.orders
            SELECT id, user_id AS uid FROM ods.orders CLUSTER BY uid
            """,
            "user_id",
            "CLUSTER_BY",
            "CLUSTERS",
        ),
    ]

    for sql, source_column, context, neo4j_type in samples:
        deps = IndirectFlowParser("hive").parse(sql)
        actual = {
            (
                dep.get("source_table"),
                dep.get("source_column"),
                dep.get("target_table"),
                dep.get("target_column"),
                dep.get("dependency_type"),
                dep.get("context"),
                dep.get("neo4j_type"),
            )
            for dep in deps
        }

        assert ("ods.orders", source_column, "dwd.orders", "*", "fdr", context, neo4j_type) in actual


def test_hive_clause_positions_are_indirect_dependencies(mock_metadata_resolver):
    """Hive positional GROUP/ORDER/SORT/DISTRIBUTE/CLUSTER references should resolve to projections."""
    samples = [
        (
            """
            INSERT OVERWRITE TABLE dwd.orders
            SELECT user_id, sum(amount) AS total FROM ods.orders GROUP BY 1
            """,
            "user_id",
            "GROUP_BY",
            "GROUPS",
        ),
        (
            """
            INSERT OVERWRITE TABLE dwd.orders
            SELECT id, amount FROM ods.orders ORDER BY 2
            """,
            "amount",
            "ORDER_BY",
            "ORDERS",
        ),
        (
            """
            INSERT OVERWRITE TABLE dwd.orders
            SELECT id, amount FROM ods.orders SORT BY 2
            """,
            "amount",
            "SORT_BY",
            "ORDERS",
        ),
        (
            """
            INSERT OVERWRITE TABLE dwd.orders
            SELECT id, user_id FROM ods.orders DISTRIBUTE BY 2
            """,
            "user_id",
            "DISTRIBUTE_BY",
            "DISTRIBUTES",
        ),
        (
            """
            INSERT OVERWRITE TABLE dwd.orders
            SELECT id, user_id FROM ods.orders CLUSTER BY 2
            """,
            "user_id",
            "CLUSTER_BY",
            "CLUSTERS",
        ),
    ]

    for sql, source_column, context, neo4j_type in samples:
        deps = IndirectFlowParser("hive").parse(sql)
        actual = {
            (
                dep.get("source_table"),
                dep.get("source_column"),
                dep.get("target_table"),
                dep.get("target_column"),
                dep.get("dependency_type"),
                dep.get("context"),
                dep.get("neo4j_type"),
            )
            for dep in deps
        }

        assert ("ods.orders", source_column, "dwd.orders", "*", "fdr", context, neo4j_type) in actual


def test_hive_having_alias_resolves_to_projection_source(mock_metadata_resolver):
    """Hive HAVING aliases should resolve to the aliased aggregate source."""
    sql = """
    INSERT OVERWRITE TABLE dwd.orders
    SELECT user_id, sum(amount) AS total
      FROM ods.orders
     GROUP BY user_id
    HAVING total > 100
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.orders", "amount", "dwd.orders", "*", "fdr", "HAVING") in actual
    assert ("ods.orders", "total", "dwd.orders", "*", "fdr", "HAVING") not in actual


def test_hive_transform_schema_maps_inputs_by_position(mock_metadata_resolver):
    """Hive TRANSFORM output schema should map input columns by position."""
    sql = """
    INSERT OVERWRITE TABLE dwd.t
    SELECT transform(id, amount) USING 'cat' AS (id, amount)
      FROM ods.orders
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.orders", "id", "dwd.t", "id", "fdd", "SELECT") in actual
    assert ("ods.orders", "amount", "dwd.t", "amount", "fdd", "SELECT") in actual
    assert ("ods.orders", "amount", "dwd.t", "id", "fdd", "SELECT") not in actual


def test_hive_insert_column_list_appends_dynamic_partition_columns(mock_metadata_resolver):
    """Hive explicit target columns should be followed by dynamic partition columns."""
    sql = """
    INSERT OVERWRITE TABLE dwd.orders PARTITION (dt) (order_id, amt)
    SELECT id, amount, dt
      FROM ods.orders
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.orders", "id", "dwd.orders", "order_id", "fdd", "SELECT") in actual
    assert ("ods.orders", "amount", "dwd.orders", "amt", "fdd", "SELECT") in actual
    assert ("ods.orders", "dt", "dwd.orders", "dt", "fdd", "SELECT") in actual
    assert ("ods.orders", "dt", "dwd.orders", "*", "fdd", "SELECT") not in actual


def test_hive_dynamic_partition_overrides_metadata_position(mock_metadata_resolver):
    """Hive dynamic partition columns should map by SELECT tail position."""
    sql = """
    INSERT OVERWRITE TABLE dwd.orders PARTITION (dt='20260101', region)
    SELECT id, amount, region
      FROM ods.orders
    """

    with patch(
        "utils.metadata_resolver.MetadataResolver.get_table_fields",
        return_value=["id", "amount", "dt", "region"],
    ):
        deps = IndirectFlowParser("hive").parse(sql)

    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.orders", "region", "dwd.orders", "region", "fdd", "SELECT") in actual
    assert ("ods.orders", "region", "dwd.orders", "dt", "fdd", "SELECT") not in actual


def test_hive_insert_partition_if_not_exists_is_parsed(mock_metadata_resolver):
    """Hive INSERT PARTITION ... IF NOT EXISTS should still produce lineage."""
    sql = """
    INSERT OVERWRITE TABLE dwd.orders PARTITION (dt='20260101') IF NOT EXISTS
    SELECT id, amount
      FROM ods.orders
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.orders", "id", "dwd.orders", "id", "fdd", "SELECT") in actual
    assert ("ods.orders", "amount", "dwd.orders", "amount", "fdd", "SELECT") in actual


def test_hive_insert_overwrite_directory_does_not_use_source_as_target(mock_metadata_resolver):
    """Hive directory output has no table target and should not create false table lineage."""
    sql = """
    INSERT OVERWRITE DIRECTORY '/tmp/out'
    SELECT id, amount
      FROM ods.orders
     WHERE dt = '20260101'
    """

    deps = IndirectFlowParser("hive").parse(sql)

    assert deps == []


def test_hive_insert_select_star_expands_from_metadata_fields(mock_metadata_resolver):
    """Hive SELECT * should expand to column lineage when source fields are known."""
    sql = """
    INSERT OVERWRITE TABLE dwd.orders (id, amount, dt)
    SELECT *
      FROM ods.orders
    """

    with patch(
        "utils.metadata_resolver.MetadataResolver.get_table_fields",
        return_value=["id", "amount", "dt"],
    ):
        deps = IndirectFlowParser("hive").parse(sql)

    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
            dep.get("lineage_origin"),
        )
        for dep in deps
    }

    assert ("ods.orders", "id", "dwd.orders", "id", "fdd", "SELECT", "star_projection") in actual
    assert ("ods.orders", "amount", "dwd.orders", "amount", "fdd", "SELECT", "star_projection") in actual
    assert ("ods.orders", "dt", "dwd.orders", "dt", "fdd", "SELECT", "star_projection") in actual


def test_hive_insert_select_qualified_star_expands_from_metadata_fields(mock_metadata_resolver):
    """Hive SELECT alias.* should expand through the alias source only."""
    sql = """
    INSERT OVERWRITE TABLE dwd.orders (id, amount)
    SELECT src.*
      FROM ods.orders src
    """

    with patch(
        "utils.metadata_resolver.MetadataResolver.get_table_fields",
        return_value=["id", "amount"],
    ):
        deps = IndirectFlowParser("hive").parse(sql)

    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("sourceExpression"),
        )
        for dep in deps
    }

    assert ("ods.orders", "id", "dwd.orders", "id", "fdd", "src.*") in actual
    assert ("ods.orders", "amount", "dwd.orders", "amount", "fdd", "src.*") in actual


def test_hive_projection_after_qualified_star_uses_expanded_target_position(mock_metadata_resolver):
    """Hive projections after alias.* should map after expanded star columns."""
    sql = """
    INSERT OVERWRITE TABLE dwd.joined (id, amount, name)
    SELECT a.*, b.name
      FROM ods.a a
      JOIN ods.b b ON a.id = b.id
    """

    def fake_fields(table_name):
        return {
            "ods.a": ["id", "amount"],
            "ods.b": ["id", "name"],
        }.get(table_name, [])

    with patch(
        "utils.metadata_resolver.MetadataResolver.get_table_fields",
        side_effect=fake_fields,
    ):
        deps = IndirectFlowParser("hive").parse(sql)

    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("sourceExpression"),
        )
        for dep in deps
    }

    assert ("ods.a", "id", "dwd.joined", "id", "fdd", "a.*") in actual
    assert ("ods.a", "amount", "dwd.joined", "amount", "fdd", "a.*") in actual
    assert ("ods.b", "name", "dwd.joined", "name", "fdd", "b.name") in actual
    assert ("ods.b", "name", "dwd.joined", "amount", "fdd", "b.name") not in actual


def test_hive_join_using_adds_join_dependencies(mock_metadata_resolver):
    """Hive JOIN USING columns should be represented as join dependencies."""
    sql = """
    INSERT OVERWRITE TABLE dwd.joined (id, name)
    SELECT a.id, b.name
      FROM ods.a a
      JOIN ods.b b USING (id)
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.a", "id", "dwd.joined", "*", "join", "JOIN_USING") in actual
    assert ("ods.b", "id", "dwd.joined", "*", "join", "JOIN_USING") in actual
    assert ("ods.b", "name", "dwd.joined", "name", "fdd", "SELECT") in actual


def test_hive_chained_join_using_only_uses_preceding_sources(mock_metadata_resolver):
    """Chained JOIN USING should not attach later tables to earlier joins."""
    sql = """
    INSERT OVERWRITE TABLE dwd.joined (id, v1, v2)
    SELECT a.id, b.v1, c.v2
      FROM ods.a a
      JOIN ods.b b USING (id)
      JOIN ods.c c USING (id)
    """

    deps = IndirectFlowParser("hive").parse(sql)
    join_deps = [
        dep
        for dep in deps
        if dep.get("context") == "JOIN_USING"
    ]
    first_join = {
        (dep.get("source_table"), dep.get("source_column"))
        for dep in join_deps
        if dep.get("targetExpression") == "JOIN ods.b AS b USING (id)"
    }
    second_join = {
        (dep.get("source_table"), dep.get("source_column"))
        for dep in join_deps
        if dep.get("targetExpression") == "JOIN ods.c AS c USING (id)"
    }

    assert ("ods.a", "id") in first_join
    assert ("ods.b", "id") in first_join
    assert ("ods.c", "id") not in first_join
    assert ("ods.a", "id") in second_join
    assert ("ods.b", "id") in second_join
    assert ("ods.c", "id") in second_join


def test_hive_insert_select_star_from_cte_expands_to_physical_source(mock_metadata_resolver):
    """Hive SELECT * from a CTE should expand through the CTE to physical sources."""
    sql = """
    WITH base AS (
      SELECT *
        FROM ods.orders
    )
    INSERT OVERWRITE TABLE dwd.orders (id, amount, dt)
    SELECT *
      FROM base
    """

    with patch(
        "utils.metadata_resolver.MetadataResolver.get_table_fields",
        return_value=["id", "amount", "dt"],
    ):
        deps = IndirectFlowParser("hive").parse(sql)

    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("lineage_origin"),
        )
        for dep in deps
    }

    assert ("ods.orders", "id", "dwd.orders", "id", "fdd", "star_projection") in actual
    assert ("ods.orders", "amount", "dwd.orders", "amount", "fdd", "star_projection") in actual
    assert ("ods.orders", "dt", "dwd.orders", "dt", "fdd", "star_projection") in actual
    assert not any(dep.get("source_table") == "base" for dep in deps)


def test_hive_mti_join_preserves_shared_source_aliases(mock_metadata_resolver):
    """Hive MTI branches must retain aliases and JOIN USING from the shared FROM."""
    sql = """
    FROM ods.a a
    JOIN ods.b b USING (id)
    INSERT OVERWRITE TABLE dwd.joined
    SELECT a.id, a.v1, b.v2
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.a", "id", "dwd.joined", "id", "fdd", "SELECT") in actual
    assert ("ods.a", "v1", "dwd.joined", "v1", "fdd", "SELECT") in actual
    assert ("ods.b", "v2", "dwd.joined", "v2", "fdd", "SELECT") in actual
    assert ("ods.a", "id", "dwd.joined", "*", "join", "JOIN_USING") in actual
    assert ("ods.b", "id", "dwd.joined", "*", "join", "JOIN_USING") in actual


def test_hive_mti_lateral_view_preserves_udtf_lineage(mock_metadata_resolver):
    """Hive MTI shared LATERAL VIEW output must trace to its physical input."""
    sql = """
    FROM ods.orders o
    LATERAL VIEW explode(items) e AS item
    INSERT OVERWRITE TABLE dwd.out
    SELECT id, item
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
        )
        for dep in deps
    }

    assert ("ods.orders", "id", "dwd.out", "id", "fdd") in actual
    assert ("ods.orders", "items", "dwd.out", "item", "fdd") in actual


def test_hive_join_using_inside_cte_is_preserved(mock_metadata_resolver):
    """JOIN USING evidence inside a CTE must be attached to the final target."""
    sql = """
    WITH joined AS (
      SELECT a.id, a.v1, b.v2
        FROM ods.a a
        JOIN ods.b b USING (id)
    )
    INSERT OVERWRITE TABLE dwd.joined (id, v1, v2)
    SELECT id, v1, v2 FROM joined
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in deps
    }

    assert ("ods.a", "id", "dwd.joined", "join", "JOIN_USING") in actual
    assert ("ods.b", "id", "dwd.joined", "join", "JOIN_USING") in actual


def test_hive_chained_lateral_view_traces_to_root_column(mock_metadata_resolver):
    """A lateral output used by another lateral view must resolve recursively."""
    sql = """
    INSERT OVERWRITE TABLE dwd.out (id, tag)
    SELECT id, tag
      FROM ods.orders o
      LATERAL VIEW explode(items) e AS item
      LATERAL VIEW explode(item.tags) t AS tag
    """

    deps = IndirectFlowParser("hive").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
        )
        for dep in deps
    }

    assert ("ods.orders", "items", "dwd.out", "tag", "fdd") in actual
    assert ("ods.orders", "item", "dwd.out", "tag", "fdd") not in actual


def test_hive_clause_function_literal_is_not_projection_position(mock_metadata_resolver):
    """Numeric literals inside clause functions are values, not ordinal references."""
    sql = """
    INSERT OVERWRITE TABLE dwd.out (a, c)
    SELECT a, c
      FROM ods.t
     ORDER BY coalesce(c, 1)
    """

    deps = IndirectFlowParser("hive").parse(sql)
    order_refs = {
        (dep.get("source_table"), dep.get("source_column"), dep.get("lineage_origin"))
        for dep in deps
        if dep.get("context") == "ORDER_BY"
    }

    assert ("ods.t", "a", "clause_position") not in order_refs
    assert any(table == "ods.t" and column == "c" for table, column, _ in order_refs)


def test_hive_clause_position_expands_select_star(mock_metadata_resolver):
    """Ordinal clauses after SELECT * use the expanded metadata-backed position."""
    sql = """
    INSERT OVERWRITE TABLE dwd.out (a, b, c, x)
    SELECT t.*, t.x
      FROM ods.t t
     ORDER BY 4
    """

    with patch(
        "utils.metadata_resolver.MetadataResolver.get_table_fields",
        return_value=["a", "b", "c"],
    ):
        deps = IndirectFlowParser("hive").parse(sql)

    assert any(
        dep.get("source_table") == "ods.t"
        and dep.get("source_column") == "x"
        and dep.get("context") == "ORDER_BY"
        and dep.get("lineage_origin") == "clause_position"
        for dep in deps
    )
