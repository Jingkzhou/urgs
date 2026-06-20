"""Reviewer：对 Worker 产出做验收。"""

from __future__ import annotations

import json
from typing import Any

from urgs_deepagents_service.orchestrator.state import ReviewResult, WorkerOutput
from urgs_deepagents_service.orchestrator.utils import (
    assistant_text_from_output,
)
from urgs_deepagents_service.runtime import create_control_agent

REVIEW_PASS_SCORE_THRESHOLD = 0.75

REVIEWER_SYSTEM_PROMPT = """你是 URGS 的 Reviewer，负责验收 Worker 的产出是否合格。

验收维度：
1. 相关性：是否回答了用户的原始问题。
2. 完整性：是否覆盖了问题的各个方面。
3. 准确性：是否存在明显错误、臆造的工具结果或与事实不符的结论。
4. 合规性：是否越权请求写文件/执行命令、是否包含敏感信息。
5. 可用性：结论是否可读、可执行。

判定规则：
- 只有所有维度均达标、score >= 0.75、且没有阻断问题时 passed=true。
- 存在明显缺陷、答案为空、泛泛而谈、没有直接回答问题、遗漏关键要求、
  工具结果不可验证或存在安全风险时 passed=false。
- passed=false 时必须列出具体 issues，并在 required_fixes 中给出可执行返工项。
- score 为 0.0-1.0 的综合质量评分。
- 只返回 JSON 对象，不要输出 Markdown 或解释性正文。

JSON 字段：
{
  "passed": true,
  "score": 0.8,
  "reason": "验收结论",
  "issues": ["具体问题1", "具体问题2"],
  "required_fixes": ["返工必须补充的内容1", "返工必须修正的内容2"]
}
"""


def _clean_items(items: list[str]) -> list[str]:
    return [item.strip() for item in items if item.strip()]


def _failure(
    reason: str, issues: list[str], required_fixes: list[str] | None = None
) -> ReviewResult:
    cleaned_issues = _clean_items(issues) or [reason]
    fixes = _clean_items(required_fixes or []) or cleaned_issues
    return ReviewResult(
        passed=False,
        score=0.0,
        reason=reason,
        issues=cleaned_issues,
        required_fixes=fixes,
    )


def _normalize_review(review: ReviewResult) -> ReviewResult:
    review.issues = _clean_items(review.issues)
    review.required_fixes = _clean_items(review.required_fixes)
    if review.passed and (review.score < REVIEW_PASS_SCORE_THRESHOLD or review.issues):
        reason = review.reason or "Reviewer 分数或问题清单未达到通过标准"
        return ReviewResult(
            passed=False,
            score=review.score,
            reason=reason,
            issues=review.issues
            or [f"质量评分 {review.score:.2f} 低于通过阈值 {REVIEW_PASS_SCORE_THRESHOLD:.2f}"],
            required_fixes=review.required_fixes
            or review.issues
            or ["补充缺失内容并确保答案完整、准确、可执行"],
        )
    if not review.passed and not review.required_fixes:
        review.required_fixes = review.issues or ([review.reason] if review.reason else [])
    if not review.reason:
        review.reason = "验收通过" if review.passed else "验收未通过"
    return review


def _parse_review(text: str) -> ReviewResult:
    start = text.find("{")
    end = text.rfind("}")
    if start < 0 or end <= start:
        return _failure(
            "Reviewer 结果解析失败，触发返工",
            ["Reviewer 未返回可解析 JSON，无法证明产出已通过验收"],
            ["重新输出严格符合用户问题的完整答案，并避免遗漏关键结论"],
        )
    data = json.loads(text[start : end + 1])
    return _normalize_review(ReviewResult.model_validate(data))


def _outputs_text(outputs: list[WorkerOutput]) -> str:
    parts: list[str] = []
    for output in outputs:
        header = f"[{output.agent_code}]"
        if output.step is not None:
            header += f" 步骤{output.step}"
        header += f" 任务：{output.task}"
        parts.append(f"{header}\n{output.answer}")
    return "\n\n".join(parts)


