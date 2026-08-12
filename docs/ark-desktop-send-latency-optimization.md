# ARK Desktop 发送消息延迟分析及优化方案

> 状态:分析完成,暂未实施
> 日期:2026-08-12

## 问题现象

会话输入框发送消息后,会有 1~5 秒不可编辑,时长不稳定。

## 机制说明(为什么输入框会被锁)

`TaskComposer` 输入框的禁用条件:

```js
disabled = (isRunning && !canQueuePrompt) || isWaitingAuthorization || sending
canQueuePrompt = 任务正在执行 && engine !== 'headless' && task.sessionId 有值
```

即:**任务进入执行中、但本地会话(sessionId)尚未建立之前,输入框锁定**。这是防御性设计(防止编辑正在提交的消息),恢复时机是"会话就绪",不是任务执行完。

### 新建任务(第一条消息)的阻塞时间线

1. `startTask` 同步创建任务(status=running、sessionId 为空)→ 输入框立即锁定;
2. 后台串行执行:
   - Git 工作区准备(仅 worktree/readonly 模式阻塞,实测 2.9~3.2s;workspace 模式已不阻塞);
   - `grok_create_session`:sidecar 进程复用或冷启动 + ACP initialize + session/new;
3. 会话建立 → 写入 sessionId → 输入框解锁 → 发送第一条 prompt。

### 已有会话追加消息的阻塞时间线

1. `sending=true` → 输入框锁定;
2. `sendFollowUp`:
   - sessionId 丢失时先搜索历史会话(API/CLI,1 到数秒);
   - 会话未挂载时 `loadGrokSession`(启动 sidecar + session/load + 重放事件,冷启动数秒);
   - 发送 prompt(快速返回,执行过程不锁输入框);
3. `sending=false` 解锁。

## 耗时构成与可压缩点

| 环节 | 现状耗时 | 可压缩方式 | 收益 |
|------|---------|-----------|------|
| sidecar 进程冷启动(最大头) | 2~5 秒 | 进入页面时预热常驻进程,任务直接复用 | 首次任务数秒 → <1 秒 |
| Git 工作区准备(worktree/readonly) | ~3 秒(阻塞) | 与进程启动并行;workspace 模式已不阻塞 | 串行变重叠 |
| 输入框解锁时机(感知层) | 等会话就绪 | 发送后立即解锁,消息排队、会话就绪自动补发 | 感知零延迟 |
| 历史会话搜索/挂载(重启后) | 1 到数秒 | sessionId 已持久化;配合进程预热 | 降到 1 秒内 |
| 环境因素 | UNC 网络盘 IO 慢 | 工作区放本地盘 | Git 扫描、文件 IO 显著变快 |

## 优化方案

### 方案 A:输入框立即解锁 + 待发消息排队(纯前端,推荐先做)

- 思路:点发送后输入框立即恢复可编辑,用户在会话就绪期间输入的消息先缓存,会话就绪后按顺序自动发送。
- 改动点:
  - `TaskComposer`/`TaskView`:解除 `canQueuePrompt` 对 `sessionId` 的依赖,任务 running 时输入框始终可用;
  - `sendFollowUp`:会话未就绪时把消息写入待发队列(`activePromptRequestsRef` 已有类似机制),会话就绪后自动补发;
  - 注意:session 未就绪时 `grok_send_prompt` 会失败(日志出现过 "Grok 本地会话尚未挂载"),因此必须前端缓存,不能直接发。
- 收益:感知上"发送后立即可继续打字",体验提升最大。
- 风险:低(纯前端,消息顺序与失败处理需覆盖)。

### 方案 B:进入 ARK Desktop 时预热 sidecar 进程(Rust 小改动)

- 思路:页面加载/应用启动时后台预启动一个通用 Grok sidecar,第一个任务的 session/new 直接复用(现有多进程复用机制已存在,日志中 session/new 热复用仅 ~424ms)。
- 改动点:`urgs-desktop/src-tauri/src/grok_runtime.rs` 进程管理,增加预热时机与空闲回收策略(避免常驻空转)。
- 收益:首次任务冷启动 2~5 秒 → 亚秒级;对"重启后首次追加消息"同样有效。
- 风险:低~中(进程生命周期管理需谨慎,避免泄漏)。

### 方案 C:worktree/readonly 模式下进程启动与 Git 准备并行(Rust + 前端配合)

- 思路:把 `grok_create_session` 拆为"启动进程"与"创建会话"两步;进程先启动,Git 准备并行进行,之后只做 session/new。
- 改动点:Rust 端拆分命令;前端 `startTask` 调整调用顺序;注意 worktree 路径依赖 Git 准备结果,会话创建仍需等待。
- 收益:worktree 模式从"3s+0.5s 串行"变为约 3s(重叠)。
- 风险:中(需要 Rust 端新命令、错误处理路径较多)。

### 零成本建议

- 常用工作区放本地盘(当前 `\\?\UNC\psf\...` 网络共享,Git 扫描偏慢);
- 模型连接选择响应快的服务,初始化探测耗时随之下降。

## 涉及文件

- 前端:`urgs-web/src/components/ark-desktop/ArkDesktopPage.tsx`(TaskComposer/TaskView)
- 前端:`urgs-web/src/components/ark-desktop/useArkDesktopRuntime.ts`(startTask / sendFollowUp)
- Rust:`urgs-desktop/src-tauri/src/grok_runtime.rs`(进程管理 / grok_create_session)
