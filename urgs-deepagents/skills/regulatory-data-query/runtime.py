"""Declarative Skill runtime for direct regulatory data queries."""

from __future__ import annotations

import json
import os
import re
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from typing import Any, Literal, cast

from langchain_core.tools import StructuredTool
from pydantic import BaseModel, Field
from sqlalchemy import create_engine, text

from urgs_deepagents_service.skill_loader import SkillConfigurationError, SkillRuntime

REGULATORY_DATA_QUERY_AGENT_CODE = "regulatory-data-query-agent"
REGULATORY_DATA_QUERY_SKILL_CODE = "regulatory-data-query"
REGULATORY_QUERY_TOOL_NAMES = frozenset(
    {
        "browse_regulatory_catalog",
        "search_regulatory_metrics",
        "search_regulatory_fields",
        "query_regulatory_summary",
        "query_regulatory_detail",
    }
)

_CODE_PATTERN = re.compile(r"^[a-z][a-z0-9_-]*$")
_IDENTIFIER_PATTERN = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)?$")
_ENV_NAME_PATTERN = re.compile(r"^[A-Z][A-Z0-9_]*$")
_MASK_RULES = frozenset({"FULL", "NAME", "MOBILE", "ID_CARD", "ACCOUNT"})
_FILTER_OPERATORS = frozenset({"eq", "in", "like"})
_FIELD_TYPES = frozenset({"string", "number", "boolean", "date"})
EngineFactory = Callable[..., Any]


@dataclass(frozen=True)
class OrderRule:
    field_code: str
    direction: Literal["asc", "desc"]


@dataclass(frozen=True)
class FieldConfig:
    code: str
    name: str
    column: str
    value_type: Literal["string", "number", "boolean", "date"]
    returnable: bool
    filterable: bool
    sortable: bool
    operators: frozenset[str]
    mask: str | None


@dataclass(frozen=True)
class MetricConfig:
    code: str
    name: str
    column: str
    value_type: Literal["string", "number", "boolean", "date"]


@dataclass(frozen=True)
class SummaryTableConfig:
    code: str
    name: str
    table: str
    date_column: str
    organization_column: str
    indicators: Mapping[str, MetricConfig]
    filters: Mapping[str, FieldConfig]
    max_rows: int
    order_by: tuple[OrderRule, ...]


@dataclass(frozen=True)
class DetailTableConfig:
    code: str
    name: str
    table: str
    date_column: str
    organization_column: str
    fields: Mapping[str, FieldConfig]
    default_return_fields: tuple[str, ...]
    max_rows: int
    order_by: tuple[OrderRule, ...]


@dataclass(frozen=True)
class SystemConfig:
    code: str
    name: str
    summary_tables: Mapping[str, SummaryTableConfig]
    detail_tables: Mapping[str, DetailTableConfig]


@dataclass(frozen=True)
class RegulatoryQuerySkill:
    skill_code: str
    skill_dir: Path
    instructions: str
    database_url_env: str
    catalog_limit: int
    systems: Mapping[str, SystemConfig]


class QueryFilterInput(BaseModel):
    field: str = Field(min_length=1, max_length=64, description="目录中的字段编码")
    operator: str = Field(min_length=1, max_length=16, description="eq、in 或 like")
    value: Any = Field(description="筛选值")


class BrowseCatalogInput(BaseModel):
    system_code: str | None = Field(default=None, description="系统编码；为空时返回可用系统")
    view: Literal["summary", "detail"] | None = Field(default=None, description="汇总或明细")
    keyword: str | None = Field(default=None, max_length=128, description="系统或表名称关键字")


class SearchCatalogInput(BaseModel):
    system_code: str = Field(min_length=1, max_length=64, description="系统编码")
    table_code: str = Field(min_length=1, max_length=64, description="目录表编码")
    keyword: str = Field(min_length=1, max_length=128, description="指标或字段名称关键字")


class QuerySummaryInput(BaseModel):
    system_code: str = Field(min_length=1, max_length=64, description="系统编码")
    table_code: str = Field(min_length=1, max_length=64, description="汇总表编码")
    indicator_codes: list[str] = Field(min_length=1, max_length=20, description="已确认的指标编码")
    start_date: str = Field(description="统计开始日期，格式 YYYY-MM-DD")
    end_date: str = Field(description="统计结束日期，格式 YYYY-MM-DD")
    organization: str = Field(min_length=1, max_length=128, description="机构或主体范围")
    filters: list[QueryFilterInput] = Field(default_factory=list, description="目录允许的筛选条件")


