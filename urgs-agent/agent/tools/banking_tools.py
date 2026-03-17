# 银行核心系统数据库查询工具
# Mock实现,用于演示Agent协作流程

from crewai.tools import BaseTool
from typing import Type
from pydantic import BaseModel, Field


class BankingSearchInput(BaseModel):
    """银行系统数据库查询输入"""

    table_name: str = Field(..., description="要查询的表名")
    data_id: str = Field(
        default="", description="可选的数据批次号或业务ID,用于精确查询"
    )
    condition: str = Field(default="", description="可选的查询条件,如 WHERE 子句")


class Search_1104_DB_Tool(BaseTool):
    """
    1104监管报送系统数据库查询工具
    用于排查银保监会报送指标的数据准确性问题
    """

    name: str = "search_1104_database"
    description: str = (
        "查询1104监管报送系统数据库。"
        "适用于排查银保监会报表数据问题,包括校验规则、指标映射、数据完整性等。"
        "输入:table_name(表名)、data_id(批次号)、condition(查询条件)"
    )
    args_schema: Type[BaseModel] = BankingSearchInput

    def _run(self, table_name: str, data_id: str = "", condition: str = "") -> str:
        """执行1104系统数据查询(Mock实现)"""

        # Mock数据:模拟常见的1104报表问题
        mock_data = {
            "G01_LOAN_INFO": {
                "schema": "loan_id, loan_amount, balance, accrual_date, status",
                "sample_count": 10000,
                "issue": "发现3笔贷款记录的 accrual_date 字段为NULL,导致月末余额汇总时被排除",
                "affected_rows": [
                    {
                        "loan_id": "LN202310001",
                        "balance": 5000000,
                        "accrual_date": None,
                    },
                    {
                        "loan_id": "LN202310089",
                        "balance": 3200000,
                        "accrual_date": None,
                    },
                    {
                        "loan_id": "LN202310156",
                        "balance": 1800000,
                        "accrual_date": None,
                    },
                ],
                "root_cause": "上游大集中系统在处理提前还款业务时,未正确更新 accrual_date 字段",
                "fix_suggestion": "联系大集中研发修复数据写入逻辑,并执行数据补录脚本",
            },
            "RPT_ASSET_SUMMARY": {
                "schema": "report_date, asset_type, total_amount, item_count, batch_id",
                "sample_count": 50,
                "issue": "资产总额合计与总账差异500万,经查是因为批次号 BATCH_2023_Q3 中缺失了'投资性房地产'科目",
                "affected_rows": [
                    {
                        "report_date": "2023-10-31",
                        "asset_type": "投资性房地产",
                        "expected": 5000000,
                        "actual": 0,
                    }
                ],
                "root_cause": "1104映射配置中,新增的投资性房地产科目代码(1503)未加入采集范围",
                "fix_suggestion": "更新 asset_mapping.xml 配置,新增科目代码1503,重新跑批",
            },
        }

        result = mock_data.get(
            table_name,
            {
                "error": f"表 {table_name} 在1104系统中不存在或无权限访问",
                "available_tables": list(mock_data.keys()),
            },
        )

        # 格式化输出
        output = f"""
【1104系统查询结果】
表名: {table_name}
批次号: {data_id or '未指定'}
查询条件: {condition or '无'}

"""
        if "error" in result:
            output += (
                f"⚠️  {result['error']}\n可用表: {', '.join(result['available_tables'])}"
            )
        else:
            output += f"""
📊 表结构: {result['schema']}
📈 总记录数: {result['sample_count']}

🔍 发现的问题:
{result['issue']}

❌ 受影响的数据:
{result['affected_rows']}

🎯 根本原因:
{result['root_cause']}

💡 修复建议:
{result['fix_suggestion']}
"""
        return output.strip()


