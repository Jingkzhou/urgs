-- ============================================================
-- 文件名: G32外汇风险敞口情况表.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: G32_11..A
--=============================================================
    --G32 'G32_11..A'插入临时表
    --=============================================================
    V_STEP_ID   := V_STEP_ID + 1;

INSERT INTO `G32_11..A`
      (ORG_NUM, --机构号
       ITEM_NUM, --报表类型
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
            ITEM_NUM,
            CASE
              WHEN SUM(ITEM_VAL) <= 0 THEN
               SUM(ITEM_VAL)
              ELSE
               0
            END
       FROM (

             SELECT T.BIZ_ORG AS ORG_NUM, --机构号
                     CASE
                       WHEN DATA_ITEM_CD = '000001^D^36' THEN
                        'G32_11..A'
                       WHEN DATA_ITEM_CD = '000001^H^22' THEN
                        'G32_11..B'
                     END AS ITEM_NUM,
                     SUM(T.DATA_ITEM_VAL * U.CCY_RATE) AS ITEM_VAL --指标值（折人民币）

               FROM SMTMODS_M_GL_REPORT_DATA_STRG T
              INNER JOIN SMTMODS_L_PUBL_RATE U
                 ON U.CCY_DATE = I_DATADATE
                AND U.BASIC_CCY = T.CURR_CD --基准币种
                AND U.FORWARD_CCY = 'CNY' --折算币种
              WHERE T.SYS = '99' --系统
                AND T.ACCT_DT = I_DATADATE
                AND T.FREQ = 'D' --频度
                AND T.REPORT_CD IN ('000001')
                AND T.DATA_ITEM_CD IN ('000001^D^36', '000001^H^22')
                AND T.CURR_CD NOT IN ('USD','EUR','JPY','GBP','HKD','CHF','AUD','CAD','CNY')
               GROUP BY T.BIZ_ORG,
                        CASE
                          WHEN DATA_ITEM_CD = '000001^D^36' THEN
                           'G32_11..A'
                          WHEN DATA_ITEM_CD = '000001^H^22' THEN
                           'G32_11..B'
                        END)
      GROUP BY ORG_NUM, ITEM_NUM;


-- ========== 逻辑组 1: 共 8 个指标 ==========
FROM (
SELECT T.BIZ_ORG AS ORG_NUM, --机构号
            CASE
               WHEN T.CURR_CD = 'USD' THEN
                 'G32_1..B'
               WHEN T.CURR_CD = 'EUR' THEN
                 'G32_2..B'
               WHEN T.CURR_CD = 'JPY' THEN
                 'G32_3..B'
               WHEN T.CURR_CD = 'GBP' THEN
                 'G32_4..B'
               WHEN T.CURR_CD = 'HKD' THEN
                 'G32_5..B'
               WHEN T.CURR_CD = 'CHF' THEN
                 'G32_6..B'
               WHEN T.CURR_CD = 'AUD' THEN
                 'G32_7..B'
               WHEN T.CURR_CD = 'CAD' THEN
                 'G32_8..B'

             END AS ITEM_NUM, --指标号AS ITEM_NUM, --指标号
            SUM(T.DATA_ITEM_VAL * U.CCY_RATE) AS ITEM_VAL --指标值（折人民币）

       FROM SMTMODS_M_GL_REPORT_DATA_STRG T
      INNER JOIN SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE T.SYS = '99' --系统
        AND T.ACCT_DT = I_DATADATE
        AND T.FREQ = 'D' --频度
        AND T.REPORT_CD IN ('000001')
        AND T.DATA_ITEM_CD = '000001^H^22' --负债合计
        AND T.CURR_CD  IN ('USD', 'EUR', 'JPY', 'GBP', 'HKD', 'CHF', 'AUD', 'CAD')
       GROUP BY T.BIZ_ORG, CASE
               WHEN T.CURR_CD = 'USD' THEN
                 'G32_1..B'
               WHEN T.CURR_CD = 'EUR' THEN
                 'G32_2..B'
               WHEN T.CURR_CD = 'JPY' THEN
                 'G32_3..B'
               WHEN T.CURR_CD = 'GBP' THEN
                 'G32_4..B'
               WHEN T.CURR_CD = 'HKD' THEN
                 'G32_5..B'
               WHEN T.CURR_CD = 'CHF' THEN
                 'G32_6..B'
               WHEN T.CURR_CD = 'AUD' THEN
                 'G32_7..B'
               WHEN T.CURR_CD = 'CAD' THEN
                 'G32_8..B'

             END
) q_1
INSERT INTO `G32_2..B` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_4..B` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_1..B` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_7..B` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_6..B` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_8..B` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_5..B` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_3..B` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *;

-- 指标: G32_10..B
INSERT INTO `G32_10..B`
      (ORG_NUM, --机构号
       ITEM_NUM, --报表类型
       ITEM_VAL --指标值
       )
          SELECT ORG_NUM,
            ITEM_NUM,
            CASE
              WHEN SUM(ITEM_VAL) > 0 THEN
               SUM(ITEM_VAL)
              ELSE
               0
            END
       FROM (

             SELECT T.BIZ_ORG AS ORG_NUM, --机构号
                     CASE
                       WHEN DATA_ITEM_CD = '000001^D^36' THEN
                        'G32_10..A'
                       WHEN DATA_ITEM_CD = '000001^H^22' THEN
                        'G32_10..B'
                     END AS ITEM_NUM,
                     SUM(T.DATA_ITEM_VAL * U.CCY_RATE) AS ITEM_VAL --指标值（折人民币）

               FROM SMTMODS_M_GL_REPORT_DATA_STRG T
              INNER JOIN SMTMODS_L_PUBL_RATE U
                 ON U.CCY_DATE = I_DATADATE
                AND U.BASIC_CCY = T.CURR_CD --基准币种
                AND U.FORWARD_CCY = 'CNY' --折算币种
              WHERE T.SYS = '99' --系统
                AND T.ACCT_DT = I_DATADATE
                AND T.FREQ = 'D' --频度
                AND T.REPORT_CD IN ('000001')
                AND T.DATA_ITEM_CD IN ('000001^D^36', '000001^H^22')
                AND T.CURR_CD NOT IN ('USD','EUR','JPY','GBP','HKD','CHF','AUD','CAD','CNY')
              GROUP BY T.BIZ_ORG,
                        CASE
                          WHEN DATA_ITEM_CD = '000001^D^36' THEN
                           'G32_10..A'
                          WHEN DATA_ITEM_CD = '000001^H^22' THEN
                           'G32_10..B'
                        END)
      GROUP BY ORG_NUM, ITEM_NUM;


-- ========== 逻辑组 3: 共 8 个指标 ==========
FROM (
SELECT T.BIZ_ORG AS ORG_NUM, --机构号
            CASE
               WHEN T.CURR_CD = 'USD' THEN
                 'G32_1..A'
               WHEN T.CURR_CD = 'EUR' THEN
                 'G32_2..A'
               WHEN T.CURR_CD = 'JPY' THEN
                 'G32_3..A'
               WHEN T.CURR_CD = 'GBP' THEN
                 'G32_4..A'
               WHEN T.CURR_CD = 'HKD' THEN
                 'G32_5..A'
               WHEN T.CURR_CD = 'CHF' THEN
                 'G32_6..A'
               WHEN T.CURR_CD = 'AUD' THEN
                 'G32_7..A'
               WHEN T.CURR_CD = 'CAD' THEN
                 'G32_8..A'

             END AS ITEM_NUM, --指标号AS ITEM_NUM, --指标号
            SUM(T.DATA_ITEM_VAL * U.CCY_RATE) AS ITEM_VAL --指标值（折人民币）

       FROM SMTMODS_M_GL_REPORT_DATA_STRG T
      INNER JOIN SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE T.SYS = '99' --系统
        AND T.ACCT_DT = I_DATADATE
        AND T.FREQ = 'D' --频度
        AND T.REPORT_CD IN ('000001')
        AND T.DATA_ITEM_CD = '000001^D^36' --资产合计
        AND T.CURR_CD  IN ('USD', 'EUR', 'JPY', 'GBP', 'HKD', 'CHF', 'AUD', 'CAD')
       GROUP BY T.BIZ_ORG, CASE
               WHEN T.CURR_CD = 'USD' THEN
                 'G32_1..A'
               WHEN T.CURR_CD = 'EUR' THEN
                 'G32_2..A'
               WHEN T.CURR_CD = 'JPY' THEN
                 'G32_3..A'
               WHEN T.CURR_CD = 'GBP' THEN
                 'G32_4..A'
               WHEN T.CURR_CD = 'HKD' THEN
                 'G32_5..A'
               WHEN T.CURR_CD = 'CHF' THEN
                 'G32_6..A'
               WHEN T.CURR_CD = 'AUD' THEN
                 'G32_7..A'
               WHEN T.CURR_CD = 'CAD' THEN
                 'G32_8..A'

             END
) q_3
INSERT INTO `G32_1..A` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_2..A` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_4..A` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_8..A` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_3..A` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_7..A` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_5..A` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G32_6..A` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *;

-- 指标: G32_10..A
--=============================================================
    --G32 'G32_10..A'插入临时表
    --=============================================================
    V_STEP_ID   := V_STEP_ID + 1;

INSERT INTO `G32_10..A`
      (ORG_NUM, --机构号
       ITEM_NUM, --报表类型
       ITEM_VAL --指标值
       )
          SELECT ORG_NUM,
            ITEM_NUM,
            CASE
              WHEN SUM(ITEM_VAL) > 0 THEN
               SUM(ITEM_VAL)
              ELSE
               0
            END
       FROM (

             SELECT T.BIZ_ORG AS ORG_NUM, --机构号
                     CASE
                       WHEN DATA_ITEM_CD = '000001^D^36' THEN
                        'G32_10..A'
                       WHEN DATA_ITEM_CD = '000001^H^22' THEN
                        'G32_10..B'
                     END AS ITEM_NUM,
                     SUM(T.DATA_ITEM_VAL * U.CCY_RATE) AS ITEM_VAL --指标值（折人民币）

               FROM SMTMODS_M_GL_REPORT_DATA_STRG T
              INNER JOIN SMTMODS_L_PUBL_RATE U
                 ON U.CCY_DATE = I_DATADATE
                AND U.BASIC_CCY = T.CURR_CD --基准币种
                AND U.FORWARD_CCY = 'CNY' --折算币种
              WHERE T.SYS = '99' --系统
                AND T.ACCT_DT = I_DATADATE
                AND T.FREQ = 'D' --频度
                AND T.REPORT_CD IN ('000001')
                AND T.DATA_ITEM_CD IN ('000001^D^36', '000001^H^22')
                AND T.CURR_CD NOT IN ('USD','EUR','JPY','GBP','HKD','CHF','AUD','CAD','CNY')
              GROUP BY T.BIZ_ORG,
                        CASE
                          WHEN DATA_ITEM_CD = '000001^D^36' THEN
                           'G32_10..A'
                          WHEN DATA_ITEM_CD = '000001^H^22' THEN
                           'G32_10..B'
                        END)
      GROUP BY ORG_NUM, ITEM_NUM;


-- 指标: G32_11..B
INSERT INTO `G32_11..B`
      (ORG_NUM, --机构号
       ITEM_NUM, --报表类型
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
            ITEM_NUM,
            CASE
              WHEN SUM(ITEM_VAL) <= 0 THEN
               SUM(ITEM_VAL)
              ELSE
               0
            END
       FROM (

             SELECT T.BIZ_ORG AS ORG_NUM, --机构号
                     CASE
                       WHEN DATA_ITEM_CD = '000001^D^36' THEN
                        'G32_11..A'
                       WHEN DATA_ITEM_CD = '000001^H^22' THEN
                        'G32_11..B'
                     END AS ITEM_NUM,
                     SUM(T.DATA_ITEM_VAL * U.CCY_RATE) AS ITEM_VAL --指标值（折人民币）

               FROM SMTMODS_M_GL_REPORT_DATA_STRG T
              INNER JOIN SMTMODS_L_PUBL_RATE U
                 ON U.CCY_DATE = I_DATADATE
                AND U.BASIC_CCY = T.CURR_CD --基准币种
                AND U.FORWARD_CCY = 'CNY' --折算币种
              WHERE T.SYS = '99' --系统
                AND T.ACCT_DT = I_DATADATE
                AND T.FREQ = 'D' --频度
                AND T.REPORT_CD IN ('000001')
                AND T.DATA_ITEM_CD IN ('000001^D^36', '000001^H^22')
                AND T.CURR_CD NOT IN ('USD','EUR','JPY','GBP','HKD','CHF','AUD','CAD','CNY')
               GROUP BY T.BIZ_ORG,
                        CASE
                          WHEN DATA_ITEM_CD = '000001^D^36' THEN
                           'G32_11..A'
                          WHEN DATA_ITEM_CD = '000001^H^22' THEN
                           'G32_11..B'
                        END)
      GROUP BY ORG_NUM, ITEM_NUM;


