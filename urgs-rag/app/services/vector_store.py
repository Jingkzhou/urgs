import os
import shelve
import uuid
import logging
import re
from dataclasses import dataclass
from typing import Dict, Iterator, List, Optional, Sequence, Tuple

import chromadb
import numpy as np
from rank_bm25 import BM25Okapi
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_community.embeddings import OpenAIEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document

from app.config import settings
from app.services.reranker import reranker_service

logger = logging.getLogger(__name__)


class ShelveDocStore:
    """
    基于 Python shelve 模块的持久化文档存储。
    
    用于存储“父文档”（即未切分的原始全息片段），
    在向量检索命中“子文档”后，通过 parent_id 找回完整的父级上下文。
    """

    def __init__(self, path: str):
        self.path = path
        os.makedirs(os.path.dirname(path), exist_ok=True)

    def mget(self, keys: Sequence[str]) -> List[Optional[Document]]:
        """批量获取文档。"""
        docs = []
        with shelve.open(self.path) as db:
            for key in keys:
                docs.append(db.get(key))
        return docs

    def mset(self, key_value_pairs: Sequence[Tuple[str, Document]]) -> None:
        """批量存储文档。"""
        with shelve.open(self.path) as db:
            for key, doc in key_value_pairs:
                db[key] = doc

    def mdelete(self, keys: Sequence[str]) -> None:
        """批量删除文档。"""
        with shelve.open(self.path) as db:
            for key in keys:
                if key in db:
                    del db[key]

    def yield_keys(self, prefix: Optional[str] = None) -> Iterator[str]:
        """迭代获取所有 Key。"""
        with shelve.open(self.path) as db:
            for key in db.keys():
                if prefix is None or key.startswith(prefix):
                    yield key

    def get_all_documents(self) -> List[Document]:
        """获取存储的所有文档。"""
        docs = []
        with shelve.open(self.path) as db:
            for key in db:
                docs.append(db[key])
        return docs


@dataclass
class ScoredDocument:
    """带评分的文档封装类。"""
    document: Document
    score: float
    score_details: Dict[str, float]


class BM25Index:
    """
    基于 BM25 算法的关键词索引。
    
    作为向量检索的补充，处理精准匹配和某些特定生僻词匹配。
    """
    def __init__(self, documents: List[Document]):
        self.documents = documents
        # 对语料进行分词处理
        self.corpus_tokens = [self._tokenize(doc.page_content) for doc in documents]
        self.bm25 = BM25Okapi(self.corpus_tokens) if self.corpus_tokens else None

    def _tokenize(self, text: str) -> List[str]:
        """简单的中英文混合分词逻辑。"""
        if not text:
            return []
        # 提取英文单词和单个中文字符
        tokens = re.findall(r"[A-Za-z0-9]+|[\u4e00-\u9fff]", text)
        return [t.lower() for t in tokens if t.strip()]

    def search(self, query: str, top_k: int, metadata_filter: Optional[dict] = None) -> List[ScoredDocument]:
        """执行 BM25 关键词检索。"""
        if not self.bm25:
            return []
        query_tokens = self._tokenize(query)
        scores = self.bm25.get_scores(query_tokens)
        # 获取得分最高的索引
        ranked = np.argsort(scores)[::-1]

        results: List[ScoredDocument] = []
        for idx in ranked[:top_k]:
            doc = self.documents[idx]
            # 执行元数据过滤
            if metadata_filter and not VectorStoreService.match_filters(doc.metadata, metadata_filter):
                continue
            score = float(scores[idx])
            results.append(
                ScoredDocument(
                    document=doc,
                    score=score,
                    score_details={"bm25": score},
                )
            )
        return results


