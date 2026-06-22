# URGS DeepAgents Service

`urgs-deepagents` 是 URGS 项目下独立维护的 DeepAgents 微服务组件。它将 LangChain 官方 `deepagents` Python 包源码 vendoring 到本项目中，并在其上层用 FastAPI 构建 HTTP/SSE 微服务，用于向 URGS 提供 DeepAgent 调用、多 Agent 编排、工具可见性控制和模型配置接入能力。

## 项目目标

本模块主要解决三类问题：

1. **依赖隔离**：`urgs-agent` 当前使用 LangChain/LangGraph 0.x 依赖链；DeepAgents 0.6.10 依赖 LangChain 1.x。独立微服务可以避免 Python 依赖冲突。
2. **能力封装**：把 DeepAgents 的文件系统、子代理、记忆、技能、摘要、工具调用等能力封装为 URGS 可调用的 HTTP 服务。
3. **多 Agent 编排**：在 DeepAgents 之上增加 URGS 自定义编排管道，用于输入校验、路由、规划、执行、验收、返工和最终汇总。

## 来源

- Upstream: `https://github.com/langchain-ai/deepagents`
- Upstream commit: `4ffea88690418207b5e4fa800ee8c1abfa454bec`
- DeepAgents package version: `0.6.10`
- License: MIT，见 `LICENSE.upstream`

本模块只复制 upstream `libs/deepagents/deepagents` 包源码；upstream README、CHANGELOG、THREAT_MODEL 放在 `vendor/` 下留作溯源。

## 技术栈

`pyproject.toml` 中定义的当前技术栈如下：

| 类别 | 技术 |
|------|------|
| Python | `>=3.11,<3.14` |
| Web 服务 | FastAPI `0.116.1`、Uvicorn `0.35.0` |
| AI/Agent | LangChain `>=1.3.9,<2.0.0`、LangGraph、DeepAgents `0.6.10` |
| 模型适配 | `langchain-openai`、`langchain-anthropic`、`langchain-google-genai` |
| 数据模型 | Pydantic `2.11.9`、pydantic-settings `2.10.1` |
| HTTP 客户端 | httpx `0.28.1` |
| 日志 | python-json-logger `3.3.0` |
| 构建 | setuptools `80.9.0`、wheel `0.45.1`、uv |
| 测试 | pytest `8.4.2`、pytest-asyncio `1.1.0` |
| 代码质量 | ruff `0.13.0`、mypy `1.18.1` |

## 项目结构

```text
urgs-deepagents/
├── README.md
├── pyproject.toml
├── uv.lock
├── Dockerfile
├── .env.example
├── LICENSE.upstream
├── vendor/                              # upstream 文档备份
├── src/
│   ├── deepagents/                      # vendored upstream DeepAgents SDK 0.6.10
│   │   ├── graph.py                     # 核心入口 create_deep_agent()
│   │   ├── backends/                    # State/Filesystem/Store/Composite/Sandbox 后端
│   │   ├── middleware/                  # 文件系统、子代理、记忆、技能、摘要、评分等中间件
│   │   └── profiles/                    # 模型与 Agent 行为配置
│   └── urgs_deepagents_service/         # URGS 微服务封装层
│       ├── main.py                      # FastAPI 应用入口和 HTTP 端点
│       ├── config.py                    # DEEPAGENTS_* 环境变量配置
│       ├── model_config.py              # 从 URGS 后端获取 AI API 默认配置并构建模型
│       ├── observability.py             # 日志与请求上下文
│       ├── runtime.py                   # Agent 运行时配置、工具权限和可见性
│       ├── schemas.py                   # Pydantic 请求/响应模型
│       ├── sse.py                       # SSE envelope、序列化和脱敏
│       └── orchestrator/
│           ├── orchestrator.py          # 多 Agent 编排主流程
│           ├── input_guard.py           # 输入安全/合规校验
│           ├── router.py                # Agent 路由与复杂度判断
│           ├── planner.py               # 复杂任务拆解
│           ├── worker.py                # 子任务执行
│           ├── reviewer.py              # 输出验收与质量判断
│           ├── finalizer.py             # 最终答案汇总
│           ├── state.py                 # 编排状态与结构化结果
│           └── utils.py                 # 编排共享工具函数
└── tests/
    ├── test_service.py                  # FastAPI 服务测试
    └── test_orchestrator.py             # 编排流程测试
```

