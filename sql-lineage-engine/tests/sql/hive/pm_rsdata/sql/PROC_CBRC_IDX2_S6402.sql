CREATE OR REPLACE PROCEDURE PROC_CBRC_IDX2_S6402(II_DATADATE IN STRING --跑批日期
                                               )
/******************************
  @AUTHOR:JIHAIJING
  @CREATE-DATE:20150929
  @DESCRIPTION:S6402
  @MODIFICATION HISTORY:LIXIN04 2015-12-25
  M0.AUTHOR-CREATE_DATE-DESCRIPTION
  M1.20160427.SHENYUNFEI.2016制度升级，取消所有E列指标
  M2.20250327  2025年制度升级  普惠型小微企业不良贷款
  *******************************/
 IS
  V_SCHEMA        VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(4000); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  V_PER_NUM   VARCHAR(30); --报表编号
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_SYSTEM     VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    V_PER_NUM   := 'S6402';
    V_TAB_NAME  := 'CBRC_A_REPT_ITEM_VAL';
    I_DATADATE  := II_DATADATE;
    D_DATADATE_CCY := I_DATADATE;
    V_SYSTEM        := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_S6402_DWD');

    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']S6402当期数据';
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

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S6402';
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   S6402 'S64_II_1.1.A-S64_II_1.21.A'插入临时表
    --====================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据至CBRC_A_REPT_DWD_S6402中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_18)
      SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             CASE WHEN B.CORP_BUSINSESS_TYPE LIKE 'A%' THEN 'S64_II_1.1.A' --  1.1农、林、牧、渔业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'B%' THEN 'S64_II_1.2.A' --  1.2采矿业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'C%' THEN 'S64_II_1.3.A' --  1.3制造业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'D%' THEN 'S64_II_1.4.A' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'E%' THEN 'S64_II_1.5.A' --  1.5建筑业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'F%' THEN 'S64_II_1.6.A' --  1.6批发和零售业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'G%' THEN 'S64_II_1.7.A' --  1.7交通运输、仓储和邮政业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'H%' THEN 'S64_II_1.8.A' --  1.8住宿和餐饮业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'I%' THEN 'S64_II_1.9.A' --  1.9信息传输、软件和信息技术服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'J%' THEN 'S64_II_1.10.A' --  1.10金融业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'K%' THEN 'S64_II_1.11.A' --  1.11房地产业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'L%' THEN 'S64_II_1.12.A' --  1.12租赁和商务服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'M%' THEN 'S64_II_1.13.A' --  1.13科学研究和技术服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'N%' THEN 'S64_II_1.14.A' --  1.14水利、环境和公共设施管理业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'O%' THEN 'S64_II_1.15.A' --  1.15居民服务、修理和其他服务业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'P%' THEN 'S64_II_1.16.A' --  1.16教育
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'Q%' THEN 'S64_II_1.17.A' --  1.17卫生和社会工作
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'R%' THEN 'S64_II_1.18.A' --  1.18文化、体育和娱乐业
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'S%' THEN 'S64_II_1.19.A' --  1.19公共管理、社会保障和社会组织
                  WHEN B.CORP_BUSINSESS_TYPE LIKE 'T%' THEN 'S64_II_1.20.A' --  1.20国际组织
                END AS ITEM_NUM, --指标号
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) + NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB, --指标值
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
             B.CUST_TYP,       -- 客户分类
             T.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') --ALTER BY WJB 20220518 增加农村合作社取数逻辑
         AND T.ACCT_TYP NOT LIKE '0301%' --SHIWENBO BY 20170318-12901 单独取直贴
         AND B.CORP_SCALE = 'B'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.LOAN_GRADE_CD IN ('3', '4', '5')
         AND T.ACCT_TYP NOT IN ('B01', 'C01', 'D01')
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0

      UNION ALL

      SELECT 
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             CASE WHEN A.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_II_1.1.A' --  1.1农、林、牧、渔业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_II_1.2.A' --  1.2采矿业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_II_1.3.A' --  1.3制造业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_II_1.4.A' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_II_1.5.A' --  1.5建筑业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_II_1.6.A' --  1.6批发和零售业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_II_1.7.A' --  1.7交通运输、仓储和邮政业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_II_1.8.A' --  1.8住宿和餐饮业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_II_1.9.A' --  1.9信息传输、软件和信息技术服务业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_II_1.10.A' --  1.10金融业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_II_1.11.A' --  1.11房地产业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_II_1.12.A' --  1.12租赁和商务服务业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_II_1.13.A' --  1.13科学研究和技术服务业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_II_1.14.A' --  1.14水利、环境和公共设施管理业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_II_1.15.A' --  1.15居民服务、修理和其他服务业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_II_1.16.A' --  1.16教育
                  WHEN A.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_II_1.17.A' --  1.17卫生和社会工作
                  WHEN A.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_II_1.18.A' --  1.18文化、体育和娱乐业
                  WHEN A.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_II_1.19.A' --  1.19公共管理、社会保障和社会组织
                  WHEN A.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_II_1.20.A' --  1.20国际组织
                END AS ITEM_NUM, --指标号
             NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB,  --字段：贷款余额_人民币
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
             C.CUST_TYP,       -- 客户分类
             A.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON A.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND C.CORP_SCALE = 'B'
         AND SUBSTR(A.ITEM_CD,1,6) IN ('130101', '130104')
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL
         AND A.LOAN_ACCT_BAL <> 0 ;
    COMMIT;

    -- 修改转贴现取数逻辑
 INSERT INTO CBRC_A_REPT_DWD_S6402
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
             A.ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             'S64_II_1.21.A' AS ITEM_NUM,
             NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB,
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
             C.CUST_TYP,       -- 客户分类
             A.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON A.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND C.CORP_SCALE = 'B'
         AND A.CANCEL_FLG = 'N'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND SUBSTR(A.ITEM_CD,1,6) IN ('130101', '130104')
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL
         AND A.LOAN_ACCT_BAL <> 0;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   S6402 'S64_II_1.1.B-S64_II_1.21.B'插入临时表
    --====================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据至CBRC_A_REPT_DWD_S6402中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
      INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_18)
      SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             CASE
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'A%' THEN 'S64_II_1.1.B' --  1.1农、林、牧、渔业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'B%' THEN 'S64_II_1.2.B' --  1.2采矿业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'C%' THEN 'S64_II_1.3.B' --  1.3制造业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'D%' THEN 'S64_II_1.4.B' --  1.4电力、热力、燃气及水的生产和供应业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'E%' THEN 'S64_II_1.5.B' --  1.5建筑业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'F%' THEN 'S64_II_1.6.B' --  1.6批发和零售业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'G%' THEN 'S64_II_1.7.B' --  1.7交通运输、仓储和邮政业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'H%' THEN 'S64_II_1.8.B' --  1.8住宿和餐饮业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'I%' THEN 'S64_II_1.9.B' --  1.9信息传输、软件和信息技术服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'J%' THEN 'S64_II_1.10.B' --  1.10金融业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'K%' THEN 'S64_II_1.11.B' --  1.11房地产业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'L%' THEN 'S64_II_1.12.B' --  1.12租赁和商务服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'M%' THEN 'S64_II_1.13.B' --  1.13科学研究和技术服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'N%' THEN 'S64_II_1.14.B' --  1.14水利、环境和公共设施管理业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'O%' THEN 'S64_II_1.15.B' --  1.15居民服务、修理和其他服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'P%' THEN 'S64_II_1.16.B' --  1.16教育
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'Q%' THEN 'S64_II_1.17.B' --  1.17卫生和社会工作
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'R%' THEN 'S64_II_1.18.B' --  1.18文化、体育和娱乐业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'S%' THEN 'S64_II_1.19.B' --  1.19公共管理、社会保障和社会组织
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'T%' THEN 'S64_II_1.20.B' --  1.20国际组织
             END AS ITEM_NUM, --指标号
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) + NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB, --指标值
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
             T.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') --ALTER BY WJB 20220518 增加农村合作社取数逻辑
         AND T.ACCT_TYP NOT LIKE '0301%' --SHIWENBO BY 20170318-12901 单独取直贴
         AND B.CORP_SCALE = 'M'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.LOAN_GRADE_CD IN ('3', '4', '5')
         AND T.ACCT_TYP NOT IN ('B01', 'C01', 'D01')
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0
      UNION ALL

       SELECT 
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             CASE
               WHEN A.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_II_1.1.B' --  1.1农、林、牧、渔业
               WHEN A.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_II_1.2.B' --  1.2采矿业
               WHEN A.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_II_1.3.B' --  1.3制造业
               WHEN A.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_II_1.4.B' --  1.4电力、热力、燃气及水的生产和供应业
               WHEN A.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_II_1.5.B' --  1.5建筑业
               WHEN A.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_II_1.6.B' --  1.6批发和零售业
               WHEN A.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_II_1.7.B' --  1.7交通运输、仓储和邮政业
               WHEN A.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_II_1.8.B' --  1.8住宿和餐饮业
               WHEN A.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_II_1.9.B' --  1.9信息传输、软件和信息技术服务业
               WHEN A.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_II_1.10.B' --  1.10金融业
               WHEN A.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_II_1.11.B' --  1.11房地产业
               WHEN A.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_II_1.12.B' --  1.12租赁和商务服务业
               WHEN A.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_II_1.13.B' --  1.13科学研究和技术服务业
               WHEN A.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_II_1.14.B' --  1.14水利、环境和公共设施管理业
               WHEN A.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_II_1.15.B' --  1.15居民服务、修理和其他服务业
               WHEN A.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_II_1.16.B' --  1.16教育
               WHEN A.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_II_1.17.B' --  1.17卫生和社会工作
               WHEN A.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_II_1.18.B' --  1.18文化、体育和娱乐业
               WHEN A.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_II_1.19.B' --  1.19公共管理、社会保障和社会组织
               WHEN A.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_II_1.20.B' --  1.20国际组织
             END AS ITEM_NUM, --指标号
             NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB,
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
             C.CUST_TYP,      -- 客户分类
             A.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON A.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND C.CORP_SCALE = 'M'
         AND SUBSTR(A.ITEM_CD,1,6) IN ('130101', '130104')
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL    --  资产未转让
         AND A.LOAN_ACCT_BAL <> 0  ;
         COMMIT;

    --SHIWENBO BY 20170318-12902 修改转贴现取数逻辑
     INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_18)
       SELECT 
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             'S64_II_1.21.B' AS ITEM_NUM,
             NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB,
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
             C.CUST_TYP,       -- 客户分类
             A.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON A.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND C.CORP_SCALE = 'M'
         AND SUBSTR(A.ITEM_CD,1,6) IN ('130101', '130104')
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.LOAN_ACCT_BAL <> 0;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   S6402 'S64_II_1.1.C-S64_II_1.21.C'插入临时表
    --====================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据至CBRC_A_REPT_DWD_S6402中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_18)
      SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             CASE
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'A%' THEN 'S64_II_1.1.C' --  1.1农、林、牧、渔业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'B%' THEN 'S64_II_1.2.C' --  1.2采矿业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'C%' THEN 'S64_II_1.3.C' --  1.3制造业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'D%' THEN 'S64_II_1.4.C' --  1.4电力、热力、燃气及水的生产和供应业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'E%' THEN 'S64_II_1.5.C' --  1.5建筑业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'F%' THEN 'S64_II_1.6.C' --  1.6批发和零售业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'G%' THEN 'S64_II_1.7.C' --  1.7交通运输、仓储和邮政业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'H%' THEN 'S64_II_1.8.C' --  1.8住宿和餐饮业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'I%' THEN 'S64_II_1.9.C' --  1.9信息传输、软件和信息技术服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'J%' THEN 'S64_II_1.10.C' --  1.10金融业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'K%' THEN 'S64_II_1.11.C' --  1.11房地产业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'L%' THEN 'S64_II_1.12.C' --  1.12租赁和商务服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'M%' THEN 'S64_II_1.13.C' --  1.13科学研究和技术服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'N%' THEN 'S64_II_1.14.C' --  1.14水利、环境和公共设施管理业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'O%' THEN 'S64_II_1.15.C' --  1.15居民服务、修理和其他服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'P%' THEN 'S64_II_1.16.C' --  1.16教育
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'Q%' THEN 'S64_II_1.17.C' --  1.17卫生和社会工作
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'R%' THEN 'S64_II_1.18.C' --  1.18文化、体育和娱乐业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'S%' THEN 'S64_II_1.19.C' --  1.19公共管理、社会保障和社会组织
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'T%' THEN 'S64_II_1.20.C' --  1.20国际组织
             END AS ITEM_NUM, --指标号
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) + NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB ,--指标值
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
             B.CUST_TYP,       -- 客户分类
             T.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') -- 增加农村合作社取数逻辑
         AND T.ACCT_TYP NOT LIKE '0301%'
         AND B.CORP_SCALE = 'S'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.LOAN_GRADE_CD IN ('3', '4', '5')
         AND T.ACCT_TYP NOT IN ('B01', 'C01', 'D01')
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0

     UNION ALL

      SELECT 
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             CASE
               WHEN A.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_II_1.1.C' --  1.1农、林、牧、渔业
               WHEN A.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_II_1.2.C' --  1.2采矿业
               WHEN A.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_II_1.3.C' --  1.3制造业
               WHEN A.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_II_1.4.C' --  1.4电力、热力、燃气及水的生产和供应业
               WHEN A.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_II_1.5.C' --  1.5建筑业
               WHEN A.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_II_1.6.C' --  1.6批发和零售业
               WHEN A.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_II_1.7.C' --  1.7交通运输、仓储和邮政业
               WHEN A.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_II_1.8.C' --  1.8住宿和餐饮业
               WHEN A.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_II_1.9.C' --  1.9信息传输、软件和信息技术服务业
               WHEN A.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_II_1.10.C' --  1.10金融业
               WHEN A.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_II_1.11.C' --  1.11房地产业
               WHEN A.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_II_1.12.C' --  1.12租赁和商务服务业
               WHEN A.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_II_1.13.C' --  1.13科学研究和技术服务业
               WHEN A.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_II_1.14.C' --  1.14水利、环境和公共设施管理业
               WHEN A.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_II_1.15.C' --  1.15居民服务、修理和其他服务业
               WHEN A.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_II_1.16.C' --  1.16教育
               WHEN A.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_II_1.17.C' --  1.17卫生和社会工作
               WHEN A.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_II_1.18.C' --  1.18文化、体育和娱乐业
               WHEN A.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_II_1.19.C' --  1.19公共管理、社会保障和社会组织
               WHEN A.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_II_1.20.C' --  1.20国际组织
             END AS ITEM_NUM, --指标号  --字段：贷款余额_人民币
             NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB,
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
             C.CUST_TYP,       -- 客户分类
             A.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON A.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND C.CORP_SCALE = 'S'
         AND SUBSTR(A.ITEM_CD,1,6) IN ('130101', '130104')
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.LOAN_ACCT_BAL <> 0;
      COMMIT;

    --SHIWENBO BY 20170318-12902 修改转贴现取数逻辑
  INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_18)
      SELECT 
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
            'S64_II_1.21.C' AS ITEM_NUM,
             NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB,
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
             C.CUST_TYP,       -- 客户分类
             A.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON A.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.CANCEL_FLG = 'N'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_STS <> '3'
         AND C.CORP_SCALE = 'S'
         AND SUBSTR(A.ITEM_CD,1,6) IN ('130101', '130104')
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL
         AND A.LOAN_ACCT_BAL <> 0 ;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   S6402 'S64_II_1.1.D-S64_II_1.21.D'插入临时表
    --====================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据至CBRC_A_REPT_DWD_S6402中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_18)
      SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             CASE
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'A%' THEN 'S64_II_1.1.D' --  1.1农、林、牧、渔业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'B%' THEN 'S64_II_1.2.D' --  1.2采矿业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'C%' THEN 'S64_II_1.3.D' --  1.3制造业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'D%' THEN 'S64_II_1.4.D' --  1.4电力、热力、燃气及水的生产和供应业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'E%' THEN 'S64_II_1.5.D' --  1.5建筑业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'F%' THEN 'S64_II_1.6.D' --  1.6批发和零售业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'G%' THEN 'S64_II_1.7.D' --  1.7交通运输、仓储和邮政业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'H%' THEN 'S64_II_1.8.D' --  1.8住宿和餐饮业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'I%' THEN 'S64_II_1.9.D' --  1.9信息传输、软件和信息技术服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'J%' THEN 'S64_II_1.10.D' --  1.10金融业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'K%' THEN 'S64_II_1.11.D' --  1.11房地产业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'L%' THEN 'S64_II_1.12.D' --  1.12租赁和商务服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'M%' THEN 'S64_II_1.13.D' --  1.13科学研究和技术服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'N%' THEN 'S64_II_1.14.D' --  1.14水利、环境和公共设施管理业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'O%' THEN 'S64_II_1.15.D' --  1.15居民服务、修理和其他服务业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'P%' THEN 'S64_II_1.16.D' --  1.16教育
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'Q%' THEN 'S64_II_1.17.D' --  1.17卫生和社会工作
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'R%' THEN 'S64_II_1.18.D' --  1.18文化、体育和娱乐业
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'S%' THEN 'S64_II_1.19.D' --  1.19公共管理、社会保障和社会组织
               WHEN B.CORP_BUSINSESS_TYPE LIKE 'T%' THEN 'S64_II_1.20.D' --  1.20国际组织
             END AS ITEM_NUM, --指标号
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) + NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB ,--指标值
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
             B.CUST_TYP,       -- 客户分类
             T.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP,1,1) IN ('1','0') --ALTER BY WJB 20220518 增加农村合作社取数逻辑
         AND T.ACCT_TYP NOT LIKE '0301%' --SHIWENBO BY 20170318-12901 单独取直贴
         AND B.CORP_SCALE = 'T'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.LOAN_GRADE_CD IN ('3', '4', '5')
         AND T.ACCT_TYP NOT IN ('B01', 'C01', 'D01')
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0
      UNION ALL

      SELECT 
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             CASE
               WHEN A.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_II_1.1.D' --  1.1农、林、牧、渔业
               WHEN A.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_II_1.2.D' --  1.2采矿业
               WHEN A.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_II_1.3.D' --  1.3制造业
               WHEN A.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_II_1.4.D' --  1.4电力、热力、燃气及水的生产和供应业
               WHEN A.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_II_1.5.D' --  1.5建筑业
               WHEN A.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_II_1.6.D' --  1.6批发和零售业
               WHEN A.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_II_1.7.D' --  1.7交通运输、仓储和邮政业
               WHEN A.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_II_1.8.D' --  1.8住宿和餐饮业
               WHEN A.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_II_1.9.D' --  1.9信息传输、软件和信息技术服务业
               WHEN A.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_II_1.10.D' --  1.10金融业
               WHEN A.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_II_1.11.D' --  1.11房地产业
               WHEN A.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_II_1.12.D' --  1.12租赁和商务服务业
               WHEN A.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_II_1.13.D' --  1.13科学研究和技术服务业
               WHEN A.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_II_1.14.D' --  1.14水利、环境和公共设施管理业
               WHEN A.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_II_1.15.D' --  1.15居民服务、修理和其他服务业
               WHEN A.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_II_1.16.D' --  1.16教育
               WHEN A.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_II_1.17.D' --  1.17卫生和社会工作
               WHEN A.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_II_1.18.D' --  1.18文化、体育和娱乐业
               WHEN A.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_II_1.19.D' --  1.19公共管理、社会保障和社会组织
               WHEN A.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_II_1.20.D' --  1.20国际组织
             END AS ITEM_NUM, --指标号
             NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB,
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
             C.CUST_TYP,      -- 客户分类
             A.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON A.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND C.CORP_SCALE = 'T'
         AND SUBSTR(A.ITEM_CD,1,6) IN ('130101', '130104')
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL
         AND A.LOAN_ACCT_BAL <> 0;
    COMMIT;

    --SHIWENBO BY 20170318-12902 修改转贴现取数逻辑
  INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_18)
      SELECT 
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             'S64_II_1.21.D' AS ITEM_NUM,
             NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB,
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
             C.CUST_TYP,       -- 客户分类
             A.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON A.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.CANCEL_FLG = 'N'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_STS <> '3'
         AND C.CORP_SCALE = 'T'
         AND SUBSTR(A.ITEM_CD,1,6) IN ('130101', '130104')
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL
         AND A.LOAN_ACCT_BAL <> 0 ;
    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   S6402 'S64_II_1.1.F-S64_II_1.21.F'插入临时表
    --====================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据至CBRC_A_REPT_DWD_S6402中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_18)
 SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             CASE
               WHEN T.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_II_1.1.F' --  1.1农、林、牧、渔业
               WHEN T.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_II_1.2.F' --  1.2采矿业
               WHEN T.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_II_1.3.F' --  1.3制造业
               WHEN T.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_II_1.4.F' --  1.4电力、热力、燃气及水的生产和供应业
               WHEN T.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_II_1.5.F' --  1.5建筑业
               WHEN T.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_II_1.6.F' --  1.6批发和零售业
               WHEN T.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_II_1.7.F' --  1.7交通运输、仓储和邮政业
               WHEN T.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_II_1.8.F' --  1.8住宿和餐饮业
               WHEN T.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_II_1.9.F' --  1.9信息传输、软件和信息技术服务业
               WHEN T.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_II_1.10.F' --  1.10金融业
               WHEN T.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_II_1.11.F' --  1.11房地产业
               WHEN T.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_II_1.12.F' --  1.12租赁和商务服务业
               WHEN T.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_II_1.13.F' --  1.13科学研究和技术服务业
               WHEN T.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_II_1.14.F' --  1.14水利、环境和公共设施管理业
               WHEN T.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_II_1.15.F' --  1.15居民服务、修理和其他服务业
               WHEN T.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_II_1.16.F' --  1.16教育
               WHEN T.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_II_1.17.F' --  1.17卫生和社会工作
               WHEN T.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_II_1.18.F' --  1.18文化、体育和娱乐业
               WHEN T.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_II_1.19.F' --  1.19公共管理、社会保障和社会组织
               WHEN T.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_II_1.20.F' --  1.20国际组织
             END AS ITEM_NUM, --指标号
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) + NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB, --指标值
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
             T.LOAN_GRADE_CD  -- 贷款投向
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP LIKE '0102%'
         AND T.LOAN_GRADE_CD IN ('3', '4', '5')
         AND SUBSTR(T.LOAN_PURPOSE_CD, 1, 1) IN ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T')
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0 ;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   S6402 'S64_II_1.1.G-S64_II_1.21.G'插入临时表
    --====================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据至CBRC_A_REPT_DWD_S6402中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_18)
 SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             CASE
               WHEN T.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_II_1.1.G' --  1.1农、林、牧、渔业
               WHEN T.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_II_1.2.G' --  1.2采矿业
               WHEN T.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_II_1.3.G' --  1.3制造业
               WHEN T.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_II_1.4.G' --  1.4电力、热力、燃气及水的生产和供应业
               WHEN T.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_II_1.5.G' --  1.5建筑业
               WHEN T.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_II_1.6.G' --  1.6批发和零售业
               WHEN T.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_II_1.7.G' --  1.7交通运输、仓储和邮政业
               WHEN T.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_II_1.8.G' --  1.8住宿和餐饮业
               WHEN T.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_II_1.9.G' --  1.9信息传输、软件和信息技术服务业
               WHEN T.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_II_1.10.G' --  1.10金融业
               WHEN T.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_II_1.11.G' --  1.11房地产业
               WHEN T.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_II_1.12.G' --  1.12租赁和商务服务业
               WHEN T.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_II_1.13.G' --  1.13科学研究和技术服务业
               WHEN T.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_II_1.14.G' --  1.14水利、环境和公共设施管理业
               WHEN T.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_II_1.15.G' --  1.15居民服务、修理和其他服务业
               WHEN T.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_II_1.16.G' --  1.16教育
               WHEN T.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_II_1.17.G' --  1.17卫生和社会工作
               WHEN T.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_II_1.18.G' --  1.18文化、体育和娱乐业
               WHEN T.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_II_1.19.G' --  1.19公共管理、社会保障和社会组织
               WHEN T.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_II_1.20.G' --  1.20国际组织
             END AS ITEM_NUM, --指标号
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) + NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB , --字段：贷款余额_人民币+利息调整_人民币
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
             T.LOAN_GRADE_CD -- 贷款投向
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP LIKE '0102%'
         AND (C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3')
         AND T.LOAN_GRADE_CD IN ('3', '4', '5')
         AND SUBSTR(T.LOAN_PURPOSE_CD, 1, 1) IN ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T')
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.LOAN_ACCT_BAL<> 0;
         COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   S6402 'S64_II_1.1.H-S64_II_1.21.H'插入临时表
    --====================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据至CBRC_A_REPT_DWD_S6402中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_18)
 SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             CASE
               WHEN T.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_II_1.1.H' --  1.1农、林、牧、渔业
               WHEN T.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_II_1.2.H' --  1.2采矿业
               WHEN T.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_II_1.3.H' --  1.3制造业
               WHEN T.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_II_1.4.H' --  1.4电力、热力、燃气及水的生产和供应业
               WHEN T.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_II_1.5.H' --  1.5建筑业
               WHEN T.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_II_1.6.H' --  1.6批发和零售业
               WHEN T.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_II_1.7.H' --  1.7交通运输、仓储和邮政业
               WHEN T.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_II_1.8.H' --  1.8住宿和餐饮业
               WHEN T.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_II_1.9.H' --  1.9信息传输、软件和信息技术服务业
               WHEN T.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_II_1.10.H' --  1.10金融业
               WHEN T.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_II_1.11.H' --  1.11房地产业
               WHEN T.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_II_1.12.H' --  1.12租赁和商务服务业
               WHEN T.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_II_1.13.H' --  1.13科学研究和技术服务业
               WHEN T.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_II_1.14.H' --  1.14水利、环境和公共设施管理业
               WHEN T.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_II_1.15.H' --  1.15居民服务、修理和其他服务业
               WHEN T.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_II_1.16.H' --  1.16教育
               WHEN T.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_II_1.17.H' --  1.17卫生和社会工作
               WHEN T.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_II_1.18.H' --  1.18文化、体育和娱乐业
               WHEN T.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_II_1.19.H' --  1.19公共管理、社会保障和社会组织
               WHEN T.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_II_1.20.H' --  1.20国际组织
             END AS ITEM_NUM, --指标号
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) +
             NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0) AS LOAN_ACCT_BAL_RMB , --字段：贷款余额_人民币+利息调整_人民币
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
             T.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE=U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP LIKE '0102%'
         AND C.OPERATE_CUST_TYPE = 'B'
         AND T.LOAN_GRADE_CD IN ('3', '4', '5')
         AND SUBSTR(T.LOAN_PURPOSE_CD, 1, 1)IN ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T')
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         AND T.LOAN_ACCT_BAL <> 0 ;


    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   S6402  买断式转贴现
    --====================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据买断式转贴现至CBRC_A_REPT_DWD_S6402中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


 INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_18)
      SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             'S64_II_1.21.F' AS ITEM_NUM,
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
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             NULL,            -- 行业类别
             NULL,            -- 企业规模
             NULL,            -- 客户分类
             T.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON T.DATA_DATE=TT.DATA_DATE
         AND TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND T.DATA_DATE = P.DATA_DATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         AND SUBSTR(T.ITEM_CD,1,6) IN ('130102', '130105')
         AND T.LOAN_GRADE_CD IN ('3', '4', '5')
         AND T.LOAN_STOCKEN_DATE IS NULL;

    COMMIT;

        INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_18)
      SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             CASE WHEN P.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3' THEN  'S64_II_1.21.G' --个体工商户
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN 'S64_II_1.21.H' --小微企业
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
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             C.CORP_HOLD_TYPE,-- 行业类别
             C.CORP_SCALE,    -- 企业规模
             C.CUST_TYP,       -- 客户分类
             T.LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON T.DATA_DATE=TT.DATA_DATE
         AND TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND T.DATA_DATE = P.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = T.DATA_DATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_TYP LIKE '0102%'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND TT.FORWARD_CCY = 'CNY'
         AND SUBSTR(T.ITEM_CD,1,6) IN ('130102', '130105')
         AND T.LOAN_GRADE_CD IN ('3', '4', '5')
         AND T.LOAN_STOCKEN_DATE IS NULL ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     --alter by  20250327  2025年制度升级

     --普惠型小微企业不良贷款   --


   ----普惠型小微企业贷款指单户授信总额1000万元及以下的小微企业贷款（个体工商户及小微企业主经营性贷款）
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取个体工商户及小微企业主经营性贷款至CBRC_A_REPT_DWD_S6402中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_19)
      SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
              CASE WHEN T.LOAN_PURPOSE_CD LIKE 'A%' THEN 'S64_II_1.1.E.2025' --  1.1农、林、牧、渔业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'B%' THEN 'S64_II_1.2.E.2025' --  1.2采矿业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'C%' THEN 'S64_II_1.3.E.2025' --  1.3制造业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'D%' THEN 'S64_II_1.4.E.2025' --  1.4电力、热力、燃气及水的生产和供应业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'E%' THEN 'S64_II_1.5.E.2025' --  1.5建筑业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'F%' THEN 'S64_II_1.6.E.2025' --  1.6批发和零售业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'G%' THEN 'S64_II_1.7.E.2025' --  1.7交通运输、仓储和邮政业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'H%' THEN 'S64_II_1.8.E.2025' --  1.8住宿和餐饮业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'I%' THEN 'S64_II_1.9.E.2025' --  1.9信息传输、软件和信息技术服务业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'J%' THEN 'S64_II_1.10.E.2025' --  1.10金融业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'K%' THEN 'S64_II_1.11.E.2025' --  1.11房地产业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'L%' THEN 'S64_II_1.12.E.2025' --  1.12租赁和商务服务业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'M%' THEN 'S64_II_1.13.E.2025' --  1.13科学研究和技术服务业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'N%' THEN 'S64_II_1.14.E.2025' --  1.14水利、环境和公共设施管理业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'O%' THEN 'S64_II_1.15.E.2025' --  1.15居民服务、修理和其他服务业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'P%' THEN 'S64_II_1.16.E.2025' --  1.16教育
                   WHEN T.LOAN_PURPOSE_CD LIKE 'Q%' THEN 'S64_II_1.17.E.2025' --  1.17卫生和社会工作
                   WHEN T.LOAN_PURPOSE_CD LIKE 'R%' THEN 'S64_II_1.18.E.2025' --  1.18文化、体育和娱乐业
                   WHEN T.LOAN_PURPOSE_CD LIKE 'S%' THEN 'S64_II_1.19.E.2025' --  1.19公共管理、社会保障和社会组织
                   WHEN T.LOAN_PURPOSE_CD LIKE 'T%' THEN 'S64_II_1.20.E.2025' --  1.20国际组织
                 END AS ITEM_NUM ,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL,
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
             T.LOAN_GRADE_CD,
             B.FACILITY_AMT
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON T.DATA_DATE = TT.DATA_DATE
         AND TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX B --ALTER BY 20241224 JLBA202412040012
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.LOAN_ACCT_BAL <> 0 --贷款余额
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND SUBSTR(t.ITEM_CD, 1, 6) not IN ('130102', '130105') --转贴现 --不含票据转贴现
         AND B.FACILITY_AMT <= 10000000 --单户授信总额1000万元及以下
         AND ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
             AND (P.OPERATE_CUST_TYPE IN ('A', 'B') OR C.CUST_TYP ='3'))
         AND T.LOAN_GRADE_CD IN ('3','4','5') --不良贷款
         AND SUBSTR(T.LOAN_PURPOSE_CD,1,1) IN ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T')
         AND T.LOAN_STOCKEN_DATE IS NULL ;
       COMMIT;

       --普惠型小微企业贷款指单户授信总额1000万元及以下的小微企业贷款（小微企业法人）
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取小微企业法人贷款至CBRC_A_REPT_DWD_S6402中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_19)
      SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             CASE WHEN C.CORP_BUSINSESS_TYPE LIKE 'A%' THEN 'S64_II_1.1.E.2025' --  1.1农、林、牧、渔业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'B%' THEN 'S64_II_1.2.E.2025' --  1.2采矿业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'C%' THEN 'S64_II_1.3.E.2025' --  1.3制造业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'D%' THEN 'S64_II_1.4.E.2025' --  1.4电力、热力、燃气及水的生产和供应业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'E%' THEN 'S64_II_1.5.E.2025' --  1.5建筑业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'F%' THEN 'S64_II_1.6.E.2025' --  1.6批发和零售业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'G%' THEN 'S64_II_1.7.E.2025' --  1.7交通运输、仓储和邮政业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'H%' THEN 'S64_II_1.8.E.2025' --  1.8住宿和餐饮业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'I%' THEN 'S64_II_1.9.E.2025' --  1.9信息传输、软件和信息技术服务业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'J%' THEN 'S64_II_1.10.E.2025' --  1.10金融业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'K%' THEN 'S64_II_1.11.E.2025' --  1.11房地产业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'L%' THEN 'S64_II_1.12.E.2025' --  1.12租赁和商务服务业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'M%' THEN 'S64_II_1.13.E.2025' --  1.13科学研究和技术服务业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'N%' THEN 'S64_II_1.14.E.2025' --  1.14水利、环境和公共设施管理业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'O%' THEN 'S64_II_1.15.E.2025' --  1.15居民服务、修理和其他服务业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'P%' THEN 'S64_II_1.16.E.2025' --  1.16教育
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'Q%' THEN 'S64_II_1.17.E.2025' --  1.17卫生和社会工作
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'R%' THEN 'S64_II_1.18.E.2025' --  1.18文化、体育和娱乐业
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'S%' THEN 'S64_II_1.19.E.2025' --  1.19公共管理、社会保障和社会组织
                  WHEN C.CORP_BUSINSESS_TYPE LIKE 'T%' THEN 'S64_II_1.20.E.2025' --  1.20国际组织
                   END AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL,
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
             C.CUST_TYP,       -- 客户分类
             T.LOAN_GRADE_CD,
             B.FACILITY_AMT
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON T.DATA_DATE = TT.DATA_DATE
         AND TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX B --ALTER BY 20241224 JLBA202412040012
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
         AND SUBSTR(C.CUST_TYP, 0, 1) IN ('1', '0') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND T.LOAN_GRADE_CD IN ('3','4','5') --不良贷款
         AND SUBSTR(C.CORP_BUSINSESS_TYPE,1,1) IN ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T')
         AND T.LOAN_STOCKEN_DATE IS NULL;

        COMMIT;


    INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_19)
      SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             'S64_II_1.E.2025' AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL,
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
             C.CUST_TYP,       -- 客户分类
             T.LOAN_GRADE_CD,
             B.FACILITY_AMT
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON T.DATA_DATE = TT.DATA_DATE
         AND TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.LOAN_ACCT_BAL <> 0 --贷款余额
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND SUBSTR(t.ITEM_CD, 1, 6) not IN ('130102', '130105') --转贴现 --不含票据转贴现
         AND B.FACILITY_AMT <= 10000000 --单户授信总额1000万元及以下
         AND ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
             AND (P.OPERATE_CUST_TYPE IN ('A', 'B') OR C.CUST_TYP ='3'))
         AND T.LOAN_GRADE_CD IN ('3','4','5') --不良贷款
         AND T.LOAN_STOCKEN_DATE IS NULL;
       COMMIT;

INSERT INTO CBRC_A_REPT_DWD_S6402
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
       COL_19)
      SELECT 
             I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6402' AS REP_NUM, -- 报表编号
             'S64_II_1.E.2025' AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL,
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
             C.CUST_TYP,       -- 客户分类
             T.LOAN_GRADE_CD,
             B.FACILITY_AMT
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON T.DATA_DATE = TT.DATA_DATE
         AND TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX B --ALTER BY 20241224 JLBA202412040012
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
         AND SUBSTR(C.CUST_TYP, 0, 1) IN ('1', '0') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND T.LOAN_GRADE_CD IN ('3','4','5') --不良贷款
         AND T.LOAN_STOCKEN_DATE IS NULL  ;
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
             'S6402' AS REP_NUM,
             T.ITEM_NUM,
             SUM(TOTAL_VALUE) AS ITEM_VAL,
             '2' AS FLAG,
             DATA_DEPARTMENT
        FROM CBRC_A_REPT_DWD_S6402 T
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM, T.ITEM_NUM,DATA_DEPARTMENT;

    COMMIT;

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
