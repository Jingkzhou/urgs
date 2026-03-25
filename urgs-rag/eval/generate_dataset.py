"""
从知识库已向量化的文档自动生成评估数据集。

用法:
    cd urgs-rag
    python -m eval.generate_dataset [--max-chunks 50] [--num-questions 3] [--output eval/data/eval_dataset.json]
"""

import argparse
import json
import logging
import os
import random
import sys

# 确保可以导入 app 模块
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

from eval.config import (
    DEFAULT_DATASET_PATH,
    DEFAULT_MAX_CHUNKS,
    DEFAULT_NUM_QUESTIONS,
    DATA_DIR,
)

logger = logging.getLogger(__name__)


def _generate_qa_with_answers(llm_service, text: str, num_questions: int) -> list[dict]:
    """
    使用 LLM 从文档片段中同时生成问题和参考答案。

    Returns:
        [{"question": "...", "answer": "..."}, ...]
    """
    prompt = (
        f"请根据以下文本生成 {num_questions} 个问答对。\n"
        "要求：\n"
        "1. 问题应模拟真实用户的提问方式，类型多样化（定义类、填报类、对比类等）\n"
        "2. 答案必须完全基于给定文本，不得编造\n"
        "3. 答案应简洁准确，50-200字\n"
        "4. 避免过于简单的问题（如直接重复标题）\n\n"
        "仅输出 JSON 数组，格式：\n"
        '[{"question": "...", "answer": "..."}]\n\n'
        f"文本：\n{text[:3000]}"
    )

    try:
        response = llm_service.client.chat.completions.create(
            model=llm_service.model_name,
            messages=[
                {
                    "role": "system",
                    "content": "你是知识评估数据集生成专家。仅输出 JSON 数组，不要输出任何其他内容。",
                },
                {"role": "user", "content": prompt},
            ],
            temperature=0.3,
            response_format={"type": "json_object"},
        )
        content = response.choices[0].message.content

        # 解析 JSON，兼容 {"data": [...]} 和 [...] 两种格式
        parsed = json.loads(content)
        if isinstance(parsed, list):
            return parsed
        if isinstance(parsed, dict):
            # 尝试从常见 key 中提取列表
            for key in ("data", "qa_pairs", "questions", "items", "result"):
                if key in parsed and isinstance(parsed[key], list):
                    return parsed[key]
            # 如果只有一个 key 且值是列表
            values = list(parsed.values())
            if len(values) == 1 and isinstance(values[0], list):
                return values[0]
        logger.warning(f"LLM 返回了非预期格式: {content[:200]}")
        return []
    except Exception as e:
        logger.error(f"生成 QA 对失败: {e}")
        return []


def generate_eval_dataset(
    max_chunks: int = DEFAULT_MAX_CHUNKS,
    num_questions: int = DEFAULT_NUM_QUESTIONS,
    output_path: str = DEFAULT_DATASET_PATH,
    collection_name: str = None,
    shuffle: bool = True,
):
    """
    从知识库文档生成评估数据集。

    流程:
    1. 从 ShelveDocStore 读取所有父文档
    2. 可选按 collection 过滤、随机采样
    3. 对每个片段调用 LLM 生成 Q&A 对
    4. 输出 JSON 文件
    """
    from app.services.llm_chain import llm_service
    from app.services.vector_store import vector_store_service

    # 获取所有父文档
    all_docs = vector_store_service.docstore.get_all_documents()
    logger.info(f"知识库中共有 {len(all_docs)} 个父文档")

    # 按 collection 过滤
    if collection_name:
        all_docs = [
            doc
            for doc in all_docs
            if doc.metadata.get("collection_name") == collection_name
        ]
        logger.info(f"过滤后（collection={collection_name}）: {len(all_docs)} 个文档")

    # 过滤掉内容过短的文档
    all_docs = [doc for doc in all_docs if len(doc.page_content.strip()) >= 100]

    if shuffle:
        random.shuffle(all_docs)

    docs_to_process = all_docs[:max_chunks]
    logger.info(f"将处理 {len(docs_to_process)} 个文档片段，每个生成 {num_questions} 个问答对")

    dataset = []
    for i, doc in enumerate(docs_to_process):
        logger.info(
            f"[{i + 1}/{len(docs_to_process)}] 处理: "
            f"{doc.metadata.get('file_name', doc.metadata.get('source', 'unknown'))[:50]}"
        )

        qa_pairs = _generate_qa_with_answers(llm_service, doc.page_content, num_questions)

        for qa in qa_pairs:
            if not qa.get("question") or not qa.get("answer"):
                continue
            dataset.append(
                {
                    "question": qa["question"],
                    "ground_truth": qa["answer"],
                    "source_document": doc.metadata.get(
                        "file_name", doc.metadata.get("source", "unknown")
                    ),
                    "contexts": [doc.page_content[:2000]],
                }
            )

    # 确保输出目录存在
    os.makedirs(os.path.dirname(output_path), exist_ok=True)

    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(dataset, f, ensure_ascii=False, indent=2)

    logger.info(f"数据集已生成: {output_path}，共 {len(dataset)} 条样本")
    print(f"\n数据集生成完成: {output_path}")
    print(f"总样本数: {len(dataset)}")
    print(f"来源文档数: {len(docs_to_process)}")


def main():
    parser = argparse.ArgumentParser(description="从知识库生成评估数据集")
    parser.add_argument(
        "--max-chunks",
        type=int,
        default=DEFAULT_MAX_CHUNKS,
        help=f"最大处理文档片段数 (默认: {DEFAULT_MAX_CHUNKS})",
    )
    parser.add_argument(
        "--num-questions",
        type=int,
        default=DEFAULT_NUM_QUESTIONS,
        help=f"每个片段生成的问题数 (默认: {DEFAULT_NUM_QUESTIONS})",
    )
    parser.add_argument(
        "--output",
        type=str,
        default=DEFAULT_DATASET_PATH,
        help=f"输出文件路径 (默认: {DEFAULT_DATASET_PATH})",
    )
    parser.add_argument(
        "--collection",
        type=str,
        default=None,
        help="指定知识库集合名称 (默认: 全部)",
    )
    parser.add_argument(
        "--no-shuffle",
        action="store_true",
        help="不随机打乱文档顺序",
    )

    args = parser.parse_args()

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s",
    )

    generate_eval_dataset(
        max_chunks=args.max_chunks,
        num_questions=args.num_questions,
        output_path=args.output,
        collection_name=args.collection,
        shuffle=not args.no_shuffle,
    )


if __name__ == "__main__":
    main()
