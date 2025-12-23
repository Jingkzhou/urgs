CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g17(II_DATADATE  IN STRING --跑批日期
                                                 )
/******************************
  @author:作者
  @create-date:日期
  @description:描述 贷记卡
  @modification history:
  m0.author-create_date-description
  m1.贷记卡数据来自银联数据，现建临时表G17_DJK存放银联数据
  M2.新建一个临时表 CBRC_L_TRAN_ACCT_INNER_TX_TMP 统计4.本年累计收入202201-04月数据，统计年累计数
  M3. 20230410 shiyu 新建临时表 CBRC_L_TRAN_CARD_TX_TEMP 本年累计卡交易
  M4. 20230410 shiyu 新建临时表 CBRC_L_TRAN_TX_TEMP 统计本年累计第三方交易
  M5. 20231011.ZJM.对涉及累放的指标进行开发，将村镇铺底数据逻辑放进去
  
目標表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_G17_AMT_TMP2_CZ  --村镇累放铺底数据
     CBRC_G17_DATA_COLLECT_TMP
     CBRC_G17_DJK           --贷记卡数据来自银联数据 落地表
     CBRC_L_TRAN_ACCT_INNER_TX_TMP
     CBRC_L_TRAN_CARD_TX_TEMP
     CBRC_L_TRAN_TX_TEMP
视图表：SMTMODS_V_PUB_IDX_FINA_GL
     SMTMODS_L_ACCT_CARD_ACCT_RELATION
     SMTMODS_L_ACCT_CARD_CREDIT
     SMTMODS_L_ACCT_CARD_DEBIT
     SMTMODS_L_ACCT_DEPOSIT
     SMTMODS_L_ACCT_INNER
     SMTMODS_L_AGRE_CARD_CREDIT
     SMTMODS_L_AGRE_CARD_INFO
     SMTMODS_L_CUST_ALL
     SMTMODS_L_FINA_GL
     SMTMODS_L_PUBL_EQUIPMENT
     SMTMODS_L_PUBL_MERCHANT
     SMTMODS_L_PUBL_ORG_BRA
     SMTMODS_L_PUBL_RATE
     SMTMODS_L_TRAN_ACCT_INNER_TX
     SMTMODS_L_TRAN_CARD_TX
     SMTMODS_L_TRAN_TX


  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE1    VARCHAR(10); --数据日期(字符型)MM/DD/YYYY
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_DATE_Q_END   VARCHAR(10); --季度末时间*/
  V_DATE_Q_START VARCHAR(10); --季度初时间
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
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G17');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME     := 'CBRC_A_REPT_ITEM_VAL';
    V_DATADATE1    := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'MM/DD/YYYY');
    V_DATE_Q_START := to_char(trunc(DATE(I_DATADATE, 'YYYYMMDD'), 'Q'),
                              'YYYYMMDD');

    V_DATE_Q_END   := to_char(ADD_MONTHS(TRUNC(DATE(I_DATADATE,
                                                       'YYYYMMDD'),
                                               'Q'),
                                         3) - 1,
                              'YYYYMMDD');
    D_DATADATE_CCY := I_DATADATE;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']G17当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G17_DATA_COLLECT_TMP';
    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G17'
       AND T.FLAG = '2';
    COMMIT;

    /*================================================1.1总卡量（张）借记卡================================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.1总卡量（张）借记卡=至G17_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_G17_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT I_DATADATE AS DATA_DATE,
       CASE
         WHEN A.ORG_NUM LIKE '51%' THEN
          '510000'
         WHEN A.ORG_NUM LIKE '52%' THEN
          '520000'
         WHEN A.ORG_NUM LIKE '53%' THEN
          '530000'
         WHEN A.ORG_NUM LIKE '54%' THEN
          '540000'
         WHEN A.ORG_NUM LIKE '55%' THEN
          '550000'
         WHEN A.ORG_NUM LIKE '56%' THEN
          '560000'
         WHEN A.ORG_NUM LIKE '57%' THEN
          '570000'
         WHEN A.ORG_NUM LIKE '58%' THEN
          '580000'
         WHEN A.ORG_NUM LIKE '59%' THEN
          '590000'
         WHEN A.ORG_NUM LIKE '60%' THEN
          '600000'
         ELSE
          '009803'
       END,
       'G17_1.1.A' AS ITEM_NUM,
       COUNT(DISTINCT A.CARD_NO)
  FROM SMTMODS_L_AGRE_CARD_INFO A --卡基本信息表
 WHERE A.DATA_DATE = I_DATADATE
   AND A.CARDKIND = '1' --1:借记卡
   AND A.CARDSTAT NOT IN ('V', 'Z')
 GROUP BY CASE
            WHEN A.ORG_NUM LIKE '51%' THEN
             '510000'
            WHEN A.ORG_NUM LIKE '52%' THEN
             '520000'
            WHEN A.ORG_NUM LIKE '53%' THEN
             '530000'
            WHEN A.ORG_NUM LIKE '54%' THEN
             '540000'
            WHEN A.ORG_NUM LIKE '55%' THEN
             '550000'
            WHEN A.ORG_NUM LIKE '56%' THEN
             '560000'
            WHEN A.ORG_NUM LIKE '57%' THEN
             '570000'
            WHEN A.ORG_NUM LIKE '58%' THEN
             '580000'
            WHEN A.ORG_NUM LIKE '59%' THEN
             '590000'
            WHEN A.ORG_NUM LIKE '60%' THEN
             '600000'
            ELSE
             '009803'
          END; --V:过期,Z:注销

COMMIT;

/*=============================================1.1总卡量（张）准贷记卡================================================================*/
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据1.1总卡量（张）准贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_1.1.B' AS ITEM_NUM,
         COUNT(DISTINCT A.CARD_NO)
    FROM SMTMODS_L_AGRE_CARD_INFO A --卡基本信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3' --3:准贷记卡
     AND A.CARDSTAT NOT IN ('V', 'Z'); --V:过期,Z:注销
commit;

/*=============================================1.1 其中： 总卡量（张）贷记卡=========================================================    */
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取1.1 数据总卡量（张）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_1.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(A.C_ITEM_VAL)
    FROM CBRC_G17_DJK A
   WHERE A.DATA_DATE = I_DATADATE
     AND TRIM(A.PROJECT_DESC) LIKE '%1.1总卡量（张）%';
COMMIT;

/*================================================= 1.1.1其中： 睡眠卡（张）贷记卡=========================================================    */
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取 1.1.1其中： 睡眠卡（张）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

--睡眠卡

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_1.1.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL)
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%1.1.1其中： 睡眠卡（张）%'; -- B:睡眠

COMMIT;

---------------------------------------------------      1.1.1其中： 睡眠卡（张）准贷记卡---------------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '1.1.1其中： 睡眠卡（张）准贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_1.1.1.B' AS ITEM_NUM,
         COUNT(DISTINCT A.CARD_NO)
    FROM SMTMODS_L_AGRE_CARD_INFO A --卡基本信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3' --3:准贷记卡
     AND A.CARDSTAT NOT IN ('V', 'Z') --V:过期,Z:注销
     AND A.CARD_ACT = 'B'; --B:睡眠

commit;

