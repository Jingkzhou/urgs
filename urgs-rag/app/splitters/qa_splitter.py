import re
from typing import List
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from app.splitters.base import BaseStructureSplitter

class QASplitter(BaseStructureSplitter):
    """FAQ/问答文档切片器"""
    
    # 匹配: Q:, A:, 问:, 答:, Q1., 问题1: 等
    PATTERN = re.compile(r'((?:Q\d*[:：.])|(?:问\d*[:：.])|(?:问题\s*\d*[:：]))')
    
    def can_handle(self, text: str) -> bool:
        matches = self.PATTERN.findall(text)
        return len(matches) >= 3
    
    def split(self, doc: Document) -> List[Document]:
        text = doc.page_content
        metadata = doc.metadata.copy()
        chunks = []
        
        matches = list(self.PATTERN.finditer(text))
        
        if not matches:
             # Fallback
            fallback = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
            return fallback.split_documents([doc])
            
        for i, match in enumerate(matches):
            start = match.start()
            end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
            
            content = text[start:end].strip()
            
            chunk_metadata = metadata.copy()
            chunk_metadata.update({
                "chunk_type": "qa_pair"
            })
            
            # 尝试分离 Question 和 Answer (简单启发式)
            # 假设 Question 很短，Answer 较长
            lines = content.split('\n', 1)
            if len(lines) > 1:
                chunk_metadata["question_preview"] = lines[0].strip()[:50]
            
            chunks.append(Document(page_content=content, metadata=chunk_metadata))
                
        return chunks
