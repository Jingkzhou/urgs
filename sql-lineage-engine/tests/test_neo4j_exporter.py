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
