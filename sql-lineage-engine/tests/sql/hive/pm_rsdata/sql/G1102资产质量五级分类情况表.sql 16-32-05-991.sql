-- ============================================================
-- 文件名: G1102资产质量五级分类情况表.sql
-- 生成时间: 2025-12-18 13:53:39
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 5 个指标 ==========
FROM (
SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE
         WHEN LOAN_GRADE_CD = '1' THEN
          'G11_2_1..C'
         WHEN LOAN_GRADE_CD IS NULL THEN
          'G11_2_1..C'
         WHEN LOAN_GRADE_CD = '2' THEN
          'G11_2_1..D'
         WHEN LOAN_GRADE_CD = '3' THEN
          'G11_2_1..F'
         WHEN LOAN_GRADE_CD = '4' THEN
          'G11_2_1..G'
         WHEN LOAN_GRADE_CD = '5' THEN
          'G11_2_1..H'
       END AS ITEM_NUM, --指标号
       SUM(NVL(A.LOAN_ACCT_BAL, 0)) AS COLLECT_VAL, --指标值
       '贷款' TAG
        FROM CBRC_TMP_ACCT_LOAN_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                 CASE
                   WHEN LOAN_GRADE_CD = '1' THEN
                    'G11_2_1..C'
                   WHEN LOAN_GRADE_CD IS NULL THEN
                    'G11_2_1..C'
                   WHEN LOAN_GRADE_CD = '2' THEN
                    'G11_2_1..D'
                   WHEN LOAN_GRADE_CD = '3' THEN
                    'G11_2_1..F'
                   WHEN LOAN_GRADE_CD = '4' THEN
                    'G11_2_1..G'
                   WHEN LOAN_GRADE_CD = '5' THEN
                    'G11_2_1..H'
                 END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL, --指标值
       TAG
       )
       --JLBA202412040012
       SELECT '009803' AS ORG_NUM,
             case
                  when LXQKQS >= 7 then
                   'G11_2_1..H'
                  when LXQKQS between 5 and 6 then
                   'G11_2_1..G'
                  when LXQKQS = 4 then
                   'G11_2_1..F'
                  when LXQKQS between 1 and 3 then
                   'G11_2_1..D'
                  else
                   'G11_2_1..C'
                end as COLLECT_TYPE,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) as COLLECT_VAL,
           '信用卡'
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
       group by case
                  when LXQKQS >= 7 then
                   'G11_2_1..H'
                  when LXQKQS between 5 and 6 then
                   'G11_2_1..G'
                  when LXQKQS = 4 then
                   'G11_2_1..F'
                  when LXQKQS between 1 and 3 then
                   'G11_2_1..D'
                  else
                   'G11_2_1..C'
                end
) q_0
INSERT INTO `G11_2_1..D` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL,  
       TAG)
SELECT *
INSERT INTO `G11_2_1..F` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL,  
       TAG)
SELECT *
INSERT INTO `G11_2_1..G` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL,  
       TAG)
SELECT *
INSERT INTO `G11_2_1..C` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL,  
       TAG)
SELECT *
INSERT INTO `G11_2_1..H` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL,  
       TAG)
SELECT *;

-- 指标: G11_2_17..I.2024
INSERT INTO `G11_2_17..I.2024`
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    --其中3笔资产特殊处理放到逾期  资产编号:东吴基金管理公司+方正证券+华阳经贸
    SELECT 
     A.ORG_NUM AS ORG_NUM, --机构号
     'G11_2_17..I.2024' AS ITEM_NUM, --指标号
     SUM(NVL(A.PRINCIPAL_BALANCE, 0) * U.CCY_RATE) AS COLLECT_VAL
      FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
       AND U.DATA_DATE = I_DATADATE
     WHERE A.SUBJECT_CD IN
          --3笔特殊处理的东吴基金管理公司，方正证券，华阳经贸的利息放到逾期
           ('N000310000012013', 'N000310000008023', 'N000310000012993')
       AND A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM;

INSERT INTO `G11_2_17..I.2024`
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             'G11_2_17..I.2024' ITEM_NUM,
             SUM(NVL(D.FACE_VAL, 0)) AS ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND (D.ISSU_ORG_NAM NOT LIKE '民生通惠%' OR  D.ISSU_ORG_NAM IS NULL)
         AND SUBSTR(D.INVEST_TYP, 1, 2) IN ('12', '99')
         AND D.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
         AND D.BOOK_TYPE = '2' --银行账薄
         AND D.ORG_NUM = '009817'
       GROUP BY D.ORG_NUM;


-- ========== 逻辑组 2: 共 2 个指标 ==========
FROM (
SELECT A.RECORD_ORG,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_14.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_14.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_14.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_14.2.H.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_14.2.G.2016'
             END,
             SUM(NVL(A.PRIN_FINAL_RESLT, 0) * U.CCY_RATE) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_ASSET_DEVALUE A --资产减值准备
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.PRIN_SUBJ_NO = '15010201'
         AND A.RECORD_ORG = '009804'
       GROUP BY A.RECORD_ORG,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_14.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_14.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_14.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_14.2.H.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_14.2.G.2016'
                END;

--009817:减值对应I9系统的最终本金ECL字段
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_14.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_14.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_14.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_14.2.H.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_14.2.G.2016'
             END,
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817' --投管
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '04' --信托
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_14.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_14.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_14.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_14.2.H.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_14.2.G.2016'
                END
) q_2
INSERT INTO `G11_2_14.2.C.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_14.2.F.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *;

-- 指标: G11_2_11..C.2016
INSERT  INTO `G11_2_11..C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --取买入返售（债券+票据）的剩余本金，默认正常类
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_11..C.2016' AS ITEM_NUM, --指标号
             SUM(A.BALANCE) AS COLLECT_VAL --指标值，A.余额（折人民币）
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A --回购信息表
       WHERE A.BUSI_TYPE LIKE '1%'
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.BUSI_TYPE IN ('101', '102') --101质押式买入返售 102买断式买入返售  201质押式卖出回购 202买断式卖出回购
         --AND A.ASS_TYPE IN ('1', '3') --1债券 3票据
         AND A.DATA_DATE = I_DATADATE
         GROUP BY A.ORG_NUM;


-- 指标: G11_2_1.2.I.2019
INSERT 
    INTO `G11_2_1.2.I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT ORG_NUM AS ORG_NUM,
           'G11_2_1.2.I.2019' AS ITEM_NUM,
           SUM(NVL(JZJE, 0)) AS ITEM_VAL
      FROM (SELECT A.DATA_DATE     AS DATA_DATE,
                   A.ORG_NUM       AS ORG_NUM,
                   A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                   A.ACCT_NUM      AS ACCT_NUM,
                   A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
                   A.SECURITY_AMT  AS SECURITY_AMT,
                   A.OD_INT        AS OD_INT,
                   A.JZJE,
                   A.LOAN_NUM
              FROM CBRC_TMP_ACCT_LOAN_G1102 A
             WHERE A.OD_DAYS <= 90
               AND A.OD_DAYS > 0
               AND A.OD_FLG = 'Y'
               AND A.DATA_DATE = I_DATADATE
               AND ORG_NUM <> '009803'
               AND (ACCT_TYP NOT LIKE '0101%' AND ACCT_TYP NOT LIKE '0103%' AND
                   ACCT_TYP NOT LIKE '0104%' AND ACCT_TYP NOT LIKE '0199%' AND
                   ACCT_TYP NOT IN ('E01', 'E02') AND ACCT_TYP NOT LIKE '90%')
               AND A.GL_ITEM_CODE NOT LIKE '130105%'

            UNION ALL

            SELECT A.DATA_DATE AS DATA_DATE,
                   A.ORG_NUM AS ORG_NUM,
                   A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                   A.ACCT_NUM AS ACCT_NUM,
                   CASE --JLBA202412040012
                     WHEN A.PAY_TYPE  IN ('01', '02','10','11') AND B.REPAY_TYP ='1'  THEN
                      NVL(A.OD_LOAN_ACCT_BAL, 0)
                     ELSE
                      NVL(A.LOAN_ACCT_BAL, 0)
                   END AS LOAN_ACCT_BAL,
                   A.SECURITY_AMT AS SECURITY_AMT,
                   A.OD_INT AS OD_INT,
                   CASE --JLBA202412040012
                     WHEN A.PAY_TYPE  IN ('01', '02','10','11') AND B.REPAY_TYP ='1'  THEN
                      NVL(A.JZJE, 0)
                     ELSE
                      NVL(A.JZJE, 0)
                   END AS JZJE,
                   A.LOAN_NUM
              FROM CBRC_TMP_ACCT_LOAN_G1102 A
                LEFT JOIN SMTMODS_L_ACCT_LOAN B
                   ON A.LOAN_NUM =B.LOAN_NUM
                   AND B.DATA_DATE = I_DATADATE
             WHERE A.OD_DAYS > 0
               AND A.OD_DAYS <= 90
               AND A.OD_FLG = 'Y'
               AND A.DATA_DATE = I_DATADATE
               AND (A.ACCT_TYP LIKE '0101%' OR A.ACCT_TYP LIKE '0103%' OR
                   A.ACCT_TYP LIKE '0104%' OR
                   A.ACCT_TYP LIKE '0199%' )
                   AND A.ACCT_TYP NOT LIKE '90%'
               AND A.GL_ITEM_CODE NOT LIKE '130105%'
               AND A.ORG_NUM <> '009803'

            UNION ALL

            SELECT A.DATA_DATE     AS DATA_DATE,
                   A.ORG_NUM       AS ORG_NUM,
                   A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                   A.ACCT_NUM      AS ACCT_NUM,
                   A.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
                   A.SECURITY_AMT  AS SECURITY_AMT,
                   A.OD_INT        AS OD_INT,
                   A.JZJE,
                   A.LOAN_NUM
              FROM CBRC_TMP_ACCT_LOAN_G1102 A
             WHERE A.OD_FLG = 'Y'
               AND A.DATA_DATE = I_DATADATE
               AND (A.OD_DAYS > 90 OR A.OD_DAYS IS NULL)
               AND A.ACCT_TYP NOT LIKE '90%')
     GROUP BY ORG_NUM;


-- 指标: G11_2_17.2.F.2016
INSERT  INTO `G11_2_17.2.F.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息 减值
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17.2.H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.BUSI_TYPE LIKE '1%'
       GROUP BY A.ORG_NUM,
                CASE
                   WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                    'G11_2_17.2.C.2016'
                   WHEN A.FIVE_TIER_CLS = '02' THEN
                    'G11_2_17.2.D.2016'
                   WHEN A.FIVE_TIER_CLS = '03' THEN
                    'G11_2_17.2.F.2016'
                   WHEN A.FIVE_TIER_CLS = '04' THEN
                    'G11_2_17.2.G.2016'
                   WHEN A.FIVE_TIER_CLS = '05' THEN
                    'G11_2_17.2.H.2016'
                 END;

--债券投资 应收利息 减值
     INSERT  INTO `G11_2_17.2.F.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM, --机构号
                CASE
                   WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                    'G11_2_17.2.C.2016'
                   WHEN A.FIVE_TIER_CLS = '02' THEN
                    'G11_2_17.2.D.2016'
                   WHEN A.FIVE_TIER_CLS = '03' THEN
                    'G11_2_17.2.F.2016'
                   WHEN A.FIVE_TIER_CLS = '04' THEN
                    'G11_2_17.2.G.2016'
                   WHEN A.FIVE_TIER_CLS = '05' THEN
                    'G11_2_17.2.H.2016'
                 END;

--存放同业 拆放同业的应收 减值
    INSERT 
    INTO `G11_2_17.2.F.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17.2.C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17.2.D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17.2.F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17.2.G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17.2.H.2016'
         END COLLECT_TYPE,
         SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM,
              CASE
                WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                 'G11_2_17.2.C.2016'
                WHEN A.FIVE_TIER_CLS = '02' THEN
                 'G11_2_17.2.D.2016'
                WHEN A.FIVE_TIER_CLS = '03' THEN
                 'G11_2_17.2.F.2016'
                WHEN A.FIVE_TIER_CLS = '04' THEN
                 'G11_2_17.2.G.2016'
                WHEN A.FIVE_TIER_CLS = '05' THEN
                 'G11_2_17.2.H.2016'
              END;

--AC的应收 减值
    INSERT 
    INTO `G11_2_17.2.F.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17.2.C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17.2.D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17.2.F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17.2.G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17.2.H.2016'
           END COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '15010201'
         AND A.ACCOUNTANT_TYPE = '3'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17.2.H.2016'
                END;

--009817：存量非标的应收利息+其他应收款按五级分类划分
    INSERT 
    INTO `G11_2_17.2.F.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17.2.C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17.2.D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17.2.F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17.2.G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17.2.H.2016'
           END COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17.2.H.2016'
                END;

/* --其他应收款的减值取科目12310101其他应收款坏账准备贷方，放次级
    INSERT \*+ append*\
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
       SELECT T.ORG_NUM AS ORG_NUM,
             'G11_2_17.2.F.2016'AS COLLECT_TYPE,
             SUM(NVL(T.CREDIT_BAL,0) * U.CCY_RATE) AS COLLECT_VAL
       FROM SMTMODS_L_FINA_GL T
       LEFT JOIN SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
        AND U.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM = '009817'
         AND T.ITEM_CD = '12310101'
       GROUP BY T.ORG_NUM;

*/

   --ADD BY DJH 20240827 投行前台补录其他应收款的减值

      INSERT 
      INTO `G11_2_17.2.F.2016` 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
        SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17.2.C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17.2.D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17.2.F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17.2.G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17.2.H.2016'
         END COLLECT_TYPE,
         SUM(NVL(A.FINAL_ECL, 0)) AS COLLECT_VAL
          FROM (SELECT 
                 A.ORG_NUM, --机构号
                 C.FIVE_TIER_CLS, --减值五级分类
                 C.FINAL_ECL,
                 A.BOOK_TYPE,
                 C.DATA_SRC
                  FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
                 INNER JOIN CBRC_TMP_ASSET_DEVALUE_TH C --资产减值准备
                    ON C.ACCT_NUM = A.ACCT_NUM
                   AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
                   AND A.ORG_NUM = C.RECORD_ORG
                   AND C.DATA_DATE = I_DATADATE
                 WHERE A.DATA_DATE = I_DATADATE
                   AND NVL(A.PRINCIPAL_BALANCE, 0) <> 0) A --投资业务信息表
         WHERE A.ORG_NUM = '009817'
           AND A.FINAL_ECL <> 0
           AND A.BOOK_TYPE = '2' --银行账薄
           AND A.DATA_SRC = '投行手工补录其他应收款坏账准备'
         GROUP BY A.ORG_NUM,
                  CASE
                    WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                     'G11_2_17.2.C.2016'
                    WHEN A.FIVE_TIER_CLS = '02' THEN
                     'G11_2_17.2.D.2016'
                    WHEN A.FIVE_TIER_CLS = '03' THEN
                     'G11_2_17.2.F.2016'
                    WHEN A.FIVE_TIER_CLS = '04' THEN
                     'G11_2_17.2.G.2016'
                    WHEN A.FIVE_TIER_CLS = '05' THEN
                     'G11_2_17.2.H.2016'
                  END;


