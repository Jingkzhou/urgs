from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from app.services.vector_store import vector_store_service
from app.config import settings
from app.loaders.sql_loader import SqlLoader
from app.loaders.asset_loader import AssetLoader
from app.loaders.lineage_loader import LineageLoader
from app.services.refiner import knowledge_refiner

router = APIRouter()

from app.services.ingestion import ingestion_service

@router.post("/ingest")
async def ingest_documents(
    source_type: Optional[str] = None,
    collection_name: Optional[str] = None,
    filenames: Optional[str] = None,
    # Allow body params as well via model if needed, but Query params are easier for simple trigger
    enable_qa_generation: bool = False
):
    """
    Ingest documents into the knowledge base.
    If 'collection_name' is provided, it triggers the IngestionService for that specific collection.
    If 'filenames' is also provided (comma separated), it only ingests those specific files.
    """
    try:
        if collection_name:
            # New Path: Trigger ingestion for a specific KB (optionally multiple files)
            return ingestion_service.run_ingestion(collection_name, filenames=filenames, enable_qa=enable_qa_generation)
        
        # Legacy Path (Optional, or can be removed if strictly following the refactor)
        raise HTTPException(status_code=400, detail="collection_name is required for ingestion.")
            
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/delete-file")
async def delete_file_vectors(collection_name: str, filename: str):
    """
    删除指定文件对应的向量切片与父文档。
    """
    try:
        return ingestion_service.delete_file_vectors(collection_name, filename)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
@router.post("/reset")
async def reset_knowledge_base(collection_name: str):
    """
    Clear all vector data and parent documents for a specific knowledge base.
    """
    try:
        from app.services.ingestion import reset_collection
        return reset_collection(collection_name)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
