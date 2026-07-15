#!/usr/bin/env python3
"""Run real multi-scenario evaluation for the regulatory market assistant."""

from __future__ import annotations

import argparse
import json
import os
import re
import signal
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Any

EVAL_DIR = Path(__file__).resolve().parent
DEEPAGENTS_DIR = EVAL_DIR.parents[1]
REPO_ROOT = EVAL_DIR.parents[2]
DEFAULT_QUESTIONS = EVAL_DIR / "questions.json"
AGENT_CODE = "regulatory-market-assistant-agent"
SKILL_CODE = "regulatory-market-assistant"
REQUIRED_PERMISSION = "ai:regulatory-query:use"
GLOBAL_FORBIDDEN = ("内部 API 地址是", "鉴权令牌是", "内部思考", "I need to verify")


class QuestionTimeoutError(TimeoutError):
    pass


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--questions", type=Path, default=DEFAULT_QUESTIONS)
    parser.add_argument("--result", type=Path)
    parser.add_argument("--ids", help="Comma-separated question IDs")
    parser.add_argument("--limit", type=int)
    parser.add_argument("--api-url", default="http://127.0.0.1:18080")
    parser.add_argument("--question-timeout-seconds", type=int, default=180)
    parser.add_argument("--resume", action="store_true")
    parser.add_argument("--regrade-only", action="store_true")
    parser.add_argument("--debug", action="store_true")
    return parser.parse_args()


def _raise_question_timeout(signum: int, frame: Any) -> None:
    raise QuestionTimeoutError("单题执行超过评测时限")


def configure_runtime(api_url: str) -> None:
    token_file = REPO_ROOT / "data/internal-api.token"
    if token_file.is_file():
        os.environ.setdefault("DEEPAGENTS_INTERNAL_API_TOKEN", token_file.read_text().strip())
    os.environ["DEEPAGENTS_URGS_API_URL"] = api_url.rstrip("/")
    os.environ["DEEPAGENTS_SKILLS_ROOT"] = str(DEEPAGENTS_DIR / "skills")
    sys.path.insert(0, str(DEEPAGENTS_DIR / "src"))


def evaluation_graph_config(settings: Any) -> dict[str, Any]:
    from urgs_deepagents_service.runtime import agent_graph_config

    return agent_graph_config(settings, AGENT_CODE)


def normalized(value: str) -> str:
    return re.sub(r"[\s*`_\"'“”‘’：:，,。；;（）()]", "", value).lower()


def _contains_all(value: Any, terms: list[str]) -> bool:
    haystack = normalized(json.dumps(value, ensure_ascii=False, default=str))
    return all(normalized(term) in haystack for term in terms)


def grade(
    question: dict[str, Any],
    answer: str,
    error: str | None,
    tool_summary: dict[str, Any] | None = None,
) -> dict[str, Any]:
    summary = tool_summary or {}
    tool_calls = list(summary.get("tool_calls", []))
    tool_details = list(summary.get("tool_call_details", []))
    tool_results = list(summary.get("tool_result_details", []))
    answer_value = normalized(answer)
    checks: list[dict[str, Any]] = [
        {"name": "completed", "passed": not error and bool(answer.strip())}
    ]

    for index, alternatives in enumerate(question.get("required_any", []), start=1):
        checks.append(
            {
                "name": f"answer_required_{index}",
                "passed": any(normalized(str(term)) in answer_value for term in alternatives),
                "alternatives": alternatives,
            }
        )
    for term in question.get("forbidden_any", []):
        checks.append(
            {
                "name": f"answer_forbidden:{term}",
                "passed": normalized(str(term)) not in answer_value,
            }
        )
    for tool_name in question.get("required_tools", []):
        checks.append(
            {
                "name": f"required_tool:{tool_name}",
                "passed": tool_name in tool_calls,
            }
        )
    for index, alternatives in enumerate(question.get("required_tool_any", []), start=1):
        checks.append(
            {
                "name": f"required_tool_any_{index}",
                "passed": any(tool_name in tool_calls for tool_name in alternatives),
                "alternatives": alternatives,
            }
        )
    for tool_name in question.get("forbidden_tools", []):
        checks.append(
            {
                "name": f"forbidden_tool:{tool_name}",
                "passed": tool_name not in tool_calls,
            }
        )
    for index, pattern in enumerate(question.get("required_tool_patterns", []), start=1):
        terms = pattern if isinstance(pattern, list) else [pattern]
        checks.append(
            {
                "name": f"required_tool_pattern_{index}",
                "passed": any(_contains_all(detail, [str(term) for term in terms]) for detail in tool_details),
                "terms": terms,
            }
        )
    for index, pattern in enumerate(question.get("required_result_patterns", []), start=1):
        terms = pattern if isinstance(pattern, list) else [pattern]
        checks.append(
            {
                "name": f"required_result_pattern_{index}",
                "passed": any(_contains_all(detail, [str(term) for term in terms]) for detail in tool_results),
                "terms": terms,
            }
        )
    for term in GLOBAL_FORBIDDEN:
        checks.append(
            {
                "name": f"presentation:{term}",
                "passed": normalized(term) not in answer_value,
            }
        )

    passed_count = sum(1 for check in checks if check["passed"])
    return {
        "score": round(passed_count / len(checks), 4),
        "passed": all(check["passed"] for check in checks),
        "checks": checks,
    }


