-- ============================================================
-- 文件名: G01_I(b) 委托贷款投向统计表.sql
-- 生成时间: 2025-12-18 13:53:37
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 16 个指标 ==========
FROM (
SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     V_REP_NUM AS REP_NUM, -- 报表编号
     CASE SUBSTR(A.LOAN_PURPOSE_CD, 1, 1)
       WHEN 'A' THEN
        'G01_I_2.2.1.A.2016'
       WHEN 'B' THEN
        'G01_I_2.2.2.A.2016'
       WHEN 'C' THEN
        'G01_I_2.2.3.A.2016'
       WHEN 'D' THEN
        'G01_I_2.2.4.A.2016'
       WHEN 'E' THEN
        'G01_I_2.2.5.A.2016'
       WHEN 'F' THEN
        'G01_I_2.2.6.A.2016'
       WHEN 'G' THEN
        'G01_I_2.2.7.A.2016'
       WHEN 'H' THEN
        'G01_I_2.2.8.A.2016'
       WHEN 'I' THEN
        'G01_I_2.2.9.A.2016'
       WHEN 'J' THEN
        'G01_I_2.2.10.A.2016'
       WHEN 'K' THEN
        'G01_I_2.2.11.A.2016'
       WHEN 'L' THEN
        'G01_I_2.2.12.A.2016'
       WHEN 'M' THEN
        'G01_I_2.2.13.A.2016'
       WHEN 'N' THEN
        'G01_I_2.2.14.A.2016'
       WHEN 'O' THEN
        'G01_I_2.2.15.A.2016'
       WHEN 'P' THEN
        'G01_I_2.2.16.A.2016'
       WHEN 'Q' THEN
        'G01_I_2.2.17.A.2016'
       WHEN 'R' THEN
        'G01_I_2.2.18.A.2016'
       WHEN 'S' THEN
        'G01_I_2.2.19.A.2016'
       WHEN 'T' THEN
        'G01_I_2.2.20.A.2016'
     END AS ITEM_NUM, -- 指标号
     A.LOAN_ACCT_BAL * NVL(U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
     A.ACCT_NUM AS COL_1, -- 合同号
     A.LOAN_NUM AS COL_2, -- 借据号
     A.CUST_ID AS COL_3, -- 客户号
     A.DRAWDOWN_AMT AS COL_4, -- 放款金额
     A.DRAWDOWN_DT AS COL_5, -- 放款日期
     A.MATURITY_DT AS COL_6, -- 原始到期日期
     A.ITEM_CD AS COL_7, -- 科目号
     A.CURR_CD AS COL_8, -- 币种
     A.ACCT_TYP AS COL_9, -- 账户类型
     A.LOAN_PURPOSE_CD AS COL_10 -- 贷款投向
      FROM SMTMODS_L_ACCT_LOAN A
     INNER JOIN SMTMODS_L_CUST_ALL B
        ON A.CUST_ID = B.CUST_ID
       AND B.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON A.DATA_DATE = U.DATA_DATE
       AND U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD -- 基准币种
       AND U.FORWARD_CCY = 'CNY' -- 折算币种
     WHERE A.DATA_DATE = I_DATADATE
       AND B.INLANDORRSHORE_FLG = 'Y'
       AND A.ACCT_TYP LIKE '90%'
       AND A.CANCEL_FLG = 'N'
       AND LENGTHB(A.ACCT_NUM) < 36
       AND A.ENTRUST_PURPOSE_CD IS NULL
       AND A.LOAN_STOCKEN_DATE IS NULL -- add by haorui 20250311 JLBA202408200012 资产未转让
       AND A.LOAN_ACCT_BAL <> 0
) q_0
INSERT INTO `G01_I_2.2.2.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.17.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.14.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.3.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.8.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.1.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.13.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.6.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.16.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.18.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.15.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.12.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.9.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.4.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.11.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *
INSERT INTO `G01_I_2.2.5.A.2016` (DATA_DATE,  
     ORG_NUM,  
     DATA_DEPARTMENT,  
     SYS_NAM,  
     REP_NUM,  
     ITEM_NUM,  
     TOTAL_VALUE,  
     COL_1,  
     COL_2,  
     COL_3,  
     COL_4,  
     COL_5,  
     COL_6,  
     COL_7,  
     COL_8,  
     COL_9,  
     COL_10)
SELECT *;

-- 指标: G01_I_2.2.21.3.A.2016
-- G01_I_2.2.21.3.A.2016
  INSERT INTO `G01_I_2.2.21.3.A.2016`
    (DATA_DATE, -- 数据日期
     ORG_NUM, -- 机构号
     DATA_DEPARTMENT, -- 数据条线
     SYS_NAM, -- 模块简称
     REP_NUM, -- 报表编号
     ITEM_NUM, -- 指标号
     TOTAL_VALUE, -- 汇总值
     COL_1, -- 字段1(合同号)
     COL_2, -- 字段2(借据号)
     COL_3, -- 字段3(客户号)
     COL_4, -- 字段4(放款金额)
     COL_5, -- 字段5(放款日期)
     COL_6, -- 字段6(原始到期日期)
     COL_7, -- 字段7(科目号)
     COL_8, -- 字段8(币种)
     COL_9, -- 字段9(账户类型)
     COL_10 -- 字段10(委托贷款特殊投向)
     )
    SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     V_REP_NUM AS REP_NUM, -- 报表编号
     'G01_I_2.2.21.3.A.2016' AS ITEM_NUM, -- 指标号
     A.LOAN_ACCT_BAL * NVL(U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
     A.ACCT_NUM AS COL_1, -- 合同号
     A.LOAN_NUM AS COL_2, -- 借据号
     A.CUST_ID AS COL_3, -- 客户号
     A.DRAWDOWN_AMT AS COL_4, -- 放款金额
     A.DRAWDOWN_DT AS COL_5, -- 放款日期
     A.MATURITY_DT AS COL_6, -- 原始到期日期
     A.ITEM_CD AS COL_7, -- 科目号
     A.CURR_CD AS COL_8, -- 币种
     A.ACCT_TYP AS COL_9, -- 账户类型
     A.ENTRUST_PURPOSE_CD AS COL_10 -- 委托贷款特殊投向
      FROM SMTMODS_L_ACCT_LOAN A
     INNER JOIN SMTMODS_L_CUST_ALL B
        ON A.CUST_ID = B.CUST_ID
       AND B.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON A.DATA_DATE = U.DATA_DATE
       AND U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
     WHERE A.DATA_DATE = I_DATADATE
       AND B.INLANDORRSHORE_FLG = 'Y'
       AND A.ACCT_TYP LIKE '90%'
       AND A.CANCEL_FLG = 'N'
       AND LENGTHB(A.ACCT_NUM) < 36
       AND A.ENTRUST_PURPOSE_CD = 'A03'
       AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       AND A.LOAN_ACCT_BAL <> 0;

V_STEP_DESC := 'G01_I_2.2.21.3.A.2016';

--SHIWENBO BY 20170426-GJJ 添加406020204科目公积金委托贷款（长春模式）

    INSERT INTO `G01_I_2.2.21.3.A.2016`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE,
       T1.ORG_NUM,
       'CBRC',
       V_REP_NUM,
       'G01_I_2.2.21.3.A.2016' AS ITEM_NUM,
       SUM(T1.DEBIT_BAL * T2.CCY_RATE),
       '2'
      --FROM SMTMODS_L_FINA_GL T1
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1 -- 20221104 UPDATE BY WANGKUI
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.DATA_DATE = T2.DATA_DATE
         AND T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD = ('30200201') -- 被删除科目号 -- 老科目 406020204 -- 20221027 BUG_042538 update by wangkui
       GROUP BY T1.ORG_NUM;


-- 指标: G01_I_2.2.21.4.A.2016
-- G01_I_2.2.21.4.A.2016
  INSERT INTO `G01_I_2.2.21.4.A.2016`
    (DATA_DATE, -- 数据日期
     ORG_NUM, -- 机构号
     DATA_DEPARTMENT, -- 数据条线
     SYS_NAM, -- 模块简称
     REP_NUM, -- 报表编号
     ITEM_NUM, -- 指标号
     TOTAL_VALUE, -- 汇总值
     COL_1, -- 字段1(合同号)
     COL_2, -- 字段2(借据号)
     COL_3, -- 字段3(客户号)
     COL_4, -- 字段4(放款金额)
     COL_5, -- 字段5(放款日期)
     COL_6, -- 字段6(原始到期日期)
     COL_7, -- 字段7(科目号)
     COL_8, -- 字段8(币种)
     COL_9, -- 字段9(账户类型)
     COL_10 -- 字段10(委托贷款特殊投向)
     )
    SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     V_REP_NUM AS REP_NUM, -- 报表编号
     'G01_I_2.2.21.4.A.2016' AS ITEM_NUM, -- 指标号
     A.LOAN_ACCT_BAL * NVL(U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
     A.ACCT_NUM AS COL_1, -- 合同号
     A.LOAN_NUM AS COL_2, -- 借据号
     A.CUST_ID AS COL_3, -- 客户号
     A.DRAWDOWN_AMT AS COL_4, -- 放款金额
     A.DRAWDOWN_DT AS COL_5, -- 放款日期
     A.MATURITY_DT AS COL_6, -- 原始到期日期
     A.ITEM_CD AS COL_7, -- 科目号
     A.CURR_CD AS COL_8, -- 币种
     A.ACCT_TYP AS COL_9, -- 账户类型
     A.ENTRUST_PURPOSE_CD AS COL_10 -- 委托贷款特殊投向
      FROM SMTMODS_L_ACCT_LOAN A
     INNER JOIN SMTMODS_L_CUST_ALL B
        ON A.CUST_ID = B.CUST_ID
       AND B.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON A.DATA_DATE = U.DATA_DATE
       AND U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
     WHERE A.DATA_DATE = I_DATADATE
       AND B.INLANDORRSHORE_FLG = 'Y'
       AND A.ACCT_TYP LIKE '90%'
       AND A.CANCEL_FLG = 'N'
       AND LENGTHB(A.ACCT_NUM) < 36
       AND A.ENTRUST_PURPOSE_CD = 'A99'
       AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       AND A.LOAN_ACCT_BAL <> 0;


