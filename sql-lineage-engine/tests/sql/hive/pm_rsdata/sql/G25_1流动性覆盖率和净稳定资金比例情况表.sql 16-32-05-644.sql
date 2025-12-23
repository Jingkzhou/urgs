-- ============================================================
-- 文件名: G25_1流动性覆盖率和净稳定资金比例情况表.sql
-- 生成时间: 2025-12-18 13:53:39
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
                  A.ORG_NUM,
                  CASE
                    WHEN A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A' THEN
                     'G25_1_1.1.1.3.1.A.2014' --主权国家发行的
                    WHEN A.ISSU_ORG = 'D02' AND A.STOCK_PRO_TYPE LIKE 'C%' THEN
                     'G25_1_1.1.1.3.2.A.2014' ---主权国家担保的
                  END AS ITEM_NUM,
                  SUM(CASE
                        WHEN A.ACCOUNTANT_TYPE = '2' AND A.BOOK_TYPE = 1 THEN
                         (A.PRINCIPAL_BALANCE_CNY *
                         (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) / A.ACCT_BAL_CNY)
                        ELSE
                         (A.ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                         A.ACCT_BAL_CNY)
                      END) AS AMT ---中登净价金额*可用面额/持有仓位
             FROM cbrc_tmp_a_cbrc_bond_bal A --债券投资分析表
            WHERE A.DATA_DATE = I_DATADATE
              AND ACCT_BAL_CNY <> 0   --JLBA202411080004
              AND A.INVEST_TYP = '00'
              AND A.DC_DATE > -30 --逾期超过一个月不取
            GROUP BY A.ORG_NUM,
                     CASE
                       WHEN A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A' THEN
                        'G25_1_1.1.1.3.1.A.2014'
                       WHEN A.ISSU_ORG = 'D02' AND
                            A.STOCK_PRO_TYPE LIKE 'C%' THEN
                        'G25_1_1.1.1.3.2.A.2014'
                     END;

INSERT 
         INTO `__INDICATOR_PLACEHOLDER__`
           (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
           SELECT I_DATADATE AS DATA_DATE,
                  A.ORG_NUM,
                  CASE
                    WHEN A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A' THEN
                     'G25_1_1.1.1.3.1.A.2014' --主权国家发行的
                    WHEN A.ISSU_ORG = 'D02' AND A.STOCK_PRO_TYPE LIKE 'C%' THEN
                     'G25_1_1.1.1.3.2.A.2014' ---主权国家担保的
                  END AS ITEM_NUM,
                  SUM(CASE
                        WHEN A.ACCOUNTANT_TYPE = '2' AND A.BOOK_TYPE = 1 THEN
                         (A.PRINCIPAL_BALANCE_CNY *
                         (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) / A.ACCT_BAL_CNY)
                        ELSE
                         (A.ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                         A.ACCT_BAL_CNY)
                      END) AS AMT ---中登净价金额*可用面额/持有仓位
             FROM cbrc_tmp_a_cbrc_bond_bal A --债券投资分析表
            WHERE A.DATA_DATE = I_DATADATE
              AND ACCT_BAL_CNY <> 0   --JLBA202411080004
              AND A.INVEST_TYP = '00'
              AND A.DC_DATE > -30 --逾期超过一个月不取
            GROUP BY A.ORG_NUM,
                     CASE
                       WHEN A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A' THEN
                        'G25_1_1.1.1.3.1.A.2014'
                       WHEN A.ISSU_ORG = 'D02' AND
                            A.STOCK_PRO_TYPE LIKE 'C%' THEN
                        'G25_1_1.1.1.3.2.A.2014'
                     END
) q_0
INSERT INTO `G25_1_1.1.1.3.2.A.2014` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G25_1_1.1.1.3.1.A.2014` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- 指标: G25_1_1.2.1.1.4.A.2014
--30日内到期  1代发工资,2保证金存款,3存单质押
    --存款按客户分组,50万以内稳定存款（不满足有效存款保险附加标准）,50万以上欠稳定存款（无存款保险）

    INSERT INTO `G25_1_1.2.1.1.4.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.2.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3 T
               WHERE T.DIFF IN ('A', 'C')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
    UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.4.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3 T
               WHERE T.DIFF IN ('B', 'D')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;

-- 除以上3类账户   按客户分组

          INSERT INTO `G25_1_1.2.1.1.4.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM, --明细不能取机构,有可能客户在不同机构与数据,关联时卉产生重复数据,翻倍等
             'G25_1_1.2.1.1.3.A.2014' AS ITEM_NUM, ---2.1.1.3欠稳定存款（有存款保险）
             SUM(CASE
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0) >= 0 THEN
                    A.ACCT_BAL_RMB
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0)
                        < 0 THEN
                    500000
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE IN ('02', '03')
               GROUP BY T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
       UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.4.A.2014' AS ITEM_NUM, ---2.1.1.4欠稳定存款（无存款保险）
             SUM(CASE
                   WHEN (500000 - NVL(A.ACCT_BAL_RMB, 0)  < 0) THEN
                    (NVL(A.ACCT_BAL_RMB, 0) - 500000 )
                   ELSE
                    0
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE IN ('02', '03')
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;

--30日内到期  1代发工资,2保证金存款,3存单质押
    --存款按客户分组,50万以内稳定存款（不满足有效存款保险附加标准）,50万以上欠稳定存款（无存款保险）

    INSERT INTO `G25_1_1.2.1.1.4.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.2.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3 T
               WHERE T.DIFF IN ('A', 'C')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
    UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.4.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3 T
               WHERE T.DIFF IN ('B', 'D')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;

-- 除以上3类账户   按客户分组

          INSERT INTO `G25_1_1.2.1.1.4.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM, --明细不能取机构,有可能客户在不同机构与数据,关联时卉产生重复数据,翻倍等
             'G25_1_1.2.1.1.3.A.2014' AS ITEM_NUM, ---2.1.1.3欠稳定存款（有存款保险）
             SUM(CASE
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0) >= 0 THEN
                    A.ACCT_BAL_RMB
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0)
                        < 0 THEN
                    500000
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE IN ('02', '03')
               GROUP BY T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
       UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.4.A.2014' AS ITEM_NUM, ---2.1.1.4欠稳定存款（无存款保险）
             SUM(CASE
                   WHEN (500000 - NVL(A.ACCT_BAL_RMB, 0)  < 0) THEN
                    (NVL(A.ACCT_BAL_RMB, 0) - 500000 )
                   ELSE
                    0
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE IN ('02', '03')
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;


-- 指标: G25_1_1.2.1.1.2.A.2014
--30日内到期  1代发工资,2保证金存款,3存单质押
    --存款按客户分组,50万以内稳定存款（不满足有效存款保险附加标准）,50万以上欠稳定存款（无存款保险）

    INSERT INTO `G25_1_1.2.1.1.2.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.2.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3 T
               WHERE T.DIFF IN ('A', 'C')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
    UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.4.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3 T
               WHERE T.DIFF IN ('B', 'D')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;

