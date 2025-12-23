CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g0105(II_DATADATE IN string --跑批日期
                                              )
/****************************** 
  @AUTHOR:AUTHOR
  @CREATE-DATE:2023-01-16
  @DESCRIPTION:G0105
  @MODIFICATION HISTORY:
  @modify:需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：石雨，提出人：王曦若
         [JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
  


目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_TMP_G0105_A_REPT_ITEM_VAL
视图表:SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
     SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
     SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
集市表:SMTMODS_L_FINA_GL --总账科目表
     SMTMODS_L_PUBL_RATE    --汇率表
     SMTMODS_L_ACCT_DEPOSIT  --存款账户信息表
     SMTMODS_L_CUST_C   --对公客户补充信息表




  ********************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_REP_NUM      VARCHAR(30); --报表名称
  I_DATADATE     INTEGER; --数据日期(数值型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
   D_DATADATE_CCY string;
  II_STATUS    INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM      VARCHAR2(30);
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_DESC := '参数初始化处理';
	V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_G0105');
	V_SYSTEM       := 'CBRC';
	V_REP_NUM      := 'G01_5';
	I_DATADATE     := II_DATADATE;
    D_DATADATE_CCY := I_DATADATE;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_DESC := '清理 [' || V_REP_NUM || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_TMP_G0105_A_REPT_ITEM_VAL';

    COMMIT;

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = V_REP_NUM
       AND FLAG = '1';
    COMMIT;
   
   V_STEP_ID   := '1';
    V_STEP_DESC := 'G01_5.1.现金';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --1. 现金
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_1..A.2023'
               WHEN 'EUR' THEN
                'G01_5_1..B.2023'
               WHEN 'JPY' THEN
                'G01_5_1..C.2023'
               WHEN 'HKD' THEN
                'G01_5_1..D.2023'
               WHEN 'GBP' THEN
                'G01_5_1..E.2023'
             END AS ITEM_NUM, --指标号
             SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1001'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_1..A.2023'
               WHEN 'EUR' THEN
                'G01_5_1..B.2023'
               WHEN 'JPY' THEN
                'G01_5_1..C.2023'
               WHEN 'HKD' THEN
                'G01_5_1..D.2023'
               WHEN 'GBP' THEN
                'G01_5_1..E.2023'
             END;

    --2. 存放中央银行款项
    V_STEP_ID   := '2';
    V_STEP_DESC := 'G01_5.2 存放中央银行款项';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
                
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_2..A.2023'
               WHEN 'EUR' THEN
                'G01_5_2..B.2023'
               WHEN 'JPY' THEN
                'G01_5_2..C.2023'
               WHEN 'HKD' THEN
                'G01_5_2..D.2023'
               WHEN 'GBP' THEN
                 'G01_5_2..E.2023'
             END AS ITEM_NUM, --指标号
             SUM(CASE
                   WHEN ITEM_CD IN ( '100303','100304') THEN
                    -A.DEBIT_BAL * B.CCY_RATE
                   ELSE
                    A.DEBIT_BAL * B.CCY_RATE
                 END) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('1003', '100303','100304')
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_2..A.2023'
               WHEN 'EUR' THEN
                'G01_5_2..B.2023'
               WHEN 'JPY' THEN
                'G01_5_2..C.2023'
               WHEN 'HKD' THEN
                'G01_5_2..D.2023'
               WHEN 'GBP' THEN
                 'G01_5_2..E.2023'
             END;
       --3. 存放同业款项
    V_STEP_ID   := '3';
    V_STEP_DESC := 'G01_5.3贷款';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_3..A.2023'
               WHEN 'EUR' THEN
                'G01_5_3..B.2023'
               WHEN 'JPY' THEN
                'G01_5_3..C.2023'
               WHEN 'HKD' THEN
                'G01_5_3..D.2023'
               WHEN 'GBP' THEN
                'G01_5_3..E.2023'
             END AS ITEM_NUM, --指标号
             SUM(A.DEBIT_BAL * B.CCY_RATE),
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         AND A.ITEM_CD IN ('1011', '1031')
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_3..A.2023'
               WHEN 'EUR' THEN
                'G01_5_3..B.2023'
               WHEN 'JPY' THEN
                'G01_5_3..C.2023'
               WHEN 'HKD' THEN
                'G01_5_3..D.2023'
               WHEN 'GBP' THEN
                'G01_5_3..E.2023'
             END;
  COMMIT;
  
   --4. 贷款
    V_STEP_ID   := '4';
    V_STEP_DESC := 'G01_5.4 贷款';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_4..A.2023'
               WHEN 'EUR' THEN
                'G01_5_4..B.2023'
               WHEN 'JPY' THEN
                'G01_5_4..C.2023'
               WHEN 'HKD' THEN
                'G01_5_4..D.2023'
               WHEN 'GBP' THEN
                'G01_5_4..E.2023'
             END AS ITEM_NUM, --指标号
             SUM(CASE
                   WHEN ITEM_CD IN ('13030102','13030202','13030302','13060102','13060202','13060302','13060402','13060502') THEN
                    -A.DEBIT_BAL * B.CCY_RATE
                   ELSE
                    A.DEBIT_BAL * B.CCY_RATE
                 END) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('1303', '1306','13030102','13030202','13030302','13060102','13060202','13060302','13060402','13060502')
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_4..A.2023'
               WHEN 'EUR' THEN
                'G01_5_4..B.2023'
               WHEN 'JPY' THEN
                'G01_5_4..C.2023'
               WHEN 'HKD' THEN
                'G01_5_4..D.2023'
               WHEN 'GBP' THEN
                'G01_5_4..E.2023'
             END;

    --5. 贸易融资
    V_STEP_ID   := '5';
    V_STEP_DESC := 'G01_5.5 贸易融资';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_5..A.2023'
               WHEN 'EUR' THEN
                'G01_5_5..B.2023'
               WHEN 'JPY' THEN
                'G01_5_5..C.2023'
               WHEN 'HKD' THEN
                'G01_5_5..D.2023'
               WHEN 'GBP' THEN
                'G01_5_5..E.2023'
             END AS ITEM_NUM, --指标号
             SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1305'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_5..A.2023'
               WHEN 'EUR' THEN
                'G01_5_5..B.2023'
               WHEN 'JPY' THEN
                'G01_5_5..C.2023'
               WHEN 'HKD' THEN
                'G01_5_5..D.2023'
               WHEN 'GBP' THEN
                'G01_5_5..E.2023'
             END;
    --6 贴现及买断式转贴现
    V_STEP_ID   := '6';
    V_STEP_DESC := 'G01_5.6 贴现及买断式转贴现';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_6..A.2023'
               WHEN 'EUR' THEN
                'G01_5_6..B.2023'
               WHEN 'JPY' THEN
                'G01_5_6..C.2023'
               WHEN 'HKD' THEN
                'G01_5_6..D.2023'
               WHEN 'GBP' THEN
                'G01_5_6..E.2023'
             END AS ITEM_NUM, --指标号
             SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('13010101',
                           '13010103',
                           '13010201',
                           '13010203',
                           '13010301',
                           '13010303',
                           '13010401',
                           '13010403',
                           '13010501',
                           '13010503',
                           '13010104',
                           '13010106',
                           '13010204',
                           '13010206',
                           '13010405',
                           '13010407',
                           '13010505',
                           '13010507'
                           )
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_6..A.2023'
               WHEN 'EUR' THEN
                'G01_5_6..B.2023'
               WHEN 'JPY' THEN
                'G01_5_6..C.2023'
               WHEN 'HKD' THEN
                'G01_5_6..D.2023'
               WHEN 'GBP' THEN
                'G01_5_6..E.2023'
             END;

    --7．拆放同业
    V_STEP_ID   := '7';
    V_STEP_DESC := 'G01_5.7 拆放同业';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_7..A.2023'
               WHEN 'EUR' THEN
                'G01_5_7..B.2023'
               WHEN 'JPY' THEN
                'G01_5_7..C.2023'
               WHEN 'HKD' THEN
                'G01_5_7..D.2023'
               WHEN 'GBP' THEN
                'G01_5_7..E.2023'
             END AS ITEM_NUM, --指标号
             SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD ='1302'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_7..A.2023'
               WHEN 'EUR' THEN
                'G01_5_7..B.2023'
               WHEN 'JPY' THEN
                'G01_5_7..C.2023'
               WHEN 'HKD' THEN
                'G01_5_7..D.2023'
               WHEN 'GBP' THEN
                'G01_5_7..E.2023'
             END;
   COMMIT;
  --8. 投资
    V_STEP_ID   := '8';
    V_STEP_DESC := 'G01_5.8. 投资';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
       'G01_5' AS REP_NUM, --报表编号
       CASE CURR_CD
         WHEN 'USD' THEN
          'G01_5_8..A.2023'
         WHEN 'EUR' THEN
          'G01_5_8..B.2023'
         WHEN 'JPY' THEN
          'G01_5_8..C.2023'
         WHEN 'HKD' THEN
          'G01_5_8..D.2023'
         WHEN 'GBP' THEN
          'G01_5_8..E.2023'
       END AS ITEM_NUM, --指标号
       SUM(
           CASE
             WHEN A.ITEM_CD IN ('1101', '1102', '1501', '1503', '1504', '1511') THEN
              (A.DEBIT_BAL - A.CREDIT_BAL)
             WHEN A.ITEM_CD IN ('11010105', '11020105', '15010105', '15030105') THEN
              A.DEBIT_BAL * -1
             WHEN A.ITEM_CD IN ('11010205',
                                '11020205',
                                '15010305',
                                '15010505',
                                '15030305',
                                '15030505',
                                '15030705') THEN
              (A.DEBIT_BAL - A.CREDIT_BAL)
           END * B.CCY_RATE) AS ITEM_VAL, --指标值
       '1' AS FLAG
  FROM SMTMODS_L_FINA_GL A
  LEFT JOIN SMTMODS_L_PUBL_RATE B
    ON B.DATA_DATE = I_DATADATE
   AND A.CURR_CD = B.BASIC_CCY
   AND B.FORWARD_CCY = 'CNY'
 WHERE A.DATA_DATE = I_DATADATE
   AND A.ITEM_CD IN ('1101',
                     '1102',
                     '1501',
                     '1503',
                     '1504',
                     '1511',
                     '11010105',
                     '11020105',
                     '15010105',
                     '15030105',
                     '11010205',
                     '11020205',
                     '15010305',
                     '15010505',
                     '15030305',
                     '15030505',
                     '15030705')
   AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
 GROUP BY A.ORG_NUM,
          CASE CURR_CD
            WHEN 'USD' THEN
             'G01_5_8..A.2023'
            WHEN 'EUR' THEN
             'G01_5_8..B.2023'
            WHEN 'JPY' THEN
             'G01_5_8..C.2023'
            WHEN 'HKD' THEN
             'G01_5_8..D.2023'
            WHEN 'GBP' THEN
             'G01_5_8..E.2023'
          END;
   COMMIT;


    --8.1 债券
    V_STEP_ID   := '8';
    V_STEP_DESC := 'G01_5.8.1 债券';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --8.1 债券
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
       'G01_5' AS REP_NUM, --报表编号
       CASE CURR_CD
         WHEN 'USD' THEN
          'G01_5_8.1.A.2023'
         WHEN 'EUR' THEN
          'G01_5_8.1.B.2023'
         WHEN 'JPY' THEN
          'G01_5_8.1.C.2023'
         WHEN 'HKD' THEN
          'G01_5_8.1.D.2023'
         WHEN 'GBP' THEN
          'G01_5_8.1.E.2023'
       END AS ITEM_NUM, --指标号
       SUM((CASE
             WHEN A.ITEM_CD IN ('11010101',
                                '11010102',
                                '11010103',
                                '11010104',
                                '11010201',
                                '11010202',
                                '11010203',
                                '11010204',
                                '11020101',
                                '11020102',
                                '11020103',
                                '11020104',
                                '11020201',
                                '11020202',
                                '11020202',
                                '11020203',
                                '11020204',
                                '15010101',
                                '15010102',
                                '15010103',
                                '15010104',
                                '15010301',
                                '15010302',
                                '15010303',
                                '15010304',
                                '15010501',
                                '15010502',
                                '15010503',
                                '15010504',
                                '15030101',
                                '15030102',
                                '15030103',
                                '15030104',
                                '15030301',
                                '15030302',
                                '15030303',
                                '15030304',
                                '15030501',
                                '15030502',
                                '15030503',
                                '15030504',
                                '15030701',
                                '15030702',
                                '15030703',
                                '15030704') THEN
              A.DEBIT_BAL
             WHEN A.ITEM_CD IN ('11010201',
                                '11010202',
                                '11010203',
                                '11010204',
                                '11020201',
                                '11020202',
                                '11020202',
                                '11020203',
                                '11020204',
                                '15010301',
                                '15010302',
                                '15010303',
                                '15010304',
                                '15010501',
                                '15010502',
                                '15010503',
                                '15010504',
                                '15030301',
                                '15030302',
                                '15030303',
                                '15030304',
                                '15030501',
                                '15030502',
                                '15030503',
                                '15030504',
                                '15030701',
                                '15030702',
                                '15030703',
                                '15030704') THEN
              -1 * A.CREDIT_BAL
           END)

           * B.CCY_RATE) AS ITEM_VAL, --指标值
       '1' AS FLAG
  FROM SMTMODS_L_FINA_GL A
  LEFT JOIN SMTMODS_L_PUBL_RATE B
    ON B.DATA_DATE = I_DATADATE
   AND A.CURR_CD = B.BASIC_CCY
   AND B.FORWARD_CCY = 'CNY'
 WHERE A.DATA_DATE = I_DATADATE
   AND A.ITEM_CD IN ('11010101',
                     '11010102',
                     '11010103',
                     '11010104',
                     '11010201',
                     '11010202',
                     '11010203',
                     '11010204',
                     '11020101',
                     '11020102',
                     '11020103',
                     '11020104',
                     '11020201',
                     '11020202',
                     '11020202',
                     '11020203',
                     '11020204',
                     '15010101',
                     '15010102',
                     '15010103',
                     '15010104',
                     '15010301',
                     '15010302',
                     '15010303',
                     '15010304',
                     '15010501',
                     '15010502',
                     '15010503',
                     '15010504',
                     '15030101',
                     '15030102',
                     '15030103',
                     '15030104',
                     '15030301',
                     '15030302',
                     '15030303',
                     '15030304',
                     '15030501',
                     '15030502',
                     '15030503',
                     '15030504',
                     '15030701',
                     '15030702',
                     '15030703',
                     '15030704',
                     '11010201',
                     '11010202',
                     '11010203',
                     '11010204',
                     '11020201',
                     '11020202',
                     '11020202',
                     '11020203',
                     '11020204',
                     '15010301',
                     '15010302',
                     '15010303',
                     '15010304',
                     '15010501',
                     '15010502',
                     '15010503',
                     '15010504',
                     '15030301',
                     '15030302',
                     '15030303',
                     '15030304',
                     '15030501',
                     '15030502',
                     '15030503',
                     '15030504',
                     '15030701',
                     '15030702',
                     '15030703',
                     '15030704')
   AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
 GROUP BY A.ORG_NUM,
          CASE CURR_CD
            WHEN 'USD' THEN
             'G01_5_8.1.A.2023'
            WHEN 'EUR' THEN
             'G01_5_8.1.B.2023'
            WHEN 'JPY' THEN
             'G01_5_8.1.C.2023'
            WHEN 'HKD' THEN
             'G01_5_8.1.D.2023'
            WHEN 'GBP' THEN
             'G01_5_8.1.E.2023'
          END
           ;
    COMMIT;

    --8.2 股票

    --8.3 其他
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
       'G01_5' AS REP_NUM, --报表编号
       ITEM_NUM,
       SUM(ITEM_VAL) AS ITEM_VAL,
       '1' AS FLAG
  FROM (SELECT I_DATADATE AS DATA_DATE, --数据日期
               ORG_NUM AS ORG_NUM, --机构号
               CASE CURR_CD
                 WHEN 'USD' THEN
                  'G01_5_8.3.A.2023'
                 WHEN 'EUR' THEN
                  'G01_5_8.3.B.2023'
                 WHEN 'JPY' THEN
                  'G01_5_8.3.C.2023'
                 WHEN 'HKD' THEN
                  'G01_5_8.3.D.2023'
                 WHEN 'GBP' THEN
                  'G01_5_8.3.E.2023'
               END AS ITEM_NUM, --指标号
               SUM(-1 * A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
               '1' AS FLAG
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('110101',
                             '110102',
                             '110201',
                             '110202',
                             '150101',
                             '150103',
                             '150105',
                             '150301',
                             '150303',
                             '150305',
                             '150307')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM,
                  CASE CURR_CD
                    WHEN 'USD' THEN
                     'G01_5_8.3.A.2023'
                    WHEN 'EUR' THEN
                     'G01_5_8.3.B.2023'
                    WHEN 'JPY' THEN
                     'G01_5_8.3.C.2023'
                    WHEN 'HKD' THEN
                     'G01_5_8.3.D.2023'
                    WHEN 'GBP' THEN
                     'G01_5_8.3.E.2023'
                  END
        UNION
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               ORG_NUM AS ORG_NUM, --机构号
               CASE CURR_CD
                 WHEN 'USD' THEN
                  'G01_5_8.3.A.2023'
                 WHEN 'EUR' THEN
                  'G01_5_8.3.B.2023'
                 WHEN 'JPY' THEN
                  'G01_5_8.3.C.2023'
                 WHEN 'HKD' THEN
                  'G01_5_8.3.D.2023'
                 WHEN 'GBP' THEN
                  'G01_5_8.3.E.2023'
               END AS ITEM_NUM, --指标号
               SUM((A.DEBIT_BAL - A.CREDIT_BAL) * B.CCY_RATE) AS ITEM_VAL, --指标值
               '1' AS FLAG
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('1101', '1102', '1501', '1503', '1504', '1511')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM,
                  CASE CURR_CD
                    WHEN 'USD' THEN
                     'G01_5_8.3.A.2023'
                    WHEN 'EUR' THEN
                     'G01_5_8.3.B.2023'
                    WHEN 'JPY' THEN
                     'G01_5_8.3.C.2023'
                    WHEN 'HKD' THEN
                     'G01_5_8.3.D.2023'
                    WHEN 'GBP' THEN
                     'G01_5_8.3.E.2023'
                  END

        UNION
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               ORG_NUM AS ORG_NUM, --机构号
               CASE CURR_CD
                 WHEN 'USD' THEN
                  'G01_5_8.3.A.2023'
                 WHEN 'EUR' THEN
                  'G01_5_8.3.B.2023'
                 WHEN 'JPY' THEN
                  'G01_5_8.3.C.2023'
                 WHEN 'HKD' THEN
                  'G01_5_8.3.D.2023'
                 WHEN 'GBP' THEN
                  'G01_5_8.3.E.2023'
               END AS ITEM_NUM, --指标号
               SUM((A.CREDIT_BAL) * B.CCY_RATE) AS ITEM_VAL, --指标值
               '1' AS FLAG
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('110102',
                             '110202',
                             '150103',
                             '150105',
                             '150303',
                             '150305',
                             '150307')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM,
                  CASE CURR_CD
                    WHEN 'USD' THEN
                     'G01_5_8.3.A.2023'
                    WHEN 'EUR' THEN
                     'G01_5_8.3.B.2023'
                    WHEN 'JPY' THEN
                     'G01_5_8.3.C.2023'
                    WHEN 'HKD' THEN
                     'G01_5_8.3.D.2023'
                    WHEN 'GBP' THEN
                     'G01_5_8.3.E.2023'
                  END
        )
 GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;
V_STEP_ID   := '9';
    V_STEP_DESC := 'G01_5.9 买入返售资产';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

       --9.买入返售资产
    V_STEP_ID   := '9';
    V_STEP_DESC := 'G01_5.9 买入返售资产';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_9..A.2023'
               WHEN 'EUR' THEN
                'G01_5_9..B.2023'
               WHEN 'JPY' THEN
                'G01_5_9..C.2023'
               WHEN 'HKD' THEN
                'G01_5_9..D.2023'
               WHEN 'GBP' THEN
                'G01_5_9..E.2023'
               END AS ITEM_NUM, --指标号
             SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD ='1111'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_9..A.2023'
               WHEN 'EUR' THEN
                'G01_5_9..B.2023'
               WHEN 'JPY' THEN
                'G01_5_9..C.2023'
               WHEN 'HKD' THEN
                'G01_5_9..D.2023'
               WHEN 'GBP' THEN
                'G01_5_9..E.2023'
               END;
           COMMIT;

    --10. 固定资产原价
    V_STEP_ID   := '10';
    V_STEP_DESC := 'G01_5.10 固定资产原价';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --10. 固定资产净值
    V_STEP_ID   := '10';
    V_STEP_DESC := 'G01_5.10 固定资产原价';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             ITEM_NUM AS ITEM_NUM, --指标号
             SUM(ITEM_VAL) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE, --数据日期
                     ORG_NUM AS ORG_NUM, --机构号
                     'CBRC' AS SYS_NAM, --模块简称
                     'G01_5' AS REP_NUM, --报表编号
                     CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_10..A.2023'
               WHEN 'EUR' THEN
                'G01_5_10..B.2023'
               WHEN 'JPY' THEN
                'G01_5_10..C.2023'
               WHEN 'HKD' THEN
                'G01_5_10..D.2023'
               WHEN 'GBP' THEN
                'G01_5_10..E.2023'
               END AS ITEM_NUM, --指标号
                     SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
                     '1' AS FLAG
                FROM SMTMODS_L_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON B.DATA_DATE = I_DATADATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ITEM_CD = '1601'
                 AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
               GROUP BY A.ORG_NUM,
                        CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_10..A.2023'
               WHEN 'EUR' THEN
                'G01_5_10..B.2023'
               WHEN 'JPY' THEN
                'G01_5_10..C.2023'
               WHEN 'HKD' THEN
                'G01_5_10..D.2023'
               WHEN 'GBP' THEN
                'G01_5_10..E.2023'
               END
              UNION
              SELECT I_DATADATE AS DATA_DATE, --数据日期
                     ORG_NUM AS ORG_NUM, --机构号
                     'CBRC' AS SYS_NAM, --模块简称
                     'G01_5' AS REP_NUM, --报表编号
                     CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_10..A.2023'
               WHEN 'EUR' THEN
                'G01_5_10..B.2023'
               WHEN 'JPY' THEN
                'G01_5_10..C.2023'
               WHEN 'HKD' THEN
                'G01_5_10..D.2023'
               WHEN 'GBP' THEN
                'G01_5_10..E.2023'
               END AS ITEM_NUM, --指标号
                     -SUM(A.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
                     '1' AS FLAG
                FROM SMTMODS_L_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON B.DATA_DATE = I_DATADATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ITEM_CD = '1602'
                 AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
               GROUP BY A.ORG_NUM,
                        CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_10..A.2023'
               WHEN 'EUR' THEN
                'G01_5_10..B.2023'
               WHEN 'JPY' THEN
                'G01_5_10..C.2023'
               WHEN 'HKD' THEN
                'G01_5_10..D.2023'
               WHEN 'GBP' THEN
                'G01_5_10..E.2023'
               END)
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

    --11. 其他资产
    V_STEP_ID   := '11';
    V_STEP_DESC := 'G01_5.11 其他资产';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
       'G01_5' AS REP_NUM, --报表编号
       CASE CURR_CD
         WHEN 'USD' THEN
          'G01_5_11..A.2023'
         WHEN 'EUR' THEN
          'G01_5_11..B.2023'
         WHEN 'JPY' THEN
          'G01_5_11..C.2023'
         WHEN 'HKD' THEN
          'G01_5_11..D.2023'
         WHEN 'GBP' THEN
          'G01_5_11..E.2023'
       END AS ITEM_NUM, --指标号
       SUM(ITEM_VAL) AS ITEM_VAL, --指标值
       '1' AS FLAG
  FROM (
        ---预付账款
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('1123')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        UNION ALL
        --3打头（轧差）
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE
                      WHEN (A.DEBIT_BAL - A.CREDIT_BAL) > 0 THEN
                       ((A.DEBIT_BAL - A.CREDIT_BAL) * B.CCY_RATE)
                      ELSE
                       0
                    END) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('300101',
                             '300102',
                             '300103',
                             '300104',
                             '300105',
                             '300106',
                             '300107',
                             '300108',
                             '300109',
                             '300199',
                             '3002',
                             '3003',
                             '3007',--alter by 石雨 20250427 JLBA202504180011
                             '3004',
                             '3005',
                             '3006',
                             '3101',
                             '3500')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        UNION ALL
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL > 0 THEN
                   ITEM_VAL
                  ELSE
                   0
                END AS ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD = '3020' THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD = '3010' THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN ('3020', '3010')
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        UNION ALL
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL > 0 THEN
                   ITEM_VAL
                  ELSE
                   0
                END AS ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD = '3040' THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD = '3030' THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN ('3040', '3030')
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        UNION ALL
        ---待处理财产损溢
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM((A.DEBIT_BAL - A.CREDIT_BAL) * B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('1901')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        --利息调整利息调整及贴现公允价值变动
        UNION ALL
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM((A.DEBIT_BAL - A.CREDIT_BAL) * B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('13010102',
                             '13010105',
                             '13010202',
                             '13010205',
                             '13010302',
                             '13010402',
                             '13010406',
                             '13010502',
                             '13010506',
                             '13030102',
                             '13030202',
                             '13030302',
                             '13050102',
                             '13060102',
                             '13060202',
                             '13060302',
                             '13060402',
                             '13060502',
                             '13010404',
                             '13010408',
                             '13010504',
                             '13010508')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        --代理业务资产-负责
        UNION ALL
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL > 0 THEN
                   ITEM_VAL
                  ELSE
                   0
                END ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD IN ('1321') THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD = '2314' THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN ('1321', '2314')
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        UNION ALL
        --同业存单
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE
                      WHEN A.ITEM_CD IN
                           ('11010105', '11020105', '15010105', '15030105') THEN
                       A.DEBIT_BAL * B.CCY_RATE
                      WHEN A.ITEM_CD IN ('11010205',
                                         '11020205',
                                         '15010305',
                                         '15010505',
                                         '15030305',
                                         '15030505',
                                         '15030705') THEN
                       (A.DEBIT_BAL - A.CREDIT_BAL) * B.CCY_RATE
                    END) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('11010105',
                             '11020105',
                             '15010105',
                             '15030105',
                             '11010205',
                             '11020205',
                             '15010305',
                             '15010505',
                             '15030305',
                             '15030505',
                             '15030705')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        --投资性房地产
        UNION ALL
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE
                      WHEN A.ITEM_CD IN ('1521') THEN
                       A.DEBIT_BAL * B.CCY_RATE
                      WHEN A.ITEM_CD IN ('1522') THEN
                       (-1 * A.CREDIT_BAL) * B.CCY_RATE
                    END) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('1521', '1522')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        --财政差
        UNION ALL
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL > 0 THEN
                   ITEM_VAL
                  ELSE
                   0
                END ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD IN ('100303') THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD IN
                                   (/*'201103', */'201104', '201105', '201106' --[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款,原逻辑中剔除]
                                   ,'2005'/*,'2008','2009'*/ -- 修改内容：调整代理国库业务会计科目_20250513
                                     ) THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN
                        ('100303', /*'201103',*/ '201104', '201105', '201106'--[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款,原逻辑中剔除]
                        ,'2005'/*,'2008','2009'*/ -- 修改内容：调整代理国库业务会计科目_20250513
                           )
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        UNION ALL
        --合同资产--使用权资产--继续涉入资产
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE
                      WHEN A.ITEM_CD IN ('1607', '1518') THEN
                       (A.DEBIT_BAL - A.CREDIT_BAL) * B.CCY_RATE
                      WHEN A.ITEM_CD = '1609' THEN
                       A.DEBIT_BAL * B.CCY_RATE
                      WHEN A.ITEM_CD = '1610' THEN
                       A.CREDIT_BAL * B.CCY_RATE
                    END) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('1607', '1609', '1610', '1518')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
          union all
      SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(a.DEBIT_BAL*B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('1431','1132','1221','1801','1606','1604','1701','1441','1811')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
      union all
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(-1 * A.CREDIT_BAL*B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('1221','1702')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
  ---福费廷公允价值变动13010304 借-贷
          union all
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM((A.DEBIT_BAL - A.CREDIT_BAL)*B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('13010304')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD

         )
 GROUP BY ORG_NUM,
          CASE CURR_CD
            WHEN 'USD' THEN
             'G01_5_11..A.2023'
            WHEN 'EUR' THEN
             'G01_5_11..B.2023'
            WHEN 'JPY' THEN
             'G01_5_11..C.2023'
            WHEN 'HKD' THEN
             'G01_5_11..D.2023'
            WHEN 'GBP' THEN
             'G01_5_11..E.2023'
          END;

    COMMIT;

    --11.1投资同业存单
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
       'G01_5' AS REP_NUM, --报表编号
       CASE CURR_CD
         WHEN 'USD' THEN
          'G01_5_11.1.A.2023'
         WHEN 'EUR' THEN
          'G01_5_11.1.B.2023'
         WHEN 'JPY' THEN
          'G01_5_11.1.C.2023'
         WHEN 'HKD' THEN
          'G01_5_11.1.D.2023'
         WHEN 'GBP' THEN
          'G01_5_11.1.E.2023'
       END AS ITEM_NUM, --指标号
       SUM(case
             when A.ITEM_CD IN ('11010105', '11020105', '15010105', '15030105') THEN
              A.DEBIT_BAL
             WHEN A.ITEM_CD IN ('11010205',
                                '11020205',
                                '15010305',
                                '15010505',
                                '15030305',
                                '15030505',
                                '15030705') THEN
              (A.DEBIT_BAL - A.CREDIT_BAL)
           END

           * B.CCY_RATE) AS ITEM_VAL, --指标值
       '1' AS FLAG
  FROM SMTMODS_L_FINA_GL A
  LEFT JOIN SMTMODS_L_PUBL_RATE B
    ON B.DATA_DATE = I_DATADATE
   AND A.CURR_CD = B.BASIC_CCY
   AND B.FORWARD_CCY = 'CNY'
 WHERE A.DATA_DATE = I_DATADATE
   AND A.ITEM_CD IN ('11010105',
                     '11020105',
                     '15010105',
                     '15030105',
                     '11010205',
                     '11020205',
                     '15010305',
                     '15010505',
                     '15030305',
                     '15030505',
                     '15030705')
   AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
 GROUP BY A.ORG_NUM,
          CASE CURR_CD
            WHEN 'USD' THEN
             'G01_5_11.1.A.2023'
            WHEN 'EUR' THEN
             'G01_5_11.1.B.2023'
            WHEN 'JPY' THEN
             'G01_5_11.1.C.2023'
            WHEN 'HKD' THEN
             'G01_5_11.1.D.2023'
            WHEN 'GBP' THEN
             'G01_5_11.1.E.2023'
          END;
    COMMIT;
    --11.2衍生金融资产
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_11.2.A.2023'
               WHEN 'EUR' THEN
                'G01_5_11.2.B.2023'
               WHEN 'JPY' THEN
                'G01_5_11.2.C.2023'
               WHEN 'HKD' THEN
                'G01_5_11.2.D.2023'
               WHEN 'GBP' THEN
                'G01_5_11.2.E.2023'
               END AS ITEM_NUM, --指标号
             SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('3101')
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_11.2.A.2023'
               WHEN 'EUR' THEN
                'G01_5_11.2.B.2023'
               WHEN 'JPY' THEN
                'G01_5_11.2.C.2023'
               WHEN 'HKD' THEN
                'G01_5_11.2.D.2023'
               WHEN 'GBP' THEN
                'G01_5_11.2.E.2023'
               END;
    COMMIT;

    --12.各项资产减值损失准备
    V_STEP_ID   := '12';
    V_STEP_DESC := 'G01_5.12 各项资产减值损失准备';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_12..A.2023'
               WHEN 'EUR' THEN
                'G01_5_12..B.2023'
               WHEN 'JPY' THEN
                'G01_5_12..C.2023'
               WHEN 'HKD' THEN
                'G01_5_12..D.2023'
               WHEN 'GBP' THEN
                'G01_5_12..E.2023'
               END AS ITEM_NUM, --指标号
             SUM(A.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('1013','1112','1231','1304','1307','1442','1482','1502','1512','1523','1603','1605','1608','1611','1703','1712')
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_12..A.2023'
               WHEN 'EUR' THEN
                'G01_5_12..B.2023'
               WHEN 'JPY' THEN
                'G01_5_12..C.2023'
               WHEN 'HKD' THEN
                'G01_5_12..D.2023'
               WHEN 'GBP' THEN
                'G01_5_12..E.2023'
               END;
    COMMIT;

    --14.单位存款
    V_STEP_ID   := '14';
    V_STEP_DESC := 'G01_5.14 单位存款';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END AS ITEM_NUM,
             SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         AND ITEM_CD IN ('20110201',
                         '20110205',
                         '20110202',
                         '20110203',
                         '20110204',
                         '20110211', -- 转股协议存款 原逻辑没有
                         '20110701',
                         '2010', --alter by 20250527 修改国库存款科目
                         '20110206',
                         '20110207',
                         '20110208',
                         '20120106',
                         '20120204'
                          ,'20110301','20110302','20110303' --[JLBA202507210012][石雨][20250918][修改内容：201103（财政性存款 ）调整为 一般单位活期存款]
                         ,'22410101' --单位久悬未取款--[JLBA202507210012][石雨][20250918][修改内容：224101久悬未取款属于活期存款]
                         ,'20080101','20090101' --[JLBA202507210012][石雨][20250918]
                         )
      /*('201', '202', '205', '206', '218', '21901', '22001','234010204','2340204')*/ --老核心科目
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END;
    COMMIT;

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             CASE
               /*WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END;
    COMMIT;

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             CASE
              /* WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END;
    COMMIT;

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             CASE
/*               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END;
    COMMIT;

    --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]剔除个体工商户部分

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL --
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
   SELECT I_DATADATE AS DATA_DATE,
             CASE
/*               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN T.ORG_NUM NOT LIKE '__98%' AND T.ORG_NUM NOT LIKE '5%' AND T.ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
               ELSE
                T.ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END AS ITEM_NUM,
    SUM(T.ACCT_BALANCE * B.CCY_RATE) * -1 AS ITEM_VAL,
    '1' AS FLAG
     from SMTMODS_L_ACCT_DEPOSIT T
    INNER JOIN SMTMODS_L_CUST_C C
       ON T.DATA_DATE = C.DATA_DATE
      AND T.CUST_ID = C.CUST_ID
    INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
       ON T.DATA_DATE = B.DATA_DATE
      AND T.CURR_CD = B.BASIC_CCY
      AND B.FORWARD_CCY = 'CNY' --折人民币
    where c.deposit_custtype in ('13', '14')
      and t.gl_item_code IN ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
      AND T.ACCT_BALANCE > 0
      AND T.DATA_DATE = I_DATADATE
        AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
    GROUP BY CASE
/*               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN T.ORG_NUM NOT LIKE '__98%' AND T.ORG_NUM NOT LIKE '5%' AND T.ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
               ELSE
                T.ORG_NUM
             END,CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END
             ;
    COMMIT;


    --15.储蓄存款
    V_STEP_ID   := '15';
    V_STEP_DESC := 'G01_5.15 储蓄存款';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END AS ITEM_NUM,
             SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
            --AND ITEM_CD in ('203','211','215','217','21902','22002')
         AND ITEM_CD IN ('20110110',
                         '20110101',
                         '20110102',
                         '20110103',
                         '20110104',
                         '20110105',
                         '20110106',
                         '20110107',
                         '20110108',
                         '20110109',
                         '20110111',
                         '20110112',
                         '20110113'
                         ,'22410102' --个人久悬未取款--[JLBA202507210012][石雨][修改内容：224101久悬未取款属于活期存款]
                         )
      /*  ('203', '211', '215', '217', '21902', '22002'\*,'201_13'*\) --lrt 20170927  -- 修改201_13科目从视图过滤 lfz 20220614*/ --老核心科目
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END;
    COMMIT;

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             CASE
       /*      WHEN ORG_NUM NOT LIKE '__98%' THEN
              SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END;
    COMMIT;

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             CASE
             /*  WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END;
    COMMIT;

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             CASE
              /* WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END;
    COMMIT;


 INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL --
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
   SELECT I_DATADATE AS DATA_DATE,
             CASE
/*               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN T.ORG_NUM NOT LIKE '__98%' AND T.ORG_NUM NOT LIKE '5%' AND T.ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
               ELSE
                T.ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END AS ITEM_NUM,
    SUM(T.ACCT_BALANCE * B.CCY_RATE)  AS ITEM_VAL,
    '1' AS FLAG
     from SMTMODS_L_ACCT_DEPOSIT T
    INNER JOIN SMTMODS_L_CUST_C C
       ON T.DATA_DATE = C.DATA_DATE
      AND T.CUST_ID = C.CUST_ID
    INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
       ON T.DATA_DATE = B.DATA_DATE
      AND T.CURR_CD = B.BASIC_CCY
      AND B.FORWARD_CCY = 'CNY' --折人民币
    where c.deposit_custtype in ('13', '14')
      and t.gl_item_code IN ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
      AND T.ACCT_BALANCE > 0
      AND T.DATA_DATE = I_DATADATE
        AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
    GROUP BY CASE
/*               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN T.ORG_NUM NOT LIKE '__98%' AND T.ORG_NUM NOT LIKE '5%' AND T.ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
               ELSE
                T.ORG_NUM
             END,CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END
             ;
    COMMIT;




    --16.向中央银行借款
    V_STEP_ID   := '16';
    V_STEP_DESC := 'G01_5.16 向中央银行借款';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_16..A.2023'
               WHEN 'EUR' THEN
                'G01_5_16..B.2023'
               WHEN 'JPY' THEN
                'G01_5_16..C.2023'
               WHEN 'HKD' THEN
                'G01_5_16..D.2023'
               WHEN 'GBP' THEN
                'G01_5_16..E.2023'
               END AS ITEM_NUM, --指标号
             SUM(A.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '2004'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_16..A.2023'
               WHEN 'EUR' THEN
                'G01_5_16..B.2023'
               WHEN 'JPY' THEN
                'G01_5_16..C.2023'
               WHEN 'HKD' THEN
                'G01_5_16..D.2023'
               WHEN 'GBP' THEN
                'G01_5_16..E.2023'
               END;
    COMMIT;

     --17.同业存放款项
    V_STEP_ID   := '17';
    V_STEP_DESC := 'G01_5.17 同业存放款项';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_17..A.2023'
               WHEN 'EUR' THEN
                'G01_5_17..B.2023'
               WHEN 'JPY' THEN
                'G01_5_17..C.2023'
               WHEN 'HKD' THEN
                'G01_5_17..D.2023'
               WHEN 'GBP' THEN
                'G01_5_17..E.2023'
               END AS ITEM_NUM, --指标号
             SUM(CASE ITEM_CD
                   WHEN '2012' THEN
                    A.CREDIT_BAL * B.CCY_RATE
                   ELSE

                    -1 * A.CREDIT_BAL * B.CCY_RATE
                 END) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('2012', '20120106','20120204')
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_17..A.2023'
               WHEN 'EUR' THEN
                'G01_5_17..B.2023'
               WHEN 'JPY' THEN
                'G01_5_17..C.2023'
               WHEN 'HKD' THEN
                'G01_5_17..D.2023'
               WHEN 'GBP' THEN
                'G01_5_17..E.2023'
               END;
    COMMIT;
    --18.同业拆入
    V_STEP_ID   := '18';
    V_STEP_DESC := 'G01_5.18 同业拆入';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             '009801' AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_18..A.2023'
               WHEN 'EUR' THEN
                'G01_5_18..B.2023'
               WHEN 'JPY' THEN
                'G01_5_18..C.2023'
               WHEN 'HKD' THEN
                'G01_5_18..D.2023'
               WHEN 'GBP' THEN
                'G01_5_18..E.2023'
               END AS ITEM_NUM,
             SUM(A.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('2003')
         AND A.ORG_NUM = '009801'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_18..A.2023'
               WHEN 'EUR' THEN
                'G01_5_18..B.2023'
               WHEN 'JPY' THEN
                'G01_5_18..C.2023'
               WHEN 'HKD' THEN
                'G01_5_18..D.2023'
               WHEN 'GBP' THEN
                'G01_5_18..E.2023'
               END;
    COMMIT;
     --19.卖出回购款项
   V_STEP_ID   := '19';
    V_STEP_DESC := 'G01_5.19 卖出回购款项';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_19..A.2023'
               WHEN 'EUR' THEN
                'G01_5_19..B.2023'
               WHEN 'JPY' THEN
                'G01_5_19..C.2023'
               WHEN 'HKD' THEN
                'G01_5_19..D.2023'
               WHEN 'GBP' THEN
                'G01_5_19..E.2023'
               END AS ITEM_NUM, --指标号
             SUM( A.CREDIT_BAL * B.CCY_RATE ) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD ='2111'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_19..A.2023'
               WHEN 'EUR' THEN
                'G01_5_19..B.2023'
               WHEN 'JPY' THEN
                'G01_5_19..C.2023'
               WHEN 'HKD' THEN
                'G01_5_19..D.2023'
               WHEN 'GBP' THEN
                'G01_5_19..E.2023'
               END;
    COMMIT;

    --20.应付债券
    V_STEP_ID   := '20';
    V_STEP_DESC := 'G01_5.20 应付债券';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_20..A.2023'
               WHEN 'EUR' THEN
                'G01_5_20..B.2023'
               WHEN 'JPY' THEN
                'G01_5_20..C.2023'
               WHEN 'HKD' THEN
                'G01_5_20..D.2023'
               WHEN 'GBP' THEN
                'G01_5_20..E.2023'
               END AS ITEM_NUM, --指标号
             SUM(A.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '250201'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_20..A.2023'
               WHEN 'EUR' THEN
                'G01_5_20..B.2023'
               WHEN 'JPY' THEN
                'G01_5_20..C.2023'
               WHEN 'HKD' THEN
                'G01_5_20..D.2023'
               WHEN 'GBP' THEN
                'G01_5_20..E.2023'
               END;
    COMMIT;

    --21.其他负债
    V_STEP_ID   := '21';
    V_STEP_DESC := 'G01_5.21 其他负债';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
       'G01_5' AS REP_NUM, --报表编号
       CASE CURR_CD
         WHEN 'USD' THEN
          'G01_5_21..A.2023'
         WHEN 'EUR' THEN
          'G01_5_21..B.2023'
         WHEN 'JPY' THEN
          'G01_5_21..C.2023'
         WHEN 'HKD' THEN
          'G01_5_21..D.2023'
         WHEN 'GBP' THEN
          'G01_5_21..E.2023'
       END AS ITEM_NUM, --指标号
       SUM(ITEM_VAL) AS ITEM_VAL, --指标值
       '1' AS FLAG
  FROM (
        --资金清算应付款
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE
                      WHEN (A.CREDIT_BAL - A.DEBIT_BAL) > 0 THEN
                       ((A.CREDIT_BAL - A.DEBIT_BAL) * B.CCY_RATE)
                      ELSE
                       0
                    END) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('2240')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        union all
        --向央行借款  贴现负债  开出本票  交易性金融负债 指定为以公允价值计量且其变动计入损益的金融负债
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(A.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('20040202', '2021', '2015', '2101', '2102')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        --同业存单
        union all
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM((A.CREDIT_BAL - A.DEBIT_BAL) * B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('25020102', '250202')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        union all
        ---代理业务负责-资产
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL < 0 THEN
                   -1 * ITEM_VAL
                  ELSE
                   0
                END AS ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD = '1321' THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD = '2314' THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN ('1321', '2314')
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        union all
        ------------------------------------
        --3头轧差
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE
                      WHEN (A.DEBIT_BAL - A.CREDIT_BAL) < 0 THEN
                       -1 * ((A.DEBIT_BAL - A.CREDIT_BAL) * B.CCY_RATE)
                      ELSE
                       0
                    END) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('300101',
                             '300102',
                             '300103',
                             '300104',
                             '300105',
                             '300106',
                             '300107',
                             '300108',
                             '300109',
                             '300199',
                             '3002',
                             '3003',
                             '3007', --alter by 石雨 JLBA202504180011
                             '3004',
                             '3005',
                             '3006',
                             '3101',
                             '3500')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        UNION ALL
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL < 0 THEN
                   -1 * ITEM_VAL
                  ELSE
                   0
                END AS ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD = '3020' THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD = '3010' THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN ('3020', '3010')
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        UNION ALL
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL < 0 THEN
                   -1 * ITEM_VAL
                  ELSE
                   0
                END AS ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD = '3040' THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD = '3030' THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN ('3040', '3030')
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        -----
        union all
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL < 0 THEN
                   -1 * ITEM_VAL
                  ELSE
                   0
                END ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD IN ('100303') THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD IN
                                   (/*'201103',*/ '201104', '201105', '201106' --[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款,原逻辑中剔除]
                                   ,'2005'/*,'2008','2009'*/ -- 修改内容：调整代理国库业务会计科目_20250513
                                   ) THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN
                        ('100303', /*'201103', */'201104', '201105', '201106'--[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款,原逻辑中剔除]
                        ,'2005'/*,'2008','2009'*/ -- 修改内容：调整代理国库业务会计科目_20250513
                        )
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        union all
        ---合同负债 --继续涉入负债 --租赁负债 --衍生工具
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(case
                      when A.ITEM_CD IN ('2505', '2504', '3101') then
                       A.CREDIT_BAL * B.CCY_RATE
                      when A.ITEM_CD = '2503' then

                       (A.CREDIT_BAL - A.DEBIT_BAL) * B.CCY_RATE
                    end) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('2505', '2504', '3101', '2503')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
         UNION ALL
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE WHEN A.ITEM_CD IN ('2014','2221') THEN (A.CREDIT_BAL-

                a.DEBIT_BAL) *B.CCY_RATE
                  ELSE A.CREDIT_BAL *B.CCY_RATE END ) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('2014','2013','20110114','20110115','20110209','20110210','2231','2221','2211','2232','2241','2401','2801','2901')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
         UNION ALL
         SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM( A.CREDIT_BAL *B.CCY_RATE *-1 ) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('201103','2008','2009','224101')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD

         )
 group by ORG_NUM,
          CASE CURR_CD
            WHEN 'USD' THEN
             'G01_5_21..A.2023'
            WHEN 'EUR' THEN
             'G01_5_21..B.2023'
            WHEN 'JPY' THEN
             'G01_5_21..C.2023'
            WHEN 'HKD' THEN
             'G01_5_21..D.2023'
            WHEN 'GBP' THEN
             'G01_5_21..E.2023'
          END;

    COMMIT;

    --21.1发行同业存单
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_21.1.A.2023'
               WHEN 'EUR' THEN
                'G01_5_21.1.B.2023'
               WHEN 'JPY' THEN
                'G01_5_21.1.C.2023'
               WHEN 'HKD' THEN
                'G01_5_21.1.D.2023'
               WHEN 'GBP' THEN
                'G01_5_21.1.E.2023'
               END AS ITEM_NUM, --指标号
             SUM(A.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '250202'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_21.1.A.2023'
               WHEN 'EUR' THEN
                'G01_5_21.1.B.2023'
               WHEN 'JPY' THEN
                'G01_5_21.1.C.2023'
               WHEN 'HKD' THEN
                'G01_5_21.1.D.2023'
               WHEN 'GBP' THEN
                'G01_5_21.1.E.2023'
               END;
    COMMIT;
    --21.2衍生金融负债
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_21.2.A.2023'
               WHEN 'EUR' THEN
                'G01_5_21.2.B.2023'
               WHEN 'JPY' THEN
                'G01_5_21.2.C.2023'
               WHEN 'HKD' THEN
                'G01_5_21.2.D.2023'
               WHEN 'GBP' THEN
                'G01_5_21.2.E.2023'
               END AS ITEM_NUM, --指标号
             SUM(A.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('3101')
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_21.2.A.2023'
               WHEN 'EUR' THEN
                'G01_5_21.2.B.2023'
               WHEN 'JPY' THEN
                'G01_5_21.2.C.2023'
               WHEN 'HKD' THEN
                'G01_5_21.2.D.2023'
               WHEN 'GBP' THEN
                'G01_5_21.2.E.2023'
               END;
    COMMIT;

    --23.少数股东权益

    --24.所有者权益
    INSERT INTO CBRC_TMP_G0105_A_REPT_ITEM_VAL
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
       'G01_5' AS REP_NUM, --报表编号
       CASE CURR_CD
         WHEN 'USD' THEN
          'G01_5_24..A.2023'
         WHEN 'EUR' THEN
          'G01_5_24..B.2023'
         WHEN 'JPY' THEN
          'G01_5_24..C.2023'
         WHEN 'HKD' THEN
          'G01_5_24..D.2023'
         WHEN 'GBP' THEN
          'G01_5_24..E.2023'
       END AS ITEM_NUM, --指标号
       SUM(case
             when A.ITEM_CD IN ('4001', '4002', '4101', '4102') THEN
              A.CREDIT_BAL
             WHEN A.ITEM_CD IN ('4003',
                                '4104',
                                '6011',
                                '6012',
                                '6021',
                                '6051',
                                '6061',
                                '6101',
                                '6111',
                                '6115',
                                '6116',
                                '6117',
                                '6301',
                                '6402',
                                '6403',
                                '6411',
                                '6412',
                                '6421',
                                '6601',
                                '6701',
                                '6702',
                                '6711',
                                '6801',
                                '6901') THEN
              (A.CREDIT_BAL - A.DEBIT_BAL)
           END

           * B.CCY_RATE) AS ITEM_VAL, --指标值
       '1' AS FLAG
  FROM SMTMODS_L_FINA_GL A
  LEFT JOIN SMTMODS_L_PUBL_RATE B
    ON B.DATA_DATE = I_DATADATE
   AND A.CURR_CD = B.BASIC_CCY
   AND B.FORWARD_CCY = 'CNY'
 WHERE A.DATA_DATE = I_DATADATE
   AND A.ITEM_CD IN ('4001',
                     '4002',
                     '4101',
                     '4102',
                     '4003',
                     '4104',
                     '6011',
                     '6012',
                     '6021',
                     '6051',
                     '6061',
                     '6101',
                     '6111',
                     '6115',
                     '6116',
                     '6117',
                     '6301',
                     '6402',
                     '6403',
                     '6411',
                     '6412',
                     '6421',
                     '6601',
                     '6701',
                     '6702',
                     '6711',
                     '6801',
                     '6901')
   AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
 GROUP BY A.ORG_NUM,
          CASE CURR_CD
         WHEN 'USD' THEN
          'G01_5_24..A.2023'
         WHEN 'EUR' THEN
          'G01_5_24..B.2023'
         WHEN 'JPY' THEN
          'G01_5_24..C.2023'
         WHEN 'HKD' THEN
          'G01_5_24..D.2023'
         WHEN 'GBP' THEN
          'G01_5_24..E.2023'
       END;
  COMMIT ;
  --------------------------------------------------------------------------

    --插入实际表
INSERT INTO CBRC_A_REPT_ITEM_VAL
  (DATA_DATE, -- 数据日期
   ORG_NUM, --机构号
   SYS_NAM, --模块简称
   REP_NUM, --报表编号
   ITEM_NUM, --指标号
   ITEM_VAL, --指标值
   FLAG, --标志位
   IS_TOTAL)
  SELECT I_DATADATE AS DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         SUM(ITEM_VAL), --指标值
         FLAG, --标志位
         CASE
           WHEN ITEM_NUM IN ('G01_5_21..A.2023',
                  'G01_5_24..C.2023',
                  'G01_5_11..B.2023',
                  'G01_5_11..A.2023',
                  'G01_5_11..D.2023',
                  'G01_5_21..B.2023',
                  'G01_5_21..C.2023',
                  'G01_5_11..C.2023',
                  'G01_5_21..D.2023',
                  'G01_5_21..E.2023',
                  'G01_5_24..B.2023',
                  'G01_5_24..A.2023',
                  'G01_5_11..E.2023',
                  'G01_5_24..D.2023',
                  'G01_5_24..E.2023') THEN --MODI BY DJH 20230509不参与汇总
            'N'
         END IS_TOTAL
    FROM CBRC_TMP_G0105_A_REPT_ITEM_VAL
   GROUP BY ORG_NUM, --机构号
            SYS_NAM, --模块简称
            REP_NUM, --报表编号
            ITEM_NUM, --指标号
            FLAG --标志位
      ;
    COMMIT;
	
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
END proc_cbrc_idx2_g0105