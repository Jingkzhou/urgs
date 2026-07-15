# 监管资产业务口径回写接口

本文件定义 URGS 监管资产表、字段和指标业务口径的读取、预览、确认回写与回读流程。接口属于项目级 Skill，只使用 URGS 内部 API 的统一令牌认证方式。

## 权限与环境

```bash
export URGS_API_URL="http://localhost:8080"
export URGS_INTERNAL_API_TOKEN="<internal-token>"
export URGS_REQUESTER_USER_ID="<current-user-id>"
```

- 内部令牌只证明调用方是受信服务，不能单独获得写权限。
- 服务端根据请求用户实时校验功能权限和监管系统范围。
- 查询、定位和预览需要 `metadata:asset:view`。
- 更新监管表口径需要 `metadata:asset:edit`。
- 更新监管字段或指标口径需要 `metadata:asset:element:edit`。
- 请求文件中的 `requesterUserId` 不能覆盖环境中的用户。

## 1. 定位并读取目标监管资产

用监管系统编码和监管表名精确定位：

```bash
python3 "$SKILL_DIR/scripts/regulatory_market_client.py" asset-resolve \
  --system-code "1104" \
  --table-name "LOAN_SUMMARY" \
  > /tmp/reg-asset-table.json
```

返回监管表 ID、当前表业务口径、更新时间，以及所属字段/指标的 ID、类型、公式、值域、填报说明、当前业务口径和更新时间。同一系统内表名不唯一时接口拒绝自动选择。

已知监管表 ID 时直接回读：

```bash
python3 "$SKILL_DIR/scripts/regulatory_market_client.py" asset-table \
  --table-id 101
```

## 2. 组织变更请求

结合加工 SQL、物理绑定、监管表/元素描述、指标公式和正式码值生成 JSON：

```json
{
  "tableId": 101,
  "expectedTableUpdateTime": "2026-07-15T10:20:30",
  "tableBusinessCaliber": "按机构、数据日期和客户维度汇总纳入统计范围的贷款余额……",
  "elements": [
    {
      "elementId": 201,
      "expectedUpdateTime": "2026-07-15T10:20:30",
      "businessCaliber": "贷款余额，取符合有效状态条件的借据余额并按人民币折算后汇总……"
    }
  ],
  "reqId": "REQ-2026-001",
  "description": "依据贷款汇总加工 SQL 和监管证据补充业务口径",
  "sourceSql": "INSERT INTO ... SELECT ..."
}
```

要求：

- 时间原样使用最近一次读取结果，不自行生成。
- 只提交能通过物理绑定、字段映射或明确证据关联的监管元素。
- 未修改表口径时省略 `tableBusinessCaliber`。
- 不用空字符串清空口径。
- `sourceSql` 必填，只保存为分析和审计证据，不执行。
- `sourceSql` 以 UTF-8 计不能超过 60000 字节，不能静默截断。
- 不在文件中手工设置 `confirmed`，由客户端按命令注入。

## 3. 预览并处理冲突

```bash
python3 "$SKILL_DIR/scripts/regulatory_market_client.py" caliber-preview \
  --request-file /tmp/reg-asset-caliber-change.json \
  > /tmp/reg-asset-caliber-preview.json
```

仅当 `valid=true` 时进入确认。预览逐项给出 `oldValue`、`newValue`、`changed` 和 `conflict`。

- `conflict=true`：监管资产已被修改，重新读取并合并现有内容。
- 元素不属于目标监管表：修正映射，不能跳过校验。
- 新旧值一致：跳过并计入 `skippedCount`。
- 已有口径与新证据冲突：停止自动回写，展示冲突并请求确认。

## 4. 显式确认后回写

```bash
python3 "$SKILL_DIR/scripts/regulatory_market_client.py" caliber-apply \
  --request-file /tmp/reg-asset-caliber-change.json \
  --confirm \
  > /tmp/reg-asset-caliber-apply.json
```

服务端在同一事务中：

1. 校验用户查看、报表编辑或元素维护权限；
2. 校验用户监管系统范围、元素归属和更新时间；
3. 只更新发生变化的现有 `business_caliber`；
4. 为每个更新写入 `REG_ASSET` 维护记录；
5. 返回更新后的监管表和全部元素。

任一并发更新或维护记录失败都会回滚。

## 5. 回读验证

再次调用 `asset-table`，核对：

- 实际值等于预览的新值；
- 未列入请求的字段/指标未变化；
- `updatedCount`、`skippedCount` 符合预期；
- 更新时间已刷新；
- 待确认项未混入已保存口径。

接口不会新增资产字段，也不会修改物理模型或码表数据。
