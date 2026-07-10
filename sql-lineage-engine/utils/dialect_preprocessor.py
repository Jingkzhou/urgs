"""Dialect-specific, lineage-safe SQL normalization before SQLGlot parsing."""

import re


def preprocess_for_sqlglot(sql: str, dialect_name: str) -> str:
    """Return a parser view while callers retain the original SQL as evidence."""
    if dialect_name == "gbase_8a":
        return _normalize_gbase_8a(sql)
    if dialect_name in {"oracle", "gbase_legacy_oracle"}:
        return _mask_oracle_q_quotes(sql)
    return sql


def _normalize_gbase_8a(sql: str) -> str:
    if not sql:
        return sql

    code_view = _code_view(sql)
    replace_match = re.match(r"(?is)^(\s*)REPLACE(?=\s+INTO\b)", code_view)
    if replace_match:
        word_start = len(replace_match.group(1))
        sql = f"{sql[:word_start]}INSERT{sql[replace_match.end():]}"
        code_view = _code_view(sql)

    spans = []
    for match in re.finditer(r"(?i)\bDISTRIBUTED\s+BY\s*", code_view):
        end = _balanced_suffix_end(code_view, match.end())
        spans.append((match.start(), end))
    for match in re.finditer(r"(?i)\bCOMPRESS\s*", code_view):
        end = _balanced_suffix_end(code_view, match.end())
        spans.append((match.start(), end))
    for match in re.finditer(r"(?i)\bREPLICATED\b", code_view):
        spans.append((match.start(), match.end()))

    if not spans:
        return sql
    return _remove_spans(sql, spans)


def _mask_oracle_q_quotes(sql: str) -> str:
    """Replace alternative-quoted constants in the parser view only."""
    chunks = []
    cursor = 0
    index = 0
    quote = None
    in_line_comment = False
    in_block_comment = False
    while index < len(sql):
        char = sql[index]
        next_char = sql[index + 1] if index + 1 < len(sql) else ""

        if in_line_comment:
            if char == "\n":
                in_line_comment = False
            index += 1
            continue
        if in_block_comment:
            if char == "*" and next_char == "/":
                in_block_comment = False
                index += 2
            else:
                index += 1
            continue
        if quote:
            if char == quote:
                if next_char == quote:
                    index += 2
                    continue
                quote = None
            index += 1
            continue

        if char == "-" and next_char == "-":
            in_line_comment = True
            index += 2
            continue
        if char == "/" and next_char == "*":
            in_block_comment = True
            index += 2
            continue
        if char in {'"', "`"}:
            quote = char
            index += 1
            continue
        if char == "'":
            quote = char
            index += 1
            continue

        if char in {"q", "Q"} and next_char == "'" and index + 2 < len(sql):
            opening = sql[index + 2]
            closing = {"[": "]", "{": "}", "(": ")", "<": ">"}.get(
                opening, opening
            )
            end_marker = f"{closing}'"
            end = sql.find(end_marker, index + 3)
            if end >= 0:
                chunks.append(sql[cursor:index])
                chunks.append("''")
                cursor = end + len(end_marker)
                index = cursor
                continue
        index += 1

    if not chunks:
        return sql
    chunks.append(sql[cursor:])
    return "".join(chunks)


def _balanced_suffix_end(code_view: str, index: int) -> int:
    while index < len(code_view) and code_view[index].isspace():
        index += 1
    if index >= len(code_view) or code_view[index] != "(":
        return index
    depth = 0
    for position in range(index, len(code_view)):
        char = code_view[position]
        if char == "(":
            depth += 1
        elif char == ")":
            depth -= 1
            if depth == 0:
                return position + 1
    return len(code_view)


def _remove_spans(sql: str, spans) -> str:
    merged = []
    for start, end in sorted(spans):
        if merged and start <= merged[-1][1]:
            merged[-1] = (merged[-1][0], max(merged[-1][1], end))
        else:
            merged.append((start, end))

    chunks = []
    cursor = 0
    for start, end in merged:
        chunks.append(sql[cursor:start])
        chunks.append(" ")
        cursor = end
    chunks.append(sql[cursor:])
    return "".join(chunks)


def _code_view(sql: str) -> str:
    """Mask quoted/comment content while preserving offsets and code punctuation."""
    chars = list(sql)
    quote = None
    in_line_comment = False
    in_block_comment = False
    index = 0
    while index < len(chars):
        char = chars[index]
        next_char = chars[index + 1] if index + 1 < len(chars) else ""

        if in_line_comment:
            if char == "\n":
                in_line_comment = False
            else:
                chars[index] = " "
            index += 1
            continue
        if in_block_comment:
            chars[index] = " "
            if char == "*" and next_char == "/":
                chars[index + 1] = " "
                in_block_comment = False
                index += 2
            else:
                index += 1
            continue
        if quote:
            chars[index] = " "
            if char == quote:
                if next_char == quote:
                    chars[index + 1] = " "
                    index += 2
                    continue
                quote = None
            index += 1
            continue

        if char == "-" and next_char == "-":
            chars[index] = chars[index + 1] = " "
            in_line_comment = True
            index += 2
            continue
        if char == "/" and next_char == "*":
            chars[index] = chars[index + 1] = " "
            in_block_comment = True
            index += 2
            continue
        if char in {"'", '"', "`"}:
            chars[index] = " "
            quote = char
        index += 1
    return "".join(chars)
