import requests
import time
import logging
from openai import OpenAI
from app.config import settings

logger = logging.getLogger(__name__)

class LLMChainService:
    def __init__(self):
        self._client = None
        self._config = None
        self._last_config_check = 0
        self._config_cache_ttl = 60  # Cache config for 60 seconds

    def _get_api_config(self):
        """
        Fetch default API config from Java backend.
        """
        now = time.time()
        if self._config and (now - self._last_config_check < self._config_cache_ttl):
            return self._config

        try:
            url = f"{settings.URGS_API_BASE_URL}/api/ai/config/default"
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                config = response.json()
                if config:
                    self._config = config
                    self._last_config_check = now
                    # Re-initialize client if config changed
                    self._client = OpenAI(
                        api_key=config.get("apiKey"),
                        base_url=config.get("endpoint") if config.get("endpoint").endswith("/") else f"{config.get('endpoint')}/"
                    )
                    return self._config
        except Exception as e:
            logger.error(f"Failed to fetch default API config: {e}")

        # Fallback to local settings if backend is unavailable or not configured
        if not self._client:
            self._client = OpenAI(
                api_key=settings.LLM_API_KEY,
                base_url=settings.LLM_API_BASE
            )
        return None

    def _record_usage(self, config_id, model, prompt_tokens, completion_tokens, request_type, success, error_message=None):
        """
        Record token usage to Java backend.
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
            logger.error(f"Failed to record usage: {e}")

    def clean_text_with_llm(self, raw_text: str) -> str:
        """
        Use LLM to clean and format raw text.
        """
        if not raw_text or len(raw_text) < 10:
            return raw_text

        config = self._get_api_config()
        model = config.get("model") if config else settings.LLM_MODEL
        config_id = config.get("id") if config else None

        prompt = (
            "You are a data cleaning assistant. "
            "Please clean the following text extracted from a document. "
            "1. Correct any OCR errors or typos.\n"
            "2. Remove meaningless headers, footers, or page numbers.\n"
            "3. If there is tabular data, format it as a standard Markdown table.\n"
            "4. Do not output any explanation, only the cleaned text.\n\n"
            f"Raw Text:\n{raw_text[:4000]}"
        )

        try:
            response = self._client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": "You are a helpful assistant for text cleaning."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.1
            )
            cleaned = response.choices[0].message.content
            
            # Record success usage
            usage = getattr(response, 'usage', None)
            if usage:
                self._record_usage(config_id, model, usage.prompt_tokens, usage.completion_tokens, "clean", True)
            
            return cleaned.strip()
        except Exception as e:
            logger.error(f"LLM cleaning failed: {e}")
            self._record_usage(config_id, model, 0, 0, "clean", False, str(e))
            return raw_text

    def generate_qa_pairs(self, text: str, num_questions: int = 3) -> list[str]:
        """
        Generate synthetic Q&A pairs/questions for a text chunk.
        """
        if not text or len(text) < 50:
            return []

        config = self._get_api_config()
        model = config.get("model") if config else settings.LLM_MODEL
        config_id = config.get("id") if config else None

        prompt = (
            f"Please generate {num_questions} questions that can be answered by the following text.\n"
            "The questions should be specific and simulate what a user might ask.\n"
            "Output only the questions, one per line.\n\n"
            f"Text:\n{text[:2000]}"
        )

        try:
            response = self._client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": "You are a knowledge engineering assistant."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.3
            )
            content = response.choices[0].message.content
            
            # Record success usage
            usage = getattr(response, 'usage', None)
            if usage:
                self._record_usage(config_id, model, usage.prompt_tokens, usage.completion_tokens, "qa_gen", True)
                
            questions = [line.strip().lstrip("- ").lstrip("1234567890. ") for line in content.splitlines() if line.strip()]
            return questions
        except Exception as e:
            logger.error(f"Q&A generation failed: {e}")
            self._record_usage(config_id, model, 0, 0, "qa_gen", False, str(e))
            return []

    def enrich_knowledge(self, text: str) -> dict:
        """
        Enrich raw text with synthetic questions, reasoning kernel, and tags.
        Returns a dict with: questions (list), reasoning (str), tags (list).
        """
        if not text or len(text) < 50:
            return {"questions": [], "reasoning": "", "tags": []}

        config = self._get_api_config()
        model = config.get("model") if config else settings.LLM_MODEL
        config_id = config.get("id") if config else None

        prompt = (
            "你是一个知识工程助手。请对以下知识片段进行深度加工。\n"
            "任务要求：\n"
            "1. 生成 5 个用户可能会问的问题，且必须能从文中找到答案。\n"
            "2. 提取 '逻辑核'：简述这段知识背后的原理、逻辑或操作流程（为什么和怎么做）。\n"
            "3. 打场景标签：标注适用业务场景（如：故障排查、产品介绍、业务合规等）。\n"
            "输出格式要求（仅输出 JSON）：\n"
            "{\n"
            "  \"questions\": [\"问题1\", \"问题2\", ...],\n"
            "  \"reasoning\": \"逻辑核内容\",\n"
            "  \"tags\": [\"标签1\", \"标签2\"]\n"
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
            
            # Record usage
            usage = getattr(response, 'usage', None)
            if usage:
                self._record_usage(config_id, model, usage.prompt_tokens, usage.completion_tokens, "enrich", True)
                
            return {
                "questions": result.get("questions", []),
                "reasoning": result.get("reasoning", ""),
                "tags": result.get("tags", [])
            }
        except Exception as e:
            logger.error(f"Knowledge enrichment failed: {e}")
            self._record_usage(config_id, model, 0, 0, "enrich", False, str(e))
            return {"questions": [], "reasoning": "", "tags": []}

llm_service = LLMChainService()
