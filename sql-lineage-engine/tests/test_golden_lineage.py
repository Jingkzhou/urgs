"""
黄金测试集 — 自动化血缘准确率测试

功能：
1. 自动发现 tests/golden/ 下的测试用例
2. 参数化运行每个用例
3. 对比实际解析结果 vs 预期结果
4. 计算 Precision / Recall / F1
5. 测试失败时打印详细 diff

文件规范：
- tests/golden/xxx.sql 或 xxx.prc  — 待解析的 SQL
- tests/golden/xxx.expected.json   — 人工标注的预期血缘
"""

import os
import sys
import json
import glob
import pytest
from typing import Dict, List, Set, Tuple, Any

# 确保项目根目录在 path 中
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)

GOLDEN_DIR = os.path.join(os.path.dirname(__file__), "golden")


# ============================================================
# 辅助函数
# ============================================================


def normalize_name(name: str) -> str:
    """标准化名称用于比较（大写 + 去引号）"""
    if not name:
        return ""
    return name.upper().replace("`", "").replace('"', "").replace("'", "").strip()


def make_table_lineage_set(
    sources: List[str], targets: List[str]
) -> Set[Tuple[str, str]]:
    """
    从 sources + targets 生成表级血缘对集合。
    每个 source -> 每个 target 构成一条表级血缘关系。
    """
    pairs = set()
    for s in sources:
        for t in targets:
            pairs.add((normalize_name(s), normalize_name(t)))
    return pairs


def make_column_lineage_set(
    column_lineage: List[Dict],
) -> Set[Tuple[str, str, str, str, str]]:
    """
    从字段级血缘列表生成可比较的元组集合。
    元组格式: (source_table, source_column, target_table, target_column, dependency_type)
    """
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


def calculate_metrics(actual: set, expected: set) -> Dict[str, Any]:
    """
    计算 Precision / Recall / F1。

    - Precision = |actual ∩ expected| / |actual|  （解析出来的有多少是对的）
    - Recall    = |actual ∩ expected| / |expected| （应该有的有多少被解析出来了）
    - F1        = 2 * P * R / (P + R)
    """
    if not actual and not expected:
        return {
            "precision": 1.0,
            "recall": 1.0,
            "f1": 1.0,
            "true_positives": set(),
            "false_positives": set(),
            "false_negatives": set(),
        }

    true_positives = actual & expected
    false_positives = actual - expected
    false_negatives = expected - actual

    precision = len(true_positives) / len(actual) if actual else 0.0
    recall = len(true_positives) / len(expected) if expected else 0.0
    f1 = (
        2 * precision * recall / (precision + recall)
        if (precision + recall) > 0
        else 0.0
    )

    return {
        "precision": round(precision, 4),
        "recall": round(recall, 4),
        "f1": round(f1, 4),
        "true_positives": true_positives,
        "false_positives": false_positives,
        "false_negatives": false_negatives,
    }


def format_diff(metrics: Dict, level: str) -> str:
    """格式化差异输出"""
    lines = []
    lines.append(f"\n{'='*60}")
    lines.append(f"{level} 血缘对比结果:")
    lines.append(f"  Precision: {metrics['precision']:.2%}")
    lines.append(f"  Recall:    {metrics['recall']:.2%}")
    lines.append(f"  F1:        {metrics['f1']:.2%}")

    if metrics["false_positives"]:
        lines.append(
            f"\n  ❌ 多余的血缘 (False Positives, 共 {len(metrics['false_positives'])} 条):"
        )
        for fp in sorted(metrics["false_positives"]):
            lines.append(f"    + {fp}")

    if metrics["false_negatives"]:
        lines.append(
            f"\n  ⚠️  遗漏的血缘 (False Negatives, 共 {len(metrics['false_negatives'])} 条):"
        )
        for fn in sorted(metrics["false_negatives"]):
            lines.append(f"    - {fn}")

    if not metrics["false_positives"] and not metrics["false_negatives"]:
        lines.append(f"\n  ✅ 完全匹配！")

    lines.append(f"{'='*60}")
    return "\n".join(lines)


