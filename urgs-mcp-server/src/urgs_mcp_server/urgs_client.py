from __future__ import annotations

from typing import Any
from uuid import uuid4

import httpx

from urgs_mcp_server.config import Settings


class UrgsApiError(RuntimeError):
    """Safe error raised when the upstream URGS API call fails."""


class UrgsApiClient:
    def __init__(
        self,
        settings: Settings,
        transport: httpx.AsyncBaseTransport | None = None,
    ) -> None:
        self._settings = settings
        self._transport = transport

    async def search_regulatory_assets(
        self,
        keyword: str,
        system_code: str | None,
        limit: int,
    ) -> dict[str, Any]:
        trace_id = str(uuid4())
        params: dict[str, str | int] = {
            "keyword": keyword,
            "limit": limit,
        }
        if system_code:
            params["systemCode"] = system_code

        async with httpx.AsyncClient(
            base_url=self._settings.api_base_url,
            timeout=self._settings.request_timeout_seconds,
            transport=self._transport,
        ) as client:
            try:
                response = await client.get(
                    "/api/agent/v1/regulatory/assets/search",
                    params=params,
                    headers={
                        "Authorization": f"Bearer {self._settings.access_token}",
                        "X-Trace-Id": trace_id,
                    },
                )
            except httpx.RequestError as error:
                raise UrgsApiError("无法连接 URGS 监管资产服务") from error

        if response.status_code == 401:
            raise UrgsApiError("URGS 登录凭证无效或已过期")
        if response.status_code == 403:
            raise UrgsApiError("当前用户无权查询指定监管资产")
        if response.is_error:
            raise UrgsApiError(f"URGS 监管资产服务调用失败，状态码 {response.status_code}")

        try:
            payload = response.json()
        except ValueError as error:
            raise UrgsApiError("URGS 监管资产服务返回了无效 JSON") from error
        if not isinstance(payload, dict):
            raise UrgsApiError("URGS 监管资产服务返回结构不正确")
        return payload
