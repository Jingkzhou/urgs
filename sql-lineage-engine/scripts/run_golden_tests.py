#!/usr/bin/env python3
"""
黄金测试集 — 独立度量报告生成器

可脱离 pytest 直接运行，生成 Markdown 格式的准确率报告。
用法：
    python scripts/run_golden_tests.py
    python scripts/run_golden_tests.py --output report.md
"""
import os
import sys
import json
import glob
import argparse
from datetime import datetime

# 将项目根目录加入 path
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, PROJECT_ROOT)

GOLDEN_DIR = os.path.join(PROJECT_ROOT, "tests", "golden")

# Mock MetadataResolver 避免 API 依赖
from unittest.mock import patch

mock_meta = patch(
    "utils.metadata_resolver.MetadataResolver.get_table_metadata", return_value=None
)
mock_val = patch(
    "utils.metadata_resolver.MetadataResolver.validate_column",
    return_value={"exists": None, "confidence": "MEDIUM", "note": "Mocked"},
)
mock_fields = patch(
    "utils.metadata_resolver.MetadataResolver.get_table_fields", return_value=[]
)
mock_meta.start()
mock_val.start()
mock_fields.start()


def normalize_name(name):
    if not name:
        return ""
    return name.upper().replace("`", "").replace('"', "").replace("'", "").strip()


def make_table_pairs(sources, targets):
    pairs = set()
    for s in sources:
        for t in targets:
            pairs.add((normalize_name(s), normalize_name(t)))
    return pairs


def make_expected_table_pairs(table_lineage):
    """Prefer annotated direct relationships over a Cartesian-product fallback."""
    relationships = table_lineage.get("relationships") or []
    if relationships:
        return {
            (normalize_name(item.get("source")), normalize_name(item.get("target")))
            for item in relationships
            if item.get("source") and item.get("target")
        }
    return make_table_pairs(
        table_lineage.get("sources", []), table_lineage.get("targets", [])
    )


def make_column_set(column_lineage):
    result = set()
    for dep in column_lineage:
        result.add(
            (
                normalize_name(dep.get("source_table", "")),
                normalize_name(dep.get("source_column", "")),
                normalize_name(dep.get("target_table", "")),
                normalize_name(dep.get("target_column", "")),
                dep.get("dependency_type", "fdd").lower(),
            )
        )
    return result


def calc_metrics(actual, expected):
    if not actual and not expected:
        return 1.0, 1.0, 1.0, set(), set(), set()
    tp = actual & expected
    fp = actual - expected
    fn = expected - actual
    p = len(tp) / len(actual) if actual else 0
    r = len(tp) / len(expected) if expected else 0
    f1 = 2 * p * r / (p + r) if (p + r) > 0 else 0
    return round(p, 4), round(r, 4), round(f1, 4), tp, fp, fn


def read_sql(path):
    for enc in ["utf-8", "gbk", "gb2312", "gb18030", "latin-1"]:
        try:
            with open(path, "r", encoding=enc) as f:
                return f.read()
        except UnicodeDecodeError:
            continue
    raise ValueError(f"无法解码: {path}")


def discover_cases():
    cases = []
    if not os.path.isdir(GOLDEN_DIR):
        return cases
    pattern = os.path.join(GOLDEN_DIR, "**", "*.expected.json")
    for ep in sorted(glob.glob(pattern, recursive=True)):
        case_stem = ep[: -len(".expected.json")]
        test_id = os.path.relpath(case_stem, GOLDEN_DIR).replace(os.sep, "/")
        for ext in [".sql", ".prc", ".ddl"]:
            sp = case_stem + ext
            if os.path.exists(sp):
                cases.append((test_id, sp, ep))
                break
    return cases


