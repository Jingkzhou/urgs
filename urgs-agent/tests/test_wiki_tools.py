from collections.abc import Callable, Sequence
from pathlib import Path
from typing import Any

import pytest
import yaml
from langchain_core.callbacks.manager import CallbackManagerForLLMRun
from langchain_core.language_models.chat_models import BaseChatModel
from langchain_core.messages import AIMessage, BaseMessage, SystemMessage
from langchain_core.outputs import ChatGeneration, ChatResult
from langchain_core.runnables import Runnable
from langchain_core.tools import BaseTool
from langgraph.checkpoint.memory import MemorySaver

from urgs_agent.domain.schemas import WorkflowDefinition
from urgs_agent.plugins.contracts import ModelProvider, ToolContext
from urgs_agent.plugins.models import ModelRegistry
from urgs_agent.plugins.tools import ToolRegistry
from urgs_agent.plugins.wiki import (
    KnowledgeWikiStore,
    WikiAppendLogTool,
    WikiOverviewTool,
    WikiReadTool,
    WikiSearchTool,
    WikiWritePageTool,
)
from urgs_agent.runtime.compiler import GraphCompiler

RECORDED_MESSAGES: list[list[BaseMessage]] = []


@pytest.fixture
def wiki_store(tmp_path):
    (tmp_path / "00-首页").mkdir()
    (tmp_path / "01-资料库").mkdir()
    (tmp_path / "05-日志").mkdir()
    (tmp_path / "AGENTS.md").write_text(
        "# LLM Wiki Agent Guide\n\n本文件是本仓库的维护规则权威版本。\n",
        encoding="utf-8",
    )
    (tmp_path / "00-首页" / "index.md").write_text(
        "# Index\n\n- [[Topic]] -监管报送和血缘审核主题。\n",
        encoding="utf-8",
    )
    (tmp_path / "05-日志" / "log.md").write_text(
        "## [2026-06-10] ingest | Seed\n\n初始化知识库。\n",
        encoding="utf-8",
    )
    (tmp_path / "Topic.md").write_text(
        "# Topic\n\n监管报送批处理会使用 lineage 审核结果。[Missing](Missing.md)\n",
        encoding="utf-8",
    )
    (tmp_path / "01-资料库" / "source.md").write_text(
        "# Source\n\nraw source also mentions lineage and report batches.\n",
        encoding="utf-8",
    )
    return KnowledgeWikiStore(
        str(tmp_path),
        raw_dir="01-资料库",
        index_path="00-首页/index.md",
        log_path="05-日志/log.md",
    )


class RecordingChatModel(BaseChatModel):
    response: str = "recorded answer"

    @property
    def _llm_type(self) -> str:
        return "recording"

    def _generate(
        self,
        messages: list[BaseMessage],
        stop: list[str] | None = None,
        run_manager: CallbackManagerForLLMRun | None = None,
        **kwargs: Any,
    ) -> ChatResult:
        RECORDED_MESSAGES.append(messages)
        return ChatResult(generations=[ChatGeneration(message=AIMessage(content=self.response))])

    def bind_tools(
        self,
        tools: Sequence[dict[str, Any] | type | Callable[..., Any] | BaseTool],
        *,
        tool_choice: str | None = None,
        **kwargs: Any,
    ) -> Runnable[Any, BaseMessage]:
        return self


class RecordingModelProvider(ModelProvider):
    name = "recording"

    def create(self, target: Any, **kwargs: Any) -> BaseChatModel:
        return RecordingChatModel(response=target.model)


def test_wiki_overview_reads_index_log_and_health(wiki_store):
    overview = wiki_store.overview(max_files=20, max_recent_log_entries=5)

    assert overview["agent_guide"]["path"] == "AGENTS.md"
    assert "维护规则权威版本" in overview["agent_guide"]["content"]
    assert overview["index"]["title"] == "Index"
    assert overview["recent_log_entries"] == ["## [2026-06-10] ingest | Seed"]
    assert overview["counts"] == {"wiki_files": 4, "raw_files": 1}
    assert overview["health"]["missing_link_targets"] == ["Missing.md"]
    assert overview["health"]["orphan_pages"] == []


