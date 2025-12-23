-- ============================================================
-- 文件名: G31_I投资业务情况表.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 4 个指标 ==========
FROM (
SELECT a.org_num AS ORG_NUM,
            /* CASE
               WHEN a.BOOK_TYPE = '2' and A.DC_DATE / 365 > 10 AND
                    b.STOCK_NAM <> '18华阳经贸CP001' THEN
                'G31_I_1.k.A.2024' ---10年以上
               WHEN A.BOOK_TYPE = '2' and A.DC_DATE / 365 > 5 THEN
                'G31_I_1.j.A.2024' --5-10年
               WHEN A.BOOK_TYPE = '2' and A.DC_DATE > 365 THEN
                'G31_I_1.i.A.2024' --1-5年
               ELSE
                'G31_I_1.h.A.2024'
             END ITEM_NUM,*/
            CASE
               WHEN  A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'   THEN
                'G31_I_1.k.A.2024' ---10年以上
               WHEN  A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001' THEN
                'G31_I_1.j.A.2024' --5-10年
               WHEN  A.DC_DATE > 360   AND b.STOCK_NAM <> '18华阳经贸CP001' THEN
                'G31_I_1.i.A.2024' --1-5年
               ELSE
                'G31_I_1.h.A.2024'
             END ITEM_NUM,     --ADD  BY  ZY 修改完成
             SUM(NVL(A.Principal_Balance, 0) * U.CCY_RATE) AS ITEM_VALUE --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
       GROUP BY a.org_num,
                 CASE
               WHEN  A.DC_DATE / 360 > 10  AND b.STOCK_NAM <> '18华阳经贸CP001'   THEN
                'G31_I_1.k.A.2024' ---10年以上
               WHEN  A.DC_DATE / 360 > 5  AND b.STOCK_NAM <> '18华阳经贸CP001' THEN
                'G31_I_1.j.A.2024' --5-10年
               WHEN  A.DC_DATE > 360   AND b.STOCK_NAM <> '18华阳经贸CP001' THEN
                'G31_I_1.i.A.2024' --1-5年
               ELSE
                'G31_I_1.h.A.2024'
             END
) q_0
INSERT INTO `G31_I_1.i.A.2024` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.k.A.2024` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.j.A.2024` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.h.A.2024` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *;

-- ========== 逻辑组 1: 共 7 个指标 ==========
FROM (
SELECT '009804' AS ORG_NUM,
             CASE
                WHEN t.ZQLX ='国债' THEN
                 'G31_I_1.1.C.2025' --1.1国债
                WHEN t.ZQLX ='地方政府债券' THEN
                 'G31_I_1.2.C.2025' --1.2地方政府债券
                WHEN t.ZQLX ='政策性金融债'  THEN
                 'G31_I_1.4.C.2025' --1.4政策性金融债
                WHEN t.ZQLX ='政府机构债券'  THEN
                 'G31_I_1.5.C.2025' --'1.5政府机构债券
               WHEN t.ZQLX ='商业性金融债'  THEN
                'G31_I_1.6.C.2025' --1.6商业性金融债
               WHEN t.ZQLX ='企业债' THEN
                'G31_I_1.7.1.C.2025' --1.7.1企业债
               WHEN t.ZQLX ='公司债'  THEN
                'G31_I_1.7.2.C.2025' --1.7.2公司债
               WHEN t.ZQLX ='企业债务融资工具'  THEN
                'G31_I_1.7.3.C.2025' --1.7.3企业债务融资工具
               WHEN t.ZQLX ='资产支持证券'  THEN
                'G31_I_1.8.C.2025' --1.8资产支持证券期末余额
               WHEN t.ZQLX ='外国债券'  THEN
                'G31_I_1.9.C.2025' --1.9外国债券
             END ITEM_NUM,
             sum( nvl(t.ZYTJGXZJQ,0) * nvl(t.ZYTQJSZ,0) /t1.ZQLX_sum)   AS ITEM_VALUE --账面余额
               FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP T
  LEFT JOIN (SELECT sum(ZYTQJSZ) ZQLX_sum, ZQLX
               FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP
              WHERE DATA_DATE = I_DATADATE
              group by ZQLX) t1
       on t.Zqlx = t1.ZQLX
 where t.DATA_DATE = I_DATADATE
 group by CASE
                WHEN t.ZQLX ='国债' THEN
                 'G31_I_1.1.C.2025' --1.1国债
                WHEN t.ZQLX ='地方政府债券' THEN
                 'G31_I_1.2.C.2025' --1.2地方政府债券
                WHEN t.ZQLX ='政策性金融债'  THEN
                 'G31_I_1.4.C.2025' --1.4政策性金融债
                WHEN t.ZQLX ='政府机构债券'  THEN
                 'G31_I_1.5.C.2025' --'1.5政府机构债券
               WHEN t.ZQLX ='商业性金融债'  THEN
                'G31_I_1.6.C.2025' --1.6商业性金融债
               WHEN t.ZQLX ='企业债' THEN
                'G31_I_1.7.1.C.2025' --1.7.1企业债
               WHEN t.ZQLX ='公司债'  THEN
                'G31_I_1.7.2.C.2025' --1.7.2公司债
               WHEN t.ZQLX ='企业债务融资工具'  THEN
                'G31_I_1.7.3.C.2025' --1.7.3企业债务融资工具
               WHEN t.ZQLX ='资产支持证券'  THEN
                'G31_I_1.8.C.2025' --1.8资产支持证券期末余额
               WHEN t.ZQLX ='外国债券'  THEN
                'G31_I_1.9.C.2025' --1.9外国债券
             END
) q_1
INSERT INTO `G31_I_1.6.C.2025` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.7.3.C.2025` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.2.C.2025` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.7.2.C.2025` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.7.1.C.2025` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.4.C.2025` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.1.C.2025` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *;

-- 指标: G31_I_3.y.B.2024
INSERT INTO `G31_I_3.y.B.2024`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_I_3.y.B.2024' AS ITEM_NUM,
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
      --AND A.ORG_NUM = '009820'
       GROUP BY A.ORG_NUM;


-- ========== 逻辑组 3: 共 7 个指标 ==========
FROM (
SELECT a.org_num AS ORG_NUM,
             CASE
                WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A01' THEN --产品分类,发行主体类型,资产证券化分类,发行主体境内境外标志
                 'G31_I_1.1.A.2018' --1.1国债
                WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02' THEN
                 'G31_I_1.2.A.2018' --1.2地方政府债券
                WHEN B.STOCK_PRO_TYPE LIKE 'C%' AND B.ISSU_ORG = 'D02' THEN
                 'G31_I_1.4.A.2018' --1.4政策性金融债
                WHEN SUBSTR(B.STOCK_PRO_TYPE, 1, 1) IN ('C', 'D') AND
                     B.ISSU_ORG LIKE 'B%' AND B.STOCK_ASSET_TYPE IS NULL AND
                     B.ISSUER_INLAND_FLG = 'Y' THEN
                 'G31_I_1.5.A.2018' --'1.5政府机构债券
               WHEN B.STOCK_PRO_TYPE LIKE 'C%' AND
                    B.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07') AND
                    B.STOCK_ASSET_TYPE IS NULL AND B.ISSUER_INLAND_FLG = 'Y' THEN
                'G31_I_1.6.A.2018' --1.6商业性金融债
               WHEN B.STOCK_PRO_TYPE = 'D04' AND
                    SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND
                    B.ISSU_ORG LIKE 'C%' THEN
                'G31_I_1.7.1.A.2018' --1.7.1企业债
               WHEN B.STOCK_PRO_TYPE = 'D05' AND
                    SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND
                    B.ISSU_ORG LIKE 'C%' THEN
                'G31_I_1.7.2.A.2018' --1.7.2公司债
               WHEN (B.STOCK_PRO_TYPE LIKE 'D01' OR
                    B.STOCK_PRO_TYPE LIKE 'D02') AND
                    SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND
                    B.ISSU_ORG LIKE 'C%' THEN
                'G31_I_1.7.3.A.2018' --1.7.3企业债务融资工具
               WHEN B.STOCK_ASSET_TYPE IS NOT NULL AND
                    B.ISSUER_INLAND_FLG = 'Y' THEN
                'G31_I_1.8.A.2018' --1.8资产支持证券期末余额
               WHEN B.STOCK_PRO_TYPE LIKE 'F%' AND B.ISSUER_INLAND_FLG = 'N' THEN
                'G31_I_1.9.A.2018' --1.9外国债券
             END ITEM_NUM,
             SUM(NVL(A.Principal_Balance, 0) * U.CCY_RATE) AS ITEM_VALUE --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
       GROUP BY a.org_num,
                CASE
                  WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A01' THEN --产品分类,发行主体类型,资产证券化分类,发行主体境内境外标志
                   'G31_I_1.1.A.2018' --1.1国债
                  WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02' THEN
                   'G31_I_1.2.A.2018' --1.2地方政府债券
                  WHEN B.STOCK_PRO_TYPE LIKE 'C%' AND B.ISSU_ORG = 'D02' THEN
                   'G31_I_1.4.A.2018' --1.4政策性金融债
                  WHEN SUBSTR(B.STOCK_PRO_TYPE, 1, 1) IN ('C', 'D') AND
                       B.ISSU_ORG LIKE 'B%' AND B.STOCK_ASSET_TYPE IS NULL AND
                       B.ISSUER_INLAND_FLG = 'Y' THEN
                   'G31_I_1.5.A.2018' --'1.5政府机构债券
                  WHEN B.STOCK_PRO_TYPE LIKE 'C%' AND
                       B.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07') AND
                       B.STOCK_ASSET_TYPE IS NULL AND
                       B.ISSUER_INLAND_FLG = 'Y' THEN
                   'G31_I_1.6.A.2018' --1.6商业性金融债
                  WHEN B.STOCK_PRO_TYPE = 'D04' AND
                       SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND
                       B.ISSU_ORG LIKE 'C%' THEN
                   'G31_I_1.7.1.A.2018' --1.7.1企业债
                  WHEN B.STOCK_PRO_TYPE = 'D05' AND
                       SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND
                       B.ISSU_ORG LIKE 'C%' THEN
                   'G31_I_1.7.2.A.2018' --1.7.2公司债
                  WHEN (B.STOCK_PRO_TYPE LIKE 'D01' OR
                       B.STOCK_PRO_TYPE LIKE 'D02') AND
                       SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND
                       B.ISSU_ORG LIKE 'C%' THEN
                   'G31_I_1.7.3.A.2018' --1.7.3企业债务融资工具
                  WHEN B.STOCK_ASSET_TYPE IS NOT NULL AND
                       B.ISSUER_INLAND_FLG = 'Y' THEN
                   'G31_I_1.8.A.2018' --1.8资产支持证券期末余额
                  WHEN B.STOCK_PRO_TYPE LIKE 'F%' AND
                       B.ISSUER_INLAND_FLG = 'N' THEN
                   'G31_I_1.9.A.2018' --1.9外国债券
                END
) q_3
INSERT INTO `G31_I_1.4.A.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.7.3.A.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.6.A.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.2.A.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.1.A.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.7.2.A.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.7.1.A.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *;

