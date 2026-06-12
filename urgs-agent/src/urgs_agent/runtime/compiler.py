import json
from collections.abc import Awaitable, Callable
from typing import Any, cast

from langchain_core.messages import AIMessage, BaseMessage, HumanMessage, SystemMessage, ToolMessage
from langchain_core.runnables import RunnableConfig
from langgraph.graph import END, START, StateGraph
from langgraph.types import Command, interrupt

from urgs_agent.domain.schemas import SpecialistConfig, WorkflowDefinition
from urgs_agent.plugins.contracts import EventSink, ToolContext
from urgs_agent.plugins.models import ModelRegistry
from urgs_agent.plugins.tools import ToolRegistry
from urgs_agent.runtime.state import AgentState


def _runtime(config: RunnableConfig) -> dict[str, Any]:
    return config.get("configurable", {})


class GraphCompiler:
    def __init__(self, models: ModelRegistry, tools: ToolRegistry) -> None:
        self.models = models
        self.tools = tools
        self._cache: dict[str, Any] = {}

    def validate(self, definition: WorkflowDefinition) -> None:
        all_tools = list(definition.tools)
        for specialist in definition.specialists:
            all_tools.extend(specialist.tools)
        self.tools.validate_names(all_tools)
        if definition.limits.max_steps < 2 and definition.template in {"react", "supervisor"}:
            raise ValueError("workflow max_steps must be at least 2")

    def compile(self, definition: WorkflowDefinition, config_hash: str, checkpointer: Any) -> Any:
        if config_hash in self._cache:
            return self._cache[config_hash]
        self.validate(definition)
        if definition.template == "react":
            graph = self._compile_react(definition)
        elif definition.template == "router":
            graph = self._compile_router(definition)
        else:
            graph = self._compile_supervisor(definition)
        compiled = graph.compile(checkpointer=checkpointer)
        self._cache[config_hash] = compiled
        return compiled

    def _model_node(
        self, definition: WorkflowDefinition, system_prompt: str, tool_names: list[str]
    ) -> Callable[[AgentState, RunnableConfig], Awaitable[dict[str, Any]]]:
        async def call_model(state: AgentState, config: RunnableConfig) -> dict[str, Any]:
            runtime = _runtime(config)
            sink = cast(EventSink | None, runtime.get("event_sink"))
            context = ToolContext(
                run_id=str(runtime.get("run_id", "")),
                request_id=str(runtime.get("request_id", "")),
                trace_id=str(runtime.get("trace_id", "")),
                permissions=frozenset(runtime.get("permissions", [])),
                metadata=runtime.get("metadata", {}),
                event_sink=sink,
            )
            system_context = await self.tools.system_context(tool_names, context)
            system_content = system_prompt
            if system_context:
                system_content = f"{system_prompt}\n\n{system_context}"
            messages: list[BaseMessage] = [
                SystemMessage(content=system_content),
                *state["messages"],
            ]
            schemas = self.tools.schemas(tool_names)
            last_error: Exception | None = None
            for index, (target, model) in enumerate(
                self.models.create_candidates(definition.model)
            ):
                try:
                    bound = model.bind_tools(schemas) if schemas else model
                    chunks: list[AIMessage] = []
                    async for chunk in bound.astream(messages, config=config):
                        chunks.append(cast(AIMessage, chunk))
                        content = getattr(chunk, "content", "")
                        if content and sink:
                            await sink("model.token", {"content": content}, None)
                    response = (
                        sum(chunks[1:], chunks[0]) if chunks else await bound.ainvoke(messages)
                    )
                    if sink:
                        usage = getattr(response, "usage_metadata", None) or {}
                        await sink(
                            "usage.updated",
                            {
                                "provider": target.provider,
                                "model": target.model,
                                "fallback_index": index,
                                "usage": usage,
                            },
                            None,
                        )
                    return {
                        "messages": [response],
                        "model_calls": state.get("model_calls", 0) + 1,
                        "steps": state.get("steps", 0) + 1,
                    }
                except Exception as exc:
                    last_error = exc
            assert last_error is not None
            raise last_error

        return call_model

    def _tool_node(
        self, definition: WorkflowDefinition
    ) -> Callable[[AgentState, RunnableConfig], Awaitable[dict[str, Any]]]:
        async def call_tools(state: AgentState, config: RunnableConfig) -> dict[str, Any]:
            runtime = _runtime(config)
            context = ToolContext(
                run_id=str(runtime["run_id"]),
                request_id=str(runtime["request_id"]),
                trace_id=str(runtime["trace_id"]),
                permissions=frozenset(runtime.get("permissions", [])),
                metadata=runtime.get("metadata", {}),
                event_sink=runtime.get("event_sink"),
            )
            last = cast(AIMessage, state["messages"][-1])
            results: list[ToolMessage] = []
            for call in last.tool_calls:
                name = call["name"]
                if name in definition.require_tool_approval:
                    decision = interrupt(
                        {"type": "tool_approval", "tool": name, "arguments": call["args"]}
                    )
                    approved = (
                        bool(decision.get("approved")) if isinstance(decision, dict) else False
                    )
                    if not approved:
                        results.append(
                            ToolMessage(content="Tool execution rejected", tool_call_id=call["id"])
                        )
                        continue
                try:
                    result = await self.tools.execute(
                        name, call["args"], context, call_id=call["id"]
                    )
                    content = self.tools.serialize_result(result)
                except Exception as exc:
                    content = json.dumps({"error": str(exc)}, ensure_ascii=False)
                results.append(ToolMessage(content=content, tool_call_id=call["id"]))
            return {"messages": results, "steps": state.get("steps", 0) + 1}

        return call_tools

    @staticmethod
    def _after_model(definition: WorkflowDefinition) -> Callable[[AgentState], str]:
        def route(state: AgentState) -> str:
            if state.get("steps", 0) >= definition.limits.max_steps:
                return END
            if state.get("model_calls", 0) >= definition.limits.max_model_calls:
                return END
            last = state["messages"][-1]
            return "tools" if isinstance(last, AIMessage) and last.tool_calls else END

        return route

    def _compile_react(self, definition: WorkflowDefinition) -> StateGraph[AgentState]:
        graph = StateGraph(AgentState)
        graph.add_node(
            "agent",
            cast(Any, self._model_node(definition, definition.system_prompt, definition.tools)),
        )
        graph.add_node("tools", cast(Any, self._tool_node(definition)))
        graph.add_edge(START, "agent")
        graph.add_conditional_edges("agent", self._after_model(definition), ["tools", END])
        graph.add_edge("tools", "agent")
        return graph

    def _compile_router(self, definition: WorkflowDefinition) -> StateGraph[AgentState]:
        graph = StateGraph(AgentState)
        specialists = definition.specialists or [
            SpecialistConfig(
                id="general",
                description="General requests",
                system_prompt=definition.system_prompt,
                tools=definition.tools,
            )
        ]

        def router(state: AgentState) -> Command[Any]:
            text = str(state["messages"][-1].content).lower()
            selected = next(
                (
                    item.id
                    for item in specialists
                    if item.id in text
                    or any(word in text for word in item.description.lower().split())
                ),
                specialists[0].id,
            )
            return Command(goto=selected)

        graph.add_node("router", router, destinations=tuple(item.id for item in specialists))
        for specialist in specialists:
            graph.add_node(
                specialist.id,
                cast(Any, self._model_node(definition, specialist.system_prompt, specialist.tools)),
            )
            graph.add_edge(specialist.id, END)
        graph.add_edge(START, "router")
        return graph

    def _compile_supervisor(self, definition: WorkflowDefinition) -> StateGraph[AgentState]:
        graph = StateGraph(AgentState)

        def specialist_node(
            specialist: SpecialistConfig,
        ) -> Callable[[AgentState, RunnableConfig], Awaitable[dict[str, Any]]]:
            model_node = self._model_node(definition, specialist.system_prompt, specialist.tools)

            async def execute(state: AgentState, config: RunnableConfig) -> dict[str, Any]:
                result = await model_node(state, config)
                message = cast(AIMessage, result["messages"][-1])
                return {
                    "specialist_results": [
                        {"specialist": specialist.id, "content": str(message.content)}
                    ],
                    "model_calls": result["model_calls"],
                    "steps": result["steps"],
                }

            return execute

        for specialist in definition.specialists:
            subgraph = StateGraph(AgentState)
            subgraph.add_node("execute", cast(Any, specialist_node(specialist)))
            subgraph.add_edge(START, "execute")
            subgraph.add_edge("execute", END)
            graph.add_node(specialist.id, subgraph.compile())
            graph.add_edge(START, specialist.id)

        async def synthesize(state: AgentState, config: RunnableConfig) -> dict[str, Any]:
            evidence = json.dumps(state.get("specialist_results", []), ensure_ascii=False)
            merged = cast(
                AgentState,
                {
                    **state,
                    "messages": [
                        *state["messages"],
                        HumanMessage(content=f"Synthesize these specialist results:\n{evidence}"),
                    ],
                },
            )
            result = await self._model_node(definition, definition.system_prompt, [])(
                merged, config
            )
            answer = str(cast(AIMessage, result["messages"][-1]).content)
            return {**result, "final_answer": answer}

        graph.add_node("synthesize", synthesize)
        for specialist in definition.specialists:
            graph.add_edge(specialist.id, "synthesize")
        graph.add_edge("synthesize", END)
        return graph