## 架构设计

### Layer 1: vendored DeepAgents SDK

`src/deepagents/` 是 LangChain 官方 DeepAgents SDK 的 vendored 源码。核心入口是 `create_deep_agent()`，基于 LangGraph Agent 构建，通过中间件栈提供以下能力：

| 能力 | 说明 |
|------|------|
| 文件系统工具 | `ls`、`read_file`、`write_file`、`edit_file`、`glob`、`grep` |
| Shell 执行 | `execute`，需要 SandboxBackendProtocol 后端 |
| Todo 管理 | `write_todos` |
| 子代理调用 | `task` 工具，支持同步和异步子代理 |
| 记忆系统 | 注入 `AGENTS.md` 等文件指令 |
| 技能系统 | 注入技能目录中的工具/流程说明 |
| 上下文管理 | Token 超限时自动摘要历史上下文 |
| 人工审批 | 对高风险工具调用配置中断和审批 |
| 可插拔后端 | State、Filesystem、Store、Composite、Sandbox 等后端 |

### Layer 2: URGS 微服务封装

`src/urgs_deepagents_service/` 负责把 DeepAgents 暴露为 URGS 可调用服务，主要职责包括：

- FastAPI 应用初始化、健康检查和业务端点。
- 从 URGS 后端读取默认 AI API 配置。
- 构造兼容 OpenAI API 的 ChatModel。
- 统一 SSE 事件 envelope。
- 运行时工具白名单、只读文件系统权限、写入工具开关。
- 多 Agent 编排流程。
- 内部 API token 鉴权。
- 错误信息脱敏。

## 多 Agent 编排

编排管道：

```text
Input Guard -> Router/Supervisor -> Planner (if complex) -> Worker -> Reviewer -> (Rework?) -> Finalizer
```

| 阶段 | 职责 |
|------|------|
| Input Guard | 校验空输入、提示注入、敏感信息、高危动作等风险 |
| Router/Supervisor | 根据 Agent 目录和任务描述选择最合适的 Agent，并判断任务复杂度 |
| Planner | 对复杂任务拆解为 2-5 个串行子步骤 |
| Worker | 执行子任务，复用 DeepAgent，并转发工具事件 |
| Reviewer | 从相关性、完整性、准确性、合规性、可用性等维度验收结果 |
| Rework | 验收失败时触发一次返工；再次失败则标记质量风险 |
| Finalizer | 简单任务透传 Worker 结果，复杂任务汇总多步骤产出 |
| Handoff | 非 DeepAgents 构建模式的 Agent 交回 URGS API 侧处理 |

## HTTP API

| 端点 | 方法 | 说明 |
|------|------|------|
| `/health/live` | GET | 存活检查 |
| `/health/ready` | GET | 就绪检查：校验模型配置来源或 URGS 默认 AI API 配置 |
| `/v1/upstream` | GET | 返回 upstream 包信息 |
| `/v1/router/route` | POST | 根据任务描述和 Agent 目录选择 Agent |
| `/v1/agents/invoke` | POST | 同步调用 DeepAgent |
| `/v1/agents/stream` | POST | SSE 流式调用 DeepAgent |
| `/v1/orchestrator/stream` | POST | 多 Agent 编排 SSE 流式输出 |

配置 `DEEPAGENTS_INTERNAL_API_TOKEN` 后，`/v1/router/route`、`/v1/agents/invoke`、`/v1/agents/stream`、`/v1/orchestrator/stream` 需要携带内部鉴权头。未配置 token 时保留本地开发兼容。

## SSE 事件协议

`/v1/agents/stream` 与 `/v1/orchestrator/stream` 保持原有 `event` 名称，同时为每个 payload 增加稳定 envelope 字段。

