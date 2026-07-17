# URGS Windows 客户端

本目录使用 Tauri 2 打包现有 `urgs-web`，客户端继续连接集中部署的 URGS 服务。

## 本地开发

```bash
cd urgs-desktop
pnpm install
pnpm dev
```

首次启动会要求填写 API 和 WebSocket 服务地址，配置保存在当前用户的应用配置目录。

客户端启动后会自动检查 GitHub Releases 中的 `latest.json`。发现新版本后会在后台下载，下载完成后提示用户重启；用户无需再次手工下载安装包。

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

验收结果会写入 `src-tauri/target/release/bundle/windows-build-manifest.json` 和 `SHA256SUMS.txt`。

也可以在 GitHub Actions 中手动运行“URGS Windows 客户端”工作流，或提交包含桌面端相关变更的 Pull Request 触发验证构建。生成的 MSI、`setup.exe` 和 SHA-256 清单会作为流水线产物保留 14 天。

## 发布自动更新

Tauri updater 强制使用签名校验。当前客户端公开密钥已经写入 `tauri.conf.json`，私钥与密码只保存在本机：

- `~/.tauri/urgs-updater.key`
- `~/.tauri/urgs-updater.key.password`

发布前，在 GitHub 仓库中配置以下 Actions Secrets：

- `TAURI_SIGNING_PRIVATE_KEY`：`urgs-updater.key` 的完整内容
- `TAURI_SIGNING_PRIVATE_KEY_PASSWORD`：`urgs-updater.key.password` 的完整内容

然后同步修改 `tauri.conf.json` 中的版本号并推送同版本标签，例如：

```bash
git tag desktop-v0.2.0
git push origin desktop-v0.2.0
```

“发布 URGS Windows 客户端”工作流会生成签名的 NSIS/MSI、`.sig` 文件和 `latest.json`，并创建正式 GitHub Release。已安装的客户端会从以下地址检查更新：

```text
https://github.com/Jingkzhou/urgs/releases/latest/download/latest.json
```

正式分发前必须配置 Windows 代码签名证书。内网终端无法在线安装 WebView2 时，应将 `webviewInstallMode` 调整为离线安装模式。
