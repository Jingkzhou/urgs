import re
from typing import Dict, List, Optional

from app.config import settings
from app.services.llm_chain import llm_service


class IntentRouter:
    """
    意图路由服务。
    
    负责分析用户的查询语句，识别用户意图（如 SQL、血缘、资产等），
    并根据意图自动配置推荐的检索集合（Collections）和过滤器（Filters）。
    """
    def __init__(self):
        # 默认使用的知识库集合
        self.default_collections = [settings.COLLECTION_NAME]

    def detect_intent(self, query: str) -> str:
        """
        通过关键词匹配或正则表达式，提取用户查询的意图。
        """
        if not query:
            return "general"
        q = query.lower()
        
        # 1. SQL / 数据库相关意图
        if "sql" in q or "select" in q or "join" in q:
            return "sql"
        # 2. 血缘分析意图
        if "血缘" in q or "lineage" in q:
            return "lineage"
        # 3. 监管资产意图
        if "资产" in q or "asset" in q:
            return "asset"
        # 4. 报表编号意图 (针对匹配 A1234 等格式)
        if re.search(r"a\d{4}", q):
            return "report"
            
        return "general"

    def analyze(self, query: str) -> Dict:
        """
        [New] 使用 LLM 进行深度意图分析。
        """
        # 1. 先用规则快速过滤特殊业务意图 (SQL/血缘/资产)
        fast_intent = self.detect_intent(query)
        if fast_intent != "general":
            return {
                "intent": fast_intent, 
                "entities": [], 
                "rewritten_query": query, 
                "is_fast_path": True
            }

        # 2. 如果是通用查询，则调用 LLM 进行深度分析
        # (WHAT_IS, HOW_TO, COMPARE, TROUBLESHOOT)
        llm_result = llm_service.analyze_query_intent(query)
        llm_result["is_fast_path"] = False
        return llm_result

    def route(self, query: str, collection_names: Optional[List[str]] = None) -> Dict:
        """
        根据意图进行路由决策，返回推荐的配置。
        
        Args:
            query (str): 用户查询语句。
            collection_names (list, optional): 若用户手动指定了集合，则以此为准。

        Returns:
            dict: 包含推荐集合、过滤器和意图标识。
        """
        # 1. 获取意图分析结果 (包含 规则 + LLM) - 无论是否手动指定集合都要执行
        analysis = self.analyze(query)
        intent = analysis.get("intent", "GENERAL")
        
        # 2. 确定使用的集合
        collections = collection_names if collection_names else self.default_collections
        
        # 3. 为特定意图自动加上元数据过滤
        filters = None
        if intent == "sql":
            filters = {"source_type": "sql_code"}
        elif intent == "lineage":
            filters = {"source_type": "lineage"}
        elif intent == "asset":
            filters = {"source_type": "regulatory_asset"}

        return {
            "collections": collections, 
            "filters": filters, 
            "intent": intent,
            "analysis": analysis  # 透传完整分析结果给后续 QA Service
        }


# 导出路由实例
intent_router = IntentRouter()
