"""Oracle-specific lineage accuracy regression tests."""

from parsers.indirect_flow_parser import IndirectFlowParser
from parsers.sql_parser import LineageParser
from utils.splitter import SqlSplitter


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


def test_oracle_q_quote_semicolon_does_not_split_statement():
    sql = """
    INSERT INTO tgt (id, note)
    SELECT s.id, q'[Bob's; data -- is text]' FROM src s;
    INSERT INTO audit_t (id) SELECT s.id FROM src s;
    """

    statements = SqlSplitter.split(sql)

    assert len(statements) == 2
    assert "Bob's; data -- is text" in statements[0]


def test_oracle_q_quote_is_a_constant_not_a_physical_column(mock_metadata_resolver):
    sql = """
    INSERT INTO tgt (id, note)
    SELECT s.id, q'[Bob's; data -- is text]' FROM src s
    """

    deps = IndirectFlowParser("oracle").parse(sql)
    actual = _facts(deps)

    assert ("src", "id", "tgt", "id", "fdd", "SELECT") in actual
    assert not any(dep.get("target_column") == "note" for dep in deps)
    assert all("q'[Bob's; data -- is text]'" in dep.get("snippet", "") for dep in deps)


def test_oracle_merge_using_filter_and_on_condition_are_control_lineage(
    mock_metadata_resolver,
):
    sql = """
    MERGE INTO l_publ_org_bra_tmp a
    USING (
      SELECT b.org_num, b.org_nam, b.region_cd
        FROM smtmods.l_publ_org_bra b
       WHERE b.data_date = is_date
    ) b
       ON (a.org_num = b.org_num)
    WHEN MATCHED THEN UPDATE SET a.region_cd = b.region_cd
    WHEN NOT MATCHED THEN INSERT (org_num, org_nam, region_cd)
      VALUES (b.org_num, b.org_nam, b.region_cd)
    """

    actual = _facts(IndirectFlowParser("oracle").parse(sql))

    assert (
        "smtmods.l_publ_org_bra",
        "org_num",
        "l_publ_org_bra_tmp",
        "*",
        "join",
        "MERGE_ON",
    ) in actual
    assert (
        "smtmods.l_publ_org_bra",
        "data_date",
        "l_publ_org_bra_tmp",
        "*",
        "fdr",
        "MERGE_USING_WHERE",
    ) in actual


def test_oracle_connect_by_is_control_not_direct_lineage(mock_metadata_resolver):
    sql = """
    INSERT INTO tgt (id, parent_id, path)
    SELECT e.id,
           e.parent_id,
           SYS_CONNECT_BY_PATH(e.name, '/')
      FROM emp e
     START WITH e.parent_id IS NULL
   CONNECT BY PRIOR e.id = e.parent_id
    """

    deps = IndirectFlowParser("oracle").parse(sql)
    actual = _facts(deps)

    assert ("emp", "parent_id", "tgt", "*", "fdr", "START_WITH") in actual
    assert ("emp", "id", "tgt", "*", "join", "CONNECT_BY") in actual
    assert ("emp", "parent_id", "tgt", "*", "join", "CONNECT_BY") in actual
    assert ("emp", "id", "tgt", "*", "fdd", "SELECT") not in actual
    assert ("emp", "parent_id", "tgt", "*", "fdd", "SELECT") not in actual


def test_oracle_rownum_is_not_a_physical_source_column(mock_metadata_resolver):
    sql = """
    INSERT INTO tgt (id)
    SELECT s.id FROM src s WHERE ROWNUM <= 10
    """

    deps = IndirectFlowParser("oracle").parse(sql)

    assert not any(dep.get("source_column", "").upper() == "ROWNUM" for dep in deps)


def test_oracle_sequence_nextval_is_generated_not_table_lineage(
    mock_metadata_resolver,
):
    sql = """
    INSERT INTO tgt (id, val)
    SELECT seq_tgt.NEXTVAL, s.val FROM src s
    """

    deps = LineageParser("oracle").get_column_lineage(sql)

    assert any(
        dep.get("source_table") == "src"
        and dep.get("source_column") == "val"
        and dep.get("target_column") == "val"
        for dep in deps
    )
    assert not any(
        dep.get("source_column", "").upper() in {"NEXTVAL", "CURRVAL"}
        for dep in deps
    )
