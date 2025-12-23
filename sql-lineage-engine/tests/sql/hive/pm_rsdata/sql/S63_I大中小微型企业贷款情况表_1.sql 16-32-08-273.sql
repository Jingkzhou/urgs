-- ============================================================
-- 文件名: S63_I大中小微型企业贷款情况表_1.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 4 个指标 ==========
FROM (
SELECT B.DATA_DATE, --数据日期
             B.ORG_NUM, --机构号
             CASE
               WHEN A.CORP_SCALE = 'B' THEN
                'S63_I_13.A.2024'
               WHEN A.CORP_SCALE = 'M' THEN
                'S63_I_13.B.2024'
               WHEN A.CORP_SCALE = 'S' THEN
                'S63_I_13.C.2024'
               WHEN A.CORP_SCALE = 'T' THEN
                'S63_I_13.D.2024'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             B.ACCT_NUM AS COL_1, -- 字段1（合同号）
             B.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
             B.CUST_ID AS COL_3, -- 字段3（客户号）
             A.CUST_NAM AS COL_4, -- 字段4（客户名称）
             (B.LOAN_ACCT_BAL * R.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       B.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       B.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       B.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       B.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN B.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN B.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN B.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN B.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN B.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       B.DEPARTMENTD AS COL_12  --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ B -- 借据表
       INNER JOIN SMTMODS_L_CUST_C A
          ON B.DATA_DATE = A.DATA_DATE
         AND B.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON B.DATA_DATE = R.DATA_DATE
         AND B.CURR_CD = R.BASIC_CCY
         AND R.FORWARD_CCY = 'CNY'
       
       WHERE B.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND SUBSTR(B.ITEM_CD, 1, 4) = '1305' --贸易融资
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND B.ACCT_TYP <> '90'
         AND B.CANCEL_FLG = 'N'
         AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_0
INSERT INTO `S63_I_13.C.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_13.B.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_13.D.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_13.A.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 1: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.C'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.C.2020'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.C.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.C.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.C.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'S'
         AND A.CANCEL_FLG <> 'Y'
            --- AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91
         AND (A.ACCT_TYP NOT LIKE '0101%' AND A.ACCT_TYP NOT LIKE '0103%' AND
             A.ACCT_TYP NOT LIKE '0104%' AND A.ACCT_TYP NOT LIKE '0199%' AND
             A.ACCT_TYP <> 'E01')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;

INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.C'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.C.2020'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.C.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.C.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.C.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.OD_LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'S'
         AND A.CANCEL_FLG <> 'Y'
            ---  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91
         AND (A.ACCT_TYP LIKE '0101%' OR A.ACCT_TYP LIKE '0103%' OR
             A.ACCT_TYP LIKE '0104%' OR A.ACCT_TYP LIKE '0199%')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_1
INSERT INTO `S63_I_1.3.3.C.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.1.C.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.2.C.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *;

-- ========== 逻辑组 2: 共 4 个指标 ==========
FROM (
SELECT B.DATA_DATE, --数据日期
             B.ORG_NUM, --机构号
             CASE
               WHEN A.CORP_SCALE = 'B' THEN
                'S63_I_11.A.2024'
               WHEN A.CORP_SCALE = 'M' THEN
                'S63_I_11.B.2024'
               WHEN A.CORP_SCALE = 'S' THEN
                'S63_I_11.C.2024'
               WHEN A.CORP_SCALE = 'T' THEN
                'S63_I_11.D.2024'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       B.ACCT_NUM AS COL_1, -- 字段1（合同号）
       B.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       B.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (B.LOAN_ACCT_BAL * R.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       B.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       B.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       B.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       B.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN B.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN B.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN B.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN B.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN B.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        B.DEPARTMENTD AS COL_12, --  字段12（业务条线）
        B.LOAN_PURPOSE_CD , --贷款投向
        M1.M_NAME
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ B -- 借据表
       INNER JOIN SMTMODS_L_CUST_C A
          ON B.DATA_DATE = A.DATA_DATE
         AND B.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON B.DATA_DATE = R.DATA_DATE
         AND B.CURR_CD = R.BASIC_CCY
         AND R.FORWARD_CCY = 'CNY'
       LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C
          ON  (B.LOAN_PURPOSE_CD = C.LOAN_PURPOSE_CD AND
             B.INDUST_STG_TYPE = C.COLUMN_OODE)     --贷款投向在相应G19投向表中
        
        LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C1
            ON (SUBSTR(B.LOAN_PURPOSE_CD, 1, 4) = C1.LOAN_PURPOSE_CD AND
             B.INDUST_STG_TYPE = C1.COLUMN_OODE)
        LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C2
            ON   (SUBSTR(B.LOAN_PURPOSE_CD, 1, 3) = C2.LOAN_PURPOSE_CD AND
             B.INDUST_STG_TYPE = C2.COLUMN_OODE )  
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
          ON M1.M_CODE =B.INDUST_STG_TYPE
          AND  M_TABLECODE ='INDUST_STG_TYPE'
       WHERE B.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND B.INDUST_STG_TYPE IN
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') --战略性新兴产业领域包含节能环保、新一代信息技术、生物、高端装备制造、新能源、新材料、新能源汽车、数字创意、相关服务九类
         AND B.ACCT_TYP NOT LIKE '01%'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND B.ACCT_TYP <> '90'
         AND B.CANCEL_FLG = 'N'
         AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (C.LOAN_PURPOSE_CD IS NOT NULL OR C1.LOAN_PURPOSE_CD  IS NOT NULL  OR C2.LOAN_PURPOSE_CD  IS NOT NULL )
) q_2
INSERT INTO `S63_I_11.D.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12 , 
       COL_13 ,  
       COL_21)
SELECT *
INSERT INTO `S63_I_11.C.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12 , 
       COL_13 ,  
       COL_21)
SELECT *
INSERT INTO `S63_I_11.A.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12 , 
       COL_13 ,  
       COL_21)
SELECT *
INSERT INTO `S63_I_11.B.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12 , 
       COL_13 ,  
       COL_21)
SELECT *;

-- ========== 逻辑组 3: 共 7 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.G'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.G.2020'
         WHEN A.OD_DAYS < 361 THEN
          'S63_I_1.3.2.G'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.G'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 0 AND A.OD_DAYS <= 30 THEN
          'S63_I_1.3.1.G.2025'
         WHEN A.OD_DAYS > 30 AND A.OD_DAYS <= 60 THEN
          'S63_I_1.3.2.G.2025'
         WHEN A.OD_DAYS > 60 AND A.OD_DAYS <= 90 THEN
          'S63_I_1.3.3.G.2025'
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.G.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.G.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.G.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.G.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(B.CUST_NAM, C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP LIKE '0102%'
         AND (C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3')
            --  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS > 0
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_3
INSERT INTO `S63_I_1.3.6.G.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.1.G.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.5.G.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.4.G.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.3.G.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.7.G.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.2.G.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *;

-- ========== 逻辑组 4: 共 7 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.H'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.H.2020'
         WHEN A.OD_DAYS < 361 THEN
          'S63_I_1.3.2.H'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.H'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 0 AND A.OD_DAYS <= 30 THEN
          'S63_I_1.3.1.H.2025'
         WHEN A.OD_DAYS > 30 AND A.OD_DAYS <= 60 THEN
          'S63_I_1.3.2.H.2025'
         WHEN A.OD_DAYS > 60 AND A.OD_DAYS <= 90 THEN
          'S63_I_1.3.3.H.2025'
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.H.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.H.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.H.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.H.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       C.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.ACCT_TYP LIKE '0102%'
         AND A.CANCEL_FLG <> 'Y'
         AND C.OPERATE_CUST_TYPE = 'B'
            --- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS > 0
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_4
INSERT INTO `S63_I_1.3.4.H.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.2.H.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.3.H.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.1.H.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.5.H.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.6.H.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.7.H.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *;

-- ========== 逻辑组 5: 共 7 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.F'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.F.2020'
         WHEN A.OD_DAYS < 361 THEN
          'S63_I_1.3.2.F'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.F'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 0 AND A.OD_DAYS <= 30 THEN
          'S63_I_1.3.1.F.2025'
         WHEN A.OD_DAYS > 30 AND A.OD_DAYS <= 60 THEN
          'S63_I_1.3.2.F.2025'
         WHEN A.OD_DAYS > 60 AND A.OD_DAYS <= 90 THEN
          'S63_I_1.3.3.F.2025'
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.F.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.F.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.F.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.F.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(B.CUST_NAM, C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
          '个体工商户'
         WHEN C.OPERATE_CUST_TYPE = 'B' THEN
          '小微企业主'
         WHEN C.OPERATE_CUST_TYPE = 'Z' THEN
          '其他个人'
       end AS COL_18, -- 字段18（个人客户类型（个体工商户 小微企业主 其他个人））

       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.ACCT_TYP LIKE '0102%'
            --- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.CANCEL_FLG <> 'Y'
         AND A.OD_DAYS > 0
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_5
INSERT INTO `S63_I_1.3.7.F.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.2.F.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.3.F.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.5.F.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.4.F.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.6.F.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.1.F.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18,  
       COL_14)
SELECT *;

-- ========== 逻辑组 6: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.D'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.D.2020'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.D.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.D.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.D.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'T'
         AND A.CANCEL_FLG <> 'Y'
            ---  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91
         AND (A.ACCT_TYP NOT LIKE '0101%' AND A.ACCT_TYP NOT LIKE '0103%' AND
             A.ACCT_TYP NOT LIKE '0104%' AND A.ACCT_TYP NOT LIKE '0199%' AND
             A.ACCT_TYP <> 'E01')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;

INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.D'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.D.2020'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.D.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.D.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.D.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.OD_LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'T'
         AND A.CANCEL_FLG <> 'Y'
            --- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91
         AND (A.ACCT_TYP LIKE '0101%' OR A.ACCT_TYP LIKE '0103%' OR
             A.ACCT_TYP LIKE '0104%' OR A.ACCT_TYP LIKE '0199%')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_6
INSERT INTO `S63_I_1.3.3.D.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.2.D.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.1.D.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *;

-- 指标: S63_I_7.1.F
-- 7.1无还本续贷贷款余额 个人经营性
    INSERT INTO `S63_I_7.1.F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_7.1.F' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM, B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) +
       (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
          '个体工商户'
         WHEN A.OPERATE_CUST_TYPE = 'A' THEN
          '小微企业主'
         WHEN A.OPERATE_CUST_TYPE = 'Z' THEN
          '其他个人'
       end COL_18
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
            --AND T.LOAN_KIND_CD = '6' --借续贷
            -- alter by  shiyu 230202 6无还本续贷,7 再融资
         AND T.LOAN_KIND_CD in ('6', '7')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- ========== 逻辑组 8: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_7.2.A'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_7.2.B'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_7.2.C'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_7.2.D'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(T.DRAWDOWN_AMT * U.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE T.DATA_DATE = I_DATADATE
            -- AND T.LOAN_KIND_CD = '6' --借续贷
            -- alter by  shiyu 230202 6无还本续贷,7 再融资
         AND T.LOAN_KIND_CD in ('6', '7')
         AND T.CANCEL_FLG <> 'Y'
         AND T.DRAWDOWN_DT >= TRUNC(D_DATADATE_CCY, 'Y') --发生
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CUST_TYP NOT IN ('2', '4', '5') --政府机关、社会团体、事业单位
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_8
INSERT INTO `S63_I_7.2.D` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_7.2.C` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_7.2.B` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 9: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             CASE
               WHEN A.CORP_SCALE = 'B' THEN
                'S63_I_4.1.A.2024'
               WHEN A.CORP_SCALE = 'M' THEN
                'S63_I_4.1.B.2024'
               WHEN A.CORP_SCALE = 'S' THEN
                'S63_I_4.1.C.2024'
               WHEN A.CORP_SCALE = 'T' THEN
                'S63_I_4.1.D.2024'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NO AS COL_1, -- 字段1（合同号）
       T.ACCT_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (NVL(T.BALANCE * TT.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.BUSINESS_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.GL_ITEM_CODE AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
        T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_L_ACCT_OBS_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND T.ACCT_TYP = '111' --银行承兑汇票
) q_9
INSERT INTO `S63_I_4.1.D.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_12)
SELECT *
INSERT INTO `S63_I_4.1.C.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_12)
SELECT *
INSERT INTO `S63_I_4.1.A.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_12)
SELECT *
INSERT INTO `S63_I_4.1.B.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_12)
SELECT *;

-- ========== 逻辑组 10: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_7.1.A'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_7.1.B'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_7.1.C'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_7.1.D'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) +
       (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE T.DATA_DATE = I_DATADATE
            --AND T.LOAN_KIND_CD = '6' --借续贷
            -- alter by  shiyu 230202 6无还本续贷,7 再融资
         AND T.LOAN_KIND_CD in ('6', '7')
         AND T.CANCEL_FLG <> 'Y'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CUST_TYP NOT IN ('2', '4', '5') --政府机关、社会团体、事业单位
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_10
INSERT INTO `S63_I_7.1.B` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_7.1.C` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_7.1.D` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 11: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       TT1.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_10.3.A.2024'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_10.3.B.2024'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_10.3.C.2024'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_10.3.D.2024'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.DRAWDOWN_AMT * TT.CCY_RATE * TT1.REAL_INT_RAT / 100)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）--放款金额*实际利率[执行利率(年)]/100
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
      T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 ---M7取放款时实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
      /* LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')*/
        
       WHERE T.DATA_DATE = I_DATADATE
            -- AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND T.CANCEL_FLG <> 'Y'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND (T.RESCHED_FLG = 'N' or t.RESCHED_FLG is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND A.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_11
INSERT INTO `S63_I_10.3.D.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.3.A.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.3.C.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.3.B.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 12: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.G'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.G'
       -- WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       --20210923  ZHOUJINGKUN UPDATE 新信贷系统修改映射B01  B99
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'S63_I_1.2.3.G'
       END,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(P.CUST_NAM, C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND T.DATA_DATE = P.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND T.DATA_DATE = C.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND TT.FORWARD_CCY = 'CNY'
         AND (P.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL -- add by haorui 20250311 JLBA202408200012 资产未转让
) q_12
INSERT INTO `S63_I_1.2.2.G` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.1.G` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.3.G` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *;

-- ========== 逻辑组 13: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             CASE
               WHEN A.CORP_SCALE = 'B' THEN
                'S63_I_4.2.A.2024'
               WHEN A.CORP_SCALE = 'M' THEN
                'S63_I_4.2.B.2024'
               WHEN A.CORP_SCALE = 'S' THEN
                'S63_I_4.2.C.2024'
               WHEN A.CORP_SCALE = 'T' THEN
                'S63_I_4.2.D.2024'
             END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NO AS COL_1, -- 字段1（合同号）
       T.ACCT_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (NVL(T.BALANCE * TT.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.BUSINESS_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.GL_ITEM_CODE AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_L_ACCT_OBS_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND SUBSTR(T.ACCT_TYP, 1, 2) = '31' --跟单信用证
) q_13
INSERT INTO `S63_I_4.2.B.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_12)
SELECT *
INSERT INTO `S63_I_4.2.C.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_12)
SELECT *
INSERT INTO `S63_I_4.2.A.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_12)
SELECT *
INSERT INTO `S63_I_4.2.D.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_12)
SELECT *;

-- ========== 逻辑组 14: 共 2 个指标 ==========
FROM (
SELECT
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_6.3.A.2024'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_6.3.B.2024'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_6.3.C.2024'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_6.3.D.2024'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.DRAWDOWN_AMT * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
        
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND A.CUST_TYP <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_14
INSERT INTO `S63_I_6.3.C.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_6.3.D.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 15: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_1.2.2.1.A.2021'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_1.2.2.1.B.2021'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_1.2.2.1.C.2021'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_1.2.2.1.D.2021'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM  AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * TT.CCY_RATE)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       INNER JOIN (SELECT
                  
                   DISTINCT B.CONTRACT_NUM --贷款合同号
                     FROM SMTMODS_L_AGRE_GUARANTEE_RELATION F1 --担保合同与担保信息对应关系表
                     LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT F --担保合同表
                       ON F.GUAR_CONTRACT_NUM = F1.GUAR_CONTRACT_NUM
                      AND F.DATA_DATE = I_DATADATE
                     LEFT JOIN SMTMODS_L_AGRE_GUA_RELATION E --业务合同与担保合同对应关系表 E
                       ON E.GUAR_CONTRACT_NUM = F.GUAR_CONTRACT_NUM
                      AND E.DATA_DATE = I_DATADATE
                     LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT B --贷款合同信息表 B
                       ON B.CONTRACT_NUM = E.CONTRACT_NUM
                      AND B.DATA_DATE = I_DATADATE
                    INNER JOIN CBRC_FINANCE_COMPANY_LIST L
                       ON TRIM(F1.GUARANTEE_NAME) = TRIM(L.COMPANY_NAME)
                    WHERE F1.DATA_DATE = I_DATADATE
                      AND F.GUAR_CONTRACT_STATUS = 'Y' --担保合同有效状态
                      AND B.ACCT_STS = '1' --合同状态：1有效
                      and L.GOV_FLG = 'Y' --政府性融资担保公司
                   ) T1
          ON T1.CONTRACT_NUM = T.ACCT_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.GUARANTY_TYP LIKE 'C%' --担保方式：保证
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_15
INSERT INTO `S63_I_1.2.2.1.C.2021` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.2.2.1.A.2021` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.2.2.1.B.2021` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.2.2.1.D.2021` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 16: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             CASE
               WHEN A.CORP_SCALE = 'B' THEN
                'S63_I_4.3.A.2024'
               WHEN A.CORP_SCALE = 'M' THEN
                'S63_I_4.3.B.2024'
               WHEN A.CORP_SCALE = 'S' THEN
                'S63_I_4.3.C.2024'
               WHEN A.CORP_SCALE = 'T' THEN
                'S63_I_4.3.D.2024'
             END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NO AS COL_1, -- 字段1（合同号）
       T.ACCT_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (NVL(T.BALANCE * TT.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.BUSINESS_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.GL_ITEM_CODE AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_L_ACCT_OBS_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = D_DATADATE_CCY
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
     
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(A.CUST_TYP, 1, 1) IN ('1', '0')
         AND A.CORP_SCALE IS NOT NULL --企业规模不为空
         AND SUBSTR(T.ACCT_TYP, 1, 3) IN ('121', '211') --保函
) q_16
INSERT INTO `S63_I_4.3.C.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_12)
SELECT *
INSERT INTO `S63_I_4.3.D.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_12)
SELECT *
INSERT INTO `S63_I_4.3.A.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_12)
SELECT *
INSERT INTO `S63_I_4.3.B.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_12)
SELECT *;

-- ========== 逻辑组 17: 共 5 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.G'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.G'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.G'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.G'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.G'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(B.CUST_NAM, C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (nvl(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (nvl(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
       AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.ACCT_TYP LIKE '0102%'
         AND A.CANCEL_FLG <> 'Y'
         AND (C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3')
            --  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_17
INSERT INTO `S63_I_1.1.3.G` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.2.G` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.4.G` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.1.G` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.5.G` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 18: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_6.1.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_6.1.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_6.1.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_6.1.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * tt.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND T.GUARANTY_TYP = 'D'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_18
INSERT INTO `S63_I_6.1.1.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_6.1.1.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 19: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.CORP_SCALE = 'B' THEN
          'S63_I_10.1.A.2024'
         WHEN B.CORP_SCALE = 'M' THEN
          'S63_I_10.1.B.2024'
         WHEN B.CORP_SCALE = 'S' THEN
          'S63_I_10.1.C.2024'
         WHEN B.CORP_SCALE = 'T' THEN
          'S63_I_10.1.D.2024'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE)  AS COL_5,  -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
        -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
      --    需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(B.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CANCEL_FLG <> 'Y'
            --    需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND B.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_19
INSERT INTO `S63_I_10.1.A.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.1.B.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.1.C.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.1.D.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 20: 共 5 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.B'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.B'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.B'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.B'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.B'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'M'
         AND A.CANCEL_FLG <> 'Y'
            --- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_20
INSERT INTO `S63_I_1.1.5.B` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.3.B` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.1.B` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.4.B` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.2.B` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 21: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*  CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS < 361 THEN
          'S63_I_1.3.2.C'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.C'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.C.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.C.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.C.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.C.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'S'
         AND A.CANCEL_FLG <> 'Y'
            -- AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS > 90
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_21
INSERT INTO `S63_I_1.3.4.C.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.7.C.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.5.C.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.6.C.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *;

-- ========== 逻辑组 22: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_1.2.4.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_1.2.4.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_1.2.4.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_1.2.4.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CUST_TYP <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.ACCT_TYP = '030101' --030101 银行承兑汇票
         AND T.ACCT_NUM NOT IN
             (SELECT BILL_NUM FROM CBRC_S6301_DATA_COLLECT_FINACIAL) --扣除财务公司承兑汇票
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_22
INSERT INTO `S63_I_1.2.4.1.A.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.2.4.1.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.2.4.1.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 23: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_1.2.4.3.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_1.2.4.3.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_1.2.4.3.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_1.2.4.3.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND A.CUST_TYP <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.ACCT_TYP = '030102' --030102 商业承兑汇票
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_23
INSERT INTO `S63_I_1.2.4.3.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.2.4.3.A.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.2.4.3.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.2.4.3.B.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 24: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       G.ORG_NUM,
       CASE
         WHEN G.CORP_SCALE = 'B' THEN
          'S63_I_7.4.A.2023'
         WHEN G.CORP_SCALE = 'M' THEN
          'S63_I_7.4.B.2023'
         WHEN G.CORP_SCALE = 'S' THEN
          'S63_I_7.4.C.2023'
         WHEN G.CORP_SCALE = 'T' THEN
          'S63_I_7.4.D.2023'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       G.CUST_ID AS COL_3, --客户号
       G.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null AS COL_10 --机构名称
        FROM (SELECT DISTINCT T.ORG_NUM, T.CUST_ID, A.CORP_SCALE,A.CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
                LEFT JOIN SMTMODS_L_CUST_C A
                  ON T.DATA_DATE = A.DATA_DATE
                 AND T.CUST_ID = A.CUST_ID
               WHERE T.DATA_DATE = I_DATADATE
                    -- AND T.LOAN_KIND_CD = '6' --借续贷
                    -- alter by  shiyu 230202 6无还本续贷,7 再融资
                 AND T.LOAN_KIND_CD in ('6', '7')
                 AND T.CANCEL_FLG <> 'Y'
                 AND T.DRAWDOWN_DT >= TRUNC(D_DATADATE_CCY, 'Y') --发生
                 AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
                 AND A.CUST_TYP NOT IN ('2', '4', '5') --政府机关、社会团体、事业单位
                 AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
              ) G
             
       GROUP BY G.ORG_NUM,
                CASE
                  WHEN G.CORP_SCALE = 'B' THEN
                   'S63_I_7.4.A.2023'
                  WHEN G.CORP_SCALE = 'M' THEN
                   'S63_I_7.4.B.2023'
                  WHEN G.CORP_SCALE = 'S' THEN
                   'S63_I_7.4.C.2023'
                  WHEN G.CORP_SCALE = 'T' THEN
                   'S63_I_7.4.D.2023'
                END,G.CUST_ID,G.CUST_NAM,null
) q_24
INSERT INTO `S63_I_7.4.D.2023` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_7.4.B.2023` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_7.4.C.2023` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- ========== 逻辑组 25: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN B.CORP_SCALE = 'B' THEN
                'S63_I_5.2.A.2022'
               WHEN B.CORP_SCALE = 'M' THEN
                'S63_I_5.2.B.2022'
               WHEN B.CORP_SCALE = 'S' THEN
                'S63_I_5.2.C.2022'
               WHEN B.CORP_SCALE = 'T' THEN
                'S63_I_5.2.D.2022'
             END AS ITEM_NUM,
             A.CUST_ID AS CUST_ID
        FROM SMTMODS_L_AGRE_LOAN_APPLY A
       INNER JOIN SMTMODS_L_CUST_C B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CUST_ID = B.CUST_ID
      /*LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
        ON A.ACCT_NUM = C.ACCT_NUM
       AND C.DATA_DATE = I_DATADATE
      LEFT JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ D
        ON C.CONTRACT_NUM = D.ACCT_NUM
       AND D.DATA_DATE = I_DATADATE*/
       WHERE NVL(A.ACCT_TYP, '&') <> '90'
         AND B.CUST_TYP <> '3'
         AND (SUBSTR(TO_CHAR(A.APPLY_DT, 'yyyymmdd'), 1, 4) =
              SUBSTR(I_DATADATE, 1, 4) --本年申请
              /*OR (\*D.CIRCLE_LOAN_FLG = 'Y' \*循环贷款*\
              AND*\ SUBSTR(TO_CHAR(D.DRAWDOWN_DT, 'yyyymmdd'), 1, 4) =
              SUBSTR(I_DATADATE, 1, 4)) --本年发放*/)
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.DATA_DATE = I_DATADATE
         and A.APPLY_SYS = '2' --审批通过
       group by A.ORG_NUM,
                A.CUST_ID,
                CASE
                  WHEN B.CORP_SCALE = 'B' THEN
                   'S63_I_5.2.A.2022'
                  WHEN B.CORP_SCALE = 'M' THEN
                   'S63_I_5.2.B.2022'
                  WHEN B.CORP_SCALE = 'S' THEN
                   'S63_I_5.2.C.2022'
                  WHEN B.CORP_SCALE = 'T' THEN
                   'S63_I_5.2.D.2022'
                END;

----借据数据,发放日期为当年
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (data_date, org_num, item_num, cust_id)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN B.CORP_SCALE = 'B' THEN
                'S63_I_5.2.A.2022'
               WHEN B.CORP_SCALE = 'M' THEN
                'S63_I_5.2.B.2022'
               WHEN B.CORP_SCALE = 'S' THEN
                'S63_I_5.2.C.2022'
               WHEN B.CORP_SCALE = 'T' THEN
                'S63_I_5.2.D.2022'
             END AS ITEM_NUM,
             A.CUST_ID AS CUST_ID
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN SMTMODS_L_CUST_C B --对公表 取小微企业
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         and NVL(A.ACCT_TYP, '&') <> '90' --剔除委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND B.CUST_TYP <> '3'
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105')
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_25
INSERT INTO `S63_I_5.2.D.2022` (data_date, org_num, item_num, cust_id)
SELECT *
INSERT INTO `S63_I_5.2.B.2022` (data_date, org_num, item_num, cust_id)
SELECT *
INSERT INTO `S63_I_5.2.C.2022` (data_date, org_num, item_num, cust_id)
SELECT *
INSERT INTO `S63_I_5.2.A.2022` (data_date, org_num, item_num, cust_id)
SELECT *;

-- ========== 逻辑组 26: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.C'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.C'
       /*   WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       'S63_I_1.2.3.C'*/
       --20210923  ZHOUJINGKUN UPDATE 新信贷系统修改映射B01  B99
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'S63_I_1.2.3.C'
         WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
          'S63_I_1.2.4.C'
       END,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL, 0) * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN t.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN t.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN t.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN t.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN t.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
     
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.CORP_SCALE = 'S'
         AND T.LOAN_ACCT_BAL <> 0
         AND TT.FORWARD_CCY = 'CNY'
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_26
INSERT INTO `S63_I_1.2.1.C` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.4.C` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.3.C` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.2.C` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *;

-- ========== 逻辑组 27: 共 5 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.C'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.C'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.C'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.C'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.C'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         and A.ACCT_TYP NOT LIKE '90%'
         AND B.CORP_SCALE = 'S'
         AND A.CANCEL_FLG <> 'Y'
            --- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_27
INSERT INTO `S63_I_1.1.4.C` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.2.C` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.3.C` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.1.C` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.5.C` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 28: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM,
             CASE
               WHEN B.CORP_SCALE = 'B' THEN
                'S63_I_5.1.A.2022'
               WHEN B.CORP_SCALE = 'M' THEN
                'S63_I_5.1.B.2022'
               WHEN B.CORP_SCALE = 'S' THEN
                'S63_I_5.1.C.2022'
               WHEN B.CORP_SCALE = 'T' THEN
                'S63_I_5.1.D.2022'
             END AS ITEM_NUM,
              'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.cust_id AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN SMTMODS_L_CUST_C B --对公表 取小微企业
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 C --取放款时机构
          ON A.LOAN_NUM = C.LOAN_NUM
        
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND B.CUST_TYP <> '3'
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY C.ORG_NUM,
                CASE
                  WHEN B.CORP_SCALE = 'B' THEN
                   'S63_I_5.1.A.2022'
                  WHEN B.CORP_SCALE = 'M' THEN
                   'S63_I_5.1.B.2022'
                  WHEN B.CORP_SCALE = 'S' THEN
                   'S63_I_5.1.C.2022'
                  WHEN B.CORP_SCALE = 'T' THEN
                   'S63_I_5.1.D.2022'
                END,A.cust_id,B.CUST_NAM,null
) q_28
INSERT INTO `S63_I_5.1.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_5.1.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_5.1.B.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_5.1.A.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- ========== 逻辑组 29: 共 5 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.F'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.F'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.F'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.F'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.F'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(B.CUST_NAM, C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (nvl(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (nvl(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
       AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
          '个体工商户'
         WHEN C.OPERATE_CUST_TYPE = 'B' THEN
          '小微企业主'
         WHEN C.OPERATE_CUST_TYPE = 'Z' THEN
          '其他个人'
       end -- 字段18（个人客户类型（个体工商户 小微企业主 其他个人））
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.ACCT_TYP LIKE '0102%'
         AND A.CANCEL_FLG <> 'Y'
            --AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_29
INSERT INTO `S63_I_1.1.4.F` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18)
SELECT *
INSERT INTO `S63_I_1.1.1.F` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18)
SELECT *
INSERT INTO `S63_I_1.1.2.F` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18)
SELECT *
INSERT INTO `S63_I_1.1.3.F` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18)
SELECT *
INSERT INTO `S63_I_1.1.5.F` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18)
SELECT *;

-- ========== 逻辑组 30: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_2.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_2.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_2.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_2.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.DRAWDOWN_AMT * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
            -- AND T.LOAN_ACCT_BAL <> 0
         AND A.CUST_TYP <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_30
INSERT INTO `S63_I_2.1.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_2.1.A.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_2.1.B.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_2.1.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 31: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_9.1.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_9.1.H.2022'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = T.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环  1是 0 否,贷款合同与借据保持一致
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_31
INSERT INTO `S63_I_9.1.H.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_9.1.G.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- 指标: S63_I_2.1.F.2022
--2.1当年累放贷款金额   个人经营性
    INSERT INTO `S63_I_2.1.F.2022`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       'S63_I_2.1.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
      CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          '个体工商户'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          '小微企业主'
         WHEN A.OPERATE_CUST_TYPE = 'Z' THEN '其他个人'
       END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- ========== 逻辑组 33: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.B'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.B'
       /* WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       'S63_I_1.2.3.B'*/
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN --ZHOUJINGKUN 20210923 新信贷系统码值重新映射
          'S63_I_1.2.3.B'
         WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
          'S63_I_1.2.4.B'
       END,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL, 0) * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN t.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN t.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN t.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN t.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN t.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND A.CORP_SCALE = 'M'
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND TT.FORWARD_CCY = 'CNY'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_33
INSERT INTO `S63_I_1.2.1.B` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.2.B` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.3.B` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.4.B` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *;

-- ========== 逻辑组 34: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_10.2.A.2024'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_10.2.B.2024'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_10.2.C.2024'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_10.2.D.2024'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (DRAWDOWN_AMT * TT.CCY_RATE)AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）--放款金额*实际利率[执行利率(年)]/100
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
      T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
       
      --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据

      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
            -- AND T.LOAN_ACCT_BAL <> 0
         AND A.CUST_TYP <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND A.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_34
INSERT INTO `S63_I_10.2.B.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.2.C.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.2.A.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.2.D.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 35: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS < 361 THEN
          'S63_I_1.3.2.B'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.B'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.B.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.B.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.B.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.B.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'M'
         AND A.CANCEL_FLG <> 'Y'
            ---  AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.OD_DAYS > 90
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_35
INSERT INTO `S63_I_1.3.5.B.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.7.B.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.6.B.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.4.B.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *;

-- ========== 逻辑组 36: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.CORP_SCALE = 'B' THEN
          'S63_I_10.1.1.A.2025'
         WHEN B.CORP_SCALE = 'M' THEN
          'S63_I_10.1.1.B.2025'
         WHEN B.CORP_SCALE = 'S' THEN
          'S63_I_10.1.1.C.2025'
         WHEN B.CORP_SCALE = 'T' THEN
          'S63_I_10.1.1.D.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE)  AS COL_5,  -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
        -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
     
      --    需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(B.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --    需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND B.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是

         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12
) q_36
INSERT INTO `S63_I_10.1.1.D.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.1.1.A.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.1.1.C.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.1.1.B.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 37: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_2.1.1.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_2.1.1.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') OR B.CUST_TYP = '3')
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND T.GUARANTY_TYP = 'D' --信用/免担保贷款
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_37
INSERT INTO `S63_I_2.1.1.H.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_2.1.1.G.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 38: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.A'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.A'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.A'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.A'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.A'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）

       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       M1.M_NAME
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
      /*INNER JOIN SMTMODS_L_CUST_ALL T
       ON A.CUST_ID = T.CUST_ID
      AND T.DATA_DATE = I_DATADATE*/
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
          ON B.CORP_HOLD_TYPE = M1.M_CODE
         AND M1.M_TABLECODE = 'CORP_HOLD_TYPE'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND B.CORP_SCALE = 'B'
         AND A.CANCEL_FLG <> 'Y'
            -- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_38
INSERT INTO `S63_I_1.1.2.A` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_16)
SELECT *
INSERT INTO `S63_I_1.1.5.A` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_16)
SELECT *
INSERT INTO `S63_I_1.1.1.A` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_16)
SELECT *;

