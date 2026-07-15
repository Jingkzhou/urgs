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

监管系统编码必须由用户明确提供，并原样用于 `--system-code` 和授权范围校验。不要从系统中文名、SQL Schema、表名前缀、存储过程变量或程序名称推断编码。

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

用户未提供监管表名、字段名或指标名时，先从 SQL 中提取目标物理表、目标列和中文注释作为多个搜索词，逐次调用 `search`，但每次都必须限定同一个用户提供的 `systemCode`。搜索结果中的表和元素只是候选：字段或指标命中后，根据其所属表 ID 读取 `table-bundle`，再结合物理绑定和 SQL 映射确认。

查询指标时，检查搜索结果和 `table-bundle` 中类型为 `INDICATOR` 的元素，并按需调用 `element` 取得公式、取数 SQL、代码片段、值域、码表和校验规则。即使用户没有给出指标名，只要 SQL 含有聚合、比例、算术派生、窗口或其他指标计算，也要主动检查候选表中的指标并完成匹配分析。

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
