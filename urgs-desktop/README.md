# URGS Windows 客户端

本目录使用 Tauri 2 打包现有 `urgs-web`，客户端继续连接集中部署的 URGS 服务。

## 本地开发

```bash
cd urgs-desktop
pnpm --dir ../urgs-web install --frozen-lockfile
pnpm install
pnpm dev
```

首次启动会要求填写 API 和 WebSocket 服务地址，配置保存在当前用户的应用配置目录。

客户端启动后会检查其安装包内写入的内网 `latest.json`。发现新版本后会在后台下载，下载完成后提示用户重启；用户无需再次手工下载安装包。

## Windows 安装包

在 Windows 构建机上执行：

```powershell
cd urgs-desktop
pnpm install --frozen-lockfile
pnpm build:unsigned
```

构建结果位于 `src-tauri/target/release/bundle/msi` 和 `src-tauri/target/release/bundle/nsis`。

构建完成后可执行以下命令，确认 MSI 和 NSIS 安装包同时存在、版本正确且文件非空，并生成 SHA-256 校验清单：

```powershell
pnpm verify:windows
```

`pnpm verify:windows` 同时检查以下交付门禁：

- Windows WebView2 使用离线安装模式；
- MSI 和 NSIS 安装包均存在、非空且版本一致。

验收结果会写入 `src-tauri/target/release/bundle/windows-build-manifest.json` 和 `SHA256SUMS.txt`。

智能任务中心及 Grok Build 运行时已经迁移到独立仓库 [Jingkzhou/jl-intelligent-center](https://github.com/Jingkzhou/jl-intelligent-center)，URGS 仅保留启动和用户快照交接入口，不再随包分发 Grok sidecar。

也可以在 GitHub Actions 中手动运行“URGS Windows 客户端”工作流，或提交包含桌面端相关变更的 Pull Request 触发验证构建。生成的 MSI、`setup.exe` 和 SHA-256 清单会作为流水线产物保留 14 天。

## 发布内网自动更新

Tauri updater 强制使用签名校验。当前客户端公开密钥已经写入 `tauri.conf.json`，私钥与密码只保存在本机：

- `~/.tauri/urgs-updater.key`
- `~/.tauri/urgs-updater.key.password`

SIT 和生产环境不连接互联网，不能把 GitHub Releases 当作更新源。请在可构建 Windows 安装包的机器上，用同一套 Tauri 更新私钥构建，并将内网更新地址写入安装包：

```powershell
$env:TAURI_UPDATER_ENDPOINT = "http://25.18.17.210:18080/desktop/latest.json"
$env:TAURI_SIGNING_PRIVATE_KEY = Get-Content "$HOME/.tauri/urgs-updater.key" -Raw
$env:TAURI_SIGNING_PRIVATE_KEY_PASSWORD = Get-Content "$HOME/.tauri/urgs-updater.key.password" -Raw
pnpm --dir urgs-desktop build:updater
```

构建完成后，将 `urgs-desktop/src-tauri/target/release/bundle/` 目录（含 MSI、`setup.exe` 以及对应 `.sig`）带回打包机，然后执行：

```bash
DEPLOY_ENV=sit \
DESKTOP_UPDATER_SOURCE_DIR=/path/to/windows-bundle \
deploy/package-services.sh api web executor nginx desktop
```

本地部署模拟使用 `deploy.local.env`，Desktop 打包流程与 SIT 相同：默认触发 GitHub Actions 签名构建，也可以显式指定已准备好的 Windows 签名工件：

```bash
DEPLOY_ENV=local \
DESKTOP_UPDATER_SOURCE_DIR=/path/to/windows-bundle \
deploy/package-services.sh api web executor nginx desktop
```

不指定 `DESKTOP_UPDATER_SOURCE_DIR` 时，需要 GitHub Actions 权限、已登录的 GitHub Token，并且当前分支已提交推送；构建产物会写入客户端本地更新地址 `http://127.0.0.1:18080/desktop/latest.json`。

也可以直接执行 `DEPLOY_ENV=sit deploy/package-services.sh api web executor nginx desktop`。当没有设置 `DESKTOP_UPDATER_SOURCE_DIR` 时，该脚本会调用 GitHub Actions、等待签名构建结束，并把工件下载到项目的 `deploy/artifacts/windows-updater/` 固定目录；首次使用前需要设置一次有 Actions 读写权限的 `DESKTOP_UPDATER_GITHUB_TOKEN`，且当前分支必须已提交并推送。它不会创建 GitHub Release。

该命令会生成内网 `latest.json`，并在服务器执行 `bin/deploy.sh up` 后由 Nginx 发布为：

```text
http://25.18.17.210:18080/desktop/latest.json
```

生产环境使用 `DEPLOY_ENV=prod`，客户端构建时的 `TAURI_UPDATER_ENDPOINT` 必须改为 `http://214.129.29.66:18080/desktop/latest.json`。首次接入内网更新时，旧版客户端仍可能指向 GitHub；需要人工安装一次这个写入内网地址的桥接版，之后才可以自动升级。

正式分发前必须配置 Windows 代码签名证书。当前配置已经启用 `webviewInstallMode.type=offlineInstaller`，所以内网终端无需访问互联网安装 WebView2；发布前仍需在一台干净 Windows 机器上完成一次“安装客户端 → 启动客户端 → 配置内网模型 → 创建会话”的验收。