| 字段 | 说明 |
|------|------|
| `event` | SSE event 名称 |
| `run_id` | 本次请求级 ID，同一条流内保持一致 |
| `step_id` | 阶段/步骤 ID |
| `agent_code` | 当前 Agent 编码；无 Agent 上下文时为 `null` |
| `timestamp` | UTC ISO 时间 |
| `status` | `started`、`completed`、`passed`、`failed`、`rejected`、`streaming` 等 |
| `message` | 面向日志与调试的阶段消息 |

主要事件：

| 事件 | 说明 |
|------|------|
| `input_guard` | 输入校验结果 |
| `routing` | 路由结果，包括 `agent_code`、`confidence`、`is_complex` |
| `planning` | 复杂任务拆解步骤 |
| `worker` | Worker 执行状态 |
| `content` | 流式或最终答案文本 |
| `agent` | 过程事件，如 thinking、tool_call、tool_result |
| `review` | 验收结果，包括 passed、score、issues |
| `rework` | 返工通知 |
| `finalizing` | 最终答案汇总开始 |
| `quality_risk` | 质量风险提示 |
| `handoff` | 非 DeepAgents Agent 交回 API 侧执行 |
| `done` | 编排完成 |
| `error` | 错误信息 |

## 配置项

配置类使用 `DEEPAGENTS_` 前缀，并读取当前目录 `.env`。

| 配置 | 默认值 | 说明 |
|------|--------|------|
| `DEEPAGENTS_SERVICE_NAME` | `urgs-deepagents` | 服务名 |
| `DEEPAGENTS_ENVIRONMENT` | `development` | 运行环境 |
| `DEEPAGENTS_HOST` | `0.0.0.0` | 服务绑定地址 |
| `DEEPAGENTS_PORT` | `8003` | 服务监听端口 |
| `DEEPAGENTS_LOG_LEVEL` | `INFO` | 日志级别 |
| `DEEPAGENTS_URGS_API_URL` | `http://127.0.0.1:8080` | URGS 后端地址 |
| `DEEPAGENTS_INTERNAL_API_TOKEN` | 空 | 内部 API 鉴权令牌 |
| `URGS_INTERNAL_API_TOKEN` | 空 | `DEEPAGENTS_INTERNAL_API_TOKEN` 的兼容别名 |
| `DEEPAGENTS_INTERNAL_API_AUTH_HEADER` | `Authorization` | 内部鉴权请求头名称 |
| `DEEPAGENTS_INTERNAL_API_AUTH_PREFIX` | `Bearer ` | 内部鉴权前缀 |
| `DEEPAGENTS_MODEL` | 空 | 模型覆盖配置 |
| `DEEPAGENTS_REQUEST_TIMEOUT_SECONDS` | `600.0` | 普通请求超时时间 |
| `DEEPAGENTS_CONFIG_REQUEST_TIMEOUT_SECONDS` | `10.0` | 拉取配置请求超时时间 |
| `DEEPAGENTS_RECURSION_LIMIT` | `100` | LangGraph 递归限制 |
| `DEEPAGENTS_ENABLE_WRITE_TOOLS` | `false` | 是否允许写入类工具 |
| `DEEPAGENTS_WORKSPACE_ROOT` | 空 | Agent 工作空间根目录 |
| `DEEPAGENTS_MEMORY_FILES` | 空 | 平台级记忆文件列表 |
| `DEEPAGENTS_SKILL_DIRS` | 空 | 平台级技能目录列表 |
| `DEEPAGENTS_SKILLS_ROOT` | `skills` | 服务内置 Skill 包根目录 |
| `DEEPAGENTS_REGULATORY_QUERY_DATABASE_URL` | 空 | 监管查询 Agent 使用的只读 MySQL 连接串 |

## 模型获取机制

默认模型来源于 URGS 后端“系统管理 → AI API 配置管理”中标记为默认且启用的配置：

```text
GET ${DEEPAGENTS_URGS_API_URL}/api/internal/ai/config/default
```

模型来源优先级：

1. 请求体 `model`
2. `DEEPAGENTS_MODEL`
3. URGS 后端默认 AI API 配置

`/health/ready` 使用相同配置来源判断服务是否可接收请求。如果配置了 `DEEPAGENTS_MODEL`，直接返回 ready；否则读取 URGS 默认 AI API 配置，失败时返回 503。

