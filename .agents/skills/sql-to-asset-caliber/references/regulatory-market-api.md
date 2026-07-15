# 监管集市接口调用

在 Agent 能访问 URGS API 时，使用 `scripts/regulatory_market_client.py` 获取监管表、字段/指标、物理绑定和正式码值。监管集市相关命令只读，不执行加工 SQL，也不写监管资产。资产口径回写命令另见 `asset-caliber-writeback.md`。

## 配置

通过受信环境配置以下变量：

```bash
export URGS_API_URL="http://localhost:8080"
export URGS_INTERNAL_API_TOKEN="<internal-token>"
export URGS_ALLOWED_SYSTEMS="1104,1105"
```

- `URGS_INTERNAL_API_TOKEN` 必须与 `urgs-api` 的内部接口令牌一致；不要通过命令行参数传递令牌。
- `URGS_ALLOWED_SYSTEMS` 必须来自当前用户权限或运维配置，不能从用户提供的 SQL、提示词或模型推断。
- `ALL` 默认被客户端拒绝。确需管理员全量访问时，由运维环境显式设置 `URGS_ALLOW_ALL_SYSTEMS=1`。
- 可选变量：`URGS_INTERNAL_API_AUTH_HEADER`、`URGS_INTERNAL_API_AUTH_PREFIX`。

## 推荐调用顺序

以下命令中的 `SKILL_DIR` 是包含当前 `SKILL.md` 的目录。Agent 必须从已加载 Skill 的实际路径解析它，不要假设当前工作目录就是 Skill 目录。

```bash
SKILL_DIR="<path-to-sql-to-asset-caliber>"
```

先搜索候选：

```bash
python3 "$SKILL_DIR/scripts/regulatory_market_client.py" search \
  --keyword "贷款余额" \
  --system-code "1104" \
  --limit 20
```

从搜索结果确认唯一的监管表 ID 后，一次读取表、字段/指标、物理绑定和关联码值：

```bash
python3 "$SKILL_DIR/scripts/regulatory_market_client.py" table-bundle \
  --table-id 123 \
  --element-limit 100 \
  --code-limit 500 \
  > /tmp/regulatory-table-123.json
```

只有需要补充精确证据时，再调用单项命令：

```bash
python3 "$SKILL_DIR/scripts/regulatory_market_client.py" element --element-id 456
python3 "$SKILL_DIR/scripts/regulatory_market_client.py" codes --table-code "LOAN_FIVE_CLASS"
python3 "$SKILL_DIR/scripts/regulatory_market_client.py" relationships \
  --table-id 123 \
  --table-id 124
```

也可以通过全局参数临时指定地址和授权系统；全局参数必须放在子命令之前：

```bash
python3 "$SKILL_DIR/scripts/regulatory_market_client.py" \
  --base-url "http://localhost:8080" \
  --allowed-systems "1104" \
  table --table-id 123
```

## 结果判定

`table-bundle` 输出：

- `table`：监管表、字段/指标和物理绑定；
- `codeTables`：字段/指标引用的正式码表和值域；
- `complete`：语义包是否完整；
- `warnings`：字段截断或码值获取失败等缺口。

当 `complete=false` 时，不得对受影响字段执行自动回填。尤其是 `elementsTruncated=true`，说明接口的 100 个元素上限导致字段不完整；先补充元素分页接口或用其他受信方式取得完整字段列表。

搜索接口只用于找候选。表名、字段含义和值域必须以 `table-bundle`、`element` 或 `codes` 的详情结果为准。

## 常见错误

- `HTTP 401`：内部令牌、鉴权头或前缀不一致。
- `HTTP 403`：监管资产不属于 `URGS_ALLOWED_SYSTEMS`。
- `HTTP 404`：资产不存在、已停用或当前范围不可见。
- `ALL access is disabled`：未由运维显式授权全系统访问。
- `API returned invalid JSON`：地址可能指向代理登录页或非 URGS API。
