#!/usr/bin/env python3
"""
老系统调度任务迁移脚本
将 bspdb.t_quartz_task 的 INSERT SQL 转换为 URGS 新调度系统的 SQL

核心逻辑:
  - 每个 task_system → 一个 sys_workflow（工作流）
  - 同系统内的依赖 → workflow 内部的 edge（边）
  - 跨系统依赖 → 在当前 workflow 中创建 DEPENDENT 代理任务节点

使用方法:
    python3 scripts/migrate_quartz_tasks.py /path/to/t_quartz_task.sql [output_dir]

输出:
    output/01_sys_task.sql            — sys_task 表插入（含 DEPENDENT 代理任务）
    output/02_sys_workflow.sql        — sys_workflow 表插入
    output/03_sys_task_dependency.sql — sys_task_dependency 表插入
    output/04_sys_job_dependency.sql  — sys_job_dependency 表插入（workflow 内的边）
    output/migration_report.txt      — 迁移统计报告
"""

import json
import os
import re
import sys
from collections import defaultdict, deque

# ============================================================
# 系统映射配置 — 请手动填写新系统的 sys_system.id
# ============================================================
SYSTEM_MAPPING = {
    "一表通": None,            # 填入新系统 sys_system.id (Long)
    "LDM接口表": None,
    "LDM任务": None,
    "金融基础数据": None,
    "审计署": None,
    "EAST": None,
    "1104": None,
    "存款保险2.0": None,
    "存款保险1.0": None,
    "利率报备监测分析": None,
    "反洗钱": None,
    "大集中": None,
    "支付统计报送": None,
    "客户风险": None,
    "集团并表": None,
    "二代央评系统": None,
    "跨系统数据免疫平台": None,
    "企业账户信息报送税务系统": None,
    "人民币利率报备": None,
    "标准化存贷款": None,
    "大额现金管理系统": None,
    "个人银行账户": None,
    "法人间参": None,
    "非居民涉税": None,
    "非居民涉税系统": None,
    "利率报备": None,
    "其他": None,
}

# 工作流 ID 起始值（避免与已有数据冲突）
WORKFLOW_ID_START = 10001


# ============================================================
# SQL 解析器（复用之前的逻辑）
# ============================================================

def parse_insert_line(line):
    """解析单条 INSERT INTO `t_quartz_task` VALUES (...); 语句"""
    m = re.match(r"INSERT INTO `t_quartz_task` VALUES \((.+)\);$", line.strip())
    if not m:
        return None

    raw = m.group(1)
    fields = []
    current = []
    in_quote = False
    i = 0
    while i < len(raw):
        ch = raw[i]
        if not in_quote:
            if ch == "'":
                in_quote = True
                i += 1
            elif ch == ",":
                fields.append("".join(current).strip())
                current = []
                i += 1
            else:
                current.append(ch)
                i += 1
        else:
            if ch == "\\" and i + 1 < len(raw):
                next_ch = raw[i + 1]
                if next_ch == "'":
                    current.append("'")
                elif next_ch == "\\":
                    current.append("\\")
                elif next_ch == "n":
                    current.append("\n")
                else:
                    current.append(next_ch)
                i += 2
            elif ch == "'" and i + 1 < len(raw) and raw[i + 1] == "'":
                current.append("'")
                i += 2
            elif ch == "'":
                in_quote = False
                i += 1
            else:
                current.append(ch)
                i += 1
    fields.append("".join(current).strip())

    if len(fields) < 22:
        return None

    def clean(val):
        val = val.strip()
        if val == "NULL" or val == "null":
            return None
        return val

    try:
        return {
            "id": int(fields[0]),
            "task_name": clean(fields[1]),
            "task_bean": clean(fields[2]),
            "task_params": clean(fields[3]),
            "task_cron": clean(fields[4]),
            "task_status": int(fields[5]) if fields[5].strip().isdigit() else 0,
            "remark": clean(fields[6]),
            "update_time": clean(fields[7]),
            "create_time": clean(fields[8]),
            "task_type": clean(fields[9]),
            "url": clean(fields[10]),
            "exe_path": clean(fields[11]),
            "depend_id": clean(fields[12]),
            "username": clean(fields[13]),
            "password": clean(fields[14]),
            "driver": clean(fields[15]),
            "period": clean(fields[16]),
            "task_system": clean(fields[17]),
            "theme": clean(fields[18]),
            "offset": clean(fields[19]),
            "data_date": clean(fields[20]),
            "job_key": clean(fields[21]) if len(fields) > 21 else None,
            "notification_completed": clean(fields[22]) if len(fields) > 22 else None,
            "notification_failed": clean(fields[23]) if len(fields) > 23 else None,
        }
    except (ValueError, IndexError):
        return None


