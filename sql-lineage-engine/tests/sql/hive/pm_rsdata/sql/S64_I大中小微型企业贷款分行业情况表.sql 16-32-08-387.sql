-- ============================================================
-- 文件名: S64_I大中小微型企业贷款分行业情况表.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 18 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'A%' THEN 'S64_I_1.1.D' --  1.1农、林、牧、渔业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'B%' THEN 'S64_I_1.2.D' --  1.2采矿业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'C%' THEN 'S64_I_1.3.D' --  1.3制造业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'D%' THEN 'S64_I_1.4.D' --  1.4电力、热力、燃气及水的生产和供应业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'E%' THEN 'S64_I_1.5.D' --  1.5建筑业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'F%' THEN 'S64_I_1.6.D' --  1.6批发和零售业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'G%' THEN 'S64_I_1.7.D' --  1.7交通运输、仓储和邮政业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'H%' THEN 'S64_I_1.8.D' --  1.8住宿和餐饮业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'I%' THEN 'S64_I_1.9.D' --  1.9信息传输、软件和信息技术服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'J%' THEN 'S64_I_1.10.D' --  1.10金融业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'K%' THEN 'S64_I_1.11.D' --  1.11房地产业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'L%' THEN 'S64_I_1.12.D' --  1.12租赁和商务服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'M%' THEN 'S64_I_1.13.D' --  1.13科学研究和技术服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'N%' THEN 'S64_I_1.14.D' --  1.14水利、环境和公共设施管理业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'O%' THEN 'S64_I_1.15.D' --  1.15居民服务、修理和其他服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'P%' THEN 'S64_I_1.16.D' --  1.16教育
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'Q%' THEN 'S64_I_1.17.D' --  1.17卫生和社会工作
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'R%' THEN 'S64_I_1.18.D' --  1.18文化、体育和娱乐业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'S%' THEN 'S64_I_1.19.D' --  1.19公共管理、社会保障和社会组织
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'T%' THEN 'S64_I_1.20.D' --  1.20国际组织
             END AS ITEM_NUM,
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) + NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP      -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') -- 增加农村合作社取数逻辑
         AND B.CORP_SCALE = 'T'
         AND T.ACCT_TYP NOT LIKE '0301%' -- 单独取直贴
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0;

--  单独取直贴
  INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17
       )
  SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN T.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_I_1.1.D' --  1.1农、林、牧、渔业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_I_1.2.D' --  1.2采矿业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_I_1.3.D' --  1.3制造业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_I_1.4.D' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_I_1.5.D' --  1.5建筑业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_I_1.6.D' --  1.6批发和零售业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_I_1.7.D' --  1.7交通运输、仓储和邮政业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_I_1.8.D' --  1.8住宿和餐饮业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_I_1.9.D' --  1.9信息传输、软件和信息技术服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_I_1.10.D' --  1.10金融业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_I_1.11.D' --  1.11房地产业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_I_1.12.D' --  1.12租赁和商务服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_I_1.13.D' --  1.13科学研究和技术服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_I_1.14.D' --  1.14水利、环境和公共设施管理业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_I_1.15.D' --  1.15居民服务、修理和其他服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_I_1.16.D' --  1.16教育
                  WHEN T.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_I_1.17.D' --  1.17卫生和社会工作
                  WHEN T.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_I_1.18.D' --  1.18文化、体育和娱乐业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_I_1.19.D' --  1.19公共管理、社会保障和社会组织
                  WHEN T.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_I_1.20.D' --  1.20国际组织
                   END AS ITEM_NUM,
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP      -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND B.CORP_SCALE = 'T'
         AND T.ITEM_CD IN ('13010101',
                           '13010102',
                           '13010103',
                           '13010104',
                           '13010105',
                           '13010106',
                           '13010401',
                           '13010402',
                           '13010403',
                           '13010404',
                           '13010405',
                           '13010406',
                           '13010407',
                           '13010408')
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0
) q_0
INSERT INTO `S64_I_1.7.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.10.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.13.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.16.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.8.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.3.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.12.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.11.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.5.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.1.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.15.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.9.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.17.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.14.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.18.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.4.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.6.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.2.D` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *;

-- ========== 逻辑组 1: 共 18 个指标 ==========
FROM (
SELECT 
            I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
            'CBRC'  AS SYS_NAM,  -- 模块简称
            'S6401' AS REP_NUM, -- 报表编号
            CASE WHEN T.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_I_1.1.G' --  1.1农、林、牧、渔业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_I_1.2.G' --  1.2采矿业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_I_1.3.G' --  1.3制造业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_I_1.4.G' --  1.4电力、热力、燃气及水的生产和供应业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_I_1.5.G' --  1.5建筑业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_I_1.6.G' --  1.6批发和零售业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_I_1.7.G' --  1.7交通运输、仓储和邮政业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_I_1.8.G' --  1.8住宿和餐饮业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_I_1.9.G' --  1.9信息传输、软件和信息技术服务业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_I_1.10.G' --  1.10金融业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_I_1.11.G' --  1.11房地产业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_I_1.12.G' --  1.12租赁和商务服务业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_I_1.13.G' --  1.13科学研究和技术服务业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_I_1.14.G' --  1.14水利、环境和公共设施管理业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_I_1.15.G' --  1.15居民服务、修理和其他服务业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_I_1.16.G' --  1.16教育
                 WHEN T.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_I_1.17.G' --  1.17卫生和社会工作
                 WHEN T.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_I_1.18.G' --  1.18文化、体育和娱乐业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_I_1.19.G' --  1.19公共管理、社会保障和社会组织
                 WHEN T.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_I_1.20.G' --  1.20国际组织                                                                          --  1.21买断式转贴现
                  END AS ITEM_NUM,
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) + NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             C.CORP_HOLD_TYPE,-- 行业类别
             C.CORP_SCALE,    -- 企业规模
             C.CUST_TYP,      -- 客户分类
             T.LOAN_PURPOSE_CD,-- 贷款投向
             P.OPERATE_CUST_TYPE -- 经营性客户类型
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND (P.OPERATE_CUST_TYPE = 'A' OR T.ACCT_TYP = '3' OR C.CUST_TYP = '3')
         AND T.ACCT_TYP LIKE '0102%' -- 个人经营性去掉贴现数据
         AND SUBSTR(T.LOAN_PURPOSE_CD, 1, 1) IN ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T')
         AND T.LOAN_STOCKEN_DATE IS NULL  --  资产未转让
         AND T.LOAN_ACCT_BAL <> 0
) q_1
INSERT INTO `S64_I_1.10.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.5.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.15.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.2.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.13.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.4.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.11.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.14.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.1.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.12.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.8.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.18.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.9.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.6.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.17.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.16.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.3.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.7.G` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *;