class Search_Core_DB_Tool(BaseTool):
    """
    大集中核心系统数据库查询工具
    用于排查核心交易链路、账户余额和流水问题
    """

    name: str = "search_core_banking_database"
    description: str = (
        "查询大集中核心系统数据库。"
        "适用于排查账户余额、交易流水、批量处理等核心业务问题。"
        "这是银行的底层系统,数据权威性最高。"
        "输入:table_name(表名)、data_id(账号或交易流水号)、condition(查询条件)"
    )
    args_schema: Type[BaseModel] = BankingSearchInput

    def _run(self, table_name: str, data_id: str = "", condition: str = "") -> str:
        """执行大集中系统数据查询(Mock实现)"""

        mock_data = {
            "ACCT_BALANCE": {
                "schema": "account_no, balance, frozen_amount, last_update_time, status",
                "sample_count": 5000000,
                "issue": f"账户 {data_id or '6222021234567890'} 的余额与流水表汇总不一致",
                "query_result": {
                    "account_no": data_id or "6222021234567890",
                    "balance": 150000.00,
                    "expected_balance": 153000.00,
                    "difference": -3000.00,
                },
                "root_cause": "10月15日的一笔转账交易(TXN20231015_00089)在批处理时写入了流水表,但因主机超时未更新余额表",
                "fix_suggestion": "执行余额重算脚本,或手工补录调整分录",
            },
            "TXN_DETAIL": {
                "schema": "txn_id, account_no, amount, txn_type, txn_date, accrual_flag",
                "sample_count": 50000000,
                "issue": "发现部分提前还款交易的 accrual_flag 字段未置位",
                "affected_count": 3,
                "root_cause": "还款交易处理存储过程 SP_EARLY_REPAY 的版本 v2.3.1 存在逻辑缺陷,在处理部分还款场景时未调用 UPDATE_ACCRUAL_FLAG 函数",
                "fix_suggestion": "升级存储过程到 v2.3.2,并对历史数据执行补丁脚本",
            },
        }

        result = mock_data.get(
            table_name,
            {
                "error": f"表 {table_name} 在大集中系统中不存在或无权限访问",
                "hint": "常用表: ACCT_BALANCE, TXN_DETAIL, LOAN_CONTRACT",
            },
        )

        output = f"""
【大集中核心系统查询结果】
表名: {table_name}
业务ID: {data_id or '未指定'}
查询条件: {condition or '无'}

"""
        if "error" in result:
            output += f"⚠️  {result['error']}\n提示: {result['hint']}"
        else:
            output += f"""
📊 表结构: {result['schema']}
📈 总记录数: {result['sample_count']}

🔍 发现的问题:
{result['issue']}

"""
            if "query_result" in result:
                output += f"📋 查询结果:\n{result['query_result']}\n\n"

            output += f"""
🎯 根本原因:
{result['root_cause']}

💡 修复建议:
{result['fix_suggestion']}
"""
        return output.strip()


class Search_EAST_DB_Tool(BaseTool):
    """
    EAST数据报送系统数据库查询工具
    用于排查EAST明细数据的采集与标准化问题
    """

    name: str = "search_east_database"
    description: str = (
        "查询EAST数据报送系统数据库。"
        "适用于排查明细数据采集、数据类型转换、枚举值映射等问题。"
        "EAST系统处理海量明细数据,常见问题是格式校验失败。"
        "输入:table_name(表名)、data_id(报送批次号)、condition(查询条件)"
    )
    args_schema: Type[BaseModel] = BankingSearchInput

    def _run(self, table_name: str, data_id: str = "", condition: str = "") -> str:
        """执行EAST系统数据查询(Mock实现)"""

        mock_data = {
            "EAST_CUSTOMER_INFO": {
                "schema": "customer_id, id_type, id_no, name, mobile, address",
                "sample_count": 3000000,
                "issue": "批次 EAST_202310 中有1250条客户记录的 id_type 字段值为 '0',不符合EAST标准枚举值",
                "validation_error": "id_type 必须为: 1-身份证, 2-护照, 3-军官证, 4-其他",
                "affected_count": 1250,
                "root_cause": "上游CRM系统历史数据中,未办理证件的客户被标记为 id_type=0,但EAST规范不允许此值",
                "fix_suggestion": "数据清洗:将 id_type=0 的记录统一映射为 4(其他),并在 ETL 脚本中添加枚举值校验",
            },
            "EAST_LOAN_CONTRACT": {
                "schema": "contract_no, loan_amount, currency_code, start_date, maturity_date",
                "sample_count": 800000,
                "issue": "部分合同的 currency_code 字段为 'RMB',应为标准货币代码 'CNY'",
                "affected_count": 320,
                "root_cause": "大集中系统在2018年前使用 'RMB' 作为人民币代码,与EAST标准不一致",
                "fix_suggestion": "在EAST采集层添加货币代码转换逻辑: RMB -> CNY, USD -> USD (无需转换)",
            },
        }

        result = mock_data.get(
            table_name,
            {
                "error": f"表 {table_name} 在EAST系统中不存在",
                "hint": "常用表: EAST_CUSTOMER_INFO, EAST_LOAN_CONTRACT, EAST_DEPOSIT_DETAIL",
            },
        )

        output = f"""
【EAST数据报送系统查询结果】
表名: {table_name}
批次号: {data_id or '未指定'}
查询条件: {condition or '无'}

"""
        if "error" in result:
            output += f"⚠️  {result['error']}\n提示: {result['hint']}"
        else:
            output += f"""
📊 表结构: {result['schema']}
📈 总记录数: {result['sample_count']}

🔍 发现的问题:
{result['issue']}

"""
            if "validation_error" in result:
                output += f"❌ 校验错误: {result['validation_error']}\n"

            output += f"""
📊 受影响记录数: {result['affected_count']}

🎯 根本原因:
{result['root_cause']}

💡 修复建议:
{result['fix_suggestion']}
"""
        return output.strip()


