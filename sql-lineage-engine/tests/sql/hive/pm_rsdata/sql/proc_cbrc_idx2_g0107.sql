CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g0107(II_DATADATE  IN STRING  --跑批日期
                                                   )
/******************************
  @AUTHOR:FANXIAOYU
  @CREATE-DATE:2015-09-20
  @DESCRIPTION:G0107
  @MODIFICATION HISTORY:
  M0.20150919-FANXIAOYU-G0107
  M1.20240118 shiyu 制度升级 新增指标：2.9.1电信、广播电视和卫星传输服务  2.9.2.互联网和相关服务 6.数字化效率提升业
  M2.20241224 shiyu  JLBA202412090001科技贷款知识产权密集型产业指标
  M3.20241224 SHIYU  从总账配置表ZH_ITEM_FORMULA出数据L_FINA_GL 程序
  m4.20250627 shiyu  修改内容：信用卡分期数据中新增了个性化分期数据，G0107中长期指标中需剔除。
  --需求编号：JLBA202507020013_关于吉林银行1104统一监管报送平台“五篇大文章”统计制度升级的需求 上线日期：20250729 修改人：石雨 提出人：于佳禾，修改内容：按照NGI数据贷款类型取数
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_A_REPT_DWD_G0107
视图表：SMTMODS_V_PUB_IDX_DK_YSDQRJJ
码值表：SMTMODS_PUB_KJDK  高技术产业
集市表：SMTMODS_L_ACCT_LOAN
     SMTMODS_L_PUBL_RATE
     SMTMODS_L_CUST_ALL
     SMTMODS_L_ACCT_FUND_INVEST
     SMTMODS_L_TRAN_CARDINSTALLMENT_CREDIT
     SMTMODS_L_ACCT_CARD_CREDIT
     SMTMODS_L_AGRE_LOAN_CONTRACT
  *******************************/
 IS
  --V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_REP_NUM   VARCHAR(30); --报表名称
  I_DATADATE  INTEGER; --数据日期(数值型)YYYYMMDD

  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  NUM            INTEGER;
  V_SYSTEM       VARCHAR(30);
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
	I_DATADATE := II_DATADATE;
    V_SYSTEM := 'CBRC';
    D_DATADATE_CCY := I_DATADATE;
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G0107');
	
    V_REP_NUM   := 'G01_7';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_REP_NUM || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = V_REP_NUM
       AND FLAG = '2';
    COMMIT;


   EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_G0107';

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--begin01 明细需求 zhoulp20250814


    V_STEP_ID   := 3;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '对境内贷款   逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    INSERT INTO CBRC_A_REPT_DWD_G0107
    (DATA_DATE, -- 数据日期
     ORG_NUM, -- 机构号
     DATA_DEPARTMENT, -- 数据条线
     SYS_NAM, -- 模块简称
     REP_NUM, -- 报表编号
     ITEM_NUM, -- 指标号
     TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       col_8 --字段8(贷款投向)
       )

      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             CASE
               WHEN LOAN_PURPOSE_CD LIKE 'A%' THEN
                'G01_7.2.1.A'
               WHEN LOAN_PURPOSE_CD LIKE 'B%' THEN
                'G01_7.2.2.A'
               WHEN LOAN_PURPOSE_CD LIKE 'C%' THEN
                'G01_7.2.3.A'
               WHEN LOAN_PURPOSE_CD LIKE 'D%' THEN
                'G01_7.2.4.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'E%' THEN
                'G01_7.2.5.A'
               WHEN LOAN_PURPOSE_CD LIKE 'F%' THEN
                'G01_7.2.6.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'G%' THEN
                'G01_7.2.7.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'H%' THEN
                'G01_7.2.8.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'I%' THEN
                'G01_7.2.9.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'J%' THEN
                'G01_7.2.10.A'
               WHEN LOAN_PURPOSE_CD LIKE 'K%' THEN
                'G01_7.2.11.A'
               WHEN LOAN_PURPOSE_CD LIKE 'L%' THEN
                'G01_7.2.12.A'
               WHEN LOAN_PURPOSE_CD LIKE 'M%' THEN
                'G01_7.2.13.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'N%' THEN
                'G01_7.2.14.A'
               WHEN LOAN_PURPOSE_CD LIKE 'O%' THEN
                'G01_7.2.15.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'P%' THEN
                'G01_7.2.16.A'
               WHEN LOAN_PURPOSE_CD LIKE 'Q%' THEN
                'G01_7.2.17.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'R%' THEN
                'G01_7.2.18.A'
               WHEN LOAN_PURPOSE_CD LIKE 'S%' THEN
                'G01_7.2.19.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'T%' THEN
                'G01_7.2.20.A'
             END AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) + NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS col_8 --字段8(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND (A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%')
         AND A.ACCT_TYP NOT LIKE '0301%'
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND SUBSTR(A.LOAN_PURPOSE_CD, 1, 1) IN ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T')

      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             CASE
               WHEN LOAN_PURPOSE_CD LIKE 'A%' THEN
                'G01_7.2.1.A'
               WHEN LOAN_PURPOSE_CD LIKE 'B%' THEN
                'G01_7.2.2.A'
               WHEN LOAN_PURPOSE_CD LIKE 'C%' THEN
                'G01_7.2.3.A'
               WHEN LOAN_PURPOSE_CD LIKE 'D%' THEN
                'G01_7.2.4.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'E%' THEN
                'G01_7.2.5.A'
               WHEN LOAN_PURPOSE_CD LIKE 'F%' THEN
                'G01_7.2.6.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'G%' THEN
                'G01_7.2.7.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'H%' THEN
                'G01_7.2.8.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'I%' THEN
                'G01_7.2.9.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'J%' THEN
                'G01_7.2.10.A'
               WHEN LOAN_PURPOSE_CD LIKE 'K%' THEN
                'G01_7.2.11.A'
               WHEN LOAN_PURPOSE_CD LIKE 'L%' THEN
                'G01_7.2.12.A'
               WHEN LOAN_PURPOSE_CD LIKE 'M%' THEN
                'G01_7.2.13.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'N%' THEN
                'G01_7.2.14.A'
               WHEN LOAN_PURPOSE_CD LIKE 'O%' THEN
                'G01_7.2.15.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'P%' THEN
                'G01_7.2.16.A'
               WHEN LOAN_PURPOSE_CD LIKE 'Q%' THEN
                'G01_7.2.17.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'R%' THEN
                'G01_7.2.18.A'
               WHEN LOAN_PURPOSE_CD LIKE 'S%' THEN
                'G01_7.2.19.A.2012'
               WHEN LOAN_PURPOSE_CD LIKE 'T%' THEN
                'G01_7.2.20.A'
             END AS ITEM_NUM, -- 指标号
             NVL(LOAN_ACCT_BAL, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS col_8 --字段8(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE FUND_USE_LOC_CD = 'I'
         AND A.DATA_DATE = I_DATADATE
         AND LENGTHB(ACCT_NUM) < 36
         AND CANCEL_FLG = 'N'
         AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (ITEM_CD LIKE '130101%' or ITEM_CD LIKE '130104%')
         AND SUBSTR(LOAN_PURPOSE_CD, 1, 1) IN   ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T');
    COMMIT;
--end01 明细需求 zhoulp20250814
    V_STEP_FLAG := 1;
    V_STEP_DESC := '对境内贷款   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := 4;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '对境外贷款   逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --==================================================
    --   G0107   3.对境外贷款
    --==================================================
--begin02 明细需求 zhoulp20250814


    INSERT INTO CBRC_A_REPT_DWD_G0107
    (DATA_DATE, -- 数据日期
     ORG_NUM, -- 机构号
     DATA_DEPARTMENT, -- 数据条线
     SYS_NAM, -- 模块简称
     REP_NUM, -- 报表编号
     ITEM_NUM, -- 指标号
     TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       col_8 --字段8(贷款投向)
       )

      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.3..A' AS ITEM_NUM, -- 指标号
             NVL(LOAN_ACCT_BAL * B.CCY_RATE, 0) +  NVL(INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS col_8 --字段8(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'O'
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
            --AND ORG_NUM NOT LIKE '5100%'
         AND A.DATA_DATE = I_DATADATE;
    COMMIT;
--end02 明细需求 zhoulp20250814

    V_STEP_FLAG := 1;
    V_STEP_DESC := '对境外贷款   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 7;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '信用卡-买断式转贴现   逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ---alter by 20241224 从总账配置表ZH_ITEM_FORMULA出数据L_FINA_GL 程序
   

--begin03 明细需求 zhoulp20250814


    INSERT INTO CBRC_A_REPT_DWD_G0107
    (DATA_DATE, -- 数据日期
     ORG_NUM, -- 机构号
     DATA_DEPARTMENT, -- 数据条线
     SYS_NAM, -- 模块简称
     REP_NUM, -- 报表编号
     ITEM_NUM, -- 指标号
     TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       col_8 --字段8(贷款投向)
       )

             SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.2.21.2.A' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0) +  NVL(A.INT_ADJEST_AMT * U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS col_8 --字段8(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.FUND_USE_LOC_CD = 'I'
         AND A.ACCT_TYP = '010301'
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36;
    COMMIT;
--end03 明细需求 zhoulp20250814

--begin04 明细需求 zhoulp20250814


    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       col_8 --字段8(贷款投向)
       )

      SELECT I_DATADATE,
             T.ORG_NUM, --机构号
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.2.21.3.A' AS ITEM_NUM, -- 指标号
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) +
             NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             T.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             T.LOAN_NUM AS col_4, --字段4(贷款编号)
             T.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             TO_CHAR(T.DRAWDOWN_DT,'YYYYMMDD') AS COL_6, --字段6(放款日期)
             TO_CHAR(T.MATURITY_DT,'YYYYMMDD') AS COL_7, --字段7(原始借据到期日期)
             T.LOAN_PURPOSE_CD AS col_8 --字段8(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON T.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE T.FUND_USE_LOC_CD = 'I'
         AND T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0101%'
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(T.ACCT_NUM) < 36
            --AND ORG_NUM NOT LIKE '5100%'
         AND T.ACCT_STS <> '3'
      UNION ALL

      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.2.21.4.A' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0) +
             NVL(INT_ADJEST_AMT * U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS col_8 --字段8(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP LIKE '01%'
         AND A.ACCT_TYP <> '010301'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '0101%'
         AND A.ACCT_TYP NOT LIKE '0102%'
         AND A.ACCT_STS <> '3';

    COMMIT;
--end04 明细需求 zhoulp20250814

--begin05 明细需求 zhoulp20250814


    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5 --字段5(贷款合同编号)
       )

      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             '' AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.2.22.A' AS ITEM_NUM, -- 指标号
             NVL(A.FACE_VAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.ACCT_NUM AS col_4, --字段4(贷款编号)
             A.CONTRACT_NO AS col_5 --字段5(贷款合同编号)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I' --贷款资金使用位置（境内）
         AND A.INVEST_TYP = '11' --买断式转贴现
         AND A.DATA_DATE = I_DATADATE;
    COMMIT;
--end05 明细需求 zhoulp20250814

    V_STEP_FLAG := 1;
    V_STEP_DESC := '信用卡-买断式转贴现   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -------------------------------------------------------------------------------------------
    ------------------------------中长期贷款逻辑加工开始---------------------------------------
    -------------------------------------------------------------------------------------------

    V_STEP_FLAG := 1;
    V_STEP_DESC := '中长期贷款逻辑加工开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--begin06 明细需求 zhoulp20250814


    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       col_8 --字段8(贷款投向)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             CASE
               WHEN LOAN_PURPOSE_CD LIKE 'A%' THEN
                'G01_7.2.1.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'B%' THEN
                'G01_7.2.2.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'C%' THEN
                'G01_7.2.3.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'D%' THEN
                'G01_7.2.4.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'E%' THEN
                'G01_7.2.5.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'F%' THEN
                'G01_7.2.6.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'G%' THEN
                'G01_7.2.7.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'H%' THEN
                'G01_7.2.8.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'I%' THEN
                'G01_7.2.9.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'J%' THEN
                'G01_7.2.10.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'K%' THEN
                'G01_7.2.11.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'L%' THEN
                'G01_7.2.12.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'M%' THEN
                'G01_7.2.13.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'N%' THEN
                'G01_7.2.14.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'O%' THEN
                'G01_7.2.15.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'P%' THEN
                'G01_7.2.16.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'Q%' THEN
                'G01_7.2.17.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'R%' THEN
                'G01_7.2.18.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'S%' THEN
                'G01_7.2.19.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'T%' THEN
                'G01_7.2.20.B.2022'
             END AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS col_8 --字段8(贷款投向)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND (A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%')
         AND A.ACCT_TYP NOT LIKE '0301%'
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND SUBSTR(A.LOAN_PURPOSE_CD, 1, 1) IN   ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T')
      UNION ALL

      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             CASE
               WHEN LOAN_PURPOSE_CD LIKE 'A%' THEN
                'G01_7.2.1.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'B%' THEN
                'G01_7.2.2.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'C%' THEN
                'G01_7.2.3.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'D%' THEN
                'G01_7.2.4.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'E%' THEN
                'G01_7.2.5.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'F%' THEN
                'G01_7.2.6.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'G%' THEN
                'G01_7.2.7.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'H%' THEN
                'G01_7.2.8.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'I%' THEN
                'G01_7.2.9.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'J%' THEN
                'G01_7.2.10.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'K%' THEN
                'G01_7.2.11.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'L%' THEN
                'G01_7.2.12.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'M%' THEN
                'G01_7.2.13.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'N%' THEN
                'G01_7.2.14.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'O%' THEN
                'G01_7.2.15.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'P%' THEN
                'G01_7.2.16.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'Q%' THEN
                'G01_7.2.17.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'R%' THEN
                'G01_7.2.18.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'S%' THEN
                'G01_7.2.19.B.2022'
               WHEN LOAN_PURPOSE_CD LIKE 'T%' THEN
                'G01_7.2.20.B.2022'
             END AS ITEM_NUM, -- 指标号
             NVL(LOAN_ACCT_BAL, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS col_8 --字段8(贷款投向)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE FUND_USE_LOC_CD = 'I'
         AND A.DATA_DATE = I_DATADATE
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12
         AND (A.ITEM_CD LIKE '130101%' or A.ITEM_CD LIKE '130104%')
         AND SUBSTR(A.LOAN_PURPOSE_CD, 1, 1) IN  ('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T');
    COMMIT;
--end06 明细需求 zhoulp20250814

    V_STEP_FLAG := 1;
    V_STEP_DESC := '中长期对境内贷款   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 4;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '中长期对境外贷款   逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --==================================================
    --   G0107   3.对境外贷款 中长期贷款
    --==================================================
--begin07 明细需求 zhoulp20250814


    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       col_8 --字段8(贷款投向)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.3..B.2022' AS ITEM_NUM, -- 指标号
             NVL(LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS col_8 --字段8(贷款投向)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'O'
         AND A.ACCT_STS <> '3'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12
         AND A.DATA_DATE = I_DATADATE;
    COMMIT;

--end07 明细需求 zhoulp20250814
    V_STEP_ID   := 7;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '中长期信用卡-买断式转贴现   逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--begin08 明细需求 zhoulp20250814


    INSERT INTO CBRC_A_REPT_DWD_G0107
    (DATA_DATE, -- 数据日期
     ORG_NUM, -- 机构号
     DATA_DEPARTMENT, -- 数据条线
     SYS_NAM, -- 模块简称
     REP_NUM, -- 报表编号
     ITEM_NUM, -- 指标号
     TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4  --字段4(贷款编号)
       )
             SELECT I_DATADATE,
             T.ORG_NUM, --机构号
             '' AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.2.21.1.B.2022' AS ITEM_NUM, -- 指标号
             NVL(T.INSTAL_BAL, 0) AS TOTAL_VALUE, -- 汇总值
             T.CUST_ID AS col_2, --字段2(客户号)
             A.CUST_NAM AS col_3, --字段3(客户名)
             T.CARD_NO AS col_4 --字段4(贷款编号)
        FROM SMTMODS_L_TRAN_CARDINSTALLMENT_CREDIT T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1 -- 信用卡账户信息表  add by zhoulp 20241120 业务夏文博 卡掉收益权转让的数据
          ON T.Acct_Num = T1.Acct_Num
         AND T.DATA_DATE = T1.DATA_DATE
         AND T1.DEALDATE = '00000000' --资产转让日期
        LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID = A.CUST_ID
         AND T.DATA_DATE = A.DATA_DATE
       WHERE T.DATA_DATE = I_DATADATE
         AND NVL(A.CUST_TYPE, '0') <> '11'
         AND T.INSTALLMENT_NUM > 12
         AND T.INSTAL_TRANS_TYPE <> 'G' --alter by 20250627 剔除个性化分期数据
       ;

    COMMIT;
--end08 明细需求 zhoulp20250814


--begin09 明细需求 zhoulp20250814


    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段6(贷款合同编号)
       COL_6, --放款日期
       COL_7 --原始到期日
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.2.21.2.B.2022' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * U.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段6(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段7(放款日期)
             A.MATURITY_DT AS COL_7 --字段8(原始借据到期日期)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.FUND_USE_LOC_CD = 'I'
         AND A.ACCT_TYP = '010301'
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36;
    COMMIT;
--end09 明细需求 zhoulp20250814

--begin10 明细需求 zhoulp20250814


    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段6(贷款合同编号)
       COL_6, --放款日期
       COL_7 --原始到期日
       )
      SELECT I_DATADATE,
             T.ORG_NUM, --机构号
             T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.2.21.3.B.2022' AS ITEM_NUM, -- 指标号
             NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0) +
             NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             T.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             T.LOAN_NUM AS col_4, --字段4(贷款编号)
             T.ACCT_NUM AS col_5, --字段6(贷款合同编号)
             TO_CHAR(T.DRAWDOWN_DT,'YYYYMMDD') AS COL_6, --字段7(放款日期)
             TO_CHAR(T.MATURITY_DT,'YYYYMMDD') AS COL_7 --字段8(原始借据到期日期)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON T.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE T.FUND_USE_LOC_CD = 'I'
         AND T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0101%'
         AND LENGTHB(T.ACCT_NUM) < 36
         AND MONTHS_BETWEEN(DATE(T.MATURITY_DT), DATE(T.DRAWDOWN_DT)) > 12
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_STS <> '3'
      UNION ALL

      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.2.21.4.B.2022' AS ITEM_NUM, -- 指标号
             NVL(LOAN_ACCT_BAL * U.CCY_RATE, 0) +
             NVL(INT_ADJEST_AMT * U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段6(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段7(放款日期)
             A.MATURITY_DT AS COL_7 --字段8(原始借据到期日期)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP LIKE '01%'
         AND A.ACCT_TYP <> '010301'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '0101%'
         AND A.ACCT_TYP NOT LIKE '0102%'
         AND A.ACCT_STS <> '3'
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12;

    COMMIT;
--end10 明细需求 zhoulp20250814
    V_STEP_FLAG := 1;
    V_STEP_DESC := '信用卡-买断式转贴现   逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --==================================================
    --   G0107 4.高技术产业
    --==================================================

    V_STEP_ID   := 5;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '高技术产业   逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --高技术产业 各项贷款

    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       COL_2, --字段2(客户号)
       COL_3, --字段3(客户名)
       COL_4, --字段4(贷款编号)
       COL_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       COL_8 --字段9(贷款投向)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.4..A.2022' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS COL_8 --字段8(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND A.ACCT_TYP NOT LIKE '0301%'
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%')
         AND LENGTHB(A.ACCT_NUM) < 36
         AND ACCT_TYP NOT LIKE '0301%' --SHIWENBO BY 20170316-12901 单独取直贴
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_PURPOSE_CD IN
             (SELECT CODE FROM SMTMODS_PUB_KJDK WHERE FLAG = '4')
      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.4..A.2022' AS ITEM_NUM, -- 指标号
             NVL(LOAN_ACCT_BAL, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS COL_8 --字段8(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE FUND_USE_LOC_CD = 'I'
         AND A.DATA_DATE = I_DATADATE
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND (A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%')
         AND A.LOAN_PURPOSE_CD IN
             (SELECT CODE FROM SMTMODS_PUB_KJDK WHERE FLAG = '4');
    COMMIT;

    --高技术产业 中长期贷款

    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       COL_8 --字段8(贷款投向)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.4..B.2022' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS COL_8 --字段8(贷款投向)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND A.ACCT_TYP NOT LIKE '0301%'
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%')
         AND LENGTHB(A.ACCT_NUM) < 36
         AND ACCT_TYP NOT LIKE '0301%' --SHIWENBO BY 20170316-12901 单独取直贴
         AND A.DATA_DATE = I_DATADATE
         AND A.LOAN_PURPOSE_CD IN
             (SELECT CODE FROM SMTMODS_PUB_KJDK WHERE FLAG = '4')
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12
      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.4..B.2022' AS ITEM_NUM, -- 指标号
             NVL(LOAN_ACCT_BAL, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS COL_8 --字段8(贷款投向)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE FUND_USE_LOC_CD = 'I'
         AND A.DATA_DATE = I_DATADATE
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
            --AND ORG_NUM NOT LIKE '5100%'
         AND (ITEM_CD LIKE '130101%' OR ITEM_CD LIKE '130104%')
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12
         AND A.LOAN_PURPOSE_CD IN
             (SELECT CODE FROM SMTMODS_PUB_KJDK WHERE FLAG = '4');
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '高技术产业  逻辑处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --==================================================
    --   G0107 5.数字经济核心产业
    --==================================================

    V_STEP_ID   := 5;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '数字经济核心产业 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --数字经济核心产业 各项贷款
    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       COL_8 --字段8(数字经济核心产业贷款)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             CASE
               WHEN SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '01' THEN
                'G01_7.5.1.A.2022' --5.1数字产品制造业
               WHEN SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '02' THEN
                'G01_7.5.2.A.2022' --5.2数字产品服务业
               WHEN SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '03' THEN
                'G01_7.5.3.A.2022' --5.3数字技术应用业
               WHEN SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '04' THEN
                'G01_7.5.4.A.2022' --5.4数字要素驱动业
             END AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             D.DIGITAL_ECONOMY_INDUSTRY AS COL_8 --字段8(数字经济核心产业贷款)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       INNER JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
         AND SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04')
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND A.ACCT_TYP NOT LIKE '0301%'
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%')
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '0301%' --SHIWENBO BY 20170316-12901 单独取直贴
         AND A.DATA_DATE = I_DATADATE
      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             CASE
               WHEN SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '01' THEN
                'G01_7.5.1.A.2022' --5.1数字产品制造业
               WHEN SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '02' THEN
                'G01_7.5.2.A.2022' --5.2数字产品服务业
               WHEN SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '03' THEN
                'G01_7.5.3.A.2022' --5.3数字技术应用业
               WHEN SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '04' THEN
                'G01_7.5.4.A.2022' --5.4数字要素驱动业
             END AS ITEM_NUM, -- 指标号
             NVL(LOAN_ACCT_BAL, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.DIGITAL_ECONOMY_INDUSTRY AS COL_8 --字段8(数字经济核心产业贷款)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE FUND_USE_LOC_CD = 'I'
         AND A.DATA_DATE = I_DATADATE
         AND LENGTHB(ACCT_NUM) < 36
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (ITEM_CD LIKE '130101%' OR ITEM_CD LIKE '130104%')
         AND SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04') --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
      ;
    COMMIT;

    --数字经济核心产业 中长期贷款

    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       COL_8 --字段8(数字经济核心产业贷款)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             CASE
               WHEN SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '01' THEN
                'G01_7.5.1.B.2022' --5.1数字产品制造业
               WHEN SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '02' THEN
                'G01_7.5.2.B.2022' --5.2数字产品服务业
               WHEN SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '03' THEN
                'G01_7.5.3.B.2022' --5.3数字技术应用业
               WHEN SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '04' THEN
                'G01_7.5.4.B.2022' --5.4数字要素驱动业
             END AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             D.DIGITAL_ECONOMY_INDUSTRY AS COL_8 --字段8(数字经济核心产业贷款)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       INNER JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
         AND SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04') --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE

       WHERE A.FUND_USE_LOC_CD = 'I'
         AND A.ACCT_TYP NOT LIKE '0301%'
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --AND A.ORG_NUM NOT LIKE '5100%'
         AND (A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%')
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '0301%' --SHIWENBO BY 20170316-12901 单独取直贴
         AND A.DATA_DATE = I_DATADATE
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12

      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             CASE
               WHEN SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '01' THEN
                'G01_7.5.1.B.2022' --5.1数字产品制造业
               WHEN SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '02' THEN
                'G01_7.5.2.B.2022' --5.2数字产品服务业
               WHEN SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '03' THEN
                'G01_7.5.3.B.2022' --5.3数字技术应用业
               WHEN SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) = '04' THEN
                'G01_7.5.4.B.2022' --5.4数字要素驱动业
             END AS ITEM_NUM, -- 指标号
             NVL(LOAN_ACCT_BAL, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.DIGITAL_ECONOMY_INDUSTRY AS COL_8 --字段8(数字经济核心产业贷款)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE FUND_USE_LOC_CD = 'I'
         AND A.DATA_DATE = I_DATADATE
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND (ITEM_CD LIKE '130101%' OR ITEM_CD LIKE '130104%')
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12
         AND SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04') --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
      ;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '数字经济核心产业 逻辑处理结束';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --==================================================
    --   G0107 6.知识产权密集型产业
    --==================================================

    V_STEP_ID   := 6;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '6.知识产权密集型产业 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --6.知识产权密集型产业 各项贷款

    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       COL_8 --字段8(知识产权密集型产业)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.6..A.2022' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             C.PANT_DENS_INDU AS COL_8 --字段8(知识产权密集型产业)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON A.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND A.ACCT_TYP NOT LIKE '0301%'
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%')
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '0301%' --SHIWENBO BY 20170316-12901 单独取直贴
         AND A.DATA_DATE = I_DATADATE
            --AND A.ORG_NUM NOT LIKE '5100%'
            --  AND A.LOAN_PURPOSE_CD IN (SELECT CODE FROM SMTMODS_PUB_KJDK WHERE FLAG = '6')
         AND nvl(C.PANT_DENS_INDU, '0') <> '0' --ALTER BY SHIYU 20241023  -ngi新增字段知识产权（专利）密集型产业 判断JLBA202412090001

      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.6..A.2022' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             C.PANT_DENS_INDU AS COL_8 --字段8(知识产权密集型产业)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON A.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND A.DATA_DATE = I_DATADATE
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
            --AND A.ORG_NUM NOT LIKE '5100%'
         AND (A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%') -- AND ITEM_CD LIKE '130101%'AND ITEM_CD LIKE  '130104%' -- 20221029 UPDATE BY WANGKUI
            --AND A.LOAN_PURPOSE_CD IN (SELECT CODE FROM SMTMODS_PUB_KJDK WHERE FLAG = '6')
         and nvl(C.PANT_DENS_INDU, '0') <> '0' --ALTER BY SHIYU 20241023  -ngi新增字段知识产权（专利）密集型产业 判断JLBA202412090001
      ;
    COMMIT;

    --6.知识产权密集型产业 中长期贷款

    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       COL_8 --字段8(知识产权密集型产业)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.6..B.2022' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             C.PANT_DENS_INDU AS COL_8 --字段8(知识产权密集型产业)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON A.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND A.ACCT_TYP NOT LIKE '0301%'
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
            --AND A.ORG_NUM NOT LIKE '5100%'
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%')
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '0301%' --SHIWENBO BY 20170316-12901 单独取直贴
         AND A.DATA_DATE = I_DATADATE
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12
            --AND A.LOAN_PURPOSE_CD IN (SELECT CODE FROM SMTMODS_PUB_KJDK WHERE FLAG = '6')
         and nvl(C.PANT_DENS_INDU, '0') <> '0' --ALTER BY SHIYU 20241023  -ngi新增字段知识产权（专利）密集型产业 判断JLBA202412090001

      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.6..B.2022' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             C.PANT_DENS_INDU AS COL_8 --字段8(知识产权密集型产业)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON A.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND A.DATA_DATE = I_DATADATE
            --AND A.ORG_NUM NOT LIKE '5100%'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
         AND (A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%')
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12
            -- AND A.LOAN_PURPOSE_CD IN(SELECT CODE FROM SMTMODS_PUB_KJDK WHERE FLAG = '6')
         and nvl(C.PANT_DENS_INDU, '0') <> '0' --ALTER BY SHIYU 20241023  -ngi新增字段知识产权（专利）密集型产业 判断JLBA202412090001
      ;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '6.知识产权密集型产业 逻辑处理结束';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := V_STEP_ID + 1;
    V_STEP_DESC := '2.9.1电信、广播电视和卫星传输服务 逻辑处理结束';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --alter by 20240118 制度升级新增指标
    --2.9.1电信、广播电视和卫星传输服务
    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       COL_8 --字段8(贷款投向)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.2.9.1.A' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS COL_8 --字段8(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND A.ACCT_TYP NOT LIKE '90%') OR
             (A.ITEM_CD LIKE '130101%' or A.ITEM_CD LIKE '130104%'))
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
            --AND ORG_NUM NOT LIKE '5100%'
         AND SUBSTR(A.LOAN_PURPOSE_CD, 1, 3) IN ('I63');
    commit;

    ---中长期
    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       COL_8 --字段8(贷款投向)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.2.9.1.B' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS COL_8 --字段8(贷款投向)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND A.ACCT_TYP NOT LIKE '90%') OR
             (A.ITEM_CD LIKE '130101%' or A.ITEM_CD LIKE '130104%'))
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
            --AND ORG_NUM NOT LIKE '5100%'
         AND SUBSTR(A.LOAN_PURPOSE_CD, 1, 3) IN ('I63')
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12;
    commit;

    V_STEP_FLAG := V_STEP_ID + 1;
    V_STEP_DESC := '2.9.2.互联网和相关服务 逻辑处理结束';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --2.9.2.互联网和相关服务
    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段6(原始到期日)
       COL_8 --字段8(贷款投向)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.2.9.2.A' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS COL_8 --字段8(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND A.ACCT_TYP NOT LIKE '90%') OR
             (A.ITEM_CD LIKE '130101%' or A.ITEM_CD LIKE '130104%'))
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
            --AND ORG_NUM NOT LIKE '5100%'
         AND SUBSTR(A.LOAN_PURPOSE_CD, 1, 3) IN ('I64');
    commit;

    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段6(原始到期日)
       COL_8 --字段8(贷款投向)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.2.9.2.B' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD') AS COL_6, --字段6(放款日期)
             TO_CHAR(A.MATURITY_DT, 'YYYYMMDD') AS COL_7, --字段7(原始借据到期日期)
             A.LOAN_PURPOSE_CD AS COL_8 --字段8(贷款投向)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND A.ACCT_TYP NOT LIKE '90%') OR
             (A.ITEM_CD LIKE '130101%' or A.ITEM_CD LIKE '130104%'))
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND LENGTHB(A.ACCT_NUM) < 36
            --AND ORG_NUM NOT LIKE '5100%'
         AND SUBSTR(A.LOAN_PURPOSE_CD, 1, 3) IN ('I64')
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12;
    commit;

    --20250318
    V_STEP_FLAG := V_STEP_ID + 1;
    V_STEP_DESC := '养老产业 逻辑处理结束';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --贷款余额
    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_5, --字段5(贷款合同编号)
       COL_6, --字段6(放款日期)
       COL_7, --字段7(原始到期日)
       COL_8 --字段8(养老产业贷款)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.8.A' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             CASE
               WHEN A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%' THEN
                A.PENSION_INDUSTRY
               ELSE
                D.PENSION_INDUSTRY
             END AS COL_8 --字段8(养老产业贷款)
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
         AND SUBSTR(D.PENSION_INDUSTRY, 1, 2) IN
             ('01',
              '02',
              '03',
              '04',
              '05',
              '06',
              '07',
              '08',
              '09',
              '10',
              '11',
              '12')
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            -- AND A.LOAN_PURPOSE_CD IN ('Q8514', 'Q8416') --Q8514老年人、残疾人养护服务  Q8416疗养院
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' and
             D.PENSION_INDUSTRY IS NOT NULL /*养老产业*/
             ) --SHIWENBO BY 20170316-12901 单独取直贴
             OR ((A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%') and
             a.PENSION_INDUSTRY IS NOT NULL /*养老产业*/
             ));
    COMMIT;
    --中长期
    INSERT INTO CBRC_A_REPT_DWD_G0107
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       col_6, --字段6(贷款合同编号)
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_18 --字段18(养老产业贷款)
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_7.8.B' AS ITEM_NUM, -- 指标号
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             A.ACCT_NUM AS col_5, --字段5(贷款合同编号)
             A.DRAWDOWN_DT AS COL_6, --字段6(放款日期)
             A.MATURITY_DT AS COL_7, --字段7(原始借据到期日期)
             CASE
               WHEN A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%' THEN
                A.PENSION_INDUSTRY
               ELSE
                D.PENSION_INDUSTRY
             END AS COL_8 --字段8(养老产业贷款)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
         AND SUBSTR(D.PENSION_INDUSTRY, 1, 2) IN
             ('01',
              '02',
              '03',
              '04',
              '05',
              '06',
              '07',
              '08',
              '09',
              '10',
              '11',
              '12')
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --AND A.LOAN_PURPOSE_CD IN ('Q8514', 'Q8416') --Q8514老年人、残疾人养护服务  Q8416疗养院
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' and
             D.PENSION_INDUSTRY IS NOT NULL /*养老产业*/
             ) --SHIWENBO BY 20170316-12901 单独取直贴
             OR ((A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%') and
             a.PENSION_INDUSTRY IS NOT NULL /*养老产业*/
             ))
         AND MONTHS_BETWEEN(DATE(A.MATURITY_DT), DATE(A.DRAWDOWN_DT)) > 12 --中长期
      -- GROUP BY A.ORG_NUM
      ;
    COMMIT;


    /*---------------------所有指标明细汇总插入目标表-----------------------------------  */

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       DATA_DEPARTMENT)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_7' AS REP_NUM,
             T.ITEM_NUM,
             SUM(TOTAL_VALUE) AS ITEM_VAL,
             '2' AS FLAG,
             DATA_DEPARTMENT
        FROM CBRC_A_REPT_DWD_G0107 T
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM, T.ITEM_NUM, DATA_DEPARTMENT;
       COMMIT;

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
END proc_cbrc_idx2_g0107