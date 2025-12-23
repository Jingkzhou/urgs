CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_s46(II_DATADATE  IN STRING --跑批日期
                                                               )
/******************************
  @description:S46农村中小银行机构补充数据表
  @modification history:
  m0-ZJM-20231027-村镇特色报表
  m1-shiyu-20240305 修改内容5.1没数据，7.21加活期，7.3.4改为按本年
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：
CBRC_S46_DEPOSIT_TMP
CBRC_S46_L_TRAN_TX
CBRC_S46_DEPOSIT_TMP
CBRC_S46_L_TRAN_TX
CBRC_S46_TMP_BZJ_MATUR_DATE
CBRC_S46_TMP_BZJ_O_ACCT_NUM
CBRC_S46_TMP_SECURITY_OBS_LOAN
CBRC_S46_TMP_SECURITY_RESULT
依赖表：CBRC_S47_BAL_TMP
集市表：SMTMODS_L_ACCT_DEPOSIT
SMTMODS_L_ACCT_LOAN
SMTMODS_L_ACCT_OBS_LOAN
SMTMODS_L_CUST_ALL
SMTMODS_L_CUST_C
SMTMODS_L_CUST_P
SMTMODS_L_PUBL_ORG_BRA
SMTMODS_L_PUBL_RATE
SMTMODS_L_TRAN_TX

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

    V_PER_NUM      := 'S46';
    V_TAB_NAME     := 'CBRC_A_REPT_ITEM_VAL';
    I_DATADATE     := II_DATADATE;
    V_SYSTEM       := 'CBRC';
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_S46');
    D_DATADATE_CCY := I_DATADATE;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND REP_NUM = V_PER_NUM
       AND SYS_NAM = 'CBRC'
       AND FLAG = '2';
    COMMIT;

    /*  ###############此表使用了S47的宽表【S47_BAL_TMP】，跑批顺序请注意，如无法调顺序，把S47宽表逻辑拿到G26里################################  */
    --处理存款保证金业务
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S46_TMP_BZJ_O_ACCT_NUM'; --保证金账号按账户分组数据处理
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S46_TMP_BZJ_MATUR_DATE'; --保证金账号到期日数据处理
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S46_TMP_SECURITY_OBS_LOAN'; --原业务及保证金账户临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S46_TMP_SECURITY_RESULT'; --保证金最终处理结果
    V_STEP_FLAG := 1;
    V_STEP_DESC := '加工保证金存款基础业务明细数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

    --取保证金账户不唯一数据
    INSERT INTO CBRC_S46_TMP_BZJ_O_ACCT_NUM
      (O_ACCT_NUM, SHULIANG)
      SELECT O_ACCT_NUM, COUNT(*) SHULIANG
        FROM (SELECT O_ACCT_NUM,
                     D.GL_ITEM_CODE,
                     D.CUST_ID,
                     D.ACCT_NUM,
                     D.ORG_NUM,
                     D.CURR_CD,
                     D.MATUR_DATE,
                     D.ACCT_BALANCE * T2.CCY_RATE
                FROM SMTMODS_L_ACCT_DEPOSIT D
                LEFT JOIN SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = D.CURR_CD --基准币种
                 AND T2.FORWARD_CCY = 'CNY'
               WHERE D.DATA_DATE = I_DATADATE
                 AND D.ACCT_BALANCE > 0
                 AND D.GL_ITEM_CODE IN ('20110114', '20110115', '20110209', '20110210'))
       GROUP BY O_ACCT_NUM
      HAVING COUNT(*) > 1;

    COMMIT;
    --DEPOSIT_NUM 不同的两个账户，如果到期日也不同那么取最新
    INSERT INTO CBRC_S46_TMP_BZJ_MATUR_DATE
      (O_ACCT_NUM, MATUR_DATE, RN)
      SELECT *
        FROM (SELECT D.O_ACCT_NUM,
                     D.MATUR_DATE,
                     ROW_NUMBER() OVER(PARTITION BY D.O_ACCT_NUM ORDER BY D.MATUR_DATE DESC) AS RN
                FROM SMTMODS_L_ACCT_DEPOSIT D
               INNER JOIN CBRC_S46_TMP_BZJ_O_ACCT_NUM K
                  ON D.O_ACCT_NUM = K.O_ACCT_NUM
                LEFT JOIN SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = D.CURR_CD --基准币种
                 AND T2.FORWARD_CCY = 'CNY'
               WHERE D.DATA_DATE = I_DATADATE
                 AND D.ACCT_BALANCE > 0
                 AND D.GL_ITEM_CODE IN ('20110114', '20110115', '20110209', '20110210')) T
       WHERE T.RN = 1;
    COMMIT;
    --保证金数据处理，如果保证金可以关联原业务，那么按照原业务划分期限，找不到原业务按照保证金本身划分期限
    --存款，贷款，保证金业务币种需要转换后再处理

    INSERT INTO CBRC_S46_TMP_SECURITY_OBS_LOAN
      (LOAN_NUM, SECURITY_ACCT_NUM, MATURITY_DT, DRAWDOWN_AMT, SECURITY_BALANCE, SECURITY_RATE, ITEM_CD, ORG_NUM, CURR_CD)
    --取原业务及保证金金额
      SELECT T.LOAN_NUM,
             T.SECURITY_ACCT_NUM,
             T.ACTUAL_MATURITY_DT AS MATURITY_DT,
             T.DRAWDOWN_AMT,
             T.DRAWDOWN_AMT * T.SECURITY_RATE * T2.CCY_RATE SECURITY_AMT, --放款金额*保证金比例
             T.SECURITY_RATE,
             T.ITEM_CD,
             T.ORG_NUM,
             T.CURR_CD
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T.CURR_CD --基准币种
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.SECURITY_ACCT_NUM IS NOT NULL
         AND T.ACTUAL_MATURITY_DT > I_DATADATE
         AND T.SECURITY_RATE > 0
      UNION
      SELECT O.ACCT_NUM LOAN_NUM,
             O.SECURITY_ACCT_NUM,
             O.END_DT AS MATURITY_DT,
             O.BALANCE AS DRAWDOWN_AMT,
             O.BALANCE * O.SECURITY_RATE * T2.CCY_RATE SECURITY_AMT,
             O.SECURITY_RATE,
             O.GL_ITEM_CODE,
             O.ORG_NUM,
             O.CURR_CD
        FROM SMTMODS_L_ACCT_OBS_LOAN O
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = O.CURR_CD --基准币种
         AND T2.FORWARD_CCY = 'CNY'
       WHERE O.DATA_DATE = I_DATADATE
         AND END_DT > I_DATADATE
         AND O.SECURITY_ACCT_NUM IS NOT NULL
         AND O.SECURITY_RATE > 0;
    COMMIT;

    --保证金最终处理开始

    INSERT INTO CBRC_S46_TMP_SECURITY_RESULT
      (ACCT_NUM, SECURITY_ACCT_NUM, MATURITY_DT, SECURITY_BALANCE, ITEM_CD, SOURCE, ORG_NUM, CURR_CD, LOAN_NUM, CUST_ID)
      SELECT M.ACCT_NUM, --保证金账号
             L.SECURITY_ACCT_NUM,
             L.MATURITY_DT, --原业务到期日
             L.SECURITY_BALANCE,
             M.GL_ITEM_CODE,
             '原业务保证金金额小于保证金账号余额',
             M.ORG_NUM,
             M.CURR_CD, --存款币种
             L.LOAN_NUM, --原业务账号
             M.CUST_ID
        FROM CBRC_S46_TMP_SECURITY_OBS_LOAN L
       INNER JOIN (SELECT 
                    T.SECURITY_ACCT_NUM, D.ACCT_NUM, D.ORG_NUM, D.CUST_ID, D.GL_ITEM_CODE, D.CURR_CD
                     FROM (SELECT T.SECURITY_ACCT_NUM, SUM(T.SECURITY_BALANCE) ACCT_BALANCE
                             FROM CBRC_S46_TMP_SECURITY_OBS_LOAN T
                            GROUP BY T.SECURITY_ACCT_NUM) T
                    INNER JOIN (SELECT D.O_ACCT_NUM,
                                      D.GL_ITEM_CODE,
                                      D.CUST_ID,
                                      D.ACCT_NUM,
                                      D.ORG_NUM,
                                      D.CURR_CD,
                                      SUM(D.ACCT_BALANCE * T2.CCY_RATE) AS ACCT_BALANCE
                                 FROM SMTMODS_L_ACCT_DEPOSIT D
                                 LEFT JOIN SMTMODS_L_PUBL_RATE T2
                                   ON T2.DATA_DATE = I_DATADATE
                                  AND T2.BASIC_CCY = D.CURR_CD --基准币种
                                  AND T2.FORWARD_CCY = 'CNY'
                                WHERE D.DATA_DATE = I_DATADATE
                                  AND D.ACCT_BALANCE > 0
                                  AND D.GL_ITEM_CODE IN ('20110114', '20110115', '20110209', '20110210')
                                GROUP BY D.O_ACCT_NUM, D.GL_ITEM_CODE, D.CUST_ID, D.ACCT_NUM, D.ORG_NUM, D.CURR_CD) D
                       ON T.SECURITY_ACCT_NUM = D.O_ACCT_NUM
                    WHERE T.ACCT_BALANCE <= D.ACCT_BALANCE) M --可能存在外币数据，存款 |(原业务)表外、贷款折币后比较
          ON L.SECURITY_ACCT_NUM = M.SECURITY_ACCT_NUM;
    COMMIT;

    INSERT INTO CBRC_S46_TMP_SECURITY_RESULT
      (ACCT_NUM, SECURITY_ACCT_NUM, MATURITY_DT, SECURITY_BALANCE, ITEM_CD, SOURCE, ORG_NUM, CURR_CD, CUST_ID)
      SELECT 
       D.ACCT_NUM,
       T.SECURITY_ACCT_NUM,
       D.MATUR_DATE,
       D.ACCT_BALANCE - T.SECURITY_BALANCE SECURITY_BALANCE,
       D.GL_ITEM_CODE,
       '保证金关联原业务剩余部分',
       D.ORG_NUM,
       D.CURR_CD,
       D.CUST_ID
        FROM (SELECT R.SECURITY_ACCT_NUM, SUM(R.SECURITY_BALANCE) SECURITY_BALANCE
                FROM CBRC_S46_TMP_SECURITY_RESULT R
               GROUP BY R.SECURITY_ACCT_NUM) T
       INNER JOIN (SELECT D.O_ACCT_NUM,
                          D.GL_ITEM_CODE,
                          D.CUST_ID,
                          D.ACCT_NUM,
                          D.ORG_NUM,
                          D.CURR_CD,
                          D.MATUR_DATE,
                          SUM(D.ACCT_BALANCE * T2.CCY_RATE) AS ACCT_BALANCE
                     FROM SMTMODS_L_ACCT_DEPOSIT D
                     LEFT JOIN SMTMODS_L_PUBL_RATE T2
                       ON T2.DATA_DATE = I_DATADATE
                      AND T2.BASIC_CCY = D.CURR_CD --基准币种
                      AND T2.FORWARD_CCY = 'CNY'
                    WHERE D.DATA_DATE = I_DATADATE
                      AND D.ACCT_BALANCE > 0
                      AND D.GL_ITEM_CODE IN ('20110114', '20110115', '20110209', '20110210')
                      AND D.O_ACCT_NUM NOT IN (SELECT O_ACCT_NUM FROM CBRC_S46_TMP_BZJ_O_ACCT_NUM)
                    GROUP BY D.O_ACCT_NUM, D.GL_ITEM_CODE, D.CUST_ID, D.ACCT_NUM, D.ORG_NUM, D.CURR_CD, D.MATUR_DATE
                   UNION ALL --特殊处理
                   SELECT T1.O_ACCT_NUM,
                          T1.GL_ITEM_CODE,
                          T1.CUST_ID,
                          T1.ACCT_NUM,
                          T1.ORG_NUM,
                          T1.CURR_CD,
                          T3.MATUR_DATE,
                          ACCT_BALANCE
                     FROM (SELECT D.O_ACCT_NUM,
                                  D.GL_ITEM_CODE,
                                  D.CUST_ID,
                                  D.ACCT_NUM,
                                  D.ORG_NUM,
                                  D.CURR_CD,
                                  SUM(D.ACCT_BALANCE * T2.CCY_RATE) AS ACCT_BALANCE
                             FROM SMTMODS_L_ACCT_DEPOSIT D
                             LEFT JOIN SMTMODS_L_PUBL_RATE T2
                               ON T2.DATA_DATE = I_DATADATE
                              AND T2.BASIC_CCY = D.CURR_CD --基准币种
                              AND T2.FORWARD_CCY = 'CNY'
                            WHERE D.DATA_DATE = I_DATADATE
                              AND D.ACCT_BALANCE > 0
                              AND D.GL_ITEM_CODE IN ('20110114', '20110115', '20110209', '20110210')
                              AND D.O_ACCT_NUM IN (SELECT O_ACCT_NUM FROM CBRC_S46_TMP_BZJ_O_ACCT_NUM)
                            GROUP BY D.O_ACCT_NUM, D.GL_ITEM_CODE, D.CUST_ID, D.ACCT_NUM, D.ORG_NUM, D.CURR_CD) T1
                     LEFT JOIN CBRC_S46_TMP_BZJ_MATUR_DATE T3 --如果两笔账户有不到到期日期，那么取最新的
                       ON T1.O_ACCT_NUM = T3.O_ACCT_NUM) D
          ON T.SECURITY_ACCT_NUM = D.O_ACCT_NUM
       WHERE D.ACCT_BALANCE - T.SECURITY_BALANCE > 0;
    COMMIT;

    INSERT INTO CBRC_S46_TMP_SECURITY_RESULT
      (ACCT_NUM, SECURITY_ACCT_NUM, MATURITY_DT, SECURITY_BALANCE, ITEM_CD, SOURCE, ORG_NUM, CURR_CD, CUST_ID)
      SELECT 
       D.ACCT_NUM,
       D.O_ACCT_NUM,
       D.MATUR_DATE,
       D.ACCT_BALANCE,
       D.GL_ITEM_CODE,
       '原业务保证金大于保证金账号余额，取保证金账号余额',
       D.ORG_NUM,
       D.CURR_CD,
       D.CUST_ID
        FROM (SELECT T.SECURITY_ACCT_NUM, SUM(T.SECURITY_BALANCE) ACCT_BALANCE
                FROM CBRC_S46_TMP_SECURITY_OBS_LOAN T
               GROUP BY T.SECURITY_ACCT_NUM) T
       INNER JOIN (SELECT D.O_ACCT_NUM,
                          D.GL_ITEM_CODE,
                          D.CUST_ID,
                          D.ACCT_NUM,
                          D.ORG_NUM,
                          D.CURR_CD,
                          D.MATUR_DATE,
                          SUM(D.ACCT_BALANCE * T2.CCY_RATE) AS ACCT_BALANCE
                     FROM SMTMODS_L_ACCT_DEPOSIT D
                     LEFT JOIN SMTMODS_L_PUBL_RATE T2
                       ON T2.DATA_DATE = I_DATADATE
                      AND T2.BASIC_CCY = D.CURR_CD --基准币种
                      AND T2.FORWARD_CCY = 'CNY'
                    WHERE D.DATA_DATE = I_DATADATE
                      AND D.ACCT_BALANCE > 0
                      AND D.GL_ITEM_CODE IN ('20110114', '20110115', '20110209', '20110210')
                      AND D.O_ACCT_NUM NOT IN (SELECT O_ACCT_NUM FROM CBRC_S46_TMP_BZJ_O_ACCT_NUM)
                    GROUP BY D.O_ACCT_NUM, D.GL_ITEM_CODE, D.CUST_ID, D.ACCT_NUM, D.ORG_NUM, D.CURR_CD, D.MATUR_DATE
                   UNION ALL -- 特殊处理
                   SELECT T1.O_ACCT_NUM,
                          T1.GL_ITEM_CODE,
                          T1.CUST_ID,
                          T1.ACCT_NUM,
                          T1.ORG_NUM,
                          T1.CURR_CD,
                          T3.MATUR_DATE,
                          ACCT_BALANCE
                     FROM (SELECT D.O_ACCT_NUM,
                                  D.GL_ITEM_CODE,
                                  D.CUST_ID,
                                  D.ACCT_NUM,
                                  D.ORG_NUM,
                                  D.CURR_CD,
                                  SUM(D.ACCT_BALANCE * T2.CCY_RATE) AS ACCT_BALANCE
                             FROM SMTMODS_L_ACCT_DEPOSIT D
                             LEFT JOIN SMTMODS_L_PUBL_RATE T2
                               ON T2.DATA_DATE = I_DATADATE
                              AND T2.BASIC_CCY = D.CURR_CD --基准币种
                              AND T2.FORWARD_CCY = 'CNY'
                            WHERE D.DATA_DATE = I_DATADATE
                              AND D.ACCT_BALANCE > 0
                              AND D.GL_ITEM_CODE IN ('20110114', '20110115', '20110209', '20110210')
                              AND D.O_ACCT_NUM IN (SELECT O_ACCT_NUM FROM CBRC_S46_TMP_BZJ_O_ACCT_NUM)
                            GROUP BY D.O_ACCT_NUM, D.GL_ITEM_CODE, D.CUST_ID, D.ACCT_NUM, D.ORG_NUM, D.CURR_CD) T1
                     LEFT JOIN CBRC_S46_TMP_BZJ_MATUR_DATE T3 --如果两笔账户有不到到期日期，那么取最新的
                       ON T1.O_ACCT_NUM = T3.O_ACCT_NUM) D
          ON T.SECURITY_ACCT_NUM = D.O_ACCT_NUM
       WHERE T.ACCT_BALANCE > D.ACCT_BALANCE;

    COMMIT;

    INSERT INTO CBRC_S46_TMP_SECURITY_RESULT
      (ACCT_NUM, SECURITY_ACCT_NUM, MATURITY_DT, SECURITY_BALANCE, ITEM_CD, SOURCE, ORG_NUM, CURR_CD, CUST_ID)
      SELECT 
       D.ACCT_NUM,
       D.O_ACCT_NUM,
       D.MATUR_DATE,
       D.ACCT_BALANCE * T2.CCY_RATE,
       D.GL_ITEM_CODE,
       '关联不上原业务，或原业务到期日小于当前日期，或原业务余额等于0，取保证金账号到期日',
       D.ORG_NUM,
       D.CURR_CD,
       D.CUST_ID
        FROM SMTMODS_L_ACCT_DEPOSIT D
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = D.CURR_CD --基准币种
         AND T2.FORWARD_CCY = 'CNY'
        LEFT JOIN (SELECT T.SECURITY_ACCT_NUM, SUM(T.SECURITY_BALANCE) ACCT_BALANCE
                     FROM CBRC_S46_TMP_SECURITY_OBS_LOAN T
                    GROUP BY T.SECURITY_ACCT_NUM) T
          ON T.SECURITY_ACCT_NUM = D.O_ACCT_NUM
       WHERE D.DATA_DATE = I_DATADATE
         AND D.ACCT_BALANCE > 0
         AND T.SECURITY_ACCT_NUM IS NULL
         AND D.GL_ITEM_CODE IN ('20110114', '20110115', '20110209', '20110210');

    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工保证金存款基础业务明细数据完成';
    --V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);
    --处理存款

    EXECUTE IMMEDIATE ('TRUNCATE TABLE CBRC_S46_DEPOSIT_TMP');

    INSERT INTO CBRC_S46_DEPOSIT_TMP
      SELECT T.DATA_DATE,
             T.ACCT_NUM,
             T.ORG_NUM,
             T.CUST_ID,
             T.CURR_CD,
             T.ACCT_TYPE,
             T.GL_ITEM_CODE,
             T.ACCT_BALANCE,
             T.MATUR_DATE,
             --COALESCE(P.REGION_CD, P.ORG_AREA, C.REGION_CD, C.ORG_AREA, '0') AS REGION_CD,
             COALESCE(P.ORG_AREA,C.ORG_AREA,P.REGION_CD,C.REGION_CD,'0') AS REGION_CD,--JLCA202411190001_关于吉银村镇银行变更异地存款取数口径的项目需求
             CASE --活期
               WHEN (T.GL_ITEM_CODE IN ('20110201',
                                        '20110101',
                                        '20110102',
                                        '20110111',
                                        '20110206',
                                        '20130101',
                                        '20130201',
                                        '20130301',
                                        '20140101',
                                        '20140201',
                                        '20140301'
                                        ,'20110301','20110302','20110303','22410101','22410102','20080101','20090101'--[JLBA202507210012][石雨][修改内容：224101久悬未取款]
                                        ) OR T.GL_ITEM_CODE = '20120106') THEN
                '0Y'
               WHEN T.GL_ITEM_CODE IN ('20110110', '20110205') --20110110  个人通知存款、20110205 单位通知存款
                THEN
                '0Y'

               WHEN T.GL_ITEM_CODE IN ('20110114', '20110115', '20110209', '20110210') THEN
                CASE
                  WHEN BZJ.MATURITY_DT IS NULL THEN
                   '0Y' --保证金到期日为空算在次日
                  WHEN (BZJ.MATURITY_DT - I_DATADATE) / 365 >= 5 THEN
                   '5Y'
                  WHEN (BZJ.MATURITY_DT - I_DATADATE) / 365 >= 4 THEN
                   '4Y'
                  WHEN (BZJ.MATURITY_DT - I_DATADATE) / 365 >= 3 THEN
                   '3Y'
                  WHEN (BZJ.MATURITY_DT - I_DATADATE) / 365 >= 2 THEN
                   '2Y'
                  WHEN (BZJ.MATURITY_DT - I_DATADATE) / 365 >= 1 THEN
                   '1Y'
                  WHEN (BZJ.MATURITY_DT - I_DATADATE) / 365 >= 0 THEN
                   '0Y'
                  WHEN (BZJ.MATURITY_DT - I_DATADATE) / 365 < 0 THEN
                   '0Y'
                END
               WHEN (T.MATUR_DATE - I_DATADATE) / 365 >= 5 THEN
                '5Y'
               WHEN (T.MATUR_DATE - I_DATADATE) / 365 >= 4 THEN
                '4Y'
               WHEN (T.MATUR_DATE - I_DATADATE) / 365 >= 3 THEN
                '3Y'
               WHEN (T.MATUR_DATE - I_DATADATE) / 365 >= 2 THEN
                '2Y'
               WHEN (T.MATUR_DATE - I_DATADATE) / 365 >= 1 THEN
                '1Y'
               WHEN (T.MATUR_DATE - I_DATADATE) / 365 >= 0 THEN
                '0Y'
               WHEN (T.MATUR_DATE - I_DATADATE) / 365 < 0 THEN
                '0Y'
             END AS TERM
        FROM SMTMODS_L_ACCT_DEPOSIT T
        LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
          ON P.DATA_DATE = I_DATADATE
         AND T.CUST_ID = P.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户补充信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S46_TMP_SECURITY_RESULT BZJ --保证金
          ON T.ACCT_NUM = BZJ.ACCT_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(T.ORG_NUM, 1, 1) IN ('5', '6')
         AND (T.GL_ITEM_CODE LIKE '2011%'
            or t.gl_item_code like '224101%' --[JLBA202507210012][石雨][20250918][修改内容：224101久悬未取款]
            or t.gl_item_code like '2008%'  or t.gl_item_code like '2009%' --[JLBA202507210012][石雨][20250918]
            )
         ;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_ID   := V_STEP_ID + 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

    --1.1.1县域外地市内贷款  --地区代码调整参考村镇银行机构信息表，县镇\市\省
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_1.1.1.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.ITEM_CD LIKE '1303%'
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 4) = SUBSTR(B.REGION_CD, 1, 4) --县域外地市内
              ) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --1.1.2地市外省内贷款
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_1.1.2.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.ITEM_CD LIKE '1303%'
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 4) <> SUBSTR(B.REGION_CD, 1, 4)
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) = SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --1.1.3省外贷款

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_1.1.3.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL

                FROM CBRC_S47_BAL_TMP A --贷款信息
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.ITEM_CD LIKE '1303%'
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) <> SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --其中:1.1.3.1关注类贷款

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_1.1.3.1.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.LOAN_GRADE_CD IN ('2')
                 AND A.ITEM_CD LIKE '1303%'
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) <> SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    -- 1.1.3.2不良贷款

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_1.1.3.2.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND A.ITEM_CD LIKE '1303%'
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) <> SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --1.2.1正常类贷款

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_1.2.1.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.ITEM_CD LIKE '1303%'
                 AND A.LOAN_GRADE_CD IN ('1')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --1.2.2关注类贷款
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_1.2.2.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.ITEM_CD LIKE '1303%'
                 AND A.LOAN_GRADE_CD IN ('2')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --1.2.3不良贷款

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_1.2.3.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.ITEM_CD LIKE '1303%'
                 AND A.LOAN_GRADE_CD IN ('3', '4', '5')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 0;
    V_STEP_DESC := V_PROCEDURE || '4.票据直贴';
    V_STEP_ID   := V_STEP_ID + 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

    --4.1.1县域外地市内  --地区代码调整参考村镇银行机构信息表，县镇\市\省
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_4.1.1.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130101', '130104') --直贴
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 4) = SUBSTR(B.REGION_CD, 1, 4) --县域外地市内
              ) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --4.1.2地市外省内
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_4.1.2.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130101', '130104') --直贴
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 4) <> SUBSTR(B.REGION_CD, 1, 4)
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) = SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --4.1.3省外

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_4.1.3.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL

                FROM CBRC_S47_BAL_TMP A --贷款信息
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130101', '130104') --直贴
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) <> SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --其中:4.1.3.1关注类

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_4.1.3.1.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.LOAN_GRADE_CD IN ('2')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130101', '130104') --直贴
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) <> SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    -- 4.1.3.2不良
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_4.1.3.2.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130101', '130104') --直贴
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) <> SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --4.2.1正常类

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_4.2.1.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130101', '130104') --直贴
                 AND A.LOAN_GRADE_CD IN ('1')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --4.2.2关注类
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_4.2.2.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130101', '130104') --直贴
                 AND A.LOAN_GRADE_CD IN ('2')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --4.2.3不良贷款

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_4.2.3.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130101', '130104') --直贴
                 AND A.LOAN_GRADE_CD IN ('3', '4', '5')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    ----------转帖

    V_STEP_FLAG := 0;
    V_STEP_DESC := V_PROCEDURE || '5.买断式转贴现';
    V_STEP_ID   := V_STEP_ID + 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

    --5.1.1县域外地市内  --地区代码调整参考村镇银行机构信息表，县镇\市\省
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_5.1.1.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130102', '130105') --转帖
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 4) = SUBSTR(B.REGION_CD, 1, 4) --县域外地市内
              ) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --5.1.2地市外省内
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_5.1.2.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130102', '130105') --转帖
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 4) <> SUBSTR(B.REGION_CD, 1, 4)
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) = SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --5.1.3省外

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_5.1.3.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL

                FROM CBRC_S47_BAL_TMP A --贷款信息
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130102', '130105') --转帖
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) <> SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --其中:5.1.3.1关注类

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_5.1.3.1.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.LOAN_GRADE_CD IN ('2')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130102', '130105') --转帖
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) <> SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    -- 5.1.3.2不良
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_5.1.3.2.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130102', '130105') --转帖
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) <> SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --5.2.1正常类

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_5.2.1.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130102', '130105') --转帖
                 AND A.LOAN_GRADE_CD IN ('1')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --5.2.2关注类
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_5.2.2.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130102', '130105') --转帖
                 AND A.LOAN_GRADE_CD IN ('2')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    --5.2.3不良贷款

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_5.2.3.A.2023' AS ITEM_NUM,
             SUM(C.LOAN_ACCT_BAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.LOAN_ACCT_BAL
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.LOAN_ACCT_BAL
                     END AS LOAN_ACCT_BAL
                FROM CBRC_S47_BAL_TMP A --贷款信息
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(A.ITEM_CD, 1, 6) IN ('130102', '130105') --转帖
                 AND A.LOAN_GRADE_CD IN ('3', '4', '5')) C
       GROUP BY C.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 0;
    V_STEP_DESC := V_PROCEDURE || '7.异地线下存款';
    V_STEP_ID   := V_STEP_ID + 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID, V_ERRORCODE, V_STEP_DESC, II_DATADATE);

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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_7.1.1.A.2023' AS ITEM_NUM,
             SUM(C.ACCT_BALANCE) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.ACCT_BALANCE
                     END AS ACCT_BALANCE
                FROM CBRC_S46_DEPOSIT_TMP A
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 4) = SUBSTR(B.REGION_CD, 1, 4) --县域外地市内
              ) C
       GROUP BY ORG_NUM;
    COMMIT;

    ---地市外省内
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_7.1.2.A.2023' AS ITEM_NUM,
             SUM(C.ACCT_BALANCE) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.ACCT_BALANCE
                FROM CBRC_S46_DEPOSIT_TMP A
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 4) <> SUBSTR(B.REGION_CD, 1, 4)
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) = SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY ORG_NUM;
    COMMIT;

    ---省外
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_7.1.3.A.2023' AS ITEM_NUM,
             SUM(C.ACCT_BALANCE) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A.ACCT_BALANCE
                FROM CBRC_S46_DEPOSIT_TMP A
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) <> SUBSTR(B.REGION_CD, 1, 2)) C
       GROUP BY ORG_NUM;
    COMMIT;

    --7.2按剩余期限划分
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             CASE
               WHEN C.TERM = '0Y' THEN
                'S46_7.2.1.A.2023'
               WHEN C.TERM = '1Y' THEN
                'S46_7.2.2.A.2023'
               WHEN C.TERM = '2Y' THEN
                'S46_7.2.3.A.2023'
               WHEN C.TERM = '3Y' THEN
                'S46_7.2.4.A.2023'
               WHEN C.TERM = '4Y' THEN
                'S46_7.2.5.A.2023'
               WHEN C.TERM = '5Y' THEN
                'S46_7.2.6.A.2023'
             END AS ITEM_NUM,
             SUM(C.ACCT_BALANCE) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A.ACCT_BALANCE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A.ACCT_BALANCE
                     END AS ACCT_BALANCE,
                     A.TERM
                FROM CBRC_S46_DEPOSIT_TMP A
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')) C
       GROUP BY ORG_NUM,
                CASE
                  WHEN C.TERM = '0Y' THEN
                   'S46_7.2.1.A.2023'
                  WHEN C.TERM = '1Y' THEN
                   'S46_7.2.2.A.2023'
                  WHEN C.TERM = '2Y' THEN
                   'S46_7.2.3.A.2023'
                  WHEN C.TERM = '3Y' THEN
                   'S46_7.2.4.A.2023'
                  WHEN C.TERM = '4Y' THEN
                   'S46_7.2.5.A.2023'
                  WHEN C.TERM = '5Y' THEN
                   'S46_7.2.6.A.2023'
                END;
    COMMIT;

    --注册外省内
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_7.3.1.A.2023' AS ITEM_NUM,
             SUM(C.ACCT_BALANCE) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     A1.CUST_TYPE,
                     SUM(CASE
                           WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                            A.ACCT_BALANCE
                           WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                            A.ACCT_BALANCE
                           WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                            A.ACCT_BALANCE
                           WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                            A.ACCT_BALANCE
                           WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                            A.ACCT_BALANCE
                           WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                            A.ACCT_BALANCE
                           WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                            A.ACCT_BALANCE
                           WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                            A.ACCT_BALANCE
                           WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                            A.ACCT_BALANCE
                           WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                            A.ACCT_BALANCE
                         END) AS ACCT_BALANCE
                FROM CBRC_S46_DEPOSIT_TMP A
                LEFT JOIN SMTMODS_L_CUST_ALL A1
                  ON A.CUST_ID = A1.CUST_ID
                 AND A1.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) = SUBSTR(B.REGION_CD, 1, 2)
               GROUP BY A.ORG_NUM, A.CUST_ID, A1.CUST_TYPE) C
       WHERE (CUST_TYPE = '00' AND ACCT_BALANCE >= 500000)
          OR (CUST_TYPE <> '00' AND ACCT_BALANCE >= 2000000)
       GROUP BY ORG_NUM;
    COMMIT;

    --7.3.2省外异地大额存款
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_7.3.2.A.2023' AS ITEM_NUM,
             SUM(C.ACCT_BALANCE) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM, A.CUST_ID, A1.CUST_TYPE, SUM(A.ACCT_BALANCE) AS ACCT_BALANCE
                FROM CBRC_S46_DEPOSIT_TMP A
                LEFT JOIN SMTMODS_L_CUST_ALL A1
                  ON A.CUST_ID = A1.CUST_ID
                 AND A1.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND SUBSTR(NVL(A.REGION_CD, '0'), 1, 2) <> SUBSTR(B.REGION_CD, 1, 2)
               GROUP BY A.ORG_NUM, A.CUST_ID, A1.CUST_TYPE) C
       WHERE (CUST_TYPE = '00' AND ACCT_BALANCE >= 500000)
          OR (CUST_TYPE <> '00' AND ACCT_BALANCE >= 2000000)
       GROUP BY ORG_NUM;
    COMMIT;

    --交易临时表 CBRC_s46_L_TRAN_TX
     EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_s46_L_TRAN_TX';

        insert into  CBRC_s46_L_TRAN_TX 
        (DATA_DATE,ORG_NUM,TX_DT,REFERENCE_NUM,CUST_ID,ACCOUNT_CODE,TRANS_AMT)
        select 
               DATA_DATE,
               ORG_NUM,
               TX_DT,
               REFERENCE_NUM,
               CUST_ID,
               ACCOUNT_CODE,
               TRANS_AMT
               
     from SMTMODS_L_TRAN_TX t
         where  t.DATA_DATE >=TO_CHAR(TRUNC(date(I_DATADATE), 'YYYY'),'YYYYMMDD')
                     AND t.DATA_DATE <= I_DATADATE
                     AND t.CD_TYPE = '2'
                     and t.TRANS_AMT >= 1000000
                     AND SUBSTR(T.ORG_NUM, 1, 1) IN ('5', '6');
    COMMIT;

    ---7.3.4异地存款-整存整取发生额 指截止填报日期，填报机构吸收的人民币100万元（含）以上的、三个月内（整存整取期限为3个月以内（含））整存整取的异地存款总额。
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
             C.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S46_7.3.4.A.2023' AS ITEM_NUM,
             SUM(C.TRANS_AMT) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM,
                     A.CUST_ID,
                     CASE
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220284') AND SUBSTR(A.ORG_NUM, 1, 2) = '51' THEN
                        A1.TRANS_AMT
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('321012') AND SUBSTR(A.ORG_NUM, 1, 2) = '52' THEN
                        A1.TRANS_AMT
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220283') AND SUBSTR(A.ORG_NUM, 1, 2) = '53' THEN
                        A1.TRANS_AMT
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220112') AND SUBSTR(A.ORG_NUM, 1, 2) = '54' THEN
                        A1.TRANS_AMT
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('130902') AND SUBSTR(A.ORG_NUM, 1, 2) = '55' THEN
                        A1.TRANS_AMT
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('131023') AND SUBSTR(A.ORG_NUM, 1, 2) = '56' THEN
                        A1.TRANS_AMT
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('222404') AND SUBSTR(A.ORG_NUM, 1, 2) = '57' THEN
                        A1.TRANS_AMT
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220382') AND SUBSTR(A.ORG_NUM, 1, 2) = '58' THEN
                        A1.TRANS_AMT
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220421') AND SUBSTR(A.ORG_NUM, 1, 2) = '59' THEN
                        A1.TRANS_AMT
                       WHEN NVL(A.REGION_CD, '0') NOT IN ('220281') AND SUBSTR(A.ORG_NUM, 1, 2) = '60' THEN
                        A1.TRANS_AMT
                     END AS TRANS_AMT
                FROM CBRC_S46_DEPOSIT_TMP A
               INNER JOIN CBRC_S46_L_TRAN_TX A1
                  ON A.ACCT_NUM = A1.ACCOUNT_CODE
              --alter by shiyu 20240305 修改成本年累计
            
                LEFT JOIN SMTMODS_L_PUBL_ORG_BRA B
                  ON A.ORG_NUM = B.ORG_NUM
                 AND B.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6')
                 AND A.GL_ITEM_CODE = '20110103'
                 AND MONTHS_BETWEEN(A.MATUR_DATE, A1.TX_DT) <= 3
                 AND A1.TRANS_AMT >= 1000000) C
       GROUP BY ORG_NUM;
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
   
END proc_cbrc_idx2_s46