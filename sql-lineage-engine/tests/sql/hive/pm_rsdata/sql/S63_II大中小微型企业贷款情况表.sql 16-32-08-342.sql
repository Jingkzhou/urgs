-- ============================================================
-- 文件名: S63_II大中小微型企业贷款情况表.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 3 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,  -- 数据日期
             T.ORG_NUM  AS ORG_NUM,   -- 机构号
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6302' AS REP_NUM, -- 报表编号
             CASE WHEN T.GUARANTY_TYP LIKE 'D%' THEN 'S63_2_2_1..H'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN 'S63_2_2_2..H'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN 'S63_2_2_3..H'
                  END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE ,
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
             NULL,            -- 贷款属性
             NULL,            -- 客户大类
             T.LOAN_GRADE_CD, -- 五级分类代码
             NULL,            -- 企业规模
             NULL,            -- 客户分类
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             P.OPERATE_CUST_TYPE -- 经营性客户类型
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND T.DATA_DATE = P.DATA_DATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG<>'Y'
         AND T.ACCT_STS<>'3'
         AND TT.FORWARD_CCY = 'CNY'
         AND P.OPERATE_CUST_TYPE = 'B'
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类-次级类贷款、可疑类贷款、损失类贷款
         AND T.LOAN_STOCKEN_DATE IS NULL
) q_0
INSERT INTO `S63_2_2_2..H` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20           ,  
      COL_21)
SELECT *
INSERT INTO `S63_2_2_1..H` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20           ,  
      COL_21)
SELECT *
INSERT INTO `S63_2_2_3..H` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20           ,  
      COL_21)
SELECT *;

-- ========== 逻辑组 1: 共 3 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,  -- 数据日期
             LOAN.ORG_NUM  AS ORG_NUM,   -- 机构号
             LOAN.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6302' AS REP_NUM, -- 报表编号
             CASE WHEN LOAN.GUARANTY_TYP LIKE 'D%' THEN 'S63_2_2_1..F' --信用贷款
                  WHEN LOAN.GUARANTY_TYP LIKE 'C%' THEN 'S63_2_2_2..F' --保证贷款
                  WHEN SUBSTR(LOAN.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN 'S63_2_2_3..F' --抵（质）押贷款
                  END AS ITEM_NUM,  -- 指标号
             (LOAN.LOAN_ACCT_BAL * TT.CCY_RATE) AS TOTAL_VALUE, -- 汇总值
             LOAN.ACCT_NUM,      -- 合同号
             LOAN.LOAN_NUM,      -- 借据号
             LOAN.CUST_ID,       -- 客户号
             LOAN.ITEM_CD,       -- 科目号
             LOAN.CURR_CD,       -- 币种
             LOAN.DRAWDOWN_AMT,  -- 放款金额
             LOAN.DRAWDOWN_DT,   -- 放款日期
             LOAN.MATURITY_DT,   -- 原始到期日期
             LOAN.ACCT_TYP,      -- 账户类型
             LOAN.ACCT_TYP_DESC, -- 账户类型说明
             LOAN.ACCT_STS,      -- 账户状态
             LOAN.CANCEL_FLG,    -- 核销标志
             NULL ,              -- 贷款属性
             NULL ,              -- 客户大类
             LOAN.LOAN_GRADE_CD, -- 五级分类代码
             NULL ,              -- 企业规模
             NULL ,              -- 客户分类
             LOAN.LOAN_STOCKEN_DATE, -- 证券化日期
             LOAN.JBYG_ID        -- 经办员工ID
        FROM SMTMODS_L_ACCT_LOAN LOAN
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = LOAN.DATA_DATE
         AND TT.BASIC_CCY = LOAN.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE LOAN.DATA_DATE = I_DATADATE
         AND LOAN.ACCT_TYP LIKE '0102%' --经营性贷款
         AND LOAN.LOAN_ACCT_BAL <> 0
         AND LOAN.ACCT_STS <> '3'
         AND LOAN.CANCEL_FLG<>'Y'
         AND TT.FORWARD_CCY = 'CNY'
         AND LOAN.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类-次级类贷款、可疑类贷款、损失类贷款
         AND LOAN.LOAN_STOCKEN_DATE IS NULL
) q_1
INSERT INTO `S63_2_2_1..F` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20)
SELECT *
INSERT INTO `S63_2_2_2..F` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20)
SELECT *
INSERT INTO `S63_2_2_3..F` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20)
SELECT *;

