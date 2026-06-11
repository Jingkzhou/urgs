from dataclasses import dataclass

from redis.asyncio import Redis
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker

from urgs_agent.config import Settings
from urgs_agent.plugins.models import MockModelProvider, ModelRegistry, OpenAICompatibleProvider
from urgs_agent.plugins.retrievers import UrgsRagRetriever
from urgs_agent.plugins.tools import (
    LineageAnalysisTool,
    McpTool,
    RagSearchTool,
    ToolRegistry,
    UrgsApiTool,
)
from urgs_agent.runtime.compiler import GraphCompiler
from urgs_agent.storage.database import create_engine, create_session_factory
from urgs_agent.storage.redis import RedisBroker
from urgs_agent.storage.repositories import AgentRepository, EventRepository, RunRepository


@dataclass
class Container:
    settings: Settings
    engine: AsyncEngine
    sessions: async_sessionmaker[AsyncSession]
    redis: Redis
    broker: RedisBroker
    agents: AgentRepository
    runs: RunRepository
    events: EventRepository
    models: ModelRegistry
    tools: ToolRegistry
    compiler: GraphCompiler

    @classmethod
    def build(cls, settings: Settings) -> "Container":
        engine = create_engine(settings)
        sessions = create_session_factory(engine)
        redis = Redis.from_url(settings.redis_url)
        models = ModelRegistry()
        models.register(OpenAICompatibleProvider(settings))
        models.register(MockModelProvider())
        tools = ToolRegistry()
        retriever = UrgsRagRetriever(settings.rag_url, settings.http_timeout_seconds)
        tools.register(RagSearchTool(retriever))
        tools.register(LineageAnalysisTool(settings.lineage_url, settings.http_timeout_seconds))
        tools.register(
            UrgsApiTool(
                settings.urgs_api_url,
                allowed_paths={"/api/jobs", "/api/metadata/lineage/graph"},
                timeout=settings.http_timeout_seconds,
            )
        )
        tools.register(McpTool(stdio_servers=settings.trusted_mcp_stdio_servers))
        return cls(
            settings=settings,
            engine=engine,
            sessions=sessions,
            redis=redis,
            broker=RedisBroker(redis, settings),
            agents=AgentRepository(sessions),
            runs=RunRepository(sessions),
            events=EventRepository(sessions),
            models=models,
            tools=tools,
            compiler=GraphCompiler(models, tools),
        )

    async def close(self) -> None:
        await self.redis.aclose()
        await self.engine.dispose()
