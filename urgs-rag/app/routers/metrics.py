from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional
import os
import json

from app.services.metrics import metrics_service

# 初始化路由，设置前缀和标签
router = APIRouter(prefix="/api/rag", tags=["metrics"])


class FeedbackRequest(BaseModel):
    """
    用户反馈请求模型
    """
    query: str      # 用户查询语句
    answer: str     # RAG 系统给出的回答
    rating: int     # 评分（如 1-5 或 0/1）
    comment: Optional[str] = None  # 可选的评论


@router.post("/feedback")
async def submit_feedback(request: FeedbackRequest):
    """
    提交用户对问答结果的反馈。
    
    记录用户对特定回答的评分和建议，用于后续优化模型或检索策略。
    """
    try:
        metrics_service.record_feedback(
            query=request.query,
            answer=request.answer,
            rating=request.rating,
            comment=request.comment,
        )
        return {"status": "success"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/metrics/summary")
async def metrics_summary():
    """
    获取系统指标概览。
    
    统计目前已记录的查询总数和反馈总数。
    """
    try:
        base_dir = os.path.join(os.getcwd(), "data", "metrics")
        query_path = os.path.join(base_dir, "queries.jsonl")
        feedback_path = os.path.join(base_dir, "feedback.jsonl")

        summary = {"queries": 0, "feedback": 0}
        # 统计查询记录文件的行数
        if os.path.exists(query_path):
            with open(query_path, "r", encoding="utf-8") as f:
                summary["queries"] = sum(1 for _ in f)
        # 统计反馈记录文件的行数
        if os.path.exists(feedback_path):
            with open(feedback_path, "r", encoding="utf-8") as f:
                summary["feedback"] = sum(1 for _ in f)
        return summary
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