def parse_sql_file(filepath):
    tasks = []
    errors = []
    with open(filepath, "r", encoding="utf-8") as f:
        for line_no, line in enumerate(f, 1):
            line = line.strip()
            if not line.startswith("INSERT INTO `t_quartz_task`"):
                continue
            task = parse_insert_line(line)
            if task:
                tasks.append(task)
            else:
                errors.append(f"Line {line_no}: 解析失败")
    return tasks, errors


# ============================================================
# 内容转换
# ============================================================

def build_content_json(task):
    """根据任务类型生成新系统的 content JSON dict"""
    task_type = task["task_type"]
    name = task["task_name"] or ""
    remark = task["remark"] or name
    exe_path = task["exe_path"] or ""

    if task_type == "1":
        script = exe_path.replace("$datadate", "$dataDate")
        return {
            "label": remark,
            "name": name,
            "rawScript": script,
            "resource": "",
            "localParams": [],
        }
    elif task_type == "2":
        method = exe_path
        param_count = 0
        proc_match = re.match(r"^(.+?)\((.+)\)\s*$", exe_path)
        if proc_match:
            method = proc_match.group(1)
            param_count = proc_match.group(2).count("?")

        local_params = []
        if param_count >= 1:
            local_params.append({"prop": "p_data_date", "direct": "IN", "type": "VARCHAR", "value": "$dataDate"})
        if param_count >= 2:
            local_params.append({"prop": "p_result", "direct": "OUT", "type": "VARCHAR", "value": ""})
        if param_count >= 3:
            local_params.append({"prop": "p_errmsg", "direct": "OUT", "type": "VARCHAR", "value": ""})
        for i in range(3, param_count):
            local_params.append({"prop": f"p_param_{i + 1}", "direct": "OUT", "type": "VARCHAR", "value": ""})

        return {
            "label": remark,
            "name": name,
            "datasourceId": "",
            "method": method,
            "localParams": local_params,
        }
    else:
        return {
            "label": remark,
            "name": name,
            "rawScript": exe_path,
            "resource": "",
            "localParams": [],
        }


def convert_task_type(old_type):
    return {"1": "SHELL", "2": "PROCEDURE"}.get(old_type, "SHELL")


def build_data_date_rule(offset_val):
    if offset_val is None:
        return None
    try:
        return json.dumps({"type": "offset", "value": int(offset_val)}, ensure_ascii=False)
    except (ValueError, TypeError):
        return None


def parse_dependencies(task):
    depend_str = task.get("depend_id")
    if not depend_str:
        return []
    return [int(p) for p in depend_str.split(",") if p.strip().isdigit()]


def escape_sql(s):
    if s is None:
        return "NULL"
    s = s.replace("\\", "\\\\")
    s = s.replace("'", "\\'")
    return f"'{s}'"


# ============================================================
# 核心: 按系统分组 → 工作流 + DEPENDENT 代理
# ============================================================

