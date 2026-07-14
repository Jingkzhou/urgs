"""Centralized DeepAgents runtime construction and tool permission policy."""

from __future__ import annotations

import re
from typing import Any

from fastapi import HTTPException
from langchain.agents.middleware import ToolCallLimitMiddleware
from langchain.agents.middleware.types import AgentMiddleware, hook_config
from langchain_core.messages import AIMessage, HumanMessage, ToolCall, ToolMessage

from deepagents import FilesystemPermission, create_deep_agent
from deepagents.backends import FilesystemBackend
from urgs_deepagents_service.orchestrator.progress import (
    PROGRESS_REPORT_INSTRUCTIONS,
    PROGRESS_TOOL_NAME,
    create_progress_tool,
)
from urgs_deepagents_service.regulatory_coverage import (
    regulatory_retrieval_requirements,
    requires_regulatory_coverage_review,
)
from urgs_deepagents_service.skill_loader import load_agent_skill_runtime

READ_ONLY_FILESYSTEM_PERMISSIONS = [
    FilesystemPermission(operations=["write"], paths=["/**"], mode="deny")
]
DEFAULT_EXCLUDED_TOOLS = frozenset({"execute"})
DEFAULT_RECURSION_LIMIT = 100
REGULATORY_KNOWLEDGE_AGENT_CODE = "regulatory-knowledge-agent"
REGULATORY_KNOWLEDGE_TOOL_CALL_LIMIT = 8
WRITE_TOOLS = frozenset({"write_file", "edit_file"})
REGULATORY_REPORT_CODE_PATTERN = re.compile(
    r"(?<![A-Za-z0-9_])(?:"
    r"JS_\d{3}(?:_[A-Z0-9_]+)?|"
    r"IE_\d{3}_\d{3}|"
    r"T_\d+(?:\.(?:\d+|x))+|"
    r"A\d{4}|"
    r"[GS]\d{2}(?:_[A-Z]+|[ⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩ]+)?"
    r")(?![A-Za-z0-9_])"
)


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
    """Filter tools visible to the model on every model call."""

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


class BusinessToolCallLimitMiddleware(ToolCallLimitMiddleware):
    """Limit business tool calls without charging public progress updates."""

    def _matches_tool_filter(self, tool_call: Any) -> bool:
        if tool_call.get("name") == PROGRESS_TOOL_NAME:
            return False
        return super()._matches_tool_filter(tool_call)


def _message_text(content: Any) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(
            str(item.get("text", "")) if isinstance(item, dict) else str(item) for item in content
        )
    return str(content)


class RegulatoryCodeEvidenceMiddleware(AgentMiddleware[Any, Any, Any]):
    """Remove exact report codes absent from this run's retrieval evidence."""

    def after_model(self, state: Any, runtime: Any) -> dict[str, Any] | None:
        messages = state.get("messages", [])
        if not messages:
            return None
        last_message = messages[-1]
        if not isinstance(last_message, AIMessage) or last_message.tool_calls:
            return None

        evidence = "\n".join(
            _message_text(message.content)
            for message in messages
            if isinstance(message, ToolMessage) and message.status != "error"
        )
        if not evidence:
            return None

        answer = _message_text(last_message.content)
        unsupported_codes = {
            match.group(0)
            for match in REGULATORY_REPORT_CODE_PATTERN.finditer(answer)
            if match.group(0) not in evidence
        }
        if not unsupported_codes:
            return None

        sanitized = answer
        for code in sorted(unsupported_codes, key=len, reverse=True):
            sanitized = sanitized.replace(code, "待核验表码")
        sanitized = (
            f"{sanitized.rstrip()}\n\n"
            "注：部分未在本轮检索证据中出现的精确表码已省略，需进一步核验。"
        )
        return {"messages": [last_message.model_copy(update={"content": sanitized})]}

    async def aafter_model(self, state: Any, runtime: Any) -> dict[str, Any] | None:
        return self.after_model(state, runtime)


