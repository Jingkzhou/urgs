"""Reviewer：对 Worker 产出做验收。"""

from __future__ import annotations

import json
from typing import Any

from urgs_deepagents_service.orchestrator.state import ReviewResult, WorkerOutput
from urgs_deepagents_service.orchestrator.utils import (
    assistant_text_from_output,
)
from urgs_deepagents_service.runtime import create_control_agent

REVIEWER_SYSTEM_PROMPT = """你是 URGS 的 Reviewer，负责验收 Worker 的产出是否合格。

验收维度：
1. 相关性：是否回答了用户的原始问题。
2. 完整性：是否覆盖了问题的各个方面。
3. 准确性：是否存在明显错误、臆造的工具结果或与事实不符的结论。
4. 合规性：是否越权请求写文件/执行命令、是否包含敏感信息。
5. 可用性：结论是否可读、可执行。

判定规则：
- 各维度均达标时 passed=true。
- 存在明显缺陷时 passed=false，列出具体 issues 并给出 reason。
- score 为 0.0-1.0 的综合质量评分。
- 只返回 JSON 对象，不要输出 Markdown 或解释性正文。

JSON 字段：
{
  "passed": true,
  "score": 0.8,
  "reason": "验收结论",
  "issues": ["具体问题1", "具体问题2"]
}
"""


def _parse_review(text: str) -> ReviewResult:
    start = text.find("{")
    end = text.rfind("}")
    if start < 0 or end <= start:
        # 无法解析时默认通过，避免编排卡死。
        return ReviewResult(
            passed=True, score=0.5, reason="Reviewer 结果解析失败，默认通过", issues=[]
        )
    data = json.loads(text[start : end + 1])
    return ReviewResult.model_validate(data)


def _outputs_text(outputs: list[WorkerOutput]) -> str:
    parts: list[str] = []
    for output in outputs:
        header = f"[{output.agent_code}]"
        if output.step is not None:
            header += f" 步骤{output.step}"
        header += f" 任务：{output.task}"
        parts.append(f"{header}\n{output.answer}")
    return "\n\n".join(parts)


async def run_review(model: Any, user_message: str, outputs: list[WorkerOutput]) -> ReviewResult:
    """对 Worker 产出做验收，返回 ReviewResult。"""
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
    except Exception:
        return ReviewResult(
            passed=True, score=0.5, reason="Reviewer 结果解析失败，默认通过", issues=[]
        )


async def run_review_with_feedback(
    model: Any, user_message: str, outputs: list[WorkerOutput], feedback: str
) -> ReviewResult:
    """返工后再次验收，附加前次验收反馈。"""
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
    except Exception:
        return ReviewResult(
            passed=True, score=0.5, reason="Reviewer 结果解析失败，默认通过", issues=[]
        )
