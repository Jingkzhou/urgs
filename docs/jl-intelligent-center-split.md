# 智能任务中心独立 App 拆分说明

## 拆分结果

智能任务中心已经从 URGS Web 与 URGS Desktop 的内嵌窗口中拆出，形成独立仓库 [Jingkzhou/jl-intelligent-center](https://github.com/Jingkzhou/jl-intelligent-center)，应用名为“吉林银行智能任务中心”，技术名为 `JLIntelligentCenter`。

职责边界如下：

| 模块 | 负责内容 |
|---|---|
| URGS Web | 保留 Ark 页面中的“Agents”启动入口；交接当前用户和旧任务快照 |
| URGS Desktop | 注册 `launch_jl_intelligent_center` 命令并启动 `jlintelligentcenter://` |
| JLIntelligentCenter Web | 任务、会话、设置、插件、工作流、自动化和 Git 审查 UI |
| JLIntelligentCenter Tauri | Grok ACP、终端、Git/Worktree、系统凭据库、文件与更新能力 |

## 身份与数据隔离

- Bundle ID：`com.jilinbank.jlintelligentcenter`
- URL Scheme：`jlintelligentcenter://`
- localStorage 主键：`jl_intelligent_center_snapshot_v1`
- macOS 数据目录：`~/Library/Application Support/com.jilinbank.jlintelligentcenter`

首次启动迁移遵循“复制但不删除”原则。旧 URGS 目录继续保留，迁移跳过日志、调试数据、运行时缓存、锁文件和符号链接，避免复制活动进程状态或越出目标目录。

## 发布边界

URGS 安装包不再包含 Grok sidecar。JLIntelligentCenter 独立持有 sidecar 锁、能力矩阵、评测夹具、Windows 构建工作流、Bundle ID 和更新清单路径。两个 App 的版本号与自动升级通道互不影响。
