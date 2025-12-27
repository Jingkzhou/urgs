import json
from datetime import datetime, timezone
from typing import Any, Dict

from pydantic import BaseModel, Field


class EventRecord(BaseModel):
    type: str
    trace_id: str
    payload: Dict[str, Any] = Field(default_factory=dict)
    ts: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class SSEEvent(EventRecord):
    def as_sse_message(self) -> Dict[str, Any]:
        return {"event": self.type, "data": json.dumps(self.model_dump())}
