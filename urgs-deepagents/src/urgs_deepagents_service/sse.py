"""SSE event serialization with a stable, backwards-compatible payload envelope."""

from __future__ import annotations

import json
import re
from dataclasses import dataclass, field
from datetime import UTC, datetime
from typing import Any
from uuid import uuid4

SENSITIVE_VALUE_RE = re.compile(
    r"(?i)(bearer\s+)[a-z0-9._\-+/=]+|"
    r"(sk-[a-z0-9_\-]{8,})|"
    r"((?:api[_-]?key|token|secret|password)\s*[=:]\s*)[^\s,;]+|"
    r"(https?://)([^/\s:@]+):([^@\s/]+)@"
)
INTERNAL_URL_RE = re.compile(
    r"https?://(?:127\.0\.0\.1|localhost|10\.\d+\.\d+\.\d+|"
    r"172\.(?:1[6-9]|2\d|3[01])\.\d+\.\d+|192\.168\.\d+\.\d+)"
    r"(?::\d+)?[^\s]*"
)


@dataclass(frozen=True)
class StreamContext:
    """Request-scoped metadata attached to every SSE payload."""

    run_id: str = field(default_factory=lambda: uuid4().hex)
    agent_code: str | None = None

    def for_agent(self, agent_code: str | None) -> StreamContext:
        return StreamContext(run_id=self.run_id, agent_code=agent_code)


def serialize(value: Any) -> Any:
    if hasattr(value, "model_dump"):
        return value.model_dump(mode="json")
    if isinstance(value, dict):
        return {key: serialize(item) for key, item in value.items()}
    if isinstance(value, list):
        return [serialize(item) for item in value]
    return value


def _now_iso() -> str:
    return datetime.now(UTC).isoformat().replace("+00:00", "Z")


def sanitize_text(value: object) -> str:
    """Return a short, log/SSE-safe message without tokens or internal URLs."""

    text = str(value)
    text = SENSITIVE_VALUE_RE.sub(
        lambda m: (m.group(1) or m.group(3) or m.group(4) or "") + "[REDACTED]",
        text,
    )
    text = INTERNAL_URL_RE.sub("[INTERNAL_URL]", text)
    return text[:1000]


def safe_error_payload(
    context: StreamContext,
    *,
    message: str,
    exc: BaseException | None = None,
    step_id: str = "error",
    agent_code: str | None = None,
) -> dict[str, Any]:
    payload: dict[str, Any] = {
        "type": "error",
        "error": message,
        "error_type": exc.__class__.__name__ if exc else "Error",
    }
    if exc is not None:
        payload["detail"] = sanitize_text(exc)
    return event_payload(
        "error",
        payload,
        context,
        step_id=step_id,
        agent_code=agent_code,
        status="failed",
        message=message,
    )


def event_payload(
    event: str,
    payload: Any,
    context: StreamContext | None = None,
    *,
    step_id: str | None = None,
    agent_code: str | None = None,
    status: str | None = None,
    message: str | None = None,
) -> dict[str, Any]:
    value = serialize(payload)
    data = dict(value) if isinstance(value, dict) else {"value": value}
    ctx = context or StreamContext()
    data.setdefault("type", event)
    data.setdefault("event", event)
    data.setdefault("run_id", ctx.run_id)
    data.setdefault("step_id", step_id or event)
    data.setdefault("agent_code", agent_code if agent_code is not None else ctx.agent_code)
    data.setdefault("timestamp", _now_iso())
    data.setdefault("status", status or data.get("status") or "info")
    data.setdefault("message", message or data.get("message") or _default_message(event, data))
    return data


def sse(
    event: str,
    payload: Any,
    context: StreamContext | None = None,
    *,
    step_id: str | None = None,
    agent_code: str | None = None,
    status: str | None = None,
    message: str | None = None,
) -> str:
    data = event_payload(
        event,
        payload,
        context,
        step_id=step_id,
        agent_code=agent_code,
        status=status,
        message=message,
    )
    return f"event: {event}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"


def _default_message(event: str, data: dict[str, Any]) -> str:
    if event == "content":
        return "内容增量"
    for key in ("reason", "title"):
        value = data.get(key)
        if isinstance(value, str) and value:
            return value
    return event
