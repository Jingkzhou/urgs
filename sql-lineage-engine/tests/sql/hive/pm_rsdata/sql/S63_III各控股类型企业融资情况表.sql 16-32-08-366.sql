-- ============================================================
-- 文件名: S63_III各控股类型企业融资情况表.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: S63_III_6.A
--   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

 --  6.当年累计发放贷款年化利息收入
      INSERT INTO `S63_III_6.A`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             TT1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_6.A' AS ITEM_NUM,
             (T.DRAWDOWN_AMT * TT.CCY_RATE * TT1.REAL_INT_RAT / 100)  AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 --取放款时的实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND A.CORP_HOLD_TYPE LIKE 'A%' --国有控股   A01  国有控股企业-绝对控股    A02  国有控股企业-相对控股
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 刨除票据转贴现
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 剔除重组
         AND T.LOAN_STOCKEN_DATE IS NULL -- 资产未转让
       ORDER BY  TT1.ORG_NUM;


-- ========== 逻辑组 1: 共 5 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.LOAN_GRADE_CD = '1' THEN 'S63_III_1.1.1.C'
                  WHEN T.LOAN_GRADE_CD = '2' THEN 'S63_III_1.1.2.C'
                  WHEN T.LOAN_GRADE_CD = '3' THEN 'S63_III_1.1.3.C'
                  WHEN T.LOAN_GRADE_CD = '4' THEN 'S63_III_1.1.4.C'
                  WHEN T.LOAN_GRADE_CD = '5' THEN 'S63_III_1.1.5.C'
                  END AS ITEM_NUM,
             (nvl(T.LOAN_ACCT_BAL,0) * U.CCY_RATE) + (nvl(T.INT_ADJEST_AMT,0) * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
             -- (T.LOAN_ACCT_BAL * U.CCY_RATE) + (NVL(T.INT_ADJEST_AMT,0) * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股
             OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行/凯旋支行   历史遗留数据 没有集团信息,默认为微型企业
         AND T.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY T.ORG_NUM
) q_1
INSERT INTO `S63_III_1.1.2.C` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.3.C` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.1.C` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.4.C` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.5.C` (DATA_DATE,
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

-- ========== 逻辑组 2: 共 2 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
              CASE WHEN T.OD_DAYS < 61 THEN 'S63_III_1.3.1.C'
                   WHEN T.OD_DAYS < 91 THEN 'S63_III_1.3.2.C'
                    END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP,      -- 客户分类
             T.OD_FLG,        -- 逾期标志
             T.OD_DAYS        -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
             OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND T.OD_FLG = 'Y'
         AND T.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND T.OD_DAYS < 91
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
     AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY T.ORG_NUM
) q_2
INSERT INTO `S63_III_1.3.2.C` (DATA_DATE,
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
       COL_20)
SELECT *
INSERT INTO `S63_III_1.3.1.C` (DATA_DATE,
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
       COL_20)
SELECT *;

-- ========== 逻辑组 3: 共 5 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.LOAN_GRADE_CD = '1' THEN 'S63_III_1.1.1.C1'
                  WHEN T.LOAN_GRADE_CD = '2' THEN 'S63_III_1.1.2.C1'
                  WHEN T.LOAN_GRADE_CD = '3' THEN 'S63_III_1.1.3.C1'
                  WHEN T.LOAN_GRADE_CD = '4' THEN 'S63_III_1.1.4.C1'
                  WHEN T.LOAN_GRADE_CD = '5' THEN 'S63_III_1.1.5.C1'
                   END AS  ITEM_NUM,
             (nvl(T.LOAN_ACCT_BAL,0) * U.CCY_RATE) + (nvl(T.INT_ADJEST_AMT,0) * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
             -- (T.LOAN_ACCT_BAL * U.CCY_RATE) + (T.INT_ADJEST_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND T.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') -- M2
         AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股
           OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行 历史遗留数据 没有集团信息,默认为微型企业
         AND B.CORP_SCALE IN ('T' , 'S')-- 微型企业 ,小型企业
         AND T.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL -- 企业规模不为空
         AND T.LOAN_STOCKEN_DATE IS NULL -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM
) q_3
INSERT INTO `S63_III_1.1.2.C1` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.4.C1` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.1.C1` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.3.C1` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.5.C1` (DATA_DATE,
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

-- 指标: S63_III_1.4.1.G
--  1.4中长期贷款
   INSERT INTO `S63_III_1.4.1.G`
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
       COL_18
       )
       SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_1.4.1.G' AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T -- 原始到日期逻辑修改,从此视图取。
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM;


-- ========== 逻辑组 5: 共 4 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.GUARANTY_TYP LIKE 'D%' THEN 'S63_III_1.2.1.C1'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN 'S63_III_1.2.2.C1'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN 'S63_III_1.2.3.C1'  -- 截取前一位为抵押
                  WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN 'S63_III_1.2.4.C1'
                  END  AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND (A.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
             OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') -- 松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IN ('T','S') -- 微型企业,小型企业
         AND TT.FORWARD_CCY = 'CNY'
         AND A.CORP_SCALE IS NOT NULL -- 企业规模不为空
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM
) q_5
INSERT INTO `S63_III_1.2.4.C1` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.3.C1` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.1.C1` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.2.C1` (DATA_DATE,
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

-- ========== 逻辑组 6: 共 2 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.OD_DAYS < 61 THEN  'S63_III_1.3.1.G'
                  WHEN T.OD_DAYS < 91 THEN  'S63_III_1.3.2.G'
                   END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP,      -- 客户分类
             T.OD_FLG,        -- 逾期标志
             T.OD_DAYS        -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND T.ACCT_TYP LIKE '0102%'
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS < 91 -- 20200114 MODIFY LJP 期限拆分成 60天以内 和61-90
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM
) q_6
INSERT INTO `S63_III_1.3.2.G` (DATA_DATE,
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
       COL_20)
SELECT *
INSERT INTO `S63_III_1.3.1.G` (DATA_DATE,
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
       COL_20)
SELECT *;

-- 指标: S63_III_4.1.G
-- 4.1当年累计发放信用贷款
INSERT INTO `S63_III_4.1.G`
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
       COL_18,
       COL_21
       )
       SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.1.G' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             NULL,            -- 行业类别
             NULL,            -- 企业规模
             NULL,            -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND T.GUARANTY_TYP LIKE 'D%'
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组 ADD BY CHM 20210604
         AND T.LOAN_STOCKEN_DATE IS NULL  -- 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_8.C1
-- 银行承兑汇票 私人控股 小微企业 T 微型企业  S 小型企业
INSERT INTO `S63_III_8.C1`
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
       COL_18
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_8.C1' AS ITEM_NUM,
             (NVL(T.BALANCE * TT.CCY_RATE, 0))AS TOTAL_VALUE,
             T.ACCT_NO,        -- 合同号
             T.ACCT_NUM,       -- 账号
             T.CUST_ID,        -- 客户号
             T.GL_ITEM_CODE,   -- 科目号
             T.CURR_CD,        -- 币种
             NULL,             -- 放款金额
             T.BUSINESS_DT,    -- 业务发生日期
             T.MATURITY_DT,    -- 到期日期
             T.ACCT_TYP,       -- 账户类型
             NULL,             -- 账户类型说明
             T.ACCT_STS,       -- 账户状态
             NULL,             -- 核销标志
             T.LOAN_GRADE_CD,  -- 五级分类
             NULL,             -- 证券化日期
             T.JBYG_ID,        -- 经办员工ID
             A.CORP_HOLD_TYPE, -- 行业类别
             A.CORP_SCALE,     -- 企业规模
             A.CUST_TYP        -- 客户分类
        FROM SMTMODS_L_ACCT_OBS_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TT.FORWARD_CCY = 'CNY'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND (A.CORP_HOLD_TYPE LIKE 'C%' OR A.CUST_ID = '8500054441' OR
             A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND A.CORP_SCALE IN ('T', 'S')
         AND T.ACCT_TYP LIKE '111' --银行承兑汇票
         AND T.BALANCE <> 0
       ORDER BY T.ORG_NUM;


-- 指标: S63_III_6.F
--   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额


  --  6.当年累计发放贷款年化利息收入
       INSERT INTO `S63_III_6.F`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             TT1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_6.F' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE * TT1.REAL_INT_RAT / 100) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 --取放款时的实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND A.CORP_HOLD_TYPE = 'Z'
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) --剔除重组
         AND T.LOAN_STOCKEN_DATE IS NULL    --资产未转让
       ORDER BY I_DATADATE, TT1.ORG_NUM;


-- 指标: S63_III_6.C1
--   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

  --  6.当年累计发放贷款年化利息收入
  INSERT INTO `S63_III_6.C1`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             TT1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_6.C1' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE * TT1.REAL_INT_RAT / 100) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 --取放款时的实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND A.CORP_SCALE IN ('T', 'S') -- T微型企业 S小型企业
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND (A.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
             OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) --剔除重组 20210923 MDF BY CHM
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, TT1.ORG_NUM;


-- 指标: S63_III_2.D
--2.有贷款余额的户数
   INSERT INTO `S63_III_2.D`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )
     SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_2.D' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID,       -- 客户号
             A.CUST_NAM       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND A.CORP_HOLD_TYPE LIKE 'D%' --港澳台商控股企业   D01  港澳台商控股企业-绝对控股    D02  港澳台商控股企业-相对控股
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 刨除票据转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY T.CUST_ID;


-- ========== 逻辑组 12: 共 2 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.LOAN_GRADE_CD = '1' THEN  'S63_III_1.1.1.D'
                  WHEN T.LOAN_GRADE_CD = '2' THEN  'S63_III_1.1.2.D'
                  WHEN T.LOAN_GRADE_CD = '3' THEN  'S63_III_1.1.3.D'
                  WHEN T.LOAN_GRADE_CD = '4' THEN  'S63_III_1.1.4.D'
                  WHEN T.LOAN_GRADE_CD = '5' THEN  'S63_III_1.1.5.D'
                   END AS ITEM_NUM,
             (nvl(T.LOAN_ACCT_BAL,0) * U.CCY_RATE) + (nvl(T.INT_ADJEST_AMT,0) * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
             -- (T.LOAN_ACCT_BAL * U.CCY_RATE) +  (T.INT_ADJEST_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND B.CORP_HOLD_TYPE LIKE 'D%' --港澳台商控股企业   D01  港澳台商控股企业-绝对控股    D02  港澳台商控股企业-相对控股
         AND T.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY T.ORG_NUM
) q_12
INSERT INTO `S63_III_1.1.2.D` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.1.D` (DATA_DATE,
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

-- 指标: S63_III_1.3.1.B
--   1.3按贷款逾期情况
INSERT INTO `S63_III_1.3.1.B`
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
       COL_18,
       COL_19,
       COL_20
       )
        SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.OD_DAYS < 61 THEN 'S63_III_1.3.1.B'
                  WHEN T.OD_DAYS < 91 THEN 'S63_III_1.3.2.B'
                  END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP,      -- 客户分类
             T.OD_FLG,        -- 逾期标志
             T.OD_DAYS        -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON t.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --m2
         AND B.CORP_HOLD_TYPE like 'B%' --集体控股   B01  集体控股-绝对控股    B02  集体控股-相对控股
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS < 91 -- 期限拆分成 60天以内 和61-90
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       ORDER BY T.ORG_NUM;


-- ========== 逻辑组 14: 共 2 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.OD_DAYS > 90 AND T.OD_DAYS < 361 THEN 'S63_III_1.3.3.G'
                  WHEN T.OD_DAYS > 360 THEN 'S63_III_1.3.4.G'
                  END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP,      -- 客户分类
             T.OD_FLG,        -- 逾期标志
             T.OD_DAYS        -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND T.ACCT_TYP LIKE '0102%'
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS > 90
         AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       ORDER BY T.ORG_NUM
) q_14
INSERT INTO `S63_III_1.3.4.G` (DATA_DATE,
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
       COL_20)
SELECT *
INSERT INTO `S63_III_1.3.3.G` (DATA_DATE,
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
       COL_20)
SELECT *;

-- ========== 逻辑组 15: 共 2 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.GUARANTY_TYP LIKE 'D%' THEN 'S63_III_1.2.1.D'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN 'S63_III_1.2.2.D'
                  WHEN substr(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN 'S63_III_1.2.3.D'
                  WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN 'S63_III_1.2.4.D'
                  END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND A.CORP_HOLD_TYPE LIKE 'D%' --港澳台商控股企业   D01  港澳台商控股企业-绝对控股    D02  港澳台商控股企业-相对控股
         AND T.LOAN_ACCT_BAL <> 0
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --m2
         AND TT.FORWARD_CCY = 'CNY'
         and A.CORP_SCALE is not null --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL    --资产未转让
       ORDER BY T.ORG_NUM
) q_15
INSERT INTO `S63_III_1.2.3.D` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.2.D` (DATA_DATE,
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

-- 指标: S63_III_4.1.E
-- 4.1当年累计发放信用贷款
 INSERT INTO `S63_III_4.1.E`
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
       COL_18,
       COL_21
       )
       SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.1.E' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE)AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND A.CORP_HOLD_TYPE LIKE 'E%' --外商控股企业   E01  外商控股企业-绝对控股    E02  外商控股企业-相对控股
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND T.GUARANTY_TYP LIKE 'D%'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组 ADD BY CHM 20210604
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_4.D
--3.a其中：以知识产权为质押的户数

   --4.当年累计发放贷款额
  INSERT INTO `S63_III_4.D`
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
       COL_18,
       COL_21
       )
        SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.D' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE)AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0')
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND A.CORP_HOLD_TYPE LIKE 'D%' --港澳台商控股企业   D01  港澳台商控股企业-绝对控股    D02  港澳台商控股企业-相对控股
         AND TT.FORWARD_CCY = 'CNY' --币种
         and A.CORP_SCALE is not null --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         and (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_4.F
--3.a其中：以知识产权为质押的户数

    --4.当年累计发放贷款额
INSERT INTO `S63_III_4.F`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.F' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE)AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND A.CORP_HOLD_TYPE = 'Z'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND T.LOAN_STOCKEN_DATE IS NULL    --  资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_2.E
--2.有贷款余额的户数
    INSERT INTO `S63_III_2.E`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )
     SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_2.E' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID,       -- 客户号
             A.CUST_NAM       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND A.CORP_HOLD_TYPE LIKE 'E%' --外商控股企业   E01  外商控股企业-绝对控股    E02  外商控股企业-相对控股
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, T.ORG_NUM;


-- ========== 逻辑组 20: 共 2 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.LOAN_GRADE_CD = '1' THEN 'S63_III_1.1.1.A'
                  WHEN T.LOAN_GRADE_CD = '2' THEN 'S63_III_1.1.2.A'
                  WHEN T.LOAN_GRADE_CD = '3' THEN 'S63_III_1.1.3.A'
                  WHEN T.LOAN_GRADE_CD = '4' THEN 'S63_III_1.1.4.A'
                  WHEN T.LOAN_GRADE_CD = '5' THEN 'S63_III_1.1.5.A'
                   END AS ITEM_NUM,
             (nvl(T.LOAN_ACCT_BAL,0) * U.CCY_RATE) + (nvl(T.INT_ADJEST_AMT,0) * U.CCY_RATE) AS TOTAL_VALUE,
             -- (T.LOAN_ACCT_BAL * U.CCY_RATE) + (T.INT_ADJEST_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND B.CORP_HOLD_TYPE LIKE 'A%' --国有控股   A01 国有控股企业-绝对控股    A02  国有控股企业-相对控股
         AND T.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.LOAN_STOCKEN_DATE IS NULL
) q_20
INSERT INTO `S63_III_1.1.1.A` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.2.A` (DATA_DATE,
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

-- ========== 逻辑组 21: 共 3 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.GUARANTY_TYP LIKE 'D%' THEN  'S63_III_1.2.1.F'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN  'S63_III_1.2.2.F'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN 'S63_III_1.2.3.F'
                  WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN  'S63_III_1.2.4.F'
                  END,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND A.CORP_HOLD_TYPE = 'Z'
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM
) q_21
INSERT INTO `S63_III_1.2.3.F` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.2.F` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.1.F` (DATA_DATE,
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

-- ========== 逻辑组 22: 共 3 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.GUARANTY_TYP LIKE 'D%' THEN'S63_III_1.2.1.E'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN 'S63_III_1.2.2.E'
                  WHEN substr(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN 'S63_III_1.2.3.E'
                  WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN 'S63_III_1.2.4.E'
                  END  AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --m2
         AND A.CORP_HOLD_TYPE LIKE 'E%' --外商控股企业   E01  外商控股企业-绝对控股    E02  外商控股企业-相对控股
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         and A.CORP_SCALE is not null --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY T.ORG_NUM
) q_22
INSERT INTO `S63_III_1.2.1.E` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.2.E` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.3.E` (DATA_DATE,
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

-- 指标: S63_III_4.A
--3.a其中：以知识产权为质押的户数


--4.当年累计发放贷款额
INSERT INTO `S63_III_4.A`
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
       COL_18,
       COL_21
       )
        SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.A' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --m2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND A.CORP_HOLD_TYPE LIKE 'A%' --国有控股   A01  国有控股企业-绝对控股    A02  国有控股企业-相对控股
         AND TT.FORWARD_CCY = 'CNY' --币种
         and A.CORP_SCALE is not null --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 刨除票据转贴现  M4
         and (t.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY P1.ORG_NUM;


-- 指标: S63_III_2.G
--2.有贷款余额的户数
    INSERT INTO `S63_III_2.G`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3
       )
      SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_2.G' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID        -- 客户号
        FROM SMTMODS_L_ACCT_LOAN T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, T.ORG_NUM;


-- 指标: S63_III_2.B
--2.有贷款余额的户数
      INSERT INTO `S63_III_2.B`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )
      SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_2.B' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID,       -- 客户号
             A.CUST_NAM       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND A.CORP_HOLD_TYPE LIKE 'B%' --集体控股   B01  集体控股-绝对控股    B02  集体控股-相对控股
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY T.ORG_NUM;


-- 指标: S63_III_2.F
--2.有贷款余额的户数
     INSERT INTO `S63_III_2.F`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )
      SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_2.F' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID,       -- 客户号
             A.CUST_NAM       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND A.CORP_HOLD_TYPE = 'Z'
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, T.ORG_NUM;