---------------------------------------------------      1.1.1其中： 睡眠卡（张）借记卡---------------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '1.1.1其中： 睡眠卡（张）借记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
         'G17_1.1.1.A' AS ITEM_NUM,
         COUNT(DISTINCT A.CARD_NO) --1.1.1其中： 睡眠卡（张）
    FROM SMTMODS_L_AGRE_CARD_INFO A --卡基本信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '1' --1:借记卡
     AND A.CARDSTAT NOT IN ('V', 'Z') --V:过期,Z:注销
     AND A.CARD_ACT = 'B'
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END; --B:睡眠

COMMIT;

---------------------------------------------------------      1.1.2其中： 长期睡眠卡（张）----------
--新增指标
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '1.1.2其中： 长期睡眠卡（张）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_1.1.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL)
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%1.1.2其中： 长期睡眠卡（张）%';
COMMIT;

--------------------------------------------------------------1.2总户数（户）借记卡 ----------------------------------------------------------------

V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据1.2总户数（户）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT 
   I_DATADATE AS DATA_DATE,
   CASE
     WHEN A.ORG_NUM LIKE '51%' THEN
      '510000'
     WHEN A.ORG_NUM LIKE '52%' THEN
      '520000'
     WHEN A.ORG_NUM LIKE '53%' THEN
      '530000'
     WHEN A.ORG_NUM LIKE '54%' THEN
      '540000'
     WHEN A.ORG_NUM LIKE '55%' THEN
      '550000'
     WHEN A.ORG_NUM LIKE '56%' THEN
      '560000'
     WHEN A.ORG_NUM LIKE '57%' THEN
      '570000'
     WHEN A.ORG_NUM LIKE '58%' THEN
      '580000'
     WHEN A.ORG_NUM LIKE '59%' THEN
      '590000'
     WHEN A.ORG_NUM LIKE '60%' THEN
      '600000'
     ELSE
      '009803'
   END,
   'G17_1.2.A' AS ITEM_NUM,
   COUNT(DISTINCT B.ID_NO)
    FROM SMTMODS_L_AGRE_CARD_INFO A --卡基本信息表
    LEFT JOIN SMTMODS_L_CUST_ALL B --全量客户信息表
      ON A.CUST_ID = B.CUST_ID
     and b.data_date = I_DATADATE
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '1' --1:借记卡
     AND A.CARDSTAT NOT IN ('V', 'Z') --V:过期,Z:注销
     AND A.MAIN_ADDITIONAL_FLG = 'A'
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END; --A:主卡

commit;

---------------------------------------------------------1.2  总户数（户）  准贷记卡---------------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '1.2  总户数（户）  准贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT 
   I_DATADATE AS DATA_DATE, '009803', 'G17_1.2.B', COUNT(DISTINCT B.ID_NO)
    FROM SMTMODS_L_AGRE_CARD_INFO A --卡基本信息表
    LEFT JOIN SMTMODS_L_CUST_ALL B --全量客户信息表
      ON A.CUST_ID = B.CUST_ID
     and b.data_date = I_DATADATE
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3' --3:准贷记卡
     AND A.CARDSTAT NOT IN ('V', 'Z') --V:过期,Z:注销
     AND A.MAIN_ADDITIONAL_FLG = 'A'; --A:主卡
COMMIT;

---------------------------------------------------------1.2  总户数（户）  贷记卡---------------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '1.2  总户数（户）  贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_1.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL)
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%1.2总户数（户）%';
COMMIT;

------------------------------------------------          1.2.1其中：睡眠户（户）借记卡--------------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '1.2.1其中：睡眠户（户）借记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT 
   I_DATADATE AS DATA_DATE,
   CASE
     WHEN A.ORG_NUM LIKE '51%' THEN
      '510000'
     WHEN A.ORG_NUM LIKE '52%' THEN
      '520000'
     WHEN A.ORG_NUM LIKE '53%' THEN
      '530000'
     WHEN A.ORG_NUM LIKE '54%' THEN
      '540000'
     WHEN A.ORG_NUM LIKE '55%' THEN
      '550000'
     WHEN A.ORG_NUM LIKE '56%' THEN
      '560000'
     WHEN A.ORG_NUM LIKE '57%' THEN
      '570000'
     WHEN A.ORG_NUM LIKE '58%' THEN
      '580000'
     WHEN A.ORG_NUM LIKE '59%' THEN
      '590000'
     WHEN A.ORG_NUM LIKE '60%' THEN
      '600000'
     ELSE
      '009803'
   END,
   'G17_1.2.1.A' AS ITEM_NUM,
   COUNT(DISTINCT B.ID_NO)
    FROM SMTMODS_L_AGRE_CARD_INFO A --卡基本信息表
    LEFT JOIN SMTMODS_L_CUST_ALL B --全量客户信息表
      ON A.CUST_ID = B.CUST_ID
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '1' --1:借记卡
     AND A.CARDSTAT NOT IN ('V', 'Z') --V:过期,Z:注销
     AND A.CARD_ACT = 'B' --B:睡眠
     AND A.MAIN_ADDITIONAL_FLG = 'A'
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END; --A:主卡

commit;

------------------------------------------------          1.2.1其中：睡眠户（户）准贷记卡--------------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '1.2.1其中：睡眠户（户）准贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT 
   I_DATADATE AS DATA_DATE,
   '009803',
   'G17_1.2.1.B' AS ITEM_NUM,
   COUNT(DISTINCT B.ID_NO)
    FROM SMTMODS_L_AGRE_CARD_INFO A --卡基本信息表
    LEFT JOIN SMTMODS_L_CUST_ALL B --全量客户信息表
      ON A.CUST_ID = B.CUST_ID
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3' --3:准贷记卡
     AND A.CARDSTAT NOT IN ('V', 'Z') --V:过期,Z:注销
     AND A.CARD_ACT = 'B' --B:睡眠
     AND A.MAIN_ADDITIONAL_FLG = 'A'; --A:主卡
commit;

------------------------------------------------          1.2.1其中：睡眠户（户）贷记卡--------------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '1.2.1其中：睡眠户（户）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_1.2.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL)
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%1.2.1其中：睡眠户（户）%';
COMMIT;

---------------------------------------------------------------1.2.2其中：长期睡眠户（户）--------------------------
--新增指标
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '1.2.2其中：长期睡眠户（户）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_1.2.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL)
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%1.2.2其中：长期睡眠户（户）%';
COMMIT;

/*=============================================================== 2.交易指标=======================================================*/
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '加工交易年累计数据相关至L_TRAN_CARD_TX_TEMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_L_TRAN_CARD_TX_TEMP';

COMMIT;

INSERT INTO CBRC_L_TRAN_CARD_TX_TEMP
  (DATA_DATE,
   CARD_NO,
   ISSUE_NUMBER,
   ACCT_NUM,
   TX_DT,
   ORG_NUM,
   REF_NUM,
   CURR_CD,
   TRANAMT,
   CARDKIND,
   CD_TYPE,
   TRANTYPE,
   CANCELTRANS_FLG,
   TRANS_FLG)
  SELECT 
   I_DATADATE,
   CARD_NO,
   ISSUE_NUMBER,
   ACCT_NUM,
   TX_DT,
   ORG_NUM,
   REF_NUM,
   CURR_CD,
   TRANAMT,
   CARDKIND,
   CD_TYPE,
   TRANTYPE,
   CANCELTRANS_FLG,
   TRANS_FLG
    FROM SMTMODS_L_TRAN_CARD_TX
   where DATA_DATE between SUBSTR(I_DATADATE, 1, 4) || '0101' and
         I_DATADATE
     AND CARDKIND in ('1', '3'); --1借记卡--3:准贷记卡

COMMIT;

V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据 2.交易指标（万元）-借记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

