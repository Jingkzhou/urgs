#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
数据库字典生成器

数据来源（三者结合，逐级可用）：
  1. 解析 Flyway 迁移脚本（V1~V102）：重建库表/字段/类型/备注/码值（主来源，零依赖）
  2. 直连本地 MySQL 反查 information_schema：交叉校验（需本地库在跑 + 已安装 pymysql）
  3. 反查 Java 枚举类：补充字段码值含义

产出：docs/db-dictionary.html（自包含网页，带搜索 / 折叠 / 码值 chips / 枚举附录）

用法：
  python3 scripts/db_dict/generate_db_dictionary.py
  DB 连接信息读取环境变量 SPRING_DATASOURCE_*，默认值与 application.yml 保持一致。
"""
import os
import re
import json
import glob
import datetime

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
MIGRATION_DIR = os.path.join(REPO_ROOT, "urgs-api", "src", "main", "resources", "db", "migration")
JAVA_SRC = os.path.join(REPO_ROOT, "urgs-api", "src", "main", "java")
OUT_HTML = os.path.join(REPO_ROOT, "docs", "db-dictionary.html")

DB_CFG = dict(
    host=os.environ.get("SPRING_DATASOURCE_HOST", "127.0.0.1"),
    port=int(os.environ.get("SPRING_DATASOURCE_PORT", "3306")),
    user=os.environ.get("SPRING_DATASOURCE_USERNAME", "root"),
    password=os.environ.get("SPRING_DATASOURCE_PASSWORD", "a8548879"),
    database=os.environ.get("SPRING_DATASOURCE_DB", "urgs_dev"),
    connect_timeout=3,
)

# ----------------------------------------------------------------------------
# 通用工具
# ----------------------------------------------------------------------------

def balanced_paren(s, start):
    """s[start] 必须是 '('，返回其内部字符串与匹配的 ')' 下标。"""
    depth = 0
    i = start
    while i < len(s):
        if s[i] == '(':
            depth += 1
        elif s[i] == ')':
            depth -= 1
            if depth == 0:
                return s[start + 1:i], i
        i += 1
    return s[start + 1:], len(s) - 1


def split_top_level(s, sep=','):
    """按顶层分隔符切分（忽略括号内的分隔符）。"""
    parts, depth, buf = [], 0, []
    for ch in s:
        if ch == '(':
            depth += 1
            buf.append(ch)
        elif ch == ')':
            depth -= 1
            buf.append(ch)
        elif ch == sep and depth == 0:
            parts.append(''.join(buf))
            buf = []
        else:
            buf.append(ch)
    if buf:
        parts.append(''.join(buf))
    return parts


def strip_sql_comments(sql):
    sql = re.sub(r'--[^\n]*', ' ', sql)
    sql = re.sub(r'/\*.*?\*/', ' ', sql, flags=re.S)
    return sql


def find_matching_brace(text, open_idx):
    depth = 0
    for i in range(open_idx, len(text)):
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                return i
    return len(text) - 1


# ----------------------------------------------------------------------------
# 码值抽取（从字段 COMMENT 中识别 A/B/C 枚举列表）
# ----------------------------------------------------------------------------

def _parse_segment(seg):
    """把一段「码值描述」拆成若干展示串（如 '0 正常'、'DRAFT'、'os 操作系统'）。
    仅当成列表/成对出现时才视为码值，避免把孤立的描述词当码值。"""
    res = []
    chunks = re.split(r'[，,;；]+', seg)
    multi = len(chunks) > 1
    for ch in chunks:
        ch = ch.strip()
        if not ch:
            continue
        # 1) CODE:含义  例 "0:正常" "Oracle:1521"
        m = re.match(r'^([A-Za-z0-9_]+)\s*[:：]\s*(.+)$', ch)
        if m:
            res.append('%s %s' % (m.group(1), m.group(2).strip()))
            continue
        # 2) CODE 含义（含义以中文开头）例 "ACTIVE 生效"
        m = re.match(r'^([A-Za-z0-9_]+)\s+([一-鿿].*)$', ch)
        if m:
            res.append('%s %s' % (m.group(1), m.group(2).strip()))
            continue
        # 3) CODE含义 / CODE(含义) 直接相连  例 "0否" "os 操作系统"
        m = re.match(r'^([A-Za-z0-9_]+)([一-鿿(].*)$', ch)
        if m:
            res.append(ch)
            continue
        # 4) 以 / 、 | 分隔的列表  例 "SERVER/DATABASE"
        if re.search(r'[/、|]', ch):
            for t in re.split(r'[/、|]', ch):
                t = t.strip()
                if t and re.match(r'^[\w一-鿿\-]+$', t) and len(t) <= 40:
                    res.append(t)
            continue
        # 5) 其余：仅当成列表（多值）的一部分时才保留，剔除孤立描述词
        if multi and (re.search(r'[A-Za-z0-9_/]', ch) or re.search(r'\d', ch)):
            res.append(ch)
    return res


def extract_code_values(comment):
    """从字段备注中抽取码值。支持：冒号列表、逗号/顿号列表、括号含义、
    CODE:含义、CODE 含义、纯 A/B/C 列表等多种写法。"""
    if not comment:
        return []
    # 把 (含义) 展开为 ' 含义'，便于后续整体解析
    base = re.sub(r'[（(]([^（）()]*)[）)]', lambda m: ' ' + m.group(1), comment)
    if ':' in base or '：' in base:
        seg = re.split(r'[:：]', base, 1)[1]
    else:
        seg = base
    items = _parse_segment(seg)
    seen, out = set(), []
    for it in items:
        it = it.strip()
        if it and it not in seen and len(it) <= 60:
            seen.add(it)
            out.append(it)
    return out


# ----------------------------------------------------------------------------
# 字段解析
# ----------------------------------------------------------------------------

COL_TYPE_RE = re.compile(
    r'`?(\w+)`?\s+(\w+(?:\(\s*[^)]*\s*\))?(?:\s+(?:UNSIGNED|ZEROFILL|SIGNED))?)\s*(.*)',
    re.I | re.S,
)
CONSTRAINT_RE = re.compile(
    r'^\s*(PRIMARY|UNIQUE|KEY|INDEX|CONSTRAINT|FOREIGN|CHECK|FULLTEXT|SPATIAL)', re.I)
COMMENT_RE = re.compile(r"\bCOMMENT\s*=?\s*'([^']*)'|\bCOMMENT\s*=?\s*\"([^\"]*)\"", re.I)
DEFAULT_RE = re.compile(
    r'\bDEFAULT\s+(?:\'([^\']*)\'|\(([^)]*)\)|([\w\.\-\+]+))', re.I)


def parse_column(part):
    """将一段列定义解析为字典；若看起来像表级约束则返回 None。"""
    if CONSTRAINT_RE.match(part):
        return None
    m = COL_TYPE_RE.match(part)
    if not m:
        return None
    name = m.group(1)
    coltype = m.group(2).upper()
    rest = m.group(3)
    cm = COMMENT_RE.search(rest)
    comment = (cm.group(1) or cm.group(2) or '').strip() if cm else ''
    dm = DEFAULT_RE.search(rest)
    default = ''
    if dm:
        default = dm.group(1) if dm.group(1) is not None else (
            dm.group(2) if dm.group(2) is not None else dm.group(3))
    nullable = not re.search(r'\bNOT\s+NULL\b', rest, re.I)
    auto_inc = bool(re.search(r'AUTO_INCREMENT', rest, re.I))
    is_pk = bool(re.search(r'\bPRIMARY\s+KEY\b', rest, re.I))
    return {
        'name': name,
        'type': coltype,
        'nullable': nullable,
        'default': default,
        'comment': comment,
        'auto_inc': auto_inc,
        'is_pk': is_pk,
        'code_values': extract_code_values(comment),
    }


def _strip_add_modify_prefix(rest, kw):
    m = re.search(kw + r'\s+(?:COLUMN\s+)?(.*)', rest, re.I | re.S)
    return m.group(1).strip() if m else None


# ----------------------------------------------------------------------------
# 语句应用（CREATE / ALTER / RENAME / DROP）
# ----------------------------------------------------------------------------

def apply_statement(stmt, schema, order):
    stmt = stmt.strip()
    if not stmt:
        return

    # ---- CREATE TABLE ----
    m = re.search(r'CREATE\s+TABLE\s+(?:IF\s+NOT\s+EXISTS\s+)?`?(\w+)`?\s*\(', stmt, re.I)
    if m:
        tname = m.group(1)
        start = m.end() - 1
        body, end = balanced_paren(stmt, start)
        tcomment = ''
        tc = COMMENT_RE.search(stmt[end:])
        if tc:
            tcomment = (tc.group(1) or tc.group(2) or '').strip()
        if tname not in schema:
            order.append(tname)
            schema[tname] = {'comment': tcomment, 'columns': {}}
        else:
            if tcomment:
                schema[tname]['comment'] = tcomment
        pk_cols = []
        for part in split_top_level(body):
            p = part.strip()
            if not p:
                continue
            up = p.upper()
            if up.startswith('PRIMARY KEY'):
                cm = re.search(r'\(([^)]*)\)', p)
                if cm:
                    pk_cols = [c.strip().strip('`') for c in cm.group(1).split(',')]
                continue
            col = parse_column(p)
            if col:
                schema[tname]['columns'][col['name']] = col
        for c in pk_cols:
            if c in schema[tname]['columns']:
                schema[tname]['columns'][c]['is_pk'] = True
        return

    # ---- RENAME TABLE ----
    if re.match(r'RENAME\s+TABLE', stmt, re.I):
        for a, b in re.findall(r'`?(\w+)`?\s+TO\s+`?(\w+)`?', stmt, re.I):
            if a in schema:
                schema[b] = schema.pop(a)
                idx = order.index(a)
                order[idx] = b
        return

    # ---- DROP TABLE ----
    m = re.search(r'DROP\s+TABLE\s+(?:IF\s+EXISTS\s+)?(.+)', stmt, re.I)
    if m:
        for t in re.findall(r'`?(\w+)`?', m.group(1)):
            if t in schema:
                order.remove(t)
                del schema[t]
        return

    # ---- ALTER TABLE ----
    m = re.search(r'ALTER\s+TABLE\s+`?(\w+)`?\s+(.*)', stmt, re.I | re.S)
    if m:
        tname = m.group(1)
        rest = m.group(2)
        if tname not in schema:
            return
        tbl = schema[tname]

        # RENAME TO
        rm = re.search(r'RENAME\s+TO\s+`?(\w+)`?', rest, re.I)
        if rm:
            new = rm.group(1)
            schema[new] = schema.pop(tname)
            order[order.index(tname)] = new
            tname = new
            tbl = schema[new]

        # ADD COMMENT='...'
        ac = re.search(r'ADD\s+COMMENT\s*=\s*\'([^\']*)\'', rest, re.I)
        if ac:
            tbl['comment'] = ac.group(1).strip()

        # ADD PRIMARY KEY
        pk = re.search(r'ADD\s+PRIMARY\s+KEY\s*\(([^)]*)\)', rest, re.I)
        if pk:
            for c in [x.strip().strip('`') for x in pk.group(1).split(',')]:
                if c in tbl['columns']:
                    tbl['columns'][c]['is_pk'] = True

        # DROP COLUMN
        dm = re.search(r'DROP\s+(?:COLUMN\s+)?`?(\w+)`?', rest, re.I)
        if dm and dm.group(1) in tbl['columns']:
            del tbl['columns'][dm.group(1)]

        # CHANGE COLUMN old new ...
        ch = re.search(r'CHANGE\s+(?:COLUMN\s+)?`?(\w+)`?\s+`?(\w+)`?\s+(.*)', rest, re.I | re.S)
        if ch:
            old, new, sub = ch.group(1), ch.group(2), ch.group(3)
            col = parse_column(new + ' ' + sub)
            if col:
                if old in tbl['columns']:
                    del tbl['columns'][old]
                tbl['columns'][col['name']] = col
            return

        # MODIFY COLUMN ...
        sub = _strip_add_modify_prefix(rest, r'MODIFY')
        if sub:
            col = parse_column(sub)
            if col and col['name'] in tbl['columns']:
                tbl['columns'][col['name']] = col
            return

        # ADD [COLUMN] ...
        sub = _strip_add_modify_prefix(rest, r'ADD')
        if sub and not re.match(r'(INDEX|KEY|UNIQUE|CONSTRAINT|PRIMARY|FOREIGN|SPATIAL|FULLTEXT)', sub, re.I):
            col = parse_column(sub)
            if col:
                tbl['columns'][col['name']] = col
        return


def parse_migrations():
    files = [f for f in os.listdir(MIGRATION_DIR) if re.match(r'V\d.*\.sql$', f)]
    files.sort(key=lambda f: tuple(int(x) for x in re.match(r'V([0-9]+(?:\.[0-9]+)*)__', f).group(1).split('.')))
    schema, order = {}, []
    for f in files:
        with open(os.path.join(MIGRATION_DIR, f), encoding='utf-8') as fh:
            raw = strip_sql_comments(fh.read())
        for st in raw.split(';'):
            apply_statement(st, schema, order)
    return schema, order, files


# ----------------------------------------------------------------------------
# Java 枚举反查
# ----------------------------------------------------------------------------

def extract_enums():
    enums = []
    for path in glob.glob(os.path.join(JAVA_SRC, '**', '*.java'), recursive=True):
        try:
            text = open(path, encoding='utf-8').read()
        except Exception:
            continue
        t = re.sub(r'/\*.*?\*/', '', text, flags=re.S)
        t = re.sub(r'//[^\n]*', '', t)
        for m in re.finditer(r'(?:public\s+|private\s+|protected\s+)?enum\s+(\w+)\s*\{', t):
            name = m.group(1)
            end = find_matching_brace(t, m.end() - 1)
            body = t[m.end():end]
            semi = body.find(';')
            region = body[:semi] if semi != -1 else body
            constants = []
            for cm in re.finditer(r'([A-Za-z_]\w*)\s*(\(([^)]*)\))?', region):
                cname = cm.group(1)
                args = cm.group(3)
                code = None
                desc = None
                if args is not None:
                    strs = re.findall(r'"([^"]*)"|\'([^\']*)\'', args)
                    nums = re.findall(r'\b\d+\b', args)
                    if strs:
                        desc = ' / '.join([a for a in sum(strs, ()) if a])
                    if nums:
                        code = nums[0]
                constants.append({'name': cname, 'code': code, 'desc': desc})
            if constants:
                enums.append({'name': name, 'constants': constants,
                              'file': os.path.relpath(path, REPO_ROOT)})
    return enums


def score_enum(ename, table, column):
    etoks = set(tok.lower() for tok in re.findall(r'[A-Z]?[a-z]+|[A-Z]+(?=[A-Z]|$)', ename) if len(tok) >= 2)
    etoks.discard('enum')
    ftoks = {t for t in re.split(r'[_\s]+', column.lower()) if len(t) >= 2}
    ttoks = {t for t in re.split(r'[_\s]+', table.lower())
             if len(t) >= 3 and t not in ('sys', 'urgs', 'table', 't', 'tbl')}
    score = 0
    for t in ftoks:
        if t in etoks:
            score += 2
    for t in ttoks:
        if t in etoks:
            score += 1
    return score


def suggest_enums(table, column, enums):
    scored = [(score_enum(e['name'], table, column), e) for e in enums]
    scored = [(s, e) for s, e in scored if s >= 2]
    scored.sort(key=lambda x: -x[0])
    return [{'name': e['name'], 'constants': e['constants'], 'score': s}
            for s, e in scored[:3]]


# ----------------------------------------------------------------------------
# 本地库交叉校验（best-effort）
# ----------------------------------------------------------------------------

def introspect_db():
    try:
        import pymysql
    except ImportError:
        return None, "未安装 pymysql 驱动（pip3 install pymysql 后重跑可启用）"
    try:
        cfg = dict(DB_CFG)
        conn = pymysql.connect(**cfg)
        cur = conn.cursor()
        cur.execute("SELECT TABLE_NAME, TABLE_COMMENT FROM information_schema.tables WHERE table_schema=%s",
                    (cfg['database'],))
        tables = {r[0]: {'comment': r[1], 'columns': {}} for r in cur.fetchall()}
        cur.execute(
            "SELECT TABLE_NAME,COLUMN_NAME,COLUMN_TYPE,IS_NULLABLE,COLUMN_DEFAULT,COLUMN_COMMENT "
            "FROM information_schema.columns WHERE table_schema=%s ORDER BY TABLE_NAME, ORDINAL_POSITION",
            (cfg['database'],))
        for r in cur.fetchall():
            t = r[0]
            tables.setdefault(t, {'comment': '', 'columns': {}})
            tables[t]['columns'][r[1]] = {
                'type': r[2].upper(), 'nullable': r[3], 'default': r[4], 'comment': r[5]}
        conn.close()
        return tables, None
    except Exception as e:
        return None, "连接失败: %s %s" % (type(e).__name__, str(e)[:150])


def cross_check(sql_schema, db_schema):
    mismatches = []
    sql_tables = set(sql_schema)
    db_tables = set(db_schema)
    for t in sorted(sql_tables - db_tables):
        mismatches.append({'table': t, 'level': 'high', 'msg': '迁移脚本定义，但本地库中不存在'})
    for t in sorted(db_tables - sql_tables):
        mismatches.append({'table': t, 'level': 'low', 'msg': '本地库存在，但迁移脚本未定义（可能为手动建表）'})
    for t in sorted(sql_tables & db_tables):
        scols = sql_schema[t]['columns']
        dcols = db_schema[t]['columns']
        for c in sorted(set(scols) - set(dcols)):
            mismatches.append({'table': t, 'level': 'high', 'msg': '字段 %s 在脚本中但库中缺失' % c})
        for c in sorted(set(dcols) - set(scols)):
            mismatches.append({'table': t, 'level': 'low', 'msg': '字段 %s 在库中但脚本未定义' % c})
        for c in sorted(set(scols) & set(dcols)):
            s, d = scols[c], dcols[c]
            if s['type'] != d['type']:
                mismatches.append({'table': t, 'level': 'mid',
                                   'msg': '字段 %s 类型不一致：脚本 %s / 库 %s' % (c, s['type'], d['type'])})
            if s['comment'] and d['comment'] and s['comment'] != d['comment']:
                mismatches.append({'table': t, 'level': 'low',
                                   'msg': '字段 %s 备注不一致：脚本「%s」/ 库「%s」' % (c, s['comment'], d['comment'])})
    return mismatches


# ----------------------------------------------------------------------------
# 数据装配
# ----------------------------------------------------------------------------

def build_data():
    sql_schema, order, files = parse_migrations()
    enums = extract_enums()
    db_schema, db_err = introspect_db()
    mismatches = cross_check(sql_schema, db_schema) if db_schema else []

    tables = []
    for t in order:
        cols = sql_schema[t]['columns']
        col_list = []
        for cname, c in cols.items():
            col_list.append({
                'name': cname, 'type': c['type'], 'nullable': c['nullable'],
                'default': c['default'], 'comment': c['comment'],
                'is_pk': c['is_pk'], 'auto_inc': c['auto_inc'],
                'code_values': c['code_values'],
                'enum_hints': [{'name': e['name'], 'constants': e['constants']}
                               for e in suggest_enums(t, cname, enums)
                               if (not c['code_values'] and e['score'] >= 2)
                               or (c['code_values'] and e['score'] >= 4)],
            })
        tables.append({'name': t, 'comment': sql_schema[t]['comment'], 'columns': col_list})

    source_note = ("基于 Flyway 迁移脚本 V1~V%s（共 %d 个脚本）重建；已尝试直连本地 MySQL(%s/%s)：%s"
                   % (files[-1].split('__')[0].lstrip('V'), len(files), DB_CFG['host'],
                      DB_CFG['database'], (db_err or "连接成功并完成交叉校验")))

    return {
        'generated': datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'source_note': source_note,
        'db_connected': db_schema is not None,
        'stats': {'tables': len(tables),
                  'columns': sum(len(t['columns']) for t in tables),
                  'enums': len(enums),
                  'coded_fields': sum(1 for t in tables for c in t['columns'] if c['code_values'])},
        'tables': tables,
        'enums': enums,
        'mismatches': mismatches,
    }


# ----------------------------------------------------------------------------
# HTML 渲染
# ----------------------------------------------------------------------------

HTML_TEMPLATE = """<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>URGS 数据库字典</title>
<style>
  :root{--bg:#f7f8fa;--card:#fff;--line:#e5e7eb;--txt:#1f2937;--sub:#6b7280;
        --pri:#2563eb;--chip:#eef2ff;--chip-txt:#3730a3;--warn:#b45309;--err:#b91c1c;}
  *{box-sizing:border-box}
  body{margin:0;font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,"PingFang SC","Microsoft YaHei",sans-serif;
       background:var(--bg);color:var(--txt);font-size:14px;line-height:1.5}
  header{background:linear-gradient(135deg,#1e3a8a,#2563eb);color:#fff;padding:24px 28px}
  header h1{margin:0 0 6px;font-size:22px}
  header .note{font-size:12.5px;opacity:.92}
  .stats{display:flex;gap:18px;margin-top:14px;flex-wrap:wrap}
  .stats .s{background:rgba(255,255,255,.15);padding:8px 14px;border-radius:8px}
  .stats .s b{font-size:18px;display:block}
  .bar{position:sticky;top:0;background:#fff;border-bottom:1px solid var(--line);padding:12px 28px;z-index:10;
       display:flex;gap:12px;align-items:center;flex-wrap:wrap}
  .bar input{flex:1;min-width:220px;padding:9px 12px;border:1px solid var(--line);border-radius:8px;font-size:14px}
  .bar label{font-size:13px;color:var(--sub);display:flex;align-items:center;gap:5px;cursor:pointer}
  main{padding:18px 28px 60px;max-width:1280px;margin:0 auto}
  .banner{padding:12px 16px;border-radius:8px;margin-bottom:16px;font-size:13px}
  .banner.ok{background:#ecfdf5;color:#065f46;border:1px solid #a7f3d0}
  .banner.warn{background:#fffbeb;color:var(--warn);border:1px solid #fde68a}
  details.tbl{background:var(--card);border:1px solid var(--line);border-radius:10px;margin-bottom:12px;overflow:hidden}
  details.tbl>summary{cursor:pointer;padding:13px 16px;font-weight:600;display:flex;align-items:center;gap:10px}
  details.tbl>summary .tname{color:var(--pri);font-family:ui-monospace,Menlo,Consolas,monospace}
  details.tbl>summary .tcm{color:var(--sub);font-weight:400;font-size:13px}
  details.tbl>summary .cnt{margin-left:auto;color:var(--sub);font-size:12px;background:var(--bg);padding:2px 9px;border-radius:20px}
  .tbl.mismatch>summary{background:#fef2f2}
  table{border-collapse:collapse;width:100%;font-size:13px}
  th,td{border-top:1px solid var(--line);padding:8px 12px;text-align:left;vertical-align:top}
  th{background:#f9fafb;color:var(--sub);font-weight:600;position:sticky}
  td.name{font-family:ui-monospace,Menlo,Consolas,monospace;color:#111827;white-space:nowrap}
  .pk{color:#b45309;font-size:11px;border:1px solid #fcd34d;background:#fffbeb;border-radius:4px;padding:0 4px;margin-left:5px}
  .nn{color:#6b7280;font-size:11px;margin-left:5px}
  .chips{display:flex;flex-wrap:wrap;gap:5px;margin-top:4px}
  .chip{background:var(--chip);color:var(--chip-txt);border-radius:6px;padding:1px 8px;font-size:12px;font-family:ui-monospace,monospace}
  .hint{margin-top:4px;font-size:12px;color:var(--sub)}
  .hint b{color:#7c3aed}
  .enum-sec{margin-top:30px}
  details.enum{background:#fff;border:1px solid var(--line);border-radius:10px;margin-bottom:10px}
  details.enum>summary{padding:11px 15px;font-weight:600;cursor:pointer}
  details.enum .efile{color:var(--sub);font-weight:400;font-size:12px;margin-left:8px}
  .ec{font-family:ui-monospace,monospace;padding:3px 0}
  .ec .ecn{color:#111827}
  .ec .ecc{color:#2563eb}
  .ec .ecd{color:var(--sub)}
  .muted{color:var(--sub)}
  mark{background:#fde68a;padding:0 1px;border-radius:2px}
</style>
</head>
<body>
<header>
  <h1>URGS 数据库字典</h1>
  <div class="note" id="srcnote"></div>
  <div class="stats" id="stats"></div>
</header>
<div class="bar">
  <input id="q" placeholder="搜索表名 / 备注 / 字段名 / 码值…" oninput="applyFilter()">
  <label><input type="checkbox" id="codedOnly" onchange="applyFilter()"> 只看有码值的字段</label>
  <label id="diffWrap" style="display:none"><input type="checkbox" id="diffOnly" onchange="applyFilter()"> 只看差异表</label>
</div>
<main>
  <div id="banner"></div>
  <div id="tables"></div>
  <div class="enum-sec">
    <h2>Java 枚举类参考（码值补充）</h2>
    <div id="enums"></div>
  </div>
</main>
<script>
const DATA = __DATA__;
const $ = s => document.querySelector(s);
function esc(s){return (s==null?'':String(s)).replace(/[&<>]/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;'}[c]));}
function hl(text){
  const q=$('#q').value.trim().toLowerCase();
  if(!q) return esc(text);
  const i=text.toLowerCase().indexOf(q);
  if(i<0) return esc(text);
  return esc(text.slice(0,i))+'<mark>'+esc(text.slice(i,i+q.length))+'</mark>'+esc(text.slice(i+q.length));
}
function buildStats(){
  const s=DATA.stats;
  $('#stats').innerHTML=['tables:表','columns:字段','coded_fields:含码值字段','enums:枚举类']
    .map(([k,l])=>`<div class="s"><b>${s[k]}</b>${l}</div>`).join('');
  $('#srcnote').textContent='生成时间：'+DATA.generated+'　|　'+DATA.source_note;
}
function buildBanner(){
  const b=$('#banner');
  if(DATA.db_connected && DATA.mismatches.length===0){
    b.className='banner ok';b.textContent='✅ 已连接本地 MySQL 并完成交叉校验，未发现差异。';
  }else if(DATA.db_connected){
    b.className='banner warn';
    b.innerHTML='⚠️ 已连接本地 MySQL，发现 '+DATA.mismatches.length+' 处差异，已在对应表头标红，详见下方列表。';
    $('#diffWrap').style.display='';
  }else{
    b.className='banner warn';
    b.textContent='ℹ️ '+DATA.source_note.split('：').slice(-1)[0]+'（当前字典完全基于迁移脚本；启动本地库后重跑脚本即可自动交叉校验）';
  }
}
function colRow(c){
  let chips='';
  if(c.code_values&&c.code_values.length)
    chips+='<div class="chips">'+c.code_values.map(v=>`<span class="chip">${esc(v)}</span>`).join('')+'</div>';
  let hint='';
  if(c.enum_hints&&c.enum_hints.length){
    hint='<div class="hint">候选枚举：'+c.enum_hints.map(e=>{
      const cs=e.constants.map(x=>`${esc(x.name)}${x.desc?'('+esc(x.desc)+')':''}`).join('、');
      return `<b>${esc(e.name)}</b> {${cs}}`;
    }).join('；')+' <span class="muted">(命名推测，请人工确认)</span></div>';
  }
  return `<tr>
    <td class="name">${hl(c.name)}${c.is_pk?'<span class="pk">PK</span>':''}${c.auto_inc?'<span class="nn">AI</span>':''}</td>
    <td>${esc(c.type)}</td>
    <td>${c.nullable?'可空':'NOT NULL'}</td>
    <td>${esc(c.default)||'<span class="muted">—</span>'}</td>
    <td>${hl(c.comment)||'<span class="muted">—</span>'}${chips}${hint}</td>
  </tr>`;
}
function buildTables(){
  const box=$('#tables');
  box.innerHTML=DATA.tables.map(t=>{
    const mismatch=DATA.mismatches.some(m=>m.table===t.name);
    const rows=t.columns.map(colRow).join('');
    return `<details class="tbl${mismatch?' mismatch':''}" data-name="${esc(t.name)}" data-cm="${esc(t.comment)}">
      <summary><span class="tname">${hl(t.name)}</span><span class="tcm">${hl(t.comment)}</span>
        <span class="cnt">${t.columns.length} 字段</span></summary>
      <table><thead><tr><th>字段</th><th>类型</th><th>可空</th><th>默认</th><th>备注 / 码值 / 候选枚举</th></tr></thead>
      <tbody>${rows}</tbody></table></details>`;
  }).join('');
}
function buildEnums(){
  const box=$('#enums');
  box.innerHTML=DATA.enums.map(e=>{
    const cs=e.constants.map(c=>`<div class="ec"><span class="ecn">${esc(c.name)}</span>`
      +(c.code?`<span class="ecc"> = ${esc(c.code)}</span>`:'')
      +(c.desc?`<span class="ecd"> — ${esc(c.desc)}</span>`:'')+'</div>').join('');
    return `<details class="enum"><summary>${esc(e.name)}<span class="efile">${esc(e.file)}</span></summary>${cs}</details>`;
  }).join('');
}
function applyFilter(){
  const q=$('#q').value.trim().toLowerCase();
  const codedOnly=$('#codedOnly').checked;
  const diffOnly=$('#diffOnly').checked;
  const mismatchTables=new Set(DATA.mismatches.map(m=>m.table));
  document.querySelectorAll('details.tbl').forEach(d=>{
    const tname=(d.getAttribute('data-name')||'').toLowerCase();
    const tcm=(d.getAttribute('data-cm')||'').toLowerCase();
    let tableMatch=!q||tname.includes(q)||tcm.includes(q);
    let anyRow=false;
    d.querySelectorAll('tbody tr').forEach((tr,idx)=>{
      const txt=tr.textContent.toLowerCase();
      const coded=tr.querySelector('.chip');
      let rowShow=(!q||txt.includes(q))&&(!codedOnly||coded);
      if(rowShow) anyRow=true;
      tr.style.display=rowShow?'':'none';
    });
    let show=tableMatch&&anyRow;
    if(diffOnly&&!mismatchTables.has(d.getAttribute('data-name'))) show=false;
    if(codedOnly&&!d.querySelector('.chip')&&!anyRow) show=false;
    d.style.display=show?'':'none';
  });
}
buildStats();buildBanner();buildTables();buildEnums();applyFilter();
</script>
</body>
</html>
"""


def generate_html(data):
    json_str = json.dumps(data, ensure_ascii=False)
    json_str = json_str.replace('</', '<\\/')
    return HTML_TEMPLATE.replace('__DATA__', json_str)


def main():
    data = build_data()
    html = generate_html(data)
    os.makedirs(os.path.dirname(OUT_HTML), exist_ok=True)
    with open(OUT_HTML, 'w', encoding='utf-8') as fh:
        fh.write(html)
    print('已生成: %s' % OUT_HTML)
    print('  表 %d / 字段 %d / 含码值字段 %d / 枚举类 %d'
          % (data['stats']['tables'], data['stats']['columns'],
             data['stats']['coded_fields'], data['stats']['enums']))
    print('  本地库: %s' % ('已连接并校验' if data['db_connected'] else '未连接 (%s)' % data['source_note'].split('：')[-1]))
    if data['mismatches']:
        print('  差异 %d 处' % len(data['mismatches']))


if __name__ == '__main__':
    main()