-- ========== 逻辑组 2: 共 14 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN B.CORP_BUSINSESS_TYPE LIKE 'A%' THEN 'S64_I_1.1.A' --  1.1农、林、牧、渔业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'B%' THEN 'S64_I_1.2.A' --  1.2采矿业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'C%' THEN 'S64_I_1.3.A' --  1.3制造业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'D%' THEN 'S64_I_1.4.A' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'E%' THEN 'S64_I_1.5.A' --  1.5建筑业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'F%' THEN 'S64_I_1.6.A' --  1.6批发和零售业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'G%' THEN 'S64_I_1.7.A' --  1.7交通运输、仓储和邮政业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'H%' THEN 'S64_I_1.8.A' --  1.8住宿和餐饮业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'I%' THEN 'S64_I_1.9.A' --  1.9信息传输、软件和信息技术服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'J%' THEN 'S64_I_1.10.A' --  1.10金融业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'K%' THEN 'S64_I_1.11.A' --  1.11房地产业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'L%' THEN 'S64_I_1.12.A' --  1.12租赁和商务服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'M%' THEN 'S64_I_1.13.A' --  1.13科学研究和技术服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'N%' THEN 'S64_I_1.14.A' --  1.14水利、环境和公共设施管理业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'O%' THEN 'S64_I_1.15.A' --  1.15居民服务、修理和其他服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'P%' THEN 'S64_I_1.16.A' --  1.16教育
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'Q%' THEN 'S64_I_1.17.A' --  1.17卫生和社会工作
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'R%' THEN 'S64_I_1.18.A' --  1.18文化、体育和娱乐业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'S%' THEN 'S64_I_1.19.A' --  1.19公共管理、社会保障和社会组织
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'T%' THEN 'S64_I_1.20.A' --  1.20国际组织
                   END AS ITEM_NUM,
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) + NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)  AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --ALTER BY WJB 20220518 增加农村合作社取数逻辑
         AND B.CORP_SCALE = 'B'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '0301%' -- 单独取直贴
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0;

--  单独取直贴
   INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17
       )
  SELECT 
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN A.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_I_1.1.A' --  1.1农、林、牧、渔业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_I_1.2.A' --  1.2采矿业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_I_1.3.A' --  1.3制造业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_I_1.4.A' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_I_1.5.A' --  1.5建筑业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_I_1.6.A' --  1.6批发和零售业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_I_1.7.A' --  1.7交通运输、仓储和邮政业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_I_1.8.A' --  1.8住宿和餐饮业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_I_1.9.A' --  1.9信息传输、软件和信息技术服务业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_I_1.10.A' --  1.10金融业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_I_1.11.A' --  1.11房地产业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_I_1.12.A' --  1.12租赁和商务服务业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_I_1.13.A' --  1.13科学研究和技术服务业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_I_1.14.A' --  1.14水利、环境和公共设施管理业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_I_1.15.A' --  1.15居民服务、修理和其他服务业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_I_1.16.A' --  1.16教育
                  WHEN A.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_I_1.17.A' --  1.17卫生和社会工作
                  WHEN A.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_I_1.18.A' --  1.18文化、体育和娱乐业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_I_1.19.A' --  1.19公共管理、社会保障和社会组织
                  WHEN A.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_I_1.20.A' --  1.20国际组织
                  END AS ITEM_NUM,
             (NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0)) AS LOAN_ACCT_BAL_RMB,
             A.ACCT_NUM,      -- 合同号
             A.LOAN_NUM,      -- 借据号
             A.CUST_ID,       -- 客户号
             A.ITEM_CD,       -- 科目号
             A.CURR_CD,       -- 币种
             A.DRAWDOWN_AMT,  -- 放款金额
             A.DRAWDOWN_DT,   -- 放款日期
             A.MATURITY_DT,   -- 原始到期日期
             A.ACCT_TYP,      -- 账户类型
             A.ACCT_TYP_DESC, -- 账户类型说明
             A.ACCT_STS,      -- 账户状态
             A.CANCEL_FLG,    -- 核销标志
             A.LOAN_STOCKEN_DATE, -- 证券化日期
             A.JBYG_ID,       -- 经办员工ID
             C.CORP_HOLD_TYPE,-- 行业类别
             C.CORP_SCALE,    -- 企业规模
             C.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('13010101',
                           '13010102',
                           '13010103',
                           '13010104',
                           '13010105',
                           '13010106',
                           '13010401',
                           '13010402',
                           '13010403',
                           '13010404',
                           '13010405',
                           '13010406',
                           '13010407',
                           '13010408')
         AND C.CORP_SCALE = 'B'
         AND A.CANCEL_FLG = 'N'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.LOAN_STOCKEN_DATE IS NULL   --  资产未转让
         AND A.LOAN_ACCT_BAL <> 0
) q_2
INSERT INTO `S64_I_1.11.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.17.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.4.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.9.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.5.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.3.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.6.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.18.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.12.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.2.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.7.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.8.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.1.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.14.A` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *;

