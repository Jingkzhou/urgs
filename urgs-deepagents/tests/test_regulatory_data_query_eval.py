"""regulatory-data-query-agent 评测评分器测试。"""

from __future__ import annotations

import runpy
from pathlib import Path

EVAL_MODULE = runpy.run_path(
    str(Path(__file__).parents[1] / "evals/regulatory_data_query/run_eval.py")
)


def test_grade_checks_answer_tool_arguments_and_tool_results() -> None:
    grade = EVAL_MODULE["grade"]
    question = {
        "required_any": [["76"], ["万元"]],
        "required_tools": ["query_regulatory_summary"],
        "required_tool_args": [
            {
                "name": "query_regulatory_summary",
                "contains": {
                    "indicator_codes": ["loan_balance"],
                    "organization": "1200",
                },
            }
        ],
        "required_tool_result_any": [["aggregates", "76", "万元"]],
        "forbidden_any": ["760000万元"],
    }
    trace = {
        "tool_calls": ["query_regulatory_summary"],
        "tool_call_details": [
            {
                "name": "query_regulatory_summary",
                "args": {"indicator_codes": ["loan_balance"], "organization": "1200"},
            }
        ],
        "tool_result_details": [
            {
                "name": "query_regulatory_summary",
                "result": {
                    "aggregates": [
                        {"indicator_code": "loan_balance", "value": "76", "unit": "万元"}
                    ]
                },
            }
        ],
    }

    result = grade(question, "各项贷款余额为76万元。", None, trace)

    assert result["passed"] is True


def test_grade_rejects_forbidden_query_tool() -> None:
    grade = EVAL_MODULE["grade"]
    question = {
        "required_any": [["汇总", "明细"]],
        "forbidden_tools": ["query_regulatory_summary", "query_regulatory_detail"],
    }
    trace = {
        "tool_calls": ["query_regulatory_summary"],
        "tool_call_details": [],
        "tool_result_details": [],
    }

    result = grade(question, "请确认查询汇总还是明细。", None, trace)

    assert result["passed"] is False


def test_grade_accepts_equivalent_tool_argument_paths() -> None:
    grade = EVAL_MODULE["grade"]
    question = {
        "required_tool_args_any": [
            [
                {"name": "compare", "contains": {"baseline": "PREVIOUS_PERIOD"}},
                {
                    "name": "compare",
                    "contains": {"baseline": "CUSTOM", "baseline_date": "2026-01-31"},
                },
            ]
        ]
    }
    trace = {
        "tool_calls": ["compare"],
        "tool_call_details": [
            {"name": "compare", "args": {"baseline": "PREVIOUS_PERIOD"}}
        ],
        "tool_result_details": [],
    }

    result = grade(question, "已完成确定性比较。", None, trace)

    assert result["passed"] is True