--30日内到期  1代发工资,2保证金存款,3存单质押
    --存款按客户分组,50万以内稳定存款（不满足有效存款保险附加标准）,50万以上欠稳定存款（无存款保险）

    INSERT INTO `G25_1_1.2.1.1.2.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.2.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3 T
               WHERE T.DIFF IN ('A', 'C')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
    UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.4.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL_SAFETY3 T
               WHERE T.DIFF IN ('B', 'D')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;


-- 指标: G25_1_1.2.1.3.2.A.2014
INSERT 
              INTO `G25_1_1.2.1.3.2.A.2014`
                (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
                SELECT I_DATADATE AS DATA_DATE,
                       A.ORG_NUM,
                       CASE
                         WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                          'G25_1_1.2.1.3.2.A.2014' --由一级资产担保的融资交易（与央行以外其他交易对手）
                         WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                          'G25_1_1.2.1.3.3.A.2014' --由2A级资产担保的融资交易（与央行以外其他交易对手）
                       END AS ITEM_NUM,
                  SUM(A.BALANCE * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
             FROM L_AGRE_REPURCHASE_GUARANTY_INFO A
            INNER JOIN V_PUB_FUND_REPURCHASE B
               ON A.ACCT_NUM = B.ACCT_NUM
              AND B.DATA_DATE = I_DATADATE
              AND B.BUSI_TYPE LIKE '2%' --卖出回购
              AND B.ASS_TYPE = '1' --债券
              AND B.BALANCE > 0
             LEFT JOIN CBRC_TMP_L_CUST_BILL_TY C
               ON B.CUST_ID = C.CUST_ID
             LEFT JOIN L_PUBL_RATE TT
               ON TT.CCY_DATE = D_DATADATE_CCY
              AND TT.BASIC_CCY = B.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
            WHERE A.DATA_DATE = I_DATADATE
              AND (C.FINA_CODE_NEW NOT LIKE 'A%' OR C.FINA_CODE_NEW IS NULL) --非货币当局
              AND (B.END_DT - D_DATADATE_CCY >= 0 AND
                  B.END_DT - D_DATADATE_CCY <= 30)
            GROUP BY A.ORG_NUM,
                     CASE
                       WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                        'G25_1_1.2.1.3.2.A.2014'
                       WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                        'G25_1_1.2.1.3.3.A.2014'
                     END;

/* SELECT I_DATADATE AS DATA_DATE,
                       A.ORG_NUM,
                       CASE
                         WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                          'G25_1_1.2.1.3.2.A.2014' --由一级资产担保的融资交易（与央行以外其他交易对手）
                         WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                          'G25_1_1.2.1.3.3.A.2014' --由2A级资产担保的融资交易（与央行以外其他交易对手）
                       END AS ITEM_NUM,
                       SUM(A.BALANCE * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
                  FROM V_PUB_FUND_REPURCHASE A --回购信息表
                  LEFT JOIN CBRC_TMP_L_CUST_BILL_TY B
                    ON A.CUST_ID = B.CUST_ID
                  LEFT JOIN L_PUBL_RATE U
                    ON U.CCY_DATE = D_DATADATE_CCY
                   AND U.BASIC_CCY = A.CURR_CD --基准币种
                   AND U.FORWARD_CCY = 'CNY' --折算币种
                 WHERE A.BUSI_TYPE LIKE '2%' --卖出回购
                   AND (B.FINA_CODE_NEW NOT LIKE 'A%' OR
                       B.FINA_CODE_NEW IS NULL) --非货币当局
                   AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                       A.END_DT - D_DATADATE_CCY <= 30)
                   AND A.DATA_DATE = I_DATADATE
                   AND ASS_TYPE = '1' --债券。回购业务只有债券有评级
                   AND A.BALANCE > 0
                 GROUP BY A.ORG_NUM,
                          CASE
                            WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                             'G25_1_1.2.1.3.2.A.2014'
                            WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                             'G25_1_1.2.1.3.3.A.2014'
                          END;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心,30天以内外币折人民币2111卖出回购余额     
             
           INSERT 
           INTO `G25_1_1.2.1.3.2.A.2014`
             (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
             SELECT 
              I_DATADATE AS DATA_DATE,
              ORG_NUM,
              'G25_1_1.2.1.3.2.A.2014' AS ITEM_NUM,
              SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
               FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL
              WHERE DATA_DATE = I_DATADATE
                AND ACCT_CUR <> 'CNY'
                AND FLAG = '07'
                AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
               GROUP BY ORG_NUM;

INSERT 
              INTO `G25_1_1.2.1.3.2.A.2014`
                (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
                SELECT I_DATADATE AS DATA_DATE,
                       A.ORG_NUM,
                       CASE
                         WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                          'G25_1_1.2.1.3.2.A.2014' --由一级资产担保的融资交易（与央行以外其他交易对手）
                         WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                          'G25_1_1.2.1.3.3.A.2014' --由2A级资产担保的融资交易（与央行以外其他交易对手）
                       END AS ITEM_NUM,
                  SUM(A.BALANCE * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB
             FROM L_AGRE_REPURCHASE_GUARANTY_INFO A
            INNER JOIN V_PUB_FUND_REPURCHASE B
               ON A.ACCT_NUM = B.ACCT_NUM
              AND B.DATA_DATE = I_DATADATE
              AND B.BUSI_TYPE LIKE '2%' --卖出回购
              AND B.ASS_TYPE = '1' --债券
              AND B.BALANCE > 0
             LEFT JOIN CBRC_TMP_L_CUST_BILL_TY C
               ON B.CUST_ID = C.CUST_ID
             LEFT JOIN L_PUBL_RATE TT
               ON TT.CCY_DATE = D_DATADATE_CCY
              AND TT.BASIC_CCY = B.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
            WHERE A.DATA_DATE = I_DATADATE
              AND (C.FINA_CODE_NEW NOT LIKE 'A%' OR C.FINA_CODE_NEW IS NULL) --非货币当局
              AND (B.END_DT - D_DATADATE_CCY >= 0 AND
                  B.END_DT - D_DATADATE_CCY <= 30)
            GROUP BY A.ORG_NUM,
                     CASE
                       WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                        'G25_1_1.2.1.3.2.A.2014'
                       WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                        'G25_1_1.2.1.3.3.A.2014'
                     END;

/* SELECT I_DATADATE AS DATA_DATE,
                       A.ORG_NUM,
                       CASE
                         WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                          'G25_1_1.2.1.3.2.A.2014' --由一级资产担保的融资交易（与央行以外其他交易对手）
                         WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                          'G25_1_1.2.1.3.3.A.2014' --由2A级资产担保的融资交易（与央行以外其他交易对手）
                       END AS ITEM_NUM,
                       SUM(A.BALANCE * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
                  FROM V_PUB_FUND_REPURCHASE A --回购信息表
                  LEFT JOIN CBRC_TMP_L_CUST_BILL_TY B
                    ON A.CUST_ID = B.CUST_ID
                  LEFT JOIN L_PUBL_RATE U
                    ON U.CCY_DATE = D_DATADATE_CCY
                   AND U.BASIC_CCY = A.CURR_CD --基准币种
                   AND U.FORWARD_CCY = 'CNY' --折算币种
                 WHERE A.BUSI_TYPE LIKE '2%' --卖出回购
                   AND (B.FINA_CODE_NEW NOT LIKE 'A%' OR
                       B.FINA_CODE_NEW IS NULL) --非货币当局
                   AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                       A.END_DT - D_DATADATE_CCY <= 30)
                   AND A.DATA_DATE = I_DATADATE
                   AND ASS_TYPE = '1' --债券。回购业务只有债券有评级
                   AND A.BALANCE > 0
                 GROUP BY A.ORG_NUM,
                          CASE
                            WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                             'G25_1_1.2.1.3.2.A.2014'
                            WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                             'G25_1_1.2.1.3.3.A.2014'
                          END;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，30天以内外币折人民币2111卖出回购余额

           INSERT 
           INTO `G25_1_1.2.1.3.2.A.2014`
             (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
             SELECT 
              I_DATADATE AS DATA_DATE,
              ORG_NUM,
              'G25_1_1.2.1.3.2.A.2014' AS ITEM_NUM,
              SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
               FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL
              WHERE DATA_DATE = I_DATADATE
                AND ACCT_CUR <> 'CNY'
                AND FLAG = '07'
                AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
               GROUP BY ORG_NUM;


-- 指标: G25_1_1.2.2.1.2.A.2014
---一个月内到期质押式逆回购本金
                         INSERT 
                         INTO `G25_1_1.2.2.1.2.A.2014`
                           (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
                           SELECT I_DATADATE AS DATA_DATE,
                                  ORG_NUM,
                                  'G25_1_1.2.2.1.2.A.2014' AS ITEM_NUM,
                                  SUM(A.BALANCE * TT.CCY_RATE)
                             FROM V_PUB_FUND_REPURCHASE A
                             LEFT JOIN L_PUBL_RATE TT
                               ON TT.CCY_DATE =
                                  D_DATADATE_CCY
                              AND TT.BASIC_CCY = A.CURR_CD
                              AND TT.FORWARD_CCY = 'CNY'
                            WHERE A.DATA_DATE = I_DATADATE
                              AND A.BUSI_TYPE LIKE '1%' --买入返售
                              AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                                  A.END_DT - D_DATADATE_CCY <= 30)
                              AND A.BALANCE > 0
                            GROUP BY ORG_NUM;

---一个月内到期质押式逆回购本金
                         INSERT 
                         INTO `G25_1_1.2.2.1.2.A.2014`
                           (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
                           SELECT I_DATADATE AS DATA_DATE,
                                  ORG_NUM,
                                  'G25_1_1.2.2.1.2.A.2014' AS ITEM_NUM,
                                  SUM(A.BALANCE * TT.CCY_RATE)
                             FROM V_PUB_FUND_REPURCHASE A
                             LEFT JOIN L_PUBL_RATE TT
                               ON TT.CCY_DATE =
                                  D_DATADATE_CCY
                              AND TT.BASIC_CCY = A.CURR_CD
                              AND TT.FORWARD_CCY = 'CNY'
                            WHERE A.DATA_DATE = I_DATADATE
                              AND A.BUSI_TYPE LIKE '1%' --买入返售
                              AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                                  A.END_DT - D_DATADATE_CCY <= 30)
                              AND A.BALANCE > 0
                            GROUP BY ORG_NUM;


-- 指标: G25_1_1.2.1.2.1.3.A.2014
-- 除以上3类账户   按客户分组

    INSERT INTO `G25_1_1.2.1.2.1.3.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
          SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM, --明细不能取机构,有可能客户在不同机构与数据,关联时卉产生重复数据,翻倍等
             'G25_1_1.2.1.2.1.3.A.2014' AS ITEM_NUM, ---          2.1.2.1.3欠稳定存款（有存款保险）
             SUM(CASE
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0) >= 0 THEN
                    A.ACCT_BAL_RMB
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0)  < 0 THEN
                    500000
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE = '02'
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM

       UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.1.4.A.2014' AS ITEM_NUM, --          2.1.2.1.4欠稳定存款（无存款保险）
             SUM(CASE
                   WHEN (500000 - NVL(A.ACCT_BAL_RMB, 0) < 0) THEN
                    (NVL(A.ACCT_BAL_RMB, 0) - 500000)
                   ELSE
                    0
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE = '02'
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;

-- 除以上3类账户   按客户分组

    INSERT INTO `G25_1_1.2.1.2.1.3.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
          SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM, --明细不能取机构,有可能客户在不同机构与数据,关联时卉产生重复数据,翻倍等
             'G25_1_1.2.1.2.1.3.A.2014' AS ITEM_NUM, ---          2.1.2.1.3欠稳定存款（有存款保险）
             SUM(CASE
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0) >= 0 THEN
                    A.ACCT_BAL_RMB
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0)  < 0 THEN
                    500000
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE = '02'
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM

       UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.1.4.A.2014' AS ITEM_NUM, --          2.1.2.1.4欠稳定存款（无存款保险）
             SUM(CASE
                   WHEN (500000 - NVL(A.ACCT_BAL_RMB, 0) < 0) THEN
                    (NVL(A.ACCT_BAL_RMB, 0) - 500000)
                   ELSE
                    0
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE = '02'
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;


-- 指标: G25_1_1_2.2.2.3.A.2012
--贷款
    --2.2.2完全正常履约协议性现金流入
    INSERT 
    INTO `G25_1_1_2.2.2.3.A.2012` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    --2.2.2.1零售客户
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1_2.2.2.1.A.2012' ITEM_NUM, --折算前
       SUM(T.NEXT_YS + T.NEXT_WEEK + T.NEXT_MONTH) AS CUR_BAL
        FROM CBRC_ID_G25_ITEMDATA_NGI T
       WHERE T.FLAG IN ('LN_01', 'LN_02')
       GROUP BY ORG_NUM
      ----------------------------信用卡部分
      --modiy by djh 20241210 去掉此处填报逻辑,文博确认不填报此处
      /*UNION ALL
      --modiy by djh 20241210 信用卡规则修改信用卡正常部分 G2501不算逾期90天内数据
      SELECT \*+PARALLEL(T,4)*\
       I_DATADATE,
       '009803',
       'G25_1_1_2.2.2.1.A.2012' AS ITEM_NUM,
       sum(T.DEBIT_BAL)
        FROM FDM_LNAC_GL T --信用卡
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_CD='1.6.A'*/
      UNION ALL
      --2.2.2.2小企业   （小、微）
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1_2.2.2.2.A.2012' ITEM_NUM,
       SUM(T.NEXT_YS + T.NEXT_WEEK + T.NEXT_MONTH) AS CUR_BAL
        FROM CBRC_ID_G25_ITEMDATA_NGI T
       WHERE T.FLAG = 'LN_04'
         AND T.CORP_SCALE IN ('S', 'T') --小  微
       GROUP BY ORG_NUM
      UNION ALL
      --2.2.2.3大中企业  （大、中）
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1_2.2.2.3.A.2012' ITEM_NUM,
       SUM(T.NEXT_YS + T.NEXT_WEEK + T.NEXT_MONTH) AS CUR_BAL
        FROM CBRC_ID_G25_ITEMDATA_NGI T
       WHERE T.FLAG = 'LN_04'
         AND T.CORP_SCALE IN ('B', 'M', '9')
       GROUP BY ORG_NUM;

--ADD BY DJH 20240510  投资银行部 009817
    --2.2.2.3大中型企业
    --存量非标业务的一个月内到期的本金+应收利息+其他应收款,包括不良资产
    INSERT 
    INTO `G25_1_1_2.2.2.3.A.2012`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       '009817' AS ORG_NUM,
       'G25_1_1_2.2.2.3.A.2012' AS ITEM_NUM,
       NVL(SUM(ACCT_BAL_RMB + INTEREST_ACCURAL + QTYSK),0) AS ITEM_VAL
        FROM (SELECT A.ORG_NUM,
                     A.MATUR_DATE,
                     SUM(NVL(A.ACCT_BAL_RMB, 0)) AS ACCT_BAL_RMB, --本金
                     SUM(NVL(A.INTEREST_ACCURAL, 0)) AS INTEREST_ACCURAL, --其他应收款
                     SUM(NVL(A.QTYSK, 0)) AS QTYSK --其他应收款
                FROM CBRC_tmp_a_cbrc_loan_bal A
               WHERE A.DATA_DATE = I_DATADATE
                 AND FLAG = '09'
                 AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                     A.MATUR_DATE - D_DATADATE_CCY <= 30)
               GROUP BY A.ORG_NUM, A.MATUR_DATE) A;

--2.2.2.3大中型企业   2.2.2.2小企业
    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT
        INTO `G25_1_1_2.2.2.3.A.2012` 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_6,
           COL_7,
           COL_8,
           COL_9)
          SELECT
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G2501' REP_NUM,
           CASE
             WHEN A.CORP_SCALE IN ('S', 'T') THEN --'S', 'T' 小,微
              'G25_1_1_2.2.2.2.A.2012'
             WHEN A.CORP_SCALE IN ('B', 'M', 'Z') OR A.CORP_SCALE IS NULL THEN
              'G25_1_1_2.2.2.3.A.2012' --'B', 'M', 'Z','NULL' 大 、中、其他、空
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT * T3.CCY_RATE AS TOTAL_VALUE, --贷款余额
           T.LOAN_NUM AS COL1, --贷款编号
           T.CURR_CD AS COL2, --币种
           T.ITEM_CD AS COL3, --科目
           TO_CHAR(T.ACTUAL_MATURITY_DT, 'YYYYMMDD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYYMMDD') AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
           T.ACCT_NUM AS COL6, --贷款合同编号
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           CASE
             WHEN T1.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T1.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T1.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T1.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T1.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8, --五级分类
           CASE
             WHEN A.CORP_SCALE = 'Z' OR A.CORP_SCALE IS NULL THEN
              '其他'
             ELSE
              T4.M_NAME
           END AS COL9 --企业规模
            FROM cbrc_fdm_lnac T
           INNER JOIN cbrc_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
           INNER JOIN L_CUST_C A
              ON T.DATA_DATE = A.DATA_DATE
             AND T.CUST_ID = A.CUST_ID
            LEFT JOIN L_PUBL_RATE T3
              ON T3.DATA_DATE = I_DATADATE
             AND T3.BASIC_CCY = T1.CURR_CD
             AND T3.FORWARD_CCY = 'CNY'
            LEFT JOIN A_REPT_DWD_MAPPING T4
              ON A.CORP_SCALE = T4.M_CODE
             AND T4.M_TABLECODE = 'CORP_SCALE'
           WHERE T.DATA_DATE = I_DATADATE
             AND T.ACCT_TYP NOT LIKE '90%'
             AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --G25去掉转帖现数据129060101面值，来源表验证是129060101面值
             AND T.LOAN_GRADE_CD IN ('1', '2') --五级分类为非不良（正常，关注）
             AND ((T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) --ADD BY DJH 20220518如果逾期天数是空值或者0，但是实际到期日小于等于当前日期数据，放在次日
                 OR (T1.IDENTITY_CODE = '1' AND T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 ))
             AND T1.NEXT_PAYMENT <> 0;

--ADD BY DJH 20240510  投资银行部 009817
    --2.2.2.3大中型企业
    --存量非标业务的一个月内到期的本金+应收利息+其他应收款,包括不良资产
    INSERT 
    INTO `G25_1_1_2.2.2.3.A.2012`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       '009817' AS ORG_NUM,
       'G25_1_1_2.2.2.3.A.2012' AS ITEM_NUM,
       NVL(SUM(ACCT_BAL_RMB + INTEREST_ACCURAL + QTYSK),0) AS ITEM_VAL
        FROM (SELECT A.ORG_NUM,
                     A.MATUR_DATE,
                     SUM(NVL(A.ACCT_BAL_RMB, 0)) AS ACCT_BAL_RMB, --本金
                     SUM(NVL(A.INTEREST_ACCURAL, 0)) AS INTEREST_ACCURAL, --其他应收款
                     SUM(NVL(A.QTYSK, 0)) AS QTYSK --其他应收款
                FROM CBRC_tmp_a_cbrc_loan_bal A
               WHERE A.DATA_DATE = I_DATADATE
                 AND FLAG = '09'
                 AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                     A.MATUR_DATE - D_DATADATE_CCY <= 30)
               GROUP BY A.ORG_NUM, A.MATUR_DATE) A;


-- ========== 逻辑组 7: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.2.4.A.2014',
             sum(CASE
                   WHEN A.ACCT_BAL_RMB - 500000 <= 0 THEN
                    A.ACCT_BAL_RMB
                   when A.ACCT_BAL_RMB - 500000 > 0 then
                    500000
                 end) val
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_BIG T
                LEFT JOIN (SELECT DISTINCT ACCT_NUM
                            FROM CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                           WHERE DATA_DATE = I_DATADATE) T1
                  ON T.ACCT_NUM = T1.ACCT_NUM
               WHERE T.DATA_DATE = I_DATADATE
                 AND T1.ACCT_NUM IS NULL --无业务关系
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
               GROUP BY ORG_NUM
      union all
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.2.5.A.2014',
             sum(case
                   when A.ACCT_BAL_RMB - 500000 > 0 then
                    A.ACCT_BAL_RMB - 500000
                 end) val
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_BIG T
                LEFT JOIN (SELECT DISTINCT ACCT_NUM
                            FROM CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                           WHERE DATA_DATE = I_DATADATE) T1
                  ON T.ACCT_NUM = T1.ACCT_NUM
               WHERE T.DATA_DATE = I_DATADATE
                 AND T1.ACCT_NUM IS NULL --无业务关系
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
               GROUP BY ORG_NUM;

--2.1.2.2.3有业务关系且无存款保险
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )

      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.2.4.A.2014',
             sum(CASE
                   WHEN A.ACCT_BAL_RMB - 500000 <= 0 THEN
                    A.ACCT_BAL_RMB
                   when A.ACCT_BAL_RMB - 500000 > 0 then
                    500000
                 end) val
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_BIG T
                LEFT JOIN (SELECT DISTINCT ACCT_NUM
                            FROM CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                           WHERE DATA_DATE = I_DATADATE) T1
                  ON T.ACCT_NUM = T1.ACCT_NUM
               WHERE T.DATA_DATE = I_DATADATE
                 AND T1.ACCT_NUM IS NULL --无业务关系
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
               GROUP BY ORG_NUM
      union all
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.2.5.A.2014',
             sum(case
                   when A.ACCT_BAL_RMB - 500000 > 0 then
                    A.ACCT_BAL_RMB - 500000
                 end) val
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_BIG T
                LEFT JOIN (SELECT DISTINCT ACCT_NUM
                            FROM CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                           WHERE DATA_DATE = I_DATADATE) T1
                  ON T.ACCT_NUM = T1.ACCT_NUM
               WHERE T.DATA_DATE = I_DATADATE
                 AND T1.ACCT_NUM IS NULL --无业务关系
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
               GROUP BY ORG_NUM
) q_7
INSERT INTO `G25_1_1.2.1.2.2.5.A.2014` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G25_1_1.2.1.2.2.4.A.2014` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *;

-- 指标: G25_1_1.2.1.5.1.A.2014
--表外 2
    --2.1.5其他或有融资义务
    --2.1.5.1无条件可撤销的信用及流动性便利

    INSERT 
    INTO `G25_1_1.2.1.5.1.A.2014` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1.2.1.5.1.A.2014' ITEM_NUM, --折算前
       SUM(T.BAL_1_30) AS CUR_BAL
        FROM CBRC_FDM_CUST_LNAC_INFO T
       WHERE T.FLAG = '03'
       GROUP BY ORG_NUM;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
      --表外 2
      --2.1.5其他或有融资义务
      --2.1.5.1无条件可撤销的信用及流动性便利
      INSERT 
      INTO `G25_1_1.2.1.5.1.A.2014` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_7,
         COL_8,
         COL_9)
        SELECT 
         I_DATADATE,
         CASE
           WHEN T1.ORG_NUM LIKE '5100%' THEN
            '510000'
           WHEN T1.ORG_NUM LIKE '5200%' THEN
            '520000'
           WHEN T1.ORG_NUM LIKE '5300%' THEN
            '530000'
           WHEN T1.ORG_NUM LIKE '5400%' THEN
            '540000'
           WHEN T1.ORG_NUM LIKE '5500%' THEN
            '550000'
           WHEN T1.ORG_NUM LIKE '5600%' THEN
            '560000'
           WHEN T1.ORG_NUM LIKE '5700%' THEN
            '570000'
           WHEN T1.ORG_NUM LIKE '5800%' THEN
            '580000'
           WHEN T1.ORG_NUM LIKE '5900%' THEN
            '590000'
           WHEN T1.ORG_NUM LIKE '6000%' THEN
            '600000'
           ELSE
            '990000'
         END AS ORG_NUM,
         T1.DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G2501' REP_NUM,
         'G25_1_1.2.1.5.1.A.2014' AS ITEM_NUM,
         T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE,
         T1.ACCT_NUM AS COL1, --表外账号
         T1.CURR_CD AS COL2, --币种
         T1.ITEM_CD AS COL3, --科目
         TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') AS COL4, --实际到期日
         T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
         CASE
           WHEN T1.LOAN_GRADE_CD = '1' THEN
            '正常'
           WHEN T1.LOAN_GRADE_CD = '2' THEN
            '关注'
           WHEN T1.LOAN_GRADE_CD = '3' THEN
            '次级'
           WHEN T1.LOAN_GRADE_CD = '4' THEN
            '可疑'
           WHEN T1.LOAN_GRADE_CD = '5' THEN
            '损失'
         END AS COL8, --五级分类
         CASE
           WHEN T1.CORP_SCALE = '9' THEN
            '其他'
           ELSE
            T3.M_NAME
         END AS COL9 --企业规模
          FROM CBRC_FDM_LNAC_PMT_BW T1
          LEFT JOIN L_PUBL_RATE T2
            ON T2.DATA_DATE = I_DATADATE
           AND T2.BASIC_CCY = T1.CURR_CD
           AND T2.FORWARD_CCY = 'CNY'
          LEFT JOIN A_REPT_DWD_MAPPING T3
            ON T1.CORP_SCALE = T3.M_CODE
           AND T3.M_TABLECODE = 'CORP_SCALE'
         WHERE T1.DATA_DATE = I_DATADATE
           AND T1.ITEM_CD = '70300101' --可撤销贷款承诺
           AND T1.IDENTITY_CODE IN ('3', '4')
           AND T1.NEXT_PAYMENT <> 0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
      INSERT
      INTO `G25_1_1.2.1.5.1.A.2014` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_2,
         COL_3)
        SELECT 
         I_DATADATE,
         CASE
           WHEN A.ORG_NUM LIKE '5100%' THEN
            '510000'
           WHEN A.ORG_NUM LIKE '5200%' THEN
            '520000'
           WHEN A.ORG_NUM LIKE '5300%' THEN
            '530000'
           WHEN A.ORG_NUM LIKE '5400%' THEN
            '540000'
           WHEN A.ORG_NUM LIKE '5500%' THEN
            '550000'
           WHEN A.ORG_NUM LIKE '5600%' THEN
            '560000'
           WHEN A.ORG_NUM LIKE '5700%' THEN
            '570000'
           WHEN A.ORG_NUM LIKE '5800%' THEN
            '580000'
           WHEN A.ORG_NUM LIKE '5900%' THEN
            '590000'
           WHEN A.ORG_NUM LIKE '6000%' THEN
            '600000'
           ELSE
            '990000'
         END AS ORG_NUM,
         '' DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G2501' REP_NUM,
         'G25_1_1.2.1.5.1.A.2014' AS ITEM_NUM,
         A.CREDIT_BAL * B.CCY_RATE AS TOTAL_VALUE,
         A.CURR_CD AS COL2, --币种
         A.ITEM_CD AS COL3 --科目
          FROM V_PUB_IDX_FINA_GL A
          LEFT JOIN L_PUBL_RATE B
            ON A.DATA_DATE = B.DATA_DATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD = '70300301' --商票保贴承诺从总账取数
           AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
           AND ORG_NUM NOT LIKE '%0000'
           AND ORG_NUM NOT IN ( /*'510000',*/ --磐石吉银村镇银行
                               '222222', --东盛除双阳汇总
                               '333333', --新双阳
                               '444444', --净月潭除双阳
                               '555555') --长春分行（除双阳、榆树、农安）
           AND A.CREDIT_BAL <> 0;

--17.表外项目
    --17.1信用和流动性便利（可无条件撤销） 60301可撤销贷款承诺、商票放在6月内
    INSERT INTO `G25_1_1.2.1.5.1.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.16.1.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G2501'
         AND ITEM_NUM = 'G25_1_1.2.1.5.1.A.2014'
       GROUP BY T.ORG_NUM;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --17.表外项目
    --17.1信用和流动性便利（可无条件撤销） 60301可撤销贷款承诺、商票放在6月内
    INSERT 
      INTO `G25_1_1.2.1.5.1.A.2014` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_7,
         COL_8)
        SELECT DATA_DATE,
               ORG_NUM,
               DATA_DEPARTMENT,
               SYS_NAM,
               'G2502' AS REP_NUM,
               'G25_2_2.16.1.A.2016' AS ITEM_NUM,
               TOTAL_VALUE,
               COL_1,
               COL_2,
               COL_3,
               COL_4,
               COL_7,
               COL_8
          FROM CBRC_A_REPT_DWD_G2501
         WHERE ITEM_NUM = 'G25_1_1.2.1.5.1.A.2014';

/*
    INSERT INTO `G25_1_1.2.1.5.1.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.16.1.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G2501'
         AND ITEM_NUM = 'G25_1_1.2.1.5.1.A.2014'
       GROUP BY T.ORG_NUM;


-- 指标: G25_1_1.2.2.2.6.1.A.2014
--2.2.2.6.1有业务关系的款项 一个月内到期全行的存放同业活期的本金+利息
        INSERT 
        INTO `G25_1_1.2.2.2.6.1.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009820' AS ORG_NUM,
           'G25_1_1.2.2.2.6.1.A.2014' AS ITEM_NUM,
           SUM(ACCT_BAL_RMB) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
             AND ACCT_BAL_RMB <> 0
             AND SUBSTR(A.GL_ITEM_CODE, 1, 6) ='101101' --存放同业活期
             AND A.ACCT_CUR = 'CNY' --取人民币部分,不要外币
             AND A.ORG_NUM NOT LIKE '5%'
             AND A.ORG_NUM NOT LIKE '6%'
          UNION ALL
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.1.A.2014' AS ITEM_NUM,
                 SUM(INTEREST_ACCURAL) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE (A.FLAG = '01' AND SUBSTR(A.GL_ITEM_CODE, 1, 6) ='101101') --存放同业活期 ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM NOT LIKE '5%'
             AND A.ORG_NUM NOT LIKE '6%';

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心,取报告期末业务状况表（机构990000,外币折人民币）,存放同业活期101101借方余额

        INSERT 
        INTO `G25_1_1.2.2.2.6.1.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009801' AS ORG_NUM,
           'G25_1_1.2.2.2.6.1.A.2014' AS ITEM_NUM,
           SUM(DEBIT_BAL) ITEM_VAL
            FROM L_FINA_GL A
           WHERE DATA_DATE = I_DATADATE
             AND CURR_CD = 'CFC'  --外币折人民币
             AND ITEM_CD = '101101'
             AND A.ORG_NUM='990000'
           GROUP BY A.ORG_NUM;

--2.2.2.6.1有业务关系的款项 一个月内到期全行的存放同业活期的本金+利息
        INSERT 
        INTO `G25_1_1.2.2.2.6.1.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009820' AS ORG_NUM,
           'G25_1_1.2.2.2.6.1.A.2014' AS ITEM_NUM,
           SUM(ACCT_BAL_RMB) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
             AND ACCT_BAL_RMB <> 0
             AND SUBSTR(A.GL_ITEM_CODE, 1, 6) ='101101' --存放同业活期
             AND A.ACCT_CUR = 'CNY' --取人民币部分，不要外币
             AND A.ORG_NUM NOT LIKE '5%'
             AND A.ORG_NUM NOT LIKE '6%'
          UNION ALL
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.1.A.2014' AS ITEM_NUM,
                 SUM(INTEREST_ACCURAL) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE (A.FLAG = '01' AND SUBSTR(A.GL_ITEM_CODE, 1, 6) ='101101') --存放同业活期 ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM NOT LIKE '5%'
             AND A.ORG_NUM NOT LIKE '6%';

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，取报告期末业务状况表（机构990000，外币折人民币），存放同业活期101101借方余额

        INSERT 
        INTO `G25_1_1.2.2.2.6.1.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009801' AS ORG_NUM,
           'G25_1_1.2.2.2.6.1.A.2014' AS ITEM_NUM,
           SUM(DEBIT_BAL) ITEM_VAL
            FROM L_FINA_GL A
           WHERE DATA_DATE = I_DATADATE
             AND CURR_CD = 'CFC'  --外币折人民币
             AND ITEM_CD = '101101'
             AND A.ORG_NUM='990000'
           GROUP BY A.ORG_NUM;


