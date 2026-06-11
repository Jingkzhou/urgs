import hashlib
import json
import uuid
from datetime import UTC, datetime
from typing import Any

from sqlalchemy import func, select, update
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from urgs_agent.domain.enums import TERMINAL_RUN_STATUSES, RunStatus, VersionStatus
from urgs_agent.domain.schemas import AgentCreate, RunCreate, WorkflowDefinition
from urgs_agent.storage.models import (
    AgentDefinitionModel,
    AgentVersionModel,
    ApprovalModel,
    ModelUsageModel,
    RunEventModel,
    RunModel,
    ToolCallModel,
)


class NotFoundError(RuntimeError):
    pass


class ConflictError(RuntimeError):
    pass


class AgentRepository:
    def __init__(self, factory: async_sessionmaker[AsyncSession]) -> None:
        self.factory = factory

    async def create(self, data: AgentCreate) -> AgentDefinitionModel:
        async with self.factory() as session, session.begin():
            model = AgentDefinitionModel(**data.model_dump())
            session.add(model)
            try:
                await session.flush()
            except IntegrityError as exc:
                raise ConflictError(f"agent already exists: {data.agent_id}") from exc
            return model

    async def get(self, agent_id: str) -> AgentDefinitionModel:
        async with self.factory() as session:
            model = await session.get(AgentDefinitionModel, agent_id)
            if model is None:
                raise NotFoundError(f"agent not found: {agent_id}")
            return model

    async def create_version(
        self, agent_id: str, definition: WorkflowDefinition
    ) -> AgentVersionModel:
        canonical = json.dumps(
            definition.model_dump(mode="json"), sort_keys=True, separators=(",", ":")
        )
        config_hash = hashlib.sha256(canonical.encode()).hexdigest()
        async with self.factory() as session, session.begin():
            agent = await session.get(AgentDefinitionModel, agent_id, with_for_update=True)
            if agent is None:
                raise NotFoundError(f"agent not found: {agent_id}")
            latest = await session.scalar(
                select(func.max(AgentVersionModel.version)).where(
                    AgentVersionModel.agent_id == agent_id
                )
            )
            model = AgentVersionModel(
                agent_id=agent_id,
                version=(latest or 0) + 1,
                config_hash=config_hash,
                definition=definition.model_dump(mode="json"),
            )
            session.add(model)
            await session.flush()
            return model

    async def publish(self, agent_id: str, version: int) -> AgentVersionModel:
        now = datetime.now(UTC)
        async with self.factory() as session, session.begin():
            agent = await session.get(AgentDefinitionModel, agent_id, with_for_update=True)
            if agent is None:
                raise NotFoundError(f"agent not found: {agent_id}")
            model = await session.scalar(
                select(AgentVersionModel).where(
                    AgentVersionModel.agent_id == agent_id,
                    AgentVersionModel.version == version,
                )
            )
            if model is None:
                raise NotFoundError(f"agent version not found: {agent_id}:{version}")
            await session.execute(
                update(AgentVersionModel)
                .where(
                    AgentVersionModel.agent_id == agent_id,
                    AgentVersionModel.status == VersionStatus.PUBLISHED,
                )
                .values(status=VersionStatus.ARCHIVED)
            )
            model.status = VersionStatus.PUBLISHED
            model.published_at = now
            agent.published_version = version
            await session.flush()
            return model

    async def resolve_version(self, agent_id: str, version: int | None = None) -> AgentVersionModel:
        async with self.factory() as session:
            if version is None:
                agent = await session.get(AgentDefinitionModel, agent_id)
                if agent is None or agent.published_version is None:
                    raise NotFoundError(f"agent has no published version: {agent_id}")
                version = agent.published_version
            model = await session.scalar(
                select(AgentVersionModel).where(
                    AgentVersionModel.agent_id == agent_id,
                    AgentVersionModel.version == version,
                )
            )
            if model is None:
                raise NotFoundError(f"agent version not found: {agent_id}:{version}")
            return model