def build_workflows(tasks):
    """
    将任务按 task_system 分组为工作流。
    跨系统依赖通过 DEPENDENT 代理节点实现。

    返回:
      workflows: {system_name: WorkflowData}
      all_task_records: [TaskRecord] — 所有 sys_task 记录（含代理）
      all_task_deps: [(task_id, pre_task_id)] — sys_task_dependency 记录
      all_job_deps: [(workflow_id, parent_id, child_id)] — sys_job_dependency 记录
    """
    task_by_id = {t["id"]: t for t in tasks}
    all_task_ids = set(task_by_id.keys())

    # 按 task_system 分组
    system_tasks = defaultdict(list)
    for t in tasks:
        system_name = t.get("task_system") or "其他"
        system_tasks[system_name].append(t)

    # 分配 workflow ID
    system_names = sorted(system_tasks.keys())
    workflow_id_map = {}  # system_name -> workflow_id
    for i, name in enumerate(system_names):
        workflow_id_map[name] = WORKFLOW_ID_START + i

    # 反查: task_id -> system_name
    task_system_map = {}
    for t in tasks:
        task_system_map[t["id"]] = t.get("task_system") or "其他"

    # ---- 构建每个工作流 ----
    workflows = {}
    all_task_records = []      # (task_id_str, name, type, content_json, cron, data_date_rule, system_id)
    all_task_deps = []         # (task_id_str, pre_task_id_str)
    all_job_deps = []          # (workflow_id, parent_id_str, child_id_str)
    dep_proxy_tasks = {}       # (workflow_id, ext_task_id) -> proxy_task_id

    warnings = []

    for system_name in system_names:
        wf_id = workflow_id_map[system_name]
        wf_tasks = system_tasks[system_name]
        system_id = SYSTEM_MAPPING.get(system_name)

        # 本工作流内的任务 ID 集合
        local_task_ids = {t["id"] for t in wf_tasks}

        # ---- 分析依赖，识别跨系统引用 ----
        # 需要创建 DEPENDENT 代理的外部任务: {ext_task_id: set(本系统中依赖它的任务)}
        ext_deps = defaultdict(set)

        for t in wf_tasks:
            deps = parse_dependencies(t)
            for dep_id in deps:
                if dep_id not in all_task_ids:
                    warnings.append(f"Task {t['id']} ({t['task_name']}): 依赖 {dep_id} 不存在")
                    continue
                if dep_id not in local_task_ids:
                    ext_deps[dep_id].add(t["id"])

        # ---- 为外部依赖创建 DEPENDENT 代理节点 ----
        proxy_nodes = {}  # ext_task_id -> proxy_task_id_str
        for ext_task_id in ext_deps:
            ext_task = task_by_id.get(ext_task_id)
            if not ext_task:
                continue
            ext_system = task_system_map[ext_task_id]
            ext_wf_id = workflow_id_map.get(ext_system)

            proxy_id = f"dep_{ext_task_id}_wf{wf_id}"
            proxy_nodes[ext_task_id] = proxy_id

            # DEPENDENT 任务的 content JSON
            proxy_content = {
                "label": f"[依赖] {ext_task['task_name']} ({ext_system})",
                "name": f"dep_{ext_task['task_name']}",
                "taskType": "DEPENDENT",
                "workflowId": ext_wf_id,
                "taskId": str(ext_task_id),
            }

            # 复制被依赖任务的 cron 和 offset（DEPENDENT 需要知道何时检查）
            all_task_records.append({
                "id": proxy_id,
                "name": f"[依赖] {ext_task['task_name']}",
                "type": "DEPENDENT",
                "content": json.dumps(proxy_content, ensure_ascii=False),
                "cron": ext_task.get("task_cron"),
                "data_date_rule": build_data_date_rule(ext_task.get("offset")),
                "system_id": system_id,
            })

            # sys_task_dependency: 代理任务依赖外部真实任务
            all_task_deps.append((proxy_id, str(ext_task_id)))
            dep_proxy_tasks[(wf_id, ext_task_id)] = proxy_id

        # ---- 生成本系统的真实任务记录 ----
        for t in wf_tasks:
            task_type_new = convert_task_type(t["task_type"])
            content = build_content_json(t)
            content["taskType"] = task_type_new
            all_task_records.append({
                "id": str(t["id"]),
                "name": t["task_name"],
                "type": task_type_new,
                "content": json.dumps(content, ensure_ascii=False),
                "cron": t.get("task_cron"),
                "data_date_rule": build_data_date_rule(t.get("offset")),
                "system_id": system_id,
            })

        # ---- 构建工作流内的 edges 和 task_dependency ----
        edges = []  # (source_id_str, target_id_str)

        for t in wf_tasks:
            deps = parse_dependencies(t)
            task_id_str = str(t["id"])

            for dep_id in deps:
                if dep_id not in all_task_ids:
                    continue

                if dep_id in local_task_ids:
                    # 同系统依赖: 直接连边
                    source_id = str(dep_id)
                    edges.append((source_id, task_id_str))
                    all_task_deps.append((task_id_str, source_id))
                    all_job_deps.append((wf_id, source_id, task_id_str))
                else:
                    # 跨系统依赖: 通过 DEPENDENT 代理
                    proxy_id = proxy_nodes.get(dep_id)
                    if proxy_id:
                        edges.append((proxy_id, task_id_str))
                        all_task_deps.append((task_id_str, proxy_id))
                        all_job_deps.append((wf_id, proxy_id, task_id_str))

        # ---- 构建工作流 graph JSON ----
        # 收集此工作流的所有节点 ID
        node_ids = [str(t["id"]) for t in wf_tasks] + list(proxy_nodes.values())

        # 自动布局: 拓扑排序分层
        node_positions = auto_layout(node_ids, edges)

        # 构建 nodes JSON（workflow content 只存 label 和 type，task 数据在 sys_task 中）
        nodes_json = []
        for t in wf_tasks:
            tid = str(t["id"])
            pos = node_positions.get(tid, {"x": 0, "y": 0})
            nodes_json.append({
                "id": tid,
                "type": "taskNode",
                "position": pos,
                "data": {
                    "label": t["task_name"],
                    "type": convert_task_type(t["task_type"]),
                },
            })

        for ext_task_id, proxy_id in proxy_nodes.items():
            ext_task = task_by_id[ext_task_id]
            ext_system = task_system_map[ext_task_id]
            pos = node_positions.get(proxy_id, {"x": 0, "y": 0})
            nodes_json.append({
                "id": proxy_id,
                "type": "taskNode",
                "position": pos,
                "data": {
                    "label": f"[依赖] {ext_task['task_name']} ({ext_system})",
                    "type": "DEPENDENT",
                },
            })

        edges_json = []
        for src, tgt in edges:
            edges_json.append({
                "id": f"e{src}-{tgt}",
                "source": src,
                "target": tgt,
                "type": "smoothstep",
                "markerEnd": {"type": "ArrowClosed"},
                "style": {"stroke": "#94a3b8"},
            })

        graph = {"nodes": nodes_json, "edges": edges_json}

        workflows[system_name] = {
            "id": wf_id,
            "name": system_name,
            "system_id": system_id,
            "content": json.dumps(graph, ensure_ascii=False),
            "task_count": len(wf_tasks),
            "proxy_count": len(proxy_nodes),
            "edge_count": len(edges),
        }

    return workflows, all_task_records, all_task_deps, all_job_deps, warnings


