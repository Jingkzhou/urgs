-- ============================================================
-- 文件名: S66三大工程信贷统计表.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: S66_3_3.A
--授信项目数量 授信户数
 INSERT INTO `S66_3_3.A`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3 )

 SELECT 
          I_DATADATE AS DATA_DATE,
          CASE WHEN TMP.ORG_NUM = '009813' THEN  '130000'
               WHEN TMP.ORG_NUM LIKE '0601%' THEN '060300'
               WHEN (SUBSTR(TMP.ORG_NUM, 3, 4) = '9801') OR SUBSTR(TMP.ORG_NUM, 1, 4) = '0098' THEN TMP.ORG_NUM
               ELSE SUBSTR(TMP.ORG_NUM, 1, 4) || '00'
                END ORG_NUM,
          NULL AS DATA_DEPARTMENT,
          'CBRC'  AS SYS_NAM,  -- 模块简称
          'S66' AS REP_NUM, -- 报表编号
          'S66_3_3.A' AS ITEM_NUM,
          1 AS LOAN_ACCT_BAL_RMB,
          TMP.CUST_ID
     FROM (SELECT T.ORG_NUM, T.CUST_ID
             FROM (SELECT T.ORG_NUM, T.CUST_ID
                     FROM SMTMODS_L_AGRE_CREDITLINE T
                    INNER JOIN (SELECT A.CUST_ID
                                 FROM SMTMODS_L_ACCT_LOAN A
                                INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
                                   ON A.LOAN_NUM = T1.LOAN_NUM
                                  AND T1.DATA_DATE = I_DATADATE
                                  AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111'
                                WHERE A.ACCT_TYP NOT LIKE '90%'
                                  AND A.DATA_DATE = I_DATADATE
                                  AND A.CANCEL_FLG <> 'Y'
                                  AND A.ACCT_STS <> '3'
                                  AND A.LOAN_ACCT_BAL <> 0
                                  AND A.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
                                GROUP BY A.CUST_ID) T1
                       ON T1.CUST_ID = T.CUST_ID
                    WHERE T.DATA_DATE = I_DATADATE
                      AND T.FACILITY_TYP IN ('2', '4','1') -- 增加供应链授信部分统计对公授信
                      AND UPPER(T.FACILITY_STS) = 'Y' -- 授信状态有效
                    GROUP BY T.ORG_NUM, T.CUST_ID ) T
            GROUP BY T.ORG_NUM, T.CUST_ID) TMP;


-- 指标: S66_3_3.C
--有贷款余额的贷款数量
     INSERT INTO `S66_3_3.C`
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
       COL_15
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             T2.ORG_NUM,
             T2.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S66' AS REP_NUM, -- 报表编号
             'S66_3_3.C' AS ITEM_NUM,
             1 AS ITEM_VAL,
             T2.ACCT_NUM,      -- 合同号
             T2.LOAN_NUM,      -- 借据号
             T2.CUST_ID,       -- 客户号
             T2.ITEM_CD,       -- 科目号
             T2.CURR_CD,       -- 币种
             T2.DRAWDOWN_AMT,  -- 放款金额
             T2.DRAWDOWN_DT,   -- 放款日期
             T2.MATURITY_DT,   -- 原始到期日期
             T2.ACCT_TYP,      -- 账户类型
             T2.ACCT_TYP_DESC, -- 账户类型说明
             T2.ACCT_STS,      -- 账户状态
             T2.CANCEL_FLG,    -- 核销标志
             T2.LOAN_STOCKEN_DATE, -- 证券化日期
             T2.JBYG_ID,       -- 经办员工ID
             T1.PROPERTYLOAN_TYP   -- 房地产贷款类型
           FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
          INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
             ON T1.LOAN_NUM = T2.LOAN_NUM
            AND T1.DATA_DATE = T2.DATA_DATE
           LEFT JOIN SMTMODS_L_PUBL_RATE U
             ON T1.DATA_DATE = U.DATA_DATE
            AND U.CCY_DATE = I_DATADATE
            AND U.BASIC_CCY = T2.CURR_CD --基准币种
            AND U.FORWARD_CCY = 'CNY' --折算币种
          WHERE T1.DATA_DATE = I_DATADATE --取本期
            AND T2.ACCT_TYP NOT LIKE '90%'
            AND T2.CANCEL_FLG <> 'Y'
            AND T2.ACCT_STS <> '3'
            AND T2.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' --111  保障性住房开发贷款
            AND T2.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S66_3_3.I
