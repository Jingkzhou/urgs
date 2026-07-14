import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
EVAL_DIR = REPO_ROOT / "urgs-deepagents/evals/regulatory_knowledge"


def test_regulatory_knowledge_eval_has_31_unique_real_questions() -> None:
    suite = json.loads((EVAL_DIR / "questions.json").read_text(encoding="utf-8"))
    questions = suite["questions"]

    assert len(questions) == 31
    assert len({question["id"] for question in questions}) == 31
    assert all(question["question"].strip() for question in questions)
    assert all(question["required_any"] for question in questions)
    assert all(question["source_truth"] for question in questions)


def test_regulatory_knowledge_eval_covers_quality_and_safety_boundaries() -> None:
    suite = json.loads((EVAL_DIR / "questions.json").read_text(encoding="utf-8"))
    categories = {question["category"] for question in suite["questions"]}

    assert {"单表事实", "字段口径", "业务场景", "证据边界", "只读安全", "抗幻觉"} <= categories
