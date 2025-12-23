-- ============================================================
-- 文件名: S70科技金融基本情况表_2.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: S70_1.1.1.B.2025
INSERT INTO `S70_1.1.1.B.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT,
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_1, --合同号
       COL_2, --贷款编号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE, --贷款余额/客户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_8, --企业规模
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23  --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       --'S70_1_1..B.2022' AS ITEM_NUM,
       'S70_1.1.1.B.2025' AS ITEM_NUM, --指标号
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       T.DRAWDOWN_AMT * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/客户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          '大型'
         WHEN A.CORP_SCALE = 'M' THEN
          '中型'
         WHEN A.CORP_SCALE = 'S' THEN
          '小型'
         WHEN A.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_8, --企业规模
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10,--机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
         T1.CP_NAME AS COL_23 --贷款产品名称
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM =T1.LOAN_NUM
         AND T1.DATA_DATE = I_DATADATE
        
       WHERE A.IF_HIGH_SALA_CORP = 'Y' --Y 是高新技术企业
         AND t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y';


-- 指标: S70_1.1.1.D.2025
--高新技术企业 贷款余额

    INSERT INTO `S70_1.1.1.D.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT,
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_1, --合同号
       COL_2, --贷款编号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE, --贷款余额/客户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_8, --企业规模
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23  --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       --'S70_1_1..D.2022' AS ITEM_NUM,
       'S70_1.1.1.D.2025' AS ITEM_NUM, --指标号
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       T.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/客户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       CASE
         WHEN A.CORP_SCALE = 'B' THEN
          '大型'
         WHEN A.CORP_SCALE = 'M' THEN
          '中型'
         WHEN A.CORP_SCALE = 'S' THEN
          '小型'
         WHEN A.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_8, --企业规模
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10,--机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
         T.CP_NAME AS COL_23 --贷款产品名称
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        /*LEFT JOIN CBRC_UPRR_U_BASE_INST I
          ON T.ORG_NUM =I.INST_ID*/
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND A.IF_HIGH_SALA_CORP = 'Y' --Y 是高新技术企业
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现;


-- 指标: S70_1.1.4.E.2025
-- 中长期贷款余额

    INSERT INTO `S70_1.1.4.E.2025`
              (DATA_DATE, --数据日期
               ORG_NUM, --机构号
               DATA_DEPARTMENT,
               SYS_NAM, --模块简称
               REP_NUM, --报表编号
               ITEM_NUM, --指标号
               COL_1, --合同号
               COL_2, --贷款编号
               COL_3, --客户号
               COL_4, --客户名称
               TOTAL_VALUE, --贷款余额/客户数/放款金额
               COL_6, --放款日期
               COL_7, --原始到期日
               COL_8, --企业规模
               COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23  --贷款产品名称
               )
              SELECT 
               I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD,-- 数据条线
               'CBRC' AS SYS_NAM, --模块简称
               'S70_1' AS REP_NUM, --报表编号
               --'S70_4..E.2024' AS ITEM_NUM,
               'S70_1.1.4.E.2025' AS ITEM_NUM,
                T.ACCT_NUM AS COL_1, --合同号
               T.LOAN_NUM AS COL_2, --贷款编号
               T.CUST_ID AS COL_3, --客户号
               A.CUST_NAM AS COL_4, --客户名称
               T.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/客户数/放款金额
               T.DRAWDOWN_DT AS COL_6, --放款日期
               T.MATURITY_DT AS COL_7, --原始到期日
               CASE
                 WHEN A.CORP_SCALE = 'B' THEN
                  '大型'
                 WHEN A.CORP_SCALE = 'M' THEN
                  '中型'
                 WHEN A.CORP_SCALE = 'S' THEN
                  '小型'
                 WHEN A.CORP_SCALE = 'T' THEN
                  '微型'
               END AS COL_8, --企业规模
               T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10,--机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
         T.CP_NAME AS COL_23 --贷款产品名称
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --贷款借据信息表 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM SMTMODS_S7001_CUST_TEMP
                WHERE CUST_TYPE LIKE '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期界定范围
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据 后续于佳禾问监管说专精特新大型企业也要报送，苏桐与吴大为和冯启航确认一表通与east也一起修改逻辑
            -- AND P.CUST_NAME IS NOT NULL --专精特新”中小企业
            --AND A.IF_SPCLED_NEW_CUST = '1'
         AND (A.IF_SPCLED_NEW_CUST = '1' or A.HUGE_SPCLED_NEW_CORP = '1') --专精特新企业或专精特新小巨人
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
      -- GROUP BY T.ORG_NUM;


