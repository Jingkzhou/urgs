CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g0501(II_DATADATE  IN string --跑批日期
                                                 
                                                   )
/****************************** 
  @AUTHOR:DJH
  @CREATE-DATE:20220210
  @DESCRIPTION:G05 个人存贷款情况统计表
  @MODIFICATION HISTORY:
  M0.AUTHOR-CREATE_DATE-DESCRIPTION
  M1.20220210.DJH.2022制度升级,新增表
  M2.20220227.DJH.2023制度升级 新增1.8、1.8.1、1.9、 1.9.1项数据
  M3.20231011.ZJM.对涉及累放的指标进行开发，将村镇铺底数据逻辑放进去
  m4.20241105.shiyu.JLBA202410250008 修改内容：修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
                             如果是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款在逾期时间90天以内的取逾期部分，逾期90天以上的取贷款余额
  m5.20250327 shiyu 调整内容： 吴大为提出：07 教育 不属于1.1.6助学贷款，放到其他里
  

目标表：CBRC_A_REPT_ITEM_VAL
视图表：SMTMODS_V_PUB_IDX_DK_YSDQRJJ    
临时表：  CBRC_G05_DATA_COLLECT_TMP
      CBRC_G05_DATA_COLLECT_TMP_FACILITY
      CBRC_G05_DATA_COLLECT_TMP_TOTALBANK
      CBRC_G05_DATA_COLLECT_TMP_YQ
      CBRC_G05_DATA_COLLECT_TMP_CUP
      CBRC_G05_DATA_COLLECT_TMP_SORT
      CBRC_G05_DATA_COLLECT_TMP_VAL
      CBRC_G05_DATA_COLLECT_TMP_LOAN
      CBRC_G05_DATA_AMT_TMP1  --累放表按月累计
      CBRC_GXH_A_REPT_ITEM_RESULT_G05    --proc_cbrc_creditline_temp_g05 程序执行结果表
集市表：SMTMODS_L_ACCT_LOAN
     SMTMODS_L_AGRE_LOAN_CONTRACT
     SMTMODS_L_CUST_P
     SMTMODS_L_PUBL_RATE
     CBRC_CUP_G05_TMP1  银联数据落地表
     CBRC_CUP_G05_TMP2  银联数据落地表
     

  *******************************/
 IS
  --V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  string; --数据日期(数值型)YYYYMMDD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR(30);
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE := II_DATADATE;
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G0501');
    V_TAB_NAME  := 'G05';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
				
    V_STEP_ID   := 1;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']G05当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G05_DATA_COLLECT_TMP';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G05_DATA_COLLECT_TMP_FACILITY';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G05_DATA_COLLECT_TMP_TOTALBANK';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G05_DATA_COLLECT_TMP_YQ';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G05_DATA_COLLECT_TMP_CUP';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G05_DATA_COLLECT_TMP_SORT';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G05_DATA_COLLECT_TMP_VAL';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G05_DATA_COLLECT_TMP_LOAN';

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G05_I';

    COMMIT;
    
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：个人经营性逾期贷款小于90天余额预处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --逾期贷款预处理  处理方式同G0102
    --个人经营性
    --个人消费 还款方式 是 一次还本 取 贷款余额 否则 取 本金逾期金额

    --个人经营性 逾期<90天
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP_YQ 
      (DATA_DATE, ORG_NUM, LOAN_NUM, LOAN_ACCT_BAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       A.LOAN_NUM,
       SUM(NVL(LOAN_ACCT_BAL, 0) * U.CCY_RATE) AS LOAN_ACCT_BAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYS <= 90
         AND OD_DAYS > 0
         AND OD_FLG = 'Y'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND ORG_NUM <> '009803'
         AND ACCT_TYP LIKE '0102%' --个人经营性
       GROUP BY ORG_NUM, A.LOAN_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：个人经营性逾期贷款小于90天余额预处理结束';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：个人消费逾期贷款小于90天余额预处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --个人消费 逾期<90天 还款方式 是 一次还本 取 贷款余额 否则 取 本金逾期金额

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP_YQ 
      (DATA_DATE, ORG_NUM, LOAN_NUM, LOAN_ACCT_BAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       A.LOAN_NUM,
       /*alter by shiyu 20241105 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
       如果是按月分期还款的个人消费贷款本金或利息逾期 */
       SUM(CASE
             WHEN a.REPAY_TYP = '1' and a.PAY_TYPE in ('01', '02', '10', '11') then --还款方式按月JLBA202412040012
              OD_LOAN_ACCT_BAL * U.CCY_RATE
             ELSE
              LOAN_ACCT_BAL * U.CCY_RATE
           END) AS LOAN_ACCT_BAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYS > 0
         AND OD_DAYS <= 90
         AND OD_FLG = 'Y'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND ACCT_TYP NOT LIKE '0102%' --除个人经营性以外所有
         AND ACCT_TYP LIKE '01%' --个人贷款
         AND ORG_NUM <> '009803'
       GROUP BY ORG_NUM, A.LOAN_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：个人消费逾期贷款小于90天余额预处理结束';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：个人经营性、个人消费逾期贷款大于90天余额预处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --个人经营性、个人消费逾期>90天
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP_YQ 
      (DATA_DATE, ORG_NUM, LOAN_NUM, LOAN_ACCT_BAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       A.LOAN_NUM,
       SUM(NVL(LOAN_ACCT_BAL, 0) * U.CCY_RATE) AS LOAN_ACCT_BAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYS > 90
         AND OD_FLG = 'Y'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND ORG_NUM <> '009803'
         AND ACCT_TYP LIKE '01%' --个人贷款
       GROUP BY ORG_NUM, A.LOAN_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：个人经营性、个人消费逾期贷款大于90天预处理结束';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ----------------------------------------个人贷款合计(不含个人经营性贷款）----------------------------------------

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1 按贷款用途（各项贷款余额）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ----------------------------------------1.1 按贷款用途----------------------------------------
    -- 1.1 按贷款用途
    -- 1.1.1信用卡
    --       其中：1.1.1.1汽车分期
    --             1.1.1.2房屋装修分期
    -- 1.1.2至1.1.7各项贷款余额
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.GRXFDKYT = '05' THEN --1.1.2汽车
          'G05_I_1.1.2.A'
         WHEN A.GRXFDKYT IN ('01', '02') THEN --1.1.3住房按揭贷款
          'G05_I_1.1.3.A'
         WHEN A.GRXFDKYT = '03' THEN --1.1.4房屋装修贷款 modify by djh20240306 带装修字样都作为房屋装修
          'G05_I_1.1.4.A'
         WHEN A.GRXFDKYT = '04' THEN --1.1.5大件耐用消费品贷款
          'G05_I_1.1.5.A'
       -- WHEN A.GRXFDKYT = '07' THEN --1.1.6助学贷款
       --  'G05_I_1.1.6.A'      --m5.20250327 shiyu 调整内容： 07 教育不属于1.1.6助学贷款，放到其他里
         ELSE
          'G05_I_1.1.7.A'
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP LIKE '01%' --个人贷款
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.GRXFDKYT = '05' THEN --1.1.2汽车
                   'G05_I_1.1.2.A'
                  WHEN A.GRXFDKYT IN ('01', '02') THEN --1.1.3住房按揭贷款
                   'G05_I_1.1.3.A'
                  WHEN A.GRXFDKYT = '03' THEN --1.1.4房屋装修贷款 modify by djh20240306 带装修字样都作为房屋装修
                   'G05_I_1.1.4.A'
                  WHEN A.GRXFDKYT = '04' THEN --1.1.5大件耐用消费品贷款
                   'G05_I_1.1.5.A'
                -- WHEN A.GRXFDKYT = '07' THEN --1.1.6助学贷款
                --  'G05_I_1.1.6.A'
                  ELSE
                   'G05_I_1.1.7.A'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1 按贷款用途（各项贷款余额）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1 按贷款用途（不良贷款余额）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --不良贷款余额
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.GRXFDKYT = '05' THEN --1.1.2汽车
          'G05_I_1.1.2.B'
         WHEN A.GRXFDKYT IN ('01', '02') THEN --1.1.3住房按揭贷款
          'G05_I_1.1.3.B'
         WHEN A.GRXFDKYT = '03' THEN --1.1.4房屋装修贷款 modify by djh20240306 带装修字样都作为房屋装修
          'G05_I_1.1.4.B'
         WHEN A.GRXFDKYT = '04' THEN --1.1.5大件耐用消费品贷款
          'G05_I_1.1.5.B'
       --WHEN A.GRXFDKYT = '07' THEN --1.1.6助学贷款
       -- 'G05_I_1.1.6.B'   --m5.20250327 shiyu 调整内容： 07 教育不属于1.1.6助学贷款，放到其他里
         ELSE
          'G05_I_1.1.7.B'
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.GRXFDKYT = '05' THEN --1.1.2汽车
                   'G05_I_1.1.2.B'
                  WHEN A.GRXFDKYT IN ('01', '02') THEN --1.1.3住房按揭贷款
                   'G05_I_1.1.3.B'
                  WHEN A.GRXFDKYT = '03' THEN --1.1.4房屋装修贷款 modify by djh20240306 带装修字样都作为房屋装修
                   'G05_I_1.1.4.B'
                  WHEN A.GRXFDKYT = '04' THEN --1.1.5大件耐用消费品贷款
                   'G05_I_1.1.5.B'
                -- WHEN A.GRXFDKYT = '07' THEN --1.1.6助学贷款
                --  'G05_I_1.1.6.B'
                  ELSE
                   'G05_I_1.1.7.B'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1 按贷款用途（不良贷款余额）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1 按贷款用途（逾期贷款余额）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --逾期贷款余额
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.GRXFDKYT = '05' THEN --1.1.2汽车
          'G05_I_1.1.2.C'
         WHEN A.GRXFDKYT IN ('01', '02') THEN --1.1.3住房按揭贷款
          'G05_I_1.1.3.C'
         WHEN A.GRXFDKYT = '03' THEN --1.1.4房屋装修贷款 modify by djh20240306 带装修字样都作为房屋装修
          'G05_I_1.1.4.C'
         WHEN A.GRXFDKYT = '04' THEN --1.1.5大件耐用消费品贷款
          'G05_I_1.1.5.C'
       --WHEN A.GRXFDKYT = '07' THEN --1.1.6助学贷款
       -- 'G05_I_1.1.6.C'
         ELSE
          'G05_I_1.1.7.C'
       END AS ITEM_NUM,
       SUM(T.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN CBRC_G05_DATA_COLLECT_TMP_YQ T --逾期贷款余额(人民币)处理
          ON A.LOAN_NUM = T.LOAN_NUM
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.OD_FLG = 'Y' --逾期贷款
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.GRXFDKYT = '05' THEN --1.1.2汽车
                   'G05_I_1.1.2.C'
                  WHEN A.GRXFDKYT IN ('01', '02') THEN --1.1.3住房按揭贷款
                   'G05_I_1.1.3.C'
                  WHEN A.GRXFDKYT = '03' THEN --1.1.4房屋装修贷款 modify by djh20240306 带装修字样都作为房屋装修
                   'G05_I_1.1.4.C'
                  WHEN A.GRXFDKYT = '04' THEN --1.1.5大件耐用消费品贷款
                   'G05_I_1.1.5.C'
                -- WHEN A.GRXFDKYT = '07' THEN --1.1.6助学贷款
                --  'G05_I_1.1.6.C'
                  ELSE
                   'G05_I_1.1.7.C'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1 按贷款用途（逾期贷款余额）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1 按贷款用途（其中：逾期超过90天）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --其中：逾期超过90天
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.GRXFDKYT = '05' THEN --1.1.2汽车
          'G05_I_1.1.2.D'
         WHEN A.GRXFDKYT IN ('01', '02') THEN --1.1.3住房按揭贷款
          'G05_I_1.1.3.D'
         WHEN A.GRXFDKYT = '03' THEN --1.1.4房屋装修贷款 modify by djh20240306 带装修字样都作为房屋装修
          'G05_I_1.1.4.D'
         WHEN A.GRXFDKYT = '04' THEN --1.1.5大件耐用消费品贷款
          'G05_I_1.1.5.D'
       -- WHEN A.GRXFDKYT = '07' THEN --1.1.6助学贷款
       --  'G05_I_1.1.6.D'
         ELSE
          'G05_I_1.1.7.D'
       END AS ITEM_NUM,
       SUM(T.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN CBRC_G05_DATA_COLLECT_TMP_YQ T --逾期贷款余额(人民币)处理
          ON A.LOAN_NUM = T.LOAN_NUM
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.OD_DAYS > 90 --逾期超过90天
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.GRXFDKYT = '05' THEN --1.1.2汽车
                   'G05_I_1.1.2.D'
                  WHEN A.GRXFDKYT IN ('01', '02') THEN --1.1.3住房按揭贷款
                   'G05_I_1.1.3.D'
                  WHEN A.GRXFDKYT = '03' THEN --1.1.4房屋装修贷款 modify by djh20240306 带装修字样都作为房屋装修
                   'G05_I_1.1.4.D'
                  WHEN A.GRXFDKYT = '04' THEN --1.1.5大件耐用消费品贷款
                   'G05_I_1.1.5.D'
                --  WHEN A.GRXFDKYT = '07' THEN --1.1.6助学贷款
                --   'G05_I_1.1.6.D'
                  ELSE
                   'G05_I_1.1.7.D'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1 按贷款用途（其中：逾期超过90天）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.2 按年龄（各项贷款余额）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ----------------------------------------1.2 按年龄--------------------------------------------
    --先取身份证，再看是否有出生日期
    -- 1.2.1至1.2.5各项贷款余额
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND --101  第一代身份证 102  第二代身份证
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 55) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 55) THEN
          'G05_I_1.2.5.A'
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 45) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 45) THEN
          'G05_I_1.2.4.A'
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 35) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 35) THEN
          'G05_I_1.2.3.A'
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 25) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 25) THEN
          'G05_I_1.2.2.A'
         ELSE
          'G05_I_1.2.1.A'
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 55) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 55) THEN
                   'G05_I_1.2.5.A'
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 45) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 45) THEN
                   'G05_I_1.2.4.A'
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 35) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 35) THEN
                   'G05_I_1.2.3.A'
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 25) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 25) THEN
                   'G05_I_1.2.2.A'
                  ELSE
                   'G05_I_1.2.1.A'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.2 按年龄（各项贷款余额）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.2 按年龄（不良贷款余额）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    -- 1.2.1至1.2.5不良贷款余额
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 55) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 55) THEN
          'G05_I_1.2.5.B'
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 45) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 45) THEN
          'G05_I_1.2.4.B'
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 35) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 35) THEN
          'G05_I_1.2.3.B'
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 25) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 25) THEN
          'G05_I_1.2.2.B'
         ELSE
          'G05_I_1.2.1.B'
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 55) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 55) THEN
                   'G05_I_1.2.5.B'
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 45) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 45) THEN
                   'G05_I_1.2.4.B'
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 35) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 35) THEN
                   'G05_I_1.2.3.B'
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 25) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 25) THEN
                   'G05_I_1.2.2.B'
                  ELSE
                   'G05_I_1.2.1.B'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.2 按年龄（不良贷款余额）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.2 按年龄（逾期贷款余额）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    -- 1.2.1至1.2.5逾期贷款余额
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 55) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 55) THEN
          'G05_I_1.2.5.C'
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 45) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 45) THEN
          'G05_I_1.2.4.C'
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 35) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 35) THEN
          'G05_I_1.2.3.C'
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 25) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 25) THEN
          'G05_I_1.2.2.C'
         ELSE
          'G05_I_1.2.1.C'
       END AS ITEM_NUM,
       SUM(T.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN CBRC_G05_DATA_COLLECT_TMP_YQ T --逾期贷款余额(人民币)处理
          ON A.LOAN_NUM = T.LOAN_NUM
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.OD_FLG = 'Y' --逾期贷款
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 55) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 55) THEN
                   'G05_I_1.2.5.C'
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 45) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 45) THEN
                   'G05_I_1.2.4.C'
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 35) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 35) THEN
                   'G05_I_1.2.3.C'
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 25) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 25) THEN
                   'G05_I_1.2.2.C'
                  ELSE
                   'G05_I_1.2.1.C'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.2 按年龄（逾期贷款余额）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.2 按年龄（逾期超过90天 ）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    -- 1.2.1至1.2.5逾期超过90天 ,取借据余额
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 55) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 55) THEN
          'G05_I_1.2.5.D'
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 45) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 45) THEN
          'G05_I_1.2.4.D'
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 35) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 35) THEN
          'G05_I_1.2.3.D'
         WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
              SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 25) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 25) THEN
          'G05_I_1.2.2.D'
         ELSE
          'G05_I_1.2.1.D'
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.OD_DAYS > 90 --逾期超过90天
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 55) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 55) THEN
                   'G05_I_1.2.5.D'
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 45) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 45) THEN
                   'G05_I_1.2.4.D'
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 35) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 35) THEN
                   'G05_I_1.2.3.D'
                  WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                       SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) > 25) OR
                       (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                       SUBSTR(I_DATADATE, 1, 4) -
                       SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) > 25) THEN
                   'G05_I_1.2.2.D'
                  ELSE
                   'G05_I_1.2.1.D'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.2 按年龄（逾期超过90天）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(支行)统一授信临时表至G05_DATA_COLLECT_TMP_FACILITY中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ----------------------------------------1.3 按授信额度----------------------------------------
    --无统一授信的客户，按客户汇总，有借据的，取合同金额作为客户授信金额
    --DJH缺少信用卡授信，可能需要从银联取
    --支行、分行按照正常汇总处理，总行单独处理不走RESULT
    --支行，一个客户在不同支行授信额度可能不同，划分到不同格子中
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP_FACILITY  --统一授信临时表
      (DATA_DATE, CUST_ID, FACILITY_AMT, ORG_NUM, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.CUST_ID,
       SUM(C.CONTRACT_AMT * R.CCY_RATE) AS FACILITY_AMT,
       TT.ORG_NUM,
       '3' AS FLAG
        FROM SMTMODS_L_AGRE_LOAN_CONTRACT C
       INNER JOIN (SELECT T.ACCT_NUM, SUM(T.LOAN_ACCT_BAL), T.ORG_NUM
                     FROM SMTMODS_L_ACCT_LOAN T
                    WHERE T.DATA_DATE = I_DATADATE
                      AND T.ACCT_TYP NOT LIKE '0102%' --个人经营性标识
                      AND T.ACCT_TYP LIKE '01%' --个人贷款
                      AND T.CANCEL_FLG = 'N'
                      AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                      AND LENGTHB(T.ACCT_NUM) < 36
                      AND T.LOAN_ACCT_BAL <> 0
                    GROUP BY T.ACCT_NUM, T.ORG_NUM) TT
          ON C.CONTRACT_NUM = TT.ACCT_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE R --汇率表
          ON R.DATA_DATE = C.DATA_DATE
         AND R.BASIC_CCY = C.CURR_CD
         AND R.FORWARD_CCY = 'CNY'
       WHERE C.DATA_DATE = I_DATADATE
      --AND C.ACCT_STS = '1'  add by djh 20231007 无效合同也增加进去，根据贷款借据HHD
       GROUP BY C.CUST_ID, TT.ORG_NUM;

    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(支行)统一授信临时表至G05_DATA_COLLECT_TMP_FACILITY中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(支行)各项贷款至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN B.ORG_NUM LIKE '%98%' THEN --网点需要把明细汇总成支行
          B.ORG_NUM
         WHEN B.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
          '060300'
         ELSE
          SUBSTR(B.ORG_NUM, 1, 4) || '00'
       END,
       CASE
         WHEN B.FACILITY_AMT >= 1000000 THEN
          'G05_I_1.3.5.A'
         WHEN B.FACILITY_AMT >= 500000 THEN
          'G05_I_1.3.4.A'
         WHEN B.FACILITY_AMT > 300000 THEN
          'G05_I_1.3.3.A'
         WHEN B.FACILITY_AMT > 100000 THEN
          'G05_I_1.3.2.A'
         ELSE
          'G05_I_1.3.1.A'
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       INNER JOIN CBRC_G05_DATA_COLLECT_TMP_FACILITY B
          ON A.CUST_ID = B.CUST_ID
         AND A.ORG_NUM = B.ORG_NUM --客户可能在不同机构有贷款
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP LIKE '01%' --个人贷款
       GROUP BY CASE
                  WHEN B.ORG_NUM LIKE '%98%' THEN --网点需要把明细汇总成支行
                   B.ORG_NUM
                  WHEN B.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(B.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN B.FACILITY_AMT >= 1000000 THEN
                   'G05_I_1.3.5.A'
                  WHEN B.FACILITY_AMT >= 500000 THEN
                   'G05_I_1.3.4.A'
                  WHEN B.FACILITY_AMT > 300000 THEN
                   'G05_I_1.3.3.A'
                  WHEN B.FACILITY_AMT > 100000 THEN
                   'G05_I_1.3.2.A'
                  ELSE
                   'G05_I_1.3.1.A'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(支行)各项贷款至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(支行)不良贷款至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN B.ORG_NUM LIKE '%98%' THEN --网点需要把明细汇总成支行
          B.ORG_NUM
         WHEN B.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
          '060300'
         ELSE
          SUBSTR(B.ORG_NUM, 1, 4) || '00'
       END,
       CASE
         WHEN B.FACILITY_AMT >= 1000000 THEN
          'G05_I_1.3.5.B'
         WHEN B.FACILITY_AMT >= 500000 THEN
          'G05_I_1.3.4.B'
         WHEN B.FACILITY_AMT > 300000 THEN
          'G05_I_1.3.3.B'
         WHEN B.FACILITY_AMT > 100000 THEN
          'G05_I_1.3.2.B'
         ELSE
          'G05_I_1.3.1.B'
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       INNER JOIN CBRC_G05_DATA_COLLECT_TMP_FACILITY B
          ON A.CUST_ID = B.CUST_ID
         AND A.ORG_NUM = B.ORG_NUM --客户可能在不同机构有贷款
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
       GROUP BY CASE
                  WHEN B.ORG_NUM LIKE '%98%' THEN --网点需要把明细汇总成支行
                   B.ORG_NUM
                  WHEN B.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(B.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN B.FACILITY_AMT >= 1000000 THEN
                   'G05_I_1.3.5.B'
                  WHEN B.FACILITY_AMT >= 500000 THEN
                   'G05_I_1.3.4.B'
                  WHEN B.FACILITY_AMT > 300000 THEN
                   'G05_I_1.3.3.B'
                  WHEN B.FACILITY_AMT > 100000 THEN
                   'G05_I_1.3.2.B'
                  ELSE
                   'G05_I_1.3.1.B'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(支行)不良贷款至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(支行)逾期贷款至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN B.ORG_NUM LIKE '%98%' THEN --网点需要把明细汇总成支行
          B.ORG_NUM
         WHEN B.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
          '060300'
         ELSE
          SUBSTR(B.ORG_NUM, 1, 4) || '00'
       END,
       CASE
         WHEN B.FACILITY_AMT >= 1000000 THEN
          'G05_I_1.3.5.C'
         WHEN B.FACILITY_AMT >= 500000 THEN
          'G05_I_1.3.4.C'
         WHEN B.FACILITY_AMT > 300000 THEN
          'G05_I_1.3.3.C'
         WHEN B.FACILITY_AMT > 100000 THEN
          'G05_I_1.3.2.C'
         ELSE
          'G05_I_1.3.1.C'
       END AS ITEM_NUM,
       SUM(T.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN CBRC_G05_DATA_COLLECT_TMP_YQ T --逾期贷款余额(人民币)处理
          ON A.LOAN_NUM = T.LOAN_NUM
       INNER JOIN CBRC_G05_DATA_COLLECT_TMP_FACILITY B
          ON A.CUST_ID = B.CUST_ID
         AND A.ORG_NUM = B.ORG_NUM --客户可能在不同机构有贷款
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.OD_FLG = 'Y' --逾期贷款
       GROUP BY CASE
                  WHEN B.ORG_NUM LIKE '%98%' THEN --网点需要把明细汇总成支行
                   B.ORG_NUM
                  WHEN B.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(B.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN B.FACILITY_AMT >= 1000000 THEN
                   'G05_I_1.3.5.C'
                  WHEN B.FACILITY_AMT >= 500000 THEN
                   'G05_I_1.3.4.C'
                  WHEN B.FACILITY_AMT > 300000 THEN
                   'G05_I_1.3.3.C'
                  WHEN B.FACILITY_AMT > 100000 THEN
                   'G05_I_1.3.2.C'
                  ELSE
                   'G05_I_1.3.1.C'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(支行)逾期贷款至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(支行)逾期超过90天至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN B.ORG_NUM LIKE '%98%' THEN --网点需要把明细汇总成支行
          B.ORG_NUM
         WHEN B.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
          '060300'
         ELSE
          SUBSTR(B.ORG_NUM, 1, 4) || '00'
       END,
       CASE
         WHEN B.FACILITY_AMT >= 1000000 THEN
          'G05_I_1.3.5.D'
         WHEN B.FACILITY_AMT >= 500000 THEN
          'G05_I_1.3.4.D'
         WHEN B.FACILITY_AMT > 300000 THEN
          'G05_I_1.3.3.D'
         WHEN B.FACILITY_AMT > 100000 THEN
          'G05_I_1.3.2.D'
         ELSE
          'G05_I_1.3.1.D'
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       INNER JOIN CBRC_G05_DATA_COLLECT_TMP_FACILITY B
          ON A.CUST_ID = B.CUST_ID
         AND A.ORG_NUM = B.ORG_NUM --客户可能在不同机构有贷款
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.OD_DAYS > 90 --逾期超过90天
       GROUP BY CASE
                  WHEN B.ORG_NUM LIKE '%98%' THEN --网点需要把明细汇总成支行
                   B.ORG_NUM
                  WHEN B.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(B.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN B.FACILITY_AMT >= 1000000 THEN
                   'G05_I_1.3.5.D'
                  WHEN B.FACILITY_AMT >= 500000 THEN
                   'G05_I_1.3.4.D'
                  WHEN B.FACILITY_AMT > 300000 THEN
                   'G05_I_1.3.3.D'
                  WHEN B.FACILITY_AMT > 100000 THEN
                   'G05_I_1.3.2.D'
                  ELSE
                   'G05_I_1.3.1.D'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(支行)逾期超过90天至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(分行)至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -----------------------------------------------------------------------------------

    --此处处理 1.3 按授信额度(分行)，按照支行汇总
    PROC_CBRC_CREDITLINE_TEMP_G05(I_DATADATE); --参考机构汇总 SP_A_REPT_ITEM_RESULT

    --将处理后的支行到分行汇总反插入表中
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL
        FROM CBRC_GXH_A_REPT_ITEM_RESULT_G05;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(分行)至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)至G05_DATA_COLLECT_TMP_LOAN中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ----------------------------------------------------------------------------

    -----ADD BY DJH 20220325  信用卡数据
    /* 客户表数据一个证件号存在多个客户号，
    1、关联有借据优先，即同时有信用卡+贷款，取那个客户号，如果两个取ID更大的
    2、无借据，只办理信用卡*/

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP_LOAN 
      (CUST_ID)
      SELECT 
      DISTINCT CUST_ID
        FROM SMTMODS_L_ACCT_LOAN A
       WHERE DATA_DATE = I_DATADATE
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36;

    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)至G05_DATA_COLLECT_TMP_LOAN中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)至G05_DATA_COLLECT_TMP_SORT中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP_SORT 
      (ID_NO, CUST_ID)
      SELECT ID_NO, CUST_ID
        FROM (SELECT 
               T2.ID_NO,
               T2.CUST_ID,
               ROW_NUMBER() OVER(PARTITION BY T2.ID_NO ORDER BY T2.CUST_ID DESC) AS NUM
                FROM SMTMODS_L_CUST_P T2
               INNER JOIN CBRC_G05_DATA_COLLECT_TMP_LOAN T3
                  ON T2.CUST_ID = T3.CUST_ID
               WHERE T2.DATA_DATE = I_DATADATE)
       WHERE NUM = 1;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)至G05_DATA_COLLECT_TMP_SORT中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)至G05_DATA_COLLECT_TMP_FACILITY中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP_FACILITY  --统一授信临时表
      (DATA_DATE,
       CUST_ID,
       FACILITY_AMT,
       ORG_NUM,
       LOAN_BAL,
       BAD_LOAN_BAL,
       OVERDUE_LOAN_BAL,
       OVER_LOAN_BAL,
       FLAG)

      SELECT I_DATADATE,
             T.ID_NO,
             SUM(TO_NUMBER(TRANSLATE(T.CREDIT_LOAN,
                                     '-.1234567890' || T.CREDIT_LOAN,
                                     '-.1234567890')) * 10000), --有非法字符，字符串转数值，且万元换算成元
             '009803' AS ORG_NUM,
             SUM(TO_NUMBER(LOAN_BAL) * 10000),
             SUM(TO_NUMBER(BAD_LOAN_BAL) * 10000),
             SUM(TO_NUMBER(OVERDUE_LOAN_BAL) * 10000),
             SUM(TO_NUMBER(OVER_LOAN_BAL) * 10000),
             '1' AS FLAG
        FROM CBRC_CUP_G05_TMP1 T
        LEFT JOIN CBRC_G05_DATA_COLLECT_TMP_SORT T1
          ON T.ID_NO = T1.ID_NO
       WHERE T1.CUST_ID IS NULL
         AND replace(t.data_date, chr(13), '') = I_DATADATE
       GROUP BY T.ID_NO
      UNION ALL
      SELECT I_DATADATE,
             T1.CUST_ID,
             SUM(TO_NUMBER(TRANSLATE(T.CREDIT_LOAN,
                                     '-.1234567890' || T.CREDIT_LOAN,
                                     '-.1234567890')) * 10000), --有非法字符，字符串转数值，且万元换算成元
             '009803' AS ORG_NUM,
             SUM(TO_NUMBER(LOAN_BAL) * 10000),
             SUM(TO_NUMBER(BAD_LOAN_BAL) * 10000),
             SUM(TO_NUMBER(OVERDUE_LOAN_BAL) * 10000),
             SUM(TO_NUMBER(OVER_LOAN_BAL) * 10000),
             '2' AS FLAG
        FROM CBRC_CUP_G05_TMP1 T
        LEFT JOIN CBRC_G05_DATA_COLLECT_TMP_SORT T1
          ON T.ID_NO = T1.ID_NO
       WHERE T1.CUST_ID IS NOT NULL
         AND replace(t.data_date, chr(13), '') = I_DATADATE
       GROUP BY T1.CUST_ID;

    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)至G05_DATA_COLLECT_TMP_FACILITY中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)至G05_DATA_COLLECT_TMP_TOTALBANK中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    -------ADD BY DJH 20220325

    --总行，授信（贷款），统一按照客户所有合同
    INSERT INTO CBRC_G05_DATA_COLLECT_TMP_TOTALBANK
      (DATA_DATE,
       CUST_ID,
       ORG_NUM,
       FACILITY_AMT,
       LOAN_BAL,
       BAD_LOAN_BAL,
       OVERDUE_LOAN_BAL,
       OVER_LOAN_BAL)
      SELECT DATA_DATE,
             CUST_ID,
             CASE
               WHEN B.ORG_NUM LIKE '5100%' THEN
                '510000'
               WHEN B.ORG_NUM LIKE '5200%' THEN
                '520000'
               WHEN B.ORG_NUM LIKE '5300%' THEN
                '530000'
               WHEN B.ORG_NUM LIKE '5400%' THEN
                '540000'
               WHEN B.ORG_NUM LIKE '5500%' THEN
                '550000'
               WHEN B.ORG_NUM LIKE '5600%' THEN
                '560000'
               WHEN B.ORG_NUM LIKE '5700%' THEN
                '570000'
               WHEN B.ORG_NUM LIKE '5800%' THEN
                '580000'
               WHEN B.ORG_NUM LIKE '5900%' THEN
                '590000'
               WHEN B.ORG_NUM LIKE '6000%' THEN
                '600000'
               ELSE
                '990000'
             END AS ORG_NUM,
             SUM(FACILITY_AMT),
             SUM(LOAN_BAL),
             SUM(BAD_LOAN_BAL),
             SUM(OVERDUE_LOAN_BAL),
             SUM(OVER_LOAN_BAL)
        FROM CBRC_G05_DATA_COLLECT_TMP_FACILITY B
       WHERE FLAG = '3' --去掉不在借据中的信用卡客户
       GROUP BY CUST_ID,
                CASE
                  WHEN B.ORG_NUM LIKE '5100%' THEN
                   '510000'
                  WHEN B.ORG_NUM LIKE '5200%' THEN
                   '520000'
                  WHEN B.ORG_NUM LIKE '5300%' THEN
                   '530000'
                  WHEN B.ORG_NUM LIKE '5400%' THEN
                   '540000'
                  WHEN B.ORG_NUM LIKE '5500%' THEN
                   '550000'
                  WHEN B.ORG_NUM LIKE '5600%' THEN
                   '560000'
                  WHEN B.ORG_NUM LIKE '5700%' THEN
                   '570000'
                  WHEN B.ORG_NUM LIKE '5800%' THEN
                   '580000'
                  WHEN B.ORG_NUM LIKE '5900%' THEN
                   '590000'
                  WHEN B.ORG_NUM LIKE '6000%' THEN
                   '600000'
                  ELSE
                   '990000'
                END,
                DATA_DATE;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)至G05_DATA_COLLECT_TMP_TOTALBANK中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)至G05_DATA_COLLECT_TMP_CUP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --不在借据表中的信用卡客户单独处理
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP_CUP
      (DATA_DATE,
       CUST_ID,
       ORG_NUM,
       FACILITY_AMT,
       LOAN_BAL,
       BAD_LOAN_BAL,
       OVERDUE_LOAN_BAL,
       OVER_LOAN_BAL)
      SELECT DATA_DATE,
             CUST_ID,
             ORG_NUM,
             SUM(FACILITY_AMT),
             SUM(LOAN_BAL),
             SUM(BAD_LOAN_BAL),
             SUM(OVERDUE_LOAN_BAL),
             SUM(OVER_LOAN_BAL)
        FROM CBRC_G05_DATA_COLLECT_TMP_FACILITY
       WHERE FLAG = '1'
       GROUP BY CUST_ID, DATA_DATE, ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)至G05_DATA_COLLECT_TMP_CUP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)各项贷款至G05_DATA_COLLECT_TMP_VAL中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --合并有贷款且有信用卡的客户
    --贷款余额
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP_VAL 
      (CUST_ID, ORG_NUM, LOAN_ACCT_BAL, FACILITY_AMT, FLAG)
      SELECT CUST_ID,
             ORG_NUM,
             SUM(LOAN_ACCT_BAL) LOAN_ACCT_BAL,
             SUM(FACILITY_AMT) AS FACILITY_AMT,
             'A' AS FLAG
        FROM (SELECT 
               A.CUST_ID,
               CASE
                 WHEN A.ORG_NUM LIKE '5100%' THEN
                  '510000'
                 WHEN A.ORG_NUM LIKE '5200%' THEN
                  '520000'
                 WHEN A.ORG_NUM LIKE '5300%' THEN
                  '530000'
                 WHEN A.ORG_NUM LIKE '5400%' THEN
                  '540000'
                 WHEN A.ORG_NUM LIKE '5500%' THEN
                  '550000'
                 WHEN A.ORG_NUM LIKE '5600%' THEN
                  '560000'
                 WHEN A.ORG_NUM LIKE '5700%' THEN
                  '570000'
                 WHEN A.ORG_NUM LIKE '5800%' THEN
                  '580000'
                 WHEN A.ORG_NUM LIKE '5900%' THEN
                  '590000'
                 WHEN A.ORG_NUM LIKE '6000%' THEN
                  '600000'
                 ELSE
                  '990000'
               END AS ORG_NUM,
               A.LOAN_ACCT_BAL * TT.CCY_RATE AS LOAN_ACCT_BAL,
               B.FACILITY_AMT
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN CBRC_G05_DATA_COLLECT_TMP_TOTALBANK B
                  ON A.CUST_ID = B.CUST_ID --按照每个客户的授信额度
                LEFT JOIN SMTMODS_L_PUBL_RATE TT
                  ON TT.DATA_DATE = A.DATA_DATE
                 AND TT.BASIC_CCY = A.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               INNER JOIN CBRC_G05_DATA_COLLECT_TMP_FACILITY K --要存在于授信表中
                  ON A.CUST_ID = K.CUST_ID
                 AND A.ORG_NUM = K.ORG_NUM
                 AND K.FLAG = '3'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
                 AND A.CANCEL_FLG = 'N'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                 AND LENGTHB(A.ACCT_NUM) < 36
                    /*AND A.ORG_NUM NOT LIKE '5100%'*/ --add 刘晟典
                 AND A.ACCT_TYP LIKE '01%' --个人贷款
              UNION ALL
              SELECT T.CUST_ID,
                     CASE
                       WHEN T.ORG_NUM LIKE '5100%' THEN
                        '510000'
                       WHEN T.ORG_NUM LIKE '5200%' THEN
                        '520000'
                       WHEN T.ORG_NUM LIKE '5300%' THEN
                        '530000'
                       WHEN T.ORG_NUM LIKE '5400%' THEN
                        '540000'
                       WHEN T.ORG_NUM LIKE '5500%' THEN
                        '550000'
                       WHEN T.ORG_NUM LIKE '5600%' THEN
                        '560000'
                       WHEN T.ORG_NUM LIKE '5700%' THEN
                        '570000'
                       WHEN T.ORG_NUM LIKE '5800%' THEN
                        '580000'
                       WHEN T.ORG_NUM LIKE '5900%' THEN
                        '590000'
                       WHEN T.ORG_NUM LIKE '6000%' THEN
                        '600000'
                       ELSE
                        '990000'
                     END AS ORG_NUM,
                     T.LOAN_BAL AS LOAN_ACCT_BAL,
                     T.FACILITY_AMT
                FROM CBRC_G05_DATA_COLLECT_TMP_FACILITY T
               WHERE FLAG = '2')
       GROUP BY CUST_ID, ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)各项贷款至G05_DATA_COLLECT_TMP_VAL中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)不良贷款余额至G05_DATA_COLLECT_TMP_VAL中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --不良贷款余额
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP_VAL 
      (CUST_ID, ORG_NUM, LOAN_ACCT_BAL, FACILITY_AMT, FLAG)
      SELECT CUST_ID,
             ORG_NUM,
             SUM(LOAN_ACCT_BAL) LOAN_ACCT_BAL,
             SUM(FACILITY_AMT) AS FACILITY_AMT,
             'B' AS FLAG
        FROM (SELECT 
               A.CUST_ID,
               A.ORG_NUM,
               A.LOAN_ACCT_BAL * TT.CCY_RATE AS LOAN_ACCT_BAL,
               B.FACILITY_AMT
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN CBRC_G05_DATA_COLLECT_TMP_TOTALBANK B
                  ON A.CUST_ID = B.CUST_ID --按照每个客户的授信额度
                LEFT JOIN SMTMODS_L_PUBL_RATE TT
                  ON TT.DATA_DATE = A.DATA_DATE
                 AND TT.BASIC_CCY = A.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               INNER JOIN CBRC_G05_DATA_COLLECT_TMP_FACILITY K
                  ON A.CUST_ID = K.CUST_ID
                 AND A.ORG_NUM = K.ORG_NUM
                 AND K.FLAG = '3'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
                 AND A.CANCEL_FLG = 'N'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                 AND LENGTHB(A.ACCT_NUM) < 36
                 AND A.ACCT_TYP LIKE '01%' --个人贷款
                 AND A.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
              UNION ALL
              SELECT T.CUST_ID,
                     T.ORG_NUM,
                     T.BAD_LOAN_BAL AS LOAN_ACCT_BAL,
                     T.FACILITY_AMT
                FROM CBRC_G05_DATA_COLLECT_TMP_FACILITY T
               WHERE FLAG = '2')
       GROUP BY CUST_ID, ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)不良贷款至G05_DATA_COLLECT_TMP_VAL中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)逾期贷款余额至G05_DATA_COLLECT_TMP_VAL中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --逾期贷款余额
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP_VAL 
      (CUST_ID, ORG_NUM, LOAN_ACCT_BAL, FACILITY_AMT, FLAG)
      SELECT CUST_ID,
             ORG_NUM,
             SUM(LOAN_ACCT_BAL) LOAN_ACCT_BAL,
             SUM(FACILITY_AMT) AS FACILITY_AMT,
             'C' AS FLAG
        FROM (SELECT 
               A.CUST_ID,
               A.ORG_NUM,
               T.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
               B.FACILITY_AMT
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN CBRC_G05_DATA_COLLECT_TMP_TOTALBANK B
                  ON A.CUST_ID = B.CUST_ID --按照每个客户的授信额度
               INNER JOIN CBRC_G05_DATA_COLLECT_TMP_YQ T --逾期贷款余额(人民币)处理
                  ON A.LOAN_NUM = T.LOAN_NUM
               INNER JOIN CBRC_G05_DATA_COLLECT_TMP_FACILITY K
                  ON A.CUST_ID = K.CUST_ID
                 AND A.ORG_NUM = K.ORG_NUM
                 AND K.FLAG = '3'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
                 AND A.CANCEL_FLG = 'N'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                 AND LENGTHB(A.ACCT_NUM) < 36
                 AND A.ACCT_TYP LIKE '01%' --个人贷款
                 AND A.OD_FLG = 'Y' --逾期贷款
              UNION ALL
              SELECT T.CUST_ID,
                     T.ORG_NUM,
                     T.OVERDUE_LOAN_BAL AS LOAN_ACCT_BAL,
                     T.FACILITY_AMT
                FROM CBRC_G05_DATA_COLLECT_TMP_FACILITY T
               WHERE FLAG = '2')
       GROUP BY CUST_ID, ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)逾期贷款余额至G05_DATA_COLLECT_TMP_VAL中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)逾期90天以上贷款余额至G05_DATA_COLLECT_TMP_VAL中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --逾期90天以上贷款余额
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP_VAL 
      (CUST_ID, ORG_NUM, LOAN_ACCT_BAL, FACILITY_AMT, FLAG)
      SELECT CUST_ID,
             ORG_NUM,
             SUM(LOAN_ACCT_BAL) LOAN_ACCT_BAL,
             SUM(FACILITY_AMT) AS FACILITY_AMT,
             'D' AS FLAG
        FROM (SELECT 
               A.CUST_ID,
               A.ORG_NUM,
               A.LOAN_ACCT_BAL * TT.CCY_RATE AS LOAN_ACCT_BAL,
               B.FACILITY_AMT
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN CBRC_G05_DATA_COLLECT_TMP_TOTALBANK B
                  ON A.CUST_ID = B.CUST_ID --按照每个客户的授信额度
                LEFT JOIN SMTMODS_L_PUBL_RATE TT
                  ON TT.DATA_DATE = A.DATA_DATE
                 AND TT.BASIC_CCY = A.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               INNER JOIN CBRC_G05_DATA_COLLECT_TMP_FACILITY K
                  ON A.CUST_ID = K.CUST_ID
                 AND A.ORG_NUM = K.ORG_NUM
                 AND K.FLAG = '3'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
                 AND A.CANCEL_FLG = 'N'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                 AND LENGTHB(A.ACCT_NUM) < 36
                 AND A.ACCT_TYP LIKE '01%' --个人贷款
                 AND A.OD_DAYS > 90 --逾期超过90天
              UNION ALL
              SELECT T.CUST_ID,
                     T.ORG_NUM,
                    T.OVER_LOAN_BAL AS LOAN_ACCT_BAL,
                     T.FACILITY_AMT
                FROM CBRC_G05_DATA_COLLECT_TMP_FACILITY T
               WHERE FLAG = '2')
       GROUP BY CUST_ID, ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)逾期90天以上贷款余额至G05_DATA_COLLECT_TMP_VAL中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN B.ORG_NUM LIKE '5100%' THEN
          '510000'
         WHEN B.ORG_NUM LIKE '5200%' THEN
          '520000'
         WHEN B.ORG_NUM LIKE '5300%' THEN
          '530000'
         WHEN B.ORG_NUM LIKE '5400%' THEN
          '540000'
         WHEN B.ORG_NUM LIKE '5500%' THEN
          '550000'
         WHEN B.ORG_NUM LIKE '5600%' THEN
          '560000'
         WHEN B.ORG_NUM LIKE '5700%' THEN
          '570000'
         WHEN B.ORG_NUM LIKE '5800%' THEN
          '580000'
         WHEN B.ORG_NUM LIKE '5900%' THEN
          '590000'
         WHEN B.ORG_NUM LIKE '6000%' THEN
          '600000'
         ELSE
          '990000'
       END AS ORG_NUM,
       /*'990000' AS ORG_NUM, */ --modify by djh 20221014 机构变更000000->990000
       CASE
         WHEN B.FACILITY_AMT >= 1000000 THEN
          'G05_I_1.3.5.A'
         WHEN B.FACILITY_AMT >= 500000 THEN
          'G05_I_1.3.4.A'
         WHEN B.FACILITY_AMT > 300000 THEN
          'G05_I_1.3.3.A'
         WHEN B.FACILITY_AMT > 100000 THEN
          'G05_I_1.3.2.A'
         ELSE
          'G05_I_1.3.1.A'
       END AS ITEM_NUM,
       SUM(B.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL_RMB
        FROM CBRC_G05_DATA_COLLECT_TMP_VAL B
       WHERE B.FLAG = 'A'
       GROUP BY CASE
                  WHEN B.ORG_NUM LIKE '5100%' THEN
                   '510000'
                  WHEN B.ORG_NUM LIKE '5200%' THEN
                   '520000'
                  WHEN B.ORG_NUM LIKE '5300%' THEN
                   '530000'
                  WHEN B.ORG_NUM LIKE '5400%' THEN
                   '540000'
                  WHEN B.ORG_NUM LIKE '5500%' THEN
                   '550000'
                  WHEN B.ORG_NUM LIKE '5600%' THEN
                   '560000'
                  WHEN B.ORG_NUM LIKE '5700%' THEN
                   '570000'
                  WHEN B.ORG_NUM LIKE '5800%' THEN
                   '580000'
                  WHEN B.ORG_NUM LIKE '5900%' THEN
                   '590000'
                  WHEN B.ORG_NUM LIKE '6000%' THEN
                   '600000'
                  ELSE
                   '990000'
                END,
                CASE
                  WHEN B.FACILITY_AMT >= 1000000 THEN
                   'G05_I_1.3.5.A'
                  WHEN B.FACILITY_AMT >= 500000 THEN
                   'G05_I_1.3.4.A'
                  WHEN B.FACILITY_AMT > 300000 THEN
                   'G05_I_1.3.3.A'
                  WHEN B.FACILITY_AMT > 100000 THEN
                   'G05_I_1.3.2.A'
                  ELSE
                   'G05_I_1.3.1.A'
                END
      UNION ALL
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN B.ORG_NUM LIKE '5100%' THEN
          '510000'
         WHEN B.ORG_NUM LIKE '5200%' THEN
          '520000'
         WHEN B.ORG_NUM LIKE '5300%' THEN
          '530000'
         WHEN B.ORG_NUM LIKE '5400%' THEN
          '540000'
         WHEN B.ORG_NUM LIKE '5500%' THEN
          '550000'
         WHEN B.ORG_NUM LIKE '5600%' THEN
          '560000'
         WHEN B.ORG_NUM LIKE '5700%' THEN
          '570000'
         WHEN B.ORG_NUM LIKE '5800%' THEN
          '580000'
         WHEN B.ORG_NUM LIKE '5900%' THEN
          '590000'
         WHEN B.ORG_NUM LIKE '6000%' THEN
          '600000'
         ELSE
          '990000'
       END AS ORG_NUM,
       /*'990000' AS ORG_NUM,*/ --modify by djh 20221014 机构变更000000->990000
       CASE
         WHEN B.FACILITY_AMT >= 1000000 THEN
          'G05_I_1.3.5.A'
         WHEN B.FACILITY_AMT >= 500000 THEN
          'G05_I_1.3.4.A'
         WHEN B.FACILITY_AMT > 300000 THEN
          'G05_I_1.3.3.A'
         WHEN B.FACILITY_AMT > 100000 THEN
          'G05_I_1.3.2.A'
         ELSE
          'G05_I_1.3.1.A'
       END AS ITEM_NUM,
       SUM(B.LOAN_BAL) AS LOAN_ACCT_BAL_RMB
        FROM CBRC_G05_DATA_COLLECT_TMP_CUP B
       GROUP BY CASE
                  WHEN B.ORG_NUM LIKE '5100%' THEN
                   '510000'
                  WHEN B.ORG_NUM LIKE '5200%' THEN
                   '520000'
                  WHEN B.ORG_NUM LIKE '5300%' THEN
                   '530000'
                  WHEN B.ORG_NUM LIKE '5400%' THEN
                   '540000'
                  WHEN B.ORG_NUM LIKE '5500%' THEN
                   '550000'
                  WHEN B.ORG_NUM LIKE '5600%' THEN
                   '560000'
                  WHEN B.ORG_NUM LIKE '5700%' THEN
                   '570000'
                  WHEN B.ORG_NUM LIKE '5800%' THEN
                   '580000'
                  WHEN B.ORG_NUM LIKE '5900%' THEN
                   '590000'
                  WHEN B.ORG_NUM LIKE '6000%' THEN
                   '600000'
                  ELSE
                   '990000'
                END,
                CASE
                  WHEN B.FACILITY_AMT >= 1000000 THEN
                   'G05_I_1.3.5.A'
                  WHEN B.FACILITY_AMT >= 500000 THEN
                   'G05_I_1.3.4.A'
                  WHEN B.FACILITY_AMT > 300000 THEN
                   'G05_I_1.3.3.A'
                  WHEN B.FACILITY_AMT > 100000 THEN
                   'G05_I_1.3.2.A'
                  ELSE
                   'G05_I_1.3.1.A'
                END;
    COMMIT;

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN B.ORG_NUM LIKE '5100%' THEN
          '510000'
         WHEN B.ORG_NUM LIKE '5200%' THEN
          '520000'
         WHEN B.ORG_NUM LIKE '5300%' THEN
          '530000'
         WHEN B.ORG_NUM LIKE '5400%' THEN
          '540000'
         WHEN B.ORG_NUM LIKE '5500%' THEN
          '550000'
         WHEN B.ORG_NUM LIKE '5600%' THEN
          '560000'
         WHEN B.ORG_NUM LIKE '5700%' THEN
          '570000'
         WHEN B.ORG_NUM LIKE '5800%' THEN
          '580000'
         WHEN B.ORG_NUM LIKE '5900%' THEN
          '590000'
         WHEN B.ORG_NUM LIKE '6000%' THEN
          '600000'
         ELSE
          '990000'
       END AS ORG_NUM,
       /*'990000' AS ORG_NUM,*/ --modify by djh 20221014 机构变更000000->990000
       CASE
         WHEN B.FACILITY_AMT >= 1000000 THEN
          'G05_I_1.3.5.B'
         WHEN B.FACILITY_AMT >= 500000 THEN
          'G05_I_1.3.4.B'
         WHEN B.FACILITY_AMT > 300000 THEN
          'G05_I_1.3.3.B'
         WHEN B.FACILITY_AMT > 100000 THEN
          'G05_I_1.3.2.B'
         ELSE
          'G05_I_1.3.1.B'
       END AS ITEM_NUM,
       SUM(B.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL_RMB
        FROM CBRC_G05_DATA_COLLECT_TMP_VAL B
       WHERE B.FLAG = 'B'
       GROUP BY CASE
                  WHEN B.ORG_NUM LIKE '5100%' THEN
                   '510000'
                  WHEN B.ORG_NUM LIKE '5200%' THEN
                   '520000'
                  WHEN B.ORG_NUM LIKE '5300%' THEN
                   '530000'
                  WHEN B.ORG_NUM LIKE '5400%' THEN
                   '540000'
                  WHEN B.ORG_NUM LIKE '5500%' THEN
                   '550000'
                  WHEN B.ORG_NUM LIKE '5600%' THEN
                   '560000'
                  WHEN B.ORG_NUM LIKE '5700%' THEN
                   '570000'
                  WHEN B.ORG_NUM LIKE '5800%' THEN
                   '580000'
                  WHEN B.ORG_NUM LIKE '5900%' THEN
                   '590000'
                  WHEN B.ORG_NUM LIKE '6000%' THEN
                   '600000'
                  ELSE
                   '990000'
                END,
                CASE
                  WHEN B.FACILITY_AMT >= 1000000 THEN
                   'G05_I_1.3.5.B'
                  WHEN B.FACILITY_AMT >= 500000 THEN
                   'G05_I_1.3.4.B'
                  WHEN B.FACILITY_AMT > 300000 THEN
                   'G05_I_1.3.3.B'
                  WHEN B.FACILITY_AMT > 100000 THEN
                   'G05_I_1.3.2.B'
                  ELSE
                   'G05_I_1.3.1.B'
                END

      UNION ALL
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN B.ORG_NUM LIKE '5100%' THEN
          '510000'
         WHEN B.ORG_NUM LIKE '5200%' THEN
          '520000'
         WHEN B.ORG_NUM LIKE '5300%' THEN
          '530000'
         WHEN B.ORG_NUM LIKE '5400%' THEN
          '540000'
         WHEN B.ORG_NUM LIKE '5500%' THEN
          '550000'
         WHEN B.ORG_NUM LIKE '5600%' THEN
          '560000'
         WHEN B.ORG_NUM LIKE '5700%' THEN
          '570000'
         WHEN B.ORG_NUM LIKE '5800%' THEN
          '580000'
         WHEN B.ORG_NUM LIKE '5900%' THEN
          '590000'
         WHEN B.ORG_NUM LIKE '6000%' THEN
          '600000'
         ELSE
          '990000'
       END AS ORG_NUM,
       /*'990000' AS ORG_NUM,*/ --modify by djh 20221014 机构变更000000->990000
       CASE
         WHEN B.FACILITY_AMT >= 1000000 THEN
          'G05_I_1.3.5.B'
         WHEN B.FACILITY_AMT >= 500000 THEN
          'G05_I_1.3.4.B'
         WHEN B.FACILITY_AMT > 300000 THEN
          'G05_I_1.3.3.B'
         WHEN B.FACILITY_AMT > 100000 THEN
          'G05_I_1.3.2.B'
         ELSE
          'G05_I_1.3.1.B'
       END AS ITEM_NUM,
       SUM(B.BAD_LOAN_BAL) AS LOAN_ACCT_BAL_RMB
        FROM CBRC_G05_DATA_COLLECT_TMP_CUP B
       GROUP BY CASE
                  WHEN B.ORG_NUM LIKE '5100%' THEN
                   '510000'
                  WHEN B.ORG_NUM LIKE '5200%' THEN
                   '520000'
                  WHEN B.ORG_NUM LIKE '5300%' THEN
                   '530000'
                  WHEN B.ORG_NUM LIKE '5400%' THEN
                   '540000'
                  WHEN B.ORG_NUM LIKE '5500%' THEN
                   '550000'
                  WHEN B.ORG_NUM LIKE '5600%' THEN
                   '560000'
                  WHEN B.ORG_NUM LIKE '5700%' THEN
                   '570000'
                  WHEN B.ORG_NUM LIKE '5800%' THEN
                   '580000'
                  WHEN B.ORG_NUM LIKE '5900%' THEN
                   '590000'
                  WHEN B.ORG_NUM LIKE '6000%' THEN
                   '600000'
                  ELSE
                   '990000'
                END,
                CASE
                  WHEN B.FACILITY_AMT >= 1000000 THEN
                   'G05_I_1.3.5.B'
                  WHEN B.FACILITY_AMT >= 500000 THEN
                   'G05_I_1.3.4.B'
                  WHEN B.FACILITY_AMT > 300000 THEN
                   'G05_I_1.3.3.B'
                  WHEN B.FACILITY_AMT > 100000 THEN
                   'G05_I_1.3.2.B'
                  ELSE
                   'G05_I_1.3.1.B'
                END;
    COMMIT;

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN B.ORG_NUM LIKE '5100%' THEN
          '510000'
         WHEN B.ORG_NUM LIKE '5200%' THEN
          '520000'
         WHEN B.ORG_NUM LIKE '5300%' THEN
          '530000'
         WHEN B.ORG_NUM LIKE '5400%' THEN
          '540000'
         WHEN B.ORG_NUM LIKE '5500%' THEN
          '550000'
         WHEN B.ORG_NUM LIKE '5600%' THEN
          '560000'
         WHEN B.ORG_NUM LIKE '5700%' THEN
          '570000'
         WHEN B.ORG_NUM LIKE '5800%' THEN
          '580000'
         WHEN B.ORG_NUM LIKE '5900%' THEN
          '590000'
         WHEN B.ORG_NUM LIKE '6000%' THEN
          '600000'
         ELSE
          '990000'
       END AS ORG_NUM,
       /*'990000' AS ORG_NUM,*/ --modify by djh 20221014 机构变更000000->990000
       CASE
         WHEN B.FACILITY_AMT >= 1000000 THEN
          'G05_I_1.3.5.C'
         WHEN B.FACILITY_AMT >= 500000 THEN
          'G05_I_1.3.4.C'
         WHEN B.FACILITY_AMT > 300000 THEN
          'G05_I_1.3.3.C'
         WHEN B.FACILITY_AMT > 100000 THEN
          'G05_I_1.3.2.C'
         ELSE
          'G05_I_1.3.1.C'
       END AS ITEM_NUM,
       SUM(B.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL_RMB
        FROM CBRC_G05_DATA_COLLECT_TMP_VAL B
       WHERE B.FLAG = 'C'
       GROUP BY CASE
                  WHEN B.ORG_NUM LIKE '5100%' THEN
                   '510000'
                  WHEN B.ORG_NUM LIKE '5200%' THEN
                   '520000'
                  WHEN B.ORG_NUM LIKE '5300%' THEN
                   '530000'
                  WHEN B.ORG_NUM LIKE '5400%' THEN
                   '540000'
                  WHEN B.ORG_NUM LIKE '5500%' THEN
                   '550000'
                  WHEN B.ORG_NUM LIKE '5600%' THEN
                   '560000'
                  WHEN B.ORG_NUM LIKE '5700%' THEN
                   '570000'
                  WHEN B.ORG_NUM LIKE '5800%' THEN
                   '580000'
                  WHEN B.ORG_NUM LIKE '5900%' THEN
                   '590000'
                  WHEN B.ORG_NUM LIKE '6000%' THEN
                   '600000'
                  ELSE
                   '990000'
                END,
                CASE
                  WHEN B.FACILITY_AMT >= 1000000 THEN
                   'G05_I_1.3.5.C'
                  WHEN B.FACILITY_AMT >= 500000 THEN
                   'G05_I_1.3.4.C'
                  WHEN B.FACILITY_AMT > 300000 THEN
                   'G05_I_1.3.3.C'
                  WHEN B.FACILITY_AMT > 100000 THEN
                   'G05_I_1.3.2.C'
                  ELSE
                   'G05_I_1.3.1.C'
                END
      UNION ALL
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN B.ORG_NUM LIKE '5100%' THEN
          '510000'
         WHEN B.ORG_NUM LIKE '5200%' THEN
          '520000'
         WHEN B.ORG_NUM LIKE '5300%' THEN
          '530000'
         WHEN B.ORG_NUM LIKE '5400%' THEN
          '540000'
         WHEN B.ORG_NUM LIKE '5500%' THEN
          '550000'
         WHEN B.ORG_NUM LIKE '5600%' THEN
          '560000'
         WHEN B.ORG_NUM LIKE '5700%' THEN
          '570000'
         WHEN B.ORG_NUM LIKE '5800%' THEN
          '580000'
         WHEN B.ORG_NUM LIKE '5900%' THEN
          '590000'
         WHEN B.ORG_NUM LIKE '6000%' THEN
          '600000'
         ELSE
          '990000'
       END AS ORG_NUM,
       /*'990000' AS ORG_NUM,*/ --modify by djh 20221014 机构变更000000->990000
       CASE
         WHEN B.FACILITY_AMT >= 1000000 THEN
          'G05_I_1.3.5.C'
         WHEN B.FACILITY_AMT >= 500000 THEN
          'G05_I_1.3.4.C'
         WHEN B.FACILITY_AMT > 300000 THEN
          'G05_I_1.3.3.C'
         WHEN B.FACILITY_AMT > 100000 THEN
          'G05_I_1.3.2.C'
         ELSE
          'G05_I_1.3.1.C'
       END AS ITEM_NUM,
       SUM(B.OVERDUE_LOAN_BAL) AS LOAN_ACCT_BAL_RMB
        FROM CBRC_G05_DATA_COLLECT_TMP_CUP B
       GROUP BY CASE
                  WHEN B.ORG_NUM LIKE '5100%' THEN
                   '510000'
                  WHEN B.ORG_NUM LIKE '5200%' THEN
                   '520000'
                  WHEN B.ORG_NUM LIKE '5300%' THEN
                   '530000'
                  WHEN B.ORG_NUM LIKE '5400%' THEN
                   '540000'
                  WHEN B.ORG_NUM LIKE '5500%' THEN
                   '550000'
                  WHEN B.ORG_NUM LIKE '5600%' THEN
                   '560000'
                  WHEN B.ORG_NUM LIKE '5700%' THEN
                   '570000'
                  WHEN B.ORG_NUM LIKE '5800%' THEN
                   '580000'
                  WHEN B.ORG_NUM LIKE '5900%' THEN
                   '590000'
                  WHEN B.ORG_NUM LIKE '6000%' THEN
                   '600000'
                  ELSE
                   '990000'
                END,
                CASE
                  WHEN B.FACILITY_AMT >= 1000000 THEN
                   'G05_I_1.3.5.C'
                  WHEN B.FACILITY_AMT >= 500000 THEN
                   'G05_I_1.3.4.C'
                  WHEN B.FACILITY_AMT > 300000 THEN
                   'G05_I_1.3.3.C'
                  WHEN B.FACILITY_AMT > 100000 THEN
                   'G05_I_1.3.2.C'
                  ELSE
                   'G05_I_1.3.1.C'
                END;

    COMMIT;

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN B.ORG_NUM LIKE '5100%' THEN
          '510000'
         WHEN B.ORG_NUM LIKE '5200%' THEN
          '520000'
         WHEN B.ORG_NUM LIKE '5300%' THEN
          '530000'
         WHEN B.ORG_NUM LIKE '5400%' THEN
          '540000'
         WHEN B.ORG_NUM LIKE '5500%' THEN
          '550000'
         WHEN B.ORG_NUM LIKE '5600%' THEN
          '560000'
         WHEN B.ORG_NUM LIKE '5700%' THEN
          '570000'
         WHEN B.ORG_NUM LIKE '5800%' THEN
          '580000'
         WHEN B.ORG_NUM LIKE '5900%' THEN
          '590000'
         WHEN B.ORG_NUM LIKE '6000%' THEN
          '600000'
         ELSE
          '990000'
       END AS ORG_NUM,
       /*'990000' AS ORG_NUM,*/ --modify by djh 20221014 机构变更000000->990000
       CASE
         WHEN B.FACILITY_AMT >= 1000000 THEN
          'G05_I_1.3.5.D'
         WHEN B.FACILITY_AMT >= 500000 THEN
          'G05_I_1.3.4.D'
         WHEN B.FACILITY_AMT > 300000 THEN
          'G05_I_1.3.3.D'
         WHEN B.FACILITY_AMT > 100000 THEN
          'G05_I_1.3.2.D'
         ELSE
          'G05_I_1.3.1.D'
       END AS ITEM_NUM,
       SUM(B.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL_RMB
        FROM CBRC_G05_DATA_COLLECT_TMP_VAL B
       WHERE B.FLAG = 'D'
       GROUP BY CASE
                  WHEN B.ORG_NUM LIKE '5100%' THEN
                   '510000'
                  WHEN B.ORG_NUM LIKE '5200%' THEN
                   '520000'
                  WHEN B.ORG_NUM LIKE '5300%' THEN
                   '530000'
                  WHEN B.ORG_NUM LIKE '5400%' THEN
                   '540000'
                  WHEN B.ORG_NUM LIKE '5500%' THEN
                   '550000'
                  WHEN B.ORG_NUM LIKE '5600%' THEN
                   '560000'
                  WHEN B.ORG_NUM LIKE '5700%' THEN
                   '570000'
                  WHEN B.ORG_NUM LIKE '5800%' THEN
                   '580000'
                  WHEN B.ORG_NUM LIKE '5900%' THEN
                   '590000'
                  WHEN B.ORG_NUM LIKE '6000%' THEN
                   '600000'
                  ELSE
                   '990000'
                END,
                CASE
                  WHEN B.FACILITY_AMT >= 1000000 THEN
                   'G05_I_1.3.5.D'
                  WHEN B.FACILITY_AMT >= 500000 THEN
                   'G05_I_1.3.4.D'
                  WHEN B.FACILITY_AMT > 300000 THEN
                   'G05_I_1.3.3.D'
                  WHEN B.FACILITY_AMT > 100000 THEN
                   'G05_I_1.3.2.D'
                  ELSE
                   'G05_I_1.3.1.D'
                END
      UNION ALL
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN B.ORG_NUM LIKE '5100%' THEN
          '510000'
         WHEN B.ORG_NUM LIKE '5200%' THEN
          '520000'
         WHEN B.ORG_NUM LIKE '5300%' THEN
          '530000'
         WHEN B.ORG_NUM LIKE '5400%' THEN
          '540000'
         WHEN B.ORG_NUM LIKE '5500%' THEN
          '550000'
         WHEN B.ORG_NUM LIKE '5600%' THEN
          '560000'
         WHEN B.ORG_NUM LIKE '5700%' THEN
          '570000'
         WHEN B.ORG_NUM LIKE '5800%' THEN
          '580000'
         WHEN B.ORG_NUM LIKE '5900%' THEN
          '590000'
         WHEN B.ORG_NUM LIKE '6000%' THEN
          '600000'
         ELSE
          '990000'
       END AS ORG_NUM,
       /*'990000' AS ORG_NUM,*/ --modify by djh 20221014 机构变更000000->990000
       CASE
         WHEN B.FACILITY_AMT >= 1000000 THEN
          'G05_I_1.3.5.D'
         WHEN B.FACILITY_AMT >= 500000 THEN
          'G05_I_1.3.4.D'
         WHEN B.FACILITY_AMT > 300000 THEN
          'G05_I_1.3.3.D'
         WHEN B.FACILITY_AMT > 100000 THEN
          'G05_I_1.3.2.D'
         ELSE
          'G05_I_1.3.1.D'
       END AS ITEM_NUM,
       SUM(B.OVER_LOAN_BAL) AS LOAN_ACCT_BAL_RMB
        FROM CBRC_G05_DATA_COLLECT_TMP_CUP B
       GROUP BY CASE
                  WHEN B.ORG_NUM LIKE '5100%' THEN
                   '510000'
                  WHEN B.ORG_NUM LIKE '5200%' THEN
                   '520000'
                  WHEN B.ORG_NUM LIKE '5300%' THEN
                   '530000'
                  WHEN B.ORG_NUM LIKE '5400%' THEN
                   '540000'
                  WHEN B.ORG_NUM LIKE '5500%' THEN
                   '550000'
                  WHEN B.ORG_NUM LIKE '5600%' THEN
                   '560000'
                  WHEN B.ORG_NUM LIKE '5700%' THEN
                   '570000'
                  WHEN B.ORG_NUM LIKE '5800%' THEN
                   '580000'
                  WHEN B.ORG_NUM LIKE '5900%' THEN
                   '590000'
                  WHEN B.ORG_NUM LIKE '6000%' THEN
                   '600000'
                  ELSE
                   '990000'
                END,
                CASE
                  WHEN B.FACILITY_AMT >= 1000000 THEN
                   'G05_I_1.3.5.D'
                  WHEN B.FACILITY_AMT >= 500000 THEN
                   'G05_I_1.3.4.D'
                  WHEN B.FACILITY_AMT > 300000 THEN
                   'G05_I_1.3.3.D'
                  WHEN B.FACILITY_AMT > 100000 THEN
                   'G05_I_1.3.2.D'
                  ELSE
                   'G05_I_1.3.1.D'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3 按授信额度(总行)至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.4 按贷款期限（各项贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ----------------------------------------1.4 按贷款期限----------------------------------------
    --短期贷款：原始期限在一年及以下的个人贷款
    --中长期贷款：原始期限在一年以上的个人贷款
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12 THEN
          'G05_I_1.4.2.A'
         ELSE
          'G05_I_1.4.1.A'
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT))  > 12 THEN
                   'G05_I_1.4.2.A'
                  ELSE
                   'G05_I_1.4.1.A'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.4 按贷款期限（各项贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.4 按贷款期限（不良贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12 THEN
          'G05_I_1.4.2.B'
         ELSE
          'G05_I_1.4.1.B'
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT))  > 12 THEN
                   'G05_I_1.4.2.B'
                  ELSE
                   'G05_I_1.4.1.B'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.4 按贷款期限（不良贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.4 按贷款期限（逾期贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT))  > 12 THEN
          'G05_I_1.4.2.C'
         ELSE
          'G05_I_1.4.1.C'
       END AS ITEM_NUM,
       SUM(T.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
       INNER JOIN CBRC_G05_DATA_COLLECT_TMP_YQ T --逾期贷款余额(人民币)处理
          ON A.LOAN_NUM = T.LOAN_NUM
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.OD_FLG = 'Y' --逾期贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT))  > 12 THEN
                   'G05_I_1.4.2.C'
                  ELSE
                   'G05_I_1.4.1.C'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.4 按贷款期限（逾期贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.4 按贷款期限（逾期超过90天）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12 THEN
          'G05_I_1.4.2.D'
         ELSE
          'G05_I_1.4.1.D'
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.OD_DAYS > 90 --逾期超过90天
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12 THEN
                   'G05_I_1.4.2.D'
                  ELSE
                   'G05_I_1.4.1.D'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.4 按贷款期限（逾期超过90天）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.5 按担保方式（各项贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ----------------------------------------1.5 按担保方式----------------------------------------
    --按贷款担保方式进行划分，若贷款存在多种担保方式，遵循抵（质）押担保方式优先的原则
    --集市L层借据会按照抵（质）押,保证，信用方式调整，1104报表直接取
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP = 'D' THEN
          'G05_I_1.5.1.A'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'G05_I_1.5.2.A'
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'G05_I_1.5.3.A'
       END,
       SUM(T.LOAN_ACCT_BAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND T.ACCT_TYP LIKE '01%' --个人贷款
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(T.ACCT_NUM) < 36
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN T.GUARANTY_TYP = 'D' THEN
                   'G05_I_1.5.1.A'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN
                   'G05_I_1.5.2.A'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                   'G05_I_1.5.3.A'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.5 按担保方式（各项贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.5 按担保方式（不良贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP = 'D' THEN
          'G05_I_1.5.1.B'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'G05_I_1.5.2.B'
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'G05_I_1.5.3.B'
       END,
       SUM(T.LOAN_ACCT_BAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND T.ACCT_TYP LIKE '01%' --个人贷款
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(T.ACCT_NUM) < 36
            /*AND T.ORG_NUM NOT LIKE '5100%'*/ --add 刘晟典
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN T.GUARANTY_TYP = 'D' THEN
                   'G05_I_1.5.1.B'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN
                   'G05_I_1.5.2.B'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                   'G05_I_1.5.3.B'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.5 按担保方式（不良贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.5 按担保方式（逾期贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP = 'D' THEN
          'G05_I_1.5.1.C'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'G05_I_1.5.2.C'
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'G05_I_1.5.3.C'
       END,
       SUM(T1.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN CBRC_G05_DATA_COLLECT_TMP_YQ T1 --逾期贷款余额(人民币)处理
          ON T.LOAN_NUM = T1.LOAN_NUM
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND T.ACCT_TYP LIKE '01%' --个人贷款
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.OD_FLG = 'Y' --逾期贷款
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN T.GUARANTY_TYP = 'D' THEN
                   'G05_I_1.5.1.C'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN
                   'G05_I_1.5.2.C'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                   'G05_I_1.5.3.C'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.5 按担保方式（逾期贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.5 按担保方式（逾期超过90天）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP = 'D' THEN
          'G05_I_1.5.1.D'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'G05_I_1.5.2.D'
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'G05_I_1.5.3.D'
       END,
       SUM(T.LOAN_ACCT_BAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND T.ACCT_TYP LIKE '01%' --个人贷款
         AND T.LOAN_ACCT_BAL <> 0
         AND T.OD_DAYS > 90 --逾期超过90天
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(T.ACCT_NUM) < 36
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN T.GUARANTY_TYP = 'D' THEN
                   'G05_I_1.5.1.D'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN
                   'G05_I_1.5.2.D'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                   'G05_I_1.5.3.D'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.6 按支付方式（逾期超过90天）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.6 按支付方式（各项贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ----------------------------------------1.6 按支付方式----------------------------------------
    --(01  自主支付 02 受托支付)
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.DRAWDOWN_TYPE = 'A' THEN
          'G05_I_1.6.1.A'
         WHEN T.DRAWDOWN_TYPE = 'B' THEN
          'G05_I_1.6.2.A'
       END,
       SUM(T.LOAN_ACCT_BAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_AGRE_LOAN_CONTRACT T1
          ON T.ACCT_NUM = T1.CONTRACT_NUM
         AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND T.ACCT_TYP LIKE '01%' --个人贷款
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.LOAN_ACCT_BAL <> 0
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN T.DRAWDOWN_TYPE = 'A' THEN
                   'G05_I_1.6.1.A'
                  WHEN T.DRAWDOWN_TYPE = 'B' THEN
                   'G05_I_1.6.2.A'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.6 按支付方式（各项贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.6 按支付方式（不良贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.DRAWDOWN_TYPE = 'A' THEN
          'G05_I_1.6.1.B'
         WHEN T.DRAWDOWN_TYPE = 'B' THEN
          'G05_I_1.6.2.B'
       END,
       SUM(T.LOAN_ACCT_BAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_AGRE_LOAN_CONTRACT T1
          ON T.ACCT_NUM = T1.CONTRACT_NUM
         AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND T.ACCT_TYP LIKE '01%' --个人贷款
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN T.DRAWDOWN_TYPE = 'A' THEN
                   'G05_I_1.6.1.B'
                  WHEN T.DRAWDOWN_TYPE = 'B' THEN
                   'G05_I_1.6.2.B'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.6 按支付方式（不良贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.6 按支付方式（逾期贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.DRAWDOWN_TYPE = 'A' THEN
          'G05_I_1.6.1.C'
         WHEN T.DRAWDOWN_TYPE = 'B' THEN
          'G05_I_1.6.2.C'
       END,
       SUM(T2.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN CBRC_G05_DATA_COLLECT_TMP_YQ T2 --逾期贷款余额(人民币)处理
          ON T.LOAN_NUM = T2.LOAN_NUM
       INNER JOIN SMTMODS_L_AGRE_LOAN_CONTRACT T1 --取支付方式
          ON T.ACCT_NUM = T1.CONTRACT_NUM
         AND T1.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND T.ACCT_TYP LIKE '01%' --个人贷款
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.OD_FLG = 'Y' --逾期贷款
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN T.DRAWDOWN_TYPE = 'A' THEN
                   'G05_I_1.6.1.C'
                  WHEN T.DRAWDOWN_TYPE = 'B' THEN
                   'G05_I_1.6.2.C'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.6 按支付方式（逾期贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.6 按支付方式（逾期超过90天）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.DRAWDOWN_TYPE = 'A' THEN
          'G05_I_1.6.1.D'
         WHEN T.DRAWDOWN_TYPE = 'B' THEN
          'G05_I_1.6.2.D'
       END,
       SUM(T.LOAN_ACCT_BAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_AGRE_LOAN_CONTRACT T1
          ON T.ACCT_NUM = T1.CONTRACT_NUM
         AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND T.ACCT_TYP LIKE '01%' --个人贷款
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.LOAN_ACCT_BAL <> 0
         AND T.OD_DAYS > 90 --逾期超过90天
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN T.DRAWDOWN_TYPE = 'A' THEN
                   'G05_I_1.6.1.D'
                  WHEN T.DRAWDOWN_TYPE = 'B' THEN
                   'G05_I_1.6.2.D'
                END;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.6 按支付方式（逾期超过90天）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.7 展期贷款（各项贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ----------------------------------------1.7 展期贷款------------------------------------------
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'G05_I_1.7.A' AS ITEM_NUM,
       SUM(T.LOAN_ACCT_BAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND T.ACCT_TYP LIKE '01%' --个人贷款
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(T.ACCT_NUM) < 36
         AND EXTENDTERM_FLG = 'Y' --展期标志
       GROUP BY I_DATADATE, T.ORG_NUM;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.7 展期贷款（各项贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.7 展期贷款（不良贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'G05_I_1.7.B' AS ITEM_NUM,
       SUM(T.LOAN_ACCT_BAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_AGRE_LOAN_CONTRACT T1
          ON T.ACCT_NUM = T1.CONTRACT_NUM
         AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND T.ACCT_TYP LIKE '01%' --个人贷款
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(T.ACCT_NUM) < 36
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
         AND EXTENDTERM_FLG = 'Y' --展期标志
       GROUP BY I_DATADATE, T.ORG_NUM;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.7 展期贷款（不良贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.个人经营性贷款（各项贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ----------------------------------------2.个人经营性贷款------------------------------------------
    -- 2.个人经营性贷款
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'G05_I_2..A' AS ITEM_NUM, --各项贷款余额
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP LIKE '0102%' --个人经营性贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
       GROUP BY A.ORG_NUM;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.个人经营性贷款（各项贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.个人经营性贷款（不良贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /*按月分期还款的个人消费贷款，发生逾期的填报方法为：逾期90天以内的，按照已逾期部分的本金的余额填报，
    逾期91天及以上的，按照整笔贷款本金的余额填报*/
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'G05_I_2..B' AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP LIKE '0102%' --个人经营性贷款
         AND LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
       GROUP BY A.ORG_NUM;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.个人经营性贷款（不良贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.个人经营性贷款（逾期贷款）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'G05_I_2..C' AS ITEM_NUM,
       SUM(T.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN CBRC_G05_DATA_COLLECT_TMP_YQ T --逾期贷款余额(人民币)处理
          ON A.LOAN_NUM = T.LOAN_NUM
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP LIKE '0102%' --个人经营性贷款
         AND OD_FLG = 'Y' --逾期贷款
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
       GROUP BY A.ORG_NUM;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.个人经营性贷款（逾期贷款）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：2.个人经营性贷款（逾期超过90天）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'G05_I_2..D' AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP LIKE '0102%' --个人经营性贷款
         AND OD_DAYS > 90
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
       GROUP BY A.ORG_NUM;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：2.个人经营性贷款（逾期超过90天）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    -----------------------------------------------------------------
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：外部信用卡数据至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --信用卡数据插入

    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             CASE
               WHEN T.INDEX_NO = '2' THEN
                'G05_I_2..A'
               ELSE
                'G05_I_' || T.INDEX_NO || '.A'
             END AS ITEM_NUM,
             TO_NUMBER(LOAN_BAL) * 10000 AS LOAN_ACCT_BAL_RMB
        FROM CBRC_CUP_G05_TMP2 T
       WHERE T.SERIAL_NO NOT IN ('1', '2', '12', '18', '24', '27', '31')
         AND TO_NUMBER(T.LOAN_BAL) <> 0
         AND replace(t.data_date, chr(13), '') = I_DATADATE
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             CASE
               WHEN T.INDEX_NO = '2' THEN
                'G05_I_2..B'
               ELSE
                'G05_I_' || T.INDEX_NO || '.B'
             END AS ITEM_NUM,
             TO_NUMBER(T.BAD_LOAN_BAL) * 10000 AS LOAN_ACCT_BAL_RMB
        FROM CBRC_CUP_G05_TMP2 T
       WHERE T.SERIAL_NO NOT IN ('1', '2', '12', '18', '24', '27', '31')
         AND TO_NUMBER(T.BAD_LOAN_BAL) <> 0
         AND replace(t.data_date, chr(13), '') = I_DATADATE
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             CASE
               WHEN T.INDEX_NO = '2' THEN
                'G05_I_2..C'
               ELSE
                'G05_I_' || T.INDEX_NO || '.C'
             END AS ITEM_NUM,
             TO_NUMBER(T.OVERDUE_LOAN_BAL) * 10000 AS LOAN_ACCT_BAL_RMB
        FROM CBRC_CUP_G05_TMP2 T
       WHERE T.SERIAL_NO NOT IN ('1', '2', '12', '18', '24', '27', '31')
         AND TO_NUMBER(T.OVERDUE_LOAN_BAL) <> 0
         AND replace(t.data_date, chr(13), '') = I_DATADATE
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             CASE
               WHEN T.INDEX_NO = '2' THEN
                'G05_I_2..D'
               ELSE
                'G05_I_' || T.INDEX_NO || '.D'
             END AS ITEM_NUM,
             TO_NUMBER(T.OVER_LOAN_BAL) * 10000 AS LOAN_ACCT_BAL_RMB
        FROM CBRC_CUP_G05_TMP2 T
       WHERE T.SERIAL_NO NOT IN ('1', '2', '12', '18', '24', '27', '31')
         AND TO_NUMBER(T.OVER_LOAN_BAL) <> 0
         AND replace(t.data_date, chr(13), '') = I_DATADATE;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：外部信用卡数据至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：加工当年累计累放贷款合计至G05_DATA_AMT_TMP1中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --累放逻辑与其他S63等报表口径相同，都取放款时机构
    --由于累放，防止手工跑，季度报表改成月度，另外把前几个月累放数据跑进去
    ------------------加工当年累计 累放贷款合计------------------
    --年初删除本年累计

    IF SUBSTR(I_DATADATE, 5, 2) = '01' THEN
      EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_G05_DATA_AMT_TMP1';
    ELSE
      DELETE FROM CBRC_G05_DATA_AMT_TMP1 T
       WHERE SUBSTR(T.DATA_DATE, 1, 6) = SUBSTR(I_DATADATE, 1, 6);
      COMMIT;

    END IF;

    COMMIT;

    --单户累放表 保留历史，每个月的放款相关都放在此表，为统计当年累放收益：实际利率按照放款时利率计算
    INSERT INTO CBRC_G05_DATA_AMT_TMP1
      (DATA_DATE, --数据日期
       ORG_NUM, --机构
       LOAN_NUM, --借据编号
       CUST_ID, --客户号
       CUST_NAM, --客户名称
       ACCT_TYP, --账户类型
       CURR_CD, --币种
       DRAWDOWN_DT, --放款日期
       LOAN_ACCT_AMT, --放款金额
       LOAN_ACCT_BAL, --贷款余额
       REAL_INT_RAT, --实际利率
       NHSY, --年化收益
       ITEM_CD, --科目号
       GUARANTY_TYP) --贷款担保方式
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构
             T.LOAN_NUM, --借据编号
             T.CUST_ID, --客户号
             P.CUST_NAM AS CUST_NAM, --客户名称
             T.ACCT_TYP, --账户类型
             T.CURR_CD, --币种
             T.DRAWDOWN_DT, --放款日期
             T.DRAWDOWN_AMT AS LOAN_ACCT_AMT, --放款金额
             T.LOAN_ACCT_BAL AS LOAN_ACCT_BAL, --贷款余额
             T.REAL_INT_RAT, --实际利率
             (T.DRAWDOWN_AMT * T.REAL_INT_RAT / 100) AS NHSY, --年化收益
             T.ITEM_CD, --科目号
             T.GUARANTY_TYP --贷款担保方式
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_P P
          ON P.DATA_DATE = T.DATA_DATE
         AND P.CUST_ID = T.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYYMM') = SUBSTR(I_DATADATE, 1, 6) --当月
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND ACCT_TYP LIKE '01%' --个人贷款
         AND T.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(T.ACCT_NUM) < 36;

    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：加工当年累计累放贷款合计至G05_DATA_AMT_TMP1中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.8 贷款累放情况（不含信用卡）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --因迁移过来的村镇数据可能仍然存在与业务提供的明细口径不一致的情况，2023年1-10月村镇累放数据单独使用村镇业务提供的累放明细CBRC_G05_AMT_TMP2_CZ出数,2024年以后正常使用原逻辑。 20231011zjm
    
      --2024年后整合
      INSERT 
      INTO CBRC_G05_DATA_COLLECT_TMP 
        (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
        SELECT 
         I_DATADATE AS DATA_DATE,
         C.ORG_NUM,
         'G05_I_1.8.A.2023' AS ITEM_NUM,
         SUM(DRAWDOWN_AMT * TT.CCY_RATE)
          FROM SMTMODS_L_ACCT_LOAN A
          LEFT JOIN SMTMODS_L_PUBL_RATE TT
            ON TT.DATA_DATE = A.DATA_DATE
           AND TT.BASIC_CCY = A.CURR_CD
           AND TT.FORWARD_CCY = 'CNY'
          LEFT JOIN CBRC_G05_DATA_AMT_TMP1 C ---取放款时所属机构
            ON A.LOAN_NUM = C.LOAN_NUM
         WHERE A.DATA_DATE = I_DATADATE
           AND TO_CHAR(A.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
           AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) -- 累放取非重组
           AND A.ACCT_TYP LIKE '01%' --个人贷款
           AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
           AND A.CANCEL_FLG = 'N'
           AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
           AND LENGTHB(A.ACCT_NUM) < 36
         GROUP BY C.ORG_NUM;
      COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.8 贷款累放情况（不含信用卡）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：其中:1.8.1 住房按揭贷款至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --因迁移过来的村镇数据可能仍然存在与业务提供的明细口径不一致的情况，2023年1-10月村镇累放数据单独使用村镇业务提供的累放明细CBRC_G05_AMT_TMP2_CZ出数,2024年以后正常使用原逻辑。 20231011zjm
    
      --2024年后整合
      INSERT 
      INTO CBRC_G05_DATA_COLLECT_TMP 
        (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
        SELECT 
         I_DATADATE AS DATA_DATE,
         C.ORG_NUM,
         'G05_I_1.8.1.A.2023' AS ITEM_NUM,
         SUM(DRAWDOWN_AMT * TT.CCY_RATE)
          FROM SMTMODS_L_ACCT_LOAN A
          LEFT JOIN SMTMODS_L_PUBL_RATE TT
            ON TT.DATA_DATE = A.DATA_DATE
           AND TT.BASIC_CCY = A.CURR_CD
           AND TT.FORWARD_CCY = 'CNY'
          LEFT JOIN CBRC_G05_DATA_AMT_TMP1 C ---取放款时所属机构
            ON A.LOAN_NUM = C.LOAN_NUM
         WHERE A.DATA_DATE = I_DATADATE
           AND TO_CHAR(A.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
           AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) -- 累放取非重组
           AND A.ACCT_TYP LIKE '01%' --个人贷款
           AND A.ACCT_TYP NOT LIKE '0102%' --非个人经营性贷款
           AND A.CANCEL_FLG = 'N'
           AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
           AND LENGTHB(A.ACCT_NUM) < 36
           AND A.ACCT_TYP = '010101' --住房按揭贷款
        /*AND A.ORG_NUM NOT LIKE '5100%'*/ --add 刘晟典
         GROUP BY C.ORG_NUM;
      COMMIT;
  

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：其中:1.8.1 住房按揭贷款至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.9 贷款年化收益（不含信用卡）至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       'G05_I_1.9.A.2023' AS ITEM_NUM,
       SUM(NHSY * TT.CCY_RATE)
        FROM CBRC_G05_DATA_AMT_TMP1 C ---取放款时所属机构
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = C.DATA_DATE
         AND TT.BASIC_CCY = C.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       GROUP BY C.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.9 贷款年化收益（不含信用卡）至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：其中:1.9.1 住房按揭贷款至G05_DATA_COLLECT_TMP中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO CBRC_G05_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       'G05_I_1.9.1.A.2023' AS ITEM_NUM,
       SUM(NHSY * TT.CCY_RATE)
        FROM CBRC_G05_DATA_AMT_TMP1 C ---取放款时所属机构
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = C.DATA_DATE
         AND TT.BASIC_CCY = C.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
         AND C.ACCT_TYP = '010101' --住房按揭贷款
       GROUP BY C.ORG_NUM;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：其中:1.9.1 住房按揭贷款至G05_DATA_COLLECT_TMP中间表';
    
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --=======================================================================================================-
    -------------------------------------G05数据插至目标指标表--------------------------------------------
    --=====================================================================================================---
    V_STEP_FLAG := 1;
    V_STEP_DESC := '产生G05指标数据，插至目标表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G05_I' AS REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(LOAN_ACCT_BAL_RMB) AS ITEM_VAL,
       CASE
         WHEN T.ITEM_NUM LIKE 'G05_I_1.3%' THEN --所有的  1.3 按授信额度不汇总，在本程序汇总支行，分行，总行
          '1'
         ELSE
          '2'
       END AS FLAG,
       CASE
         WHEN T.ITEM_NUM LIKE 'G05_I_1.3%' THEN --MODI BY DJH 20230509不参与汇总
          'N'
       END AS IS_TOTAL
        FROM CBRC_G05_DATA_COLLECT_TMP T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM LIKE 'G05_I_1.3%' THEN --所有的  1.3 按授信额度不汇总，在本程序汇总支行，分行，总行
                   '1'
                  ELSE
                   '2'
                END;
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
   
END proc_cbrc_idx2_g0501