-- 指标: G25_1_1_2.2.2.1.A.2012
--贷款
    --2.2.2完全正常履约协议性现金流入
    INSERT 
    INTO `G25_1_1_2.2.2.1.A.2012` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    --2.2.2.1零售客户
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1_2.2.2.1.A.2012' ITEM_NUM, --折算前
       SUM(T.NEXT_YS + T.NEXT_WEEK + T.NEXT_MONTH) AS CUR_BAL
        FROM CBRC_ID_G25_ITEMDATA_NGI T
       WHERE T.FLAG IN ('LN_01', 'LN_02')
       GROUP BY ORG_NUM
      ----------------------------信用卡部分
      --modiy by djh 20241210 去掉此处填报逻辑,文博确认不填报此处
      /*UNION ALL
      --modiy by djh 20241210 信用卡规则修改信用卡正常部分 G2501不算逾期90天内数据
      SELECT \*+PARALLEL(T,4)*\
       I_DATADATE,
       '009803',
       'G25_1_1_2.2.2.1.A.2012' AS ITEM_NUM,
       sum(T.DEBIT_BAL)
        FROM FDM_LNAC_GL T --信用卡
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_CD='1.6.A'*/
      UNION ALL
      --2.2.2.2小企业   （小、微）
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1_2.2.2.2.A.2012' ITEM_NUM,
       SUM(T.NEXT_YS + T.NEXT_WEEK + T.NEXT_MONTH) AS CUR_BAL
        FROM CBRC_ID_G25_ITEMDATA_NGI T
       WHERE T.FLAG = 'LN_04'
         AND T.CORP_SCALE IN ('S', 'T') --小  微
       GROUP BY ORG_NUM
      UNION ALL
      --2.2.2.3大中企业  （大、中）
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1_2.2.2.3.A.2012' ITEM_NUM,
       SUM(T.NEXT_YS + T.NEXT_WEEK + T.NEXT_MONTH) AS CUR_BAL
        FROM CBRC_ID_G25_ITEMDATA_NGI T
       WHERE T.FLAG = 'LN_04'
         AND T.CORP_SCALE IN ('B', 'M', '9')
       GROUP BY ORG_NUM;

---2.2.2.1零售客户   个人贷款=个人经营性贷款+个人消费贷款

    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G25_1_1_2.2.2.1.A.2012` 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_6,
           COL_7,
           COL_8)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G2501' REP_NUM,
           'G25_1_1_2.2.2.1.A.2012' AS ITEM_NUM,
           T1.NEXT_PAYMENT * T3.CCY_RATE AS TOTAL_VALUE, --贷款余额
           T.LOAN_NUM AS COL1, --贷款编号
           T.CURR_CD AS COL2, --币种
           T.ITEM_CD AS COL3, --科目
           TO_CHAR(T.ACTUAL_MATURITY_DT, 'YYYYMMDD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYYMMDD') AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
           T.ACCT_NUM AS COL6, --贷款合同编号
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           CASE
             WHEN T1.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T1.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T1.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T1.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T1.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8 --五级分类
          --'P' AS COL9 --企业规模 零售客户
            FROM cbrc_fdm_lnac T
           INNER JOIN cbrc_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
           INNER JOIN L_CUST_P T2
              ON T.CUST_ID = T2.CUST_ID
             AND T.DATA_DATE = T2.DATA_DATE
            LEFT JOIN L_PUBL_RATE T3
              ON T3.DATA_DATE = I_DATADATE
             AND T3.BASIC_CCY = T1.CURR_CD
             AND T3.FORWARD_CCY = 'CNY'
           WHERE T.DATA_DATE = I_DATADATE
             AND ((T.ACCT_TYP LIKE '0102%' OR T.ACCT_TYP like '04%') --0102 个人经营性    04个体工商户贸易融资  zhoujingkun 20210412
                 OR SUBSTR(T.ACCT_TYP, 1, 4) in ('0199', '0103', '0101')) --0103 个人消费  0199 其他   0101房地产贷款;


-- 指标: G25_1_1.2.1.2.1.2.A.2014
INSERT INTO `G25_1_1.2.1.2.1.2.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
            'G25_1_1.2.1.2.1.2.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3 T
               WHERE T.DIFF IN ('A', 'C')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
    UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
              'G25_1_1.2.1.2.1.4.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3 T
               WHERE T.DIFF IN ('B', 'D')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;

INSERT INTO `G25_1_1.2.1.2.1.2.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
            'G25_1_1.2.1.2.1.2.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3 T
               WHERE T.DIFF IN ('A', 'C')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
    UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
              'G25_1_1.2.1.2.1.4.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3 T
               WHERE T.DIFF IN ('B', 'D')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;


-- 指标: G25_1_1.2.2.2.6.3.A.2014
----ADD BY DJH 20241205,数仓逻辑变更自动取数  2.2.2.6.3其他借款和现金流入  取值中收计提表中剩余期限一个月数据【本期累计计提中收】 ,同G22
 INSERT 
 INTO `G25_1_1.2.2.2.6.3.A.2014` 
   (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
   SELECT I_DATADATE AS DATA_DATE,
          B.ORG_NUM,
          'G25_1_1.2.2.2.6.3.A.2014' ITEM_NUM, --折算前
          SUM(B.ITEM_VAL) --期末产品余额折人民币
     FROM CBRC_g22_data_collect_tmp_ngi B
    WHERE B.ITEM_NUM IN ('G22R_1.5.A',
                         'G22R_1.5.B')
    AND ORG_NUM NOT IN('009804','009820') --ADD BY CHM 金融市场部 G2501 G25_1_1.2.2.2.6.3.A.2014 同G22 G22R_1.5.A口径不一致  --ADD BY DJH 20240510 同业金融部 同G22 G22R_1.5.A口径不一致
    GROUP BY B.ORG_NUM;

INSERT 
             INTO `G25_1_1.2.2.2.6.3.A.2014`
               (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
               SELECT I_DATADATE AS DATA_DATE, ORG_NUM, ITEM_NUM, SUM(AMT)
                 FROM --一个月内到期的同业存单投资账面 + 同业存单应收利息
                      (SELECT ORG_NUM,
                              'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                              SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE +
                                  A.INTEREST_RECEIVABLE * TT.CCY_RATE) AS AMT
                         FROM V_PUB_FUND_CDS_BAL A
                         LEFT JOIN L_PUBL_RATE TT
                           ON TT.CCY_DATE = D_DATADATE_CCY
                          AND TT.BASIC_CCY = A.CURR_CD
                          AND TT.FORWARD_CCY = 'CNY'
                        WHERE A.DATA_DATE = I_DATADATE
                          AND DC_DATE >= 0
                          AND DC_DATE <= 30
                          AND STOCK_PRO_TYPE = 'A' --同业存单
                          AND PRODUCT_PROP = 'A' --持有
                          AND ORG_NUM = '009804' --ADD BY DJH 20240510  与同业金融部单独处理
                        GROUP BY ORG_NUM
                       UNION ALL

                       --一个月内到期逆回购应收利息

                       SELECT ORG_NUM,
                              'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                              SUM(A.ACCRUAL * TT.CCY_RATE) AS AMT
                         FROM V_PUB_FUND_REPURCHASE A
                         LEFT JOIN L_PUBL_RATE TT
                           ON TT.CCY_DATE = D_DATADATE_CCY
                          AND TT.BASIC_CCY = A.CURR_CD
                          AND TT.FORWARD_CCY = 'CNY'
                        WHERE A.DATA_DATE = I_DATADATE
                          AND A.BUSI_TYPE LIKE '1%' --买入返售
                          AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                              A.END_DT - D_DATADATE_CCY <= 30)
                          AND A.END_DT > D_DATADATE_CCY
                          --AND ORG_NUM = '009804'
                        GROUP BY ORG_NUM
                       UNION ALL

                       --一个月到期的转贴现票面金额
                       SELECT ORG_NUM,
                              'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                              SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS AMT
                         FROM L_ACCT_LOAN A
                         LEFT JOIN L_PUBL_RATE TT
                           ON TT.CCY_DATE = D_DATADATE_CCY
                          AND TT.BASIC_CCY = A.CURR_CD
                          AND TT.FORWARD_CCY = 'CNY'
                         LEFT JOIN CBRC_L_PUBL_HOLIDAY_G2501 B
                          ON A.MATURITY_DT = B.HOLIDAY_DATE
                        WHERE A.DATA_DATE = I_DATADATE
                          AND (A.ITEM_CD LIKE '130102%' --以摊余成本计量的转贴现
                              OR ITEM_CD LIKE '130105%') --以公允价值计量变动计入权益的转贴现
                          AND ORG_NUM = '009804'
                          AND (NVL(B.LASTDAY,A.MATURITY_DT) - D_DATADATE_CCY >= 0 AND NVL(B.LASTDAY,A.MATURITY_DT) - D_DATADATE_CCY <= 30)
                        GROUP BY ORG_NUM
                        UNION ALL

                        -- 一个月内债券借贷融出的未到期余额（金额为：融出面额*中登净价价格/100）
                        -- 融出科目72100101 做为主表原因 同一标的存在只有融入没有融出情况 当为这种情况时 融入额是不需要计算的
                       SELECT A.ORG_NUM,'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,SUM(NVL(A.BALANCE,0)-NVL(B.BALANCE,0))AMT
                          FROM (
                                SELECT T.TZBD_ID TZBD_ID,T.ORG_NUM,SUM(T.BALANCE*T.ZD_NET_AMT/100) BALANCE
                                  FROM V_PUB_FUND_MMFUND T
                                 WHERE T.GL_ITEM_CODE = '72100101' -- 债券借贷 应收借出债券 融出
                                   AND T.DATA_DATE = I_DATADATE
                                   AND T.BALANCE <> 0
                                   AND T.DATE_SOURCESD = '康星_债券借贷'
                                   AND T.ORG_NUM = '009804'
                                   AND (T.MATURE_DATE - D_DATADATE_CCY >= 0 AND T.MATURE_DATE - D_DATADATE_CCY <= 30)
                                 GROUP BY T.TZBD_ID, T.GL_ITEM_CODE,T.ORG_NUM) A
                          LEFT JOIN (
                                 SELECT T.TZBD_ID TZBD_ID,T.ORG_NUM, SUM(T.BALANCE*T.ZD_NET_AMT/100) BALANCE
                                  FROM V_PUB_FUND_MMFUND T
                                 WHERE T.GL_ITEM_CODE ='72400101' -- 债券借贷  应付借入债券 融入
                                   AND T.DATA_DATE = I_DATADATE
                                   AND T.BALANCE <> 0
                                   AND T.DATE_SOURCESD = '康星_债券借贷'
                                   AND T.ORG_NUM = '009804'
                                   AND (T.MATURE_DATE - D_DATADATE_CCY >= 0 AND T.MATURE_DATE - D_DATADATE_CCY <= 30)
                                 GROUP BY T.TZBD_ID, T.GL_ITEM_CODE,T.ORG_NUM) B
                                ON A.TZBD_ID = B.TZBD_ID
                          GROUP BY A.ORG_NUM
                        )
                GROUP BY ORG_NUM, ITEM_NUM;

3.委外的投资：科目为11010303,取一个月内到期的账户类型是FVTPL的账户的持有仓位+公允,其中中信信托2笔特殊处理不填报于此）
    +一个月内到期的债券借贷*/
      INSERT 
      INTO `G25_1_1.2.2.2.6.3.A.2014`
        (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
        SELECT 
         I_DATADATE AS DATA_DATE,
         '009820' AS ORG_NUM,
         'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
         SUM(ACCT_BAL_RMB) ITEM_VAL
          FROM CBRC_tmp_a_cbrc_loan_bal A
         WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
           AND ACCT_BAL_RMB <> 0
           AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '103101' --同业活期的保证金账户
           AND A.ACCT_CUR = 'CNY' --取人民币部分,不要外币
           AND A.ORG_NUM NOT LIKE '5%'
           AND A.ORG_NUM NOT LIKE '6%'
         /*  AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
               A.MATUR_DATE - D_DATADATE_CCY <= 30)*/;

--一个月内到期009820机构存放同业定期本金和利息 取全行还是同业金融部？
        INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009820' AS ORG_NUM,
           'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
           SUM(ACCT_BAL_RMB) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
             AND ACCT_BAL_RMB <> 0
             AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '101102' --此处存放同业定期
             AND A.ORG_NUM NOT LIKE '5%'
             AND A.ORG_NUM NOT LIKE '6%'
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND A.MATUR_DATE - D_DATADATE_CCY <= 30)
          UNION ALL
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(INTEREST_ACCURAL) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE (A.FLAG = '01' AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '101102') --存放同业定期  ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
            AND A.ORG_NUM NOT LIKE '5%'
            AND A.ORG_NUM NOT LIKE '6%'
            AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND A.MATUR_DATE - D_DATADATE_CCY <= 30);

--一个月内到期009820机构拆放同业（包括借出同业）本金和利息
        INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB,0)+NVL(INTEREST_ACCURAL,0)) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG = '02' --01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM = '009820'
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND A.MATUR_DATE - D_DATADATE_CCY <= 30);

3.委外的投资：科目为11010303,取一个月内到期的账户类型是FVTPL的账户的持有仓位+公允,其中中信信托2笔特殊处理不填报于此）*/
        INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB,0)+NVL(INTEREST_ACCURAL,0)) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG IN('06') --01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM = '009820'
             AND A.REMAIN_TERM_CODE IN ('A','B','C');

INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB,0)) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG IN('07') --01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM = '009820'
             AND ACCT_NUM NOT IN ('N000310000025496', 'N000310000025495')
             AND A.REMAIN_TERM_CODE IN ('A','B','C');

INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB, 0) + NVL(INTEREST_ACCURAL, 0)) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG = '04' --01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM = '009820'
             AND (DC_DATE >= 0 AND DC_DATE <= 30);

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心,30天以内外币折人民币1302拆放同业余额 + 报告期末业务状况表（990000,外币折人民币）,1031借方余额
        
        INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009801' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB, 0)) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG = '02' -- 02(1302拆出资金)
             AND A.ORG_NUM = '009801'
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATUR_DATE - D_DATADATE_CCY <= 30);

INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009801' AS ORG_NUM,
           'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
           SUM(DEBIT_BAL) ITEM_VAL
            FROM L_FINA_GL A
           WHERE DATA_DATE = I_DATADATE
             AND CURR_CD = 'CFC' --外币折人民币
             AND ITEM_CD = '1031'
             AND A.ORG_NUM='990000'
           GROUP BY A.ITEM_CD, A.ORG_NUM;

----ADD BY DJH 20241205，数仓逻辑变更自动取数  2.2.2.6.3其他借款和现金流入  取值中收计提表中剩余期限一个月数据【本期累计计提中收】 ，同G22
 INSERT 
 INTO `G25_1_1.2.2.2.6.3.A.2014` 
   (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
   SELECT I_DATADATE AS DATA_DATE,
          B.ORG_NUM,
          'G25_1_1.2.2.2.6.3.A.2014' ITEM_NUM, --折算前
          SUM(B.ITEM_VAL) --期末产品余额折人民币
     FROM CBRC_g22_data_collect_tmp_ngi B
    WHERE B.ITEM_NUM IN ('G22R_1.5.A',
                         'G22R_1.5.B')
    AND ORG_NUM NOT IN('009804','009820') --ADD BY CHM 金融市场部 G2501 G25_1_1.2.2.2.6.3.A.2014 同G22 G22R_1.5.A口径不一致  --ADD BY DJH 20240510 同业金融部 同G22 G22R_1.5.A口径不一致
    GROUP BY B.ORG_NUM
    union  all 
    SELECT I_DATADATE AS DATA_DATE,
          B.ORG_NUM,
          'G25_1_1.2.2.2.6.3.A.2014' ITEM_NUM, --折算前
          SUM(nvl(B.TOTAL_VALUE,0)) --期末产品余额折人民币
     FROM CBRC_A_REPT_DWD_G22 B
    WHERE B.ITEM_NUM IN ('G22R_1.5.A',
                         'G22R_1.5.B')
    AND ORG_NUM NOT IN('009804','009820') 
    GROUP BY B.ORG_NUM;

INSERT 
             INTO `G25_1_1.2.2.2.6.3.A.2014`
               (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
               SELECT I_DATADATE AS DATA_DATE, ORG_NUM, ITEM_NUM, SUM(AMT)
                 FROM --一个月内到期的同业存单投资账面 + 同业存单应收利息
                      (SELECT ORG_NUM,
                              'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                              SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE +
                                  A.INTEREST_RECEIVABLE * TT.CCY_RATE) AS AMT
                         FROM V_PUB_FUND_CDS_BAL A
                         LEFT JOIN L_PUBL_RATE TT
                           ON TT.CCY_DATE = D_DATADATE_CCY
                          AND TT.BASIC_CCY = A.CURR_CD
                          AND TT.FORWARD_CCY = 'CNY'
                        WHERE A.DATA_DATE = I_DATADATE
                          AND DC_DATE >= 0
                          AND DC_DATE <= 30
                          AND STOCK_PRO_TYPE = 'A' --同业存单
                          AND PRODUCT_PROP = 'A' --持有
                          AND ORG_NUM = '009804' --ADD BY DJH 20240510  与同业金融部单独处理
                        GROUP BY ORG_NUM
                       UNION ALL

                       --一个月内到期逆回购应收利息

                       SELECT ORG_NUM,
                              'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                              SUM(A.ACCRUAL * TT.CCY_RATE) AS AMT
                         FROM V_PUB_FUND_REPURCHASE A
                         LEFT JOIN L_PUBL_RATE TT
                           ON TT.CCY_DATE = D_DATADATE_CCY
                          AND TT.BASIC_CCY = A.CURR_CD
                          AND TT.FORWARD_CCY = 'CNY'
                        WHERE A.DATA_DATE = I_DATADATE
                          AND A.BUSI_TYPE LIKE '1%' --买入返售
                          AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                              A.END_DT - D_DATADATE_CCY <= 30)
                          AND A.END_DT > D_DATADATE_CCY
                          --AND ORG_NUM = '009804'
                        GROUP BY ORG_NUM
                       UNION ALL

                       --一个月到期的转贴现票面金额
                       SELECT ORG_NUM,
                              'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                              SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS AMT
                         FROM L_ACCT_LOAN A
                         LEFT JOIN L_PUBL_RATE TT
                           ON TT.CCY_DATE = D_DATADATE_CCY
                          AND TT.BASIC_CCY = A.CURR_CD
                          AND TT.FORWARD_CCY = 'CNY'
                         LEFT JOIN CBRC_L_PUBL_HOLIDAY_G2501 B
                          ON A.MATURITY_DT = B.HOLIDAY_DATE
                        WHERE A.DATA_DATE = I_DATADATE
                          AND (A.ITEM_CD LIKE '130102%' --以摊余成本计量的转贴现
                              OR ITEM_CD LIKE '130105%') --以公允价值计量变动计入权益的转贴现
                          AND ORG_NUM = '009804'
                          AND (NVL(B.LASTDAY,A.MATURITY_DT) - D_DATADATE_CCY >= 0 AND NVL(B.LASTDAY,A.MATURITY_DT) - D_DATADATE_CCY <= 30)
                        GROUP BY ORG_NUM
                        UNION ALL

                        -- 一个月内债券借贷融出的未到期余额（金额为：融出面额*中登净价价格/100）
                        -- 融出科目72100101 做为主表原因 同一标的存在只有融入没有融出情况 当为这种情况时 融入额是不需要计算的
                       SELECT A.ORG_NUM,'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,SUM(NVL(A.BALANCE,0)-NVL(B.BALANCE,0))AMT
                          FROM (
                                SELECT T.TZBD_ID TZBD_ID,T.ORG_NUM,SUM(T.BALANCE*T.ZD_NET_AMT/100) BALANCE
                                  FROM V_PUB_FUND_MMFUND T
                                 WHERE T.GL_ITEM_CODE = '72100101' -- 债券借贷 应收借出债券 融出
                                   AND T.DATA_DATE = I_DATADATE
                                   AND T.BALANCE <> 0
                                   AND T.DATE_SOURCESD = '康星_债券借贷'
                                   AND T.ORG_NUM = '009804'
                                   AND (T.MATURE_DATE - D_DATADATE_CCY >= 0 AND T.MATURE_DATE - D_DATADATE_CCY <= 30)
                                 GROUP BY T.TZBD_ID, T.GL_ITEM_CODE,T.ORG_NUM) A
                          LEFT JOIN (
                                 SELECT T.TZBD_ID TZBD_ID,T.ORG_NUM, SUM(T.BALANCE*T.ZD_NET_AMT/100) BALANCE
                                  FROM V_PUB_FUND_MMFUND T
                                 WHERE T.GL_ITEM_CODE ='72400101' -- 债券借贷  应付借入债券 融入
                                   AND T.DATA_DATE = I_DATADATE
                                   AND T.BALANCE <> 0
                                   AND T.DATE_SOURCESD = '康星_债券借贷'
                                   AND T.ORG_NUM = '009804'
                                   AND (T.MATURE_DATE - D_DATADATE_CCY >= 0 AND T.MATURE_DATE - D_DATADATE_CCY <= 30)
                                 GROUP BY T.TZBD_ID, T.GL_ITEM_CODE,T.ORG_NUM) B
                                ON A.TZBD_ID = B.TZBD_ID
                          GROUP BY A.ORG_NUM
                        )
                GROUP BY ORG_NUM, ITEM_NUM;

3.委外的投资：科目为11010303，取一个月内到期的账户类型是FVTPL的账户的持有仓位+公允，其中中信信托2笔特殊处理不填报于此）
    +一个月内到期的债券借贷*/
      INSERT 
      INTO `G25_1_1.2.2.2.6.3.A.2014`
        (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
        SELECT 
         I_DATADATE AS DATA_DATE,
         '009820' AS ORG_NUM,
         'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
         SUM(ACCT_BAL_RMB) ITEM_VAL
          FROM CBRC_tmp_a_cbrc_loan_bal A
         WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
           AND ACCT_BAL_RMB <> 0
           AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '103101' --同业活期的保证金账户
           AND A.ACCT_CUR = 'CNY' --取人民币部分，不要外币
           AND A.ORG_NUM NOT LIKE '5%'
           AND A.ORG_NUM NOT LIKE '6%'
         /*  AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
               A.MATUR_DATE - D_DATADATE_CCY <= 30)*/;

--一个月内到期009820机构存放同业定期本金和利息 取全行还是同业金融部？
        INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009820' AS ORG_NUM,
           'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
           SUM(ACCT_BAL_RMB) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
             AND ACCT_BAL_RMB <> 0
             AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '101102' --此处存放同业定期
             AND A.ORG_NUM NOT LIKE '5%'
             AND A.ORG_NUM NOT LIKE '6%'
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND A.MATUR_DATE - D_DATADATE_CCY <= 30)
          UNION ALL
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(INTEREST_ACCURAL) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE (A.FLAG = '01' AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '101102') --存放同业定期  ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
            AND A.ORG_NUM NOT LIKE '5%'
            AND A.ORG_NUM NOT LIKE '6%'
            AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND A.MATUR_DATE - D_DATADATE_CCY <= 30);

--一个月内到期009820机构拆放同业（包括借出同业）本金和利息
        INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB,0)+NVL(INTEREST_ACCURAL,0)) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG = '02' --01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM = '009820'
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND A.MATUR_DATE - D_DATADATE_CCY <= 30);

3.委外的投资：科目为11010303，取一个月内到期的账户类型是FVTPL的账户的持有仓位+公允，其中中信信托2笔特殊处理不填报于此）*/
        INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB,0)+NVL(INTEREST_ACCURAL,0)) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG IN('06') --01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM = '009820'
             AND A.REMAIN_TERM_CODE IN ('A','B','C');

INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB,0)) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG IN('07') --01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM = '009820'
             AND ACCT_NUM NOT IN ('N000310000025496', 'N000310000025495')
             AND A.REMAIN_TERM_CODE IN ('A','B','C');

INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB, 0) + NVL(INTEREST_ACCURAL, 0)) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG = '04' --01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
             AND A.ORG_NUM = '009820'
             AND (DC_DATE >= 0 AND DC_DATE <= 30);

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，30天以内外币折人民币1302拆放同业余额 + 报告期末业务状况表（990000，外币折人民币），1031借方余额

        INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009801' AS ORG_NUM,
                 'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB, 0)) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG = '02' -- 02(1302拆出资金)
             AND A.ORG_NUM = '009801'
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATUR_DATE - D_DATADATE_CCY <= 30);

INSERT 
        INTO `G25_1_1.2.2.2.6.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009801' AS ORG_NUM,
           'G25_1_1.2.2.2.6.3.A.2014' AS ITEM_NUM,
           SUM(DEBIT_BAL) ITEM_VAL
            FROM L_FINA_GL A
           WHERE DATA_DATE = I_DATADATE
             AND CURR_CD = 'CFC' --外币折人民币
             AND ITEM_CD = '1031'
             AND A.ORG_NUM='990000'
           GROUP BY A.ITEM_CD, A.ORG_NUM;


