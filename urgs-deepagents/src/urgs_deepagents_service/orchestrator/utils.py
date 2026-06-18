"""编排模块共享的运行时工具：SSE 序列化、消息解析、Agent 构建参数。

为避免与 `main.py` 形成循环导入，此处自包含一份等价的纯函数与中间件副本，
仅服务于编排包内部。行为与 `main.py` 中同名工具保持一致。
"""

from __future__ import annotations

import json
from typing import Any

from deepagents import FilesystemPermission
from deepagents.backends import FilesystemBackend
from fastapi import HTTPException
from langchain.agents.middleware.types import AgentMiddleware


READ_ONLY_FILESYSTEM_PERMISSIONS = [
    FilesystemPermission(operations=["write"], paths=["/**"], mode="deny")
]
DEFAULT_EXCLUDED_TOOLS = frozenset({"execute"})
DEFAULT_RECURSION_LIMIT = 100


def graph_config(settings: Any) -> dict[str, Any]:
    recursion_limit = getattr(settings, "recursion_limit", DEFAULT_RECURSION_LIMIT)
    try:
        recursion_limit = int(recursion_limit)
    except (TypeError, ValueError):
        recursion_limit = DEFAULT_RECURSION_LIMIT
    return {"recursion_limit": max(25, recursion_limit)}


def _tool_name(tool: Any) -> str | None:
    if isinstance(tool, dict):
        name = tool.get("name")
        return name if isinstance(name, str) else None
    name = getattr(tool, "name", None)
    return name if isinstance(name, str) else None


class ToolVisibilityMiddleware(AgentMiddleware[Any, Any, Any]):
    """按白名单/黑名单过滤模型可见工具，与 main.py 中实现等价。"""

    def __init__(
        self,
        *,
        allowed: frozenset[str] | None = None,
        excluded: frozenset[str] = frozenset(),
    ) -> None:
        self.allowed = allowed
        self.excluded = excluded

    def _filter_tools(self, tools: list[Any]) -> list[Any]:
        if self.allowed is not None:
            return [tool for tool in tools if _tool_name(tool) in self.allowed]
        if self.excluded:
            return [tool for tool in tools if _tool_name(tool) not in self.excluded]
        return tools

    def wrap_model_call(self, request: Any, handler: Any) -> Any:
        return handler(request.override(tools=self._filter_tools(request.tools)))

    async def awrap_model_call(self, request: Any, handler: Any) -> Any:
        return await handler(request.override(tools=self._filter_tools(request.tools)))


def serialize(value: Any) -> Any:
    if hasattr(value, "model_dump"):
        return value.model_dump(mode="json")
    if isinstance(value, dict):
        return {key: serialize(item) for key, item in value.items()}
    if isinstance(value, list):
        return [serialize(item) for item in value]
    return value


def sse(event: str, payload: Any) -> str:
    return f"event: {event}\ndata: {json.dumps(serialize(payload), ensure_ascii=False)}\n\n"


def chunk_text(chunk: Any) -> str:
    content = getattr(chunk, "content", None)
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, str):
                parts.append(item)
            elif isinstance(item, dict):
                if item.get("type") in {"text", "text_delta"} and item.get("text"):
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


def normalize_path_list(value: str | list[str] | None) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    items: list[str] = []
    for line in str(value).replace("\uff0c", ",").replace("\uff1b", ";").splitlines():
        for part in line.replace(";", ",").split(","):
            text = part.strip()
            if text:
                items.append(text)
    return items


def merge_unique(*values: list[str]) -> list[str]:
    merged: list[str] = []
    seen: set[str] = set()
    for value in values:
        for item in value:
            if item not in seen:
                seen.add(item)
                merged.append(item)
    return merged


def build_agent_kwargs(
    *,
    settings: Any,
    memory_files: str | list[str] | None,
    skill_dirs: str | list[str] | None,
    tool_allowlist: str | list[str] | None,
    allow_write: bool = False,
    workspace_root: str | None = None,
    debug: bool,
) -> dict[str, Any]:
    """构建 `create_deep_agent` 的运行时 kwargs。

    与 main._agent_runtime_kwargs 一致，额外支持 agent 级写权限与工作空间根目录：
    - allow_write=False（默认）：写权限全局拒绝（只读工作区）。
    - allow_write=True：不附加 write deny 规则，允许在 workspace 内写文件
      （仍受 tool_allowlist 控制，需显式包含 write_file/edit_file）。
    - workspace_root 优先于全局 settings.workspace_root，支持 per-agent 工作空间隔离。
    """
    merged_memory = merge_unique(
        normalize_path_list(getattr(settings, "memory_files", "") or ""),
        normalize_path_list(memory_files),
    )
    merged_skills = merge_unique(
        normalize_path_list(getattr(settings, "skill_dirs", "") or ""),
        normalize_path_list(skill_dirs),
    )
    allow_set = frozenset(normalize_path_list(tool_allowlist))
    # 写权限需要 write_file/edit_file 工具，未在白名单中时强制只读以避免无效放开
    effective_allow_write = allow_write and (
        "write_file" in allow_set or "edit_file" in allow_set
    )
    if effective_allow_write:
        permissions: list[FilesystemPermission] = []
    else:
        permissions = READ_ONLY_FILESYSTEM_PERMISSIONS
    kwargs: dict[str, Any] = {
        "permissions": permissions,
        "middleware": [
            ToolVisibilityMiddleware(
                allowed=allow_set if allow_set else None,
                excluded=DEFAULT_EXCLUDED_TOOLS if not allow_set else frozenset(),
            )
        ],
        "debug": debug,
    }
    root = workspace_root or getattr(settings, "workspace_root", None)
    if root:
        kwargs["backend"] = FilesystemBackend(root_dir=root, virtual_mode=True)
    elif merged_memory or merged_skills:
        raise HTTPException(
            status_code=400,
            detail="配置 memory_files 或 skill_dirs 需要设置 DEEPAGENTS_WORKSPACE_ROOT 或 agent 级 workspace_root",
        )
    if merged_memory:
        kwargs["memory"] = merged_memory
    if merged_skills:
        kwargs["skills"] = merged_skills
    return kwargs
