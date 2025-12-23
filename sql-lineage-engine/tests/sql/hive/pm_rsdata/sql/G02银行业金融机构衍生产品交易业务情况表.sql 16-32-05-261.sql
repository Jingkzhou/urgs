-- ============================================================
-- 文件名: G02银行业金融机构衍生产品交易业务情况表.sql
-- 生成时间: 2025-12-18 13:53:37
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G02' AS REP_NUM, --报表编号
       CASE
         WHEN COUNTERPARTY_TYP = '1' THEN
          'G02_4_1.1.P'
         WHEN COUNTERPARTY_TYP = '2' THEN
          'G02_4_1.2.P'
         WHEN COUNTERPARTY_TYP = '3' THEN
          'G02_4_1.3.P'
         WHEN COUNTERPARTY_TYP = '4' THEN
          'G02_4_1.4.P'
         WHEN COUNTERPARTY_TYP = '5' THEN
          'G02_4_1.5.P'
       END AS ITEM_NUM, --指标号
       SUM(T.RE_MARKET_VALUE * V.CCY_RATE) AS ITEM_VAL, --指标值
       '2' AS FLAG
  FROM (SELECT A.ORG_NUM,
               A.RE_MARKET_VALUE_CCY,
               CASE
                 WHEN B.CUST_TYPE = '00' THEN
                  '5'
                 WHEN B.CUST_TYPE = '11' OR C.FINA_CODE = 'I10000' THEN
                  '4'
                 WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND
                      C.FINA_CODE NOT LIKE 'C%' AND
                      B.INLANDORRSHORE_FLG = 'Y' THEN
                  '2'
                 WHEN B.CUST_TYPE = '12' AND C.FINA_CODE NOT LIKE 'C%' AND
                      B.INLANDORRSHORE_FLG = 'Y' THEN
                  '1'
                 WHEN B.CUST_TYPE = '12' AND C.FINA_CODE <> 'I10000' AND
                      B.INLANDORRSHORE_FLG = 'N' THEN
                  '3'
               END AS COUNTERPARTY_TYP, --交易对手类型 SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
               RE_MARKET_VALUE --估值损益
          FROM SMTMODS_L_ACCT_DERIVE_DETAIL_INFO A
          LEFT JOIN SMTMODS_L_CUST_ALL B
            ON A.OPPO_PTY_CD = B.CUST_ID
           AND B.DATA_DATE = I_DATADATE
         INNER JOIN SMTMODS_L_CUST_C C
            ON B.CUST_ID = C.CUST_ID
           AND C.DATA_DATE = I_DATADATE
         WHERE RE_MARKET_VALUE > 0
           AND AGREEMENT_TYPE = '7'
           AND A.DATA_DATE = I_DATADATE) T
  LEFT JOIN SMTMODS_L_PUBL_RATE V ON V.CCY_DATE = I_DATADATE
                 AND V.BASIC_CCY = T.RE_MARKET_VALUE_CCY --基准币种
                 AND V.FORWARD_CCY = 'CNY' --折算币种
 WHERE T.COUNTERPARTY_TYP IN ('1', '2', '3', '4', '5')
 GROUP BY ORG_NUM,
          CASE
            WHEN COUNTERPARTY_TYP = '1' THEN
             'G02_4_1.1.P'
            WHEN COUNTERPARTY_TYP = '2' THEN
             'G02_4_1.2.P'
            WHEN COUNTERPARTY_TYP = '3' THEN
             'G02_4_1.3.P'
            WHEN COUNTERPARTY_TYP = '4' THEN
             'G02_4_1.4.P'
            WHEN COUNTERPARTY_TYP = '5' THEN
             'G02_4_1.5.P'
          END
) q_0
INSERT INTO `G02_4_1.4.P` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G02_4_1.1.P` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G02_4_1.2.P` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G02_4_1.3.P` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G02_4_1.5.P` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

