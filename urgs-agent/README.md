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
