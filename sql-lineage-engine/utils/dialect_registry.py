"""Canonical SQL dialect profiles shared by parser entry points."""

from dataclasses import dataclass
import re
from typing import Dict, Iterable, Optional, Tuple


@dataclass(frozen=True)
class DialectProfile:
    """Map one public dialect name to the parser-specific dialect names."""

    name: str
    sqlglot_dialect: Optional[str]
    gsp_dialect: str
    aliases: Tuple[str, ...] = ()
    path_markers: Tuple[str, ...] = ()
    detection_patterns: Tuple[str, ...] = ()


_PROFILES = (
    DialectProfile(
        name="mysql",
        sqlglot_dialect="mysql",
        gsp_dialect="mysql",
    ),
    DialectProfile(
        name="oracle",
        sqlglot_dialect="oracle",
        gsp_dialect="oracle",
        detection_patterns=(
            r"\bNVL\s*\(",
            r"\bDECODE\s*\(",
            r"\bTO_CHAR\s*\(",
            r"\bTO_DATE\s*\(",
            r"\bSYSDATE\b",
            r"\bFROM\s+DUAL\b",
            r"CREATE\s+(?:OR\s+REPLACE\s+)?PROCEDURE",
            r"\bVARCHAR2\b",
            r"\bDBMS_OUTPUT\b",
            r"\bBEGIN\s*$",
            r"\bEND\s*;\s*$",
        ),
    ),
    DialectProfile(
        name="hive",
        sqlglot_dialect="hive",
        gsp_dialect="hive",
        detection_patterns=(
            r"\bPARTITIONED\s+BY\b",
            r"\bCLUSTERED\s+BY\b",
            r"\bROW\s+FORMAT\b",
            r"\bSTORED\s+AS\b",
            r"\bLATERAL\s+VIEW\b",
            r"\bEXPLODE\s*\(",
            r"\bASC\s+NULLS\s+(?:FIRST|LAST)\b",
            r"(?s)^\s*FROM\s+.*\bINSERT\s+INTO\b",
        ),
    ),
    DialectProfile(
        name="spark",
        sqlglot_dialect="spark",
        gsp_dialect="hive",
    ),
    DialectProfile(
        name="postgresql",
        sqlglot_dialect="postgres",
        gsp_dialect="postgresql",
        aliases=("postgres",),
    ),
    DialectProfile(
        name="sqlserver",
        sqlglot_dialect="tsql",
        gsp_dialect="sqlserver",
        aliases=("tsql", "t-sql"),
    ),
    DialectProfile(
        name="gbase_8a",
        sqlglot_dialect="mysql",
        gsp_dialect="mysql",
        aliases=("gbase",),
    ),
    DialectProfile(
        name="gbase_8s",
        sqlglot_dialect=None,
        gsp_dialect="informix",
    ),
    DialectProfile(
        name="gbase_legacy_oracle",
        sqlglot_dialect="oracle",
        gsp_dialect="gbase",
    ),
    DialectProfile(
        name="presto",
        sqlglot_dialect="presto",
        gsp_dialect="mysql",
    ),
    DialectProfile(
        name="trino",
        sqlglot_dialect="trino",
        gsp_dialect="mysql",
    ),
    DialectProfile(
        name="bigquery",
        sqlglot_dialect="bigquery",
        gsp_dialect="mysql",
    ),
    DialectProfile(
        name="snowflake",
        sqlglot_dialect="snowflake",
        gsp_dialect="mysql",
    ),
)


def _normalize_dialect_name(value: str) -> str:
    return str(value or "").strip().lower()


def _build_indexes() -> tuple[Dict[str, DialectProfile], Dict[str, DialectProfile]]:
    by_name: Dict[str, DialectProfile] = {}
    by_alias: Dict[str, DialectProfile] = {}
    for profile in _PROFILES:
        canonical = _normalize_dialect_name(profile.name)
        if not canonical or canonical in by_name:
            raise ValueError(f"Duplicate SQL dialect profile: {profile.name}")
        by_name[canonical] = profile
        for alias in (profile.name, *profile.aliases):
            normalized_alias = _normalize_dialect_name(alias)
            existing = by_alias.get(normalized_alias)
            if existing and existing.name != profile.name:
                raise ValueError(f"Duplicate SQL dialect alias: {alias}")
            by_alias[normalized_alias] = profile
    return by_name, by_alias


DIALECT_PROFILES, _DIALECT_ALIASES = _build_indexes()


def iter_dialect_profiles() -> Iterable[DialectProfile]:
    return _PROFILES


def resolve_dialect_profile(dialect: str) -> DialectProfile:
    """Resolve a canonical name or alias to its immutable dialect profile."""

    normalized = _normalize_dialect_name(dialect)
    profile = _DIALECT_ALIASES.get(normalized)
    if profile is None:
        supported = ", ".join(sorted(_DIALECT_ALIASES))
        raise ValueError(
            f"Unsupported SQL dialect: {dialect!r}. Supported values: {supported}"
        )
    return profile


def canonicalize_dialect(dialect: str) -> str:
    return resolve_dialect_profile(dialect).name


def detect_sql_dialect(sql: str) -> Optional[str]:
    """Return the canonical dialect detected from SQL syntax, if any."""

    sql_upper = (sql or "").upper()
    best_profile = None
    best_score = 0
    for profile in _PROFILES:
        score = sum(
            1
            for pattern in profile.detection_patterns
            if re.search(pattern, sql_upper)
        )
        if score > best_score:
            best_profile = profile
            best_score = score
    return best_profile.name if best_profile else None


def detect_path_dialect(file_path: str) -> Optional[str]:
    """Return a canonical dialect when a complete path segment is an alias."""

    path_parts = [
        _normalize_dialect_name(part)
        for part in re.split(r"[\\/]+", str(file_path or ""))
        if part
    ]
    for part in reversed(path_parts):
        profile = DIALECT_PROFILES.get(part)
        if profile:
            return profile.name
    for part in reversed(path_parts):
        profile = _DIALECT_ALIASES.get(part)
        if profile:
            return profile.name
    for part in reversed(path_parts):
        for profile in _PROFILES:
            if part in {
                _normalize_dialect_name(marker) for marker in profile.path_markers
            }:
                return profile.name
    return None
