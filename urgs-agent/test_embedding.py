#!/usr/bin/env python3
"""
直接测试火山引擎 Embedding API
用于排查 CrewAI 初始化失败问题
"""

import os
import sys
from pathlib import Path

# 加载 .env
parent_env = Path(__file__).parent.parent / ".env"
if parent_env.exists():
    from dotenv import load_dotenv

    load_dotenv(parent_env)
    print(f"✅ 已加载配置: {parent_env}")

# 读取配置
api_key = os.getenv("Embeddings_API_KEY", "")
base_url = os.getenv("Embeddings_BASE_URL", "")
model_name = os.getenv("Embeddings_MODEL_NAME", "")

print(f"\n📋 当前配置:")
print(f"  - API Key: {'***' + api_key[-8:] if len(api_key) > 8 else '(未设置)'}")
print(f"  - Base URL: {base_url or '(未设置)'}")
print(f"  - Model: {model_name or '(未设置)'}")

if not all([api_key, base_url, model_name]):
    print("\n❌ 配置不完整，请检查 .env 文件")
    sys.exit(1)

# 测试 API 调用
print(f"\n🔄 正在测试 Embedding API...")

try:
    from openai import OpenAI

    client = OpenAI(
        api_key=api_key,
        base_url=base_url,
    )

    response = client.embeddings.create(
        model=model_name,
        input="测试文本",
    )

    print(f"\n✅ API 调用成功!")
    print(f"  - 返回向量维度: {len(response.data[0].embedding)}")
    print(f"  - 模型: {response.model}")
    print(f"  - Token 使用: {response.usage.total_tokens if response.usage else 'N/A'}")

except Exception as e:
    print(f"\n❌ API 调用失败!")
    print(f"  - 错误类型: {type(e).__name__}")
    print(f"  - 错误信息: {e}")

    # 如果是 502 错误，给出建议
    if "502" in str(e):
        print(f"\n💡 502 错误通常意味着:")
        print(f"   1. 模型名称 '{model_name}' 可能不正确")
        print(f"   2. 火山引擎方舟需要使用接入点 ID (ep-xxxxxx) 而非模型名")
        print(
            f"   3. 请登录 https://console.volcengine.com/ark 检查您的 Embedding 模型接入点"
        )