class VectorStoreService:
    """
    全息向量存储服务。
    
    管理 ChromaDB 向量空间（分为语义、逻辑、摘要三个 Collection）
    以及 BM25 索引，支持混合检索 (Hybrid Search) 和精排 (Rerank)。
    """
    def __init__(self):
        self.persist_directory = settings.CHROMA_PERSIST_DIRECTORY
        self.doc_store_path = os.path.join(settings.PARENT_DOC_STORE_PATH, "holographic_store.db")

        # 初始化 Embedding 模型
        if settings.EMBEDDING_PROVIDER == "huggingface":
            self.embeddings = HuggingFaceEmbeddings(
                model_name=settings.EMBEDDING_MODEL_NAME,
                model_kwargs={"device": settings.EMBEDDING_DEVICE},
            )
        elif settings.EMBEDDING_PROVIDER == "qwen3":
            self.embeddings = OpenAIEmbeddings(
                model=settings.EMBEDDING_MODEL_NAME,
                openai_api_base=settings.LLM_API_BASE,
                openai_api_key=settings.LLM_API_KEY,
            )

        # 初始化向量库和父文档存储
        self.client = chromadb.PersistentClient(path=self.persist_directory)
        self.docstore = ShelveDocStore(self.doc_store_path)
        # 用于将父文档切分为子片段的切分器（用于向量搜索）
        self.child_splitter = RecursiveCharacterTextSplitter(chunk_size=400, chunk_overlap=50)

        self.current_collection = None
        self.semantic_vs = None
        self.logic_vs = None
        self.summary_vs = None
        self._bm25_indexes: Dict[str, BM25Index] = {}

    @staticmethod
    def match_filters(metadata: dict, metadata_filter: dict) -> bool:
        """
        通用的元数据过滤匹配逻辑。
        支持单值匹配、列表包含匹配以及列表交集匹配。
        """
        for key, value in (metadata_filter or {}).items():
            meta_value = metadata.get(key)
            if isinstance(meta_value, list):
                if isinstance(value, list):
                    # 列表与列表：取交集
                    if not set(meta_value) & set(value):
                        return False
                else:
                    # 列表与单值
                    if value not in meta_value:
                        return False
            elif isinstance(value, list):
                # 单值与列表
                if meta_value not in value:
                    return False
            else:
                # 单值与单值
                if meta_value != value:
                    return False
        return True

    def _ensure_vectorstores(self, collection_name: str):
        """确保目标集合的各个路径向量空间已连接。"""
        if not collection_name:
            collection_name = settings.COLLECTION_NAME
        if self.current_collection == collection_name and self.semantic_vs is not None:
            return

        logger.info(f"正在连接知识库向量空间: {collection_name}")
        # 分别连接语义、逻辑、摘要三个 Chroma 集合
        self.semantic_vs = Chroma(
            client=self.client,
            collection_name=f"{collection_name}_semantic",
            embedding_function=self.embeddings,
        )
        self.logic_vs = Chroma(
            client=self.client,
            collection_name=f"{collection_name}_logic",
            embedding_function=self.embeddings,
        )
        self.summary_vs = Chroma(
            client=self.client,
            collection_name=f"{collection_name}_summary",
            embedding_function=self.embeddings,
        )
        self.current_collection = collection_name

    def _normalize_vector_score(self, score: float) -> float:
        """将 Chroma 返回的欧氏距离转换为 [0, 1] 的相似度评分。"""
        if score is None:
            return 0.0
        # Chroma 返回的是距离，距离越小越相似
        return 1.0 / (1.0 + float(score))

    def _normalize_scores(self, items: List[ScoredDocument], key: str) -> List[ScoredDocument]:
        """将一组检索结果的评分归一化到 [0, 1] 空间。"""
        if not items:
            return []
        max_score = max(d.score for d in items) or 1.0
        normalized = []
        for item in items:
            norm_score = item.score / max_score
            normalized.append(
                ScoredDocument(
                    document=item.document,
                    score=norm_score,
                    score_details={**item.score_details, key: norm_score},
                )
            )
        return normalized

    def _vector_search(self, vectorstore: Chroma, query: str, k: int, metadata_filter: Optional[dict], source: str) -> List[ScoredDocument]:
        """执行单一向量空间的搜索，并自动回溯到父文档。"""
        if not vectorstore:
            return []
        try:
            hits = vectorstore.similarity_search_with_score(query, k=k, filter=metadata_filter)
        except TypeError:
            # 某些旧版本或兼容层不支持 filter
            hits = vectorstore.similarity_search_with_score(query, k=k)

        parent_scores: Dict[str, float] = {}
        direct_results: List[ScoredDocument] = []
        
        # 遍历命中片段
        for child_doc, distance in hits:
            score = self._normalize_vector_score(distance)
            parent_id = child_doc.metadata.get("parent_id")
            if parent_id:
                # 记录该父文档的最佳子片段得分
                parent_scores[parent_id] = max(parent_scores.get(parent_id, 0.0), score)
            else:
                # 无父文档标识的直接作为结果
                direct_results.append(
                    ScoredDocument(
                        document=child_doc,
                        score=score,
                        score_details={source: score},
                    )
                )

        if parent_scores:
            # 从父文档存储 (Shelve) 中批量取回完整内容
            parent_ids = list(parent_scores.keys())
            parent_docs = self.docstore.mget(parent_ids)
            for parent_id, parent_doc in zip(parent_ids, parent_docs):
                if not parent_doc:
                    continue
                # 后置过滤（以防向量库 filter 穿透）
                if metadata_filter and not self.match_filters(parent_doc.metadata, metadata_filter):
                    continue
                score = parent_scores[parent_id]
                direct_results.append(
                    ScoredDocument(
                        document=parent_doc,
                        score=score,
                        score_details={source: score},
                    )
                )

        return direct_results

    def _get_bm25_index(self, collection_name: str) -> Optional[BM25Index]:
        """按需加载指定集合的 BM25 索引。"""
        if not collection_name:
            collection_name = settings.COLLECTION_NAME
        if collection_name in self._bm25_indexes:
            return self._bm25_indexes[collection_name]

        # 首次加载需从 docstore 遍历所有属于该集合的父文档
        documents = self.docstore.get_all_documents()
        filtered_docs = [
            doc for doc in documents
            if doc.metadata.get("collection_name") == collection_name
        ]
        if not filtered_docs:
            return None
        index = BM25Index(filtered_docs)
        self._bm25_indexes[collection_name] = index
        return index

    def _merge_scored(self, buckets: List[Tuple[str, float, List[ScoredDocument]]]) -> List[Dict]:
        """将不同路径和算法返回的分数按权重合并。"""
        merged: Dict[str, Dict] = {}
        for source, weight, docs in buckets:
            # 路径内评分归一化
            normalized_docs = self._normalize_scores(docs, source)
            for item in normalized_docs:
                doc = item.document
                # 确定文档唯一标识
                doc_key = doc.metadata.get("parent_id") or doc.metadata.get("origin_parent_id") or doc.metadata.get("file_name") or str(id(doc))
                if doc_key not in merged:
                    merged[doc_key] = {
                        "document": doc,
                        "score": 0.0,
                        "score_details": {},
                    }
                # 加权求和
                merged[doc_key]["score"] += weight * item.score
                merged[doc_key]["score_details"].update(item.score_details)

        # 按综合得分降序排列
        return sorted(merged.values(), key=lambda x: x["score"], reverse=True)

    def hybrid_search(
        self,
        query: str,
        k: int = 4,
        collection_name: str = None,
        metadata_filter: Optional[dict] = None,
    ) -> List[Dict]:
        """
        全息混合检索：四路搜索 + 动态权重 + 可选重排序。
        
        搜索路径：
        1. BM25: 关键词匹配。
        2. Semantic: 原始语义向量匹配。
        3. Logic: 合成问题/逻辑核向量匹配。
        4. Summary: 核心摘要向量匹配。
        """
        self._ensure_vectorstores(collection_name)
        top_k = max(k, settings.RETRIEVAL_TOP_K)
        candidate_k = max(top_k * 2, 8) # 预取的候选量

        # 并行执行四路检索（此处为串行代码实现）
        semantic_hits = self._vector_search(self.semantic_vs, query, candidate_k, metadata_filter, "semantic")
        logic_hits = self._vector_search(self.logic_vs, query, candidate_k, metadata_filter, "logic")
        summary_hits = self._vector_search(self.summary_vs, query, candidate_k, metadata_filter, "summary")

        bm25_index = self._get_bm25_index(collection_name)
        bm25_hits = bm25_index.search(query, candidate_k, metadata_filter) if bm25_index else []

        # 组装权重桶
        buckets = [
            ("bm25", settings.WEIGHT_BM25, bm25_hits),
            ("semantic", settings.WEIGHT_SEMANTIC, semantic_hits),
            ("logic", settings.WEIGHT_LOGIC, logic_hits),
            ("summary", settings.WEIGHT_SUMMARY, summary_hits),
        ]

        # 合并各路结果
        merged = self._merge_scored(buckets)
        if not merged:
            return []

        # 可选：精排 (Rerank)
        if settings.RERANKER_ENABLED:
            # 仅对合并后的前 N 个候选者进行精排，以平衡时间效率
            rerank_top = merged[: min(settings.RERANKER_TOP_N, len(merged))]
            rerank_docs = [item["document"] for item in rerank_top]
            rerank_scores = reranker_service.rerank(query, rerank_docs)
            
            if rerank_scores:
                # 归一化精排得分
                max_rerank = max(score for _, score in rerank_scores) or 1.0
                rerank_map = {self._doc_key(doc): score / max_rerank for doc, score in rerank_scores}
                
                for item in merged:
                    doc_key = self._doc_key(item["document"])
                    if doc_key in rerank_map:
                        base_score = item["score"]
                        rerank_score = rerank_map[doc_key]
                        # 综合计算：(1-w)*初筛分数 + w*精排分数
                        item["score"] = (1 - settings.RERANKER_WEIGHT) * base_score + settings.RERANKER_WEIGHT * rerank_score
                        item["score_details"]["rerank"] = rerank_score

        return merged[:top_k]

    def _doc_key(self, doc: Document) -> str:
        """从文档元数据中提取唯一标识 Key。"""
        return doc.metadata.get("parent_id") or doc.metadata.get("origin_parent_id") or doc.metadata.get("file_name") or str(id(doc))

    def add_documents(self, documents: List[Document], collection_name: str = None):
        """
        向向量库添加全息文档。
        
        过程：
        1. 注入集合名称元数据。
        2. 生成并存储父文档到 Shelve。
        3. 利用 child_splitter 将父文档切分为子片段。
        4. 根据 path_type 将子片段路由到不同的向量 Collection (Semantic/Logic/Summary)。
        5. 清除旧的 BM25 索引缓存。
        """
        self._ensure_vectorstores(collection_name)
        if not documents:
            return

        if collection_name:
            for d in documents:
                d.metadata["collection_name"] = collection_name

        # 确保每个父文档都有 parent_id
        for doc in documents:
            if not doc.metadata.get("parent_id"):
                doc.metadata["parent_id"] = uuid.uuid4().hex

        # 存入父文档存储
        self.docstore.mset([(doc.metadata["parent_id"], doc) for doc in documents])

        # 切分为子片段用于向量检索
        child_docs = self.child_splitter.split_documents(documents)
        for child in child_docs:
            if not child.metadata.get("parent_id"):
                # 关联到父文档 ID
                child.metadata["parent_id"] = child.metadata.get("origin_parent_id") or uuid.uuid4().hex

        # 根据全息路径类型路由子片段
        semantic_docs = [d for d in child_docs if d.metadata.get("path_type") in (None, "semantic")]
        logic_docs = [d for d in child_docs if d.metadata.get("path_type") == "logic"]
        summary_docs = [d for d in child_docs if d.metadata.get("path_type") == "summary"]

        if semantic_docs:
            logger.info(f"正在向语义路径添加 {len(semantic_docs)} 个片段...")
            self.semantic_vs.add_documents(semantic_docs)
        if logic_docs:
            logger.info(f"正在向逻辑路径添加 {len(logic_docs)} 个片段...")
            self.logic_vs.add_documents(logic_docs)
        if summary_docs:
            logger.info(f"正在向摘要路径添加 {len(summary_docs)} 个片段...")
            self.summary_vs.add_documents(summary_docs)

        # 添加新文档后，强制 BM25 索引在下次搜索时重新构建
        if collection_name:
            self._bm25_indexes.pop(collection_name, None)

    def clear_collection(self, collection_name: str):
        """彻底清空指定集合的向量库和父文档存储。"""
        logger.info(f"正在重置集合 '{collection_name}' 的向量存储...")
        try:
            semantic_col = f"{collection_name}_semantic"
            logic_col = f"{collection_name}_logic"
            summary_col = f"{collection_name}_summary"
            base_col = collection_name

            # 删除并重建所有相关的 Chroma 集合
            for col in [semantic_col, logic_col, summary_col, base_col]:
                try:
                    self.client.delete_collection(col)
                    logger.info(f"已删除 Chroma 集合: {col}")
                except Exception:
                    pass
                try:
                    self.client.create_collection(col)
                except Exception:
                    pass
        except Exception as e:
            logger.warning(f"重置 Chroma 集合 {collection_name} 时出错: {e}")

        try:
            # 从 Shelve 中删除属于该集合的父文档
            keys_to_del = []
            all_keys = list(self.docstore.yield_keys())
            batch_size = 500
            for i in range(0, len(all_keys), batch_size):
                batch_keys = all_keys[i:i + batch_size]
                docs = self.docstore.mget(batch_keys)
                for j, doc in enumerate(docs):
                    if doc and doc.metadata.get("collection_name") == collection_name:
                        keys_to_del.append(batch_keys[j])

            if keys_to_del:
                logger.info(f"正在从 DocStore 中清理属于 {collection_name} 的 {len(keys_to_del)} 个父文档")
                for i in range(0, len(keys_to_del), batch_size):
                    self.docstore.mdelete(keys_to_del[i:i + batch_size])
        except Exception as e:
            logger.error(f"清理 DocStore 时出错: {e}")

        # 清除内存中的索引和连接
        self._bm25_indexes.pop(collection_name, None)
        self.current_collection = None
        self.semantic_vs = None
        self.logic_vs = None
        self.summary_vs = None
        return True

    def delete_by_file(self, collection_name: str, file_name: str) -> dict:
        """按文件名删除指定集合的向量片段与父文档。"""
        self._ensure_vectorstores(collection_name)
        if not collection_name or not file_name:
            return {"status": "error", "message": "collection_name 和 file_name 均不能为空。"}

        deleted_parent = 0
        deleted_vectors = 0

        # 删除向量库中的子片段
        for suffix in ["semantic", "logic", "summary"]:
            col_name = f"{collection_name}_{suffix}"
            try:
                col = self.client.get_collection(col_name)
                col.delete(where={"collection_name": collection_name, "file_name": file_name})
                deleted_vectors += 1
            except Exception as e:
                logger.warning(f"删除向量集合 {col_name} 中的 {file_name} 失败: {e}")

        # 删除 DocStore 中的父文档
        keys_to_del = []
        all_keys = list(self.docstore.yield_keys())
        batch_size = 500
        for i in range(0, len(all_keys), batch_size):
            batch_keys = all_keys[i:i + batch_size]
            docs = self.docstore.mget(batch_keys)
            for j, doc in enumerate(docs):
                if not doc:
                    continue
                meta = doc.metadata or {}
                if meta.get("collection_name") == collection_name and meta.get("file_name") == file_name:
                    keys_to_del.append(batch_keys[j])

        if keys_to_del:
            for i in range(0, len(keys_to_del), batch_size):
                self.docstore.mdelete(keys_to_del[i:i + batch_size])
            deleted_parent = len(keys_to_del)

        # 触发 BM25 索引重建
        self._bm25_indexes.pop(collection_name, None)

        return {
            "status": "success",
            "message": f"已删除 {file_name} 的向量片段与父文档。",
            "deleted_parent_docs": deleted_parent,
            "deleted_vector_collections": deleted_vectors,
        }

    def list_collections(self) -> List[dict]:
        """列出所有已存在的 Chroma 集合。"""
        try:
            collections = self.client.list_collections()
            return [{"name": c.name, "metadata": c.metadata} for c in collections]
        except Exception as e:
            logger.error(f"获取集合列表失败: {e}")
            return []

    def rebuild_bm25_index(self, collection_name: str) -> bool:
        """手动强制重建指定集合的 BM25 索引。"""
        try:
            self._bm25_indexes.pop(collection_name, None)
            self._get_bm25_index(collection_name)
            return True
        except Exception as e:
            logger.error(f"重建 {collection_name} 的 BM25 索引失败: {e}")
            return False


# 导出全息向量存储服务单例
vector_store_service = VectorStoreService()
