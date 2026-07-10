"""GBase 8a lineage compatibility tests."""

from parsers.indirect_flow_parser import IndirectFlowParser
from parsers.sql_parser import LineageParser


def _direct_facts(dependencies):
    return {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
        )
        for dep in dependencies
        if dep.get("dependency_type") == "fdd"
    }


def test_gbase_alias_uses_mysql_protocol_and_backtick_syntax(mock_metadata_resolver):
    sql = """
    INSERT INTO `tgt` (`id`, `val`)
    SELECT s.`id`, IFNULL(s.`val`, 0)
      FROM `src` s
     LIMIT 10
    """

    parser = IndirectFlowParser("gbase")
    actual = _direct_facts(parser.parse(sql))

    assert parser.dialect_name == "gbase_8a"
    assert parser.dialect == "mysql"
    assert ("src", "id", "tgt", "id", "fdd") in actual
    assert ("src", "val", "tgt", "val", "fdd") in actual


def test_gbase_full_parser_reconciles_quoted_gsp_and_sqlglot_columns(
    mock_metadata_resolver,
):
    sql = """
    INSERT INTO `tgt` (`id`, `val`)
    SELECT s.`id`, IFNULL(s.`val`, 0)
      FROM `src` s
    """

    actual = [
        dep
        for dep in LineageParser("gbase").get_column_lineage(sql)
        if dep.get("dependency_type") == "fdd"
    ]
    facts = _direct_facts(actual)

    assert facts == {
        ("src", "id", "tgt", "id", "fdd"),
        ("src", "val", "tgt", "val", "fdd"),
    }
    assert len(actual) == 2


def test_explicit_gbase_profile_is_not_overridden_by_oracle_function_name(
    mock_metadata_resolver,
):
    sql = """
    INSERT INTO `tgt` (`id`, `val`)
    SELECT s.`id`, NVL(s.`val`, 0)
      FROM `src` s
    """

    parser = LineageParser("gbase")
    actual = _direct_facts(parser.get_column_lineage(sql))

    assert parser.dialect == "gbase_8a"
    assert ("src", "id", "tgt", "id", "fdd") in actual
    assert ("src", "val", "tgt", "val", "fdd") in actual


def test_gbase_ctas_ignores_distribution_storage_clause(mock_metadata_resolver):
    sql = """
    CREATE TABLE `tgt`
    DISTRIBUTED BY (`id`)
    COMPRESS (5, 5)
    AS SELECT s.`id`, s.`val` FROM `src` s
    """

    actual = _direct_facts(IndirectFlowParser("gbase").parse(sql))

    assert ("src", "id", "tgt", "id", "fdd") in actual
    assert ("src", "val", "tgt", "val", "fdd") in actual


def test_gbase_replace_select_uses_insert_lineage_view(mock_metadata_resolver):
    sql = """
    REPLACE INTO `tgt` (`id`, `val`)
    SELECT s.`id`, s.`val` FROM `src` s
    """

    deps = IndirectFlowParser("gbase").parse(sql)
    actual = _direct_facts(deps)

    assert ("src", "id", "tgt", "id", "fdd") in actual
    assert ("src", "val", "tgt", "val", "fdd") in actual
    assert all("REPLACE INTO" in dep.get("snippet", "").upper() for dep in deps)