-- ========== 逻辑组 4: 共 3 个指标 ==========
FROM (
SELECT a.org_num AS ORG_NUM,
             case
               when a.ACCOUNTANT_TYPE = '1' --交易类
                then
                'G31_I_1.e.A.2018'
               when a.ACCOUNTANT_TYPE = '2' --可供出售类
                then
                'G31_I_1.f.A.2018'
               when a.ACCOUNTANT_TYPE = '3' -- 持有至到期
                then
                'G31_I_1.d.A.2018'
             end ITEM_NUM,
             SUM(NVL(A.Principal_Balance, 0) * U.CCY_RATE) AS ITEM_VALUE --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
       GROUP BY a.org_num,
                case
                  when a.ACCOUNTANT_TYPE = '1' --交易类
                   then
                   'G31_I_1.e.A.2018'
                  when a.ACCOUNTANT_TYPE = '2' --可供出售类
                   then
                   'G31_I_1.f.A.2018'
                  when a.ACCOUNTANT_TYPE = '3' -- 持有至到期
                   then
                   'G31_I_1.d.A.2018'
                end
) q_4
INSERT INTO `G31_I_1.e.A.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.f.A.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.d.A.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *;

-- 指标: G31_I_0_1.3.A.2022
--二级资本债
    INSERT INTO `G31_I_0_1.3.A.2022` --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT a.org_num AS ORG_NUM,
             'G31_I_0_1.3.A.2022' ITEM_NUM,
             SUM(NVL(A.Principal_Balance, 0) * U.CCY_RATE) AS ITEM_VALUE --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
         and b.stock_pro_type in ( /*'C01',*/ 'C0101')
       GROUP BY a.org_num;


-- ========== 逻辑组 6: 共 3 个指标 ==========
FROM (
SELECT '009804' AS ORG_NUM,
       CASE
         WHEN T2.JYTZ = '交易性金融资产' --交易类
          THEN
          'G31_I_1.e.C.2025'
         WHEN T2.JYTZ = '可供出售金融资产' --可供出售类
          THEN
          'G31_I_1.f.C.2025'
         WHEN T2.JYTZ = '持有至到期投资' -- 持有至到期
          THEN
          'G31_I_1.d.C.2025'
       END ITEM_NUM,
       SUM(NVL(T.ZYTJGXZJQ, 0) * NVL(T.ZYTQJSZ, 0) / T2.JYTZ_SUM) AS ITEM_VALUE --账面余额
  FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP T
  LEFT JOIN (SELECT SUM(ZYTQJSZ) JYTZ_SUM, JYTZ
               FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP
              WHERE DATA_DATE = I_DATADATE
              GROUP BY JYTZ) T2
    ON T.JYTZ = T2.JYTZ
 WHERE T.DATA_DATE = I_DATADATE
 GROUP BY CASE
            WHEN T2.JYTZ = '交易性金融资产' --交易类
             THEN
             'G31_I_1.e.C.2025'
            WHEN T2.JYTZ = '可供出售金融资产' --可供出售类
             THEN
             'G31_I_1.f.C.2025'
            WHEN T2.JYTZ = '持有至到期投资' -- 持有至到期
             THEN
             'G31_I_1.d.C.2025'
          END
) q_6
INSERT INTO `G31_I_1.f.C.2025` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.d.C.2025` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.e.C.2025` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *;

-- 指标: G31_I_1.x.B.2018
---投资收入（年初至报告期末数）
    INSERT INTO `G31_I_1.x.B.2018` --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT G.ORG_NUM,
             'G31_I_1.x.B.2018' ITEM_NUM,
             SUM(CASE
                   WHEN G.ITEM_CD IN ('611105', '61110101', '6101', '611106',
                     --[JLBA202508060001][于佳禾][20250918][石雨][新增科目(60110509+60110510+60110607+60110608)贷+（61110107+61110108+61111407+61111408）贷-借]
                     '61110107','61110108','61111407','61111408') THEN
                    G.CREDIT_BAL - G.DEBIT_BAL --贷-借
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
                           '611106',
                           --[JLBA202508060001][于佳禾][20250918][石雨][新增科目(60110509+60110510+60110607+60110608)贷+（61110107+61110108+61111407+61111408）贷-借]
                           '60110509','60110510','60110607','60110608',
                           '61110107','61110108','61111407','61111408'
                           )
       GROUP BY G.ORG_NUM;


-- 指标: G31_I_1.f.B.2018
--1.f 以公允价值计量且变动计入其他综合收益

    INSERT INTO `G31_I_1.f.B.2018` --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT G.ORG_NUM,
             'G31_I_1.f.B.2018' ITEM_NUM,
             SUM(CASE
                   WHEN G.ITEM_CD IN ('611106') THEN
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
         AND G.ITEM_CD IN ('60110601', '60110602', '60110603', '611106')

       GROUP BY G.ORG_NUM;


-- 指标: G31_I_1.7.C.2025
INSERT INTO `G31_I_1.7.C.2025` --PUB_DATA_COLLECT_G31_2016
   (ORG_NUM, --机构号
    ITEM_NUM, --指标号
    ITEM_VALUE --指标值
    )
   SELECT '009804' AS ORG_NUM,
          'G31_I_1.7.C.2025' ITEM_NUM,
          sum(nvl(t.ZYTJGXZJQ, 0) * nvl(t.ZYTQJSZ, 0) / v_ZYTQJSZ_sum1) AS ITEM_VALUE --账面余额
     FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP T
    where t.DATA_DATE = I_DATADATE
    AND  ZQLX IN ('企业债','公司债','企业债务融资工具');


-- 指标: G31_I_3.1.A.2024
INSERT INTO `G31_I_3.1.A.2024`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_I_3.1.A.2024' AS ITEM_NUM,
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


-- 指标: G31_I_1.x.A.2018
--自主管理
    INSERT INTO `G31_I_1.x.A.2018` --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT a.org_num AS ORG_NUM,
             'G31_I_1.x.A.2018' ITEM_NUM,
             SUM(NVL(A.Principal_Balance, 0) * U.CCY_RATE) AS ITEM_VALUE --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
       GROUP BY a.org_num;


-- 指标: G31_I_1.2.1.C.2025
INSERT INTO `G31_I_1.2.1.C.2025` --PUB_DATA_COLLECT_G31_2016
   (ORG_NUM, --机构号
    ITEM_NUM, --指标号
    ITEM_VALUE --指标值
    )
   SELECT '009804' AS ORG_NUM,
          'G31_I_1.2.1.C.2025' ITEM_NUM,
          sum(nvl(t.ZYTJGXZJQ, 0) * nvl(t.ZYTQJSZ, 0) / v_ZYTQJSZ_sum2) AS ITEM_VALUE --账面余额
     FROM CBRC_EV_OVRFLWGPRFT_LOSS_TEMP T
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON t.STOCK_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
    where t.DATA_DATE = I_DATADATE
    and  B.FXZJYT ='02'  ---专项债券
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
         AND B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02';


-- ========== 逻辑组 13: 共 3 个指标 ==========
FROM (
SELECT a.org_num AS ORG_NUM,
             case
               when b.APPRAISE_TYPE in ('1', '2') or
                    b.stock_cd = 'X0003118A1600001' then
                'G31_I_1.a.A.2018'
               when b.APPRAISE_TYPE in
                    ('3', '4', '5', '6', '7', '8', '9', 'a', 'b') or
                    b.stock_cd in ('032001060', '101788002') then
                'G31_I_1.b.A.2018'
               else
                'G31_I_1.c.A.2018'
             end ITEM_NUM,
             SUM(NVL(A.Principal_Balance, 0) * U.CCY_RATE) AS ITEM_VALUE --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
         and SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D'
         AND B.ISSU_ORG LIKE 'C%' --非金融企业债

       GROUP BY a.org_num,
                case
                  when b.APPRAISE_TYPE in ('1', '2') or
                       b.stock_cd = 'X0003118A1600001' then
                   'G31_I_1.a.A.2018'
                  when b.APPRAISE_TYPE in
                       ('3', '4', '5', '6', '7', '8', '9', 'a', 'b') or
                       b.stock_cd in ('032001060', '101788002') then
                   'G31_I_1.b.A.2018'
                  else
                   'G31_I_1.c.A.2018'
                end
) q_13
INSERT INTO `G31_I_1.a.A.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.c.A.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *
INSERT INTO `G31_I_1.b.A.2018` (ORG_NUM,  
       ITEM_NUM,  
       ITEM_VALUE)
