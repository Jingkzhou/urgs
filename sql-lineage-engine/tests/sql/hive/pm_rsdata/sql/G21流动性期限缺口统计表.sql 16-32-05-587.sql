-- ============================================================
-- 文件名: G21流动性期限缺口统计表.sql
-- 生成时间: 2025-12-18 13:53:39
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 7 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN
                'G21_1.7.1.2.H.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
                'G21_1.7.1.2.H1.2018' ---10年以上
               WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
                'G21_1.7.1.2.G1.2018' --5-10年
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
                'G21_1.7.1.2.F.2018' --1-5年
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
                'G21_1.7.1.2.E.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
                'G21_1.7.1.2.D.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
                'G21_1.7.1.2.C.2018'
               WHEN BOOK_TYPE = '1' OR (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
                'G21_1.7.1.2.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
               WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                'G21_1.7.1.2.A.2018'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN A.ACCOUNTANT_TYPE = '2' AND A.BOOK_TYPE = 1 THEN
                    (A.PRINCIPAL_BALANCE_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                    A.ACCT_BAL_CNY)
                   ELSE
                    (A.ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                    A.ACCT_BAL_CNY)
                 END) AS AMT ---中登净价金额*可用面额/持有仓位
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A --债券投资分析表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND ACCT_BAL_CNY <> 0
         AND ((A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') OR --地方政府债
             (A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
             A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是AA的债券
             OR A.STOCK_CD IN ('032000573', '032001060')) --20四平城投PPN001  20四平城投PPN002 RPA取数没有债券评级,此处特殊处理
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN
                   'G21_1.7.1.2.H.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
                   'G21_1.7.1.2.H1.2018' ---10年以上
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
                   'G21_1.7.1.2.G1.2018' --5-10年
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
                   'G21_1.7.1.2.F.2018' --1-5年
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
                   'G21_1.7.1.2.E.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
                   'G21_1.7.1.2.D.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
                   'G21_1.7.1.2.C.2018'
                  WHEN BOOK_TYPE = '1' OR
                       (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
                   'G21_1.7.1.2.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
                  WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                   'G21_1.7.1.2.A.2018'
                END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN
                'G21_1.7.1.2.H.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
                'G21_1.7.1.2.H1.2018' ---10年以上
               WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
                'G21_1.7.1.2.G1.2018' --5-10年
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
                'G21_1.7.1.2.F.2018' --1-5年
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
                'G21_1.7.1.2.E.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
                'G21_1.7.1.2.D.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
                'G21_1.7.1.2.C.2018'
               WHEN BOOK_TYPE = '1' OR (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
                'G21_1.7.1.2.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
               WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                'G21_1.7.1.2.A.2018'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN A.ACCOUNTANT_TYPE = '2' AND A.BOOK_TYPE = 1 THEN
                    (A.PRINCIPAL_BALANCE_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                    A.ACCT_BAL_CNY)
                   ELSE
                    (A.ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                    A.ACCT_BAL_CNY)
                 END) AS AMT ---中登净价金额*可用面额/持有仓位
        FROM CBRC_TMP_A_CBRC_BOND_BAL A --债券投资分析表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND ACCT_BAL_CNY <> 0
         AND ((A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') OR --地方政府债
             (A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
             A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是AA的债券
             OR A.STOCK_CD IN ('032000573', '032001060')) --20四平城投PPN001  20四平城投PPN002 RPA取数没有债券评级,此处特殊处理
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN
                   'G21_1.7.1.2.H.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
                   'G21_1.7.1.2.H1.2018' ---10年以上
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
                   'G21_1.7.1.2.G1.2018' --5-10年
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
                   'G21_1.7.1.2.F.2018' --1-5年
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
                   'G21_1.7.1.2.E.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
                   'G21_1.7.1.2.D.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
                   'G21_1.7.1.2.C.2018'
                  WHEN BOOK_TYPE = '1' OR
                       (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
                   'G21_1.7.1.2.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
                  WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                   'G21_1.7.1.2.A.2018'
                END
) q_0
INSERT INTO `G21_1.7.1.2.G1.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.2.B.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.2.H1.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.2.D.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.2.F.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.2.E.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.2.C.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- ========== 逻辑组 1: 共 7 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

INSERT INTO `__INDICATOR_PLACEHOLDER__` 
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
                  T1.DATA_DATE,
                  T1.ORG_NUM,
                  T1.DATA_DEPARTMENT,
                  'CBRC' AS SYS_NAM,
                  'G21' REP_NUM,
                  CASE --ADD BY DJH 20220518如果逾期天数是空值或者0,但是实际到期日小于等于当前日期数据,放在次日
                    WHEN (T1.PMT_REMAIN_TERM_C = 1 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%') or
                         (T1.ACCT_STATUS_1104 = '10' AND
                         T1.PMT_REMAIN_TERM_C <= 0 AND
                         T1.ITEM_CD NOT LIKE '1306%') THEN
                     'G21_1.6.A'
                    WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.B'
                    WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.C'
                    WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.D'
                    WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.E'
                    WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 360 * 5 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.F'
                    WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND
                         360 * 10 AND T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.M'
                    WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.N'
                    WHEN T1.IDENTITY_CODE = '2' THEN
                     'G21_1.6.H' --逾期部分全部放这里
                  END AS ITEM_NUM,
                  T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE,
                  T1.LOAN_NUM AS COL1, --贷款编号
                  T1.CURR_CD AS COL2, --币种
                  T1.ITEM_CD AS COL3, --科目
                  TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                  TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --（到期日）还款计划本金到期日/没有还款计划按照贷款实际到期日
                  T1.ACCT_NUM AS COL6, --贷款合同编号
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
                  END AS COL8 --五级分类
                 -- T1.REPAY_SEQ, --还款期数
                 -- T1.ACCT_STATUS_1104,
             FROM CBRC_FDM_LNAC_PMT T1
             LEFT JOIN L_PUBL_RATE T2
               ON T2.DATA_DATE = I_DATADATE
              AND T2.BASIC_CCY = T1.CURR_CD
              AND T2.FORWARD_CCY = 'CNY'
              AND T1.NEXT_PAYMENT <>0
) q_1
INSERT INTO `G21_1.6.E` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_1.6.C` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_1.6.D` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_1.6.F` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_1.6.B` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_1.6.M` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_1.6.N` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- 指标: G21_1.3.A
--114(存放同业)、 117(存出保证金)
    INSERT 
    INTO `G21_1.3.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.3.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.3.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.3.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.3.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.3.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.3.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.3.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.3.A'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.3.H.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
          AND A.FLAG='01'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.3.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.3.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.3.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.3.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.3.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.3.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.3.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.3.A'
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.3.H.2018'
                END;

--114(存放同业)、 117(存出保证金)
    INSERT 
    INTO `G21_1.3.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.3.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.3.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.3.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.3.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.3.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.3.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.3.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.3.A'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.3.H.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
          AND A.FLAG='01'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.3.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.3.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.3.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.3.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.3.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.3.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.3.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.3.A'
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.3.H.2018'
                END;


-- 指标: G21_16.2.D.2021
INSERT 
    INTO `G21_16.2.D.2021`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                'G21_16.2.H.2021'
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_16.2.G1.2021'
               WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                'G21_16.2.F.2021'
               WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                'G21_16.2.E.2021'
               WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                'G21_16.2.D.2021'
               WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                'G21_16.2.C.2021'
               WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                'G21_16.2.B.2021'
               WHEN (REDEMP_DATE IS NULL OR
                    REDEMP_DATE - I_DATADATE <= 1) THEN
                'G21_16.2.A.2021'
             END,
             /* CASE
               WHEN ROLL_PERIOD / 360 > 10 THEN --开放式产品滚动(或开发赎回)周期‘
                'G21_16.2.H.2021'
               WHEN ROLL_PERIOD / 360 > 5 THEN
                'G21_16.2.G.2021'
               WHEN ROLL_PERIOD > 360 THEN
                'G21_16.2.F.2021'
               WHEN ROLL_PERIOD > 90 THEN
                'G21_16.2.E.2021'
               WHEN ROLL_PERIOD > 30 THEN
                'G21_16.2.D.2021'
               WHEN ROLL_PERIOD > 7 THEN
                'G21_16.2.C.2021'
               WHEN ROLL_PERIOD > 1 THEN
                'G21_16.2.B.2021'
               WHEN (ROLL_PERIOD IS NULL OR ROLL_PERIOD < = 1) THEN
                'G21_16.2.A.2021'
             END,*/
             SUM(A.END_PROD_AMT_CNY)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                   'G21_16.2.H.2021'
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_16.2.G1.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                   'G21_16.2.F.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                   'G21_16.2.E.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                   'G21_16.2.D.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                   'G21_16.2.C.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                   'G21_16.2.B.2021'
                  WHEN (REDEMP_DATE IS NULL OR
                       REDEMP_DATE - I_DATADATE <= 1) THEN
                   'G21_16.2.A.2021'
                END;

INSERT 
    INTO `G21_16.2.D.2021`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                'G21_16.2.H.2021'
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_16.2.G1.2021'
               WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                'G21_16.2.F.2021'
               WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                'G21_16.2.E.2021'
               WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                'G21_16.2.D.2021'
               WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                'G21_16.2.C.2021'
               WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                'G21_16.2.B.2021'
               WHEN (REDEMP_DATE IS NULL OR
                    REDEMP_DATE - I_DATADATE <= 1) THEN
                'G21_16.2.A.2021'
             END,
             /* CASE
               WHEN ROLL_PERIOD / 360 > 10 THEN --开放式产品滚动(或开发赎回)周期‘
                'G21_16.2.H.2021'
               WHEN ROLL_PERIOD / 360 > 5 THEN
                'G21_16.2.G.2021'
               WHEN ROLL_PERIOD > 360 THEN
                'G21_16.2.F.2021'
               WHEN ROLL_PERIOD > 90 THEN
                'G21_16.2.E.2021'
               WHEN ROLL_PERIOD > 30 THEN
                'G21_16.2.D.2021'
               WHEN ROLL_PERIOD > 7 THEN
                'G21_16.2.C.2021'
               WHEN ROLL_PERIOD > 1 THEN
                'G21_16.2.B.2021'
               WHEN (ROLL_PERIOD IS NULL OR ROLL_PERIOD < = 1) THEN
                'G21_16.2.A.2021'
             END,*/
             SUM(A.END_PROD_AMT_CNY)
        FROM CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                   'G21_16.2.H.2021'
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_16.2.G1.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                   'G21_16.2.F.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                   'G21_16.2.E.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                   'G21_16.2.D.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                   'G21_16.2.C.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                   'G21_16.2.B.2021'
                  WHEN (REDEMP_DATE IS NULL OR
                       REDEMP_DATE - I_DATADATE <= 1) THEN
                   'G21_16.2.A.2021'
                END;


-- ========== 逻辑组 4: 共 7 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN
                'G21_1.7.1.1.H.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
                'G21_1.7.1.1.H1.2018' ---10年以上
               WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
                'G21_1.7.1.1.G1.2018' --5-10年
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
                'G21_1.7.1.1.F.2018' --1-5年
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
                'G21_1.7.1.1.E.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
                'G21_1.7.1.1.D.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
                'G21_1.7.1.1.C.2018'
               WHEN BOOK_TYPE = '1' OR (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
                'G21_1.7.1.1.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
               WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                'G21_1.7.1.1.A.2018'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN A.ACCOUNTANT_TYPE = '2' AND A.BOOK_TYPE = 1 THEN
                    (A.PRINCIPAL_BALANCE_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                    ACCT_BAL_CNY)
                   ELSE
                    (ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                    ACCT_BAL_CNY)
                 END) AS AMT ---中登净价金额*可用面额/持有仓位
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A --债券投资分析表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND ACCT_BAL_CNY <> 0
         AND ((A.ISSU_ORG = 'D02' AND A.STOCK_PRO_TYPE LIKE 'C%') OR
             (A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A')) --政策银行债 , 国债
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN
                   'G21_1.7.1.1.H.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
                   'G21_1.7.1.1.H1.2018' ---10年以上
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
                   'G21_1.7.1.1.G1.2018' --5-10年
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
                   'G21_1.7.1.1.F.2018' --1-5年
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
                   'G21_1.7.1.1.E.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
                   'G21_1.7.1.1.D.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
                   'G21_1.7.1.1.C.2018'
                  WHEN BOOK_TYPE = '1' OR
                       (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
                   'G21_1.7.1.1.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
                  WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                   'G21_1.7.1.1.A.2018'
                END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN
                'G21_1.7.1.1.H.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
                'G21_1.7.1.1.H1.2018' ---10年以上
               WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
                'G21_1.7.1.1.G1.2018' --5-10年
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
                'G21_1.7.1.1.F.2018' --1-5年
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
                'G21_1.7.1.1.E.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
                'G21_1.7.1.1.D.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
                'G21_1.7.1.1.C.2018'
               WHEN BOOK_TYPE = '1' OR (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
                'G21_1.7.1.1.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
               WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                'G21_1.7.1.1.A.2018'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN A.ACCOUNTANT_TYPE = '2' AND A.BOOK_TYPE = 1 THEN
                    (A.PRINCIPAL_BALANCE_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                    ACCT_BAL_CNY)
                   ELSE
                    (ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                    ACCT_BAL_CNY)
                 END) AS AMT ---中登净价金额*可用面额/持有仓位
        FROM CBRC_TMP_A_CBRC_BOND_BAL A --债券投资分析表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND ACCT_BAL_CNY <> 0
         AND ((A.ISSU_ORG = 'D02' AND A.STOCK_PRO_TYPE LIKE 'C%') OR
             (A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A')) --政策银行债 , 国债
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN
                   'G21_1.7.1.1.H.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
                   'G21_1.7.1.1.H1.2018' ---10年以上
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
                   'G21_1.7.1.1.G1.2018' --5-10年
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
                   'G21_1.7.1.1.F.2018' --1-5年
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
                   'G21_1.7.1.1.E.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
                   'G21_1.7.1.1.D.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
                   'G21_1.7.1.1.C.2018'
                  WHEN BOOK_TYPE = '1' OR
                       (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
                   'G21_1.7.1.1.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
                  WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                   'G21_1.7.1.1.A.2018'
                END
) q_4
INSERT INTO `G21_1.7.1.1.C.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.1.D.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.1.F.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.1.E.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.1.B.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.1.G1.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.1.H1.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- 指标: G21_1.9.G
INSERT INTO `G21_1.9.G`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

--处理133,260利息 不足的数据,与总账找齐

INSERT 
    INTO `G21_1.9.G` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       IS_TOTAL)
SELECT I_DATADATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       SUM(ITEM_VAL) AS ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       CASE
           WHEN ITEM_NUM = 'G21_1.9.G' THEN  --ADD BY DJH 20230509 里面有轧差不参与汇总
            'N'
         END IS_TOTAL
  FROM (SELECT 
         A.ORG_NUM,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         NVL(A.ITEM_VAL, 0) AS ITEM_VAL,
         ITEM_VAL_V,
         FLAG,
         B_CURR_CD
          FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI A
         WHERE A.DATA_DATE = I_DATADATE
           AND A.REP_NUM = 'G21'
        UNION ALL
        SELECT 
         B.ORG_NUM,
         'CBRC' AS SYS_NAM,
         'G21' REP_NUM,
         CASE
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YS' THEN
            'G21_1.8.A'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_WEEK' THEN
            'G21_1.8.B'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_MONTH' THEN
            'G21_1.8.C'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_1.8.D'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YEAR' THEN
            'G21_1.8.E'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_FIVE' THEN
            'G21_1.8.F'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_TEN' THEN
            'G21_1.8.M'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'MORE_TEN' THEN
            'G21_1.8.N'
           WHEN ITEM_CD =  '113201' AND B.QX = 'YQ' THEN
            'G21_1.8.H'
           WHEN  ITEM_CD = '2231' AND B.QX = 'NEXT_YS' THEN
            'G21_3.8.A'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_WEEK' THEN
            'G21_3.8.B'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_MONTH' THEN
            'G21_3.8.C'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_3.8.D'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YEAR' THEN
            'G21_3.8.E'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_FIVE' THEN
            'G21_3.8.F.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_TEN' THEN
            'G21_3.8.G1.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'MORE_TEN' THEN
            'G21_3.8.H1.2018'
         END ITEM_NUM,
         SUM(MINUS_AMT) AS MINUS_AMT,
         NULL ITEM_VAL_V,
         '2' AS FLAG,
         'ALL' CURR_CD
          FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP B
         WHERE MINUS_AMT <> 0
         GROUP BY B.ORG_NUM, ITEM_CD,QX)
 GROUP BY ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL_V, FLAG, B_CURR_CD;

INSERT INTO `G21_1.9.G`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

--处理133,260利息 不足的数据,与总账找齐

INSERT 
INTO `G21_1.9.G` 
  (DATA_DATE,
   ORG_NUM,
   DATA_DEPARTMENT,
   SYS_NAM,
   REP_NUM,
   ITEM_NUM,
   ITEM_VAL,
   ITEM_VAL_V,
   FLAG,
   B_CURR_CD,
   IS_TOTAL)
  SELECT I_DATADATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         SUM(ITEM_VAL) AS ITEM_VAL,
         ITEM_VAL_V,
         FLAG,
         B_CURR_CD,
         CASE
           WHEN ITEM_NUM = 'G21_1.9.G' THEN --ADD BY DJH 20230509 里面有轧差不参与汇总
            'N'
         END IS_TOTAL
    FROM (SELECT 
           A.ORG_NUM,
           '' AS DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           NVL(A.ITEM_VAL, 0) AS ITEM_VAL,
           ITEM_VAL_V,
           FLAG,
           B_CURR_CD
            FROM CBRC_A_REPT_ITEM_VAL_NGI A
           WHERE A.DATA_DATE = I_DATADATE
             AND A.REP_NUM = 'G21'
          UNION ALL
          SELECT 
           B.ORG_NUM,
           '' AS DATA_DEPARTMENT,
           'CBRC' AS SYS_NAM,
           'G21' REP_NUM,
           CASE
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YS' THEN
              'G21_1.8.A'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_WEEK' THEN
              'G21_1.8.B'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_MONTH' THEN
              'G21_1.8.C'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_QUARTER' THEN
              'G21_1.8.D'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YEAR' THEN
              'G21_1.8.E'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_FIVE' THEN
              'G21_1.8.F'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_TEN' THEN
              'G21_1.8.M'
             WHEN ITEM_CD = '113201' AND B.QX = 'MORE_TEN' THEN
              'G21_1.8.N'
             WHEN ITEM_CD = '113201' AND B.QX = 'YQ' THEN
              'G21_1.8.H'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YS' THEN
              'G21_3.8.A'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_WEEK' THEN
              'G21_3.8.B'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_MONTH' THEN
              'G21_3.8.C'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_QUARTER' THEN
              'G21_3.8.D'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YEAR' THEN
              'G21_3.8.E'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_FIVE' THEN
              'G21_3.8.F.2018'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_TEN' THEN
              'G21_3.8.G1.2018'
             WHEN ITEM_CD = '2231' AND B.QX = 'MORE_TEN' THEN
              'G21_3.8.H1.2018'
           END ITEM_NUM,
           SUM(MINUS_AMT) AS MINUS_AMT,
           NULL ITEM_VAL_V,
           '2' AS FLAG,
           'ALL' CURR_CD
            FROM CBRC_ITEM_MINUS_AMT_TEMP B
           WHERE MINUS_AMT <> 0
             AND ITEM_CD = '2231' ---- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级] 因为113201在明细数据中已出
           GROUP BY B.ORG_NUM, ITEM_CD, QX
          UNION ALL
          SELECT 
                 ORG_NUM,
                 DATA_DEPARTMENT,
                 SYS_NAM,
                 REP_NUM,
                 ITEM_NUM,
                 SUM(TOTAL_VALUE) AS ITEM_VAL,
                 '' ITEM_VAL_V,
                 '2' AS FLAG,
                 'ALL' CURR_CD
            FROM CBRC_A_REPT_DWD_G21
           GROUP BY ORG_NUM, DATA_DEPARTMENT, SYS_NAM, REP_NUM, ITEM_NUM)
   GROUP BY ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            ITEM_VAL_V,
            FLAG,
            B_CURR_CD;


-- ========== 逻辑组 6: 共 7 个指标 ==========
FROM (
SELECT I_DATADATE,
             CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN A.ORG_NUM LIKE '%98%' THEN
                A.ORG_NUM
              WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
               ELSE
                SUBSTR(A.ORG_NUM, 1, 4) || '00'
             END,
             CASE
               WHEN (A.MATUR_DATE_ACCURED - I_DATADATE) / 360 > 10 THEN
                'G21_3.8.H1.2018'
               WHEN (A.MATUR_DATE_ACCURED - I_DATADATE) / 360 > 5 THEN
                'G21_3.8.G1.2018'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 360 THEN
                'G21_3.8.F.2018'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 90 THEN
                'G21_3.8.E'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 30 THEN
                'G21_3.8.D'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 7 THEN
                'G21_3.8.C'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 1 THEN
                'G21_3.8.B'
               WHEN (A.MATUR_DATE_ACCURED IS NULL OR A.MATUR_DATE_ACCURED - I_DATADATE <=1) THEN
                'G21_3.8.A'
             END AS ITEM_NUM,
             --SUM(NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0))  AS ITEM_VAL
             SUM(CASE
                    WHEN A.ORG_NUM = '009820' AND A.FLAG = '10' THEN NVL(ACCT_BAL_RMB,0) + NVL(INTEREST_ACCURAL, 0)
                    WHEN A.ORG_NUM IN ('009804','009801') AND A.FLAG IN ('05','07') THEN NVL(INTEREST_ACCURAL, 0)
                    ELSE NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                 END) AS ITEM_VAL-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君]增加009801清算中心外币业务2003拆入资金、2111卖出回购本金对应的应付利息
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
        -- AND A.ORG_NUM <> '009804' --ADD BY CHM 金融市场部口径不一,单独处理
        -- AND (A.ACCT_TYP <> '9999' or A.ACCT_TYP is null) --虚拟账户应计利息放在3.9没有确定到期日的负债
       GROUP BY CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                  WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN (A.MATUR_DATE_ACCURED -
                       I_DATADATE) / 360 > 10 THEN
                   'G21_3.8.H1.2018'
                  WHEN (A.MATUR_DATE_ACCURED -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_3.8.G1.2018'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 360 THEN
                   'G21_3.8.F.2018'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 90 THEN
                   'G21_3.8.E'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 30 THEN
                   'G21_3.8.D'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 7 THEN
                   'G21_3.8.C'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 1 THEN
                   'G21_3.8.B'
                  WHEN (A.MATUR_DATE_ACCURED IS NULL OR A.MATUR_DATE_ACCURED - I_DATADATE <=1) THEN
                   'G21_3.8.A'
                END
      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_3.8.B' AS ITEM_NUM,
             sum(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
            --AND A.ITEM_CD ='11003'
         AND ITEM_CD = '3.8.B'
       GROUP BY I_DATADATE, A.ORG_NUM;

INSERT INTO
 `__INDICATOR_PLACEHOLDER__` (
ORG_NUM ,
MINUS_AMT ,
ITEM_CD ,
CURR_CD,
QX
)
SELECT C.ORG_NUM, TEMP.MINUS_AMT, TEMP.ITEM_CD, TEMP.CURR_CD, C.QX
  FROM ( SELECT A.ORG_NUM,A.QX
         FROM (SELECT CASE
                        WHEN T.ITEM_NUM = 'G21_3.8.A' THEN
                         'NEXT_YS'
                        WHEN T.ITEM_NUM = 'G21_3.8.B' THEN
                         'NEXT_WEEK'
                        WHEN T.ITEM_NUM = 'G21_3.8.C' THEN
                         'NEXT_MONTH'
                        WHEN T.ITEM_NUM = 'G21_3.8.D' THEN
                         'NEXT_QUARTER'
                        WHEN T.ITEM_NUM = 'G21_3.8.E' THEN
                         'NEXT_YEAR'
                        WHEN T.ITEM_NUM = 'G21_3.8.F.2018' THEN
                         'NEXT_FIVE'
                        WHEN T.ITEM_NUM = 'G21_3.8.G1.2018' THEN
                         'NEXT_TEN'
                        WHEN T.ITEM_NUM = 'G21_3.8.H1.2018' THEN
                         'MORE_TEN'
                      END QX,
                      T.ORG_NUM, --在3.8已经处理成支行了,直接关联
                      SUM(T.ITEM_VAL) ITEM_VAL,
                      ROW_NUMBER() OVER(PARTITION BY T.ORG_NUM ORDER BY SUM(T.ITEM_VAL) DESC) AS RN
                 FROM PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI T
                WHERE T.ITEM_NUM LIKE 'G21_3.8%'
                GROUP BY ITEM_NUM, T.ORG_NUM) A
        WHERE A.RN = 1) C
 INNER JOIN PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1 TEMP
    ON C.ORG_NUM = TEMP.ORG_NUM
   AND TEMP.MINUS_AMT < 0
   AND TEMP.ITEM_CD = '2231';

--处理133,260利息 不足的数据,与总账找齐

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       IS_TOTAL)
SELECT I_DATADATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       SUM(ITEM_VAL) AS ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       CASE
           WHEN ITEM_NUM = 'G21_1.9.G' THEN  --ADD BY DJH 20230509 里面有轧差不参与汇总
            'N'
         END IS_TOTAL
  FROM (SELECT 
         A.ORG_NUM,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         NVL(A.ITEM_VAL, 0) AS ITEM_VAL,
         ITEM_VAL_V,
         FLAG,
         B_CURR_CD
          FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI A
         WHERE A.DATA_DATE = I_DATADATE
           AND A.REP_NUM = 'G21'
        UNION ALL
        SELECT 
         B.ORG_NUM,
         'CBRC' AS SYS_NAM,
         'G21' REP_NUM,
         CASE
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YS' THEN
            'G21_1.8.A'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_WEEK' THEN
            'G21_1.8.B'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_MONTH' THEN
            'G21_1.8.C'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_1.8.D'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YEAR' THEN
            'G21_1.8.E'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_FIVE' THEN
            'G21_1.8.F'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_TEN' THEN
            'G21_1.8.M'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'MORE_TEN' THEN
            'G21_1.8.N'
           WHEN ITEM_CD =  '113201' AND B.QX = 'YQ' THEN
            'G21_1.8.H'
           WHEN  ITEM_CD = '2231' AND B.QX = 'NEXT_YS' THEN
            'G21_3.8.A'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_WEEK' THEN
            'G21_3.8.B'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_MONTH' THEN
            'G21_3.8.C'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_3.8.D'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YEAR' THEN
            'G21_3.8.E'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_FIVE' THEN
            'G21_3.8.F.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_TEN' THEN
            'G21_3.8.G1.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'MORE_TEN' THEN
            'G21_3.8.H1.2018'
         END ITEM_NUM,
         SUM(MINUS_AMT) AS MINUS_AMT,
         NULL ITEM_VAL_V,
         '2' AS FLAG,
         'ALL' CURR_CD
          FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP B
         WHERE MINUS_AMT <> 0
         GROUP BY B.ORG_NUM, ITEM_CD,QX)
 GROUP BY ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL_V, FLAG, B_CURR_CD;

--11003与221,222,223,225扎差负债方 260应付利息

    --其中的260应计利息处理
    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN A.ORG_NUM LIKE '%98%' THEN
                A.ORG_NUM
              WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
               ELSE
                SUBSTR(A.ORG_NUM, 1, 4) || '00'
             END,
             CASE
               WHEN (A.MATUR_DATE_ACCURED - I_DATADATE) / 360 > 10 THEN
                'G21_3.8.H1.2018'
               WHEN (A.MATUR_DATE_ACCURED - I_DATADATE) / 360 > 5 THEN
                'G21_3.8.G1.2018'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 360 THEN
                'G21_3.8.F.2018'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 90 THEN
                'G21_3.8.E'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 30 THEN
                'G21_3.8.D'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 7 THEN
                'G21_3.8.C'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 1 THEN
                'G21_3.8.B'
               WHEN (A.MATUR_DATE_ACCURED IS NULL OR A.MATUR_DATE_ACCURED - I_DATADATE <=1) THEN
                'G21_3.8.A'
             END AS ITEM_NUM,
             --SUM(NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0))  AS ITEM_VAL
             SUM(CASE
                    WHEN A.ORG_NUM = '009820' AND A.FLAG = '10' THEN NVL(ACCT_BAL_RMB,0) + NVL(INTEREST_ACCURAL, 0)
                    WHEN A.ORG_NUM IN ('009804','009801') AND A.FLAG IN ('05','07') THEN NVL(INTEREST_ACCURAL, 0)
                    ELSE NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                 END) AS ITEM_VAL-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君]增加009801清算中心外币业务2003拆入资金、2111卖出回购本金对应的应付利息
        FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
        -- AND A.ORG_NUM <> '009804' --ADD BY CHM 金融市场部口径不一,单独处理
        -- AND (A.ACCT_TYP <> '9999' or A.ACCT_TYP is null) --虚拟账户应计利息放在3.9没有确定到期日的负债
       GROUP BY CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                  WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN (A.MATUR_DATE_ACCURED -
                       I_DATADATE) / 360 > 10 THEN
                   'G21_3.8.H1.2018'
                  WHEN (A.MATUR_DATE_ACCURED -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_3.8.G1.2018'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 360 THEN
                   'G21_3.8.F.2018'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 90 THEN
                   'G21_3.8.E'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 30 THEN
                   'G21_3.8.D'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 7 THEN
                   'G21_3.8.C'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 1 THEN
                   'G21_3.8.B'
                  WHEN (A.MATUR_DATE_ACCURED IS NULL OR A.MATUR_DATE_ACCURED - I_DATADATE <=1) THEN
                   'G21_3.8.A'
                END
      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_3.8.B' AS ITEM_NUM,
             sum(A.DEBIT_BAL)
        FROM CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
            --AND A.ITEM_CD ='11003'
         AND ITEM_CD = '3.8.B'
       GROUP BY I_DATADATE, A.ORG_NUM;

INSERT INTO
 `__INDICATOR_PLACEHOLDER__` (
ORG_NUM ,
MINUS_AMT ,
ITEM_CD ,
CURR_CD,
QX
)
SELECT C.ORG_NUM, TEMP.MINUS_AMT, TEMP.ITEM_CD, TEMP.CURR_CD, C.QX
  FROM ( SELECT A.ORG_NUM,A.QX
         FROM (SELECT CASE
                        WHEN T.ITEM_NUM = 'G21_3.8.A' THEN
                         'NEXT_YS'
                        WHEN T.ITEM_NUM = 'G21_3.8.B' THEN
                         'NEXT_WEEK'
                        WHEN T.ITEM_NUM = 'G21_3.8.C' THEN
                         'NEXT_MONTH'
                        WHEN T.ITEM_NUM = 'G21_3.8.D' THEN
                         'NEXT_QUARTER'
                        WHEN T.ITEM_NUM = 'G21_3.8.E' THEN
                         'NEXT_YEAR'
                        WHEN T.ITEM_NUM = 'G21_3.8.F.2018' THEN
                         'NEXT_FIVE'
                        WHEN T.ITEM_NUM = 'G21_3.8.G1.2018' THEN
                         'NEXT_TEN'
                        WHEN T.ITEM_NUM = 'G21_3.8.H1.2018' THEN
                         'MORE_TEN'
                      END QX,
                      T.ORG_NUM, --在3.8已经处理成支行了,直接关联
                      SUM(T.ITEM_VAL) ITEM_VAL,
                      ROW_NUMBER() OVER(PARTITION BY T.ORG_NUM ORDER BY SUM(T.ITEM_VAL) DESC) AS RN
                 FROM CBRC_G21_DATA_COLLECT_TMP_NGI T
                WHERE T.ITEM_NUM LIKE 'G21_3.8%'
                GROUP BY ITEM_NUM, T.ORG_NUM) A
        WHERE A.RN = 1) C
 INNER JOIN CBRC_ITEM_MINUS_AMT_TEMP1 TEMP
    ON C.ORG_NUM = TEMP.ORG_NUM
   AND TEMP.MINUS_AMT < 0
   AND TEMP.ITEM_CD = '2231';

--处理133,260利息 不足的数据,与总账找齐

INSERT 
INTO `__INDICATOR_PLACEHOLDER__` 
  (DATA_DATE,
   ORG_NUM,
   DATA_DEPARTMENT,
   SYS_NAM,
   REP_NUM,
   ITEM_NUM,
   ITEM_VAL,
   ITEM_VAL_V,
   FLAG,
   B_CURR_CD,
   IS_TOTAL)
  SELECT I_DATADATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         SUM(ITEM_VAL) AS ITEM_VAL,
         ITEM_VAL_V,
         FLAG,
         B_CURR_CD,
         CASE
           WHEN ITEM_NUM = 'G21_1.9.G' THEN --ADD BY DJH 20230509 里面有轧差不参与汇总
            'N'
         END IS_TOTAL
    FROM (SELECT 
           A.ORG_NUM,
           '' AS DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           NVL(A.ITEM_VAL, 0) AS ITEM_VAL,
           ITEM_VAL_V,
           FLAG,
           B_CURR_CD
            FROM CBRC_A_REPT_ITEM_VAL_NGI A
           WHERE A.DATA_DATE = I_DATADATE
             AND A.REP_NUM = 'G21'
          UNION ALL
          SELECT 
           B.ORG_NUM,
           '' AS DATA_DEPARTMENT,
           'CBRC' AS SYS_NAM,
           'G21' REP_NUM,
           CASE
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YS' THEN
              'G21_1.8.A'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_WEEK' THEN
              'G21_1.8.B'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_MONTH' THEN
              'G21_1.8.C'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_QUARTER' THEN
              'G21_1.8.D'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YEAR' THEN
              'G21_1.8.E'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_FIVE' THEN
              'G21_1.8.F'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_TEN' THEN
              'G21_1.8.M'
             WHEN ITEM_CD = '113201' AND B.QX = 'MORE_TEN' THEN
              'G21_1.8.N'
             WHEN ITEM_CD = '113201' AND B.QX = 'YQ' THEN
              'G21_1.8.H'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YS' THEN
              'G21_3.8.A'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_WEEK' THEN
              'G21_3.8.B'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_MONTH' THEN
              'G21_3.8.C'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_QUARTER' THEN
              'G21_3.8.D'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YEAR' THEN
              'G21_3.8.E'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_FIVE' THEN
              'G21_3.8.F.2018'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_TEN' THEN
              'G21_3.8.G1.2018'
             WHEN ITEM_CD = '2231' AND B.QX = 'MORE_TEN' THEN
              'G21_3.8.H1.2018'
           END ITEM_NUM,
           SUM(MINUS_AMT) AS MINUS_AMT,
           NULL ITEM_VAL_V,
           '2' AS FLAG,
           'ALL' CURR_CD
            FROM CBRC_ITEM_MINUS_AMT_TEMP B
           WHERE MINUS_AMT <> 0
             AND ITEM_CD = '2231' ---- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级] 因为113201在明细数据中已出
           GROUP BY B.ORG_NUM, ITEM_CD, QX
          UNION ALL
          SELECT 
                 ORG_NUM,
                 DATA_DEPARTMENT,
                 SYS_NAM,
                 REP_NUM,
                 ITEM_NUM,
                 SUM(TOTAL_VALUE) AS ITEM_VAL,
                 '' ITEM_VAL_V,
                 '2' AS FLAG,
                 'ALL' CURR_CD
            FROM CBRC_A_REPT_DWD_G21
           GROUP BY ORG_NUM, DATA_DEPARTMENT, SYS_NAM, REP_NUM, ITEM_NUM)
   GROUP BY ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            ITEM_VAL_V,
            FLAG,
            B_CURR_CD
) q_6
INSERT INTO `G21_3.8.G1.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.8.F.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.8.D` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.8.C` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.8.E` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.8.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.8.B` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- ========== 逻辑组 7: 共 17 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --------------------------III.附注：主要表外业务情况  12.发行的银行承兑汇票、13.发行的跟单信用证、14.发行的保函、15.提供的贷款承诺（不可无条件撤销）
     INSERT   INTO `__INDICATOR_PLACEHOLDER__` 
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
              T1.DATA_DATE,
              T1.ORG_NUM as ORGNO,
              T1.DATA_DEPARTMENT,
              'CBRC' AS SYS_NAM,
              'G21' REP_NUM,
              CASE
                WHEN T1.PMT_REMAIN_TERM_C = 1 OR T1.PMT_REMAIN_TERM_C <= 0 THEN
                 CASE
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7020' THEN --承兑汇票
                    'G21_12..A.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7010' THEN --开出信用证
                    'G21_13..A.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7040' THEN --开出保函
                    'G21_14..A.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '70300201' THEN --不可撤销贷款承诺
                    'G21_15..A.2018'
                 END
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 THEN
                 CASE
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7020' THEN --承兑汇票
                    'G21_12..B.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7010' THEN --开出信用证
                    'G21_13..B.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7040' THEN --开出保函
                    'G21_14..B.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '70300201' THEN --不可撤销贷款承诺
                    'G21_15..B.2018'
                 END
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 THEN
                 CASE
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7020' THEN --承兑汇票
                    'G21_12..C.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7010' THEN --开出信用证
                    'G21_13..C.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7040' THEN --开出保函
                    'G21_14..C.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '70300201' THEN --不可撤销贷款承诺
                    'G21_15..C.2018'
                 END
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 THEN
                 CASE
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7020' THEN --承兑汇票
                    'G21_12..D.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7010' THEN --开出信用证
                    'G21_13..D.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7040' THEN --开出保函
                    'G21_14..D.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '70300201' THEN --不可撤销贷款承诺
                    'G21_15..D.2018'
                 END
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 THEN
                 CASE
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7020' THEN --承兑汇票
                    'G21_12..E.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7010' THEN --开出信用证
                    'G21_13..E.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7040' THEN --开出保函
                    'G21_14..E.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '70300201' THEN --不可撤销贷款承诺
                    'G21_15..E.2018'
                 END
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 360 * 5 THEN
                 CASE
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7020' THEN --承兑汇票
                    'G21_12..F.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7010' THEN --开出信用证
                    'G21_13..F.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7040' THEN --开出保函
                    'G21_14..F.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '70300201' THEN --不可撤销贷款承诺
                    'G21_15..F.2018'
                 END
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND 360 * 10 THEN
                 CASE
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7020' THEN --承兑汇票
                    'G21_12..G1.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7010' THEN --开出信用证
                    'G21_13..G1.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7040' THEN --开出保函
                    'G21_14..G1.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '70300201' THEN --不可撤销贷款承诺
                    'G21_15..G1.2018'
                 END
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 THEN
                 CASE
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7020' THEN --承兑汇票
                    'G21_12..H1.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7010' THEN --开出信用证
                    'G21_13..H1.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '7040' THEN --开出保函
                    'G21_14..H1.2018'
                   WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '70300201' THEN --不可撤销贷款承诺
                    'G21_15..H1.2018'
                 END
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE,
              T1.ACCT_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --到期日
              -- T1.NEXT_PAYMENT_DT AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
              -- T1.ACCT_NUM AS COL6, --贷款合同编号
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
         FROM CBRC_FDM_LNAC_PMT_BW T1
         LEFT JOIN L_PUBL_RATE T2
           ON T2.DATA_DATE = I_DATADATE
          AND T2.BASIC_CCY = T1.CURR_CD
          AND T2.FORWARD_CCY = 'CNY'
          AND (SUBSTR(T1.ITEM_CD, 1, 4) in ('7010', '7020', '7040') OR
              T1.ITEM_CD = '70300201')
          AND T1.IDENTITY_CODE IN ('3', '4')
          AND T1.NEXT_PAYMENT <>0
) q_7
INSERT INTO `G21_12..A.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_14..A.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_14..E.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_13..C.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_13..A.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_12..D.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_13..D.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_14..F.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_12..C.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_14..B.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_14..G1.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_12..B.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_12..E.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_13..E.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_14..D.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_13..B.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_14..C.2018` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- ========== 逻辑组 8: 共 7 个指标 ==========
FROM (
SELECT I_DATADATE,
             CASE WHEN  A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN A.ORG_NUM LIKE '%98%' THEN
                A.ORG_NUM
               WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
               ELSE
                SUBSTR(A.ORG_NUM, 1, 4) || '00'
             END,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.5.1.A'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.5.1.B'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.5.1.C'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.5.1.D'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.5.1.E'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.5.1.F.2018'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.5.1.G1.2018'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.5.1.H1.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
       WHERE A.DATA_DATE = I_DATADATE
         AND ( A.GL_ITEM_CODE IN
             ('20110205', '20110110', '20110202','20110203','20110204','20110211', '20110701', '20110103','20110104','20110105','20110106',
             '20110107','20110108','20110109', '20110208','20110113', '20110114','20110115','20110209','20110210','20110207','20110112') OR
             A.GL_ITEM_CODE = '20120204'
              OR A.GL_ITEM_CODE LIKE '2010%'  --ALTER BY 石雨 JLBA202504180011
             )
       GROUP BY CASE  WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                  WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.5.1.A'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.5.1.B'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.5.1.C'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.5.1.D'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.5.1.E'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.5.1.F.2018'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.5.1.G1.2018'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.5.1.H1.2018'
                END;

--  3.5.1定期存款    202、203、205、206、215、220、2340204、251,219结构性存款
    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             CASE WHEN  A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN A.ORG_NUM LIKE '%98%' THEN
                A.ORG_NUM
               WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
               ELSE
                SUBSTR(A.ORG_NUM, 1, 4) || '00'
             END,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.5.1.A'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.5.1.B'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.5.1.C'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.5.1.D'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.5.1.E'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.5.1.F.2018'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.5.1.G1.2018'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.5.1.H1.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
       WHERE A.DATA_DATE = I_DATADATE
         AND ( A.GL_ITEM_CODE IN
             ('20110205', '20110110', '20110202','20110203','20110204','20110211', '20110701', '20110103','20110104','20110105','20110106',
             '20110107','20110108','20110109', '20110208','20110113', '20110114','20110115','20110209','20110210','20110207','20110112') OR
             A.GL_ITEM_CODE = '20120204'
              OR A.GL_ITEM_CODE LIKE '2010%'  --ALTER BY 石雨 JLBA202504180011
             )
       GROUP BY CASE  WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                  WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.5.1.A'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.5.1.B'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.5.1.C'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.5.1.D'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.5.1.E'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.5.1.F.2018'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.5.1.G1.2018'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.5.1.H1.2018'
                END
) q_8
INSERT INTO `G21_3.5.1.G1.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.5.1.B` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.5.1.H1.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.5.1.D` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.5.1.F.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.5.1.E` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.5.1.C` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- ========== 逻辑组 9: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                'G21_16.1.H.2021'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 5 THEN
                'G21_16.1.G1.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 360 THEN
                'G21_16.1.F.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 90 THEN
                'G21_16.1.E.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 30 THEN
                'G21_16.1.D.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 7 THEN
                'G21_16.1.C.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 1 THEN
                'G21_16.1.B.2021'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                    COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE <= 1) THEN
                'G21_16.1.A.2021'
             END,
             SUM(A.END_PROD_AMT_CNY)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
          AND FLAG='1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 10 THEN
                   'G21_16.1.H.2021'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_16.1.G1.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 360 THEN
                   'G21_16.1.F.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 90 THEN
                   'G21_16.1.E.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 30 THEN
                   'G21_16.1.D.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 7 THEN
                   'G21_16.1.C.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 1 THEN
                   'G21_16.1.B.2021'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                       COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE <= 1) THEN
                   'G21_16.1.A.2021'
                END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                'G21_16.1.H.2021'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 5 THEN
                'G21_16.1.G1.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 360 THEN
                'G21_16.1.F.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 90 THEN
                'G21_16.1.E.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 30 THEN
                'G21_16.1.D.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 7 THEN
                'G21_16.1.C.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 1 THEN
                'G21_16.1.B.2021'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                    COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE <= 1) THEN
                'G21_16.1.A.2021'
             END,
             SUM(A.END_PROD_AMT_CNY)
        FROM CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
          AND FLAG='1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 10 THEN
                   'G21_16.1.H.2021'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_16.1.G1.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 360 THEN
                   'G21_16.1.F.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 90 THEN
                   'G21_16.1.E.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 30 THEN
                   'G21_16.1.D.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 7 THEN
                   'G21_16.1.C.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 1 THEN
                   'G21_16.1.B.2021'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                       COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE <= 1) THEN
                   'G21_16.1.A.2021'
                END
) q_9
INSERT INTO `G21_16.1.E.2021` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_16.1.F.2021` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_16.1.D.2021` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- 指标: G21_1.1.A
INSERT 
    INTO `G21_1.1.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM AS ORG_NUM,
             'G21_1.1.A',
             sum(A.DEBIT_BAL * B.CCY_RATE)
        FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1001' --库存现金
         AND A.DEBIT_BAL <> 0
         AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
         AND A.ORG_NUM NOT LIKE '%0000' --去掉分行,汇总时不需要
         AND A.ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                               /*'510000',*/ --磐石吉银村镇银行
                               '222222', --东盛除双阳汇总
                               '333333', --新双阳
                               '444444', --净月潭除双阳
                               '555555') --长春分行（除双阳、榆树、农安）
       GROUP BY A.ORG_NUM;

INSERT 
    INTO `G21_1.1.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM AS ORG_NUM,
             'G21_1.1.A',
             sum(A.DEBIT_BAL * B.CCY_RATE)
        FROM  V_PUB_IDX_FINA_GL A
        LEFT JOIN L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1001' --库存现金
         AND A.DEBIT_BAL <> 0
         AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
         AND A.ORG_NUM NOT LIKE '%0000' --去掉分行,汇总时不需要
         AND A.ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                               /*'510000',*/ --磐石吉银村镇银行
                               '222222', --东盛除双阳汇总
                               '333333', --新双阳
                               '444444', --净月潭除双阳
                               '555555') --长春分行（除双阳、榆树、农安）
       GROUP BY A.ORG_NUM;