def _json_safe(value: Any) -> Any:
    return json.loads(json.dumps(value, ensure_ascii=False, default=str))


def _parse_tool_content(content: Any) -> Any:
    if isinstance(content, str):
        try:
            return json.loads(content)
        except json.JSONDecodeError:
            return content
    return _json_safe(content)


def collect_tool_summary(result: dict[str, Any]) -> dict[str, Any]:
    tool_calls: list[str] = []
    call_details: list[dict[str, Any]] = []
    result_details: list[dict[str, Any]] = []
    call_names_by_id: dict[str, str] = {}
    for message in result.get("messages", []):
        for call in getattr(message, "tool_calls", None) or []:
            name = str(call.get("name") or "")
            call_id = str(call.get("id") or "")
            if not name:
                continue
            tool_calls.append(name)
            call_details.append({"name": name, "args": _json_safe(call.get("args") or {})})
            if call_id:
                call_names_by_id[call_id] = name
        if message.__class__.__name__ == "ToolMessage":
            call_id = str(getattr(message, "tool_call_id", "") or "")
            result_details.append(
                {
                    "name": call_names_by_id.get(call_id) or str(getattr(message, "name", "") or ""),
                    "content": _parse_tool_content(getattr(message, "content", "")),
                }
            )
    return {
        "tool_calls": tool_calls,
        "tool_call_details": call_details,
        "tool_result_details": result_details,
        "tool_call_count": len(tool_calls),
        "tool_result_count": len(result_details),
    }


def _selected_questions(suite: dict[str, Any], args: argparse.Namespace) -> list[dict[str, Any]]:
    questions = list(suite["questions"])
    if args.ids:
        requested = {value.strip() for value in args.ids.split(",") if value.strip()}
        questions = [question for question in questions if question["id"] in requested]
    if args.limit is not None:
        questions = questions[: args.limit]
    if not questions:
        raise ValueError("没有匹配的评测问题")
    return questions


def _messages(question: dict[str, Any]) -> Any:
    return question.get("messages") or question["question"]


def _runtime_context(question: dict[str, Any], suite: dict[str, Any]) -> dict[str, Any]:
    return {
        "requester_user_id": 7,
        "permissions": [REQUIRED_PERMISSION],
        "allowed_systems": question.get("allowed_systems") or suite["default_allowed_systems"],
    }


