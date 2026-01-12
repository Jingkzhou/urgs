import logging
from typing import List, Dict
from langchain_core.documents import Document

from app.config import settings
from app.splitters.detector import LLMStructureDetector
from app.splitters.base import BaseStructureSplitter
from app.splitters.default_splitter import DefaultSplitter
from app.splitters.report_item_splitter import ReportItemSplitter
from app.splitters.legal_article_splitter import LegalArticleSplitter
from app.splitters.qa_splitter import QASplitter
from app.splitters.markdown_splitter import MarkdownSplitter

logger = logging.getLogger(__name__)

class SmartSplitter:
    """智能文档切片器 - 自动检测结构并选择最优切片策略"""
    
    def __init__(self):
        self.detector = LLMStructureDetector()
        
        # 注册切片器
        self.splitters: Dict[str, BaseStructureSplitter] = {
            "report_item": ReportItemSplitter(),
            "legal_article": LegalArticleSplitter(),
            "qa_format": QASplitter(),
            "markdown": MarkdownSplitter(),
            "default": DefaultSplitter()
        }
    
    def split_documents(self, documents: List[Document]) -> List[Document]:
        """
        对文档列表进行智能切分。
        
        Args:
            documents: 原始文档列表
        
        Returns:
            List[Document]: 切分后的文档片段列表
        """
        all_chunks = []
        
        for doc in documents:
            # 如果配置关闭了智能切片，直接使用默认
            if not getattr(settings, "SMART_SPLITTER_ENABLED", True):
                all_chunks.extend(self.splitters["default"].split(doc))
                continue
                
            text = doc.page_content
            
            # 1. 结构检测
            doc_type = "default"
            confidence = 0.0
            
            # 优先使用 LLM 检测 (如果配置启用)
            if getattr(settings, "SMART_SPLITTER_LLM_DETECT", True):
                doc_type, confidence = self.detector.detect(text)
            
            # 可选：如果 LLM 检测置信度低，尝试简单的规则校验（此处简化，直接信任 LLM 或回退）
            if confidence < getattr(settings, "SMART_SPLITTER_MIN_CONFIDENCE", 0.6) and doc_type != "default":
                logger.info(f"[SmartSplitter] Confidence {confidence} too low for {doc_type}, fallback to default")
                doc_type = "default"
                
            logger.info(f"[SmartSplitter] Using strategy '{doc_type}' for document (len={len(text)})")
            
            # 2. 路由策略
            splitter = self.splitters.get(doc_type, self.splitters["default"])
            
            # 3. 执行切分
            try:
                chunks = splitter.split(doc)
                
                # 添加处理用的策略元数据，便于调试
                for chunk in chunks:
                    chunk.metadata["splitter_strategy"] = doc_type
                    
                all_chunks.extend(chunks)
                
            except Exception as e:
                logger.error(f"[SmartSplitter] Error splitting with {doc_type}: {e}, fallback to default")
                # 异常回退
                chunks = self.splitters["default"].split(doc)
                all_chunks.extend(chunks)
                
        return all_chunks

# 单例实例
smart_splitter = SmartSplitter()
