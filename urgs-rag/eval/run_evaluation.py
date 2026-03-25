"""
Ragas 离线评估脚本。

加载测试数据集，调用 urgs-agent /chat 获取回答，
同时调用 urgs-rag /api/v1/query 获取检索上下文，
然后运行 Ragas 评估。

用法:
    cd urgs-rag
    python -m eval.run_evaluation [--dataset eval/data/eval_dataset.json] [--mode agent|rag|both]
"""

import argparse
import json
import logging
import os
import sys
import warnings

# 确保可以导入 app 模块
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from eval.config import (
    AGENT_BASE_URL,
    RAG_BASE_URL,
    EVAL_LLM_MODEL,
    EVAL_LLM_BASE_URL,
    EVAL_LLM_API_KEY,
    DEFAULT_DATASET_PATH,
    DEFAULT_EVAL_SET_PATH,
    DEFAULT_RESULTS_PATH,
)
from eval.report import generate_report

logger = logging.getLogger(__name__)

# 过滤 Ragas 的 deprecation 警告
warnings.filterwarnings("ignore", category=DeprecationWarning, module="ragas")


def _call_agent(agent_url: str, question: str, timeout: int = 120) -> str:
    """调用 urgs-agent /chat 端点获取回答。"""
    import httpx

    try:
        resp = httpx.post(
            f"{agent_url}/chat",
            json={"user_id": "eval_user", "text": question},
            timeout=timeout,
        )
        resp.raise_for_status()
        data = resp.json()
        return data.get("answer", "")
    except Exception as e:
        logger.error(f"Agent 调用失败: {e}")
        return f"[调用失败: {e}]"


def _call_rag(rag_url: str, question: str, k: int = 4, timeout: int = 60) -> dict:
    """
    调用 urgs-rag /api/v1/query 端点获取回答和检索上下文。

    Returns:
        {"answer": str, "contexts": [str], "confidence": float}
    """
    import httpx

    try:
        resp = httpx.post(
            f"{rag_url}/api/v1/query",
            json={"query": question, "k": k},
            timeout=timeout,
        )
        resp.raise_for_status()
        data = resp.json()
        contexts = []
        for r in data.get("results", []):
            content = r.get("content") or r.get("page_content") or r.get("snippet", "")
            if content:
                contexts.append(content[:1000])
        return {
            "answer": data.get("answer", ""),
            "contexts": contexts,
            "confidence": data.get("confidence", 0.0),
        }
    except Exception as e:
        logger.error(f"RAG 调用失败: {e}")
        return {"answer": f"[调用失败: {e}]", "contexts": [], "confidence": 0.0}


def _build_evaluator_llm():
    """构建 Ragas 评估用的 LLM wrapper。"""
    from langchain_openai import ChatOpenAI
    from ragas.llms import LangchainLLMWrapper

    llm = ChatOpenAI(
        model=EVAL_LLM_MODEL,
        openai_api_base=EVAL_LLM_BASE_URL,
        openai_api_key=EVAL_LLM_API_KEY,
        temperature=0.1,
    )
    return LangchainLLMWrapper(llm)


def _build_evaluator_embeddings():
    """构建 Ragas 评估用的 Embedding wrapper。"""
    from ragas.embeddings import LangchainEmbeddingsWrapper
    from app.services.vector_store import vector_store_service

    embeddings = vector_store_service.get_embeddings()
    return LangchainEmbeddingsWrapper(embeddings)


