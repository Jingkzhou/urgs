import asyncio
import logging
import uuid
from typing import Any

from langchain_core.messages import AIMessage, HumanMessage
from langgraph.types import Command

from urgs_agent.domain.enums import RunStatus
from urgs_agent.domain.schemas import WorkflowDefinition
from urgs_agent.runtime.callbacks import CallbackDispatcher
from urgs_agent.runtime.compiler import GraphCompiler
from urgs_agent.storage.redis import RedisBroker
from urgs_agent.storage.repositories import AgentRepository, EventRepository, RunRepository

logger = logging.getLogger(__name__)


class RunExecutor:
    def __init__(
        self,
        agents: AgentRepository,
        runs: RunRepository,
        events: EventRepository,
        broker: RedisBroker,
        compiler: GraphCompiler,
        checkpointer: Any,
        callbacks: CallbackDispatcher,
    ) -> None:
        self.agents = agents
        self.runs = runs
        self.events = events
        self.broker = broker
        self.compiler = compiler
        self.checkpointer = checkpointer
        self.callbacks = callbacks

    async def execute(self, run_id: uuid.UUID) -> None:
        run = await self.runs.get(run_id)
        if await self.broker.is_cancelled(run_id):
            await self._finish(run_id, RunStatus.CANCELLED, "run.cancelled", {})
            return
        if not await self.broker.acquire_thread(run.thread_id, run_id):
            await self._finish(
                run_id,
                RunStatus.FAILED,
                "run.failed",
                {"code": "THREAD_BUSY", "message": "thread already has an active run"},
            )
            return
        try:
            await self.runs.transition(run_id, RunStatus.RUNNING)
            run = await self.runs.get(run_id)
            await self._emit(run, "run.started", {})
            version = await self.agents.resolve_version(run.agent_id, run.agent_version)
            definition = WorkflowDefinition.model_validate(version.definition)
            graph = self.compiler.compile(definition, version.config_hash, self.checkpointer)
            config = {
                "configurable": {
                    "thread_id": f"{run.agent_id}:{run.agent_version}:{run.thread_id}",
                    "run_id": str(run.run_id),
                    "request_id": run.request_id,
                    "trace_id": run.trace_id,
                    "permissions": run.request_context.get("permissions", []),
                    "metadata": run.request_context.get("metadata", {}),
                    "event_sink": self._event_sink(run),
                },
                "recursion_limit": definition.limits.max_steps + 5,
            }
            resume_value = await self.runs.consume_resume_value(run_id)
            graph_input: Any
            if resume_value is not None:
                graph_input = Command(resume=resume_value)
            else:
                content = run.input if isinstance(run.input, str) else str(run.input)
                graph_input = {
                    "messages": [HumanMessage(content=content)],
                    "context": run.request_context,
                    "model_calls": 0,
                    "steps": 0,
                    "specialist_results": [],
                }
            result = await asyncio.wait_for(
                graph.ainvoke(graph_input, config=config), timeout=definition.limits.timeout_seconds
            )
            snapshot = await graph.aget_state(config)
            interrupts = [item for task in snapshot.tasks for item in task.interrupts]
            if interrupts:
                payload = {"interrupts": [item.value for item in interrupts]}
                await self.events.create_approval(run_id, payload)
                await self.runs.transition(run_id, RunStatus.WAITING_APPROVAL)
                await self._emit(run, "approval.required", payload)
                await self._emit(run, "run.paused", {"reason": "approval"})
                return
            messages = result.get("messages", [])
            answer = result.get("final_answer")
            if answer is None and messages:
                last = messages[-1]
                answer = str(last.content) if isinstance(last, AIMessage) else str(last)
            output = {
                "answer": answer or "",
                "specialist_results": result.get("specialist_results", []),
            }
            await self.runs.transition(run_id, RunStatus.COMPLETED, output=output)
            await self._emit(run, "run.completed", output)
            await self.callbacks.deliver(
                run, {"run_id": str(run_id), "status": "COMPLETED", **output}
            )
        except TimeoutError:
            await self._finish(run_id, RunStatus.TIMED_OUT, "run.failed", {"code": "TIMEOUT"})
        except asyncio.CancelledError:
            await self._finish(run_id, RunStatus.CANCELLED, "run.cancelled", {})
        except Exception as exc:
            logger.exception("run execution failed", extra={"run_id": str(run_id)})
            await self._finish(
                run_id,
                RunStatus.FAILED,
                "run.failed",
                {"code": type(exc).__name__, "message": str(exc)},
            )
        finally:
            await self.broker.release_thread(run.thread_id, run_id)

    def _event_sink(self, run: Any) -> Any:
        async def sink(event_type: str, payload: dict[str, Any], node_id: str | None) -> None:
            if await self.broker.is_cancelled(run.run_id):
                raise asyncio.CancelledError
            await self._emit(run, event_type, payload, node_id)
            if event_type == "usage.updated":
                await self.events.record_usage(run.run_id, payload)
            elif event_type in {"tool.started", "tool.completed"}:
                await self.events.record_tool_event(run.run_id, event_type, payload)

        return sink

    async def _emit(
        self,
        run: Any,
        event_type: str,
        payload: dict[str, Any],
        node_id: str | None = None,
    ) -> None:
        event = await self.events.append(run, event_type, payload, node_id)
        await self.broker.publish_event(
            run.run_id,
            {
                "event_id": str(event.event_id),
                "event_type": event.event_type,
                "sequence": event.sequence,
                "timestamp": event.timestamp,
                "run_id": str(event.run_id),
                "thread_id": event.thread_id,
                "request_id": event.request_id,
                "trace_id": event.trace_id,
                "agent_id": event.agent_id,
                "agent_version": event.agent_version,
                "node_id": event.node_id,
                "payload": event.payload,
            },
        )

    async def _finish(
        self,
        run_id: uuid.UUID,
        status: RunStatus,
        event_type: str,
        payload: dict[str, Any],
    ) -> None:
        run = await self.runs.get(run_id)
        await self.runs.transition(
            run_id, status, error=payload if status != RunStatus.CANCELLED else None
        )
        await self._emit(run, event_type, payload)
        await self.callbacks.deliver(
            run, {"run_id": str(run_id), "status": status.value, "error": payload}
        )
