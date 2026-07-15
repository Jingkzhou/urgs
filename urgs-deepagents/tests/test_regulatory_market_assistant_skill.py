from __future__ import annotations

from pathlib import Path
from typing import Any

import httpx
import pytest
from pydantic import ValidationError

from urgs_deepagents_service.skill_loader import SkillConfigurationError, load_agent_skill_runtime

SKILL_CODE = "regulatory-market-assistant"
AGENT_CODE = "regulatory-market-assistant-agent"
SKILLS_ROOT = Path(__file__).parents[1] / "skills"


class _Settings:
    skills_root = str(SKILLS_ROOT)


def _context(*, include_permission: bool = True) -> dict[str, Any]:
    return {
        "requester_user_id": 7,
        "permissions": ["ai:regulatory-query:use"] if include_permission else [],
        "allowed_systems": ["1104"],
    }


def test_skill_exposes_only_declared_read_only_market_tools(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("DEEPAGENTS_URGS_API_URL", "http://urgs-api:8080")
    monkeypatch.setenv("DEEPAGENTS_INTERNAL_API_TOKEN", "internal-token")

    runtime = load_agent_skill_runtime(
        _Settings(), AGENT_CODE, [SKILL_CODE], _context()
    )

    assert runtime is not None
    assert runtime.tool_names == {
        "scan_regulatory_catalog",
        "search_regulatory_assets",
        "get_regulatory_table",
        "get_regulatory_element",
        "get_regulatory_code_values",
        "get_regulatory_relationships",
        "build_indicator_context",
        "validate_generated_sql",
    }
    assert "不执行 SQL" in runtime.instructions
    assert "不写回监管资产" in runtime.instructions


def test_catalog_scan_carries_dynamic_plan_and_access_scope(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("DEEPAGENTS_URGS_API_URL", "http://urgs-api:8080")
    monkeypatch.setenv("DEEPAGENTS_INTERNAL_API_TOKEN", "internal-token")
    captured: dict[str, Any] = {}

    def fake_request(method: str, url: str, **kwargs: Any) -> httpx.Response:
        captured.update(method=method, url=url, **kwargs)
        return httpx.Response(
            200,
            json={"scannedTableCount": 858, "candidates": []},
            request=httpx.Request(method, url),
        )

    monkeypatch.setattr(httpx, "request", fake_request)
    runtime = load_agent_skill_runtime(_Settings(), AGENT_CODE, [SKILL_CODE], _context())
    assert runtime is not None
    tool = next(item for item in runtime.tools if item.name == "scan_regulatory_catalog")

    result = tool.invoke(
        {
            "mode": "sql_development",
            "requirement": "用 L_ACCT_LOAN 查询贷款借据",
            "keywords": ["贷款借据"],
            "exact_identifiers": ["L_ACCT_LOAN"],
            "system_codes": [],
            "evidence_needs": ["来源表", "日期字段", "贷款状态码值"],
            "limit": 10,
        }
    )

    assert result["ok"] is True
    assert captured["url"].endswith("/api/internal/regulatory-market/catalog-scan")
    assert captured["json"]["exactIdentifiers"] == ["L_ACCT_LOAN"]
    assert captured["json"]["allowedSystems"] == "1104"


def test_search_tool_forwards_server_side_access_scope(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("DEEPAGENTS_URGS_API_URL", "http://urgs-api:8080")
    monkeypatch.setenv("DEEPAGENTS_INTERNAL_API_TOKEN", "internal-token")
    captured: dict[str, Any] = {}

    def fake_request(method: str, url: str, **kwargs: Any) -> httpx.Response:
        captured.update(method=method, url=url, **kwargs)
        return httpx.Response(
            200,
            json={"keyword": "贷款", "items": [], "truncated": False},
            request=httpx.Request(method, url),
        )

    monkeypatch.setattr(httpx, "request", fake_request)
    runtime = load_agent_skill_runtime(
        _Settings(), AGENT_CODE, [SKILL_CODE], _context()
    )
    assert runtime is not None
    tool = next(item for item in runtime.tools if item.name == "search_regulatory_assets")

    result = tool.invoke({"keyword": "贷款", "system_code": "1104", "limit": 10})

    assert result["ok"] is True
    assert captured["url"].endswith("/api/internal/regulatory-market/search")
    assert captured["params"]["allowedSystems"] == "1104"
    assert captured["params"]["systemCode"] == "1104"
    assert captured["headers"] == {"Authorization": "Bearer internal-token"}


def test_skill_rejects_requests_without_permission(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("DEEPAGENTS_URGS_API_URL", "http://urgs-api:8080")
    monkeypatch.setenv("DEEPAGENTS_INTERNAL_API_TOKEN", "internal-token")

    with pytest.raises(SkillConfigurationError, match="缺少监管指标查询权限"):
        load_agent_skill_runtime(
            _Settings(), AGENT_CODE, [SKILL_CODE], _context(include_permission=False)
        )


def test_code_value_tool_rejects_path_traversal(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("DEEPAGENTS_URGS_API_URL", "http://urgs-api:8080")
    monkeypatch.setenv("DEEPAGENTS_INTERNAL_API_TOKEN", "internal-token")
    runtime = load_agent_skill_runtime(
        _Settings(), AGENT_CODE, [SKILL_CODE], _context()
    )
    assert runtime is not None
    tool = next(item for item in runtime.tools if item.name == "get_regulatory_code_values")

    with pytest.raises(ValidationError):
        tool.invoke({"table_code": "../../ai/config/default?x=", "limit": 10})


def test_sql_validation_forwards_camel_case_code_checks(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("DEEPAGENTS_URGS_API_URL", "http://urgs-api:8080")
    monkeypatch.setenv("DEEPAGENTS_INTERNAL_API_TOKEN", "internal-token")
    captured: dict[str, Any] = {}

    def fake_request(method: str, url: str, **kwargs: Any) -> httpx.Response:
        captured.update(method=method, url=url, **kwargs)
        return httpx.Response(
            200,
            json={"valid": True, "errors": [], "warnings": []},
            request=httpx.Request(method, url),
        )

    monkeypatch.setattr(httpx, "request", fake_request)
    runtime = load_agent_skill_runtime(_Settings(), AGENT_CODE, [SKILL_CODE], _context())
    assert runtime is not None
    tool = next(item for item in runtime.tools if item.name == "validate_generated_sql")

    result = tool.invoke(
        {
            "sql": "SELECT * FROM CORE.DEMO WHERE FLAG = 'Y'",
            "code_checks": [{"table_code": "BOOL_CODE", "code": "Y"}],
        }
    )

    assert result["ok"] is True
    assert captured["json"]["codeChecks"] == [{"tableCode": "BOOL_CODE", "code": "Y"}]


def test_table_tool_removes_unverified_historical_code(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    monkeypatch.setenv("DEEPAGENTS_URGS_API_URL", "http://urgs-api:8080")
    monkeypatch.setenv("DEEPAGENTS_INTERNAL_API_TOKEN", "internal-token")

    def fake_request(method: str, url: str, **kwargs: Any) -> httpx.Response:
        return httpx.Response(
            200,
            json={
                "id": "1",
                "name": "G01",
                "elements": [{"id": "2", "name": "TOTAL", "codeSnippet": "SELECT secret"}],
            },
            request=httpx.Request(method, url),
        )

    monkeypatch.setattr(httpx, "request", fake_request)
    runtime = load_agent_skill_runtime(_Settings(), AGENT_CODE, [SKILL_CODE], _context())
    assert runtime is not None
    tool = next(item for item in runtime.tools if item.name == "get_regulatory_table")

    result = tool.invoke({"table_id": 1, "element_limit": 20})

    assert result["ok"] is True
    assert "codeSnippet" not in result["elements"][0]
