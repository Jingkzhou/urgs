# CodeGraph 使用指南

## 📦 安装状态

- ✅ CodeGraph v1.0.1 已安装
- ✅ 项目已初始化（928 个文件，16,154 个节点，33,975 条边）
- ✅ Claude Code 已配置 CodeGraph MCP Server
- ✅ 本地模型：qwen3.6-35b-a3b-mtp (http://127.0.0.1:1234)

## 🚀 快速开始

### 方式 1：在 Codex/OpenCode 中使用（推荐）

#### 1. 重启 Codex/OpenCode

要使 CodeGraph MCP Server 生效，需要重启 Codex/OpenCode。

#### 2. 在 Codex/OpenCode 中询问代码问题

重启后，你可以直接询问关于代码的问题，Codex/OpenCode 会自动使用 CodeGraph：

**示例问题：**
```
> 分析 OnlineDocumentController 的调用流程
> 找出所有依赖 TaskService 的地方
> 显示 UserController 的完整代码结构
> 这个方法的调用链是什么？
> 修改这个方法会影响哪些文件？
```

Codex/OpenCode 会优先使用 CodeGraph 的 MCP 工具（`codegraph_explore` 和 `codegraph_node`）来查询代码知识图谱，而不是逐个文件扫描。

**你的 Codex 配置：**
- 配置文件：`~/.config/opencode/opencode.json`
- 当前模型：`openrouter/inclusionai/ring-2.6-1t:free`
- 本地模型：`qwen/qwen3.6-35b-a3b` (http://127.0.0.1:1234/v1)
- CodeGraph MCP：已启用

### 方式 2：在 Claude Code 中使用

#### 1. 重启 Claude Code

要使 CodeGraph MCP Server 生效，需要重启 Claude Code。

#### 2. 在 Claude Code 中使用

重启后，你可以直接询问关于代码的问题，Claude Code 会自动使用 CodeGraph：

**示例问题：**
```
- 分析 OnlineDocumentController 的调用流程
- 找出所有依赖 TaskService 的地方
- 显示 UserController 的完整代码结构
```

Claude Code 会优先使用 CodeGraph 的 MCP 工具（`codegraph_explore` 和 `codegraph_node`）来查询代码知识图谱。

## 🔧 命令行使用

除了在 Claude Code 中使用，你也可以直接使用 CodeGraph 的命令行工具：

### 搜索符号

```bash
codegraph query "OnlineDocumentController"
```

### 探索符号的源代码和调用路径

```bash
codegraph explore "OnlineDocumentController"
```

### 查看某个文件的完整内容（带行号）

```bash
codegraph node "urgs-api/src/main/java/com/example/urgs_api/online/controller/OnlineDocumentController.java"
```

### 查看索引状态

```bash
codegraph status
```

### 查看项目文件结构

```bash
codegraph files
```

### 查找调用者

```bash
codegraph callers "OnlineDocumentController"
```

### 查找被调用者

```bash
codegraph callees "OnlineDocumentController"
```

### 分析修改影响

```bash
codegraph impact "OnlineDocumentController"
```

## 📊 CodeGraph 的优势

根据官方数据，CodeGraph 可以：

- **减少 35% 的 Token 消耗**
- **减少 46% 的响应时间**
- **减少 71% 的工具调用次数**

## 🔄 自动同步

CodeGraph 会自动监听文件变化并更新索引（默认 2 秒防抖）。你不需要手动执行任何同步操作。

如果需要手动同步（例如在 CI 环境中），可以运行：

```bash
codegraph sync
```

## 📝 配置说明

CodeGraph 使用零配置文件设计，会自动：

- 根据文件扩展名识别语言
- 忽略 `node_modules`、`vendor`、`dist`、`build`、`target`、`.venv` 等目录
- 遵循 `.gitignore`
- 跳过 > 1MB 的文件

如需通过环境变量微调：

```bash
# 调整文件监听防抖时间（默认 2000ms）
export CODEGRAPH_WATCH_DEBOUNCE_MS=1000

# 禁用后台文件监听守护进程
export CODEGRAPH_NO_DAEMON=1

# 关闭匿名遥测
export CODEGRAPH_TELEMETRY=0
```

## 🔍 验证 CodeGraph 是否工作

运行以下命令验证：

```bash
# 查看索引状态
codegraph status

# 测试查询功能
codegraph query "OnlineDocumentController"

# 测试探索功能
codegraph explore "OnlineDocumentController"
```

## 📚 更多信息

- 官方文档：https://colbymchenry.github.io/codegraph/
- GitHub 仓库：https://github.com/colbymchenry/codegraph
- 遥测说明：https://github.com/colbymchenry/codegraph/blob/main/TELEMETRY.md

## 🚨 故障排除

### CodeGraph 工具未出现在 Claude Code 中

1. 确保已重启 Claude Code
2. 检查 MCP Server 配置：`cat ~/.claude.json | grep -A 10 "mcpServers"`
3. 手动加载工具：在 Claude Code 中输入 `/mcp`

### 索引未更新

1. 检查守护进程状态：`codegraph daemons`
2. 手动同步：`codegraph sync`
3. 重新构建索引：`codegraph index`

### 查询结果为空

1. 确认当前目录是已初始化的项目（存在 `.codegraph/` 目录）
2. 检查索引状态：`codegraph status`
3. 如果索引损坏，重新初始化：`codegraph uninit && codegraph init`