-- ========== 逻辑组 2: 共 3 个指标 ==========
FROM (
SELECT 
         I_DATADATE   AS DATA_DATE,  -- 数据日期
         LOAN.ORG_NUM AS ORG_NUM,   -- 机构号
         LOAN.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
         'CBRC'  AS SYS_NAM,  -- 模块简称
         'S6302' AS REP_NUM, -- 报表编号
         CASE WHEN C.CORP_SCALE = 'B' THEN 'S63_2_2_2..A' -- 大型企业不良贷款
              WHEN C.CORP_SCALE = 'M' THEN 'S63_2_2_2..B' -- 中型企业不良贷款
              WHEN C.CORP_SCALE = 'S' THEN 'S63_2_2_2..C' -- 小型企业不良贷款
              WHEN C.CORP_SCALE = 'T' THEN 'S63_2_2_2..D' -- 微型企业不良贷款
              END AS ITEM_NUM ,
        (LOAN.LOAN_ACCT_BAL * U.CCY_RATE) + (LOAN.INT_ADJEST_AMT * U.CCY_RATE) AS TOTAL_VALUE, -- 汇总值
        LOAN.ACCT_NUM,      -- 合同号
        LOAN.LOAN_NUM,      -- 借据号
        LOAN.CUST_ID,       -- 客户号
        LOAN.ITEM_CD,       -- 科目号
        LOAN.CURR_CD,       -- 币种
        LOAN.DRAWDOWN_AMT,  -- 放款金额
        LOAN.DRAWDOWN_DT,   -- 放款日期
        LOAN.MATURITY_DT,   -- 原始到期日期
        LOAN.ACCT_TYP,      -- 账户类型
        LOAN.ACCT_TYP_DESC, -- 账户类型说明
        LOAN.ACCT_STS,      -- 账户状态
        LOAN.CANCEL_FLG,    -- 核销标志
        GUA.LOAN_SUBTYPE,   -- 贷款属性
        T.CUST_TYPE,        -- 客户大类
        LOAN.LOAN_GRADE_CD, -- 五级分类代码
        C.CORP_SCALE,       -- 企业规模
        C.CUST_TYP,         -- 客户分类
        LOAN.LOAN_STOCKEN_DATE, -- 证券化日期
        LOAN.JBYG_ID        -- 经办员工ID
        FROM SMTMODS_L_ACCT_LOAN LOAN
       INNER JOIN SMTMODS_L_CUST_ALL T
          ON T.CUST_ID = LOAN.CUST_ID
         AND T.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT DATA_DATE, -- 数据日期
                          CONTRACT_NUM, -- 业务合同号
                          MAX(LOAN_SUBTYPE) AS LOAN_SUBTYPE, -- 贷款属性
                          SUM(COLL_MK_VAL_SUM) AS COLL_MK_VAL -- 押品市场价值和
                     FROM (SELECT A.DATA_DATE,
                                  A.CONTRACT_NUM,
                                  CASE WHEN B.GUAR_TYP = 'A0101' THEN  'C'
                                       WHEN B.GUAR_TYP = 'B0101' THEN  'D'
                                       WHEN B.GUAR_TYP IN ('C0101', 'C0201',  'C0301', 'C0302', 'C0401') THEN 'B'
                                       WHEN B.GUAR_TYP IS NULL THEN 'A'
                                       ELSE 'A'
                                       END AS LOAN_SUBTYPE,
                                  NVL(D.COLL_MK_VAL * U.CCY_RATE, 0) AS COLL_MK_VAL_SUM
                             FROM SMTMODS_L_AGRE_GUA_RELATION A
                             LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT B
                               ON A.GUAR_CONTRACT_NUM = B.GUAR_CONTRACT_NUM
                              AND B.DATA_DATE = I_DATADATE
                             LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_RELATION C
                               ON A.GUAR_CONTRACT_NUM = C.GUAR_CONTRACT_NUM
                              AND C.DATA_DATE = I_DATADATE
                             LEFT JOIN SMTMODS_L_AGRE_GUARANTY_INFO D
                               ON C.GUARANTEE_SERIAL_NUM =
                                  D.GUARANTEE_SERIAL_NUM
                              AND D.DATA_DATE = I_DATADATE
                             LEFT JOIN SMTMODS_L_PUBL_RATE U
                               ON U.CCY_DATE =
                                  I_DATADATE
                              AND U.BASIC_CCY = D.COLL_CCY -- 基准币种
                              AND U.FORWARD_CCY = 'CNY' -- 折算币种
                            WHERE C.GUAR_CUST_ID IS NOT NULL
                              AND A.DATA_DATE = I_DATADATE
                              AND GUAR_CONTRACT_STATUS = 'Y')
                    GROUP BY DATA_DATE, CONTRACT_NUM) GUA
          ON LOAN.ACCT_NUM = GUA.CONTRACT_NUM
         AND GUA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = LOAN.CURR_CD -- 基准币种
         AND U.FORWARD_CCY = 'CNY' -- 折算币种
       WHERE LOAN.ACCT_TYP NOT LIKE '90%'
         AND LOAN.ACCT_STS <> '3'
         AND LOAN.CANCEL_FLG<>'Y'
         AND LOAN.DATA_DATE = I_DATADATE
         AND NVL(GUA.LOAN_SUBTYPE, '0') = 'B'
         AND T.CUST_TYPE <> '00'
         AND LOAN.ACCT_TYP NOT IN ('030101', '030102')
         AND LOAN.LOAN_GRADE_CD IN ('3', '4', '5')
         AND C.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') -- 判断对公客户是企业
         AND C.CUST_TYP<>'3'
         AND LOAN.LOAN_STOCKEN_DATE IS NULL
         AND LOAN.LOAN_ACCT_BAL <> 0
) q_2
INSERT INTO `S63_2_2_2..D` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20)
SELECT *
INSERT INTO `S63_2_2_2..C` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20)
SELECT *
INSERT INTO `S63_2_2_2..B` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20)
SELECT *;