--------------------------------------------------------------2.1本期消费金额（万元）借记卡----------------------------------------------

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
         'G17_2.1.A' AS ITEM_NUM,
         SUM(A.TRANAMT)
    FROM CBRC_L_TRAN_CARD_TX_TEMP A --卡交易信息表
   WHERE A.TRANTYPE = '01' --01:消费
     AND A.CARDKIND = '1' --1:借记卡
  --AND A.TX_DT IN (TRUNC(TO_DATE(I_DATADATE, 'YYYY')));
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;

commit;

--------------------------------------------------------------2.1本期消费金额（万元）准贷记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.1本期消费金额（万元）准贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_2.1.B' AS ITEM_NUM,
         SUM(A.TRANAMT)
    FROM CBRC_L_TRAN_CARD_TX_TEMP A --卡交易信息表
   WHERE A.TRANTYPE = '01' --01:消费
     AND A.CARDKIND = '3' --3:准贷记卡
  --AND A.TX_DT IN (TRUNC(I_DATADATE));
  ;
commit;

------------------------------------------------2.1本期消费金额（万元）贷记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.1本年累计消费金额（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.1本年累计消费金额（万元）%';
commit;

-- ------------------------------------------------------------    2.2本期取现金额（万元）借记卡--------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.2本期取现金额（万元）借记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
         'G17_2.2.A' AS ITEM_NUM,
         SUM(A.TRANAMT)
    FROM CBRC_L_TRAN_CARD_TX_TEMP A --卡交易信息表
   WHERE A.TRANTYPE = '02' --02:取现
     AND A.CARDKIND = '1' --1:借记卡
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;

commit;

-- ------------------------------------------------------------    2.2本期取现金额（万元）准贷记卡--------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.2本期取现金额（万元）准贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)


  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_2.2.B' AS ITEM_NUM,
         SUM(A.TRANAMT)
    FROM CBRC_L_TRAN_CARD_TX_TEMP A --卡交易信息表
   WHERE A.TRANTYPE = '02' --02:取现
     AND A.CARDKIND = '3' --1:借记卡
  ;
commit;

-----------------------------------------------2.2本期取现金额（万元）贷记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.2本年累计取现金额（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.2本年累计取现金额（万元）%';
commit;

--  ----------------------------------------------------   2.3本期转账金额（万元）借记卡---------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.3本期转账金额（万元）借记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
         'G17_2.3.A' AS ITEM_NUM,
         SUM(A.TRANAMT)
    FROM CBRC_L_TRAN_CARD_TX_TEMP A --卡交易信息表
   WHERE A.TRANTYPE = '03' --03:转账（转出）
     AND A.CARDKIND = '1' --1:借记卡
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;
commit;

--  ----------------------------------------------------   2.3本期转账金额（万元）准贷记卡---------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.3本期转账金额（万元）准贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_2.3.B' AS ITEM_NUM,
         SUM(A.TRANAMT)
    FROM CBRC_L_TRAN_CARD_TX_TEMP A --卡交易信息表
   WHERE A.TRANTYPE = '03' --03:转账（转出）
     AND A.CARDKIND = '3' --3:准贷记卡
  --AND A.TX_DT IN (TRUNC(I_DATADATE));
  ;
commit;

-----------------------------------------2.3本期转账金额（万元）贷记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.3本年累计转账金额（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.3.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.3本年累计转账金额（万元）%';
commit;

------------------------------------------------2.4本年累计还款金额（万元）贷记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.4本年累计还款金额（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.4.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.4本年累计还款金额（万元）%';
commit;

----------------------------------------通过第三方支付机构交易------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '加工交易年累计数据相关至 CBRC_L_TRAN_TX_TEMP 中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_L_TRAN_TX_TEMP';

COMMIT;

INSERT INTO CBRC_L_TRAN_TX_TEMP
  (DATA_DATE,
   TX_DT,
   ORG_NUM,
   REFERENCE_NUM,
   CUST_ID,
   ACCOUNT_CODE,
   TRAN_CODE,
   TRAN_CODE_DESCRIBE,
   TRANS_INCOME_TYPE,
   CD_TYPE,
   TRANS_AMT,
   CURRENCY,
   OPPO_ORG_NUM,
   OPPO_ORG_NAM,
   OPPO_ACCT_NUM,
   OPPO_ACCT_NAM,
   GL_ITEM_CODE,
   TRAN_STS,
   TRANS_FLG,
   KEY_TRANS_NO,
   SUB_TRANS_NO,
   SERIAL_NO,
   TRANS_CHANNEL,
   O_ACCT_NUM,
   CARD_NO)
  SELECT I_DATADATE,
         TX_DT,
         ORG_NUM,
         REFERENCE_NUM,
         CUST_ID,
         ACCOUNT_CODE,
         TRAN_CODE,
         TRAN_CODE_DESCRIBE,
         TRANS_INCOME_TYPE,
         CD_TYPE,
         TRANS_AMT,
         CURRENCY,
         OPPO_ORG_NUM,
         OPPO_ORG_NAM,
         OPPO_ACCT_NUM,
         OPPO_ACCT_NAM,
         GL_ITEM_CODE,
         TRAN_STS,
         TRANS_FLG,
         KEY_TRANS_NO,
         SUB_TRANS_NO,
         SERIAL_NO,
         TRANS_CHANNEL,
         O_ACCT_NUM,
         CARD_NO
    FROM SMTMODS_L_TRAN_TX
   WHERE DATA_DATE between
         to_char(TRUNC(I_DATADATE, 'Q'), 'yyyymmdd') and
         I_DATADATE
     AND TRANS_CHANNEL = 'WLPJ' /*网联*/
     AND TRAN_STS = 'A' /*交易状态：正常*/
  ;
COMMIT;

------------------------------------2.5.1.1通过第三方支付机构交易金额-转出（万元） 借记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.5.1.1通过第三方支付机构交易金额-转出（万元） 借记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         CASE
              WHEN ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END,
         'G17_2.5.1.1.A.2022' AS ITEM_NUM,
         SUM(TRANS_AMT)
    FROM CBRC_L_TRAN_TX_TEMP --SMTMODS_L_TRAN_TX
   WHERE OPPO_ORG_NUM IN ('Z2007933000010', 'Z2004944000010')
     AND TRANS_INCOME_TYPE = '1' /*资金收付标志：收*/
   GROUP BY CASE
              WHEN ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;
commit;

------------------------------------2.5.1.1通过第三方支付机构交易金额-转出（万元） 贷记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.5.1.1通过第三方支付机构交易金额-转出（万元） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.5.1.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.5.1.1通过第三方支付机构交易金额-转出（万元）%';
commit;

------------------------------------2.5.1.2通过第三方支付机构交易金额-转入（万元） 借记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.5.1.2通过第三方支付机构交易金额-转入（万元） 借记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
         'G17_2.5.1.2.A.2022' AS ITEM_NUM,
         SUM(TRANS_AMT)
    FROM CBRC_L_TRAN_TX_TEMP A --SMTMODS_L_TRAN_TX
   WHERE
  -- AND TRANS_CHANNEL = 'WLPJ' /*网联*/
  -- AND TRAN_STS = 'A' /*交易状态：正常*/
  --AND TRA_MED_NAME='11'   /*交易介质名称 ：借记卡*/
  --OPPO_ORG_NUM IN ('Z2007933000010', 'Z2004944000010')
    TRANS_INCOME_TYPE = '2' /*资金收付标志：付*/
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;
commit;

