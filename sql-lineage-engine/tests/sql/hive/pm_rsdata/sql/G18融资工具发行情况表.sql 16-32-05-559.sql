-- ============================================================
-- 文件名: G18融资工具发行情况表.sql
-- 生成时间: 2025-12-18 13:53:39
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: G18_0_1.1.1.A.2020
--大额存单面值，无境外发放
    INSERT INTO `G18_0_1.1.1.A.2020`
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


-- ========== 逻辑组 1: 共 2 个指标 ==========
FROM (
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

--大额存单面值，无境外发放
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
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
       GROUP BY A.ORG_NUM
) q_1
INSERT INTO `G18_0_1.1.1.E.2020` (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
SELECT *
INSERT INTO `G18_0_1.1.1.F.2020` (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
SELECT *;

-- 指标: G18_0_1.4.1.A.2022
--1.4.1 其中：二级资本债
    --境内发行账面余额
    INSERT INTO `G18_0_1.4.1.A.2022`
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


-- 指标: G18_0_1.4.A.2022
---------------
    --M1 1.4项次级债券
     --境内发行账面余额
    INSERT INTO `G18_0_1.4.A.2022`
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


-- 指标: G18_0_1.7.G.2022
----剩余期限
    INSERT INTO `G18_0_1.7.G.2022`
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


-- 指标: G18_0_1.4.1.G.2022
--剩余期限
       INSERT INTO `G18_0_1.4.1.G.2022`
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


-- 指标: G18_0_1.4.G.2022
--剩余期限
       INSERT INTO `G18_0_1.4.G.2022`
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


-- 指标: G18_0_1.1.1.B.2020
--本年发放
    INSERT INTO `G18_0_1.1.1.B.2020`
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


-- 指标: G18_0_1.4.1.B.2022
--境内发行其中:本年发行
    INSERT INTO `G18_0_1.4.1.B.2022`
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


-- 指标: G18_0_1.1.2.B.2020
--本年发放
    INSERT INTO `G18_0_1.1.2.B.2020`
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


-- 指标: G18_0_1.7.A.2022
--1.7其他具有固定期限的融资工具
    --境内发行账面余额
    INSERT INTO `G18_0_1.7.A.2022`
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


-- 指标: G18_0_1.1.2.A.2020
--同业存单面值，无境外发放
    INSERT INTO `G18_0_1.1.2.A.2020`
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


-- ========== 逻辑组 12: 共 2 个指标 ==========
FROM (
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
             END
) q_12
INSERT INTO `G18_0_1.1.E.2020` (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
SELECT *
INSERT INTO `G18_0_1.1.F.2020` (DATA_DATE,
       ORG_NUM,
       ITEM_NUM,
       FACE_VAL_RMB,
       GZSY_VAL_RMB,
       PREPARATION_RMB)
SELECT *;

-- 指标: G18_0_1.1.2.E.2020
INSERT INTO `G18_0_1.1.2.E.2020`
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

--同业存单面值，无境外发放
    INSERT INTO `G18_0_1.1.2.E.2020`
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


-- 指标: G18_0_1.4.B.2022
--境内发行其中:本年发行
    INSERT INTO `G18_0_1.4.B.2022`
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


