CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g1406(II_DATADATE  IN STRING --跑批日期
                                                   )
/******************************
  @AUTHOR:DJH
  @CREATE-DATE:20240910
  @DESCRIPTION:G1406  第VI部分：同业集团客户大额风险暴露情况表
  @MODIFICATION HISTORY:
  需求编号：JLBA202505280011 上线日期： 2025-09-19，修改人：狄家卉，提出人：赵翰君  修改原因：关于实现1104监管报送报表自动化采集加工的需求  增加009801清算中心(国际业务部)外币折人民币业务
  
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1406
     CBRC_TMP_BUSINESS_GROUP_FLAG_G1406
     CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1406
     CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE_G1406
码值表：CBRC_G1406_CONFIG_TMP
     CBRC_G1406_CONFIG_TMP_QS
     CBRC_G1406_CONFIG_TMP_TY
依赖表：CBRC_G1405_CONFIG_RESULT_MAPPING
     CBRC_BUSINESS_TABLE_TYDYKH_RESULT  --G1405结果表 
集市表：SMTMODS_L_CUST_EXTERNAL_INFO
  
  
  
  
  
  
  
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
    V_PER_NUM   := 'G1406';
    I_DATADATE  := II_DATADATE;
    V_DATADATE  := TO_CHAR(DATE(I_DATADATE), 'YYYY-MM-DD');
    V_TAB_NAME  := 'G1406';
	V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G1406');
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


     --取同业集团客户。在G1405表基础上，取同业集团客户，按照风险暴露总和的合计汇总排序；
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_BUSINESS_GROUP_FLAG_G1406';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1406'; --通过找同业集团找到对应数据
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE_G1406';--通过找同业集团找到对应数据（数据排名）
   -- EXECUTE IMMEDIATE 'TRUNCATE TABLE  TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1406';--通过G1406反找G1405同名客户合并为集团客户
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1406'; -- G1406  第VI部分：同业集团客户大额风险暴露情况表
    --CBRC_G1405_CONFIG_RESULT_MAPPING  共用配置表   CBRC_G1406_CONFIG_TMP  报表映射指标配置表(金融市场)   CBRC_G1406_CONFIG_TMP_TY 报表映射指标配置表(同业金融)

    /*中国银行股份有限公司、
     中国农业银行股份有限公司、
     中国工商银行股份有限公司、
     中国建设银行股份有限公司、
     交通银行股份有限公司、
     国家开发银行、
     中国农业发展银行、
     进出口银行*/
    --这些客户直接判定为非集团客户，不需要要找所属集团


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1406数据明细处理表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1406
    (ORG_CODE,
     CUST_NAM,
     ID_NO,
     RISK_TOTAL,
     HAVE_RISK_SUBTOTAL,
     GENERAL_RISK_TOTAL,
     BUY_BACK,
     INTERBANK_BOND,
     POLICY_BANK,
     INTERBANK_RECEIPT,
     TRADE_ACCOUNT,
     POTENTIAL_RISK,
     PRIN_MINUS,
     DATA_DATE,
     CUST_TYPE,
     INTERBANK_FUNDING,
     INTERBANK_BORROWING,
     INTERBANK_LENDING,
     BELONG_GROUP_ORG_CD,
     BELONG_GROUP_NAME)
    SELECT ORG_CODE,
           CUST_NAM,
           ID_NO,
           RISK_TOTAL,
           HAVE_RISK_SUBTOTAL,
           GENERAL_RISK_TOTAL,
           BUY_BACK,
           INTERBANK_BOND,
           POLICY_BANK,
           INTERBANK_RECEIPT,
           TRADE_ACCOUNT,
           POTENTIAL_RISK,
           PRIN_MINUS,
           I_DATADATE,
           CUST_TYPE,
           INTERBANK_FUNDING,
           INTERBANK_BORROWING,
           INTERBANK_LENDING,
           BELONG_GROUP_ORG_CD,
           BELONG_GROUP_NAME
      FROM (SELECT A.ORG_CODE,
                   A.CUST_NAM,
                   A.ID_NO,
                   SUM(RISK_TOTAL) AS RISK_TOTAL,
                   SUM(HAVE_RISK_SUBTOTAL) AS HAVE_RISK_SUBTOTAL,
                   SUM(GENERAL_RISK_TOTAL) AS GENERAL_RISK_TOTAL,
                   SUM(BUY_BACK) AS BUY_BACK,
                   SUM(INTERBANK_BOND) AS INTERBANK_BOND,
                   SUM(POLICY_BANK) AS POLICY_BANK,
                   SUM(INTERBANK_RECEIPT) AS INTERBANK_RECEIPT,
                   SUM(TRADE_ACCOUNT) AS TRADE_ACCOUNT,
                   SUM(POTENTIAL_RISK) AS POTENTIAL_RISK,
                   SUM(PRIN_MINUS) AS PRIN_MINUS,
                   '同业集团客户' AS CUST_TYPE,
                   SUM(INTERBANK_FUNDING) AS INTERBANK_FUNDING,
                   SUM(INTERBANK_BORROWING) AS INTERBANK_BORROWING,
                   SUM(INTERBANK_LENDING) AS INTERBANK_LENDING,
                   C.BELONG_GROUP_ORG_CD,
                   C.BELONG_GROUP_NAME
              FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT A --G1405结果表
             INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO C --客户外部信息表 判定所属集团组织机构代码  所属集团名称 “不空 ”
                ON A.ID_NO = C.USCD
               AND C.DATA_DATE = I_DATADATE
               AND (C.BELONG_GROUP_ORG_CD IS NOT NULL OR
                   C.BELONG_GROUP_NAME IS NOT NULL)
            /*     INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO E --判定所属集团是否是同业客户（机构类型大类“不空 ” 才是同业客户）
             ON C.BELONG_GROUP_ORG_CD = E.USCD
            AND E.DATA_DATE = I_DATADATE
            AND E.ORG_TYPE_MCLS IS NOT NULL*/
            /* INNER JOIN TMP_ECIF_L_CUST_BILL_TY E --G1405结果表临时表 判定所属集团是否是同业客户
                ON C.BELONG_GROUP_ORG_CD = E.TYSHXYDM
               AND E.DATA_DATE = I_DATADATE
               AND E.FLAG = '1' */                       --康哥，20241008，去掉此条件
             WHERE A.CUST_NAM NOT IN ('中国银行股份有限公司',
                                      '中国农业银行股份有限公司',
                                      '中国工商银行股份有限公司',
                                      '中国建设银行股份有限公司',
                                      '交通银行股份有限公司',
                                      '国家开发银行',
                                      '中国农业发展银行',
                                      '中国进出口银行')
              AND  C.BELONG_GROUP_NAME <> '香港中央结算(代理人)有限公司' --康哥，20241008，过滤掉所属集团名称为'香港中央结算(代理人)有限公司'
             GROUP BY ORG_CODE,
                      C.BELONG_GROUP_NAME,
                      C.BELONG_GROUP_ORG_CD,
                      A.CUST_NAM,
                      A.ID_NO) A;

    COMMIT;

     --补充与G1405,与G1406集团同名的单一法人客户放进G1406

         INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1406
           (ORG_CODE,
            CUST_NAM,
            ID_NO,
            RISK_TOTAL,
            HAVE_RISK_SUBTOTAL,
            GENERAL_RISK_TOTAL,
            BUY_BACK,
            INTERBANK_BOND,
            POLICY_BANK,
            INTERBANK_RECEIPT,
            TRADE_ACCOUNT,
            POTENTIAL_RISK,
            PRIN_MINUS,
            DATA_DATE,
            CUST_TYPE,
            INTERBANK_FUNDING,
            INTERBANK_BORROWING,
            INTERBANK_LENDING,
            BELONG_GROUP_ORG_CD,
            BELONG_GROUP_NAME)
           SELECT A.ORG_CODE,
                  A.CUST_NAM,
                  A.ID_NO,
                  A.RISK_TOTAL,
                  A.HAVE_RISK_SUBTOTAL,
                  A.GENERAL_RISK_TOTAL,
                  A.BUY_BACK,
                  A.INTERBANK_BOND,
                  A.POLICY_BANK,
                  A.INTERBANK_RECEIPT,
                  A.TRADE_ACCOUNT,
                  A.POTENTIAL_RISK,
                  A.PRIN_MINUS,
                  I_DATADATE,
                  '同业集团客户' AS CUST_TYPE,
                  A.INTERBANK_FUNDING,
                  A.INTERBANK_BORROWING,
                  A.INTERBANK_LENDING,
                  A.ID_NO,    --如果存在那么集团证件就是它本身
                  A.CUST_NAM  --如果存在那么集团名就是它本身
             FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT A --处理G1405通过名称反找G1406集团名称同名数据，合并到G1406
            WHERE EXISTS (SELECT 1
                     FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1406 B --G1406
                     WHERE  A.CUST_NAM = B.BELONG_GROUP_NAME
                      AND A.ID_NO = B.BELONG_GROUP_ORG_CD
                      AND A.ORG_CODE = B.ORG_CODE) ;

         COMMIT;



    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1406集团下客户数量,更新集团客户标识';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     --按机构分组，集团下有一个客户的算单一客户，不算集团客户
    INSERT INTO CBRC_TMP_BUSINESS_GROUP_FLAG_G1406
      (BELONG_GROUP_NAME, AMOUNT, BELONG_GROUP_FLAG ,ORG_CODE)
      SELECT T.BELONG_GROUP_NAME, COUNT(*), '01' AS BELONG_GROUP_FLAG,ORG_CODE --01集团客户  02单一客户
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1406 T
       GROUP BY T.BELONG_GROUP_NAME,ORG_CODE
      HAVING COUNT(*) > 1;
   COMMIT;

   --(1)更新所属集团标识BELONG_GROUP_FLAG:01集团客户
   --(2)集团为 结尾:政府、委员会、财政局、财政厅、财政部，均不填报集团，而是填报在单一

    UPDATE CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1406 A
       SET BELONG_GROUP_FLAG =
           (SELECT CASE
                     WHEN (B.BELONG_GROUP_NAME LIKE '%政府'  OR
                          B.BELONG_GROUP_NAME LIKE '%委员会' OR
                          B.BELONG_GROUP_NAME LIKE '%财政局' OR
                          B.BELONG_GROUP_NAME LIKE '%财政厅' OR
                          B.BELONG_GROUP_NAME LIKE '%财政部') THEN
                      '02'
                     ELSE
                      B.BELONG_GROUP_FLAG
                   END AS BELONG_GROUP_FLAG
              FROM CBRC_TMP_BUSINESS_GROUP_FLAG_G1406 B
             WHERE A.BELONG_GROUP_NAME = B.BELONG_GROUP_NAME);
    COMMIT;
   --更新剩余所属集团标识BELONG_GROUP_FLAG:02单一客户
   UPDATE CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1406 A
       SET BELONG_GROUP_FLAG = '02'
     WHERE A.BELONG_GROUP_FLAG IS NULL;
    COMMIT;




    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1406数据机构处理最终表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


  INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE_G1406
    (ORG_CODE,
     SEQ_NO,
     CUST_NAM,
     ID_NO,
     RISK_TOTAL,
     HAVE_RISK_SUBTOTAL,
     GENERAL_RISK_TOTAL,
     BUY_BACK,
     INTERBANK_BOND,
     POLICY_BANK,
     INTERBANK_RECEIPT,
     TRADE_ACCOUNT,
     POTENTIAL_RISK,
     PRIN_MINUS,
     DATA_DATE,
     CUST_TYPE,
     REPORT_ITEM_ID,
     INTERBANK_FUNDING,
     INTERBANK_BORROWING,
     INTERBANK_LENDING)
    SELECT ORG_CODE,
           A.SEQ_NO,
           CUST_NAM,
           ID_NO,
           RISK_TOTAL,
           HAVE_RISK_SUBTOTAL,
           GENERAL_RISK_TOTAL,
           BUY_BACK,
           INTERBANK_BOND,
           POLICY_BANK,
           INTERBANK_RECEIPT,
           TRADE_ACCOUNT,
           POTENTIAL_RISK,
           PRIN_MINUS,
           I_DATADATE,
           CUST_TYPE,
           REPORT_ITEM_ID,
           INTERBANK_FUNDING,
           INTERBANK_BORROWING,
           INTERBANK_LENDING
      FROM (SELECT ORG_CODE,
                   ROW_NUMBER() OVER(PARTITION BY ORG_CODE ORDER BY SUM(RISK_TOTAL) DESC) AS SEQ_NO,
                   BELONG_GROUP_NAME AS CUST_NAM,
                   BELONG_GROUP_ORG_CD AS ID_NO,
                   SUM(RISK_TOTAL) AS RISK_TOTAL,
                   SUM(HAVE_RISK_SUBTOTAL) AS HAVE_RISK_SUBTOTAL,
                   SUM(GENERAL_RISK_TOTAL) AS GENERAL_RISK_TOTAL,
                   SUM(BUY_BACK) AS BUY_BACK,
                   SUM(INTERBANK_BOND) AS INTERBANK_BOND,
                   SUM(POLICY_BANK) AS POLICY_BANK,
                   SUM(INTERBANK_RECEIPT) AS INTERBANK_RECEIPT,
                   SUM(TRADE_ACCOUNT) AS TRADE_ACCOUNT,
                   SUM(POTENTIAL_RISK) AS POTENTIAL_RISK,
                   SUM(PRIN_MINUS) AS PRIN_MINUS,
                   CUST_TYPE,
                   SUM(INTERBANK_FUNDING) AS INTERBANK_FUNDING,
                   SUM(INTERBANK_BORROWING) AS INTERBANK_BORROWING,
                   SUM(INTERBANK_LENDING) AS INTERBANK_LENDING
              FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1406
             WHERE BELONG_GROUP_FLAG = '01' --01集团客户
             GROUP BY ORG_CODE,
                      BELONG_GROUP_NAME,
                      BELONG_GROUP_ORG_CD,
                      CUST_TYPE) A
      LEFT JOIN CBRC_G1405_CONFIG_RESULT_MAPPING B
        ON A.SEQ_NO = B.SEQ_NO
       AND B.SEQ_NO NOT LIKE 'II_%'
     WHERE A.SEQ_NO <= 30; --定长30户;

    COMMIT;

    --==================================================
    --G1406通过名称反找G1405同名数据，合并到G1406
    --==================================================

    --处理G1406通过名称反找G1405同名数据，合并到G1406
    --处理G1402时，G1406数据包含进来后，再从G1405中去掉打标识明细数据这两条

   

     INSERT INTO CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1406
       (ORG_CODE,
        SEQ_NO,
        CUST_NAM,
        ID_NO,
        RISK_TOTAL,
        HAVE_RISK_SUBTOTAL,
        GENERAL_RISK_TOTAL,
        BUY_BACK,
        INTERBANK_BOND,
        POLICY_BANK,
        INTERBANK_RECEIPT,
        TRADE_ACCOUNT,
        POTENTIAL_RISK,
        PRIN_MINUS,
        DATA_DATE,
        CUST_TYPE,
        REPORT_ITEM_ID,
        INTERBANK_FUNDING,
        INTERBANK_BORROWING,
        INTERBANK_LENDING)
       SELECT ORG_CODE,
              A.SEQ_NO,
              CUST_NAM,
              ID_NO,
              RISK_TOTAL,
              HAVE_RISK_SUBTOTAL,
              GENERAL_RISK_TOTAL,
              BUY_BACK,
              INTERBANK_BOND,
              POLICY_BANK,
              INTERBANK_RECEIPT,
              TRADE_ACCOUNT,
              POTENTIAL_RISK,
              PRIN_MINUS,
              I_DATADATE,
              CUST_TYPE,
              B.REPORT_ITEM_ID,
              INTERBANK_FUNDING,
              INTERBANK_BORROWING,
              INTERBANK_LENDING
         FROM (SELECT ORG_CODE,
                      ROW_NUMBER() OVER(PARTITION BY ORG_CODE ORDER BY SUM(RISK_TOTAL) DESC) AS SEQ_NO,
                      CUST_NAM,
                      ID_NO,
                      SUM(RISK_TOTAL) AS RISK_TOTAL,
                      SUM(HAVE_RISK_SUBTOTAL) AS HAVE_RISK_SUBTOTAL,
                      SUM(GENERAL_RISK_TOTAL) AS GENERAL_RISK_TOTAL,
                      SUM(BUY_BACK) AS BUY_BACK,
                      SUM(INTERBANK_BOND) AS INTERBANK_BOND,
                      SUM(POLICY_BANK) AS POLICY_BANK,
                      SUM(INTERBANK_RECEIPT) AS INTERBANK_RECEIPT,
                      SUM(TRADE_ACCOUNT) AS TRADE_ACCOUNT,
                      SUM(POTENTIAL_RISK) AS POTENTIAL_RISK,
                      SUM(PRIN_MINUS) AS PRIN_MINUS,
                      '同业集团客户' AS CUST_TYPE, --集团和单一客户，统一处理集团
                      SUM(INTERBANK_FUNDING) AS INTERBANK_FUNDING,
                      SUM(INTERBANK_BORROWING) AS INTERBANK_BORROWING,
                      SUM(INTERBANK_LENDING) AS INTERBANK_LENDING
                 FROM (
                       SELECT ORG_CODE,
                              CUST_NAM,
                              ID_NO,
                              RISK_TOTAL,
                              HAVE_RISK_SUBTOTAL,
                              GENERAL_RISK_TOTAL,
                              BUY_BACK,
                              INTERBANK_BOND,
                              POLICY_BANK,
                              INTERBANK_RECEIPT,
                              TRADE_ACCOUNT,
                              POTENTIAL_RISK,
                              PRIN_MINUS,
                              CUST_TYPE,
                              INTERBANK_FUNDING,
                              INTERBANK_BORROWING,
                              INTERBANK_LENDING
                         FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE_G1406
                     )
                GROUP BY ORG_CODE, CUST_NAM, ID_NO) A
         LEFT JOIN CBRC_G1405_CONFIG_RESULT_MAPPING B
           ON A.SEQ_NO = B.SEQ_NO
          AND B.SEQ_NO NOT LIKE 'II_%'
        WHERE A.SEQ_NO <= 30; --定长30户;

   COMMIT;
    --==================================================
    --G1406更新各机构配置结果
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1406更新各机构配置结果';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DECLARE
         V_SQL   VARCHAR2(1000); --金融市场部
         V_SQL_V VARCHAR2(1000);
         V_SQL1   VARCHAR2(1000);--投资银行部
         V_SQL_V1 VARCHAR2(1000);
         V_SQL2   VARCHAR2(1000);--009801总行清算中心(国际业务部) [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务
         V_SQL_V2 VARCHAR2(1000);
       BEGIN
       ----------------------金融市场部----------------------
         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1406_CONFIG_TMP F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL := 'UPDATE CBRC_G1406_CONFIG_TMP B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1406
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                    I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                    '009804' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                    I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL;
         COMMIT;
         END LOOP;

         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1406_CONFIG_TMP F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V := 'UPDATE CBRC_G1406_CONFIG_TMP B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1406
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                      '009804' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                      I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL_V;
          COMMIT;
         END LOOP;

      --------------同业金融部

        FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1406_CONFIG_TMP_TY F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL1 := 'UPDATE CBRC_G1406_CONFIG_TMP_TY B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1406
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                    I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                    '009820' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                    I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL1;
         COMMIT;
         END LOOP;

         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1406_CONFIG_TMP_TY F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V1 := 'UPDATE CBRC_G1406_CONFIG_TMP_TY B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1406
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                      '009820' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                      I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL_V1;
          COMMIT;
         END LOOP;
       --------------总行清算中心(国际业务部)

        FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1406_CONFIG_TMP_QS F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL2 := 'UPDATE CBRC_G1406_CONFIG_TMP_QS B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1406
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                    I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                    '009801' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                    I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL2;
         COMMIT;
         END LOOP;

         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1406_CONFIG_TMP_QS F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V2 := 'UPDATE CBRC_G1406_CONFIG_TMP_QS B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1406
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                      '009801' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                      I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL_V2;
          COMMIT;
         END LOOP;  
        
       END;

    --==================================================
    --G1406插入A_REPT_ITEM_VAL
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1406数据机构处理前30家进A_REPT_ITEM_VAL';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL,ITEM_VAL_V, FLAG,IS_TOTAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009804',
             'CBRC' AS SYS_NAM,
             'G1406' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             ITEM_VAL_V AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_G1406_CONFIG_TMP
       UNION ALL
       SELECT I_DATADATE AS DATA_DATE,
             '009820',
             'CBRC' AS SYS_NAM,
             'G1406' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             ITEM_VAL_V AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_G1406_CONFIG_TMP_TY;

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
   
END proc_cbrc_idx2_g1406;