------------------------------------2.5.1.2通过第三方支付机构交易金额-转入（万元）贷记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.5.1.2通过第三方支付机构交易金额-转入（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.5.1.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.5.1.2通过第三方支付机构交易金额-转入（万元）%';
commit;

------------------------------------2.5.2.1通过第三方支付机构交易笔数-转出（笔数） 借记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.5.2.1通过第三方支付机构交易笔数-转出（笔数） 借记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
          'G17_2.5.2.1.A.2022' AS ITEM_NUM,
         COUNT(1)
    FROM CBRC_L_TRAN_TX_TEMP A --SMTMODS_L_TRAN_TX
   WHERE
  --AND TRANS_CHANNEL = 'WLPJ' /*网联*/
  --AND TRAN_STS = 'A' /*交易状态：正常*/
  --AND TRA_MED_NAME='11'   /*交易介质名称 ：借记卡*/
   OPPO_ORG_NUM IN ('Z2007933000010', 'Z2004944000010')
   AND TRANS_INCOME_TYPE = '1' /*资金收付标志：收*/
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;
COMMIT;

------------------------------------2.5.2.1通过第三方支付机构交易笔数-转出（笔数） 贷记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.5.2.1通过第三方支付机构交易笔数-转出（笔数） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.5.2.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.5.2.1通过第三方支付机构交易笔数-转出（笔数）%';
commit;

------------------------------------2.5.2.2通过第三方支付机构交易笔数-转入（笔数） 借记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.5.2.2通过第三方支付机构交易笔数-转入（笔数） 借记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
          'G17_2.5.2.2.A.2022' AS ITEM_NUM,
         COUNT(1)
    FROM CBRC_L_TRAN_TX_TEMP A --SMTMODS_L_TRAN_TX
   WHERE OPPO_ORG_NUM IN ('Z2007933000010', 'Z2004944000010')
     AND TRANS_INCOME_TYPE = '2' /*资金收付标志：付*/
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;
commit;

------------------------------------2.5.2.2通过第三方支付机构交易笔数-转入（笔数） 贷记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.5.2.2通过第三方支付机构交易笔数-转入（笔数） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.5.2.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.5.2.2通过第三方支付机构交易笔数-转入（笔数）%';
commit;

------------------------------------2.5.3通过第三方支付机构交易的卡量（张） 借记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.5.3通过第三方支付机构交易的卡量（张） 借记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         -- '009803',
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
         'G17_2.5.3.A.2022' AS ITEM_NUM,
         COUNT(distinct ACCOUNT_CODE)
    FROM CBRC_L_TRAN_TX_TEMP A --SMTMODS_L_TRAN_TX
   WHERE OPPO_ORG_NUM IN ('Z2007933000010', 'Z2004944000010')
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;

commit;

------------------------------------2.5.3通过第三方支付机构交易的卡量（张） 贷记卡----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '2.5.3通过第三方支付机构交易的卡量（张） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.5.3.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.5.3通过第三方支付机构交易的卡量（张）%';
commit;

/*===================================================================3.资金状况=========================================================    */
---------------------------------------------------------------3.1存款余额（万元）借记卡-----------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据3.1存款余额（万元）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT 
   I_DATADATE AS DATA_DATE,
   CASE
     WHEN A.ORG_NUM LIKE '51%' THEN
      '510000'
     WHEN A.ORG_NUM LIKE '52%' THEN
      '520000'
     WHEN A.ORG_NUM LIKE '53%' THEN
      '530000'
     WHEN A.ORG_NUM LIKE '54%' THEN
      '540000'
     WHEN A.ORG_NUM LIKE '55%' THEN
      '550000'
     WHEN A.ORG_NUM LIKE '56%' THEN
      '560000'
     WHEN A.ORG_NUM LIKE '57%' THEN
      '570000'
     WHEN A.ORG_NUM LIKE '58%' THEN
      '580000'
     WHEN A.ORG_NUM LIKE '59%' THEN
      '590000'
     WHEN A.ORG_NUM LIKE '60%' THEN
      '600000'
     ELSE
      '009803'
   END,
   'G17_3.1.A' AS ITEM_NUM,
   SUM(A.ACCT_BALANCE* U.CCY_RATE)
    FROM SMTMODS_L_ACCT_DEPOSIT A
    LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.DATA_DATE = I_DATADATE
                 AND A.CURR_CD = U.BASIC_CCY
                 AND U.FORWARD_CCY = 'CNY'
   WHERE A.DATA_DATE = I_DATADATE
     AND EXISTS (SELECT 1 FROM
      SMTMODS_L_ACCT_CARD_ACCT_RELATION B
      WHERE B.DATA_DATE = I_DATADATE
      AND A.ACCT_NUM = B.ACCT_NUM
      AND B.DATE_SOURCESD = '借记卡' )
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END; --1:借记卡,4:借贷合一卡
commit;

---------------------------------------------------------------3.1存款余额（万元）准贷记卡-----------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据3.1存款余额（万元）准贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT 
   I_DATADATE AS DATA_DATE,
   '009803',
   'G17_3.1.B' AS ITEM_NUM,
   SUM(B.AVAILBAL)
    FROM SMTMODS_L_ACCT_CARD_ACCT_RELATION C --卡基本信息和卡账户信息对应关系表
    LEFT JOIN SMTMODS_L_AGRE_CARD_INFO A --卡基本信息表
      ON A.CARD_NO = C.CARD_NO
     AND A.ISSUE_NUMBER = C.ISSUE_NUMBER
     AND A.DATA_DATE = I_DATADATE
    LEFT JOIN SMTMODS_L_ACCT_CARD_DEBIT B --信用卡账户信息表
      ON B.ACCT_NUM = C.ACCT_NUM
     AND B.DATA_DATE = I_DATADATE
   WHERE C.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3'; --3:准贷记卡
commit;

---------------------------------------------------------------3.1存款余额（万元）贷记卡-----------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据3.1存款余额（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.1存款余额（万元）%';
COMMIT;

--------------------------------------------------------------------------3.2授信额度（万元）准贷记卡--------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据3.2授信额度（万元）准贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_3.2.B' AS ITEM_NUM,
         SUM(A.SHARE_QUANTUM)
    FROM SMTMODS_L_AGRE_CARD_CREDIT A --信用卡补充信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3'; --3:准贷记卡

COMMIT;

--------------------------------------------------------------------------3.2授信额度（万元）贷记卡--------------------------------------------

V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据3.2授信额度（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.2授信额度（万元）%';
COMMIT;

---------------------------------------------------------------------3.3应收账款余额-按是否为预借现金业务划分（万元））-----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据3.3应收账款余额-按是否为预借现金业务划分（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.3.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.3应收账款余额-按是否为预借现金业务划分（万元）%';
COMMIT;

--------------------------------------------------------------------- 3.3.1其中：生息的应收账款余额（万元）-----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.3.1其中：生息的应收账款余额（万元）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.3.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.3.1其中：刷卡消费形成的应收账款余额（万元）%';

COMMIT;

--------------------------------------------------------------------- 3.3.2.C 其中：预借现金业务形成的应收账款余额（万元）-----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.3.2.C 其中：预借现金业务形成的应收账款余额（万元）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.3.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.3.2其中：预借现金业务形成的应收账款余额（万元）%';

COMMIT;

-----------------3.3.2.1.C其中：现金分期形成的应收账款余额（万元）----------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.3.2.1.C其中：现金分期形成的应收账款余额（万元）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.3.2.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.3.2.1其中：现金转账业务形成的应收账款余额（万元）%';