# ============================================================
# 测试用例发现
# ============================================================


def discover_golden_cases() -> List[Tuple[str, str, str]]:
    """
    发现所有黄金测试用例。
    返回: [(test_id, sql_path, expected_path), ...]
    """
    cases = []
    if not os.path.isdir(GOLDEN_DIR):
        return cases

    expected_files = glob.glob(
        os.path.join(GOLDEN_DIR, "**", "*.expected.json"), recursive=True
    )
    for expected_path in sorted(expected_files):
        case_stem = expected_path[: -len(".expected.json")]
        test_id = os.path.relpath(case_stem, GOLDEN_DIR).replace(os.sep, "/")

        # 查找对应的 SQL 文件
        sql_path = None
        for ext in [".sql", ".prc", ".ddl"]:
            candidate = case_stem + ext
            if os.path.exists(candidate):
                sql_path = candidate
                break

        if sql_path:
            cases.append((test_id, sql_path, expected_path))

    return cases


# ============================================================
# 参数化测试
# ============================================================

golden_cases = discover_golden_cases()


@pytest.mark.parametrize(
    "test_id,sql_path,expected_path", golden_cases, ids=[c[0] for c in golden_cases]
)
def test_table_lineage(test_id, sql_path, expected_path, mock_metadata_resolver):
    """测试表级血缘的准确性"""
    from parsers.sql_parser import LineageParser

    # 1. 加载预期数据
    with open(expected_path, "r", encoding="utf-8") as f:
        expected_data = json.load(f)

    dialect = expected_data.get("dialect", "oracle")

    # 2. 读取 SQL
    sql_content = _read_sql_file(sql_path)

    # 3. 解析
    parser = LineageParser(dialect=dialect)
    result = parser.parse(sql_content, source_file=sql_path)

    # 4. 构建比较集合
    actual_table_pairs = set()
    for rel in result.get("relationships", []):
        src = normalize_name(rel.get("source", ""))
        tgt = normalize_name(rel.get("target", ""))
        if src and tgt:
            actual_table_pairs.add((src, tgt))

    # 如果 relationships 为空，从 sources x targets 构建
    if not actual_table_pairs:
        actual_table_pairs = make_table_lineage_set(
            result.get("sources", []), result.get("targets", [])
        )

    expected_tl = expected_data.get("table_lineage", {})
    # 优先使用精确 relationships 列表，没有时降级到 sources × targets 笛卡尔积
    if expected_tl.get("relationships"):
        expected_table_pairs = set(
            (normalize_name(r["source"]), normalize_name(r["target"]))
            for r in expected_tl["relationships"]
            if r.get("source") and r.get("target")
        )
    else:
        expected_table_pairs = make_table_lineage_set(
            expected_tl.get("sources", []), expected_tl.get("targets", [])
        )

    # 5. 计算指标
    metrics = calculate_metrics(actual_table_pairs, expected_table_pairs)

    # 6. 断言
    diff_msg = format_diff(metrics, "表级")
    assert (
        metrics["f1"] >= 0.8
    ), f"表级血缘 F1 分数过低: {metrics['f1']:.2%}\n{diff_msg}"


