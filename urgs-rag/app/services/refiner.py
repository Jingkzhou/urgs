from typing import List
from langchain_core.documents import Document
from app.services.llm_chain import llm_service


class KnowledgeRefiner:
    """
    知识精炼器。

    核心作用是将厚重的原始文档"处理薄、处理透"。
    通过调用 LLM 生成合成数据，将单一的文档片段转化为三条特征路径的全息数据：
    1. 语义路径 (Semantic): 原始文本内容。
    2. 逻辑路径 (Logic): 模拟问题和逻辑推导核。
    3. 摘要路径 (Summary): 核心内容摘要。
    """

    def refine_documents(
        self, documents: List[Document], enrich_prompt: str = None
    ) -> List[Document]:
        """
        对输入的文档列表进行全息增强。

        Args:
            documents (List[Document]): 原始文档片段列表。
            enrich_prompt (str, optional): 自定义的知识增强提示词。

        Returns:
            List[Document]: 包含原始片段及大量合成衍生片段的全息文档列表。
        """
        holographic_docs = []
        total = len(documents)
        print(f"正在启动全息数据生成，共需精炼 {total} 个原始片段...")

        for i, doc in enumerate(documents):
            # 1. 语义路径 (Semantic Path): 保留原始文档片段
            doc.metadata["path_type"] = "semantic"
            holographic_docs.append(doc)

            # 对所有片段进行 LLM 增强（移除了长度阈值限制）
            text = doc.page_content
            print(f"正在精炼文档片段 {i+1}/{total} (长度: {len(text)} 字符)...")
            # 调用 LLM 进行全息深加工，传递自定义提示词
            enriched = llm_service.enrich_knowledge(text, custom_prompt=enrich_prompt)

            print(
                f"[KnowledgeRefiner] - 片段 {i+1} 增强产出: {len(enriched.get('questions', []))} 个模拟问题, 逻辑核: {'有' if enriched.get('reasoning') else '无'}, 摘要: {'有' if enriched.get('summary') else '无'}"
            )

            # 2. 逻辑路径 (Logic Path) - 模拟问题
            # 将"问题-答案"对存入逻辑路径，实现"以问搜问"，极大提升短句搜索准确率
            for q in enriched.get("questions", []):
                # 构建合成文档的 metadata，显式删除 parent_id 以避免覆盖原始语义文档
                synthetic_meta = {
                    k: v for k, v in doc.metadata.items() if k != "parent_id"
                }
                q_doc = Document(
                    page_content=f"问题: {q}\n相关知识: {text[:200]}...",
                    metadata={
                        **synthetic_meta,
                        "path_type": "logic",
                        "logic_type": "question",
                        "original_content": text,
                        "origin_parent_id": doc.metadata.get("parent_id"),
                        "is_synthetic": True,
                    },
                )
                holographic_docs.append(q_doc)

            # 3. 逻辑路径 (Logic Path) - 逻辑/策略核
            # 提取文档背后的流程或逻辑模版，作为高级推理的依据
            reasoning = enriched.get("reasoning")
            if reasoning:
                # 构建合成文档的 metadata，显式删除 parent_id
                synthetic_meta = {
                    k: v for k, v in doc.metadata.items() if k != "parent_id"
                }
                r_doc = Document(
                    page_content=f"逻辑核/推导过程: {reasoning}",
                    metadata={
                        **synthetic_meta,
                        "path_type": "logic",
                        "logic_type": "reasoning",
                        "tags": ",".join(enriched.get("tags", [])),
                        "keywords": ",".join(enriched.get("keywords", [])),
                        "original_content": text,
                        "origin_parent_id": doc.metadata.get("parent_id"),
                        "is_synthetic": True,
                    },
                )
                holographic_docs.append(r_doc)

                # 同时更新原始文档的标签和关键词，便于后续过滤
                doc.metadata["tags"] = ",".join(enriched.get("tags", []))
                doc.metadata["keywords"] = ",".join(enriched.get("keywords", []))

            # 4. 摘要路径 (Summary Path)
            # 提供极高浓缩度的语义信息，适合快速概览检索
            summary = enriched.get("summary")
            if summary:
                # 构建合成文档的 metadata，显式删除 parent_id
                synthetic_meta = {
                    k: v for k, v in doc.metadata.items() if k != "parent_id"
                }
                s_doc = Document(
                    page_content=f"摘要: {summary}",
                    metadata={
                        **synthetic_meta,
                        "path_type": "summary",
                        "summary_type": "auto",
                        "origin_parent_id": doc.metadata.get("parent_id"),
                        "tags": ",".join(enriched.get("tags", [])),
                        "keywords": ",".join(enriched.get("keywords", [])),
                        "original_content": text,
                        "is_synthetic": True,
                    },
                )
                holographic_docs.append(s_doc)

        print(
            f"精炼完成！原始 {total} 个片段已扩展为 {len(holographic_docs)} 个全息数据单元。"
        )
        return holographic_docs


# 导出精炼服务单例
knowledge_refiner = KnowledgeRefiner()