SELECT *;

-- 指标: G31_I_3.y.A.2024
INSERT INTO `G31_I_3.y.A.2024`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_I_3.y.A.2024' AS ITEM_NUM,
             SUM(CASE
                   WHEN B.SUBJECT_PRO_TYPE = '0102' --债券基金
                    THEN
                    A.ACCT_BAL * TT.CCY_RATE + A.MK_VAL * TT.CCY_RATE
                   WHEN B.SUBJECT_PRO_TYPE = '0103' --货币市场共同基金
                    THEN
                    A.ACCT_BAL * TT.CCY_RATE
                 END)
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
         AND B.SUBJECT_PRO_TYPE in ('0102', --债券基金
                                    '0103') --货币市场共同基金
       GROUP BY A.ORG_NUM;


-- 指标: G31_I_1.2.1.A.2021
----add  by  zy  20240902   1.2.1专项债券
INSERT INTO `G31_I_1.2.1.A.2021`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
select 
A.ORG_NUM,
             'G31_I_1.2.1.A.2021' AS ITEM_NUM,
SUM(A.PRINCIPAL_BALANCE * U.CCY_RATE ) AS ITEM_VALUE  --账面余额
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种，债券投资
          AND B.FXZJYT ='02'  ---专项债券
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
         AND B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02'
         GROUP BY A.ORG_NUM;


