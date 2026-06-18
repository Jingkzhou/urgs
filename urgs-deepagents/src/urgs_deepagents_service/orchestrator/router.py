"""Router / Supervisor：路由分发 + 复杂度判断。"""

from __future__ import annotations

import json
from typing import Any

from deepagents import create_deep_agent
from langchain_core.language_models import BaseChatModel

from urgs_deepagents_service.orchestrator.state import RoutingResult
from urgs_deepagents_service.orchestrator.utils import (
    READ_ONLY_FILESYSTEM_PERMISSIONS,
    ToolVisibilityMiddleware,
    assistant_text_from_output,
)
from urgs_deepagents_service.schemas import RouterAgentDescriptor

ROUTER_SYSTEM_PROMPT = """你是 URGS 的 Router Agent，负责把用户任务分发给最合适的业务 Agent，并判断任务复杂度。

规则：
1. 只能从请求提供的 agents 列表中选择一个 agent_code。
2. 优先选择最匹配的专业 Agent；没有专业 Agent 适合时选择 agent_type=GENERAL 的通用 Agent。
3. 不允许创造新的 agent_code，不允许使用列表外的 Agent。
4. 复杂度判断：任务需要多个步骤、跨多个领域、需要先调研再分析再汇总时，is_complex=true；单一领域、可直接回答的任务 is_complex=false。
5. 只返回 JSON 对象，不要输出 Markdown，不要输出解释性正文。

JSON 字段：
{
  "agent_code": "从 agents 列表选择的编码",
  "confidence": 0.0 到 1.0 的数字,
  "reason": "选择原因",
  "task_type": "任务类型",
  "is_complex": false,
  "collaboration_plan": ""
}
"""


def _agent_catalog_text(agents: list[RouterAgentDescriptor]) -> str:
    rows: list[str] = []
    for agent in agents:
        rows.append(
            json.dumps(
                {
                    "agent_code": agent.agent_code,
                    "agent_name": agent.agent_name,
                    "agent_type": agent.agent_type,
                    "build_mode": agent.build_mode,
                    "description": agent.description,
                    "capability_tags": agent.capability_tags,
                    "routing_examples": agent.routing_examples,
                    "sort_order": agent.sort_order,
                },
                ensure_ascii=False,
            )
        )
    return "\n".join(rows)


def _parse_routing_result(text: str, allowed_codes: set[str]) -> RoutingResult:
    start = text.find("{")
    end = text.rfind("}")
    if start < 0 or end <= start:
        raise ValueError("Router Agent 未返回结构化路由结果")
    data = json.loads(text[start : end + 1])
    result = RoutingResult.model_validate(data)
    if result.agent_code not in allowed_codes:
        raise ValueError(f"Router Agent 返回了未注册的 agent_code: {result.agent_code}")
    return result


async def run_router(
    model: BaseChatModel, user_message: str, agents: list[RouterAgentDescriptor]
) -> RoutingResult:
    """执行路由分发与复杂度判断。"""
    if not agents:
        raise ValueError("agents 不能为空")
    router = create_deep_agent(
        model=model,
        tools=[],
        system_prompt=ROUTER_SYSTEM_PROMPT,
        permissions=READ_ONLY_FILESYSTEM_PERMISSIONS,
        middleware=[ToolVisibilityMiddleware(allowed=frozenset())],
    )
    user_prompt = (
        f"用户任务：\n{user_message}\n\n"
        f"可选 agents，每行一个 JSON：\n{_agent_catalog_text(agents)}\n\n"
        "请选择唯一主责 Agent 并判断复杂度。"
    )
    result: Any = await router.ainvoke({"messages": [{"role": "user", "content": user_prompt}]})
    text = assistant_text_from_output(result).strip()
    allowed_codes = {agent.agent_code for agent in agents}
    return _parse_routing_result(text, allowed_codes)