-- 指标: G25_1_1.2.1.2.1.4.A.2014
INSERT INTO `G25_1_1.2.1.2.1.4.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
            'G25_1_1.2.1.2.1.2.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3 T
               WHERE T.DIFF IN ('A', 'C')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
    UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
              'G25_1_1.2.1.2.1.4.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3 T
               WHERE T.DIFF IN ('B', 'D')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;

-- 除以上3类账户   按客户分组

    INSERT INTO `G25_1_1.2.1.2.1.4.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
          SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM, --明细不能取机构,有可能客户在不同机构与数据,关联时卉产生重复数据,翻倍等
             'G25_1_1.2.1.2.1.3.A.2014' AS ITEM_NUM, ---          2.1.2.1.3欠稳定存款（有存款保险）
             SUM(CASE
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0) >= 0 THEN
                    A.ACCT_BAL_RMB
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0)  < 0 THEN
                    500000
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE = '02'
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM

       UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.1.4.A.2014' AS ITEM_NUM, --          2.1.2.1.4欠稳定存款（无存款保险）
             SUM(CASE
                   WHEN (500000 - NVL(A.ACCT_BAL_RMB, 0) < 0) THEN
                    (NVL(A.ACCT_BAL_RMB, 0) - 500000)
                   ELSE
                    0
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE = '02'
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;

INSERT INTO `G25_1_1.2.1.2.1.4.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
            'G25_1_1.2.1.2.1.2.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3 T
               WHERE T.DIFF IN ('A', 'C')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
    UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
              'G25_1_1.2.1.2.1.4.A.2014',
             SUM(A.ACCT_BAL_RMB) VAL
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL_SAFETY3 T
               WHERE T.DIFF IN ('B', 'D')
               AND (T.REMAIN_TERM_CODE_QX IS NULL OR REMAIN_TERM_CODE_QX <=30)
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;

-- 除以上3类账户   按客户分组

    INSERT INTO `G25_1_1.2.1.2.1.4.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
          SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM, --明细不能取机构,有可能客户在不同机构与数据,关联时卉产生重复数据,翻倍等
             'G25_1_1.2.1.2.1.3.A.2014' AS ITEM_NUM, ---          2.1.2.1.3欠稳定存款（有存款保险）
             SUM(CASE
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0) >= 0 THEN
                    A.ACCT_BAL_RMB
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0)  < 0 THEN
                    500000
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE = '02'
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM

       UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.1.4.A.2014' AS ITEM_NUM, --          2.1.2.1.4欠稳定存款（无存款保险）
             SUM(CASE
                   WHEN (500000 - NVL(A.ACCT_BAL_RMB, 0) < 0) THEN
                    (NVL(A.ACCT_BAL_RMB, 0) - 500000)
                   ELSE
                    0
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_SMALL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE = '02'
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;


-- 指标: G25_1_1_2.2.2.2.A.2012
--贷款
    --2.2.2完全正常履约协议性现金流入
    INSERT 
    INTO `G25_1_1_2.2.2.2.A.2012` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    --2.2.2.1零售客户
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1_2.2.2.1.A.2012' ITEM_NUM, --折算前
       SUM(T.NEXT_YS + T.NEXT_WEEK + T.NEXT_MONTH) AS CUR_BAL
        FROM CBRC_ID_G25_ITEMDATA_NGI T
       WHERE T.FLAG IN ('LN_01', 'LN_02')
       GROUP BY ORG_NUM
      ----------------------------信用卡部分
      --modiy by djh 20241210 去掉此处填报逻辑,文博确认不填报此处
      /*UNION ALL
      --modiy by djh 20241210 信用卡规则修改信用卡正常部分 G2501不算逾期90天内数据
      SELECT \*+PARALLEL(T,4)*\
       I_DATADATE,
       '009803',
       'G25_1_1_2.2.2.1.A.2012' AS ITEM_NUM,
       sum(T.DEBIT_BAL)
        FROM FDM_LNAC_GL T --信用卡
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_CD='1.6.A'*/
      UNION ALL
      --2.2.2.2小企业   （小、微）
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1_2.2.2.2.A.2012' ITEM_NUM,
       SUM(T.NEXT_YS + T.NEXT_WEEK + T.NEXT_MONTH) AS CUR_BAL
        FROM CBRC_ID_G25_ITEMDATA_NGI T
       WHERE T.FLAG = 'LN_04'
         AND T.CORP_SCALE IN ('S', 'T') --小  微
       GROUP BY ORG_NUM
      UNION ALL
      --2.2.2.3大中企业  （大、中）
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1_2.2.2.3.A.2012' ITEM_NUM,
       SUM(T.NEXT_YS + T.NEXT_WEEK + T.NEXT_MONTH) AS CUR_BAL
        FROM CBRC_ID_G25_ITEMDATA_NGI T
       WHERE T.FLAG = 'LN_04'
         AND T.CORP_SCALE IN ('B', 'M', '9')
       GROUP BY ORG_NUM;

--2.2.2.3大中型企业   2.2.2.2小企业
    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT
        INTO `G25_1_1_2.2.2.2.A.2012` 
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_1,
           COL_2,
           COL_3,
           COL_4,
           COL_5,
           COL_6,
           COL_7,
           COL_8,
           COL_9)
          SELECT
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G2501' REP_NUM,
           CASE
             WHEN A.CORP_SCALE IN ('S', 'T') THEN --'S', 'T' 小,微
              'G25_1_1_2.2.2.2.A.2012'
             WHEN A.CORP_SCALE IN ('B', 'M', 'Z') OR A.CORP_SCALE IS NULL THEN
              'G25_1_1_2.2.2.3.A.2012' --'B', 'M', 'Z','NULL' 大 、中、其他、空
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT * T3.CCY_RATE AS TOTAL_VALUE, --贷款余额
           T.LOAN_NUM AS COL1, --贷款编号
           T.CURR_CD AS COL2, --币种
           T.ITEM_CD AS COL3, --科目
           TO_CHAR(T.ACTUAL_MATURITY_DT, 'YYYYMMDD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYYMMDD') AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
           T.ACCT_NUM AS COL6, --贷款合同编号
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           CASE
             WHEN T1.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T1.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T1.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T1.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T1.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8, --五级分类
           CASE
             WHEN A.CORP_SCALE = 'Z' OR A.CORP_SCALE IS NULL THEN
              '其他'
             ELSE
              T4.M_NAME
           END AS COL9 --企业规模
            FROM cbrc_fdm_lnac T
           INNER JOIN cbrc_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
           INNER JOIN L_CUST_C A
              ON T.DATA_DATE = A.DATA_DATE
             AND T.CUST_ID = A.CUST_ID
            LEFT JOIN L_PUBL_RATE T3
              ON T3.DATA_DATE = I_DATADATE
             AND T3.BASIC_CCY = T1.CURR_CD
             AND T3.FORWARD_CCY = 'CNY'
            LEFT JOIN A_REPT_DWD_MAPPING T4
              ON A.CORP_SCALE = T4.M_CODE
             AND T4.M_TABLECODE = 'CORP_SCALE'
           WHERE T.DATA_DATE = I_DATADATE
             AND T.ACCT_TYP NOT LIKE '90%'
             AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --G25去掉转帖现数据129060101面值，来源表验证是129060101面值
             AND T.LOAN_GRADE_CD IN ('1', '2') --五级分类为非不良（正常，关注）
             AND ((T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) --ADD BY DJH 20220518如果逾期天数是空值或者0，但是实际到期日小于等于当前日期数据，放在次日
                 OR (T1.IDENTITY_CODE = '1' AND T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 ))
             AND T1.NEXT_PAYMENT <> 0;


