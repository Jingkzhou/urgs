# Grok Build Desktop 能力矩阵

更新时间：2026-08-10

## 结论

本矩阵以 URGS 随包二进制、真实 ACP 握手、同提交 Grok Build 用户指南和源码为准，不再把 Pager/TUI 命令误认为 ACP 会自动下发的 Slash Command。

- 本轮二进制：`grok 1.0.0 (ddbc5c3)`，目标 `aarch64-apple-darwin`
- SHA-256：`9a8581dad0182be548ec01e12f27a6f4152b00c24e254fd6c9db79c3196e3790`
- 随包清单：`src-tauri/binaries/grok-sidecar-manifest.json`
- 实际 ACP `initialize`：协议版本 1；支持 session list/resume/close、HTTP/SSE MCP、Hooks、文件通知、Recap、Cancel Rewind、Voice Mode；prompt 支持 embedded context，不支持 image/audio
- 实际 `session/new`：动态返回 33 个 Agent/Skill/Hook/Workflow 命令，但不返回 `/plan`、`/view-plan`、`/fork`，因为三者属于 Pager 客户端命令

## 为什么此前没有 `/plan`

Grok Build 的 Plan Mode 由客户端负责：Pager 的 `/plan` 或 Shift+Tab 调用 ACP `session/set_mode(modeId=plan)`；智能体完成计划后，通过 `x.ai/exit_plan_mode` 反向请求审批。ACP `availableCommands` 只下发 Agent、Skill、Hook、Workflow 等运行时命令，不会下发 Pager 自己的 `/plan`。

URGS 之前只展示 `availableCommands`，虽然已经处理退出计划模式的审批请求，却没有实现进入 Plan Mode 的客户端动作，因此入口缺失。本轮已补齐：

1. 新任务和会话输入区提供“正常执行 / 计划模式 / 询问模式”。
2. `/plan [description]` 调用 `session/set_mode` 后发送任务；裸 `/plan` 在已有会话中只切换模式。
3. `current_mode_update` 同步回任务状态并持久化。
4. `/view-plan`、`/show-plan`、`/plan-view` 安全读取会话目录内的 `plan.md`。
5. Plan 审批允许空计划响应，并保留“带意见批准”的反馈。
6. `/fork` 和会话菜单调用 `x.ai/session/fork`，复制消息、更新和 Plan 状态，生成独立会话。

## ACP 与核心运行能力

| 能力 | 官方协议/文档 | URGS 入口 | 接入状态 | 验证 |
|---|---|---|---|---|
| 新建、加载、恢复、续聊、关闭 | `session/new`、`load`、`resume`、`prompt`、`close` | 新建任务、历史会话、删除 | 原生 UI | Rust 49 项单测、TypeScript 检查 |
| Plan / Ask / Default | `session/set_mode`、`current_mode_update` | 输入框模式选择、`/plan` | 原生 UI，本轮补齐 | 模式白名单单测、真实二进制协议审计 |
| 计划审批 | `x.ai/exit_plan_mode` | 计划审批弹窗 | 原生 UI | 直接/包装反向请求解析单测 |
| 计划文档 | 会话目录 `plan.md` | `/view-plan` 及别名 | 原生 UI，本轮补齐 | 文件类型、大小、目录边界门禁 |
| 会话分支 | `x.ai/session/fork` | `/fork`、会话菜单“创建会话分支” | 原生 UI，本轮补齐 | ACP DTO 与 Rust/TS 编译 |
| 取消、排队、插话 | `session/cancel`、queue、`x.ai/interject` | 停止按钮、运行中继续发送、队列控制 | 原生 UI | 事件标准化与队列单测 |
| 工具、思考、Todo/Plan | `session/update` | 工具时间线、任务计划 | 原生 UI | 保留有 eventId 的权威 Todo；忽略瞬态 Plan 清理覆盖 |
| 用户提问 | `x.ai/ask_user_question` | 问题选择弹窗 | 原生 UI | 直接/包装反向请求解析单测 |
| 权限 | ACP permission reverse request | 权限弹窗、请求批准/完全访问 | 原生 UI | 会话归属与参数单测 |
| 模型与推理强度 | model config/state | 模型选择、执行设置 | 原生 UI | 模型目录、系统凭据库与切换链路 |
| Recap | `sessionRecap=true`、`session_recap` | 会话详情“最近会话 Recap” | 原生 UI | 事件处理与异步完成保护 |
| Rewind | `cancelRewind=true`、`x.ai/rewind/points`、`execute` | 每轮变更摘要“回退文件” | 原生 UI | Rust 回退模型选择测试；需真实有改动会话人工确认 |
| 附件上下文 | `embeddedContext=true` | 原生附件选择 | 原生 UI | 文本/二进制、一次授权、路径和大小门禁单测 |
| MCP | ACP HTTP/SSE + `grok mcp *` | MCP 管理器、运行时重载 | 原生 UI + 受控 CLI | 服务状态、启停、重载和诊断链路 |
| Hooks | `x.ai/hooks`、动态 Hook 命令 | Slash 菜单、配置、诊断面板 | 原生 UI | 动态命令与 `hooks_changed` 诊断事件 |
| Workflow | `workflow`、项目/用户 Rhai | Workflow 中心、运行控制、Slash | 原生 UI | 项目 `.grok/workflows` 与用户目录安全发现单测 |
| Goal / Loop / Deep Research | 动态 Slash 命令与事件 | Slash 菜单、目标/工作流活动 | 原生 UI | 实际 `session/new` 命令目录 + 前端类型检查 |
| Background Task / Subagent | ACP 更新和扩展 | 会话工具条、活动时间线 | 原生 UI | 列表、等待、停止/取消链路 |
| 文件通知 | `fs_notify` | 运行时桥接 | 通用桥接 | initialize 能力审计；无独立 UI，文件变更统一进入任务视图 |
| Voice Mode | `voiceMode=true` | 无 | 暂不产品化 | 能力宣告不等于 ACP 音频输入；`audio=false` |
| 图片/音频 Prompt | `image=false`、`audio=false` | 无 | 上游未支持 | 严格按 initialize 隐藏 |

