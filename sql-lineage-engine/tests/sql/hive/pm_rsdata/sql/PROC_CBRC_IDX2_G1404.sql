CREATE OR REPLACE PROCEDURE PROC_CBRC_IDX2_G1404(II_DATADATE  IN STRING --跑批日期
                                                   )
/******************************
  @AUTHOR:DJH
  @CREATE-DATE:20240909
  @DESCRIPTION:G1404  第IV部分：非同业集团客户及经济依存客户大额风险暴露情况表
  @MODIFICATION HISTORY:
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
    V_PER_NUM   := 'G1404';
    I_DATADATE  := II_DATADATE;
    V_DATADATE  := TO_CHAR(TO_DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');
    V_TAB_NAME  := 'G1404';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G1404');
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


     --取非同业集团客户。在G1403表基础上，取非同业集团客户，按照风险暴露总和的合计汇总排序；
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_BUSINESS_GROUP_FLAG_G1404';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1404';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE_G1404';
   -- EXECUTE IMMEDIATE 'TRUNCATE TABLE  TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1404';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1404'; -- G14 第III部分：非同业单一客户大额风险暴露情况表：非同业单一客户大额风险暴露情况表
    --CBRC_G1403_CONFIG_RESULT_MAPPING  共用配置表   G1404_CONFIG_TMP  报表映射指标配置表(金融市场)   G1404_CONFIG_TMP_TH 报表映射指标配置表(投资银行部)


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1404数据明细处理表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1404
      (ORG_CODE,
       CUST_NAM,
       ID_NO,
       FXBLHJ,
       BKHMFXBL,
       YBFXBLHJ,
       YBFX_GXDK,
       YBFX_ZQTZ,
       ZCGLCP,
       XTCP,
       FBBLC,
       ZQYZGCP,
       ZCZQHCP,
       JYZBFXBL,
       JYDSXYFX,
       QZFXBLHJ,
       YC,
       XYZ,
       BH,
       CN,
       QTFXBL,
       FXHS,
       DATA_DATE,
       CUST_TYPE,
       BELONG_GROUP_ORG_CD,
       BELONG_GROUP_NAME)
      SELECT ORG_CODE,
             CUST_NAM,
             ID_NO,
             FXBLHJ,
             BKHMFXBL,
             YBFXBLHJ,
             YBFX_GXDK,
             YBFX_ZQTZ,
             ZCGLCP,
             XTCP,
             FBBLC,
             ZQYZGCP,
             ZCZQHCP,
             JYZBFXBL,
             JYDSXYFX,
             QZFXBLHJ,
             YC,
             XYZ,
             BH,
             CN,
             QTFXBL,
             FXHS,
             I_DATADATE,
             CUST_TYPE,
             BELONG_GROUP_ORG_CD,
             BELONG_GROUP_NAME
        FROM (SELECT ORG_CODE,
                     CUST_NAM,
                     ID_NO,
                     SUM(FXBLHJ) AS FXBLHJ,
                     SUM(BKHMFXBL) AS BKHMFXBL,
                     SUM(YBFXBLHJ) AS YBFXBLHJ,
                     SUM(YBFX_GXDK) AS YBFX_GXDK,
                     SUM(YBFX_ZQTZ) AS YBFX_ZQTZ,
                     SUM(ZCGLCP) AS ZCGLCP,
                     SUM(XTCP) AS XTCP,
                     SUM(FBBLC) AS FBBLC,
                     SUM(ZQYZGCP) AS ZQYZGCP,
                     SUM(ZCZQHCP) AS ZCZQHCP,
                     SUM(JYZBFXBL) AS JYZBFXBL,
                     SUM(JYDSXYFX) AS JYDSXYFX,
                     SUM(QZFXBLHJ) AS QZFXBLHJ,
                     SUM(YC) AS YC,
                     SUM(XYZ) AS XYZ,
                     SUM(BH) AS BH,
                     SUM(CN) AS CN,
                     SUM(QTFXBL) AS QTFXBL,
                     SUM(FXHS) AS FXHS,
                     '非同业集团客户' AS CUST_TYPE,
                     C.BELONG_GROUP_NAME,
                     C.BELONG_GROUP_ORG_CD
                FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403 A
               INNER JOIN CBRC_TMP_L_CUST_EXTERNAL_INFO_G1403 C --客户外部信息表  判定所属集团组织机构代码  所属集团名称 “不空”
                  ON A.ID_NO = C.USCD
               --  AND C.DATA_DATE = I_DATADATE
                 AND (C.BELONG_GROUP_ORG_CD IS NOT NULL OR
                     C.BELONG_GROUP_NAME IS NOT NULL)
              /*   INNER JOIN SMTMODS.L_CUST_EXTERNAL_INFO E --判定所属集团是否是非同业客户（机构类型大类“空”  才是非同业客户）
               ON C.BELONG_GROUP_ORG_CD = E.USCD
              AND E.DATA_DATE = I_DATADATE
              AND E.ORG_TYPE_MCLS IS NULL*/
              /*  LEFT JOIN TMP_ECIF_L_CUST_BILL_TY_G1403 E --G1403结果表临时表 判定所属集团是否是同业客户
                  ON C.BELONG_GROUP_ORG_CD = E.TYSHXYDM
                 AND E.DATA_DATE = I_DATADATE
                 AND E.FLAG = '1'
               WHERE E.TYSHXYDM IS NULL*/     --康哥，20241008，去掉此条件
               GROUP BY ORG_CODE,
                        CUST_NAM,
                        ID_NO,
                        C.BELONG_GROUP_NAME,
                        C.BELONG_GROUP_ORG_CD) A;

     COMMIT;

       --补充与G1403,与G1403集团同名的单一法人客户放进G1404

      INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1404
        (ORG_CODE,
         CUST_NAM,
         ID_NO,
         FXBLHJ,
         BKHMFXBL,
         YBFXBLHJ,
         YBFX_GXDK,
         YBFX_ZQTZ,
         ZCGLCP,
         XTCP,
         FBBLC,
         ZQYZGCP,
         ZCZQHCP,
         JYZBFXBL,
         JYDSXYFX,
         QZFXBLHJ,
         YC,
         XYZ,
         BH,
         CN,
         QTFXBL,
         FXHS,
         DATA_DATE,
         CUST_TYPE,
         BELONG_GROUP_ORG_CD,
         BELONG_GROUP_NAME)
        SELECT ORG_CODE,
               CUST_NAM,
               ID_NO,
               FXBLHJ,
               BKHMFXBL,
               YBFXBLHJ,
               YBFX_GXDK,
               YBFX_ZQTZ,
               ZCGLCP,
               XTCP,
               FBBLC,
               ZQYZGCP,
               ZCZQHCP,
               JYZBFXBL,
               JYDSXYFX,
               QZFXBLHJ,
               YC,
               XYZ,
               BH,
               CN,
               QTFXBL,
               FXHS,
               I_DATADATE,
               '非同业集团客户' AS CUST_TYPE,
               ID_NO,  --如果存在那么集团证件就是它本身
               CUST_NAM  --如果存在那么集团名就是它本身
          FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1403 A --处理G1404通过名称反找G1403集团名称同名数据，合并到G1404
         WHERE EXISTS (SELECT 1
                  FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1404 B --G1404
                 WHERE A.CUST_NAM = B.BELONG_GROUP_NAME
                   AND A.ID_NO = B.BELONG_GROUP_ORG_CD
                   AND A.ORG_CODE = B.ORG_CODE);

         COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1404集团下客户数量,更新集团客户标识';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     --按机构分组，集团下有一个客户的算单一客户，不算集团客户
    INSERT INTO CBRC_TMP_BUSINESS_GROUP_FLAG_G1404
      (BELONG_GROUP_NAME, AMOUNT, BELONG_GROUP_FLAG ,ORG_CODE)
      SELECT T.BELONG_GROUP_NAME, COUNT(*), '01' AS BELONG_GROUP_FLAG ,ORG_CODE --01集团客户  02单一客户
        FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1404 T
       GROUP BY T.BELONG_GROUP_NAME ,ORG_CODE
      HAVING COUNT(*) > 1;
   COMMIT;

   --(1)更新所属集团标识BELONG_GROUP_FLAG:01集团客户
   --(2)集团为 结尾:政府、委员会、财政局、财政厅、财政部，均不填报集团，而是填报在单一
    UPDATE CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1404 A
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
              FROM CBRC_TMP_BUSINESS_GROUP_FLAG_G1404 B
             WHERE A.BELONG_GROUP_NAME = B.BELONG_GROUP_NAME);
    COMMIT;
   --更新所属集团标识BELONG_GROUP_FLAG:02单一客户
   UPDATE CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1404 A
       SET BELONG_GROUP_FLAG = '02'
     WHERE A.BELONG_GROUP_FLAG IS NULL;
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1404数据机构处理最终表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


     INSERT INTO CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE_G1404
       (ORG_CODE,
        SEQ_NO,
        CUST_NAM,
        ID_NO,
        FXBLHJ,
        BKHMFXBL,
        YBFXBLHJ,
        YBFX_GXDK,
        YBFX_ZQTZ,
        ZCGLCP,
        XTCP,
        FBBLC,
        ZQYZGCP,
        ZCZQHCP,
        JYZBFXBL,
        JYDSXYFX,
        QZFXBLHJ,
        YC,
        XYZ,
        BH,
        CN,
        QTFXBL,
        FXHS,
        DATA_DATE,
        CUST_TYPE,
        REPORT_ITEM_ID)
       SELECT ORG_CODE,
              A.SEQ_NO,
              CUST_NAM,
              ID_NO,
              FXBLHJ,
              BKHMFXBL,
              YBFXBLHJ,
              YBFX_GXDK,
              YBFX_ZQTZ,
              ZCGLCP,
              XTCP,
              FBBLC,
              ZQYZGCP,
              ZCZQHCP,
              JYZBFXBL,
              JYDSXYFX,
              QZFXBLHJ,
              YC,
              XYZ,
              BH,
              CN,
              QTFXBL,
              FXHS,
              I_DATADATE,
              CUST_TYPE,
              REPORT_ITEM_ID
         FROM (SELECT ORG_CODE,
                      ROW_NUMBER() OVER(PARTITION BY ORG_CODE ORDER BY SUM(FXBLHJ) DESC) AS SEQ_NO,
                      BELONG_GROUP_NAME AS CUST_NAM,
                      BELONG_GROUP_ORG_CD AS ID_NO,
                      SUM(FXBLHJ) AS FXBLHJ,
                      SUM(BKHMFXBL) AS BKHMFXBL,
                      SUM(YBFXBLHJ) AS YBFXBLHJ,
                      SUM(YBFX_GXDK) AS YBFX_GXDK,
                      SUM(YBFX_ZQTZ) AS YBFX_ZQTZ,
                      SUM(ZCGLCP) AS ZCGLCP,
                      SUM(XTCP) AS XTCP,
                      SUM(FBBLC) AS FBBLC,
                      SUM(ZQYZGCP) AS ZQYZGCP,
                      SUM(ZCZQHCP) AS ZCZQHCP,
                      SUM(JYZBFXBL) AS JYZBFXBL,
                      SUM(JYDSXYFX) AS JYDSXYFX,
                      SUM(QZFXBLHJ) AS QZFXBLHJ,
                      SUM(YC) AS YC,
                      SUM(XYZ) AS XYZ,
                      SUM(BH) AS BH,
                      SUM(CN) AS CN,
                      SUM(QTFXBL) AS QTFXBL,
                      SUM(FXHS) AS FXHS,
                      CUST_TYPE
                 FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_BEGIN_G1404
                 WHERE BELONG_GROUP_FLAG='01'  --01集团客户
                GROUP BY ORG_CODE,
                         BELONG_GROUP_NAME,
                         BELONG_GROUP_ORG_CD,
                         CUST_TYPE) A
         LEFT JOIN CBRC_G1403_CONFIG_RESULT_MAPPING B
           ON A.SEQ_NO = B.SEQ_NO
        WHERE A.SEQ_NO <= 70; --定长70户
    COMMIT;


     --==================================================
    --G1404通过名称反找G1403同名数据，合并到G1404
    --==================================================

    --处理G1404通过名称反找G1403同名数据，合并到G1404
    --处理G1402时，G1404数据包含进来后，再从G1403中去掉打标识明细数据这两条

   
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1404通过名称反找G1403同名数据，合并到G1404(汇总)';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     INSERT INTO CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1404
       (ORG_CODE,
        CUST_NAM,
        ID_NO,
        FXBLHJ,
        BKHMFXBL,
        YBFXBLHJ,
        YBFX_GXDK,
        YBFX_ZQTZ,
        ZCGLCP,
        XTCP,
        FBBLC,
        ZQYZGCP,
        ZCZQHCP,
        JYZBFXBL,
        JYDSXYFX,
        QZFXBLHJ,
        YC,
        XYZ,
        BH,
        CN,
        QTFXBL,
        FXHS,
        DATA_DATE,
        CUST_TYPE,
        REPORT_ITEM_ID)
       SELECT ORG_CODE,
              CUST_NAM,
              ID_NO,
              FXBLHJ,
              BKHMFXBL,
              YBFXBLHJ,
              YBFX_GXDK,
              YBFX_ZQTZ,
              ZCGLCP,
              XTCP,
              FBBLC,
              ZQYZGCP,
              ZCZQHCP,
              JYZBFXBL,
              JYDSXYFX,
              QZFXBLHJ,
              YC,
              XYZ,
              BH,
              CN,
              QTFXBL,
              FXHS,
              I_DATADATE,
              CUST_TYPE,
              B.REPORT_ITEM_ID
         FROM (SELECT ORG_CODE,
                      ROW_NUMBER() OVER(PARTITION BY ORG_CODE ORDER BY SUM(FXBLHJ) DESC) AS SEQ_NO,
                      CUST_NAM,
                      ID_NO,
                      SUM(FXBLHJ) AS FXBLHJ,
                      SUM(BKHMFXBL) AS BKHMFXBL,
                      SUM(YBFXBLHJ) AS YBFXBLHJ,
                      SUM(YBFX_GXDK) AS YBFX_GXDK,
                      SUM(YBFX_ZQTZ) AS YBFX_ZQTZ,
                      SUM(ZCGLCP) AS ZCGLCP,
                      SUM(XTCP) AS XTCP,
                      SUM(FBBLC) AS FBBLC,
                      SUM(ZQYZGCP) AS ZQYZGCP,
                      SUM(ZCZQHCP) AS ZCZQHCP,
                      SUM(JYZBFXBL) AS JYZBFXBL,
                      SUM(JYDSXYFX) AS JYDSXYFX,
                      SUM(QZFXBLHJ) AS QZFXBLHJ,
                      SUM(YC) AS YC,
                      SUM(XYZ) AS XYZ,
                      SUM(BH) AS BH,
                      SUM(CN) AS CN,
                      SUM(QTFXBL) AS QTFXBL,
                      SUM(FXHS) AS FXHS,
                      '非同业集团客户' AS CUST_TYPE --集团和单一客户，统一处理集团
                 FROM (
                       SELECT ORG_CODE,
                              CUST_NAM,
                              ID_NO,
                              FXBLHJ,
                              BKHMFXBL,
                              YBFXBLHJ,
                              YBFX_GXDK,
                              YBFX_ZQTZ,
                              ZCGLCP,
                              XTCP,
                              FBBLC,
                              ZQYZGCP,
                              ZCZQHCP,
                              JYZBFXBL,
                              JYDSXYFX,
                              QZFXBLHJ,
                              YC,
                              XYZ,
                              BH,
                              CN,
                              QTFXBL,
                              FXHS,
                              DATA_DATE,
                              CUST_TYPE
                         FROM CBRC_TMP_BUSINESS_TABLE_TYDYKH_MIDDLE_G1404
                        /*WHERE CUST_NAM NOT IN
                              (SELECT CUST_NAM
                                 FROM TMP_BUSINESS_TABLE_TYDYKH_RESULT_G1404)*/)
                GROUP BY ORG_CODE, CUST_NAM, ID_NO) A
         LEFT JOIN CBRC_G1403_CONFIG_RESULT_MAPPING B
           ON A.SEQ_NO = B.SEQ_NO
        WHERE A.SEQ_NO <= 70; --定长70户

   COMMIT;

    --==================================================
    --G1404更新各机构配置结果
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1404更新各机构配置结果';
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
       BEGIN
       ----------------------金融市场部----------------------
         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1404_CONFIG_TMP F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL := 'UPDATE CBRC_G1404_CONFIG_TMP B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1404
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
                     FROM CBRC_G1404_CONFIG_TMP F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V := 'UPDATE CBRC_G1404_CONFIG_TMP B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1404
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

      ----------------------投资银行部----------------------
      --只有华晨汽车集团控股有限公司  91210000744327380Q，特殊数据处理问题，报送在投资银行部009817，非金融市场部009804
        FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1404_CONFIG_TMP_TH F
                    WHERE F.REPORT_ITEM_NAME NOT IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP --补充数值型字段
           V_SQL1 := 'UPDATE CBRC_G1404_CONFIG_TMP_TH B SET B.ITEM_VAL = (SELECT ' ||
                    NVL(I.REPORT_ITEM_NAME, 0) ||
                    ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1404
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                    I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                    '009817' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                    I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                    I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL1;
         COMMIT;
         END LOOP;

         FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                     FROM CBRC_G1404_CONFIG_TMP_TH F
                    WHERE F.REPORT_ITEM_NAME IN
                          ('CUST_TYPE', 'CUST_NAM', 'ID_NO')) LOOP  --补充字符型字段
           V_SQL_V1 := 'UPDATE CBRC_G1404_CONFIG_TMP_TH B SET B.ITEM_VAL_V = (SELECT ' ||
                      NVL(I.REPORT_ITEM_NAME, 0) ||
                      ' FROM CBRC_BUSINESS_TABLE_TYDYKH_RESULT_G1404
                                WHERE REPORT_ITEM_ID = ' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = ' || '''' ||
                      I_DATADATE || '''' ||  ' AND ORG_CODE = ' || '''' ||
                      '009817' ||'''' || ' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                      I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                      I.REPORT_ITEM_NAME || '''';
           -- DBMS_OUTPUT.PUT_LINE(V_SQL);
           EXECUTE IMMEDIATE V_SQL_V1;
          COMMIT;
         END LOOP;
       END;


    --==================================================
    --G1404插入A_REPT_ITEM_VAL
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := 'G1404数据机构处理前70家进A_REPT_ITEM_VAL';
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
             'G1404' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             ITEM_VAL_V AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_G1404_CONFIG_TMP
       UNION ALL
       SELECT I_DATADATE AS DATA_DATE,
             '009817',
             'CBRC' AS SYS_NAM,
             'G1404' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             ITEM_VAL_V AS ITEM_VAL_V,
             '2' AS FLAG,
             'Y' AS IS_TOTAL
        FROM CBRC_G1404_CONFIG_TMP_TH;

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
   
END ;