-- ========== 逻辑组 6: 共 3 个指标 ==========
FROM (
SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN (A.GRADE = '1' OR A.GRADE IS NULL) THEN --正常类
                'G11_2_14..C.2016'
               WHEN A.GRADE = '2' THEN --关注类
                'G11_2_14..D.2016'
               WHEN A.GRADE = '3' THEN --次级类
                'G11_2_14..F.2016'
               WHEN A.GRADE = '4' THEN --可疑类
                'G11_2_14..G.2016'
               WHEN A.GRADE = '5' THEN --损失类
                'G11_2_14..H.2016'
             END AS ITEM_NUM, --指标号
             SUM(A.FACE_VAL + A.MK_VAL) AS COLLECT_VAL --持有仓位+公允价值
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '04' --信托产品投资
         AND A.ORG_NUM <> '009817' --投管不在此处取
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN(A.GRADE = '1' OR A.GRADE IS NULL) THEN --正常类
                   'G11_2_14..C.2016'
                  WHEN A.GRADE = '2' THEN --关注类
                   'G11_2_14..D.2016'
                  WHEN A.GRADE = '3' THEN --次级类
                   'G11_2_14..F.2016'
                  WHEN A.GRADE = '4' THEN --可疑类
                   'G11_2_14..G.2016'
                  WHEN A.GRADE = '5' THEN --损失类
                   'G11_2_14..H.2016'
                END;

--009817：存量非标信托关联I9系统，取信托减值的五级分类划分信托本金的五级分类
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN --正常类
                'G11_2_14..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN --关注类
                'G11_2_14..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN --次级类
                'G11_2_14..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN --可疑类
                'G11_2_14..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN --损失类
                'G11_2_14..H.2016'
             END AS ITEM_NUM, --指标号
             SUM(A.FACE_VAL) AS COLLECT_VAL --持有仓位
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817' --投管
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '04' --信托
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN --正常类
                   'G11_2_14..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN --关注类
                   'G11_2_14..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN --次级类
                   'G11_2_14..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN --可疑类
                   'G11_2_14..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN --损失类
                   'G11_2_14..H.2016'
                END
) q_6
INSERT INTO `G11_2_14..C.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_14..G.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_14..F.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *;

-- 指标: G11_2_17..H.2016
INSERT  INTO `G11_2_17..H.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    --同业存单 应收利息
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(A.INTEREST_RECEIVABLE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_CDS_BAL_G1102 A --存单投资与发行信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

INSERT  INTO `G11_2_17..H.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BUSI_TYPE LIKE '1%'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--债券投资 应收利息
   INSERT  INTO `G11_2_17..H.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.ACCRUAL, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--损失:140万固定值+其他应收款应收1221科目
     INSERT 
     INTO `G11_2_17..H.2016` 
       (ORG_NUM, --机构号
        COLLECT_TYPE, --报表类型
        COLLECT_VAL --指标值
        )
       SELECT 
        A.ORG_NUM AS ORG_NUM, --机构号
        'G11_2_17..H.2016' AS ITEM_NUM, --指标号
        SUM(A.DEBIT_BAL + 1400000) AS COLLECT_VAL
         FROM SMTMODS_L_FINA_GL A
         LEFT JOIN SMTMODS_L_PUBL_RATE U
           ON U.CCY_DATE = I_DATADATE
          AND U.BASIC_CCY = A.CURR_CD --基准币种
          AND U.FORWARD_CCY = 'CNY' --折算币种
          AND U.DATA_DATE = I_DATADATE
        WHERE A.DATA_DATE = I_DATADATE
          AND A.ORG_NUM = '009820'
          AND A.ITEM_CD IN ('1221')
          AND A.CURR_CD = 'BWB'
        GROUP BY A.ORG_NUM;

--基金的应收
    INSERT 
    INTO `G11_2_17..H.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17..C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17..D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17..F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17..G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17..H.2016'
           END COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP IN ('01')
         AND A.ACCRUAL <> 0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--存放同业 拆放同业的应收
    INSERT 
    INTO `G11_2_17..H.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17..C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17..D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17..F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17..G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17..H.2016'
         END COLLECT_TYPE,
         SUM(A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM,
              CASE
                WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                 'G11_2_17..C.2016'
                WHEN A.FIVE_TIER_CLS = '02' THEN
                 'G11_2_17..D.2016'
                WHEN A.FIVE_TIER_CLS = '03' THEN
                 'G11_2_17..F.2016'
                WHEN A.FIVE_TIER_CLS = '04' THEN
                 'G11_2_17..G.2016'
                WHEN A.FIVE_TIER_CLS = '05' THEN
                 'G11_2_17..H.2016'
              END;

--009817：存量非标的应收利息+其他应收款按五级分类划分
    INSERT 
    INTO `G11_2_17..H.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17..C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17..D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17..F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17..G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17..H.2016'
           END COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--009820 AC账户 应收利息
   INSERT  INTO `G11_2_17..H.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.ACCRUAL, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.ORG_NUM = '009820'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '3' --AC账户
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;


-- ========== 逻辑组 8: 共 3 个指标 ==========
FROM (
SELECT 
     ORG_NUM AS ORG_NUM,
     CASE
       WHEN LOAN_GRADE_CD = '3' THEN
        'G11_2_1.1.F'
       WHEN LOAN_GRADE_CD = '4' THEN
        'G11_2_1.1.G'
       WHEN LOAN_GRADE_CD = '5' THEN
        'G11_2_1.1.H'
     END AS ITEM_NUM, --指标号
     SUM(CASE
           WHEN NVL(SECURITY_AMT, 0) + NVL(COLL_MK_VAL, 0) > NVL(LOAN_ACCT_BAL, 0) + NVL(OD_INT, 0) THEN
            NVL(LOAN_ACCT_BAL, 0) + NVL(OD_INT, 0)
           ELSE
            NVL(SECURITY_AMT, 0) + NVL(COLL_MK_VAL, 0)
         END) AS COLLECT_VAL
      FROM (SELECT 
             LOAN.DATA_DATE AS DATA_DATE,
             LOAN.ORG_NUM AS ORG_NUM, --机构号
             LOAN.LOAN_GRADE_CD AS LOAN_GRADE_CD,
             NVL(GUA.COLL_MK_VAL, 0) AS COLL_MK_VAL,
             LOAN.SECURITY_AMT AS SECURITY_AMT,
             LOAN.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
             LOAN.OD_INT AS OD_INT,
             LOAN.ACCT_NUM AS ACCT_NUM
              FROM (SELECT T.DATA_DATE AS DATA_DATE,
                           T.ORG_NUM AS ORG_NUM,
                           T.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                           T.ACCT_NUM AS ACCT_NUM,
                           SUM(T.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL,
                           SUM(T.SECURITY_AMT) AS SECURITY_AMT,
                           SUM(T.OD_INT) AS OD_INT
                      FROM CBRC_TMP_ACCT_LOAN_G1102 T
                     WHERE T.DATA_DATE = I_DATADATE
                       AND SUBSTR(GUARANTY_TYP, 1, 1) NOT IN ('C', 'D') --去掉保证信用
                     GROUP BY T.DATA_DATE,T.ORG_NUM, T.LOAN_GRADE_CD, T.ACCT_NUM) LOAN
              LEFT JOIN (SELECT DATA_DATE AS DATA_DATE,
                               CONTRACT_NUM AS CONTRACT_NUM,
                               SUM(COLL_MK_VAL) AS COLL_MK_VAL
                          FROM CBRC_TMP_AGRE_GUARANTEE
                         GROUP BY DATA_DATE, CONTRACT_NUM) GUA
                ON LOAN.ACCT_NUM = GUA.CONTRACT_NUM
               AND GUA.DATA_DATE = I_DATADATE
             WHERE LOAN.DATA_DATE = I_DATADATE
               AND LOAN.LOAN_GRADE_CD IN ('3', '4', '5')) --不良资产
     GROUP BY ORG_NUM,
              CASE
                WHEN LOAN_GRADE_CD = '3' THEN
                 'G11_2_1.1.F'
                WHEN LOAN_GRADE_CD = '4' THEN
                 'G11_2_1.1.G'
                WHEN LOAN_GRADE_CD = '5' THEN
                 'G11_2_1.1.H'
              END
) q_8
INSERT INTO `G11_2_1.1.F` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_1.1.G` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_1.1.H` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *;

-- 指标: G11_2_17.2.D.2016
--15万其他应收款的减值取科目1231 放关注
    INSERT 
    INTO `G11_2_17.2.D.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
       SELECT T.ORG_NUM AS ORG_NUM,
             'G11_2_17.2.D.2016'AS COLLECT_TYPE,
             SUM(NVL(T.CREDIT_BAL,0) * U.CCY_RATE) AS COLLECT_VAL
       FROM SMTMODS_L_FINA_GL T
       LEFT JOIN SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
        AND U.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM = '009804'
         AND T.ITEM_CD = '1231'
       GROUP BY T.ORG_NUM;

INSERT  INTO `G11_2_17.2.D.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息 减值
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17.2.H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.BUSI_TYPE LIKE '1%'
       GROUP BY A.ORG_NUM,
                CASE
                   WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                    'G11_2_17.2.C.2016'
                   WHEN A.FIVE_TIER_CLS = '02' THEN
                    'G11_2_17.2.D.2016'
                   WHEN A.FIVE_TIER_CLS = '03' THEN
                    'G11_2_17.2.F.2016'
                   WHEN A.FIVE_TIER_CLS = '04' THEN
                    'G11_2_17.2.G.2016'
                   WHEN A.FIVE_TIER_CLS = '05' THEN
                    'G11_2_17.2.H.2016'
                 END;

--债券投资 应收利息 减值
     INSERT  INTO `G11_2_17.2.D.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM, --机构号
                CASE
                   WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                    'G11_2_17.2.C.2016'
                   WHEN A.FIVE_TIER_CLS = '02' THEN
                    'G11_2_17.2.D.2016'
                   WHEN A.FIVE_TIER_CLS = '03' THEN
                    'G11_2_17.2.F.2016'
                   WHEN A.FIVE_TIER_CLS = '04' THEN
                    'G11_2_17.2.G.2016'
                   WHEN A.FIVE_TIER_CLS = '05' THEN
                    'G11_2_17.2.H.2016'
                 END;

--存放同业 拆放同业的应收 减值
    INSERT 
    INTO `G11_2_17.2.D.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17.2.C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17.2.D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17.2.F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17.2.G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17.2.H.2016'
         END COLLECT_TYPE,
         SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM,
              CASE
                WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                 'G11_2_17.2.C.2016'
                WHEN A.FIVE_TIER_CLS = '02' THEN
                 'G11_2_17.2.D.2016'
                WHEN A.FIVE_TIER_CLS = '03' THEN
                 'G11_2_17.2.F.2016'
                WHEN A.FIVE_TIER_CLS = '04' THEN
                 'G11_2_17.2.G.2016'
                WHEN A.FIVE_TIER_CLS = '05' THEN
                 'G11_2_17.2.H.2016'
              END;

--AC的应收 减值
    INSERT 
    INTO `G11_2_17.2.D.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17.2.C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17.2.D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17.2.F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17.2.G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17.2.H.2016'
           END COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '15010201'
         AND A.ACCOUNTANT_TYPE = '3'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17.2.H.2016'
                END;

--009817：存量非标的应收利息+其他应收款按五级分类划分
    INSERT 
    INTO `G11_2_17.2.D.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17.2.C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17.2.D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17.2.F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17.2.G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17.2.H.2016'
           END COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17.2.H.2016'
                END;

*/

   --ADD BY DJH 20240827 投行前台补录其他应收款的减值

      INSERT 
      INTO `G11_2_17.2.D.2016` 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
        SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17.2.C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17.2.D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17.2.F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17.2.G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17.2.H.2016'
         END COLLECT_TYPE,
         SUM(NVL(A.FINAL_ECL, 0)) AS COLLECT_VAL
          FROM (SELECT 
                 A.ORG_NUM, --机构号
                 C.FIVE_TIER_CLS, --减值五级分类
                 C.FINAL_ECL,
                 A.BOOK_TYPE,
                 C.DATA_SRC
                  FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
                 INNER JOIN CBRC_TMP_ASSET_DEVALUE_TH C --资产减值准备
                    ON C.ACCT_NUM = A.ACCT_NUM
                   AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
                   AND A.ORG_NUM = C.RECORD_ORG
                   AND C.DATA_DATE = I_DATADATE
                 WHERE A.DATA_DATE = I_DATADATE
                   AND NVL(A.PRINCIPAL_BALANCE, 0) <> 0) A --投资业务信息表
         WHERE A.ORG_NUM = '009817'
           AND A.FINAL_ECL <> 0
           AND A.BOOK_TYPE = '2' --银行账薄
           AND A.DATA_SRC = '投行手工补录其他应收款坏账准备'
         GROUP BY A.ORG_NUM,
                  CASE
                    WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                     'G11_2_17.2.C.2016'
                    WHEN A.FIVE_TIER_CLS = '02' THEN
                     'G11_2_17.2.D.2016'
                    WHEN A.FIVE_TIER_CLS = '03' THEN
                     'G11_2_17.2.F.2016'
                    WHEN A.FIVE_TIER_CLS = '04' THEN
                     'G11_2_17.2.G.2016'
                    WHEN A.FIVE_TIER_CLS = '05' THEN
                     'G11_2_17.2.H.2016'
                  END;


-- ========== 逻辑组 10: 共 2 个指标 ==========
FROM (
SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_5.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_5.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_5.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_5.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_5.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL --指标值
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND (SUBSTR(A.STOCK_PRO_TYPE, 1, 1) = 'D' AND A.ISSU_ORG LIKE 'C%')
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_5.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_5.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_5.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_5.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_5.2.H.2016'
                END
) q_10
INSERT INTO `G11_2_5.2.F.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_5.2.C.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *;

-- 指标: G11_2_19..I.2019
INSERT   INTO `G11_2_19..I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    --同业存单 应收利息 逾期
      SELECT A.ORG_NUM,
             'G11_2_19..I.2019' COLLECT_TYPE,
             SUM(A.INTEREST_RECEIVABLE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_CDS_BAL_G1102 A --存单投资与发行信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.DC_DATE < 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM;

INSERT  INTO `G11_2_19..I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息 逾期
      SELECT  T.ORG_NUM,
             'G11_2_19..I.2019'COLLECT_TYPE,
             SUM(T.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.BUSI_TYPE LIKE '1%'
         --AND T.FIVE_TIER_CLS IN ('03','04','05')
         AND T.END_DT - I_DATADATE < 0
         AND T.BOOK_TYPE = '2' --银行账薄
       GROUP BY T.ORG_NUM;

--债券投资 应收利息 逾期
      INSERT 
      INTO `G11_2_19..I.2019` 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
        SELECT  A.ORG_NUM AS ORG_NUM, --机构号
               'G11_2_19..I.2019' AS ITEM_NUM, --指标号
               SUM(NVL(A.ACCRUAL, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
          FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
         WHERE A.DATA_DATE = I_DATADATE
           AND (A.DC_DATE < 0 OR A.SUBJECT_CD = '1523004')
           AND A.BOOK_TYPE = '2' --银行账薄
           AND A.INVEST_TYP = '00'
         GROUP BY A.ORG_NUM;

INSERT 
     INTO `G11_2_19..I.2019` 
       (ORG_NUM, --机构号
        COLLECT_TYPE, --报表类型
        COLLECT_VAL --指标值
        )
       SELECT 
        A.ORG_NUM AS ORG_NUM, --机构号
        'G11_2_19..I.2019' AS ITEM_NUM, --指标号
        SUM(A.DEBIT_BAL + 1400000) AS COLLECT_VAL
         FROM SMTMODS_L_FINA_GL A
         LEFT JOIN SMTMODS_L_PUBL_RATE U
           ON U.CCY_DATE = I_DATADATE
          AND U.BASIC_CCY = A.CURR_CD --基准币种
          AND U.FORWARD_CCY = 'CNY' --折算币种
          AND U.DATA_DATE = I_DATADATE
        WHERE A.DATA_DATE = I_DATADATE
          AND A.ORG_NUM = '009820'
          AND A.ITEM_CD IN ('1221')
          AND A.CURR_CD = 'BWB'
        GROUP BY A.ORG_NUM;

--基金的应收 逾期
    INSERT 
    INTO `G11_2_19..I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           'G11_2_19..I.2019'AS COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP IN ('01')
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
         AND A.ACCRUAL <> 0
       GROUP BY A.ORG_NUM;

--3笔特殊处理的东吴基金管理公司，方正证券，华阳经贸的利息放到逾期
    INSERT 
    INTO `G11_2_19..I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       'G11_2_19..I.2019' AS ITEM_NUM, --指标号
       SUM(NVL(A.ACCRUAL, 0) * U.CCY_RATE) AS COLLECT_VAL
        FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
       WHERE A.SUBJECT_CD IN
            --3笔特殊处理的东吴基金管理公司，方正证券，华阳经贸的利息放到逾期
             ('N000310000012013', 'N000310000008023', 'N000310000012993')
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM;

--存放同业 拆放同业的应收 逾期
    INSERT 
    INTO `G11_2_19..I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         'G11_2_19..I.2019' AS  COLLECT_TYPE,
         SUM(A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
       AND A.FIVE_TIER_CLS IN ('03', '04', '05')
     GROUP BY A.ORG_NUM;

--009817：存量非标的应收利息+其他应收款按五级分类划分  逾期
    INSERT 
    INTO `G11_2_19..I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           'G11_2_19..I.2019'AS COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM;

--信用卡 -逾期
    INSERT  INTO `G11_2_19..I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
        SELECT  '009803' AS ORG_NUM ,
               'G11_2_19..I.2019'  AS COLLECT_TYPE,
                SUM(G.DEBIT_BAL * U.CCY_RATE)
       FROM  SMTMODS_L_FINA_GL G
          LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE G.DATA_DATE= I_DATADATE
            AND G.ORG_NUM ='009803'
            AND G.ITEM_CD IN ('1132');


-- ========== 逻辑组 12: 共 3 个指标 ==========
FROM (
SELECT D.ORG_NUM,
             CASE
               WHEN D.GRADE = '1' THEN --正常类
                'G11_2_17..C.2024'
               WHEN D.GRADE = '2' THEN --关注类
                'G11_2_17..D.2024'
               WHEN D.GRADE = '3' THEN --次级类
                'G11_2_17..F.2024'
               WHEN D.GRADE = '4' THEN --可疑类
                'G11_2_17..G.2024'
               WHEN D.GRADE = '5' THEN --损失类
                'G11_2_17..H.2024'
             END ITEM_NUM,
             SUM(CASE
                   WHEN D.PROTYPE_DIS = '其他同业投资' THEN
                    NVL(D.ACCT_BAL, 0)
                   ELSE
                    NVL(D.ACCT_BAL, 0) + NVL(D.MK_VAL, 0)
                 END) AS ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND (D.ISSU_ORG_NAM NOT LIKE '民生通惠%' OR  D.ISSU_ORG_NAM IS NULL)
         AND SUBSTR(D.INVEST_TYP, 1, 2) IN ('12', '99')
         AND D.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
         AND D.BOOK_TYPE = '2' --银行账薄
         AND D.ORG_NUM <> '009817'
       GROUP BY D.ORG_NUM,
                CASE
                  WHEN D.GRADE = '1' THEN --正常类
                   'G11_2_17..C.2024'
                  WHEN D.GRADE = '2' THEN --关注类
                   'G11_2_17..D.2024'
                  WHEN D.GRADE = '3' THEN --次级类
                   'G11_2_17..F.2024'
                  WHEN D.GRADE = '4' THEN --可疑类
                   'G11_2_17..G.2024'
                  WHEN D.GRADE = '5' THEN --损失类
                   'G11_2_17..H.2024'
                END;

INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             CASE
               WHEN D.FIVE_TIER_CLS = '01' OR D.FIVE_TIER_CLS IS NULL THEN --正常类
                'G11_2_17..C.2024'
               WHEN D.FIVE_TIER_CLS = '02' THEN --关注类
                'G11_2_17..D.2024'
               WHEN D.FIVE_TIER_CLS = '03' THEN --次级类
                'G11_2_17..F.2024'
               WHEN D.FIVE_TIER_CLS = '04' THEN --可疑类
                'G11_2_17..G.2024'
               WHEN D.FIVE_TIER_CLS = '05' THEN --损失类
                'G11_2_17..H.2024'
             END ITEM_NUM,
             SUM(NVL(D.FACE_VAL, 0)) AS ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND (D.ISSU_ORG_NAM NOT LIKE '民生通惠%' OR  D.ISSU_ORG_NAM IS NULL)
         AND SUBSTR(D.INVEST_TYP, 1, 2) IN ('12', '99')
         AND D.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
         AND D.BOOK_TYPE = '2' --银行账薄
         AND D.ORG_NUM = '009817'
       GROUP BY D.ORG_NUM,
                CASE
                   WHEN D.FIVE_TIER_CLS = '01' OR D.FIVE_TIER_CLS IS NULL THEN --正常类
                    'G11_2_17..C.2024'
                   WHEN D.FIVE_TIER_CLS = '02' THEN --关注类
                    'G11_2_17..D.2024'
                   WHEN D.FIVE_TIER_CLS = '03' THEN --次级类
                    'G11_2_17..F.2024'
                   WHEN D.FIVE_TIER_CLS = '04' THEN --可疑类
                    'G11_2_17..G.2024'
                   WHEN D.FIVE_TIER_CLS = '05' THEN --损失类
                    'G11_2_17..H.2024'
                 END
) q_12
INSERT INTO `G11_2_17..C.2024` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_17..H.2024` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_17..F.2024` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *;

-- 指标: G11_2_3..C
INSERT  INTO `G11_2_3..C` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_3..C' --存放同业正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_3..D' --存放同业关注类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_3..F' --存放同业次级类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_3..G' --存放同业可疑类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_3..H' --存放同业损失类
             END COLLECT_TYPE,
             SUM(A.BALANCE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金往来信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '存放同业'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_3..C' --存放同业正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_3..D' --存放同业关注类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_3..F' --存放同业次级类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_3..G' --存放同业可疑类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_3..H' --存放同业损失类
                END,
                ORG_NUM;


-- 指标: G11_2_7..C
INSERT  INTO `G11_2_7..C`  
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  G.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_7..C' COLLECT_TYPE,
             SUM(G.DEBIT_BAL * U.CCY_RATE) COLLECT_VAL
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE 
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ORG_NUM <> '009804'
         AND G.ITEM_CD IN ('70200201',
                           '70200101',
                           '7010',
                           '70400101',
                           '70400103',
                           '70400201',
                           '70400203',
                           '70400102',
                           '70400104',
                           '70400202',
                           '70400204')
       GROUP BY G.ORG_NUM;

INSERT  INTO `G11_2_7..C`  
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_7..C' COLLECT_TYPE,
             SUM(A.AMOUNT * U.CCY_RATE) COLLECT_VAL
        FROM SMTMODS_L_AGRE_BILL_CONTRACT A
       INNER JOIN SMTMODS_L_AGRE_BILL_INFO B
          ON A.BILL_NUM = B.BILL_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = B.CURR_CD -- 基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN CBRC_TMP_ASSET_DEVALUE_S2601 C
          ON A.BILL_NUM = C.ACCT_NUM
         AND C.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND TO_CHAR(B.MATU_DATE, 'YYYYMMDD') > I_DATADATE ---未到期的
         AND A.BUSI_TYPE = 'BT01' ---转贴现
         AND A.STATUS = '2' ---卖出结束
         AND A.ORG_NUM = '009804'
       GROUP BY A.ORG_NUM;


-- ========== 逻辑组 15: 共 2 个指标 ==========
FROM (
SELECT D.ORG_NUM,
             CASE
               WHEN D.GRADE = '1' THEN --正常类
                'G11_2_17.2.C.2024'
               WHEN D.GRADE = '2' THEN --关注类
                'G11_2_17.2.D.2024'
               WHEN D.GRADE = '3' THEN --次级类
                'G11_2_17.2.F.2024'
               WHEN D.GRADE = '4' THEN --可疑类
                'G11_2_17.2.G.2024'
               WHEN D.GRADE = '5' THEN --损失类
                'G11_2_17.2.H.2024'
             END ITEM_NUM,
             SUM(NVL(D.JZJE, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D
       WHERE D.DATA_DATE = I_DATADATE
         AND (D.ISSU_ORG_NAM NOT LIKE '民生通惠%' OR  D.ISSU_ORG_NAM IS NULL)
         AND SUBSTR(D.INVEST_TYP, 1, 2) IN ('12', '99')
         AND D.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
         AND D.BOOK_TYPE = '2' --银行账薄
         AND D.ORG_NUM <> '009817'
         AND D.GL_ITEM_CODE = '15010201'
       GROUP BY D.ORG_NUM,
                CASE
                  WHEN D.GRADE = '1' THEN --正常类
                   'G11_2_17.2.C.2024'
                  WHEN D.GRADE = '2' THEN --关注类
                   'G11_2_17.2.D.2024'
                  WHEN D.GRADE = '3' THEN --次级类
                   'G11_2_17.2.F.2024'
                  WHEN D.GRADE = '4' THEN --可疑类
                   'G11_2_17.2.G.2024'
                  WHEN D.GRADE = '5' THEN --损失类
                   'G11_2_17.2.H.2024'
                END;

INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             CASE
               WHEN D.FIVE_TIER_CLS = '01' OR D.FIVE_TIER_CLS IS NULL THEN --正常类
                'G11_2_17.2.C.2024'
               WHEN D.FIVE_TIER_CLS = '02' THEN --关注类
                'G11_2_17.2.D.2024'
               WHEN D.FIVE_TIER_CLS = '03' THEN --次级类
                'G11_2_17.2.F.2024'
               WHEN D.FIVE_TIER_CLS = '04' THEN --可疑类
                'G11_2_17.2.G.2024'
               WHEN D.FIVE_TIER_CLS = '05' THEN --损失类
                'G11_2_17.2.H.2024'
             END ITEM_NUM,
             SUM(NVL(D.JZJE, 0)) AS ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND (D.ISSU_ORG_NAM NOT LIKE '民生通惠%' OR  D.ISSU_ORG_NAM IS NULL)
         AND SUBSTR(D.INVEST_TYP, 1, 2) IN ('12', '99')
         AND D.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
         AND D.BOOK_TYPE = '2' --银行账薄
         AND D.ORG_NUM = '009817'
       GROUP BY D.ORG_NUM,
                CASE
                   WHEN D.FIVE_TIER_CLS = '01' OR D.FIVE_TIER_CLS IS NULL THEN --正常类
                    'G11_2_17.2.C.2024'
                   WHEN D.FIVE_TIER_CLS = '02' THEN --关注类
                    'G11_2_17.2.D.2024'
                   WHEN D.FIVE_TIER_CLS = '03' THEN --次级类
                    'G11_2_17.2.F.2024'
                   WHEN D.FIVE_TIER_CLS = '04' THEN --可疑类
                    'G11_2_17.2.G.2024'
                   WHEN D.FIVE_TIER_CLS = '05' THEN --损失类
                    'G11_2_17.2.H.2024'
                 END
) q_15
INSERT INTO `G11_2_17.2.F.2024` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_17.2.H.2024` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *;

-- ========== 逻辑组 16: 共 4 个指标 ==========
FROM (
SELECT 
       T.ORG_NUM AS ORG_NUM, --机构号
       CASE
         WHEN T.FIVE_TIER_CLS = '01' THEN
          'G11_2_1.2.C'
         WHEN T.FIVE_TIER_CLS IS NULL THEN
          'G11_2_1.2.C'
         WHEN T.FIVE_TIER_CLS = '02' THEN
          'G11_2_1.2.D'
         WHEN T.FIVE_TIER_CLS = '03' THEN
          'G11_2_1.2.F'
         WHEN T.FIVE_TIER_CLS = '04' THEN
          'G11_2_1.2.G'
         WHEN T.FIVE_TIER_CLS = '05' THEN
          'G11_2_1.2.H'
       END AS ITEM_NUM, --指标号
       SUM(NVL(T.JZJE, 0)) AS COLLECT_VAL
        FROM CBRC_TMP_ACCT_LOAN_G1102 T
       WHERE T.DATA_DATE = I_DATADATE
         AND NOT EXISTS (SELECT 1
                FROM CBRC_TMP_ACCT_LOAN_G1102 A
               WHERE A.LOAN_NUM = T.LOAN_NUM
                 AND A.DATA_DATE = I_DATADATE
                 AND A.ORG_NUM = '009804' --剔除金融市场部正常减值数据，从科目40030216里取数据
                 AND A.LOAN_GRADE_CD = '1'
                 )
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN T.FIVE_TIER_CLS = '01' THEN
                   'G11_2_1.2.C'
                  WHEN T.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_1.2.C'
                  WHEN T.FIVE_TIER_CLS = '02' THEN
                   'G11_2_1.2.D'
                  WHEN T.FIVE_TIER_CLS = '03' THEN
                   'G11_2_1.2.F'
                  WHEN T.FIVE_TIER_CLS = '04' THEN
                   'G11_2_1.2.G'
                  WHEN T.FIVE_TIER_CLS = '05' THEN
                   'G11_2_1.2.H'
                END;

INSERT 
    INTO `__INDICATOR_PLACEHOLDER__` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      
            SELECT '009803' org_num,
                   'G11_2_1.2.D' COLLECT_TYPE,
               SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE * 0.03 ) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
           AND T.LXQKQS between 1 and 3
           union all
           SELECT '009803' org_num,
                   'G11_2_1.2.F' COLLECT_TYPE,
               SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE * 0.26 ) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
           AND T.LXQKQS =4
            union all
           SELECT '009803' org_num,
                   'G11_2_1.2.G' COLLECT_TYPE,
               SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE * 0.51 ) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
           AND T.LXQKQS between 5 and 6
             union all
           SELECT '009803' org_num,
                   'G11_2_1.2.H' COLLECT_TYPE,
               SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 U.CCY_RATE  ) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
           AND T.LXQKQS >=7;

--新增信用卡逻辑JLBA202412040012
       INSERT 
    INTO `__INDICATOR_PLACEHOLDER__` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
       SELECT  ORG_NUM , COLLECT_TYPE ,SUM(COLLECT_VAL) FROM (
       SELECT  '009803' ORG_NUM,
             'G11_2_1.2.C' AS COLLECT_TYPE,
             SUM(CASE WHEN G.ITEM_CD ='1304' THEN G.CREDIT_BAL
                  WHEN G.ITEM_CD ='130407' THEN G.CREDIT_BAL*-1 END * U.CCY_RATE) AS COLLECT_VAL

       FROM  SMTMODS_L_FINA_GL G
          LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE G.DATA_DATE= I_DATADATE
            AND G.ORG_NUM ='009803'
            AND G.ITEM_CD IN ('1304','130407')
       UNION ALL

         SELECT  '009803' ORG_NUM,
                  'G11_2_1.2.C' AS COLLECT_TYPE,
                  SUM(T.COLLECT_VAL) * -1  AS COLLECT_VAL
          FROM  CBRC_PUB_DATA_COLLECT_G1102 T
           WHERE T.COLLECT_TYPE IN ('G11_2_1.2.D','G11_2_1.2.F','G11_2_1.2.G','G11_2_1.2.H')
           ) AA
           GROUP BY ORG_NUM , COLLECT_TYPE
) q_16
INSERT INTO `G11_2_1.2.D` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_1.2.F` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_1.2.H` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_1.2.G` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *;

-- 指标: G11_2_12.2.C.2016
INSERT  INTO `G11_2_12.2.C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_12.2.C.2016' --14.购买同业存单正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_12.2.D.2016' --14.购买同业存单关注类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_12.2.F.2016' --14.购买同业存单次级类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_12.2.G.2016' --14.购买同业存单可疑类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_12.2.H.2016' --14.购买同业存单损失类
             END COLLECT_TYPE,
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_CDS_BAL_G1102 A --存单投资与发行信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_12.2.C.2016' --14.购买同业存单正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_12.2.D.2016' --14.购买同业存单关注类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_12.2.F.2016' --14.购买同业存单次级类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_12.2.G.2016' --14.购买同业存单可疑类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_12.2.H.2016' --14.购买同业存单损失类
                END;


-- 指标: G11_2_12..C.2016
INSERT   INTO `G11_2_12..C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_12..C.2016' --14.购买同业存单正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_12..D.2016' --14.购买同业存单关注类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_12..F.2016' --14.购买同业存单次级类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_12..G.2016' --14.购买同业存单可疑类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_12..H.2016' --14.购买同业存单损失类
             END COLLECT_TYPE,
             SUM(A.PRINCIPAL_BALANCE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_CDS_BAL_G1102 A --存单投资与发行信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_12..C.2016' --14.购买同业存单正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_12..D.2016' --14.购买同业存单关注类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_12..F.2016' --14.购买同业存单次级类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_12..G.2016' --14.购买同业存单可疑类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_12..H.2016' --14.购买同业存单损失类
                END;


-- 指标: G11_2_12..I.2019
INSERT  INTO `G11_2_12..I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             'G11_2_12..I.2019'  COLLECT_TYPE,
             SUM(A.BALANCE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_MMFUND_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '拆放同业'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.MATURE_DATE - I_DATADATE < 0
         --AND A.FIVE_TIER_CLS IN ( '03','04','05')
       GROUP BY ORG_NUM;


-- 指标: G11_2_6..I.2019
INSERT 
    INTO `G11_2_6..I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       'G11_2_6..I.2019' AS ITEM_NUM, --指标号
       SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND (SUBSTR(A.STOCK_PRO_TYPE, 1, 1) = 'D' AND A.ISSU_ORG LIKE 'C%')
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND (A.DC_DATE < 0 OR A.SUBJECT_CD = 'X0003120B2700001')  -- 18华阳经贸CP001 特殊处理指定放在逾期
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM;


-- 指标: G11_2_3..C.2016
INSERT  INTO `G11_2_3..C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_3..C.2016'
               WHEN A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_3..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_3..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_3..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_3..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_3..H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.STOCK_PRO_TYPE = 'A'
         AND A.ISSU_ORG = 'A02'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_3..C.2016'
                  WHEN A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_3..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_3..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_3..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_3..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_3..H.2016'
                END;


-- 指标: G11_2_12.2.I.2019
INSERT  INTO `G11_2_12.2.I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             'G11_2_12.2.I.2019',
             SUM(NVL(A.JZJE,0)) BALANCE
        FROM CBRC_TMP_FUND_MMFUND_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '拆放同业'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.MATURE_DATE - I_DATADATE < 0
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
       GROUP BY A.ORG_NUM;


-- 指标: G11_2_26..A.2024
--债券
    INSERT  INTO `G11_2_26..A.2024` 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..A.2024' AS COLLECT_TYPE,
           SUM(A.PRINCIPAL_BALANCE + A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.INVEST_TYP = '00'
       AND A.BOOK_TYPE = '1' --交易账薄
    GROUP BY A.ORG_NUM;

--资金往来
    INSERT  INTO `G11_2_26..A.2024` 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..A.2024' AS COLLECT_TYPE,
           SUM(A.BALANCE + A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '1' --交易账薄
    GROUP BY A.ORG_NUM;

--回购
    INSERT  INTO `G11_2_26..A.2024` 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..A.2024' AS COLLECT_TYPE,
           SUM(A.BALANCE + A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '1' --交易账薄
       AND A.BUSI_TYPE LIKE '1%'
    GROUP BY A.ORG_NUM;

--存单
    INSERT  INTO `G11_2_26..A.2024` 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..A.2024' AS COLLECT_TYPE,
           SUM(A.PRINCIPAL_BALANCE + A.INTEREST_RECEIVABLE) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_CDS_BAL_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '1' --交易账薄
    GROUP BY A.ORG_NUM;

--理财 信托 基金 资产管理 等
    INSERT  INTO `G11_2_26..A.2024` 
    (ORG_NUM, --机构号
     COLLECT_TYPE, --报表类型
     COLLECT_VAL --指标值
    )
    SELECT A.ORG_NUM AS ORG_NUM,
           'G11_2_26..A.2024' AS COLLECT_TYPE,
           --SUM(A.ACCT_BAL + A.ACCRUAL) AS COLLECT_VAL
           SUM(
           CASE
             WHEN A.INVEST_TYP IN ('12', '99') AND A.PROTYPE_DIS = '其他同业投资' THEN A.ACCT_BAL
             WHEN A.INVEST_TYP = '04'                  THEN A.FACE_VAL + A.MK_VAL
             WHEN A.INVEST_TYP IN ('12', '99', '01', '15') THEN A.ACCT_BAL + A.MK_VAL
             ELSE A.FACE_VAL
           END) AS COLLECT_VAL
      FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '1' --交易账薄
       AND SUBSTR(A.INVEST_TYP,1,2) IN ('05','04','01','12','99','15')
    GROUP BY A.ORG_NUM;


-- 指标: G11_2_17.2.H.2016
INSERT  INTO `G11_2_17.2.H.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息 减值
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17.2.H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.BUSI_TYPE LIKE '1%'
       GROUP BY A.ORG_NUM,
                CASE
                   WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                    'G11_2_17.2.C.2016'
                   WHEN A.FIVE_TIER_CLS = '02' THEN
                    'G11_2_17.2.D.2016'
                   WHEN A.FIVE_TIER_CLS = '03' THEN
                    'G11_2_17.2.F.2016'
                   WHEN A.FIVE_TIER_CLS = '04' THEN
                    'G11_2_17.2.G.2016'
                   WHEN A.FIVE_TIER_CLS = '05' THEN
                    'G11_2_17.2.H.2016'
                 END;

--债券投资 应收利息 减值
     INSERT  INTO `G11_2_17.2.H.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM, --机构号
                CASE
                   WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                    'G11_2_17.2.C.2016'
                   WHEN A.FIVE_TIER_CLS = '02' THEN
                    'G11_2_17.2.D.2016'
                   WHEN A.FIVE_TIER_CLS = '03' THEN
                    'G11_2_17.2.F.2016'
                   WHEN A.FIVE_TIER_CLS = '04' THEN
                    'G11_2_17.2.G.2016'
                   WHEN A.FIVE_TIER_CLS = '05' THEN
                    'G11_2_17.2.H.2016'
                 END;

--存放同业 拆放同业的应收 减值
    INSERT 
    INTO `G11_2_17.2.H.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17.2.C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17.2.D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17.2.F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17.2.G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17.2.H.2016'
         END COLLECT_TYPE,
         SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM,
              CASE
                WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                 'G11_2_17.2.C.2016'
                WHEN A.FIVE_TIER_CLS = '02' THEN
                 'G11_2_17.2.D.2016'
                WHEN A.FIVE_TIER_CLS = '03' THEN
                 'G11_2_17.2.F.2016'
                WHEN A.FIVE_TIER_CLS = '04' THEN
                 'G11_2_17.2.G.2016'
                WHEN A.FIVE_TIER_CLS = '05' THEN
                 'G11_2_17.2.H.2016'
              END;

--AC的应收 减值
    INSERT 
    INTO `G11_2_17.2.H.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17.2.C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17.2.D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17.2.F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17.2.G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17.2.H.2016'
           END COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '15010201'
         AND A.ACCOUNTANT_TYPE = '3'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17.2.H.2016'
                END;

--损失:140万固定值+其他应收款应收1221科目
     INSERT 
     INTO `G11_2_17.2.H.2016` 
       (ORG_NUM, --机构号
        COLLECT_TYPE, --报表类型
        COLLECT_VAL --指标值
        )
       SELECT 
        A.ORG_NUM AS ORG_NUM, --机构号
        'G11_2_17.2.H.2016' AS ITEM_NUM, --指标号
        SUM(A.DEBIT_BAL + 1400000) AS COLLECT_VAL
         FROM SMTMODS_L_FINA_GL A
         LEFT JOIN SMTMODS_L_PUBL_RATE U
           ON U.CCY_DATE = I_DATADATE
          AND U.BASIC_CCY = A.CURR_CD --基准币种
          AND U.FORWARD_CCY = 'CNY' --折算币种
          AND U.DATA_DATE = I_DATADATE
        WHERE A.DATA_DATE = I_DATADATE
          AND A.ORG_NUM = '009820'
          AND A.ITEM_CD IN ('1221')
          AND A.CURR_CD = 'BWB'
        GROUP BY A.ORG_NUM;

--009817：存量非标的应收利息+其他应收款按五级分类划分
    INSERT 
    INTO `G11_2_17.2.H.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17.2.C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17.2.D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17.2.F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17.2.G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17.2.H.2016'
           END COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17.2.H.2016'
                END;

*/

   --ADD BY DJH 20240827 投行前台补录其他应收款的减值

      INSERT 
      INTO `G11_2_17.2.H.2016` 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
        SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17.2.C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17.2.D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17.2.F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17.2.G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17.2.H.2016'
         END COLLECT_TYPE,
         SUM(NVL(A.FINAL_ECL, 0)) AS COLLECT_VAL
          FROM (SELECT 
                 A.ORG_NUM, --机构号
                 C.FIVE_TIER_CLS, --减值五级分类
                 C.FINAL_ECL,
                 A.BOOK_TYPE,
                 C.DATA_SRC
                  FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
                 INNER JOIN CBRC_TMP_ASSET_DEVALUE_TH C --资产减值准备
                    ON C.ACCT_NUM = A.ACCT_NUM
                   AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
                   AND A.ORG_NUM = C.RECORD_ORG
                   AND C.DATA_DATE = I_DATADATE
                 WHERE A.DATA_DATE = I_DATADATE
                   AND NVL(A.PRINCIPAL_BALANCE, 0) <> 0) A --投资业务信息表
         WHERE A.ORG_NUM = '009817'
           AND A.FINAL_ECL <> 0
           AND A.BOOK_TYPE = '2' --银行账薄
           AND A.DATA_SRC = '投行手工补录其他应收款坏账准备'
         GROUP BY A.ORG_NUM,
                  CASE
                    WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                     'G11_2_17.2.C.2016'
                    WHEN A.FIVE_TIER_CLS = '02' THEN
                     'G11_2_17.2.D.2016'
                    WHEN A.FIVE_TIER_CLS = '03' THEN
                     'G11_2_17.2.F.2016'
                    WHEN A.FIVE_TIER_CLS = '04' THEN
                     'G11_2_17.2.G.2016'
                    WHEN A.FIVE_TIER_CLS = '05' THEN
                     'G11_2_17.2.H.2016'
                  END;


-- ========== 逻辑组 25: 共 2 个指标 ==========
FROM (
SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_10.2.C.2016' --拆放同业减值准备正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_10.2.D.2016' --拆放同业减值准备正常类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_10.2.F.2016' --拆放同业减值准备正常类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_10.2.G.2016' --拆放同业减值准备正常类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_10.2.H.2016' --拆放同业减值准备正常类
             END,
             SUM(NVL(A.JZJE,0)) BALANCE
        FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '拆放同业'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_10.2.C.2016' --拆放同业减值准备正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_10.2.D.2016' --拆放同业减值准备正常类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_10.2.F.2016' --拆放同业减值准备正常类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_10.2.G.2016' --拆放同业减值准备正常类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_10.2.H.2016' --拆放同业减值准备正常类
                END
) q_25
INSERT INTO `G11_2_10.2.C.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_10.2.H.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *;

-- 指标: G11_2_3.2.C
INSERT  INTO `G11_2_3.2.C` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_3.2.C' --存放同业正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_3.2.D' --存放同业关注类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_3.2.F' --存放同业次级类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_3.2.G' --存放同业可疑类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_3.2.H' --存放同业损失类
             END COLLECT_TYPE,
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金往来信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '存放同业'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_3.2.C' --存放同业正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_3.2.D' --存放同业关注类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_3.2.F' --存放同业次级类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_3.2.G' --存放同业可疑类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_3.2.H' --存放同业损失类
                END,
                ORG_NUM;


-- 指标: G11_2_1.1.I.2019
--贷款保证金和抵质押品价值逾期
    INSERT 
    INTO `G11_2_1.1.I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
     ORG_NUM AS ORG_NUM,
     'G11_2_1.1.I.2019' AS ITEM_NUM, --指标号
     SUM(CASE
           WHEN NVL(SECURITY_AMT, 0) + NVL(COLL_MK_VAL, 0) > NVL(LOAN_ACCT_BAL, 0) + NVL(OD_INT, 0) THEN
            NVL(LOAN_ACCT_BAL, 0) + NVL(OD_INT, 0)
           ELSE
            NVL(SECURITY_AMT, 0) + NVL(COLL_MK_VAL, 0)
         END) AS COLLECT_VAL
      FROM (SELECT 
             LOAN.DATA_DATE AS DATA_DATE,
             LOAN.ORG_NUM AS ORG_NUM, --机构号
             LOAN.LOAN_GRADE_CD AS LOAN_GRADE_CD,
             NVL(GUA.COLL_MK_VAL, 0) AS COLL_MK_VAL,
             LOAN.SECURITY_AMT AS SECURITY_AMT,
             LOAN.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,
             LOAN.OD_INT AS OD_INT,
             LOAN.ACCT_NUM AS ACCT_NUM
              FROM (SELECT A.DATA_DATE AS DATA_DATE,
                           A.ORG_NUM AS ORG_NUM,
                           A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                           A.ACCT_NUM AS ACCT_NUM,
                           SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL,
                           SUM(A.SECURITY_AMT) AS SECURITY_AMT,
                           SUM(A.OD_INT) AS OD_INT
                      FROM CBRC_TMP_ACCT_LOAN_G1102 A
                     WHERE A.OD_DAYS <= 90
                       AND A.OD_DAYS > 0
                       AND A.OD_FLG = 'Y'
                       AND A.DATA_DATE = I_DATADATE
                       AND ORG_NUM <> '009803'
                       AND (ACCT_TYP NOT LIKE '0101%' AND ACCT_TYP NOT LIKE '0103%' AND ACCT_TYP NOT LIKE '0104%' AND
                            ACCT_TYP NOT LIKE '0199%' AND ACCT_TYP NOT IN ('E01', 'E02') AND ACCT_TYP NOT LIKE '90%')
                       AND A.GL_ITEM_CODE NOT LIKE '130105%'
                       AND SUBSTR(GUARANTY_TYP, 1, 1) NOT IN ('C', 'D') --去掉保证信用
                     GROUP BY A.DATA_DATE, A.ORG_NUM, A.LOAN_GRADE_CD, A.ACCT_NUM

                    UNION ALL

                    SELECT A.DATA_DATE AS DATA_DATE,
                           A.ORG_NUM AS ORG_NUM,
                           A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                           A.ACCT_NUM AS ACCT_NUM,
                           SUM(CASE --JLBA202412040012
                                 WHEN A.PAY_TYPE  IN ('01', '02','10','11')  AND B.REPAY_TYP ='1' THEN
                                  NVL(A.OD_LOAN_ACCT_BAL, 0)
                                 ELSE
                                  NVL(A.LOAN_ACCT_BAL, 0)
                               END) AS LOAN_ACCT_BAL,
                           SUM(A.SECURITY_AMT) AS SECURITY_AMT,
                           SUM(A.OD_INT) AS OD_INT
                      FROM CBRC_TMP_ACCT_LOAN_G1102 A
                      LEFT JOIN SMTMODS_L_ACCT_LOAN B
                         ON A.LOAN_NUM =B.LOAN_NUM
                        AND B.DATA_DATE  = I_DATADATE
                     WHERE A.OD_DAYS > 0
                       AND A.OD_DAYS <= 90
                       AND A.OD_FLG = 'Y'
                       AND A.DATA_DATE = I_DATADATE
                       AND (A.ACCT_TYP LIKE '0101%' OR A.ACCT_TYP LIKE '0103%' OR A.ACCT_TYP LIKE '0104%' OR
                            A.ACCT_TYP LIKE '0199%') AND A.ACCT_TYP NOT LIKE '90%'
                       AND A.GL_ITEM_CODE NOT LIKE '130105%'
                       AND SUBSTR(A.GUARANTY_TYP, 1, 1) NOT IN ('C', 'D') --去掉保证信用
                       AND A.ORG_NUM <> '009803'
                     GROUP BY A.DATA_DATE, A.ORG_NUM, A.LOAN_GRADE_CD, A.ACCT_NUM

                    UNION ALL

                    SELECT A.DATA_DATE AS DATA_DATE,
                           A.ORG_NUM AS ORG_NUM,
                           A.LOAN_GRADE_CD AS LOAN_GRADE_CD,
                           A.ACCT_NUM AS ACCT_NUM,
                           SUM(A.LOAN_ACCT_BAL) AS LOAN_ACCT_BAL,
                           SUM(A.SECURITY_AMT) AS SECURITY_AMT,
                           SUM(A.OD_INT) AS OD_INT
                      FROM CBRC_TMP_ACCT_LOAN_G1102 A
                     WHERE A.OD_FLG = 'Y'
                       AND A.DATA_DATE = I_DATADATE
                       AND (A.OD_DAYS > 90 OR A.OD_DAYS IS NULL)
                       AND SUBSTR(GUARANTY_TYP, 1, 1) NOT IN ('C', 'D') --去掉保证信用
                       AND A.ACCT_TYP NOT LIKE '90%'
                     GROUP BY A.DATA_DATE, A.ORG_NUM, A.LOAN_GRADE_CD, A.ACCT_NUM) LOAN
              LEFT JOIN (SELECT DATA_DATE AS DATA_DATE,
                               CONTRACT_NUM AS CONTRACT_NUM,
                               SUM(COLL_MK_VAL) AS COLL_MK_VAL
                          FROM CBRC_TMP_AGRE_GUARANTEE
                         GROUP BY DATA_DATE, CONTRACT_NUM) GUA
                ON LOAN.ACCT_NUM = GUA.CONTRACT_NUM
               AND GUA.DATA_DATE = I_DATADATE
             WHERE LOAN.DATA_DATE = I_DATADATE
               ) --不良资产
     GROUP BY ORG_NUM;

---信用卡 1.1保证金和抵质押品价值I列取：逾期贷款(M1+M2...+M6+)
   --alter by 20241217 JLBA202412040012

    INSERT 
    INTO `G11_2_1.1.I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT '009803' AS ORG_NUM,
             'G11_2_1.1.I.2019' AS COLLECT_TYPE,
             --M4 + M5 + M6 + M6_UP AS ITEM_VAL,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS COLLECT_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
          AND  LXQKQS >= 1;


-- 指标: G11_2_4..C.2016
INSERT  INTO `G11_2_4..C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_4..C.2016'
               WHEN A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_4..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_4..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_4..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_4..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_4..H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND ((SUBSTR(A.STOCK_PRO_TYPE, 1, 1) = 'B' AND A.ISSU_ORG = 'D01') OR
             (A.STOCK_PRO_TYPE LIKE 'C%' AND A.ISSU_ORG = 'D02') OR
             (SUBSTR(A.STOCK_PRO_TYPE, 1, 1) IN ('C', 'D') AND
             A.ISSU_ORG LIKE 'B%'))
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
      GROUP BY A.ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_4..C.2016'
               WHEN A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_4..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_4..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_4..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_4..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_4..H.2016'
             END;


-- 指标: G11_2_6.2.I.2019
INSERT  INTO `G11_2_6.2.I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_6.2.I.2019'  AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL --指标值
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND (SUBSTR(A.STOCK_PRO_TYPE, 1, 1) = 'D' AND A.ISSU_ORG LIKE 'C%')
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND (A.DC_DATE < 0 OR A.SUBJECT_CD = 'X0003120B2700001')  -- 18华阳经贸CP001 特殊处理指定放在逾期
       GROUP BY A.ORG_NUM;


-- 指标: G11_2_3.2.C.2016
INSERT  INTO `G11_2_3.2.C.2016`  
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_3.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_3.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_3.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_3.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_3.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.STOCK_PRO_TYPE = 'A'
         AND A.ISSU_ORG = 'A02'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_3.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_3.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_3.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_3.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_3.2.H.2016'
                END;


-- 指标: G11_2_2..C.2016
INSERT  INTO `G11_2_2..C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_2..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_2..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_2..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_2..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_2..H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00' --债券
         AND A.STOCK_PRO_TYPE = 'A'
         AND A.ISSU_ORG = 'A01'
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_2..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_2..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_2..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_2..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_2..H.2016'
                END;


-- 指标: G11_2_19.2.I.2019
INSERT  INTO `G11_2_19.2.I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息 减值 逾期
      SELECT  A.ORG_NUM,
             'G11_2_19.2.I.2019' AS  COLLECT_TYPE,
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BUSI_TYPE LIKE '1%'
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.END_DT - I_DATADATE < 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM;

--债券投资 应收利息 减值 逾期
     INSERT  INTO `G11_2_19.2.I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_19.2.I.2019' AS ITEM_NUM, --指标号
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM;

--存放同业 拆放同业的应收 减值 逾期
    INSERT 
    INTO `G11_2_19.2.I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         'G11_2_19.2.I.2019' AS  COLLECT_TYPE,
         SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
       --AND A.FIVE_TIER_CLS IN ('03','04','05')
       AND A.MATURE_DATE - I_DATADATE < 0
     GROUP BY A.ORG_NUM;

INSERT INTO `G11_2_19.2.I.2019`
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
     A.ORG_NUM AS ORG_NUM, --机构号
     'G11_2_19.2.I.2019' AS ITEM_NUM, --指标号
     SUM((NVL(C.COLLBL_INT_FINAL_RESLT, 0)) * U.CCY_RATE) AS COLLECT_VAL
      FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
       AND U.DATA_DATE = I_DATADATE
      LEFT JOIN CBRC_TMP_ASSET_DEVALUE C --资产减值准备
        ON C.ACCT_NUM = A.SUBJECT_CD
       AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
       AND A.ORG_NUM = C.RECORD_ORG
       AND C.DATA_DATE = I_DATADATE
     WHERE A.SUBJECT_CD IN
          --3笔特殊处理的东吴基金管理公司，方正证券，华阳经贸的利息放到逾期
           ('N000310000012013', 'N000310000008023', 'N000310000012993')
       AND A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM;

--逾期:140万固定值+其他应收款应收1221科目
     INSERT 
     INTO `G11_2_19.2.I.2019` 
       (ORG_NUM, --机构号
        COLLECT_TYPE, --报表类型
        COLLECT_VAL --指标值
        )
       SELECT 
        A.ORG_NUM AS ORG_NUM, --机构号
        'G11_2_19.2.I.2019' AS ITEM_NUM, --指标号
        SUM(A.DEBIT_BAL + 1400000) AS COLLECT_VAL
         FROM SMTMODS_L_FINA_GL A
         LEFT JOIN SMTMODS_L_PUBL_RATE U
           ON U.CCY_DATE = I_DATADATE
          AND U.BASIC_CCY = A.CURR_CD --基准币种
          AND U.FORWARD_CCY = 'CNY' --折算币种
          AND U.DATA_DATE = I_DATADATE
        WHERE A.DATA_DATE = I_DATADATE
          AND A.ORG_NUM = '009820'
          AND A.ITEM_CD IN ('1221')
          AND A.CURR_CD = 'BWB'
        GROUP BY A.ORG_NUM;

--009817：存量非标的应收利息+其他应收款按五级分类划分  逾期
    INSERT 
    INTO `G11_2_19.2.I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           'G11_2_19.2.I.2019'AS COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
       GROUP BY A.ORG_NUM;

--其他应收款的减值取科目12310101其他应收款坏账准备贷方，放次级
    INSERT \*+ append*\
    INTO CBRC_PUB_DATA_COLLECT_G1102 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
       SELECT T.ORG_NUM AS ORG_NUM,
             'G11_2_19.2.I.2019'AS COLLECT_TYPE,
             SUM(NVL(T.CREDIT_BAL,0) * U.CCY_RATE) AS COLLECT_VAL
       FROM SMTMODS_L_FINA_GL T
       LEFT JOIN SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
        AND U.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM = '009817'
         AND T.ITEM_CD = '12310101'
       GROUP BY T.ORG_NUM;

INSERT 
      INTO `G11_2_19.2.I.2019` 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
        SELECT 
         A.ORG_NUM,
         'G11_2_19.2.I.2019' AS COLLECT_TYPE, 
         SUM(NVL(A.FINAL_ECL, 0)) AS COLLECT_VAL
          FROM (SELECT 
                 A.ORG_NUM, --机构号
                 C.FIVE_TIER_CLS, --减值五级分类
                 C.FINAL_ECL,
                 A.BOOK_TYPE,
                 C.DATA_SRC,
                 A.DC_DATE
                  FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
                 INNER JOIN CBRC_TMP_ASSET_DEVALUE_TH C --资产减值准备
                    ON C.ACCT_NUM = A.ACCT_NUM
                   AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
                   AND A.ORG_NUM = C.RECORD_ORG
                   AND C.DATA_DATE = I_DATADATE
                 WHERE A.DATA_DATE = I_DATADATE
                   AND NVL(A.PRINCIPAL_BALANCE, 0) <> 0) A --投资业务信息表
         WHERE A.ORG_NUM = '009817'
           AND A.FINAL_ECL <> 0
           AND A.BOOK_TYPE = '2' --银行账薄
           AND A.DATA_SRC = '投行手工补录其他应收款坏账准备'
           AND DC_DATE < 0
          GROUP BY A.ORG_NUM;


-- 指标: G11_2_1.2.C
--贷款减值
    INSERT 
    INTO `G11_2_1.2.C` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       T.ORG_NUM AS ORG_NUM, --机构号
       CASE
         WHEN T.FIVE_TIER_CLS = '01' THEN
          'G11_2_1.2.C'
         WHEN T.FIVE_TIER_CLS IS NULL THEN
          'G11_2_1.2.C'
         WHEN T.FIVE_TIER_CLS = '02' THEN
          'G11_2_1.2.D'
         WHEN T.FIVE_TIER_CLS = '03' THEN
          'G11_2_1.2.F'
         WHEN T.FIVE_TIER_CLS = '04' THEN
          'G11_2_1.2.G'
         WHEN T.FIVE_TIER_CLS = '05' THEN
          'G11_2_1.2.H'
       END AS ITEM_NUM, --指标号
       SUM(NVL(T.JZJE, 0)) AS COLLECT_VAL
        FROM CBRC_TMP_ACCT_LOAN_G1102 T
       WHERE T.DATA_DATE = I_DATADATE
         AND NOT EXISTS (SELECT 1
                FROM CBRC_TMP_ACCT_LOAN_G1102 A
               WHERE A.LOAN_NUM = T.LOAN_NUM
                 AND A.DATA_DATE = I_DATADATE
                 AND A.ORG_NUM = '009804' --剔除金融市场部正常减值数据，从科目40030216里取数据
                 AND A.LOAN_GRADE_CD = '1'
                 )
       GROUP BY T.ORG_NUM,
                CASE
                  WHEN T.FIVE_TIER_CLS = '01' THEN
                   'G11_2_1.2.C'
                  WHEN T.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_1.2.C'
                  WHEN T.FIVE_TIER_CLS = '02' THEN
                   'G11_2_1.2.D'
                  WHEN T.FIVE_TIER_CLS = '03' THEN
                   'G11_2_1.2.F'
                  WHEN T.FIVE_TIER_CLS = '04' THEN
                   'G11_2_1.2.G'
                  WHEN T.FIVE_TIER_CLS = '05' THEN
                   'G11_2_1.2.H'
                END;

--金融市场部正常减值数据，从科目40030216里取数据
    INSERT 
    INTO `G11_2_1.2.C` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
       '009804' AS ORG_NUM, --机构号
       'G11_2_1.2.C' COLLECT_TYPE,
       SUM(G.CREDIT_BAL * U.CCY_RATE) COLLECT_VAL
        FROM SMTMODS_L_FINA_GL G
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ORG_NUM = '009804'
         AND G.ITEM_CD IN ('40030216');

--新增信用卡逻辑JLBA202412040012
       INSERT 
    INTO `G11_2_1.2.C` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
       SELECT  ORG_NUM , COLLECT_TYPE ,SUM(COLLECT_VAL) FROM (
       SELECT  '009803' ORG_NUM,
             'G11_2_1.2.C' AS COLLECT_TYPE,
             SUM(CASE WHEN G.ITEM_CD ='1304' THEN G.CREDIT_BAL
                  WHEN G.ITEM_CD ='130407' THEN G.CREDIT_BAL*-1 END * U.CCY_RATE) AS COLLECT_VAL

       FROM  SMTMODS_L_FINA_GL G
          LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE G.DATA_DATE= I_DATADATE
            AND G.ORG_NUM ='009803'
            AND G.ITEM_CD IN ('1304','130407')
       UNION ALL

         SELECT  '009803' ORG_NUM,
                  'G11_2_1.2.C' AS COLLECT_TYPE,
                  SUM(T.COLLECT_VAL) * -1  AS COLLECT_VAL
          FROM  CBRC_PUB_DATA_COLLECT_G1102 T
           WHERE T.COLLECT_TYPE IN ('G11_2_1.2.D','G11_2_1.2.F','G11_2_1.2.G','G11_2_1.2.H')
           ) AA
           GROUP BY ORG_NUM , COLLECT_TYPE;


-- 指标: G11_2_16..I.2019
INSERT INTO `G11_2_16..I.2019`
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT '009804' AS ORG_NUM, --机构号
             'G11_2_16..I.2019' AS ITEM_NUM, --指标号
             SUM(A.FACE_VAL) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '15010201' --债权投资特定目的载体投资投资成本
         AND A.ORG_NUM = '009804'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '04' --信托
         AND A.GRADE IN ('3', '4', '5');


-- ========== 逻辑组 35: 共 2 个指标 ==========
FROM (
SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE
         WHEN A.FIVE_TIER_CLS = '01' THEN
          'G11_2_5..C.2016'
         WHEN A.FIVE_TIER_CLS IS NULL THEN
          'G11_2_5..C.2016'
         WHEN A.FIVE_TIER_CLS = '02' THEN
          'G11_2_5..D.2016'
         WHEN A.FIVE_TIER_CLS = '03' THEN
          'G11_2_5..F.2016'
         WHEN A.FIVE_TIER_CLS = '04' THEN
          'G11_2_5..G.2016'
         WHEN A.FIVE_TIER_CLS = '05' THEN
          'G11_2_5..H.2016'
       END AS ITEM_NUM, --指标号
       SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
         AND (SUBSTR(A.STOCK_PRO_TYPE, 1, 1) = 'D' AND A.ISSU_ORG LIKE 'C%')
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_5..C.2016'
                  WHEN A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_5..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_5..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_5..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_5..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_5..H.2016'
                END
) q_35
INSERT INTO `G11_2_5..F.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_5..C.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *;

-- 指标: G11_2_16..C.2024
INSERT INTO `G11_2_16..C.2024`
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             CASE
               WHEN D.GRADE = '1' THEN --正常类
                'G11_2_16..C.2024'
               WHEN D.GRADE = '2' THEN --关注类
                'G11_2_16..D.2024'
               WHEN D.GRADE = '3' THEN --次级类
                'G11_2_16..F.2024'
               WHEN D.GRADE = '4' THEN --可疑类
                'G11_2_16..G.2024'
               WHEN D.GRADE = '5' THEN --损失类
                'G11_2_16..H.2024'
             END ITEM_NUM,
             SUM(NVL(D.ACCT_BAL, 0) + NVL(D.MK_VAL, 0)) ITEM_VALUE
             --SUM(NVL(D.FACE_VAL, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND D.INVEST_TYP =  '01' --基金
         AND D.BOOK_TYPE = '2' --银行账薄
       GROUP BY D.ORG_NUM,
                CASE
                  WHEN D.GRADE = '1' THEN --正常类
                   'G11_2_16..C.2024'
                  WHEN D.GRADE = '2' THEN --关注类
                   'G11_2_16..D.2024'
                  WHEN D.GRADE = '3' THEN --次级类
                   'G11_2_16..F.2024'
                  WHEN D.GRADE = '4' THEN --可疑类
                   'G11_2_16..G.2024'
                  WHEN D.GRADE = '5' THEN --损失类
                   'G11_2_16..H.2024'
                END;


-- 指标: G11_2_17.2.G.2016
INSERT  INTO `G11_2_17.2.G.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息 减值
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17.2.H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.BUSI_TYPE LIKE '1%'
       GROUP BY A.ORG_NUM,
                CASE
                   WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                    'G11_2_17.2.C.2016'
                   WHEN A.FIVE_TIER_CLS = '02' THEN
                    'G11_2_17.2.D.2016'
                   WHEN A.FIVE_TIER_CLS = '03' THEN
                    'G11_2_17.2.F.2016'
                   WHEN A.FIVE_TIER_CLS = '04' THEN
                    'G11_2_17.2.G.2016'
                   WHEN A.FIVE_TIER_CLS = '05' THEN
                    'G11_2_17.2.H.2016'
                 END;

--债券投资 应收利息 减值
     INSERT  INTO `G11_2_17.2.G.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM, --机构号
                CASE
                   WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                    'G11_2_17.2.C.2016'
                   WHEN A.FIVE_TIER_CLS = '02' THEN
                    'G11_2_17.2.D.2016'
                   WHEN A.FIVE_TIER_CLS = '03' THEN
                    'G11_2_17.2.F.2016'
                   WHEN A.FIVE_TIER_CLS = '04' THEN
                    'G11_2_17.2.G.2016'
                   WHEN A.FIVE_TIER_CLS = '05' THEN
                    'G11_2_17.2.H.2016'
                 END;

--存放同业 拆放同业的应收 减值
    INSERT 
    INTO `G11_2_17.2.G.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17.2.C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17.2.D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17.2.F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17.2.G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17.2.H.2016'
         END COLLECT_TYPE,
         SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM,
              CASE
                WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                 'G11_2_17.2.C.2016'
                WHEN A.FIVE_TIER_CLS = '02' THEN
                 'G11_2_17.2.D.2016'
                WHEN A.FIVE_TIER_CLS = '03' THEN
                 'G11_2_17.2.F.2016'
                WHEN A.FIVE_TIER_CLS = '04' THEN
                 'G11_2_17.2.G.2016'
                WHEN A.FIVE_TIER_CLS = '05' THEN
                 'G11_2_17.2.H.2016'
              END;

--AC的应收 减值
    INSERT 
    INTO `G11_2_17.2.G.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17.2.C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17.2.D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17.2.F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17.2.G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17.2.H.2016'
           END COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '15010201'
         AND A.ACCOUNTANT_TYPE = '3'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17.2.H.2016'
                END;

--009817：存量非标的应收利息+其他应收款按五级分类划分
    INSERT 
    INTO `G11_2_17.2.G.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17.2.C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17.2.D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17.2.F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17.2.G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17.2.H.2016'
           END COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17.2.H.2016'
                END;

*/

   --ADD BY DJH 20240827 投行前台补录其他应收款的减值

      INSERT 
      INTO `G11_2_17.2.G.2016` 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
        SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17.2.C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17.2.D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17.2.F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17.2.G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17.2.H.2016'
         END COLLECT_TYPE,
         SUM(NVL(A.FINAL_ECL, 0)) AS COLLECT_VAL
          FROM (SELECT 
                 A.ORG_NUM, --机构号
                 C.FIVE_TIER_CLS, --减值五级分类
                 C.FINAL_ECL,
                 A.BOOK_TYPE,
                 C.DATA_SRC
                  FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
                 INNER JOIN CBRC_TMP_ASSET_DEVALUE_TH C --资产减值准备
                    ON C.ACCT_NUM = A.ACCT_NUM
                   AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
                   AND A.ORG_NUM = C.RECORD_ORG
                   AND C.DATA_DATE = I_DATADATE
                 WHERE A.DATA_DATE = I_DATADATE
                   AND NVL(A.PRINCIPAL_BALANCE, 0) <> 0) A --投资业务信息表
         WHERE A.ORG_NUM = '009817'
           AND A.FINAL_ECL <> 0
           AND A.BOOK_TYPE = '2' --银行账薄
           AND A.DATA_SRC = '投行手工补录其他应收款坏账准备'
         GROUP BY A.ORG_NUM,
                  CASE
                    WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                     'G11_2_17.2.C.2016'
                    WHEN A.FIVE_TIER_CLS = '02' THEN
                     'G11_2_17.2.D.2016'
                    WHEN A.FIVE_TIER_CLS = '03' THEN
                     'G11_2_17.2.F.2016'
                    WHEN A.FIVE_TIER_CLS = '04' THEN
                     'G11_2_17.2.G.2016'
                    WHEN A.FIVE_TIER_CLS = '05' THEN
                     'G11_2_17.2.H.2016'
                  END;


-- ========== 逻辑组 38: 共 2 个指标 ==========
FROM (
SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_10..C.2016' --拆放同业正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_10..D.2016' --拆放同业关注类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_10..F.2016' --拆放同业次级类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_10..G.2016' --拆放同业可疑类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_10..H.2016' --拆放同业损失类
             END COLLECT_TYPE,
             SUM(A.BALANCE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.TAG = '拆放同业'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_10..C.2016' --拆放同业正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_10..D.2016' --拆放同业关注类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_10..F.2016' --拆放同业次级类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_10..G.2016' --拆放同业可疑类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_10..H.2016' --拆放同业损失类
                END,
                ORG_NUM
) q_38
INSERT INTO `G11_2_10..C.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_10..H.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *;

-- ========== 逻辑组 39: 共 2 个指标 ==========
FROM (
SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       CASE
         WHEN A.FIVE_TIER_CLS = '01' THEN
          'G11_2_6..C.2016'
         WHEN A.FIVE_TIER_CLS IS NULL THEN
          'G11_2_6..C.2016'
         WHEN A.FIVE_TIER_CLS = '02' THEN
          'G11_2_6..D.2016'
         WHEN A.FIVE_TIER_CLS = '03' THEN
          'G11_2_6..F.2016'
         WHEN A.FIVE_TIER_CLS = '04' THEN
          'G11_2_6..G.2016'
         WHEN A.FIVE_TIER_CLS = '05' THEN
          'G11_2_6..H.2016'
       END AS ITEM_NUM, --指标号
       SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
            --20221221 shiyu  与G31保持一致
         AND (A.STOCK_PRO_TYPE LIKE 'C%' AND A.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07'))
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' THEN
                   'G11_2_6..C.2016'
                  WHEN A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_6..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_6..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_6..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_6..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_6..H.2016'
                END
) q_39
INSERT INTO `G11_2_6..F.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_6..C.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *;

-- 指标: G11_2_11.2.C.2016
INSERT  INTO `G11_2_11.2.C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS is null THEN
                'G11_2_11.2.C.2016' --13.金融机构间买入返售资产减值准备正常类
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_11.2.D.2016' --13.金融机构间买入返售资产减值准备关注类
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_11.2.F.2016' --13.金融机构间买入返售资产减值准备次级类
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_11.2.G.2016' --13.金融机构间买入返售资产减值准备可疑类
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_11.2.H.2016' --13.金融机构间买入返售资产减值准备损失类
             END COLLECT_TYPE,
             SUM(NVL(A.JZJE, 0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.BUSI_TYPE LIKE '1%'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS is null THEN
                   'G11_2_11.2.C.2016' --13.金融机构间买入返售资产减值准备正常类
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_11.2.D.2016' --13.金融机构间买入返售资产减值准备关注类
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_11.2.F.2016' --13.金融机构间买入返售资产减值准备次级类
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_11.2.G.2016' --13.金融机构间买入返售资产减值准备可疑类
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_11.2.H.2016' --13.金融机构间买入返售资产减值准备损失类
                END;


-- 指标: G11_2_17..D.2016
INSERT  INTO `G11_2_17..D.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    --同业存单 应收利息
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(A.INTEREST_RECEIVABLE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_CDS_BAL_G1102 A --存单投资与发行信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

INSERT  INTO `G11_2_17..D.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BUSI_TYPE LIKE '1%'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--债券投资 应收利息
   INSERT  INTO `G11_2_17..D.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.ACCRUAL, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--从总账取的应收
      INSERT 
      INTO `G11_2_17..D.2016` 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
        SELECT G.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN (G.ITEM_CD = '12210202') THEN 'G11_2_17..C.2016'
                 WHEN G.ITEM_CD = '12210201' THEN 'G11_2_17..D.2016'
               END AS COLLECT_TYPE,
               SUM(G.DEBIT_BAL * U.CCY_RATE) COLLECT_VAL
          FROM SMTMODS_L_FINA_GL G
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = G.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY'
           AND U.DATA_DATE = I_DATADATE
         WHERE G.DATA_DATE = I_DATADATE
           AND G.ORG_NUM = '009804'
           AND (G.ITEM_CD IN ('12210202','12210201'))
         GROUP BY G.ORG_NUM,
                CASE
                  WHEN (G.ITEM_CD = '12210202') THEN 'G11_2_17..C.2016'
                  WHEN  G.ITEM_CD = '12210201'  THEN 'G11_2_17..D.2016'
                END;

--基金的应收
    INSERT 
    INTO `G11_2_17..D.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17..C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17..D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17..F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17..G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17..H.2016'
           END COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP IN ('01')
         AND A.ACCRUAL <> 0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--存放同业 拆放同业的应收
    INSERT 
    INTO `G11_2_17..D.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17..C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17..D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17..F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17..G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17..H.2016'
         END COLLECT_TYPE,
         SUM(A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM,
              CASE
                WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                 'G11_2_17..C.2016'
                WHEN A.FIVE_TIER_CLS = '02' THEN
                 'G11_2_17..D.2016'
                WHEN A.FIVE_TIER_CLS = '03' THEN
                 'G11_2_17..F.2016'
                WHEN A.FIVE_TIER_CLS = '04' THEN
                 'G11_2_17..G.2016'
                WHEN A.FIVE_TIER_CLS = '05' THEN
                 'G11_2_17..H.2016'
              END;

--009817：存量非标的应收利息+其他应收款按五级分类划分
    INSERT 
    INTO `G11_2_17..D.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17..C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17..D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17..F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17..G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17..H.2016'
           END COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--009820 AC账户 应收利息
   INSERT  INTO `G11_2_17..D.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.ACCRUAL, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.ORG_NUM = '009820'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '3' --AC账户
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;


-- 指标: G11_2_17.2.C.2016
INSERT  INTO `G11_2_17.2.C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息 减值
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17.2.H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.BUSI_TYPE LIKE '1%'
       GROUP BY A.ORG_NUM,
                CASE
                   WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                    'G11_2_17.2.C.2016'
                   WHEN A.FIVE_TIER_CLS = '02' THEN
                    'G11_2_17.2.D.2016'
                   WHEN A.FIVE_TIER_CLS = '03' THEN
                    'G11_2_17.2.F.2016'
                   WHEN A.FIVE_TIER_CLS = '04' THEN
                    'G11_2_17.2.G.2016'
                   WHEN A.FIVE_TIER_CLS = '05' THEN
                    'G11_2_17.2.H.2016'
                 END;

--债券投资 应收利息 减值
     INSERT  INTO `G11_2_17.2.C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.COLLBL_INT_FINAL_RESLT, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM, --机构号
                CASE
                   WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                    'G11_2_17.2.C.2016'
                   WHEN A.FIVE_TIER_CLS = '02' THEN
                    'G11_2_17.2.D.2016'
                   WHEN A.FIVE_TIER_CLS = '03' THEN
                    'G11_2_17.2.F.2016'
                   WHEN A.FIVE_TIER_CLS = '04' THEN
                    'G11_2_17.2.G.2016'
                   WHEN A.FIVE_TIER_CLS = '05' THEN
                    'G11_2_17.2.H.2016'
                 END;

--存放同业 拆放同业的应收 减值
    INSERT 
    INTO `G11_2_17.2.C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17.2.C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17.2.D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17.2.F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17.2.G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17.2.H.2016'
         END COLLECT_TYPE,
         SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM,
              CASE
                WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                 'G11_2_17.2.C.2016'
                WHEN A.FIVE_TIER_CLS = '02' THEN
                 'G11_2_17.2.D.2016'
                WHEN A.FIVE_TIER_CLS = '03' THEN
                 'G11_2_17.2.F.2016'
                WHEN A.FIVE_TIER_CLS = '04' THEN
                 'G11_2_17.2.G.2016'
                WHEN A.FIVE_TIER_CLS = '05' THEN
                 'G11_2_17.2.H.2016'
              END;

--AC的应收 减值
    INSERT 
    INTO `G11_2_17.2.C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17.2.C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17.2.D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17.2.F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17.2.G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17.2.H.2016'
           END COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '15010201'
         AND A.ACCOUNTANT_TYPE = '3'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17.2.H.2016'
                END;

--009817：存量非标的应收利息+其他应收款按五级分类划分
    INSERT 
    INTO `G11_2_17.2.C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17.2.C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17.2.D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17.2.F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17.2.G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17.2.H.2016'
           END COLLECT_TYPE,
           SUM(NVL(A.COLLBL_INT_FINAL_RESLT,0)) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17.2.C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17.2.D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17.2.F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17.2.G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17.2.H.2016'
                END;

*/

   --ADD BY DJH 20240827 投行前台补录其他应收款的减值

      INSERT 
      INTO `G11_2_17.2.C.2016` 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
        SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17.2.C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17.2.D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17.2.F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17.2.G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17.2.H.2016'
         END COLLECT_TYPE,
         SUM(NVL(A.FINAL_ECL, 0)) AS COLLECT_VAL
          FROM (SELECT 
                 A.ORG_NUM, --机构号
                 C.FIVE_TIER_CLS, --减值五级分类
                 C.FINAL_ECL,
                 A.BOOK_TYPE,
                 C.DATA_SRC
                  FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
                 INNER JOIN CBRC_TMP_ASSET_DEVALUE_TH C --资产减值准备
                    ON C.ACCT_NUM = A.ACCT_NUM
                   AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
                   AND A.ORG_NUM = C.RECORD_ORG
                   AND C.DATA_DATE = I_DATADATE
                 WHERE A.DATA_DATE = I_DATADATE
                   AND NVL(A.PRINCIPAL_BALANCE, 0) <> 0) A --投资业务信息表
         WHERE A.ORG_NUM = '009817'
           AND A.FINAL_ECL <> 0
           AND A.BOOK_TYPE = '2' --银行账薄
           AND A.DATA_SRC = '投行手工补录其他应收款坏账准备'
         GROUP BY A.ORG_NUM,
                  CASE
                    WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                     'G11_2_17.2.C.2016'
                    WHEN A.FIVE_TIER_CLS = '02' THEN
                     'G11_2_17.2.D.2016'
                    WHEN A.FIVE_TIER_CLS = '03' THEN
                     'G11_2_17.2.F.2016'
                    WHEN A.FIVE_TIER_CLS = '04' THEN
                     'G11_2_17.2.G.2016'
                    WHEN A.FIVE_TIER_CLS = '05' THEN
                     'G11_2_17.2.H.2016'
                  END;

--alter by 20241217 JLBA202412040012信用卡 21.2减值准备C列取：业务状况表（本外币合并）科目“130407”
      INSERT 
      INTO `G11_2_17.2.C.2016` 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
          SELECT  '009803' org_num,
                  'G11_2_17.2.C.2016' as COLLECT_TYPE,
                  sum(g.CREDIT_BAL *u.ccy_rate)

       FROM  SMTMODS_L_FINA_GL G
          LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE G.DATA_DATE= I_DATADATE
            AND G.ORG_NUM ='009803'
            AND G.ITEM_CD IN ('130407');


-- 指标: G11_2_17..C.2016
INSERT  INTO `G11_2_17..C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    --同业存单 应收利息
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(A.INTEREST_RECEIVABLE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_CDS_BAL_G1102 A --存单投资与发行信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

INSERT  INTO `G11_2_17..C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BUSI_TYPE LIKE '1%'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--债券投资 应收利息
   INSERT  INTO `G11_2_17..C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.ACCRUAL, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--从总账取的应收
      INSERT 
      INTO `G11_2_17..C.2016` 
        (ORG_NUM, --机构号
         COLLECT_TYPE, --报表类型
         COLLECT_VAL --指标值
         )
        SELECT G.ORG_NUM AS ORG_NUM, --机构号
               CASE
                 WHEN (G.ITEM_CD = '12210202') THEN 'G11_2_17..C.2016'
                 WHEN G.ITEM_CD = '12210201' THEN 'G11_2_17..D.2016'
               END AS COLLECT_TYPE,
               SUM(G.DEBIT_BAL * U.CCY_RATE) COLLECT_VAL
          FROM SMTMODS_L_FINA_GL G
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = G.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY'
           AND U.DATA_DATE = I_DATADATE
         WHERE G.DATA_DATE = I_DATADATE
           AND G.ORG_NUM = '009804'
           AND (G.ITEM_CD IN ('12210202','12210201'))
         GROUP BY G.ORG_NUM,
                CASE
                  WHEN (G.ITEM_CD = '12210202') THEN 'G11_2_17..C.2016'
                  WHEN  G.ITEM_CD = '12210201'  THEN 'G11_2_17..D.2016'
                END;

--基金的应收
    INSERT 
    INTO `G11_2_17..C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17..C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17..D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17..F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17..G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17..H.2016'
           END COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP IN ('01')
         AND A.ACCRUAL <> 0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--存放同业 拆放同业的应收
    INSERT 
    INTO `G11_2_17..C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17..C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17..D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17..F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17..G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17..H.2016'
         END COLLECT_TYPE,
         SUM(A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM,
              CASE
                WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                 'G11_2_17..C.2016'
                WHEN A.FIVE_TIER_CLS = '02' THEN
                 'G11_2_17..D.2016'
                WHEN A.FIVE_TIER_CLS = '03' THEN
                 'G11_2_17..F.2016'
                WHEN A.FIVE_TIER_CLS = '04' THEN
                 'G11_2_17..G.2016'
                WHEN A.FIVE_TIER_CLS = '05' THEN
                 'G11_2_17..H.2016'
              END;

--009817：存量非标的应收利息+其他应收款按五级分类划分
    INSERT 
    INTO `G11_2_17..C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17..C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17..D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17..F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17..G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17..H.2016'
           END COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--009820 AC账户 应收利息
   INSERT  INTO `G11_2_17..C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.ACCRUAL, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.ORG_NUM = '009820'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '3' --AC账户
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--009816：G01资产负债项目统计表 5.应收利息+11.其他应收款；正常类取归并项  配置公式

---alter by 20241217 JLBA202412040012新增信用卡应收利息和其他应收款C列取：业务状况表（本外币合并）科目“1132”加科目“1221”


     --信用卡
     INSERT  INTO `G11_2_17..C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
        SELECT  '009803' AS ORG_NUM ,
               'G11_2_17..C.2016' AS COLLECT_TYPE,
                SUM(G.DEBIT_BAL * U.CCY_RATE)
       FROM  SMTMODS_L_FINA_GL G
          LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = G.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE G.DATA_DATE= I_DATADATE
            AND G.ORG_NUM ='009803'
            AND G.ITEM_CD IN ('1132','1221');


-- 指标: G11_2_6.2.C.2016
INSERT  INTO `G11_2_6.2.C.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_6.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_6.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_6.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_6.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_6.2.H.2016'
             END AS ITEM_NUM, --指标号
             SUM(NVL(A.JZJE, 0)) ITEM_VALUE
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
            --20221221 shiyu  与G31保持一致
         AND (A.STOCK_PRO_TYPE LIKE 'C%' AND
             A.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07'))
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.DATA_DATE = I_DATADATE
      GROUP BY A.ORG_NUM, --机构号
             CASE
               WHEN A.FIVE_TIER_CLS = '01' THEN
                'G11_2_6.2.C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_6.2.D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_6.2.F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_6.2.G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_6.2.H.2016'
             END;


-- ========== 逻辑组 45: 共 2 个指标 ==========
FROM (
SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(A.INTEREST_RECEIVABLE) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_CDS_BAL_G1102 A --存单投资与发行信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

INSERT  INTO `__INDICATOR_PLACEHOLDER__` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      --买入返售 应收利息
      SELECT  A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_FUND_REPURCHASE_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BUSI_TYPE LIKE '1%'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--债券投资 应收利息
   INSERT  INTO `__INDICATOR_PLACEHOLDER__` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.ACCRUAL, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--基金的应收
    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17..C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17..D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17..F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17..G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17..H.2016'
           END COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         AND A.INVEST_TYP IN ('01')
         AND A.ACCRUAL <> 0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--存放同业 拆放同业的应收
    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
         A.ORG_NUM,
         CASE
           WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
            'G11_2_17..C.2016'
           WHEN A.FIVE_TIER_CLS = '02' THEN
            'G11_2_17..D.2016'
           WHEN A.FIVE_TIER_CLS = '03' THEN
            'G11_2_17..F.2016'
           WHEN A.FIVE_TIER_CLS = '04' THEN
            'G11_2_17..G.2016'
           WHEN A.FIVE_TIER_CLS = '05' THEN
            'G11_2_17..H.2016'
         END COLLECT_TYPE,
         SUM(A.ACCRUAL) AS COLLECT_VAL
      FROM CBRC_TMP_FUND_MMFUND_G1102 A --资金交易信息表
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ACCRUAL <> 0
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM,
              CASE
                WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                 'G11_2_17..C.2016'
                WHEN A.FIVE_TIER_CLS = '02' THEN
                 'G11_2_17..D.2016'
                WHEN A.FIVE_TIER_CLS = '03' THEN
                 'G11_2_17..F.2016'
                WHEN A.FIVE_TIER_CLS = '04' THEN
                 'G11_2_17..G.2016'
                WHEN A.FIVE_TIER_CLS = '05' THEN
                 'G11_2_17..H.2016'
              END;

--009817：存量非标的应收利息+其他应收款按五级分类划分
    INSERT 
    INTO `__INDICATOR_PLACEHOLDER__` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM,
           CASE
             WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
              'G11_2_17..C.2016'
             WHEN A.FIVE_TIER_CLS = '02' THEN
              'G11_2_17..D.2016'
             WHEN A.FIVE_TIER_CLS = '03' THEN
              'G11_2_17..F.2016'
             WHEN A.FIVE_TIER_CLS = '04' THEN
              'G11_2_17..G.2016'
             WHEN A.FIVE_TIER_CLS = '05' THEN
              'G11_2_17..H.2016'
           END COLLECT_TYPE,
           SUM(A.ACCRUAL) AS COLLECT_VAL
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.ACCRUAL <> 0
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END;

--009820 AC账户 应收利息
   INSERT  INTO `__INDICATOR_PLACEHOLDER__` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM,
             CASE
               WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                'G11_2_17..C.2016'
               WHEN A.FIVE_TIER_CLS = '02' THEN
                'G11_2_17..D.2016'
               WHEN A.FIVE_TIER_CLS = '03' THEN
                'G11_2_17..F.2016'
               WHEN A.FIVE_TIER_CLS = '04' THEN
                'G11_2_17..G.2016'
               WHEN A.FIVE_TIER_CLS = '05' THEN
                'G11_2_17..H.2016'
             END COLLECT_TYPE,
             SUM(NVL(A.ACCRUAL, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.ORG_NUM = '009820'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '3' --AC账户
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.FIVE_TIER_CLS = '01' OR A.FIVE_TIER_CLS IS NULL THEN
                   'G11_2_17..C.2016'
                  WHEN A.FIVE_TIER_CLS = '02' THEN
                   'G11_2_17..D.2016'
                  WHEN A.FIVE_TIER_CLS = '03' THEN
                   'G11_2_17..F.2016'
                  WHEN A.FIVE_TIER_CLS = '04' THEN
                   'G11_2_17..G.2016'
                  WHEN A.FIVE_TIER_CLS = '05' THEN
                   'G11_2_17..H.2016'
                END
) q_45
INSERT INTO `G11_2_17..F.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *
INSERT INTO `G11_2_17..G.2016` (ORG_NUM,  
       COLLECT_TYPE,  
       COLLECT_VAL)
SELECT *;

-- 指标: G11_2_1..I.2019
--逾期
    INSERT 
    INTO `G11_2_1..I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL, --指标值
       TAG
       )
      SELECT 
       A.ORG_NUM AS ORG_NUM, --机构号
       'G11_2_1..I.2019' AS ITEM_NUM, --指标号
       SUM(NVL(A.LOAN_ACCT_BAL, 0)) AS COLLECT_VAL, --指标值
       '资金买断式转贴逾期' AS TAG
        FROM CBRC_TMP_ACCT_LOAN_G1102 A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.LOAN_GRADE_CD IN ('3', '4', '5')
         AND A.TAG = '资金买断式转贴'
       GROUP BY A.ORG_NUM;

/* 以下逻辑处理逾期贷款总数 逻辑*/
    INSERT 
    INTO `G11_2_1..I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT ORG_NUM AS ORG_NUM,
             'G11_2_1..I.2019' AS ITEM_NUM,
             SUM(NVL(LOAN_ACCT_BAL, 0)) AS ITEM_VAL
        FROM CBRC_TMP_ACCT_LOAN_G1102 A
       WHERE OD_DAYS <= 90
         AND OD_DAYS > 0
         AND OD_FLG = 'Y'
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND ORG_NUM <> '009803'
         AND (ACCT_TYP NOT LIKE '0101%' AND ACCT_TYP NOT LIKE '0103%' AND
              ACCT_TYP NOT LIKE '0104%' AND ACCT_TYP NOT LIKE '0199%' AND
              ACCT_TYP NOT IN ('E01', 'E02') AND ACCT_TYP NOT LIKE '90%')
         AND A.GL_ITEM_CODE NOT LIKE '130105%'
       GROUP BY ORG_NUM;

/* 还款方式 变更为 1 2  等额本息 等额本金  */
    INSERT 
    INTO `G11_2_1..I.2019` 

      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT a.ORG_NUM AS ORG_NUM,
             'G11_2_1..I.2019' AS ITEM_NUM,
             SUM(CASE  --JLBA202412040012
                   WHEN A.PAY_TYPE  IN ('01', '02','10','11')  and  b.REPAY_TYP ='1' THEN NVL(a.OD_LOAN_ACCT_BAL,0)
                   ELSE NVL(a.LOAN_ACCT_BAL,0)
                 END) AS ITEM_VAL
        FROM CBRC_TMP_ACCT_LOAN_G1102 A
         left join SMTMODS_L_ACCT_LOAN b
           on  a.loan_num =b.loan_num
            and b.data_date = I_DATADATE
       WHERE a.OD_DAYS > 0
         AND a.OD_DAYS <= 90
         AND a.OD_FLG = 'Y'
         AND a.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         --0101  个人住房贷款 0103  个人消费贷款 0104  个人助学贷款 0199  其他个人类贷款
         AND (a.ACCT_TYP LIKE '0101%' OR a.ACCT_TYP LIKE '0103%' OR
             a.ACCT_TYP LIKE '0104%' OR
             a.ACCT_TYP LIKE '0199%' )
             AND a.ACCT_TYP NOT LIKE '90%'
         AND A.GL_ITEM_CODE NOT LIKE '130105%'
         AND a.ORG_NUM <> '009803'
       GROUP BY a.ORG_NUM;

INSERT 
    INTO `G11_2_1..I.2019` 

      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT A.ORG_NUM AS ORG_NUM,
             'G11_2_1..I.2019' AS ITEM_NUM,
             SUM(NVL(LOAN_ACCT_BAL, 0)) AS ITEM_VAL
        FROM CBRC_TMP_ACCT_LOAN_G1102 A
       WHERE A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND (A.OD_DAYS > 90 OR A.OD_DAYS IS NULL)
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.ACCT_TYP NOT LIKE '90%'
       GROUP BY ORG_NUM;

--信用卡逾期JLBA202412040012
    INSERT 
    INTO `G11_2_1..I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL, --指标值
       TAG
       )
      SELECT '009803' AS ORG_NUM,
             'G11_2_1..I.2019' AS ITEM_NUM,
             --M4 + M5 + M6 + M6_UP AS ITEM_VAL,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) AS ITEM_VAL,
             '信用卡逾期'
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
          AND  LXQKQS >= 1;


-- 指标: G11_2_17.2.I.2024
INSERT INTO `G11_2_17.2.I.2024`
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
    SELECT 
     A.ORG_NUM AS ORG_NUM, --机构号
     'G11_2_17.2.I.2024' AS ITEM_NUM, --指标号
     SUM((NVL(C.PRIN_FINAL_RESLT, 0) + NVL(C.OFBS_FINAL_RESLT, 0)) * U.CCY_RATE) AS COLLECT_VAL
      FROM CBRC_V_PUB_FUND_INVEST A --投资业务信息表 A
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
       AND U.DATA_DATE = I_DATADATE
      LEFT JOIN CBRC_TMP_ASSET_DEVALUE C --资产减值准备
        ON C.ACCT_NUM = A.SUBJECT_CD
       AND A.GL_ITEM_CODE = C.PRIN_SUBJ_NO
       AND A.ORG_NUM = C.RECORD_ORG
       AND C.DATA_DATE = I_DATADATE
     WHERE A.SUBJECT_CD IN
          --3笔特殊处理的东吴基金管理公司，方正证券，华阳经贸的利息放到逾期
           ('N000310000012013', 'N000310000008023', 'N000310000012993')
       AND A.DATA_DATE = I_DATADATE
       AND A.BOOK_TYPE = '2' --银行账薄
     GROUP BY A.ORG_NUM;

INSERT INTO `G11_2_17.2.I.2024`
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT D.ORG_NUM,
             'G11_2_17.2.I.2024' ITEM_NUM,
             SUM(NVL(D.JZJE, 0)) AS ITEM_VALUE
        FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 D --投资业务信息表
       WHERE D.DATA_DATE = I_DATADATE
         AND SUBSTR(D.INVEST_TYP, 1, 2) IN ('12', '99')
         AND D.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
         AND (D.ISSU_ORG_NAM NOT LIKE '民生通惠%' OR  D.ISSU_ORG_NAM IS NULL)
         AND D.BOOK_TYPE = '2' --银行账薄
         AND D.ORG_NUM = '009817'
       GROUP BY D.ORG_NUM;


-- 指标: G11_2_16..F.2016
INSERT 
    INTO `G11_2_16..F.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM AS ORG_NUM, --机构号
           CASE
             WHEN A.GRADE = '1' THEN
              'G11_2_16..C.2016'
             WHEN A.GRADE IS NULL THEN
              'G11_2_16..C.2016'
             WHEN A.GRADE = '2' THEN
              'G11_2_16..D.2016'
             WHEN A.GRADE = '3' THEN
              'G11_2_16..F.2016'
             WHEN A.GRADE = '4' THEN
              'G11_2_16..G.2016'
             WHEN A.GRADE = '5' THEN
              'G11_2_16..H.2016'
           END AS ITEM_NUM, --指标号
           SUM(A.FACE_VAL) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
       FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.ACCT_NUM IN ('N000310000012723','N000310000012748')
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.GRADE = '1' THEN
                   'G11_2_16..C.2016'
                  WHEN A.GRADE IS NULL THEN
                   'G11_2_16..C.2016'
                  WHEN A.GRADE = '2' THEN
                   'G11_2_16..D.2016'
                  WHEN A.GRADE = '3' THEN
                   'G11_2_16..F.2016'
                  WHEN A.GRADE = '4' THEN
                   'G11_2_16..G.2016'
                  WHEN A.GRADE = '5' THEN
                   'G11_2_16..H.2016'
                END;


-- 指标: G11_2_16.2.F.2016
INSERT 
    INTO `G11_2_16.2.F.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM AS ORG_NUM, --机构号
           CASE
             WHEN A.GRADE = '1' THEN
              'G11_2_16.2.C.2016'
             WHEN A.GRADE IS NULL THEN
              'G11_2_16.2.C.2016'
             WHEN A.GRADE = '2' THEN
              'G11_2_16.2.D.2016'
             WHEN A.GRADE = '3' THEN
              'G11_2_16.2.F.2016'
             WHEN A.GRADE = '4' THEN
              'G11_2_16.2.G.2016'
             WHEN A.GRADE = '5' THEN
              'G11_2_16.2.H.2016'
           END AS ITEM_NUM, --指标号
           SUM(A.JZJE) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
       FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '01'
         AND A.FUNDS_TYPE LIKE 'B%'
         AND A.DATA_DATE = I_DATADATE
         AND A.IN_OFF_FLG = '1'
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.GRADE = '1' THEN
                   'G11_2_16.2.C.2016'
                  WHEN A.GRADE IS NULL THEN
                   'G11_2_16.2.C.2016'
                  WHEN A.GRADE = '2' THEN
                   'G11_2_16.2.D.2016'
                  WHEN A.GRADE = '3' THEN
                   'G11_2_16.2.F.2016'
                  WHEN A.GRADE = '4' THEN
                   'G11_2_16.2.G.2016'
                  WHEN A.GRADE = '5' THEN
                   'G11_2_16.2.H.2016'
                END;

INSERT 
    INTO `G11_2_16.2.F.2016` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT 
           A.ORG_NUM AS ORG_NUM, --机构号
           CASE
             WHEN A.GRADE = '1' THEN
              'G11_2_16.2.C.2016'
             WHEN A.GRADE IS NULL THEN
              'G11_2_16.2.C.2016'
             WHEN A.GRADE = '2' THEN
              'G11_2_16.2.D.2016'
             WHEN A.GRADE = '3' THEN
              'G11_2_16.2.F.2016'
             WHEN A.GRADE = '4' THEN
              'G11_2_16.2.G.2016'
             WHEN A.GRADE = '5' THEN
              'G11_2_16.2.H.2016'
           END AS ITEM_NUM, --指标号
           SUM(A.JZJE) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
       FROM CBRC_TMP_INVEST_OTHER_SUBJECT_G1102 A --投资业务信息表
       WHERE A.ACCT_NUM IN ('N000310000012723','N000310000012748')
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
       GROUP BY A.ORG_NUM, --机构号
                CASE
                  WHEN A.GRADE = '1' THEN
                   'G11_2_16.2.C.2016'
                  WHEN A.GRADE IS NULL THEN
                   'G11_2_16.2.C.2016'
                  WHEN A.GRADE = '2' THEN
                   'G11_2_16.2.D.2016'
                  WHEN A.GRADE = '3' THEN
                   'G11_2_16.2.F.2016'
                  WHEN A.GRADE = '4' THEN
                   'G11_2_16.2.G.2016'
                  WHEN A.GRADE = '5' THEN
                   'G11_2_16.2.H.2016'
                END;


-- 指标: G11_2_5..I.2019
INSERT  INTO `G11_2_5..I.2019` 
      (ORG_NUM, --机构号
       COLLECT_TYPE, --报表类型
       COLLECT_VAL --指标值
       )
      SELECT  A.ORG_NUM AS ORG_NUM, --机构号
             'G11_2_5..I.2019' AS ITEM_NUM, --指标号
             SUM(NVL(A.PRINCIPAL_BALANCE, 0)) AS COLLECT_VAL --指标值，A.账面余额（折人民币）
        FROM CBRC_TMP_INVEST_BOND_INFO_G1102 A --投资业务信息表
       WHERE A.INVEST_TYP = '00'
            --20221221 shiyu  与G31保持一致
         AND (A.STOCK_PRO_TYPE LIKE 'C%' AND A.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07'))
         AND A.STOCK_ASSET_TYPE IS NULL
         AND A.ISSUER_INLAND_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND A.BOOK_TYPE = '2' --银行账薄
         --AND A.FIVE_TIER_CLS IN ('03','04','05')
         AND A.DC_DATE < 0
        GROUP BY A.ORG_NUM;