-- ========== 逻辑组 3: 共 17 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN B.CORP_BUSINSESS_TYPE LIKE 'A%' THEN 'S64_I_1.1.B' --  1.1农、林、牧、渔业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'B%' THEN 'S64_I_1.2.B' --  1.2采矿业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'C%' THEN 'S64_I_1.3.B' --  1.3制造业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'D%' THEN 'S64_I_1.4.B' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'E%' THEN 'S64_I_1.5.B' --  1.5建筑业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'F%' THEN 'S64_I_1.6.B' --  1.6批发和零售业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'G%' THEN 'S64_I_1.7.B' --  1.7交通运输、仓储和邮政业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'H%' THEN 'S64_I_1.8.B' --  1.8住宿和餐饮业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'I%' THEN 'S64_I_1.9.B' --  1.9信息传输、软件和信息技术服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'J%' THEN 'S64_I_1.10.B' --  1.10金融业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'K%' THEN 'S64_I_1.11.B' --  1.11房地产业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'L%' THEN 'S64_I_1.12.B' --  1.12租赁和商务服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'M%' THEN 'S64_I_1.13.B' --  1.13科学研究和技术服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'N%' THEN 'S64_I_1.14.B' --  1.14水利、环境和公共设施管理业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'O%' THEN 'S64_I_1.15.B' --  1.15居民服务、修理和其他服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'P%' THEN 'S64_I_1.16.B' --  1.16教育
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'Q%' THEN 'S64_I_1.17.B' --  1.17卫生和社会工作
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'R%' THEN 'S64_I_1.18.B' --  1.18文化、体育和娱乐业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'S%' THEN 'S64_I_1.19.B' --  1.19公共管理、社会保障和社会组织
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'T%' THEN 'S64_I_1.20.B' --  1.20国际组织
                   END AS ITEM_NUM,
             (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) + NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP      -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --  增加农村合作社取数逻辑
         AND B.CORP_SCALE = 'M'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '0301%' -- 单独取直贴
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0;

-- 单独取直贴
  INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17
       )
  SELECT 
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN A.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_I_1.1.B' --  1.1农、林、牧、渔业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_I_1.2.B' --  1.2采矿业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_I_1.3.B' --  1.3制造业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_I_1.4.B' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_I_1.5.B' --  1.5建筑业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_I_1.6.B' --  1.6批发和零售业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_I_1.7.B' --  1.7交通运输、仓储和邮政业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_I_1.8.B' --  1.8住宿和餐饮业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_I_1.9.B' --  1.9信息传输、软件和信息技术服务业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_I_1.10.B' --  1.10金融业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_I_1.11.B' --  1.11房地产业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_I_1.12.B' --  1.12租赁和商务服务业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_I_1.13.B' --  1.13科学研究和技术服务业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_I_1.14.B' --  1.14水利、环境和公共设施管理业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_I_1.15.B' --  1.15居民服务、修理和其他服务业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_I_1.16.B' --  1.16教育
                  WHEN A.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_I_1.17.B' --  1.17卫生和社会工作
                  WHEN A.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_I_1.18.B' --  1.18文化、体育和娱乐业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_I_1.19.B' --  1.19公共管理、社会保障和社会组织
                  WHEN A.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_I_1.20.B' --  1.20国际组织
                   END AS ITEM_NUM,
             (NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0)) AS LOAN_ACCT_BAL_RMB,
             A.ACCT_NUM,      -- 合同号
             A.LOAN_NUM,      -- 借据号
             A.CUST_ID,       -- 客户号
             A.ITEM_CD,       -- 科目号
             A.CURR_CD,       -- 币种
             A.DRAWDOWN_AMT,  -- 放款金额
             A.DRAWDOWN_DT,   -- 放款日期
             A.MATURITY_DT,   -- 原始到期日期
             A.ACCT_TYP,      -- 账户类型
             A.ACCT_TYP_DESC, -- 账户类型说明
             A.ACCT_STS,      -- 账户状态
             A.CANCEL_FLG,    -- 核销标志
             A.LOAN_STOCKEN_DATE, -- 证券化日期
             A.JBYG_ID,       -- 经办员工ID
             C.CORP_HOLD_TYPE,-- 行业类别
             C.CORP_SCALE,    -- 企业规模
             C.CUST_TYP      -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE C.CORP_SCALE = 'M'
         AND A.CANCEL_FLG = 'N'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ITEM_CD IN ('13010101',
                           '13010102',
                           '13010103',
                           '13010104',
                           '13010105',
                           '13010106',
                           '13010401',
                           '13010402',
                           '13010403',
                           '13010404',
                           '13010405',
                           '13010406',
                           '13010407',
                           '13010408')
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL  -- 资产未转让
         AND A.LOAN_ACCT_BAL <> 0
) q_3
INSERT INTO `S64_I_1.14.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.18.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.2.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.17.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.13.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.12.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.1.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.9.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.4.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.16.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.11.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.3.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.8.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.5.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.15.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.6.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.7.B` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *;

