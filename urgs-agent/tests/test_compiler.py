from typing import Any

import pytest
from langgraph.checkpoint.memory import MemorySaver

from urgs_agent.domain.schemas import WorkflowDefinition
from urgs_agent.plugins.models import MockModelProvider, ModelRegistry
from urgs_agent.plugins.tools import ToolRegistry
from urgs_agent.runtime.compiler import GraphCompiler


def definition(**overrides: Any) -> WorkflowDefinition:
    raw: dict[str, Any] = {
        "template": "react",
        "system_prompt": "test",
        "model": {"primary": {"model": "test"}},
    }
    raw.update(overrides)
    return WorkflowDefinition.model_validate(raw)


def test_compiler_rejects_unknown_tool() -> None:
    compiler = GraphCompiler(ModelRegistry(), ToolRegistry())
    with pytest.raises(ValueError, match="unknown tools"):
        compiler.validate(definition(tools=["missing"]))


def test_compiler_accepts_minimal_react_definition() -> None:
    compiler = GraphCompiler(ModelRegistry(), ToolRegistry())
    compiler.validate(definition())
    compiler.compile(definition(), "react-hash", MemorySaver())


def test_compiler_builds_router_and_supervisor_templates() -> None:
    compiler = GraphCompiler(ModelRegistry(), ToolRegistry())
    specialists = [
        {"id": "rag", "description": "knowledge", "system_prompt": "retrieve"},
        {"id": "lineage", "description": "sql", "system_prompt": "analyze"},
    ]
    router = definition(template="router", specialists=specialists)
    supervisor = definition(template="supervisor", specialists=specialists)
    compiler.compile(router, "router-hash", MemorySaver())
    compiler.compile(supervisor, "supervisor-hash", MemorySaver())


@pytest.mark.asyncio
async def test_react_graph_executes_with_mock_model() -> None:
    models = ModelRegistry()
    models.register(MockModelProvider())
    compiler = GraphCompiler(models, ToolRegistry())
    graph_definition = definition(
        model={"primary": {"provider": "mock", "model": "deterministic answer"}}
    )
    graph = compiler.compile(graph_definition, "mock-hash", MemorySaver())
    result = await graph.ainvoke(
        {"messages": [("user", "hello")], "model_calls": 0, "steps": 0},
        config={"configurable": {"thread_id": "mock-thread"}},
    )
    assert result["messages"][-1].content == "deterministic answer"
