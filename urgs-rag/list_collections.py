from app.services.vector_store import vector_store_service
import logging

# Setup logging
logging.basicConfig(level=logging.ERROR)

def list_cols():
    print("--- Listing Chroma Collections ---")
    try:
        cols = vector_store_service.list_collections()
        for c in cols:
            print(f"- {c['name']}")
    except Exception as e:
        print(e)
            
if __name__ == "__main__":
    list_cols()
