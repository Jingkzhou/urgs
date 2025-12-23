CREATE OR REPLACE PROCEDURE PROC_CBRC_U_BASE_INST(II_DATADATE IN string --跑批日期
                                              
                                               )
/******************************
  @author:fanxiaoyu
  @create-date:2015-09-19
  @description:G04
  @modification history:
  m0.20150919-fanxiaoyu-G04

  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_REP_NUM      VARCHAR(30); --报表名称
  I_DATADATE     string; --数据日期(数值型)YYYYMMDD
  V_DATADATE     VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  D_DATADATE_CCY string; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS    INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM      VARCHAR2(30);

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    I_DATADATE     := II_DATADATE;
    V_DATADATE     := I_DATADATE;
    D_DATADATE_CCY := I_DATADATE;
    V_SYSTEM       := 'CBRC';
    V_PROCEDURE    := UPPER('PROC_CBRC_U_BASE_INST');
    V_REP_NUM      := 'CBRC_UPRR_U_BASE_INST';
    V_STEP_DESC := '存储过程开始处理';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_REP_NUM || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_UPRR_U_BASE_INST ;
    COMMIT;



    V_STEP_ID   := 2;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '加工数据UPMS_ORG';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    insert into CBRC_UPRR_U_BASE_INST
(
INST_ID, --机构编号
INST_NAME, --机构名称
INST_SMP_NAME, --机构简称
PARENT_INST_ID, --上级机构
INST_LAYER, --机构级别
ORDER_NUM, --排序值
START_DATE, --启用日期
END_DATE, --终止日期
CREATE_TIME, --创建时间
ENABLED, --启用标识
INST_PATH, --机构编号路径
INST_LEVEL, --机构在数据库中的物理级别
IS_HEAD --是否是总行 TRUE:是 FALSE:否
)
SELECT  ORG_ID,
      ORG_NAME,
      ORG_SHORT_NAME ,
      SUP_ORG_ID,
      ORG_LEVEL_ID ,
      ORDER_NUM,
      BEGIN_DATE,
      END_DATE ,
      CREATE_TIME,
      IS_USED,
      SUP_ORG_IDS,
        LENGTH(replace(replace(SUP_ORG_IDS,',,',','),',-1,00001','')) - LENGTH(REPLACE(replace(replace(SUP_ORG_IDS,',,',','),',-1,00001',''), ',', '')) ,
       CASE WHEN ORG_ID ='990000' THEN 'true' ELSE 'false' END
 FROM CBRC_UPMS_ORG
  WHERE ORG_ID <>'00001';
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
   
END ;