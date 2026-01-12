from typing import List
from langchain_core.documents import Document
from langchain_text_splitters import MarkdownHeaderTextSplitter, RecursiveCharacterTextSplitter
from app.splitters.base import BaseStructureSplitter

class MarkdownSplitter(BaseStructureSplitter):
    """Markdown 文档切片器"""
    
    def can_handle(self, text: str) -> bool:
        # 简单判断是否包含多个 # 标题
        return text.count("\n#") >= 3
    
    def split(self, doc: Document) -> List[Document]:
        text = doc.page_content
        metadata = doc.metadata.copy()
        
        headers_to_split_on = [
            ("#", "h1"),
            ("##", "h2"),
            ("###", "h3"),
        ]
        
        # 1. 结构化切分
        markdown_splitter = MarkdownHeaderTextSplitter(headers_to_split_on=headers_to_split_on)
        md_chunks = markdown_splitter.split_text(text)
        
        final_chunks = []
        
        # 2. 对每个区块进行二次切分（如果太长）
        recursive_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
        
        for chunk in md_chunks:
            # 合并元数据
            chunk_meta = metadata.copy()
            chunk_meta.update(chunk.metadata)
            chunk_meta["chunk_type"] = "markdown_section"
            
            # 二次切分
            if len(chunk.page_content) > 1200:
                sub_chunks = recursive_splitter.create_documents([chunk.page_content], metadatas=[chunk_meta])
                final_chunks.extend(sub_chunks)
            else:
                chunk.metadata = chunk_meta
                final_chunks.append(chunk)

        if not final_chunks:
             # Fallback
            return recursive_splitter.split_documents([doc])
            
        return final_chunks
