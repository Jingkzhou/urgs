from __future__ import annotations

import importlib.util
import json
import re
import sys
from pathlib import Path
from shutil import copyfile
from typing import Any

import pytest

from urgs_deepagents_service.runtime import create_runtime_agent
from urgs_deepagents_service.skill_loader import SkillConfigurationError, load_agent_skill_runtime

REGULATORY_DATA_QUERY_AGENT_CODE = "regulatory-data-query-agent"
REGULATORY_DATA_QUERY_SKILL_CODE = "regulatory-data-query"
_RUNTIME_PATH = (
    Path(__file__).parents[1] / "skills" / REGULATORY_DATA_QUERY_SKILL_CODE / "runtime.py"
)
_SPEC = importlib.util.spec_from_file_location("test_regulatory_query_runtime", _RUNTIME_PATH)
assert _SPEC is not None and _SPEC.loader is not None
_MODULE = importlib.util.module_from_spec(_SPEC)
sys.modules[_SPEC.name] = _MODULE
_SPEC.loader.exec_module(_MODULE)
create_regulatory_query_skill_runtime = _MODULE.create_regulatory_query_skill_runtime
load_regulatory_query_skill = _MODULE.load_regulatory_query_skill

TOOLS = [
    "browse_regulatory_catalog",
    "list_regulatory_periods",
    "search_regulatory_metrics",
    "search_regulatory_fields",
    "query_regulatory_summary",
    "query_regulatory_detail",
]


def _manifest(*, enabled: bool = True) -> dict[str, Any]:
    return {
        "skill_code": REGULATORY_DATA_QUERY_SKILL_CODE,
        "version": 2,
        "enabled": enabled,
        "agent_code": REGULATORY_DATA_QUERY_AGENT_CODE,
        "runtime_entrypoint": "runtime.py",
        "tools": TOOLS,
        "database": {"dialect": "mysql", "url_env": "DEEPAGENTS_REGULATORY_QUERY_DATABASE_URL"},
        "catalog_limit": 20,
    }


def _catalog(*, detail_max_rows: int = 5) -> dict[str, Any]:
    return {
        "skill_code": REGULATORY_DATA_QUERY_SKILL_CODE,
        "version": 1,
        "systems": [
            {
                "code": "credit",
                "name": "信贷监管系统",
                "summary_tables": [
                    {
                        "code": "loan_summary",
                        "name": "贷款指标汇总表",
                        "table": "reg_summary",
                        "date_column": "stat_date",
                        "organization_column": "org_code",
                        "organization_name_column": "org_name",
                        "metric_code_column": "metric_code",
                        "indicators": [
                            {
                                "code": "loan_balance",
                                "name": "各项贷款余额",
                                "type": "number",
                            },
                            {
                                "code": "npl_balance",
                                "name": "不良贷款余额",
                                "type": "number",
                            },
                        ],
                        "result_fields": [
                            {
                                "code": "data_date",
                                "name": "数据日期",
                                "column": "stat_date",
                                "type": "date",
                                "returnable": True,
                                "filterable": False,
                                "sortable": False,
                            },
                            {
                                "code": "metric_code",
                                "name": "指标编号",
                                "column": "metric_code",
                                "type": "string",
                                "returnable": True,
                                "filterable": False,
                                "sortable": False,
                            },
                            {
                                "code": "metric_value",
                                "name": "指标值",
                                "column": "metric_value",
                                "type": "number",
                                "returnable": True,
                                "filterable": False,
                                "sortable": False,
                            },
                        ],
                        "filters": [
                            {
                                "code": "product_type",
                                "name": "产品类型",
                                "column": "product_type",
                                "type": "string",
                                "filterable": True,
                                "returnable": False,
                                "sortable": False,
                                "operators": ["eq", "in"],
                            }
                        ],
                        "max_rows": 100,
                        "order_by": [],
                    }
                ],
                "detail_tables": [
                    {
                        "code": "loan_detail",
                        "name": "贷款明细表",
                        "table": "reg_detail",
                        "date_column": "stat_date",
                        "organization_column": "org_code",
                        "organization_name_column": "org_name",
                        "default_return_fields": ["contract_no", "customer_name", "loan_balance"],
                        "fields": [
                            {
                                "code": "contract_no",
                                "name": "合同号",
                                "column": "contract_no",
                                "type": "string",
                                "returnable": True,
                                "filterable": True,
                                "sortable": True,
                                "operators": ["eq", "like"],
                                "mask": "ACCOUNT",
                            },
                            {
                                "code": "customer_name",
                                "name": "客户名称",
                                "column": "customer_name",
                                "type": "string",
                                "returnable": True,
                                "filterable": True,
                                "sortable": False,
                                "operators": ["eq", "like"],
                                "mask": "NAME",
                            },
                            {
                                "code": "loan_balance",
                                "name": "贷款余额",
                                "column": "loan_balance",
                                "type": "number",
                                "returnable": True,
                                "filterable": True,
                                "sortable": True,
                                "operators": ["eq", "in"],
                            },
                            {
                                "code": "mobile",
                                "name": "手机号",
                                "column": "mobile",
                                "type": "string",
                                "returnable": True,
                                "filterable": False,
                                "sortable": False,
                                "mask": "MOBILE",
                            },
                        ],
                        "order_by": [{"field": "contract_no", "direction": "asc"}],
                        "max_rows": detail_max_rows,
                    }
                ],
            }
        ],
    }


