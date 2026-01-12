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

@router.get("/collections/{collection_name}/random-qa")
async def get_random_qa(collection_name: str, count: int = 4):
    """
    从指定知识库的逻辑路径 (Logic) 集合中随机抽取模拟问答。
    
    用于生成智能体的推荐提示词。
    """
    import random
    
    try:
        logic_collection_name = f"{collection_name}_logic"
        collection = vector_store_service.client.get_collection(name=logic_collection_name)
        
        # 获取所有 logic_type=question 的文档
        results = collection.get(
            where={"logic_type": {"$eq": "question"}},
            include=["documents", "metadatas"]
        )
        
        documents = results.get('documents', [])
        
        if not documents:
            return {"questions": [], "message": "该知识库暂无模拟问答数据"}
        
        # 提取问题内容
        qa_candidates = []
        for doc in documents:
            if doc.startswith("问题:"):
                question = doc.split("\n")[0].replace("问题:", "").strip()
                if question:
                    qa_candidates.append(question)
        
        if not qa_candidates:
            return {"questions": [], "message": "未提取到有效问题"}
        
        # 简单随机抽取
        selected_contents = random.sample(qa_candidates, min(count, len(qa_candidates)))
        
        # 格式化返回
        result_list = []
        for content in selected_contents:
            result_list.append({
                "title": content[:20] + "..." if len(content) > 20 else content,
                "content": content
            })
            
        return {
            "questions": result_list,
            "total_available": len(qa_candidates),
            "message": f"随机抽取了 {len(result_list)} 个问题"
        }
    except Exception as e:
        if "does not exist" in str(e):
            raise HTTPException(status_code=404, detail=f"逻辑集合 '{logic_collection_name}' 未找到，请确保知识库已完成向量化")
        raise HTTPException(status_code=500, detail=str(e))