class QueryDetailInput(BaseModel):
    system_code: str = Field(min_length=1, max_length=64, description="系统编码")
    table_code: str = Field(min_length=1, max_length=64, description="明细表编码")
    return_fields: list[str] = Field(
        default_factory=list, max_length=30, description="需要返回的明细字段编码；为空使用默认字段"
    )
    start_date: str = Field(description="统计开始日期，格式 YYYY-MM-DD")
    end_date: str = Field(description="统计结束日期，格式 YYYY-MM-DD")
    organization: str = Field(min_length=1, max_length=128, description="机构或主体范围")
    filters: list[QueryFilterInput] = Field(default_factory=list, description="目录允许的筛选条件")
    sort_field: str | None = Field(default=None, description="目录中允许排序的字段编码")
    sort_direction: Literal["asc", "desc"] | None = Field(default=None, description="排序方向")


def _require_code(value: Any, field_name: str) -> str:
    candidate = str(value or "").strip()
    if not _CODE_PATTERN.fullmatch(candidate):
        raise SkillConfigurationError(f"{field_name} 必须是小写业务编码")
    return candidate


def _require_identifier(value: Any, field_name: str) -> str:
    candidate = str(value or "").strip()
    if not _IDENTIFIER_PATTERN.fullmatch(candidate):
        raise SkillConfigurationError(f"{field_name} 必须是安全的表或字段标识符")
    return candidate


def _require_name(value: Any, field_name: str) -> str:
    candidate = str(value or "").strip()
    if not candidate:
        raise SkillConfigurationError(f"{field_name} 不能为空")
    return candidate


def _parse_field(value: Any, field_name: str) -> FieldConfig:
    if not isinstance(value, dict):
        raise SkillConfigurationError(f"{field_name} 必须是对象")
    value_type = str(value.get("type") or "").lower()
    if value_type not in _FIELD_TYPES:
        raise SkillConfigurationError(f"{field_name}.type 不受支持")
    raw_operators = value.get("operators") or (
        ["eq", "in", "like"] if value_type == "string" else ["eq", "in"]
    )
    if not isinstance(raw_operators, list):
        raise SkillConfigurationError(f"{field_name}.operators 必须是数组")
    operators = frozenset(str(item).lower() for item in raw_operators)
    if not operators <= _FILTER_OPERATORS:
        raise SkillConfigurationError(f"{field_name}.operators 包含不支持的操作符")
    mask = value.get("mask")
    if mask is not None:
        mask = str(mask).upper()
        if mask not in _MASK_RULES:
            raise SkillConfigurationError(f"{field_name}.mask 包含未知脱敏规则")
    return FieldConfig(
        code=_require_code(value.get("code"), f"{field_name}.code"),
        name=_require_name(value.get("name"), f"{field_name}.name"),
        column=_require_identifier(value.get("column"), f"{field_name}.column"),
        value_type=cast(Literal["string", "number", "boolean", "date"], value_type),
        returnable=value.get("returnable") is True,
        filterable=value.get("filterable") is True,
        sortable=value.get("sortable") is True,
        operators=operators,
        mask=mask,
    )


def _parse_metric(value: Any, field_name: str) -> MetricConfig:
    if not isinstance(value, dict):
        raise SkillConfigurationError(f"{field_name} 必须是对象")
    value_type = str(value.get("type") or "").lower()
    if value_type not in _FIELD_TYPES:
        raise SkillConfigurationError(f"{field_name}.type 不受支持")
    return MetricConfig(
        code=_require_code(value.get("code"), f"{field_name}.code"),
        name=_require_name(value.get("name"), f"{field_name}.name"),
        column=_require_identifier(value.get("column"), f"{field_name}.column"),
        value_type=cast(Literal["string", "number", "boolean", "date"], value_type),
    )


