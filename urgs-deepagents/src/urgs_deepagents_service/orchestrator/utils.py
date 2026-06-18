"""Compatibility helpers for orchestrator modules.

The canonical SSE serialization and DeepAgent runtime policy live in
`urgs_deepagents_service.sse` and `urgs_deepagents_service.runtime`. This module
keeps the previous import path stable for tests and local callers.
"""

from __future__ import annotations

import json
from typing import Any

from urgs_deepagents_service.runtime import (
    DEFAULT_EXCLUDED_TOOLS,
    DEFAULT_RECURSION_LIMIT,
    READ_ONLY_FILESYSTEM_PERMISSIONS,
    ToolVisibilityMiddleware,
    build_agent_kwargs,
    graph_config,
    merge_unique,
    normalize_path_list,
)
from urgs_deepagents_service.sse import StreamContext, serialize, sse

__all__ = [
    "DEFAULT_EXCLUDED_TOOLS",
    "DEFAULT_RECURSION_LIMIT",
    "READ_ONLY_FILESYSTEM_PERMISSIONS",
    "StreamContext",
    "ToolVisibilityMiddleware",
    "assistant_text_from_output",
    "build_agent_kwargs",
    "chunk_text",
    "graph_config",
    "merge_unique",
    "normalize_path_list",
    "serialize",
    "sse",
    "tool_call_payload",
    "tool_result_text",
]


def chunk_text(chunk: Any) -> str:
    content = getattr(chunk, "content", None)
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, str):
                parts.append(item)
            elif isinstance(item, dict) and item.get("type") in {"text", "text_delta"}:
                if item.get("text"):
                    parts.append(str(item["text"]))
        return "".join(parts)
    return ""


def assistant_text_from_output(output: Any) -> str:
    value = serialize(output)
    messages = value.get("messages") if isinstance(value, dict) else None
    if not isinstance(messages, list):
        return chunk_text(output)
    for message in reversed(messages):
        if not isinstance(message, dict):
            continue
        if message.get("type") not in {"ai", "assistant"} and message.get("role") != "assistant":
            continue
        content = message.get("content")
        if isinstance(content, str):
            return content
        if isinstance(content, list):
            parts: list[str] = []
            for item in content:
                if isinstance(item, str):
                    parts.append(item)
                elif isinstance(item, dict) and item.get("text"):
                    parts.append(str(item["text"]))
            return "".join(parts)
    return ""


def tool_call_payload(raw: Any) -> dict[str, Any]:
    value = serialize(raw)
    if isinstance(value, dict):
        return {
            "id": value.get("id") or value.get("tool_call_id"),
            "name": value.get("name") or value.get("tool"),
            "args": value.get("args") or value.get("input"),
        }
    return {"name": str(value)}


def tool_result_text(raw: Any) -> str:
    value = serialize(raw)
    if isinstance(value, dict):
        content = value.get("content") or value.get("output")
        if isinstance(content, str):
            return content
    if isinstance(value, str):
        return value
    return json.dumps(value, ensure_ascii=False)
