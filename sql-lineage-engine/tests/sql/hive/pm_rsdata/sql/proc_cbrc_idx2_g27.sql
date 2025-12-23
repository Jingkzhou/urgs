CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g27(II_DATADATE IN STRING --跑批日期
                                               )
/******************************
      @AUTHOR:WANGJB
      @CREATE-DATE:20220209
      @DESCRIPTION:G27
      --    需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-27，修改人：石雨，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
      --[JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
  
  
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_G27_DATA_COLLECT
     CBRC_G27_DATA_COLLECT_TMP
     CBRC_G27_TEMP1_217
依赖表：CBRC_G27_TEMP    --信用卡G27数据文件物理表
视图表：SMTMODS_V_PUB_IDX_CK_GTGSHDQ
     SMTMODS_V_PUB_IDX_CK_GTGSHHQ
     SMTMODS_V_PUB_IDX_CK_GTGSHTZ
集市表：SMTMODS_L_ACCT_DEPOSIT
     SMTMODS_L_ACCT_FUND_MMFUND
     SMTMODS_L_CUST_ALL
     SMTMODS_L_CUST_C
     SMTMODS_L_CUST_P
     SMTMODS_L_FINA_GL
     SMTMODS_L_PUBL_RATE


  *******************************/

 IS
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(50); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR(30);


BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE  := II_DATADATE;
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G27');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME     := 'CBRC_A_REPT_ITEM_VAL';
    D_DATADATE_CCY := I_DATADATE;
    V_STEP_FLAG    := 1;
	V_SYSTEM       := 'CBRC';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || 'G27当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --删除目标表G27数据

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G27'
       AND T.FLAG = '1';

    COMMIT;

    --删除临时表数据

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G27_DATA_COLLECT';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G27_TEMP1_217';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G27_DATA_COLLECT_TMP';
    COMMIT;

    --=====================================================================================================
    -------------------------------------G27个人存款加工开始---------------------------------------------------
    --=====================================================================================================

    V_STEP_ID   := 1;
    V_STEP_DESC := '个人存款本金余额加工开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --1.个人存款 本金余额

    V_STEP_ID   := 2;
    V_STEP_DESC := '个人存款本金余额';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_G27_DATA_COLLECT_TMP 
      (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.CUST_ID,
       CASE
         WHEN T.GL_ITEM_CODE NOT LIKE '20110206%' AND
              T.GL_ITEM_CODE NOT LIKE '20110208%' AND
              T.GL_ITEM_CODE NOT LIKE '2013%' AND
              T.GL_ITEM_CODE NOT LIKE '2014%' AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_1.1.A'
         WHEN T.GL_ITEM_CODE NOT LIKE '20110206%' AND
              T.GL_ITEM_CODE NOT LIKE '20110208%' AND
              T.GL_ITEM_CODE NOT LIKE '2013%' AND
              T.GL_ITEM_CODE NOT LIKE '2014%' AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
          'G27_1.2.A'
         WHEN T.GL_ITEM_CODE NOT LIKE '20110206%' AND
              T.GL_ITEM_CODE NOT LIKE '20110208%' AND
              T.GL_ITEM_CODE NOT LIKE '2013%' AND
              T.GL_ITEM_CODE NOT LIKE '2014%' AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 2000000 THEN
          'G27_1.3.A'
         WHEN P.CUST_ID IS NOT NULL AND (T.GL_ITEM_CODE LIKE '2013%' or
              T.GL_ITEM_CODE LIKE '2014%') AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_1.1.A'
         WHEN P.CUST_ID IS NOT NULL AND ( T.GL_ITEM_CODE LIKE '2013%' or
              T.GL_ITEM_CODE LIKE '2014%' )AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
          'G27_1.2.A'
         WHEN P.CUST_ID IS NOT NULL AND( T.GL_ITEM_CODE LIKE '2013%' or
              T.GL_ITEM_CODE LIKE '2014%' )AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 2000000 THEN
          'G27_1.3.A'
         WHEN C.DEPOSIT_CUSTTYPE IN ('13', '14') AND
              (T.GL_ITEM_CODE LIKE '20110206%' or
              T.GL_ITEM_CODE LIKE '20110208%' )AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_1.1.A'
         WHEN C.DEPOSIT_CUSTTYPE IN ('13', '14') AND
              (T.GL_ITEM_CODE LIKE '20110206%' or
              T.GL_ITEM_CODE LIKE '20110208%' )AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
          'G27_1.2.A'
         WHEN C.DEPOSIT_CUSTTYPE IN ('13', '14') AND
              (T.GL_ITEM_CODE LIKE '20110206%' or
              T.GL_ITEM_CODE LIKE '20110208%') AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 2000000 THEN
          'G27_1.3.A'
       END AS ITEM_NUM,
       SUM(ACCT_BALANCE * TT.CCY_RATE) AS ITEM_VAL,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       T.GL_ITEM_CODE,
       SUM(T.INTEREST_ACCURED * TT.CCY_RATE +
           T.INTEREST_ACCURAL * TT.CCY_RATE)
      --SUM(T.INTEREST_ACCURED + T.INTEREST_ACCURAL)
        FROM SMTMODS_L_ACCT_DEPOSIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON T.DATA_DATE = TT.DATA_DATE
         AND TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND T.DATA_DATE = P.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND T.DATA_DATE = C.DATA_DATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (T.GL_ITEM_CODE LIKE '20110110%' --203 个人通知存款
             OR T.GL_ITEM_CODE IN ('20110101', '20110102') --211 活期储蓄存款
             OR T.GL_ITEM_CODE IN ('20110103',
                                    '20110104',
                                    '20110105',
                                    '20110106',
                                    '20110107',
                                    '20110108',
                                    '20110109') --215 定期储蓄存款
             OR T.GL_ITEM_CODE LIKE '20110112%' --21902 个人结构性存款
             OR T.GL_ITEM_CODE LIKE '20110113%' --22002 发行个人大额存单
             OR T.GL_ITEM_CODE IN ('20110114', '20110115') --25101 个人保证金存款
             OR T.GL_ITEM_CODE LIKE '2013%' --243 应解汇款及临时存款
             OR T.GL_ITEM_CODE LIKE '2014%' --244 开出汇票
             OR T.GL_ITEM_CODE LIKE '20110206%' --218 单位信用卡存款
             OR T.GL_ITEM_CODE LIKE '20110208%' --22001 发行单位大额存单
             OR T.GL_ITEM_CODE ='22410102'  --[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
             )
         /*AND T.ORG_NUM NOT LIKE '51%'*/
         AND T.ACCT_BALANCE > 0
       GROUP BY T.CUST_ID,
                CASE
                  WHEN T.GL_ITEM_CODE NOT LIKE '20110206%' AND
                       T.GL_ITEM_CODE NOT LIKE '20110208%' AND
                       T.GL_ITEM_CODE NOT LIKE '2013%' AND
                       T.GL_ITEM_CODE NOT LIKE '2014%' AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <=
                       500000 THEN
                   'G27_1.1.A'
                  WHEN T.GL_ITEM_CODE NOT LIKE '20110206%' AND
                       T.GL_ITEM_CODE NOT LIKE '20110208%' AND
                       T.GL_ITEM_CODE NOT LIKE '2013%' AND
                       T.GL_ITEM_CODE NOT LIKE '2014%' AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       500000 AND NVL(T.ACCT_BALANCE, 0) +
                       NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
                   'G27_1.2.A'
                  WHEN T.GL_ITEM_CODE NOT LIKE '20110206%' AND
                       T.GL_ITEM_CODE NOT LIKE '20110208%' AND
                       T.GL_ITEM_CODE NOT LIKE '2013%' AND
                       T.GL_ITEM_CODE NOT LIKE '2014%' AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       2000000 THEN
                   'G27_1.3.A'
                  WHEN P.CUST_ID IS NOT NULL AND (T.GL_ITEM_CODE LIKE '2013%' or
                       T.GL_ITEM_CODE LIKE '2014%' )AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <=
                       500000 THEN
                   'G27_1.1.A'
                  WHEN P.CUST_ID IS NOT NULL AND (T.GL_ITEM_CODE LIKE '2013%' or
                       T.GL_ITEM_CODE LIKE '2014%' )AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       500000 AND NVL(T.ACCT_BALANCE, 0) +
                       NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
                   'G27_1.2.A'
                  WHEN P.CUST_ID IS NOT NULL AND (T.GL_ITEM_CODE LIKE '2013%' or
                       T.GL_ITEM_CODE LIKE '2014%') AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       2000000 THEN
                   'G27_1.3.A'
                  WHEN C.DEPOSIT_CUSTTYPE IN ('13', '14') AND
                       (T.GL_ITEM_CODE LIKE '20110206%' or
                       T.GL_ITEM_CODE LIKE '20110208%') AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <=
                       500000 THEN
                   'G27_1.1.A'
                  WHEN C.DEPOSIT_CUSTTYPE IN ('13', '14') AND
                       (T.GL_ITEM_CODE LIKE '20110206%' or
                       T.GL_ITEM_CODE LIKE '20110208%' )AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       500000 AND NVL(T.ACCT_BALANCE, 0) +
                       NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
                   'G27_1.2.A'
                  WHEN C.DEPOSIT_CUSTTYPE IN ('13', '14') AND
                       (T.GL_ITEM_CODE LIKE '20110206%' or
                       T.GL_ITEM_CODE LIKE '20110208%') AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       2000000 THEN
                   'G27_1.3.A'
                END,
                T.GL_ITEM_CODE,
                CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;
    COMMIT;

    --个体工商户活期存款 修改为视图出 20220620 LFZ
    INSERT 
    INTO CBRC_G27_DATA_COLLECT_TMP 
      (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)
      SELECT 
       II_DATADATE AS DATA_DATE,
       T.CUST_ID,
       CASE
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_1.1.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
          'G27_1.2.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 2000000 THEN
          'G27_1.3.A'
       END AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       T.GL_ITEM_CODE,
       SUM(T.INTEREST_ACCURED + T.INTEREST_ACCURAL)
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ T --个体工商户活期存款
       WHERE DATA_DATE = II_DATADATE
         AND CURR_CD = 'CNY'
         /*AND T.ORG_NUM NOT LIKE '51%'*/
         AND T.ACCT_BALANCE_RMB > 0
       GROUP BY T.CUST_ID,
                CASE
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <=
                       500000 THEN
                   'G27_1.1.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       500000 AND NVL(T.ACCT_BALANCE, 0) +
                       NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
                   'G27_1.2.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       2000000 THEN
                   'G27_1.3.A'
                END,
                T.GL_ITEM_CODE,
                CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;

    COMMIT;

    V_STEP_ID   := 3;
    V_STEP_DESC := '个人存款本金余额 个体工商户定期存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --个体工商户定期存款 修改为视图出 20220620 LFZ
    INSERT 
    INTO CBRC_G27_DATA_COLLECT_TMP 
      (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)
      SELECT 
       II_DATADATE AS DATA_DATE,
       T.CUST_ID,
       CASE
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_1.1.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
          'G27_1.2.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 2000000 THEN
          'G27_1.3.A'
       END AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       T.GL_ITEM_CODE,
       SUM(T.INTEREST_ACCURED + T.INTEREST_ACCURAL)
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ T --个体工商户定期存款
       WHERE DATA_DATE = II_DATADATE
         AND CURR_CD = 'CNY'
         /*AND T.ORG_NUM NOT LIKE '51%'*/
         AND T.ACCT_BALANCE_RMB > 0
       GROUP BY T.CUST_ID,
                CASE
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <=
                       500000 THEN
                   'G27_1.1.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       500000 AND NVL(T.ACCT_BALANCE, 0) +
                       NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
                   'G27_1.2.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       2000000 THEN
                   'G27_1.3.A'
                END,
                T.GL_ITEM_CODE,
                CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;

    COMMIT;

    V_STEP_ID   := 4;
    V_STEP_DESC := '个人存款本金余额 个体工商户通知存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --个体工商户通知存款 修改为视图出 20220620 LFZ
    INSERT 
    INTO CBRC_G27_DATA_COLLECT_TMP 
      (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)
      SELECT 
       II_DATADATE AS DATA_DATE,
       T.CUST_ID,
       CASE
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_1.1.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
          'G27_1.2.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 2000000 THEN
          'G27_1.3.A'
       END AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       T.GL_ITEM_CODE,
       SUM(T.INTEREST_ACCURED + T.INTEREST_ACCURAL)
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ T --个体工商户通知存款
       WHERE DATA_DATE = II_DATADATE
         AND CURR_CD = 'CNY'
         /*AND T.ORG_NUM NOT LIKE '51%'*/
         AND T.ACCT_BALANCE_RMB > 0
       GROUP BY T.CUST_ID,
                CASE
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <=
                       500000 THEN
                   'G27_1.1.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       500000 AND NVL(T.ACCT_BALANCE, 0) +
                       NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
                   'G27_1.2.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       2000000 THEN
                   'G27_1.3.A'
                END,
                T.GL_ITEM_CODE,
                CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;

    COMMIT;
    
   ---[JLBA202507210012][石雨][修改内容：修改内容：22410101单位久悬未取款属于活期存款、201103（财政性存款）调整为 一般单位活期存款]
  
 INSERT 
    INTO CBRC_G27_DATA_COLLECT_TMP 
      (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)
      SELECT 
       II_DATADATE AS DATA_DATE,
       T.CUST_ID,
       CASE
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_1.1.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
          'G27_1.2.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 2000000 THEN
          'G27_1.3.A'
       END AS ITEM_NUM,
       SUM(t.ACCT_BALANCE * B.CCY_RATE) AS ITEM_VAL,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       T.GL_ITEM_CODE,
       SUM(nvl(T.INTEREST_ACCURED,0) * B.CCY_RATE+nvl( T.INTEREST_ACCURAL,0)* B.CCY_RATE )
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
      AND T.DATA_DATE = I_DATADATE
    GROUP BY T.CUST_ID, CASE
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_1.1.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 2000000 THEN
          'G27_1.2.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 2000000 THEN
          'G27_1.3.A'
       END,CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END, T.GL_ITEM_CODE;
   commit;
    
    

    V_STEP_ID   := 5;
    V_STEP_DESC := '个人存款本金余额 218 22001 个体工商户';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --ALTER BY WJB 20220630 信用卡溢缴款逻辑修改，不从存款表217科目取数，从信用卡推过来的明细取数
    --信用卡溢缴款第一部分
    INSERT 
    INTO CBRC_G27_TEMP1_217 
      (CUST_ID,
       ORG_NUM,
       DATA_DATE,
       ACCT_BALANCE,
       INTEREST_ACCURAL,
       INTEREST_ACCURED,
       CURR_CD,
       ID_NO)
      SELECT 
       CUST_ID,
       ORG_NUM,
       DATA_DATE,
       ACCT_BALANCE,
       INTEREST_ACCURAL,
       INTEREST_ACCURED,
       CURR_CD,
       ID_NO
        FROM (SELECT
               T.*,
               ROW_NUMBER() OVER(PARTITION BY ID_NO ORDER BY CUST_ID) AS RN
                FROM (SELECT A.CUST_ID,
                             A.ORG_NUM,
                             A.DATA_DATE,
                             A.ACCT_BALANCE,
                             A.INTEREST_ACCURAL,
                             A.INTEREST_ACCURED,
                             A.CURR_CD,
                             C.ID_NO
                        FROM SMTMODS_L_ACCT_DEPOSIT A
                       INNER JOIN SMTMODS_L_CUST_ALL C
                          ON A.CUST_ID = C.CUST_ID
                         AND A.DATA_DATE = C.DATA_DATE
                       WHERE A.DATA_DATE = I_DATADATE
                         /*AND A.ORG_NUM NOT LIKE '51%'*/) T) CC
       WHERE CC.RN = 1;
    COMMIT;

    INSERT 
    INTO CBRC_G27_DATA_COLLECT_TMP 
      (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.CUST_ID,
       CASE
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) +
              NVL(T.BALANCE, 0) <= 500000 THEN
          'G27_1.1.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) +
              NVL(T.BALANCE, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) +
              NVL(T.BALANCE, 0) <= 2000000 THEN
          'G27_1.2.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) +
              NVL(T.BALANCE, 0) > 2000000 THEN
          'G27_1.3.A'
       END AS ITEM_NUM,
       --SUM(T.BALANCE * TT.CCY_RATE) AS ITEM_VAL,
       SUM(T.BALANCE) AS ITEM_VAL,  --溢缴款不折币
       '990000' AS ORG_NUM,
       '217',
     --  SUM(T.INTEREST_ACCURED * TT.CCY_RATE +
     --      T.INTEREST_ACCURAL * TT.CCY_RATE) AS LX
      0 AS LX  --modi by djh 信用卡溢缴款不计算利息，此处设置0
        FROM (SELECT 
               AA.CUST_ID,
               AA.ORG_NUM,
               AA.DATA_DATE,
               AA.ACCT_BALANCE,
               AA.INTEREST_ACCURAL,
               AA.INTEREST_ACCURED,
               AA.CURR_CD,
               AA.ID_NO,
               TMP.BALANCE
                FROM CBRC_G27_TEMP1_217 AA
               INNER JOIN CBRC_G27_TEMP TMP
                  ON TMP.ID_NO = AA.ID_NO) T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON T.DATA_DATE = TT.DATA_DATE
         AND TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY T.CUST_ID,
                CASE
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) +
                       NVL(T.BALANCE, 0) <= 500000 THEN
                   'G27_1.1.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) +
                       NVL(T.BALANCE, 0) > 500000 AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) +
                       NVL(T.BALANCE, 0) <= 2000000 THEN
                   'G27_1.2.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) +
                       NVL(T.BALANCE, 0) > 2000000 THEN
                   'G27_1.3.A'
                END;

    COMMIT;

    V_STEP_ID   := 6;
    V_STEP_DESC := '个人存款本金余额 217 信用卡溢缴款第二部分';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --信用卡溢缴款第二部分

    INSERT 
    INTO CBRC_G27_DATA_COLLECT_TMP 
      (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ID_NO,
       CASE
         WHEN NVL(T.BALANCE, 0) <= 500000 THEN
          'G27_1.1.A'
         WHEN NVL(T.BALANCE, 0) > 500000 AND NVL(T.BALANCE, 0) <= 2000000 THEN
          'G27_1.2.A'
         WHEN NVL(T.BALANCE, 0) > 2000000 THEN
          'G27_1.3.A'
       END AS ITEM_NUM,
       SUM(BALANCE) AS ITEM_VAL,
       '990000' AS ORG_NUM,
       '217'
        FROM (SELECT 
               *
                FROM CBRC_G27_TEMP
               WHERE ID_NO NOT IN (SELECT 
                                    TMP.ID_NO
                                     FROM CBRC_G27_TEMP1_217 AA
                                    INNER JOIN CBRC_G27_TEMP TMP
                                       ON TMP.ID_NO = AA.ID_NO)) T
       GROUP BY T.ID_NO,CASE
                  WHEN NVL(T.BALANCE, 0) <= 500000 THEN
                   'G27_1.1.A'
                  WHEN NVL(T.BALANCE, 0) > 500000 AND
                       NVL(T.BALANCE, 0) <= 2000000 THEN
                   'G27_1.2.A'
                  WHEN NVL(T.BALANCE, 0) > 2000000 THEN
                   'G27_1.3.A'
                END;

    COMMIT;


--插入 CBRC_G27_DATA_COLLECT
INSERT INTO CBRC_G27_DATA_COLLECT 
  (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)
  SELECT 
   DATA_DATE,
   CUST_ID,
   CASE
     WHEN NVL(ACCT_BALANCE, 0) + NVL(LX, 0) <= 500000 THEN
      'G27_1.1.A'
     WHEN NVL(ACCT_BALANCE, 0) + NVL(LX, 0) > 500000 AND
          NVL(ACCT_BALANCE, 0) + NVL(LX, 0) <= 2000000 THEN --alter by 20231116
      'G27_1.2.A'
     WHEN NVL(ACCT_BALANCE, 0) + NVL(LX, 0) > 2000000 THEN --alter by 20231116
      'G27_1.3.A'
   END,
   ACCT_BALANCE,
   ORG_NUM,
   '',
   LX
    FROM (SELECT 
           DATA_DATE,
           CUST_ID,
           SUM(ACCT_BALANCE) AS ACCT_BALANCE,
           ORG_NUM,
           SUM(LX) AS LX
            FROM CBRC_G27_DATA_COLLECT_TMP
           WHERE DATA_DATE = I_DATADATE
            AND ITEM_NUM LIKE 'G27_1%'
           GROUP BY DATA_DATE, CUST_ID, ORG_NUM) T;

COMMIT;


    V_STEP_ID   := 7;
    V_STEP_DESC := '个人存款本金余额加工结束';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 8;
    V_STEP_DESC := '个人存款户数加工开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --2.个人存款 户数

    INSERT 
    INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G27' AS REP_NUM,
       CASE
         WHEN T.ITEM_NUM = 'G27_1.1.A' THEN
          'G27_1.1.B'
         WHEN T.ITEM_NUM = 'G27_1.2.A' THEN
          'G27_1.2.B'
         WHEN T.ITEM_NUM = 'G27_1.3.A' THEN
          'G27_1.3.B'
       END AS ITEM_NUM,
       COUNT(DISTINCT CUST_ID) AS ITEM_VAL,
       '1' AS FLAG
        FROM CBRC_G27_DATA_COLLECT T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
         AND T.ITEM_NUM IN ('G27_1.1.A', 'G27_1.2.A', 'G27_1.3.A')
         AND T.ACCT_BALANCE > 0
       GROUP BY CASE
                  WHEN T.ITEM_NUM = 'G27_1.1.A' THEN
                   'G27_1.1.B'
                  WHEN T.ITEM_NUM = 'G27_1.2.A' THEN
                   'G27_1.2.B'
                  WHEN T.ITEM_NUM = 'G27_1.3.A' THEN
                   'G27_1.3.B'
                END,
                CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;

    COMMIT;

    V_STEP_ID   := 9;
    V_STEP_DESC := '个人存款户数加工结束';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 10;
    V_STEP_DESC := '个人存款利息金额加工开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --3.个人存款 利息金额

    INSERT 
    INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G27' AS REP_NUM,
       CASE
         WHEN T.ITEM_NUM = 'G27_1.1.A' THEN
          'G27_1.1.C'
         WHEN T.ITEM_NUM = 'G27_1.2.A' THEN
          'G27_1.2.C'
         WHEN T.ITEM_NUM = 'G27_1.3.A' THEN
          'G27_1.3.C'
       END AS ITEM_NUM,
       SUM(LX) AS ITEM_VAL,
       '1' AS FLAG
        FROM CBRC_G27_DATA_COLLECT T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
         AND T.ITEM_NUM IN ('G27_1.1.A', 'G27_1.2.A', 'G27_1.3.A')
         AND T.ACCT_BALANCE > 0
       GROUP BY CASE
                  WHEN T.ITEM_NUM = 'G27_1.1.A' THEN
                   'G27_1.1.C'
                  WHEN T.ITEM_NUM = 'G27_1.2.A' THEN
                   'G27_1.2.C'
                  WHEN T.ITEM_NUM = 'G27_1.3.A' THEN
                   'G27_1.3.C'
                END,
                CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;

    COMMIT;

    V_STEP_ID   := 11;
    V_STEP_DESC := '个人存款利息金额加工结束';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 12;
    V_STEP_DESC := '单位存款本金余额加工开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --1.单位存款 本金余额

    INSERT 
    INTO CBRC_G27_DATA_COLLECT_TMP 
      (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)

      SELECT 
       I_DATADATE AS DATA_DATE,
       T.CUST_ID,
       CASE
         WHEN T.GL_ITEM_CODE NOT LIKE '2013%' AND
              T.GL_ITEM_CODE NOT LIKE '2014%' AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_2.1.A'
         WHEN T.GL_ITEM_CODE NOT LIKE '2013%' AND
              T.GL_ITEM_CODE NOT LIKE '2014%' AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN --alter by 20231116
          'G27_2.2.A'
         WHEN T.GL_ITEM_CODE NOT LIKE '2013%' AND
              T.GL_ITEM_CODE NOT LIKE '2014%' AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 10000000 THEN  --alter by 20231116
          'G27_2.3.A'
         WHEN (C.CUST_ID IS NOT NULL AND (T.GL_ITEM_CODE LIKE '2013%' OR
              T.GL_ITEM_CODE LIKE '2014%')) AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_2.1.A'
         WHEN (C.CUST_ID IS NOT NULL AND( T.GL_ITEM_CODE LIKE '2013%' OR
              T.GL_ITEM_CODE LIKE '2014%')) AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN  --alter by 20231116
          'G27_2.2.A'
         WHEN (C.CUST_ID IS NOT NULL AND( T.GL_ITEM_CODE LIKE '2013%' OR
              T.GL_ITEM_CODE LIKE '2014%')) AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 10000000 THEN  --alter by 20231116
          'G27_2.3.A'
         WHEN (C.DEPOSIT_CUSTTYPE IN ('13', '14') AND
              (T.GL_ITEM_CODE LIKE '20110206%' OR
              T.GL_ITEM_CODE LIKE '20110208%')) AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_2.1.A'
         WHEN (C.DEPOSIT_CUSTTYPE IN ('13', '14') AND
              (T.GL_ITEM_CODE LIKE '20110206%' OR
              T.GL_ITEM_CODE LIKE '20110208%')) AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN --alter by 20231116
          'G27_2.2.A'
         WHEN (C.DEPOSIT_CUSTTYPE IN ('13', '14') AND
              (T.GL_ITEM_CODE LIKE '20110206%' OR
              T.GL_ITEM_CODE LIKE '20110208%')) AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 10000000 THEN  --alter by 20231116
          'G27_2.3.A'
       END AS ITEM_NUM,
       SUM(CASE
             WHEN (T.GL_ITEM_CODE LIKE '20110206%' OR
                  T.GL_ITEM_CODE LIKE '20110208%') AND
                  C.DEPOSIT_CUSTTYPE  IN ('13', '14') THEN
               0
             ELSE
              ACCT_BALANCE * TT.CCY_RATE
           END) AS ITEM_VAL,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       T.GL_ITEM_CODE,
       SUM(T.INTEREST_ACCURED * TT.CCY_RATE +
           T.INTEREST_ACCURAL * TT.CCY_RATE)
      --SUM(T.INTEREST_ACCURED + T.INTEREST_ACCURAL) AS LX
        FROM SMTMODS_L_ACCT_DEPOSIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON T.DATA_DATE = TT.DATA_DATE
         AND TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND T.DATA_DATE = C.DATA_DATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (T.GL_ITEM_CODE LIKE '20110201%' --201 单位活期存款
             OR T.GL_ITEM_CODE LIKE '20110205%' --202 单位通知存款
             OR T.GL_ITEM_CODE IN
             ('20110202', '20110203', '20110204', '20110211') --205 单位定期存款
             OR T.GL_ITEM_CODE LIKE '20110701%' --206 国库定期存款
             --    需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：石雨，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
             OR T.GL_ITEM_CODE LIKE '2010%' 
             OR T.GL_ITEM_CODE LIKE '20110206%' --218 单位信用卡存款
             OR T.GL_ITEM_CODE LIKE '20110207%' --21901 单位结构性存款
             OR T.GL_ITEM_CODE LIKE '21903%' --21903 其他结构性存款
             OR T.GL_ITEM_CODE LIKE '20110208%' --22001 发行单位大额存单
             OR T.GL_ITEM_CODE IN ('20110209', '20110210') --25102 单位保证金存款
             OR T.GL_ITEM_CODE LIKE '2013%' --243 应解汇款及临时存款
             OR T.GL_ITEM_CODE LIKE '2014%' --244 开出汇票
             OR T.GL_ITEM_CODE IN ('22410101','20110301','20110302','20110303','20080101','20090101' ) --[JLBA202507210012][石雨][修改内容：修改内容：22410101单位久悬未取款属于活期存款、201103（财政性存款）调整为 一般单位活期存款]
             )
         /*AND T.ORG_NUM NOT LIKE '51%'*/
      --AND T.ACCT_BALANCE > 0
       GROUP BY T.CUST_ID,
                CASE
                  WHEN T.GL_ITEM_CODE NOT LIKE '2013%' AND
                       T.GL_ITEM_CODE NOT LIKE '2014%' AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <=
                       500000 THEN
                   'G27_2.1.A'
                  WHEN T.GL_ITEM_CODE NOT LIKE '2013%' AND
                       T.GL_ITEM_CODE NOT LIKE '2014%' AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       500000 AND NVL(T.ACCT_BALANCE, 0) +
                       NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN ----alter by 20231116
                   'G27_2.2.A'
                  WHEN T.GL_ITEM_CODE NOT LIKE '2013%' AND
                       T.GL_ITEM_CODE NOT LIKE '2014%' AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       10000000 THEN  --alter by 20231116
                   'G27_2.3.A'
                  WHEN (C.CUST_ID IS NOT NULL AND
                       (T.GL_ITEM_CODE LIKE '2013%' OR
                       T.GL_ITEM_CODE LIKE '2014%')) AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <=
                       500000 THEN
                   'G27_2.1.A'
                  WHEN (C.CUST_ID IS NOT NULL AND
                       (T.GL_ITEM_CODE LIKE '2013%' OR
                       T.GL_ITEM_CODE LIKE '2014%')) AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       500000 AND NVL(T.ACCT_BALANCE, 0) +
                       NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN  --alter by 20231116
                   'G27_2.2.A'
                  WHEN (C.CUST_ID IS NOT NULL AND
                       (T.GL_ITEM_CODE LIKE '2013%' OR
                       T.GL_ITEM_CODE LIKE '2014%')) AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       10000000 THEN  --alter by 20231116
                   'G27_2.3.A'
                  WHEN (C.DEPOSIT_CUSTTYPE IN ('13', '14') AND
                       (T.GL_ITEM_CODE LIKE '20110206%' OR
                       T.GL_ITEM_CODE LIKE '20110208%')) AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <=
                       500000 THEN
                   'G27_2.1.A'
                  WHEN (C.DEPOSIT_CUSTTYPE IN ('13', '14') AND
                       (T.GL_ITEM_CODE LIKE '20110206%' OR
                       T.GL_ITEM_CODE LIKE '20110208%')) AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       500000 AND NVL(T.ACCT_BALANCE, 0) +
                       NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN  --alter by 20231116
                   'G27_2.2.A'
                  WHEN (C.DEPOSIT_CUSTTYPE IN ('13', '14') AND
                       (T.GL_ITEM_CODE LIKE '20110206%' OR
                       T.GL_ITEM_CODE LIKE '20110208%')) AND
                       NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       10000000 THEN  --alter by 20231116
                   'G27_2.3.A'
                END,
                T.GL_ITEM_CODE,
                CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;

    COMMIT;

    --234010204 保险业金融机构存放款项 2340204 保险业金融机构存放款项
    INSERT 
    INTO CBRC_G27_DATA_COLLECT_TMP 
      (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.CUST_ID,
       CASE
         WHEN T.ACCT_BALANCE <= 500000 THEN
          'G27_2.1.A'
         WHEN T.ACCT_BALANCE > 500000 AND T.ACCT_BALANCE <= 10000000 THEN --alter by 20231116
          'G27_2.2.A'
         WHEN T.ACCT_BALANCE > 10000000 THEN  -----alter by 20231116
          'G27_2.3.A'
       END AS ITEM_NUM,
       SUM(T.ACCT_BALANCE * TT.CCY_RATE) AS ITEM_VAL,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       T.GL_ITEM_CODE,
       SUM(T.INTEREST_ACCURED * TT.CCY_RATE +
           T.INTEREST_ACCURAL * TT.CCY_RATE) AS LX
      --SUM(T.INTEREST_ACCURED + T.INTEREST_ACCURAL) AS LX
      --FROM SMTMODS_L_ACCT_FUND_MMFUND T --资金往来信息表
        FROM SMTMODS_L_ACCT_DEPOSIT T --存款表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON T.DATA_DATE = TT.DATA_DATE
         AND TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND (T.GL_ITEM_CODE LIKE '20120106%' OR
             T.GL_ITEM_CODE LIKE '20120204%') --保险业金融机构存放款项 --保险业金融机构存放款项
         /*AND T.ORG_NUM NOT LIKE '51%'*/
         AND T.ACCT_BALANCE > 0
       GROUP BY T.CUST_ID,
                CASE
                  WHEN T.ACCT_BALANCE <= 500000 THEN
                   'G27_2.1.A'
                  WHEN T.ACCT_BALANCE > 500000 AND T.ACCT_BALANCE <= 10000000 THEN ----alter by 20231116
                   'G27_2.2.A'
                  WHEN T.ACCT_BALANCE > 10000000 THEN --alter by 20231116
                   'G27_2.3.A'
                END,
                T.GL_ITEM_CODE,
                CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;

    COMMIT;

    V_STEP_ID   := 13;
    V_STEP_DESC := '单位存款本金余额 个体工商户活期存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --个体工商户活期存款 修改为视图出 20220620 LFZ
    INSERT 
    INTO CBRC_G27_DATA_COLLECT_TMP 
      (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)
      SELECT 
       II_DATADATE AS DATA_DATE,
       T.CUST_ID,
       CASE
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_2.1.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN --alter by 20231116
          'G27_2.2.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 10000000 THEN  --alter by 20231116
          'G27_2.3.A'
       END AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       T.GL_ITEM_CODE,
       SUM(T.INTEREST_ACCURED + T.INTEREST_ACCURAL) * -1
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ T --个体工商户活期存款
       WHERE DATA_DATE = II_DATADATE
         AND CURR_CD = 'CNY'
         /*AND T.ORG_NUM NOT LIKE '51%'*/
         AND T.ACCT_BALANCE > 0
       GROUP BY T.CUST_ID,
                CASE
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <=
                       500000 THEN
                   'G27_2.1.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       500000 AND NVL(T.ACCT_BALANCE, 0) +
                       NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN --alter by 20231116
                   'G27_2.2.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       10000000 THEN  --alter by 20231116
                   'G27_2.3.A'
                END,
                T.GL_ITEM_CODE,
                CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;

    COMMIT;

    V_STEP_ID   := 14;
    V_STEP_DESC := '单位存款本金余额 个体工商户定期存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --个体工商户定期存款 修改为视图出 20220620 LFZ
    INSERT 
    INTO CBRC_G27_DATA_COLLECT_TMP 
      (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)
      SELECT 
       II_DATADATE AS DATA_DATE,
       T.CUST_ID,
       CASE
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_2.1.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN --alter by 20231116
          'G27_2.2.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 10000000 THEN --alter by 20231116
          'G27_2.3.A'
       END AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       T.GL_ITEM_CODE,
       SUM(T.INTEREST_ACCURED + T.INTEREST_ACCURAL) * -1
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ T --个体工商户定期存款
       WHERE DATA_DATE = II_DATADATE
         AND CURR_CD = 'CNY'
         /*AND T.ORG_NUM NOT LIKE '51%'*/
         AND T.ACCT_BALANCE > 0
       GROUP BY T.CUST_ID,
                CASE
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <=
                       500000 THEN
                   'G27_2.1.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       500000 AND NVL(T.ACCT_BALANCE, 0) +
                       NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN --alter by 20231116
                   'G27_2.2.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       10000000 THEN
                   'G27_2.3.A'
                END,
                T.GL_ITEM_CODE,
                CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;

    COMMIT;

    V_STEP_ID   := 15;
    V_STEP_DESC := '单位存款本金余额 个体工商户通知存款';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --个体工商户通知存款 修改为视图出 20220620 LFZ
    INSERT 
    INTO CBRC_G27_DATA_COLLECT_TMP 
      (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)
      SELECT 
       II_DATADATE AS DATA_DATE,
       T.CUST_ID,
       CASE
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_2.1.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN--alter by 20231116
          'G27_2.2.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 10000000 THEN --alter by 20231116
          'G27_2.3.A'
       END AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       T.GL_ITEM_CODE,
       SUM(T.INTEREST_ACCURED + T.INTEREST_ACCURAL) * -1
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ T --个体工商户通知存款
       WHERE DATA_DATE = II_DATADATE
         AND CURR_CD = 'CNY'
        /* AND T.ORG_NUM NOT LIKE '51%'*/
         AND T.ACCT_BALANCE > 0
       GROUP BY T.CUST_ID,
                CASE
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <=
                       500000 THEN
                   'G27_2.1.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       500000 AND NVL(T.ACCT_BALANCE, 0) +
                       NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN --alter by 20231116
                   'G27_2.2.A'
                  WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) >
                       10000000 THEN  --alter by 20231116
                   'G27_2.3.A'
                END,
                T.GL_ITEM_CODE,
                CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;
    COMMIT;

---[JLBA202507210012][石雨][修改内容：修改内容：22410101单位久悬未取款属于活期存款、201103（财政性存款）调整为 一般单位活期存款]
  
 INSERT 
    INTO CBRC_G27_DATA_COLLECT_TMP 
      (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)
      SELECT 
       II_DATADATE AS DATA_DATE,
       T.CUST_ID,
       CASE
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_2.1.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN--alter by 20231116
          'G27_2.2.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 10000000 THEN --alter by 20231116
          'G27_2.3.A'
       END AS ITEM_NUM,
       SUM(t.ACCT_BALANCE * B.CCY_RATE) * -1 AS ITEM_VAL,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       T.GL_ITEM_CODE,
       SUM(nvl(T.INTEREST_ACCURED,0) * B.CCY_RATE+nvl( T.INTEREST_ACCURAL,0)* B.CCY_RATE ) *-1
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
      AND T.DATA_DATE = I_DATADATE
    GROUP BY T.CUST_ID, CASE
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 500000 THEN
          'G27_2.1.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 500000 AND
              NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) <= 10000000 THEN--alter by 20231116
          'G27_2.2.A'
         WHEN NVL(T.ACCT_BALANCE, 0) + NVL(T.INTEREST_ACCURAL, 0) > 10000000 THEN --alter by 20231116
          'G27_2.3.A'
       END,CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END, T.GL_ITEM_CODE;
   commit;