INSERT INTO `S66_3_3.I`
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
       COL_15
       )
         SELECT 
                I_DATADATE AS DATA_DATE,
                C.ORG_NUM,
                T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
                'CBRC'  AS SYS_NAM,  -- 模块简称
                'S66' AS REP_NUM, -- 报表编号
                'S66_3_3.I' AS ITEM_NUM,
                (DRAWDOWN_AMT * TT.CCY_RATE)AS ITEM_VAL,
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
                T1.PROPERTYLOAN_TYP   -- 房地产贷款类型
           FROM SMTMODS_L_ACCT_LOAN T
          INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
             ON T.LOAN_NUM = T1.LOAN_NUM
            AND T1.DATA_DATE = I_DATADATE
           LEFT JOIN SMTMODS_L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
          INNER JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
             ON T.LOAN_NUM = C.LOAN_NUM
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.CANCEL_FLG <> 'Y'
            AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
            AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
            AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' --111  保障性住房开发贷款
            AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S66_3_3.B
--授信情况 授信金额
INSERT INTO `S66_3_3.B`
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3 )

        SELECT 
               I_DATADATE AS DATA_DATE,
               CASE WHEN T.ORG_NUM = '009813' THEN '130000'
                    WHEN T.ORG_NUM LIKE '0601%' THEN '060300'
                    WHEN (SUBSTR(T.ORG_NUM, 3, 4) = '9801') OR SUBSTR(T.ORG_NUM, 1, 4) = '0098' THEN T.ORG_NUM
                    ELSE SUBSTR(T.ORG_NUM, 1, 4) || '00'
                    END,
               NULL AS DATA_DEPARTMENT,
               'CBRC'  AS SYS_NAM,  -- 模块简称
               'S66' AS REP_NUM, -- 报表编号
               'S66_3_3.B' AS ITEM_NUM,
              (T.FACILITY_AMT * TT.CCY_RATE) AS FACILITY_AMT,
              T.CUST_ID
        FROM SMTMODS_L_AGRE_CREDITLINE T
       INNER JOIN (SELECT A.CUST_ID
                     FROM SMTMODS_L_ACCT_LOAN A
                    INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
                       ON A.LOAN_NUM = T1.LOAN_NUM
                      AND T1.DATA_DATE = I_DATADATE
                      AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111'
                    WHERE A.ACCT_TYP NOT LIKE '90%'
                      AND A.DATA_DATE = I_DATADATE
                      AND A.CANCEL_FLG <> 'Y'
                      AND A.ACCT_STS <> '3'
                      AND A.LOAN_ACCT_BAL <> 0
            AND A.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
                    GROUP BY A.CUST_ID) T1
          ON T1.CUST_ID = T.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.FACILITY_TYP IN ('2','4','1')   -- 增加供应链授信部分统计对公授信
         AND T.FACILITY_STS ='Y';


-- 指标: S66_3_3.M
INSERT INTO `S66_3_3.M`
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
       COL_15
       )
       SELECT 
                I_DATADATE AS DATA_DATE,
                T2.ORG_NUM,
                T2.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
                'CBRC'  AS SYS_NAM,  -- 模块简称
                'S66' AS REP_NUM, -- 报表编号
                CASE WHEN T2.LOAN_GRADE_CD = '1' THEN 'S66_3_3.M' --正常类
                     WHEN T2.LOAN_GRADE_CD = '2' THEN 'S66_3_3.N' --关注类
                     WHEN T2.LOAN_GRADE_CD = '3' THEN 'S66_3_3.P' --次级类
                     WHEN T2.LOAN_GRADE_CD = '4' THEN 'S66_3_3.Q' --可疑类
                     WHEN T2.LOAN_GRADE_CD = '5' THEN 'S66_3_3.R' --损失类
                      END AS ITEM_NUM,
                (T2.LOAN_ACCT_BAL * U.CCY_RATE) ITEM_VAL,
                T2.ACCT_NUM,      -- 合同号
                T2.LOAN_NUM,      -- 借据号
                T2.CUST_ID,       -- 客户号
                T2.ITEM_CD,       -- 科目号
                T2.CURR_CD,       -- 币种
                T2.DRAWDOWN_AMT,  -- 放款金额
                T2.DRAWDOWN_DT,   -- 放款日期
                T2.MATURITY_DT,   -- 原始到期日期
                T2.ACCT_TYP,      -- 账户类型
                T2.ACCT_TYP_DESC, -- 账户类型说明
                T2.ACCT_STS,      -- 账户状态
                T2.CANCEL_FLG,    -- 核销标志
                T2.LOAN_STOCKEN_DATE, -- 证券化日期
                T2.JBYG_ID,       -- 经办员工ID
                T1.PROPERTYLOAN_TYP   -- 房地产贷款类型
           FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
          INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
             ON T1.LOAN_NUM = T2.LOAN_NUM
            AND T1.DATA_DATE = T2.DATA_DATE
           LEFT JOIN SMTMODS_L_PUBL_RATE U
             ON T1.DATA_DATE = U.DATA_DATE
            AND U.CCY_DATE = I_DATADATE
            AND U.BASIC_CCY = T2.CURR_CD --基准币种
            AND U.FORWARD_CCY = 'CNY' --折算币种
          WHERE T1.DATA_DATE = I_DATADATE --取本期
            AND T2.ACCT_TYP NOT LIKE '90%'
            AND T2.CANCEL_FLG <> 'Y'
            AND T2.ACCT_STS <> '3'
            AND T2.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' --111  保障性住房开发贷款
            AND T2.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S66_3_3.J
