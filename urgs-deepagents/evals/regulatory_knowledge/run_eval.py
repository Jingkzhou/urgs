#!/usr/bin/env python3
"""Run the regulatory knowledge agent against the real local model and vault."""

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
DEFAULT_VAULT = REPO_ROOT / "regulatory-knowledge-vault"
DEFAULT_QUESTIONS = EVAL_DIR / "questions.json"
DEFAULT_PROMPT_SQL = (
    REPO_ROOT
    / "urgs-api/src/main/resources/db/migration/"
    "V105__Refine_Regulatory_Knowledge_Agent_Retrieval.sql"
)
GLOBAL_FORBIDDEN = ("让我先验证", "Worker 引用", "内部思考", "I need to verify")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--questions", type=Path, default=DEFAULT_QUESTIONS)
    parser.add_argument("--prompt-sql", type=Path, default=DEFAULT_PROMPT_SQL)
    parser.add_argument("--vault", type=Path, default=DEFAULT_VAULT)
    parser.add_argument("--result", type=Path)
    parser.add_argument("--ids", help="Comma-separated question IDs")
    parser.add_argument("--limit", type=int)
    parser.add_argument(
        "--question-timeout-seconds",
        type=int,
        default=0,
        help="单题超时秒数；0 表示不限制（默认）",
    )
    parser.add_argument("--resume", action="store_true", help="跳过结果文件中已有的问题")
    parser.add_argument("--regrade-only", action="store_true", help="仅按当前规则重算已有结果")
    parser.add_argument("--debug", action="store_true")
    return parser.parse_args()


def load_system_prompt(path: Path) -> str:
    sql = path.read_text(encoding="utf-8")
    concat_match = re.search(r"SET\s+v_system_prompt\s*=\s*CONCAT\((.*?)\);", sql, re.DOTALL)
    if concat_match:
        chunks = re.findall(r"'((?:''|[^'])*)'", concat_match.group(1), re.DOTALL)
        if chunks:
            return "".join(chunks).replace("''", "'").replace("\\n", "\n")
    patterns = (
        r"`system_prompt`\s*=\s*'(.*?)',\s*\n\s*`",
        r"\n\s*'(你是 URGS 平台的监管知识库助手.*?)',\s*\n\s*0,",
    )
    for pattern in patterns:
        match = re.search(pattern, sql, re.DOTALL)
        if match:
            return match.group(1).replace("''", "'").replace("\\n", "\n")
    raise ValueError(f"无法从迁移脚本提取 system_prompt: {path}")


def configure_runtime() -> None:
    token_file = REPO_ROOT / "data/internal-api.token"
    if token_file.is_file():
        os.environ.setdefault("DEEPAGENTS_INTERNAL_API_TOKEN", token_file.read_text().strip())
    os.environ.setdefault("DEEPAGENTS_URGS_API_URL", "http://127.0.0.1:8080")
    sys.path.insert(0, str(DEEPAGENTS_DIR / "src"))


class QuestionTimeoutError(TimeoutError):
    pass


def _raise_question_timeout(signum: int, frame: Any) -> None:
    raise QuestionTimeoutError("单题执行超过评测时限")


def normalized(value: str) -> str:
    return re.sub(r"[\s*`_\"'“”‘’：:，,。；;（）()]", "", value).lower()


def _trace_contains_group(tool_call_details: list[dict[str, Any]], terms: list[str]) -> bool:
    return any(
        all(
            normalized(term) in normalized(json.dumps(detail, ensure_ascii=False))
            for term in terms
        )
        for detail in tool_call_details
    )


