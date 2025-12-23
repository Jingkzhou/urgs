from fastapi import APIRouter, HTTPException
from typing import List, Optional
from app.services.vector_store import vector_store_service

router = APIRouter(prefix="/api/rag/vector-db", tags=["vector-db"])

@router.get("/collections")
async def list_collections():
    """List all collections in ChromaDB"""
    try:
        return vector_store_service.list_collections()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/collections/{name}/peek")
async def peek_collection(name: str, limit: int = 20):
    """Peek into a collection to see sample documents"""
    try:
        collection = vector_store_service.client.get_collection(name=name)
        count = collection.count()
        
        # Peek returns dict with 'ids', 'documents', 'metadatas'
        results = collection.peek(limit=limit)
        
        formatted_results = []
        ids = results.get('ids', [])
        documents = results.get('documents', [])
        metadatas = results.get('metadatas', [])
        
        for i in range(len(ids)):
            formatted_results.append({
                "id": ids[i],
                "content": documents[i] if documents else "",
                "metadata": metadatas[i] if metadatas else {}
            })
            
        return {
            "name": name,
            "total_count": count,
            "results": formatted_results
        }
    except Exception as e:
        if "does not exist" in str(e):
             raise HTTPException(status_code=404, detail=f"Collection '{name}' not found")
        raise HTTPException(status_code=500, detail=str(e))
