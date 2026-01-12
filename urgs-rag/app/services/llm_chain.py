import requests
import time
import logging
from openai import OpenAI
from app.config import settings

logger = logging.getLogger(__name__)

class LLMChainService:
    """
    LLM 链路管理服务。
    
    统一屏蔽不同 LLM 厂商的 API 差异，提供文本清理、QA 对生成、
    知识增强以及结构化结果生成等核心能力。
    支持从 Java 后端动态拉取 API 配置并记录 Token 使用情况。
    """
    def __init__(self):
        self._client = None          # OpenAI 兼容客户端实例
        self._config = None          # 当前使用的配置缓存
        self._last_config_check = 0  # 上次从后端同步配置的时间
        self._config_cache_ttl = 60  # 配置缓存有效期 (秒)

    @property
    def client(self):
        """公开的 client 属性，确保在访问前已初始化。"""
        if self._client is None:
            self._get_api_config()  # 触发初始化
        return self._client

    @property
    def model_name(self):
        """公开的 model_name 属性，返回当前配置的模型名称。"""
        if self._config is None:
            self._get_api_config()  # 触发初始化
        return self._config.get("model") if self._config else settings.LLM_MODEL

    def _get_api_config(self):
        """
        从 Java 后端网关动态获取推荐的 AI 配置。
        实现热更新：当后端修改 API Key 或模型时，Python 端自动同步。
        """
        now = time.time()
        if self._config and (now - self._last_config_check < self._config_cache_ttl):
            return self._config

        try:
            # 访问管理后台暴露的默认配置接口
            url = f"{settings.URGS_API_BASE_URL}/api/ai/config/default"
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                config = response.json()
                if config:
                    self._config = config
                    self._last_config_check = now
                    # 配置变更时，重新初始化底层客户端
                    self._client = OpenAI(
                        api_key=config.get("apiKey"),
                        base_url=config.get("endpoint") if config.get("endpoint").endswith("/") else f"{config.get('endpoint')}/"
                    )
                    return self._config
        except Exception as e:
            logger.error(f"从后端获取 API 配置失败: {e}")

        # 若后端不可用或未配置，则退回到本地配置文件的默认设置
        if not self._client:
            self._client = OpenAI(
                api_key=settings.LLM_API_KEY,
                base_url=settings.LLM_API_BASE
            )
        return None

    def _record_usage(self, config_id, model, prompt_tokens, completion_tokens, request_type, success, error_message=None):
        """
        将 Token 消耗情况上报至 Java 后端，用于审计、计费或统计。
        """
        try:
            url = f"{settings.URGS_API_BASE_URL}/api/ai/usage/record"
            payload = {
                "configId": config_id,
                "model": model,
                "promptTokens": prompt_tokens,
                "completionTokens": completion_tokens,
                "requestType": f"rag_{request_type}",
                "success": success,
                "errorMessage": error_message
            }
            requests.post(url, json=payload, timeout=5)
        except Exception as e:
            logger.error(f"上报 Token 使用情况失败: {e}")

    def clean_text_with_llm(self, raw_text: str) -> str:
        """
        利用 LLM 对原始文本进行清理。
        
        主要任务：纠正 OCR 错误、去除无意义的页码/页眉、将散乱数据转为 Markdown 表格。
        """
        if not raw_text or len(raw_text) < 10:
            return raw_text

        config = self._get_api_config()
        model = config.get("model") if config else settings.LLM_MODEL
        config_id = config.get("id") if config else None

        prompt = (
            "你是一个数据清理助手。请清理以下从文档中提取的文本。\n"
            "1. 纠正任何 OCR 错误或拼写错误。\n"
            "2. 删除无意义的页眉、页脚或页码。\n"
            "3. 如果存在表格数据，请将其格式化为标准的 Markdown 表格。\n"
            "4. 不要输出任何解释，直接返回清理后的文本。\n\n"
            f"原始文本：\n{raw_text[:4000]}"
        )

        try:
            response = self._client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": "你是一个专业的文本清理助手。"},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.1
            )
            cleaned = response.choices[0].message.content
            
            # 记录 Token 消耗
            usage = getattr(response, 'usage', None)
            if usage:
                self._record_usage(config_id, model, usage.prompt_tokens, usage.completion_tokens, "clean", True)
            
            return cleaned.strip()
        except Exception as e:
            logger.error(f"LLM 文本清理失败: {e}")
            self._record_usage(config_id, model, 0, 0, "clean", False, str(e))
            return raw_text

    def generate_qa_pairs(self, text: str, num_questions: int = 3) -> list[str]:
        """
        基于文本片段生成模拟用户问题的列表。
        用于后续的“假设性提问”增强检索效果。
        """
        if not text or len(text) < 50:
            return []

        config = self._get_api_config()
        model = config.get("model") if config else settings.LLM_MODEL
        config_id = config.get("id") if config else None

        prompt = (
            f"请根据以下文本生成 {num_questions} 个可以被该文本回答的问题。\n"
            "这些问题应该是具体的，模拟真实用户可能会问的内容。\n"
            "仅输出问题，每行一个。\n\n"
            f"文本：\n{text[:2000]}"
        )

        try:
            response = self._client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": "你是一个知识工程助手。"},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3
            )
            content = response.choices[0].message.content
            
            usage = getattr(response, 'usage', None)
            if usage:
                self._record_usage(config_id, model, usage.prompt_tokens, usage.completion_tokens, "qa_gen", True)
                
            # 清理回答中的特殊前缀符号
            questions = [line.strip().lstrip("- ").lstrip("1234567890. ") for line in content.splitlines() if line.strip()]
            return questions
        except Exception as e:
            logger.error(f"QA 对生成失败: {e}")
            self._record_usage(config_id, model, 0, 0, "qa_gen", False, str(e))
            return []

    def enrich_knowledge(self, text: str) -> dict:
        """
        【全息增强】对原始文本进行深度加工。
        
        加工内容包括：
        - 模拟问题 (Questions)
        - 逻辑核/思考范式 (Reasoning Kernel)
        - 摘要 (Summary)
        - 场景标签 (Tags)
        - 关键词 (Keywords)
        """
        # 仅跳过完全空白的文本
        if not text or not text.strip():
            return {"questions": [], "reasoning": "", "tags": [], "summary": "", "keywords": []}

        config = self._get_api_config()
        model = config.get("model") if config else settings.LLM_MODEL
        config_id = config.get("id") if config else None

        prompt = (
            "你是一个知识工程助手。请对以下知识片段进行深度加工。\n"
            "任务要求：\n"
            "1. 生成 5 个用户可能会问的问题，且必须能从文中找到答案。\n"
            "2. 提取 '逻辑核'：简述这段知识背后的原理、逻辑或操作流程（为什么和怎么做）。\n"
            "3. 打场景标签：标注适用业务场景（如：故障排查、产品介绍、业务合规等）。\n"
            "4. 生成 1 段摘要（80-150 字）。\n"
            "5. 提取 5-10 个关键词或实体（名词短语）。\n"
            "输出格式要求（仅输出 JSON）：\n"
            "{\n"
            "  \"questions\": [\"问题1\", \"问题2\", ...],\n"
            "  \"reasoning\": \"逻辑核内容\",\n"
            "  \"tags\": [\"标签1\", \"标签2\"],\n"
            "  \"summary\": \"摘要内容\",\n"
            "  \"keywords\": [\"关键词1\", \"关键词2\"]\n"
            "}\n\n"
            f"片段内容：\n{text[:3000]}"
        )

        try:
            response = self._client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": "You are a professional knowledge engineer. Output ONLY valid JSON."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3,
                response_format={"type": "json_object"}
            )
            import json
            content = response.choices[0].message.content
            result = json.loads(content)
            
            usage = getattr(response, 'usage', None)
            if usage:
                self._record_usage(config_id, model, usage.prompt_tokens, usage.completion_tokens, "enrich", True)
                
            return {
                "questions": result.get("questions", []),
                "reasoning": result.get("reasoning", ""),
                "tags": result.get("tags", []),
                "summary": result.get("summary", ""),
                "keywords": result.get("keywords", [])
            }
        except Exception as e:
            logger.error(f"全息知识增强失败: {e}")
            self._record_usage(config_id, model, 0, 0, "enrich", False, str(e))
            return {"questions": [], "reasoning": "", "tags": [], "summary": "", "keywords": []}

    def analyze_query_intent(self, query: str) -> dict:
        """
        分析用户查询意图，进行分类、实体提取和检索重写。
        
        Returns:
            dict: {
                "intent": "WHAT|HOW|COMPARE|TROUBLESHOOT|GENERAL",
                "entities": ["entity1", ...],
                "rewritten_query": "optimized search query",
                "keywords": ["kw1", "kw2"]
            }
        """
        if not query:
            return {"intent": "GENERAL", "entities": [], "rewritten_query": "", "keywords": []}

        config = self._get_api_config()
        model = config.get("model") if config else settings.LLM_MODEL
        config_id = config.get("id") if config else None

        prompt = (
            "你是一个即搜索意图分析专家。请分析用户的查询语句。\n"
            "任务：\n"
            "1. 判定意图类型 (Intent Type)：\n"
            "   - WHAT_IS: 定义、概念解释 (e.g. '什么是RAG')\n"
            "   - HOW_TO: 操作步骤、流程 (e.g. '怎么部署', '如何申请')\n"
            "   - COMPARE: 对比、区别 (e.g. 'A和B的区别')\n"
            "   - TROUBLESHOOT: 报错、故障排查 (e.g. '启动失败', '报错500')\n"
            "   - GENERAL: 其他通用问题\n"
            "2. 提取关键实体 (Entities)：产品名、技术术语、报错代码等。\n"
            "3. 提取关键词 (Keywords)：用于倒排索引的关键词。\n"
            "4. 改写查询 (Rewritten Query)：生成一个更适合搜索引擎的 Query，去除口语化词汇，突出实体和意图。\n"
            "\n"
            "输出仅 JSON 格式：\n"
            "{\n"
            "  \"intent\": \"类型\",\n"
            "  \"entities\": [\"实体1\"],\n"
            "  \"keywords\": [\"关键词1\"],\n"
            "  \"rewritten_query\": \"改写后的Query\"\n"
            "}\n\n"
            f"用户查询：{query}"
        )

        try:
            response = self._client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": "You are a search intent analyzer. Output valid JSON."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.1,
                response_format={"type": "json_object"}
            )
            import json
            content = response.choices[0].message.content
            result = json.loads(content)
            
            usage = getattr(response, 'usage', None)
            if usage:
                self._record_usage(config_id, model, usage.prompt_tokens, usage.completion_tokens, "intent", True)
                
            return {
                "intent": result.get("intent", "GENERAL"),
                "entities": result.get("entities", []),
                "rewritten_query": result.get("rewritten_query", query),
                "keywords": result.get("keywords", [])
            }
        except Exception as e:
            logger.error(f"意图分析失败: {e}")
            self._record_usage(config_id, model, 0, 0, "intent", False, str(e))
            return {"intent": "GENERAL", "entities": [], "rewritten_query": query, "keywords": []}

    def generate_structured_answer(
        self,
        query: str,
        facts: list[str],
        reasoning_templates: list[str],
        tags: list[str],
        sources: list[dict],
        min_confidence: float
    ) -> dict:
        """
        生成最终的结构化回答，并包含证据绑定。
        
        Args:
            query: 用户提问
            facts: 检索到的核心事实
            reasoning_templates: 检索到的逻辑核模版
            tags: 相关标签
            sources: 源文档详细信息
            min_confidence: 最低置信度基准

        Returns:
            dict: 符合指定 Schema 的结构化响应
        """
        config = self._get_api_config()
        model = config.get("model") if config else settings.LLM_MODEL
        config_id = config.get("id") if config else None

        # 拼接 Prompt
        facts_str = "\n".join([f"- {f}" for f in facts]) or "无直接事实参考"
        templates_str = "\n".join([f"- {t}" for t in reasoning_templates]) or "无逻辑模板参考"
        tags_str = ", ".join(tags) or "通用场景"
        sources_str = "\n".join([
            f"- source_id: {s.get('source_id')} | score: {s.get('score'):.3f} | snippet: {s.get('snippet')}"
            for s in sources
        ]) or "无可用证据"

        prompt = (
            "你是一个专业的监管问答助手。请严格基于已给证据回答，避免编造。\n"
            "若证据不足，请输出澄清问题与方向性建议。\n"
            "输出要求：仅输出 JSON，字段严格遵循 schema。\n\n"
            "【已知事实】\n"
            f"{facts_str}\n\n"
            "【思考范式/逻辑核】\n"
            f"{templates_str}\n\n"
            "【场景标签】\n"
            f"{tags_str}\n\n"
            "【证据列表】\n"
            f"{sources_str}\n\n"
            f"【用户问题】{query}\n\n"
            "Schema:\n"
            "{\n"
            "  \"conclusion\": \"简明结论\",\n"
            "  \"evidence\": [\n"
            "    {\"source_id\": \"\", \"quote\": \"\", \"reason\": \"\"}\n"
            "  ],\n"
            "  \"suggestions\": [\n"
            "    {\"action\": \"\", \"reason\": \"\", \"source_id\": \"\", \"type\": \"evidence|experience\"}\n"
            "  ],\n"
            "  \"risks\": [\"\"],\n"
            "  \"boundary\": \"适用边界\",\n"
            "  \"clarifying_questions\": [\"\"],\n"
            f"  \"confidence\": {min_confidence}\n"
            "}\n"
        )

        try:
            response = self._client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": "你是专业的合规与监管知识顾问，仅输出 JSON。"},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.2,
                response_format={"type": "json_object"}
            )
            import json
            content = response.choices[0].message.content
            result = json.loads(content)

            usage = getattr(response, 'usage', None)
            if usage:
                self._record_usage(config_id, model, usage.prompt_tokens, usage.completion_tokens, "answer", True)

            return result
        except Exception as e:
            logger.error(f"生成结构化回答失败: {e}")
            self._record_usage(config_id, model, 0, 0, "answer", False, str(e))
            return {
                "conclusion": "当前证据不足，无法给出确定结论。",
                "evidence": [],
                "suggestions": [],
                "risks": [],
                "boundary": "",
                "clarifying_questions": ["请提供更具体的业务场景或报表口径信息。"],
                "confidence": min_confidence
            }

# 导出 LLM 服务实例
llm_service = LLMChainService()
