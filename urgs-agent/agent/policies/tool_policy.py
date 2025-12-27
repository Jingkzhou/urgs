from dataclasses import dataclass
from typing import Any, Dict, List, Optional

from core.config import Settings, get_settings

WRITE_PREFIXES = ("create", "update", "delete", "rerun", "trigger")


@dataclass
class ToolMetadata:
    name: str
    side_effect: bool = False
    description: Optional[str] = None
    schema: Optional[Dict[str, Any]] = None


class ToolPolicy:
    def __init__(self, settings: Optional[Settings] = None):
        self.settings = settings or get_settings()

    def filter_allowlist(self, tools: List[ToolMetadata]) -> List[ToolMetadata]:
        if not self.settings.allowlist_tools:
            return tools
        return [tool for tool in tools if tool.name in self.settings.allowlist_tools]

    def is_allowed(self, tool_name: str) -> bool:
        if not self.settings.allowlist_tools:
            return True
        return tool_name in self.settings.allowlist_tools

    def requires_approval(self, metadata: ToolMetadata) -> bool:
        if metadata.side_effect and self.settings.require_approval_for_side_effect:
            return True
        return metadata.name.startswith(WRITE_PREFIXES)

    def summarize_args(self, args: Dict[str, Any], max_length: int = 200) -> Dict[str, Any]:
        digest: Dict[str, Any] = {}
        for key, value in args.items():
            text = str(value)
            digest[key] = text if len(text) <= max_length else f"{text[:max_length]}..."
        return digest
