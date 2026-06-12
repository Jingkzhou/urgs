import json
from typing import Any, Literal, cast

import httpx
from mcp import ClientSession, StdioServerParameters
from mcp.client.stdio import stdio_client
from mcp.client.streamable_http import streamablehttp_client
from pydantic import BaseModel, Field

from urgs_agent.plugins.contracts import Retriever, ToolContext, ToolPlugin


class RagSearchArgs(BaseModel):
    query: str
    knowledge_bases: list[str] = Field(default_factory=list)


class RagSearchTool(ToolPlugin):
    name = "rag_search"
    description = "Search URGS knowledge bases and return cited passages."
    args_schema = RagSearchArgs
    required_permissions = frozenset({"knowledge:read"})

    def __init__(self, retriever: Retriever) -> None:
        self.retriever = retriever

    async def execute(self, arguments: dict[str, Any], context: ToolContext) -> dict[str, Any]:
        args = self.args_schema.model_validate(arguments)
        return {"results": await self.retriever.search(args.query, args.knowledge_bases, context)}


class LineageArgs(BaseModel):
    sql: str
    dialect: str = "hive"


class LineageAnalysisTool(ToolPlugin):
    name = "lineage_analyze"
    description = "Analyze SQL and return table and column lineage."
    args_schema = LineageArgs
    required_permissions = frozenset({"lineage:analyze"})

    def __init__(self, base_url: str, timeout: float = 60) -> None:
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout

    async def execute(self, arguments: dict[str, Any], context: ToolContext) -> dict[str, Any]:
        args = self.args_schema.model_validate(arguments)
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"{self.base_url}/api/lineage/parse",
                json=args.model_dump(),
                headers={"X-Trace-Id": context.trace_id},
            )
            response.raise_for_status()
            return cast(dict[str, Any], response.json())


class UrgsApiArgs(BaseModel):
    method: Literal["GET", "POST"] = "GET"
    path: str = Field(pattern=r"^/api/")
    query: dict[str, str] = Field(default_factory=dict)
    body: dict[str, Any] = Field(default_factory=dict)


class UrgsApiTool(ToolPlugin):
    name = "urgs_api"
    description = "Call an allowlisted URGS business API endpoint."
    args_schema = UrgsApiArgs
    required_permissions = frozenset({"urgs:api:call"})

    def __init__(self, base_url: str, allowed_paths: set[str], timeout: float = 60) -> None:
        self.base_url = base_url.rstrip("/")
        self.allowed_paths = allowed_paths
        self.timeout = timeout

    async def execute(self, arguments: dict[str, Any], context: ToolContext) -> dict[str, Any]:
        args = self.args_schema.model_validate(arguments)
        if args.path not in self.allowed_paths:
            raise PermissionError(f"URGS API path is not allowlisted: {args.path}")
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.request(
                args.method,
                f"{self.base_url}{args.path}",
                params=args.query,
                json=args.body if args.method == "POST" else None,
                headers={"X-Trace-Id": context.trace_id},
            )
            response.raise_for_status()
            return cast(dict[str, Any], response.json())


class McpArgs(BaseModel):
    server: str
    tool: str
    arguments: dict[str, Any] = Field(default_factory=dict)


class McpTool(ToolPlugin):
    name = "mcp_call"
    description = "Call a tool exposed by a trusted MCP server."
    args_schema = McpArgs
    required_permissions = frozenset({"mcp:call"})

    def __init__(
        self,
        http_servers: dict[str, str] | None = None,
        stdio_servers: dict[str, list[str]] | None = None,
    ) -> None:
        self.http_servers = http_servers or {}
        self.stdio_servers = stdio_servers or {}

    async def execute(self, arguments: dict[str, Any], context: ToolContext) -> dict[str, Any]:
        args = self.args_schema.model_validate(arguments)
        if args.server in self.http_servers:
            async with streamablehttp_client(self.http_servers[args.server]) as streams:
                read, write, _ = streams
                async with ClientSession(read, write) as session:
                    await session.initialize()
                    result = await session.call_tool(args.tool, args.arguments)
        elif args.server in self.stdio_servers:
            command = self.stdio_servers[args.server]
            params = StdioServerParameters(command=command[0], args=command[1:])
            async with stdio_client(params) as streams:
                async with ClientSession(*streams) as session:
                    await session.initialize()
                    result = await session.call_tool(args.tool, args.arguments)
        else:
            raise PermissionError(f"MCP server is not trusted: {args.server}")
        return {"content": [item.model_dump(mode="json") for item in result.content]}


class ToolRegistry:
    def __init__(self) -> None:
        self._tools: dict[str, ToolPlugin] = {}

    def register(self, tool: ToolPlugin) -> None:
        if tool.name in self._tools:
            raise ValueError(f"tool already registered: {tool.name}")
        self._tools[tool.name] = tool

    def validate_names(self, names: list[str]) -> None:
        missing = sorted(set(names) - self._tools.keys())
        if missing:
            raise ValueError(f"unknown tools: {', '.join(missing)}")

    def schemas(self, names: list[str]) -> list[dict[str, Any]]:
        self.validate_names(names)
        return [self._tools[name].openai_schema() for name in names]

    async def system_context(self, names: list[str], context: ToolContext) -> str:
        self.validate_names(names)
        sections: list[str] = []
        seen: set[str] = set()
        for name in names:
            if name in seen:
                continue
            seen.add(name)
            section = await self._tools[name].system_context(context)
            if section:
                sections.append(section)
        return "\n\n".join(sections)

    async def execute(
        self,
        name: str,
        arguments: dict[str, Any],
        context: ToolContext,
        call_id: str | None = None,
    ) -> dict[str, Any]:
        tool = self._tools.get(name)
        if tool is None:
            raise ValueError(f"unknown tool: {name}")
        missing = tool.required_permissions - context.permissions
        if missing:
            raise PermissionError(f"missing permissions for {name}: {', '.join(sorted(missing))}")
        if context.event_sink:
            await context.event_sink(
                "tool.started",
                {"tool": name, "arguments": arguments, "tool_call_id": call_id},
                name,
            )
        result = await tool.execute(arguments, context)
        if context.event_sink:
            await context.event_sink(
                "tool.completed",
                {"tool": name, "result": result, "tool_call_id": call_id},
                name,
            )
        return result

    @staticmethod
    def serialize_result(result: dict[str, Any]) -> str:
        return json.dumps(result, ensure_ascii=False, default=str)