-- ========== 逻辑组 3: 共 3 个指标 ==========
FROM (
SELECT 
             I_DATADATE   AS DATA_DATE,  -- 数据日期
             LOAN.ORG_NUM AS ORG_NUM,   -- 机构号
             LOAN.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6302' AS REP_NUM, -- 报表编号
             CASE WHEN C.CORP_SCALE = 'B' THEN 'S63_2_2_1..A' -- 大型企业不良贷款
                  WHEN C.CORP_SCALE = 'M' THEN 'S63_2_2_1..B' -- 中型企业不良贷款
                  WHEN C.CORP_SCALE = 'S' THEN 'S63_2_2_1..C' -- 小型企业不良贷款
                  WHEN C.CORP_SCALE = 'T' THEN 'S63_2_2_1..D' -- 微型企业不良贷款
                   END AS ITEM_NUM,  -- 指标号
             (LOAN.LOAN_ACCT_BAL * U.CCY_RATE) +(LOAN.INT_ADJEST_AMT * U.CCY_RATE) AS TOTAL_VALUE, -- 汇总值
             LOAN.ACCT_NUM,      -- 合同号
             LOAN.LOAN_NUM,      -- 借据号
             LOAN.CUST_ID,       -- 客户号
             LOAN.ITEM_CD,       -- 科目号
             LOAN.CURR_CD,       -- 币种
             LOAN.DRAWDOWN_AMT,  -- 放款金额
             LOAN.DRAWDOWN_DT,   -- 放款日期
             LOAN.MATURITY_DT,   -- 原始到期日期
             LOAN.ACCT_TYP,      -- 账户类型
             LOAN.ACCT_TYP_DESC, -- 账户类型说明
             LOAN.ACCT_STS,      -- 账户状态
             LOAN.CANCEL_FLG,    -- 核销标志
             GUA.LOAN_SUBTYPE,   -- 贷款属性
             T.CUST_TYPE,        -- 客户大类
             LOAN.LOAN_GRADE_CD, -- 五级分类代码
             C.CORP_SCALE,       -- 企业规模
             C.CUST_TYP,         -- 客户分类
             LOAN.LOAN_STOCKEN_DATE, -- 证券化日期
             LOAN.JBYG_ID        -- 经办员工ID
        FROM SMTMODS_L_ACCT_LOAN LOAN
       INNER JOIN SMTMODS_L_CUST_ALL T
          ON T.CUST_ID = LOAN.CUST_ID
         AND T.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT DATA_DATE, --数据日期
                          CONTRACT_NUM, --业务合同号
                          MAX(LOAN_SUBTYPE) AS LOAN_SUBTYPE, --贷款属性
                          SUM(COLL_MK_VAL_SUM) AS COLL_MK_VAL   --押品市场价值和
                     FROM (SELECT A.DATA_DATE,
                                  A.CONTRACT_NUM,
                                  CASE WHEN B.GUAR_TYP = 'A0101' THEN 'C'
                                       WHEN B.GUAR_TYP = 'B0101' THEN 'D'
                                       WHEN B.GUAR_TYP IN ('C0101','C0201','C0301','C0302','C0401') THEN 'B'
                                       WHEN B.GUAR_TYP IS NULL THEN 'A'
                                       ELSE 'A'
                                       END AS LOAN_SUBTYPE,
                                  NVL(D.COLL_MK_VAL * U.CCY_RATE, 0) AS COLL_MK_VAL_SUM
                             FROM SMTMODS_L_AGRE_GUA_RELATION A
                             LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT B
                               ON A.GUAR_CONTRACT_NUM = B.GUAR_CONTRACT_NUM
                              AND B.DATA_DATE = I_DATADATE
                             LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_RELATION C
                               ON A.GUAR_CONTRACT_NUM = C.GUAR_CONTRACT_NUM
                              AND C.DATA_DATE = I_DATADATE
                             LEFT JOIN SMTMODS_L_AGRE_GUARANTY_INFO D
                               ON C.GUARANTEE_SERIAL_NUM = D.GUARANTEE_SERIAL_NUM
                              AND D.DATA_DATE = I_DATADATE
                             LEFT JOIN SMTMODS_L_PUBL_RATE U
                               ON U.CCY_DATE = I_DATADATE
                              AND U.BASIC_CCY = D.COLL_CCY --基准币种
                              AND U.FORWARD_CCY = 'CNY' --折算币种
                            WHERE C.GUAR_CUST_ID IS NOT NULL
                              AND A.DATA_DATE = I_DATADATE
                              AND GUAR_CONTRACT_STATUS = 'Y')
                    GROUP BY DATA_DATE, CONTRACT_NUM) GUA
          ON LOAN.ACCT_NUM = GUA.CONTRACT_NUM
         AND GUA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = LOAN.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON LOAN.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE LOAN.ACCT_TYP NOT LIKE '90%'
         AND LOAN.ACCT_STS <> '3'
         AND LOAN.CANCEL_FLG<>'Y'
         AND LOAN.DATA_DATE = I_DATADATE
         AND NVL(GUA.LOAN_SUBTYPE, '0') NOT IN ('B', 'C', 'D')
         AND T.CUST_TYPE <> '00'
         AND LOAN.ACCT_TYP NOT IN ('B01', 'C01', 'D01', '030101', '030102')
         AND LOAN.LOAN_GRADE_CD IN ('3', '4', '5')
         AND LOAN.LOAN_ACCT_BAL<>0
         AND C.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0')
         AND C.CUST_TYP<>'3'  --剔除个体工商户
         AND LOAN.LOAN_STOCKEN_DATE IS NULL
) q_3
INSERT INTO `S63_2_2_1..D` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20)
SELECT *
INSERT INTO `S63_2_2_1..C` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20)
SELECT *
INSERT INTO `S63_2_2_1..B` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20)
SELECT *;

