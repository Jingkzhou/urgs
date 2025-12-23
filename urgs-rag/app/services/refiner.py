from typing import List
from langchain_core.documents import Document
from app.services.llm_chain import llm_service

class KnowledgeRefiner:
    """
    Refines knowledge by generating holographic data (QA, Reasoning, Tags).
    Separates content into 'semantic' and 'logic' paths.
    """
    def refine_documents(self, documents: List[Document]) -> List[Document]:
        """
        Enhance documents with holographic data.
        """
        holographic_docs = []
        total = len(documents)
        print(f"Refining {total} documents with holographic data generation...")
        
        for i, doc in enumerate(documents):
            # 1. Semantic Path: Original Document
            doc.metadata["path_type"] = "semantic"
            holographic_docs.append(doc)
            
            # Enrich substantial chunks
            text = doc.page_content
            if len(text) > 100:
                print(f"Enriching doc {i+1}/{total}...")
                enriched = llm_service.enrich_knowledge(text)
                
                # 2. Logic Path - Questions
                for q in enriched.get("questions", []):
                    q_doc = Document(
                        page_content=f"问题: {q}\n相关知识: {text[:200]}...",
                        metadata={
                            **doc.metadata,
                            "path_type": "logic",
                            "logic_type": "question",
                            "original_content": text, # Link to full context
                            "is_synthetic": True
                        }
                    )
                    holographic_docs.append(q_doc)
                
                # 3. Logic Path - Reasoning Kernel
                reasoning = enriched.get("reasoning")
                if reasoning:
                    r_doc = Document(
                        page_content=f"逻辑核/推导过程: {reasoning}",
                        metadata={
                            **doc.metadata,
                            "path_type": "logic",
                            "logic_type": "reasoning",
                            "tags": enriched.get("tags", []),
                            "is_synthetic": True
                        }
                    )
                    holographic_docs.append(r_doc)
                    
                    # Also update primary doc with tags
                    doc.metadata["tags"] = enriched.get("tags", [])
        
        print(f"Refinement complete. {total} docs -> {len(holographic_docs)} holographic pieces.")
        return holographic_docs

knowledge_refiner = KnowledgeRefiner()