def _write_skill(
    tmp_path: Path, manifest: dict[str, Any] | None = None, catalog: dict[str, Any] | None = None
) -> Path:
    skill_dir = tmp_path / REGULATORY_DATA_QUERY_SKILL_CODE
    skill_dir.mkdir(parents=True)
    (skill_dir / "SKILL.md").write_text("# 监管查询\n\n使用受控工具查询。\n", encoding="utf-8")
    (skill_dir / "skill.json").write_text(
        json.dumps(manifest or _manifest(), ensure_ascii=False), encoding="utf-8"
    )
    (skill_dir / "catalog.json").write_text(
        json.dumps(catalog or _catalog(), ensure_ascii=False), encoding="utf-8"
    )
    copyfile(
        Path(__file__).parents[1] / "skills" / REGULATORY_DATA_QUERY_SKILL_CODE / "runtime.py",
        skill_dir / "runtime.py",
    )
    return skill_dir


class _FakeResult:
    def __init__(self, rows: list[dict[str, Any]]) -> None:
        self.rows = rows

    def mappings(self) -> _FakeResult:
        return self

    def one(self) -> dict[str, Any]:
        return self.rows[0]

    def all(self) -> list[dict[str, Any]]:
        return self.rows


class _FakeConnection:
    def __init__(self, calls: list[tuple[str, dict[str, Any]]]) -> None:
        self.calls = calls

    def __enter__(self) -> _FakeConnection:
        return self

    def __exit__(self, *args: object) -> None:
        return None

    def execute(self, statement: Any, parameters: dict[str, Any]) -> _FakeResult:
        sql = str(statement)
        self.calls.append((sql, parameters))
        if "reg_element_query_config" in sql:
            return _FakeResult([])
        if "reg_table_query_config" in sql:
            return _FakeResult([])
        if "FROM model_field" in sql:
            return _FakeResult([])
        if "COUNT(DISTINCT" in sql:
            return _FakeResult([{"total_count": 2}])
        if "SELECT DISTINCT" in sql:
            return _FakeResult([{"data_date": "2026-02-28"}, {"data_date": "2026-01-31"}])
        if "COUNT(*)" in sql:
            return _FakeResult([{"total_count": 7}])
        if "`reg_summary`" in sql:
            return _FakeResult(
                [
                    {
                        "data_date": "2026-01-31",
                        "org_name": "总行",
                        "org_code": "1100",
                        "metric_code": "loan_balance",
                        "metric_value": 12.5,
                    }
                ]
            )
        return _FakeResult(
            [
                {
                    "stat_date": "2026-01-31",
                    "org_name": "总行",
                    "org_code": "1100",
                    "contract_no": "HT20260001",
                    "customer_name": "张三",
                    "loan_balance": 12.5,
                    "mobile": "13800138000",
                }
            ]
        )


class _FakeEngine:
    def __init__(self) -> None:
        self.calls: list[tuple[str, dict[str, Any]]] = []

    def connect(self) -> _FakeConnection:
        return _FakeConnection(self.calls)