-- ========== 逻辑组 4: 共 3 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,  -- 数据日期
             T.ORG_NUM  AS ORG_NUM,   -- 机构号
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6302' AS REP_NUM, -- 报表编号
             CASE WHEN T.GUARANTY_TYP LIKE 'D%' THEN 'S63_2_2_1..G'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN 'S63_2_2_2..G'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN 'S63_2_2_3..G'
                  END  AS ITEM_NUM ,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS TOTAL_VALUE, -- 汇总值
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
             NULL,            -- 贷款属性
             NULL,            -- 客户大类
             T.LOAN_GRADE_CD, -- 五级分类代码
             C.CORP_SCALE,       -- 企业规模
             C.CUST_TYP,         -- 客户分类
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             P.OPERATE_CUST_TYPE -- 经营性客户类型
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND T.DATA_DATE = P.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND T.DATA_DATE = C.DATA_DATE
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG<>'Y'
         AND T.ACCT_STS<>'3'
         AND TT.FORWARD_CCY = 'CNY'
         AND (P.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3')
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类-次级类贷款、可疑类贷款、损失类贷款
         AND T.LOAN_STOCKEN_DATE IS NULL
       ORDER BY T.ORG_NUM
) q_4
INSERT INTO `S63_2_2_2..G` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20           ,  
      COL_21)