def auto_layout(node_ids, edges):
    """
    简单的拓扑分层布局。
    按拓扑层级纵向排列，同层横向均匀分布。
    """
    if not node_ids:
        return {}

    # 构建邻接表
    graph = defaultdict(set)
    in_degree = {nid: 0 for nid in node_ids}
    node_set = set(node_ids)

    for src, tgt in edges:
        if src in node_set and tgt in node_set:
            graph[src].add(tgt)
            in_degree[tgt] = in_degree.get(tgt, 0) + 1

    # Kahn 拓扑排序分层
    layers = []
    queue = deque([n for n in node_ids if in_degree.get(n, 0) == 0])
    visited = set()

    while queue:
        layer = []
        for _ in range(len(queue)):
            node = queue.popleft()
            if node in visited:
                continue
            visited.add(node)
            layer.append(node)
            for neighbor in graph[node]:
                in_degree[neighbor] -= 1
                if in_degree[neighbor] == 0:
                    queue.append(neighbor)
        if layer:
            layers.append(layer)

    # 未被排序的节点（可能存在于孤立节点中）
    remaining = [n for n in node_ids if n not in visited]
    if remaining:
        layers.append(remaining)

    # 分配位置
    positions = {}
    x_spacing = 250
    y_spacing = 120

    for layer_idx, layer in enumerate(layers):
        for node_idx, node_id in enumerate(layer):
            positions[node_id] = {
                "x": node_idx * x_spacing + 50,
                "y": layer_idx * y_spacing + 50,
            }

    return positions


