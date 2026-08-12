# Grok 内网 GitLab 插件市场建设规范

本文适用于 URGS 智能任务中心内置的 Grok Build 1.0.0 插件市场。市场仓库负责发现和分发插件，客户端负责连接市场、安装、启停、更新和卸载。

## 1. 推荐的 GitLab 组织方式

建议创建一个 GitLab Group：`ai-plugins`，并至少包含一个市场仓库：

```text
ai-plugins/
├── grok-plugin-marketplace       # 市场索引，客户端直接连接
├── urgs-regulatory-toolkit       # 可选：独立插件仓库
├── urgs-lineage-review           # 可选：独立插件仓库
└── urgs-database-inspector       # 可选：独立插件仓库
```

插件数量少、均由同一团队维护时，可以全部放在市场仓库的 `plugins/` 目录。插件需要独立发布、独立授权或由不同团队维护时，使用独立仓库，并在市场索引中通过 Git URL 和提交 SHA 引用。

完整可复制示例位于 `docs/examples/grok-plugin-marketplace/`。

## 2. 市场仓库目录

```text
grok-plugin-marketplace/
├── .grok-plugin/
│   ├── marketplace.json          # 必需：市场和插件索引
│   └── plugin-index.json         # 推荐：组件清单，用于客户端安装前展示
├── plugins/
│   └── urgs-regulatory-toolkit/
│       ├── plugin.json           # 必需：插件清单
│       ├── skills/
│       ├── commands/
│       ├── agents/
│       ├── hooks/hooks.json
│       ├── .mcp.json
│       └── .lsp.json
├── .gitlab-ci.yml
├── CODEOWNERS
└── README.md
```

内部市场统一使用 `.grok-plugin/marketplace.json` 和插件根目录 `plugin.json`。虽然 Grok 兼容 `.claude-plugin/` 和无清单的约定式目录，但不建议内网正式市场依赖兼容格式。

## 3. marketplace.json

```json
{
  "name": "grok-plugin-marketplace",
  "description": "URGS 内网 Grok 插件市场",
  "owner": {
    "name": "监管科技团队",
    "email": "ai-platform@example.intra"
  },
  "plugins": [
    {
      "name": "urgs-regulatory-toolkit",
      "version": "1.0.0",
      "description": "监管资产查询、口径解释和报表辅助能力",
      "category": "regulatory",
      "author": {
        "name": "监管科技团队"
      },
      "source": {
        "type": "local",
        "path": "./plugins/urgs-regulatory-toolkit"
      },
      "tags": ["URGS", "监管", "数据资产"],
      "keywords": ["监管查询", "报表口径", "监管元素"],
      "domains": ["urgs.intra"]
    }
  ]
}
```

独立插件仓库应固定到经过审核的提交 SHA：

```json
{
  "name": "urgs-lineage-review",
  "source": {
    "source": "url",
    "url": "ssh://git@gitlab.example.intra/ai-plugins/urgs-lineage-review.git",
    "sha": "0123456789abcdef0123456789abcdef01234567"
  }
}
```

正式环境禁止只引用可移动的 `main`、分支名或未锁定的 tag。更新插件时先审核新提交，再更新市场仓库中的 SHA。

## 4. plugin.json

插件名称必须使用小写英文、数字和短横线，长度不超过 64 个字符。版本使用 SemVer。

```json
{
  "name": "urgs-regulatory-toolkit",
  "version": "1.0.0",
  "description": "监管资产查询、口径解释和报表辅助能力",
  "author": {
    "name": "监管科技团队",
    "email": "ai-platform@example.intra"
  },
  "repository": "ssh://git@gitlab.example.intra/ai-plugins/grok-plugin-marketplace.git",
  "license": "Proprietary",
  "keywords": ["URGS", "regulatory", "metadata"],
  "skills": "skills",
  "commands": "commands",
  "agents": "agents",
  "hooks": "hooks/hooks.json",
  "mcpServers": ".mcp.json",
  "lspServers": ".lsp.json"
}
```

一个插件可以包含以下任意组合：

| 组件 | 目录或字段 | 用途 |
|---|---|---|
| Skills | `skills/*/SKILL.md` | 可自动触发或由用户调用的业务方法 |
| Commands | `commands/*.md` | 斜杠命令和标准操作入口 |
| Agents | `agents/*.md` | 专项 Agent 角色与规则 |
| Hooks | `hooks/hooks.json` | 会话、指令、工具执行前后的自动动作 |
| MCP Servers | `.mcp.json` | 内网 API、数据库、知识库和工具服务 |
| LSP Servers | `.lsp.json` | Java、Python、SQL 等语言分析服务 |

## 5. plugin-index.json

该文件用于在用户安装前展示插件具体提供了什么。缺少该文件时插件仍可安装，但市场卡片只能显示“安装后读取组件清单”。

```json
{
  "version": 1,
  "plugins": {
    "urgs-regulatory-toolkit": {
      "components": {
        "skills": [
          {
            "name": "regulatory-query",
            "description": "查询监管表、监管元素和业务口径"
          }
        ],
        "commands": [
          {
            "name": "regulatory-health",
            "description": "检查监管资产和 MCP 连接状态"
          }
        ],
        "agents": [
          {
            "name": "regulatory-reviewer",
            "description": "监管口径和数据使用审核"
          }
        ],
        "mcpServers": [
          {
            "name": "urgs-regulatory",
            "description": "stdio"
          }
        ],
        "hooks": [
          {
            "name": "PreToolUse",
            "description": "拦截未经授权的监管数据写操作"
          }
        ],
        "lspServers": [
          {
            "name": "sql-language-server",
            "description": "SQL"
          }
        ]
      }
    }
  }
}
```