def _index_by_code(
    items: Any, field_name: str, parser: Callable[[Any, str], Any]
) -> Mapping[str, Any]:
    if not isinstance(items, list) or not items:
        raise SkillConfigurationError(f"{field_name} 必须至少配置一项")
    indexed: dict[str, Any] = {}
    for index, item in enumerate(items):
        parsed = parser(item, f"{field_name}[{index}]")
        if parsed.code in indexed:
            raise SkillConfigurationError(f"{field_name} 存在重复编码: {parsed.code}")
        indexed[parsed.code] = parsed
    return indexed


def _parse_order_rules(
    value: Any, field_name: str, fields: Mapping[str, FieldConfig]
) -> tuple[OrderRule, ...]:
    if value is None:
        return ()
    if not isinstance(value, list):
        raise SkillConfigurationError(f"{field_name} 必须是数组")
    rules: list[OrderRule] = []
    for index, item in enumerate(value):
        if not isinstance(item, dict):
            raise SkillConfigurationError(f"{field_name}[{index}] 必须是对象")
        field_code = _require_code(item.get("field"), f"{field_name}[{index}].field")
        if field_code not in fields or not fields[field_code].sortable:
            raise SkillConfigurationError(f"{field_name} 只能使用允许排序的字段")
        direction = str(item.get("direction") or "").lower()
        if direction not in {"asc", "desc"}:
            raise SkillConfigurationError(f"{field_name}.direction 只支持 asc 或 desc")
        rules.append(OrderRule(field_code, cast(Literal["asc", "desc"], direction)))
    return tuple(rules)


def _parse_summary_table(value: Any, field_name: str) -> SummaryTableConfig:
    if not isinstance(value, dict):
        raise SkillConfigurationError(f"{field_name} 必须是对象")
    filters = _index_by_code(value.get("filters", []), f"{field_name}.filters", _parse_field)
    if any(not field.filterable for field in filters.values()):
        raise SkillConfigurationError(f"{field_name}.filters 中字段必须允许筛选")
    max_rows = value.get("max_rows", 100)
    if not isinstance(max_rows, int) or not 1 <= max_rows <= 1000:
        raise SkillConfigurationError(f"{field_name}.max_rows 必须在 1 到 1000 之间")
    return SummaryTableConfig(
        code=_require_code(value.get("code"), f"{field_name}.code"),
        name=_require_name(value.get("name"), f"{field_name}.name"),
        table=_require_identifier(value.get("table"), f"{field_name}.table"),
        date_column=_require_identifier(value.get("date_column"), f"{field_name}.date_column"),
        organization_column=_require_identifier(
            value.get("organization_column"), f"{field_name}.organization_column"
        ),
        indicators=_index_by_code(
            value.get("indicators"), f"{field_name}.indicators", _parse_metric
        ),
        filters=filters,
        max_rows=max_rows,
        order_by=_parse_order_rules(value.get("order_by"), f"{field_name}.order_by", filters),
    )


def _parse_detail_table(value: Any, field_name: str) -> DetailTableConfig:
    if not isinstance(value, dict):
        raise SkillConfigurationError(f"{field_name} 必须是对象")
    fields = _index_by_code(value.get("fields"), f"{field_name}.fields", _parse_field)
    default_fields = value.get("default_return_fields")
    if not isinstance(default_fields, list) or not default_fields:
        raise SkillConfigurationError(f"{field_name}.default_return_fields 必须至少配置一个字段")
    normalized_defaults = tuple(
        _require_code(item, f"{field_name}.default_return_fields") for item in default_fields
    )
    if len(set(normalized_defaults)) != len(normalized_defaults) or any(
        code not in fields or not fields[code].returnable for code in normalized_defaults
    ):
        raise SkillConfigurationError(f"{field_name}.default_return_fields 必须是可返回字段")
    max_rows = value.get("max_rows")
    if not isinstance(max_rows, int) or not 1 <= max_rows <= 5:
        raise SkillConfigurationError(f"{field_name}.max_rows 必须在 1 到 5 之间")
    return DetailTableConfig(
        code=_require_code(value.get("code"), f"{field_name}.code"),
        name=_require_name(value.get("name"), f"{field_name}.name"),
        table=_require_identifier(value.get("table"), f"{field_name}.table"),
        date_column=_require_identifier(value.get("date_column"), f"{field_name}.date_column"),
        organization_column=_require_identifier(
            value.get("organization_column"), f"{field_name}.organization_column"
        ),
        fields=fields,
        default_return_fields=normalized_defaults,
        max_rows=max_rows,
        order_by=_parse_order_rules(value.get("order_by"), f"{field_name}.order_by", fields),
    )


