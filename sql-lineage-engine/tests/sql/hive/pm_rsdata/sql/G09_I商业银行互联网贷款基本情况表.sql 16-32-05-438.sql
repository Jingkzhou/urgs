-- ============================================================
-- 文件名: G09_I商业银行互联网贷款基本情况表.sql
-- 生成时间: 2025-12-18 13:53:37
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 5 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          (CASE
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND --101  第一代身份证 102  第二代身份证
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 25) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 25) THEN
             'G09_I_1.5.1.A'
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 35) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 35) THEN
             'G09_I_1.5.2.A'
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 45) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 45) THEN
             'G09_I_1.5.3.A'
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 55) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 55) THEN
             'G09_I_1.5.4.A'
            ELSE
             'G09_I_1.5.5.A'
          END)
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          (CASE
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND --101  第一代身份证 102  第二代身份证
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 25) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 25) THEN
             'G09_I_1.5.1.B'
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 35) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 35) THEN
             'G09_I_1.5.2.B'
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 45) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 45) THEN
             'G09_I_1.5.3.B'
            WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                 SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 55) OR
                 (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                 SUBSTR(I_DATADATE, 1, 4) -
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 55) THEN
             'G09_I_1.5.4.B'
            ELSE
             'G09_I_1.5.5.B'
          END)
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN T --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN A --贷款借据信息表
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%') --个人经营性贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   (CASE
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND --101  第一代身份证 102  第二代身份证
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 25) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 25) THEN
                      'G09_I_1.5.1.A'
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 35) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 35) THEN
                      'G09_I_1.5.2.A'
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 45) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 45) THEN
                      'G09_I_1.5.3.A'
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 55) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 55) THEN
                      'G09_I_1.5.4.A'
                     ELSE
                      'G09_I_1.5.5.A'
                   END)
                  WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   (CASE
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND --101  第一代身份证 102  第二代身份证
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 25) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 25) THEN
                      'G09_I_1.5.1.B'
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 35) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 35) THEN
                      'G09_I_1.5.2.B'
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 45) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 45) THEN
                      'G09_I_1.5.3.B'
                     WHEN (SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                          SUBSTR(I_DATADATE, 1, 4) - SUBSTR(C.ID_NO, 7, 4) <= 55) OR
                          (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                          SUBSTR(I_DATADATE, 1, 4) -
                          SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) <= 55) THEN
                      'G09_I_1.5.4.B'
                     ELSE
                      'G09_I_1.5.5.B'
                   END)
                END
) q_0
INSERT INTO `G09_I_1.5.5.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.5.3.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.5.4.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.5.1.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.5.2.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- ========== 逻辑组 1: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          (CASE
         WHEN C.COOP_CUST_TYPE = 'A' THEN
          'G09_I_8.1.3.1.A' --商业银行
         WHEN C.COOP_CUST_TYPE = 'B' THEN
          'G09_I_8.1.3.2.A' --信托
         WHEN C.COOP_CUST_TYPE = 'C' THEN
          'G09_I_8.1.3.3.A' --消费金融公司
         WHEN C.COOP_CUST_TYPE = 'D' THEN
          'G09_I_8.1.3.4.A' --小额贷款公司
          END)
         WHEN B.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          (CASE
         WHEN C.COOP_CUST_TYPE = 'A' THEN
          'G09_I_8.1.3.1.B' --商业银行
         WHEN C.COOP_CUST_TYPE = 'B' THEN
          'G09_I_8.1.3.2.B' --信托
         WHEN C.COOP_CUST_TYPE = 'C' THEN
          'G09_I_8.1.3.3.B' --消费金融公司
         WHEN C.COOP_CUST_TYPE = 'D' THEN
          'G09_I_8.1.3.4.B' --小额贷款公司
          END)
         WHEN B.ACCT_TYP = '0202' THEN --流动资金贷款
          (CASE
         WHEN C.COOP_CUST_TYPE = 'A' THEN
          'G09_I_8.1.3.1.C' --商业银行
         WHEN C.COOP_CUST_TYPE = 'B' THEN
          'G09_I_8.1.3.2.C' --信托
         WHEN C.COOP_CUST_TYPE = 'C' THEN
          'G09_I_8.1.3.3.C' --消费金融公司
         WHEN C.COOP_CUST_TYPE = 'D' THEN
          'G09_I_8.1.3.4.C' --小额贷款公司
          END)
       END AS ITEM_NUM,
       SUM(b.loan_acct_bal * U.CCY_RATE)/0.7*0.3 AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_COOP_AGEN C --合作机构信息表
          ON A.COOP_CUST_ID = C.COOP_CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ORG_ROLE = 'A' --主要作为资金提供方
         AND A.INTERNET_LOAN_TYP IN ('B', 'C') --B线上联合贷款 C同属商业银行互联网贷款和线上联合贷款
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   (CASE
                  WHEN C.COOP_CUST_TYPE = 'A' THEN
                   'G09_I_8.1.3.1.A' --商业银行
                  WHEN C.COOP_CUST_TYPE = 'B' THEN
                   'G09_I_8.1.3.2.A' --信托
                  WHEN C.COOP_CUST_TYPE = 'C' THEN
                   'G09_I_8.1.3.3.A' --消费金融公司
                  WHEN C.COOP_CUST_TYPE = 'D' THEN
                   'G09_I_8.1.3.4.A' --小额贷款公司
                   END)
                  WHEN B.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   (CASE
                  WHEN C.COOP_CUST_TYPE = 'A' THEN
                   'G09_I_8.1.3.1.B' --商业银行
                  WHEN C.COOP_CUST_TYPE = 'B' THEN
                   'G09_I_8.1.3.2.B' --信托
                  WHEN C.COOP_CUST_TYPE = 'C' THEN
                   'G09_I_8.1.3.3.B' --消费金融公司
                  WHEN C.COOP_CUST_TYPE = 'D' THEN
                   'G09_I_8.1.3.4.B' --小额贷款公司
                   END)
                  WHEN B.ACCT_TYP = '0202' THEN --流动资金贷款
                   (CASE
                  WHEN C.COOP_CUST_TYPE = 'A' THEN
                   'G09_I_8.1.3.1.C' --商业银行
                  WHEN C.COOP_CUST_TYPE = 'B' THEN
                   'G09_I_8.1.3.2.C' --信托
                  WHEN C.COOP_CUST_TYPE = 'C' THEN
                   'G09_I_8.1.3.3.C' --消费金融公司
                  WHEN C.COOP_CUST_TYPE = 'D' THEN
                   'G09_I_8.1.3.4.C' --小额贷款公司
                   END)
                END
) q_1
INSERT INTO `G09_I_8.1.3.1.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_8.1.3.3.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- ========== 逻辑组 2: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          (CASE
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 6 THEN
             'G09_I_1.4.1.A'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 6 AND
                 MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 12 THEN
             'G09_I_1.4.2.A'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 12 AND
                 MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 36 THEN
             'G09_I_1.4.3.A'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 36 THEN
             'G09_I_1.4.4.A'
          END)
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          (CASE
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 6 THEN
             'G09_I_1.4.1.B'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 6 AND
                 MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 12 THEN
             'G09_I_1.4.2.B'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 12 AND
                 MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 36 THEN
             'G09_I_1.4.3.B'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 36 THEN
             'G09_I_1.4.4.B'
          END)
         WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
          (CASE
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 6 THEN
             'G09_I_1.4.1.C'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 6 AND
                 MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 12 THEN
             'G09_I_1.4.2.C'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 12 AND
                 MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 36 THEN
             'G09_I_1.4.3.C'
            WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 36 THEN
             'G09_I_1.4.4.C'
          END)
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN T --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN A --贷款借据信息表
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   (CASE
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 6 THEN
                      'G09_I_1.4.1.A'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 6 AND
                          MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 12 THEN
                      'G09_I_1.4.2.A'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 12 AND
                          MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 36 THEN
                      'G09_I_1.4.3.A'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 36 THEN
                      'G09_I_1.4.4.A'
                   END)
                  WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   (CASE
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 6 THEN
                      'G09_I_1.4.1.B'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 6 AND
                          MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 12 THEN
                      'G09_I_1.4.2.B'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 12 AND
                          MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 36 THEN
                      'G09_I_1.4.3.B'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 36 THEN
                      'G09_I_1.4.4.B'
                   END)
                  WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
                   (CASE
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 6 THEN
                      'G09_I_1.4.1.C'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 6 AND
                          MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 12 THEN
                      'G09_I_1.4.2.C'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 12 AND
                          MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) <= 36 THEN
                      'G09_I_1.4.3.C'
                     WHEN MONTHS_BETWEEN(DATE(MATURITY_DT), DATE(DRAWDOWN_DT)) > 36 THEN
                      'G09_I_1.4.4.C'
                   END)
                END
) q_2
INSERT INTO `G09_I_1.4.1.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.4.3.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.4.2.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- 指标: G09_I_8.1.4.1.A
----------------------------------------------合作机构管理情况(本机构主要作为资金提供方共同出资):  8.1.4.1 本行当年累计通过授信客户户数--------------------------------------------------------------------------
    INSERT
    INTO `G09_I_8.1.4.1.A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.REC_ACCT_TYPE = 'A' THEN
          'G09_I_8.1.4.1.A' --个人消费
         WHEN A.REC_ACCT_TYPE = 'B' THEN
          'G09_I_8.1.4.1.B' --个人生产经营
         WHEN A.REC_ACCT_TYPE = 'C' THEN
          'G09_I_8.1.4.1.C' --流动资金
       END AS ITEM_NUM,
       COUNT(DISTINCT CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_REC_CUST_INTERNET_LOAN A --互联网贷款客户推荐信息表
       WHERE A.ORG_ROLE = 'A' --本机构主要作为资金提供方
         AND A.CREDIT_FLG = 'Y' --通过授信
         AND SUBSTR(A.REC_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4) --推荐日期在本年度
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REC_ACCT_TYPE = 'A' THEN
                   'G09_I_8.1.4.1.A' --个人消费
                  WHEN A.REC_ACCT_TYPE = 'B' THEN
                   'G09_I_8.1.4.1.B' --个人生产经营
                  WHEN A.REC_ACCT_TYPE = 'C' THEN
                   'G09_I_8.1.4.1.C' --流动资金
                END;


-- ========== 逻辑组 4: 共 6 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          (CASE
            WHEN A.OD_FLG = 'N' THEN
             'G09_I_1.2.1.A'
            WHEN A.OD_DAYS BETWEEN 1 AND 30 THEN
             'G09_I_1.2.2.A'
            WHEN A.OD_DAYS BETWEEN 31 AND 60 THEN
             'G09_I_1.2.3.A'
            WHEN A.OD_DAYS BETWEEN 61 AND 90 THEN
             'G09_I_1.2.4.A'
            WHEN A.OD_DAYS BETWEEN 91 AND 360 THEN
             'G09_I_1.2.5.A'
            WHEN A.OD_DAYS > 360 THEN
             'G09_I_1.2.6.A'
          END)
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          (CASE
            WHEN A.OD_FLG = 'N' THEN
             'G09_I_1.2.1.B'
            WHEN A.OD_DAYS BETWEEN 1 AND 30 THEN
             'G09_I_1.2.2.B'
            WHEN A.OD_DAYS BETWEEN 31 AND 60 THEN
             'G09_I_1.2.3.B'
            WHEN A.OD_DAYS BETWEEN 61 AND 90 THEN
             'G09_I_1.2.4.B'
            WHEN A.OD_DAYS BETWEEN 91 AND 360 THEN
             'G09_I_1.2.5.B'
            WHEN A.OD_DAYS > 360 THEN
             'G09_I_1.2.6.B'
          END)
         WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
          (CASE
            WHEN A.OD_FLG = 'N' THEN
             'G09_I_1.2.1.C'
            WHEN A.OD_DAYS BETWEEN 1 AND 30 THEN
             'G09_I_1.2.2.C'
            WHEN A.OD_DAYS BETWEEN 31 AND 60 THEN
             'G09_I_1.2.3.C'
            WHEN A.OD_DAYS BETWEEN 61 AND 90 THEN
             'G09_I_1.2.4.C'
            WHEN A.OD_DAYS BETWEEN 91 AND 360 THEN
             'G09_I_1.2.5.C'
            WHEN A.OD_DAYS > 360 THEN
             'G09_I_1.2.6.C'
          END)
       END AS ITEM_NUM,
       /*alter by shiyu 20241105 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
            如果是按月分期还款的个人消费贷款本金或利息逾期 */
       SUM(CASE WHEN A.ACCT_TYP LIKE '0103%' AND A.OD_DAYS <=90 AND a.REPAY_TYP ='1' and  a.PAY_TYPE in   ('01','02','10','11')--JLBA202412040012
       THEN  A.OD_LOAN_ACCT_BAL * U.CCY_RATE
        ELSE A.LOAN_ACCT_BAL * U.CCY_RATE END)AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN T --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN A --贷款借据信息表
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   (CASE
                     WHEN A.OD_FLG = 'N' THEN
                      'G09_I_1.2.1.A'
                     WHEN A.OD_DAYS BETWEEN 1 AND 30 THEN
                      'G09_I_1.2.2.A'
                     WHEN A.OD_DAYS BETWEEN 31 AND 60 THEN
                      'G09_I_1.2.3.A'
                     WHEN A.OD_DAYS BETWEEN 61 AND 90 THEN
                      'G09_I_1.2.4.A'
                     WHEN A.OD_DAYS BETWEEN 91 AND 360 THEN
                      'G09_I_1.2.5.A'
                     WHEN A.OD_DAYS > 360 THEN
                      'G09_I_1.2.6.A'
                   END)
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   (CASE
                     WHEN A.OD_FLG = 'N' THEN
                      'G09_I_1.2.1.B'
                     WHEN A.OD_DAYS BETWEEN 1 AND 30 THEN
                      'G09_I_1.2.2.B'
                     WHEN A.OD_DAYS BETWEEN 31 AND 60 THEN
                      'G09_I_1.2.3.B'
                     WHEN A.OD_DAYS BETWEEN 61 AND 90 THEN
                      'G09_I_1.2.4.B'
                     WHEN A.OD_DAYS BETWEEN 91 AND 360 THEN
                      'G09_I_1.2.5.B'
                     WHEN A.OD_DAYS > 360 THEN
                      'G09_I_1.2.6.B'
                   END)
                  WHEN A.ACCT_TYP = '0202' THEN
                   (CASE
                     WHEN A.OD_FLG = 'N' THEN
                      'G09_I_1.2.1.C'
                     WHEN A.OD_DAYS BETWEEN 1 AND 30 THEN
                      'G09_I_1.2.2.C'
                     WHEN A.OD_DAYS BETWEEN 31 AND 60 THEN
                      'G09_I_1.2.3.C'
                     WHEN A.OD_DAYS BETWEEN 61 AND 90 THEN
                      'G09_I_1.2.4.C'
                     WHEN A.OD_DAYS BETWEEN 91 AND 360 THEN
                      'G09_I_1.2.5.C'
                     WHEN A.OD_DAYS > 360 THEN
                      'G09_I_1.2.6.C'
                   END)
                END
) q_4
INSERT INTO `G09_I_1.2.3.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.2.6.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.2.5.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.2.2.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.2.4.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.2.1.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- ========== 逻辑组 5: 共 5 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          (CASE
            WHEN A.LOAN_GRADE_CD = '1' THEN
             'G09_I_1.1.1.A'
            WHEN A.LOAN_GRADE_CD = '2' THEN
             'G09_I_1.1.2.A'
            WHEN A.LOAN_GRADE_CD = '3' THEN
             'G09_I_1.1.3.A'
            WHEN A.LOAN_GRADE_CD = '4' THEN
             'G09_I_1.1.4.A'
            WHEN A.LOAN_GRADE_CD = '5' THEN
             'G09_I_1.1.5.A'
          END)
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          (CASE
            WHEN A.LOAN_GRADE_CD = '1' THEN
             'G09_I_1.1.1.B'
            WHEN A.LOAN_GRADE_CD = '2' THEN
             'G09_I_1.1.2.B'
            WHEN A.LOAN_GRADE_CD = '3' THEN
             'G09_I_1.1.3.B'
            WHEN A.LOAN_GRADE_CD = '4' THEN
             'G09_I_1.1.4.B'
            WHEN A.LOAN_GRADE_CD = '5' THEN
             'G09_I_1.1.5.B'
          END)
         WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
          (CASE
            WHEN A.LOAN_GRADE_CD = '1' THEN
             'G09_I_1.1.1.C'
            WHEN A.LOAN_GRADE_CD = '2' THEN
             'G09_I_1.1.2.C'
            WHEN A.LOAN_GRADE_CD = '3' THEN
             'G09_I_1.1.3.C'
            WHEN A.LOAN_GRADE_CD = '4' THEN
             'G09_I_1.1.4.C'
            WHEN A.LOAN_GRADE_CD = '5' THEN
             'G09_I_1.1.5.C'
          END)
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN T --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN A --贷款借据信息表
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --五级分类
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   (CASE
                     WHEN A.LOAN_GRADE_CD = '1' THEN
                      'G09_I_1.1.1.A'
                     WHEN A.LOAN_GRADE_CD = '2' THEN
                      'G09_I_1.1.2.A'
                     WHEN A.LOAN_GRADE_CD = '3' THEN
                      'G09_I_1.1.3.A'
                     WHEN A.LOAN_GRADE_CD = '4' THEN
                      'G09_I_1.1.4.A'
                     WHEN A.LOAN_GRADE_CD = '5' THEN
                      'G09_I_1.1.5.A'
                   END)
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   (CASE
                     WHEN A.LOAN_GRADE_CD = '1' THEN
                      'G09_I_1.1.1.B'
                     WHEN A.LOAN_GRADE_CD = '2' THEN
                      'G09_I_1.1.2.B'
                     WHEN A.LOAN_GRADE_CD = '3' THEN
                      'G09_I_1.1.3.B'
                     WHEN A.LOAN_GRADE_CD = '4' THEN
                      'G09_I_1.1.4.B'
                     WHEN A.LOAN_GRADE_CD = '5' THEN
                      'G09_I_1.1.5.B'
                   END)
                  WHEN A.ACCT_TYP = '0202' THEN
                   (CASE
                     WHEN A.LOAN_GRADE_CD = '1' THEN
                      'G09_I_1.1.1.C'
                     WHEN A.LOAN_GRADE_CD = '2' THEN
                      'G09_I_1.1.2.C'
                     WHEN A.LOAN_GRADE_CD = '3' THEN
                      'G09_I_1.1.3.C'
                     WHEN A.LOAN_GRADE_CD = '4' THEN
                      'G09_I_1.1.4.C'
                     WHEN A.LOAN_GRADE_CD = '5' THEN
                      'G09_I_1.1.5.C'
                   END)
                END
) q_5
INSERT INTO `G09_I_1.1.3.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.1.2.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.1.1.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.1.5.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G09_I_1.1.4.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- 指标: G09_I_8.1.2.A
----------------------------------------------合作机构管理情况(本机构主要作为资金提供方共同出资): 8.1.2本机构出资发放贷款余额--------------------------------------------------------------------------
    INSERT
    INTO `G09_I_8.1.2.A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.1.2.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.1.2.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.1.2.C'
       END AS ITEM_NUM,
       SUM((A.TOTAL_LOAN_BAL - A.COOP_LOAN_BAL) * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ORG_ROLE = 'A' --主要作为资金提供方   --吴大为提出 本机构发放贷余额全部归为本机构出资发放贷款   --zjk
         AND A.INTERNET_LOAN_TYP IN ('B', 'C') --B线上联合贷款 C同属商业银行互联网贷款和线上联合贷款
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.1.2.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.1.2.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.1.2.C'
                END;


-- 指标: G09_I_3..A
---当年累计发放贷款户数-------------------

    INSERT
    INTO `G09_I_3..A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN
          'G09_I_3..A'
         WHEN A.ACCT_TYP LIKE '0102%' THEN
          'G09_I_3..B'
         WHEN A.ACCT_TYP = '0202' THEN
          'G09_I_3..C'
       END AS ITEM_NUM,
       COUNT(DISTINCT A.CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN SMTMODS_L_CUST_ALL T
          ON T.CUST_ID = A.CUST_ID
         AND T.DATA_DATE = I_DATADATE
       WHERE A.CANCEL_FLG <> 'Y' --未核销
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND SUBSTR(A.DRAWDOWN_DT, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND A.DATA_DATE = I_DATADATE
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_3..A'
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_3..B'
                  WHEN A.ACCT_TYP = '0202' THEN
                   'G09_I_3..C'
                END;


-- 指标: G09_I_5..A
INSERT
    INTO `G09_I_5..A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN
          'G09_I_5..A'
         WHEN A.ACCT_TYP LIKE '0102%' THEN
          'G09_I_5..B'
         WHEN A.ACCT_TYP = '0202' THEN
          'G09_I_5..C'
       END AS ITEM_NUM,
       SUM(A.DRAWDOWN_AMT * A.REAL_INT_RAT / 100) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON B.BASIC_CCY = A.CURR_CD --基准币种
         AND B.FORWARD_CCY = 'CNY' --折算币种
         AND B.CCY_DATE = I_DATADATE
       WHERE A.CANCEL_FLG <> 'Y' --未核销
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组
         AND SUBSTR(A.DRAWDOWN_DT, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
         AND A.DATA_DATE = I_DATADATE
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_5..A'
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_5..B'
                  WHEN A.ACCT_TYP = '0202' THEN
                   'G09_I_5..C'
                END;


-- 指标: G09_I_6.1.A
INSERT
    INTO `G09_I_6.1.A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          'G09_I_6.1.A'
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          'G09_I_6.1.B'
         WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
          'G09_I_6.1.C'
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN T --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN A --贷款借据信息表
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   'G09_I_6.1.A'
                  WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   'G09_I_6.1.B'
                  WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
                   'G09_I_6.1.C'
                END;


-- 指标: G09_I_2..A
---有贷款余额户数-------------------

    INSERT
    INTO `G09_I_2..A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN
          'G09_I_2..A'
         WHEN A.ACCT_TYP LIKE '0102%' THEN
          'G09_I_2..B'
         WHEN A.ACCT_TYP = '0202' THEN
          'G09_I_2..C'
       END AS ITEM_NUM,
       COUNT(DISTINCT A.CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN SMTMODS_L_CUST_ALL T
          ON T.CUST_ID = A.CUST_ID
         AND T.DATA_DATE = I_DATADATE
       WHERE A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.LOAN_ACCT_BAL <> 0
         AND A.DATA_DATE = I_DATADATE
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_2..A'
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_2..B'
                  WHEN A.ACCT_TYP = '0202' THEN
                   'G09_I_2..C'
                END;


-- 指标: G09_I_8.1.1.A
INSERT
    INTO `G09_I_8.1.1.A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.1.1.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.1.1.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.1.1.C'
       END AS ITEM_NUM,
       COUNT(DISTINCT A.COOP_CUST_ID) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
       WHERE A.ORG_ROLE = 'A' --主要作为资金提供方
         AND A.INTERNET_LOAN_TYP IN ('B', 'C') --B线上联合贷款 C同属商业银行互联网贷款和线上联合贷款
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.1.1.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.1.1.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.1.1.C'
                END;


-- 指标: G09_I_4..A
INSERT
    INTO `G09_I_4..A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN
          'G09_I_4..A'
         WHEN A.ACCT_TYP LIKE '0102%' THEN
          'G09_I_4..B'
         WHEN A.ACCT_TYP = '0202' THEN
          'G09_I_4..C'
       END AS ITEM_NUM,
       SUM(A.DRAWDOWN_AMT * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.CANCEL_FLG <> 'Y' --未核销
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组
         AND A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.DRAWDOWN_DT, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_4..A'
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_4..B'
                  WHEN A.ACCT_TYP = '0202' THEN
                   'G09_I_4..C'
                END;


-- 指标: G09_I_8.1.4.A
----------------------------------------------合作机构管理情况(本机构主要作为资金提供方共同出资):
    --  8.1.4合作方当年累计推荐客户户数--------------------------------------------------------------------------
    INSERT
    INTO `G09_I_8.1.4.A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      
    --alter by  shiyu 20240129 当年推荐户数：当年放款+当年推荐
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ITEM_NUM = 'A' THEN
          'G09_I_8.1.4.A' --个人消费
         WHEN A.ITEM_NUM = 'B' THEN
          'G09_I_8.1.4.B' --个人生产经营
         WHEN A.ITEM_NUM = 'C' THEN
          'G09_I_8.1.4.C' --流动资金
       END AS ITEM_NUM,
       COUNT(DISTINCT CUST_ID) AS ITEM_VAL
        FROM (
              SELECT 
               I_DATADATE AS DATA_DATE,
                A.ORG_NUM,
                CASE
                  WHEN a.ACCT_TYP LIKE '0103%' THEN
                   'A'
                  WHEN a.ACCT_TYP LIKE '0102%' THEN
                   'B'
                  WHEN a.ACCT_TYP = '0202' THEN
                   'C'
                END AS ITEM_NUM,
                A.CUST_ID
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_CUST_ALL T
                  ON T.CUST_ID = A.CUST_ID
                 AND T.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_ACCT_INTERNET_LOAN T1 --互联网贷款业务信息表
                  ON A.LOAN_NUM = T1.LOAN_NUM
                 AND A.DATA_DATE = T1.DATA_DATE
               WHERE A.CANCEL_FLG <> 'Y' --未核销
                 AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
                 AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
                     OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
                     OR A.ACCT_TYP = '0202') --流动资金贷款
                 AND TO_CHAR(A.DRAWDOWN_DT, 'YYYY') =
                     SUBSTR(I_DATADATE, 1, 4) --当年发放贷款
                 AND A.DATA_DATE = I_DATADATE
                 and T1.ORG_ROLE = 'A' --本机构主要作为资金提供方
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
               GROUP BY A.ORG_NUM,
                         CASE
                           WHEN a.ACCT_TYP LIKE '0103%' THEN
                            'A'
                           WHEN a.ACCT_TYP LIKE '0102%' THEN
                            'B'
                           WHEN a.ACCT_TYP = '0202' THEN
                            'C'
                         END,
                         a.cust_id
              union all
              SELECT 
               I_DATADATE      AS DATA_DATE,
                A.ORG_NUM,
                A.REC_ACCT_TYPE AS ITEM_NUM,
                a.cust_id

                FROM SMTMODS_L_REC_CUST_INTERNET_LOAN A --互联网贷款客户推荐信息表
               WHERE A.ORG_ROLE = 'A' --本机构主要作为资金提供方
                 AND SUBSTR(A.REC_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4) --推荐日期在本年度
                 AND A.DATA_DATE = I_DATADATE) a
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ITEM_NUM = 'A' THEN
                   'G09_I_8.1.4.A' --个人消费
                  WHEN A.ITEM_NUM = 'B' THEN
                   'G09_I_8.1.4.B' --个人生产经营
                  WHEN A.ITEM_NUM = 'C' THEN
                   'G09_I_8.1.4.C' --流动资金
                END;


-- 指标: G09_I_1.6.1.A
---其他情况：1.6.1采用自主支付方式发放的贷款余额-------------------
    INSERT
    INTO `G09_I_1.6.1.A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN
          'G09_I_1.6.1.A' --个人消费贷款
         WHEN A.ACCT_TYP LIKE '0102%' THEN
          'G09_I_1.6.1.B' --个人经营性贷款
         WHEN A.ACCT_TYP = '0202' THEN
          'G09_I_1.6.1.C' --流动资金贷款
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.DRAWDOWN_TYPE = 'A' --放款方式：自主支付
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_1.6.1.A' --个人消费贷款
                  WHEN A.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_1.6.1.B' --个人经营性贷款
                  WHEN A.ACCT_TYP = '0202' THEN
                   'G09_I_1.6.1.C' --流动资金贷款
                END;


-- 指标: G09_I_8.1.3.A
----------------------------------------------合作机构管理情况(本机构主要作为资金提供方共同出资): 8.1.3合作方出资发放贷款余额--------------------------------------------------------------------------
    INSERT
    INTO `G09_I_8.1.3.A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.1.3.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.1.3.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.1.3.C'
       END AS ITEM_NUM,
       SUM(b.loan_acct_bal * U.CCY_RATE)/0.7*0.3 AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ORG_ROLE = 'A' --主要作为资金提供方
         AND A.INTERNET_LOAN_TYP IN ('B', 'C') --B线上联合贷款 C同属商业银行互联网贷款和线上联合贷款
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.1.3.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.1.3.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.1.3.C'
                END;

----------------------------------------------合作机构管理情况(本机构主要作为信息提供方共同出资): 8.2.3合作方出资发放贷款余额--------------------------------------------------------------------------
    INSERT
    INTO `G09_I_8.1.3.A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.ACCT_TYP LIKE '0103%' THEN
          'G09_I_8.1.3.A'
         WHEN B.ACCT_TYP LIKE '0102%' THEN
          'G09_I_8.1.3.B'
         WHEN B.ACCT_TYP = '0202' THEN
          'G09_I_8.1.3.C'
       END AS ITEM_NUM,
       SUM(A.COOP_LOAN_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN A --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN B
          ON A.LOAN_NUM = B.LOAN_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.ORG_ROLE = 'B' --主要作为信息提供方
         AND A.INTERNET_LOAN_TYP IN ('B', 'C')
         AND A.DATA_DATE = I_DATADATE
         AND B.CANCEL_FLG <> 'Y' --未核销
         AND B.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND B.ACCT_STS <> '3' --账户状态未结清
         AND (B.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR B.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR B.ACCT_TYP = '0202') --流动资金贷款
     AND B.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.ACCT_TYP LIKE '0103%' THEN
                   'G09_I_8.1.3.A'
                  WHEN B.ACCT_TYP LIKE '0102%' THEN
                   'G09_I_8.1.3.B'
                  WHEN B.ACCT_TYP = '0202' THEN
                   'G09_I_8.1.3.C'
                END;


-- 指标: G09_I_1.3.1.A
----------------互联网贷款余额:按担保方式--------------------------
    INSERT
    INTO `G09_I_1.3.1.A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
          (CASE
            WHEN A.GUARANTY_TYP = 'D' THEN
             'G09_I_1.3.1.A' --信用贷款
            WHEN A.GUARANTY_TYP LIKE 'C%' THEN
             'G09_I_1.3.2.A' --保证贷款
            WHEN SUBSTR(A.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
             'G09_I_1.3.3.A' --抵押贷款
          END)
         WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
          (CASE
            WHEN A.GUARANTY_TYP = 'D' THEN
             'G09_I_1.3.1.B' --信用贷款
            WHEN A.GUARANTY_TYP LIKE 'C%' THEN
             'G09_I_1.3.2.B' --保证贷款
            WHEN SUBSTR(A.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
             'G09_I_1.3.3.B' --抵押贷款
          END)
         WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
          (CASE
            WHEN A.GUARANTY_TYP = 'D' THEN
             'G09_I_1.3.1.C' --信用贷款
            WHEN A.GUARANTY_TYP LIKE 'C%' THEN
             'G09_I_1.3.2.C' --保证贷款
            WHEN SUBSTR(A.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
             'G09_I_1.3.3.C' --抵押贷款
          END)
       END AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_INTERNET_LOAN T --互联网贷款业务信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN A --贷款借据信息表
          ON T.LOAN_NUM = A.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.CCY_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND A.INTERNET_LOAN_FLG = 'Y' --互联网贷款
         AND (A.ACCT_TYP LIKE '0103%' --个人消费贷款
             OR A.ACCT_TYP LIKE '0102%' --个人经营性贷款
             OR A.ACCT_TYP = '0202') --流动资金贷款
         AND A.ACCT_STS <> '3' --账户状态未结清
         AND A.CANCEL_FLG <> 'Y' --未核销
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.ACCT_TYP LIKE '0103%' THEN --个人消费贷款
                   (CASE
                     WHEN A.GUARANTY_TYP = 'D' THEN
                      'G09_I_1.3.1.A' --信用贷款
                     WHEN A.GUARANTY_TYP LIKE 'C%' THEN
                      'G09_I_1.3.2.A' --保证贷款
                     WHEN SUBSTR(A.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                      'G09_I_1.3.3.A' --抵押贷款
                   END)
                  WHEN A.ACCT_TYP LIKE '0102%' THEN --个人经营性贷款
                   (CASE
                     WHEN A.GUARANTY_TYP = 'D' THEN
                      'G09_I_1.3.1.B' --信用贷款
                     WHEN A.GUARANTY_TYP LIKE 'C%' THEN
                      'G09_I_1.3.2.B' --保证贷款
                     WHEN SUBSTR(A.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                      'G09_I_1.3.3.B' --抵押贷款
                   END)
                  WHEN A.ACCT_TYP = '0202' THEN --流动资金贷款
                   (CASE
                     WHEN A.GUARANTY_TYP = 'D' THEN
                      'G09_I_1.3.1.C' --信用贷款
                     WHEN A.GUARANTY_TYP LIKE 'C%' THEN
                      'G09_I_1.3.2.C' --保证贷款
                     WHEN SUBSTR(A.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                      'G09_I_1.3.3.C' --抵押贷款
                   END)
                END;


