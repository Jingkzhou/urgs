from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
from app.services.qa_service import qa_service

router = APIRouter()


class QueryRequest(BaseModel):
    """
    RAG 查询请求模型
    """
    query: str                          # 用户的提问
    k: int = 4                          # 检索的 Top K 数量
    collection_names: Optional[List[str]] = None  # 指定检索的集合列表
    metadata_filter: Optional[Dict[str, Any]] = None  # 元数据过滤器


class QueryResponse(BaseModel):
    """
    RAG 查询响应模型
    """
    answer: str                         # LLM 生成的最终回答
    answer_structured: Dict[str, Any]   # 结构化的回答内容（如果适用）
    results: List[dict]                 # 检索到的源文档片段及其得分
    tags: List[str] = []                # 问题的标签
    confidence: float = 0.0             # 回答的置信度得分
    intent: str = "general"             # 识别出的用户意图


@router.post("/query", response_model=QueryResponse)
async def query_knowledge_base(request: QueryRequest):
    """
    核心问答接口：使用全息 RAG 链路进行检索和回答。
    
    该接口会经历以下步骤：
    1. 意图识别
    2. 多路召回（向量 + 关键词）
    3. 重排序 (Rerank)
    4. 结果精炼 (Refinement)
    5. LLM 生成回答
    """
    try:
        # 调用核心问答服务
        response = qa_service.answer_question(
            request.query,
            collection_names=request.collection_names,
            k=request.k,
            metadata_filter=request.metadata_filter,
        )
        # 异常处理
        if "error" in response:
            raise HTTPException(status_code=500, detail=response["error"])

        # 封装并返回响应结果
        print(f"[RAG-Query] <<< 问答流程结束. 置信度: {response.get('confidence', 0.0):.4f}, 回答字数: {len(response['answer'])}")
        return QueryResponse(
            answer=response["answer"],
            answer_structured=response["answer_structured"],
            results=response["sources"],
            tags=response.get("tags", []),
            confidence=response.get("confidence", 0.0),
            intent=response.get("intent", "general"),
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
