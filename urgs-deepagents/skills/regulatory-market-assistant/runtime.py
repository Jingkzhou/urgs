"""Packaged runtime for regulatory-market consultation and indicator SQL development."""

from __future__ import annotations

import json
import os
from collections.abc import Callable, Mapping
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import quote

import httpx
from langchain_core.tools import StructuredTool
from pydantic import BaseModel, Field

from urgs_deepagents_service.skill_loader import SkillConfigurationError, SkillRuntime

SKILL_CODE = "regulatory-market-assistant"
AGENT_CODE = "regulatory-market-assistant-agent"
REQUIRED_PERMISSION = "ai:regulatory-query:use"
TABLE_CODE_PATTERN = r"^[A-Za-z0-9][A-Za-z0-9_.-]{0,127}$"
TOOL_NAMES = frozenset(
    {
        "search_regulatory_assets",
        "get_regulatory_table",
        "get_regulatory_element",
        "get_regulatory_code_values",
        "get_regulatory_relationships",
        "build_indicator_context",
        "validate_generated_sql",
    }
)


class SearchAssetsInput(BaseModel):
    keyword: str = Field(
        description="单个表编码、字段编码或业务短语；不要把监管系统编码拼进关键词"
    )
    system_code: str | None = Field(default=None, description="可选监管系统编码")
    limit: int = Field(default=20, ge=1, le=50, description="最多返回的候选资产数")


class GetTableInput(BaseModel):
    table_id: int = Field(description="监管表资产 ID")
    element_limit: int = Field(default=20, ge=1, le=20, description="最多返回的字段和指标数")


class GetElementInput(BaseModel):
    element_id: int = Field(description="监管字段或监管指标资产 ID")


class GetCodeValuesInput(BaseModel):
    table_code: str = Field(pattern=TABLE_CODE_PATTERN, description="码表编码")
    limit: int = Field(default=200, ge=1, le=500, description="最多返回的码值数")


class GetRelationshipsInput(BaseModel):
    table_ids: list[int] = Field(min_length=1, max_length=10, description="需要检查关系的监管表 ID")


class BuildIndicatorContextInput(BaseModel):
    requirement: str = Field(description="用户的完整指标开发需求")
    keywords: list[str] = Field(
        default_factory=list,
        max_length=8,
        description="从需求中提取的业务短语，例如不良贷款、五级分类、贷款余额",
    )
    table_ids: list[int] = Field(default_factory=list, description="已确认的监管表 ID")
    element_ids: list[int] = Field(default_factory=list, description="已确认的监管字段或指标 ID")


class CodeValueCheckInput(BaseModel):
    table_code: str = Field(pattern=TABLE_CODE_PATTERN, description="码表编码")
    code: str = Field(description="SQL 中使用的码值")


class ValidateGeneratedSqlInput(BaseModel):
    sql: str = Field(description="需要静态校验的 SELECT 或 INSERT SELECT SQL")
    code_checks: list[CodeValueCheckInput] = Field(
        default_factory=list,
        max_length=50,
        description="SQL 使用的码表和码值清单",
    )


@dataclass(frozen=True)
class AccessContext:
    requester_user_id: int
    permissions: frozenset[str]
    allowed_systems: tuple[str, ...]

    @property
    def allowed_systems_param(self) -> str:
        return ",".join(self.allowed_systems)


