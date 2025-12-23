CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s6302(II_DATADATE IN STRING --跑批日期
                                              )
/******************************
  @AUTHOR:JIHAIJING
  @CREATE-DATE:20150929
  @DESCRIPTION:S6302
  @MODIFICATION HISTORY:
  M0.AUTHOR-CREATE_DATE-DESCRIPTION
  M1.20160427.SHENYUNFEI.2016制度升级，取消所有E列指标
  m2.20220321.shiyu.新增银税贷款取数逻辑
  M3 SHIYU 注释客户全量客户境内标识
  
 目标表：CBRC_A_REPT_ITEM_VAL
      CBRC_A_REPT_DWD_S6302
集市表：
SMTMODS_L_ACCT_LOAN
SMTMODS_L_AGRE_GUARANTEE_CONTRACT
SMTMODS_L_AGRE_GUARANTEE_RELATION
SMTMODS_L_AGRE_GUARANTY_INFO
SMTMODS_L_AGRE_GUA_RELATION
SMTMODS_L_CUST_ALL
SMTMODS_L_CUST_C
SMTMODS_L_CUST_P
SMTMODS_L_PUBL_ORG_BRA
SMTMODS_L_PUBL_RATE

  *******************************/
 IS
  V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE  VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE  VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE := II_DATADATE;
    V_SYSTEM   := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_S6302');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME := 'CBRC_A_REPT_DWD_S6302';
    V_DATADATE := TO_CHAR(DATE(I_DATADATE), 'YYYY-MM-DD');

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']S6302当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S6302';
    
       DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'S6302'
       AND T.FLAG = '2';

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*--------------------------------------------------------  -------------------信用贷款---大、中、小、微型企业不良贷款----------------------------------------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据信用贷款至S6302_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20             -- 经办员工ID
   )
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
         AND LOAN.LOAN_STOCKEN_DATE IS NULL;
      COMMIT;

INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20             -- 经办员工ID
      )
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
         AND LOAN.LOAN_STOCKEN_DATE IS NULL ;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*----  --------------------------------------------------------保证贷款-大、中、小、微型企业不良贷款-------------------------------------------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据保证贷款至S6302_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20             -- 经办员工ID
   )
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
         AND LOAN.LOAN_ACCT_BAL <> 0;

  COMMIT;
    ---------------------其中：个体工商户不良贷款-信用贷款-保证贷款-抵（质）押贷款--------------

INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20           , -- 经办员工ID
      COL_21             -- 经营性客户类型
   )
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
       ORDER BY T.ORG_NUM;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*-------------------------  -------------------保抵（质）押贷款----------------------------------------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据保抵（质）押贷款至S6302_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20             -- 经办员工ID
   )
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
         AND LOAN.LOAN_STOCKEN_DATE IS NULL ;
  COMMIT;
    -----------------------------其中：小微企业主不良贷款-信用贷款-保证贷款-抵（质）押贷款----------------
INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20           , -- 经办员工ID
      COL_21             -- 经营性客户类型
      )
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
         AND T.LOAN_STOCKEN_DATE IS NULL;
    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*----  ------------------------------------------------贴现及买断式转贴现-----------------------------------------------------*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据贴现及买断式转贴现至S6302_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20             -- 经办员工ID
      )
       SELECT 
             I_DATADATE AS DATA_DATE,  -- 数据日期
             LOAN.ORG_NUM  AS ORG_NUM,   -- 机构号
             LOAN.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6302' AS REP_NUM, -- 报表编号
             CASE WHEN C.CORP_SCALE = 'B' THEN 'S63_2_2_4..A' -- 大型企业不良贷款
                  WHEN C.CORP_SCALE = 'M' THEN 'S63_2_2_4..B' -- 中型企业不良贷款
                  WHEN C.CORP_SCALE = 'S' THEN 'S63_2_2_4..C' -- 小型企业不良贷款
                  WHEN C.CORP_SCALE = 'T' THEN 'S63_2_2_4..D' -- 微型企业不良贷款
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
             NULL,               -- 客户大类
             LOAN.LOAN_GRADE_CD, -- 五级分类代码
             C.CORP_SCALE,       -- 企业规模
             C.CUST_TYP,         -- 客户分类
             LOAN.LOAN_STOCKEN_DATE, -- 证券化日期
             LOAN.JBYG_ID        -- 经办员工ID
        FROM SMTMODS_L_ACCT_LOAN LOAN
        INNER JOIN SMTMODS_L_CUST_C C
          ON C.CUST_ID = LOAN.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT DATA_DATE, -- 数据日期
                          CONTRACT_NUM, -- 业务合同号
                          MAX(LOAN_SUBTYPE) AS LOAN_SUBTYPE, -- 贷款属性
                          SUM(COLL_MK_VAL_SUM) AS COLL_MK_VAL -- 押品市场价值和
                     FROM (SELECT A.DATA_DATE,
                                  A.CONTRACT_NUM,
                                  CASE WHEN B.GUAR_TYP = 'A0101' THEN 'C'
                                    WHEN B.GUAR_TYP = 'B0101' THEN 'D'
                                    WHEN B.GUAR_TYP IN ('C0101','C0201','C0301','C0302','C0401') THEN 'B'
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
                              AND U.BASIC_CCY = D.COLL_CCY --  基准币种
                              AND U.FORWARD_CCY = 'CNY' --  折算币种
                            WHERE C.GUAR_CUST_ID IS NOT NULL
                              AND A.DATA_DATE = I_DATADATE
                              AND GUAR_CONTRACT_STATUS = 'Y')
                    GROUP BY DATA_DATE, CONTRACT_NUM) GUA
          ON LOAN.ACCT_NUM = GUA.CONTRACT_NUM
         AND GUA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = LOAN.CURR_CD --  基准币种
         AND U.FORWARD_CCY = 'CNY' --  折算币种
       WHERE LOAN.ACCT_TYP NOT LIKE '90%'
         AND LOAN.ACCT_STS <> '3'
         AND LOAN.DATA_DATE = I_DATADATE
         AND LOAN.CANCEL_FLG<>'Y'
         AND LOAN.ACCT_TYP IN ('C01', '030101', '030102')
         AND GUA.LOAN_SUBTYPE = 'B'
         AND LOAN.LOAN_GRADE_CD IN ('3', '4', '5')
         AND C.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND substr(C.CUST_TYP, 1, 1) in ('1', '0') --  判断对公客户是企业
         AND C.CUST_TYP <> '3'
         AND LOAN.LOAN_ACCT_BAL <> 0
         AND LOAN.LOAN_STOCKEN_DATE IS NULL ;
  COMMIT;

 INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20             -- 经办员工ID
      )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6302' AS REP_NUM, -- 报表编号
             'S63_2_2_4..F' AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) + (T.INT_ADJEST_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             NULL,               -- 贷款属性
             NULL,               -- 客户大类
             T.LOAN_GRADE_CD, -- 五级分类代码
             NULL,               -- 企业规模
             NULL,               -- 客户分类
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID        -- 经办员工ID
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
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG<>'Y'
         AND T.ACCT_TYP IN ('030101', '030102')
         AND T.LOAN_GRADE_CD IN ('3', '4', '5')
         AND T.LOAN_STOCKEN_DATE IS NULL;
  COMMIT;

 INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20           , -- 经办员工ID
      COL_21             -- 经营性客户类型
   )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6302' AS REP_NUM, -- 报表编号
             'S63_2_2_4..G' AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) + (T.INT_ADJEST_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             a.CUST_TYPE,     -- 客户大类
             T.LOAN_GRADE_CD, -- 五级分类代码
             b.CORP_SCALE,       -- 企业规模
             b.CUST_TYP,         -- 客户分类
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,        -- 经办员工ID
             P.OPERATE_CUST_TYPE -- 经营性客户类型
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE (P.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3')
         AND T.ACCT_TYP IN ('030101', '030102')
         AND T.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T.ACCT_STS <> '3' --账户状态不为结清
         AND T.CANCEL_FLG<>'Y'
         AND T.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL
         ;
COMMIT;

 INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20           , -- 经办员工ID
      COL_21             -- 经营性客户类型
   )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6302' AS REP_NUM, -- 报表编号
             'S63_2_2_4..H'  AS ITEM_NUM,
             (T.LOAN_ACCT_BAL * U.CCY_RATE) + (T.INT_ADJEST_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
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
             A.CUST_TYPE,     -- 客户大类
             T.LOAN_GRADE_CD, -- 五级分类代码
             B.CORP_SCALE,       -- 企业规模
             B.CUST_TYP,         -- 客户分类
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,        -- 经办员工ID
             P.OPERATE_CUST_TYPE -- 经营性客户类型
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U -- 汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD -- 基准币种
         AND U.FORWARD_CCY = 'CNY' -- 折算币种
       WHERE P.OPERATE_CUST_TYPE = 'B'
         AND T.ACCT_TYP IN ('C01', '030101', '030102')
         AND T.LOAN_GRADE_CD IN ('3', '4', '5')
         AND T.ACCT_TYP NOT LIKE '90%' -- 委托贷款
         AND T.ACCT_STS <> '3' -- 账户状态不为结清
         AND T.CANCEL_FLG<>'Y'
         AND A.DATA_DATE = I_DATADATE
         AND T.LOAN_STOCKEN_DATE IS NULL ;
         COMMIT ;
    --================================银税合作贷款=============================================ypb20220225更新

  V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据银税合作贷款至S6302_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
   SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --企业不良贷款


 INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20           , -- 经办员工ID
      COL_21           , -- 经营性客户类型
      COL_22             -- 银税贷款标志
      )
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
         ;

    COMMIT;

   --- 个人经营性不良贷款

 INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20           , -- 经办员工ID
      COL_21           , -- 经营性客户类型
      COL_22             -- 银税贷款标志
      )
      SELECT
             '20250731' AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6302' AS REP_NUM, -- 报表编号
             'S63_2_2_5..F' AS ITEM_NUM,
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
             NULL,            -- 企业规模
             NULL,            -- 客户分类
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             NULL,            -- 经营性客户类型
             T.TAX_RELATED_FLG    -- 银税贷款标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = '20250731'
         AND T.ACCT_TYP LIKE '0102%' --经营性贷款
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类-次级类贷款、可疑类贷款、损失类贷款
         AND T.TAX_RELATED_FLG ='Y' --银税贷款标志
        ;
   COMMIT;

   --个体工商户

 INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20           , -- 经办员工ID
      COL_21           , -- 经营性客户类型
      COL_22             -- 银税贷款标志
      )
      SELECT 
             '20250731' AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6302' AS REP_NUM, -- 报表编号
             'S63_2_2_5..G' AS ITEM_NUM,
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
             NULL,            -- 企业规模
             NULL,            -- 客户分类
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             NULL,            -- 经营性客户类型
             T.TAX_RELATED_FLG    -- 银税贷款标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND T.DATA_DATE = P.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID=C.CUST_ID
          AND C.DATA_DATE='20250731'
       WHERE T.DATA_DATE = '20250731'
         AND T.ACCT_TYP LIKE '0102%' --经营性贷款
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         AND (P.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP='3')
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类-次级类贷款、可疑类贷款、损失类贷款
         AND T.TAX_RELATED_FLG ='Y' --银税贷款标志
        ;
   COMMIT;

   ---小微企业

 INSERT INTO CBRC_A_REPT_DWD_S6302
     (DATA_DATE        , --  数据日期
      ORG_NUM          , --  机构号
      DATA_DEPARTMENT  , --  数据条线
      SYS_NAM          , --  模块简称
      REP_NUM          , --  报表编号
      ITEM_NUM         , --  指标号
      TOTAL_VALUE      , --  汇总值
      COL_1            , -- 合同号
      COL_2            , -- 借据号
      COL_3            , -- 客户号
      COL_4            , -- 科目号
      COL_5            , -- 币种
      COL_6            , -- 放款金额
      COL_7            , -- 放款日期
      COL_8            , -- 原始到期日期
      COL_9            , -- 账户类型
      COL_10           , -- 账户类型说明
      COL_12           , -- 账户状态
      COL_13           , -- 核销标志
      COL_14           , -- 贷款属性
      COL_15           , -- 客户大类
      COL_16           , -- 五级分类代码
      COL_17           , -- 企业规模
      COL_18           , -- 客户分类
      COL_19           , -- 证券化日期
      COL_20           , -- 经办员工ID
      COL_21           , -- 经营性客户类型
      COL_22             -- 银税贷款标志
      )
      SELECT 
             '20250731' AS DATA_DATE,
             T.ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC'  AS SYS_NAM,  -- 模块简称
             'S6302' AS REP_NUM, -- 报表编号
             'S63_2_2_5..H' AS ITEM_NUM,
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
             NULL,            -- 企业规模
             NULL,            -- 客户分类
             T.LOAN_STOCKEN_DATE, -- 证券化日期
             T.JBYG_ID,       -- 经办员工ID
             NULL,            -- 经营性客户类型
             T.TAX_RELATED_FLG    -- 银税贷款标志
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND T.DATA_DATE = P.DATA_DATE
       WHERE T.DATA_DATE = '20250731'
         AND T.ACCT_TYP LIKE '0102%' --经营性贷款
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         AND P.OPERATE_CUST_TYPE = 'B'
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类-次级类贷款、可疑类贷款、损失类贷款
         AND T.TAX_RELATED_FLG ='Y' --银税贷款标志
        ;
    COMMIT;

    V_STEP_DESC := '提取数据银税合作贷款至S6302_DATA_COLLECT_TMP中间表完成';
    V_STEP_FLAG := 1;
   SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --**************************************************

    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

      --=======================================================================================================-
    -------------------------------------S6302数据插至目标指标表--------------------------------------------
    --=====================================================================================================---

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生S6302指标数据，插至目标表';
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
             'S6302' AS REP_NUM,
             T.ITEM_NUM,
             SUM(TOTAL_VALUE) AS ITEM_VAL,
             '2' AS FLAG,
             DATA_DEPARTMENT
        FROM CBRC_A_REPT_DWD_S6302 T
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM, T.ITEM_NUM,DATA_DEPARTMENT;

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
   
END proc_cbrc_idx2_s6302