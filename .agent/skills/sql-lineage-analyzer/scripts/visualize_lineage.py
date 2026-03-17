#!/usr/bin/env python3
"""
血缘可视化工具 - 生成 Mermaid 图

支持输入格式:
- parse_lineage.py 的 parse() 输出（表级）
- parse_lineage.py 的 get_column_lineage() 输出（字段级）
- 传统的单条/列表 JSON 格式

用法:
  python visualize_lineage.py <lineage_json> [table|column|impact <table_name>]
"""

import json
import sys
from typing import Union


def generate_mermaid_table_level(lineage_data: Union[dict, list]) -> str:
    """
    生成表级血缘 Mermaid 图

    支持两种输入格式:
    - 引擎格式: {"sources": [...], "targets": [...], "relationships": [...]}
    - 传统格式: [{"source_tables": [...], "target_table": "...", "statement_type": "..."}]
    """
    lines = ["graph LR"]
    edges = set()

    # 处理引擎格式
    if isinstance(lineage_data, dict) and "relationships" in lineage_data:
        for rel in lineage_data.get("relationships", []):
            src = rel.get("source") or rel.get("source_table", "")
            tgt = rel.get("target") or rel.get("target_table", "")
            rel_type = rel.get("type") or rel.get("dependency_type", "fdd")
            if src and tgt:
                src_id = src.replace(".", "_").replace("-", "_").replace("$", "_")
                tgt_id = tgt.replace(".", "_").replace("-", "_").replace("$", "_")
                edge = f'    {src_id}["{src}"] --> |{rel_type}| {tgt_id}["{tgt}"]'
                edges.add(edge)
    else:
        # 传统格式
        if isinstance(lineage_data, dict):
            lineage_data = [lineage_data]
        for item in lineage_data:
            target = item.get("target_table") or "RESULT"
            sources = item.get("source_tables", [])
            stmt_type = item.get("statement_type", "")
            target_id = target.replace(".", "_").replace("-", "_")
            for src in sources:
                src_id = src.replace(".", "_").replace("-", "_")
                edge = (
                    f'    {src_id}["{src}"] --> |{stmt_type}| {target_id}["{target}"]'
                )
                edges.add(edge)

    lines.extend(sorted(edges))
    lines.append("")
    lines.append("    %% 样式定义")
    lines.append("    classDef source fill:#e1f5fe,stroke:#01579b")
    lines.append("    classDef target fill:#fff3e0,stroke:#e65100")

    return "\n".join(lines)


def generate_mermaid_column_level(lineage_data: Union[dict, list]) -> str:
    """
    生成字段级血缘 Mermaid 图

    支持两种输入格式:
    - 引擎格式: [{"source_table", "source_column", "target_table", "target_column", "dependency_type"}]
    - 传统格式: [{"column_lineages": [...]}]
    """
    lines = ["graph LR"]
    subgraphs = {}
    edges = []

    items = []
    if isinstance(lineage_data, list):
        # 检测是否为引擎字段级输出（列表中每项含 source_table/target_table）
        if lineage_data and "source_table" in lineage_data[0]:
            items = lineage_data
        else:
            # 传统格式
            for item in lineage_data:
                for col in item.get("column_lineages", []):
                    items.append(col)
    elif isinstance(lineage_data, dict):
        if "column_lineages" in lineage_data:
            items = lineage_data["column_lineages"]
        elif "relationships" in lineage_data:
            items = [r for r in lineage_data["relationships"] if r.get("target_column")]

    for col in items:
        src_table = col.get("source_table", "UNKNOWN")
        src_col = col.get("source_column", "")
        tgt_table = col.get("target_table", "RESULT")
        tgt_col = col.get("target_column", "")
        transform = col.get("transform_type") or col.get("dependency_type", "")

        if not src_col or not tgt_col:
            continue

        if src_table not in subgraphs:
            subgraphs[src_table] = set()
        subgraphs[src_table].add(src_col)

        if tgt_table not in subgraphs:
            subgraphs[tgt_table] = set()
        subgraphs[tgt_table].add(tgt_col)

        src_id = (
            f"{src_table}_{src_col}".replace(".", "_")
            .replace("-", "_")
            .replace("$", "_")
        )
        tgt_id = (
            f"{tgt_table}_{tgt_col}".replace(".", "_")
            .replace("-", "_")
            .replace("$", "_")
        )

        if transform and transform.upper() not in ["DIRECT", "FDD"]:
            edges.append(f"    {src_id} --> |{transform}| {tgt_id}")
        else:
            edges.append(f"    {src_id} --> {tgt_id}")

    for table, cols in subgraphs.items():
        table_id = table.replace(".", "_").replace("-", "_").replace("$", "_")
        lines.append(f'    subgraph {table_id}["{table}"]')
        for col in sorted(cols):
            col_id = (
                f"{table}_{col}".replace(".", "_").replace("-", "_").replace("$", "_")
            )
            lines.append(f'        {col_id}["{col}"]')
        lines.append("    end")
        lines.append("")

    lines.extend(edges)
    lines.append("")
    lines.append("    %% 样式")
    lines.append("    classDef transform fill:#fff9c4,stroke:#f57f17")

    return "\n".join(lines)


def generate_impact_analysis(
    lineage_data: Union[dict, list], changed_table: str
) -> dict:
    """生成影响分析报告"""
    downstream = {}
    upstream = {}

    # 提取关系
    relationships = []
    if isinstance(lineage_data, dict) and "relationships" in lineage_data:
        relationships = lineage_data["relationships"]
    elif isinstance(lineage_data, list):
        if lineage_data and "relationships" in lineage_data[0]:
            for item in lineage_data:
                relationships.extend(item.get("relationships", []))
        else:
            relationships = lineage_data

    for rel in relationships:
        src = rel.get("source") or rel.get("source_table", "")
        tgt = rel.get("target") or rel.get("target_table", "")
        if src and tgt:
            upstream.setdefault(tgt, []).append(src)
            downstream.setdefault(src, []).append(tgt)

    def find_downstream(table, visited=None):
        if visited is None:
            visited = set()
        if table in visited:
            return []
        visited.add(table)
        result = []
        for dep in downstream.get(table, []):
            result.append(dep)
            result.extend(find_downstream(dep, visited))
        return result

    def find_upstream(table, visited=None):
        if visited is None:
            visited = set()
        if table in visited:
            return []
        visited.add(table)
        result = []
        for src in upstream.get(table, []):
            result.append(src)
            result.extend(find_upstream(src, visited))
        return result

    affected = find_downstream(changed_table)
    dependencies = find_upstream(changed_table)

    return {
        "changed_table": changed_table,
        "direct_downstream": downstream.get(changed_table, []),
        "all_affected": list(set(affected)),
        "affected_count": len(set(affected)),
        "dependencies": list(set(dependencies)),
        "risk_level": (
            "HIGH" if len(affected) > 5 else "MEDIUM" if len(affected) > 2 else "LOW"
        ),
    }


def main():
    """命令行入口"""
    if len(sys.argv) < 2:
        print("用法:")
        print("  python visualize_lineage.py <lineage_json> [table|column]")
        print("  python visualize_lineage.py <lineage_json> impact <table_name>")
        sys.exit(1)

    json_file = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else "table"

    with open(json_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    if mode == "impact" and len(sys.argv) > 3:
        table_name = sys.argv[3]
        result = generate_impact_analysis(data, table_name)
        print(json.dumps(result, ensure_ascii=False, indent=2))
    elif mode == "column":
        print(generate_mermaid_column_level(data))
    else:
        print(generate_mermaid_table_level(data))


if __name__ == "__main__":
    main()