def _parse_system(value: Any, field_name: str) -> SystemConfig:
    if not isinstance(value, dict):
        raise SkillConfigurationError(f"{field_name} 必须是对象")
    return SystemConfig(
        code=_require_code(value.get("code"), f"{field_name}.code"),
        name=_require_name(value.get("name"), f"{field_name}.name"),
        summary_tables=_index_by_code(
            value.get("summary_tables"), f"{field_name}.summary_tables", _parse_summary_table
        ),
        detail_tables=_index_by_code(
            value.get("detail_tables"), f"{field_name}.detail_tables", _parse_detail_table
        ),
    )


def load_regulatory_query_skill(skill_dir: Path) -> RegulatoryQuerySkill:
    """Load and validate the Skill manifest and approved data catalog."""

    skill_file = skill_dir / "SKILL.md"
    manifest_file = skill_dir / "skill.json"
    catalog_file = skill_dir / "catalog.json"
    if not skill_file.is_file() or not manifest_file.is_file() or not catalog_file.is_file():
        raise SkillConfigurationError("监管查询 Skill 缺少 SKILL.md、skill.json 或 catalog.json")
    try:
        manifest = json.loads(manifest_file.read_text(encoding="utf-8"))
        catalog = json.loads(catalog_file.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SkillConfigurationError("监管查询 Skill 配置文件无法解析") from exc
    if not isinstance(manifest, dict) or not isinstance(catalog, dict):
        raise SkillConfigurationError("监管查询 Skill 配置必须是对象")
    if (
        manifest.get("skill_code") != REGULATORY_DATA_QUERY_SKILL_CODE
        or catalog.get("skill_code") != REGULATORY_DATA_QUERY_SKILL_CODE
    ):
        raise SkillConfigurationError("监管查询 Skill 编码不匹配")
    if manifest.get("version") != 2 or catalog.get("version") != 1:
        raise SkillConfigurationError("监管查询 Skill 配置版本不受支持")
    if manifest.get("enabled") is not True:
        raise SkillConfigurationError("监管查询 Skill 尚未启用或映射未完成")
    if set(manifest.get("tools") or []) != REGULATORY_QUERY_TOOL_NAMES:
        raise SkillConfigurationError("监管查询 Skill 只能声明固定的受控查询工具")
    database = manifest.get("database")
    if not isinstance(database, dict) or database.get("dialect") != "mysql":
        raise SkillConfigurationError("监管查询 Skill 仅支持 MySQL 数据源")
    database_url_env = str(database.get("url_env") or "")
    if not _ENV_NAME_PATTERN.fullmatch(database_url_env):
        raise SkillConfigurationError("database.url_env 必须是环境变量名称")
    catalog_limit = manifest.get("catalog_limit", 50)
    if not isinstance(catalog_limit, int) or not 1 <= catalog_limit <= 100:
        raise SkillConfigurationError("catalog_limit 必须在 1 到 100 之间")
    instructions = skill_file.read_text(encoding="utf-8").strip()
    if not instructions:
        raise SkillConfigurationError("监管查询 Skill 的 SKILL.md 不能为空")
    return RegulatoryQuerySkill(
        skill_code=REGULATORY_DATA_QUERY_SKILL_CODE,
        skill_dir=skill_dir,
        instructions=instructions,
        database_url_env=database_url_env,
        catalog_limit=catalog_limit,
        systems=_index_by_code(catalog.get("systems"), "catalog.systems", _parse_system),
    )


def _quote_identifier(value: str) -> str:
    return ".".join(f"`{part}`" for part in value.split("."))


def _json_safe(value: Any) -> Any:
    if value is None or isinstance(value, (str, int, float, bool)):
        return value
    if isinstance(value, Decimal):
        return str(value)
    if isinstance(value, (datetime, date)):
        return value.isoformat()
    return str(value)


def _mask_value(value: Any, rule: str) -> Any:
    if value is None:
        return None
    text_value = str(value)
    if rule == "FULL":
        return "***"
    if rule == "NAME":
        return text_value[:1] + "*" * max(len(text_value) - 1, 1)
    if rule == "MOBILE":
        return "***" if len(text_value) <= 7 else text_value[:3] + "****" + text_value[-4:]
    if rule == "ID_CARD":
        return "***" if len(text_value) <= 10 else text_value[:6] + "********" + text_value[-4:]
    if rule == "ACCOUNT":
        return "***" if len(text_value) <= 4 else "*" * (len(text_value) - 4) + text_value[-4:]
    raise SkillConfigurationError("未知脱敏规则")


class RegulatoryDataQueryService:
    """Build parameterized MySQL reads from approved logical catalog items only."""

    def __init__(
        self,
        skill: RegulatoryQuerySkill,
        database_url: str,
        engine_factory: EngineFactory = create_engine,
    ) -> None:
        if not database_url.startswith(("mysql://", "mysql+")):
            raise SkillConfigurationError("监管查询数据库连接必须使用 MySQL URL")
        self.skill = skill
        self.engine = engine_factory(database_url, pool_pre_ping=True)

    def browse_catalog(
        self, system_code: str | None, view: str | None, keyword: str | None
    ) -> dict[str, Any]:
        needle = (keyword or "").strip().lower()
        if system_code:
            system = self._system(system_code)
            systems = [system]
        else:
            systems = list(self.skill.systems.values())
        entries: list[dict[str, Any]] = []
        for system in systems:
            selected: list[tuple[str, SummaryTableConfig | DetailTableConfig]] = []
            if view in (None, "summary"):
                selected.extend(("summary", table) for table in system.summary_tables.values())
            if view in (None, "detail"):
                selected.extend(("detail", table) for table in system.detail_tables.values())
            tables = [
                {"code": table.code, "name": table.name, "view": table_view}
                for table_view, table in selected
                if not needle
                or needle in system.name.lower()
                or needle in table.code.lower()
                or needle in table.name.lower()
            ]
            if tables:
                entries.append(
                    {"system_code": system.code, "system_name": system.name, "tables": tables}
                )
        return {"system_count": len(entries), "systems": entries[: self.skill.catalog_limit]}

    def search_metrics(self, system_code: str, table_code: str, keyword: str) -> dict[str, Any]:
        table = self._summary_table(system_code, table_code)
        needle = keyword.strip().lower()
        if not needle:
            raise ValueError("指标关键字不能为空")
        metrics = [
            {"code": item.code, "name": item.name, "type": item.value_type}
            for item in table.indicators.values()
            if needle in item.code.lower() or needle in item.name.lower()
        ]
        return {
            "system_code": system_code,
            "table_code": table_code,
            "candidate_count": len(metrics),
            "candidates": metrics[: self.skill.catalog_limit],
        }

    def search_fields(self, system_code: str, table_code: str, keyword: str) -> dict[str, Any]:
        table = self._detail_table(system_code, table_code)
        needle = keyword.strip().lower()
        if not needle:
            raise ValueError("字段关键字不能为空")
        fields = [
            {
                "code": item.code,
                "name": item.name,
                "type": item.value_type,
                "returnable": item.returnable,
                "filterable": item.filterable,
                "sortable": item.sortable,
            }
            for item in table.fields.values()
            if needle in item.code.lower() or needle in item.name.lower()
        ]
        return {
            "system_code": system_code,
            "table_code": table_code,
            "field_count": len(fields),
            "fields": fields[: self.skill.catalog_limit],
        }

    def query_summary(
        self,
        *,
        system_code: str,
        table_code: str,
        indicator_codes: Sequence[str],
        start_date: str,
        end_date: str,
        organization: str,
        filters: Sequence[Mapping[str, Any]],
    ) -> dict[str, Any]:
        table = self._summary_table(system_code, table_code)
        indicators = self._select_items(table.indicators, indicator_codes, "指标")
        start, end, normalized_organization = self._required_scope(
            start_date, end_date, organization
        )
        where_sql, parameters, filter_summary = self._where_clause(
            table.date_column,
            table.organization_column,
            table.filters,
            start,
            end,
            normalized_organization,
            filters,
        )
        selected = [table.date_column, table.organization_column] + [
            indicator.column for indicator in indicators
        ]
        columns_sql = ", ".join(_quote_identifier(column) for column in selected)
        order_sql = self._order_clause(table.order_by, table.filters)
        rows = self._rows(
            text(
                f"SELECT {columns_sql} FROM {_quote_identifier(table.table)} "
                f"{where_sql}{order_sql} LIMIT :limit"
            ),
            {**parameters, "limit": table.max_rows},
        )
        return {
            "view": "summary",
            "system_code": system_code,
            "table_code": table_code,
            "indicators": [{"code": item.code, "name": item.name} for item in indicators],
            "start_date": start.isoformat(),
            "end_date": end.isoformat(),
            "organization": normalized_organization,
            "filters": filter_summary,
            "returned_count": len(rows),
            "rows": [self._json_row(row) for row in rows],
        }

    def query_detail(
        self,
        *,
        system_code: str,
        table_code: str,
        return_fields: Sequence[str],
        start_date: str,
        end_date: str,
        organization: str,
        filters: Sequence[Mapping[str, Any]],
        sort_field: str | None,
        sort_direction: str | None,
    ) -> dict[str, Any]:
        table = self._detail_table(system_code, table_code)
        fields = self._select_items(
            table.fields, return_fields or table.default_return_fields, "明细返回字段"
        )
        if any(not field.returnable for field in fields):
            raise ValueError("请求包含不可返回的明细字段")
        start, end, normalized_organization = self._required_scope(
            start_date, end_date, organization
        )
        filterable = {code: field for code, field in table.fields.items() if field.filterable}
        where_sql, parameters, filter_summary = self._where_clause(
            table.date_column,
            table.organization_column,
            filterable,
            start,
            end,
            normalized_organization,
            filters,
        )
        order_by = table.order_by
        if sort_field:
            field = table.fields.get(sort_field)
            if field is None or not field.sortable:
                raise ValueError("请求的明细排序字段未在目录中允许")
            direction = (sort_direction or "asc").lower()
            if direction not in {"asc", "desc"}:
                raise ValueError("明细排序方向只支持 asc 或 desc")
            order_by = (OrderRule(sort_field, cast(Literal["asc", "desc"], direction)),)
        count = self._count(
            text(
                f"SELECT COUNT(*) AS total_count FROM {_quote_identifier(table.table)} {where_sql}"
            ),
            parameters,
        )
        columns_sql = ", ".join(_quote_identifier(field.column) for field in fields)
        order_sql = self._order_clause(order_by, table.fields)
        rows = self._rows(
            text(
                f"SELECT {columns_sql} FROM {_quote_identifier(table.table)} "
                f"{where_sql}{order_sql} LIMIT :limit"
            ),
            {**parameters, "limit": min(table.max_rows, 5)},
        )
        return {
            "view": "detail",
            "system_code": system_code,
            "table_code": table_code,
            "return_fields": [{"code": field.code, "name": field.name} for field in fields],
            "start_date": start.isoformat(),
            "end_date": end.isoformat(),
            "organization": normalized_organization,
            "filters": filter_summary,
            "total_count": count,
            "returned_count": len(rows),
            "truncated": count > len(rows),
            "rows": [
                self._json_row(row, {field.column: field.mask for field in fields if field.mask})
                for row in rows[:5]
            ],
        }

    def _system(self, code: str) -> SystemConfig:
        system = self.skill.systems.get(code)
        if system is None:
            raise ValueError("系统未在 Skill 目录中配置")
        return system

    def _summary_table(self, system_code: str, table_code: str) -> SummaryTableConfig:
        table = self._system(system_code).summary_tables.get(table_code)
        if table is None:
            raise ValueError("汇总表未在指定系统中配置")
        return table

    def _detail_table(self, system_code: str, table_code: str) -> DetailTableConfig:
        table = self._system(system_code).detail_tables.get(table_code)
        if table is None:
            raise ValueError("明细表未在指定系统中配置")
        return table

    @staticmethod
    def _select_items(catalog: Mapping[str, Any], codes: Sequence[str], label: str) -> list[Any]:
        if not codes:
            raise ValueError(f"{label}不能为空")
        items: list[Any] = []
        seen: set[str] = set()
        for code in codes:
            if code in seen:
                continue
            item = catalog.get(code)
            if item is None:
                raise ValueError(f"{label}未在 Skill 目录中配置: {code}")
            seen.add(code)
            items.append(item)
        return items

    @staticmethod
    def _required_scope(
        start_date: str, end_date: str, organization: str
    ) -> tuple[date, date, str]:
        normalized_organization = organization.strip()
        if not normalized_organization:
            raise ValueError("机构或主体范围不能为空")
        start = RegulatoryDataQueryService._parse_date(start_date, "开始日期")
        end = RegulatoryDataQueryService._parse_date(end_date, "结束日期")
        if start > end:
            raise ValueError("开始日期不能晚于结束日期")
        return start, end, normalized_organization

    def _where_clause(
        self,
        date_column: str,
        organization_column: str,
        fields: Mapping[str, FieldConfig],
        start: date,
        end: date,
        organization: str,
        filters: Sequence[Mapping[str, Any]],
    ) -> tuple[str, dict[str, Any], list[dict[str, Any]]]:
        conditions = [
            f"{_quote_identifier(date_column)} >= :start_date",
            f"{_quote_identifier(date_column)} <= :end_date",
            f"{_quote_identifier(organization_column)} = :organization",
        ]
        parameters: dict[str, Any] = {
            "start_date": start,
            "end_date": end,
            "organization": organization,
        }
        summary: list[dict[str, Any]] = []
        for index, raw in enumerate(filters):
            code = str(raw.get("field") or "").strip()
            operator = str(raw.get("operator") or "").lower()
            field = fields.get(code)
            if field is None or not field.filterable:
                raise ValueError(f"筛选字段未在 Skill 中配置: {code or '空'}")
            if operator not in field.operators:
                raise ValueError(f"筛选字段 {code} 不支持操作符 {operator or '空'}")
            condition, values, normalized = self._filter_condition(
                field, operator, raw.get("value"), f"filter_{index}"
            )
            conditions.append(f"{_quote_identifier(field.column)} {condition}")
            parameters.update(values)
            summary.append({"field": code, "operator": operator, "value": normalized})
        return " WHERE " + " AND ".join(conditions), parameters, summary

    def _filter_condition(
        self, field: FieldConfig, operator: str, value: Any, prefix: str
    ) -> tuple[str, dict[str, Any], Any]:
        if operator == "in":
            if not isinstance(value, list) or not value:
                raise ValueError("in 操作符必须提供非空数组")
            values = [self._validate_filter_value(field.value_type, item) for item in value]
            parameters = {f"{prefix}_{index}": item for index, item in enumerate(values)}
            return (
                f"IN ({', '.join(':' + key for key in parameters)})",
                parameters,
                [_json_safe(item) for item in values],
            )
        normalized = self._validate_filter_value(field.value_type, value)
        if operator == "like":
            if field.value_type != "string":
                raise ValueError("like 操作符只支持字符串字段")
            return f"LIKE :{prefix}", {prefix: f"%{normalized}%"}, normalized
        return f"= :{prefix}", {prefix: normalized}, _json_safe(normalized)

    @staticmethod
    def _validate_filter_value(value_type: str, value: Any) -> Any:
        if value_type == "string":
            if not isinstance(value, str) or not value.strip():
                raise ValueError("字符串筛选值不能为空")
            return value.strip()
        if value_type == "number":
            if isinstance(value, bool) or not isinstance(value, (int, float, Decimal)):
                raise ValueError("数值筛选字段必须提供数字")
            return value
        if value_type == "boolean":
            if not isinstance(value, bool):
                raise ValueError("布尔筛选字段必须提供 true 或 false")
            return value
        if value_type == "date":
            if not isinstance(value, str):
                raise ValueError("日期筛选字段必须使用 YYYY-MM-DD")
            return RegulatoryDataQueryService._parse_date(value, "筛选日期")
        raise ValueError("筛选字段类型不受支持")

    @staticmethod
    def _parse_date(value: str, label: str) -> date:
        try:
            return date.fromisoformat(value)
        except (TypeError, ValueError) as exc:
            raise ValueError(f"{label}必须使用 YYYY-MM-DD 格式") from exc

    @staticmethod
    def _order_clause(rules: Sequence[OrderRule], fields: Mapping[str, FieldConfig]) -> str:
        if not rules:
            return ""
        return " ORDER BY " + ", ".join(
            f"{_quote_identifier(fields[rule.field_code].column)} {rule.direction.upper()}"
            for rule in rules
        )

    def _count(self, statement: Any, parameters: Mapping[str, Any]) -> int:
        with self.engine.connect() as connection:
            return int(
                connection.execute(statement, dict(parameters)).mappings().one().get("total_count")
                or 0
            )

    def _rows(self, statement: Any, parameters: Mapping[str, Any]) -> list[dict[str, Any]]:
        with self.engine.connect() as connection:
            return [
                dict(row)
                for row in connection.execute(statement, dict(parameters)).mappings().all()
            ]

    @staticmethod
    def _json_row(
        row: Mapping[str, Any], masks: Mapping[str, str | None] | None = None
    ) -> dict[str, Any]:
        sanitized: dict[str, Any] = {}
        for column, value in row.items():
            mask = masks.get(column) if masks else None
            sanitized[column] = _mask_value(value, mask) if mask else _json_safe(value)
        return sanitized


def create_regulatory_query_skill_runtime(
    skill: RegulatoryQuerySkill, engine_factory: EngineFactory = create_engine
) -> SkillRuntime:
    database_url = os.getenv(skill.database_url_env, "").strip()
    if not database_url:
        raise SkillConfigurationError(f"缺少监管查询数据库连接环境变量: {skill.database_url_env}")
    service = RegulatoryDataQueryService(skill, database_url, engine_factory)

    def filters(items: list[QueryFilterInput]) -> list[dict[str, Any]]:
        return [
            item.model_dump() if isinstance(item, QueryFilterInput) else dict(item)
            for item in items
        ]

    return SkillRuntime(
        instructions=skill.instructions,
        tools=(
            StructuredTool.from_function(
                service.browse_catalog,
                name="browse_regulatory_catalog",
                description="查询已配置的监管系统和汇总/明细表目录，不读取业务数据。",
                args_schema=BrowseCatalogInput,
            ),
            StructuredTool.from_function(
                service.search_metrics,
                name="search_regulatory_metrics",
                description="在指定系统和汇总表中检索受控指标目录，不读取业务数据。",
                args_schema=SearchCatalogInput,
            ),
            StructuredTool.from_function(
                service.search_fields,
                name="search_regulatory_fields",
                description="在指定系统和明细表中检索可用字段目录，不读取业务数据。",
                args_schema=SearchCatalogInput,
            ),
            StructuredTool.from_function(
                lambda **kwargs: service.query_summary(
                    **{**kwargs, "filters": filters(kwargs["filters"])}
                ),
                name="query_regulatory_summary",
                description="按受控系统、汇总表、指标、日期、机构和筛选条件查询汇总数据。",
                args_schema=QuerySummaryInput,
            ),
            StructuredTool.from_function(
                lambda **kwargs: service.query_detail(
                    **{**kwargs, "filters": filters(kwargs["filters"])}
                ),
                name="query_regulatory_detail",
                description=(
                    "按受控系统、明细表、返回字段、日期、机构和筛选条件查询明细数据，"
                    "最多返回 5 条。"
                ),
                args_schema=QueryDetailInput,
            ),
        ),
        tool_names=REGULATORY_QUERY_TOOL_NAMES,
    )


def create_skill_runtime(skill_dir: Path) -> SkillRuntime:
    """Packaged Skill entry point used by the generic Sidecar loader."""

    return create_regulatory_query_skill_runtime(load_regulatory_query_skill(skill_dir))


def is_regulatory_query_tool(name: str) -> bool:
    return name in REGULATORY_QUERY_TOOL_NAMES


def summarize_regulatory_query_result(output: Any) -> str:
    if not isinstance(output, dict):
        return "监管数据查询已完成"
    if "systems" in output:
        return f"监管目录检索完成，共 {output.get('system_count', 0)} 个系统"
    if "candidates" in output:
        return f"指标候选检索完成，共 {output.get('candidate_count', 0)} 条候选"
    if "fields" in output:
        return f"明细字段检索完成，共 {output.get('field_count', 0)} 个字段"
    suffix = "，结果已截断" if output.get("truncated") else ""
    returned_count = output.get("returned_count", 0)
    return f"监管{output.get('view', '数据')}查询完成，返回 {returned_count} 条{suffix}"