-- ========== 逻辑组 39: 共 2 个指标 ==========
FROM (
SELECT 
       DISTINCT  I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_6.2.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_6.2.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_6.2.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_6.2.D.2022'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.cust_id AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_STS <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_39
INSERT INTO `S63_I_6.2.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_6.2.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- 指标: S63_I_2.2.F.2022
--2.2当年累放贷款年化利息收益   个人经营性
    INSERT INTO `S63_I_2.2.F.2022`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       TT1.ORG_NUM,
       'S63_I_2.2.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * U.CCY_RATE * TT1.REAL_INT_RAT / 100) AS COL_5, --放款金额*实际利率[执行利率(年)]/100
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
        CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          '个体工商户'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          '小微企业主'
         WHEN A.OPERATE_CUST_TYPE = 'Z' THEN --其中：小微企业主贷款
          '其他个人'
       END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 ---M7取放款时实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
      
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' or t.RESCHED_FLG is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- ========== 逻辑组 41: 共 5 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.H'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.H'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.H'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.H'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.H'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       C.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (nvl(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (nvl(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
       AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP LIKE '0102%'
         AND C.OPERATE_CUST_TYPE = 'B'
            --  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_41
INSERT INTO `S63_I_1.1.5.H` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.3.H` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.2.H` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.1.H` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.4.H` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 42: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_1.2.3.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_1.2.3.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_1.2.3.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_1.2.3.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM  AS COL_4, -- 字段4（客户名称）
      T.LOAN_ACCT_BAL * U.CCY_RATE * g.zb  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）

        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN CBRC_S6301_DATA_COLLECT_GUARANTEE G --新型抵质押类贷款临时表
          ON G.CONTRACT_NUM = T.ACCT_NUM
         and COLL_MK_VAL <> 0
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'  --客户类型为企业
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%' --非委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         and a.cust_typ <> '3'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_42
INSERT INTO `S63_I_1.2.3.1.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.2.3.1.B.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.2.3.1.A.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.2.3.1.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- 指标: S63_I_14.1.B.2024
/* 14.1银行承兑汇票扣除财务公司承兑汇票,由于银承包含了财务公司,14.2财务公司承兑汇票已经有
    因此14.1银行承兑汇票需要去掉 */

    --14.1银行承兑汇票 大、中、小、微
    INSERT INTO `S63_I_14.1.B.2024`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       /*CASE
         WHEN T3.CORP_SCALE = 'B' THEN
          'S63_I_14.1.A.2024'
         WHEN T3.CORP_SCALE = 'M' THEN
          'S63_I_14.1.B.2024'
         WHEN T3.CORP_SCALE = 'S' THEN
          'S63_I_14.1.C.2024'
         WHEN T3.CORP_SCALE = 'T' THEN
          'S63_I_14.1.D.2024'
       END AS ITEM_NUM,*/
       CASE
         WHEN T3.CORP_SIZE = '01' THEN
          'S63_I_14.1.A.2024'
         WHEN T3.CORP_SIZE = '02' THEN
          'S63_I_14.1.B.2024'
         WHEN T3.CORP_SIZE = '03' THEN
          'S63_I_14.1.C.2024'
         WHEN T3.CORP_SIZE = '04' THEN
          'S63_I_14.1.D.2024'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       T3.ORG_FULLNAME AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5,-- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN CBRC_S6301_DATA_COLLECT_BILL_TY T2 --（1）买断式转帖客户需要在转贴现同业客户信息表找到对应客户
          ON T.CUST_ID = T2.CUST_ID
      /*INNER JOIN SMTMODS_L_CUST_C T3 --（2）再找到对应ECIF客户的企业规模
       ON T2.ECIF_CUST_ID = T3.CUST_ID
      AND T3.DATA_DATE = I_DATADATE*/
       INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO T3 --（2）康哥反馈按照总行报送,客户外部信息表（万德债券投资表）存的是总行级别的,风险：刘名赫反馈交易对手在万德债券投资表都存在,不仅只有债券业务,也有票据的
          ON T2.LEGAL_TYSHXYDM = T3.USCD
         AND T3.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            /*AND SUBSTR(T3.CUST_TYP, 1, 1) IN ('1', '0')*/
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
            /*AND T3.CORP_SCALE IN ('B', 'M', 'S', 'T')*/
         AND T3.CORP_SIZE IN ('01', '02', '03', '04')
         AND T.ACCT_TYP = '030101' --030101 银行承兑汇票
         AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
         AND T.ACCT_NUM NOT IN
             (SELECT BILL_NUM FROM CBRC_S6301_DATA_COLLECT_FINACIAL) --扣除财务公司承兑汇票
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- 指标: S63_I_2.1.1.F.2022
--2.1.1当年累放信用贷款   个人经营性

    INSERT INTO `S63_I_2.1.1.F.2022`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 ,--  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       'S63_I_2.1.1.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 ,--  字段12（业务条线）
        CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          '个体工商户'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          '小微企业主'
         WHEN A.OPERATE_CUST_TYPE = 'Z' THEN --其中：小微企业主贷款
          '其他个人'
       END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND T.GUARANTY_TYP = 'D' --信用/免担保贷款
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- ========== 逻辑组 45: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_9.2.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_9.2.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_9.2.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_9.2.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             T.cust_id AS COL_3, -- 字段3（客户号）
             A.CUST_NAM AS COL_4, -- 字段4（客户名称）
             1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
             null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_STS <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环 ,贷款合同与借据保持一致,
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN A.CORP_SCALE = 'B' THEN
                   'S63_I_9.2.A.2022'
                  WHEN A.CORP_SCALE = 'M' THEN
                   'S63_I_9.2.B.2022'
                  WHEN A.CORP_SCALE = 'S' THEN
                   'S63_I_9.2.C.2022'
                  WHEN A.CORP_SCALE = 'T' THEN
                   'S63_I_9.2.D.2022'
                END,T.cust_id,A.CUST_NAM,null
) q_45
INSERT INTO `S63_I_9.2.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_9.2.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_9.2.B.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_9.2.A.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- ========== 逻辑组 46: 共 5 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          'S63_I_1.1.1.D'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          'S63_I_1.1.2.D'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          'S63_I_1.1.3.D'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          'S63_I_1.1.4.D'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          'S63_I_1.1.5.D'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE) COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'T'
         AND A.CANCEL_FLG <> 'Y'
            ---  AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_46
INSERT INTO `S63_I_1.1.2.D` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.1.D` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.3.D` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.4.D` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.1.5.D` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 47: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             P.ORG_NUM,
             CASE
               WHEN B.Cust_Typ = '3' OR C.OPERATE_CUST_TYPE = 'A' THEN
                'S63_I_5.1.G.2022'
               WHEN C.OPERATE_CUST_TYPE = 'B' THEN
                'S63_I_5.1.H.2022'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             A.cust_id AS COL_3, -- 字段3（客户号）
       NVL(B.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN SMTMODS_L_CUST_C B --对公表 取小微企业
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 P
          ON A.LOAN_NUM = P.LOAN_NUM
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND A.ACCT_TYP LIKE '0102%'
         AND (C.OPERATE_CUST_TYPE IN ('A', 'B') OR B.CUST_TYP = '3')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY P.ORG_NUM,
                CASE
                  WHEN B.Cust_Typ = '3' OR C.OPERATE_CUST_TYPE = 'A' THEN
                   'S63_I_5.1.G.2022'
                  WHEN C.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_5.1.H.2022'
                END,A.cust_id,NVL(B.CUST_NAM,C.CUST_NAM),null
) q_47
INSERT INTO `S63_I_5.1.G.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_5.1.H.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- ========== 逻辑组 48: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS < 361 THEN
          'S63_I_1.3.2.D'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.D'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.D.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.D.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.D.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.D.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'T'
         AND A.CANCEL_FLG <> 'Y'
            --- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS > 90
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_48
INSERT INTO `S63_I_1.3.7.D.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.6.D.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.4.D.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *
INSERT INTO `S63_I_1.3.5.D.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_14)
SELECT *;

