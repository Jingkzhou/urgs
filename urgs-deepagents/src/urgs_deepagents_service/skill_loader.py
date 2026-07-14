"""Generic loader for packaged, declarative Agent Skills."""

from __future__ import annotations

import importlib.util
import json
import re
import sys
from collections.abc import Sequence
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from langchain_core.tools import StructuredTool

_SKILL_CODE_PATTERN = re.compile(r"^[a-z][a-z0-9-]*$")


class SkillConfigurationError(ValueError):
    """Raised when a packaged Skill cannot be loaded safely."""


@dataclass(frozen=True)
class SkillRuntime:
    instructions: str
    tools: tuple[StructuredTool, ...]
    tool_names: frozenset[str]


def normalize_skill_dirs(value: str | Sequence[str] | None) -> list[str]:
    if value is None:
        return []
    if isinstance(value, str):
        return [item.strip() for item in value.replace(";", ",").split(",") if item.strip()]
    return [str(item).strip() for item in value if str(item).strip()]


def load_agent_skill_runtime(
    settings: Any,
    agent_code: str | None,
    skill_dirs: str | Sequence[str] | None,
    runtime_context: dict[str, Any] | None = None,
) -> SkillRuntime | None:
    """Load the sole configured packaged runtime without embedding domain logic in Sidecar."""

    directories = normalize_skill_dirs(skill_dirs)
    if not directories:
        return None
    if len(directories) != 1 or not _SKILL_CODE_PATTERN.fullmatch(directories[0]):
        raise SkillConfigurationError("带运行时的 Agent 必须且只能配置一个合法 Skill")
    skills_root = Path(str(getattr(settings, "skills_root", "skills"))).expanduser().resolve()
    skill_dir = (skills_root / directories[0]).resolve()
    if not skills_root.is_dir() or skill_dir.parent != skills_root or not skill_dir.is_dir():
        raise SkillConfigurationError("Skill 根目录或路径无效")
    try:
        manifest = json.loads((skill_dir / "skill.json").read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        raise SkillConfigurationError("Skill 的 skill.json 无法解析") from exc
    if not isinstance(manifest, dict) or manifest.get("agent_code") != agent_code:
        return None
    if manifest.get("runtime_entrypoint") != "runtime.py":
        raise SkillConfigurationError("Skill runtime_entrypoint 必须是 runtime.py")
    runtime_file = skill_dir / "runtime.py"
    if not runtime_file.is_file():
        raise SkillConfigurationError("Skill 缺少运行时入口 runtime.py")
    spec = importlib.util.spec_from_file_location(
        f"urgs_skill_{directories[0].replace('-', '_')}", runtime_file
    )
    if spec is None or spec.loader is None:
        raise SkillConfigurationError("Skill 运行时入口无法加载")
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    factory = getattr(module, "create_skill_runtime", None)
    if not callable(factory):
        raise SkillConfigurationError("Skill 运行时缺少 create_skill_runtime")
    runtime = factory(skill_dir, runtime_context)
    if not isinstance(runtime, SkillRuntime):
        raise SkillConfigurationError("Skill 运行时返回结果无效")
    return runtime