class RunRepository:
    def __init__(self, factory: async_sessionmaker[AsyncSession]) -> None:
        self.factory = factory

    async def create(self, data: RunCreate, agent_version: int) -> tuple[RunModel, bool]:
        tenant_scope = data.tenant_id or "__global__"
        async with self.factory() as session, session.begin():
            existing = await session.scalar(
                select(RunModel).where(
                    RunModel.tenant_scope == tenant_scope, RunModel.request_id == data.request_id
                )
            )
            if existing is not None:
                return existing, False
            model = RunModel(
                tenant_id=data.tenant_id,
                tenant_scope=tenant_scope,
                user_id=data.user_id,
                operator_id=data.operator_id,
                business_id=data.business_id,
                conversation_id=data.conversation_id,
                thread_id=data.thread_id,
                request_id=data.request_id,
                trace_id=data.trace_id,
                agent_id=data.agent_id,
                agent_version=agent_version,
                status=RunStatus.QUEUED,
                input=data.input,
                callback_url=str(data.callback_url) if data.callback_url else None,
                request_context={
                    "metadata": data.metadata,
                    "permissions": data.permissions,
                    "tenant_id": data.tenant_id,
                    "user_id": data.user_id,
                    "operator_id": data.operator_id,
                    "business_id": data.business_id,
                },
            )
            session.add(model)
            try:
                await session.flush()
            except IntegrityError:
                await session.rollback()
                async with self.factory() as retry_session:
                    raced = await retry_session.scalar(
                        select(RunModel).where(
                            RunModel.tenant_scope == tenant_scope,
                            RunModel.request_id == data.request_id,
                        )
                    )
                    if raced is None:
                        raise
                    return raced, False
            return model, True

    async def get(self, run_id: uuid.UUID) -> RunModel:
        async with self.factory() as session:
            model = await session.get(RunModel, run_id)
            if model is None:
                raise NotFoundError(f"run not found: {run_id}")
            return model

    async def transition(
        self,
        run_id: uuid.UUID,
        status: RunStatus,
        *,
        output: dict[str, Any] | None = None,
        error: dict[str, Any] | None = None,
    ) -> RunModel:
        async with self.factory() as session, session.begin():
            model = await session.get(RunModel, run_id, with_for_update=True)
            if model is None:
                raise NotFoundError(f"run not found: {run_id}")
            if model.status in TERMINAL_RUN_STATUSES and model.status != status:
                raise ConflictError(
                    f"terminal run cannot transition from {model.status} to {status}"
                )
            now = datetime.now(UTC)
            model.status = status
            if status == RunStatus.RUNNING and model.started_at is None:
                model.started_at = now
            if status in TERMINAL_RUN_STATUSES:
                model.finished_at = now
            if output is not None:
                model.output = output
            if error is not None:
                model.error = error
            await session.flush()
            return model

    async def set_resume_value(self, run_id: uuid.UUID, value: Any) -> None:
        async with self.factory() as session, session.begin():
            model = await session.get(RunModel, run_id, with_for_update=True)
            if model is None:
                raise NotFoundError(f"run not found: {run_id}")
            if model.status not in {RunStatus.WAITING_APPROVAL, RunStatus.PAUSED}:
                raise ConflictError(f"run is not resumable: {model.status}")
            model.resume_value = value
            model.status = RunStatus.QUEUED

    async def consume_resume_value(self, run_id: uuid.UUID) -> Any | None:
        async with self.factory() as session, session.begin():
            model = await session.get(RunModel, run_id, with_for_update=True)
            if model is None:
                raise NotFoundError(f"run not found: {run_id}")
            value = model.resume_value
            model.resume_value = None
            return value


