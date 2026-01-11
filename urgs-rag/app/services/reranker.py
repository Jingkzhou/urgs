import logging
from typing import List, Tuple

from langchain_core.documents import Document

from app.config import settings

logger = logging.getLogger(__name__)


class RerankerService:
    """
    检索重排序服务。
    
    使用 CrossEncoder 模型对初筛检索结果进行二次打分，
    以获得比向量检索更精确的相关性评估（精排）。
    """
    def __init__(self):
        self._model = None

    def _load_model(self):
        """
        按需加载重排序模型。
        """
        if not settings.RERANKER_ENABLED:
            return None
        if self._model is not None:
            return self._model
        try:
            try:
                from sentence_transformers import CrossEncoder
                self._model = CrossEncoder(settings.RERANKER_MODEL, device=settings.RERANKER_DEVICE)
                return self._model
            except ImportError:
                logger.warning("sentence-transformers not installed, Reranker disabled.")
                return None
        except Exception as e:
            logger.error(f"加载精排模型失败: {e}")
            self._model = None
            return None

    def rerank(self, query: str, documents: List[Document]) -> List[Tuple[Document, float]]:
        """
        执行重排序任务。

        Args:
            query (str): 用户查询语句。
            documents (List[Document]): 待排序的候选文档列表。

        Returns:
            List[Tuple[Document, float]]: 排序后的 (原始文档, 精排得分) 元组列表。
        """
        if not settings.RERANKER_ENABLED:
            return []
        model = self._load_model()
        if model is None or not documents:
            return []

        # 构造 (查询, 内容) 对，CrossEncoder 会对每一对计算相关性
        # 注意：限制文档内容长度，避免显存溢出
        pairs = [(query, doc.page_content[:1200]) for doc in documents]
        try:
            scores = model.predict(pairs)
            return list(zip(documents, [float(s) for s in scores]))
        except Exception as e:
            logger.error(f"重排序计算失败: {e}")
            return []


# 导出重排序单例
reranker_service = RerankerService()
