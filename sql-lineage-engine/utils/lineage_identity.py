import hashlib
import re
from typing import Any, Dict


def normalize_sql_for_hash(sql: str) -> str:
    if not sql:
        return ""
    normalized = re.sub(r"/\*.*?\*/", " ", sql, flags=re.DOTALL)
    normalized = re.sub(r"--.*?$", " ", normalized, flags=re.MULTILINE)
    normalized = re.sub(r"\s+", " ", normalized).strip()
    if normalized.endswith(";"):
        normalized = normalized[:-1].strip()
    return normalized.upper()


def stable_hash(*parts: Any) -> str:
    digest = hashlib.sha256()
    for part in parts:
        digest.update(str(part or "").encode("utf-8"))
        digest.update(b"|")
    return digest.hexdigest()


def statement_hash(sql: str) -> str:
    normalized = normalize_sql_for_hash(sql)
    if not normalized:
        return ""
    return hashlib.sha256(normalized.encode("utf-8")).hexdigest()


def parser_statement_uid(source_file: str, statement_index: int, sql: str) -> str:
    return stable_hash(source_file or "", statement_index, statement_hash(sql))


def scoped_statement_uid(version: str, repo_id: str, parser_uid: str) -> str:
    return stable_hash(version or "", repo_id or "", parser_uid or "")


def relation_uid(version: str, repo_id: str, relation: Dict[str, Any]) -> str:
    return stable_hash(
        version or "",
        repo_id or "",
        relation.get("statementUid") or relation.get("statement_uid"),
        relation.get("relationType") or relation.get("neo4j_type") or relation.get("dependency_type"),
        relation.get("sourceTable") or relation.get("source_table") or relation.get("source"),
        relation.get("sourceColumn") or relation.get("source_column"),
        relation.get("targetTable") or relation.get("target_table") or relation.get("target"),
        relation.get("targetColumn") or relation.get("target_column"),
        relation.get("projectionIndex") if relation.get("projectionIndex") is not None else relation.get("projection_index"),
        relation.get("sourceExpression") or relation.get("source_expression"),
        relation.get("targetExpression") or relation.get("target_expression"),
    )
