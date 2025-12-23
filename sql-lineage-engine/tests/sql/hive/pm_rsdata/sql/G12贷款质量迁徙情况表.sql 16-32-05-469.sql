-- ============================================================
-- 文件名: G12贷款质量迁徙情况表.sql
-- 生成时间: 2025-12-18 13:53:39
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: G12_3..E
--G12.3..E

    INSERT INTO `G12_3..E`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..E'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..E'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..E'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..E'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..E'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '3'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..E'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..E'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..E'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..E'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..E'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_3..E`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初正常类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_3..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN T2.LXQKQS >= 7 THEN
                'G12_3..G'
               WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_3..F'
               WHEN T2.LXQKQS = 4 THEN
                'G12_3..E'
               WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_3..D'
               ELSE
                'G12_3..C'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    0
                   ELSE
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP) - T.TRANAMT
                 END)
        FROM ( --年初为正常的贷款，本年还款金额与年初比大小，在根据期末五级分类状态划分五级分类
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
        LEFT JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T2.CARD_NO = T1.CARD_NO
         AND T2.ACCT_NUM = T1.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.LXQKQS <= 0 --年初是正常
       GROUP BY CASE
                  WHEN T2.LXQKQS >= 7 THEN
                   'G12_3..G'
                  WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_3..F'
                  WHEN T2.LXQKQS = 4 THEN
                   'G12_3..E'
                  WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_3..D'
                  ELSE
                   'G12_3..C'
                END;

--次级
    INSERT INTO `G12_3..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..E' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..E' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..E',
                          'G12_3..E',
                          'G12_4..E',
                          'G12_5..E',
                          'G12_6..E',
                          'G12_7..E')
       GROUP BY ORG_NUM;


-- 指标: G12_5..M
INSERT INTO `G12_5..M`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..M'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..M'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..M'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..M'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..M'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取不到，本月取
                              OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(S.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                             OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '4') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 and a.cancel_flg <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..M'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..M'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..M'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..M'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..M'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初次级，归还时在次级、可疑、损失
    INSERT INTO `G12_5..M`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_5..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_5..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_5..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS = 4 --年初关注，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_5..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_5..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_5..L'
                END;


-- 指标: G12_5..N
INSERT INTO `G12_5..N`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..N'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..N'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..N'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..N'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..N'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取不到，本月取
                             OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(s.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                                 OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT= (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '5') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 and a.cancel_flg <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..N'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..N'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..N'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..N'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..N'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初次级，归还时在次级、可疑、损失
    INSERT INTO `G12_5..N`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_5..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_5..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_5..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS = 4 --年初关注，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_5..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_5..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_5..L'
                END;


-- 指标: G12_2..F
--====================================================
    --   G12   2.本期增加,正常类贷款-损失类贷款
    --====================================================
    INSERT INTO `G12_2..F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN LOAN_GRADE_CD = '1' THEN
                        'G12_2..C'
                       WHEN LOAN_GRADE_CD = '2' THEN
                        'G12_2..D'
                       WHEN LOAN_GRADE_CD = '3' THEN
                        'G12_2..E'
                       WHEN LOAN_GRADE_CD = '4' THEN
                        'G12_2..F'
                       WHEN LOAN_GRADE_CD = '5' THEN
                        'G12_2..G'
                     END AS ITEM_NUM, --指标号
                     SUM(LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE (TO_CHAR(A.DRAWDOWN_DT, 'YYYY') =
                     SUBSTR(I_DATADATE, 1, 4) OR
                     (A.INTERNET_LOAN_FLG = 'Y' AND
                     A.DRAWDOWN_DT =
                     (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                     OR (A.cp_id IN  ('DK001000100041') AND A.DRAWDOWN_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                     )
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                    --AND ITEM_CD NOT LIKE '129%' --本指标2022年一月份打开  20211029  ZHOUJINGKUN
                    -- AND SUBSTR(ITEM_CD,1,4) NOT LIKE '1301%' --M2
                    --AND A.ITEM_CD NOT IN ('12902', '12906') --刨除票据转贴现  20220421 shiyu
                    -- AND SUBSTR(A.ITEM_CD,1,6) NOT IN('130102','130105')  --刨除票据转贴现 --M2
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND A.ORG_NUM <> '009803'
                 and a.cancel_flg <> 'Y'
                 AND A.DATA_DATE = I_DATADATE --LRT 20180111
                 and A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_2..C'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_2..D'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_2..E'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_2..F'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_2..G'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--可疑
    INSERT INTO `G12_2..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..F' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..F' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..F',
                          'G12_3..F',
                          'G12_4..F',
                          'G12_5..F',
                          'G12_6..F',
                          'G12_7..F')
       GROUP BY ORG_NUM;


-- 指标: G12_5..G
--G12.3..G

    INSERT INTO `G12_5..G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..G'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..G'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..G'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..G'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..G'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '5'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..G'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..G'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..G'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..G'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..G'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_5..G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初次级类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_5..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_5..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_5..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_5..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_5..D'
               ELSE
                'G12_5..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)
        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS = 4 --年初是次级
       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_5..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_5..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_5..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_5..D'
                  ELSE
                   'G12_5..C'
                END;

--损失

    INSERT INTO `G12_5..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..G' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..G' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..G',
                          'G12_3..G',
                          'G12_4..G',
                          'G12_5..G',
                          'G12_6..G',
                          'G12_7..G')
       GROUP BY ORG_NUM;

------------------------------------
    ---本期减少  次级类  可疑类  损失
    -------------------------------------

    INSERT INTO `G12_5..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_5..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_5..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_5..A',
                          'G12_5..C',
                          'G12_5..D',
                          'G12_5..E',
                          'G12_5..F',
                          'G12_5..G')
       GROUP BY ORG_NUM;


-- 指标: G12_2..D
--====================================================
    --   G12   2.本期增加,正常类贷款-损失类贷款
    --====================================================
    INSERT INTO `G12_2..D`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN LOAN_GRADE_CD = '1' THEN
                        'G12_2..C'
                       WHEN LOAN_GRADE_CD = '2' THEN
                        'G12_2..D'
                       WHEN LOAN_GRADE_CD = '3' THEN
                        'G12_2..E'
                       WHEN LOAN_GRADE_CD = '4' THEN
                        'G12_2..F'
                       WHEN LOAN_GRADE_CD = '5' THEN
                        'G12_2..G'
                     END AS ITEM_NUM, --指标号
                     SUM(LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE (TO_CHAR(A.DRAWDOWN_DT, 'YYYY') =
                     SUBSTR(I_DATADATE, 1, 4) OR
                     (A.INTERNET_LOAN_FLG = 'Y' AND
                     A.DRAWDOWN_DT =
                     (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                     OR (A.cp_id IN  ('DK001000100041') AND A.DRAWDOWN_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                     )
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                    --AND ITEM_CD NOT LIKE '129%' --本指标2022年一月份打开  20211029  ZHOUJINGKUN
                    -- AND SUBSTR(ITEM_CD,1,4) NOT LIKE '1301%' --M2
                    --AND A.ITEM_CD NOT IN ('12902', '12906') --刨除票据转贴现  20220421 shiyu
                    -- AND SUBSTR(A.ITEM_CD,1,6) NOT IN('130102','130105')  --刨除票据转贴现 --M2
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND A.ORG_NUM <> '009803'
                 and a.cancel_flg <> 'Y'
                 AND A.DATA_DATE = I_DATADATE --LRT 20180111
                 and A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_2..C'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_2..D'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_2..E'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_2..F'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_2..G'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--关注
    INSERT INTO `G12_2..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..D' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..D' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..D',
                          'G12_3..D',
                          'G12_4..D',
                          'G12_5..D',
                          'G12_6..D',
                          'G12_7..D')
       GROUP BY ORG_NUM;


