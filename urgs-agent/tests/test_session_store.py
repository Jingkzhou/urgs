import pytest

from schemas.api import PendingApproval
from schemas.events import EventRecord
from storage.session_store import SessionStore


@pytest.mark.asyncio
async def test_session_store_lifecycle():
    store = SessionStore()
    session_id = await store.create_session("u1", {"env": "dev"})
    await store.append_event(session_id, EventRecord(type="test", trace_id="t1", payload={"text": "hi"}))
    events = await store.list_events(session_id)
    assert len(events) == 1

    await store.set_status(session_id, "COMPLETED")
    summary = await store.get_session(session_id)
    assert summary["status"] == "COMPLETED"

    approval = PendingApproval(approval_id="a1", reason="r", action_summary="act", expires_at=None)
    await store.store_pending(session_id, approval)
    popped = await store.pop_pending("a1")
    assert popped is not None
    popped_session, pending_obj = popped
    assert popped_session == session_id
    assert pending_obj.approval_id == "a1"
