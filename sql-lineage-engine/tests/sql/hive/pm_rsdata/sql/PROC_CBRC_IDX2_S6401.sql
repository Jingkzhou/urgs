CREATE OR REPLACE PROCEDURE PROC_CBRC_IDX2_S6401(II_DATADATE IN STRING --跑批日期
                                              )
/******************************
  @AUTHOR:JIHAIJING
  @CREATE-DATE:20150929
  @DESCRIPTION:S6401
  @MODIFICATION HISTORY:
  M0.AUTHOR-CREATE_DATE-DESCRIPTION
  M1.20160427.SHENYUNFEI.2016制度升级，取消所有E列指标
  M3.授信额度因S7101修改，同步更改 20220722 shiyu
  M4.20230224 SHIYU  修改内容：新增6.首贷户情况逻辑
  M5.20230828 shiyu 修改内容：普惠型小微企业贷款：单位客户及单位名称的个体工商户取客户授信协议金额，不考虑授信协议状态，自然人客户取客户合同金额合计
  M6 20240228 首贷户逻辑，修改按照客户分组，放款日期取最小的，借据号按照从小到大排序
  M7 20240708  zy  添加金融市场部的大中小微企业的买断式转贴现的值
  M8 20241224 shiyu 改为有授信视图出数据 v_pub_idx_sx_phjrdksx

目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_A_REPT_DWD_S6401
依赖表：CBRC_L_CUST_C_TMP
        CBRC_L_CUST_P_TMP
        CBRC_S6401_CREDITLINE_HZ
集市表：SMTMODS_L_ACCT_LOAN
        SMTMODS_L_AGRE_BILL_INFO
        SMTMODS_L_AGRE_LOAN_APPLY
        SMTMODS_L_AGRE_LOAN_CONTRACT
        SMTMODS_L_CUST_BILL_TY
        SMTMODS_L_CUST_C
        SMTMODS_L_CUST_EXTERNAL_INFO
        SMTMODS_L_CUST_P
        SMTMODS_L_PUBL_RATE
视图表：SMTMODS_V_PUB_IDX_DK_DGSNDK
        SMTMODS_V_PUB_IDX_DK_GRSNDK
        SMTMODS_V_PUB_IDX_DK_GTGSHSNDK
        SMTMODS_V_PUB_IDX_SX_PHJRDKSX

  
  *******************************/
 IS
  V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
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
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE  := II_DATADATE;
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_S6401');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME := 'CBRC_A_REPT_ITEM_VAL';
    D_DATADATE_CCY := I_DATADATE;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']S6401当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S6401';

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'S6401'
       AND T.FLAG = '2';
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*---------------------------------  -------------------大型企业-------------------------------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据大型企业至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 INSERT INTO CBRC_A_REPT_DWD_S6401
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
    COMMIT;


    --  单独取直贴
   INSERT INTO CBRC_A_REPT_DWD_S6401
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
         AND A.LOAN_ACCT_BAL <> 0;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*----  --------------------------------------------------------中型企业-----------------------------------------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据中型企业至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  INSERT INTO CBRC_A_REPT_DWD_S6401
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
    COMMIT;

    -- 单独取直贴
  INSERT INTO CBRC_A_REPT_DWD_S6401
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
         AND A.LOAN_ACCT_BAL <> 0;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*----  -------------------------------------小型企业--------------------------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据小型企业至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 INSERT INTO CBRC_A_REPT_DWD_S6401
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
    COMMIT;


      -- 单独取直贴
  INSERT INTO CBRC_A_REPT_DWD_S6401
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
       AND T.LOAN_ACCT_BAL <> 0;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*----  -------------------------------------微型企业--------------------------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据微型企业至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT INTO CBRC_A_REPT_DWD_S6401
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
    COMMIT;


    --  单独取直贴
  INSERT INTO CBRC_A_REPT_DWD_S6401
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
         AND T.LOAN_ACCT_BAL <> 0;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