def grade(
    question: dict[str, Any],
    answer: str,
    error: str | None,
    tool_summary: dict[str, Any] | None = None,
) -> dict[str, Any]:
    checks: list[dict[str, Any]] = []
    normalized_answer = normalized(answer)
    tool_call_details = list((tool_summary or {}).get("tool_call_details", []))
    normalized_trace = normalized(json.dumps(tool_call_details, ensure_ascii=False))

    checks.append({"name": "completed", "passed": not error and bool(answer.strip())})
    for index, alternatives in enumerate(question.get("required_any", []), start=1):
        passed = any(normalized(str(term)) in normalized_answer for term in alternatives)
        checks.append(
            {
                "name": f"required_{index}",
                "passed": passed,
                "alternatives": alternatives,
            }
        )
    for term in question.get("forbidden_any", []):
        checks.append(
            {
                "name": f"forbidden:{term}",
                "passed": normalized(term) not in normalized_answer,
            }
        )
    for index, source in enumerate(question.get("required_sources", []), start=1):
        alternatives = source if isinstance(source, list) else [source]
        checks.append(
            {
                "name": f"required_source_{index}",
                "passed": any(normalized(str(item)) in normalized_trace for item in alternatives),
                "alternatives": alternatives,
            }
        )
    for index, pattern in enumerate(question.get("required_tool_patterns", []), start=1):
        terms = pattern if isinstance(pattern, list) else [pattern]
        checks.append(
            {
                "name": f"required_tool_pattern_{index}",
                "passed": _trace_contains_group(tool_call_details, [str(term) for term in terms]),
                "terms": terms,
            }
        )
    for term in GLOBAL_FORBIDDEN:
        checks.append(
            {
                "name": f"presentation:{term}",
                "passed": normalized(term) not in normalized_answer,
            }
        )

    passed_count = sum(1 for check in checks if check["passed"])
    score = round(passed_count / len(checks), 4) if checks else 0.0
    return {
        "score": score,
        "passed": bool(checks) and all(check["passed"] for check in checks),
        "checks": checks,
    }


def collect_tool_summary(result: dict[str, Any]) -> dict[str, Any]:
    tool_calls: list[str] = []
    tool_call_details: list[dict[str, Any]] = []
    tool_results = 0
    for message in result.get("messages", []):
        for call in getattr(message, "tool_calls", None) or []:
            name = call.get("name")
            if name:
                tool_calls.append(str(name))
                tool_call_details.append(
                    {
                        "name": str(name),
                        "args": json.loads(
                            json.dumps(call.get("args") or {}, ensure_ascii=False, default=str)
                        ),
                    }
                )
        if message.__class__.__name__ == "ToolMessage":
            tool_results += 1
    return {
        "tool_calls": tool_calls,
        "tool_call_details": tool_call_details,
        "tool_call_count": len(tool_calls),
        "tool_result_count": tool_results,
    }