# ============================================================
# SQL 生成
# ============================================================

def generate_sql(workflows, all_task_records, all_task_deps, all_job_deps, warnings, output_dir):
    os.makedirs(output_dir, exist_ok=True)

    stats = {
        "workflows": len(workflows),
        "total_tasks": 0,
        "real_tasks": 0,
        "proxy_tasks": 0,
        "task_deps": len(all_task_deps),
        "job_deps": len(all_job_deps),
    }

    # ---- 01: sys_task ----
    task_path = os.path.join(output_dir, "01_sys_task.sql")
    with open(task_path, "w", encoding="utf-8") as f:
        f.write("-- 迁移自老系统 bspdb.t_quartz_task\n")
        f.write("-- 包含原始任务 + DEPENDENT 代理任务\n")
        f.write("-- 所有任务初始状态为禁用(status=0)\n\n")

        for rec in all_task_records:
            stats["total_tasks"] += 1
            if rec["type"] == "DEPENDENT":
                stats["proxy_tasks"] += 1
            else:
                stats["real_tasks"] += 1

            sid = str(rec["system_id"]) if rec["system_id"] is not None else "NULL"
            ddr = escape_sql(rec["data_date_rule"]) if rec["data_date_rule"] else "NULL"

            f.write(
                f"INSERT INTO sys_task "
                f"(id, name, type, content, system_id, cron_expression, "
                f"data_date_rule, status, priority, create_time, update_time) VALUES ("
                f"{escape_sql(rec['id'])}, "
                f"{escape_sql(rec['name'])}, "
                f"{escape_sql(rec['type'])}, "
                f"{escape_sql(rec['content'])}, "
                f"{sid}, "
                f"{escape_sql(rec['cron'])}, "
                f"{ddr}, "
                f"0, 0, NOW(), NOW());\n"
            )

    # ---- 02: sys_workflow ----
    wf_path = os.path.join(output_dir, "02_sys_workflow.sql")
    with open(wf_path, "w", encoding="utf-8") as f:
        f.write("-- 每个 task_system 对应一个工作流\n\n")
        for wf in sorted(workflows.values(), key=lambda w: w["id"]):
            sid = str(wf["system_id"]) if wf["system_id"] is not None else "NULL"
            f.write(
                f"INSERT INTO sys_workflow "
                f"(id, name, owner, description, content, system_id, create_time, update_time) VALUES ("
                f"{wf['id']}, "
                f"{escape_sql(wf['name'])}, "
                f"{escape_sql('system')}, "
                f"{escape_sql('迁移自老系统 - ' + wf['name'] + ' (任务:' + str(wf['task_count']) + ', 代理:' + str(wf['proxy_count']) + ')')}, "
                f"{escape_sql(wf['content'])}, "
                f"{sid}, "
                f"NOW(), NOW());\n"
            )

    # ---- 03: sys_task_dependency ----
    td_path = os.path.join(output_dir, "03_sys_task_dependency.sql")
    with open(td_path, "w", encoding="utf-8") as f:
        f.write("-- 任务级依赖（含跨工作流的 DEPENDENT 代理依赖）\n\n")
        for task_id, pre_task_id in all_task_deps:
            f.write(
                f"INSERT INTO sys_task_dependency (task_id, pre_task_id) VALUES ("
                f"{escape_sql(task_id)}, {escape_sql(pre_task_id)});\n"
            )

    # ---- 04: sys_job_dependency ----
    jd_path = os.path.join(output_dir, "04_sys_job_dependency.sql")
    with open(jd_path, "w", encoding="utf-8") as f:
        f.write("-- 工作流内的边（DAG 结构）\n\n")
        for wf_id, parent_id, child_id in all_job_deps:
            f.write(
                f"INSERT INTO sys_job_dependency (workflow_id, parent_job_name, child_job_name) VALUES ("
                f"{wf_id}, {escape_sql(parent_id)}, {escape_sql(child_id)});\n"
            )

    # ---- 报告 ----
    report_path = os.path.join(output_dir, "migration_report.txt")
    with open(report_path, "w", encoding="utf-8") as f:
        f.write("=" * 60 + "\n")
        f.write("  老系统调度任务迁移报告（工作流模式）\n")
        f.write("=" * 60 + "\n\n")

        f.write(f"工作流数量:          {stats['workflows']}\n")
        f.write(f"任务总数:            {stats['total_tasks']}\n")
        f.write(f"  原始任务:          {stats['real_tasks']}\n")
        f.write(f"  DEPENDENT 代理:    {stats['proxy_tasks']}\n")
        f.write(f"任务依赖关系:        {stats['task_deps']}\n")
        f.write(f"工作流边(DAG):       {stats['job_deps']}\n\n")

        f.write("工作流明细:\n")
        f.write(f"{'ID':<8} {'系统名称':<24} {'任务数':<8} {'代理数':<8} {'边数':<8}\n")
        f.write("-" * 60 + "\n")
        for wf in sorted(workflows.values(), key=lambda w: w["id"]):
            f.write(
                f"{wf['id']:<8} {wf['name']:<24} "
                f"{wf['task_count']:<8} {wf['proxy_count']:<8} {wf['edge_count']:<8}\n"
            )

        if warnings:
            f.write(f"\n告警 ({len(warnings)} 条):\n")
            for w in warnings[:100]:
                f.write(f"  [WARN] {w}\n")
            if len(warnings) > 100:
                f.write(f"  ... 还有 {len(warnings) - 100} 条告警\n")

        f.write("\n" + "=" * 60 + "\n")
        f.write("输出文件:\n")
        f.write(f"  {task_path}\n")
        f.write(f"  {wf_path}\n")
        f.write(f"  {td_path}\n")
        f.write(f"  {jd_path}\n")
        f.write("=" * 60 + "\n")

    return stats, report_path


