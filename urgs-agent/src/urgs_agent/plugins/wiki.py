import hashlib
import re
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Any, Literal

from pydantic import BaseModel, Field

from urgs_agent.plugins.contracts import ToolContext, ToolPlugin

ReadScope = Literal["wiki", "raw"]
SearchScope = Literal["wiki", "raw", "all"]
LogOperation = Literal["ingest", "query", "lint", "maintenance"]

TEXT_SUFFIXES = {
    ".csv",
    ".json",
    ".markdown",
    ".md",
    ".mdx",
    ".py",
    ".sql",
    ".ts",
    ".tsx",
    ".txt",
    ".yaml",
    ".yml",
}
SKIP_DIRS = {
    ".codex-batch",
    ".git",
    ".obsidian",
    ".openclaw",
    ".trash",
    ".venv",
    "__pycache__",
    "node_modules",
}
WIKI_LINK_RE = re.compile(r"\[\[([^\]\|#]+)(?:#[^\]\|]+)?(?:\|[^\]]+)?\]\]")
MARKDOWN_LINK_RE = re.compile(
    r"\[[^\]]+\]\(([^):#?]+(?:\.md|\.markdown)(?:#[^)]+)?)\)"
)


@dataclass(frozen=True)
class WikiFile:
    scope: ReadScope
    path: str
    absolute: Path


class WikiOverviewArgs(BaseModel):
    max_files: int = Field(default=80, ge=1, le=500)
    max_recent_log_entries: int = Field(default=10, ge=1, le=50)


class WikiReadArgs(BaseModel):
    scope: ReadScope = "wiki"
    path: str = Field(min_length=1, max_length=500)
    max_chars: int = Field(default=20000, ge=1, le=100000)


class WikiSearchArgs(BaseModel):
    query: str = Field(min_length=1, max_length=500)
    scope: SearchScope = "all"
    max_results: int = Field(default=12, ge=1, le=50)
    max_snippets: int = Field(default=3, ge=1, le=8)


class WikiWritePageArgs(BaseModel):
    path: str = Field(min_length=1, max_length=500)
    content: str = Field(min_length=1)
    expected_sha256: str | None = Field(default=None, min_length=64, max_length=64)


class WikiAppendLogArgs(BaseModel):
    operation: LogOperation
    title: str = Field(min_length=1, max_length=200)
    summary: str = Field(min_length=1, max_length=4000)
    paths: list[str] = Field(default_factory=list, max_length=30)


