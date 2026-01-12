import re
from typing import List
from langchain_core.documents import Document
from langchain_text_splitters import RecursiveCharacterTextSplitter
from app.splitters.base import BaseStructureSplitter

class ReportItemSplitter(BaseStructureSplitter):
    """报表填报说明切片器"""
    
    # 匹配 [数字. 项目名称] 或 [数字．项目名称] 模式
    # 兼容: [1. 现金], [4．存放同业款项], [13.2 长期借款]
    PATTERN = re.compile(r'\[(\d+(?:\.\d+)?)[.．\s]+([^\]]+)\]')
    
    def can_handle(self, text: str) -> bool:
        # 简单规则校验：至少包含 3 个项目标记
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
            
        # 1. 处理第一个项目之前的内容 (Pre-content)
        if matches[0].start() > 0:
            pre_content = text[:matches[0].start()].strip()
            if pre_content:
                pre_meta = metadata.copy()
                pre_meta.update({"chunk_type": "report_preface"})
                chunks.append(Document(page_content=pre_content, metadata=pre_meta))
        
        # 2. 处理每个项目
        for i, match in enumerate(matches):
            start = match.start()
            # 下一个项目的开始位置作为当前项目的结束位置
            end = matches[i + 1].start() if i + 1 < len(matches) else len(text)
            
            content = text[start:end].strip()
            item_number = match.group(1).strip()
            item_name = match.group(2).strip()
            
            chunk_metadata = metadata.copy()
            chunk_metadata.update({
                "item_number": item_number,
                "item_name": item_name,
                "chunk_type": "report_item"
            })
            
            # 如果内容过长，内部再进行递归切分，但保持 metadata
            if len(content) > 1500:
                sub_splitter = RecursiveCharacterTextSplitter(chunk_size=1000, chunk_overlap=200)
                sub_docs = sub_splitter.create_documents([content], metadatas=[chunk_metadata])
                chunks.extend(sub_docs)
            else:
                chunks.append(Document(page_content=content, metadata=chunk_metadata))
                
        return chunks
