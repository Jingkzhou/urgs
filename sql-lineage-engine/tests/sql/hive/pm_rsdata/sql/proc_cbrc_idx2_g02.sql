CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g02(II_DATADATE IN STRING  --跑批日期                                 
)
/******************************
  @author:fanxiaoyu
  @create-date:2015-09-21
  @description:G02
  @modification history:
  m0.20150919-fanxiaoyu-G02
  
  
  
  
目标表：CBRC_A_REPT_ITEM_VAL

集市表：   SMTMODS_L_ACCT_DERIVE_DETAIL_INFO
      SMTMODS_L_CUST_ALL
      SMTMODS_L_CUST_C
      SMTMODS_L_PUBL_RATE

  *******************************/
 IS
  V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE  VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(300); --任务描述
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  D_NOW_YEAR  DATE; --当年
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR2(30);
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE  := II_DATADATE;
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G02');
    D_NOW_YEAR := EXTRACT(YEAR FROM DATE(I_DATADATE));
    V_TAB_NAME := 'G02';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);
    
    V_STEP_ID   := 1;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
           AND SYS_NAM = 'CBRC'
           AND REP_NUM = 'G02'
           AND FLAG = '2';
    COMMIT;


    V_STEP_ID   := 2;
    V_STEP_DESC := '1.1买入期权-1.6混合类(所有产品)  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);
    --==================================================
    --   G02 1.1买入期权-1.6混合类
    --==================================================
  

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G02' AS REP_NUM, --报表编号
             CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.A'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.A'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.A'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.A'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.A'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.A'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.C.2012'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.C.2012'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.C.2012'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.C.2012'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.C.2012'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.C.2012'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.E'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.E'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.E'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.E'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.E'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.E'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.G'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.G'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.G'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.G'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.G'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.G'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.I'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.I'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.I'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.I'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.I'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.I'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.K'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.K'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.K'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.K'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.K'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.K'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.M'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.M'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.M'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.M'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.M'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.M'
                END)
             END AS ITEM_NUM, --指标号
             SUM(A.NOMINAL_CORPUS_BUY * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
        LEFT JOIN SMTMODS_L_PUBL_RATE U ON U.CCY_DATE =I_DATADATE
                               AND U.BASIC_CCY = A.CURR_CD1 --基准币种
                               AND U.FORWARD_CCY = 'CNY' --折算币种
           WHERE ACCT_TYPE = '1'
             AND AGREEMENT_TYPE IN ('1', '2', '3', '4', '5', '6', '7')
             AND BUSINESS_TYP IN ('1', '2', '3', '4', '5', '6')
             AND A.DATA_DATE = I_DATADATE
       GROUP BY ORG_NUM,
                CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.A'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.A'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.A'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.A'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.A'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.A'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.C.2012'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.C.2012'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.C.2012'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.C.2012'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.C.2012'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.C.2012'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.E'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.E'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.E'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.E'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.E'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.E'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.G'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.G'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.G'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.G'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.G'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.G'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.I'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.I'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.I'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.I'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.I'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.I'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.K'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.K'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.K'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.K'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.K'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.K'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.M'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.M'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.M'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.M'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.M'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.M'
                END)
                END;
    COMMIT;

    V_STEP_DESC := '1.1买入期权-1.6混合类(所有产品)   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);
    
    V_STEP_ID   := 2;
    V_STEP_DESC := '1.1买入期权-1.6混合类(人民币产品)  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);
    --==================================================
    --   G02 1.1买入期权-1.6混合类(人民币产品)
    --==================================================
   

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G02' AS REP_NUM, --报表编号
             CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.B'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.B'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.B'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.B'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.B'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.B'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.D.2012'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.D.2012'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.D.2012'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.D.2012'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.D.2012'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.D.2012'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.F'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.F'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.F'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.F'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.F'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.F'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.H'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.H'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.H'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.H'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.H'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.H'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.J'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.J'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.J'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.J'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.J'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.J'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.L'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.L'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.L'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.L'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.L'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.L'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.N'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.N'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.N'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.N'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.N'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.N'
                END)
             END AS ITEM_NUM, --指标号
             SUM(A.NOMINAL_CORPUS_BUY * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = A.CURR_CD1 --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE ACCT_TYPE = '1'
             AND AGREEMENT_TYPE IN ('1', '2', '3', '4', '5', '6', '7')
             AND BUSINESS_TYP IN ('1', '2', '3', '4', '5', '6')
             AND (CURR_CD1 = 'CNY' OR CURR_CD2 = 'CNY')
             AND A.DATA_DATE = I_DATADATE
             AND BUSINESS_TYP IS NOT NULL
             AND AGREEMENT_TYPE IS NOT NULL
       GROUP BY ORG_NUM,
                CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.B'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.B'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.B'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.B'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.B'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.B'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.D.2012'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.D.2012'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.D.2012'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.D.2012'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.D.2012'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.D.2012'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.F'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.F'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.F'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.F'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.F'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.F'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.H'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.H'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.H'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.H'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.H'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.H'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.J'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.J'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.J'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.J'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.J'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.J'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.L'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.L'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.L'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.L'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.L'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.L'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_1.1.N'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_1.2.N'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_1.3.N'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_1.4.N'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_1.5.N'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_1.6.N'
                END)
             END;
    COMMIT;
    V_STEP_DESC := '1.1买入期权-1.6混合类(人民币产品)   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    V_STEP_ID   := 3;
    V_STEP_DESC := '2.1买入期权-2.6混合类 (所有产品)  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    --==================================================
    --   G02 2.1买入期权-2.6混合类 (所有产品)
    --==================================================
    

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G02' AS REP_NUM, --报表编号
             CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.A'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.A'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.A'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.A'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.A'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.A'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.C.2012'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.C.2012'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.C.2012'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.C.2012'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.C.2012'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.C.2012'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.E'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.E'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.E'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.E'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.E'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.E'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.G'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.G'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.G'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.G'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.G'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.G'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.I'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.I'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.I'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.I'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.I'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.I'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.K'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.K'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.K'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.K'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.K'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.K'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.M'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.M'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.M'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.M'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.N'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.N'
                END)
             END AS ITEM_NUM, --指标号
             SUM(A.NOMINAL_CORPUS_BUY * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = A.CURR_CD1 --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE ACCT_TYPE = '2'
             AND AGREEMENT_TYPE IN ('1', '2', '3', '4', '5', '6', '7')
             AND BUSINESS_TYP IN ('1', '2', '3', '4', '5', '6')
             AND A.DATA_DATE = I_DATADATE
       GROUP BY ORG_NUM,
                CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.A'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.A'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.A'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.A'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.A'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.A'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.C.2012'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.C.2012'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.C.2012'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.C.2012'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.C.2012'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.C.2012'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.E'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.E'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.E'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.E'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.E'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.E'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.G'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.G'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.G'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.G'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.G'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.G'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.I'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.I'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.I'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.I'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.I'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.I'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.K'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.K'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.K'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.K'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.K'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.K'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.M'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.M'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.M'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.M'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.N'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.N'
                END)
             END;
    COMMIT;

    V_STEP_DESC := '2.1买入期权-2.6混合类 (所有产品)   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    V_STEP_ID   := 4;
    V_STEP_DESC := '2.1买入期权-2.6混合类 (人民币产品)  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    --==================================================
    --   G02 2.1买入期权-2.6混合类(人民币产品)
    --==================================================
  

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G02' AS REP_NUM, --报表编号
             CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.B'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.B'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.B'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.B'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.B'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.B'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.D.2012'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.D.2012'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.D.2012'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.D.2012'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.D.2012'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.D.2012'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.F'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.F'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.F'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.F'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.F'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.F'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.H'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.H'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.H'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.H'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.H'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.H'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.J'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.J'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.J'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.J'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.J'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.J'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.L'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.L'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.L'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.L'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.L'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.L'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.N'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.N'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.N'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.N'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.N'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.N'
                END)
             END AS ITEM_NUM, --指标号
             SUM(A.NOMINAL_CORPUS_BUY * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = A.CURR_CD1 --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE ACCT_TYPE = '2'
             AND AGREEMENT_TYPE IN ('1', '2', '3', '4', '5', '6', '7')
             AND BUSINESS_TYP IN ('1', '2', '3', '4', '5', '6')
             AND (CURR_CD1 = 'CNY' OR CURR_CD2 = 'CNY')
             AND A.DATA_DATE = I_DATADATE
       GROUP BY ORG_NUM,
                CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.B'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.B'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.B'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.B'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.B'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.B'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.D.2012'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.D.2012'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.D.2012'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.D.2012'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.D.2012'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.D.2012'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.F'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.F'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.F'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.F'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.F'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.F'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.H'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.H'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.H'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.H'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.H'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.H'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.J'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.J'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.J'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.J'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.J'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.J'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.L'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.L'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.L'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.L'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.L'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.L'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_1_2.1.N'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_1_2.2.N'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_1_2.3.N'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_1_2.4.N'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_1_2.5.N'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_1_2.6.N'
                END)
             END;
    COMMIT;
    V_STEP_DESC := '2.1买入期权-2.6混合类 (人民币产品)   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    V_STEP_ID   := 5;
    V_STEP_DESC := '1.1买入期权-1.6混合类 (正总市场价值)  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    --==================================================
    --   G02 1.1买入期权-1.6混合类 (市场价值-利率)
    --==================================================
   

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G02' AS REP_NUM, --报表编号
             CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.A'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.A'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.A'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.A'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.A'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.A'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.C.2012'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.C.2012'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.C.2012'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.C.2012'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.C.2012'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.C.2012'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.E'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.E'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.E'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.E'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.E'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.E'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.G'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.G'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.G'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.G'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.G'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.G'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.I'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.I'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.I'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.I'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.I'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.I'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.K'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.K'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.K'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.K'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.K'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.K'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.M'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.M'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.M'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.M'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.M'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.M'
                END)
             END AS ITEM_NUM, --指标号
             SUM(A.RE_MARKET_VALUE * V.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
        LEFT JOIN SMTMODS_L_PUBL_RATE V
                  ON V.CCY_DATE = I_DATADATE
                 AND V.BASIC_CCY = A.RE_MARKET_VALUE_CCY --基准币种
                 AND V.FORWARD_CCY = 'CNY' --折算币种
       WHERE ACCT_TYPE = '1'
             AND RE_MARKET_VALUE > 0
             AND AGREEMENT_TYPE IN ('1', '2', '3', '4', '5', '6', '7')
             AND BUSINESS_TYP IN ('1', '2', '3', '4', '5', '6')
             AND A.DATA_DATE = I_DATADATE
       GROUP BY ORG_NUM,
                CASE
                  WHEN AGREEMENT_TYPE = 1 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.A'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.A'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.A'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.A'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.A'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.A'
                   END)
                  WHEN AGREEMENT_TYPE = 2 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.C.2012'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.C.2012'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.C.2012'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.C.2012'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.C.2012'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.C.2012'
                   END)
                  WHEN AGREEMENT_TYPE = 3 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.E'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.E'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.E'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.E'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.E'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.E'
                   END)
                  WHEN AGREEMENT_TYPE = 4 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.G'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.G'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.G'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.G'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.G'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.G'
                   END)
                  WHEN AGREEMENT_TYPE = 5 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.I'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.I'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.I'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.I'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.I'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.I'
                   END)
                  WHEN AGREEMENT_TYPE = 6 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.K'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.K'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.K'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.K'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.K'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.K'
                   END)
                  WHEN AGREEMENT_TYPE = 7 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.M'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.M'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.M'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.M'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.M'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.M'
                   END)
                END;
    COMMIT;
    V_STEP_DESC := '1.1买入期权-1.6混合类 (正总市场价值)   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    V_STEP_ID   := 6;
    V_STEP_DESC := '1.1买入期权-1.6混合类 (负总市场价值)  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    --==================================================
    --   G02 市场价值-负总市场价值-1买入期权_6混合类
    --==================================================
    

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G02' AS REP_NUM, --报表编号
             CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.B'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.B'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.B'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.B'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.B'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.B'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.D.2012'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.D.2012'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.D.2012'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.D.2012'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.D.2012'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.D.2012'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.F'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.F'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.F'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.F'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.F'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.F'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.H'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.H'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.H'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.H'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.H'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.H'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.J'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.J'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.J'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.J'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.J'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.J'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.L'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.L'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.L'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.L'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.L'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.L'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_2_1.1.N'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_2_1.2.N'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_2_1.3.N'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_2_1.4.N'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_2_1.5.N'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_2_1.6.N'
                END)
             END AS ITEM_NUM, --指标号
             SUM(ABS(RE_MARKET_VALUE * V.CCY_RATE)) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
        LEFT JOIN SMTMODS_L_PUBL_RATE V
                  ON V.CCY_DATE = I_DATADATE
                 AND V.BASIC_CCY = A.RE_MARKET_VALUE_CCY --基准币种
                 AND V.FORWARD_CCY = 'CNY' --折算币种
       WHERE ACCT_TYPE = '1'
             AND RE_MARKET_VALUE < 0
             AND AGREEMENT_TYPE IN ('1', '2', '3', '4', '5', '6', '7')
             AND BUSINESS_TYP IN ('1', '2', '3', '4', '5', '6')
             AND A.DATA_DATE = I_DATADATE
       GROUP BY ORG_NUM,
                CASE
                  WHEN AGREEMENT_TYPE = 1 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.B'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.B'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.B'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.B'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.B'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.B'
                   END)
                  WHEN AGREEMENT_TYPE = 2 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.D.2012'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.D.2012'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.D.2012'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.D.2012'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.D.2012'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.D.2012'
                   END)
                  WHEN AGREEMENT_TYPE = 3 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.F'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.F'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.F'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.F'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.F'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.F'
                   END)
                  WHEN AGREEMENT_TYPE = 4 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.H'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.H'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.H'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.H'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.H'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.H'
                   END)
                  WHEN AGREEMENT_TYPE = 5 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.J'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.J'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.J'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.J'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.J'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.J'
                   END)
                  WHEN AGREEMENT_TYPE = 6 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.L'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.L'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.L'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.L'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.L'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.L'
                   END)
                  WHEN AGREEMENT_TYPE = 7 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_2_1.1.N'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_2_1.2.N'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_2_1.3.N'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_2_1.4.N'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_2_1.5.N'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_2_1.6.N'
                   END)
                END;
    COMMIT;

    V_STEP_DESC := '1.1买入期权-1.6混合类 (负总市场价值)   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    V_STEP_ID   := 7;
    V_STEP_DESC := '业务发生额-所有产品-1买入期权_6混合类  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    --==================================================
    --   G02 业务发生额-所有产品-1买入期权_6混合类
    --==================================================
    
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G02' AS REP_NUM, --报表编号
             CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.A'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.A'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.A'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.A'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.A'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.A'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.C'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.C'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.C'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.C'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.C'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.C'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.E'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.E'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.E'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.E'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.E'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.E'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.G'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.G'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.G'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.G'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.G'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.G'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.I'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.I'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.I'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.I'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.I'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.I'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.K'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.K'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.K'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.K'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.K'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.K'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.M'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.M'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.M'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.M'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.M'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.M'
                END)
             END AS ITEM_NUM, --指标号
             SUM(CASE
               WHEN TRUNC(DEAL_DATE, 'Y') = D_NOW_YEAR THEN
                A.NOMINAL_CORPUS_BUY * U.CCY_RATE
               ELSE
                0
             END) AS ITEM_VAL, --指标值
             '2' AS FLAG
       FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = A.CURR_CD1 --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE ACCT_TYPE = '1'
             AND AGREEMENT_TYPE IN ('1', '2', '3', '4', '5', '6', '7')
             AND BUSINESS_TYP IN ('1', '2', '3', '4', '5', '6')
             AND A.DATA_DATE = I_DATADATE
       GROUP BY ORG_NUM,
                CASE
                  WHEN AGREEMENT_TYPE = 1 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.A'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.A'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.A'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.A'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.A'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.A'
                   END)
                  WHEN AGREEMENT_TYPE = 2 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.C'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.C'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.C'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.C'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.C'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.C'
                   END)
                  WHEN AGREEMENT_TYPE = 3 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.E'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.E'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.E'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.E'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.E'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.E'
                   END)
                  WHEN AGREEMENT_TYPE = 4 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.G'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.G'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.G'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.G'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.G'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.G'
                   END)
                  WHEN AGREEMENT_TYPE = 5 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.I'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.I'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.I'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.I'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.I'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.I'
                   END)
                  WHEN AGREEMENT_TYPE = 6 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.K'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.K'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.K'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.K'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.K'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.K'
                   END)
                  WHEN AGREEMENT_TYPE = 7 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.M'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.M'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.M'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.M'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.M'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.M'
                   END)
                END;
    COMMIT;

    V_STEP_DESC := '业务发生额-所有产品-1买入期权_6混合类  逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    V_STEP_ID   := 8;
    V_STEP_DESC := '业务发生额-人民币产品-1买入期权_6混合类  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    --==================================================
    --   G02 业务发生额-人民币产品-1买入期权_6混合类
    --==================================================
    
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G02' AS REP_NUM, --报表编号
             CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.B'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.B'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.B'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.B'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.B'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.B'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.D'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.D'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.D'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.D'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.D'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.D'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.F'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.F'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.F'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.F'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.F'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.F'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.H'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.H'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.H'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.H'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.H'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.H'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.J'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.J'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.J'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.J'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.J'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.J'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.L'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.L'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.L'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.L'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.L'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.L'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_1.1.N'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_1.2.N'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_1.3.N'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_1.4.N'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_1.5.N'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_1.6.N'
                END)
             END AS ITEM_NUM, --指标号
             SUM(CASE
               WHEN TRUNC(DEAL_DATE, 'Y') = D_NOW_YEAR THEN
                A.NOMINAL_CORPUS_BUY * U.CCY_RATE
               ELSE
                0
             END) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = A.CURR_CD1 --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE ACCT_TYPE = '1'
             AND AGREEMENT_TYPE IN ('1', '2', '3', '4', '5', '6', '7')
             AND BUSINESS_TYP IN ('1', '2', '3', '4', '5', '6')
             AND (CURR_CD1 = 'CNY' OR CURR_CD2 = 'CNY')
             AND A.DATA_DATE = I_DATADATE
       GROUP BY ORG_NUM,
                CASE
                  WHEN AGREEMENT_TYPE = 1 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.B'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.B'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.B'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.B'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.B'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.B'
                   END)
                  WHEN AGREEMENT_TYPE = 2 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.D'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.D'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.D'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.D'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.D'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.D'
                   END)
                  WHEN AGREEMENT_TYPE = 3 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.F'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.F'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.F'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.F'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.F'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.F'
                   END)
                  WHEN AGREEMENT_TYPE = 4 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.H'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.H'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.H'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.H'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.H'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.H'
                   END)
                  WHEN AGREEMENT_TYPE = 5 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.J'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.J'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.J'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.J'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.J'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.J'
                   END)
                  WHEN AGREEMENT_TYPE = 6 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.L'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.L'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.L'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.L'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.L'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.L'
                   END)
                  WHEN AGREEMENT_TYPE = 7 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_1.1.N'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_1.2.N'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_1.3.N'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_1.4.N'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_1.5.N'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_1.6.N'
                   END)
                END;
    COMMIT;
    V_STEP_DESC := '业务发生额-人民币产品-1买入期权_6混合类   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    V_STEP_ID   := 9;
    V_STEP_DESC := '业务发生额-所有产品-2.1买入期权_2.6混合类  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    --==================================================
    --   G02 业务发生额-所有产品-2.1买入期权_2.6混合类
    --==================================================

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G02' AS REP_NUM, --报表编号
             CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.A'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.A'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.A'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.A'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.A'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.A'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.C'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.C'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.C'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.C'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.C'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.C'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.E'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.E'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.E'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.E'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.E'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.E'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.G'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.G'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.G'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.G'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.G'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.G'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.I'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.I'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.I'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.I'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.I'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.I'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.K'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.K'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.K'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.K'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.K'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.K'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.M'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.M'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.M'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.M'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.M'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.M'
                END)
             END AS ITEM_NUM, --指标号
             SUM(CASE
               WHEN TRUNC(DEAL_DATE, 'Y') = D_NOW_YEAR THEN
                A.NOMINAL_CORPUS_BUY * U.CCY_RATE
               ELSE
                0
             END) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = A.CURR_CD1 --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE ACCT_TYPE = '2'
             AND AGREEMENT_TYPE IN ('1', '2', '3', '4', '5', '6', '7')
             AND BUSINESS_TYP IN ('1', '2', '3', '4', '5', '6')
             AND A.DATA_DATE = I_DATADATE
       GROUP BY ORG_NUM,
                CASE
                  WHEN AGREEMENT_TYPE = 1 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.A'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.A'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.A'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.A'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.A'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.A'
                   END)
                  WHEN AGREEMENT_TYPE = 2 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.C'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.C'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.C'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.C'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.C'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.C'
                   END)
                  WHEN AGREEMENT_TYPE = 3 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.E'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.E'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.E'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.E'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.E'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.E'
                   END)
                  WHEN AGREEMENT_TYPE = 4 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.G'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.G'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.G'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.G'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.G'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.G'
                   END)
                  WHEN AGREEMENT_TYPE = 5 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.I'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.I'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.I'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.I'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.I'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.I'
                   END)
                  WHEN AGREEMENT_TYPE = 6 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.K'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.K'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.K'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.K'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.K'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.K'
                   END)
                  WHEN AGREEMENT_TYPE = 7 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.M'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.M'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.M'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.M'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.M'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.M'
                   END)
                END;
    COMMIT;
    V_STEP_DESC := '业务发生额-所有产品-2.1买入期权_2.6混合类  逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    V_STEP_ID   := 10;
    V_STEP_DESC := '业务发生额-人民币产品-2.1买入期权_2.6混合类  逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    --==================================================
    --   G02 业务发生额-人民币产品-2.1买入期权_2.6混合类
    --==================================================
   

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G02' AS REP_NUM, --报表编号
             CASE
               WHEN AGREEMENT_TYPE = 1 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.B'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.B'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.B'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.B'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.B'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.B'
                END)
               WHEN AGREEMENT_TYPE = 2 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.D'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.D'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.D'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.D'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.D'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.D'
                END)
               WHEN AGREEMENT_TYPE = 3 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.F'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.F'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.F'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.F'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.F'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.F'
                END)
               WHEN AGREEMENT_TYPE = 4 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.H'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.H'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.H'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.H'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.H'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.H'
                END)
               WHEN AGREEMENT_TYPE = 5 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.J'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.J'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.J'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.J'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.J'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.J'
                END)
               WHEN AGREEMENT_TYPE = 6 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.L'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.L'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.L'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.L'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.L'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.L'
                END)
               WHEN AGREEMENT_TYPE = 7 THEN
                (CASE
                  WHEN BUSINESS_TYP = '1' THEN
                   'G02_3_2.1.N'
                  WHEN BUSINESS_TYP = '2' THEN
                   'G02_3_2.2.N'
                  WHEN BUSINESS_TYP = '3' THEN
                   'G02_3_2.3.N'
                  WHEN BUSINESS_TYP = '4' THEN
                   'G02_3_2.4.N'
                  WHEN BUSINESS_TYP = '5' THEN
                   'G02_3_2.5.N'
                  WHEN BUSINESS_TYP = '6' THEN
                   'G02_3_2.6.N'
                END)
             END AS ITEM_NUM, --指标号
             SUM(CASE
               WHEN TRUNC(DEAL_DATE, 'Y') = D_NOW_YEAR THEN
                A.NOMINAL_CORPUS_BUY * U.CCY_RATE
               ELSE
                0
             END) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = A.CURR_CD1 --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE ACCT_TYPE = '2'
             AND AGREEMENT_TYPE IN ('1', '2', '3', '4', '5', '6', '7')
             AND BUSINESS_TYP IN ('1', '2', '3', '4', '5', '6')
             AND (CURR_CD1 = 'CNY' OR CURR_CD2 = 'CNY')
             AND A.DATA_DATE = I_DATADATE
       GROUP BY ORG_NUM,
                CASE
                  WHEN AGREEMENT_TYPE = 1 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.B'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.B'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.B'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.B'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.B'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.B'
                   END)
                  WHEN AGREEMENT_TYPE = 2 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.D'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.D'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.D'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.D'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.D'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.D'
                   END)
                  WHEN AGREEMENT_TYPE = 3 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.F'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.F'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.F'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.F'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.F'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.F'
                   END)
                  WHEN AGREEMENT_TYPE = 4 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.H'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.H'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.H'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.H'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.H'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.H'
                   END)
                  WHEN AGREEMENT_TYPE = 5 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.J'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.J'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.J'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.J'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.J'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.J'
                   END)
                  WHEN AGREEMENT_TYPE = 6 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.L'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.L'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.L'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.L'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.L'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.L'
                   END)
                  WHEN AGREEMENT_TYPE = 7 THEN
                   (CASE
                     WHEN BUSINESS_TYP = '1' THEN
                      'G02_3_2.1.N'
                     WHEN BUSINESS_TYP = '2' THEN
                      'G02_3_2.2.N'
                     WHEN BUSINESS_TYP = '3' THEN
                      'G02_3_2.3.N'
                     WHEN BUSINESS_TYP = '4' THEN
                      'G02_3_2.4.N'
                     WHEN BUSINESS_TYP = '5' THEN
                      'G02_3_2.5.N'
                     WHEN BUSINESS_TYP = '6' THEN
                      'G02_3_2.6.N'
                   END)
                END;

    COMMIT;
    V_STEP_DESC := '业务发生额-人民币产品-2.1买入期权_2.6混合类   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    V_STEP_ID   := 11;
    V_STEP_DESC := '交易对手-业务存量-1.1银行业金融机构_1.5个人客户 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    --==================================================
    --   G02 交易对手-业务存量-1.1银行业金融机构_1.5个人客户
    --==================================================
   

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G02' AS REP_NUM, --报表编号
             CASE
               WHEN AGREEMENT_TYPE = '1' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.A'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.A'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.A'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.A'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.A'
                END)
               WHEN AGREEMENT_TYPE = '2' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.C'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.C'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.C'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.C'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.C'
                END)
               WHEN AGREEMENT_TYPE = '3' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.E'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.E'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.E'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.E'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.E'
                END)
               WHEN AGREEMENT_TYPE = '4' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.G'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.G'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.G'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.G'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.G'
                END)
               WHEN AGREEMENT_TYPE = '5' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.I'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.I'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.I'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.I'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.I'
                END)
               WHEN AGREEMENT_TYPE = '6' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.K'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.K'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.K'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.K'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.K'
                END)
               WHEN AGREEMENT_TYPE = '7' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.M'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.M'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.M'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.M'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.M'
                END)
             END AS ITEM_NUM, --指标号
             SUM(A.NOMINAL_CORPUS_BUY * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = A.CURR_CD1 --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL B
               ON A.OPPO_PTY_CD = B.CUST_ID
              AND B.DATA_DATE = I_DATADATE
        INNER JOIN SMTMODS_L_CUST_C C
                ON B.CUST_ID = C.CUST_ID
               AND C.DATA_DATE = I_DATADATE
       WHERE AGREEMENT_TYPE IN ('1', '2', '3', '4', '5', '6', '7')
             AND BUSINESS_TYP IN ('1', '2', '3', '4', '5', '6')
             AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN AGREEMENT_TYPE = '1' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.A'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.A'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.A'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.A'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.A'
                   END)
                  WHEN AGREEMENT_TYPE = '2' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.C'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.C'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.C'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.C'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.C'
                   END)
                  WHEN AGREEMENT_TYPE = '3' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.E'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.E'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.E'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.E'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.E'
                   END)
                  WHEN AGREEMENT_TYPE = '4' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.G'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.G'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.G'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.G'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.G'
                   END)
                  WHEN AGREEMENT_TYPE = '5' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.I'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.I'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.I'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.I'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.I'
                   END)
                  WHEN AGREEMENT_TYPE = '6' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.K'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.K'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.K'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.K'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.K'
                   END)
                  WHEN AGREEMENT_TYPE = '7' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.M'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.M'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.M'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.M'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.M'
                   END)
                END;
    COMMIT;
    V_STEP_DESC := '交易对手-业务存量-1.1银行业金融机构_1.5个人客户  逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    V_STEP_ID   := 12;
    V_STEP_DESC := '交易对手-业务存量-1.1银行业金融机构_1.5个人客户 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    --==================================================
    --   G02 交易对手-市场价值-1.1银行业金融机构_1.5个人客户
    --==================================================
   

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G02' AS REP_NUM, --报表编号
             CASE
               WHEN AGREEMENT_TYPE = '1' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.B'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.B'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.B'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.B'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.B'
                END)
               WHEN AGREEMENT_TYPE = '2' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.D'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.D'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.D'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.D'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.D'
                END)
               WHEN AGREEMENT_TYPE = '3' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.F'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.F'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.F'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.F'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.F'
                END)
               WHEN AGREEMENT_TYPE = '4' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.H'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.H'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.H'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.H'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.H'
                END)
               WHEN AGREEMENT_TYPE = '5' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.J'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.J'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.J'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.J'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.J'
                END)
               WHEN AGREEMENT_TYPE = '6' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.L'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.L'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.L'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.L'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.L'
                END)
               WHEN AGREEMENT_TYPE = '7' THEN
                (CASE
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.1.N'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                   'G02_4_1.2.N'
                  WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                   'G02_4_1.3.N'
                  WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                   'G02_4_1.4.N'
                  WHEN B.CUST_TYPE = '00' THEN
                   'G02_4_1.5.N'
                END)
             END AS ITEM_NUM, --指标号
             SUM(A.RE_MARKET_VALUE * V.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
        LEFT JOIN SMTMODS_L_PUBL_RATE V
                  ON V.CCY_DATE = I_DATADATE
                 AND V.BASIC_CCY = A.RE_MARKET_VALUE_CCY --基准币种
                 AND V.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL B
               ON A.OPPO_PTY_CD = B.CUST_ID
              AND B.DATA_DATE = I_DATADATE
        INNER JOIN SMTMODS_L_CUST_C C
                ON B.CUST_ID = C.CUST_ID
               AND C.DATA_DATE = I_DATADATE
       WHERE AGREEMENT_TYPE IN ('1', '2', '3', '4', '5', '6', '7')
             AND BUSINESS_TYP IN ('1', '2', '3', '4', '5', '6')
             AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN AGREEMENT_TYPE = '1' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.B'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.B'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.B'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.B'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.B'
                   END)
                  WHEN AGREEMENT_TYPE = '2' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.D'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.D'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.D'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.D'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.D'
                   END)
                  WHEN AGREEMENT_TYPE = '3' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.F'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.F'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.F'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.F'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.F'
                   END)
                  WHEN AGREEMENT_TYPE = '4' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.H'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.H'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.H'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.H'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.H'
                   END)
                  WHEN AGREEMENT_TYPE = '5' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.J'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.J'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.J'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.J'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.J'
                   END)
                  WHEN AGREEMENT_TYPE = '6' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.L'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.L'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.L'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.L'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.L'
                   END)
                  WHEN AGREEMENT_TYPE = '7' THEN
                   (CASE
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.1.N'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND C.FINA_CODE NOT LIKE 'C%' AND B.INLANDORRSHORE_FLG = 'Y' THEN
                      'G02_4_1.2.N'
                     WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND B.INLANDORRSHORE_FLG = 'N' THEN
                      'G02_4_1.3.N'
                     WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                      'G02_4_1.4.N'
                     WHEN B.CUST_TYPE = '00' THEN
                      'G02_4_1.5.N'
                   END)
                END;

    COMMIT;
    V_STEP_DESC := '交易对手-业务存量-1.1银行业金融机构_1.5个人客户  逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    V_STEP_ID   := 13;
    V_STEP_DESC := '交易对手-正总市场价值-1.1银行业金融机构_1.5个人客户 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);
    --==================================================
    --   G02 交易对手-正总市场价值-1.1银行业金融机构_1.5个人客户
    --==================================================
   
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    SELECT I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G02' AS REP_NUM, --报表编号
       CASE
         WHEN COUNTERPARTY_TYP = '1' THEN
          'G02_4_1.1.P'
         WHEN COUNTERPARTY_TYP = '2' THEN
          'G02_4_1.2.P'
         WHEN COUNTERPARTY_TYP = '3' THEN
          'G02_4_1.3.P'
         WHEN COUNTERPARTY_TYP = '4' THEN
          'G02_4_1.4.P'
         WHEN COUNTERPARTY_TYP = '5' THEN
          'G02_4_1.5.P'
       END AS ITEM_NUM, --指标号
       SUM(T.RE_MARKET_VALUE * V.CCY_RATE) AS ITEM_VAL, --指标值
       '2' AS FLAG
  FROM (SELECT A.ORG_NUM,
               A.RE_MARKET_VALUE_CCY,
               CASE
                 WHEN B.CUST_TYPE = '00' THEN
                  '5'
                 WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                  '4'
                 WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND
                      C.FINA_CODE NOT LIKE 'C%' AND
                      B.INLANDORRSHORE_FLG = 'Y' THEN
                  '2'
                 WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND
                      B.INLANDORRSHORE_FLG = 'Y' THEN
                  '1'
                 WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND
                      B.INLANDORRSHORE_FLG = 'N' THEN
                  '3'
               END AS COUNTERPARTY_TYP, --交易对手类型 SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
               RE_MARKET_VALUE --估值损益
          FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
          LEFT JOIN SMTMODS_L_CUST_ALL B
            ON A.OPPO_PTY_CD = B.CUST_ID
           AND B.DATA_DATE = I_DATADATE
         INNER JOIN SMTMODS_L_CUST_C C
            ON B.CUST_ID = C.CUST_ID
           AND C.DATA_DATE = I_DATADATE
         WHERE RE_MARKET_VALUE > 0
           AND AGREEMENT_TYPE = '7'
           AND A.DATA_DATE = I_DATADATE) T
  LEFT JOIN SMTMODS_L_PUBL_RATE V ON V.CCY_DATE = I_DATADATE
                 AND V.BASIC_CCY = T.RE_MARKET_VALUE_CCY --基准币种
                 AND V.FORWARD_CCY = 'CNY' --折算币种
 WHERE T.COUNTERPARTY_TYP IN ('1', '2', '3', '4', '5')
 GROUP BY ORG_NUM,
          CASE
            WHEN COUNTERPARTY_TYP = '1' THEN
             'G02_4_1.1.P'
            WHEN COUNTERPARTY_TYP = '2' THEN
             'G02_4_1.2.P'
            WHEN COUNTERPARTY_TYP = '3' THEN
             'G02_4_1.3.P'
            WHEN COUNTERPARTY_TYP = '4' THEN
             'G02_4_1.4.P'
            WHEN COUNTERPARTY_TYP = '5' THEN
             'G02_4_1.5.P'
          END;

