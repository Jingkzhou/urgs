# 吉林银行智能任务中心

`JLIntelligentCenter` 是从 URGS Desktop 拆分出的独立智能任务中心 App，负责本地智能体任务执行、工作区与 Git Worktree 管理、会话恢复、插件、工作流、自动化和模型连接。

## 应用身份

- 中文名称：吉林银行智能任务中心
- 技术名称：JLIntelligentCenter
- Bundle ID：`com.jilinbank.jlintelligentcenter`
- 启动协议：`jlintelligentcenter://`
- 数据目录：由 Tauri 按独立 Bundle ID 管理

URGS 只保留启动入口。首次从 URGS 启动本 App 时，URGS 会交接当前登录用户和旧任务快照；独立 App 会以只复制、不删除的方式迁移旧会话、通用任务目录、模型配置、Worktree 记录与 Git 审计数据。

## 本地开发

```bash
cd jl-intelligent-center
pnpm install
pnpm dev
```

`pnpm dev` 会先运行 `prepare:grok`，将当前目标平台的 Grok Build sidecar 准备到 `src-tauri/binaries/`。

## 验证与构建

```bash
pnpm run test:desktop-compat
pnpm run check:desktop-compat
pnpm run build:web
cargo test --manifest-path src-tauri/Cargo.toml
pnpm run build:debug
```

macOS Debug App 输出到：

```text
src-tauri/target/debug/bundle/macos/吉林银行智能任务中心.app
```

## Windows 发布

Windows x64 sidecar 由 `grok-sidecar.lock.json` 固定版本、大小和 SHA-256。GitHub Actions 使用：

- `.github/workflows/jl-intelligent-center-windows.yml`
- `.github/workflows/jl-intelligent-center-release.yml`

独立更新清单路径应使用 `/jl-intelligent-center/latest.json`，不得复用 URGS Desktop 的 `/desktop/latest.json`。

完整 Grok/ACP 能力状态见 [GROK_BUILD_CAPABILITY_MATRIX.md](GROK_BUILD_CAPABILITY_MATRIX.md)。