-- ========== 逻辑组 4: 共 4 个指标 ==========
FROM (
SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN T.CORP_SCALE = 'B' THEN 'S64_I_6.1.A.2020'
                  WHEN T.CORP_SCALE = 'M' THEN 'S64_I_6.1.B.2020'
                  WHEN T.CORP_SCALE = 'S' THEN 'S64_I_6.1.C.2020'
                  WHEN T.CORP_SCALE = 'T' THEN 'S64_I_6.1.D.2020'
                  END AS ITEM_NUM,
             1 AS LOAN_ACCT_BAL_RMB,
             T.CUST_ID,
             T.CUST_NAM
        FROM (SELECT T.ORG_NUM,
                     T.CUST_ID,
                     T.LOAN_NUM,
                     T.DRAWDOWN_DT,
                     T.DRAWDOWN_AMT,
                     T.CURR_CD,
                     C.CORP_SCALE,
                     C.CUST_NAM,
                     ROW_NUMBER() OVER(PARTITION BY T.CUST_ID ORDER BY T.DRAWDOWN_DT,T.LOAN_NUM) RNK
                FROM SMTMODS_L_ACCT_LOAN T
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON T.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.DATA_DATE = I_DATADATE
                 AND U.BASIC_CCY = T.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE T.DATA_DATE = I_DATADATE
                 AND LENGTHB(T.ACCT_NUM) < 36
                 AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
                 AND T.IS_FIRST_LOAN_TAG = 'Y' --是否首次贷款
                 AND SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0')
                 AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4)) T
               WHERE T.RNK=1
) q_4
INSERT INTO `S64_I_6.1.A.2020` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_20)
SELECT *
INSERT INTO `S64_I_6.1.B.2020` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_20)
SELECT *
INSERT INTO `S64_I_6.1.C.2020` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_20)
SELECT *
INSERT INTO `S64_I_6.1.D.2020` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_20)
SELECT *;

