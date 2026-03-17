import os
import re
from typing import List

class SqlSplitter:
    """
    Helper class to split SQL scripts into individual statements.
    Respects quotes (', ", `) and comments (--, #, /*...*/)
    """
    
    @staticmethod
    def get_char_limit() -> int:
        return int(os.environ.get("SQLFLOW_CHAR_LIMIT", 10000))

    @staticmethod
    def split(sql: str) -> List[str]:
        if not sql:
            return []
            
        statements = []
        current_stmt = []
        
        # State
        in_single_quote = False
        in_double_quote = False
        in_backtick = False
        in_block_comment = False
        in_line_comment = False 
        
        delimiter = ";"
        
        i = 0
        n = len(sql)
        
        while i < n:
            char = sql[i]
            
            # Check for comments start
            if not (in_single_quote or in_double_quote or in_backtick or in_block_comment or in_line_comment):
                if char == '-' and i + 1 < n and sql[i+1] == '-':
                    in_line_comment = True
                    current_stmt.append(char)
                    i += 1
                    current_stmt.append(sql[i])
                    i += 1
                    continue
                elif char == '#' and (i==0 or sql[i-1].isspace()): 
                    in_line_comment = True
                    current_stmt.append(char)
                    i += 1
                    continue
                elif char == '/' and i + 1 < n and sql[i+1] == '*':
                    in_block_comment = True
                    current_stmt.append(char)
                    i += 1
                    current_stmt.append(sql[i])
                    i += 1
                    continue
                
                # Check for DELIMITER command
                if (len(current_stmt) == 0 or "".join(current_stmt).strip() == ""):
                    # Check match
                    remainder = sql[i:]
                    if len(remainder) >= 10 and remainder[:10].upper().startswith("DELIMITER "):
                        # Found DELIMITER command
                        # Find end of line
                        eol = remainder.find('\n')
                        if eol == -1:
                            line = remainder
                            i = n # Finish
                        else:
                            line = remainder[:eol]
                            i += eol # Skip to end of line
                            
                        # Extract new delimiter
                        parts = line.strip().split()
                        if len(parts) >= 2:
                            delimiter = parts[1]
                        
                        # Clear current_stmt (consume directive)
                        current_stmt = []
                        continue

            # Check for comments end
            if in_line_comment:
                current_stmt.append(char)
                if char == '\n':
                    in_line_comment = False
                i += 1
                continue
                
            if in_block_comment:
                current_stmt.append(char)
                if char == '*' and i + 1 < n and sql[i+1] == '/':
                    in_block_comment = False
                    i += 1
                    current_stmt.append(sql[i])
                i += 1
                continue
            
            # Check for quotes
            if char == "'" and not (in_double_quote or in_backtick):
                if not in_single_quote:
                    in_single_quote = True
                else:
                    if i + 1 < n and sql[i+1] == "'":
                        current_stmt.append(char)
                        i += 1
                        current_stmt.append(sql[i])
                        i += 1
                        continue
                    in_single_quote = False
            
            elif char == '"' and not (in_single_quote or in_backtick):
                if not in_double_quote:
                    in_double_quote = True
                else:
                    if i + 1 < n and sql[i+1] == '"':
                        current_stmt.append(char)
                        i += 1
                        current_stmt.append(sql[i])
                        i += 1
                        continue
                    in_double_quote = False
            
            elif char == '`' and not (in_single_quote or in_double_quote):
                 if not in_backtick:
                    in_backtick = True
                 else:
                    if i + 1 < n and sql[i+1] == '`':
                        current_stmt.append(char)
                        i += 1
                        current_stmt.append(sql[i])
                        i += 1
                        continue
                    in_backtick = False
            
            # Dynamic Delimiter check
            if not (in_single_quote or in_double_quote or in_backtick):
                # Lookahead for delimiter
                delim_len = len(delimiter)
                if sql[i:i+delim_len] == delimiter:
                    stmt = "".join(current_stmt).strip()
                    if stmt:
                        statements.append(stmt)
                    current_stmt = []
                    i += delim_len
                    continue
                
            current_stmt.append(char)
            i += 1
            
        # Append last statement
        stmt = "".join(current_stmt).strip()
        if stmt:
            statements.append(stmt)
        return statements

    @staticmethod
    def smart_split(sql: str, limit: int = None) -> List[str]:
        """
        Smartly identify and split large SQL statements into smaller valid statements.
        Prioritizes:
        1. Splitting multi-row VALUES (INSERT ... VALUES)
        2. Splitting UNION ALL (INSERT ... SELECT ... UNION ALL ...)
        3. Splitting columns (INSERT ... SELECT or INSERT ... VALUES single row)
        """
        if limit is None:
            limit = SqlSplitter.get_char_limit()
            
        # Optimization: remove comments to ensure robust splitting and reduce size
        # Strategies rely on regex/parsing that can be confused by comments.
        sql = SqlSplitter.remove_comments(sql)
        
        if len(sql) <= limit:
            return [sql]
            
        # Strategy 1: VALUES multi-row split
        chunks = SqlSplitter.split_values_rows(sql, limit)
        if len(chunks) > 1:
            final_chunks = []
            for chunk in chunks:
                if len(chunk) > limit:
                     # Recursive attempt (though split_values_rows usually does best effort)
                     # Maybe try strategy 3 on the chunk if it is a single row?
                     # For now, let's just recurse smart_split
                     final_chunks.extend(SqlSplitter.smart_split(chunk, limit))
                else:
                    final_chunks.append(chunk)
            return final_chunks
            
        # Strategy 2: UNION ALL split
        chunks = SqlSplitter.split_union_all(sql)
        if len(chunks) > 1:
             final_chunks = []
             for chunk in chunks:
                final_chunks.extend(SqlSplitter.smart_split(chunk, limit))
             return final_chunks
             
        # Strategy 3: Column split
        # Check if it is INSERT SELECT or INSERT VALUES
        # Try split_large_insert_select first (handles SELECT)
        chunks = SqlSplitter.split_large_insert_select(sql, limit)
        if len(chunks) > 1:
             # Recursion unlikely needed for column split as it targets limit, but good to have
             final_chunks = []
             for chunk in chunks:
                 if len(chunk) > limit:
                     # If still too big, maybe we can't split further or logic failed
                     # Could try VALUES column split if it was misidentified? Unlikely.
                     final_chunks.append(chunk) 
                 else:
                     final_chunks.append(chunk)
             return final_chunks

        # Try split_large_insert_values_columns (handles wide VALUES single row)
        chunks = SqlSplitter.split_large_insert_values_columns(sql, limit)
        if len(chunks) > 1:
             return chunks

        # If all fail
        return [sql]

    @staticmethod
    def split_values_rows(sql: str, max_length: int = 8000) -> List[str]:
        """
        Strategy 1: Split a large INSERT statement with multiple VALUES rows into multiple statements.
        INSERT INTO table VALUES (...), (...), (...) -> INSERT INTO ... VALUES (...); ...
        """
        # Check if length warrants splitting
        if len(sql) <= max_length:
            return [sql]
            
        # Regex to capture prelude and values part.
        match = re.match(r"(?i)(INSERT\s+INTO\s+.*?\s+VALUES)\s*(.*)", sql, re.DOTALL)
        if not match:
            return [sql]
            
        prelude = match.group(1)
        values_str = match.group(2).strip()
        
        if values_str.endswith(";"):
             values_str = values_str[:-1].strip()
             
        # Parse values list: (v1, v2), (v3, v4), ...
        rows = []
        current_row = []
        
        # State
        in_single_quote = False
        in_double_quote = False
        paren_depth = 0
        
        i = 0
        n = len(values_str)
        
        while i < n:
            char = values_str[i]
            
            if char == "'" and not in_double_quote:
                 in_single_quote = not in_single_quote
            elif char == '"' and not in_single_quote:
                 in_double_quote = not in_double_quote
            elif char == '(' and not (in_single_quote or in_double_quote):
                 paren_depth += 1
            elif char == ')' and not (in_single_quote or in_double_quote):
                 paren_depth -= 1
            elif char == ',' and not (in_single_quote or in_double_quote) and paren_depth == 0:
                 # Found a row separator
                 rows.append("".join(current_row).strip())
                 current_row = []
                 i += 1
                 continue
                 
            current_row.append(char)
            i += 1
            
        if current_row:
             rows.append("".join(current_row).strip())
             
        if len(rows) <= 1:
            # Single row or parse fail, strategy 1 not applicable/helpful for single row
            return [sql]

        # Now chunk rows
        chunks = []
        current_chunk_rows = []
        current_chunk_len = len(prelude)
        
        for row in rows:
             row_len = len(row) + 2 # comma + space approximation
             
             if current_chunk_len + row_len > max_length and current_chunk_rows:
                 # Flush current chunk
                 chunks.append(f"{prelude} {', '.join(current_chunk_rows)};")
                 current_chunk_rows = []
                 current_chunk_len = len(prelude)
             
             current_chunk_rows.append(row)
             current_chunk_len += row_len
             
        if current_chunk_rows:
             chunks.append(f"{prelude} {', '.join(current_chunk_rows)};")
             
        return chunks

    @staticmethod
    def split_union_all(sql: str) -> List[str]:
        """
        Strategy 2: Split INSERT ... SELECT ... UNION ALL SELECT ...
        """
        # Regex check basic pattern
        if "UNION ALL" not in sql.upper():
            return [sql]
            
        # Match: INSERT INTO table SELECT ... UNION ALL SELECT ...
        # logic: 
        # 1. Identify prefix "INSERT INTO table "
        # 2. Identify first "SELECT"
        # 3. Split by "UNION ALL" at depth 0
        
        # Find prefix
        match = re.match(r"(?i)(INSERT\s+INTO\s+.*?)\s+(SELECT\s+.*)", sql, re.DOTALL)
        if not match:
             return [sql]
             
        prefix = match.group(1).strip()
        rest = match.group(2).strip()
        
        if rest.endswith(";"):
            rest = rest[:-1].strip()
            
        # Split `rest` by "UNION ALL" respecting quotes/parens
        parts = []
        current_part = []
        
        # Tokenizer-ish approach
        # Look for "UNION ALL" sequence
        
        i = 0
        n = len(rest)
        in_single = False
        in_double = False
        paren_depth = 0
        
        # To avoid complex lookahead in loop, we can just iterate.
        # But we need to match "UNION" then space then "ALL".
        
        while i < n:
            char = rest[i]
            
            if char == "'" and not in_double:
                in_single = not in_single
            elif char == '"' and not in_single:
                in_double = not in_double
            elif char == '(' and not (in_single or in_double):
                paren_depth += 1
            elif char == ')' and not (in_single or in_double):
                paren_depth -= 1
            
            # Check for UNION ALL
            # Must be depth 0, not in quotes
            if paren_depth == 0 and not (in_single or in_double):
                # Check for UNION ALL
                if char.upper() == 'U':
                    # Potential match
                    remainder = rest[i:]
                    # Check regex match at start of remainder to ensure word boundaries and spacing
                    u_match = re.match(r"(?i)UNION\s+ALL\b", remainder)
                    if u_match:
                         # Found split point
                         parts.append("".join(current_part).strip())
                         current_part = []
                         i += u_match.end()
                         continue
            
            current_part.append(char)
            i += 1
            
        if current_part:
            parts.append("".join(current_part).strip())
            
        if len(parts) <= 1:
            return [sql]
            
        # Reconstruct
        results = []
        for p in parts:
            results.append(f"{prefix} {p};")
            
        return results

    @staticmethod
    def split_large_insert_values_columns(sql: str, max_length: int = 8000) -> List[str]:
        """
        Strategy 3 variant: Split INSERT INTO t (c1, c2...) VALUES (v1, v2...)
        where single row is too long.
        """
        # 1. Parse into Columns and Values
        # Strict pattern: INSERT INTO table (cols) VALUES (vals)
        match = re.match(r"(?i)(INSERT\s+INTO\s+.*?)\s*\((.*?)\)\s*VALUES\s*\((.*)\)", sql, re.DOTALL)
        # Note: the above regex is simplistic for nested parens in values. 
        # Need robust parsing similar to split_large_insert_select
        
        # Reuse robust parsing logic?
        # Let's find "VALUES" keyword
        
        # Find "VALUES" at depth 0
        # Then find parens before and after
        
        # ... Implementation similar to select splitter ...
        
        # Quick check for applicability
        if "VALUES" not in sql.upper():
            return [sql]
            
        # Locate VALUES
        # We need to find the split point between (cols) and (vals)
        # Scan for VALUES keyword at depth 0
        
        values_idx = -1
        i = 0
        n = len(sql)
        in_quote = False
        paren_depth = 0
        
        while i < n:
            char = sql[i]
            if char == "'" or char == '"': # simplified quote toggling
                 # Actually need to distinct
                 pass # Let's use robust find
            i+=1
            
        # Let's use the helper _find_keyword_at_depth_0 if we make it reusable?
        # Or just inline a finder here.
        
        def find_keyword(text, kw):
            d = 0
            n = len(text)
            i = 0
            in_s = False
            in_d = False
            kw_len = len(kw)
            while i < n:
                c = text[i]
                if c == "'" and not in_d: in_s = not in_s
                elif c == '"' and not in_s: in_d = not in_d
                elif c == '(' and not (in_s or in_d): d += 1
                elif c == ')' and not (in_s or in_d): d -= 1
                elif d == 0 and not (in_s or in_d):
                     if text[i:i+kw_len].upper() == kw:
                         return i
                i += 1
            return -1

        values_pos = find_keyword(sql, "VALUES")
        if values_pos == -1:
            return [sql]
            
        # Extract prefix (INSERT INTO table )
        # Pre-VALUES part: "INSERT INTO table (c1, c2...)"
        pre_values = sql[:values_pos].strip()
        post_values = sql[values_pos + 6:].strip() # skip VALUES
        
        if post_values.endswith(";"):
             post_values = post_values[:-1].strip()
        
        # Extract columns
        # pre_values ends with (...)
        if not pre_values.endswith(')'):
             return [sql]
        
        # Find start of cols parens (last balanced open paren?)
        # Actually pre_values is "INSERT INTO table (cols...)"
        # Scan backwards to find matching '(' for the last ')'
        
        d = 0
        cols_start = -1
        for j in range(len(pre_values)-1, -1, -1):
            c = pre_values[j]
            if c == ')': d += 1
            elif c == '(': d -= 1
            if d == 0:
                cols_start = j
                break
        
        if cols_start == -1:
             return [sql]
             
        table_prefix = pre_values[:cols_start].strip() # INSERT INTO table
        cols_content = pre_values[cols_start+1:-1].strip()
        
        # Extract values
        # post_values should be "(v1, v2...)"
        # It might be multiple rows "(...), (...)" but this strategy is for SINGLE row too long 
        # (or effectively treating multiple rows as separate is Strategy 1)
        # If Strategy 1 failed to reduce size enough, maybe one row is huge?
        # If multiple rows exist, post_values looks like "(r1), (r2)". 
        # If we are here, we assume we want to split *columns*. 
        # If multiple rows exist, we can't easily split columns across all rows unless we iterate all.
        # Simplification: Only support single row for column split.
        
        if post_values.strip().startswith('(') and post_values.strip().endswith(')'):
             # check if there are commas at depth 0 -> multiple rows
             # If multiple rows, we should have processed them in Strategy 1.
             # If Strategy 1 ran, we might have a single huge row here.
             pass
        else:
             return [sql]

        vals_content = post_values.strip()[1:-1].strip()
        
        # Split cols and vals
        cols = SqlSplitter._split_by_comma(cols_content)
        vals = SqlSplitter._split_by_comma(vals_content)
        
        if len(cols) != len(vals) or not cols:
             return [sql]
             
        # Chunking
        chunks = []
        current_cols = []
        current_vals = []
        
        # Overhead: INSERT INTO table () VALUES ();
        base_overhead = len(table_prefix) + 20 
        current_len = base_overhead
        
        for c, v in zip(cols, vals):
             pair_len = len(c) + len(v) + 4
             
             if current_len + pair_len > max_length and current_cols:
                 chunks.append(f"{table_prefix} ({', '.join(current_cols)}) VALUES ({', '.join(current_vals)});")
                 current_cols = []
                 current_vals = []
                 current_len = base_overhead
            
             current_cols.append(c)
             current_vals.append(v)
             current_len += pair_len
             
        if current_cols:
             chunks.append(f"{table_prefix} ({', '.join(current_cols)}) VALUES ({', '.join(current_vals)});")
             
        return chunks

    @staticmethod
    def extract_procedure_body(sql: str) -> List[str]:
        """
        If the SQL is a CREATE PROCEDURE/FUNCTION, extract the body (content between BEGIN/END).
        Returns a list of statements found in the body.
        If not a procedure or extraction fails, returns [sql].
        """
        match = re.search(r"(?i)\bBEGIN\b(.*)\bEND\b", sql, re.DOTALL)
        if match:
            body = match.group(1).strip()
            # Now split the body as if it were a script
            return SqlSplitter.split(body)
            
        return [sql]

    @staticmethod
    def remove_comments(sql: str) -> str:
        """
        Remove comments (-- and /* */) from SQL string while respecting quotes.
        """
        if not sql:
            return ""
            
        result = []
        n = len(sql)
        i = 0
        
        in_single_quote = False
        in_double_quote = False
        in_backtick = False
        in_block_comment = False
        in_line_comment = False 
        
        while i < n:
            char = sql[i]
            
            # Check for comments start
            if not (in_single_quote or in_double_quote or in_backtick or in_block_comment or in_line_comment):
                if char == '-' and i + 1 < n and sql[i+1] == '-':
                    in_line_comment = True
                    i += 2
                    continue
                elif char == '#' and (i==0 or sql[i-1].isspace()): 
                    in_line_comment = True
                    i += 1
                    continue
                elif char == '/' and i + 1 < n and sql[i+1] == '*':
                    in_block_comment = True
                    i += 2
                    continue
            
            # Check for comments end
            if in_line_comment:
                if char == '\n':
                    in_line_comment = False
                    result.append(char) # Keep newline for formatting safety
                i += 1
                continue
                
            if in_block_comment:
                if char == '*' and i + 1 < n and sql[i+1] == '/':
                    in_block_comment = False
                    i += 2
                else:
                    i += 1
                continue
            
            # Quotes logic
            if char == "'" and not (in_double_quote or in_backtick):
                if not in_single_quote:
                    in_single_quote = True
                elif i + 1 < n and sql[i+1] == "'":
                    # Escaped quote
                    result.append(char)
                    i += 1
                    char = sql[i] # append next '
                else:
                    in_single_quote = False
            
            elif char == '"' and not (in_single_quote or in_backtick):
                if not in_double_quote:
                    in_double_quote = True
                elif i + 1 < n and sql[i+1] == '"':
                     # Escaped 
                    result.append(char)
                    i += 1
                    char = sql[i]
                else:
                    in_double_quote = False
                    
            elif char == '`' and not (in_single_quote or in_double_quote):
                 if not in_backtick:
                    in_backtick = True
                 elif i + 1 < n and sql[i+1] == '`':
                     # Escaped
                     result.append(char)
                     i += 1
                     char = sql[i]
                 else:
                    in_backtick = False

            result.append(char)
            i += 1
            
        return "".join(result)

    @staticmethod
    def _split_by_comma(text: str) -> List[str]:
        """Split string by comma, ignoring commas inside quotes or parentheses."""
        items = []
        current = []
        paren_depth = 0
        in_single = False
        in_double = False
        in_backtick = False
        
        n = len(text)
        i = 0
        while i < n:
            char = text[i]
            if char == "'" and not (in_double or in_backtick):
                in_single = not in_single
            elif char == '"' and not (in_single or in_backtick):
                in_double = not in_double
            elif char == '`' and not (in_single or in_double):
                in_backtick = not in_backtick
            elif char == '(' and not (in_single or in_double or in_backtick):
                paren_depth += 1
            elif char == ')' and not (in_single or in_double or in_backtick):
                paren_depth -= 1
            elif char == ',' and paren_depth == 0 and not (in_single or in_double or in_backtick):
                items.append("".join(current).strip())
                current = []
                i += 1
                continue
            
            current.append(char)
            i += 1
            
        if current:
            items.append("".join(current).strip())
        return items

    @staticmethod
    def split_large_insert_select(sql: str, max_length: int = 8000) -> List[str]:
        """
        Split large INSERT ... SELECT statement into multiple column-wise chunks.
        Handling CTEs (WITH clause) and complex nesting.
        """
        # 1. Find the column list start
        match = re.search(r"(?i)(INSERT\s+INTO\s+[^(]+\s*)\(", sql)
        if not match:
            return [sql]
            
        start_idx = match.end()
        prefix_base = match.group(1).strip()
        
        # 2. Extract strictly the column list (balance parens)
        col_end_idx = -1
        depth = 1 # We passed one '('
        for i in range(start_idx, len(sql)):
            ch = sql[i]
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
                if depth == 0:
                    col_end_idx = i
                    break
        
        if col_end_idx == -1:
            return [sql]
            
        cols_str = sql[start_idx:col_end_idx]
        
        # 3. Find the MAIN SELECT and FROM at depth 0
        # Search from col_end_idx + 1
        # We need to skip potential WITH clause or random spaces
        
        current_idx = col_end_idx + 1
        select_start_idx = -1
        select_end_idx = -1 # After SELECT word
        from_start_idx = -1
        
        # Helper to find keyword at depth 0
        def find_keyword_at_depth_0(text, start, keyword):
            d = 0
            n = len(text)
            i = start
            in_quote = False 
            kw_len = len(keyword)
            kw_upper = keyword.upper()
            
            while i < n:
                ch = text[i]
                
                # Check Quote
                if ch == "'" and (i==0 or text[i-1]!='\\'):
                     # Find next quote
                     j = i + 1
                     while j < n:
                         if text[j] == "'" and text[j-1]!='\\':
                             break
                         j += 1
                     i = j + 1
                     continue
                     
                if ch == '(':
                    d += 1
                elif ch == ')':
                    d -= 1
                elif d == 0:
                    # Check match
                    if text[i:i+kw_len].upper() == kw_upper:
                         # Ensure word boundary
                         prev_char = text[i-1] if i>0 else ' '
                         next_char = text[i+kw_len] if i+kw_len < n else ' '
                         if (not prev_char.isalnum() and prev_char != '_') and \
                            (not next_char.isalnum() and next_char != '_'):
                             return i
                i += 1
            return -1

        select_start_idx = find_keyword_at_depth_0(sql, current_idx, "SELECT")
        if select_start_idx == -1:
            return [sql]
            
        # The content between col_end_idx+1 and select_start_idx is intermediate (e.g. WITH clause)
        intermediate = sql[col_end_idx+1 : select_start_idx].strip()
        
        select_content_start = select_start_idx + 6 # len("SELECT")
        
        from_start_idx = find_keyword_at_depth_0(sql, select_content_start, "FROM")
        if from_start_idx == -1:
            return [sql]
            
        exprs_str = sql[select_content_start : from_start_idx].strip()
        suffix = sql[from_start_idx:]
        
        # 4. Split Lists
        cols = SqlSplitter._split_by_comma(cols_str)
        exprs = SqlSplitter._split_by_comma(exprs_str)
        
        # 5. Validate
        if len(cols) != len(exprs) or not cols:
            return [sql]

        # 6. Chunking
        chunks = []
        current_cols = []
        current_exprs = []
        
        # Reconstruct prefix properly
        # INSERT INTO T ( ... ) WITH ... SELECT ... FROM ...
        # chunk: INSERT INTO T (cols) WITH ... SELECT exprs FROM ...
        
        # Overhead: ' (' + ') ' + ' SELECT ' + ' ' = 2 + 2 + 8 + 1 = 13 approx.
        # Plus we need comma space for items but that's handled in loop?
        # Actually loop adds commas: len(c) + len(e) + 4 (two ", " for col and expr)
        # But for the first item, no comma. So + 4 is generous but okay.
        
        base_overhead = len(prefix_base) + len(intermediate) + len(suffix) + 12
        current_len = base_overhead
        
        for c, e in zip(cols, exprs):
            pair_len = len(c) + len(e) + 4 
            
            if current_len + pair_len > max_length and current_cols:
                # Flush
                chunk_cols_str = ", ".join(current_cols)
                chunk_exprs_str = ", ".join(current_exprs)
                
                # Format: prefix (cols) intermediate SELECT exprs suffix
                chunk_sql = f"{prefix_base} ({chunk_cols_str}) {intermediate} SELECT {chunk_exprs_str} {suffix}"
                chunks.append(chunk_sql)
                
                current_cols = []
                current_exprs = []
                current_len = base_overhead
            
            current_cols.append(c)
            current_exprs.append(e)
            current_len += pair_len
            
        if current_cols:
            chunk_cols_str = ", ".join(current_cols)
            chunk_exprs_str = ", ".join(current_exprs)
            chunk_sql = f"{prefix_base} ({chunk_cols_str}) {intermediate} SELECT {chunk_exprs_str} {suffix}"
            chunks.append(chunk_sql)
            
        return chunks
