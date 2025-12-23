-- ============================================================
-- 文件名: G25_2净稳定资金比率.sql
-- 生成时间: 2025-12-18 13:53:39
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.3.2.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.3.2.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.3.2.C.2016' --≥1年
             END,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE T
       WHERE T.FLAG_CODE IN ('002', '004')--ALTER BY 石雨 20250929 JLBA202507210012 新增久悬财政性存款
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;

--3.2欠稳定存款.金额（按剩余期限）.<6个月
    --3.2欠稳定存款.金额（按剩余期限）.6-12个月
    --3.2欠稳定存款.金额（按剩余期限）.≥1年
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.3.2.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.3.2.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.3.2.C.2016' --≥1年
             END,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE T
       WHERE T.FLAG_CODE IN ('002', '004')--ALTER BY 石雨 20250929 JLBA202507210012 新增久悬财政性存款
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE
) q_0
INSERT INTO `G25_2_1.3.2.B.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_1.3.2.C.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- ========== 逻辑组 1: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.8.3.1.C.2016'
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.8.3.1.B.2016'
               ELSE
                'G25_2_2.8.3.1.A.2016'
             END AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE_CNY *
                 (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) / A.ACCT_BAL_CNY),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        from CBRC_tmp_a_cbrc_bond_bal A --债券投资分析表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND ((A.ISSU_ORG = 'D02' AND A.STOCK_PRO_TYPE LIKE 'C%') OR
             (A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A')) --政策银行债 , 国债
         AND A.INVEST_TYP = '00'
         AND A.DC_DATE > 0 --不取逾期
         AND ACCT_BAL_CNY <> 0   --JLBA202411080004
       GROUP BY ORG_NUM,
                CASE
                  WHEN DC_DATE >= 360 THEN
                   'G25_2_2.8.3.1.C.2016'
                  WHEN DC_DATE >= 180 THEN
                   'G25_2_2.8.3.1.B.2016'
                  ELSE
                   'G25_2_2.8.3.1.A.2016'
                END;

---依赖G21

    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.8.3.1.C.2016'
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.8.3.1.B.2016'
               ELSE
                'G25_2_2.8.3.1.A.2016'
             END AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE_CNY *
                 (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) / A.ACCT_BAL_CNY),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        from CBRC_TMP_A_CBRC_BOND_BAL A --债券投资分析表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND ((A.ISSU_ORG = 'D02' AND A.STOCK_PRO_TYPE LIKE 'C%') OR
             (A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A')) --政策银行债 , 国债
         AND A.INVEST_TYP = '00'
         AND A.DC_DATE > 0 --不取逾期
         AND ACCT_BAL_CNY <> 0   --JLBA202411080004
       GROUP BY ORG_NUM,
                CASE
                  WHEN DC_DATE >= 360 THEN
                   'G25_2_2.8.3.1.C.2016'
                  WHEN DC_DATE >= 180 THEN
                   'G25_2_2.8.3.1.B.2016'
                  ELSE
                   'G25_2_2.8.3.1.A.2016'
                END
) q_1
INSERT INTO `G25_2_2.8.3.1.C.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_2.8.3.1.A.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_2.8.3.1.B.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- ========== 逻辑组 2: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.ORG_NUM,
                     DC_DATE,
                     SUM(CASE
                           WHEN ((A.ISSU_ORG = 'D02' AND
                                A.STOCK_PRO_TYPE LIKE 'C%') OR --（发行主体类型：D02政策性银行，债券产品类型：C是金融债（大类）包含很多小类）
                                (A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A')) THEN --（发行主体类型：A01中央政府，债券产品类型：A政府债券（指我国政府发行债券））
                            A.PRINCIPAL_BALANCE_CNY * A.COLL_AMT_CNY / A.ACCT_BAL_CNY  --（账面余额*质押面额）/持有仓位）
                           WHEN ((A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') OR --（发行主体类型：A02地方政府，债券产品类型：A政府债券（指我国政府发行债券）），
                                (A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
                                A.STOCK_PRO_TYPE IN
                                ('D01', 'D02', 'D04', 'D05')) --（债券产品类型：D01短期融资券，D02中期票据，D04企业债，D05公司债， 且信用评级是AA的债券）
                                OR
                                A.STOCK_CD IN
                                ('032000573', '032001060', 'X0003118A1600001')) THEN --债券编号'032000573' 20四平城投PPN001, '032001060' 20四平城投PPN002-外部评级AA,18翔控01(X0003118A1600001)-外部评级AA+
                            A.PRINCIPAL_BALANCE_CNY * A.COLL_AMT_CNY / A.ACCT_BAL_CNY
                           ELSE
                            A.PRINCIPAL_BALANCE_CNY
                         END) AS ITEM_VAL
                FROM CBRC_tmp_a_cbrc_bond_bal A
               WHERE A.INVEST_TYP = '00'
                 AND A.DC_DATE > 0 --不取逾期
                 AND A.STOCK_NAM <> '18华阳经贸CP001' --特殊处理，算逾期
                 AND ACCT_BAL_CNY <> 0   --JLBA202411080004
               GROUP BY A.ORG_NUM, DC_DATE
              UNION ALL
              SELECT A.ORG_NUM, DC_DATE, SUM(ACCT_BAL_RMB)
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE FLAG = '04'
                AND ORG_NUM = '009804' --此处不限制机构，同业存单 包含金融市场部，同业金融部2个部分数据  -ADD BY DJH 20240510  同业金融部 009820  分开写也可同数据源
               GROUP BY A.ORG_NUM, DC_DATE) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.DC_DATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN A.DC_DATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
                END;

--9.2其他     /*同业存单投资中登净价金额+基金持有仓位+基金的公允按剩余期限划分；其中随时申赎的基金放<6个月，定开的按剩余期限划分填报在009820*/
    --ADD BY DJH 20240510  同业金融部 009820

    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.ORG_NUM, DC_DATE, SUM(ACCT_BAL_RMB) ITEM_VAL
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE FLAG = '04'
                 AND ORG_NUM = '009820' --此处不限制机构，同业存单 包含金融市场部，同业金融部2个部分数据  -ADD BY DJH 20240510  同业金融部 009820  分开写也可同数据源
               GROUP BY A.ORG_NUM, DC_DATE) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN DC_DATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN DC_DATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
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
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(ACCT_BAL_RMB) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.FLAG = '06' --基金
                 AND A.REDEMPTION_TYPE = '定期赎回'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
                END;

-------9.2其他  一级资产，2A资产的抵押面额（账面余额*质押面额）/持有仓位）+其他信用评级的债券账面余额（抵押+未抵押）包含同业存单
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.ORG_NUM,
                     DC_DATE,
                     SUM(CASE
                           WHEN ((A.ISSU_ORG = 'D02' AND
                                A.STOCK_PRO_TYPE LIKE 'C%') OR --（发行主体类型：D02政策性银行，债券产品类型：C是金融债（大类）包含很多小类）
                                (A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A')) THEN --（发行主体类型：A01中央政府，债券产品类型：A政府债券（指我国政府发行债券））
                            A.PRINCIPAL_BALANCE_CNY * A.COLL_AMT_CNY / A.ACCT_BAL_CNY  --（账面余额*质押面额）/持有仓位）
                           WHEN ((A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') OR --（发行主体类型：A02地方政府，债券产品类型：A政府债券（指我国政府发行债券）），
                                (A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
                                A.STOCK_PRO_TYPE IN
                                ('D01', 'D02', 'D04', 'D05')) --（债券产品类型：D01短期融资券，D02中期票据，D04企业债，D05公司债， 且信用评级是AA的债券）
                                OR
                                A.STOCK_CD IN
                                ('032000573', '032001060', 'X0003118A1600001')) THEN --债券编号'032000573' 20四平城投PPN001, '032001060' 20四平城投PPN002-外部评级AA,18翔控01(X0003118A1600001)-外部评级AA+
                            A.PRINCIPAL_BALANCE_CNY * A.COLL_AMT_CNY / A.ACCT_BAL_CNY
                           ELSE
                            A.PRINCIPAL_BALANCE_CNY
                         END) AS ITEM_VAL
                FROM CBRC_tmp_a_cbrc_bond_bal A
               WHERE A.INVEST_TYP = '00'
                 AND A.DC_DATE > 0 --不取逾期
                 AND A.STOCK_NAM <> '18华阳经贸CP001' --特殊处理，算逾期
                 AND ACCT_BAL_CNY <> 0   --JLBA202411080004
               GROUP BY A.ORG_NUM, DC_DATE
              UNION ALL
              SELECT A.ORG_NUM, DC_DATE, SUM(ACCT_BAL_RMB)
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE FLAG = '04'
                AND ORG_NUM = '009804' --此处不限制机构，同业存单 包含金融市场部，同业金融部2个部分数据  -ADD BY DJH 20240510  同业金融部 009820  分开写也可同数据源
               GROUP BY A.ORG_NUM, DC_DATE) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.DC_DATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN A.DC_DATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
                END;

--9.2其他     /*同业存单投资中登净价金额+基金持有仓位+基金的公允按剩余期限划分；其中随时申赎的基金放<6个月，定开的按剩余期限划分填报在009820*/
    --ADD BY DJH 20240510  同业金融部 009820

    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.ORG_NUM, DC_DATE, SUM(ACCT_BAL_RMB) ITEM_VAL
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE FLAG = '04'
                 AND ORG_NUM = '009820' --此处不限制机构，同业存单 包含金融市场部，同业金融部2个部分数据  -ADD BY DJH 20240510  同业金融部 009820  分开写也可同数据源
               GROUP BY A.ORG_NUM, DC_DATE) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN DC_DATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN DC_DATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
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
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(ACCT_BAL_RMB) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.FLAG = '06' --基金
                 AND A.REDEMPTION_TYPE = '定期赎回'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
                END
) q_2
INSERT INTO `G25_2_2.9.2.B.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_2.9.2.C.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- ========== 逻辑组 3: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.4.2.2.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL1 + YQ_90) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G2502_DATA_COLLECT_TMP T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM = 'G25_2_2.4.2.2'
       GROUP BY T.ORG_NUM
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.4.2.2.B.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL2) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G2502_DATA_COLLECT_TMP T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM = 'G25_2_2.4.2.2'
       GROUP BY T.ORG_NUM
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.4.2.2.C.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL3) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G2502_DATA_COLLECT_TMP T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM = 'G25_2_2.4.2.2'
       GROUP BY T.ORG_NUM;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --4住房抵押贷款
    --4.22风险权重高于35%
       INSERT
       INTO `__INDICATOR_PLACEHOLDER__` 
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
          'G2502' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C < 180 AND T1.IDENTITY_CODE = '1') OR
                 (T1.IDENTITY_CODE = '2' AND PMT_REMAIN_TERM_C <= 90) THEN -- .<6个月 或者逾期小于90天（<-90）即欠本欠息小于90天
             'G25_2_2.4.2.2.A.2016'
            WHEN T1.PMT_REMAIN_TERM_C >= 180 AND T1.PMT_REMAIN_TERM_C < 360 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G25_2_2.4.2.2.B.2016'
            WHEN T1.PMT_REMAIN_TERM_C >= 360 AND T1.IDENTITY_CODE = '1' THEN
             'G25_2_2.4.2.2.C.2016'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE, --贷款余额
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
           FROM CBRC_fdm_lnac T
           LEFT JOIN CBRC_FDM_LNAC_PMT T1
             ON T.LOAN_NUM = T1.LOAN_NUM
            AND T.DATA_DATE = T1.DATA_DATE
           LEFT JOIN L_PUBL_RATE T2
             ON T2.DATA_DATE = I_DATADATE
            AND T2.BASIC_CCY = T1.CURR_CD --基准币种
            AND T2.FORWARD_CCY = 'CNY'
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP LIKE '0101%' --djh20210813 个人贷款住房贷款判断条件   逻辑与G0107 2.21.3住房按揭贷款 保持一致
            AND T.LOAN_GRADE_CD IN (1, 2)
) q_3
INSERT INTO `G25_2_2.4.2.2.A.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_2.4.2.2.C.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_2.4.2.2.B.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- ========== 逻辑组 4: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.3.1.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.3.1.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.3.1.C.2016' --≥1年
             END AS ITEM_NUM,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_STABLE T
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;

--3.1稳定存款.金额（按剩余期限）.<6个月
    --3.1稳定存款.金额（按剩余期限）.6-12个月
    --3.1稳定存款.金额（按剩余期限）.≥1年
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.3.1.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.3.1.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.3.1.C.2016' --≥1年
             END AS ITEM_NUM,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_STABLE T
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE
) q_4
INSERT INTO `G25_2_1.3.1.A.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_1.3.1.B.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_1.3.1.C.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- 指标: G25_2_2.16.2.A.2016
--17.2信用和流动性便利（不可无条件撤销） 信用卡和承兑汇票、未使用授信额度放在6月内
    INSERT INTO `G25_2_2.16.2.A.2016`
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
      INTO `G25_2_2.16.2.A.2016` 
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

/* INSERT INTO `G25_2_2.16.2.A.2016`
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


-- ========== 逻辑组 6: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.5.2.B.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL2) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G2502_DATA_COLLECT_TMP T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM = 'G25_2_2.5.2.2'
       GROUP BY T.ORG_NUM
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.5.2.C.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL3) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G2502_DATA_COLLECT_TMP T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM = 'G25_2_2.5.2.2'
       GROUP BY T.ORG_NUM;

--5向个人、非金融机构、主权、公共部门实体和政策性金融机构等发放的贷款（不含住房抵押贷款）
    --5.2.2风险权重高于35%
     INSERT 
       INTO `__INDICATOR_PLACEHOLDER__` 
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
          'G2502' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C < 180 AND T1.IDENTITY_CODE = '1') OR
                 (T1.IDENTITY_CODE = '2' AND PMT_REMAIN_TERM_C <= 90) THEN -- .<6个月 或者逾期小于90天（<-90）即欠本欠息小于90天
             'G25_2_2.5.2.A.2016'
            WHEN T1.PMT_REMAIN_TERM_C >= 180 AND T1.PMT_REMAIN_TERM_C < 360 AND
                 T1.IDENTITY_CODE = '1' THEN
              'G25_2_2.5.2.B.2016'
            WHEN T1.PMT_REMAIN_TERM_C >= 360 AND T1.IDENTITY_CODE = '1' THEN
             'G25_2_2.5.2.C.2016'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE, --贷款余额
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(T.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
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
         FROM CBRC_fdm_lnac T
        LEFT JOIN CBRC_FDM_LNAC_PMT T1
          ON T.LOAN_NUM = T1.LOAN_NUM
         AND T.DATA_DATE = T1.DATA_DATE
        LEFT JOIN L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD --基准币种
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_GRADE_CD IN (1, 2) --五级分类为非不良（正常，关注）
         AND T.ACCT_TYP NOT LIKE '0101%' --去除住房抵押贷款
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN  ('130102', '130105')
) q_6
INSERT INTO `G25_2_2.5.2.B.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_2.5.2.C.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_2.5.2.B.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_2.5.2.C.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- ========== 逻辑组 7: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM as ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.5.2.A.2016' AS ITEM_NUM,
             SUM(T.ITEM_VAL1 + YQ_90) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_G2502_DATA_COLLECT_TMP T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM = 'G25_2_2.5.2.2'
       GROUP BY T.ORG_NUM
      UNION ALL
      --modiy by djh 20241210 5.2.2风险权重高于35% A列取：正常类+关注类（M0+M1+M2+M3） 信用卡
      SELECT I_DATADATE,
             '009803',
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_2.5.2.A.2016' AS ITEM_NUM,
             SUM(NVL(M0, 0) + NVL(T.M1, 0) + NVL(T.M2, 0) + NVL(T.M3, 0) + NVL(T.M4, 0) +
                 NVL(T.M5, 0) + NVL(T.M6, 0) + NVL(T.M6_UP, 0)),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM L_ACCT_CARD_CREDIT T
       WHERE T.DATA_DATE = I_DATADATE
         AND LXQKQS <= 3;

