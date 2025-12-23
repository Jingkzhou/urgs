-- ============================================================
-- 文件名: G05_I个人贷款情况统计表.sql
-- 生成时间: 2025-12-18 13:53:37
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 5 个指标 ==========
FROM (
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
                END
) q_0
INSERT INTO `G05_I_1.1.2.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.5.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.4.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.3.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.7.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- 指标: G05_I_2..B
/*按月分期还款的个人消费贷款，发生逾期的填报方法为：逾期90天以内的，按照已逾期部分的本金的余额填报，
    逾期91天及以上的，按照整笔贷款本金的余额填报*/
    INSERT 
    INTO `G05_I_2..B` 
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

--信用卡数据插入

    INSERT 
    INTO `G05_I_2..B` 
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


-- ========== 逻辑组 2: 共 5 个指标 ==========
FROM (
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
                END
) q_2
INSERT INTO `G05_I_1.1.5.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.7.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.3.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.2.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.4.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 3: 共 3 个指标 ==========
FROM (
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
                END
) q_3
INSERT INTO `G05_I_1.5.3.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.5.1.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.5.2.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 4: 共 5 个指标 ==========
FROM (
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
                END
) q_4
INSERT INTO `G05_I_1.2.3.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.1.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.4.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.2.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.5.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 5: 共 5 个指标 ==========
FROM (
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

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__` 
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
                END
) q_5
INSERT INTO `G05_I_1.3.3.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.4.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.2.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.5.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.1.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 6: 共 5 个指标 ==========
FROM (
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

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__` 
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
                END
) q_6
INSERT INTO `G05_I_1.3.1.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.4.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.3.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.2.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.5.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 7: 共 5 个指标 ==========
FROM (
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

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__` 
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
                END
) q_7
INSERT INTO `G05_I_1.3.5.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.2.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.4.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.1.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.3.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- 指标: G05_I_1.9.1.A.2023
INSERT 
    INTO `G05_I_1.9.1.A.2023` 
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


-- ========== 逻辑组 9: 共 5 个指标 ==========
FROM (
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
                END
) q_9
INSERT INTO `G05_I_1.1.2.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.3.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.7.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.5.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.4.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- 指标: G05_I_1.7.A
----------------------------------------1.7 展期贷款------------------------------------------
    INSERT 
    INTO `G05_I_1.7.A` 
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


-- ========== 逻辑组 11: 共 5 个指标 ==========
FROM (
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
                END
) q_11
INSERT INTO `G05_I_1.2.2.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.1.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.5.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.4.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.3.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 12: 共 2 个指标 ==========
FROM (
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
                END
) q_12
INSERT INTO `G05_I_1.4.1.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.4.2.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 13: 共 3 个指标 ==========
FROM (
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
                END
) q_13
INSERT INTO `G05_I_1.5.2.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.5.1.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.5.3.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 14: 共 2 个指标 ==========
FROM (
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
                END
) q_14
INSERT INTO `G05_I_1.4.1.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.4.2.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 15: 共 5 个指标 ==========
FROM (
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
                END
) q_15
INSERT INTO `G05_I_1.2.1.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.5.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.4.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.3.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.2.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 16: 共 3 个指标 ==========
FROM (
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
                END
) q_16
INSERT INTO `G05_I_1.5.1.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.5.2.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.5.3.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 17: 共 5 个指标 ==========
FROM (
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
                END
) q_17
INSERT INTO `G05_I_1.1.5.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.3.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.4.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.7.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.1.2.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 18: 共 2 个指标 ==========
FROM (
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
                END
) q_18
INSERT INTO `G05_I_1.6.2.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.6.1.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 19: 共 2 个指标 ==========
FROM (
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
                END
) q_19
INSERT INTO `G05_I_1.4.2.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.4.1.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 20: 共 2 个指标 ==========
FROM (
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
                END
) q_20
INSERT INTO `G05_I_1.4.1.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.4.2.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 21: 共 3 个指标 ==========
FROM (
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
                END
) q_21
INSERT INTO `G05_I_1.5.2.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.5.3.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.5.1.D` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 22: 共 2 个指标 ==========
FROM (
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
                END
) q_22
INSERT INTO `G05_I_1.6.2.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.6.1.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 23: 共 5 个指标 ==========
FROM (
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
                END
) q_23
INSERT INTO `G05_I_1.2.2.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.5.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.1.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.3.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.2.4.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- 指标: G05_I_1.8.1.A.2023
--因迁移过来的村镇数据可能仍然存在与业务提供的明细口径不一致的情况，2023年1-10月村镇累放数据单独使用村镇业务提供的累放明细CBRC_G05_AMT_TMP2_CZ出数,2024年以后正常使用原逻辑。 20231011zjm
    
      --2024年后整合
      INSERT 
      INTO `G05_I_1.8.1.A.2023` 
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


-- ========== 逻辑组 25: 共 5 个指标 ==========
FROM (
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

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__` 
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
                END
) q_25
INSERT INTO `G05_I_1.3.4.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.5.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.1.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.2.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.3.3.C` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- 指标: G05_I_1.9.A.2023
INSERT 
    INTO `G05_I_1.9.A.2023` 
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


-- 指标: G05_I_2..C
INSERT 
    INTO `G05_I_2..C` 
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

--信用卡数据插入

    INSERT 
    INTO `G05_I_2..C` 
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


-- 指标: G05_I_2..D
INSERT 
    INTO `G05_I_2..D` 
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

--信用卡数据插入

    INSERT 
    INTO `G05_I_2..D` 
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


-- ========== 逻辑组 29: 共 2 个指标 ==========
FROM (
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
                END
) q_29
INSERT INTO `G05_I_1.6.2.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.6.1.A` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- ========== 逻辑组 30: 共 2 个指标 ==========
FROM (
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
                END
) q_30
INSERT INTO `G05_I_1.6.2.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *
INSERT INTO `G05_I_1.6.1.B` (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT *;

-- 指标: G05_I_1.8.A.2023
--因迁移过来的村镇数据可能仍然存在与业务提供的明细口径不一致的情况，2023年1-10月村镇累放数据单独使用村镇业务提供的累放明细CBRC_G05_AMT_TMP2_CZ出数,2024年以后正常使用原逻辑。 20231011zjm
    
      --2024年后整合
      INSERT 
      INTO `G05_I_1.8.A.2023` 
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


-- 指标: G05_I_2..A
----------------------------------------2.个人经营性贷款------------------------------------------
    -- 2.个人经营性贷款
    INSERT 
    INTO `G05_I_2..A` 
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

--信用卡数据插入

    INSERT 
    INTO `G05_I_2..A` 
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


-- 指标: G05_I_1.7.B
INSERT 
    INTO `G05_I_1.7.B` 
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


