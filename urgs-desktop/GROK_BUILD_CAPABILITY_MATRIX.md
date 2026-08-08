# Grok Build Desktop 能力矩阵

更新时间：2026-08-08

## 现场基线

- URGS 本轮构建二进制：`grok 1.0.0 (5151f2f)`，当前开发机为 `aarch64-apple-darwin`；`5151f2f` 为官方 `afbc0fb` 叠加 URGS 两行 Git 子进程分离修复
- Windows 发布锁定：`1.0.0 (3cd0d0cbce)`，目标为 `x86_64-pc-windows-msvc`，哈希见 `grok-sidecar.lock.json`
- 随包清单：`src-tauri/binaries/grok-sidecar-manifest.json`
- 官方公开仓库基线：`afbc0fb710320c7add294c2106d447ecc3e3af2e`，`SOURCE_REV=3e620a76a5f374ce644dc7c87f7e990c68348218`
- 发现方式：随包二进制 `--version`、根命令和全部顶级子命令 `--help`、真实 ACP `initialize`、扩展方法探测、官方同提交源码与用户指南

能力判断以本轮构建二进制的真实响应为准；1.0.0 ACP `initialize` 宣告了 `sessionCapabilities.list/resume/close`、Hooks、`sessionRecap`、`cancelRewind` 和 `voiceMode`，图片/音频输入仍未宣告。`session/new` 已接受会话级 `startupHints`，在未配置模型凭据的隔离探测中按预期返回认证要求。

## 能力矩阵

