"""Regression tests for non-INSERT query mutations across supported dialects."""

from parsers.indirect_flow_parser import IndirectFlowParser


def _facts(dependencies):
    return {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
            dep.get("context"),
        )
        for dep in dependencies
    }


def test_oracle_merge_extracts_update_insert_and_match_lineage(mock_metadata_resolver):
    sql = """
    MERGE INTO dwh.customer_dim d
    USING (
      SELECT id, upper(name) AS clean_name, status
        FROM ods.customer
    ) s
       ON (d.id = s.id)
    WHEN MATCHED THEN UPDATE SET
      d.name = s.clean_name,
      d.status = s.status
    WHEN NOT MATCHED THEN INSERT (id, name, status)
      VALUES (s.id, s.clean_name, s.status)
    """

    actual = _facts(IndirectFlowParser("oracle").parse(sql))

    assert ("ods.customer", "id", "dwh.customer_dim", "id", "fdd", "MERGE_INSERT") in actual
    assert ("ods.customer", "name", "dwh.customer_dim", "name", "fdd", "MERGE_UPDATE") in actual
    assert ("ods.customer", "status", "dwh.customer_dim", "status", "fdd", "MERGE_UPDATE") in actual
    assert ("ods.customer", "id", "dwh.customer_dim", "*", "join", "MERGE_ON") in actual


def test_hive_merge_uses_same_mutation_contract(mock_metadata_resolver):
    sql = """
    MERGE INTO dwh.customer t
    USING ods.customer_delta s
       ON t.id = s.id
    WHEN MATCHED THEN UPDATE SET name = s.name
    WHEN NOT MATCHED THEN INSERT VALUES (s.id, s.name)
    """

    actual = _facts(IndirectFlowParser("hive").parse(sql))

    assert ("ods.customer_delta", "name", "dwh.customer", "name", "fdd", "MERGE_UPDATE") in actual
    assert ("ods.customer_delta", "id", "dwh.customer", "*", "join", "MERGE_ON") in actual


def test_oracle_insert_all_preserves_every_target_branch(mock_metadata_resolver):
    sql = """
    INSERT ALL
      WHEN amount > 0 THEN
        INTO pos_txn (id, amount) VALUES (id, amount)
      ELSE
        INTO neg_txn (id, amount) VALUES (id, amount)
    SELECT id, amount FROM staging_txn
    """

    actual = _facts(IndirectFlowParser("oracle").parse(sql))

    assert ("staging_txn", "id", "pos_txn", "id", "fdd", "INSERT_ALL") in actual
    assert ("staging_txn", "amount", "pos_txn", "amount", "fdd", "INSERT_ALL") in actual
    assert ("staging_txn", "id", "neg_txn", "id", "fdd", "INSERT_ALL") in actual
    assert ("staging_txn", "amount", "neg_txn", "amount", "fdd", "INSERT_ALL") in actual
    assert ("staging_txn", "amount", "pos_txn", "*", "fdr", "INSERT_ALL_WHEN") in actual


def test_oracle_insert_first_keeps_conditions_out_of_direct_targets(mock_metadata_resolver):
    sql = """
    INSERT FIRST
      WHEN kind = 'A' THEN INTO tgt_a (id, val) VALUES (id, val)
      WHEN kind = 'B' THEN INTO tgt_b (id, val) VALUES (id, val)
      ELSE INTO tgt_other (id, val) VALUES (id, val)
    SELECT id, val, kind FROM src
    """

    actual = _facts(IndirectFlowParser("oracle").parse(sql))

    for target in ("tgt_a", "tgt_b", "tgt_other"):
        assert ("src", "id", target, "id", "fdd", "INSERT_ALL") in actual
        assert ("src", "val", target, "val", "fdd", "INSERT_ALL") in actual
        assert ("src", "kind", target, "kind", "fdd", "INSERT_ALL") not in actual
    assert ("src", "kind", "tgt_a", "*", "fdr", "INSERT_ALL_WHEN") in actual
    assert ("src", "kind", "tgt_b", "*", "fdr", "INSERT_ALL_WHEN") in actual


def test_oracle_update_extracts_scalar_subquery_and_filter_lineage(mock_metadata_resolver):
    sql = """
    UPDATE dwh.account d
       SET d.balance = (
         SELECT s.balance
           FROM ods.account s
          WHERE s.id = d.id
       )
     WHERE EXISTS (
       SELECT 1 FROM ods.account s WHERE s.id = d.id
     )
    """

    actual = _facts(IndirectFlowParser("oracle").parse(sql))

    assert ("ods.account", "balance", "dwh.account", "balance", "fdd", "UPDATE_SET") in actual
    assert ("ods.account", "id", "dwh.account", "*", "fdr", "UPDATE_WHERE") in actual
    assert ("dwh.account", "id", "dwh.account", "*", "fdr", "UPDATE_WHERE") in actual
    assert ("ods.account", "id", "dwh.account", "balance", "fdd", "UPDATE_SET") not in actual