@pytest.mark.parametrize(
    "test_id,sql_path,expected_path", golden_cases, ids=[c[0] for c in golden_cases]
)
def test_column_lineage(test_id, sql_path, expected_path, mock_metadata_resolver):
    """测试字段级血缘的准确性"""
    from parsers.sql_parser import LineageParser

    # 1. 加载预期数据
    with open(expected_path, "r", encoding="utf-8") as f:
        expected_data = json.load(f)

    dialect = expected_data.get("dialect", "oracle")

    # 如果预期数据没有 column_lineage，跳过
    expected_columns = expected_data.get("column_lineage", [])
    if not expected_columns:
        pytest.skip(f"{test_id}: 无预期字段级血缘数据")

    # 2. 读取 SQL
    sql_content = _read_sql_file(sql_path)

    # 3. 解析
    parser = LineageParser(dialect=dialect)
    actual_deps = parser.get_column_lineage(sql_content, source_file=sql_path)

    # 4. 构建比较集合（只比较 fdd 直接数据流）
    actual_fdd = set()
    actual_all = set()
    for dep in actual_deps:
        entry = (
            normalize_name(dep.get("source_table", "")),
            normalize_name(dep.get("source_column", "")),
            normalize_name(dep.get("target_table", "")),
            normalize_name(dep.get("target_column", "")),
            dep.get("dependency_type", "fdd").lower(),
        )
        actual_all.add(entry)
        if entry[4] == "fdd":
            actual_fdd.add(entry)

    expected_set = make_column_lineage_set(expected_columns)
    expected_fdd = {e for e in expected_set if e[4] == "fdd"}
    expected_other = expected_set - expected_fdd

    # 5. 分层计算指标
    # 5a. 直接数据流 (fdd)
    fdd_metrics = calculate_metrics(actual_fdd, expected_fdd)

    # 5b. 间接数据流 (fdr, join 等)
    actual_other = actual_all - actual_fdd
    other_metrics = calculate_metrics(actual_other, expected_other)

    # 6. 断言（新语料可通过 quality_gates 使用更严格的门禁）
    diff_msg_fdd = format_diff(fdd_metrics, "字段级-直接流(fdd)")
    diff_msg_other = format_diff(other_metrics, "字段级-间接流(fdr/join)")
    quality_gates = expected_data.get("quality_gates", {})
    direct_f1_gate = quality_gates.get("direct_f1", 0.5)

    assert (
        fdd_metrics["f1"] >= direct_f1_gate
    ), f"字段级直接流 F1 分数过低: {fdd_metrics['f1']:.2%}\n{diff_msg_fdd}\n{diff_msg_other}"

    if expected_other:
        control_precision_gate = quality_gates.get("control_precision", 0.5)
        control_recall_gate = quality_gates.get("control_recall", 0.8)
        assert (
            other_metrics["precision"] >= control_precision_gate
            and other_metrics["recall"] >= control_recall_gate
        ), (
            f"字段级控制流门禁未通过: P={other_metrics['precision']:.2%}, "
            f"R={other_metrics['recall']:.2%}\n{diff_msg_other}"
        )


def _read_sql_file(path: str) -> str:
    """尝试多种编码读取 SQL 文件"""
    encodings = ["utf-8", "gbk", "gb2312", "gb18030", "latin-1"]
    for enc in encodings:
        try:
            with open(path, "r", encoding=enc) as f:
                return f.read()
        except UnicodeDecodeError:
            continue
    raise ValueError(f"无法解码文件: {path}")


def test_repeated_select_column_maps_by_position(mock_metadata_resolver):
    """同名投影列重复出现时，必须按 SELECT 位置映射到不同目标列。"""
    from parsers.sql_parser import LineageParser

    sql = """
    INSERT INTO IE_TY_TYJDFS_INC
      (datadate, corpid, nbjgh, IRS_CORP_ID)
    SELECT
      datadate,
      corpid,
      corpid,
      CASE
        WHEN CORPID LIKE '51%' THEN '510000'
        ELSE '990000'
      END
    FROM DATACORE_IE_TY_TYJDFS
    """

    parser = LineageParser(dialect="oracle", default_schema="IRS_DATACORE")
    actual = make_column_lineage_set(parser.get_column_lineage(sql))

    assert (
        "IRS_DATACORE.DATACORE_IE_TY_TYJDFS",
        "CORPID",
        "IRS_DATACORE.IE_TY_TYJDFS_INC",
        "NBJGH",
        "fdd",
    ) in actual


