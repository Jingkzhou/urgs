CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g06_1(II_DATADATE IN STRING --跑批日期
                                           
                                               )
/******************************
  @author:wangjinbao
  @create-date:20230327
  @description:G06_1
  @modification history:
  
目标表：CBRC_A_REPT_ITEM_VAL
码值表：CBRC_G06_1_CONFIG_TMP 
集市表： CBRC_FAMS_CHB_MONTH_REPORT_DETAIL_SHEET1  --资管文件落地表
      SMTMODS_L_FIMM_PRODUCT
      SMTMODS_L_FIMM_PRODUCT_BAL
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
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  LAST_DATA   VARCHAR(8); --错误编码
  V_SYSTEM    VARCHAR2(30);
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    I_DATADATE := II_DATADATE;
    LAST_DATA  := TO_CHAR(ADD_MONTHS(DATE(II_DATADATE, 'YYYYMMDD'), -1),'YYYYMMDD');

    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('BSP_SP_CBRC_IDX2_G06_1');
    V_TAB_NAME  := 'G06_1';

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
       AND REP_NUM = 'G06_1';

    COMMIT;

    V_STEP_FLAG := 2;
    V_STEP_DESC := 'G06_1 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G06_1_CONFIG_TMP';

    DECLARE
      V_SQL VARCHAR2(1000);
    BEGIN
      FOR I IN (SELECT F.REPORT_ITEM_ID, F.REPORT_ITEM_NAME
                  FROM CBRC_G06_1_CONFIG_TMP F) LOOP
        V_SQL := 'UPDATE CBRC_G06_1_CONFIG_TMP B SET B.ITEM_VAL = (SELECT ' ||
                 I.REPORT_ITEM_NAME ||
                 ' FROM CBRC_FAMS_CHB_MONTH_REPORT_DETAIL_SHEET1
                            WHERE PROPERTYCODE = ' || '''' ||
                 I.REPORT_ITEM_ID || '''' || ' AND DATA_DATE = '|| '''' || I_DATADATE || '''' ||' ) WHERE B.REPORT_ITEM_ID=' || '''' ||
                 I.REPORT_ITEM_ID || '''' || ' AND B.REPORT_ITEM_NAME= ' || '''' ||
                 I.REPORT_ITEM_NAME || '''';
       --DBMS_OUTPUT.PUT_LINE(V_SQL);
        EXECUTE IMMEDIATE V_SQL;
        COMMIT;
      END LOOP;
    END;

  ------------------------------------------------------------------------------------------------------

    --JLBA202409260002_关于1104系统完善表外理财业务报表的相关需求
    --删除1.按募集方式划分（1.1 公募理财产品、1.2 私募理财产品、1.3 合 计）H列 本期银行端实现收益总额 不使用理财传过来的数据，单独取数
     DELETE FROM CBRC_G06_1_CONFIG_TMP T
     WHERE T.ITEM_NUM IN ('G06_1_1.1.H.2017',
                          'G06_1_1.2.H.2017',
                          'G06_1_1.3.H.2017',
                          'G06_1_2.1.H.2017',
                          'G06_1_2.2.H.2017',
                          'G06_1_2.3.H.2017',
                          'G06_1_2.4.H.2017',
                          'G06_1_2.5.H.2017');
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE,'009816','CBRC','G06_1','G06_1_1.1.H.2017',SUM(LJYHDSY),'2'
        FROM (SELECT T.PRODUCT_CODE AS PRODUCT_CODE,
                      CASE
                        WHEN SUBSTR(I_DATADATE,5,4) = '0131' THEN NVL(T.YHDSY, 0)
                        ELSE  NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0)
                      END AS LJYHDSY -- 累计实现银行端收益
                FROM SMTMODS_L_FIMM_PRODUCT_BAL T
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT A
                  ON A.PRODUCT_CODE = T.PRODUCT_CODE
                 AND A.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT_BAL T1
                  ON T.PRODUCT_CODE = T1.PRODUCT_CODE
                 AND T1.DATA_DATE = LAST_DATA
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.DATE_SOURCESD <> 'ZGXT'
                 AND A.COLLECT_TYP = '1' -- 募集方式 1：公募 2：私募
                 AND T.PRODUCT_CODE <> '60211401'
                 AND NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0) <> 0
              UNION ALL
              SELECT T.PRODUCT_CODE AS PRODUCT_CODE,
                     CASE
                        WHEN SUBSTR(I_DATADATE,5,4) = '0131' THEN NVL(T.YHDSY, 0)
                        ELSE  NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0)
                      END AS LJYHDSY -- 累计实现银行端收益
                FROM SMTMODS_L_FIMM_PRODUCT_BAL T
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT A
                  ON A.PRODUCT_CODE = T.PRODUCT_CODE
                 AND A.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT_BAL T1
                  ON T.PRODUCT_CODE = T1.PRODUCT_CODE
                 AND T1.DATA_DATE = LAST_DATA
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.DATE_SOURCESD <> 'ZGXT'
                 AND T.PRODUCT_CODE = '60211401' --固定取数在公募基金
                 AND NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0) <> 0);
     COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE,'009816','CBRC','G06_1','G06_1_1.2.H.2017',SUM(LJYHDSY),'2'
        FROM (SELECT T.PRODUCT_CODE AS PRODUCT_CODE,
                     NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0) AS LJYHDSY -- 累计实现银行端收益
                FROM SMTMODS_L_FIMM_PRODUCT_BAL T
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT A
                  ON A.PRODUCT_CODE = T.PRODUCT_CODE
                 AND A.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT_BAL T1
                  ON T.PRODUCT_CODE = T1.PRODUCT_CODE
                 AND T1.DATA_DATE = LAST_DATA
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.DATE_SOURCESD <> 'ZGXT'
                 AND A.COLLECT_TYP = '2' -- 募集方式 1：公募 2：私募
                 AND NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0) <> 0);
     COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE,'009816','CBRC','G06_1','G06_1_1.3.H.2017',SUM(ITEM_VAL),'2'
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM = '009816'
         AND T.ITEM_NUM IN ('G06_1_1.2.H.2017','G06_1_1.1.H.2017');
     COMMIT;

       -- 2.按投资性质划分  2.1 固定收益类  2.2 权益类   2.3 商品及金融衍生品类   2.4 混合类  本期银行端实现收益总额
   /* 理财产品类型 A 固定收益类 B 权益类  C 商品及金融衍生品类 D 混合类  E 表内*/
    -- 2.5合计=ROUND(业务状况表6021本期发生额贷方/10000,2)

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE,
             '009816',
             'CBRC',
             'G06_1',
             CASE
               WHEN PRODUCT_TYPE = 'A' THEN
                'G06_1_2.1.H.2017'
               WHEN PRODUCT_TYPE = 'B' THEN
                'G06_1_2.2.H.2017'
               WHEN PRODUCT_TYPE = 'C' THEN
                'G06_1_2.3.H.2017'
               WHEN PRODUCT_TYPE = 'D' THEN
                'G06_1_2.4.H.2017'
             END,
             SUM(LJYHDSY),
             '2'
        FROM (SELECT A.PRODUCT_TYPE,
                     T.PRODUCT_CODE AS PRODUCT_CODE,
                     CASE
                        WHEN SUBSTR(I_DATADATE,5,4) = '0131' THEN NVL(T.YHDSY, 0)
                        ELSE  NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0)
                      END AS LJYHDSY -- 累计实现银行端收益
                FROM SMTMODS_L_FIMM_PRODUCT_BAL T
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT A
                  ON A.PRODUCT_CODE = T.PRODUCT_CODE
                 AND A.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT_BAL T1
                  ON T.PRODUCT_CODE = T1.PRODUCT_CODE
                 AND T1.DATA_DATE = LAST_DATA
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.DATE_SOURCESD <> 'ZGXT'
                 AND T.PRODUCT_CODE <> '60211401'
                 AND NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0) <> 0
              UNION ALL
              SELECT 'A' AS PRODUCT_TYPE,
                     T.PRODUCT_CODE AS PRODUCT_CODE,
                     CASE
                        WHEN SUBSTR(I_DATADATE,5,4) = '0131' THEN NVL(T.YHDSY, 0)
                        ELSE  NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0)
                      END AS LJYHDSY -- 虚拟产品60211401累计实现银行端收益
                FROM SMTMODS_L_FIMM_PRODUCT_BAL T
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT A
                  ON A.PRODUCT_CODE = T.PRODUCT_CODE
                 AND A.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT_BAL T1
                  ON T.PRODUCT_CODE = T1.PRODUCT_CODE
                 AND T1.DATA_DATE = LAST_DATA
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.DATE_SOURCESD <> 'ZGXT'
                 AND T.PRODUCT_CODE = '60211401'
                 AND NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0) <> 0)
       GROUP BY CASE
                  WHEN PRODUCT_TYPE = 'A' THEN
                   'G06_1_2.1.H.2017'
                  WHEN PRODUCT_TYPE = 'B' THEN
                   'G06_1_2.2.H.2017'
                  WHEN PRODUCT_TYPE = 'C' THEN
                   'G06_1_2.3.H.2017'
                  WHEN PRODUCT_TYPE = 'D' THEN
                   'G06_1_2.4.H.2017'
                END;
       COMMIT;

      INSERT INTO CBRC_A_REPT_ITEM_VAL
        (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
        SELECT I_DATADATE,
               '009816',
               'CBRC',
               'G06_1',
               'G06_1_2.5.H.2017',
               SUM(ITEM_VAL),
               '2'
          FROM CBRC_A_REPT_ITEM_VAL T
         WHERE T.DATA_DATE = I_DATADATE
           AND T.ORG_NUM = '009816'
           AND T.ITEM_NUM IN ('G06_1_2.1.H.2017',
                              'G06_1_2.2.H.2017',
                              'G06_1_2.3.H.2017',
                              'G06_1_2.4.H.2017');
     COMMIT;

  ------------------------------------------------------------------------------------------------------

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             '009816',
             'CBRC' AS SYS_NAM,
             'G06_1' AS REP_NUM,
             ITEM_NUM AS ITEM_NUM,
             ITEM_VAL AS ITEM_VAL,
             '1' AS FLAG
        FROM CBRC_G06_1_CONFIG_TMP;

    COMMIT;

    V_STEP_FLAG := 3;
    V_STEP_DESC := 'G06_1 全部逻辑处理完成';
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
   
END proc_cbrc_idx2_g06_1