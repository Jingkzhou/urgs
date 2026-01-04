from fastapi import APIRouter, HTTPException
from typing import List, Optional
from app.services.vector_store import vector_store_service

# 初始化路由，设置专门的向量数据库管理前缀
router = APIRouter(prefix="/api/rag/vector-db", tags=["vector-db"])

@router.get("/collections")
async def list_collections():
    """
    列出 ChromaDB 中所有的集合名称。
    """
    try:
        return vector_store_service.list_collections()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/collections/{name}/peek")
async def peek_collection(name: str, limit: int = 20):
    """
    预览集合中的数据片段，用于调试和确认数据。
    """
    try:
        collection = vector_store_service.client.get_collection(name=name)
        count = collection.count()
        
        # peek 返回包含 'ids', 'documents', 'metadatas' 的字典
        results = collection.peek(limit=limit)
        
        formatted_results = []
        ids = results.get('ids', [])
        documents = results.get('documents', [])
        metadatas = results.get('metadatas', [])
        
        # 格式化输出，方便前端/控制台展示
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
             raise HTTPException(status_code=404, detail=f"集合 '{name}' 未找到")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/collections/{name}/bm25/rebuild")
async def rebuild_bm25(name: str):
    """
    手动重建指定集合的 BM25 (关键词) 索引。
    
    通常在全量更新向量数据库后需要调用，以确保混合检索的准确性。
    """
    try:
        success = vector_store_service.rebuild_bm25_index(name)
        if not success:
            raise HTTPException(status_code=500, detail="BM25 索引重建失败")
        return {"status": "success", "message": f"成功为 '{name}' 重建 BM25 索引"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
