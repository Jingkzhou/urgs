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

    def expand_query(self, query: str, num_queries: int = 5) -> List[dict]:
        """
        多路查询改写：生成同一问题的多种变体，覆盖不同检索角度。
        
        Returns:
            List[dict]: 包含 type 和 query 的改写结果列表
            [{"type": "original", "query": "..."}, {"type": "keyword", "query": "..."}, ...]
        """
        if not query:
            return []

        prompt = f"""你是一个检索优化专家，专注于监管报送与金融合规领域。
请将用户的查询改写为 {num_queries} 条不同的搜索语句，覆盖以下角度：

【改写规则】
1. 关键词版 (keyword)：提取核心实体+动作，用空格分隔，适合关键词检索
   - 去除语气词、口语化表达
   - 保留专业术语、表名、字段名、系统代码
   
2. 同义词版 (synonym)：替换专业术语的同义词、缩写、英文名
   - 例如：资本充足率 ↔ CAR ↔ Capital Adequacy Ratio
   - 例如：1104报表 ↔ 监管报表 ↔ 银保监报送
   
3. 拆分版 (split)：若为复合问题，拆分为多个独立子问题
   - 每个子问题应能独立检索到相关内容
   
4. 上下位词版 (hypernym)：用更宽泛或更具体的词替换
   - 例如：G01表 → 资本充足率系列报表

【输出格式】仅输出 JSON，不要添加其他文字：
{{
  "queries": [
    {{"type": "keyword", "query": "改写后的查询"}},
    {{"type": "synonym", "query": "改写后的查询"}},
    {{"type": "split", "query": "改写后的查询"}},
    {{"type": "hypernym", "query": "改写后的查询"}}
  ]
}}

【用户原始查询】
{query}
"""
        try:
            client = llm_service.client
            if not client:
                logger.warning("LLM client not available, skipping query expansion.")
                return [{"type": "original", "query": query}]

            response = client.chat.completions.create(
                model=llm_service.model_name or "gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "你是一个专业的检索优化助手，仅输出 JSON 格式结果。"},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,
                response_format={"type": "json_object"}
            )
            
            content = response.choices[0].message.content.strip()
            
            # 清理可能的 Markdown 代码块标记
            if "```" in content:
                content = content.replace("```json", "").replace("```", "").strip()
            
            result = json.loads(content)
            queries = result.get("queries", [])
            
            # 确保原始查询在结果中
            expanded = [{"type": "original", "query": query}]
            for q in queries:
                if isinstance(q, dict) and q.get("query") and q.get("query") != query:
                    expanded.append(q)
            
            logger.info(f"Query expansion: {query} -> {len(expanded)} variants")
            return expanded

        except Exception as e:
            logger.error(f"Query expansion failed: {e}")
            return [{"type": "original", "query": query}]


    def generate_hypothetical_answer(self, query: str) -> str:
        """
        HyDE (Hypothetical Document Embeddings): 生成一个假设性的答案。
        
        通过生成假设性回答，将其向量化后用于检索，
        可以更好地匹配"答案风格"的文档内容。
        """
        if not query:
            return ""

        prompt = f"""你是一位监管报送与金融合规领域的资深专家。
请为以下问题撰写一段专业、详尽的回答。

【要求】
1. 假设你拥有完整的监管知识库，直接给出答案
2. 回答应包含具体的报表名称、字段名、口径说明、制度依据等专业信息
3. 语言专业、结构清晰，约 150-250 字
4. 不要说"根据资料"或"我不确定"，假设你完全知道答案

【问题】
{query}

【专业回答】
"""
        
        try:
            client = llm_service.client
            if not client:
                logger.warning("LLM client not available, skipping HyDE generation.")
                return ""

            response = client.chat.completions.create(
                model=llm_service.model_name or "gpt-3.5-turbo",
                messages=[
                    {"role": "system", "content": "你是监管报送与金融合规领域的资深专家，请提供专业、权威的回答。"},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.5
            )
            
            result = response.choices[0].message.content.strip()
            logger.info(f"HyDE generated: {len(result)} chars for query: {query[:50]}...")
            return result
        except Exception as e:

            logger.error(f"HyDE generation failed: {e}")
            return ""

query_expansion_service = QueryExpansionService()