## 请求模型

### `InvokeRequest`

| 字段 | 说明 |
|------|------|
| `messages` | 用户消息或消息列表 |
| `agent_code` | 指定 Agent 编码 |
| `system_prompt` | 额外系统提示词 |
| `model` | 单次请求模型覆盖 |
| `tool_allowlist` | 工具白名单 |
| `memory_files` | 请求级记忆文件 |
| `skill_dirs` | 请求级技能目录 |
| `debug` | 调试开关 |

### `OrchestratorRequest`

| 字段 | 说明 |
|------|------|
| `messages` | 用户消息或消息列表 |
| `agents` | 可选 Agent 列表 |
| `agent_configs` | Agent 运行配置 |
| `selected_agent_code` | 直接指定 Agent，跳过路由 |
| `system_prompt` | 编排级系统提示词 |
| `model` | 模型覆盖 |
| `debug` | 调试开关 |

### `AgentRuntimeConfig`

| 字段 | 说明 |
|------|------|
| `workspace_root` | 工作空间根目录 |
| `memory_files` | 记忆文件列表 |
| `skill_dirs` | 技能目录列表 |
| `tool_allowlist` | 工具白名单 |
| `system_prompt` | Agent 系统提示词 |
| `allow_write` | 是否允许写入工具 |

## 安全策略

- 默认只读文件系统权限，写入 `/**` 被拒绝。
- 默认排除 `execute` 工具，避免直接开放 shell 执行。
- 支持 `tool_allowlist`，通过工具可见性过滤限制模型可见工具。
- 写工具有服务端总开关：即使请求传入 `allow_write=true` 且白名单包含 `write_file`/`edit_file`，仍必须显式设置 `DEEPAGENTS_ENABLE_WRITE_TOOLS=true`。
- 编排入口前置 Input Guard。
- 内部 API 使用 token 鉴权。
- SSE/HTTP 错误会脱敏 token、密钥和内部地址。

## 监管指标查询 Skill

`regulatory-data-query-agent` 通过 `skills/regulatory-data-query/` 直接连接 MySQL。`SKILL.md` 定义反问和结果表达规则，`skill.json` 定义开关、工具和连接环境变量，`catalog.json` 按“系统 -> 汇总表 -> 指标”和“系统 -> 明细表 -> 字段”维护受控目录；连接串仅从 `DEEPAGENTS_REGULATORY_QUERY_DATABASE_URL` 读取。

Agent 默认停用。启用前必须完成 `catalog.json` 的实际系统、表、指标和字段映射，并为数据库账号只授予目录中目标表的 `SELECT` 权限。运行时只允许目录浏览、指标检索、字段检索、汇总查询和明细查询五个受控工具，不开放 `execute` 或文件工具。明细查询由工具强制限制为最多 5 条。

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

多 Agent 编排：

```bash
curl -X POST http://127.0.0.1:8003/v1/orchestrator/stream \
  -H 'Content-Type: application/json' \
  -d '{"messages":"分析这个需求并给出实施计划"}' \
  --no-buffer
```

## 测试与自检

```bash
cd urgs-deepagents
uv run pytest tests/ -v
uv run mypy src tests
uv run ruff check src tests
```

当前测试覆盖重点包括：

- 服务健康检查与 ready 状态。
- 内部 API 鉴权。
- 默认 AI API 配置读取、重试和错误脱敏。
- DeepAgent 同步与 SSE 流式调用。
- 工具白名单、默认隐藏 `execute`、默认拒绝文件写入。
- Router 路由、编排 SSE envelope、复杂任务规划、返工、质量风险、handoff。

## Docker

```bash
cd urgs-deepagents
docker build -t urgs-deepagents .
docker run -p 8003:8003 --env-file .env urgs-deepagents
```

## 版本提交记录

以下记录按当前分支 `codex/langchainaideepagents` 中涉及 `urgs-deepagents/` 的 Git 提交倒序整理。后续每次对本模块做功能、修复、文档或验证类提交时，应继续在本节顶部追加一条。