--5向个人、非金融机构、主权、公共部门实体和政策性金融机构等发放的贷款（不含住房抵押贷款）
    --5.2.2风险权重高于35%
     INSERT 
       INTO `__INDICATOR_PLACEHOLDER__` 
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
          'G2502' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C < 180 AND T1.IDENTITY_CODE = '1') OR
                 (T1.IDENTITY_CODE = '2' AND PMT_REMAIN_TERM_C <= 90) THEN -- .<6个月 或者逾期小于90天（<-90）即欠本欠息小于90天
             'G25_2_2.5.2.A.2016'
            WHEN T1.PMT_REMAIN_TERM_C >= 180 AND T1.PMT_REMAIN_TERM_C < 360 AND
                 T1.IDENTITY_CODE = '1' THEN
              'G25_2_2.5.2.B.2016'
            WHEN T1.PMT_REMAIN_TERM_C >= 360 AND T1.IDENTITY_CODE = '1' THEN
             'G25_2_2.5.2.C.2016'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE, --贷款余额
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(T.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
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
         FROM CBRC_fdm_lnac T
        LEFT JOIN CBRC_FDM_LNAC_PMT T1
          ON T.LOAN_NUM = T1.LOAN_NUM
         AND T.DATA_DATE = T1.DATA_DATE
        LEFT JOIN L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD --基准币种
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_GRADE_CD IN (1, 2) --五级分类为非不良（正常，关注）
         AND T.ACCT_TYP NOT LIKE '0101%' --去除住房抵押贷款
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN  ('130102', '130105');

--modiy by djh 20241210 5.2.2风险权重高于35% A列取：正常类+关注类（M0+M1+M2+M3） 信用卡
      INSERT
      INTO `__INDICATOR_PLACEHOLDER__` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE)
        SELECT I_DATADATE,
               '009803',
               null AS  DATA_DEPARTMENT,
               'CBRC' AS SYS_NAM,
               'G2502' AS REP_NUM,
               'G25_2_2.5.2.A.2016' AS ITEM_NUM,
               SUM(NVL(M0, 0) + NVL(T.M1, 0) + NVL(T.M2, 0) + NVL(T.M3, 0) +
                   NVL(T.M4, 0) + NVL(T.M5, 0) + NVL(T.M6, 0) +
                   NVL(T.M6_UP, 0)) AS TOTAL_VALUE
          FROM L_ACCT_CARD_CREDIT T
         WHERE T.DATA_DATE = I_DATADATE
           AND LXQKQS <= 3
) q_7
INSERT INTO `G25_2_2.5.2.A.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_2.5.2.A.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- 指标: G25_2_1.3.2.A.2016
--3.2欠稳定存款.金额（按剩余期限）.<6个月
    --3.2欠稳定存款.金额（按剩余期限）.6-12个月
    --3.2欠稳定存款.金额（按剩余期限）.≥1年
    INSERT INTO `G25_2_1.3.2.A.2016`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.3.2.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.3.2.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.3.2.C.2016' --≥1年
             END,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE T
       WHERE T.FLAG_CODE IN ('002', '004')--ALTER BY 石雨 20250929 JLBA202507210012 新增久悬财政性存款
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;

INSERT INTO `G25_2_1.3.2.A.2016`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_1.3.2.A.2016' AS ITEM_NUM, --add by djh20220622 注意与G2501规则相同，所有除不可提前支取的外，其他存款视为活期，要放在6个月内
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE T
       WHERE T.FLAG_CODE IN ('001', '003') --ALTER BY 石雨 20250929 JLBA202507210012 新增久悬财政性存款
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;

-----3.5.1其中：定期存款 '21510'其他定期储蓄存款（含有奖储蓄）没有到期日放次日
    /*INSERT INTO `G25_2_1.3.2.A.2016`
           (DATA_DATE, --数据日期
            ORG_NUM, --机构号
            SYS_NAM, --模块简称
            REP_NUM, --报表编号
            ITEM_NUM, --指标号
            ITEM_VAL, --指标值
            FLAG, --标志位
            B_CURR_CD --标志位
            )
          SELECT I_DATADATE,
                  A.ORG_NUM AS ORG_NUM,
                 'CBRC' AS SYS_NAM,
                 'G2502' AS REP_NUM,
                 'G25_2_1.3.2.A.2016', --3.2欠稳定存款
                 sum(A.CREDIT_BAL * B.CCY_RATE),
                  '2' AS FLAG,
                  'ALL' AS B_CURR_CD
            FROM  V_PUB_IDX_FINA_GL A
            LEFT JOIN L_PUBL_RATE B
              ON A.DATA_DATE = B.DATA_DATE
             AND A.CURR_CD = B.BASIC_CCY
             AND B.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
             AND A.ITEM_CD = '20110109' --'21510'其他定期储蓄存款（含有奖储蓄）
             AND A.CURR_CD <> 'BWB'
             AND A.CREDIT_BAL<>0
             AND A.ORG_NUM NOT LIKE '%0000' --去掉分行，汇总时不需要
             AND A.ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构，汇总时会导致机构重复
                                   '510000', --磐石吉银村镇银行
                                   '222222', --东盛除双阳汇总
                                   '333333', --新双阳
                                   '444444', --净月潭除双阳
                                   '555555') --长春分行（除双阳、榆树、农安）
             GROUP BY ORG_NUM;

--3.2欠稳定存款.金额（按剩余期限）.<6个月
    --3.2欠稳定存款.金额（按剩余期限）.6-12个月
    --3.2欠稳定存款.金额（按剩余期限）.≥1年
    INSERT INTO `G25_2_1.3.2.A.2016`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.3.2.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.3.2.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.3.2.C.2016' --≥1年
             END,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE T
       WHERE T.FLAG_CODE IN ('002', '004')--ALTER BY 石雨 20250929 JLBA202507210012 新增久悬财政性存款
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;

INSERT INTO `G25_2_1.3.2.A.2016`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_1.3.2.A.2016' AS ITEM_NUM, --add by djh20220622 注意与G2501规则相同，所有除不可提前支取的外，其他存款视为活期，要放在6个月内
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_UNSTABLE T
       WHERE T.FLAG_CODE IN ('001', '003') --ALTER BY 石雨 20250929 JLBA202507210012 新增久悬财政性存款
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;

-----3.5.1其中：定期存款 '21510'其他定期储蓄存款（含有奖储蓄）没有到期日放次日
    /*INSERT INTO `G25_2_1.3.2.A.2016`
           (DATA_DATE, --数据日期
            ORG_NUM, --机构号
            SYS_NAM, --模块简称
            REP_NUM, --报表编号
            ITEM_NUM, --指标号
            ITEM_VAL, --指标值
            FLAG, --标志位
            B_CURR_CD --标志位
            )
          SELECT I_DATADATE,
                  A.ORG_NUM AS ORG_NUM,
                 'CBRC' AS SYS_NAM,
                 'G2502' AS REP_NUM,
                 'G25_2_1.3.2.A.2016', --3.2欠稳定存款
                 sum(A.CREDIT_BAL * B.CCY_RATE),
                  '2' AS FLAG,
                  'ALL' AS B_CURR_CD
            FROM  V_PUB_IDX_FINA_GL A
            LEFT JOIN L_PUBL_RATE B
              ON A.DATA_DATE = B.DATA_DATE
             AND A.CURR_CD = B.BASIC_CCY
             AND B.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
             AND A.ITEM_CD = '20110109' --'21510'其他定期储蓄存款（含有奖储蓄）
             AND A.CURR_CD <> 'BWB'
             AND A.CREDIT_BAL<>0
             AND A.ORG_NUM NOT LIKE '%0000' --去掉分行，汇总时不需要
             AND A.ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构，汇总时会导致机构重复
                                   '510000', --磐石吉银村镇银行
                                   '222222', --东盛除双阳汇总
                                   '333333', --新双阳
                                   '444444', --净月潭除双阳
                                   '555555') --长春分行（除双阳、榆树、农安）
             GROUP BY ORG_NUM;


-- ========== 逻辑组 9: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.4.1.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.4.1.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.4.1.C.2016' --≥1年
             END AS ITEM_NUM,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '001' --有业务关系
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;

--4.1业务关系存款.金额（按剩余期限）.<6个月
    --4.1业务关系存款.金额（按剩余期限）.6-12个月
    --4.1业务关系存款.金额（按剩余期限）.≥1年
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.4.1.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.4.1.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.4.1.C.2016' --≥1年
             END AS ITEM_NUM,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '001' --有业务关系
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE
) q_9
INSERT INTO `G25_2_1.4.1.C.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_1.4.1.B.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- ========== 逻辑组 10: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009804',
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              ITEM_NUM,
              SUM(BALANCE),
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT CASE
                        WHEN A.MATURITY_DT - A.DATA_DATE >= 360 THEN
                         'G25_2_2.7.3.2.C.2016'
                        WHEN A.MATURITY_DT - A.DATA_DATE >= 180 THEN
                         'G25_2_2.7.3.2.B.2016'
                        ELSE
                         'G25_2_2.7.3.2.A.2016'
                      END AS ITEM_NUM,
                      SUM(LOAN_ACCT_BAL) AS BALANCE
                 FROM L_ACCT_LOAN A
                WHERE DATA_DATE = I_DATADATE
                  AND (A.ITEM_CD LIKE '130102%' OR A.ITEM_CD LIKE '130105%')
                  AND A.LOAN_ACCT_BAL > 0
                     --AND ORG_NUM NOT LIKE '51%'
                  AND A.ORG_NUM NOT LIKE '5%'
                  AND A.ORG_NUM NOT LIKE '6%' --ADD BY CH 20231031
                GROUP BY CASE
                           WHEN A.MATURITY_DT - A.DATA_DATE >= 360 THEN
                            'G25_2_2.7.3.2.C.2016'
                           WHEN A.MATURITY_DT - A.DATA_DATE >= 180 THEN
                            'G25_2_2.7.3.2.B.2016'
                           ELSE
                            'G25_2_2.7.3.2.A.2016'
                         END
               UNION ALL
               SELECT CASE
                        WHEN B.END_DT - B.DATA_DATE >= 360 THEN
                         'G25_2_2.7.3.2.C.2016'
                        WHEN B.END_DT - B.DATA_DATE >= 180 THEN
                         'G25_2_2.7.3.2.B.2016'
                        ELSE
                         'G25_2_2.7.3.2.A.2016'
                      END AS ITEM_NUM,
                      SUM(A.BALANCE * TT.CCY_RATE) AS BALANCE
                 FROM L_AGRE_REPURCHASE_GUARANTY_INFO A
                INNER JOIN V_PUB_FUND_REPURCHASE B
                   ON A.ACCT_NUM = B.ACCT_NUM
                  AND B.DATA_DATE = I_DATADATE
                  AND B.BUSI_TYPE LIKE '1%' --买入返售
                  AND B.ASS_TYPE = '1' --债券
                  AND B.BALANCE > 0
                 LEFT JOIN L_PUBL_RATE TT
                   ON TT.CCY_DATE = I_DATADATE
                  AND TT.BASIC_CCY = B.CURR_CD
                  AND TT.FORWARD_CCY = 'CNY'
                WHERE A.DATA_DATE = I_DATADATE
                  AND A.PLEDGE_ASSETS_TYPE <> 'A'
                  AND A.ORG_NUM NOT LIKE '5%'
                  AND A.ORG_NUM NOT LIKE '6%' --ADD BY CH 20231031
                GROUP BY CASE
                           WHEN B.END_DT - B.DATA_DATE >= 360 THEN
                            'G25_2_2.7.3.2.C.2016'
                           WHEN B.END_DT - B.DATA_DATE >= 180 THEN
                            'G25_2_2.7.3.2.B.2016'
                           ELSE
                            'G25_2_2.7.3.2.A.2016'
                         END
               UNION ALL   --ADD BY DJH 20240510  金融市场部 009804  补充买入返售票据
               SELECT CASE
                        WHEN A.END_DT - B.DATA_DATE >= 360 THEN
                         'G25_2_2.7.3.2.C.2016'
                        WHEN A.END_DT - B.DATA_DATE >= 180 THEN
                         'G25_2_2.7.3.2.B.2016'
                        ELSE
                         'G25_2_2.7.3.2.A.2016'
                      END AS ITEM_NUM,
                      SUM(A.BALANCE * U.CCY_RATE) AS BALANCE
                 FROM V_PUB_FUND_REPURCHASE A
                 LEFT JOIN L_AGRE_BILL_INFO B -- 商业汇票票面信息表
                   ON A.SUBJECT_CD = B.BILL_NUM
                  AND B.DATA_DATE = I_DATADATE
                 LEFT JOIN L_PUBL_RATE U
                   ON U.CCY_DATE = I_DATADATE
                  AND U.BASIC_CCY = A.CURR_CD --基准币种
                  AND U.FORWARD_CCY = 'CNY' --折算币种
                WHERE A.DATA_DATE = I_DATADATE
                  AND A.GL_ITEM_CODE = '111102' --质押式买入返售票据
                  AND A.BALANCE > 0
                  AND A.ORG_NUM NOT LIKE '5%'
                  AND A.ORG_NUM NOT LIKE '6%'
                GROUP BY CASE
                           WHEN A.END_DT - B.DATA_DATE >= 360 THEN
                            'G25_2_2.7.3.2.C.2016'
                           WHEN A.END_DT - B.DATA_DATE >= 180 THEN
                            'G25_2_2.7.3.2.B.2016'
                           ELSE
                            'G25_2_2.7.3.2.A.2016'
                         END)
        GROUP BY ITEM_NUM;

--7.3.2其他贷款
    /*存放同业定期持有仓位（暂时全行都没有）+1302同业拆出/同业借出定期持有仓位按剩余期限划分填报在009820*/

    --ADD BY DJH 20240510  同业金融部 009820
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，外币折人民币1302拆放同业余额
      INSERT INTO `__INDICATOR_PLACEHOLDER__`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                  'G25_2_2.7.3.2.C.2016' ---1年以上
                 WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                  'G25_2_2.7.3.2.B.2016' --6个月-1年
                 ELSE
                  'G25_2_2.7.3.2.A.2016'
               END AS ITEM_NUM,
               SUM(ITEM_VAL) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT 
                 A.GL_ITEM_CODE,
                 A.CUST_ID,
                 SUM(ACCT_BAL_RMB) ITEM_VAL,
                 MATUR_DATE,
                 A.ORG_NUM
                  FROM CBRC_TMP_A_CBRC_LOAN_BAL A
                 WHERE A.FLAG = '02' --1302(拆出资金/借出)
                   AND ACCT_BAL_RMB <> 0
                   AND A.ORG_NUM IN('009820','009801') --(有其他机构)
                 GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
         GROUP BY A.ORG_NUM,
                  CASE
                    WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                     'G25_2_2.7.3.2.C.2016' ---1年以上
                    WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                     'G25_2_2.7.3.2.B.2016' --6个月-1年
                    ELSE
                     'G25_2_2.7.3.2.A.2016'
                  END;

--ADD BY DJH 20240510  同业金融部 009820
   --存放同业定期持有仓位（暂时全行都没有） 没有数
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_2.7.3.2.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_2.7.3.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.7.3.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(ACCT_BAL_RMB) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
                 AND ACCT_BAL_RMB <> 0
                 AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '101102' --此处存放同业定期
                 AND A.ORG_NUM NOT LIKE '5%'
                 AND A.ORG_NUM NOT LIKE '6%'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
       GROUP BY CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_2.7.3.2.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_2.7.3.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.7.3.2.A.2016'
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
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009804',
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              ITEM_NUM,
              SUM(BALANCE),
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT CASE
                        WHEN A.MATURITY_DT - A.DATA_DATE >= 360 THEN
                         'G25_2_2.7.3.2.C.2016'
                        WHEN A.MATURITY_DT - A.DATA_DATE >= 180 THEN
                         'G25_2_2.7.3.2.B.2016'
                        ELSE
                         'G25_2_2.7.3.2.A.2016'
                      END AS ITEM_NUM,
                      SUM(LOAN_ACCT_BAL) AS BALANCE
                 FROM L_ACCT_LOAN A
                WHERE DATA_DATE = I_DATADATE
                  AND (A.ITEM_CD LIKE '130102%' OR A.ITEM_CD LIKE '130105%')
                  AND A.LOAN_ACCT_BAL > 0
                     --AND ORG_NUM NOT LIKE '51%'
                  AND A.ORG_NUM NOT LIKE '5%'
                  AND A.ORG_NUM NOT LIKE '6%' --ADD BY CH 20231031
                GROUP BY CASE
                           WHEN A.MATURITY_DT - A.DATA_DATE >= 360 THEN
                            'G25_2_2.7.3.2.C.2016'
                           WHEN A.MATURITY_DT - A.DATA_DATE >= 180 THEN
                            'G25_2_2.7.3.2.B.2016'
                           ELSE
                            'G25_2_2.7.3.2.A.2016'
                         END
               UNION ALL
               SELECT CASE
                        WHEN B.END_DT - B.DATA_DATE >= 360 THEN
                         'G25_2_2.7.3.2.C.2016'
                        WHEN B.END_DT - B.DATA_DATE >= 180 THEN
                         'G25_2_2.7.3.2.B.2016'
                        ELSE
                         'G25_2_2.7.3.2.A.2016'
                      END AS ITEM_NUM,
                      SUM(A.BALANCE * TT.CCY_RATE) AS BALANCE
                 FROM L_AGRE_REPURCHASE_GUARANTY_INFO A
                INNER JOIN V_PUB_FUND_REPURCHASE B
                   ON A.ACCT_NUM = B.ACCT_NUM
                  AND B.DATA_DATE = I_DATADATE
                  AND B.BUSI_TYPE LIKE '1%' --买入返售
                  AND B.ASS_TYPE = '1' --债券
                  AND B.BALANCE > 0
                 LEFT JOIN L_PUBL_RATE TT
                   ON TT.CCY_DATE = I_DATADATE
                  AND TT.BASIC_CCY = B.CURR_CD
                  AND TT.FORWARD_CCY = 'CNY'
                WHERE A.DATA_DATE = I_DATADATE
                  AND A.PLEDGE_ASSETS_TYPE <> 'A'
                  AND A.ORG_NUM NOT LIKE '5%'
                  AND A.ORG_NUM NOT LIKE '6%' --ADD BY CH 20231031
                GROUP BY CASE
                           WHEN B.END_DT - B.DATA_DATE >= 360 THEN
                            'G25_2_2.7.3.2.C.2016'
                           WHEN B.END_DT - B.DATA_DATE >= 180 THEN
                            'G25_2_2.7.3.2.B.2016'
                           ELSE
                            'G25_2_2.7.3.2.A.2016'
                         END
               UNION ALL   --ADD BY DJH 20240510  金融市场部 009804  补充买入返售票据
               SELECT CASE
                        WHEN A.END_DT - B.DATA_DATE >= 360 THEN
                         'G25_2_2.7.3.2.C.2016'
                        WHEN A.END_DT - B.DATA_DATE >= 180 THEN
                         'G25_2_2.7.3.2.B.2016'
                        ELSE
                         'G25_2_2.7.3.2.A.2016'
                      END AS ITEM_NUM,
                      SUM(A.BALANCE * U.CCY_RATE) AS BALANCE
                 FROM V_PUB_FUND_REPURCHASE A
                 LEFT JOIN L_AGRE_BILL_INFO B -- 商业汇票票面信息表
                   ON A.SUBJECT_CD = B.BILL_NUM
                  AND B.DATA_DATE = I_DATADATE
                 LEFT JOIN L_PUBL_RATE U
                   ON U.CCY_DATE = I_DATADATE
                  AND U.BASIC_CCY = A.CURR_CD --基准币种
                  AND U.FORWARD_CCY = 'CNY' --折算币种
                WHERE A.DATA_DATE = I_DATADATE
                  AND A.GL_ITEM_CODE = '111102' --质押式买入返售票据
                  AND A.BALANCE > 0
                  AND A.ORG_NUM NOT LIKE '5%'
                  AND A.ORG_NUM NOT LIKE '6%'
                GROUP BY CASE
                           WHEN A.END_DT - B.DATA_DATE >= 360 THEN
                            'G25_2_2.7.3.2.C.2016'
                           WHEN A.END_DT - B.DATA_DATE >= 180 THEN
                            'G25_2_2.7.3.2.B.2016'
                           ELSE
                            'G25_2_2.7.3.2.A.2016'
                         END)
        GROUP BY ITEM_NUM;

--7.3.2其他贷款
    /*存放同业定期持有仓位（暂时全行都没有）+1302同业拆出/同业借出定期持有仓位按剩余期限划分填报在009820*/

    --ADD BY DJH 20240510  同业金融部 009820
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，外币折人民币1302拆放同业余额
      INSERT INTO `__INDICATOR_PLACEHOLDER__`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               A.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                  'G25_2_2.7.3.2.C.2016' ---1年以上
                 WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                  'G25_2_2.7.3.2.B.2016' --6个月-1年
                 ELSE
                  'G25_2_2.7.3.2.A.2016'
               END AS ITEM_NUM,
               SUM(ITEM_VAL) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT 
                 A.GL_ITEM_CODE,
                 A.CUST_ID,
                 SUM(ACCT_BAL_RMB) ITEM_VAL,
                 MATUR_DATE,
                 A.ORG_NUM
                  FROM CBRC_TMP_A_CBRC_LOAN_BAL A
                 WHERE A.FLAG = '02' --1302(拆出资金/借出)
                   AND ACCT_BAL_RMB <> 0
                   AND A.ORG_NUM IN('009820','009801') --(有其他机构)
                 GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
         GROUP BY A.ORG_NUM,
                  CASE
                    WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                     'G25_2_2.7.3.2.C.2016' ---1年以上
                    WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                     'G25_2_2.7.3.2.B.2016' --6个月-1年
                    ELSE
                     'G25_2_2.7.3.2.A.2016'
                  END;

