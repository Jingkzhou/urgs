CREATE OR REPLACE PROCEDURE PROC_CBRC_IDX2_S6303(II_DATADATE  IN STRING --跑批日期
                                                   )
/******************************
   @author:zhoujingkun
   @create-date:20200710
   @description:s6303
   m1  注释客户境内外标志筛选条件,为了测试 ecif数据不准
   m2  业务缺少农村合作社数据,修改条件cust_typ 前一位为 0或1 shiyu 20220518
   M3   a.cust_id  ='8500054441' )--松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
   M4  贴现业务未取到,S6303包含直贴现业务  AND T.ITEM_CD NOT IN ('12902', '12906') --刨除票据转贴现
      cust_id='8000575302' --凯旋支行历史遗留数据 默认为微型企业
   m5 CBRC_S6301_AMT_TMP1 TT1 --取放款时的实际利率
   m6 20220715 shiyu L层模型现账户类型未细分,改为用科目取数
   
目标表:CBRC_A_REPT_ITEM_VAL
临时表：CBRC_A_REPT_DWD_S6303
        CBRC_S6301_AMT_TMP1
集市表：SMTMODS_L_ACCT_LOAN
SMTMODS_L_ACCT_OBS_LOAN
SMTMODS_L_AGRE_GUARANTEE_CONTRACT
SMTMODS_L_AGRE_GUARANTEE_RELATION
SMTMODS_L_AGRE_GUARANTY_INFO
SMTMODS_L_AGRE_GUA_RELATION
SMTMODS_L_CUST_ALL
SMTMODS_L_CUST_C
SMTMODS_L_PUBL_RATE
SMTMODS_V_PUB_IDX_DK_YSDQRJJ

  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE     VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时,用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30); 
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE  := II_DATADATE;
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_S6303');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME     := 'CBRC_A_REPT_ITEM_VAL';
    V_DATADATE     := TO_CHAR(DATE(I_DATADATE), 'YYYY-MM-DD');
    D_DATADATE_CCY := I_DATADATE;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']S6303当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S6303';

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'S6303'
       AND T.FLAG = '2';
    COMMIT;

    -----------------------------------------------------------------------国有控股--------------------------------------------------------------------------
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_DESC := '提取数据国有控股至S6303_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  --1.境内贷款余额合计
 INSERT INTO CBRC_A_REPT_DWD_S6303
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
         AND T.LOAN_STOCKEN_DATE IS NULL;  -- 资产未转让
         COMMIT;

       --   1.2按贷款担保方式
 INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM;
       COMMIT;

   --  1.3按贷款逾期情况
      INSERT INTO CBRC_A_REPT_DWD_S6303
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
             CASE WHEN T.OD_DAYS < 61 THEN 'S63_III_1.3.1.A'
                  WHEN T.OD_DAYS < 91 THEN 'S63_III_1.3.2.A'
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
         AND substr(B.CUST_TYP, 1, 1) in ('0', '1') --m2
         AND B.CORP_HOLD_TYPE LIKE 'A%' --国有控股   A01 国有控股企业-绝对控股    A02  国有控股企业-相对控股
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS < 91 -- 期限拆分成 60天以内 和61-90
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         and B.CORP_SCALE is not null --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.LOAN_STOCKEN_DATE IS NULL ;   -- 资产未转让
    COMMIT;


   INSERT INTO CBRC_A_REPT_DWD_S6303
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
             CASE WHEN T.OD_DAYS > 90 AND T.OD_DAYS < 361 THEN 'S63_III_1.3.3.A'
                  WHEN T.OD_DAYS > 360 THEN  'S63_III_1.3.4.A'
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
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --m2
         AND B.CORP_HOLD_TYPE LIKE 'A%' -- A01 国有控股企业-绝对控股    A02  国有控股企业-相对控股
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS > 90
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         and B.CORP_SCALE is not null --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.LOAN_STOCKEN_DATE IS NULL  -- 资产未转让
       ORDER BY T.ORG_NUM;
    COMMIT;

   --   1.4中长期贷款
INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;


 --2.有贷款余额的户数
INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

  --3.当年累计发放贷款户数
INSERT INTO CBRC_A_REPT_DWD_S6303
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
       COMMIT;

    --3.a其中：以知识产权为质押的户数


--4.当年累计发放贷款额
INSERT INTO CBRC_A_REPT_DWD_S6303
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
       COMMIT;

  -- 4.1当年累计发放信用贷款
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT ;
    --   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

 --  6.当年累计发放贷款年化利息收入
      INSERT INTO CBRC_A_REPT_DWD_S6303
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
       COMMIT;

    --7.当年累计承担或减免的信贷相关费用
    --8.银行承兑汇票
    --9.跟单信用证
    --10.保函
    --11.不可无条件撤销的贷款承诺 暂无业务
    --12.委托贷款（非现金管理项下）

    -----------------------------------------------------------------------集体控股--------------------------------------------------------------------------

    V_STEP_FLAG := 2;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 2;
    V_STEP_DESC := '提取数据集体空库至S6303_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --1.境内贷款余额合计
 INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
       COMMIT;

   --   1.2按贷款担保方式
     INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM;
    COMMIT;

--   1.3按贷款逾期情况
INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
       COMMIT;



  INSERT INTO CBRC_A_REPT_DWD_S6303
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
             CASE WHEN T.OD_DAYS > 90 AND T.OD_DAYS < 361 THEN 'S63_III_1.3.3.B'
                  WHEN T.OD_DAYS > 360 THEN 'S63_III_1.3.4.B'
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
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --m2
         AND B.CORP_HOLD_TYPE like 'B%' --集体控股   B01  集体控股-绝对控股    B02  集体控股-相对控股
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS > 90
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL -- 企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.LOAN_STOCKEN_DATE IS NULL -- 资产未转让
       ORDER BY T.ORG_NUM ;
    COMMIT;

    --   1.4中长期贷款
    INSERT INTO CBRC_A_REPT_DWD_S6303
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
             'S63_III_1.4.1.B' AS ITEM_NUM,
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
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --m2
         AND B.CORP_HOLD_TYPE LIKE 'B%' --集体控股   B01  集体控股-绝对控股    B02  集体控股-相对控股
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
       ORDER BY T.ORG_NUM;
       COMMIT;


  --2.有贷款余额的户数
      INSERT INTO CBRC_A_REPT_DWD_S6303
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
       COMMIT;

    --3.当年累计发放贷款户数
    INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

    --3.a其中：以知识产权为质押的户数

   --4.当年累计发放贷款额
INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

     -- 4.1当年累计发放信用贷款
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
    commit;
    --   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

          --  6.当年累计发放贷款年化利息收入
       INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

    --7.当年累计承担或减免的信贷相关费用
    --8.银行承兑汇票
    --9.跟单信用证
    --10.保函
    --11.不可无条件撤销的贷款承诺 暂无业务
    --12.委托贷款（非现金管理项下）

    -----------------------------------------------------------------------私人控股--------------------------------------------------------------------------

    V_STEP_FLAG := 3;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 3;
    V_STEP_DESC := '提取数据集体空库至S6303_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 --1.境内贷款余额合计
INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT;

   --  1.2按贷款担保方式
INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM;
    COMMIT;

   INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT;


      INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;


--2.有贷款余额的户数
INSERT INTO CBRC_A_REPT_DWD_S6303
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
   COMMIT;

  --3.当年累计发放贷款户数
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

    --3.a其中：以知识产权为质押的户数

  --4.当年累计发放贷款额
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

  -- 4.1当年累计发放信用贷款
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;
    --   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

--  6.当年累计发放贷款年化利息收入
 INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;
    --7.当年累计承担或减免的信贷相关费用
    ------------------------------------------------------------------------------------------------------------
    --表外融资  add by chm 20210616
    --------------------------------------------------------------------------------------------------------------------
  -- 银行承兑汇票
INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT;

   -- 银行承兑汇票 私人控股 小微企业 T 微型企业  S 小型企业
INSERT INTO CBRC_A_REPT_DWD_S6303
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

    COMMIT;

  -- 跟单信用证
INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM;
    COMMIT;

   -- 跟单信用证 小微
INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

 -- 保函
 INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT;

    -- 保函 小微
 INSERT INTO CBRC_A_REPT_DWD_S6303
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
       COMMIT;

 -- 不可无条件撤销的贷款承诺
 INSERT INTO CBRC_A_REPT_DWD_S6303
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
              CASE WHEN A.CORP_HOLD_TYPE LIKE 'A%' THEN 'S63_III_11.A' --国有控股   A01 国有控股企业-绝对控股    A02  国有控股企业-相对控股
                   WHEN A.CORP_HOLD_TYPE LIKE 'B%' THEN 'S63_III_11.B' --集体控股
                   WHEN (A.CORP_HOLD_TYPE LIKE 'C%' OR A.CUST_ID = '8500054441' OR A.CUST_ID = '8000575302') THEN 'S63_III_11.C' --私人控股 --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
                   WHEN A.CORP_HOLD_TYPE LIKE 'D%' THEN 'S63_III_11.D' --港澳台商控股
                   WHEN A.CORP_HOLD_TYPE LIKE 'E%' THEN 'S63_III_11.E' --外商控股
                   WHEN A.CORP_HOLD_TYPE LIKE 'Z%' THEN 'S63_III_11.F' --其他控股
                    END AS ITEM_NUM,
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
         AND A.CORP_SCALE <> 'Z'
         AND T.GL_ITEM_CODE IN ('70300201') --20220715 SHIYU L层模型现账户类型未细分,改为用科目取数
         AND T.BALANCE <> 0
       ORDER BY T.ORG_NUM ;
    COMMIT;

 -- 不可无条件撤销的贷款承诺 小微
 INSERT INTO CBRC_A_REPT_DWD_S6303
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
             'S63_III_11.C1' AS ITEM_NUM,
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
         AND A.CORP_SCALE <> 'Z'
         AND T.ACCT_TYP IN ('521', '522', '523') --不可无条件撤销的贷款承诺
         AND (A.CORP_HOLD_TYPE LIKE 'C%' OR A.CUST_ID = '8500054441' OR
              A.CUST_ID = '8000575302') --松原前郭支行   历史遗留数据 没有集团信息,默认为微型企业
         AND A.CORP_SCALE IN ('T', 'S')
         AND T.BALANCE <> 0
       ORDER BY T.ORG_NUM ;
    COMMIT;
    --12.委托贷款（非现金管理项下）
    -----------------------------------------------------------------------私人控股(其中：小微企业)--------------------------------------------------------------------------

    V_STEP_FLAG := 4;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 4;
    V_STEP_DESC := '提取数据私人控股(其中：小微企业)至S6303_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --1.境内贷款余额合计
       --1.境内贷款余额合计
   INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT;

      --  1.2按贷款担保方式
   INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM;
    COMMIT;


   INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT;

INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT;

--   1.4中长期贷款
 INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT;

    --2.有贷款余额的户数
 INSERT INTO CBRC_A_REPT_DWD_S6303
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
    commit;

    --3.当年累计发放贷款户数
    INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

    --3.a其中：以知识产权为质押的户数

  --4.当年累计发放贷款额
   INSERT INTO CBRC_A_REPT_DWD_S6303
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
    commit;

    -- 4.1当年累计发放信用贷款
   INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;
    --   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

  --  6.当年累计发放贷款年化利息收入
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;
    --7.当年累计承担或减免的信贷相关费用
    --8.银行承兑汇票
    --9.跟单信用证
    --10.保函
    --11.不可无条件撤销的贷款承诺 暂无业务
    --12.委托贷款（非现金管理项下）

    -----------------------------------------------------------------------港澳台商控股-------------------------------------------------------------------------

    V_STEP_FLAG := 5;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 2;
    V_STEP_DESC := '提取数据港澳台商控股至S6303_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  --1.境内贷款余额合计
 INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT;


    --   1.2按贷款担保方式
    INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM;
    COMMIT;


 INSERT INTO CBRC_A_REPT_DWD_S6303
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
             CASE WHEN T.OD_DAYS < 61 THEN 'S63_III_1.3.1.D'
                  WHEN T.OD_DAYS < 91 THEN 'S63_III_1.3.2.D'
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
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --m2
         AND B.CORP_HOLD_TYPE LIKE 'D%' --港澳台商控股企业   D01  港澳台商控股企业-绝对控股    D02  港澳台商控股企业-相对控股
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS < 91
         AND (T.ACCT_TYP NOT LIKE '0101%' AND T.ACCT_TYP NOT LIKE '0103%' AND
             T.ACCT_TYP NOT LIKE '0104%' AND T.ACCT_TYP NOT LIKE '0199%')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         and B.CORP_SCALE is not null --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.LOAN_STOCKEN_DATE IS NULL -- 资产未转让
       ORDER BY T.ORG_NUM ;
    COMMIT;


  INSERT INTO CBRC_A_REPT_DWD_S6303
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
             CASE WHEN T.OD_DAYS > 90 AND T.OD_DAYS < 361 THEN  'S63_III_1.3.3.D'
                  WHEN T.OD_DAYS > 360 THEN 'S63_III_1.3.4.D'
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
             T.OD_FLG,        --  逾期标志
             T.OD_DAYS        --  逾期天数
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
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --m2
         AND B.CORP_HOLD_TYPE LIKE 'D%' --港澳台商控股企业   D01  港澳台商控股企业-绝对控股    D02  港澳台商控股企业-相对控股
         AND T.OD_FLG = 'Y'
         AND (T.ACCT_TYP NOT LIKE '0101%' AND T.ACCT_TYP NOT LIKE '0103%' AND
             T.ACCT_TYP NOT LIKE '0104%' AND T.ACCT_TYP NOT LIKE '0199%')
         AND T.OD_DAYS > 90
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         and B.CORP_SCALE is not null --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       ORDER BY T.ORG_NUM;
    COMMIT;


      --   1.4中长期贷款
    INSERT INTO CBRC_A_REPT_DWD_S6303
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
    commit;

     --2.有贷款余额的户数
   INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.CUST_ID ;
    COMMIT;


    --3.当年累计发放贷款户数
    INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.CUST_ID ;
    COMMIT;

    --3.a其中：以知识产权为质押的户数

   --4.当年累计发放贷款额
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
       COMMIT;


   -- 4.1当年累计发放信用贷款
   INSERT INTO CBRC_A_REPT_DWD_S6303
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
             'S63_III_4.1.D' AS ITEM_NUM,
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
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --m2
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND A.CORP_HOLD_TYPE LIKE 'D%' --港澳台商控股企业   D01  港澳台商控股企业-绝对控股    D02  港澳台商控股企业-相对控股
         AND TT.FORWARD_CCY = 'CNY' --币种
         and T.GUARANTY_TYP LIKE 'D%'
         and A.CORP_SCALE is not null --企业规模不为空
         AND A.CORP_SCALE <> 'Z'
         and (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组 ADD BY CHM 20210604
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       ORDER BY I_DATADATE, P1.ORG_NUM;
    commit;
    --   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

   --  6.当年累计发放贷款年化利息收入
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

    --7.当年累计承担或减免的信贷相关费用
    --8.银行承兑汇票
    --9.跟单信用证
    --10.保函
    --11.不可无条件撤销的贷款承诺 暂无业务
    --12.委托贷款（非现金管理项下）
    -----------------------------------------------------------------------外商控股------------------------------------------------------------------------

    V_STEP_FLAG := 6;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 6;
    V_STEP_DESC := '提取数据外商控股至S6303_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     --1.境内贷款余额合计
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT;

     --   1.2按贷款担保方式
      INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM;
    COMMIT ;

     --   1.3按贷款逾期情况
     INSERT INTO CBRC_A_REPT_DWD_S6303
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
             CASE WHEN T.OD_DAYS < 61 THEN 'S63_III_1.3.1.E'
                  WHEN T.OD_DAYS < 91 THEN 'S63_III_1.3.2.E'
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
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0')
         AND B.CORP_HOLD_TYPE LIKE 'E%' --外商控股企业   E01  外商控股企业-绝对控股    E02  外商控股企业-相对控股
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS < 91 --  期限拆分成 60天以内 和61-90
         AND (T.ACCT_TYP NOT LIKE '0101%' AND T.ACCT_TYP NOT LIKE '0103%' AND
             T.ACCT_TYP NOT LIKE '0104%' AND T.ACCT_TYP NOT LIKE '0199%')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         and B.CORP_SCALE is not null --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_STOCKEN_DATE IS NULL    --  资产未转让
       ORDER BY T.ORG_NUM ;
       COMMIT;


INSERT INTO CBRC_A_REPT_DWD_S6303
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
             CASE WHEN T.OD_DAYS > 90 AND T.OD_DAYS < 361 THEN  'S63_III_1.3.3.E'
                  WHEN T.OD_DAYS > 360 THEN 'S63_III_1.3.4.E'
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
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --m2
         AND B.CORP_HOLD_TYPE LIKE 'E%' --外商控股企业   E01  外商控股企业-绝对控股    E02  外商控股企业-相对控股
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS > 90
         AND (T.ACCT_TYP NOT LIKE '0101%' AND T.ACCT_TYP NOT LIKE '0103%' AND
             T.ACCT_TYP NOT LIKE '0104%' AND T.ACCT_TYP NOT LIKE '0199%')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         and B.CORP_SCALE is not null --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0
       ORDER BY T.ORG_NUM ;
    COMMIT;

   --   1.4中长期贷款
     INSERT INTO CBRC_A_REPT_DWD_S6303
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
             'S63_III_1.4.1.E' AS ITEM_NUM,
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
         AND B.CORP_HOLD_TYPE LIKE 'E%' --外商控股企业   E01  外商控股企业-绝对控股    E02  外商控股企业-相对控股
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12
         AND (T.ACCT_TYP NOT LIKE '0101%' AND T.ACCT_TYP NOT LIKE '0103%' AND
             T.ACCT_TYP NOT LIKE '0104%' AND T.ACCT_TYP NOT LIKE '0199%')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_ACCT_BAL  <> 0
       ORDER BY T.ORG_NUM;
    COMMIT;

    --2.有贷款余额的户数
    INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;


    --3.当年累计发放贷款户数
     INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

    --3.a其中：以知识产权为质押的户数

   --4.当年累计发放贷款额
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
    commit;

 -- 4.1当年累计发放信用贷款
 INSERT INTO CBRC_A_REPT_DWD_S6303
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
    commit;
    --   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

   --  6.当年累计发放贷款年化利息收入
INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;
    --7.当年累计承担或减免的信贷相关费用
    --8.银行承兑汇票
    --9.跟单信用证
    --10.保函
    --11.不可无条件撤销的贷款承诺 暂无业务
    --12.委托贷款（非现金管理项下）

    -----------------------------------------------------------------------个人经营性贷款------------------------------------------------------------------------

    V_STEP_FLAG := 7;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 7;
    V_STEP_DESC := '提取数据个人经营性贷款至S6303_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


  --1.境内贷款余额合计
INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT ;

 --  1.2按贷款担保方式
INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM;
    COMMIT ;

 --   1.3按贷款逾期情况
INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT ;

    INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT;

     --  1.4中长期贷款
   INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT ;

     --2.有贷款余额的户数
    INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT ;

    --3.当年累计发放贷款户数
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT ;

    --3.a其中：以知识产权为质押的户数

   --4.当年累计发放贷款额
INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

     -- 4.1当年累计发放信用贷款
INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;
    --   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额

   --  6.当年累计发放贷款年化利息收入
       INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

    -----------------------------------------------------------------------------------------------------------------
    ---知识产权质押
    ------------------------------------------------------------------------------------------------------------------

    -- 4.a其中：当年累计发放知识产权质押贷款
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6303' AS REP_NUM, -- 报表编号
             'S63_III_4.a' AS ITEM_NUM,
             (T.DRAWDOWN_AMT * TT.CCY_RATE) AS TOTAL_VALUE,
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
             T.JBYG_ID        -- 经办员工ID
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       INNER JOIN (SELECT GR.CONTRACT_NUM
                     FROM SMTMODS_L_AGRE_GUA_RELATION GR --业务合同与担保合同对应关系表
                    INNER JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT GC --担保合同表
                       ON GR.GUAR_CONTRACT_NUM = GC.GUAR_CONTRACT_NUM
                      AND GC.DATA_DATE = I_DATADATE
                      AND GC.GUAR_CONTRACT_STATUS = 'Y'
                    INNER JOIN SMTMODS_L_AGRE_GUARANTEE_RELATION AGR --担保合同与担保信息对应关系表
                       ON GC.GUAR_CONTRACT_NUM = AGR.GUAR_CONTRACT_NUM
                      AND AGR.DATA_DATE = I_DATADATE
                      AND AGR.REL_STATUS = 'Y'
                    INNER JOIN SMTMODS_L_AGRE_GUARANTY_INFO GI
                       ON AGR.GUARANTEE_SERIAL_NUM = GI.GUARANTEE_SERIAL_NUM
                      AND GI.DATA_DATE = I_DATADATE
                      AND GI.COLL_STATUS = 'Y'
                    WHERE GR.DATA_DATE = I_DATADATE
                      AND SUBSTR(GI.COLL_PRO_TYPE, 1, 3) = 'D05' --以知识产权质押
                      AND GC.GUAR_TYP LIKE 'B%' --质押
                    ORDER BY GR.CONTRACT_NUM) C
          ON T.ACCT_NUM = C.CONTRACT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --不取委托贷款
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY T.ORG_NUM;
    COMMIT;

    -- 3.a其中：以知识产权为质押的户数
    INSERT INTO CBRC_A_REPT_DWD_S6303
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
             'S63_III_3.a' AS ITEM_NUM,
             1 AS TOTAL_VALUE,
             T.CUST_ID
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       INNER JOIN (SELECT GR.CONTRACT_NUM
                     FROM SMTMODS_L_AGRE_GUA_RELATION GR --业务合同与担保合同对应关系表
                    INNER JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT GC --担保合同表
                       ON GR.GUAR_CONTRACT_NUM = GC.GUAR_CONTRACT_NUM
                      AND GC.DATA_DATE = I_DATADATE
                      AND GC.GUAR_CONTRACT_STATUS = 'Y'
                    INNER JOIN SMTMODS_L_AGRE_GUARANTEE_RELATION AGR --担保合同与担保信息对应关系表
                       ON GC.GUAR_CONTRACT_NUM = AGR.GUAR_CONTRACT_NUM
                      AND AGR.DATA_DATE = I_DATADATE
                      AND AGR.REL_STATUS = 'Y'
                    INNER JOIN SMTMODS_L_AGRE_GUARANTY_INFO GI
                       ON AGR.GUARANTEE_SERIAL_NUM = GI.GUARANTEE_SERIAL_NUM
                      AND GI.DATA_DATE = I_DATADATE
                      AND GI.COLL_STATUS = 'Y'
                    WHERE GR.DATA_DATE = I_DATADATE
                      AND SUBSTR(GI.COLL_PRO_TYPE, 1, 3) = 'D05' --以知识产权质押
                      AND GC.GUAR_TYP LIKE 'B%' --质押
                    GROUP BY GR.CONTRACT_NUM) C
          ON T.ACCT_NUM = C.CONTRACT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --不取委托贷款
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --到期日
         AND TT.FORWARD_CCY = 'CNY' --币种
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
       ORDER BY T.CUST_ID;
    COMMIT;

    --ALTER BY WJB 20221026 新增企业控股类型为其他的取数逻辑

    --1.境内贷款余额合计
INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM ;
    COMMIT;

       --   1.2按贷款担保方式
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
       ORDER BY T.ORG_NUM;
    COMMIT;



--   1.3按贷款逾期情况
INSERT INTO CBRC_A_REPT_DWD_S6303
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
       CASE WHEN T.OD_DAYS < 61 THEN  'S63_III_1.3.1.F'
            WHEN T.OD_DAYS < 91 THEN  'S63_III_1.3.2.F'
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
         AND B.CORP_HOLD_TYPE = 'Z'
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS < 91 --  期限拆分成 60天以内 和61-90
         AND (T.ACCT_TYP NOT LIKE '0101%' AND T.ACCT_TYP NOT LIKE '0103%' AND
             T.ACCT_TYP NOT LIKE '0104%' AND T.ACCT_TYP NOT LIKE '0199%')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_STOCKEN_DATE IS NULL --  资产未转让
       ORDER BY T.ORG_NUM ;

    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6303
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
             CASE WHEN T.OD_DAYS > 90 AND T.OD_DAYS < 361 THEN 'S63_III_1.3.3.F'
                  WHEN T.OD_DAYS > 360 THEN  'S63_III_1.3.4.F'
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
         AND B.CORP_HOLD_TYPE = 'Z'
         AND T.OD_FLG = 'Y'
         AND T.OD_DAYS > 90
         AND (T.ACCT_TYP NOT LIKE '0101%' AND T.ACCT_TYP NOT LIKE '0103%' AND
             T.ACCT_TYP NOT LIKE '0104%' AND T.ACCT_TYP NOT LIKE '0199%')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T.LOAN_STOCKEN_DATE IS NULL    --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       ORDER BY T.ORG_NUM ;
    COMMIT;


 --   1.4中长期贷款
    INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

    --2.有贷款余额的户数
     INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

    --3.当年累计发放贷款户数
    INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

    --3.a其中：以知识产权为质押的户数

    --4.当年累计发放贷款额
INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

-- 4.1当年累计发放信用贷款
  INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;
    --   4.a其中：当年累计发放知识产权质押贷款

    --   5.已处置的不良贷款金额


  --  6.当年累计发放贷款年化利息收入
       INSERT INTO CBRC_A_REPT_DWD_S6303
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
    COMMIT;

 
    --=======================================================================================================-
    -------------------------------------S6303数据插至目标指标表--------------------------------------------
    --=====================================================================================================---
    V_STEP_FLAG := 8;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 8;
    V_STEP_DESC := '产生S6303指标数据,插至目标表';
    V_STEP_FLAG := 0;
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
             'S6303' AS REP_NUM,
             T.ITEM_NUM,
             SUM(TOTAL_VALUE) AS ITEM_VAL,
             '2' AS FLAG,
             DATA_DEPARTMENT
        FROM CBRC_A_REPT_DWD_S6303 T
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM, T.ITEM_NUM,DATA_DEPARTMENT;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := V_PROCEDURE || '的业务逻辑全部处理完成';
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