class _AssetFakeConnection(_FakeConnection):
    def execute(self, statement: Any, parameters: dict[str, Any]) -> _FakeResult:
        sql = str(statement)
        self.calls.append((sql, parameters))
        if "reg_element_query_config" in sql:
            return _FakeResult(
                [
                    {
                        "config_id": 1,
                        "reg_element_id": 101,
                        "query_mode": "SUMMARY",
                        "model_table_id": "mt_loan",
                        "date_field_id": "f_date",
                        "org_code_field_id": "f_org",
                        "org_name_field_id": "f_org_name",
                        "metric_code_field_id": "f_metric",
                        "value_field_id": "f_value",
                        "default_return_field_ids": json.dumps(
                            ["f_date", "f_org", "f_org_name", "f_value"]
                        ),
                        "filter_field_ids": json.dumps(["f_status"]),
                        "sort_field_ids": json.dumps(["f_date"]),
                        "mask_field_ids": "[]",
                        "detail_max_rows": 5,
                        "element_code": "loan_balance_asset",
                        "element_name": "各项贷款余额",
                        "element_description": "资产配置指标",
                        "reg_table_id": 10,
                        "reg_table_code": "loan_asset",
                        "reg_table_name": "资产贷款指标表",
                        "system_code": "credit_asset",
                        "physical_table": "asset_summary",
                        "physical_owner": "",
                    }
                ]
            )
        if "reg_table_query_config" in sql:
            return _FakeResult([])
        if "FROM model_field" in sql:
            return _FakeResult(
                [
                    {
                        "id": "f_date",
                        "table_id": "mt_loan",
                        "name": "data_date",
                        "cn_name": "数据日期",
                        "type": "date",
                    },
                    {
                        "id": "f_org",
                        "table_id": "mt_loan",
                        "name": "org_code",
                        "cn_name": "机构编号",
                        "type": "varchar",
                    },
                    {
                        "id": "f_org_name",
                        "table_id": "mt_loan",
                        "name": "org_name",
                        "cn_name": "机构名称",
                        "type": "varchar",
                    },
                    {
                        "id": "f_metric",
                        "table_id": "mt_loan",
                        "name": "metric_code",
                        "cn_name": "指标编号",
                        "type": "varchar",
                    },
                    {
                        "id": "f_value",
                        "table_id": "mt_loan",
                        "name": "metric_value",
                        "cn_name": "指标值",
                        "type": "decimal",
                    },
                    {
                        "id": "f_status",
                        "table_id": "mt_loan",
                        "name": "record_status",
                        "cn_name": "记录状态",
                        "type": "varchar",
                    },
                ]
            )
        if "`asset_summary`" in sql:
            return _FakeResult(
                [
                    {
                        "data_date": "2026-02-28",
                        "org_code": "1200",
                        "org_name": "分行一",
                        "metric_value": 760000,
                    }
                ]
            )
        return super().execute(statement, parameters)


class _AssetFakeEngine(_FakeEngine):
    def connect(self) -> _AssetFakeConnection:
        return _AssetFakeConnection(self.calls)


