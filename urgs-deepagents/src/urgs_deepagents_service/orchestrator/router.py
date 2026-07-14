"""Router / Supervisor：路由分发 + 复杂度判断。"""

from __future__ import annotations

import json
import re
from typing import Any

from urgs_deepagents_service.orchestrator.state import RoutingResult
from urgs_deepagents_service.orchestrator.utils import (
    assistant_text_from_output,
)
from urgs_deepagents_service.runtime import create_control_agent
from urgs_deepagents_service.schemas import RouterAgentDescriptor

REGULATORY_DATA_QUERY_AGENT_CODE = "regulatory-data-query-agent"
_DATA_QUERY_CAPABILITY_FOLLOWUPS = (
    "都能查哪些指标",
    "能查哪些指标",
    "可以查哪些指标",
    "可查哪些指标",
    "有哪些指标可以查",
    "都能查什么",
    "能查询什么",
    "能查哪些数据",
    "有哪些数据可查",
    "有哪些日期",
    "能查哪些日期",
    "有哪些系统",
    "能查哪些系统",
    "有哪些表",
    "能查哪些表",
)
_REGULATORY_KNOWLEDGE_MARKERS = (
    "定义",
    "口径",
    "含义",
    "报送",
    "填报",
    "制度",
    "规则",
    "依据",
    "校验",
    "字段解释",
)

ROUTER_SYSTEM_PROMPT = """你是 URGS 的 Router Agent，负责把用户任务分发给最合适的业务 Agent，
并判断任务复杂度。

规则：
1. 只能从请求提供的 agents 列表中选择一个 agent_code。
2. 优先选择最匹配的专业 Agent；没有专业 Agent 适合时选择 agent_type=GENERAL 的通用 Agent。
3. 不允许创造新的 agent_code，不允许使用列表外的 Agent。
4. 复杂度判断：任务需要多个步骤、跨多个领域、需要先调研再分析再汇总时，
   is_complex=true；单一领域、可直接回答的任务 is_complex=false。
5. 如果请求提供 current_agent_code，它只是当前会话的软绑定：
   - 用户任务明显延续上一轮、补充条件、要求改写/导出/继续处理时，优先复用当前 Agent。
   - 用户任务切换到其他业务领域、工具能力或问题类型时，必须重新选择更匹配的 Agent。
   - 不要因为存在 current_agent_code 就无条件复用。
6. 区分“实际可查询的数据目录”与“监管知识”：
   - 在数据查询会话中追问“能查哪些指标/系统/表/日期”等，是对已接入数据目录的续问，
     应复用监管指标数据查询 Agent。
   - 询问指标定义、业务口径、字段含义、报送要求、制度依据时，才选择监管知识 Agent。
   - 不得用知识库理论覆盖范围替代当前实际已接入、可查询的数据目录。
7. 只返回 JSON 对象，不要输出 Markdown，不要输出解释性正文。

JSON 字段：
{
  "agent_code": "从 agents 列表选择的编码",
  "confidence": 0.0 到 1.0 的数字,
  "reason": "选择原因",
  "task_type": "任务类型",
  "is_complex": false,
  "collaboration_plan": "",
  "reused_current_agent": false
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


def _regulatory_data_query_continuation(
    user_message: str,
    current_agent_code: str | None,
    conversation_context: str,
    agents: list[RouterAgentDescriptor],
) -> RoutingResult | None:
    """Keep short data-catalog follow-ups on the active data-query agent."""

    if current_agent_code != REGULATORY_DATA_QUERY_AGENT_CODE:
        return None
    if not conversation_context.strip():
        return None
    if not any(agent.agent_code == REGULATORY_DATA_QUERY_AGENT_CODE for agent in agents):
        return None
    normalized = re.sub(r"[\s，。！？、,.!?：:]", "", user_message).lower()
    if any(marker in normalized for marker in _REGULATORY_KNOWLEDGE_MARKERS):
        return None
    if not any(pattern in normalized for pattern in _DATA_QUERY_CAPABILITY_FOLLOWUPS):
        return None
    return RoutingResult(
        agent_code=REGULATORY_DATA_QUERY_AGENT_CODE,
        confidence=0.99,
        reason="当前问题是对上一轮监管数据查询范围的续问，继续使用数据查询目录能力",
        task_type="监管数据查询能力续问",
        is_complex=False,
        reused_current_agent=True,
    )


async def run_router(
    model: Any,
    user_message: str,
    agents: list[RouterAgentDescriptor],
    current_agent_code: str | None = None,
    conversation_context: str = "",
) -> RoutingResult:
    """执行路由分发与复杂度判断。"""
    if not agents:
        raise ValueError("agents 不能为空")
    allowed_codes = {agent.agent_code for agent in agents}
    effective_current_agent_code = (
        current_agent_code if current_agent_code in allowed_codes else None
    )
    current_agent = next(
        (agent for agent in agents if agent.agent_code == effective_current_agent_code),
        None,
    )
    continuation = _regulatory_data_query_continuation(
        user_message,
        effective_current_agent_code,
        conversation_context,
        agents,
    )
    if continuation is not None:
        return continuation
    current_section = ""
    if current_agent is not None:
        current_section = (
            "当前会话上一次自动路由使用的 Agent（软绑定，可复用也可切换）：\n"
            f"{json.dumps(current_agent.model_dump(), ensure_ascii=False)}\n\n"
        )
    history_section = ""
    if conversation_context.strip():
        history_section = f"历史对话上下文：\n{conversation_context.strip()}\n\n"
    router = create_control_agent(
        model=model,
        system_prompt=ROUTER_SYSTEM_PROMPT,
    )
    user_prompt = (
        f"用户任务：\n{user_message}\n\n"
        f"{history_section}"
        f"{current_section}"
        f"可选 agents，每行一个 JSON：\n{_agent_catalog_text(agents)}\n\n"
        "请选择唯一主责 Agent 并判断复杂度。"
    )
    result: Any = await router.ainvoke({"messages": [{"role": "user", "content": user_prompt}]})
    text = assistant_text_from_output(result).strip()
    routing = _parse_routing_result(text, allowed_codes)
    routing.reused_current_agent = (
        effective_current_agent_code is not None
        and routing.agent_code == effective_current_agent_code
    )
    return routing
