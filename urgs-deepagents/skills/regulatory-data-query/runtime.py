"""Declarative Skill runtime for direct regulatory data queries."""

from __future__ import annotations

import json
import os
import re
from collections.abc import Callable, Mapping, Sequence
from dataclasses import dataclass, field
from datetime import date, datetime
from decimal import Decimal
from pathlib import Path
from typing import Any, Literal, cast

from langchain_core.tools import StructuredTool
from pydantic import BaseModel, Field
from sqlalchemy import create_engine, text
from sqlalchemy.exc import SQLAlchemyError

from urgs_deepagents_service.skill_loader import SkillConfigurationError, SkillRuntime

REGULATORY_DATA_QUERY_AGENT_CODE = "regulatory-data-query-agent"
REGULATORY_DATA_QUERY_SKILL_CODE = "regulatory-data-query"
REGULATORY_QUERY_TOOL_NAMES = frozenset(
    {
        "browse_regulatory_catalog",
        "list_regulatory_periods",
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
_COMPACT_DATE_PATTERN = re.compile(r"^\d{8}$")
_CHINESE_DATE_PATTERN = re.compile(r"^(\d{4})年(\d{1,2})月(\d{1,2})日?$")
_ORG_CODE_WITH_SUFFIX_PATTERN = re.compile(r"^([A-Za-z0-9_-]+)\s*(?:机构|主体)$")
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
class AssetMetricQueryConfig:
    reg_element_id: int
    source_metric_code: str
    query_mode: Literal["SUMMARY", "DETAIL"]
    table: str
    date_column: str
    organization_column: str
    organization_name_column: str | None
    metric_code_column: str | None
    value_column: str
    fields: Mapping[str, FieldConfig]
    default_return_fields: tuple[str, ...]
    max_rows: int
    order_by: tuple[OrderRule, ...]
    description: str | None


@dataclass(frozen=True)
class MetricConfig:
    code: str
    name: str
    value_type: Literal["string", "number", "boolean", "date"]
    query_config: AssetMetricQueryConfig | None = None


@dataclass(frozen=True)
class SummaryTableConfig:
    code: str
    name: str
    table: str
    date_column: str
    organization_column: str
    organization_name_column: str | None
    metric_code_column: str
    indicators: Mapping[str, MetricConfig]
    result_fields: tuple[FieldConfig, ...]
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
    organization_name_column: str | None
    fields: Mapping[str, FieldConfig]
    default_return_fields: tuple[str, ...]
    max_rows: int
    order_by: tuple[OrderRule, ...]
    indicator_configs: Mapping[str, MetricConfig] = field(default_factory=dict)


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
    system_code: str | None = Field(
        default=None, description="系统编码或唯一系统名称；为空时返回可用系统"
    )
    view: Literal["summary", "detail"] | None = Field(default=None, description="汇总或明细")
    keyword: str | None = Field(default=None, max_length=128, description="系统或表名称关键字")


class SearchCatalogInput(BaseModel):
    system_code: str = Field(min_length=1, max_length=64, description="系统编码或唯一系统名称")
    table_code: str = Field(min_length=1, max_length=64, description="目录表编码或唯一表名称")
    keyword: str = Field(min_length=1, max_length=128, description="指标或字段名称关键字")


class ListPeriodsInput(BaseModel):
    system_code: str = Field(min_length=1, max_length=64, description="系统编码或唯一系统名称")
    table_code: str = Field(min_length=1, max_length=64, description="目录表编码或唯一表名称")
    view: Literal["summary", "detail"] = Field(description="汇总或明细")
    indicator_codes: list[str] = Field(
        default_factory=list, max_length=20, description="汇总指标编码或唯一指标名称"
    )
    organization: str | None = Field(default=None, max_length=128, description="机构编号或机构名称")
    filters: list[QueryFilterInput] = Field(default_factory=list, description="目录允许的筛选条件")


class QuerySummaryInput(BaseModel):
    system_code: str = Field(min_length=1, max_length=64, description="系统编码或唯一系统名称")
    table_code: str = Field(min_length=1, max_length=64, description="汇总表编码或唯一表名称")
    indicator_codes: list[str] = Field(min_length=1, max_length=20, description="已确认的指标编码")
    start_date: str = Field(description="统计开始日期，格式 YYYY-MM-DD")
    end_date: str = Field(description="统计结束日期，格式 YYYY-MM-DD")
    organization: str = Field(min_length=1, max_length=128, description="机构或主体范围")
    filters: list[QueryFilterInput] = Field(default_factory=list, description="目录允许的筛选条件")


class QueryDetailInput(BaseModel):
    system_code: str = Field(min_length=1, max_length=64, description="系统编码或唯一系统名称")
    table_code: str = Field(min_length=1, max_length=64, description="明细表编码或唯一表名称")
    indicator_codes: list[str] = Field(
        default_factory=list, max_length=20, description="明细指标编码或唯一指标名称"
    )
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


def _safe_asset_code(value: Any, fallback: str) -> str:
    candidate = str(value or "").strip().lower()
    candidate = re.sub(r"[^a-z0-9_-]+", "_", candidate).strip("_-")
    if not candidate or not candidate[0].isalpha():
        candidate = fallback
    if not _CODE_PATTERN.fullmatch(candidate):
        candidate = fallback
    return candidate


def _field_value_type(raw_type: Any) -> Literal["string", "number", "boolean", "date"]:
    normalized = str(raw_type or "").strip().lower()
    if any(token in normalized for token in ("date", "time")):
        return "date"
    if any(
        token in normalized
        for token in ("int", "number", "decimal", "numeric", "double", "float")
    ):
        return "number"
    if any(token in normalized for token in ("bool", "bit")):
        return "boolean"
    return "string"


def _read_json_list(value: Any) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item) for item in value if str(item or "").strip()]
    text_value = str(value or "").strip()
    if not text_value:
        return []
    try:
        parsed = json.loads(text_value)
    except json.JSONDecodeError:
        return []
    if not isinstance(parsed, list):
        return []
    return [str(item) for item in parsed if str(item or "").strip()]


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
    result_fields = tuple(
        _index_by_code(
            value.get("result_fields"), f"{field_name}.result_fields", _parse_field
        ).values()
    )
    if any(not field.returnable for field in result_fields):
        raise SkillConfigurationError(f"{field_name}.result_fields 中字段必须允许返回")
    organization_name_column = value.get("organization_name_column")
    return SummaryTableConfig(
        code=_require_code(value.get("code"), f"{field_name}.code"),
        name=_require_name(value.get("name"), f"{field_name}.name"),
        table=_require_identifier(value.get("table"), f"{field_name}.table"),
        date_column=_require_identifier(value.get("date_column"), f"{field_name}.date_column"),
        organization_column=_require_identifier(
            value.get("organization_column"), f"{field_name}.organization_column"
        ),
        organization_name_column=(
            _require_identifier(
                organization_name_column, f"{field_name}.organization_name_column"
            )
            if organization_name_column
            else None
        ),
        metric_code_column=_require_identifier(
            value.get("metric_code_column"), f"{field_name}.metric_code_column"
        ),
        indicators=_index_by_code(
            value.get("indicators"), f"{field_name}.indicators", _parse_metric
        ),
        result_fields=result_fields,
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
    organization_name_column = value.get("organization_name_column")
    return DetailTableConfig(
        code=_require_code(value.get("code"), f"{field_name}.code"),
        name=_require_name(value.get("name"), f"{field_name}.name"),
        table=_require_identifier(value.get("table"), f"{field_name}.table"),
        date_column=_require_identifier(value.get("date_column"), f"{field_name}.date_column"),
        organization_column=_require_identifier(
            value.get("organization_column"), f"{field_name}.organization_column"
        ),
        organization_name_column=(
            _require_identifier(
                organization_name_column, f"{field_name}.organization_name_column"
            )
            if organization_name_column
            else None
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


def _safe_tool_error(exc: Exception) -> dict[str, Any]:
    message = str(exc).strip().splitlines()[0] if str(exc).strip() else "监管查询工具执行失败"
    return {
        "ok": False,
        "error": message,
        "error_type": exc.__class__.__name__,
    }


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
        self.engine = engine_factory(database_url, pool_pre_ping=True)
        self.skill = self._merge_asset_catalog(skill)

    def _merge_asset_catalog(self, skill: RegulatoryQuerySkill) -> RegulatoryQuerySkill:
        systems = self._copy_systems(skill.systems)
        try:
            asset_rows = self._rows(
                text(
                    """
                    SELECT
                        cfg.id AS config_id,
                        cfg.reg_element_id,
                        cfg.query_mode,
                        cfg.model_table_id,
                        cfg.date_field_id,
                        cfg.org_code_field_id,
                        cfg.org_name_field_id,
                        cfg.metric_code_field_id,
                        cfg.value_field_id,
                        cfg.default_return_field_ids,
                        cfg.filter_field_ids,
                        cfg.sort_field_ids,
                        cfg.mask_field_ids,
                        cfg.detail_max_rows,
                        elem.name AS element_code,
                        elem.cn_name AS element_name,
                        elem.business_caliber AS element_description,
                        tbl.id AS reg_table_id,
                        tbl.name AS reg_table_code,
                        tbl.cn_name AS reg_table_name,
                        tbl.system_code AS system_code,
                        mt.name AS physical_table,
                        mt.owner AS physical_owner
                    FROM reg_element_query_config cfg
                    JOIN reg_element elem ON elem.id = cfg.reg_element_id
                    JOIN reg_table tbl ON tbl.id = elem.table_id
                    JOIN model_table mt ON mt.id = cfg.model_table_id
                    WHERE cfg.enabled = 1
                      AND UPPER(elem.type) = 'INDICATOR'
                    """
                ),
                {},
            )
        except SQLAlchemyError:
            asset_rows = []

        if asset_rows:
            field_ids = sorted(
                {
                    field_id
                    for row in asset_rows
                    for field_id in self._asset_config_field_ids(row)
                    if field_id
                }
            )
            field_rows = self._load_asset_fields(field_ids)
            for row in asset_rows:
                metric = self._asset_metric_from_row(row, field_rows)
                query_config = metric.query_config
                if query_config is None:
                    continue
                system_code = _safe_asset_code(row.get("system_code"), "asset")
                system = systems.get(system_code)
                if system is None:
                    system = SystemConfig(
                        code=system_code,
                        name=str(row.get("system_code") or "资产管理监管系统"),
                        summary_tables={},
                        detail_tables={},
                    )
                table_code = _safe_asset_code(
                    row.get("reg_table_code"), f"asset_table_{row.get('reg_table_id')}"
                )
                table_name = str(
                    row.get("reg_table_name") or row.get("reg_table_code") or table_code
                )
                if query_config.query_mode == "SUMMARY":
                    summary_tables = dict(system.summary_tables)
                    current = summary_tables.get(table_code)
                    if current is None:
                        current = self._asset_summary_table(table_code, table_name, metric)
                    summary_tables[table_code] = SummaryTableConfig(
                        code=current.code,
                        name=current.name,
                        table=current.table,
                        date_column=current.date_column,
                        organization_column=current.organization_column,
                        organization_name_column=current.organization_name_column,
                        metric_code_column=current.metric_code_column,
                        indicators={**current.indicators, metric.code: metric},
                        result_fields=current.result_fields,
                        filters=current.filters,
                        max_rows=current.max_rows,
                        order_by=current.order_by,
                    )
                    systems[system_code] = SystemConfig(
                        code=system.code,
                        name=system.name,
                        summary_tables=summary_tables,
                        detail_tables=system.detail_tables,
                    )
                else:
                    detail_tables = dict(system.detail_tables)
                    current_detail = detail_tables.get(table_code)
                    if current_detail is None:
                        current_detail = self._asset_detail_table(table_code, table_name, metric)
                    else:
                        current_detail = self._merge_asset_detail_table(current_detail, metric)
                    detail_tables[table_code] = current_detail
                    systems[system_code] = SystemConfig(
                        code=system.code,
                        name=system.name,
                        summary_tables=system.summary_tables,
                        detail_tables=detail_tables,
                    )

        systems = self._merge_table_detail_catalog(systems)
        return RegulatoryQuerySkill(
            skill_code=skill.skill_code,
            skill_dir=skill.skill_dir,
            instructions=skill.instructions,
            database_url_env=skill.database_url_env,
            catalog_limit=skill.catalog_limit,
            systems=systems,
        )

    def _merge_table_detail_catalog(
        self, systems: dict[str, SystemConfig]
    ) -> dict[str, SystemConfig]:
        try:
            table_rows = self._rows(
                text(
                    """
                    SELECT
                        cfg.id AS config_id,
                        cfg.reg_table_id,
                        cfg.model_table_id,
                        cfg.date_field_id,
                        cfg.org_code_field_id,
                        cfg.org_name_field_id,
                        cfg.default_return_field_ids,
                        cfg.filter_field_ids,
                        cfg.sort_field_ids,
                        cfg.mask_field_ids,
                        cfg.detail_max_rows,
                        tbl.name AS reg_table_code,
                        tbl.cn_name AS reg_table_name,
                        tbl.system_code AS system_code,
                        mt.name AS physical_table,
                        mt.owner AS physical_owner
                    FROM reg_table_query_config cfg
                    JOIN reg_table tbl ON tbl.id = cfg.reg_table_id
                    JOIN model_table mt ON mt.id = cfg.model_table_id
                    WHERE cfg.enabled = 1
                      AND UPPER(COALESCE(tbl.query_table_type, 'SUMMARY')) = 'DETAIL'
                    """
                ),
                {},
            )
        except SQLAlchemyError:
            return systems
        if not table_rows:
            return systems

        field_ids = sorted(
            {
                field_id
                for row in table_rows
                for field_id in self._table_config_field_ids(row)
                if field_id
            }
        )
        field_rows = self._load_asset_fields(field_ids)
        for row in table_rows:
            system_code = _safe_asset_code(row.get("system_code"), "asset")
            system = systems.get(system_code)
            if system is None:
                system = SystemConfig(
                    code=system_code,
                    name=str(row.get("system_code") or "资产管理监管系统"),
                    summary_tables={},
                    detail_tables={},
                )
            table_code = _safe_asset_code(
                row.get("reg_table_code"), f"asset_table_{row.get('reg_table_id')}"
            )
            detail_tables = dict(system.detail_tables)
            detail_tables[table_code] = self._table_detail_from_row(
                table_code,
                str(row.get("reg_table_name") or row.get("reg_table_code") or table_code),
                row,
                field_rows,
            )
            systems[system_code] = SystemConfig(
                code=system.code,
                name=system.name,
                summary_tables=system.summary_tables,
                detail_tables=detail_tables,
            )
        return systems

    @staticmethod
    def _copy_systems(systems: Mapping[str, SystemConfig]) -> dict[str, SystemConfig]:
        return {
            code: SystemConfig(
                code=system.code,
                name=system.name,
                summary_tables=dict(system.summary_tables),
                detail_tables=dict(system.detail_tables),
            )
            for code, system in systems.items()
        }

    @staticmethod
    def _asset_config_field_ids(row: Mapping[str, Any]) -> tuple[str, ...]:
        field_ids = [
            row.get("date_field_id"),
            row.get("org_code_field_id"),
            row.get("org_name_field_id"),
            row.get("metric_code_field_id"),
            row.get("value_field_id"),
        ]
        field_ids.extend(_read_json_list(row.get("default_return_field_ids")))
        field_ids.extend(_read_json_list(row.get("filter_field_ids")))
        field_ids.extend(_read_json_list(row.get("sort_field_ids")))
        field_ids.extend(_read_json_list(row.get("mask_field_ids")))
        return tuple(dict.fromkeys(str(item) for item in field_ids if str(item or "").strip()))

    @staticmethod
    def _table_config_field_ids(row: Mapping[str, Any]) -> tuple[str, ...]:
        field_ids = [
            row.get("date_field_id"),
            row.get("org_code_field_id"),
            row.get("org_name_field_id"),
        ]
        field_ids.extend(_read_json_list(row.get("default_return_field_ids")))
        field_ids.extend(_read_json_list(row.get("filter_field_ids")))
        field_ids.extend(_read_json_list(row.get("sort_field_ids")))
        field_ids.extend(_read_json_list(row.get("mask_field_ids")))
        return tuple(dict.fromkeys(str(item) for item in field_ids if str(item or "").strip()))

    def _load_asset_fields(self, field_ids: Sequence[str]) -> Mapping[str, Mapping[str, Any]]:
        if not field_ids:
            return {}
        parameters = {f"field_{index}": field_id for index, field_id in enumerate(field_ids)}
        placeholders = ", ".join(f":{key}" for key in parameters)
        rows = self._rows(
            text(
                "SELECT id, table_id, name, cn_name, type "
                f"FROM model_field WHERE id IN ({placeholders})"
            ),
            parameters,
        )
        return {str(row["id"]): row for row in rows}

    def _asset_metric_from_row(
        self, row: Mapping[str, Any], fields_by_id: Mapping[str, Mapping[str, Any]]
    ) -> MetricConfig:
        query_mode = str(row.get("query_mode") or "").upper()
        if query_mode not in {"SUMMARY", "DETAIL"}:
            raise SkillConfigurationError("资产查询配置的查询模式只支持 SUMMARY 或 DETAIL")
        model_table_id = str(row.get("model_table_id") or "")
        table_name = self._asset_table_identifier(row)
        default_ids = tuple(_read_json_list(row.get("default_return_field_ids")))
        filter_ids = set(_read_json_list(row.get("filter_field_ids")))
        sort_ids = set(_read_json_list(row.get("sort_field_ids")))
        mask_ids = set(_read_json_list(row.get("mask_field_ids")))
        max_rows = int(row.get("detail_max_rows") or 5)
        if max_rows < 1 or max_rows > 5:
            raise SkillConfigurationError("资产查询配置的明细最大返回行数必须在 1 到 5 之间")
        required_ids = {
            str(row.get("date_field_id") or ""),
            str(row.get("org_code_field_id") or ""),
            str(row.get("value_field_id") or ""),
        }
        if not all(required_ids):
            raise SkillConfigurationError("资产查询配置缺少日期、机构编号或指标值字段")
        selected_ids = self._asset_config_field_ids(row)
        field_configs, field_code_by_id = self._asset_field_configs(
            model_table_id=model_table_id,
            field_ids=selected_ids,
            fields_by_id=fields_by_id,
            default_ids=set(default_ids),
            filter_ids=filter_ids,
            sort_ids=sort_ids,
            mask_ids=mask_ids,
        )
        for field_id in required_ids:
            if field_id not in field_code_by_id:
                raise SkillConfigurationError("资产查询配置引用了不存在的必填字段")
        default_codes = tuple(field_code_by_id[field_id] for field_id in default_ids)
        if not default_codes:
            raise SkillConfigurationError("资产查询配置必须选择默认返回字段")
        order_by = tuple(
            OrderRule(field_code_by_id[field_id], "asc")
            for field_id in _read_json_list(row.get("sort_field_ids"))
            if field_id in field_code_by_id
        )
        metric_code = _safe_asset_code(
            row.get("element_code"), f"asset_metric_{row.get('reg_element_id')}"
        )
        return MetricConfig(
            code=metric_code,
            name=str(row.get("element_name") or row.get("element_code") or metric_code),
            value_type="number",
            query_config=AssetMetricQueryConfig(
                reg_element_id=int(row.get("reg_element_id") or 0),
                source_metric_code=str(row.get("element_code") or metric_code),
                query_mode=cast(Literal["SUMMARY", "DETAIL"], query_mode),
                table=table_name,
                date_column=self._asset_column(row.get("date_field_id"), fields_by_id),
                organization_column=self._asset_column(
                    row.get("org_code_field_id"), fields_by_id
                ),
                organization_name_column=self._asset_optional_column(
                    row.get("org_name_field_id"), fields_by_id
                ),
                metric_code_column=self._asset_optional_column(
                    row.get("metric_code_field_id"), fields_by_id
                ),
                value_column=self._asset_column(row.get("value_field_id"), fields_by_id),
                fields=field_configs,
                default_return_fields=default_codes,
                max_rows=max_rows if query_mode == "DETAIL" else 100,
                order_by=order_by,
                description=(
                    str(row.get("element_description"))
                    if row.get("element_description")
                    else None
                ),
            ),
        )

    def _table_detail_from_row(
        self,
        table_code: str,
        table_name: str,
        row: Mapping[str, Any],
        fields_by_id: Mapping[str, Mapping[str, Any]],
    ) -> DetailTableConfig:
        model_table_id = str(row.get("model_table_id") or "")
        physical_table = self._asset_table_identifier(row)
        default_ids = tuple(_read_json_list(row.get("default_return_field_ids")))
        filter_ids = set(_read_json_list(row.get("filter_field_ids")))
        sort_ids = set(_read_json_list(row.get("sort_field_ids")))
        mask_ids = set(_read_json_list(row.get("mask_field_ids")))
        max_rows = int(row.get("detail_max_rows") or 5)
        if max_rows < 1 or max_rows > 5:
            raise SkillConfigurationError("表级明细查询配置的最大返回行数必须在 1 到 5 之间")
        required_ids = {
            str(row.get("date_field_id") or ""),
            str(row.get("org_code_field_id") or ""),
        }
        if not all(required_ids):
            raise SkillConfigurationError("表级明细查询配置缺少日期或机构编号字段")
        selected_ids = self._table_config_field_ids(row)
        field_configs, field_code_by_id = self._asset_field_configs(
            model_table_id=model_table_id,
            field_ids=selected_ids,
            fields_by_id=fields_by_id,
            default_ids=set(default_ids),
            filter_ids=filter_ids,
            sort_ids=sort_ids,
            mask_ids=mask_ids,
        )
        for field_id in required_ids:
            if field_id not in field_code_by_id:
                raise SkillConfigurationError("表级明细查询配置引用了不存在的必填字段")
        default_codes = tuple(field_code_by_id[field_id] for field_id in default_ids)
        if not default_codes:
            raise SkillConfigurationError("表级明细查询配置必须选择默认返回字段")
        order_by = tuple(
            OrderRule(field_code_by_id[field_id], "asc")
            for field_id in _read_json_list(row.get("sort_field_ids"))
            if field_id in field_code_by_id
        )
        return DetailTableConfig(
            code=table_code,
            name=table_name,
            table=physical_table,
            date_column=self._asset_column(row.get("date_field_id"), fields_by_id),
            organization_column=self._asset_column(row.get("org_code_field_id"), fields_by_id),
            organization_name_column=self._asset_optional_column(
                row.get("org_name_field_id"), fields_by_id
            ),
            fields=field_configs,
            default_return_fields=default_codes,
            max_rows=max_rows,
            order_by=order_by,
        )

    def _asset_field_configs(
        self,
        *,
        model_table_id: str,
        field_ids: Sequence[str],
        fields_by_id: Mapping[str, Mapping[str, Any]],
        default_ids: set[str],
        filter_ids: set[str],
        sort_ids: set[str],
        mask_ids: set[str],
    ) -> tuple[dict[str, FieldConfig], dict[str, str]]:
        fields: dict[str, FieldConfig] = {}
        field_code_by_id: dict[str, str] = {}
        for field_id in field_ids:
            raw_field = fields_by_id.get(field_id)
            if raw_field is None:
                raise SkillConfigurationError(f"资产查询配置引用了不存在的物理字段: {field_id}")
            if str(raw_field.get("table_id") or "") != model_table_id:
                raise SkillConfigurationError("资产查询配置引用了不属于主查询表的物理字段")
            base_code = _safe_asset_code(raw_field.get("name"), f"field_{len(fields) + 1}")
            code = base_code
            suffix = 2
            while code in fields:
                code = f"{base_code}_{suffix}"
                suffix += 1
            value_type = _field_value_type(raw_field.get("type"))
            fields[code] = FieldConfig(
                code=code,
                name=str(raw_field.get("cn_name") or raw_field.get("name") or code),
                column=_require_identifier(raw_field.get("name"), "资产查询配置字段名"),
                value_type=value_type,
                returnable=field_id in default_ids,
                filterable=field_id in filter_ids,
                sortable=field_id in sort_ids,
                operators=frozenset(
                    ["eq", "in", "like"] if value_type == "string" else ["eq", "in"]
                ),
                mask=self._infer_mask_rule(raw_field) if field_id in mask_ids else None,
            )
            field_code_by_id[field_id] = code
        return fields, field_code_by_id

    @staticmethod
    def _asset_table_identifier(row: Mapping[str, Any]) -> str:
        physical_table = _require_identifier(row.get("physical_table"), "资产查询配置物理表名")
        owner = str(row.get("physical_owner") or "").strip()
        if owner:
            return _require_identifier(f"{owner}.{physical_table}", "资产查询配置物理表名")
        return physical_table

    @staticmethod
    def _asset_column(field_id: Any, fields_by_id: Mapping[str, Mapping[str, Any]]) -> str:
        raw_field = fields_by_id.get(str(field_id or ""))
        if raw_field is None:
            raise SkillConfigurationError("资产查询配置引用了不存在的物理字段")
        return _require_identifier(raw_field.get("name"), "资产查询配置字段名")

    @staticmethod
    def _asset_optional_column(
        field_id: Any, fields_by_id: Mapping[str, Mapping[str, Any]]
    ) -> str | None:
        if not str(field_id or "").strip():
            return None
        return RegulatoryDataQueryService._asset_column(field_id, fields_by_id)

    @staticmethod
    def _infer_mask_rule(raw_field: Mapping[str, Any]) -> str:
        text_value = f"{raw_field.get('name') or ''} {raw_field.get('cn_name') or ''}".lower()
        if any(token in text_value for token in ("mobile", "phone", "手机号", "电话")):
            return "MOBILE"
        if any(token in text_value for token in ("id_card", "身份证")):
            return "ID_CARD"
        if any(token in text_value for token in ("account", "acct", "账号", "账户", "合同")):
            return "ACCOUNT"
        if any(token in text_value for token in ("name", "姓名", "客户名称", "名称")):
            return "NAME"
        return "FULL"

    @staticmethod
    def _asset_summary_table(
        table_code: str, table_name: str, metric: MetricConfig
    ) -> SummaryTableConfig:
        query_config = metric.query_config
        if query_config is None:
            raise SkillConfigurationError("资产指标缺少查询配置")
        result_fields = tuple(
            query_config.fields[field_code] for field_code in query_config.default_return_fields
        )
        filters = {
            field.code: field for field in query_config.fields.values() if field.filterable
        }
        return SummaryTableConfig(
            code=table_code,
            name=table_name,
            table=query_config.table,
            date_column=query_config.date_column,
            organization_column=query_config.organization_column,
            organization_name_column=query_config.organization_name_column,
            metric_code_column=query_config.metric_code_column or query_config.value_column,
            indicators={metric.code: metric},
            result_fields=result_fields,
            filters=filters,
            max_rows=100,
            order_by=query_config.order_by,
        )

    @staticmethod
    def _asset_detail_table(
        table_code: str, table_name: str, metric: MetricConfig
    ) -> DetailTableConfig:
        query_config = metric.query_config
        if query_config is None:
            raise SkillConfigurationError("资产指标缺少查询配置")
        return DetailTableConfig(
            code=table_code,
            name=table_name,
            table=query_config.table,
            date_column=query_config.date_column,
            organization_column=query_config.organization_column,
            organization_name_column=query_config.organization_name_column,
            fields=query_config.fields,
            default_return_fields=query_config.default_return_fields,
            max_rows=query_config.max_rows,
            order_by=query_config.order_by,
            indicator_configs={metric.code: metric},
        )

    @staticmethod
    def _merge_asset_detail_table(
        current: DetailTableConfig, metric: MetricConfig
    ) -> DetailTableConfig:
        query_config = metric.query_config
        if query_config is None:
            raise SkillConfigurationError("资产指标缺少查询配置")
        fields = {**current.fields, **query_config.fields}
        default_return_fields = tuple(
            dict.fromkeys([*current.default_return_fields, *query_config.default_return_fields])
        )
        return DetailTableConfig(
            code=current.code,
            name=current.name,
            table=current.table,
            date_column=current.date_column,
            organization_column=current.organization_column,
            organization_name_column=current.organization_name_column,
            fields=fields,
            default_return_fields=default_return_fields,
            max_rows=min(current.max_rows, query_config.max_rows, 5),
            order_by=current.order_by or query_config.order_by,
            indicator_configs={**current.indicator_configs, metric.code: metric},
        )

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
        system = self._system(system_code)
        try:
            table: SummaryTableConfig | DetailTableConfig = self._summary_table(
                system_code, table_code
            )
            indicator_catalog = table.indicators
        except ValueError:
            table = self._detail_table(system_code, table_code)
            indicator_catalog = table.indicator_configs
        if not indicator_catalog:
            raise ValueError("指定表未配置可查询指标")
        needle = keyword.strip().lower()
        if not needle:
            raise ValueError("指标关键字不能为空")
        metrics = [
            {"code": item.code, "name": item.name, "type": item.value_type}
            for item in indicator_catalog.values()
            if needle in item.code.lower() or needle in item.name.lower()
        ]
        return {
            "system_code": system.code,
            "table_code": table.code,
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
            "system_code": self._system(system_code).code,
            "table_code": table.code,
            "field_count": len(fields),
            "fields": fields[: self.skill.catalog_limit],
        }

    def list_periods(
        self,
        system_code: str,
        table_code: str,
        view: str,
        indicator_codes: Sequence[str],
        organization: str | None,
        filters: Sequence[Mapping[str, Any]],
    ) -> dict[str, Any]:
        if view == "summary":
            table = self._summary_table(system_code, table_code)
            fields = table.filters
            organization_columns = self._organization_columns(table)
            conditions, parameters, filter_summary = self._optional_scope_conditions(
                organization_columns, organization, fields, filters
            )
            indicators = (
                self._select_items(table.indicators, indicator_codes, "指标")
                if indicator_codes
                else []
            )
            if any(indicator.query_config is not None for indicator in indicators):
                if any(indicator.query_config is None for indicator in indicators):
                    raise ValueError("资产配置指标与静态目录指标不能在一次查询中混用")
                return self._list_asset_periods(
                    system=self._system(system_code),
                    table_code=table.code,
                    view="summary",
                    indicators=indicators,
                    organization=organization,
                    filters=filters,
                )
            if indicators:
                metric_parameters = {
                    f"metric_{index}": indicator.code for index, indicator in enumerate(indicators)
                }
                conditions.append(
                    f"{_quote_identifier(table.metric_code_column)} "
                    f"IN ({', '.join(f':{key}' for key in metric_parameters)})"
                )
                parameters.update(metric_parameters)
            normalized_system = self._system(system_code)
            normalized_table_code = table.code
            date_column = table.date_column
        elif view == "detail":
            table = self._detail_table(system_code, table_code)
            if table.indicator_configs:
                indicators = (
                    self._select_asset_detail_indicators(table, indicator_codes)
                    if indicator_codes
                    else list(table.indicator_configs.values())
                )
                return self._list_asset_periods(
                    system=self._system(system_code),
                    table_code=table.code,
                    view="detail",
                    indicators=indicators,
                    organization=organization,
                    filters=filters,
                )
            filterable = {code: field for code, field in table.fields.items() if field.filterable}
            conditions, parameters, filter_summary = self._optional_scope_conditions(
                self._organization_columns(table), organization, filterable, filters
            )
            indicators = []
            normalized_system = self._system(system_code)
            normalized_table_code = table.code
            date_column = table.date_column
        else:
            raise ValueError("view 只能是 summary 或 detail")

        where_sql = f" WHERE {' AND '.join(conditions)}" if conditions else ""
        count = self._count(
            text(
                f"SELECT COUNT(DISTINCT {_quote_identifier(date_column)}) AS total_count "
                f"FROM {_quote_identifier(table.table)}{where_sql}"
            ),
            parameters,
        )
        rows = self._rows(
            text(
                f"SELECT DISTINCT {_quote_identifier(date_column)} AS data_date "
                f"FROM {_quote_identifier(table.table)}{where_sql} "
                f"ORDER BY {_quote_identifier(date_column)} DESC LIMIT :limit"
            ),
            {**parameters, "limit": self.skill.catalog_limit},
        )
        return {
            "view": view,
            "system_code": normalized_system.code,
            "table_code": normalized_table_code,
            "indicators": [{"code": item.code, "name": item.name} for item in indicators],
            "organization": self._normalize_organization(organization) if organization else None,
            "filters": filter_summary,
            "total_count": count,
            "returned_count": len(rows),
            "truncated": count > len(rows),
            "dates": [self._json_row(row)["data_date"] for row in rows],
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
        system = self._system(system_code)
        table = self._summary_table(system_code, table_code)
        indicators = self._select_items(table.indicators, indicator_codes, "指标")
        if any(indicator.query_config is not None for indicator in indicators):
            if any(indicator.query_config is None for indicator in indicators):
                raise ValueError("资产配置指标与静态目录指标不能在一次查询中混用")
            return self._query_asset_summary(
                system=system,
                table=table,
                indicators=indicators,
                start_date=start_date,
                end_date=end_date,
                organization=organization,
                filters=filters,
            )
        start, end, normalized_organization = self._required_scope(
            start_date, end_date, organization
        )
        where_sql, parameters, filter_summary = self._where_clause(
            table.date_column,
            self._organization_columns(table),
            table.filters,
            start,
            end,
            normalized_organization,
            filters,
        )
        metric_parameters = {
            f"metric_{index}": indicator.code for index, indicator in enumerate(indicators)
        }
        metric_placeholders = ", ".join(f":{key}" for key in metric_parameters)
        where_sql += (
            f" AND {_quote_identifier(table.metric_code_column)} IN ({metric_placeholders})"
        )
        columns_sql = ", ".join(
            f"{_quote_identifier(field.column)} AS {_quote_identifier(field.code)}"
            for field in table.result_fields
        )
        order_sql = self._order_clause(table.order_by, table.filters)
        rows = self._rows(
            text(
                f"SELECT {columns_sql} FROM {_quote_identifier(table.table)} "
                f"{where_sql}{order_sql} LIMIT :limit"
            ),
            {**parameters, **metric_parameters, "limit": table.max_rows},
        )
        return {
            "view": "summary",
            "system_code": system.code,
            "table_code": table.code,
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
        indicator_codes: Sequence[str] | None = None,
        return_fields: Sequence[str],
        start_date: str,
        end_date: str,
        organization: str,
        filters: Sequence[Mapping[str, Any]],
        sort_field: str | None,
        sort_direction: str | None,
    ) -> dict[str, Any]:
        system = self._system(system_code)
        table = self._detail_table(system_code, table_code)
        if table.indicator_configs:
            return self._query_asset_detail(
                system=system,
                table=table,
                indicator_codes=indicator_codes or [],
                return_fields=return_fields,
                start_date=start_date,
                end_date=end_date,
                organization=organization,
                filters=filters,
                sort_field=sort_field,
                sort_direction=sort_direction,
            )
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
            self._organization_columns(table),
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
            "system_code": system.code,
            "table_code": table.code,
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

    def _list_asset_periods(
        self,
        *,
        system: SystemConfig,
        table_code: str,
        view: Literal["summary", "detail"],
        indicators: Sequence[MetricConfig],
        organization: str | None,
        filters: Sequence[Mapping[str, Any]],
    ) -> dict[str, Any]:
        if not indicators:
            raise ValueError("资产配置指标不能为空")
        all_dates: set[str] = set()
        filter_summary: list[dict[str, Any]] = []
        for indicator in indicators:
            query_config = self._asset_query_config(indicator, view.upper())
            conditions, parameters, filter_summary = self._optional_scope_conditions(
                self._asset_organization_columns(query_config),
                organization,
                self._asset_filterable_fields(query_config),
                filters,
            )
            if query_config.metric_code_column:
                conditions.append(
                    f"{_quote_identifier(query_config.metric_code_column)} = :asset_metric_code"
                )
                parameters["asset_metric_code"] = query_config.source_metric_code
            where_sql = f" WHERE {' AND '.join(conditions)}" if conditions else ""
            rows = self._rows(
                text(
                    f"SELECT DISTINCT {_quote_identifier(query_config.date_column)} AS data_date "
                    f"FROM {_quote_identifier(query_config.table)}{where_sql} "
                    f"ORDER BY {_quote_identifier(query_config.date_column)} DESC "
                    "LIMIT :limit"
                ),
                {**parameters, "limit": self.skill.catalog_limit},
            )
            all_dates.update(str(self._json_row(row)["data_date"]) for row in rows)
        ordered_dates = sorted(all_dates, reverse=True)
        returned_dates = ordered_dates[: self.skill.catalog_limit]
        return {
            "view": view,
            "system_code": system.code,
            "table_code": table_code,
            "indicators": [{"code": item.code, "name": item.name} for item in indicators],
            "organization": self._normalize_organization(organization) if organization else None,
            "filters": filter_summary,
            "total_count": len(ordered_dates),
            "returned_count": len(returned_dates),
            "truncated": len(ordered_dates) > len(returned_dates),
            "dates": returned_dates,
        }

    def _query_asset_summary(
        self,
        *,
        system: SystemConfig,
        table: SummaryTableConfig,
        indicators: Sequence[MetricConfig],
        start_date: str,
        end_date: str,
        organization: str,
        filters: Sequence[Mapping[str, Any]],
    ) -> dict[str, Any]:
        start, end, normalized_organization = self._required_scope(
            start_date, end_date, organization
        )
        rows: list[dict[str, Any]] = []
        filter_summary: list[dict[str, Any]] = []
        for indicator in indicators:
            query_config = self._asset_query_config(indicator, "SUMMARY")
            where_sql, parameters, filter_summary = self._where_clause(
                query_config.date_column,
                self._asset_organization_columns(query_config),
                self._asset_filterable_fields(query_config),
                start,
                end,
                normalized_organization,
                filters,
            )
            if query_config.metric_code_column:
                where_sql += (
                    f" AND {_quote_identifier(query_config.metric_code_column)} "
                    "= :asset_metric_code"
                )
                parameters["asset_metric_code"] = query_config.source_metric_code
            fields = [
                query_config.fields[field_code]
                for field_code in query_config.default_return_fields
                if field_code in query_config.fields
            ]
            columns_sql, masks = self._asset_select_columns(
                fields, query_config.value_column
            )
            order_sql = self._order_clause(query_config.order_by, query_config.fields)
            result_rows = self._rows(
                text(
                    f"SELECT {columns_sql} FROM {_quote_identifier(query_config.table)} "
                    f"{where_sql}{order_sql} LIMIT :limit"
                ),
                {**parameters, "limit": query_config.max_rows},
            )
            for row in result_rows:
                sanitized = self._json_row(row, masks)
                sanitized.setdefault("metric_code", indicator.code)
                sanitized.setdefault("metric_name", indicator.name)
                if query_config.description:
                    sanitized.setdefault("metric_description", query_config.description)
                rows.append(sanitized)
        return {
            "view": "summary",
            "system_code": system.code,
            "table_code": table.code,
            "indicators": [{"code": item.code, "name": item.name} for item in indicators],
            "start_date": start.isoformat(),
            "end_date": end.isoformat(),
            "organization": normalized_organization,
            "filters": filter_summary,
            "returned_count": len(rows),
            "rows": rows,
        }

    def _query_asset_detail(
        self,
        *,
        system: SystemConfig,
        table: DetailTableConfig,
        indicator_codes: Sequence[str],
        return_fields: Sequence[str],
        start_date: str,
        end_date: str,
        organization: str,
        filters: Sequence[Mapping[str, Any]],
        sort_field: str | None,
        sort_direction: str | None,
    ) -> dict[str, Any]:
        indicators = self._select_asset_detail_indicators(table, indicator_codes)
        start, end, normalized_organization = self._required_scope(
            start_date, end_date, organization
        )
        rows: list[dict[str, Any]] = []
        total_count = 0
        filter_summary: list[dict[str, Any]] = []
        returned_fields: dict[str, FieldConfig] = {}
        for indicator in indicators:
            query_config = self._asset_query_config(indicator, "DETAIL")
            selected_fields = self._select_items(
                query_config.fields,
                return_fields or query_config.default_return_fields,
                "明细返回字段",
            )
            if any(not field.returnable for field in selected_fields):
                raise ValueError("请求包含不可返回的明细字段")
            returned_fields.update({field.code: field for field in selected_fields})
            where_sql, parameters, filter_summary = self._where_clause(
                query_config.date_column,
                self._asset_organization_columns(query_config),
                self._asset_filterable_fields(query_config),
                start,
                end,
                normalized_organization,
                filters,
            )
            if query_config.metric_code_column:
                where_sql += (
                    f" AND {_quote_identifier(query_config.metric_code_column)} "
                    "= :asset_metric_code"
                )
                parameters["asset_metric_code"] = query_config.source_metric_code
            order_by = query_config.order_by
            if sort_field:
                field_config = query_config.fields.get(sort_field)
                if field_config is None or not field_config.sortable:
                    raise ValueError("请求的明细排序字段未在目录中允许")
                direction = (sort_direction or "asc").lower()
                if direction not in {"asc", "desc"}:
                    raise ValueError("明细排序方向只支持 asc 或 desc")
                order_by = (OrderRule(sort_field, cast(Literal["asc", "desc"], direction)),)
            count = self._count(
                text(
                    "SELECT COUNT(*) AS total_count "
                    f"FROM {_quote_identifier(query_config.table)} {where_sql}"
                ),
                parameters,
            )
            total_count += count
            remaining = 5 - len(rows)
            if remaining <= 0:
                continue
            columns_sql, masks = self._asset_select_columns(
                selected_fields, query_config.value_column
            )
            order_sql = self._order_clause(order_by, query_config.fields)
            result_rows = self._rows(
                text(
                    f"SELECT {columns_sql} FROM {_quote_identifier(query_config.table)} "
                    f"{where_sql}{order_sql} LIMIT :limit"
                ),
                {**parameters, "limit": min(query_config.max_rows, remaining, 5)},
            )
            for row in result_rows[:remaining]:
                sanitized = self._json_row(row, masks)
                sanitized.setdefault("metric_code", indicator.code)
                sanitized.setdefault("metric_name", indicator.name)
                if query_config.description:
                    sanitized.setdefault("metric_description", query_config.description)
                rows.append(sanitized)
        return {
            "view": "detail",
            "system_code": system.code,
            "table_code": table.code,
            "indicators": [{"code": item.code, "name": item.name} for item in indicators],
            "return_fields": [
                {"code": field.code, "name": field.name} for field in returned_fields.values()
            ],
            "start_date": start.isoformat(),
            "end_date": end.isoformat(),
            "organization": normalized_organization,
            "filters": filter_summary,
            "total_count": total_count,
            "returned_count": len(rows),
            "truncated": total_count > len(rows),
            "rows": rows[:5],
        }

    @staticmethod
    def _asset_query_config(indicator: MetricConfig, expected_mode: str) -> AssetMetricQueryConfig:
        query_config = indicator.query_config
        if query_config is None or query_config.query_mode != expected_mode:
            raise ValueError("指标未配置对应查询模式")
        return query_config

    @staticmethod
    def _asset_organization_columns(query_config: AssetMetricQueryConfig) -> tuple[str, ...]:
        columns = [query_config.organization_column]
        if (
            query_config.organization_name_column
            and query_config.organization_name_column not in columns
        ):
            columns.append(query_config.organization_name_column)
        return tuple(columns)

    @staticmethod
    def _asset_filterable_fields(
        query_config: AssetMetricQueryConfig,
    ) -> Mapping[str, FieldConfig]:
        return {code: field for code, field in query_config.fields.items() if field.filterable}

    @staticmethod
    def _asset_select_columns(
        fields: Sequence[FieldConfig], value_column: str
    ) -> tuple[str, dict[str, str | None]]:
        selected: list[str] = []
        masks: dict[str, str | None] = {}
        aliases: set[str] = set()
        for field_config in fields:
            aliases.add(field_config.code)
            masks[field_config.code] = field_config.mask
            selected.append(
                f"{_quote_identifier(field_config.column)} "
                f"AS {_quote_identifier(field_config.code)}"
            )
        if "metric_value" not in aliases:
            selected.append(f"{_quote_identifier(value_column)} AS `metric_value`")
        return ", ".join(selected), masks

    def _select_asset_detail_indicators(
        self, table: DetailTableConfig, indicator_codes: Sequence[str]
    ) -> list[MetricConfig]:
        if indicator_codes:
            return self._select_items(table.indicator_configs, indicator_codes, "明细指标")
        if len(table.indicator_configs) == 1:
            return list(table.indicator_configs.values())
        raise ValueError("明细指标不能为空，请先确认要查询的指标")

    def _system(self, code: str) -> SystemConfig:
        system = self.skill.systems.get(code)
        if system is not None:
            return system
        matched = [candidate for candidate in self.skill.systems.values() if candidate.name == code]
        if len(matched) == 1:
            return matched[0]
        if len(matched) > 1:
            raise ValueError(f"系统名称存在多个目录项，请使用编码: {code}")
        raise ValueError("系统未在 Skill 目录中配置")

    def _summary_table(self, system_code: str, table_code: str) -> SummaryTableConfig:
        return cast(
            SummaryTableConfig,
            self._table(self._system(system_code).summary_tables, table_code, "汇总表"),
        )

    def _detail_table(self, system_code: str, table_code: str) -> DetailTableConfig:
        return cast(
            DetailTableConfig,
            self._table(self._system(system_code).detail_tables, table_code, "明细表"),
        )

    @staticmethod
    def _table(
        catalog: Mapping[str, SummaryTableConfig | DetailTableConfig], code: str, label: str
    ) -> SummaryTableConfig | DetailTableConfig:
        table = catalog.get(code)
        if table is not None:
            return table
        matched = [candidate for candidate in catalog.values() if candidate.name == code]
        if len(matched) == 1:
            return matched[0]
        if len(matched) > 1:
            raise ValueError(f"{label}名称存在多个目录项，请使用编码: {code}")
        raise ValueError(f"{label}未在指定系统中配置")

    @staticmethod
    def _organization_columns(table: SummaryTableConfig | DetailTableConfig) -> tuple[str, ...]:
        columns = [table.organization_column]
        if table.organization_name_column and table.organization_name_column not in columns:
            columns.append(table.organization_name_column)
        return tuple(columns)

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
                matched = [candidate for candidate in catalog.values() if candidate.name == code]
                if len(matched) == 1:
                    item = matched[0]
                elif len(matched) > 1:
                    raise ValueError(f"{label}名称存在多个目录项，请使用编码: {code}")
                else:
                    raise ValueError(f"{label}未在 Skill 目录中配置: {code}")
            if item.code in seen:
                continue
            seen.add(item.code)
            items.append(item)
        return items

    @staticmethod
    def _required_scope(
        start_date: str, end_date: str, organization: str
    ) -> tuple[date, date, str]:
        normalized_organization = RegulatoryDataQueryService._normalize_organization(organization)
        if not normalized_organization:
            raise ValueError("机构或主体范围不能为空")
        start = RegulatoryDataQueryService._parse_date(start_date, "开始日期")
        end = RegulatoryDataQueryService._parse_date(end_date, "结束日期")
        if start > end:
            raise ValueError("开始日期不能晚于结束日期")
        return start, end, normalized_organization

    def _optional_scope_conditions(
        self,
        organization_columns: Sequence[str],
        organization: str | None,
        fields: Mapping[str, FieldConfig],
        filters: Sequence[Mapping[str, Any]],
    ) -> tuple[list[str], dict[str, Any], list[dict[str, Any]]]:
        conditions: list[str] = []
        parameters: dict[str, Any] = {}
        if organization and organization.strip():
            normalized = self._normalize_organization(organization)
            conditions.append(self._organization_condition(organization_columns))
            parameters["organization"] = normalized
        filter_conditions, filter_parameters, filter_summary = self._filter_conditions(
            fields, filters
        )
        conditions.extend(filter_conditions)
        parameters.update(filter_parameters)
        return conditions, parameters, filter_summary

    def _where_clause(
        self,
        date_column: str,
        organization_columns: Sequence[str],
        fields: Mapping[str, FieldConfig],
        start: date,
        end: date,
        organization: str,
        filters: Sequence[Mapping[str, Any]],
    ) -> tuple[str, dict[str, Any], list[dict[str, Any]]]:
        conditions = [
            f"{_quote_identifier(date_column)} >= :start_date",
            f"{_quote_identifier(date_column)} <= :end_date",
            self._organization_condition(organization_columns),
        ]
        parameters: dict[str, Any] = {
            "start_date": start,
            "end_date": end,
            "organization": organization,
        }
        filter_conditions, filter_parameters, summary = self._filter_conditions(fields, filters)
        conditions.extend(filter_conditions)
        parameters.update(filter_parameters)
        return " WHERE " + " AND ".join(conditions), parameters, summary

    @staticmethod
    def _organization_condition(organization_columns: Sequence[str]) -> str:
        unique_columns = tuple(dict.fromkeys(organization_columns))
        if not unique_columns:
            raise SkillConfigurationError("机构字段未配置")
        if len(unique_columns) == 1:
            return f"{_quote_identifier(unique_columns[0])} = :organization"
        return "(" + " OR ".join(
            f"{_quote_identifier(column)} = :organization" for column in unique_columns
        ) + ")"

    def _filter_conditions(
        self, fields: Mapping[str, FieldConfig], filters: Sequence[Mapping[str, Any]]
    ) -> tuple[list[str], dict[str, Any], list[dict[str, Any]]]:
        conditions: list[str] = []
        parameters: dict[str, Any] = {}
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
        return conditions, parameters, summary

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
        text_value = str(value or "").strip()
        if _COMPACT_DATE_PATTERN.fullmatch(text_value):
            text_value = f"{text_value[:4]}-{text_value[4:6]}-{text_value[6:]}"
        else:
            chinese_match = _CHINESE_DATE_PATTERN.fullmatch(text_value)
            if chinese_match:
                year, month, day = chinese_match.groups()
                text_value = f"{year}-{int(month):02d}-{int(day):02d}"
            else:
                text_value = text_value.replace("/", "-").replace(".", "-")
        try:
            return date.fromisoformat(text_value)
        except (TypeError, ValueError) as exc:
            raise ValueError(f"{label}必须使用明确日期格式，例如 YYYY-MM-DD 或 YYYYMMDD") from exc

    @staticmethod
    def _normalize_organization(value: str) -> str:
        normalized = str(value or "").strip()
        match = _ORG_CODE_WITH_SUFFIX_PATTERN.fullmatch(normalized)
        return match.group(1) if match else normalized

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

    def safe_call(operation: Callable[..., dict[str, Any]], **kwargs: Any) -> dict[str, Any]:
        try:
            return {"ok": True, **operation(**kwargs)}
        except (ValueError, SQLAlchemyError) as exc:
            return _safe_tool_error(exc)

    return SkillRuntime(
        instructions=skill.instructions,
        tools=(
            StructuredTool.from_function(
                lambda **kwargs: safe_call(service.browse_catalog, **kwargs),
                name="browse_regulatory_catalog",
                description="查询已配置的监管系统和汇总/明细表目录，不读取业务数据。",
                args_schema=BrowseCatalogInput,
            ),
            StructuredTool.from_function(
                lambda **kwargs: safe_call(
                    service.list_periods,
                    **{**kwargs, "filters": filters(kwargs["filters"])}
                ),
                name="list_regulatory_periods",
                description="按受控系统、表、指标、机构和筛选条件列出可用统计日期。",
                args_schema=ListPeriodsInput,
            ),
            StructuredTool.from_function(
                lambda **kwargs: safe_call(service.search_metrics, **kwargs),
                name="search_regulatory_metrics",
                description="在指定系统和汇总表中检索受控指标目录，不读取业务数据。",
                args_schema=SearchCatalogInput,
            ),
            StructuredTool.from_function(
                lambda **kwargs: safe_call(service.search_fields, **kwargs),
                name="search_regulatory_fields",
                description="在指定系统和明细表中检索可用字段目录，不读取业务数据。",
                args_schema=SearchCatalogInput,
            ),
            StructuredTool.from_function(
                lambda **kwargs: safe_call(
                    service.query_summary,
                    **{**kwargs, "filters": filters(kwargs["filters"])}
                ),
                name="query_regulatory_summary",
                description="按受控系统、汇总表、指标、日期、机构和筛选条件查询汇总数据。",
                args_schema=QuerySummaryInput,
            ),
            StructuredTool.from_function(
                lambda **kwargs: safe_call(
                    service.query_detail,
                    **{**kwargs, "filters": filters(kwargs["filters"])}
                ),
                name="query_regulatory_detail",
                description=(
                    "按受控系统、明细表、返回字段、日期、机构和筛选条件查询表级明细数据，"
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
    if output.get("ok") is False:
        return f"监管数据查询失败：{output.get('error') or '工具执行失败'}"
    if "systems" in output:
        return f"监管目录检索完成，共 {output.get('system_count', 0)} 个系统"
    if "dates" in output:
        return f"监管日期检索完成，共 {output.get('returned_count', 0)} 个日期"
    if "candidates" in output:
        return f"指标候选检索完成，共 {output.get('candidate_count', 0)} 条候选"
    if "fields" in output:
        return f"明细字段检索完成，共 {output.get('field_count', 0)} 个字段"
    suffix = "，结果已截断" if output.get("truncated") else ""
    returned_count = output.get("returned_count", 0)
    return f"监管{output.get('view', '数据')}查询完成，返回 {returned_count} 条{suffix}"
