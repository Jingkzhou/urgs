from __future__ import annotations

import pytest

from urgs_mcp_server.config import Settings


def test_loads_loopback_settings(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("URGS_API_BASE_URL", "http://127.0.0.1:8080/")
    monkeypatch.setenv("URGS_ACCESS_TOKEN", "user-token")
    monkeypatch.setenv("URGS_MCP_PORT", "8011")

    settings = Settings.from_env()

    assert settings.api_base_url == "http://127.0.0.1:8080"
    assert settings.access_token == "user-token"
    assert settings.port == 8011


def test_rejects_unauthenticated_remote_bind(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("URGS_API_BASE_URL", "https://urgs.example.intra")
    monkeypatch.setenv("URGS_ACCESS_TOKEN", "user-token")
    monkeypatch.setenv("URGS_MCP_HOST", "0.0.0.0")

    with pytest.raises(ValueError, match="只允许监听本机回环地址"):
        Settings.from_env()
