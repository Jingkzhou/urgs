import re
from typing import Dict, List, Optional

from app.config import settings


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

    def route(self, query: str, collection_names: Optional[List[str]] = None) -> Dict:
        """
        根据意图进行路由决策，返回推荐的配置。
        
        Args:
            query (str): 用户查询语句。
            collection_names (list, optional): 若用户手动指定了集合，则以此为准。

        Returns:
            dict: 包含推荐集合、过滤器和意图标识。
        """
        if collection_names:
            return {"collections": collection_names, "filters": None, "intent": "manual"}

        intent = self.detect_intent(query)
        filters = None
        
        # 为特定意图自动加上元数据过滤，缩小检索范围，提高准确率
        if intent == "sql":
            filters = {"source_type": "sql_code"}
        elif intent == "lineage":
            filters = {"source_type": "lineage"}
        elif intent == "asset":
            filters = {"source_type": "regulatory_asset"}

        return {"collections": self.default_collections, "filters": filters, "intent": intent}


# 导出路由实例
intent_router = IntentRouter()
