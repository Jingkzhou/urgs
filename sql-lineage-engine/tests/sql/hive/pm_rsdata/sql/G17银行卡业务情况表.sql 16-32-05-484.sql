-- ============================================================
-- 文件名: G17银行卡业务情况表.sql
-- 生成时间: 2025-12-18 13:53:39
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: G17_1.1.C.2022
INSERT INTO `G17_1.1.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_1.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(A.C_ITEM_VAL)
    FROM CBRC_G17_DJK A
   WHERE A.DATA_DATE = I_DATADATE
     AND TRIM(A.PROJECT_DESC) LIKE '%1.1总卡量（张）%';

INSERT INTO `G17_1.1.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803',
             'G17_1.1.C.2022' AS ITEM_NUM,
             TO_NUMBER(A.C_ITEM_VAL)
        FROM CBRC_g17_djk A
       WHERE A.DATA_DATE = I_DATADATE
         AND TRIM(A.PROJECT_DESC) LIKE '%1.1总卡量（张）%';


-- 指标: G17_2.5.3.C.2021
INSERT INTO `G17_2.5.3.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.5.3.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.5.3通过第三方支付机构交易的卡量（张）%';

INSERT INTO `G17_2.5.3.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_2.5.3.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%2.5.3通过第三方支付机构交易的卡量（张）%';


-- 指标: G17_4.3.1.C.2022
INSERT INTO `G17_4.3.1.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_4.3.1.C.2022' AS ITEM_NUM,
         SUM(case
               when t.PAYMENT_PROPERTY = '1' then
                T.TX_AMT * U.CCY_RATE
               when t.PAYMENT_PROPERTY = '2' then
                T.TX_AMT * U.CCY_RATE * -1
             end) / 1.06 AS ITEM_VAL
    FROM CBRC_L_TRAN_ACCT_INNER_TX_TMP T
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = T.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE T.REMARK LIKE '%分润%'
     AND T.ACCT_NUM IN ('9019840302000204', '90198403020002041') --9019840302000204 分期付款手续费;

INSERT INTO `G17_4.3.1.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803' AS ORG_NUM,
         G.ORG_NUM AS ORG_NUM,
         'G17_4.7.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_L_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = I_DATADATE
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD = '60210601' --60210601  银行卡结算业务收入
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_4.7.C.2022' AS ITEM_NUM,
         SUM(ITEM_VAL) * -1 AS ITEM_VAL
    FROM CBRC_G17_DATA_COLLECT_TMP
   WHERE DATA_DATE = I_DATADATE
     AND ITEM_NUM IN
         ('G17_4.3.1.C.2022', 'G17_4.4.1.C.2022', 'G17_4.5.C.2022');

INSERT INTO `G17_4.3.1.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT I_DATADATE AS DATA_DATE,
             '009803',
             'G17_4.3.1.C.2022' AS ITEM_NUM,
             SUM(case when   t.PAYMENT_PROPERTY='1'  then T.TX_AMT * U.CCY_RATE
                     when  t.PAYMENT_PROPERTY='2' then   T.TX_AMT * U.CCY_RATE*-1 end)/1.06 AS ITEM_VAL
        FROM CBRC_l_tran_acct_inner_tx_tmp T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE TO_CHAR(T.TX_DATE, 'YYYYMM') BETWEEN SUBSTR(I_DATADATE, 1, 4)||'0101' AND I_DATADATE
         AND T.REMARK LIKE '%分润%'
         AND T.ACCT_NUM = '9019840302000204' --9019840302000204 分期付款手续费;

INSERT INTO `G17_4.3.1.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_4.7.C.2022' AS ITEM_NUM,
             SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD = '60210601'  --60210601  银行卡结算业务收入
         AND G.ORG_NUM = '009803'
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_4.7.C.2022' AS ITEM_NUM,
             SUM(ITEM_VAL) * -1 AS ITEM_VAL
        FROM CBRC_G17_DATA_COLLECT_TMP
       WHERE DATA_DATE = I_DATADATE
         AND ITEM_NUM IN
             ('G17_4.3.1.C.2022', 'G17_4.4.1.C.2022', 'G17_4.5.C.2022');


-- 指标: G17_6.5.2.2.C.2021
INSERT INTO `G17_6.5.2.2.C.2021`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.5.2.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.5.2.2其中：专项分期逾期91天及以上的应收账款余额（万元）%';

INSERT INTO `G17_6.5.2.2.C.2021`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.5.2.2.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.5.2.2其中：专项分期逾期91天及以上的应收账款余额（万元）%';


-- 指标: G17_1.1.2.C.2022
INSERT INTO `G17_1.1.2.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_1.1.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL)
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%1.1.2其中： 长期睡眠卡（张）%';

INSERT INTO `G17_1.1.2.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_1.1.2.C.2022' AS ITEM_NUM,
             TO_NUMBER(T.C_ITEM_VAL)
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%1.1.2其中： 长期睡眠卡（张）%';


-- 指标: G17_3.4.2.2.3.C.2021
INSERT INTO `G17_3.4.2.2.3.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.2.2.3.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.2.2.3其中：其他消费分期应收账款余额（万元）%';

INSERT INTO `G17_3.4.2.2.3.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.4.2.2.3.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.4.2.2.3其中：其他消费分期应收账款余额（万元）%';


-- 指标: G17_3.4.2.2.C.2021
INSERT INTO `G17_3.4.2.2.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.2.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.2.2其中：消费分期应收账款余额（万元）%';

INSERT INTO `G17_3.4.2.2.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.4.2.2.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.4.2.2其中：消费分期应收账款余额（万元）%';


-- 指标: G17_3.8.5.C.2022
INSERT INTO `G17_3.8.5.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.8.5.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.8.5持卡人55岁以上的应收账款余额%';

INSERT INTO `G17_3.8.5.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.8.5.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.8.5持卡人55岁以上的应收账款余额%';


-- 指标: G17_3.4.2.2.2.C.2021
INSERT INTO `G17_3.4.2.2.2.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.2.2.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.2.2.2其中：专项分期应收账款余额（万元）%';

INSERT INTO `G17_3.4.2.2.2.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.4.2.2.2.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.4.2.2.2其中：专项分期应收账款余额（万元）%';


-- 指标: G17_2.1.C.2022
INSERT INTO `G17_2.1.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.1本年累计消费金额（万元）%';

INSERT INTO `G17_2.1.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_2.1.C.2022' AS ITEM_NUM,
             TO_NUMBER(T.C_ITEM_VAL) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%2.1本年累计消费金额（万元）%';


-- 指标: G17_3.4.1.C.2021
INSERT INTO `G17_3.4.1.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.1其中：非分期业务形成的应收账款余额（万元）%';

INSERT INTO `G17_3.4.1.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.4.1.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.4.1其中：非分期业务形成的应收账款余额（万元）%';


