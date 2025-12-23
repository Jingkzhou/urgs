import os
import shelve
import chromadb
from typing import Iterator, List, Optional, Sequence, Tuple
from chromadb.config import Settings as ChromaSettings
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.embeddings import OpenAIEmbeddings
from langchain_community.retrievers import BM25Retriever
from langchain_classic.retrievers import EnsembleRetriever
from langchain_classic.retrievers import ParentDocumentRetriever
from langchain_core.stores import BaseStore
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document
from app.config import settings
import logging

logger = logging.getLogger(__name__)

class ShelveDocStore(BaseStore[str, Document]):
    """
    A simple persistent DocStore using Python's shelve module.
    """
    def __init__(self, path: str):
        self.path = path
        # Ensure directory exists
        os.makedirs(os.path.dirname(path), exist_ok=True)

    def mget(self, keys: Sequence[str]) -> List[Optional[Document]]:
        docs = []
        with shelve.open(self.path) as db:
            for key in keys:
                docs.append(db.get(key))
        return docs

    def mset(self, key_value_pairs: Sequence[Tuple[str, Document]]) -> None:
        with shelve.open(self.path) as db:
            for key, doc in key_value_pairs:
                db[key] = doc

    def mdelete(self, keys: Sequence[str]) -> None:
        with shelve.open(self.path) as db:
            for key in keys:
                if key in db:
                    del db[key]

    def yield_keys(self, prefix: Optional[str] = None) -> Iterator[str]:
        with shelve.open(self.path) as db:
            for key in db.keys():
                if prefix is None or key.startswith(prefix):
                    yield key

    def get_all_documents(self) -> List[Document]:
        """Custom helper to fetch all docs for BM25 init"""
        docs = []
        with shelve.open(self.path) as db:
            for key in db:
                docs.append(db[key])
        return docs