-- ========== 逻辑组 49: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_6.2.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_6.2.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_6.2.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_6.2.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_STS <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN A.CORP_SCALE = 'B' THEN
                   'S63_I_6.2.1.A.2022'
                  WHEN A.CORP_SCALE = 'M' THEN
                   'S63_I_6.2.1.B.2022'
                  WHEN A.CORP_SCALE = 'S' THEN
                   'S63_I_6.2.1.C.2022'
                  WHEN A.CORP_SCALE = 'T' THEN
                   'S63_I_6.2.1.D.2022'
                END,T.CUST_ID,A.CUST_NAM,null
) q_49
INSERT INTO `S63_I_6.2.1.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_6.2.1.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- ========== 逻辑组 50: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_5.1.A'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_5.1.B'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_5.1.C'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_5.1.D'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null as COL_10 --机构名称
        FROM (SELECT LOAN.CUST_ID,
                     LOAN.LOAN_ACCT_BAL,
                     LOAN.DATA_DATE,
                     LOAN.ACCT_TYP,
                     C.CORP_SCALE,
                     LOAN.ORG_NUM,
                     C.CUST_TYP,
                     T.INLANDORRSHORE_FLG,
                     T.CUST_NAM
                FROM (SELECT A.CUST_ID,
                             A.LOAN_ACCT_BAL,
                             A.DATA_DATE,
                             A.ACCT_TYP,
                             A.ORG_NUM
                        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                       WHERE A.ACCT_TYP NOT LIKE '90%'
                         AND A.CANCEL_FLG <> 'Y'
                         AND A.DATA_DATE = I_DATADATE
                         AND A.ACCT_STS <> '3'
                         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                             ('130102', '130105') --m14  不含转贴现
                         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                      ) LOAN
               INNER JOIN SMTMODS_L_CUST_ALL T
                  ON T.CUST_ID = LOAN.CUST_ID
                 AND T.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON T.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE) A
       
       WHERE --A.INLANDORRSHORE_FLG = 'Y' --M2
      --A.CUST_TYP = '11'
       substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
       AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
       AND A.DATA_DATE = I_DATADATE
       AND A.LOAN_ACCT_BAL <> 0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.CORP_SCALE = 'B' THEN
                   'S63_I_5.1.A'
                  WHEN A.CORP_SCALE = 'M' THEN
                   'S63_I_5.1.B'
                  WHEN A.CORP_SCALE = 'S' THEN
                   'S63_I_5.1.C'
                  WHEN A.CORP_SCALE = 'T' THEN
                   'S63_I_5.1.D'
                END,
                A.CUST_ID,
                A.CUST_NAM,
                null
) q_50
INSERT INTO `S63_I_5.1.C` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_5.1.A` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_5.1.D` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_5.1.B` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- ========== 逻辑组 51: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.CORP_SCALE = 'B' THEN
          'S63_I_10.1.2.A.2025'
         WHEN B.CORP_SCALE = 'M' THEN
          'S63_I_10.1.2.B.2025'
         WHEN B.CORP_SCALE = 'S' THEN
          'S63_I_10.1.2.C.2025'
         WHEN B.CORP_SCALE = 'T' THEN
          'S63_I_10.1.2.D.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE)  AS COL_5,  -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
        -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
       FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        
      --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
      /* LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(B.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND B.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.GUARANTY_TYP = 'D'
) q_51
INSERT INTO `S63_I_10.1.2.D.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.1.2.A.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.1.2.B.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_10.1.2.C.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- 指标: S63_I_1.2.3.1.H.2022
--  1.2.3.1新型抵质押类贷款 个体工商户、小微企业主
    INSERT INTO `S63_I_1.2.3.1.H.2022`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' or B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_1.2.3.1.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_1.2.3.1.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,b.CUST_NAM)  AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE * g.zb)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN CBRC_S6301_DATA_COLLECT_GUARANTEE G
          ON G.CONTRACT_NUM = T.ACCT_NUM
        left JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND (A.OPERATE_CUST_TYPE in ('A', 'B') --个体工商户贷款,小微企业主贷款
             OR B.CUST_TYP = '3')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- ========== 逻辑组 53: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.CORP_SCALE = 'B' THEN
          'S63_I_1.4.A'
         WHEN B.CORP_SCALE = 'M' THEN
          'S63_I_1.4.B'
         WHEN B.CORP_SCALE = 'S' THEN
          'S63_I_1.4.C'
         WHEN B.CORP_SCALE = 'T' THEN
          'S63_I_1.4.D'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改,从此视图取。
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            -- AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            ---  AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12
         AND (A.ACCT_TYP NOT LIKE '0101%' AND A.ACCT_TYP NOT LIKE '0103%' AND
             A.ACCT_TYP NOT LIKE '0104%' AND A.ACCT_TYP NOT LIKE '0199%')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
) q_53
INSERT INTO `S63_I_1.4.A` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.4.B` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.4.D` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.4.C` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 54: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       TT1.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_2.2.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_2.2.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_2.2.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_2.2.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * TT.CCY_RATE * TT1.REAL_INT_RAT / 100) AS COL_5, --放款金额*实际利率[执行利率(年)]/100
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 ---M7取放款时实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
       
       WHERE T.DATA_DATE = I_DATADATE
            -- AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND T.CANCEL_FLG <> 'Y'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND (T.RESCHED_FLG = 'N' or t.RESCHED_FLG is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_54
INSERT INTO `S63_I_2.2.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_2.2.A.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_2.2.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_2.2.B.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 55: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.CORP_SCALE = 'B' THEN
          'S63_I_10.4.A.2025'
         WHEN B.CORP_SCALE = 'M' THEN
          'S63_I_10.4.B.2025'
         WHEN B.CORP_SCALE = 'S' THEN
          'S63_I_10.4.C.2025'
         WHEN B.CORP_SCALE = 'T' THEN
          'S63_I_10.4.D.2025'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.cust_id AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）

        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         
      --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据

      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(B.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND B.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现

       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.CORP_SCALE = 'B' THEN
                   'S63_I_10.4.A.2025'
                  WHEN B.CORP_SCALE = 'M' THEN
                   'S63_I_10.4.B.2025'
                  WHEN B.CORP_SCALE = 'S' THEN
                   'S63_I_10.4.C.2025'
                  WHEN B.CORP_SCALE = 'T' THEN
                   'S63_I_10.4.D.2025'
                END,A.cust_id,B.CUST_NAM,null
) q_55
INSERT INTO `S63_I_10.4.A.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_10.4.B.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_10.4.D.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_10.4.C.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- ========== 逻辑组 56: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       G.ORG_NUM,
       CASE
         WHEN (G.OPERATE_CUST_TYPE = 'A' OR G.CUST_TYP = '3') THEN
          'S63_I_7.3.G.2023'
         WHEN G.OPERATE_CUST_TYPE = 'B' THEN
          'S63_I_7.3.H.2023'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       G.CUST_ID AS COL_3, --客户号
       G.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null AS COL_10 --机构名称
        FROM (SELECT DISTINCT T.ORG_NUM,
                              T.CUST_ID,
                              A.OPERATE_CUST_TYPE,
                              C.CUST_TYP,
                              NVL(A.CUST_NAM ,C.CUST_NAM)CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
                LEFT JOIN SMTMODS_L_CUST_P A
                  ON T.DATA_DATE = A.DATA_DATE
                 AND T.CUST_ID = A.CUST_ID
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON T.DATA_DATE = C.DATA_DATE
                 AND T.CUST_ID = C.CUST_ID
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.ACCT_TYP LIKE '0102%' --个人经营性
                    --AND T.LOAN_KIND_CD = '6' --借续贷
                    -- alter by  shiyu 230202 6无还本续贷,7 再融资
                 AND T.LOAN_KIND_CD in ('6', '7')
                 AND T.LOAN_ACCT_BAL <> 0 --ALTER BY WJB 20230202 计算户数的时候不要贷款余额等于0的
                 AND T.CANCEL_FLG <> 'Y'
                 AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
              ) G
             
       GROUP BY G.ORG_NUM,
                CASE
                  WHEN (G.OPERATE_CUST_TYPE = 'A' OR G.CUST_TYP = '3') THEN
                   'S63_I_7.3.G.2023'
                  WHEN G.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_7.3.H.2023'
                END,G.CUST_ID,G.CUST_NAM,null
) q_56
INSERT INTO `S63_I_7.3.H.2023` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_7.3.G.2023` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- ========== 逻辑组 57: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       G.ORG_NUM,
       CASE
         WHEN (G.OPERATE_CUST_TYPE = 'A' OR G.CUST_TYP = '3') THEN
          'S63_I_7.4.G.2023'
         WHEN G.OPERATE_CUST_TYPE = 'B' THEN
          'S63_I_7.4.H.2023'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       G.CUST_ID AS COL_3, --客户号
       G.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null AS COL_10 --机构名称
        FROM (SELECT DISTINCT T.ORG_NUM,
                              T.CUST_ID,
                              A.OPERATE_CUST_TYPE,
                              C.CUST_TYP,
                              NVL(A.CUST_NAM,C.CUST_NAM) CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
                LEFT JOIN SMTMODS_L_CUST_P A
                  ON T.DATA_DATE = A.DATA_DATE
                 AND T.CUST_ID = A.CUST_ID
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON T.DATA_DATE = C.DATA_DATE
                 AND T.CUST_ID = C.CUST_ID
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.ACCT_TYP LIKE '0102%' --个人经营性
                    --AND T.LOAN_KIND_CD = '6' --借续贷
                    -- alter by  shiyu 230202 6无还本续贷,7 再融资
                 AND T.LOAN_KIND_CD in ('6', '7')
                 AND T.CANCEL_FLG <> 'Y'
                 AND T.DRAWDOWN_DT >= TRUNC(D_DATADATE_CCY, 'Y') --发生
                 AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
              ) G
            
       GROUP BY G.ORG_NUM,
                CASE
                  WHEN (G.OPERATE_CUST_TYPE = 'A' OR G.CUST_TYP = '3') THEN
                   'S63_I_7.4.G.2023'
                  WHEN G.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_7.4.H.2023'
                END,G.CUST_ID,G.CUST_NAM,null
) q_57
INSERT INTO `S63_I_7.4.G.2023` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_7.4.H.2023` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- 指标: S63_I_7.4.F.2023
-- 7.4当年无还本续贷贷款累放户数 个人经营性

    INSERT INTO `S63_I_7.4.F.2023`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'S63_I_7.4.F.2023' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       G.CUST_ID AS COL_3, --客户号
       G.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null AS COL_10 --机构名称
        FROM (SELECT DISTINCT T.ORG_NUM, T.CUST_ID,NVL(A.CUST_NAM,C.CUST_NAM) CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
                LEFT JOIN SMTMODS_L_CUST_P A
                  ON T.DATA_DATE = A.DATA_DATE
                 AND T.CUST_ID = A.CUST_ID
                LEFT JOIN SMTMODS_L_CUST_C C
                   ON T.DATA_DATE = C.DATA_DATE
                 AND T.CUST_ID = C.CUST_ID
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.ACCT_TYP LIKE '0102%' --个人经营性
                    --AND T.LOAN_KIND_CD = '6' --借续贷
                    -- alter by  shiyu 230202 6无还本续贷,7 再融资
                 AND T.LOAN_KIND_CD in ('6', '7')
                 AND T.CANCEL_FLG <> 'Y'
                 AND T.DRAWDOWN_DT >= TRUNC(D_DATADATE_CCY, 'Y') --发生
                 AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
              ) G
             
       GROUP BY ORG_NUM,G.CUST_ID,G.CUST_NAM,null;


-- ========== 逻辑组 59: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             C.ORG_NUM,
             CASE
               WHEN B.CORP_SCALE = 'B' THEN
                'S63_I_6.4.A.2024'
               WHEN B.CORP_SCALE = 'M' THEN
                'S63_I_6.4.B.2024'
               WHEN B.CORP_SCALE = 'S' THEN
                'S63_I_6.4.C.2024'
               WHEN B.CORP_SCALE = 'T' THEN
                'S63_I_6.4.D.2024'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
        A.cust_id AS COL_3, -- 字段3（客户号）
        B.CUST_NAM AS COL_4, -- 字段4（客户名称）
        1  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
        null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN SMTMODS_L_CUST_C B --对公表
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 C --取放款时机构
          ON A.LOAN_NUM = C.LOAN_NUM
      
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0')
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND B.CUST_TYP <> '3'
         AND A.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY C.ORG_NUM,
                CASE
                  WHEN B.CORP_SCALE = 'B' THEN
                   'S63_I_6.4.A.2024'
                  WHEN B.CORP_SCALE = 'M' THEN
                   'S63_I_6.4.B.2024'
                  WHEN B.CORP_SCALE = 'S' THEN
                   'S63_I_6.4.C.2024'
                  WHEN B.CORP_SCALE = 'T' THEN
                   'S63_I_6.4.D.2024'
                END,A.cust_id,B.CUST_NAM,null
) q_59
INSERT INTO `S63_I_6.4.C.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_6.4.D.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- ========== 逻辑组 60: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_2.1.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_2.1.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_2.1.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_2.1.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.DRAWDOWN_AMT * tt.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
            --AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.CANCEL_FLG <> 'Y'
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND T.GUARANTY_TYP = 'D' --信用/免担保贷款
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_60
INSERT INTO `S63_I_2.1.1.A.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_2.1.1.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_2.1.1.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_2.1.1.B.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- 指标: S63_I_9.3.F.2022
--9.3当年循环贷累放金额  个人经营性

    INSERT INTO `S63_I_9.3.F.2022`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 ,--  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_9.3.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (t.drawdown_amt * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
        CASE WHEN A.OPERATE_CUST_TYPE ='A' OR C.CUST_TYP ='3' THEN '个体工商户'
            WHEN A.OPERATE_CUST_TYPE ='B' THEN '小微企业主'
            WHEN A.OPERATE_CUST_TYPE ='Z' THEN '其他个人' end
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- ========== 逻辑组 62: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             CASE
               WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
                'S63_I_11.G.2024'
               WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
                'S63_I_11.H.2024'
             END AS ITEM_NUM,
              'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
       t.ACCT_NUM AS COL_1, -- 字段1（合同号）
      t.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       t.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(A.CUST_NAM,b.cust_nam) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
        T.LOAN_PURPOSE_CD , --贷款投向
        M1.M_NAME
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C
          ON  (T.LOAN_PURPOSE_CD = C.LOAN_PURPOSE_CD AND
             T.INDUST_STG_TYPE = C.COLUMN_OODE)     --贷款投向在相应G19投向表中
        
        LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C11
            ON (SUBSTR(T.LOAN_PURPOSE_CD, 1, 4) = C11.LOAN_PURPOSE_CD AND
             T.INDUST_STG_TYPE = C11.COLUMN_OODE)
        LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C22
            ON   (SUBSTR(T.LOAN_PURPOSE_CD, 1, 3) = C22.LOAN_PURPOSE_CD AND
             T.INDUST_STG_TYPE = C22.COLUMN_OODE )  
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = T.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
          ON M1.M_CODE =T.INDUST_STG_TYPE
          AND  M_TABLECODE ='INDUST_STG_TYPE'
      
       WHERE T.DATA_DATE = I_DATADATE
         AND T.INDUST_STG_TYPE IN
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') --战略性新兴产业领域包含节能环保、新一代信息技术、生物、高端装备制造、新能源、新材料、新能源汽车、数字创意、相关服务九类
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND T.ACCT_TYP <> '90'
         AND T.CANCEL_FLG = 'N'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (C.LOAN_PURPOSE_CD IS NOT NULL OR C11.LOAN_PURPOSE_CD  IS NOT NULL  OR C22.LOAN_PURPOSE_CD  IS NOT NULL )
) q_62
INSERT INTO `S63_I_11.G.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12 , 
       COL_13 ,  
       COL_21)
SELECT *
INSERT INTO `S63_I_11.H.2024` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12 , 
       COL_13 ,  
       COL_21)
SELECT *;

-- ========== 逻辑组 63: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.A'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.A'
       /*WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       'S63_I_1.2.3.A'*/
       --20210923  ZHOUJINGKUN UPDATE 新信贷系统修改映射B01  B99
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'S63_I_1.2.3.A'
         WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
          'S63_I_1.2.4.A'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL, 0) * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）

       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN t.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN t.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN t.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN t.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN t.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD

       WHERE T.DATA_DATE = I_DATADATE
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND A.CORP_SCALE = 'B'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND TT.FORWARD_CCY = 'CNY'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_63
INSERT INTO `S63_I_1.2.2.A` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.4.A` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.1.A` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.3.A` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *;

-- ========== 逻辑组 64: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.H'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.H'
       -- WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       --20210923  ZHOUJINGKUN UPDATE 新信贷系统修改映射B01  B99
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'S63_I_1.2.3.H'
       END,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       P.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P P
          ON T.CUST_ID = P.CUST_ID
         AND T.DATA_DATE = P.DATA_DATE
     
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND TT.FORWARD_CCY = 'CNY'
         AND P.OPERATE_CUST_TYPE = 'B'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_64
INSERT INTO `S63_I_1.2.1.H` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.3.H` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.2.H` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *;

-- 指标: S63_I_1.3.2.B.2025
INSERT INTO `S63_I_1.3.2.B.2025`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )
    --   1.3按贷款逾期情况

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /* CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.B'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.B.2020'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.B.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.B.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.B.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'M'
         AND A.CANCEL_FLG <> 'Y'
            -- AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91
         AND (A.ACCT_TYP NOT LIKE '0101%' AND A.ACCT_TYP NOT LIKE '0103%' AND
             A.ACCT_TYP NOT LIKE '0104%' AND A.ACCT_TYP NOT LIKE '0199%' AND
             A.ACCT_TYP <> 'E01')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;

INSERT INTO `S63_I_1.3.2.B.2025`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /* CASE
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.1.B'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.1.B.2020'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS < 31 THEN
          'S63_I_1.3.1.B.2025'
         WHEN A.OD_DAYS < 61 THEN
          'S63_I_1.3.2.B.2025'
         WHEN A.OD_DAYS < 91 THEN
          'S63_I_1.3.3.B.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.OD_LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND B.CORP_SCALE = 'M'
         AND A.CANCEL_FLG <> 'Y'
            ---  AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.OD_DAYS < 91
         AND (A.ACCT_TYP LIKE '0101%' OR A.ACCT_TYP LIKE '0103%' OR
             A.ACCT_TYP LIKE '0104%' OR A.ACCT_TYP LIKE '0199%' OR
             A.ACCT_TYP = 'E01')
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- 指标: S63_I_1.3.7.A.2025
--1.3.2.A  1.3.3.A
    INSERT INTO `S63_I_1.3.7.A.2025`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_14 -- 字段14（逾期天数）
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       /*CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.2.A'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.3.A'
       END AS ITEM_NUM,*/
       CASE
         WHEN A.OD_DAYS > 90 AND A.OD_DAYS <= 180 THEN
          'S63_I_1.3.4.A.2025'
         WHEN A.OD_DAYS > 180 AND A.OD_DAYS <= 270 THEN
          'S63_I_1.3.5.A.2025'
         WHEN A.OD_DAYS > 270 AND A.OD_DAYS <= 360 THEN
          'S63_I_1.3.6.A.2025'
         WHEN A.OD_DAYS > 360 THEN
          'S63_I_1.3.7.A.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       A.OD_DAYS AS COL_14 -- 字段14（逾期天数）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
            --AND B.CUST_TYP LIKE '1%'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.CANCEL_FLG <> 'Y'
         AND B.CORP_SCALE = 'B'
            ---   AND T.INLANDORRSHORE_FLG = 'Y'  --m2
         AND A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.OD_DAYS > 90
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- ========== 逻辑组 67: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN (A.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3') THEN
          'S63_I_7.1.G'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN
          'S63_I_7.1.H'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM, c.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL * U.CCY_RATE, 0)) +
       (NVL(T.INT_ADJEST_AMT * U.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
            --AND T.LOAN_KIND_CD = '6' --借续贷
            -- alter by  shiyu 230202 6无还本续贷,7 再融资
         AND T.LOAN_KIND_CD in ('6', '7')
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_67
INSERT INTO `S63_I_7.1.H` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_7.1.G` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 68: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN (A.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3') THEN
          'S63_I_7.2.G'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN
          'S63_I_7.2.H'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (NVL(T.DRAWDOWN_AMT * U.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
            --AND T.LOAN_KIND_CD = '6' --借续贷
            -- alter by  shiyu 230202 6无还本续贷,7 再融资
         AND T.LOAN_KIND_CD in ('6', '7')
         AND T.CANCEL_FLG <> 'Y'
         AND T.DRAWDOWN_DT >= TRUNC(D_DATADATE_CCY, 'Y') --发生
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_68
INSERT INTO `S63_I_7.2.G` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_7.2.H` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- 指标: S63_I_1.4.F
INSERT INTO `S63_I_1.4.F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18)
    --   1.4中长期贷款

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'S63_I_1.4.F' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(B.CUST_NAM, c.cust_nam) AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       case
         when c.operate_cust_type = 'A' OR B.CUST_TYP = '3' THEN
          '个体工商户'
         when c.operate_cust_type = 'B' then
          '小微企业主'
         when c.operate_cust_type = 'Z' then
          '其他个人'
       END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改,从此视图取。
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.ACCT_TYP LIKE '0102%'
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12
            --- AND MONTHS_BETWEEN(A.ACTUAL_MATURITY_DT, A.DRAWDOWN_DT) > 12 --m5
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现;


-- ========== 逻辑组 70: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_9.3.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_9.3.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_9.3.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_9.3.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (t.drawdown_amt * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.CANCEL_FLG <> 'Y'
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_70
INSERT INTO `S63_I_9.3.A.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_9.3.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_9.3.B.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_9.3.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 71: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_9.3.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_9.3.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (t.drawdown_amt * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CUST_ID = B.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' OR T.RESCHED_FLG IS NULL) -- 累放取非重组
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_71
INSERT INTO `S63_I_9.3.H.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_9.3.G.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 72: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.D'
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.D'
       --   WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       --20210923  ZHOUJINGKUN UPDATE 新信贷系统修改映射B01  B99
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'S63_I_1.2.3.D'
         WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
          'S63_I_1.2.4.D'
       END,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(T.LOAN_ACCT_BAL, 0) * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN t.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN t.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN t.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN t.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN t.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%'
         AND A.CORP_SCALE = 'T'
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND TT.FORWARD_CCY = 'CNY'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_72
INSERT INTO `S63_I_1.2.4.D` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.1.D` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.2.D` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.3.D` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_15)
SELECT *;

-- ========== 逻辑组 73: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             CASE
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('01', 'B') THEN
                'S63_I_3.1.A.2025'
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('02', 'M') THEN
                'S63_I_3.1.B.2025'
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('S', '03') THEN
                'S63_I_3.1.C.2025'
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('04', 'T') THEN
                'S63_I_3.1.D.2025'
             END AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             A.ACCT_NUM as COL_1, --账号
             B.STOCK_CD as COL_2, --债券编号
             A.CUST_ID, --客户号
             C1.CUST_NAM, --客户名
             (NVL(A.PRINCIPAL_BALANCE, 0) * U.CCY_RATE) COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
             b.STOCK_NAM as COL_6, -- 债券名称
             CASE
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('01', 'B') THEN
                '大型'
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('02', 'M') THEN
                '中型'
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('S', '03') THEN
                '小型'
               WHEN nvl(C.CORP_SIZE, C1.CORP_SCALE) in ('04', 'T') THEN
                '微型'
             END COL_7 --  企业规模
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_EXTERNAL_INFO C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C1
          ON A.CUST_ID = C1.CUST_ID
         AND C1.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
         AND A.PRINCIPAL_BALANCE <> 0
         AND B.STOCK_PRO_TYPE in ('D01', 'D04', 'D05', 'D02') /*D01 短期融资债券\超短期融资券  D04 企业债 D05 公司债 D02 中期票据*/
) q_73
INSERT INTO `S63_I_3.1.B.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_17)
SELECT *
INSERT INTO `S63_I_3.1.A.2025` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_17)
SELECT *;

-- 指标: S63_I_7.2.F
-- 7.2当年无还本续贷贷款累放金额 个人经营性
     INSERT INTO `S63_I_7.2.F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_7.2.F' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (NVL(T.DRAWDOWN_AMT * U.CCY_RATE, 0)) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
          '个体工商户'
         WHEN A.OPERATE_CUST_TYPE = 'A' THEN
          '小微企业主'
         WHEN A.OPERATE_CUST_TYPE = 'Z' THEN
          '其他个人'
       end COL_18
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
        LEFT JOIN  SMTMODS_L_CUST_C B
          ON T.cust_id =B.CUST_ID
          AND B.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
            -- AND T.LOAN_KIND_CD = '6' --借续贷
            -- alter by  shiyu 230202 6无还本续贷,7 再融资
         AND T.LOAN_KIND_CD in ('6', '7')
         AND T.CANCEL_FLG <> 'Y'
         AND T.DRAWDOWN_DT >= TRUNC(D_DATADATE_CCY, 'Y') --发生
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- ========== 逻辑组 75: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_1.2.2.1.F.2021'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_1.2.2.1.G.2021'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,b.CUST_NAM)  AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT
                  
                   DISTINCT B.CONTRACT_NUM --贷款合同号
                     FROM SMTMODS_L_AGRE_GUARANTEE_RELATION F1 --担保合同与担保信息对应关系表
                     LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT F --担保合同表
                       ON F.GUAR_CONTRACT_NUM = F1.GUAR_CONTRACT_NUM
                      AND F.DATA_DATE = I_DATADATE
                     LEFT JOIN SMTMODS_L_AGRE_GUA_RELATION E --业务合同与担保合同对应关系表 E
                       ON E.GUAR_CONTRACT_NUM = F.GUAR_CONTRACT_NUM
                      AND E.DATA_DATE = I_DATADATE
                     LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT B --贷款合同信息表 B
                       ON B.CONTRACT_NUM = E.CONTRACT_NUM
                      AND B.DATA_DATE = I_DATADATE
                    INNER JOIN CBRC_FINANCE_COMPANY_LIST L
                       ON TRIM(F1.GUARANTEE_NAME) = TRIM(L.COMPANY_NAME)
                    WHERE F1.DATA_DATE = I_DATADATE
                      AND F.GUAR_CONTRACT_STATUS = 'Y' --担保合同有效状态
                      AND B.ACCT_STS = '1' --合同状态：1有效
                      and L.GOV_FLG = 'Y' --政府性融资担保公司
                   ) T1
          ON T1.CONTRACT_NUM = T.ACCT_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_STS <> '3'
         AND T.GUARANTY_TYP LIKE 'C%' --担保方式：保证
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_75
INSERT INTO `S63_I_1.2.2.1.F.2021` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_1.2.2.1.G.2021` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 76: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       --TMP.ORG_NUM,
       CASE /*WHEN SUBSTR(A.ORG_NUM,1,2) IN ('08','10','11','13') THEN SUBSTR(A.ORG_NUM,1,2)||'0000'*/ --20191012 LJP MODIFY 机构汇总数据缺失,先汇支行再汇分行
         when TMP.ORG_NUM = '009813' then
          '130000'
         WHEN TMP.org_num LIKE '0601%' THEN
          '060300'
         when (SUBSTR(TMP.org_num, 3, 4) = '9801') or
              SUBSTR(TMP.org_num, 1, 4) = '0098' or
              (SUBSTR(TMP.org_num, 3, 2) = '98') then
          TMP.org_num
         ELSE
          SUBSTR(TMP.ORG_NUM, 1, 4) || '00'
       END org_num,
       CASE
         WHEN (TMP.OPERATE_CUST_TYPE = 'A' OR TMP.CUST_TYP = '3') THEN
          'S63_I_5.3.G.2014'
         WHEN TMP.OPERATE_CUST_TYPE = 'B' THEN
          'S63_I_5.3.H.2014'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       TMP.CUST_ID AS COL_3, --客户号
       C.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null as COL_10 --机构名称
        FROM (SELECT A.CUST_ID,
                     A.CORP_SCALE,
                     -- A.INLANDORRSHORE_FLG,
                     A.CUST_TYP,
                     A.ORG_NUM,
                     A.DATA_DATE,
                     A.ACCT_TYP,
                     A.OPERATE_CUST_TYPE
                FROM (SELECT LOAN.CUST_ID,
                             LOAN.LOAN_ACCT_BAL,
                             LOAN.DATA_DATE,
                             LOAN.ACCT_TYP,
                             C.CORP_SCALE,
                             LOAN.ORG_NUM,
                             --T.INLANDORRSHORE_FLG,
                             C.CUST_TYP,
                             LCP.OPERATE_CUST_TYPE
                        FROM (SELECT A.CUST_ID,
                                     A.LOAN_ACCT_BAL,
                                     A.DATA_DATE,
                                     A.ACCT_TYP,
                                     A.ORG_NUM
                                FROM SMTMODS_L_AGRE_LOAN_CONTRACT B
                               INNER JOIN (SELECT A.CUST_ID,
                                                 SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL,
                                                 A.DATA_DATE,
                                                 A.ACCT_TYP,
                                                 A.ORG_NUM,
                                                 A.ACCT_NUM
                                            FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                                           WHERE A.ACCT_TYP NOT LIKE '90%'
                                             AND A.CANCEL_FLG <> 'Y'
                                             AND A.DATA_DATE = I_DATADATE
                                             AND A.ACCT_STS <> '3'
                                             AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                                                 ('130102', '130105') --m14  不含转贴现
                                             AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                                          --AND A.ORG_NUM NOT LIKE '5100%'
                                           GROUP BY A.CUST_ID,
                                                    A.DATA_DATE,
                                                    A.ACCT_TYP,
                                                    A.ORG_NUM,
                                                    A.ACCT_NUM) A
                                  ON A.ACCT_NUM = B.CONTRACT_NUM
                               WHERE B.DATA_DATE = I_DATADATE
                                 AND B.ACCT_STS = '1' --有效
                              ) LOAN
                        LEFT JOIN SMTMODS_L_CUST_C C
                          ON LOAN.CUST_ID = C.CUST_ID
                         AND C.DATA_DATE = I_DATADATE
                        LEFT JOIN SMTMODS_L_CUST_P LCP
                          ON LOAN.CUST_ID = LCP.CUST_ID
                         AND LCP.DATA_DATE = I_DATADATE) A
               WHERE A.LOAN_ACCT_BAL <> 0
              -----需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨    修改内容：客户授信逻辑
              UNION ALL
              SELECT CR.CUST_ID,
                     C.CORP_SCALE,
                     C.CUST_TYP,
                     CR.ORG_NUM,
                     CR.DATA_DATE,
                     '0102' ACCT_TYP,
                     P.OPERATE_CUST_TYPE
                FROM SMTMODS_L_AGRE_CREDITLINE CR
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON CR.DATA_DATE = C.DATA_DATE
                 AND CR.CUST_ID = C.CUST_ID
                LEFT JOIN SMTMODS_L_CUST_P P
                  ON CR.DATA_DATE = P.DATA_DATE
                 AND CR.CUST_ID = P.CUST_ID
               WHERE CR.DATA_DATE = I_DATADATE
                 AND CR.FACILITY_STS = 'Y'
                 AND (CR.FACILITY_BUSI_TYP = '10' OR
                     ((C.CUST_TYP = '3' OR P.CUST_ID IS NOT NULL) AND
                     CR.FACILITY_BUSI_TYP = '4'))
               GROUP BY CR.CUST_ID,
                        C.CORP_SCALE,
                        C.CUST_TYP,
                        CR.ORG_NUM,
                        CR.DATA_DATE,
                        P.OPERATE_CUST_TYPE

              ) TMP
        
        LEFT JOIN SMTMODS_L_CUST_ALL C
          ON TMP.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE --TMP.INLANDORRSHORE_FLG = 'Y' AND
       TMP.ACCT_TYP LIKE '0102%'
       AND TMP.DATA_DATE = I_DATADATE
       AND (TMP.OPERATE_CUST_TYPE IN ('A', 'B') OR TMP.CUST_TYP = '3')
       GROUP BY CASE /*WHEN SUBSTR(A.ORG_NUM,1,2) IN ('08','10','11','13') THEN SUBSTR(A.ORG_NUM,1,2)||'0000'*/ --20191012 LJP MODIFY 机构汇总数据缺失,先汇支行再汇分行
                  when TMP.ORG_NUM = '009813' then
                   '130000'
                  WHEN TMP.org_num LIKE '0601%' THEN
                   '060300'
                  when (SUBSTR(TMP.org_num, 3, 4) = '9801') or
                       SUBSTR(TMP.org_num, 1, 4) = '0098' or
                       (SUBSTR(TMP.org_num, 3, 2) = '98') then
                   TMP.org_num
                  ELSE
                   SUBSTR(TMP.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN (TMP.OPERATE_CUST_TYPE = 'A' OR TMP.CUST_TYP = '3') THEN
                   'S63_I_5.3.G.2014'
                  WHEN TMP.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_5.3.H.2014'
                END,
                TMP.CUST_ID,
                C.CUST_NAM,
                null
) q_76
INSERT INTO `S63_I_5.3.H.2014` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_5.3.G.2014` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- ========== 逻辑组 77: 共 3 个指标 ==========
FROM (
SELECT
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN T.GUARANTY_TYP LIKE 'D%' THEN
          'S63_I_1.2.1.F' --信用贷款
         WHEN T.GUARANTY_TYP LIKE 'C%' THEN
          'S63_I_1.2.2.F' --保证贷款
       --   WHEN T.GUARANTY_TYP IN ('A', 'B') THEN
       --20210923  ZHOUJINGKUN UPDATE 新信贷系统修改映射B01  B99
         WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
          'S63_I_1.2.3.F' --抵（质）押贷款
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(B.CUST_NAM, C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
         WHEN C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
          '个体工商户'
         WHEN C.OPERATE_CUST_TYPE = 'B' THEN
          '小微企业主'
         WHEN C.OPERATE_CUST_TYPE = 'Z' THEN
          '其他个人'
       end, -- 字段18（个人客户类型（个体工商户 小微企业主 其他个人））
       CASE
         WHEN T.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN T.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN T.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN T.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN T.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN T.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN T.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN T.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN T.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN T.GUARANTY_TYP = 'Z' THEN
          '其他'
       END COL_15 --贷款担保方式
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T

        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --经营性贷款
         AND T.LOAN_ACCT_BAL <> 0
         AND T.CANCEL_FLG <> 'Y'
         AND TT.FORWARD_CCY = 'CNY'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_77
INSERT INTO `S63_I_1.2.2.F` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.1.F` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18,  
       COL_15)
