"""通用助手任务模式判定。"""

from __future__ import annotations

import re

GENERAL_AGENT_CODE = "general-agent"

_DIRECT_ANSWER_MARKERS = (
    "只做解答",
    "只需解答",
    "只回答",
    "直接回答",
    "不要调用工具",
    "不调用工具",
    "不要扫描",
    "无需扫描",
    "不要查看项目",
    "无需查看项目",
    "不需要查看项目",
    "answer only",
    "do not use tools",
)

_WORKSPACE_SCOPE_MARKERS = (
    "当前项目",
    "本项目",
    "这个项目",
    "当前工程",
    "本工程",
    "这个工程",
    "当前仓库",
    "本仓库",
    "这个仓库",
    "代码仓库",
    "代码库",
    "当前工作区",
    "本工作区",
    "工作区文件",
    "项目文件",
    "工程文件",
    "仓库文件",
    "这个文件",
    "该文件",
    "这些文件",
    "这个目录",
    "该目录",
    "当前源码",
    "现有源码",
    "当前代码",
    "现有代码",
    "current project",
    "this project",
    "current repository",
    "this repository",
    "current workspace",
    "this workspace",
)

_WORKSPACE_MODULE_PATTERN = re.compile(
    r"\burgs-(?:web|api|deepagents|executor|scheduler)\b",
    re.I,
)
_SOURCE_FILE_PATTERN = re.compile(
    r"(?<![\w.-])[\w.-]+\.(?:tsx?|jsx?|java|py|sql|md|json|ya?ml|toml|xml|sh|vue|css|scss)(?=$|[\s:，。；])",
    re.I,
)
_PATH_PATTERN = re.compile(
    r"(?:^|[\s（(])(?:(?:/[^\s，。；)）]+){2,}|\./[^\s，。；)）]+|\.\./[^\s，。；)）]+)",
    re.I,
)
_WORKSPACE_ACTION_PATTERN = re.compile(
    r"(?:查看|读取|检查|扫描|搜索|定位|排查|修改|编辑|删除|新建|创建|写入|落地|修复)"
    r"[^\n。！？]{0,16}(?:文件|目录|源码|代码仓库|代码库|工作区|模块)",
)


def explicitly_requests_workspace_access(text: str) -> bool:
    """判断文本是否明确要求访问当前工作区，而不是仅索要知识或代码示例。"""

    normalized = text.strip()
    if not normalized:
        return False
    lowered = normalized.lower()
    if any(marker in lowered for marker in _WORKSPACE_SCOPE_MARKERS):
        return True
    return any(
        pattern.search(normalized) is not None
        for pattern in (
            _WORKSPACE_MODULE_PATTERN,
            _SOURCE_FILE_PATTERN,
            _PATH_PATTERN,
            _WORKSPACE_ACTION_PATTERN,
        )
    )


def should_answer_directly(
    agent_code: str,
    user_message: str,
    conversation_context: str = "",
) -> bool:
    """通用助手默认直接回答；仅在用户明确授权访问工作区时进入工具链路。"""

    if agent_code != GENERAL_AGENT_CODE:
        return False
    if any(marker in user_message.lower() for marker in _DIRECT_ANSWER_MARKERS):
        return True
    return not explicitly_requests_workspace_access(
        "\n".join(part for part in (conversation_context, user_message) if part)
    )