class _TableDetailFakeConnection(_FakeConnection):
    def execute(self, statement: Any, parameters: dict[str, Any]) -> _FakeResult:
        sql = str(statement)
        self.calls.append((sql, parameters))
        if "reg_element_query_config" in sql:
            return _FakeResult([])
        if "reg_table_query_config" in sql:
            return _FakeResult(
                [
                    {
                        "config_id": 2,
                        "reg_table_id": 20,
                        "model_table_id": "mt_detail",
                        "date_field_id": "d_date",
                        "org_code_field_id": "d_org",
                        "org_name_field_id": "d_org_name",
                        "default_return_field_ids": json.dumps(["d_contract", "d_customer"]),
                        "filter_field_ids": json.dumps(["d_status"]),
                        "sort_field_ids": json.dumps(["d_contract"]),
                        "mask_field_ids": json.dumps(["d_customer"]),
                        "detail_max_rows": 5,
                        "reg_table_code": "loan_detail_asset",
                        "reg_table_name": "资产贷款明细表",
                        "system_code": "credit_asset",
                        "physical_table": "asset_detail",
                        "physical_owner": "",
                    }
                ]
            )
        if "FROM model_field" in sql:
            return _FakeResult(
                [
                    {
                        "id": "d_date",
                        "table_id": "mt_detail",
                        "name": "data_date",
                        "cn_name": "数据日期",
                        "type": "date",
                    },
                    {
                        "id": "d_org",
                        "table_id": "mt_detail",
                        "name": "org_code",
                        "cn_name": "机构编号",
                        "type": "varchar",
                    },
                    {
                        "id": "d_org_name",
                        "table_id": "mt_detail",
                        "name": "org_name",
                        "cn_name": "机构名称",
                        "type": "varchar",
                    },
                    {
                        "id": "d_contract",
                        "table_id": "mt_detail",
                        "name": "contract_no",
                        "cn_name": "合同号",
                        "type": "varchar",
                    },
                    {
                        "id": "d_customer",
                        "table_id": "mt_detail",
                        "name": "customer_name",
                        "cn_name": "客户名称",
                        "type": "varchar",
                    },
                    {
                        "id": "d_status",
                        "table_id": "mt_detail",
                        "name": "record_status",
                        "cn_name": "记录状态",
                        "type": "varchar",
                    },
                ]
            )
        if "COUNT(*)" in sql and "`asset_detail`" in sql:
            return _FakeResult([{"total_count": 6}])
        if "`asset_detail`" in sql:
            return _FakeResult(
                [
                    {
                        "contract_no": "HT20260001",
                        "customer_name": "张三",
                    }
                ]
            )
        return super().execute(statement, parameters)


class _TableDetailFakeEngine(_FakeEngine):
    def connect(self) -> _TableDetailFakeConnection:
        return _TableDetailFakeConnection(self.calls)