class Search_YBT_DB_Tool(BaseTool):
    """
    一表通统一报表系统数据库查询工具
    用于排查综合报表展示层的数据差异问题
    """

    name: str = "search_yibiatong_database"
    description: str = (
        "查询一表通(统一报表)系统数据库。"
        "适用于排查报表展示层的数据差异、汇总逻辑错误等问题。"
        "一表通汇聚全行数据,需要判断是底表逻辑错误还是上游数据问题。"
        "输入:table_name(表名)、data_id(报表日期或批次)、condition(查询条件)"
    )
    args_schema: Type[BaseModel] = BankingSearchInput

    def _run(self, table_name: str, data_id: str = "", condition: str = "") -> str:
        """执行一表通系统数据查询(Mock实现)"""

        mock_data = {
            "YBT_DAILY_SUMMARY": {
                "schema": "report_date, metric_code, metric_name, value, source_system",
                "sample_count": 10000,
                "issue": f"日期 {data_id or '2023-10-31'} 的'存款总额'指标显示为0,但大集中系统有正常数据",
                "comparison": {
                    "一表通显示": 0,
                    "大集中实际": 12500000000,
                    "差异": -12500000000,
                },
                "root_cause": "一表通的ETL任务 JOB_DAILY_DEPOSIT_SYNC 在10月31日02:15执行失败,日志显示'Source connection timeout'",
                "fix_suggestion": "手工重跑ETL任务,并检查与大集中系统的网络连接稳定性",
            },
            "YBT_BRANCH_REPORT": {
                "schema": "branch_code, branch_name, deposit_balance, loan_balance, report_date",
                "sample_count": 500,
                "issue": "分行代码 '320100' (南京分行) 的贷款余额比总行报送数据少2亿",
                "comparison": {
                    "一表通": 5000000000,
                    "总行系统": 5200000000,
                    "差异": -200000000,
                },
                "root_cause": "一表通的分行维度汇总SQL中,WHERE条件遗漏了 '表外贷款' 科目(类型代码=99)",
                "fix_suggestion": "修改汇总SQL,添加: WHERE loan_type IN (01, 02, ..., 99),并重新计算历史数据",
            },
        }

        result = mock_data.get(
            table_name,
            {
                "error": f"表 {table_name} 在一表通系统中不存在",
                "hint": "常用表: YBT_DAILY_SUMMARY, YBT_BRANCH_REPORT, YBT_PRODUCT_ANALYSIS",
            },
        )

        output = f"""
【一表通统一报表系统查询结果】
表名: {table_name}
报表日期: {data_id or '未指定'}
查询条件: {condition or '无'}

"""
        if "error" in result:
            output += f"⚠️  {result['error']}\n提示: {result['hint']}"
        else:
            output += f"""
📊 表结构: {result['schema']}
📈 总记录数: {result['sample_count']}

🔍 发现的问题:
{result['issue']}

"""
            if "comparison" in result:
                output += "📊 数据对比:\n"
                for k, v in result["comparison"].items():
                    output += f"  {k}: {v:,}\n"
                output += "\n"

            output += f"""
🎯 根本原因:
{result['root_cause']}

💡 修复建议:
{result['fix_suggestion']}
"""
        return output.strip()


