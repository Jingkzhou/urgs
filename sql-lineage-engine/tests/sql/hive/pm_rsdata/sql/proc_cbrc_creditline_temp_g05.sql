CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_creditline_temp_g05(II_DATADATE IN STRING)
/******************************
  @author: djh
  @create-date: 20220222
  @description: 用于处理G05中的1.3 按授信额度从支行到分行汇总，但是总行数据会删除
  @modification history:
  m0.author-create_date-description
  m1.取消dblink  将U_BASE_INST@SMTM1104 替换成uprr_U_BASE_INST
  
  临时表：、
PM_RSDATA.CBRC_UPRR_U_BASE_INST
PM_RSDATA.CBRC_GXH_CM_ORG_G05
PM_RSDATA.CBRC_GXH_A_REPT_ITEM_RESULT_G05
PM_RSDATA.CBRC_G05_DATA_COLLECT_TMP1
PM_RSDATA.CBRC_G05_DATA_COLLECT_TMP
  
  *******************************/

  IS
  V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(300); --任务描述
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  V_DATADATE  VARCHAR(10); --()YYYY-MM-DD
   DBANK       VARCHAR2(20);
  V_SYSTEM     VARCHAR2(30); 
  --游标循环，所有的向下汇总数据
  CURSOR CUR_BANK IS
    SELECT   FJG
      FROM (SELECT  FJG,JB FROM (
SELECT DISTINCT T.PARENT_INST_ID FJG,
                            CASE
                              WHEN T.PARENT_INST_ID = '010001' THEN
                               5.5
                              WHEN T.PARENT_INST_ID = '060000' THEN
                               6
                              ELSE
                               T.INST_LEVEL
                            END JB
              FROM  PM_RSDATA.CBRC_UPRR_U_BASE_INST T
             WHERE T.PARENT_INST_ID IS NOT NULL
               AND T.PARENT_INST_ID NOT IN ('888888', '999999')
               AND T.INST_ID <> '060101' )
             ORDER BY FJG  DESC );

BEGIN
  V_STEP_ID   := 0;
  V_STEP_DESC := '';

  I_DATADATE := II_DATADATE;
  V_SYSTEM   := 'CBRC';
  V_PROCEDURE := UPPER('SP_A_REPT_ITEM_RESULT_G05');
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

  V_STEP_ID   := 1;
  V_STEP_DESC := '删除临时表';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

  EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_GXH_CM_ORG_G05';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_GXH_A_REPT_ITEM_RESULT_G05';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_G05_DATA_COLLECT_TMP1';

  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