--ADD BY DJH 20240510  同业金融部 009820
   --存放同业定期持有仓位（暂时全行都没有） 没有数
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_2.7.3.2.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_2.7.3.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.7.3.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(ACCT_BAL_RMB) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
                 AND ACCT_BAL_RMB <> 0
                 AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '101102' --此处存放同业定期
                 AND A.ORG_NUM NOT LIKE '5%'
                 AND A.ORG_NUM NOT LIKE '6%'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
       GROUP BY CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_2.7.3.2.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_2.7.3.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.7.3.2.A.2016'
                END
) q_10
INSERT INTO `G25_2_2.7.3.2.B.2016` (DATA_DATE,  
        ORG_NUM,  
        SYS_NAM,  
        REP_NUM,  
        ITEM_NUM,  
        ITEM_VAL,  
        FLAG,  
        B_CURR_CD)
SELECT *
INSERT INTO `G25_2_2.7.3.2.A.2016` (DATA_DATE,  
        ORG_NUM,  
        SYS_NAM,  
        REP_NUM,  
        ITEM_NUM,  
        ITEM_VAL,  
        FLAG,  
        B_CURR_CD)
SELECT *;

-- 指标: G25_2_1.6.1.A.2016
--6.1业务关系存款
    /*分行的东北证券股份有限公司和永诚保险资产管理有限公司的持有仓位放<6个月中，资产类型为同业存放的定期中取字段原币金额按剩余期限划分报在009820机构*/

    INSERT INTO `G25_2_1.6.1.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM,  --分行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_1.6.1.A.2016' AS ITEM_NUM, --6个月内
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.GL_ITEM_CODE,
                     A.CUST_ID,
                     A.JYDSTYDM,
                     SUM(A.BALANCE * CCY_RATE) ITEM_VAL,
                     MATURE_DATE
                FROM V_PUB_FUND_MMFUND A
                LEFT JOIN L_PUBL_RATE TT
                  ON TT.CCY_DATE = I_DATADATE
                 AND TT.BASIC_CCY = A.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                -- AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201201' --同业存放活期款项
                 AND A.BALANCE <> 0
                 AND A.CUST_ID  IN ('8913402328', '8916869348') --8913402328东北证券股份有限公司 8916869348永诚保险资产管理有限公司
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A;

--ADD BY DJH 20240510  同业金融部 009820
      INSERT INTO `G25_2_1.6.1.A.2016`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               '009820' AS ORG_NUM, --分行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                  'G25_2_1.6.1.C.2016' ---1年以上
                 WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                  'G25_2_1.6.1.B.2016' --6个月-1年
                 ELSE
                  'G25_2_1.6.1.A.2016'
               END AS ITEM_NUM,
               SUM(ITEM_VAL) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.GL_ITEM_CODE,
                       A.CUST_ID,
                       A.JYDSTYDM,
                       SUM(A.BALANCE * CCY_RATE) ITEM_VAL,
                       MATURE_DATE
                  FROM V_PUB_FUND_MMFUND A
                  LEFT JOIN L_PUBL_RATE TT
                    ON TT.CCY_DATE = I_DATADATE
                   AND TT.BASIC_CCY = A.CURR_CD
                   AND TT.FORWARD_CCY = 'CNY'
                 WHERE A.DATA_DATE = I_DATADATE
                   AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放的定期
                   AND A.BALANCE <> 0
                   AND A.ORG_NUM NOT LIKE '5%'
                   AND A.ORG_NUM NOT LIKE '6%'
                 GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A
         GROUP BY CASE
                    WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                     'G25_2_1.6.1.C.2016' ---1年以上
                    WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                     'G25_2_1.6.1.B.2016' --6个月-1年
                    ELSE
                     'G25_2_1.6.1.A.2016'
                  END;

--6.1业务关系存款
    /*分行的东北证券股份有限公司和永诚保险资产管理有限公司的持有仓位放<6个月中，资产类型为同业存放的定期中取字段原币金额按剩余期限划分报在009820机构*/

    INSERT INTO `G25_2_1.6.1.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM,  --分行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_1.6.1.A.2016' AS ITEM_NUM, --6个月内
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.GL_ITEM_CODE,
                     A.CUST_ID,
                     A.JYDSTYDM,
                     SUM(A.BALANCE * CCY_RATE) ITEM_VAL,
                     MATURE_DATE
                FROM V_PUB_FUND_MMFUND A
                LEFT JOIN L_PUBL_RATE TT
                  ON TT.CCY_DATE = I_DATADATE
                 AND TT.BASIC_CCY = A.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                -- AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201201' --同业存放活期款项
                 AND A.BALANCE <> 0
                 AND A.CUST_ID  IN ('8913402328', '8916869348') --8913402328东北证券股份有限公司 8916869348永诚保险资产管理有限公司
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A;

--ADD BY DJH 20240510  同业金融部 009820
      INSERT INTO `G25_2_1.6.1.A.2016`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               '009820' AS ORG_NUM, --分行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                  'G25_2_1.6.1.C.2016' ---1年以上
                 WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                  'G25_2_1.6.1.B.2016' --6个月-1年
                 ELSE
                  'G25_2_1.6.1.A.2016'
               END AS ITEM_NUM,
               SUM(ITEM_VAL) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.GL_ITEM_CODE,
                       A.CUST_ID,
                       A.JYDSTYDM,
                       SUM(A.BALANCE * CCY_RATE) ITEM_VAL,
                       MATURE_DATE
                  FROM V_PUB_FUND_MMFUND A
                  LEFT JOIN L_PUBL_RATE TT
                    ON TT.CCY_DATE = I_DATADATE
                   AND TT.BASIC_CCY = A.CURR_CD
                   AND TT.FORWARD_CCY = 'CNY'
                 WHERE A.DATA_DATE = I_DATADATE
                   AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放的定期
                   AND A.BALANCE <> 0
                   AND A.ORG_NUM NOT LIKE '5%'
                   AND A.ORG_NUM NOT LIKE '6%'
                 GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A
         GROUP BY CASE
                    WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                     'G25_2_1.6.1.C.2016' ---1年以上
                    WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                     'G25_2_1.6.1.B.2016' --6个月-1年
                    ELSE
                     'G25_2_1.6.1.A.2016'
                  END;


-- 指标: G25_2_2.15.C.2016
--ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO `G25_2_2.15.C.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.FLAG = '06' THEN
                'G25_2_2.15.A.2016'
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(INTEREST_ACCURAL) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM,
               A.FLAG
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.FLAG IN ('06', '02', '04') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
                 AND A.ORG_NUM = '009820'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM,A.FLAG) A
       GROUP BY CASE
                  WHEN A.FLAG = '06' THEN
                   'G25_2_2.15.A.2016'
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;

--ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO `G25_2_2.15.C.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 AND
                    ACCT_NUM NOT IN
                    ('N000310000012993', 'N000310000008023', 'N000310000012013') THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 AND
                    ACCT_NUM NOT IN
                    ('N000310000012993', 'N000310000008023', 'N000310000012013') THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(DECODE(A.GL_ITEM_CODE,'15010201',ACCT_BAL_RMB+INTEREST_ACCURAL,A.INTEREST_ACCURAL)) ITEM_VAL,--SUM(A.INTEREST_ACCURAL) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM,
               ACCT_NUM
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.FLAG IN ('07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户  '15010201' )
                 AND a.ORG_NUM = '009820'
               GROUP BY A.GL_ITEM_CODE,
                        A.CUST_ID,
                        MATUR_DATE,
                        A.ORG_NUM,
                        ACCT_NUM) A
       GROUP BY CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 AND
                       ACCT_NUM NOT IN ('N000310000012993',
                                        'N000310000008023',
                                        'N000310000012013') THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 AND
                       ACCT_NUM NOT IN ('N000310000012993',
                                        'N000310000008023',
                                        'N000310000012013') THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;

--特定目的载体11010303 本金+公允价值
    INSERT INTO `G25_2_2.15.C.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN (A.DC_DATE < 0 OR C.REDEMPTION_TYPE = '随时赎回') THEN
                'G25_2_2.15.A.2016'
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(A.FACE_VAL +A.MK_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM V_PUB_FUND_INVEST A
       INNER JOIN L_AGRE_OTHER_SUBJECT_INFO C -- 其他标的物信息表
          ON A.SUBJECT_CD = C.SUBJECT_CD
         AND C.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009820'
         AND A.GL_ITEM_CODE = '11010303'
       GROUP BY CASE
                  WHEN (A.DC_DATE < 0 OR C.REDEMPTION_TYPE = '随时赎回') THEN
                   'G25_2_2.15.A.2016'
                  WHEN A.DC_DATE >= 360 THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.DC_DATE >= 180 THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;

/*    --15010201  本金借方-贷方
    INSERT INTO `G25_2_2.15.C.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.15.C.2016' AS ITEM_NUM,
             SUM(A.DEBIT_BAL) - SUM(CREDIT_BAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM L_FINA_GL A
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'BWB'
         AND ITEM_CD = '15010201'
         AND A.ORG_NUM = '009820'
       GROUP BY A.ITEM_CD, A.ORG_NUM;

--由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第16项不在系统取数，业务手填
    /*  --ADD BY DJH 20240510  投资银行部 009817
      --存量非标的本金+其他应收款+应收利息-存量非标本金的减值-其他应收款的减值-应收利息的减值，按剩余期限划分；逾期的放<6个月
      INSERT INTO `G25_2_2.15.C.2016`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               ORG_NUM AS ORG_NUM, --全行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                  'G25_2_2.15.C.2016' ---1年以上
                 WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                  'G25_2_2.15.B.2016' --6个月-1年
                 ELSE
                  'G25_2_2.15.A.2016'
               END AS ITEM_NUM,
               SUM(ACCT_BAL_RMB+INTEREST_ACCURAL+QTYSK-PRIN_FINAL_RESLT-COLLBL_INT_FINAL_RESLT) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.ORG_NUM,
                       A.MATUR_DATE,
                       SUM(NVL(A.ACCT_BAL_RMB,0)) AS ACCT_BAL_RMB, --本金
                       SUM(NVL(A.INTEREST_ACCURAL,0)) AS INTEREST_ACCURAL, --其他应收款
                       SUM(NVL(A.QTYSK,0)) AS QTYSK, --其他应收款
                       SUM(NVL(PRIN_FINAL_RESLT,0)) AS PRIN_FINAL_RESLT, --本金的减值
                       SUM(NVL(COLLBL_INT_FINAL_RESLT,0)) AS COLLBL_INT_FINAL_RESLT, --应收利息的减值
                       0 AS QT --其他应收款的减值
                  FROM CBRC_TMP_A_CBRC_LOAN_BAL A
                  LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE_G B
                    ON A.ACCT_NUM = B.ACCT_NUM
                 WHERE A.DATA_DATE = I_DATADATE
                   AND FLAG = '09'
                 GROUP BY A.ORG_NUM, A.MATUR_DATE) A
         GROUP BY ORG_NUM,
                  CASE
                    WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                     'G25_2_2.15.C.2016' ---1年以上
                    WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                     'G25_2_2.15.B.2016' --6个月-1年
                    ELSE
                     'G25_2_2.15.A.2016'
                  END;

--债券正常
 INSERT INTO `G25_2_2.15.C.2016`
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          A.ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
            WHEN DC_DATE >= 360 THEN
             'G25_2_2.15.C.2016' ---1年以上
            WHEN DC_DATE >= 180 THEN
             'G25_2_2.15.B.2016' --6个月-1年
            ELSE
             'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(CASE
                WHEN A.ACCT_NUM = '1523004' THEN ACCRUAL - BJ_JZ - YSLX_JZ - YJLX_JZ
                ELSE ACCRUAL - BJ_JZ - YSLX_JZ - YJLX_JZ
               END) AS ITEM_VAL,
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            DC_DATE,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG = '01' --债券
              AND A.DC_DATE > 0
              AND ACCT_NUM <>'X0003120B2700001') A  -- ADD BY DJH 20240510  金融市场部 X0003120B2700001  18华阳经贸CP001  与G21判定规则相同，这笔默认逾期,已放在上面，此处去掉
    GROUP BY A.ORG_NUM,
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;

--同业存单  买入返售的应收（票据+债券)
 INSERT INTO `G25_2_2.15.C.2016`
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
             WHEN A.DC_DATE >= 360 THEN
              'G25_2_2.15.C.2016' ---1年以上
             WHEN A.DC_DATE >= 180 THEN
              'G25_2_2.15.B.2016' --6个月-1年
             ELSE
              'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(ACCRUAL - BJ_JZ - YSLX_JZ) AS ITEM_VAL,
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            A.DC_DATE,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG IN ('02', '04', '05')) A --同业存单  买入返售的应收（票据+债券)
    GROUP BY ORG_NUM,
             CASE
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;

--转贴现的公允价值+转贴现的利息调整+转贴现的减值--全行，报在009804，刨除磐石
 INSERT INTO `G25_2_2.15.C.2016`
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          A.ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
            WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
             'G25_2_2.15.C.2016' ---1年以上
            WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
             'G25_2_2.15.B.2016' --6个月-1年
            ELSE
             'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(MK_VAL-INT_ADJEST_AMT-BJ_JZ) AS ITEM_VAL, -- 公允价值（有正有负） - 利息调整（贷方）  - 本金减值
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            MATURITY_DT,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG = '03') A --转贴现
    GROUP BY A.ORG_NUM,
             CASE
               WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;

A列资产负债表资产总计期末余额（年末保持与G01利润结转后的资产总计一致）
     16.其他资产.金额（按剩余期限）6-12个月:G1.9其他有确定到期日的资产(理财资管回传表)180≦剩余期限<360
     16.其他资产.金额（按剩余期限）≥1年:G1.9其他有确定到期日的资产(理财资管回传表)剩余期限一年以上*/
   INSERT INTO `G25_2_2.15.C.2016`
     (DATA_DATE, --数据日期
      ORG_NUM, --机构号
      SYS_NAM, --模块简称
      REP_NUM, --报表编号
      ITEM_NUM, --指标号
      ITEM_VAL, --指标值
      FLAG, --标志位
      B_CURR_CD)
     SELECT I_DATADATE AS DATA_DATE, --数据日期
            A.ORG_NUM AS ORG_NUM,
            'CBRC' AS SYS_NAM, --模块简称
            'G2502' AS REP_NUM, --报表编号
            CASE
              WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
               'G25_2_2.15.C.2016' ---1年以上
              WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
               'G25_2_2.15.B.2016' --6个月-1年
             /* ELSE
               'G25_2_2.16.A.2016'*/
            END AS ITEM_NUM,
            SUM(RECVAPAY_AMT) AS ITEM_VAL,
            '2' AS FLAG,
            'ALL' AS B_CURR_CD
       FROM (SELECT A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT) RECVAPAY_AMT
               FROM cbrc_tmp_fimm_product_bal A
              WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
                AND FLAG = '1'
             GROUP BY A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE)
             UNION ALL
             SELECT A.ORG_NUM,REDEMP_DATE AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT)
               FROM cbrc_tmp_fimm_product_bal A
              WHERE A.OPER_TYPE LIKE '2%' --运行方式是封闭式
                AND FLAG = '1'
              GROUP BY A.ORG_NUM,REDEMP_DATE) A
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
                  'G25_2_2.15.C.2016' ---1年以上
                 WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
                  'G25_2_2.15.B.2016' --6个月-1年
                /* ELSE
                  'G25_2_2.16.A.2016'*/
               END;

--ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO `G25_2_2.15.C.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.FLAG = '06' THEN
                'G25_2_2.15.A.2016'
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(INTEREST_ACCURAL) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM,
               A.FLAG
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.FLAG IN ('06', '02', '04') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
                 AND A.ORG_NUM = '009820'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM,A.FLAG) A
       GROUP BY CASE
                  WHEN A.FLAG = '06' THEN
                   'G25_2_2.15.A.2016'
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;

--ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO `G25_2_2.15.C.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 AND
                    ACCT_NUM NOT IN
                    ('N000310000012993', 'N000310000008023', 'N000310000012013') THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 AND
                    ACCT_NUM NOT IN
                    ('N000310000012993', 'N000310000008023', 'N000310000012013') THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(DECODE(A.GL_ITEM_CODE,'15010201',ACCT_BAL_RMB+INTEREST_ACCURAL,A.INTEREST_ACCURAL)) ITEM_VAL,--SUM(A.INTEREST_ACCURAL) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM,
               ACCT_NUM
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.FLAG IN ('07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户  '15010201' )
                 AND a.ORG_NUM = '009820'
               GROUP BY A.GL_ITEM_CODE,
                        A.CUST_ID,
                        MATUR_DATE,
                        A.ORG_NUM,
                        ACCT_NUM) A
       GROUP BY CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 AND
                       ACCT_NUM NOT IN ('N000310000012993',
                                        'N000310000008023',
                                        'N000310000012013') THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 AND
                       ACCT_NUM NOT IN ('N000310000012993',
                                        'N000310000008023',
                                        'N000310000012013') THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;