# 导出所有工具
def get_banking_tools():
    """获取所有银行系统工具"""
    return [
        Search_1104_DB_Tool(),
        Search_Core_DB_Tool(),
        Search_EAST_DB_Tool(),
        Search_YBT_DB_Tool(),
    ]


def get_1104_tools():
    """获取1104系统专用工具"""
    return [Search_1104_DB_Tool()]


def get_core_banking_tools():
    """获取大集中系统专用工具"""
    return [Search_Core_DB_Tool()]


def get_east_tools():
    """获取EAST系统专用工具"""
    return [Search_EAST_DB_Tool()]


def get_ybt_tools():
    """获取一表通系统专用工具"""
    return [Search_YBT_DB_Tool()]


# ==================== 系统级RAG知识库工具 ====================


class RAGSearchInput(BaseModel):
    """RAG知识库查询输入"""

    query: str = Field(..., description="要查询的问题或关键词")
    top_k: int = Field(default=5, description="返回结果数量")


class Search_1104_RAG_Tool(BaseTool):
    """1104系统知识库查询工具"""

    name: str = "search_1104_knowledge"
    description: str = (
        "从1104系统专属知识库检索相关信息。"
        "适用于查询1104报表规则、历史问题解决方案、配置文档、校验公式等。"
        "输入:query(查询问题)、top_k(返回数量,默认5)"
    )
    args_schema: Type[BaseModel] = RAGSearchInput

    def _run(self, query: str, top_k: int = 5) -> str:
        """查询1104知识库(Mock实现)"""

        # Mock知识库数据
        knowledge_base = {
            "报表规则": """
1104报表遵循银保监会《银行业非现场监管报表制度》:
- G01表: 贷款五级分类统计,包含正常、关注、次级、可疑、损失
- G06表: 资产负债表,需与会计总账数据一致
- G09表: 利润表,计算公式: 净利润 = 营业收入 - 营业支出 - 所得税
            """,
            "常见问题": """
Q: 贷款余额合计与总账不符?
A: 检查以下几点:
   1. accrual_date 字段是否存在NULL值
   2. 批次任务是否执行完整
   3. 科目映射配置是否包含所有贷款类型

Q: 校验规则报错?
A: 查看 config/1104_validation_rules.xml
   常见错误码: E001(金额为负), E002(比例超100%), E003(必填项为空)
            """,
            "配置文档": """
1104系统关键配置文件:
- /config/1104_mapping.xml: 科目代码映射
- /config/validation_rules.xml: 校验规则定义
- /scripts/batch_jobs.sh: 批处理脚本
            """,
            "历史修复案例": """
案例1: 2023年Q3贷款余额少3笔
原因: accrual_date 字段为NULL
修复: 执行 UPDATE G01_LOAN_INFO SET accrual_date=txn_date WHERE accrual_date IS NULL

案例2: 投资性房地产科目缺失
原因: 新增科目1503未加入mapping.xml
修复: 更新配置并重新跑批
            """,
        }

        # 简单关键词匹配
        results = []
        for category, content in knowledge_base.items():
            if any(kw in query for kw in category.split()) or any(
                kw in content for kw in query.split()[:3]
            ):
                results.append(f"**{category}**\n{content}")

        output = f"【1104系统知识库】查询: {query}\n\n"
        if results:
            output += "\n\n".join(results[:top_k])
        else:
            output += (
                "未找到相关知识,建议查询: 报表规则、常见问题、配置文档、历史修复案例"
            )

        return output.strip()


