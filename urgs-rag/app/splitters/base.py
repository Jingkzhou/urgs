from abc import ABC, abstractmethod
from typing import List
from langchain_core.documents import Document

class BaseStructureSplitter(ABC):
    """文档结构切片器基类"""
    
    @abstractmethod
    def can_handle(self, text: str) -> bool:
        """
        判断该切片器是否能处理给定的文本。
        虽然主要依赖 LLMDetector 进行路由，但每个切片器
        保留此方法用于简单的规则校验或兜底逻辑。
        """
        pass
    
    @abstractmethod
    def split(self, doc: Document) -> List[Document]:
        """
        执行切片逻辑。
        必须保留原始 metadata，并添加结构化元数据。
        """
        pass
