CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g26(II_DATADATE  IN STRING --跑批日期
                                                 )
/******************************
  @description:G26第I部分 优质流动性资产充足率
  @modification history:
  m0-ZJM-20231026-村镇特色报表
  [JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
  
  
目标表：CBRC_A_REPT_ITEM_VAL
依赖表：CBRC_S47_BAL_TMP
     CBRC_L_ACCT_DEPOSIT_TMP
视图表：SMTMODS_V_PUB_IDX_CK_GTGSHDQ
     SMTMODS_V_PUB_IDX_CK_GTGSHHQ
     SMTMODS_V_PUB_IDX_CK_GTGSHTZ
     SMTMODS_V_PUB_IDX_FINA_GL
集市表：SMTMODS_L_ACCT_DEPOSIT
     SMTMODS_L_CUST_C
     SMTMODS_L_FINA_GL
     SMTMODS_L_PUBL_RATE


  ********************************/
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

    V_PER_NUM      := 'G26';
    V_TAB_NAME     := 'CBRC_A_REPT_ITEM_VAL';
    I_DATADATE     := II_DATADATE;
    V_SYSTEM       := 'CBRC';
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_G26');
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

    /*  ###############此表使用了S47的宽表【S47_BAL_TMP】，跑批顺序请注意，如无法调顺序，把S47宽表逻辑拿到G26里################################  */

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- 1.1.1 现金
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
             'G26_1.1.1.A.2018' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1001'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --1.1.2 超额准备金
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
             'G26_1.1.2.A.2018' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '100302'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --2.1.1 储蓄存款  ---和 G01 保持一致
   INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT  I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'G26_2.1.1.A.2018' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT  I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.1.A.2018' AS ITEM_NUM,
                     SUM(CREDIT_BAL) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
                 AND ITEM_CD IN ('201101','22410102') --[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
               GROUP BY ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;
       COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL  -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
               SELECT  I_DATADATE AS DATA_DATE,
                      ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.1.A.2018' AS ITEM_NUM,
                     SUM(ACCT_BALANCE_RMB)  ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ  --个体工商户定期存款
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
               GROUP BY ORG_NUM;
               COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL  -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)

              SELECT  I_DATADATE AS DATA_DATE,
                      ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.1.A.2018' AS ITEM_NUM,
                     SUM(ACCT_BALANCE_RMB)  AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ  --个体工商户活期存款
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
               GROUP BY ORG_NUM;
               COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL  -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
              SELECT  I_DATADATE AS DATA_DATE,
                      ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.1.A.2018' AS ITEM_NUM,
                     SUM(ACCT_BALANCE_RMB)  AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
               GROUP BY ORG_NUM;
               COMMIT;
               
    
    INSERT INTO CBRC_A_REPT_ITEM_VAL
   (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
   SELECT 
    I_DATADATE AS DATA_DATE,
    T.ORG_NUM,
    'CBRC' AS SYS_NAM,
    'G01' AS REP_NUM,
    'G26_2.1.1.A.2018' AS ITEM_NUM,
    SUM(T.ACCT_BALANCE * B.CCY_RATE)  AS ITEM_VAL,
    '2' AS FLAG
     from SMTMODS_L_ACCT_DEPOSIT T
    INNER JOIN SMTMODS_L_CUST_C C
       ON T.DATA_DATE = C.DATA_DATE
      AND T.CUST_ID = C.CUST_ID
    INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
       ON T.DATA_DATE = B.DATA_DATE
      AND T.CURR_CD = B.BASIC_CCY
      AND B.FORWARD_CCY = 'CNY' --折人民币
    where c.deposit_custtype in ('13', '14')
      and t.gl_item_code IN ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
      AND T.ACCT_BALANCE > 0
      AND T.DATA_DATE = I_DATADATE
    GROUP BY T.ORG_NUM;            
               
     

    -- 2.1.2 对公存款  ---总数和 G01保持一致
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
           SELECT   I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.2.A.2018' AS ITEM_NUM,
                     SUM(CREDIT_BAL) AS ITEM_VAL,
                     '2' AS FLAG
                --FROM SMTMODS_L_FINA_GL
                FROM SMTMODS_V_PUB_IDX_FINA_GL
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
                 AND ITEM_CD IN ('201102','22410101','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款）调整为 一般单位活期存款]
               GROUP BY ORG_NUM   ;
         COMMIT;


    INSERT INTO CBRC_A_REPT_ITEM_VAL  -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
              SELECT  I_DATADATE AS DATA_DATE,
                      ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.2.A.2018' AS ITEM_NUM,
                     SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ  --个体工商户定期存款
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
               GROUP BY ORG_NUM ;
               COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL  -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
              SELECT 
                     I_DATADATE AS DATA_DATE,
                      ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.2.A.2018' AS ITEM_NUM,
                     SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ  --个体工商户活期存款
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
               GROUP BY ORG_NUM;
               COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL  -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
              SELECT  I_DATADATE AS DATA_DATE,
                      ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.2.A.2018' AS ITEM_NUM,
                     SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
               GROUP BY ORG_NUM;
               COMMIT;
               
        INSERT INTO CBRC_A_REPT_ITEM_VAL
   (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
   SELECT 
    I_DATADATE AS DATA_DATE,
    T.ORG_NUM,
    'CBRC' AS SYS_NAM,
    'G01' AS REP_NUM,
    'G26_2.1.2.A.2018' AS ITEM_NUM,
    SUM(T.ACCT_BALANCE * B.CCY_RATE)* -1  AS ITEM_VAL,
    '2' AS FLAG
     from SMTMODS_L_ACCT_DEPOSIT T
    INNER JOIN SMTMODS_L_CUST_C C
       ON T.DATA_DATE = C.DATA_DATE
      AND T.CUST_ID = C.CUST_ID
    INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
       ON T.DATA_DATE = B.DATA_DATE
      AND T.CURR_CD = B.BASIC_CCY
      AND B.FORWARD_CCY = 'CNY' --折人民币
    where c.deposit_custtype in ('13', '14')
      and t.gl_item_code IN ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
      AND T.ACCT_BALANCE > 0
      AND T.DATA_DATE = I_DATADATE
    GROUP BY T.ORG_NUM;              
      

    /*以下明细可以选择做一张临时表以供取数*/

    --2.1.2.1 小企业存款
    --企业部分
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
             'G26_2.1.2.1.A.2018' AS ITEM_NUM,
             SUM(A.ACCT_BALANCE_RMB) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_L_ACCT_DEPOSIT_TMP A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND B.CORP_SCALE IN ('S', 'T')
         AND B.DEPOSIT_CUSTTYPE = '01'
       GROUP BY A.ORG_NUM;
    COMMIT;



    --2.1.2.2 大中型企业存款
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
             'G26_2.1.2.2.A.2018' AS ITEM_NUM,
             SUM(A.ACCT_BALANCE_RMB) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_L_ACCT_DEPOSIT_TMP A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND B.CORP_SCALE IN ('B', 'M')
         AND B.DEPOSIT_CUSTTYPE = '01'
       GROUP BY A.ORG_NUM;
    COMMIT;

    -- 2.2.1.1 结算目的
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
             'G26_2.2.1.1.A.2018' AS ITEM_NUM,
             A.CREDIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('20120101', '20120201')
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --2.2.1.2 融资目的
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
             'G26_2.2.1.2.A.2018' AS ITEM_NUM,
             A.CREDIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('20120103')
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --2.4 向央行借款
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
             'G26_2.4.A.2018' AS ITEM_NUM,
             A.CREDIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('2004')
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    -- 2.5.3 保函和信用证
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
             'G26_2.5.3.A.2018' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('70400101')
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --3.1.1 零售及小企业
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
             'G26_3.1.1.A.2018' AS ITEM_NUM,
             SUM(A.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --使用S47的宽表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.LOAN_GRADE_CD IN ('1', '2')
         AND A.CUST_TYP = '2'
         AND A.ACCT_TYP NOT LIKE '03%'
         AND A.MATURITY_DT <= (I_DATADATE + 30)
         AND A.MATURITY_DT >= (I_DATADATE - 30)
       GROUP BY A.ORG_NUM;
    COMMIT;

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
             'G26_3.1.1.A.2018' AS ITEM_NUM,
             SUM(A.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --使用S47的宽表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.LOAN_GRADE_CD IN ('1', '2')
         AND A.CUST_TYP = '1'
         AND A.CORP_SCALE IN ('S', 'T')
         AND A.ACCT_TYP NOT LIKE '03%'
         AND A.MATURITY_DT <= (I_DATADATE + 30)
         AND A.MATURITY_DT >= (I_DATADATE - 30)
       GROUP BY A.ORG_NUM;
    COMMIT;

    --3.1.2 大中型企业
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
             'G26_3.1.2.A.2018' AS ITEM_NUM,
             SUM(A.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --使用S47的宽表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.LOAN_GRADE_CD IN ('1', '2')
         AND A.CUST_TYP = '1'
         AND A.CORP_SCALE IN ('B', 'M')
         AND A.ACCT_TYP NOT LIKE '03%'
         AND A.MATURITY_DT <= (I_DATADATE + 30)
         AND A.MATURITY_DT >= (I_DATADATE - 30)
       GROUP BY A.ORG_NUM;
    COMMIT;

    --3.1.3 票据贴现

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
             'G26_3.1.3.A.2018' AS ITEM_NUM,
             SUM(A.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S47_BAL_TMP A --使用S47的宽表
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
         AND A.LOAN_GRADE_CD IN ('1', '2')
         AND A.ACCT_TYP LIKE '03%'
         AND A.MATURITY_DT <= (I_DATADATE + 30)
         AND A.MATURITY_DT >= (I_DATADATE - 30)
       GROUP BY A.ORG_NUM;
    COMMIT;

    --   3.2.1.1 结算目的
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
             'G26_3.2.1.1.A.2018' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('10110101', '10110201')
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    --  3.2.1.2 融资目的
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
             'G26_3.2.1.2.A.2018' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('10110103')
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
   
END proc_cbrc_idx2_g26