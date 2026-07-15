#!/usr/bin/env python3
"""Run multi-turn regulatory agent routing evaluations against DeepAgents."""

from __future__ import annotations

import argparse
import json
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


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--questions", type=Path, default=DEFAULT_QUESTIONS)
    parser.add_argument("--result", type=Path)
    parser.add_argument("--ids", help="Comma-separated question IDs")
    parser.add_argument("--limit", type=int)
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--token-file", type=Path, default=DEFAULT_TOKEN_FILE)
    parser.add_argument("--timeout-seconds", type=int, default=120)
    parser.add_argument("--repeat", type=int, default=1)
    return parser.parse_args()


def grade(question: dict[str, Any], response: dict[str, Any], error: str | None) -> dict[str, Any]:
    checks = [
        {"name": "completed", "passed": error is None and bool(response)},
        {
            "name": "agent_code",
            "passed": response.get("agent_code") == question["expected_agent_code"],
            "expected": question["expected_agent_code"],
            "actual": response.get("agent_code"),
        },
    ]
    if "expected_reused_current_agent" in question:
        checks.append(
            {
                "name": "reused_current_agent",
                "passed": response.get("reused_current_agent")
                is question["expected_reused_current_agent"],
                "expected": question["expected_reused_current_agent"],
                "actual": response.get("reused_current_agent"),
            }
        )
    return {
        "passed": all(check["passed"] for check in checks),
        "score": round(sum(int(check["passed"]) for check in checks) / len(checks), 4),
        "checks": checks,
    }


def invoke(
    *,
    base_url: str,
    token: str,
    timeout_seconds: int,
    agents: list[dict[str, Any]],
    question: dict[str, Any],
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "message": question["message"],
        "agents": agents,
    }
    for field in ("current_agent_code", "conversation_context"):
        if field in question:
            payload[field] = question[field]
    request = urllib.request.Request(
        base_url.rstrip("/") + "/v1/router/route",
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        method="POST",
    )
    with urllib.request.urlopen(request, timeout=timeout_seconds) as response:
        return dict(json.loads(response.read().decode("utf-8")))


def selected_questions(args: argparse.Namespace, suite: dict[str, Any]) -> list[dict[str, Any]]:
    questions = list(suite["questions"])
    if args.ids:
        requested = {value.strip() for value in args.ids.split(",") if value.strip()}
        questions = [question for question in questions if question["id"] in requested]
    if args.limit is not None:
        questions = questions[: args.limit]
    if not questions:
        raise ValueError("没有匹配的评测问题")
    if args.repeat < 1:
        raise ValueError("--repeat 必须大于等于 1")
    return questions


def main() -> int:
    args = parse_args()
    suite = json.loads(args.questions.read_text(encoding="utf-8"))
    questions = selected_questions(args, suite)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    result_path = args.result or EVAL_DIR / "results" / f"run-{timestamp}.jsonl"
    result_path.parent.mkdir(parents=True, exist_ok=True)
    token = args.token_file.read_text(encoding="utf-8").strip()
    total = len(questions) * args.repeat
    passed = 0

    with result_path.open("w", encoding="utf-8") as output:
        index = 0
        for repetition in range(1, args.repeat + 1):
            for question in questions:
                index += 1
                started = time.monotonic()
                response: dict[str, Any] = {}
                error: str | None = None
                try:
                    response = invoke(
                        base_url=args.base_url,
                        token=token,
                        timeout_seconds=args.timeout_seconds,
                        agents=suite["agents"],
                        question=question,
                    )
                except (OSError, ValueError, urllib.error.HTTPError) as exc:
                    error = f"{type(exc).__name__}: {exc}"
                duration_seconds = round(time.monotonic() - started, 3)
                grading = grade(question, response, error)
                passed += int(grading["passed"])
                record = {
                    "suite": suite["suite"],
                    "question_id": question["id"],
                    "category": question["category"],
                    "repetition": repetition,
                    "message": question["message"],
                    "current_agent_code": question.get("current_agent_code"),
                    "response": response,
                    "error": error,
                    "duration_seconds": duration_seconds,
                    "grading": grading,
                }
                output.write(json.dumps(record, ensure_ascii=False) + "\n")
                output.flush()
                status = "PASS" if grading["passed"] else "FAIL"
                print(
                    f"[{index:02d}/{total:02d}] {question['id']} {status} "
                    f"agent={response.get('agent_code', '-')} duration={duration_seconds:.1f}s",
                    flush=True,
                )

    print(f"RESULT {result_path}")
    print(f"SUMMARY passed={passed} failed={total - passed} total={total}")
    return 0 if passed == total else 1


if __name__ == "__main__":
    raise SystemExit(main())