-- ========== 逻辑组 15: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
                A.ORG_NUM,
                CASE
                  WHEN ((A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
                       A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是AA的债券
                       OR A.STOCK_CD IN ('032000573', '032001060')) THEN
                   'G25_1_1.1.2.1.A.2014'
                  WHEN (A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') THEN
                   'G25_1_1.1.2.3.4.A.2014' --地方政府债
                  WHEN (A.APPRAISE_TYPE IN ('5', '6', '7', '8', '9', 'a') AND
                       A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是2B的债券
                   THEN  'G25_1_1.1.2.4.A.2014'
                END AS ITEM_NUM,
                SUM(CASE
                      WHEN A.ACCOUNTANT_TYPE = '2' AND A.BOOK_TYPE = 1 THEN
                       (A.PRINCIPAL_BALANCE_CNY *
                       (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) / A.ACCT_BAL_CNY)
                      ELSE
                       (A.ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                       A.ACCT_BAL_CNY)
                    END) AS AMT ---中登净价金额*可用面额/持有仓位
           FROM cbrc_tmp_a_cbrc_bond_bal A --债券投资分析表
          WHERE A.DATA_DATE = I_DATADATE
            AND ACCT_BAL_CNY <> 0    --JLBA202411080004
            AND A.INVEST_TYP = '00'
            AND A.DC_DATE > -30
          GROUP BY A.ORG_NUM,
                   CASE
                     WHEN ((A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
                          A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是AA的债券
                          OR A.STOCK_CD IN ('032000573', '032001060')) THEN
                      'G25_1_1.1.2.1.A.2014'
                     WHEN (A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') THEN
                      'G25_1_1.1.2.3.4.A.2014' --地方政府债
                     WHEN (A.APPRAISE_TYPE IN ('5', '6', '7', '8', '9', 'a') AND
                          A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是2B的债券
                      THEN  'G25_1_1.1.2.4.A.2014'
                   END;

INSERT 
       INTO `__INDICATOR_PLACEHOLDER__`
         (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT I_DATADATE AS DATA_DATE,
                A.ORG_NUM,
                CASE
                  WHEN ((A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
                       A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券，短期融资券，公司债，企业债，中期票据 且信用评级是AA的债券
                       OR A.STOCK_CD IN ('032000573', '032001060')) THEN
                   'G25_1_1.1.2.1.A.2014'
                  WHEN (A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') THEN
                   'G25_1_1.1.2.3.4.A.2014' --地方政府债
                  WHEN (A.APPRAISE_TYPE IN ('5', '6', '7', '8', '9', 'a') AND
                       A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券，短期融资券，公司债，企业债，中期票据 且信用评级是2B的债券
                   THEN  'G25_1_1.1.2.4.A.2014'
                END AS ITEM_NUM,
                SUM(CASE
                      WHEN A.ACCOUNTANT_TYPE = '2' AND A.BOOK_TYPE = 1 THEN
                       (A.PRINCIPAL_BALANCE_CNY *
                       (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) / A.ACCT_BAL_CNY)
                      ELSE
                       (A.ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                       A.ACCT_BAL_CNY)
                    END) AS AMT ---中登净价金额*可用面额/持有仓位
           FROM cbrc_tmp_a_cbrc_bond_bal A --债券投资分析表
          WHERE A.DATA_DATE = I_DATADATE
            AND ACCT_BAL_CNY <> 0    --JLBA202411080004
            AND A.INVEST_TYP = '00'
            AND A.DC_DATE > -30
          GROUP BY A.ORG_NUM,
                   CASE
                     WHEN ((A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
                          A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券，短期融资券，公司债，企业债，中期票据 且信用评级是AA的债券
                          OR A.STOCK_CD IN ('032000573', '032001060')) THEN
                      'G25_1_1.1.2.1.A.2014'
                     WHEN (A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') THEN
                      'G25_1_1.1.2.3.4.A.2014' --地方政府债
                     WHEN (A.APPRAISE_TYPE IN ('5', '6', '7', '8', '9', 'a') AND
                          A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券，短期融资券，公司债，企业债，中期票据 且信用评级是2B的债券
                      THEN  'G25_1_1.1.2.4.A.2014'
                   END
) q_15
INSERT INTO `G25_1_1.1.2.1.A.2014` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G25_1_1.1.2.3.4.A.2014` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- 指标: G25_1_1.2.1.5.3.A.2014
--2.1.5.3信用证
    INSERT 
    INTO `G25_1_1.2.1.5.3.A.2014` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1.2.1.5.3.A.2014' ITEM_NUM, --折算前
       SUM(T.BAL_1_30) AS CUR_BAL
        FROM CBRC_FDM_CUST_LNAC_INFO T
       WHERE T.FLAG = '05'
       GROUP BY ORG_NUM;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
      --2.1.5.2保函
      --2.1.5.3信用证

      --由于余额，保证金，担保物币种均不一样，因此折币后处理
      INSERT 
      INTO `G25_1_1.2.1.5.3.A.2014` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_7,
         COL_8)
        SELECT 
         I_DATADATE,
         CASE
           WHEN T1.ORG_NUM LIKE '5100%' THEN
            '510000'
           WHEN T1.ORG_NUM LIKE '5200%' THEN
            '520000'
           WHEN T1.ORG_NUM LIKE '5300%' THEN
            '530000'
           WHEN T1.ORG_NUM LIKE '5400%' THEN
            '540000'
           WHEN T1.ORG_NUM LIKE '5500%' THEN
            '550000'
           WHEN T1.ORG_NUM LIKE '5600%' THEN
            '560000'
           WHEN T1.ORG_NUM LIKE '5700%' THEN
            '570000'
           WHEN T1.ORG_NUM LIKE '5800%' THEN
            '580000'
           WHEN T1.ORG_NUM LIKE '5900%' THEN
            '590000'
           WHEN T1.ORG_NUM LIKE '6000%' THEN
            '600000'
           ELSE
            '990000'
         END,
         T1.DEPARTMENTD, --数据条线
         'CBRC' AS SYS_NAM,
         'G2501' REP_NUM,
         CASE
           WHEN SUBSTR(T1.GL_ITEM_CODE, 1, 4) = '7040' THEN --2.1.5.2保函
            'G25_1_1.2.1.5.2.A.2014'
           WHEN SUBSTR(T1.GL_ITEM_CODE, 1, 4) = '7010' THEN --2.1.5.3信用证
            'G25_1_1.2.1.5.3.A.2014'
         END AS ITEM_NUM,
         NVL(T1.BALANCE * T2.CCY_RATE, 0) -
         NVL(T1.SECURITY_AMT * T3.CCY_RATE, 0) - NVL(TM.DEP_AMT, 0) -
         NVL(TM.COLL_BILL_AMOUNT, 0) AS TOTAL_VALUE, --612保函、601-开出信用证 扣除保证金、本行存单、国债敞口部分
         T1.ACCT_NUM AS COL_1, --表外账号
         T1.CURR_CD AS COL2, --币种
         T1.GL_ITEM_CODE AS COL3, --科目
         TO_CHAR(MATURITY_DT, 'YYYYMMDD') AS COL4, --实际到期日
         T1.MATURITY_DT - D_DATADATE_CCY AS COL7, --剩余期限（天数）
         CASE
           WHEN T1.LOAN_GRADE_CD = '1' THEN
            '正常'
           WHEN T1.LOAN_GRADE_CD = '2' THEN
            '关注'
           WHEN T1.LOAN_GRADE_CD = '3' THEN
            '次级'
           WHEN T1.LOAN_GRADE_CD = '4' THEN
            '可疑'
           WHEN T1.LOAN_GRADE_CD = '5' THEN
            '损失'
         END AS COL8 --五级分类
        -- T1.ACCT_TYP, --贷款承诺类型511无条件撤销承诺521不可撤销承诺-循环包销便利522不可撤销承诺-票据发行便利523不可撤销承诺-其他531有条件撤销承诺
          FROM L_ACCT_OBS_LOAN T1
          LEFT JOIN L_PUBL_RATE T2
            ON T2.DATA_DATE = I_DATADATE
           AND T2.BASIC_CCY = T1.CURR_CD --表外余额折币
           AND T2.FORWARD_CCY = 'CNY'
          LEFT JOIN L_PUBL_RATE T3
            ON T3.DATA_DATE = I_DATADATE
           AND T3.BASIC_CCY = T1.SECURITY_CURR --表外保证金折币
           AND T3.FORWARD_CCY = 'CNY'
          LEFT JOIN (SELECT T2.CONTRACT_NUM,
                            SUM(NVL(T4.DEP_AMT * T6.CCY_RATE, 0)) AS DEP_AMT,
                            SUM(NVL(T5.COLL_BILL_AMOUNT * T6.CCY_RATE, 0)) AS COLL_BILL_AMOUNT
                       FROM L_AGRE_GUA_RELATION T2
                       LEFT JOIN L_AGRE_GUARANTEE_RELATION T3
                         ON T2.GUAR_CONTRACT_NUM = T3.GUAR_CONTRACT_NUM
                        AND T3.DATA_DATE = I_DATADATE
                       LEFT JOIN L_AGRE_GUARANTY_INFO T4
                         ON T3.GUARANTEE_SERIAL_NUM =
                            T4.GUARANTEE_SERIAL_NUM
                        AND T4.DATA_DATE = I_DATADATE
                        AND T4.COLL_TYP = 'A0201' --  是本行存单
                       LEFT JOIN L_AGRE_GUARANTY_INFO T5
                         ON T3.GUARANTEE_SERIAL_NUM =
                            T5.GUARANTEE_SERIAL_NUM
                        AND T5.DATA_DATE = I_DATADATE
                        AND T5.COLL_TYP IN ('A0602', 'A0603')
                       LEFT JOIN L_PUBL_RATE T6
                         ON T6.DATA_DATE = I_DATADATE
                        AND T6.BASIC_CCY = T3.CURR_CD --担保物折币
                        AND T6.FORWARD_CCY = 'CNY'
                      WHERE T2.DATA_DATE = I_DATADATE
                      GROUP BY T2.CONTRACT_NUM) TM --押品类型为 A0602一级国家及地区的国债 A0603二级国家及地区的国债
            ON T1.ACCT_NUM = TM.CONTRACT_NUM
         WHERE T1.DATA_DATE = I_DATADATE
           AND (T1.GL_ITEM_CODE LIKE '7010%' OR
               T1.GL_ITEM_CODE LIKE '7040%')
           AND NVL(T1.BALANCE * T2.CCY_RATE, 0) -
               NVL(T1.SECURITY_AMT * T3.CCY_RATE, 0) - NVL(TM.DEP_AMT, 0) -
               NVL(TM.COLL_BILL_AMOUNT, 0) > 0;

--17.3 担保、信用证及其他贸易融资工具 1开出信用证敞口 2保函敞口放在6月内
    INSERT INTO `G25_1_1.2.1.5.3.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.16.3.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G2501'
         AND ITEM_NUM IN
             ('G25_1_1.2.1.5.2.A.2014', 'G25_1_1.2.1.5.3.A.2014')
       GROUP BY T.ORG_NUM;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
      INSERT 
      INTO `G25_1_1.2.1.5.3.A.2014` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_7,
         COL_8)
        SELECT DATA_DATE,
               ORG_NUM,
               DATA_DEPARTMENT,
               SYS_NAM,
               'G2502' AS REP_NUM,
               'G25_2_2.16.3.A.2016' AS ITEM_NUM,
               TOTAL_VALUE,
               COL_1,
               COL_2,
               COL_3,
               COL_4,
               COL_7,
               COL_8
          FROM CBRC_A_REPT_DWD_G2501
         WHERE ITEM_NUM IN
               ('G25_1_1.2.1.5.2.A.2014', 'G25_1_1.2.1.5.3.A.2014');

/*   --17.3 担保、信用证及其他贸易融资工具 1开出信用证敞口 2保函敞口放在6月内
    INSERT INTO `G25_1_1.2.1.5.3.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.16.3.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G2501'
         AND ITEM_NUM IN
             ('G25_1_1.2.1.5.2.A.2014', 'G25_1_1.2.1.5.3.A.2014')
       GROUP BY T.ORG_NUM;


-- 指标: G25_1_1.2.1.6.A.2014
INSERT 
                     INTO `G25_1_1.2.1.6.A.2014`
                       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
                       SELECT I_DATADATE AS DATA_DATE,
                              ORG_NUM,
                              'G25_1_1.2.1.6.A.2014' AS ITEM_NUM,
                              SUM(A.ACCRUAL * TT.CCY_RATE)
                         FROM V_PUB_FUND_REPURCHASE A
                         LEFT JOIN L_PUBL_RATE TT
                           ON TT.CCY_DATE = D_DATADATE_CCY
                          AND TT.BASIC_CCY = A.CURR_CD
                          AND TT.FORWARD_CCY = 'CNY'
                        WHERE A.DATA_DATE = I_DATADATE
                          AND A.BUSI_TYPE LIKE '2%' --卖出回购
                          AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                              A.END_DT - D_DATADATE_CCY <= 30)
                          AND A.BALANCE > 0
                        GROUP BY ORG_NUM;

涉及科目'22310903','22310904','22310905','22310907','22310908','22310909','22310910','22310911'*/

    --一个月内到期009820同业拆入利息
     INSERT 
     INTO `G25_1_1.2.1.6.A.2014`
       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
       SELECT I_DATADATE AS DATA_DATE,
              '009820' AS ORG_NUM,
              'G25_1_1.2.1.6.A.2014' AS ITEM_NUM,
              SUM(INTEREST_ACCURAL) ITEM_VAL
         FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
        WHERE A.FLAG IN ('05','10') --同业拆入应付利息
          AND INTEREST_ACCURAL <> 0
          AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
              A.MATUR_DATE - D_DATADATE_CCY <= 30)
          AND A.ORG_NUM = '009820';

--全行一个月内到期同业存放定期利息
     INSERT 
     INTO `G25_1_1.2.1.6.A.2014`
       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
       SELECT I_DATADATE AS DATA_DATE,
              '009820' AS ORG_NUM,
              'G25_1_1.2.1.6.A.2014' AS ITEM_NUM,
              SUM(A.ACCRUAL * CCY_RATE) ITEM_VAL
         FROM V_PUB_FUND_MMFUND A
         LEFT JOIN L_PUBL_RATE TT
           ON TT.CCY_DATE = D_DATADATE_CCY
          AND TT.BASIC_CCY = A.CURR_CD
          AND TT.FORWARD_CCY = 'CNY'
        WHERE A.DATA_DATE = I_DATADATE
          AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放定期
          AND A.ACCRUAL <> 0
          AND (A.MATURE_DATE - D_DATADATE_CCY >= 0 AND
              A.MATURE_DATE - D_DATADATE_CCY <= 30)
          AND A.ORG_NUM NOT LIKE '5%'
          AND A.ORG_NUM NOT LIKE '6%';

涉及科目'22310903','22310904','22310905','22310907','22310908','22310909','22310910','22310911'
       INSERT 
       INTO `G25_1_1.2.1.6.A.2014`
         (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT I_DATADATE AS DATA_DATE,
                '009820' AS ORG_NUM,
                'G25_1_1.2.1.6.A.2014' AS ITEM_NUM,
                SUM(T.CREDIT_BAL * CCY_RATE) ITEM_VAL
           FROM L_FINA_GL T
           LEFT JOIN L_PUBL_RATE TT
             ON TT.CCY_DATE = D_DATADATE_CCY
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
          WHERE T.ITEM_CD IN ('22310903',
                              '22310904',
                              '22310905',
                              '22310907',
                              '22310908',
                              '22310909',
                              '22310910',
                              '22310911')
            AND T.DATA_DATE = I_DATADATE
            AND T.CURR_CD <> 'BWB'
            AND T.ORG_NUM = '990000';

INSERT 
                     INTO `G25_1_1.2.1.6.A.2014`
                       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
                       SELECT I_DATADATE AS DATA_DATE,
                              ORG_NUM,
                              'G25_1_1.2.1.6.A.2014' AS ITEM_NUM,
                              SUM(A.ACCRUAL * TT.CCY_RATE)
                         FROM V_PUB_FUND_REPURCHASE A
                         LEFT JOIN L_PUBL_RATE TT
                           ON TT.CCY_DATE = D_DATADATE_CCY
                          AND TT.BASIC_CCY = A.CURR_CD
                          AND TT.FORWARD_CCY = 'CNY'
                        WHERE A.DATA_DATE = I_DATADATE
                          AND A.BUSI_TYPE LIKE '2%' --卖出回购
                          AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                              A.END_DT - D_DATADATE_CCY <= 30)
                          AND A.BALANCE > 0
                        GROUP BY ORG_NUM;

涉及科目'22310903','22310904','22310905','22310907','22310908','22310909','22310910','22310911'*/

    --一个月内到期009820同业拆入利息
     INSERT 
     INTO `G25_1_1.2.1.6.A.2014`
       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
       SELECT I_DATADATE AS DATA_DATE,
              '009820' AS ORG_NUM,
              'G25_1_1.2.1.6.A.2014' AS ITEM_NUM,
              SUM(INTEREST_ACCURAL) ITEM_VAL
         FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
        WHERE A.FLAG IN ('05','10') --同业拆入应付利息
          AND INTEREST_ACCURAL <> 0
          AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
              A.MATUR_DATE - D_DATADATE_CCY <= 30)
          AND A.ORG_NUM = '009820';

--全行一个月内到期同业存放定期利息
     INSERT 
     INTO `G25_1_1.2.1.6.A.2014`
       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
       SELECT I_DATADATE AS DATA_DATE,
              '009820' AS ORG_NUM,
              'G25_1_1.2.1.6.A.2014' AS ITEM_NUM,
              SUM(A.ACCRUAL * CCY_RATE) ITEM_VAL
         FROM V_PUB_FUND_MMFUND A
         LEFT JOIN L_PUBL_RATE TT
           ON TT.CCY_DATE = D_DATADATE_CCY
          AND TT.BASIC_CCY = A.CURR_CD
          AND TT.FORWARD_CCY = 'CNY'
        WHERE A.DATA_DATE = I_DATADATE
          AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放定期
          AND A.ACCRUAL <> 0
          AND (A.MATURE_DATE - D_DATADATE_CCY >= 0 AND
              A.MATURE_DATE - D_DATADATE_CCY <= 30)
          AND A.ORG_NUM NOT LIKE '5%'
          AND A.ORG_NUM NOT LIKE '6%';

涉及科目'22310903','22310904','22310905','22310907','22310908','22310909','22310910','22310911'
       INSERT 
       INTO `G25_1_1.2.1.6.A.2014`
         (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT I_DATADATE AS DATA_DATE,
                '009820' AS ORG_NUM,
                'G25_1_1.2.1.6.A.2014' AS ITEM_NUM,
                SUM(T.CREDIT_BAL * CCY_RATE) ITEM_VAL
           FROM L_FINA_GL T
           LEFT JOIN L_PUBL_RATE TT
             ON TT.CCY_DATE = D_DATADATE_CCY
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
          WHERE T.ITEM_CD IN ('22310903',
                              '22310904',
                              '22310905',
                              '22310907',
                              '22310908',
                              '22310909',
                              '22310910',
                              '22310911')
            AND T.DATA_DATE = I_DATADATE
            AND T.CURR_CD <> 'BWB'
            AND T.ORG_NUM = '990000';


-- 指标: G25_1_1.2.1.4.10.2.1.A.2014
--2.1.4.10.2大中型企业
    --2.1.4.10.2.1信用便利
    INSERT 
    INTO `G25_1_1.2.1.4.10.2.1.A.2014` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1.2.1.4.10.2.1.A.2014' ITEM_NUM, --折算前
       SUM(T.BAL_1_30) AS CUR_BAL
        FROM CBRC_FDM_CUST_LNAC_INFO T
       WHERE T.FLAG = '02'
       GROUP BY ORG_NUM;

/* 1、承兑汇票 正常表外30以内+所有逾期  逾期与G21一样都取
    2、未使用额度 30天内有效的未使用额度，不需要限制到期日所有都取
    3、不可撤销贷款承诺*/


        -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
          --表外 1
          --2.1.4.10未提取的不可无条件撤销的信用便利和流动性便利
          --2.1.4.10.1零售客户和小企业
          --2.1.4.10.2大中型企业
          --2.1.4.10.2.1信用便利

         INSERT 
         INTO `G25_1_1.2.1.4.10.2.1.A.2014` 
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_1,
            COL_2,
            COL_3,
            COL_4,
            COL_7,
            COL_8,
            COL_9)
           SELECT 
            I_DATADATE,
            CASE
              WHEN T1.ORG_NUM LIKE '5100%' THEN
               '510000'
              WHEN T1.ORG_NUM LIKE '5200%' THEN
               '520000'
              WHEN T1.ORG_NUM LIKE '5300%' THEN
               '530000'
              WHEN T1.ORG_NUM LIKE '5400%' THEN
               '540000'
              WHEN T1.ORG_NUM LIKE '5500%' THEN
               '550000'
              WHEN T1.ORG_NUM LIKE '5600%' THEN
               '560000'
              WHEN T1.ORG_NUM LIKE '5700%' THEN
               '570000'
              WHEN T1.ORG_NUM LIKE '5800%' THEN
               '580000'
              WHEN T1.ORG_NUM LIKE '5900%' THEN
               '590000'
              WHEN T1.ORG_NUM LIKE '6000%' THEN
               '600000'
              ELSE
               '990000'
            END AS ORG_NUM,
            T1.DATA_DEPARTMENT, --数据条线
            'CBRC' AS SYS_NAM,
            'G2501' REP_NUM,
            CASE
              WHEN T1.CORP_SCALE IN ('P', 'S', 'T') THEN --零售  小型  微型
               'G25_1_1.2.1.4.10.1.A.2014'
              WHEN T1.CORP_SCALE IN ('B', 'M', '9') THEN --大型   中型  其他
               'G25_1_1.2.1.4.10.2.1.A.2014'
            END AS ITEM_NUM,
            T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE, --贷款余额
            T1.ACCT_NUM AS COL1, --表外账号
            T1.CURR_CD AS COL2, --币种
            T1.ITEM_CD AS COL3, --科目
            TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') AS COL4, --到期日
            T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
            CASE
              WHEN T1.LOAN_GRADE_CD = '1' THEN
               '正常'
              WHEN T1.LOAN_GRADE_CD = '2' THEN
               '关注'
              WHEN T1.LOAN_GRADE_CD = '3' THEN
               '次级'
              WHEN T1.LOAN_GRADE_CD = '4' THEN
               '可疑'
              WHEN T1.LOAN_GRADE_CD = '5' THEN
               '损失'
            END AS COL8, --五级分类
            CASE
              WHEN T1.CORP_SCALE = '9' THEN
               '其他'
              ELSE
               T3.M_NAME
            END AS COL9 --企业规模
             FROM CBRC_FDM_LNAC_PMT_BW T1
             LEFT JOIN L_PUBL_RATE T2
               ON T2.DATA_DATE = I_DATADATE
              AND T2.BASIC_CCY = T1.CURR_CD
              AND T2.FORWARD_CCY = 'CNY'
             LEFT JOIN A_REPT_DWD_MAPPING T3
               ON T1.CORP_SCALE = T3.M_CODE
              AND T3.M_TABLECODE = 'CORP_SCALE'
            WHERE ((T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.PMT_REMAIN_TERM_C <= 30) OR T1.PMT_REMAIN_TERM_C <= 0)
              AND T1.ITEM_CD in ('70200101', '70200201', '70300201') --应收银行承兑汇票款项、应付银行承兑汇票款项、不可撤销贷款承诺
              AND T1.NEXT_PAYMENT <> 0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
         INSERT 
         INTO `G25_1_1.2.1.4.10.2.1.A.2014` 
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_1,
            COL_2,
            COL_3,
            COL_4,
            COL_7,
            COL_8,
            COL_9)
           SELECT 
            I_DATADATE,
            CASE
              WHEN T1.ORG_NUM LIKE '5100%' THEN
               '510000'
              WHEN T1.ORG_NUM LIKE '5200%' THEN
               '520000'
              WHEN T1.ORG_NUM LIKE '5300%' THEN
               '530000'
              WHEN T1.ORG_NUM LIKE '5400%' THEN
               '540000'
              WHEN T1.ORG_NUM LIKE '5500%' THEN
               '550000'
              WHEN T1.ORG_NUM LIKE '5600%' THEN
               '560000'
              WHEN T1.ORG_NUM LIKE '5700%' THEN
               '570000'
              WHEN T1.ORG_NUM LIKE '5800%' THEN
               '580000'
              WHEN T1.ORG_NUM LIKE '5900%' THEN
               '590000'
              WHEN T1.ORG_NUM LIKE '6000%' THEN
               '600000'
              ELSE
               '990000'
            END AS ORG_NUM,
            T1.DATA_DEPARTMENT, --数据条线
            'CBRC' AS SYS_NAM,
            'G2501' REP_NUM,
            CASE
              WHEN T1.CORP_SCALE IN ('P', 'S', 'T') THEN --零售  小型  微型
               'G25_1_1.2.1.4.10.1.A.2014'
              WHEN T1.CORP_SCALE IN ('B', 'M', '9') THEN --大型   中型  其他
               'G25_1_1.2.1.4.10.2.1.A.2014'
            END AS ITEM_NUM,
            T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE, --贷款余额
            T1.ACCT_NUM AS COL1, --表外账号
            T1.CURR_CD AS COL2, --币种
            T1.ITEM_CD AS COL3, --科目
            TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') AS COL4, --实际到期日
            T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
            CASE
              WHEN T1.LOAN_GRADE_CD = '1' THEN
               '正常'
              WHEN T1.LOAN_GRADE_CD = '2' THEN
               '关注'
              WHEN T1.LOAN_GRADE_CD = '3' THEN
               '次级'
              WHEN T1.LOAN_GRADE_CD = '4' THEN
               '可疑'
              WHEN T1.LOAN_GRADE_CD = '5' THEN
               '损失'
            END AS COL8, --五级分类
            CASE
              WHEN T1.CORP_SCALE = '9' THEN
               '其他'
              ELSE
               T3.M_NAME
            END AS COL9 --企业规模
             FROM CBRC_FDM_LNAC_PMT_BW T1
             LEFT JOIN L_PUBL_RATE T2
               ON T2.DATA_DATE = I_DATADATE
              AND T2.BASIC_CCY = T1.CURR_CD
              AND T2.FORWARD_CCY = 'CNY'
             LEFT JOIN A_REPT_DWD_MAPPING T3
               ON T1.CORP_SCALE = T3.M_CODE
              AND T3.M_TABLECODE = 'CORP_SCALE'
            WHERE T1.ITEM_CD = '60302_G25'
              AND T1.NEXT_PAYMENT <> 0;

--17.2信用和流动性便利（不可无条件撤销） 信用卡和承兑汇票、未使用授信额度放在6月内
    INSERT INTO `G25_1_1.2.1.4.10.2.1.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.16.2.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G2501'
         AND ITEM_NUM IN
             ('G25_1_1.2.1.4.10.1.A.2014', 'G25_1_1.2.1.4.10.2.1.A.2014')
       GROUP BY T.ORG_NUM;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --17.2信用和流动性便利（不可无条件撤销） 信用卡和承兑汇票、未使用授信额度放在6月内
      INSERT
      INTO `G25_1_1.2.1.4.10.2.1.A.2014` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_7,
         COL_8)
        SELECT DATA_DATE,
               ORG_NUM,
               DATA_DEPARTMENT,
               SYS_NAM,
               'G2502' AS REP_NUM,
               'G25_2_2.16.2.A.2016' AS ITEM_NUM,
               TOTAL_VALUE,
               COL_1,
               COL_2,
               COL_3,
               COL_4,
               COL_7,
               COL_8
          FROM CBRC_A_REPT_DWD_G2501
         WHERE ITEM_NUM IN
               ('G25_1_1.2.1.4.10.1.A.2014', 'G25_1_1.2.1.4.10.2.1.A.2014');

/* INSERT INTO `G25_1_1.2.1.4.10.2.1.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.16.2.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G2501'
         AND ITEM_NUM IN
             ('G25_1_1.2.1.4.10.1.A.2014', 'G25_1_1.2.1.4.10.2.1.A.2014')
       GROUP BY T.ORG_NUM;


-- 指标: G25_1_1.2.1.2.4.3.A.2014
--2.1.2.4.3银行存款,有业务关系且无存款保险
   -- 一个月内到期的同业拆入+同业存放定期（全行的定期报送在009820）本金+结算性同业存放活期(20120101和20120102的全行数取进009820,从业务状况表取,都属于1个月内)
   -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心30天以内外币折人民币2003拆入资金本金
        INSERT 
        INTO `G25_1_1.2.1.2.4.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 A.ORG_NUM,
                 'G25_1_1.2.1.2.4.3.A.2014' AS ITEM_NUM,
                 SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
            FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
           WHERE A.FLAG  IN ('05','10') --同业拆入(有其他机构) 转贷款
             AND ACCT_BAL_RMB <> 0
             AND A.ORG_NUM IN ('009804', '009820') 
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATUR_DATE - D_DATADATE_CCY <= 30)
           GROUP BY A.ORG_NUM;

INSERT 
        INTO `G25_1_1.2.1.2.4.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.1.2.4.3.A.2014' AS ITEM_NUM,
                 SUM(A.BALANCE * CCY_RATE) ITEM_VAL
            FROM V_PUB_FUND_MMFUND A
            LEFT JOIN L_PUBL_RATE TT
              ON TT.CCY_DATE = D_DATADATE_CCY
             AND TT.BASIC_CCY = A.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
             AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放的定期
             AND A.BALANCE <> 0
             AND A.ORG_NUM NOT LIKE '5%'
             AND A.ORG_NUM NOT LIKE '6%'
             AND (A.MATURE_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATURE_DATE - D_DATADATE_CCY <= 30);

--20240331填报上没有这块？
        INSERT 
        INTO `G25_1_1.2.1.2.4.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009820' AS ORG_NUM,
           'G25_1_1.2.1.2.4.3.A.2014' AS ITEM_NUM,
           SUM(CREDIT_BAL) ITEM_VAL
            FROM L_FINA_GL A
           WHERE DATA_DATE = I_DATADATE
             AND CURR_CD = 'BWB'
             AND ITEM_CD IN('20120101','20120102')
             AND A.ORG_NUM='990000'
           GROUP BY A.ITEM_CD, A.ORG_NUM;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心,30天以内外币折人民币1302拆放同业余额
        
        INSERT 
        INTO `G25_1_1.2.1.2.4.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009801' AS ORG_NUM,
                 'G25_1_1.2.1.2.4.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB, 0)) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG = '02' -- 02(1302拆出资金)
             AND A.ORG_NUM = '009801'
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATUR_DATE - D_DATADATE_CCY <= 30);

--2.1.2.4.3银行存款，有业务关系且无存款保险
   -- 一个月内到期的同业拆入+同业存放定期（全行的定期报送在009820）本金+结算性同业存放活期(20120101和20120102的全行数取进009820,从业务状况表取，都属于1个月内)
   -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心30天以内外币折人民币2003拆入资金本金
        INSERT 
        INTO `G25_1_1.2.1.2.4.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 A.ORG_NUM,
                 'G25_1_1.2.1.2.4.3.A.2014' AS ITEM_NUM,
                 SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
            FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
           WHERE A.FLAG  IN ('05','10') --同业拆入(有其他机构) 转贷款
             AND ACCT_BAL_RMB <> 0
             AND A.ORG_NUM IN ('009804', '009820')
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATUR_DATE - D_DATADATE_CCY <= 30)
           GROUP BY A.ORG_NUM;

INSERT 
        INTO `G25_1_1.2.1.2.4.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009820' AS ORG_NUM,
                 'G25_1_1.2.1.2.4.3.A.2014' AS ITEM_NUM,
                 SUM(A.BALANCE * CCY_RATE) ITEM_VAL
            FROM V_PUB_FUND_MMFUND A
            LEFT JOIN L_PUBL_RATE TT
              ON TT.CCY_DATE = D_DATADATE_CCY
             AND TT.BASIC_CCY = A.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
             AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放的定期
             AND A.BALANCE <> 0
             AND A.ORG_NUM NOT LIKE '5%'
             AND A.ORG_NUM NOT LIKE '6%'
             AND (A.MATURE_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATURE_DATE - D_DATADATE_CCY <= 30);

--20240331填报上没有这块？
        INSERT 
        INTO `G25_1_1.2.1.2.4.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009820' AS ORG_NUM,
           'G25_1_1.2.1.2.4.3.A.2014' AS ITEM_NUM,
           SUM(CREDIT_BAL) ITEM_VAL
            FROM L_FINA_GL A
           WHERE DATA_DATE = I_DATADATE
             AND CURR_CD = 'BWB'
             AND ITEM_CD IN('20120101','20120102')
             AND A.ORG_NUM='990000'
           GROUP BY A.ITEM_CD, A.ORG_NUM;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，30天以内外币折人民币1302拆放同业余额

        INSERT 
        INTO `G25_1_1.2.1.2.4.3.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 '009801' AS ORG_NUM,
                 'G25_1_1.2.1.2.4.3.A.2014' AS ITEM_NUM,
                 SUM(NVL(ACCT_BAL_RMB, 0)) ITEM_VAL
            FROM CBRC_tmp_a_cbrc_loan_bal A
           WHERE A.FLAG = '02' -- 02(1302拆出资金)
             AND A.ORG_NUM = '009801'
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATUR_DATE - D_DATADATE_CCY <= 30);


-- 指标: G25_1_1.2.1.1.3.A.2014
-- 除以上3类账户   按客户分组

          INSERT INTO `G25_1_1.2.1.1.3.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM, --明细不能取机构,有可能客户在不同机构与数据,关联时卉产生重复数据,翻倍等
             'G25_1_1.2.1.1.3.A.2014' AS ITEM_NUM, ---2.1.1.3欠稳定存款（有存款保险）
             SUM(CASE
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0) >= 0 THEN
                    A.ACCT_BAL_RMB
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0)
                        < 0 THEN
                    500000
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE IN ('02', '03')
               GROUP BY T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
       UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.4.A.2014' AS ITEM_NUM, ---2.1.1.4欠稳定存款（无存款保险）
             SUM(CASE
                   WHEN (500000 - NVL(A.ACCT_BAL_RMB, 0)  < 0) THEN
                    (NVL(A.ACCT_BAL_RMB, 0) - 500000 )
                   ELSE
                    0
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE IN ('02', '03')
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;

/* -----3.5.1其中：定期存款 '21510'其他定期储蓄存款（含有奖储蓄）没有到期日放次日
    INSERT INTO `G25_1_1.2.1.1.3.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE,
             '990000' AS ORG_NUM,
             'G25_1_1.2.1.1.3.A.2014', --2.1.1.3欠稳定存款（有存款保险）
             sum(A.CREDIT_BAL * B.CCY_RATE)
        FROM  V_PUB_IDX_FINA_GL A
        LEFT JOIN L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '20110109' --'21510'其他定期储蓄存款（含有奖储蓄）
         AND A.CURR_CD <> 'BWB' --本外币合计去掉
         and A.ORG_NUM = '990000';

-- 除以上3类账户   按客户分组

          INSERT INTO `G25_1_1.2.1.1.3.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM, --明细不能取机构,有可能客户在不同机构与数据,关联时卉产生重复数据,翻倍等
             'G25_1_1.2.1.1.3.A.2014' AS ITEM_NUM, ---2.1.1.3欠稳定存款（有存款保险）
             SUM(CASE
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0) >= 0 THEN
                    A.ACCT_BAL_RMB
                   WHEN 500000 - NVL(A.ACCT_BAL_RMB, 0)
                        < 0 THEN
                    500000
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE IN ('02', '03')
               GROUP BY T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
       UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.1.4.A.2014' AS ITEM_NUM, ---2.1.1.4欠稳定存款（无存款保险）
             SUM(CASE
                   WHEN (500000 - NVL(A.ACCT_BAL_RMB, 0)  < 0) THEN
                    (NVL(A.ACCT_BAL_RMB, 0) - 500000 )
                   ELSE
                    0
                 END) AS LOAN_ACCT_BAL_RMB
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_PERSONAL T
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.FLAG_CODE IN ('02', '03')
                 AND T.ACCT_BAL_RMB <> 0
               GROUP BY T.CUST_ID,
               CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;

/* -----3.5.1其中：定期存款 '21510'其他定期储蓄存款（含有奖储蓄）没有到期日放次日
    INSERT INTO `G25_1_1.2.1.1.3.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE,
             '990000' AS ORG_NUM,
             'G25_1_1.2.1.1.3.A.2014', --2.1.1.3欠稳定存款（有存款保险）
             sum(A.CREDIT_BAL * B.CCY_RATE)
        FROM  V_PUB_IDX_FINA_GL A
        LEFT JOIN L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '20110109' --'21510'其他定期储蓄存款（含有奖储蓄）
         AND A.CURR_CD <> 'BWB' --本外币合计去掉
         and A.ORG_NUM = '990000';


-- 指标: G25_1_1.2.1.5.2.A.2014
--2.1.5.2保函
    INSERT 
    INTO `G25_1_1.2.1.5.2.A.2014` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1.2.1.5.2.A.2014' ITEM_NUM, --折算前
       SUM(T.BAL_1_30) AS CUR_BAL
        FROM CBRC_FDM_CUST_LNAC_INFO T
       WHERE T.FLAG = '04'
       GROUP BY ORG_NUM;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
      --2.1.5.2保函
      --2.1.5.3信用证

      --由于余额，保证金，担保物币种均不一样，因此折币后处理
      INSERT 
      INTO `G25_1_1.2.1.5.2.A.2014` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_7,
         COL_8)
        SELECT 
         I_DATADATE,
         CASE
           WHEN T1.ORG_NUM LIKE '5100%' THEN
            '510000'
           WHEN T1.ORG_NUM LIKE '5200%' THEN
            '520000'
           WHEN T1.ORG_NUM LIKE '5300%' THEN
            '530000'
           WHEN T1.ORG_NUM LIKE '5400%' THEN
            '540000'
           WHEN T1.ORG_NUM LIKE '5500%' THEN
            '550000'
           WHEN T1.ORG_NUM LIKE '5600%' THEN
            '560000'
           WHEN T1.ORG_NUM LIKE '5700%' THEN
            '570000'
           WHEN T1.ORG_NUM LIKE '5800%' THEN
            '580000'
           WHEN T1.ORG_NUM LIKE '5900%' THEN
            '590000'
           WHEN T1.ORG_NUM LIKE '6000%' THEN
            '600000'
           ELSE
            '990000'
         END,
         T1.DEPARTMENTD, --数据条线
         'CBRC' AS SYS_NAM,
         'G2501' REP_NUM,
         CASE
           WHEN SUBSTR(T1.GL_ITEM_CODE, 1, 4) = '7040' THEN --2.1.5.2保函
            'G25_1_1.2.1.5.2.A.2014'
           WHEN SUBSTR(T1.GL_ITEM_CODE, 1, 4) = '7010' THEN --2.1.5.3信用证
            'G25_1_1.2.1.5.3.A.2014'
         END AS ITEM_NUM,
         NVL(T1.BALANCE * T2.CCY_RATE, 0) -
         NVL(T1.SECURITY_AMT * T3.CCY_RATE, 0) - NVL(TM.DEP_AMT, 0) -
         NVL(TM.COLL_BILL_AMOUNT, 0) AS TOTAL_VALUE, --612保函、601-开出信用证 扣除保证金、本行存单、国债敞口部分
         T1.ACCT_NUM AS COL_1, --表外账号
         T1.CURR_CD AS COL2, --币种
         T1.GL_ITEM_CODE AS COL3, --科目
         TO_CHAR(MATURITY_DT, 'YYYYMMDD') AS COL4, --实际到期日
         T1.MATURITY_DT - D_DATADATE_CCY AS COL7, --剩余期限（天数）
         CASE
           WHEN T1.LOAN_GRADE_CD = '1' THEN
            '正常'
           WHEN T1.LOAN_GRADE_CD = '2' THEN
            '关注'
           WHEN T1.LOAN_GRADE_CD = '3' THEN
            '次级'
           WHEN T1.LOAN_GRADE_CD = '4' THEN
            '可疑'
           WHEN T1.LOAN_GRADE_CD = '5' THEN
            '损失'
         END AS COL8 --五级分类
        -- T1.ACCT_TYP, --贷款承诺类型511无条件撤销承诺521不可撤销承诺-循环包销便利522不可撤销承诺-票据发行便利523不可撤销承诺-其他531有条件撤销承诺
          FROM L_ACCT_OBS_LOAN T1
          LEFT JOIN L_PUBL_RATE T2
            ON T2.DATA_DATE = I_DATADATE
           AND T2.BASIC_CCY = T1.CURR_CD --表外余额折币
           AND T2.FORWARD_CCY = 'CNY'
          LEFT JOIN L_PUBL_RATE T3
            ON T3.DATA_DATE = I_DATADATE
           AND T3.BASIC_CCY = T1.SECURITY_CURR --表外保证金折币
           AND T3.FORWARD_CCY = 'CNY'
          LEFT JOIN (SELECT T2.CONTRACT_NUM,
                            SUM(NVL(T4.DEP_AMT * T6.CCY_RATE, 0)) AS DEP_AMT,
                            SUM(NVL(T5.COLL_BILL_AMOUNT * T6.CCY_RATE, 0)) AS COLL_BILL_AMOUNT
                       FROM L_AGRE_GUA_RELATION T2
                       LEFT JOIN L_AGRE_GUARANTEE_RELATION T3
                         ON T2.GUAR_CONTRACT_NUM = T3.GUAR_CONTRACT_NUM
                        AND T3.DATA_DATE = I_DATADATE
                       LEFT JOIN L_AGRE_GUARANTY_INFO T4
                         ON T3.GUARANTEE_SERIAL_NUM =
                            T4.GUARANTEE_SERIAL_NUM
                        AND T4.DATA_DATE = I_DATADATE
                        AND T4.COLL_TYP = 'A0201' --  是本行存单
                       LEFT JOIN L_AGRE_GUARANTY_INFO T5
                         ON T3.GUARANTEE_SERIAL_NUM =
                            T5.GUARANTEE_SERIAL_NUM
                        AND T5.DATA_DATE = I_DATADATE
                        AND T5.COLL_TYP IN ('A0602', 'A0603')
                       LEFT JOIN L_PUBL_RATE T6
                         ON T6.DATA_DATE = I_DATADATE
                        AND T6.BASIC_CCY = T3.CURR_CD --担保物折币
                        AND T6.FORWARD_CCY = 'CNY'
                      WHERE T2.DATA_DATE = I_DATADATE
                      GROUP BY T2.CONTRACT_NUM) TM --押品类型为 A0602一级国家及地区的国债 A0603二级国家及地区的国债
            ON T1.ACCT_NUM = TM.CONTRACT_NUM
         WHERE T1.DATA_DATE = I_DATADATE
           AND (T1.GL_ITEM_CODE LIKE '7010%' OR
               T1.GL_ITEM_CODE LIKE '7040%')
           AND NVL(T1.BALANCE * T2.CCY_RATE, 0) -
               NVL(T1.SECURITY_AMT * T3.CCY_RATE, 0) - NVL(TM.DEP_AMT, 0) -
               NVL(TM.COLL_BILL_AMOUNT, 0) > 0;

--17.3 担保、信用证及其他贸易融资工具 1开出信用证敞口 2保函敞口放在6月内
    INSERT INTO `G25_1_1.2.1.5.2.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.16.3.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G2501'
         AND ITEM_NUM IN
             ('G25_1_1.2.1.5.2.A.2014', 'G25_1_1.2.1.5.3.A.2014')
       GROUP BY T.ORG_NUM;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
      INSERT 
      INTO `G25_1_1.2.1.5.2.A.2014` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_7,
         COL_8)
        SELECT DATA_DATE,
               ORG_NUM,
               DATA_DEPARTMENT,
               SYS_NAM,
               'G2502' AS REP_NUM,
               'G25_2_2.16.3.A.2016' AS ITEM_NUM,
               TOTAL_VALUE,
               COL_1,
               COL_2,
               COL_3,
               COL_4,
               COL_7,
               COL_8
          FROM CBRC_A_REPT_DWD_G2501
         WHERE ITEM_NUM IN
               ('G25_1_1.2.1.5.2.A.2014', 'G25_1_1.2.1.5.3.A.2014');

/*   --17.3 担保、信用证及其他贸易融资工具 1开出信用证敞口 2保函敞口放在6月内
    INSERT INTO `G25_1_1.2.1.5.2.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.16.3.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G2501'
         AND ITEM_NUM IN
             ('G25_1_1.2.1.5.2.A.2014', 'G25_1_1.2.1.5.3.A.2014')
       GROUP BY T.ORG_NUM;


-- 指标: G25_1_1.2.1.5.5.1.A.2014
--ADD BY DJH 20230417 2.1.5.5.1其中：属于理财产品的部分  G21封闭式+开放式,30日内到期
 INSERT 
 INTO `G25_1_1.2.1.5.5.1.A.2014` 
   (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
   SELECT I_DATADATE AS DATA_DATE,
          B.ORG_NUM,
          'G25_1_1.2.1.5.5.1.A.2014' ITEM_NUM, --折算前
          SUM(B.ITEM_VAL) --期末产品余额折人民币
     FROM CBRC_g21_data_collect_tmp_ngi B
    WHERE B.ITEM_NUM IN ('G21_16.1.A.2021',
                         'G21_16.1.B.2021',
                         'G21_16.1.C.2021',
                         'G21_16.2.A.2021',
                         'G21_16.2.B.2021',
                         'G21_16.2.C.2021')
    GROUP BY B.ORG_NUM;

--ADD BY DJH 20230417 2.1.5.5.1其中：属于理财产品的部分  G21封闭式+开放式，30日内到期
 INSERT 
 INTO `G25_1_1.2.1.5.5.1.A.2014` 
   (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
   SELECT I_DATADATE AS DATA_DATE,
          B.ORG_NUM,
          'G25_1_1.2.1.5.5.1.A.2014' ITEM_NUM, --折算前
          SUM(B.ITEM_VAL) --期末产品余额折人民币
     FROM CBRC_g21_data_collect_tmp_ngi B
    WHERE B.ITEM_NUM IN ('G21_16.1.A.2021',
                         'G21_16.1.B.2021',
                         'G21_16.1.C.2021',
                         'G21_16.2.A.2021',
                         'G21_16.2.B.2021',
                         'G21_16.2.C.2021')
    GROUP BY B.ORG_NUM;


-- 指标: G25_1_1.2.1.2.5.A.2014
--2.1.2.5未包含在以上无担保批发现金流出分类的其他类别
    --一个月内到期的同业存单持有仓位(账面余额)
     INSERT 
     INTO `G25_1_1.2.1.2.5.A.2014`
       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
       SELECT 
        I_DATADATE AS DATA_DATE,
        '009820' AS ORG_NUM,
        'G25_1_1.2.1.2.5.A.2014' AS ITEM_NUM,
        SUM(ACCT_BAL_RMB) ITEM_VAL
         FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
        WHERE A.FLAG = '06'--同业存单发行
          AND ACCT_BAL_RMB <> 0
          AND A.ORG_NUM = '009820'
          AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
              A.MATUR_DATE - D_DATADATE_CCY <= 30);

--一个月内到期同业拆入应付利息
       INSERT 
        INTO `G25_1_1.2.1.2.5.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 A.ORG_NUM,
                 'G25_1_1.2.1.2.5.A.2014' AS ITEM_NUM,
                 SUM(A.INTEREST_ACCURAL) AS ITEM_VAL
            FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
           WHERE A.FLAG = '05' --同业拆入(有其他机构)
             AND ACCT_BAL_RMB <> 0
             AND A.ORG_NUM IN ('009804')
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATUR_DATE - D_DATADATE_CCY <= 30)
           GROUP BY A.ORG_NUM;

--2.1.2.5未包含在以上无担保批发现金流出分类的其他类别
    --一个月内到期的同业存单持有仓位(账面余额)
     INSERT 
     INTO `G25_1_1.2.1.2.5.A.2014`
       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
       SELECT 
        I_DATADATE AS DATA_DATE,
        '009820' AS ORG_NUM,
        'G25_1_1.2.1.2.5.A.2014' AS ITEM_NUM,
        SUM(ACCT_BAL_RMB) ITEM_VAL
         FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
        WHERE A.FLAG = '06'--同业存单发行
          AND ACCT_BAL_RMB <> 0
          AND A.ORG_NUM = '009820'
          AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
              A.MATUR_DATE - D_DATADATE_CCY <= 30);

--一个月内到期同业拆入应付利息
       INSERT 
        INTO `G25_1_1.2.1.2.5.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT I_DATADATE AS DATA_DATE,
                 A.ORG_NUM,
                 'G25_1_1.2.1.2.5.A.2014' AS ITEM_NUM,
                 SUM(A.INTEREST_ACCURAL) AS ITEM_VAL
            FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
           WHERE A.FLAG = '05' --同业拆入(有其他机构)
             AND ACCT_BAL_RMB <> 0
             AND A.ORG_NUM IN ('009804')
             AND (A.MATUR_DATE - D_DATADATE_CCY >= 0 AND
                 A.MATUR_DATE - D_DATADATE_CCY <= 30)
           GROUP BY A.ORG_NUM;


-- 指标: G25_1_1.2.1.2.4.6.A.2014
INSERT 
        INTO `G25_1_1.2.1.2.4.6.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009820' AS ORG_NUM,
           'G25_1_1.2.1.2.4.6.A.2014' AS ITEM_NUM,
           SUM(A.BALANCE * CCY_RATE) ITEM_VAL
            FROM V_PUB_FUND_MMFUND A
            LEFT JOIN L_PUBL_RATE TT
              ON TT.CCY_DATE = D_DATADATE_CCY
             AND TT.BASIC_CCY = A.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
                -- AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201201' --同业存放活期款项
             AND A.BALANCE <> 0
             AND A.CUST_ID IN ('8913402328', '8916869348');

INSERT 
        INTO `G25_1_1.2.1.2.4.6.A.2014`
          (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
          SELECT 
           I_DATADATE AS DATA_DATE,
           '009820' AS ORG_NUM,
           'G25_1_1.2.1.2.4.6.A.2014' AS ITEM_NUM,
           SUM(A.BALANCE * CCY_RATE) ITEM_VAL
            FROM V_PUB_FUND_MMFUND A
            LEFT JOIN L_PUBL_RATE TT
              ON TT.CCY_DATE = D_DATADATE_CCY
             AND TT.BASIC_CCY = A.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
                -- AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201201' --同业存放活期款项
             AND A.BALANCE <> 0
             AND A.CUST_ID IN ('8913402328', '8916869348');


-- ========== 逻辑组 25: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.2.2.A.2014',
             sum(CASE
                   WHEN A.ACCT_BAL_RMB - 500000 <= 0 THEN
                    A.ACCT_BAL_RMB
                   when A.ACCT_BAL_RMB - 500000 > 0 then
                    500000
                 end) val
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_BIG T
               INNER JOIN (SELECT DISTINCT ACCT_NUM
                            FROM CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                           WHERE DATA_DATE = I_DATADATE) T1 --有业务关系
                  ON T.ACCT_NUM = T1.ACCT_NUM
               WHERE T.DATA_DATE = I_DATADATE
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) a
               GROUP BY ORG_NUM
      union all
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.2.3.A.2014',
             sum(case
                   when A.ACCT_BAL_RMB - 500000 > 0 then
                    A.ACCT_BAL_RMB - 500000
                 end) val
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_BIG T
               INNER JOIN (SELECT DISTINCT ACCT_NUM
                            FROM CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                           WHERE DATA_DATE = I_DATADATE) T1 --有业务关系
                  ON T.ACCT_NUM = T1.ACCT_NUM
               WHERE T.DATA_DATE = I_DATADATE
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM;

--存款按客户分组,50万以内稳定存款（有存款保险）,50万以上欠稳定存款（无存款保险）
    --2.1.2.2.2有业务关系且有存款保险（不满足有效存款保险附加标准）
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --贷款余额（折人民币）
       )
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.2.2.A.2014',
             sum(CASE
                   WHEN A.ACCT_BAL_RMB - 500000 <= 0 THEN
                    A.ACCT_BAL_RMB
                   when A.ACCT_BAL_RMB - 500000 > 0 then
                    500000
                 end) val
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_BIG T
               INNER JOIN (SELECT DISTINCT ACCT_NUM
                            FROM CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                           WHERE DATA_DATE = I_DATADATE) T1 --有业务关系
                  ON T.ACCT_NUM = T1.ACCT_NUM
               WHERE T.DATA_DATE = I_DATADATE
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) a
               GROUP BY ORG_NUM
      union all
      SELECT I_DATADATE AS DATA_DATE,
              ORG_NUM,
             'G25_1_1.2.1.2.2.3.A.2014',
             sum(case
                   when A.ACCT_BAL_RMB - 500000 > 0 then
                    A.ACCT_BAL_RMB - 500000
                 end) val
        FROM (SELECT 
               T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END AS ORG_NUM,
              SUM(T.ACCT_BAL_RMB) AS ACCT_BAL_RMB
                FROM CBRC_TMP_DEPOSIT_WD_DIFF_BIG T
               INNER JOIN (SELECT DISTINCT ACCT_NUM
                            FROM CBRC_TMP_DEPOSIT_WD_ACCT_BRO
                           WHERE DATA_DATE = I_DATADATE) T1 --有业务关系
                  ON T.ACCT_NUM = T1.ACCT_NUM
               WHERE T.DATA_DATE = I_DATADATE
               GROUP BY T.CUST_ID,CASE WHEN  T.ORG_NUM     LIKE '5100%' THEN '510000'
             WHEN  T.ORG_NUM     LIKE '5200%' THEN '520000'
             WHEN  T.ORG_NUM     LIKE '5300%' THEN '530000'
             WHEN  T.ORG_NUM     LIKE '5400%' THEN '540000'
             WHEN  T.ORG_NUM     LIKE '5500%' THEN '550000'
             WHEN  T.ORG_NUM     LIKE '5600%' THEN '560000'
             WHEN  T.ORG_NUM     LIKE '5700%' THEN '570000'
             WHEN  T.ORG_NUM     LIKE '5800%' THEN '580000'
             WHEN  T.ORG_NUM     LIKE '5900%' THEN '590000'
             WHEN  T.ORG_NUM     LIKE '6000%' THEN '600000'
           ELSE '990000'
             END) A
             GROUP BY ORG_NUM
) q_25
INSERT INTO `G25_1_1.2.1.2.2.3.A.2014` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G25_1_1.2.1.2.2.2.A.2014` (DATA_DATE,  
       ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *;

-- 指标: G25_1_1.2.1.2.4.8.A.2014
--2.1.2.4.8无业务关系的金融机构存款
    --扣除东北证券和保险后的非结算性同业存放活期余额（全行口径）
         INSERT 
         INTO `G25_1_1.2.1.2.4.8.A.2014`
           (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
           SELECT 
            I_DATADATE AS DATA_DATE,
            '009820' AS ORG_NUM,
            'G25_1_1.2.1.2.4.8.A.2014' AS ITEM_NUM,
            SUM(A.BALANCE * CCY_RATE) ITEM_VAL
             FROM V_PUB_FUND_MMFUND A
             LEFT JOIN L_PUBL_RATE TT
               ON TT.CCY_DATE = I_DATADATE
              AND TT.BASIC_CCY = A.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
            WHERE A.DATA_DATE = I_DATADATE
              AND A.GL_ITEM_CODE IN
                  ('20120103', '20120104', '20120105', '20120109', '20120110')
              AND A.CUST_ID NOT IN ('8913402328', '8916869348') --去掉8913402328东北证券股份有限公司 8916869348永诚保险资产管理有限公司
              AND A.BALANCE <> 0
              AND A.ORG_NUM NOT LIKE '5%'
              AND A.ORG_NUM NOT LIKE '6%';

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心,30天以内外币折人民币2003同业拆入及同业代付余额,业务说同业代付包含009801清算中心以及分支行业务
       INSERT 
       INTO `G25_1_1.2.1.2.4.8.A.2014`
         (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT 
          I_DATADATE AS DATA_DATE,
          ORG_NUM,
          'G25_1_1.2.1.2.4.8.A.2014' AS ITEM_NUM,
          SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
           FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL
          WHERE DATA_DATE = I_DATADATE
            AND ACCT_CUR <> 'CNY'
            AND FLAG = '05'
            AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
          GROUP BY ORG_NUM;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君]   G2501取分行同业代付30天内,G2502取所有
      /*新国结系统,会传给ngi系统
      1、负债方：委托代付,是我行委托他行,业务提供新国结系统进口代付业务明细表页面数据,所以从ngi系统取数
      2、资产方：受托代付,是他行委托我行,这个功能没上线*/  
      
     --备注： 委托方同业代付：是指填报机构（委托方）委托其他金融机构（受托方）向企业客户付款,委托方在约定还款日偿还代付款项本息的资金融通款项。

      
       INSERT 
       INTO `G25_1_1.2.1.2.4.8.A.2014`
         (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT A.DATA_DATE,
                '009801' AS ORG_NUM,
                'G25_1_1.2.1.2.4.8.A.2014' AS ITEM_NUM,
                SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
           FROM L_ACCT_LOAN A --贷款借据信息表
           LEFT JOIN L_AGRE_LOAN_CONTRACT B
             ON A.ACCT_NUM = B.CONTRACT_NUM
            AND B.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE U
             ON U.CCY_DATE = I_DATADATE
            AND U.BASIC_CCY = A.CURR_CD
            AND U.FORWARD_CCY = 'CNY'
            AND U.DATA_DATE = I_DATADATE
          WHERE A.DATA_DATE = I_DATADATE
            AND B.CP_ID = 'MR0020002'
            AND LOAN_ACCT_BAL <> 0
            AND (A.ACTUAL_MATURITY_DT - D_DATADATE_CCY >= 0 AND
                 A.ACTUAL_MATURITY_DT - D_DATADATE_CCY <= 30)
          GROUP BY A.DATA_DATE;

--2.1.2.4.8无业务关系的金融机构存款
    --扣除东北证券和保险后的非结算性同业存放活期余额（全行口径）
         INSERT 
         INTO `G25_1_1.2.1.2.4.8.A.2014`
           (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
           SELECT 
            I_DATADATE AS DATA_DATE,
            '009820' AS ORG_NUM,
            'G25_1_1.2.1.2.4.8.A.2014' AS ITEM_NUM,
            SUM(A.BALANCE * CCY_RATE) ITEM_VAL
             FROM V_PUB_FUND_MMFUND A
             LEFT JOIN L_PUBL_RATE TT
               ON TT.CCY_DATE = I_DATADATE
              AND TT.BASIC_CCY = A.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
            WHERE A.DATA_DATE = I_DATADATE
              AND A.GL_ITEM_CODE IN
                  ('20120103', '20120104', '20120105', '20120109', '20120110')
              AND A.CUST_ID NOT IN ('8913402328', '8916869348') --去掉8913402328东北证券股份有限公司 8916869348永诚保险资产管理有限公司
              AND A.BALANCE <> 0
              AND A.ORG_NUM NOT LIKE '5%'
              AND A.ORG_NUM NOT LIKE '6%';

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，30天以内外币折人民币2003同业拆入及同业代付余额,业务说同业代付包含009801清算中心以及分支行业务
       INSERT 
       INTO `G25_1_1.2.1.2.4.8.A.2014`
         (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT 
          I_DATADATE AS DATA_DATE,
          ORG_NUM,
          'G25_1_1.2.1.2.4.8.A.2014' AS ITEM_NUM,
          SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
           FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL
          WHERE DATA_DATE = I_DATADATE
            AND ACCT_CUR <> 'CNY'
            AND FLAG = '05'
            AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
          GROUP BY ORG_NUM;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君]   G2501取分行同业代付30天内，G2502取所有
      /*新国结系统,会传给ngi系统
      1、负债方：委托代付，是我行委托他行，业务提供新国结系统进口代付业务明细表页面数据,所以从ngi系统取数
      2、资产方：受托代付，是他行委托我行，这个功能没上线*/

     --备注： 委托方同业代付：是指填报机构（委托方）委托其他金融机构（受托方）向企业客户付款，委托方在约定还款日偿还代付款项本息的资金融通款项。


       INSERT 
       INTO `G25_1_1.2.1.2.4.8.A.2014`
         (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT A.DATA_DATE,
                '009801' AS ORG_NUM,
                'G25_1_1.2.1.2.4.8.A.2014' AS ITEM_NUM,
                SUM(A.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL
           FROM L_ACCT_LOAN A --贷款借据信息表
           LEFT JOIN L_AGRE_LOAN_CONTRACT B
             ON A.ACCT_NUM = B.CONTRACT_NUM
            AND B.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE U
             ON U.CCY_DATE = I_DATADATE
            AND U.BASIC_CCY = A.CURR_CD
            AND U.FORWARD_CCY = 'CNY'
            AND U.DATA_DATE = I_DATADATE
          WHERE A.DATA_DATE = I_DATADATE
            AND B.CP_ID = 'MR0020002'
            AND LOAN_ACCT_BAL <> 0
            AND (A.ACTUAL_MATURITY_DT - D_DATADATE_CCY >= 0 AND
                 A.ACTUAL_MATURITY_DT - D_DATADATE_CCY <= 30)
          GROUP BY A.DATA_DATE;


-- 指标: G25_1_1.2.1.3.2.1.A.2014
----该部分需要手动调仓的数据,暂时出数不准,待接入,接入后使用L_AGRE_REPURCHASE_GUARANTY_INFO表添加MOR_AMT字段重新开发程序
   /*             INSERT \*+ APPEND *\
                 INTO CBRC_G2501_DATA_COLLECT_TMP
                   (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
                   SELECT I_DATADATE AS DATA_DATE,
                          A.ORG_NUM,
                          CASE
                            WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN --担保品风险分类为一级资产 缺失外汇抵押（暂时不取）
                             'G25_1_1.2.1.3.2.1.A.2014'
                            WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                             'G25_1_1.2.1.3.3.1.A.2014' --担保品风险分类为2A级资产
                          END AS ITEM_NUM,
                          SUM(A.MOR_AMT * U.CCY_RATE)*10000 AS LOAN_ACCT_BAL_RMB ---上游加工是质押券面总额(万)*中登净价价格/100 ,质押券面总额直取
                     FROM V_PUB_FUND_REPURCHASE A --回购信息表
                     LEFT JOIN CBRC_TMP_L_CUST_BILL_TY B
                       ON A.CUST_ID = B.CUST_ID
                     LEFT JOIN L_PUBL_RATE U
                       ON U.CCY_DATE = D_DATADATE_CCY
                      AND U.BASIC_CCY = A.CURR_CD --基准币种
                      AND U.FORWARD_CCY = 'CNY' --折算币种
                    WHERE A.BUSI_TYPE LIKE '2%' --卖出回购
                      AND (B.FINA_CODE_NEW NOT LIKE 'A%' OR
                          B.FINA_CODE_NEW IS NULL) --非货币当局
                      AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                          A.END_DT - D_DATADATE_CCY <= 30)
                      AND A.DATA_DATE = I_DATADATE
                      AND ASS_TYPE = '1' --回购业务只有债券有评级
                      AND A.BALANCE > 0
                    GROUP BY A.ORG_NUM,
                             CASE
                               WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                                'G25_1_1.2.1.3.2.1.A.2014'
                               WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                                'G25_1_1.2.1.3.3.1.A.2014' --担保品风险分类为2A级资产
                             END;

*/
         -- [2025-04-18] [石雨] [JLBA202502280012] [刘名赫]取康星系统一级资产一个月内到期的债券正回购押品的市场价值=押品的面额*中登净价价格/100

            INSERT 
            INTO `G25_1_1.2.1.3.2.1.A.2014`
              (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
              SELECT I_DATADATE AS DATA_DATE,
                     A.ORG_NUM,
                     CASE
                       WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                        'G25_1_1.2.1.3.2.1.A.2014' --由一级资产担保的融资交易（与央行以外其他交易对手）
                       WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                        'G25_1_1.2.1.3.3.1.A.2014' --由2A级资产担保的融资交易（与央行以外其他交易对手）
                     END AS ITEM_NUM,
                     SUM(CASE
                           WHEN E.POSITION_ADJUST_REM LIKE '%外汇%' THEN
                            NVL(A.COLL_MK_VAL, 0)   --外汇取市值金额
                           ELSE
                            NVL(a.BOND_VAL, 0) * (NVL(a.COLL_MK_VAL, 0) / 100)
                         END) AS LOAN_ACCT_BAL_RMB
                FROM L_AGRE_REPURCHASE_GUARANTY_INFO A --回购抵质押信息表
               INNER JOIN V_PUB_FUND_REPURCHASE B --回购信息表
                  ON A.ACCT_NUM = B.ACCT_NUM
                 AND B.DATA_DATE = I_DATADATE
                 AND B.BUSI_TYPE LIKE '2%' --卖出回购
                 AND B.ASS_TYPE = '1' --债券
                 AND B.BALANCE > 0
                LEFT JOIN CBRC_TMP_L_CUST_BILL_TY C
                  ON B.CUST_ID = C.CUST_ID
                LEFT JOIN L_PUBL_RATE TT
                  ON TT.CCY_DATE = D_DATADATE_CCY
                 AND TT.BASIC_CCY = B.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
                LEFT JOIN L_AGRE_BOND_INFO E
                  ON A.SUBJECT_CD = E.STOCK_CD
                 AND E.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND (C.FINA_CODE_NEW NOT LIKE 'A%' OR
                     C.FINA_CODE_NEW IS NULL) --非货币当局
                 AND (B.END_DT - D_DATADATE_CCY >= 0 AND
                     B.END_DT - D_DATADATE_CCY <= 30)
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                           'G25_1_1.2.1.3.2.1.A.2014' --由一级资产担保的融资交易（与央行以外其他交易对手）
                          WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                           'G25_1_1.2.1.3.3.1.A.2014' --由2A级资产担保的融资交易（与央行以外其他交易对手）
                        END;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心,30天以内外币折人民币2111卖出回购所对应的抵押品面值
           
             INSERT 
             INTO `G25_1_1.2.1.3.2.1.A.2014`
               (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
               SELECT I_DATADATE AS DATA_DATE,
                      A.ORG_NUM,
                      'G25_1_1.2.1.3.2.1.A.2014' AS ITEM_NUM, --由一级资产担保的融资交易（与央行以外其他交易对手）
                      SUM(A.BOND_VAL) AS LOAN_ACCT_BAL_RMB
                 FROM L_AGRE_REPURCHASE_GUARANTY_INFO A --回购抵质押信息表
                INNER JOIN V_PUB_FUND_REPURCHASE B --回购信息表
                   ON A.ACCT_NUM = B.ACCT_NUM
                  AND SUBSTR(B.GL_ITEM_CODE, 1, 4) = '2111'
                  AND B.CURR_CD <> 'CNY'
                WHERE A.DATA_DATE = I_DATADATE
                  AND (B.END_DT - I_DATADATE >= 0 AND
                      B.END_DT - I_DATADATE <= 30)
                GROUP BY A.ORG_NUM;

----该部分需要手动调仓的数据，暂时出数不准，待接入，接入后使用L_AGRE_REPURCHASE_GUARANTY_INFO表添加MOR_AMT字段重新开发程序
   /*             INSERT \*+ APPEND *\
                 INTO CBRC_G2501_DATA_COLLECT_TMP
                   (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
                   SELECT I_DATADATE AS DATA_DATE,
                          A.ORG_NUM,
                          CASE
                            WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN --担保品风险分类为一级资产 缺失外汇抵押（暂时不取）
                             'G25_1_1.2.1.3.2.1.A.2014'
                            WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                             'G25_1_1.2.1.3.3.1.A.2014' --担保品风险分类为2A级资产
                          END AS ITEM_NUM,
                          SUM(A.MOR_AMT * U.CCY_RATE)*10000 AS LOAN_ACCT_BAL_RMB ---上游加工是质押券面总额(万)*中登净价价格/100 ，质押券面总额直取
                     FROM CBRC_DATACORE.V_PUB_FUND_REPURCHASE A --回购信息表
                     LEFT JOIN TMP_L_CUST_BILL_TY B
                       ON A.CUST_ID = B.CUST_ID
                     LEFT JOIN L_PUBL_RATE U
                       ON U.CCY_DATE = D_DATADATE_CCY
                      AND U.BASIC_CCY = A.CURR_CD --基准币种
                      AND U.FORWARD_CCY = 'CNY' --折算币种
                    WHERE A.BUSI_TYPE LIKE '2%' --卖出回购
                      AND (B.FINA_CODE_NEW NOT LIKE 'A%' OR
                          B.FINA_CODE_NEW IS NULL) --非货币当局
                      AND (A.END_DT - D_DATADATE_CCY >= 0 AND
                          A.END_DT - D_DATADATE_CCY <= 30)
                      AND A.DATA_DATE = I_DATADATE
                      AND ASS_TYPE = '1' --回购业务只有债券有评级
                      AND A.BALANCE > 0
                    GROUP BY A.ORG_NUM,
                             CASE
                               WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                                'G25_1_1.2.1.3.2.1.A.2014'
                               WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                                'G25_1_1.2.1.3.3.1.A.2014' --担保品风险分类为2A级资产
                             END;

*/
         -- [2025-04-18] [石雨] [JLBA202502280012] [刘名赫]取康星系统一级资产一个月内到期的债券正回购押品的市场价值=押品的面额*中登净价价格/100

            INSERT 
            INTO `G25_1_1.2.1.3.2.1.A.2014`
              (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
              SELECT I_DATADATE AS DATA_DATE,
                     A.ORG_NUM,
                     CASE
                       WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                        'G25_1_1.2.1.3.2.1.A.2014' --由一级资产担保的融资交易（与央行以外其他交易对手）
                       WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                        'G25_1_1.2.1.3.3.1.A.2014' --由2A级资产担保的融资交易（与央行以外其他交易对手）
                     END AS ITEM_NUM,
                     SUM(CASE
                           WHEN E.POSITION_ADJUST_REM LIKE '%外汇%' THEN
                            NVL(A.COLL_MK_VAL, 0)   --外汇取市值金额
                           ELSE
                            NVL(a.BOND_VAL, 0) * (NVL(a.COLL_MK_VAL, 0) / 100)
                         END) AS LOAN_ACCT_BAL_RMB
                FROM L_AGRE_REPURCHASE_GUARANTY_INFO A --回购抵质押信息表
               INNER JOIN V_PUB_FUND_REPURCHASE B --回购信息表
                  ON A.ACCT_NUM = B.ACCT_NUM
                 AND B.DATA_DATE = I_DATADATE
                 AND B.BUSI_TYPE LIKE '2%' --卖出回购
                 AND B.ASS_TYPE = '1' --债券
                 AND B.BALANCE > 0
                LEFT JOIN CBRC_TMP_L_CUST_BILL_TY C
                  ON B.CUST_ID = C.CUST_ID
                LEFT JOIN L_PUBL_RATE TT
                  ON TT.CCY_DATE = D_DATADATE_CCY
                 AND TT.BASIC_CCY = B.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
                LEFT JOIN L_AGRE_BOND_INFO E
                  ON A.SUBJECT_CD = E.STOCK_CD
                 AND E.DATA_DATE = I_DATADATE
               WHERE A.DATA_DATE = I_DATADATE
                 AND (C.FINA_CODE_NEW NOT LIKE 'A%' OR
                     C.FINA_CODE_NEW IS NULL) --非货币当局
                 AND (B.END_DT - D_DATADATE_CCY >= 0 AND
                     B.END_DT - D_DATADATE_CCY <= 30)
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.PLEDGE_ASSETS_TYPE = 'A' THEN
                           'G25_1_1.2.1.3.2.1.A.2014' --由一级资产担保的融资交易（与央行以外其他交易对手）
                          WHEN A.PLEDGE_ASSETS_TYPE = 'B' THEN
                           'G25_1_1.2.1.3.3.1.A.2014' --由2A级资产担保的融资交易（与央行以外其他交易对手）
                        END;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，30天以内外币折人民币2111卖出回购所对应的抵押品面值

             INSERT 
             INTO `G25_1_1.2.1.3.2.1.A.2014`
               (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
               SELECT I_DATADATE AS DATA_DATE,
                      A.ORG_NUM,
                      'G25_1_1.2.1.3.2.1.A.2014' AS ITEM_NUM, --由一级资产担保的融资交易（与央行以外其他交易对手）
                      SUM(A.BOND_VAL) AS LOAN_ACCT_BAL_RMB
                 FROM L_AGRE_REPURCHASE_GUARANTY_INFO A --回购抵质押信息表
                INNER JOIN V_PUB_FUND_REPURCHASE B --回购信息表
                   ON A.ACCT_NUM = B.ACCT_NUM
                  AND SUBSTR(B.GL_ITEM_CODE, 1, 4) = '2111'
                  AND B.CURR_CD <> 'CNY'
                WHERE A.DATA_DATE = I_DATADATE
                  AND (B.END_DT - I_DATADATE >= 0 AND
                      B.END_DT - I_DATADATE <= 30)
                GROUP BY A.ORG_NUM;


-- 指标: G25_1_1.2.1.3.1.A.2014
INSERT 
          INTO `G25_1_1.2.1.3.1.A.2014`
            (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
            SELECT I_DATADATE AS DATA_DATE,
                   '009804', --填报在金融市场部
                   'G25_1_1.2.1.3.1.A.2014' AS ITEM_NUM,
                   SUM(BALANCE)
              FROM V_PUB_FUND_MMFUND A
             WHERE DATA_DATE = I_DATADATE
               AND A.MATURE_DATE - D_DATADATE_CCY >= 0
               AND A.MATURE_DATE - D_DATADATE_CCY <= 30
               AND ACCT_TYP IN ('20303', '20304') --20303 回购式再贴现  20304 买断式再贴现
             GROUP BY A.ORG_NUM
            UNION ALL
            SELECT I_DATADATE AS DATA_DATE,
                   CASE
                     WHEN A.ORG_NUM = '009801' THEN
                      '009804'
                   END,     ---中期便利账在清算中心,报在金融市场部
                   'G25_1_1.2.1.3.1.A.2014' AS ITEM_NUM,
                   SUM(A.BALANCE)
              FROM V_PUB_FUND_MMFUND A
             WHERE DATA_DATE = I_DATADATE
               AND (A.MATURE_DATE - D_DATADATE_CCY >= 0 AND
                   A.MATURE_DATE - D_DATADATE_CCY <= 30)
               AND A.GL_ITEM_CODE = '20040501' --中期借贷便利
             GROUP BY A.ORG_NUM;

INSERT 
          INTO `G25_1_1.2.1.3.1.A.2014`
            (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
            SELECT I_DATADATE AS DATA_DATE,
                   '009804', --填报在金融市场部
                   'G25_1_1.2.1.3.1.A.2014' AS ITEM_NUM,
                   SUM(BALANCE)
              FROM V_PUB_FUND_MMFUND A
             WHERE DATA_DATE = I_DATADATE
               AND A.MATURE_DATE - D_DATADATE_CCY >= 0
               AND A.MATURE_DATE - D_DATADATE_CCY <= 30
               AND ACCT_TYP IN ('20303', '20304') --20303 回购式再贴现  20304 买断式再贴现
             GROUP BY A.ORG_NUM
            UNION ALL
            SELECT I_DATADATE AS DATA_DATE,
                   CASE
                     WHEN A.ORG_NUM = '009801' THEN
                      '009804'
                   END,     ---中期便利账在清算中心，报在金融市场部
                   'G25_1_1.2.1.3.1.A.2014' AS ITEM_NUM,
                   SUM(A.BALANCE)
              FROM V_PUB_FUND_MMFUND A
             WHERE DATA_DATE = I_DATADATE
               AND (A.MATURE_DATE - D_DATADATE_CCY >= 0 AND
                   A.MATURE_DATE - D_DATADATE_CCY <= 30)
               AND A.GL_ITEM_CODE = '20040501' --中期借贷便利
             GROUP BY A.ORG_NUM;


-- 指标: G25_1_1.2.1.4.10.1.A.2014
--表外 1
    --2.1.4.10未提取的不可无条件撤销的信用便利和流动性便利
    --2.1.4.10.1零售客户和小企业
    INSERT 
    INTO `G25_1_1.2.1.4.10.1.A.2014` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'G25_1_1.2.1.4.10.1.A.2014' ITEM_NUM, --折算前
       SUM(T.BAL_1_30) AS CUR_BAL
        FROM CBRC_FDM_CUST_LNAC_INFO T
       WHERE T.FLAG = '01'
       GROUP BY ORG_NUM;

/* UNION ALL --信用卡未使用额度  取数逻辑不对暂时不取
    SELECT I_DATADATE AS DATA_DATE,
           '009803',
           'G25_1_1.2.1.4.10.1.A.2014' ITEM_NUM, --折算前
           SUM(NVL(CRED_LIMIT, 0) + NVL(TEMP_LIMIT, 0)
               +NVL(MP_BAL, 0)) - SUM(NVL(DEBIT_BAL, 0))
      FROM DATACORE.CUP_ACCT_ALL T1
      LEFT JOIN (SELECT SUM(DEBIT_BAL) AS DEBIT_BAL
                   FROM FDM_LNAC_GL
                  WHERE DATA_DATE = I_DATADATE
                    AND (GL_ACCOUNT LIKE '13604%' OR
                        GL_ACCOUNT LIKE '12203%')) T2 ON 1 = 1
     WHERE T1.ODS_DATA_DATE <= I_DATADATE;

/* 1、承兑汇票 正常表外30以内+所有逾期  逾期与G21一样都取
    2、未使用额度 30天内有效的未使用额度，不需要限制到期日所有都取
    3、不可撤销贷款承诺*/


        -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
          --表外 1
          --2.1.4.10未提取的不可无条件撤销的信用便利和流动性便利
          --2.1.4.10.1零售客户和小企业
          --2.1.4.10.2大中型企业
          --2.1.4.10.2.1信用便利

         INSERT 
         INTO `G25_1_1.2.1.4.10.1.A.2014` 
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_1,
            COL_2,
            COL_3,
            COL_4,
            COL_7,
            COL_8,
            COL_9)
           SELECT 
            I_DATADATE,
            CASE
              WHEN T1.ORG_NUM LIKE '5100%' THEN
               '510000'
              WHEN T1.ORG_NUM LIKE '5200%' THEN
               '520000'
              WHEN T1.ORG_NUM LIKE '5300%' THEN
               '530000'
              WHEN T1.ORG_NUM LIKE '5400%' THEN
               '540000'
              WHEN T1.ORG_NUM LIKE '5500%' THEN
               '550000'
              WHEN T1.ORG_NUM LIKE '5600%' THEN
               '560000'
              WHEN T1.ORG_NUM LIKE '5700%' THEN
               '570000'
              WHEN T1.ORG_NUM LIKE '5800%' THEN
               '580000'
              WHEN T1.ORG_NUM LIKE '5900%' THEN
               '590000'
              WHEN T1.ORG_NUM LIKE '6000%' THEN
               '600000'
              ELSE
               '990000'
            END AS ORG_NUM,
            T1.DATA_DEPARTMENT, --数据条线
            'CBRC' AS SYS_NAM,
            'G2501' REP_NUM,
            CASE
              WHEN T1.CORP_SCALE IN ('P', 'S', 'T') THEN --零售  小型  微型
               'G25_1_1.2.1.4.10.1.A.2014'
              WHEN T1.CORP_SCALE IN ('B', 'M', '9') THEN --大型   中型  其他
               'G25_1_1.2.1.4.10.2.1.A.2014'
            END AS ITEM_NUM,
            T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE, --贷款余额
            T1.ACCT_NUM AS COL1, --表外账号
            T1.CURR_CD AS COL2, --币种
            T1.ITEM_CD AS COL3, --科目
            TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') AS COL4, --到期日
            T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
            CASE
              WHEN T1.LOAN_GRADE_CD = '1' THEN
               '正常'
              WHEN T1.LOAN_GRADE_CD = '2' THEN
               '关注'
              WHEN T1.LOAN_GRADE_CD = '3' THEN
               '次级'
              WHEN T1.LOAN_GRADE_CD = '4' THEN
               '可疑'
              WHEN T1.LOAN_GRADE_CD = '5' THEN
               '损失'
            END AS COL8, --五级分类
            CASE
              WHEN T1.CORP_SCALE = '9' THEN
               '其他'
              ELSE
               T3.M_NAME
            END AS COL9 --企业规模
             FROM CBRC_FDM_LNAC_PMT_BW T1
             LEFT JOIN L_PUBL_RATE T2
               ON T2.DATA_DATE = I_DATADATE
              AND T2.BASIC_CCY = T1.CURR_CD
              AND T2.FORWARD_CCY = 'CNY'
             LEFT JOIN A_REPT_DWD_MAPPING T3
               ON T1.CORP_SCALE = T3.M_CODE
              AND T3.M_TABLECODE = 'CORP_SCALE'
            WHERE ((T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.PMT_REMAIN_TERM_C <= 30) OR T1.PMT_REMAIN_TERM_C <= 0)
              AND T1.ITEM_CD in ('70200101', '70200201', '70300201') --应收银行承兑汇票款项、应付银行承兑汇票款项、不可撤销贷款承诺
              AND T1.NEXT_PAYMENT <> 0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
         INSERT 
         INTO `G25_1_1.2.1.4.10.1.A.2014` 
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_1,
            COL_2,
            COL_3,
            COL_4,
            COL_7,
            COL_8,
            COL_9)
           SELECT 
            I_DATADATE,
            CASE
              WHEN T1.ORG_NUM LIKE '5100%' THEN
               '510000'
              WHEN T1.ORG_NUM LIKE '5200%' THEN
               '520000'
              WHEN T1.ORG_NUM LIKE '5300%' THEN
               '530000'
              WHEN T1.ORG_NUM LIKE '5400%' THEN
               '540000'
              WHEN T1.ORG_NUM LIKE '5500%' THEN
               '550000'
              WHEN T1.ORG_NUM LIKE '5600%' THEN
               '560000'
              WHEN T1.ORG_NUM LIKE '5700%' THEN
               '570000'
              WHEN T1.ORG_NUM LIKE '5800%' THEN
               '580000'
              WHEN T1.ORG_NUM LIKE '5900%' THEN
               '590000'
              WHEN T1.ORG_NUM LIKE '6000%' THEN
               '600000'
              ELSE
               '990000'
            END AS ORG_NUM,
            T1.DATA_DEPARTMENT, --数据条线
            'CBRC' AS SYS_NAM,
            'G2501' REP_NUM,
            CASE
              WHEN T1.CORP_SCALE IN ('P', 'S', 'T') THEN --零售  小型  微型
               'G25_1_1.2.1.4.10.1.A.2014'
              WHEN T1.CORP_SCALE IN ('B', 'M', '9') THEN --大型   中型  其他
               'G25_1_1.2.1.4.10.2.1.A.2014'
            END AS ITEM_NUM,
            T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE, --贷款余额
            T1.ACCT_NUM AS COL1, --表外账号
            T1.CURR_CD AS COL2, --币种
            T1.ITEM_CD AS COL3, --科目
            TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') AS COL4, --实际到期日
            T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
            CASE
              WHEN T1.LOAN_GRADE_CD = '1' THEN
               '正常'
              WHEN T1.LOAN_GRADE_CD = '2' THEN
               '关注'
              WHEN T1.LOAN_GRADE_CD = '3' THEN
               '次级'
              WHEN T1.LOAN_GRADE_CD = '4' THEN
               '可疑'
              WHEN T1.LOAN_GRADE_CD = '5' THEN
               '损失'
            END AS COL8, --五级分类
            CASE
              WHEN T1.CORP_SCALE = '9' THEN
               '其他'
              ELSE
               T3.M_NAME
            END AS COL9 --企业规模
             FROM CBRC_FDM_LNAC_PMT_BW T1
             LEFT JOIN L_PUBL_RATE T2
               ON T2.DATA_DATE = I_DATADATE
              AND T2.BASIC_CCY = T1.CURR_CD
              AND T2.FORWARD_CCY = 'CNY'
             LEFT JOIN A_REPT_DWD_MAPPING T3
               ON T1.CORP_SCALE = T3.M_CODE
              AND T3.M_TABLECODE = 'CORP_SCALE'
            WHERE T1.ITEM_CD = '60302_G25'
              AND T1.NEXT_PAYMENT <> 0;

--17.2信用和流动性便利（不可无条件撤销） 信用卡和承兑汇票、未使用授信额度放在6月内
    INSERT INTO `G25_1_1.2.1.4.10.1.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.16.2.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G2501'
         AND ITEM_NUM IN
             ('G25_1_1.2.1.4.10.1.A.2014', 'G25_1_1.2.1.4.10.2.1.A.2014')
       GROUP BY T.ORG_NUM;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --17.2信用和流动性便利（不可无条件撤销） 信用卡和承兑汇票、未使用授信额度放在6月内
      INSERT
      INTO `G25_1_1.2.1.4.10.1.A.2014` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_7,
         COL_8)
        SELECT DATA_DATE,
               ORG_NUM,
               DATA_DEPARTMENT,
               SYS_NAM,
               'G2502' AS REP_NUM,
               'G25_2_2.16.2.A.2016' AS ITEM_NUM,
               TOTAL_VALUE,
               COL_1,
               COL_2,
               COL_3,
               COL_4,
               COL_7,
               COL_8
          FROM CBRC_A_REPT_DWD_G2501
         WHERE ITEM_NUM IN
               ('G25_1_1.2.1.4.10.1.A.2014', 'G25_1_1.2.1.4.10.2.1.A.2014');

/* INSERT INTO `G25_1_1.2.1.4.10.1.A.2014`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.16.2.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G2501'
         AND ITEM_NUM IN
             ('G25_1_1.2.1.4.10.1.A.2014', 'G25_1_1.2.1.4.10.2.1.A.2014')
       GROUP BY T.ORG_NUM;


-- 指标: G25_1_1.1.1.1.A.2014
--节假日临时表

    --开始处理存款部分
    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.REP_NUM = 'G2501'
       AND DATA_DATE = I_DATADATE
        AND T.ITEM_NUM <> 'G25_1_1.1.1.1.A.2014';

--开始处理存款部分
    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.REP_NUM = 'G2501'
       AND DATA_DATE = I_DATADATE
       AND T.ITEM_NUM <> 'G25_1_1.1.1.1.A.2014';


