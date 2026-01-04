import json
import os
import sys

# 将当前工作目录添加到 Python 路径，确保可以正确导入 app 模块
sys.path.append(os.getcwd())

from app.services.vector_store import vector_store_service


def load_eval_set(path: str):
    """
    加载评估集数据。
    """
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def build_dataset(k: int = 4):
    """
    构建符合 Ragas 评估格式的数据集。
    
    Ragas 需要包含 question, answer, contexts (检索到的片段), ground_truth 的数据集。
    """
    data = load_eval_set(os.path.join(os.getcwd(), "eval", "eval_set.json"))
    rows = []
    print(f"正在对 {len(data)} 个样本运行混合检索，构建 Ragas 评估数据集...")
    
    for item in data:
        query = item["question"]
        # 执行混合检索获取上下文环境
        results = vector_store_service.hybrid_search(query, k=k)
        contexts = [r["document"].page_content[:1000] for r in results]
        
        rows.append({
            "question": query,
            "answer": item.get("answer", ""),          # LLM 生成的答案（若有）
            "contexts": contexts,                      # 检索到的实际上下文
            "ground_truth": item.get("answer", ""),    # 这里的 ground_truth 暂设为标准答案
        })
    return rows


def run_ragas():
    """
    运行 Ragas 评估，综合考核 RAG 系统的检索和生成质量。
    
    评估维度：
    1. context_recall: 上下文召回率（检索出的内容是否包含正确答案）
    2. context_precision: 上下文精确度（检索出的内容是否高度相关且无噪声）
    3. answer_relevancy: 回答相关性（生成的答案是否针对问题本身）
    4. faithfulness: 忠实度（生成的答案是否完全基于检索到的上下文，有无幻觉）
    """
    try:
        from ragas import evaluate
        from ragas.metrics import (
            context_recall,
            context_precision,
            answer_relevancy,
            faithfulness,
        )
        from datasets import Dataset

        # 将列表转换为 HuggingFace Dataset 格式
        dataset = Dataset.from_list(build_dataset())
        
        print("正在调用 LLM 作为裁判运行 Ragas 自动化评估...")
        result = evaluate(
            dataset,
            metrics=[context_recall, context_precision, answer_relevancy, faithfulness],
        )
        print("\n--- Ragas 自动化评估结果 ---")
        print(result)
    except Exception as e:
        print(f"Ragas 评估运行失败: {e}")
        print("请检查 ragas 依赖是否安装，以及 OpenAI/Qwen API 环境变量配置。")


if __name__ == "__main__":
    # 执行评估流水线
    run_ragas()
