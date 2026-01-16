"""
置信度评分服务。

将 RRF 分数与"回答可信度"分离，基于多特征组合计算真实置信度。
"""
import logging
import re
from typing import List, Optional
from dataclasses import dataclass

logger = logging.getLogger(__name__)


@dataclass
class ConfidenceResult:
    """置信度计算结果"""
    score: float                    # 综合置信度 (0.0 - 1.0)
    is_sufficient: bool             # 证据是否充足
    features: dict                  # 各特征的详细得分
    reasoning: str                  # 置信度判断说明


class ConfidenceScorer:
    """
    多特征置信度计算器。
    
    基于以下特征计算综合置信度：
    1. entity_match: 查询实体是否在 Top1 中硬匹配
    2. margin: Top1 与 Top2 的分差（边际优势）
    3. stability: Top1 是否在多个改写查询中稳定出现
    4. source_quality: 来源质量（原文 > 摘要 > 二次加工）
    5. doc_count: 有效文档数量
    """
    
    # 特征权重配置
    WEIGHTS = {
        "entity_match": 0.25,
        "margin": 0.20,
        "stability": 0.20,
        "source_quality": 0.20,
        "doc_count": 0.15
    }
    
    # 置信度阈值
    CONFIDENCE_THRESHOLD = 0.45  # 低于此值认为证据不足
    
    def calculate(
        self,
        query: str,
        docs_with_scores: List[dict],
        query_entities: Optional[List[str]] = None,
        multi_query_hits: Optional[dict] = None
    ) -> ConfidenceResult:
        """
        计算综合置信度。
        
        Args:
            query: 用户原始查询
            docs_with_scores: 检索结果列表，每项包含 document 和 score
            query_entities: 从查询中提取的关键实体（可选）
            multi_query_hits: 多路查询的命中统计（可选）
            
        Returns:
            ConfidenceResult: 包含综合置信度和各特征得分
        """
        if not docs_with_scores:
            return ConfidenceResult(
                score=0.0,
                is_sufficient=False,
                features={},
                reasoning="无检索结果"
            )
        
        features = {}
        
        # 1. 实体硬匹配特征
        features["entity_match"] = self._calc_entity_match(
            query, docs_with_scores[0], query_entities
        )
        
        # 2. 边际分差特征
        features["margin"] = self._calc_margin(docs_with_scores)
        
        # 3. 跨查询稳定性特征
        features["stability"] = self._calc_stability(
            docs_with_scores[0], multi_query_hits
        )
        
        # 4. 来源质量特征
        features["source_quality"] = self._calc_source_quality(docs_with_scores)
        
        # 5. 文档数量特征
        features["doc_count"] = self._calc_doc_count(len(docs_with_scores))
        
        # 加权求和
        final_score = sum(
            features[k] * self.WEIGHTS[k] for k in self.WEIGHTS
        )
        
        # 生成判断说明
        reasoning = self._build_reasoning(features, final_score)
        
        return ConfidenceResult(
            score=round(final_score, 4),
            is_sufficient=final_score >= self.CONFIDENCE_THRESHOLD,
            features={k: round(v, 4) for k, v in features.items()},
            reasoning=reasoning
        )
    
    def _calc_entity_match(
        self,
        query: str,
        top_doc: dict,
        query_entities: Optional[List[str]] = None
    ) -> float:
        """
        计算实体硬匹配得分。
        
        如果没有预提取的实体，则从查询中提取关键词进行匹配。
        """
        content = top_doc["document"].page_content.lower()
        
        if query_entities:
            # 使用预提取的实体
            entities = query_entities
        else:
            # 简单提取：中文词 + 英文/数字词
            entities = self._extract_simple_entities(query)
        
        if not entities:
            return 0.5  # 无实体时给中性分
        
        matched = sum(1 for e in entities if e.lower() in content)
        return matched / len(entities)
    
    def _extract_simple_entities(self, query: str) -> List[str]:
        """
        简单实体提取（不依赖 NLP 模型）。
        
        提取规则：
        - 大写字母开头的英文词（如 G01, CAR）
        - 数字编号（如 1104）
        - 中文专业术语（长度 >= 2 的连续中文）
        """
        entities = []
        
        # 英文/数字词（如 G01, 1104, CAR）
        en_pattern = r'\b[A-Z0-9][A-Za-z0-9]{1,10}\b'
        entities.extend(re.findall(en_pattern, query))
        
        # 中文词（简单按连续中文切分，取长度 >= 2 的）
        cn_pattern = r'[\u4e00-\u9fa5]{2,}'
        cn_words = re.findall(cn_pattern, query)
        # 过滤掉常见虚词
        stopwords = {"怎么", "什么", "如何", "哪些", "哪个", "为什么", "是什么", "的", "了", "在", "有", "和", "与"}
        entities.extend([w for w in cn_words if w not in stopwords])
        
        return list(set(entities))
    
    def _calc_margin(self, docs_with_scores: List[dict]) -> float:
        """
        计算 Top1 与 Top2 的边际分差。
        
        边际越大，说明 Top1 越有优势。
        """
        if len(docs_with_scores) < 2:
            return 0.8  # 只有一个结果，给较高分（独占优势）
        
        top1_score = docs_with_scores[0]["score"]
        top2_score = docs_with_scores[1]["score"]
        
        if top1_score == 0:
            return 0.0
        
        # 相对边际：(Top1 - Top2) / Top1
        relative_margin = (top1_score - top2_score) / top1_score
        
        # 映射到 0-1，边际 >= 0.3 视为满分
        return min(relative_margin / 0.3, 1.0)
    
    def _calc_stability(
        self,
        top_doc: dict,
        multi_query_hits: Optional[dict] = None
    ) -> float:
        """
        计算跨查询稳定性。
        
        如果 Top1 在多个改写查询中都出现在 TopN，说明结果稳定可靠。
        """
        if not multi_query_hits:
            return 0.5  # 无多路查询信息时给中性分
        
        doc_key = top_doc["document"].metadata.get("parent_id") or \
                  top_doc["document"].metadata.get("file_name") or \
                  str(id(top_doc["document"]))
        
        # 统计该文档在多少个查询中出现
        hit_count = multi_query_hits.get(doc_key, 0)
        total_queries = multi_query_hits.get("_total_queries", 1)
        
        return hit_count / max(total_queries, 1)
    
    def _calc_source_quality(self, docs_with_scores: List[dict]) -> float:
        """
        计算来源质量得分。
        
        原文 chunk > 摘要 > QA > 逻辑核
        """
        quality_map = {
            "semantic": 1.0,    # 原文语义切片
            "chunk": 1.0,       # 原文 chunk
            "summary": 0.7,     # 摘要索引
            "qa": 0.6,          # 模拟 QA
            "logic": 0.5,       # 逻辑核/思考范式
        }
        
        # 取 Top3 的平均来源质量
        top_docs = docs_with_scores[:3]
        if not top_docs:
            return 0.0
        
        total = 0.0
        for item in top_docs:
            path_type = item["document"].metadata.get("path_type", "semantic")
            total += quality_map.get(path_type, 0.5)
        
        return total / len(top_docs)
    
    def _calc_doc_count(self, count: int) -> float:
        """
        计算文档数量得分。
        
        足够的候选文档数量表明检索覆盖充分。
        """
        if count == 0:
            return 0.0
        if count >= 5:
            return 1.0
        if count >= 3:
            return 0.8
        if count >= 2:
            return 0.5
        return 0.3  # 只有 1 个
    
    def _build_reasoning(self, features: dict, final_score: float) -> str:
        """
        生成置信度判断说明。
        """
        parts = []
        
        if features["entity_match"] < 0.5:
            parts.append("查询实体在结果中匹配度较低")
        elif features["entity_match"] >= 0.8:
            parts.append("查询实体在结果中高度匹配")
        
        if features["margin"] < 0.3:
            parts.append("Top1 与 Top2 分差较小，结果不够明确")
        elif features["margin"] >= 0.7:
            parts.append("Top1 具有显著优势")
        
        if features["source_quality"] < 0.6:
            parts.append("来源主要为二次加工内容")
        elif features["source_quality"] >= 0.9:
            parts.append("来源为高质量原文片段")
        
        if features["doc_count"] < 0.5:
            parts.append("候选文档数量较少")
        
        if not parts:
            if final_score >= self.CONFIDENCE_THRESHOLD:
                parts.append("综合置信度达标")
            else:
                parts.append("综合置信度较低")
        
        return "；".join(parts)


# 导出服务单例
confidence_scorer = ConfidenceScorer()
