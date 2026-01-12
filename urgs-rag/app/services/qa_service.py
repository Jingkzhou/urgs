from typing import List, Optional
import logging
import time

from langchain_core.documents import Document

from app.config import settings
from app.services.llm_chain import llm_service
from app.services.vector_store import vector_store_service
from app.services.intent_router import intent_router
from app.services.metrics import metrics_service
from app.services.query_expansion import query_expansion_service

logger = logging.getLogger(__name__)


class QAService:
    """
    全息问答核心服务。
    
    协调意图路由、混合检索、结果去重、回答能力评估以及最终的 LLM 生成流程。
    """
    def answer_question(
        self,
        query: str,
        collection_names: Optional[List[str]] = None,
        k: int = 4,
        metadata_filter: Optional[dict] = None,
        fusion_strategy: str = "rrf", # weighted | rrf
    ) -> dict:
        """
        核心 RAG 链路：混合检索 + 结构化回答。

        Args:
            query (str): 用户提问。
            collection_names (list, optional): 手动指定的检索集合。
            k (int): 每个路径检索的 Top K 数量。
            metadata_filter (dict, optional): 外部传入的元数据过滤器。

        Returns:
            dict: 包含回答、来源、标签、置信度和意图的字典。
        """
        start_time = time.time()
        # 1. 意图路由：识别意图并确定要检索的集合及预置过滤器
        route_info = intent_router.route(query, collection_names)
        collections = route_info["collections"]
        route_filter = route_info.get("filters")
        intent = route_info.get("intent", "general")
        intent = route_info.get("intent", "general")
        analysis = route_info.get("analysis", {})
        rewritten_query = analysis.get("rewritten_query", query)
        
        print(f"\n[RAG-QA] >>> 意图识别: {intent}, 改写查询: {rewritten_query}")
        print(f"[RAG-QA] >>> 路由集合: {collections}")

        unique_docs_map = {}

        # 确定搜索查询列表
        search_queries = [rewritten_query]
        if settings.ENABLE_QUERY_EXPANSION:
            logger.info(f"正在进行查询扩展: {rewritten_query}")
            expanded = query_expansion_service.expand_query(rewritten_query, num_queries=2)
            # 扩展查询包含原查询，这里取前3个以平衡性能
            search_queries = expanded[:3]
            logger.info(f"扩展后的查询列表: {search_queries}")
        
        # 2. 对每个目标集合执行全息混合检索
        for name in collections:
            # 合并路由过滤器和外部传入的过滤器
            if metadata_filter and route_filter:
                effective_filter = {**route_filter, **metadata_filter}
            else:
                effective_filter = metadata_filter or route_filter

            for q_str in search_queries:
                try:
                    col_docs = vector_store_service.hybrid_search(
                        q_str,
                        k=k,
                        collection_name=name, # Use the current collection name
                        metadata_filter=effective_filter, # Use the effective filter
                        fusion_strategy=fusion_strategy,
                    )
                    
                    # 结果去重合并 (保留最高分)
                    for item in col_docs:
                        doc = item["document"]
                        # 使用 parent_id 作为去重键，确保同一文档不重复出现
                        key = doc.metadata.get("parent_id") or doc.metadata.get("file_name") or str(id(doc))
                        
                        if key not in unique_docs_map:
                            unique_docs_map[key] = item
                        else:
                            # 如果新结果分数更高，则更新
                            if item["score"] > unique_docs_map[key]["score"]:
                                unique_docs_map[key] = item
                except Exception as e:
                    logger.error(f"检索失败 (Collection: {name}, Query: {q_str}): {e}")

        # 转换为列表并按分数排序
        docs_with_scores = list(unique_docs_map.values())
        docs_with_scores.sort(key=lambda x: x["score"], reverse=True)

        # 4. 回答能力评估 (Answerability check)
        # 如果检索到的文档太少或最高分太低，则认为证据不足
        top_score = docs_with_scores[0]["score"] if docs_with_scores else 0.0
        print(f"[RAG-QA] 检索结果去重完成, 最终候选片段数: {len(docs_with_scores)}, 最高相似度: {top_score:.4f}")
        low_evidence = (
            len(docs_with_scores) < settings.ANSWERABILITY_MIN_DOCS
            or top_score < settings.ANSWERABILITY_MIN_SCORE
        )

        # 准备传送给 LLM 的上下文组件
        facts = []
        reasoning_templates = []
        tags = set()
        sources = []

        for item in docs_with_scores:
            doc = item["document"]
            path_type = doc.metadata.get("path_type", "semantic")
            
            # 区分不同路径的内容，分别填入事实库或策略库
            if path_type == "semantic":
                facts.append(doc.page_content)
            elif path_type == "logic":
                reasoning_templates.append(doc.page_content)
            elif path_type == "summary":
                facts.append(doc.page_content)

            # 汇总标签
            doc_tags = doc.metadata.get("tags", [])
            if isinstance(doc_tags, list):
                tags.update(doc_tags)

            # 构造来源标识
            source_id = self._build_source_id(doc)
            sources.append(
                {
                    "source_id": source_id,
                    "score": item["score"],
                    "score_details": item.get("score_details", {}),
                    "metadata": doc.metadata,
                    "content": doc.page_content,  # 完整内容用于构建 RAG 上下文
                    "snippet": doc.page_content[:200].replace("\n", " "),
                }
            )

        # 5. 生成结果
        if low_evidence:
            # 证据不足时，返回引导性建议和澄清问题，不强行生成可能存在幻觉的回答
            answer_structured = {
                "conclusion": "当前证据不足，建议补充关键信息后再检索。",
                "evidence": [],
                "suggestions": [
                    {
                        "action": "补充报表编号、口径版本或统计范围",
                        "reason": "目前匹配证据不足",
                        "source_id": "",
                        "type": "experience",
                    }
                ],
                "risks": ["证据不足可能导致回答偏差"],
                "boundary": "仅基于当前检索结果",
                "clarifying_questions": self._clarifying_questions(query, intent),
                "confidence": top_score,
            }
        else:
            # 证据充足，调用 LLM 生成深度绑定的结构化回答
            print(f"[RAG-QA] 证据充足 (TopScore={top_score:.4f})，正在注入提示词上下文 (Fact x {len(facts)}, Reasoning x {len(reasoning_templates)})...")
            answer_structured = llm_service.generate_structured_answer(
                query=query,
                facts=facts,
                reasoning_templates=reasoning_templates,
                tags=list(tags),
                sources=sources,
                min_confidence=top_score,
            )

        # 记录查询指标
        latency_ms = int((time.time() - start_time) * 1000)
        metrics_service.record_query(
            query=query,
            intent=intent,
            success=True,
            top_score=top_score,
            docs_count=len(docs_with_scores),
            latency_ms=latency_ms,
            low_evidence=low_evidence,
        )

        return {
            "query": query,
            "rewritten_query": rewritten_query,
            "answer": answer_structured.get("conclusion", ""),
            "answer_structured": answer_structured,
            "sources": sources,
            "tags": list(tags),
            "confidence": top_score,
            "intent": intent,
        }

    def _build_source_id(self, doc: Document) -> str:
        """
        构造源文档的唯一标识字符串（包含页码信息）。
        """
        file_name = doc.metadata.get("file_name") or doc.metadata.get("source") or "未知来源"
        page = doc.metadata.get("page")
        if page is not None:
            return f"{file_name}#第{page}页"
        return file_name

    def _clarifying_questions(self, query: str, intent: str) -> List[str]:
        """
        根据用户意图，生成针对性的引导提问。
        """
        if intent == "report":
            return [
                "请提供具体报表编号（如 Axxxx）或具体的制度名称",
                "请说明您关注的统计范围或具体的时间维度",
            ]
        if intent == "sql":
            return ["请提供更完整的 SQL 逻辑描述或相关的表结构信息"]
        return [
            "请补充更具体的业务背景或监管制度口径",
            "建议提供对应的报表编号或标准文件名称进行精确匹配",
        ]


# 导出 QA 服务单例
qa_service = QAService()