COMMIT;

-----------------3.3.2.2.C其中：现金分期形成的应收账款余额（万元）----------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.3.2.2.C其中：现金分期形成的应收账款余额（万元）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.3.2.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.3.2.2其中：现金提取业务形成的应收账款余额（万元）%';

COMMIT;

-----------------3.3.3.C 其中：汽车分期形成的应收账款余额（万元）-------------



--------------------------------------------------------------------- 3.4应收账款余额-按是否为分期业务划分（万元）  -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.4应收账款余额-按是否为分期业务划分（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4应收账款余额-按是否为分期业务划分（万元）%';
commit;

--------------------------------------------------------------------- 3.4.1非分期业务形成的应收账款余额（万元）   -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.4.1非分期业务形成的应收账款余额（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.1其中：非分期业务形成的应收账款余额（万元）%';
commit;

--------------------------------------------------------------------- 3.4.1.1其中：生息的应收账款余额（万元）   -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.4.1.1其中：生息的应收账款余额（万元）贷记卡 至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.1.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.1.1其中：生息的应收账款余额（万元）%';

commit;

--------------------------------------------------------------------- 3.4.1.2其中：处于免息期的应收账款余额（万元）   -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.4.1.2其中：处于免息期的应收账款余额（万元）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.1.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.1.2其中：处于免息期的应收账款余额（万元）%';

commit;

--------------------------------------------------------------------- 3.4.2其中：分期业务应收账款余额（万元）   -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.4.2其中：分期业务应收账款余额（万元）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.2其中：分期业务应收账款余额（万元）%';

commit;

--------------------------------------------------------------------- 3.4.2.1其中：现金分期应收账款余额（万元）   -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.4.2.1其中：现金分期应收账款余额（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.2.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.2.1其中：现金分期应收账款余额（万元）%';

commit;

--------------------------------------------------------------------- 3.4.2.2其中：消费分期应收账款余额（万元）   -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.4.2.2其中：消费分期应收账款余额（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.2.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.2.2其中：消费分期应收账款余额（万元）%';

commit;

--------------------------------------------------------------------- 3.4.2.2.1其中：账单分期应收账款余额（万元）   -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.4.2.2.1其中：账单分期应收账款余额（万元）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.2.2.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.2.2.1其中：账单分期应收账款余额（万元）%';

commit;

--------------------------------------------------------------------- 3.4.2.2.2其中：专项分期应收账款余额（万元）   -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.4.2.2.2其中：专项分期应收账款余额（万元）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.2.2.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.2.2.2其中：专项分期应收账款余额（万元）%';

commit;

--------------------------------------------------------------------- 3.4.2.2.3其中：其他消费分期应收账款余额（万元）   -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.4.2.2.3其中：其他消费分期应收账款余额（万元） 至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.2.2.3.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.2.2.3其中：其他消费分期应收账款余额（万元）%';

commit;

--------------------------------------------------------------------- 3.5循环信用账户户数（户）  -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.5循环信用账户户数（户） 至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.5.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.5循环信用账户户数（户）%';

commit;

--------------------------------------------------------------------- 3.6循环信用账户透支余额（万元）  -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.6循环信用账户透支余额（万元） 至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.6.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.6循环信用账户透支余额（万元）%';

commit;

---------------------------------------------------------- 3.7.1本年累计不良资产证卷化出表的应收账款（万元）  -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.7.1本年累计不良资产证卷化出表的应收账款（万元） 至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.7.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.7.1本年累计不良资产证券化出表的应收账款(万元)%';
commit;

---------------------------------------------------------- 3.7.2本年累计以其他不良信贷资产转让方式出表的应收账款（万元）  -----------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.7.2本年累计以其他不良信贷资产转让方式出表的应收账款（万元） 至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.7.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.7.2本年累计以其他不良信贷资产转让方式出表的应收账款(万元)%';
commit;

/*======================================================================3.8应收账款余额-按持卡人年龄划分（万元）=====================================*/
----------------------------------------------------------------------3.8.1持卡人25岁以下（含）的应收账款余额------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.8.1持卡人25岁以下（含）的应收账款余额贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.8.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.8.1持卡人25岁以下（含）的应收账款余额%';
commit;

----------------------------------------------------------------------3.8.2持卡人25岁-35岁（含）的应收账款余额-----------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.8.2持卡人25岁-35岁（含）的应收账款余额 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.8.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.8.2持卡人25岁-35岁（含）的应收账款余额%';
commit;

----------------------------------------------------------------------3.8.3持卡人35岁-45岁（含）的应收账款余额-----------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.8.3持卡人35岁-45岁（含）的应收账款余额 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.8.3.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.8.3持卡人35岁-45岁（含）的应收账款余额%';
commit;

----------------------------------------------------------------------3.8.4持卡人45岁-55岁（含）的应收账款余额-----------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.8.4持卡人45岁-55岁（含）的应收账款余额 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.8.4.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.8.4持卡人45岁-55岁（含）的应收账款余额%';
commit;

----------------------------------------------------------------------3.8.5持卡人55岁以上的应收账款余额------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '3.8.5持卡人55岁以上的应收账款余额 记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.8.5.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.8.5持卡人55岁以上的应收账款余额%';
commit;

/* =====================================================================4.本年累计收入=========================================================*/
--年初删除本年累计
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '加工数据4.本年累计收入至CBRC_L_TRAN_ACCT_INNER_TX_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_L_TRAN_ACCT_INNER_TX_TMP';

COMMIT;

insert into CBRC_L_TRAN_ACCT_INNER_TX_TMP

  SELECT 
   I_DATADATE ASDATA_DATE,
   t.TX_NUM,
   t.REFERENCE_SUB_NUM,
   t.SUB_NUM,
   i.o_acct_num,
   t.ORG_NUM,
   t.ITEM_ID,
   t.TX_DATE,
   t.TX_TIME,
   t.CURR_CD,
   t.TX_TYPE,
   t.TX_AMT,
   t.OPPO_ACCT_NUM,
   t.OPPO_ACCT_NAM,
   t.OPPO_ORG_NUM,
   t.CHANNEL,
   t.TRANS_FLG,
   t.OP_TELLER_NUM,
   t.AUTH_TELLER_CD,
   t.OPPO_ITEM_ID,
   t.INPUT_DATE,
   t.CLOSE_DATE,
   t.REMARK,
   t.TRAN_STS,
   t.PAYMENT_PROPERTY,
   t.TRANS_BAL,
   t.DEPARTMENTD,
   t.DATE_SOURCESD,
   t.OPPO_ORG_NAM,
   t.DEBIT_BAL,
   t.CREDIT_BAL,
   t.CHANNEL_DES,
   t.CUST_TYPE,
   t.TRANTYPE_DESC
    FROM SMTMODS_L_TRAN_ACCT_INNER_TX T
    LEFT JOIN SMTMODS_L_ACCT_INNER I
      ON T.ACCT_NUM = I.ACCT_NUM
     AND I.DATA_DATE = I_DATADATE
   WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
         I_DATADATE
     AND I.O_ACCT_NUM IN ('90198010140327000021', --POS消费他代本应收银行手续费
                          '90198010140329000011', --本代本POS消费应收银行手续费
                          '90198403020002041', --分期付款手续费
                          '90198403020000641', --滞纳金
                          '90198403020000941', --预借现金手续费
                          '9019801014032700002', --POS消费他代本应收银行手续费
                          '9019801014032900001', --本代本POS消费应收银行手续费
                          '9019840302000204', --分期付款手续费
                          '9019840302000064', --滞纳金
                          '9019840302000094' --预借现金手续费
                          );