SELECT *
INSERT INTO `S63_2_2_1..G` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20           ,  
      COL_21)
SELECT *
INSERT INTO `S63_2_2_3..G` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20           ,  
      COL_21)
SELECT *;

-- ========== 逻辑组 5: 共 4 个指标 ==========
FROM (
SELECT 
             I_DATADATE AS DATA_DATE,  -- 数据日期
             LOAN.ORG_NUM  AS ORG_NUM,   -- 机构号
             LOAN.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6302' AS REP_NUM, -- 报表编号
             CASE WHEN C.CORP_SCALE = 'B' THEN 'S63_2_2_3..A' --大型企业不良贷款
                  WHEN C.CORP_SCALE = 'M' THEN 'S63_2_2_3..B' --中型企业不良贷款
                  WHEN C.CORP_SCALE = 'S' THEN 'S63_2_2_3..C' --小型企业不良贷款
                  WHEN C.CORP_SCALE = 'T' THEN 'S63_2_2_3..D' --微型企业不良贷款
                   END AS ITEM_NUM,
             (LOAN.LOAN_ACCT_BAL * U.CCY_RATE) + (LOAN.INT_ADJEST_AMT * U.CCY_RATE) AS TOTAL_VALUE,
             LOAN.ACCT_NUM,      -- 合同号
             LOAN.LOAN_NUM,      -- 借据号
             LOAN.CUST_ID,       -- 客户号
             LOAN.ITEM_CD,       -- 科目号
             LOAN.CURR_CD,       -- 币种
             LOAN.DRAWDOWN_AMT,  -- 放款金额
             LOAN.DRAWDOWN_DT,   -- 放款日期
             LOAN.MATURITY_DT,   -- 原始到期日期
             LOAN.ACCT_TYP,      -- 账户类型
             LOAN.ACCT_TYP_DESC, -- 账户类型说明
             LOAN.ACCT_STS,      -- 账户状态
             LOAN.CANCEL_FLG,    -- 核销标志
             GUA.LOAN_SUBTYPE,   -- 贷款属性
             T.CUST_TYPE,        -- 客户大类
             LOAN.LOAN_GRADE_CD, -- 五级分类代码
             C.CORP_SCALE,       -- 企业规模
             C.CUST_TYP,         -- 客户分类
             LOAN.LOAN_STOCKEN_DATE, -- 证券化日期
             LOAN.JBYG_ID        -- 经办员工ID
        FROM SMTMODS_L_ACCT_LOAN LOAN
       INNER JOIN SMTMODS_L_CUST_ALL T
          ON T.CUST_ID = LOAN.CUST_ID
         AND T.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT DATA_DATE, --数据日期
                          CONTRACT_NUM, --业务合同号
                          MAX(LOAN_SUBTYPE) AS LOAN_SUBTYPE, --贷款属性
                          SUM(COLL_MK_VAL_SUM) AS COLL_MK_VAL  --押品市场价值和
                     FROM (SELECT A.DATA_DATE,
                                  A.CONTRACT_NUM,
                                  CASE WHEN B.GUAR_TYP = 'A0101' THEN 'C'
                                       WHEN B.GUAR_TYP = 'B0101' THEN 'D'
                                       WHEN B.GUAR_TYP IN ('C0101','C0201','C0301','C0302','C0401') THEN 'B'
                                       WHEN B.GUAR_TYP IS NULL THEN 'A'
                                       ELSE 'A'
                                       END AS LOAN_SUBTYPE,
                                  NVL(D.COLL_MK_VAL * U.CCY_RATE, 0) AS COLL_MK_VAL_SUM
                             FROM SMTMODS_L_AGRE_GUA_RELATION A
                             LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT B
                               ON A.GUAR_CONTRACT_NUM = B.GUAR_CONTRACT_NUM
                              AND B.DATA_DATE = I_DATADATE
                             LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_RELATION C
                               ON A.GUAR_CONTRACT_NUM = C.GUAR_CONTRACT_NUM
                              AND C.DATA_DATE = I_DATADATE
                             LEFT JOIN SMTMODS_L_AGRE_GUARANTY_INFO D
                               ON C.GUARANTEE_SERIAL_NUM =
                                  D.GUARANTEE_SERIAL_NUM
                              AND D.DATA_DATE = I_DATADATE
                             LEFT JOIN SMTMODS_L_PUBL_RATE U
                               ON U.CCY_DATE =
                                  I_DATADATE
                              AND U.BASIC_CCY = D.COLL_CCY -- 基准币种
                              AND U.FORWARD_CCY = 'CNY' -- 折算币种
                            WHERE C.GUAR_CUST_ID IS NOT NULL
                              AND A.DATA_DATE = I_DATADATE
                              AND GUAR_CONTRACT_STATUS = 'Y')
                    GROUP BY DATA_DATE, CONTRACT_NUM) GUA
          ON LOAN.ACCT_NUM = GUA.CONTRACT_NUM
         AND GUA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = LOAN.CURR_CD -- 基准币种
         AND U.FORWARD_CCY = 'CNY' -- 折算币种
       WHERE LOAN.ACCT_TYP NOT LIKE '90%'
         AND LOAN.ACCT_STS <> '3'
         AND LOAN.DATA_DATE = I_DATADATE
         AND NVL(GUA.LOAN_SUBTYPE, '0') IN ('C', 'D')
         AND T.CUST_TYPE <> '00'
         AND LOAN.CANCEL_FLG<>'Y'
         AND LOAN.ACCT_TYP NOT IN ('B01', 'C01', 'D01', '030101', '030102')
         AND LOAN.LOAN_GRADE_CD IN ('3', '4', '5')
         AND C.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND substr(C.CUST_TYP, 1, 1) in ('1', '0') -- 判断对公客户是企业
         AND C.CUST_TYP <>'3'
         AND LOAN.LOAN_STOCKEN_DATE IS NULL
) q_5
INSERT INTO `S63_2_2_3..A` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20)
SELECT *
INSERT INTO `S63_2_2_3..B` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20)
SELECT *
INSERT INTO `S63_2_2_3..D` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20)
SELECT *
INSERT INTO `S63_2_2_3..C` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20)
SELECT *;