-- 指标: G17_2.5.2.1.A.2022
INSERT INTO `G17_2.5.2.1.A.2022`
  (data_date, org_num, item_num, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
          'G17_2.5.2.1.A.2022' AS ITEM_NUM,
         COUNT(1)
    FROM CBRC_L_TRAN_TX_TEMP A --SMTMODS_L_TRAN_TX
   WHERE
  --AND TRANS_CHANNEL = 'WLPJ' /*网联*/
  --AND TRAN_STS = 'A' /*交易状态：正常*/
  --AND TRA_MED_NAME='11'   /*交易介质名称 ：借记卡*/
   OPPO_ORG_NUM IN ('Z2007933000010', 'Z2004944000010')
   AND TRANS_INCOME_TYPE = '1' /*资金收付标志：收*/
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;


-- 指标: G17_1.2.C.2022
INSERT INTO `G17_1.2.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_1.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL)
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%1.2总户数（户）%';

INSERT INTO `G17_1.2.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_1.2.C.2022' AS ITEM_NUM,
             TO_NUMBER(T.C_ITEM_VAL)
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%1.2总户数（户）%';


-- 指标: G17_6.4.2.C.2022
--6.4.2    31-60天(M2)贷记卡
INSERT INTO `G17_6.4.2.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.2    31-60天(M2)%';

--6.4.2    31-60天(M2)贷记卡
    INSERT INTO `G17_6.4.2.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.4.2.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.4.2    31-60天(M2)%';


-- 指标: G17_2.5.1.1.A.2022
INSERT INTO `G17_2.5.1.1.A.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         CASE
              WHEN ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END,
         'G17_2.5.1.1.A.2022' AS ITEM_NUM,
         SUM(TRANS_AMT)
    FROM CBRC_L_TRAN_TX_TEMP --SMTMODS_L_TRAN_TX
   WHERE OPPO_ORG_NUM IN ('Z2007933000010', 'Z2004944000010')
     AND TRANS_INCOME_TYPE = '1' /*资金收付标志：收*/
   GROUP BY CASE
              WHEN ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;


-- 指标: G17_6.6.C.2021
INSERT INTO `G17_6.6.C.2021`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.6.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.6 预借现金业务逾期91天及以上形成的应收账款余额（万元）%';

INSERT INTO `G17_6.6.C.2021`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.6.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.6 预借现金业务逾期91天及以上形成的应收账款余额（万元）%';


-- 指标: G17_1.2.A
INSERT INTO `G17_1.2.A`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT 
   I_DATADATE AS DATA_DATE,
   CASE
     WHEN A.ORG_NUM LIKE '51%' THEN
      '510000'
     WHEN A.ORG_NUM LIKE '52%' THEN
      '520000'
     WHEN A.ORG_NUM LIKE '53%' THEN
      '530000'
     WHEN A.ORG_NUM LIKE '54%' THEN
      '540000'
     WHEN A.ORG_NUM LIKE '55%' THEN
      '550000'
     WHEN A.ORG_NUM LIKE '56%' THEN
      '560000'
     WHEN A.ORG_NUM LIKE '57%' THEN
      '570000'
     WHEN A.ORG_NUM LIKE '58%' THEN
      '580000'
     WHEN A.ORG_NUM LIKE '59%' THEN
      '590000'
     WHEN A.ORG_NUM LIKE '60%' THEN
      '600000'
     ELSE
      '009803'
   END,
   'G17_1.2.A' AS ITEM_NUM,
   COUNT(DISTINCT B.ID_NO)
    FROM SMTMODS_L_AGRE_CARD_INFO A --卡基本信息表
    LEFT JOIN SMTMODS_L_CUST_ALL B --全量客户信息表
      ON A.CUST_ID = B.CUST_ID
     and b.data_date = I_DATADATE
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '1' --1:借记卡
     AND A.CARDSTAT NOT IN ('V', 'Z') --V:过期,Z:注销
     AND A.MAIN_ADDITIONAL_FLG = 'A'
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;


-- 指标: G17_6.5.2.3.C.2021
INSERT INTO `G17_6.5.2.3.C.2021`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.5.2.3.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.5.2.3其中：其他消费逾期91天及以上分期应收账款余额（万元）%';

INSERT INTO `G17_6.5.2.3.C.2021`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.5.2.3.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.5.2.3其中：其他消费逾期91天及以上分期应收账款余额（万元）%';


-- 指标: G17_6.8.C.2022
INSERT INTO `G17_6.8.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.8.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.8 当年新发生逾期90天以上透支余额（万元）%';

INSERT INTO `G17_6.8.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.8.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.8 当年新发生逾期90天以上透支余额（万元）%';


-- 指标: G17_3.8.2.C.2022
INSERT INTO `G17_3.8.2.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.8.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.8.2持卡人25岁-35岁（含）的应收账款余额%';

INSERT INTO `G17_3.8.2.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.8.2.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.8.2持卡人25岁-35岁（含）的应收账款余额%';


-- 指标: G17_6.1.C.2022
INSERT INTO `G17_6.1.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.1逾期账户户数（户）%';

INSERT INTO `G17_6.1.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.1.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.1逾期账户户数（户）%';


-- 指标: G17_1.2.1.C.2022
INSERT INTO `G17_1.2.1.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_1.2.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL)
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%1.2.1其中：睡眠户（户）%';

INSERT INTO `G17_1.2.1.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_1.2.1.C.2022' AS ITEM_NUM,
             TO_NUMBER(T.C_ITEM_VAL)
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%1.2.1其中：睡眠户（户）%';


-- 指标: G17_6.4.1.C.2022
--    6.4.1    1-30天(M1) 贷记卡
INSERT INTO `G17_6.4.1.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.1    1-30天(M1)%';

--    6.4.1    1-30天(M1) 贷记卡
    INSERT INTO `G17_6.4.1.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.4.1.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.4.1    1-30天(M1)%';


-- 指标: G17_6.4.5.C.2022
--6.4.5    121-150天(M5)贷记卡
INSERT INTO `G17_6.4.5.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.5.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.5    121-150天(M5)%';

--6.4.5    121-150天(M5)贷记卡
    INSERT INTO `G17_6.4.5.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.4.5.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.4.5    121-150天(M5)%';


-- 指标: G17_4.2.C.2022
INSERT INTO `G17_4.2.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         G.ORG_NUM,
         'G17_4.2.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_V_PUB_IDX_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD = '60210603' --60210603  银行卡跨行结算业务收入
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM;

INSERT INTO `G17_4.2.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
             G.ORG_NUM,
             'G17_4.2.C.2022' AS ITEM_NUM,
             SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD = '60210603'  --60210603  银行卡跨行结算业务收入
         AND G.ORG_NUM = '009803'
       GROUP BY G.ORG_NUM;


-- 指标: G17_2.4.C.2022
INSERT INTO `G17_2.4.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.4.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.4本年累计还款金额（万元）%';