class Search_Core_RAG_Tool(BaseTool):
    """大集中系统知识库查询工具"""

    name: str = "search_core_knowledge"
    description: str = (
        "从大集中核心系统专属知识库检索相关信息。"
        "适用于查询账户处理流程、交易规则、存储过程说明、历史问题解决方案等。"
        "输入:query(查询问题)、top_k(返回数量,默认5)"
    )
    args_schema: Type[BaseModel] = RAGSearchInput

    def _run(self, query: str, top_k: int = 5) -> str:
        """查询大集中知识库(Mock实现)"""

        knowledge_base = {
            "账户处理": """
大集中账户处理核心流程:
1. 开户: PROC_OPEN_ACCOUNT → 生成账号 → 写入ACCT_MASTER
2. 交易: PROC_TXN_PROCESS → 检查余额 → 更新ACCT_BALANCE
3. 结息: PROC_ACCRUAL_CALC → 计算利息 → 写入ACCT_INTEREST
            """,
            "余额不一致": """
余额与流水不一致常见原因:
1. 批处理超时: 流水已写入,余额未更新
   - 检查日志: /logs/batch_YYYYMMDD.log
   - 解决: 执行余额重算脚本 /scripts/rebalance.sh

2. 并发冲突: 多笔交易同时更新同一账户
   - 检查锁表日志
   - 解决: 启用pessimistic locking

3. 存储过程版本问题: SP_EARLY_REPAY v2.3.1有bug
   - 升级到v2.3.2
            """,
            "存储过程": """
关键存储过程:
- SP_EARLY_REPAY: 提前还款处理
  版本: v2.3.2 (最新)
  已知问题: v2.3.1在部分还款时不更新accrual_flag

- SP_TXN_REVERSE: 交易冲正
  注意: 必须在T+1日前执行
            """,
            "历史案例": """
案例: 账户余额差3000元
排查: 
1. 查询交易流水: SELECT * FROM TXN_DETAIL WHERE account_no='xxx'
2. 发现TXN20231015_00089已入流水表
3. 检查余额表: 未更新
4. 查看日志: 批处理02:30超时
解决: 手工补录调整分录
            """,
        }

        results = []
        for category, content in knowledge_base.items():
            if any(kw in query for kw in category.split()) or any(
                kw in content for kw in query.split()[:3]
            ):
                results.append(f"**{category}**\n{content}")

        output = f"【大集中系统知识库】查询: {query}\n\n"
        if results:
            output += "\n\n".join(results[:top_k])
        else:
            output += (
                "未找到相关知识,建议查询: 账户处理、余额不一致、存储过程、历史案例"
            )

        return output.strip()


class Search_EAST_RAG_Tool(BaseTool):
    """EAST系统知识库查询工具"""

    name: str = "search_east_knowledge"
    description: str = (
        "从EAST数据报送系统专属知识库检索相关信息。"
        "适用于查询EAST数据标准、校验规则、枚举值映射、ETL流程等。"
        "输入:query(查询问题)、top_k(返回数量,默认5)"
    )
    args_schema: Type[BaseModel] = RAGSearchInput

    def _run(self, query: str, top_k: int = 5) -> str:
        """查询EAST知识库(Mock实现)"""

        knowledge_base = {
            "数据标准": """
EAST数据元标准(人民银行《金融业数据元规范》):
- 证件类型: 1-身份证, 2-护照, 3-军官证, 4-其他 (不允许0)
- 货币代码: CNY-人民币, USD-美元 (不使用RMB)
- 性别代码: 1-男, 2-女, 9-未说明
- 日期格式: YYYYMMDD
            """,
            "枚举值映射": """
常见枚举值映射错误及修复:
1. id_type=0 → 映射为4(其他)
2. currency='RMB' → 转换为'CNY'
3. gender='M' → 转换为'1', 'F'→'2'

ETL脚本中添加转换逻辑:
CASE WHEN id_type=0 THEN 4 ELSE id_type END AS id_type_std
            """,
            "校验规则": """
EAST校验常见错误:
- E_DT001: 日期格式错误 (应为YYYYMMDD)
- E_AM002: 金额字段为负值
- E_EN003: 枚举值不在允许范围内
- E_LEN004: 字段长度超限

修复方法:
1. 查看LOG文件定位具体记录
2. 使用data_cleansing.sql清洗脚本
3. 重新生成EAST文件
            """,
            "历史案例": """
案例: 客户信息表1250条id_type校验失败
原因: CRM系统历史数据id_type=0
修复:
UPDATE EAST_CUSTOMER_INFO 
SET id_type=4 
WHERE id_type=0 OR id_type IS NULL
            """,
        }

        results = []
        for category, content in knowledge_base.items():
            if any(kw in query for kw in category.split()) or any(
                kw in content for kw in query.split()[:3]
            ):
                results.append(f"**{category}**\n{content}")

        output = f"【EAST系统知识库】查询: {query}\n\n"
        if results:
            output += "\n\n".join(results[:top_k])
        else:
            output += (
                "未找到相关知识,建议查询: 数据标准、枚举值映射、校验规则、历史案例"
            )

        return output.strip()


