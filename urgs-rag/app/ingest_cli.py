import asyncio
import sys
import os

# Ensure project root is in path
sys.path.append(os.getcwd())

from app.config import settings
from app.loaders.doc_loader import DocLoader
from app.loaders.sql_loader import SqlLoader
from app.services.refiner import knowledge_refiner
from app.services.vector_store import vector_store_service

def main():
    print(f"Starting ingestion from: {settings.DOC_STORAGE_PATH}")
    
    all_docs = []

    # 1. Load General Documents (PDF, DOCX, XLSX, TXT)
    print("--- Loading General Documents ---")
    doc_loader = DocLoader(storage_path=settings.DOC_STORAGE_PATH, use_llm_clean=True)
    docs = doc_loader.load()
    print(f"Loaded {len(docs)} document chunks.")
    all_docs.extend(docs)

    # 2. Load SQL Files
    print("--- Loading SQL Files ---")
    sql_loader = SqlLoader(storage_path=settings.DOC_STORAGE_PATH) # Reuse same root, it filters .sql
    sql_docs = sql_loader.load()
    print(f"Loaded {len(sql_docs)} SQL chunks.")
    all_docs.extend(sql_docs)

    if not all_docs:
        print("No documents found to ingest.")
        return

    print(f"Total documents to refine: {len(all_docs)}")

    # 3. Knowledge Refinement (Q&A Generation)
    print("--- Starting Knowledge Refinement (Q&A Generation) ---")
    # This might take a while
    refined_docs = knowledge_refiner.refine_documents(all_docs)
    print(f"Refinement complete. Total docs now: {len(refined_docs)}")

    # 4. Vector Store Ingestion
    print("--- Ingesting into Vector Store ---")
    vector_store_service.add_documents(refined_docs)
    print("Ingestion Complete!")

if __name__ == "__main__":
    main()
