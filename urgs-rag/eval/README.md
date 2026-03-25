# URGS RAG 评估模块

自动化质量评估工具，用于评测 RAG 检索质量和 Agent 问答质量。

## 目录结构

```
eval/
├── config.py              # 配置（端点 URL、LLM、路径），支持环境变量覆盖
├── generate_dataset.py    # 从知识库自动生成评估数据集
├── run_evaluation.py      # Ragas 离线评估主脚本
├── report.py              # 评估报告生成（JSON + 终端摘要）
├── eval_runner.py         # 检索评估（Hit@K / MRR / 覆盖率）
├── ragas_runner.py        # 旧版 Ragas 评估（兼容保留）
├── eval_set.json          # 基础评测集（60 条定义/命名类）
└── data/                  # 生成的数据集和评估结果
    ├── eval_dataset.json  # (生成) 测试数据集
    └── eval_results.json  # (生成) 评估结果报告
```

## 快速开始

### 前置条件

- 已安装 Python 依赖（ragas、langchain-openai、httpx 等）
- 知识库文档已向量化（ChromaDB + ShelveDocStore 中有数据）
- urgs-rag 服务运行中（默认 `http://localhost:8001`）
- urgs-agent 服务运行中（默认 `http://localhost:8000`）—— 仅 agent 模式需要

### 第一步：生成评估数据集

从已有知识库文档自动生成高质量 Q&A 对：

```bash
cd urgs-rag

# 小量测试（5 个文档片段，每个 3 个问题 ≈ 15 条样本）
python -m eval.generate_dataset --max-chunks 5

# 完整生成（50 个片段 ≈ 150 条样本）
python -m eval.generate_dataset --max-chunks 50 --num-questions 3

# 指定知识库集合
python -m eval.generate_dataset --collection urgs_knowledge_base --max-chunks 30

# 自定义输出路径
python -m eval.generate_dataset --output eval/data/my_dataset.json
```

**参数说明：**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--max-chunks` | 50 | 最大处理文档片段数 |
| `--num-questions` | 3 | 每个片段生成的问题数 |
| `--output` | `eval/data/eval_dataset.json` | 输出文件路径 |
| `--collection` | 全部 | 指定知识库集合名称 |
| `--no-shuffle` | 否 | 不随机打乱文档顺序 |

**输出格式：**

```json
[
  {
    "question": "G01表的填报范围是什么？",
    "ground_truth": "G01表适用于...",
    "source_document": "G01_填报说明.pdf",
    "contexts": ["原始文档片段内容..."]
  }
]
```

### 第二步：运行 Ragas 评估

```bash
cd urgs-rag

# 评估模式 1：仅测 RAG（调用 urgs-rag /api/v1/query）
python -m eval.run_evaluation --mode rag

# 评估模式 2：测 Agent（调用 urgs-agent /chat + urgs-rag 获取 contexts）
python -m eval.run_evaluation --mode agent

# 使用已有的 eval_set.json 评估
python -m eval.run_evaluation --dataset eval/eval_set.json --mode rag

# 自定义端点和输出
python -m eval.run_evaluation \
  --dataset eval/data/eval_dataset.json \
  --agent-url http://localhost:8000 \
  --rag-url http://localhost:8001 \
  --output eval/data/eval_results.json \
  --mode agent
```

**参数说明：**

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--dataset` | `eval/data/eval_dataset.json` | 测试数据集路径 |
| `--mode` | `agent` | 评估模式：`agent` / `rag` / `both` |
| `--agent-url` | `http://localhost:8000` | urgs-agent 端点 |
| `--rag-url` | `http://localhost:8001` | urgs-rag 端点 |
| `--output` | `eval/data/eval_results.json` | 结果输出路径 |

### 第三步：查看评估报告

评估完成后会在终端打印摘要，同时生成 JSON 详细报告：

```
==================================================
  URGS RAG 评估报告
==================================================
  评估时间: 2026-03-25 15:30:00
  数据集大小: 150 条
  Agent 端点: http://localhost:8000

  指标汇总:
    faithfulness              0.8200  [################----]
    answer_relevancy          0.7600  [###############-----]
    llm_context_precision     0.7100  [##############------]
    llm_context_recall        0.6800  [#############-------]

  低分样本 (Faithfulness < 0.5): 3 条
    - [0.32] G01表的填报范围是什么？
    - [0.41] 贷款变动因素统计制度的主要内容？
==================================================
```

JSON 报告位于 `eval/data/eval_results.json`，包含每条样本的逐项得分。

## 评估指标说明

| 指标 | 含义 | 期望值 |
|------|------|--------|
| **Faithfulness** | 回答是否忠实于检索到的上下文（无幻觉） | ≥ 0.8 |
| **Answer Relevancy** | 回答与问题的相关性 | ≥ 0.7 |
| **Context Precision** | 检索结果中相关内容的排序精确度 | ≥ 0.7 |
| **Context Recall** | 检索是否覆盖了参考答案所需的内容 | ≥ 0.7 |

## 传统检索评估（Hit@K / MRR）

使用已有的 `eval_runner.py` 进行检索质量评估：

```bash
cd urgs-rag
python -m eval.eval_runner
```

输出示例：
```
--- 检索模型评估汇总 ---
总样本量: 60
Hit@5: 0.850
MRR: 0.720
覆盖率: 0.950
```

## 环境变量配置

所有配置项均可通过环境变量覆盖：

```bash
# 服务端点
export EVAL_AGENT_URL=http://localhost:8000
export EVAL_RAG_URL=http://localhost:8001

# 评估用 LLM（推荐使用较强模型做裁判）
export EVAL_LLM_MODEL=qwen3
export EVAL_LLM_BASE_URL=http://25.64.32.35:18085/v1
export EVAL_LLM_API_KEY=sk-xxx
```

## 评测集格式

### 新版格式（generate_dataset 生成）

```json
[
  {
    "question": "用户问题",
    "ground_truth": "标准答案",
    "source_document": "来源文件名",
    "contexts": ["原始文档片段"]
  }
]
```

### 旧版格式（eval_set.json，兼容支持）

```json
[
  {
    "id": "Q-001",
    "question": "用户问题",
    "answer": "标准答案",
    "source": "来源文件名",
    "type": "definition"
  }
]
```

两种格式均可作为 `run_evaluation.py` 的输入数据集。

## 典型使用场景

1. **知识库更新后回归测试**：更新文档后重新跑评估，对比前后分数变化
2. **Prompt 调优**：修改 system prompt 后跑评估，验证效果提升
3. **模型切换评估**：切换底层 LLM 前后对比四项指标
4. **检索参数调优**：调整 Top-K、BM25 权重等参数后对比 Context Precision/Recall
