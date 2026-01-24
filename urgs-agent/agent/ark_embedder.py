"""
火山引擎 Ark 多模态 Embedding 适配器

将 Doubao-embedding-vision 的 multimodal_embeddings API
适配为 CrewAI/ChromaDB 兼容的 EmbeddingFunction 接口
"""

import numpy as np
from typing import List, Any, cast
from chromadb.utils.embedding_functions import EmbeddingFunction
from chromadb.api.types import Documents
from volcenginesdkarkruntime import Ark


class ArkMultimodalEmbeddingFunction(EmbeddingFunction[Documents]):
    """
    火山引擎多模态 Embedding 适配器

    使用 volcenginesdkarkruntime 的 multimodal_embeddings.create() 接口
    实现 ChromaDB EmbeddingFunction 接口，可直接用于 CrewAI
    """

    def __init__(self, api_key: str, model: str, **kwargs):
        """
        初始化适配器

        Args:
            api_key: 火山引擎 API Key
            model: 模型接入点 ID (ep-xxxxxx)
            **kwargs: 其他兼容参数
        """
        self._client = Ark(api_key=api_key)
        self._model = model
        self._name = "ark_multimodal"

    @property
    def name(self) -> str:
        return self._name

    def _embed_text(self, text: str) -> List[float]:
        """对单条文本进行嵌入"""
        response = self._client.multimodal_embeddings.create(
            model=self._model, input=[{"type": "text", "text": text}]
        )
        return response.data.embedding

    def __call__(self, input: Documents) -> List[np.ndarray]:
        """
        ChromaDB EmbeddingFunction 接口实现

        Args:
            input: 文档列表

        Returns:
            嵌入向量列表 (numpy 数组)
        """
        embeddings = []
        for text in input:
            embedding = self._embed_text(text)
            embeddings.append(np.array(embedding, dtype=np.float32))
        return embeddings

    def embed_query(self, query: str) -> np.ndarray:
        """
        对查询文本进行嵌入 (CrewAI 可能调用此方法)

        Args:
            query: 查询文本

        Returns:
            嵌入向量
        """
        embedding = self._embed_text(query)
        return np.array(embedding, dtype=np.float32)


def create_ark_embedder(
    api_key: str, model: str, **kwargs
) -> ArkMultimodalEmbeddingFunction:
    """
    工厂函数：创建 Ark Embedder 实例

    Args:
        api_key: 火山引擎 API Key
        model: 模型接入点 ID
        **kwargs: 其他配置参数（兼容性）

    Returns:
        ArkMultimodalEmbeddingFunction 实例
    """
    return ArkMultimodalEmbeddingFunction(api_key=api_key, model=model)
