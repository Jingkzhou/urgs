CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g32(II_DATADATE IN STRING --跑批日期
)
/******************************
  @author:fubingyi
  @create-date:2015-09-22
  @description:G32
  @modification history:
  m0.20150919-fubingyi-G32
  m1.20221228 G32的资产负债口径从资产负债表M_GL_REPORT_DATA_STRG取数
  
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_PUB_DATA_COLLECT_G32
集市表：SMTMODS_L_PUBL_RATE
     SMTMODS_M_GL_REPORT_DATA_STRG
  *******************************/
 IS
  V_SCHEMA        VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE     VARCHAR(30); --当前储存过程名称
  V_TAB_NAME      VARCHAR(30); --目标表名
  I_DATADATE      STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE      VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_DATADATE_YEAR VARCHAR(10); --数据日期(字符型)YYYY
  D_DATADATE_CCY  STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID       INTEGER; --任务号
  V_STEP_DESC     VARCHAR(4000); --任务描述
  V_STEP_FLAG     INTEGER; --任务执行状态标识
  V_ERRORCODE     VARCHAR(20); --错误编码
  V_ERRORDESC     VARCHAR(280); --错误内容
  V_PER_NUM       VARCHAR(30); --报表编号
  II_STATUS       INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM        VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID       := 0;
    V_STEP_FLAG     := 0;
    V_STEP_DESC     := '参数初始化处理';
    V_PER_NUM       := 'G32';
    I_DATADATE      := II_DATADATE;
    V_DATADATE      := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');
    V_DATADATE_YEAR := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY');
    D_DATADATE_CCY  := I_DATADATE;
    V_SYSTEM        := 'CBRC';
    V_PROCEDURE     := UPPER('PROC_CBRC_IDX2_G32');

    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL
    WHERE DATA_DATE = I_DATADATE
          AND REP_NUM = V_PER_NUM
          AND SYS_NAM = 'CBRC'
          AND FLAG = '1'
          AND (ITEM_NUM LIKE '%A%' OR ITEM_NUM LIKE '%B%' ) ;--只删除即期资产即期负债指标
    COMMIT;
    --清除临时表数据

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_PUB_DATA_COLLECT_G32';

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --=============================================================
    --G32 'G32_1..A - G32_8..A'插入临时表
    --=============================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || ': G32_1..A - G32_8..A';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G32
      (ORG_NUM, --机构号
       ITEM_NUM, --报表类型
       ITEM_VAL --指标值
       )
      SELECT T.BIZ_ORG AS ORG_NUM, --机构号
            CASE
               WHEN T.CURR_CD = 'USD' THEN
                 'G32_1..A'
               WHEN T.CURR_CD = 'EUR' THEN
                 'G32_2..A'
               WHEN T.CURR_CD = 'JPY' THEN
                 'G32_3..A'
               WHEN T.CURR_CD = 'GBP' THEN
                 'G32_4..A'
               WHEN T.CURR_CD = 'HKD' THEN
                 'G32_5..A'
               WHEN T.CURR_CD = 'CHF' THEN
                 'G32_6..A'
               WHEN T.CURR_CD = 'AUD' THEN
                 'G32_7..A'
               WHEN T.CURR_CD = 'CAD' THEN
                 'G32_8..A'

             END AS ITEM_NUM, --指标号AS ITEM_NUM, --指标号
            SUM(T.DATA_ITEM_VAL * U.CCY_RATE) AS ITEM_VAL --指标值（折人民币）

       FROM SMTMODS_M_GL_REPORT_DATA_STRG T
      INNER JOIN SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE T.SYS = '99' --系统
        AND T.ACCT_DT = I_DATADATE
        AND T.FREQ = 'D' --频度
        AND T.REPORT_CD IN ('000001')
        AND T.DATA_ITEM_CD = '000001^D^36' --资产合计
        AND T.CURR_CD  IN ('USD', 'EUR', 'JPY', 'GBP', 'HKD', 'CHF', 'AUD', 'CAD')
       GROUP BY T.BIZ_ORG, CASE
               WHEN T.CURR_CD = 'USD' THEN
                 'G32_1..A'
               WHEN T.CURR_CD = 'EUR' THEN
                 'G32_2..A'
               WHEN T.CURR_CD = 'JPY' THEN
                 'G32_3..A'
               WHEN T.CURR_CD = 'GBP' THEN
                 'G32_4..A'
               WHEN T.CURR_CD = 'HKD' THEN
                 'G32_5..A'
               WHEN T.CURR_CD = 'CHF' THEN
                 'G32_6..A'
               WHEN T.CURR_CD = 'AUD' THEN
                 'G32_7..A'
               WHEN T.CURR_CD = 'CAD' THEN
                 'G32_8..A'

             END;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     --=============================================================
    --G32 'G32_9..A'插入临时表
    --=============================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || ': G32_9..A ';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     INSERT INTO CBRC_PUB_DATA_COLLECT_G32
      (ORG_NUM, --机构号
       ITEM_NUM, --报表类型
       ITEM_VAL --指标值
       )
     SELECT T.BIZ_ORG AS ORG_NUM, --机构号
            'G32_9..A'AS ITEM_NUM, --指标号AS ITEM_NUM, --指标号
            SUM(T.DATA_ITEM_VAL * U.CCY_RATE) AS ITEM_VAL --指标值（折人民币）

       FROM SMTMODS_M_GL_REPORT_DATA_STRG T
      INNER JOIN SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE T.SYS = '99' --系统
        AND T.ACCT_DT = I_DATADATE
        AND T.FREQ = 'D' --频度
        AND T.REPORT_CD IN ('000001')
        AND T.DATA_ITEM_CD = '000001^D^8' --贵金属
        AND T.CURR_CD  IN ( 'CNY')
        group by  T.BIZ_ORG;
        commit;
        V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);




    --=============================================================
    --G32 'G32_1..B - G32_8..B'插入临时表
    --=============================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || ': G32_1..B - G32_8..B';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G32
      (ORG_NUM, --机构号
       ITEM_NUM, --报表类型
       ITEM_VAL --指标值
       )
      SELECT T.BIZ_ORG AS ORG_NUM, --机构号
            CASE
               WHEN T.CURR_CD = 'USD' THEN
                 'G32_1..B'
               WHEN T.CURR_CD = 'EUR' THEN
                 'G32_2..B'
               WHEN T.CURR_CD = 'JPY' THEN
                 'G32_3..B'
               WHEN T.CURR_CD = 'GBP' THEN
                 'G32_4..B'
               WHEN T.CURR_CD = 'HKD' THEN
                 'G32_5..B'
               WHEN T.CURR_CD = 'CHF' THEN
                 'G32_6..B'
               WHEN T.CURR_CD = 'AUD' THEN
                 'G32_7..B'
               WHEN T.CURR_CD = 'CAD' THEN
                 'G32_8..B'

             END AS ITEM_NUM, --指标号AS ITEM_NUM, --指标号
            SUM(T.DATA_ITEM_VAL * U.CCY_RATE) AS ITEM_VAL --指标值（折人民币）

       FROM SMTMODS_M_GL_REPORT_DATA_STRG T
      INNER JOIN SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE T.SYS = '99' --系统
        AND T.ACCT_DT = I_DATADATE
        AND T.FREQ = 'D' --频度
        AND T.REPORT_CD IN ('000001')
        AND T.DATA_ITEM_CD = '000001^H^22' --负债合计
        AND T.CURR_CD  IN ('USD', 'EUR', 'JPY', 'GBP', 'HKD', 'CHF', 'AUD', 'CAD')
       GROUP BY T.BIZ_ORG, CASE
               WHEN T.CURR_CD = 'USD' THEN
                 'G32_1..B'
               WHEN T.CURR_CD = 'EUR' THEN
                 'G32_2..B'
               WHEN T.CURR_CD = 'JPY' THEN
                 'G32_3..B'
               WHEN T.CURR_CD = 'GBP' THEN
                 'G32_4..B'
               WHEN T.CURR_CD = 'HKD' THEN
                 'G32_5..B'
               WHEN T.CURR_CD = 'CHF' THEN
                 'G32_6..B'
               WHEN T.CURR_CD = 'AUD' THEN
                 'G32_7..B'
               WHEN T.CURR_CD = 'CAD' THEN
                 'G32_8..B'

             END;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    --=============================================================
    --G32 'G32_10..A'插入临时表
    --=============================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || ': G32_10..A G32_10..B';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G32
      (ORG_NUM, --机构号
       ITEM_NUM, --报表类型
       ITEM_VAL --指标值
       )
          SELECT ORG_NUM,
            ITEM_NUM,
            CASE
              WHEN SUM(ITEM_VAL) > 0 THEN
               SUM(ITEM_VAL)
              ELSE
               0
            END
       FROM (

             SELECT T.BIZ_ORG AS ORG_NUM, --机构号
                     CASE
                       WHEN DATA_ITEM_CD = '000001^D^36' THEN
                        'G32_10..A'
                       WHEN DATA_ITEM_CD = '000001^H^22' THEN
                        'G32_10..B'
                     END AS ITEM_NUM,
                     SUM(T.DATA_ITEM_VAL * U.CCY_RATE) AS ITEM_VAL --指标值（折人民币）

               FROM SMTMODS_M_GL_REPORT_DATA_STRG T
              INNER JOIN SMTMODS_L_PUBL_RATE U
                 ON U.CCY_DATE = I_DATADATE
                AND U.BASIC_CCY = T.CURR_CD --基准币种
                AND U.FORWARD_CCY = 'CNY' --折算币种
              WHERE T.SYS = '99' --系统
                AND T.ACCT_DT = I_DATADATE
                AND T.FREQ = 'D' --频度
                AND T.REPORT_CD IN ('000001')
                AND T.DATA_ITEM_CD IN ('000001^D^36', '000001^H^22')
                AND T.CURR_CD NOT IN ('USD','EUR','JPY','GBP','HKD','CHF','AUD','CAD','CNY')
              GROUP BY T.BIZ_ORG,
                        CASE
                          WHEN DATA_ITEM_CD = '000001^D^36' THEN
                           'G32_10..A'
                          WHEN DATA_ITEM_CD = '000001^H^22' THEN
                           'G32_10..B'
                        END)
      GROUP BY ORG_NUM, ITEM_NUM;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    --=============================================================
    --G32 'G32_11..A'插入临时表
    --=============================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := V_TAB_NAME || ': G32_11..A G32_11..B ';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_PUB_DATA_COLLECT_G32
      (ORG_NUM, --机构号
       ITEM_NUM, --报表类型
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
            ITEM_NUM,
            CASE
              WHEN SUM(ITEM_VAL) <= 0 THEN
               SUM(ITEM_VAL)
              ELSE
               0
            END
       FROM (

             SELECT T.BIZ_ORG AS ORG_NUM, --机构号
                     CASE
                       WHEN DATA_ITEM_CD = '000001^D^36' THEN
                        'G32_11..A'
                       WHEN DATA_ITEM_CD = '000001^H^22' THEN
                        'G32_11..B'
                     END AS ITEM_NUM,
                     SUM(T.DATA_ITEM_VAL * U.CCY_RATE) AS ITEM_VAL --指标值（折人民币）

               FROM SMTMODS_M_GL_REPORT_DATA_STRG T
              INNER JOIN SMTMODS_L_PUBL_RATE U
                 ON U.CCY_DATE = I_DATADATE
                AND U.BASIC_CCY = T.CURR_CD --基准币种
                AND U.FORWARD_CCY = 'CNY' --折算币种
              WHERE T.SYS = '99' --系统
                AND T.ACCT_DT = I_DATADATE
                AND T.FREQ = 'D' --频度
                AND T.REPORT_CD IN ('000001')
                AND T.DATA_ITEM_CD IN ('000001^D^36', '000001^H^22')
                AND T.CURR_CD NOT IN ('USD','EUR','JPY','GBP','HKD','CHF','AUD','CAD','CNY')
               GROUP BY T.BIZ_ORG,
                        CASE
                          WHEN DATA_ITEM_CD = '000001^D^36' THEN
                           'G32_11..A'
                          WHEN DATA_ITEM_CD = '000001^H^22' THEN
                           'G32_11..B'
                        END)
      GROUP BY ORG_NUM, ITEM_NUM;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --==================================================
    --汇总临时表值
    --==================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '汇总临时表值';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       IS_TOTAL
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_PER_NUM AS REP_NUM, --报表编号
             ITEM_NUM, --指标号
             SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
             '1' AS FLAG,
             'N' AS IS_TOTAL--不参与汇总
      FROM CBRC_PUB_DATA_COLLECT_G32 A
      WHERE A.ITEM_NUM IS NOT NULL
      GROUP BY ORG_NUM, --机构号
               ITEM_NUM; --报表类型

    COMMIT;

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
   
END proc_cbrc_idx2_g32