commit;

--------------------------------------------------------------------4.1年费收入（万元）----------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据4.本年累计收入至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         G.ORG_NUM,
         'G17_4.1.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_V_PUB_IDX_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD = '60210602' --银行卡年费收入
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM;

COMMIT;

--------------------------------------------------------------------- 4.2佣金收入（万元）借记卡--------------------------------------------

--因迁移过来的村镇数据可能仍然存在与业务提供的明细口径不一致的情况，2023年1-10月村镇累放数据cbrc_g17_amt_tmp2_cz单独使用村镇业务提供的累放明细出数,2024年以后正常使用原逻辑。 20231011zjm
--这部分村镇数据，逻辑仍然有缺陷，后续开发人员需根据实际情况将11月后村镇部分内部账账号和科目部分加上

V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据4.2佣金收入-借记卡本年累计至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);


  INSERT INTO CBRC_G17_DATA_COLLECT_TMP
    (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
           T.ORG_NUM AS ORG_NUM,
           'G17_4.2.A' AS ITEM_NUM,
           SUM(case
                 when PAYMENT_PROPERTY = '1' then
                  T.TX_AMT * U.CCY_RATE
                 when PAYMENT_PROPERTY = '2' then
                  T.TX_AMT * U.CCY_RATE * -1
               end) AS ITEM_VAL
      FROM CBRC_L_TRAN_ACCT_INNER_TX_TMP T
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = T.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
     WHERE /*T.ACCT_NUM IN ('9019801014032900001',
                          '9019801014032700002',
                          '90198010140329000011',
                          '90198010140327000021') --9019801014032700002（POS消费他代本应收银行手续费）+9019801014032900001（本代本POS消费应收银行手续费）
       AND*/ T.TRAN_STS = 'A' --正常
       AND T.REMARK like '%分润%'
     GROUP BY T.ORG_NUM;
  COMMIT;


V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据4.2佣金收入-贷记卡本年累计至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         G.ORG_NUM,
         'G17_4.2.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_V_PUB_IDX_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD = '60210603' --60210603  银行卡跨行结算业务收入
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM;
COMMIT;

--------------------------------------------------------------------4.3利息收入（万元）----------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '4.3利息收入（万元） 至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         G.ORG_NUM,
         'G17_4.3.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_V_PUB_IDX_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD like '6011' --6011利息收益
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM;
COMMIT;

--------------------------------------------------------------------- 4.3.1分期业务利息收入-------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '4.3.1其中：分期业务利息收入（万元） 贷记卡 至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_4.3.1.C.2022' AS ITEM_NUM,
         SUM(case
               when t.PAYMENT_PROPERTY = '1' then
                T.TX_AMT * U.CCY_RATE
               when t.PAYMENT_PROPERTY = '2' then
                T.TX_AMT * U.CCY_RATE * -1
             end) / 1.06 AS ITEM_VAL
    FROM CBRC_L_TRAN_ACCT_INNER_TX_TMP T
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = T.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE T.REMARK LIKE '%分润%'
     AND T.ACCT_NUM IN ('9019840302000204', '90198403020002041') --9019840302000204 分期付款手续费
  ;
COMMIT;

---------------------------------------------------------------------4.4惩罚性收入（万元）
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '4.4惩罚性收入（万元）贷记卡 至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_4.4.C.2022' AS ITEM_NUM,
         SUM(case
               when t.PAYMENT_PROPERTY = '1' then
                T.TX_AMT * U.CCY_RATE
               when t.PAYMENT_PROPERTY = '2' then
                T.TX_AMT * U.CCY_RATE * -1
             end) / 1.06 AS ITEM_VAL
    FROM CBRC_L_TRAN_ACCT_INNER_TX_TMP T
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = T.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE T.REMARK LIKE '%分润%'
     AND T.ACCT_NUM IN ('9019840302000064', '90198403020000641') -- 9019840302000064 滞纳金
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         G.ORG_NUM,
         'G17_4.4.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_L_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD like '602113' --602113  账户管理业务收入
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM;

COMMIT;

--------------------------------------------------------------------4.4.1其中：违约金（万元）
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '4.4.1其中：违约金（万元）贷记卡 至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_4.4.1.C.2022' AS ITEM_NUM,
         SUM(case
               when t.PAYMENT_PROPERTY = '1' then
                T.TX_AMT * U.CCY_RATE
               when t.PAYMENT_PROPERTY = '2' then
                T.TX_AMT * U.CCY_RATE * -1
             end) / 1.06 AS ITEM_VAL
    FROM CBRC_L_TRAN_ACCT_INNER_TX_TMP T
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = T.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE T.REMARK LIKE '%分润%'
     AND T.ACCT_NUM IN ('9019840302000064', '90198403020000641') -- 9019840302000064 滞纳金

  ;
COMMIT;

--------------------------------------------------------------------4.4.2其中：小额账户管理费（万元）----------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '4.4.2其中：小额账户管理费（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803' AS ORG_NUM,
         G.ORG_NUM AS ORG_NUM,
         'G17_4.4.2.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_L_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD like '602113' --602113  账户管理业务收入
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM;
COMMIT;

--------------------------------------------------------------------4.5预借现金手续费收入（万元）
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '4.5预借现金手续费收入（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_4.5.C.2022' AS ITEM_NUM,
         SUM(case
               when t.PAYMENT_PROPERTY = '1' then
                T.TX_AMT * U.CCY_RATE
               when t.PAYMENT_PROPERTY = '2' then
                T.TX_AMT * U.CCY_RATE * -1
             end) / 1.06 AS ITEM_VAL
    FROM CBRC_L_TRAN_ACCT_INNER_TX_TMP T
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = T.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE T.REMARK LIKE '%分润%'
     AND T.ACCT_NUM IN ('9019840302000094', '90198403020000941') -- 9019840302000094 预借现金手续费
  ;
COMMIT;

--------------------------------------------------------------------4.6分期业务收入（万元）
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '4.6分期业务收入（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_4.6.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%4.6分期业务收入（万元）%';
COMMIT;

--------------------------------------------------------------------4.7其他收入（万元）
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '4.7其他收入（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803' AS ORG_NUM,
         G.ORG_NUM AS ORG_NUM,
         'G17_4.7.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_L_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = I_DATADATE
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD = '60210601' --60210601  银行卡结算业务收入
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_4.7.C.2022' AS ITEM_NUM,
         SUM(ITEM_VAL) * -1 AS ITEM_VAL
    FROM CBRC_G17_DATA_COLLECT_TMP
   WHERE DATA_DATE = I_DATADATE
     AND ITEM_NUM IN
         ('G17_4.3.1.C.2022', 'G17_4.4.1.C.2022', 'G17_4.5.C.2022');
COMMIT;

/* =====================================================================5.损失准备=========================================================*/
----------------------------------------------------------------------5.1损失准备余额（万元）----------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据5.1损失准备至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         T.ORG_NUM,
         'G17_5.1.C.2022' AS ITEM_NUM,
         SUM(T.CREDIT_BAL)
    FROM SMTMODS_L_FINA_GL T
   WHERE T.DATA_DATE = I_DATADATE
     AND T.ORG_NUM = '009803'
     AND T.ITEM_CD like '1304'
   GROUP BY T.ORG_NUM; --1304  贷款损失准备

COMMIT;

-----------------------------------------------------------  5.2本期冲销（万元）
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据5.2本期冲销（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_5.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%5.2本期冲销（万元）%';

COMMIT;

-----------------------------------------------------------  5.3本年累计冲销（万元）
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据5.3本年累计冲销（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_5.3.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%5.3本年累计冲销（万元）%';

COMMIT;

-----------------------------------------------------------  5.4本年累计伪冒损失（万元）
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据5.4本年累计伪冒损失（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_5.4.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%5.4本年累计伪冒损失（万元）%';

COMMIT;

-----------------------------------------------------------  5.5伪冒损失准备余额（万元）
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据5.5伪冒损失准备余额（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_5.5.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%5.5伪冒损失准备余额（万元）%';

COMMIT;

/* =====================================================================6.逾期状况=========================================================*/
---------------------------------------------------------------6.1逾期账户户数（户）准贷记卡-----------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据6.1逾期账户户数（户）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_6.1.B',
         COUNT(DISTINCT A.ACCT_NUM)
    FROM SMTMODS_L_ACCT_CARD_CREDIT A --信用卡账户信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3' --3:准贷记卡
     AND (A.M1 <> 0 OR A.M2 <> 0 OR A.M3 <> 0 OR A.M4 <> 0 OR A.M5 <> 0 OR
         A.M6 <> 0 OR A.M6_UP <> 0);
COMMIT;

---------------------------------------------------------------6.1逾期账户户数（户）贷记卡-----------------------------------------------------

V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据6.1逾期账户户数（户）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.1逾期账户户数（户）%';
COMMIT;

------------------------------------------------------------6.2逾期账户授信额度（万元）准贷记卡---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据6.2逾期账户授信额度（万元）准贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_6.2.B' AS ITEM_NUM,
         SUM(B.QUANTUM)
    FROM SMTMODS_L_ACCT_CARD_CREDIT A --信用卡账户信息表
    LEFT JOIN SMTMODS_L_AGRE_CARD_CREDIT B --信用卡授信额度补充信息表
      ON A.CARD_NO = B.CARD_NO
     AND B.DATA_DATE = I_DATADATE
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3' --3:准贷记卡
     AND (A.M1 <> 0 OR A.M2 <> 0 OR A.M3 <> 0 OR A.M4 <> 0 OR A.M5 <> 0 OR
         A.M6 <> 0 OR A.M6_UP <> 0);

COMMIT;

------------------------------------------------------------6.2逾期账户授信额度（万元）贷记卡---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据6.2逾期账户授信额度（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.2逾期账户授信额度（万元）%';

COMMIT;

------------------------------------------------------------6.3未逾期的透支余额(M0)（万元）准贷记卡---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据6.3未逾期的透支余额(M0)（万元）准贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_6.3.B' AS ITEM_NUM,
         SUM(A.M0)
    FROM SMTMODS_L_ACCT_CARD_CREDIT A --信用卡账户信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3'; --3:准贷记卡
COMMIT;

------------------------------------------------------------6.3未逾期的透支余额(M0)（万元）贷记卡---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据6.3未逾期的透支余额(M0)（万元）贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.3.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.3未逾期的透支余额(M0)（万元）%';
COMMIT;

------------------------------------------------------------6.4逾期的透支余额（万元）***复用***-----------------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据6.4逾期的透支余额（万元）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

--    6.4.1    1-30天(M1) 准贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_6.4.1.B' AS ITEM_NUM,
         SUM(A.M1)
    FROM SMTMODS_L_ACCT_CARD_CREDIT A --信用卡账户信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3'; --3:准贷记卡

COMMIT;

--    6.4.1    1-30天(M1) 贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.1    1-30天(M1)%';

COMMIT;
--6.4.2    31-60天(M2)准贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_6.4.2.B' AS ITEM_NUM,
         SUM(A.M2)
    FROM SMTMODS_L_ACCT_CARD_CREDIT A --信用卡账户信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3'; --3:准贷记卡
COMMIT;
--6.4.2    31-60天(M2)贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.2    31-60天(M2)%';
COMMIT;
--6.4.3    61-90天(M3)准贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_6.4.3.B' AS ITEM_NUM,
         SUM(A.M3)
    FROM SMTMODS_L_ACCT_CARD_CREDIT A --信用卡账户信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3'; --3:准贷记卡
COMMIT;
--6.4.3    61-90天(M3)贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.3.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.3    61-90天(M3)%';
COMMIT;
--6.4.4    91-120天(M4)准贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_6.4.4.B' AS ITEM_NUM,
         SUM(A.M4)
    FROM SMTMODS_L_ACCT_CARD_CREDIT A --信用卡账户信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3'; --3:准贷记卡
COMMIT;
--6.4.4    91-120天(M4)贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.4.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.4    91-120天(M4)%';
COMMIT;
--6.4.5    121-150天(M5)准贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_6.4.5.B' AS ITEM_NUM,
         SUM(A.M5)
    FROM SMTMODS_L_ACCT_CARD_CREDIT A --信用卡账户信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3'; --3:准贷记卡
COMMIT;
--6.4.5    121-150天(M5)贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.5.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.5    121-150天(M5)%';
COMMIT;
--6.4.6    151-180天(M6)准贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_6.4.6.B' AS ITEM_NUM,
         SUM(A.M6)
    FROM SMTMODS_L_ACCT_CARD_CREDIT A --信用卡账户信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3'; --3:准贷记卡
COMMIT;
--6.4.6    151-180天(M6)贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.6.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.6    151-180天(M6)%';
COMMIT;
--6.4.7    超过180天(M6+)准贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_6.4.7.B' AS ITEM_NUM,
         SUM(A.M6_UP)
    FROM SMTMODS_L_ACCT_CARD_CREDIT A --信用卡账户信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '3'; --3:准贷记卡
COMMIT;
--6.4.7    超过180天(M6+)贷记卡
INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.7.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.7    超过180天(M6+)%';
COMMIT;

------------------------------------------------------------6.5分期业务逾期91天及以上形成的应收账款余额（万元） 贷记卡---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据6.5分期业务逾期91天及以上形成的应收账款余额（万元） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.5.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.5 分期业务逾期91天及以上形成的应收账款余额（万元）%';
COMMIT;

------------------------------------------------------------6.5.1 其中：现金分期逾期91天及以上形成的应收账款余额（万元） 贷记卡---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据6.5.1 其中：现金分期逾期91天及以上形成的应收账款余额（万元） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.5.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.5.1其中：现金分期逾期91天及以上形成的应收账款余额（万元）%';
COMMIT;

------------------------------------------------------------6.5.2 其中：消费分期逾期91天及以上形成的应收账款余额（万元） 贷记卡---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据6.5.2 其中：消费分期逾期91天及以上形成的应收账款余额（万元） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.5.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.5.2其中：消费分期逾期91天及以上形成的应收账款余额（万元）%';
COMMIT;

------------------------------------------------------------6.5.2.1 其中：账单分期逾期91天及以上形成的应收账款余额（万元） 贷记卡---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据6.5.2.1 其中：账单分期逾期91天及以上形成的应收账款余额（万元） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.5.2.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.5.2.1其中：账单分期逾期91天及以上的应收账款余额（万元）%';
COMMIT;

----------------------------------------------------6.5.2.2 其中：专项分期逾期91天及以上形成的应收账款余额（万元） 贷记卡---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据6.5.2.2 其中：专项分期逾期91天及以上形成的应收账款余额（万元） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.5.2.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.5.2.2其中：专项分期逾期91天及以上的应收账款余额（万元）%';
COMMIT;

----------------------------------------------------6.5.2.3 其中：其他消费逾期91天及以上形成的应收账款余额（万元） 贷记卡---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据6.5.2.3 其中：其他消费逾期91天及以上形成的应收账款余额（万元） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.5.2.3.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.5.2.3其中：其他消费逾期91天及以上分期应收账款余额（万元）%';
COMMIT;

----------------------------------------------------6.6 预借现金业务逾期91天及以上形成的应收账款余额（万元） 贷记卡---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '6.6 预借现金业务逾期91天及以上形成的应收账款余额（万元） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.6.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.6 预借现金业务逾期91天及以上形成的应收账款余额（万元）%';
COMMIT;

----------------------------------------------------6.6.1 现金转账逾期91天及以上形成的应收账款余额（万元） 贷记卡---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '6.6.1 现金转账逾期91天及以上形成的应收账款余额（万元） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.6.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.6.1其中：现金转账逾期91天及以上形成的应收账款余额（万元）%';
COMMIT;

----------------------------------------------------6.6.2 现金提取逾期91天及以上形成的应收账款余额（万元） 贷记卡---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '6.6.2 现金提取逾期91天及以上形成的应收账款余额（万元） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.6.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.6.2其中：现金提取逾期91天及以上形成的应收账款余额（万元）%';
COMMIT;

----------------------------------------------------6.7 当年新发生逾期透支余额（万元）
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '6.7 当年新发生逾期透支余额（万元） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.7.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.7 当年新发生逾期透支余额（万元）%';
COMMIT;

----------------------------------------------------6.8 当年新发生逾期90天以上透支余额（万元）
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '6.8 当年新发生逾期90天以上透支余额（万元） 贷记卡至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.8.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.8 当年新发生逾期90天以上透支余额（万元）%';
COMMIT;

----------------------------------------------------7.1 银行网点数（个）---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据7.1 银行网点数（个）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_7.1.A' AS ITEM_NUM,
         COUNT(DISTINCT A.ORG_NUM)
    FROM SMTMODS_L_PUBL_ORG_BRA A --机构表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.ORG_TYP = '4' --4:支行
     AND A.ORG_STATUS = 'A' --A:有效
     AND (A.ORG_NUM NOT LIKE '5%' OR A.ORG_NUM NOT LIKE '6%')
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
         END,
         'G17_7.1.A' AS ITEM_NUM,
         COUNT(1)
    FROM SMTMODS_L_PUBL_ORG_BRA A --机构表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.ORG_NAM LIKE '%支行%'
     AND A.ORG_STATUS = 'A' --A:有效
     AND (A.ORG_NUM LIKE '5%' OR A.ORG_NUM LIKE '6%')
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
            END

  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_7.1.A' AS ITEM_NUM,
         TO_NUMBER(NVL(T.A_ITEM_VAL, '0')) AS ITEM_NUM
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%7.1银行网点数（个）%';
COMMIT;

----------------------------------------------------7.2 自助机具台数（台）---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据7.2 自助机具台数（台）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         -- '009803',
         CASE
           WHEN SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6') THEN
            A.ORG_NUM
           ELSE
            '009803'
         END,
         'G17_7.2.A' AS ITEM_NUM,
         COUNT(DISTINCT A.EQUIPMENT_NBR)
    FROM SMTMODS_L_PUBL_EQUIPMENT A --自助设备信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.EQUIPMENT_TYP <> 'B' --B:POS
     AND A.EQUIPMENT_STS = 'A' --A:有效
     AND (A.EQUIPMENT_FLG = 'Y' OR A.EQUIPMENT_FLG IS NULL) --Y:是
   GROUP BY CASE
              WHEN SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6') THEN
               A.ORG_NUM
              ELSE
               '009803'
            END
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_7.2.A' AS ITEM_NUM,
         TO_NUMBER(NVL(T.A_ITEM_VAL, '0')) AS ITEM_NUM
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%7.2自助机具台数（台）%';
COMMIT;

----------------------------------------------------7.3 特约商户数（户）---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据7.3 特约商户数（户）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         CASE
           WHEN SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6') THEN
            A.ORG_NUM
           ELSE
            '009803'
         END,
         'G17_7.3.A' AS ITEM_NUM,
         COUNT(DISTINCT A.MERCHANT_NBR)
    FROM SMTMODS_L_PUBL_MERCHANT A --特约商户信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.MERCHANT_STS = 'A' --A:有效
   GROUP BY CASE
              WHEN SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6') THEN
               A.ORG_NUM
              ELSE
               '009803'
            END
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_7.3.A' AS ITEM_NUM,
         TO_NUMBER(NVL(T.A_ITEM_VAL, '0')) AS ITEM_NUM
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%7.3特约商户数（户）%';
COMMIT;

----------------------------------------------------7.4 POS设备台数（台）---------------------------------------------
V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '提取数据7.4 POS设备台数（台）至G17_DATA_COLLECT_TMP中间表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

INSERT INTO CBRC_G17_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         CASE
           WHEN SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6') THEN
            A.ORG_NUM
           ELSE
            '009803'
         END,
         'G17_7.4.A' AS ITEM_NUM,
         COUNT(DISTINCT A.EQUIPMENT_NBR)
    FROM SMTMODS_L_PUBL_EQUIPMENT A --自助设备信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.EQUIPMENT_TYP = 'B' --B:POS
     AND A.EQUIPMENT_STS = 'A' --A:有效
   GROUP BY CASE
              WHEN SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6') THEN
               A.ORG_NUM
              ELSE
               '009803'
            END
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_7.4.A' AS ITEM_NUM,
         TO_NUMBER(NVL(T.A_ITEM_VAL, '0')) AS ITEM_NUM
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%7.4POS设备台数（台）%';
COMMIT;

--=======================================================================================================-
-------------------------------------G17数据插至目标指标表--------------------------------------------
--=====================================================================================================---

V_STEP_ID   := V_STEP_ID + 1;
V_STEP_DESC := '产生G17指标数据，插至目标表';
V_STEP_FLAG := 0;
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);
/*---  ------------------所有指标插入目标表-----------------------------------  */

INSERT INTO CBRC_A_REPT_ITEM_VAL
  (DATA_DATE, --数据日期
   ORG_NUM, --机构号
   SYS_NAM, --模块简称
   REP_NUM, --报表编号
   ITEM_NUM, --指标号
   ITEM_VAL, --指标值（数值型）
   FLAG --标志位
   )
  SELECT I_DATADATE AS DATA_DATE,
         T.ORG_NUM,
         'CBRC' AS SYS_NAM,
         'G17' AS REP_NUM,
         T.ITEM_NUM,
         SUM(T.ITEM_VAL) AS ITEM_VAL,
         '2' AS FLAG
    FROM CBRC_G17_DATA_COLLECT_TMP T
   WHERE T.DATA_DATE = I_DATADATE
     AND T.ITEM_NUM IS NOT NULL
   GROUP BY T.ORG_NUM, T.ITEM_NUM;
COMMIT;
EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_L_TRAN_CARD_TX_TEMP';
EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_L_TRAN_TX_TEMP';
V_STEP_FLAG := 1;
V_STEP_DESC := V_PROCEDURE || '的业务逻辑全部处理完成';
SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

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
   
END proc_cbrc_idx2_g17