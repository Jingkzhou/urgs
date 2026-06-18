"""Finalizer：汇总最终答案，标记 quality_risk。"""

from __future__ import annotations

from collections.abc import AsyncIterator
from typing import Any

from deepagents import create_deep_agent
from langchain_core.language_models import BaseChatModel

from urgs_deepagents_service.orchestrator.state import ReviewResult, WorkerOutput
from urgs_deepagents_service.orchestrator.utils import (
    build_agent_kwargs,
    chunk_text,
    graph_config,
    sse,
)


def _outputs_text(outputs: list[WorkerOutput]) -> str:
    parts: list[str] = []
    for output in outputs:
        header = f"[{output.agent_code}]"
        if output.step is not None:
            header += f" 步骤{output.step}"
        header += f" 任务：{output.task}"
        parts.append(f"{header}\n{output.answer}")
    return "\n\n".join(parts)


def _build_system_prompt(quality_risk: bool, review: ReviewResult | None) -> str:
    base = (
        "你是 URGS 的 Finalizer，负责把 Worker 的产出整合为面向用户的最终答案。\n"
        "要求：\n"
        "1. 直接给出可读的最终答案，不要解释编排过程。\n"
        "2. 综合各 Worker 的结论，去除冗余，保留关键事实与结论。\n"
        "3. 如果存在未解决问题，在答案末尾用「注意：」简要说明。\n"
    )
    if quality_risk:
        base += (
            "4. 本次任务已经过一次返工仍未通过验收，存在质量风险。请在答案末尾标注"
            "「⚠️ 质量风险提示：本结果经过返工仍未完全通过验收，请人工复核。」\n"
        )
    if review is not None and review.issues:
        base += f"5. 验收发现的问题：{'; '.join(review.issues)}\n"
    return base


async def stream_finalizer(
    *,
    model: BaseChatModel | str,
    settings: Any,
    agent_config: Any | None,
    user_message: str,
    outputs: list[WorkerOutput],
    review: ReviewResult | None,
    quality_risk: bool,
    debug: bool,
) -> AsyncIterator[str]:
    """流式产出最终答案。以 content 事件下发文本。"""
    runtime_kwargs = build_agent_kwargs(
        settings=settings,
        memory_files=getattr(agent_config, "memory_files", None) if agent_config else None,
        skill_dirs=getattr(agent_config, "skill_dirs", None) if agent_config else None,
        tool_allowlist=getattr(agent_config, "tool_allowlist", None) if agent_config else None,
        allow_write=getattr(agent_config, "allow_write", False) if agent_config else False,
        workspace_root=getattr(agent_config, "workspace_root", None) if agent_config else None,
        debug=debug,
    )
    system_prompt = _build_system_prompt(quality_risk, review)
    finalizer = create_deep_agent(
        model=model,
        tools=[],
        system_prompt=system_prompt,
        **runtime_kwargs,
    )
    user_prompt = (
        f"用户原始问题：\n{user_message}\n\n"
        f"Worker 产出：\n{_outputs_text(outputs)}\n\n"
        "请给出最终答案。"
    )
    yield sse("agent", {"type": "thinking", "title": "Finalizer 汇总", "content": "正在整合最终答案"})
    emitted = False
    async for event in finalizer.astream_events(
        {"messages": [{"role": "user", "content": user_prompt}]}, config=graph_config(settings), version="v2"
    ):
        event_name = event.get("event")
        data = event.get("data") or {}
        if event_name == "on_chat_model_stream":
            text = chunk_text(data.get("chunk"))
            if text:
                emitted = True
                yield sse("content", {"content": text})
            continue
        if event_name == "on_chain_end" and event.get("name") == "LangGraph" and not emitted:
            output = data.get("output")
            text = chunk_text(output)
            if not text:
                from urgs_deepagents_service.orchestrator.utils import assistant_text_from_output

                text = assistant_text_from_output(output)
            if text:
                yield sse("content", {"content": text})