# ============================================================
# 主程序
# ============================================================

def main():
    if len(sys.argv) < 2:
        print("用法: python3 migrate_quartz_tasks.py <t_quartz_task.sql> [output_dir]")
        sys.exit(1)

    sql_file = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "./output"

    if not os.path.exists(sql_file):
        print(f"错误: 文件不存在 {sql_file}")
        sys.exit(1)

    print(f"解析 SQL 文件: {sql_file}")
    tasks, parse_errors = parse_sql_file(sql_file)
    if parse_errors:
        print(f"解析错误: {len(parse_errors)} 条")
    print(f"成功解析 {len(tasks)} 条任务")

    # 检查未映射的系统
    unmapped = [k for k, v in SYSTEM_MAPPING.items() if v is None]
    if unmapped:
        print(f"\n注意: {len(unmapped)} 个系统尚未映射 systemId (workflow/task 的 systemId 将为 NULL)")

    print(f"\n构建工作流...")
    workflows, all_task_records, all_task_deps, all_job_deps, warnings = build_workflows(tasks)

    print(f"  工作流: {len(workflows)} 个")
    print(f"  任务: {len(all_task_records)} 条 (含 DEPENDENT 代理)")
    print(f"  依赖: {len(all_task_deps)} 条")
    print(f"  工作流边: {len(all_job_deps)} 条")

    if warnings:
        print(f"  告警: {len(warnings)} 条")

    print(f"\n生成 SQL 到 {output_dir}/")
    stats, report_path = generate_sql(workflows, all_task_records, all_task_deps, all_job_deps, warnings, output_dir)

    print(f"\n迁移完成! 详细报告: {report_path}")

    # 显示工作流摘要
    print(f"\n工作流摘要:")
    print(f"{'ID':<8} {'系统':<20} {'任务':<6} {'代理':<6} {'边':<6}")
    print("-" * 50)
    for wf in sorted(workflows.values(), key=lambda w: -w["task_count"]):
        print(f"{wf['id']:<8} {wf['name']:<20} {wf['task_count']:<6} {wf['proxy_count']:<6} {wf['edge_count']:<6}")


if __name__ == "__main__":
    main()
