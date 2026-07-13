import os
from pathlib import Path

os.chdir(Path(__file__).resolve().parents[1])

from exporters.neo4j import Neo4jClient


class RecordingSession:
    def __init__(self, calls):
        self.calls = calls

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        return False

    def execute_write(self, func, *args):
        self.calls.append((func.__name__, args))


class RecordingDriver:
    def __init__(self):
        self.calls = []

    def session(self):
        return RecordingSession(self.calls)


def test_star_columns_are_fact_only_and_not_column_relationships():
    client = Neo4jClient.__new__(Neo4jClient)
    driver = RecordingDriver()
    client.driver = driver

    client.create_column_lineage_v2(
        [
            {
                "source_table": "ODS.UNKNOWN_SRC",
                "source_column": "*",
                "target_table": "MART.UNKNOWN_TGT",
                "target_column": "*",
                "dependency_type": "fdd",
                "ambiguityCode": "STAR_EXPANSION_UNAVAILABLE",
                "confidence": "LOW",
                "validation_note": "Source table metadata not found for SELECT * expansion",
            }
        ],
        version="test-version",
    )

    call_names = [name for name, _ in driver.calls]
    assert "_create_direct_column_batch_safe" not in call_names
    assert "_create_indirect_column_batch_safe" not in call_names
    assert call_names == ["_create_lineage_facts_batch"]


def test_star_columns_are_removed_from_table_relationship_column_lists():
    assert Neo4jClient._as_clean_list(["A", "*", "", None, "B"]) == ["A", "B"]
    assert Neo4jClient._is_placeholder_column("*")


def test_hive_distribution_relationship_types_are_not_downgraded():
    client = Neo4jClient.__new__(Neo4jClient)
    driver = RecordingDriver()
    client.driver = driver
    client.batch_size = 100
    client.max_batch_bytes = 1024 * 1024

    client.create_column_lineage_v2(
        [
            {
                "source_table": "ODS.EVENTS",
                "source_column": "USER_ID",
                "target_table": "DWD.EVENTS",
                "target_column": "*",
                "dependency_type": "fdr",
                "neo4j_type": "DISTRIBUTES",
                "context": "DISTRIBUTE_BY",
            },
            {
                "source_table": "ODS.EVENTS",
                "source_column": "EVENT_TIME",
                "target_table": "DWD.EVENTS",
                "target_column": "*",
                "dependency_type": "fdr",
                "neo4j_type": "CLUSTERS",
                "context": "CLUSTER_BY",
            },
        ],
        version="test-version",
    )

    relation_types = {
        args[1]
        for call_name, args in driver.calls
        if call_name == "_create_indirect_column_batch_safe"
    }
    assert relation_types == {"DISTRIBUTES", "CLUSTERS"}


def test_write_batches_limit_count_and_serialized_bytes():
    client = Neo4jClient.__new__(Neo4jClient)
    client.batch_size = 3
    client.max_batch_bytes = 100

    items = [
        {"snippet": "a" * 30},
        {"snippet": "b" * 30},
        {"snippet": "c" * 80},
        {"snippet": "d"},
    ]

    batches = list(client._iter_write_batches(items))

    assert [len(batch) for batch in batches] == [2, 1, 1]
    assert [item for batch in batches for item in batch] == items


def test_default_schema_preserves_dots_inside_quoted_table_name():
    client = Neo4jClient.__new__(Neo4jClient)
    client.default_schema = "PM_RSDATA"

    identity = client._table_identity("pm_rsdata.S75_1.1.A")

    assert identity["owner"] == "PM_RSDATA"
    assert identity["table_name"] == "S75_1.1.A"
    assert identity["qualified_name"] == "PM_RSDATA.S75_1.1.A"
    assert identity["object_uid"]


def test_same_qualified_table_is_isolated_by_data_source():
    first = Neo4jClient.__new__(Neo4jClient)
    first.default_schema = "ODS"
    first.data_source_id = "100"
    second = Neo4jClient.__new__(Neo4jClient)
    second.default_schema = "ODS"
    second.data_source_id = "200"

    first_identity = first._table_identity("ODS.CUSTOMER")
    second_identity = second._table_identity("ODS.CUSTOMER")

    assert first_identity["qualified_name"] == second_identity["qualified_name"]
    assert first_identity["object_uid"] != second_identity["object_uid"]


def test_file_level_analysis_results_preserve_failed_parse_evidence():
    client = Neo4jClient.__new__(Neo4jClient)
    driver = RecordingDriver()
    client.driver = driver
    client.batch_size = 100
    client.max_batch_bytes = 1024 * 1024

    client.create_analysis_results_batch(
        [{
            "file_path": "broken.sql",
            "error": None,
            "analysis_quality": {
                "status": "FAILED",
                "confidence": "LOW",
                "inferred": False,
                "ambiguous": False,
                "diagnostics": [{"code": "PARSER_ERROR", "message": "bad syntax"}],
                "tableRelationCount": 0,
                "columnRelationCount": 0,
            },
            "dialect_profile": {"requested": "oracle", "effective": "oracle"},
        }],
        version="v1",
        repo_id="repo-1",
    )

    assert [name for name, _ in driver.calls] == ["_create_analysis_results_batch"]
    item = driver.calls[0][1][0][0]
    assert item["status"] == "FAILED"
    assert item["source_file"] == "broken.sql"
    assert '"PARSER_ERROR"' in item["diagnostics_json"]