-- ========== 逻辑组 11: 共 9 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN (BOOK_TYPE = '2' and A.DC_DATE < 0) OR
                    STOCK_NAM = '18华阳经贸CP001' THEN
                'G21_1.7.1.H.2018'
               WHEN BOOK_TYPE = '2' and A.DC_DATE / 360 > 10 AND
                    STOCK_NAM <> '18华阳经贸CP001' THEN
                'G21_1.7.1.H1.2018' ---10年以上
               WHEN BOOK_TYPE = '2' and A.DC_DATE / 360 > 5 THEN
                'G21_1.7.1.G1.2018' --5-10年
               WHEN BOOK_TYPE = '2' and A.DC_DATE > 360 THEN
                'G21_1.7.1.F.2018' --1-5年
               WHEN BOOK_TYPE = '2' and A.DC_DATE > 90 THEN
                'G21_1.7.1.E.2018'
               WHEN BOOK_TYPE = '2' and A.DC_DATE > 30 THEN
                'G21_1.7.1.D.2018'
               WHEN BOOK_TYPE = '2' and A.DC_DATE > 7 THEN
                'G21_1.7.1.C.2018'
               WHEN BOOK_TYPE = '1' or (BOOK_TYPE = '2' and A.DC_DATE > 1) THEN
                'G21_1.7.1.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
               WHEN BOOK_TYPE = '2' and (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                'G21_1.7.1.A.2018'
             END AS ITEM_NUM,
             SUM(PRINCIPAL_BALANCE_CNY)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A --债券投资分析表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (BOOK_TYPE = '2' and A.DC_DATE < 0) OR
                       STOCK_NAM = '18华阳经贸CP001' THEN
                   'G21_1.7.1.H.2018'
                  WHEN BOOK_TYPE = '2' and A.DC_DATE / 360 > 10 AND
                       STOCK_NAM <> '18华阳经贸CP001' THEN
                   'G21_1.7.1.H1.2018' ---10年以上
                  WHEN BOOK_TYPE = '2' and A.DC_DATE / 360 > 5 THEN
                   'G21_1.7.1.G1.2018' --5-10年
                  WHEN BOOK_TYPE = '2' and A.DC_DATE > 360 THEN
                   'G21_1.7.1.F.2018' --1-5年
                  WHEN BOOK_TYPE = '2' and A.DC_DATE > 90 THEN
                   'G21_1.7.1.E.2018'
                  WHEN BOOK_TYPE = '2' and A.DC_DATE > 30 THEN
                   'G21_1.7.1.D.2018'
                  WHEN BOOK_TYPE = '2' and A.DC_DATE > 7 THEN
                   'G21_1.7.1.C.2018'
                  WHEN BOOK_TYPE = '1' or
                       (BOOK_TYPE = '2' and A.DC_DATE > 1) THEN
                   'G21_1.7.1.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
                  WHEN BOOK_TYPE = '2' and (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                   'G21_1.7.1.A.2018'
                END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN (BOOK_TYPE = '2' and A.DC_DATE < 0) OR
                    STOCK_NAM = '18华阳经贸CP001' THEN
                'G21_1.7.1.H.2018'
               WHEN BOOK_TYPE = '2' and A.DC_DATE / 360 > 10 AND
                    STOCK_NAM <> '18华阳经贸CP001' THEN
                'G21_1.7.1.H1.2018' ---10年以上
               WHEN BOOK_TYPE = '2' and A.DC_DATE / 360 > 5 THEN
                'G21_1.7.1.G1.2018' --5-10年
               WHEN BOOK_TYPE = '2' and A.DC_DATE > 360 THEN
                'G21_1.7.1.F.2018' --1-5年
               WHEN BOOK_TYPE = '2' and A.DC_DATE > 90 THEN
                'G21_1.7.1.E.2018'
               WHEN BOOK_TYPE = '2' and A.DC_DATE > 30 THEN
                'G21_1.7.1.D.2018'
               WHEN BOOK_TYPE = '2' and A.DC_DATE > 7 THEN
                'G21_1.7.1.C.2018'
               WHEN BOOK_TYPE = '1' or (BOOK_TYPE = '2' and A.DC_DATE > 1) THEN
                'G21_1.7.1.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
               WHEN BOOK_TYPE = '2' and (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                'G21_1.7.1.A.2018'
             END AS ITEM_NUM,
             SUM(PRINCIPAL_BALANCE_CNY)
        FROM CBRC_TMP_A_CBRC_BOND_BAL A --债券投资分析表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (BOOK_TYPE = '2' and A.DC_DATE < 0) OR
                       STOCK_NAM = '18华阳经贸CP001' THEN
                   'G21_1.7.1.H.2018'
                  WHEN BOOK_TYPE = '2' and A.DC_DATE / 360 > 10 AND
                       STOCK_NAM <> '18华阳经贸CP001' THEN
                   'G21_1.7.1.H1.2018' ---10年以上
                  WHEN BOOK_TYPE = '2' and A.DC_DATE / 360 > 5 THEN
                   'G21_1.7.1.G1.2018' --5-10年
                  WHEN BOOK_TYPE = '2' and A.DC_DATE > 360 THEN
                   'G21_1.7.1.F.2018' --1-5年
                  WHEN BOOK_TYPE = '2' and A.DC_DATE > 90 THEN
                   'G21_1.7.1.E.2018'
                  WHEN BOOK_TYPE = '2' and A.DC_DATE > 30 THEN
                   'G21_1.7.1.D.2018'
                  WHEN BOOK_TYPE = '2' and A.DC_DATE > 7 THEN
                   'G21_1.7.1.C.2018'
                  WHEN BOOK_TYPE = '1' or
                       (BOOK_TYPE = '2' and A.DC_DATE > 1) THEN
                   'G21_1.7.1.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
                  WHEN BOOK_TYPE = '2' and (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                   'G21_1.7.1.A.2018'
                END
) q_11
INSERT INTO `G21_1.7.1.G1.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.A.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.C.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.D.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.F.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.H.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.B.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.H1.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.1.E.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- ========== 逻辑组 12: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A.2018'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A.2018'
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H.2018'
                END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A.2018'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A.2018'
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H.2018'
                END
) q_12
INSERT INTO `G21_1.8.B.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.8.D.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.8.E.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.8.C.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- ========== 逻辑组 13: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

INSERT INTO `__INDICATOR_PLACEHOLDER__` 
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
                  T1.DATA_DATE,
                  T1.ORG_NUM,
                  T1.DATA_DEPARTMENT,
                  'CBRC' AS SYS_NAM,
                  'G21' REP_NUM,
                  CASE --ADD BY DJH 20220518如果逾期天数是空值或者0,但是实际到期日小于等于当前日期数据,放在次日
                    WHEN (T1.PMT_REMAIN_TERM_C = 1 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%') or
                         (T1.ACCT_STATUS_1104 = '10' AND
                         T1.PMT_REMAIN_TERM_C <= 0 AND
                         T1.ITEM_CD NOT LIKE '1306%') THEN
                     'G21_1.6.A'
                    WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.B'
                    WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.C'
                    WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.D'
                    WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.E'
                    WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 360 * 5 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.F'
                    WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND
                         360 * 10 AND T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.M'
                    WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 AND
                         T1.IDENTITY_CODE = '1' AND
                         T1.ITEM_CD NOT LIKE '1306%' THEN
                     'G21_1.6.N'
                    WHEN T1.IDENTITY_CODE = '2' THEN
                     'G21_1.6.H' --逾期部分全部放这里
                  END AS ITEM_NUM,
                  T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE,
                  T1.LOAN_NUM AS COL1, --贷款编号
                  T1.CURR_CD AS COL2, --币种
                  T1.ITEM_CD AS COL3, --科目
                  TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                  TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --（到期日）还款计划本金到期日/没有还款计划按照贷款实际到期日
                  T1.ACCT_NUM AS COL6, --贷款合同编号
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
                  END AS COL8 --五级分类
                 -- T1.REPAY_SEQ, --还款期数
                 -- T1.ACCT_STATUS_1104,
             FROM CBRC_FDM_LNAC_PMT T1
             LEFT JOIN L_PUBL_RATE T2
               ON T2.DATA_DATE = I_DATADATE
              AND T2.BASIC_CCY = T1.CURR_CD
              AND T2.FORWARD_CCY = 'CNY'
              AND T1.NEXT_PAYMENT <>0;

--总账补充,条线为空值
       INSERT  INTO `__INDICATOR_PLACEHOLDER__` 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE)
         SELECT I_DATADATE,
                A.ORG_NUM,
                '' AS DATA_DEPARTMENT,
                'CBRC' AS SYS_NAM,
                'G21' REP_NUM,
                'G21_1.6.A',
                SUM(A.DEBIT_BAL)
           FROM CBRC_FDM_LNAC_GL A
          WHERE A.DATA_DATE = I_DATADATE
            AND ITEM_CD = '1.6.A' --'13604' 信用卡逾期
            AND A.DEBIT_BAL <>0
          GROUP BY A.ORG_NUM
         UNION ALL
         SELECT  I_DATADATE,
                A.ORG_NUM,
                '' AS DATA_DEPARTMENT,
                'CBRC' AS SYS_NAM,
                'G21' REP_NUM,
                'G21_1.6.H',
                sum(A.DEBIT_BAL)
           FROM CBRC_FDM_LNAC_GL A
          WHERE A.DATA_DATE = I_DATADATE
            AND ITEM_CD = '1.6.H' -- '12203' 信用卡
            AND A.DEBIT_BAL <>0
          GROUP BY A.ORG_NUM
) q_13
INSERT INTO `G21_1.6.H` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G21_1.6.A` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- 指标: G21_1.8.H
---1.9其他有确定到期日的资产 : 买入返售应收利息+同业存单应收利息+债券投资应收利息
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1111买入返售本金对应的应收利息
    INSERT 
    INTO `G21_1.8.H`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '03' --买入返售
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `G21_1.8.H`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04' --同业存单
      --AND ORG_NUM = '009804'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `G21_1.8.H`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '05' --债券投资
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

所有AC账户（除3笔特殊账户）,按剩余期限划分取应收利息,其中2笔华创证券有限责任公司的到期日特殊处理成2028/11/30处理后划分；
        +140万+63.32万(固定值)--固定值放逾期
        G01的11.其他应收款009820机构放逾期；*/

     --ADD BY DJH 20240510  金融市场部 拆放同业利息补充进来
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金本金对应的应收利息
    INSERT 
    INTO `G21_1.8.H`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(A.INTEREST_ACCURAL)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG IN ('01', '02' /*, '04'*/, '06', '07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资) 08(AC账户)  已在金融市场取数
        -- AND A.ORG_NUM IN ('009820', '009804')
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

--ADD BY DJH 20240510  同业金融部
    INSERT
    INTO `G21_1.8.H`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009820' AS ORG_NUM,
             'G21_1.8.H' AS ITEM_NUM,
             T.CREDIT_BAL
        FROM PM_RSDATA.SMTMODS_L_FINA_GL T
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'BWB'
         AND ITEM_CD IN ('12310101') -- 12310101 其他应收款坏账准备固定值放逾期 63.32万
         AND T.ORG_NUM = '009820';

--ADD BY DJH 20240510  同业金融部
    INSERT
    INTO `G21_1.8.H`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009820' AS ORG_NUM, --只有009820
             'G21_1.8.H' AS ITEM_NUM,
             1400000 AS ITEM_VAL --140万固定值放逾期
        FROM SYSTEM.DUAL;

--ADD BY DJH 20240510  投资银行部
    --009817机构存量的非标的应收利息+其他应收款按剩余期限划分


    INSERT INTO `G21_1.8.H`  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN 'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN 'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN 'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN 'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN 'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN 'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN 'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN 'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR  T1.PLA_MATURITY_DATE - I_DATADATE = 0  THEN
              'G21_1.8.A'
           END ITEM_NUM,
           SUM(T.INTEREST_ACCURAL+T.QTYSK)
      FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL T
      LEFT JOIN (SELECT Q.ACCT_NUM,
                        Q.PLA_MATURITY_DATE,
                        ROW_NUMBER() OVER(PARTITION BY Q.ACCT_NUM ORDER BY Q.PLA_MATURITY_DATE) RN
                   FROM PM_RSDATA.SMTMODS_L_ACCT_FUND_MMFUND_PAYM_SCHED Q
                  WHERE Q.DATA_DATE = I_DATADATE
                    AND DATA_SOURCE = '投行业务'
                    AND Q.PLA_MATURITY_DATE > I_DATADATE
                 ) T1
        ON T.ACCT_NUM = T1.ACCT_NUM
       AND T1.RN = 1
     WHERE T.DATA_DATE = I_DATADATE
       AND T.FLAG = '09'
       --由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第1.9项,除去逾期部分其余不在系统取数,业务手填
       AND (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE)
     GROUP BY
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN
              'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
              'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
              'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN
              'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN
              'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN
              'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN
              'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN
              'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR
                  T1.PLA_MATURITY_DATE - I_DATADATE = 0 THEN
              'G21_1.8.A'
           END;

INSERT INTO `G21_1.8.H`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

--处理133,260利息 不足的数据,与总账找齐

INSERT 
    INTO `G21_1.8.H` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       IS_TOTAL)
SELECT I_DATADATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       SUM(ITEM_VAL) AS ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       CASE
           WHEN ITEM_NUM = 'G21_1.9.G' THEN  --ADD BY DJH 20230509 里面有轧差不参与汇总
            'N'
         END IS_TOTAL
  FROM (SELECT 
         A.ORG_NUM,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         NVL(A.ITEM_VAL, 0) AS ITEM_VAL,
         ITEM_VAL_V,
         FLAG,
         B_CURR_CD
          FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI A
         WHERE A.DATA_DATE = I_DATADATE
           AND A.REP_NUM = 'G21'
        UNION ALL
        SELECT 
         B.ORG_NUM,
         'CBRC' AS SYS_NAM,
         'G21' REP_NUM,
         CASE
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YS' THEN
            'G21_1.8.A'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_WEEK' THEN
            'G21_1.8.B'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_MONTH' THEN
            'G21_1.8.C'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_1.8.D'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YEAR' THEN
            'G21_1.8.E'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_FIVE' THEN
            'G21_1.8.F'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_TEN' THEN
            'G21_1.8.M'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'MORE_TEN' THEN
            'G21_1.8.N'
           WHEN ITEM_CD =  '113201' AND B.QX = 'YQ' THEN
            'G21_1.8.H'
           WHEN  ITEM_CD = '2231' AND B.QX = 'NEXT_YS' THEN
            'G21_3.8.A'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_WEEK' THEN
            'G21_3.8.B'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_MONTH' THEN
            'G21_3.8.C'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_3.8.D'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YEAR' THEN
            'G21_3.8.E'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_FIVE' THEN
            'G21_3.8.F.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_TEN' THEN
            'G21_3.8.G1.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'MORE_TEN' THEN
            'G21_3.8.H1.2018'
         END ITEM_NUM,
         SUM(MINUS_AMT) AS MINUS_AMT,
         NULL ITEM_VAL_V,
         '2' AS FLAG,
         'ALL' CURR_CD
          FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP B
         WHERE MINUS_AMT <> 0
         GROUP BY B.ORG_NUM, ITEM_CD,QX)
 GROUP BY ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL_V, FLAG, B_CURR_CD;

---1.9其他有确定到期日的资产 : 买入返售应收利息+同业存单应收利息+债券投资应收利息
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1111买入返售本金对应的应收利息
    INSERT 
    INTO `G21_1.8.H`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '03' --买入返售
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `G21_1.8.H`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04' --同业存单
      --AND ORG_NUM = '009804'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `G21_1.8.H`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '05' --债券投资
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

所有AC账户（除3笔特殊账户）,按剩余期限划分取应收利息,其中2笔华创证券有限责任公司的到期日特殊处理成2028/11/30处理后划分；
        +140万+63.32万(固定值)--固定值放逾期
        G01的11.其他应收款009820机构放逾期；*/

     --ADD BY DJH 20240510  金融市场部 拆放同业利息补充进来
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金本金对应的应收利息
    INSERT 
    INTO `G21_1.8.H`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(A.INTEREST_ACCURAL)
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG IN ('01', '02' /*, '04'*/, '06', '07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资) 08(AC账户)  已在金融市场取数
        -- AND A.ORG_NUM IN ('009820', '009804')
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

--ADD BY DJH 20240510  同业金融部
    INSERT
    INTO `G21_1.8.H`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009820' AS ORG_NUM,
             'G21_1.8.H' AS ITEM_NUM,
             T.CREDIT_BAL
        FROM L_FINA_GL T
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'BWB'
         AND ITEM_CD IN ('12310101') -- 12310101 其他应收款坏账准备固定值放逾期 63.32万
         AND T.ORG_NUM = '009820';

--ADD BY DJH 20240510  同业金融部
    INSERT
    INTO `G21_1.8.H`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009820' AS ORG_NUM, --只有009820
             'G21_1.8.H' AS ITEM_NUM,
             1400000 AS ITEM_VAL --140万固定值放逾期
        FROM SYSTEM.DUAL;

--ADD BY DJH 20240510  投资银行部
    --009817机构存量的非标的应收利息+其他应收款按剩余期限划分


    INSERT INTO `G21_1.8.H`  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN 'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN 'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN 'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN 'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN 'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN 'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN 'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN 'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR  T1.PLA_MATURITY_DATE - I_DATADATE = 0  THEN
              'G21_1.8.A'
           END ITEM_NUM,
           SUM(T.INTEREST_ACCURAL+T.QTYSK)
      FROM CBRC_TMP_A_CBRC_LOAN_BAL T
      LEFT JOIN (SELECT Q.ACCT_NUM,
                        Q.PLA_MATURITY_DATE,
                        ROW_NUMBER() OVER(PARTITION BY Q.ACCT_NUM ORDER BY Q.PLA_MATURITY_DATE) RN
                   FROM L_ACCT_FUND_MMFUND_PAYM_SCHED Q
                  WHERE Q.DATA_DATE = I_DATADATE
                    AND DATA_SOURCE = '投行业务'
                    AND Q.PLA_MATURITY_DATE > I_DATADATE
                 ) T1
        ON T.ACCT_NUM = T1.ACCT_NUM
       AND T1.RN = 1
     WHERE T.DATA_DATE = I_DATADATE
       AND T.FLAG = '09'
       --由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第1.9项,除去逾期部分其余不在系统取数,业务手填
       AND (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE)
     GROUP BY
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN
              'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
              'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
              'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN
              'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN
              'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN
              'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN
              'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN
              'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR
                  T1.PLA_MATURITY_DATE - I_DATADATE = 0 THEN
              'G21_1.8.A'
           END;

INSERT INTO `G21_1.8.H`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

INSERT  INTO `G21_1.8.H` 
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
                   T1.DATA_DATE,
                   CASE
                     WHEN T1.ORG_NUM LIKE '5%' OR T1.ORG_NUM LIKE '6%' THEN
                      T1.ORG_NUM
                     WHEN T1.ORG_NUM LIKE '%98%' THEN
                      T1.ORG_NUM
                     WHEN t1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                      '060300'
                     ELSE
                      SUBSTR(T1.ORG_NUM, 1, 4) || '00'
                   END as ORGNO,
                   T1.DATA_DEPARTMENT,
                   'CBRC' AS SYS_NAM,
                   'G21' REP_NUM,
                   CASE
                     WHEN T1.PMT_REMAIN_TERM_C = 1 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.A'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.B'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.C'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.D'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.E'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 360 * 5 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.F'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND
                          360 * 10 AND T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.M'
                     WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.N'
                     WHEN T1.IDENTITY_CODE = '4' THEN
                      'G21_1.8.H' --逾期利息包括应收利息+营改增挂账利息,营改增挂账利息废弃
                   END AS ITEM_NUM,
                   CASE
                     WHEN T1.IDENTITY_CODE = '3' THEN
                      T1.ACCU_INT_AMT * T2.CCY_RATE --正常贷款贷款表应计利息
                     WHEN T1.IDENTITY_CODE = '4' THEN
                      NVL(T1.OD_INT, 0) * T2.CCY_RATE --逾期贷款逾期利息
                   END AS TOTAL_VALUE,
                   T1.LOAN_NUM AS COL1, --贷款编号
                   T1.CURR_CD AS COL2, --币种
                   CASE
                     WHEN T1.ITEM_CD IN ('13030101', '13030103') THEN
                      '11320102'
                     WHEN T1.ITEM_CD IN ('13030201', '13030203') THEN
                      '11320104'
                     WHEN T1.ITEM_CD IN ('13050101', '13050103') THEN
                      '11320106'
                     WHEN T1.ITEM_CD IN ('13060101', '13060103') THEN
                      '11320108'
                     WHEN T1.ITEM_CD IN ('13060201', '13060203') THEN
                      '11320110'
                     WHEN T1.ITEM_CD IN ('13060301', '13060303') THEN
                      '11320112'
                     WHEN T1.ITEM_CD IN ('13060501', '13060503') THEN
                      '11320116'
                     ELSE
                      T1.ITEM_CD
                   END AS COL3, --本金对应应计利息科目
                   TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                   TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
                   T1.ACCT_NUM AS COL6, --贷款合同编号
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
            -- T1.REPAY_SEQ , --还款期数
            --  T1.ACCT_STATUS_1104,
              FROM CBRC_FDM_LNAC_PMT_LX T1
              LEFT JOIN L_PUBL_RATE T2
                ON T2.DATA_DATE = I_DATADATE
               AND T2.BASIC_CCY = T1.CURR_CD
               AND T2.FORWARD_CCY = 'CNY'
               AND (T1.ACCU_INT_AMT <>0 OR T1.OD_INT <>0);

--总账补充,条线为空值

       INSERT  INTO `G21_1.8.H` 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE)
         SELECT 
                I_DATADATE,
                A.ORG_NUM,
                '' AS DATA_DEPARTMENT,
                'CBRC' AS SYS_NAM,
                'G21' REP_NUM,
                'G21_1.8.A',
                SUM(A.DEBIT_BAL)
           FROM CBRC_FDM_LNAC_GL A
          WHERE A.DATA_DATE = I_DATADATE
            AND ITEM_CD = '1.8.A' --14310101  库存贵金属
            AND A.DEBIT_BAL <>0
          GROUP BY A.ORG_NUM
         UNION ALL
         SELECT 
                I_DATADATE,
                A.ORG_NUM,
                '' AS DATA_DEPARTMENT,
                'CBRC' AS SYS_NAM,
                'G21' REP_NUM,
                'G21_1.8.B',
                sum(A.DEBIT_BAL)
           FROM CBRC_FDM_LNAC_GL A
          WHERE A.DATA_DATE = I_DATADATE
            AND ITEM_CD = '1.8.B' -- '11003'
            AND A.DEBIT_BAL <>0
          GROUP BY A.ORG_NUM
         UNION  ALL
         SELECT 
                I_DATADATE,
                A.ORG_NUM,
                '' AS DATA_DEPARTMENT,
                'CBRC' AS SYS_NAM,
                'G21' REP_NUM,
                'G21_1.8.H',
                sum(A.DEBIT_BAL)
           FROM CBRC_FDM_LNAC_GL A
          WHERE A.DATA_DATE = I_DATADATE
            AND ITEM_CD = '1.8.H' --113201信用卡利息 放在逾期
            AND A.DEBIT_BAL <>0
          GROUP BY A.ORG_NUM;

--补充1132应收利息轧差,条线为空值
          INSERT  INTO `G21_1.8.H` 
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE)
            SELECT 
             I_DATADATE,
             B.ORG_NUM,
             '' AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             'G21' REP_NUM,
             CASE
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YS' THEN
                'G21_1.8.A'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_WEEK' THEN
                'G21_1.8.B'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_MONTH' THEN
                'G21_1.8.C'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_QUARTER' THEN
                'G21_1.8.D'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YEAR' THEN
                'G21_1.8.E'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_FIVE' THEN
                'G21_1.8.F'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_TEN' THEN
                'G21_1.8.M'
               WHEN ITEM_CD = '113201' AND B.QX = 'MORE_TEN' THEN
                'G21_1.8.N'
               WHEN ITEM_CD = '113201' AND B.QX = 'YQ' THEN
                'G21_1.8.H'
             END ITEM_NUM,
             SUM(MINUS_AMT) AS TOTAL_VALUE
              FROM CBRC_ITEM_MINUS_AMT_TEMP B
             WHERE MINUS_AMT <> 0
               AND ITEM_CD = '113201'
             GROUP BY B.ORG_NUM, ITEM_CD, QX;

--处理133,260利息 不足的数据,与总账找齐

INSERT 
INTO `G21_1.8.H` 
  (DATA_DATE,
   ORG_NUM,
   DATA_DEPARTMENT,
   SYS_NAM,
   REP_NUM,
   ITEM_NUM,
   ITEM_VAL,
   ITEM_VAL_V,
   FLAG,
   B_CURR_CD,
   IS_TOTAL)
  SELECT I_DATADATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         SUM(ITEM_VAL) AS ITEM_VAL,
         ITEM_VAL_V,
         FLAG,
         B_CURR_CD,
         CASE
           WHEN ITEM_NUM = 'G21_1.9.G' THEN --ADD BY DJH 20230509 里面有轧差不参与汇总
            'N'
         END IS_TOTAL
    FROM (SELECT 
           A.ORG_NUM,
           '' AS DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           NVL(A.ITEM_VAL, 0) AS ITEM_VAL,
           ITEM_VAL_V,
           FLAG,
           B_CURR_CD
            FROM CBRC_A_REPT_ITEM_VAL_NGI A
           WHERE A.DATA_DATE = I_DATADATE
             AND A.REP_NUM = 'G21'
          UNION ALL
          SELECT 
           B.ORG_NUM,
           '' AS DATA_DEPARTMENT,
           'CBRC' AS SYS_NAM,
           'G21' REP_NUM,
           CASE
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YS' THEN
              'G21_1.8.A'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_WEEK' THEN
              'G21_1.8.B'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_MONTH' THEN
              'G21_1.8.C'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_QUARTER' THEN
              'G21_1.8.D'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YEAR' THEN
              'G21_1.8.E'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_FIVE' THEN
              'G21_1.8.F'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_TEN' THEN
              'G21_1.8.M'
             WHEN ITEM_CD = '113201' AND B.QX = 'MORE_TEN' THEN
              'G21_1.8.N'
             WHEN ITEM_CD = '113201' AND B.QX = 'YQ' THEN
              'G21_1.8.H'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YS' THEN
              'G21_3.8.A'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_WEEK' THEN
              'G21_3.8.B'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_MONTH' THEN
              'G21_3.8.C'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_QUARTER' THEN
              'G21_3.8.D'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YEAR' THEN
              'G21_3.8.E'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_FIVE' THEN
              'G21_3.8.F.2018'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_TEN' THEN
              'G21_3.8.G1.2018'
             WHEN ITEM_CD = '2231' AND B.QX = 'MORE_TEN' THEN
              'G21_3.8.H1.2018'
           END ITEM_NUM,
           SUM(MINUS_AMT) AS MINUS_AMT,
           NULL ITEM_VAL_V,
           '2' AS FLAG,
           'ALL' CURR_CD
            FROM CBRC_ITEM_MINUS_AMT_TEMP B
           WHERE MINUS_AMT <> 0
             AND ITEM_CD = '2231' ---- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级] 因为113201在明细数据中已出
           GROUP BY B.ORG_NUM, ITEM_CD, QX
          UNION ALL
          SELECT 
                 ORG_NUM,
                 DATA_DEPARTMENT,
                 SYS_NAM,
                 REP_NUM,
                 ITEM_NUM,
                 SUM(TOTAL_VALUE) AS ITEM_VAL,
                 '' ITEM_VAL_V,
                 '2' AS FLAG,
                 'ALL' CURR_CD
            FROM CBRC_A_REPT_DWD_G21
           GROUP BY ORG_NUM, DATA_DEPARTMENT, SYS_NAM, REP_NUM, ITEM_NUM)
   GROUP BY ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            ITEM_VAL_V,
            FLAG,
            B_CURR_CD;


-- 指标: G21_3.2.2.A.2020
/* =================================3.2.2活期存放=========================================================================*/

    ----同业存放 活期
    INSERT 
    INTO `G21_3.2.2.A.2020`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             'G21_3.2.2.A.2020' AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04'
         AND A.GL_ITEM_CODE <> '20120106' --保险业金融机构存放款项放到3.5.2活期存款
       GROUP BY A.ORG_NUM;

/* =================================3.2.2活期存放=========================================================================*/

    ----同业存放 活期
    INSERT 
    INTO `G21_3.2.2.A.2020`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             'G21_3.2.2.A.2020' AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04'
         AND A.GL_ITEM_CODE <> '20120106' --保险业金融机构存放款项放到3.5.2活期存款
       GROUP BY A.ORG_NUM;


-- ========== 逻辑组 16: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE,
             CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN A.ORG_NUM LIKE '%98%' THEN
                A.ORG_NUM
               WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
               ELSE
                SUBSTR(A.ORG_NUM, 1, 4) || '00'
             END,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.1.H1.2018'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.1.G1.2018'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.1.F.2018'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.1.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.1.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.1.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.1.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.1.A'
             END AS ITEM_NUM,
             SUM(ACCT_BAL_RMB) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '02'
       GROUP BY CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                   WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.1.H1.2018'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.1.G1.2018'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.1.F.2018'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.1.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.1.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.1.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.1.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.1.A'
                END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN A.ORG_NUM LIKE '%98%' THEN
                A.ORG_NUM
               WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
               ELSE
                SUBSTR(A.ORG_NUM, 1, 4) || '00'
             END,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.1.H1.2018'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.1.G1.2018'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.1.F.2018'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.1.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.1.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.1.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.1.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.1.A'
             END AS ITEM_NUM,
             SUM(ACCT_BAL_RMB) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '02'
       GROUP BY CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                   WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.1.H1.2018'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.1.G1.2018'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.1.F.2018'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.1.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.1.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.1.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.1.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.1.A'
                END
) q_16
INSERT INTO `G21_3.1.C` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.1.E` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.1.D` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- ========== 逻辑组 17: 共 6 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             '009804',
             CASE
               WHEN A.MATURITY_DATE < I_DATADATE THEN
                'G21_1.7.3.H.2018'
               WHEN (A.MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
                'G21_1.7.3.H1.2018' ---10年以上
               WHEN (A.MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_1.7.3.G1.2018' --5-10年
               WHEN A.MATURITY_DATE - I_DATADATE > 360 THEN
                'G21_1.7.3.F.2018' --1-5年
               WHEN A.MATURITY_DATE - I_DATADATE > 90 THEN
                'G21_1.7.3.E.2018'
               WHEN A.MATURITY_DATE - I_DATADATE > 30 THEN
                'G21_1.7.3.D.2018'
               WHEN A.MATURITY_DATE - I_DATADATE > 7 THEN
                'G21_1.7.3.C.2018'
               WHEN A.MATURITY_DATE - I_DATADATE > 1 THEN
                'G21_1.7.3.B.2018'
               WHEN (A.MATURITY_DATE - I_DATADATE = 1 OR
                    A.MATURITY_DATE - I_DATADATE = 0) THEN
                'G21_1.7.3.A.2018'
             END AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE_CNY)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '15010201' --业务口径：债权投资特定目的载体投资投资成本,目前就国民信托一笔
         AND A.ORG_NUM = '009804'
       GROUP BY CASE
                  WHEN A.MATURITY_DATE < I_DATADATE THEN
                   'G21_1.7.3.H.2018'
                  WHEN (A.MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
                   'G21_1.7.3.H1.2018' ---10年以上
                  WHEN (A.MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_1.7.3.G1.2018' --5-10年
                  WHEN A.MATURITY_DATE - I_DATADATE > 360 THEN
                   'G21_1.7.3.F.2018' --1-5年
                  WHEN A.MATURITY_DATE - I_DATADATE > 90 THEN
                   'G21_1.7.3.E.2018'
                  WHEN A.MATURITY_DATE - I_DATADATE > 30 THEN
                   'G21_1.7.3.D.2018'
                  WHEN A.MATURITY_DATE - I_DATADATE > 7 THEN
                   'G21_1.7.3.C.2018'
                  WHEN A.MATURITY_DATE - I_DATADATE > 1 THEN
                   'G21_1.7.3.B.2018'
                  WHEN (A.MATURITY_DATE - I_DATADATE = 1 OR
                       A.MATURITY_DATE - I_DATADATE = 0) THEN
                   'G21_1.7.3.A.2018'
                END;

剩余的定开（康星系统有标识,为剩余的债券基金投资）按照剩余期限划分,取持有仓位；
      所有AC账户,按剩余期限划分取持有仓位,其中2笔华创证券有限责任公司的到期日特殊处理成2028/11/30处理后划分；
      其中3笔AC账户的特殊处理,取持有仓位（中国华阳经贸集团有限公司,方正证券股份有限公司,东吴基金管理公司）放逾期；*/

    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009820',
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.7.3.H.2018'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.7.3.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.7.3.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.7.3.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.7.3.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.7.3.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.7.3.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.7.3.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.7.3.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG IN (/*'01', '02', '04',*/ '06', '07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资) 08(AC账户)
         AND A.ORG_NUM = '009820'
       GROUP BY CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.7.3.H.2018'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.7.3.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.7.3.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.7.3.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.7.3.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.7.3.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.7.3.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.7.3.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.7.3.A.2018'
                END;

--ADD BY DJH 20240510
    --009817机构存量的非标本金按剩余期限划分
     INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.7.3.H.2018'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.7.3.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.7.3.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.7.3.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.7.3.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.7.3.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.7.3.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.7.3.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.7.3.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG ='09' --投资银行
       GROUP BY ORG_NUM,CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.7.3.H.2018'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.7.3.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.7.3.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.7.3.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.7.3.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.7.3.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.7.3.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.7.3.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.7.3.A.2018'
                END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009804',
             CASE
               WHEN A.MATURITY_DATE < I_DATADATE THEN
                'G21_1.7.3.H.2018'
               WHEN (A.MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
                'G21_1.7.3.H1.2018' ---10年以上
               WHEN (A.MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_1.7.3.G1.2018' --5-10年
               WHEN A.MATURITY_DATE - I_DATADATE > 360 THEN
                'G21_1.7.3.F.2018' --1-5年
               WHEN A.MATURITY_DATE - I_DATADATE > 90 THEN
                'G21_1.7.3.E.2018'
               WHEN A.MATURITY_DATE - I_DATADATE > 30 THEN
                'G21_1.7.3.D.2018'
               WHEN A.MATURITY_DATE - I_DATADATE > 7 THEN
                'G21_1.7.3.C.2018'
               WHEN A.MATURITY_DATE - I_DATADATE > 1 THEN
                'G21_1.7.3.B.2018'
               WHEN (A.MATURITY_DATE - I_DATADATE = 1 OR
                    A.MATURITY_DATE - I_DATADATE = 0) THEN
                'G21_1.7.3.A.2018'
             END AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE_CNY)
        FROM CBRC_TMP_A_CBRC_BOND_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '15010201' --业务口径：债权投资特定目的载体投资投资成本,目前就国民信托一笔
         AND A.ORG_NUM = '009804'
       GROUP BY CASE
                  WHEN A.MATURITY_DATE < I_DATADATE THEN
                   'G21_1.7.3.H.2018'
                  WHEN (A.MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
                   'G21_1.7.3.H1.2018' ---10年以上
                  WHEN (A.MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_1.7.3.G1.2018' --5-10年
                  WHEN A.MATURITY_DATE - I_DATADATE > 360 THEN
                   'G21_1.7.3.F.2018' --1-5年
                  WHEN A.MATURITY_DATE - I_DATADATE > 90 THEN
                   'G21_1.7.3.E.2018'
                  WHEN A.MATURITY_DATE - I_DATADATE > 30 THEN
                   'G21_1.7.3.D.2018'
                  WHEN A.MATURITY_DATE - I_DATADATE > 7 THEN
                   'G21_1.7.3.C.2018'
                  WHEN A.MATURITY_DATE - I_DATADATE > 1 THEN
                   'G21_1.7.3.B.2018'
                  WHEN (A.MATURITY_DATE - I_DATADATE = 1 OR
                       A.MATURITY_DATE - I_DATADATE = 0) THEN
                   'G21_1.7.3.A.2018'
                END;

剩余的定开（康星系统有标识,为剩余的债券基金投资）按照剩余期限划分,取持有仓位；
      所有AC账户,按剩余期限划分取持有仓位,其中2笔华创证券有限责任公司的到期日特殊处理成2028/11/30处理后划分；
      其中3笔AC账户的特殊处理,取持有仓位（中国华阳经贸集团有限公司,方正证券股份有限公司,东吴基金管理公司）放逾期；*/

    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009820',
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.7.3.H.2018'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.7.3.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.7.3.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.7.3.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.7.3.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.7.3.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.7.3.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.7.3.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.7.3.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG IN (/*'01', '02', '04',*/ '06', '07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资) 08(AC账户)
         AND A.ORG_NUM = '009820'
       GROUP BY CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.7.3.H.2018'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.7.3.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.7.3.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.7.3.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.7.3.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.7.3.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.7.3.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.7.3.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.7.3.A.2018'
                END;

--ADD BY DJH 20240510
    --009817机构存量的非标本金按剩余期限划分
     INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.7.3.H.2018'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.7.3.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.7.3.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.7.3.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.7.3.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.7.3.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.7.3.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.7.3.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.7.3.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG ='09' --投资银行
       GROUP BY ORG_NUM,CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.7.3.H.2018'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.7.3.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.7.3.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.7.3.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.7.3.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.7.3.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.7.3.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.7.3.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.7.3.A.2018'
                END
) q_17
INSERT INTO `G21_1.7.3.B.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.3.H.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.3.E.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.3.D.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.3.F.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.7.3.C.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- 指标: G21_3.5.1.A
--  3.5.1定期存款    202、203、205、206、215、220、2340204、251,219结构性存款
    INSERT 
    INTO `G21_3.5.1.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             CASE WHEN  A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN A.ORG_NUM LIKE '%98%' THEN
                A.ORG_NUM
               WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
               ELSE
                SUBSTR(A.ORG_NUM, 1, 4) || '00'
             END,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.5.1.A'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.5.1.B'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.5.1.C'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.5.1.D'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.5.1.E'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.5.1.F.2018'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.5.1.G1.2018'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.5.1.H1.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
       WHERE A.DATA_DATE = I_DATADATE
         AND ( A.GL_ITEM_CODE IN
             ('20110205', '20110110', '20110202','20110203','20110204','20110211', '20110701', '20110103','20110104','20110105','20110106',
             '20110107','20110108','20110109', '20110208','20110113', '20110114','20110115','20110209','20110210','20110207','20110112') OR
             A.GL_ITEM_CODE = '20120204'
              OR A.GL_ITEM_CODE LIKE '2010%'  --ALTER BY 石雨 JLBA202504180011
             )
       GROUP BY CASE  WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                  WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.5.1.A'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.5.1.B'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.5.1.C'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.5.1.D'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.5.1.E'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.5.1.F.2018'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.5.1.G1.2018'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.5.1.H1.2018'
                END;

/* UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_3.5.1.A' AS ITEM_NUM,
             sum(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
            --AND A.ITEM_CD ='11003'
         AND ITEM_CD = '3.5.1.A'
       GROUP BY I_DATADATE, A.ORG_NUM;

--  3.5.1定期存款    202、203、205、206、215、220、2340204、251,219结构性存款
    INSERT 
    INTO `G21_3.5.1.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             CASE WHEN  A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN A.ORG_NUM LIKE '%98%' THEN
                A.ORG_NUM
               WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
               ELSE
                SUBSTR(A.ORG_NUM, 1, 4) || '00'
             END,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.5.1.A'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.5.1.B'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.5.1.C'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.5.1.D'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.5.1.E'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.5.1.F.2018'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.5.1.G1.2018'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.5.1.H1.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
       WHERE A.DATA_DATE = I_DATADATE
         AND ( A.GL_ITEM_CODE IN
             ('20110205', '20110110', '20110202','20110203','20110204','20110211', '20110701', '20110103','20110104','20110105','20110106',
             '20110107','20110108','20110109', '20110208','20110113', '20110114','20110115','20110209','20110210','20110207','20110112') OR
             A.GL_ITEM_CODE = '20120204'
              OR A.GL_ITEM_CODE LIKE '2010%'  --ALTER BY 石雨 JLBA202504180011
             )
       GROUP BY CASE  WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                  WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.5.1.A'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.5.1.B'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.5.1.C'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.5.1.D'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.5.1.E'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.5.1.F.2018'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.5.1.G1.2018'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.5.1.H1.2018'
                END;

/* UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_3.5.1.A' AS ITEM_NUM,
             sum(A.DEBIT_BAL)
        FROM CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
            --AND A.ITEM_CD ='11003'
         AND ITEM_CD = '3.5.1.A'
       GROUP BY I_DATADATE, A.ORG_NUM;


-- ========== 逻辑组 19: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                'G21_16.2.H.2021'
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_16.2.G1.2021'
               WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                'G21_16.2.F.2021'
               WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                'G21_16.2.E.2021'
               WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                'G21_16.2.D.2021'
               WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                'G21_16.2.C.2021'
               WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                'G21_16.2.B.2021'
               WHEN (REDEMP_DATE IS NULL OR
                    REDEMP_DATE - I_DATADATE <= 1) THEN
                'G21_16.2.A.2021'
             END,
             /* CASE
               WHEN ROLL_PERIOD / 360 > 10 THEN --开放式产品滚动(或开发赎回)周期‘
                'G21_16.2.H.2021'
               WHEN ROLL_PERIOD / 360 > 5 THEN
                'G21_16.2.G.2021'
               WHEN ROLL_PERIOD > 360 THEN
                'G21_16.2.F.2021'
               WHEN ROLL_PERIOD > 90 THEN
                'G21_16.2.E.2021'
               WHEN ROLL_PERIOD > 30 THEN
                'G21_16.2.D.2021'
               WHEN ROLL_PERIOD > 7 THEN
                'G21_16.2.C.2021'
               WHEN ROLL_PERIOD > 1 THEN
                'G21_16.2.B.2021'
               WHEN (ROLL_PERIOD IS NULL OR ROLL_PERIOD < = 1) THEN
                'G21_16.2.A.2021'
             END,*/
             SUM(A.END_PROD_AMT_CNY)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                   'G21_16.2.H.2021'
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_16.2.G1.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                   'G21_16.2.F.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                   'G21_16.2.E.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                   'G21_16.2.D.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                   'G21_16.2.C.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                   'G21_16.2.B.2021'
                  WHEN (REDEMP_DATE IS NULL OR
                       REDEMP_DATE - I_DATADATE <= 1) THEN
                   'G21_16.2.A.2021'
                END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                'G21_16.2.H.2021'
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_16.2.G1.2021'
               WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                'G21_16.2.F.2021'
               WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                'G21_16.2.E.2021'
               WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                'G21_16.2.D.2021'
               WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                'G21_16.2.C.2021'
               WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                'G21_16.2.B.2021'
               WHEN (REDEMP_DATE IS NULL OR
                    REDEMP_DATE - I_DATADATE <= 1) THEN
                'G21_16.2.A.2021'
             END,
             /* CASE
               WHEN ROLL_PERIOD / 360 > 10 THEN --开放式产品滚动(或开发赎回)周期‘
                'G21_16.2.H.2021'
               WHEN ROLL_PERIOD / 360 > 5 THEN
                'G21_16.2.G.2021'
               WHEN ROLL_PERIOD > 360 THEN
                'G21_16.2.F.2021'
               WHEN ROLL_PERIOD > 90 THEN
                'G21_16.2.E.2021'
               WHEN ROLL_PERIOD > 30 THEN
                'G21_16.2.D.2021'
               WHEN ROLL_PERIOD > 7 THEN
                'G21_16.2.C.2021'
               WHEN ROLL_PERIOD > 1 THEN
                'G21_16.2.B.2021'
               WHEN (ROLL_PERIOD IS NULL OR ROLL_PERIOD < = 1) THEN
                'G21_16.2.A.2021'
             END,*/
             SUM(A.END_PROD_AMT_CNY)
        FROM CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                   'G21_16.2.H.2021'
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_16.2.G1.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                   'G21_16.2.F.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                   'G21_16.2.E.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                   'G21_16.2.D.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                   'G21_16.2.C.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                   'G21_16.2.B.2021'
                  WHEN (REDEMP_DATE IS NULL OR
                       REDEMP_DATE - I_DATADATE <= 1) THEN
                   'G21_16.2.A.2021'
                END;

--ADD BY DJH 20230417 2.1.5.5.1其中：属于理财产品的部分  G21封闭式+开放式,30日内到期
 INSERT 
 INTO `__INDICATOR_PLACEHOLDER__` 
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
 INTO `__INDICATOR_PLACEHOLDER__` 
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
    GROUP BY B.ORG_NUM
) q_19
INSERT INTO `G21_16.2.C.2021` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_16.2.A.2021` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- ========== 逻辑组 20: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.2.1.H1.2020' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.2.1.G1.2020' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.2.1.F.2020' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.2.1.E.2020'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.2.1.D.2020'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.2.1.C.2020'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.2.1.B.2020'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.2.1.A.2020' ---逾期放次日
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS BALANCE_CNY
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '03'
         AND A.GL_ITEM_CODE <> '20120204' --保险业金融机构存放款项放到3.5.1定期存款
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.2.1.H1.2020' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.2.1.G1.2020' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.2.1.F.2020' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.2.1.E.2020'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.2.1.D.2020'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.2.1.C.2020'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.2.1.B.2020'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.2.1.A.2020' ---逾期放次日
                END;

----同业存放定期
    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.2.1.H1.2020' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.2.1.G1.2020' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.2.1.F.2020' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.2.1.E.2020'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.2.1.D.2020'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.2.1.C.2020'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.2.1.B.2020'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.2.1.A.2020' ---逾期放次日
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS BALANCE_CNY
        FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '03'
         AND A.GL_ITEM_CODE <> '20120204' --保险业金融机构存放款项放到3.5.1定期存款
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.2.1.H1.2020' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.2.1.G1.2020' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.2.1.F.2020' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.2.1.E.2020'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.2.1.D.2020'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.2.1.C.2020'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.2.1.B.2020'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.2.1.A.2020' ---逾期放次日
                END
) q_20
INSERT INTO `G21_3.2.1.D.2020` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.2.1.E.2020` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.2.1.C.2020` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- ========== 逻辑组 21: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE,
             A.ORG_NUM AS ORG_NUM,
             CASE
               WHEN A.ITEM_CD = '10030201' THEN
                'G21_1.2.A' --次日
               ELSE
                'G21_1.2.G' --未定期限
             END ITEM_NUM,
             sum(A.DEBIT_BAL * B.CCY_RATE)
        FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('10030101', '10030102', '10030201', '10030401')
         AND A.DEBIT_BAL <> 0
         AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
         AND A.ORG_NUM NOT LIKE '%0000' --去掉分行,汇总时不需要
         AND A.ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                               /*'510000',*/ --磐石吉银村镇银行
                               '222222', --东盛除双阳汇总
                               '333333', --新双阳
                               '444444', --净月潭除双阳
                               '555555') --长春分行（除双阳、榆树、农安）
       GROUP BY A.ORG_NUM, A.ITEM_CD;

--11002(存放中央银行超额备付金存款)次日,其他放未定期限
    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM AS ORG_NUM,
             CASE
               WHEN A.ITEM_CD = '10030201' THEN
                'G21_1.2.A' --次日
               ELSE
                'G21_1.2.G' --未定期限
             END ITEM_NUM,
             sum(A.DEBIT_BAL * B.CCY_RATE)
        FROM  V_PUB_IDX_FINA_GL A
        LEFT JOIN L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('10030101', '10030102', '10030201', '10030401')
         AND A.DEBIT_BAL <> 0
         AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
         AND A.ORG_NUM NOT LIKE '%0000' --去掉分行,汇总时不需要
         AND A.ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                               /*'510000',*/ --磐石吉银村镇银行
                               '222222', --东盛除双阳汇总
                               '333333', --新双阳
                               '444444', --净月潭除双阳
                               '555555') --长春分行（除双阳、榆树、农安）
       GROUP BY A.ORG_NUM, A.ITEM_CD
) q_21
INSERT INTO `G21_1.2.G` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.2.A` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- ========== 逻辑组 22: 共 6 个指标 ==========
FROM (
SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '03' --买入返售
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04' --同业存单
      --AND ORG_NUM = '009804'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '05' --债券投资
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

所有AC账户（除3笔特殊账户）,按剩余期限划分取应收利息,其中2笔华创证券有限责任公司的到期日特殊处理成2028/11/30处理后划分；
        +140万+63.32万(固定值)--固定值放逾期
        G01的11.其他应收款009820机构放逾期；*/

     --ADD BY DJH 20240510  金融市场部 拆放同业利息补充进来
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金本金对应的应收利息
    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(A.INTEREST_ACCURAL)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG IN ('01', '02' /*, '04'*/, '06', '07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资) 08(AC账户)  已在金融市场取数
        -- AND A.ORG_NUM IN ('009820', '009804')
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

--ADD BY DJH 20240510  投资银行部
    --009817机构存量的非标的应收利息+其他应收款按剩余期限划分


    INSERT INTO `__INDICATOR_PLACEHOLDER__`  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN 'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN 'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN 'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN 'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN 'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN 'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN 'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN 'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR  T1.PLA_MATURITY_DATE - I_DATADATE = 0  THEN
              'G21_1.8.A'
           END ITEM_NUM,
           SUM(T.INTEREST_ACCURAL+T.QTYSK)
      FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL T
      LEFT JOIN (SELECT Q.ACCT_NUM,
                        Q.PLA_MATURITY_DATE,
                        ROW_NUMBER() OVER(PARTITION BY Q.ACCT_NUM ORDER BY Q.PLA_MATURITY_DATE) RN
                   FROM PM_RSDATA.SMTMODS_L_ACCT_FUND_MMFUND_PAYM_SCHED Q
                  WHERE Q.DATA_DATE = I_DATADATE
                    AND DATA_SOURCE = '投行业务'
                    AND Q.PLA_MATURITY_DATE > I_DATADATE
                 ) T1
        ON T.ACCT_NUM = T1.ACCT_NUM
       AND T1.RN = 1
     WHERE T.DATA_DATE = I_DATADATE
       AND T.FLAG = '09'
       --由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第1.9项,除去逾期部分其余不在系统取数,业务手填
       AND (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE)
     GROUP BY
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN
              'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
              'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
              'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN
              'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN
              'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN
              'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN
              'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN
              'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR
                  T1.PLA_MATURITY_DATE - I_DATADATE = 0 THEN
              'G21_1.8.A'
           END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                'G21_1.8.N'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                    COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                   'G21_1.8.N'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                       COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END
      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_1.8.A' AS ITEM_NUM,
             SUM(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND ITEM_CD = 'G21_1.8.A'
       GROUP BY I_DATADATE, A.ORG_NUM;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                'G21_1.8.N'
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (REDEMP_DATE IS NULL OR
                    REDEMP_DATE - I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                   'G21_1.8.N'
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (REDEMP_DATE IS NULL OR
                       REDEMP_DATE - I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END;

INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

--处理133,260利息 不足的数据,与总账找齐

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       IS_TOTAL)
SELECT I_DATADATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       SUM(ITEM_VAL) AS ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       CASE
           WHEN ITEM_NUM = 'G21_1.9.G' THEN  --ADD BY DJH 20230509 里面有轧差不参与汇总
            'N'
         END IS_TOTAL
  FROM (SELECT 
         A.ORG_NUM,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         NVL(A.ITEM_VAL, 0) AS ITEM_VAL,
         ITEM_VAL_V,
         FLAG,
         B_CURR_CD
          FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI A
         WHERE A.DATA_DATE = I_DATADATE
           AND A.REP_NUM = 'G21'
        UNION ALL
        SELECT 
         B.ORG_NUM,
         'CBRC' AS SYS_NAM,
         'G21' REP_NUM,
         CASE
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YS' THEN
            'G21_1.8.A'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_WEEK' THEN
            'G21_1.8.B'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_MONTH' THEN
            'G21_1.8.C'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_1.8.D'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YEAR' THEN
            'G21_1.8.E'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_FIVE' THEN
            'G21_1.8.F'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_TEN' THEN
            'G21_1.8.M'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'MORE_TEN' THEN
            'G21_1.8.N'
           WHEN ITEM_CD =  '113201' AND B.QX = 'YQ' THEN
            'G21_1.8.H'
           WHEN  ITEM_CD = '2231' AND B.QX = 'NEXT_YS' THEN
            'G21_3.8.A'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_WEEK' THEN
            'G21_3.8.B'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_MONTH' THEN
            'G21_3.8.C'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_3.8.D'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YEAR' THEN
            'G21_3.8.E'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_FIVE' THEN
            'G21_3.8.F.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_TEN' THEN
            'G21_3.8.G1.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'MORE_TEN' THEN
            'G21_3.8.H1.2018'
         END ITEM_NUM,
         SUM(MINUS_AMT) AS MINUS_AMT,
         NULL ITEM_VAL_V,
         '2' AS FLAG,
         'ALL' CURR_CD
          FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP B
         WHERE MINUS_AMT <> 0
         GROUP BY B.ORG_NUM, ITEM_CD,QX)
 GROUP BY ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL_V, FLAG, B_CURR_CD;

---1.9其他有确定到期日的资产 : 买入返售应收利息+同业存单应收利息+债券投资应收利息
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1111买入返售本金对应的应收利息
    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '03' --买入返售
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04' --同业存单
      --AND ORG_NUM = '009804'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '05' --债券投资
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

所有AC账户（除3笔特殊账户）,按剩余期限划分取应收利息,其中2笔华创证券有限责任公司的到期日特殊处理成2028/11/30处理后划分；
        +140万+63.32万(固定值)--固定值放逾期
        G01的11.其他应收款009820机构放逾期；*/

     --ADD BY DJH 20240510  金融市场部 拆放同业利息补充进来
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金本金对应的应收利息
    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(A.INTEREST_ACCURAL)
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG IN ('01', '02' /*, '04'*/, '06', '07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资) 08(AC账户)  已在金融市场取数
        -- AND A.ORG_NUM IN ('009820', '009804')
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

--ADD BY DJH 20240510  投资银行部
    --009817机构存量的非标的应收利息+其他应收款按剩余期限划分


    INSERT INTO `__INDICATOR_PLACEHOLDER__`  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN 'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN 'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN 'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN 'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN 'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN 'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN 'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN 'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR  T1.PLA_MATURITY_DATE - I_DATADATE = 0  THEN
              'G21_1.8.A'
           END ITEM_NUM,
           SUM(T.INTEREST_ACCURAL+T.QTYSK)
      FROM CBRC_TMP_A_CBRC_LOAN_BAL T
      LEFT JOIN (SELECT Q.ACCT_NUM,
                        Q.PLA_MATURITY_DATE,
                        ROW_NUMBER() OVER(PARTITION BY Q.ACCT_NUM ORDER BY Q.PLA_MATURITY_DATE) RN
                   FROM L_ACCT_FUND_MMFUND_PAYM_SCHED Q
                  WHERE Q.DATA_DATE = I_DATADATE
                    AND DATA_SOURCE = '投行业务'
                    AND Q.PLA_MATURITY_DATE > I_DATADATE
                 ) T1
        ON T.ACCT_NUM = T1.ACCT_NUM
       AND T1.RN = 1
     WHERE T.DATA_DATE = I_DATADATE
       AND T.FLAG = '09'
       --由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第1.9项,除去逾期部分其余不在系统取数,业务手填
       AND (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE)
     GROUP BY
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN
              'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
              'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
              'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN
              'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN
              'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN
              'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN
              'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN
              'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR
                  T1.PLA_MATURITY_DATE - I_DATADATE = 0 THEN
              'G21_1.8.A'
           END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                'G21_1.8.N'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                    COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                   'G21_1.8.N'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                       COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END
      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_1.8.A' AS ITEM_NUM,
             SUM(A.DEBIT_BAL)
        FROM CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND ITEM_CD = 'G21_1.8.A'
       GROUP BY I_DATADATE, A.ORG_NUM;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                'G21_1.8.N'
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (REDEMP_DATE IS NULL OR
                    REDEMP_DATE - I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                   'G21_1.8.N'
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (REDEMP_DATE IS NULL OR
                       REDEMP_DATE - I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END;

INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

INSERT  INTO `__INDICATOR_PLACEHOLDER__` 
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
                   T1.DATA_DATE,
                   CASE
                     WHEN T1.ORG_NUM LIKE '5%' OR T1.ORG_NUM LIKE '6%' THEN
                      T1.ORG_NUM
                     WHEN T1.ORG_NUM LIKE '%98%' THEN
                      T1.ORG_NUM
                     WHEN t1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                      '060300'
                     ELSE
                      SUBSTR(T1.ORG_NUM, 1, 4) || '00'
                   END as ORGNO,
                   T1.DATA_DEPARTMENT,
                   'CBRC' AS SYS_NAM,
                   'G21' REP_NUM,
                   CASE
                     WHEN T1.PMT_REMAIN_TERM_C = 1 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.A'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.B'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.C'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.D'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.E'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 360 * 5 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.F'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND
                          360 * 10 AND T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.M'
                     WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.N'
                     WHEN T1.IDENTITY_CODE = '4' THEN
                      'G21_1.8.H' --逾期利息包括应收利息+营改增挂账利息,营改增挂账利息废弃
                   END AS ITEM_NUM,
                   CASE
                     WHEN T1.IDENTITY_CODE = '3' THEN
                      T1.ACCU_INT_AMT * T2.CCY_RATE --正常贷款贷款表应计利息
                     WHEN T1.IDENTITY_CODE = '4' THEN
                      NVL(T1.OD_INT, 0) * T2.CCY_RATE --逾期贷款逾期利息
                   END AS TOTAL_VALUE,
                   T1.LOAN_NUM AS COL1, --贷款编号
                   T1.CURR_CD AS COL2, --币种
                   CASE
                     WHEN T1.ITEM_CD IN ('13030101', '13030103') THEN
                      '11320102'
                     WHEN T1.ITEM_CD IN ('13030201', '13030203') THEN
                      '11320104'
                     WHEN T1.ITEM_CD IN ('13050101', '13050103') THEN
                      '11320106'
                     WHEN T1.ITEM_CD IN ('13060101', '13060103') THEN
                      '11320108'
                     WHEN T1.ITEM_CD IN ('13060201', '13060203') THEN
                      '11320110'
                     WHEN T1.ITEM_CD IN ('13060301', '13060303') THEN
                      '11320112'
                     WHEN T1.ITEM_CD IN ('13060501', '13060503') THEN
                      '11320116'
                     ELSE
                      T1.ITEM_CD
                   END AS COL3, --本金对应应计利息科目
                   TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                   TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
                   T1.ACCT_NUM AS COL6, --贷款合同编号
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
            -- T1.REPAY_SEQ , --还款期数
            --  T1.ACCT_STATUS_1104,
              FROM CBRC_FDM_LNAC_PMT_LX T1
              LEFT JOIN L_PUBL_RATE T2
                ON T2.DATA_DATE = I_DATADATE
               AND T2.BASIC_CCY = T1.CURR_CD
               AND T2.FORWARD_CCY = 'CNY'
               AND (T1.ACCU_INT_AMT <>0 OR T1.OD_INT <>0);

--补充1132应收利息轧差,条线为空值
          INSERT  INTO `__INDICATOR_PLACEHOLDER__` 
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE)
            SELECT 
             I_DATADATE,
             B.ORG_NUM,
             '' AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             'G21' REP_NUM,
             CASE
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YS' THEN
                'G21_1.8.A'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_WEEK' THEN
                'G21_1.8.B'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_MONTH' THEN
                'G21_1.8.C'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_QUARTER' THEN
                'G21_1.8.D'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YEAR' THEN
                'G21_1.8.E'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_FIVE' THEN
                'G21_1.8.F'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_TEN' THEN
                'G21_1.8.M'
               WHEN ITEM_CD = '113201' AND B.QX = 'MORE_TEN' THEN
                'G21_1.8.N'
               WHEN ITEM_CD = '113201' AND B.QX = 'YQ' THEN
                'G21_1.8.H'
             END ITEM_NUM,
             SUM(MINUS_AMT) AS TOTAL_VALUE
              FROM CBRC_ITEM_MINUS_AMT_TEMP B
             WHERE MINUS_AMT <> 0
               AND ITEM_CD = '113201'
             GROUP BY B.ORG_NUM, ITEM_CD, QX;

--处理133,260利息 不足的数据,与总账找齐

INSERT 
INTO `__INDICATOR_PLACEHOLDER__` 
  (DATA_DATE,
   ORG_NUM,
   DATA_DEPARTMENT,
   SYS_NAM,
   REP_NUM,
   ITEM_NUM,
   ITEM_VAL,
   ITEM_VAL_V,
   FLAG,
   B_CURR_CD,
   IS_TOTAL)
  SELECT I_DATADATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         SUM(ITEM_VAL) AS ITEM_VAL,
         ITEM_VAL_V,
         FLAG,
         B_CURR_CD,
         CASE
           WHEN ITEM_NUM = 'G21_1.9.G' THEN --ADD BY DJH 20230509 里面有轧差不参与汇总
            'N'
         END IS_TOTAL
    FROM (SELECT 
           A.ORG_NUM,
           '' AS DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           NVL(A.ITEM_VAL, 0) AS ITEM_VAL,
           ITEM_VAL_V,
           FLAG,
           B_CURR_CD
            FROM CBRC_A_REPT_ITEM_VAL_NGI A
           WHERE A.DATA_DATE = I_DATADATE
             AND A.REP_NUM = 'G21'
          UNION ALL
          SELECT 
           B.ORG_NUM,
           '' AS DATA_DEPARTMENT,
           'CBRC' AS SYS_NAM,
           'G21' REP_NUM,
           CASE
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YS' THEN
              'G21_1.8.A'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_WEEK' THEN
              'G21_1.8.B'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_MONTH' THEN
              'G21_1.8.C'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_QUARTER' THEN
              'G21_1.8.D'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YEAR' THEN
              'G21_1.8.E'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_FIVE' THEN
              'G21_1.8.F'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_TEN' THEN
              'G21_1.8.M'
             WHEN ITEM_CD = '113201' AND B.QX = 'MORE_TEN' THEN
              'G21_1.8.N'
             WHEN ITEM_CD = '113201' AND B.QX = 'YQ' THEN
              'G21_1.8.H'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YS' THEN
              'G21_3.8.A'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_WEEK' THEN
              'G21_3.8.B'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_MONTH' THEN
              'G21_3.8.C'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_QUARTER' THEN
              'G21_3.8.D'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YEAR' THEN
              'G21_3.8.E'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_FIVE' THEN
              'G21_3.8.F.2018'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_TEN' THEN
              'G21_3.8.G1.2018'
             WHEN ITEM_CD = '2231' AND B.QX = 'MORE_TEN' THEN
              'G21_3.8.H1.2018'
           END ITEM_NUM,
           SUM(MINUS_AMT) AS MINUS_AMT,
           NULL ITEM_VAL_V,
           '2' AS FLAG,
           'ALL' CURR_CD
            FROM CBRC_ITEM_MINUS_AMT_TEMP B
           WHERE MINUS_AMT <> 0
             AND ITEM_CD = '2231' ---- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级] 因为113201在明细数据中已出
           GROUP BY B.ORG_NUM, ITEM_CD, QX
          UNION ALL
          SELECT 
                 ORG_NUM,
                 DATA_DEPARTMENT,
                 SYS_NAM,
                 REP_NUM,
                 ITEM_NUM,
                 SUM(TOTAL_VALUE) AS ITEM_VAL,
                 '' ITEM_VAL_V,
                 '2' AS FLAG,
                 'ALL' CURR_CD
            FROM CBRC_A_REPT_DWD_G21
           GROUP BY ORG_NUM, DATA_DEPARTMENT, SYS_NAM, REP_NUM, ITEM_NUM)
   GROUP BY ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            ITEM_VAL_V,
            FLAG,
            B_CURR_CD
) q_22
INSERT INTO `G21_1.8.M` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.8.E` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.8.D` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.8.C` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.8.N` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.8.F` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- ========== 逻辑组 23: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.4.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.4.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.4.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.4.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.4.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.4.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.4.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.4.A'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.4.H.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
          AND A.FLAG='02'
           GROUP BY A.ORG_NUM,
            CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.4.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.4.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.4.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.4.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.4.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.4.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.4.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.4.A'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.4.H.2018'
             END;

--120(拆出资金)
    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.4.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.4.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.4.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.4.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.4.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.4.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.4.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.4.A'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.4.H.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
          AND A.FLAG='02'
           GROUP BY A.ORG_NUM,
            CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.4.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.4.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.4.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.4.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.4.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.4.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.4.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.4.A'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.4.H.2018'
             END
) q_23
INSERT INTO `G21_1.4.C` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.4.D` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.4.E` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_1.4.H.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- 指标: G21_1.8.A
--ADD BY DJH 20230718 资管次日数据
     INSERT INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
       SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_1.8.A',
             SUM(DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL,
             A.CURR_CD,
             A.ITEM_CD
        FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND ITEM_CD = '12210201' --jrsj垫资款 即 应收业务周转金 一直放次日
         AND ORG_NUM = '009816'
         AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
       GROUP BY A.ORG_NUM,A.CURR_CD, A.ITEM_CD;

---1.9其他有确定到期日的资产 : 买入返售应收利息+同业存单应收利息+债券投资应收利息
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1111买入返售本金对应的应收利息
    INSERT 
    INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '03' --买入返售
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04' --同业存单
      --AND ORG_NUM = '009804'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '05' --债券投资
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

所有AC账户（除3笔特殊账户）,按剩余期限划分取应收利息,其中2笔华创证券有限责任公司的到期日特殊处理成2028/11/30处理后划分；
        +140万+63.32万(固定值)--固定值放逾期
        G01的11.其他应收款009820机构放逾期；*/

     --ADD BY DJH 20240510  金融市场部 拆放同业利息补充进来
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金本金对应的应收利息
    INSERT 
    INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(A.INTEREST_ACCURAL)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG IN ('01', '02' /*, '04'*/, '06', '07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资) 08(AC账户)  已在金融市场取数
        -- AND A.ORG_NUM IN ('009820', '009804')
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

--ADD BY DJH 20240510  投资银行部
    --009817机构存量的非标的应收利息+其他应收款按剩余期限划分


    INSERT INTO `G21_1.8.A`  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN 'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN 'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN 'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN 'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN 'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN 'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN 'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN 'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR  T1.PLA_MATURITY_DATE - I_DATADATE = 0  THEN
              'G21_1.8.A'
           END ITEM_NUM,
           SUM(T.INTEREST_ACCURAL+T.QTYSK)
      FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL T
      LEFT JOIN (SELECT Q.ACCT_NUM,
                        Q.PLA_MATURITY_DATE,
                        ROW_NUMBER() OVER(PARTITION BY Q.ACCT_NUM ORDER BY Q.PLA_MATURITY_DATE) RN
                   FROM PM_RSDATA.SMTMODS_L_ACCT_FUND_MMFUND_PAYM_SCHED Q
                  WHERE Q.DATA_DATE = I_DATADATE
                    AND DATA_SOURCE = '投行业务'
                    AND Q.PLA_MATURITY_DATE > I_DATADATE
                 ) T1
        ON T.ACCT_NUM = T1.ACCT_NUM
       AND T1.RN = 1
     WHERE T.DATA_DATE = I_DATADATE
       AND T.FLAG = '09'
       --由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第1.9项,除去逾期部分其余不在系统取数,业务手填
       AND (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE)
     GROUP BY
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN
              'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
              'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
              'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN
              'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN
              'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN
              'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN
              'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN
              'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR
                  T1.PLA_MATURITY_DATE - I_DATADATE = 0 THEN
              'G21_1.8.A'
           END;

INSERT 
    INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                'G21_1.8.N'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                    COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                   'G21_1.8.N'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                       COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END
      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_1.8.A' AS ITEM_NUM,
             SUM(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND ITEM_CD = 'G21_1.8.A'
       GROUP BY I_DATADATE, A.ORG_NUM;

INSERT 
    INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                'G21_1.8.N'
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (REDEMP_DATE IS NULL OR
                    REDEMP_DATE - I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                   'G21_1.8.N'
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (REDEMP_DATE IS NULL OR
                       REDEMP_DATE - I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END;

INSERT INTO `G21_1.8.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

--处理133,260利息 不足的数据,与总账找齐

INSERT 
    INTO `G21_1.8.A` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       IS_TOTAL)
SELECT I_DATADATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       SUM(ITEM_VAL) AS ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       CASE
           WHEN ITEM_NUM = 'G21_1.9.G' THEN  --ADD BY DJH 20230509 里面有轧差不参与汇总
            'N'
         END IS_TOTAL
  FROM (SELECT 
         A.ORG_NUM,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         NVL(A.ITEM_VAL, 0) AS ITEM_VAL,
         ITEM_VAL_V,
         FLAG,
         B_CURR_CD
          FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI A
         WHERE A.DATA_DATE = I_DATADATE
           AND A.REP_NUM = 'G21'
        UNION ALL
        SELECT 
         B.ORG_NUM,
         'CBRC' AS SYS_NAM,
         'G21' REP_NUM,
         CASE
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YS' THEN
            'G21_1.8.A'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_WEEK' THEN
            'G21_1.8.B'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_MONTH' THEN
            'G21_1.8.C'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_1.8.D'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YEAR' THEN
            'G21_1.8.E'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_FIVE' THEN
            'G21_1.8.F'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_TEN' THEN
            'G21_1.8.M'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'MORE_TEN' THEN
            'G21_1.8.N'
           WHEN ITEM_CD =  '113201' AND B.QX = 'YQ' THEN
            'G21_1.8.H'
           WHEN  ITEM_CD = '2231' AND B.QX = 'NEXT_YS' THEN
            'G21_3.8.A'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_WEEK' THEN
            'G21_3.8.B'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_MONTH' THEN
            'G21_3.8.C'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_3.8.D'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YEAR' THEN
            'G21_3.8.E'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_FIVE' THEN
            'G21_3.8.F.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_TEN' THEN
            'G21_3.8.G1.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'MORE_TEN' THEN
            'G21_3.8.H1.2018'
         END ITEM_NUM,
         SUM(MINUS_AMT) AS MINUS_AMT,
         NULL ITEM_VAL_V,
         '2' AS FLAG,
         'ALL' CURR_CD
          FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP B
         WHERE MINUS_AMT <> 0
         GROUP BY B.ORG_NUM, ITEM_CD,QX)
 GROUP BY ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL_V, FLAG, B_CURR_CD;

--ADD BY DJH 20230718 资管次日数据
     INSERT INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
       SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_1.8.A',
             SUM(DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL,
             A.CURR_CD,
             A.ITEM_CD
        FROM V_PUB_IDX_FINA_GL A
        LEFT JOIN L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND ITEM_CD = '12210201' --jrsj垫资款 即 应收业务周转金 一直放次日
         AND ORG_NUM = '009816'
         AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
       GROUP BY A.ORG_NUM,A.CURR_CD, A.ITEM_CD;

---1.9其他有确定到期日的资产 : 买入返售应收利息+同业存单应收利息+债券投资应收利息
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1111买入返售本金对应的应收利息
    INSERT 
    INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '03' --买入返售
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04' --同业存单
      --AND ORG_NUM = '009804'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '05' --债券投资
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

所有AC账户（除3笔特殊账户）,按剩余期限划分取应收利息,其中2笔华创证券有限责任公司的到期日特殊处理成2028/11/30处理后划分；
        +140万+63.32万(固定值)--固定值放逾期
        G01的11.其他应收款009820机构放逾期；*/

     --ADD BY DJH 20240510  金融市场部 拆放同业利息补充进来
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金本金对应的应收利息
    INSERT 
    INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(A.INTEREST_ACCURAL)
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG IN ('01', '02' /*, '04'*/, '06', '07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资) 08(AC账户)  已在金融市场取数
        -- AND A.ORG_NUM IN ('009820', '009804')
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

--ADD BY DJH 20240510  投资银行部
    --009817机构存量的非标的应收利息+其他应收款按剩余期限划分


    INSERT INTO `G21_1.8.A`  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN 'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN 'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN 'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN 'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN 'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN 'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN 'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN 'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR  T1.PLA_MATURITY_DATE - I_DATADATE = 0  THEN
              'G21_1.8.A'
           END ITEM_NUM,
           SUM(T.INTEREST_ACCURAL+T.QTYSK)
      FROM CBRC_TMP_A_CBRC_LOAN_BAL T
      LEFT JOIN (SELECT Q.ACCT_NUM,
                        Q.PLA_MATURITY_DATE,
                        ROW_NUMBER() OVER(PARTITION BY Q.ACCT_NUM ORDER BY Q.PLA_MATURITY_DATE) RN
                   FROM L_ACCT_FUND_MMFUND_PAYM_SCHED Q
                  WHERE Q.DATA_DATE = I_DATADATE
                    AND DATA_SOURCE = '投行业务'
                    AND Q.PLA_MATURITY_DATE > I_DATADATE
                 ) T1
        ON T.ACCT_NUM = T1.ACCT_NUM
       AND T1.RN = 1
     WHERE T.DATA_DATE = I_DATADATE
       AND T.FLAG = '09'
       --由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第1.9项,除去逾期部分其余不在系统取数,业务手填
       AND (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE)
     GROUP BY
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN
              'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
              'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
              'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN
              'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN
              'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN
              'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN
              'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN
              'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR
                  T1.PLA_MATURITY_DATE - I_DATADATE = 0 THEN
              'G21_1.8.A'
           END;

INSERT 
    INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                'G21_1.8.N'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                    COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                   'G21_1.8.N'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                       COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END
      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_1.8.A' AS ITEM_NUM,
             SUM(A.DEBIT_BAL)
        FROM CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND ITEM_CD = 'G21_1.8.A'
       GROUP BY I_DATADATE, A.ORG_NUM;

INSERT 
    INTO `G21_1.8.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                'G21_1.8.N'
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (REDEMP_DATE IS NULL OR
                    REDEMP_DATE - I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                   'G21_1.8.N'
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (REDEMP_DATE IS NULL OR
                       REDEMP_DATE - I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END;

INSERT INTO `G21_1.8.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

INSERT  INTO `G21_1.8.A` 
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
                   T1.DATA_DATE,
                   CASE
                     WHEN T1.ORG_NUM LIKE '5%' OR T1.ORG_NUM LIKE '6%' THEN
                      T1.ORG_NUM
                     WHEN T1.ORG_NUM LIKE '%98%' THEN
                      T1.ORG_NUM
                     WHEN t1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                      '060300'
                     ELSE
                      SUBSTR(T1.ORG_NUM, 1, 4) || '00'
                   END as ORGNO,
                   T1.DATA_DEPARTMENT,
                   'CBRC' AS SYS_NAM,
                   'G21' REP_NUM,
                   CASE
                     WHEN T1.PMT_REMAIN_TERM_C = 1 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.A'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.B'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.C'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.D'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.E'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 360 * 5 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.F'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND
                          360 * 10 AND T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.M'
                     WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.N'
                     WHEN T1.IDENTITY_CODE = '4' THEN
                      'G21_1.8.H' --逾期利息包括应收利息+营改增挂账利息,营改增挂账利息废弃
                   END AS ITEM_NUM,
                   CASE
                     WHEN T1.IDENTITY_CODE = '3' THEN
                      T1.ACCU_INT_AMT * T2.CCY_RATE --正常贷款贷款表应计利息
                     WHEN T1.IDENTITY_CODE = '4' THEN
                      NVL(T1.OD_INT, 0) * T2.CCY_RATE --逾期贷款逾期利息
                   END AS TOTAL_VALUE,
                   T1.LOAN_NUM AS COL1, --贷款编号
                   T1.CURR_CD AS COL2, --币种
                   CASE
                     WHEN T1.ITEM_CD IN ('13030101', '13030103') THEN
                      '11320102'
                     WHEN T1.ITEM_CD IN ('13030201', '13030203') THEN
                      '11320104'
                     WHEN T1.ITEM_CD IN ('13050101', '13050103') THEN
                      '11320106'
                     WHEN T1.ITEM_CD IN ('13060101', '13060103') THEN
                      '11320108'
                     WHEN T1.ITEM_CD IN ('13060201', '13060203') THEN
                      '11320110'
                     WHEN T1.ITEM_CD IN ('13060301', '13060303') THEN
                      '11320112'
                     WHEN T1.ITEM_CD IN ('13060501', '13060503') THEN
                      '11320116'
                     ELSE
                      T1.ITEM_CD
                   END AS COL3, --本金对应应计利息科目
                   TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                   TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
                   T1.ACCT_NUM AS COL6, --贷款合同编号
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
            -- T1.REPAY_SEQ , --还款期数
            --  T1.ACCT_STATUS_1104,
              FROM CBRC_FDM_LNAC_PMT_LX T1
              LEFT JOIN L_PUBL_RATE T2
                ON T2.DATA_DATE = I_DATADATE
               AND T2.BASIC_CCY = T1.CURR_CD
               AND T2.FORWARD_CCY = 'CNY'
               AND (T1.ACCU_INT_AMT <>0 OR T1.OD_INT <>0);

--总账补充,条线为空值

       INSERT  INTO `G21_1.8.A` 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE)
         SELECT 
                I_DATADATE,
                A.ORG_NUM,
                '' AS DATA_DEPARTMENT,
                'CBRC' AS SYS_NAM,
                'G21' REP_NUM,
                'G21_1.8.A',
                SUM(A.DEBIT_BAL)
           FROM CBRC_FDM_LNAC_GL A
          WHERE A.DATA_DATE = I_DATADATE
            AND ITEM_CD = '1.8.A' --14310101  库存贵金属
            AND A.DEBIT_BAL <>0
          GROUP BY A.ORG_NUM
         UNION ALL
         SELECT 
                I_DATADATE,
                A.ORG_NUM,
                '' AS DATA_DEPARTMENT,
                'CBRC' AS SYS_NAM,
                'G21' REP_NUM,
                'G21_1.8.B',
                sum(A.DEBIT_BAL)
           FROM CBRC_FDM_LNAC_GL A
          WHERE A.DATA_DATE = I_DATADATE
            AND ITEM_CD = '1.8.B' -- '11003'
            AND A.DEBIT_BAL <>0
          GROUP BY A.ORG_NUM
         UNION  ALL
         SELECT 
                I_DATADATE,
                A.ORG_NUM,
                '' AS DATA_DEPARTMENT,
                'CBRC' AS SYS_NAM,
                'G21' REP_NUM,
                'G21_1.8.H',
                sum(A.DEBIT_BAL)
           FROM CBRC_FDM_LNAC_GL A
          WHERE A.DATA_DATE = I_DATADATE
            AND ITEM_CD = '1.8.H' --113201信用卡利息 放在逾期
            AND A.DEBIT_BAL <>0
          GROUP BY A.ORG_NUM;

--补充1132应收利息轧差,条线为空值
          INSERT  INTO `G21_1.8.A` 
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE)
            SELECT 
             I_DATADATE,
             B.ORG_NUM,
             '' AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             'G21' REP_NUM,
             CASE
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YS' THEN
                'G21_1.8.A'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_WEEK' THEN
                'G21_1.8.B'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_MONTH' THEN
                'G21_1.8.C'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_QUARTER' THEN
                'G21_1.8.D'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YEAR' THEN
                'G21_1.8.E'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_FIVE' THEN
                'G21_1.8.F'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_TEN' THEN
                'G21_1.8.M'
               WHEN ITEM_CD = '113201' AND B.QX = 'MORE_TEN' THEN
                'G21_1.8.N'
               WHEN ITEM_CD = '113201' AND B.QX = 'YQ' THEN
                'G21_1.8.H'
             END ITEM_NUM,
             SUM(MINUS_AMT) AS TOTAL_VALUE
              FROM CBRC_ITEM_MINUS_AMT_TEMP B
             WHERE MINUS_AMT <> 0
               AND ITEM_CD = '113201'
             GROUP BY B.ORG_NUM, ITEM_CD, QX;

--处理133,260利息 不足的数据,与总账找齐

INSERT 
INTO `G21_1.8.A` 
  (DATA_DATE,
   ORG_NUM,
   DATA_DEPARTMENT,
   SYS_NAM,
   REP_NUM,
   ITEM_NUM,
   ITEM_VAL,
   ITEM_VAL_V,
   FLAG,
   B_CURR_CD,
   IS_TOTAL)
  SELECT I_DATADATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         SUM(ITEM_VAL) AS ITEM_VAL,
         ITEM_VAL_V,
         FLAG,
         B_CURR_CD,
         CASE
           WHEN ITEM_NUM = 'G21_1.9.G' THEN --ADD BY DJH 20230509 里面有轧差不参与汇总
            'N'
         END IS_TOTAL
    FROM (SELECT 
           A.ORG_NUM,
           '' AS DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           NVL(A.ITEM_VAL, 0) AS ITEM_VAL,
           ITEM_VAL_V,
           FLAG,
           B_CURR_CD
            FROM CBRC_A_REPT_ITEM_VAL_NGI A
           WHERE A.DATA_DATE = I_DATADATE
             AND A.REP_NUM = 'G21'
          UNION ALL
          SELECT 
           B.ORG_NUM,
           '' AS DATA_DEPARTMENT,
           'CBRC' AS SYS_NAM,
           'G21' REP_NUM,
           CASE
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YS' THEN
              'G21_1.8.A'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_WEEK' THEN
              'G21_1.8.B'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_MONTH' THEN
              'G21_1.8.C'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_QUARTER' THEN
              'G21_1.8.D'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YEAR' THEN
              'G21_1.8.E'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_FIVE' THEN
              'G21_1.8.F'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_TEN' THEN
              'G21_1.8.M'
             WHEN ITEM_CD = '113201' AND B.QX = 'MORE_TEN' THEN
              'G21_1.8.N'
             WHEN ITEM_CD = '113201' AND B.QX = 'YQ' THEN
              'G21_1.8.H'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YS' THEN
              'G21_3.8.A'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_WEEK' THEN
              'G21_3.8.B'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_MONTH' THEN
              'G21_3.8.C'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_QUARTER' THEN
              'G21_3.8.D'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YEAR' THEN
              'G21_3.8.E'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_FIVE' THEN
              'G21_3.8.F.2018'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_TEN' THEN
              'G21_3.8.G1.2018'
             WHEN ITEM_CD = '2231' AND B.QX = 'MORE_TEN' THEN
              'G21_3.8.H1.2018'
           END ITEM_NUM,
           SUM(MINUS_AMT) AS MINUS_AMT,
           NULL ITEM_VAL_V,
           '2' AS FLAG,
           'ALL' CURR_CD
            FROM CBRC_ITEM_MINUS_AMT_TEMP B
           WHERE MINUS_AMT <> 0
             AND ITEM_CD = '2231' ---- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级] 因为113201在明细数据中已出
           GROUP BY B.ORG_NUM, ITEM_CD, QX
          UNION ALL
          SELECT 
                 ORG_NUM,
                 DATA_DEPARTMENT,
                 SYS_NAM,
                 REP_NUM,
                 ITEM_NUM,
                 SUM(TOTAL_VALUE) AS ITEM_VAL,
                 '' ITEM_VAL_V,
                 '2' AS FLAG,
                 'ALL' CURR_CD
            FROM CBRC_A_REPT_DWD_G21
           GROUP BY ORG_NUM, DATA_DEPARTMENT, SYS_NAM, REP_NUM, ITEM_NUM)
   GROUP BY ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            ITEM_VAL_V,
            FLAG,
            B_CURR_CD;

--====================================================
    --G22 1.5一个月内到期的应收利息及其他应收款  增加资管009816 取剩余期限30天（含）内中收计提表【本期累计计提中收】 ADD BY DJH 20241205数仓逻辑变更自动取数
    --====================================================
 --人民币
      INSERT INTO `G21_1.8.A`
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.A',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
           AND FLAG = '1'
           AND REDEMP_DATE IS NULL
            OR (REDEMP_DATE - I_DATADATE >= 1 AND
               REDEMP_DATE - I_DATADATE <= 30)
           AND A.CURR_CD = 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.A',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
           AND FLAG = '1'
           AND COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL
            OR (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE >= 1 AND
               COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE <= 30)
           AND A.CURR_CD = 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
       SELECT I_DATADATE,
              A.ORG_NUM,
              'G22R_1.5.A' AS ITEM_NUM,
              SUM(A.DEBIT_BAL)
         FROM PM_RSDATA.CBRC_FDM_LNAC_GL A   --G21取总账数据表
        WHERE A.DATA_DATE = I_DATADATE
          AND ITEM_CD = 'G21_1.8.A'
          AND A.CURR_CD = 'CNY'
        GROUP BY I_DATADATE, A.ORG_NUM;

--外币

      INSERT INTO `G21_1.8.A`
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.B',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
           AND FLAG = '1'
           AND REDEMP_DATE IS NULL
            OR (REDEMP_DATE - I_DATADATE >= 1 AND
               REDEMP_DATE - I_DATADATE <= 30)
           AND A.CURR_CD <> 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.B',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
           AND FLAG = '1'
           AND COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL
            OR (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE >= 1 AND
               COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE <= 30)
           AND A.CURR_CD <> 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
       SELECT I_DATADATE,
              A.ORG_NUM,
              'G22R_1.5.B' AS ITEM_NUM,
              SUM(A.DEBIT_BAL)
         FROM PM_RSDATA.CBRC_FDM_LNAC_GL A   --G21取总账数据表
        WHERE A.DATA_DATE = I_DATADATE
          AND ITEM_CD = 'G21_1.8.A'
          AND A.CURR_CD <> 'CNY'
        GROUP BY I_DATADATE, A.ORG_NUM;

--====================================================
    --G22 1.5一个月内到期的应收利息及其他应收款  增加资管009816 取剩余期限30天（含）内中收计提表【本期累计计提中收】 ADD BY DJH 20241205数仓逻辑变更自动取数
    --====================================================
 --人民币
      INSERT INTO `G21_1.8.A`
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.A',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
           AND FLAG = '1'
           AND REDEMP_DATE IS NULL
            OR (REDEMP_DATE - I_DATADATE >= 1 AND
               REDEMP_DATE - I_DATADATE <= 30)
           AND A.CURR_CD = 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.A',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
           AND FLAG = '1'
           AND COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL
            OR (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE >= 1 AND
               COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE <= 30)
           AND A.CURR_CD = 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
       SELECT I_DATADATE,
              A.ORG_NUM,
              'G22R_1.5.A' AS ITEM_NUM,
              SUM(A.DEBIT_BAL)
         FROM PM_RSDATA.CBRC_FDM_LNAC_GL A   --G21取总账数据表
        WHERE A.DATA_DATE = I_DATADATE
          AND ITEM_CD = 'G21_1.8.A'
          AND A.CURR_CD = 'CNY'
        GROUP BY I_DATADATE, A.ORG_NUM;

--外币

      INSERT INTO `G21_1.8.A`
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.B',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
           AND FLAG = '1'
           AND REDEMP_DATE IS NULL
            OR (REDEMP_DATE - I_DATADATE >= 1 AND
               REDEMP_DATE - I_DATADATE <= 30)
           AND A.CURR_CD <> 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.B',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
           AND FLAG = '1'
           AND COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL
            OR (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE >= 1 AND
               COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE <= 30)
           AND A.CURR_CD <> 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
       SELECT I_DATADATE,
              A.ORG_NUM,
              'G22R_1.5.B' AS ITEM_NUM,
              SUM(A.DEBIT_BAL)
         FROM PM_RSDATA.CBRC_FDM_LNAC_GL A   --G21取总账数据表
        WHERE A.DATA_DATE = I_DATADATE
          AND ITEM_CD = 'G21_1.8.A'
          AND A.CURR_CD <> 'CNY'
        GROUP BY I_DATADATE, A.ORG_NUM;


-- 指标: G21_3.5.2.A
--  3.5.2活期存款    201、211、217、218、234010204、243、244
    INSERT 
    INTO `G21_3.5.2.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_3.5.2.A' AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款账户信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND (A.GL_ITEM_CODE  IN
             ('20110201', '20110101', '20110102','20110111', '20110206', '20130101','20130201','20130301', '20140101','20140201','20140301') OR
             A.GL_ITEM_CODE = '20120106'
             or a.gl_item_code in ('22410101','22410102','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
             )
       GROUP BY A.ORG_NUM;

--  3.5.2活期存款    201、211、217、218、234010204、243、244
    INSERT 
    INTO `G21_3.5.2.A`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_3.5.2.A' AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款账户信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND (A.GL_ITEM_CODE  IN
             ('20110201', '20110101', '20110102','20110111', '20110206', '20130101','20130201','20130301', '20140101','20140201','20140301') OR
             A.GL_ITEM_CODE = '20120106'
             or a.gl_item_code in ('22410101','22410102','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
             )
       GROUP BY A.ORG_NUM;


-- ========== 逻辑组 26: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'H' THEN
                'G21_3.7.H1.2018'
               WHEN REMAIN_TERM_CODE = 'G' THEN
                'G21_3.7.G1.2018'
               WHEN REMAIN_TERM_CODE = 'F' THEN
                'G21_3.7.F.2018'
               WHEN REMAIN_TERM_CODE = 'E' THEN
                'G21_3.7.E.2018'
               WHEN REMAIN_TERM_CODE = 'D' THEN
                'G21_3.7.D.2018'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G21_3.7.C.2018'
               WHEN REMAIN_TERM_CODE = 'B' THEN
                'G21_3.7.B.2018'
               WHEN REMAIN_TERM_CODE = 'A' THEN
                'G21_3.7.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款账户信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '06'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.7.H1.2018'
                  WHEN REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.7.G1.2018'
                  WHEN REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.7.F.2018'
                  WHEN REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.7.E.2018'
                  WHEN REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.7.D.2018'
                  WHEN REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.7.C.2018'
                  WHEN REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.7.B.2018'
                  WHEN REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.7.A.2018'
                END;

--2340301同业存单款项-面值
    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'H' THEN
                'G21_3.7.H1.2018'
               WHEN REMAIN_TERM_CODE = 'G' THEN
                'G21_3.7.G1.2018'
               WHEN REMAIN_TERM_CODE = 'F' THEN
                'G21_3.7.F.2018'
               WHEN REMAIN_TERM_CODE = 'E' THEN
                'G21_3.7.E.2018'
               WHEN REMAIN_TERM_CODE = 'D' THEN
                'G21_3.7.D.2018'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G21_3.7.C.2018'
               WHEN REMAIN_TERM_CODE = 'B' THEN
                'G21_3.7.B.2018'
               WHEN REMAIN_TERM_CODE = 'A' THEN
                'G21_3.7.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款账户信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '06'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.7.H1.2018'
                  WHEN REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.7.G1.2018'
                  WHEN REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.7.F.2018'
                  WHEN REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.7.E.2018'
                  WHEN REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.7.D.2018'
                  WHEN REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.7.C.2018'
                  WHEN REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.7.B.2018'
                  WHEN REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.7.A.2018'
                END
) q_26
INSERT INTO `G21_3.7.E.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.7.D.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *
INSERT INTO `G21_3.7.C.2018` (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
SELECT *;

-- 指标: G21_3.4.1.C.2018
INSERT 
    INTO `G21_3.4.1.C.2018`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.4.1.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.4.1.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.4.1.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.4.1.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.4.1.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.4.1.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.4.1.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.4.1.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS BALANCE_CNY
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '07'
         AND A.ACCT_BAL_RMB <> 0 --余额不为0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.4.1.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.4.1.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.4.1.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.4.1.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.4.1.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.4.1.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.4.1.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.4.1.A.2018'
                END;

INSERT 
    INTO `G21_3.4.1.C.2018`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.4.1.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.4.1.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.4.1.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.4.1.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.4.1.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.4.1.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.4.1.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.4.1.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS BALANCE_CNY
        FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '07'
         AND A.ACCT_BAL_RMB <> 0 --余额不为0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.4.1.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.4.1.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.4.1.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.4.1.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.4.1.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.4.1.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.4.1.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.4.1.A.2018'
                END;


-- 指标: G21_1.8.B
---1.9其他有确定到期日的资产 : 买入返售应收利息+同业存单应收利息+债券投资应收利息
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1111买入返售本金对应的应收利息
    INSERT 
    INTO `G21_1.8.B`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '03' --买入返售
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `G21_1.8.B`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04' --同业存单
      --AND ORG_NUM = '009804'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `G21_1.8.B`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '05' --债券投资
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

所有AC账户（除3笔特殊账户）,按剩余期限划分取应收利息,其中2笔华创证券有限责任公司的到期日特殊处理成2028/11/30处理后划分；
        +140万+63.32万(固定值)--固定值放逾期
        G01的11.其他应收款009820机构放逾期；*/

     --ADD BY DJH 20240510  金融市场部 拆放同业利息补充进来
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金本金对应的应收利息
    INSERT 
    INTO `G21_1.8.B`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(A.INTEREST_ACCURAL)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG IN ('01', '02' /*, '04'*/, '06', '07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资) 08(AC账户)  已在金融市场取数
        -- AND A.ORG_NUM IN ('009820', '009804')
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

--ADD BY DJH 20240510  投资银行部
    --009817机构存量的非标的应收利息+其他应收款按剩余期限划分


    INSERT INTO `G21_1.8.B`  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN 'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN 'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN 'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN 'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN 'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN 'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN 'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN 'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR  T1.PLA_MATURITY_DATE - I_DATADATE = 0  THEN
              'G21_1.8.A'
           END ITEM_NUM,
           SUM(T.INTEREST_ACCURAL+T.QTYSK)
      FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL T
      LEFT JOIN (SELECT Q.ACCT_NUM,
                        Q.PLA_MATURITY_DATE,
                        ROW_NUMBER() OVER(PARTITION BY Q.ACCT_NUM ORDER BY Q.PLA_MATURITY_DATE) RN
                   FROM PM_RSDATA.SMTMODS_L_ACCT_FUND_MMFUND_PAYM_SCHED Q
                  WHERE Q.DATA_DATE = I_DATADATE
                    AND DATA_SOURCE = '投行业务'
                    AND Q.PLA_MATURITY_DATE > I_DATADATE
                 ) T1
        ON T.ACCT_NUM = T1.ACCT_NUM
       AND T1.RN = 1
     WHERE T.DATA_DATE = I_DATADATE
       AND T.FLAG = '09'
       --由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第1.9项,除去逾期部分其余不在系统取数,业务手填
       AND (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE)
     GROUP BY
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN
              'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
              'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
              'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN
              'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN
              'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN
              'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN
              'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN
              'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR
                  T1.PLA_MATURITY_DATE - I_DATADATE = 0 THEN
              'G21_1.8.A'
           END;

INSERT 
    INTO `G21_1.8.B`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                'G21_1.8.N'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                    COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                   'G21_1.8.N'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                       COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END
      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_1.8.A' AS ITEM_NUM,
             SUM(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND ITEM_CD = 'G21_1.8.A'
       GROUP BY I_DATADATE, A.ORG_NUM;

INSERT 
    INTO `G21_1.8.B`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                'G21_1.8.N'
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (REDEMP_DATE IS NULL OR
                    REDEMP_DATE - I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                   'G21_1.8.N'
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (REDEMP_DATE IS NULL OR
                       REDEMP_DATE - I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END;

INSERT INTO `G21_1.8.B`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

--处理133,260利息 不足的数据,与总账找齐

INSERT 
    INTO `G21_1.8.B` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       IS_TOTAL)
SELECT I_DATADATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       SUM(ITEM_VAL) AS ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       CASE
           WHEN ITEM_NUM = 'G21_1.9.G' THEN  --ADD BY DJH 20230509 里面有轧差不参与汇总
            'N'
         END IS_TOTAL
  FROM (SELECT 
         A.ORG_NUM,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         NVL(A.ITEM_VAL, 0) AS ITEM_VAL,
         ITEM_VAL_V,
         FLAG,
         B_CURR_CD
          FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI A
         WHERE A.DATA_DATE = I_DATADATE
           AND A.REP_NUM = 'G21'
        UNION ALL
        SELECT 
         B.ORG_NUM,
         'CBRC' AS SYS_NAM,
         'G21' REP_NUM,
         CASE
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YS' THEN
            'G21_1.8.A'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_WEEK' THEN
            'G21_1.8.B'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_MONTH' THEN
            'G21_1.8.C'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_1.8.D'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YEAR' THEN
            'G21_1.8.E'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_FIVE' THEN
            'G21_1.8.F'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_TEN' THEN
            'G21_1.8.M'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'MORE_TEN' THEN
            'G21_1.8.N'
           WHEN ITEM_CD =  '113201' AND B.QX = 'YQ' THEN
            'G21_1.8.H'
           WHEN  ITEM_CD = '2231' AND B.QX = 'NEXT_YS' THEN
            'G21_3.8.A'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_WEEK' THEN
            'G21_3.8.B'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_MONTH' THEN
            'G21_3.8.C'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_3.8.D'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YEAR' THEN
            'G21_3.8.E'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_FIVE' THEN
            'G21_3.8.F.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_TEN' THEN
            'G21_3.8.G1.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'MORE_TEN' THEN
            'G21_3.8.H1.2018'
         END ITEM_NUM,
         SUM(MINUS_AMT) AS MINUS_AMT,
         NULL ITEM_VAL_V,
         '2' AS FLAG,
         'ALL' CURR_CD
          FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP B
         WHERE MINUS_AMT <> 0
         GROUP BY B.ORG_NUM, ITEM_CD,QX)
 GROUP BY ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL_V, FLAG, B_CURR_CD;

---1.9其他有确定到期日的资产 : 买入返售应收利息+同业存单应收利息+债券投资应收利息
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1111买入返售本金对应的应收利息
    INSERT 
    INTO `G21_1.8.B`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '03' --买入返售
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `G21_1.8.B`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04' --同业存单
      --AND ORG_NUM = '009804'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

INSERT 
    INTO `G21_1.8.B`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '05' --债券投资
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

所有AC账户（除3笔特殊账户）,按剩余期限划分取应收利息,其中2笔华创证券有限责任公司的到期日特殊处理成2028/11/30处理后划分；
        +140万+63.32万(固定值)--固定值放逾期
        G01的11.其他应收款009820机构放逾期；*/

     --ADD BY DJH 20240510  金融市场部 拆放同业利息补充进来
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金本金对应的应收利息
    INSERT 
    INTO `G21_1.8.B`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(A.INTEREST_ACCURAL)
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG IN ('01', '02' /*, '04'*/, '06', '07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资) 08(AC账户)  已在金融市场取数
        -- AND A.ORG_NUM IN ('009820', '009804')
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

--ADD BY DJH 20240510  投资银行部
    --009817机构存量的非标的应收利息+其他应收款按剩余期限划分


    INSERT INTO `G21_1.8.B`  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN 'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN 'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN 'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN 'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN 'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN 'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN 'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN 'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR  T1.PLA_MATURITY_DATE - I_DATADATE = 0  THEN
              'G21_1.8.A'
           END ITEM_NUM,
           SUM(T.INTEREST_ACCURAL+T.QTYSK)
      FROM CBRC_TMP_A_CBRC_LOAN_BAL T
      LEFT JOIN (SELECT Q.ACCT_NUM,
                        Q.PLA_MATURITY_DATE,
                        ROW_NUMBER() OVER(PARTITION BY Q.ACCT_NUM ORDER BY Q.PLA_MATURITY_DATE) RN
                   FROM L_ACCT_FUND_MMFUND_PAYM_SCHED Q
                  WHERE Q.DATA_DATE = I_DATADATE
                    AND DATA_SOURCE = '投行业务'
                    AND Q.PLA_MATURITY_DATE > I_DATADATE
                 ) T1
        ON T.ACCT_NUM = T1.ACCT_NUM
       AND T1.RN = 1
     WHERE T.DATA_DATE = I_DATADATE
       AND T.FLAG = '09'
       --由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第1.9项,除去逾期部分其余不在系统取数,业务手填
       AND (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE)
     GROUP BY
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN
              'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
              'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
              'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN
              'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN
              'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN
              'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN
              'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN
              'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR
                  T1.PLA_MATURITY_DATE - I_DATADATE = 0 THEN
              'G21_1.8.A'
           END;

INSERT 
    INTO `G21_1.8.B`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                'G21_1.8.N'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                    COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                   'G21_1.8.N'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                       COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END
      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_1.8.A' AS ITEM_NUM,
             SUM(A.DEBIT_BAL)
        FROM CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND ITEM_CD = 'G21_1.8.A'
       GROUP BY I_DATADATE, A.ORG_NUM;

INSERT 
    INTO `G21_1.8.B`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                'G21_1.8.N'
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (REDEMP_DATE IS NULL OR
                    REDEMP_DATE - I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                   'G21_1.8.N'
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (REDEMP_DATE IS NULL OR
                       REDEMP_DATE - I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END;

INSERT INTO `G21_1.8.B`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;

INSERT  INTO `G21_1.8.B` 
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
                   T1.DATA_DATE,
                   CASE
                     WHEN T1.ORG_NUM LIKE '5%' OR T1.ORG_NUM LIKE '6%' THEN
                      T1.ORG_NUM
                     WHEN T1.ORG_NUM LIKE '%98%' THEN
                      T1.ORG_NUM
                     WHEN t1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                      '060300'
                     ELSE
                      SUBSTR(T1.ORG_NUM, 1, 4) || '00'
                   END as ORGNO,
                   T1.DATA_DEPARTMENT,
                   'CBRC' AS SYS_NAM,
                   'G21' REP_NUM,
                   CASE
                     WHEN T1.PMT_REMAIN_TERM_C = 1 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.A'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.B'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.C'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.D'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.E'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 360 * 5 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.F'
                     WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND
                          360 * 10 AND T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.M'
                     WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 AND
                          T1.IDENTITY_CODE = '3' THEN
                      'G21_1.8.N'
                     WHEN T1.IDENTITY_CODE = '4' THEN
                      'G21_1.8.H' --逾期利息包括应收利息+营改增挂账利息,营改增挂账利息废弃
                   END AS ITEM_NUM,
                   CASE
                     WHEN T1.IDENTITY_CODE = '3' THEN
                      T1.ACCU_INT_AMT * T2.CCY_RATE --正常贷款贷款表应计利息
                     WHEN T1.IDENTITY_CODE = '4' THEN
                      NVL(T1.OD_INT, 0) * T2.CCY_RATE --逾期贷款逾期利息
                   END AS TOTAL_VALUE,
                   T1.LOAN_NUM AS COL1, --贷款编号
                   T1.CURR_CD AS COL2, --币种
                   CASE
                     WHEN T1.ITEM_CD IN ('13030101', '13030103') THEN
                      '11320102'
                     WHEN T1.ITEM_CD IN ('13030201', '13030203') THEN
                      '11320104'
                     WHEN T1.ITEM_CD IN ('13050101', '13050103') THEN
                      '11320106'
                     WHEN T1.ITEM_CD IN ('13060101', '13060103') THEN
                      '11320108'
                     WHEN T1.ITEM_CD IN ('13060201', '13060203') THEN
                      '11320110'
                     WHEN T1.ITEM_CD IN ('13060301', '13060303') THEN
                      '11320112'
                     WHEN T1.ITEM_CD IN ('13060501', '13060503') THEN
                      '11320116'
                     ELSE
                      T1.ITEM_CD
                   END AS COL3, --本金对应应计利息科目
                   TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                   TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
                   T1.ACCT_NUM AS COL6, --贷款合同编号
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
            -- T1.REPAY_SEQ , --还款期数
            --  T1.ACCT_STATUS_1104,
              FROM CBRC_FDM_LNAC_PMT_LX T1
              LEFT JOIN L_PUBL_RATE T2
                ON T2.DATA_DATE = I_DATADATE
               AND T2.BASIC_CCY = T1.CURR_CD
               AND T2.FORWARD_CCY = 'CNY'
               AND (T1.ACCU_INT_AMT <>0 OR T1.OD_INT <>0);

--总账补充,条线为空值

       INSERT  INTO `G21_1.8.B` 
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE)
         SELECT 
                I_DATADATE,
                A.ORG_NUM,
                '' AS DATA_DEPARTMENT,
                'CBRC' AS SYS_NAM,
                'G21' REP_NUM,
                'G21_1.8.A',
                SUM(A.DEBIT_BAL)
           FROM CBRC_FDM_LNAC_GL A
          WHERE A.DATA_DATE = I_DATADATE
            AND ITEM_CD = '1.8.A' --14310101  库存贵金属
            AND A.DEBIT_BAL <>0
          GROUP BY A.ORG_NUM
         UNION ALL
         SELECT 
                I_DATADATE,
                A.ORG_NUM,
                '' AS DATA_DEPARTMENT,
                'CBRC' AS SYS_NAM,
                'G21' REP_NUM,
                'G21_1.8.B',
                sum(A.DEBIT_BAL)
           FROM CBRC_FDM_LNAC_GL A
          WHERE A.DATA_DATE = I_DATADATE
            AND ITEM_CD = '1.8.B' -- '11003'
            AND A.DEBIT_BAL <>0
          GROUP BY A.ORG_NUM
         UNION  ALL
         SELECT 
                I_DATADATE,
                A.ORG_NUM,
                '' AS DATA_DEPARTMENT,
                'CBRC' AS SYS_NAM,
                'G21' REP_NUM,
                'G21_1.8.H',
                sum(A.DEBIT_BAL)
           FROM CBRC_FDM_LNAC_GL A
          WHERE A.DATA_DATE = I_DATADATE
            AND ITEM_CD = '1.8.H' --113201信用卡利息 放在逾期
            AND A.DEBIT_BAL <>0
          GROUP BY A.ORG_NUM;

--补充1132应收利息轧差,条线为空值
          INSERT  INTO `G21_1.8.B` 
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE)
            SELECT 
             I_DATADATE,
             B.ORG_NUM,
             '' AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             'G21' REP_NUM,
             CASE
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YS' THEN
                'G21_1.8.A'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_WEEK' THEN
                'G21_1.8.B'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_MONTH' THEN
                'G21_1.8.C'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_QUARTER' THEN
                'G21_1.8.D'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YEAR' THEN
                'G21_1.8.E'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_FIVE' THEN
                'G21_1.8.F'
               WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_TEN' THEN
                'G21_1.8.M'
               WHEN ITEM_CD = '113201' AND B.QX = 'MORE_TEN' THEN
                'G21_1.8.N'
               WHEN ITEM_CD = '113201' AND B.QX = 'YQ' THEN
                'G21_1.8.H'
             END ITEM_NUM,
             SUM(MINUS_AMT) AS TOTAL_VALUE
              FROM CBRC_ITEM_MINUS_AMT_TEMP B
             WHERE MINUS_AMT <> 0
               AND ITEM_CD = '113201'
             GROUP BY B.ORG_NUM, ITEM_CD, QX;

--处理133,260利息 不足的数据,与总账找齐

INSERT 
INTO `G21_1.8.B` 
  (DATA_DATE,
   ORG_NUM,
   DATA_DEPARTMENT,
   SYS_NAM,
   REP_NUM,
   ITEM_NUM,
   ITEM_VAL,
   ITEM_VAL_V,
   FLAG,
   B_CURR_CD,
   IS_TOTAL)
  SELECT I_DATADATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         SUM(ITEM_VAL) AS ITEM_VAL,
         ITEM_VAL_V,
         FLAG,
         B_CURR_CD,
         CASE
           WHEN ITEM_NUM = 'G21_1.9.G' THEN --ADD BY DJH 20230509 里面有轧差不参与汇总
            'N'
         END IS_TOTAL
    FROM (SELECT 
           A.ORG_NUM,
           '' AS DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           NVL(A.ITEM_VAL, 0) AS ITEM_VAL,
           ITEM_VAL_V,
           FLAG,
           B_CURR_CD
            FROM CBRC_A_REPT_ITEM_VAL_NGI A
           WHERE A.DATA_DATE = I_DATADATE
             AND A.REP_NUM = 'G21'
          UNION ALL
          SELECT 
           B.ORG_NUM,
           '' AS DATA_DEPARTMENT,
           'CBRC' AS SYS_NAM,
           'G21' REP_NUM,
           CASE
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YS' THEN
              'G21_1.8.A'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_WEEK' THEN
              'G21_1.8.B'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_MONTH' THEN
              'G21_1.8.C'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_QUARTER' THEN
              'G21_1.8.D'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_YEAR' THEN
              'G21_1.8.E'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_FIVE' THEN
              'G21_1.8.F'
             WHEN ITEM_CD = '113201' AND B.QX = 'NEXT_TEN' THEN
              'G21_1.8.M'
             WHEN ITEM_CD = '113201' AND B.QX = 'MORE_TEN' THEN
              'G21_1.8.N'
             WHEN ITEM_CD = '113201' AND B.QX = 'YQ' THEN
              'G21_1.8.H'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YS' THEN
              'G21_3.8.A'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_WEEK' THEN
              'G21_3.8.B'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_MONTH' THEN
              'G21_3.8.C'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_QUARTER' THEN
              'G21_3.8.D'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YEAR' THEN
              'G21_3.8.E'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_FIVE' THEN
              'G21_3.8.F.2018'
             WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_TEN' THEN
              'G21_3.8.G1.2018'
             WHEN ITEM_CD = '2231' AND B.QX = 'MORE_TEN' THEN
              'G21_3.8.H1.2018'
           END ITEM_NUM,
           SUM(MINUS_AMT) AS MINUS_AMT,
           NULL ITEM_VAL_V,
           '2' AS FLAG,
           'ALL' CURR_CD
            FROM CBRC_ITEM_MINUS_AMT_TEMP B
           WHERE MINUS_AMT <> 0
             AND ITEM_CD = '2231' ---- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级] 因为113201在明细数据中已出
           GROUP BY B.ORG_NUM, ITEM_CD, QX
          UNION ALL
          SELECT 
                 ORG_NUM,
                 DATA_DEPARTMENT,
                 SYS_NAM,
                 REP_NUM,
                 ITEM_NUM,
                 SUM(TOTAL_VALUE) AS ITEM_VAL,
                 '' ITEM_VAL_V,
                 '2' AS FLAG,
                 'ALL' CURR_CD
            FROM CBRC_A_REPT_DWD_G21
           GROUP BY ORG_NUM, DATA_DEPARTMENT, SYS_NAM, REP_NUM, ITEM_NUM)
   GROUP BY ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            ITEM_VAL_V,
            FLAG,
            B_CURR_CD;


-- 指标: G21_16.1.C.2021
INSERT 
    INTO `G21_16.1.C.2021`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                'G21_16.1.H.2021'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 5 THEN
                'G21_16.1.G1.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 360 THEN
                'G21_16.1.F.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 90 THEN
                'G21_16.1.E.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 30 THEN
                'G21_16.1.D.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 7 THEN
                'G21_16.1.C.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 1 THEN
                'G21_16.1.B.2021'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                    COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE <= 1) THEN
                'G21_16.1.A.2021'
             END,
             SUM(A.END_PROD_AMT_CNY)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
          AND FLAG='1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 10 THEN
                   'G21_16.1.H.2021'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_16.1.G1.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 360 THEN
                   'G21_16.1.F.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 90 THEN
                   'G21_16.1.E.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 30 THEN
                   'G21_16.1.D.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 7 THEN
                   'G21_16.1.C.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 1 THEN
                   'G21_16.1.B.2021'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                       COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE <= 1) THEN
                   'G21_16.1.A.2021'
                END;

INSERT 
    INTO `G21_16.1.C.2021`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                'G21_16.1.H.2021'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 5 THEN
                'G21_16.1.G1.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 360 THEN
                'G21_16.1.F.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 90 THEN
                'G21_16.1.E.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 30 THEN
                'G21_16.1.D.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 7 THEN
                'G21_16.1.C.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 1 THEN
                'G21_16.1.B.2021'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                    COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE <= 1) THEN
                'G21_16.1.A.2021'
             END,
             SUM(A.END_PROD_AMT_CNY)
        FROM CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
          AND FLAG='1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 10 THEN
                   'G21_16.1.H.2021'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_16.1.G1.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 360 THEN
                   'G21_16.1.F.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 90 THEN
                   'G21_16.1.E.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 30 THEN
                   'G21_16.1.D.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 7 THEN
                   'G21_16.1.C.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 1 THEN
                   'G21_16.1.B.2021'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                       COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE <= 1) THEN
                   'G21_16.1.A.2021'
                END;

--ADD BY DJH 20230417 2.1.5.5.1其中：属于理财产品的部分  G21封闭式+开放式,30日内到期
 INSERT 
 INTO `G21_16.1.C.2021` 
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
 INTO `G21_16.1.C.2021` 
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


-- 指标: G21_3.6.G1.2018
INSERT 
    INTO `G21_3.6.G1.2018`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'H' THEN
                'G21_3.6.H1.2018'
               WHEN REMAIN_TERM_CODE = 'G' THEN
                'G21_3.6.G1.2018'
               WHEN REMAIN_TERM_CODE = 'F' THEN
                'G21_3.6.F.2018'
               WHEN REMAIN_TERM_CODE = 'E' THEN
                'G21_3.6.E.2018'
               WHEN REMAIN_TERM_CODE = 'D' THEN
                'G21_3.6.D.2018'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G21_3.6.C.2018'
               WHEN REMAIN_TERM_CODE = 'B' THEN
                'G21_3.6.B.2018'
               WHEN REMAIN_TERM_CODE = 'A' THEN
                'G21_3.6.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款账户信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '08'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.6.H1.2018'
                  WHEN REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.6.G1.2018'
                  WHEN REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.6.F.2018'
                  WHEN REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.6.E.2018'
                  WHEN REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.6.D.2018'
                  WHEN REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.6.C.2018'
                  WHEN REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.6.B.2018'
                  WHEN REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.6.A.2018'
                END;

INSERT 
    INTO `G21_3.6.G1.2018`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'H' THEN
                'G21_3.6.H1.2018'
               WHEN REMAIN_TERM_CODE = 'G' THEN
                'G21_3.6.G1.2018'
               WHEN REMAIN_TERM_CODE = 'F' THEN
                'G21_3.6.F.2018'
               WHEN REMAIN_TERM_CODE = 'E' THEN
                'G21_3.6.E.2018'
               WHEN REMAIN_TERM_CODE = 'D' THEN
                'G21_3.6.D.2018'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G21_3.6.C.2018'
               WHEN REMAIN_TERM_CODE = 'B' THEN
                'G21_3.6.B.2018'
               WHEN REMAIN_TERM_CODE = 'A' THEN
                'G21_3.6.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款账户信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '08'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.6.H1.2018'
                  WHEN REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.6.G1.2018'
                  WHEN REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.6.F.2018'
                  WHEN REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.6.E.2018'
                  WHEN REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.6.D.2018'
                  WHEN REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.6.C.2018'
                  WHEN REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.6.B.2018'
                  WHEN REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.6.A.2018'
                END;


-- 指标: G21_1.5.1.C.2018
/*140扣除减值准备,即：
    14001 买入返售债券
    14002 买入返售贷款
    14003 买入返售票据
    14099 买入返售其他金融资产*/
    INSERT 
    INTO `G21_1.5.1.C.2018`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.5.1.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.5.1.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.5.1.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.5.1.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.5.1.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.5.1.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.5.1.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.5.1.A.2018'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.5.1.H.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG='03'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.5.1.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.5.1.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.5.1.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.5.1.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.5.1.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.5.1.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.5.1.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.5.1.A.2018'
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.5.1.H.2018'
                END;

/*140扣除减值准备,即：
    14001 买入返售债券
    14002 买入返售贷款
    14003 买入返售票据
    14099 买入返售其他金融资产*/
    INSERT 
    INTO `G21_1.5.1.C.2018`
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.5.1.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.5.1.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.5.1.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.5.1.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.5.1.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.5.1.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.5.1.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.5.1.A.2018'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.5.1.H.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG='03'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.5.1.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.5.1.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.5.1.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.5.1.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.5.1.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.5.1.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.5.1.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.5.1.A.2018'
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.5.1.H.2018'
                END;


