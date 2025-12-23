CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g0903(II_DATADATE  IN string  --跑批日期
                                                                 )
/******************************
  @AUTHOR:87v
  @CREATE-DATE:202307
  @DESCRIPTION:G09_III 前十大合作机构合作情况表(不含共同出资发放贷款业务)
  
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_G0903_DATA_COLLECT_TMP
     CBRC_G0903_TMP_BLDKYE
     CBRC_G0903_TMP_LX
     CBRC_G0903_TMP_TOP10
     CBRC_G0903_TMP_YQYE
集市表：SMTMODS_L_ACCT_INTERNET_LOAN
     SMTMODS_L_ACCT_LOAN
     SMTMODS_L_CUST_COOP_AGEN
     SMTMODS_L_PUBL_RATE

  *******************************/
 IS

  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR(30); 
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
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G0903');
    V_TAB_NAME  := 'G0903';

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']G0903当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G0903_DATA_COLLECT_TMP';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G0903_TMP_TOP10';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G0903_TMP_BLDKYE';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G0903_TMP_YQYE';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G0903_TMP_LX';

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G0903';

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：加载临时表数据开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --临时表：取共同出资发放贷款余额前十大合作机构
    INSERT  INTO CBRC_G0903_TMP_TOP10 
      (XH, ORG_NUM, COOP_CUST_ID, COOP_TYPE, TOTAL_LOAN_BAL, COOP_LOAN_BAL)
      SELECT ROWNUM,
       ORG_NUM,
       COOP_CUST_ID,
       COOP_TYPE,
       TOTAL_LOAN_BAL,
       COOP_LOAN_BAL
 FROM (
SELECT 
       ROW_NUMBER() OVER (ORDER BY TOTAL_LOAN_BAL) AS ROWNUM ,
       ORG_NUM,
       COOP_CUST_ID,
       COOP_TYPE,
       TOTAL_LOAN_BAL,
       COOP_LOAN_BAL
        FROM (SELECT 
               ORG_NUM,
               COOP_CUST_ID, --合作方客户号
               COOP_TYPE, --合作方式
               SUM(TOTAL_LOAN_BAL * U.CCY_RATE) AS TOTAL_LOAN_BAL, --共同出资贷款余额
               SUM(COOP_LOAN_BAL * U.CCY_RATE) AS COOP_LOAN_BAL --合作方出资贷款余额
                FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
                 AND U.CCY_DATE = I_DATADATE
               WHERE A.INTERNET_LOAN_TYP = 'A' -- 填报机构出资比例为100%：A 仅为商业银行互联网贷款
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY ORG_NUM, COOP_CUST_ID, COOP_TYPE)
       )