-----------================================M7  ZHANGYUE BY 20270726 新增转贴现取数逻辑 start   -----
---转贴现=商承+银承
--商承取数逻辑
  INSERT INTO CBRC_A_REPT_DWD_S6401
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
           CASE WHEN T3.CORP_SCALE = 'B' THEN 'S64_I_1.21.A'
                WHEN T3.CORP_SCALE = 'M' THEN 'S64_I_1.21.B'
                WHEN T3.CORP_SCALE = 'S' THEN 'S64_I_1.21.C'
                WHEN T3.CORP_SCALE = 'T' THEN 'S64_I_1.21.D'
                 END AS ITEM_NUM,
           T.LOAN_ACCT_BAL * TT.CCY_RATE AS LOAN_ACCT_BAL_RMB,
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
           T3.CUST_TYP      -- 客户分类
      FROM SMTMODS_L_ACCT_LOAN T
     INNER JOIN SMTMODS_L_AGRE_BILL_INFO T1   ---（1）票面信息表，找到出票人编号,汇票号码关联
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
       AND T.ACCT_TYP = '030102' -- 商业承兑汇票
       AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') -- 买断式转贴现
       AND T.LOAN_STOCKEN_DATE IS NULL    --  资产未转让
       AND T.LOAN_ACCT_BAL <> 0;
     COMMIT ;

