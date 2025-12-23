import os
import shutil
import logging
from typing import List, Optional
from app.config import settings
from app.loaders.doc_loader import DocLoader
from app.loaders.sql_loader import SqlLoader
from app.services.refiner import knowledge_refiner
from app.services.vector_store import vector_store_service

logger = logging.getLogger(__name__)

class IngestionService:
    def list_files(self, collection_name: str) -> List[dict]:
        """
        List files in the collection's directory.
        """
        base_path = os.path.join(settings.DOC_STORAGE_PATH, collection_name)
        if not os.path.exists(base_path):
            return []
            
        files = []
        for f in os.listdir(base_path):
            file_path = os.path.join(base_path, f)
            if os.path.isfile(file_path):
                files.append({
                    "name": f,
                    "size": os.path.getsize(file_path),
                    "last_modified": os.path.getmtime(file_path)
                })
        return files

    async def save_file(self, collection_name: str, filename: str, content: bytes) -> str:
        """
        Save an uploaded file to the collection's directory.
        """
        base_path = os.path.join(settings.DOC_STORAGE_PATH, collection_name)
        os.makedirs(base_path, exist_ok=True)
        
        file_path = os.path.join(base_path, filename)
        with open(file_path, "wb") as f:
            f.write(content)
            
        return file_path

    def delete_file(self, collection_name: str, filename: str) -> bool:
        """
        Delete a file from the collection's directory.
        """
        file_path = os.path.join(settings.DOC_STORAGE_PATH, collection_name, filename)
        if os.path.exists(file_path):
            os.remove(file_path)
            return True
        return False

    def run_ingestion(self, collection_name: str, filenames: Optional[str] = None, enable_qa: bool = False) -> dict:
        """
        Run the ingestion process for a specific collection or a list of files within it.
        filenames: comma separated list of filenames.
        """
        source_path = os.path.join(settings.DOC_STORAGE_PATH, collection_name)
        
        if not os.path.exists(source_path):
             return {"status": "error", "message": f"Directory {source_path} does not exist."}

        # Determine target file(s)
        if filenames:
            # Handle comma separated filenames
            fn_list = [f.strip() for f in filenames.split(",") if f.strip()]
            target_files = []
            for fn in fn_list:
                fp = os.path.join(source_path, fn)
                if os.path.exists(fp):
                    target_files.append(fp)
                else:
                    logger.warning(f"File {fn} not found in {collection_name}, skipping.")
            
            if not target_files:
                return {"status": "error", "message": f"None of the requested files found in {collection_name}."}
            logger.info(f"Targeting {len(target_files)} files for ingestion in {collection_name}")
        else:
            logger.info(f"Starting legacy full ingestion for collection '{collection_name}'...")
            target_files = [os.path.join(source_path, f) for f in os.listdir(source_path) if os.path.isfile(os.path.join(source_path, f))]

        all_docs = []
        file_stats = {}

        for fp in target_files:
            ext = os.path.splitext(fp)[1].lower()
            fname = os.path.basename(fp)
            try:
                if ext == ".sql":
                    loader = SqlLoader(storage_path=os.path.dirname(fp))
                    docs = loader.load()
                    docs = [d for d in docs if os.path.basename(d.metadata.get("file_path", "")) == fname]
                else:
                    loader = DocLoader(storage_path=fp, use_llm_clean=True)
                    docs = loader.load()
                
                # Inject collection name for future pruning/filtering
                for doc in docs:
                    doc.metadata["collection_name"] = collection_name
                
                all_docs.extend(docs)
                file_stats[fname] = len(docs)
                logger.info(f"Loaded {len(docs)} chunks from {fname}")
            except Exception as e:
                logger.error(f"Error loading {fp}: {e}")

        if not all_docs:
            return {"status": "warning", "message": "No documents found to ingest."}

        # 3. Knowledge Refinement
        if enable_qa:
            logger.info("Starting holographic enrichment...")
            all_docs = knowledge_refiner.refine_documents(all_docs)

        # 4. Vector Store Ingestion
        logger.info(f"Ingesting {len(all_docs)} chunks into vector store '{collection_name}'...")
        vector_store_service.add_documents(all_docs, collection_name=collection_name)
        
        return {
            "status": "success", 
            "message": f"Successfully ingested {len(all_docs)} chunks into '{collection_name}'.",
            "chunk_count": len(all_docs),
            "file_stats": file_stats
        }

# Singleton
ingestion_service = IngestionService()

def reset_collection(collection_name: str) -> dict:
    """
    Shortcut for clearing a collection's data.
    """
    from app.services.vector_store import vector_store_service
    success = vector_store_service.clear_collection(collection_name)
    if success:
        return {"status": "success", "message": f"Knowledge base '{collection_name}' has been reset."}
    else:
        return {"status": "error", "message": f"Failed to reset knowledge base '{collection_name}'."}