--特定目的载体11010303 本金+公允价值
    INSERT INTO `G25_2_2.15.C.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN (A.DC_DATE < 0 OR C.REDEMPTION_TYPE = '随时赎回') THEN
                'G25_2_2.15.A.2016'
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(A.FACE_VAL +A.MK_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM V_PUB_FUND_INVEST A
       INNER JOIN L_AGRE_OTHER_SUBJECT_INFO C -- 其他标的物信息表
          ON A.SUBJECT_CD = C.SUBJECT_CD
         AND C.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009820'
         AND A.GL_ITEM_CODE = '11010303'
       GROUP BY CASE
                  WHEN (A.DC_DATE < 0 OR C.REDEMPTION_TYPE = '随时赎回') THEN
                   'G25_2_2.15.A.2016'
                  WHEN A.DC_DATE >= 360 THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.DC_DATE >= 180 THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;

/*    --15010201  本金借方-贷方
    INSERT INTO `G25_2_2.15.C.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.15.C.2016' AS ITEM_NUM,
             SUM(A.DEBIT_BAL) - SUM(CREDIT_BAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM L_FINA_GL A
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'BWB'
         AND ITEM_CD = '15010201'
         AND A.ORG_NUM = '009820'
       GROUP BY A.ITEM_CD, A.ORG_NUM;

--由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第16项不在系统取数，业务手填
    /*  --ADD BY DJH 20240510  投资银行部 009817
      --存量非标的本金+其他应收款+应收利息-存量非标本金的减值-其他应收款的减值-应收利息的减值，按剩余期限划分；逾期的放<6个月
      INSERT INTO `G25_2_2.15.C.2016`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               ORG_NUM AS ORG_NUM, --全行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                  'G25_2_2.15.C.2016' ---1年以上
                 WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                  'G25_2_2.15.B.2016' --6个月-1年
                 ELSE
                  'G25_2_2.15.A.2016'
               END AS ITEM_NUM,
               SUM(ACCT_BAL_RMB+INTEREST_ACCURAL+QTYSK-PRIN_FINAL_RESLT-COLLBL_INT_FINAL_RESLT) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.ORG_NUM,
                       A.MATUR_DATE,
                       SUM(NVL(A.ACCT_BAL_RMB,0)) AS ACCT_BAL_RMB, --本金
                       SUM(NVL(A.INTEREST_ACCURAL,0)) AS INTEREST_ACCURAL, --其他应收款
                       SUM(NVL(A.QTYSK,0)) AS QTYSK, --其他应收款
                       SUM(NVL(PRIN_FINAL_RESLT,0)) AS PRIN_FINAL_RESLT, --本金的减值
                       SUM(NVL(COLLBL_INT_FINAL_RESLT,0)) AS COLLBL_INT_FINAL_RESLT, --应收利息的减值
                       0 AS QT --其他应收款的减值
                  FROM CBRC_TMP_A_CBRC_LOAN_BAL A
                  LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE_G B
                    ON A.ACCT_NUM = B.ACCT_NUM
                 WHERE A.DATA_DATE = I_DATADATE
                   AND FLAG = '09'
                 GROUP BY A.ORG_NUM, A.MATUR_DATE) A
         GROUP BY ORG_NUM,
                  CASE
                    WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                     'G25_2_2.15.C.2016' ---1年以上
                    WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                     'G25_2_2.15.B.2016' --6个月-1年
                    ELSE
                     'G25_2_2.15.A.2016'
                  END;

--债券正常
 INSERT INTO `G25_2_2.15.C.2016`
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          A.ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
            WHEN DC_DATE >= 360 THEN
             'G25_2_2.15.C.2016' ---1年以上
            WHEN DC_DATE >= 180 THEN
             'G25_2_2.15.B.2016' --6个月-1年
            ELSE
             'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(CASE
                WHEN A.ACCT_NUM = '1523004' THEN ACCRUAL - BJ_JZ - YSLX_JZ - YJLX_JZ
                ELSE ACCRUAL - BJ_JZ - YSLX_JZ - YJLX_JZ
               END) AS ITEM_VAL,
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            DC_DATE,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG = '01' --债券
              AND A.DC_DATE > 0
              AND ACCT_NUM <>'X0003120B2700001') A  -- ADD BY DJH 20240510  金融市场部 X0003120B2700001  18华阳经贸CP001  与G21判定规则相同，这笔默认逾期,已放在上面，此处去掉
    GROUP BY A.ORG_NUM,
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;

--同业存单  买入返售的应收（票据+债券)
 INSERT INTO `G25_2_2.15.C.2016`
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
             WHEN A.DC_DATE >= 360 THEN
              'G25_2_2.15.C.2016' ---1年以上
             WHEN A.DC_DATE >= 180 THEN
              'G25_2_2.15.B.2016' --6个月-1年
             ELSE
              'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(ACCRUAL - BJ_JZ - YSLX_JZ) AS ITEM_VAL,
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            A.DC_DATE,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG IN ('02', '04', '05')) A --同业存单  买入返售的应收（票据+债券)
    GROUP BY ORG_NUM,
             CASE
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;

--转贴现的公允价值+转贴现的利息调整+转贴现的减值--全行，报在009804，刨除磐石
 INSERT INTO `G25_2_2.15.C.2016`
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          A.ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
            WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
             'G25_2_2.15.C.2016' ---1年以上
            WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
             'G25_2_2.15.B.2016' --6个月-1年
            ELSE
             'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(MK_VAL-INT_ADJEST_AMT-BJ_JZ) AS ITEM_VAL, -- 公允价值（有正有负） - 利息调整（贷方）  - 本金减值
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            MATURITY_DT,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG = '03') A --转贴现
    GROUP BY A.ORG_NUM,
             CASE
               WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;

A列资产负债表资产总计期末余额（年末保持与G01利润结转后的资产总计一致）
     16.其他资产.金额（按剩余期限）6-12个月:G1.9其他有确定到期日的资产(理财资管回传表)180≦剩余期限<360
     16.其他资产.金额（按剩余期限）≥1年:G1.9其他有确定到期日的资产(理财资管回传表)剩余期限一年以上*/
   INSERT INTO `G25_2_2.15.C.2016`
     (DATA_DATE, --数据日期
      ORG_NUM, --机构号
      SYS_NAM, --模块简称
      REP_NUM, --报表编号
      ITEM_NUM, --指标号
      ITEM_VAL, --指标值
      FLAG, --标志位
      B_CURR_CD)
     SELECT I_DATADATE AS DATA_DATE, --数据日期
            A.ORG_NUM AS ORG_NUM,
            'CBRC' AS SYS_NAM, --模块简称
            'G2502' AS REP_NUM, --报表编号
            CASE
              WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
               'G25_2_2.15.C.2016' ---1年以上
              WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
               'G25_2_2.15.B.2016' --6个月-1年
             /* ELSE
               'G25_2_2.16.A.2016'*/
            END AS ITEM_NUM,
            SUM(RECVAPAY_AMT) AS ITEM_VAL,
            '2' AS FLAG,
            'ALL' AS B_CURR_CD
       FROM (SELECT A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT) RECVAPAY_AMT
               FROM cbrc_tmp_fimm_product_bal A
              WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
                AND FLAG = '1'
             GROUP BY A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE)
             UNION ALL
             SELECT A.ORG_NUM,REDEMP_DATE AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT)
               FROM cbrc_tmp_fimm_product_bal A
              WHERE A.OPER_TYPE LIKE '2%' --运行方式是封闭式
                AND FLAG = '1'
              GROUP BY A.ORG_NUM,REDEMP_DATE) A
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
                  'G25_2_2.15.C.2016' ---1年以上
                 WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
                  'G25_2_2.15.B.2016' --6个月-1年
                /* ELSE
                  'G25_2_2.16.A.2016'*/
               END;


-- 指标: G25_2_2.7.3.1.A.2016
INSERT INTO `G25_2_2.7.3.1.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             B.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN B.END_DT - B.DATA_DATE >= 360 THEN
                'G25_2_2.7.3.1.C.2016'
               WHEN B.END_DT - B.DATA_DATE >= 180 THEN
                'G25_2_2.7.3.1.B.2016'
               ELSE
                'G25_2_2.7.3.1.A.2016'
             END,
             SUM(A.BALANCE * TT.CCY_RATE),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM L_AGRE_REPURCHASE_GUARANTY_INFO A
       INNER JOIN V_PUB_FUND_REPURCHASE B
          ON A.ACCT_NUM = B.ACCT_NUM
         AND B.DATA_DATE = I_DATADATE
         AND B.BUSI_TYPE LIKE '1%' --买入返售
         AND B.ASS_TYPE = '1' --债券
         AND B.BALANCE > 0
        LEFT JOIN L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = B.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.PLEDGE_ASSETS_TYPE = 'A' --质押物为一级资产
       GROUP BY B.ORG_NUM,CASE
                  WHEN B.END_DT - B.DATA_DATE >= 360 THEN
                   'G25_2_2.7.3.1.C.2016'
                  WHEN B.END_DT - B.DATA_DATE >= 180 THEN
                   'G25_2_2.7.3.1.B.2016'
                  ELSE
                   'G25_2_2.7.3.1.A.2016'
                END;

INSERT INTO `G25_2_2.7.3.1.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             B.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN B.END_DT - B.DATA_DATE >= 360 THEN
                'G25_2_2.7.3.1.C.2016'
               WHEN B.END_DT - B.DATA_DATE >= 180 THEN
                'G25_2_2.7.3.1.B.2016'
               ELSE
                'G25_2_2.7.3.1.A.2016'
             END,
             SUM(A.BALANCE * TT.CCY_RATE),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM L_AGRE_REPURCHASE_GUARANTY_INFO A
       INNER JOIN V_PUB_FUND_REPURCHASE B
          ON A.ACCT_NUM = B.ACCT_NUM
         AND B.DATA_DATE = I_DATADATE
         AND B.BUSI_TYPE LIKE '1%' --买入返售
         AND B.ASS_TYPE = '1' --债券
         AND B.BALANCE > 0
        LEFT JOIN L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = B.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.PLEDGE_ASSETS_TYPE = 'A' --质押物为一级资产
       GROUP BY B.ORG_NUM,CASE
                  WHEN B.END_DT - B.DATA_DATE >= 360 THEN
                   'G25_2_2.7.3.1.C.2016'
                  WHEN B.END_DT - B.DATA_DATE >= 180 THEN
                   'G25_2_2.7.3.1.B.2016'
                  ELSE
                   'G25_2_2.7.3.1.A.2016'
                END;


-- 指标: G25_2_1.6.3.A.2016
-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，2111卖出回购外币折人民币本金余额
    INSERT INTO `G25_2_1.6.3.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM,     
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             ITEM_CD,
             SUM(ACCRUAL),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT I_DATADATE AS DATA_DATE, --数据日期
                     ORG_NUM,
                     'CBRC' AS SYS_NAM, --模块简称
                     'G2502' AS REP_NUM, --报表编号
                     CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.6.3.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.6.3.B.2016'
                       ELSE
                        'G25_2_1.6.3.A.2016'
                     END AS ITEM_CD,
                     SUM(A.ACCT_BAL_RMB) AS ACCRUAL,
                     '2' AS FLAG,
                     'ALL' AS B_CURR_CD
                FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE FLAG = '07' --卖出回购
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY ORG_NUM,
                        CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.6.3.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.6.3.B.2016'
                          ELSE
                           'G25_2_1.6.3.A.2016'
                        END
              UNION ALL --ADD BY DJH 20240510  金融市场部 009804 补充拆入 2003同业拆入
              SELECT I_DATADATE AS DATA_DATE, --数据日期
                     ORG_NUM,
                     'CBRC' AS SYS_NAM, --模块简称
                     'G2502' AS REP_NUM, --报表编号
                     CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.6.3.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.6.3.B.2016'
                       ELSE
                        'G25_2_1.6.3.A.2016'
                     END,
                     SUM(A.ACCT_BAL_RMB) AS ACCRUAL,
                     '2' AS FLAG,
                     'ALL' AS B_CURR_CD
                FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE A.FLAG = '05' --同业拆入(有其他机构)
                 AND ACCT_BAL_RMB <> 0
                 AND A.ORG_NUM = '009804'
               GROUP BY ORG_NUM,
                        CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.6.3.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.6.3.B.2016'
                          ELSE
                           'G25_2_1.6.3.A.2016'
                        END)
       GROUP BY ITEM_CD,ORG_NUM;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，2111卖出回购外币折人民币本金余额
    INSERT INTO `G25_2_1.6.3.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             ITEM_CD,
             SUM(ACCRUAL),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT I_DATADATE AS DATA_DATE, --数据日期
                     ORG_NUM,
                     'CBRC' AS SYS_NAM, --模块简称
                     'G2502' AS REP_NUM, --报表编号
                     CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.6.3.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.6.3.B.2016'
                       ELSE
                        'G25_2_1.6.3.A.2016'
                     END AS ITEM_CD,
                     SUM(A.ACCT_BAL_RMB) AS ACCRUAL,
                     '2' AS FLAG,
                     'ALL' AS B_CURR_CD
                FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE FLAG = '07' --卖出回购
                 AND A.DATA_DATE = I_DATADATE
               GROUP BY ORG_NUM,
                        CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.6.3.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.6.3.B.2016'
                          ELSE
                           'G25_2_1.6.3.A.2016'
                        END
              UNION ALL --ADD BY DJH 20240510  金融市场部 009804 补充拆入 2003同业拆入
              SELECT I_DATADATE AS DATA_DATE, --数据日期
                     ORG_NUM,
                     'CBRC' AS SYS_NAM, --模块简称
                     'G2502' AS REP_NUM, --报表编号
                     CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.6.3.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.6.3.B.2016'
                       ELSE
                        'G25_2_1.6.3.A.2016'
                     END,
                     SUM(A.ACCT_BAL_RMB) AS ACCRUAL,
                     '2' AS FLAG,
                     'ALL' AS B_CURR_CD
                FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE A.FLAG = '05' --同业拆入(有其他机构)
                 AND ACCT_BAL_RMB <> 0
                 AND A.ORG_NUM = '009804'
               GROUP BY ORG_NUM,
                        CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.6.3.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.6.3.B.2016'
                          ELSE
                           'G25_2_1.6.3.A.2016'
                        END)
       GROUP BY ITEM_CD,ORG_NUM;


-- ========== 逻辑组 15: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.FLAG = '06' THEN
                'G25_2_2.15.A.2016'
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(INTEREST_ACCURAL) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM,
               A.FLAG
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.FLAG IN ('06', '02', '04') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
                 AND A.ORG_NUM = '009820'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM,A.FLAG) A
       GROUP BY CASE
                  WHEN A.FLAG = '06' THEN
                   'G25_2_2.15.A.2016'
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;

--ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 AND
                    ACCT_NUM NOT IN
                    ('N000310000012993', 'N000310000008023', 'N000310000012013') THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 AND
                    ACCT_NUM NOT IN
                    ('N000310000012993', 'N000310000008023', 'N000310000012013') THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(DECODE(A.GL_ITEM_CODE,'15010201',ACCT_BAL_RMB+INTEREST_ACCURAL,A.INTEREST_ACCURAL)) ITEM_VAL,--SUM(A.INTEREST_ACCURAL) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM,
               ACCT_NUM
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.FLAG IN ('07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户  '15010201' )
                 AND a.ORG_NUM = '009820'
               GROUP BY A.GL_ITEM_CODE,
                        A.CUST_ID,
                        MATUR_DATE,
                        A.ORG_NUM,
                        ACCT_NUM) A
       GROUP BY CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 AND
                       ACCT_NUM NOT IN ('N000310000012993',
                                        'N000310000008023',
                                        'N000310000012013') THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 AND
                       ACCT_NUM NOT IN ('N000310000012993',
                                        'N000310000008023',
                                        'N000310000012013') THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;

--特定目的载体11010303 本金+公允价值
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN (A.DC_DATE < 0 OR C.REDEMPTION_TYPE = '随时赎回') THEN
                'G25_2_2.15.A.2016'
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(A.FACE_VAL +A.MK_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM V_PUB_FUND_INVEST A
       INNER JOIN L_AGRE_OTHER_SUBJECT_INFO C -- 其他标的物信息表
          ON A.SUBJECT_CD = C.SUBJECT_CD
         AND C.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009820'
         AND A.GL_ITEM_CODE = '11010303'
       GROUP BY CASE
                  WHEN (A.DC_DATE < 0 OR C.REDEMPTION_TYPE = '随时赎回') THEN
                   'G25_2_2.15.A.2016'
                  WHEN A.DC_DATE >= 360 THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.DC_DATE >= 180 THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;

--由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第16项不在系统取数，业务手填
    /*  --ADD BY DJH 20240510  投资银行部 009817
      --存量非标的本金+其他应收款+应收利息-存量非标本金的减值-其他应收款的减值-应收利息的减值，按剩余期限划分；逾期的放<6个月
      INSERT INTO `__INDICATOR_PLACEHOLDER__`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               ORG_NUM AS ORG_NUM, --全行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                  'G25_2_2.15.C.2016' ---1年以上
                 WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                  'G25_2_2.15.B.2016' --6个月-1年
                 ELSE
                  'G25_2_2.15.A.2016'
               END AS ITEM_NUM,
               SUM(ACCT_BAL_RMB+INTEREST_ACCURAL+QTYSK-PRIN_FINAL_RESLT-COLLBL_INT_FINAL_RESLT) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.ORG_NUM,
                       A.MATUR_DATE,
                       SUM(NVL(A.ACCT_BAL_RMB,0)) AS ACCT_BAL_RMB, --本金
                       SUM(NVL(A.INTEREST_ACCURAL,0)) AS INTEREST_ACCURAL, --其他应收款
                       SUM(NVL(A.QTYSK,0)) AS QTYSK, --其他应收款
                       SUM(NVL(PRIN_FINAL_RESLT,0)) AS PRIN_FINAL_RESLT, --本金的减值
                       SUM(NVL(COLLBL_INT_FINAL_RESLT,0)) AS COLLBL_INT_FINAL_RESLT, --应收利息的减值
                       0 AS QT --其他应收款的减值
                  FROM CBRC_TMP_A_CBRC_LOAN_BAL A
                  LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE_G B
                    ON A.ACCT_NUM = B.ACCT_NUM
                 WHERE A.DATA_DATE = I_DATADATE
                   AND FLAG = '09'
                 GROUP BY A.ORG_NUM, A.MATUR_DATE) A
         GROUP BY ORG_NUM,
                  CASE
                    WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                     'G25_2_2.15.C.2016' ---1年以上
                    WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                     'G25_2_2.15.B.2016' --6个月-1年
                    ELSE
                     'G25_2_2.15.A.2016'
                  END;

--债券正常
 INSERT INTO `__INDICATOR_PLACEHOLDER__`
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          A.ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
            WHEN DC_DATE >= 360 THEN
             'G25_2_2.15.C.2016' ---1年以上
            WHEN DC_DATE >= 180 THEN
             'G25_2_2.15.B.2016' --6个月-1年
            ELSE
             'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(CASE
                WHEN A.ACCT_NUM = '1523004' THEN ACCRUAL - BJ_JZ - YSLX_JZ - YJLX_JZ
                ELSE ACCRUAL - BJ_JZ - YSLX_JZ - YJLX_JZ
               END) AS ITEM_VAL,
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            DC_DATE,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG = '01' --债券
              AND A.DC_DATE > 0
              AND ACCT_NUM <>'X0003120B2700001') A  -- ADD BY DJH 20240510  金融市场部 X0003120B2700001  18华阳经贸CP001  与G21判定规则相同，这笔默认逾期,已放在上面，此处去掉
    GROUP BY A.ORG_NUM,
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;

--同业存单  买入返售的应收（票据+债券)
 INSERT INTO `__INDICATOR_PLACEHOLDER__`
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
             WHEN A.DC_DATE >= 360 THEN
              'G25_2_2.15.C.2016' ---1年以上
             WHEN A.DC_DATE >= 180 THEN
              'G25_2_2.15.B.2016' --6个月-1年
             ELSE
              'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(ACCRUAL - BJ_JZ - YSLX_JZ) AS ITEM_VAL,
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            A.DC_DATE,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG IN ('02', '04', '05')) A --同业存单  买入返售的应收（票据+债券)
    GROUP BY ORG_NUM,
             CASE
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;

--转贴现的公允价值+转贴现的利息调整+转贴现的减值--全行，报在009804，刨除磐石
 INSERT INTO `__INDICATOR_PLACEHOLDER__`
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          A.ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
            WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
             'G25_2_2.15.C.2016' ---1年以上
            WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
             'G25_2_2.15.B.2016' --6个月-1年
            ELSE
             'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(MK_VAL-INT_ADJEST_AMT-BJ_JZ) AS ITEM_VAL, -- 公允价值（有正有负） - 利息调整（贷方）  - 本金减值
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            MATURITY_DT,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG = '03') A --转贴现
    GROUP BY A.ORG_NUM,
             CASE
               WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;

A列资产负债表资产总计期末余额（年末保持与G01利润结转后的资产总计一致）
     16.其他资产.金额（按剩余期限）6-12个月:G1.9其他有确定到期日的资产(理财资管回传表)180≦剩余期限<360
     16.其他资产.金额（按剩余期限）≥1年:G1.9其他有确定到期日的资产(理财资管回传表)剩余期限一年以上*/
   INSERT INTO `__INDICATOR_PLACEHOLDER__`
     (DATA_DATE, --数据日期
      ORG_NUM, --机构号
      SYS_NAM, --模块简称
      REP_NUM, --报表编号
      ITEM_NUM, --指标号
      ITEM_VAL, --指标值
      FLAG, --标志位
      B_CURR_CD)
     SELECT I_DATADATE AS DATA_DATE, --数据日期
            A.ORG_NUM AS ORG_NUM,
            'CBRC' AS SYS_NAM, --模块简称
            'G2502' AS REP_NUM, --报表编号
            CASE
              WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
               'G25_2_2.15.C.2016' ---1年以上
              WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
               'G25_2_2.15.B.2016' --6个月-1年
             /* ELSE
               'G25_2_2.16.A.2016'*/
            END AS ITEM_NUM,
            SUM(RECVAPAY_AMT) AS ITEM_VAL,
            '2' AS FLAG,
            'ALL' AS B_CURR_CD
       FROM (SELECT A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT) RECVAPAY_AMT
               FROM cbrc_tmp_fimm_product_bal A
              WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
                AND FLAG = '1'
             GROUP BY A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE)
             UNION ALL
             SELECT A.ORG_NUM,REDEMP_DATE AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT)
               FROM cbrc_tmp_fimm_product_bal A
              WHERE A.OPER_TYPE LIKE '2%' --运行方式是封闭式
                AND FLAG = '1'
              GROUP BY A.ORG_NUM,REDEMP_DATE) A
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
                  'G25_2_2.15.C.2016' ---1年以上
                 WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
                  'G25_2_2.15.B.2016' --6个月-1年
                /* ELSE
                  'G25_2_2.16.A.2016'*/
               END;

--ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.FLAG = '06' THEN
                'G25_2_2.15.A.2016'
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(INTEREST_ACCURAL) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM,
               A.FLAG
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.FLAG IN ('06', '02', '04') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户)
                 AND A.ORG_NUM = '009820'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM,A.FLAG) A
       GROUP BY CASE
                  WHEN A.FLAG = '06' THEN
                   'G25_2_2.15.A.2016'
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;

--ADD BY DJH 20240510  同业金融部 009804
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 AND
                    ACCT_NUM NOT IN
                    ('N000310000012993', 'N000310000008023', 'N000310000012013') THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 AND
                    ACCT_NUM NOT IN
                    ('N000310000012993', 'N000310000008023', 'N000310000012013') THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(DECODE(A.GL_ITEM_CODE,'15010201',ACCT_BAL_RMB+INTEREST_ACCURAL,A.INTEREST_ACCURAL)) ITEM_VAL,--SUM(A.INTEREST_ACCURAL) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM,
               ACCT_NUM
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.FLAG IN ('07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资 无利息) 08(AC账户  '15010201' )
                 AND a.ORG_NUM = '009820'
               GROUP BY A.GL_ITEM_CODE,
                        A.CUST_ID,
                        MATUR_DATE,
                        A.ORG_NUM,
                        ACCT_NUM) A
       GROUP BY CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 AND
                       ACCT_NUM NOT IN ('N000310000012993',
                                        'N000310000008023',
                                        'N000310000012013') THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 AND
                       ACCT_NUM NOT IN ('N000310000012993',
                                        'N000310000008023',
                                        'N000310000012013') THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;

--特定目的载体11010303 本金+公允价值
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN (A.DC_DATE < 0 OR C.REDEMPTION_TYPE = '随时赎回') THEN
                'G25_2_2.15.A.2016'
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END AS ITEM_NUM,
             SUM(A.FACE_VAL +A.MK_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM V_PUB_FUND_INVEST A
       INNER JOIN L_AGRE_OTHER_SUBJECT_INFO C -- 其他标的物信息表
          ON A.SUBJECT_CD = C.SUBJECT_CD
         AND C.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ORG_NUM = '009820'
         AND A.GL_ITEM_CODE = '11010303'
       GROUP BY CASE
                  WHEN (A.DC_DATE < 0 OR C.REDEMPTION_TYPE = '随时赎回') THEN
                   'G25_2_2.15.A.2016'
                  WHEN A.DC_DATE >= 360 THEN
                   'G25_2_2.15.C.2016' ---1年以上
                  WHEN A.DC_DATE >= 180 THEN
                   'G25_2_2.15.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.15.A.2016'
                END;

--由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第16项不在系统取数，业务手填
    /*  --ADD BY DJH 20240510  投资银行部 009817
      --存量非标的本金+其他应收款+应收利息-存量非标本金的减值-其他应收款的减值-应收利息的减值，按剩余期限划分；逾期的放<6个月
      INSERT INTO `__INDICATOR_PLACEHOLDER__`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               ORG_NUM AS ORG_NUM, --全行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                  'G25_2_2.15.C.2016' ---1年以上
                 WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                  'G25_2_2.15.B.2016' --6个月-1年
                 ELSE
                  'G25_2_2.15.A.2016'
               END AS ITEM_NUM,
               SUM(ACCT_BAL_RMB+INTEREST_ACCURAL+QTYSK-PRIN_FINAL_RESLT-COLLBL_INT_FINAL_RESLT) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.ORG_NUM,
                       A.MATUR_DATE,
                       SUM(NVL(A.ACCT_BAL_RMB,0)) AS ACCT_BAL_RMB, --本金
                       SUM(NVL(A.INTEREST_ACCURAL,0)) AS INTEREST_ACCURAL, --其他应收款
                       SUM(NVL(A.QTYSK,0)) AS QTYSK, --其他应收款
                       SUM(NVL(PRIN_FINAL_RESLT,0)) AS PRIN_FINAL_RESLT, --本金的减值
                       SUM(NVL(COLLBL_INT_FINAL_RESLT,0)) AS COLLBL_INT_FINAL_RESLT, --应收利息的减值
                       0 AS QT --其他应收款的减值
                  FROM CBRC_TMP_A_CBRC_LOAN_BAL A
                  LEFT JOIN CBRC_TMP_ASSET_DEVALUE_PREPARE_G B
                    ON A.ACCT_NUM = B.ACCT_NUM
                 WHERE A.DATA_DATE = I_DATADATE
                   AND FLAG = '09'
                 GROUP BY A.ORG_NUM, A.MATUR_DATE) A
         GROUP BY ORG_NUM,
                  CASE
                    WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                     'G25_2_2.15.C.2016' ---1年以上
                    WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                     'G25_2_2.15.B.2016' --6个月-1年
                    ELSE
                     'G25_2_2.15.A.2016'
                  END;

--债券正常
 INSERT INTO `__INDICATOR_PLACEHOLDER__`
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          A.ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
            WHEN DC_DATE >= 360 THEN
             'G25_2_2.15.C.2016' ---1年以上
            WHEN DC_DATE >= 180 THEN
             'G25_2_2.15.B.2016' --6个月-1年
            ELSE
             'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(CASE
                WHEN A.ACCT_NUM = '1523004' THEN ACCRUAL - BJ_JZ - YSLX_JZ - YJLX_JZ
                ELSE ACCRUAL - BJ_JZ - YSLX_JZ - YJLX_JZ
               END) AS ITEM_VAL,
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            DC_DATE,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG = '01' --债券
              AND A.DC_DATE > 0
              AND ACCT_NUM <>'X0003120B2700001') A  -- ADD BY DJH 20240510  金融市场部 X0003120B2700001  18华阳经贸CP001  与G21判定规则相同，这笔默认逾期,已放在上面，此处去掉
    GROUP BY A.ORG_NUM,
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;

--同业存单  买入返售的应收（票据+债券)
 INSERT INTO `__INDICATOR_PLACEHOLDER__`
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
             WHEN A.DC_DATE >= 360 THEN
              'G25_2_2.15.C.2016' ---1年以上
             WHEN A.DC_DATE >= 180 THEN
              'G25_2_2.15.B.2016' --6个月-1年
             ELSE
              'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(ACCRUAL - BJ_JZ - YSLX_JZ) AS ITEM_VAL,
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            A.DC_DATE,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG IN ('02', '04', '05')) A --同业存单  买入返售的应收（票据+债券)
    GROUP BY ORG_NUM,
             CASE
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;

--转贴现的公允价值+转贴现的利息调整+转贴现的减值--全行，报在009804，刨除磐石
 INSERT INTO `__INDICATOR_PLACEHOLDER__`
   (DATA_DATE, --数据日期
    ORG_NUM, --机构号
    SYS_NAM, --模块简称
    REP_NUM, --报表编号
    ITEM_NUM, --指标号
    ITEM_VAL, --指标值
    FLAG, --标志位
    B_CURR_CD)
   SELECT I_DATADATE AS DATA_DATE, --数据日期
          A.ORG_NUM AS ORG_NUM,
          'CBRC' AS SYS_NAM, --模块简称
          'G2502' AS REP_NUM, --报表编号
          CASE
            WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
             'G25_2_2.15.C.2016' ---1年以上
            WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
             'G25_2_2.15.B.2016' --6个月-1年
            ELSE
             'G25_2_2.15.A.2016'
          END AS ITEM_NUM,
          SUM(MK_VAL-INT_ADJEST_AMT-BJ_JZ) AS ITEM_VAL, -- 公允价值（有正有负） - 利息调整（贷方）  - 本金减值
          '2' AS FLAG,
          'ALL' AS B_CURR_CD
     FROM (SELECT 
            A.GL_ITEM_CODE,
            MATURITY_DT,
            A.ORG_NUM,
            ACCT_NUM,
            NVL(BALANCE, 0) BALANCE,
            NVL(MK_VAL, 0) MK_VAL,
            NVL(INT_ADJEST_AMT, 0) INT_ADJEST_AMT,
            NVL(ACCRUAL, 0) ACCRUAL,
            NVL(DISCOUNT_INTEREST, 0) DISCOUNT_INTEREST,
            NVL(BJ_JZ, 0) BJ_JZ,
            NVL(YSLX_JZ, 0) YSLX_JZ,
            NVL(YJLX_JZ, 0) YJLX_JZ,
            NVL(BW_JZ, 0) BW_JZ
             FROM CBRC_TMP_FINANCIAL_MARKET A
            WHERE A.DATA_DATE = I_DATADATE
              AND A.FLAG = '03') A --转贴现
    GROUP BY A.ORG_NUM,
             CASE
               WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
                'G25_2_2.15.C.2016' ---1年以上
               WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
                'G25_2_2.15.B.2016' --6个月-1年
               ELSE
                'G25_2_2.15.A.2016'
             END;

A列资产负债表资产总计期末余额（年末保持与G01利润结转后的资产总计一致）
     16.其他资产.金额（按剩余期限）6-12个月:G1.9其他有确定到期日的资产(理财资管回传表)180≦剩余期限<360
     16.其他资产.金额（按剩余期限）≥1年:G1.9其他有确定到期日的资产(理财资管回传表)剩余期限一年以上*/
   INSERT INTO `__INDICATOR_PLACEHOLDER__`
     (DATA_DATE, --数据日期
      ORG_NUM, --机构号
      SYS_NAM, --模块简称
      REP_NUM, --报表编号
      ITEM_NUM, --指标号
      ITEM_VAL, --指标值
      FLAG, --标志位
      B_CURR_CD)
     SELECT I_DATADATE AS DATA_DATE, --数据日期
            A.ORG_NUM AS ORG_NUM,
            'CBRC' AS SYS_NAM, --模块简称
            'G2502' AS REP_NUM, --报表编号
            CASE
              WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
               'G25_2_2.15.C.2016' ---1年以上
              WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
               'G25_2_2.15.B.2016' --6个月-1年
             /* ELSE
               'G25_2_2.16.A.2016'*/
            END AS ITEM_NUM,
            SUM(RECVAPAY_AMT) AS ITEM_VAL,
            '2' AS FLAG,
            'ALL' AS B_CURR_CD
       FROM (SELECT A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT) RECVAPAY_AMT
               FROM cbrc_tmp_fimm_product_bal A
              WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
                AND FLAG = '1'
             GROUP BY A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE)
             UNION ALL
             SELECT A.ORG_NUM,REDEMP_DATE AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT)
               FROM cbrc_tmp_fimm_product_bal A
              WHERE A.OPER_TYPE LIKE '2%' --运行方式是封闭式
                AND FLAG = '1'
              GROUP BY A.ORG_NUM,REDEMP_DATE) A
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
                  'G25_2_2.15.C.2016' ---1年以上
                 WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
                  'G25_2_2.15.B.2016' --6个月-1年
                /* ELSE
                  'G25_2_2.16.A.2016'*/
               END
) q_15
INSERT INTO `G25_2_2.15.B.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_2.15.B.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- 指标: G25_2_2.16.4.A.2016
--17.4非契约性义务
    INSERT INTO `G25_2_2.16.4.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.16.4.A.2016' AS ITEM_NUM, --指标号
             SUM(T.INV_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM L_FIMM_FIN_PENE T
        LEFT JOIN L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.DATA_TYP LIKE 'A%' --资产负债类型为资产
         AND T.INV_FLAY = '否' --穿透前
       GROUP BY T.ORG_NUM;

--17.4非契约性义务
    INSERT INTO `G25_2_2.16.4.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.16.4.A.2016' AS ITEM_NUM, --指标号
             SUM(T.INV_AMT * U.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM L_FIMM_FIN_PENE T
        LEFT JOIN L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.DATA_TYP LIKE 'A%' --资产负债类型为资产
         AND T.INV_FLAY = '否' --穿透前
       GROUP BY T.ORG_NUM;


-- 指标: G25_2_2.6.2.A.2016
--6.2其他
    /*全行的存放同业活期持有仓位按剩余期限划分+全行的存放同业保证金的人民币按剩余期限划分填报在009820，都放到6个月内,因为存放同业活期和存放同业保证金无到期日
     取人民币部分，不要外币*/
       --ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO `G25_2_2.6.2.A.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009820' AS ORG_NUM, --全行报在009820机构
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              'G25_2_2.6.2.A.2016'AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                SUM(ACCT_BAL_RMB) ITEM_VAL,
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_LOAN_BAL A
                WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
                  AND ACCT_BAL_RMB <> 0
                  AND SUBSTR(A.GL_ITEM_CODE, 1, 6) <> '101102' --存放同业定期不要
                  AND A.ACCT_CUR = 'CNY' --取人民币部分，不要外币
                  AND A.ORG_NUM NOT LIKE '5%'
                  AND A.ORG_NUM NOT LIKE '6%'
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心取,业务状况表（机构990000，外币折人民币），101101存放同业活期款项借方余额；103101存出活期保证金借方余额。
     INSERT INTO `G25_2_2.6.2.A.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009801' AS ORG_NUM, --全行报在009820机构
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              'G25_2_2.6.2.A.2016' AS ITEM_NUM,
              SUM(DEBIT_BAL) ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM L_FINA_GL A
        WHERE DATA_DATE = I_DATADATE
          AND CURR_CD = 'CFC' --外币折人民币
          AND ITEM_CD IN('101101','103101')
          AND A.ORG_NUM = '990000'
        GROUP BY A.ITEM_CD, A.ORG_NUM;

--6.2其他
    /*全行的存放同业活期持有仓位按剩余期限划分+全行的存放同业保证金的人民币按剩余期限划分填报在009820，都放到6个月内,因为存放同业活期和存放同业保证金无到期日
     取人民币部分，不要外币*/
       --ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO `G25_2_2.6.2.A.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009820' AS ORG_NUM, --全行报在009820机构
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              'G25_2_2.6.2.A.2016'AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                SUM(ACCT_BAL_RMB) ITEM_VAL,
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_LOAN_BAL A
                WHERE A.FLAG = '01' --1011(存放同业)、 1031(存出保证金)
                  AND ACCT_BAL_RMB <> 0
                  AND SUBSTR(A.GL_ITEM_CODE, 1, 6) <> '101102' --存放同业定期不要
                  AND A.ACCT_CUR = 'CNY' --取人民币部分，不要外币
                  AND A.ORG_NUM NOT LIKE '5%'
                  AND A.ORG_NUM NOT LIKE '6%'
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心取,业务状况表（机构990000，外币折人民币），101101存放同业活期款项借方余额；103101存出活期保证金借方余额。
     INSERT INTO `G25_2_2.6.2.A.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009801' AS ORG_NUM, --全行报在009820机构
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              'G25_2_2.6.2.A.2016' AS ITEM_NUM,
              SUM(DEBIT_BAL) ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM L_FINA_GL A
        WHERE DATA_DATE = I_DATADATE
          AND CURR_CD = 'CFC' --外币折人民币
          AND ITEM_CD IN('101101','103101')
          AND A.ORG_NUM = '990000'
        GROUP BY A.ITEM_CD, A.ORG_NUM;


-- 指标: G25_2_1.6.1.B.2016
--ADD BY DJH 20240510  同业金融部 009820
      INSERT INTO `G25_2_1.6.1.B.2016`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               '009820' AS ORG_NUM, --分行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                  'G25_2_1.6.1.C.2016' ---1年以上
                 WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                  'G25_2_1.6.1.B.2016' --6个月-1年
                 ELSE
                  'G25_2_1.6.1.A.2016'
               END AS ITEM_NUM,
               SUM(ITEM_VAL) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.GL_ITEM_CODE,
                       A.CUST_ID,
                       A.JYDSTYDM,
                       SUM(A.BALANCE * CCY_RATE) ITEM_VAL,
                       MATURE_DATE
                  FROM V_PUB_FUND_MMFUND A
                  LEFT JOIN L_PUBL_RATE TT
                    ON TT.CCY_DATE = I_DATADATE
                   AND TT.BASIC_CCY = A.CURR_CD
                   AND TT.FORWARD_CCY = 'CNY'
                 WHERE A.DATA_DATE = I_DATADATE
                   AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放的定期
                   AND A.BALANCE <> 0
                   AND A.ORG_NUM NOT LIKE '5%'
                   AND A.ORG_NUM NOT LIKE '6%'
                 GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A
         GROUP BY CASE
                    WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                     'G25_2_1.6.1.C.2016' ---1年以上
                    WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                     'G25_2_1.6.1.B.2016' --6个月-1年
                    ELSE
                     'G25_2_1.6.1.A.2016'
                  END;

--ADD BY DJH 20240510  同业金融部 009820
      INSERT INTO `G25_2_1.6.1.B.2016`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               '009820' AS ORG_NUM, --分行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                  'G25_2_1.6.1.C.2016' ---1年以上
                 WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                  'G25_2_1.6.1.B.2016' --6个月-1年
                 ELSE
                  'G25_2_1.6.1.A.2016'
               END AS ITEM_NUM,
               SUM(ITEM_VAL) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.GL_ITEM_CODE,
                       A.CUST_ID,
                       A.JYDSTYDM,
                       SUM(A.BALANCE * CCY_RATE) ITEM_VAL,
                       MATURE_DATE
                  FROM V_PUB_FUND_MMFUND A
                  LEFT JOIN L_PUBL_RATE TT
                    ON TT.CCY_DATE = I_DATADATE
                   AND TT.BASIC_CCY = A.CURR_CD
                   AND TT.FORWARD_CCY = 'CNY'
                 WHERE A.DATA_DATE = I_DATADATE
                   AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放的定期
                   AND A.BALANCE <> 0
                   AND A.ORG_NUM NOT LIKE '5%'
                   AND A.ORG_NUM NOT LIKE '6%'
                 GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A
         GROUP BY CASE
                    WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                     'G25_2_1.6.1.C.2016' ---1年以上
                    WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                     'G25_2_1.6.1.B.2016' --6个月-1年
                    ELSE
                     'G25_2_1.6.1.A.2016'
                  END;


-- 指标: G25_2_1.10.A.2016
INSERT INTO `G25_2_1.10.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009804',
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             ITEM_CD,
             SUM(ACCRUAL),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.10.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.10.B.2016'
                       ELSE
                        'G25_2_1.10.A.2016'
                     END AS ITEM_CD,
                     SUM(A.INTEREST_ACCURAL) AS ACCRUAL
                FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE FLAG = '07' --卖出回购
                 AND A.DATA_DATE = I_DATADATE
                 AND A.MATUR_DATE > I_DATADATE
               GROUP BY CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.10.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.10.B.2016'
                          ELSE
                           'G25_2_1.10.A.2016'
                        END
              UNION ALL
              SELECT 'G25_2_1.10.A.2016' AS ITEM_CD, -SUM(T.DEBIT_BAL)
                FROM L_FINA_GL T
               WHERE DATA_DATE = I_DATADATE
                 AND ITEM_CD = '20040202'
                 AND ORG_NUM = '990000'
                 AND T.CURR_CD = 'CNY' --再贴现的利息调整取全行，放进剩余期限<6个月
              UNION ALL  --ADD BY DJH 20240510  金融市场部 009804 补充拆入 2003同业拆入利息
              SELECT CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.10.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.10.B.2016'
                       ELSE
                        'G25_2_1.10.A.2016'
                     END AS ITEM_CD,
                     SUM(A.INTEREST_ACCURAL) AS ACCRUAL
                FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE A.FLAG = '05' --同业拆入(有其他机构)
                  AND INTEREST_ACCURAL <> 0
                  AND A.ORG_NUM = '009804'
               GROUP BY CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.10.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.10.B.2016'
                          ELSE
                           'G25_2_1.10.A.2016'
                        END)
       GROUP BY ITEM_CD;