---------------------------------------------------------------------
  V_STEP_ID   := 1;
  V_STEP_DESC := '处理G05_DATA_COLLECT_TMP1表落地数据';


  --原表数据落临时表使用，反复利用
  INSERT INTO PM_RSDATA.CBRC_G05_DATA_COLLECT_TMP1
    (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
    SELECT DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB
      FROM PM_RSDATA.CBRC_G05_DATA_COLLECT_TMP
     WHERE ITEM_NUM LIKE 'G05_I_1.3%';

     ----------------------------------------------------------

  V_STEP_ID   := 1;
  V_STEP_DESC := '处理GXH_CM_ORG_G05表数据';

  INSERT INTO PM_RSDATA.CBRC_GXH_CM_ORG_G05
    (INST_ID,
     INST_NAME,
     INST_LAYER,
     ADDRESS,
     ZIP,
     TEL,
     FAX,
     IS_BUSSINESS,
     ORDER_NUM,
     DESCRIPTION,
     START_DATE,
     END_DATE,
     CREATE_TIME,
     ENABLED,
     INST_REGION,
     EMAIL,
     INST_PATH,
     INST_LEVEL,
     IS_HEAD)
    SELECT INST_ID,
           INST_NAME,
           INST_LAYER,
           ADDRESS,
           ZIP,
           TEL,
           FAX,
           IS_BUSSINESS,
           ORDER_NUM,
           DESCRIPTION,
           START_DATE,
           END_DATE,
           CREATE_TIME,
           ENABLED,
           INST_REGION,
           EMAIL,
           INST_PATH,
           INST_LEVEL,
           IS_HEAD
      FROM PM_RSDATA.CBRC_UPRR_U_BASE_INST
     WHERE INST_ID IN (SELECT  DISTINCT INST_ID FROM 
                            (SELECT DISTINCT INST_ID,hq__level
                                FROM PM_RSDATA.CBRC_UPRR_U_BASE_INST 
                                START WITH PARENT_INST_ID IS NOT NULL
                                CONNECT BY PRIOR PARENT_INST_ID = INST_ID
                                ) WHERE hq__level ='2'
                        );
  COMMIT;

-----------------------------------------------------------------
  V_STEP_ID   := 1;
  V_STEP_DESC := '开始处理机构循环分组汇总（分、总）数据';

  
  OPEN CUR_BANK;
  LOOP
    FETCH CUR_BANK
      INTO DBANK;
    EXIT WHEN CUR_BANK%NOTFOUND;

    DELETE FROM PM_RSDATA.CBRC_GXH_A_REPT_ITEM_RESULT_G05 A
     WHERE A.ORG_NUM = DBANK
       AND A.DATA_DATE = V_DATADATE;
    COMMIT;

    --汇总处理
    INSERT INTO PM_RSDATA.CBRC_GXH_A_REPT_ITEM_RESULT_G05
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       B_CURR_CD,
       ITEM_VAL,
       ITEM_VAL_V)
      SELECT A.DATA_DATE,
             DBANK JG,
             'CBRC' AS SYS_NAM,
             'G05_I' AS REP_NUM,
             A.ITEM_NUM,
             ''AS B_CURR_CD,
             SUM(A.LOAN_ACCT_BAL_RMB) ITEM_VAL,
             '' AS ITEM_VAL_V
        FROM PM_RSDATA.CBRC_G05_DATA_COLLECT_TMP1 A
       INNER JOIN PM_RSDATA.CBRC_UPRR_U_BASE_INST B
          ON A.ORG_NUM = B.INST_ID
       INNER JOIN PM_RSDATA.CBRC_GXH_CM_ORG_G05 C
          ON B.PARENT_INST_ID = C.INST_ID
       INNER JOIN CBRC_A_REPT_ITEM_CONF D
          ON A.ITEM_NUM = D.ITEM_NUM
      -- AND D.CONF_FLG <> '1'  --会在配置报表配置总账，自己汇总，不走1104大汇总
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM IN
             (SELECT  DISTINCT INST_ID FROM 
                            (SELECT DISTINCT I.INST_ID,hq__level
                FROM PM_RSDATA.CBRC_UPRR_U_BASE_INST I
                  START WITH I.PARENT_INST_ID = DBANK
              CONNECT BY  PRIOR I.PARENT_INST_ID =  I.INST_ID
              ) WHERE hq__level ='1'
                        )
       GROUP BY A.DATA_DATE, DBANK, A.ITEM_NUM;







    COMMIT;

  -----------------------------------------------------------
    V_STEP_ID   := 1;
    V_STEP_DESC := '处理机构循环汇总到总行为止';


    --从支行汇总分行数据反插入G05_DATA_COLLECT_TMP1，在循环中汇总到总行为止
    MERGE INTO PM_RSDATA.CBRC_G05_DATA_COLLECT_TMP1 A
    USING PM_RSDATA.CBRC_GXH_A_REPT_ITEM_RESULT_G05 B
    ON (A.DATA_DATE = B.DATA_DATE AND A.ORG_NUM = B.ORG_NUM AND A.ITEM_NUM = B.ITEM_NUM)
    WHEN MATCHED THEN
      UPDATE SET A.LOAN_ACCT_BAL_RMB = B.ITEM_VAL
    WHEN NOT MATCHED THEN
      INSERT
        (A.DATA_DATE, A.ORG_NUM, A.ITEM_NUM, A.LOAN_ACCT_BAL_RMB)
      VALUES
        (B.DATA_DATE, B.ORG_NUM, B.ITEM_NUM, B.ITEM_VAL);
    COMMIT;

  END LOOP;
  CLOSE CUR_BANK;
-------------------------------------------------------
  V_STEP_ID   := 1;
  V_STEP_DESC := '循环结束，删除所有总行数据';


  --汇总成总行的数据，全部删除
  DELETE FROM PM_RSDATA.CBRC_GXH_A_REPT_ITEM_RESULT_G05 WHERE ORG_NUM = '990000';  --modify by djh 20221014 机构变更000000->990000

    V_STEP_DESC := V_PROCEDURE || '的业务逻辑全部处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
				
    DBMS_OUTPUT.PUT_LINE('O_STATUS=0');
    DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=完成'); 
    ------------------------------------------------------------------

 -- END IF;

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
   
END proc_cbrc_creditline_temp_g05;
