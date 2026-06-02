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
