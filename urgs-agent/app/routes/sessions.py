from fastapi import APIRouter

from schemas.api import SessionEventsResponse, SessionSummary
from storage.audit_store import audit_store
from storage.session_store import session_store

router = APIRouter()


@router.get("/{session_id}", response_model=SessionSummary)
async def get_session(session_id: str) -> SessionSummary:
    session = await session_store.get_session(session_id)
    if not session:
        # 如果找不到会话，返回默认空状态
        return SessionSummary(
            session_id=session_id, status="NOT_FOUND", recent_messages=[]
        )

    messages = await session_store.recent_messages(session_id)
    return SessionSummary(
        session_id=session_id,
        status=session.get("status", "UNKNOWN"),
        recent_messages=messages,
    )


@router.get("/{session_id}/events", response_model=SessionEventsResponse)
async def get_session_events(session_id: str) -> SessionEventsResponse:
    events = await session_store.list_events(session_id)
    audit_events = await audit_store.list_events(session_id)
    # 合并审计日志和业务事件，按时间排序
    merged = sorted(events + audit_events, key=lambda evt: evt.ts)
    return SessionEventsResponse(session_id=session_id, events=merged)