-- 指标: G12_3..B
--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_3..B`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

-----------------------
    ---本期减少  正常类  关注类
    -----------------------
    INSERT INTO `G12_3..B`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             'G12_3..B' AS ITEM_NUM,
             NVL(SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP)
                   ELSE
                    T.TRANAMT

                 END),0)
        FROM ( --期初余额-本年还款 <= 0 取期初余额，如果 >0 取还款金额
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
         and t1.LXQKQS <= 0 --年初为正常类;


-- 指标: G12_3..L
--====================================================
    --   G12   本年不良贷款处置情况,次级-损失
    --====================================================
    --修改 LRT 20180115
    INSERT INTO `G12_3..L`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..L'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..L'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..L'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..L'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..L'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                              OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(s.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                               OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '3') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND A.CANCEL_FLG <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..L'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..L'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..L'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..L'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..L'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初正常，归还时在次级、可疑、损失
    INSERT INTO `G12_3..L`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_3..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_3..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_3..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS <= 0 --年初正常，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_3..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_3..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_3..L'
                END;


-- 指标: G12_4..N
INSERT INTO `G12_4..N`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..N'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..N'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..N'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..N'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..N'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取不到，本月取
                             OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(s.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                                 OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT= (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '5') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 and a.cancel_flg <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..N'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..N'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..N'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..N'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..N'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初关注，归还时在次级、可疑、损失
    INSERT INTO `G12_4..N`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_4..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_4..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_4..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS between 1 and 3 --年初关注，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_4..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_4..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_4..L'
                END;


-- 指标: G12_2..G
--====================================================
    --   G12   2.本期增加,正常类贷款-损失类贷款
    --====================================================
    INSERT INTO `G12_2..G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN LOAN_GRADE_CD = '1' THEN
                        'G12_2..C'
                       WHEN LOAN_GRADE_CD = '2' THEN
                        'G12_2..D'
                       WHEN LOAN_GRADE_CD = '3' THEN
                        'G12_2..E'
                       WHEN LOAN_GRADE_CD = '4' THEN
                        'G12_2..F'
                       WHEN LOAN_GRADE_CD = '5' THEN
                        'G12_2..G'
                     END AS ITEM_NUM, --指标号
                     SUM(LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE (TO_CHAR(A.DRAWDOWN_DT, 'YYYY') =
                     SUBSTR(I_DATADATE, 1, 4) OR
                     (A.INTERNET_LOAN_FLG = 'Y' AND
                     A.DRAWDOWN_DT =
                     (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                     OR (A.cp_id IN  ('DK001000100041') AND A.DRAWDOWN_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                     )
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                    --AND ITEM_CD NOT LIKE '129%' --本指标2022年一月份打开  20211029  ZHOUJINGKUN
                    -- AND SUBSTR(ITEM_CD,1,4) NOT LIKE '1301%' --M2
                    --AND A.ITEM_CD NOT IN ('12902', '12906') --刨除票据转贴现  20220421 shiyu
                    -- AND SUBSTR(A.ITEM_CD,1,6) NOT IN('130102','130105')  --刨除票据转贴现 --M2
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND A.ORG_NUM <> '009803'
                 and a.cancel_flg <> 'Y'
                 AND A.DATA_DATE = I_DATADATE --LRT 20180111
                 and A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_2..C'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_2..D'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_2..E'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_2..F'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_2..G'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--损失

    INSERT INTO `G12_2..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..G' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..G' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..G',
                          'G12_3..G',
                          'G12_4..G',
                          'G12_5..G',
                          'G12_6..G',
                          'G12_7..G')
       GROUP BY ORG_NUM;


-- ========== 逻辑组 10: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             CASE
               WHEN FLAG_TMP = '3' THEN
                'G12_2..L'
               WHEN FLAG_TMP = '4' THEN
                'G12_2..M'
               WHEN FLAG_TMP = '5' THEN
                'G12_2..N'
             END AS ITEM_NUM, --指标号
             SUM(NVL(BALANCE_UP, 0) + NVL(BALANCE_DOWN, 0)) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM CBRC_PUB_DATA_G12
       WHERE FLAG_TMP IN ('3', '4', '5')
       GROUP BY ORG_NUM,
                CASE
                  WHEN FLAG_TMP = '3' THEN
                   'G12_2..L'
                  WHEN FLAG_TMP = '4' THEN
                   'G12_2..M'
                  WHEN FLAG_TMP = '5' THEN
                   'G12_2..N'
                END;

------------------------------
    -- 本年不良贷款处置情况
    -----------------------------

    --本期增加
    --年初为正常或关注,期末时点为不良贷款，归还时在次级、可疑、损失
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT  '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_2..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_2..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_2..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT  T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
         and t1.LXQKQS <= 3 ----年初为正常或关注,期末时点为不良贷款，归还时在次级、可疑、损失
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T.CARD_NO = T2.CARD_NO
         AND T.ACCT_NUM = T2.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
         and t2.LXQKQS >= 4
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_2..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_2..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_2..L'
                END
) q_10
INSERT INTO `G12_2..L` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_2..M` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_2..N` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- 指标: G12_6..D
--G12.3..D

    INSERT INTO `G12_6..D`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..D'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..D'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..D'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..D'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..D'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '2'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..D'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..D'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..D'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..D'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..D'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_6..D`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    --年初可疑类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_6..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_6..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_6..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_6..D'
               ELSE
                'G12_6..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)

        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS BETWEEN 5 AND 6 --年初是可疑类贷款
       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_6..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_6..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_6..D'
                  ELSE
                   'G12_6..C'
                END;

--关注
    INSERT INTO `G12_6..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..D' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..D' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..D',
                          'G12_3..D',
                          'G12_4..D',
                          'G12_5..D',
                          'G12_6..D',
                          'G12_7..D')
       GROUP BY ORG_NUM;

INSERT INTO `G12_6..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_6..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_6..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_6..A',
                          'G12_6..C',
                          'G12_6..D',
                          'G12_6..E',
                          'G12_6..F',
                          'G12_6..G')
       GROUP BY ORG_NUM;


-- 指标: G12_6..E
--G12.3..E

    INSERT INTO `G12_6..E`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..E'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..E'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..E'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..E'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..E'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '3'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..E'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..E'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..E'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..E'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..E'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_6..E`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    --年初可疑类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_6..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_6..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_6..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_6..D'
               ELSE
                'G12_6..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)

        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS BETWEEN 5 AND 6 --年初是可疑类贷款
       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_6..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_6..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_6..D'
                  ELSE
                   'G12_6..C'
                END;

--次级
    INSERT INTO `G12_6..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..E' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..E' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..E',
                          'G12_3..E',
                          'G12_4..E',
                          'G12_5..E',
                          'G12_6..E',
                          'G12_7..E')
       GROUP BY ORG_NUM;

INSERT INTO `G12_6..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_6..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_6..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_6..A',
                          'G12_6..C',
                          'G12_6..D',
                          'G12_6..E',
                          'G12_6..F',
                          'G12_6..G')
       GROUP BY ORG_NUM;


-- 指标: G12_7..G
--G12.3..G

    INSERT INTO `G12_7..G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..G'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..G'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..G'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..G'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..G'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '5'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..G'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..G'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..G'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..G'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..G'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_7..G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    --年初损失类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_7..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_7..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_7..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_7..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_7..D'
               ELSE
                'G12_7..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)

        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS >= 7 --年初是损失类贷款

       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_7..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_7..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_7..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_7..D'
                  ELSE
                   'G12_7..C'
                END;

--损失

    INSERT INTO `G12_7..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..G' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..G' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..G',
                          'G12_3..G',
                          'G12_4..G',
                          'G12_5..G',
                          'G12_6..G',
                          'G12_7..G')
       GROUP BY ORG_NUM;

INSERT INTO `G12_7..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_7..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_7..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_7..A',
                          'G12_7..C',
                          'G12_7..D',
                          'G12_7..E',
                          'G12_7..F',
                          'G12_7..G')
       GROUP BY ORG_NUM;


-- 指标: G12_5..D
--G12.3..D

    INSERT INTO `G12_5..D`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..D'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..D'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..D'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..D'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..D'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '2'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..D'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..D'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..D'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..D'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..D'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_5..D`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初次级类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_5..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_5..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_5..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_5..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_5..D'
               ELSE
                'G12_5..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)
        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS = 4 --年初是次级
       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_5..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_5..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_5..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_5..D'
                  ELSE
                   'G12_5..C'
                END;

--关注
    INSERT INTO `G12_5..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..D' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..D' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..D',
                          'G12_3..D',
                          'G12_4..D',
                          'G12_5..D',
                          'G12_6..D',
                          'G12_7..D')
       GROUP BY ORG_NUM;

------------------------------------
    ---本期减少  次级类  可疑类  损失
    -------------------------------------

    INSERT INTO `G12_5..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_5..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_5..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_5..A',
                          'G12_5..C',
                          'G12_5..D',
                          'G12_5..E',
                          'G12_5..F',
                          'G12_5..G')
       GROUP BY ORG_NUM;


-- 指标: G12_7..N
INSERT INTO `G12_7..N`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..N'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..N'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..N'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..N'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..N'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取不到，本月取
                             OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(s.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                                 OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT= (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '5') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 and a.cancel_flg <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..N'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..N'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..N'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..N'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..N'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初损失，归还时在次级、可疑、损失

    INSERT INTO `G12_7..N`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_7..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_7..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_7..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS >= 7 --年初损失，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_7..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_7..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_7..L'
                END;


-- 指标: G12_6..M
INSERT INTO `G12_6..M`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..M'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..M'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..M'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..M'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..M'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取不到，本月取
                              OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(S.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                             OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '4') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 and a.cancel_flg <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..M'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..M'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..M'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..M'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..M'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初可疑，归还时在次级、可疑、损失

    INSERT INTO `G12_6..M`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_6..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_6..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS BETWEEN 5 AND 6 --年初可疑，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_6..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_6..L'
                END;


-- 指标: G12_3..G
--G12.3..G

    INSERT INTO `G12_3..G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..G'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..G'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..G'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..G'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..G'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '5'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..G'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..G'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..G'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..G'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..G'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_3..G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初正常类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_3..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN T2.LXQKQS >= 7 THEN
                'G12_3..G'
               WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_3..F'
               WHEN T2.LXQKQS = 4 THEN
                'G12_3..E'
               WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_3..D'
               ELSE
                'G12_3..C'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    0
                   ELSE
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP) - T.TRANAMT
                 END)
        FROM ( --年初为正常的贷款，本年还款金额与年初比大小，在根据期末五级分类状态划分五级分类
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
        LEFT JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T2.CARD_NO = T1.CARD_NO
         AND T2.ACCT_NUM = T1.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.LXQKQS <= 0 --年初是正常
       GROUP BY CASE
                  WHEN T2.LXQKQS >= 7 THEN
                   'G12_3..G'
                  WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_3..F'
                  WHEN T2.LXQKQS = 4 THEN
                   'G12_3..E'
                  WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_3..D'
                  ELSE
                   'G12_3..C'
                END;

--损失

    INSERT INTO `G12_3..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..G' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..G' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..G',
                          'G12_3..G',
                          'G12_4..G',
                          'G12_5..G',
                          'G12_6..G',
                          'G12_7..G')
       GROUP BY ORG_NUM;


-- 指标: G12_2..E
--====================================================
    --   G12   2.本期增加,正常类贷款-损失类贷款
    --====================================================
    INSERT INTO `G12_2..E`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN LOAN_GRADE_CD = '1' THEN
                        'G12_2..C'
                       WHEN LOAN_GRADE_CD = '2' THEN
                        'G12_2..D'
                       WHEN LOAN_GRADE_CD = '3' THEN
                        'G12_2..E'
                       WHEN LOAN_GRADE_CD = '4' THEN
                        'G12_2..F'
                       WHEN LOAN_GRADE_CD = '5' THEN
                        'G12_2..G'
                     END AS ITEM_NUM, --指标号
                     SUM(LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE (TO_CHAR(A.DRAWDOWN_DT, 'YYYY') =
                     SUBSTR(I_DATADATE, 1, 4) OR
                     (A.INTERNET_LOAN_FLG = 'Y' AND
                     A.DRAWDOWN_DT =
                     (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                     OR (A.cp_id IN  ('DK001000100041') AND A.DRAWDOWN_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                     )
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                    --AND ITEM_CD NOT LIKE '129%' --本指标2022年一月份打开  20211029  ZHOUJINGKUN
                    -- AND SUBSTR(ITEM_CD,1,4) NOT LIKE '1301%' --M2
                    --AND A.ITEM_CD NOT IN ('12902', '12906') --刨除票据转贴现  20220421 shiyu
                    -- AND SUBSTR(A.ITEM_CD,1,6) NOT IN('130102','130105')  --刨除票据转贴现 --M2
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND A.ORG_NUM <> '009803'
                 and a.cancel_flg <> 'Y'
                 AND A.DATA_DATE = I_DATADATE --LRT 20180111
                 and A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_2..C'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_2..D'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_2..E'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_2..F'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_2..G'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--次级
    INSERT INTO `G12_2..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..E' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..E' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..E',
                          'G12_3..E',
                          'G12_4..E',
                          'G12_5..E',
                          'G12_6..E',
                          'G12_7..E')
       GROUP BY ORG_NUM;


-- 指标: G12_3..F
--G12.3..F

    INSERT INTO `G12_3..F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..F'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..F'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..F'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..F'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..F'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '4'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..F'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..F'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..F'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..F'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..F'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_3..F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初正常类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_3..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN T2.LXQKQS >= 7 THEN
                'G12_3..G'
               WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_3..F'
               WHEN T2.LXQKQS = 4 THEN
                'G12_3..E'
               WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_3..D'
               ELSE
                'G12_3..C'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    0
                   ELSE
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP) - T.TRANAMT
                 END)
        FROM ( --年初为正常的贷款，本年还款金额与年初比大小，在根据期末五级分类状态划分五级分类
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
        LEFT JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T2.CARD_NO = T1.CARD_NO
         AND T2.ACCT_NUM = T1.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.LXQKQS <= 0 --年初是正常
       GROUP BY CASE
                  WHEN T2.LXQKQS >= 7 THEN
                   'G12_3..G'
                  WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_3..F'
                  WHEN T2.LXQKQS = 4 THEN
                   'G12_3..E'
                  WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_3..D'
                  ELSE
                   'G12_3..C'
                END;

--可疑
    INSERT INTO `G12_3..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..F' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..F' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..F',
                          'G12_3..F',
                          'G12_4..F',
                          'G12_5..F',
                          'G12_6..F',
                          'G12_7..F')
       GROUP BY ORG_NUM;


