from __future__ import annotations

from typing import Any

import pytest

from urgs_mcp_server.server import create_server


class FakeUrgsApiClient:
    def __init__(self) -> None:
        self.arguments: tuple[str, str | None, int] | None = None

    async def search_regulatory_assets(
        self,
        keyword: str,
        system_code: str | None,
        limit: int,
    ) -> dict[str, Any]:
        self.arguments = (keyword, system_code, limit)
        return {"items": [], "count": 0, "traceId": "trace-1"}


@pytest.mark.asyncio
async def test_exposes_and_invokes_regulatory_search_tool() -> None:
    client = FakeUrgsApiClient()
    server = create_server(client)

    tools = await server.list_tools()
    result = await server.call_tool(
        "search_regulatory_assets",
        {"keyword": " 贷款 ", "system_code": "EAST5", "limit": 5},
    )

    assert [tool.name for tool in tools] == ["search_regulatory_assets"]
    assert client.arguments == ("贷款", "EAST5", 5)
    assert result.is_error is not True


@pytest.mark.asyncio
async def test_rejects_invalid_system_code_before_calling_urgs() -> None:
    client = FakeUrgsApiClient()
    server = create_server(client)

    result = await server.call_tool(
        "search_regulatory_assets",
        {"keyword": "贷款", "system_code": "../EAST5", "limit": 5},
    )

    assert result.is_error is True
    assert client.arguments is None
