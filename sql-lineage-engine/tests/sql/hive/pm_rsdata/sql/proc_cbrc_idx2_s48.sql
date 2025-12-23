CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s48(II_DATADATE  IN STRING --跑批日期
                                                 )
/******************************
  @description:S48农村中小金融机构非信贷资产五级分类统计表
  @modification history:
  m0-ZJM-20231026-村镇特色报表
  
目标表：CBRC_A_REPT_ITEM_VAL
集市表：SMTMODS_L_FINA_GL

  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  V_PER_NUM      VARCHAR(30); --报表编号
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    V_PER_NUM      := 'S48';
    V_TAB_NAME     := 'CBRC_A_REPT_ITEM_VAL';
    I_DATADATE     := II_DATADATE;
    V_SYSTEM       := 'CBRC';
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_S48');
    D_DATADATE_CCY := I_DATADATE;

    V_STEP_FLAG := 1;
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
       AND FLAG = '2';
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --1.现金
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S48_1..C' AS ITEM_NUM,
             A.CREDIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '4001'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --3.存放中央银行款项
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S48_3..C' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('100301', '100302')
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --4.存放同业款项（含存出保证金）

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S48_4..C' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1011'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --8.1.其中：应收利息
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S48_8.1.C' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1132'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    -- 8.2.其他应收款
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S48_8.2.C' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1221'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --10.固定资产净值
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S48_10..C' AS ITEM_NUM,
             SUM(BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.DEBIT_BAL AS BAL
                FROM SMTMODS_L_FINA_GL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ITEM_CD = '1601'
                 AND A.CURR_CD = 'BWB'
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
              UNION ALL
              SELECT A.ORG_NUM, -A.CREDIT_BAL AS BAL
                FROM SMTMODS_L_FINA_GL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ITEM_CD = '1602'
                 AND A.CURR_CD = 'BWB'
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')) T
       GROUP BY T.ORG_NUM;
    COMMIT;

    --11.固定资产清理
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S48_11..C' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1606'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;
    --   12.在建工程
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S48_12..C' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1604'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    -- 14.1.其中：房屋及建筑物
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S48_14.1.C' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '144101'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --14.2.土地使用权
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S48_14.2.C' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '144102'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --14.3.交通运输工具
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S48_14.3.C' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '144103'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --  14.4.其他抵债资产
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S48_14.4.C' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('144104', '144105', '144106', '144199')
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --16.递延资产
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S48_14.4.C' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('1801', '1811')
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    

  V_STEP_ID   := V_STEP_ID+1;
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
   
END proc_cbrc_idx2_s48