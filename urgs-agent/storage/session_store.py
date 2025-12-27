import uuid
from typing import Any, Dict, List, Optional, Tuple

from schemas.api import PendingApproval
from schemas.events import EventRecord


class SessionStore:
    def __init__(self):
        self.sessions: Dict[str, Dict[str, Any]] = {}
        self.events: Dict[str, List[EventRecord]] = {}
        self.pending: Dict[str, Dict[str, Any]] = {}

    async def create_session(self, user_id: str, context: Optional[Dict[str, Any]] = None) -> str:
        session_id = f"s_{uuid.uuid4().hex}"
        self.sessions[session_id] = {"user_id": user_id, "context": context or {}, "status": "ACTIVE"}
        self.events[session_id] = []
        return session_id

    async def set_status(self, session_id: str, status: str) -> None:
        if session_id in self.sessions:
            self.sessions[session_id]["status"] = status

    async def append_event(self, session_id: str, event: EventRecord) -> None:
        self.events.setdefault(session_id, []).append(event)

    async def list_events(self, session_id: str) -> List[EventRecord]:
        return self.events.get(session_id, [])

    async def recent_messages(self, session_id: str, limit: int = 5) -> List[str]:
        events = self.events.get(session_id, [])
        texts = [str(evt.payload.get("text", "")) for evt in events if evt.payload.get("text")]
        return texts[-limit:]

    async def store_pending(self, session_id: str, pending: PendingApproval) -> None:
        self.pending[pending.approval_id] = {"session_id": session_id, "approval": pending}

    async def pop_pending(self, approval_id: str) -> Optional[Tuple[str, PendingApproval]]:
        record = self.pending.pop(approval_id, None)
        if not record:
            return None
        return record["session_id"], record["approval"]

    async def get_session(self, session_id: str) -> Optional[Dict[str, Any]]:
        return self.sessions.get(session_id)
