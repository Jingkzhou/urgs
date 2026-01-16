import json
import os
import sys
from typing import List

# 将当前工作目录添加到 Python 路径，确保可以正确导入 app 模块
sys.path.append(os.getcwd())

from app.services.vector_store import vector_store_service


def load_eval_set(path: str) -> List[dict]:
    """
    从指定路径加载评估数据集（JSON 格式）。
    """
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def match_source(doc_meta: dict, expected: str) -> bool:
    """
    检查检索到的文档元数据是否与期望的来源匹配。

    Args:
        doc_meta (dict): 检索到的文档元数据。
        expected (str): 期望的文件名或来源标识。

    Returns:
        bool: 是否匹配成功。
    """
    if not expected or expected == "TBD":
        return False
    # 支持从 file_name 或 source 字段进行模糊匹配
    file_name = doc_meta.get("file_name") or doc_meta.get("source") or ""
    return expected in file_name


def evaluate(k: int = 5):
    """
    运行检索评估流程，计算 Hit@K, MRR 和 覆盖率。

    Args:
        k (int): 检索深度。
    """
    eval_path = os.path.join(os.getcwd(), "eval", "eval_set.json")
    if not os.path.exists(eval_path):
        print(f"评估集不存在: {eval_path}")
        return

    data = load_eval_set(eval_path)

    hits = 0        # 命中次数（至少有一个结果匹配预期来源）
    rr_sum = 0.0    # 倒数排名之和（用于计算 MRR）
    covered = 0     # 覆盖次数（检索结果不为空的次数）

    for item in data:
        query = item["question"]
        expected = item.get("source")
        
        # 执行混合检索
        results = vector_store_service.hybrid_search(query, k=k)
        if results:
            covered += 1
            
        rank = None
        # 在 Top K 结果中寻找匹配项
        for idx, result in enumerate(results, 1):
            doc = result["document"]
            if match_source(doc.metadata, expected):
                rank = idx
                break
        
        if rank:
            hits += 1
            # 计算倒数排名 (Reciprocal Rank)
            rr_sum += 1.0 / rank

    # 计算最终指标
    total = len(data)
    hit_at_k = hits / total if total else 0
    mrr = rr_sum / total if total else 0
    coverage = covered / total if total else 0

    print("--- 检索模型评估汇总 ---")
    print(f"总样本量: {total}")
    print(f"Hit@{k}: {hit_at_k:.3f} (在 Top {k} 中找到正确答案的概率)")
    print(f"MRR: {mrr:.3f} (平均倒数排名，衡量排序靠前程度)")
    print(f"覆盖率: {coverage:.3f} (系统对问题的响应率)")


if __name__ == "__main__":
    # 默认评估 Top 5 检索效果
    evaluate(k=5)