-- ========== 逻辑组 27: 共 4 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.GUARANTY_TYP LIKE 'D%' THEN 'S63_III_1.2.1.C'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN 'S63_III_1.2.2.C'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN 'S63_III_1.2.3.C'
                  WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN 'S63_III_1.2.4.C'
                   END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND (A.CORP_HOLD_TYPE LIKE 'C%' --私人控股
             OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY T.ORG_NUM
) q_27
INSERT INTO `S63_III_1.2.2.C` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.3.C` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.1.C` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.4.C` (DATA_DATE,
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

-- 指标: S63_III_3.F
--3.当年累计发放贷款户数
    INSERT INTO `S63_III_3.F`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )
      SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_3.F' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID,       -- 客户号
             A.CUST_NAM       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND A.CORP_HOLD_TYPE = 'Z'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4)
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) --MDF BY CHM 20210923 剔除重组
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- ========== 逻辑组 29: 共 2 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, --  数据条线
             'CBRC'  AS SYS_NAM,  --  模块简称
             'S6303' AS REP_NUM, --  报表编号
             CASE WHEN T.OD_DAYS < 61 THEN 'S63_III_1.3.1.C1'
                  WHEN T.OD_DAYS < 91 THEN 'S63_III_1.3.2.C1'
                   END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      --  合同号
             T.LOAN_NUM,      --  借据号
             T.CUST_ID,       --  客户号
             T.ITEM_CD,       --  科目号
             T.CURR_CD,       --  币种
             T.DRAWDOWN_AMT,  --  放款金额
             T.DRAWDOWN_DT,   --  放款日期
             T.MATURITY_DT,   --  原始到期日期
             T.ACCT_TYP,      --  账户类型
             T.ACCT_TYP_DESC, --  账户类型说明
             T.ACCT_STS,      --  账户状态
             T.CANCEL_FLG,    --  核销标志
             T.LOAN_GRADE_CD, --  五级分类代码
             T.LOAN_STOCKEN_DATE, --  证券化日期
             T.JBYG_ID,       --  经办员工ID
             B.CORP_HOLD_TYPE,--  行业类别
             B.CORP_SCALE,    --  企业规模
             B.CUST_TYP,      --  客户分类
             T.OD_FLG,        -- 逾期标志
             T.OD_DAYS        -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U -- 汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD -- 基准币种
         AND U.FORWARD_CCY = 'CNY' -- 折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' -- 委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3' -- 账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') -- M2
         AND B.CORP_SCALE IN ('T','S') --  微型企业,小型企业
         AND (B.CORP_HOLD_TYPE LIKE 'C%' -- 私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
           OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') -- 松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS < 91
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL -- 企业规模不为空
         AND T.LOAN_STOCKEN_DATE IS NULL    --  资产未转让
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM
) q_29
INSERT INTO `S63_III_1.3.1.C1` (DATA_DATE,
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
       COL_20)
SELECT *
INSERT INTO `S63_III_1.3.2.C1` (DATA_DATE,
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
       COL_20)
SELECT *;

-- 指标: S63_III_4.C
--3.a其中：以知识产权为质押的户数

  --4.当年累计发放贷款额
  INSERT INTO `S63_III_4.C`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.C' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 借新还旧标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND (A.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
             OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND T.LOAN_STOCKEN_DATE IS NULL    --  资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_1.4.1.D
--   1.4中长期贷款
    INSERT INTO `S63_III_1.4.1.D`
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
       COL_18
       )
        SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_1.4.1.D' AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --ALTER BY WJB 20220621 原始到日期逻辑修改,从此视图取。
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND B.CORP_HOLD_TYPE LIKE 'D%' --港澳台商控股企业   D01  港澳台商控股企业-绝对控股    D02  港澳台商控股企业-相对控股
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12
         AND (T.ACCT_TYP NOT LIKE '0101%' AND T.ACCT_TYP NOT LIKE '0103%' AND
             T.ACCT_TYP NOT LIKE '0104%' AND T.ACCT_TYP NOT LIKE '0199%')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM;


-- 指标: S63_III_10.C1
-- 保函 小微
 INSERT INTO `S63_III_10.C1`
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
       COL_18
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_10.C1'AS ITEM_NUM, --私人控股 小微企业 T 微型企业  S 小型企业
             (NVL(T.BALANCE * TT.CCY_RATE, 0)) AS ITEM_NUM,
             T.ACCT_NO,        -- 合同号
             T.ACCT_NUM,       -- 账号
             T.CUST_ID,        -- 客户号
             T.GL_ITEM_CODE,   -- 科目号
             T.CURR_CD,        -- 币种
             NULL,             -- 放款金额
             T.BUSINESS_DT,    -- 业务发生日期
             T.MATURITY_DT,    -- 到期日期
             T.ACCT_TYP,       -- 账户类型
             NULL,             -- 账户类型说明
             T.ACCT_STS,       -- 账户状态
             NULL,             -- 核销标志
             T.LOAN_GRADE_CD,  -- 五级分类
             NULL,             -- 证券化日期
             T.JBYG_ID,        -- 经办员工ID
             A.CORP_HOLD_TYPE, -- 行业类别
             A.CORP_SCALE,     -- 企业规模
             A.CUST_TYP        -- 客户分类
        FROM SMTMODS_L_ACCT_OBS_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TT.FORWARD_CCY = 'CNY'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND T.ACCT_TYP IN ('121', '211') --保函
         AND (A.CORP_HOLD_TYPE LIKE 'C%' OR A.CUST_ID = '8500054441' OR
              A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND A.CORP_SCALE IN ('T', 'S')
         AND T.BALANCE <> 0
       ORDER BY T.ORG_NUM;


-- ========== 逻辑组 33: 共 3 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE  WHEN T.GUARANTY_TYP LIKE 'D%' THEN  'S63_III_1.2.1.G'
                   WHEN T.GUARANTY_TYP LIKE 'C%' THEN 'S63_III_1.2.2.G'
                   WHEN substr(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN  'S63_III_1.2.3.G'
                   WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN 'S63_III_1.2.4.G'
                    END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         and t.ACCT_TYP LIKE '0102%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.LOAN_STOCKEN_DATE IS NULL -- 资产未转让
       ORDER BY T.ORG_NUM
) q_33
INSERT INTO `S63_III_1.2.1.G` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.2.G` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.3.G` (DATA_DATE,
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

-- ========== 逻辑组 34: 共 2 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, --   数据条线
             'CBRC'  AS SYS_NAM,  --   模块简称
             'S6303' AS REP_NUM, --   报表编号
             CASE WHEN T.OD_DAYS > 90 AND T.OD_DAYS < 361 THEN 'S63_III_1.3.3.C1'
                  WHEN T.OD_DAYS > 360 THEN 'S63_III_1.3.4.C1'
                   END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      --   合同号
             T.LOAN_NUM,      --   借据号
             T.CUST_ID,       --   客户号
             T.ITEM_CD,       --   科目号
             T.CURR_CD,       --   币种
             T.DRAWDOWN_AMT,  --   放款金额
             T.DRAWDOWN_DT,   --   放款日期
             T.MATURITY_DT,   --   原始到期日期
             T.ACCT_TYP,      --   账户类型
             T.ACCT_TYP_DESC, --   账户类型说明
             T.ACCT_STS,      --   账户状态
             T.CANCEL_FLG,    --   核销标志
             T.LOAN_GRADE_CD, --   五级分类代码
             T.LOAN_STOCKEN_DATE, --   证券化日期
             T.JBYG_ID,       --   经办员工ID
             B.CORP_HOLD_TYPE,--   行业类别
             B.CORP_SCALE,    --   企业规模
             B.CUST_TYP,      --   客户分类
             T.OD_FLG,        --  逾期标志
             T.OD_DAYS        --  逾期天数
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U -- 汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD -- 基准币种
         AND U.FORWARD_CCY = 'CNY' -- 折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' -- 委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3' -- 账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') -- M2
         AND B.CORP_SCALE IN ('T','S') --   微型企业,小型企业
         AND (B.CORP_HOLD_TYPE LIKE 'C%' -- 私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
           OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') -- 松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS > 90
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL -- 企业规模不为空
         AND T.LOAN_STOCKEN_DATE IS NULL    -- ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM
) q_34
INSERT INTO `S63_III_1.3.3.C1` (DATA_DATE,
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
       COL_20)
SELECT *
INSERT INTO `S63_III_1.3.4.C1` (DATA_DATE,
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
       COL_20)
SELECT *;

-- 指标: S63_III_1.4.1.C1
--   1.4中长期贷款
 INSERT INTO `S63_III_1.4.1.C1`
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
       COL_18
       )
     SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, --  数据条线
             'CBRC'  AS SYS_NAM, --   模块简称
             'S6303' AS REP_NUM, --   报表编号
             'S63_III_1.4.1.C1' AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
             T.ACCT_NUM,      --   合同号
             T.LOAN_NUM,      --   借据号
             T.CUST_ID,       --   客户号
             T.ITEM_CD,       --   科目号
             T.CURR_CD,       --   币种
             T.DRAWDOWN_AMT,  --   放款金额
             T.DRAWDOWN_DT,   --   放款日期
             T.MATURITY_DT,   --   原始到期日期
             T.ACCT_TYP,      --   账户类型
             T.ACCT_TYP_DESC, --   账户类型说明
             T.ACCT_STS,      --   账户状态
             T.CANCEL_FLG,    --   核销标志
             T.LOAN_GRADE_CD, --   五级分类代码
             T.LOAN_STOCKEN_DATE, --   证券化日期
             T.JBYG_ID,       --   经办员工ID
             B.CORP_HOLD_TYPE,--   行业类别
             B.CORP_SCALE,    --   企业规模
             B.CUST_TYP       --   客户分类
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T -- ALTER BY WJB 20220621 原始到日期逻辑修改,从此视图取。
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U -- 汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD -- 基准币种
         AND U.FORWARD_CCY = 'CNY' -- 折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' -- 委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL    -- ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_STS <> '3' -- 账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') -- M2
         AND B.CORP_SCALE IN ('T','S') --    微型企业,小型企业
         AND (B.CORP_HOLD_TYPE LIKE 'C%' -- 私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
           OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') -- 松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL -- 企业规模不为空
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM;


-- ========== 逻辑组 36: 共 4 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.GUARANTY_TYP LIKE 'D%' THEN 'S63_III_1.2.1.A'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN 'S63_III_1.2.2.A'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN 'S63_III_1.2.3.A' --  L层模型调整改为截取前一位为抵押
                  WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN 'S63_III_1.2.4.A'
                  END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('0', '1') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND A.CORP_HOLD_TYPE LIKE 'A%' --国有控股   A01 国有控股企业-绝对控股    A02  国有控股企业-相对控股
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL -- 资产未转让
       ORDER BY T.ORG_NUM
) q_36
INSERT INTO `S63_III_1.2.1.A` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.3.A` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.4.A` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.2.A` (DATA_DATE,
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

-- 指标: S63_III_4.1.B
-- 4.1当年累计发放信用贷款
  INSERT INTO `S63_III_4.1.B`
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
       COL_18,
       COL_21
       )
       SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.1.B' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND A.CORP_HOLD_TYPE LIKE 'B%' --集体控股   B01  集体控股-绝对控股    B02  集体控股-相对控股
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND T.GUARANTY_TYP LIKE 'D%'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_1.1.1.F
--ALTER BY WJB 20221026 新增企业控股类型为其他的取数逻辑

    --1.境内贷款余额合计
