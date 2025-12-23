CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s47(II_DATADATE  IN STRING --跑批日期
                                                 )
/******************************
  @description:S47新型农村金融机构经营情况统计表
  @modification history:
  m0-ZJM-20231025-村镇特色报表
  --[JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]

目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_A_REPT_ITEM_VAL_S47
     CBRC_S47_BAL_TMP
视图表：SMTMODS_V_PUB_IDX_DK_YSDQRJJ
集市表：SMTMODS_L_ACCT_DEPOSIT
     SMTMODS_L_ACCT_LOAN
     SMTMODS_L_ACCT_LOAN_FARMING
     SMTMODS_L_ACCT_LOAN_REALESTATE
     SMTMODS_L_CUST_ALL
     SMTMODS_L_CUST_C
     SMTMODS_L_CUST_P
     SMTMODS_L_FINA_GL
     SMTMODS_L_PUBL_RATE
     SMTMODS_L_TRAN_TX



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
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  V_PER_NUM      VARCHAR(30); --报表编号
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    V_PER_NUM      := 'S47';
    V_TAB_NAME     := 'CBRC_A_REPT_ITEM_VAL';
    I_DATADATE     := II_DATADATE;
    V_SYSTEM       := 'CBRC';
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_S47');
    D_DATADATE_CCY := I_DATADATE;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
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



    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S47_BAL_TMP';
    INSERT INTO CBRC_S47_BAL_TMP
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
       CUST_TYP, --24客户大类
       REGION_CD, --25客户所在地区
       CORP_HOLD_TYPE, --26控股方式
       ACCT_TYP, --27贷款产品类别
       PROPERTYLOAN_TYP, --28房地产贷款产品类别
       DRAWDOWN_AMT, --29放款金额
       REAL_INT_RAT --30实际利率
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
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
          THEN
          COALESCE(P.OPERATE_CUST_TYPE, C.CUST_TYP) --个体工商户：一部分在对私:A、一部分在对公:3  tanglei20220406
       END AS OPERATE_CUST_TYPE, --14经营性客户类型
       P.DEFORMITY_FLG, --15残疾人标志
       T.LOAN_GRADE_CD, --16五级分类
       T.GUARANTY_TYP, --17贷款担保方式
       T.LOAN_KIND_CD, --18贷款形式
       CASE
         WHEN F.LOAN_NUM IS NOT NULL THEN
          'Y'
         ELSE
          'N'
       END AS AGREI_P_FLG, --19涉农标志
       F.COOP_LAON_FLAG, --20农民合作社贷款标志
       F.RUR_COLL_ECO_ORG_LOAN_FLG, --21农村集体经济组织贷款标志
       T.CUST_ID, --22客户号
       A.CUST_NAM, --23客户名称
       CASE
         WHEN P.CUST_ID IS NOT NULL THEN
          '2'
         ELSE
          '1'
       END, --24客户大类
       COALESCE(P.REGION_CD, P.ORG_AREA, C.REGION_CD, C.ORG_AREA), --25客户所属地区
       C.CORP_HOLD_TYPE, --控股方式
       T.acct_typ, --贷款产品类别
       G.PROPERTYLOAN_TYP, --房地产类别
       T.DRAWDOWN_AMT, --放款金额
       T.REAL_INT_RAT --实际利率
        FROM --SMTMODS_L_ACCT_LOAN T --贷款借据信息表
             SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
          ON T.DATA_DATE = P.DATA_DATE
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
        LEFT JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_CUST_ALL A --客户表 取农民专业合作社
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE G --房地产补充
          ON T.loan_num = G.LOAN_NUM
         AND G.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(T.ORG_NUM, 1, 1) IN ('5', '6')
         AND T.LOAN_ACCT_BAL <> 0 --贷款余额
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
            
         AND T.CANCEL_FLG <> 'Y' --剔除 核销状态=‘Y’
     AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250228 JLBA202408200012 资产未转让
      ;

    COMMIT;

    --5.实收注册资本
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_5..A' AS ITEM_NUM,
             A.CREDIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '4001'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --7.1.各项存款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_7.1.A' AS ITEM_NUM,
             A.CREDIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('201101', '201102','201103','224101','200801','200901')--[JLBA202507210012][石雨][修改内容：224101久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

---累放当月
   DELETE FROM CBRC_A_REPT_ITEM_VAL_S47
     WHERE DATA_DATE = I_DATADATE
       AND ITEM_NUM IN ( 'S47_1_7.2.A');
    COMMIT;


     INSERT INTO CBRC_A_REPT_ITEM_VAL_S47
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_7.2.A' AS ITEM_NUM,
             COUNT(1) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_TRAN_TX A
       WHERE A.DATA_DATE >= SUBSTR(I_DATADATE,1,6)||'01' AND A.DATA_DATE <= I_DATADATE
         AND A.GL_ITEM_CODE LIKE '2011%'
         AND CD_TYPE= '2'
         AND SUMMARY NOT LIKE '%手续费%'
         AND SUMMARY NOT LIKE '%结息%'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         GROUP BY A.ORG_NUM;
    COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_7.3.A' AS ITEM_NUM,
             COUNT(DISTINCT ACCT_NUM) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_DEPOSIT A
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND (A.ACCT_TYPE <> '0602' OR A.ACCT_TYPE IS NULL)
         AND a.gl_item_code like '2011%'
         AND TO_CHAR(ACCT_OPDATE,'YYYYMM') = SUBSTR(I_DATADATE,1,6)
         GROUP BY A.ORG_NUM;
    COMMIT;


     INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
       SELECT
             I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_7.2.A' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
       FROM CBRC_A_REPT_ITEM_VAL_S47
     WHERE  ITEM_NUM IN ( 'S47_1_7.2.A')
       AND DATA_DATE<=I_DATADATE
       GROUP BY ORG_NUM;

      COMMIT;


    --7.4.法定存款准备金余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_7.4.A' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('100301')
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    -- 8.1.1.其中100万元以下贷款余额（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.1.1.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
               GROUP BY A.ORG_NUM, A.CUST_ID
              HAVING SUM(A.LOAN_ACCT_BAL) <= 1000000) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --    8.1.2.其中500万元以下贷款余额（包含100万元以下贷款）（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.1.2.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
               GROUP BY A.ORG_NUM, A.CUST_ID
              HAVING SUM(A.LOAN_ACCT_BAL) <= 5000000) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    -- 8.2.贷款户数（户）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.2.A' AS ITEM_NUM,
             COUNT(DISTINCT A.CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --贷款信息临时表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.LOAN_ACCT_BAL > 0
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.3.成立以来贷款累计发生金额（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.3.A'  AS ITEM_NUM,
             SUM(DRAWDOWN_AMT) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A --贷款借据信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.4.成立以来累计贷款笔数（笔）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.4.A' AS ITEM_NUM,
             COUNT(1) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A --贷款借据信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.5.成立以来累计贷款户数（户）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.5.A' AS ITEM_NUM,
             COUNT(DISTINCT CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A --贷款借据信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.6.成立以来累计首放贷款金额（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.6.A' AS ITEM_NUM,
             SUM(DRAWDOWN_AMT) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A --贷款借据信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND IS_FIRST_LOAN_TAG = 'Y'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.7.成立以来累计首放贷款笔数（笔）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.7.A' AS ITEM_NUM,
             COUNT(1) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A --贷款借据信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND IS_FIRST_LOAN_TAG = 'Y'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.8.成立以来累计首放贷款户数（户）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.8.A' AS ITEM_NUM,
             COUNT(DISTINCT CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A --贷款借据信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND IS_FIRST_LOAN_TAG = 'Y'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.9.1.1.其中100万元以下小微企业贷款余额（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.9.1.1.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND (A.CORP_SCALE IN ('S', 'T') OR
                     A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))
               GROUP BY A.ORG_NUM, A.CUST_ID
              HAVING SUM(A.LOAN_ACCT_BAL) <= 1000000) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --8.9.1.2.其中500万元以下小微企业贷款余额（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.9.1.2.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND (A.CORP_SCALE IN ('S', 'T') OR
                     A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))
               GROUP BY A.ORG_NUM, A.CUST_ID
              HAVING SUM(A.LOAN_ACCT_BAL) <= 5000000) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --8.9.1.3.其中小微型企业不良贷款余额（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.9.1.3.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND (A.CORP_SCALE IN ('S', 'T') OR
                     A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))
                 AND A.LOAN_GRADE_CD IN ('3', '4', '5')
               GROUP BY A.ORG_NUM, A.CUST_ID
              --HAVING SUM(A.LOAN_ACCT_BAL) <= 5000000
              ) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --  8.9.2.小微企业贷款户数（户）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.9.2.A' AS ITEM_NUM,
             COUNT(DISTINCT A.CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --贷款信息临时表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND (A.CORP_SCALE IN ('S', 'T') OR
             A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))
         AND A.LOAN_ACCT_BAL > 0
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    -- 8.9.2.1.其中100万元以下小微企业贷款户数（户）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(C.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.9.2.1.A' AS ITEM_NUM,
             COUNT(DISTINCT C.CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND (A.CORP_SCALE IN ('S', 'T') OR
                     A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))
               GROUP BY A.ORG_NUM, A.CUST_ID
              HAVING SUM(A.LOAN_ACCT_BAL) <= 1000000) C
       GROUP BY SUBSTR(C.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.9.2.2.其中500万元以下小微企业贷款户数（户）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(C.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.9.2.2.A' AS ITEM_NUM,
             COUNT(DISTINCT C.CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND (A.CORP_SCALE IN ('S', 'T') OR
                     A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))
               GROUP BY A.ORG_NUM, A.CUST_ID
              HAVING SUM(A.LOAN_ACCT_BAL) <= 5000000) C
       GROUP BY SUBSTR(C.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.9.2.3.其中小微型企业不良贷款户数（户）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.9.2.3.A' AS ITEM_NUM,
             COUNT(DISTINCT A.CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --贷款信息临时表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND (A.CORP_SCALE IN ('S', 'T') OR
             A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.9.3.成立以来小微企业贷款累计发生金额（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.9.3.A' AS ITEM_NUM,
             SUM(A.DRAWDOWN_AMT) AS ITEM_VAL,
             '2' AS FLAG
             FROM CBRC_S47_BAL_TMP A --贷款信息
             WHERE A.DATA_DATE = I_DATADATE
               AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
               AND (A.CORP_SCALE IN ('S', 'T') OR
                     A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.9.4.成立以来小微企业贷款累计发生笔数（笔）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.9.4.A' AS ITEM_NUM,
             COUNT(1) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --贷款信息临时表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND (A.CORP_SCALE IN ('S', 'T') OR
             A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.9.5.成立以来小微企业贷款累计发放户数（户）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.9.5.A' AS ITEM_NUM,
             COUNT(DISTINCT A.CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --贷款信息临时表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND (A.CORP_SCALE IN ('S', 'T') OR
             A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.9.6.当年累计发放小微企业贷款额（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(C.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.9.6.A' AS ITEM_NUM,
             SUM(DRAWDOWN_AMT) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.DRAWDOWN_AMT
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND (A.CORP_SCALE IN ('S', 'T') OR
                     A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))
                 AND SUBSTR(A.DRAWDOWN_DT,1,8) >= SUBSTR(I_DATADATE, 1,4) || '0001') C
       GROUP BY SUBSTR(C.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.9.7.当年累计发放小微企业贷款年化利息收入（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.9.7.A' AS ITEM_NUM,
             SUM(DRAWDOWN_AMT * REAL_INT_RAT / 100) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --贷款信息
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND (A.CORP_SCALE IN ('S', 'T') OR
             A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))
         AND SUBSTR(A.DRAWDOWN_DT,1,8) >= SUBSTR(I_DATADATE, 1,4) || '0001'
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.10.1.农户贷款余额（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.1.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --个人涉农贷款
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.AGREI_P_FLG = 'Y'
                 AND A.CUST_TYP = '2') C
       GROUP BY C.ORG_NUM;
    COMMIT;

    -- 8.10.1.1.其中100万元以下农户贷款余额（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.1.1.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --个人涉农贷款
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.AGREI_P_FLG = 'Y'
                 AND A.CUST_TYP = '2'
               GROUP BY A.ORG_NUM, A.CUST_ID
              HAVING SUM(A.LOAN_ACCT_BAL) <= 1000000) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    -- 8.10.1.2.其中500万元以下农户贷款余额（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.1.2.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --个人涉农贷款
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.AGREI_P_FLG = 'Y'
                 AND A.CUST_TYP = '2'
               GROUP BY A.ORG_NUM, A.CUST_ID
              HAVING SUM(A.LOAN_ACCT_BAL) <= 5000000) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    -- 8.10.1.3.其中农户贷款不良贷款余额（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.1.3.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --个人涉农贷款
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.AGREI_P_FLG = 'Y'
                 AND A.CUST_TYP = '2'
                 AND A.LOAN_GRADE_CD IN ('3', '4', '5')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    -- 8.10.1.4.其中农户个体工商户和农户小微企业主贷款余额（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.1.4.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --个人涉农贷款
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.AGREI_P_FLG = 'Y'
                 AND A.OPERATE_CUST_TYPE IN ('A', 'B', '3')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --8.10.2.农户贷款户数（户）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.2.A' AS ITEM_NUM,
             COUNT(DISTINCT A.CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --贷款信息临时表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.AGREI_P_FLG = 'Y'
         AND A.CUST_TYP = '2'
         AND A.LOAN_ACCT_BAL > 0
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.10.2.1.其中100万元以下农户贷款户数（户）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(C.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.2.1.A' AS ITEM_NUM,
             COUNT(DISTINCT C.CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.AGREI_P_FLG = 'Y'
                 AND A.CUST_TYP = '2'
               GROUP BY A.ORG_NUM, A.CUST_ID
              HAVING SUM(A.LOAN_ACCT_BAL) <= 1000000) C
       GROUP BY SUBSTR(C.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.10.2.2.其中500万元以下农户贷款户数（户）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(C.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.2.2.A' AS ITEM_NUM,
             COUNT(DISTINCT C.CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.AGREI_P_FLG = 'Y'
                 AND A.CUST_TYP = '2'
               GROUP BY A.ORG_NUM, A.CUST_ID
              HAVING SUM(A.LOAN_ACCT_BAL) <= 5000000) C
       GROUP BY SUBSTR(C.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.10.2.3.其中农户贷款不良贷款户数（户）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(C.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.2.3.A' AS ITEM_NUM,
             COUNT(DISTINCT C.CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.AGREI_P_FLG = 'Y'
                 AND A.CUST_TYP = '2'
                 AND A.LOAN_GRADE_CD IN ('3', '4', '5')) C
       GROUP BY SUBSTR(C.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.10.2.4.其中农户个体工商户和农户小微企业主贷款户数（户）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(C.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.2.4.A' AS ITEM_NUM,
             COUNT(DISTINCT C.CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.AGREI_P_FLG = 'Y'
                 AND A.OPERATE_CUST_TYPE IN ('A', 'B', '3')) C
       GROUP BY SUBSTR(C.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    --8.10.3.成立以来农户贷款累计发生金额（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.3.A' AS ITEM_NUM,
             SUM(A.DRAWDOWN_AMT) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --个人涉农贷款
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.AGREI_P_FLG = 'Y' --涉农标志为是
         AND A.CUST_TYP = '2' --对私客户号不为空
       GROUP BY A.ORG_NUM;
    COMMIT;

    --8.10.3.1其中农户个体工商户和农户小微企业主贷款累计发生金额（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.3.1.A' AS ITEM_NUM,
             SUM(A.DRAWDOWN_AMT) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --个人涉农贷款
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.AGREI_P_FLG = 'Y'
         AND A.OPERATE_CUST_TYPE IN ('A', 'B', '3')
       GROUP BY A.ORG_NUM;
    COMMIT;

    --8.10.4.成立以来农户贷款累计发生笔数（笔）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.4.A' AS ITEM_NUM,
             COUNT(1) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --个人涉农贷款
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.AGREI_P_FLG = 'Y' --涉农标志为是
         AND A.CUST_TYP = '2' --对私客户号不为空
       GROUP BY A.ORG_NUM;
    COMMIT;

    --8.10.4.1其中农户个体工商户和农户小微企业主贷款累计发生笔数（笔）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.4.1.A' AS ITEM_NUM,
             COUNT(1) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --个人涉农贷款
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.AGREI_P_FLG = 'Y'
         AND A.OPERATE_CUST_TYPE IN ('A', 'B', '3')
       GROUP BY A.ORG_NUM;
    COMMIT;

    --8.10.5.成立以来农户贷款累计发放户数（户）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.5.A' AS ITEM_NUM,
             COUNT(DISTINCT CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --个人涉农贷款
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.AGREI_P_FLG = 'Y' --涉农标志为是
         AND A.CUST_TYP = '2' --对私客户号不为空
       GROUP BY A.ORG_NUM;
    COMMIT;

    --8.10.5.1其中农户个体工商户和农户小微企业主贷款累计发放户数（户）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.10.5.1.A' AS ITEM_NUM,
             COUNT(DISTINCT CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --个人涉农贷款
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.AGREI_P_FLG = 'Y' --涉农标志为是
         AND A.CUST_TYP = '2' --对私客户号不为空
       GROUP BY A.ORG_NUM;
    COMMIT;

    --   8.11.当地贷款    --地区代码调整参考村镇银行机构信息表，县镇\市\省
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.11..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '321%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '130%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '131%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '222%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --    8.11.1.当地小微企业贷款（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.11.1..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                      CASE
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '321%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '130%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '131%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '222%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND (A.CORP_SCALE IN ('S', 'T') OR
                     A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --      8.11.2.当地涉农贷款（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.11.2..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                      CASE
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '321%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '130%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '131%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '222%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.AGREI_P_FLG = 'Y') C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --  8.11.3.当地私人控股企业贷款（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.11.3..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                      CASE
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '321%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '130%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '131%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '222%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.CORP_HOLD_TYPE LIKE 'C%') C
       GROUP BY C.ORG_NUM;
    COMMIT;

    -- 8.11.4.当地个人经营性贷款（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.11.4..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                      CASE
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '321%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '130%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '131%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '222%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN ( A.REGION_CD LIKE '220%' OR A.REGION_CD IS NULL) AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND (A.ACCT_TYP LIKE '0102%' OR
                     A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))) C
       GROUP BY C.ORG_NUM;
    COMMIT;


    --   8.12.异地贷款    --地区代码调整参考村镇银行机构信息表，县镇\市\省
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.12..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '321%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '130%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '131%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '222%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --    8.12.1.异地小微企业贷款（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.12.1..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                      CASE
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '321%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '130%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '131%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '222%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND (A.CORP_SCALE IN ('S', 'T') OR
                     A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --      8.12.2.异地涉农贷款（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.12.2..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                      CASE
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '321%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '130%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '131%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '222%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.AGREI_P_FLG = 'Y') C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --  8.12.3.异地私人控股企业贷款（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_8.12.3..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                      CASE
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '321%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '130%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '131%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '222%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.CORP_HOLD_TYPE LIKE 'C%') C
       GROUP BY C.ORG_NUM;
    COMMIT;

    -- 8.12.4.异地个人经营性贷款（万元） 'S47_1_8.12.4..A' 
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             -- 'S47_1_8.12.3..A' AS ITEM_NUM,
             'S47_1_8.12.4..A' AS ITEM_NUM, --ALTER BY SHIYU 20250929 原程序指标编号写错
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                      CASE
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '321%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '130%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '131%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '222%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN A.REGION_CD NOT LIKE '220%' AND
                            SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND (A.ACCT_TYP LIKE '0102%' OR
                     A.OPERATE_CUST_TYPE IN ('A', 'B', '3'))) C
       GROUP BY C.ORG_NUM;
    COMMIT;


    --  9.1.存放同业款项（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_9.1.A' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1011'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --  9.2.同业存放款项（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_9.2.A' AS ITEM_NUM,
             A.CREDIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '2012'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --11.1.1.不良贷款

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_2_11.1.2.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.AGREI_P_FLG = 'Y'
                 AND A.LOAN_GRADE_CD IN ('3', '4', '5')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --  11.2.信用贷款（万元）  --alter by 石雨 20250929 代码重复，指标统计翻倍 
/*
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_2_11.1.2.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.AGREI_P_FLG = 'Y'
                 AND A.LOAN_GRADE_CD IN ('3', '4', '5')) C
       GROUP BY C.ORG_NUM;
    COMMIT;
    */

    --   11.2.信用贷款（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_2_11.2..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.GUARANTY_TYP = 'D') C
       GROUP BY C.ORG_NUM;
    COMMIT;

    -- 11.2.1.其中农户小额信用贷款（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_2_11.2.1.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.GUARANTY_TYP = 'D'
                 AND A.AGREI_P_FLG = 'Y'
                 AND A.CUST_TYP = '2'
               GROUP BY A.ORG_NUM, A.CUST_ID
              HAVING SUM(A.LOAN_ACCT_BAL) <= 500000) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --11.3.保证贷款（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_2_11.3..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.GUARANTY_TYP LIKE 'C%') C
       GROUP BY C.ORG_NUM;
    COMMIT;

    -- 11.4.抵押贷款（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_2_11.4..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.GUARANTY_TYP LIKE 'B%') C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --11.5.质押贷款（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_2_11.5..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.GUARANTY_TYP = 'A') C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --11.6.票据贴现及转贴现金额（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_5..A' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1301'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --11.8.房地产开发贷款（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_2_11.8..A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.PROPERTYLOAN_TYP LIKE '1%') C
       GROUP BY C.ORG_NUM;
    COMMIT;

    -- 11.8.1 其中：保障房项目贷款（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_2_11.8.1.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.PROPERTYLOAN_TYP IN ('102', '111')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --12.5 自年初其他应付款科目贷方累计发生额（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_2_12.5..A' AS ITEM_NUM,
             SUM(A.CREDIT_D_AMT) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE >= SUBSTR(I_DATADATE,1,4)||'0101' AND A.DATA_DATE <= I_DATADATE
         AND A.ITEM_CD = '2241'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         GROUP BY A.ORG_NUM;
    COMMIT;

    --12.6 自年初存放同业科目借方累计发生额（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_2_12.6..A' AS ITEM_NUM,
             SUM(A.DEBIT_D_AMT) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE >= SUBSTR(I_DATADATE,1,4)||'0101' AND A.DATA_DATE <= I_DATADATE
         AND A.ITEM_CD = '1011'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         GROUP BY A.ORG_NUM;
    COMMIT;

    --12.7 自年初同业存放科目贷方累计发生额（万元）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_2_12.7..A' AS ITEM_NUM,
             SUM(A.CREDIT_D_AMT) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE >= SUBSTR(I_DATADATE,1,4)||'0101' AND A.DATA_DATE <= I_DATADATE
         AND A.ITEM_CD = '2012'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         GROUP BY A.ORG_NUM;
    COMMIT;

    --18.存放同业款项（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_3_18...A' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1011'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --19.同业存放款项（万元）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_3_19...A' AS ITEM_NUM,
             A.CREDIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '2012'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    -- 21.1.3. 信用户户数

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_4_21.1.3..A' AS ITEM_NUM,
             COUNT(DISTINCT A.CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --贷款信息临时表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.CUST_TYP = '2'
         AND A.LOAN_ACCT_BAL > 0
         AND A.GUARANTY_TYP = 'D'
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    -- 21.1.3.1. 有贷款的信用户户数

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             SUBSTR(A.ORG_NUM, 1, 2) || '0000' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_4_21.1.3.1.A' AS ITEM_NUM,
             COUNT(DISTINCT A.CUST_ID) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --贷款信息临时表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.CUST_TYP = '2'
         AND A.LOAN_ACCT_BAL > 0
         AND A.GUARANTY_TYP = 'D'
       GROUP BY SUBSTR(A.ORG_NUM, 1, 2) || '0000';
    COMMIT;

    -- 21.1.3.2. 有贷款的信用户贷款余额

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_4_21.1.3.2.A' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --个人涉农贷款
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.CUST_TYP = '2'
                 AND A.LOAN_ACCT_BAL > 0
                 AND A.GUARANTY_TYP = 'D') C
       GROUP BY C.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID+1;
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
   
END proc_cbrc_idx2_s47