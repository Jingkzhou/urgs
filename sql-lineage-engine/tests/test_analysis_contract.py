"""Public analysis and CLI compatibility contract tests."""

import json
import os
from pathlib import Path
import subprocess
import sys

from parsers.sql_parser import LineageParser


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
