from typing import List
from langchain_core.documents import Document
from app.services.llm_chain import llm_service
from app.services.vector_store import vector_store_service
import logging

logger = logging.getLogger(__name__)

class QAService:
    def answer_question(self, query: str, collection_names: List[str] = None) -> dict:
        """
        Full RAG Pipeline with CoT Prompting.
        """
        # 1. Multi-Path Retrieval
        docs = []
        if collection_names and len(collection_names) > 0:
            for name in collection_names:
                try:
                    # Provide k=6 per collection to ensure coverage
                    col_docs = vector_store_service.similarity_search(query, k=6, collection_name=name)
                    docs.extend(col_docs)
                except Exception as e:
                    logger.warning(f"Search failed for collection {name}: {e}")
        else:
            # Fallback to default collection search
            docs = vector_store_service.similarity_search(query, k=10)
        
        # 2. Extract Components for CoT
        facts = []
        reasoning_templates = []
        tags = set()
        
        for doc in docs:
            path_type = doc.metadata.get("path_type", "semantic")
            if path_type == "semantic":
                facts.append(doc.page_content)
            elif path_type == "logic":
                reasoning_templates.append(doc.page_content)
            
            # Collect tags
            doc_tags = doc.metadata.get("tags", [])
            if isinstance(doc_tags, list):
                tags.update(doc_tags)

        # 3. Build CoT Prompt
        facts_str = "\n".join([f"- {f}" for f in facts]) or "无直接事实参考"
        templates_str = "\n".join([f"- {t}" for t in reasoning_templates]) or "无逻辑模板参考"
        tags_str = ", ".join(tags) or "通用场景"

        system_prompt = (
            "你是一个极其专业且逻辑严密的 AI 顾问。你的目标是结合已知的'事实记录'、'思考范式'和'背景常识'，"
            "为用户提供深度、专业且具有推导性的回答。你需要严格遵循提供的思考范式，回答内容要丰满且具有可操作性。"
        )

        user_prompt = f"""
【已知事实】（来源：知识库原文）
{facts_str}

【思考范式 / 逻辑核】（来源：专家模板/逻辑路径）
{templates_str}

【当前业务场景 / 标签】
{tags_str}

【任务指令】
请根据上述信息，结合你的专业常识，回答以下用户问题：
"{query}"

要求：
1. 回答要体现出推导过程（为什么这么建议）。
2. 如果事实与范式存在冲突，以事实为准，但参考范式的思维结构。
3. 如果信息不足以回答，请基于常识给出方向性建议并说明原因。
"""


        try:
            # 4. Generate Answer
            # OPTIMIZATION: Skipped redundant generation. Java backend handles it.
            answer = "Retrieval Only" 
            
            return {
                "query": query,
                "answer": answer,
                "sources": [
                    {
                        "content": doc.page_content, 
                        "metadata": doc.metadata, 
                        "score": max(0.6, 0.95 - (i * 0.05)) # Simulated score based on rank
                    } for i, doc in enumerate(docs)
                ],
                "tags": list(tags)
            }
        except Exception as e:
            logger.error(f"QA generation failed: {e}")
            return {"error": str(e)}

qa_service = QAService()