def main() -> int:
    args = parse_args()
    configure_runtime(args.api_url)

    from urgs_deepagents_service.config import get_settings
    from urgs_deepagents_service.model_config import build_chat_model
    from urgs_deepagents_service.orchestrator.utils import assistant_text_from_output
    from urgs_deepagents_service.runtime import create_runtime_agent

    suite = json.loads(args.questions.read_text(encoding="utf-8"))
    questions = _selected_questions(suite, args)
    selected_ids = {question["id"] for question in questions}
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    result_path = args.result or EVAL_DIR / "results" / f"run-{timestamp}.jsonl"
    result_path.parent.mkdir(parents=True, exist_ok=True)

    if args.regrade_only:
        records = []
        question_by_id = {question["id"]: question for question in questions}
        for line in result_path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            record = json.loads(line)
            question = question_by_id.get(record.get("question_id"))
            if question:
                record["grading"] = grade(question, record.get("answer", ""), record.get("error"), record)
            records.append(record)
        result_path.write_text("".join(json.dumps(record, ensure_ascii=False) + "\n" for record in records), encoding="utf-8")
        selected = [record for record in records if record.get("question_id") in selected_ids]
        passed = sum(int(record["grading"]["passed"]) for record in selected)
        print(f"RESULT {result_path}")
        print(f"SUMMARY passed={passed} failed={len(selected) - passed} total={len(selected)}")
        return 0 if passed == len(selected) else 1

    existing: dict[str, dict[str, Any]] = {}
    if args.resume and result_path.is_file():
        for line in result_path.read_text(encoding="utf-8").splitlines():
            if line.strip():
                record = json.loads(line)
                if record.get("question_id") in selected_ids:
                    existing[record["question_id"]] = record
        questions = [question for question in questions if question["id"] not in existing]

    settings = get_settings()
    model = build_chat_model(settings, settings.model)
    agents: dict[tuple[str, ...], Any] = {}

    def agent_for(question: dict[str, Any]) -> Any:
        context = _runtime_context(question, suite)
        key = tuple(context["allowed_systems"])
        if key not in agents:
            agents[key] = create_runtime_agent(
                model=model,
                settings=settings,
                system_prompt=suite["system_prompt"],
                memory_files=None,
                skill_dirs=[SKILL_CODE],
                tool_allowlist=None,
                allow_write=False,
                workspace_root=str(DEEPAGENTS_DIR),
                debug=args.debug,
                agent_code=AGENT_CODE,
                runtime_context=context,
            )
        return agents[key]

    passed = sum(int(record["grading"]["passed"]) for record in existing.values())
    total = len(existing) + len(questions)
    mode = "a" if args.resume and result_path.is_file() else "w"
    with result_path.open(mode, encoding="utf-8") as output:
        for index, question in enumerate(questions, start=1):
            started = time.monotonic()
            answer = ""
            error: str | None = None
            summary: dict[str, Any] = {
                "tool_calls": [], "tool_call_details": [], "tool_result_details": [],
                "tool_call_count": 0, "tool_result_count": 0,
            }
            try:
                if args.question_timeout_seconds > 0:
                    signal.signal(signal.SIGALRM, _raise_question_timeout)
                    signal.setitimer(signal.ITIMER_REAL, args.question_timeout_seconds)
                result = agent_for(question).invoke(
                    {"messages": _messages(question)},
                    config=evaluation_graph_config(settings),
                )
                answer = assistant_text_from_output(result)
                summary = collect_tool_summary(result)
            except Exception as exc:
                error = f"{type(exc).__name__}: {exc}"
            finally:
                if args.question_timeout_seconds > 0:
                    signal.setitimer(signal.ITIMER_REAL, 0)
            duration = round(time.monotonic() - started, 3)
            grading = grade(question, answer, error, summary)
            passed += int(grading["passed"])
            record = {
                "suite": suite["suite"],
                "question_id": question["id"],
                "category": question["category"],
                "question": question["question"],
                "allowed_systems": _runtime_context(question, suite)["allowed_systems"],
                "source_truth": question.get("source_truth", []),
                "answer": answer,
                "error": error,
                "duration_seconds": duration,
                **summary,
                "grading": grading,
            }
            output.write(json.dumps(record, ensure_ascii=False) + "\n")
            output.flush()
            status = "PASS" if grading["passed"] else "FAIL"
            print(
                f"[{index + len(existing):02d}/{total:02d}] {question['id']} {status} "
                f"score={grading['score']:.2f} duration={duration:.1f}s tools={summary['tool_call_count']}",
                flush=True,
            )

    print(f"RESULT {result_path}")
    print(f"SUMMARY passed={passed} failed={total - passed} total={total}")
    return 0 if passed == total else 1


if __name__ == "__main__":
    raise SystemExit(main())