在 URGS 内网市场中，`plugin-index.json` 是强制发布文件，不是可选说明。插件必须在安装前声明 Skills、Commands、Agents、MCP Servers、Hooks、LSP Servers 中实际包含的能力；客户端据此展示能力标签和筛选项。缺少索引的插件会显示“能力类型未声明”，用户无法在安装前完成安全判断。

如果市场条目引用独立仓库，`plugin-index.json` 中对应插件还必须填写相同的 `sha`，否则 Grok 会隐藏可能过期的组件说明。

## 6. MCP、Hooks 和密钥规范

- MCP 配置只能引用环境变量名，禁止在 `.mcp.json`、脚本或 Git 历史中写入密码、Token、Cookie、数据库连接密码。
- 推荐由 Desktop 启动环境、系统凭据库或受控部署配置注入密钥。
- Hooks 属于可执行代码，必须明确事件、匹配范围、超时和失败策略。
- `PreToolUse`、`Stop` 等阻塞型 Hook 必须经过安全评审，不得静默扩大文件、网络或数据库权限。
- MCP Server 和 Hook 脚本必须支持内网环境，不得在未说明的情况下访问互联网。
- 插件卸载默认删除插件内容；需要持久化的数据应写入 Grok 约定的数据目录，不得写回插件安装目录。

## 7. GitLab 权限与发布门禁

建议启用以下规则：

1. `main` 为保护分支，禁止直接 push。
2. 至少一名插件维护人和一名安全审核人批准 Merge Request。
3. 使用 `CODEOWNERS` 约束 `.grok-plugin/`、Hooks、MCP 和脚本目录。
4. 禁止将 Personal Access Token 写入市场 URL；优先使用 SSH Key、Deploy Key 或系统 Git Credential Helper。
5. 开启 Secret Detection、依赖扫描和恶意脚本检查。
6. 市场索引中的远程插件必须固定 40 位提交 SHA。
7. 插件版本、`marketplace.json`、`plugin-index.json` 必须在同一 Merge Request 更新。
8. 发布记录至少包含：插件名、旧版本、新版本、提交 SHA、组件变化、权限变化、回退方式。
9. `marketplace.json` 中的每个插件必须在 `plugin-index.json` 中存在同名条目，并至少声明一种组件能力；不满足时禁止发布。

## 8. CI 校验建议

```yaml
stages:
  - validate

validate-marketplace:
  stage: validate
  image: registry.example.intra/devops/grok-build:1.0.0
  script:
    - jq empty .grok-plugin/marketplace.json
    - jq empty .grok-plugin/plugin-index.json
    - test "$(jq -r '.version' .grok-plugin/plugin-index.json)" = "1"
    - test "$(jq -r '.plugins[].name' .grok-plugin/marketplace.json | sort)" = "$(jq -r '.plugins | keys[]' .grok-plugin/plugin-index.json | sort)"
    - jq -e '(.plugins | length) > 0 and all(.plugins[]; (.components | type) == "object" and ([.components[]? | length] | add // 0) > 0)' .grok-plugin/plugin-index.json
    - for plugin in plugins/*; do grok plugin validate "$plugin"; done
    - test -z "$(git grep -nE '(glpat-|PRIVATE-TOKEN|password[[:space:]]*=|api[_-]?key[[:space:]]*=)' -- . ':!docs')"
```

实际 CI 镜像应使用和 URGS 客户端随包版本一致的 Grok 二进制，避免市场校验通过但客户端无法加载。

## 9. 客户端使用流程

1. 打开“智能任务中心 → 设置 → 插件 → Marketplace”。
2. 输入 GitLab SSH 或 HTTPS 仓库地址，点击“连接仓库”。
3. 在市场中搜索插件，确认来源、组件和风险后点击“安装”。
4. 安装完成后在 Plugins 页启用、禁用、更新或卸载。
5. 在 Hooks、Skills、MCP Servers 页核对实际加载结果。

对应 CLI 为：

```bash
grok plugin marketplace add git@gitlab.example.intra:ai-plugins/grok-plugin-marketplace.git
grok plugin marketplace update
grok plugin install urgs-regulatory-toolkit@grok-plugin-marketplace --trust
grok plugin disable urgs-regulatory-toolkit
grok plugin enable urgs-regulatory-toolkit
grok plugin update urgs-regulatory-toolkit
grok plugin uninstall urgs-regulatory-toolkit --confirm
```

Grok 1.0.0 使用 Git 仓库名作为 Marketplace 限定符，而不是读取
`marketplace.json` 中的展示名称。因此仓库项目名应固定为
`grok-plugin-marketplace`，安装时使用
`插件名@grok-plugin-marketplace`。如果仓库改名，客户端限定符也会随之改变。

注意：移除市场源会同时卸载从该来源安装的插件。生产用户执行前必须在客户端再次确认。