def test_subquery_projection_resolves_unqualified_columns_by_alias(mock_metadata_resolver):
    """外层无表别名字段必须按子查询输出列回溯，不能扩散到子查询内所有表。"""
    from parsers.indirect_flow_parser import IndirectFlowParser

    sql = """
    INSERT INTO TX_JRJG_YESTERDAY
    SELECT DISTINCT CUST_NAM, ORGTPCODE
      FROM (SELECT A.ACCDEPCODE,
                   B.REF_NUM,
                   B.CUST_ID,
                   C.CUST_NAM   AS CUST_NAM,
                   A.ORGTPCODE  AS ORGTPCODE
              FROM IE_TY_TYCKJC_YD A
              LEFT JOIN SMTMODS.L_ACCT_FUND_MMFUND B
                ON A.ACCDEPCODE = B.REF_NUM
              LEFT JOIN SMTMODS.L_CUST_ALL C
                ON B.CUST_ID = C.CUST_ID
             WHERE A.ORGTPCODE IS NOT NULL)
    """

    deps = IndirectFlowParser("oracle").parse(sql)
    actual = {
        (
            dep.get("source_table"),
            dep.get("source_column"),
            dep.get("target_table"),
            dep.get("target_column"),
            dep.get("dependency_type"),
        )
        for dep in deps
    }

    assert (
        "IE_TY_TYCKJC_YD",
        "ORGTPCODE",
        "TX_JRJG_YESTERDAY",
        "ORGTPCODE",
        "fdd",
    ) in actual
    assert (
        "SMTMODS.L_CUST_ALL",
        "ORGTPCODE",
        "TX_JRJG_YESTERDAY",
        "*",
        "fdd",
    ) not in actual


def test_case_when_unqualified_condition_uses_single_projection_alias(mock_metadata_resolver):
    """CASE 条件中的未限定字段在同一表达式只有一个明确别名时，应归属到该别名。"""
    from parsers.sql_parser import LineageParser

    sql = """
    INSERT INTO IE_TY_TYCKJC (deptermtype)
    SELECT CASE
             WHEN A.DEPTERMTYPE IS NULL OR FINADEPTYPE = 'A011' THEN '01'
             ELSE A.DEPTERMTYPE
           END
      FROM DATACORE_IE_TY_TYCKJC A
      LEFT JOIN DATACORE_TMP_TX_JRJG B
        ON A.CUST_NAME = B.CUST_ID
    """

    parser = LineageParser(dialect="oracle", default_schema="IRS_DATACORE")
    actual = make_column_lineage_set(parser.get_column_lineage(sql))

    assert (
        "IRS_DATACORE.DATACORE_IE_TY_TYCKJC",
        "FINADEPTYPE",
        "IRS_DATACORE.IE_TY_TYCKJC",
        "DEPTERMTYPE",
        "case_when",
    ) in actual


def test_case_when_unqualified_condition_uses_single_case_alias(mock_metadata_resolver):
    """CASE 条件中混用 T.COL 和 COL 时，未限定字段可归属到同一 CASE 表达式的唯一别名。"""
    from parsers.sql_parser import LineageParser

    sql = """
    INSERT INTO DATACORE_IE_TY_TYCKJC (finadeptype)
    SELECT CASE
             WHEN T.GL_ITEM_CODE LIKE '250202%' AND MATURE_DATE IS NOT NULL THEN 'A012'
             ELSE NULL
           END
      FROM SMTMODS.L_ACCT_FUND_MMFUND T
      LEFT JOIN CUST_TY_NEW A
        ON T.CUST_ID = A.CUST_ID
    """

    parser = LineageParser(dialect="oracle", default_schema="IRS_DATACORE")
    actual = make_column_lineage_set(parser.get_column_lineage(sql))

    assert (
        "SMTMODS.L_ACCT_FUND_MMFUND",
        "MATURE_DATE",
        "IRS_DATACORE.DATACORE_IE_TY_TYCKJC",
        "FINADEPTYPE",
        "case_when",
    ) in actual


