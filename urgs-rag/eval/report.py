"""
评估报告生成模块。

支持 JSON 详情报告和终端文本摘要。
"""

import json
from datetime import datetime
from typing import Any


def generate_report(
    eval_result: dict[str, Any],
    samples: list[dict],
    output_path: str,
    agent_url: str = "",
    dataset_size: int = 0,
) -> str:
    """
    生成评估报告。

    Args:
        eval_result: Ragas evaluate() 返回的结果字典
        samples: 每条样本的详细评分
        output_path: JSON 报告输出路径
        agent_url: 被测 Agent 端点
        dataset_size: 数据集大小

    Returns:
        终端摘要文本
    """
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    # 构建 JSON 报告
    report = {
        "meta": {
            "eval_time": now,
            "agent_url": agent_url,
            "dataset_size": dataset_size,
        },
        "summary": eval_result,
        "samples": samples,
    }

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)

    # 构建终端摘要
    lines = [
        "",
        "=" * 50,
        "  URGS RAG 评估报告",
        "=" * 50,
        f"  评估时间: {now}",
        f"  数据集大小: {dataset_size} 条",
        f"  Agent 端点: {agent_url}",
        "",
        "  指标汇总:",
    ]

    for metric_name, score in eval_result.items():
        if isinstance(score, (int, float)):
            bar = _score_bar(score)
            lines.append(f"    {metric_name:<25s} {score:.4f}  {bar}")

    # 低分样本告警
    low_score_samples = _find_low_score_samples(samples, threshold=0.5)
    if low_score_samples:
        lines.append("")
        lines.append(f"  低分样本 (Faithfulness < 0.5): {len(low_score_samples)} 条")
        for s in low_score_samples[:5]:
            q = s.get("question", "")[:60]
            score = s.get("faithfulness", 0)
            lines.append(f"    - [{score:.2f}] {q}")
        if len(low_score_samples) > 5:
            lines.append(f"    ... 还有 {len(low_score_samples) - 5} 条")

    lines.append("")
    lines.append(f"  详细报告: {output_path}")
    lines.append("=" * 50)

    return "\n".join(lines)


def _score_bar(score: float, width: int = 20) -> str:
    """生成评分进度条。"""
    filled = int(score * width)
    bar = "#" * filled + "-" * (width - filled)
    return f"[{bar}]"


def _find_low_score_samples(
    samples: list[dict], threshold: float = 0.5
) -> list[dict]:
    """筛选低分样本。"""
    return [
        s
        for s in samples
        if s.get("faithfulness") is not None and s["faithfulness"] < threshold
    ]
