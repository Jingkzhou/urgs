CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g06_2(II_DATADATE IN STRING --跑批日期
                                              )
/******************************
  @author:wangjinbao
  @create-date:20230327
  @description:G06_2
  @modification history:
  
  
目标表：CBRC_A_REPT_ITEM_VAL
码值表：CBRC_G06_2_CONFIG_TMP
集市表：CBRC_FAMS_CHB_MONTH_REPORT_DETAIL_SHEET2 --G06指标2表 资管文件落地表



  *******************************/
 IS
  V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  II_STATUS    INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR2(30);
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    V_SYSTEM    := 'CBRC';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    I_DATADATE := II_DATADATE;

    
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G06_2');
    V_TAB_NAME  := 'G06_2';

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ------------------------------------------------------------------------------------------------------

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = 'G06_2';

    COMMIT;

    V_STEP_FLAG := 2;
    V_STEP_DESC := 'G06_2 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DECLARE
      V_SQL VARCHAR2(1000);
    BEGIN
      FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                  FROM CBRC_G06_2_CONFIG_TMP F) LOOP
        V_SQL := 'UPDATE CBRC_G06_2_CONFIG_TMP B SET B.ITEM_VAL = (SELECT ' ||
                 I.REPORT_ITEM_NAME ||
                 ' FROM CBRC_FAMS_CHB_MONTH_REPORT_DETAIL_SHEET2
                            WHERE PROPERTYCODE = ' || '''' ||
                 I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = '|| '''' || I_DATADATE || '''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                 I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                 I.REPORT_ITEM_NAME || '''';
        EXECUTE IMMEDIATE V_SQL;
        COMMIT;
      END LOOP;
    END;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             '009816',
             'CBRC' AS SYS_NAM,
             'G06_2' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             '1' AS FLAG
        FROM CBRC_G06_2_CONFIG_TMP;

    COMMIT;

    V_STEP_FLAG := 3;
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
   
END proc_cbrc_idx2_g06_2