## 官方 Pager Slash Command 全量归类

下表覆盖 `docs/user-guide/04-slash-commands.md` 的全部命令。状态不是“每个命令都复制一个 TUI 弹窗”，而是每项都有原生入口、ACP 动态入口、受控 CLI 入口或明确的安全/平台边界。

| 官方命令 | URGS 对应入口 | 归类 |
|---|---|---|
| `/new`、`/home` | 新建任务 | 原生等价 |
| `/resume`、`/dashboard`、`/history` | 工作区会话侧栏、搜索、筛选 | 原生等价 |
| `/compact`、`/context`、`/session-info` | 会话能力菜单、上下文菜单 | ACP 动态/原生 |
| `/fork` | Slash + 会话菜单 | 本轮原生接入 |
| `/rewind`、`/undo`、`/edit-prompt` | 每轮变更摘要回退；继续输入可修订 | 原生等价；不伪造 Pager 编辑器 |
| `/copy` | 消息复制按钮 | 原生等价 |
| `/export`、`/transcript` | CLI 中心 `sessions export` / `export` | 受控 CLI |
| `/quit` | 关闭桌面窗口 | 平台等价 |
| `/delete`、`/rename` | 会话菜单 | 原生等价 |
| `/model`、`/effort` | 输入区模型选择、执行设置 | 原生等价 |
| `/always-approve`、`/auto` | 权限模式选择 | 原生等价 + ACP 动态 |
| `/multiline` | 多行输入框 | 原生常驻能力 |
| `/compact-mode`、`/minimal`、`/fullscreen` | 响应式 Desktop 布局 | Pager 渲染专属，不透传 |
| `/vim-mode` | 无 | Pager 输入法专属，不适用于 React 输入框 |
| `/plan`、`/view-plan` | Slash + 交互模式选择 | 本轮原生接入 |
| `/memory`、`/flush`、`/dream`、`/remember` | 动态 Slash、会话记忆动作、CLI 清理 | ACP/受控 CLI |
| `/hooks` | 动态 Hook 命令、配置与诊断 | ACP 动态/原生 |
| `/plugins`、`/marketplace`、`/skills` | 插件管理器、技能选择、动态命令 | 原生 UI；在线市场按内网策略关闭 |
| `/imagine`、`/imagine-video` | 仅在运行时实际下发时显示 | ACP 能力门禁，不虚构入口 |
| `/loop`、`/goal`、`/deep-research` | Slash 菜单与活动时间线 | ACP 动态 |
| `/workflow`、`/workflows` | Workflow 中心与 Slash | 原生 UI + ACP 动态 |
| `/theme`、`/settings`、`/timestamps` | URGS 设置、固定消息时间 | 原生等价 |
| `/feedback`、`/btw` | 运行时实际下发时显示 | ACP 动态 |
| `/mcps` | MCP 管理器 | 原生等价 |
| `/doctor` | CLI 与诊断 | 受控 CLI |
| `/release-notes`、`/docs`、`/tutorial` | 能力矩阵与随包文档 | 文档入口；不启动外网浏览器 |
| `/import-claude`、`/config-agents`、`/personas` | Agent/Skill/Plugin 配置与 CLI 中心 | 原生/受控 CLI |
| `/login`、`/logout`、`/privacy` | 无 | 内网隔离策略禁止 xAI 账户与遥测 |
| `/usage` | 上下文与会话信息 | 原生等价；不展示远端计费 |

## 顶级 CLI 全量归类

| 顶级命令 | URGS 状态 |
|---|---|
| `agent`、`leader` | 后台服务中心，可启动、查看、停止 |
| `sessions` | 列表、搜索、删除、导出、Trace，并有原生会话侧栏 |
| `mcp` | 原生 MCP 管理器 + doctor/add/remove/list |
| `plugin` | 原生插件管理器，支持本地 validate/install/enable/disable/details/list |
| `memory` | 清理与 flush；高风险动作确认 |
| `worktree` | 原生 Git/Worktree 流程 + CLI list/show/rm/gc/db |
| `inspect`、`doctor`、`du`、`trace`、`export`、`version` | CLI 与诊断中心 |
| `completions` | CLI 中心 |
| `wrap` | 原生剪贴板/消息展示等价，不依赖终端包装 |
| `dashboard` | 智能任务中心本身 |
| `login`、`logout`、`setup`、`models`、`update` | 内网安全策略禁止；模型由 URGS 本地连接管理，不允许组件自更新 |

## 仍需真实环境验收的边界

- 图片和音频输入不是遗漏，当前二进制明确宣告不支持。
- 在线 Marketplace、xAI 登录、遥测隐私切换和 Grok 自更新按内网策略保持禁用。
- Voice Mode 虽已宣告，但没有 ACP 音频输入能力，暂不创建不可用入口。
- Plan、Ask、计划审批、计划预览和 Fork 已完成代码链路与自动化验证；`/Applications/URGS.app` 已真实启动并确认任务中心显示“正常执行 / 计划模式 / 询问模式”。
