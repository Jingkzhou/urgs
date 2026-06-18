"""编排主流程：Input Guard -> Router -> (Planner?) -> Worker -> Review -> (Rework?) -> Finalizer。

按用户给定的流程图实现：
- 简单：Worker 直接执行
- 复杂：Planner 先拆任务，再 Worker 执行
- Reviewer 验收 -> 合格 Finalizer 返回；不合格返工一次 -> 再验收 ->
  仍不合格返回最佳结果 + quality_risk=true

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

from collections.abc import AsyncIterator
from typing import Any

from urgs_deepagents_service.model_config import build_chat_model
from urgs_deepagents_service.orchestrator.finalizer import stream_final_answer
from urgs_deepagents_service.orchestrator.input_guard import local_input_guard, run_input_guard
from urgs_deepagents_service.orchestrator.planner import run_planner
from urgs_deepagents_service.orchestrator.reviewer import run_review, run_review_with_feedback
from urgs_deepagents_service.orchestrator.router import run_router
from urgs_deepagents_service.orchestrator.state import (
    OrchestrationState,
    PlanStep,
    RoutingResult,
    WorkerOutput,
)
from urgs_deepagents_service.orchestrator.utils import StreamContext, sse
from urgs_deepagents_service.orchestrator.worker import run_worker
from urgs_deepagents_service.schemas import OrchestratorRequest, RouterAgentDescriptor
from urgs_deepagents_service.sse import safe_error_payload


def _extract_user_message(messages: str | list[dict[str, Any]]) -> str:
    if isinstance(messages, str):
        return messages
    for item in reversed(messages):
        if isinstance(item, dict) and item.get("role") == "user":
            content = item.get("content")
            if isinstance(content, str) and content.strip():
                return content
    # 退化为拼接
    return "\n".join(str(item.get("content", "")) for item in messages if isinstance(item, dict))


def _find_agent(agents: list[RouterAgentDescriptor], code: str) -> RouterAgentDescriptor | None:
    for agent in agents:
        if agent.agent_code == code:
            return agent
    return None


async def stream_orchestration(request: OrchestratorRequest, settings: Any) -> AsyncIterator[str]:
    """编排主入口，产出 SSE 事件流。"""
    context = StreamContext()
    state = OrchestrationState(run_id=context.run_id)

    def emit(
        event: str,
        payload: Any,
        *,
        step_id: str | None = None,
        agent_code: str | None = None,
        status: str | None = None,
        message: str | None = None,
    ) -> str:
        return sse(
            event,
            payload,
            context,
            step_id=step_id,
            agent_code=agent_code,
            status=status,
            message=message,
        )

    def done_payload() -> dict[str, Any]:
        state.record("done", "completed", "编排完成")
        return state.done_payload()

    try:
        user_message = _extract_user_message(request.messages)
        state.user_message = user_message

        # 1. Input Guard
        state.record("input_guard", "started", "正在校验输入")
        yield emit(
            "agent",
            {"type": "thinking", "title": "Input Guard", "content": "正在校验输入"},
            step_id="input_guard.start",
            status="started",
            message="正在校验输入",
        )
        local_guard = local_input_guard(user_message)
        if local_guard is not None:
            guard = local_guard
            model = None
        else:
            model = build_chat_model(settings, request.model or settings.model)
            guard = await run_input_guard(model, user_message)
        if guard.passed:
            state.record("input_guard", "passed", guard.reason or "Input Guard 通过")
            yield emit(
                "input_guard",
                {
                    "type": "input_guard",
                    "status": "passed",
                    "reason": guard.reason,
                    "category": guard.category,
                },
                step_id="input_guard.completed",
                status="passed",
                message=guard.reason or "Input Guard 通过",
            )
        else:
            state.quality_risk = True
            state.quality_risk_reason = f"输入被拒绝：{guard.reason}"
            state.record("input_guard", "rejected", guard.reason or "Input Guard 拒绝")
            state.record("quality_risk", "failed", state.quality_risk_reason)
            yield emit(
                "input_guard",
                {
                    "type": "input_guard",
                    "status": "rejected",
                    "reason": guard.reason,
                    "category": guard.category,
                },
                step_id="input_guard.rejected",
                status="rejected",
                message=guard.reason or "Input Guard 拒绝",
            )
            yield emit(
                "quality_risk",
                {"type": "quality_risk", "reason": f"输入被拒绝：{guard.reason}"},
                step_id="quality_risk.input_guard",
                status="failed",
                message="输入被拒绝",
            )
            yield emit(
                "done",
                done_payload(),
                step_id="orchestrator.done",
                status="completed",
                message="编排完成",
            )
            return
        if model is None:
            model = build_chat_model(settings, request.model or settings.model)

        # 2. Router / Supervisor（若已预选则跳过路由）
        config_lookup = request.agent_configs or {}

        def get_config(code: str) -> Any:
            return config_lookup.get(code)

        if request.selected_agent_code:
            routing_agent_code = request.selected_agent_code
            selected = _find_agent(request.agents, routing_agent_code)
            if selected is None:
                state.record("error", "failed", "预选 agent_code 不在目录中")
                yield emit(
                    "error",
                    {"error": "预选 agent_code 不在目录中", "agent_code": routing_agent_code},
                    step_id="routing.error",
                    agent_code=routing_agent_code,
                    status="failed",
                    message="预选 agent_code 不在目录中",
                )
                return
            routing = RoutingResult(
                agent_code=routing_agent_code,
                confidence=1.0,
                reason="手动预选 Agent，跳过 Router",
                task_type="manual",
                is_complex=False,
            )
            state.record(
                "routing", "skipped", "手动预选 Agent，跳过 Router", agent_code=routing_agent_code
            )
        else:
            state.record("routing", "started", "正在识别任务并选择 Agent")
            yield emit(
                "agent",
                {"type": "thinking", "title": "Router", "content": "正在识别任务并选择 Agent"},
                step_id="routing.start",
                status="started",
                message="正在识别任务并选择 Agent",
            )
            routing = await run_router(model, user_message, request.agents)
            routing_agent_code = routing.agent_code
            selected = _find_agent(request.agents, routing_agent_code)
            if selected is None:
                state.record("error", "failed", "Router 选择了不存在的 agent_code")
                yield emit(
                    "error",
                    {"error": "Router 选择了不存在的 agent_code", "agent_code": routing_agent_code},
                    step_id="routing.error",
                    agent_code=routing_agent_code,
                    status="failed",
                    message="Router 选择了不存在的 agent_code",
                )
                return

        state.routing = routing
        state.selected_agent_code = routing_agent_code
        yield emit(
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
            step_id="routing.completed",
            agent_code=routing_agent_code,
            status="completed",
            message=routing.reason or "路由完成",
        )

        # 非 DEEPAGENTS Agent（无运行时配置）：交回 API 侧走遗留执行路径
        if get_config(routing_agent_code) is None:
            state.path = "handoff"
            state.handoff_agent_code = routing_agent_code
            state.record(
                "handoff",
                "completed",
                "非 DEEPAGENTS Agent，交回 API 侧执行",
                agent_code=routing_agent_code,
            )
            yield emit(
                "handoff",
                {
                    "type": "handoff",
                    "agent_code": routing_agent_code,
                    "agent_name": selected.agent_name,
                    "build_mode": selected.build_mode,
                },
                step_id="handoff",
                agent_code=routing_agent_code,
                status="completed",
                message="非 DEEPAGENTS Agent，交回 API 侧执行",
            )
            yield emit(
                "done",
                done_payload(),
                step_id="orchestrator.done",
                status="completed",
                message="编排完成",
            )
            return

        outputs: list[WorkerOutput] = []
        steps: list[PlanStep] = []

        if not routing.is_complex:
            state.path = "simple"
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
                stream_context=context,
            )
            async for evt in run.events():
                yield evt
            outputs = [run.output]
            state.worker_outputs = outputs
        else:
            state.path = "complex"
            # 复杂路径：Planner 拆解 -> 串行 Worker 执行（不流式，仅过程事件）
            candidate_agents = [
                agent.agent_code
                for agent in request.agents
                if get_config(agent.agent_code) is not None
            ]
            state.record("planning", "started", "开始拆解复杂任务")
            yield emit(
                "planning",
                {"type": "planning", "status": "started"},
                step_id="planning.start",
                status="started",
                message="开始拆解复杂任务",
            )
            steps = await run_planner(model, user_message, candidate_agents)
            state.plan = steps
            state.record("planning", "completed", "复杂任务拆解完成", details={"steps": len(steps)})
            yield emit(
                "planning",
                {
                    "type": "planning",
                    "status": "completed",
                    "steps": [
                        {
                            "step": s.step,
                            "agent": s.agent,
                            "task": s.task,
                            "depends_on": s.depends_on,
                        }
                        for s in steps
                    ],
                },
                step_id="planning.completed",
                status="completed",
                message="复杂任务拆解完成",
            )
            context_parts: list[str] = []
            for step in steps:
                cfg = get_config(step.agent)
                if cfg is None:
                    state.path = "handoff"
                    state.handoff_agent_code = step.agent
                    state.record(
                        "handoff",
                        "completed",
                        "Planner 选择了非 DEEPAGENTS Agent，交回 API 侧执行",
                        agent_code=step.agent,
                        details={"step": step.step},
                    )
                    yield emit(
                        "handoff",
                        {
                            "type": "handoff",
                            "agent_code": step.agent,
                            "step": step.step,
                            "reason": "planned_step_without_deepagents_config",
                        },
                        step_id=f"handoff.step.{step.step}",
                        agent_code=step.agent,
                        status="completed",
                        message="Planner 选择了非 DEEPAGENTS Agent，交回 API 侧执行",
                    )
                    yield emit(
                        "done",
                        done_payload(),
                        step_id="orchestrator.done",
                        status="completed",
                        message="编排完成",
                    )
                    return
                run = await run_worker(
                    model=model,
                    settings=settings,
                    agent_code=step.agent,
                    agent_config=cfg,
                    task=step.task,
                    context="\n".join(context_parts),
                    stream_content=False,
                    debug=request.debug,
                    stream_context=context,
                )
                async for evt in run.events():
                    yield evt
                run.output.step = step.step
                outputs.append(run.output)
                state.worker_outputs = outputs
                context_parts.append(f"[{step.agent}] {run.output.answer}")

        # 3. Reviewer 验收
        state.record("review", "started", "正在验收产出")
        yield emit(
            "agent",
            {"type": "thinking", "title": "Reviewer", "content": "正在验收产出"},
            step_id="review.start",
            status="started",
            message="正在验收产出",
        )
        review = await run_review(model, user_message, outputs)
        state.reviews.append(review)
        state.record("review", "passed" if review.passed else "failed", review.reason)
        yield _review_event(review, context)

        # 4. 返工判定
        if not review.passed:
            state.rework_attempts = 1
            state.record("rework", "started", "验收未通过，开始第 1 次返工")
            yield emit(
                "rework",
                {"type": "rework", "status": "started", "attempt": 1},
                step_id="rework.1.start",
                status="started",
                message="验收未通过，开始第 1 次返工",
            )
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
                    stream_context=context,
                )
                async for evt in run.events():
                    yield evt
                rework_outputs = [run.output]
            else:
                context_parts2: list[str] = []
                for step in steps:
                    cfg = get_config(step.agent)
                    if cfg is None:
                        state.path = "handoff"
                        state.handoff_agent_code = step.agent
                        state.record(
                            "handoff",
                            "completed",
                            "返工计划包含非 DEEPAGENTS Agent，交回 API 侧执行",
                            agent_code=step.agent,
                            details={"step": step.step},
                        )
                        yield emit(
                            "handoff",
                            {
                                "type": "handoff",
                                "agent_code": step.agent,
                                "step": step.step,
                                "reason": "rework_step_without_deepagents_config",
                            },
                            step_id=f"handoff.rework.step.{step.step}",
                            agent_code=step.agent,
                            status="completed",
                            message="返工计划包含非 DEEPAGENTS Agent，交回 API 侧执行",
                        )
                        yield emit(
                            "done",
                            done_payload(),
                            step_id="orchestrator.done",
                            status="completed",
                            message="编排完成",
                        )
                        return
                    run = await run_worker(
                        model=model,
                        settings=settings,
                        agent_code=step.agent,
                        agent_config=cfg,
                        task=step.task,
                        context="\n".join(context_parts2) + f"\n前次验收反馈：\n{feedback}",
                        stream_content=False,
                        debug=request.debug,
                        stream_context=context,
                    )
                    async for evt in run.events():
                        yield evt
                    run.output.step = step.step
                    rework_outputs.append(run.output)
                    context_parts2.append(f"[{step.agent}] {run.output.answer}")

            review2 = await run_review_with_feedback(model, user_message, rework_outputs, feedback)
            state.reviews.append(review2)
            state.record("review", "passed" if review2.passed else "failed", review2.reason)
            yield _review_event(review2, context, step_id="review.rework")

            if review2.passed:
                outputs = rework_outputs
                state.worker_outputs = outputs
                state.record("finalizing", "started", "开始生成最终答案")
                yield emit(
                    "finalizing",
                    {"type": "finalizing"},
                    step_id="finalizer.start",
                    status="started",
                    message="开始生成最终答案",
                )
                cfg = get_config(routing.agent_code)
                async for evt in stream_final_answer(
                    model=model,
                    settings=settings,
                    agent_config=cfg,
                    user_message=user_message,
                    outputs=outputs,
                    review=review2,
                    quality_risk=False,
                    debug=request.debug,
                    stream_context=context,
                    prefer_direct_answer=not routing.is_complex,
                    direct_message="返工验收通过，直接返回结果",
                ):
                    yield evt
                yield emit(
                    "done",
                    done_payload(),
                    step_id="orchestrator.done",
                    status="completed",
                    message="编排完成",
                )
                return
            else:
                # 仍不合格：返回最佳结果 + quality_risk
                state.worker_outputs = rework_outputs
                state.quality_risk = True
                state.quality_risk_reason = f"返工后仍未通过验收：{review2.reason}"
                state.record("quality_risk", "failed", state.quality_risk_reason)
                yield emit(
                    "quality_risk",
                    {"type": "quality_risk", "reason": state.quality_risk_reason},
                    step_id="quality_risk.rework",
                    status="failed",
                    message="返工后仍未通过验收",
                )
                state.record("finalizing", "started", "开始生成带质量风险的最终答案")
                yield emit(
                    "finalizing",
                    {"type": "finalizing"},
                    step_id="finalizer.start",
                    status="started",
                    message="开始生成带质量风险的最终答案",
                )
                cfg = get_config(routing.agent_code)
                async for evt in stream_final_answer(
                    model=model,
                    settings=settings,
                    agent_config=cfg,
                    user_message=user_message,
                    outputs=rework_outputs,
                    review=review2,
                    quality_risk=True,
                    debug=request.debug,
                    stream_context=context,
                ):
                    yield evt
                yield emit(
                    "done",
                    done_payload(),
                    step_id="orchestrator.done",
                    status="completed",
                    message="编排完成",
                )
                return

        # 验收合格：输出最终答案
        state.record("finalizing", "started", "开始生成最终答案")
        yield emit(
            "finalizing",
            {"type": "finalizing"},
            step_id="finalizer.start",
            status="started",
            message="开始生成最终答案",
        )
        cfg = get_config(routing.agent_code)
        async for evt in stream_final_answer(
            model=model,
            settings=settings,
            agent_config=cfg,
            user_message=user_message,
            outputs=outputs,
            review=review,
            quality_risk=False,
            debug=request.debug,
            stream_context=context,
            prefer_direct_answer=not routing.is_complex,
        ):
            yield evt

        yield emit(
            "done",
            done_payload(),
            step_id="orchestrator.done",
            status="completed",
            message="编排完成",
        )
    except Exception as exc:
        state.record("error", "failed", "编排失败")
        yield sse("error", safe_error_payload(context, message="编排失败", exc=exc), context)


def _review_event(review: Any, context: StreamContext, step_id: str = "review.completed") -> str:
    return sse(
        "review",
        {
            "type": "review",
            "status": "passed" if review.passed else "failed",
            "score": review.score,
            "reason": review.reason,
            "issues": review.issues,
        },
        context,
        step_id=step_id,
        status="passed" if review.passed else "failed",
        message=review.reason or ("验收通过" if review.passed else "验收未通过"),
    )
