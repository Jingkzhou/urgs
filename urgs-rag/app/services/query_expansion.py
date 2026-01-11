import logging
import json
from typing import List
from app.services.llm_chain import llm_service

logger = logging.getLogger(__name__)

class QueryExpansionService:
    """
    查询扩展与理解服务。
    负责将用户的原始查询转化为更易于检索的形式。
    """

    def expand_query(self, query: str, num_queries: int = 4) -> List[str]:
        """
        多路查询改写：生成同一个问题的多种变体。
        """
        if not query:
            return []

        prompt = f"""You are an AI language model assistant. Your task is to generate {num_queries} different search queries that aim to answer the user question from multiple perspectives. 
The user question is: "{query}"

Respond with a JSON list of strings, e.g.: ["query 1", "query 2"]
Do not add any other text.
"""
        try:
            # 复用 llm_service 的 client，确保配置同步
            client = llm_service.client
            if not client:
                logger.warning("LLM client not available, skipping query expansion.")
                return [query]

            response = client.chat.completions.create(
                model=llm_service.model_name or "gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are a helpful assistant that generates search query variations."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7
            )
            
            content = response.choices[0].message.content.strip()
            # 简单的 JSON 解析
            if "```" in content:
                content = content.replace("```json", "").replace("```", "")
            
            queries = json.loads(content)
            if isinstance(queries, list):
                 # 确保原始查询也在其中
                return list(set([query] + queries))
            return [query]

        except Exception as e:
            logger.error(f"Query expansion failed: {e}")
            return [query]

    def generate_hypothetical_answer(self, query: str) -> str:
        """
        HyDE (Hypothetical Document Embeddings): 生成一个假设性的答案。
        """
        if not query:
            return ""

        prompt = f"""Please write a passage to answer the question. 
Question: "{query}"
Passage:"""
        
        try:
            client = llm_service.client
            if not client:
                return ""

            response = client.chat.completions.create(
                model=llm_service.model_name or "gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "You are a helpful expert assistant."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.7
            )
            return response.choices[0].message.content.strip()
        except Exception as e:
            logger.error(f"HyDE generation failed: {e}")
            return ""

query_expansion_service = QueryExpansionService()