-- 指标: G12_7..F
--G12.3..F

    INSERT INTO `G12_7..F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..F'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..F'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..F'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..F'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..F'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '4'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..F'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..F'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..F'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..F'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..F'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_7..F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    --年初损失类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_7..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_7..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_7..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_7..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_7..D'
               ELSE
                'G12_7..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)

        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS >= 7 --年初是损失类贷款

       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_7..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_7..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_7..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_7..D'
                  ELSE
                   'G12_7..C'
                END;

--可疑
    INSERT INTO `G12_7..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..F' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..F' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..F',
                          'G12_3..F',
                          'G12_4..F',
                          'G12_5..F',
                          'G12_6..F',
                          'G12_7..F')
       GROUP BY ORG_NUM;

INSERT INTO `G12_7..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_7..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_7..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_7..A',
                          'G12_7..C',
                          'G12_7..D',
                          'G12_7..E',
                          'G12_7..F',
                          'G12_7..G')
       GROUP BY ORG_NUM;


-- 指标: G12_7..C
--====================================================
    --   G12 本期减少,本年不良贷款处置情况，正常-损失
    --====================================================
    

    --G12.3..C
    INSERT INTO `G12_7..C`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..C'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..C'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..C'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..C'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..C'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND A.ACCT_TYP NOT LIKE 'E%'
                 AND B.LOAN_GRADE_CD = '1'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 and a.cancel_flg <> 'Y'
                 AND A.ORG_NUM <> '009803'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..C'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..C'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..C'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..C'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..C'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_7..C`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    --年初损失类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_7..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_7..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_7..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_7..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_7..D'
               ELSE
                'G12_7..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)

        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS >= 7 --年初是损失类贷款

       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_7..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_7..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_7..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_7..D'
                  ELSE
                   'G12_7..C'
                END;

--正常
    INSERT INTO `G12_7..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..C' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..C' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..C',
                          'G12_3..C',
                          'G12_4..C',
                          'G12_5..C',
                          'G12_6..C',
                          'G12_7..C')
       GROUP BY ORG_NUM;

INSERT INTO `G12_7..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_7..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_7..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_7..A',
                          'G12_7..C',
                          'G12_7..D',
                          'G12_7..E',
                          'G12_7..F',
                          'G12_7..G')
       GROUP BY ORG_NUM;


-- 指标: G12_7..L
--====================================================
    --   G12   本年不良贷款处置情况,次级-损失
    --====================================================
    --修改 LRT 20180115
    INSERT INTO `G12_7..L`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..L'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..L'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..L'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..L'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..L'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                              OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(s.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                               OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '3') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND A.CANCEL_FLG <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..L'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..L'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..L'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..L'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..L'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初损失，归还时在次级、可疑、损失

    INSERT INTO `G12_7..L`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_7..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_7..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_7..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS >= 7 --年初损失，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_7..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_7..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_7..L'
                END;


-- 指标: G12_14..B
-------------------------------------------
    ----14.不良贷款对外转让总额
    ---------------------------------------
    INSERT INTO `G12_14..B`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             'G12_14..B' AS ITEM_NUM,
             SUM(T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP)
        from SMTMODS_L_ACCT_CARD_CREDIT t
       where t.data_date = I_DATADATE
         and DEALDATE <> '00000000';


-- 指标: G12_10.1.A
--------------------------------
    ----10.1 转为正常后归还
    --------------------------------
    INSERT INTO `G12_10.1.A`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             'G12_10.1.A' AS ITEM_NUM,
             SUM(NVL(T.TRANAMT, 0))

        FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS >= 4 --年初为5.次级类贷款、6.可疑类贷款7.损失类贷款，归还时在正常或关注
       WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
             I_DATADATE
         AND T.TRANTYPE IN ('11', '12') --交易类型为还款
         and t.lxqkqs <= 3
       GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD;


-- 指标: G12_6..B
--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_6..B`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

INSERT INTO `G12_6..B`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_6..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_6..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_6..A',
                          'G12_6..C',
                          'G12_6..D',
                          'G12_6..E',
                          'G12_6..F',
                          'G12_6..G')
       GROUP BY ORG_NUM;


-- 指标: G12_3..M
INSERT INTO `G12_3..M`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..M'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..M'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..M'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..M'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..M'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取不到，本月取
                              OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(S.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                             OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '4') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 and a.cancel_flg <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..M'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..M'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..M'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..M'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..M'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初正常，归还时在次级、可疑、损失
    INSERT INTO `G12_3..M`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_3..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_3..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_3..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS <= 0 --年初正常，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_3..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_3..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_3..L'
                END;


-- 指标: G12_7..E
--G12.3..E

    INSERT INTO `G12_7..E`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..E'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..E'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..E'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..E'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..E'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '3'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..E'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..E'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..E'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..E'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..E'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_7..E`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    --年初损失类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_7..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_7..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_7..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_7..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_7..D'
               ELSE
                'G12_7..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)

        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS >= 7 --年初是损失类贷款

       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_7..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_7..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_7..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_7..D'
                  ELSE
                   'G12_7..C'
                END;

--次级
    INSERT INTO `G12_7..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..E' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..E' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..E',
                          'G12_3..E',
                          'G12_4..E',
                          'G12_5..E',
                          'G12_6..E',
                          'G12_7..E')
       GROUP BY ORG_NUM;

INSERT INTO `G12_7..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_7..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_7..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_7..A',
                          'G12_7..C',
                          'G12_7..D',
                          'G12_7..E',
                          'G12_7..F',
                          'G12_7..G')
       GROUP BY ORG_NUM;


-- 指标: G12_7..M
INSERT INTO `G12_7..M`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..M'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..M'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..M'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..M'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..M'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取不到，本月取
                              OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(S.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                             OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '4') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 and a.cancel_flg <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..M'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..M'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..M'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..M'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..M'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初损失，归还时在次级、可疑、损失

    INSERT INTO `G12_7..M`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_7..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_7..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_7..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS >= 7 --年初损失，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_7..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_7..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_7..L'
                END;


-- 指标: G12_4..G
--G12.3..G

    INSERT INTO `G12_4..G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..G'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..G'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..G'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..G'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..G'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '5'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..G'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..G'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..G'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..G'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..G'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_4..G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初关注类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_4..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN T2.LXQKQS >= 7 THEN
                'G12_4..G'
               WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_4..F'
               WHEN T2.LXQKQS = 4 THEN
                'G12_4..E'
               WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_4..D'
               ELSE
                'G12_4..C'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    0
                   ELSE
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP) - T.TRANAMT
                 END)
        FROM ( --年初为正常的贷款，本年还款金额与年初比大小，在根据期末五级分类状态划分五级分类
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
        LEFT JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T2.CARD_NO = T1.CARD_NO
         AND T2.ACCT_NUM = T1.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.LXQKQS BETWEEN 1 AND 3 --年初是关注
       GROUP BY CASE
                  WHEN T2.LXQKQS >= 7 THEN
                   'G12_4..G'
                  WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_4..F'
                  WHEN T2.LXQKQS = 4 THEN
                   'G12_4..E'
                  WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_4..D'
                  ELSE
                   'G12_4..C'
                END;

--损失

    INSERT INTO `G12_4..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..G' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..G' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..G',
                          'G12_3..G',
                          'G12_4..G',
                          'G12_5..G',
                          'G12_6..G',
                          'G12_7..G')
       GROUP BY ORG_NUM;


-- 指标: G12_6..L
--====================================================
    --   G12   本年不良贷款处置情况,次级-损失
    --====================================================
    --修改 LRT 20180115
    INSERT INTO `G12_6..L`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..L'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..L'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..L'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..L'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..L'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                              OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(s.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                               OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '3') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND A.CANCEL_FLG <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..L'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..L'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..L'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..L'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..L'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初可疑，归还时在次级、可疑、损失

    INSERT INTO `G12_6..L`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_6..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_6..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS BETWEEN 5 AND 6 --年初可疑，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_6..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_6..L'
                END;


-- 指标: G12_3..C
--====================================================
    --   G12 本期减少,本年不良贷款处置情况，正常-损失
    --====================================================
    

    --G12.3..C
    INSERT INTO `G12_3..C`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..C'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..C'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..C'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..C'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..C'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND A.ACCT_TYP NOT LIKE 'E%'
                 AND B.LOAN_GRADE_CD = '1'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 and a.cancel_flg <> 'Y'
                 AND A.ORG_NUM <> '009803'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..C'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..C'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..C'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..C'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..C'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_3..C`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初正常类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_3..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN T2.LXQKQS >= 7 THEN
                'G12_3..G'
               WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_3..F'
               WHEN T2.LXQKQS = 4 THEN
                'G12_3..E'
               WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_3..D'
               ELSE
                'G12_3..C'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    0
                   ELSE
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP) - T.TRANAMT
                 END)
        FROM ( --年初为正常的贷款，本年还款金额与年初比大小，在根据期末五级分类状态划分五级分类
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
        LEFT JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T2.CARD_NO = T1.CARD_NO
         AND T2.ACCT_NUM = T1.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.LXQKQS <= 0 --年初是正常
       GROUP BY CASE
                  WHEN T2.LXQKQS >= 7 THEN
                   'G12_3..G'
                  WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_3..F'
                  WHEN T2.LXQKQS = 4 THEN
                   'G12_3..E'
                  WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_3..D'
                  ELSE
                   'G12_3..C'
                END;

--正常
    INSERT INTO `G12_3..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..C' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..C' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..C',
                          'G12_3..C',
                          'G12_4..C',
                          'G12_5..C',
                          'G12_6..C',
                          'G12_7..C')
       GROUP BY ORG_NUM;


-- 指标: G12_6..G
--G12.3..G

    INSERT INTO `G12_6..G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..G'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..G'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..G'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..G'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..G'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '5'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..G'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..G'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..G'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..G'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..G'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_6..G`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    --年初可疑类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_6..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_6..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_6..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_6..D'
               ELSE
                'G12_6..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)

        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS BETWEEN 5 AND 6 --年初是可疑类贷款
       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_6..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_6..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_6..D'
                  ELSE
                   'G12_6..C'
                END;

--损失

    INSERT INTO `G12_6..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..G' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..G' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..G',
                          'G12_3..G',
                          'G12_4..G',
                          'G12_5..G',
                          'G12_6..G',
                          'G12_7..G')
       GROUP BY ORG_NUM;

