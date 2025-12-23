CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g1402(II_DATADATE  IN STRING  --跑批日期
                                                   )
/******************************
  @AUTHOR:DJH
  @CREATE-DATE:20240910
  @DESCRIPTION:G1402  第II部分：大额风险暴露客户情况表
  @MODIFICATION HISTORY:
  
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1402
     CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1402
依赖表：CBRC_BUSINESS_TABLE_TYDYKH_RESULT  --G1405同业单一客户大额风险暴露情况表
     CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403
     CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1404
     CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1406
     CBRC_G1403_CONFIG_RESULT_MAPPING
     CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1404
     CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1406
     CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1404
     CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1406
  *******************************/
 IS
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  V_PER_NUM   VARCHAR(30); --报表编号
  V_DATADATE  VARCHAR2(10);
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR(30);
  

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    V_PER_NUM   := 'G1402';
    I_DATADATE  := II_DATADATE;
    V_DATADATE  := TO_CHAR(TO_DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');
    V_TAB_NAME  := 'G1402';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G1402');
	V_SYSTEM    := 'CBRC';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
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
       AND REP_NUM = V_PER_NUM
       AND IS_TOTAL = 'Y';
    COMMIT;


     --在G1403,G1405(单一)G1404,G1406(集团)的基础上取非集团成员的非同业单一客户，非集团成员的同业单一客户，同业集团客户，非同业集团客户等客户
     --1404+1406集团+剩余非集团，按照风险暴露总和的合计汇总排序；
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1402';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1402'; -- G1402  大额风险暴露客户情况表



  --==================================================
    --G1402业务数据排序结果表处理
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1402业务数据排序结果表处理';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1402
  (DATA_DATE,
   ORG_CODE,
   CUST_NAM,
   ID_NO,
   CUST_TYPE,
   RISK_TOTAL,
   HAVE_RISK_SUBTOTAL,
   GENERAL_RISK_TOTAL,
   TRADE_ACCOUNT,
   POTENTIAL_RISK,
   PRIN_MINUS,
   SPECIFIC_RISK,
   TRADE_RIVAL_RISK,
   OTHER_RISK)
  SELECT I_DATADATE,
         ORG_CODE,
         CUST_NAM,
         ID_NO,
         CUST_TYPE,
         RISK_TOTAL,
         HAVE_RISK_SUBTOTAL,
         GENERAL_RISK_TOTAL,
         TRADE_ACCOUNT,
         POTENTIAL_RISK,
         PRIN_MINUS,
         SPECIFIC_RISK,
         TRADE_RIVAL_RISK,
         OTHER_RISK
    FROM (SELECT ORG_CODE,
                 CUST_NAM,
                 ID_NO,
                 CUST_TYPE,
                 SUM(RISK_TOTAL) AS RISK_TOTAL,
                 SUM(HAVE_RISK_SUBTOTAL) AS HAVE_RISK_SUBTOTAL,
                 SUM(GENERAL_RISK_TOTAL) AS GENERAL_RISK_TOTAL,
                 SUM(TRADE_ACCOUNT) AS TRADE_ACCOUNT,
                 SUM(POTENTIAL_RISK) AS POTENTIAL_RISK,
                 SUM(PRIN_MINUS) AS PRIN_MINUS,
                 SUM(SPECIFIC_RISK) AS SPECIFIC_RISK,
                 SUM(TRADE_RIVAL_RISK) AS TRADE_RIVAL_RISK,
                 SUM(OTHER_RISK) AS OTHER_RISK
            FROM (SELECT ORG_CODE,
                         CUST_NAM,
                         ID_NO,
                         RISK_TOTAL AS RISK_TOTAL,
                         HAVE_RISK_SUBTOTAL AS HAVE_RISK_SUBTOTAL,
                         GENERAL_RISK_TOTAL AS GENERAL_RISK_TOTAL,
                         TRADE_ACCOUNT AS TRADE_ACCOUNT,
                         POTENTIAL_RISK AS POTENTIAL_RISK,
                         PRIN_MINUS AS PRIN_MINUS,
                         '同业集团客户' AS CUST_TYPE,
                         0 AS SPECIFIC_RISK,
                         0 AS TRADE_RIVAL_RISK,
                         0 AS OTHER_RISK
                    FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1406 T --G1405同业单一客户大额风险暴露情况表（同业单一）  基础上的 G1406同业集团客户大额风险暴露情况表（同业集团）
                  union all
                  SELECT ORG_CODE,
                         CUST_NAM,
                         ID_NO,
                         FXBLHJ AS RISK_TOTAL,
                         BKHMFXBL AS HAVE_RISK_SUBTOTAL,
                         YBFXBLHJ AS GENERAL_RISK_TOTAL,
                         JYZBFXBL AS TRADE_ACCOUNT,
                         QZFXBLHJ AS POTENTIAL_RISK,
                         FXHS AS PRIN_MINUS,
                         '非同业集团客户' AS CUST_TYPE,
                         ZCGLCP AS SPECIFIC_RISK,
                         0 AS TRADE_RIVAL_RISK,
                         0 AS OTHER_RISK
                    FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1404 T --G1403非同业单一客户大额风险暴露情况表（非同业单一）基础上的 G1404非同业集团客户及经济依存客户大额风险暴露情况表（非同业集团）
                  UNION ALL
                  SELECT A.ORG_CODE,
                         A.CUST_NAM,
                         A.ID_NO,
                         SUM(A.RISK_TOTAL) AS RISK_TOTAL,
                         SUM(A.HAVE_RISK_SUBTOTAL) AS HAVE_RISK_SUBTOTAL,
                         SUM(A.GENERAL_RISK_TOTAL) AS GENERAL_RISK_TOTAL,
                         SUM(A.TRADE_ACCOUNT) AS TRADE_ACCOUNT,
                         SUM(A.POTENTIAL_RISK) AS POTENTIAL_RISK,
                         SUM(A.PRIN_MINUS) AS PRIN_MINUS,
                         '同业单一客户' AS CUST_TYPE,--非集团成员的同业单一客户
                         0 AS SPECIFIC_RISK,
                         0 AS TRADE_RIVAL_RISK,
                         0 AS OTHER_RISK
                    FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT A --G1405同业单一客户大额风险暴露情况表
                   LEFT JOIN CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1406 B --G1406同业集团客户大额风险暴露情况表（明细）
                      ON A.ID_NO = B.ID_NO
                     AND B.DATA_DATE = I_DATADATE
                     AND A.ORG_CODE=B.ORG_CODE
                     AND B.BELONG_GROUP_FLAG ='01'
                   WHERE  B.ID_NO IS NULL --G1405剩余非集团成员的同业单一客户
                     AND A.CUST_NAM NOT IN (SELECT CUST_NAM FROM  CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1406) --且不包含G1406通过名称反找G1405同名数据，合并到G1406的部分，因为集团应包含
                   GROUP BY A.ORG_CODE, A.CUST_NAM, A.ID_NO
                  UNION ALL
                  SELECT A.ORG_CODE,
                         A.CUST_NAM,
                         A.ID_NO,
                         SUM(A.FXBLHJ) AS RISK_TOTAL,
                         SUM(A.BKHMFXBL) AS HAVE_RISK_SUBTOTAL,
                         SUM(A.YBFXBLHJ) AS GENERAL_RISK_TOTAL,
                         SUM(A.JYZBFXBL) AS TRADE_ACCOUNT,
                         SUM(A.QZFXBLHJ) AS POTENTIAL_RISK,
                         SUM(A.FXHS) AS PRIN_MINUS,
                         '非同业单一客户' AS CUST_TYPE,--非集团成员的非同业单一客户
                         SUM(A.ZCGLCP) AS SPECIFIC_RISK,
                         0 AS TRADE_RIVAL_RISK,
                         0 AS OTHER_RISK
                    FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403 A
                   LEFT JOIN CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1404 B --G1404非同业集团客户及经济依存客户大额风险暴露情况表
                      ON A.ID_NO = B.ID_NO
                     AND B.DATA_DATE = I_DATADATE
                     AND A.ORG_CODE=B.ORG_CODE
                     AND B.BELONG_GROUP_FLAG ='01'
                   WHERE B.ID_NO IS NULL --G1403剩余非集团成员的同业单一客户
                     AND A.CUST_NAM NOT IN (SELECT CUST_NAM FROM  CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1404) --且不包含G1404通过名称反找G1403同名数据，合并到G1404，因为集团应包含
                   GROUP BY A.ORG_CODE, A.CUST_NAM, A.ID_NO)
           GROUP BY ORG_CODE, CUST_NAM, ID_NO, CUST_TYPE) A;
    COMMIT;



    --==================================================
    --G1402数据机构处理最终表
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1402数据机构处理最终表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1402
      (DATA_DATE,
       ORG_CODE,
       SEQ_NO,
       CUST_NAM,
       ID_NO,
       CUST_TYPE,
       RISK_TOTAL,
       HAVE_RISK_SUBTOTAL,
       GENERAL_RISK_TOTAL,
       TRADE_ACCOUNT,
       POTENTIAL_RISK,
       PRIN_MINUS,
       REPORT_ITEM_ID,
       SPECIFIC_RISK,
       TRADE_RIVAL_RISK,
       OTHER_RISK)
      SELECT I_DATADATE,
             ORG_CODE,
             A.SEQ_NO,
             CUST_NAM,
             ID_NO,
             CUST_TYPE,
             RISK_TOTAL,
             HAVE_RISK_SUBTOTAL,
             GENERAL_RISK_TOTAL,
             TRADE_ACCOUNT,
             POTENTIAL_RISK,
             PRIN_MINUS,
             B.REPORT_ITEM_ID,
             SPECIFIC_RISK,
             TRADE_RIVAL_RISK,
             OTHER_RISK
        FROM (SELECT ORG_CODE,
                     ROW_NUMBER() OVER(PARTITION BY ORG_CODE ORDER BY SUM(RISK_TOTAL) DESC) AS SEQ_NO,
                     CUST_NAM,
                     ID_NO,
                     CUST_TYPE,
                     SUM(RISK_TOTAL) AS RISK_TOTAL,
                     SUM(HAVE_RISK_SUBTOTAL) AS HAVE_RISK_SUBTOTAL,
                     SUM(GENERAL_RISK_TOTAL) AS GENERAL_RISK_TOTAL,
                     SUM(TRADE_ACCOUNT) AS TRADE_ACCOUNT,
                     SUM(POTENTIAL_RISK) AS POTENTIAL_RISK,
                     SUM(PRIN_MINUS) AS PRIN_MINUS,
                     SUM(SPECIFIC_RISK) AS SPECIFIC_RISK,
                     SUM(TRADE_RIVAL_RISK) AS TRADE_RIVAL_RISK,
                     SUM(OTHER_RISK) AS OTHER_RISK
                FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1402
               GROUP BY ORG_CODE, CUST_NAM, ID_NO, CUST_TYPE) A
        LEFT JOIN CBRC_G1403_CONFIG_RESULT_MAPPING B
          ON A.SEQ_NO = B.SEQ_NO;
    COMMIT;

    -------------------------------------------------------------------------------------------
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
   
END proc_cbrc_idx2_g1402;