INSERT INTO `S66_3_3.J`
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
       COL_15
       )
      SELECT 
             I_DATADATE AS DATA_DATE,
             C.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S66' AS REP_NUM, -- 报表编号
             'S66_3_3.J' AS ITEM_NUM,
             (T.DRAWDOWN_AMT * TT.CCY_RATE * C.REAL_INT_RAT / 100) AS ITEM_NUM, --放款金额*实际利率[执行利率(年)]/100
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
             T1.PROPERTYLOAN_TYP   -- 房地产贷款类型
             FROM SMTMODS_L_ACCT_LOAN T
            INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
               ON T.LOAN_NUM = T1.LOAN_NUM
              AND T1.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_L_PUBL_RATE TT
               ON TT.DATA_DATE = T.DATA_DATE
              AND TT.BASIC_CCY = T.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
            INNER JOIN CBRC_S6301_AMT_TMP1 C ---M7取放款时实际利率
               ON T.LOAN_NUM = C.LOAN_NUM
            WHERE T.DATA_DATE = I_DATADATE
              AND T.ACCT_TYP NOT LIKE '90%'
              AND T.CANCEL_FLG <> 'Y'
              AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
              AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
              AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' --111  保障性住房开发贷款
              AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S66_3_3.F
--期限为1年以内的贷款余额，期限为1-3年的贷款余额，期限为3-5年的贷款余额，期限为5年以上的贷款余额
     INSERT INTO `S66_3_3.F`
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
       COL_15
       )

      SELECT   
               I_DATADATE AS DATA_DATE,
               T2.ORG_NUM,
               T2.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
               'CBRC'  AS SYS_NAM,  -- 模块简称
               'S66' AS REP_NUM, -- 报表编号
               CASE WHEN (T2.MATURITY_DT - I_DATADATE) < 360 THEN 'S66_3_3.E'
                    WHEN (T2.MATURITY_DT - I_DATADATE) >= 360 AND (T2.MATURITY_DT - I_DATADATE) < 1080 THEN 'S66_3_3.F'
                    WHEN (T2.MATURITY_DT - I_DATADATE) >= 1080 AND (T2.MATURITY_DT - I_DATADATE) < 1800 THEN 'S66_3_3.G'
                    WHEN (T2.MATURITY_DT - I_DATADATE) > 1800 THEN 'S66_3_3.H'
                     END AS ITEM_NUM,
               (T2.LOAN_ACCT_BAL * U.CCY_RATE) ITEM_VAL,
               T2.ACCT_NUM,      -- 合同号
               T2.LOAN_NUM,      -- 借据号
               T2.CUST_ID,       -- 客户号
               T2.ITEM_CD,       -- 科目号
               T2.CURR_CD,       -- 币种
               T2.DRAWDOWN_AMT,  -- 放款金额
               T2.DRAWDOWN_DT,   -- 放款日期
               T2.MATURITY_DT,   -- 原始到期日期
               T2.ACCT_TYP,      -- 账户类型
               T2.ACCT_TYP_DESC, -- 账户类型说明
               T2.ACCT_STS,      -- 账户状态
               T2.CANCEL_FLG,    -- 核销标志
               T2.LOAN_STOCKEN_DATE, -- 证券化日期
               T2.JBYG_ID,       -- 经办员工ID
               T1.PROPERTYLOAN_TYP   -- 房地产贷款类型
          FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
         INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ T2 --贷款借据信息表 原始到期日
            ON T1.LOAN_NUM = T2.LOAN_NUM
           AND T1.DATA_DATE = T2.DATA_DATE
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON T1.DATA_DATE = U.DATA_DATE
           AND U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = T2.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE T1.DATA_DATE = I_DATADATE --取本期
           AND T2.ACCT_TYP NOT LIKE '90%'
           AND T2.CANCEL_FLG <> 'Y'
           AND T2.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
           AND T2.ACCT_STS <> '3'
           AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' -- 保障性住房开发贷款
           AND T2.LOAN_ACCT_BAL <> 0;


