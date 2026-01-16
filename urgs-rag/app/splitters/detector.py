import logging
from typing import Tuple
from app.services.llm_chain import llm_service

logger = logging.getLogger(__name__)

class LLMStructureDetector:
    """基于 LLM 的文档结构检测器"""
    
    PROMPT_TEMPLATE = """你是一个文档结构分析专家。请分析以下文档片段的结构类型。

文档内容（前2000字符）：
---
{text_sample}
---

请判断这是哪种类型的文档，只返回以下类型之一：

1. report_item - 报表填报说明（特征：包含 [序号. 项目名称] 格式，如"[1．现金]"、"[4. 存放同业款项]"）
2. legal_article - 法规条款文档（特征：包含"第X条"、"第X章"等法律条款格式，如"第一条"、"Article 1"）
3. qa_format - FAQ问答文档（特征：包含"Q:"/"A:"或"问:"/"答:"格式，或"问题:"）
4. markdown - Markdown格式文档（特征：包含 # ## ### 标题格式）
5. default - 普通文档（无上述明显结构特征）

返回格式要求：
类型名|置信度(0.0-1.0)|识别依据

注意：
- 置信度必须是 0.0 到 1.0 之间的数字
- 如果不确定，请返回 default|0.5|无法确定结构
- 只返回一行结果，不要包含额外解释

示例返回：
report_item|0.95|发现15个[序号.项目名称]格式的标记
"""

    def __init__(self, sample_size: int = 2000):
        self.sample_size = sample_size
        
    def detect(self, text: str) -> Tuple[str, float]:
        """
        检测文档类型。
        
        Args:
            text: 文档全文
            
        Returns:
            Tuple[str, float]: (类型名称, 置信度)
        """
        if not text:
            return "default", 0.0
            
        try:
            # 采样文档头部
            sample = text[:self.sample_size]
            prompt = self.PROMPT_TEMPLATE.format(text_sample=sample)
            
            # 使用 LLM 进行判断 (复用 llm_service 的 run 方法或 chat 接口，这里假设用 chat)
            # 注意：需确保 config 中已配置 LLM
            response = llm_service.chat(prompt)
            
            # 解析响应 "type|confidence|reason"
            response = response.strip()
            parts = response.split('|')
            
            doc_type = parts[0].strip()
            confidence = 0.5
            
            if len(parts) >= 2:
                try:
                    confidence = float(parts[1].strip())
                except ValueError:
                    confidence = 0.5
                    
            logger.info(f"[SmartSplitter] Detect result: {doc_type} (conf={confidence}) | Reason: {parts[2] if len(parts)>2 else 'None'}")
            
            valid_types = {"report_item", "legal_article", "qa_format", "markdown", "default"}
            if doc_type not in valid_types:
                logger.warning(f"[SmartSplitter] Unknown type detected: {doc_type}, fallback to default")
                return "default", 0.0
                
            return doc_type, confidence
            
        except Exception as e:
            logger.error(f"[SmartSplitter] Detection failed: {e}")
            return "default", 0.0