class Search_YBT_RAG_Tool(BaseTool):
    """一表通系统知识库查询工具"""

    name: str = "search_yibiatong_knowledge"
    description: str = (
        "从一表通(统一报表)系统专属知识库检索相关信息。"
        "适用于查询报表计算逻辑、ETL任务配置、数据源说明、历史问题等。"
        "输入:query(查询问题)、top_k(返回数量,默认5)"
    )
    args_schema: Type[BaseModel] = RAGSearchInput

    def _run(self, query: str, top_k: int = 5) -> str:
        """查询一表通知识库(Mock实现)"""

        knowledge_base = {
            "报表架构": """
一表通数据流:
上游系统 → ETL任务 → ODS层 → DW层 → 报表层
- 大集中: 账户、交易数据 (每日02:00同步)
- 1104: 监管报表数据 (每月3日同步)
- EAST: 明细数据 (每周同步)
            """,
            "ETL任务": """
关键ETL任务:
1. JOB_DAILY_DEPOSIT_SYNC: 每日存款同步
   - 调度时间: 02:00
   - 数据源: 大集中ACCT_BALANCE
   - 常见错误: Source connection timeout

2. JOB_BRANCH_SUMMARY: 分行汇总
   - 调度时间: 04:00
   - 依赖: JOB_DAILY_DEPOSIT_SYNC
            """,
            "汇总逻辑": """
分行贷款余额汇总SQL:
SELECT branch_code, SUM(balance)
FROM ODS_LOAN
WHERE loan_type IN (01, 02, ..., 99)  -- 注意:包含表外贷款99
GROUP BY branch_code

常见错误:
- 遗漏某些贷款类型 → WHERE条件不完整
- 重复计算 → 未去重
            """,
            "历史案例": """
案例1: 存款总额显示为0
原因: ETL任务02:15超时,未同步数据
修复: 手工重跑 exec_etl_job.sh JOB_DAILY_DEPOSIT_SYNC 2023-10-31

案例2: 分行贷款少2亿
原因: SQL遗漏了loan_type=99(表外贷款)
修复: 更新汇总SQL,添加99至IN列表
            """,
        }

        results = []
        for category, content in knowledge_base.items():
            if any(kw in query for kw in category.split()) or any(
                kw in content for kw in query.split()[:3]
            ):
                results.append(f"**{category}**\n{content}")

        output = f"【一表通系统知识库】查询: {query}\n\n"
        if results:
            output += "\n\n".join(results[:top_k])
        else:
            output += "未找到相关知识,建议查询: 报表架构、ETL任务、汇总逻辑、历史案例"

        return output.strip()


# 导出RAG工具
def get_1104_rag_tools():
    """获取1104系统RAG工具"""
    return [Search_1104_RAG_Tool()]


def get_core_rag_tools():
    """获取大集中系统RAG工具"""
    return [Search_Core_RAG_Tool()]


def get_east_rag_tools():
    """获取EAST系统RAG工具"""
    return [Search_EAST_RAG_Tool()]


def get_ybt_rag_tools():
    """获取一表通系统RAG工具"""
    return [Search_YBT_RAG_Tool()]