INSERT INTO `G17_2.4.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_2.4.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%2.4本年累计还款金额（万元）%';


-- 指标: G17_3.3.2.C.2021
INSERT INTO `G17_3.3.2.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.3.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.3.2其中：预借现金业务形成的应收账款余额（万元）%';

INSERT INTO `G17_3.3.2.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.3.2.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.3.2其中：预借现金业务形成的应收账款余额（万元）%';


-- 指标: G17_3.4.2.1.C.2021
INSERT INTO `G17_3.4.2.1.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.2.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.2.1其中：现金分期应收账款余额（万元）%';

INSERT INTO `G17_3.4.2.1.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.4.2.1.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.4.2.1其中：现金分期应收账款余额（万元）%';


-- 指标: G17_2.5.3.A.2022
INSERT INTO `G17_2.5.3.A.2022`
  (data_date, org_num, item_num, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         -- '009803',
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
         'G17_2.5.3.A.2022' AS ITEM_NUM,
         COUNT(distinct ACCOUNT_CODE)
    FROM CBRC_L_TRAN_TX_TEMP A --SMTMODS_L_TRAN_TX
   WHERE OPPO_ORG_NUM IN ('Z2007933000010', 'Z2004944000010')
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;


-- 指标: G17_7.2.A
INSERT INTO `G17_7.2.A`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         -- '009803',
         CASE
           WHEN SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6') THEN
            A.ORG_NUM
           ELSE
            '009803'
         END,
         'G17_7.2.A' AS ITEM_NUM,
         COUNT(DISTINCT A.EQUIPMENT_NBR)
    FROM SMTMODS_L_PUBL_EQUIPMENT A --自助设备信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.EQUIPMENT_TYP <> 'B' --B:POS
     AND A.EQUIPMENT_STS = 'A' --A:有效
     AND (A.EQUIPMENT_FLG = 'Y' OR A.EQUIPMENT_FLG IS NULL) --Y:是
   GROUP BY CASE
              WHEN SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6') THEN
               A.ORG_NUM
              ELSE
               '009803'
            END
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_7.2.A' AS ITEM_NUM,
         TO_NUMBER(NVL(T.A_ITEM_VAL, '0')) AS ITEM_NUM
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%7.2自助机具台数（台）%';

DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G17'
       AND T.ORG_NUM ='009803'
       AND (  T.ITEM_NUM IN ('G17_7.1.A',
         'G17_7.2.A', 'G17_7.3.A', 'G17_7.4.A'))
       AND T.FLAG = '2';

INSERT INTO `G17_7.2.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803',
             'G17_7.2.A' AS ITEM_NUM,
             COUNT(DISTINCT A.EQUIPMENT_NBR)
        FROM SMTMODS_L_PUBL_EQUIPMENT A --自助设备信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.EQUIPMENT_TYP <> 'B' --B:POS
         AND A.EQUIPMENT_STS = 'A' --A:有效
         AND (A.EQUIPMENT_FLG = 'Y' OR A.EQUIPMENT_FLG IS NULL) --Y:是
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_7.2.A' AS ITEM_NUM,
             TO_NUMBER(NVL(T.A_ITEM_VAL, '0')) AS ITEM_NUM
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%7.2自助机具台数（台）%';


-- 指标: G17_6.2.C.2022
INSERT INTO `G17_6.2.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.2逾期账户授信额度（万元）%';

INSERT INTO `G17_6.2.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.2.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.2逾期账户授信额度（万元）%';