COMMIT;


    V_STEP_DESC := '交易对手-正总市场价值-1.1银行业金融机构_1.5个人客户  逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    V_STEP_ID   := 13;
    V_STEP_DESC := '交易对手-负总市场价值-1.1银行业金融机构_1.5个人客户 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);
    --==================================================
    --   G02 交易对手-负总市场价值-1.1银行业金融机构_1.5个人客户
    --==================================================
   

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G02' AS REP_NUM, --报表编号
             CASE
               WHEN COUNTERPARTY_TYP = '1' THEN
                'G02_4_1.1.Q'
               WHEN COUNTERPARTY_TYP = '2' THEN
                'G02_4_1.2.Q'
               WHEN COUNTERPARTY_TYP = '3' THEN
                'G02_4_1.3.Q'
               WHEN COUNTERPARTY_TYP = '4' THEN
                'G02_4_1.4.Q'
               WHEN COUNTERPARTY_TYP = '5' THEN
                'G02_4_1.5.Q'
             END AS ITEM_NUM, --指标号
             SUM(ABS(RE_MARKET_VALUE)) AS ITEM_VAL, --指标值
             '2' AS FLAG
  FROM (SELECT A.ORG_NUM,
               A.CURR_CD1,
               CASE
                 WHEN B.CUST_TYPE = '00' THEN
                  '5'
                 WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                  '4'
                 WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND
                      C.FINA_CODE NOT LIKE 'C%' AND
                      B.INLANDORRSHORE_FLG = 'Y' THEN
                  '2'
                 WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND
                      B.INLANDORRSHORE_FLG = 'Y' THEN
                  '1'
                 WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND
                      B.INLANDORRSHORE_FLG = 'N' THEN
                  '3'
               END AS COUNTERPARTY_TYP, --交易对手类型 SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
               RE_MARKET_VALUE --估值损益
          FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
          LEFT JOIN SMTMODS_L_CUST_ALL B
            ON A.OPPO_PTY_CD = B.CUST_ID
           AND B.DATA_DATE = I_DATADATE
         INNER JOIN SMTMODS_L_CUST_C C
            ON B.CUST_ID = C.CUST_ID
           AND C.DATA_DATE = I_DATADATE
         WHERE RE_MARKET_VALUE < 0
           AND AGREEMENT_TYPE = '7'
           AND A.DATA_DATE = I_DATADATE) T
 WHERE T.COUNTERPARTY_TYP IN ('1', '2', '3', '4', '5')
 GROUP BY ORG_NUM,
                CASE
                  WHEN COUNTERPARTY_TYP = '1' THEN
                   'G02_4_1.1.Q'
                  WHEN COUNTERPARTY_TYP = '2' THEN
                   'G02_4_1.2.Q'
                  WHEN COUNTERPARTY_TYP = '3' THEN
                   'G02_4_1.3.Q'
                  WHEN COUNTERPARTY_TYP = '4' THEN
                   'G02_4_1.4.Q'
                  WHEN COUNTERPARTY_TYP = '5' THEN
                   'G02_4_1.5.Q'
                END;

COMMIT;

    V_STEP_DESC := '交易对手-负总市场价值-1.1银行业金融机构_1.5个人客户  逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

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
   
END proc_cbrc_idx2_g02