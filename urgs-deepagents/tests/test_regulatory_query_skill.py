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
                        "indicators": [
                            {
                                "code": "loan_balance",
                                "name": "各项贷款余额",
                                "column": "loan_balance",
                                "type": "number",
                            },
                            {
                                "code": "npl_balance",
                                "name": "不良贷款余额",
                                "column": "npl_balance",
                                "type": "number",
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
        if "COUNT(*)" in sql:
            return _FakeResult([{"total_count": 7}])
        if "`reg_summary`" in sql:
            return _FakeResult(
                [{"stat_date": "2026-01-31", "org_code": "1100", "loan_balance": 12.5}]
            )
        return _FakeResult(
            [
                {
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


def _runtime(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> tuple[Any, _FakeEngine]:
    skill = load_regulatory_query_skill(_write_skill(tmp_path))
    monkeypatch.setenv(
        "DEEPAGENTS_REGULATORY_QUERY_DATABASE_URL", "mysql+pymysql://user:pass@db/test"
    )
    engine = _FakeEngine()
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
    with pytest.raises(ValueError, match="明细返回字段未在 Skill"):
        tool.invoke({**base, "return_fields": ["not_exists"]})
    with pytest.raises(ValueError, match="筛选字段未在 Skill"):
        tool.invoke({**base, "filters": [{"field": "mobile", "operator": "eq", "value": "x"}]})
    with pytest.raises(ValueError, match="排序字段"):
        tool.invoke({**base, "sort_field": "customer_name"})


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
