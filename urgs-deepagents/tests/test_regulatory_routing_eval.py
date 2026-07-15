"""监管 Agent 多轮路由评测器测试。"""

from __future__ import annotations

import runpy
from pathlib import Path

EVAL_MODULE = runpy.run_path(
    str(Path(__file__).parents[1] / "evals/regulatory_routing/run_eval.py")
)


def test_grade_accepts_expected_agent_and_reuse() -> None:
    result = EVAL_MODULE["grade"](
        {
            "expected_agent_code": "regulatory-data-query-agent",
            "expected_reused_current_agent": True,
        },
        {
            "agent_code": "regulatory-data-query-agent",
            "reused_current_agent": True,
        },
        None,
    )

    assert result["passed"] is True


def test_grade_rejects_context_losing_route() -> None:
    result = EVAL_MODULE["grade"](
        {
            "expected_agent_code": "regulatory-data-query-agent",
            "expected_reused_current_agent": True,
        },
        {
            "agent_code": "regulatory-knowledge-agent",
            "reused_current_agent": False,
        },
        None,
    )

    assert result["passed"] is False
