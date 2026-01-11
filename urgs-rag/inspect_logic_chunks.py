from app.services.vector_store import vector_store_service
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)

def inspect_logic(file_name_keyword: str):
    print(f"Checking for logic chunks for file containing: {file_name_keyword}")
    collection_name = "urgs_knowledge_base"
    vector_store_service._ensure_vectorstores(collection_name)
    
    # Query the logic collection directly
    logic_vs = vector_store_service.logic_vs
    if not logic_vs:
        print("Logic vector store not initialized.")
        return

    # Chroma allows get() with where clause
    try:
        # Note: metadata keys might vary, we check 'file_name'
        # Since we can't do 'contains' easily in chroma 'where', we fetch a broad set or just iterate if small
        # But wait, vector_store_service.docstore has all parent docs. Logic chunks are in Chroma.
        # Let's simple query Chroma for *all* logic chunks first (limit 20) and filter in python to find the file
        results = logic_vs.get(limit=100, include=["metadatas", "documents"])
        
        found_count = 0
        print("\n--- Simulated Questions found ---")
        for i, meta in enumerate(results['metadatas']):
            if file_name_keyword in meta.get("file_name", ""):
                 content = results['documents'][i]
                 # Logic chunks usually start with "问题:"
                 if "问题:" in content:
                     print(f"[Question] {content.split('相关知识')[0].strip()}")
                     found_count += 1
                 elif "逻辑核" in content:
                     print(f"[Reasoning] {content[:100]}...")
                     found_count += 1
        
        if found_count == 0:
            print("No logic chunks found for this file. It might not have been ingested with AI refinement enabled, or text was too short.")
            
    except Exception as e:
        print(f"Error inspecting chroma: {e}")

if __name__ == "__main__":
    inspect_logic("视觉型小学生")