--10.以上未包括的所有其它负债和权益
    /*1.分行：资产类型为同业存放的定期中的利息按剩余期限划分报在009820机构；
    2.009820：同业拆入应付利息按期限-存单发行的应付利息调整按期限+3001（清算间往来）贷方放在6个月内；其中同业存单发行的应付利息调整按负数填报；
    009817机构从G01的60.负债及所有者权益总计同步取值，放>1年中；
    009816机构从G01资产负债项目统计表 49.负债合计同步取值；*/
    /*
    特殊： 同业存单发行的应付利息调整按负数填报   实际上不是报送在2231科目，而是在250202科目借方（利息调整），本金在贷方
     SELECT T.ORG_NUM, ITEM_CD, DEBIT_BAL, T.CREDIT_BAL
       FROM L_FINA_GL T
      WHERE DATA_DATE = I_DATADATE
        AND CURR_CD = 'BWB'
        AND ITEM_CD IN ('250202')*/

     --ADD BY DJH 20240510  同业金融部 009820
      INSERT INTO `G25_2_1.10.A.2016`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               '009820' AS ORG_NUM, --分行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                  'G25_2_1.10.C.2016' ---1年以上
                 WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                  'G25_2_1.10.B.2016' --6个月-1年
                 ELSE
                  'G25_2_1.10.A.2016'
               END AS ITEM_NUM,
               SUM(ITEM_VAL) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.GL_ITEM_CODE,
                       A.CUST_ID,
                       A.JYDSTYDM,
                       SUM(A.ACCRUAL * CCY_RATE) ITEM_VAL,
                       MATURE_DATE
                  FROM V_PUB_FUND_MMFUND A
                  LEFT JOIN L_PUBL_RATE TT
                    ON TT.CCY_DATE = I_DATADATE
                   AND TT.BASIC_CCY = A.CURR_CD
                   AND TT.FORWARD_CCY = 'CNY'
                 WHERE A.DATA_DATE = I_DATADATE
                   AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放定期
                   AND A.ACCRUAL <> 0
                   AND A.ORG_NUM NOT LIKE '5%'
                   AND A.ORG_NUM NOT LIKE '6%'
                 GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A
         GROUP BY CASE
                    WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                     'G25_2_1.10.C.2016' ---1年以上
                    WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                     'G25_2_1.10.B.2016' --6个月-1年
                    ELSE
                     'G25_2_1.10.A.2016'
                  END;

--ADD BY DJH 20240510  同业金融部 009820
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，2003拆入资金交易产生的应付利息 与核对223111科目贷方余额应付利息核对
     INSERT INTO `G25_2_1.10.A.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.10.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.10.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.10.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                SUM(INTEREST_ACCURAL) ITEM_VAL,
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG IN ('05', '10') --同业拆入 转贷款 应付利息
                  AND INTEREST_ACCURAL <> 0
                  AND A.ORG_NUM IN ('009820', '009801')
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.10.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.10.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.10.A.2016'
                 END,
                 ORG_NUM;

--ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO `G25_2_1.10.A.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009820' AS ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.10.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.10.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.10.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                -1 * SUM(CYCB) ITEM_VAL, --利息调整  CYCB资产方的叫持有成本，负债方的利息调整   台账表中【利息收益（即利息调整）】
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG = '06' --同业存单发行
                  AND CYCB <> 0
                  AND A.ORG_NUM = '009820'
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.10.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.10.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.10.A.2016'
                 END;

--ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO `G25_2_1.10.A.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009820' AS ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              'G25_2_1.10.A.2016' AS ITEM_NUM, --3001（清算间往来）贷方放在6个月内
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.ITEM_CD, SUM(CREDIT_BAL) ITEM_VAL, A.ORG_NUM
                 FROM L_FINA_GL A
                WHERE DATA_DATE = I_DATADATE
                  AND CURR_CD = 'BWB'
                  AND ITEM_CD = '3001'
                  AND A.ORG_NUM = '009820'
                GROUP BY A.ITEM_CD, A.ORG_NUM) A;

INSERT INTO `G25_2_1.10.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009804',
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             ITEM_CD,
             SUM(ACCRUAL),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.10.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.10.B.2016'
                       ELSE
                        'G25_2_1.10.A.2016'
                     END AS ITEM_CD,
                     SUM(A.INTEREST_ACCURAL) AS ACCRUAL
                FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE FLAG = '07' --卖出回购
                 AND A.DATA_DATE = I_DATADATE
                 AND A.MATUR_DATE > I_DATADATE
               GROUP BY CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.10.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.10.B.2016'
                          ELSE
                           'G25_2_1.10.A.2016'
                        END
              UNION ALL
              SELECT 'G25_2_1.10.A.2016' AS ITEM_CD, -SUM(T.DEBIT_BAL)
                FROM L_FINA_GL T
               WHERE DATA_DATE = I_DATADATE
                 AND ITEM_CD = '20040202'
                 AND ORG_NUM = '990000'
                 AND T.CURR_CD = 'CNY' --再贴现的利息调整取全行，放进剩余期限<6个月
              UNION ALL  --ADD BY DJH 20240510  金融市场部 009804 补充拆入 2003同业拆入利息
              SELECT CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.10.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.10.B.2016'
                       ELSE
                        'G25_2_1.10.A.2016'
                     END AS ITEM_CD,
                     SUM(A.INTEREST_ACCURAL) AS ACCRUAL
                FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE A.FLAG = '05' --同业拆入(有其他机构)
                  AND INTEREST_ACCURAL <> 0
                  AND A.ORG_NUM = '009804'
               GROUP BY CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.10.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.10.B.2016'
                          ELSE
                           'G25_2_1.10.A.2016'
                        END)
       GROUP BY ITEM_CD;

--10.以上未包括的所有其它负债和权益
    /*1.分行：资产类型为同业存放的定期中的利息按剩余期限划分报在009820机构；
    2.009820：同业拆入应付利息按期限-存单发行的应付利息调整按期限+3001（清算间往来）贷方放在6个月内；其中同业存单发行的应付利息调整按负数填报；
    009817机构从G01的60.负债及所有者权益总计同步取值，放>1年中；
    009816机构从G01资产负债项目统计表 49.负债合计同步取值；*/
    /*
    特殊： 同业存单发行的应付利息调整按负数填报   实际上不是报送在2231科目，而是在250202科目借方（利息调整），本金在贷方
     SELECT T.ORG_NUM, ITEM_CD, DEBIT_BAL, T.CREDIT_BAL
       FROM L_FINA_GL T
      WHERE DATA_DATE = I_DATADATE
        AND CURR_CD = 'BWB'
        AND ITEM_CD IN ('250202')*/

     --ADD BY DJH 20240510  同业金融部 009820
      INSERT INTO `G25_2_1.10.A.2016`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               '009820' AS ORG_NUM, --分行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                  'G25_2_1.10.C.2016' ---1年以上
                 WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                  'G25_2_1.10.B.2016' --6个月-1年
                 ELSE
                  'G25_2_1.10.A.2016'
               END AS ITEM_NUM,
               SUM(ITEM_VAL) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.GL_ITEM_CODE,
                       A.CUST_ID,
                       A.JYDSTYDM,
                       SUM(A.ACCRUAL * CCY_RATE) ITEM_VAL,
                       MATURE_DATE
                  FROM V_PUB_FUND_MMFUND A
                  LEFT JOIN L_PUBL_RATE TT
                    ON TT.CCY_DATE = I_DATADATE
                   AND TT.BASIC_CCY = A.CURR_CD
                   AND TT.FORWARD_CCY = 'CNY'
                 WHERE A.DATA_DATE = I_DATADATE
                   AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放定期
                   AND A.ACCRUAL <> 0
                   AND A.ORG_NUM NOT LIKE '5%'
                   AND A.ORG_NUM NOT LIKE '6%'
                 GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A
         GROUP BY CASE
                    WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                     'G25_2_1.10.C.2016' ---1年以上
                    WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                     'G25_2_1.10.B.2016' --6个月-1年
                    ELSE
                     'G25_2_1.10.A.2016'
                  END;

--ADD BY DJH 20240510  同业金融部 009820
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，2003拆入资金交易产生的应付利息 与核对223111科目贷方余额应付利息核对
     INSERT INTO `G25_2_1.10.A.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.10.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.10.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.10.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                SUM(INTEREST_ACCURAL) ITEM_VAL,
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG IN ('05', '10') --同业拆入 转贷款 应付利息
                  AND INTEREST_ACCURAL <> 0
                  AND A.ORG_NUM IN ('009820', '009801')
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.10.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.10.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.10.A.2016'
                 END,
                 ORG_NUM;

--ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO `G25_2_1.10.A.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009820' AS ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.10.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.10.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.10.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                -1 * SUM(CYCB) ITEM_VAL, --利息调整  CYCB资产方的叫持有成本，负债方的利息调整   台账表中【利息收益（即利息调整）】
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG = '06' --同业存单发行
                  AND CYCB <> 0
                  AND A.ORG_NUM = '009820'
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.10.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.10.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.10.A.2016'
                 END;

--ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO `G25_2_1.10.A.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009820' AS ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              'G25_2_1.10.A.2016' AS ITEM_NUM, --3001（清算间往来）贷方放在6个月内
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.ITEM_CD, SUM(CREDIT_BAL) ITEM_VAL, A.ORG_NUM
                 FROM L_FINA_GL A
                WHERE DATA_DATE = I_DATADATE
                  AND CURR_CD = 'BWB'
                  AND ITEM_CD = '3001'
                  AND A.ORG_NUM = '009820'
                GROUP BY A.ITEM_CD, A.ORG_NUM) A;


-- 指标: G25_2_2.16.3.A.2016
--17.3 担保、信用证及其他贸易融资工具 1开出信用证敞口 2保函敞口放在6月内
    INSERT INTO `G25_2_2.16.3.A.2016`
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
      INTO `G25_2_2.16.3.A.2016` 
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
    INSERT INTO `G25_2_2.16.3.A.2016`
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


-- 指标: G25_2_2.16.1.A.2016
--17.表外项目
    --17.1信用和流动性便利（可无条件撤销） 60301可撤销贷款承诺、商票放在6月内
    INSERT INTO `G25_2_2.16.1.A.2016`
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
      INTO `G25_2_2.16.1.A.2016` 
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
    INSERT INTO `G25_2_2.16.1.A.2016`
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


-- 指标: G25_2_1.4.2.A.2016
--4.2非业务关系存款及其他无担保借款.金额（按剩余期限）.<6个月
    --4.2非业务关系存款及其他无担保借款.金额（按剩余期限）.6-12个月
    --4.2非业务关系存款及其他无担保借款.金额（按剩余期限）.≥1年
    INSERT INTO `G25_2_1.4.2.A.2016`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.4.2.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.4.2.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.4.2.C.2016' --≥1年
             END AS ITEM_NUM,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '003' --无业务关系
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;

INSERT INTO `G25_2_1.4.2.A.2016`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_1.4.2.A.2016' AS ITEM_NUM, --add by djh20220622 注意与G2501规则相同，所有除不可提前支取的外，其他存款视为活期，要放在6个月内
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '004' --无业务关系,且不是稳定存款那些类型的
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;

--4.2非业务关系存款及其他无担保借款.金额（按剩余期限）.<6个月
    --4.2非业务关系存款及其他无担保借款.金额（按剩余期限）.6-12个月
    --4.2非业务关系存款及其他无担保借款.金额（按剩余期限）.≥1年
    INSERT INTO `G25_2_1.4.2.A.2016`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.4.2.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.4.2.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.4.2.C.2016' --≥1年
             END AS ITEM_NUM,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '003' --无业务关系
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;

INSERT INTO `G25_2_1.4.2.A.2016`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_1.4.2.A.2016' AS ITEM_NUM, --add by djh20220622 注意与G2501规则相同，所有除不可提前支取的外，其他存款视为活期，要放在6个月内
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '004' --无业务关系,且不是稳定存款那些类型的
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;


-- 指标: G25_2_1.6.2.B.2016
--ADD BY DJH 20240510  同业金融部 009820
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，2003同业拆入外币折人民币本金余额  加本条线同业代付 差异在于 G2501取分行同业代付30天内，G2502取所有
     INSERT INTO `G25_2_1.6.2.B.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              A.ORG_NUM AS ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.6.2.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.6.2.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.6.2.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                SUM(ACCT_BAL_RMB) ITEM_VAL,
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG IN ('05', '06','10') --同业拆入(有其他机构)  同业存单发行
                  AND ACCT_BAL_RMB <> 0
                  AND A.ORG_NUM IN ('009820','009801')  
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY A.ORG_NUM,
                 CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.6.2.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.6.2.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.6.2.A.2016'
                 END;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心本条线同业代付 差异在于 G2501取分行同业代付30天内，G2502取所有
    INSERT INTO `G25_2_1.6.2.B.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009801' AS ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_1.6.2.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_1.6.2.B.2016' --6个月-1年
               ELSE
                'G25_2_1.6.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.DATA_DATE,
                     ACTUAL_MATURITY_DT AS MATUR_DATE,
                     A.LOAN_ACCT_BAL * U.CCY_RATE AS ITEM_VAL
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
                 AND LOAN_ACCT_BAL <> 0) A
       GROUP BY CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_1.6.2.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_1.6.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_1.6.2.A.2016'
                END;

--ADD BY DJH 20240510  同业金融部 009820
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，2003同业拆入外币折人民币本金余额  加本条线同业代付 差异在于 G2501取分行同业代付30天内，G2502取所有
     INSERT INTO `G25_2_1.6.2.B.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              A.ORG_NUM AS ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.6.2.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.6.2.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.6.2.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                SUM(ACCT_BAL_RMB) ITEM_VAL,
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG IN ('05', '06','10') --同业拆入(有其他机构)  同业存单发行
                  AND ACCT_BAL_RMB <> 0
                  AND A.ORG_NUM IN ('009820','009801')
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY A.ORG_NUM,
                 CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.6.2.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.6.2.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.6.2.A.2016'
                 END;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心本条线同业代付 差异在于 G2501取分行同业代付30天内，G2502取所有
    INSERT INTO `G25_2_1.6.2.B.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009801' AS ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_1.6.2.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_1.6.2.B.2016' --6个月-1年
               ELSE
                'G25_2_1.6.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.DATA_DATE,
                     ACTUAL_MATURITY_DT AS MATUR_DATE,
                     A.LOAN_ACCT_BAL * U.CCY_RATE AS ITEM_VAL
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
                 AND LOAN_ACCT_BAL <> 0) A
       GROUP BY CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_1.6.2.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_1.6.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_1.6.2.A.2016'
                END;


-- 指标: G25_2_1.6.2.A.2016
--6.2非业务关系存款及其他无担保借款
   /*1.分行：其他非结算的科目20120103贷+20120104贷+20120105贷+20120109贷+20120110贷-东北证券股份有限公司-永诚保险资产管理有限公司% 放到6个月中报在009820机构
     2.009820：同业拆入持有仓位+同业存单发行持有仓位按照剩余期限取值*/
   --ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO `G25_2_1.6.2.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM,  --分行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_1.6.2.A.2016' AS ITEM_NUM, --6个月内
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.GL_ITEM_CODE,
                     A.CUST_ID,
                     A.JYDSTYDM,
                     SUM(A.BALANCE * CCY_RATE) ITEM_VAL,
                     MATURE_DATE
                FROM V_PUB_FUND_MMFUND A
                LEFT JOIN L_PUBL_RATE TT
                  ON TT.CCY_DATE = I_DATADATE
                 AND TT.BASIC_CCY = A.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.GL_ITEM_CODE IN('20120103','20120104','20120105','20120109','20120110')
                 AND A.CUST_ID NOT IN ('8913402328', '8916869348') --去掉8913402328东北证券股份有限公司 8916869348永诚保险资产管理有限公司
                 AND A.BALANCE <> 0
                 AND A.ORG_NUM NOT LIKE '5%'
                 AND A.ORG_NUM NOT LIKE '6%'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A;

