CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g1803(II_DATADATE  IN STRING --跑批日期
                                                   )
/******************************
  @author:lixin04
  @create-date:2015-12-24
  @description:
  @modification history:
  m0.create-date-author-description
  m1.20160406.shenyunfei-处理CUST_ALL
  m2.20230821 shiyu alter by 金融市场部取数：地方政府债券投资按剩余期限划分
  M3.20231102 shiyu alter by 按照发行债券名称判断省份
  
目标表：CBRC_A_REPT_ITEM_VAL
依赖表：CBRC_JTDP_INTERF_PAYHSRCCASHYIELD  --收益率曲线表 落地表需要依赖数据
临时表：CBRC_PUB_DATA_COLLECT_G18_3
     CBRC_STOCK_HOLIDAY
     CBRC_STOCK_HOLIDAY_TEMP
集市表：SMTMODS_L_ACCT_FUND_INVEST
     SMTMODS_L_AGRE_BOND_INFO
     SMTMODS_L_CUST_ALL
     SMTMODS_L_PUBL_RATE
  
  *******************************/
 IS
  V_SCHEMA        VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE     VARCHAR(30); --当前储存过程名称
  V_TAB_NAME      VARCHAR(30); --目标表名
  I_DATADATE      STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE      VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_DATADATE_YEAR VARCHAR(10); --数据日期(字符型)YYYY
  D_DATADATE_CCY  STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID       INTEGER; --任务号
  V_STEP_DESC     VARCHAR(4000); --任务描述
  V_STEP_FLAG     INTEGER; --任务执行状态标识
  V_ERRORCODE     VARCHAR(20); --错误编码
  V_ERRORDESC     VARCHAR(280); --错误内容
  V_PER_NUM       VARCHAR(30); --报表编号
  D_ISSU_DT       STRING;
  II_STATUS       INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM        VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID       := 0;
    V_STEP_FLAG     := 0;
    V_STEP_DESC     := '参数初始化处理';
    V_PER_NUM       := 'G18_3';
    V_TAB_NAME      := 'CBRC_A_REPT_ITEM_VAL';
    I_DATADATE      := II_DATADATE;
    V_DATADATE      := I_DATADATE;
    V_DATADATE_YEAR := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY');
    D_DATADATE_CCY  := I_DATADATE;
    V_SYSTEM        := 'CBRC';
    --V_PROCEDURE     := UPPER('SP_CBRC_IDX2_G18_3');
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G1803');
    D_ISSU_DT   := TO_DATE('2014-09-21', 'YYYY-MM-DD');

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

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_PUB_DATA_COLLECT_G18_3';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_L_ACCT_FUND_INVEST_TMP1';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_STOCK_HOLIDAY';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_STOCK_HOLIDAY_TEMP';

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G18_3 '1..A-36..A'插入临时表
    --====================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '1..A-31..A';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
      (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE SUBSTR(CA.REGION_CD, 1, 2) --指标序号
         WHEN '11' THEN
          'G18_3_1..A'
         WHEN '12' THEN
          'G18_3_2..A'
         WHEN '13' THEN
          'G18_3_3..A'
         WHEN '14' THEN
          'G18_3_4..A'
         WHEN '15' THEN
          'G18_3_5..A'
         WHEN '21' THEN
          'G18_3_6..A'
         WHEN '22' THEN
          'G18_3_7..A'
         WHEN '23' THEN
          'G18_3_8..A'
         WHEN '31' THEN
          'G18_3_9..A'
         WHEN '32' THEN
          'G18_3_10..A'
         WHEN '33' THEN
          'G18_3_11..A'
         WHEN '34' THEN
          'G18_3_12..A'
         WHEN '35' THEN
          'G18_3_13..A'
         WHEN '36' THEN
          'G18_3_14..A'
         WHEN '37' THEN
          'G18_3_15..A'
         WHEN '41' THEN
          'G18_3_16..A'
         WHEN '42' THEN
          'G18_3_17..A'
         WHEN '43' THEN
          'G18_3_18..A'
         WHEN '44' THEN
          'G18_3_19..A'
         WHEN '45' THEN
          'G18_3_20..A'
         WHEN '46' THEN
          'G18_3_21..A'
         WHEN '50' THEN
          'G18_3_22..A'
         WHEN '51' THEN
          'G18_3_23..A'
         WHEN '52' THEN
          'G18_3_24..A'
         WHEN '53' THEN
          'G18_3_25..A'
         WHEN '54' THEN
          'G18_3_26..A'
         WHEN '61' THEN
          'G18_3_27..A'
         WHEN '62' THEN
          'G18_3_28..A'
         WHEN '63' THEN
          'G18_3_29..A'
         WHEN '64' THEN
          'G18_3_30..A'
         WHEN '65' THEN
          'G18_3_31..A'
       END AS ITEM_NUM,
       --指标值字段：a.账面余额（折人民币）A.FACE_VAL
       DECODE(A.CURR_CD, 'CNY', A.FACE_VAL, A.FACE_VAL * U.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_ALL CA
          ON A.INVEST_ID = CA.CUST_ID
         AND CA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND B.STOCK_PRO_TYPE = 'A'
         AND B.ISSU_ORG = 'A02'
         AND B.ISSU_DT > D_ISSU_DT;

    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '32..A-36..A';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
      (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE SUBSTR(CA.REGION_CD, 1, 4) --指标序号
         WHEN '3502' THEN
          'G18_3_32..A'
         WHEN '3702' THEN
          'G18_3_33..A'
         WHEN '2102' THEN
          'G18_3_34..A'
         WHEN '4403' THEN
          'G18_3_35..A'
         WHEN '3302' THEN
          'G18_3_36..A'
       END AS ITEM_NUM,
       --指标值字段：a.账面余额（折人民币）A.FACE_VAL
       DECODE(A.CURR_CD, 'CNY', A.FACE_VAL, A.FACE_VAL * U.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_ALL CA
          ON A.INVEST_ID = CA.CUST_ID
         AND CA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND B.STOCK_PRO_TYPE = 'A'
         AND B.ISSU_ORG = 'A02'
         AND B.ISSU_DT > D_ISSU_DT;
    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G18_3 '1..B-36..B'插入临时表
    --====================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '1..B-31..B';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
      (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE SUBSTR(CA.REGION_CD, 1, 2) --指标序号
         WHEN '11' THEN
          'G18_3_1..B'
         WHEN '12' THEN
          'G18_3_2..B'
         WHEN '13' THEN
          'G18_3_3..B'
         WHEN '14' THEN
          'G18_3_4..B'
         WHEN '15' THEN
          'G18_3_5..B'
         WHEN '21' THEN
          'G18_3_6..B'
         WHEN '22' THEN
          'G18_3_7..B'
         WHEN '23' THEN
          'G18_3_8..B'
         WHEN '31' THEN
          'G18_3_9..B'
         WHEN '32' THEN
          'G18_3_10..B'
         WHEN '33' THEN
          'G18_3_11..B'
         WHEN '34' THEN
          'G18_3_12..B'
         WHEN '35' THEN
          'G18_3_13..B'
         WHEN '36' THEN
          'G18_3_14..B'
         WHEN '37' THEN
          'G18_3_15..B'
         WHEN '41' THEN
          'G18_3_16..B'
         WHEN '42' THEN
          'G18_3_17..B'
         WHEN '43' THEN
          'G18_3_18..B'
         WHEN '44' THEN
          'G18_3_19..B'
         WHEN '45' THEN
          'G18_3_20..B'
         WHEN '46' THEN
          'G18_3_21..B'
         WHEN '50' THEN
          'G18_3_22..B'
         WHEN '51' THEN
          'G18_3_23..B'
         WHEN '52' THEN
          'G18_3_24..B'
         WHEN '53' THEN
          'G18_3_25..B'
         WHEN '54' THEN
          'G18_3_26..B'
         WHEN '61' THEN
          'G18_3_27..B'
         WHEN '62' THEN
          'G18_3_28..B'
         WHEN '63' THEN
          'G18_3_29..B'
         WHEN '64' THEN
          'G18_3_30..B'
         WHEN '65' THEN
          'G18_3_31..B'
       END AS ITEM_NUM,
       --指标值字段：a.账面余额（折人民币）A.FACE_VAL
       DECODE(A.CURR_CD, 'CNY', A.FACE_VAL, A.FACE_VAL * U.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_ALL CA
          ON A.INVEST_ID = CA.CUST_ID
         AND CA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND B.STOCK_PRO_TYPE = 'A'
         AND B.ISSU_ORG = 'A02'
         AND B.BOND_ISSUE_TYPE = 'B'
         AND B.ISSU_DT > D_ISSU_DT;

    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '32..B-36..B';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
      (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE SUBSTR(CA.REGION_CD, 1, 4) --指标序号
         WHEN '3502' THEN
          'G18_3_32..B'
         WHEN '3702' THEN
          'G18_3_33..B'
         WHEN '2102' THEN
          'G18_3_34..B'
         WHEN '4403' THEN
          'G18_3_35..B'
         WHEN '3302' THEN
          'G18_3_36..B'
       END AS ITEM_NUM,
       --指标值字段：a.账面余额（折人民币）A.FACE_VAL
       DECODE(A.CURR_CD, 'CNY', A.FACE_VAL, A.FACE_VAL * U.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_ALL CA
          ON A.INVEST_ID = CA.CUST_ID
         AND CA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND B.STOCK_PRO_TYPE = 'A'
         AND B.ISSU_ORG = 'A02'
         AND B.BOND_ISSUE_TYPE = 'B'
         AND B.ISSU_DT > D_ISSU_DT;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G18_3 '1..C-36..C'插入临时表
    --====================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '1..C-31..C';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
      (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE SUBSTR(CA.REGION_CD, 1, 2) --指标序号
         WHEN '11' THEN
          'G18_3_1..C'
         WHEN '12' THEN
          'G18_3_2..C'
         WHEN '13' THEN
          'G18_3_3..C'
         WHEN '14' THEN
          'G18_3_4..C'
         WHEN '15' THEN
          'G18_3_5..C'
         WHEN '21' THEN
          'G18_3_6..C'
         WHEN '22' THEN
          'G18_3_7..C'
         WHEN '23' THEN
          'G18_3_8..C'
         WHEN '31' THEN
          'G18_3_9..C'
         WHEN '32' THEN
          'G18_3_10..C'
         WHEN '33' THEN
          'G18_3_11..C'
         WHEN '34' THEN
          'G18_3_12..C'
         WHEN '35' THEN
          'G18_3_13..C'
         WHEN '36' THEN
          'G18_3_14..C'
         WHEN '37' THEN
          'G18_3_15..C'
         WHEN '41' THEN
          'G18_3_16..C'
         WHEN '42' THEN
          'G18_3_17..C'
         WHEN '43' THEN
          'G18_3_18..C'
         WHEN '44' THEN
          'G18_3_19..C'
         WHEN '45' THEN
          'G18_3_20..C'
         WHEN '46' THEN
          'G18_3_21..C'
         WHEN '50' THEN
          'G18_3_22..C'
         WHEN '51' THEN
          'G18_3_23..C'
         WHEN '52' THEN
          'G18_3_24..C'
         WHEN '53' THEN
          'G18_3_25..C'
         WHEN '54' THEN
          'G18_3_26..C'
         WHEN '61' THEN
          'G18_3_27..C'
         WHEN '62' THEN
          'G18_3_28..C'
         WHEN '63' THEN
          'G18_3_29..C'
         WHEN '64' THEN
          'G18_3_30..C'
         WHEN '65' THEN
          'G18_3_31..C'
       END AS ITEM_NUM,
       --指标值字段：a.账面余额（折人民币）A.FACE_VAL
       DECODE(A.CURR_CD, 'CNY', A.FACE_VAL, A.FACE_VAL * U.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_ALL CA
          ON A.INVEST_ID = CA.CUST_ID
         AND CA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND B.STOCK_PRO_TYPE = 'A'
         AND B.ISSU_ORG = 'A02'
         AND B.BOND_ISSUE_TYPE = 'A'
         AND B.ISSU_DT > D_ISSU_DT;

    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '32..C-36..C';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
      (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE SUBSTR(CA.REGION_CD, 1, 4) --指标序号
         WHEN '3502' THEN
          'G18_3_32..C'
         WHEN '3702' THEN
          'G18_3_33..C'
         WHEN '2102' THEN
          'G18_3_34..C'
         WHEN '4403' THEN
          'G18_3_35..C'
         WHEN '3302' THEN
          'G18_3_36..C'
       END AS ITEM_NUM,
       --指标值字段：a.账面余额（折人民币）A.FACE_VAL
       DECODE(A.CURR_CD, 'CNY', A.FACE_VAL, A.FACE_VAL * U.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_ALL CA
          ON A.INVEST_ID = CA.CUST_ID
         AND CA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND B.STOCK_PRO_TYPE = 'A'
         AND B.ISSU_ORG = 'A02'
         AND B.BOND_ISSUE_TYPE = 'A'
         AND B.ISSU_DT > D_ISSU_DT;
    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  


    --====================================================
    --   G18_3 '1..G-36..G'插入临时表
    --====================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '1..G-31..G';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
      (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE SUBSTR(CA.REGION_CD, 1, 2) --指标序号
         WHEN '11' THEN
          'G18_3_1..G'
         WHEN '12' THEN
          'G18_3_2..G'
         WHEN '13' THEN
          'G18_3_3..G'
         WHEN '14' THEN
          'G18_3_4..G'
         WHEN '15' THEN
          'G18_3_5..G'
         WHEN '21' THEN
          'G18_3_6..G'
         WHEN '22' THEN
          'G18_3_7..G'
         WHEN '23' THEN
          'G18_3_8..G'
         WHEN '31' THEN
          'G18_3_9..G'
         WHEN '32' THEN
          'G18_3_10..G'
         WHEN '33' THEN
          'G18_3_11..G'
         WHEN '34' THEN
          'G18_3_12..G'
         WHEN '35' THEN
          'G18_3_13..G'
         WHEN '36' THEN
          'G18_3_14..G'
         WHEN '37' THEN
          'G18_3_15..G'
         WHEN '41' THEN
          'G18_3_16..G'
         WHEN '42' THEN
          'G18_3_17..G'
         WHEN '43' THEN
          'G18_3_18..G'
         WHEN '44' THEN
          'G18_3_19..G'
         WHEN '45' THEN
          'G18_3_20..G'
         WHEN '46' THEN
          'G18_3_21..G'
         WHEN '50' THEN
          'G18_3_22..G'
         WHEN '51' THEN
          'G18_3_23..G'
         WHEN '52' THEN
          'G18_3_24..G'
         WHEN '53' THEN
          'G18_3_25..G'
         WHEN '54' THEN
          'G18_3_26..G'
         WHEN '61' THEN
          'G18_3_27..G'
         WHEN '62' THEN
          'G18_3_28..G'
         WHEN '63' THEN
          'G18_3_29..G'
         WHEN '64' THEN
          'G18_3_30..G'
         WHEN '65' THEN
          'G18_3_31..G'
       END AS ITEM_NUM,
       --指标值字段：a.账面余额（折人民币）A.FACE_VAL
       DECODE(A.CURR_CD, 'CNY', A.FACE_VAL, A.FACE_VAL * U.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_ALL CA
          ON A.INVEST_ID = CA.CUST_ID
         AND CA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND B.STOCK_PRO_TYPE = 'A'
         AND B.ISSU_ORG = 'A02'
         AND DATEDIFF(DATE(B.MATURITY_DT) , DATE(B.DATA_DATE)) <= 360
         AND B.ISSU_DT > D_ISSU_DT;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '32..G-36..G';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
      (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE SUBSTR(CA.REGION_CD, 1, 4) --指标序号
         WHEN '3502' THEN
          'G18_3_32..G'
         WHEN '3702' THEN
          'G18_3_33..G'
         WHEN '2102' THEN
          'G18_3_34..G'
         WHEN '4403' THEN
          'G18_3_35..G'
         WHEN '3302' THEN
          'G18_3_36..G'
       END AS ITEM_NUM,
       --指标值字段：a.账面余额（折人民币）A.FACE_VAL
       DECODE(A.CURR_CD, 'CNY', A.FACE_VAL, A.FACE_VAL * U.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_ALL CA
          ON A.INVEST_ID = CA.CUST_ID
         AND CA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND B.STOCK_PRO_TYPE = 'A'
         AND B.ISSU_ORG = 'A02'
         AND  DATEDIFF(DATE(B.MATURITY_DT) , DATE(B.DATA_DATE))  <= 360
         AND B.ISSU_DT > D_ISSU_DT;
    COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G18_3 '1..H-36..H'插入临时表
    --====================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '1..H-31..H';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
      (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE SUBSTR(CA.REGION_CD, 1, 2) --指标序号
         WHEN '11' THEN
          'G18_3_1..H'
         WHEN '12' THEN
          'G18_3_2..H'
         WHEN '13' THEN
          'G18_3_3..H'
         WHEN '14' THEN
          'G18_3_4..H'
         WHEN '15' THEN
          'G18_3_5..H'
         WHEN '21' THEN
          'G18_3_6..H'
         WHEN '22' THEN
          'G18_3_7..H'
         WHEN '23' THEN
          'G18_3_8..H'
         WHEN '31' THEN
          'G18_3_9..H'
         WHEN '32' THEN
          'G18_3_10..H'
         WHEN '33' THEN
          'G18_3_11..H'
         WHEN '34' THEN
          'G18_3_12..H'
         WHEN '35' THEN
          'G18_3_13..H'
         WHEN '36' THEN
          'G18_3_14..H'
         WHEN '37' THEN
          'G18_3_15..H'
         WHEN '41' THEN
          'G18_3_16..H'
         WHEN '42' THEN
          'G18_3_17..H'
         WHEN '43' THEN
          'G18_3_18..H'
         WHEN '44' THEN
          'G18_3_19..H'
         WHEN '45' THEN
          'G18_3_20..H'
         WHEN '46' THEN
          'G18_3_21..H'
         WHEN '50' THEN
          'G18_3_22..H'
         WHEN '51' THEN
          'G18_3_23..H'
         WHEN '52' THEN
          'G18_3_24..H'
         WHEN '53' THEN
          'G18_3_25..H'
         WHEN '54' THEN
          'G18_3_26..H'
         WHEN '61' THEN
          'G18_3_27..H'
         WHEN '62' THEN
          'G18_3_28..H'
         WHEN '63' THEN
          'G18_3_29..H'
         WHEN '64' THEN
          'G18_3_30..H'
         WHEN '65' THEN
          'G18_3_31..H'
       END AS ITEM_NUM,
       --指标值字段：a.账面余额（折人民币）A.FACE_VAL
       DECODE(A.CURR_CD, 'CNY', A.FACE_VAL, A.FACE_VAL * U.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_ALL CA
          ON A.INVEST_ID = CA.CUST_ID
         AND CA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND B.STOCK_PRO_TYPE = 'A'
         AND B.ISSU_ORG = 'A02'
         AND DATEDIFF(DATE(B.MATURITY_DT) , DATE(B.DATA_DATE)) <= 1080
         AND DATEDIFF(DATE(B.MATURITY_DT) , DATE(B.DATA_DATE)) > 360
         AND B.ISSU_DT > D_ISSU_DT;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '32..H-36..H';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
      (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE SUBSTR(CA.REGION_CD, 1, 4) --指标序号
         WHEN '3502' THEN
          'G18_3_32..H'
         WHEN '3702' THEN
          'G18_3_33..H'
         WHEN '2102' THEN
          'G18_3_34..H'
         WHEN '4403' THEN
          'G18_3_35..H'
         WHEN '3302' THEN
          'G18_3_36..H'
       END AS ITEM_NUM,
       --指标值字段：a.账面余额（折人民币）A.FACE_VAL
       DECODE(A.CURR_CD, 'CNY', A.FACE_VAL, A.FACE_VAL * U.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_ALL CA
          ON A.INVEST_ID = CA.CUST_ID
         AND CA.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND B.STOCK_PRO_TYPE = 'A'
         AND B.ISSU_ORG = 'A02'
         AND DATEDIFF(DATE(B.MATURITY_DT) , DATE(B.DATA_DATE)) <= 1080
         AND DATEDIFF(DATE(B.MATURITY_DT) , DATE(B.DATA_DATE)) > 360
         AND B.ISSU_DT > D_ISSU_DT;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
----add  by   zy   20240903  start
--- 按资金用途划分：一般债券  专项债券
INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
   (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
SELECT 
 A.ORG_NUM,
 CASE
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..B.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..C.2019'
 END AS ITEM_NUM,
 SUM(A.PRINCIPAL_BALANCE * U.CCY_RATE) AS ITEM_VALUE --账面余额
  FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
 INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
    ON A.SUBJECT_CD = B.STOCK_CD
   AND B.DATA_DATE = I_DATADATE
  LEFT JOIN SMTMODS_L_PUBL_RATE U
    ON U.CCY_DATE = I_DATADATE
   AND U.BASIC_CCY = A.CURR_CD --基准币种
   AND U.FORWARD_CCY = 'CNY' --折算币种
 WHERE A.DATA_DATE = I_DATADATE
   AND A.INVEST_TYP = '00' ---投资业务品种，债券投资
   AND B.FXZJYT IN ('02', '01') --01：一般债券 02：专项债券
   AND B.STOCK_ASSET_TYPE IS NULL
   AND B.ISSUER_INLAND_FLG = 'Y'
   AND B.STOCK_PRO_TYPE = 'A'
   AND B.ISSU_ORG = 'A02'     ---地方政府债
 GROUP BY A.ORG_NUM, CASE
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..B.2019'
   WHEN B.FXZJYT = '01' AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..B.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..C.2019'
   WHEN B.FXZJYT = '02' AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..C.2019'
 END;
         COMMIT;

--- 按利率水平："较基准国债平均收益率上浮15%以内（含15%）"  ,"较基准国债平均收益率上浮15%至30%（含30%）"  ,"较基准国债平均收益率上浮30%以上"
---发行日期-2 是工作日的情况
INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
   (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
 SELECT 
 A.ORG_NUM,
CASE
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..F'

   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..E'


   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..D'
 END AS ITEM_NUM,
SUM(A.PRINCIPAL_BALANCE * U.CCY_RATE ) AS ITEM_VALUE --账面余额
  FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
 INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
    ON A.SUBJECT_CD = B.STOCK_CD
   AND B.DATA_DATE = I_DATADATE
  inner  JOIN (
  select STATE_DATE, CURVE_CODE, CURVE_NAME, MTRTY, YLD, CURVE_TYPE ,
   avg(YLD)over(PARTITION  BY CURVE_NAME, MTRTY  order by STATE_DATE ROWS BETWEEN 4 PRECEDING  AND 0 FOLLOWING)   AVG_YLD  ---表示往前4行到往后0行，共5行
   from
(select  distinct(STATE_DATE) STATE_DATE  , CURVE_CODE, CURVE_NAME, MTRTY, YLD, CURVE_TYPE
from  CBRC_JTDP_INTERF_PAYHSRCCASHYIELD  where  CURVE_NAME  like '%中债国债收益率曲线%'   and  CURVE_TYPE = '02') t1  ) C
ON TO_CHAR(B.ISSU_DT-2,'YYYYMMDD') = C.STATE_DATE
AND (CASE WHEN  (MATURITY_DATE-ISSU_DT)/365 < 1 THEN ROUND((MATURITY_DATE-ISSU_DT)/365,2)
  ELSE ROUND((MATURITY_DATE-ISSU_DT)/365,0) END = C.MTRTY )
  LEFT JOIN SMTMODS_L_PUBL_RATE U
    ON U.CCY_DATE = I_DATADATE
   AND U.BASIC_CCY = A.CURR_CD --基准币种
   AND U.FORWARD_CCY = 'CNY' --折算币种
 WHERE A.DATA_DATE = I_DATADATE
   AND A.INVEST_TYP = '00' ---投资业务品种，债券投资
   AND B.STOCK_ASSET_TYPE IS NULL
   AND B.ISSUER_INLAND_FLG = 'Y'
   AND B.STOCK_PRO_TYPE = 'A'
   AND B.ISSU_ORG = 'A02'
   group by  A.ORG_NUM,
CASE
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..F'

   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..E'


   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..D'
 END  ;
 COMMIT;

 -----
---发行日期-2 是非工作日的情况


INSERT  INTO  CBRC_STOCK_HOLIDAY
SELECT  TO_CHAR(B.ISSU_DT-2,'YYYYMMDD') as ISSU_DT_2, B.STOCK_CD
 FROM SMTMODS_L_ACCT_FUND_INVEST A
 INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
    ON A.SUBJECT_CD = B.STOCK_CD
   AND B.DATA_DATE = I_DATADATE
   WHERE A.DATA_DATE = I_DATADATE
   AND A.INVEST_TYP = '00' ---投资业务品种，债券投资
   AND B.STOCK_ASSET_TYPE IS NULL
   AND B.ISSUER_INLAND_FLG = 'Y'
   AND B.STOCK_PRO_TYPE = 'A'
   AND B.ISSU_ORG = 'A02'
   AND TO_CHAR(B.ISSU_DT-2,'YYYYMMDD') NOT IN(select  distinct(STATE_DATE) STATE_DATE
from  CBRC_JTDP_INTERF_PAYHSRCCASHYIELD );
COMMIT ;


 INSERT  INTO CBRC_STOCK_HOLIDAY_TEMP
select  max(t1.STATE_DATE) STATE_DATE ,T.STOCK_CD ,T.ISSU_DT_2 from CBRC_STOCK_HOLIDAY  T
 INNER   JOIN
( select  distinct(STATE_DATE) STATE_DATE  from  CBRC_JTDP_INTERF_PAYHSRCCASHYIELD )  t1
    ON 1=1
WHERE  T.ISSU_DT_2 > t1.STATE_DATE
GROUP BY   T.STOCK_CD ,T.ISSU_DT_2 ;
COMMIT ;

 INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
   (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
SELECT 
 A.ORG_NUM,
CASE
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..F'

   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..E'


   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..D'
 END AS ITEM_NUM,
SUM(A.PRINCIPAL_BALANCE * U.CCY_RATE ) AS ITEM_VALUE --账面余额
  FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
 INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
    ON A.SUBJECT_CD = B.STOCK_CD
   AND B.DATA_DATE = I_DATADATE
   inner  JOIN  CBRC_STOCK_HOLIDAY_TEMP D
   ON B.STOCK_CD  =D.STOCK_CD
   AND TO_CHAR(B.ISSU_DT-2,'YYYYMMDD') = D.ISSU_DT_2
  inner  JOIN (
  select STATE_DATE, CURVE_CODE, CURVE_NAME, MTRTY, YLD, CURVE_TYPE ,
   avg(YLD)over(PARTITION  BY CURVE_NAME, MTRTY  order by STATE_DATE ROWS BETWEEN 4 PRECEDING  AND 0 FOLLOWING)   AVG_YLD ---表示往前4行到往后0行，共5行
    from
(select  distinct(STATE_DATE) STATE_DATE  , CURVE_CODE, CURVE_NAME, MTRTY, YLD, CURVE_TYPE
from  CBRC_JTDP_INTERF_PAYHSRCCASHYIELD  where  CURVE_NAME  like '%中债国债收益率曲线%'   and  CURVE_TYPE = '02') t1  ) C
ON D.STATE_DATE = C.STATE_DATE
AND (CASE WHEN  (MATURITY_DATE-ISSU_DT)/365 <1 THEN ROUND((MATURITY_DATE-ISSU_DT)/365,2)
  ELSE ROUND((MATURITY_DATE-ISSU_DT)/365,0) END = C.MTRTY)
  LEFT JOIN SMTMODS_L_PUBL_RATE U
    ON U.CCY_DATE = I_DATADATE
   AND U.BASIC_CCY = A.CURR_CD --基准币种
   AND U.FORWARD_CCY = 'CNY' --折算币种
 WHERE A.DATA_DATE = I_DATADATE
   AND A.INVEST_TYP = '00' ---投资业务品种，债券投资
   AND B.STOCK_ASSET_TYPE IS NULL
   AND B.ISSUER_INLAND_FLG = 'Y'
   AND B.STOCK_PRO_TYPE = 'A'
   AND B.ISSU_ORG = 'A02'
   group by  A.ORG_NUM,
CASE
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..F'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.30 AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..F'

   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..E'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) >0.15 AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..E'


   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..D'
   WHEN ROUND(A.REAL_INT_RAT-C.AVG_YLD,2) <=0.15 AND B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..D'
 END  ;

  --------------------------   add  by   zy   start  20240904

/* 按剩余期限
一年以内（含一年）
一年至五年（含五年）
五年至十年（含十年）
十年以上*/
   INSERT INTO CBRC_PUB_DATA_COLLECT_G18_3
      (ORG_NUM, --机构号
       ITEM_NUM, --指标序号
       ITEM_VAL --指标值
       )
SELECT 
 A.ORG_NUM,
 CASE
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..L'


   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..K'


   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..J'

   ELSE
  ( CASE WHEN   B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..I'
   END )
 END AS ITEM_NUM,
 SUM(A.PRINCIPAL_BALANCE * U.CCY_RATE) AS ITEM_VALUE --账面余额
  FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
 INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
    ON A.SUBJECT_CD = B.STOCK_CD
   AND B.DATA_DATE = I_DATADATE
  LEFT JOIN SMTMODS_L_PUBL_RATE U
    ON U.CCY_DATE = I_DATADATE
   AND U.BASIC_CCY = A.CURR_CD --基准币种
   AND U.FORWARD_CCY = 'CNY' --折算币种
 WHERE A.DATA_DATE = I_DATADATE
   AND A.INVEST_TYP = '00' ---投资业务品种，债券投资
   AND B.STOCK_ASSET_TYPE IS NULL
   AND B.ISSUER_INLAND_FLG = 'Y'
   AND B.STOCK_PRO_TYPE = 'A'
   AND B.ISSU_ORG = 'A02'     ---地方政府债
 GROUP BY A.ORG_NUM, CASE
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..L'
   WHEN A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..L'


   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..K'
   WHEN A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..K'


   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..J'
   WHEN A.DC_DATE > 360  AND b.STOCK_NAM <> '18华阳经贸CP001'  AND  B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..J'

   ELSE
  ( CASE WHEN   B.ISSU_ORG_NAM LIKE '%北京%' THEN 'G18_3_1..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%天津%' THEN 'G18_3_2..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%河北%' THEN 'G18_3_3..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%山西%' THEN 'G18_3_4..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%内蒙古%' THEN 'G18_3_5..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%辽宁%' THEN 'G18_3_6..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%吉林%' THEN 'G18_3_7..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%黑龙江%' THEN 'G18_3_8..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%上海%' THEN 'G18_3_9..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%江苏%' THEN 'G18_3_10..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%浙江%' THEN 'G18_3_11..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%安徽%' THEN 'G18_3_12..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%福建%' THEN 'G18_3_13..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%江西%' THEN 'G18_3_14..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%山东%' THEN 'G18_3_15..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%河南%' THEN 'G18_3_16..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%湖北%' THEN 'G18_3_17..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%湖南%' THEN 'G18_3_18..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%广东%' THEN 'G18_3_19..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%广西%' THEN 'G18_3_20..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%海南%' THEN 'G18_3_21..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%重庆%' THEN 'G18_3_22..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%四川%' THEN 'G18_3_23..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%贵州%' THEN 'G18_3_24..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%云南%' THEN 'G18_3_25..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%西藏%' THEN 'G18_3_26..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%陕西%' THEN 'G18_3_27..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%甘肃%' THEN 'G18_3_28..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%青海%' THEN 'G18_3_29..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%宁夏%' THEN 'G18_3_30..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%新疆%' THEN 'G18_3_31..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%厦门%' THEN 'G18_3_32..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%青岛%' THEN 'G18_3_33..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%大连%' THEN 'G18_3_34..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%深圳%' THEN 'G18_3_35..I'
   WHEN   B.ISSU_ORG_NAM LIKE '%宁波%' THEN 'G18_3_36..I'
   END )
 END;
         COMMIT;





----add  by   zy   20240903  end

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_PER_NUM AS REP_NUM, --报表编号
             ITEM_NUM, --指标号
             SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM CBRC_PUB_DATA_COLLECT_G18_3 A
       WHERE A.ITEM_NUM IS NOT NULL
       GROUP BY ORG_NUM, --机构号
                ITEM_NUM; --报表类型

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
   
END proc_cbrc_idx2_g1803