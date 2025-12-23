CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s7103(II_DATADATE  IN STRING --跑批日期
                                                   )
/******************************
  @AUTHOR:HMC
  @CREATE-DATE:20210616
  @DESCRIPTION:S7103
  M1.授信额度剔除磐石机构的授信额度
  M2.20231011.ZJM.对涉及累放的指标进行开发，将村镇铺底数据逻辑放进去
  m3 20250318 2025年制度升级
  
  cbrc_a_rept_item_val
cbrc_l_agre_creditline_test_7103
cbrc_s7103_amt_tmp1_cz
cbrc_s7103_amt_tmp2_cz
cbrc_s7103_temp2
pboc_jzfpdk
smtmods_l_acct_loan
smtmods_l_acct_loan_farming
smtmods_v_pub_idx_dk_xfsx

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
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE := II_DATADATE;
    V_SYSTEM   := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_S7103');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
				
    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'S7103'
       AND T.FLAG = '2';
    COMMIT;


    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_L_AGRE_CREDITLINE_TEST_7103';
    COMMIT;

    INSERT INTO CBRC_L_AGRE_CREDITLINE_TEST_7103 ---统一授信临时表
      (DATA_DATE, CUST_ID, FACILITY_AMT)
   SELECT DATA_DATE, CUST_ID, FACILITY_AMT
     FROM SMTMODS_V_PUB_IDX_DK_XFSX
    WHERE DATA_DATE = I_DATADATE;

    COMMIT;

    ---------------------------加工当年累计
    --年初删除本年累计
    IF SUBSTR(I_DATADATE, 5, 2) = 01 THEN

      EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S7103_TEMP2';
    COMMIT;

    ELSE
      EXECUTE IMMEDIATE ('DELETE FROM  CBRC_S7103_TEMP2 T WHERE  T.DATA_DATE = ' || '''' ||
                        I_DATADATE || '''' || ''); --删除当前日期数据 ADD BY CHM 20210729
    END IF;

       INSERT INTO CBRC_S7103_TEMP2
       SELECT 
       ORG_NUM AS ORG_NUM, --机构号
       T.CUST_ID, --客户号
       T.FACILITY_AMT FACILITY_AMT, --授信金额
       A.DRAWDOWN_AMT LOAN_ACCT_BAL, --余额
       A.DRAWDOWN_AMT * A.REAL_INT_RAT / 100 NHSY, --年化收益
       A.LOAN_NUM, --借据号
       I_DATADATE
        FROM SMTMODS_V_PUB_IDX_DK_XFSX T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND TO_CHAR(A.DRAWDOWN_DT,'YYYYMMDD') =T.DATA_DATE
         AND A.DATA_DATE = I_DATADATE
       WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
             A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
         AND A.ACCT_TYP NOT LIKE '010301'
         AND (A.LOAN_PURPOSE_CD IS NULL OR A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
         AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
        -- AND T.FACILITY_AMT <= 100000  --20250318  2025年制度升级
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) =
             SUBSTR(I_DATADATE, 1, 6);
    --------------------------1.普惠型消费性贷款--------------------------------------------------------

    --贷款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 and  c.FACILITY_AMT <= 100000 THEN
                'S7103_1.A2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.A1'
               when C.FACILITY_AMT > 100000 then   --20250318 2025年制度升级
                'S7103_1.A3.2025'
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
                -- AND T.FACILITY_AMT <= 100000  --20250318 2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
                  WHEN C.FACILITY_AMT > 10000 and c.FACILITY_AMT <= 100000 THEN
                   'S7103_1.A2'
                  WHEN C.FACILITY_AMT <= 10000 THEN
                   'S7103_1.A1'
                  when C.FACILITY_AMT > 100000 then   --20250318 2025年制度升级
                'S7103_1.A3.2025'
                END;

    --贷款余额户数

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 AND c.FACILITY_AMT <= 100000  THEN
                'S7103_1.B2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.B1'
               when C.FACILITY_AMT > 100000 then
                'S7103_1.B3.2025'  --20250318 制度升级
             END AS ITEM_NUM, --指标号
             COUNT(1) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.LOAN_ACCT_BAL > 0
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
                 -- AND T.FACILITY_AMT <= 100000  --20250318 2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
                  WHEN C.FACILITY_AMT > 10000 AND c.FACILITY_AMT <= 100000 THEN
                   'S7103_1.B2'
                  WHEN C.FACILITY_AMT <= 10000 THEN
                   'S7103_1.B1'
                  when C.FACILITY_AMT > 100000 then
                   'S7103_1.B3.2025'  --20250318 2025制度升级
                END;

    --不良贷款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                'S7103_1.C2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.C1'
                WHEN C.FACILITY_AMT > 100000 THEN
                 'S7103_1.C3.2025'     --20250318 2025制度升级
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
                 --AND T.FACILITY_AMT <= 100000  --20250318 2025制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
                  WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                   'S7103_1.C2'
                  WHEN C.FACILITY_AMT <= 10000 THEN
                   'S7103_1.C1'
                   WHEN C.FACILITY_AMT > 100000 THEN
                 'S7103_1.C3.2025'     --20250318 2025制度升级
                END;

    --当年累放贷款额

    
      INSERT INTO CBRC_A_REPT_ITEM_VAL 
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值（数值型）
         FLAG --标志位
         )
        SELECT I_DATADATE, --数据日期
               ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'S7103' AS REP_NUM, --报表编号
               CASE
                 WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000 THEN
                  'S7103_1.D2'
                 WHEN C.FACILITY_AMT <= 10000 THEN
                  'S7103_1.D1'
                 WHEN C.FACILITY_AMT > 100000  THEN
                  'S7103_1.D3.2025'  --20250318 2025年制度升级
               END AS ITEM_NUM, --指标号
               SUM(DRAWDOWN_AMT) AS ITEM_VAL, --指标值（数值型）
               '2' --标志位
          FROM (SELECT 
                 ORG_NUM        AS ORG_NUM, --机构号
                 T.CUST_ID, --客户号
                 T.FACILITY_AMT FACILITY_AMT, --授信金额
                 T.DRAWDOWN_AMT --放款金额
                  FROM CBRC_S7103_TEMP2 T) C
         GROUP BY ORG_NUM,
                  CASE
                    WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000  THEN
                     'S7103_1.D2'
                    WHEN C.FACILITY_AMT <= 10000 THEN
                     'S7103_1.D1'
                    WHEN C.FACILITY_AMT > 100000  THEN
                     'S7103_1.D3.2025'
                  END;
      COMMIT;


    --当年累放贷款户数
    
      INSERT INTO CBRC_A_REPT_ITEM_VAL 
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值（数值型）
         FLAG --标志位
         )
        SELECT I_DATADATE, --数据日期
               ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'S7103' AS REP_NUM, --报表编号
               CASE
                 WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000 THEN
                  'S7103_1.E2'
                 WHEN C.FACILITY_AMT <= 10000 THEN
                  'S7103_1.E1'
                 WHEN C.FACILITY_AMT > 100000 THEN
                  'S7103_1.E3.2025'    --20250318 2025年制度升级
               END AS ITEM_NUM, --指标号
               COUNT(DISTINCT CUST_ID) AS ITEM_VAL, --指标值（数值型）
               '2' --标志位
          FROM (SELECT 
                 ORG_NUM        AS ORG_NUM, --机构号
                 T.CUST_ID, --客户号
                 T.FACILITY_AMT FACILITY_AMT, --授信金额
                 T.DRAWDOWN_AMT --放款金额
                  FROM CBRC_S7103_TEMP2 T) C
         GROUP BY ORG_NUM,
                  CASE
                    WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000 THEN
                     'S7103_1.E2'
                    WHEN C.FACILITY_AMT <= 10000 THEN
                     'S7103_1.E1'
                    WHEN C.FACILITY_AMT > 100000 THEN
                     'S7103_1.E3.2025'
                  END;
      COMMIT;
  

    --当年累放贷款年化收益

    
      INSERT INTO CBRC_A_REPT_ITEM_VAL 
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值（数值型）
         FLAG --标志位
         )
        SELECT I_DATADATE, --数据日期
               ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'S7103' AS REP_NUM, --报表编号
               CASE
                 WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                  'S7103_1.F2'
                 WHEN C.FACILITY_AMT <= 10000 THEN
                  'S7103_1.F1'
                 WHEN C.FACILITY_AMT > 100000 THEN
                  'S7103_1.F3.2025'      --20250318 2025年制度升级
               END AS ITEM_NUM, --指标号
               SUM(NHSY) AS ITEM_VAL, --指标值（数值型）
               '2' --标志位
          FROM (SELECT 
                 ORG_NUM        AS ORG_NUM, --机构号
                 T.CUST_ID, --客户号
                 T.FACILITY_AMT FACILITY_AMT, --授信金额
                 T.DRAWDOWN_AMT, --放款金额
                 T.NHSY --年化收益
                  FROM CBRC_S7103_TEMP2 T) C
         GROUP BY ORG_NUM,
                  CASE
                    WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                     'S7103_1.F2'
                    WHEN C.FACILITY_AMT <= 10000 THEN
                     'S7103_1.F1'
                    WHEN C.FACILITY_AMT > 100000 THEN
                     'S7103_1.F3.2025'
                  END;
      COMMIT;

    -------------------------------  1.3其中：普惠型农户消费贷款------------------------------------------
    --合计
    --合计 贷款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             'S7103_1.3.A' AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充 --20250318  2025年制度升级
              -- ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生
                  ON A.DATA_DATE = F.DATA_DATE
                 AND A.LOAN_NUM = F.LOAN_NUM
                -- AND F.AGREI_P_FLG = 'Y'
                 and F.SNDKFL = 'P_102'
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
                -- AND T.FACILITY_AMT <= 100000  --20250318  2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM;

    --合计 贷款余额户数

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             'S7103_1.3.B' AS ITEM_NUM, --指标号
             COUNT(1) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充  --20250318  2025年制度升级
              -- ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生
                  ON A.DATA_DATE = F.DATA_DATE
                 AND A.LOAN_NUM = F.LOAN_NUM
                 --AND F.AGREI_P_FLG = 'Y'
                 and F.SNDKFL = 'P_102'
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.LOAN_ACCT_BAL > 0
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
               --  AND T.FACILITY_AMT <= 100000  --20250318  2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM;

    --合计  不良贷款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             'S7103_1.3.C' AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充  --20250318  2025年制度升级
              /* ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
                  ON A.DATA_DATE = F.DATA_DATE
                 AND A.LOAN_NUM = F.LOAN_NUM
                 --AND F.AGREI_P_FLG = 'Y'
                 and F.SNDKFL = 'P_102'
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
                 --AND T.FACILITY_AMT <= 100000  --20250318  2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM;

    --合计 当年累放贷款额

    
      INSERT INTO CBRC_A_REPT_ITEM_VAL 
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值（数值型）
         FLAG --标志位
         )
        SELECT I_DATADATE, --数据日期
               ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'S7103' AS REP_NUM, --报表编号
               'S7103_1.3.D' AS ITEM_NUM, --指标号
               SUM(DRAWDOWN_AMT) AS ITEM_VAL, --指标值（数值型）
               '2' --标志位
          FROM (SELECT 
                 ORG_NUM        AS ORG_NUM, --机构号
                 T.CUST_ID, --客户号
                 T.FACILITY_AMT FACILITY_AMT, --授信金额
                 T.DRAWDOWN_AMT --放款金额
                  FROM CBRC_S7103_TEMP2 T
                 INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
                -- ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生
                    ON F.DATA_DATE = I_DATADATE
                   AND T.LOAN_NUM = F.LOAN_NUM
                  -- AND F.AGREI_P_FLG = 'Y'
                    AND F.SNDKFL = 'P_102'
                   ) C
         GROUP BY ORG_NUM;
      COMMIT;


    --合计 当年累放贷款户数

    
      INSERT INTO CBRC_A_REPT_ITEM_VAL 
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值（数值型）
         FLAG --标志位
         )
        SELECT I_DATADATE, --数据日期
               ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'S7103' AS REP_NUM, --报表编号
               'S7103_1.3.E' AS ITEM_NUM, --指标号
               COUNT(DISTINCT CUST_ID) AS ITEM_VAL, --指标值（数值型）
               '2' --标志位
          FROM (SELECT 
                 ORG_NUM        AS ORG_NUM, --机构号
                 T.CUST_ID, --客户号
                 T.FACILITY_AMT FACILITY_AMT, --授信金额
                 T.DRAWDOWN_AMT --放款金额
                  FROM CBRC_S7103_TEMP2 T
                 INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
                -- ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生
                    ON F.DATA_DATE = I_DATADATE
                   AND T.LOAN_NUM = F.LOAN_NUM
                   --AND F.AGREI_P_FLG = 'Y'
                    AND F.SNDKFL = 'P_102'
                   ) C
         GROUP BY ORG_NUM;
      COMMIT;


    --合计 当年累放贷款年化收益
    
      INSERT INTO CBRC_A_REPT_ITEM_VAL 
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值（数值型）
         FLAG --标志位
         )
        SELECT I_DATADATE, --数据日期
               ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'S7103' AS REP_NUM, --报表编号
               'S7103_1.3.F' AS ITEM_NUM, --指标号
               SUM(NHSY) AS ITEM_VAL, --指标值（数值型）
               '2' --标志位
          FROM (SELECT 
                 ORG_NUM        AS ORG_NUM, --机构号
                 T.CUST_ID, --客户号
                 T.FACILITY_AMT FACILITY_AMT, --授信金额
                 T.DRAWDOWN_AMT, --放款金额
                 T.NHSY --年化收益
                  FROM CBRC_S7103_TEMP2 T
                 INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
                -- ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生
                    ON F.DATA_DATE = I_DATADATE
                   AND T.LOAN_NUM = F.LOAN_NUM
                 --  AND F.AGREI_P_FLG = 'Y'
                   AND F.SNDKFL = 'P_102'
                   ) C
         GROUP BY ORG_NUM;
      COMMIT;

    ---------------------------------
    --贷款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.A2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.A1'
               WHEN  C.FACILITY_AMT > 100000 THEN
                'S7103_1.3.A3.2025'   --20250318  2025年制度升级
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充   --20250318  2025年制度升级
               /*ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
                  ON A.DATA_DATE = F.DATA_DATE
                 AND A.LOAN_NUM = F.LOAN_NUM
               --  AND F.AGREI_P_FLG = 'Y'
                and F.SNDKFL = 'P_102'
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
                -- AND T.FACILITY_AMT <= 100000   --20250318  2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
                  WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                   'S7103_1.3.A2'
                  WHEN C.FACILITY_AMT <= 10000 THEN
                   'S7103_1.3.A1'
                  WHEN  C.FACILITY_AMT > 100000 THEN
                   'S7103_1.3.A3.2025'
                END;

    --贷款余额户数

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000  and C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.B2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.B1'
                WHEN C.FACILITY_AMT > 100000 then
                  'S7103_1.3.B3.2025'    --20250318  2025年制度升级
             END AS ITEM_NUM, --指标号
             COUNT(1) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充  --20250318  2025年制度升级
               /*ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
                  ON A.DATA_DATE = F.DATA_DATE
                 AND A.LOAN_NUM = F.LOAN_NUM
                -- AND F.AGREI_P_FLG = 'Y'
                  and F.SNDKFL = 'P_102'
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.LOAN_ACCT_BAL > 0
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
                 --AND T.FACILITY_AMT <= 100000 ----20250318  2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
                  WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000 THEN
                   'S7103_1.3.B2'
                  WHEN C.FACILITY_AMT <= 10000 THEN
                   'S7103_1.3.B1'
                  WHEN C.FACILITY_AMT > 100000 then
                  'S7103_1.3.B3.2025'
                END;

    --不良贷款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.C2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.C1'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.3.C3.2025'
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
               /*ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
                  ON A.DATA_DATE = F.DATA_DATE
                 AND A.LOAN_NUM = F.LOAN_NUM
                 --AND F.AGREI_P_FLG = 'Y'
                 and F.SNDKFL = 'P_102'
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
                 --AND T.FACILITY_AMT <= 100000
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
               WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.C2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.C1'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.3.C3.2025'
                END;

    --当年累放贷款额
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.D2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.D1'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.3.D3.2025'
             END AS ITEM_NUM, --指标号
             SUM(DRAWDOWN_AMT) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM        AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               T.FACILITY_AMT FACILITY_AMT, --授信金额
               T.DRAWDOWN_AMT --放款金额
                FROM CBRC_S7103_TEMP2 T
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
              -- ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生
                  ON F.DATA_DATE =I_DATADATE
                 AND T.LOAN_NUM = F.LOAN_NUM
               --  AND F.AGREI_P_FLG = 'Y'
                 AND F.SNDKFL = 'P_102'
                 ) C
       GROUP BY ORG_NUM,
                CASE
               WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.D2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.D1'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.3.D3.2025'
             END;

    --当年累放贷款户数
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.E2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.E1'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.3.E3.2025'
             END AS ITEM_NUM, --指标号
             COUNT(DISTINCT CUST_ID) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM        AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               T.FACILITY_AMT FACILITY_AMT, --授信金额
               T.DRAWDOWN_AMT --放款金额
                FROM CBRC_S7103_TEMP2 T
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
             ---  ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生
                  ON F.DATA_DATE = I_DATADATE
                 AND T.LOAN_NUM = F.LOAN_NUM
                -- AND F.AGREI_P_FLG = 'Y'
                  AND F.SNDKFL = 'P_102'
                 ) C
       GROUP BY ORG_NUM,
                CASE
               WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.E2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.E1'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.3.E3.2025'
             END;

    --当年累放贷款年化收益
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.F2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.F1'
                WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.3.F3.2025'
             END AS ITEM_NUM, --指标号
             SUM(NHSY) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM        AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               T.FACILITY_AMT FACILITY_AMT, --授信金额
               T.DRAWDOWN_AMT, --放款金额
               T.NHSY --年化收益
                FROM CBRC_S7103_TEMP2 T
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
              -- ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生
                  ON F.DATA_DATE = I_DATADATE
                 AND T.LOAN_NUM = F.LOAN_NUM
               --  AND F.AGREI_P_FLG = 'Y'
                  AND F.SNDKFL = 'P_102'
                 ) C
       GROUP BY ORG_NUM,
                CASE
               WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.F2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.F1'
                WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.3.F3.2025'
             END;
      ---20250318 2025年制度升级 1.3.1其中：建档立卡贫困户消费贷款 及1.4其中：低保户消费贷款 指标已删除，注释
   
    --20250318 2025年制度升级新增指标附注：1.4原建档立卡贫困人口消费贷款

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             'S7103_1.4.A.2025' AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
          

               INNER JOIN PBOC_JZFPDK RR
                 ON A.LOAN_NUM =RR.LOAN_NUM
                 AND RR.DATA_DATE =I_DATADATE


               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM;
       COMMIT;

    --合计   贷款余额户数
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             'S7103_1.4.B.2025' AS ITEM_NUM, --指标号
             COUNT(1) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT
              A. ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
              /* INNER JOIN L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
                  ON A.LOAN_NUM = R.LOAN_NUM
                 AND A.DATA_DATE = R.DATA_DATE
                 AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
                 */
                 INNER JOIN pboc_jzfpdk RR
                 ON A.LOAN_NUM =RR.LOAN_NUM
                 AND RR.DATA_DATE =I_DATADATE
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.LOAN_ACCT_BAL > 0
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM;
       COMMIT;
    --合计  不良贷款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             'S7103_1.4.C.2025' AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               /*INNER JOIN L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
                  ON A.LOAN_NUM = R.LOAN_NUM
                 AND A.DATA_DATE = R.DATA_DATE
                 AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
                 */
                 INNER JOIN pboc_jzfpdk RR
                 ON A.LOAN_NUM =RR.LOAN_NUM
                 AND RR.DATA_DATE =I_DATADATE
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM;
       COMMIT;

    --合计 当年累放贷款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             'S7103_1.4.D.2025' AS ITEM_NUM, --指标号
             SUM(DRAWDOWN_AMT) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               T.ORG_NUM        AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               T.FACILITY_AMT FACILITY_AMT, --授信金额
               T.DRAWDOWN_AMT, --放款金额
               T.NHSY --年化收益
                FROM CBRC_S7103_TEMP2 T
               /*INNER JOIN L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
                  ON T.LOAN_NUM = R.LOAN_NUM
                 AND  R.DATA_DATE =I_DATADATE
                 AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
                 */
                 INNER JOIN pboc_jzfpdk RR
                 ON T.LOAN_NUM =RR.LOAN_NUM
                 AND RR.DATA_DATE =I_DATADATE
              ) C
       GROUP BY ORG_NUM;
        COMMIT;

    --合计 当年累放贷款户数
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             'S7103_1.4.E.2025', --指标号
             COUNT(DISTINCT CUST_ID) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               t.ORG_NUM        AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               T.FACILITY_AMT FACILITY_AMT, --授信金额
               T.DRAWDOWN_AMT, --放款金额
               T.NHSY --年化收益
                FROM CBRC_S7103_TEMP2 T
                /*
               INNER JOIN L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
                  ON T.LOAN_NUM = R.LOAN_NUM
                 AND  R.DATA_DATE = I_DATADATE
                 AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
                 */
                  INNER JOIN pboc_jzfpdk RR
                 ON T.LOAN_NUM =RR.LOAN_NUM
                 AND RR.DATA_DATE =I_DATADATE
              ) C
       GROUP BY ORG_NUM;
       COMMIT;

    --合计 当年累放贷款年化收益
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             c.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             'S7103_1.4.F.2025', --指标号
             SUM(NHSY) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               t.ORG_NUM        AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               T.FACILITY_AMT FACILITY_AMT, --授信金额
               T.DRAWDOWN_AMT, --放款金额
               T.NHSY --年化收益
                FROM CBRC_S7103_TEMP2 T
                /*
               INNER JOIN L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
                  ON T.LOAN_NUM = R.LOAN_NUM
                 AND  R.DATA_DATE = I_DATADATE
                 AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
                 */
                 INNER JOIN pboc_jzfpdk RR
                 ON T.LOAN_NUM =RR.LOAN_NUM
                 AND RR.DATA_DATE =I_DATADATE
              ) C
       GROUP BY ORG_NUM;
    COMMIT;
    --贷款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 AND  C.FACILITY_AMT <= 100000 THEN
                'S7103_1.4.A2.2025'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.4.A1.2025'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.4.A3.2025'
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               a.ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
              /* INNER JOIN L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
                  ON A.LOAN_NUM = R.LOAN_NUM
                 AND A.DATA_DATE = R.DATA_DATE
                 AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
                 */
                  INNER JOIN pboc_jzfpdk RR
                 ON a.LOAN_NUM =RR.LOAN_NUM
                 AND RR.DATA_DATE =I_DATADATE
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
               WHEN C.FACILITY_AMT > 10000 AND  C.FACILITY_AMT <= 100000 THEN
                'S7103_1.4.A2.2025'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.4.A1.2025'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.4.A3.2025'
             END;
             COMMIT;

    --贷款余额户数
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 AND  C.FACILITY_AMT <= 100000 THEN
                'S7103_1.4.B2.2025'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.4.B1.2025'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.4.B3.2025'
                END AS ITEM_NUM, --指标号
             COUNT(1) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               a.ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
              /* INNER JOIN L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
                  ON A.LOAN_NUM = R.LOAN_NUM
                 AND A.DATA_DATE = R.DATA_DATE
                 AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
               */
                INNER JOIN pboc_jzfpdk RR
                 ON a.LOAN_NUM =RR.LOAN_NUM
                 AND RR.DATA_DATE =I_DATADATE
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.LOAN_ACCT_BAL > 0
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
               WHEN C.FACILITY_AMT > 10000 AND  C.FACILITY_AMT <= 100000 THEN
                'S7103_1.4.B2.2025'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.4.B1.2025'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.4.B3.2025'
                END;
         COMMIT;
    --不良贷款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 AND  C.FACILITY_AMT <= 100000 THEN
                'S7103_1.4.C2.2025'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.4.C1.2025'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.4.C3.2025'
                END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               a.ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
              /* INNER JOIN L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
                  ON A.LOAN_NUM = R.LOAN_NUM
                 AND A.DATA_DATE = R.DATA_DATE
                 AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
                  */
                   INNER JOIN pboc_jzfpdk RR
                 ON a.LOAN_NUM =RR.LOAN_NUM
                 AND RR.DATA_DATE =I_DATADATE
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
               WHEN C.FACILITY_AMT > 10000 AND  C.FACILITY_AMT <= 100000 THEN
                'S7103_1.4.C2.2025'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.4.C1.2025'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.4.C3.2025'
                END;
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
   
END proc_cbrc_idx2_s7103