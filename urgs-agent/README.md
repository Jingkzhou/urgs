# URGS Agent Runtime

独立的 LangGraph 智能体运行服务。负责 Agent 定义、版本发布、异步执行、工具与模型调用、Checkpoint、人工审批、SSE 事件和运行审计，不负责用户认证、RBAC 或业务数据管理。

## 运行依赖

- Python 3.11
- PostgreSQL 15+
- Redis 7+
- OpenAI-compatible Chat API

## 本地启动

```bash
cd urgs-agent
cp .env.example .env
uv sync --all-extras
uv run alembic upgrade head
uv run uvicorn urgs_agent.main:app --host 0.0.0.0 --port 8002
```

另开终端启动 Worker：

```bash
cd urgs-agent
uv run python -m urgs_agent.worker
```

也可以使用本地 Compose：

```bash
AGENT_OPENAI_BASE_URL=http://host.docker.internal:11434/v1 docker compose up --build
```

## 创建并发布 Agent

```bash
curl -X POST http://127.0.0.1:8002/v1/agents \
  -H 'Content-Type: application/json' \
  -d '{"agent_id":"general-assistant","name":"General Assistant"}'

curl -X POST http://127.0.0.1:8002/v1/agents/general-assistant/versions \
  -H 'Content-Type: application/json' \
  --data-binary @examples/general-react.yaml

curl -X POST http://127.0.0.1:8002/v1/agents/general-assistant/versions/1/publish
```

API 接收 JSON；示例 YAML 用于展示声明式配置，调用前需要转换为 JSON 或通过业务 API 读取后提交。

## LLM Wiki 知识库 Agent

`examples/llm-wiki-explorer.yaml` 是按 Karpathy LLM Wiki 模式配置的自驱动知识库探索 Agent。
默认读取你的 Obsidian vault：
`/Users/zhoujingkun/Documents/GitHub/Obsidian/regulatory-knowledge-vault`。
Runtime 会在每次模型调用前强制读取并注入 vault 根目录的 `AGENTS.md`，不依赖模型自行调用工具。
当前约定目录结构：

```text
regulatory-knowledge-vault/
  AGENTS.md
  00-首页/index.md
  01-资料库/
    <原始资料，只读>
  02-主题/
  03-实体/
  04-综合/
  05-日志/log.md
  06-项目/
```

配置真实知识库路径：

```bash
export AGENT_KNOWLEDGE_WIKI_ROOT=/Users/zhoujingkun/Documents/GitHub/Obsidian/regulatory-knowledge-vault
export AGENT_KNOWLEDGE_WIKI_WIKI_DIR=.
export AGENT_KNOWLEDGE_WIKI_RAW_DIR=01-资料库
export AGENT_KNOWLEDGE_WIKI_INDEX_PATH=00-首页/index.md
export AGENT_KNOWLEDGE_WIKI_LOG_PATH=05-日志/log.md
export AGENT_KNOWLEDGE_WIKI_AGENT_GUIDE_PATH=AGENTS.md
```

发布 Agent：

```bash
cd urgs-agent
uv run python - <<'PY'
import json
from pathlib import Path

import yaml

data = yaml.safe_load(Path("examples/llm-wiki-explorer.yaml").read_text())
Path("/tmp/llm-wiki-agent.json").write_text(
    json.dumps(
        {key: data[key] for key in ("agent_id", "name", "description")},
        ensure_ascii=False,
    )
)
Path("/tmp/llm-wiki-version.json").write_text(
    json.dumps({"definition": data["definition"]}, ensure_ascii=False)
)
PY

curl -X POST http://127.0.0.1:8002/v1/agents \
  -H 'Content-Type: application/json' \
  --data-binary @/tmp/llm-wiki-agent.json

curl -X POST http://127.0.0.1:8002/v1/agents/llm-wiki-explorer/versions \
  -H 'Content-Type: application/json' \
  --data-binary @/tmp/llm-wiki-version.json

curl -X POST http://127.0.0.1:8002/v1/agents/llm-wiki-explorer/versions/1/publish
```

创建一次深度问答运行：

```bash
curl -X POST http://127.0.0.1:8002/v1/runs \
  -H 'Content-Type: application/json' \
  -d '{
    "conversation_id":"wiki-c-1",
    "thread_id":"wiki-t-1",
    "request_id":"wiki-r-1",
    "trace_id":"wiki-trace-1",
    "agent_id":"llm-wiki-explorer",
    "input":"围绕这个知识库，梳理监管报送批处理和血缘审核之间的关系，给出证据链。",
    "permissions":["knowledge:read","knowledge:write"]
  }'
```

只允许问答、不允许回写 wiki 时，把 `knowledge:write` 从 `permissions` 中移除。

## 创建运行

```bash
curl -X POST http://127.0.0.1:8002/v1/runs \
  -H 'Content-Type: application/json' \
  -d '{
    "conversation_id":"c-1",
    "thread_id":"t-1",
    "request_id":"r-1",
    "trace_id":"trace-1",
    "agent_id":"general-assistant",
    "input":"查询相关知识",
    "permissions":["knowledge:read"]
  }'
```

订阅事件：

```bash
curl -N http://127.0.0.1:8002/v1/runs/<run_id>/events
```

审批恢复：

```bash
curl -X POST http://127.0.0.1:8002/v1/runs/<run_id>/resume \
  -H 'Content-Type: application/json' \
  -d '{"value":{"approved":true}}'
```

## 结构

```text
src/urgs_agent/api       HTTP 与 SSE
src/urgs_agent/domain    状态和 API 契约
src/urgs_agent/plugins   模型、工具、RAG、MCP 插件
src/urgs_agent/runtime   LangGraph 编译与 Worker 执行
src/urgs_agent/storage   PostgreSQL、Redis 与仓储
migrations               Runtime 自有 Alembic 迁移
examples                 声明式 Agent 示例
```

一期内置 `react`、`router`、`supervisor` 模板。Runtime 只允许引用已注册插件，不支持上传任意 Python 代码。
