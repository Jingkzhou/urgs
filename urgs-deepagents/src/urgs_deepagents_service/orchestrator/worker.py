"""Worker：执行子任务，复用 create_deep_agent，支持流式输出与工具事件转发。"""

from __future__ import annotations

from collections.abc import AsyncIterator
from dataclasses import dataclass, field
from typing import Any

from deepagents import create_deep_agent
from langchain_core.language_models import BaseChatModel

from urgs_deepagents_service.orchestrator.state import WorkerOutput
from urgs_deepagents_service.orchestrator.utils import (
    assistant_text_from_output,
    build_agent_kwargs,
    chunk_text,
    sse,
    tool_call_payload,
    tool_result_text,
)


@dataclass
class WorkerRun:
    """单次 Worker 执行的容器：events() 产出 SSE，output 在迭代结束后填充。"""

    agent_code: str
    task: str
    stream_content: bool
    output: WorkerOutput = field(init=False)

    def __post_init__(self) -> None:
        self.output = WorkerOutput(agent_code=self.agent_code, task=self.task, answer="")


async def run_worker(
    *,
    model: BaseChatModel | str,
    settings: Any,
    agent_code: str,
    agent_config: Any,
    task: str,
    context: str,
    stream_content: bool,
    debug: bool,
) -> WorkerRun:
    """构建并返回 WorkerRun。调用方迭代 run.events() 取事件，结束后读 run.output。"""
    runtime_kwargs = build_agent_kwargs(
        settings=settings,
        memory_files=getattr(agent_config, "memory_files", None),
        skill_dirs=getattr(agent_config, "skill_dirs", None),
        tool_allowlist=getattr(agent_config, "tool_allowlist", None),
        allow_write=getattr(agent_config, "allow_write", False),
        workspace_root=getattr(agent_config, "workspace_root", None),
        debug=debug,
    )
    system_prompt = getattr(agent_config, "system_prompt", None) or "You are a helpful assistant."
    if getattr(agent_config, "workspace_root", None):
        # FilesystemBackend 已绑定工作空间根，但 LLM 不知道路径约定，会凭 prompt 字样猜前缀。
        # 这里只说明路径约定（相对根、前导 /、不加前缀），不暴露宿主机物理路径。
        system_prompt = (
            f"{system_prompt}\n\n"
            f"## 文件工具路径约定\n"
            f"你的文件工具（ls/read_file/write_file/grep 等）工作在一个已绑定的工作空间内。"
            f"所有路径均相对于该工作空间根，使用前导 `/`，不要在路径前加工作空间名、"
            f"系统名或任意前缀。例如 `00-首页/index.md` 对应工具路径 `/00-首页/index.md`。"
        )
    agent = create_deep_agent(
        model=model,
        tools=[],
        system_prompt=system_prompt,
        **runtime_kwargs,
    )

    messages: list[dict[str, str]] = []
    if context:
        messages.append({"role": "user", "content": f"前置上下文：\n{context}"})
    messages.append({"role": "user", "content": task})

    run = WorkerRun(agent_code=agent_code, task=task, stream_content=stream_content)
    collected: list[str] = []
    emitted_text = False

    async def events() -> AsyncIterator[str]:
        nonlocal emitted_text
        yield sse("worker", {"type": "worker", "status": "started", "agent_code": agent_code, "task": task})
        yield sse(
            "agent",
            {"type": "thinking", "title": f"{agent_code} 正在思考", "content": "正在分析并执行子任务"},
        )
        async for event in agent.astream_events({"messages": messages}, version="v2"):
            event_name = event.get("event")
            name = event.get("name") or ""
            data = event.get("data") or {}

            if event_name == "on_chat_model_stream":
                text = chunk_text(data.get("chunk"))
                if text:
                    if stream_content:
                        yield sse("content", {"content": text})
                    else:
                        collected.append(text)
                    emitted_text = True
                continue

            if event_name == "on_tool_start":
                yield sse(
                    "agent",
                    {
                        "type": "tool_call",
                        "title": f"调用工具 {name}",
                        "toolName": name,
                        "args": data.get("input"),
                    },
                )
                continue

            if event_name == "on_tool_end":
                yield sse(
                    "agent",
                    {
                        "type": "tool_result",
                        "title": f"工具 {name} 返回结果",
                        "toolName": name,
                        "content": tool_result_text(data.get("output")),
                    },
                )
                continue

            if event_name == "on_chat_model_end":
                output = data.get("output")
                if not emitted_text:
                    text = chunk_text(output)
                    if text:
                        if stream_content:
                            yield sse("content", {"content": text})
                        else:
                            collected.append(text)
                        emitted_text = True
                # 不在此转发 tool_call：on_tool_start 已会发送，避免「准备调用」与「调用」重复
                continue

            if event_name == "on_chain_end" and name == "LangGraph" and not emitted_text:
                text = assistant_text_from_output(data.get("output"))
                if text:
                    if stream_content:
                        yield sse("content", {"content": text})
                    else:
                        collected.append(text)
                    emitted_text = True

        run.output.answer = "".join(collected) if not stream_content else ""
        yield sse(
            "worker",
            {
                "type": "worker",
                "status": "completed",
                "agent_code": agent_code,
                "task": task,
                "answer_preview": (run.output.answer[:200] if not stream_content else None),
            },
        )

    run.events = events  # type: ignore[method-assign]
    return run