--银承取数的逻辑

  INSERT INTO CBRC_A_REPT_DWD_S6401
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
           CASE WHEN T3.CORP_SIZE = '01' THEN 'S64_I_1.21.A'
                WHEN T3.CORP_SIZE = '02' THEN 'S64_I_1.21.B'
                WHEN T3.CORP_SIZE = '03' THEN 'S64_I_1.21.C'
                WHEN T3.CORP_SIZE = '04' THEN 'S64_I_1.21.D'
                 END AS ITEM_NUM,
           T.LOAN_ACCT_BAL * TT.CCY_RATE  AS LOAN_ACCT_BAL_RMB,
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
           T3.CORP_SIZE,    -- 企业规模
           NULL             -- 客户分类
      FROM SMTMODS_L_ACCT_LOAN T
     INNER JOIN (SELECT CUST_ID, ECIF_CUST_ID ,LEGAL_TYSHXYDM
                   FROM (SELECT ROW_NUMBER() OVER(PARTITION BY CUST_ID ORDER BY ECIF_CUST_ID) RN,T.*
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
       and TT.FORWARD_CCY = 'CNY'
     WHERE T.DATA_DATE = I_DATADATE
       AND T.ACCT_TYP NOT LIKE '90%'
       AND T.CANCEL_FLG <> 'Y'
       AND T.LOAN_ACCT_BAL <> 0
       AND T3.CORP_SIZE IN ('01', '02', '03', '04')
       AND T.ACCT_TYP = '030101' --030101 银行承兑汇票
       AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
       AND T.LOAN_STOCKEN_DATE IS NULL   -- 资产未转让
       AND T.LOAN_ACCT_BAL <> 0;

    COMMIT;

-----------================================M7  ZHANGYUE BY 20270726 新增转贴现取数逻辑 end    -------


    /*----  -------------------------------------个人经营性贷款--------------------------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据个人经营性贷款至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


  INSERT INTO CBRC_A_REPT_DWD_S6401
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
         AND T.LOAN_ACCT_BAL <> 0;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*----  ------------------------------------其中：个体工商户贷款--------------------------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据其中：个体工商户贷款-至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


  INSERT INTO CBRC_A_REPT_DWD_S6401
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
       COL_19
       )
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
         AND T.LOAN_ACCT_BAL <> 0;
    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*----------------------------------------其中：小微企业主贷款--------------------------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据其中：小微企业主贷款至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


  INSERT INTO CBRC_A_REPT_DWD_S6401
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
       COL_19
       )
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
         AND T.LOAN_ACCT_BAL <> 0;
    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*----------------------------------------1.21 转贴现 个人经营性 ------------------------------*/
    --- ADD BY CHM 20210526

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.21.转贴现 个人经营性贷款余额至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


  INSERT INTO CBRC_A_REPT_DWD_S6401
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
             'S6401' AS REP_NUM, -- 报表编号
             'S64_I_1.21.F' AS ITEM_NUM,
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
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             NULL,            -- 行业类别
             NULL,            -- 企业规模
             NULL,            -- 客户分类
             T.LOAN_PURPOSE_CD -- 贷款投向
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON T.DATA_DATE = TT.DATA_DATE
         AND TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND T.DATA_DATE = P.DATA_DATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         AND SUBSTR(ITEM_CD, 1, 6) IN ('130102', '130105') --转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL    --  资产未转让
         AND T.LOAN_ACCT_BAL <> 0;

    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6401
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
       COL_19
       )

    SELECT 
            I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
            'CBRC'  AS SYS_NAM,  -- 模块简称
            'S6401' AS REP_NUM, -- 报表编号
            'S64_I_1.21.F' AS ITEM_NUM,
             CASE WHEN (P.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3') THEN  'S64_I_1.21.G'--个体工商户
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN 'S64_I_1.21.H' --小微企业
                   END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * TT.CCY_RATE AS LOAN_ACCT_BAL_RMB,
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
             P.OPERATE_CUST_TYPE -- 经营性客户类型
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND T.DATA_DATE = P.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND T.DATA_DATE = C.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON T.DATA_DATE = TT.DATA_DATE
         AND TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_TYP LIKE '0102%'
         AND TT.FORWARD_CCY = 'CNY'
         AND SUBSTR(ITEM_CD, 1, 6) IN ('130102', '130105') --转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0;
    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*----------------------------------------附注----------------------------------------------*/
    /*----------------------------------------2.贷款当年累计发放额------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据2.贷款当年累计发放额至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


  INSERT INTO CBRC_A_REPT_DWD_S6401
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
             CASE WHEN B.CORP_SCALE = 'B' THEN 'S64_I_2..A'
                  WHEN B.CORP_SCALE = 'M' THEN 'S64_I_2..B'
                  WHEN B.CORP_SCALE = 'S' THEN 'S64_I_2..C'
                  WHEN B.CORP_SCALE = 'T' THEN 'S64_I_2..D'
                   END AS ITEM_NUM,
             A.DRAWDOWN_AMT * U.CCY_RATE AS LOAN_ACCT_BAL_RMB,
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
             B.CORP_HOLD_TYPE,-- 行业类别
             B.CORP_SCALE,    -- 企业规模
             B.CUST_TYP       -- 客户分类
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN cbrc_l_cust_c_tmp B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CUST_ID = B.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ACCT_TYP NOT LIKE '90%'
         AND A.CANCEL_FLG = 'N'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND B.INLANDORRSHORE_FLG = 'Y'
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) =
             SUBSTR(I_DATADATE, 1, 4)
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL ;   --  资产未转让
   COMMIT ;

     INSERT INTO CBRC_A_REPT_DWD_S6401
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
             'S64_I_2..F' AS ITEM_NUM,
             T.DRAWDOWN_AMT * U.CCY_RATE  AS LOAN_ACCT_BAL_RMB,
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
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_TYP LIKE '0102%' -- 个人经营性去掉贴现数据
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) =
             SUBSTR(I_DATADATE, 1, 4)
         AND T.LOAN_STOCKEN_DATE IS NULL; -- 资产未转让
   COMMIT ;

   INSERT INTO CBRC_A_REPT_DWD_S6401
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
             'S6401' AS REP_NUM, -- 报表编号
             'S64_I_2..G' AS ITEM_NUM,
             T.DRAWDOWN_AMT * U.CCY_RATE  AS LOAN_ACCT_BAL_RMB,
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
             P.OPERATE_CUST_TYPE
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND B.CUST_TYP = '3'
         AND T.ACCT_TYP LIKE '0102%' -- 个人经营性去掉贴现数据
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) =
             SUBSTR(I_DATADATE, 1, 4)
         AND (P.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3')
         AND T.LOAN_STOCKEN_DATE IS NULL;    --  资产未转让
COMMIT;


  INSERT INTO CBRC_A_REPT_DWD_S6401
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
             'S6401' AS REP_NUM, -- 报表编号
             'S64_I_2..H' AS ITEM_NUM,
             T.DRAWDOWN_AMT * U.CCY_RATE AS LOAN_ACCT_BAL_RMB,
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
             P.OPERATE_CUST_TYPE -- 经营性客户类型
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_TYP LIKE '0102%' -- 个人经营性去掉贴现数据
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) =
             SUBSTR(I_DATADATE, 1, 4)
         AND P.OPERATE_CUST_TYPE = 'B'
         AND T.LOAN_STOCKEN_DATE IS NULL;  -- 资产未转让
    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*----------------------------------------3.贷款当年累计发放户数------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据3.贷款当年累计发放户数至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



INSERT INTO CBRC_A_REPT_DWD_S6401
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
             'S6401' AS REP_NUM, -- 报表编号
             'S64_I_3..F' AS ITEM_NUM,
             1 AS LOAN_ACCT_BAL_RMB,
             T.CUST_ID,
             B.CUST_NAM
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP LIKE '0102%' --  个人经营性去掉贴现数据
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) =  SUBSTR(I_DATADATE, 1, 4)
         AND T.LOAN_STOCKEN_DATE IS NULL ;  --  资产未转让
         COMMIT ;

  INSERT INTO CBRC_A_REPT_DWD_S6401
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
             'S6401' AS REP_NUM, -- 报表编号
             'S64_I_3..G' AS ITEM_NUM,
             1 AS LOAN_ACCT_BAL_RMB,
             T.CUST_ID,
             B.CUST_NAM
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_TYP LIKE '0102%' -- 个人经营性去掉贴现数据
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND (P.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3')
         AND T.LOAN_STOCKEN_DATE IS NULL  ;  --  资产未转让
     COMMIT ;

  INSERT INTO CBRC_A_REPT_DWD_S6401
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
             'S6401' AS REP_NUM, -- 报表编号
             'S64_I_3..H' AS ITEM_NUM,
             1 AS LOAN_ACCT_BAL_RMB,
             T.CUST_ID,
             B.CUST_NAM
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_TYP LIKE '0102%' -- 个人经营性去掉贴现数据
         AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND P.OPERATE_CUST_TYPE = 'B'
         AND T.LOAN_STOCKEN_DATE IS NULL  ;  -- 资产未转让
       COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*----------------------------------------4.贷款当年累计申请户数------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据4.贷款当年累计申请户数至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  INSERT INTO CBRC_A_REPT_DWD_S6401
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
         DATA_DATE
        ,ORG_NUM
        ,DATA_DEPARTMENT
        ,SYS_NAM
        ,REP_NUM
        ,ITEM_NUM
        ,LOAN_ACCT_BAL_RMB
        ,CUST_ID
        ,CUST_NAM
   FROM  ( SELECT 
             DISTINCT
                     I_DATADATE AS DATA_DATE,
                     A.ORG_NUM,
                     NULL AS DATA_DEPARTMENT, -- 数据条线
                     'CBRC'  AS SYS_NAM,  -- 模块简称
                     'S6401' AS REP_NUM, -- 报表编号
                     CASE WHEN B.CORP_SCALE = 'B' THEN 'S64_I_4..A.2014'
                          WHEN B.CORP_SCALE = 'M' THEN 'S64_I_4..B.2014'
                          WHEN B.CORP_SCALE = 'S' THEN 'S64_I_4..C.2014'
                          WHEN B.CORP_SCALE = 'T' THEN 'S64_I_4..D.2014'
                           END AS ITEM_NUM,
                     1 AS LOAN_ACCT_BAL_RMB,
                     A.CUST_ID,
                     B.CUST_NAM
                FROM SMTMODS_L_AGRE_LOAN_APPLY A
               INNER JOIN cbrc_l_cust_c_tmp B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CUST_ID = B.CUST_ID
               WHERE A.ACCT_TYP <> '90'
                 AND B.INLANDORRSHORE_FLG = 'Y'
                 AND SUBSTR(TO_CHAR(A.APPLY_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
                 AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
                 AND A.DATA_DATE = I_DATADATE
              UNION ALL
             SELECT 
                     DISTINCT
                     I_DATADATE AS DATA_DATE,
                     A.ORG_NUM,
                     NULL AS DATA_DEPARTMENT, -- 数据条线
                     'CBRC'  AS SYS_NAM,  -- 模块简称
                     'S6401' AS REP_NUM, -- 报表编号
                     CASE WHEN B.CORP_SCALE = 'B' THEN 'S64_I_4..A.2014'
                          WHEN B.CORP_SCALE = 'M' THEN 'S64_I_4..B.2014'
                          WHEN B.CORP_SCALE = 'S' THEN 'S64_I_4..C.2014'
                          WHEN B.CORP_SCALE = 'T' THEN 'S64_I_4..D.2014'
                           END AS ITEM_NUM,
                     1 AS LOAN_ACCT_BAL_RMB,
                     A.CUST_ID,
                     B.CUST_NAM
                FROM SMTMODS_L_AGRE_LOAN_APPLY A
               INNER JOIN cbrc_l_cust_c_tmp B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CUST_ID = B.CUST_ID
               INNER JOIN SMTMODS_L_AGRE_LOAN_CONTRACT E
                  ON A.ACCT_NUM = E.ACCT_NUM
                 AND A.DATA_DATE = E.DATA_DATE
               INNER JOIN SMTMODS_L_ACCT_LOAN D
                  ON A.DATA_DATE = D.DATA_DATE
                 AND D.ACCT_NUM = E.CONTRACT_NUM
               WHERE A.ACCT_TYP <> '90'
                 AND D.CANCEL_FLG = 'N'
                 AND LENGTHB(D.ACCT_NUM) < 36
                 AND B.INLANDORRSHORE_FLG = 'Y'
                 AND SUBSTR(TO_CHAR(A.APPLY_DT, 'YYYYMMDD'), 1, 4) <> SUBSTR(I_DATADATE, 1, 4)
                 AND SUBSTR(TO_CHAR(D.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
                 AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
                 AND A.DATA_DATE = I_DATADATE
                 AND D.LOAN_STOCKEN_DATE IS NULL    -- 资产未转让
               ) AA ;
    COMMIT;

    --个人经营性贷款
  INSERT INTO CBRC_A_REPT_DWD_S6401
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
         DATA_DATE
        ,ORG_NUM
        ,DATA_DEPARTMENT
        ,SYS_NAM
        ,REP_NUM
        ,ITEM_NUM
        ,LOAN_ACCT_BAL_RMB
        ,CUST_ID
      FROM (  SELECT 
                     DISTINCT
                     I_DATADATE AS DATA_DATE,
                     A.ORG_NUM,
                     NULL AS DATA_DEPARTMENT, -- 数据条线
                     'CBRC'  AS SYS_NAM,  -- 模块简称
                     'S6401' AS REP_NUM, -- 报表编号
                     'S64_I_4..F.2014' AS ITEM_NUM,
                     1 AS LOAN_ACCT_BAL_RMB,
                     A.CUST_ID
                FROM SMTMODS_L_AGRE_LOAN_APPLY A
               WHERE A.ACCT_TYP LIKE '0102%' -- 个人经营性去掉贴现数据
                 AND SUBSTR(TO_CHAR(A.APPLY_DT, 'YYYYMMDD'), 1, 4) =
                     SUBSTR(I_DATADATE, 1, 4)
                 AND A.DATA_DATE = I_DATADATE
              UNION ALL
              SELECT 
                     DISTINCT
                     I_DATADATE AS DATA_DATE,
                     A.ORG_NUM,
                     NULL AS DATA_DEPARTMENT, -- 数据条线
                     'CBRC'  AS SYS_NAM,  -- 模块简称
                     'S6401' AS REP_NUM, -- 报表编号
                     'S64_I_4..F.2014' AS ITEM_NUM,
                     1 AS LOAN_ACCT_BAL_RMB,
                     A.CUST_ID
                FROM SMTMODS_L_AGRE_LOAN_APPLY A
               INNER JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
                  ON A.ACCT_NUM = D.ACCT_NUM
                 AND A.DATA_DATE = D.DATA_DATE
               INNER JOIN SMTMODS_L_ACCT_LOAN E
                  ON A.DATA_DATE = E.DATA_DATE
                 AND E.ACCT_NUM = D.CONTRACT_NUM
               WHERE A.ACCT_TYP LIKE '0102%'
                 AND E.CANCEL_FLG = 'N'
                 AND E.LOAN_STOCKEN_DATE IS NULL
                 AND LENGTHB(E.ACCT_NUM) < 36
                 AND SUBSTR(TO_CHAR(A.APPLY_DT, 'YYYYMMDD'), 1, 4) <>  SUBSTR(I_DATADATE, 1, 4)
                 AND SUBSTR(TO_CHAR(E.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
                 AND A.DATA_DATE = I_DATADATE) AA ;
    COMMIT;

  INSERT INTO CBRC_A_REPT_DWD_S6401
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
             A.ORG_NUM,
             NULL AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             'S64_I_4..G.2014' AS ITEM_NUM,
             1 AS LOAN_ACCT_BAL_RMB,
             A.CUST_ID,
             C.CUST_NAM
        FROM SMTMODS_L_AGRE_LOAN_APPLY A
       INNER JOIN CBRC_L_CUST_P_TMP B
          ON A.CUST_ID = B.CUST_ID
       INNER JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE A.ACCT_TYP LIKE '0102%'
         AND B.INLANDORRSHORE_FLG = 'Y'
         AND SUBSTR(TO_CHAR(A.APPLY_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND (B.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3')
         AND A.DATA_DATE = I_DATADATE;
    COMMIT;

     INSERT INTO CBRC_A_REPT_DWD_S6401
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
             A.ORG_NUM,
             NULL AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             'S64_I_4..G.2014' AS ITEM_NUM,
             1 AS LOAN_ACCT_BAL_RMB,
             A.CUST_ID,
             C.CUST_NAM
        FROM SMTMODS_L_AGRE_LOAN_APPLY A
       INNER JOIN CBRC_L_CUST_P_TMP B
          ON A.CUST_ID = B.CUST_ID
       INNER JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON A.ACCT_NUM = D.ACCT_NUM
         AND A.DATA_DATE = D.DATA_DATE
       INNER JOIN SMTMODS_L_ACCT_LOAN E
          ON A.DATA_DATE = E.DATA_DATE
         AND E.ACCT_NUM = D.CONTRACT_NUM
       INNER JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE --SHIWENBO BY 20170318-CUST 去掉关联对公客户表
       WHERE A.ACCT_TYP LIKE '0102%'
         AND B.INLANDORRSHORE_FLG = 'Y'
         AND SUBSTR(TO_CHAR(A.APPLY_DT, 'YYYYMMDD'), 1, 4) <> SUBSTR(I_DATADATE, 1, 4)
         AND SUBSTR(TO_CHAR(E.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND A.DATA_DATE = I_DATADATE
         AND E.CANCEL_FLG = 'N'
         AND LENGTHB(E.ACCT_NUM) < 36
         AND (B.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3')
         AND E.LOAN_STOCKEN_DATE IS NULL ;
    COMMIT;

     INSERT INTO CBRC_A_REPT_DWD_S6401
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
             'S6401' AS REP_NUM, -- 报表编号
             'S64_I_4..H.2014' AS ITEM_NUM,
             1 AS LOAN_ACCT_BAL_RMB,
             A.CUST_ID
        FROM SMTMODS_L_AGRE_LOAN_APPLY A
       INNER JOIN CBRC_L_CUST_P_TMP B
          ON A.CUST_ID = B.CUST_ID
       WHERE A.ACCT_TYP LIKE '0102%'
         AND B.INLANDORRSHORE_FLG = 'Y'
         AND SUBSTR(TO_CHAR(A.APPLY_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND B.OPERATE_CUST_TYPE = 'B'
         AND A.DATA_DATE = I_DATADATE ;
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6401
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
             'S6401' AS REP_NUM, -- 报表编号
              'S64_I_4..H.2014' AS ITEM_NUM,
             1 AS LOAN_ACCT_BAL_RMB,
             A.CUST_ID
        FROM SMTMODS_L_AGRE_LOAN_APPLY A
       INNER JOIN CBRC_L_CUST_P_TMP B
          ON A.CUST_ID = B.CUST_ID
       INNER JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON A.ACCT_NUM = D.ACCT_NUM
         AND A.DATA_DATE = D.DATA_DATE
       INNER JOIN SMTMODS_L_ACCT_LOAN E
          ON A.DATA_DATE = E.DATA_DATE
         AND E.ACCT_NUM = D.CONTRACT_NUM
       WHERE A.ACCT_TYP LIKE '0102%' --SHIWENBO BY 20170318-GRJYX 个人经营性去掉贴现数据
       AND B.INLANDORRSHORE_FLG = 'Y'
       AND SUBSTR(TO_CHAR(A.APPLY_DT, 'YYYYMMDD'), 1, 4) <> SUBSTR(I_DATADATE, 1, 4)
       AND SUBSTR(TO_CHAR(E.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = SUBSTR(I_DATADATE, 1, 4)
       AND A.DATA_DATE = I_DATADATE
       AND E.CANCEL_FLG = 'N'
       AND LENGTHB(E.ACCT_NUM) < 36
       AND B.OPERATE_CUST_TYPE = 'B'
       AND E.LOAN_STOCKEN_DATE IS NULL ;   --  资产未转让
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*----------------------------------------5.关停企业贷款余额------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据5.关停企业贷款余额至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT INTO CBRC_A_REPT_DWD_S6401
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
             CASE WHEN B.CORP_SCALE = 'B' THEN  'S64_I_5..A'
                  WHEN B.CORP_SCALE = 'M' THEN  'S64_I_5..B'
                  WHEN B.CORP_SCALE = 'S' THEN  'S64_I_5..C'
                  WHEN B.CORP_SCALE = 'T' THEN  'S64_I_5..D'
                  END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * U.CCY_RATE  AS LOAN_ACCT_BAL_RMB,
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
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') -- 增加农村合作社取数逻辑
         AND B.CORP_CLOSE_FLG = 'Y'
         AND T.CANCEL_FLG = 'N'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.LOAN_STOCKEN_DATE IS NULL  -- 资产未转让
         AND T.LOAN_ACCT_BAL <> 0 ;
   COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据授信信息至CBRC_S6401_CREDITLINE_HZ中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S6401_CREDITLINE_HZ';

    INSERT INTO CBRC_S6401_CREDITLINE_HZ
      (CUST_ID, FACILITY_AMT, DATA_DATE)
      SELECT CUST_ID, FACILITY_AMT, DATA_DATE
        FROM SMTMODS_V_PUB_IDX_SX_PHJRDKSX
       WHERE DATA_DATE = I_DATADATE;
    COMMIT;


    ----普惠型小微企业贷款指单户授信总额1000万元及以下的小微企业贷款（个体工商户及小微企业主经营性贷款）
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据个体工商户及小微企业主经营性贷款至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  INSERT INTO CBRC_A_REPT_DWD_S6401
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
         AND T.LOAN_ACCT_BAL <> 0 ;
    COMMIT;

    -- 一部分个体工商户放到了cust_c里

  INSERT INTO CBRC_A_REPT_DWD_S6401
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
    COMMIT;

    INSERT INTO CBRC_A_REPT_DWD_S6401
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
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6401' AS REP_NUM, -- 报表编号
             'S64_I_1.E.2022' AS ITEM_NUM,
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
             C.CORP_HOLD_TYPE,-- 行业类别
             C.CORP_SCALE,    -- 企业规模
             C.CUST_TYP,      -- 客户分类
             P.OPERATE_CUST_TYPE,
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
        AND T.LOAN_STOCKEN_DATE IS NULL    --  资产未转让
        AND T.LOAN_ACCT_BAL <> 0;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --普惠型小微企业贷款指单户授信总额1000万元及以下的小微企业贷款（小微企业法人）

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据普惠型小微企业贷款至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT INTO CBRC_A_REPT_DWD_S6401
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
             'S64_I_1.E.2022' AS ITEM_NUM,
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
             C.CUST_TYP,      -- 客户分类
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
         AND T.LOAN_STOCKEN_DATE IS NULL ;
    COMMIT;

   INSERT INTO CBRC_A_REPT_DWD_S6401
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
         AND T.LOAN_STOCKEN_DATE IS NULL ;
    COMMIT;

    --M4.20230224 SHIYU  修改内容：新增6.首贷户情况逻辑
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据6.首贷户情况至CBRC_A_REPT_DWD_S6401中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- 6.1当年首次贷款的首贷户数
  INSERT INTO CBRC_A_REPT_DWD_S6401
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
               WHERE T.RNK=1;
    COMMIT ;

    --   6.1.1当年首次贷款的涉农首贷户数

  INSERT INTO CBRC_A_REPT_DWD_S6401
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
               WHERE T.RNK=1;
    COMMIT;

  INSERT INTO CBRC_A_REPT_DWD_S6401
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
       COL_17)
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
       WHERE T.RNK=1;
    COMMIT;

   INSERT INTO CBRC_A_REPT_DWD_S6401
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
       COL_17)
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
       WHERE T.RNK=1;
    COMMIT;




    --=======================================================================================================-
    -------------------------------------S6401数据插至目标指标表--------------------------------------------
    --=====================================================================================================---

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生S6401指标数据，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*---  ------------------所有指标插入目标表-----------------------------------  */
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
             'S6401' AS REP_NUM,
             T.ITEM_NUM,
             SUM(TOTAL_VALUE) AS ITEM_VAL,
             '2' AS FLAG,
             DATA_DEPARTMENT
        FROM CBRC_A_REPT_DWD_S6401 T
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM, T.ITEM_NUM,DATA_DEPARTMENT;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

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