-- ========== 逻辑组 5: 共 18 个指标 ==========
FROM (
SELECT 
            I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
            'CBRC'  AS SYS_NAM,  -- 模块简称
            'S6401' AS REP_NUM, -- 报表编号
            CASE WHEN T.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_I_1.1.H' --  1.1农、林、牧、渔业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_I_1.2.H' --  1.2采矿业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_I_1.3.H' --  1.3制造业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_I_1.4.H' --  1.4电力、热力、燃气及水的生产和供应业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_I_1.5.H' --  1.5建筑业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_I_1.6.H' --  1.6批发和零售业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_I_1.7.H' --  1.7交通运输、仓储和邮政业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_I_1.8.H' --  1.8住宿和餐饮业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_I_1.9.H' --  1.9信息传输、软件和信息技术服务业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_I_1.10.H' --  1.10金融业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_I_1.11.H' --  1.11房地产业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_I_1.12.H' --  1.12租赁和商务服务业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_I_1.13.H' --  1.13科学研究和技术服务业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_I_1.14.H' --  1.14水利、环境和公共设施管理业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_I_1.15.H' --  1.15居民服务、修理和其他服务业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_I_1.16.H' --  1.16教育
                 WHEN T.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_I_1.17.H' --  1.17卫生和社会工作
                 WHEN T.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_I_1.18.H' --  1.18文化、体育和娱乐业
                 WHEN T.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_I_1.19.H' --  1.19公共管理、社会保障和社会组织
                 WHEN T.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_I_1.20.H' --  1.20国际组织
                  END AS ITEM_NUM,
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) + NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)  AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             NULL,            -- 行业类别
             NULL,            -- 企业规模
             NULL,            -- 客户分类
             T.LOAN_PURPOSE_CD,-- 贷款投向
             B.OPERATE_CUST_TYPE -- 经营性客户类型
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_P B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND B.OPERATE_CUST_TYPE = 'B'
         AND T.ACCT_TYP LIKE '0102%' --SHIWENBO BY 20170318-GRJYX 个人经营性去掉贴现数据
         AND SUBSTR(T.LOAN_PURPOSE_CD, 1, 1) IN ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T')
         AND T.LOAN_STOCKEN_DATE IS NULL -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0
) q_5
INSERT INTO `S64_I_1.5.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.11.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.17.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.12.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.4.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.16.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.2.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.7.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.13.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.1.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.10.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.8.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.3.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.9.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.15.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.14.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.18.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *
INSERT INTO `S64_I_1.6.H` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19)
SELECT *;

-- ========== 逻辑组 6: 共 18 个指标 ==========
FROM (
SELECT 
            I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
            'CBRC'  AS SYS_NAM,  -- 模块简称
            'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN T.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_I_1.1.F' --  1.1农、林、牧、渔业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_I_1.2.F' --  1.2采矿业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_I_1.3.F' --  1.3制造业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_I_1.4.F' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_I_1.5.F' --  1.5建筑业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_I_1.6.F' --  1.6批发和零售业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_I_1.7.F' --  1.7交通运输、仓储和邮政业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_I_1.8.F' --  1.8住宿和餐饮业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_I_1.9.F' --  1.9信息传输、软件和信息技术服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_I_1.10.F' --  1.10金融业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_I_1.11.F' --  1.11房地产业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_I_1.12.F' --  1.12租赁和商务服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_I_1.13.F' --  1.13科学研究和技术服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_I_1.14.F' --  1.14水利、环境和公共设施管理业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_I_1.15.F' --  1.15居民服务、修理和其他服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_I_1.16.F' --  1.16教育
                  WHEN T.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_I_1.17.F' --  1.17卫生和社会工作
                  WHEN T.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_I_1.18.F' --  1.18文化、体育和娱乐业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_I_1.19.F' --  1.19公共管理、社会保障和社会组织
                  WHEN T.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_I_1.20.F' --  1.20国际组织
                   END AS ITEM_NUM,
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) + NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP,      -- 客户分类
             T.LOAN_PURPOSE_CD-- 贷款投向
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND T.ACCT_TYP LIKE '0102%' --SHIWENBO BY 20170318-GRJYX 个人经营性去掉贴现数据
         AND SUBSTR(T.LOAN_PURPOSE_CD, 1, 1) IN ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T')
         AND T.LOAN_STOCKEN_DATE IS NULL --  资产未转让
         AND T.LOAN_ACCT_BAL <> 0
) q_6
INSERT INTO `S64_I_1.2.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.13.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.17.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.7.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.1.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.10.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.3.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.4.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.5.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.11.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.9.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.16.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.14.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.15.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.8.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.12.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.6.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S64_I_1.18.F` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18)
SELECT *;

-- ========== 逻辑组 7: 共 18 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN B.CORP_BUSINSESS_TYPE LIKE 'A%' THEN 'S64_I_1.1.C' --  1.1农、林、牧、渔业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'B%' THEN 'S64_I_1.2.C' --  1.2采矿业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'C%' THEN 'S64_I_1.3.C' --  1.3制造业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'D%' THEN 'S64_I_1.4.C' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'E%' THEN 'S64_I_1.5.C' --  1.5建筑业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'F%' THEN 'S64_I_1.6.C' --  1.6批发和零售业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'G%' THEN 'S64_I_1.7.C' --  1.7交通运输、仓储和邮政业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'H%' THEN 'S64_I_1.8.C' --  1.8住宿和餐饮业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'I%' THEN 'S64_I_1.9.C' --  1.9信息传输、软件和信息技术服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'J%' THEN 'S64_I_1.10.C' --  1.10金融业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'K%' THEN 'S64_I_1.11.C' --  1.11房地产业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'L%' THEN 'S64_I_1.12.C' --  1.12租赁和商务服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'M%' THEN 'S64_I_1.13.C' --  1.13科学研究和技术服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'N%' THEN 'S64_I_1.14.C' --  1.14水利、环境和公共设施管理业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'O%' THEN 'S64_I_1.15.C' --  1.15居民服务、修理和其他服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'P%' THEN 'S64_I_1.16.C' --  1.16教育
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'Q%' THEN 'S64_I_1.17.C' --  1.17卫生和社会工作
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'R%' THEN 'S64_I_1.18.C' --  1.18文化、体育和娱乐业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'S%' THEN 'S64_I_1.19.C' --  1.19公共管理、社会保障和社会组织
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'T%' THEN 'S64_I_1.20.C' --  1.20国际组织
                   END AS ITEM_NUM,
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) + NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)  AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP      -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') -- 增加农村合作社取数逻辑
         AND B.CORP_SCALE = 'S'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '0301%' -- 单独取直贴
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0;

-- 单独取直贴
  INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17
       )
  SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN T.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_I_1.1.C' --  1.1农、林、牧、渔业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_I_1.2.C' --  1.2采矿业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_I_1.3.C' --  1.3制造业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_I_1.4.C' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_I_1.5.C' --  1.5建筑业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_I_1.6.C' --  1.6批发和零售业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_I_1.7.C' --  1.7交通运输、仓储和邮政业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_I_1.8.C' --  1.8住宿和餐饮业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_I_1.9.C' --  1.9信息传输、软件和信息技术服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_I_1.10.C' --  1.10金融业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_I_1.11.C' --  1.11房地产业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_I_1.12.C' --  1.12租赁和商务服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_I_1.13.C' --  1.13科学研究和技术服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_I_1.14.C' --  1.14水利、环境和公共设施管理业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_I_1.15.C' --  1.15居民服务、修理和其他服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_I_1.16.C' --  1.16教育
                  WHEN T.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_I_1.17.C' --  1.17卫生和社会工作
                  WHEN T.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_I_1.18.C' --  1.18文化、体育和娱乐业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_I_1.19.C' --  1.19公共管理、社会保障和社会组织
                  WHEN T.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_I_1.20.C' --  1.20国际组织
                   END AS ITEM_NUM,
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP      -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND B.CORP_SCALE = 'S'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ITEM_CD IN ('13010101',
                           '13010102',
                           '13010103',
                           '13010104',
                           '13010105',
                           '13010106',
                           '13010401',
                           '13010402',
                           '13010403',
                           '13010404',
                           '13010405',
                           '13010406',
                           '13010407',
                           '13010408')
       AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       AND T.LOAN_ACCT_BAL <> 0
) q_7
INSERT INTO `S64_I_1.8.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.3.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.18.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.7.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.11.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.5.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.14.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.16.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.17.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.1.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.12.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.15.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.10.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.9.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.13.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.6.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.4.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_1.2.C` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *;

-- ========== 逻辑组 8: 共 18 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN T.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_I_1.1.E.2022' --  1.1农、林、牧、渔业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_I_1.2.E.2022' --  1.2采矿业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_I_1.3.E.2022' --  1.3制造业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_I_1.4.E.2022' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_I_1.5.E.2022' --  1.5建筑业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_I_1.6.E.2022' --  1.6批发和零售业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_I_1.7.E.2022' --  1.7交通运输、仓储和邮政业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_I_1.8.E.2022' --  1.8住宿和餐饮业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_I_1.9.E.2022' --  1.9信息传输、软件和信息技术服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_I_1.10.E.2022' --  1.10金融业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_I_1.11.E.2022' --  1.11房地产业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_I_1.12.E.2022' --  1.12租赁和商务服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_I_1.13.E.2022' --  1.13科学研究和技术服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_I_1.14.E.2022' --  1.14水利、环境和公共设施管理业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_I_1.15.E.2022' --  1.15居民服务、修理和其他服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_I_1.16.E.2022' --  1.16教育
                  WHEN T.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_I_1.17.E.2022' --  1.17卫生和社会工作
                  WHEN T.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_I_1.18.E.2022' --  1.18文化、体育和娱乐业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_I_1.19.E.2022' --  1.19公共管理、社会保障和社会组织
                  WHEN T.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_I_1.20.E.2022' --  1.20国际组织
                   END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * TT.CCY_RATE AS LOAN_ACCT_BAL,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             P.INDUSTRY_TYPE, -- 行业类别
             P.COM_SCALE,     -- 企业规模
             NULL,            -- 客户分类
             T.LOAN_PURPOSE_CD,-- 贷款投向
             P.OPERATE_CUST_TYPE, -- 经营性客户类型
             B.FACILITY_AMT   -- 授信金额
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON T.DATA_DATE = TT.DATA_DATE
         AND TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6401_CREDITLINE_HZ B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL <> 0 --贷款余额
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND SUBSTR(t.ITEM_CD, 1, 6) not IN ('130102', '130105') --转贴现 --不含票据转贴现
         AND B.FACILITY_AMT <= 10000000 -- 单户授信总额1000万元及以下
         AND ((T.ACCT_TYP LIKE '0102%' -- 个人经营性标识
             OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND T.ITEM_CD LIKE '1305%')) -- 个体工商户贸易融资
             AND P.OPERATE_CUST_TYPE IN ('A', 'B'))
         AND T.LOAN_STOCKEN_DATE IS NULL -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0;

-- 一部分个体工商户放到了cust_c里

  INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN T.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_I_1.1.E.2022' --  1.1农、林、牧、渔业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_I_1.2.E.2022' --  1.2采矿业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_I_1.3.E.2022' --  1.3制造业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_I_1.4.E.2022' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_I_1.5.E.2022' --  1.5建筑业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_I_1.6.E.2022' --  1.6批发和零售业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_I_1.7.E.2022' --  1.7交通运输、仓储和邮政业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_I_1.8.E.2022' --  1.8住宿和餐饮业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_I_1.9.E.2022' --  1.9信息传输、软件和信息技术服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_I_1.10.E.2022' --  1.10金融业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_I_1.11.E.2022' --  1.11房地产业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_I_1.12.E.2022' --  1.12租赁和商务服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_I_1.13.E.2022' --  1.13科学研究和技术服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_I_1.14.E.2022' --  1.14水利、环境和公共设施管理业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_I_1.15.E.2022' --  1.15居民服务、修理和其他服务业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_I_1.16.E.2022' --  1.16教育
                  WHEN T.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_I_1.17.E.2022' --  1.17卫生和社会工作
                  WHEN T.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_I_1.18.E.2022' --  1.18文化、体育和娱乐业
                  WHEN T.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_I_1.19.E.2022' --  1.19公共管理、社会保障和社会组织
                  WHEN T.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_I_1.20.E.2022' --  1.20国际组织
                   END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * TT.CCY_RATE  AS LOAN_ACCT_BAL,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             P.CORP_HOLD_TYPE,-- 行业类别
             P.CORP_SCALE,    -- 企业规模
             P.CUST_TYP,       -- 客户分类
             B.FACILITY_AMT
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON T.DATA_DATE = TT.DATA_DATE
         AND TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6401_CREDITLINE_HZ B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C P
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL <> 0 --贷款余额
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND SUBSTR(t.ITEM_CD, 1, 6) not IN ('130102', '130105') --转贴现 --不含票据转贴现
         AND B.FACILITY_AMT <= 10000000 --单户授信总额1000万元及以下
         AND ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND T.ITEM_CD LIKE '1305%')) -- 个体工商户贸易融资
             AND P.CUST_TYP IN ('3'))
         AND T.LOAN_STOCKEN_DATE IS NULL -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0;

INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17
       )
     SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN C.CORP_BUSINSESS_TYPE LIKE 'A%' THEN 'S64_I_1.1.E.2022' --  1.1农、林、牧、渔业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'B%' THEN 'S64_I_1.2.E.2022' --  1.2采矿业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'C%' THEN 'S64_I_1.3.E.2022' --  1.3制造业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'D%' THEN 'S64_I_1.4.E.2022' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'E%' THEN 'S64_I_1.5.E.2022' --  1.5建筑业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'F%' THEN 'S64_I_1.6.E.2022' --  1.6批发和零售业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'G%' THEN 'S64_I_1.7.E.2022' --  1.7交通运输、仓储和邮政业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'H%' THEN 'S64_I_1.8.E.2022' --  1.8住宿和餐饮业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'I%' THEN 'S64_I_1.9.E.2022' --  1.9信息传输、软件和信息技术服务业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'J%' THEN 'S64_I_1.10.E.2022' --  1.10金融业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'K%' THEN 'S64_I_1.11.E.2022' --  1.11房地产业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'L%' THEN 'S64_I_1.12.E.2022' --  1.12租赁和商务服务业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'M%' THEN 'S64_I_1.13.E.2022' --  1.13科学研究和技术服务业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'N%' THEN 'S64_I_1.14.E.2022' --  1.14水利、环境和公共设施管理业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'O%' THEN 'S64_I_1.15.E.2022' --  1.15居民服务、修理和其他服务业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'P%' THEN 'S64_I_1.16.E.2022' --  1.16教育
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'Q%' THEN 'S64_I_1.17.E.2022' --  1.17卫生和社会工作
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'R%' THEN 'S64_I_1.18.E.2022' --  1.18文化、体育和娱乐业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'S%' THEN 'S64_I_1.19.E.2022' --  1.19公共管理、社会保障和社会组织
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'T%' THEN 'S64_I_1.20.E.2022' --  1.20国际组织
                END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * TT.CCY_RATE AS LOAN_ACCT_BAL,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             C.CORP_HOLD_TYPE,-- 行业类别
             C.CORP_SCALE,    -- 企业规模
             C.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON T.DATA_DATE = TT.DATA_DATE
         AND TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6401_CREDITLINE_HZ B --ALTER BY 20241224 JLBA202412040012
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL <> 0 --贷款余额
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND SUBSTR(t.ITEM_CD, 1, 6) not IN ('130102', '130105') --转贴现 --不含票据转贴现
         AND B.FACILITY_AMT <= 10000000 --单户授信总额1000万元及以下
         AND C.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(C.CUST_TYP, 0, 1) IN ('1', '0') -- 取企业 企业规模中含事业单位、民办非企业贷款
         AND T.LOAN_STOCKEN_DATE IS NULL
) q_8
INSERT INTO `S64_I_1.7.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.6.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.15.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.13.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.18.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.4.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.5.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.14.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.8.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.16.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.1.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.10.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.12.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.17.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.11.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.3.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.2.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *
INSERT INTO `S64_I_1.9.E.2022` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17,
       COL_18,
       COL_19,
       COL_21)
