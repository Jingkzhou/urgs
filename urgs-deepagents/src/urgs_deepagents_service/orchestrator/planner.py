"""Planner：复杂任务拆解为子任务步骤。"""

from __future__ import annotations

import json
from typing import Any

from deepagents import create_deep_agent
from langchain_core.language_models import BaseChatModel

from urgs_deepagents_service.orchestrator.state import PlanStep
from urgs_deepagents_service.orchestrator.utils import (
    READ_ONLY_FILESYSTEM_PERMISSIONS,
    ToolVisibilityMiddleware,
    assistant_text_from_output,
)

PLANNER_SYSTEM_PROMPT = """你是 URGS 的 Planner，负责把复杂任务拆解为可串行执行的子任务步骤。

规则：
1. 只能使用请求提供的 candidate_agents 中的 agent_code。
2. 每个步骤必须指明负责的 agent、具体任务描述、依赖的前置步骤编号（depends_on）。
3. 步骤应可串行执行：尽量按依赖顺序编号，避免循环依赖。
4. 步骤数量控制在 2-5 个之间，避免过度拆解。
5. 最后一步通常是汇总/报告类步骤。
6. 只返回 JSON 对象，不要输出 Markdown 或解释性正文。

JSON 字段：
{
  "plan": [
    {"step": 1, "agent": "agent_code", "task": "具体任务", "depends_on": []}
  ]
}
"""


def _parse_plan(text: str, allowed_agents: set[str]) -> list[PlanStep]:
    start = text.find("{")
    end = text.rfind("}")
    if start < 0 or end <= start:
        raise ValueError("Planner 未返回结构化计划")
    data = json.loads(text[start : end + 1])
    raw_steps = data.get("plan") or []
    steps: list[PlanStep] = []
    for idx, item in enumerate(raw_steps, start=1):
        step = PlanStep(
            step=int(item.get("step", idx)),
            agent=str(item.get("agent", "")).strip(),
            task=str(item.get("task", "")).strip(),
            depends_on=[int(x) for x in (item.get("depends_on") or []) if str(x).strip().isdigit()],
        )
        if step.agent not in allowed_agents:
            raise ValueError(f"Planner 使用了未注册的 agent_code: {step.agent}")
        if not step.task:
            raise ValueError(f"Planner 步骤 {step.step} 缺少任务描述")
        steps.append(step)
    if not steps:
        raise ValueError("Planner 未生成任何步骤")
    steps.sort(key=lambda s: s.step)
    return steps


async def run_planner(
    model: BaseChatModel,
    user_message: str,
    candidate_agents: list[str],
) -> list[PlanStep]:
    """拆解复杂任务为子任务步骤列表。"""
    planner = create_deep_agent(
        model=model,
        tools=[],
        system_prompt=PLANNER_SYSTEM_PROMPT,
        permissions=READ_ONLY_FILESYSTEM_PERMISSIONS,
        middleware=[ToolVisibilityMiddleware(allowed=frozenset())],
    )
    user_prompt = (
        f"用户任务：\n{user_message}\n\n"
        f"可用的 candidate_agents：{json.dumps(candidate_agents, ensure_ascii=False)}\n\n"
        "请拆解为可串行执行的子任务步骤。"
    )
    result: Any = await planner.ainvoke({"messages": [{"role": "user", "content": user_prompt}]})
    text = assistant_text_from_output(result).strip()
    return _parse_plan(text, set(candidate_agents))