class KnowledgeWikiStore:
    def __init__(
        self,
        root: str,
        wiki_dir: str = ".",
        raw_dir: str = "raw",
        index_path: str = "index.md",
        log_path: str = "log.md",
        agent_guide_path: str = "AGENTS.md",
        max_file_bytes: int = 1_000_000,
        max_search_files: int = 1000,
    ) -> None:
        if not raw_dir.strip() or raw_dir.strip() == ".":
            raise ValueError("raw_dir must name a child directory")
        self.root = Path(root).expanduser().resolve(strict=False)
        self.wiki_dir = wiki_dir.strip() or "."
        self.raw_dir = raw_dir.strip()
        self.index_path = index_path.strip() or "index.md"
        self.log_path = log_path.strip() or "log.md"
        self.agent_guide_path = agent_guide_path.strip() or "AGENTS.md"
        self.max_file_bytes = max_file_bytes
        self.max_search_files = max_search_files

    @property
    def wiki_root(self) -> Path:
        return (self.root / self.wiki_dir).resolve(strict=False)

    @property
    def raw_root(self) -> Path:
        return (self.root / self.raw_dir).resolve(strict=False)

    def overview(self, max_files: int, max_recent_log_entries: int) -> dict[str, Any]:
        wiki_files = self._catalog("wiki", max_files)
        raw_files = self._catalog("raw", max_files)
        graph = self._link_health(wiki_files)
        return {
            "root": str(self.root),
            "wiki_root": str(self.wiki_root),
            "raw_root": str(self.raw_root),
            "exists": self.root.exists(),
            "agent_guide": self._optional_read("wiki", self.agent_guide_path, 20000),
            "index": self._optional_read("wiki", self.index_path, 8000),
            "recent_log_entries": self._recent_log_entries(max_recent_log_entries),
            "counts": {"wiki_files": len(wiki_files), "raw_files": len(raw_files)},
            "wiki_files": [self._file_summary(item) for item in wiki_files[:max_files]],
            "raw_files": [self._file_summary(item) for item in raw_files[:max_files]],
            "health": graph,
            "path_contract": (
                "Use paths returned by this tool. wiki_* tools read paths relative to wiki_root; "
                "raw reads paths relative to raw_root. "
                f"Agent guide: {self.agent_guide_path}; index: {self.index_path}; "
                f"log: {self.log_path}."
            ),
        }

    def read(self, scope: ReadScope, path: str, max_chars: int) -> dict[str, Any]:
        absolute = self._resolve(scope, path)
        if not absolute.exists():
            raise FileNotFoundError(f"wiki file not found: {scope}:{path}")
        if not absolute.is_file():
            raise IsADirectoryError(f"wiki path is not a file: {scope}:{path}")
        if not self._is_text_file(absolute):
            raise ValueError(f"wiki path is not a supported text file: {scope}:{path}")
        content = self._read_limited(absolute, max_chars + 1)
        returned = content[:max_chars]
        return {
            "scope": scope,
            "path": self._relative_path(scope, absolute),
            "title": self._title_from_text(returned, absolute),
            "sha256": self._sha256(absolute),
            "bytes": absolute.stat().st_size,
            "truncated": len(content) > max_chars,
            "content": returned,
        }

    def search(
        self, query: str, scope: SearchScope, max_results: int, max_snippets: int
    ) -> dict[str, Any]:
        terms = [term for term in re.split(r"\s+", query.casefold()) if term]
        query_casefold = query.casefold()
        scored: list[tuple[int, WikiFile, str, list[dict[str, Any]]]] = []
        skipped = 0
        search_files = self._iter_search_files(scope)
        for item in search_files:
            stat = item.absolute.stat()
            if stat.st_size > self.max_file_bytes:
                skipped += 1
                continue
            text = self._read_limited(item.absolute, self.max_file_bytes)
            score = self._score(query_casefold, terms, item.path, text)
            if score <= 0:
                continue
            snippets = self._snippets(text, query_casefold, terms, max_snippets)
            scored.append((score, item, text, snippets))
        scored.sort(key=lambda entry: (-entry[0], entry[1].scope, entry[1].path))
        results = [
            {
                "scope": item.scope,
                "path": item.path,
                "title": self._title_from_text(text, item.absolute),
                "score": score,
                "sha256": self._sha256(item.absolute),
                "snippets": snippets,
            }
            for score, item, text, snippets in scored[:max_results]
        ]
        return {
            "query": query,
            "scope": scope,
            "results": results,
            "searched_files": len(search_files),
            "skipped_large_files": skipped,
        }

    def write_page(
        self, path: str, content: str, expected_sha256: str | None = None
    ) -> dict[str, Any]:
        if not path.endswith((".md", ".markdown")):
            raise ValueError("wiki_write_page only writes markdown files")
        absolute = self._resolve("wiki", path)
        if self._is_under(absolute, self.raw_root):
            raise PermissionError("wiki_write_page cannot modify raw sources")
        if expected_sha256 is not None:
            if not absolute.exists():
                raise FileNotFoundError(f"cannot verify hash for missing page: {path}")
            actual = self._sha256(absolute)
            if actual != expected_sha256:
                raise ValueError(
                    f"sha256 mismatch for {path}: expected {expected_sha256}, got {actual}"
                )
        absolute.parent.mkdir(parents=True, exist_ok=True)
        normalized = content.rstrip() + "\n"
        absolute.write_text(normalized, encoding="utf-8")
        return {
            "scope": "wiki",
            "path": self._relative_path("wiki", absolute),
            "sha256": self._sha256(absolute),
            "bytes": absolute.stat().st_size,
        }

    def append_log(
        self, operation: LogOperation, title: str, summary: str, paths: list[str]
    ) -> dict[str, Any]:
        log_path = self._resolve("wiki", self.log_path)
        if self._is_under(log_path, self.raw_root):
            raise PermissionError("wiki_append_log cannot modify raw sources")
        log_path.parent.mkdir(parents=True, exist_ok=True)
        today = datetime.now().date().isoformat()
        referenced = "".join(f"- `{item}`\n" for item in paths)
        entry = f"\n## [{today}] {operation} | {title}\n\n{summary.strip()}\n"
        if referenced:
            entry = f"{entry}\n{referenced}"
        if log_path.exists() and log_path.stat().st_size > 0:
            with log_path.open("a", encoding="utf-8") as handle:
                handle.write(entry)
        else:
            log_path.write_text(entry.lstrip(), encoding="utf-8")
        return {
            "scope": "wiki",
            "path": self._relative_path("wiki", log_path),
            "sha256": self._sha256(log_path),
            "entry": entry.strip(),
        }

    def agent_guide_context(self, max_chars: int = 30000) -> str | None:
        guide = self._optional_read("wiki", self.agent_guide_path, max_chars)
        if guide is None:
            return (
                "## LLM Wiki Agent Guide\n\n"
                f"AGENTS.md was not found at `wiki:{self.agent_guide_path}`. "
                "Do not treat this run as fully initialized until the wiki guide is restored."
            )
        return (
            "## LLM Wiki Agent Guide\n\n"
            f"Source: `wiki:{guide['path']}`\n"
            f"SHA256: `{guide['sha256']}`\n\n"
            "The following rules are mandatory for this run:\n\n"
            f"{guide['content']}"
        )

    def _catalog(self, scope: ReadScope, limit: int) -> list[WikiFile]:
        return list(self._iter_files(scope, limit))

    def _iter_search_files(self, scope: SearchScope) -> list[WikiFile]:
        if scope == "all":
            return [
                *self._iter_files("wiki", self.max_search_files),
                *self._iter_files("raw", self.max_search_files),
            ]
        read_scope: ReadScope = "wiki" if scope == "wiki" else "raw"
        return list(self._iter_files(read_scope, self.max_search_files))

    def _iter_files(self, scope: ReadScope, limit: int) -> list[WikiFile]:
        base = self.wiki_root if scope == "wiki" else self.raw_root
        if not base.exists() or not base.is_dir():
            return []
        files: list[WikiFile] = []
        for absolute in sorted(base.rglob("*")):
            if len(files) >= limit:
                break
            if any(part in SKIP_DIRS for part in absolute.parts):
                continue
            if not absolute.is_file() or not self._is_text_file(absolute):
                continue
            if scope == "wiki" and self._is_under(absolute.resolve(strict=False), self.raw_root):
                continue
            files.append(
                WikiFile(scope=scope, path=self._relative_path(scope, absolute), absolute=absolute)
            )
        return files

    def _optional_read(
        self, scope: ReadScope, path: str, max_chars: int
    ) -> dict[str, Any] | None:
        absolute = self._resolve(scope, path)
        if not absolute.exists() or not absolute.is_file():
            return None
        data = self.read(scope, path, max_chars)
        return {
            key: data[key] for key in ("path", "title", "sha256", "truncated", "content")
        }

    def _recent_log_entries(self, limit: int) -> list[str]:
        log_path = self._resolve("wiki", self.log_path)
        if not log_path.exists() or not log_path.is_file():
            return []
        text = self._read_limited(log_path, self.max_file_bytes)
        entries = [line.strip() for line in text.splitlines() if line.startswith("## [")]
        return entries[-limit:]

    def _file_summary(self, item: WikiFile) -> dict[str, Any]:
        stat = item.absolute.stat()
        text = self._read_limited(item.absolute, 4000)
        return {
            "scope": item.scope,
            "path": item.path,
            "title": self._title_from_text(text, item.absolute),
            "bytes": stat.st_size,
            "updated_at": datetime.fromtimestamp(stat.st_mtime).isoformat(timespec="seconds"),
        }

    def _link_health(self, wiki_files: list[WikiFile]) -> dict[str, Any]:
        paths = {item.path for item in wiki_files}
        stems = {Path(item.path).stem: item.path for item in wiki_files}
        inbound = {item.path: 0 for item in wiki_files}
        missing: set[str] = set()
        for item in wiki_files:
            text = self._read_limited(item.absolute, self.max_file_bytes)
            for target in self._link_targets(item.path, text):
                resolved = self._resolve_link_target(target, paths, stems)
                if resolved is None:
                    missing.add(target)
                elif resolved in inbound and resolved != item.path:
                    inbound[resolved] += 1
        exempt_paths = {self.agent_guide_path, self.index_path, self.log_path}
        orphans = [
            path
            for path, count in inbound.items()
            if count == 0 and path not in exempt_paths
        ]
        return {
            "orphan_pages": sorted(orphans)[:50],
            "missing_link_targets": sorted(missing)[:50],
            "checked_pages": len(wiki_files),
        }

    def _link_targets(self, source_path: str, text: str) -> set[str]:
        targets: set[str] = set()
        for raw_target in WIKI_LINK_RE.findall(text):
            target = raw_target.strip()
            if target:
                targets.add(
                    target if target.endswith((".md", ".markdown")) else f"{target}.md"
                )
        source_parent = Path(source_path).parent
        for raw_target in MARKDOWN_LINK_RE.findall(text):
            target = raw_target.split("#", 1)[0].strip()
            if not target or "://" in target:
                continue
            targets.add((source_parent / target).as_posix())
        return targets

    def _resolve_link_target(
        self, target: str, paths: set[str], stems: dict[str, str]
    ) -> str | None:
        normalized = self._normalize_link_path(target)
        if normalized in paths:
            return normalized
        stem_match = stems.get(Path(normalized).stem)
        return stem_match

    def _normalize_link_path(self, target: str) -> str:
        return Path(target.strip().lstrip("/")).as_posix()

    def _resolve(self, scope: ReadScope, path: str) -> Path:
        clean = self._clean_relative_path(path)
        base = self.wiki_root if scope == "wiki" else self.raw_root
        absolute = (base / clean).resolve(strict=False)
        if not self._is_under(absolute, base):
            raise PermissionError(f"path escapes {scope} root: {path}")
        return absolute

    def _relative_path(self, scope: ReadScope, absolute: Path) -> str:
        base = self.wiki_root if scope == "wiki" else self.raw_root
        return absolute.resolve(strict=False).relative_to(base).as_posix()

    def _clean_relative_path(self, path: str) -> Path:
        if "\x00" in path:
            raise ValueError("path contains NUL byte")
        candidate = Path(path)
        if candidate.is_absolute():
            raise PermissionError("absolute paths are not allowed")
        if any(part in {"", ".", ".."} for part in candidate.parts):
            raise PermissionError(f"path traversal is not allowed: {path}")
        return candidate

    def _is_text_file(self, path: Path) -> bool:
        return path.suffix.casefold() in TEXT_SUFFIXES

    def _is_under(self, child: Path, parent: Path) -> bool:
        try:
            child.resolve(strict=False).relative_to(parent.resolve(strict=False))
        except ValueError:
            return False
        return True

    def _read_limited(self, path: Path, max_chars: int) -> str:
        with path.open("r", encoding="utf-8", errors="replace") as handle:
            return handle.read(max_chars)

    def _sha256(self, path: Path) -> str:
        digest = hashlib.sha256()
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()

    def _title_from_text(self, text: str, path: Path) -> str:
        for line in text.splitlines():
            stripped = line.strip()
            if stripped.startswith("#"):
                return stripped.lstrip("#").strip() or path.stem
        return path.stem

    def _score(self, query: str, terms: list[str], path: str, text: str) -> int:
        haystack = text.casefold()
        score = haystack.count(query) * 10
        score += path.casefold().count(query) * 20
        for term in terms:
            score += haystack.count(term)
            score += path.casefold().count(term) * 5
        return score

    def _snippets(
        self, text: str, query: str, terms: list[str], max_snippets: int
    ) -> list[dict[str, Any]]:
        needles = [query, *terms]
        snippets: list[dict[str, Any]] = []
        used_offsets: set[int] = set()
        haystack = text.casefold()
        for needle in needles:
            if not needle:
                continue
            start = haystack.find(needle)
            while start >= 0 and len(snippets) < max_snippets:
                window_start = max(0, start - 120)
                if window_start not in used_offsets:
                    window_end = min(len(text), start + len(needle) + 180)
                    snippet = " ".join(text[window_start:window_end].split())
                    snippets.append(
                        {"line": text.count("\n", 0, start) + 1, "text": snippet}
                    )
                    used_offsets.add(window_start)
                start = haystack.find(needle, start + len(needle))
        return snippets