class RegulatoryMarketApiClient:
    def __init__(
        self,
        base_url: str,
        token: str,
        auth_header: str,
        auth_prefix: str,
        access_context: AccessContext,
        timeout_seconds: float = 20.0,
    ) -> None:
        normalized_url = base_url.strip().rstrip("/")
        if not normalized_url.startswith(("http://", "https://")):
            raise SkillConfigurationError("监管集市 API 地址必须使用 http:// 或 https://")
        if not token.strip():
            raise SkillConfigurationError("缺少监管集市内部 API 鉴权令牌")
        self.base_url = normalized_url
        self.headers = {auth_header: auth_prefix + token}
        self.access_context = access_context
        self.timeout_seconds = timeout_seconds

    def search_assets(self, **kwargs: Any) -> dict[str, Any]:
        system_code = kwargs.pop("system_code", None)
        return self._request(
            "GET",
            "/api/internal/regulatory-market/search",
            params={
                "keyword": kwargs.get("keyword", ""),
                "systemCode": system_code,
                "limit": kwargs.get("limit", 20),
                "allowedSystems": self.access_context.allowed_systems_param,
            },
        )

    def get_table(self, **kwargs: Any) -> dict[str, Any]:
        table_id = kwargs.pop("table_id")
        return self._request(
            "GET",
            f"/api/internal/regulatory-market/tables/{table_id}",
            params={
                "elementLimit": kwargs.get("element_limit", 20),
                "allowedSystems": self.access_context.allowed_systems_param,
            },
        )

    def get_element(self, **kwargs: Any) -> dict[str, Any]:
        element_id = kwargs.pop("element_id")
        return self._request(
            "GET",
            f"/api/internal/regulatory-market/elements/{element_id}",
            params={"allowedSystems": self.access_context.allowed_systems_param},
        )

    def get_code_values(self, **kwargs: Any) -> dict[str, Any]:
        table_code = kwargs.pop("table_code")
        return self._request(
            "GET",
            f"/api/internal/regulatory-market/code-tables/{quote(table_code, safe='')}/values",
            params={**kwargs, "allowedSystems": self.access_context.allowed_systems_param},
        )

    def get_relationships(self, **kwargs: Any) -> dict[str, Any]:
        return self._request(
            "POST",
            "/api/internal/regulatory-market/relationships",
            json_body={
                "tableIds": kwargs.get("table_ids", []),
                "allowedSystems": self.access_context.allowed_systems_param,
            },
        )

    def build_indicator_context(self, **kwargs: Any) -> dict[str, Any]:
        return self._request(
            "POST",
            "/api/internal/regulatory-market/development-context",
            json_body={
                "requirement": kwargs.get("requirement", ""),
                "keywords": kwargs.get("keywords", []),
                "tableIds": kwargs.get("table_ids", []),
                "elementIds": kwargs.get("element_ids", []),
                "allowedSystems": self.access_context.allowed_systems_param,
            },
        )

    def validate_sql(self, **kwargs: Any) -> dict[str, Any]:
        checks = []
        for item in kwargs.pop("code_checks", []):
            raw = item.model_dump() if isinstance(item, CodeValueCheckInput) else dict(item)
            checks.append(
                {
                    "tableCode": raw.get("table_code") or raw.get("tableCode"),
                    "code": raw.get("code"),
                }
            )
        return self._request(
            "POST",
            "/api/internal/regulatory-market/validate-sql",
            json_body={
                **kwargs,
                "codeChecks": checks,
                "allowedSystems": self.access_context.allowed_systems_param,
            },
        )

    def _request(
        self,
        method: str,
        path: str,
        *,
        params: Mapping[str, Any] | None = None,
        json_body: Mapping[str, Any] | None = None,
    ) -> dict[str, Any]:
        response = httpx.request(
            method,
            self.base_url + path,
            headers=self.headers,
            params=params,
            json=json_body,
            timeout=self.timeout_seconds,
        )
        response.raise_for_status()
        payload = response.json()
        if not isinstance(payload, dict):
            raise ValueError("监管集市 API 返回了无效响应")
        return payload


def _parse_access_context(value: Mapping[str, Any] | None) -> AccessContext:
    context = dict(value or {})
    requester = context.get("requester_user_id")
    permissions = frozenset(str(item) for item in context.get("permissions") or [])
    allowed_systems = tuple(
        dict.fromkeys(
            str(item).strip()
            for item in context.get("allowed_systems") or []
            if str(item).strip()
        )
    )
    if not isinstance(requester, int) or requester <= 0:
        raise SkillConfigurationError("监管集市助手缺少当前用户上下文")
    if REQUIRED_PERMISSION not in permissions:
        raise SkillConfigurationError("当前用户缺少监管指标查询权限")
    if not allowed_systems:
        raise SkillConfigurationError("当前用户没有可访问的监管系统")
    return AccessContext(requester, permissions, allowed_systems)


def _load_manifest(skill_dir: Path) -> tuple[dict[str, Any], str]:
    try:
        manifest = json.loads((skill_dir / "skill.json").read_text(encoding="utf-8"))
        instructions = (skill_dir / "SKILL.md").read_text(encoding="utf-8")
    except (OSError, json.JSONDecodeError) as exc:
        raise SkillConfigurationError("监管集市 Skill 文件无法读取") from exc
    if manifest.get("skill_code") != SKILL_CODE or manifest.get("agent_code") != AGENT_CODE:
        raise SkillConfigurationError("监管集市 Skill 清单与 Agent 不匹配")
    if frozenset(manifest.get("tools") or []) != TOOL_NAMES:
        raise SkillConfigurationError("监管集市 Skill 工具清单不完整")
    return manifest, instructions