SELECT *;

-- ========== 逻辑组 9: 共 3 个指标 ==========
FROM (
SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN T.CORP_SCALE = 'B' THEN 'S64_I_6.1.1.A.2023'
                  WHEN T.CORP_SCALE = 'M' THEN 'S64_I_6.1.1.B.2023'
                  WHEN T.CORP_SCALE = 'S' THEN 'S64_I_6.1.1.C.2023'
                  WHEN T.CORP_SCALE = 'T' THEN 'S64_I_6.1.1.D.2023'
             END AS ITEM_NUM,
             1 AS LOAN_ACCT_BAL_RMB,
             T.CUST_ID,
             T.CUST_NAM
        FROM (SELECT T.ORG_NUM,
                     T.CUST_ID,
                     T.LOAN_NUM,
                     T.DRAWDOWN_DT,
                     T.DRAWDOWN_AMT,
                     T.CURR_CD,
                     C.CORP_SCALE,
                     C.CUST_NAM,
                     ROW_NUMBER() OVER(PARTITION BY T.CUST_ID ORDER BY T.DRAWDOWN_DT,T.LOAN_NUM) RNK
                FROM SMTMODS_L_ACCT_LOAN T
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON T.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.DATA_DATE = I_DATADATE
                 AND U.BASIC_CCY = T.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               INNER JOIN (SELECT t.LOAN_NUM, t.SNDKFL, t.IF_CT_UA, t.AGR_USE_ADDL
                             FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                            WHERE T.DATA_DATE = I_DATADATE
                              AND SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103', 'P_201')
                UNION ALL
                           SELECT t.LOAN_NUM, t.SNDKFL, t.IF_CT_UA, t.AGR_USE_ADDL
                             FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                            WHERE T.DATA_DATE = I_DATADATE
                              AND SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103', 'P_201')
                UNION ALL
                           SELECT A.LOAN_NUM, A.SNDKFL, A.IF_CT_UA, A.AGR_USE_ADDL
                             FROM SMTMODS_V_PUB_IDX_DK_DGSNDK A --对公涉农
                             LEFT JOIN SMTMODS_L_ACCT_LOAN B
                               ON A.LOAN_NUM = B.LOAN_NUM
                              AND A.DATA_DATE = B.DATA_DATE
                            WHERE A.DATA_DATE = I_DATADATE
                              AND (A.SNDKFL LIKE 'C_301%' OR
                                  SUBSTR(A.SNDKFL, 0, 5) = 'C_401' OR
                                  A.SNDKFL LIKE 'C_1%' OR
                                  SUBSTR(A.SNDKFL, 0, 3) = 'C_2' OR
                                  ((A.SNDKFL LIKE 'C_402%' OR A.SNDKFL LIKE 'C_302%') AND
                                  (CASE WHEN SUBSTR(A.SNDKFL, 0, 7) IN  ('C_40202', 'C_30202') AND
                                        (NVL(A.AGR_USE_ADDL, '#') IN ('05') OR  NVL(B.LOAN_PURPOSE_CD, '#') IN  ('A0514', 'A0523')) THEN 1 ELSE  0 END) = 0))) F
                  ON T.LOAN_NUM = F.LOAN_NUM
               WHERE T.DATA_DATE = I_DATADATE
                 AND LENGTHB(T.ACCT_NUM) < 36
                 AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
                 AND T.IS_FIRST_LOAN_TAG = 'Y' --是否首次贷款
                 AND SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0')
                 AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4)) T
               WHERE T.RNK=1
) q_9
INSERT INTO `S64_I_6.1.1.C.2023` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_20)
SELECT *
INSERT INTO `S64_I_6.1.1.D.2023` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_20)
SELECT *
INSERT INTO `S64_I_6.1.1.A.2023` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_20)
SELECT *;

