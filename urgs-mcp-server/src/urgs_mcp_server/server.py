from __future__ import annotations

import re
from typing import Any, Protocol

from mcp.server.mcpserver import MCPServer

SYSTEM_CODE_PATTERN = re.compile(r"^[A-Za-z0-9_.-]{1,64}$")


class RegulatoryAssetClient(Protocol):
    async def search_regulatory_assets(
        self,
        keyword: str,
        system_code: str | None,
        limit: int,
    ) -> dict[str, Any]: ...


def create_server(client: RegulatoryAssetClient) -> MCPServer:
    server = MCPServer(
        "urgs-regulatory",
        instructions=(
            "查询 URGS 监管资产时先搜索候选表，再根据证据继续缩小范围。"
            "当前服务只提供只读查询能力。"
        ),
    )

    @server.tool(
        name="search_regulatory_assets",
        description="按关键词查询当前 URGS 用户有权访问的监管表。",
        structured_output=True,
    )
    async def search_regulatory_assets(
        keyword: str,
        system_code: str | None = None,
        limit: int = 10,
    ) -> dict[str, Any]:
        normalized_keyword = keyword.strip()
        if not normalized_keyword:
            raise ValueError("keyword 不能为空")
        if len(normalized_keyword) > 100:
            raise ValueError("keyword 长度不能超过 100")
        normalized_system_code = system_code.strip() if system_code else None
        if normalized_system_code and not SYSTEM_CODE_PATTERN.fullmatch(normalized_system_code):
            raise ValueError("system_code 格式不正确")
        if limit < 1 or limit > 20:
            raise ValueError("limit 必须在 1 到 20 之间")
        return await client.search_regulatory_assets(
            keyword=normalized_keyword,
            system_code=normalized_system_code,
            limit=limit,
        )

    return server
