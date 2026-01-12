import re
from typing import List
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from app.splitters.base import BaseStructureSplitter

class LegalArticleSplitter(BaseStructureSplitter):
    """法规条款切片器"""
    
    # 匹配: 第一条、第二章、Article 1、Section 2 等
    # 捕获组: (完整匹配, 编号部分)
    PATTERN = re.compile(r'((?:第[一二三四五六七八九十百]+[条章节])|(?:Article\s+\d+)|(?:Section\s+\d+))')
    
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

        # 处理开头
        if matches[0].start() > 0:
            pre = text[:matches[0].start()].strip()
            if pre:
                chunks.append(Document(page_content=pre, metadata=metadata))
        
        for i, match in enumerate(matches):
            start = match.start()
            end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
            
            content = text[start:end].strip()
            article_num = match.group(1).strip()
            
            chunk_metadata = metadata.copy()
            chunk_metadata.update({
                "article_number": article_num,
                "chunk_type": "legal_article"
            })
            
            if len(content) > 1200:
                sub_splitter = RecursiveCharacterTextSplitter(chunk_size=800, chunk_overlap=100)
                sub_docs = sub_splitter.create_documents([content], metadatas=[chunk_metadata])
                chunks.extend(sub_docs)
            else:
                chunks.append(Document(page_content=content, metadata=chunk_metadata))
                
        return chunks
