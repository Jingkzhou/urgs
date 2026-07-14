#!/usr/bin/env python3
"""Run regulatory-data-query-agent evaluations against a local DeepAgents service."""

from __future__ import annotations

import argparse
import json
import re
import time
import urllib.error
import urllib.request
from datetime import datetime
from pathlib import Path
from typing import Any

EVAL_DIR = Path(__file__).resolve().parent
REPO_ROOT = EVAL_DIR.parents[2]
DEFAULT_QUESTIONS = EVAL_DIR / "questions.json"
DEFAULT_TOKEN_FILE = REPO_ROOT / "data/internal-api.token"
DEFAULT_BASE_URL = "http://127.0.0.1:8003"
AGENT_CODE = "regulatory-data-query-agent"
SKILL_CODE = "regulatory-data-query"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--questions", type=Path, default=DEFAULT_QUESTIONS)
    parser.add_argument("--result", type=Path)
    parser.add_argument("--ids", help="Comma-separated question IDs")
    parser.add_argument("--limit", type=int)
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--token-file", type=Path, default=DEFAULT_TOKEN_FILE)
    parser.add_argument("--timeout-seconds", type=int, default=120)
    parser.add_argument("--regrade-only", action="store_true")
    return parser.parse_args()


def normalized(value: Any) -> str:
    return re.sub(r"[\s*`_\"'“”‘’：:，,。；;（）()]", "", str(value)).lower()


def _contains(actual: Any, expected: Any) -> bool:
    if isinstance(expected, dict):
        return isinstance(actual, dict) and all(
            key in actual and _contains(actual[key], value) for key, value in expected.items()
        )
    if isinstance(expected, list):
        return isinstance(actual, list) and all(
            any(_contains(actual_item, expected_item) for actual_item in actual)
            for expected_item in expected
        )
    return normalized(actual) == normalized(expected)


def collect_trace(output: dict[str, Any]) -> dict[str, Any]:
    answer = ""
    tool_calls: list[str] = []
    tool_call_details: list[dict[str, Any]] = []
    call_names: dict[str, str] = {}
    tool_result_details: list[dict[str, Any]] = []
    for message in output.get("messages", []):
        message_type = message.get("type")
        content = message.get("content")
        if message_type == "ai" and isinstance(content, str) and content.strip():
            answer = content.strip()
        for call in message.get("tool_calls") or []:
            name = str(call.get("name") or "")
            if not name:
                continue
            tool_calls.append(name)
            detail = {"name": name, "args": call.get("args") or {}}
            tool_call_details.append(detail)
            if call.get("id"):
                call_names[str(call["id"])] = name
        if message_type == "tool":
            parsed: Any = content
            if isinstance(content, str):
                try:
                    parsed = json.loads(content)
                except json.JSONDecodeError:
                    pass
            call_id = str(message.get("tool_call_id") or "")
            tool_result_details.append(
                {
                    "name": str(message.get("name") or call_names.get(call_id) or ""),
                    "result": parsed,
                }
            )
    return {
        "answer": answer,
        "tool_calls": tool_calls,
        "tool_call_details": tool_call_details,
        "tool_result_details": tool_result_details,
        "tool_call_count": len(tool_calls),
        "tool_result_count": len(tool_result_details),
    }


def grade(
    question: dict[str, Any],
    answer: str,
    error: str | None,
    trace: dict[str, Any],
) -> dict[str, Any]:
    checks: list[dict[str, Any]] = []
    normalized_answer = normalized(answer)
    tool_calls = list(trace.get("tool_calls", []))
    tool_call_details = list(trace.get("tool_call_details", []))
    result_text = normalized(
        json.dumps(trace.get("tool_result_details", []), ensure_ascii=False, default=str)
    )
    checks.append({"name": "completed", "passed": not error and bool(answer.strip())})
    for index, alternatives in enumerate(question.get("required_any", []), start=1):
        checks.append(
            {
                "name": f"required_answer_{index}",
                "passed": any(normalized(term) in normalized_answer for term in alternatives),
                "alternatives": alternatives,
            }
        )
    for term in question.get("forbidden_any", []):
        checks.append(
            {
                "name": f"forbidden_answer:{term}",
                "passed": normalized(term) not in normalized_answer,
            }
        )
    for name in question.get("required_tools", []):
        checks.append(
            {"name": f"required_tool:{name}", "passed": name in tool_calls}
        )
    for name in question.get("forbidden_tools", []):
        checks.append(
            {"name": f"forbidden_tool:{name}", "passed": name not in tool_calls}
        )
    for index, expectation in enumerate(question.get("required_tool_args", []), start=1):
        passed = any(
            detail.get("name") == expectation["name"]
            and _contains(detail.get("args") or {}, expectation.get("contains") or {})
            for detail in tool_call_details
        )
        checks.append(
            {
                "name": f"required_tool_args_{index}:{expectation['name']}",
                "passed": passed,
                "contains": expectation.get("contains") or {},
            }
        )
    for index, alternatives in enumerate(question.get("required_tool_args_any", []), start=1):
        passed = any(
            any(
                detail.get("name") == expectation["name"]
                and _contains(detail.get("args") or {}, expectation.get("contains") or {})
                for detail in tool_call_details
            )
            for expectation in alternatives
        )
        checks.append(
            {
                "name": f"required_tool_args_any_{index}",
                "passed": passed,
                "alternatives": alternatives,
            }
        )
    for index, terms in enumerate(question.get("required_tool_result_any", []), start=1):
        checks.append(
            {
                "name": f"required_tool_result_{index}",
                "passed": all(normalized(term) in result_text for term in terms),
                "terms": terms,
            }
        )
    passed_count = sum(1 for check in checks if check["passed"])
    return {
        "score": round(passed_count / len(checks), 4) if checks else 0.0,
        "passed": bool(checks) and all(check["passed"] for check in checks),
        "checks": checks,
    }