-- 指标: G31_I_1.e.B.2018
--1.e 以公允价值计量且变动计入当期损益

    INSERT INTO `G31_I_1.e.B.2018` --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT G.ORG_NUM,
             'G31_I_1.e.B.2018' ITEM_NUM,
             SUM(CASE
                   WHEN G.ITEM_CD IN ('61110101', '6101', '61110107','61110108','61111407','61111408'--[JLBA202508060001][于佳禾][20250918][石雨][新增科目（61110107+61110108+61111407+61111408）贷-借]
                     ) THEN
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
         AND G.ITEM_CD IN
             ('61110102', '61110103', '61110104', '61110101', '6101',
               '61110107','61110108','61111407','61111408'--[JLBA202508060001][于佳禾][20250918][石雨][新增科目（61110107+61110108+61111407+61111408）贷-借]

             )
       GROUP BY G.ORG_NUM;


-- 指标: G31_I_3.2.A.2024
INSERT INTO `G31_I_3.2.A.2024`
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT A.ORG_NUM,
             'G31_I_3.2.A.2024' AS ITEM_NUM,
             SUM(A.ACCT_BAL * TT.CCY_RATE)
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


-- 指标: G31_I_1.d.B.2018
--1.d 以摊余成本计量

    INSERT INTO `G31_I_1.d.B.2018` --PUB_DATA_COLLECT_G31_2016
      (ORG_NUM, --机构号
       ITEM_NUM, --指标号
       ITEM_VALUE --指标值
       )
      SELECT G.ORG_NUM,
             'G31_I_1.d.B.2018' ITEM_NUM,
             SUM(CASE
                   WHEN G.ITEM_CD IN ('611105') THEN
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
         AND G.ITEM_CD IN ('60110501', '60110502', '60110503', '611105',
           --[JLBA202508060001][于佳禾][20250918][石雨][新增科目(60110509+60110510+60110607+60110608)贷]
                           '60110509','60110510','60110607','60110608'
                           )
       GROUP BY G.ORG_NUM;