class EventRepository:
    def __init__(self, factory: async_sessionmaker[AsyncSession]) -> None:
        self.factory = factory

    async def append(
        self,
        run: RunModel,
        event_type: str,
        payload: dict[str, Any],
        node_id: str | None = None,
    ) -> RunEventModel:
        async with self.factory() as session, session.begin():
            await session.get(RunModel, run.run_id, with_for_update=True)
            latest = await session.scalar(
                select(func.max(RunEventModel.sequence)).where(RunEventModel.run_id == run.run_id)
            )
            event = RunEventModel(
                run_id=run.run_id,
                event_type=event_type,
                sequence=(latest or 0) + 1,
                thread_id=run.thread_id,
                request_id=run.request_id,
                trace_id=run.trace_id,
                agent_id=run.agent_id,
                agent_version=run.agent_version,
                node_id=node_id,
                payload=payload,
            )
            session.add(event)
            await session.flush()
            return event

    async def list(self, run_id: uuid.UUID, after_sequence: int = 0) -> list[RunEventModel]:
        async with self.factory() as session:
            result = await session.scalars(
                select(RunEventModel)
                .where(
                    RunEventModel.run_id == run_id,
                    RunEventModel.sequence > after_sequence,
                )
                .order_by(RunEventModel.sequence)
            )
            return list(result)

    async def create_approval(self, run_id: uuid.UUID, payload: dict[str, Any]) -> ApprovalModel:
        async with self.factory() as session, session.begin():
            approval = ApprovalModel(run_id=run_id, payload=payload)
            session.add(approval)
            await session.flush()
            return approval

    async def resolve_latest_approval(self, run_id: uuid.UUID, decision: Any) -> None:
        async with self.factory() as session, session.begin():
            approval = await session.scalar(
                select(ApprovalModel)
                .where(ApprovalModel.run_id == run_id, ApprovalModel.status == "PENDING")
                .order_by(ApprovalModel.created_at.desc())
            )
            if approval is not None:
                approval.status = "RESOLVED"
                approval.decision = {"value": decision}
                approval.resolved_at = datetime.now(UTC)

    async def record_usage(self, run_id: uuid.UUID, payload: dict[str, Any]) -> None:
        usage = payload.get("usage", {})
        if not isinstance(usage, dict):
            usage = {}
        async with self.factory() as session, session.begin():
            session.add(
                ModelUsageModel(
                    run_id=run_id,
                    provider=str(payload.get("provider", "unknown")),
                    model=str(payload.get("model", "unknown")),
                    prompt_tokens=int(usage.get("input_tokens", 0) or 0),
                    completion_tokens=int(usage.get("output_tokens", 0) or 0),
                    cached_tokens=int(
                        usage.get("input_token_details", {}).get("cache_read", 0) or 0
                    )
                    if isinstance(usage.get("input_token_details"), dict)
                    else 0,
                    estimated_cost=None,
                    latency_ms=0,
                    success=True,
                )
            )

    async def record_tool_event(
        self, run_id: uuid.UUID, event_type: str, payload: dict[str, Any]
    ) -> None:
        call_id = payload.get("tool_call_id")
        if event_type == "tool.started":
            async with self.factory() as session, session.begin():
                session.add(
                    ToolCallModel(
                        run_id=run_id,
                        tool_name=str(payload.get("tool", "unknown")),
                        idempotency_key=str(call_id) if call_id else None,
                        status="RUNNING",
                        request=payload.get("arguments", {}),
                    )
                )
            return
        async with self.factory() as session, session.begin():
            model = await session.scalar(
                select(ToolCallModel)
                .where(
                    ToolCallModel.run_id == run_id,
                    ToolCallModel.idempotency_key == (str(call_id) if call_id else None),
                    ToolCallModel.status == "RUNNING",
                )
                .order_by(ToolCallModel.started_at.desc())
            )
            if model is not None:
                model.status = "COMPLETED"
                model.response = payload.get("result", {})
                model.finished_at = datetime.now(UTC)
