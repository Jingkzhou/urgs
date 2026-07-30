# Grok Build Desktop 能力矩阵

更新时间：2026-07-30

## 现场基线

- URGS 随包二进制：`grok 0.2.112 (9bbd559437aa)`，`aarch64-apple-darwin`
- 随包清单：`src-tauri/binaries/grok-sidecar-manifest.json`
- 官方公开仓库最新提交：`5da6962e4adb9c857f3def762542b52b4ec3e522`
- 发现方式：随包二进制 `--version`、根命令和全部顶级子命令 `--help`、真实 ACP `initialize`、扩展方法探测、官方同提交源码与用户指南

随包二进制的构建哈希不是官方公开仓库中的可达提交，因此能力判断以随包二进制的真实响应为准，公开源码只用于识别后续候选。

## 能力矩阵

| 能力 | 官方证据 | URGS 入口 | 接入层 | 状态 | 自动化证据 | 人工证据 | 阻塞/备注 |
|---|---|---|---|---|---|---|---|
| 新建、加载、续聊 | ACP `session/new`、`session/load`、`session/prompt` | 新建任务、历史任务输入框 | ACP + 会话状态 | 原生 UI | Rust 会话测试、前端类型检查 | 历史任务可恢复后继续发送 | 已按 session/process/task 三重标识隔离 |
| 多会话与取消 | ACP `session/cancel` | 左侧历史会话、输入框停止按钮 | ACP + 会话状态 | 原生 UI | Rust 进程关联测试 | 多任务状态独立显示 | 并发数量不硬编码 |
| 工具、思考、计划、权限 | ACP `session/update`、permission reverse request | 消息区工具时间线、计划按钮、权限弹窗 | ACP 事件桥接 | 原生 UI | Rust 事件解析测试、前端类型检查 | 工具详情可展开，权限归属当前任务 | 未识别事件保留为诊断活动 |
| 本地附件上下文 | `promptCapabilities.embeddedContext=true`，ACP 基线支持嵌入资源 | 新任务附件按钮、首条消息附件回显 | 原生文件选择授权 + ACP 文本/二进制 `resource` | 原生 UI | Rust 文本、二进制、路径、一次性授权与大小门禁单测 | 原生选择授权和附件回显已验收；未发送文件内容 | 最多 20 个绝对路径文件，单文件 10 MB、合计 25 MB；不支持目录 |
| 持续目标 | `availableCommands: goal`、`goal_updated` | 会话能力条、`/goal` 菜单、目标活动 | ACP 命令 + 事件 | 原生 UI | 前端类型检查 | 待真实目标运行验收 | 支持设置、状态、暂停、恢复、清理 |
| 工作流 | `availableCommands: workflow` | 会话能力条、`/workflow` 菜单 | ACP 命令 | 原生 UI | 前端类型检查 | 待真实工作流运行验收 | 运行详情依赖运行时事件，未知变体进入诊断 |
| 深度研究 | `availableCommands: deep-research` | 会话能力条、`/deep-research` 菜单 | ACP 命令 | 原生 UI | 前端类型检查 | 待真实研究任务验收 | 内网模型是否具备搜索工具由会话配置决定 |
| 上下文、会话信息、压缩 | `context`、`session-info`、`compact` | 会话能力条、斜杠命令菜单 | ACP 命令 | 原生 UI | 前端类型检查 | 待长会话验收 | 自动压缩事件已进入工具时间线 |
| 模型与凭据 | ACP model state；官方自定义模型配置 | 设置 → 常规 → 模型连接 | Tauri + 系统凭据库 | 原生 UI | Rust 模型配置测试 | 模型可选择且页面初始化不读取密钥 | URGS 内网隔离禁止 xAI 登录和回退 |
| MCP | `grok mcp list/add/remove/doctor` | 设置 → CLI 与诊断 → MCP 服务 | 受控 CLI | 仅 CLI 中心 | CLI allowlist 测试 | 待真实 MCP 连通性验收 | ACP 新会话当前传入空 `mcpServers`，运行时读取本地配置 |
| 插件与市场 | `grok plugin *` | 设置 → CLI 与诊断 → 插件与市场 | 受控 CLI | 仅 CLI 中心 | CLI 参数测试 | 待真实本地插件验收 | 内网隔离关闭官方市场自动注册；本地源仍可用 |
| 记忆 | `grok memory clear`、`--experimental-memory` | 任务执行设置、CLI 与诊断 | ACP 参数 + 受控 CLI | 通用桥接 | 参数构建测试 | 记忆事件显示在工具时间线 | 清理动作需要确认 |
| Worktree | `--worktree`、`grok worktree *` | 任务执行设置、CLI 与诊断 | Headless 参数 + 受控 CLI | 通用桥接 | CLI 参数测试 | 待真实创建/清理验收 | 删除默认 dry-run，关闭预览需再次确认 |
| Agent/Leader 后台服务 | `agent headless/serve/leader`、`leader *` | 设置 → CLI 与诊断 → Agent 服务 | Tauri 后台进程 | 通用桥接 | Rust 服务 allowlist 测试 | 服务 PID、输出和停止可见 | ACP stdio 由新建任务托管 |
| 导出、Trace、Doctor、Inspect | 顶级 CLI 命令 | 设置 → CLI 与诊断 | 受控 CLI | 仅 CLI 中心 | CLI allowlist 测试 | 输出可查看和复制 | Trace 默认仅本地 |
| 登录、托管配置、在线模型、自更新 | `login/logout/setup/models/update` | 无 | 禁止接入 | 缺失 | CLI allowlist 拒绝测试 | 设置页显示内网隔离 | 产品安全策略明确禁止 xAI 与组件自更新 |
| 会话 Recap | ACP `initialize` 宣告 `sessionRecap=true` | 无 | 扩展探测 | 上游不支持 | `x.ai/recap` 返回 `-32601 Method not found` | 无 | 当前二进制声明与实际方法不一致，升级后重验 |
| 会话 Rewind | ACP `initialize` 宣告 `cancelRewind=true` | 无 | 扩展探测 | 上游不支持 | `x.ai/rewind/points` 返回 `-32601 Method not found` | 无 | 不创建不可用入口；升级后优先接入 |
| 图片、音频提示 | `promptCapabilities.image=false`、`audio=false` | 无 | ACP 能力门禁 | 上游不支持 | ACP initialize 探测 | 无 | `voiceMode=true` 不能替代 ACP 图片/音频提示能力 |
| Hooks 管理 | ACP 宣告 `x.ai/hooks` 能力；官方新源码含管理扩展 | 无 | 未接入 | 缺失 | 仅完成 initialize 探测 | 无 | 当前随包版本没有可验证管理方法；升级后再接入 |

## 下一阶段优先级

1. 升级并锁定新的官方 sidecar 后，重新探测 `x.ai/rewind/*`、`x.ai/recap`、`x.ai/session/info` 和 Hooks 扩展。
2. 扩展方法真实可用后，优先补齐原生 Rewind 选择器、会话 Recap 和结构化上下文用量面板。
3. 继续验证工作流运行详情、目标暂停恢复、两个并发会话和历史恢复后的事件隔离。