class VectorStoreService:
    def __init__(self):
        self.persist_directory = settings.CHROMA_PERSIST_DIRECTORY
        self.doc_store_path = os.path.join(settings.PARENT_DOC_STORE_PATH, "holographic_store.db")
        
        # Initialize Embeddings
        if settings.EMBEDDING_PROVIDER == "huggingface":
            self.embeddings = HuggingFaceEmbeddings(
                model_name=settings.EMBEDDING_MODEL_NAME,
                model_kwargs={'device': settings.EMBEDDING_DEVICE}
            )
        elif settings.EMBEDDING_PROVIDER == "qwen3":
            self.embeddings = OpenAIEmbeddings(
                model=settings.EMBEDDING_MODEL_NAME,
                openai_api_base=settings.LLM_API_BASE,
                openai_api_key=settings.LLM_API_KEY
            )
            
        # Initialize Chroma Client
        self.client = chromadb.PersistentClient(path=self.persist_directory)
        
        # Shared Parent Doc Store
        self.docstore = ShelveDocStore(self.doc_store_path)
        self.child_splitter = RecursiveCharacterTextSplitter(chunk_size=400, chunk_overlap=50)
        
        # State tracking
        self.current_collection = None
        self.semantic_vs = None
        self.logic_vs = None
        self.semantic_retriever = None
        self.logic_retriever = None
        self.bm25_retriever = None
        self.ensemble_retriever = None
        self._initialized = False

    def _ensure_retrievers(self, collection_name: str):
        """
        Ensure vector store and retrievers are bound to the requested collection.
        If collection_name changes or is forced, we re-initialize.
        """
        # If no collection name provided, use default
        if not collection_name:
            collection_name = settings.COLLECTION_NAME

        if self.current_collection == collection_name and self.semantic_retriever is not None:
            return

        logger.info(f"Connecting to Vector Space for Knowledge Base: {collection_name}")
        
        # 1. Semantic Path Vector Store
        self.semantic_vs = Chroma(
            client=self.client,
            collection_name=f"{collection_name}_semantic",
            embedding_function=self.embeddings,
        )
        
        # 2. Logic Path Vector Store
        self.logic_vs = Chroma(
            client=self.client,
            collection_name=f"{collection_name}_logic",
            embedding_function=self.embeddings,
        )
        
        # Initialize Path Retrievers
        self.semantic_retriever = ParentDocumentRetriever(
            vectorstore=self.semantic_vs,
            docstore=self.docstore,
            child_splitter=self.child_splitter,
        )
        self.logic_retriever = ParentDocumentRetriever(
            vectorstore=self.logic_vs,
            docstore=self.docstore,
            child_splitter=self.child_splitter,
        )

        self.current_collection = collection_name
        self._initialized = False # Force reload of hybrid/ensemble for this new context

    def _initialize_hybrid_retriever(self, documents=None):
        try:
            if not documents:
                logger.info("Checking ShelveDocStore for BM25 documents...")
                # We only build BM25 if there's actual data. 
                # Optimization: Don't load everything just to check size if we can avoid it.
                # documents = self.docstore.get_all_documents()
                
                # Check at least one key exists to avoid loading 10k docs unnecessarily during metadata calls
                has_data = any(self.docstore.yield_keys())
                if not has_data:
                    logger.info("DocStore is empty. Hybrid Search waiting for data.")
                    self._initialized = True
                    return

                logger.info("Loading documents for BM25 initialization...")
                documents = self.docstore.get_all_documents()
            
            if documents:
                logger.info(f"Building BM25 index from {len(documents)} parent documents...")
                self.bm25_retriever = BM25Retriever.from_documents(documents)
                self.bm25_retriever.k = 5
                
                # Triple-Path Ensemble: BM25 + Semantic + Logic
                self.ensemble_retriever = EnsembleRetriever(
                    retrievers=[self.bm25_retriever, self.semantic_retriever, self.logic_retriever],
                    weights=[0.4, 0.3, 0.3]
                )
            self._initialized = True
        except Exception as e:
            logger.error(f"Failed to initialize multi-path hybrid retriever: {e}")
            # Ensure we don't loop forever if it keeps failing
            self._initialized = True 

    def add_documents(self, documents: List[Document], collection_name: str = None):
        """
        Add documents with Path-based routing.
        """
        self._ensure_retrievers(collection_name)
        if not documents:
            return
        
        # Ensure collection_name is tracked in metadata for future cleanup
        if collection_name:
            for d in documents:
                d.metadata["collection_name"] = collection_name
        
        # Default to semantic path if no type is specified
        semantic_docs = [d for d in documents if d.metadata.get("path_type") == "semantic" or d.metadata.get("path_type") is None]
        logic_docs = [d for d in documents if d.metadata.get("path_type") == "logic"]
        
        if semantic_docs:
            logger.info(f"Adding {len(semantic_docs)} to Semantic Path (including default/untyped)...")
            self.semantic_retriever.add_documents(semantic_docs)
            
        if logic_docs:
            logger.info(f"Adding {len(logic_docs)} to Logic Path...")
            self.logic_retriever.add_documents(logic_docs)
        
        self._initialize_hybrid_retriever()

    def similarity_search(self, query: str, k: int = 4, collection_name: str = None):
        """
        Search across all paths. 
        Note: We return Parent Documents (Full Context).
        """
        self._ensure_retrievers(collection_name)
        if not self._initialized:
            self._initialize_hybrid_retriever()

        if self.ensemble_retriever:
            logger.info(f"Performing Multi-Path Hybrid Search: {query}")
            return self.ensemble_retriever.invoke(query, k=k)
        else:
            # Fallback to semantic if ensemble not ready
            logger.info(f"Performing Parent-Child Search (Semantic Only) for: {query}")
            return self.semantic_retriever.invoke(query)

    def as_retriever(self, collection_name: str = None):
        self._ensure_retrievers(collection_name)
        if not self._initialized:
            self._initialize_hybrid_retriever()
        return self.ensemble_retriever or self.semantic_retriever

    def clear_collection(self, collection_name: str):
        """
        Delete all data associated with a collection from Chroma and the DocStore.
        """
        logger.info(f"Resetting vector store for collection '{collection_name}'...")
        
        # 1. Delete Chroma Collections
        try:
            # We target the specific sub-collections we manage, AND the base collection if it exists
            semantic_col = f"{collection_name}_semantic"
            logic_col = f"{collection_name}_logic"
            base_col = collection_name
            
            target_cols = [semantic_col, logic_col, base_col]
            for col in target_cols:
                try:
                    # Check if collection exists before attempting delete to avoid noise in logs
                    # But delete_collection usually raises if missing, so we catch
                    self.client.delete_collection(col)
                    logger.info(f"Deleted Chroma collection: {col}")
                except Exception:
                    pass
                
                # Re-create empty collections for future use
                try:
                    self.client.create_collection(col)
                except Exception:
                    pass

        except Exception as e:
            logger.warning(f"Error during Chroma collections reset for {collection_name}: {e}")

        # 2. Cleanup DocStore
        # Since ShelveDocStore is shared and doesn't support easy 'filtered delete' by collection,
        # we rely on the fact that when we re-ingest, we overwrite or add new ones.
        # However, to be thorough, if we knew the doc IDs we could delete them.
        # Alternative: Re-initialize hybrid retriever which will detect empty store for this context
        # (though DocStore might still have other collections' data).
        # A better ShelveDocStore should support 'collection' partitioning.
        # For now, we manually prune if we find keys matching source patterns.
        try:
             keys_to_del = []
             all_keys = list(self.docstore.yield_keys())
             batch_size = 500
             
             for i in range(0, len(all_keys), batch_size):
                  batch_keys = all_keys[i:i+batch_size]
                  docs = self.docstore.mget(batch_keys)
                  for j, doc in enumerate(docs):
                       if doc and doc.metadata.get("collection_name") == collection_name:
                            keys_to_del.append(batch_keys[j])
             
             if keys_to_del:
                  logger.info(f"Pruning {len(keys_to_del)} parent documents from DocStore for {collection_name}")
                  # Batch delete
                  for i in range(0, len(keys_to_del), batch_size):
                       self.docstore.mdelete(keys_to_del[i:i+batch_size])
        except Exception as e:
             logger.error(f"Error pruning DocStore: {e}")

        # VERY IMPORTANT: Re-connect to force refresh of collection IDs
        self._reinit_singleton_state()
        return True

    def _reinit_singleton_state(self):
        """Reset state to force re-connection on next call"""
        self.current_collection = None
        self._initialized = False
        self.semantic_retriever = None
        self.ensemble_retriever = None

    def list_collections(self) -> List[dict]:
        """
        List all available ChromaDB collections.
        """
        try:
            collections = self.client.list_collections()
            return [{"name": c.name, "metadata": c.metadata} for c in collections]
        except Exception as e:
            logger.error(f"Failed to list collections: {e}")
            return []

# Singleton instance
vector_store_service = VectorStoreService()
