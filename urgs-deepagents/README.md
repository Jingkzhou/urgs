# URGS DeepAgents Service

独立的 DeepAgents 微服务组件。该模块把 `langchain-ai/deepagents` 的 Python 包源码 vendoring 到本项目中，并用一个很薄的 FastAPI 服务暴露最小运行入口。

## 来源

- Upstream: https://github.com/langchain-ai/deepagents
- Commit: `4ffea88690418207b5e4fa800ee8c1abfa454bec`
- Package version: `0.6.10`
- License: MIT，见 `LICENSE.upstream`

本模块只复制 upstream `libs/deepagents/deepagents` 包源码；upstream README、CHANGELOG、THREAT_MODEL 放在 `vendor/` 下留作溯源。

## 为什么独立成模块

`urgs-agent` 当前使用 LangChain/LangGraph 0.x 依赖链；DeepAgents 0.6.10 依赖 LangChain 1.x。为了避免破坏现有 Agent Runtime，DeepAgents 作为平级微服务维护独立依赖、镜像和端口。

## 本地启动

```bash
cd urgs-deepagents
cp .env.example .env
uv sync --all-extras
uv run uvicorn urgs_deepagents_service.main:app --host 0.0.0.0 --port 8003
```

健康检查：

```bash
curl http://127.0.0.1:8003/health/live
```

查看 upstream 信息：

```bash
curl http://127.0.0.1:8003/v1/upstream
```

调用 DeepAgent：

```bash
curl -X POST http://127.0.0.1:8003/v1/agents/invoke \
  -H 'Content-Type: application/json' \
  -d '{"messages":"用一句话说明 DeepAgents 的核心能力"}'
```

## 结构

```text
src/deepagents                  vendored upstream DeepAgents Python package
src/urgs_deepagents_service     URGS 微服务封装
vendor                          upstream 文档备份
LICENSE.upstream                upstream MIT License
```

默认模型来源于 URGS 后端“系统管理 -> AI API 配置管理”中标记为默认且启用的配置。
DeepAgents 通过内部接口读取：
`GET ${DEEPAGENTS_URGS_API_URL}/api/internal/ai/config/default`。
该接口使用 `DEEPAGENTS_INTERNAL_API_TOKEN` 鉴权；通过根目录 `start.sh` 启动时会自动复用 `URGS_INTERNAL_API_TOKEN`。

只有显式设置 `DEEPAGENTS_MODEL` 或在 `/v1/agents/invoke` 请求体里传 `model` 时，才会覆盖该默认配置。

当前服务默认不注册 URGS 业务工具，也不提供真实文件系统或 shell 沙箱；后续接入业务工具时，应先定义权限边界、审计和沙箱策略。