INSERT INTO CBRC_G27_DATA_COLLECT 
  (DATA_DATE, CUST_ID, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD, LX)
  SELECT 
   DATA_DATE,
   CUST_ID,
   CASE
     WHEN NVL(ACCT_BALANCE, 0) + NVL(LX, 0) <= 500000 THEN
      'G27_2.1.A'
     WHEN NVL(ACCT_BALANCE, 0) + NVL(LX, 0) > 500000 AND
          NVL(ACCT_BALANCE, 0) + NVL(LX, 0) <= 10000000 THEN --alter by 20231116
      'G27_2.2.A'
     WHEN NVL(ACCT_BALANCE, 0) + NVL(LX, 0) > 10000000 THEN --alter by 20231116
      'G27_2.3.A'
   END,
   ACCT_BALANCE,
   ORG_NUM,
   '',
   LX
    FROM (SELECT 
           DATA_DATE,
           CUST_ID,
           SUM(ACCT_BALANCE) AS ACCT_BALANCE,
           ORG_NUM,
           SUM(LX) AS LX
            FROM CBRC_G27_DATA_COLLECT_TMP
           WHERE DATA_DATE = I_DATADATE
             AND ITEM_NUM LIKE 'G27_2%'
           GROUP BY DATA_DATE, CUST_ID, ORG_NUM) T;

