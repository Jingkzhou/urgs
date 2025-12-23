CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s75(II_DATADATE  IN STRING--跑批日期
                                                     )
/******************************
  @author:
  @create-date:2025-07-04
  @description:S75普惠贷款情况表
  @modification history:

  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_REP_NUM      VARCHAR(30); --报表名称
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE     VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  NUM            INTEGER;
  NEXTDATE       VARCHAR2(10);
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  D_DATADATE_CCY STRING;
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE     := II_DATADATE;
    V_DATADATE     := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYYMMDD');
    D_DATADATE_CCY := I_DATADATE;
    V_SYSTEM       := 'CBRC';
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_S75');
    V_REP_NUM      := 'S75';

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_REP_NUM || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    NEXTDATE := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD') + 1, 'YYYYMMDD');

    --begin 明细需求 bohe20250815

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S75';

    --end 明细需求 bohe20250815

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND REP_NUM = V_REP_NUM
       AND SYS_NAM = 'CBRC';
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'S75 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --累放数据

    --年初删除本年累计:

    IF SUBSTR(I_DATADATE, 5, 2) = 01 THEN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S75_LOAN_TEMP';
    ELSE
     
      DELETE FROM CBRC_S75_LOAN_TEMP T WHERE T.DATA_DATE = I_DATADATE;
      COMMIT;

      INSERT INTO CBRC_S75_LOAN_TEMP
        (DATA_DATE,
         ORG_NUM,
         CUST_ID,
         LOAN_ACCT_AMT,
         NHSY,
         LOAN_NUM,
         ITEM_CD,
         UNDERTAK_GUAR_TYPE,
         MATURITY_DT,
         DRAWDOWN_DT,
         GUARANTY_TYP,
         LOAN_KIND_CD,
         CURR_CD,
         FACILITY_AMT,
         ACCT_TYP,
         DEPARTMENTD)
        SELECT 
         I_DATADATE DATA_DATE,
         A.ORG_NUM, --机构号
         A.CUST_ID, --客户号
         A.DRAWDOWN_AMT AS LOAN_ACCT_AMT, --累放金额
         A.DRAWDOWN_AMT * A.REAL_INT_RAT / 100 NHSY, --年化收益
         A.LOAN_NUM, --借据号
         A.ITEM_CD, --科目号
         A.UNDERTAK_GUAR_TYPE, --创业担保贷款类型
         A.MATURITY_DT, --原始到期日期
         A.DRAWDOWN_DT, --放款日期
         A.GUARANTY_TYP, --贷款担保方式
         A.LOAN_KIND_CD, --贷款形式
         A.CURR_CD, --币种
         B.FACILITY_AMT, --授信额度
         A.ACCT_TYP,
         A.DEPARTMENTD --条线
          FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
          LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX B
            ON A.CUST_ID = B.CUST_ID
           AND B.DATA_DATE = TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD')
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
           AND A.CANCEL_FLG <> 'Y'
           AND A.LOAN_STOCKEN_DATE IS NULL -- ADD BY HAORUI 20250228 JLBA202408200012 资产未转让
           AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 刨除票据转贴现
           AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) -- 累放不取贷款重组 SHIYU 20220210  新口径吴大为
           AND (SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = -- 取当月
               SUBSTR(I_DATADATE, 1, 6) OR
               (A.INTERNET_LOAN_FLG = 'Y' AND
               A.DRAWDOWN_DT =
               (TRUNC(DATE(I_DATADATE, 'YYYYMMDD'), 'MM') - 1)) -- MODIFY BY 87V : 互联网贷款数据晚一天下发，上月末数据当月取
               )
           and B.CUST_ID is not null;
      COMMIT;

      DELETE FROM CBRC_S75_LOAN_TEMP_HIS T
       WHERE SUBSTR(T.DATA_DATE, 1, 6) = SUBSTR(I_DATADATE, 1, 6);
      COMMIT;

      INSERT INTO CBRC_S75_LOAN_TEMP_HIS
        (DATA_DATE,
         ORG_NUM,
         CUST_ID,
         LOAN_ACCT_AMT,
         NHSY,
         LOAN_NUM,
         ITEM_CD,
         UNDERTAK_GUAR_TYPE,
         MATURITY_DT,
         DRAWDOWN_DT,
         GUARANTY_TYP,
         LOAN_KIND_CD,
         CURR_CD,
         FACILITY_AMT,
         ACCT_TYP,
         DEPARTMENTD)
        SELECT I_DATADATE DATA_DATE,
               ORG_NUM,
               CUST_ID,
               LOAN_ACCT_AMT,
               NHSY,
               LOAN_NUM,
               ITEM_CD,
               UNDERTAK_GUAR_TYPE,
               MATURITY_DT,
               DRAWDOWN_DT,
               GUARANTY_TYP,
               LOAN_KIND_CD,
               CURR_CD,
               FACILITY_AMT,
               ACCT_TYP,
               DEPARTMENTD
          FROM CBRC_S75_LOAN_TEMP T
         WHERE SUBSTR(T.DATA_DATE, 1, 6) = SUBSTR(I_DATADATE, 1, 6);
      COMMIT;

    END IF;

    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工涉农贷款宽表至CBRC_S75_SNDK_TEMP临时表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S75_SNDK_TEMP';

    ----20250327 新增涉农贷款逻辑

    INSERT INTO CBRC_S75_SNDK_TEMP
      (DATA_DATE,
       LOAN_NUM,
       SNDKFL,
       IF_CT_UA,
       AGR_USE_ADDL,
       COOP_LAON_FLAG,
       RUR_COLL_ECO_ORG_LOAN_FLG)

      SELECT I_DATADATE DATA_DATE,
             F.LOAN_NUM,
             F.SNDKFL,
             F.IF_CT_UA,
             F.AGR_USE_ADDL,
             K.COOP_LAON_FLAG,
             K.RUR_COLL_ECO_ORG_LOAN_FLG
        from (SELECT t.LOAN_NUM, t.SNDKFL, t.IF_CT_UA, t.AGR_USE_ADDL
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
                     A.SNDKFL LIKE 'C_1%' or SUBSTR(A.SNDKFL, 0, 3) = 'C_2' OR
                     ((A.SNDKFL LIKE 'C_402%' or A.SNDKFL LIKE 'C_302%') AND
                     (CASE
                       WHEN SUBSTR(A.SNDKFL, 0, 7) IN ('C_40202', 'C_30202') AND
                            (NVL(A.AGR_USE_ADDL, '#') IN ('05') OR
                             NVL(B.LOAN_PURPOSE_CD, '#') IN
                             ('A0514', 'A0523')) THEN
                        1
                       ELSE
                        0
                     END) = 0))) F
       INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING K
          ON F.LOAN_NUM = K.LOAN_NUM
         AND K.DATA_DATE = I_DATADATE;
    COMMIT;

    ---
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工贷款余额宽表至S75_LOAN_BAL临时表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S75_LOAN_BAL';

    COMMIT;

    INSERT INTO CBRC_S75_LOAN_BAL
      (DATA_DATE,
       ORG_NUM,
       ACCT_NUM,
       LOAN_NUM,
       CUST_ID,
       CUST_NAM,
       FACILITY_AMT,
       DRAWDOWN_DT,
       MATURITY_DT,
       LOAN_ACCT_BAL,
       CORP_SCALE,
       ITEM_CD,
       CUST_TYP,
       OPERATE_CUST_TYPE,
       LOAN_GRADE_CD,
       AGREI_P_FLG,
       SNDKFL,
       CURR_CD,
       ACCT_TYP,
       UNDERTAK_GUAR_TYPE,
       DEPARTMENTD)
      SELECT 
       I_DATADATE AS DATA_DATE, --1数据日期
       T.ORG_NUM AS ORG_NUM, --2机构号
       T.ACCT_NUM AS ACCT_NUM, --3合同号
       T.LOAN_NUM AS LOAN_NUM, --4借据号
       T.CUST_ID AS CUST_ID, --5客户号
       NVL(C.CUST_NAM, P.CUST_NAM) CUST_NAM, --6客户名称
       B.FACILITY_AMT AS FACILITY_AMT, --7授信额度
       T.DRAWDOWN_DT AS DRAWDOWN_DT, --8放款日期
       T.MATURITY_DT AS MATURITY_DT, --9原始到期日
       T.LOAN_ACCT_BAL * TT.CCY_RATE AS LOAN_ACCT_BAL, --10贷款余额
       C.CORP_SCALE AS CORP_SCALE, --11企业规模
       T.ITEM_CD AS ITEM_CD, --12科目号
       C.CUST_TYP AS CUST_TYP, --13客户分类
       CASE
         WHEN (T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
          THEN
          COALESCE(P.OPERATE_CUST_TYPE, C.CUST_TYP) --个体工商户：一部分在对私:A、一部分在对公:3  tanglei20220406
       END AS OPERATE_CUST_TYPE, --14经营性客户类型
       T.LOAN_GRADE_CD, --15五级分类

       CASE
         WHEN F.LOAN_NUM IS NOT NULL THEN
          'Y'
         ELSE
          'N'
       END AS AGREI_P_FLG, --16涉农标志
       F.SNDKFL, --17涉农分类
       T.CURR_CD, --18币种
       T.ACCT_TYP, --19账户类型
       T.UNDERTAK_GUAR_TYPE,
       T.DEPARTMENTD
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
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
        LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX B --授信额度
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL <> 0 --贷款余额
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现
         AND T.CANCEL_FLG <> 'Y' --剔除 核销状态=‘Y’--tanglei20220406
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (
             --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') OR
              C.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              C.CORP_SCALE IN ('S', 'T') AND B.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              B.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND B.FACILITY_AMT <= 5000000 AND
              SUBSTR(F.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')) or
              t.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
             );
    COMMIT;

    -----------------------------------------------------加工指标逻辑-----------------------------------------

    --1.普惠贷款 贷款余额

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.A' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE;
    COMMIT;

    --1.普惠贷款 贷款户数

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益

       )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               'S75' AS REP_NUM,
               'S75_1.B' AS ITEM_NUM,
               T.CUST_ID AS COL_2, --客户号
               C.CUST_NAM AS COL_3, --客户名
               '1' AS TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE;
    COMMIT;

    --1.普惠贷款 不良贷款

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.C' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_GRADE_CD IN ('3', '4', '5');
    COMMIT;

    -- 1.普惠贷款 累放金额

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.D' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
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
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') OR
              C.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              C.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(F.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')) or
              t.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
             );
    COMMIT;

    -- 1.普惠贷款 累放收益

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.E' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
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
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') OR
              C.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              C.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(F.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')) or
              t.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
             );
    COMMIT;

    --1.1普惠重点领域贷款  贷款余额

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.A' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0') OR
              T.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              T.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103'))

             );
    COMMIT;

    --1.1普惠重点领域贷款  贷款户数

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益

       )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               'S75' AS REP_NUM,
               'S75_1.1.B' AS ITEM_NUM,
               T.CUST_ID AS COL_2, --客户号
               C.CUST_NAM AS COL_3, --客户名
               '1' AS TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益

        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0') OR
              T.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              T.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')));
    COMMIT;

    --1.1普惠重点领域贷款  不良贷款

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.C' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0') OR
              T.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              T.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')))
         AND T.LOAN_GRADE_CD IN ('3', '4', '5');
    COMMIT;

    --1.1普惠重点领域贷款 累放金额

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.D' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
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
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') OR
              C.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              C.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(F.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')));
    COMMIT;

    -- --1.1普惠重点领域贷款 累放收益

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.E' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
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
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') OR
              C.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              C.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(F.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')));
    COMMIT;

    --1.1.1单户授信小于1000万元的小微企业贷款  贷款余额
    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.1.A' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0') OR
              T.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              T.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微

             );
    COMMIT;

    --1.1.1单户授信小于1000万元的小微企业贷款  贷款户数
    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益
       )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               'S75' AS REP_NUM,
               'S75_1.1.1.B' AS ITEM_NUM,
               T.CUST_ID AS COL_2, --客户号
               C.CUST_NAM AS COL_3, --客户名
               '1' AS TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0') OR
              T.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              T.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微

             );
    COMMIT;

    --1.1.1单户授信小于1000万元的小微企业贷款  不良贷款
    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.1.C' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0') OR
              T.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              T.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
             )
         AND T.LOAN_GRADE_CD IN ('3', '4', '5');
    COMMIT;

    -- 1.1.1单户授信小于1000万元的小微企业贷款 累放金额

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.1.D' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
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
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') OR
              C.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              C.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微

             );
    COMMIT;

    -- 1.1.1单户授信小于1000万元的小微企业贷款 累放收益

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.1.E' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
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
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') OR
              C.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              C.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微

             );
    COMMIT;

    --1.1.2 1.1.3 贷款余额

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       CASE
         WHEN T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A') THEN
          'S75_1.1.2.A'
         WHEN T.OPERATE_CUST_TYPE IN ('B') THEN
          'S75_1.1.3.A'
       END AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000));
    COMMIT;

    --1.1.2 1.1.3 贷款户数

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益

       )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               'S75' AS REP_NUM,
               CASE
                 WHEN T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A') THEN
                  'S75_1.1.2.B'
                 WHEN T.OPERATE_CUST_TYPE IN ('B') THEN
                  'S75_1.1.3.B'
               END AS ITEM_NUM,
               T.CUST_ID AS COL_2, --客户号
               C.CUST_NAM AS COL_3, --客户名
               '1' AS TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益

        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE

       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000));
    COMMIT;

    --1.1.2 1.1.3  不良贷款

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       CASE
         WHEN T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A') THEN
          'S75_1.1.2.C'
         WHEN T.OPERATE_CUST_TYPE IN ('B') THEN
          'S75_1.1.3.C'
       END AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000))
         AND T.LOAN_GRADE_CD IN ('3', '4', '5');
    COMMIT;

    -- 1.1.2 1.1.3  累放金额

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       CASE
         WHEN C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A') THEN
          'S75_1.1.2.D'
         WHEN P.OPERATE_CUST_TYPE IN ('B') THEN
          'S75_1.1.3.D'
       END AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
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
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000));
    COMMIT;

    -- 1.1.2 1.1.3  累放收益

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       CASE
         WHEN C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A') THEN
          'S75_1.1.2.E'
         WHEN P.OPERATE_CUST_TYPE IN ('B') THEN
          'S75_1.1.3.E'
       END AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
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
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000));
    COMMIT;

    --1.1.4单户授信小于500万元的农户经营性贷款 贷款余额

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.4.A' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
             AND T.FACILITY_AMT <= 5000000 AND
             SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103'));
    COMMIT;

    --1.1.4单户授信小于500万元的农户经营性贷款 贷款户数

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益

       )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               'S75' AS REP_NUM,
               'S75_1.1.4.B' AS ITEM_NUM,
               T.CUST_ID AS COL_2, --客户号
               C.CUST_NAM AS COL_3, --客户名
               '1' AS TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
             AND T.FACILITY_AMT <= 5000000 AND
             SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103'));
    COMMIT;

    --1.1.4单户授信小于500万元的农户经营性贷款  不良贷款

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.4.C' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
             AND T.FACILITY_AMT <= 5000000 AND
             SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103'))
         AND T.LOAN_GRADE_CD IN ('3', '4', '5');
    COMMIT;

    ----1.1.4单户授信小于500万元的农户经营性贷款 累放金额

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.4.D' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE ( --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(F.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')));
    COMMIT;

    ----1.1.4单户授信小于500万元的农户经营性贷款 累放收益

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.4.E' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE ( --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(F.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')));
    COMMIT;

    --1.2创业担保贷款 贷款余额

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.2.A' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B'); --创业担保
    COMMIT;

    --1.2创业担保贷款贷款户数

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益
       )
      SELECT 
      distinct I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               'S75' AS REP_NUM,
               'S75_1.2.B' AS ITEM_NUM,
               T.CUST_ID AS COL_2, --客户号
               C.CUST_NAM AS COL_3, --客户名
               '1' AS TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益

        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B'); --创业担保
    COMMIT;

    --1.2创业担保贷款  不良贷款

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.2.C' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
         AND T.LOAN_GRADE_CD IN ('3', '4', '5');
    COMMIT;

    -- 1.2创业担保贷款  累放金额

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.2.D' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.UNDERTAK_GUAR_TYPE IN ('A', 'B'); --创业担保
    COMMIT;

    -- 1.2创业担保贷款  累放收益

    INSERT INTO CBRC_A_REPT_DWD_S75
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.2.E' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
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
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.UNDERTAK_GUAR_TYPE IN ('A', 'B'); --创业担保
    COMMIT;

    --begin 明细需求 bohe20250815
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       DATA_DEPARTMENT)
      SELECT DATA_DATE, --数据日期
             ORG_NUM, --机构号
             SYS_NAM, --模块简称
             REP_NUM, --报表编号
             ITEM_NUM, --指标号
             SUM(TOTAL_VALUE) AS ITEM_VAL, --指标值
             '2' AS FLAG, --标志位
             DATA_DEPARTMENT
        FROM CBRC_A_REPT_DWD_S75
       WHERE DATA_DATE = I_DATADATE
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, DATA_DEPARTMENT;
    COMMIT;
    --end 明细需求 bohe20250815

    V_STEP_FLAG := V_STEP_ID + 1;
    V_STEP_DESC := 'S75 逻辑处理完成';
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
   
END proc_cbrc_idx2_s75