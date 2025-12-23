-- ============================================================
-- 文件名: S71_III银行业普惠金融重点领域贷款情况表.sql
-- 生成时间: 2025-12-18 13:53:41
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.C2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.C1'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.3.C3.2025'
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
               /*ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
                  ON A.DATA_DATE = F.DATA_DATE
                 AND A.LOAN_NUM = F.LOAN_NUM
                 --AND F.AGREI_P_FLG = 'Y'
                 and F.SNDKFL = 'P_102'
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
                 --AND T.FACILITY_AMT <= 100000
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
               WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.C2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.C1'
               WHEN C.FACILITY_AMT > 100000 THEN
                'S7103_1.3.C3.2025'
                END
) q_0
INSERT INTO `S7103_1.3.C2` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `S7103_1.3.C3.2025` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 1: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000  and C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.B2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.B1'
                WHEN C.FACILITY_AMT > 100000 then
                  'S7103_1.3.B3.2025'    --20250318  2025年制度升级
             END AS ITEM_NUM, --指标号
             COUNT(1) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充  --20250318  2025年制度升级
               /*ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
                  ON A.DATA_DATE = F.DATA_DATE
                 AND A.LOAN_NUM = F.LOAN_NUM
                -- AND F.AGREI_P_FLG = 'Y'
                  and F.SNDKFL = 'P_102'
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.LOAN_ACCT_BAL > 0
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
                 --AND T.FACILITY_AMT <= 100000 ----20250318  2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
                  WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000 THEN
                   'S7103_1.3.B2'
                  WHEN C.FACILITY_AMT <= 10000 THEN
                   'S7103_1.3.B1'
                  WHEN C.FACILITY_AMT > 100000 then
                  'S7103_1.3.B3.2025'
                END
) q_1
INSERT INTO `S7103_1.3.B3.2025` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `S7103_1.3.B1` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `S7103_1.3.B2` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 2: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 and  c.FACILITY_AMT <= 100000 THEN
                'S7103_1.A2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.A1'
               when C.FACILITY_AMT > 100000 then   --20250318 2025年制度升级
                'S7103_1.A3.2025'
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
                -- AND T.FACILITY_AMT <= 100000  --20250318 2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
                  WHEN C.FACILITY_AMT > 10000 and c.FACILITY_AMT <= 100000 THEN
                   'S7103_1.A2'
                  WHEN C.FACILITY_AMT <= 10000 THEN
                   'S7103_1.A1'
                  when C.FACILITY_AMT > 100000 then   --20250318 2025年制度升级
                'S7103_1.A3.2025'
                END
) q_2
INSERT INTO `S7103_1.A3.2025` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `S7103_1.A1` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `S7103_1.A2` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- 指标: S7103_1.3.B
--合计 贷款余额户数

    INSERT INTO `S7103_1.3.B` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             'S7103_1.3.B' AS ITEM_NUM, --指标号
             COUNT(1) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充  --20250318  2025年制度升级
              -- ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生
                  ON A.DATA_DATE = F.DATA_DATE
                 AND A.LOAN_NUM = F.LOAN_NUM
                 --AND F.AGREI_P_FLG = 'Y'
                 and F.SNDKFL = 'P_102'
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.LOAN_ACCT_BAL > 0
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
               --  AND T.FACILITY_AMT <= 100000  --20250318  2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM;


-- ========== 逻辑组 4: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                'S7103_1.C2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.C1'
                WHEN C.FACILITY_AMT > 100000 THEN
                 'S7103_1.C3.2025'     --20250318 2025制度升级
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
                 --AND T.FACILITY_AMT <= 100000  --20250318 2025制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
                  WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                   'S7103_1.C2'
                  WHEN C.FACILITY_AMT <= 10000 THEN
                   'S7103_1.C1'
                   WHEN C.FACILITY_AMT > 100000 THEN
                 'S7103_1.C3.2025'     --20250318 2025制度升级
                END
) q_4
INSERT INTO `S7103_1.C3.2025` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `S7103_1.C2` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `S7103_1.C1` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 5: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
               ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'S7103' AS REP_NUM, --报表编号
               CASE
                 WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                  'S7103_1.F2'
                 WHEN C.FACILITY_AMT <= 10000 THEN
                  'S7103_1.F1'
                 WHEN C.FACILITY_AMT > 100000 THEN
                  'S7103_1.F3.2025'      --20250318 2025年制度升级
               END AS ITEM_NUM, --指标号
               SUM(NHSY) AS ITEM_VAL, --指标值（数值型）
               '2' --标志位
          FROM (SELECT 
                 ORG_NUM        AS ORG_NUM, --机构号
                 T.CUST_ID, --客户号
                 T.FACILITY_AMT FACILITY_AMT, --授信金额
                 T.DRAWDOWN_AMT, --放款金额
                 T.NHSY --年化收益
                  FROM CBRC_S7103_TEMP2 T) C
         GROUP BY ORG_NUM,
                  CASE
                    WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                     'S7103_1.F2'
                    WHEN C.FACILITY_AMT <= 10000 THEN
                     'S7103_1.F1'
                    WHEN C.FACILITY_AMT > 100000 THEN
                     'S7103_1.F3.2025'
                  END
) q_5
INSERT INTO `S7103_1.F1` (DATA_DATE,  
         ORG_NUM,  
         SYS_NAM,  
         REP_NUM,  
         ITEM_NUM,  
         ITEM_VAL,  
         FLAG)
SELECT *
INSERT INTO `S7103_1.F2` (DATA_DATE,  
         ORG_NUM,  
         SYS_NAM,  
         REP_NUM,  
         ITEM_NUM,  
         ITEM_VAL,  
         FLAG)
SELECT *
INSERT INTO `S7103_1.F3.2025` (DATA_DATE,  
         ORG_NUM,  
         SYS_NAM,  
         REP_NUM,  
         ITEM_NUM,  
         ITEM_VAL,  
         FLAG)
SELECT *;

-- ========== 逻辑组 6: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
               ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'S7103' AS REP_NUM, --报表编号
               CASE
                 WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000 THEN
                  'S7103_1.D2'
                 WHEN C.FACILITY_AMT <= 10000 THEN
                  'S7103_1.D1'
                 WHEN C.FACILITY_AMT > 100000  THEN
                  'S7103_1.D3.2025'  --20250318 2025年制度升级
               END AS ITEM_NUM, --指标号
               SUM(DRAWDOWN_AMT) AS ITEM_VAL, --指标值（数值型）
               '2' --标志位
          FROM (SELECT 
                 ORG_NUM        AS ORG_NUM, --机构号
                 T.CUST_ID, --客户号
                 T.FACILITY_AMT FACILITY_AMT, --授信金额
                 T.DRAWDOWN_AMT --放款金额
                  FROM CBRC_S7103_TEMP2 T) C
         GROUP BY ORG_NUM,
                  CASE
                    WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000  THEN
                     'S7103_1.D2'
                    WHEN C.FACILITY_AMT <= 10000 THEN
                     'S7103_1.D1'
                    WHEN C.FACILITY_AMT > 100000  THEN
                     'S7103_1.D3.2025'
                  END
) q_6
INSERT INTO `S7103_1.D2` (DATA_DATE,  
         ORG_NUM,  
         SYS_NAM,  
         REP_NUM,  
         ITEM_NUM,  
         ITEM_VAL,  
         FLAG)
SELECT *
INSERT INTO `S7103_1.D1` (DATA_DATE,  
         ORG_NUM,  
         SYS_NAM,  
         REP_NUM,  
         ITEM_NUM,  
         ITEM_VAL,  
         FLAG)
SELECT *
INSERT INTO `S7103_1.D3.2025` (DATA_DATE,  
         ORG_NUM,  
         SYS_NAM,  
         REP_NUM,  
         ITEM_NUM,  
         ITEM_VAL,  
         FLAG)
SELECT *;

-- ========== 逻辑组 7: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 AND c.FACILITY_AMT <= 100000  THEN
                'S7103_1.B2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.B1'
               when C.FACILITY_AMT > 100000 then
                'S7103_1.B3.2025'  --20250318 制度升级
             END AS ITEM_NUM, --指标号
             COUNT(1) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.LOAN_ACCT_BAL > 0
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
                 -- AND T.FACILITY_AMT <= 100000  --20250318 2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
                  WHEN C.FACILITY_AMT > 10000 AND c.FACILITY_AMT <= 100000 THEN
                   'S7103_1.B2'
                  WHEN C.FACILITY_AMT <= 10000 THEN
                   'S7103_1.B1'
                  when C.FACILITY_AMT > 100000 then
                   'S7103_1.B3.2025'  --20250318 2025制度升级
                END
) q_7
INSERT INTO `S7103_1.B1` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `S7103_1.B3.2025` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `S7103_1.B2` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- 指标: S7103_1.3.A
-------------------------------  1.3其中：普惠型农户消费贷款------------------------------------------
    --合计
    --合计 贷款余额
    INSERT INTO `S7103_1.3.A` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             'S7103_1.3.A' AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充 --20250318  2025年制度升级
              -- ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生
                  ON A.DATA_DATE = F.DATA_DATE
                 AND A.LOAN_NUM = F.LOAN_NUM
                -- AND F.AGREI_P_FLG = 'Y'
                 and F.SNDKFL = 'P_102'
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
                -- AND T.FACILITY_AMT <= 100000  --20250318  2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM;


-- 指标: S7103_1.3.C
--合计  不良贷款余额
    INSERT INTO `S7103_1.3.C` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             'S7103_1.3.C' AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充  --20250318  2025年制度升级
              /* ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
                  ON A.DATA_DATE = F.DATA_DATE
                 AND A.LOAN_NUM = F.LOAN_NUM
                 --AND F.AGREI_P_FLG = 'Y'
                 and F.SNDKFL = 'P_102'
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
                 --AND T.FACILITY_AMT <= 100000  --20250318  2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM;


-- 指标: S7103_1.3.F
--合计 当年累放贷款年化收益
    
      INSERT INTO `S7103_1.3.F` 
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值（数值型）
         FLAG --标志位
         )
        SELECT I_DATADATE, --数据日期
               ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'S7103' AS REP_NUM, --报表编号
               'S7103_1.3.F' AS ITEM_NUM, --指标号
               SUM(NHSY) AS ITEM_VAL, --指标值（数值型）
               '2' --标志位
          FROM (SELECT 
                 ORG_NUM        AS ORG_NUM, --机构号
                 T.CUST_ID, --客户号
                 T.FACILITY_AMT FACILITY_AMT, --授信金额
                 T.DRAWDOWN_AMT, --放款金额
                 T.NHSY --年化收益
                  FROM CBRC_S7103_TEMP2 T
                 INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
                -- ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生
                    ON F.DATA_DATE = I_DATADATE
                   AND T.LOAN_NUM = F.LOAN_NUM
                 --  AND F.AGREI_P_FLG = 'Y'
                   AND F.SNDKFL = 'P_102'
                   ) C
         GROUP BY ORG_NUM;


-- ========== 逻辑组 11: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
               ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'S7103' AS REP_NUM, --报表编号
               CASE
                 WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000 THEN
                  'S7103_1.E2'
                 WHEN C.FACILITY_AMT <= 10000 THEN
                  'S7103_1.E1'
                 WHEN C.FACILITY_AMT > 100000 THEN
                  'S7103_1.E3.2025'    --20250318 2025年制度升级
               END AS ITEM_NUM, --指标号
               COUNT(DISTINCT CUST_ID) AS ITEM_VAL, --指标值（数值型）
               '2' --标志位
          FROM (SELECT 
                 ORG_NUM        AS ORG_NUM, --机构号
                 T.CUST_ID, --客户号
                 T.FACILITY_AMT FACILITY_AMT, --授信金额
                 T.DRAWDOWN_AMT --放款金额
                  FROM CBRC_S7103_TEMP2 T) C
         GROUP BY ORG_NUM,
                  CASE
                    WHEN C.FACILITY_AMT > 10000 and C.FACILITY_AMT <= 100000 THEN
                     'S7103_1.E2'
                    WHEN C.FACILITY_AMT <= 10000 THEN
                     'S7103_1.E1'
                    WHEN C.FACILITY_AMT > 100000 THEN
                     'S7103_1.E3.2025'
                  END
) q_11
INSERT INTO `S7103_1.E2` (DATA_DATE,  
         ORG_NUM,  
         SYS_NAM,  
         REP_NUM,  
         ITEM_NUM,  
         ITEM_VAL,  
         FLAG)
SELECT *
INSERT INTO `S7103_1.E1` (DATA_DATE,  
         ORG_NUM,  
         SYS_NAM,  
         REP_NUM,  
         ITEM_NUM,  
         ITEM_VAL,  
         FLAG)
SELECT *
INSERT INTO `S7103_1.E3.2025` (DATA_DATE,  
         ORG_NUM,  
         SYS_NAM,  
         REP_NUM,  
         ITEM_NUM,  
         ITEM_VAL,  
         FLAG)
SELECT *;

-- ========== 逻辑组 12: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7103' AS REP_NUM, --报表编号
             CASE
               WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                'S7103_1.3.A2'
               WHEN C.FACILITY_AMT <= 10000 THEN
                'S7103_1.3.A1'
               WHEN  C.FACILITY_AMT > 100000 THEN
                'S7103_1.3.A3.2025'   --20250318  2025年制度升级
             END AS ITEM_NUM, --指标号
             SUM(LOAN_ACCT_BAL) AS ITEM_VAL, --指标值（数值型）
             '2' --标志位
        FROM (SELECT 
               ORG_NUM AS ORG_NUM, --机构号
               T.CUST_ID, --客户号
               MAX(T.FACILITY_AMT) FACILITY_AMT, --授信金额
               SUM(A.LOAN_ACCT_BAL) LOAN_ACCT_BAL --余额
                FROM CBRC_L_AGRE_CREDITLINE_TEST_7103 T
               INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
                  ON T.CUST_ID = A.CUST_ID
                 AND A.DATA_DATE = I_DATADATE
               INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充   --20250318  2025年制度升级
               /*ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
                  ON A.DATA_DATE = F.DATA_DATE
                 AND A.LOAN_NUM = F.LOAN_NUM
               --  AND F.AGREI_P_FLG = 'Y'
                and F.SNDKFL = 'P_102'
               WHERE (SUBSTR(A.ACCT_TYP, 1, 4) IN ('0199', '0103', '0104') OR
                     A.ACCT_TYP = '010199') --0103 个人消费贷款  0199 其他--ADD BY YHY 20211221 0104 个人助学贷款 010199 其他个人住房贷款
                 AND A.ACCT_TYP NOT LIKE '010301'
                 AND (A.LOAN_PURPOSE_CD IS NULL OR
                     A.LOAN_PURPOSE_CD NOT LIKE 'K%') --HMC 210720 消费贷款不含房地产贷款和汽车贷款
                 AND REGEXP_LIKE(A.ITEM_CD, '^(1305|1303)') ---1305贸易融资  1303贷款
                 AND A.DATA_DATE = I_DATADATE
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
                -- AND T.FACILITY_AMT <= 100000   --20250318  2025年制度升级
               GROUP BY A.ORG_NUM, T.CUST_ID) C
       GROUP BY ORG_NUM,
                CASE
                  WHEN C.FACILITY_AMT > 10000 AND C.FACILITY_AMT <= 100000 THEN
                   'S7103_1.3.A2'
                  WHEN C.FACILITY_AMT <= 10000 THEN
                   'S7103_1.3.A1'
                  WHEN  C.FACILITY_AMT > 100000 THEN
                   'S7103_1.3.A3.2025'
                END
) q_12
INSERT INTO `S7103_1.3.A2` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `S7103_1.3.A1` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `S7103_1.3.A3.2025` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- 指标: S7103_1.3.E
--合计 当年累放贷款户数

    
      INSERT INTO `S7103_1.3.E` 
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值（数值型）
         FLAG --标志位
         )
        SELECT I_DATADATE, --数据日期
               ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'S7103' AS REP_NUM, --报表编号
               'S7103_1.3.E' AS ITEM_NUM, --指标号
               COUNT(DISTINCT CUST_ID) AS ITEM_VAL, --指标值（数值型）
               '2' --标志位
          FROM (SELECT 
                 ORG_NUM        AS ORG_NUM, --机构号
                 T.CUST_ID, --客户号
                 T.FACILITY_AMT FACILITY_AMT, --授信金额
                 T.DRAWDOWN_AMT --放款金额
                  FROM CBRC_S7103_TEMP2 T
                 INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
                -- ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生
                    ON F.DATA_DATE = I_DATADATE
                   AND T.LOAN_NUM = F.LOAN_NUM
                   --AND F.AGREI_P_FLG = 'Y'
                    AND F.SNDKFL = 'P_102'
                   ) C
         GROUP BY ORG_NUM;


-- 指标: S7103_1.3.D
--合计 当年累放贷款额

    
      INSERT INTO `S7103_1.3.D` 
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值（数值型）
         FLAG --标志位
         )
        SELECT I_DATADATE, --数据日期
               ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'S7103' AS REP_NUM, --报表编号
               'S7103_1.3.D' AS ITEM_NUM, --指标号
               SUM(DRAWDOWN_AMT) AS ITEM_VAL, --指标值（数值型）
               '2' --标志位
          FROM (SELECT 
                 ORG_NUM        AS ORG_NUM, --机构号
                 T.CUST_ID, --客户号
                 T.FACILITY_AMT FACILITY_AMT, --授信金额
                 T.DRAWDOWN_AMT --放款金额
                  FROM CBRC_S7103_TEMP2 T
                 INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F --涉农贷款补充
                -- ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生
                    ON F.DATA_DATE = I_DATADATE
                   AND T.LOAN_NUM = F.LOAN_NUM
                  -- AND F.AGREI_P_FLG = 'Y'
                    AND F.SNDKFL = 'P_102'
                   ) C
         GROUP BY ORG_NUM;


