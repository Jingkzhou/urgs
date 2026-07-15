"""Centralized DeepAgents runtime construction and tool permission policy."""

from __future__ import annotations

import hashlib
import json
import logging
import re
from datetime import date, datetime
from typing import Any
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

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
REGULATORY_KNOWLEDGE_TOOL_CALL_HARD_LIMIT = 30
REGULATORY_KNOWLEDGE_MIN_RECURSION_LIMIT = REGULATORY_KNOWLEDGE_TOOL_CALL_HARD_LIMIT * 8
REGULATORY_MARKET_ASSISTANT_AGENT_CODE = "regulatory-market-assistant-agent"
REGULATORY_MARKET_ASSISTANT_TOOL_CALL_HARD_LIMIT = 14
TOOL_LOOP_HISTORY_SIZE = 30
TOOL_LOOP_WARNING_THRESHOLD = 4
TOOL_LOOP_CRITICAL_THRESHOLD = 8
WRITE_TOOLS = frozenset({"write_file", "edit_file"})
DEFAULT_RUNTIME_TIMEZONE = "Asia/Shanghai"
logger = logging.getLogger(__name__)
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


def _runtime_date_context(current_date: date | None = None) -> str:
    if current_date is None:
        try:
            current_date = datetime.now(ZoneInfo(DEFAULT_RUNTIME_TIMEZONE)).date()
        except ZoneInfoNotFoundError:
            logger.warning(
                "Timezone %s unavailable; using local timezone", DEFAULT_RUNTIME_TIMEZONE
            )
            current_date = datetime.now().astimezone().date()
    return (
        "## 运行时日期基准\n"
        f"- 当前日期：{current_date.isoformat()}。\n"
        f"- ‘今年’‘本年’指 {current_date.year} 年；‘本月’和相对月份也必须以当前日期为准。\n"
        "- 不得沿用训练数据年份或自行猜测其他年份；若用户日期仍有歧义，应明确反问。"
    )


def agent_graph_config(settings: Any, agent_code: str | None) -> dict[str, Any]:
    """Size graph depth for agent-specific middleware and tool-call budgets."""

    config = graph_config(settings)
    if agent_code == REGULATORY_KNOWLEDGE_AGENT_CODE:
        config["recursion_limit"] = max(
            config["recursion_limit"], REGULATORY_KNOWLEDGE_MIN_RECURSION_LIMIT
        )
    return config


def _tool_name(tool: Any) -> str | None:
    if isinstance(tool, dict):
        name = tool.get("name")
        return name if isinstance(name, str) else None
    name = getattr(tool, "name", None)
    return name if isinstance(name, str) else None


class ToolVisibilityMiddleware(AgentMiddleware[Any, Any, Any]):
    """Filter visible tools and reject hidden tool calls at execution time."""

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

    def _is_allowed(self, name: str) -> bool:
        if self.allowed is not None:
            return name in self.allowed
        return name not in self.excluded

    @staticmethod
    def _denied_tool_message(tool_call: ToolCall) -> ToolMessage:
        name = str(tool_call.get("name") or "")
        return ToolMessage(
            content=f"工具 {name} 不在当前 Agent 的允许清单中，请使用已授权工具完成任务。",
            tool_call_id=str(tool_call.get("id") or "denied-tool-call"),
            name=name or None,
            status="error",
        )

    def wrap_model_call(self, request: Any, handler: Any) -> Any:
        return handler(request.override(tools=self._filter_tools(request.tools)))

    async def awrap_model_call(self, request: Any, handler: Any) -> Any:
        return await handler(request.override(tools=self._filter_tools(request.tools)))

    def wrap_tool_call(self, request: Any, handler: Any) -> Any:
        if not self._is_allowed(str(request.tool_call.get("name") or "")):
            return self._denied_tool_message(request.tool_call)
        return handler(request)

    async def awrap_tool_call(self, request: Any, handler: Any) -> Any:
        if not self._is_allowed(str(request.tool_call.get("name") or "")):
            return self._denied_tool_message(request.tool_call)
        return await handler(request)


class BusinessToolCallLimitMiddleware(ToolCallLimitMiddleware):
    """Global circuit breaker without charging public progress updates."""

    def _matches_tool_filter(self, tool_call: Any) -> bool:
        if tool_call.get("name") == PROGRESS_TOOL_NAME:
            return False
        return super()._matches_tool_filter(tool_call)


def _tool_call_signature(tool_call: ToolCall) -> str:
    payload = {
        "name": tool_call.get("name") or "",
        "args": tool_call.get("args") or {},
    }
    return json.dumps(payload, ensure_ascii=False, sort_keys=True, default=str)


