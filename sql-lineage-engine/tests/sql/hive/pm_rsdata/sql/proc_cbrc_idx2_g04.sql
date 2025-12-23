CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g04(II_DATADATE IN STRING --跑批日期         
                                               )
/******************************
  @author:fanxiaoyu
  @create-date:2015-09-19
  @description:G04
  @modification history:
  m0.20150919-fanxiaoyu-G04


目标表：CBRC_A_REPT_ITEM_VAL
视图表：SMTMODS_V_PUB_IDX_FINA_GL
集市表：SMTMODS_L_PUBL_RATE

  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_REP_NUM      VARCHAR(30); --报表名称
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE     VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS    INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM     VARCHAR2(30);

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE     := II_DATADATE;
    V_DATADATE     := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');
    D_DATADATE_CCY := I_DATADATE;
    V_SYSTEM       := 'CBRC';
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_G04');
    V_REP_NUM      := 'G04';

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

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = V_REP_NUM
       AND FLAG IN ('1', '2')
       AND ITEM_NUM IN (  'G04.14.A.2025' );
    COMMIT;

    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 2;
    V_STEP_DESC := '14.增值税';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, SYS_NAM, REP_NUM, ORG_NUM, ITEM_NUM, ITEM_VAL, FLAG,IS_TOTAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       'CBRC' AS SYS_NUM,
       'G04' AS REP_NUM,
       T.ORG_NUM AS ORG_NUM,
       'G04.14.A.2025' AS ITEM_NUM,
       (CASE
         WHEN SUM(CREDIT_BAL* T2.CCY_RATE) - SUM(DEBIT_BAL* T2.CCY_RATE) > 0 THEN
          SUM(CREDIT_BAL* T2.CCY_RATE) - SUM(DEBIT_BAL* T2.CCY_RATE)
         ELSE
          0
       END) AS ITEM_VAL,
       '2' AS FLAG,
        'N' AS IS_TOTAL
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
         LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T.DATA_DATE = T2.DATA_DATE
       WHERE T.DATA_DATE <= I_DATADATE
       AND T.DATA_DATE >=
	   TO_CHAR(TRUNC(DATE(I_DATADATE, 'YYYYMMDD'), 'yEAR'), 'YYYYMMDD') 
       AND SUBSTR(T.DATA_DATE, 5, 4) IN ('0331', '0630', '0930', '1231')
       AND T.ITEM_CD IN ('222110', '222113', '222114')
       --AND T.CURR_CD = 'CNY'
       GROUP BY T.ORG_NUM;
    COMMIT;


    V_STEP_ID   := 3;
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
   
END proc_cbrc_idx2_g04