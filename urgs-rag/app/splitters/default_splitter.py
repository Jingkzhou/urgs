from typing import List
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from app.splitters.base import BaseStructureSplitter

class DefaultSplitter(BaseStructureSplitter):
    """默认切片器 - 使用 LangChain 的递归字符切片"""
    
    def __init__(self, chunk_size: int = 1000, chunk_overlap: int = 200):
        self.chunk_size = chunk_size
        self.chunk_overlap = chunk_overlap
        self.splitter = RecursiveCharacterTextSplitter(
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap,
            separators=["\n\n", "\n", " ", ""],
        )
    
    def can_handle(self, text: str) -> bool:
        return True  # 总是可以处理
    
    def split(self, doc: Document) -> List[Document]:
        """执行切片"""
        chunks = self.splitter.split_documents([doc])
        # 统一添加 metadata
        for chunk in chunks:
            chunk.metadata["chunk_type"] = "default"
        return chunks
