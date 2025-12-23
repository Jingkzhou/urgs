CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g18(II_DATADATE IN STRING --跑批日期
                                              )
/******************************
  @author:JIHAIJING
  @create-date:20150929
  @description:G18
  @modification history:
  m0.author-create_date-description
  m1.1.4项及1,7项新增逻辑
  m2.1.1.2项改为从L_ACCT_FUND_CDS_BAL取数。
  m3.逻辑有问题，前台未引用的指标全部注释
  --JLBA202504300003_关于1104报送系统实现G24、G01、G18表自动化取数的需求 上线时间：20250619 修改人：石雨 提出人：苏桐 修改内容：1.1存单，剩余期限汇总项目未合计,将1.1.2同业存单项汇总合计
  
目标表:CBRC_A_REPT_ITEM_VAL
临时表：CBRC_G18_DATA_COLLECT_TMP
集市表：SMTMODS_L_ACCT_DEPOSIT
     SMTMODS_L_ACCT_FUND_BOND_ISSUE
     SMTMODS_L_ACCT_FUND_CDS_BAL
     SMTMODS_L_CUST_ALL
     SMTMODS_L_PUBL_RATE  

  ********************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE := II_DATADATE;
    V_SYSTEM   := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G18');
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME     := 'CBRC_A_REPT_ITEM_VAL';
    D_DATADATE_CCY := TO_DATE(I_DATADATE, 'YYYYMMDD');

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']G18当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G18_DATA_COLLECT_TMP';
    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G18'
       AND T.FLAG = '2';
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   
    --2020年制度升级修改内容

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取大额存单至CBRC_G18_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --按期限划分
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
      SELECT 
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             CASE
               WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE),
                                   DATE(A.DATA_DATE)) <= 12 THEN
                'G18_0_1.1.1.E.2020' --剩余期限-1年
               WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE),
                                   DATE(A.DATA_DATE)) > 12 AND
                    MONTHS_BETWEEN(DATE(A.MATUR_DATE),
                                   DATE(A.DATA_DATE)) <= 60 THEN
                'G18_0_1.1.1.F.2020' --剩余期限-1-5年
               WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE),
                                   DATE(A.DATA_DATE)) > 60 AND
                    MONTHS_BETWEEN(DATE(A.MATUR_DATE),
                                   DATE(A.DATA_DATE)) <= 120 THEN  --ZHOUJINGKUN 20210702 UPDATE 条件判断错误  由>120 修改为 < 120
                'G18_0_1.1.1.G.2020' --剩余期限-5-10年
               WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE),
                                   DATE(A.DATA_DATE)) > 120 THEN
                'G18_0_1.1.1.H.2020' --剩余期限-10年以上

             END AS ITEM_NUM,
             SUM(A.ACCT_BALANCE * U.CCY_RATE) AS FACE_VAL_RMB,
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_DEPOSIT A
        LEFT JOIN SMTMODS_L_PUBL_RATE U ON U.CCY_DATE = D_DATADATE_CCY
                               AND U.BASIC_CCY = A.CURR_CD --基准币种
                               AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE IN ('20110208','20110113') --大额存单
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE),
                                      DATE(A.DATA_DATE)) <= 12 THEN
                   'G18_0_1.1.1.E.2020' --剩余期限-1年
                  WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE),
                                      DATE(A.DATA_DATE)) > 12 AND
                       MONTHS_BETWEEN(DATE(A.MATUR_DATE),
                                      DATE(A.DATA_DATE)) <= 60 THEN
                   'G18_0_1.1.1.F.2020' --剩余期限-1-5年
                  WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE),
                                      DATE(A.DATA_DATE)) > 60 AND
                       MONTHS_BETWEEN(DATE(A.MATUR_DATE),
                                      DATE(A.DATA_DATE)) <= 120 THEN
                   'G18_0_1.1.1.G.2020' --剩余期限-5-10年
                  WHEN MONTHS_BETWEEN(DATE(A.MATUR_DATE),
                                      DATE(A.DATA_DATE)) > 120 THEN
                   'G18_0_1.1.1.H.2020' --剩余期限-10年以上

                END;
    COMMIT;

    --本年发放
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
      SELECT 
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'G18_0_1.1.1.B.2020' AS ITEM_NUM, --境内-本年发行
             SUM(A.ACCT_BALANCE * U.CCY_RATE) AS FACE_VAL_RMB,
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_DEPOSIT A
        LEFT JOIN SMTMODS_L_PUBL_RATE U ON U.CCY_DATE = D_DATADATE_CCY
                               AND U.BASIC_CCY = A.CURR_CD --基准币种
                               AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE IN ('20110208','20110113') --大额存单
         AND TO_CHAR(A.ST_INT_DT, 'YYYYMMDD') BETWEEN
             SUBSTR(I_DATADATE, 0, 4) || '0101' AND
             SUBSTR(I_DATADATE, 0, 4) || '1231'
       GROUP BY A.ORG_NUM;
    COMMIT;

    --大额存单面值，无境外发放
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
      SELECT
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'G18_0_1.1.1.A.2020' AS ITEM_NUM, --境内大额存单面值
             SUM(A.FACE_VAL_RMB),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM CBRC_G18_DATA_COLLECT_TMP A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_NUM IN ('G18_0_1.1.1.E.2020', 'G18_0_1.1.1.F.2020',
              'G18_0_1.1.1.G.2020', 'G18_0_1.1.1.H.2020')
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取同业存单至CBRC_G18_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --按期限划分

    ---JLBA202504300003_关于1104报送系统实现G24、G01、G18表自动化取数的需求 修改人：石雨 新增1.1存单，剩余期限汇总项目合计规则

     INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
       SELECT 
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             CASE
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE))  <= 12 THEN
                'G18_0_1.1.E.2020' --剩余期限-1年
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) >12 AND
                    MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE))  <= 60 THEN
                'G18_0_1.1.F.2020' --剩余期限-1-5年
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) > 60 AND
                    MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) <= 120 THEN
                'G18_0_1.1.G.2020' --剩余期限-5-10年
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) > 120 THEN
                'G18_0_1.1.H.2020' --剩余期限-10年以上
             END AS ITEM_NUM,
             SUM(A.FACE_VAL * U.CCY_RATE) AS FACE_VAL_RMB,
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_FUND_CDS_BAL A --存单投资与发行信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE U ON U.CCY_DATE = I_DATADATE
                               AND U.BASIC_CCY = A.CURR_CD --基准币种
                               AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE LIKE '250202%' --同业存单科目
         --and A.REAL_MATURITY_DT> to_date(I_DATADATE,'yyyymmdd')
       GROUP BY A.ORG_NUM,
                CASE
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE))  <= 12 THEN
                'G18_0_1.1.E.2020' --剩余期限-1年
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) >12 AND
                    MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE))  <= 60 THEN
                'G18_0_1.1.F.2020' --剩余期限-1-5年
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) > 60 AND
                    MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) <= 120 THEN
                'G18_0_1.1.G.2020' --剩余期限-5-10年
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) > 120 THEN
                'G18_0_1.1.H.2020' --剩余期限-10年以上
             END;
             COMMIT;




    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
      
        SELECT 
             I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             CASE
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE))  <= 12 THEN
                'G18_0_1.1.2.E.2020' --剩余期限-1年
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) >12 AND
                    MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE))  <= 60 THEN
                'G18_0_1.1.2.F.2020' --剩余期限-1-5年
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) > 60 AND
                    MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) <= 120 THEN
                'G18_0_1.1.2.G.2020' --剩余期限-5-10年
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) > 120 THEN
                'G18_0_1.1.2.H.2020' --剩余期限-10年以上
             END AS ITEM_NUM,
             SUM(A.FACE_VAL * U.CCY_RATE) AS FACE_VAL_RMB,
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_FUND_CDS_BAL A --存单投资与发行信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE U ON U.CCY_DATE = I_DATADATE
                               AND U.BASIC_CCY = A.CURR_CD --基准币种
                               AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE LIKE '250202%' --同业存单科目
         --and A.REAL_MATURITY_DT> to_date(I_DATADATE,'yyyymmdd')
       GROUP BY A.ORG_NUM,
                CASE
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE))  <= 12 THEN
                'G18_0_1.1.2.E.2020' --剩余期限-1年
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) >12 AND
                    MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE))  <= 60 THEN
                'G18_0_1.1.2.F.2020' --剩余期限-1-5年
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) > 60 AND
                    MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) <= 120 THEN
                'G18_0_1.1.2.G.2020' --剩余期限-5-10年
               WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT),DATE(I_DATADATE)) > 120 THEN
                'G18_0_1.1.2.H.2020' --剩余期限-10年以上
             END;
    COMMIT;

    --本年发放
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
     
       SELECT I_DATADATE AS DATA_DATE,
             A.org_num AS ORG_NUM,
             'G18_0_1.1.2.B.2020' AS ITEM_NUM, --境内-本年发行
             SUM(A.FACE_VAL * U.CCY_RATE) AS FACE_VAL_RMB,
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
       FROM SMTMODS_L_ACCT_FUND_CDS_BAL A --存单投资与发行信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE U ON U.CCY_DATE = I_DATADATE
                               AND U.BASIC_CCY = A.CURR_CD --基准币种
                               AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE LIKE '250202%' --同业存单科目
      AND TO_CHAR(A.INT_ST_DT, 'YYYYMMDD') BETWEEN
             SUBSTR(I_DATADATE, 0, 4) || '0101' AND
             SUBSTR(I_DATADATE, 0, 4) || '1231'
       GROUP BY A.Org_Num;
    COMMIT;

    --同业存单面值，无境外发放
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'G18_0_1.1.2.A.2020' AS ITEM_NUM, --境内大额存单面值
             SUM(A.FACE_VAL_RMB),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM CBRC_G18_DATA_COLLECT_TMP A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_NUM IN ('G18_0_1.1.2.E.2020', 'G18_0_1.1.2.F.2020',
              'G18_0_1.1.2.G.2020', 'G18_0_1.1.2.H.2020')
       GROUP BY A.ORG_NUM;
    COMMIT;

    ---------------
    --M1 1.4项次级债券
     --境内发行账面余额
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
       SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'G18_0_1.4.A.2022' AS ITEM_NUM,
             SUM(T.FACE_VAL* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_FUND_BOND_ISSUE T --债券发行信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = D_DATADATE_CCY
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID=A.CUST_ID
           AND A.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.MATURITY_DATE >D_DATADATE_CCY
         AND T.FACE_VAL<>0
         AND A.INLANDORRSHORE_FLG='Y'
       GROUP BY T.ORG_NUM;
       COMMIT;
     --境内发行其中:本年发行
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
       SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'G18_0_1.4.B.2022' AS ITEM_NUM,
             SUM(T.FACE_VAL* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_FUND_BOND_ISSUE T --债券发行信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = D_DATADATE_CCY
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID=A.CUST_ID
           AND A.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.MATURITY_DATE >D_DATADATE_CCY
         AND TO_CHAR(T.INT_ST_DT,'YYYY') =SUBSTR(I_DATADATE,1,4) --本年
         AND T.FACE_VAL<>0
         AND A.INLANDORRSHORE_FLG='Y'
       GROUP BY T.ORG_NUM;
       COMMIT;
      --境外发行账面余额
     INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
       SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'G18_0_1.4.C.2022' AS ITEM_NUM,
             SUM(T.FACE_VAL* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_FUND_BOND_ISSUE T --债券发行信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = D_DATADATE_CCY
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID=A.CUST_ID
           AND A.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.MATURITY_DATE >D_DATADATE_CCY
         AND T.FACE_VAL<>0
         AND A.INLANDORRSHORE_FLG='N'
       GROUP BY T.ORG_NUM;
       COMMIT;
       --境外发行其中:本年发行
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
       SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'G18_0_1.4.D.2022' AS ITEM_NUM,
             SUM(T.FACE_VAL* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_FUND_BOND_ISSUE T --债券发行信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = D_DATADATE_CCY
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID=A.CUST_ID
           AND A.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.MATURITY_DATE >D_DATADATE_CCY
         AND TO_CHAR(T.INT_ST_DT,'YYYY') =SUBSTR(I_DATADATE,1,4) --本年
         AND T.FACE_VAL<>0
         AND A.INLANDORRSHORE_FLG='N'
       GROUP BY T.ORG_NUM;
       COMMIT;
       --剩余期限
       INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
       SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             CASE
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE))  <= 12 THEN
                'G18_0_1.4.E.2022' --剩余期限-1年
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) >12 AND
                    MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE))  <= 60 THEN
                'G18_0_1.4.F.2022' --剩余期限-1-5年
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) > 60 AND
                    MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) <= 120 THEN
                'G18_0_1.4.G.2022' --剩余期限-5-10年
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) > 120 THEN
                'G18_0_1.4.H.2022' --剩余期限-10年以上
             END AS ITEM_NUM,
             SUM(T.FACE_VAL* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_FUND_BOND_ISSUE T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
              ON U.CCY_DATE = I_DATADATE
             AND U.BASIC_CCY = t.CURR_CD --基准币种
             AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE T.DATA_DATE=I_DATADATE
  AND T.MATURITY_DATE >I_DATADATE
 AND T.FACE_VAL<>0
       GROUP BY T.ORG_NUM,
                CASE
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE))  <= 12 THEN
                'G18_0_1.4.E.2022' --剩余期限-1年
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) >12 AND
                    MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE))  <= 60 THEN
                'G18_0_1.4.F.2022' --剩余期限-1-5年
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) > 60 AND
                    MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) <= 120 THEN
                'G18_0_1.4.G.2022' --剩余期限-5-10年
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) > 120 THEN
                'G18_0_1.4.H.2022' --剩余期限-10年以上
             END;
    COMMIT;
    --1.4.1 其中：二级资本债
    --境内发行账面余额
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
       SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'G18_0_1.4.1.A.2022' AS ITEM_NUM,
             SUM(T.FACE_VAL* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_FUND_BOND_ISSUE T --债券发行信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = D_DATADATE_CCY
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID=A.CUST_ID
           AND A.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.MATURITY_DATE >D_DATADATE_CCY
         AND T.FACE_VAL<>0
         AND A.INLANDORRSHORE_FLG='Y'
       GROUP BY T.ORG_NUM;
       COMMIT;
     --境内发行其中:本年发行
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
       SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'G18_0_1.4.1.B.2022' AS ITEM_NUM,
             SUM(T.FACE_VAL* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_FUND_BOND_ISSUE T --债券发行信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = D_DATADATE_CCY
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID=A.CUST_ID
           AND A.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.MATURITY_DATE >D_DATADATE_CCY
         AND TO_CHAR(T.INT_ST_DT,'YYYY') =SUBSTR(I_DATADATE,1,4) --本年
         AND T.FACE_VAL<>0
         AND A.INLANDORRSHORE_FLG='Y'
       GROUP BY T.ORG_NUM;
       COMMIT;
      --境外发行账面余额
     INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
       SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'G18_0_1.4.1.C.2022' AS ITEM_NUM,
             SUM(T.FACE_VAL* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_FUND_BOND_ISSUE T --债券发行信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = D_DATADATE_CCY
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID=A.CUST_ID
           AND A.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.MATURITY_DATE >D_DATADATE_CCY
         AND T.FACE_VAL<>0
         AND A.INLANDORRSHORE_FLG='N'
       GROUP BY T.ORG_NUM;
       COMMIT;
       --境外发行其中:本年发行
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
       SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'G18_0_1.4.1.D.2022' AS ITEM_NUM,
             SUM(T.FACE_VAL* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_FUND_BOND_ISSUE T --债券发行信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = D_DATADATE_CCY
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID=A.CUST_ID
           AND A.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.MATURITY_DATE >D_DATADATE_CCY
         AND TO_CHAR(T.INT_ST_DT,'YYYY') =SUBSTR(I_DATADATE,1,4) --本年
         AND T.FACE_VAL<>0
         AND A.INLANDORRSHORE_FLG='N'
       GROUP BY T.ORG_NUM;
       COMMIT;
       --剩余期限
       INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
       SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             CASE
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE))  <= 12 THEN
                'G18_0_1.4.1.E.2022' --剩余期限-1年
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) >12 AND
                    MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE))  <= 60 THEN
                'G18_0_1.4.1.F.2022' --剩余期限-1-5年
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) > 60 AND
                    MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) <= 120 THEN
                'G18_0_1.4.1.G.2022' --剩余期限-5-10年
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) > 120 THEN
                'G18_0_1.4.1.H.2022' --剩余期限-10年以上
             END AS ITEM_NUM,
             SUM(T.FACE_VAL* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_FUND_BOND_ISSUE T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
              ON U.CCY_DATE = I_DATADATE
             AND U.BASIC_CCY = t.CURR_CD --基准币种
             AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE T.DATA_DATE=I_DATADATE
  AND T.MATURITY_DATE >I_DATADATE
 AND T.FACE_VAL<>0
       GROUP BY T.ORG_NUM,
                CASE
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE))  <= 12 THEN
                'G18_0_1.4.1.E.2022' --剩余期限-1年
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) >12 AND
                    MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE))  <= 60 THEN
                'G18_0_1.4.1.F.2022' --剩余期限-1-5年
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) > 60 AND
                    MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) <= 120 THEN
                'G18_0_1.4.1.G.2022' --剩余期限-5-10年
               WHEN MONTHS_BETWEEN(T.MATURITY_DATE,DATE(I_DATADATE)) > 120 THEN
                'G18_0_1.4.1.H.2022' --剩余期限-10年以上
             END;
    COMMIT;
    --1.7其他具有固定期限的融资工具
    --境内发行账面余额
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'G18_0_1.7.A.2022' AS ITEM_NUM,
             SUM(T.ACCT_BALANCE* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_DEPOSIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = D_DATADATE_CCY
           AND U.BASIC_CCY = t.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID=A.CUST_ID
           AND A.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.GL_ITEM_CODE LIKE '20110211%' --转股协议存款
         --AND T.ACCT_STS='N' --账户状态：正常
         AND T.ACCT_BALANCE <> 0
         AND A.INLANDORRSHORE_FLG='Y' --境内
       GROUP BY T.ORG_NUM;
       COMMIT;
    --境内发行其中:本年发行
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'G18_0_1.7.B.2022' AS ITEM_NUM,
             SUM(T.ACCT_BALANCE* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_DEPOSIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U ON U.CCY_DATE = D_DATADATE_CCY
                               AND U.BASIC_CCY = t.CURR_CD --基准币种
                               AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID=A.CUST_ID
           AND A.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         --AND T.ACCT_STS='N' --账户状态：正常
         AND T.GL_ITEM_CODE LIKE '20110211%' --转股协议存款
         AND TO_CHAR(T.ST_INT_DT,'YYYY') =SUBSTR(I_DATADATE,1,4) --本年
         AND T.ACCT_BALANCE <> 0
         AND A.INLANDORRSHORE_FLG='Y' --境内
       GROUP BY T.ORG_NUM;
       COMMIT;
    --境外发行账面余额
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'G18_0_1.7.C.2022' AS ITEM_NUM,
             SUM(T.ACCT_BALANCE* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_DEPOSIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U ON U.CCY_DATE = D_DATADATE_CCY
                               AND U.BASIC_CCY = t.CURR_CD --基准币种
                               AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID=A.CUST_ID
           AND A.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.GL_ITEM_CODE LIKE '20110211%' --转股协议存款
        -- AND T.ACCT_STS='N' --账户状态：正常
         AND T.ACCT_BALANCE <> 0
         AND A.INLANDORRSHORE_FLG='N' --境外
       GROUP BY T.ORG_NUM;
       COMMIT;
    --境外发行其中:本年发行
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'G18_0_1.7.D.2022' AS ITEM_NUM,
             SUM(T.ACCT_BALANCE* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_DEPOSIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U ON U.CCY_DATE = D_DATADATE_CCY
                               AND U.BASIC_CCY = t.CURR_CD --基准币种
                               AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID=A.CUST_ID
           AND A.DATA_DATE=I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         --AND T.ACCT_STS='N' --账户状态：正常
         AND T.GL_ITEM_CODE LIKE '20110211%' --转股协议存款
         AND TO_CHAR(T.ST_INT_DT,'YYYY') =SUBSTR(I_DATADATE,1,4) --本年
         AND T.ACCT_BALANCE <> 0
         AND A.INLANDORRSHORE_FLG='N' --境外
       GROUP BY T.ORG_NUM;
       COMMIT;

    ----剩余期限
    INSERT INTO CBRC_G18_DATA_COLLECT_TMP
      (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
    SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             CASE
               WHEN MONTHS_BETWEEN(DATE(T.MATUR_DATE),DATE(I_DATADATE))  <= 12 THEN
                'G18_0_1.7.E.2022' --剩余期限-1年
               WHEN MONTHS_BETWEEN(DATE(T.MATUR_DATE),DATE(I_DATADATE)) >12 AND
                    MONTHS_BETWEEN(DATE(T.MATUR_DATE),DATE(I_DATADATE))  <= 60 THEN
                'G18_0_1.7.F.2022' --剩余期限-1-5年
               WHEN MONTHS_BETWEEN(DATE(T.MATUR_DATE),DATE(I_DATADATE)) > 60 AND
                    MONTHS_BETWEEN(DATE(T.MATUR_DATE),DATE(I_DATADATE)) <= 120 THEN
                'G18_0_1.7.G.2022' --剩余期限-5-10年
               WHEN MONTHS_BETWEEN(DATE(T.MATUR_DATE),DATE(I_DATADATE)) > 120 THEN
                'G18_0_1.7.H.2022' --剩余期限-10年以上
             END AS ITEM_NUM,
             SUM(T.ACCT_BALANCE* U.CCY_RATE),
             0 AS GZSY_VAL_RMB,
             0 AS PREPARATION_RMB
        FROM SMTMODS_L_ACCT_DEPOSIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
             ON U.CCY_DATE = I_DATADATE
             AND U.BASIC_CCY = t.CURR_CD --基准币种
             AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE T.DATA_DATE=I_DATADATE
   AND  T.GL_ITEM_CODE LIKE '20110211%' --转股协议存款
   AND T.ACCT_BALANCE<>0
       GROUP BY T.ORG_NUM,
                CASE
               WHEN MONTHS_BETWEEN(DATE(T.MATUR_DATE),DATE(I_DATADATE))  <= 12 THEN
                'G18_0_1.7.E.2022' --剩余期限-1年
               WHEN MONTHS_BETWEEN(DATE(T.MATUR_DATE),DATE(I_DATADATE)) >12 AND
                    MONTHS_BETWEEN(DATE(T.MATUR_DATE),DATE(I_DATADATE))  <= 60 THEN
                'G18_0_1.7.F.2022' --剩余期限-1-5年
               WHEN MONTHS_BETWEEN(DATE(T.MATUR_DATE),DATE(I_DATADATE)) > 60 AND
                    MONTHS_BETWEEN(DATE(T.MATUR_DATE),DATE(I_DATADATE)) <= 120 THEN
                'G18_0_1.7.G.2022' --剩余期限-5-10年
               WHEN MONTHS_BETWEEN(DATE(T.MATUR_DATE),DATE(I_DATADATE)) > 120 THEN
                'G18_0_1.7.H.2022' --剩余期限-10年以上
             END;
    COMMIT;

    --=================================================================================================================================-
    -------------------------------------------------------------------G18数据插至目标指标表--------------------------------------------
    --================================================================================================================================---

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生G18指标数据，插至目标表（二）';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

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
             'G18' AS REP_NUM,
             T.ITEM_NUM AS ITEM_NUM,
             SUM(NVL(T.FACE_VAL_RMB, 0)) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_G18_DATA_COLLECT_TMP T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM, T.ITEM_NUM;

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
   
END proc_cbrc_idx2_g18