def test_wiki_search_reads_wiki_and_raw_scopes(wiki_store):
    result = wiki_store.search("lineage", scope="all", max_results=10, max_snippets=2)
    hits = {(item["scope"], item["path"]) for item in result["results"]}

    assert ("wiki", "Topic.md") in hits
    assert ("raw", "source.md") in hits
    assert result["searched_files"] == 5


def test_wiki_read_blocks_path_traversal(wiki_store):
    with pytest.raises(PermissionError, match="path traversal"):
        wiki_store.read("wiki", "../README.md", max_chars=1000)


def test_wiki_write_page_rejects_raw_and_checks_hash(wiki_store):
    created = wiki_store.write_page("analysis/new-page.md", "# New Page\n\nReusable answer.")
    assert created["path"] == "analysis/new-page.md"

    page = wiki_store.read("wiki", "analysis/new-page.md", max_chars=1000)
    assert page["title"] == "New Page"

    with pytest.raises(ValueError, match="sha256 mismatch"):
        wiki_store.write_page(
            "analysis/new-page.md",
            "# Changed",
            expected_sha256="0" * 64,
        )

    with pytest.raises(PermissionError, match="raw sources"):
        wiki_store.write_page("01-资料库/not-allowed.md", "# Bad")


@pytest.mark.asyncio
async def test_wiki_append_log_tool_writes_parseable_entry(wiki_store):
    tool = WikiAppendLogTool(wiki_store)
    context = ToolContext("run", "request", "trace", frozenset({"knowledge:write"}))

    result = await tool.execute(
        {
            "operation": "query",
            "title": "Lineage question",
            "summary": "用户问题已经沉淀为可复用结论。",
            "paths": ["Topic.md"],
        },
        context,
    )

    assert result["path"] == "05-日志/log.md"
    log_text = wiki_store.read("wiki", "05-日志/log.md", max_chars=5000)["content"]
    assert "query | Lineage question" in log_text
    assert "- `Topic.md`" in log_text


def test_llm_wiki_example_definition_uses_registered_tools(tmp_path):
    example_path = Path(__file__).resolve().parents[1] / "examples" / "llm-wiki-explorer.yaml"
    data = yaml.safe_load(example_path.read_text(encoding="utf-8"))
    definition = WorkflowDefinition.model_validate(data["definition"])
    store = KnowledgeWikiStore(str(tmp_path))
    registry = ToolRegistry()
    registry.register(WikiOverviewTool(store))
    registry.register(WikiSearchTool(store))
    registry.register(WikiReadTool(store))
    registry.register(WikiWritePageTool(store))
    registry.register(WikiAppendLogTool(store))

    GraphCompiler(models=ModelRegistry(), tools=registry).validate(definition)


@pytest.mark.asyncio
async def test_graph_injects_agent_guide_before_model_call(wiki_store):
    RECORDED_MESSAGES.clear()
    models = ModelRegistry()
    models.register(RecordingModelProvider())
    registry = ToolRegistry()
    registry.register(WikiOverviewTool(wiki_store))
    definition = WorkflowDefinition.model_validate(
        {
            "template": "react",
            "system_prompt": "base system prompt",
            "model": {"primary": {"provider": "recording", "model": "ok"}},
            "tools": ["wiki_overview"],
        }
    )
    graph = GraphCompiler(models=models, tools=registry).compile(
        definition,
        "agent-guide-context",
        MemorySaver(),
    )

    await graph.ainvoke(
        {"messages": [("user", "hello")], "model_calls": 0, "steps": 0},
        config={
            "configurable": {
                "thread_id": "wiki-thread",
                "run_id": "run",
                "request_id": "request",
                "trace_id": "trace",
                "permissions": ["knowledge:read"],
            }
        },
    )

    system_messages = [
        message for message in RECORDED_MESSAGES[0] if isinstance(message, SystemMessage)
    ]
    assert system_messages
    system_content = str(system_messages[0].content)
    assert "Source: `wiki:AGENTS.md`" in system_content
    assert "本文件是本仓库的维护规则权威版本" in system_content
