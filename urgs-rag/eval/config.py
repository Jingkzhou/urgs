"""
评估模块配置。

所有配置项均可通过环境变量覆盖。
"""

import os
from pathlib import Path

# 评估数据目录
EVAL_DIR = Path(__file__).resolve().parent
DATA_DIR = EVAL_DIR / "data"

# 服务端点
AGENT_BASE_URL = os.getenv("EVAL_AGENT_URL", "http://localhost:8000")
RAG_BASE_URL = os.getenv("EVAL_RAG_URL", "http://localhost:8001")

# 评估用 LLM 配置（可独立于生产 LLM，推荐用更强模型做评判）
EVAL_LLM_MODEL = os.getenv("EVAL_LLM_MODEL", "qwen3")
EVAL_LLM_BASE_URL = os.getenv("EVAL_LLM_BASE_URL", "http://25.64.32.35:18085/v1")
EVAL_LLM_API_KEY = os.getenv("EVAL_LLM_API_KEY", "sk-xxx")

# 数据集路径
DEFAULT_EVAL_SET_PATH = str(EVAL_DIR / "eval_set.json")
DEFAULT_DATASET_PATH = str(DATA_DIR / "eval_dataset.json")
DEFAULT_RESULTS_PATH = str(DATA_DIR / "eval_results.json")

# 数据集生成参数
DEFAULT_NUM_QUESTIONS = 3
DEFAULT_MAX_CHUNKS = 50