def test_group_by_column_preserves_group_relation_type(mock_metadata_resolver):
    """GROUP BY 字段应保留 GROUPS 类型，不能被 fdr 默认映射覆盖成 FILTERS。"""
    from parsers.sql_parser import LineageParser

    sql = """
    INSERT INTO JS_201_DBWXX_TMP01
    SELECT T.ACCT_NUM, SUM(LOAN_ACCT_BAL) LOAN_ACCT_BAL
      FROM SMTMODS.L_ACCT_LOAN T
     WHERE T.DATA_DATE = IS_DATE
       AND T.LOAN_STOCKEN_DATE IS NULL
     GROUP BY T.ACCT_NUM
    HAVING SUM(LOAN_ACCT_BAL) > 0
    """

    parser = LineageParser(dialect="oracle", default_schema="PBOCD_DATACORE")
    deps = parser.get_column_lineage(sql)

    assert any(
        dep.get("source_table") == "SMTMODS.L_ACCT_LOAN"
        and dep.get("source_column") == "ACCT_NUM"
        and dep.get("target_table") == "PBOCD_DATACORE.JS_201_DBWXX_TMP01"
        and dep.get("dependency_type") == "fdr"
        and dep.get("neo4j_type") == "GROUPS"
        for dep in deps
    )


def test_minus_select_star_maps_each_left_projection_as_filter_dependency(mock_metadata_resolver):
    """MINUS/EXCEPT 右侧 SELECT * 应按左侧投影逐列影响目标，不能只落到第一列。"""
    from parsers.sql_parser import LineageParser

    sql = """
    INSERT INTO TX_JRJG_DIF
    SELECT DISTINCT CUST_NAM, ORGTPCODE
      FROM (SELECT A.CUST_NAME AS CUST_NAM,
                   NVL(B.JRJG, A.ORGTPCODE) AS ORGTPCODE
              FROM DATACORE_IE_TY_TYCKJC A
              LEFT JOIN DATACORE_TMP_TX_JRJG B
                ON A.CUST_NAME = B.CUST_ID)
    MINUS
    SELECT *
      FROM TX_JRJG_YESTERDAY
    """

    parser = LineageParser(dialect="oracle", default_schema="IRS_DATACORE")
    actual = make_column_lineage_set(parser.get_column_lineage(sql))

    assert (
        "IRS_DATACORE.TX_JRJG_YESTERDAY",
        "CUST_NAM",
        "IRS_DATACORE.TX_JRJG_DIF",
        "CUST_NAM",
        "fdr",
    ) in actual
    assert (
        "IRS_DATACORE.TX_JRJG_YESTERDAY",
        "ORGTPCODE",
        "IRS_DATACORE.TX_JRJG_DIF",
        "ORGTPCODE",
        "fdr",
    ) in actual
    assert (
        "IRS_DATACORE.TX_JRJG_YESTERDAY",
        "*",
        "IRS_DATACORE.TX_JRJG_DIF",
        "CUST_NAM",
        "fdd",
    ) not in actual


def test_statement_hash_ignores_comments_and_whitespace():
    from exporters.neo4j import Neo4jClient

    sql_with_comments = """
    /* ignored block */
    INSERT INTO TX_JRJG_YESTERDAY
      SELECT CUST_NAM -- ignored line
        FROM SMTMODS.L_CUST_ALL;
    """
    sql_without_comments = "INSERT  INTO TX_JRJG_YESTERDAY SELECT CUST_NAM FROM SMTMODS.L_CUST_ALL"

    assert Neo4jClient._statement_hash(sql_with_comments) == Neo4jClient._statement_hash(
        sql_without_comments
    )


# ============================================================
# 汇总报告（作为最后一个测试运行）
# ============================================================