INSERT INTO `G12_6..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_6..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_6..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_6..A',
                          'G12_6..C',
                          'G12_6..D',
                          'G12_6..E',
                          'G12_6..F',
                          'G12_6..G')
       GROUP BY ORG_NUM;


-- 指标: G12_6..C
--====================================================
    --   G12 本期减少,本年不良贷款处置情况，正常-损失
    --====================================================
    

    --G12.3..C
    INSERT INTO `G12_6..C`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..C'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..C'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..C'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..C'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..C'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND A.ACCT_TYP NOT LIKE 'E%'
                 AND B.LOAN_GRADE_CD = '1'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 and a.cancel_flg <> 'Y'
                 AND A.ORG_NUM <> '009803'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..C'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..C'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..C'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..C'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..C'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_6..C`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    --年初可疑类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_6..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_6..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_6..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_6..D'
               ELSE
                'G12_6..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)

        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS BETWEEN 5 AND 6 --年初是可疑类贷款
       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_6..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_6..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_6..D'
                  ELSE
                   'G12_6..C'
                END;

--正常
    INSERT INTO `G12_6..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..C' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..C' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..C',
                          'G12_3..C',
                          'G12_4..C',
                          'G12_5..C',
                          'G12_6..C',
                          'G12_7..C')
       GROUP BY ORG_NUM;

INSERT INTO `G12_6..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_6..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_6..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_6..A',
                          'G12_6..C',
                          'G12_6..D',
                          'G12_6..E',
                          'G12_6..F',
                          'G12_6..G')
       GROUP BY ORG_NUM;


-- 指标: G12_4..C
--====================================================
    --   G12 本期减少,本年不良贷款处置情况，正常-损失
    --====================================================
    

    --G12.3..C
    INSERT INTO `G12_4..C`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..C'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..C'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..C'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..C'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..C'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND A.ACCT_TYP NOT LIKE 'E%'
                 AND B.LOAN_GRADE_CD = '1'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 and a.cancel_flg <> 'Y'
                 AND A.ORG_NUM <> '009803'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..C'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..C'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..C'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..C'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..C'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_4..C`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初关注类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_4..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN T2.LXQKQS >= 7 THEN
                'G12_4..G'
               WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_4..F'
               WHEN T2.LXQKQS = 4 THEN
                'G12_4..E'
               WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_4..D'
               ELSE
                'G12_4..C'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    0
                   ELSE
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP) - T.TRANAMT
                 END)
        FROM ( --年初为正常的贷款，本年还款金额与年初比大小，在根据期末五级分类状态划分五级分类
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
        LEFT JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T2.CARD_NO = T1.CARD_NO
         AND T2.ACCT_NUM = T1.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.LXQKQS BETWEEN 1 AND 3 --年初是关注
       GROUP BY CASE
                  WHEN T2.LXQKQS >= 7 THEN
                   'G12_4..G'
                  WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_4..F'
                  WHEN T2.LXQKQS = 4 THEN
                   'G12_4..E'
                  WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_4..D'
                  ELSE
                   'G12_4..C'
                END;

--正常
    INSERT INTO `G12_4..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..C' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..C' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..C',
                          'G12_3..C',
                          'G12_4..C',
                          'G12_5..C',
                          'G12_6..C',
                          'G12_7..C')
       GROUP BY ORG_NUM;


-- 指标: G12_6..F
--G12.3..F

    INSERT INTO `G12_6..F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..F'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..F'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..F'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..F'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..F'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '4'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..F'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..F'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..F'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..F'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..F'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_6..F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    --年初可疑类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_6..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_6..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_6..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_6..D'
               ELSE
                'G12_6..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)

        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS BETWEEN 5 AND 6 --年初是可疑类贷款
       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_6..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_6..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_6..D'
                  ELSE
                   'G12_6..C'
                END;

--可疑
    INSERT INTO `G12_6..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..F' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..F' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..F',
                          'G12_3..F',
                          'G12_4..F',
                          'G12_5..F',
                          'G12_6..F',
                          'G12_7..F')
       GROUP BY ORG_NUM;

INSERT INTO `G12_6..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_6..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_6..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_6..A',
                          'G12_6..C',
                          'G12_6..D',
                          'G12_6..E',
                          'G12_6..F',
                          'G12_6..G')
       GROUP BY ORG_NUM;


-- 指标: G12_6..N
INSERT INTO `G12_6..N`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..N'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..N'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..N'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..N'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..N'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取不到，本月取
                             OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(s.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                                 OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT= (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '5') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 and a.cancel_flg <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..N'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..N'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..N'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..N'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..N'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初可疑，归还时在次级、可疑、损失

    INSERT INTO `G12_6..N`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_6..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_6..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS BETWEEN 5 AND 6 --年初可疑，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_6..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_6..L'
                END;


-- 指标: G12_5..C
--====================================================
    --   G12 本期减少,本年不良贷款处置情况，正常-损失
    --====================================================
    

    --G12.3..C
    INSERT INTO `G12_5..C`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..C'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..C'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..C'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..C'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..C'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND A.ACCT_TYP NOT LIKE 'E%'
                 AND B.LOAN_GRADE_CD = '1'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 and a.cancel_flg <> 'Y'
                 AND A.ORG_NUM <> '009803'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..C'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..C'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..C'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..C'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..C'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_5..C`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初次级类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_5..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_5..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_5..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_5..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_5..D'
               ELSE
                'G12_5..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)
        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS = 4 --年初是次级
       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_5..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_5..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_5..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_5..D'
                  ELSE
                   'G12_5..C'
                END;

--正常
    INSERT INTO `G12_5..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..C' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..C' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..C',
                          'G12_3..C',
                          'G12_4..C',
                          'G12_5..C',
                          'G12_6..C',
                          'G12_7..C')
       GROUP BY ORG_NUM;

------------------------------------
    ---本期减少  次级类  可疑类  损失
    -------------------------------------

    INSERT INTO `G12_5..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_5..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_5..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_5..A',
                          'G12_5..C',
                          'G12_5..D',
                          'G12_5..E',
                          'G12_5..F',
                          'G12_5..G')
       GROUP BY ORG_NUM;


-- 指标: G12_2..B
V_STEP_DESC := 'G12_2..B';

INSERT INTO `G12_2..B`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )

      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             'G12_2..B' AS ITEM_NUM, --指标号
             SUM(NVL(BALANCE_UP, 0) + NVL(BALANCE_4, 0) + NVL(BALANCE_5, 0)) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM CBRC_PUB_DATA_G12
       GROUP BY ORG_NUM;

-------------------
    --本期增加
    --------------------
    INSERT INTO `G12_2..B`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
       'G12_2..B' AS ITEM_NUM,
       NVL(SUM(CASE
                 WHEN T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                          T1.M6_UP
                           - NVL(T.TRANAMT, 0) >= 0 THEN
                  0
                 ELSE
                  NVL(T.TRANAMT, 0) - T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 +
                                          T1.M5 + T1.M6 + T1.M6_UP

               END
              ),0) ITEM_VAL
  FROM ( --期初余额-本年还款>0取0，否则  期初余额-本年还款 <0 取期初余额-本年还款 差值
        SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(NVL(TRANAMT, 0)) TRANAMT
          FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
         WHERE T.DATA_DATE BETWEEN SUBSTR('20250131', 1, 4) || '0101' AND
               '20250131'
           AND T.TRANTYPE IN ('11', '12') --交易类型为还款
         GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
 INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
    ON T.CARD_NO = T1.CARD_NO
   AND T.ACCT_NUM = T1.ACCT_NUM
   AND T1.DATA_DATE = I_LAST_YEAR;


-- 指标: G12_4..M
INSERT INTO `G12_4..M`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..M'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..M'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..M'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..M'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..M'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取不到，本月取
                              OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(S.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                             OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '4') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 and a.cancel_flg <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..M'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..M'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..M'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..M'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..M'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初关注，归还时在次级、可疑、损失
    INSERT INTO `G12_4..M`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_4..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_4..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_4..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS between 1 and 3 --年初关注，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_4..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_4..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_4..L'
                END;


-- 指标: G12_4..D
--G12.3..D

    INSERT INTO `G12_4..D`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..D'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..D'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..D'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..D'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..D'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '2'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..D'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..D'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..D'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..D'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..D'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_4..D`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初关注类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_4..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN T2.LXQKQS >= 7 THEN
                'G12_4..G'
               WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_4..F'
               WHEN T2.LXQKQS = 4 THEN
                'G12_4..E'
               WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_4..D'
               ELSE
                'G12_4..C'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    0
                   ELSE
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP) - T.TRANAMT
                 END)
        FROM ( --年初为正常的贷款，本年还款金额与年初比大小，在根据期末五级分类状态划分五级分类
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
        LEFT JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T2.CARD_NO = T1.CARD_NO
         AND T2.ACCT_NUM = T1.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.LXQKQS BETWEEN 1 AND 3 --年初是关注
       GROUP BY CASE
                  WHEN T2.LXQKQS >= 7 THEN
                   'G12_4..G'
                  WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_4..F'
                  WHEN T2.LXQKQS = 4 THEN
                   'G12_4..E'
                  WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_4..D'
                  ELSE
                   'G12_4..C'
                END;

--关注
    INSERT INTO `G12_4..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..D' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..D' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..D',
                          'G12_3..D',
                          'G12_4..D',
                          'G12_5..D',
                          'G12_6..D',
                          'G12_7..D')
       GROUP BY ORG_NUM;


-- 指标: G12_3..N
INSERT INTO `G12_3..N`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..N'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..N'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..N'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..N'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..N'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'MM') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，上月末数据当月取不到，本月取
                             OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(s.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                                 OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT= (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '5') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 and a.cancel_flg <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..N'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..N'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..N'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..N'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..N'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初正常，归还时在次级、可疑、损失
    INSERT INTO `G12_3..N`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_3..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_3..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_3..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS <= 0 --年初正常，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_3..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_3..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_3..L'
                END;


-- 指标: G12_4..B
--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_4..B`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

INSERT INTO `G12_4..B`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             'G12_4..B' AS ITEM_NUM,
             NVL(SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP)
                   ELSE
                    T.TRANAMT

                 END),0)
        FROM ( --期初余额-本年还款 <= 0 取期初余额，如果 >0 取还款金额
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
         and t1.LXQKQS BETWEEN 1 AND 3 --年初为关注类;


-- 指标: G12_5..E
--G12.3..E

    INSERT INTO `G12_5..E`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..E'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..E'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..E'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..E'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..E'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '3'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..E'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..E'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..E'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..E'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..E'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_5..E`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初次级类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_5..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_5..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_5..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_5..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_5..D'
               ELSE
                'G12_5..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)
        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS = 4 --年初是次级
       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_5..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_5..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_5..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_5..D'
                  ELSE
                   'G12_5..C'
                END;

--次级
    INSERT INTO `G12_5..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..E' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..E' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..E',
                          'G12_3..E',
                          'G12_4..E',
                          'G12_5..E',
                          'G12_6..E',
                          'G12_7..E')
       GROUP BY ORG_NUM;

------------------------------------
    ---本期减少  次级类  可疑类  损失
    -------------------------------------

    INSERT INTO `G12_5..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_5..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_5..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_5..A',
                          'G12_5..C',
                          'G12_5..D',
                          'G12_5..E',
                          'G12_5..F',
                          'G12_5..G')
       GROUP BY ORG_NUM;


