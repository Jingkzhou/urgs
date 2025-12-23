CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g0902(II_DATADATE  IN STRING --跑批日期
                                                   )
/******************************
  @AUTHOR:87v
  @CREATE-DATE:202307
  @DESCRIPTION:G09_II 前十大共同出资发放互联网贷款情况表
   m1.20241224 shiyu 修改内容：修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
                             如果是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款在逾期时间90天以内的取逾期部分，逾期90天以上的取贷款余额



目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_G0902_DATA_COLLECT_TMP
     CBRC_G0902_TMP_BLDKYE
     CBRC_G0902_TMP_LX
     CBRC_G0902_TMP_TOP10
     CBRC_G0902_TMP_YQYE
     CBRC_G0902_TM_L_ORG_FLAT
     CBRC_UPRR_U_BASE_INST   --1104系统机构树表
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
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G0902');
    V_TAB_NAME  := 'G0902';

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']G0902当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G0902_DATA_COLLECT_TMP';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G0902_TMP_TOP10';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G0902_TMP_BLDKYE';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G0902_TMP_YQYE';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G0902_TMP_LX';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G0902_TM_L_ORG_FLAT'; --处理机构，用于汇总

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G0902';
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '处理机构层级汇总';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --递归找到所有上级
    FOR DBANK IN (SELECT INST_ID FROM CBRC_UPRR_U_BASE_INST) LOOP
      INSERT INTO CBRC_G0902_TM_L_ORG_FLAT
        (ORG_CODE, SUB_ORG_CODE)
        SELECT DISTINCT PARENT_INST_ID, INST_ID
          FROM (SELECT PARENT_INST_ID, DBANK.INST_ID AS INST_ID
                  FROM CBRC_UPRR_U_BASE_INST
                 WHERE PARENT_INST_ID IS NOT NULL
                 START WITH INST_ID = DBANK.INST_ID
                CONNECT BY PRIOR PARENT_INST_ID = INST_ID
                UNION ALL
                SELECT DBANK.INST_ID, DBANK.INST_ID
                  FROM system.DUAL);
      COMMIT;
    END LOOP;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '处理机构层级汇总完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：加载临时表数据开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --临时表：取共同出资发放贷款余额前十大合作机构
    INSERT 
    INTO CBRC_G0902_TMP_TOP10 
      (XH, ORG_NUM, COOP_CUST_ID, COOP_TYPE, LOAN_BAL,TOTAL_LOAN_BAL, COOP_LOAN_BAL)
      SELECT  
       rownum, 
       ORG_NUM,
       COOP_CUST_ID,
       COOP_TYPE,
       LOAN_BAL,
       TOTAL_LOAN_BAL,
       COOP_LOAN_BAL
  FROM (
SELECT 
       ORG_NUM,
       COOP_CUST_ID,
       COOP_TYPE,
       LOAN_BAL,
       TOTAL_LOAN_BAL,
       COOP_LOAN_BAL,
       ROW_NUMBER() OVER (ORDER BY TOTAL_LOAN_BAL) AS rownum
        FROM (SELECT 
               A.ORG_NUM,
               A.COOP_CUST_ID, --合作方客户号
               A.COOP_TYPE, --合作方式
               SUM(A.TOTAL_LOAN_BAL) AS LOAN_BAL, --E 我行发放贷款余额
               SUM(A.TOTAL_LOAN_BAL/0.7 * U.CCY_RATE) AS TOTAL_LOAN_BAL, --共同出资贷款余额
               SUM(A.TOTAL_LOAN_BAL/0.7*0.3 * U.CCY_RATE) AS COOP_LOAN_BAL --合作方出资贷款余额
                FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
                LEFT JOIN SMTMODS_L_ACCT_LOAN B --贷款借据信息表
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
                 AND U.CCY_DATE = I_DATADATE
               WHERE A.INTERNET_LOAN_TYP IN ('B', 'C') -- 共同出资：B线上联合贷款 C同属商业银行互联网贷款和线上联合贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
                 AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
                     OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
                     OR B.ACCT_TYP = '0202') --流动资金贷款
                 AND B.ACCT_STS <> '3' --账户状态未结清
                 AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.LOAN_STOCKEN_DATE IS NULL     --add by haorui 20250311 JLBA202408200012 资产未转让
               GROUP BY A.ORG_NUM, A.COOP_CUST_ID, A.COOP_TYPE)
) WHERE ROWNUM <=10
ORDER BY ROWNUM DESC
;
    COMMIT;

    --临时表：H 填报机构不良贷款余额
    --储存前十大合作机构的填报机构不良贷款余额

    INSERT  INTO CBRC_G0902_TMP_BLDKYE 
      (ORG_NUM, COOP_CUST_ID, BLDKYE)
      SELECT 
       A.ORG_NUM,
       A.COOP_CUST_ID, --合作方机构号
       SUM(A.TOTAL_LOAN_BAL * U.CCY_RATE) AS BLDKYE --填报机构不良贷款 = 共同出资-合作方出资
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
         AND B.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.COOP_CUST_ID IN (SELECT COOP_CUST_ID FROM CBRC_G0902_TMP_TOP10)
       GROUP BY A.ORG_NUM, A.COOP_CUST_ID;
    COMMIT;

    --临时表：I 共同出资发放贷款逾期率（逾期30天以上）
    --储存前十大合作机构逾期30天以上贷款余额

    INSERT  INTO CBRC_G0902_TMP_YQYE 
      (ORG_NUM, COOP_CUST_ID, YQYE)
      SELECT 
       A.ORG_NUM,
       A.COOP_CUST_ID, --合作方机构号
      /*alter by shiyu 20241105 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
            如果是按月分期还款的个人消费贷款本金或利息逾期 JLBA202412040012*/
      SUM(CASE WHEN  (ACCT_TYP LIKE '0101%' OR ACCT_TYP LIKE '0103%' OR
             ACCT_TYP LIKE '0104%' OR ACCT_TYP LIKE '0199%' ) AND B.OD_DAYS <=90 and B.REPAY_TYP ='1' and  B.PAY_TYPE in   ('01','02','10','11')
      THEN B.OD_LOAN_ACCT_BAL* U.CCY_RATE
      ELSE B.LOAN_ACCT_BAL* U.CCY_RATE END ) AS YQYE --逾期30天以上贷款余额
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
         AND B.OD_DAYS > 30 --逾期30天以上
         AND A.COOP_CUST_ID IN (SELECT COOP_CUST_ID FROM CBRC_G0902_TMP_TOP10)
       GROUP BY A.ORG_NUM, A.COOP_CUST_ID;
    COMMIT;

    --临时表：J 贷款平均利率
    --储存前十大合作机构贷款余额利息之和
    INSERT  INTO CBRC_G0902_TMP_LX 
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
         AND A.COOP_CUST_ID IN (SELECT COOP_CUST_ID FROM CBRC_G0902_TMP_TOP10)
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
    -------------------------------------G0902 数据插至汇总表--------------------------------------------
    --=====================================================================================================---
    V_STEP_FLAG := V_STEP_ID + 1;
    V_STEP_DESC := '产生G0902数据，插至目标表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_G0902_DATA_COLLECT_TMP 
      (SEQ_NO, --排序
       ORG_NUM,
       CO1, --B 合作机构名称
       CO2, --C 统一社会信用代码
       CO3, --D 合作机构类型
       CO4, --E 共同出资发放贷款余额
       CO5, --F 合作机构出资占比
       CO6, --G 合作机构服务类型
       CO7, --H 不良贷款率
       CO8, --I 共同出资发放贷款逾期率
       CO9 --J 贷款平均利率
       )

      SELECT T2.SEQ_NO, --序号
             T2.ORG_NUM,
             T2.CO1,
             T2.CO2,
             T2.CO3,
             T2.CO4,
             T2.CO5,
             T2.CO6,
             T2.CO7,
             T2.CO8,
             T2.CO9
        FROM (SELECT T1.*,
                     ROW_NUMBER() OVER(PARTITION BY T1.ORG_NUM ORDER BY T1.CO1 DESC, T1.ORG_NUM, T1.CO1, T1.CO2, T1.CO6) AS SEQ_NO
                FROM (SELECT F.ORG_CODE AS ORG_NUM,
                             T.COOP_CUST_NAM AS CO1, --B 合作机构名称
                             T.COOP_ID_NO AS CO2, --C 统一社会信用代码
                             T.COOP_CUST_TYPE AS CO3, --D 合作机构类型
                             SUM(T.TOTAL_LOAN_BAL) AS CO4, --E 共同出资发放贷款余额
                             '0.3' CO5, --F 合作机构出资占比
                             T.COOP_TYPE CO6, --G 合作机构提供服务类型
                             SUM(T.BLDKYE) / SUM(T.LOAN_BAL) AS CO7, --H 不良贷款率
                             SUM(T.YQYE) / SUM(T.LOAN_BAL)* 100 AS CO8, --I 共同出资发放贷款逾期率 --alter by shiyu 逾期率需要乘100
                             SUM(T.LX) / SUM(T.LOAN_BAL) * 100 AS CO9 -- J 贷款平均利率
                        FROM (SELECT 
                               A.ORG_NUM,
                               A.COOP_CUST_NAM, --B 合作机构名称
                               A.COOP_ID_NO, --C 统一社会信用代码
                               CASE
                                 WHEN A.COOP_CUST_TYPE = 'A' THEN
                                  '商业银行'
                                 WHEN A.COOP_CUST_TYPE = 'B' THEN
                                  '信托公司'
                                 WHEN A.COOP_CUST_TYPE = 'C' THEN
                                  '消费金融公司'
                                 WHEN A.COOP_CUST_TYPE = 'D' THEN
                                  '小额贷款公司'
                                 WHEN A.COOP_CUST_TYPE = 'E' THEN
                                  '保险业金融机构'
                                 ELSE
                                  '其他'
                               END AS COOP_CUST_TYPE, --D 合作机构类型
                               SUM(B.LOAN_BAL) AS LOAN_BAL, --E 我行出资发放贷款余额
                               SUM(B.TOTAL_LOAN_BAL) AS TOTAL_LOAN_BAL, --E 共同出资发放贷款余额
                               SUM(B.COOP_LOAN_BAL) AS COOP_LOAN_BAL, --F 合作机构出资贷款余额
                               B.COOP_TYPE AS COOP_TYPE, --G 合作机构提供服务类型
                               SUM(NVL(C.BLDKYE,0)) AS BLDKYE, --H 填报机构不良贷款余额
                               SUM(NVL(D.YQYE,0)) AS YQYE, --I 共同出资发放贷款逾期金额
                               SUM(E.LX) AS LX --贷款利息总额
                                FROM SMTMODS_L_CUST_COOP_AGEN A --合作机构信息表
                               INNER JOIN CBRC_G0902_TMP_TOP10 B
                                  ON A.COOP_CUST_ID = B.COOP_CUST_ID
                               LEFT JOIN CBRC_G0902_TMP_BLDKYE C
                                  ON A.COOP_CUST_ID = C.COOP_CUST_ID
                               LEFT JOIN CBRC_G0902_TMP_YQYE D
                                  ON A.COOP_CUST_ID = D.COOP_CUST_ID
                               INNER JOIN CBRC_G0902_TMP_LX E
                                  ON A.COOP_CUST_ID = E.COOP_CUST_ID
                               WHERE A.DATA_DATE = I_DATADATE
                               GROUP BY A.ORG_NUM,
                                        A.COOP_CUST_NAM, --B 合作机构名称
                                        A.COOP_ID_NO, --C 统一社会信用代码
                                        CASE
                                          WHEN A.COOP_CUST_TYPE = 'A' THEN
                                           '商业银行'
                                          WHEN A.COOP_CUST_TYPE = 'B' THEN
                                           '信托公司'
                                          WHEN A.COOP_CUST_TYPE = 'C' THEN
                                           '消费金融公司'
                                          WHEN A.COOP_CUST_TYPE = 'D' THEN
                                           '小额贷款公司'
                                          WHEN A.COOP_CUST_TYPE = 'E' THEN
                                           '保险业金融机构'
                                          ELSE
                                           '其他'
                                        END,
                                        B.COOP_TYPE) T
                       INNER JOIN CBRC_G0902_TM_L_ORG_FLAT F
                          ON T.ORG_NUM = F.SUB_ORG_CODE
                       GROUP BY F.ORG_CODE,
                                T.COOP_CUST_NAM, --B 合作机构名称
                                T.COOP_ID_NO, --C 统一社会信用代码
                                T.COOP_CUST_TYPE, --D 合作机构类型
                                T.COOP_TYPE --G 合作机构提供服务类型
                      ) T1) T2;
    COMMIT;

    --前十大共同出资发放互联网贷款        B 合作机构名称
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
             'G0902' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G0902_1_B'
               WHEN T.SEQ_NO = '2' THEN
                'G0902_2_B'
               WHEN T.SEQ_NO = '3' THEN
                'G0902_3_B'
               WHEN T.SEQ_NO = '4' THEN
                'G0902_4_B'
               WHEN T.SEQ_NO = '5' THEN
                'G0902_5_B'
               WHEN T.SEQ_NO = '6' THEN
                'G0902_6_B'
               WHEN T.SEQ_NO = '7' THEN
                'G0902_7_B'
               WHEN T.SEQ_NO = '8' THEN
                'G0902_8_B'
               WHEN T.SEQ_NO = '9' THEN
                'G0902_9_B'
               WHEN T.SEQ_NO = '10' THEN
                'G0902_10_B'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             T.CO1 AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0902_DATA_COLLECT_TMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --前十大共同出资发放互联网贷款        C 统一社会信用代码
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
             'G0902' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G0902_1_C'
               WHEN T.SEQ_NO = '2' THEN
                'G0902_2_C'
               WHEN T.SEQ_NO = '3' THEN
                'G0902_3_C'
               WHEN T.SEQ_NO = '4' THEN
                'G0902_4_C'
               WHEN T.SEQ_NO = '5' THEN
                'G0902_5_C'
               WHEN T.SEQ_NO = '6' THEN
                'G0902_6_C'
               WHEN T.SEQ_NO = '7' THEN
                'G0902_7_C'
               WHEN T.SEQ_NO = '8' THEN
                'G0902_8_C'
               WHEN T.SEQ_NO = '9' THEN
                'G0902_9_C'
               WHEN T.SEQ_NO = '10' THEN
                'G0902_10_C'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             T.CO2 AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0902_DATA_COLLECT_TMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --前十大共同出资发放互联网贷款        D 合作机构类型
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
             'G0902' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G0902_1_D'
               WHEN T.SEQ_NO = '2' THEN
                'G0902_2_D'
               WHEN T.SEQ_NO = '3' THEN
                'G0902_3_D'
               WHEN T.SEQ_NO = '4' THEN
                'G0902_4_D'
               WHEN T.SEQ_NO = '5' THEN
                'G0902_5_D'
               WHEN T.SEQ_NO = '6' THEN
                'G0902_6_D'
               WHEN T.SEQ_NO = '7' THEN
                'G0902_7_D'
               WHEN T.SEQ_NO = '8' THEN
                'G0902_8_D'
               WHEN T.SEQ_NO = '9' THEN
                'G0902_9_D'
               WHEN T.SEQ_NO = '10' THEN
                'G0902_10_D'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             T.CO3 AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0902_DATA_COLLECT_TMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --前十大共同出资发放互联网贷款   E 共同出资发放贷款余额
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
             'G0902' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G0902_1_E'
               WHEN T.SEQ_NO = '2' THEN
                'G0902_2_E'
               WHEN T.SEQ_NO = '3' THEN
                'G0902_3_E'
               WHEN T.SEQ_NO = '4' THEN
                'G0902_4_E'
               WHEN T.SEQ_NO = '5' THEN
                'G0902_5_E'
               WHEN T.SEQ_NO = '6' THEN
                'G0902_6_E'
               WHEN T.SEQ_NO = '7' THEN
                'G0902_7_E'
               WHEN T.SEQ_NO = '8' THEN
                'G0902_8_E'
               WHEN T.SEQ_NO = '9' THEN
                'G0902_9_E'
               WHEN T.SEQ_NO = '10' THEN
                'G0902_10_E'
             END AS ITEM_NUM,
             T.CO4 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0902_DATA_COLLECT_TMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --前十大共同出资发放互联网贷款   F 合作机构出资占比
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
             'G0902' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G0902_1_F'
               WHEN T.SEQ_NO = '2' THEN
                'G0902_2_F'
               WHEN T.SEQ_NO = '3' THEN
                'G0902_3_F'
               WHEN T.SEQ_NO = '4' THEN
                'G0902_4_F'
               WHEN T.SEQ_NO = '5' THEN
                'G0902_5_F'
               WHEN T.SEQ_NO = '6' THEN
                'G0902_6_F'
               WHEN T.SEQ_NO = '7' THEN
                'G0902_7_F'
               WHEN T.SEQ_NO = '8' THEN
                'G0902_8_F'
               WHEN T.SEQ_NO = '9' THEN
                'G0902_9_F'
               WHEN T.SEQ_NO = '10' THEN
                'G0902_10_F'
             END AS ITEM_NUM,
             T.CO5 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0902_DATA_COLLECT_TMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --前十大共同出资发放互联网贷款   G 合作机构服务类型
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
             'G0902' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G0902_1_G'
               WHEN T.SEQ_NO = '2' THEN
                'G0902_2_G'
               WHEN T.SEQ_NO = '3' THEN
                'G0902_3_G'
               WHEN T.SEQ_NO = '4' THEN
                'G0902_4_G'
               WHEN T.SEQ_NO = '5' THEN
                'G0902_5_G'
               WHEN T.SEQ_NO = '6' THEN
                'G0902_6_G'
               WHEN T.SEQ_NO = '7' THEN
                'G0902_7_G'
               WHEN T.SEQ_NO = '8' THEN
                'G0902_8_G'
               WHEN T.SEQ_NO = '9' THEN
                'G0902_9_G'
               WHEN T.SEQ_NO = '10' THEN
                'G0902_10_G'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             T.CO6 AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0902_DATA_COLLECT_TMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --前十大共同出资发放互联网贷款   H 不良贷款率
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
             'G0902' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G0902_1_H'
               WHEN T.SEQ_NO = '2' THEN
                'G0902_2_H'
               WHEN T.SEQ_NO = '3' THEN
                'G0902_3_H'
               WHEN T.SEQ_NO = '4' THEN
                'G0902_4_H'
               WHEN T.SEQ_NO = '5' THEN
                'G0902_5_H'
               WHEN T.SEQ_NO = '6' THEN
                'G0902_6_H'
               WHEN T.SEQ_NO = '7' THEN
                'G0902_7_H'
               WHEN T.SEQ_NO = '8' THEN
                'G0902_8_H'
               WHEN T.SEQ_NO = '9' THEN
                'G0902_9_H'
               WHEN T.SEQ_NO = '10' THEN
                'G0902_10_H'
             END AS ITEM_NUM,
             T.CO7 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0902_DATA_COLLECT_TMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --前十大共同出资发放互联网贷款   I 共同出资发放贷款逾期率
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
             'G0902' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G0902_1_I'
               WHEN T.SEQ_NO = '2' THEN
                'G0902_2_I'
               WHEN T.SEQ_NO = '3' THEN
                'G0902_3_I'
               WHEN T.SEQ_NO = '4' THEN
                'G0902_4_I'
               WHEN T.SEQ_NO = '5' THEN
                'G0902_5_I'
               WHEN T.SEQ_NO = '6' THEN
                'G0902_6_I'
               WHEN T.SEQ_NO = '7' THEN
                'G0902_7_I'
               WHEN T.SEQ_NO = '8' THEN
                'G0902_8_I'
               WHEN T.SEQ_NO = '9' THEN
                'G0902_9_I'
               WHEN T.SEQ_NO = '10' THEN
                'G0902_10_I'
             END AS ITEM_NUM,
             T.CO8 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0902_DATA_COLLECT_TMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --前十大共同出资发放互联网贷款   J 贷款平均利率
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
             'G0902' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G0902_1_J'
               WHEN T.SEQ_NO = '2' THEN
                'G0902_2_J'
               WHEN T.SEQ_NO = '3' THEN
                'G0902_3_J'
               WHEN T.SEQ_NO = '4' THEN
                'G0902_4_J'
               WHEN T.SEQ_NO = '5' THEN
                'G0902_5_J'
               WHEN T.SEQ_NO = '6' THEN
                'G0902_6_J'
               WHEN T.SEQ_NO = '7' THEN
                'G0902_7_J'
               WHEN T.SEQ_NO = '8' THEN
                'G0902_8_J'
               WHEN T.SEQ_NO = '9' THEN
                'G0902_9_J'
               WHEN T.SEQ_NO = '10' THEN
                'G0902_10_J'
             END AS ITEM_NUM,
             T.CO9 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G0902_DATA_COLLECT_TMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    UPDATE CBRC_A_REPT_ITEM_VAL
       SET IS_TOTAL = 'N'
     WHERE DATA_DATE = I_DATADATE
       AND REP_NUM = 'G0902';

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
   
END proc_cbrc_idx2_g0902