| 能力 | 官方证据 | URGS 入口 | 接入层 | 状态 | 自动化证据 | 人工证据 | 阻塞/备注 |
|---|---|---|---|---|---|---|---|
| 新建、加载、续聊 | ACP `session/new`、`session/load`、`session/prompt` | 新建任务、历史任务输入框 | ACP + 会话状态 | 原生 UI | Rust 会话测试、前端类型检查 | 历史任务可恢复后继续发送 | 已按 session/process/task 三重标识隔离 |
| 会话附着策略 | 1.0.0 支持会话请求 `_meta.startupHints`，含 `nonInteractive`、`deliveryTools` | 新建任务、历史任务续聊 | ACP 请求元数据 | 通用桥接 | Rust 元数据一致性测试、真实 1.0.0 `session/new` 探测 | 无额外操作；恢复任务延续当前交互策略 | URGS 为可见交互界面，保持 `nonInteractive=false`、`deliveryTools=[]` |
| 多会话与取消 | ACP `session/cancel` | 左侧历史会话、输入框停止按钮 | ACP + 会话状态 | 原生 UI | Rust 进程关联测试 | 多任务状态独立显示 | 并发数量不硬编码 |
| 工作区会话管理 | `grok sessions delete` + URGS 本地会话状态 | 左侧工作区、工作区/会话菜单、状态筛选 | 受控 CLI + 本地持久化状态 | 原生 UI | 前端类型检查、真实 App 交互验收 | 支持在指定工作区新建、固定、重命名、归档/恢复、搜索筛选和永久删除 | 运行中或等待授权的会话禁止归档和删除；永久删除会同步清理 Grok 历史 |
| 工具、思考、计划、权限 | ACP `session/update`、permission reverse request | 消息区工具时间线、计划按钮、权限弹窗 | ACP 事件桥接 | 原生 UI | Rust 事件解析测试、前端类型检查 | 工具详情可展开，权限归属当前任务 | 未识别事件保留为诊断活动 |
| 本地附件上下文 | `promptCapabilities.embeddedContext=true`，ACP 基线支持嵌入资源 | 新任务附件按钮、首条消息附件回显 | 原生文件选择授权 + ACP 文本/二进制 `resource` | 原生 UI | Rust 文本、二进制、路径、一次性授权与大小门禁单测 | 原生选择授权和附件回显已验收；未发送文件内容 | 最多 20 个绝对路径文件，单文件 10 MB、合计 25 MB；不支持目录 |
| 本地任务技能 | URGS `ArkDesktopSkill` 与 `buildSessionRules` | 新任务输入框 `+` → 技能 | 本地技能状态 + ACP 会话规则 | 原生 UI | 前端类型检查 | 真实 App 已验证多选、取消与菜单保持展开 | 仅展示已启用技能；选择状态在新会话创建时注入，不伪装成 Grok 原生插件技能 |
| 持续目标 | `availableCommands: goal`、`goal_updated` | 输入框 `+` → 会话能力、`/goal` 菜单、目标活动 | ACP 命令 + 事件 | 原生 UI | 前端类型检查 | 真实 App 已完成创建、状态展示、结果和清理验收 | 支持设置、状态、暂停、恢复、清理 |
| 工作流 | `availableCommands: workflow` | 输入框 `+` → 会话能力、`/workflow` 菜单 | ACP 命令 | 原生 UI | 前端类型检查、固定 Rhai 夹具 | 用户作用域工作流真实 App 运行通过 | 隔离 `GROK_HOME` 暂未发现仓库 `.grok/workflows`，项目作用域仍待接入 |
| 深度研究 | `availableCommands: deep-research` | 输入框 `+` → 会话能力、`/deep-research` 菜单 | ACP 命令 | 原生 UI | 前端类型检查、真实本地研究用例 | 本地 README 研究结果和子智能体中间输出隔离均通过；入口可正确填入命令 | 内网模型是否具备搜索工具由会话配置决定 |
| 上下文、会话信息、压缩 | `context`、`session-info`、`compact` | 会话能力条、斜杠命令菜单 | ACP 命令 | 原生 UI | 前端类型检查 | 待长会话验收 | 自动压缩事件已进入工具时间线 |
| 模型与凭据 | ACP model state；官方自定义模型配置 | 设置 → 常规 → 模型连接 | Tauri + 系统凭据库 | 原生 UI | Rust 模型配置测试 | 模型可选择且页面初始化不读取密钥 | URGS 内网隔离禁止 xAI 登录和回退 |
| MCP | `grok mcp list/add/remove/doctor` | 设置 → CLI 与诊断 → MCP 服务 | 受控 CLI | 仅 CLI 中心 | CLI allowlist 测试 | 待真实 MCP 连通性验收 | ACP 新会话当前传入空 `mcpServers`，运行时读取本地配置 |
| 插件与市场 | `grok plugin validate/install/enable/disable/details/list --json`、`grok inspect --json` | 新任务输入框 `+` → 插件状态；设置 → 插件 | 本地目录选择 + 稳定 DTO + 受控 CLI | 原生 UI | 隔离 `GROK_HOME` 完整生命周期、Rust 单测、前端类型检查 | 真实 App 已验证本地目录校验、信任安装、组件详情、启停和 `+` 菜单同步 | 仅支持本地源；在线市场保持关闭。当前 sidecar 禁用后 `inspect.plugins[].enabled` 仍为 true，状态改以 `[plugins] enabled/disabled` 为准，并用技能列表消失验证实际停用 |
| 记忆 | `grok memory clear`、`--experimental-memory` | 任务执行设置、CLI 与诊断 | ACP 参数 + 受控 CLI | 通用桥接 | 参数构建测试 | 记忆事件显示在工具时间线 | 清理动作需要确认 |
| Worktree | `--worktree`、`grok worktree *` | 任务执行设置、CLI 与诊断 | Headless 参数 + 受控 CLI | 通用桥接 | CLI 参数测试 | 待真实创建/清理验收 | 删除默认 dry-run，关闭预览需再次确认 |
| Agent/Leader 后台服务 | `agent headless/serve/leader`、`leader *` | 设置 → CLI 与诊断 → Agent 服务 | Tauri 后台进程 | 通用桥接 | Rust 服务 allowlist 测试 | 服务 PID、输出和停止可见 | ACP stdio 由新建任务托管 |
| 导出、Trace、Doctor、Inspect | 顶级 CLI 命令 | 设置 → CLI 与诊断 | 受控 CLI | 仅 CLI 中心 | CLI allowlist 测试 | 输出可查看和复制 | Trace 默认仅本地 |
| 登录、托管配置、在线模型、自更新 | `login/logout/setup/models/update` | 无 | 禁止接入 | 缺失 | CLI allowlist 拒绝测试 | 设置页显示内网隔离 | 产品安全策略明确禁止 xAI 与组件自更新 |
| 会话 Recap | 1.0.0 ACP `initialize` 宣告 `sessionRecap=true`，摘要跟随会话语言 | 会话详情 → 会话摘要 | ACP 扩展 + 会话状态 | 待验证 | 1.0.0 initialize 已宣告；前端已处理 `session_recap` 和不可用事件 | 待有模型凭据的中文长会话验收 | 不增加独立弹窗，摘要在会话详情按需展开 |
| 会话 Rewind | ACP `initialize` 宣告 `cancelRewind=true` | 无 | 扩展探测 | 待验证 | 1.0.0 initialize 已宣告，尚未完成真实会话方法探测 | 无 | 不创建不可验证入口 |
| 图片、音频提示 | `promptCapabilities.image=false`、`audio=false` | 无 | ACP 能力门禁 | 上游不支持 | 1.0.0 ACP initialize | 无 | `voiceMode=true` 不能替代 ACP 图片/音频提示能力；MCP 工具结果图片是另一条链路 |
| Hooks 管理 | ACP 宣告 `x.ai/hooks` 能力 | 无 | 通用桥接未产品化 | 缺失 | 1.0.0 ACP initialize 已宣告 Hooks | 无 | 当前仍无用户可操作的 Hooks 管理入口 |

## 下一阶段优先级

1. 使用已配置内网模型的真实长会话复验中文 Recap、`x.ai/rewind/*`、`x.ai/session/info` 和 Hooks 扩展。
2. 扩展方法真实可用后，优先补齐原生 Rewind 选择器；Recap 和上下文信息继续放在会话详情，避免打断对话。
3. 补齐项目作用域 `.grok/workflows` 的安全发现机制，并继续验证严格重叠执行的两个并发会话。