-- 指标: G12_5..F
--G12.3..F

    INSERT INTO `G12_5..F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..F'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..F'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..F'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..F'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..F'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '4'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..F'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..F'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..F'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..F'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..F'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_5..F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初次级类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_5..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_5..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_5..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_5..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_5..D'
               ELSE
                'G12_5..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)
        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS = 4 --年初是次级
       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_5..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_5..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_5..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_5..D'
                  ELSE
                   'G12_5..C'
                END;

--可疑
    INSERT INTO `G12_5..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..F' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..F' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..F',
                          'G12_3..F',
                          'G12_4..F',
                          'G12_5..F',
                          'G12_6..F',
                          'G12_7..F')
       GROUP BY ORG_NUM;

------------------------------------
    ---本期减少  次级类  可疑类  损失
    -------------------------------------

    INSERT INTO `G12_5..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_5..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_5..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_5..A',
                          'G12_5..C',
                          'G12_5..D',
                          'G12_5..E',
                          'G12_5..F',
                          'G12_5..G')
       GROUP BY ORG_NUM;


-- 指标: G12_5..B
--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_5..B`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------------
    ---本期减少  次级类  可疑类  损失
    -------------------------------------

    INSERT INTO `G12_5..B`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_5..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_5..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_5..A',
                          'G12_5..C',
                          'G12_5..D',
                          'G12_5..E',
                          'G12_5..F',
                          'G12_5..G')
       GROUP BY ORG_NUM;


-- 指标: G12_5..L
--====================================================
    --   G12   本年不良贷款处置情况,次级-损失
    --====================================================
    --修改 LRT 20180115
    INSERT INTO `G12_5..L`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..L'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..L'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..L'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..L'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..L'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                              OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(s.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                               OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '3') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND A.CANCEL_FLG <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..L'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..L'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..L'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..L'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..L'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初次级，归还时在次级、可疑、损失
    INSERT INTO `G12_5..L`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_5..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_5..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_5..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS = 4 --年初关注，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_5..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_5..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_5..L'
                END;


-- 指标: G12_4..E
--G12.3..E

    INSERT INTO `G12_4..E`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..E'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..E'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..E'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..E'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..E'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '3'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..E'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..E'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..E'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..E'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..E'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_4..E`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初关注类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_4..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN T2.LXQKQS >= 7 THEN
                'G12_4..G'
               WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_4..F'
               WHEN T2.LXQKQS = 4 THEN
                'G12_4..E'
               WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_4..D'
               ELSE
                'G12_4..C'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    0
                   ELSE
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP) - T.TRANAMT
                 END)
        FROM ( --年初为正常的贷款，本年还款金额与年初比大小，在根据期末五级分类状态划分五级分类
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
        LEFT JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T2.CARD_NO = T1.CARD_NO
         AND T2.ACCT_NUM = T1.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.LXQKQS BETWEEN 1 AND 3 --年初是关注
       GROUP BY CASE
                  WHEN T2.LXQKQS >= 7 THEN
                   'G12_4..G'
                  WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_4..F'
                  WHEN T2.LXQKQS = 4 THEN
                   'G12_4..E'
                  WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_4..D'
                  ELSE
                   'G12_4..C'
                END;

--次级
    INSERT INTO `G12_4..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..E' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..E' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..E',
                          'G12_3..E',
                          'G12_4..E',
                          'G12_5..E',
                          'G12_6..E',
                          'G12_7..E')
       GROUP BY ORG_NUM;


-- 指标: G12_4..F
--G12.3..F

    INSERT INTO `G12_4..F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..F'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..F'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..F'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..F'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..F'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '4'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..F'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..F'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..F'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..F'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..F'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_4..F`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初关注类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_4..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN T2.LXQKQS >= 7 THEN
                'G12_4..G'
               WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_4..F'
               WHEN T2.LXQKQS = 4 THEN
                'G12_4..E'
               WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_4..D'
               ELSE
                'G12_4..C'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    0
                   ELSE
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP) - T.TRANAMT
                 END)
        FROM ( --年初为正常的贷款，本年还款金额与年初比大小，在根据期末五级分类状态划分五级分类
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
        LEFT JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T2.CARD_NO = T1.CARD_NO
         AND T2.ACCT_NUM = T1.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.LXQKQS BETWEEN 1 AND 3 --年初是关注
       GROUP BY CASE
                  WHEN T2.LXQKQS >= 7 THEN
                   'G12_4..G'
                  WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_4..F'
                  WHEN T2.LXQKQS = 4 THEN
                   'G12_4..E'
                  WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_4..D'
                  ELSE
                   'G12_4..C'
                END;

--可疑
    INSERT INTO `G12_4..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..F' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..F' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..F',
                          'G12_3..F',
                          'G12_4..F',
                          'G12_5..F',
                          'G12_6..F',
                          'G12_7..F')
       GROUP BY ORG_NUM;


-- 指标: G12_2..C
--====================================================
    --   G12   2.本期增加,正常类贷款-损失类贷款
    --====================================================
    INSERT INTO `G12_2..C`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN LOAN_GRADE_CD = '1' THEN
                        'G12_2..C'
                       WHEN LOAN_GRADE_CD = '2' THEN
                        'G12_2..D'
                       WHEN LOAN_GRADE_CD = '3' THEN
                        'G12_2..E'
                       WHEN LOAN_GRADE_CD = '4' THEN
                        'G12_2..F'
                       WHEN LOAN_GRADE_CD = '5' THEN
                        'G12_2..G'
                     END AS ITEM_NUM, --指标号
                     SUM(LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE (TO_CHAR(A.DRAWDOWN_DT, 'YYYY') =
                     SUBSTR(I_DATADATE, 1, 4) OR
                     (A.INTERNET_LOAN_FLG = 'Y' AND
                     A.DRAWDOWN_DT =
                     (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                     OR (A.cp_id IN  ('DK001000100041') AND A.DRAWDOWN_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                     )
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                    --AND ITEM_CD NOT LIKE '129%' --本指标2022年一月份打开  20211029  ZHOUJINGKUN
                    -- AND SUBSTR(ITEM_CD,1,4) NOT LIKE '1301%' --M2
                    --AND A.ITEM_CD NOT IN ('12902', '12906') --刨除票据转贴现  20220421 shiyu
                    -- AND SUBSTR(A.ITEM_CD,1,6) NOT IN('130102','130105')  --刨除票据转贴现 --M2
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND A.ORG_NUM <> '009803'
                 and a.cancel_flg <> 'Y'
                 AND A.DATA_DATE = I_DATADATE --LRT 20180111
                 and A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_2..C'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_2..D'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_2..E'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_2..F'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_2..G'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--正常
    INSERT INTO `G12_2..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..C' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..C' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..C',
                          'G12_3..C',
                          'G12_4..C',
                          'G12_5..C',
                          'G12_6..C',
                          'G12_7..C')
       GROUP BY ORG_NUM;