COMMIT;

    V_STEP_ID   := 16;
    V_STEP_DESC := '单位存款本金余额加工结束';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 17;
    V_STEP_DESC := '单位存款户数加工开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --2.单位存款 户数

    INSERT 
    INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G27' AS REP_NUM,
       CASE
         WHEN T.ITEM_NUM = 'G27_2.1.A' THEN
          'G27_2.1.B'
         WHEN T.ITEM_NUM = 'G27_2.2.A' THEN
          'G27_2.2.B'
         WHEN T.ITEM_NUM = 'G27_2.3.A' THEN
          'G27_2.3.B'
       END AS ITEM_NUM,
       COUNT(DISTINCT CUST_ID) AS ITEM_VAL,
       '1' AS FLAG
        FROM CBRC_G27_DATA_COLLECT T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
         AND T.ITEM_NUM IN ('G27_2.1.A', 'G27_2.2.A', 'G27_2.3.A')
         AND T.ACCT_BALANCE > 0
       GROUP BY CASE
                  WHEN T.ITEM_NUM = 'G27_2.1.A' THEN
                   'G27_2.1.B'
                  WHEN T.ITEM_NUM = 'G27_2.2.A' THEN
                   'G27_2.2.B'
                  WHEN T.ITEM_NUM = 'G27_2.3.A' THEN
                   'G27_2.3.B'
                END,
                CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;

    COMMIT;

    V_STEP_ID   := 18;
    V_STEP_DESC := '单位存款户数加工结束';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 19;
    V_STEP_DESC := '单位存款利息金额加工开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --3.单位存款 利息金额

    INSERT 
    INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G27' AS REP_NUM,
       CASE
         WHEN T.ITEM_NUM = 'G27_2.1.A' THEN
          'G27_2.1.C'
         WHEN T.ITEM_NUM = 'G27_2.2.A' THEN
          'G27_2.2.C'
         WHEN T.ITEM_NUM = 'G27_2.3.A' THEN
          'G27_2.3.C'
       END AS ITEM_NUM,
       SUM(LX) AS ITEM_VAL,
       '1' AS FLAG
        FROM CBRC_G27_DATA_COLLECT T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
         AND T.ITEM_NUM IN ('G27_2.1.A', 'G27_2.2.A', 'G27_2.3.A')
      --AND T.ACCT_BALANCE > 0
       GROUP BY CASE
                  WHEN T.ITEM_NUM = 'G27_2.1.A' THEN
                   'G27_2.1.C'
                  WHEN T.ITEM_NUM = 'G27_2.2.A' THEN
                   'G27_2.2.C'
                  WHEN T.ITEM_NUM = 'G27_2.3.A' THEN
                   'G27_2.3.C'
                END,
                CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;

    COMMIT;

    V_STEP_ID   := 20;
    V_STEP_DESC := '单位存款利息金额加工结束';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 21;
    V_STEP_DESC := '特殊处理逻辑加工开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --特殊处理：由于存款明细表和总账表存在总分不平的情况，和大为哥确认后决定通过轧差的方式处理总分不平的科目
    --21510 总账里有此科目、明细里没有
    --21510 本金金额

    INSERT INTO CBRC_G27_DATA_COLLECT 
      (DATA_DATE, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD)
      SELECT I_DATADATE AS DATA_DATE,
             'G27_1.1.A' AS ITEM_NUM,
             SUM(ZZ) - SUM(明细) AS ACCT_BALANCE,
             CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
             '20110109' AS ITEM_CD
        FROM ( --明细
              SELECT 0 AS ZZ,
                      A.ORG_NUM,
                      GL_ITEM_CODE,
                      SUM(A.ACCT_BALANCE * B.CCY_RATE) AS 明细
                FROM SMTMODS_L_ACCT_DEPOSIT A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 /*AND A.ORG_NUM NOT LIKE '51%'*/
                 AND A.GL_ITEM_CODE IN ('20110103',
                                        '20110104',
                                        '20110105',
                                        '20110106',
                                        '20110107',
                                        '20110108',
                                        '20110109')
               GROUP BY A.ORG_NUM,A.GL_ITEM_CODE
              UNION ALL
              --总账
              SELECT SUM(A.CREDIT_BAL * B.CCY_RATE) AS ZZ,A.ORG_NUM, ITEM_CD, 0 AS 明细
                FROM SMTMODS_L_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ITEM_CD IN ('20110103',
                                   '20110104',
                                   '20110105',
                                   '20110106',
                                   '20110107',
                                   '20110108',
                                   '20110109')
                 AND A.ORG_NUM IN( '990000','510000','520000','530000','540000','550000','560000','570000','580000','590000','600000')
               GROUP BY A.ORG_NUM,A.ITEM_CD) T
               GROUP BY CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END;
    COMMIT;

    --201科目

    INSERT INTO CBRC_G27_DATA_COLLECT 
      (DATA_DATE, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD)
      SELECT I_DATADATE AS DATA_DATE,
             'G27_2.1.A' AS ITEM_NUM,
             SUM(ZZ) - SUM(明细) AS ACCT_BALANCE,
             CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
             '20110201' AS ITEM_CD
        FROM ( --明细
              SELECT 0 AS ZZ,
                      A.ORG_NUM,
                      GL_ITEM_CODE,
                      SUM(A.ACCT_BALANCE * B.CCY_RATE) AS 明细
                FROM SMTMODS_L_ACCT_DEPOSIT A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND (A.GL_ITEM_CODE LIKE '20110201%'
                  OR A.GL_ITEM_CODE IN ('22410101','20110301','20110302','20110303','20080101','20090101' ) )--[JLBA202507210012][石雨][修改内容：修改内容：22410101单位久悬未取款属于活期存款、201103（财政性存款）调整为 一般单位活期存款]
             
                 /*AND A.ORG_NUM NOT LIKE '51%'*/
               GROUP BY A.ORG_NUM,A.GL_ITEM_CODE
              UNION ALL
              --总账
              SELECT SUM(A.CREDIT_BAL * B.CCY_RATE) AS ZZ,A.ORG_NUM, ITEM_CD, 0 AS 明细
                FROM SMTMODS_L_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND (A.ITEM_CD = '20110201'
                 OR A.ITEM_CD IN ('22410101','20110301','20110302','20110303','20080101','20090101' ) )--[JLBA202507210012][石雨][修改内容：修改内容：22410101单位久悬未取款属于活期存款、201103（财政性存款）调整为 一般单位活期存款]
             
                 AND A.ORG_NUM IN( '990000','510000','520000','530000','540000','550000','560000','570000','580000','590000','600000')
               GROUP BY A.ORG_NUM,A.ITEM_CD)T
               GROUP BY CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END
               ;
    COMMIT;

    --21101科目

    INSERT INTO CBRC_G27_DATA_COLLECT 
      (DATA_DATE, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD)
      SELECT I_DATADATE AS DATA_DATE,
             'G27_1.1.A' AS ITEM_NUM,
             SUM(ZZ) - SUM(明细) AS ACCT_BALANCE,
             CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
             '20110101' AS ITEM_CD
        FROM ( --明细
              SELECT 0 AS ZZ,
                      A.ORG_NUM,
                      GL_ITEM_CODE,
                      SUM(A.ACCT_BALANCE * B.CCY_RATE) AS 明细
                FROM SMTMODS_L_ACCT_DEPOSIT A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND (A.GL_ITEM_CODE LIKE '20110101%'
                    or A.GL_ITEM_CODE LIKE '22410102' )--[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
                 /*AND A.ORG_NUM NOT LIKE '51%'*/
               GROUP BY A.ORG_NUM, A.GL_ITEM_CODE
              UNION ALL
              --总账
              SELECT SUM(A.CREDIT_BAL * B.CCY_RATE) AS ZZ,A.ORG_NUM, ITEM_CD, 0 AS 明细
                FROM SMTMODS_L_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND (A.ITEM_CD = '20110101'
                  or A.ITEM_CD LIKE '22410102' )--[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
                 AND A.ORG_NUM IN( '990000','510000','520000','530000','540000','550000','560000','570000','580000','590000','600000')
               GROUP BY A.ORG_NUM,A.ITEM_CD)T
               GROUP BY CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END
               ;
    COMMIT;

    --2510201

    INSERT INTO CBRC_G27_DATA_COLLECT 
      (DATA_DATE, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD)
      SELECT I_DATADATE AS DATA_DATE,
             'G27_2.1.A' AS ITEM_NUM,
             SUM(ZZ) - SUM(明细) AS ACCT_BALANCE,
             CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
             '20110209' AS ITEM_CD
        FROM ( --明细
              SELECT 0 AS ZZ,
                      A.ORG_NUM,
                      GL_ITEM_CODE,
                      SUM(A.ACCT_BALANCE * B.CCY_RATE) AS 明细
                FROM SMTMODS_L_ACCT_DEPOSIT A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.GL_ITEM_CODE LIKE '20110209%'
                 /*AND A.ORG_NUM NOT LIKE '51%'*/
               GROUP BY A.ORG_NUM,A.GL_ITEM_CODE
              UNION ALL
              --总账
              SELECT SUM(A.CREDIT_BAL * B.CCY_RATE) AS ZZ,A.ORG_NUM, ITEM_CD, 0 AS 明细
                FROM SMTMODS_L_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ITEM_CD = '20110209'
                 AND A.ORG_NUM IN( '990000','510000','520000','530000','540000','550000','560000','570000','580000','590000','600000')
               GROUP BY A.ORG_NUM,A.ITEM_CD)T
               GROUP BY CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END
               ;

    COMMIT;

    --234010204

    INSERT INTO CBRC_G27_DATA_COLLECT 
      (DATA_DATE, ITEM_NUM, ACCT_BALANCE, ORG_NUM, ITEM_CD)
      SELECT I_DATADATE AS DATA_DATE,
             'G27_2.1.A' AS ITEM_NUM,
             SUM(ZZ) - SUM(明细) AS ACCT_BALANCE,
             CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
             '20120106' AS ITEM_CD
        FROM ( --明细
              SELECT 0 AS ZZ,
                      T.ORG_NUM,
                      GL_ITEM_CODE,
                      SUM(T.BALANCE * TT.CCY_RATE) AS 明细
                FROM SMTMODS_L_ACCT_FUND_MMFUND T --资金往来信息表
                LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
                  ON TT.CCY_DATE = D_DATADATE_CCY
                 AND TT.BASIC_CCY = T.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.GL_ITEM_CODE LIKE '20120106%' --保险业金融机构存放款项
                 /*AND T.ORG_NUM NOT LIKE '51%'*/
               GROUP BY T.ORG_NUM,T.GL_ITEM_CODE
              UNION ALL
              --总账
              SELECT SUM(A.CREDIT_BAL * B.CCY_RATE) AS ZZ,A.ORG_NUM, ITEM_CD, 0 AS 明细
                FROM SMTMODS_L_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ITEM_CD = '20120106'
                 AND A.ORG_NUM IN( '990000','510000','520000','530000','540000','550000','560000','570000','580000','590000','600000')
               GROUP BY A.ORG_NUM,A.ITEM_CD)T
               GROUP BY CASE WHEN  T.ORG_NUM     LIKE '51%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '52%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '53%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '54%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '55%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '56%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '57%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '58%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '59%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '60%' THEN '600000'
           ELSE '990000'
             END
               ;
    COMMIT;

    --=====================================================================================================
    -------------------------------------G27指标插入CBRC_A_REPT_ITEM_VAL目标表------------------------------
    --=====================================================================================================

    V_STEP_ID   := 22;
    V_STEP_DESC := '产生G27指标数据，插至 CBRC_A_REPT_ITEM_VAL 目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G27' AS REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(ACCT_BALANCE) AS ITEM_VAL,
       '1' AS FLAG
        FROM CBRC_G27_DATA_COLLECT T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,T.ITEM_NUM;

    COMMIT;

    V_STEP_FLAG := 23;
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
   
END proc_cbrc_idx2_g27