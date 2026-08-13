# 吉林银行智能任务中心真实 App 历史验收报告

验收日期：2026-07-30

## 验收基线

- 原验收 App：`urgs-desktop/src-tauri/target/debug/bundle/macos/URGS.app`
- App 构建时间：`2026-07-30 09:43:03`
- Desktop 可执行文件 SHA-256：`4ffa8904d6655e0e5328a18af93ce1a2107c3e188774d5a079508577c1b43de0`
- Grok sidecar：`grok 0.2.112 (9bbd559437aa)`
- 模型：`deepseek-v4-flash`
- 工作区：`/Users/zhoujingkun/Documents/GitHub/urgs`
- 方法：从上述 App 包启动真实 macOS 桌面程序，通过原生文件选择器、真实 ACP 会话和真实 sidecar 执行验收。

> 说明：本报告是拆分前的历史回归基线；当前独立 App 路径为 `jl-intelligent-center/src-tauri/target/debug/bundle/macos/吉林银行智能任务中心.app`。

## 结果

| 用例 | 结果 | 现场证据 |
|---|---|---|
| 文本附件读取 | 通过 | 精确返回 `URGS-ATTACHMENT-TEXT-7C21` |
| 中文和空格路径附件 | 通过 | 精确返回 `URGS-ATTACHMENT-ZH-4B9D` |
| 二进制附件 | 通过 | SHA-256 精确返回 `e8e8463c43f580fabd3db57757f84c55a2ac976aac478e023e5071c348f2039f` |
| `/goal` 生命周期 | 通过 | 创建后精确返回 `URGS-GOAL-EVAL-READY`；状态可见；`/goal clear` 后无活动目标 |
| `/workflow` | 通过（用户作用域） | 临时安装到 Desktop 隔离 `GROK_HOME/workflows` 后，精确返回 `URGS-WORKFLOW-EVAL-READY` |
| `/deep-research` | 通过 | 仅读取 `README.md` 第一行，正确返回 `URGS (Unified Resource Governance System)`；主聊天只有启动提示和正式结论，11 个中间活动折叠且均为完成态 |
| 快速切换会话隔离 | 通过 | A、B 会话分别返回 `URGS-SESSION-A-OK`、`URGS-SESSION-B-OK`，切换期间状态和输出未串会话 |
| 历史会话恢复续聊 | 通过 | B 恢复后精确返回 `URGS-SESSION-B-RESUME`，A 中无 B 输出；A 恢复后精确返回 `URGS-SESSION-A-RESUME` |

## 会话能力中心增量验收

- App 构建时间：`2026-07-30 10:45:06`
- Desktop 可执行文件 SHA-256：`ed865b6d202f728e818da2bb9cec9f9d37b38530334674f70f1094b20829888b`
- 结果：通过。真实 App 展示“添加 / 会话能力 / 技能 / 插件”4 个分组；6 个会话命令、6 个启用技能、插件空状态均与运行时一致；技能可选/取消，插件管理直达 CLI 与诊断。

## 本地插件管理增量验收

- App 构建时间：`2026-07-30 11:36:07`
- Desktop 可执行文件 SHA-256：`b93a93e4f2c7d0e4c25c8a2646b374ec786fa92b44fd06d63d416b85fcfdb588`
- 夹具：`fixtures/local-plugin`，包含 `plugin.json` 和 1 个技能目录。
- 隔离 CLI 结果：清单校验、信任安装、列表、启用、详情、禁用全部成功；启用后 `inspect.skills` 出现 `fixture-check`，禁用后该技能消失。
- 真实 App 结果：通过。`+` 菜单直达独立“插件”设置页；原生目录选择、安装、启用状态、组件详情和禁用均可操作；启用时菜单显示 `urgs-local-plugin-fixture`，禁用后恢复空状态。夹具最终保持已安装但禁用。
- 兼容处理：当前 sidecar 在禁用后仍把 `inspect.plugins[].enabled` 返回为 `true`，Desktop 以 CLI 实际写入的 `[plugins] enabled/disabled` 作为开关状态源，同时用运行时技能发现结果验证真实加载。
- 首屏能力修复：会话命令不再启动无模型的离线发现进程，而是复用同工作区、已绑定模型的预热 ACP 进程；预热完成后主动刷新命令，避免全新安装无历史任务时菜单为空。

## 本轮发现与修复

### DR-001 深度研究子智能体输出泄漏到主聊天

- 现象：研究规划、声明提取和交叉验证子智能体的原始 JSON/Markdown 被当作主智能体回复渲染，最终报告虽正确，但聊天区被中间产物淹没。
- 原因：子会话消息可能早于 `subagent_spawned` 映射到达；只依赖已登记映射会把早到消息当成父会话回复，并行输出还会发生字符级交织。
- 修复：用事件 `sessionId` 与任务主 `sessionId` 的身份差异从源头识别子会话；所有子会话内容只进入折叠活动，父会话正式回复保留在聊天区；迟到 chunk 不再让活动终态回退。
- 状态：最终 Debug App 真实复验通过。落盘快照为 1 条用户消息、2 条父会话回复；子智能体活动状态集合仅包含 `已完成`。

## 已知兼容差异

Desktop 为内网隔离使用独立 `GROK_HOME`。本轮 sidecar 能发现该目录下的用户作用域工作流，但未发现仓库 `.grok/workflows` 中的同名工作流。当前验收只确认“用户作用域工作流可运行”，不把项目作用域发现标记为通过。后续若接入项目工作流同步，需要处理同名冲突、刷新时机和工作区切换，不能简单复制覆盖。

## 复验说明

用例定义和固定夹具位于本目录。工作流夹具需临时复制到 Desktop 的隔离 `GROK_HOME/workflows`，重启 App 后执行；验收结束应移除临时副本，避免污染用户长期工作流目录。
