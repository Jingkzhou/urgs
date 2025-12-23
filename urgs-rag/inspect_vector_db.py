import sys
import os
import shelve

# Ensure project root is in path
sys.path.append(os.getcwd())

from app.services.vector_store import vector_store_service, settings

def inspect_db():
    print("--- Inspecting Knowledge Base ---")
    
    # 1. Inspect Parent Document Store (Shelve)
    print(f"\n[Parent Store] Path: {vector_store_service.doc_store_path}")
    try:
        with shelve.open(vector_store_service.doc_store_path) as db:
            keys = list(db.keys())
            count = len(keys)
            print(f"Total Parent Documents: {count}")
            
            if count > 0:
                print("\nSample Documents (First 5):")
                for i, key in enumerate(keys[:5]):
                    doc = db[key]
                    meta = doc.metadata
                    source = meta.get('file_name') or meta.get('source') or 'Unknown'
                    content_preview = doc.page_content[:100].replace('\n', ' ')
                    print(f"  {i+1}. ID: {key} | Source: {source}")
                    print(f"     Preview: {content_preview}...")
    except Exception as e:
        print(f"Error accessing Parent Store: {e}")

    # 2. Inspect Vector Store (ChromaDB)
    print(f"\n[Vector Store] Collection: {settings.COLLECTION_NAME}")
    try:
        collection = vector_store_service.client.get_collection(name=settings.COLLECTION_NAME)
        count = collection.count()
        print(f"Total Vector Chunks (Children): {count}")
        
        if count > 0:
            print("\nSample Vector Chunks (First 5):")
            # Peek returns dict with 'ids', 'documents', 'metadatas'
            results = collection.peek(limit=5)
            ids = results['ids']
            docs = results['documents']
            metadatas = results['metadatas']
            
            for i in range(len(ids)):
                meta = metadatas[i] if metadatas else {}
                source = meta.get('file_name') or meta.get('source') or 'Unknown'
                content_preview = docs[i][:100].replace('\n', ' ') if docs else "No Content"
                print(f"  {i+1}. ID: {ids[i]} | Source: {source}")
                print(f"     Preview: {content_preview}...")
                
    except Exception as e:
        print(f"Error accessing Vector Store: {e}")

if __name__ == "__main__":
    inspect_db()