def _tool_result_signature(message: ToolMessage) -> str:
    payload = {
        "status": getattr(message, "status", None),
        "content": _message_text(message.content),
    }
    raw = json.dumps(payload, ensure_ascii=False, sort_keys=True, default=str)
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


class BusinessToolLoopDetectionMiddleware(AgentMiddleware[Any, Any, Any]):
    """Detect repeated no-progress tool calls using an OpenClaw-style rolling history."""

    def __init__(
        self,
        *,
        history_size: int = TOOL_LOOP_HISTORY_SIZE,
        warning_threshold: int = TOOL_LOOP_WARNING_THRESHOLD,
        critical_threshold: int = TOOL_LOOP_CRITICAL_THRESHOLD,
    ) -> None:
        if warning_threshold >= critical_threshold:
            raise ValueError("warning_threshold must be lower than critical_threshold")
        self.history_size = history_size
        self.warning_threshold = warning_threshold
        self.critical_threshold = critical_threshold

    @staticmethod
    def _history(messages: list[Any]) -> list[tuple[str, str]]:
        calls_by_id: dict[str, ToolCall] = {}
        executions: list[tuple[str, str]] = []
        for message in messages:
            if isinstance(message, AIMessage):
                for call in message.tool_calls or []:
                    call_id = call.get("id")
                    if call_id and call.get("name") != PROGRESS_TOOL_NAME:
                        calls_by_id[call_id] = call
                continue
            if not isinstance(message, ToolMessage):
                continue
            matched_call = calls_by_id.get(message.tool_call_id)
            if matched_call is None:
                continue
            executions.append((_tool_call_signature(matched_call), _tool_result_signature(message)))
        return executions

    def _is_no_progress_repeat(
        self, current_signature: str, history: list[tuple[str, str]]
    ) -> bool:
        matching_results = [
            result for signature, result in history if signature == current_signature
        ]
        required_previous_results = self.critical_threshold - 1
        if len(matching_results) < required_previous_results:
            return False
        recent = matching_results[-required_previous_results:]
        return len(set(recent)) == 1

    def _is_no_progress_ping_pong(
        self, current_signature: str, history: list[tuple[str, str]]
    ) -> bool:
        required_previous_results = self.critical_threshold - 1
        if len(history) < required_previous_results:
            return False
        recent = history[-required_previous_results:]
        signatures = [signature for signature, _ in recent] + [current_signature]
        if len(set(signatures)) != 2:
            return False
        if any(signatures[index] != signatures[index - 2] for index in range(2, len(signatures))):
            return False
        results_by_signature: dict[str, set[str]] = {}
        for signature, result in recent:
            results_by_signature.setdefault(signature, set()).add(result)
        return all(len(results) == 1 for results in results_by_signature.values())

    def after_model(self, state: Any, runtime: Any) -> dict[str, Any] | None:
        messages = state.get("messages", [])
        if not messages:
            return None
        last_message = messages[-1]
        if not isinstance(last_message, AIMessage) or not last_message.tool_calls:
            return None

        history = self._history(messages[:-1])[-self.history_size :]
        blocked_messages: list[ToolMessage] = []
        for call in last_message.tool_calls:
            if call.get("name") == PROGRESS_TOOL_NAME:
                continue
            signature = _tool_call_signature(call)
            repeat_count = sum(1 for previous, _ in history if previous == signature) + 1
            ping_pong = self._is_no_progress_ping_pong(signature, history)
            repeated = self._is_no_progress_repeat(signature, history)
            if repeated or ping_pong:
                pattern = "交替调用" if ping_pong else "相同调用"
                blocked_messages.append(
                    ToolMessage(
                        content=(
                            f"检测到无进展的工具{pattern}循环，已阻止本次调用。"
                            "请调整检索条件、改读更直接的证据页，或基于已有证据明确说明边界。"
                        ),
                        tool_call_id=call.get("id") or "tool-loop-detected",
                        name=call.get("name"),
                        status="error",
                    )
                )
                continue
            if repeat_count >= self.warning_threshold:
                logger.warning(
                    "Possible tool loop: tool=%s repeated=%d without reaching critical threshold",
                    call.get("name"),
                    repeat_count,
                )

        return {"messages": blocked_messages} if blocked_messages else None

    async def aafter_model(self, state: Any, runtime: Any) -> dict[str, Any] | None:
        return self.after_model(state, runtime)


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
        if not requires_regulatory_coverage_review(REGULATORY_KNOWLEDGE_AGENT_CODE, user_message):
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


