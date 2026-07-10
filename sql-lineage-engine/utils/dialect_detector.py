"""SQL dialect detection backed by the canonical dialect registry."""

from typing import Optional

from utils.dialect_registry import DIALECT_PROFILES, detect_sql_dialect


# Preserve these public constants for callers that import the legacy module directly.
ORACLE_PATTERNS = list(DIALECT_PROFILES["oracle"].detection_patterns)
HIVE_PATTERNS = list(DIALECT_PROFILES["hive"].detection_patterns)


def detect_dialect(sql: str, default: str = "mysql") -> Optional[str]:
    """
    启发式方言探测。
    返回 'oracle' / 'hive' 或 None（保持 default）。

    Args:
        sql: SQL语句
        default: 默认方言（当无法检测时使用）

    Returns:
        检测到的方言名称，或None（表示使用default）
    """
    return detect_sql_dialect(sql)
