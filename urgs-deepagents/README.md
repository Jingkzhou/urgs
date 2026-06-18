# URGS DeepAgents Service

独立的 DeepAgents 微服务组件，将 LangChain 官方 [deepagents](https://github.com/langchain-ai/deepagents) 的 Python 包源码 vendoring 到本项目中，并在其上层用 FastAPI 构建薄封装，以 HTTP 微服务方式暴露 DeepAgents 能力和多 Agent 编排管道。

## 来源

- Upstream: https://github.com/langchain-ai/deepagents
- Commit: `4ffea88690418207b5e4fa800ee8c1abfa454bec`
- Package version: `0.6.10`
- License: MIT，见 `LICENSE.upstream`

本模块只复制 upstream `libs/deepagents/deepagents` 包源码；upstream README、CHANGELOG、THREAT_MODEL 放在 `vendor/` 下留作溯源。

## 为什么独立成模块

`urgs-agent` 当前使用 LangChain/LangGraph 0.x 依赖链；DeepAgents 0.6.10 依赖 LangChain 1.x。为避免依赖冲突，DeepAgents 作为平级微服务维护独立依赖、Docker 镜像和网络端口（默认 8003）。

## 项目结构

```text
src/
├── deepagents/                          # vendored upstream DeepAgents SDK 0.6.10
│   ├── graph.py                         # 核心入口 create_deep_agent()
│   ├── backends/                        # 可插拔后端（State/Filesystem/Store/Composite/Sandbox）
│   ├── middleware/                      # 中间件层（文件系统、子代理、记忆、技能、摘要、评分等）
│   └── profiles/                        # 模型与 Agent 行为配置（ProviderProfile + HarnessProfile）
└── urgs_deepagents_service/             # URGS 微服务封装层
    ├── main.py                          # FastAPI 应用入口 + 所有 HTTP 端点
    ├── config.py                        # 环境变量 → Pydantic 配置（前缀 DEEPAGENTS_）
    ├── model_config.py                  # 从 URGS 后端拉取 AI API 配置 + 构建 ChatOpenAI
    ├── schemas.py                       # Pydantic 请求/响应模型
    └── orchestrator/                    # 多 Agent 编排模块
        ├── orchestrator.py              # 编排主流程（SSE 事件流）
        ├── input_guard.py               # Input Guard（安全/合规前置校验）
        ├── router.py                    # Router/Supervisor（路由分发 + 复杂度判断）
        ├── planner.py                   # Planner（复杂任务拆解为子步骤）
        ├── worker.py                    # Worker（执行子任务，含流式输出 + 工具事件转发）
        ├── reviewer.py                  # Reviewer（多维度验收 Worker 产出）
        ├── finalizer.py                 # Finalizer（汇总最终答案）
        ├── state.py                     # 结构化结果 Pydantic 模型
        └── utils.py                     # 共享工具（SSE 序列化、消息解析、Agent 构建参数）
vendor/                                  # upstream 文档备份
tests/
├── test_service.py                      # FastAPI 服务测试
└── test_orchestrator.py                 # 编排流程测试
```

## 架构

### 两层设计

**Layer 1 — vendored DeepAgents SDK (`src/deepagents/`)**
LangChain 官方 deepagents 包的完整源码，核心是 `create_deep_agent()`，基于 LangGraph 的 `create_agent()` 构建，通过中间件栈提供：

| 能力 | 实现 |
|------|------|
| 文件系统工具 | `ls`、`read_file`、`write_file`、`edit_file`、`glob`、`grep` — `FilesystemMiddleware` |
| Shell 执行 | `execute` — 需 `SandboxBackendProtocol` 后端 |
| Todo 管理 | `write_todos` — `TodoListMiddleware` |
| 子代理调用 | `task` 工具 — `SubAgentMiddleware`，支持同步 + 异步子代理 |
| 记忆系统 | `AGENTS.md` 等文件指令注入 — `MemoryMiddleware` |
| 技能系统 | 技能目录指令注入 — `SkillsMiddleware` |
| 上下文窗口管理 | Token 超限时自动摘要历史 — `SummarizationMiddleware` |
| 提示缓存 | Anthropic 模型 prompt caching |
| Human-in-the-Loop | `interrupt_on` 配置 + `FilesystemPermission` 人工审批 |
| 可插拔后端 | `StateBackend`(默认) / `FilesystemBackend` / `StoreBackend` / `CompositeBackend` / `SandboxBackend` |

**Layer 2 — URGS 微服务封装 (`src/urgs_deepagents_service/`)**
HTTP 微服务层，负责模型获取、安全控制、SSE 流式输出和多 Agent 编排。

### 编排管道

多 Agent 编排是 URGS 的核心自定义功能，实现完整的编排管道并通过 SSE 事件流向前端推送进展：

```
Input Guard → Router/Supervisor → Planner (if complex) → Worker → Reviewer → (Rework?) → Finalizer
```

#### SSE 事件协议

| 事件 | 描述 |
|------|------|
| `input_guard` | 输入校验结果（`passed`/`rejected`） |
| `routing` | 路由结果（`agent_code`, `confidence`, `is_complex`） |
| `planning` | 复杂任务拆解（`steps` 列表） |
| `worker` | Worker 执行状态（`started`/`completed`） |
| `content` | 流式/最终答案文本 |
| `agent` | 过程事件（`thinking`/`tool_call`/`tool_result`） |
| `review` | 验收结果（`passed`/`failed`, `score`, `issues`） |
| `rework` | 返工通知 |
| `finalizing` | 最终答案汇总开始 |
| `quality_risk` | 质量风险提示 |
| `handoff` | 非 DEEPAGENTS agent 交回 API 侧执行 |
| `done` | 编排完成 |
| `error` | 错误信息 |

#### 编排各阶段职责

1. **Input Guard** — 对用户输入做安全/合规校验：空输入、提示注入、敏感信息、高危动作
2. **Router** — 根据 agent 目录和任务描述选择最合适的 agent，同时判断任务复杂度
3. **Planner** — 对复杂任务拆解为 2-5 个串行子步骤，每个步骤指定负责的 agent 和依赖关系
4. **Worker** — 执行子任务，复用 `create_deep_agent`，支持流式输出和工具事件转发。编排管道中默认不向前端流式输出内容（避免半成品泄露），最终答案统一由 Finalizer 输出
5. **Reviewer** — 对 Worker 产出做多维度验收：相关性、完整性、准确性、合规性、可用性
6. **返工机制** — 验收不合格 → 返工一次 → 再次验收 → 仍不合格则标记 `quality_risk=true` 并返回最佳结果
7. **Finalizer** — 汇总最终答案：简单路径（单 Worker）直接透传，复杂路径（多 Worker）调用 LLM 整合
8. **Handoff** — 对非 DEEPAGENTS 构建模式的 agent（如 RAG），返回 `handoff` 事件交回 API 侧走遗留执行路径

## HTTP API 端点

| 端点 | 方法 | 描述 |
|------|------|------|
| `/health/live` | GET | 健康检查 |
| `/health/ready` | GET | 就绪检查：校验模型配置来源或 URGS 默认 AI API 配置 |
| `/v1/upstream` | GET | 返回 upstream 信息（包名、版本、仓库、commit、license） |
| `/v1/router/route` | POST | Router Agent：根据任务描述和 agent 目录选择最合适的 agent |
| `/v1/agents/invoke` | POST | 同步调用 DeepAgent |
| `/v1/agents/stream` | POST | SSE 流式调用 DeepAgent |
| `/v1/orchestrator/stream` | POST | 多 Agent 编排（完整编排管道，SSE 流式输出） |

## 安全措施

- **默认只读文件系统权限** — `READ_ONLY_FILESYSTEM_PERMISSIONS`：deny write on `/**`
- **默认排除 execute 工具** — `DEFAULT_EXCLUDED_TOOLS` = `{"execute"}`
- **工具可见性过滤** — 支持 `tool_allowlist` 白名单控制，`ToolVisibilityMiddleware` 在每次模型调用时动态过滤工具列表
- **Input Guard** — 编排管道前置安全校验
- **错误脱敏** — SSE/HTTP 错误会脱敏 token、密钥和内部地址
- **本地前置校验** — 空输入、常见提示词注入、敏感信息、高危生产动作会先于模型调用被拒绝

## 模型获取机制

默认模型来源于 URGS 后端"系统管理 → AI API 配置管理"中标记为默认且启用的配置：

```
GET ${DEEPAGENTS_URGS_API_URL}/api/internal/ai/config/default
```

该接口使用 `DEEPAGENTS_INTERNAL_API_TOKEN` 鉴权；通过根目录 `start.sh` 启动时会自动复用 `URGS_INTERNAL_API_TOKEN`。

只有显式设置 `DEEPAGENTS_MODEL` 或在请求体中传 `model` 时，才会覆盖该默认配置。

模型来源优先级：

1. 请求体 `model`
2. `DEEPAGENTS_MODEL`
3. URGS 后端默认 AI API 配置

`/health/ready` 使用相同的配置来源判断服务是否可接收请求：如果配置了 `DEEPAGENTS_MODEL`，直接返回 ready；否则会读取 URGS 默认 AI API 配置，失败时返回 503。

## SSE 事件约定

`/v1/agents/stream` 与 `/v1/orchestrator/stream` 保持原有 `event` 名称与旧字段，同时为每个 payload 增加稳定 envelope 字段：

| 字段 | 说明 |
|------|------|
| `event` | SSE event 名称 |
| `run_id` | 本次请求级 ID，同一条流内保持一致 |
| `step_id` | 阶段/步骤 ID |
| `agent_code` | 当前 Agent 编码；无 Agent 上下文时为 `null` |
| `timestamp` | UTC ISO 时间 |
| `status` | `started` / `completed` / `passed` / `failed` / `rejected` / `streaming` 等 |
| `message` | 面向日志与调试的阶段消息 |

## 本地开发

```bash
cd urgs-deepagents
cp .env.example .env
uv sync --all-extras
uv run uvicorn urgs_deepagents_service.main:app --host 0.0.0.0 --port 8003
```

健康检查：

```bash
curl http://127.0.0.1:8003/health/live
curl http://127.0.0.1:8003/health/ready
```

查看 upstream 信息：

```bash
curl http://127.0.0.1:8003/v1/upstream
```

同步调用 DeepAgent：

```bash
curl -X POST http://127.0.0.1:8003/v1/agents/invoke \
  -H 'Content-Type: application/json' \
  -d '{"messages":"用一句话说明 DeepAgents 的核心能力"}'
```

SSE 流式调用：

```bash
curl -X POST http://127.0.0.1:8003/v1/agents/stream \
  -H 'Content-Type: application/json' \
  -d '{"messages":"写一段 Python 快速排序代码"}' \
  --no-buffer
```

## 测试

```bash
uv run pytest tests/ -v
uv run ruff check .
uv run mypy src/
```

`src/deepagents/` 是 vendored upstream 源码，ruff/mypy 配置排除或忽略该包的静态检查错误，避免为了本服务门禁修改 upstream 文件。

## 环境变量

| 变量 | 说明 | 默认值 |
|------|------|--------|
| `DEEPAGENTS_ENVIRONMENT` | 运行环境 | `development` |
| `DEEPAGENTS_HOST` | 绑定地址 | `0.0.0.0` |
| `DEEPAGENTS_PORT` | 监听端口 | `8003` |
| `DEEPAGENTS_LOG_LEVEL` | 日志级别 | `INFO` |
| `DEEPAGENTS_URGS_API_URL` | URGS 后端地址 | `http://127.0.0.1:8080` |
| `DEEPAGENTS_INTERNAL_API_TOKEN` | 内部 API 鉴权令牌 | `""` |
| `DEEPAGENTS_MODEL` | 模型覆盖（可选） | — |
| `DEEPAGENTS_WORKSPACE_ROOT` | 工作空间根目录 | — |
| `DEEPAGENTS_MEMORY_FILES` | 平台级记忆文件列表 | — |
| `DEEPAGENTS_SKILL_DIRS` | 平台级技能目录列表 | — |

## Docker

```bash
cd urgs-deepagents
docker build -t urgs-deepagents .
docker run -p 8003:8003 --env-file .env urgs-deepagents
```

## 技术栈

- **Web 框架**：FastAPI + Uvicorn
- **AI/Agent**：LangChain 1.x + LangGraph + DeepAgents 0.6.10
- **模型**：ChatOpenAI（兼容 OpenAI API 的任意模型）
- **数据校验**：Pydantic v2 + pydantic-settings
- **HTTP 客户端**：httpx
- **日志**：python-json-logger
- **构建**：setuptools + uv
- **测试**：pytest + pytest-asyncio
- **代码质量**：ruff + mypy

## 当前状态与后续计划

当前服务默认不注册 URGS 业务工具，也不提供真实文件系统或 shell 沙箱。后续接入业务工具时，应先定义权限边界、审计和沙箱策略。
