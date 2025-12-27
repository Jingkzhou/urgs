import uuid
from typing import AsyncGenerator, Optional

from agent.policies.approval_policy import ApprovalPolicy
from agent.policies.injection_guard import InjectionGuard
from agent.policies.tool_policy import ToolPolicy
from agent.runtime.executor import ToolExecutor
from agent.runtime.tool_registry import ToolRegistry
from agent.state import AgentState
from core.config import Settings, get_settings
from core.logging import get_logger
from langchain_core.messages import HumanMessage
from llm.client import LLMClient
from schemas.api import (
    ApprovalDecisionRequest,
    ApprovalDecisionResponse,
    ApprovalStatus,
    ChatRequest,
    ChatResponse,
    ChatStatus,
    PendingApproval,
    SessionEventsResponse,
    SessionSummary,
)
from schemas.events import EventRecord, SSEEvent
from storage.audit_store import AuditStore
from storage.session_store import SessionStore


class AgentOrchestrator:
    def __init__(
        self,
        settings: Optional[Settings] = None,
        session_store: Optional[SessionStore] = None,
        audit_store: Optional[AuditStore] = None,
    ):
        self.settings = settings or get_settings()
        self.session_store = session_store or SessionStore()
        self.audit_store = audit_store or AuditStore()
        self.tool_policy = ToolPolicy(self.settings)
        self.approval_policy = ApprovalPolicy(self.settings)
        self.injection_guard = InjectionGuard()
        self.tool_registry = ToolRegistry(self.settings)
        self.executor = ToolExecutor(timeout_s=self.settings.tool_timeout_s, max_retries=self.settings.tool_max_retries)
        self.llm_client = LLMClient(self.settings)
        self.logger = get_logger("agent")

    async def run_chat(self, request: ChatRequest) -> ChatResponse:
        self.injection_guard.assert_safe(request.text)
        session_id = request.session_id or await self.session_store.create_session(
            user_id=request.user_id, context=request.context.model_dump() if request.context else None
        )
        trace_id = uuid.uuid4().hex
        message_id = f"msg_{uuid.uuid4().hex}"
        state = AgentState(
            session_id=session_id,
            context=request.context.model_dump() if request.context else {},
            audit_trace_id=trace_id,
        )
        await self.audit_store.record_event(session_id, "chat_started", {"text": request.text}, trace_id)
        await self.session_store.append_event(session_id, EventRecord(type="chat_started", trace_id=trace_id, payload={"text": request.text}))
        pending = self._maybe_require_approval(request.text)
        if pending:
            await self.session_store.store_pending(session_id, pending)
            await self.session_store.set_status(session_id, ChatStatus.NEED_APPROVAL.value)
            await self.audit_store.record_event(session_id, "approval_created", pending.model_dump(), trace_id)
            return ChatResponse(
                session_id=session_id,
                message_id=message_id,
                status=ChatStatus.NEED_APPROVAL,
                pending_approval=pending,
            )

        answer = await self._draft_answer(request, state)
        await self.session_store.append_event(
            session_id,
            EventRecord(
                type="final",
                trace_id=trace_id,
                payload={"answer": answer, "message_id": message_id},
            ),
        )
        await self.audit_store.record_event(session_id, "final_answer", {"answer": answer}, trace_id)
        await self.session_store.set_status(session_id, ChatStatus.COMPLETED.value)
        state.final_answer = answer
        return ChatResponse(session_id=session_id, message_id=message_id, answer=answer, status=ChatStatus.COMPLETED)

    async def run_chat_stream(self, request: ChatRequest) -> AsyncGenerator[SSEEvent, None]:
        self.injection_guard.assert_safe(request.text)
        session_id = request.session_id or await self.session_store.create_session(
            user_id=request.user_id, context=request.context.model_dump() if request.context else None
        )
        trace_id = uuid.uuid4().hex
        message_id = f"msg_{uuid.uuid4().hex}"
        await self.audit_store.record_event(session_id, "chat_started", {"text": request.text}, trace_id)
        planning = SSEEvent(type="token", trace_id=trace_id, payload={"text": "规划中..."})
        await self.session_store.append_event(session_id, planning)
        yield planning

        pending = self._maybe_require_approval(request.text)
        if pending:
            await self.session_store.store_pending(session_id, pending)
            await self.session_store.set_status(session_id, ChatStatus.NEED_APPROVAL.value)
            await self.audit_store.record_event(session_id, "approval_created", pending.model_dump(), trace_id)
            pending_event = SSEEvent(type="need_approval", trace_id=trace_id, payload=pending.model_dump())
            await self.session_store.append_event(session_id, pending_event)
            yield pending_event
            return

        answer = await self._draft_answer(request, AgentState(session_id=session_id, audit_trace_id=trace_id))
        final_event = SSEEvent(
            type="final",
            trace_id=trace_id,
            payload={"session_id": session_id, "message_id": message_id, "answer": answer},
        )
        await self.session_store.append_event(session_id, final_event)
        await self.audit_store.record_event(session_id, "final_answer", {"answer": answer}, trace_id)
        await self.session_store.set_status(session_id, ChatStatus.COMPLETED.value)
        yield final_event

    async def handle_approval(self, approval_id: str, payload: ApprovalDecisionRequest) -> ApprovalDecisionResponse:
        record = await self.session_store.pop_pending(approval_id)
        trace_id = uuid.uuid4().hex
        if not record:
            return ApprovalDecisionResponse(approval_id=approval_id, status=ApprovalStatus.REJECTED, next="RESUME_GRAPH")

        session_id, approval = record
        status = ApprovalStatus.APPROVED if payload.decision.value == "APPROVE" else ApprovalStatus.REJECTED
        await self.audit_store.record_event(
            session_id,
            f"approval_{status.value.lower()}",
            {"comment": payload.comment or "", "approval_id": approval.approval_id},
            trace_id,
        )
        await self.session_store.set_status(session_id, status.value)
        return ApprovalDecisionResponse(approval_id=approval_id, status=status, next="RESUME_GRAPH")

    async def get_session_summary(self, session_id: str) -> SessionSummary:
        session = await self.session_store.get_session(session_id)
        if not session:
            return SessionSummary(session_id=session_id, status="NOT_FOUND", recent_messages=[])

        messages = await self.session_store.recent_messages(session_id)
        return SessionSummary(session_id=session_id, status=session.get("status", "UNKNOWN"), recent_messages=messages)

    async def get_session_events(self, session_id: str) -> SessionEventsResponse:
        events = await self.session_store.list_events(session_id)
        audit_events = await self.audit_store.list_events(session_id)
        merged = sorted(events + audit_events, key=lambda evt: evt.ts)
        return SessionEventsResponse(session_id=session_id, events=merged)

    def _maybe_require_approval(self, text: str) -> Optional[PendingApproval]:
        danger_keywords = ("删除", "重跑", "drop", "truncate", "update", "trigger")
        if any(keyword.lower() in text.lower() for keyword in danger_keywords):
            return self.approval_policy.build_pending(action_summary=text[:120], reason="疑似写操作，需人工确认")
        return None

    async def _draft_answer(self, request: ChatRequest, state: AgentState) -> str:
        messages = [HumanMessage(content=request.text)]
        try:
            ai_message = await self.llm_client.chat(messages)
            if ai_message.content:
                return str(ai_message.content)
        except Exception as exc:  # pragma: no cover - 依赖外部模型时兜底
            self.logger.info("llm_fallback", error=str(exc))

        try:
            prompt = f"用户请求：{request.text}\n上下文：{request.context.model_dump() if request.context else {}}\n请给出简洁回应。"
            _ = prompt  # 占位，后续接入 LangGraph/工具调用
        except Exception:
            pass
        return f"已记录请求「{request.text}」，后续将通过 LangGraph 与工具链执行。"