--ADD BY DJH 20240510  同业金融部 009820
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，2003同业拆入外币折人民币本金余额  加本条线同业代付 差异在于 G2501取分行同业代付30天内，G2502取所有
     INSERT INTO `G25_2_1.6.2.A.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              A.ORG_NUM AS ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.6.2.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.6.2.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.6.2.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                SUM(ACCT_BAL_RMB) ITEM_VAL,
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG IN ('05', '06','10') --同业拆入(有其他机构)  同业存单发行
                  AND ACCT_BAL_RMB <> 0
                  AND A.ORG_NUM IN ('009820','009801')  
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY A.ORG_NUM,
                 CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.6.2.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.6.2.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.6.2.A.2016'
                 END;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心本条线同业代付 差异在于 G2501取分行同业代付30天内，G2502取所有
    INSERT INTO `G25_2_1.6.2.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009801' AS ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_1.6.2.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_1.6.2.B.2016' --6个月-1年
               ELSE
                'G25_2_1.6.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.DATA_DATE,
                     ACTUAL_MATURITY_DT AS MATUR_DATE,
                     A.LOAN_ACCT_BAL * U.CCY_RATE AS ITEM_VAL
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
                 AND LOAN_ACCT_BAL <> 0) A
       GROUP BY CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_1.6.2.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_1.6.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_1.6.2.A.2016'
                END;

--6.2非业务关系存款及其他无担保借款
   /*1.分行：其他非结算的科目20120103贷+20120104贷+20120105贷+20120109贷+20120110贷-东北证券股份有限公司-永诚保险资产管理有限公司% 放到6个月中报在009820机构
     2.009820：同业拆入持有仓位+同业存单发行持有仓位按照剩余期限取值*/
   --ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO `G25_2_1.6.2.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009820' AS ORG_NUM,  --分行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_1.6.2.A.2016' AS ITEM_NUM, --6个月内
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.GL_ITEM_CODE,
                     A.CUST_ID,
                     A.JYDSTYDM,
                     SUM(A.BALANCE * CCY_RATE) ITEM_VAL,
                     MATURE_DATE
                FROM V_PUB_FUND_MMFUND A
                LEFT JOIN L_PUBL_RATE TT
                  ON TT.CCY_DATE = I_DATADATE
                 AND TT.BASIC_CCY = A.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.GL_ITEM_CODE IN('20120103','20120104','20120105','20120109','20120110')
                 AND A.CUST_ID NOT IN ('8913402328', '8916869348') --去掉8913402328东北证券股份有限公司 8916869348永诚保险资产管理有限公司
                 AND A.BALANCE <> 0
                 AND A.ORG_NUM NOT LIKE '5%'
                 AND A.ORG_NUM NOT LIKE '6%'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A;

--ADD BY DJH 20240510  同业金融部 009820
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，2003同业拆入外币折人民币本金余额  加本条线同业代付 差异在于 G2501取分行同业代付30天内，G2502取所有
     INSERT INTO `G25_2_1.6.2.A.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              A.ORG_NUM AS ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.6.2.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.6.2.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.6.2.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                SUM(ACCT_BAL_RMB) ITEM_VAL,
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG IN ('05', '06','10') --同业拆入(有其他机构)  同业存单发行
                  AND ACCT_BAL_RMB <> 0
                  AND A.ORG_NUM IN ('009820','009801')
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY A.ORG_NUM,
                 CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.6.2.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.6.2.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.6.2.A.2016'
                 END;

-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心本条线同业代付 差异在于 G2501取分行同业代付30天内，G2502取所有
    INSERT INTO `G25_2_1.6.2.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009801' AS ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_1.6.2.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_1.6.2.B.2016' --6个月-1年
               ELSE
                'G25_2_1.6.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.DATA_DATE,
                     ACTUAL_MATURITY_DT AS MATUR_DATE,
                     A.LOAN_ACCT_BAL * U.CCY_RATE AS ITEM_VAL
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
                 AND LOAN_ACCT_BAL <> 0) A
       GROUP BY CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_1.6.2.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_1.6.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_1.6.2.A.2016'
                END;


-- ========== 逻辑组 25: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.8.3.2.C.2016'
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.8.3.2.B.2016'
               ELSE
                'G25_2_2.8.3.2.A.2016'
             END,
             SUM(A.PRINCIPAL_BALANCE_CNY *
                 (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) / A.ACCT_BAL_CNY),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_tmp_a_cbrc_bond_bal A
       WHERE A.DATA_DATE = I_DATADATE
         AND ((A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') OR --地方政府债
             (A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
             A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券，短期融资券，公司债，企业债，中期票据 且信用评级是AA的债券
             OR
             A.STOCK_CD IN ('032000573', '032001060', 'X0003118A1600001')) --20四平城投PPN001  20四平城投PPN002 RPA取数没有债券评级，此处特殊处理
         AND A.INVEST_TYP = '00'
         AND A.DC_DATE > 0 --不取逾期
         AND A.STOCK_NAM <> '18华阳经贸CP001' --特殊处理，算逾期
         AND ACCT_BAL_CNY <> 0   --JLBA202411080004
       GROUP BY ORG_NUM,
                CASE
                  WHEN DC_DATE >= 360 THEN
                   'G25_2_2.8.3.2.C.2016'
                  WHEN DC_DATE >= 180 THEN
                   'G25_2_2.8.3.2.B.2016'
                  ELSE
                   'G25_2_2.8.3.2.A.2016'
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
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.8.3.2.C.2016'
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.8.3.2.B.2016'
               ELSE
                'G25_2_2.8.3.2.A.2016'
             END,
             SUM(A.PRINCIPAL_BALANCE_CNY *
                 (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) / A.ACCT_BAL_CNY),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_A_CBRC_BOND_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND ((A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') OR --地方政府债
             (A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
             A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券，短期融资券，公司债，企业债，中期票据 且信用评级是AA的债券
             OR
             A.STOCK_CD IN ('032000573', '032001060', 'X0003118A1600001')) --20四平城投PPN001  20四平城投PPN002 RPA取数没有债券评级，此处特殊处理
         AND A.INVEST_TYP = '00'
         AND A.DC_DATE > 0 --不取逾期
         AND A.STOCK_NAM <> '18华阳经贸CP001' --特殊处理，算逾期
         AND ACCT_BAL_CNY <> 0   --JLBA202411080004
       GROUP BY ORG_NUM,
                CASE
                  WHEN DC_DATE >= 360 THEN
                   'G25_2_2.8.3.2.C.2016'
                  WHEN DC_DATE >= 180 THEN
                   'G25_2_2.8.3.2.B.2016'
                  ELSE
                   'G25_2_2.8.3.2.A.2016'
                END
) q_25
INSERT INTO `G25_2_2.8.3.2.B.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_2.8.3.2.A.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_2.8.3.2.C.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- 指标: G25_2_1.4.1.A.2016
--4.1业务关系存款.金额（按剩余期限）.<6个月
    --4.1业务关系存款.金额（按剩余期限）.6-12个月
    --4.1业务关系存款.金额（按剩余期限）.≥1年
    INSERT INTO `G25_2_1.4.1.A.2016`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.4.1.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.4.1.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.4.1.C.2016' --≥1年
             END AS ITEM_NUM,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '001' --有业务关系
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;

INSERT INTO `G25_2_1.4.1.A.2016`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_1.4.1.A.2016' AS ITEM_NUM, --add by djh20220622 注意与G2501规则相同，所有除不可提前支取的外，其他存款视为活期，要放在6个月内
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '002' --有业务关系,且不是稳定存款那些类型的
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;

--4.1业务关系存款.金额（按剩余期限）.<6个月
    --4.1业务关系存款.金额（按剩余期限）.6-12个月
    --4.1业务关系存款.金额（按剩余期限）.≥1年
    INSERT INTO `G25_2_1.4.1.A.2016`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'A' THEN --<6个月
                'G25_2_1.4.1.A.2016'
               WHEN REMAIN_TERM_CODE = 'B' THEN --6-12个月
                'G25_2_1.4.1.B.2016'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G25_2_1.4.1.C.2016' --≥1年
             END AS ITEM_NUM,
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '001' --有业务关系
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;

INSERT INTO `G25_2_1.4.1.A.2016`
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
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G2502' AS REP_NUM,
             'G25_2_1.4.1.A.2016' AS ITEM_NUM, --add by djh20220622 注意与G2501规则相同，所有除不可提前支取的外，其他存款视为活期，要放在6个月内
             SUM(T.ACCT_BAL_RMB) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM CBRC_TMP_DEPOSIT_WD_DIFF_BUSINESS T
       WHERE T.FLAG_CODE = '002' --有业务关系,且不是稳定存款那些类型的
       GROUP BY T.ORG_NUM, REMAIN_TERM_CODE;


-- 指标: G25_2_1.10.B.2016
INSERT INTO `G25_2_1.10.B.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009804',
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             ITEM_CD,
             SUM(ACCRUAL),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.10.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.10.B.2016'
                       ELSE
                        'G25_2_1.10.A.2016'
                     END AS ITEM_CD,
                     SUM(A.INTEREST_ACCURAL) AS ACCRUAL
                FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE FLAG = '07' --卖出回购
                 AND A.DATA_DATE = I_DATADATE
                 AND A.MATUR_DATE > I_DATADATE
               GROUP BY CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.10.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.10.B.2016'
                          ELSE
                           'G25_2_1.10.A.2016'
                        END
              UNION ALL
              SELECT 'G25_2_1.10.A.2016' AS ITEM_CD, -SUM(T.DEBIT_BAL)
                FROM L_FINA_GL T
               WHERE DATA_DATE = I_DATADATE
                 AND ITEM_CD = '20040202'
                 AND ORG_NUM = '990000'
                 AND T.CURR_CD = 'CNY' --再贴现的利息调整取全行，放进剩余期限<6个月
              UNION ALL  --ADD BY DJH 20240510  金融市场部 009804 补充拆入 2003同业拆入利息
              SELECT CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.10.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.10.B.2016'
                       ELSE
                        'G25_2_1.10.A.2016'
                     END AS ITEM_CD,
                     SUM(A.INTEREST_ACCURAL) AS ACCRUAL
                FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE A.FLAG = '05' --同业拆入(有其他机构)
                  AND INTEREST_ACCURAL <> 0
                  AND A.ORG_NUM = '009804'
               GROUP BY CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.10.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.10.B.2016'
                          ELSE
                           'G25_2_1.10.A.2016'
                        END)
       GROUP BY ITEM_CD;

--10.以上未包括的所有其它负债和权益
    /*1.分行：资产类型为同业存放的定期中的利息按剩余期限划分报在009820机构；
    2.009820：同业拆入应付利息按期限-存单发行的应付利息调整按期限+3001（清算间往来）贷方放在6个月内；其中同业存单发行的应付利息调整按负数填报；
    009817机构从G01的60.负债及所有者权益总计同步取值，放>1年中；
    009816机构从G01资产负债项目统计表 49.负债合计同步取值；*/
    /*
    特殊： 同业存单发行的应付利息调整按负数填报   实际上不是报送在2231科目，而是在250202科目借方（利息调整），本金在贷方
     SELECT T.ORG_NUM, ITEM_CD, DEBIT_BAL, T.CREDIT_BAL
       FROM L_FINA_GL T
      WHERE DATA_DATE = I_DATADATE
        AND CURR_CD = 'BWB'
        AND ITEM_CD IN ('250202')*/

     --ADD BY DJH 20240510  同业金融部 009820
      INSERT INTO `G25_2_1.10.B.2016`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               '009820' AS ORG_NUM, --分行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                  'G25_2_1.10.C.2016' ---1年以上
                 WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                  'G25_2_1.10.B.2016' --6个月-1年
                 ELSE
                  'G25_2_1.10.A.2016'
               END AS ITEM_NUM,
               SUM(ITEM_VAL) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.GL_ITEM_CODE,
                       A.CUST_ID,
                       A.JYDSTYDM,
                       SUM(A.ACCRUAL * CCY_RATE) ITEM_VAL,
                       MATURE_DATE
                  FROM V_PUB_FUND_MMFUND A
                  LEFT JOIN L_PUBL_RATE TT
                    ON TT.CCY_DATE = I_DATADATE
                   AND TT.BASIC_CCY = A.CURR_CD
                   AND TT.FORWARD_CCY = 'CNY'
                 WHERE A.DATA_DATE = I_DATADATE
                   AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放定期
                   AND A.ACCRUAL <> 0
                   AND A.ORG_NUM NOT LIKE '5%'
                   AND A.ORG_NUM NOT LIKE '6%'
                 GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A
         GROUP BY CASE
                    WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                     'G25_2_1.10.C.2016' ---1年以上
                    WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                     'G25_2_1.10.B.2016' --6个月-1年
                    ELSE
                     'G25_2_1.10.A.2016'
                  END;

--ADD BY DJH 20240510  同业金融部 009820
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，2003拆入资金交易产生的应付利息 与核对223111科目贷方余额应付利息核对
     INSERT INTO `G25_2_1.10.B.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.10.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.10.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.10.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                SUM(INTEREST_ACCURAL) ITEM_VAL,
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG IN ('05', '10') --同业拆入 转贷款 应付利息
                  AND INTEREST_ACCURAL <> 0
                  AND A.ORG_NUM IN ('009820', '009801')
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.10.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.10.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.10.A.2016'
                 END,
                 ORG_NUM;

--ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO `G25_2_1.10.B.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009820' AS ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.10.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.10.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.10.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                -1 * SUM(CYCB) ITEM_VAL, --利息调整  CYCB资产方的叫持有成本，负债方的利息调整   台账表中【利息收益（即利息调整）】
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG = '06' --同业存单发行
                  AND CYCB <> 0
                  AND A.ORG_NUM = '009820'
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.10.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.10.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.10.A.2016'
                 END;

INSERT INTO `G25_2_1.10.B.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009804',
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             ITEM_CD,
             SUM(ACCRUAL),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.10.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.10.B.2016'
                       ELSE
                        'G25_2_1.10.A.2016'
                     END AS ITEM_CD,
                     SUM(A.INTEREST_ACCURAL) AS ACCRUAL
                FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE FLAG = '07' --卖出回购
                 AND A.DATA_DATE = I_DATADATE
                 AND A.MATUR_DATE > I_DATADATE
               GROUP BY CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.10.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.10.B.2016'
                          ELSE
                           'G25_2_1.10.A.2016'
                        END
              UNION ALL
              SELECT 'G25_2_1.10.A.2016' AS ITEM_CD, -SUM(T.DEBIT_BAL)
                FROM L_FINA_GL T
               WHERE DATA_DATE = I_DATADATE
                 AND ITEM_CD = '20040202'
                 AND ORG_NUM = '990000'
                 AND T.CURR_CD = 'CNY' --再贴现的利息调整取全行，放进剩余期限<6个月
              UNION ALL  --ADD BY DJH 20240510  金融市场部 009804 补充拆入 2003同业拆入利息
              SELECT CASE
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 360 THEN
                        'G25_2_1.10.C.2016'
                       WHEN A.MATUR_DATE - A.DATA_DATE >= 180 THEN
                        'G25_2_1.10.B.2016'
                       ELSE
                        'G25_2_1.10.A.2016'
                     END AS ITEM_CD,
                     SUM(A.INTEREST_ACCURAL) AS ACCRUAL
                FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
               WHERE A.FLAG = '05' --同业拆入(有其他机构)
                  AND INTEREST_ACCURAL <> 0
                  AND A.ORG_NUM = '009804'
               GROUP BY CASE
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 360 THEN
                           'G25_2_1.10.C.2016'
                          WHEN A.MATUR_DATE -
                               A.DATA_DATE >= 180 THEN
                           'G25_2_1.10.B.2016'
                          ELSE
                           'G25_2_1.10.A.2016'
                        END)
       GROUP BY ITEM_CD;

--10.以上未包括的所有其它负债和权益
    /*1.分行：资产类型为同业存放的定期中的利息按剩余期限划分报在009820机构；
    2.009820：同业拆入应付利息按期限-存单发行的应付利息调整按期限+3001（清算间往来）贷方放在6个月内；其中同业存单发行的应付利息调整按负数填报；
    009817机构从G01的60.负债及所有者权益总计同步取值，放>1年中；
    009816机构从G01资产负债项目统计表 49.负债合计同步取值；*/
    /*
    特殊： 同业存单发行的应付利息调整按负数填报   实际上不是报送在2231科目，而是在250202科目借方（利息调整），本金在贷方
     SELECT T.ORG_NUM, ITEM_CD, DEBIT_BAL, T.CREDIT_BAL
       FROM L_FINA_GL T
      WHERE DATA_DATE = I_DATADATE
        AND CURR_CD = 'BWB'
        AND ITEM_CD IN ('250202')*/

     --ADD BY DJH 20240510  同业金融部 009820
      INSERT INTO `G25_2_1.10.B.2016`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         ITEM_VAL, --指标值
         FLAG, --标志位
         B_CURR_CD)
        SELECT I_DATADATE AS DATA_DATE, --数据日期
               '009820' AS ORG_NUM, --分行报在009820机构
               'CBRC' AS SYS_NAM, --模块简称
               'G2502' AS REP_NUM, --报表编号
               CASE
                 WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                  'G25_2_1.10.C.2016' ---1年以上
                 WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                  'G25_2_1.10.B.2016' --6个月-1年
                 ELSE
                  'G25_2_1.10.A.2016'
               END AS ITEM_NUM,
               SUM(ITEM_VAL) AS ITEM_VAL,
               '2' AS FLAG,
               'ALL' AS B_CURR_CD
          FROM (SELECT A.GL_ITEM_CODE,
                       A.CUST_ID,
                       A.JYDSTYDM,
                       SUM(A.ACCRUAL * CCY_RATE) ITEM_VAL,
                       MATURE_DATE
                  FROM V_PUB_FUND_MMFUND A
                  LEFT JOIN L_PUBL_RATE TT
                    ON TT.CCY_DATE = I_DATADATE
                   AND TT.BASIC_CCY = A.CURR_CD
                   AND TT.FORWARD_CCY = 'CNY'
                 WHERE A.DATA_DATE = I_DATADATE
                   AND SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' --同业存放定期
                   AND A.ACCRUAL <> 0
                   AND A.ORG_NUM NOT LIKE '5%'
                   AND A.ORG_NUM NOT LIKE '6%'
                 GROUP BY A.GL_ITEM_CODE, A.CUST_ID, A.JYDSTYDM, MATURE_DATE) A
         GROUP BY CASE
                    WHEN A.MATURE_DATE - I_DATADATE >= 360 THEN
                     'G25_2_1.10.C.2016' ---1年以上
                    WHEN A.MATURE_DATE - I_DATADATE >= 180 THEN
                     'G25_2_1.10.B.2016' --6个月-1年
                    ELSE
                     'G25_2_1.10.A.2016'
                  END;

