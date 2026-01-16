import json
import os
import time
from typing import Optional

from app.config import settings


class MetricsService:
    """
    指标与监控服务。
    
    负责记录系统查询行为（耗时、得分、文档数等）以及用户反馈（评分、评论），
    并将这些指标持久化到本地 JSONL 文件中，供后续离线分析和效果评估。
    """
    def __init__(self):
        # 初始化指标存储目录
        self.base_dir = os.path.join(os.getcwd(), "data", "metrics")
        os.makedirs(self.base_dir, exist_ok=True)

    def _append(self, filename: str, payload: dict):
        """
        内部方法：将数据追加到指定的 JSONL 文件中。
        """
        path = os.path.join(self.base_dir, filename)
        with open(path, "a", encoding="utf-8") as f:
            f.write(json.dumps(payload, ensure_ascii=False) + "\n")

    def record_query(
        self,
        query: str,
        intent: str,
        success: bool,
        top_score: float,
        docs_count: int,
        latency_ms: int,
        low_evidence: bool = False,
    ):
        """
        记录一次完整的 RAG 查询指标。

        Args:
            query (str): 用户问题。
            intent (str): 识别出的意图。
            success (bool): 查询是否成功完成。
            top_score (float): 检索到的最匹配文档的得分。
            docs_count (int): 参与回答的文档片段数量。
            latency_ms (int): 端到端响应耗时 (ms)。
            low_evidence (bool): 标识该回答是否处于“证据不足”状态。
        """
        payload = {
            "timestamp": int(time.time()),
            "query": query,
            "intent": intent,
            "success": success,
            "top_score": top_score,
            "docs_count": docs_count,
            "latency_ms": latency_ms,
            "low_evidence": low_evidence,
        }
        self._append("queries.jsonl", payload)

    def record_feedback(
        self,
        query: str,
        answer: str,
        rating: int,
        comment: Optional[str] = None,
    ):
        """
        记录用户对回答结果的反馈（点赞/点踩/评论）。
        """
        payload = {
            "timestamp": int(time.time()),
            "query": query,
            "answer": answer,
            "rating": rating,
            "comment": comment,
        }
        self._append("feedback.jsonl", payload)


# 导出指标服务实例
metrics_service = MetricsService()
