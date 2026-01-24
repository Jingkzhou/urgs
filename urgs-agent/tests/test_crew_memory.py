#!/usr/bin/env python3
"""
测试 CrewAI 自定义 Embedder 配置
验证火山引擎多模态 Embedding API 是否与 CrewAI 兼容
"""

import os
import sys
from pathlib import Path

# 加载 .env (从 tests/ 向上到 urgs-agent/ 再向上到 urgs/)
parent_env = Path(__file__).parent.parent.parent / ".env"
if parent_env.exists():
    from dotenv import load_dotenv

    load_dotenv(parent_env)
    print(f"✅ 已加载配置: {parent_env}")
else:
    print(f"⚠️  未找到 .env 文件: {parent_env}")

# 从配置读取
api_key = os.getenv("Embeddings_API_KEY", "")
model_name = os.getenv("Embeddings_MODEL_NAME", "")

print(f"\n📋 Embedder 配置:")
print(f"  - API Key: {'***' + api_key[-8:] if len(api_key) > 8 else '(未设置)'}")
print(f"  - Model: {model_name or '(未设置)'}")

if not all([api_key, model_name]):
    print("\n❌ 配置不完整，请检查 .env 文件")
    sys.exit(1)

# 测试 1: 直接测试 ArkMultimodalEmbeddingFunction
print(f"\n🔄 测试 1: ArkMultimodalEmbeddingFunction 适配器...")
try:
    # 将 urgs-agent 添加到 path
    agent_path = Path(__file__).parent.parent
    sys.path.insert(0, str(agent_path))

    from agent.ark_embedder import ArkMultimodalEmbeddingFunction

    embedder = ArkMultimodalEmbeddingFunction(
        api_key=api_key,
        model=model_name,
    )

    # 测试 __call__ 方法 (ChromaDB 接口)
    test_docs = ["测试文本1", "测试文本2"]
    embeddings = embedder(test_docs)

    print(f"✅ __call__ 方法成功!")
    print(f"  - 文档数量: {len(embeddings)}")
    print(f"  - 向量维度: {embeddings[0].shape}")
    print(f"  - 数据类型: {embeddings[0].dtype}")

    # 测试 embed_query 方法
    query_embedding = embedder.embed_query("查询文本")
    print(f"✅ embed_query 方法成功!")
    print(f"  - 向量维度: {query_embedding.shape}")

except Exception as e:
    print(f"❌ 适配器测试失败: {type(e).__name__}: {e}")
    import traceback

    traceback.print_exc()
    sys.exit(1)

# 测试 2: 验证 CrewAI 可以初始化
print(f"\n🔄 测试 2: CrewAI Crew 初始化 (使用自定义 embedder)...")
try:
    from crewai import Crew, Agent, Task

    # 创建简单的测试 Agent 和 Task
    test_agent = Agent(
        role="测试助手", goal="验证 embedder 配置", backstory="我是一个用于测试的助手"
    )

    test_task = Task(
        description="简单测试任务", expected_output="测试完成", agent=test_agent
    )

    # 使用自定义 embedder
    crew = Crew(
        agents=[test_agent],
        tasks=[test_task],
        memory=True,
        embedder=embedder,  # 直接传入自定义 embedder 实例
        verbose=False,
    )

    print(f"✅ CrewAI Crew 初始化成功!")
    print(f"  - Memory 已启用")
    print(f"  - Embedder: ArkMultimodalEmbeddingFunction")

except Exception as e:
    print(f"❌ CrewAI 初始化失败: {type(e).__name__}: {e}")
    import traceback

    traceback.print_exc()
    sys.exit(1)

print(f"\n🎉 所有测试通过! 火山引擎多模态 Embedding 配置正确。")