def invoke(
    *,
    base_url: str,
    token: str,
    timeout_seconds: int,
    messages: str | list[dict[str, Any]],
    system_prompt: str,
) -> dict[str, Any]:
    payload = json.dumps(
        {
            "messages": messages,
            "agent_code": AGENT_CODE,
            "skill_dirs": [SKILL_CODE],
            "system_prompt": system_prompt,
        },
        ensure_ascii=False,
    ).encode("utf-8")
    request = urllib.request.Request(
        base_url.rstrip("/") + "/v1/agents/invoke",
        data=payload,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
        body = json.loads(response.read().decode("utf-8"))
    return dict(body.get("output") or {})


def _selected_questions(args: argparse.Namespace, suite: dict[str, Any]) -> list[dict[str, Any]]:
    questions = list(suite["questions"])
    if args.ids:
        requested = {value.strip() for value in args.ids.split(",") if value.strip()}
        questions = [question for question in questions if question["id"] in requested]
    if args.limit is not None:
        questions = questions[: args.limit]
    if not questions:
        raise ValueError("没有匹配的评测问题")
    return questions


def main() -> int:
    args = parse_args()
    suite = json.loads(args.questions.read_text(encoding="utf-8"))
    questions = _selected_questions(args, suite)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    result_path = args.result or EVAL_DIR / "results" / f"run-{timestamp}.jsonl"
    result_path.parent.mkdir(parents=True, exist_ok=True)

    if args.regrade_only:
        records = [
            json.loads(line)
            for line in result_path.read_text(encoding="utf-8").splitlines()
            if line.strip()
        ]
        question_by_id = {question["id"]: question for question in questions}
        for record in records:
            question = question_by_id.get(record.get("question_id"))
            if question:
                record["grading"] = grade(
                    question,
                    record.get("answer", ""),
                    record.get("error"),
                    record,
                )
        result_path.write_text(
            "".join(json.dumps(record, ensure_ascii=False) + "\n" for record in records),
            encoding="utf-8",
        )
        selected = [record for record in records if record.get("question_id") in question_by_id]
        passed = sum(int(record["grading"]["passed"]) for record in selected)
        print(f"RESULT {result_path}")
        print(f"SUMMARY passed={passed} failed={len(selected) - passed} total={len(selected)}")
        return 0 if passed == len(selected) else 1

    token = args.token_file.read_text(encoding="utf-8").strip()
    passed = 0
    with result_path.open("w", encoding="utf-8") as output_file:
        for index, question in enumerate(questions, start=1):
            started = time.monotonic()
            error: str | None = None
            trace = collect_trace({})
            try:
                agent_output = invoke(
                    base_url=args.base_url,
                    token=token,
                    timeout_seconds=args.timeout_seconds,
                    messages=question.get("messages") or question["question"],
                    system_prompt=suite["system_prompt"],
                )
                trace = collect_trace(agent_output)
            except (OSError, ValueError, urllib.error.HTTPError) as exc:
                error = f"{type(exc).__name__}: {exc}"
            duration_seconds = round(time.monotonic() - started, 3)
            grading = grade(question, trace["answer"], error, trace)
            passed += int(grading["passed"])
            record = {
                "suite": suite["suite"],
                "question_id": question["id"],
                "category": question["category"],
                "question": question["question"],
                "answer": trace["answer"],
                "error": error,
                "duration_seconds": duration_seconds,
                **{key: value for key, value in trace.items() if key != "answer"},
                "grading": grading,
            }
            output_file.write(json.dumps(record, ensure_ascii=False) + "\n")
            output_file.flush()
            status = "PASS" if grading["passed"] else "FAIL"
            print(
                f"[{index:02d}/{len(questions):02d}] {question['id']} {status} "
                f"score={grading['score']:.2f} duration={duration_seconds:.1f}s "
                f"tools={trace['tool_call_count']}",
                flush=True,
            )
    print(f"RESULT {result_path}")
    print(f"SUMMARY passed={passed} failed={len(questions) - passed} total={len(questions)}")
    return 0 if passed == len(questions) else 1


if __name__ == "__main__":
    raise SystemExit(main())