class WikiOverviewTool(ToolPlugin):
    name = "wiki_overview"
    description = (
        "Inspect the configured LLM wiki, including index, recent log, files, and link health."
    )
    args_schema = WikiOverviewArgs
    required_permissions = frozenset({"knowledge:read"})

    def __init__(self, store: KnowledgeWikiStore) -> None:
        self.store = store

    async def system_context(self, context: ToolContext) -> str | None:
        return self.store.agent_guide_context()

    async def execute(
        self, arguments: dict[str, Any], context: ToolContext
    ) -> dict[str, Any]:
        args = self.args_schema.model_validate(arguments)
        return self.store.overview(args.max_files, args.max_recent_log_entries)


class WikiReadTool(ToolPlugin):
    name = "wiki_read"
    description = "Read a markdown or text file from the wiki or raw-source layer."
    args_schema = WikiReadArgs
    required_permissions = frozenset({"knowledge:read"})

    def __init__(self, store: KnowledgeWikiStore) -> None:
        self.store = store

    async def execute(
        self, arguments: dict[str, Any], context: ToolContext
    ) -> dict[str, Any]:
        args = self.args_schema.model_validate(arguments)
        return self.store.read(args.scope, args.path, args.max_chars)


class WikiSearchTool(ToolPlugin):
    name = "wiki_search"
    description = "Search markdown and text files in the LLM wiki and raw-source layers."
    args_schema = WikiSearchArgs
    required_permissions = frozenset({"knowledge:read"})

    def __init__(self, store: KnowledgeWikiStore) -> None:
        self.store = store

    async def execute(
        self, arguments: dict[str, Any], context: ToolContext
    ) -> dict[str, Any]:
        args = self.args_schema.model_validate(arguments)
        return self.store.search(args.query, args.scope, args.max_results, args.max_snippets)


class WikiWritePageTool(ToolPlugin):
    name = "wiki_write_page"
    description = "Create or replace a markdown page in the generated wiki layer."
    args_schema = WikiWritePageArgs
    required_permissions = frozenset({"knowledge:write"})
    idempotent = False

    def __init__(self, store: KnowledgeWikiStore) -> None:
        self.store = store

    async def execute(
        self, arguments: dict[str, Any], context: ToolContext
    ) -> dict[str, Any]:
        args = self.args_schema.model_validate(arguments)
        return self.store.write_page(args.path, args.content, args.expected_sha256)


class WikiAppendLogTool(ToolPlugin):
    name = "wiki_append_log"
    description = "Append a parseable chronological entry to wiki log.md."
    args_schema = WikiAppendLogArgs
    required_permissions = frozenset({"knowledge:write"})
    idempotent = False

    def __init__(self, store: KnowledgeWikiStore) -> None:
        self.store = store

    async def execute(
        self, arguments: dict[str, Any], context: ToolContext
    ) -> dict[str, Any]:
        args = self.args_schema.model_validate(arguments)
        return self.store.append_log(args.operation, args.title, args.summary, args.paths)