| 提交 | 日期 | 类型 | 内容 |
|------|------|------|------|
| `d2293cee` | 2026-06-19 | docs | 更新 README，按当前分支实际源码补充项目目标、技术栈、结构、API、SSE、配置、安全策略和测试方式。 |
| `d5e5e3b9` | 2026-06-18 | refactor | 将最终答案输出集中到 Finalizer 阶段；简单单 Worker 验收通过时直接发布完整答案，复杂或质量风险场景仍由无工具 control agent 汇总。 |
| `dbce413d` | 2026-06-18 | fix/security | 增加写工具服务端总开关；即使请求允许写入，也必须显式启用 `DEEPAGENTS_ENABLE_WRITE_TOOLS`；补齐非 DeepAgents Agent 的 handoff 兼容路径和测试。 |
| `5348be6b` | 2026-06-18 | docs | 文档补充 ready 检查、SSE envelope、内部鉴权和安全策略说明。 |
| `8b2f4dbd` | 2026-06-18 | feat/observability | 新增 `/health/ready`、请求追踪和结构化日志；优化默认 AI API 配置读取、重试、错误脱敏与 Docker 健康检查。 |
| `c77a6471` | 2026-06-18 | test | 为编排生命周期、SSE envelope、ready 状态和服务端路径补充测试；新增结构化编排状态模型。 |
| `1a77bb0d` | 2026-06-18 | refactor | 抽出 `runtime.py` 和 `sse.py`，集中管理 DeepAgent 运行时参数、工具可见性、只读权限、SSE envelope 与错误脱敏；梳理 guard/router/planner/reviewer/finalizer/worker 职责边界。 |
| `3d278a64` | 2026-06-18 | docs | 扩充 DeepAgents 微服务架构说明，补充 vendored upstream、两层架构、编排流程、API、环境变量、Docker 和测试说明。 |
| `13340343` | 2026-06-18 | feat | 增加递归限制配置，将 `recursion_limit` 传入 DeepAgent/Finalizer/Worker 运行配置。 |
| `a9b89079` | 2026-06-18 | feat | 集成 AI token 预算相关能力，优化 DeepAgent 调用和 Worker 上下文管理。 |
| `3dd74018` | 2026-06-18 | feat | 增加 AI 聊天消息校验和 Agent 运行策略配置；扩展请求 schema 与编排/Worker 测试。 |
| `50b6c23d` | 2026-06-18 | feat | 引入完整多 Agent 编排模块，包括 Input Guard、Router、Planner、Worker、Reviewer、Finalizer、一次 Rework 和 `quality_risk` 标记。 |
| `a27ec8d2` | 2026-06-18 | feat | 完善 Router Agent 路由逻辑和响应解析，确保只从请求提供的 Agent 目录中选择有效 Agent。 |
| `c0610038` | 2026-06-18 | feat/api | 实现 DeepAgents Router API 和运行事件追踪；补充 Agent 描述、路由请求/响应 schema、`.env.example` 配置和服务测试。 |
| `1b42fdc7` | 2026-06-18 | feat | 增加 DeepAgents SSE 流式调用能力，转发模型内容、工具调用和工具结果事件。 |
| `7e012b53` | 2026-06-18 | feat/security | 增加内部 API token 鉴权，优化默认 AI 配置拉取和错误处理，并补充相关配置与测试。 |
| `ca4d8121` | 2026-06-18 | feat/startup | 初始化 `urgs-deepagents` 服务：vendoring upstream DeepAgents 0.6.10，新增 FastAPI 微服务、`pyproject.toml`、Dockerfile、环境样例、License、README 和基础测试。 |

## 当前状态

- 当前分支包含 `pyproject.toml`、`uv.lock`、`.env.example`、`Dockerfile`、`src/**/*.py`、`tests/**/*.py` 和 `vendor/`。
- `urgs-deepagents-service` 当前版本为 `0.1.0`。
- 服务默认端口为 `8003`。
- 当前服务默认不注册 URGS 业务工具，也不提供真实 shell 沙箱；监管查询 Agent 是受 Skill 白名单约束的例外，未完成 Skill 映射时不会启用。
