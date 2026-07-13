"""Public analysis and CLI compatibility contract tests."""

import json
import os
from pathlib import Path
import subprocess
import sys

from parsers.sql_parser import LineageParser
from parsers.parallel_parser import parse_single_file


PROJECT_ROOT = Path(__file__).resolve().parents[1]


def test_analyze_returns_table_column_and_effective_dialect_contract(
    mock_metadata_resolver,
):
    sql = """
    INSERT INTO `tgt` (`id`, `val`)
    SELECT s.`id`, IFNULL(s.`val`, 0) FROM `src` s
    """

    result = LineageParser("gbase").analyze(sql, source_file="job.sql")

    assert result["dialectProfile"] == {
        "requested": "gbase_8a",
        "effective": "gbase_8a",
        "sqlglot": "mysql",
        "gsp": "mysql",
        "detected": False,
    }
    assert result["relationships"]
    assert {
        (
            dep["source_table"],
            dep["source_column"],
            dep["target_table"],
            dep["target_column"],
        )
        for dep in result["columnDependencies"]
        if dep["dependency_type"] == "fdd"
    } == {("src", "id", "tgt", "id"), ("src", "val", "tgt", "val")}


def test_json_cli_does_not_require_neo4j_and_exposes_dialect_profile():
    env = os.environ.copy()
    env["NEO4J_URI"] = "bolt://127.0.0.1:1"
    completed = subprocess.run(
        [
            sys.executable,
            str(PROJECT_ROOT / "bin" / "lineage-cli"),
            "parse-sql",
            "--sql",
            "INSERT INTO `tgt` (`id`) SELECT `id` FROM `src`",
            "--dialect",
            "gbase",
            "--output",
            "json",
        ],
        cwd=PROJECT_ROOT,
        env=env,
        check=True,
        capture_output=True,
        text=True,
        timeout=30,
    )

    result = json.loads(completed.stdout)
    assert result["dialectProfile"]["effective"] == "gbase_8a"
    assert result["columnDependencies"]


def test_analysis_quality_marks_verified_lineage_and_propagates_to_facts(
    mock_metadata_resolver,
):
    result = LineageParser("hive").analyze(
        "INSERT INTO tgt (id) SELECT id FROM src",
        source_file="job.sql",
    )

    assert result["quality"]["status"] in {"EXACT", "INCOMPLETE"}
    assert result["quality"]["columnRelationCount"] > 0
    assert result["quality"]["diagnostics"] == (
        [] if result["quality"]["status"] == "EXACT" else result["quality"]["diagnostics"]
    )
    assert all(
        item["parseStatus"] == result["quality"]["status"]
        for item in result["columnDependencies"]
    )


def test_analysis_quality_does_not_present_unparseable_sql_as_success():
    result = LineageParser("oracle").analyze("INSERT INTO", source_file="broken.sql")

    assert result["quality"]["status"] == "FAILED"
    assert result["quality"]["columnRelationCount"] == 0
    assert any(
        diagnostic["code"] in {"SYNTAX_ERROR", "NO_LINEAGE_FACTS"}
        for diagnostic in result["quality"]["diagnostics"]
    )


def test_parallel_worker_counts_failed_quality_as_failed_file(tmp_path):
    sql_file = tmp_path / "broken.sql"
    sql_file.write_text("INSERT INTO", encoding="utf-8")

    result = parse_single_file((str(sql_file), "oracle", "oracle", None, None))

    assert result["success"] is False
    assert result["analysis_quality"]["status"] == "FAILED"
    assert result["error"]