--ADD BY DJH 20240510  同业金融部 009820
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心，2003拆入资金交易产生的应付利息 与核对223111科目贷方余额应付利息核对
     INSERT INTO `G25_2_1.10.B.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.10.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.10.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.10.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                SUM(INTEREST_ACCURAL) ITEM_VAL,
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG IN ('05', '10') --同业拆入 转贷款 应付利息
                  AND INTEREST_ACCURAL <> 0
                  AND A.ORG_NUM IN ('009820', '009801')
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.10.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.10.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.10.A.2016'
                 END,
                 ORG_NUM;

--ADD BY DJH 20240510  同业金融部 009820
     INSERT INTO `G25_2_1.10.B.2016`
       (DATA_DATE, --数据日期
        ORG_NUM, --机构号
        SYS_NAM, --模块简称
        REP_NUM, --报表编号
        ITEM_NUM, --指标号
        ITEM_VAL, --指标值
        FLAG, --标志位
        B_CURR_CD)
       SELECT I_DATADATE AS DATA_DATE, --数据日期
              '009820' AS ORG_NUM,
              'CBRC' AS SYS_NAM, --模块简称
              'G2502' AS REP_NUM, --报表编号
              CASE
                WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                 'G25_2_1.10.C.2016' ---1年以上
                WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                 'G25_2_1.10.B.2016' --6个月-1年
                ELSE
                 'G25_2_1.10.A.2016'
              END AS ITEM_NUM,
              SUM(ITEM_VAL) AS ITEM_VAL,
              '2' AS FLAG,
              'ALL' AS B_CURR_CD
         FROM (SELECT 
                A.GL_ITEM_CODE,
                A.CUST_ID,
                -1 * SUM(CYCB) ITEM_VAL, --利息调整  CYCB资产方的叫持有成本，负债方的利息调整   台账表中【利息收益（即利息调整）】
                MATUR_DATE,
                A.ORG_NUM
                 FROM CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                WHERE A.FLAG = '06' --同业存单发行
                  AND CYCB <> 0
                  AND A.ORG_NUM = '009820'
                GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
        GROUP BY CASE
                   WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                    'G25_2_1.10.C.2016' ---1年以上
                   WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                    'G25_2_1.10.B.2016' --6个月-1年
                   ELSE
                    'G25_2_1.10.A.2016'
                 END;


-- 指标: G25_2_2.9.2.A.2016
-------9.2其他  一级资产，2A资产的抵押面额（账面余额*质押面额）/持有仓位）+其他信用评级的债券账面余额（抵押+未抵押）包含同业存单
    INSERT INTO `G25_2_2.9.2.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.ORG_NUM,
                     DC_DATE,
                     SUM(CASE
                           WHEN ((A.ISSU_ORG = 'D02' AND
                                A.STOCK_PRO_TYPE LIKE 'C%') OR --（发行主体类型：D02政策性银行，债券产品类型：C是金融债（大类）包含很多小类）
                                (A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A')) THEN --（发行主体类型：A01中央政府，债券产品类型：A政府债券（指我国政府发行债券））
                            A.PRINCIPAL_BALANCE_CNY * A.COLL_AMT_CNY / A.ACCT_BAL_CNY  --（账面余额*质押面额）/持有仓位）
                           WHEN ((A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') OR --（发行主体类型：A02地方政府，债券产品类型：A政府债券（指我国政府发行债券）），
                                (A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
                                A.STOCK_PRO_TYPE IN
                                ('D01', 'D02', 'D04', 'D05')) --（债券产品类型：D01短期融资券，D02中期票据，D04企业债，D05公司债， 且信用评级是AA的债券）
                                OR
                                A.STOCK_CD IN
                                ('032000573', '032001060', 'X0003118A1600001')) THEN --债券编号'032000573' 20四平城投PPN001, '032001060' 20四平城投PPN002-外部评级AA,18翔控01(X0003118A1600001)-外部评级AA+
                            A.PRINCIPAL_BALANCE_CNY * A.COLL_AMT_CNY / A.ACCT_BAL_CNY
                           ELSE
                            A.PRINCIPAL_BALANCE_CNY
                         END) AS ITEM_VAL
                FROM CBRC_tmp_a_cbrc_bond_bal A
               WHERE A.INVEST_TYP = '00'
                 AND A.DC_DATE > 0 --不取逾期
                 AND A.STOCK_NAM <> '18华阳经贸CP001' --特殊处理，算逾期
                 AND ACCT_BAL_CNY <> 0   --JLBA202411080004
               GROUP BY A.ORG_NUM, DC_DATE
              UNION ALL
              SELECT A.ORG_NUM, DC_DATE, SUM(ACCT_BAL_RMB)
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE FLAG = '04'
                AND ORG_NUM = '009804' --此处不限制机构，同业存单 包含金融市场部，同业金融部2个部分数据  -ADD BY DJH 20240510  同业金融部 009820  分开写也可同数据源
               GROUP BY A.ORG_NUM, DC_DATE) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.DC_DATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN A.DC_DATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
                END;

--9.2其他     /*同业存单投资中登净价金额+基金持有仓位+基金的公允按剩余期限划分；其中随时申赎的基金放<6个月，定开的按剩余期限划分填报在009820*/
    --ADD BY DJH 20240510  同业金融部 009820

    INSERT INTO `G25_2_2.9.2.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.ORG_NUM, DC_DATE, SUM(ACCT_BAL_RMB) ITEM_VAL
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE FLAG = '04'
                 AND ORG_NUM = '009820' --此处不限制机构，同业存单 包含金融市场部，同业金融部2个部分数据  -ADD BY DJH 20240510  同业金融部 009820  分开写也可同数据源
               GROUP BY A.ORG_NUM, DC_DATE) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN DC_DATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN DC_DATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
                END;

INSERT INTO `G25_2_2.9.2.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(ACCT_BAL_RMB) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.FLAG = '06' --基金
                 AND A.REDEMPTION_TYPE = '定期赎回'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
                END;

--ADD BY DJH 20240510  同业金融部 009820
    INSERT INTO `G25_2_2.9.2.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.9.2.A.2016' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(ACCT_BAL_RMB) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.FLAG = '06' --基金
                 AND A.REDEMPTION_TYPE = '随时赎回'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
       GROUP BY A.ORG_NUM;

-------9.2其他  一级资产，2A资产的抵押面额（账面余额*质押面额）/持有仓位）+其他信用评级的债券账面余额（抵押+未抵押）包含同业存单
    INSERT INTO `G25_2_2.9.2.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.DC_DATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN A.DC_DATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.ORG_NUM,
                     DC_DATE,
                     SUM(CASE
                           WHEN ((A.ISSU_ORG = 'D02' AND
                                A.STOCK_PRO_TYPE LIKE 'C%') OR --（发行主体类型：D02政策性银行，债券产品类型：C是金融债（大类）包含很多小类）
                                (A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A')) THEN --（发行主体类型：A01中央政府，债券产品类型：A政府债券（指我国政府发行债券））
                            A.PRINCIPAL_BALANCE_CNY * A.COLL_AMT_CNY / A.ACCT_BAL_CNY  --（账面余额*质押面额）/持有仓位）
                           WHEN ((A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') OR --（发行主体类型：A02地方政府，债券产品类型：A政府债券（指我国政府发行债券）），
                                (A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
                                A.STOCK_PRO_TYPE IN
                                ('D01', 'D02', 'D04', 'D05')) --（债券产品类型：D01短期融资券，D02中期票据，D04企业债，D05公司债， 且信用评级是AA的债券）
                                OR
                                A.STOCK_CD IN
                                ('032000573', '032001060', 'X0003118A1600001')) THEN --债券编号'032000573' 20四平城投PPN001, '032001060' 20四平城投PPN002-外部评级AA,18翔控01(X0003118A1600001)-外部评级AA+
                            A.PRINCIPAL_BALANCE_CNY * A.COLL_AMT_CNY / A.ACCT_BAL_CNY
                           ELSE
                            A.PRINCIPAL_BALANCE_CNY
                         END) AS ITEM_VAL
                FROM CBRC_tmp_a_cbrc_bond_bal A
               WHERE A.INVEST_TYP = '00'
                 AND A.DC_DATE > 0 --不取逾期
                 AND A.STOCK_NAM <> '18华阳经贸CP001' --特殊处理，算逾期
                 AND ACCT_BAL_CNY <> 0   --JLBA202411080004
               GROUP BY A.ORG_NUM, DC_DATE
              UNION ALL
              SELECT A.ORG_NUM, DC_DATE, SUM(ACCT_BAL_RMB)
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE FLAG = '04'
                AND ORG_NUM = '009804' --此处不限制机构，同业存单 包含金融市场部，同业金融部2个部分数据  -ADD BY DJH 20240510  同业金融部 009820  分开写也可同数据源
               GROUP BY A.ORG_NUM, DC_DATE) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.DC_DATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN A.DC_DATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
                END;

--9.2其他     /*同业存单投资中登净价金额+基金持有仓位+基金的公允按剩余期限划分；其中随时申赎的基金放<6个月，定开的按剩余期限划分填报在009820*/
    --ADD BY DJH 20240510  同业金融部 009820

    INSERT INTO `G25_2_2.9.2.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN DC_DATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN DC_DATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT A.ORG_NUM, DC_DATE, SUM(ACCT_BAL_RMB) ITEM_VAL
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE FLAG = '04'
                 AND ORG_NUM = '009820' --此处不限制机构，同业存单 包含金融市场部，同业金融部2个部分数据  -ADD BY DJH 20240510  同业金融部 009820  分开写也可同数据源
               GROUP BY A.ORG_NUM, DC_DATE) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN DC_DATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN DC_DATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
                END;

INSERT INTO `G25_2_2.9.2.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                'G25_2_2.9.2.C.2016' ---1年以上
               WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                'G25_2_2.9.2.B.2016' --6个月-1年
               ELSE
                'G25_2_2.9.2.A.2016'
             END AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(ACCT_BAL_RMB) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.FLAG = '06' --基金
                 AND A.REDEMPTION_TYPE = '定期赎回'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.MATUR_DATE - I_DATADATE >= 360 THEN
                   'G25_2_2.9.2.C.2016' ---1年以上
                  WHEN A.MATUR_DATE - I_DATADATE >= 180 THEN
                   'G25_2_2.9.2.B.2016' --6个月-1年
                  ELSE
                   'G25_2_2.9.2.A.2016'
                END;

--ADD BY DJH 20240510  同业金融部 009820
    INSERT INTO `G25_2_2.9.2.A.2016`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --全行报在009820机构
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             'G25_2_2.9.2.A.2016' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM (SELECT 
               A.GL_ITEM_CODE,
               A.CUST_ID,
               SUM(ACCT_BAL_RMB) ITEM_VAL,
               MATUR_DATE,
               A.ORG_NUM
                FROM CBRC_TMP_A_CBRC_LOAN_BAL A
               WHERE A.FLAG = '06' --基金
                 AND A.REDEMPTION_TYPE = '随时赎回'
               GROUP BY A.GL_ITEM_CODE, A.CUST_ID, MATUR_DATE, A.ORG_NUM) A
       GROUP BY A.ORG_NUM;


-- 指标: G25_2_2.16.A.2016
A列资产负债表资产总计期末余额（年末保持与G01利润结转后的资产总计一致）
     16.其他资产.金额（按剩余期限）6-12个月:G1.9其他有确定到期日的资产(理财资管回传表)180≦剩余期限<360
     16.其他资产.金额（按剩余期限）≥1年:G1.9其他有确定到期日的资产(理财资管回传表)剩余期限一年以上*/
   INSERT INTO `G25_2_2.16.A.2016`
     (DATA_DATE, --数据日期
      ORG_NUM, --机构号
      SYS_NAM, --模块简称
      REP_NUM, --报表编号
      ITEM_NUM, --指标号
      ITEM_VAL, --指标值
      FLAG, --标志位
      B_CURR_CD)
     SELECT I_DATADATE AS DATA_DATE, --数据日期
            A.ORG_NUM AS ORG_NUM,
            'CBRC' AS SYS_NAM, --模块简称
            'G2502' AS REP_NUM, --报表编号
            CASE
              WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
               'G25_2_2.15.C.2016' ---1年以上
              WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
               'G25_2_2.15.B.2016' --6个月-1年
             /* ELSE
               'G25_2_2.16.A.2016'*/
            END AS ITEM_NUM,
            SUM(RECVAPAY_AMT) AS ITEM_VAL,
            '2' AS FLAG,
            'ALL' AS B_CURR_CD
       FROM (SELECT A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT) RECVAPAY_AMT
               FROM cbrc_tmp_fimm_product_bal A
              WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
                AND FLAG = '1'
             GROUP BY A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE)
             UNION ALL
             SELECT A.ORG_NUM,REDEMP_DATE AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT)
               FROM cbrc_tmp_fimm_product_bal A
              WHERE A.OPER_TYPE LIKE '2%' --运行方式是封闭式
                AND FLAG = '1'
              GROUP BY A.ORG_NUM,REDEMP_DATE) A
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
                  'G25_2_2.15.C.2016' ---1年以上
                 WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
                  'G25_2_2.15.B.2016' --6个月-1年
                /* ELSE
                  'G25_2_2.16.A.2016'*/
               END;

A列资产负债表资产总计期末余额（年末保持与G01利润结转后的资产总计一致）
     16.其他资产.金额（按剩余期限）6-12个月:G1.9其他有确定到期日的资产(理财资管回传表)180≦剩余期限<360
     16.其他资产.金额（按剩余期限）≥1年:G1.9其他有确定到期日的资产(理财资管回传表)剩余期限一年以上*/
   INSERT INTO `G25_2_2.16.A.2016`
     (DATA_DATE, --数据日期
      ORG_NUM, --机构号
      SYS_NAM, --模块简称
      REP_NUM, --报表编号
      ITEM_NUM, --指标号
      ITEM_VAL, --指标值
      FLAG, --标志位
      B_CURR_CD)
     SELECT I_DATADATE AS DATA_DATE, --数据日期
            A.ORG_NUM AS ORG_NUM,
            'CBRC' AS SYS_NAM, --模块简称
            'G2502' AS REP_NUM, --报表编号
            CASE
              WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
               'G25_2_2.15.C.2016' ---1年以上
              WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
               'G25_2_2.15.B.2016' --6个月-1年
             /* ELSE
               'G25_2_2.16.A.2016'*/
            END AS ITEM_NUM,
            SUM(RECVAPAY_AMT) AS ITEM_VAL,
            '2' AS FLAG,
            'ALL' AS B_CURR_CD
       FROM (SELECT A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT) RECVAPAY_AMT
               FROM cbrc_tmp_fimm_product_bal A
              WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
                AND FLAG = '1'
             GROUP BY A.ORG_NUM,COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE)
             UNION ALL
             SELECT A.ORG_NUM,REDEMP_DATE AS MATURITY_DT,
                    SUM(A.RECVAPAY_AMT)
               FROM cbrc_tmp_fimm_product_bal A
              WHERE A.OPER_TYPE LIKE '2%' --运行方式是封闭式
                AND FLAG = '1'
              GROUP BY A.ORG_NUM,REDEMP_DATE) A
      GROUP BY A.ORG_NUM,
               CASE
                 WHEN A.MATURITY_DT - I_DATADATE >= 360 THEN
                  'G25_2_2.15.C.2016' ---1年以上
                 WHEN A.MATURITY_DT - I_DATADATE >= 180 THEN
                  'G25_2_2.15.B.2016' --6个月-1年
                /* ELSE
                  'G25_2_2.16.A.2016'*/
               END;


-- ========== 逻辑组 30: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009804',
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATURE_DATE - A.DATA_DATE >= 360 THEN
                'G25_2_1.5.3.C.2016'
               WHEN A.MATURE_DATE - A.DATA_DATE >= 180 THEN
                'G25_2_1.5.3.B.2016'
               ELSE
                'G25_2_1.5.3.A.2016'
             END AS ITEM_NUM,
             SUM(BALANCE),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM V_PUB_FUND_MMFUND A
       WHERE DATA_DATE = I_DATADATE
         AND ACCT_TYP IN ('20303', '20304') --20303 回购式再贴现  20304 买断式再贴现   取全行的再贴现
       GROUP BY CASE
                  WHEN A.MATURE_DATE - A.DATA_DATE >= 360 THEN
                   'G25_2_1.5.3.C.2016'
                  WHEN A.MATURE_DATE - A.DATA_DATE >= 180 THEN
                   'G25_2_1.5.3.B.2016'
                  ELSE
                   'G25_2_1.5.3.A.2016'
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
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009804',
             'CBRC' AS SYS_NAM, --模块简称
             'G2502' AS REP_NUM, --报表编号
             CASE
               WHEN A.MATURE_DATE - A.DATA_DATE >= 360 THEN
                'G25_2_1.5.3.C.2016'
               WHEN A.MATURE_DATE - A.DATA_DATE >= 180 THEN
                'G25_2_1.5.3.B.2016'
               ELSE
                'G25_2_1.5.3.A.2016'
             END AS ITEM_NUM,
             SUM(BALANCE),
             '2' AS FLAG,
             'ALL' AS B_CURR_CD
        FROM V_PUB_FUND_MMFUND A
       WHERE DATA_DATE = I_DATADATE
         AND ACCT_TYP IN ('20303', '20304') --20303 回购式再贴现  20304 买断式再贴现   取全行的再贴现
       GROUP BY CASE
                  WHEN A.MATURE_DATE - A.DATA_DATE >= 360 THEN
                   'G25_2_1.5.3.C.2016'
                  WHEN A.MATURE_DATE - A.DATA_DATE >= 180 THEN
                   'G25_2_1.5.3.B.2016'
                  ELSE
                   'G25_2_1.5.3.A.2016'
                END
) q_30
INSERT INTO `G25_2_1.5.3.A.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *
INSERT INTO `G25_2_1.5.3.B.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG,  
       B_CURR_CD)
SELECT *;

-- 指标: G25_2_2.1.A.2016
-- ADD BY DJH 20240510 同业金融部，金融市场部，投资银行部等业务指标加工临时报

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.REP_NUM = 'G2502'
       AND DATA_DATE = I_DATADATE
       AND T.ITEM_NUM <> 'G25_2_2.1.A.2016';

-- ADD BY DJH 20240510 同业金融部，金融市场部，投资银行部等业务指标加工临时报

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.REP_NUM = 'G2502'
       AND DATA_DATE = I_DATADATE
       AND T.ITEM_NUM <> 'G25_2_2.1.A.2016';


