# URGS MCP Server

`urgs-mcp-server` 是 JLIntelligentCenter 与 URGS 业务能力之间的 MCP 协议适配层。它不直接访问数据库，只调用受 URGS 用户身份和权限控制的 `/api/agent/v1/**` 接口。

当前第一阶段只提供只读工具：

- `search_regulatory_assets`：按关键词查询当前用户有权访问的监管表。

## 本地启动

```bash
cd urgs-mcp-server
uv sync --all-extras
export URGS_API_BASE_URL=http://127.0.0.1:8080
export URGS_ACCESS_TOKEN=<当前 URGS 用户 Token>
uv run urgs-mcp-server
```

默认 MCP 地址为：

```text
http://127.0.0.1:8010/mcp
```

当前版本使用进程环境中的用户 Token，且强制只监听回环地址，适合本地闭环验证。正式远程部署前必须接入 URGS OAuth/PKCE 和 MCP Bearer Token 校验，不能把共享内部令牌或用户 Token 写入插件配置。

## JLIntelligentCenter 配置

在用户或项目的 Grok `config.toml` 中增加：

```toml
[mcp_servers.urgs-regulatory]
type = "http"
url = "http://127.0.0.1:8010/mcp"
enabled = true
```

保存后在 JLIntelligentCenter 的 MCP 管理器中重新加载服务。

## 验证

```bash
cd urgs-mcp-server
uv run pytest -v
uv run ruff check .
uv run mypy src/
```

也可以启动 MCP Inspector，连接 `http://127.0.0.1:8010/mcp`，确认工具发现和调用均成功。
