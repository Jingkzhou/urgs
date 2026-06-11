from typing import Any

import pytest
from pydantic import BaseModel

from urgs_agent.plugins.contracts import ToolContext, ToolPlugin
from urgs_agent.plugins.tools import ToolRegistry


class Args(BaseModel):
    value: str


class EchoTool(ToolPlugin):
    name = "echo"
    description = "echo"
    args_schema = Args
    required_permissions = frozenset({"echo:call"})

    async def execute(self, arguments: dict[str, Any], context: ToolContext) -> dict[str, Any]:
        return {"value": self.args_schema.model_validate(arguments).value}


@pytest.mark.asyncio
async def test_tool_permission_is_enforced() -> None:
    registry = ToolRegistry()
    registry.register(EchoTool())
    context = ToolContext("run", "request", "trace", frozenset())
    with pytest.raises(PermissionError, match="echo:call"):
        await registry.execute("echo", {"value": "x"}, context)


@pytest.mark.asyncio
async def test_tool_executes_with_permission() -> None:
    registry = ToolRegistry()
    registry.register(EchoTool())
    context = ToolContext("run", "request", "trace", frozenset({"echo:call"}))
    assert await registry.execute("echo", {"value": "x"}, context) == {"value": "x"}
