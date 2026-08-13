from __future__ import annotations

import os
from dataclasses import dataclass
from urllib.parse import urlparse


@dataclass(frozen=True)
class Settings:
    api_base_url: str
    access_token: str
    host: str = "127.0.0.1"
    port: int = 8010
    request_timeout_seconds: float = 20.0

    @classmethod
    def from_env(cls) -> Settings:
        api_base_url = _required_env("URGS_API_BASE_URL").rstrip("/")
        access_token = _required_env("URGS_ACCESS_TOKEN")
        host = os.getenv("URGS_MCP_HOST", "127.0.0.1").strip()
        port = _integer_env("URGS_MCP_PORT", 8010)
        timeout = _float_env("URGS_MCP_REQUEST_TIMEOUT_SECONDS", 20.0)

        parsed_url = urlparse(api_base_url)
        if parsed_url.scheme not in {"http", "https"} or not parsed_url.netloc:
            raise ValueError("URGS_API_BASE_URL 必须是有效的 HTTP 或 HTTPS 地址")
        if host not in {"127.0.0.1", "localhost", "::1"}:
            raise ValueError("当前版本尚未启用远程 Bearer 鉴权，只允许监听本机回环地址")
        if not 1 <= port <= 65535:
            raise ValueError("URGS_MCP_PORT 必须在 1 到 65535 之间")
        if timeout <= 0 or timeout > 300:
            raise ValueError("URGS_MCP_REQUEST_TIMEOUT_SECONDS 必须在 0 到 300 之间")

        return cls(
            api_base_url=api_base_url,
            access_token=access_token,
            host=host,
            port=port,
            request_timeout_seconds=timeout,
        )


def _required_env(name: str) -> str:
    value = os.getenv(name, "").strip()
    if not value:
        raise ValueError(f"必须配置 {name}")
    return value


def _integer_env(name: str, default: int) -> int:
    raw_value = os.getenv(name)
    if raw_value is None:
        return default
    try:
        return int(raw_value)
    except ValueError as error:
        raise ValueError(f"{name} 必须是整数") from error


def _float_env(name: str, default: float) -> float:
    raw_value = os.getenv(name)
    if raw_value is None:
        return default
    try:
        return float(raw_value)
    except ValueError as error:
        raise ValueError(f"{name} 必须是数字") from error