class RegulatoryRetrievalGateMiddleware(AgentMiddleware[Any, Any, Any]):
    """在复杂监管影响评估完成最小证据检索前阻止模型直接结束。"""

    @staticmethod
    def _tool_calls(messages: list[Any]) -> list[ToolCall]:
        return [
            call
            for message in messages
            if isinstance(message, AIMessage)
            for call in (message.tool_calls or [])
        ]

    @staticmethod
    def _matches(call: ToolCall, name: str, args: dict[str, str]) -> bool:
        if call.get("name") != name:
            return False
        call_args = call.get("args") or {}
        if name == "read_file":
            expected = args["file_path"].lstrip("/")
            actual = str(call_args.get("file_path") or "").lstrip("/")
            return actual == expected
        if name == "grep":
            return str(call_args.get("pattern") or "").strip() == args["pattern"]
        return all(str(call_args.get(key) or "") == value for key, value in args.items())

    @hook_config(can_jump_to=["tools"])
    def after_model(self, state: Any, runtime: Any) -> dict[str, Any] | None:
        messages = state.get("messages", [])
        if not messages:
            return None
        last_message = messages[-1]
        if not isinstance(last_message, AIMessage) or last_message.tool_calls:
            return None

        user_message = "\n".join(
            _message_text(message.content)
            for message in messages
            if isinstance(message, HumanMessage)
        )
        if not requires_regulatory_coverage_review(
            REGULATORY_KNOWLEDGE_AGENT_CODE, user_message
        ):
            return None

        calls = self._tool_calls(messages)
        missing = next(
            (
                (index, name, args)
                for index, (name, args) in enumerate(
                    regulatory_retrieval_requirements(user_message), start=1
                )
                if not any(self._matches(call, name, args) for call in calls)
            ),
            None,
        )
        if missing is None:
            return None

        index, name, args = missing
        forced_call = {
            "name": name,
            "args": args,
            "id": f"regulatory-retrieval-{index}",
            "type": "tool_call",
        }
        return {
            "messages": [
                last_message.model_copy(update={"content": "", "tool_calls": [forced_call]})
            ],
            "jump_to": "tools",
        }

    @hook_config(can_jump_to=["tools"])
    async def aafter_model(self, state: Any, runtime: Any) -> dict[str, Any] | None:
        return self.after_model(state, runtime)


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
    include_platform_skills: bool = True,
    always_allowed_tools: frozenset[str] | None = None,
    debug: bool,
) -> dict[str, Any]:
    """Build safe `create_deep_agent` runtime kwargs.

    Default policy is read-only filesystem and hidden `execute`. Write access requires
    both `allow_write=True` and an explicit write-capable tool allowlist.
    """

    merged_memory = merge_unique(
        normalize_path_list(getattr(settings, "memory_files", "") or ""),
        normalize_path_list(memory_files),
    )
    merged_skills = merge_unique(
        normalize_path_list(getattr(settings, "skill_dirs", "") or "")
        if include_platform_skills
        else [],
        normalize_path_list(skill_dirs),
    )
    allow_set = frozenset(normalize_path_list(tool_allowlist))
    visible_allow_set = allow_set | (always_allowed_tools or frozenset()) if allow_set else None
    write_tools_enabled = bool(getattr(settings, "enable_write_tools", False))
    effective_allow_write = write_tools_enabled and allow_write and bool(allow_set & WRITE_TOOLS)
    permissions: list[FilesystemPermission] = (
        [] if effective_allow_write else READ_ONLY_FILESYSTEM_PERMISSIONS
    )
    kwargs: dict[str, Any] = {
        "permissions": permissions,
        "middleware": [
            ToolVisibilityMiddleware(
                allowed=visible_allow_set,
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
            detail=(
                "配置 memory_files 或 skill_dirs 需要设置 "
                "DEEPAGENTS_WORKSPACE_ROOT 或 agent 级 workspace_root"
            ),
        )
    if merged_memory:
        kwargs["memory"] = merged_memory
    if merged_skills:
        kwargs["skills"] = merged_skills
    return kwargs


def create_control_agent(*, model: Any, system_prompt: str, debug: bool = False) -> Any:
    """Create a no-tools control agent for guard/router/planner/reviewer."""

    return create_deep_agent(
        model=model,
        tools=[],
        system_prompt=system_prompt,
        permissions=READ_ONLY_FILESYSTEM_PERMISSIONS,
        middleware=[ToolVisibilityMiddleware(allowed=frozenset())],
        debug=debug,
    )


def create_runtime_agent(
    *,
    model: Any,
    settings: Any,
    system_prompt: str | None,
    memory_files: str | list[str] | None,
    skill_dirs: str | list[str] | None,
    tool_allowlist: str | list[str] | None,
    allow_write: bool = False,
    workspace_root: str | None = None,
    debug: bool,
    agent_code: str | None = None,
) -> Any:
    """Create a DeepAgent with centralized permission, backend, memory, and skill policy."""

    regulatory_runtime = load_agent_skill_runtime(settings, agent_code, skill_dirs)
    effective_system_prompt = system_prompt
    effective_tool_allowlist = tool_allowlist
    effective_skill_dirs = skill_dirs
    include_platform_skills = True
    runtime_tools: list[Any] = [create_progress_tool()]
    if regulatory_runtime is not None:
        effective_system_prompt = (
            f"{system_prompt or ''}\n\n"
            "## 已启用监管指标查询 Skill\n"
            f"{regulatory_runtime.instructions}"
        ).strip()
        effective_tool_allowlist = list(regulatory_runtime.tool_names)
        effective_skill_dirs = None
        include_platform_skills = False
        runtime_tools.extend(regulatory_runtime.tools)

    effective_system_prompt = (
        f"{effective_system_prompt or ''}\n\n{PROGRESS_REPORT_INSTRUCTIONS}"
    ).strip()

    runtime_kwargs = build_agent_kwargs(
        settings=settings,
        memory_files=memory_files,
        skill_dirs=effective_skill_dirs,
        tool_allowlist=effective_tool_allowlist,
        allow_write=allow_write,
        workspace_root=workspace_root,
        include_platform_skills=include_platform_skills,
        always_allowed_tools=frozenset({PROGRESS_TOOL_NAME}),
        debug=debug,
    )
    if agent_code == REGULATORY_KNOWLEDGE_AGENT_CODE:
        runtime_kwargs["middleware"][:0] = [
            BusinessToolCallLimitMiddleware(
                run_limit=REGULATORY_KNOWLEDGE_TOOL_CALL_LIMIT,
                exit_behavior="continue",
            ),
            RegulatoryRetrievalGateMiddleware(),
            RegulatoryCodeEvidenceMiddleware(),
        ]
    return create_deep_agent(
        model=model,
        tools=runtime_tools,
        system_prompt=effective_system_prompt,
        **runtime_kwargs,
    )
