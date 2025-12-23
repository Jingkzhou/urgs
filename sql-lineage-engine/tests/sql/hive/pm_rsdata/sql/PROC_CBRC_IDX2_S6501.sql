CREATE OR REPLACE PROCEDURE PROC_CBRC_IDX2_S6501(II_DATADATE IN STRING --跑批日期
                                              )
/******************************
  @author:fanxiaoyu
  @create-date:2015-09-22
  @description:S6501
  @modification history:
  m0.20150919-fanxiaoyu-S6501
  m1.20160406-shenyunfei-S6501 处理CUST_ALL
  m2.20160427.shenyunfei.2016制度升级，取消所有I/J/K列指标
  m3.20240708.zy  添加金融市场部大中小微余额的取数逻辑
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_A_REPT_DWD_S6501
集市表：SMTMODS_L_ACCT_LOAN
SMTMODS_L_AGRE_BILL_INFO
SMTMODS_L_CUST_ALL
SMTMODS_L_CUST_BILL_TY
SMTMODS_L_CUST_C
SMTMODS_L_CUST_EXTERNAL_INFO
SMTMODS_L_CUST_P
SMTMODS_L_PUBL_RATE
  *******************************/
 IS
  --V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  --V_DATADATE     VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS    INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM     VARCHAR(30);
    
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    I_DATADATE := II_DATADATE;
    V_PROCEDURE := UPPER('BSP_SP_CBRC_IDX2_S6501');
    V_TAB_NAME  := 'S6501';
	V_SYSTEM    := 'CBRC';

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    D_DATADATE_CCY := I_DATADATE;

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..A插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
				
    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND REP_NUM = V_TAB_NAME
       AND SYS_NAM = 'CBRC'
       AND FLAG = '2';
    COMMIT;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S6501';

    --====================================================
    --   s6501 S65_1_1_1..A插入临时表
    --====================================================

     INSERT INTO CBRC_A_REPT_DWD_S6501
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

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 's6501 S65_1_1_1..A插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..B插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   s6501 S65_1_1_1..B插入临时表
    --====================================================

  INSERT INTO CBRC_A_REPT_DWD_S6501
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
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..B插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..C插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   s6501 S65_1_1_1..C插入临时表
    --====================================================

 INSERT INTO CBRC_A_REPT_DWD_S6501
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
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..C插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..D插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   s6501 S65_1_1_1..D插入临时表
    --====================================================


   INSERT INTO CBRC_A_REPT_DWD_S6501
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
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..D'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..D'
                   END AS ITEM_NUM, --指标号
             (T.DRAWDOWN_AMT * U.CCY_RATE) AS COLLECT_VAL, --指标值
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
       INNER JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND SUBSTR(T.ACCT_TYP, 1, 3) NOT IN ('B01', 'D01')
         AND B.CORP_SCALE = 'S'
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') --ALTER BY WJB 20220518 增加农村合作社取数逻辑
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND T.LOAN_STOCKEN_DATE IS NULL;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..D插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..E插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     INSERT INTO CBRC_A_REPT_DWD_S6501
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_20
       )
       SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..E'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..E'
             END AS ITEM_NUM, --指标号
             1 AS COLLECT_VAL, --指标值
             T.CUST_ID,
             B.CUST_NAM
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND SUBSTR(T.ACCT_TYP, 1, 3) NOT IN ('B01', 'D01')
         AND B.CORP_SCALE = 'S'
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') --  增加农村合作社取数逻辑
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND T.LOAN_STOCKEN_DATE IS NULL;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..E插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..F插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   s6501 S65_1_1_1..F插入临时表
    --====================================================

     INSERT INTO CBRC_A_REPT_DWD_S6501
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

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..F插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..G插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   s6501 S65_1_1_1..G插入临时表
    --====================================================

  INSERT INTO CBRC_A_REPT_DWD_S6501
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
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..G'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..G'
                   END AS ITEM_NUM, --指标号
             (T.DRAWDOWN_AMT * U.CCY_RATE) AS COLLECT_VAL, --指标值
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
       INNER JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND SUBSTR(T.ACCT_TYP, 1, 3) NOT IN ('B01', 'D01')
         AND B.CORP_SCALE = 'T'
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') --ALTER BY WJB 20220518 增加农村合作社取数逻辑
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND T.LOAN_STOCKEN_DATE IS NULL;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..G插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..H插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   s6501 S65_1_1_1..H插入临时表
    --====================================================

     INSERT INTO CBRC_A_REPT_DWD_S6501
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_20
       )
      SELECT DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN SUBSTR(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..H'
                  WHEN SUBSTR(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..H'
                   END AS ITEM_NUM, --指标号
             1 AS COLLECT_VAL, --指标值
             T.CUST_ID,
             B.CUST_NAM
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE =  I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND SUBSTR(T.ACCT_TYP, 1, 3) NOT IN ('B01', 'D01')
         AND B.CORP_SCALE = 'T'
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0')
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND T.LOAN_STOCKEN_DATE IS NULL;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..H插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..I插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..L插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   s6501 S65_1_1_1..L插入临时表
    --====================================================

   INSERT INTO CBRC_A_REPT_DWD_S6501
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
         AND T.LOAN_ACCT_BAL<> 0;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..L插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..M插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   s6501 S65_1_1_1..M插入临时表
    --====================================================

   INSERT INTO CBRC_A_REPT_DWD_S6501
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
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..M'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..M'
                   END AS ITEM_NUM, --指标号
             (T.DRAWDOWN_AMT * U.CCY_RATE) AS COLLECT_VAL, --指标值
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
       WHERE T.ACCT_TYP NOT LIKE '90%'
         AND T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND (T.ACCT_TYP LIKE '0102%' OR T.ACCT_TYP LIKE '03%')
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND T.LOAN_STOCKEN_DATE IS NULL;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..M插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..N插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   s6501 S65_1_1_1..N插入临时表
    --====================================================

   INSERT INTO CBRC_A_REPT_DWD_S6501
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
             NULL AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..N'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..N'
                   END AS ITEM_NUM, --指标号
             1 AS COLLECT_VAL, --指标值
             T.CUST_ID
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.ACCT_TYP NOT LIKE '90%'
         AND T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND (T.ACCT_TYP LIKE '0102%' OR T.ACCT_TYP LIKE '03%')
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND T.LOAN_STOCKEN_DATE IS NULL;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..N插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..O插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   s6501 S65_1_1_1..O插入临时表
    --====================================================

     INSERT INTO CBRC_A_REPT_DWD_S6501
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
         AND T.LOAN_ACCT_BAL<> 0;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..O插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..P插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   s6501 S65_1_1_1..P插入临时表
    --====================================================

  INSERT INTO CBRC_A_REPT_DWD_S6501
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
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..P'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..P'
                   END AS ITEM_NUM, --指标号
             (T.DRAWDOWN_AMT * U.CCY_RATE) AS COLLECT_VAL, --指标值
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
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE =  I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
       WHERE (T.ACCT_TYP LIKE '0102%' OR T.ACCT_TYP LIKE '03%')
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND T.CANCEL_FLG = 'N'
         AND T.DATA_DATE = I_DATADATE
         AND LENGTHB(T.ACCT_NUM) < 36
         AND EXISTS (SELECT 1
                FROM SMTMODS_L_ACCT_LOAN T1
               INNER JOIN SMTMODS_L_CUST_ALL A
                  ON A.CUST_ID = T1.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_CUST_P C
                  ON A.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_CUST_C D
                  ON D.CUST_ID = A.CUST_ID
                 AND D.DATA_DATE = I_DATADATE
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.ACCT_TYP NOT LIKE '90%' --委托贷款
                 AND T.CUST_ID = T1.CUST_ID
                 AND T1.CANCEL_FLG = 'N'
         AND T1.LOAN_STOCKEN_DATE IS NULL
                 AND LENGTHB(T1.ACCT_NUM) < 36
                 AND (C.OPERATE_CUST_TYPE = 'A' OR
                     A.CUST_TYPE = '3' OR D.CUST_TYP = '3')
                 AND A.INLANDORRSHORE_FLG = 'Y')
         AND T.LOAN_STOCKEN_DATE IS NULL;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..P插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..Q插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   s6501 S65_1_1_1..Q插入临时表
    --====================================================

  INSERT INTO CBRC_A_REPT_DWD_S6501
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       TOTAL_VALUE,
       COL_3,
       COL_20
       )
      SELECT 
             DISTINCT
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             NULL AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(T.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..Q'
                  WHEN substr(T.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..Q'
                   END AS ITEM_NUM, --指标号
             1 AS COLLECT_VAL, --指标值
             T.CUST_ID,
             A.CUST_NAM
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID = A.CUST_ID
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
       WHERE T.ACCT_TYP NOT LIKE '90%'
         AND T.DATA_DATE = I_DATADATE
         AND A.INLANDORRSHORE_FLG = 'Y'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND (T.ACCT_TYP LIKE '0102%' OR T.ACCT_TYP LIKE '03%')
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) =  SUBSTR(I_DATADATE, 1, 4)
         AND (C.OPERATE_CUST_TYPE = 'A' OR A.CUST_TYPE = '3' OR
              D.CUST_TYP = '3')
         AND T.LOAN_STOCKEN_DATE IS NULL;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..Q插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..R插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   s6501 S65_1_1_1..R插入临时表
    --====================================================

    INSERT INTO CBRC_A_REPT_DWD_S6501
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
         AND T.LOAN_ACCT_BAL <> 0;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..R插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..S插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   s6501 S65_1_1_1..S插入临时表
    --====================================================

 INSERT INTO CBRC_A_REPT_DWD_S6501
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
             A.ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6501' AS REP_NUM, -- 报表编号
              CASE WHEN substr(A.ORG_NUM, 1, 1) = '1' THEN 'S65_1_1_7..S'
                   WHEN substr(A.ORG_NUM, 1, 1) = '0' THEN 'S65_1_1_8..S'
                    END AS ITEM_NUM, --指标号
             (A.DRAWDOWN_AMT * U.CCY_RATE) AS COLLECT_VAL, --指标值
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
             A.JBYG_ID        -- 经办员工ID
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE =  I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE (A.ACCT_TYP LIKE '0102%' OR A.ACCT_TYP LIKE '03%')
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) =  SUBSTR(I_DATADATE, 1, 4)
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.CANCEL_FLG = 'N'
         AND A.DATA_DATE = I_DATADATE
         AND LENGTHB(A.ACCT_NUM) < 36
         AND EXISTS (SELECT 1
                FROM  SMTMODS_L_CUST_P C
               WHERE A.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = A.DATA_DATE
                 AND C.OPERATE_CUST_TYPE = 'B')
         AND A.LOAN_STOCKEN_DATE IS NULL;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..S插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S65_1_1_1..T插入临时表  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   s6501 S65_1_1_1..T插入临时表
    --====================================================

   INSERT INTO CBRC_A_REPT_DWD_S6501
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
             A.ORG_NUM,
             NULL AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6501' AS REP_NUM, -- 报表编号
             CASE WHEN substr(A.ORG_NUM, 1, 1) = '1' THEN  'S65_1_1_7..T'
                  WHEN substr(A.ORG_NUM, 1, 1) = '0' THEN  'S65_1_1_8..T'
                   END AS ITEM_NUM, --指标号
             1 AS COLLECT_VAL, --指标值
             A.CUST_ID
        FROM SMTMODS_L_ACCT_LOAN A
       WHERE (A.ACCT_TYP LIKE '0102%' OR A.ACCT_TYP LIKE '03%')
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) =
             SUBSTR(I_DATADATE, 1, 4)
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.CANCEL_FLG = 'N'
         AND A.DATA_DATE = I_DATADATE
         AND LENGTHB(A.ACCT_NUM) < 36
         AND EXISTS (SELECT 1
                FROM SMTMODS_L_CUST_P C
               WHERE A.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
                 AND C.OPERATE_CUST_TYPE = 'B')
         AND A.LOAN_STOCKEN_DATE IS NULL;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'S65_1_1_1..T插入临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

------=====================m3  add  by  zy 20240708  金融市场部 大中小微吉林省取数贷款余额逻辑   =====================
---转贴现=商承+银承
--商承取数逻辑
    INSERT INTO CBRC_A_REPT_DWD_S6501
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

     COMMIT ;

--银承取数的逻辑
 INSERT INTO CBRC_A_REPT_DWD_S6501
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

    COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := 's6501插入金融市场部临时表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
------=====================m3  add  by  zy 20240708  金融市场部 大中小微吉林省取数贷款余额逻辑  =====================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '插入指标表  逻辑处理完成';
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
             'S6501' AS REP_NUM,
             T.ITEM_NUM,
             SUM(TOTAL_VALUE) AS ITEM_VAL,
             '2' AS FLAG,
             DATA_DEPARTMENT
        FROM CBRC_A_REPT_DWD_S6501 T
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM, T.ITEM_NUM,DATA_DEPARTMENT;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '插入指标表 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := V_PROCEDURE || '全部处理完成';
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
   
END ;