def _local_review_failure(outputs: list[WorkerOutput]) -> ReviewResult | None:
    if not outputs:
        return _failure(
            "Worker 未返回任何产出",
            ["没有可验收的 Worker 结果"],
            ["重新执行任务并返回完整答案"],
        )
    blank_outputs = [
        output.agent_code for output in outputs if not output.answer or not output.answer.strip()
    ]
    if blank_outputs:
        return _failure(
            "Worker 产出为空，触发返工",
            [f"{agent_code} 没有返回有效答案" for agent_code in blank_outputs],
            ["补充完整答案，至少覆盖用户问题中的核心诉求"],
        )
    return None


def build_rework_feedback(review: ReviewResult, outputs: list[WorkerOutput]) -> str:
    """生成给 Worker 的结构化返工上下文。"""

    fixes = review.required_fixes or review.issues or ([review.reason] if review.reason else [])
    return (
        "前次验收未通过，请基于以下反馈返工。\n\n"
        f"验收评分：{review.score:.2f}\n"
        f"验收结论：{review.reason or '未说明'}\n"
        f"问题清单：\n{_bullet_list(review.issues)}\n\n"
        f"必须修复：\n{_bullet_list(fixes)}\n\n"
        "前次 Worker 产出（仅作为需要修正的参考，不要机械复述）：\n"
        f"{_outputs_text(outputs)}\n\n"
        "返工要求：直接重做当前任务，优先补齐缺失结论、关键依据、边界条件和可执行步骤；"
        "不要解释 Reviewer 或编排流程。"
    )


def _bullet_list(items: list[str]) -> str:
    cleaned = _clean_items(items)
    if not cleaned:
        return "- 无"
    return "\n".join(f"- {item}" for item in cleaned)


async def run_review(model: Any, user_message: str, outputs: list[WorkerOutput]) -> ReviewResult:
    """对 Worker 产出做验收，返回 ReviewResult。"""
    local_failure = _local_review_failure(outputs)
    if local_failure is not None:
        return local_failure
    reviewer = create_control_agent(
        model=model,
        system_prompt=REVIEWER_SYSTEM_PROMPT,
    )
    user_prompt = (
        f"用户原始问题：\n{user_message}\n\n"
        f"Worker 产出：\n{_outputs_text(outputs)}\n\n"
        "请验收上述产出是否合格。"
    )
    result: Any = await reviewer.ainvoke({"messages": [{"role": "user", "content": user_prompt}]})
    text = assistant_text_from_output(result).strip()
    try:
        return _parse_review(text)
    except Exception as exc:
        return _failure(
            "Reviewer 结果解析失败，触发返工",
            [f"解析异常：{exc.__class__.__name__}"],
            ["重新输出严格符合用户问题的完整答案，并避免遗漏关键结论"],
        )


async def run_review_with_feedback(
    model: Any, user_message: str, outputs: list[WorkerOutput], feedback: str
) -> ReviewResult:
    """返工后再次验收，附加前次验收反馈。"""
    local_failure = _local_review_failure(outputs)
    if local_failure is not None:
        return local_failure
    reviewer = create_control_agent(
        model=model,
        system_prompt=REVIEWER_SYSTEM_PROMPT,
    )
    user_prompt = (
        f"用户原始问题：\n{user_message}\n\n"
        f"Worker 产出（已返工）：\n{_outputs_text(outputs)}\n\n"
        f"前次验收反馈：\n{feedback}\n\n"
        "请再次验收。"
    )
    result: Any = await reviewer.ainvoke({"messages": [{"role": "user", "content": user_prompt}]})
    text = assistant_text_from_output(result).strip()
    try:
        return _parse_review(text)
    except Exception as exc:
        return _failure(
            "Reviewer 结果解析失败，触发质量风险",
            [f"返工后解析异常：{exc.__class__.__name__}"],
            ["人工复核返工结果，并补齐缺失结论"],
        )