SELECT *
INSERT INTO `S63_I_1.2.3.F` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12,  
       COL_18,  
       COL_15)
SELECT *;

-- ========== 逻辑组 78: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       G.ORG_NUM,
       CASE
         WHEN G.CORP_SCALE = 'B' THEN
          'S63_I_7.3.A.2023'
         WHEN G.CORP_SCALE = 'M' THEN
          'S63_I_7.3.B.2023'
         WHEN G.CORP_SCALE = 'S' THEN
          'S63_I_7.3.C.2023'
         WHEN G.CORP_SCALE = 'T' THEN
          'S63_I_7.3.D.2023'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       G.CUST_ID AS COL_3, --客户号
       G.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null AS COL_10 --机构名称
        FROM (SELECT DISTINCT T.ORG_NUM, A.CUST_ID AS CUST_ID, CORP_SCALE,A.CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
                LEFT JOIN SMTMODS_L_CUST_C A
                  ON T.DATA_DATE = A.DATA_DATE
                 AND T.CUST_ID = A.CUST_ID
               WHERE T.DATA_DATE = I_DATADATE
                    -- AND T.LOAN_KIND_CD = '6' --借续贷
                    -- alter by  shiyu 230202 6无还本续贷,7 再融资
                 AND T.LOAN_KIND_CD in ('6', '7')
                 AND T.CANCEL_FLG <> 'Y'
                 AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
                 AND T.LOAN_ACCT_BAL <> 0 --ALTER BY WJB 20230202 计算户数的时候不要贷款余额等于0的
                 AND A.CUST_TYP NOT IN ('2', '4', '5')
                 AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
              ) G --政府机关、社会团体、事业单位
            
      GROUP BY G.ORG_NUM,CASE
         WHEN G.CORP_SCALE = 'B' THEN
          'S63_I_7.3.A.2023'
         WHEN G.CORP_SCALE = 'M' THEN
          'S63_I_7.3.B.2023'
         WHEN G.CORP_SCALE = 'S' THEN
          'S63_I_7.3.C.2023'
         WHEN G.CORP_SCALE = 'T' THEN
          'S63_I_7.3.D.2023'
       END,G.CUST_ID,G.CUST_NAM,null
) q_78
INSERT INTO `S63_I_7.3.B.2023` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_7.3.D.2023` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_7.3.C.2023` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- ========== 逻辑组 79: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       C.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_2.1.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_2.1.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）

        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 C ---取放款时所属机构
          ON T.LOAN_NUM = C.LOAN_NUM
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') OR B.CUST_TYP = '3')
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' or t.resched_flg is null) -- 累放取非重组
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_79
INSERT INTO `S63_I_2.1.H.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_2.1.G.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 80: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.OPERATE_CUST_TYPE in ('A', '3') THEN
                'S63_I_5.2.G.2022'
               WHEN A.OPERATE_CUST_TYPE = 'B' THEN
                'S63_I_5.2.H.2022'
             END AS ITEM_NUM,
            'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             A.cust_id AS COL_3, -- 字段3（客户号）
             C.CUST_NAM AS COL_4, -- 字段4（客户名称）
             1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
             null AS COL_10 --  字段10（机构名称）
        FROM CBRC_S6301_APPLY_P A
        LEFT JOIN SMTMODS_L_CUST_ALL C
            ON A.CUST_ID =C.CUST_ID
            AND C.DATA_DATE = I_DATADATE
        
       WHERE A.OPERATE_CUST_TYPE IN ('A', 'B', '3')
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.OPERATE_CUST_TYPE in ('A', '3') THEN
                   'S63_I_5.2.G.2022'
                  WHEN A.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_5.2.H.2022'
                END, A.cust_id,C.CUST_NAM,null
) q_80
INSERT INTO `S63_I_5.2.H.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_5.2.G.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- 指标: S63_I_9.1.F.2022
--9.1循环贷余额  个人经营性
    INSERT INTO `S63_I_9.1.F.2022`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_9.1.F.2022' AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 ,--  字段12（业务条线）
        CASE WHEN A.OPERATE_CUST_TYPE ='A' OR C.CUST_TYP ='3' THEN '个体工商户'
            WHEN A.OPERATE_CUST_TYPE ='B' THEN '小微企业主'
            WHEN A.OPERATE_CUST_TYPE ='Z' THEN '其他个人' end
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
           ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环 1是 0 否,贷款合同与借据保持一致
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- 指标: S63_I_5.3.F.2014
--modi by djh 20230828  法人综授,大为哥口径确定修改
    /*  自然人客户合同状态为‘有效’且贷款未结清的计1户
    */
    INSERT INTO `S63_I_5.3.F.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       --TMP.ORG_NUM,
       CASE /*WHEN SUBSTR(A.ORG_NUM,1,2) IN ('08','10','11','13') THEN SUBSTR(A.ORG_NUM,1,2)||'0000'*/ --20191012 LJP MODIFY 机构汇总数据缺失,先汇支行再汇分行
         when TMP.ORG_NUM = '009813' then
          '130000'
         WHEN TMP.org_num LIKE '0601%' THEN
          '060300'
         when (SUBSTR(TMP.org_num, 3, 4) = '9801') or
              SUBSTR(TMP.org_num, 1, 4) = '0098' or
              (SUBSTR(TMP.org_num, 3, 2) = '98')

          then
          TMP.org_num
         ELSE
          SUBSTR(TMP.ORG_NUM, 1, 4) || '00'
       END org_num,
       'S63_I_5.3.F.2014' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       TMP.CUST_ID AS COL_3, --客户号
       C.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null as COL_10 --机构名称
        FROM (SELECT A.CUST_ID,
                     A.CORP_SCALE,
                     --  A.INLANDORRSHORE_FLG,
                     A.CUST_TYP,
                     A.ORG_NUM,
                     A.DATA_DATE,
                     A.ACCT_TYP
                FROM (SELECT LOAN.CUST_ID,
                             LOAN.LOAN_ACCT_BAL,
                             LOAN.DATA_DATE,
                             LOAN.ACCT_TYP,
                             C.CORP_SCALE,
                             LOAN.ORG_NUM,
                             T.INLANDORRSHORE_FLG,
                             C.CUST_TYP
                        FROM (SELECT A.CUST_ID,
                                     A.LOAN_ACCT_BAL,
                                     A.DATA_DATE,
                                     A.ACCT_TYP,
                                     A.ORG_NUM
                                FROM SMTMODS_L_AGRE_LOAN_CONTRACT B
                               INNER JOIN (SELECT A.CUST_ID,
                                                 SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL,
                                                 A.DATA_DATE,
                                                 A.ACCT_TYP,
                                                 A.ORG_NUM,
                                                 A.ACCT_NUM
                                            FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                                           WHERE A.ACCT_TYP NOT LIKE '90%'
                                             AND A.CANCEL_FLG <> 'Y'
                                             AND A.DATA_DATE = I_DATADATE
                                             AND A.ACCT_STS <> '3'
                                             AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                                                 ('130102', '130105') --m14  不含转贴现
                                             AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                                          --AND A.ORG_NUM NOT LIKE '5100%'
                                           GROUP BY A.CUST_ID,
                                                    A.DATA_DATE,
                                                    A.ACCT_TYP,
                                                    A.ORG_NUM,
                                                    A.ACCT_NUM) A
                                  ON A.ACCT_NUM = B.CONTRACT_NUM
                               WHERE B.DATA_DATE = I_DATADATE
                                 AND B.ACCT_STS = '1' --有效

                              ) LOAN
                       INNER JOIN SMTMODS_L_CUST_ALL T
                          ON T.CUST_ID = LOAN.CUST_ID
                         AND T.DATA_DATE = I_DATADATE
                        LEFT JOIN SMTMODS_L_CUST_C C
                          ON T.CUST_ID = C.CUST_ID
                         AND C.DATA_DATE = I_DATADATE) A
               WHERE A.LOAN_ACCT_BAL <> 0
              -----需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨    修改内容：客户授信逻辑
              UNION ALL
              SELECT CR.CUST_ID,
                     C.CORP_SCALE,
                     C.CUST_TYP,
                     CR.ORG_NUM,
                     CR.DATA_DATE,
                     '0102' ACCT_TYP
                FROM SMTMODS_L_AGRE_CREDITLINE CR
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON CR.DATA_DATE = C.DATA_DATE
                 AND CR.CUST_ID = C.CUST_ID
                LEFT JOIN SMTMODS_L_CUST_P P
                  ON CR.DATA_DATE = P.DATA_DATE
                 AND CR.CUST_ID = P.CUST_ID
               WHERE CR.DATA_DATE = I_DATADATE
                 AND CR.FACILITY_STS = 'Y'
                 AND (CR.FACILITY_BUSI_TYP = '10' OR
                     ((C.CUST_TYP = '3' OR P.CUST_ID IS NOT NULL) AND
                     CR.FACILITY_BUSI_TYP = '4'))
               GROUP BY CR.CUST_ID,
                        C.CORP_SCALE,
                        C.CUST_TYP,
                        CR.ORG_NUM,
                        CR.DATA_DATE

              ) TMP
        
        LEFT JOIN SMTMODS_L_CUST_ALL C
          ON TMP.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE -- TMP.INLANDORRSHORE_FLG = 'Y' AND --M2
       TMP.ACCT_TYP LIKE '0102%'
       AND TMP.DATA_DATE = I_DATADATE
       GROUP BY CASE /*WHEN SUBSTR(A.ORG_NUM,1,2) IN ('08','10','11','13') THEN SUBSTR(A.ORG_NUM,1,2)||'0000'*/ --20191012 LJP MODIFY 机构汇总数据缺失,先汇支行再汇分行
                  when TMP.ORG_NUM = '009813' then
                   '130000'
                  WHEN TMP.org_num LIKE '0601%' THEN
                   '060300'
                  when (SUBSTR(TMP.org_num, 3, 4) = '9801') or
                       SUBSTR(TMP.org_num, 1, 4) = '0098' or
                       (SUBSTR(TMP.org_num, 3, 2) = '98') then
                   TMP.org_num
                  ELSE
                   SUBSTR(TMP.ORG_NUM, 1, 4) || '00'
                END,
                TMP.CUST_ID,
                C.CUST_NAM,
                null;


-- 指标: S63_I_5.1.H
INSERT INTO `S63_I_5.1.H`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'S63_I_5.1.H' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null as COL_10 --机构名称
        FROM (SELECT LOAN.CUST_ID,
                     LOAN.LOAN_ACCT_BAL,
                     LOAN.DATA_DATE,
                     LOAN.ACCT_TYP,

                     LCP.OPERATE_CUST_TYPE,
                     LOAN.ORG_NUM,
                     NVL(C.CUST_NAM, LCP.CUST_NAM) CUST_NAM
                FROM (SELECT A.CUST_ID,
                             A.LOAN_ACCT_BAL,
                             A.DATA_DATE,
                             A.ACCT_TYP,
                             A.ORG_NUM
                        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                       WHERE A.ACCT_TYP NOT LIKE '90%'
                         AND A.CANCEL_FLG <> 'Y'
                         AND A.DATA_DATE = I_DATADATE
                         AND A.ACCT_STS <> '3'
                         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                             ('130102', '130105') --m14  不含转贴现
                         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                      ) LOAN

                LEFT JOIN SMTMODS_L_CUST_C C
                  ON LOAN.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_CUST_P LCP
                  ON LOAN.CUST_ID = LCP.CUST_ID
                 AND LCP.DATA_DATE = I_DATADATE) A
       
       WHERE -- A.INLANDORRSHORE_FLG = 'Y' AND --M2
       A.OPERATE_CUST_TYPE = 'B'
       AND A.DATA_DATE = I_DATADATE
       AND A.LOAN_ACCT_BAL > 0
       AND A.ACCT_TYP LIKE '0102%'
       GROUP BY A.ORG_NUM, a.CUST_ID, a.CUST_NAM, null;


-- ========== 逻辑组 84: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_9.2.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_9.2.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             T.cust_id AS COL_3, -- 字段3（客户号）
             NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
             1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
             null AS COL_10 --  字段10（机构名称）

        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CUST_ID = B.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND T.LOAN_ACCT_BAL <> 0
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN
                   'S63_I_9.2.G.2022'
                  WHEN A.OPERATE_CUST_TYPE = 'B' THEN
                   'S63_I_9.2.H.2022'
                END,T.cust_id,NVL(A.CUST_NAM,B.CUST_NAM),null
) q_84
INSERT INTO `S63_I_9.2.H.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_9.2.G.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- ========== 逻辑组 85: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       --TMP.ORG_NUM,
       CASE /*WHEN SUBSTR(A.ORG_NUM,1,2) IN ('08','10','11','13') THEN SUBSTR(A.ORG_NUM,1,2)||'0000'*/ --20191012 LJP MODIFY 机构汇总数据缺失,先汇支行再汇分行
         when TMP.ORG_NUM = '009813' then
          '130000'
         WHEN TMP.org_num LIKE '0601%' THEN
          '060300'
         when (SUBSTR(TMP.org_num, 3, 4) = '9801') or
              SUBSTR(TMP.org_num, 1, 4) = '0098' or
              (SUBSTR(TMP.org_num, 3, 2) = '98') then
          TMP.org_num
         ELSE
          SUBSTR(TMP.ORG_NUM, 1, 4) || '00'
       END org_num,
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          'S63_I_5.3.A.2014'
         WHEN C.CORP_SCALE = 'M' THEN
          'S63_I_5.3.B.2014'
         WHEN C.CORP_SCALE = 'S' THEN
          'S63_I_5.3.C.2014'
         WHEN C.CORP_SCALE = 'T' THEN
          'S63_I_5.3.D.2014'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       TMP.CUST_ID AS COL_3, --客户号
       C.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null as COL_10 --机构名称

        FROM (SELECT T.ORG_NUM, T.CUST_ID
                FROM (SELECT T.ORG_NUM, T.CUST_ID
                        FROM SMTMODS_L_AGRE_CREDITLINE T
                       INNER JOIN SMTMODS_L_CUST_C C
                          ON T.CUST_ID = C.CUST_ID
                         AND C.DATA_DATE = I_DATADATE
                         AND UPPER(T.FACILITY_STS) = 'Y'
                         AND T.FACILITY_TYP IN ('2', '4', '1') ----需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨    修改内容：客户授信逻辑
                      --AND T.ORG_NUM NOT LIKE '5100%' --M10
                       WHERE T.DATA_DATE = I_DATADATE
                       GROUP BY T.ORG_NUM, T.CUST_ID
                      UNION ALL
                      SELECT T.ORG_NUM, T.CUST_ID
                        FROM SMTMODS_L_AGRE_CREDITLINE T
                       INNER JOIN (SELECT CUST_ID
                                    FROM (SELECT A1.CUST_ID
                                            FROM SMTMODS_L_ACCT_OBS_LOAN A1
                                           WHERE A1.BALANCE <> 0
                                             AND A1.DATA_DATE = I_DATADATE
                                           GROUP BY A1.CUST_ID
                                          UNION ALL
                                          SELECT A.CUST_ID
                                            FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                                           WHERE A.ACCT_TYP NOT LIKE '90%'
                                             AND A.DATA_DATE = I_DATADATE
                                             AND A.CANCEL_FLG <> 'Y'
                                             AND A.ACCT_STS <> '3'
                                             AND A.LOAN_ACCT_BAL <> 0
                                             AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                                                 ('130102', '130105') --m14  不含转贴现
                                             AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                                           GROUP BY A.CUST_ID)
                                   GROUP BY CUST_ID) T1
                          ON T1.CUST_ID = T.CUST_ID
                       WHERE T.DATA_DATE = I_DATADATE
                         AND UPPER(T.FACILITY_STS) = 'N'
                         AND T.FACILITY_TYP IN ('2', '4', '1') ----需求编号：JLBA202504160004_关于吉林银行修改单一客户授信逻辑的需求 提出人：苏桐  上线时间：20250627 修改人：石雨    修改内容：客户授信逻辑
                      --AND T.ORG_NUM NOT LIKE '5100%' --M10
                       GROUP BY T.ORG_NUM, T.CUST_ID
                      UNION ALL --补充客户授信与业务机构不属于同一家机构,该客户授信机构及业务机构都统计进来
                      SELECT ORG_NUM, CUST_ID
                        FROM (SELECT A1.ORG_NUM, A1.CUST_ID
                                FROM SMTMODS_L_ACCT_OBS_LOAN A1
                               WHERE A1.BALANCE <> 0
                                 AND A1.DATA_DATE = I_DATADATE
                               GROUP BY A1.ORG_NUM, A1.CUST_ID
                              UNION ALL
                              SELECT A.ORG_NUM, A.CUST_ID
                                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                               WHERE A.ACCT_TYP NOT LIKE '90%'
                                 AND A.DATA_DATE = I_DATADATE
                                 AND A.CANCEL_FLG <> 'Y'
                                 AND A.ACCT_STS <> '3'
                                 AND A.LOAN_ACCT_BAL <> 0
                                 AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                                     ('130102', '130105') --m14  不含转贴现
                                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                               GROUP BY A.ORG_NUM, A.CUST_ID)
                       GROUP BY ORG_NUM, CUST_ID) T
               GROUP BY T.ORG_NUM, T.CUST_ID) TMP

        LEFT JOIN SMTMODS_L_CUST_C C
          ON TMP.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        
       WHERE SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') --M4
         AND C.CORP_SCALE IN ('B', 'M', 'S', 'T')
       GROUP BY CASE /*WHEN SUBSTR(A.ORG_NUM,1,2) IN ('08','10','11','13') THEN SUBSTR(A.ORG_NUM,1,2)||'0000'*/ --20191012 LJP MODIFY 机构汇总数据缺失,先汇支行再汇分行
                  when TMP.ORG_NUM = '009813' then
                   '130000'
                  WHEN TMP.org_num LIKE '0601%' THEN
                   '060300'
                  when (SUBSTR(TMP.org_num, 3, 4) = '9801') or
                       SUBSTR(TMP.org_num, 1, 4) = '0098' or
                       (SUBSTR(TMP.org_num, 3, 2) = '98') then
                   TMP.org_num

                  ELSE
                   SUBSTR(TMP.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN C.CORP_SCALE = 'B' THEN
                   'S63_I_5.3.A.2014'
                  WHEN C.CORP_SCALE = 'M' THEN
                   'S63_I_5.3.B.2014'
                  WHEN C.CORP_SCALE = 'S' THEN
                   'S63_I_5.3.C.2014'
                  WHEN C.CORP_SCALE = 'T' THEN
                   'S63_I_5.3.D.2014'
                END,
                TMP.CUST_ID,
                C.CUST_NAM,
                null
) q_85
INSERT INTO `S63_I_5.3.D.2014` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_5.3.B.2014` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_5.3.A.2014` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_5.3.C.2014` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- 指标: S63_I_5.2.F.2022
INSERT INTO `S63_I_5.2.F.2022`
      (data_date, org_num, item_num, cust_id, OPERATE_CUST_TYPE)
      SELECT
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'S63_I_5.2.F.2022' AS ITEM_NUM,
       A.CUST_ID,
       NVL(P.OPERATE_CUST_TYPE, C.CUST_TYP)

        FROM SMTMODS_L_AGRE_LOAN_APPLY A
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT E
          ON A.ACCT_NUM = E.ACCT_NUM
         AND E.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ F
          ON E.CONTRACT_NUM = F.ACCT_NUM
         AND F.DATA_DATE = I_DATADATE
       WHERE A.ACCT_TYP LIKE '0102%'
            -- AND B.INLANDORRSHORE_FLG = 'Y'
         AND (SUBSTR(TO_CHAR(A.APPLY_DT, 'yyyymmdd'), 1, 4) =
             SUBSTR(I_DATADATE, 1, 4) --本年申请
             OR ( /*F.CIRCLE_LOAN_FLG = 'Y' \*循环贷款*\
                                                                                  AND*/
              SUBSTR(TO_CHAR(F.DRAWDOWN_DT, 'yyyymmdd'), 1, 4) =
              SUBSTR(I_DATADATE, 1, 4)) --本年发放
             AND SUBSTR(F.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
             )
         and A.APPLY_SYS = '2' --审批通过
         AND A.DATA_DATE = I_DATADATE
      union all
      SELECT I_DATADATE AS DATA_DATE,
             P.ORG_NUM,
             'S63_I_5.2.F.2022' AS ITEM_NUM,
             A.CUST_ID AS LOAN_ACCT_BAL_RMB,
             NVL(C.OPERATE_CUST_TYPE, B.CUST_TYP)
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN SMTMODS_L_CUST_C B --对公表 取小微企业
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 P
          ON A.LOAN_NUM = P.LOAN_NUM
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND A.ACCT_TYP LIKE '0102%'
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105')
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- 指标: S63_I_1.2.3.1.F.2022
-- 1.2.3.1新型抵质押类贷款 个人经营性

   INSERT INTO `S63_I_1.2.3.1.F.2022`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_1.2.3.1.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM)  AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE * g.zb)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE WHEN A.OPERATE_CUST_TYPE ='A' OR C.CUST_TYP ='3' THEN '个体工商户'
         WHEN A.OPERATE_CUST_TYPE ='B' THEN '小微企业主'
           WHEN A.OPERATE_CUST_TYPE ='Z'  THEN '其他个人' END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN CBRC_S6301_DATA_COLLECT_GUARANTEE G
          ON G.CONTRACT_NUM = T.ACCT_NUM
        left JOIN SMTMODS_L_CUST_P A ---- m17 20250327 shiyu 修改内容：分行反馈问题调整
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C
           ON T.DATA_DATE = c.DATA_DATE
         AND T.CUST_ID = c.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- ========== 逻辑组 88: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_6.2.1.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_6.2.1.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_6.2.1.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_6.2.1.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）

        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_STS <> '3'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND T.GUARANTY_TYP = 'D' --信用
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY I_DATADATE,
                T.ORG_NUM,
                CASE
                  WHEN A.CORP_SCALE = 'B' THEN
                   'S63_I_6.2.1.1.A.2022'
                  WHEN A.CORP_SCALE = 'M' THEN
                   'S63_I_6.2.1.1.B.2022'
                  WHEN A.CORP_SCALE = 'S' THEN
                   'S63_I_6.2.1.1.C.2022'
                  WHEN A.CORP_SCALE = 'T' THEN
                   'S63_I_6.2.1.1.D.2022'
                END,T.CUST_ID,A.CUST_NAM, null
) q_88
INSERT INTO `S63_I_6.2.1.1.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *
INSERT INTO `S63_I_6.2.1.1.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_10)
SELECT *;

-- 指标: S63_I_1.4.G
INSERT INTO `S63_I_1.4.G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）

       )
    --   1.4中长期贷款

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'S63_I_1.4.G' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(B.CUST_NAM, c.cust_nam) AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改,从此视图取。
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.ACCT_TYP LIKE '0102%'
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (C.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3')
            --AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现;


-- 指标: S63_I_5.1.G
INSERT INTO `S63_I_5.1.G`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'S63_I_5.1.G' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null as COL_10 --机构名称
        FROM (SELECT LOAN.CUST_ID,
                     LOAN.LOAN_ACCT_BAL,
                     LOAN.DATA_DATE,
                     LOAN.ACCT_TYP,
                     LCP.OPERATE_CUST_TYPE,
                     C.CUST_TYP,
                     LOAN.ORG_NUM,
                     NVL(C.CUST_NAM, LCP.CUST_NAM) CUST_NAM
                FROM (SELECT A.CUST_ID,
                             A.LOAN_ACCT_BAL,
                             A.DATA_DATE,
                             A.ACCT_TYP,
                             A.ORG_NUM
                        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
                       WHERE A.ACCT_TYP NOT LIKE '90%'
                         AND A.CANCEL_FLG <> 'Y'
                         AND A.DATA_DATE = I_DATADATE
                         AND A.ACCT_STS <> '3'
                         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN
                             ('130102', '130105') --m14  不含转贴现
                         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
                      ) LOAN
                LEFT JOIN SMTMODS_L_CUST_C C
                  ON LOAN.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_CUST_P LCP
                  ON LOAN.CUST_ID = LCP.CUST_ID
                 AND LCP.DATA_DATE = I_DATADATE) A
       
       WHERE -- A.INLANDORRSHORE_FLG = 'Y' AND --M2
       (A.OPERATE_CUST_TYPE = 'A' OR A.CUST_TYP = '3')
       AND A.DATA_DATE = I_DATADATE
       AND A.LOAN_ACCT_BAL > 0
       AND A.ACCT_TYP LIKE '0102%'
       GROUP BY A.ORG_NUM, a.CUST_ID, a.CUST_NAM, null;


-- 指标: S63_I_5.1.F
--ZHOUJINGKUN UPDATE 20210329   松原分行提升个人经验性贷款户数不准确

    INSERT INTO `S63_I_5.1.F`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )

      SELECT I_DATADATE AS DATA_DATE,
             B.ORG_NUM,
             'S63_I_5.1.F' AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             B.CUST_ID AS COL_3, --客户号
             B.CUST_NAM AS COL_4, --客户名称
             1 AS COL_5, --贷款余额/客户数/放款金额
             null as COL_10 --机构名称
        FROM (

              SELECT

               A.ORG_NUM, C.CUST_ID, C.CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
               INNER JOIN SMTMODS_L_CUST_ALL C
                  ON A.DATA_DATE = C.DATA_DATE
                 AND A.CUST_ID = C.CUST_ID
               WHERE A.ACCT_TYP LIKE '0102%' --个人经营性标识
                 AND A.DATA_DATE = I_DATADATE
                 AND A.CANCEL_FLG <> 'Y'
                 AND A.LOAN_ACCT_BAL > 0 --20211102 LXA ADD 和大为哥确认只取贷款余额大于0的户数
                 AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
               GROUP BY A.ORG_NUM, C.CUST_ID, C.CUST_NAM) B
       
       GROUP BY B.ORG_NUM, B.CUST_ID, B.CUST_NAM, null;


