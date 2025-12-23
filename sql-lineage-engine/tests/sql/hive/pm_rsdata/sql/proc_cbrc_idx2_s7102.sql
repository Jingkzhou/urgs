CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s7102(II_DATADATE  IN STRING --跑批日期
                                                       )
/******************************
   @AUTHOR:DJH
   @CREATE-DATE:20250811
   @DESCRIPTION: S7102明细数据

   1.JLBA202503070010_关于吉林银行统一监管报送平台升级的需求  全表按照明细级开发
   cbrc_a_rept_dwd_s7102
cbrc_a_rept_item_val
cbrc_s7101_amt_tmp1
cbrc_s7102_bal_tmp1
cbrc_s7102_temp1
cbrc_s7102_temp1_lj
cbrc_s7102_temp2
cbrc_s7102_temp2_his
cbrc_s7102_temp2_temp
smtmods_a_rept_dwd_mapping
smtmods_l_acct_loan
smtmods_l_acct_loan_farming
smtmods_l_acct_poverty_relif
smtmods_l_cust_all
smtmods_l_cust_c
smtmods_l_cust_p
smtmods_l_publ_org_bra
smtmods_l_publ_rate
smtmods_v_pub_idx_dk_dgsndk
smtmods_v_pub_idx_dk_grsndk
smtmods_v_pub_idx_dk_gtgshsndk
smtmods_v_pub_idx_dk_ysdqrjj
smtmods_v_pub_idx_sx_phjrdksx

  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  NEXTDATE       VARCHAR2(10);
  CURRENTDATE    VARCHAR2(10);
  NUM            INTEGER;
  V_ERRORCODE    VARCHAR(280); --错误内容
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
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_S7102');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME     := 'CBRC_A_REPT_ITEM_VAL';
    D_DATADATE_CCY := I_DATADATE;
    V_STEP_FLAG    := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']S7102当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- SMTMODS_A_REPT_DWD_MAPPING 码值映射表

    CURRENTDATE := TO_CHAR(I_DATADATE, 'YYYYMMDD');
    NEXTDATE    := TO_CHAR(I_DATADATE + 1, 'YYYYMMDD');

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'S7102';
    COMMIT;

  EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S7102';
    --===========================================start====================
    DELETE FROM CBRC_S7102_TEMP1; --删除授信信息
    COMMIT;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S7102_CREDITLINE_TEST';

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工统一授信至CBRC_S7102_TEMP1中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --20241224新增从授信视图出授信数据   JLBA202412040012
    INSERT INTO CBRC_S7102_TEMP1
      (CUST_ID, FACILITY_AMT, DATA_DATE)
      SELECT 
       CUST_ID, FACILITY_AMT, DATA_DATE
        FROM SMTMODS_V_PUB_IDX_SX_PHJRDKSX
       WHERE DATA_DATE = I_DATADATE;
    COMMIT;

    EXECUTE IMMEDIATE ('DELETE FROM  CBRC_S7102_TEMP1_LJ T WHERE  T.DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' || ''); --保留历史数据

    INSERT INTO CBRC_S7102_TEMP1_LJ
      (CUST_ID, FACILITY_AMT, DATA_DATE)
      SELECT 
       CUST_ID, FACILITY_AMT, DATA_DATE
        FROM SMTMODS_V_PUB_IDX_SX_PHJRDKSX
       WHERE DATA_DATE = I_DATADATE;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工当年累计CBRC_S7102_TEMP2';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---------------------------加工当年累计单户授信总额500万元以下普惠型农户经营性贷款----
    --年初删除本年累计
    IF SUBSTR(I_DATADATE, 5, 2) = 01 THEN
      DELETE FROM CBRC_S7102_TEMP2_TEMP T;
      COMMIT;
    END IF;

    DELETE FROM CBRC_S7102_TEMP2_TEMP T WHERE T.DATA_DATE = I_DATADATE;
    COMMIT;

    INSERT INTO CBRC_S7102_TEMP2_TEMP
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       T.CUST_ID, --客户号
       T.FACILITY_AMT FACILITY_AMT, --授信金额
       A.DRAWDOWN_AMT LOAN_ACCT_BAL, --余额
       A.DRAWDOWN_AMT * A.REAL_INT_RAT / 100 NHSY, --年化收益
       A.LOAN_NUM, --借据号
       I_DATADATE, --数据日期
       A.GUARANTY_TYP, --贷款方式
       A.MATURITY_DT, --到期日
       A.DRAWDOWN_DT, --放款日期
       A.CURR_CD,
       A.ACCT_NUM, --合同号
       A.ACCT_TYP, --
       A.ITEM_CD,
       A.DEPARTMENTD,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS LOAN_GRADE_CD,
       A.LOAN_PURPOSE_CD
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
       INNER JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX T --授信加工临时表
          ON T.CUST_ID = A.CUST_ID
         AND T.DATA_DATE = TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD') --取放款时的授信--需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨 修改内容：客户授信逻辑
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '132%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) =
             SUBSTR(I_DATADATE, 1, 6);
    COMMIT;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S7102_TEMP2';

    INSERT INTO CBRC_S7102_TEMP2
      SELECT A.ORG_NUM,
             A.CUST_ID,
             A.FACILITY_AMT,
             A.DRAWDOWN_AMT * TT.CCY_RATE AS DRAWDOWN_AMT,
             A.NHSY * TT.CCY_RATE AS NHSY,
             A.LOAN_NUM,
             A.DATA_DATE,
             A.GUARANTY_TYP,
             A.MATURITY_DT,
             A.DRAWDOWN_DT,
             NVL(P.CUST_NAM, C.CUST_NAM) AS CUST_NAM,
             ORG.ORG_NAM AS ORG_NAM,
             A.ACCT_NUM AS ACCT_NUM,
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS CUST_TYPE,
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS CORP_SCALE,
             A.ITEM_CD,
             T3.M_NAME AS M_NAME,
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS GUARANTY_TYPNA,
             A.DEPARTMENTD,
             A.LOAN_GRADE_CD,
             A.LOAN_PURPOSE_CD
        FROM CBRC_S7102_TEMP2_TEMP A
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = A.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = A.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       where A.FACILITY_AMT <= 5000000;
    commit;

    --清除历史数据，支持重跑
    DELETE FROM CBRC_S7102_TEMP2_HIS WHERE DATA_DATE = I_DATADATE;
    COMMIT;
    --插入累放数据至历史表
    INSERT INTO CBRC_S7102_TEMP2_HIS
      SELECT ORG_NUM,
             CUST_ID,
             FACILITY_AMT,
             DRAWDOWN_AMT,
             NHSY,
             LOAN_NUM,
             DATA_DATE,
             GUARANTY_TYP,
             MATURITY_DT,
             DRAWDOWN_DT
        FROM CBRC_S7102_TEMP2
       WHERE DATA_DATE = I_DATADATE;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工1.普惠型农户经营性贷款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --------------------------1.普惠型农户经营性贷款
    --1.普惠型农户经营性贷款 贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT 
       I_DATADATE, --数据日期
       A.ORG_NUM, --机构号
       A.DEPARTMENTD,--数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S7102' AS REP_NUM, --报表编号
       CASE
         WHEN T.FACILITY_AMT > 1000000 THEN
          'S7102_1.A3'
         WHEN T.FACILITY_AMT > 100000 THEN
          'S7102_1.A2'
         WHEN T.FACILITY_AMT <= 100000 THEN
          'S7102_1.A1'
       END AS ITEM_NUM, --指标号
       A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
       ORG.ORG_NAM AS COL_1, --机构名
       T.CUST_ID AS COL_2, -- (客户号)
       NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
       A.LOAN_NUM AS COL_4, -- (贷款编号)
       A.ACCT_NUM AS COL_6, -- (贷款合同编号)
       T.FACILITY_AMT AS COL_7, -- (授信额度)
       A.DRAWDOWN_DT AS COL_8, -- (放款日期)
       A.MATURITY_DT AS COL_9, -- (原始到期日)
       CASE
         WHEN P.OPERATE_CUST_TYPE = 'A' THEN
          '个体工商户'
         WHEN P.OPERATE_CUST_TYPE = 'B' THEN
          '小微企业主'
         WHEN C.CUST_TYP = '3' THEN
          '个体工商户'
         ELSE
          '其他个人'
       END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_11, -- 字段11(企业规模)
       A.ITEM_CD AS COL_12, -- 字段12(科目号)
       A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_14, -- 字段14(五级分类)
       T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
       --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
       CASE
         WHEN A.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN A.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN A.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN A.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN A.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN A.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN A.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN A.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN A.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN A.GUARANTY_TYP = 'Z' THEN
          '其他'
       END AS COL_17, -- 字段17(贷款担保方式)
       A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    COMMIT;

    --1.普惠型农户经营性贷款  贷款余额户数
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.B3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.B2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.B1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.B3'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.B2'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.B1'
                END,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;
    COMMIT;

    --1.普惠型农户经营性贷款  不良贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT 
       I_DATADATE, --数据日期
       A.ORG_NUM, --机构号
       A.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S7102' AS REP_NUM, --报表编号
       CASE
         WHEN T.FACILITY_AMT > 1000000 THEN
          'S7102_1.C3'
         WHEN T.FACILITY_AMT > 100000 THEN
          'S7102_1.C2'
         WHEN T.FACILITY_AMT <= 100000 THEN
          'S7102_1.C1'
       END AS ITEM_NUM, --指标号
       ORG.ORG_NAM AS COL_1, --机构名
       T.CUST_ID AS COL_2, -- (客户号)
       NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
       A.LOAN_NUM AS COL_4, -- (贷款编号)
       A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
       A.ACCT_NUM AS COL_6, -- (贷款合同编号)
       T.FACILITY_AMT AS COL_7, -- (授信额度)
       A.DRAWDOWN_DT AS COL_8, -- (放款日期)
       A.MATURITY_DT AS COL_9, -- (原始到期日)
       CASE
         WHEN P.OPERATE_CUST_TYPE = 'A' THEN
          '个体工商户'
         WHEN P.OPERATE_CUST_TYPE = 'B' THEN
          '小微企业主'
         WHEN C.CUST_TYP = '3' THEN
          '个体工商户'
         ELSE
          '其他个人'
       END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_11, -- 字段11(企业规模)
       A.ITEM_CD AS COL_12, -- 字段12(科目号)
       A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_14, -- 字段14(五级分类)
       T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
       --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
       CASE
         WHEN A.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN A.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN A.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN A.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN A.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN A.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN A.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN A.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN A.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN A.GUARANTY_TYP = 'Z' THEN
          '其他'
       END AS COL_17, -- 字段17(贷款担保方式)
       A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND A.CANCEL_FLG <> 'Y'
         AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    COMMIT;

    --1.普惠型农户经营性贷款  当年累放贷款额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT 
       I_DATADATE, --数据日期
       A.ORG_NUM, --机构号
       A.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S7102' AS REP_NUM, --报表编号
       CASE
         WHEN A.FACILITY_AMT > 1000000 THEN
          'S7102_1.D3'
         WHEN A.FACILITY_AMT > 100000 THEN
          'S7102_1.D2'
         WHEN A.FACILITY_AMT <= 100000 THEN
          'S7102_1.D1'
       END AS ITEM_NUM, --指标号
       A.ORG_NAM AS COL_1, --机构名
       A.CUST_ID AS COL_2, -- (客户号)
       A.CUST_NAM AS COL_3, -- (客户名)
       A.LOAN_NUM AS COL_4, -- (贷款编号)
       A.DRAWDOWN_AMT AS TOTAL_VALUE, -- (贷款余额)
       A.ACCT_NUM AS COL_6, -- (贷款合同编号)
       A.FACILITY_AMT AS COL_7, -- (授信额度)
       A.DRAWDOWN_DT AS COL_8, -- (放款日期)
       A.MATURITY_DT AS COL_9, -- (原始到期日)
       A.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
       A.CORP_SCALE AS COL_11, -- 字段11(企业规模)
       A.ITEM_CD AS COL_12, -- 字段12(科目号)
       A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
       A.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
       A.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
       --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
       A.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
       A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 A;

    COMMIT;

    --1.普惠型农户经营性贷款 当年累放贷款户数
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN A.FACILITY_AMT > 1000000 THEN
                'S7102_1.E3'
               WHEN A.FACILITY_AMT > 100000 THEN
                'S7102_1.E2'
               WHEN A.FACILITY_AMT <= 100000 THEN
                'S7102_1.E1'
             END AS ITEM_NUM, --指标号
             A.ORG_NAM AS COL_1, --字段1(机构名)
             A.CUST_ID AS COL_2, --字段2(客户号)
             A.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 A
       GROUP BY ORG_NUM,
                CASE
                  WHEN A.FACILITY_AMT > 1000000 THEN
                   'S7102_1.E3'
                  WHEN A.FACILITY_AMT > 100000 THEN
                   'S7102_1.E2'
                  WHEN A.FACILITY_AMT <= 100000 THEN
                   'S7102_1.E1'
                END,
                A.CUST_ID,
                A.CUST_NAM,
                A.ORG_NAM;
    COMMIT;

    --1.普惠型农户经营性贷款 当年累放贷款年化收益
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN A.FACILITY_AMT > 1000000 THEN
                'S7102_1.F3'
               WHEN A.FACILITY_AMT > 100000 THEN
                'S7102_1.F2'
               WHEN A.FACILITY_AMT <= 100000 THEN
                'S7102_1.F1'
             END AS ITEM_NUM, --指标号
             A.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             A.CUST_NAM AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.NHSY AS TOTAL_VALUE, -- (年化收益)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             A.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             A.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             A.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             A.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             A.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 A;
    commit;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工1.1其中家庭农场贷款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --------------------------1.1其中：家庭农场贷款------------------------------
    ----贷款余额 --ADD BY YHY 20211214
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S71_II_1.1.A3.2018'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S71_II_1.1.A2.2018'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S71_II_1.1.A1.2018'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*       V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND T.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
         AND A.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    COMMIT;

    ----贷款余额户数 --ADD BY YHY 20211214
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S71_II_1.1.B3.2018'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S71_II_1.1.B2.2018'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S71_II_1.1.B1.2018'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             P.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                T.CUST_ID,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S71_II_1.1.B3.2018'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S71_II_1.1.B2.2018'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S71_II_1.1.B1.2018'
                END,
                ORG.ORG_NAM,
                P.CUST_NAM;
    COMMIT;

    ----不良贷款余额 --ADD BY YHY 20211214

    --1.普惠型农户经营性贷款 贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       --COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S71_II_1.1.C3.2018'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S71_II_1.1.C2.2018'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S71_II_1.1.C1.2018'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             P.CUST_NAM AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /* V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
         AND A.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    COMMIT;

    ----当年累放贷款额 --ADD BY YHY 20211214

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S71_II_1.1.D.2018' AS ITEM_NUM, --指标号
             A.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             A.CUST_NAM AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.DRAWDOWN_AMT AS TOTAL_VALUE, -- (年化收益)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             A.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             A.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             A.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             A.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             A.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 A
        LEFT JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE <> 'A01'
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A'; --承包方农户类型

    COMMIT;

    ----当年累放贷款户数 --ADD BY YHY 20211214

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S71_II_1.1.E.2018', --指标号
             T.ORG_NAM AS COL_1, --字段1(机构名)
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 T
        LEFT JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON T.LOAN_NUM = R.LOAN_NUM
         AND T.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE <> 'A01'
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
       GROUP BY T.ORG_NUM, T.CUST_ID, T.ORG_NAM, T.CUST_NAM;
    COMMIT;

    ----当年累放贷款年化收益 --ADD BY YHY 20211214

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S71_II_1.1.F.2018', --指标号
             A.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             A.CUST_NAM AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.NHSY AS TOTAL_VALUE, -- (年化收益)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             A.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             A.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             A.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             A.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             A.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 A
        LEFT JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE <> 'A01'
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A'; --承包方农户类型
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工1.2农户个体工商户';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ----------------------------------农户个体工商户加工逻辑
    --BEGIN
    --合计  1.2其中：普惠型农户个体工商户和农户小微企业主贷款 当年累放贷款余额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.D' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.DRAWDOWN_AMT AS TOTAL_VALUE, -- (放款金额)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
        LEFT JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE P.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款
          OR C.CUST_TYP = '3';
    COMMIT;

    --合计  1.2其中：普惠型农户个体工商户和农户小微企业主贷款 当年累放贷款户数
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.E', --指标号
             T.ORG_NAM AS COL_1, --字段1(机构名)
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 T
        LEFT JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE P.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款
          OR C.CUST_TYP = '3'
       GROUP BY T.ORG_NUM, T.CUST_ID, T.ORG_NAM, T.CUST_NAM;
    COMMIT;

    --合计  1.2其中：普惠型农户个体工商户和农户小微企业主贷款 当年累放贷款年化收益

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.F', --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.NHSY AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
        LEFT JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE P.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款
          OR C.CUST_TYP = '3';
    COMMIT;

    --  1.2其中：普惠型农户个体工商户和农户小微企业主贷款 贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.A3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.2.A2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.A1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND (P.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款
             OR C.CUST_TYP = '3')
         AND A.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    COMMIT;

    -- 1.2其中：普惠型农户个体工商户和农户小微企业主贷款 贷款余额户数
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.B3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.2.B2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.B1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /* V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND (P.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款
             OR C.CUST_TYP = '3')
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.B3'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.B2'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.B1'
                END,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;
    COMMIT;

    -- 1.2其中：普惠型农户个体工商户和农户小微企业主贷款 不良贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.C3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.2.C2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.C1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)

        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /* V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND (P.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款
             OR C.CUST_TYP = '3')
         AND A.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    COMMIT;

    ---------------------------------农户个体工商户  END------------------------------------
    ------------------------  1.3其中：建档立卡贫困户经营性贷款----------------------
    --BEGIN
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工1.3其中：建档立卡贫困户经营性贷款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --合计 当年累放贷款余额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.3.D' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.DRAWDOWN_AMT AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON T.LOAN_NUM = R.LOAN_NUM
         AND R.DATA_DATE = T.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01'; --建档立卡贫困人口贷款，包括未脱贫&返贫;
    COMMIT;

    --合计 当年累放贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.3.E', --指标号
             T.ORG_NAM AS COL_1, --字段1(机构名)
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON T.LOAN_NUM = R.LOAN_NUM
         AND T.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
       GROUP BY ORG_NUM, T.CUST_ID, T.CUST_NAM, T.ORG_NAM;
    COMMIT;

    --合计 当年累放贷款年化收益

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.3.F', --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.NHSY AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON T.LOAN_NUM = R.LOAN_NUM
         AND T.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01'; --建档立卡贫困人口贷款，包括未脱贫&返贫;
    COMMIT;

    --1.3其中：建档立卡贫困户经营性贷款 贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.3.A3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.3.A2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.3.A1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    COMMIT;

    --1.3其中：建档立卡贫困户经营性贷款 贷款余额户数
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.3.B3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.3.B2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.3.B1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /* V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.3.B3'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.3.B2'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.3.B1'
                END,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;
    COMMIT;

    --1.3其中：建档立卡贫困户经营性贷款 不良贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.3.C3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.3.C2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.3.C1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*     V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      ;
    --END

    --------------------------------------    1.3.1 其中：扶贫小额信贷   贷款期限三年以内，放款金额50000以下（含），担保方式：信用，建档立卡
    --BEGIN
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工1.3.1 其中：扶贫小额信贷';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --1.3.1 其中：扶贫小额信贷 贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.3.1.A3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.3.1.A2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.3.1.A1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE

       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND A.DRAWDOWN_AMT <= 50000 --放款金额小于50000
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) <= 36 --三年以内
         AND A.GUARANTY_TYP = 'D' --担保方式D  信用
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE;

    -- 1.3.1 其中：扶贫小额信贷 贷款余额户数
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.3.1.B3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.3.1.B2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.3.1.B1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /* V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND A.DRAWDOWN_AMT <= 50000 --放款金额小于50000
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) <= 36 --三年以内
         AND A.GUARANTY_TYP = 'D' --担保方式D  信用
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.3.1.B3'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.3.1.B2'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.3.1.B1'
                END,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;

    --------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '11111';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- 1.3.1 其中：扶贫小额信贷 不良贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.3.1.C3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.3.1.C2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.3.1.C1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /* V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*  V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND A.DRAWDOWN_AMT <= 50000 --放款金额小于50000
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) <= 36 --三年以内
         AND A.GUARANTY_TYP = 'D' --担保方式D  信用
         AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '22222';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---alter by shiyu 20220223 修改内容 根据最新制度1.3.1 授信500万额度划分范围已不填报，
    ---改为单户授信500万元（含）以下合计报送，新建指标

    --1.3.1 其中：扶贫小额信贷 当年累放贷款额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.3.1.D.2022' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.DRAWDOWN_AMT AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /* V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND R.DATA_DATE = I_DATADATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DRAWDOWN_AMT <= 50000 --放款金额小于50000
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) <= 36 --三年以内
         AND A.GUARANTY_TYP = 'D' --担保方式D  信用
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    COMMIT;

    --1.3.1 其中：扶贫小额信贷 当年累放贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.3.1.E.2022' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --字段1(机构名)
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /* V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /* V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND R.DATA_DATE = I_DATADATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DRAWDOWN_AMT <= 50000 --放款金额小于50000
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) <= 36 --三年以内
         AND A.GUARANTY_TYP = 'D' --担保方式D  信用
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM, T.CUST_ID, T.CUST_NAM, T.ORG_NAM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工2.普惠型涉农小微企业法人贷款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ----------------------------------------------------------
    /****** 新建两张临时表统计普惠型涉农小微企业法人贷款（单户授信总额1000万以下的含本数）贷款余额（CBRC_S7102_BAL_TMP1）及累放贷款金额（S7102_AMT_TMP1）  ****/

    -------新增2.普惠型涉农小微企业法人贷款 贷款余额宽表供其使用------

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S7102_BAL_TMP1';

    INSERT INTO CBRC_S7102_BAL_TMP1
      (DATA_DATE, --1数据日期
       ORG_NUM, --2机构号
       ACCT_NUM, --3合同号
       LOAN_NUM, --4借据号
       FACILITY_AMT, --5授信额度
       LOAN_ACCT_BAL, --6贷款余额
       DRAWDOWN_DT, --7放款日期
       MATURITY_DT, --8原始到期日
       CORP_SCALE, --9企业规模
       ITEM_CD, --10科目号
       TECH_CORP_TYPE, --11科技型企业类型
       UNDERTAK_GUAR_TYPE, --12创业担保贷款类型
       CUST_TYPE, --13客户分类
       OPERATE_CUST_TYPE, --14经营性客户类型
       DEFORMITY_FLG, --15残疾人标志
       LOAN_GRADE_CD, --16五级分类
       GUARANTY_TYP, --17贷款担保方式
       LOAN_KIND_CD, --18贷款形式
       AGREI_P_FLG, --19涉农标志
       COOP_LAON_FLAG, --20农民合作社贷款标志
       RUR_COLL_ECO_ORG_LOAN_FLG, --21农村集体经济组织贷款标志
       CUST_ID, --22客户号
       CUST_NAME, --23客户名称
       DEPARTMENTD, --24业务条线
       M_NAME, --25涉农分类（中文）
       ORG_NAM, --26机构名称
       CORP_SCALE_NAM, --27企业规模（中文）
       LOAN_GRADE_CD_NAM, --28五级分类（中文）
       GUARANTY_TYP_NAM, --29担保方式（中文）
       CUST_TYPE_NAM --30个人客户类型
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --1数据日期
       T.ORG_NUM AS ORG_NUM, --2机构号
       T.ACCT_NUM AS ACCT_NUM, --3合同号
       T.LOAN_NUM AS LOAN_NUM, --4借据号
       B.FACILITY_AMT AS FACILITY_AMT, --5授信额度
       T.LOAN_ACCT_BAL * TT.CCY_RATE AS LOAN_ACCT_BAL, --6贷款余额
       T.DRAWDOWN_DT AS DRAWDOWN_DT, --7放款日期
       T.MATURITY_DT AS MATURITY_DT, --8原始到期日
       C.CORP_SCALE AS CORP_SCALE, --9企业规模
       T.ITEM_CD AS ITEM_CD, --10科目号
       CASE
         WHEN C.TECH_CORP_TYPE = 'C01' THEN
          '1'
         ELSE
          '0'
       END AS TECH_CORP_TYPE, --11科技型企业类型
       T.UNDERTAK_GUAR_TYPE AS UNDERTAK_GUAR_TYPE, --12创业担保贷款类型
       C.CUST_TYP AS CUST_TYPE, --13客户分类
       CASE
         WHEN (T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '132%')) --个体工商户贸易融资
          THEN
          P.OPERATE_CUST_TYPE
       END AS OPERATE_CUST_TYPE, --14经营性客户类型
       P.DEFORMITY_FLG, --15残疾人标志
       T.LOAN_GRADE_CD, --16五级分类
       T.GUARANTY_TYP, --17贷款担保方式
       T.LOAN_KIND_CD, --18贷款形式
       CASE
         WHEN FF.LOAN_NUM IS NOT NULL THEN
          'Y'
         ELSE
          'N'
       END AS AGREI_P_FLG, --19涉农标志
       F.COOP_LAON_FLAG, --20农民合作社贷款标志
       F.RUR_COLL_ECO_ORG_LOAN_FLG, --21农村集体经济组织贷款标志
       T.CUST_ID, --22客户号
       A.CUST_NAM, --23客户名称
       A.DEPARTMENTD, --24业务条线
       T3.M_NAME, --25涉农分类（中文）
       ORG_NAM, --26机构名称
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS CORP_SCALE_NAM, --27企业规模（中文）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS LOAN_GRADE_CD_NAM, --28五级分类（中文）
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END AS GUARANTY_TYP_NAM, --29担保方式（中文）
       CASE
         WHEN P.OPERATE_CUST_TYPE = 'A' THEN
          '个体工商户'
         WHEN P.OPERATE_CUST_TYPE = 'B' THEN
          '小微企业主'
         WHEN C.CUST_TYP = '3' THEN
          '个体工商户'
         ELSE
          '其他个人'
       END AS CUST_TYPE_NAM --30个人客户类型
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --贷款借据信息表 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
          ON P.DATA_DATE = I_DATADATE
         AND T.CUST_ID = P.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户补充信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S7102_TEMP1 B --授信额度
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
      --20250327 修改内容：1104涉农贷款修改与大集中保持一致
       INNER JOIN (SELECT T.LOAN_NUM, T.SNDKFL, T.IF_CT_UA, T.AGR_USE_ADDL
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
                          ((A.SNDKFL LIKE 'C_402%' or
                          A.SNDKFL LIKE 'C_302%') AND (CASE
                            WHEN SUBSTR(A.SNDKFL, 0, 7) IN
                                 ('C_40202', 'C_30202') AND
                                 (NVL(A.AGR_USE_ADDL, '#') IN ('05') OR
                                  NVL(B.LOAN_PURPOSE_CD, '#') IN
                                  ('A0514', 'A0523')) THEN
                             1
                            ELSE
                             0
                          END) = 0))) FF
          ON T.loan_num = FF.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
      /* ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
          ON F.DATA_DATE = I_DATADATE
         AND FF.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_CUST_ALL A --客户表 取农民专业合作社
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(FF.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON T.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL <> 0 --贷款余额
         AND T.ITEM_CD NOT IN ('13010201',
                               '13010202',
                               '13010203',
                               '13010204',
                               '13010205',
                               '13010206',
                               '13010501',
                               '13010502',
                               '13010503',
                               '13010504',
                               '13010505',
                               '13010506',
                               '13010507',
                               '13010508') --刨除票据转贴现
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款;
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND B.FACILITY_AMT <= 10000000 --单户授信总额1000万以下,含本数
         AND C.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(C.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
      ;
    COMMIT;

    ----------新增------------2.普惠型涉农小微企业法人贷款 （单户授信1000万元（含）以下合计）  --ADD BY zxy 20220217

    --  2.普惠型涉农小微企业法人贷款 贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.A0' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0'); -- 企业规模中含事业单位、民办非企业贷款
    COMMIT;

    ----新增 2.1其中：普惠型农村集体经济组织贷款 --ADD BY zxy 20220217

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.1.A0' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.RUR_COLL_ECO_ORG_LOAN_FLG = 'Y'; --农村集体经济组织贷款标志
    COMMIT;

    -- 新增  2.2其中：普惠型农民专业合作社贷款--ADD BY zxy 20220217
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.2.A0' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y'; --农民合作社贷款标志
    COMMIT;

    -------------新增-------------2其中：普惠型涉农小微企业法人贷款 贷款余额户数  --ADD BY zxy 20220217

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.B0' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.DATA_DATE = I_DATADATE
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAME, TT.ORG_NAM;
    COMMIT;

    ---新增--2.1其中：普惠型农村集体经济组织贷款 贷款余额户数   --ADD BY zxy 20220217
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.1.B0' AS ITEM_NUM,
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.RUR_COLL_ECO_ORG_LOAN_FLG = 'Y' --农村集体经济组织贷款标志
         AND TT.DATA_DATE = I_DATADATE
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAME, TT.ORG_NAM;

    COMMIT;
    ---新增-- 2.2其中：普惠型农民专业合作社贷款  贷款余额户数  --ADD BY zxy 20220217
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.2.B0' AS ITEM_NUM,
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         AND TT.DATA_DATE = I_DATADATE
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAME, TT.ORG_NAM;
    COMMIT;
    -------------新增----------------2.普惠型涉农小微企业法人贷款 不良贷款余额  --ADD BY zxy 20220217
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.C0' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.LOAN_GRADE_CD IN ('3', '4', '5'); --不良贷款
    COMMIT;
    ---新增-2.1其中：普惠型农村集体经济组织贷款 不良贷款余额  --ADD BY zxy 20220217
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.1.C0' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.RUR_COLL_ECO_ORG_LOAN_FLG = 'Y' --农村集体经济组织贷款标志
         AND TT.LOAN_GRADE_CD IN ('3', '4', '5'); --不良贷款
    COMMIT;
    ---新增-- 2.2其中：普惠型农民专业合作社贷款 不良贷款余额  --ADD BY zxy 20220217
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.2.C0' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         AND LOAN_GRADE_CD IN ('3', '4', '5'); --不良贷款
    COMMIT;

    ---shiyu 20220621 与S7101取数一致。
    --与S7101用同一张临时表，客户属性用最新客户表数据，非放款时数据

    -----------新增-----------------2.普惠型涉农小微企业法人贷款 当年累放贷款额  --ADD BY zxy 20220217

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.D0' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_AMT AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 10000000
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.CORP_SCALE IN ('S', 'T'); --小微企业
    COMMIT;

    -------------新增----------2普惠型涉农小微企业法人贷款  当年累放贷款户数  --ADD BY zxy 20220217

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.E0' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN CBRC_S7102_TEMP1_LJ T --授信加工临时表
          ON T.CUST_ID = TT.CUST_ID
         AND T.DATA_DATE = I_DATADATE --取当月的授信金额
         AND T.FACILITY_AMT <= 10000000 --单户授信总额1000万元以下，含本数 属于普惠型
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       INNER JOIN --L_ACCT_LOAN_FARMING F --涉农贷款补充
      /* ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
      --20250327 修改内容：1104涉农贷款修改与大集中保持一致
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
           AND (A.SNDKFL LIKE 'C_301%' OR SUBSTR(A.SNDKFL, 0, 5) = 'C_401' OR
               A.SNDKFL LIKE 'C_1%' or SUBSTR(A.SNDKFL, 0, 3) = 'C_2' OR
               ((A.SNDKFL LIKE 'C_402%' or A.SNDKFL LIKE 'C_302%') AND
               (CASE
                 WHEN SUBSTR(A.SNDKFL, 0, 7) IN ('C_40202', 'C_30202') AND
                      (NVL(A.AGR_USE_ADDL, '#') IN ('05') OR
                       NVL(B.LOAN_PURPOSE_CD, '#') IN ('A0514', 'A0523')) THEN
                  1
                 ELSE
                  0
               END) = 0))) F
          ON TT.LOAN_NUM = F.LOAN_NUM
       WHERE SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') --  企业规模中含事业单位、民办非企业贷款
         and NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000 --单户授信总额1000万元以下
         AND TT.FACILITY_AMT <= 10000000
         AND TT.CORP_SCALE IN ('S', 'T')
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAM, ORG.ORG_NAM; --贷款借据信息表

    COMMIT;

    ---------新增----2普惠型涉农小微企业法人贷款  当年累放贷款年化利息收益  --ADD BY zxy 20220217

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.F0' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.NHSY AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)

        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 10000000
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.CORP_SCALE IN ('S', 'T');
    COMMIT;

    -----新增----2.普惠型涉农小微企业法人贷款-----单户授信1000万元（含）以下不含票据融资合计（贷款余额）----add by zxy 20220221
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.A4' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.ITEM_CD NOT LIKE '129%'; --刨除票据
    COMMIT;

    -----新增----2.普惠型涉农小微企业法人贷款-----单户授信1000万元（含）以下不含票据融资合计（贷款余额户数）----add by zxy 20220221
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.B4' AS ITEM_NUM,
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.DATA_DATE = I_DATADATE
         AND TT.ITEM_CD NOT LIKE '129%' --刨除票据
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAME, TT.ORG_NAM;
    COMMIT;

    -----新增----2.普惠型涉农小微企业法人贷款-----单户授信1000万元（含）以下不含票据融资合计（不良贷款余额）----add by zxy 20220221
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.C4' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
         AND TT.ITEM_CD NOT LIKE '129%'; --刨除票据
    COMMIT;

    ---------新增-------2.普惠型涉农小微企业法人贷款 单户授信1000万元（含）以下不含票据融资合计（当年累放贷款额）  --ADD BY zxy 20220221

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.D4' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_AMT AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 10000000
         AND ITEM_CD NOT LIKE '1301%' --刨除票据
         AND TT.CORP_SCALE IN ('S', 'T')
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1'); -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款

    COMMIT;

    ---------新增-------2.普惠型涉农小微企业法人贷款 单户授信1000万元（含）以下不含票据融资合计（当年累放贷款额）  --ADD BY zxy 20220221

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.E4' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S7102_TEMP1_LJ T --授信加工临时表
          ON T.CUST_ID = TT.CUST_ID
         AND T.DATA_DATE = I_DATADATE --取当月的授信金额
         AND T.FACILITY_AMT <= 10000000 --单户授信总额1000万元以下，含本数 属于普惠型
         AND ITEM_CD NOT LIKE '1301%' --刨除票据
       INNER JOIN -- L_ACCT_LOAN_FARMING F --涉农贷款补充
      /*ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
      --20250327 修改内容：1104涉农贷款修改与大集中保持一致
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
           AND (A.SNDKFL LIKE 'C_301%' OR SUBSTR(A.SNDKFL, 0, 5) = 'C_401' OR
               A.SNDKFL LIKE 'C_1%' or SUBSTR(A.SNDKFL, 0, 3) = 'C_2' OR
               ((A.SNDKFL LIKE 'C_402%' or A.SNDKFL LIKE 'C_302%') AND
               (CASE
                 WHEN SUBSTR(A.SNDKFL, 0, 7) IN ('C_40202', 'C_30202') AND
                      (NVL(A.AGR_USE_ADDL, '#') IN ('05') OR
                       NVL(B.LOAN_PURPOSE_CD, '#') IN ('A0514', 'A0523')) THEN
                  1
                 ELSE
                  0
               END) = 0))) F
          ON TT.LOAN_NUM = F.LOAN_NUM
       WHERE SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') --  企业规模中含事业单位、民办非企业贷款
         and NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000 --单户授信总额1000万元以下
         AND TT.FACILITY_AMT <= 10000000
         AND TT.CORP_SCALE IN ('S', 'T')
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAM, ORG.ORG_NAM;
    COMMIT;

    ---------新增-------2.普惠型涉农小微企业法人贷款 单户授信1000万元（含）以下不含票据融资合计（当年累放贷款年化利息收益）--ADD BY zxy 20220221

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             ORG.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.F4' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.NHSY AS TOTAL_VALUE, -- (年化收益)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND TT.FACILITY_AMT <= 10000000
         AND TT.CORP_SCALE IN ('S', 'T')
         AND ITEM_CD NOT LIKE '1301%' --刨除票据
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1'); -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款

    COMMIT;

    --alter by shiyu 20240118---开始

    --alter by shiyu 20240118

    --1.1.4其中：信用类普惠型农户经营性贷款
    --贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.4.A3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.4.A2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.4.A1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /* V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /* V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         and a.guaranty_typ = 'D' --信用贷款
         AND A.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    COMMIT;
    --贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.4.B3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.4.B2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.4.B1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*   V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.GUARANTY_TYP = 'D' --信用贷款
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.1.4.B3.2024'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.1.4.B2.2024'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.1.4.B1.2024'
                END,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;
    COMMIT;

    --不良贷款
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.4.C3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.4.C2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.4.C1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /* V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         and a.guaranty_typ = 'D' --信用贷款
         AND A.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    COMMIT;

    --当年累计放款金额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.4.D.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.DRAWDOWN_AMT AS TOTAL_VALUE, -- (放款金额)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       WHERE T.GUARANTY_TYP = 'D'; --信用贷款
    COMMIT;

    ---当年累放户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.4.E.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --字段1(机构名)
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 T
       WHERE T.GUARANTY_TYP = 'D' --信用贷款
       GROUP BY ORG_NUM, T.CUST_ID, T.CUST_NAM, T.ORG_NAM;
    COMMIT;

    --当年累放贷款收益

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.4.F.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.NHSY AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       WHERE T.GUARANTY_TYP = 'D'; --信用贷款
    COMMIT;

    ---1.1.4.1其中：信用类家庭农场贷款

    --贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.4.1.A3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.4.1.A2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.4.1.A1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             P.CUST_NAM AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_CUST_P P
          ON P.CUST_ID = A.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.GUARANTY_TYP = 'D' --信用贷款
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
         AND A.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让;
    COMMIT;
    --贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.4.1.B3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.4.1.B2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.4.1.B1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             P.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM

       INNER JOIN SMTMODS_L_CUST_P P --alter by shiyu 20220224 农户贷款
          ON P.CUST_ID = A.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.GUARANTY_TYP = 'D' --信用贷款
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.1.4.1.B3.2024'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.1.4.1.B2.2024'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.1.4.1.B1.2024'
                END,
                T.CUST_ID,
                P.CUST_NAM,
                ORG.ORG_NAM;
    COMMIT;

    --不良贷款
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.4.1.C3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.4.1.C2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.4.1.C1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             P.CUST_NAM AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_CUST_P P
          ON P.CUST_ID = A.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         and a.guaranty_typ = 'D' --信用贷款
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
         AND A.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让

    COMMIT;

    --当年累计放款金额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.4.1.D.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.DRAWDOWN_AMT AS TOTAL_VALUE, -- (放款金额)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
       WHERE T.GUARANTY_TYP = 'D'; --信用贷款
    COMMIT;

    ---当年累放户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.4.1.E.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --字段1(机构名)
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
       WHERE T.GUARANTY_TYP = 'D' --信用贷款
       GROUP BY T.ORG_NUM, T.CUST_ID, T.CUST_NAM, T.ORG_NAM;
    COMMIT;

    --当年累放贷款收益

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.4.1.F.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.NHSY AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
       WHERE T.GUARANTY_TYP = 'D'; --信用贷款
    COMMIT;

    ---1.1.5其中：中长期普惠型农户经营性贷款

    --贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.5.A3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.5.A2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.5.A1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12; --中长期贷款
    COMMIT;
    --贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.5.B3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.5.B2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.5.B1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12 --中长期贷款
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.1.5.B3.2024'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.1.5.B2.2024'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.1.5.B1.2024'
                END,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;
    COMMIT;

    --不良贷款
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.5.C3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.5.C2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.5.C1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /* V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /*   V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12; --中长期贷款
    COMMIT;

    --当年累计放款金额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.5.D.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.DRAWDOWN_AMT AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       WHERE MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12; --中长期贷款
    COMMIT;

    ---当年累放户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.5.E.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --字段1(机构名)
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 T
       WHERE MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期贷款
       GROUP BY ORG_NUM, T.CUST_ID, T.CUST_NAM, T.ORG_NAM;
    COMMIT;

    --当年累放贷款收益

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.5.F.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.NHSY AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       WHERE MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12; --中长期贷款
    COMMIT;

    --1.2.3其中：信用类普惠型涉农小微企业法人贷款

    --贷款余额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.3.A.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         and TT.GUARANTY_TYP = 'D'; --信用贷款

    --贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.3.B.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.DATA_DATE = I_DATADATE
         AND TT.GUARANTY_TYP = 'D' --信用贷款
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAME, TT.ORG_NAM;
    COMMIT;

    --不良贷款

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.3.C.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         and TT.GUARANTY_TYP = 'D' --信用贷款
         AND TT.LOAN_GRADE_CD IN ('3', '4', '5'); --不良贷款

    --1.2.3.1其中：信用类普惠型农民专业合作社贷款

    -- 贷款余额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.3.1.A.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         and TT.GUARANTY_TYP = 'D'; --信用贷款
    COMMIT;

    --贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.3.1.B.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         and TT.GUARANTY_TYP = 'D' --信用贷款
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAME, TT.ORG_NAM;
    COMMIT;

    --不良贷款

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.3.1.C.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         and TT.GUARANTY_TYP = 'D' --信用贷款
         AND TT.LOAN_GRADE_CD IN ('3', '4', '5'); --不良贷款
    COMMIT;

    -- 1.2.4其中：中长期普惠型涉农小微企业法人贷款

    --贷款余额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.4.A.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND MONTHS_BETWEEN(tt.MATURITY_DT, tt.DRAWDOWN_DT) > 12;
    COMMIT;

    --贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.4.B.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.DATA_DATE = I_DATADATE
         AND MONTHS_BETWEEN(tt.MATURITY_DT, tt.DRAWDOWN_DT) > 12
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAME, TT.ORG_NAM;
    COMMIT;

    --不良贷款

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.4.C.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND MONTHS_BETWEEN(tt.MATURITY_DT, tt.DRAWDOWN_DT) > 12
         AND TT.LOAN_GRADE_CD IN ('3', '4', '5'); --不良贷款

    --2.粮食重点领域贷款( 粮食重点领域贷款+ 农田基本建设贷款)
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       --COL_7,
       COL_8,
       COL_9,
       --COL_10,
       --COL_11,
       COL_12,
       COL_13,
       --COL_14,
       COL_15,
       --COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2..A.2024' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.LOAN_ACCT_BAL * B.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             --T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             --T.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             --T.CORP_SCALE_NAM    AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD     AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             --T.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             '' AS COL_15, -- 字段15(涉农贷款分类)
             --T.GUARANTY_TYP_NAM  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY' --折人民币
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON T.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --贷款账户类型去除委托贷款
         AND T.ACCT_STS <> 3 --账户状态非注销
         AND T.CANCEL_FLG = 'N' --核销标识为否
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.LOAN_ACCT_BAL <> 0
         AND LENGTH(T.ACCT_NUM) < 36
         AND (substr(T.LOAN_PURPOSE_CD, 1, 4) in
             ('A011', 'C131', 'C262', 'C263', 'C357') or
             substr(T.LOAN_PURPOSE_CD, 1, 5) in
             ('A0121',
               'A0123',
               'A0511',
               'A0512',
               'A0513',
               'C1391',
               'C1392',
               'C1431',
               'F5111',
               'F5112',
               'F5121',
               'F5221',
               'G5951'))
      UNION ALL
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2..A.2024' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             C.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.LOAN_ACCT_BAL * B.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             --T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             --T.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             --T.CORP_SCALE_NAM    AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD     AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             --T.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --T.GUARANTY_TYP_NAM  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F
          ON T.DATA_DATE = F.DATA_DATE
         AND T.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY' --折人民币
       INNER JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
         AND C.CUST_TYP <> '3'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON T.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --贷款账户类型去除委托贷款
         AND T.ACCT_STS <> 3 --账户状态非注销
         AND T.CANCEL_FLG = 'N' --核销标识为否
         AND SUBSTR(F.SNDKFL, 0, 7) in
             ('C_10201', 'C_20201', 'C_30201', 'C_40201')
         AND T.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    commit;

    --2.1农田基本建设贷款

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       --COL_7,
       COL_8,
       COL_9,
       --COL_10,
       --COL_11,
       COL_12,
       COL_13,
       --COL_14,
       COL_15,
       --COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.1.A.2024' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             C.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.LOAN_ACCT_BAL * B.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             --T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             --T.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             --T.CORP_SCALE_NAM    AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD     AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             --T.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --T.GUARANTY_TYP_NAM  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F
      /* ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
          ON T.DATA_DATE = F.DATA_DATE
         AND T.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY' --折人民币
       INNER JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
         AND C.CUST_TYP <> '3'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON T.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --贷款账户类型去除委托贷款
         AND T.ACCT_STS <> 3 --账户状态非注销
         AND T.CANCEL_FLG = 'N' --核销标识为否
         AND SUBSTR(F.SNDKFL, 0, 7) in
             ('C_10201', 'C_20201', 'C_30201', 'C_40201')
         AND T.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    COMMIT;

    ----1.2普惠型涉农小微企业法人贷款（单户授信500万元以下区间划分）
    --贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.A3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.A2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.A1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.FACILITY_AMT <= 5000000;
    commit;
    --贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.B3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.B2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.B1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.FACILITY_AMT <= 5000000
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN tt.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.B3.2024'
                  WHEN tt.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.B2.2024'
                  WHEN tt.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.B1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAME,
                TT.ORG_NAM;
    commit;

    --不良贷款

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.C3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.C2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.C1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.FACILITY_AMT <= 5000000
         and tt.loan_grade_cd in ('3', '4', '5'); --不良贷款
    commit;
    --当年累放贷款额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN TT.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.D3.2024'
               WHEN TT.FACILITY_AMT > 100000 THEN
                'S7102_1.2.D2.2024'
               WHEN TT.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.D1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_AMT AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1'); -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
    COMMIT;

    --当年累放贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN TT.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.E3.2024'
               WHEN TT.FACILITY_AMT > 100000 THEN
                'S7102_1.2.E2.2024'
               WHEN TT.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.E1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN TT.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.E3.2024'
                  WHEN TT.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.E2.2024'
                  WHEN TT.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.E1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAM,
                ORG.ORG_NAM;
    COMMIT;

    --当年累放贷款收益

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tT.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.F3.2024'
               WHEN tT.FACILITY_AMT > 100000 THEN
                'S7102_1.2.F2.2024'
               WHEN tT.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.F1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.NHSY AS TOTAL_VALUE, -- (当年累放贷款额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T')
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1'); -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
    COMMIT;

    --1.2.a普惠型涉农小微企业法人贷款,不含票据融资（单户授信500万元以下区间划分）
    --贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.a.A3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.a.A2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.a.A1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.FACILITY_AMT <= 5000000
         AND Tt.ITEM_CD NOT LIKE '1301%'; --刨除票据
    commit;
    --贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.a.B3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.a.B2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.a.B1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.FACILITY_AMT <= 5000000
         AND Tt.ITEM_CD NOT LIKE '1301%' --刨除票据
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN tt.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.a.B3.2024'
                  WHEN tt.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.a.B2.2024'
                  WHEN tt.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.a.B1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAME,
                TT.ORG_NAM;
    commit;

    --不良贷款

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.a.C3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.a.C2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.a.C1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.FACILITY_AMT <= 5000000
         and TT.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
         AND Tt.ITEM_CD NOT LIKE '1301%'; --刨除票据
    commit;
    --当年累放贷款额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             ORG.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN TT.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.a.D3.2024'
               WHEN TT.FACILITY_AMT > 100000 THEN
                'S7102_1.2.a.D2.2024'
               WHEN TT.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.a.D1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_AMT AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 tt
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND ITEM_CD NOT LIKE '1301%' --刨除票据
         and Tt.CORP_SCALE IN ('S', 'T'); --小微企业
    COMMIT;

    --当年累放贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tT.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.a.E3.2024'
               WHEN tT.FACILITY_AMT > 100000 THEN
                'S7102_1.2.a.E2.2024'
               WHEN tT.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.a.E1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND ITEM_CD NOT LIKE '1301%' --刨除票据
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN Tt.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.a.E3.2024'
                  WHEN tT.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.a.E2.2024'
                  WHEN Tt.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.a.E1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAM,
                ORG.ORG_NAM;
    COMMIT;

    --当年累放贷款收益

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tT.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.a.F3.2024'
               WHEN Tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.a.F2.2024'
               WHEN tT.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.a.F1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (年化收益)
             TT.NHSY AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND ITEM_CD NOT LIKE '1301%'; --刨除票据

    COMMIT;

    -- 1.2.1其中：普惠型农村集体经济组织贷款

    --贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.1.A3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.1.A2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.1.A1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.RUR_COLL_ECO_ORG_LOAN_FLG = 'Y' --农村集体经济组织贷款标志
         AND TT.FACILITY_AMT <= 5000000;
    commit;
    --贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.1.B3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.1.B2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.1.B1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.RUR_COLL_ECO_ORG_LOAN_FLG = 'Y' --农村集体经济组织贷款标志
         AND TT.FACILITY_AMT <= 5000000
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN tt.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.1.B3.2024'
                  WHEN tt.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.1.B2.2024'
                  WHEN tt.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.1.B1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAME,
                TT.ORG_NAM;
    commit;

    --不良贷款

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.1.C3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.1.C2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.1.C1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.RUR_COLL_ECO_ORG_LOAN_FLG = 'Y' --农村集体经济组织贷款标志
         AND TT.FACILITY_AMT <= 5000000
         and tt.loan_grade_cd in ('3', '4', '5'); --不良贷款

    commit;
    --当年累放贷款额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN Tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.1.D3.2024'
               WHEN Tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.1.D2.2024'
               WHEN Tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.1.D1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_AMT AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE TT.AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         and RUR_COLL_ECO_ORG_LOAN_FLG = 'Y'; --农村集体经济组织贷款标志

    COMMIT;

    --当年累放贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN Tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.1.E3.2024'
               WHEN Tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.1.E2.2024'
               WHEN Tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.1.E1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         and RUR_COLL_ECO_ORG_LOAN_FLG = 'Y' --农村集体经济组织贷款标志
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN Tt.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.1.E3.2024'
                  WHEN Tt.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.1.E2.2024'
                  WHEN Tt.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.1.E1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAM,
                ORG.ORG_NAM;
    COMMIT;

    --当年累放贷款收益

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             tt.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.1.F3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.1.F2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.1.F1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.NHSY AS TOTAL_VALUE, -- (年化收益)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 tt
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         and Tt.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         and RUR_COLL_ECO_ORG_LOAN_FLG = 'Y'; --农村集体经济组织贷款标志
    COMMIT;

    -- 1.2.2其中：普惠型农民专业合作社贷款

    --贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.2.A3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.2.A2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.2.A1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         AND TT.FACILITY_AMT <= 5000000;
    commit;
    --贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.2.B3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.2.B2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.2.B1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         AND TT.FACILITY_AMT <= 5000000
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN tt.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.2.B3.2024'
                  WHEN tt.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.2.B2.2024'
                  WHEN tt.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.2.B1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAME,
                TT.ORG_NAM;
    commit;

    --不良贷款

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.2.C3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.2.C2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.2.C1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         AND TT.FACILITY_AMT <= 5000000
         and tt.loan_grade_cd in ('3', '4', '5'); --不良贷款

    commit;
    --当年累放贷款额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             tt.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.2.D3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.2.D2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.2.D1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_AMT AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 tt
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         and Tt.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         and COOP_LAON_FLAG = 'Y'; --农民合作社贷款标志

    COMMIT;

    --当年累放贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             tt.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.2.E3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.2.E2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.2.E1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM cbrc_s7101_amt_tmp1 tt
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         and Tt.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         and COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN tt.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.2.E3.2024'
                  WHEN tt.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.2.E2.2024'
                  WHEN tt.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.2.E1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAM,
                ORG.ORG_NAM;
    COMMIT;

    --当年累放贷款收益

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN Tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.2.F3.2024'
               WHEN Tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.2.F2.2024'
               WHEN Tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.2.F1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (年化收益)
             TT.NHSY AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         and COOP_LAON_FLAG = 'Y'; --农民合作社贷款标志

    COMMIT;

    -- 1.2.3其中：信用类普惠型涉农小微企业法人贷款

    --贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.3.A3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.3.A2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.3.A1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.GUARANTY_TYP = 'D' --信用贷款
         AND TT.FACILITY_AMT <= 5000000;
    commit;
    --贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.3.B3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.3.B2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.3.B1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.GUARANTY_TYP = 'D' --信用贷款
         AND TT.FACILITY_AMT <= 5000000
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN tt.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.3.B3.2024'
                  WHEN tt.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.3.B2.2024'
                  WHEN tt.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.3.B1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAME,
                TT.ORG_NAM;
    commit;

    --不良贷款

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.3.C3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.3.C2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.3.C1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.GUARANTY_TYP = 'D' --信用贷款
         AND TT.FACILITY_AMT <= 5000000
         and tt.loan_grade_cd in ('3', '4', '5'); --不良贷款
    commit;
    --当年累放贷款额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN Tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.3.D3.2024'
               WHEN Tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.3.D2.2024'
               WHEN Tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.3.D1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_AMT AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND GUARANTY_TYP = 'D'; --信用贷款
    COMMIT;

    --当年累放贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tT.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.3.E3.2024'
               WHEN tT.FACILITY_AMT > 100000 THEN
                'S7102_1.2.3.E2.2024'
               WHEN tT.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.3.E1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND GUARANTY_TYP = 'D' --信用贷款
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN Tt.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.3.E3.2024'
                  WHEN tT.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.3.E2.2024'
                  WHEN Tt.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.3.E1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAM,
                ORG.ORG_NAM;
    COMMIT;

    --当年累放贷款收益

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN Tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.3.F3.2024'
               WHEN Tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.3.F2.2024'
               WHEN Tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.3.F1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.NHSY AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND GUARANTY_TYP = 'D' --信用贷款
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1'); -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款

    COMMIT;

    -- 1.2.3.1其中：信用类普惠型农民专业合作社贷款
    --贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.3.1.A3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.3.1.A2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.3.1.A1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         AND TT.FACILITY_AMT <= 5000000
         AND TT.GUARANTY_TYP = 'D'; --信用贷款
    commit;
    --贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.3.1.B3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.3.1.B2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.3.1.B1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         AND TT.GUARANTY_TYP = 'D' --信用贷款
         AND TT.FACILITY_AMT <= 5000000
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN tt.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.3.1.B3.2024'
                  WHEN tt.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.3.1.B2.2024'
                  WHEN tt.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.3.1.B1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAME,
                TT.ORG_NAM;
    commit;

    --不良贷款

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.3.1.C3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.3.1.C2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.3.1.C1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         AND TT.GUARANTY_TYP = 'D' --信用贷款
         AND TT.FACILITY_AMT <= 5000000
         and tt.loan_grade_cd in ('3', '4', '5'); --不良贷款
    commit;
    --当年累放贷款额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN Tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.3.1.D3.2024'
               WHEN Tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.3.1.D2.2024'
               WHEN Tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.3.1.D1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_AMT AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         and COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         AND GUARANTY_TYP = 'D'; --信用贷款

    COMMIT;

    --当年累放贷款户数
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tT.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.3.1.E3.2024'
               WHEN tT.FACILITY_AMT > 100000 THEN
                'S7102_1.2.3.1.E2.2024'
               WHEN tT.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.3.1.E1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         and COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         AND GUARANTY_TYP = 'D' --信用贷款
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN Tt.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.3.1.E3.2024'
                  WHEN Tt.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.3.1.E2.2024'
                  WHEN Tt.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.3.1.E1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAM,
                ORG.ORG_NAM; --贷款借据信息表
    COMMIT;

    --当年累放贷款收益

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN Tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.3.1.F3.2024'
               WHEN Tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.3.1.F2.2024'
               WHEN Tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.3.1.F1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.NHSY AS TOTAL_VALUE, -- (当年累放贷款额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         and COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         AND GUARANTY_TYP = 'D'; --信用贷款
    COMMIT;

    -- 1.2.4其中：中长期普惠型涉农小微企业法人贷款

    --贷款余额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.4.A3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.4.A2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.4.A1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND MONTHS_BETWEEN(Tt.MATURITY_DT, Tt.DRAWDOWN_DT) > 12 --中长期贷款
         AND TT.FACILITY_AMT <= 5000000;
    commit;
    --贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.4.B3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.4.B2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.4.B1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND MONTHS_BETWEEN(Tt.MATURITY_DT, Tt.DRAWDOWN_DT) > 12 --中长期贷款
         AND TT.FACILITY_AMT <= 5000000
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN tt.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.4.B3.2024'
                  WHEN tt.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.4.B2.2024'
                  WHEN tt.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.4.B1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAME,
                TT.ORG_NAM;
    commit;

    --不良贷款

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.4.C3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.4.C2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.4.C1.2024'
             END AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND MONTHS_BETWEEN(Tt.MATURITY_DT, Tt.DRAWDOWN_DT) > 12 --中长期贷款
         AND TT.FACILITY_AMT <= 5000000
         and tt.loan_grade_cd in ('3', '4', '5'); --不良贷款
    commit;
    --当年累放贷款额

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN Tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.4.D3.2024'
               WHEN Tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.4.D2.2024'
               WHEN Tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.4.D1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_AMT AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND MONTHS_BETWEEN(MATURITY_DT, DRAWDOWN_DT) > 12; --中长期贷款
    COMMIT;

    --当年累放贷款户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tT.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.4.E3.2024'
               WHEN tT.FACILITY_AMT > 100000 THEN
                'S7102_1.2.4.E2.2024'
               WHEN tT.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.4.E1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND MONTHS_BETWEEN(MATURITY_DT, DRAWDOWN_DT) > 12 --中长期贷款
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
       GROUP BY TT.ORG_NUM,
                CASE
                  WHEN Tt.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.4.E3.2024'
                  WHEN Tt.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.4.E2.2024'
                  WHEN Tt.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.4.E1.2024'
                END,
                TT.CUST_ID,
                TT.CUST_NAM,
                ORG.ORG_NAM;
    COMMIT;

    --当年累放贷款收益

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             tt.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN tt.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.4.F3.2024'
               WHEN tt.FACILITY_AMT > 100000 THEN
                'S7102_1.2.4.F2.2024'
               WHEN tt.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.4.F1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.NHSY AS TOTAL_VALUE, -- (年化收益)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 5000000
         and tt.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业
         AND MONTHS_BETWEEN(MATURITY_DT, DRAWDOWN_DT) > 12; --中长期贷款
    COMMIT;

    ----2025年新增制度指标
    --3.单户授信1000万元（含）以下的农户经营贷款
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.A.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 10000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL; --add by haorui 20250311 JLBA202408200012 资产未转让
    COMMIT;

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.B.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 10000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;
    COMMIT;

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.C.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 10000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.LOAN_GRADE_CD IN ('3', '4', '5'); --不良贷款
    COMMIT;

    --累放金额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.D.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.DRAWDOWN_AMT AS TOTAL_VALUE, -- (累放金额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2_TEMP A
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = A.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
       where A.FACILITY_AMT <= 10000000;
    COMMIT;
    --累放户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.E.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             A.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2_TEMP A
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = A.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
       where A.FACILITY_AMT <= 10000000
       GROUP BY A.ORG_NUM,
                A.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;
    COMMIT;

    --累放收益
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.F.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.NHSY AS TOTAL_VALUE, -- (累放金额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2_TEMP A
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = A.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       where A.FACILITY_AMT <= 10000000;
    COMMIT;

    ------3.1其中：农户个体工商户和农户小微企业主贷款

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.1.A.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = A.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = A.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 10000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B'));
    COMMIT;

    ---
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.1.B.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = A.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = A.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 10000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B'))
       GROUP BY A.ORG_NUM,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;
    COMMIT;

    ----
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.1.C.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = A.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = A.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 10000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B'))
         AND A.LOAN_GRADE_CD IN ('3', '4', '5');
    COMMIT;
    --累放金额
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.1.D.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.DRAWDOWN_AMT * TT.CCY_RATE AS TOTAL_VALUE, -- (累放金额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2_TEMP A
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON C.CUST_ID = A.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       where A.FACILITY_AMT <= 10000000
         AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B'));
    COMMIT;
    --累放户数

    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.1.E.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             A.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2_TEMP A
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON C.CUST_ID = A.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       where A.FACILITY_AMT <= 10000000
         AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B'))
       GROUP BY A.ORG_NUM,
                A.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;
    COMMIT;
    --累放收益
    INSERT INTO 
    CBRC_A_REPT_DWD_S7102 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
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
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.1.F.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.NHSY * TT.CCY_RATE AS TOTAL_VALUE, -- (累放金额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2_TEMP A
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON C.CUST_ID = A.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       where A.FACILITY_AMT <= 10000000
         AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B'));
    COMMIT;

    --插入结果表
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '插入结果表CBRC_A_REPT_ITEM_VAL';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM , DATA_DEPARTMENT, ITEM_VAL )
      SELECT T.DATA_DATE,
             T.ORG_NUM,
             T.SYS_NAM,
             T.REP_NUM,
             T.ITEM_NUM,
             T.DATA_DEPARTMENT,
             SUM(TOTAL_VALUE) AS ITEM_VAL
        FROM CBRC_A_REPT_DWD_S7102 T
       GROUP BY T.DATA_DATE, T.ORG_NUM, T.SYS_NAM, T.REP_NUM, T.ITEM_NUM,T.DATA_DEPARTMENT;
    COMMIT;

    --============================================end======================

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
   
END proc_cbrc_idx2_s7102;
