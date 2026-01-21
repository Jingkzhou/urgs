# Chat 路由 - CrewAI 版本
# 处理聊天请求，调用 CrewAI Crew 执行

import uuid
from typing import AsyncGenerator

from fastapi import APIRouter
from sse_starlette.sse import EventSourceResponse

from agent.crews import run_crew, URGSCrew, classify_intent
from agent.policies.approval_policy import ApprovalPolicy
from agent.policies.injection_guard import InjectionGuard
from core.config import get_settings
from core.logging import get_logger
from schemas.api import (
    ChatRequest,
    ChatResponse,
    ChatStatus,
    PendingApproval,
)
from schemas.events import SSEEvent
from storage.audit_store import AuditStore
from storage.session_store import SessionStore

router = APIRouter()
logger = get_logger("chat")

# 复用现有的存储和策略
session_store = SessionStore()
audit_store = AuditStore()
approval_policy = ApprovalPolicy()
injection_guard = InjectionGuard()


@router.post("/chat", response_model=ChatResponse)
async def chat_endpoint(payload: ChatRequest) -> ChatResponse:
    """
    同步聊天接口
    接收用户请求，调用 CrewAI 处理，返回结果
    """
    # 安全检查
    injection_guard.assert_safe(payload.text)

    # 创建会话
    session_id = payload.session_id or await session_store.create_session(
        user_id=payload.user_id,
        context=payload.context.model_dump() if payload.context else None,
    )
    trace_id = uuid.uuid4().hex
    message_id = f"msg_{uuid.uuid4().hex}"

    # 审计记录
    await audit_store.record_event(
        session_id, "chat_started", {"text": payload.text}, trace_id
    )

    # 检查是否需要审批（危险操作）
    pending = _maybe_require_approval(payload.text)
    if pending:
        await session_store.store_pending(session_id, pending)
        await session_store.set_status(session_id, ChatStatus.NEED_APPROVAL.value)
        await audit_store.record_event(
            session_id, "approval_created", pending.model_dump(), trace_id
        )
        return ChatResponse(
            session_id=session_id,
            message_id=message_id,
            status=ChatStatus.NEED_APPROVAL,
            pending_approval=pending,
        )

    # 调用 CrewAI 执行
    try:
        context = payload.context.model_dump() if payload.context else {}
        answer = run_crew(payload.text, context)
    except Exception as e:
        logger.error("crew_execution_failed", error=str(e))
        answer = f"处理请求时发生错误: {str(e)}"

    # 记录结果
    await audit_store.record_event(
        session_id, "final_answer", {"answer": answer[:500]}, trace_id
    )
    await session_store.set_status(session_id, ChatStatus.COMPLETED.value)

    return ChatResponse(
        session_id=session_id,
        message_id=message_id,
        answer=answer,
        status=ChatStatus.COMPLETED,
    )


@router.post("/chat/stream")
async def chat_stream(payload: ChatRequest) -> EventSourceResponse:
    """
    流式聊天接口 (SSE)
    实时返回处理进度
    """
    injection_guard.assert_safe(payload.text)

    session_id = payload.session_id or await session_store.create_session(
        user_id=payload.user_id,
        context=payload.context.model_dump() if payload.context else None,
    )
    trace_id = uuid.uuid4().hex
    message_id = f"msg_{uuid.uuid4().hex}"

    await audit_store.record_event(
        session_id, "chat_started", {"text": payload.text}, trace_id
    )

    async def event_generator() -> AsyncGenerator[str, None]:
        # 发送开始事件
        yield SSEEvent(
            type="start", trace_id=trace_id, payload={"session_id": session_id}
        ).as_sse_message()

        # 发送处理中提示
        intent = classify_intent(payload.text)
        yield SSEEvent(
            type="token",
            trace_id=trace_id,
            payload={"text": f"正在分析请求 (意图: {intent})..."},
        ).as_sse_message()

        # 检查审批
        pending = _maybe_require_approval(payload.text)
        if pending:
            await session_store.store_pending(session_id, pending)
            await session_store.set_status(session_id, ChatStatus.NEED_APPROVAL.value)
            await audit_store.record_event(
                session_id, "approval_created", pending.model_dump(), trace_id
            )
            yield SSEEvent(
                type="need_approval", trace_id=trace_id, payload=pending.model_dump()
            ).as_sse_message()
            return

        # 执行 CrewAI
        try:
            yield SSEEvent(
                type="token",
                trace_id=trace_id,
                payload={"text": "Crew 正在协作处理..."},
            ).as_sse_message()

            context = payload.context.model_dump() if payload.context else {}
            answer = run_crew(payload.text, context)

            await audit_store.record_event(
                session_id, "final_answer", {"answer": answer[:500]}, trace_id
            )
            await session_store.set_status(session_id, ChatStatus.COMPLETED.value)

            yield SSEEvent(
                type="final",
                trace_id=trace_id,
                payload={
                    "session_id": session_id,
                    "message_id": message_id,
                    "answer": answer,
                },
            ).as_sse_message()

        except Exception as e:
            logger.error("crew_stream_failed", error=str(e))
            yield SSEEvent(
                type="error", trace_id=trace_id, payload={"error": str(e)}
            ).as_sse_message()

    return EventSourceResponse(event_generator())


def _maybe_require_approval(text: str):
    """检查是否需要审批（危险操作检测）"""
    danger_keywords = (
        "删除",
        "重跑",
        "drop",
        "truncate",
        "update",
        "trigger",
        "执行",
        "运行",
    )
    if any(keyword.lower() in text.lower() for keyword in danger_keywords):
        return approval_policy.build_pending(
            action_summary=text[:120], reason="疑似写操作，需人工确认"
        )
    return None