def run_evaluation(
    dataset_path: str = DEFAULT_DATASET_PATH,
    agent_url: str = AGENT_BASE_URL,
    rag_url: str = RAG_BASE_URL,
    output_path: str = DEFAULT_RESULTS_PATH,
    mode: str = "agent",
):
    """
    运行 Ragas 离线评估。

    Args:
        dataset_path: 测试数据集路径
        agent_url: urgs-agent 端点
        rag_url: urgs-rag 端点
        output_path: 结果输出路径
        mode: 评估模式
            - "agent": 调用 urgs-agent /chat 获取回答，urgs-rag 获取 contexts
            - "rag": 仅调用 urgs-rag /api/v1/query
            - "both": 两个都跑，对比评分
    """
    from ragas import evaluate, EvaluationDataset, SingleTurnSample
    from ragas.metrics import (
        Faithfulness,
        AnswerRelevancy,
        LLMContextPrecisionWithReference,
        LLMContextRecall,
    )

    # 加载数据集
    with open(dataset_path, "r", encoding="utf-8") as f:
        test_data = json.load(f)

    if not test_data:
        logger.error("数据集为空")
        return

    logger.info(f"加载数据集: {len(test_data)} 条样本")

    # 构建评估器
    evaluator_llm = _build_evaluator_llm()
    evaluator_embeddings = _build_evaluator_embeddings()

    # 收集样本
    samples = []
    sample_details = []

    for i, item in enumerate(test_data):
        question = item["question"]
        ground_truth = item.get("ground_truth", item.get("answer", ""))
        reference_contexts = item.get("contexts", [])

        logger.info(f"[{i + 1}/{len(test_data)}] 评估: {question[:50]}...")

        if mode in ("agent", "both"):
            # 调用 agent 获取回答
            agent_answer = _call_agent(agent_url, question)
            # 调用 rag 获取 contexts
            rag_result = _call_rag(rag_url, question)
            retrieved_contexts = rag_result["contexts"]

            sample = SingleTurnSample(
                user_input=question,
                response=agent_answer,
                retrieved_contexts=retrieved_contexts if retrieved_contexts else [""],
                reference=ground_truth,
                reference_contexts=reference_contexts if reference_contexts else None,
            )
            samples.append(sample)
            sample_details.append(
                {
                    "question": question,
                    "agent_answer": agent_answer,
                    "ground_truth": ground_truth,
                    "retrieved_contexts_count": len(retrieved_contexts),
                    "source": item.get("source_document", item.get("source", "")),
                }
            )

        if mode == "rag":
            rag_result = _call_rag(rag_url, question)
            sample = SingleTurnSample(
                user_input=question,
                response=rag_result["answer"],
                retrieved_contexts=(
                    rag_result["contexts"] if rag_result["contexts"] else [""]
                ),
                reference=ground_truth,
                reference_contexts=reference_contexts if reference_contexts else None,
            )
            samples.append(sample)
            sample_details.append(
                {
                    "question": question,
                    "rag_answer": rag_result["answer"],
                    "ground_truth": ground_truth,
                    "retrieved_contexts_count": len(rag_result["contexts"]),
                    "confidence": rag_result["confidence"],
                    "source": item.get("source_document", item.get("source", "")),
                }
            )

    if not samples:
        logger.error("没有有效样本可评估")
        return

    logger.info(f"共 {len(samples)} 条样本，开始 Ragas 评估...")

    # 构建评估数据集
    eval_dataset = EvaluationDataset(samples=samples)

    metrics = [
        Faithfulness(llm=evaluator_llm),
        AnswerRelevancy(llm=evaluator_llm, embeddings=evaluator_embeddings),
        LLMContextPrecisionWithReference(llm=evaluator_llm),
        LLMContextRecall(llm=evaluator_llm),
    ]

    result = evaluate(
        dataset=eval_dataset,
        metrics=metrics,
    )

    # 提取每条样本的分数
    result_df = result.to_pandas()
    for idx, row in result_df.iterrows():
        if idx < len(sample_details):
            for col in result_df.columns:
                if col not in ("user_input", "response", "retrieved_contexts", "reference"):
                    val = row[col]
                    if isinstance(val, float):
                        sample_details[idx][col] = round(val, 4)

    # 生成报告
    eval_summary = {}
    for col in result_df.columns:
        if col not in ("user_input", "response", "retrieved_contexts", "reference", "reference_contexts"):
            vals = result_df[col].dropna()
            if len(vals) > 0:
                try:
                    eval_summary[col] = round(float(vals.mean()), 4)
                except (TypeError, ValueError):
                    pass

    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    report_text = generate_report(
        eval_result=eval_summary,
        samples=sample_details,
        output_path=output_path,
        agent_url=agent_url if mode != "rag" else rag_url,
        dataset_size=len(samples),
    )

    print(report_text)
    logger.info("评估完成")


def main():
    parser = argparse.ArgumentParser(description="URGS RAG Ragas 离线评估")
    parser.add_argument(
        "--dataset",
        type=str,
        default=DEFAULT_DATASET_PATH,
        help="测试数据集路径（也支持 eval_set.json 格式）",
    )
    parser.add_argument(
        "--agent-url",
        type=str,
        default=AGENT_BASE_URL,
        help=f"urgs-agent 端点 (默认: {AGENT_BASE_URL})",
    )
    parser.add_argument(
        "--rag-url",
        type=str,
        default=RAG_BASE_URL,
        help=f"urgs-rag 端点 (默认: {RAG_BASE_URL})",
    )
    parser.add_argument(
        "--output",
        type=str,
        default=DEFAULT_RESULTS_PATH,
        help=f"结果输出路径 (默认: {DEFAULT_RESULTS_PATH})",
    )
    parser.add_argument(
        "--mode",
        type=str,
        choices=["agent", "rag", "both"],
        default="agent",
        help="评估模式: agent (调用智能体), rag (仅RAG), both (对比)",
    )

    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )

    run_evaluation(
        dataset_path=args.dataset,
        agent_url=args.agent_url,
        rag_url=args.rag_url,
        output_path=args.output,
        mode=args.mode,
    )


if __name__ == "__main__":
    main()
