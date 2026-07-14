"""Public progress reporting for Worker runs without exposing private reasoning."""

from __future__ import annotations

import json
from typing import Any

from langchain_core.tools import StructuredTool
from pydantic import BaseModel, Field

from urgs_deepagents_service.sse import sanitize_text

PROGRESS_TOOL_NAME = "report_progress"

PROGRESS_REPORT_INSTRUCTIONS = """
## 用户可见进度说明
你可以使用 `report_progress` 向用户说明任务进展。它不是业务工具，也不是最终答案。
- 仅在有实质信息增量时调用：开始多步骤工作、获得关键发现、调整方案、重试或进入核验阶段。
- 每次用 1 至 3 句说明“已确认什么、接下来做什么”，不要逐条复述工具调用。
- 只能陈述已由当前上下文或工具结果确认的事实，不得猜测、编造或暴露内部思维链。
- 不要包含密钥、内部地址、大段文件原文或原始工具返回。
- 简单问答无需调用；最终业务答案仍正常返回，不要通过此工具提交最终答案。
- 如果填写了 next_action，进度调用返回后必须实际执行该动作；
  report_progress 不能替代检索、读取、验证或编辑工具。
""".strip()


class ProgressReportInput(BaseModel):
    """Arguments accepted by the internal public-progress tool."""

    title: str = Field(description="简短进度标题", min_length=1, max_length=80)
    content: str = Field(
        description="已经确认的进展或发现，1 至 3 句", min_length=1, max_length=800
    )
    next_action: str = Field(
        default="", description="接下来准备执行的动作", max_length=300
    )
    phase: str = Field(
        default="execution",
        description="当前阶段，如 analysis、execution、verification、adjustment",
        max_length=40,
    )


def _report_progress(
    title: str, content: str, next_action: str = "", phase: str = "execution"
) -> str:
    """Acknowledge a public progress update; Worker converts the call into an SSE event."""

    del title, content, next_action, phase
    return "进度已记录，请继续执行任务。"


def create_progress_tool() -> StructuredTool:
    """Create the side-effect-free tool used for model-authored public progress."""

    return StructuredTool.from_function(
        func=_report_progress,
        name=PROGRESS_TOOL_NAME,
        description=(
            "向用户发布简短、基于事实的工作进度。仅在关键发现、方案调整、重试或阶段变化时使用；"
            "不要输出内部思维链，也不要用它提交最终答案。"
        ),
        args_schema=ProgressReportInput,
    )


def normalize_progress_payload(value: Any) -> dict[str, str]:
    """Normalize model tool arguments into a compact, display-safe payload."""

    if isinstance(value, str):
        try:
            parsed = json.loads(value)
        except json.JSONDecodeError:
            parsed = {"title": "进度更新", "content": value}
    else:
        parsed = value
    if not isinstance(parsed, dict):
        parsed = {}

    title = sanitize_text(parsed.get("title") or "进度更新").strip()[:80]
    content = sanitize_text(parsed.get("content") or "任务正在继续处理").strip()[:800]
    next_action = sanitize_text(parsed.get("next_action") or "").strip()[:300]
    phase = sanitize_text(parsed.get("phase") or "execution").strip()[:40]
    return {
        "title": title,
        "content": content,
        "next_action": next_action,
        "phase": phase,
    }


def build_tool_progress_payload(
    tool_name: str, arguments: Any, result_text: str
) -> dict[str, str]:
    """Build a factual fallback update from a completed business tool call."""

    args = arguments if isinstance(arguments, dict) else {}
    path = sanitize_text(args.get("file_path") or args.get("path") or "").strip()[:160]
    pattern = sanitize_text(args.get("pattern") or "").strip()[:80]
    result_lower = result_text.strip().lower()
    failed = (
        result_lower.startswith(("error:", "failed:", "permission denied"))
        or "file_not_found" in result_lower
    )
    if failed:
        return {
            "title": f"{tool_name} 未成功完成",
            "content": "本次工具调用未得到有效结果，正在调整处理方式。",
            "next_action": "检查输入条件并选择替代路径",
            "phase": "adjustment",
        }

    if tool_name == "grep":
        scope = f"在 {path} 中" if path else "在当前知识范围内"
        if "no matches found" in result_lower:
            target = f"“{pattern}”" if pattern else "目标内容"
            return {
                "title": f"未找到{target}的直接匹配",
                "content": f"{scope}没有找到直接匹配，准备调整关键词或扩大检索范围。",
                "next_action": "调整检索条件后继续查找",
                "phase": "adjustment",
            }
        target = f"“{pattern}”" if pattern else "目标内容"
        return {
            "title": f"已定位{target}相关内容",
            "content": f"{scope}获得了相关命中，接下来读取具体文件核对上下文和业务口径。",
            "next_action": "读取命中文件并核对原文",
            "phase": "verification",
        }

    if tool_name == "read_file":
        target = path or "目标文件"
        return {
            "title": f"已读取 {target}",
            "content": "文件读取完成，正在提取与当前问题直接相关的信息。",
            "next_action": "核对关键内容并形成结论",
            "phase": "verification",
        }

    if tool_name in {"edit_file", "write_file"}:
        target = path or "目标文件"
        return {
            "title": f"已更新 {target}",
            "content": "文件修改已经完成，接下来检查变更是否满足当前要求。",
            "next_action": "验证修改结果",
            "phase": "verification",
        }

    if tool_name in {"ls", "glob"}:
        target = path or pattern or "当前目录"
        return {
            "title": f"已确认 {target} 的内容范围",
            "content": "候选范围已经明确，正在继续缩小与当前问题直接相关的内容。",
            "next_action": "检索并读取相关文件",
            "phase": "analysis",
        }

    return {
        "title": f"{tool_name} 已完成",
        "content": "工具已经返回结果，正在结合当前问题提取有效信息。",
        "next_action": "核对结果并继续处理",
        "phase": "verification",
    }
