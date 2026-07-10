import pytest

from parsers.parallel_parser import detect_dialect_from_path
from utils.dialect_detector import detect_dialect
from utils.dialect_registry import resolve_dialect_profile


@pytest.mark.parametrize(
    ("requested", "canonical", "sqlglot_dialect", "gsp_dialect"),
    [
        ("mysql", "mysql", "mysql", "mysql"),
        ("oracle", "oracle", "oracle", "oracle"),
        ("hive", "hive", "hive", "hive"),
        ("spark", "spark", "spark", "hive"),
        ("postgres", "postgresql", "postgres", "postgresql"),
        ("postgresql", "postgresql", "postgres", "postgresql"),
        ("sqlserver", "sqlserver", "tsql", "sqlserver"),
        ("tsql", "sqlserver", "tsql", "sqlserver"),
        ("t-sql", "sqlserver", "tsql", "sqlserver"),
        ("gbase", "gbase_8a", "mysql", "mysql"),
        ("gbase_8a", "gbase_8a", "mysql", "mysql"),
        ("gbase_8s", "gbase_8s", None, "informix"),
        ("gbase_legacy_oracle", "gbase_legacy_oracle", "oracle", "gbase"),
        ("presto", "presto", "presto", "mysql"),
        ("trino", "trino", "trino", "mysql"),
        ("bigquery", "bigquery", "bigquery", "mysql"),
        ("snowflake", "snowflake", "snowflake", "mysql"),
    ],
)
def test_registry_resolves_canonical_profiles_and_aliases(
    requested, canonical, sqlglot_dialect, gsp_dialect
):
    profile = resolve_dialect_profile(requested)

    assert profile.name == canonical
    assert profile.sqlglot_dialect == sqlglot_dialect
    assert profile.gsp_dialect == gsp_dialect


def test_registry_rejects_unknown_dialect():
    with pytest.raises(ValueError, match="Unsupported SQL dialect"):
        resolve_dialect_profile("unknown-database")


@pytest.mark.parametrize(
    ("file_path", "expected"),
    [
        ("/repo/oracle/jobs/load.sql", "oracle"),
        ("/repo/postgres/jobs/load.sql", "postgresql"),
        ("/repo/postgresql/jobs/load.sql", "postgresql"),
        ("/repo/sqlserver/jobs/load.sql", "sqlserver"),
        ("/repo/t-sql/jobs/load.sql", "sqlserver"),
        ("/repo/gbase/jobs/load.sql", "gbase_8a"),
        (r"C:\repo\gbase_8a\jobs\load.sql", "gbase_8a"),
        ("/repo/gbase_8s/jobs/load.sql", "gbase_8s"),
        ("/repo/gbase/gbase_8s/jobs/load.sql", "gbase_8s"),
        ("/repo/gbase_legacy_oracle/jobs/load.sql", "gbase_legacy_oracle"),
    ],
)
def test_path_detection_returns_canonical_dialect(file_path, expected):
    assert detect_dialect_from_path(file_path) == expected


def test_path_detection_requires_a_complete_path_segment():
    assert detect_dialect_from_path("/repo/oracle_jobs/load.sql") is None


@pytest.mark.parametrize(
    ("sql", "expected"),
    [
        ("SELECT NVL(amount, 0) FROM orders", "oracle"),
        (
            "SELECT item FROM src LATERAL VIEW EXPLODE(items) exploded AS item",
            "hive",
        ),
        ("SELECT id FROM orders", None),
    ],
)
def test_sql_detection_uses_registered_profile_patterns(sql, expected):
    assert detect_dialect(sql) == expected


def test_sql_detection_uses_all_evidence_instead_of_first_function_match():
    sql = """
    INSERT OVERWRITE TABLE dwd.events
    SELECT TO_DATE(event_time), item
      FROM ods.events
      LATERAL VIEW EXPLODE(items) e AS item
    """

    assert detect_dialect(sql) == "hive"
