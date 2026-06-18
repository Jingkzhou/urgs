"""编排主流程：Input Guard -> Router -> (Planner?) -> Worker -> Review -> (Rework?) -> Finalizer。

按用户给定的流程图实现：
- 简单：Worker 直接执行
- 复杂：Planner 先拆任务，再 Worker 执行
- Reviewer 验收 -> 合格 Finalizer 返回；不合格返工一次 -> 再验收 -> 仍不合格返回最佳结果 + quality_risk=true

SSE 事件协议（event 名 : 关键字段）：
  input_guard  {status: passed|rejected, reason, category}
  routing      {agent_code, confidence, reason, task_type, is_complex}
  planning     {status: started|completed, steps?}
  worker       {status: started|completed, agent_code, task, answer_preview?}
  content      {content}                      # 最终/流式答案文本
  agent        {type: thinking|tool_call|tool_result, ...}  # 过程事件
  review       {status: passed|failed, score, reason, issues}
  rework       {status: started, attempt}
  finalizing   {}
  quality_risk {reason}
  done         {done: true}
  error        {error}
"""

from __future__ import annotations

import json
from collections.abc import AsyncIterator
from typing import Any

from urgs_deepagents_service.model_config import build_chat_model
from urgs_deepagents_service.orchestrator.finalizer import stream_finalizer
from urgs_deepagents_service.orchestrator.input_guard import run_input_guard
from urgs_deepagents_service.orchestrator.planner import run_planner
from urgs_deepagents_service.orchestrator.reviewer import run_review, run_review_with_feedback
from urgs_deepagents_service.orchestrator.router import run_router
from urgs_deepagents_service.orchestrator.state import RoutingResult, WorkerOutput
from urgs_deepagents_service.orchestrator.utils import assistant_text_from_output, sse
from urgs_deepagents_service.orchestrator.worker import run_worker
from urgs_deepagents_service.schemas import OrchestratorRequest, RouterAgentDescriptor


def _extract_user_message(messages: str | list[dict[str, Any]]) -> str:
    if isinstance(messages, str):
        return messages
    for item in reversed(messages):
        if isinstance(item, dict) and item.get("role") == "user":
            content = item.get("content")
            if isinstance(content, str) and content.strip():
                return content
    # 退化为拼接
    return "\n".join(
        str(item.get("content", "")) for item in messages if isinstance(item, dict)
    )


def _find_agent(agents: list[RouterAgentDescriptor], code: str) -> RouterAgentDescriptor | None:
    for agent in agents:
        if agent.agent_code == code:
            return agent
    return None


