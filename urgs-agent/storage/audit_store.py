from typing import Any, Dict, List

from core.logging import get_logger
from schemas.events import EventRecord


class AuditStore:
    def __init__(self):
        self.logger = get_logger("audit")
        self.records: List[EventRecord] = []

    async def record_event(self, session_id: str, event_type: str, payload: Dict[str, Any], trace_id: str) -> EventRecord:
        event = EventRecord(type=event_type, trace_id=trace_id, payload={"session_id": session_id, **payload})
        self.records.append(event)
        self.logger.info("audit_event", event=event.model_dump())
        return event

    async def list_events(self, session_id: str) -> List[EventRecord]:
        return [event for event in self.records if event.payload.get("session_id") == session_id]