WHERE ROWNUM <=10
       ORDER BY ROWNUM DESC;
    COMMIT;

    --临时表：H 填报机构不良贷款余额
    --储存前十大合作机构的填报机构不良贷款余额

    INSERT  INTO CBRC_G0903_TMP_BLDKYE 
      (ORG_NUM, COOP_CUST_ID, BLDKYE)
      SELECT 
       A.ORG_NUM,
       A.COOP_CUST_ID, --合作方机构号
       CASE
         WHEN B.LOAN_GRADE_CD IN ('3', '4', '5') THEN
          SUM((A.TOTAL_LOAN_BAL * U.CCY_RATE) -
              (A.COOP_LOAN_BAL * U.CCY_RATE))
         ELSE
          0
       END AS BLDKYE --填报机构不良贷款 = 共同出资-合作方出资
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B --贷款借据信息表
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND B.CANCEL_FLG <> 'Y' --未核销
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.COOP_CUST_ID IN (SELECT COOP_CUST_ID FROM CBRC_G0903_TMP_TOP10)
       GROUP BY A.ORG_NUM, A.COOP_CUST_ID, B.LOAN_GRADE_CD;
    COMMIT;

    --临时表：I 贷款逾期率（逾期30天以上）
    --储存前十大合作机构逾期30天以上贷款余额

    INSERT  INTO CBRC_G0903_TMP_YQYE 
      (ORG_NUM, COOP_CUST_ID, YQYE)
      SELECT 
       A.ORG_NUM,
       A.COOP_CUST_ID, --合作方机构号
       CASE
         WHEN B.OD_DAYS > 30 --逾期30天以上
          THEN
          SUM(A.TOTAL_LOAN_BAL * U.CCY_RATE)
         ELSE
          0
       END AS YQYE --逾期30天以上贷款余额
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B --贷款借据信息表
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND B.CANCEL_FLG <> 'Y' --未核销
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.COOP_CUST_ID IN (SELECT COOP_CUST_ID FROM CBRC_G0903_TMP_TOP10)
       GROUP BY A.ORG_NUM, A.COOP_CUST_ID, B.OD_DAYS;
    COMMIT;

    --临时表：J 贷款平均利率
    --储存前十大合作机构贷款余额利息之和
    INSERT  INTO CBRC_G0903_TMP_LX 
      (ORG_NUM, COOP_CUST_ID, LX)
      SELECT A.ORG_NUM,
             A.COOP_CUST_ID,
             SUM((A.TOTAL_LOAN_BAL * U.CCY_RATE) * B.REAL_INT_RAT / 100) AS LX --利息之和
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B --贷款借据信息表
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND B.CANCEL_FLG <> 'Y' --未核销
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.COOP_CUST_ID IN (SELECT COOP_CUST_ID FROM CBRC_G0903_TMP_TOP10)
       GROUP BY A.ORG_NUM, A.COOP_CUST_ID;
    COMMIT;

    V_STEP_FLAG := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：临时表数据加载完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --=======================================================================================================-
    -------------------------------------G0903 数据插至汇总表--------------------------------------------
    --=====================================================================================================---
    V_STEP_FLAG := V_STEP_ID + 1;
    V_STEP_DESC := '产生G0903数据，插至目标表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_G0903_DATA_COLLECT_TMP 
      (DATA_DATE, --数据日期
       PX, --排序
       ORG_NUM,
       HZJGMC, --合作机构名称
       TYSHXYDM, --统一社会信用代码
       TBJGDKYE, --填报机构发放贷款余额
       HZJGFWLX, --合作机构提供服务类型
       BLDKL, --不良贷款率
       DKYQL, --填报机构发放贷款逾期率
       DKPJLV --贷款平均利率
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       B.XH AS PX, --排序
       A.ORG_NUM,
       A.COOP_CUST_NAM AS HZJGMC, --合作机构名称
       A.COOP_ID_NO AS TYSHXYDM, --统一社会信用代码
       B.TOTAL_LOAN_BAL AS TBJGDKYE, --填报机构发放贷款余额
       B.COOP_TYPE AS HZJGFWLX, --合作机构提供服务类型
       C.BLDKYE / B.TOTAL_LOAN_BAL AS BLDKL, --不良贷款率
       D.YQYE / B.TOTAL_LOAN_BAL AS DKYQL, --填报机构发放贷款逾期率
       (E.LX / B.TOTAL_LOAN_BAL) * 100 AS DKPJLV --贷款平均利率
        FROM SMTMODS_L_CUST_COOP_AGEN A --合作机构信息表
       INNER JOIN CBRC_G0903_TMP_TOP10 B
          ON A.COOP_CUST_ID = B.COOP_CUST_ID
       INNER JOIN CBRC_G0903_TMP_BLDKYE C
          ON A.COOP_CUST_ID = C.COOP_CUST_ID
       INNER JOIN CBRC_G0903_TMP_YQYE D
          ON A.COOP_CUST_ID = D.COOP_CUST_ID
       INNER JOIN CBRC_G0903_TMP_LX E
          ON A.COOP_CUST_ID = E.COOP_CUST_ID
       WHERE A.DATA_DATE = I_DATADATE
       ORDER BY B.XH;
    COMMIT;

    --前十大合作机构        B 合作机构名称
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G0903' AS REP_NUM,
             CASE
               WHEN T.PX = '1' THEN
                'G0903_1_B'
               WHEN T.PX = '2' THEN
                'G0903_2_B'
               WHEN T.PX = '3' THEN
                'G0903_3_B'
               WHEN T.PX = '4' THEN
                'G0903_4_B'
               WHEN T.PX = '5' THEN
                'G0903_5_B'
               WHEN T.PX = '6' THEN
                'G0903_6_B'
               WHEN T.PX = '7' THEN
                'G0903_7_B'
               WHEN T.PX = '8' THEN
                'G0903_8_B'
               WHEN T.PX = '9' THEN
                'G0903_9_B'
               WHEN T.PX = '10' THEN
                'G0903_10_B'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             T.HZJGMC AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0903_DATA_COLLECT_TMP T;
    COMMIT;

    --前十大合作机构        C 统一社会信用代码
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G0903' AS REP_NUM,
             CASE
               WHEN T.PX = '1' THEN
                'G0903_1_C'
               WHEN T.PX = '2' THEN
                'G0903_2_C'
               WHEN T.PX = '3' THEN
                'G0903_3_C'
               WHEN T.PX = '4' THEN
                'G0903_4_C'
               WHEN T.PX = '5' THEN
                'G0903_5_C'
               WHEN T.PX = '6' THEN
                'G0903_6_C'
               WHEN T.PX = '7' THEN
                'G0903_7_C'
               WHEN T.PX = '8' THEN
                'G0903_8_C'
               WHEN T.PX = '9' THEN
                'G0903_9_C'
               WHEN T.PX = '10' THEN
                'G0903_10_C'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             T.TYSHXYDM AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0903_DATA_COLLECT_TMP T;
    COMMIT;

    --前十大合作机构   D 合作机构服务类型
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G0903' AS REP_NUM,
             CASE
               WHEN T.PX = '1' THEN
                'G0903_1_D'
               WHEN T.PX = '2' THEN
                'G0903_2_D'
               WHEN T.PX = '3' THEN
                'G0903_3_D'
               WHEN T.PX = '4' THEN
                'G0903_4_D'
               WHEN T.PX = '5' THEN
                'G0903_5_D'
               WHEN T.PX = '6' THEN
                'G0903_6_D'
               WHEN T.PX = '7' THEN
                'G0903_7_D'
               WHEN T.PX = '8' THEN
                'G0903_8_D'
               WHEN T.PX = '9' THEN
                'G0903_9_D'
               WHEN T.PX = '10' THEN
                'G0903_10_D'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             T.HZJGFWLX AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0903_DATA_COLLECT_TMP T;
    COMMIT;

    --前十大合作机构   E 填报机构发放贷款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G0903' AS REP_NUM,
             CASE
               WHEN T.PX = '1' THEN
                'G0903_1_E'
               WHEN T.PX = '2' THEN
                'G0903_2_E'
               WHEN T.PX = '3' THEN
                'G0903_3_E'
               WHEN T.PX = '4' THEN
                'G0903_4_E'
               WHEN T.PX = '5' THEN
                'G0903_5_E'
               WHEN T.PX = '6' THEN
                'G0903_6_E'
               WHEN T.PX = '7' THEN
                'G0903_7_E'
               WHEN T.PX = '8' THEN
                'G0903_8_E'
               WHEN T.PX = '9' THEN
                'G0903_9_E'
               WHEN T.PX = '10' THEN
                'G0903_10_E'
             END AS ITEM_NUM,
             T.TBJGDKYE AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0903_DATA_COLLECT_TMP T;
    COMMIT;

    --前十大合作机构   F 不良贷款率
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G0903' AS REP_NUM,
             CASE
               WHEN T.PX = '1' THEN
                'G0903_1_F'
               WHEN T.PX = '2' THEN
                'G0903_2_F'
               WHEN T.PX = '3' THEN
                'G0903_3_F'
               WHEN T.PX = '4' THEN
                'G0903_4_F'
               WHEN T.PX = '5' THEN
                'G0903_5_F'
               WHEN T.PX = '6' THEN
                'G0903_6_F'
               WHEN T.PX = '7' THEN
                'G0903_7_F'
               WHEN T.PX = '8' THEN
                'G0903_8_F'
               WHEN T.PX = '9' THEN
                'G0903_9_F'
               WHEN T.PX = '10' THEN
                'G0903_10_F'
             END AS ITEM_NUM,
             T.BLDKL AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0903_DATA_COLLECT_TMP T;
    COMMIT;

    --前十大合作机构   G 发放贷款逾期率
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G0903' AS REP_NUM,
             CASE
               WHEN T.PX = '1' THEN
                'G0903_1_G'
               WHEN T.PX = '2' THEN
                'G0903_2_G'
               WHEN T.PX = '3' THEN
                'G0903_3_G'
               WHEN T.PX = '4' THEN
                'G0903_4_G'
               WHEN T.PX = '5' THEN
                'G0903_5_G'
               WHEN T.PX = '6' THEN
                'G0903_6_G'
               WHEN T.PX = '7' THEN
                'G0903_7_G'
               WHEN T.PX = '8' THEN
                'G0903_8_G'
               WHEN T.PX = '9' THEN
                'G0903_9_G'
               WHEN T.PX = '10' THEN
                'G0903_10_G'
             END AS ITEM_NUM,
             T.DKYQL AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0903_DATA_COLLECT_TMP T;
    COMMIT;

    --前十大合作机构   H 贷款平均利率
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G0903' AS REP_NUM,
             CASE
               WHEN T.PX = '1' THEN
                'G0903_1_H'
               WHEN T.PX = '2' THEN
                'G0903_2_H'
               WHEN T.PX = '3' THEN
                'G0903_3_H'
               WHEN T.PX = '4' THEN
                'G0903_4_H'
               WHEN T.PX = '5' THEN
                'G0903_5_H'
               WHEN T.PX = '6' THEN
                'G0903_6_H'
               WHEN T.PX = '7' THEN
                'G0903_7_H'
               WHEN T.PX = '8' THEN
                'G0903_8_H'
               WHEN T.PX = '9' THEN
                'G0903_9_H'
               WHEN T.PX = '10' THEN
                'G0903_10_H'
             END AS ITEM_NUM,
             T.DKPJLV AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0903_DATA_COLLECT_TMP T;
    COMMIT;

    V_STEP_FLAG := V_STEP_ID + 1;
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
   
END proc_cbrc_idx2_g0903