async def stream_orchestration(
    request: OrchestratorRequest, settings: Any
) -> AsyncIterator[str]:
    """编排主入口，产出 SSE 事件流。"""
    try:
        model = build_chat_model(settings, request.model or settings.model)
        user_message = _extract_user_message(request.messages)

        # 1. Input Guard
        yield sse("agent", {"type": "thinking", "title": "Input Guard", "content": "正在校验输入"})
        guard = await run_input_guard(model, user_message)
        if guard.passed:
            yield sse(
                "input_guard",
                {"type": "input_guard", "status": "passed", "reason": guard.reason, "category": guard.category},
            )
        else:
            yield sse(
                "input_guard",
                {"type": "input_guard", "status": "rejected", "reason": guard.reason, "category": guard.category},
            )
            yield sse("quality_risk", {"type": "quality_risk", "reason": f"输入被拒绝：{guard.reason}"})
            yield sse("done", {"done": True})
            return

        # 2. Router / Supervisor（若已预选则跳过路由）
        config_lookup = request.agent_configs or {}

        def get_config(code: str) -> Any:
            return config_lookup.get(code)

        if request.selected_agent_code:
            routing_agent_code = request.selected_agent_code
            selected = _find_agent(request.agents, routing_agent_code)
            if selected is None:
                yield sse("error", {"error": f"预选 agent_code 不在目录中: {routing_agent_code}"})
                return
            routing = RoutingResult(
                agent_code=routing_agent_code,
                confidence=1.0,
                reason="手动预选 Agent，跳过 Router",
                task_type="manual",
                is_complex=False,
            )
        else:
            yield sse("agent", {"type": "thinking", "title": "Router", "content": "正在识别任务并选择 Agent"})
            routing = await run_router(model, user_message, request.agents)
            routing_agent_code = routing.agent_code
            selected = _find_agent(request.agents, routing_agent_code)
            if selected is None:
                yield sse("error", {"error": f"Router 选择了不存在的 agent_code: {routing_agent_code}"})
                return

        yield sse(
            "routing",
            {
                "type": "routing",
                "agent_code": routing_agent_code,
                "agent_name": selected.agent_name,
                "confidence": routing.confidence,
                "reason": routing.reason,
                "task_type": routing.task_type,
                "is_complex": routing.is_complex,
                "build_mode": selected.build_mode,
            },
        )

        # 非 DEEPAGENTS Agent（无运行时配置）：交回 API 侧走遗留执行路径
        if get_config(routing_agent_code) is None:
            yield sse(
                "handoff",
                {
                    "type": "handoff",
                    "agent_code": routing_agent_code,
                    "agent_name": selected.agent_name,
                    "build_mode": selected.build_mode,
                },
            )
            yield sse("done", {"done": True})
            return

        outputs: list[WorkerOutput] = []
        steps: list = []

        if not routing.is_complex:
            # 简单路径：Worker 内部执行，不直接流式到前端。
            # 验收未过前不向用户暴露半成品，最终答案统一由 Finalizer 输出。
            cfg = get_config(routing.agent_code)
            run = await run_worker(
                model=model,
                settings=settings,
                agent_code=routing.agent_code,
                agent_config=cfg,
                task=user_message,
                context="",
                stream_content=False,
                debug=request.debug,
            )
            async for evt in run.events():  # type: ignore[attr-defined]
                yield evt
            outputs = [run.output]
        else:
            # 复杂路径：Planner 拆解 -> 串行 Worker 执行（不流式，仅过程事件）
            candidate_agents = [a.agent_code for a in request.agents]
            yield sse("planning", {"type": "planning", "status": "started"})
            steps = await run_planner(model, user_message, candidate_agents)
            yield sse(
                "planning",
                {
                    "type": "planning",
                    "status": "completed",
                    "steps": [
                        {"step": s.step, "agent": s.agent, "task": s.task, "depends_on": s.depends_on}
                        for s in steps
                    ],
                },
            )
            context_parts: list[str] = []
            for step in steps:
                cfg = get_config(step.agent)
                run = await run_worker(
                    model=model,
                    settings=settings,
                    agent_code=step.agent,
                    agent_config=cfg,
                    task=step.task,
                    context="\n".join(context_parts),
                    stream_content=False,
                    debug=request.debug,
                )
                async for evt in run.events():  # type: ignore[attr-defined]
                    yield evt
                run.output.step = step.step
                outputs.append(run.output)
                context_parts.append(f"[{step.agent}] {run.output.answer}")

        # 3. Reviewer 验收
        yield sse("agent", {"type": "thinking", "title": "Reviewer", "content": "正在验收产出"})
        review = await run_review(model, user_message, outputs)
        yield _review_event(review)

        # 4. 返工判定
        if not review.passed:
            yield sse("rework", {"type": "rework", "status": "started", "attempt": 1})
            feedback = review.reason + ("；" + "; ".join(review.issues) if review.issues else "")
            # 返工：对原 Worker 重跑（简单路径重跑同一 agent；复杂路径重跑所有步骤）
            rework_outputs: list[WorkerOutput] = []
            if not routing.is_complex:
                cfg = get_config(routing.agent_code)
                run = await run_worker(
                    model=model,
                    settings=settings,
                    agent_code=routing.agent_code,
                    agent_config=cfg,
                    task=user_message,
                    context=f"前次验收反馈：\n{feedback}",
                    stream_content=False,
                    debug=request.debug,
                )
                async for evt in run.events():  # type: ignore[attr-defined]
                    yield evt
                rework_outputs = [run.output]
            else:
                context_parts2: list[str] = []
                for step in steps:
                    cfg = get_config(step.agent)
                    run = await run_worker(
                        model=model,
                        settings=settings,
                        agent_code=step.agent,
                        agent_config=cfg,
                        task=step.task,
                        context="\n".join(context_parts2) + f"\n前次验收反馈：\n{feedback}",
                        stream_content=False,
                        debug=request.debug,
                    )
                    async for evt in run.events():  # type: ignore[attr-defined]
                        yield evt
                    run.output.step = step.step
                    rework_outputs.append(run.output)
                    context_parts2.append(f"[{step.agent}] {run.output.answer}")

            review2 = await run_review_with_feedback(model, user_message, rework_outputs, feedback)
            yield _review_event(review2)

            if review2.passed:
                outputs = rework_outputs
                yield sse("finalizing", {"type": "finalizing"})
                cfg = get_config(routing.agent_code)
                # 返工通过：单 Worker 直接透传，多 Worker 走 Finalizer 汇总
                if not routing.is_complex and len(outputs) == 1 and outputs[0].answer:
                    yield sse("agent", {"type": "thinking", "title": "Finalizer 汇总", "content": "返工验收通过，直接返回结果"})
                    yield sse("content", {"content": outputs[0].answer})
                else:
                    async for evt in stream_finalizer(
                        model=model,
                        settings=settings,
                        agent_config=cfg,
                        user_message=user_message,
                        outputs=outputs,
                        review=review2,
                        quality_risk=False,
                        debug=request.debug,
                    ):
                        yield evt
                yield sse("done", {"done": True})
                return
            else:
                # 仍不合格：返回最佳结果 + quality_risk
                yield sse(
                    "quality_risk",
                    {"type": "quality_risk", "reason": f"返工后仍未通过验收：{review2.reason}"},
                )
                yield sse("finalizing", {"type": "finalizing"})
                cfg = get_config(routing.agent_code)
                async for evt in stream_finalizer(
                    model=model,
                    settings=settings,
                    agent_config=cfg,
                    user_message=user_message,
                    outputs=rework_outputs,
                    review=review2,
                    quality_risk=True,
                    debug=request.debug,
                ):
                    yield evt
                yield sse("done", {"done": True})
                return

        # 验收合格：输出最终答案
        yield sse("finalizing", {"type": "finalizing"})
        cfg = get_config(routing.agent_code)
        # 简单路径（单 Worker）：Worker 产出已是完整答案，直接透传，跳过 Finalizer LLM 调用，
        # 节省 token 与延迟，避免事实查询被二次改写引入偏差。
        # 复杂路径（多 Worker）：仍需 Finalizer 汇总。
        if not routing.is_complex and len(outputs) == 1 and outputs[0].answer:
            yield sse("agent", {"type": "thinking", "title": "Finalizer 汇总", "content": "验收通过，直接返回结果"})
            yield sse("content", {"content": outputs[0].answer})
        else:
            async for evt in stream_finalizer(
                model=model,
                settings=settings,
                agent_config=cfg,
                user_message=user_message,
                outputs=outputs,
                review=review,
                quality_risk=False,
                debug=request.debug,
            ):
                yield evt

        yield sse("done", {"done": True})
    except Exception as exc:
        yield sse("error", {"error": f"编排失败: {exc}"})


def _review_event(review: Any) -> str:
    return sse(
        "review",
        {
            "type": "review",
            "status": "passed" if review.passed else "failed",
            "score": review.score,
            "reason": review.reason,
            "issues": review.issues,
        },
    )
