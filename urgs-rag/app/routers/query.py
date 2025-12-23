from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from app.services.qa_service import qa_service

router = APIRouter()

class QueryRequest(BaseModel):
    query: str
    k: int = 4
    collection_names: Optional[List[str]] = None

class QueryResponse(BaseModel):
    answer: str
    results: List[dict]
    tags: List[str] = []

@router.post("/query", response_model=QueryResponse)
async def query_knowledge_base(request: QueryRequest):
    """
    Search and answer using the enhanced holographic RAG pipeline.
    """
    try:
        response = qa_service.answer_question(request.query, collection_names=request.collection_names)
        if "error" in response:
            raise HTTPException(status_code=500, detail=response["error"])
            
        return QueryResponse(
            answer=response["answer"],
            results=response["sources"],
            tags=response.get("tags", [])
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
