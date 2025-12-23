-- ============================================================
-- 文件名: G04利润表.sql
-- 生成时间: 2025-12-18 13:53:37
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: G04.14.A.2025
DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = V_REP_NUM
       AND FLAG IN ('1', '2')
       AND ITEM_NUM IN (  'G04.14.A.2025' );

INSERT INTO `G04.14.A.2025`
      (DATA_DATE, SYS_NAM, REP_NUM, ORG_NUM, ITEM_NUM, ITEM_VAL, FLAG,IS_TOTAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       'CBRC' AS SYS_NUM,
       'G04' AS REP_NUM,
       T.ORG_NUM AS ORG_NUM,
       'G04.14.A.2025' AS ITEM_NUM,
       (CASE
         WHEN SUM(CREDIT_BAL* T2.CCY_RATE) - SUM(DEBIT_BAL* T2.CCY_RATE) > 0 THEN
          SUM(CREDIT_BAL* T2.CCY_RATE) - SUM(DEBIT_BAL* T2.CCY_RATE)
         ELSE
          0
       END) AS ITEM_VAL,
       '2' AS FLAG,
        'N' AS IS_TOTAL
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
         LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T.DATA_DATE = T2.DATA_DATE
       WHERE T.DATA_DATE <= I_DATADATE
       AND T.DATA_DATE >=
	   TO_CHAR(TRUNC(DATE(I_DATADATE, 'YYYYMMDD'), 'yEAR'), 'YYYYMMDD') 
       AND SUBSTR(T.DATA_DATE, 5, 4) IN ('0331', '0630', '0930', '1231')
       AND T.ITEM_CD IN ('222110', '222113', '222114')
       --AND T.CURR_CD = 'CNY'
       GROUP BY T.ORG_NUM;


