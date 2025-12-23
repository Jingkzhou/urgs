CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s66(II_DATADATE IN STRING--跑批日期
                                              )
/******************************
  @author:djh
  @create-date:20240207
  @description:S66 “三大工程”贷款情况表
  @modification history:
  --需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨 修改内容：客户授信逻辑
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_A_REPT_DWD_S66
        CBRC_S6301_AMT_TMP1
集市表： SMTMODS_L_ACCT_LOAN
SMTMODS_L_ACCT_LOAN_REALESTATE
SMTMODS_L_AGRE_CREDITLINE
SMTMODS_L_PUBL_RATE
SMTMODS_V_PUB_IDX_DK_YSDQRJJ
  *******************************/
 IS
  V_SCHEMA        VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE     VARCHAR(30); --当前储存过程名称
  V_TAB_NAME      VARCHAR(30); --目标表名
  I_DATADATE      STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE      VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_DATADATE_YEAR VARCHAR(10); --数据日期(字符型)YYYY
  V_STEP_ID       INTEGER; --任务号
  V_STEP_DESC     VARCHAR(4000); --任务描述
  V_STEP_FLAG     INTEGER; --任务执行状态标识
  V_ERRORCODE     VARCHAR(20); --错误编码
  V_ERRORDESC     VARCHAR(280); --错误内容
  V_PER_NUM       VARCHAR(30); --报表编号
  II_STATUS       INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM        VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID       := 0;
    V_STEP_FLAG     := 0;
    V_STEP_DESC     := '参数初始化处理';
    V_PER_NUM       := 'S66';
    V_TAB_NAME      := 'CBRC_A_REPT_ITEM_VAL';
    I_DATADATE      := II_DATADATE;
    V_DATADATE      := TO_CHAR(DATE(I_DATADATE), 'YYYY-MM-DD');
    V_DATADATE_YEAR := TO_CHAR(DATE(I_DATADATE), 'YYYY');
    V_SYSTEM        := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_S66');

    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND REP_NUM = V_PER_NUM
       AND SYS_NAM = 'CBRC'
       AND FLAG = '2';
    COMMIT;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_PUB_DATA_COLLECT_S66';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S66';


    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC :='授信情况:授信项目数量';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  --授信项目数量 授信户数
 INSERT INTO CBRC_A_REPT_DWD_S66
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
     COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC :='授信情况:授信金额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     --授信情况 授信金额
INSERT INTO CBRC_A_REPT_DWD_S66
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
         AND T.FACILITY_STS ='Y' ;

     COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC :='贷款情况:存续项目数量';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --有贷款余额的贷款数量
     INSERT INTO CBRC_A_REPT_DWD_S66
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

    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC :='贷款情况:贷款期限';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   --期限为1年以内的贷款余额，期限为1-3年的贷款余额，期限为3-5年的贷款余额，期限为5年以上的贷款余额
     INSERT INTO CBRC_A_REPT_DWD_S66
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

    COMMIT;

 --依赖S6301累放数据临时表，配置依赖配置好
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC :='当年累放贷款额';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT INTO CBRC_A_REPT_DWD_S66
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
            AND T.LOAN_STOCKEN_DATE IS NULL ;   -- 资产未转让

     COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC :='当年累放贷款年化利息收益';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

       INSERT INTO CBRC_A_REPT_DWD_S66
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
              AND T.LOAN_STOCKEN_DATE IS NULL ;   -- 资产未转让

         COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC :='贷款五级分类情况';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


INSERT INTO CBRC_A_REPT_DWD_S66
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
            AND T2.LOAN_STOCKEN_DATE IS NULL;    -- 资产未转让
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC :='展期';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


INSERT INTO CBRC_A_REPT_DWD_S66
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
                  T1.ORG_NUM,
                  T2.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
                  'CBRC'  AS SYS_NAM,  -- 模块简称
                  'S66' AS REP_NUM, -- 报表编号
                  'S66_3_3.S' AS ITEM_NUM,
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
              AND EXTENDTERM_FLG = 'Y' --展期
              AND T2.LOAN_STOCKEN_DATE IS NULL ;   -- 资产未转让
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC :='贷款逾期情况';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
     --“1-30天”、“31-60天”、“61-90天”、“91-180天”、“181-360天”和“361天

INSERT INTO CBRC_A_REPT_DWD_S66
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
                T1.ORG_NUM,
                T2.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
                'CBRC'  AS SYS_NAM,  -- 模块简称
                'S66' AS REP_NUM, -- 报表编号
                CASE WHEN T2.OD_DAYS > 360 THEN 'S66_3_3.Z' --361天
                     WHEN T2.OD_DAYS > 180 THEN 'S66_3_3.Y' --181-360天
                     WHEN T2.OD_DAYS > 90 THEN  'S66_3_3.X' --91-180天
                     WHEN T2.OD_DAYS > 60 THEN  'S66_3_3.W' --61-90天
                     WHEN T2.OD_DAYS > 30 THEN  'S66_3_3.V' --31-60天
                     WHEN T2.OD_DAYS > 0 THEN   'S66_3_3.U' --1-30天
                      END ITEM_NUM,
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
            AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
            AND T2.LOAN_STOCKEN_DATE IS NULL ; -- 资产未转让
    COMMIT;

    --==================================================
    --汇总临时表值
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '汇总临时表值';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       DATA_DEPARTMENT
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'S66' AS REP_NUM,
             T.ITEM_NUM,
             SUM(TOTAL_VALUE) AS ITEM_VAL,
             '2' AS FLAG,
             DATA_DEPARTMENT
        FROM CBRC_A_REPT_DWD_S66 T
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM, T.ITEM_NUM,DATA_DEPARTMENT;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := V_PROCEDURE|| '全部处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   DBMS_OUTPUT.PUT_LINE('O_STATUS=0');
    DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=完成'); 
    ------------------------------------------------------------------

  END IF;

EXCEPTION
  WHEN OTHERS THEN
    V_ERRORCODE := SQLCODE;
    V_ERRORDESC := SUBSTR(SQLERRM, 1, 280);
    V_STEP_DESC := '发生异常。详细信息为，' || TO_CHAR(SQLCODE) ||
                   SUBSTR(SQLERRM, 1, 280);
				   
    DBMS_OUTPUT.PUT_LINE('O_STATUS=-1');
    DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=失败'); 
    --记录异常信息
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
     ROLLBACK;
   
END proc_cbrc_idx2_s66