-- 指标: S63_I_1.2.2.1.E.2021
--1.2.2.1政府性融资担保公司保证贷款  个人经营性
    INSERT INTO `S63_I_1.2.2.1.E.2021`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_1.2.2.1.E.2021' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM)  AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * U.CCY_RATE)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE WHEN A.OPERATE_CUST_TYPE ='A' OR C.CUST_TYP ='3' THEN '个体工商户'
         WHEN A.OPERATE_CUST_TYPE ='B' THEN '小微企业主'
           WHEN A.OPERATE_CUST_TYPE ='Z'  THEN '其他个人' END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        left JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
       INNER JOIN (SELECT
                 
                   DISTINCT B.CONTRACT_NUM --贷款合同号
                     FROM SMTMODS_L_AGRE_GUARANTEE_RELATION F1 --担保合同与担保信息对应关系表
                     LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT F --担保合同表
                       ON F.GUAR_CONTRACT_NUM = F1.GUAR_CONTRACT_NUM
                      AND F.DATA_DATE = I_DATADATE
                     LEFT JOIN SMTMODS_L_AGRE_GUA_RELATION E --业务合同与担保合同对应关系表 E
                       ON E.GUAR_CONTRACT_NUM = F.GUAR_CONTRACT_NUM
                      AND E.DATA_DATE = I_DATADATE
                     LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT B --贷款合同信息表 B
                       ON B.CONTRACT_NUM = E.CONTRACT_NUM
                      AND B.DATA_DATE = I_DATADATE
                    INNER JOIN CBRC_FINANCE_COMPANY_LIST L
                       ON TRIM(F1.GUARANTEE_NAME) = TRIM(L.COMPANY_NAME)
                    WHERE F1.DATA_DATE = I_DATADATE
                      AND F.GUAR_CONTRACT_STATUS = 'Y' --担保合同有效状态
                      AND B.ACCT_STS = '1' --合同状态：1有效
                      and L.GOV_FLG = 'Y' --政府性融资担保公司
                   ) T1
          ON T1.CONTRACT_NUM = T.ACCT_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.cust_id =C.CUST_ID
          AND C.DATA_DATE = I_DATADATE
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND T.ACCT_STS <> '3'
         AND T.GUARANTY_TYP LIKE 'C%' --担保方式：保证
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- ========== 逻辑组 93: 共 4 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_9.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_9.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_9.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_9.1.D.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * TT.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12--  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环  1是 0 否,贷款合同与借据保持一致
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_93
INSERT INTO `S63_I_9.1.B.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_9.1.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_9.1.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_9.1.A.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- ========== 逻辑组 94: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       TT1.ORG_NUM,
       CASE
         WHEN A.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3' THEN --其中：个体工商户贷款
          'S63_I_2.2.G.2022'
         WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
          'S63_I_2.2.H.2022'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
      (T.DRAWDOWN_AMT * U.CCY_RATE * TT1.REAL_INT_RAT / 100) AS COL_5, --放款金额*实际利率[执行利率(年)]/100
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S6301_AMT_TMP1 TT1 ---M7取放款时实际利率
          ON T.LOAN_NUM = TT1.LOAN_NUM
       
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) --当年
         AND (T.RESCHED_FLG = 'N' or t.RESCHED_FLG is null) -- 累放取非重组
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') OR C.CUST_TYP = '3')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_94
INSERT INTO `S63_I_2.2.G.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_2.2.H.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- 指标: S63_I_7.3.F.2023
-- 7.3无还本续贷贷款余额户数  个人经营性
     INSERT INTO `S63_I_7.3.F.2023`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       COL_3, --客户号
       COL_4, --客户名称
       COL_5, --贷款余额/客户数/放款金额
       COL_10 --机构名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       G.ORG_NUM,
       'S63_I_7.3.F.2023' AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       G.CUST_ID AS COL_3, --客户号
       G.CUST_NAM AS COL_4, --客户名称
       1 AS COL_5, --贷款余额/客户数/放款金额
       null AS COL_10 --机构名称
        FROM (SELECT DISTINCT T.ORG_NUM, T.CUST_ID,NVL(A.CUST_NAM ,B.CUST_NAM) CUST_NAM
                FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
                LEFT JOIN SMTMODS_L_CUST_P A
                  ON T.DATA_DATE = A.DATA_DATE
                 AND T.CUST_ID = A.CUST_ID
                LEFT JOIN SMTMODS_L_CUST_C B
                 ON T.DATA_DATE = B.DATA_DATE
                 AND T.CUST_ID = B.CUST_ID
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.ACCT_TYP LIKE '0102%' --个人经营性
                 AND T.CANCEL_FLG <> 'Y'
                    --AND T.LOAN_KIND_CD = '6' --借续贷
                    -- alter by  shiyu 230202 6无还本续贷,7 再融资
                 AND T.LOAN_KIND_CD in ('6', '7')
                 AND T.LOAN_ACCT_BAL <> 0 --ALTER BY WJB 20230202 计算户数的时候不要贷款余额等于0的
                 AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
                 AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
              ) G
             
       GROUP BY G.ORG_NUM,G.CUST_ID,G.CUST_NAM,null;


