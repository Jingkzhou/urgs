"""监管知识评测的答案与工具证据门禁测试。"""

from __future__ import annotations

import runpy
from pathlib import Path
from types import SimpleNamespace

EVAL_MODULE = runpy.run_path(
    str(Path(__file__).parents[1] / "evals/regulatory_knowledge/run_eval.py")
)


def test_grade_requires_source_and_tool_pattern_in_trace() -> None:
    grade = EVAL_MODULE["grade"]
    question = {
        "required_any": [["EAST5.0"]],
        "required_sources": ["03-实体/EAST5.0-IE_004_405-对公存款分户账.md"],
        "required_tool_patterns": [["grep", "同业存放"]],
    }
    tool_summary = {
        "tool_call_details": [
            {
                "name": "grep",
                "args": {"pattern": "同业存放", "path": "/03-实体"},
            },
            {
                "name": "read_file",
                "args": {
                    "file_path": "/03-实体/EAST5.0-IE_004_405-对公存款分户账.md"
                },
            },
        ]
    }

    result = grade(question, "EAST5.0 应纳入", None, tool_summary)

    assert result["passed"] is True


def test_collect_tool_summary_keeps_tool_arguments() -> None:
    collect_tool_summary = EVAL_MODULE["collect_tool_summary"]

    message = SimpleNamespace(
        tool_calls=[
            {"name": "grep", "args": {"pattern": "同业存放", "path": "/03-实体"}}
        ]
    )

    result = collect_tool_summary({"messages": [message]})

    assert result["tool_calls"] == ["grep"]
    assert result["tool_call_details"][0]["args"]["pattern"] == "同业存放"


def test_eval_uses_regulatory_knowledge_graph_budget() -> None:
    evaluation_graph_config = EVAL_MODULE["evaluation_graph_config"]

    result = evaluation_graph_config(SimpleNamespace(recursion_limit=100))

    assert result["recursion_limit"] > 100