INSERT INTO `S63_III_1.1.1.F`
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
       COL_18
       )
        SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.LOAN_GRADE_CD = '1' THEN 'S63_III_1.1.1.F'
                  WHEN T.LOAN_GRADE_CD = '2' THEN 'S63_III_1.1.2.F'
                  WHEN T.LOAN_GRADE_CD = '3' THEN 'S63_III_1.1.3.F'
                  WHEN T.LOAN_GRADE_CD = '4' THEN 'S63_III_1.1.4.F'
                  WHEN T.LOAN_GRADE_CD = '5' THEN 'S63_III_1.1.5.F'
                   END AS ITEM_NUM,
             (nvl(T.LOAN_ACCT_BAL,0) * U.CCY_RATE) + (nvl(T.INT_ADJEST_AMT,0) * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
             -- (T.LOAN_ACCT_BAL * U.CCY_RATE) + (T.INT_ADJEST_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND B.CORP_HOLD_TYPE = 'Z'
         AND T.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_STOCKEN_DATE IS NULL   -- 资产未转让
       ORDER BY T.ORG_NUM;


-- 指标: S63_III_4.G
--3.a其中：以知识产权为质押的户数

   --4.当年累计发放贷款额
INSERT INTO `S63_III_4.G`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.G' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE)AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组 ADD BY CHM 20210604
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- ========== 逻辑组 40: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN A.CORP_HOLD_TYPE LIKE 'A%' THEN 'S63_III_10.A' --国有控股   A01 国有控股企业-绝对控股    A02  国有控股企业-相对控股
                  WHEN A.CORP_HOLD_TYPE LIKE 'B%' THEN 'S63_III_10.B' --集体控股
                  WHEN (A.CORP_HOLD_TYPE LIKE 'C%' OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') THEN 'S63_III_10.C' --私人控股 --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
                  WHEN A.CORP_HOLD_TYPE LIKE 'D%' THEN 'S63_III_10.D' --港澳台商控股
                  WHEN A.CORP_HOLD_TYPE LIKE 'E%' THEN 'S63_III_10.E' --外商控股
                  WHEN A.CORP_HOLD_TYPE LIKE 'Z%' THEN 'S63_III_10.F' --其他控股
                   END AS ITEM_NUM,
             (NVL(T.BALANCE * TT.CCY_RATE, 0))AS TOTAL_VALUE,
             T.ACCT_NO,        -- 合同号
             T.ACCT_NUM,       -- 账号
             T.CUST_ID,        -- 客户号
             T.GL_ITEM_CODE,   -- 科目号
             T.CURR_CD,        -- 币种
             NULL,             -- 放款金额
             T.BUSINESS_DT,    -- 业务发生日期
             T.MATURITY_DT,    -- 到期日期
             T.ACCT_TYP,       -- 账户类型
             NULL,             -- 账户类型说明
             T.ACCT_STS,       -- 账户状态
             NULL,             -- 核销标志
             T.LOAN_GRADE_CD,  -- 五级分类
             NULL,             -- 证券化日期
             T.JBYG_ID,        -- 经办员工ID
             A.CORP_HOLD_TYPE, -- 行业类别
             A.CORP_SCALE,     -- 企业规模
             A.CUST_TYP        -- 客户分类
        FROM SMTMODS_L_ACCT_OBS_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TT.FORWARD_CCY = 'CNY'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND T.BALANCE <> 0
         AND T.ACCT_TYP IN ('121', '211') --保函
       ORDER BY T.ORG_NUM
) q_40
INSERT INTO `S63_III_10.C` (DATA_DATE,
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
INSERT INTO `S63_III_10.A` (DATA_DATE,
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

-- 指标: S63_III_4.1.C1
-- 4.1当年累计发放信用贷款
   INSERT INTO `S63_III_4.1.C1`
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
       COL_18,
       COL_21
       )
  SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.1.C1' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND A.CORP_SCALE IN ('T', 'S') -- T微型企业 S小型企业
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND (A.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
           OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND T.GUARANTY_TYP LIKE 'D%'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- ========== 逻辑组 42: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN A.CORP_HOLD_TYPE LIKE 'A%' THEN 'S63_III_9.A' --国有控股   A01 国有控股企业-绝对控股    A02  国有控股企业-相对控股
                  WHEN A.CORP_HOLD_TYPE LIKE 'B%' THEN 'S63_III_9.B' --集体控股
                  WHEN (A.CORP_HOLD_TYPE LIKE 'C%' OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302')THEN 'S63_III_9.C' --私人控股 --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
                  WHEN A.CORP_HOLD_TYPE LIKE 'D%' THEN 'S63_III_9.D' --港澳台商控股
                  WHEN A.CORP_HOLD_TYPE LIKE 'E%' THEN 'S63_III_9.E' --外商控股
                  WHEN A.CORP_HOLD_TYPE LIKE 'Z%' THEN  'S63_III_9.F' --其他控股
                   END AS ITEM_NUM,
             (NVL(T.BALANCE * TT.CCY_RATE, 0))AS TOTAL_VALUE,
             T.ACCT_NO,        -- 合同号
             T.ACCT_NUM,       -- 账号
             T.CUST_ID,        -- 客户号
             T.GL_ITEM_CODE,   -- 科目号
             T.CURR_CD,        -- 币种
             NULL,             -- 放款金额
             T.BUSINESS_DT,    -- 业务发生日期
             T.MATURITY_DT,    -- 到期日期
             T.ACCT_TYP,       -- 账户类型
             NULL,             -- 账户类型说明
             T.ACCT_STS,       -- 账户状态
             NULL,             -- 核销标志
             T.LOAN_GRADE_CD,  -- 五级分类
             NULL,             -- 证券化日期
             T.JBYG_ID,        -- 经办员工ID
             A.CORP_HOLD_TYPE, -- 行业类别
             A.CORP_SCALE,     -- 企业规模
             A.CUST_TYP        -- 客户分类
        FROM SMTMODS_L_ACCT_OBS_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2 --对公客户分类 企业
         AND TT.FORWARD_CCY = 'CNY'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND T.ACCT_TYP LIKE '31%'
         AND T.BALANCE <> 0
       ORDER BY T.ORG_NUM
) q_42
INSERT INTO `S63_III_9.C` (DATA_DATE,
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
INSERT INTO `S63_III_9.D` (DATA_DATE,
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
INSERT INTO `S63_III_9.B` (DATA_DATE,
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
INSERT INTO `S63_III_9.A` (DATA_DATE,
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

-- 指标: S63_III_3.A
--3.当年累计发放贷款户数
INSERT INTO `S63_III_3.A`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )
      SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_3.A' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
            T.CUST_ID,       -- 客户号
            A.CUST_NAM       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 -- 当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --m2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4)
         AND A.CORP_HOLD_TYPE LIKE 'A%' --国有控股   A01  国有控股企业-绝对控股    A02  国有控股企业-相对控股
         and A.CORP_SCALE is not null --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG <> 'Y' OR T.RESCHED_FLG IS NULL) -- 剔除重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY P1.ORG_NUM;


-- ========== 逻辑组 44: 共 2 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.LOAN_GRADE_CD = '1' THEN 'S63_III_1.1.1.B'
                  WHEN T.LOAN_GRADE_CD = '2' THEN 'S63_III_1.1.2.B'
                  WHEN T.LOAN_GRADE_CD = '3' THEN 'S63_III_1.1.3.B'
                  WHEN T.LOAN_GRADE_CD = '4' THEN 'S63_III_1.1.4.B'
                  WHEN T.LOAN_GRADE_CD = '5' THEN 'S63_III_1.1.5.B'
                   END AS ITEM_NUM,
             (nvl(T.LOAN_ACCT_BAL,0) * U.CCY_RATE) + (nvl(T.INT_ADJEST_AMT,0) * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
             -- (T.LOAN_ACCT_BAL * U.CCY_RATE) + (nvl(t.INT_ADJEST_AMT,0) * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND B.CORP_HOLD_TYPE LIKE 'B%' --集体控股   B01  集体控股-绝对控股    B02  集体控股-相对控股
         AND T.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY T.ORG_NUM
) q_44
INSERT INTO `S63_III_1.1.2.B` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.1.B` (DATA_DATE,
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

-- ========== 逻辑组 45: 共 5 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.LOAN_GRADE_CD = '1' THEN 'S63_III_1.1.1.G'
                  WHEN T.LOAN_GRADE_CD = '2' THEN 'S63_III_1.1.2.G'
                  WHEN T.LOAN_GRADE_CD = '3' THEN 'S63_III_1.1.3.G'
                  WHEN T.LOAN_GRADE_CD = '4' THEN 'S63_III_1.1.4.G'
                  WHEN T.LOAN_GRADE_CD = '5' THEN 'S63_III_1.1.5.G'
                   END AS ITEM_NUM,
             (nvl(T.LOAN_ACCT_BAL,0) * U.CCY_RATE) + (nvl(T.INT_ADJEST_AMT,0) * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
             -- (T.LOAN_ACCT_BAL * U.CCY_RATE) + (T.INT_ADJEST_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND T.ACCT_TYP LIKE '0102%'
         AND T.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND T.LOAN_STOCKEN_DATE IS NULL  -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM
) q_45
INSERT INTO `S63_III_1.1.3.G` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.2.G` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.4.G` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.1.G` (DATA_DATE,
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
INSERT INTO `S63_III_1.1.5.G` (DATA_DATE,
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

-- 指标: S63_III_3.C1
--3.当年累计发放贷款户数
    INSERT INTO `S63_III_3.C1`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )
         SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_3.C1' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID,       -- 客户号
             A.CUST_NAM       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND A.CORP_SCALE IN ('T', 'S') -- T微型企业 S小型企业
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4)
         AND (A.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
             OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) --  剔除重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_2.C
--2.有贷款余额的户数
INSERT INTO `S63_III_2.C`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )
      SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_2.C' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID,       -- 客户号
             A.CUST_NAM       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND (A.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
             OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, T.ORG_NUM;


-- ========== 逻辑组 48: 共 3 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.GUARANTY_TYP LIKE 'D%' THEN 'S63_III_1.2.1.B'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN 'S63_III_1.2.2.B'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN 'S63_III_1.2.3.B' -- 截取前一位为抵押
                  WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN 'S63_III_1.2.4.B'
                  END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE)AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON A.DATA_DATE = I_DATADATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND A.CORP_HOLD_TYPE LIKE 'B%' --集体控股   B01  集体控股-绝对控股    B02  集体控股-相对控股
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL  -- 资产未转让
       ORDER BY T.ORG_NUM
) q_48
INSERT INTO `S63_III_1.2.2.B` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.3.B` (DATA_DATE,
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
INSERT INTO `S63_III_1.2.1.B` (DATA_DATE,
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

-- 指标: S63_III_1.4.1.F
--   1.4中长期贷款
    INSERT INTO `S63_III_1.4.1.F`
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
       COL_18
       )
       SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_1.4.1.F' AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --  原始到日期逻辑修改,从此视图取。
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND B.CORP_HOLD_TYPE = 'Z'
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12
         AND (T.ACCT_TYP NOT LIKE '0101%' AND T.ACCT_TYP NOT LIKE '0103%' AND
              T.ACCT_TYP NOT LIKE '0104%' AND T.ACCT_TYP NOT LIKE '0199%')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM;


-- 指标: S63_III_2.A
--2.有贷款余额的户数
INSERT INTO `S63_III_2.A`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )

 SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_2.A' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID,       -- 客户号
             A.CUST_NAM       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON A.DATA_DATE = I_DATADATE
         AND T.CUST_ID = A.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND A.CORP_HOLD_TYPE LIKE 'A%' --国有控股   A01  国有控股企业-绝对控股    A02  国有控股企业-相对控股
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY T.ORG_NUM;


-- 指标: S63_III_3.D
--3.当年累计发放贷款户数
    INSERT INTO `S63_III_3.D`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )
      SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
              'S63_III_3.D' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID,       -- 客户号
             A.CUST_NAM       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 -- 当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4)
         AND A.CORP_HOLD_TYPE LIKE 'D%' -- 港澳台商控股企业   D01  港澳台商控股企业-绝对控股    D02  港澳台商控股企业-相对控股
         AND A.CORP_SCALE IS NOT NULL -- 企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 剔除重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY T.CUST_ID;


-- 指标: S63_III_6.G
--   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

   --  6.当年累计发放贷款年化利息收入
       INSERT INTO `S63_III_6.G`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             TT1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_6.G' AS ITEM_NUM,
            (DRAWDOWN_AMT * TT.CCY_RATE * TT1.REAL_INT_RAT / 100) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             NULL,            -- 行业类别
             NULL,            -- 企业规模
             NULL,            -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 --取放款时的实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) --剔除重组 20210923 MDF BY CHM
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, TT1.ORG_NUM;


-- 指标: S63_III_4.C1
--3.a其中：以知识产权为质押的户数

  --4.当年累计发放贷款额
   INSERT INTO `S63_III_4.C1`
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
       COL_18,
       COL_21
       )
        SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.C1' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE)AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND A.CORP_SCALE IN ('T', 'S') -- T微型企业 S小型企业
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND (A.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
             OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息，默认为微型企业
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_3.B
--3.当年累计发放贷款户数
    INSERT INTO `S63_III_3.B`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )
      SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_3.B' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID,       -- 客户号
             A.CUST_NAM       -- 客户分类
         FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON A.DATA_DATE = I_DATADATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4)
         AND A.CORP_HOLD_TYPE LIKE 'B%' --集体控股   B01  集体控股-绝对控股    B02  集体控股-相对控股
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 剔除重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY T.ORG_NUM;


-- 指标: S63_III_6.E
--   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

   --  6.当年累计发放贷款年化利息收入
INSERT INTO `S63_III_6.E`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             TT1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_6.E' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE * TT1.REAL_INT_RAT / 100) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 --取放款时的实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND A.CORP_HOLD_TYPE LIKE 'E%' --外商控股企业   E01  外商控股企业-绝对控股    E02  外商控股企业-相对控股
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) --剔除重组 20210923 MDF BY CHM
         AND T.LOAN_STOCKEN_DATE IS NULL    --  资产未转让
       ORDER BY I_DATADATE, TT1.ORG_NUM;


-- 指标: S63_III_4.1.A
-- 4.1当年累计发放信用贷款
  INSERT INTO `S63_III_4.1.A`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.1.A' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE)AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 借新还旧标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND A.CORP_HOLD_TYPE LIKE 'A%' --国有控股   A01  国有控股企业-绝对控股    A02  国有控股企业-相对控股
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND T.GUARANTY_TYP LIKE 'D%'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组 ADD BY CHM 20210604
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_1.4.1.C
INSERT INTO `S63_III_1.4.1.C`
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
       COL_18
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_1.4.1.C' AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T -- 原始到日期逻辑修改,从此视图取。
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
     AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
         AND T.ACCT_STS <> '3'
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
             OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND T.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM;


-- 指标: S63_III_4.1.F
-- 4.1当年累计发放信用贷款
  INSERT INTO `S63_III_4.1.F`
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
       COL_18,
       COL_21
       )
       SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.1.F' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE)AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND A.CORP_HOLD_TYPE = 'Z'
         AND T.GUARANTY_TYP LIKE 'D%'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组 ADD BY CHM 20210604
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_6.D
--   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

   --  6.当年累计发放贷款年化利息收入
  INSERT INTO `S63_III_6.D`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             TT1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_6.D' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE * TT1.REAL_INT_RAT / 100) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 --取放款时的实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND A.CORP_HOLD_TYPE LIKE 'D%' --港澳台商控股企业   D01  港澳台商控股企业-绝对控股    D02  港澳台商控股企业-相对控股
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) --剔除重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY I_DATADATE, TT1.ORG_NUM;


-- 指标: S63_III_6.B
--   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

          --  6.当年累计发放贷款年化利息收入
       INSERT INTO `S63_III_6.B`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             TT1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_6.B' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE * TT1.REAL_INT_RAT / 100)AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 --取放款时的实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND A.CORP_HOLD_TYPE LIKE 'B%' --集体控股   B01  集体控股-绝对控股    B02  集体控股-相对控股
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) --剔除重组 20210923 MDF BY CHM
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, TT1.ORG_NUM;


-- 指标: S63_III_4.1.C
-- 4.1当年累计发放信用贷款
  INSERT INTO `S63_III_4.1.C`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.1.C' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 借新还旧标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND (A.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
             OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND T.GUARANTY_TYP LIKE 'D%'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- ========== 逻辑组 62: 共 2 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.OD_DAYS > 90 AND T.OD_DAYS < 361 THEN 'S63_III_1.3.3.C'
                  WHEN T.OD_DAYS > 360 THEN 'S63_III_1.3.4.C'
                   END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP,      -- 客户分类
             T.OD_FLG,        -- 逾期标志
             T.OD_DAYS        -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
             OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS > 90
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_STOCKEN_DATE IS NULL -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM
) q_62
INSERT INTO `S63_III_1.3.4.C` (DATA_DATE,
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
       COL_20)
SELECT *
INSERT INTO `S63_III_1.3.3.C` (DATA_DATE,
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
       COL_20)
SELECT *;

-- 指标: S63_III_3.C
--3.当年累计发放贷款户数
  INSERT INTO `S63_III_3.C`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )
      SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_3.C' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID,       -- 客户号
             A.CUST_NAM       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4)
         AND (A.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
             OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 剔除重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_3.G
--3.当年累计发放贷款户数
  INSERT INTO `S63_III_3.G`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3
       )
       SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_3.G' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID        -- 客户号
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4)
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) --MDF BY CHM 20210923 剔除重组
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_6.C
--   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

--  6.当年累计发放贷款年化利息收入
 INSERT INTO `S63_III_6.C`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             TT1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_6.C' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE * TT1.REAL_INT_RAT / 100) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 借新还旧标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 --取放款时的实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND (A.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
             OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) --剔除重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY I_DATADATE, TT1.ORG_NUM;


-- 指标: S63_III_2.C1
--2.有贷款余额的户数
 INSERT INTO `S63_III_2.C1`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )
      SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_2.C1' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID,       -- 客户号
             A.CUST_NAM       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND A.CORP_SCALE IN ('T','S') --    微型企业,小型企业
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND (A.CORP_HOLD_TYPE LIKE 'C%' --私人控股   B01  私人控股-绝对控股    B02  私人控股-相对控股
             OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY I_DATADATE, T.ORG_NUM;


-- ========== 逻辑组 67: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN A.CORP_HOLD_TYPE LIKE 'A%' THEN 'S63_III_8.A' --国有控股   A01 国有控股企业-绝对控股    A02  国有控股企业-相对控股
                  WHEN A.CORP_HOLD_TYPE LIKE 'B%' THEN 'S63_III_8.B' --集体控股
                  WHEN (A.CORP_HOLD_TYPE LIKE 'C%' OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') THEN 'S63_III_8.C' --私人控股 --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
                  WHEN A.CORP_HOLD_TYPE LIKE 'D%' THEN 'S63_III_8.D' --港澳台商控股
                  WHEN A.CORP_HOLD_TYPE LIKE 'E%' THEN 'S63_III_8.E' --外商控股
                  WHEN A.CORP_HOLD_TYPE LIKE 'Z%' THEN 'S63_III_8.F' --其他控股
                   END AS ITEM_NUM,
             (NVL(T.BALANCE * TT.CCY_RATE, 0))AS TOTAL_VALUE,
             T.ACCT_NO,        -- 合同号
             T.ACCT_NUM,       -- 账号
             T.CUST_ID,        -- 客户号
             T.GL_ITEM_CODE,   -- 科目号
             T.CURR_CD,        -- 币种
             NULL,             -- 放款金额
             T.BUSINESS_DT,    -- 业务发生日期
             T.MATURITY_DT,    -- 到期日期
             T.ACCT_TYP,       -- 账户类型
             NULL,             -- 账户类型说明
             T.ACCT_STS,       -- 账户状态
             NULL,             -- 核销标志
             T.LOAN_GRADE_CD,  -- 五级分类
             NULL,             -- 证券化日期
             T.JBYG_ID,        -- 经办员工ID
             A.CORP_HOLD_TYPE, -- 行业类别
             A.CORP_SCALE,     -- 企业规模
             A.CUST_TYP        -- 客户分类
        FROM SMTMODS_L_ACCT_OBS_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TT.FORWARD_CCY = 'CNY'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND T.ACCT_TYP LIKE '111' --银行承兑汇票
         AND T.BALANCE <> 0
       ORDER BY T.ORG_NUM
) q_67
INSERT INTO `S63_III_8.A` (DATA_DATE,
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
INSERT INTO `S63_III_8.E` (DATA_DATE,
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
INSERT INTO `S63_III_8.C` (DATA_DATE,
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

-- 指标: S63_III_4.E
--3.a其中：以知识产权为质押的户数

   --4.当年累计发放贷款额
  INSERT INTO `S63_III_4.E`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.E' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE)AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND A.CORP_HOLD_TYPE LIKE 'E%' --外商控股企业   E01  外商控股企业-绝对控股    E02  外商控股企业-相对控股
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组 ADD BY CHM 20210604
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_9.C1
-- 跟单信用证 小微
INSERT INTO `S63_III_9.C1`
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
       COL_18
       )

      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_9.C1'AS ITEM_NUM,  --私人控股 小微企业 T 微型企业  S 小型企业
             (NVL(T.BALANCE * TT.CCY_RATE, 0))AS TOTAL_VALUE,
             T.ACCT_NO,        -- 合同号
             T.ACCT_NUM,       -- 账号
             T.CUST_ID,        -- 客户号
             T.GL_ITEM_CODE,   -- 科目号
             T.CURR_CD,        -- 币种
             NULL,             -- 放款金额
             T.BUSINESS_DT,    -- 业务发生日期
             T.MATURITY_DT,    -- 到期日期
             T.ACCT_TYP,       -- 账户类型
             NULL,             -- 账户类型说明
             T.ACCT_STS,       -- 账户状态
             NULL,             -- 核销标志
             T.LOAN_GRADE_CD,  -- 五级分类
             NULL,             -- 证券化日期
             T.JBYG_ID,        -- 经办员工ID
             A.CORP_HOLD_TYPE, -- 行业类别
             A.CORP_SCALE,     -- 企业规模
             A.CUST_TYP        -- 客户分类
        FROM SMTMODS_L_ACCT_OBS_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2 --对公客户分类 企业
         AND TT.FORWARD_CCY = 'CNY'
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND (A.CORP_HOLD_TYPE LIKE 'C%' OR A.CUST_ID = '8500054441' OR
              A.CUST_ID = '8000575302') -- 松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND A.CORP_SCALE IN ('T', 'S')
         AND T.ACCT_TYP LIKE '31%'
         AND T.BALANCE <> 0
       ORDER BY T.ORG_NUM;


-- 指标: S63_III_1.4.1.A
--   1.4中长期贷款
INSERT INTO `S63_III_1.4.1.A`
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
       COL_18
       )

       SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_1.4.1.A' AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --ALTER BY WJB 20220621 原始到日期逻辑修改,从此视图取。
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
         AND T.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') -- m2
         AND B.CORP_HOLD_TYPE LIKE 'A%' --国有控股   A01 国有控股企业-绝对控股    A02  国有控股企业-相对控股
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         and B.CORP_SCALE is not null --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
       ORDER BY T.ORG_NUM;


-- 指标: S63_III_4.B
--3.a其中：以知识产权为质押的户数

   --4.当年累计发放贷款额
INSERT INTO `S63_III_4.B`
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
       COL_18,
       COL_21
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.B' AS ITEM_NUM,
             (DRAWDOWN_AMT * TT.CCY_RATE) AS TOTAL_VALUE,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             A.CORP_HOLD_TYPE,-- 行业类别
             A.CORP_SCALE,    -- 企业规模
             A.CUST_TYP,      -- 客户分类
             T.RESCHED_FLG    -- 无还本续贷标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND A.CORP_HOLD_TYPE LIKE 'B%' --集体控股   B01  集体控股-绝对控股    B02  集体控股-相对控股
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_3.E
--3.当年累计发放贷款户数
     INSERT INTO `S63_III_3.E`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_22
       )
      SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             P1.ORG_NUM,
             NULL    AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_3.E' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID,       -- 客户号
             A.CUST_NAM       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN CBRC_S6301_AMT_TMP1 P1 ---当年累计发放贷款户数以放款时机构为准
          ON T.LOAN_NUM = P1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4)
         AND A.CORP_HOLD_TYPE LIKE 'E%' --外商控股企业   E01  外商控股企业-绝对控股    E02  外商控股企业-相对控股
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) --MDF BY CHM 20210923 剔除重组
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;


-- 指标: S63_III_1.1.1.E
--1.境内贷款余额合计
  INSERT INTO `S63_III_1.1.1.E`
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
       COL_18
       )
        SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             CASE WHEN T.LOAN_GRADE_CD = '1' THEN 'S63_III_1.1.1.E'
                  WHEN T.LOAN_GRADE_CD = '2' THEN 'S63_III_1.1.2.E'
                  WHEN T.LOAN_GRADE_CD = '3' THEN 'S63_III_1.1.3.E'
                  WHEN T.LOAN_GRADE_CD = '4' THEN 'S63_III_1.1.4.E'
                  WHEN T.LOAN_GRADE_CD = '5' THEN 'S63_III_1.1.5.E'
                  END AS ITEM_NUM,
             (nvl(T.LOAN_ACCT_BAL,0) * U.CCY_RATE) + (nvl(T.INT_ADJEST_AMT,0) * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
             -- (T.LOAN_ACCT_BAL * U.CCY_RATE) + (T.INT_ADJEST_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             T.LOAN_GRADE_CD, -- 五级分类代码
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND B.CORP_HOLD_TYPE LIKE 'E%' --外商控股企业   E01  外商控股企业-绝对控股    E02  外商控股企业-相对控股
         AND T.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_STOCKEN_DATE IS NULL  --资产未转让
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM;