-- 指标: G12_4..L
--====================================================
    --   G12   本年不良贷款处置情况,次级-损失
    --====================================================
    --修改 LRT 20180115
    INSERT INTO `G12_4..L`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN A.LOAN_GRADE_CD = '1' THEN
                  'G12_3..L'
                 WHEN A.LOAN_GRADE_CD = '2' THEN
                  'G12_4..L'
                 WHEN A.LOAN_GRADE_CD = '3' THEN
                  'G12_5..L'
                 WHEN A.LOAN_GRADE_CD = '4' THEN
                  'G12_6..L'
                 WHEN A.LOAN_GRADE_CD = '5' THEN
                  'G12_7..L'
               END ITEM_NUM,
               SUM(B.PAY_AMT) ITEM_VAL
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN (SELECT 
                           S.DATA_DATE,
                           S.LOAN_NUM,
                           S.ACCT_NUM,
                           S.PAY_AMT,
                           T.LOAN_GRADE_CD,
                           S.ORG_NUM
                            FROM SMTMODS_L_TRAN_LOAN_PAYM S
                           INNER JOIN SMTMODS_L_ACCT_LOAN T
                              ON S.LOAN_NUM = T.LOAN_NUM
                             AND T.DATA_DATE = I_DATADATE
                             AND (TO_CHAR(S.REPAY_DT, 'YYYYMM') =
                                 SUBSTR(T.DATA_DATE, 1, 6) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                              OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           WHERE (TO_CHAR(s.Repay_Dt, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (T.INTERNET_LOAN_FLG = 'Y' AND
                                 S.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                               OR (T.cp_id IN  ('DK001000100041') AND S.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                             AND T.ACCT_TYP NOT LIKE '90%'
                             AND T.ACCT_TYP NOT LIKE 'E%'
                             AND T.LOAN_GRADE_CD = '3') B
                  ON A.LOAN_NUM = B.LOAN_NUM
               WHERE A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231' --年初
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND A.CANCEL_FLG <> 'Y'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..L'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..L'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..L'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..L'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..L'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--年初关注，归还时在次级、可疑、损失
    INSERT INTO `G12_4..L`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_4..N'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_4..M'
               WHEN t.LXQKQS = 4 THEN
                'G12_4..L'
             END AS ITEM_NUM,
             SUM(T.TRANAMT)
        FROM (SELECT T.CARD_NO,
                     T.ACCT_NUM,
                     T.CURR_CD,
                     SUM(TRANAMT) TRANAMT,
                     t.lxqkqs
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
                 and t.lxqkqs >= 4
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD, t.lxqkqs) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR
         and t1.LXQKQS between 1 and 3 --年初关注，归还时在次级、可疑、损失
       GROUP BY CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_4..N'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_4..M'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_4..L'
                END;


-- 指标: G12_3..D
--G12.3..D

    INSERT INTO `G12_3..D`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..D'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..D'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..D'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..D'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..D'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '2'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..D'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..D'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..D'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..D'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..D'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_3..D`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    ---年初正常类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_3..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN T2.LXQKQS >= 7 THEN
                'G12_3..G'
               WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_3..F'
               WHEN T2.LXQKQS = 4 THEN
                'G12_3..E'
               WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_3..D'
               ELSE
                'G12_3..C'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                        T1.M6_UP) - T.TRANAMT <= 0 THEN
                    0
                   ELSE
                    (T1.M0 + T1.M1 + T1.M2 + T1.M3 + T1.M4 + T1.M5 + T1.M6 +
                    T1.M6_UP) - T.TRANAMT
                 END)
        FROM ( --年初为正常的贷款，本年还款金额与年初比大小，在根据期末五级分类状态划分五级分类
              SELECT T.CARD_NO, T.ACCT_NUM, T.CURR_CD, SUM(TRANAMT) TRANAMT
                FROM SMTMODS_L_TRAN_CARD_CREDIT_TX T
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
                     I_DATADATE
                 AND T.TRANTYPE IN ('11', '12') --交易类型为还款
               GROUP BY T.CARD_NO, T.ACCT_NUM, T.CURR_CD) T
       INNER JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T1.DATA_DATE = I_LAST_YEAR --
        LEFT JOIN SMTMODS_L_ACCT_CARD_CREDIT T2
          ON T2.CARD_NO = T1.CARD_NO
         AND T2.ACCT_NUM = T1.ACCT_NUM
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.LXQKQS <= 0 --年初是正常
       GROUP BY CASE
                  WHEN T2.LXQKQS >= 7 THEN
                   'G12_3..G'
                  WHEN T2.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_3..F'
                  WHEN T2.LXQKQS = 4 THEN
                   'G12_3..E'
                  WHEN T2.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_3..D'
                  ELSE
                   'G12_3..C'
                END;

--关注
    INSERT INTO `G12_3..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..D' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..D' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..D',
                          'G12_3..D',
                          'G12_4..D',
                          'G12_5..D',
                          'G12_6..D',
                          'G12_7..D')
       GROUP BY ORG_NUM;


-- 指标: G12_7..B
--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_7..B`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

INSERT INTO `G12_7..B`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_7..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_7..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_7..A',
                          'G12_7..C',
                          'G12_7..D',
                          'G12_7..E',
                          'G12_7..F',
                          'G12_7..G')
       GROUP BY ORG_NUM;


-- 指标: G12_7..D
--G12.3..D

    INSERT INTO `G12_7..D`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        'G12_3..D'
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        'G12_4..D'
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        'G12_5..D'
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        'G12_6..D'
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        'G12_7..D'
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_GRADE_CD = '2'
                 AND B.ACCT_STS <> '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           'G12_3..D'
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           'G12_4..D'
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           'G12_5..D'
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           'G12_6..D'
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           'G12_7..D'
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM;

--====================================================
    --   G12   3..B~7..B
    --====================================================
    INSERT INTO `G12_7..D`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             FLAG
        FROM (SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN A.ITEM_NUM IN ('G12_3..C',
                                     'G12_3..D',
                                     'G12_3..E',
                                     'G12_3..F',
                                     'G12_3..G') THEN
                  'G12_3..B'
                 WHEN A.ITEM_NUM IN ('G12_4..C',
                                     'G12_4..D',
                                     'G12_4..E',
                                     'G12_4..F',
                                     'G12_4..G') THEN
                  'G12_4..B'
                 WHEN A.ITEM_NUM IN ('G12_5..C',
                                     'G12_5..D',
                                     'G12_5..E',
                                     'G12_5..F',
                                     'G12_5..G') THEN
                  'G12_5..B'
                 WHEN A.ITEM_NUM IN ('G12_6..C',
                                     'G12_6..D',
                                     'G12_6..E',
                                     'G12_6..F',
                                     'G12_6..G') THEN
                  'G12_6..B'
                 WHEN A.ITEM_NUM IN ('G12_7..C',
                                     'G12_7..D',
                                     'G12_7..E',
                                     'G12_7..F',
                                     'G12_7..G') THEN
                  'G12_7..B'
               END AS ITEM_NUM, --指标号
               -SUM(A.ITEM_VAL) AS ITEM_VAL, --指标值
               '2' AS FLAG
                FROM CBRC_A_REPT_ITEM_VAL A
               WHERE A.ORG_NUM <> '009803'
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.ITEM_NUM IN ('G12_3..C',
                                              'G12_3..D',
                                              'G12_3..E',
                                              'G12_3..F',
                                              'G12_3..G') THEN
                           'G12_3..B'
                          WHEN A.ITEM_NUM IN ('G12_4..C',
                                              'G12_4..D',
                                              'G12_4..E',
                                              'G12_4..F',
                                              'G12_4..G') THEN
                           'G12_4..B'
                          WHEN A.ITEM_NUM IN ('G12_5..C',
                                              'G12_5..D',
                                              'G12_5..E',
                                              'G12_5..F',
                                              'G12_5..G') THEN
                           'G12_5..B'
                          WHEN A.ITEM_NUM IN ('G12_6..C',
                                              'G12_6..D',
                                              'G12_6..E',
                                              'G12_6..F',
                                              'G12_6..G') THEN
                           'G12_6..B'
                          WHEN A.ITEM_NUM IN ('G12_7..C',
                                              'G12_7..D',
                                              'G12_7..E',
                                              'G12_7..F',
                                              'G12_7..G') THEN
                           'G12_7..B'
                        END
              UNION ALL

              SELECT 
               I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'G12' AS REP_NUM, --报表编号
               CASE
                 WHEN LOAN_GRADE_CD = '1' THEN
                  'G12_3..B'
                 WHEN LOAN_GRADE_CD = '2' THEN
                  'G12_4..B'
                 WHEN LOAN_GRADE_CD = '3' THEN
                  'G12_5..B'
                 WHEN LOAN_GRADE_CD = '4' THEN
                  'G12_6..B'
                 WHEN LOAN_GRADE_CD = '5' THEN
                  'G12_7..B'
               END AS ITEM_NUM,
               SUM(LOAN_ACCT_BAL * U.CCY_RATE),
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = D_DATADATE_CCY
                 AND U.BASIC_CCY = CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_LAST_YEAR
                 AND ACCT_STS <> '3'
                 AND CANCEL_FLG <> 'Y'
                 AND ACCT_TYP NOT LIKE '90%'
                 AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN LOAN_GRADE_CD = '1' THEN
                           'G12_3..B'
                          WHEN LOAN_GRADE_CD = '2' THEN
                           'G12_4..B'
                          WHEN LOAN_GRADE_CD = '3' THEN
                           'G12_5..B'
                          WHEN LOAN_GRADE_CD = '4' THEN
                           'G12_6..B'
                          WHEN LOAN_GRADE_CD = '5' THEN
                           'G12_7..B'
                        END)
       WHERE ITEM_NUM IS NOT NULL
       GROUP BY DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, FLAG;

------------------------------
    --年初损失类贷款，期末正常五级分类
    ------------------------------
    INSERT INTO `G12_7..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      select '009803' AS ORG_NUM,
             CASE
               WHEN t.LXQKQS >= 7 THEN
                'G12_7..G'
               WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                'G12_7..F'
               WHEN t.LXQKQS = 4 THEN
                'G12_7..E'
               WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                'G12_7..D'
               ELSE
                'G12_7..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE)

        from SMTMODS_L_ACCT_CARD_CREDIT T
       inner JOIN SMTMODS_L_ACCT_CARD_CREDIT T1
          ON T.CARD_NO = T1.CARD_NO
         AND T.ACCT_NUM = T1.ACCT_NUM
         AND T.ISSUE_NUMBER = T1.ISSUE_NUMBER
         AND T1.DATA_DATE = I_LAST_YEAR
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and t1.LXQKQS >= 7 --年初是损失类贷款

       group by CASE
                  WHEN t.LXQKQS >= 7 THEN
                   'G12_7..G'
                  WHEN t.LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_7..F'
                  WHEN t.LXQKQS = 4 THEN
                   'G12_7..E'
                  WHEN t.LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_7..D'
                  ELSE
                   'G12_7..C'
                END;

--关注
    INSERT INTO `G12_7..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..D' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..D' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..D',
                          'G12_3..D',
                          'G12_4..D',
                          'G12_5..D',
                          'G12_6..D',
                          'G12_7..D')
       GROUP BY ORG_NUM;

INSERT INTO `G12_7..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_7..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_7..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_7..A',
                          'G12_7..C',
                          'G12_7..D',
                          'G12_7..E',
                          'G12_7..F',
                          'G12_7..G')
       GROUP BY ORG_NUM;


-- 指标: G12_12..B
--====================================================
    --   G12   以物抵债-12.贷款核销
    --====================================================
    INSERT INTO `G12_12..B`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM AS ITEM_NUM, --指标号
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN B.PAY_TYPE = '06' THEN
                  'G12_11..B'
                 WHEN B.PAY_TYPE = '08' THEN
                  'G12_12..B'
               END AS ITEM_NUM, --指标号
               SUM(B.PAY_AMT * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM B
                  ON A.LOAN_NUM = B.LOAN_NUM
              --AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND A.ACCT_STS <> '3'
                 AND A.CANCEL_FLG <> 'Y'
                 AND (TO_CHAR(B.REPAY_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) OR
                     (A.INTERNET_LOAN_FLG = 'Y' AND
                     B.REPAY_DT =
                     (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                     OR (A.cp_id IN  ('DK001000100041') AND B.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                     )
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND B.PAY_TYPE IN ('06', '08')
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN B.PAY_TYPE = '06' THEN
                           'G12_11..B'
                          WHEN B.PAY_TYPE = '08' THEN
                           'G12_12..B'
                        END) A
       GROUP BY A.ORG_NUM, ITEM_NUM;

-----------------------------
    -----12.贷款核销
    -----------------------------
    INSERT INTO `G12_12..B`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             'G12_12..B' AS ITEM_NUM,
             NVL(sum(T.DRAWDOWN_AMT),0)
        FROM SMTMODS_L_ACCT_WRITE_OFF T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.RETRIEVE_FLG <> 'C' -- 完全回收不报
         AND EXISTS (SELECT 1
                FROM SMTMODS_L_ACCT_CARD_CREDIT W
               WHERE W.DATA_DATE = I_DATADATE
                 AND T.ACCT_NUM = W.ACCT_NUM)
         and t.org_num = '009803';


-- ========== 逻辑组 55: 共 6 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '3' THEN
                        (CASE
                          WHEN A.RESCHED_FLG = 'Y' AND
                               B.LOAN_GRADE_CD IN ('1', '2') THEN
                           'G12_5..J'
                          WHEN A.RESCHED_FLG = 'N' AND
                               B.LOAN_GRADE_CD IN ('1', '2') THEN
                           'G12_5..K'
                        END)
                       WHEN A.LOAN_GRADE_CD = '4' THEN
                        (CASE
                          WHEN A.RESCHED_FLG = 'Y' AND
                               B.LOAN_GRADE_CD IN ('1', '2') THEN
                           'G12_6..J'
                          WHEN A.RESCHED_FLG = 'N' AND
                               B.LOAN_GRADE_CD IN ('1', '2') THEN
                           'G12_6..K'
                        END)
                       WHEN A.LOAN_GRADE_CD = '5' THEN
                        (CASE
                          WHEN A.RESCHED_FLG = 'Y' AND
                               B.LOAN_GRADE_CD IN ('1', '2') THEN
                           'G12_7..J'
                          WHEN A.RESCHED_FLG = 'N' AND
                               B.LOAN_GRADE_CD IN ('1', '2') THEN
                           'G12_7..K'
                        END)
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD = '1'
                 AND B.LOAN_GRADE_CD IN ('1', '2')
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.ACCT_TYP <> '3'
                 AND A.ACCT_TYP NOT LIKE '90%'
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '3' THEN
                           (CASE
                             WHEN A.RESCHED_FLG = 'Y' AND
                                  B.LOAN_GRADE_CD IN ('1', '2') THEN
                              'G12_5..J'
                             WHEN A.RESCHED_FLG = 'N' AND
                                  B.LOAN_GRADE_CD IN ('1', '2') THEN
                              'G12_5..K'
                           END)
                          WHEN A.LOAN_GRADE_CD = '4' THEN
                           (CASE
                             WHEN A.RESCHED_FLG = 'Y' AND
                                  B.LOAN_GRADE_CD IN ('1', '2') THEN
                              'G12_6..J'
                             WHEN A.RESCHED_FLG = 'N' AND
                                  B.LOAN_GRADE_CD IN ('1', '2') THEN
                              'G12_6..K'
                           END)
                          WHEN A.LOAN_GRADE_CD = '5' THEN
                           (CASE
                             WHEN A.RESCHED_FLG = 'Y' AND
                                  B.LOAN_GRADE_CD IN ('1', '2') THEN
                              'G12_7..J'
                             WHEN A.RESCHED_FLG = 'N' AND
                                  B.LOAN_GRADE_CD IN ('1', '2') THEN
                              'G12_7..K'
                           END)
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM
) q_55
INSERT INTO `G12_5..J` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_7..K` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_6..K` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_5..K` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_6..J` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_7..J` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 56: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM, --指标号,
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT A.ORG_NUM AS ORG_NUM, --机构号
                     CASE
                       WHEN A.LOAN_GRADE_CD = '1' THEN
                        (CASE
                          WHEN A.RESCHED_FLG = 'Y' THEN
                           'G12_3..J'
                          WHEN A.RESCHED_FLG = 'N' THEN
                           'G12_3..K'
                        END)
                       WHEN A.LOAN_GRADE_CD = '2' THEN
                        (CASE
                          WHEN A.RESCHED_FLG = 'Y' THEN --重组标志
                           'G12_4..J'
                          WHEN A.RESCHED_FLG = 'N' THEN
                           'G12_4..K'
                        END)
                     END AS ITEM_NUM, --指标号
                     SUM(B.LOAN_ACCT_BAL * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD = '1'
                 AND B.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.ACCT_TYP <> '3'
                 and b.cancel_flg <> 'Y'
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN A.LOAN_GRADE_CD = '1' THEN
                           (CASE
                             WHEN A.RESCHED_FLG = 'Y' THEN
                              'G12_3..J'
                             WHEN A.RESCHED_FLG = 'N' THEN
                              'G12_3..K'
                           END)
                          WHEN A.LOAN_GRADE_CD = '2' THEN
                           (CASE
                             WHEN A.RESCHED_FLG = 'Y' THEN
                              'G12_4..J'
                             WHEN A.RESCHED_FLG = 'N' THEN
                              'G12_4..K'
                           END)
                        END) A
       GROUP BY ORG_NUM, ITEM_NUM
) q_56
INSERT INTO `G12_3..J` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_4..K` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_3..K` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_4..J` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- 指标: G12_11..B
--====================================================
    --   G12   以物抵债-12.贷款核销
    --====================================================
    INSERT INTO `G12_11..B`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             ITEM_NUM AS ITEM_NUM, --指标号
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN B.PAY_TYPE = '06' THEN
                  'G12_11..B'
                 WHEN B.PAY_TYPE = '08' THEN
                  'G12_12..B'
               END AS ITEM_NUM, --指标号
               SUM(B.PAY_AMT * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM B
                  ON A.LOAN_NUM = B.LOAN_NUM
              --AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND A.ACCT_STS <> '3'
                 AND A.CANCEL_FLG <> 'Y'
                 AND (TO_CHAR(B.REPAY_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) OR
                     (A.INTERNET_LOAN_FLG = 'Y' AND
                     B.REPAY_DT =
                     (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                     OR (A.cp_id IN  ('DK001000100041') AND B.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                     )
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND B.PAY_TYPE IN ('06', '08')
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM,
                        CASE
                          WHEN B.PAY_TYPE = '06' THEN
                           'G12_11..B'
                          WHEN B.PAY_TYPE = '08' THEN
                           'G12_12..B'
                        END) A
       GROUP BY A.ORG_NUM, ITEM_NUM;


-- 指标: G12_7..A
------------------------------
    --年初余额
    ------------------------------
    INSERT INTO `G12_7..A`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN LXQKQS >= 7 THEN
                'G12_7..A'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..A'
               WHEN LXQKQS = 4 THEN
                'G12_5..A'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G12_4..A'
               ELSE
                'G12_3..A'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_LAST_YEAR
       GROUP BY CASE
                  WHEN LXQKQS >= 7 THEN
                   'G12_7..A'
                  WHEN LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..A'
                  WHEN LXQKQS = 4 THEN
                   'G12_5..A'
                  WHEN LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_4..A'
                  ELSE
                   'G12_3..A'
                END;

INSERT INTO `G12_7..A`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_7..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_7..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_7..A',
                          'G12_7..C',
                          'G12_7..D',
                          'G12_7..E',
                          'G12_7..F',
                          'G12_7..G')
       GROUP BY ORG_NUM;


-- ========== 逻辑组 59: 共 15 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G12' AS REP_NUM,
             CASE
               WHEN COLLECT_TYPE = '1' THEN
                'G12_10.2.L'
               WHEN COLLECT_TYPE = '2' THEN
                'G12_10.2.M'
               WHEN COLLECT_TYPE = '3' THEN
                'G12_10.2.N'
               WHEN COLLECT_TYPE = '4' THEN
                'G12_11..L'
               WHEN COLLECT_TYPE = '5' THEN
                'G12_11..M'
               WHEN COLLECT_TYPE = '6' THEN
                'G12_11..N'
               WHEN COLLECT_TYPE = '7' THEN
                'G12_12..L'
               WHEN COLLECT_TYPE = '8' THEN
                'G12_12..M'
               WHEN COLLECT_TYPE = '9' THEN
                'G12_12..N'
               WHEN COLLECT_TYPE = '10' THEN
                'G12_13..L'
               WHEN COLLECT_TYPE = '11' THEN
                'G12_13..M'
               WHEN COLLECT_TYPE = '12' THEN
                'G12_13..N'
               WHEN COLLECT_TYPE = '13' THEN
                'G12_10.2.1.L.2016'
               WHEN COLLECT_TYPE = '14' THEN
                'G12_10.2.1.L.M.2016'
               WHEN COLLECT_TYPE = '15' THEN
                'G12_10.2.1.L.N.2016'
               WHEN COLLECT_TYPE = '16' THEN
                'G12_12.1.L.2016'
               WHEN COLLECT_TYPE = '17' THEN
                'G12_12.1.M.2016'
               WHEN COLLECT_TYPE = '18' THEN
                'G12_12.1.N.2016'
               WHEN COLLECT_TYPE = '19' THEN
                'G12_14..L.2016'
               WHEN COLLECT_TYPE = '20' THEN
                'G12_14..M.2016'
               WHEN COLLECT_TYPE = '21' THEN
                'G12_14..N'
             END AS ITEM_NUM,
             SUM(COLLECT_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_PUB_DATA_COLLECT_G12
       WHERE COLLECT_TYPE IS NOT NULL
       GROUP BY ORG_NUM,
                CASE
                  WHEN COLLECT_TYPE = '1' THEN
                   'G12_10.2.L'
                  WHEN COLLECT_TYPE = '2' THEN
                   'G12_10.2.M'
                  WHEN COLLECT_TYPE = '3' THEN
                   'G12_10.2.N'
                  WHEN COLLECT_TYPE = '4' THEN
                   'G12_11..L'
                  WHEN COLLECT_TYPE = '5' THEN
                   'G12_11..M'
                  WHEN COLLECT_TYPE = '6' THEN
                   'G12_11..N'
                  WHEN COLLECT_TYPE = '7' THEN
                   'G12_12..L'
                  WHEN COLLECT_TYPE = '8' THEN
                   'G12_12..M'
                  WHEN COLLECT_TYPE = '9' THEN
                   'G12_12..N'
                  WHEN COLLECT_TYPE = '10' THEN
                   'G12_13..L'
                  WHEN COLLECT_TYPE = '11' THEN
                   'G12_13..M'
                  WHEN COLLECT_TYPE = '12' THEN
                   'G12_13..N'
                  WHEN COLLECT_TYPE = '13' THEN
                   'G12_10.2.1.L.2016'
                  WHEN COLLECT_TYPE = '14' THEN
                   'G12_10.2.1.L.M.2016'
                  WHEN COLLECT_TYPE = '15' THEN
                   'G12_10.2.1.L.N.2016'
                  WHEN COLLECT_TYPE = '16' THEN
                   'G12_12.1.L.2016'
                  WHEN COLLECT_TYPE = '17' THEN
                   'G12_12.1.M.2016'
                  WHEN COLLECT_TYPE = '18' THEN
                   'G12_12.1.N.2016'
                  WHEN COLLECT_TYPE = '19' THEN
                   'G12_14..L.2016'
                  WHEN COLLECT_TYPE = '20' THEN
                   'G12_14..M.2016'
                  WHEN COLLECT_TYPE = '21' THEN
                   'G12_14..N'
                END
) q_59
INSERT INTO `G12_10.2.M` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_10.2.L` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_12..N` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_10.2.1.L.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_11..N` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_12..L` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_11..L` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_12.1.M.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_12.1.N.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_10.2.N` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_11..M` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_12..M` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_14..L.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_14..M.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G12_12.1.L.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- 指标: G12_6..A
------------------------------
    --年初余额
    ------------------------------
    INSERT INTO `G12_6..A`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN LXQKQS >= 7 THEN
                'G12_7..A'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..A'
               WHEN LXQKQS = 4 THEN
                'G12_5..A'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G12_4..A'
               ELSE
                'G12_3..A'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_LAST_YEAR
       GROUP BY CASE
                  WHEN LXQKQS >= 7 THEN
                   'G12_7..A'
                  WHEN LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..A'
                  WHEN LXQKQS = 4 THEN
                   'G12_5..A'
                  WHEN LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_4..A'
                  ELSE
                   'G12_3..A'
                END;

INSERT INTO `G12_6..A`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_6..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_6..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_6..A',
                          'G12_6..C',
                          'G12_6..D',
                          'G12_6..E',
                          'G12_6..F',
                          'G12_6..G')
       GROUP BY ORG_NUM;


-- 指标: G12_1..C
------------------------------
    ----期末余额
    ----------------------------
    INSERT INTO `G12_1..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN LXQKQS >= 7 THEN
                'G12_1..G'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G12_1..F'
               WHEN LXQKQS = 4 THEN
                'G12_1..E'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G12_1..D'
               ELSE
                'G12_1..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY CASE
                  WHEN LXQKQS >= 7 THEN
                   'G12_1..G'
                  WHEN LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_1..F'
                  WHEN LXQKQS = 4 THEN
                   'G12_1..E'
                  WHEN LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_1..D'
                  ELSE
                   'G12_1..C'
                END;

--正常
    INSERT INTO `G12_1..C`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..C' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..C' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..C',
                          'G12_3..C',
                          'G12_4..C',
                          'G12_5..C',
                          'G12_6..C',
                          'G12_7..C')
       GROUP BY ORG_NUM;


-- ========== 逻辑组 62: 共 2 个指标 ==========
FROM (
SELECT '009803' AS ORG_NUM,
             CASE
               WHEN LXQKQS >= 7 THEN
                'G12_7..A'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..A'
               WHEN LXQKQS = 4 THEN
                'G12_5..A'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G12_4..A'
               ELSE
                'G12_3..A'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_LAST_YEAR
       GROUP BY CASE
                  WHEN LXQKQS >= 7 THEN
                   'G12_7..A'
                  WHEN LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..A'
                  WHEN LXQKQS = 4 THEN
                   'G12_5..A'
                  WHEN LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_4..A'
                  ELSE
                   'G12_3..A'
                END
) q_62
INSERT INTO `G12_4..A` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *
INSERT INTO `G12_3..A` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VAL)
SELECT *;

-- 指标: G12_1..G
------------------------------
    ----期末余额
    ----------------------------
    INSERT INTO `G12_1..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN LXQKQS >= 7 THEN
                'G12_1..G'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G12_1..F'
               WHEN LXQKQS = 4 THEN
                'G12_1..E'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G12_1..D'
               ELSE
                'G12_1..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY CASE
                  WHEN LXQKQS >= 7 THEN
                   'G12_1..G'
                  WHEN LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_1..F'
                  WHEN LXQKQS = 4 THEN
                   'G12_1..E'
                  WHEN LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_1..D'
                  ELSE
                   'G12_1..C'
                END;

--损失

    INSERT INTO `G12_1..G`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..G' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..G' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..G',
                          'G12_3..G',
                          'G12_4..G',
                          'G12_5..G',
                          'G12_6..G',
                          'G12_7..G')
       GROUP BY ORG_NUM;


-- 指标: G12_1..D
------------------------------
    ----期末余额
    ----------------------------
    INSERT INTO `G12_1..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN LXQKQS >= 7 THEN
                'G12_1..G'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G12_1..F'
               WHEN LXQKQS = 4 THEN
                'G12_1..E'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G12_1..D'
               ELSE
                'G12_1..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY CASE
                  WHEN LXQKQS >= 7 THEN
                   'G12_1..G'
                  WHEN LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_1..F'
                  WHEN LXQKQS = 4 THEN
                   'G12_1..E'
                  WHEN LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_1..D'
                  ELSE
                   'G12_1..C'
                END;

--关注
    INSERT INTO `G12_1..D`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..D' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..D' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..D',
                          'G12_3..D',
                          'G12_4..D',
                          'G12_5..D',
                          'G12_6..D',
                          'G12_7..D')
       GROUP BY ORG_NUM;


-- 指标: G12_5..A
------------------------------
    --年初余额
    ------------------------------
    INSERT INTO `G12_5..A`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN LXQKQS >= 7 THEN
                'G12_7..A'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G12_6..A'
               WHEN LXQKQS = 4 THEN
                'G12_5..A'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G12_4..A'
               ELSE
                'G12_3..A'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_LAST_YEAR
       GROUP BY CASE
                  WHEN LXQKQS >= 7 THEN
                   'G12_7..A'
                  WHEN LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_6..A'
                  WHEN LXQKQS = 4 THEN
                   'G12_5..A'
                  WHEN LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_4..A'
                  ELSE
                   'G12_3..A'
                END;

------------------------------------
    ---本期减少  次级类  可疑类  损失
    -------------------------------------

    INSERT INTO `G12_5..A`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_5..B' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_5..A' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_5..A',
                          'G12_5..C',
                          'G12_5..D',
                          'G12_5..E',
                          'G12_5..F',
                          'G12_5..G')
       GROUP BY ORG_NUM;


-- 指标: G12_10.2.1.B.2016
--====================================================
    --   G12   以物抵债-12.贷款核销
    --====================================================
    INSERT INTO `G12_10.2.1.B.2016`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             'G12_10.2.1.B.2016' AS ITEM_NUM, --指标号
             SUM(ITEM_VAL) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               SUM((A.LOAN_ACCT_BAL - B.LOAN_ACCT_BAL) * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
               INNER JOIN (SELECT D.LOAN_NUM, MAX(D.PAY_TYPE)
                            FROM SMTMODS_L_TRAN_LOAN_PAYM D
                            LEFT JOIN SMTMODS_L_ACCT_LOAN E
                              ON E.LOAN_NUM = D.LOAN_NUM
                           WHERE D.PAY_TYPE <= '03'
                             AND D.BATCH_TRAN_FLG = 'Y'
                             AND (TO_CHAR(D.REPAY_DT, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (E.INTERNET_LOAN_FLG = 'Y' AND
                                 D.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                                 OR (E.cp_id IN  ('DK001000100041') AND  D.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           GROUP BY D.LOAN_NUM) C
                  ON A.LOAN_NUM = C.LOAN_NUM
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND B.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND B.ACCT_STS != '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM) A --是 批量转让
       GROUP BY A.ORG_NUM;


-- 指标: G12_1..F
------------------------------
    ----期末余额
    ----------------------------
    INSERT INTO `G12_1..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN LXQKQS >= 7 THEN
                'G12_1..G'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G12_1..F'
               WHEN LXQKQS = 4 THEN
                'G12_1..E'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G12_1..D'
               ELSE
                'G12_1..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY CASE
                  WHEN LXQKQS >= 7 THEN
                   'G12_1..G'
                  WHEN LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_1..F'
                  WHEN LXQKQS = 4 THEN
                   'G12_1..E'
                  WHEN LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_1..D'
                  ELSE
                   'G12_1..C'
                END;

--可疑
    INSERT INTO `G12_1..F`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..F' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..F' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..F',
                          'G12_3..F',
                          'G12_4..F',
                          'G12_5..F',
                          'G12_6..F',
                          'G12_7..F')
       GROUP BY ORG_NUM;


-- 指标: G12_1..E
------------------------------
    ----期末余额
    ----------------------------
    INSERT INTO `G12_1..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT '009803' AS ORG_NUM,
             CASE
               WHEN LXQKQS >= 7 THEN
                'G12_1..G'
               WHEN LXQKQS BETWEEN 5 AND 6 THEN
                'G12_1..F'
               WHEN LXQKQS = 4 THEN
                'G12_1..E'
               WHEN LXQKQS BETWEEN 1 AND 3 THEN
                'G12_1..D'
               ELSE
                'G12_1..C'
             END AS ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY CASE
                  WHEN LXQKQS >= 7 THEN
                   'G12_1..G'
                  WHEN LXQKQS BETWEEN 5 AND 6 THEN
                   'G12_1..F'
                  WHEN LXQKQS = 4 THEN
                   'G12_1..E'
                  WHEN LXQKQS BETWEEN 1 AND 3 THEN
                   'G12_1..D'
                  ELSE
                   'G12_1..C'
                END;

--次级
    INSERT INTO `G12_1..E`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VAL --指标值
       )
      SELECT ORG_NUM,
             'G12_2..E' AS ITEM_NUM,
             SUM(CASE
                   WHEN ITEM_NUM = 'G12_1..E' THEN
                    ITEM_VAL
                   ELSE
                    ITEM_VAL * -1
                 END) AS ITEM_VAL

        FROM CBRC_G12_XYK_TEMP
       WHERE ITEM_NUM IN ('G12_1..E',
                          'G12_3..E',
                          'G12_4..E',
                          'G12_5..E',
                          'G12_6..E',
                          'G12_7..E')
       GROUP BY ORG_NUM;


-- 指标: G12_12.1.B.2016
V_STEP_DESC := 'G12_12.1.B.2016';

--====================================================
    --   G12   以物抵债-12.贷款核销
    --====================================================
    INSERT INTO `G12_12.1.B.2016`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             'G12_12.1.B.2016' AS ITEM_NUM, --指标号
             SUM(ITEM_VAL) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               SUM(B.PAY_AMT * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM B
                  ON A.LOAN_NUM = B.LOAN_NUM
              -- AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND A.ACCT_STS <> '3'
                 AND A.CANCEL_FLG <> 'Y'
                 AND (TO_CHAR(B.REPAY_DT, 'YYYY') = SUBSTR(I_DATADATE, 1, 4) OR
                     (A.INTERNET_LOAN_FLG = 'Y' AND
                     B.REPAY_DT =
                     (TRUNC(I_DATADATE, 'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                     OR (A.cp_id IN  ('DK001000100041') AND B.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]
                     )
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND B.BATCH_TRAN_FLG = 'Y'
                 AND SUBSTR(A.ACCT_TYP, 1, 2) != '90'
                 AND B.PAY_TYPE = '08'
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM

              ) A
       GROUP BY A.ORG_NUM;

V_STEP_DESC := 'G12_12.1.B.2016';


-- 指标: G12_10.2.B
--====================================================
    --   G1101 10.2  不良贷款处理
    --====================================================
    INSERT INTO `G12_10.2.B`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G12' AS REP_NUM, --报表编号
             'G12_10.2.B' AS ITEM_NUM, --指标号
             SUM(ITEM_VAL), --指标值
             '2' AS FLAG
        FROM (SELECT 
               A.ORG_NUM AS ORG_NUM, --机构号
               SUM((A.LOAN_ACCT_BAL - B.LOAN_ACCT_BAL) * U.CCY_RATE) AS ITEM_VAL --指标值
                FROM SMTMODS_L_ACCT_LOAN A
               INNER JOIN SMTMODS_L_ACCT_LOAN B
                  ON A.LOAN_NUM = B.LOAN_NUM
                 AND B.DATA_DATE = I_DATADATE
               INNER JOIN (SELECT D.LOAN_NUM, MAX(D.PAY_TYPE)
                            FROM SMTMODS_L_TRAN_LOAN_PAYM D
                            LEFT JOIN SMTMODS_L_ACCT_LOAN E
                              ON E.LOAN_NUM = D.LOAN_NUM
                           WHERE D.PAY_TYPE <= '03'
                             AND (TO_CHAR(D.REPAY_DT, 'YYYY') =
                                 SUBSTR(I_DATADATE, 1, 4) OR
                                 (E.INTERNET_LOAN_FLG = 'Y' AND
                                 D.REPAY_DT =
                                 (TRUNC(I_DATADATE,
                                          'YY') - 1)) --modify by 87v : 互联网贷款数据晚一天下发，去年末数据当年取不到，本年取
                                 OR (E.cp_id IN  ('DK001000100041') AND D.REPAY_DT = (TRUNC(I_DATADATE, 'MM') - 1) )      --[JLBA202507300010][石雨][新增吉慧贷产品晚两天下发]

                                 )
                           GROUP BY D.LOAN_NUM) C
                  ON A.LOAN_NUM = C.LOAN_NUM
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND B.LOAN_GRADE_CD IN ('3', '4', '5')
                 AND B.ACCT_STS != '3'
                 AND B.CANCEL_FLG <> 'Y'
                 AND A.ACCT_TYP NOT LIKE '90%'
                 AND A.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
                 AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
               GROUP BY A.ORG_NUM) A
       GROUP BY A.ORG_NUM;


