CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g0901(II_DATADATE  IN string --跑批日期
                                                                 )
/******************************
  @AUTHOR:87V
  @CREATE-DATE:20230625
  @DESCRIPTION:G09_I 商业银行互联网贷款基本情况表
  @MODIFICATION HISTORY:
   m1.20241224 shiyu  修改内容：修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
                             如果是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款在逾期时间90天以内的取逾期部分，逾期90天以上的取贷款余额

目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_G0901_DATA_COLLECT_TMP
集市表：SMTMODS_L_ACCT_INTERNET_LOAN
     SMTMODS_L_ACCT_LOAN
     SMTMODS_L_CUST_ALL
     SMTMODS_L_CUST_C
     SMTMODS_L_CUST_COOP_AGEN
     SMTMODS_L_CUST_P
     SMTMODS_L_PUBL_RATE
     SMTMODS_L_REC_CUST_INTERNET_LOAN
     SMTMODS_L_TRAN_LOAN_PAYM

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
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30); 
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE  := II_DATADATE;
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G0901');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME     := 'CBRC_A_REPT_ITEM_VAL';
    D_DATADATE_CCY := I_DATADATE;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']G0901当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    D_DATADATE_CCY := I_DATADATE;

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G0901_DATA_COLLECT_TMP';

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G0901'
       AND T.FLAG = '2';
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    
     ----------------------------------------------互联网贷款余额--------------------------------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取互联网贷款余额数据至G0901_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ----------------互联网贷款余额:按贷款五级分类--------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          (CASE
            WHEN A.LOAN_GRADE_CD = '1' THEN
             'G09_I_1.1.1.A'
            WHEN A.LOAN_GRADE_CD = '2' THEN
             'G09_I_1.1.2.A'
            WHEN A.LOAN_GRADE_CD = '3' THEN
             'G09_I_1.1.3.A'
            WHEN A.LOAN_GRADE_CD = '4' THEN
             'G09_I_1.1.4.A'
            WHEN A.LOAN_GRADE_CD = '5' THEN
             'G09_I_1.1.5.A'
          END)
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          (CASE
            WHEN A.LOAN_GRADE_CD = '1' THEN
             'G09_I_1.1.1.B'
            WHEN A.LOAN_GRADE_CD = '2' THEN
             'G09_I_1.1.2.B'
            WHEN A.LOAN_GRADE_CD = '3' THEN
             'G09_I_1.1.3.B'
            WHEN A.LOAN_GRADE_CD = '4' THEN
             'G09_I_1.1.4.B'
            WHEN A.LOAN_GRADE_CD = '5' THEN
             'G09_I_1.1.5.B'
          END)
         WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
          (CASE
            WHEN A.LOAN_GRADE_CD = '1' THEN
             'G09_I_1.1.1.C'
            WHEN A.LOAN_GRADE_CD = '2' THEN
             'G09_I_1.1.2.C'
            WHEN A.LOAN_GRADE_CD = '3' THEN
             'G09_I_1.1.3.C'
            WHEN A.LOAN_GRADE_CD = '4' THEN
             'G09_I_1.1.4.C'
            WHEN A.LOAN_GRADE_CD = '5' THEN
             'G09_I_1.1.5.C'
          END)
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN T --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN A --贷款借据信息表
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --五级分类
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   (CASE
                     WHEN A.LOAN_GRADE_CD = '1' THEN
                      'G09_I_1.1.1.A'
                     WHEN A.LOAN_GRADE_CD = '2' THEN
                      'G09_I_1.1.2.A'
                     WHEN A.LOAN_GRADE_CD = '3' THEN
                      'G09_I_1.1.3.A'
                     WHEN A.LOAN_GRADE_CD = '4' THEN
                      'G09_I_1.1.4.A'
                     WHEN A.LOAN_GRADE_CD = '5' THEN
                      'G09_I_1.1.5.A'
                   END)
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   (CASE
                     WHEN A.LOAN_GRADE_CD = '1' THEN
                      'G09_I_1.1.1.B'
                     WHEN A.LOAN_GRADE_CD = '2' THEN
                      'G09_I_1.1.2.B'
                     WHEN A.LOAN_GRADE_CD = '3' THEN
                      'G09_I_1.1.3.B'
                     WHEN A.LOAN_GRADE_CD = '4' THEN
                      'G09_I_1.1.4.B'
                     WHEN A.LOAN_GRADE_CD = '5' THEN
                      'G09_I_1.1.5.B'
                   END)
                  WHEN A.ACCT_TYP = '0202' THEN
                   (CASE
                     WHEN A.LOAN_GRADE_CD = '1' THEN
                      'G09_I_1.1.1.C'
                     WHEN A.LOAN_GRADE_CD = '2' THEN
                      'G09_I_1.1.2.C'
                     WHEN A.LOAN_GRADE_CD = '3' THEN
                      'G09_I_1.1.3.C'
                     WHEN A.LOAN_GRADE_CD = '4' THEN
                      'G09_I_1.1.4.C'
                     WHEN A.LOAN_GRADE_CD = '5' THEN
                      'G09_I_1.1.5.C'
                   END)
                END;
    COMMIT;

    ----------------互联网贷款余额:按按逾期情况--------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          (CASE
            WHEN A.OD_FLG = 'N' THEN
             'G09_I_1.2.1.A'
            WHEN A.OD_DAYS BETWEEN 1 AND 30 THEN
             'G09_I_1.2.2.A'
            WHEN A.OD_DAYS BETWEEN 31 AND 60 THEN
             'G09_I_1.2.3.A'
            WHEN A.OD_DAYS BETWEEN 61 AND 90 THEN
             'G09_I_1.2.4.A'
            WHEN A.OD_DAYS BETWEEN 91 AND 360 THEN
             'G09_I_1.2.5.A'
            WHEN A.OD_DAYS > 360 THEN
             'G09_I_1.2.6.A'
          END)
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          (CASE
            WHEN A.OD_FLG = 'N' THEN
             'G09_I_1.2.1.B'
            WHEN A.OD_DAYS BETWEEN 1 AND 30 THEN
             'G09_I_1.2.2.B'
            WHEN A.OD_DAYS BETWEEN 31 AND 60 THEN
             'G09_I_1.2.3.B'
            WHEN A.OD_DAYS BETWEEN 61 AND 90 THEN
             'G09_I_1.2.4.B'
            WHEN A.OD_DAYS BETWEEN 91 AND 360 THEN
             'G09_I_1.2.5.B'
            WHEN A.OD_DAYS > 360 THEN
             'G09_I_1.2.6.B'
          END)
         WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
          (CASE
            WHEN A.OD_FLG = 'N' THEN
             'G09_I_1.2.1.C'
            WHEN A.OD_DAYS BETWEEN 1 AND 30 THEN
             'G09_I_1.2.2.C'
            WHEN A.OD_DAYS BETWEEN 31 AND 60 THEN
             'G09_I_1.2.3.C'
            WHEN A.OD_DAYS BETWEEN 61 AND 90 THEN
             'G09_I_1.2.4.C'
            WHEN A.OD_DAYS BETWEEN 91 AND 360 THEN
             'G09_I_1.2.5.C'
            WHEN A.OD_DAYS > 360 THEN
             'G09_I_1.2.6.C'
          END)
       END AS ITEM_NUM,
       /*alter by shiyu 20241105 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
            如果是按月分期还款的个人消费贷款本金或利息逾期 */
       SUM(CASE WHEN A.ACCT_TYP LIKE '0103%' AND A.OD_DAYS <=90 AND a.REPAY_TYP ='1' and  a.PAY_TYPE in   ('01','02','10','11')--JLBA202412040012
       THEN  A.OD_LOAN_ACCT_BAL * U.CCY_RATE
        ELSE A.LOAN_ACCT_BAL * U.CCY_RATE END)AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN T --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN A --贷款借据信息表
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   (CASE
                     WHEN A.OD_FLG = 'N' THEN
                      'G09_I_1.2.1.A'
                     WHEN A.OD_DAYS BETWEEN 1 AND 30 THEN
                      'G09_I_1.2.2.A'
                     WHEN A.OD_DAYS BETWEEN 31 AND 60 THEN
                      'G09_I_1.2.3.A'
                     WHEN A.OD_DAYS BETWEEN 61 AND 90 THEN
                      'G09_I_1.2.4.A'
                     WHEN A.OD_DAYS BETWEEN 91 AND 360 THEN
                      'G09_I_1.2.5.A'
                     WHEN A.OD_DAYS > 360 THEN
                      'G09_I_1.2.6.A'
                   END)
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   (CASE
                     WHEN A.OD_FLG = 'N' THEN
                      'G09_I_1.2.1.B'
                     WHEN A.OD_DAYS BETWEEN 1 AND 30 THEN
                      'G09_I_1.2.2.B'
                     WHEN A.OD_DAYS BETWEEN 31 AND 60 THEN
                      'G09_I_1.2.3.B'
                     WHEN A.OD_DAYS BETWEEN 61 AND 90 THEN
                      'G09_I_1.2.4.B'
                     WHEN A.OD_DAYS BETWEEN 91 AND 360 THEN
                      'G09_I_1.2.5.B'
                     WHEN A.OD_DAYS > 360 THEN
                      'G09_I_1.2.6.B'
                   END)
                  WHEN A.ACCT_TYP = '0202' THEN
                   (CASE
                     WHEN A.OD_FLG = 'N' THEN
                      'G09_I_1.2.1.C'
                     WHEN A.OD_DAYS BETWEEN 1 AND 30 THEN
                      'G09_I_1.2.2.C'
                     WHEN A.OD_DAYS BETWEEN 31 AND 60 THEN
                      'G09_I_1.2.3.C'
                     WHEN A.OD_DAYS BETWEEN 61 AND 90 THEN
                      'G09_I_1.2.4.C'
                     WHEN A.OD_DAYS BETWEEN 91 AND 360 THEN
                      'G09_I_1.2.5.C'
                     WHEN A.OD_DAYS > 360 THEN
                      'G09_I_1.2.6.C'
                   END)
                END;
    COMMIT;

    ----------------互联网贷款余额:按担保方式--------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          (CASE
            WHEN A.GUARANTY_TYP = 'D' THEN
             'G09_I_1.3.1.A' --信用贷款
            WHEN A.GUARANTY_TYP LIKE 'C%' THEN
             'G09_I_1.3.2.A' --保证贷款
            WHEN SUBSTR(A.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
             'G09_I_1.3.3.A' --抵押贷款
          END)
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          (CASE
            WHEN A.GUARANTY_TYP = 'D' THEN
             'G09_I_1.3.1.B' --信用贷款
            WHEN A.GUARANTY_TYP LIKE 'C%' THEN
             'G09_I_1.3.2.B' --保证贷款
            WHEN SUBSTR(A.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
             'G09_I_1.3.3.B' --抵押贷款
          END)
         WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
          (CASE
            WHEN A.GUARANTY_TYP = 'D' THEN
             'G09_I_1.3.1.C' --信用贷款
            WHEN A.GUARANTY_TYP LIKE 'C%' THEN
             'G09_I_1.3.2.C' --保证贷款
            WHEN SUBSTR(A.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
             'G09_I_1.3.3.C' --抵押贷款
          END)
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN T --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN A --贷款借据信息表
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   (CASE
                     WHEN A.GUARANTY_TYP = 'D' THEN
                      'G09_I_1.3.1.A' --信用贷款
                     WHEN A.GUARANTY_TYP LIKE 'C%' THEN
                      'G09_I_1.3.2.A' --保证贷款
                     WHEN SUBSTR(A.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                      'G09_I_1.3.3.A' --抵押贷款
                   END)
                  WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   (CASE
                     WHEN A.GUARANTY_TYP = 'D' THEN
                      'G09_I_1.3.1.B' --信用贷款
                     WHEN A.GUARANTY_TYP LIKE 'C%' THEN
                      'G09_I_1.3.2.B' --保证贷款
                     WHEN SUBSTR(A.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                      'G09_I_1.3.3.B' --抵押贷款
                   END)
                  WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
                   (CASE
                     WHEN A.GUARANTY_TYP = 'D' THEN
                      'G09_I_1.3.1.C' --信用贷款
                     WHEN A.GUARANTY_TYP LIKE 'C%' THEN
                      'G09_I_1.3.2.C' --保证贷款
                     WHEN SUBSTR(A.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                      'G09_I_1.3.3.C' --抵押贷款
                   END)
                END;
    COMMIT;

    ----------------互联网贷款余额:按贷款合同期限--------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          (CASE
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 6 THEN
             'G09_I_1.4.1.A'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 6 AND
                 MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 12 THEN
             'G09_I_1.4.2.A'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 12 AND
                 MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 36 THEN
             'G09_I_1.4.3.A'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 36 THEN
             'G09_I_1.4.4.A'
          END)
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          (CASE
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 6 THEN
             'G09_I_1.4.1.B'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 6 AND
                 MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 12 THEN
             'G09_I_1.4.2.B'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 12 AND
                 MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 36 THEN
             'G09_I_1.4.3.B'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 36 THEN
             'G09_I_1.4.4.B'
          END)
         WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
          (CASE
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 6 THEN
             'G09_I_1.4.1.C'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 6 AND
                 MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 12 THEN
             'G09_I_1.4.2.C'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 12 AND
                 MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 36 THEN
             'G09_I_1.4.3.C'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 36 THEN
             'G09_I_1.4.4.C'
          END)
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN T --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN A --贷款借据信息表
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   (CASE
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 6 THEN
                      'G09_I_1.4.1.A'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 6 AND
                          MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 12 THEN
                      'G09_I_1.4.2.A'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 12 AND
                          MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 36 THEN
                      'G09_I_1.4.3.A'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 36 THEN
                      'G09_I_1.4.4.A'
                   END)
                  WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   (CASE
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 6 THEN
                      'G09_I_1.4.1.B'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 6 AND
                          MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 12 THEN
                      'G09_I_1.4.2.B'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 12 AND
                          MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 36 THEN
                      'G09_I_1.4.3.B'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 36 THEN
                      'G09_I_1.4.4.B'
                   END)
                  WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
                   (CASE
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 6 THEN
                      'G09_I_1.4.1.C'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 6 AND
                          MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 12 THEN
                      'G09_I_1.4.2.C'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 12 AND
                          MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 36 THEN
                      'G09_I_1.4.3.C'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 36 THEN
                      'G09_I_1.4.4.C'
                   END)
                END;
    COMMIT;

    ----------------互联网贷款余额:按借款人年龄--------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          (CASE
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND --101  第一代身份证 102  第二代身份证
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 25) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 25) THEN
             'G09_I_1.5.1.A'
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 35) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 35) THEN
             'G09_I_1.5.2.A'
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 45) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 45) THEN
             'G09_I_1.5.3.A'
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 55) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 55) THEN
             'G09_I_1.5.4.A'
            ELSE
             'G09_I_1.5.5.A'
          END)
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          (CASE
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND --101  第一代身份证 102  第二代身份证
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 25) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 25) THEN
             'G09_I_1.5.1.B'
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 35) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 35) THEN
             'G09_I_1.5.2.B'
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 45) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 45) THEN
             'G09_I_1.5.3.B'
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 55) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 55) THEN
             'G09_I_1.5.4.B'
            ELSE
             'G09_I_1.5.5.B'
          END)
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN T --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN A --贷款借据信息表
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%') --个人经营性贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   (CASE
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND --101  第一代身份证 102  第二代身份证
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 25) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 25) THEN
                      'G09_I_1.5.1.A'
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 35) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 35) THEN
                      'G09_I_1.5.2.A'
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 45) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 45) THEN
                      'G09_I_1.5.3.A'
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 55) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 55) THEN
                      'G09_I_1.5.4.A'
                     ELSE
                      'G09_I_1.5.5.A'
                   END)
                  WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   (CASE
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND --101  第一代身份证 102  第二代身份证
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 25) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 25) THEN
                      'G09_I_1.5.1.B'
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 35) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 35) THEN
                      'G09_I_1.5.2.B'
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 45) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 45) THEN
                      'G09_I_1.5.3.B'
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 55) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 55) THEN
                      'G09_I_1.5.4.B'
                     ELSE
                      'G09_I_1.5.5.B'
                   END)
                END;
    COMMIT;

    ---其他情况：1.6.1采用自主支付方式发放的贷款余额-------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN
          'G09_I_1.6.1.A' --个人消费贷款
         WHEN A.ACCT_TYP LIKE '0102%' THEN
          'G09_I_1.6.1.B' --个人经营性贷款
         WHEN A.ACCT_TYP = '0202' THEN
          'G09_I_1.6.1.C' --流动资金贷款
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.DRAWDOWN_TYPE = 'A' --放款方式：自主支付
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_1.6.1.A' --个人消费贷款
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_1.6.1.B' --个人经营性贷款
                  WHEN A.ACCT_TYP = '0202' THEN
                   'G09_I_1.6.1.C' --流动资金贷款
                END;
    COMMIT;

    ---其他情况：1.6.2用于小微企业(包括小型企业、微型企业、个体工商户贷款和小微企业主)的贷款余额-------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    -----------小型企业、微型企业----------------

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0102%' THEN
          'G09_I_1.6.2.B' --个人经营性贷款
         WHEN A.ACCT_TYP = '0202' THEN
          'G09_I_1.6.2.C' --流动资金贷款
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND B.CORP_SCALE IN ('S', 'T') --S小型、T微型企业
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_1.6.2.B' --个人经营性贷款
                  WHEN A.ACCT_TYP = '0202' THEN
                   'G09_I_1.6.2.C' --流动资金贷款
                END;

    COMMIT;

    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    ----------------个体工商户贷款------------------------------

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0102%' THEN
          'G09_I_1.6.2.B' --个人经营性贷款
         WHEN A.ACCT_TYP = '0202' THEN
          'G09_I_1.6.2.C' --流动资金贷款
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND (A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND A.CANCEL_FLG <> 'Y' --未核销
         AND (C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3') --个体工商户
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_1.6.2.B' --个人经营性贷款
                  WHEN A.ACCT_TYP = '0202' THEN
                   'G09_I_1.6.2.C' --流动资金贷款
                END;
    COMMIT;

    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    -----------------小微企业主-----------------------------------

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0102%' THEN
          'G09_I_1.6.2.B' --个人经营性贷款
         WHEN A.ACCT_TYP = '0202' THEN
          'G09_I_1.6.2.C' --流动资金贷款
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND (A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND A.CANCEL_FLG <> 'Y' --未核销
         AND C.OPERATE_CUST_TYPE = 'B'
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_1.6.2.B' --个人经营性贷款
                  WHEN A.ACCT_TYP = '0202' THEN
                   'G09_I_1.6.2.C' --流动资金贷款
                END;
    COMMIT;

    ----------------------------------------------互联网贷款户数--------------------------------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取互联网贷款户数数据至G0901_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ---有贷款余额户数-------------------

    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN
          'G09_I_2..A'
         WHEN A.ACCT_TYP LIKE '0102%' THEN
          'G09_I_2..B'
         WHEN A.ACCT_TYP = '0202' THEN
          'G09_I_2..C'
       END AS ITEM_NUM,
       COUNT(DISTINCT A.CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN SMTMODS_L_CUST_ALL T
          ON T.CUST_ID = A.CUST_ID
         AND T.DATA_DATE = I_DATADATE
       WHERE A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.LOAN_ACCT_BAL <> 0
         AND A.DATA_DATE = I_DATADATE
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_2..A'
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_2..B'
                  WHEN A.ACCT_TYP = '0202' THEN
                   'G09_I_2..C'
                END;
    COMMIT;

    ---当年累计发放贷款户数-------------------

    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN
          'G09_I_3..A'
         WHEN A.ACCT_TYP LIKE '0102%' THEN
          'G09_I_3..B'
         WHEN A.ACCT_TYP = '0202' THEN
          'G09_I_3..C'
       END AS ITEM_NUM,
       COUNT(DISTINCT A.CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN SMTMODS_L_CUST_ALL T
          ON T.CUST_ID = A.CUST_ID
         AND T.DATA_DATE = I_DATADATE
       WHERE A.CANCEL_FLG <> 'Y' --未核销
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND SUBSTR(A.DRAWDOWN_DT, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND A.DATA_DATE = I_DATADATE
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_3..A'
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_3..B'
                  WHEN A.ACCT_TYP = '0202' THEN
                   'G09_I_3..C'
                END;
    COMMIT;

    ----------------------------------------------当年新发放贷款:当年累放贷款额--------------------------------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取互联网当年新发放贷款相关数据至G0901_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN
          'G09_I_4..A'
         WHEN A.ACCT_TYP LIKE '0102%' THEN
          'G09_I_4..B'
         WHEN A.ACCT_TYP = '0202' THEN
          'G09_I_4..C'
       END AS ITEM_NUM,
       SUM(A.DRAWDOWN_AMT * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.CANCEL_FLG <> 'Y' --未核销
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组
         AND A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.DRAWDOWN_DT, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_4..A'
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_4..B'
                  WHEN A.ACCT_TYP = '0202' THEN
                   'G09_I_4..C'
                END;
    COMMIT;

    ----------------------------------------------贷款融资成本:当年累放贷款年化利息收益--------------------------------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取互联网当年累放贷款年化利息收益数据至G0901_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN
          'G09_I_5..A'
         WHEN A.ACCT_TYP LIKE '0102%' THEN
          'G09_I_5..B'
         WHEN A.ACCT_TYP = '0202' THEN
          'G09_I_5..C'
       END AS ITEM_NUM,
       SUM(A.DRAWDOWN_AMT * A.REAL_INT_RAT / 100) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON B.BASIC_CCY = A.CURR_CD --基准币种
         AND B.FORWARD_CCY = 'CNY' --折算币种
         AND B.CCY_DATE = I_DATADATE
       WHERE A.CANCEL_FLG <> 'Y' --未核销
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组
         AND SUBSTR(A.DRAWDOWN_DT, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND A.DATA_DATE = I_DATADATE
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_5..A'
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_5..B'
                  WHEN A.ACCT_TYP = '0202' THEN
                   'G09_I_5..C'
                END;
    COMMIT;

    ----------------------------------------------不良处置: 6.1 当年累计形成不良贷款金额--------------------------------------------------------------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取不良处置相关数据至G0901_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          'G09_I_6.1.A'
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          'G09_I_6.1.B'
         WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
          'G09_I_6.1.C'
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN T --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN A --贷款借据信息表
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   'G09_I_6.1.A'
                  WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   'G09_I_6.1.B'
                  WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
                   'G09_I_6.1.C'
                END;
    COMMIT;

    ----------------------------------------------不良处置: 6.2 当年已处置不良贷款金额--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          'G09_I_6.2.A'
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          'G09_I_6.2.B'
         WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
          'G09_I_6.2.C'
       END AS ITEM_NUM,
       SUM(CASE
             WHEN C.PAY_TYPE IN ('11', '08') THEN
              NVL(C.RECEIVE_AMT, 0) * U.CCY_RATE
             ELSE
              NVL(C.PAY_AMT, 0) * U.CCY_RATE
           END) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_LOAN A --贷款信息表
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM C --贷款还款明细信息表
          ON A.LOAN_NUM = C.LOAN_NUM
         AND C.BATCH_TRAN_FLG = 'Y'
         AND SUBSTR(C.REPAY_DT, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND C.PAY_TYPE IN
             ('01', '02', '03', '07', '08', '09', '11', '12', '05')
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   'G09_I_6.2.A'
                  WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   'G09_I_6.2.B'
                  WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
                   'G09_I_6.2.C'
                END;
    COMMIT;

    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          'G09_I_6.2.A'
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          'G09_I_6.2.B'
         WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
          'G09_I_6.2.C'
       END AS ITEM_NUM,
       SUM(B.PAY_AMT * U.CCY_RATE) AS ITEM_VAL --指标值
        FROM SMTMODS_L_ACCT_LOAN A --贷款信息表
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM B
          ON A.LOAN_NUM = B.LOAN_NUM --贷款还款明细信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND SUBSTR(B.REPAY_DT, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND A.DATA_DATE = I_DATADATE
         AND B.PAY_TYPE = '06'
         AND A.ACCT_STS <> '3'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   'G09_I_6.2.A'
                  WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   'G09_I_6.2.B'
                  WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
                   'G09_I_6.2.C'
                END;
    COMMIT; -----以物抵债

    ----------------------------------------------担保代偿:7 当年累计担保代偿金额--------------------------------------------------------------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取担保代偿相关数据至G0901_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT I_DATADATE, --数据日期
             T1.ORG_NUM, --机构号
             CASE
               WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                'G09_I_7..A'
               WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                'G09_I_7..B'
               WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
                'G09_I_7..C'
             END AS ITEM_NUM,
             SUM(T.PAY_AMT + T.PAY_INT_AMT + T.PAY_OTH_AMT) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN T1
        LEFT JOIN SMTMODS_L_TRAN_LOAN_PAYM T
          ON T1.LOAN_NUM = T.LOAN_NUM
         AND T.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_ACCT_LOAN A --贷款借据信息表
          ON T1.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
         AND T.PAY_TYPE = '07' --还款方式：担保代偿
         AND SUBSTR(TO_CHAR(T.REPAY_DT, 'YYYYMMDD'), 1, 4) =
             SUBSTR(I_DATADATE, 1, 4)
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T1.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   'G09_I_7..A'
                  WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   'G09_I_7..B'
                  WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
                   'G09_I_7..C'
                END;
    COMMIT;
    ----------------------------------------------合作机构管理情况(本机构主要作为资金提供方共同出资): 8.1.1共同出资发放贷款合作机构家数--------------------------------------------------------------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取互联网合作机构管理情况数据至G0901_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.1.1.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.1.1.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.1.1.C'
       END AS ITEM_NUM,
       COUNT(DISTINCT A.COOP_CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
       WHERE A.ORG_ROLE = 'A' --主要作为资金提供方
         AND A.INTERNET_LOAN_TYP IN ('B', 'C') --B线上联合贷款 C同属商业银行互联网贷款和线上联合贷款
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.1.1.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.1.1.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.1.1.C'
                END;
    COMMIT;

    ----------------------------------------------合作机构管理情况(本机构主要作为资金提供方共同出资): 8.1.2本机构出资发放贷款余额--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.1.2.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.1.2.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.1.2.C'
       END AS ITEM_NUM,
       SUM((A.TOTAL_LOAN_BAL - A.COOP_LOAN_BAL) * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ORG_ROLE = 'A' --主要作为资金提供方   --吴大为提出 本机构发放贷余额全部归为本机构出资发放贷款   --zjk
         AND A.INTERNET_LOAN_TYP IN ('B', 'C') --B线上联合贷款 C同属商业银行互联网贷款和线上联合贷款
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.1.2.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.1.2.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.1.2.C'
                END;
    COMMIT;

    ----------------------------------------------合作机构管理情况(本机构主要作为资金提供方共同出资): 8.1.2.1合作方提供增信的贷款余额--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.1.2.1.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.1.2.1.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.1.2.1.C'
       END AS ITEM_NUM,
       SUM(b.loan_acct_bal * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ORG_ROLE = 'A' --主要作为资金提供方
         AND A.COOP_TYPE LIKE '%F%' --担保增信
         AND A.INTERNET_LOAN_TYP IN ('B', 'C') --B线上联合贷款 C同属商业银行互联网贷款和线上联合贷款
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.1.2.1.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.1.2.1.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.1.2.1.C'
                END;
    COMMIT;

    ----------------------------------------------合作机构管理情况(本机构主要作为资金提供方共同出资): 8.1.3合作方出资发放贷款余额--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.1.3.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.1.3.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.1.3.C'
       END AS ITEM_NUM,
       SUM(b.loan_acct_bal * U.CCY_RATE)/0.7*0.3 AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ORG_ROLE = 'A' --主要作为资金提供方
         AND A.INTERNET_LOAN_TYP IN ('B', 'C') --B线上联合贷款 C同属商业银行互联网贷款和线上联合贷款
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.1.3.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.1.3.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.1.3.C'
                END;
    COMMIT;

    ------8.1.3合作方出资发放贷款余额:8.1.3.1 商业银行 8.1.3.2 信托 8.1.3.3 消费金融公司 8.1.3.4 小额贷款公司------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          (CASE
         WHEN C.COOP_CUST_TYPE = 'A' THEN
          'G09_I_8.1.3.1.A' --商业银行
         WHEN C.COOP_CUST_TYPE = 'B' THEN
          'G09_I_8.1.3.2.A' --信托
         WHEN C.COOP_CUST_TYPE = 'C' THEN
          'G09_I_8.1.3.3.A' --消费金融公司
         WHEN C.COOP_CUST_TYPE = 'D' THEN
          'G09_I_8.1.3.4.A' --小额贷款公司
          END)
         WHEN B.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          (CASE
         WHEN C.COOP_CUST_TYPE = 'A' THEN
          'G09_I_8.1.3.1.B' --商业银行
         WHEN C.COOP_CUST_TYPE = 'B' THEN
          'G09_I_8.1.3.2.B' --信托
         WHEN C.COOP_CUST_TYPE = 'C' THEN
          'G09_I_8.1.3.3.B' --消费金融公司
         WHEN C.COOP_CUST_TYPE = 'D' THEN
          'G09_I_8.1.3.4.B' --小额贷款公司
          END)
         WHEN B.ACCT_TYP = '0202' THEN --流动资金贷款
          (CASE
         WHEN C.COOP_CUST_TYPE = 'A' THEN
          'G09_I_8.1.3.1.C' --商业银行
         WHEN C.COOP_CUST_TYPE = 'B' THEN
          'G09_I_8.1.3.2.C' --信托
         WHEN C.COOP_CUST_TYPE = 'C' THEN
          'G09_I_8.1.3.3.C' --消费金融公司
         WHEN C.COOP_CUST_TYPE = 'D' THEN
          'G09_I_8.1.3.4.C' --小额贷款公司
          END)
       END AS ITEM_NUM,
       SUM(b.loan_acct_bal * U.CCY_RATE)/0.7*0.3 AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_COOP_AGEN C --合作机构信息表
          ON A.COOP_CUST_ID = C.COOP_CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ORG_ROLE = 'A' --主要作为资金提供方
         AND A.INTERNET_LOAN_TYP IN ('B', 'C') --B线上联合贷款 C同属商业银行互联网贷款和线上联合贷款
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   (CASE
                  WHEN C.COOP_CUST_TYPE = 'A' THEN
                   'G09_I_8.1.3.1.A' --商业银行
                  WHEN C.COOP_CUST_TYPE = 'B' THEN
                   'G09_I_8.1.3.2.A' --信托
                  WHEN C.COOP_CUST_TYPE = 'C' THEN
                   'G09_I_8.1.3.3.A' --消费金融公司
                  WHEN C.COOP_CUST_TYPE = 'D' THEN
                   'G09_I_8.1.3.4.A' --小额贷款公司
                   END)
                  WHEN B.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   (CASE
                  WHEN C.COOP_CUST_TYPE = 'A' THEN
                   'G09_I_8.1.3.1.B' --商业银行
                  WHEN C.COOP_CUST_TYPE = 'B' THEN
                   'G09_I_8.1.3.2.B' --信托
                  WHEN C.COOP_CUST_TYPE = 'C' THEN
                   'G09_I_8.1.3.3.B' --消费金融公司
                  WHEN C.COOP_CUST_TYPE = 'D' THEN
                   'G09_I_8.1.3.4.B' --小额贷款公司
                   END)
                  WHEN B.ACCT_TYP = '0202' THEN --流动资金贷款
                   (CASE
                  WHEN C.COOP_CUST_TYPE = 'A' THEN
                   'G09_I_8.1.3.1.C' --商业银行
                  WHEN C.COOP_CUST_TYPE = 'B' THEN
                   'G09_I_8.1.3.2.C' --信托
                  WHEN C.COOP_CUST_TYPE = 'C' THEN
                   'G09_I_8.1.3.3.C' --消费金融公司
                  WHEN C.COOP_CUST_TYPE = 'D' THEN
                   'G09_I_8.1.3.4.C' --小额贷款公司
                   END)
                END;
    COMMIT;

    ----------------------------------------------合作机构管理情况(本机构主要作为资金提供方共同出资):
    --  8.1.4合作方当年累计推荐客户户数--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      
    --alter by  shiyu 20240129 当年推荐户数：当年放款+当年推荐
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ITEM_NUM = 'A' THEN
          'G09_I_8.1.4.A' --个人消费
         WHEN A.ITEM_NUM = 'B' THEN
          'G09_I_8.1.4.B' --个人生产经营
         WHEN A.ITEM_NUM = 'C' THEN
          'G09_I_8.1.4.C' --流动资金
       END AS ITEM_NUM,
       COUNT(DISTINCT CUST_ID) AS ITEM_VAL
        FROM (
              SELECT 
               I_DATADATE AS DATA_DATE,
                A.ORG_NUM,
                CASE
                  WHEN a.ACCT_TYP LIKE '0103%' THEN
                   'A'
                  WHEN a.ACCT_TYP LIKE '0102%' THEN
                   'B'
                  WHEN a.ACCT_TYP = '0202' THEN
                   'C'
                END AS ITEM_NUM,
                A.CUST_ID
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_CUST_ALL T
                  ON T.CUST_ID = A.CUST_ID
                 AND T.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_ACCT_INTERNET_LOAN T1 --互联网贷款业务信息表
                  ON A.LOAN_NUM = T1.LOAN_NUM
                 AND A.DATA_DATE = T1.DATA_DATE
               WHERE A.CANCEL_FLG <> 'Y' --未核销
                 AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
                 AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
                     OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
                     OR A.ACCT_TYP = '0202') --流动资金贷款
                 AND TO_CHAR(A.DRAWDOWN_DT, 'YYYY') =
                     SUBSTR(I_DATADATE, 1, 4) --当年发放贷款
                 AND A.DATA_DATE = I_DATADATE
                 and T1.ORG_ROLE = 'A' --本机构主要作为资金提供方
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
               GROUP BY A.ORG_NUM,
                         CASE
                           WHEN a.ACCT_TYP LIKE '0103%' THEN
                            'A'
                           WHEN a.ACCT_TYP LIKE '0102%' THEN
                            'B'
                           WHEN a.ACCT_TYP = '0202' THEN
                            'C'
                         END,
                         a.cust_id
              union all
              SELECT 
               I_DATADATE      AS DATA_DATE,
                A.ORG_NUM,
                A.REC_ACCT_TYPE AS ITEM_NUM,
                a.cust_id

                FROM SMTMODS_L_REC_CUST_INTERNET_LOAN A --互联网贷款客户推荐信息表
               WHERE A.ORG_ROLE = 'A' --本机构主要作为资金提供方
                 AND SUBSTR(A.REC_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4) --推荐日期在本年度
                 AND A.DATA_DATE = I_DATADATE) a
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ITEM_NUM = 'A' THEN
                   'G09_I_8.1.4.A' --个人消费
                  WHEN A.ITEM_NUM = 'B' THEN
                   'G09_I_8.1.4.B' --个人生产经营
                  WHEN A.ITEM_NUM = 'C' THEN
                   'G09_I_8.1.4.C' --流动资金
                END;

    COMMIT;

    ----------------------------------------------合作机构管理情况(本机构主要作为资金提供方共同出资):  8.1.4.1 本行当年累计通过授信客户户数--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.REC_ACCT_TYPE = 'A' THEN
          'G09_I_8.1.4.1.A' --个人消费
         WHEN A.REC_ACCT_TYPE = 'B' THEN
          'G09_I_8.1.4.1.B' --个人生产经营
         WHEN A.REC_ACCT_TYPE = 'C' THEN
          'G09_I_8.1.4.1.C' --流动资金
       END AS ITEM_NUM,
       COUNT(DISTINCT CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_REC_CUST_INTERNET_LOAN A --互联网贷款客户推荐信息表
       WHERE A.ORG_ROLE = 'A' --本机构主要作为资金提供方
         AND A.CREDIT_FLG = 'Y' --通过授信
         AND SUBSTR(A.REC_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4) --推荐日期在本年度
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REC_ACCT_TYPE = 'A' THEN
                   'G09_I_8.1.4.1.A' --个人消费
                  WHEN A.REC_ACCT_TYPE = 'B' THEN
                   'G09_I_8.1.4.1.B' --个人生产经营
                  WHEN A.REC_ACCT_TYPE = 'C' THEN
                   'G09_I_8.1.4.1.C' --流动资金
                END;
    COMMIT;

    ----------------------------------------------合作机构管理情况(本机构主要作为信息提供方共同出资): 8.2.1 共同出资发放贷款合作机构家数--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.2.1.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.2.1.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.2.1.C'
       END AS ITEM_NUM,
       COUNT(DISTINCT A.COOP_CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
       WHERE A.ORG_ROLE = 'B' --主要作为信息提供方
         AND A.INTERNET_LOAN_TYP IN ('B', 'C')
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.2.1.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.2.1.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.2.1.C'
                END;
    COMMIT;

    ----------------------------------------------合作机构管理情况(本机构主要作为信息提供方共同出资): 8.2.2本机构出资发放贷款余额--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.2.2.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.2.2.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.2.2.C'
       END AS ITEM_NUM,
       SUM(A.TOTAL_LOAN_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ORG_ROLE = 'B' --主要作为信息提供方
         AND A.INTERNET_LOAN_TYP IN ('B', 'C')
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.2.2.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.2.2.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.2.2.C'
                END;
    COMMIT;
    ----------------------------------------------合作机构管理情况(本机构主要作为信息提供方共同出资): 8.2.2.1合作方提供增信的贷款余额--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.2.2.1.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.2.2.1.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.2.2.1.C'
       END AS ITEM_NUM,
       SUM(A.TOTAL_LOAN_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ORG_ROLE = 'B' --主要作为信息提供方
         AND A.INTERNET_LOAN_TYP IN ('B', 'C')
         AND A.COOP_TYPE LIKE '%F%' --包含担保增信
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.2.2.1.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.2.2.1.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.2.2.1.C'
                END;
    COMMIT;

    ----------------------------------------------合作机构管理情况(本机构主要作为信息提供方共同出资): 8.2.3合作方出资发放贷款余额--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.1.3.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.1.3.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.1.3.C'
       END AS ITEM_NUM,
       SUM(A.COOP_LOAN_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ORG_ROLE = 'B' --主要作为信息提供方
         AND A.INTERNET_LOAN_TYP IN ('B', 'C')
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.1.3.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.1.3.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.1.3.C'
                END;
    COMMIT;

    ------8.2.3合作方出资发放贷款余额:8.2.3.1 商业银行 8.2.3.2 信托 8.2.3.3 消费金融公司 8.2.3.4 小额贷款公司------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          (CASE
         WHEN C.COOP_CUST_TYPE = 'A' THEN
          'G09_I_8.2.3.1.A' --商业银行
         WHEN C.COOP_CUST_TYPE = 'B' THEN
          'G09_I_8.2.3.2.A' --信托
         WHEN C.COOP_CUST_TYPE = 'C' THEN
          'G09_I_8.2.3.3.A' --消费金融公司
         WHEN C.COOP_CUST_TYPE = 'D' THEN
          'G09_I_8.2.3.4.A' --小额贷款公司
          END)
         WHEN B.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          (CASE
         WHEN C.COOP_CUST_TYPE = 'A' THEN
          'G09_I_8.2.3.1.B' --商业银行
         WHEN C.COOP_CUST_TYPE = 'B' THEN
          'G09_I_8.2.3.2.B' --信托
         WHEN C.COOP_CUST_TYPE = 'C' THEN
          'G09_I_8.2.3.3.B' --消费金融公司
         WHEN C.COOP_CUST_TYPE = 'D' THEN
          'G09_I_8.2.3.4.B' --小额贷款公司
          END)
         WHEN B.ACCT_TYP = '0202' THEN --流动资金贷款
          (CASE
         WHEN C.COOP_CUST_TYPE = 'A' THEN
          'G09_I_8.2.3.1.C' --商业银行
         WHEN C.COOP_CUST_TYPE = 'B' THEN
          'G09_I_8.2.3.2.C' --信托
         WHEN C.COOP_CUST_TYPE = 'C' THEN
          'G09_I_8.2.3.3.C' --消费金融公司
         WHEN C.COOP_CUST_TYPE = 'D' THEN
          'G09_I_8.2.3.4.C' --小额贷款公司
          END)
       END AS ITEM_NUM,
       SUM(A.COOP_LOAN_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_COOP_AGEN C --合作机构信息表
          ON A.COOP_CUST_ID = C.COOP_CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ORG_ROLE = 'B' --主要作为信息提供方
         AND A.INTERNET_LOAN_TYP IN ('B', 'C') --B线上联合贷款 C同属商业银行互联网贷款和线上联合贷款
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   (CASE
                  WHEN C.COOP_CUST_TYPE = 'A' THEN
                   'G09_I_8.2.3.1.A' --商业银行
                  WHEN C.COOP_CUST_TYPE = 'B' THEN
                   'G09_I_8.2.3.2.A' --信托
                  WHEN C.COOP_CUST_TYPE = 'C' THEN
                   'G09_I_8.2.3.3.A' --消费金融公司
                  WHEN C.COOP_CUST_TYPE = 'D' THEN
                   'G09_I_8.2.3.4.A' --小额贷款公司
                   END)
                  WHEN B.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   (CASE
                  WHEN C.COOP_CUST_TYPE = 'A' THEN
                   'G09_I_8.2.3.1.B' --商业银行
                  WHEN C.COOP_CUST_TYPE = 'B' THEN
                   'G09_I_8.2.3.2.B' --信托
                  WHEN C.COOP_CUST_TYPE = 'C' THEN
                   'G09_I_8.2.3.3.B' --消费金融公司
                  WHEN C.COOP_CUST_TYPE = 'D' THEN
                   'G09_I_8.2.3.4.B' --小额贷款公司
                   END)
                  WHEN B.ACCT_TYP = '0202' THEN --流动资金贷款
                   (CASE
                  WHEN C.COOP_CUST_TYPE = 'A' THEN
                   'G09_I_8.2.3.1.C' --商业银行
                  WHEN C.COOP_CUST_TYPE = 'B' THEN
                   'G09_I_8.2.3.2.C' --信托
                  WHEN C.COOP_CUST_TYPE = 'C' THEN
                   'G09_I_8.2.3.3.C' --消费金融公司
                  WHEN C.COOP_CUST_TYPE = 'D' THEN
                   'G09_I_8.2.3.4.C' --小额贷款公司
                   END)
                END;
    COMMIT;

    ----------------------------------------------合作机构管理情况(本机构主要作为信息提供方共同出资):  8.2.4本机构当年累计推荐客户户数--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

   
    --alter by shiyu 推荐人数：当年推荐+当年放款

    SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ITEM_NUM = 'A' THEN
          'G09_I_8.2.4.A' --个人消费
         WHEN A.ITEM_NUM = 'B' THEN
          'G09_I_8.2.4.B' --个人生产经营
         WHEN A.ITEM_NUM = 'C' THEN
          'G09_I_8.2.4.C' --流动资金
       END AS ITEM_NUM,
       COUNT(DISTINCT CUST_ID) AS ITEM_VAL
        FROM (SELECT 
               I_DATADATE AS DATA_DATE,
                A.ORG_NUM,
                CASE
                  WHEN a.ACCT_TYP LIKE '0103%' THEN
                   'A'
                  WHEN a.ACCT_TYP LIKE '0102%' THEN
                   'B'
                  WHEN a.ACCT_TYP = '0202' THEN
                   'C'
                END AS ITEM_NUM,
                a.cust_id
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_CUST_ALL T
                  ON T.CUST_ID = A.CUST_ID
                 AND T.DATA_DATE = I_DATADATE
                left join SMTMODS_L_ACCT_INTERNET_LOAN t1 --互联网贷款业务信息表
                  on a.loan_num = t1.loan_num
                 and a.data_date = t1.data_date
               WHERE A.CANCEL_FLG <> 'Y' --未核销
                 AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
                 AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
                     OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
                     OR A.ACCT_TYP = '0202') --流动资金贷款
                 AND TO_CHAR(A.DRAWDOWN_DT, 'YYYY') =
                     SUBSTR(I_DATADATE, 1, 4) --当年发放贷款
                 AND A.DATA_DATE = I_DATADATE
                 and T1.ORG_ROLE = 'B' --本机构主要作为信息提供方
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
               GROUP BY A.ORG_NUM,
                         CASE
                           WHEN a.ACCT_TYP LIKE '0103%' THEN
                            'A'
                           WHEN a.ACCT_TYP LIKE '0102%' THEN
                            'B'
                           WHEN a.ACCT_TYP = '0202' THEN
                            'C'
                         END,
                         a.cust_id
              union all
              SELECT 
               I_DATADATE      AS DATA_DATE,
                A.ORG_NUM,
                A.REC_ACCT_TYPE AS ITEM_NUM,
                a.cust_id

                FROM SMTMODS_L_REC_CUST_INTERNET_LOAN A --互联网贷款客户推荐信息表
               WHERE A.ORG_ROLE = 'B' --本机构主要作为信息提供方
                 AND TO_CHAR(A.REC_DATE, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --推荐日期在本年度
                 AND A.DATA_DATE = I_DATADATE
                 ) a
       GROUP BY A.ORG_NUM,
                CASE
         WHEN A.ITEM_NUM = 'A' THEN
          'G09_I_8.2.4.A' --个人消费
         WHEN A.ITEM_NUM = 'B' THEN
          'G09_I_8.2.4.B' --个人生产经营
         WHEN A.ITEM_NUM = 'C' THEN
          'G09_I_8.2.4.C' --流动资金
       END;

    COMMIT;

    ----------------------------------------------合作机构管理情况(本机构主要作为资金提供方共同出资):   8.2.4.1合作机构当年累计通过授信客户户数--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.REC_ACCT_TYPE = 'A' THEN
          'G09_I_8.2.4.1.A' --个人消费
         WHEN A.REC_ACCT_TYPE = 'B' THEN
          'G09_I_8.2.4.1.B' --个人生产经营
         WHEN A.REC_ACCT_TYPE = 'C' THEN
          'G09_I_8.2.4.1.C' --流动资金
       END AS ITEM_NUM,
       COUNT(DISTINCT CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_REC_CUST_INTERNET_LOAN A --互联网贷款客户推荐信息表
       WHERE A.ORG_ROLE = 'B' --本机构主要作为信息提供方
         AND A.CREDIT_FLG = 'Y' --通过授信
         AND SUBSTR(A.REC_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4) --推荐日期在本年度
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REC_ACCT_TYPE = 'A' THEN
                   'G09_I_8.2.4.1.A' --个人消费
                  WHEN A.REC_ACCT_TYPE = 'B' THEN
                   'G09_I_8.2.4.1.B' --个人生产经营
                  WHEN A.REC_ACCT_TYPE = 'C' THEN
                   'G09_I_8.2.4.1.C' --流动资金
                END;
    COMMIT;

    ----------------------------------------------合作机构管理情况(银行单独出资合作发放互联网贷款情况): 8.3.1合作机构家数--------------------------------------------------------------------------


   INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.3.1.A.2022'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.3.1.B.2022'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.3.1.B.2022'
       END AS ITEM_NUM,
       COUNT(DISTINCT A.COOP_CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
       WHERE A.INTERNET_LOAN_TYP = 'A'
         AND A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.3.1.A.2022'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.3.1.B.2022'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.3.1.B.2022'
       END;
    COMMIT;
    ---------------  其中：8.3.1.1担保增信合作机构家数------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.3.1.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.3.1.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.3.1.C'
       END AS ITEM_NUM,
       COUNT(DISTINCT A.COOP_CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
       WHERE A.INTERNET_LOAN_TYP = 'A'
         AND A.COOP_TYPE LIKE '%F%' --合作方式包含担保增信
         AND A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.3.1.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.3.1.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.3.1.C'
                END;
    COMMIT;
    ---------------  其中：8.3.1.2提供部分风险评价服务合作机构家数------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.4.1.1.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.4.1.1.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.4.1.1.C'
       END AS ITEM_NUM,
       COUNT(DISTINCT A.COOP_CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
       WHERE A.INTERNET_LOAN_TYP = 'A'
         AND A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND A.COOP_TYPE LIKE '%E%' --合作方式包含部分风险评价
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.4.1.1.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.4.1.1.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.4.1.1.C'
                END;
    COMMIT;
    ----------------------------------------------合作机构管理情况(银行单独出资合作发放互联网贷款情况): 8.3.2 合作发放贷款余额--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.3.2.A.2022'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.3.2.B.2022'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.3.2.C.2022'
       END AS ITEM_NUM,
       SUM(A.TOTAL_LOAN_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.INTERNET_LOAN_TYP = 'A'
         AND A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.3.2.A.2022'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.3.2.B.2022'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.3.2.C.2022'
                END;
    COMMIT;

    ----------------------------------------------合作机构管理情况(银行单独出资合作发放互联网贷款情况): 8.3.3 合作方提供担保增信的贷款余额--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.3.3.A.2022'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.3.3.B.2022'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.3.3.C.2022'
       END AS ITEM_NUM,
       SUM(A.TOTAL_LOAN_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.INTERNET_LOAN_TYP = 'A'
         AND A.COOP_TYPE LIKE '%F%' --合作方式包含担保增信
         AND A.DATA_DATE = I_DATADATE
         AND A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.3.3.A.2022'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.3.3.B.2022'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.3.3.C.2022'
                END;
    COMMIT;
    ----------其中：8.3.3.1 由保证保险提供增信的贷款余额-------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.3.2.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.3.2.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.3.2.C'
       END AS ITEM_NUM,
       SUM(A.TOTAL_LOAN_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.INTERNET_LOAN_TYP = 'A'
         AND A.COOP_TYPE LIKE '%F%' --合作方式包含担保增信
         AND A.CREDIT_ORG_TYPE = 'A' --增信机构类型:保证保险
         AND A.DATA_DATE = I_DATADATE
         AND A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.3.2.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.3.2.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.3.2.C'
                END;
    COMMIT;

    ----------其中：8.3.3.2 由信用保险提供增信的贷款余额-------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.3.3.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.3.3.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.3.3.C'
       END AS ITEM_NUM,
       SUM(A.TOTAL_LOAN_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.INTERNET_LOAN_TYP = 'A'
         AND A.COOP_TYPE LIKE '%F%' --合作方式包含担保增信
         AND A.CREDIT_ORG_TYPE = 'B' --增信机构类型:信用保险
         AND A.DATA_DATE = I_DATADATE
         AND A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.3.3.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.3.3.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.3.3.C'
                END;
    COMMIT;

    ----------其中：8.3.3.3 由融资担保公司提供增信的贷款余额-------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.3.4.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.3.4.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.3.4.C'
       END AS ITEM_NUM,
       SUM(A.TOTAL_LOAN_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.INTERNET_LOAN_TYP = 'A'
         AND A.COOP_TYPE LIKE '%F%' --合作方式包含担保增信
         AND A.CREDIT_ORG_TYPE = 'C' --增信机构类型:融资担保公司
         AND A.DATA_DATE = I_DATADATE
         AND A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.3.4.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.3.4.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.3.4.C'
                END;
    COMMIT;

    ----------其中：8.3.3.3 由融资担保公司提供增信的贷款余额-------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.3.4.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.3.4.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.3.4.C'
       END AS ITEM_NUM,
       SUM(A.TOTAL_LOAN_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.INTERNET_LOAN_TYP = 'A'
         AND A.COOP_TYPE LIKE '%F%' --合作方式包含担保增信
         AND A.CREDIT_ORG_TYPE = 'C' --增信机构类型:融资担保公司
         AND A.DATA_DATE = I_DATADATE
         AND A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.3.4.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.3.4.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.3.4.C'
                END;
    COMMIT;

    ----------其中：8.3.3.4 由其他机构提供增信的贷款余额-------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.3.5.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.3.5.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.3.5.C'
       END AS ITEM_NUM,
       SUM(A.TOTAL_LOAN_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.INTERNET_LOAN_TYP = 'A'
         AND A.COOP_TYPE LIKE '%F%' --合作方式包含担保增信
         AND A.CREDIT_ORG_TYPE = 'Z' --增信机构类型:其他
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.3.5.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.3.5.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.3.5.C'
                END;
    COMMIT;

    ----------------------------------------------合作机构管理情况(银行单独出资合作发放互联网贷款情况): 8.3.4 合作方当年累计推荐客户户数--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ITEM_NUM = 'A' THEN
          'G09_I_8.3.4.A.2022' --个人消费
         WHEN A.ITEM_NUM = 'B' THEN
          'G09_I_8.3.4.B.2022' --个人生产经营
         WHEN A.ITEM_NUM = 'C' THEN
          'G09_I_8.3.4.C.2022' --流动资金
       END AS ITEM_NUM,
       COUNT(DISTINCT CUST_ID) AS ITEM_VAL
        FROM (SELECT 
               I_DATADATE AS DATA_DATE,
                A.ORG_NUM,
                CASE
                  WHEN a.ACCT_TYP LIKE '0103%' THEN
                   'A'
                  WHEN a.ACCT_TYP LIKE '0102%' THEN
                   'B'
                  WHEN a.ACCT_TYP = '0202' THEN
                   'C'
                END AS ITEM_NUM,
                a.cust_id
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_CUST_ALL T
                  ON T.CUST_ID = A.CUST_ID
                 AND T.DATA_DATE = I_DATADATE
                left join SMTMODS_L_ACCT_INTERNET_LOAN t1 --互联网贷款业务信息表
                  on a.loan_num = t1.loan_num
                 and a.data_date = t1.data_date
               WHERE A.CANCEL_FLG <> 'Y' --未核销
                 AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
                 AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
                     OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
                     OR A.ACCT_TYP = '0202') --流动资金贷款
                 AND TO_CHAR(A.DRAWDOWN_DT, 'YYYY') =
                     SUBSTR(I_DATADATE, 1, 4) --当年发放贷款
                 AND A.DATA_DATE = I_DATADATE
                 and T1.ORG_ROLE = 'C'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
               GROUP BY A.ORG_NUM,
                         CASE
                           WHEN a.ACCT_TYP LIKE '0103%' THEN
                            'A'
                           WHEN a.ACCT_TYP LIKE '0102%' THEN
                            'B'
                           WHEN a.ACCT_TYP = '0202' THEN
                            'C'
                         END,
                         a.cust_id
              union all
              SELECT 
               I_DATADATE      AS DATA_DATE,
                A.ORG_NUM,
                A.REC_ACCT_TYPE AS ITEM_NUM,
                a.cust_id

                FROM SMTMODS_L_REC_CUST_INTERNET_LOAN A --互联网贷款客户推荐信息表
               WHERE A.ORG_ROLE = 'C'
                 AND TO_CHAR(A.REC_DATE, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --推荐日期在本年度
                 AND A.DATA_DATE = I_DATADATE

                 ) a
       GROUP BY A.ORG_NUM,
                CASE
         WHEN A.ITEM_NUM = 'A' THEN
          'G09_I_8.3.4.A.2022' --个人消费
         WHEN A.ITEM_NUM = 'B' THEN
          'G09_I_8.3.4.B.2022' --个人生产经营
         WHEN A.ITEM_NUM = 'C' THEN
          'G09_I_8.3.4.C.2022' --流动资金
       END;

    COMMIT;

    ----------------------------------------------合作机构管理情况(银行单独出资合作发放互联网贷款情况):  8.3.4.1 本行当年累计通过授信客户户数--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.REC_ACCT_TYPE = 'A' THEN
          'G09_I_8.3.4.1.A.2022' --个人消费
         WHEN A.REC_ACCT_TYPE = 'B' THEN
          'G09_I_8.3.4.1.B.2022' --个人生产经营
         WHEN A.REC_ACCT_TYPE = 'C' THEN
          'G09_I_8.3.4.1.C.2022' --流动资金
       END AS ITEM_NUM,
       COUNT(DISTINCT CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_REC_CUST_INTERNET_LOAN A --互联网贷款客户推荐信息表
       WHERE --A.ORG_ROLE = 'A' --本机构主要作为资金提供方
        A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND A.CREDIT_FLG = 'Y' --通过授信
         AND TO_CHAR(A.REC_DATE, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --推荐日期在本年度
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REC_ACCT_TYPE = 'A' THEN
                   'G09_I_8.3.4.1.A.2022' --个人消费
                  WHEN A.REC_ACCT_TYPE = 'B' THEN
                   'G09_I_8.3.4.1.B.2022' --个人生产经营
                  WHEN A.REC_ACCT_TYPE = 'C' THEN
                   'G09_I_8.3.4.1.C.2022' --流动资金
                END;
    COMMIT;
    ----------------------------------------------合作机构管理情况(银行单独出资合作发放互联网贷款情况): 8.3.5 向合作方累计支付费用 --------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.3.5.A.2022'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.3.5.B.2022'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.3.5.C.2022'
       END AS ITEM_NUM,
       SUM(A.YEAR_SERV_FEE * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.INTERNET_LOAN_TYP = 'A'
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.3.5.A.2022'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.3.5.B.2022'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.3.5.C.2022'
                END;
    COMMIT;

    -------其中：8.3.5.1 担保增信费用----------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.3.5.1.A.2022'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.3.5.1.B.2022'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.3.5.1.C.2022'
       END AS ITEM_NUM,
       SUM(A.YEAR_SERV_FEE * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.INTERNET_LOAN_TYP = 'A' --仅为商业银行互联网贷款
         AND A.COOP_TYPE LIKE '%F%' --合作方式包含担保增信
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.3.5.1.A.2022'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.3.5.1.B.2022'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.3.5.1.C.2022'
                END;

    ----------------------------------------------合作机构管理情况(银行单独出资合作发放互联网贷款情况): 8.3.6 合作发放贷款利息收益--------------------------------------------------------------------------
    INSERT
    INTO CBRC_G0901_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.3.6.A.2022'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.3.6.B.2022'
         WHEN B.ACCT_TYP = '0202' THEN 
          'G09_I_8.3.6.C.2022'
       END AS ITEM_NUM,
       SUM((B.ACCU_INT_AMT + B.OD_INT) * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.INTERNET_LOAN_TYP = 'A' --仅为商业银行互联网贷款
         AND A.DATA_DATE = I_DATADATE
         AND A.ORG_ROLE ='C' --作为单独出资方 --ALTER BY SHIYU 20240112
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND (B.ACCU_INT_AMT <> 0 OR B.OD_INT <> 0)
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.3.6.A.2022'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.3.6.B.2022'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.3.6.C.2022'
                END;
    COMMIT;

    --=======================================================================================================-
    -------------------------------------G0901数据插至目标指标表--------------------------------------------
    --=====================================================================================================---

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G0901指标数据，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*-----------------------所有指标插入目标表-----------------------------------  */

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值(数值型)
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G0901' AS REP_NUM,
             T.ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_G0901_DATA_COLLECT_TMP T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM, T.ITEM_NUM;

    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
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
   
END proc_cbrc_idx2_g0901