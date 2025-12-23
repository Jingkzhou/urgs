-- ============================================================
-- 文件名: S65_I大中小微型企业贷款分地区情况表.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 2 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..L'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..L'
                   END AS ITEM_NUM, --指标号
             (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) + (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS COLLECT_VAL, --指标值
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
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND (T.ACCT_TYP LIKE '0102%' OR T.ACCT_TYP LIKE '03%')
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL<> 0
) q_0
INSERT INTO `S65_1_1_8..L` (DATA_DATE,
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
INSERT INTO `S65_1_1_7..L` (DATA_DATE,
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

-- ========== 逻辑组 1: 共 2 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..R'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..R'
                  END AS ITEM_NUM, --指标号
             (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) + (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS COLLECT_VAL ,--指标值
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
             NULL,             -- 行业类别
             NULL,             -- 企业规模
             A.CUST_TYPE       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND A.INLANDORRSHORE_FLG = 'Y'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND (T.ACCT_TYP LIKE '0102%' OR T.ACCT_TYP LIKE '03%')
         AND C.OPERATE_CUST_TYPE = 'B'
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0
) q_1
INSERT INTO `S65_1_1_7..R` (DATA_DATE,
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
INSERT INTO `S65_1_1_8..R` (DATA_DATE,
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

-- 指标: S65_1_1_7..A
--====================================================
    --   s6501 S65_1_1_1..A插入临时表
    --====================================================

     INSERT INTO `S65_1_1_7..A`
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
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..A'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..A'
                   END AS ITEM_NUM, --指标号
             (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) + (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS LOAN_ACCT_BAL_RMB, --指标值
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
         AND SUBSTR(T.ACCT_TYP, 1, 3) NOT IN ('B01', 'D01') --客户分类
         AND B.CORP_SCALE = 'B'
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') --ALTER BY WJB 20220518 增加农村合作社取数逻辑
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0;


-- 指标: S65_1_1_8..B
--====================================================
    --   s6501 S65_1_1_1..B插入临时表
    --====================================================

  INSERT INTO `S65_1_1_8..B`
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
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..B'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..B'
                   END AS ITEM_NUM, --指标号
             (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) + (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS LOAN_ACCT_BAL_RMB, --指标值
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
         AND SUBSTR(T.ACCT_TYP, 1, 3) NOT IN ('B01', 'D01')
         AND B.CORP_SCALE = 'M'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') --ALTER BY WJB 20220518 增加农村合作社取数逻辑
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0;

------=====================m3  add  by  zy 20240708  金融市场部 大中小微吉林省取数贷款余额逻辑   =====================
---转贴现=商承+银承
--商承取数逻辑
    INSERT INTO `S65_1_1_8..B`
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
             'S6501' AS REP_NUM, -- 报表编号
            CASE WHEN T3.CORP_SCALE = 'B' THEN 'S65_1_1_8..A'
                 WHEN T3.CORP_SCALE = 'M' THEN 'S65_1_1_8..B'
                 WHEN T3.CORP_SCALE = 'S' THEN 'S65_1_1_8..C'
                 WHEN T3.CORP_SCALE = 'T' THEN 'S65_1_1_8..F'
                  END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COLLECT_VAL, --指标值
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
             T3.CORP_HOLD_TYPE,-- 行业类别
             T3.CORP_SCALE,    -- 企业规模
             T3.CUST_TYP       -- 客户分类
      FROM SMTMODS_L_ACCT_LOAN T
     INNER JOIN SMTMODS_L_AGRE_BILL_INFO  T1   -- （1）票面信息表，找到出票人编号,汇票号码关联
        ON T.DRAFT_NBR =T1.BILL_NUM
       AND T1.DATA_DATE=I_DATADATE
     INNER JOIN SMTMODS_L_CUST_C T3 --（2）根据出票人编号找到企业规模
        ON T1.AFF_CODE = T3.CUST_ID
       AND T3.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.DATA_DATE = T.DATA_DATE
       AND TT.BASIC_CCY = T.CURR_CD
       and TT.FORWARD_CCY = 'CNY'
     WHERE T.DATA_DATE = I_DATADATE
       AND SUBSTR(T3.CUST_TYP, 1, 1) in ('1', '0')
       AND T.ACCT_TYP NOT LIKE '90%'
       AND T.LOAN_ACCT_BAL <> 0
       AND T.CANCEL_FLG <> 'Y'
       AND T3.CORP_SCALE IN ('B', 'M', 'S', 'T')
       AND T.ACCT_TYP = '030102' --030102 商业承兑汇票
       AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
       AND T.LOAN_STOCKEN_DATE IS NULL
       AND T.LOAN_ACCT_BAL <> 0;

--银承取数的逻辑
 INSERT INTO `S65_1_1_8..B`
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
       COL_14
       )
     SELECT 
            I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
            'CBRC'  AS SYS_NAM,  -- 模块简称
            'S6501' AS REP_NUM, -- 报表编号
            CASE WHEN T3.CORP_SIZE = '01' THEN 'S65_1_1_8..A'
                 WHEN T3.CORP_SIZE = '02' THEN 'S65_1_1_8..B'
                 WHEN T3.CORP_SIZE = '03' THEN 'S65_1_1_8..C'
                 WHEN T3.CORP_SIZE = '04' THEN 'S65_1_1_8..F'
                  END AS ITEM_NUM,
            (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB, --指标值
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
            T.JBYG_ID        -- 经办员工ID
      FROM SMTMODS_L_ACCT_LOAN T
     INNER JOIN (SELECT CUST_ID, ECIF_CUST_ID ,LEGAL_TYSHXYDM
           FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY ECIF_CUST_ID) RN,
                    T.*
               FROM SMTMODS_L_CUST_BILL_TY T
              WHERE DATA_DATE = I_DATADATE
                AND T.ORG_NUM NOT LIKE '5%'
                AND T.ORG_NUM NOT LIKE '6%') --对于总行客户来说，不需要取村镇ECIF客户
              WHERE RN = 1) T2 --（1）买断式转帖客户需要在转贴现同业客户信息表找到对应客户
        ON T.CUST_ID = T2.CUST_ID
     INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO T3 --（2）康哥反馈按照总行报送，客户外部信息表（万德债券投资表）存的是总行级别的，风险：刘名赫反馈交易对手在万德债券投资表都存在，不仅只有债券业务，也有票据的
        ON T2.LEGAL_TYSHXYDM = T3.USCD
       AND T3.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.DATA_DATE = T.DATA_DATE
       AND TT.BASIC_CCY = T.CURR_CD
       AND TT.FORWARD_CCY = 'CNY'
     WHERE T.DATA_DATE = I_DATADATE
       AND T.ACCT_TYP NOT LIKE '90%'
       AND T.CANCEL_FLG <> 'Y'
       AND T.LOAN_ACCT_BAL <> 0
       AND T3.CORP_SIZE IN ('01', '02', '03', '04')
       AND T.ACCT_TYP = '030101' --030101 银行承兑汇票
       AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
       AND T.LOAN_STOCKEN_DATE IS NULL
       AND T.LOAN_ACCT_BAL <> 0;


-- 指标: S65_1_1_7..C
--====================================================
    --   s6501 S65_1_1_1..C插入临时表
    --====================================================

 INSERT INTO `S65_1_1_7..C`
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
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..C'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..C'
                   END AS ITEM_NUM, --指标号
             (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) + (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS LOAN_ACCT_BAL_RMB, --指标值
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
         AND SUBSTR(T.ACCT_TYP, 1, 3) NOT IN ('B01', 'D01')
         AND B.CORP_SCALE = 'S'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') --ALTER BY WJB 20220518 增加农村合作社取数逻辑
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0;


-- 指标: S65_1_1_8..F
--====================================================
    --   s6501 S65_1_1_1..F插入临时表
    --====================================================

     INSERT INTO `S65_1_1_8..F`
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
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..F'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..F'
                  END AS ITEM_NUM, --指标号
             (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) + (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS COLLECT_VAL , --指标值
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
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND SUBSTR(T.ACCT_TYP, 1, 3) NOT IN ('B01', 'D01')
         AND B.CORP_SCALE = 'T'
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') -- 增加农村合作社取数逻辑
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0;

------=====================m3  add  by  zy 20240708  金融市场部 大中小微吉林省取数贷款余额逻辑   =====================
---转贴现=商承+银承
--商承取数逻辑
    INSERT INTO `S65_1_1_8..F`
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
             'S6501' AS REP_NUM, -- 报表编号
            CASE WHEN T3.CORP_SCALE = 'B' THEN 'S65_1_1_8..A'
                 WHEN T3.CORP_SCALE = 'M' THEN 'S65_1_1_8..B'
                 WHEN T3.CORP_SCALE = 'S' THEN 'S65_1_1_8..C'
                 WHEN T3.CORP_SCALE = 'T' THEN 'S65_1_1_8..F'
                  END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COLLECT_VAL, --指标值
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
             T3.CORP_HOLD_TYPE,-- 行业类别
             T3.CORP_SCALE,    -- 企业规模
             T3.CUST_TYP       -- 客户分类
      FROM SMTMODS_L_ACCT_LOAN T
     INNER JOIN SMTMODS_L_AGRE_BILL_INFO  T1   -- （1）票面信息表，找到出票人编号,汇票号码关联
        ON T.DRAFT_NBR =T1.BILL_NUM
       AND T1.DATA_DATE=I_DATADATE
     INNER JOIN SMTMODS_L_CUST_C T3 --（2）根据出票人编号找到企业规模
        ON T1.AFF_CODE = T3.CUST_ID
       AND T3.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.DATA_DATE = T.DATA_DATE
       AND TT.BASIC_CCY = T.CURR_CD
       and TT.FORWARD_CCY = 'CNY'
     WHERE T.DATA_DATE = I_DATADATE
       AND SUBSTR(T3.CUST_TYP, 1, 1) in ('1', '0')
       AND T.ACCT_TYP NOT LIKE '90%'
       AND T.LOAN_ACCT_BAL <> 0
       AND T.CANCEL_FLG <> 'Y'
       AND T3.CORP_SCALE IN ('B', 'M', 'S', 'T')
       AND T.ACCT_TYP = '030102' --030102 商业承兑汇票
       AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
       AND T.LOAN_STOCKEN_DATE IS NULL
       AND T.LOAN_ACCT_BAL <> 0;

--银承取数的逻辑
 INSERT INTO `S65_1_1_8..F`
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
       COL_14
       )
     SELECT 
            I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
            'CBRC'  AS SYS_NAM,  -- 模块简称
            'S6501' AS REP_NUM, -- 报表编号
            CASE WHEN T3.CORP_SIZE = '01' THEN 'S65_1_1_8..A'
                 WHEN T3.CORP_SIZE = '02' THEN 'S65_1_1_8..B'
                 WHEN T3.CORP_SIZE = '03' THEN 'S65_1_1_8..C'
                 WHEN T3.CORP_SIZE = '04' THEN 'S65_1_1_8..F'
                  END AS ITEM_NUM,
            (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB, --指标值
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
            T.JBYG_ID        -- 经办员工ID
      FROM SMTMODS_L_ACCT_LOAN T
     INNER JOIN (SELECT CUST_ID, ECIF_CUST_ID ,LEGAL_TYSHXYDM
           FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY ECIF_CUST_ID) RN,
                    T.*
               FROM SMTMODS_L_CUST_BILL_TY T
              WHERE DATA_DATE = I_DATADATE
                AND T.ORG_NUM NOT LIKE '5%'
                AND T.ORG_NUM NOT LIKE '6%') --对于总行客户来说，不需要取村镇ECIF客户
              WHERE RN = 1) T2 --（1）买断式转帖客户需要在转贴现同业客户信息表找到对应客户
        ON T.CUST_ID = T2.CUST_ID
     INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO T3 --（2）康哥反馈按照总行报送，客户外部信息表（万德债券投资表）存的是总行级别的，风险：刘名赫反馈交易对手在万德债券投资表都存在，不仅只有债券业务，也有票据的
        ON T2.LEGAL_TYSHXYDM = T3.USCD
       AND T3.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.DATA_DATE = T.DATA_DATE
       AND TT.BASIC_CCY = T.CURR_CD
       AND TT.FORWARD_CCY = 'CNY'
     WHERE T.DATA_DATE = I_DATADATE
       AND T.ACCT_TYP NOT LIKE '90%'
       AND T.CANCEL_FLG <> 'Y'
       AND T.LOAN_ACCT_BAL <> 0
       AND T3.CORP_SIZE IN ('01', '02', '03', '04')
       AND T.ACCT_TYP = '030101' --030101 银行承兑汇票
       AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
       AND T.LOAN_STOCKEN_DATE IS NULL
       AND T.LOAN_ACCT_BAL <> 0;


-- ========== 逻辑组 6: 共 2 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..O'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..O'
                   END AS ITEM_NUM, --指标号
             (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) + (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS COLLECT_VAL, --指标值
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
             D.CORP_HOLD_TYPE,-- 行业类别
             D.CORP_SCALE,    -- 企业规模
             D.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C D
          ON D.CUST_ID = A.CUST_ID
         AND D.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND A.INLANDORRSHORE_FLG = 'Y'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND (T.ACCT_TYP LIKE '0102%' OR T.ACCT_TYP LIKE '03%')
         AND (C.OPERATE_CUST_TYPE = 'A' OR A.CUST_TYPE = '3' OR
              D.CUST_TYP = '3')
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL<> 0
) q_6
INSERT INTO `S65_1_1_8..O` (DATA_DATE,
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
INSERT INTO `S65_1_1_7..O` (DATA_DATE,
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

-- 指标: S65_1_1_8..A
--====================================================
    --   s6501 S65_1_1_1..A插入临时表
    --====================================================

     INSERT INTO `S65_1_1_8..A`
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
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..A'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..A'
                   END AS ITEM_NUM, --指标号
             (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) + (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS LOAN_ACCT_BAL_RMB, --指标值
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
         AND SUBSTR(T.ACCT_TYP, 1, 3) NOT IN ('B01', 'D01') --客户分类
         AND B.CORP_SCALE = 'B'
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') --ALTER BY WJB 20220518 增加农村合作社取数逻辑
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0;

------=====================m3  add  by  zy 20240708  金融市场部 大中小微吉林省取数贷款余额逻辑   =====================
---转贴现=商承+银承
--商承取数逻辑
    INSERT INTO `S65_1_1_8..A`
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
             'S6501' AS REP_NUM, -- 报表编号
            CASE WHEN T3.CORP_SCALE = 'B' THEN 'S65_1_1_8..A'
                 WHEN T3.CORP_SCALE = 'M' THEN 'S65_1_1_8..B'
                 WHEN T3.CORP_SCALE = 'S' THEN 'S65_1_1_8..C'
                 WHEN T3.CORP_SCALE = 'T' THEN 'S65_1_1_8..F'
                  END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COLLECT_VAL, --指标值
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
             T3.CORP_HOLD_TYPE,-- 行业类别
             T3.CORP_SCALE,    -- 企业规模
             T3.CUST_TYP       -- 客户分类
      FROM SMTMODS_L_ACCT_LOAN T
     INNER JOIN SMTMODS_L_AGRE_BILL_INFO  T1   -- （1）票面信息表，找到出票人编号,汇票号码关联
        ON T.DRAFT_NBR =T1.BILL_NUM
       AND T1.DATA_DATE=I_DATADATE
     INNER JOIN SMTMODS_L_CUST_C T3 --（2）根据出票人编号找到企业规模
        ON T1.AFF_CODE = T3.CUST_ID
       AND T3.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.DATA_DATE = T.DATA_DATE
       AND TT.BASIC_CCY = T.CURR_CD
       and TT.FORWARD_CCY = 'CNY'
     WHERE T.DATA_DATE = I_DATADATE
       AND SUBSTR(T3.CUST_TYP, 1, 1) in ('1', '0')
       AND T.ACCT_TYP NOT LIKE '90%'
       AND T.LOAN_ACCT_BAL <> 0
       AND T.CANCEL_FLG <> 'Y'
       AND T3.CORP_SCALE IN ('B', 'M', 'S', 'T')
       AND T.ACCT_TYP = '030102' --030102 商业承兑汇票
       AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
       AND T.LOAN_STOCKEN_DATE IS NULL
       AND T.LOAN_ACCT_BAL <> 0;

--银承取数的逻辑
 INSERT INTO `S65_1_1_8..A`
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
       COL_14
       )
     SELECT 
            I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
            'CBRC'  AS SYS_NAM,  -- 模块简称
            'S6501' AS REP_NUM, -- 报表编号
            CASE WHEN T3.CORP_SIZE = '01' THEN 'S65_1_1_8..A'
                 WHEN T3.CORP_SIZE = '02' THEN 'S65_1_1_8..B'
                 WHEN T3.CORP_SIZE = '03' THEN 'S65_1_1_8..C'
                 WHEN T3.CORP_SIZE = '04' THEN 'S65_1_1_8..F'
                  END AS ITEM_NUM,
            (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB, --指标值
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
            T.JBYG_ID        -- 经办员工ID
      FROM SMTMODS_L_ACCT_LOAN T
     INNER JOIN (SELECT CUST_ID, ECIF_CUST_ID ,LEGAL_TYSHXYDM
           FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY ECIF_CUST_ID) RN,
                    T.*
               FROM SMTMODS_L_CUST_BILL_TY T
              WHERE DATA_DATE = I_DATADATE
                AND T.ORG_NUM NOT LIKE '5%'
                AND T.ORG_NUM NOT LIKE '6%') --对于总行客户来说，不需要取村镇ECIF客户
              WHERE RN = 1) T2 --（1）买断式转帖客户需要在转贴现同业客户信息表找到对应客户
        ON T.CUST_ID = T2.CUST_ID
     INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO T3 --（2）康哥反馈按照总行报送，客户外部信息表（万德债券投资表）存的是总行级别的，风险：刘名赫反馈交易对手在万德债券投资表都存在，不仅只有债券业务，也有票据的
        ON T2.LEGAL_TYSHXYDM = T3.USCD
       AND T3.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.DATA_DATE = T.DATA_DATE
       AND TT.BASIC_CCY = T.CURR_CD
       AND TT.FORWARD_CCY = 'CNY'
     WHERE T.DATA_DATE = I_DATADATE
       AND T.ACCT_TYP NOT LIKE '90%'
       AND T.CANCEL_FLG <> 'Y'
       AND T.LOAN_ACCT_BAL <> 0
       AND T3.CORP_SIZE IN ('01', '02', '03', '04')
       AND T.ACCT_TYP = '030101' --030101 银行承兑汇票
       AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
       AND T.LOAN_STOCKEN_DATE IS NULL
       AND T.LOAN_ACCT_BAL <> 0;


-- 指标: S65_1_1_8..C
--====================================================
    --   s6501 S65_1_1_1..C插入临时表
    --====================================================

 INSERT INTO `S65_1_1_8..C`
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
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..C'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..C'
                   END AS ITEM_NUM, --指标号
             (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) + (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS LOAN_ACCT_BAL_RMB, --指标值
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
         AND SUBSTR(T.ACCT_TYP, 1, 3) NOT IN ('B01', 'D01')
         AND B.CORP_SCALE = 'S'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') --ALTER BY WJB 20220518 增加农村合作社取数逻辑
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0;

------=====================m3  add  by  zy 20240708  金融市场部 大中小微吉林省取数贷款余额逻辑   =====================
---转贴现=商承+银承
--商承取数逻辑
    INSERT INTO `S65_1_1_8..C`
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
             'S6501' AS REP_NUM, -- 报表编号
            CASE WHEN T3.CORP_SCALE = 'B' THEN 'S65_1_1_8..A'
                 WHEN T3.CORP_SCALE = 'M' THEN 'S65_1_1_8..B'
                 WHEN T3.CORP_SCALE = 'S' THEN 'S65_1_1_8..C'
                 WHEN T3.CORP_SCALE = 'T' THEN 'S65_1_1_8..F'
                  END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COLLECT_VAL, --指标值
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
             T3.CORP_HOLD_TYPE,-- 行业类别
             T3.CORP_SCALE,    -- 企业规模
             T3.CUST_TYP       -- 客户分类
      FROM SMTMODS_L_ACCT_LOAN T
     INNER JOIN SMTMODS_L_AGRE_BILL_INFO  T1   -- （1）票面信息表，找到出票人编号,汇票号码关联
        ON T.DRAFT_NBR =T1.BILL_NUM
       AND T1.DATA_DATE=I_DATADATE
     INNER JOIN SMTMODS_L_CUST_C T3 --（2）根据出票人编号找到企业规模
        ON T1.AFF_CODE = T3.CUST_ID
       AND T3.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.DATA_DATE = T.DATA_DATE
       AND TT.BASIC_CCY = T.CURR_CD
       and TT.FORWARD_CCY = 'CNY'
     WHERE T.DATA_DATE = I_DATADATE
       AND SUBSTR(T3.CUST_TYP, 1, 1) in ('1', '0')
       AND T.ACCT_TYP NOT LIKE '90%'
       AND T.LOAN_ACCT_BAL <> 0
       AND T.CANCEL_FLG <> 'Y'
       AND T3.CORP_SCALE IN ('B', 'M', 'S', 'T')
       AND T.ACCT_TYP = '030102' --030102 商业承兑汇票
       AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
       AND T.LOAN_STOCKEN_DATE IS NULL
       AND T.LOAN_ACCT_BAL <> 0;

--银承取数的逻辑
 INSERT INTO `S65_1_1_8..C`
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
       COL_14
       )
     SELECT 
            I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
            'CBRC'  AS SYS_NAM,  -- 模块简称
            'S6501' AS REP_NUM, -- 报表编号
            CASE WHEN T3.CORP_SIZE = '01' THEN 'S65_1_1_8..A'
                 WHEN T3.CORP_SIZE = '02' THEN 'S65_1_1_8..B'
                 WHEN T3.CORP_SIZE = '03' THEN 'S65_1_1_8..C'
                 WHEN T3.CORP_SIZE = '04' THEN 'S65_1_1_8..F'
                  END AS ITEM_NUM,
            (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB, --指标值
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
            T.JBYG_ID        -- 经办员工ID
      FROM SMTMODS_L_ACCT_LOAN T
     INNER JOIN (SELECT CUST_ID, ECIF_CUST_ID ,LEGAL_TYSHXYDM
           FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY ECIF_CUST_ID) RN,
                    T.*
               FROM SMTMODS_L_CUST_BILL_TY T
              WHERE DATA_DATE = I_DATADATE
                AND T.ORG_NUM NOT LIKE '5%'
                AND T.ORG_NUM NOT LIKE '6%') --对于总行客户来说，不需要取村镇ECIF客户
              WHERE RN = 1) T2 --（1）买断式转帖客户需要在转贴现同业客户信息表找到对应客户
        ON T.CUST_ID = T2.CUST_ID
     INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO T3 --（2）康哥反馈按照总行报送，客户外部信息表（万德债券投资表）存的是总行级别的，风险：刘名赫反馈交易对手在万德债券投资表都存在，不仅只有债券业务，也有票据的
        ON T2.LEGAL_TYSHXYDM = T3.USCD
       AND T3.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.DATA_DATE = T.DATA_DATE
       AND TT.BASIC_CCY = T.CURR_CD
       AND TT.FORWARD_CCY = 'CNY'
     WHERE T.DATA_DATE = I_DATADATE
       AND T.ACCT_TYP NOT LIKE '90%'
       AND T.CANCEL_FLG <> 'Y'
       AND T.LOAN_ACCT_BAL <> 0
       AND T3.CORP_SIZE IN ('01', '02', '03', '04')
       AND T.ACCT_TYP = '030101' --030101 银行承兑汇票
       AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
       AND T.LOAN_STOCKEN_DATE IS NULL
       AND T.LOAN_ACCT_BAL <> 0;


-- 指标: S65_1_1_7..B
--====================================================
    --   s6501 S65_1_1_1..B插入临时表
    --====================================================

  INSERT INTO `S65_1_1_7..B`
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
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..B'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..B'
                   END AS ITEM_NUM, --指标号
             (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) + (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS LOAN_ACCT_BAL_RMB, --指标值
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
         AND SUBSTR(T.ACCT_TYP, 1, 3) NOT IN ('B01', 'D01')
         AND B.CORP_SCALE = 'M'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') --ALTER BY WJB 20220518 增加农村合作社取数逻辑
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0;


-- 指标: S65_1_1_7..F
--====================================================
    --   s6501 S65_1_1_1..F插入临时表
    --====================================================

     INSERT INTO `S65_1_1_7..F`
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
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..F'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..F'
                  END AS ITEM_NUM, --指标号
             (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) + (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS COLLECT_VAL , --指标值
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
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND SUBSTR(T.ACCT_TYP, 1, 3) NOT IN ('B01', 'D01')
         AND B.CORP_SCALE = 'T'
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') -- 增加农村合作社取数逻辑
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0;