-- 指标: G17_4.2.A
INSERT INTO `G17_4.2.A`
    (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
           T.ORG_NUM AS ORG_NUM,
           'G17_4.2.A' AS ITEM_NUM,
           SUM(case
                 when PAYMENT_PROPERTY = '1' then
                  T.TX_AMT * U.CCY_RATE
                 when PAYMENT_PROPERTY = '2' then
                  T.TX_AMT * U.CCY_RATE * -1
               end) AS ITEM_VAL
      FROM CBRC_L_TRAN_ACCT_INNER_TX_TMP T
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = T.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
     WHERE /*T.ACCT_NUM IN ('9019801014032900001',
                          '9019801014032700002',
                          '90198010140329000011',
                          '90198010140327000021') --9019801014032700002（POS消费他代本应收银行手续费）+9019801014032900001（本代本POS消费应收银行手续费）
       AND*/ T.TRAN_STS = 'A' --正常
       AND T.REMARK like '%分润%'
     GROUP BY T.ORG_NUM;


-- 指标: G17_4.3.C.2022
INSERT INTO `G17_4.3.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         G.ORG_NUM,
         'G17_4.3.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_V_PUB_IDX_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD like '6011' --6011利息收益
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM;

INSERT INTO `G17_4.3.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             G.ORG_NUM,
             'G17_4.3.C.2022' AS ITEM_NUM,
             SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD like  '6011%' --6011利息收益
         AND G.ORG_NUM = '009803'
       GROUP BY G.ORG_NUM;


-- 指标: G17_3.3.C.2022
INSERT INTO `G17_3.3.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.3.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.3应收账款余额-按是否为预借现金业务划分（万元）%';

INSERT INTO `G17_3.3.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.3.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.3应收账款余额-按是否为预借现金业务划分（万元）%';


-- 指标: G17_4.1.C.2022
INSERT INTO `G17_4.1.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         G.ORG_NUM,
         'G17_4.1.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_V_PUB_IDX_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD = '60210602' --银行卡年费收入
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM;

INSERT INTO `G17_4.1.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             G.ORG_NUM,
             'G17_4.1.C.2022' AS ITEM_NUM,
             SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD = '60210602'  --银行卡年费收入
         AND G.ORG_NUM = '009803'
       GROUP BY G.ORG_NUM;


-- 指标: G17_2.5.1.2.A.2022
INSERT INTO `G17_2.5.1.2.A.2022`
  (data_date, org_num, item_num, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
         'G17_2.5.1.2.A.2022' AS ITEM_NUM,
         SUM(TRANS_AMT)
    FROM CBRC_L_TRAN_TX_TEMP A --SMTMODS_L_TRAN_TX
   WHERE
  -- AND TRANS_CHANNEL = 'WLPJ' /*网联*/
  -- AND TRAN_STS = 'A' /*交易状态：正常*/
  --AND TRA_MED_NAME='11'   /*交易介质名称 ：借记卡*/
  --OPPO_ORG_NUM IN ('Z2007933000010', 'Z2004944000010')
    TRANS_INCOME_TYPE = '2' /*资金收付标志：付*/
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;


-- 指标: G17_3.6.C.2022
INSERT INTO `G17_3.6.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.6.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.6循环信用账户透支余额（万元）%';

INSERT INTO `G17_3.6.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.6.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.6循环信用账户透支余额（万元）%';


-- 指标: G17_7.4.A
INSERT INTO `G17_7.4.A`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         CASE
           WHEN SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6') THEN
            A.ORG_NUM
           ELSE
            '009803'
         END,
         'G17_7.4.A' AS ITEM_NUM,
         COUNT(DISTINCT A.EQUIPMENT_NBR)
    FROM SMTMODS_L_PUBL_EQUIPMENT A --自助设备信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.EQUIPMENT_TYP = 'B' --B:POS
     AND A.EQUIPMENT_STS = 'A' --A:有效
   GROUP BY CASE
              WHEN SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6') THEN
               A.ORG_NUM
              ELSE
               '009803'
            END
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_7.4.A' AS ITEM_NUM,
         TO_NUMBER(NVL(T.A_ITEM_VAL, '0')) AS ITEM_NUM
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%7.4POS设备台数（台）%';

DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G17'
       AND T.ORG_NUM ='009803'
       AND (  T.ITEM_NUM IN ('G17_7.1.A',
         'G17_7.2.A', 'G17_7.3.A', 'G17_7.4.A'))
       AND T.FLAG = '2';

INSERT INTO `G17_7.4.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803',
             'G17_7.4.A' AS ITEM_NUM,
             COUNT(DISTINCT A.EQUIPMENT_NBR)
        FROM SMTMODS_L_PUBL_EQUIPMENT A --自助设备信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.EQUIPMENT_TYP = 'B' --B:POS
         AND A.EQUIPMENT_STS = 'A' --A:有效
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_7.4.A' AS ITEM_NUM,
             TO_NUMBER(NVL(T.A_ITEM_VAL, '0')) AS ITEM_NUM
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%7.4POS设备台数（台）%';


-- 指标: G17_7.1.A
INSERT INTO `G17_7.1.A`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_7.1.A' AS ITEM_NUM,
         COUNT(DISTINCT A.ORG_NUM)
    FROM SMTMODS_L_PUBL_ORG_BRA A --机构表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.ORG_TYP = '4' --4:支行
     AND A.ORG_STATUS = 'A' --A:有效
     AND (A.ORG_NUM NOT LIKE '5%' OR A.ORG_NUM NOT LIKE '6%')
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
         END,
         'G17_7.1.A' AS ITEM_NUM,
         COUNT(1)
    FROM SMTMODS_L_PUBL_ORG_BRA A --机构表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.ORG_NAM LIKE '%支行%'
     AND A.ORG_STATUS = 'A' --A:有效
     AND (A.ORG_NUM LIKE '5%' OR A.ORG_NUM LIKE '6%')
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
            END

  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_7.1.A' AS ITEM_NUM,
         TO_NUMBER(NVL(T.A_ITEM_VAL, '0')) AS ITEM_NUM
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%7.1银行网点数（个）%';

DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G17'
       AND T.ORG_NUM ='009803'
       AND (  T.ITEM_NUM IN ('G17_7.1.A',
         'G17_7.2.A', 'G17_7.3.A', 'G17_7.4.A'))
       AND T.FLAG = '2';

INSERT INTO `G17_7.1.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803',
             'G17_7.1.A' AS ITEM_NUM,
             COUNT(DISTINCT A.ORG_NUM)
        FROM SMTMODS_L_PUBL_ORG_BRA A --机构表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_TYP = '4' --4:支行
         AND A.ORG_STATUS = 'A' --A:有效
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_7.1.A' AS ITEM_NUM,
             TO_NUMBER(NVL(T.A_ITEM_VAL, '0')) AS ITEM_NUM
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%7.1银行网点数（个）%';


-- 指标: G17_6.4.3.C.2022
--6.4.3    61-90天(M3)贷记卡
INSERT INTO `G17_6.4.3.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.3.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.3    61-90天(M3)%';

--6.4.3    61-90天(M3)贷记卡
    INSERT INTO `G17_6.4.3.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.4.3.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.4.3    61-90天(M3)%';


-- 指标: G17_2.2.A
INSERT INTO `G17_2.2.A`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
         'G17_2.2.A' AS ITEM_NUM,
         SUM(A.TRANAMT)
    FROM CBRC_L_TRAN_CARD_TX_TEMP A --卡交易信息表
   WHERE A.TRANTYPE = '02' --02:取现
     AND A.CARDKIND = '1' --1:借记卡
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;


-- 指标: G17_2.1.A
--------------------------------------------------------------2.1本期消费金额（万元）借记卡----------------------------------------------

INSERT INTO `G17_2.1.A`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
         'G17_2.1.A' AS ITEM_NUM,
         SUM(A.TRANAMT)
    FROM CBRC_L_TRAN_CARD_TX_TEMP A --卡交易信息表
   WHERE A.TRANTYPE = '01' --01:消费
     AND A.CARDKIND = '1' --1:借记卡
  --AND A.TX_DT IN (TRUNC(TO_DATE(I_DATADATE, 'YYYY')));


-- 指标: G17_3.4.2.C.2021
INSERT INTO `G17_3.4.2.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.2其中：分期业务应收账款余额（万元）%';

INSERT INTO `G17_3.4.2.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.4.2.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.4.2其中：分期业务应收账款余额（万元）%';


-- 指标: G17_4.5.C.2022
INSERT INTO `G17_4.5.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_4.5.C.2022' AS ITEM_NUM,
         SUM(case
               when t.PAYMENT_PROPERTY = '1' then
                T.TX_AMT * U.CCY_RATE
               when t.PAYMENT_PROPERTY = '2' then
                T.TX_AMT * U.CCY_RATE * -1
             end) / 1.06 AS ITEM_VAL
    FROM CBRC_L_TRAN_ACCT_INNER_TX_TMP T
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = T.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE T.REMARK LIKE '%分润%'
     AND T.ACCT_NUM IN ('9019840302000094', '90198403020000941') -- 9019840302000094 预借现金手续费;

INSERT INTO `G17_4.5.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803' AS ORG_NUM,
         G.ORG_NUM AS ORG_NUM,
         'G17_4.7.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_L_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = I_DATADATE
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD = '60210601' --60210601  银行卡结算业务收入
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_4.7.C.2022' AS ITEM_NUM,
         SUM(ITEM_VAL) * -1 AS ITEM_VAL
    FROM CBRC_G17_DATA_COLLECT_TMP
   WHERE DATA_DATE = I_DATADATE
     AND ITEM_NUM IN
         ('G17_4.3.1.C.2022', 'G17_4.4.1.C.2022', 'G17_4.5.C.2022');

INSERT INTO `G17_4.5.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803',
             'G17_4.5.C.2022' AS ITEM_NUM,
             SUM(case when   t.PAYMENT_PROPERTY='1'  then T.TX_AMT * U.CCY_RATE
                     when  t.PAYMENT_PROPERTY='2' then   T.TX_AMT * U.CCY_RATE*-1 end)/1.06 AS ITEM_VAL
        FROM CBRC_l_tran_acct_inner_tx_tmp T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE TO_CHAR(T.TX_DATE, 'YYYYMM') BETWEEN SUBSTR(I_DATADATE, 1, 4)||'0101' AND I_DATADATE
         AND T.REMARK LIKE '%分润%'
         AND T.ACCT_NUM = '9019840302000094' -- 9019840302000094 预借现金手续费;

INSERT INTO `G17_4.5.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_4.7.C.2022' AS ITEM_NUM,
             SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD = '60210601'  --60210601  银行卡结算业务收入
         AND G.ORG_NUM = '009803'
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_4.7.C.2022' AS ITEM_NUM,
             SUM(ITEM_VAL) * -1 AS ITEM_VAL
        FROM CBRC_G17_DATA_COLLECT_TMP
       WHERE DATA_DATE = I_DATADATE
         AND ITEM_NUM IN
             ('G17_4.3.1.C.2022', 'G17_4.4.1.C.2022', 'G17_4.5.C.2022');


-- 指标: G17_6.5.2.C.2021
INSERT INTO `G17_6.5.2.C.2021`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.5.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.5.2其中：消费分期逾期91天及以上形成的应收账款余额（万元）%';

INSERT INTO `G17_6.5.2.C.2021`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.5.2.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.5.2其中：消费分期逾期91天及以上形成的应收账款余额（万元）%';


-- 指标: G17_3.1.A
INSERT INTO `G17_3.1.A`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT 
   I_DATADATE AS DATA_DATE,
   CASE
     WHEN A.ORG_NUM LIKE '51%' THEN
      '510000'
     WHEN A.ORG_NUM LIKE '52%' THEN
      '520000'
     WHEN A.ORG_NUM LIKE '53%' THEN
      '530000'
     WHEN A.ORG_NUM LIKE '54%' THEN
      '540000'
     WHEN A.ORG_NUM LIKE '55%' THEN
      '550000'
     WHEN A.ORG_NUM LIKE '56%' THEN
      '560000'
     WHEN A.ORG_NUM LIKE '57%' THEN
      '570000'
     WHEN A.ORG_NUM LIKE '58%' THEN
      '580000'
     WHEN A.ORG_NUM LIKE '59%' THEN
      '590000'
     WHEN A.ORG_NUM LIKE '60%' THEN
      '600000'
     ELSE
      '009803'
   END,
   'G17_3.1.A' AS ITEM_NUM,
   SUM(A.ACCT_BALANCE* U.CCY_RATE)
    FROM SMTMODS_L_ACCT_DEPOSIT A
    LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.DATA_DATE = I_DATADATE
                 AND A.CURR_CD = U.BASIC_CCY
                 AND U.FORWARD_CCY = 'CNY'
   WHERE A.DATA_DATE = I_DATADATE
     AND EXISTS (SELECT 1 FROM
      SMTMODS_L_ACCT_CARD_ACCT_RELATION B
      WHERE B.DATA_DATE = I_DATADATE
      AND A.ACCT_NUM = B.ACCT_NUM
      AND B.DATE_SOURCESD = '借记卡' )
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;


-- 指标: G17_3.4.2.2.1.C.2021
INSERT INTO `G17_3.4.2.2.1.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.2.2.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.2.2.1其中：账单分期应收账款余额（万元）%';

INSERT INTO `G17_3.4.2.2.1.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.4.2.2.1.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.4.2.2.1其中：账单分期应收账款余额（万元）%';


-- 指标: G17_2.5.2.2.A.2022
INSERT INTO `G17_2.5.2.2.A.2022`
  (data_date, org_num, item_num, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
          'G17_2.5.2.2.A.2022' AS ITEM_NUM,
         COUNT(1)
    FROM CBRC_L_TRAN_TX_TEMP A --SMTMODS_L_TRAN_TX
   WHERE OPPO_ORG_NUM IN ('Z2007933000010', 'Z2004944000010')
     AND TRANS_INCOME_TYPE = '2' /*资金收付标志：付*/
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;


-- 指标: G17_1.1.A
INSERT INTO `G17_1.1.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT I_DATADATE AS DATA_DATE,
       CASE
         WHEN A.ORG_NUM LIKE '51%' THEN
          '510000'
         WHEN A.ORG_NUM LIKE '52%' THEN
          '520000'
         WHEN A.ORG_NUM LIKE '53%' THEN
          '530000'
         WHEN A.ORG_NUM LIKE '54%' THEN
          '540000'
         WHEN A.ORG_NUM LIKE '55%' THEN
          '550000'
         WHEN A.ORG_NUM LIKE '56%' THEN
          '560000'
         WHEN A.ORG_NUM LIKE '57%' THEN
          '570000'
         WHEN A.ORG_NUM LIKE '58%' THEN
          '580000'
         WHEN A.ORG_NUM LIKE '59%' THEN
          '590000'
         WHEN A.ORG_NUM LIKE '60%' THEN
          '600000'
         ELSE
          '009803'
       END,
       'G17_1.1.A' AS ITEM_NUM,
       COUNT(DISTINCT A.CARD_NO)
  FROM SMTMODS_L_AGRE_CARD_INFO A --卡基本信息表
 WHERE A.DATA_DATE = I_DATADATE
   AND A.CARDKIND = '1' --1:借记卡
   AND A.CARDSTAT NOT IN ('V', 'Z')
 GROUP BY CASE
            WHEN A.ORG_NUM LIKE '51%' THEN
             '510000'
            WHEN A.ORG_NUM LIKE '52%' THEN
             '520000'
            WHEN A.ORG_NUM LIKE '53%' THEN
             '530000'
            WHEN A.ORG_NUM LIKE '54%' THEN
             '540000'
            WHEN A.ORG_NUM LIKE '55%' THEN
             '550000'
            WHEN A.ORG_NUM LIKE '56%' THEN
             '560000'
            WHEN A.ORG_NUM LIKE '57%' THEN
             '570000'
            WHEN A.ORG_NUM LIKE '58%' THEN
             '580000'
            WHEN A.ORG_NUM LIKE '59%' THEN
             '590000'
            WHEN A.ORG_NUM LIKE '60%' THEN
             '600000'
            ELSE
             '009803'
          END;


-- 指标: G17_7.3.A
INSERT INTO `G17_7.3.A`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         CASE
           WHEN SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6') THEN
            A.ORG_NUM
           ELSE
            '009803'
         END,
         'G17_7.3.A' AS ITEM_NUM,
         COUNT(DISTINCT A.MERCHANT_NBR)
    FROM SMTMODS_L_PUBL_MERCHANT A --特约商户信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.MERCHANT_STS = 'A' --A:有效
   GROUP BY CASE
              WHEN SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6') THEN
               A.ORG_NUM
              ELSE
               '009803'
            END
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_7.3.A' AS ITEM_NUM,
         TO_NUMBER(NVL(T.A_ITEM_VAL, '0')) AS ITEM_NUM
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%7.3特约商户数（户）%';

DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'G17'
       AND T.ORG_NUM ='009803'
       AND (  T.ITEM_NUM IN ('G17_7.1.A',
         'G17_7.2.A', 'G17_7.3.A', 'G17_7.4.A'))
       AND T.FLAG = '2';

INSERT INTO `G17_7.3.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803',
             'G17_7.3.A' AS ITEM_NUM,
             COUNT(DISTINCT A.MERCHANT_NBR)
        FROM SMTMODS_L_PUBL_MERCHANT A --特约商户信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.MERCHANT_STS = 'A' --A:有效
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_7.3.A' AS ITEM_NUM,
             TO_NUMBER(NVL(T.A_ITEM_VAL, '0')) AS ITEM_NUM
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%7.3特约商户数（户）%';


-- 指标: G17_3.8.4.C.2022
INSERT INTO `G17_3.8.4.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.8.4.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.8.4持卡人45岁-55岁（含）的应收账款余额%';

INSERT INTO `G17_3.8.4.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.8.4.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.8.4持卡人45岁-55岁（含）的应收账款余额%';


-- 指标: G17_3.8.1.C.2022
INSERT INTO `G17_3.8.1.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.8.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.8.1持卡人25岁以下（含）的应收账款余额%';

INSERT INTO `G17_3.8.1.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.8.1.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.8.1持卡人25岁以下（含）的应收账款余额%';


-- 指标: G17_5.1.C.2022
INSERT INTO `G17_5.1.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         T.ORG_NUM,
         'G17_5.1.C.2022' AS ITEM_NUM,
         SUM(T.CREDIT_BAL)
    FROM SMTMODS_L_FINA_GL T
   WHERE T.DATA_DATE = I_DATADATE
     AND T.ORG_NUM = '009803'
     AND T.ITEM_CD like '1304'
   GROUP BY T.ORG_NUM;

INSERT INTO `G17_5.1.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803',
             'G17_5.1.C.2022' AS ITEM_NUM,
             SUM(T.CREDIT_BAL)
        FROM SMTMODS_L_FINA_GL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM = '009803'
         AND T.ITEM_CD like '1304%';


-- 指标: G17_3.8.3.C.2022
INSERT INTO `G17_3.8.3.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.8.3.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.8.3持卡人35岁-45岁（含）的应收账款余额%';

INSERT INTO `G17_3.8.3.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.8.3.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.8.3持卡人35岁-45岁（含）的应收账款余额%';


-- 指标: G17_3.3.1.C.2021
INSERT INTO `G17_3.3.1.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.3.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.3.1其中：刷卡消费形成的应收账款余额（万元）%';

INSERT INTO `G17_3.3.1.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.3.1.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.3.1其中：刷卡消费形成的应收账款余额（万元）%';


-- 指标: G17_4.4.1.C.2022
INSERT INTO `G17_4.4.1.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803',
         'G17_4.4.1.C.2022' AS ITEM_NUM,
         SUM(case
               when t.PAYMENT_PROPERTY = '1' then
                T.TX_AMT * U.CCY_RATE
               when t.PAYMENT_PROPERTY = '2' then
                T.TX_AMT * U.CCY_RATE * -1
             end) / 1.06 AS ITEM_VAL
    FROM CBRC_L_TRAN_ACCT_INNER_TX_TMP T
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = T.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE T.REMARK LIKE '%分润%'
     AND T.ACCT_NUM IN ('9019840302000064', '90198403020000641') -- 9019840302000064 滞纳金;

INSERT INTO `G17_4.4.1.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803' AS ORG_NUM,
         G.ORG_NUM AS ORG_NUM,
         'G17_4.7.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_L_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = I_DATADATE
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD = '60210601' --60210601  银行卡结算业务收入
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_4.7.C.2022' AS ITEM_NUM,
         SUM(ITEM_VAL) * -1 AS ITEM_VAL
    FROM CBRC_G17_DATA_COLLECT_TMP
   WHERE DATA_DATE = I_DATADATE
     AND ITEM_NUM IN
         ('G17_4.3.1.C.2022', 'G17_4.4.1.C.2022', 'G17_4.5.C.2022');

INSERT INTO `G17_4.4.1.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803',
             'G17_4.4.1.C.2022' AS ITEM_NUM,
             SUM(case when   t.PAYMENT_PROPERTY='1'  then T.TX_AMT * U.CCY_RATE
                     when  t.PAYMENT_PROPERTY='2' then   T.TX_AMT * U.CCY_RATE*-1 end)/1.06 AS ITEM_VAL
        FROM CBRC_l_tran_acct_inner_tx_tmp T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE TO_CHAR(T.TX_DATE, 'YYYYMM') BETWEEN SUBSTR(I_DATADATE, 1, 4)||'0101' AND I_DATADATE
         AND T.REMARK LIKE '%分润%'
         AND T.ACCT_NUM = '9019840302000064' -- 9019840302000064 滞纳金;

INSERT INTO `G17_4.4.1.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_4.7.C.2022' AS ITEM_NUM,
             SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD = '60210601'  --60210601  银行卡结算业务收入
         AND G.ORG_NUM = '009803'
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_4.7.C.2022' AS ITEM_NUM,
             SUM(ITEM_VAL) * -1 AS ITEM_VAL
        FROM CBRC_G17_DATA_COLLECT_TMP
       WHERE DATA_DATE = I_DATADATE
         AND ITEM_NUM IN
             ('G17_4.3.1.C.2022', 'G17_4.4.1.C.2022', 'G17_4.5.C.2022');


-- 指标: G17_4.7.C.2022
INSERT INTO `G17_4.7.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803' AS ORG_NUM,
         G.ORG_NUM AS ORG_NUM,
         'G17_4.7.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_L_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = I_DATADATE
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD = '60210601' --60210601  银行卡结算业务收入
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_4.7.C.2022' AS ITEM_NUM,
         SUM(ITEM_VAL) * -1 AS ITEM_VAL
    FROM CBRC_G17_DATA_COLLECT_TMP
   WHERE DATA_DATE = I_DATADATE
     AND ITEM_NUM IN
         ('G17_4.3.1.C.2022', 'G17_4.4.1.C.2022', 'G17_4.5.C.2022');

INSERT INTO `G17_4.7.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_4.7.C.2022' AS ITEM_NUM,
             SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD = '60210601'  --60210601  银行卡结算业务收入
         AND G.ORG_NUM = '009803'
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_4.7.C.2022' AS ITEM_NUM,
             SUM(ITEM_VAL) * -1 AS ITEM_VAL
        FROM CBRC_G17_DATA_COLLECT_TMP
       WHERE DATA_DATE = I_DATADATE
         AND ITEM_NUM IN
             ('G17_4.3.1.C.2022', 'G17_4.4.1.C.2022', 'G17_4.5.C.2022');


-- 指标: G17_6.3.C.2022
INSERT INTO `G17_6.3.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.3.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.3未逾期的透支余额(M0)（万元）%';

INSERT INTO `G17_6.3.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.3.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.3未逾期的透支余额(M0)（万元）%';


-- 指标: G17_6.4.4.C.2022
--6.4.4    91-120天(M4)贷记卡
INSERT INTO `G17_6.4.4.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.4.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.4    91-120天(M4)%';

--6.4.4    91-120天(M4)贷记卡
    INSERT INTO `G17_6.4.4.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.4.4.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.4.4    91-120天(M4)%';


-- 指标: G17_4.4.C.2022
INSERT INTO `G17_4.4.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_4.4.C.2022' AS ITEM_NUM,
         SUM(case
               when t.PAYMENT_PROPERTY = '1' then
                T.TX_AMT * U.CCY_RATE
               when t.PAYMENT_PROPERTY = '2' then
                T.TX_AMT * U.CCY_RATE * -1
             end) / 1.06 AS ITEM_VAL
    FROM CBRC_L_TRAN_ACCT_INNER_TX_TMP T
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = T.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE T.REMARK LIKE '%分润%'
     AND T.ACCT_NUM IN ('9019840302000064', '90198403020000641') -- 9019840302000064 滞纳金
  UNION ALL
  SELECT I_DATADATE AS DATA_DATE,
         --'009803',
         G.ORG_NUM,
         'G17_4.4.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_L_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD like '602113' --602113  账户管理业务收入
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM;

INSERT INTO `G17_4.4.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_4.4.C.2022' AS ITEM_NUM,
             SUM(case when   t.PAYMENT_PROPERTY='1'  then T.TX_AMT * U.CCY_RATE
                     when  t.PAYMENT_PROPERTY='2' then   T.TX_AMT * U.CCY_RATE*-1 end)/1.06 AS ITEM_VAL
        FROM CBRC_l_tran_acct_inner_tx_tmp T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE TO_CHAR(T.TX_DATE, 'YYYYMM') BETWEEN SUBSTR(I_DATADATE, 1, 4)||'0101' AND I_DATADATE
         AND T.REMARK LIKE '%分润%'
         AND T.ACCT_NUM = '9019840302000064' -- 9019840302000064 滞纳金
         UNION ALL
       SELECT I_DATADATE AS DATA_DATE,
             '009803',
             'G17_4.4.C.2022' AS ITEM_NUM,
             SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD like '602113%'  --602113  账户管理业务收入
         AND G.ORG_NUM = '009803';


-- 指标: G17_3.4.1.1.C.2021
INSERT INTO `G17_3.4.1.1.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.1.1.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.1.1其中：生息的应收账款余额（万元）%';

INSERT INTO `G17_3.4.1.1.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.4.1.1.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.4.1.1其中：生息的应收账款余额（万元）%';


-- 指标: G17_4.4.2.C.2022
INSERT INTO `G17_4.4.2.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         --'009803' AS ORG_NUM,
         G.ORG_NUM AS ORG_NUM,
         'G17_4.4.2.C.2022' AS ITEM_NUM,
         SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
    FROM SMTMODS_L_FINA_GL G
    LEFT JOIN SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = G.CURR_CD --基准币种
     AND U.FORWARD_CCY = 'CNY' --折算币种
   WHERE G.DATA_DATE = I_DATADATE
     AND G.ITEM_CD like '602113' --602113  账户管理业务收入
     AND G.ORG_NUM = '009803'
   GROUP BY G.ORG_NUM;

INSERT INTO `G17_4.4.2.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_4.4.2.C.2022' AS ITEM_NUM,
             SUM(G.CREDIT_BAL * U.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD like '602113%'  --602113  账户管理业务收入
         AND G.ORG_NUM = '009803'
       GROUP BY G.ORG_NUM;


-- 指标: G17_2.5.2.2.C.2021
INSERT INTO `G17_2.5.2.2.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.5.2.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.5.2.2通过第三方支付机构交易笔数-转入（笔数）%';

INSERT INTO `G17_2.5.2.2.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_2.5.2.2.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%2.5.2.2通过第三方支付机构交易笔数-转入（笔数）%';


-- 指标: G17_6.6.2.C.2021
INSERT INTO `G17_6.6.2.C.2021`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.6.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.6.2其中：现金提取逾期91天及以上形成的应收账款余额（万元）%';

INSERT INTO `G17_6.6.2.C.2021`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.6.2.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.6.2其中：现金提取逾期91天及以上形成的应收账款余额（万元）%';


-- 指标: G17_3.4.1.2.C.2021
INSERT INTO `G17_3.4.1.2.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.1.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4.1.2其中：处于免息期的应收账款余额（万元）%';

INSERT INTO `G17_3.4.1.2.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.4.1.2.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.4.1.2其中：处于免息期的应收账款余额（万元）%';


-- 指标: G17_2.2.C.2022
INSERT INTO `G17_2.2.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.2本年累计取现金额（万元）%';

INSERT INTO `G17_2.2.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_2.2.C.2022' AS ITEM_NUM,
             TO_NUMBER(T.C_ITEM_VAL) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%2.2本年累计取现金额（万元）%';


-- 指标: G17_3.2.C.2022
INSERT INTO `G17_3.2.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.2授信额度（万元）%';

INSERT INTO `G17_3.2.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.2.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.2授信额度（万元）%';


-- 指标: G17_6.4.7.C.2022
--6.4.7    超过180天(M6+)贷记卡
INSERT INTO `G17_6.4.7.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.7.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.7    超过180天(M6+)%';

--6.4.7    超过180天(M6+)贷记卡
    INSERT INTO `G17_6.4.7.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.4.7.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.4.7    超过180天(M6+)%';


-- 指标: G17_1.2.2.C.2022
INSERT INTO `G17_1.2.2.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_1.2.2.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL)
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%1.2.2其中：长期睡眠户（户）%';

INSERT INTO `G17_1.2.2.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_1.2.2.C.2022' AS ITEM_NUM,
             TO_NUMBER(T.C_ITEM_VAL)
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%1.2.2其中：长期睡眠户（户）%';


-- 指标: G17_6.5.C.2021
INSERT INTO `G17_6.5.C.2021`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.5.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.5 分期业务逾期91天及以上形成的应收账款余额（万元）%';

INSERT INTO `G17_6.5.C.2021`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.5.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.5 分期业务逾期91天及以上形成的应收账款余额（万元）%';


-- 指标: G17_6.7.C.2022
INSERT INTO `G17_6.7.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.7.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.7 当年新发生逾期透支余额（万元）%';

INSERT INTO `G17_6.7.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.7.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.7 当年新发生逾期透支余额（万元）%';


-- 指标: G17_3.1.C.2022
INSERT INTO `G17_3.1.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.1存款余额（万元）%';

INSERT INTO `G17_3.1.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.1.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.1存款余额（万元）%';


-- 指标: G17_2.3.A
INSERT INTO `G17_2.3.A`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)

  SELECT I_DATADATE AS DATA_DATE,
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
         'G17_2.3.A' AS ITEM_NUM,
         SUM(A.TRANAMT)
    FROM CBRC_L_TRAN_CARD_TX_TEMP A --卡交易信息表
   WHERE A.TRANTYPE = '03' --03:转账（转出）
     AND A.CARDKIND = '1' --1:借记卡
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;


-- 指标: G17_2.5.1.2.C.2021
INSERT INTO `G17_2.5.1.2.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.5.1.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.5.1.2通过第三方支付机构交易金额-转入（万元）%';

INSERT INTO `G17_2.5.1.2.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_2.5.1.2.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%2.5.1.2通过第三方支付机构交易金额-转入（万元）%';


-- 指标: G17_3.3.2.2.C.2021
INSERT INTO `G17_3.3.2.2.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.3.2.2.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.3.2.2其中：现金提取业务形成的应收账款余额（万元）%';

INSERT INTO `G17_3.3.2.2.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.3.2.2.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.3.2.2其中：现金提取业务形成的应收账款余额（万元）%';


-- 指标: G17_1.1.1.A
INSERT INTO `G17_1.1.1.A`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         CASE
           WHEN A.ORG_NUM LIKE '51%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '52%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '53%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '54%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '55%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '56%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '57%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '58%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '59%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '60%' THEN
            '600000'
           ELSE
            '009803'
         END,
         'G17_1.1.1.A' AS ITEM_NUM,
         COUNT(DISTINCT A.CARD_NO) --1.1.1其中： 睡眠卡（张）
    FROM SMTMODS_L_AGRE_CARD_INFO A --卡基本信息表
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '1' --1:借记卡
     AND A.CARDSTAT NOT IN ('V', 'Z') --V:过期,Z:注销
     AND A.CARD_ACT = 'B'
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;


-- 指标: G17_2.3.C.2022
INSERT INTO `G17_2.3.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_2.3.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%2.3本年累计转账金额（万元）%';

INSERT INTO `G17_2.3.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_2.3.C.2022' AS ITEM_NUM,
             TO_NUMBER(T.C_ITEM_VAL) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%2.3本年累计转账金额（万元）%';


-- 指标: G17_6.4.6.C.2022
--6.4.6    151-180天(M6)贷记卡
INSERT INTO `G17_6.4.6.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_6.4.6.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%6.4.6    151-180天(M6)%';

--6.4.6    151-180天(M6)贷记卡
    INSERT INTO `G17_6.4.6.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_6.4.6.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%6.4.6    151-180天(M6)%';


-- 指标: G17_1.1.1.C.2022
--睡眠卡

INSERT INTO `G17_1.1.1.C.2022`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_1.1.1.C.2022' AS ITEM_NUM,
         TO_NUMBER(T.C_ITEM_VAL)
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%1.1.1其中： 睡眠卡（张）%';

--睡眠卡

    INSERT INTO `G17_1.1.1.C.2022`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_1.1.1.C.2022' AS ITEM_NUM,
             TO_NUMBER(T.C_ITEM_VAL)
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%1.1.1其中： 睡眠卡（张）%';


-- 指标: G17_3.5.C.2022
INSERT INTO `G17_3.5.C.2022`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.5.C.2022' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.5循环信用账户户数（户）%';

INSERT INTO `G17_3.5.C.2022`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.5.C.2022' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.5循环信用账户户数（户）%';


-- 指标: G17_3.4.C.2021
INSERT INTO `G17_3.4.C.2021`
  (data_date, org_num, item_num, ITEM_VAL)
  SELECT I_DATADATE AS DATA_DATE,
         '009803' AS ORG_NUM,
         'G17_3.4.C.2021' AS ITEM_NUM,
         TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
    FROM CBRC_G17_DJK T
   WHERE DATA_DATE = I_DATADATE
     AND TRIM(PROJECT_DESC) LIKE '%3.4应收账款余额-按是否为分期业务划分（万元）%';

INSERT INTO `G17_3.4.C.2021`
      (data_date, org_num, item_num, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009803' AS ORG_NUM,
             'G17_3.4.C.2021' AS ITEM_NUM,
             TO_NUMBER(NVL(T.C_ITEM_VAL, '0')) * 10000 AS ITEM_VAL
        FROM CBRC_g17_djk T
       WHERE DATA_DATE = I_DATADATE
         AND TRIM(PROJECT_DESC) LIKE '%3.4应收账款余额-按是否为分期业务划分（万元）%';


-- 指标: G17_1.2.1.A
INSERT INTO `G17_1.2.1.A`
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT 
   I_DATADATE AS DATA_DATE,
   CASE
     WHEN A.ORG_NUM LIKE '51%' THEN
      '510000'
     WHEN A.ORG_NUM LIKE '52%' THEN
      '520000'
     WHEN A.ORG_NUM LIKE '53%' THEN
      '530000'
     WHEN A.ORG_NUM LIKE '54%' THEN
      '540000'
     WHEN A.ORG_NUM LIKE '55%' THEN
      '550000'
     WHEN A.ORG_NUM LIKE '56%' THEN
      '560000'
     WHEN A.ORG_NUM LIKE '57%' THEN
      '570000'
     WHEN A.ORG_NUM LIKE '58%' THEN
      '580000'
     WHEN A.ORG_NUM LIKE '59%' THEN
      '590000'
     WHEN A.ORG_NUM LIKE '60%' THEN
      '600000'
     ELSE
      '009803'
   END,
   'G17_1.2.1.A' AS ITEM_NUM,
   COUNT(DISTINCT B.ID_NO)
    FROM SMTMODS_L_AGRE_CARD_INFO A --卡基本信息表
    LEFT JOIN SMTMODS_L_CUST_ALL B --全量客户信息表
      ON A.CUST_ID = B.CUST_ID
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CARDKIND = '1' --1:借记卡
     AND A.CARDSTAT NOT IN ('V', 'Z') --V:过期,Z:注销
     AND A.CARD_ACT = 'B' --B:睡眠
     AND A.MAIN_ADDITIONAL_FLG = 'A'
   GROUP BY CASE
              WHEN A.ORG_NUM LIKE '51%' THEN
               '510000'
              WHEN A.ORG_NUM LIKE '52%' THEN
               '520000'
              WHEN A.ORG_NUM LIKE '53%' THEN
               '530000'
              WHEN A.ORG_NUM LIKE '54%' THEN
               '540000'
              WHEN A.ORG_NUM LIKE '55%' THEN
               '550000'
              WHEN A.ORG_NUM LIKE '56%' THEN
               '560000'
              WHEN A.ORG_NUM LIKE '57%' THEN
               '570000'
              WHEN A.ORG_NUM LIKE '58%' THEN
               '580000'
              WHEN A.ORG_NUM LIKE '59%' THEN
               '590000'
              WHEN A.ORG_NUM LIKE '60%' THEN
               '600000'
              ELSE
               '009803'
            END;


