-- ============================================================
-- 文件名: G31_II投资业务情况表.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: G31_II_5.a.B.2019
--资管计划中取FVTPL账户的利息收益
   INSERT INTO `G31_II_5.a.B.2019`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.a.B.2019' AS ITEM_NUM,
             SUM(NVL(A.THISMONTH_DIVIDEND_INTEREST,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99')
         AND A.ORG_NUM <> '009817'
         AND (A.MATURITY_DATE >= I_DATADATE OR A.MATURITY_DATE < I_DATADATE AND A.ACCT_BAL >= 0)
       GROUP BY A.ORG_NUM;

INSERT INTO `G31_II_5.a.B.2019`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.a.B.2019' AS ITEM_NUM,
             SUM(NVL(A.THISMONTH_DIVIDEND_INTEREST,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
       GROUP BY A.ORG_NUM;


-- ========== 逻辑组 1: 共 2 个指标 ==========
FROM (
SELECT A.ORG_NUM,
             CASE
               WHEN A.ORG_NUM = '009804' THEN 'G31_II_5.2.L.2018'
               WHEN A.ORG_NUM = '009817' THEN 'G31_II_5.2.M.2018'
             END AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '04'
         AND A.ORG_NUM IN ('009817','009804')
       GROUP BY A.ORG_NUM
) q_1
INSERT INTO `G31_II_5.2.L.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_II_5.2.M.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *;

-- 指标: G31_II_5.4.B.2018
--民生通惠资产管理有限公司，该公司属于资管中的保险类，取该公司的利息收益
    INSERT INTO `G31_II_5.4.B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.4.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP LIKE '12%' --资管计划
         AND B.ISSU_ORG_NAM LIKE '民生通惠%'
       GROUP BY A.ORG_NUM;


-- ========== 逻辑组 3: 共 2 个指标 ==========
FROM (
SELECT A.ORG_NUM,
             CASE
               WHEN A.ORG_NUM = '009804' THEN 'G31_II_5.2.H.2018'
               WHEN A.ORG_NUM = '009817' THEN 'G31_II_5.2.F.2018'
             END AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '04'
         AND A.ORG_NUM IN ( '009817','009804')
       GROUP BY A.ORG_NUM
) q_3
INSERT INTO `G31_II_5.2.F.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_II_5.2.H.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *;

-- 指标: G31_II_8..C.2018
--货币市场基金投资持有仓位+公允
    INSERT INTO `G31_II_8..C.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8..C.2018' AS ITEM_NUM,
             SUM(A.ACCT_BAL * TT.CCY_RATE + A.MK_VAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B --债券信息表
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '01' --基金
         AND B.SUBJECT_PRO_TYPE = '0103' --货币市场共同基金
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_8..D.2018
--债券基金投资持有仓位+公允
    INSERT INTO `G31_II_8..D.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8..D.2018' AS ITEM_NUM,
             SUM(A.ACCT_BAL * TT.CCY_RATE + A.MK_VAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B --债券信息表
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '01' --基金
         AND B.SUBJECT_PRO_TYPE = '0102' --债券基金
       GROUP BY A.ORG_NUM;

INSERT INTO `G31_II_8..D.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
       SELECT A.ORG_NUM,
              'G31_II_8..D.2018' AS ITEM_NUM,
              SUM(NVL(A.PRINCIPAL_BALANCE, 0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009804'
         AND A.INVEST_TYP <> '04'
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_5.2.A.2018
--009820:取类型是信托计划投资的持有仓位；
    INSERT INTO `G31_II_5.2.A.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.2.A.2018' AS ITEM_NUM,
             SUM(CASE
                   WHEN A.ORG_NUM = '009817' THEN A.PRINCIPAL_BALANCE * TT.CCY_RATE
                   ELSE A.ACCT_BAL * TT.CCY_RATE + A.MK_VAL * TT.CCY_RATE
                 END)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP LIKE '04%' --信托
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_5.3.L.2018
因为是存量业务，穿透固定
    INSERT INTO `G31_II_5.3.L.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.3.L.2018' AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '12'
         AND A.ORG_NUM = '009817'
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_5.5.A.2018
INSERT INTO `G31_II_5.5.A.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.5.A.2018' AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP LIKE '99%' --其它投资
         AND A.ACCT_NUM  IN ('N000310000012723','N000310000012748')
         AND B.PROTYPE_DIS = '其他同业投资'
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_5.3.A.2018
--009820:取类型是资管计划投资的持有仓位；扣掉民生通惠资产管理有限公司，该公司属于资管中的保险类；
    INSERT INTO `G31_II_5.3.A.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.3.A.2018' AS ITEM_NUM,
             SUM((A.ACCT_BAL * TT.CCY_RATE) + (A.MK_VAL * TT.CCY_RATE))
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         --AND A.INVEST_TYP LIKE '12%' --资管计划
         AND B.ISSU_ORG_NAM NOT LIKE '民生通惠%'
         AND SUBSTR(A.INVEST_TYP, 1, 2) IN ('12', '99')
         AND A.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
       GROUP BY A.ORG_NUM;

--009817:存量非标证券业业务的本金
    INSERT INTO `G31_II_5.3.A.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.3.A.2018' AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
         AND A.INVEST_TYP LIKE '12%' --资管计划
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_5.y.B.2018
--取账户类型是FVTPL账户利息收益
    INSERT INTO `G31_II_5.y.B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.y.B.2018' AS ITEM_NUM,
             SUM(NVL(A.THISMONTH_DIVIDEND_INTEREST,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '1' --1 交易类 FVTPL账户
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99')
         AND A.ORG_NUM NOT IN ('009817','009804')
         AND (A.MATURITY_DATE >= I_DATADATE OR A.MATURITY_DATE < I_DATADATE AND A.ACCT_BAL >= 0)
       GROUP BY A.ORG_NUM;

INSERT INTO `G31_II_5.y.B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.y.B.2018' AS ITEM_NUM,
             SUM(NVL(A.THISMONTH_DIVIDEND_INTEREST,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM IN ('009817','009804')
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04')
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_8..A.2018
--5.4保险业资产管理产品|期末余额+5.5其他资产管理产品|期末余额+5.x自主管理（资产管理产品）|期末余额+5.y委托管理（资产管理产品）|期末余额+5.a公募（资产管理产品）|期末余额+
--债券基金投资持有仓位+债券基金投资公允+货币市场基金投资持有仓位
    INSERT INTO `G31_II_8..A.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8..A.2018' AS ITEM_NUM,
             SUM(
               CASE
                 WHEN B.PROTYPE_DIS = '债券基金投资' THEN (NVL(A.ACCT_BAL,0) + NVL(A.MK_VAL,0)) * TT.CCY_RATE
                 WHEN B.PROTYPE_DIS = '货币基金投资' THEN  NVL(A.ACCT_BAL,0) * TT.CCY_RATE
                 WHEN A.ORG_NUM = '009817' THEN A.PRINCIPAL_BALANCE * TT.CCY_RATE
                 WHEN A.ORG_NUM = '009804' THEN NVL(A.PRINCIPAL_BALANCE,0) * TT.CCY_RATE
                ELSE (NVL(A.ACCT_BAL,0) + NVL(A.MK_VAL,0)) * TT.CCY_RATE
               END
             )
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_8..H.2018
INSERT INTO `G31_II_8..H.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
       SELECT A.ORG_NUM,
              'G31_II_8..H.2018' AS ITEM_NUM,
              SUM(NVL(A.PRINCIPAL_BALANCE, 0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009804'
         AND A.INVEST_TYP = '04'
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_5.3.F.2018
--009817:存量非标证券业穿透为信贷类的金额；因为是存量业务，穿透固定
    INSERT INTO `G31_II_5.3.F.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.3.F.2018' AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '12'
         AND A.ORG_NUM = '009817'
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_8.y.B.2018
--取账户类型是FVTPL账户利息收益+G3101的y委托管理（公募基金）投资收入
    INSERT INTO `G31_II_8.y.B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
    SELECT A.ORG_NUM,
           'G31_II_8.y.B.2018' AS ITEM_NUM,
           SUM(CASE
                 WHEN A.ITEM_CD = '61110202' THEN
                  A.CREDIT_BAL * TT.CCY_RATE - A.DEBIT_BAL * TT.CCY_RATE
                 WHEN A.ITEM_CD = '61111302' THEN
                  A.CREDIT_BAL * TT.CCY_RATE
               END)
      FROM SMTMODS_L_FINA_GL A
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.CCY_DATE = I_DATADATE
       AND TT.BASIC_CCY = A.CURR_CD
       AND TT.FORWARD_CCY = 'CNY'
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ITEM_CD IN ('61110202', '61111302')
       AND A.ORG_NUM <> '009817'
     GROUP BY A.ORG_NUM;

INSERT INTO `G31_II_8.y.B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8.y.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B --债券信息表
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '1' --1 交易类 FVTPL账户
         AND A.INVEST_TYP <> '01'
         AND A.ORG_NUM <> '009817'
       GROUP BY A.ORG_NUM;

INSERT INTO `G31_II_8.y.B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8.y.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_5.y.A.2018
INSERT INTO `G31_II_5.y.A.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.y.A.2018' AS ITEM_NUM,
             SUM((NVL(A.ACCT_BAL,0) * TT.CCY_RATE) + (NVL(A.MK_VAL,0) * TT.CCY_RATE))
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '1' --1 交易类 FVTPL账户
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99')
         AND A.ORG_NUM NOT IN ('009817','009804')
         AND (A.MATURITY_DATE >= I_DATADATE OR A.MATURITY_DATE < I_DATADATE AND A.ACCT_BAL >= 0)
       GROUP BY A.ORG_NUM;

INSERT INTO `G31_II_5.y.A.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.y.A.2018' AS ITEM_NUM,
             SUM(NVL(A.PRINCIPAL_BALANCE,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM IN ( '009817','009804')
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04')
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_5.1.B.2018
--银行理财产品投资的利息收益
    INSERT INTO `G31_II_5.1.B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.1.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP LIKE '05%' --理财
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_5.2.B.2018
--信托计划投资的利息收益,委外的利息收益去业务状况表取，台账不准；委外的利息取科目61111304交易性特定目的载体投资非应税投资收入
    INSERT INTO `G31_II_5.2.B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.2.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP LIKE '04%' --信托
       GROUP BY A.ORG_NUM;

/*    INSERT INTO `G31_II_5.2.B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
    SELECT T.ORG_NUM,
            'G31_II_5.2.B.2018' AS ITEM_NUM,
            SUM(T.CREDIT_BAL)
      FROM SMTMODS_L_FINA_GL T
     WHERE T.DATA_DATE = I_DATADATE
       AND T.ITEM_CD = '61111304'
       AND T.CURR_CD = 'BWB'
       AND T.ORG_NUM = '009820'
     GROUP BY T.ORG_NUM;


-- 指标: G31_II_5.a.A.2019
取类型是资管计划，取AC账户持有仓位+FVTPL账户持有仓位+公允；
    INSERT INTO `G31_II_5.a.A.2019`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.a.A.2019' AS ITEM_NUM,
             SUM(
               CASE
                 WHEN ACCOUNTANT_TYPE = '1' THEN (NVL(A.ACCT_BAL,0) * TT.CCY_RATE) + (NVL(A.MK_VAL,0) * TT.CCY_RATE)
                 WHEN A.ACCOUNTANT_TYPE = '3' THEN NVL(A.ACCT_BAL,0) * TT.CCY_RATE
               END)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM <> '009817'
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99')
         AND (A.MATURITY_DATE >= I_DATADATE OR A.MATURITY_DATE < I_DATADATE AND A.ACCT_BAL >= 0)
       GROUP BY A.ORG_NUM;

INSERT INTO `G31_II_5.a.A.2019`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.a.A.2019' AS ITEM_NUM,
             SUM((NVL(A.PRINCIPAL_BALANCE,0) * TT.CCY_RATE))
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009817'
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_5.x.A.2018
取账户类型是AC账户的持有仓位；
    INSERT INTO `G31_II_5.x.A.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.x.A.2018' AS ITEM_NUM,
             SUM(A.ACCT_BAL * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '3' --AC账户
         AND A.ORG_NUM NOT IN ('009817','009804')
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99')
         AND (A.MATURITY_DATE >= I_DATADATE OR A.MATURITY_DATE < I_DATADATE AND A.ACCT_BAL >= 0)
       GROUP BY A.ORG_NUM;

INSERT INTO `G31_II_5.x.A.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
    SELECT A.ORG_NUM,
           'G31_II_5.x.A.2018' AS ITEM_NUM,
           SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
      FROM SMTMODS_L_ACCT_FUND_INVEST A
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.CCY_DATE = I_DATADATE
       AND TT.BASIC_CCY = A.CURR_CD
       AND TT.FORWARD_CCY = 'CNY'
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ORG_NUM = '009817'
       AND SUBSTR(A.INVEST_TYP, 1, 2) IN ('12')
     GROUP BY A.ORG_NUM;


-- 指标: G31_II_8.y.A.2018
INSERT INTO `G31_II_8.y.A.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8.y.A.2018' AS ITEM_NUM,
             SUM(
               CASE
                 WHEN A.ACCOUNTANT_TYPE = '1' THEN (NVL(A.ACCT_BAL,0) + NVL(A.MK_VAL,0)) * TT.CCY_RATE
                 WHEN PROTYPE_DIS = '债券基金投资' THEN (NVL(A.ACCT_BAL,0) + NVL(A.MK_VAL,0)) * TT.CCY_RATE
                 WHEN PROTYPE_DIS = '货币基金投资' THEN NVL(A.PRINCIPAL_BALANCE,0) * TT.CCY_RATE
               END
                )
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM NOT IN('009817','009804')
         AND (A.ACCOUNTANT_TYPE = '1' OR A.INVEST_TYP = '01')
       GROUP BY A.ORG_NUM;

-- 009804 009817：存量非标信托业务的本金
    INSERT INTO `G31_II_8.y.A.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8.y.A.2018' AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '04'
         AND A.ORG_NUM IN('009817','009804')
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_5.3.B.2018
--资管计划投资的利息收益； 扣掉民生通惠资产管理有限公司，该公司属于资管中的保险类
    INSERT INTO `G31_II_5.3.B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_5.3.B.2018' AS ITEM_NUM,
             SUM(A.THISMONTH_DIVIDEND_INTEREST * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
       INNER JOIN SMTMODS_L_AGRE_OTHER_SUBJECT_INFO B
          ON A.SUBJECT_CD = B.SUBJECT_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         --AND A.INVEST_TYP LIKE '12%' --资管计划
         AND B.ISSU_ORG_NAM NOT LIKE '民生通惠%'
         AND SUBSTR(A.INVEST_TYP, 1, 2) IN ('12', '99')
         AND A.ACCT_NUM NOT IN ('N000310000012723','N000310000012748')
       GROUP BY A.ORG_NUM;


-- 指标: G31_II_8..B.2018
--5.4保险业资产管理产品|投资收入+5.5其他资产管理产品|投资收入+5.x自主管理（资产管理产品）|投资收入+
--5.y委托管理（资产管理产品）|投资收入+5.a公募（资产管理产品）|投资收入+G3101的y委托管理（公募基金）投资收入

    INSERT INTO `G31_II_8..B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8..B.2018' AS ITEM_NUM,
             SUM(NVL(A.THISMONTH_DIVIDEND_INTEREST,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCOUNTANT_TYPE = '1' --1 交易类 FVTPL账户
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99','00')
         AND A.ORG_NUM = '009820'
         AND (A.MATURITY_DATE >= I_DATADATE OR A.MATURITY_DATE < I_DATADATE AND A.ACCT_BAL >= 0)
       GROUP BY A.ORG_NUM;

INSERT INTO `G31_II_8..B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
    SELECT A.ORG_NUM,
           'G31_II_8..B.2018' AS ITEM_NUM,
           SUM(CASE
                 WHEN A.ITEM_CD = '61110202' THEN
                  A.CREDIT_BAL * TT.CCY_RATE - A.DEBIT_BAL * TT.CCY_RATE
                 WHEN A.ITEM_CD = '61111302' THEN
                  A.CREDIT_BAL * TT.CCY_RATE
               END)
      FROM SMTMODS_L_FINA_GL A
      LEFT JOIN SMTMODS_L_PUBL_RATE TT
        ON TT.CCY_DATE = I_DATADATE
       AND TT.BASIC_CCY = A.CURR_CD
       AND TT.FORWARD_CCY = 'CNY'
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ITEM_CD IN ('61110202', '61111302')
       AND A.ORG_NUM = '009820'
     GROUP BY A.ORG_NUM;

INSERT INTO `G31_II_8..B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
    SELECT G.ORG_NUM,
           'G31_II_8..B.2018' ITEM_NUM,
           SUM(CASE
                 WHEN G.ITEM_CD IN ('611105', '61110101', '6101', '611106') THEN
                  G.CREDIT_BAL - G.DEBIT_BAL
                 ELSE
                  G.CREDIT_BAL
               END * U.CCY_RATE) ITEM_VALUE
      FROM SMTMODS_L_FINA_GL G
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = G.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
     WHERE G.ORG_NUM = '009804'
       AND G.DATA_DATE = I_DATADATE
       AND G.ITEM_CD IN ('60110501',
                         '60110502',
                         '60110503',
                         '611105',
                         '61110102',
                         '61110103',
                         '61110104',
                         '61110101',
                         '6101',
                         '60110601',
                         '60110602',
                         '60110603',
                         '611106')
     GROUP BY G.ORG_NUM;

INSERT INTO `G31_II_8..B.2018`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_II_8..B.2018' AS ITEM_NUM,
             SUM(NVL(A.THISMONTH_DIVIDEND_INTEREST,0) * TT.CCY_RATE)
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.INVEST_TYP,1,2) IN ('04','05','12','99','00')
         AND A.ORG_NUM = '009817'
       GROUP BY A.ORG_NUM;


