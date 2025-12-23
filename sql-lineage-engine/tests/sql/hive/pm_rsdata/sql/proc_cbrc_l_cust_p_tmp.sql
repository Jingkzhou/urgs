CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_l_cust_p_tmp(II_DATADATE IN STRING --跑批日期
                                             
)
/******************************
  @author:xiangxu
  @create-date:2015-09-19
  @description:对公客户信息处理（全量客户信息+对公补充信息）
  @modification history:
  m0.author-create_date-description
  *******************************/
 IS
  V_SCHEMA    STRING; --当前存储过程所属的模式名
  V_SYSTEM    STRING; --系统名
  V_PROCEDURE  STRING; --当前储存过程名称
  V_TAB_NAME  STRING; --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE  STRING; --数据日期(字符型)YYYY-MM-DD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC STRING; --任务描述
  V_STEP_FLAG STRING; --任务执行状态标识
  V_ERRORCODE     STRING; --错误编码
  V_ERRORDESC     STRING; --错误内容
  II_STATUS    INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
BEGIN
  IF II_STATUS=0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE := II_DATADATE;
    V_SYSTEM  := 'CBRC';
    V_SCHEMA   := 'USER';
    V_PROCEDURE := UPPER('PROC_CBRC_L_CUST_P_TMP');
    
    sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,  V_ERRORCODE,  V_STEP_DESC,  II_DATADATE);

    V_TAB_NAME := 'CBRC_L_CUST_P_TMP';
  
  
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
    sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,  V_ERRORCODE,  V_STEP_DESC,  II_DATADATE);
    
    
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_L_CUST_P_TMP' ;
    
    

  
    V_STEP_ID   := 2;
    V_STEP_DESC := '对公客户临时表处理(全量客户信息+对公补充信息)';
    V_STEP_FLAG := 0;
    sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,  V_ERRORCODE,  V_STEP_DESC,  II_DATADATE);


  
    INSERT  INTO PM_RSDATA.CBRC_L_CUST_P_TMP 
      (CUST_ID, --客户号
       CITY_VILLAGE_FLG, --农户标志
       OPERATE_CUST_TYPE, --经营性客户类型
       CUST_TYPE, --客户大类
       INLANDORRSHORE_FLG --境内境外标志
       )
      SELECT T.CUST_ID, --客户号
             C.CITY_VILLAGE_FLG, --农户标志
             C.OPERATE_CUST_TYPE, --经营性客户类型
             T.CUST_TYPE, --客户大类
             T.INLANDORRSHORE_FLG --境内境外标志
        FROM PM_RSDATA.SMTMODS_L_CUST_ALL T
       INNER JOIN PM_RSDATA.SMTMODS_L_CUST_P C 
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = T.DATA_DATE
       WHERE T.DATA_DATE = I_DATADATE;

    COMMIT;



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
   
END proc_cbrc_l_cust_p_tmp