def _runtime(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> tuple[Any, _FakeEngine]:
    skill = load_regulatory_query_skill(_write_skill(tmp_path))
    monkeypatch.setenv(
        "DEEPAGENTS_REGULATORY_QUERY_DATABASE_URL", "mysql+pymysql://user:pass@db/test"
    )
    engine = _FakeEngine()
    return create_regulatory_query_skill_runtime(
        skill, engine_factory=lambda *_args, **_kwargs: engine
    ), engine


def _runtime_with_engine(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch, engine: _FakeEngine
) -> tuple[Any, _FakeEngine]:
    skill = load_regulatory_query_skill(_write_skill(tmp_path))
    monkeypatch.setenv(
        "DEEPAGENTS_REGULATORY_QUERY_DATABASE_URL", "mysql+pymysql://user:pass@db/test"
    )
    return create_regulatory_query_skill_runtime(
        skill, engine_factory=lambda *_args, **_kwargs: engine
    ), engine


def test_skill_rejects_disabled_missing_catalog_or_invalid_detail_limit(tmp_path: Path) -> None:
    with pytest.raises(SkillConfigurationError, match="尚未启用"):
        load_regulatory_query_skill(_write_skill(tmp_path / "disabled", _manifest(enabled=False)))
    invalid_catalog = _catalog(detail_max_rows=6)
    with pytest.raises(SkillConfigurationError, match="1 到 5"):
        load_regulatory_query_skill(_write_skill(tmp_path / "invalid", catalog=invalid_catalog))
    skill_dir = _write_skill(tmp_path / "missing")
    (skill_dir / "catalog.json").unlink()
    with pytest.raises(SkillConfigurationError, match=re.escape("catalog.json")):
        load_regulatory_query_skill(skill_dir)


def test_catalog_tools_return_logical_system_table_metric_and_field_directory(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    runtime, _ = _runtime(tmp_path, monkeypatch)
    tools = {tool.name: tool for tool in runtime.tools}
    assert tools["browse_regulatory_catalog"].invoke({"view": "summary"})["systems"][0][
        "tables"
    ] == [{"code": "loan_summary", "name": "贷款指标汇总表", "view": "summary"}]
    assert tools["search_regulatory_metrics"].invoke(
        {"system_code": "credit", "table_code": "loan_summary", "keyword": "贷款"}
    )["candidates"] == [
        {"code": "loan_balance", "name": "各项贷款余额", "type": "number"},
        {"code": "npl_balance", "name": "不良贷款余额", "type": "number"},
    ]
    fields = tools["search_regulatory_fields"].invoke(
        {"system_code": "credit", "table_code": "loan_detail", "keyword": "合同"}
    )["fields"]
    assert fields[0]["code"] == "contract_no"
    assert "column" not in fields[0]


def test_catalog_tools_accept_unique_chinese_system_and_table_names(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    runtime, _ = _runtime(tmp_path, monkeypatch)
    tools = {tool.name: tool for tool in runtime.tools}

    catalog = tools["browse_regulatory_catalog"].invoke(
        {"system_code": "信贷监管系统", "view": "summary"}
    )
    metrics = tools["search_regulatory_metrics"].invoke(
        {"system_code": "信贷监管系统", "table_code": "贷款指标汇总表", "keyword": "贷款"}
    )

    assert catalog["systems"][0]["system_code"] == "credit"
    assert metrics["system_code"] == "credit"
    assert metrics["table_code"] == "loan_summary"
    assert metrics["candidate_count"] == 2


def test_period_tool_lists_available_dates_with_normalized_scope(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    runtime, engine = _runtime(tmp_path, monkeypatch)
    tool = next(tool for tool in runtime.tools if tool.name == "list_regulatory_periods")

    result = tool.invoke(
        {
            "system_code": "信贷监管系统",
            "table_code": "贷款指标汇总表",
            "view": "summary",
            "indicator_codes": ["各项贷款余额"],
            "organization": "1200机构",
            "filters": [{"field": "product_type", "operator": "eq", "value": "loan"}],
        }
    )

    assert result["system_code"] == "credit"
    assert result["table_code"] == "loan_summary"
    assert result["organization"] == "1200"
    assert result["dates"] == ["2026-02-28", "2026-01-31"]
    count_sql, count_params = next(
        (sql, params) for sql, params in engine.calls if "COUNT(DISTINCT `stat_date`)" in sql
    )
    assert "COUNT(DISTINCT `stat_date`)" in count_sql
    assert "(`org_code` = :organization OR `org_name` = :organization)" in count_sql
    assert count_params["organization"] == "1200"
    assert count_params["metric_0"] == "loan_balance"


def test_query_tools_use_catalog_columns_parameters_masks_and_hard_detail_limit(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    runtime, engine = _runtime(tmp_path, monkeypatch)
    tools = {tool.name: tool for tool in runtime.tools}
    summary = tools["query_regulatory_summary"].invoke(
        {
            "system_code": "credit",
            "table_code": "loan_summary",
            "indicator_codes": ["loan_balance"],
            "start_date": "2026-01-01",
            "end_date": "2026-01-31",
            "organization": "1100",
            "filters": [{"field": "product_type", "operator": "eq", "value": "loan"}],
        }
    )
    detail = tools["query_regulatory_detail"].invoke(
        {
            "system_code": "credit",
            "table_code": "loan_detail",
            "return_fields": ["contract_no", "customer_name", "mobile"],
            "start_date": "2026-01-01",
            "end_date": "2026-01-31",
            "organization": "1100",
            "filters": [{"field": "contract_no", "operator": "like", "value": "HT"}],
            "sort_field": "contract_no",
            "sort_direction": "desc",
        }
    )
    assert summary["indicators"] == [{"code": "loan_balance", "name": "各项贷款余额"}]
    assert (
        detail["returned_count"] == 1 and detail["total_count"] == 7 and detail["truncated"] is True
    )
    assert detail["rows"][0]["contract_no"] == "******0001"
    assert detail["rows"][0]["customer_name"] == "张*"
    assert detail["rows"][0]["mobile"] == "138****8000"
    assert all("= 'loan'" not in sql for sql, _ in engine.calls)
    detail_calls = [params for sql, params in engine.calls if "`reg_detail`" in sql]
    assert detail_calls[-1]["limit"] == 5
    assert detail_calls[-1]["filter_0"] == "%HT%"


def test_query_tools_accept_compact_dates_org_suffix_and_org_name(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    runtime, engine = _runtime(tmp_path, monkeypatch)
    tool = next(tool for tool in runtime.tools if tool.name == "query_regulatory_summary")

    suffix_result = tool.invoke(
        {
            "system_code": "credit",
            "table_code": "loan_summary",
            "indicator_codes": ["loan_balance"],
            "start_date": "20260228",
            "end_date": "2026/02/28",
            "organization": "1200机构",
        }
    )
    name_result = tool.invoke(
        {
            "system_code": "credit",
            "table_code": "loan_summary",
            "indicator_codes": ["loan_balance"],
            "start_date": "2026年2月28日",
            "end_date": "2026.02.28",
            "organization": "分行一",
        }
    )

    assert suffix_result["start_date"] == "2026-02-28"
    assert suffix_result["end_date"] == "2026-02-28"
    assert suffix_result["organization"] == "1200"
    assert name_result["organization"] == "分行一"
    summary_calls = [(sql, params) for sql, params in engine.calls if "`reg_summary`" in sql]
    suffix_sql, suffix_params = summary_calls[-2]
    _, name_params = summary_calls[-1]
    assert "(`org_code` = :organization OR `org_name` = :organization)" in suffix_sql
    assert suffix_params["start_date"].isoformat() == "2026-02-28"
    assert suffix_params["end_date"].isoformat() == "2026-02-28"
    assert suffix_params["organization"] == "1200"
    assert name_params["organization"] == "分行一"


def test_summary_query_accepts_unique_indicator_name(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    runtime, _ = _runtime(tmp_path, monkeypatch)
    tool = next(tool for tool in runtime.tools if tool.name == "query_regulatory_summary")

    result = tool.invoke(
        {
            "system_code": "credit",
            "table_code": "loan_summary",
            "indicator_codes": ["各项贷款余额"],
            "start_date": "2026-01-01",
            "end_date": "2026-01-31",
            "organization": "1100",
        }
    )

    assert result["indicators"] == [{"code": "loan_balance", "name": "各项贷款余额"}]


def test_summary_query_accepts_unique_chinese_system_table_and_indicator_names(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    runtime, _ = _runtime(tmp_path, monkeypatch)
    tool = next(tool for tool in runtime.tools if tool.name == "query_regulatory_summary")

    result = tool.invoke(
        {
            "system_code": "信贷监管系统",
            "table_code": "贷款指标汇总表",
            "indicator_codes": ["各项贷款余额"],
            "start_date": "2026-01-01",
            "end_date": "2026-01-31",
            "organization": "1100",
        }
    )

    assert result["system_code"] == "credit"
    assert result["table_code"] == "loan_summary"
    assert result["indicators"] == [{"code": "loan_balance", "name": "各项贷款余额"}]


def test_asset_query_config_overrides_catalog_with_parameterized_summary_query(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    runtime, engine = _runtime_with_engine(tmp_path, monkeypatch, _AssetFakeEngine())
    tools = {tool.name: tool for tool in runtime.tools}

    catalog = tools["browse_regulatory_catalog"].invoke({"system_code": "credit_asset"})
    metrics = tools["search_regulatory_metrics"].invoke(
        {"system_code": "credit_asset", "table_code": "loan_asset", "keyword": "各项贷款"}
    )
    result = tools["query_regulatory_summary"].invoke(
        {
            "system_code": "credit_asset",
            "table_code": "loan_asset",
            "indicator_codes": ["各项贷款余额"],
            "start_date": "2026-02-28",
            "end_date": "2026-02-28",
            "organization": "1200",
            "filters": [{"field": "record_status", "operator": "eq", "value": "normal"}],
        }
    )

    assert catalog["systems"][0]["tables"] == [
        {"code": "loan_asset", "name": "资产贷款指标表", "view": "summary"}
    ]
    assert metrics["candidates"] == [
        {"code": "loan_balance_asset", "name": "各项贷款余额", "type": "number"}
    ]
    assert result["rows"][0]["metric_value"] == 760000
    asset_sql, asset_params = next(
        (sql, params) for sql, params in engine.calls if "`asset_summary`" in sql
    )
    assert "`metric_code` = :asset_metric_code" in asset_sql
    assert "`record_status` = :filter_0" in asset_sql
    assert asset_params["asset_metric_code"] == "loan_balance_asset"
    assert asset_params["filter_0"] == "normal"
    assert "'normal'" not in asset_sql


def test_table_level_detail_query_config_does_not_require_detail_indicator(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    runtime, engine = _runtime_with_engine(tmp_path, monkeypatch, _TableDetailFakeEngine())
    tools = {tool.name: tool for tool in runtime.tools}

    fields = tools["search_regulatory_fields"].invoke(
        {"system_code": "credit_asset", "table_code": "loan_detail_asset", "keyword": "客户"}
    )
    result = tools["query_regulatory_detail"].invoke(
        {
            "system_code": "credit_asset",
            "table_code": "loan_detail_asset",
            "return_fields": ["contract_no", "customer_name"],
            "start_date": "2026-02-28",
            "end_date": "2026-02-28",
            "organization": "1200机构",
            "filters": [{"field": "record_status", "operator": "eq", "value": "normal"}],
            "sort_field": "contract_no",
            "sort_direction": "asc",
        }
    )

    assert fields["fields"][0]["code"] == "customer_name"
    assert result["returned_count"] == 1
    assert result["total_count"] == 6
    assert result["truncated"] is True
    assert result["rows"][0]["customer_name"] == "张*"
    detail_sql, detail_params = next(
        (sql, params) for sql, params in engine.calls if "`asset_detail`" in sql and "LIMIT" in sql
    )
    assert "`record_status` = :filter_0" in detail_sql
    assert detail_params["organization"] == "1200"
    assert detail_params["limit"] == 5


def test_query_tools_reject_unknown_return_filter_or_sort_field(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    runtime, _ = _runtime(tmp_path, monkeypatch)
    tool = next(tool for tool in runtime.tools if tool.name == "query_regulatory_detail")
    base = {
        "system_code": "credit",
        "table_code": "loan_detail",
        "start_date": "2026-01-01",
        "end_date": "2026-01-31",
        "organization": "1100",
    }
    unknown_return = tool.invoke({**base, "return_fields": ["not_exists"]})
    assert unknown_return["ok"] is False
    assert "明细返回字段未在 Skill" in unknown_return["error"]

    unknown_filter = tool.invoke(
        {**base, "filters": [{"field": "mobile", "operator": "eq", "value": "x"}]}
    )
    assert unknown_filter["ok"] is False
    assert "筛选字段未在 Skill" in unknown_filter["error"]

    unknown_sort = tool.invoke({**base, "sort_field": "customer_name"})
    assert unknown_sort["ok"] is False
    assert "排序字段" in unknown_sort["error"]


def test_skill_runtime_requires_database_url_environment(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    skill = load_regulatory_query_skill(_write_skill(tmp_path))
    monkeypatch.delenv("DEEPAGENTS_REGULATORY_QUERY_DATABASE_URL", raising=False)
    with pytest.raises(SkillConfigurationError, match="缺少监管查询数据库连接环境变量"):
        create_regulatory_query_skill_runtime(skill)


def test_target_agent_uses_only_declared_skill_tools(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    _write_skill(tmp_path)
    monkeypatch.setenv(
        "DEEPAGENTS_REGULATORY_QUERY_DATABASE_URL", "mysql+pymysql://user:pass@db/test"
    )
    captured: dict[str, Any] = {}

    class _Settings:
        memory_files = ""
        skill_dirs = ""
        workspace_root = None
        skills_root = str(tmp_path)
        enable_write_tools = False

    monkeypatch.setattr(
        "urgs_deepagents_service.runtime.create_deep_agent",
        lambda **kwargs: captured.update(kwargs) or kwargs,
    )
    create_runtime_agent(
        model=object(),
        settings=_Settings(),
        agent_code=REGULATORY_DATA_QUERY_AGENT_CODE,
        system_prompt="base",
        memory_files=None,
        skill_dirs=[REGULATORY_DATA_QUERY_SKILL_CODE],
        tool_allowlist=None,
        allow_write=False,
        workspace_root=None,
        debug=False,
    )
    assert {tool.name for tool in captured["tools"]} == set(TOOLS)
    middleware = captured["middleware"][0]
    assert middleware._filter_tools([{"name": "execute"}, {"name": "read_file"}]) == []


def test_target_agent_rejects_skill_path_traversal(tmp_path: Path) -> None:
    class _Settings:
        skills_root = str(tmp_path)

    with pytest.raises(SkillConfigurationError, match="必须且只能配置"):
        load_agent_skill_runtime(
            _Settings(), REGULATORY_DATA_QUERY_AGENT_CODE, ["../regulatory-data-query"]
        )