def main() -> int:
    args = parse_args()
    configure_runtime()

    from urgs_deepagents_service.config import get_settings
    from urgs_deepagents_service.model_config import build_chat_model
    from urgs_deepagents_service.orchestrator.utils import assistant_text_from_output
    from urgs_deepagents_service.runtime import create_runtime_agent, graph_config

    suite = json.loads(args.questions.read_text(encoding="utf-8"))
    questions = suite["questions"]
    if args.ids:
        requested = {value.strip() for value in args.ids.split(",") if value.strip()}
        questions = [question for question in questions if question["id"] in requested]
    if args.limit is not None:
        questions = questions[: args.limit]
    if not questions:
        raise ValueError("没有匹配的评测问题")

    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    result_path = args.result or EVAL_DIR / "results" / f"run-{timestamp}.jsonl"
    result_path.parent.mkdir(parents=True, exist_ok=True)
    selected_ids = {question["id"] for question in questions}
    if args.regrade_only:
        if not result_path.is_file():
            raise FileNotFoundError(f"结果文件不存在: {result_path}")
        question_by_id = {question["id"]: question for question in questions}
        records: list[dict[str, Any]] = []
        for line in result_path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            record = json.loads(line)
            question = question_by_id.get(record.get("question_id"))
            if question is not None:
                record["grading"] = grade(
                    question,
                    record.get("answer", ""),
                    record.get("error"),
                    record,
                )
            records.append(record)
        result_path.write_text(
            "".join(json.dumps(record, ensure_ascii=False) + "\n" for record in records),
            encoding="utf-8",
        )
        selected_records = [
            record for record in records if record.get("question_id") in selected_ids
        ]
        passed = sum(int(record["grading"]["passed"]) for record in selected_records)
        print(f"RESULT {result_path}")
        print(
            f"SUMMARY passed={passed} failed={len(selected_records) - passed} "
            f"total={len(selected_records)}"
        )
        return 0 if passed == len(selected_records) else 1

    existing_records: dict[str, dict[str, Any]] = {}
    if args.resume and result_path.is_file():
        for line in result_path.read_text(encoding="utf-8").splitlines():
            if not line.strip():
                continue
            record = json.loads(line)
            if record.get("question_id") in selected_ids:
                existing_records[record["question_id"]] = record
        questions = [question for question in questions if question["id"] not in existing_records]

    if not questions:
        passed = sum(int(record["grading"]["passed"]) for record in existing_records.values())
        print(f"RESULT {result_path}")
        print(
            f"SUMMARY passed={passed} failed={len(existing_records) - passed} "
            f"total={len(existing_records)}"
        )
        return 0 if passed == len(existing_records) else 1

    args.vault = args.vault.resolve()
    if not (args.vault / "AGENTS.md").is_file():
        raise FileNotFoundError(f"监管知识库缺少 AGENTS.md: {args.vault}")

    prompt = load_system_prompt(args.prompt_sql.resolve())
    settings = get_settings()
    model = build_chat_model(settings, settings.model)
    agent = create_runtime_agent(
        model=model,
        settings=settings,
        system_prompt=prompt,
        memory_files="/AGENTS.md",
        skill_dirs=None,
        tool_allowlist="ls,read_file,glob,grep",
        allow_write=False,
        workspace_root=str(args.vault),
        debug=args.debug,
        agent_code="regulatory-knowledge-agent",
    )

    passed = sum(int(record["grading"]["passed"]) for record in existing_records.values())
    total = len(existing_records) + len(questions)
    mode = "a" if args.resume and result_path.is_file() else "w"
    with result_path.open(mode, encoding="utf-8") as output:
        for index, question in enumerate(questions, start=1):
            started = time.monotonic()
            answer = ""
            error: str | None = None
            tool_summary: dict[str, Any] = {
                "tool_calls": [],
                "tool_call_details": [],
                "tool_call_count": 0,
                "tool_result_count": 0,
            }
            try:
                if args.question_timeout_seconds > 0:
                    signal.signal(signal.SIGALRM, _raise_question_timeout)
                    signal.setitimer(signal.ITIMER_REAL, args.question_timeout_seconds)
                result = agent.invoke(
                    {"messages": question["question"]},
                    config=graph_config(settings),
                )
                answer = assistant_text_from_output(result)
                tool_summary = collect_tool_summary(result)
            except Exception as exc:
                error = f"{type(exc).__name__}: {exc}"
            finally:
                if args.question_timeout_seconds > 0:
                    signal.setitimer(signal.ITIMER_REAL, 0)
            duration_seconds = round(time.monotonic() - started, 3)
            grading = grade(question, answer, error, tool_summary)
            passed += int(grading["passed"])
            record = {
                "suite": suite["suite"],
                "prompt_sql": str(args.prompt_sql.resolve().relative_to(REPO_ROOT)),
                "question_id": question["id"],
                "category": question["category"],
                "question": question["question"],
                "source_truth": question.get("source_truth", []),
                "answer": answer,
                "error": error,
                "duration_seconds": duration_seconds,
                **tool_summary,
                "grading": grading,
            }
            output.write(json.dumps(record, ensure_ascii=False) + "\n")
            output.flush()
            status = "PASS" if grading["passed"] else "FAIL"
            print(
                f"[{index + len(existing_records):02d}/{total:02d}] "
                f"{question['id']} {status} "
                f"score={grading['score']:.2f} duration={duration_seconds:.1f}s "
                f"tools={tool_summary['tool_call_count']}",
                flush=True,
            )

    print(f"RESULT {result_path}")
    print(f"SUMMARY passed={passed} failed={total - passed} total={total}")
    return 0 if passed == total else 1


if __name__ == "__main__":
    raise SystemExit(main())
