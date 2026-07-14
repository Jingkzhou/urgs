"""Finalizer：汇总最终答案，标记 quality_risk。"""

from __future__ import annotations

import json
from collections.abc import AsyncIterator
from typing import Any

from urgs_deepagents_service.orchestrator.state import ReviewResult, WorkerOutput
from urgs_deepagents_service.orchestrator.utils import (
    StreamContext,
    chunk_text,
    graph_config,
    sse,
)
from urgs_deepagents_service.runtime import create_control_agent


def _outputs_text(outputs: list[WorkerOutput]) -> str:
    parts: list[str] = []
    for output in outputs:
        header = f"[{output.agent_code}]"
        if output.step is not None:
            header += f" 步骤{output.step}"
        header += f" 任务：{output.task}"
        body = output.answer
        if output.tool_results:
            body += "\n\n工具调用结果（可信证据）：\n"
            body += json.dumps(output.tool_results, ensure_ascii=False, default=str)
        parts.append(f"{header}\n{body}")
    return "\n\n".join(parts)


def _build_system_prompt(quality_risk: bool, review: ReviewResult | None) -> str:
    base = (
        "你是 URGS 的 Finalizer，负责把 Worker 的产出整合为面向用户的最终答案。\n"
        "要求：\n"
        "1. 直接给出可读的最终答案，不要解释编排过程。\n"
        "2. 综合各 Worker 的结论，去除冗余，保留关键事实与结论。\n"
        "3. 如果存在未解决问题，在答案末尾用「注意：」简要说明。\n"
        "4. 不要向用户输出 Reviewer、验收、返工、quality_risk、required_fixes 等内部流程信息。\n"
        "5. Worker 产出是唯一业务输入，不要再次验证、质疑或推测文件是否存在，"
        "不要声称自己将读取文件。\n"
        "6. 第一段直接回答用户问题；禁止输出“让我先”“我需要先”“下面验证”等自我对话或工作计划。\n"
    )
    if quality_risk:
        base += (
            "7. 本次存在内部质量风险标记，但该标记只用于平台审计；"
            "最终答案只说明业务结果、缺失条件或查询失败原因，不展示内部风险提示。\n"
        )
    return base


async def stream_finalizer(
    *,
    model: Any,
    settings: Any,
    agent_config: Any | None,
    user_message: str,
    outputs: list[WorkerOutput],
    review: ReviewResult | None,
    quality_risk: bool,
    debug: bool,
    stream_context: StreamContext | None = None,
) -> AsyncIterator[str]:
    """流式产出最终答案。以 content 事件下发文本。"""
    event_context = stream_context or StreamContext()
    system_prompt = _build_system_prompt(quality_risk, review)
    finalizer = create_control_agent(
        model=model,
        system_prompt=system_prompt,
        debug=debug,
    )
    user_prompt = (
        f"用户原始问题：\n{user_message}\n\n"
        f"Worker 产出：\n{_outputs_text(outputs)}\n\n"
        "请给出最终答案。"
    )
    yield sse(
        "agent",
        {"type": "thinking", "title": "Finalizer 汇总", "content": "正在整合最终答案"},
        event_context,
        step_id="finalizer.thinking",
        status="started",
        message="正在整合最终答案",
    )
    emitted = False
    async for event in finalizer.astream_events(
        {"messages": [{"role": "user", "content": user_prompt}]},
        config=graph_config(settings),
        version="v2",
    ):
        event_name = event.get("event")
        data = event.get("data") or {}
        if event_name == "on_chat_model_stream":
            text = chunk_text(data.get("chunk"))
            if text:
                emitted = True
                yield sse(
                    "content",
                    {"content": text},
                    event_context,
                    step_id="finalizer.content",
                    status="streaming",
                    message="最终答案增量",
                )
            continue
        if event_name == "on_chain_end" and event.get("name") == "LangGraph" and not emitted:
            output = data.get("output")
            text = chunk_text(output)
            if not text:
                from urgs_deepagents_service.orchestrator.utils import assistant_text_from_output

                text = assistant_text_from_output(output)
            if text:
                yield sse(
                    "content",
                    {"content": text},
                    event_context,
                    step_id="finalizer.content",
                    status="streaming",
                    message="最终答案增量",
                )


async def stream_final_answer(
    *,
    model: Any,
    settings: Any,
    agent_config: Any | None,
    user_message: str,
    outputs: list[WorkerOutput],
    review: ReviewResult | None,
    quality_risk: bool,
    debug: bool,
    stream_context: StreamContext | None = None,
    prefer_direct_answer: bool = False,
    direct_message: str = "验收通过，直接返回结果",
) -> AsyncIterator[str]:
    """统一从 Finalizer 阶段输出最终答案。

    简单单 Worker 可由 Finalizer 阶段直接发布 Worker 的完整答案；质量风险通过事件元数据表达，
    不再调用一个没有工具的新模型重新质疑或改写业务答案。
    复杂、多 Worker 场景仍由 control agent 汇总。
    """
    event_context = stream_context or StreamContext()
    if prefer_direct_answer and len(outputs) == 1 and outputs[0].answer:
        output = outputs[0]
        yield sse(
            "agent",
            {"type": "thinking", "title": "Finalizer 汇总", "content": direct_message},
            event_context,
            step_id="finalizer.direct",
            status="completed",
            message=direct_message,
        )
        yield sse(
            "content",
            {"content": output.answer},
            event_context,
            step_id="finalizer.content",
            agent_code=output.agent_code,
            status="completed",
            message="最终答案",
        )
        return

    async for event in stream_finalizer(
        model=model,
        settings=settings,
        agent_config=agent_config,
        user_message=user_message,
        outputs=outputs,
        review=review,
        quality_risk=quality_risk,
        debug=debug,
        stream_context=event_context,
    ):
        yield event