def run_report(output_path=None):
    from parsers.sql_parser import LineageParser

    cases = discover_cases()
    if not cases:
        print("⚠️  未找到黄金测试用例，请确认 tests/golden/ 目录已填充")
        return

    lines = []
    lines.append(f"# 血缘解析准确率报告")
    lines.append(f"")
    lines.append(f"**生成时间**: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    lines.append(f"**测试用例数**: {len(cases)}")
    lines.append(f"")

    # 表级汇总
    lines.append(f"## 表级血缘")
    lines.append(f"")
    lines.append(f"| 用例 | 预期 | 实际 | TP | FP | FN | Precision | Recall | F1 |")
    lines.append(f"|------|------|------|----|----|----|-----------:|-------:|----:|")

    t_tp_total, t_fp_total, t_fn_total = 0, 0, 0
    direct_tp_total, direct_fp_total, direct_fn_total = 0, 0, 0
    control_tp_total, control_fp_total, control_fn_total = 0, 0, 0
    strict_direct_tp, strict_direct_fp, strict_direct_fn = 0, 0, 0
    strict_direct_case_count = 0
    strict_control_case_count = 0

    detail_sections = []

    for test_id, sql_path, expected_path in cases:
        with open(expected_path, "r", encoding="utf-8") as f:
            expected_data = json.load(f)

        dialect = expected_data.get("dialect", "oracle")
        sql = read_sql(sql_path)
        parser = LineageParser(dialect=dialect)

        # 表级
        result = parser.parse(sql, source_file=sql_path)
        actual_pairs = set()
        for rel in result.get("relationships", []):
            s = normalize_name(rel.get("source", ""))
            t = normalize_name(rel.get("target", ""))
            if s and t:
                actual_pairs.add((s, t))
        if not actual_pairs:
            actual_pairs = make_table_pairs(
                result.get("sources", []), result.get("targets", [])
            )

        etl = expected_data.get("table_lineage", {})
        expected_pairs = make_expected_table_pairs(etl)
        p, r, f1, tp, fp, fn = calc_metrics(actual_pairs, expected_pairs)

        t_tp_total += len(tp)
        t_fp_total += len(fp)
        t_fn_total += len(fn)

        lines.append(
            f"| {test_id} | {len(expected_pairs)} | {len(actual_pairs)} | "
            f"{len(tp)} | {len(fp)} | {len(fn)} | {p:.2%} | {r:.2%} | **{f1:.2%}** |"
        )

        # 字段级详情
        detail = []
        detail.append(f"### {test_id}")
        detail.append(f"")
        detail.append(f"**描述**: {expected_data.get('description', 'N/A')}")
        detail.append(f"")

        if fp:
            detail.append(f"**表级多余血缘 (FP)**:")
            for item in sorted(fp):
                detail.append(f"- `{item[0]}` → `{item[1]}`")
            detail.append(f"")
        if fn:
            detail.append(f"**表级遗漏血缘 (FN)**:")
            for item in sorted(fn):
                detail.append(f"- `{item[0]}` → `{item[1]}`")
            detail.append(f"")

        # 字段级
        expected_cols = expected_data.get("column_lineage", [])
        if expected_cols:
            actual_deps = parser.get_column_lineage(sql, source_file=sql_path)
            actual_col = make_column_set(actual_deps)
            expected_col = make_column_set(expected_cols)

            actual_fdd = {e for e in actual_col if e[4] == "fdd"}
            expected_fdd = {e for e in expected_col if e[4] == "fdd"}
            cp, cr, cf1, ctp, cfp, cfn = calc_metrics(actual_fdd, expected_fdd)
            direct_tp_total += len(ctp)
            direct_fp_total += len(cfp)
            direct_fn_total += len(cfn)

            quality_gates = expected_data.get("quality_gates", {})
            if "direct_f1" in quality_gates:
                strict_direct_tp += len(ctp)
                strict_direct_fp += len(cfp)
                strict_direct_fn += len(cfn)
                strict_direct_case_count += 1

            actual_control = actual_col - actual_fdd
            expected_control = expected_col - expected_fdd
            _, _, _, control_tp, control_fp, control_fn = calc_metrics(
                actual_control, expected_control
            )
            if "control_precision" in quality_gates and "control_recall" in quality_gates:
                control_tp_total += len(control_tp)
                control_fp_total += len(control_fp)
                control_fn_total += len(control_fn)
                strict_control_case_count += 1

            detail.append(f"**字段级 (fdd)**: P={cp:.2%} R={cr:.2%} F1={cf1:.2%}")
            detail.append(f"")
            if cfp:
                detail.append(f"多余 (FP, {len(cfp)} 条):")
                for item in sorted(cfp):
                    detail.append(f"- `{item[0]}.{item[1]}` → `{item[2]}.{item[3]}`")
                detail.append(f"")
            if cfn:
                detail.append(f"遗漏 (FN, {len(cfn)} 条):")
                for item in sorted(cfn):
                    detail.append(f"- `{item[0]}.{item[1]}` → `{item[2]}.{item[3]}`")
                detail.append(f"")

        detail_sections.append("\n".join(detail))

    # 表级汇总行
    def safe_f1(tp, fp, fn):
        p = tp / (tp + fp) if (tp + fp) > 0 else 0
        r = tp / (tp + fn) if (tp + fn) > 0 else 0
        return 2 * p * r / (p + r) if (p + r) > 0 else 0

    overall_p = (
        t_tp_total / (t_tp_total + t_fp_total) if (t_tp_total + t_fp_total) > 0 else 0
    )
    overall_r = (
        t_tp_total / (t_tp_total + t_fn_total) if (t_tp_total + t_fn_total) > 0 else 0
    )
    overall_f1 = safe_f1(t_tp_total, t_fp_total, t_fn_total)

    lines.append(
        f"| **汇总** | | | "
        f"**{t_tp_total}** | **{t_fp_total}** | **{t_fn_total}** | "
        f"**{overall_p:.2%}** | **{overall_r:.2%}** | **{overall_f1:.2%}** |"
    )
    lines.append(f"")

    def aggregate_metrics(tp, fp, fn):
        precision = tp / (tp + fp) if tp + fp else 1.0
        recall = tp / (tp + fn) if tp + fn else 1.0
        f1 = (
            2 * precision * recall / (precision + recall)
            if precision + recall
            else 0.0
        )
        return precision, recall, f1

    direct_p, direct_r, direct_f1 = aggregate_metrics(
        direct_tp_total, direct_fp_total, direct_fn_total
    )
    strict_direct_p, strict_direct_r, strict_direct_f1 = aggregate_metrics(
        strict_direct_tp, strict_direct_fp, strict_direct_fn
    )
    control_p, control_r, control_f1 = aggregate_metrics(
        control_tp_total, control_fp_total, control_fn_total
    )
    lines.append("## 字段级血缘汇总")
    lines.append("")
    lines.append("| 类型 | TP | FP | FN | Precision | Recall | F1 |")
    lines.append("|------|---:|---:|---:|----------:|-------:|---:|")
    lines.append(
        f"| 严格标注直接流 fdd ({strict_direct_case_count} 用例) | {strict_direct_tp} | {strict_direct_fp} | {strict_direct_fn} | "
        f"{strict_direct_p:.2%} | {strict_direct_r:.2%} | **{strict_direct_f1:.2%}** |"
    )
    lines.append(
        f"| 旧语料严格集合差异 (诊断) | {direct_tp_total} | {direct_fp_total} | {direct_fn_total} | "
        f"{direct_p:.2%} | {direct_r:.2%} | **{direct_f1:.2%}** |"
    )
    lines.append(
        f"| 严格标注控制流 fdr/join ({strict_control_case_count} 用例) | {control_tp_total} | {control_fp_total} | {control_fn_total} | "
        f"{control_p:.2%} | {control_r:.2%} | **{control_f1:.2%}** |"
    )
    lines.append("")
    lines.append("> 旧存储过程语料中的 `*` 和表达式字段是部分标注，不具备完整负样本，故仅作为差异诊断；Precision/Recall 门禁只统计显式配置 `quality_gates` 的完整标注用例。")
    lines.append("")

    # 详情部分
    lines.append(f"## 用例详情")
    lines.append(f"")
    for section in detail_sections:
        lines.append(section)
        lines.append(f"---")
        lines.append(f"")

    report = "\n".join(lines)

    if output_path:
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(report)
        print(f"✅ 报告已保存到: {output_path}")
    else:
        print(report)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="黄金测试集准确率报告生成器")
    parser.add_argument("--output", "-o", help="输出文件路径 (默认输出到 stdout)")
    args = parser.parse_args()
    run_report(args.output)