def _safe_call(operation: Callable[..., dict[str, Any]], **kwargs: Any) -> dict[str, Any]:
    try:
        return {"ok": True, **_without_historical_code(operation(**kwargs))}
    except httpx.HTTPStatusError as exc:
        return {"ok": False, "error": f"监管集市 API 返回 HTTP {exc.response.status_code}"}
    except httpx.HTTPError:
        return {"ok": False, "error": "监管集市 API 暂时不可用"}
    except (TypeError, ValueError) as exc:
        return {"ok": False, "error": str(exc)[:240]}


def _without_historical_code(value: Any) -> Any:
    if isinstance(value, dict):
        return {
            key: _without_historical_code(item)
            for key, item in value.items()
            if key != "codeSnippet"
        }
    if isinstance(value, list):
        return [_without_historical_code(item) for item in value]
    return value


def create_skill_runtime(
    skill_dir: Path, access_context: Mapping[str, Any] | None = None
) -> SkillRuntime:
    manifest, instructions = _load_manifest(skill_dir)
    access = _parse_access_context(access_context)
    api_config = manifest.get("api") or {}
    base_url = os.getenv(str(api_config.get("url_env") or "DEEPAGENTS_URGS_API_URL"), "").strip()
    token_env = str(api_config.get("token_env") or "DEEPAGENTS_INTERNAL_API_TOKEN")
    token = os.getenv(token_env, "").strip()
    client = RegulatoryMarketApiClient(
        base_url=base_url,
        token=token,
        auth_header=os.getenv("DEEPAGENTS_INTERNAL_API_AUTH_HEADER", "Authorization"),
        auth_prefix=os.getenv("DEEPAGENTS_INTERNAL_API_AUTH_PREFIX", "Bearer "),
        access_context=access,
    )
    tools = (
        StructuredTool.from_function(
            lambda **kwargs: _safe_call(client.search_assets, **kwargs),
            name="search_regulatory_assets",
            description=(
                "按单个业务关键词检索当前用户有权访问的监管表、字段、指标和码表候选。"
                "精确编码应原样放入 keyword，监管系统必须单独放入 system_code。"
            ),
            args_schema=SearchAssetsInput,
        ),
        StructuredTool.from_function(
            lambda **kwargs: _safe_call(client.get_table, **kwargs),
            name="get_regulatory_table",
            description="读取监管表的业务口径、物理表绑定及字段和指标目录。",
            args_schema=GetTableInput,
        ),
        StructuredTool.from_function(
            lambda **kwargs: _safe_call(client.get_element, **kwargs),
            name="get_regulatory_element",
            description="读取单个监管字段或指标的口径、公式、物理字段绑定和关联码值。",
            args_schema=GetElementInput,
        ),
        StructuredTool.from_function(
            lambda **kwargs: _safe_call(client.get_code_values, **kwargs),
            name="get_regulatory_code_values",
            description="按码表编码读取当前有效的正式码值和说明。",
            args_schema=GetCodeValuesInput,
        ),
        StructuredTool.from_function(
            lambda **kwargs: _safe_call(client.get_relationships, **kwargs),
            name="get_regulatory_relationships",
            description="检查多个监管表之间已确认的物理绑定关系；不会猜测未维护的 JOIN 键。",
            args_schema=GetRelationshipsInput,
        ),
        StructuredTool.from_function(
            lambda **kwargs: _safe_call(client.build_indicator_context, **kwargs),
            name="build_indicator_context",
            description="根据指标需求、关键词和已确认资产组装代码开发上下文并列出缺失信息。",
            args_schema=BuildIndicatorContextInput,
        ),
        StructuredTool.from_function(
            lambda **kwargs: _safe_call(client.validate_sql, **kwargs),
            name="validate_generated_sql",
            description=(
                "静态校验 SELECT 或 INSERT SELECT 的语法、表、限定字段和正式码值，"
                "不执行 SQL。"
            ),
            args_schema=ValidateGeneratedSqlInput,
        ),
    )
    return SkillRuntime(instructions=instructions, tools=tools, tool_names=TOOL_NAMES)