def test_golden_summary_report(mock_metadata_resolver):
    """生成所有黄金用例的汇总统计报告"""
    from parsers.sql_parser import LineageParser

    cases = discover_golden_cases()
    if not cases:
        pytest.skip("未找到黄金测试用例")

    report_lines = []
    report_lines.append("\n" + "=" * 70)
    report_lines.append("📊 黄金测试集汇总报告")
    report_lines.append("=" * 70)
    report_lines.append(
        f"{'用例':<30} {'表级F1':>8} {'字段F1(fdd)':>12} {'字段F1(all)':>12}"
    )
    report_lines.append("-" * 70)

    total_table_tp = 0
    total_table_fp = 0
    total_table_fn = 0
    total_col_tp = 0
    total_col_fp = 0
    total_col_fn = 0

    for test_id, sql_path, expected_path in cases:
        with open(expected_path, "r", encoding="utf-8") as f:
            expected_data = json.load(f)

        dialect = expected_data.get("dialect", "oracle")
        sql_content = _read_sql_file(sql_path)

        parser = LineageParser(dialect=dialect)

        # 表级
        result = parser.parse(sql_content, source_file=sql_path)
        actual_table_pairs = set()
        for rel in result.get("relationships", []):
            src = normalize_name(rel.get("source", ""))
            tgt = normalize_name(rel.get("target", ""))
            if src and tgt:
                actual_table_pairs.add((src, tgt))
        if not actual_table_pairs:
            actual_table_pairs = make_table_lineage_set(
                result.get("sources", []), result.get("targets", [])
            )

        expected_tl = expected_data.get("table_lineage", {})
        if expected_tl.get("relationships"):
            expected_table_pairs = set(
                (normalize_name(r["source"]), normalize_name(r["target"]))
                for r in expected_tl["relationships"]
                if r.get("source") and r.get("target")
            )
        else:
            expected_table_pairs = make_table_lineage_set(
                expected_tl.get("sources", []), expected_tl.get("targets", [])
            )
        table_metrics = calculate_metrics(actual_table_pairs, expected_table_pairs)

        total_table_tp += len(table_metrics["true_positives"])
        total_table_fp += len(table_metrics["false_positives"])
        total_table_fn += len(table_metrics["false_negatives"])

        # 字段级
        col_f1_fdd = "N/A"
        col_f1_all = "N/A"
        expected_columns = expected_data.get("column_lineage", [])
        if expected_columns:
            actual_deps = parser.get_column_lineage(sql_content, source_file=sql_path)
            actual_col_set = make_column_lineage_set(actual_deps)
            expected_col_set = make_column_lineage_set(expected_columns)

            # fdd only
            actual_fdd = {e for e in actual_col_set if e[4] == "fdd"}
            expected_fdd = {e for e in expected_col_set if e[4] == "fdd"}
            fdd_m = calculate_metrics(actual_fdd, expected_fdd)
            col_f1_fdd = f"{fdd_m['f1']:.2%}"

            # all
            all_m = calculate_metrics(actual_col_set, expected_col_set)
            col_f1_all = f"{all_m['f1']:.2%}"

            total_col_tp += len(all_m["true_positives"])
            total_col_fp += len(all_m["false_positives"])
            total_col_fn += len(all_m["false_negatives"])

        report_lines.append(
            f"{test_id:<30} {table_metrics['f1']:>7.2%} {col_f1_fdd:>12} {col_f1_all:>12}"
        )

    # 汇总
    report_lines.append("-" * 70)

    def safe_f1(tp, fp, fn):
        p = tp / (tp + fp) if (tp + fp) > 0 else 0
        r = tp / (tp + fn) if (tp + fn) > 0 else 0
        return 2 * p * r / (p + r) if (p + r) > 0 else 0

    overall_table_f1 = safe_f1(total_table_tp, total_table_fp, total_table_fn)
    overall_col_f1 = safe_f1(total_col_tp, total_col_fp, total_col_fn)

    report_lines.append(
        f"{'整体汇总':<30} {overall_table_f1:>7.2%} {'':>12} {overall_col_f1:>11.2%}"
    )
    report_lines.append("=" * 70)

    report = "\n".join(report_lines)
    print(report)

    # 不断言，只输出报告
    assert True