-- ========== 逻辑组 96: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       t.ORG_NUM,
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          'S63_I_6.1.A.2022'
         WHEN A.CORP_SCALE = 'M' THEN
          'S63_I_6.1.B.2022'
         WHEN A.CORP_SCALE = 'S' THEN
          'S63_I_6.1.C.2022'
         WHEN A.CORP_SCALE = 'T' THEN
          'S63_I_6.1.D.2022'
       END AS ITEM_NUM,
        'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       T.ACCT_NUM AS COL_1, -- 字段1（合同号）
       T.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       T.CUST_ID AS COL_3, -- 字段3（客户号）
       A.CUST_NAM AS COL_4, -- 字段4（客户名称）
      (T.LOAN_ACCT_BAL * TT.CCY_RATE)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       T.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       T.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       T.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       T.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       T.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
       INNER JOIN SMTMODS_L_CUST_C A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYP LIKE '1%'
         AND substr(A.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_ACCT_BAL <> 0
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND T.TAX_RELATED_FLG = 'Y' -- 银税合作贷款标志
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_96
INSERT INTO `S63_I_6.1.D.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *
INSERT INTO `S63_I_6.1.C.2022` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       SYS_NAM,  
       REP_NUM,  
       COL_1,  
       COL_2,  
       COL_3,  
       COL_4,  
       COL_5,  
       COL_6,  
       COL_7,  
       COL_9,  
       COL_10,  
       COL_22,  
       COL_11,  
       COL_12)
SELECT *;

-- 指标: S63_I_1.4.H
INSERT INTO `S63_I_1.4.H`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）

       )
    --   1.4中长期贷款

      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'S63_I_1.4.H' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       c.cust_nam AS COL_4, -- 字段4（客户名称）
       (A.LOAN_ACCT_BAL * U.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改,从此视图取。
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP LIKE '0102%'
         AND C.OPERATE_CUST_TYPE = 'B'
            --  AND T.INLANDORRSHORE_FLG = 'Y' --m2
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现;


-- 指标: S63_I_5.1.F.2022
--   5.1贷款当年累计发放贷款户数 --个人经营性
     INSERT INTO `S63_I_5.1.F.2022`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT I_DATADATE AS DATA_DATE,
             P.ORG_NUM,
             'S63_I_5.1.F.2022' AS ITEM_NUM,
              'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.cust_id AS COL_3, -- 字段3（客户号）
       NVL(B.CUST_NAM,C.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
        LEFT JOIN SMTMODS_L_CUST_C B --对公表 取小微企业
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S6301_AMT_TMP1 P
          ON A.LOAN_NUM = P.LOAN_NUM
        
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND A.CANCEL_FLG <> 'Y'
         AND (A.RESCHED_FLG = 'N' OR A.RESCHED_FLG IS NULL) ---累放不取贷款重组 SHIYU 20220210  新口径吴大为
         AND SUBSTR(TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD'), 1, 4) = ---取当年
             SUBSTR(I_DATADATE, 1, 4)
         AND A.ACCT_TYP LIKE '0102%'
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
      --AND ( C.OPERATE_CUST_TYPE IN ('A','B') OR B.CUST_TYP ='3')
       GROUP BY P.ORG_NUM,A.cust_id,NVL(B.CUST_NAM,C.CUST_NAM),null;


-- 指标: S63_I_10.1.3.C.2025
--10.1.3“专精特新”中小企业不良贷款余额
    INSERT INTO `S63_I_10.1.3.C.2025`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       CASE
         WHEN B.CORP_SCALE = 'B' THEN
          'S63_I_10.1.3.A.2025'
         WHEN B.CORP_SCALE = 'M' THEN
          'S63_I_10.1.3.B.2025'
         WHEN B.CORP_SCALE = 'S' THEN
          'S63_I_10.1.3.C.2025'
         WHEN B.CORP_SCALE = 'T' THEN
          'S63_I_10.1.3.D.2025'
       END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       A.ACCT_NUM AS COL_1, -- 字段1（合同号）
       A.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       A.CUST_ID AS COL_3, -- 字段3（客户号）
       B.CUST_NAM AS COL_4, -- 字段4（客户名称）
       (NVL(A.LOAN_ACCT_BAL, 0) * U.CCY_RATE) +
       (NVL(A.INT_ADJEST_AMT, 0) * U.CCY_RATE)  AS COL_5,  -- m17 20250327 shiyu 修改内容：分行反馈五级分类转贴现部分未取到数据INT_ADJEST_AMT有空值,改成nvl(INT_ADJEST_AMT,0)。
        -- 字段5（贷款余额/客户数/放款金额/收益）
       A.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       A.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       A.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       A.CP_NAME AS COL_22, --  字段22（贷款产品名称）
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
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         
      --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM S7001_CUST_TEMP
                 where  CUST_TYPE like '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(B.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND A.ACCT_STS <> '3'
         AND substr(B.CUST_TYP, 1, 1) in ('1', '0') --M4
         AND A.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND B.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29,修改人：石雨,提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --and P.CUST_NAME IS NOT NULL
         AND B.IF_SPCLED_NEW_CUST = '1' --是否专精特新客户 1是
         AND SUBSTR(A.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND A.LOAN_GRADE_CD IN ('3', '4', '5');


