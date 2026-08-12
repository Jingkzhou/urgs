# URGS 内网 Grok 插件市场

本仓库由 URGS 智能任务中心通过 Grok Build 插件市场协议读取。

## 本地校验

```bash
jq empty .grok-plugin/marketplace.json
jq empty .grok-plugin/plugin-index.json
for plugin in plugins/*; do grok plugin validate "$plugin"; done
```

## 客户端连接

```bash
grok plugin marketplace add git@gitlab.example.intra:ai-plugins/grok-plugin-marketplace.git
grok plugin marketplace list --json
grok plugin install urgs-regulatory-toolkit@grok-plugin-marketplace --trust
```

Grok 1.0.0 以 Git 仓库名作为 Marketplace 限定符，所以仓库项目名请固定为
`grok-plugin-marketplace`；仓库改名后，安装限定符也必须同步修改。

插件发布必须通过 Merge Request，并由插件维护人和安全审核人共同批准。