class RegulatoryMarketWorkflowMiddleware(AgentMiddleware[Any, Any, Any]):
    """Force SQL validation and switch excessive asset exploration to context assembly."""

    EXPLORATION_TOOLS = frozenset(
        {
            "scan_regulatory_catalog",
            "search_regulatory_assets",
            "get_regulatory_table",
            "get_regulatory_element",
            "get_regulatory_code_values",
        }
    )
    EXPLORATION_LIMIT = 7
    SQL_PATTERN = re.compile(
        r"(?is)\b(SELECT|INSERT|DELETE|UPDATE|CREATE|ALTER|DROP)\b.*?(?=。|；|$)"
    )
    REQUESTED_SYSTEM_PATTERN = re.compile(
        r"(?<![A-Za-z0-9_])([A-Z][A-Z0-9]{2,31}|\d{3,12})"
        r"(?![A-Za-z0-9_])(?=\s*(?:系统|的))"
    )
    NON_SYSTEM_TERMS = frozenset({"SQL", "API", "ID", "DDL", "DML"})
    CATALOG_IDENTIFIER_PATTERN = re.compile(
        r"(?<![A-Za-z0-9_$])(?:[A-Za-z][A-Za-z0-9_$]*\.)?"
        r"[A-Za-z][A-Za-z0-9_$]*_[A-Za-z0-9_$]+(?![A-Za-z0-9_$])"
    )
    CODE_TABLE_PATTERN = re.compile(
        r"(?<![A-Za-z0-9_])([A-Z][A-Z0-9]*_[A-Z0-9_]+)(?![A-Za-z0-9_])"
    )

    def __init__(self, allowed_systems: list[str] | tuple[str, ...] | None = None) -> None:
        self.allowed_systems = tuple(
            dict.fromkeys(
                str(item).strip().upper()
                for item in allowed_systems or []
                if str(item).strip()
            )
        )

    def _out_of_scope_systems(
        self, calls: list[ToolCall], user_text: str = ""
    ) -> list[str]:
        if not self.allowed_systems or "ALL" in self.allowed_systems:
            return []
        candidates: list[str] = []
        for call in calls:
            args = call.get("args") or {}
            candidates.append(str(args.get("system_code") or "").strip().upper())
            candidates.extend(
                str(item).strip().upper() for item in args.get("system_codes") or []
            )
        if any(
            call.get("name") in {"scan_regulatory_catalog", "search_regulatory_assets"}
            for call in calls
        ):
            candidates.extend(
                match.group(1).upper()
                for match in self.REQUESTED_SYSTEM_PATTERN.finditer(user_text)
                if match.group(1).upper() not in self.NON_SYSTEM_TERMS
            )
        return list(
            dict.fromkeys(
                system_code
                for system_code in candidates
                if system_code
                and system_code not in self.allowed_systems
            )
        )

    @classmethod
    def _catalog_scan_call(cls, user_text: str, search_call: ToolCall) -> ToolCall:
        args = search_call.get("args") or {}
        keyword = str(args.get("keyword") or "").strip()
        system_code = str(args.get("system_code") or "").strip()
        challenge = any(term in user_text for term in ("不是", "为什么", "质疑", "核验", "对吗"))
        development = cls._is_indicator_development_request(user_text) or "SQL" in user_text.upper()
        mode = "challenge" if challenge else "sql_development" if development else "consultation"
        evidence_needs = ["来源表", "物理绑定"]
        if mode == "sql_development":
            evidence_needs.extend(["查询粒度", "日期字段", "度量字段", "过滤码值", "必要的 JOIN"])
        elif mode == "challenge":
            evidence_needs.extend(["支持证据", "冲突证据"])
        return {
            "name": "scan_regulatory_catalog",
            "args": {
                "mode": mode,
                "requirement": user_text,
                "keywords": [keyword] if keyword else [],
                "exact_identifiers": cls.CATALOG_IDENTIFIER_PATTERN.findall(user_text),
                "system_codes": [system_code] if system_code else [],
                "evidence_needs": evidence_needs,
                "limit": 10,
            },
            "id": f"catalog-scan-{hashlib.sha256(user_text.encode()).hexdigest()[:12]}",
            "type": "tool_call",
        }

    @staticmethod
    def _tool_calls(messages: list[Any]) -> list[ToolCall]:
        return [
            call
            for message in messages
            if isinstance(message, AIMessage)
            for call in (message.tool_calls or [])
        ]

    @staticmethod
    def _current_turn_messages(messages: list[Any]) -> list[Any]:
        for index in range(len(messages) - 1, -1, -1):
            if isinstance(messages[index], HumanMessage):
                return messages[index:]
        return messages

    @staticmethod
    def _last_user_text(messages: list[Any]) -> str:
        return next(
            (
                _message_text(message.content)
                for message in reversed(messages)
                if isinstance(message, HumanMessage)
            ),
            "",
        )

    @staticmethod
    def _parse_tool_payload(message: ToolMessage) -> dict[str, Any] | None:
        content = _message_text(message.content)
        try:
            payload = json.loads(content)
        except (TypeError, json.JSONDecodeError):
            return None
        return payload if isinstance(payload, dict) else None

    @classmethod
    def _latest_development_context(cls, messages: list[Any]) -> dict[str, Any] | None:
        for message in reversed(messages):
            if not isinstance(message, ToolMessage):
                continue
            if str(getattr(message, "name", "") or "") != "build_indicator_context":
                continue
            return cls._parse_tool_payload(message)
        return None

    @classmethod
    def _latest_relationship_context(cls, messages: list[Any]) -> dict[str, Any] | None:
        for message in reversed(messages):
            if not isinstance(message, ToolMessage):
                continue
            if str(getattr(message, "name", "") or "") != "get_regulatory_relationships":
                continue
            return cls._parse_tool_payload(message)
        return None

    @classmethod
    def _has_confirmed_teller_evidence(cls, messages: list[Any]) -> bool:
        payload = cls._latest_development_context(messages)
        if not payload or payload.get("ok") is False:
            return False
        table_confirmed = any(
            isinstance(table, dict) and table.get("name") == "IE_001_103"
            for table in payload.get("tables") or []
        )
        field_confirmed = any(
            isinstance(element, dict)
            and element.get("name") == "SFSTGY"
            and (
                element.get("codeTableCode") == "EAST_SFBZ"
                or (
                    isinstance(element.get("codeTable"), dict)
                    and element["codeTable"].get("tableCode") == "EAST_SFBZ"
                )
            )
            for element in payload.get("selectedElements") or []
        )
        return table_confirmed and field_confirmed

    @staticmethod
    def _missing_context_answer(
        payload: dict[str, Any], extra_missing: list[str] | None = None
    ) -> str:
        missing = [str(item) for item in payload.get("missingInformation") or []]
        for item in extra_missing or []:
            if item not in missing:
                missing.append(item)
        evidence = [str(item) for item in payload.get("evidence") or []]
        lines = [
            "当前监管集市证据不足，无法形成可运行 SQL。",
            "",
            "### 指标设计卡（待补充）",
            "- 来源资产：仅保留当前已定位的逻辑监管资产。",
            "- 来源物理表、字段、过滤、聚合和关联规则：待以下信息闭合后确定。",
            "",
            "### 待确认项",
            *[f"- {item}" for item in missing],
        ]
        if evidence:
            lines.extend(["", "### 资产证据", *[f"- {item}" for item in evidence]])
        lines.extend(
            [
                "",
                "在这些待确认项补齐前，不生成、猜测或静态校验 SQL。",
            ]
        )
        return "\n".join(lines)

    @staticmethod
    def _explicit_requirement_gaps(user_text: str) -> list[str]:
        if not any(term in user_text for term in ("没有说明", "缺少", "未指定", "待确认")):
            return []
        dimensions = (
            ("统计日期", "统计日期或统计周期待确认。"),
            ("统计周期", "统计日期或统计周期待确认。"),
            ("粒度", "统计粒度待确认。"),
            ("机构范围", "机构范围待确认。"),
            ("客户定义", "客户定义待确认。"),
        )
        return list(
            dict.fromkeys(message for term, message in dimensions if term in user_text)
        )

    @staticmethod
    def _has_blocking_physical_gap(payload: dict[str, Any]) -> bool:
        tables = [item for item in payload.get("tables") or [] if isinstance(item, dict)]
        if not tables:
            return True
        return all(not (table.get("physicalTables") or []) for table in tables)

    @classmethod
    def _has_blocking_context_gap(cls, payload: dict[str, Any]) -> bool:
        if cls._has_blocking_physical_gap(payload):
            return True
        return any(
            any(
                term in str(item)
                for term in (
                    "尚未绑定物理字段",
                    "未绑定物理字段",
                    "缺少物理字段",
                    "尚未确认指标使用的具体监管字段",
                    "尚未确认指标使用的具体监管指标",
                )
            )
            for item in payload.get("missingInformation") or []
        )

    @staticmethod
    def _is_indicator_development_request(user_text: str) -> bool:
        if any(term in user_text for term in ("存储过程", "调度任务", "CREATE TABLE")):
            return False
        return any(
            term in user_text
            for term in ("开发", "指标设计", "生成 SQL", "生成SQL", "SELECT 草稿", "INSERT SELECT", "统计实体柜员数的设计")
        )

    @staticmethod
    def _is_sql_validation_request(user_text: str) -> bool:
        return any(term in user_text for term in ("校验", "检查", "是否能作为", "能否作为"))

    @classmethod
    def _candidate_ids(cls, messages: list[Any]) -> tuple[list[int], list[int]]:
        confirmed_tables: list[int] = []
        search_tables: list[int] = []
        confirmed_elements: list[int] = []
        search_elements: list[int] = []
        requested_code_tables = {
            str((call.get("args") or {}).get("table_code") or "")
            for message in messages
            if isinstance(message, AIMessage)
            for call in (message.tool_calls or [])
            if call.get("name") == "get_regulatory_code_values"
        }

        def append_id(target: list[int], value: Any) -> None:
            try:
                parsed = int(value)
            except (TypeError, ValueError):
                return
            if parsed > 0 and parsed not in target:
                target.append(parsed)

        for message in messages:
            if not isinstance(message, ToolMessage):
                continue
            payload = cls._parse_tool_payload(message)
            if payload is None:
                continue
            name = str(getattr(message, "name", "") or "")
            if name == "get_regulatory_table":
                append_id(confirmed_tables, payload.get("id"))
                for element in payload.get("elements") or []:
                    if not isinstance(element, dict):
                        continue
                    code_table = element.get("codeTable")
                    code_table_code = (
                        code_table.get("tableCode")
                        if isinstance(code_table, dict)
                        else element.get("codeTableCode")
                    )
                    if code_table_code in requested_code_tables:
                        append_id(confirmed_elements, element.get("id"))
            elif name == "get_regulatory_element":
                append_id(confirmed_elements, payload.get("id"))
                append_id(confirmed_tables, payload.get("tableId"))
            elif name == "search_regulatory_assets":
                for item in payload.get("items") or []:
                    if not isinstance(item, dict):
                        continue
                    if item.get("assetType") == "REG_TABLE":
                        append_id(search_tables, item.get("assetId"))
                    elif item.get("assetType") == "REG_ELEMENT":
                        append_id(search_elements, item.get("assetId"))
                        append_id(search_tables, item.get("parentId"))
            elif name == "scan_regulatory_catalog":
                for item in payload.get("candidates") or []:
                    if isinstance(item, dict):
                        append_id(search_tables, item.get("tableId"))
        table_ids = list(dict.fromkeys([*confirmed_tables, *search_tables]))[:3]
        element_ids = list(dict.fromkeys([*confirmed_elements, *search_elements]))[:6]
        return table_ids, element_ids

    @classmethod
    def _sql_from_user_text(cls, value: str) -> str | None:
        fenced = re.search(r"(?is)```(?:sql)?\s*(.*?)```", value)
        if fenced:
            return fenced.group(1).strip()
        match = cls.SQL_PATTERN.search(value)
        if not match:
            return None
        candidate = match.group(0).strip()
        search_from = 0
        while True:
            separator = candidate.find(";", search_from)
            if separator < 0:
                return candidate
            remainder = candidate[separator + 1 :].lstrip()
            if not remainder:
                return candidate[: separator + 1].strip()
            if re.match(
                r"(?is)^(SELECT|INSERT|DELETE|UPDATE|CREATE|ALTER|DROP)\b",
                remainder,
            ):
                search_from = separator + 1
                continue
            return candidate[: separator + 1].strip()

    @classmethod
    def _latest_validated_sql(cls, messages: list[Any]) -> str | None:
        successful_call_ids = {
            str(message.tool_call_id)
            for message in messages
            if isinstance(message, ToolMessage)
            and str(getattr(message, "name", "") or "") == "validate_generated_sql"
            and (cls._parse_tool_payload(message) or {}).get("valid") is True
        }
        for message in reversed(messages):
            if not isinstance(message, AIMessage):
                continue
            for call in reversed(message.tool_calls or []):
                if call.get("name") != "validate_generated_sql":
                    continue
                if str(call.get("id") or "") not in successful_call_ids:
                    continue
                sql = (call.get("args") or {}).get("sql")
                if isinstance(sql, str) and sql.strip():
                    return sql.strip()
        return None

    @hook_config(can_jump_to=["tools"])
    def after_model(self, state: Any, runtime: Any) -> dict[str, Any] | None:
        messages = state.get("messages", [])
        if not messages or not isinstance(messages[-1], AIMessage):
            return None
        last_message = messages[-1]
        current_turn_messages = self._current_turn_messages(messages)
        current_turn_calls = self._tool_calls(current_turn_messages)
        user_text = self._last_user_text(messages)

        out_of_scope_systems = self._out_of_scope_systems(current_turn_calls, user_text)
        if out_of_scope_systems:
            requested_scope = "、".join(out_of_scope_systems)
            allowed_scope = "、".join(self.allowed_systems)
            return {
                "messages": [
                    last_message.model_copy(
                        update={
                            "content": (
                                f"当前请求允许访问的监管系统仅为 {allowed_scope}；"
                                f"{requested_scope} 不在当前访问范围内，因此无法查询其监管资产。"
                                "这不表示相关资产不存在或未接入；如需查询，请先申请对应系统权限。"
                            ),
                            "tool_calls": [],
                        }
                    )
                ]
            }

        execution_request = any(
            term in user_text
            for term in ("执行 DELETE", "执行 UPDATE", "执行 DROP", "执行 ALTER")
        ) and not self._is_sql_validation_request(user_text)
        if execution_request:
            return {
                "messages": [
                    last_message.model_copy(
                        update={
                            "content": (
                                "监管集市助手是只读能力，不能执行 DELETE、UPDATE、DROP 或 ALTER，"
                                "也不会提供绕过只读边界的执行建议。"
                            ),
                            "tool_calls": [],
                        }
                    )
                ]
            }

        write_back_request = any(
            term in user_text for term in ("写回监管集市", "写回监管资产", "立即写回")
        )
        if write_back_request:
            return {
                "messages": [
                    last_message.model_copy(
                        update={
                            "content": "监管集市只读，不能写回或修改监管资产。",
                            "tool_calls": [],
                        }
                    )
                ]
            }

        deployment_request = any(
            term in user_text for term in ("创建目标表", "存储过程", "调度任务", "CREATE TABLE")
        ) and not self._is_sql_validation_request(user_text)
        if deployment_request:
            return {
                "messages": [
                    last_message.model_copy(
                        update={
                            "content": (
                                "第一阶段只支持 SELECT 或 INSERT SELECT 草稿；"
                                "不能创建 DDL、存储过程或调度任务，也不会执行部署。"
                            ),
                            "tool_calls": [],
                        }
                    )
                ]
            }

        missing_date_request = any(
            term in user_text
            for term in ("缺少统计日期", "统计日期缺失", "未提供统计日期")
        )
        if missing_date_request and any(
            call.get("name") == "validate_generated_sql" for call in last_message.tool_calls
        ):
            teller_evidence_confirmed = self._has_confirmed_teller_evidence(
                current_turn_messages
            )
            content = (
                "IE_001_103 已确认实体柜员标志为 SFSTGY，码表为 EAST_SFBZ，"
                "码值为“是”。指标设计中的统计日期待确认；"
                "在日期字段和统计周期确认前不生成或校验 SQL。"
                if teller_evidence_confirmed
                else (
                    "指标设计中的统计日期待确认；在日期字段和统计周期确认前，"
                    "不生成或校验 SQL，也不编造日期字段。"
                )
            )
            return {
                "messages": [
                    last_message.model_copy(
                        update={
                            "content": content,
                            "tool_calls": [],
                        }
                    )
                ]
            }

        development_context = self._latest_development_context(current_turn_messages)
        missing_information = (
            list(development_context.get("missingInformation") or [])
            if development_context
            else []
        )
        if (
            missing_information
            and self._has_blocking_context_gap(development_context)
        ):
            return {
                "messages": [
                    last_message.model_copy(
                        update={
                            "content": self._missing_context_answer(
                                development_context,
                                self._explicit_requirement_gaps(user_text),
                            ),
                            "tool_calls": [],
                        }
                    )
                ]
            }

        has_catalog_scan = any(
            call.get("name") == "scan_regulatory_catalog" for call in current_turn_calls
        )
        proposed_search = next(
            (
                call
                for call in last_message.tool_calls
                if call.get("name") == "search_regulatory_assets"
            ),
            None,
        )
        if (
            proposed_search is not None
            and not has_catalog_scan
            and not self._is_sql_validation_request(user_text)
        ):
            return {
                "messages": [
                    last_message.model_copy(
                        update={
                            "content": "",
                            "tool_calls": [self._catalog_scan_call(user_text, proposed_search)],
                        }
                    )
                ],
                "jump_to": "tools",
            }

        sensitive_request = any(
            term in user_text for term in ("内部 API", "内部API", "鉴权令牌", "连接信息")
        )
        requested_code_table = next(
            (match.group(1) for match in self.CODE_TABLE_PATTERN.finditer(user_text)),
            None,
        )
        has_code_lookup = any(
            call.get("name") == "get_regulatory_code_values"
            for call in current_turn_calls
        )
        if (
            sensitive_request
            and "码值" in user_text
            and requested_code_table
            and not has_code_lookup
            and not last_message.tool_calls
        ):
            forced_call: ToolCall = {
                "name": "get_regulatory_code_values",
                "args": {"table_code": requested_code_table, "limit": 200},
                "id": (
                    "safe-code-lookup-"
                    f"{hashlib.sha256(user_text.encode()).hexdigest()[:12]}"
                ),
                "type": "tool_call",
            }
            return {
                "messages": [
                    last_message.model_copy(
                        update={"content": "", "tool_calls": [forced_call]}
                    )
                ],
                "jump_to": "tools",
            }
        explicit_refusal = any(
            term in _message_text(last_message.content)
            for term in ("不能提供", "不会提供", "无法提供", "不能也不应", "不会输出")
        )
        if sensitive_request and not last_message.tool_calls and not explicit_refusal:
            safe_content = (
                f"{_message_text(last_message.content).rstrip()}\n\n"
                "安全说明：内部 API 地址、鉴权令牌和连接信息不能提供。"
            ).strip()
            return {
                "messages": [last_message.model_copy(update={"content": safe_content})]
            }

        relationship_context = self._latest_relationship_context(current_turn_messages)
        relationship_question = any(term in user_text for term in ("JOIN", "join", "关联", "关系"))
        confirmed_join_keys = any(
            isinstance(item, dict) and bool(item.get("joinKeys"))
            for item in (relationship_context or {}).get("relationships") or []
        )
        if (
            relationship_context
            and relationship_question
            and not confirmed_join_keys
            and not last_message.tool_calls
        ):
            safe_content = (
                "当前监管集市无法确认这些表的 JOIN 字段。"
                "关系工具没有返回已维护的 JOIN 键；物理表绑定、同名字段、主键标识或字段开发说明"
                "都不能替代正式关系证据，因此不能生成 JOIN SQL。"
                "请先由监管集市治理人员维护或确认表间关联规则。"
            )
            return {
                "messages": [last_message.model_copy(update={"content": safe_content})]
            }

        user_sql = self._sql_from_user_text(user_text)
        disallowed_validation = bool(
            user_sql
            and re.match(r"(?is)^\s*(DELETE|UPDATE|CREATE|ALTER|DROP)\b", user_sql)
        )
        if (
            disallowed_validation
            and self._is_sql_validation_request(user_text)
            and not last_message.tool_calls
            and any(call.get("name") == "validate_generated_sql" for call in current_turn_calls)
        ):
            statement_type = re.match(r"(?is)^\s*(\w+)", user_sql or "")
            keyword = statement_type.group(1).upper() if statement_type else "该语句"
            return {
                "messages": [
                    last_message.model_copy(
                        update={
                            "content": (
                                f"校验不通过：监管指标开发不允许使用 {keyword}。"
                                "第一阶段只接受 SELECT 或 INSERT SELECT 草稿，且不会执行 SQL。"
                            )
                        }
                    )
                ]
            }

        validated_sql = self._latest_validated_sql(current_turn_messages)
        if (
            validated_sql
            and not last_message.tool_calls
            and self._is_indicator_development_request(user_text)
        ):
            content = _message_text(last_message.content)
            sections: list[str] = []
            if "指标设计卡" not in content:
                sections.extend(
                    [
                        "### 指标设计卡",
                        f"- 业务需求：{user_text}",
                        "- 交付物：经静态校验的查询草稿。",
                    ]
                )
            if validated_sql.lower() not in content.lower():
                sections.extend(["### SELECT 草稿", f"```sql\n{validated_sql}\n```"])
            if sections:
                safe_content = f"{content.rstrip()}\n\n" + "\n\n".join(sections)
                return {
                    "messages": [last_message.model_copy(update={"content": safe_content})]
                }

        sql = user_sql
        if (
            sql
            and self._is_sql_validation_request(user_text)
            and not last_message.tool_calls
            and not any(call.get("name") == "validate_generated_sql" for call in current_turn_calls)
        ):
            forced_call = {
                "name": "validate_generated_sql",
                "args": {"sql": sql, "code_checks": []},
                "id": "regulatory-market-sql-validation",
                "type": "tool_call",
            }
            return {
                "messages": [last_message.model_copy(update={"content": "", "tool_calls": [forced_call]})],
                "jump_to": "tools",
            }

        if (
            not last_message.tool_calls
            and self._is_indicator_development_request(user_text)
            and not any(call.get("name") == "build_indicator_context" for call in current_turn_calls)
        ):
            table_ids, element_ids = self._candidate_ids(current_turn_messages)
            forced_call = {
                "name": "build_indicator_context",
                "args": {
                    "requirement": user_text,
                    "keywords": [],
                    "table_ids": table_ids,
                    "element_ids": element_ids,
                },
                "id": "regulatory-market-required-context",
                "type": "tool_call",
            }
            return {
                "messages": [
                    last_message.model_copy(update={"content": "", "tool_calls": [forced_call]})
                ],
                "jump_to": "tools",
            }

        if not last_message.tool_calls or not any(
            term in user_text for term in ("指标", "开发", "统计", "生成 SQL", "生成SQL")
        ):
            return None
        if any(call.get("name") == "build_indicator_context" for call in current_turn_calls):
            return None
        exploration_count = sum(
            1 for call in current_turn_calls if call.get("name") in self.EXPLORATION_TOOLS
        )
        if exploration_count <= self.EXPLORATION_LIMIT:
            return None
        if not any(
            call.get("name") in self.EXPLORATION_TOOLS for call in last_message.tool_calls
        ):
            return None

        table_ids, element_ids = self._candidate_ids(current_turn_messages)
        forced_call = {
            "name": "build_indicator_context",
            "args": {
                "requirement": user_text,
                "keywords": [],
                "table_ids": table_ids,
                "element_ids": element_ids,
            },
            "id": f"regulatory-market-context-{exploration_count}",
            "type": "tool_call",
        }
        return {
            "messages": [last_message.model_copy(update={"content": "", "tool_calls": [forced_call]})],
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
        system_prompt=f"{system_prompt}\n\n{_runtime_date_context()}".strip(),
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
    runtime_context: dict[str, Any] | None = None,
) -> Any:
    """Create a DeepAgent with centralized permission, backend, memory, and skill policy."""

    regulatory_runtime = load_agent_skill_runtime(settings, agent_code, skill_dirs, runtime_context)
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
        f"{effective_system_prompt or ''}\n\n"
        f"{_runtime_date_context()}\n\n"
        f"{PROGRESS_REPORT_INSTRUCTIONS}"
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
        effective_system_prompt = (
            f"{effective_system_prompt}\n\n"
            "## 运行时工具策略（优先于前文的固定次数说明）\n"
            "- 不使用固定 8 次工具调用作为正常停止条件；应以关键证据是否闭合决定是否继续检索。\n"
            "- 避免相同工具与相同参数的重复调用；命中目录或索引后，应转向更直接的实体页或原文页。\n"
            "- 运行时会对无进展重复、交替循环进行检测，并以 30 次业务工具调用作为异常熔断上限。\n"
            "- 若问题涉及字段、值域、校验、公式、版本或具体报送指导，不能仅因已读取目录页就停止；"
            "应继续核对实体页或原文页。\n"
            "- 对跨系统影响评估，优先读取业务场景映射和系统报表目录，"
            "只选择性核对决定结论的核心实体页；"
            "不得为了穷举所有可能性逐页遍历。系统、报表、口径、排除项和待确认项的关键证据闭合后应立即作答，"
            "证据不足的分支列为待确认。\n"
            "- 不得把单笔贷款金额、贷款余额等同于单户授信总额。若报送门槛按单户授信总额判断，"
            "而用户只提供单笔金额，必须列为条件命中或待确认，并明确还需核对该客户的单户授信总额。"
        ).strip()
        runtime_kwargs["middleware"][:0] = [
            BusinessToolCallLimitMiddleware(
                run_limit=REGULATORY_KNOWLEDGE_TOOL_CALL_HARD_LIMIT,
                exit_behavior="continue",
            ),
            BusinessToolLoopDetectionMiddleware(),
            RegulatoryRetrievalGateMiddleware(),
            RegulatoryCodeEvidenceMiddleware(),
        ]
    if agent_code == REGULATORY_MARKET_ASSISTANT_AGENT_CODE:
        allowed_systems = [
            str(item).strip()
            for item in (runtime_context or {}).get("allowed_systems") or []
            if str(item).strip()
        ]
        access_scope = "、".join(dict.fromkeys(allowed_systems))
        effective_system_prompt = (
            f"{effective_system_prompt}\n\n"
            "## 监管集市运行时工具策略（优先于前文）\n"
            f"- 当前请求允许访问的监管系统仅为：{access_scope}。"
            "用户请求清单外系统时，必须明确说明受当前访问范围限制；"
            "不得把权限过滤后的空结果表述为资产不存在、未接入或表名错误。\n"
            "- 只能调用当前 Skill 的监管集市工具和进度工具；不得尝试文件、Shell 或其他平台工具。\n"
            "- 首次资产探索先扫描表层目录并形成证据计划；目录返回后再按候选和证据缺口下钻。\n"
            "- 禁止以相同参数重复调用工具；不得用同义词遍历代替目录扫描。\n"
            "- 发现物理绑定、字段、码值、统计日期、粒度或 JOIN 证据缺失时，"
            "应立即把缺口列为待确认项并停止生成或校验 SQL。\n"
            "- 单轮最多 14 次业务工具调用；达到上限前必须基于已有证据作答。"
        ).strip()
        runtime_kwargs["middleware"][:0] = [
            RegulatoryMarketWorkflowMiddleware(allowed_systems=allowed_systems),
            BusinessToolCallLimitMiddleware(
                run_limit=REGULATORY_MARKET_ASSISTANT_TOOL_CALL_HARD_LIMIT,
                exit_behavior="continue",
            ),
            BusinessToolLoopDetectionMiddleware(),
        ]
    return create_deep_agent(
        model=model,
        tools=runtime_tools,
        system_prompt=effective_system_prompt,
        **runtime_kwargs,
    )
