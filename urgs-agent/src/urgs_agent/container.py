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
from urgs_agent.plugins.wiki import (
    KnowledgeWikiStore,
    WikiAppendLogTool,
    WikiOverviewTool,
    WikiReadTool,
    WikiSearchTool,
    WikiWritePageTool,
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
        wiki_store = KnowledgeWikiStore(
            settings.knowledge_wiki_root,
            settings.knowledge_wiki_wiki_dir,
            settings.knowledge_wiki_raw_dir,
            settings.knowledge_wiki_index_path,
            settings.knowledge_wiki_log_path,
            settings.knowledge_wiki_agent_guide_path,
            settings.knowledge_wiki_max_file_bytes,
            settings.knowledge_wiki_max_search_files,
        )
        tools.register(WikiOverviewTool(wiki_store))
        tools.register(WikiSearchTool(wiki_store))
        tools.register(WikiReadTool(wiki_store))
        tools.register(WikiWritePageTool(wiki_store))
        tools.register(WikiAppendLogTool(wiki_store))
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