-- ========== 逻辑组 10: 共 3 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN T.CORP_SCALE = 'B' THEN 'S64_I_6.2.1.A.2023'
                  WHEN T.CORP_SCALE = 'M' THEN 'S64_I_6.2.1.B.2023'
                  WHEN T.CORP_SCALE = 'S' THEN 'S64_I_6.2.1.C.2023'
                  WHEN T.CORP_SCALE = 'T' THEN 'S64_I_6.2.1.D.2023'
                   END AS ITEM_NUM,
             T.DRAWDOWN_AMT AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             T.CORP_HOLD_TYPE,-- 行业类别
             T.CORP_SCALE,    -- 企业规模
             T.CUST_TYP       -- 客户分类
       FROM (SELECT
             T.ORG_NUM,
             T.DEPARTMENTD,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             NVL(T.DRAWDOWN_AMT * U.CCY_RATE, 0)DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             C.CORP_HOLD_TYPE,-- 行业类别
             C.CORP_SCALE,    -- 企业规模
             C.CUST_TYP,      -- 客户分类
             ROW_NUMBER() OVER(PARTITION BY T.CUST_ID ORDER BY T.DRAWDOWN_DT,T.LOAN_NUM) RNK
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        INNER JOIN
                  (SELECT t.LOAN_NUM, t.SNDKFL, t.IF_CT_UA, t.AGR_USE_ADDL
                  FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                 WHERE T.DATA_DATE = I_DATADATE
                   AND SUBSTR(T.SNDKFL, 1, 5) IN
                       ('P_101', 'P_102', 'P_103', 'P_201')
                UNION ALL
                SELECT t.LOAN_NUM, t.SNDKFL, t.IF_CT_UA, t.AGR_USE_ADDL
                  FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                 WHERE T.DATA_DATE = I_DATADATE
                   AND SUBSTR(T.SNDKFL, 1, 5) IN
                       ('P_101', 'P_102', 'P_103', 'P_201')
                UNION ALL
                SELECT A.LOAN_NUM, A.SNDKFL, A.IF_CT_UA, A.AGR_USE_ADDL
                  FROM SMTMODS_V_PUB_IDX_DK_DGSNDK A --对公涉农
                  LEFT JOIN SMTMODS_L_ACCT_LOAN B
                    ON A.LOAN_NUM = B.LOAN_NUM
                   AND A.DATA_DATE = B.DATA_DATE
                 WHERE A.DATA_DATE = I_DATADATE
                   AND (A.SNDKFL LIKE 'C_301%' OR
                       SUBSTR(A.SNDKFL, 0, 5) = 'C_401' OR
                       A.SNDKFL LIKE 'C_1%' or
                       SUBSTR(A.SNDKFL, 0, 3) = 'C_2' OR
                       ((A.SNDKFL LIKE 'C_402%' or A.SNDKFL LIKE 'C_302%') AND
                       (CASE  WHEN SUBSTR(A.SNDKFL, 0, 7) IN  ('C_40202', 'C_30202') AND
                              (NVL(A.AGR_USE_ADDL, '#') IN ('05') OR  NVL(B.LOAN_PURPOSE_CD, '#') IN  ('A0514', 'A0523')) THEN
                          1  ELSE  0 END) = 0))) F
          ON T.LOAN_NUM = F.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.IS_FIRST_LOAN_TAG = 'Y' --是否首次贷款
         AND SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0')
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) ) T
       WHERE T.RNK=1
) q_10
INSERT INTO `S64_I_6.2.1.D.2023` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_6.2.1.A.2023` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_6.2.1.C.2023` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *;

