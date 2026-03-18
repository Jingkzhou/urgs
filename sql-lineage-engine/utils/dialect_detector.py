"""
SQL方言检测工具模块

用于启发式检测SQL语句的方言类型（Oracle、Hive等）
"""

import re
from typing import Optional

ORACLE_PATTERNS = [
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
]

HIVE_PATTERNS = [
    r"\bPARTITIONED\s+BY\b",
    r"\bCLUSTERED\s+BY\b",
    r"\bROW\s+FORMAT\b",
    r"\bSTORED\s+AS\b",
    r"\bLATERAL\s+VIEW\b",
    r"\bEXPLODE\s*\(",
    r"\bASC\s+NULLS\s+(?:FIRST|LAST)\b",
    r"(?s)^\s*FROM\s+.*\bINSERT\s+INTO\b",
]


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
    sql_upper = sql.upper()

    for pattern in ORACLE_PATTERNS:
        if re.search(pattern, sql_upper):
            return "oracle"

    for pattern in HIVE_PATTERNS:
        if re.search(pattern, sql_upper):
            return "hive"

    return None