-- ========== 逻辑组 6: 共 2 个指标 ==========
FROM (
SELECT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6302' AS REP_NUM, -- 报表编号
             CASE WHEN C.CORP_SCALE = 'B' THEN 'S63_2_2_5..A' --大型企业不良贷款
                  WHEN C.CORP_SCALE = 'M' THEN 'S63_2_2_5..B' --中型企业不良贷款
                  WHEN C.CORP_SCALE = 'S' THEN 'S63_2_2_5..C' --小型企业不良贷款
                  WHEN C.CORP_SCALE = 'T' THEN 'S63_2_2_5..D' --微型企业不良贷款
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
             NULL,            -- 贷款属性
             NULL,            -- 客户大类
             T.LOAN_GRADE_CD, -- 五级分类代码
             C.CORP_SCALE,    -- 企业规模
             C.CUST_TYP,      -- 客户分类
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             NULL,            -- 经营性客户类型
             T.TAX_RELATED_FLG    -- 银税贷款标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C C  ---对公客户补充信息表
          ON T.CUST_ID = C.CUST_ID
         AND T.DATA_DATE = C.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT  --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         AND C.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') -- 判断对公客户是企业
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') -- 五级分类-次级类贷款、可疑类贷款、损失类贷款
         AND T.TAX_RELATED_FLG ='Y' -- 银税贷款标志
) q_6
INSERT INTO `S63_2_2_5..C` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20           ,  
      COL_21           ,  
      COL_22)
SELECT *
INSERT INTO `S63_2_2_5..D` (DATA_DATE        ,  
      ORG_NUM          ,  
      DATA_DEPARTMENT  ,  
      SYS_NAM          ,  
      REP_NUM          ,  
      ITEM_NUM         ,  
      TOTAL_VALUE      ,  
      COL_1            ,  
      COL_2            ,  
      COL_3            ,  
      COL_4            ,  
      COL_5            ,  
      COL_6            ,  
      COL_7            ,  
      COL_8            ,  
      COL_9            ,  
      COL_10           ,  
      COL_12           ,  
      COL_13           ,  
      COL_14           ,  
      COL_15           ,  
      COL_16           ,  
      COL_17           ,  
      COL_18           ,  
      COL_19           ,  
      COL_20           ,  
      COL_21           ,  
      COL_22)
SELECT *;

