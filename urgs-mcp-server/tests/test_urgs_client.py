from __future__ import annotations

import httpx
import pytest

from urgs_mcp_server.config import Settings
from urgs_mcp_server.urgs_client import UrgsApiClient, UrgsApiError


@pytest.mark.asyncio
async def test_search_forwards_user_token_and_trace_id() -> None:
    def handler(request: httpx.Request) -> httpx.Response:
        assert request.url.path == "/api/agent/v1/regulatory/assets/search"
        assert request.url.params["keyword"] == "贷款"
        assert request.url.params["systemCode"] == "EAST5"
        assert request.headers["Authorization"] == "Bearer user-token"
        assert request.headers["X-Trace-Id"]
        return httpx.Response(200, json={"items": [], "count": 0, "traceId": "trace-1"})

    client = UrgsApiClient(
        Settings("http://urgs.test", "user-token"),
        transport=httpx.MockTransport(handler),
    )

    result = await client.search_regulatory_assets("贷款", "EAST5", 10)

    assert result["count"] == 0


@pytest.mark.asyncio
async def test_search_hides_upstream_forbidden_response_body() -> None:
    client = UrgsApiClient(
        Settings("http://urgs.test", "user-token"),
        transport=httpx.MockTransport(
            lambda request: httpx.Response(403, text="sensitive internal details")
        ),
    )

    with pytest.raises(UrgsApiError, match="无权查询") as error:
        await client.search_regulatory_assets("贷款", "SMTMODS", 10)

    assert "sensitive internal details" not in str(error.value)
