CREATE OR REPLACE PROCEDURE PROC_CBRC_IDX2_G12(II_DATADATE  IN STRING  --跑批日期
                                                 )
/******************************
  @AUTHOR:FANXIAOYU
  @CREATE-DATE:2015-09-22
  @DESCRIPTION:G12
  @MODIFICATION HISTORY:
  M0.20150919-FANXIAOYU-G12
  M1.现L层无法满足标准口径数据，信用卡数据放在SP_CBRC_IDX2_G12_card加工
  m2. alter by shiyu  李淑敏提供：贴现业务也统计
   --需求编号: JLBA202507300010_关于新一代信贷管理系统新增线上微贷板块的需求 上线日期：20250929 修改人：石雨 提出人：于佳禾 新增吉慧贷产品
   
   
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_G12_XYK_TEMP
     CBRC_PUB_DATA_COLLECT_G12
     CBRC_PUB_DATA_G12
集市表：SMTMODS.L_ACCT_CARD_CREDIT
     SMTMODS_L_ACCT_FUND_INVEST
     SMTMODS_L_ACCT_LOAN
     SMTMODS_L_ACCT_WRITE_OFF
     SMTMODS_L_PUBL_RATE
     SMTMODS_L_TRAN_CARD_CREDIT_TX
     SMTMODS_L_TRAN_LOAN_PAYM

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
  I_BEGINOFYEAR  INTEGER; --年初日期
  I_LAST_YEAR    INTEGER; --上年末日期
  V_LAST_YEAR    VARCHAR(10); --上年末日期
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE  := II_DATADATE;
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G12');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_TAB_NAME     := 'G12';
    I_BEGINOFYEAR  := TO_CHAR(TRUNC(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY'),'YYYYMMDD');
	
    I_LAST_YEAR    := SUBSTR(I_DATADATE, 0, 4) - 1 || '1231';
	
    V_LAST_YEAR    := TO_CHAR(TO_DATE(I_LAST_YEAR, 'YYYYMMDD'),'YYYYMMDD');
    D_DATADATE_CCY := I_DATADATE;

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
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = V_TAB_NAME
       AND FLAG = '2';
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 2;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G12_2..B';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G12 2.本期增加
    --====================================================
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_PUB_DATA_G12';
    INSERT INTO CBRC_PUB_DATA_G12
      (BALANCE_UP, --金额余额
       ORG_NUM)
      SELECT SUM((A.DRAWDOWN_AMT - A.LOAN_ACCT_BAL) * U.CCY_RATE) AS BALANCE_UP, --金额余额
             A.ORG_NUM
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE TO_CHAR(DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4)
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.ACCT_TYP NOT LIKE 'E%'
         AND A.ORG_NUM <> '009803'
         and a.cancel_flg <> 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
       GROUP BY A.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_G12
      (BALANCE_4, --金额余额
       ORG_NUM)
      SELECT SUM((T.ATM - T.FACE_VAL) * U.CCY_RATE) AS BALANCE_4, --A.发生额-A.账面余额
             T.ORG_NUM
        FROM SMTMODS_L_ACCT_FUND_INVEST T --投资业务信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE TO_CHAR(T.TX_DATE, 'YYYY') = SUBSTR(I_DATADATE, 1, 4)
         AND T.INVEST_TYP = '11' --投资业务品种(买断式转贴现)
       GROUP BY T.ORG_NUM;
    COMMIT;



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
             'G12' AS REP_NUM, --报表编号
             'G12_2..B' AS ITEM_NUM, --指标号
             SUM(NVL(BALANCE_UP, 0) + NVL(BALANCE_4, 0) + NVL(BALANCE_5, 0)) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM CBRC_PUB_DATA_G12
       GROUP BY ORG_NUM;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := 'G12 2.本期增加  逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 2;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '2.本期增加,正常类贷款-损失类贷款  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G12   2.本期增加,正常类贷款-损失类贷款
    --====================================================
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
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN LOAN_GRADE_CD = '1' THEN
                        'G12_2..C'
                       WHEN LOAN_GRADE_CD = '2' THEN
                        'G12_2..D'
                       WHEN LOAN_GRADE_CD = '3' THEN
                        'G12_2..E'
                       WHEN LOAN_GRADE_CD = '4' THEN
                        'G12_2..F'
                       WHEN LOAN_GRADE_CD = '5' THEN
                        'G12_2..G'
                     END AS ITEM_NUM, --指标号
                     SUM(LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE (TO_CHAR(A.DRAWDOWN_DT, 'YYYY') =
                     SUBSTR(I_DATADATE, 1, 4) OR
                     (A.INTERNET_LOAN_FLG = 'Y' AND
                     A.DRAWDOWN_DT =
                     (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                     OR (A.cp_id IN  ('DK001000100041') AND A.DRAWDOWN_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                     )
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                    --AND ITEM_CD NOT LIKE '129%' --本指标2022年一月份打开  20211029  ZHOUJINGKUN
                    -- AND SUBSTR(ITEM_CD,1,4) NOT LIKE '1301%' --M2
                    --AND A.ITEM_CD NOT IN ('12902', '12906') --刨除票据转贴现  20220421 shiyu
                    -- AND SUBSTR(A.ITEM_CD,1,6) NOT IN('130102','130105')  --刨除票据转贴现 --M2
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND A.ORG_NUM <> '009803'
                 and a.cancel_flg <> 'Y'
                 AND A.DATA_DATE = I_DATADATE --LRT 20180111
                 and A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_2..C'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_2..D'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_2..E'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_2..F'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_2..G'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '2.本期增加,正常类贷款-损失类贷款  逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 3;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '2.本期增加,本年不良贷款处置情况  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G12 2.本期增加,本年不良贷款处置情况
    --====================================================
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_PUB_DATA_G12';
    INSERT INTO CBRC_PUB_DATA_G12
      (BALANCE_UP, --金额余额
       ORG_NUM,
       FLAG_TMP)
      SELECT SUM(B.PAY_AMT * U.CCY_RATE) AS BALANCE_UP, --金额余额
             A.ORG_NUM,
             LOAN_GRADE_CD
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND (TO_CHAR(B.Repay_Dt, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) OR
             (A.INTERNET_LOAN_FLG = 'Y' AND
             B.REPAY_DT =
             (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
             OR (A.cp_id IN  ('DK001000100041') AND B.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

             )
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE (TO_CHAR(DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) OR
             (A.INTERNET_LOAN_FLG = 'Y' AND
             B.REPAY_DT =
             (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
            OR (A.cp_id IN  ('DK001000100041') AND B.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

        )
         AND A.ACCT_TYP NOT LIKE '90%'
         and a.cancel_flg <> 'Y'
         AND A.DATA_DATE = I_DATADATE --LRT 20170111
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
       GROUP BY A.ORG_NUM, LOAN_GRADE_CD;
    COMMIT;

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
             'G12' AS REP_NUM, --报表编号
             CASE
               WHEN FLAG_TMP = '3' THEN
                'G12_2..L'
               WHEN FLAG_TMP = '4' THEN
                'G12_2..M'
               WHEN FLAG_TMP = '5' THEN
                'G12_2..N'
             END AS ITEM_NUM, --指标号
             SUM(NVL(BALANCE_UP, 0) + NVL(BALANCE_DOWN, 0)) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM CBRC_PUB_DATA_G12
       WHERE FLAG_TMP IN ('3', '4', '5')
       GROUP BY ORG_NUM,
                CASE
                  WHEN FLAG_TMP = '3' THEN
                   'G12_2..L'
                  WHEN FLAG_TMP = '4' THEN
                   'G12_2..M'
                  WHEN FLAG_TMP = '5' THEN
                   'G12_2..N'
                END;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '2.本期增加,本年不良贷款处置情况  逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 4;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '本期减少,本年不良贷款处置情况，正常-损失  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G12 本期减少,本年不良贷款处置情况，正常-损失
    --====================================================
    

    --G12.3..C
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
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..C'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..C'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..C'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..C'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..C'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND A.ACCT_TYP NOT LIKE 'E%'
                 AND B.LOAN_GRADE_CD = '1'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 and a.cancel_flg <> 'Y'
                 AND A.ORG_NUM <> '009803'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..C'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..C'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..C'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..C'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..C'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

    --G12.3..D

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
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..D'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..D'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..D'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..D'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..D'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '2'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..D'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..D'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..D'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..D'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..D'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

    --G12.3..E

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
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..E'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..E'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..E'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..E'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..E'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '3'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..E'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..E'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..E'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..E'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..E'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

    --G12.3..F

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
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..F'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..F'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..F'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..F'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..F'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '4'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..F'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..F'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..F'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..F'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..F'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

    --G12.3..G

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
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..G'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..G'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..G'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..G'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..G'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '5'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..G'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..G'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..G'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..G'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..G'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '本期减少,本年不良贷款处置情况，正常-损失  逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 5;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '贷款质量迁徙情况,正常类贷款-损失  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G12   贷款质量迁徙情况,正常类贷款-损失
    --====================================================
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
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        (CASE
                          WHEN A.RESCHED_FLG = 'Y' THEN
                           'G12_3..J'
                          WHEN A.RESCHED_FLG = 'N' THEN
                           'G12_3..K'
                        END)
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        (CASE
                          WHEN A.RESCHED_FLG = 'Y' THEN --重组标志
                           'G12_4..J'
                          WHEN A.RESCHED_FLG = 'N' THEN
                           'G12_4..K'
                        END)
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD = '1'
                 AND B.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.ACCT_TYP <> '3'
                 and b.cancel_flg <> 'Y'
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           (CASE
                             WHEN A.RESCHED_FLG = 'Y' THEN
                              'G12_3..J'
                             WHEN A.RESCHED_FLG = 'N' THEN
                              'G12_3..K'
                           END)
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           (CASE
                             WHEN A.RESCHED_FLG = 'Y' THEN
                              'G12_4..J'
                             WHEN A.RESCHED_FLG = 'N' THEN
                              'G12_4..K'
                           END)
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

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
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        (CASE
                          WHEN A.RESCHED_FLG = 'Y' AND
                               B.LOAN_GRADE_CD IN ('1', '2') THEN
                           'G12_5..J'
                          WHEN A.RESCHED_FLG = 'N' AND
                               B.LOAN_GRADE_CD IN ('1', '2') THEN
                           'G12_5..K'
                        END)
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        (CASE
                          WHEN A.RESCHED_FLG = 'Y' AND
                               B.LOAN_GRADE_CD IN ('1', '2') THEN
                           'G12_6..J'
                          WHEN A.RESCHED_FLG = 'N' AND
                               B.LOAN_GRADE_CD IN ('1', '2') THEN
                           'G12_6..K'
                        END)
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        (CASE
                          WHEN A.RESCHED_FLG = 'Y' AND
                               B.LOAN_GRADE_CD IN ('1', '2') THEN
                           'G12_7..J'
                          WHEN A.RESCHED_FLG = 'N' AND
                               B.LOAN_GRADE_CD IN ('1', '2') THEN
                           'G12_7..K'
                        END)
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD = '1'
                 AND B.LOAN_GRADE_CD IN ('1', '2')
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.ACCT_TYP <> '3'
                 AND A.ACCT_TYP NOT LIKE '90%'
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           (CASE
                             WHEN A.RESCHED_FLG = 'Y' AND
                                  B.LOAN_GRADE_CD IN ('1', '2') THEN
                              'G12_5..J'
                             WHEN A.RESCHED_FLG = 'N' AND
                                  B.LOAN_GRADE_CD IN ('1', '2') THEN
                              'G12_5..K'
                           END)
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           (CASE
                             WHEN A.RESCHED_FLG = 'Y' AND
                                  B.LOAN_GRADE_CD IN ('1', '2') THEN
                              'G12_6..J'
                             WHEN A.RESCHED_FLG = 'N' AND
                                  B.LOAN_GRADE_CD IN ('1', '2') THEN
                              'G12_6..K'
                           END)
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           (CASE
                             WHEN A.RESCHED_FLG = 'Y' AND
                                  B.LOAN_GRADE_CD IN ('1', '2') THEN
                              'G12_7..J'
                             WHEN A.RESCHED_FLG = 'N' AND
                                  B.LOAN_GRADE_CD IN ('1', '2') THEN
                              'G12_7..K'
                           END)
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '贷款质量迁徙情况,正常类贷款-损失  逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '本年不良贷款处置情况,次级-损失  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G12   本年不良贷款处置情况,次级-损失
    --====================================================
    --修改 LRT 20180115
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
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..L'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..L'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..L'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..L'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..L'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                              OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(s.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                               OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '3') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND A.CANCEL_FLG <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..L'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..L'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..L'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..L'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..L'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

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
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..M'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..M'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..M'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..M'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..M'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取不到，本月取
                              OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(S.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                             OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '4') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 and a.cancel_flg <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..M'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..M'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..M'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..M'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..M'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

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
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..N'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..N'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..N'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..N'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..N'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取不到，本月取
                             OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(s.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                                 OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT= (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '5') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 and a.cancel_flg <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..N'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..N'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..N'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..N'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..N'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '本年不良贷款处置情况,次级-损失 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '10.转为正常后归还  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --   G1101 10.1 转为正常后归还,求和分别插入临时表中
    --====================================================
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_PUB_DATA_G12';
    INSERT INTO CBRC_PUB_DATA_G12
      (BALANCE_UP, --逾期金额_人民币
       ORG_NUM)
      SELECT 
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS OD_LOAN_ACCT_BAL_RMB, A.ORG_NUM
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM C
          ON A.LOAN_NUM = C.LOAN_NUM
         AND SUBSTR(C.DATA_DATE, 1, 6) = SUBSTR(I_DATADATE, 1, 6)
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND B.ACCT_STS <> '3'
         AND B.CANCEL_FLG <> 'Y'
         AND B.LOAN_GRADE_CD IN ('1', '2')
         AND (TO_CHAR(C.REPAY_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) OR
             (A.INTERNET_LOAN_FLG = 'Y' AND
             C.REPAY_DT =
             (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
             OR (A.cp_id IN  ('DK001000100041') AND C.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

             )
         AND C.PAY_TYPE IN ('01', '02', '03')
         AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
         AND A.ACCT_TYP NOT LIKE '90%'
         AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
       GROUP BY A.ORG_NUM;
    COMMIT;
    --==================================
    INSERT INTO CBRC_PUB_DATA_G12
      (BALANCE_DOWN, --贷款余额_人民币
       ORG_NUM)
      SELECT 
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB, A.ORG_NUM
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM C
          ON A.LOAN_NUM = C.LOAN_NUM
         AND SUBSTR(C.DATA_DATE, 1, 6) = SUBSTR(I_DATADATE, 1, 6)
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND B.ACCT_STS = '3'
         AND B.LOAN_ACCT_BAL = 0
         AND (TO_CHAR(C.REPAY_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) OR
             (A.INTERNET_LOAN_FLG = 'Y' AND
             C.REPAY_DT =
             (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
             OR (A.cp_id IN  ('DK001000100041') AND C.REPAY_DT= (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

             )
         AND C.PAY_TYPE IN ('01', '02', '03')
         AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
         AND A.ACCT_TYP NOT LIKE '90%'
       GROUP BY A.ORG_NUM;
    COMMIT;
    --====================================================

    --====================================================
    /*PAY_TYPE:
    1 展期
    11  债务减免
    12  资产剥离
    13  资产转让
    14  信用卡个性化分期
    15  核销
    16  银行主动延期
    17  强制平仓
    18  正常收回
    19  其他
    2 担保人（第三方）代偿
    3 以资抵债
    4 提前还款（包括提前归还部分本金、还款期限不变，以及缩短还款期限两种情况）
    5 提前结清
    8 司法追偿*/
    --====================================================
   

    --====================================================
    --   G1101 10.1 转为正常后归还
    --====================================================
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
             'G12' AS REP_NUM, --报表编号
             'G12_10.1.B' AS ITEM_NUM, --指标号
             SUM(NVL(BALANCE_UP, 0) + NVL(BALANCE_DOWN, 0)) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM CBRC_PUB_DATA_G12
       GROUP BY ORG_NUM;
    COMMIT;

    --====================================================
    --   G1101 10.2  不良贷款处理
    --====================================================
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
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             'G12_10.2.B' AS ITEM_NUM, --指标号
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               SUM((A.LOAN_ACCT_BAL - B.LOAN_ACCT_BAL) * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
               INNER JOIN (SELECT D.LOAN_NUM, MAX(D.PAY_TYPE)
                            FROM SMTMODS_L_TRAN_LOAN_PAYM D
                            LEFT JOIN SMTMODS_L_ACCT_LOAN E
                              ON E.LOAN_NUM = D.LOAN_NUM
                           WHERE D.PAY_TYPE <= '03'
                             AND (TO_CHAR(D.REPAY_DT, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (E.INTERNET_LOAN_FLG = 'Y' AND
                                 D.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                                 OR (E.cp_id IN  ('DK001000100041') AND D.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           GROUP BY D.LOAN_NUM) C
                  ON A.LOAN_NUM = C.LOAN_NUM
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND B.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND B.ACCT_STS != '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM) A
       GROUP BY A.ORG_NUM;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '10.转为正常后归还  逻辑处理 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '以物抵债-12.贷款核销  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G12   以物抵债-12.贷款核销
    --====================================================
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
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM AS ITEM_NUM, --指标号
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN B.PAY_TYPE = '06' THEN
                  'G12_11..B'
                 WHEN B.PAY_TYPE = '08' THEN
                  'G12_12..B'
               END AS ITEM_NUM, --指标号
               SUM(B.PAY_AMT * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM B
                  ON A.LOAN_NUM = B.LOAN_NUM
              --AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND A.ACCT_STS <> '3'
                 AND A.CANCEL_FLG <> 'Y'
                 AND (TO_CHAR(B.REPAY_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) OR
                     (A.INTERNET_LOAN_FLG = 'Y' AND
                     B.REPAY_DT =
                     (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                     OR (A.cp_id IN  ('DK001000100041') AND B.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                     )
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND B.PAY_TYPE IN ('06', '08')
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN B.PAY_TYPE = '06' THEN
                           'G12_11..B'
                          WHEN B.PAY_TYPE = '08' THEN
                           'G12_12..B'
                        END) A
       GROUP BY A.ORG_NUM, ITEM_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '以物抵债-12.贷款核销 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G12_10.2.1.B.2016....';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G12   以物抵债-12.贷款核销
    --====================================================
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
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             'G12_10.2.1.B.2016' AS ITEM_NUM, --指标号
             SUM(ITEM_VAL) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               SUM((A.LOAN_ACCT_BAL - B.LOAN_ACCT_BAL) * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
               INNER JOIN (SELECT D.LOAN_NUM, MAX(D.PAY_TYPE)
                            FROM SMTMODS_L_TRAN_LOAN_PAYM D
                            LEFT JOIN SMTMODS_L_ACCT_LOAN E
                              ON E.LOAN_NUM = D.LOAN_NUM
                           WHERE D.PAY_TYPE <= '03'
                             AND D.BATCH_TRAN_FLG = 'Y'
                             AND (TO_CHAR(D.REPAY_DT, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (E.INTERNET_LOAN_FLG = 'Y' AND
                                 D.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                                 OR (E.cp_id IN  ('DK001000100041') AND  D.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           GROUP BY D.LOAN_NUM) C
                  ON A.LOAN_NUM = C.LOAN_NUM
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND B.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND B.ACCT_STS != '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM) A --是 批量转让
       GROUP BY A.ORG_NUM;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '以物抵债-12.贷款核销 逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G12 本年不良贷款处置情况,以物抵债-其他  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --==================================================================
    --   G12 插入临时表
    --==================================================================
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_PUB_DATA_COLLECT_G12';
    INSERT INTO CBRC_PUB_DATA_COLLECT_G12
      (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
      SELECT 
       A.ORG_NUM AS ORG_NUM,
       CASE
         WHEN B.PAY_TYPE IN ('01', '02', '03') THEN
          (CASE
            WHEN A.LOAN_GRADE_CD = '3' THEN
             1
            WHEN A.LOAN_GRADE_CD = '4' THEN
             2
            WHEN A.LOAN_GRADE_CD = '5' THEN
             3
          END)
         WHEN B.PAY_TYPE = '06' THEN
          (CASE
            WHEN A.LOAN_GRADE_CD = '3' THEN
             4
            WHEN A.LOAN_GRADE_CD = '4' THEN
             5
            WHEN A.LOAN_GRADE_CD = '5' THEN
             6
          END)
         WHEN B.PAY_TYPE = '08' THEN
          (CASE
            WHEN A.LOAN_GRADE_CD = '3' THEN
             7
            WHEN A.LOAN_GRADE_CD = '4' THEN
             8
            WHEN A.LOAN_GRADE_CD = '5' THEN
             9
          END)
         WHEN B.PAY_TYPE NOT IN ('01', '02', '03', '06', '08') THEN
          (CASE
            WHEN A.LOAN_GRADE_CD = '3' THEN
             10
            WHEN A.LOAN_GRADE_CD = '4' THEN
             11
            WHEN A.LOAN_GRADE_CD = '5' THEN
             12
          END)
       END COLLECT_TYPE,
       SUM(B.PAY_AMT * U.CCY_RATE) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND substr(B.DATA_DATE, 1, 6) = substr(I_DATADATE, 1, 6)
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE /*TO_CHAR(REPAY_DT, 'YYYY') < SUBSTR(I_DATADATE, 1, 4)*/
       (TO_CHAR(B.REPAY_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) OR --还款日期取本年 LRT20170811
       (A.INTERNET_LOAN_FLG = 'Y' AND
       B.REPAY_DT = (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
       OR (A.cp_id IN  ('DK001000100041') AND B.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

       )
       AND A.ACCT_TYP NOT LIKE '90%'
       AND A.CANCEL_FLG <> 'Y'
       AND A.DATA_DATE = I_DATADATE
       AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.PAY_TYPE IN ('01', '02', '03') THEN
                   (CASE
                     WHEN A.LOAN_GRADE_CD = '3' THEN
                      1
                     WHEN A.LOAN_GRADE_CD = '4' THEN
                      2
                     WHEN A.LOAN_GRADE_CD = '5' THEN
                      3
                   END)
                  WHEN B.PAY_TYPE = '06' THEN
                   (CASE
                     WHEN A.LOAN_GRADE_CD = '3' THEN
                      4
                     WHEN A.LOAN_GRADE_CD = '4' THEN
                      5
                     WHEN A.LOAN_GRADE_CD = '5' THEN
                      6
                   END)
                  WHEN B.PAY_TYPE = '08' THEN
                   (CASE
                     WHEN A.LOAN_GRADE_CD = '3' THEN
                      7
                     WHEN A.LOAN_GRADE_CD = '4' THEN
                      8
                     WHEN A.LOAN_GRADE_CD = '5' THEN
                      9
                   END)
                  WHEN B.PAY_TYPE NOT IN ('01', '02', '03', '06', '08') THEN
                   (CASE
                     WHEN A.LOAN_GRADE_CD = '3' THEN
                      10
                     WHEN A.LOAN_GRADE_CD = '4' THEN
                      11
                     WHEN A.LOAN_GRADE_CD = '5' THEN
                      12
                   END)
                END;
    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G12
      (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)
      SELECT 
       A.ORG_NUM AS ORG_NUM,
       CASE
         WHEN B.PAY_TYPE IN ('01', '02', '03') THEN
          (CASE
            WHEN A.LOAN_GRADE_CD = '3' THEN
             '13'
            WHEN A.LOAN_GRADE_CD = '4' THEN
             '14'
            WHEN A.LOAN_GRADE_CD = '5' THEN
             '15'
          END)
         WHEN B.PAY_TYPE = '08' THEN
          (CASE
            WHEN A.LOAN_GRADE_CD = '3' THEN
             '16'
            WHEN A.LOAN_GRADE_CD = '4' THEN
             '17'
            WHEN A.LOAN_GRADE_CD = '5' THEN
             '18'
          END)
       END AS COLLECT_TYPE,
       SUM(B.PAY_AMT * U.CCY_RATE) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND substr(B.DATA_DATE, 1, 6) = substr(I_DATADATE, 1, 6)
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE /*TO_CHAR(REPAY_DT, 'YYYY') < SUBSTR(I_DATADATE, 1, 4)*/
       (TO_CHAR(B.REPAY_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) OR --还款日期取本年 LRT20170811
       (A.INTERNET_LOAN_FLG = 'Y' AND
       B.REPAY_DT = (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
       OR (A.cp_id IN  ('DK001000100041') AND B.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

       )
       AND A.ACCT_TYP NOT LIKE '90%'
       AND A.CANCEL_FLG <> 'Y'
       AND A.DATA_DATE = I_DATADATE
       AND B.BATCH_TRAN_FLG = 'Y'
       AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.PAY_TYPE IN ('01', '02', '03') THEN
                   (CASE
                     WHEN A.LOAN_GRADE_CD = '3' THEN
                      '13'
                     WHEN A.LOAN_GRADE_CD = '4' THEN
                      '14'
                     WHEN A.LOAN_GRADE_CD = '5' THEN
                      '15'
                   END)
                  WHEN B.PAY_TYPE = '08' THEN
                   (CASE
                     WHEN A.LOAN_GRADE_CD = '3' THEN
                      '16'
                     WHEN A.LOAN_GRADE_CD = '4' THEN
                      '17'
                     WHEN A.LOAN_GRADE_CD = '5' THEN
                      '18'
                   END)
                END;

    COMMIT;

    INSERT INTO CBRC_PUB_DATA_COLLECT_G12
      (ORG_NUM, COLLECT_TYPE, COLLECT_VAL)

      SELECT 
       A.ORG_NUM AS ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '19'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '20'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '21'
       END COLLECT_TYPE,
       SUM(B.PAY_AMT * U.CCY_RATE) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND substr(B.DATA_DATE, 1, 6) = substr(I_DATADATE, 1, 6)
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE /*TO_CHAR(REPAY_DT, 'YYYY') < SUBSTR(I_DATADATE, 1, 4)*/
       (TO_CHAR(REPAY_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) OR --还款日期取本年 LRT20170811
       (A.INTERNET_LOAN_FLG = 'Y' AND
       B.REPAY_DT = (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
       OR (A.cp_id IN  ('DK001000100041') AND   B.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
       )
       AND A.ACCT_TYP NOT LIKE '90%'
       AND A.CANCEL_FLG <> 'Y'
       AND A.DATA_DATE = I_DATADATE
       AND B.BATCH_TRAN_FLG = 'Y'
       AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.LOAN_GRADE_CD = '3' THEN
                   '19'
                  WHEN A.LOAN_GRADE_CD = '4' THEN
                   '20'
                  WHEN A.LOAN_GRADE_CD = '5' THEN
                   '21'
                END;

    COMMIT;
    --==================================================
    --   G12 本年不良贷款处置情况,以物抵债-其他
    --==================================================
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G12' AS REP_NUM,
             CASE
               WHEN COLLECT_TYPE = '1' THEN
                'G12_10.2.L'
               WHEN COLLECT_TYPE = '2' THEN
                'G12_10.2.M'
               WHEN COLLECT_TYPE = '3' THEN
                'G12_10.2.N'
               WHEN COLLECT_TYPE = '4' THEN
                'G12_11..L'
               WHEN COLLECT_TYPE = '5' THEN
                'G12_11..M'
               WHEN COLLECT_TYPE = '6' THEN
                'G12_11..N'
               WHEN COLLECT_TYPE = '7' THEN
                'G12_12..L'
               WHEN COLLECT_TYPE = '8' THEN
                'G12_12..M'
               WHEN COLLECT_TYPE = '9' THEN
                'G12_12..N'
               WHEN COLLECT_TYPE = '10' THEN
                'G12_13..L'
               WHEN COLLECT_TYPE = '11' THEN
                'G12_13..M'
               WHEN COLLECT_TYPE = '12' THEN
                'G12_13..N'
               WHEN COLLECT_TYPE = '13' THEN
                'G12_10.2.1.L.2016'
               WHEN COLLECT_TYPE = '14' THEN
                'G12_10.2.1.L.M.2016'
               WHEN COLLECT_TYPE = '15' THEN
                'G12_10.2.1.L.N.2016'
               WHEN COLLECT_TYPE = '16' THEN
                'G12_12.1.L.2016'
               WHEN COLLECT_TYPE = '17' THEN
                'G12_12.1.M.2016'
               WHEN COLLECT_TYPE = '18' THEN
                'G12_12.1.N.2016'
               WHEN COLLECT_TYPE = '19' THEN
                'G12_14..L.2016'
               WHEN COLLECT_TYPE = '20' THEN
                'G12_14..M.2016'
               WHEN COLLECT_TYPE = '21' THEN
                'G12_14..N'
             END AS ITEM_NUM,
             SUM(COLLECT_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_PUB_DATA_COLLECT_G12
       WHERE COLLECT_TYPE IS NOT NULL
       GROUP BY ORG_NUM,
                CASE
                  WHEN COLLECT_TYPE = '1' THEN
                   'G12_10.2.L'
                  WHEN COLLECT_TYPE = '2' THEN
                   'G12_10.2.M'
                  WHEN COLLECT_TYPE = '3' THEN
                   'G12_10.2.N'
                  WHEN COLLECT_TYPE = '4' THEN
                   'G12_11..L'
                  WHEN COLLECT_TYPE = '5' THEN
                   'G12_11..M'
                  WHEN COLLECT_TYPE = '6' THEN
                   'G12_11..N'
                  WHEN COLLECT_TYPE = '7' THEN
                   'G12_12..L'
                  WHEN COLLECT_TYPE = '8' THEN
                   'G12_12..M'
                  WHEN COLLECT_TYPE = '9' THEN
                   'G12_12..N'
                  WHEN COLLECT_TYPE = '10' THEN
                   'G12_13..L'
                  WHEN COLLECT_TYPE = '11' THEN
                   'G12_13..M'
                  WHEN COLLECT_TYPE = '12' THEN
                   'G12_13..N'
                  WHEN COLLECT_TYPE = '13' THEN
                   'G12_10.2.1.L.2016'
                  WHEN COLLECT_TYPE = '14' THEN
                   'G12_10.2.1.L.M.2016'
                  WHEN COLLECT_TYPE = '15' THEN
                   'G12_10.2.1.L.N.2016'
                  WHEN COLLECT_TYPE = '16' THEN
                   'G12_12.1.L.2016'
                  WHEN COLLECT_TYPE = '17' THEN
                   'G12_12.1.M.2016'
                  WHEN COLLECT_TYPE = '18' THEN
                   'G12_12.1.N.2016'
                  WHEN COLLECT_TYPE = '19' THEN
                   'G12_14..L.2016'
                  WHEN COLLECT_TYPE = '20' THEN
                   'G12_14..M.2016'
                  WHEN COLLECT_TYPE = '21' THEN
                   'G12_14..N'
                END;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'G12_10.2.1.B.2016....';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G12_12.1.B.2016';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G12   以物抵债-12.贷款核销
    --====================================================
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
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             'G12_12.1.B.2016' AS ITEM_NUM, --指标号
             SUM(ITEM_VAL) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               SUM(B.PAY_AMT * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM B
                  ON A.LOAN_NUM = B.LOAN_NUM
              -- AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND A.ACCT_STS <> '3'
                 AND A.CANCEL_FLG <> 'Y'
                 AND (TO_CHAR(B.REPAY_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) OR
                     (A.INTERNET_LOAN_FLG = 'Y' AND
                     B.REPAY_DT =
                     (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                     OR (A.cp_id IN  ('DK001000100041') AND B.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                     )
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND B.BATCH_TRAN_FLG = 'Y'
                 AND SUBSTR(A.ACCT_TYP, 1, 2) != '90'
                 AND B.PAY_TYPE = '08'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM

              ) A
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'G12_12.1.B.2016';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G12_14..B.2016';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G12   以物抵债-12.贷款核销
    --====================================================
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
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             'G12_14..B.2016' AS ITEM_NUM, --指标号
             SUM(ITEM_VAL) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               SUM(B.PAY_AMT * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM B
                  ON A.LOAN_NUM = B.LOAN_NUM
              --AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND A.ACCT_STS <> '3'
                 AND A.CANCEL_FLG <> 'Y'
                 AND (TO_CHAR(B.REPAY_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) OR
                     (A.INTERNET_LOAN_FLG = 'Y' AND
                     B.REPAY_DT =
                     (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                     OR (A.cp_id IN  ('DK001000100041') AND B.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                     )
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND SUBSTR(A.ACCT_TYP, 1, 2) != '90'
                 AND B.BATCH_TRAN_FLG = 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM

              ) A
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := 'G12_14..B.2016';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --END IF;

    --====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;
    COMMIT;

    

    ------------------------------
    ---- 信用卡部分
    ------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '删除临时表CBRC_G12_XYK_TEMP';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G12_XYK_TEMP';

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '加工信用卡期末余额数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ------------------------------
    ----期末余额
    ----------------------------
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN LXQKQS >= 7 THEN
                'G12_1..G'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G12_1..F'
               WHEN LXQKQS = 4 THEN
                'G12_1..E'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G12_1..D'
               ELSE
                'G12_1..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY CASE
                  WHEN LXQKQS >= 7 THEN
                   'G12_1..G'
                  WHEN LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_1..F'
                  WHEN LXQKQS = 4 THEN
                   'G12_1..E'
                  WHEN LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_1..D'
                  ELSE
                   'G12_1..C'
                END;
    COMMIT;

    ------------------------------
    --年初余额
    ------------------------------
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN LXQKQS >= 7 THEN
                'G12_7..A'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..A'
               WHEN LXQKQS = 4 THEN
                'G12_5..A'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G12_4..A'
               ELSE
                'G12_3..A'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_LAST_YEAR
       GROUP BY CASE
                  WHEN LXQKQS >= 7 THEN
                   'G12_7..A'
                  WHEN LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..A'
                  WHEN LXQKQS = 4 THEN
                   'G12_5..A'
                  WHEN LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_4..A'
                  ELSE
                   'G12_3..A'
                END;
    COMMIT;
    ------------------------------
    ---年初正常类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN T2.LXQKQS >= 7 THEN
                'G12_3..G'
               WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_3..F'
               WHEN T2.LXQKQS = 4 THEN
                'G12_3..E'
               WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_3..D'
               ELSE
                'G12_3..C'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    0
                   ELSE
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP) - T.TRANAMT
                 END)
        FROM ( --年初为正常的贷款，本年还款金额与年初比大小，在根据期末五级分类状态划分五级分类
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
        LEFT JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T2.CARD_NO = T1.CARD_NO
         AND T2.ACCT_NUM = T1.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.LXQKQS <= 0 --年初是正常
       GROUP BY CASE
                  WHEN T2.LXQKQS >= 7 THEN
                   'G12_3..G'
                  WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_3..F'
                  WHEN T2.LXQKQS = 4 THEN
                   'G12_3..E'
                  WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_3..D'
                  ELSE
                   'G12_3..C'
                END;
    COMMIT;

    ------------------------------
    ---年初关注类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN T2.LXQKQS >= 7 THEN
                'G12_4..G'
               WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_4..F'
               WHEN T2.LXQKQS = 4 THEN
                'G12_4..E'
               WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_4..D'
               ELSE
                'G12_4..C'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    0
                   ELSE
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP) - T.TRANAMT
                 END)
        FROM ( --年初为正常的贷款，本年还款金额与年初比大小，在根据期末五级分类状态划分五级分类
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
        LEFT JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T2.CARD_NO = T1.CARD_NO
         AND T2.ACCT_NUM = T1.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.LXQKQS BETWEEN 1 AND 3 --年初是关注
       GROUP BY CASE
                  WHEN T2.LXQKQS >= 7 THEN
                   'G12_4..G'
                  WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_4..F'
                  WHEN T2.LXQKQS = 4 THEN
                   'G12_4..E'
                  WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_4..D'
                  ELSE
                   'G12_4..C'
                END;
    COMMIT;
    ------------------------------
    ---年初次级类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_5..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_5..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_5..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_5..D'
               ELSE
                'G12_5..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)
        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS = 4 --年初是次级
       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_5..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_5..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_5..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_5..D'
                  ELSE
                   'G12_5..C'
                END;
    COMMIT;

    ------------------------------
    --年初可疑类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_6..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_6..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_6..D'
               ELSE
                'G12_6..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)

        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS BETWEEN 5 AND 6 --年初是可疑类贷款
       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_6..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_6..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_6..D'
                  ELSE
                   'G12_6..C'
                END;
    COMMIT;

    ------------------------------
    --年初损失类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_7..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_7..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_7..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_7..D'
               ELSE
                'G12_7..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)

        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS >= 7 --年初是损失类贷款

       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_7..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_7..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_7..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_7..D'
                  ELSE
                   'G12_7..C'
                END;
    COMMIT;

    -------------------
    --本期增加
    --------------------
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
       'G12_2..B' AS ITEM_NUM,
       NVL(SUM(CASE
                 WHEN T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                          T1.M6_UP
                           - NVL(T.TRANAMT, 0) >= 0 THEN
                  0
                 ELSE
                  NVL(T.TRANAMT, 0) - T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 +
                                          T1.M5 + T1.M6 + T1.M6_UP

               END
              ),0) ITEM_VAL
  FROM ( --期初余额-本年还款>0取0，否则  期初余额-本年还款 <0 取期初余额-本年还款 差值
        SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(NVL(TRANAMT, 0)) TRANAMT
          FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
         WHERE T.DATA_DATE BETWEEN SUBSTR('20250131', 1, 4) || '0101' AND
               '20250131'
           AND T.TRANTYPE IN ('11', '12') --交易类型为还款
         GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
 INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
    ON T.CARD_NO = T1.CARD_NO
   AND T.ACCT_NUM = T1.ACCT_NUM
   AND T1.DATA_DATE = I_LAST_YEAR;
    COMMIT;

    --正常
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..C' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..C' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..C',
                          'G12_3..C',
                          'G12_4..C',
                          'G12_5..C',
                          'G12_6..C',
                          'G12_7..C')
       GROUP BY ORG_NUM;
    COMMIT;

    --关注
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..D' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..D' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..D',
                          'G12_3..D',
                          'G12_4..D',
                          'G12_5..D',
                          'G12_6..D',
                          'G12_7..D')
       GROUP BY ORG_NUM;
    COMMIT;

    --次级
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..E' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..E' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..E',
                          'G12_3..E',
                          'G12_4..E',
                          'G12_5..E',
                          'G12_6..E',
                          'G12_7..E')
       GROUP BY ORG_NUM;
    COMMIT;
    --可疑
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..F' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..F' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..F',
                          'G12_3..F',
                          'G12_4..F',
                          'G12_5..F',
                          'G12_6..F',
                          'G12_7..F')
       GROUP BY ORG_NUM;
    COMMIT;

    --损失

    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..G' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..G' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..G',
                          'G12_3..G',
                          'G12_4..G',
                          'G12_5..G',
                          'G12_6..G',
                          'G12_7..G')
       GROUP BY ORG_NUM;
    COMMIT;
    -----------------------
    ---本期减少  正常类  关注类
    -----------------------
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             'G12_3..B' AS ITEM_NUM,
             NVL(SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP)
                   ELSE
                    T.TRANAMT

                 END),0)
        FROM ( --期初余额-本年还款 <= 0 取期初余额，如果 >0 取还款金额
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
         and t1.LXQKQS <= 0 --年初为正常类
      ;
    COMMIT;

    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             'G12_4..B' AS ITEM_NUM,
             NVL(SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP)
                   ELSE
                    T.TRANAMT

                 END),0)
        FROM ( --期初余额-本年还款 <= 0 取期初余额，如果 >0 取还款金额
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
         and t1.LXQKQS BETWEEN 1 AND 3 --年初为关注类
      ;
    COMMIT;

    ------------------------------------
    ---本期减少  次级类  可疑类  损失
    -------------------------------------

    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_5..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_5..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_5..A',
                          'G12_5..C',
                          'G12_5..D',
                          'G12_5..E',
                          'G12_5..F',
                          'G12_5..G')
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_6..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_6..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_6..A',
                          'G12_6..C',
                          'G12_6..D',
                          'G12_6..E',
                          'G12_6..F',
                          'G12_6..G')
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_7..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_7..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_7..A',
                          'G12_7..C',
                          'G12_7..D',
                          'G12_7..E',
                          'G12_7..F',
                          'G12_7..G')
       GROUP BY ORG_NUM;
    COMMIT;

    --------------------------------
    ----10.1 转为正常后归还
    --------------------------------
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             'G12_10.1.A' AS ITEM_NUM,
             SUM(NVL(T.TRANAMT, 0))

        FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS >= 4 --年初为5.次级类贷款、6.可疑类贷款7.损失类贷款，归还时在正常或关注
       WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
             I_DATADATE
         AND T.TRANTYPE IN ('11', '12') --交易类型为还款
         and t.lxqkqs <= 3
       GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD;
    COMMIT;
    ------------------------------
    -- 本年不良贷款处置情况
    -----------------------------

    --本期增加
    --年初为正常或关注,期末时点为不良贷款，归还时在次级、可疑、损失
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT  '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_2..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_2..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_2..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT  T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
         and t1.LXQKQS <= 3 ----年初为正常或关注,期末时点为不良贷款，归还时在次级、可疑、损失
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T.CARD_NO = T2.CARD_NO
         AND T.ACCT_NUM = T2.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
         and t2.LXQKQS >= 4
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_2..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_2..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_2..L'
                END;
    COMMIT;

    --年初正常，归还时在次级、可疑、损失
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_3..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_3..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_3..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS <= 0 --年初正常，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_3..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_3..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_3..L'
                END;
    COMMIT;

    --年初关注，归还时在次级、可疑、损失
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_4..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_4..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_4..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS between 1 and 3 --年初关注，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_4..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_4..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_4..L'
                END;
    COMMIT;

    --年初次级，归还时在次级、可疑、损失
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_5..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_5..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_5..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS = 4 --年初关注，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_5..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_5..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_5..L'
                END;
    COMMIT;

    --年初可疑，归还时在次级、可疑、损失

    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_6..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_6..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS BETWEEN 5 AND 6 --年初可疑，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_6..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_6..L'
                END;
    COMMIT;
    --年初损失，归还时在次级、可疑、损失

    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_7..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_7..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_7..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS >= 7 --年初损失，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_7..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_7..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_7..L'
                END;
    COMMIT;
    -----------------------------
    -----12.贷款核销
    -----------------------------
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             'G12_12..B' AS ITEM_NUM,
             NVL(sum(T.DRAWDOWN_AMT),0)
        FROM SMTMODS_L_ACCT_WRITE_OFF T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.RETRIEVE_FLG <> 'C' -- 完全回收不报
         AND EXISTS (SELECT 1
                FROM SMTMODS_L_ACCT_CARD_CREDIT W
               WHERE W.DATA_DATE = I_DATADATE
                 AND T.ACCT_NUM = W.ACCT_NUM)
         and t.org_num = '009803';
    COMMIT;

    -------------------------------------------
    ----14.不良贷款对外转让总额
    ---------------------------------------
    INSERT INTO CBRC_G12_XYK_TEMP
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             'G12_14..B' AS ITEM_NUM,
             SUM(T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP)
        from SMTMODS_L_ACCT_CARD_CREDIT t
       where t.data_date = I_DATADATE
         and DEALDATE <> '00000000';
    COMMIT;

    --将信用卡数据插入到指标表
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, -- 数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号
             ITEM_VAL, --指标值
             '2' FLAG --标志位
        FROM CBRC_G12_XYK_TEMP;
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
   
END ;
