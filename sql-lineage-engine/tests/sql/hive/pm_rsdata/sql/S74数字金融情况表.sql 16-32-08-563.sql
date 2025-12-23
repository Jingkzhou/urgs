-- ============================================================
-- 文件名: S74数字金融情况表.sql
-- 生成时间: 2025-12-18 13:53:41
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             CASE
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '01' THEN
                'S74.1.1.D'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '02' THEN
                'S74.1.2.D'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '03' THEN
                'S74.1.3.D'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '04' THEN
                'S74.1.4.D'
             END AS ITEM_NUM,
             A.CUST_ID,
             C.CUST_NAM,
             A.LOAN_NUM,
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS COLLECT_VAL, --汇总值
             A.ACCT_NUM,
             A.DRAWDOWN_DT,
             A.MATURITY_DT,
             '',
             CASE
               WHEN C1.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C1.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C1.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C1.CORP_SCALE = 'T' THEN
                '微型'
             END CORP_SCALE, --企业规模
             '',
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END LOAN_GRADE_CD, --五级分类
             NVL(C1.CORP_BUSINSESS_TYPE, C2.INDUSTRY_TYPE) AS CORP_BUSINSESS_TYPE, --行业分类
             A.LOAN_PURPOSE_CD,
             ''
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
        LEFT JOIN SMTMODS_L_CUST_ALL C --客户表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C1 --对公客户表
          ON A.CUST_ID = C1.CUST_ID
         AND C1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C2 --个人客户表
          ON A.CUST_ID = C2.CUST_ID
         AND C2.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
            /*AND A.LOAN_PURPOSE_CD IN
            (SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')*/
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND
             SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04')) --SHIWENBO BY 20170316-12901 单独取直贴
             OR ((A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%') AND
             SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04'))) --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12 --中长期
) q_0
INSERT INTO `S74.1.4.D` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.2.D` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.3.D` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.1.D` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *;

-- ========== 逻辑组 1: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             T.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             CASE
               WHEN DIGITAL_ECONOMY_INDUSTRY = '01' THEN
                'S74.1.1.B'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '02' THEN
                'S74.1.2.B'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '03' THEN
                'S74.1.3.B'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '04' THEN
                'S74.1.4.B'
             END AS ITEM_NUM,
             T.CUST_ID,
             T.CUST_NAM,
             T.LOAN_NUM,
             NVL(T.LOAN_ACCT_AMT, 0) * B.CCY_RATE AS COLLECT_VAL, --汇总值
             T.ACCT_NUM,
             T.DRAWDOWN_DT,
             T.MATURITY_DT,
             '',
             T.CORP_SCALE,
             '',
             T.LOAN_GRADE_CD,
             T.CORP_BUSINSESS_TYPE,
             T.LOAN_PURPOSE_CD,
             ''
        FROM CBRC_S74_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE SUBSTR(T.DATA_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
            --  AND t.LOAN_PURPOSE_CD IN (SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')
         AND T.DIGITAL_ECONOMY_INDUSTRY IN ('01', '02', '03', '04') --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
) q_1
INSERT INTO `S74.1.2.B` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.4.B` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.3.B` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.1.B` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *;

-- ========== 逻辑组 2: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             CASE
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '01' THEN
                'S74.1.1.E'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '02' THEN
                'S74.1.2.E'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '03' THEN
                'S74.1.3.E'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '04' THEN
                'S74.1.4.E'
             END AS ITEM_NUM,
             A.CUST_ID,
             C.CUST_NAM,
             A.LOAN_NUM,
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS COLLECT_VAL, --汇总值
             A.ACCT_NUM,
             A.DRAWDOWN_DT,
             A.MATURITY_DT,
             '',
             CASE
               WHEN C1.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C1.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C1.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C1.CORP_SCALE = 'T' THEN
                '微型'
             END CORP_SCALE, --企业规模
             '',
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END LOAN_GRADE_CD, --五级分类
             NVL(C1.CORP_BUSINSESS_TYPE, C2.INDUSTRY_TYPE) AS CORP_BUSINSESS_TYPE, --行业分类
             A.LOAN_PURPOSE_CD,
             ''
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
        LEFT JOIN SMTMODS_L_CUST_ALL C --客户表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C1 --对公客户表
          ON A.CUST_ID = C1.CUST_ID
         AND C1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C2 --个人客户表
          ON A.CUST_ID = C2.CUST_ID
         AND C2.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
            /*AND A.LOAN_PURPOSE_CD IN
            (SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')*/
            --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND
             SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04')) --SHIWENBO BY 20170316-12901 单独取直贴
             OR ((A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%') AND
             SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04')))
         AND A.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
) q_2
INSERT INTO `S74.1.3.E` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.1.E` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.4.E` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.2.E` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *;

-- ========== 逻辑组 3: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             T.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             CASE
               WHEN DIGITAL_ECONOMY_INDUSTRY = '01' THEN
                'S74.1.1.F'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '02' THEN
                'S74.1.2.F'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '03' THEN
                'S74.1.3.F'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '04' THEN
                'S74.1.4.F'
             END AS ITEM_NUM,
             T.CUST_ID,
             T.CUST_NAM,
             T.LOAN_NUM,
             NVL(T.NHSY, 0) * B.CCY_RATE AS COLLECT_VAL, --汇总值
             T.ACCT_NUM,
             T.DRAWDOWN_DT,
             T.MATURITY_DT,
             '',
             T.CORP_SCALE,
             '',
             T.LOAN_GRADE_CD,
             T.CORP_BUSINSESS_TYPE,
             T.LOAN_PURPOSE_CD,
             ''
        FROM CBRC_S74_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE SUBSTR(T.DATA_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
            /*    AND t.LOAN_PURPOSE_CD IN
            (SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')*/
         AND T.DIGITAL_ECONOMY_INDUSTRY IN ('01', '02', '03', '04') --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
) q_3
INSERT INTO `S74.1.4.F` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.3.F` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.1.F` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.2.F` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *;

-- ========== 逻辑组 4: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             --T.DEPARTMENTD,
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             CASE
               WHEN DIGITAL_ECONOMY_INDUSTRY = '01' THEN
                'S74.1.1.A'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '02' THEN
                'S74.1.2.A'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '03' THEN
                'S74.1.3.A'
               WHEN DIGITAL_ECONOMY_INDUSTRY = '04' THEN
                'S74.1.4.A'
             END AS ITEM_NUM,
             T.CUST_ID AS COL_2, --字段2(客户号)
             1 AS TOTAL_VALUE --字段5(贷款余额/贷款金额/客户数/贷款收益)
        FROM CBRC_S74_LOAN_TEMP T
       WHERE SUBSTR(T.DATA_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
            --- AND t.LOAN_PURPOSE_CD IN(SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')
         AND DIGITAL_ECONOMY_INDUSTRY IN ('01', '02', '03', '04') --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
       GROUP BY T.ORG_NUM,
                --T.DEPARTMENTD,
                T.CUST_ID,
                CASE
                  WHEN DIGITAL_ECONOMY_INDUSTRY = '01' THEN
                   'S74.1.1.A'
                  WHEN DIGITAL_ECONOMY_INDUSTRY = '02' THEN
                   'S74.1.2.A'
                  WHEN DIGITAL_ECONOMY_INDUSTRY = '03' THEN
                   'S74.1.3.A'
                  WHEN DIGITAL_ECONOMY_INDUSTRY = '04' THEN
                   'S74.1.4.A'
                END
) q_4
INSERT INTO `S74.1.4.A` (DATA_DATE,
       ORG_NUM,
        
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_2,  
       TOTAL_VALUE)
SELECT *
INSERT INTO `S74.1.1.A` (DATA_DATE,
       ORG_NUM,
        
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_2,  
       TOTAL_VALUE)
SELECT *
INSERT INTO `S74.1.2.A` (DATA_DATE,
       ORG_NUM,
        
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_2,  
       TOTAL_VALUE)
SELECT *
INSERT INTO `S74.1.3.A` (DATA_DATE,
       ORG_NUM,
        
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_2,  
       TOTAL_VALUE)
SELECT *;

-- 指标: S74.6..A
INSERT INTO `S74.6..A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             'S74.6..A' AS ITEM_NUM,
             COUNT(*), --指标值
             '2' AS FLAG
        FROM (SELECT REFERENCE_NUM, ACCOUNT_CODE, TRANS_AMT, TX_DT, ORG_NUM
                FROM CBRC_S74_DIGITAL_TRANS_SERVICES) T
       GROUP BY T.ORG_NUM;


-- 指标: S74.3..A
INSERT INTO `S74.3..A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             'S74.3..A' AS ITEM_NUM,
             COUNT(*), --指标值
             '2' AS FLAG
        FROM CBRC_S74_CUST_INFO_JRFUSZHZX T
       WHERE T.CUST_TYPE = '2' -- 2 个人
         AND DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;


-- 指标: S74.4..A
--明细汇总

    --end 明细需求 zhangyq20250815

    ------------------------ S74第II部分：金融服务数字化转型---------------------------------------

    -- 3.个人客户数量   4.法人客户数量
    INSERT INTO `S74.4..A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             'S74.4..A' AS ITEM_NUM,
             COUNT(*), --指标值
             '2' AS FLAG
        FROM CBRC_S74_CUST_INFO_JRFUSZHZX T
       WHERE T.CUST_TYPE = '1' -- 1 对公
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;


-- ========== 逻辑组 8: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             CASE
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '01' THEN
                'S74.1.1.C'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '02' THEN
                'S74.1.2.C'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '03' THEN
                'S74.1.3.C'
               WHEN SUBSTR(NVL(D.DIGITAL_ECONOMY_INDUSTRY,
                               A.DIGITAL_ECONOMY_INDUSTRY),
                           1,
                           2) = '04' THEN
                'S74.1.4.C'
             END AS ITEM_NUM,
             A.CUST_ID,
             C.CUST_NAM,
             A.LOAN_NUM,
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS COLLECT_VAL, --汇总值
             A.ACCT_NUM,
             A.DRAWDOWN_DT,
             A.MATURITY_DT,
             '',
             CASE
               WHEN C1.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C1.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C1.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C1.CORP_SCALE = 'T' THEN
                '微型'
             END CORP_SCALE, --企业规模
             '',
             CASE
               WHEN A.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN A.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN A.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN A.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN A.LOAN_GRADE_CD = '5' THEN
                '损失'
             END LOAN_GRADE_CD, --五级分类
             NVL(C1.CORP_BUSINSESS_TYPE, C2.INDUSTRY_TYPE) AS CORP_BUSINSESS_TYPE, --行业分类
             A.LOAN_PURPOSE_CD,
             ''
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
        LEFT JOIN SMTMODS_L_CUST_ALL C --客户表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C1 --对公客户表
          ON A.CUST_ID = C1.CUST_ID
         AND C1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C2 --个人客户表
          ON A.CUST_ID = C2.CUST_ID
         AND C2.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
            /* AND A.LOAN_PURPOSE_CD IN
            (SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')*/
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND
             SUBSTR(D.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04')) --SHIWENBO BY 20170316-12901 单独取直贴
             OR ((A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%') AND
             SUBSTR(A.DIGITAL_ECONOMY_INDUSTRY, 1, 2) IN
             ('01', '02', '03', '04'))) --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
) q_8
INSERT INTO `S74.1.3.C` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.4.C` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.2.C` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *
INSERT INTO `S74.1.1.C` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_9,  
       COL_10,  
       COL_11,  
       COL_12,  
       COL_13,  
       COL_14,  
       COL_15)
SELECT *;

-- 指标: S74.3.1.A
-- 3.1其中：开通移动端银行业务的客户数量   4.1其中：开通移动端银行业务的客户数量

    INSERT INTO `S74.3.1.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             'S74.3.1.A' AS ITEM_NUM,
             COUNT(*), --指标值
             '2' AS FLAG
        FROM (SELECT T.CUST_ID, T.ORG_NUM
                FROM CBRC_S74_DIGITAL_TRANS_SERVICES T
                LEFT JOIN SMTMODS_L_CUST_C T1
                  ON T.CUST_ID = T1.CUST_ID
                 AND T1.DATA_DATE = I_DATADATE
                 AND T1.CUST_TYP <> '3'
               WHERE CHANNEL IN ('JLBW', 'JMBK', 'WXIN', 'NBKJ', 'EIBK')
                 AND T1.CUST_ID IS NULL
               GROUP BY T.CUST_ID, T.ORG_NUM) T
       GROUP BY T.ORG_NUM;


-- 指标: S74.1.A
INSERT INTO `S74.1.A`
      (DATA_DATE,
       ORG_NUM,
       --DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_2, --字段2(客户号)
       TOTAL_VALUE --字段5(贷款余额/贷款金额/客户数/贷款收益)
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             --T.DEPARTMENTD, --数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             'S74.1.A' AS ITEM_NUM, --指标号
             T.CUST_ID AS COL_2, --字段2(客户号)
             1 AS TOTAL_VALUE --字段5(贷款余额/贷款金额/客户数/贷款收益)
        FROM CBRC_S74_LOAN_TEMP T
       WHERE SUBSTR(T.DATA_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
            --- AND t.LOAN_PURPOSE_CD IN(SELECT CODE FROM PUB_KJDK WHERE FLAG = '5.1')
         AND DIGITAL_ECONOMY_INDUSTRY IN ('01', '02', '03', '04') --[JLBA202507020013][20250729][石雨][于佳禾][按照NGI数据贷款类型取数]
       GROUP BY T.ORG_NUM, /*T.DEPARTMENTD, */T.CUST_ID;


-- 指标: S74.6.1.A
INSERT INTO `S74.6.1.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             'S74.6.1.A' AS ITEM_NUM,
             COUNT(*), --指标值
             '2' AS FLAG
        FROM (SELECT REFERENCE_NUM,
                     ACCOUNT_CODE,
                     TRANS_AMT,
                     TX_DT,
                     ORG_NUM,
                     CHANNEL
                FROM CBRC_S74_DIGITAL_TRANS_SERVICES
               WHERE CHANNEL IN ('EFSM',
                                 'JLBW',
                                 'JMBK',
                                 'WXIN',
                                 'NBKJ',
                                 'EIBK',
                                 'STIJ',
                                 'SMKS',
                                 '1',
                                 '2',
                                 '3',
                                 '4',
                                 'B',
                                 'D',
                                 'E')) T
       GROUP BY T.ORG_NUM;


-- 指标: S74.4.1.A
INSERT INTO `S74.4.1.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S74' AS REP_NUM, --报表编号
             'S74.4.1.A' AS ITEM_NUM,
             COUNT(*), --指标值
             '2' AS FLAG
        FROM (SELECT T.CUST_ID, T.ORG_NUM
                FROM CBRC_S74_DIGITAL_TRANS_SERVICES T
               INNER JOIN SMTMODS_L_CUST_C T1
                  ON T.CUST_ID = T1.CUST_ID
                 AND T1.DATA_DATE = I_DATADATE
                 AND T1.CUST_TYP <> '3'
               WHERE CHANNEL IN ('JLBW', 'JMBK', 'WXIN', 'NBKJ', 'EIBK')
               GROUP BY T.CUST_ID, T.ORG_NUM) T
       GROUP BY T.ORG_NUM;