-- ========== 逻辑组 11: 共 4 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             CASE WHEN T.CORP_SCALE = 'B' THEN 'S64_I_6.2.A.2020'
                  WHEN T.CORP_SCALE = 'M' THEN 'S64_I_6.2.B.2020'
                  WHEN T.CORP_SCALE = 'S' THEN 'S64_I_6.2.C.2020'
                  WHEN T.CORP_SCALE = 'T' THEN 'S64_I_6.2.D.2020'
             END AS ITEM_NUM,
             T.DRAWDOWN_AMT AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      -- 合同号
             T.LOAN_NUM,      -- 借据号
             T.CUST_ID,       -- 客户号
             T.ITEM_CD,       -- 科目号
             T.CURR_CD,       -- 币种
             T.DRAWDOWN_AMT,  -- 放款金额
             T.DRAWDOWN_DT,   -- 放款日期
             T.MATURITY_DT,   -- 原始到期日期
             T.ACCT_TYP,      -- 账户类型
             T.ACCT_TYP_DESC, -- 账户类型说明
             T.ACCT_STS,      -- 账户状态
             T.CANCEL_FLG,    -- 核销标志
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             T.CORP_HOLD_TYPE,-- 行业类别
             T.CORP_SCALE,    -- 企业规模
             T.CUST_TYP       -- 客户分类
       FROM (SELECT T.ORG_NUM,
                     T.CUST_ID,
                     T.ACCT_NUM,
                     T.LOAN_NUM,
                     T.DRAWDOWN_DT,
                     T.ITEM_CD,
                     T.DEPARTMENTD,
                     NVL(T.DRAWDOWN_AMT * U.CCY_RATE, 0)DRAWDOWN_AMT ,
                     T.CURR_CD,
                     C.CORP_SCALE,
                     C.CUST_NAM,
                     T.MATURITY_DT,   -- 原始到期日期
                     T.ACCT_TYP,      -- 账户类型
                     T.ACCT_TYP_DESC, -- 账户类型说明
                     T.ACCT_STS,      -- 账户状态
                     T.CANCEL_FLG,    -- 核销标志
                     T.LOAN_STOCKEN_DATE, -- 证券化日期
                     T.JBYG_ID,       -- 经办员工ID
                     C.CORP_HOLD_TYPE,
                     C.CUST_TYP,
                     ROW_NUMBER() OVER(PARTITION BY T.CUST_ID ORDER BY T.DRAWDOWN_DT,T.LOAN_NUM) RNK
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.IS_FIRST_LOAN_TAG = 'Y' --是否首次贷款
         AND SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0')
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4)) T
       WHERE T.RNK=1
) q_11
INSERT INTO `S64_I_6.2.D.2020` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_6.2.C.2020` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_6.2.A.2020` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *
INSERT INTO `S64_I_6.2.B.2020` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_16,
       COL_17)
SELECT *;

