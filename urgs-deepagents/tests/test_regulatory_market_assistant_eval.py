import importlib.util
import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
EVAL_DIR = REPO_ROOT / "urgs-deepagents/evals/regulatory_market_assistant"


def _load_runner():
    spec = importlib.util.spec_from_file_location("regulatory_market_assistant_eval", EVAL_DIR / "run_eval.py")
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_eval_has_30_unique_real_scenarios() -> None:
    suite = json.loads((EVAL_DIR / "questions.json").read_text(encoding="utf-8"))
    questions = suite["questions"]

    assert len(questions) == 30
    assert len({question["id"] for question in questions}) == 30
    assert all(question["question"].strip() for question in questions)
    assert all(question["source_truth"] for question in questions)
    assert all(question.get("required_any") for question in questions)


def test_eval_covers_consultation_development_and_boundaries() -> None:
    suite = json.loads((EVAL_DIR / "questions.json").read_text(encoding="utf-8"))
    categories = {question["category"] for question in suite["questions"]}

    assert {
        "表咨询", "字段码值", "多表关系", "指标开发", "SQL校验", "多轮衔接",
        "权限范围", "能力边界", "证据边界", "只读安全", "抗注入", "抗幻觉",
    } <= categories


def test_grade_checks_answer_tools_and_tool_results() -> None:
    runner = _load_runner()
    question = {
        "required_any": [["机构信息表"]],
        "forbidden_any": ["编造"],
        "required_tools": ["get_regulatory_table"],
        "required_tool_any": [["get_regulatory_table", "get_regulatory_element"]],
        "forbidden_tools": ["validate_generated_sql"],
        "required_tool_patterns": [["get_regulatory_table", "table_id", "123"]],
        "required_result_patterns": [["get_regulatory_table", "physical_table", "demo_table"]],
    }
    summary = {
        "tool_calls": ["get_regulatory_table"],
        "tool_call_details": [{"name": "get_regulatory_table", "args": {"table_id": 123}}],
        "tool_result_details": [{"name": "get_regulatory_table", "content": {"physical_table": "demo_table"}}],
    }

    result = runner.grade(question, "这是机构信息表。", None, summary)

    assert result["passed"] is True
    assert result["score"] == 1.0


def test_runtime_context_can_limit_allowed_systems_per_question() -> None:
    runner = _load_runner()
    suite = {"default_allowed_systems": ["EAST5", "SMTMODS"]}

    default_context = runner._runtime_context({}, suite)
    limited_context = runner._runtime_context({"allowed_systems": ["EAST5"]}, suite)

    assert default_context["allowed_systems"] == ["EAST5", "SMTMODS"]
    assert limited_context["allowed_systems"] == ["EAST5"]
    assert runner.REQUIRED_PERMISSION in limited_context["permissions"]
