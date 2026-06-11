"""Create agent runtime core tables.

Revision ID: 0001
Revises:
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "0001"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

agent_status = sa.Enum("ACTIVE", "DISABLED", name="agentstatus")
version_status = sa.Enum("DRAFT", "PUBLISHED", "ARCHIVED", name="versionstatus")
run_status = sa.Enum(
    "QUEUED",
    "RUNNING",
    "WAITING_APPROVAL",
    "PAUSED",
    "COMPLETED",
    "FAILED",
    "CANCELLED",
    "TIMED_OUT",
    name="runstatus",
)


def upgrade() -> None:
    op.create_table(
        "agent_definitions",
        sa.Column("agent_id", sa.String(64), primary_key=True),
        sa.Column("name", sa.String(200), nullable=False),
        sa.Column("description", sa.Text(), nullable=False, server_default=""),
        sa.Column("status", agent_status, nullable=False),
        sa.Column("published_version", sa.Integer()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
    )
    op.create_table(
        "agent_versions",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("agent_id", sa.String(64), sa.ForeignKey("agent_definitions.agent_id")),
        sa.Column("version", sa.Integer(), nullable=False),
        sa.Column("status", version_status, nullable=False),
        sa.Column("config_hash", sa.String(64), nullable=False),
        sa.Column("definition", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("published_at", sa.DateTime(timezone=True)),
        sa.UniqueConstraint("agent_id", "version"),
    )
    op.create_index("ix_agent_versions_agent_id", "agent_versions", ["agent_id"])
    op.create_index("ix_agent_versions_config_hash", "agent_versions", ["config_hash"])
    op.create_table(
        "agent_runs",
        sa.Column("run_id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("tenant_id", sa.String(128)),
        sa.Column("tenant_scope", sa.String(128), nullable=False),
        sa.Column("user_id", sa.String(128)),
        sa.Column("operator_id", sa.String(128)),
        sa.Column("business_id", sa.String(128)),
        sa.Column("conversation_id", sa.String(128), nullable=False),
        sa.Column("thread_id", sa.String(128), nullable=False),
        sa.Column("request_id", sa.String(128), nullable=False),
        sa.Column("trace_id", sa.String(128), nullable=False),
        sa.Column("agent_id", sa.String(64), nullable=False),
        sa.Column("agent_version", sa.Integer(), nullable=False),
        sa.Column("status", run_status, nullable=False),
        sa.Column("input", sa.JSON(), nullable=False),
        sa.Column("output", sa.JSON()),
        sa.Column("error", sa.JSON()),
        sa.Column("request_context", sa.JSON(), nullable=False),
        sa.Column("callback_url", sa.Text()),
        sa.Column("resume_value", sa.JSON()),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("started_at", sa.DateTime(timezone=True)),
        sa.Column("finished_at", sa.DateTime(timezone=True)),
        sa.UniqueConstraint("tenant_scope", "request_id", name="uq_run_tenant_request"),
    )
    op.create_index("ix_run_thread_status", "agent_runs", ["thread_id", "status"])
    for column in ("conversation_id", "thread_id", "trace_id", "agent_id", "status"):
        op.create_index(f"ix_agent_runs_{column}", "agent_runs", [column])
    op.create_table(
        "run_events",
        sa.Column("event_id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("run_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("agent_runs.run_id")),
        sa.Column("event_type", sa.String(80), nullable=False),
        sa.Column("sequence", sa.BigInteger(), nullable=False),
        sa.Column("timestamp", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("thread_id", sa.String(128), nullable=False),
        sa.Column("request_id", sa.String(128), nullable=False),
        sa.Column("trace_id", sa.String(128), nullable=False),
        sa.Column("agent_id", sa.String(64), nullable=False),
        sa.Column("agent_version", sa.Integer(), nullable=False),
        sa.Column("node_id", sa.String(128)),
        sa.Column("payload", sa.JSON(), nullable=False),
        sa.UniqueConstraint("run_id", "sequence"),
    )
    op.create_index("ix_run_events_run_id", "run_events", ["run_id"])
    op.create_index("ix_run_events_event_type", "run_events", ["event_type"])
    _create_auxiliary_tables()


def _create_auxiliary_tables() -> None:
    specs = {
        "tool_calls": [
            sa.Column("tool_name", sa.String(128), nullable=False),
            sa.Column("idempotency_key", sa.String(200)),
            sa.Column("status", sa.String(32), nullable=False),
            sa.Column("request", sa.JSON(), nullable=False),
            sa.Column("response", sa.JSON()),
            sa.Column("error", sa.Text()),
            sa.Column("started_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
            sa.Column("finished_at", sa.DateTime(timezone=True)),
        ],
        "run_approvals": [
            sa.Column("interrupt_id", sa.String(128)),
            sa.Column("payload", sa.JSON(), nullable=False),
            sa.Column("decision", sa.JSON()),
            sa.Column("status", sa.String(32), nullable=False),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
            sa.Column("resolved_at", sa.DateTime(timezone=True)),
        ],
        "model_usage": [
            sa.Column("provider", sa.String(64), nullable=False),
            sa.Column("model", sa.String(128), nullable=False),
            sa.Column("prompt_tokens", sa.Integer(), nullable=False),
            sa.Column("completion_tokens", sa.Integer(), nullable=False),
            sa.Column("cached_tokens", sa.Integer(), nullable=False),
            sa.Column("estimated_cost", sa.String(40)),
            sa.Column("latency_ms", sa.Integer(), nullable=False),
            sa.Column("success", sa.Boolean(), nullable=False),
            sa.Column("error", sa.Text()),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        ],
        "callback_deliveries": [
            sa.Column("url", sa.Text(), nullable=False),
            sa.Column("attempt", sa.Integer(), nullable=False),
            sa.Column("status_code", sa.Integer()),
            sa.Column("success", sa.Boolean(), nullable=False),
            sa.Column("error", sa.Text()),
            sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        ],
    }
    for table, columns in specs.items():
        op.create_table(
            table,
            sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
            sa.Column("run_id", postgresql.UUID(as_uuid=True), sa.ForeignKey("agent_runs.run_id")),
            *columns,
        )
        op.create_index(f"ix_{table}_run_id", table, ["run_id"])
    op.create_table(
        "long_term_memories",
        sa.Column("id", postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column("namespace", sa.String(256), nullable=False),
        sa.Column("memory_key", sa.String(256), nullable=False),
        sa.Column("value", sa.JSON(), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now()),
        sa.UniqueConstraint("namespace", "memory_key"),
    )
    op.create_index("ix_long_term_memories_namespace", "long_term_memories", ["namespace"])


def downgrade() -> None:
    for table in (
        "long_term_memories",
        "callback_deliveries",
        "model_usage",
        "run_approvals",
        "tool_calls",
        "run_events",
        "agent_runs",
        "agent_versions",
        "agent_definitions",
    ):
        op.drop_table(table)
    bind = op.get_bind()
    run_status.drop(bind, checkfirst=True)
    version_status.drop(bind, checkfirst=True)
    agent_status.drop(bind, checkfirst=True)
