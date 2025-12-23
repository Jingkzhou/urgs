-- ============================================================
-- 文件名: S70科技金融基本情况表_1.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: S70_1.1.4.F.2025
-- 信用贷款余额

    INSERT INTO `S70_1.1.4.F.2025`
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
      -- COL_10, --机构名称
       COL_11, --五级分类
       COL_23  --贷款产品名称
               )
              SELECT 
               I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD,-- 数据条线
               'CBRC' AS SYS_NAM, --模块简称
               'S70_1' AS REP_NUM, --报表编号
               --'S70_4..F.2024' AS ITEM_NUM,
               'S70_1.1.4.F.2025' AS ITEM_NUM,
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
      -- I.INST_NAME AS COL_10,--机构名称
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
         AND T.GUARANTY_TYP = 'D' --信用贷款判断条件
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据 后续于佳禾问监管说专精特新大型企业也要报送，苏桐与吴大为和冯启航确认一表通与east也一起修改逻辑
            -- AND P.CUST_NAME IS NOT NULL --专精特新”中小企业
            --AND A.IF_SPCLED_NEW_CUST = '1'
         AND (A.IF_SPCLED_NEW_CUST = '1' or A.HUGE_SPCLED_NEW_CORP = '1') --专精特新企业或专精特新小巨人
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.4.C.2025
--END
    -- 存量贷款户数

   INSERT INTO   `S70_1.1.4.C.2025`
           (DATA_DATE ,--数据日期
            ORG_NUM     ,--机构号
            SYS_NAM     ,--模块简称
            REP_NUM     ,--报表编号
            ITEM_NUM  ,--指标号
            COL_3     ,--客户号
            COL_4     ,--客户名称
            TOTAL_VALUE -- ,   --贷款余额/客户数/放款金额
           -- COL_10 --机构名称
          )
      SELECT 
       DISTINCT I_DATADATE AS DATA_DATE,
       F.ORG_CODE,
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       --'S70_4..C.2024' AS ITEM_NUM,
       'S70_1.1.4.C.2025' AS ITEM_NUM,
       T.CUST_ID AS COL_3     ,--客户号
       A.CUST_NAM AS      COL_4     ,--客户名称
         1 AS   TOTAL_VALUE  --  , --贷款余额/客户数/放款金额
         --I.INST_NAME --机构名称
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM SMTMODS_S7001_CUST_TEMP
                WHERE CUST_TYPE LIKE '%专精特新%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')*/
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据后续于佳禾问监管说专精特新大型企业也要报送，苏桐与吴大为和冯启航确认一表通与east也一起修改逻辑
            -- AND P.CUST_NAME IS NOT NULL --专精特新”中小企业
            --AND A.IF_SPCLED_NEW_CUST = '1'
         AND (A.IF_SPCLED_NEW_CUST = '1' or A.HUGE_SPCLED_NEW_CORP = '1') --专精特新企业或专精特新小巨人
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
      -- GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.4.C.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.1.3.E.2025
-- 中长期贷款余额

    INSERT INTO `S70_1.1.3.E.2025`
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
       --'S70_2.G.2025' AS ITEM_NUM,
       'S70_1.1.3.E.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       T.loan_acct_bal * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/客户数/放款金额
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
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    WHERE CUST_TYPE LIKE '%创新型%'
                    GROUP BY TRIM(CUST_NAME)) P --各企业类型清单
          ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期界定范围
         AND P.CUST_NAME IS NOT NULL
         AND A.CORP_SCALE IN ('M', 'S', 'T')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.6.C.2025
-- 存量贷款户数

    INSERT INTO `S70_1.1.6.C.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE  ,--贷款余额/客户数/放款金额
       --COL_10 , --机构名称
       COL_14  ,-- 国家技术创新示范企业
       COL_15  -- 制造业单项冠军企业

       )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.1.6.C.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE ,
              -- I.INST_NAME  AS COL_10,
               CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
                    WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
               CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
                    WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  -- 制造业单项冠军企业
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND (A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             or A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.6.C.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.G.2025
-- 不良贷款余额

    INSERT INTO `S70_1.G.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
      -- COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_12  ,-- 高新技术
       COL_13  ,-- 科技型中小企业
       COL_14  ,-- 国家技术创新示范企业
       COL_15  ,-- 制造业单项冠军企业
       COL_16  ,-- 专精特新客户
       COL_17  ,-- 专精特新小巨人企业
       COL_18  ,-- 创新型企业
       COL_19  ,-- 高技术制造业类型
       COL_20  ,-- 高技术服务业类型
       COL_21  ,-- 战略性新兴产业类型
       COL_22  -- 知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.G.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       NVL(A.CUST_NAM,B.CUST_NAM) COL_4, --客户名称
       T.LOAN_ACCT_BAL * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
      CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
               CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
                    WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13  ,-- 科技型中小企业
               CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
                    WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
               CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
                    WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  ,-- 制造业单项冠军企业
               CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
                    WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
               CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
                    WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
               CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18,  -- 创新型企业
       M1.M_NAME as COL_19  ,--高技术制造业类型
       M2.M_NAME as COL_20  ,--高技术服务业类型
       M3.M_NAME as COL_21  ,--战略性新兴产业类型
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P B
           ON T.CUST_ID =B.CUST_ID
           AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON C.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON C.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  C.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类为次级、可疑、损失的贷款
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or
             (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')) or
             nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.6.E.2025
-- 中长期贷款余额

    INSERT INTO `S70_1.1.6.E.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_8, --企业规模
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_14  ,-- 国家技术创新示范企业
       COL_15  -- 制造业单项冠军企业
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.1.6.E.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.LOAN_ACCT_BAL * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       A.CORP_SCALE AS COL_8, --企业规模
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
            WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
       CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
            WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  -- 制造业单项冠军企业

        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --贷款借据信息表 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期界定范围
         AND (A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             or A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.C.2025
-- 存量贷款户数

    INSERT INTO `S70_1.1.C.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE  ,--贷款余额/客户数/放款金额
       --COL_10 , --机构名称
       COL_12  ,-- 高新技术
       COL_13  ,-- 科技型中小企业
       COL_14  ,-- 国家技术创新示范企业
       COL_15  ,-- 制造业单项冠军企业
       COL_16  ,-- 专精特新客户
       COL_17  ,-- 专精特新小巨人企业
       COL_18  -- 创新型企业
       )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.1.C.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE ,
              -- I.INST_NAME  AS COL_10,
               CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
               CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
                    WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13  ,-- 科技型中小企业
               CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
                    WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
               CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
                    WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  ,-- 制造业单项冠军企业
               CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
                    WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
               CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
                    WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
               CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18  -- 创新型企业
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')))
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
      -- GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.C.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.1.H.2025
--累放贷款年化利息收益

    /* INSERT INTO `S70_1.1.H.2025`
    (DATA_DATE, ORG_NUM, LOAN_ACCT_BAL, ITEM_NUM, FLAG)
    SELECT \*+ use_hash(T,A) parallel(4) *\
     I_DATADATE AS DATA_DATE,
     T.ORG_NUM,
     SUM(T.NHSY * TT.CCY_RATE) AS LOAN_ACCT_BAL,
     'S70_1.1.H.2025' AS ITEM_NUM,
     '2' FLAG
      FROM \*SMTMODS_L_ACCT_LOAN*\ CBRC_S70_LOAN_TEMP T --贷款借据信息表
     INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
        ON A.DATA_DATE = I_DATADATE
       AND A.CUST_ID = T.CUST_ID
       and a.CUST_TYP <> '3' --不等于个体工商户
      LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                   FROM SMTMODS_S7001_CUST_TEMP
                  where CUST_TYPE like '%创新型企业%'
                  GROUP BY TRIM(CUST_NAME)) P5
        ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
           replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
      LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
        ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
       AND TT.BASIC_CCY = T.CURR_CD --基准币种
       AND TT.FORWARD_CCY = 'CNY' --折算币种
     WHERE  t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
       and t.CANCEL_FLG <> 'Y'
       AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
           OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
           OR (A.IF_SPCLED_NEW_CUST = '1' AND
           A.CORP_SCALE IN ('B','S', 'M', 'T')) --专精特新”中小企业
           OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
           OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
           OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
           or(P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T'))
           )
     GROUP BY T.ORG_NUM;

*/
    INSERT INTO `S70_1.1.H.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_8, --企业规模
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_12  ,-- 高新技术
       COL_13  ,-- 科技型中小企业
       COL_14  ,-- 国家技术创新示范企业
       COL_15  ,-- 制造业单项冠军企业
       COL_16  ,-- 专精特新客户
       COL_17  ,-- 专精特新小巨人企业
       COL_18  -- 创新型企业

       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.1.H.2025' AS ITEM_NUM, --指标号
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Nhsy * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       A.CORP_SCALE AS COL_8, --企业规模
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
       CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
            WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13  ,-- 科技型中小企业
       CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
            WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
       CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
            WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  ,-- 制造业单项冠军企业
       CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
            WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
       CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
            WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
       CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18  -- 创新型企业
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         AND A.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    WHERE CUST_TYPE LIKE '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON REPLACE(REPLACE(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             REPLACE(REPLACE(TRIM(A.CUST_NAM), '(', '（'), ')', '）')

        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM = T1.LOAN_NUM
         AND T1.DATA_DATE = I_DATADATE
       WHERE T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
         AND T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
             I_DATADATE
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             OR
             (P5.CUST_NAME IS NOT NULL AND A.CORP_SCALE IN ('S', 'M', 'T')));


-- 指标: S70_1.F.2025
-- 信用贷款余额

    INSERT INTO `S70_1.F.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
      --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_12  ,-- 高新技术
       COL_13  ,-- 科技型中小企业
       COL_14  ,-- 国家技术创新示范企业
       COL_15  ,-- 制造业单项冠军企业
       COL_16  ,-- 专精特新客户
       COL_17  ,-- 专精特新小巨人企业
       COL_18  ,-- 创新型企业
       COL_19  ,-- 高技术制造业类型
       COL_20  ,-- 高技术服务业类型
       COL_21  ,-- 战略性新兴产业类型
       COL_22  -- 知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.F.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       NVL(A.CUST_NAM,B.CUST_NAM) COL_4, --客户名称
       T.LOAN_ACCT_BAL * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
      CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
               CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
                    WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13  ,-- 科技型中小企业
               CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
                    WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
               CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
                    WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  ,-- 制造业单项冠军企业
               CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
                    WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
               CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
                    WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
               CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18,  -- 创新型企业
       M1.M_NAME as COL_19  ,--高技术制造业类型
       M2.M_NAME as COL_20  ,--高技术服务业类型
       M3.M_NAME as COL_21  ,--战略性新兴产业类型
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P B
           ON T.CUST_ID =B.CUST_ID
           AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON C.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON C.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  C.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.GUARANTY_TYP = 'D' --信用贷款判断条件
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or
             (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')) or
             nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.5.H.2025
--20250318 2025年制度升级
    --START
    --当年累放贷款年化利息收益
    INSERT INTO `S70_1.1.5.H.2025`
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
      -- COL_10, --机构名称
       COL_11, --五级分类
       COL_23  --贷款产品名称
               )
              SELECT 
               I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD,-- 数据条线
               'CBRC' AS SYS_NAM, --模块简称
               'S70_1' AS REP_NUM, --报表编号
       --'S70_5..J.2025' AS ITEM_NUM,
       'S70_1.1.5.H.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
               T.LOAN_NUM AS COL_2, --贷款编号
               T.CUST_ID AS COL_3, --客户号
               A.CUST_NAM AS COL_4, --客户名称
               T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/客户数/放款金额
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
      -- I.INST_NAME AS COL_10,--机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
         T1.CP_NAME AS COL_23 --贷款产品名称
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM SMTMODS_S7001_CUST_TEMP
                WHERE CUST_TYPE LIKE '%专精特新小巨人%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')*/
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
         LEFT JOIN SMTMODS_L_ACCT_LOAN T1
                  ON T.LOAN_NUM = T1.LOAN_NUM
                 AND T1.DATA_DATE = I_DATADATE
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --AND P.CUST_NAME IS NOT NULL --专精特新“小巨人”企业
         AND A.HUGE_SPCLED_NEW_CORP = '1'
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.3.D.2025
-- 贷款余额

    INSERT INTO `S70_1.1.3.D.2025`
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
      -- COL_10, --机构名称
       COL_11, --五级分类
       COL_23  --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       --'S70_2.D.2025' AS ITEM_NUM,
       'S70_1.1.3.D.2025' AS ITEM_NUM,
        T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/客户数/放款金额
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
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    WHERE CUST_TYPE LIKE '%创新型%'
                    GROUP BY TRIM(CUST_NAME)) P --各企业类型清单
          ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND P.CUST_NAME IS NOT NULL
         AND A.CORP_SCALE IN ('M', 'S', 'T')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.5.F.2025
-- 信用贷款余额

     INSERT INTO `S70_1.1.5.F.2025`
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
       --'S70_5..F.2024' AS ITEM_NUM,
       'S70_1.1.5.F.2025' AS ITEM_NUM,
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
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM SMTMODS_S7001_CUST_TEMP
                WHERE CUST_TYPE LIKE '%专精特新小巨人%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.GUARANTY_TYP = 'D' --信用贷款判断条件
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --AND P.CUST_NAME IS NOT NULL --专精特新“小巨人”企业
         AND A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.1.H.2025
--20250318 2025年制度升级
    --START
    --当年累放贷款年化利息收益
    INSERT INTO `S70_1.1.1.H.2025`
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
       --'S70_1_1..J.2025' AS ITEM_NUM,
       'S70_1.1.1.H.2025' AS ITEM_NUM, --指标号
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/客户数/放款金额
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


-- 指标: S70_1.1.4.H.2025
--20250318 2025年制度升级
    --START
    --当年累放贷款年化利息收益
    INSERT INTO `S70_1.1.4.H.2025`
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
              -- COL_10, --机构名称
       COL_11, --五级分类
       COL_23  --贷款产品名称
               )
              SELECT 
               I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD,-- 数据条线
               'CBRC' AS SYS_NAM, --模块简称
               'S70_1' AS REP_NUM, --报表编号
               --'S70_4..J.2025' AS ITEM_NUM,
               'S70_1.1.4.H.2025' AS ITEM_NUM,
               T1.ACCT_NUM AS COL_1, --合同号
               T.LOAN_NUM AS COL_2, --贷款编号
               T.CUST_ID AS COL_3, --客户号
               A.CUST_NAM AS COL_4, --客户名称
               T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/客户数/放款金额
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
        FROM /* SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
    
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
                  ON T.LOAN_NUM = T1.LOAN_NUM
                 AND T1.DATA_DATE = I_DATADATE
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据 ,后续于佳禾问监管说专精特新大型企业也要报送，苏桐与吴大为和冯启航确认一表通与east也一起修改逻辑
            -- AND P.CUST_NAME IS NOT NULL --专精特新”中小企业
            --AND A.IF_SPCLED_NEW_CUST = '1'
         AND (A.IF_SPCLED_NEW_CUST = '1' or A.HUGE_SPCLED_NEW_CORP = '1') --专精特新企业或专精特新小巨人
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.1.F.2025
-- 信用贷款余额

    INSERT INTO `S70_1.2.1.F.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_19  --高技术制造业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.1.F.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M1.M_NAME as COL_19  --高技术制造业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID =A.CUST_ID
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON C.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.GUARANTY_TYP = 'D' --信用贷款判断条件
         AND (nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业

             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.1.E.2025
--高新技术企业 中长期贷款余额

    INSERT INTO `S70_1.1.1.E.2025`
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
       --'S70_1_1..E.2022' AS ITEM_NUM,
       'S70_1.1.1.E.2025' AS ITEM_NUM, --指标号
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
        /*LEFT JOIN CBRC_UPRR_U_BASE_INST I
          ON T.ORG_NUM =I.INST_ID*/
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期界定范围
         AND A.IF_HIGH_SALA_CORP = 'Y' --Y 是高新技术企业
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现;


-- 指标: S70_1.1.3.C.2025
-- 存量贷款户数

      INSERT INTO `S70_1.1.3.C.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE --,--贷款余额/客户数/放款金额
      -- COL_10 --机构名称
       )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE AS ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'S70_1' AS REP_NUM, --报表编号
       --'S70_2.C.2025' AS ITEM_NUM,
       'S70_1.1.3.C.2025' AS ITEM_NUM,
       T.CUST_ID AS COL_3,--客户号
               A.CUST_NAM AS COL_4,--客户名称
               '1' AS TOTAL_VALUE--,--贷款余额/客户数/放款金额
              -- I.INST_NAME AS COL_10  --机构名称
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    WHERE CUST_TYPE LIKE '%创新型%'
                    GROUP BY TRIM(CUST_NAME)) P --各企业类型清单
          ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND P.CUST_NAME IS NOT NULL
         AND A.CORP_SCALE IN ('M', 'S', 'T')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.3.C.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.2.4.A.2025
----------------------------1.2.4知识产权（专利）密集型产业
    --累放户数

     INSERT INTO `S70_1.2.4.A.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE -- ,--贷款余额/客户数/放款金额
       --COL_10  --机构名称
        )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.2.4.A.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE --,
               --I.INST_NAME  AS COL_10
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表

        LEFT JOIN CBRC_S7001_ORG_FLAT F ---机构汇总按照层级
          ON F.SUB_ORG_CODE = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.loan_stocken_date IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND nvl(T.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.2.4.A.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.1.4.A.2025
--4.“专精特新”中小企业
    ---当年累放贷款户数


          INSERT INTO   `S70_1.1.4.A.2025`
          (
          DATA_DATE ,--数据日期
          ORG_NUM     ,--机构号
          SYS_NAM     ,--模块简称
          REP_NUM     ,--报表编号
          ITEM_NUM  ,--指标号
          COL_3     ,--客户号
          COL_4     ,--客户名称
          TOTAL_VALUE --,    --贷款余额/客户数/放款金额
          -- COL_10 --机构名称
          )
      SELECT 
      DISTINCT  I_DATADATE AS DATA_DATE,
       F.ORG_CODE,
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       --'S70_4..A.2024' AS ITEM_NUM,
       'S70_1.1.4.A.2025' AS ITEM_NUM,
       T.CUST_ID  AS COL_3     ,--客户号
       A.CUST_NAM AS COL_4     ,--客户名称
       1 AS   TOTAL_VALUE  --  , --贷款余额/客户数/放款金额
       --I.ORDER_NUM
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
   
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据，后续于佳禾问监管说专精特新大型企业也要报送，苏桐与吴大为和冯启航确认一表通与east也一起修改逻辑
            -- AND P.CUST_NAME IS NOT NULL --专精特新”中小企业
            --AND A.IF_SPCLED_NEW_CUST = '1'
         AND (A.IF_SPCLED_NEW_CUST = '1' or A.HUGE_SPCLED_NEW_CORP = '1') --专精特新企业或专精特新小巨人
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.4.A.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.2.C.2025
-- 存量贷款户数

     INSERT INTO `S70_1.2.C.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE -- ,--贷款余额/客户数/放款金额
       --COL_10  --机构名称
        )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.2.C.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE --,
               --I.INST_NAME  AS COL_10
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
         LEFT JOIN SMTMODS_L_CUST_ALL A
            ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND (nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.2.C.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.2.F.2025
-- 信用贷款余额

    INSERT INTO `S70_1.2.F.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_19  ,--高技术制造业类型
       COL_20  ,--高技术服务业类型
       COL_21  ,--战略性新兴产业类型
       COL_22  --知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.F.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M1.M_NAME as COL_19  ,--高技术制造业类型
       M2.M_NAME as COL_20  ,--高技术服务业类型
       M3.M_NAME as COL_21  ,--战略性新兴产业类型
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID =A.CUST_ID
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON C.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON C.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  C.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.GUARANTY_TYP = 'D' --信用贷款判断条件
         AND (nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.4.G.2025
-- 不良贷款余额

    INSERT INTO `S70_1.2.4.G.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_22  --知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.4.G.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  C.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类为次级、可疑、损失的贷款
         AND nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
         AND SUBSTR(T.ITEM_CD, 1, 6) not IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.A.2025
----------------------------------     1.科技贷款    --------------------------------------------------
    --累放户数
    INSERT INTO `S70_1.A.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE -- ,--贷款余额/客户数/放款金额
       --COL_10  --机构名称
        )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.A.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A1.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE --,
              -- I.INST_NAME  AS COL_10
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
        left JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
         left join SMTMODS_L_CUST_ALL a1
            ON A1.DATA_DATE = I_DATADATE
         AND A1.CUST_ID = T.CUST_ID
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             or (A.IF_SPCLED_NEW_CUST = '1' and
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             or a.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             or A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             or A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or
             (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')) --创新型中小企业
             or nvl(t.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(t.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(t.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.A.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.2.1.A.2025
------------------------1.2.1高技术制造业-------------
    --累放户数
     INSERT INTO `S70_1.2.1.A.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE -- ,--贷款余额/客户数/放款金额
       --COL_10  --机构名称
        )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.2.1.A.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE --,
               --I.INST_NAME  AS COL_10
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表

        LEFT JOIN CBRC_S7001_ORG_FLAT F ---机构汇总按照层级
          ON F.SUB_ORG_CODE = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
          LEFT JOIN SMTMODS_L_CUST_ALL A
            ON T.CUST_ID =A.CUST_ID
            AND A.DATA_DATE =I_DATADATE
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.loan_stocken_date IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (nvl(t.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业

             )
      -- GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.2.1.A.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.2.H.2025
--累放贷款年化利息收益

    INSERT INTO `S70_1.2.H.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_19  ,--高技术制造业类型
       COL_20  ,--高技术服务业类型
       COL_21  ,--战略性新兴产业类型
       COL_22  --知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.H.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.NHSY * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       M1.M_NAME as COL_19  ,--高技术制造业类型
       M2.M_NAME as COL_20  ,--高技术服务业类型
       M3.M_NAME as COL_21  ,--战略性新兴产业类型
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
         LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM =T1.LOAN_NUM
          AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON t.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON t.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  T.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (nvl(t.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(t.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(t.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.B.2025
-- 当年累计发放贷款额

    INSERT INTO `S70_1.B.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_12  ,-- 高新技术
       COL_13  ,-- 科技型中小企业
       COL_14  ,-- 国家技术创新示范企业
       COL_15  ,-- 制造业单项冠军企业
       COL_16  ,-- 专精特新客户
       COL_17  ,-- 专精特新小巨人企业
       COL_18  ,-- 创新型企业
       COL_19  ,-- 高技术制造业类型
       COL_20  ,-- 高技术服务业类型
       COL_21  ,-- 战略性新兴产业类型
       COL_22  -- 知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.B.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       NVL(A.CUST_NAM,B.CUST_NAM) COL_4, --客户名称
       T.Drawdown_Amt * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
      CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
               CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
                    WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13  ,-- 科技型中小企业
               CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
                    WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
               CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
                    WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  ,-- 制造业单项冠军企业
               CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
                    WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
               CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
                    WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
               CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18,  -- 创新型企业
       M1.M_NAME as COL_19  ,--高技术制造业类型
       M2.M_NAME as COL_20  ,--高技术服务业类型
       M3.M_NAME as COL_21  ,--战略性新兴产业类型
       M4.M_NAME as COL_22  --知识产权密集型产业类型

        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
        left JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
         LEFT JOIN SMTMODS_L_CUST_P B
           ON T.CUST_ID =B.CUST_ID
           AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
            ON T.LOAN_NUM =T1.LOAN_NUM
            AND T1.DATA_DATE =I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON t.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON t.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  T.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or
             (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')) or
             nvl(t.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(t.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(t.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.4.F.2025
-- 信用贷款余额

    INSERT INTO `S70_1.2.4.F.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_22  --知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.4.F.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
      -- I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
         LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  C.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.GUARANTY_TYP = 'D' --信用贷款判断条件
         AND nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
         AND SUBSTR(T.ITEM_CD, 1, 6) not IN ('130102', '130105') --转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.4.D.2025
-- 贷款余额

    INSERT INTO `S70_1.1.4.D.2025`
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
      -- COL_10, --机构名称
       COL_11, --五级分类
       COL_23  --贷款产品名称
               )
              SELECT 
               I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD,-- 数据条线
               'CBRC' AS SYS_NAM, --模块简称
               'S70_1' AS REP_NUM, --报表编号
               --'S70_4..D.2024' AS ITEM_NUM,
              'S70_1.1.4.D.2025' AS ITEM_NUM,
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
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据后续于佳禾问监管说专精特新大型企业也要报送，苏桐与吴大为和冯启航确认一表通与east也一起修改逻辑
            -- AND P.CUST_NAME IS NOT NULL --专精特新”中小企业
            --AND A.IF_SPCLED_NEW_CUST = '1'
         AND (A.IF_SPCLED_NEW_CUST = '1' or A.HUGE_SPCLED_NEW_CORP = '1') --专精特新企业或专精特新小巨人
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.E.2025
-- 中长期贷款余额

    INSERT INTO `S70_1.2.E.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_19  ,--高技术制造业类型
       COL_20  ,--高技术服务业类型
       COL_21  ,--战略性新兴产业类型
       COL_22  --知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.E.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M1.M_NAME as COL_19  ,--高技术制造业类型
       M2.M_NAME as COL_20  ,--高技术服务业类型
       M3.M_NAME as COL_21  ,--战略性新兴产业类型
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --贷款借据信息表 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID =A.CUST_ID
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON C.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON C.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  C.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期界定范围
         AND (nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.2.A.2025
--科技型中小企业 当年累放贷款户数
   INSERT INTO `S70_1.1.2.A.2025`
        (
        DATA_DATE ,--数据日期
        ORG_NUM     ,--机构号
        SYS_NAM     ,--模块简称
        REP_NUM     ,--报表编号
        ITEM_NUM  ,--指标号
        COL_3     ,--客户号
        COL_4     ,--客户名称
        TOTAL_VALUE  --   ,--贷款余额/客户数/放款金额
       -- COL_10 --机构名称
        )
    SELECT 
    DISTINCT I_DATADATE AS DATA_DATE,
             F.ORG_CODE,
             'CBRC' AS SYS_NAM, --模块简称
             'S70_1' AS REP_NUM, --报表编号
             --'S70_1_2..A.2022' AS ITEM_NUM,
             'S70_1.1.2.A.2025' AS ITEM_NUM,
             T.CUST_ID AS col_3, --客户号
             A.CUST_NAM AS col_4, --客户名称
             1 AS TOTAL_VALUE --, --贷款余额/客户数/放款金额
            -- I.INST_NAME --机构名称
      FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
     INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
        ON A.DATA_DATE = I_DATADATE
       AND A.CUST_ID = T.CUST_ID
       and a.CUST_TYP <> '3' --不等于个体工商户
      LEFT JOIN CBRC_S7001_ORG_FLAT F ---机构汇总按照层级
        ON F.SUB_ORG_CODE = CASE
             WHEN T.ORG_NUM LIKE '%98%' THEN
              T.ORG_NUM
             WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
              '060300'
             ELSE
              SUBSTR(T.ORG_NUM, 1, 4) || '00'
           END
      /*LEFT JOIN CBRC_UPRR_U_BASE_INST I
        ON F.ORG_CODE = I.INST_ID*/
     WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
       and t.CANCEL_FLG <> 'Y'
       AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
          --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
          -- AND A.CORP_SCALE IN ('S', 'M', 'T')
          --  AND A.TECH_CORP_TYPE IN ('C01', 'C02') --C01 科技型企业-科创企业  C02 科技型企业-非科创企业
       AND A.IF_ST_SMAL_CORP = '1' --是否科技中小企业
    -- GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.2.A.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.2.2.D.2025
-- 贷款余额

    INSERT INTO `S70_1.2.2.D.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_20  --高技术服务业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.2.D.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M2.M_NAME as COL_20  --高技术服务业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON c.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.4.G.2025
-- 不良贷款余额

    INSERT INTO `S70_1.1.4.G.2025`
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
               --'S70_4..G.2024' AS ITEM_NUM,
               'S70_1.1.4.G.2025' AS ITEM_NUM,
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
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类为次级、可疑、损失的贷款
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据后续于佳禾问监管说专精特新大型企业也要报送，苏桐与吴大为和冯启航确认一表通与east也一起修改逻辑
            -- AND P.CUST_NAME IS NOT NULL --专精特新”中小企业
            --AND A.IF_SPCLED_NEW_CUST = '1'
         AND (A.IF_SPCLED_NEW_CUST = '1' or A.HUGE_SPCLED_NEW_CORP = '1') --专精特新企业或专精特新小巨人
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.5.B.2025
-- 当年累计发放贷款额
    INSERT INTO `S70_1.1.5.B.2025`
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
               --'S70_5..B.2024' AS ITEM_NUM,
               'S70_1.1.5.B.2025' AS ITEM_NUM,
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
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM SMTMODS_S7001_CUST_TEMP
                WHERE CUST_TYPE LIKE '%专精特新小巨人%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')*/
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
         LEFT JOIN SMTMODS_L_ACCT_LOAN T1
                  ON T.LOAN_NUM = T1.LOAN_NUM
                 AND T1.DATA_DATE = I_DATADATE
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --AND P.CUST_NAME IS NOT NULL --专精特新“小巨人”企业
         AND A.HUGE_SPCLED_NEW_CORP = '1'
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.5.E.2025
-- 中长期贷款余额

    INSERT INTO `S70_1.1.5.E.2025`
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
       --'S70_5..E.2024' AS ITEM_NUM,
       'S70_1.1.5.E.2025' AS ITEM_NUM,
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
      -- I.INST_NAME AS COL_10,--机构名称
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
                WHERE CUST_TYPE LIKE '%专精特新小巨人%'
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
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --AND P.CUST_NAME IS NOT NULL --专精特新“小巨人”企业
         AND A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.2.G.2025
--科技型中小企业 不良贷款余额

    INSERT INTO `S70_1.1.2.G.2025`
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
      -- COL_10, --机构名称
       COL_11, --五级分类
       COL_23  --贷款产品名称
               )
              SELECT 
               I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD,-- 数据条线
               'CBRC' AS SYS_NAM, --模块简称
               'S70_1' AS REP_NUM, --报表编号
                --'S70_1_2..G.2022' AS ITEM_NUM,
               'S70_1.1.2.G.2025' AS ITEM_NUM,
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
      -- I.INST_NAME AS COL_10,--机构名称
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
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类为次级、可疑、损失的贷款
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            -- AND A.CORP_SCALE IN ('S', 'M', 'T')
            --  AND A.TECH_CORP_TYPE IN ('C01', 'C02') --C01 科技型企业-科创企业  C02 科技型企业-非科创企业
         AND A.IF_ST_SMAL_CORP = '1' --是否科技中小企业
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.2.E.2025
--科技型中小企业 中长期贷款余额

    INSERT INTO `S70_1.1.2.E.2025`
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
               --'S70_1_2..E.2022' AS ITEM_NUM,
               'S70_1.1.2.E.2025' AS ITEM_NUM,
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
        /*LEFT JOIN CBRC_UPRR_U_BASE_INST I
         ON T.ORG_NUM =I.INST_ID*/
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期界定范围
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            -- AND A.CORP_SCALE IN ('S', 'M', 'T')
            --  AND A.TECH_CORP_TYPE IN ('C01', 'C02') --C01 科技型企业-科创企业  C02 科技型企业-非科创企业
         AND A.IF_ST_SMAL_CORP = '1' --是否科技中小企业
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.2.D.2025
--科技型中小企业 贷款余额

    INSERT INTO `S70_1.1.2.D.2025`
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
               --'S70_1_2..D.2022' AS ITEM_NUM,
               'S70_1.1.2.D.2025' AS ITEM_NUM,
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
      -- I.INST_NAME AS COL_10,--机构名称
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
         AND A.CORP_SCALE IN ('S', 'M', 'T')
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            -- AND A.CORP_SCALE IN ('S', 'M', 'T')
            --  AND A.TECH_CORP_TYPE IN ('C01', 'C02') --C01 科技型企业-科创企业  C02 科技型企业-非科创企业
         AND A.IF_ST_SMAL_CORP = '1' --是否科技中小企业
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.3.G.2025
-- 不良贷款余额

    INSERT INTO `S70_1.1.3.G.2025`
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
       --'S70_2.I.2025' AS ITEM_NUM,
       'S70_1.1.3.G.2025' AS ITEM_NUM,
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
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    WHERE CUST_TYPE LIKE '%创新型%'
                    GROUP BY TRIM(CUST_NAME)) P --各企业类型清单
          ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类为次级、可疑、损失的贷款
         AND P.CUST_NAME IS NOT NULL
         AND A.CORP_SCALE IN ('M', 'S', 'T')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.2.F.2025
-- 信用贷款余额

    INSERT INTO `S70_1.2.2.F.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_20  --高技术服务业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.2.F.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M2.M_NAME as COL_20  --高技术服务业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON c.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.GUARANTY_TYP = 'D' --信用贷款判断条件
         AND nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.3.H.2025
--累放贷款年化利息收益

    INSERT INTO `S70_1.2.3.H.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_21  --战略新兴产业
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.3.H.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Nhsy * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       M3.M_NAME as COL_21  --战略新兴产业
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
           ON T.LOAN_NUM =T1.LOAN_NUM
          AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.C.2025
-- 存量贷款户数

    INSERT INTO `S70_1.C.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE  --,--贷款余额/客户数/放款金额
       --COL_10  --机构名称
        )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.C.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A1.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE --,
               --I.INST_NAME  AS COL_10
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        left join SMTMODS_L_CUST_ALL a1
            ON A1.DATA_DATE = I_DATADATE
         AND A1.CUST_ID = T.CUST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or
             (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')) or
             nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
      -- GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.C.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.2.3.F.2025
-- 信用贷款余额

    INSERT INTO `S70_1.2.3.F.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_21  --战略新兴产业
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.3.F.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M3.M_NAME as COL_21  --战略新兴产业
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.GUARANTY_TYP = 'D' --信用贷款判断条件
         AND t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.2.B.2025
-- 累放金额

    INSERT INTO `S70_1.2.2.B.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_20  --高技术服务业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.2.B.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.DRAWDOWN_AMT * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       M2.M_NAME as COL_19  --高技术服务业类型
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM =T1.LOAN_NUM
          AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON t.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND nvl(t.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.3.B.2025
-- 当年累计发放贷款额
    INSERT INTO `S70_1.1.3.B.2025`
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
       --'S70_2.B.2025' AS ITEM_NUM,
       'S70_1.1.3.B.2025' AS ITEM_NUM,
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
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    WHERE CUST_TYPE LIKE '%创新型%'
                    GROUP BY TRIM(CUST_NAME)) P --各企业类型清单
          ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
         LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM =T1.LOAN_NUM
         AND T1.DATA_DATE = I_DATADATE
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND P.CUST_NAME IS NOT NULL
         AND A.CORP_SCALE IN ('M', 'S', 'T')
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.2.C.2025
-- 存量贷款户数

     INSERT INTO `S70_1.2.2.C.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE -- ,--贷款余额/客户数/放款金额
       --COL_10  --机构名称
        )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.2.2.C.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE --,
               --I.INST_NAME  AS COL_10
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
          LEFT JOIN SMTMODS_L_CUST_ALL A
             ON T.CUST_ID =A.CUST_ID
             AND A.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.2.2.C.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.2.4.B.2025
-- 累放金额

    INSERT INTO `S70_1.2.4.B.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_22  --知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.4.B.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.DRAWDOWN_AMT * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM =T1.LOAN_NUM
          AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  T.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND nvl(T.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.B.2025
-- 累放金额

    INSERT INTO `S70_1.2.B.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_19  ,--高技术制造业类型
       COL_20  ,--高技术服务业类型
       COL_21  ,--战略性新兴产业类型
       COL_22  --知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.B.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.DRAWDOWN_AMT * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       M1.M_NAME as COL_19  ,--高技术制造业类型
       M2.M_NAME as COL_20  ,--高技术服务业类型
       M3.M_NAME as COL_21  ,--战略性新兴产业类型
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM =T1.LOAN_NUM
          AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON t.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON t.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  T.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (nvl(t.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(t.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(t.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.1.C.2025
-- 存量贷款户数

     INSERT INTO `S70_1.2.1.C.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE -- ,--贷款余额/客户数/放款金额
       --COL_10  --机构名称
        )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.2.1.C.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE --,
               --I.INST_NAME  AS COL_10
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
          LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID =A.CUST_ID
          AND A.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND (nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.2.1.C.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.2.1.B.2025
-- 累放金额

    INSERT INTO `S70_1.2.1.B.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_19  --高技术制造业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.1.B.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.DRAWDOWN_AMT * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       M1.M_NAME as COL_19  --高技术制造业类型
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种、
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM =T1.LOAN_NUM
          AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID =A.CUST_ID
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON t.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (nvl(t.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             )
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.G.2025
-- 不良贷款余额

    INSERT INTO `S70_1.1.G.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_8, --企业规模
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_12  ,-- 高新技术
       COL_13  ,-- 科技型中小企业
       COL_14  ,-- 国家技术创新示范企业
       COL_15  ,-- 制造业单项冠军企业
       COL_16  ,-- 专精特新客户
       COL_17  ,-- 专精特新小巨人企业
       COL_18  -- 创新型企业

       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.1.G.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.LOAN_ACCT_BAL * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       A.CORP_SCALE AS COL_8, --企业规模
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
       CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
            WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13  ,-- 科技型中小企业
       CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
            WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
       CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
            WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  ,-- 制造业单项冠军企业
       CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
            WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
       CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
            WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
       CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18  -- 创新型企业
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类为次级、可疑、损失的贷款
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or
             (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')))
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.A.2025
--累放户数
    /*INSERT INTO `S70_1.1.A.2025`
      (DATA_DATE, ORG_NUM, LOAN_ACCT_BAL, ITEM_NUM, FLAG)
      SELECT \*+ use_hash(T,A) parallel(4) *\
       I_DATADATE AS DATA_DATE,
       F.ORG_CODE,
       COUNT(DISTINCT T.CUST_ID) AS LOAN_ACCT_BAL,
       'S70_1.1.A.2025' AS ITEM_NUM,
       '1' FLAG
        FROM  CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
      LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             or (A.IF_SPCLED_NEW_CUST = '1' and A.CORP_SCALE IN ('B','S', 'M', 'T')) --专精特新”中小企业
             or a.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             or A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             or A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')) --创新型中小企业
          )
       GROUP BY F.ORG_CODE;

*/

    INSERT INTO `S70_1.1.A.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE  ,--贷款余额/客户数/放款金额
       --COL_10 , --机构名称
       COL_12 ,-- 高新技术
        COL_13  ,-- 科技型中小企业
        COL_14  ,-- 国家技术创新示范企业
        COL_15  ,-- 制造业单项冠军企业
        COL_16  ,-- 专精特新客户
        COL_17  ,-- 专精特新小巨人企业
        COL_18  -- 创新型企业
       )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.1.A.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE ,
              -- I.INST_NAME  AS COL_10,
               CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
               CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
                    WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13 ,-- 科技型中小企业
               CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
                    WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
               CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
                    WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15 ,-- 制造业单项冠军企业
               CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
                    WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
               CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
                    WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
               CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18  -- 创新型企业

        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         AND A.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    WHERE CUST_TYPE LIKE '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON REPLACE(REPLACE(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             REPLACE(REPLACE(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        LEFT JOIN CBRC_S7001_ORG_FLAT F ---机构汇总按照层级
          ON F.SUB_ORG_CODE = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
       WHERE T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
         AND T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
             I_DATADATE
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             OR
             (P5.CUST_NAME IS NOT NULL AND A.CORP_SCALE IN ('S', 'M', 'T')) --创新型中小企业
             );

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.A.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.1.F.2025
-- 信用贷款余额

    INSERT INTO `S70_1.1.F.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_8, --企业规模
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_12  ,-- 高新技术
       COL_13  ,-- 科技型中小企业
       COL_14  ,-- 国家技术创新示范企业
       COL_15  ,-- 制造业单项冠军企业
       COL_16  ,-- 专精特新客户
       COL_17  ,-- 专精特新小巨人企业
       COL_18  -- 创新型企业

       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.1.F.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.LOAN_ACCT_BAL * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       A.CORP_SCALE AS COL_8, --企业规模
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
       CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
            WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13  ,-- 科技型中小企业
       CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
            WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
       CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
            WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  ,-- 制造业单项冠军企业
       CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
            WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
       CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
            WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
       CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18  -- 创新型企业
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.GUARANTY_TYP = 'D' --信用贷款判断条件
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or
             (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')))
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.D.2025
-- 贷款余额

    INSERT INTO `S70_1.1.D.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_8, --企业规模
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_12  ,-- 高新技术
       COL_13  ,-- 科技型中小企业
       COL_14  ,-- 国家技术创新示范企业
       COL_15  ,-- 制造业单项冠军企业
       COL_16  ,-- 专精特新客户
       COL_17  ,-- 专精特新小巨人企业
       COL_18  -- 创新型企业

       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.1.D.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       A.CORP_SCALE AS COL_8, --企业规模
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
       CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
            WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13  ,-- 科技型中小企业
       CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
            WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
       CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
            WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  ,-- 制造业单项冠军企业
       CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
            WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
       CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
            WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
       CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18  -- 创新型企业
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or
             (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')))
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.3.E.2025
-- 中长期贷款余额

    INSERT INTO `S70_1.2.3.E.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_21  --战略新兴产业
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.3.E.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M3.M_NAME as COL_21  --战略新兴产业
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --贷款借据信息表 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期界定范围
         AND t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.1.F.2025
--高新技术企业 信用贷款余额

    INSERT INTO `S70_1.1.1.F.2025`
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
       --'S70_1_1..F.2022' AS ITEM_NUM,
       'S70_1.1.1.F.2025' AS ITEM_NUM,
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
         AND T.GUARANTY_TYP = 'D' --信用贷款判断条件
         AND A.IF_HIGH_SALA_CORP = 'Y' --Y 是高新技术企业
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现;


-- 指标: S70_1.1.2.B.2025
*/

    --科技型中小企业 当年累计发放贷款额

    INSERT INTO `S70_1.1.2.B.2025`
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
               --'S70_1_2..B.2022' AS ITEM_NUM,
               'S70_1.1.2.B.2025' AS ITEM_NUM,
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
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
           ON T.LOAN_NUM = T1.LOAN_NUM
           AND T1.DATA_DATE = I_DATADATE
        /*LEFT JOIN CBRC_UPRR_U_BASE_INST I
          ON T.ORG_NUM =I.INST_ID*/
       WHERE

      --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据后续于佳禾问监管说专精特新大型企业也要报送，苏桐与吴大为和冯启航确认一表通与east也一起修改逻辑
      -- AND A.CORP_SCALE IN ('S', 'M', 'T')
      --  AND A.TECH_CORP_TYPE IN ('C01', 'C02') --C01 科技型企业-科创企业  C02 科技型企业-非科创企业
       A.IF_ST_SMAL_CORP = '1' --是否科技中小企业
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.5.C.2025
-- 存量贷款户数

    INSERT INTO   `S70_1.1.5.C.2025`
           (DATA_DATE ,--数据日期
            ORG_NUM     ,--机构号
            SYS_NAM     ,--模块简称
            REP_NUM     ,--报表编号
            ITEM_NUM  ,--指标号
            COL_3     ,--客户号
            COL_4     ,--客户名称
            TOTAL_VALUE    -- ,--贷款余额/客户数/放款金额
            --COL_10 --机构名称
          )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
       F.ORG_CODE,
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       --'S70_5..C.2024' AS ITEM_NUM,
       'S70_1.1.5.C.2025' AS ITEM_NUM,
       T.CUST_ID AS COL_3     ,--客户号
       A.CUST_NAM AS COL_4     ,--客户名称
         1   TOTAL_VALUE--,     --贷款余额/客户数/放款金额
       --I.INST_NAME
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM SMTMODS_S7001_CUST_TEMP
                WHERE CUST_TYPE LIKE '%专精特新小巨人%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')*/
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --AND P.CUST_NAME IS NOT NULL --专精特新“小巨人”企业
         AND A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.5.C.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.1.3.A.2025
--20250318 2025年制度升级
    --START
    --创新型中小企业

    ---当年累放贷款户数

     INSERT INTO   `S70_1.1.3.A.2025`
           (DATA_DATE ,--数据日期
            ORG_NUM     ,--机构号
            SYS_NAM     ,--模块简称
            REP_NUM     ,--报表编号
            ITEM_NUM  ,--指标号
            COL_3     ,--客户号
            COL_4     ,--客户名称
            TOTAL_VALUE   -- , --贷款余额/客户数/放款金额
           -- COL_10 --机构名称
          )
      SELECT 
       DISTINCT I_DATADATE AS DATA_DATE,
       F.ORG_CODE,
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号

       --'S70_2.A.2025' AS ITEM_NUM,
       'S70_1.1.3.A.2025' AS ITEM_NUM,
       T.CUST_ID AS COL_3     ,--客户号
       A.CUST_NAM AS COL_4     ,--客户名称
       1 AS TOTAL_VALUE    -- ,--贷款余额/客户数/放款金额
      -- I.INST_NAME
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    WHERE CUST_TYPE LIKE '%创新型%'
                    GROUP BY TRIM(CUST_NAME)) P --各企业类型清单
          ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND P.CUST_NAME IS NOT NULL --专精特新“小巨人”企业
         AND A.CORP_SCALE IN ('M', 'S', 'T')
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.3.A.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.1.2.H.2025
*/

    --20250318 2025年制度升级
    --START
    --科技型中小企业 当年累放贷款年化利息收益
    INSERT INTO `S70_1.1.2.H.2025`
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
       COL_23 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       --'S70_1_2..J.2025' AS ITEM_NUM,
       'S70_1.1.2.H.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/客户数/放款金额
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
      -- I.INST_NAME AS COL_10, --机构名称
       CASE
         WHEN T.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN T.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN T.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN T.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN T.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --五级分类
       T1.CP_NAME AS COL_23 --贷款产品名称
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM = T1.LOAN_NUM
         AND T1.DATA_DATE = I_DATADATE
        /*LEFT JOIN CBRC_UPRR_U_BASE_INST I
          ON T.ORG_NUM = I.INST_ID*/
       WHERE
      --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
      -- AND A.CORP_SCALE IN ('S', 'M', 'T')
      --  AND A.TECH_CORP_TYPE IN ('C01', 'C02') --C01 科技型企业-科创企业  C02 科技型企业-非科创企业
       A.IF_ST_SMAL_CORP = '1' --是否科技中小企业
      --  GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.5.D.2025
-- 贷款余额

    INSERT INTO `S70_1.1.5.D.2025`
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
      -- COL_10, --机构名称
       COL_11, --五级分类
       COL_23  --贷款产品名称
               )
              SELECT 
               I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD,-- 数据条线
               'CBRC' AS SYS_NAM, --模块简称
               'S70_1' AS REP_NUM, --报表编号
               --'S70_5..D.2024' AS ITEM_NUM,
               'S70_1.1.5.D.2025' AS ITEM_NUM,
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
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM SMTMODS_S7001_CUST_TEMP
                WHERE CUST_TYPE LIKE '%专精特新小巨人%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')*/
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --AND P.CUST_NAME IS NOT NULL --专精特新“小巨人”企业
         AND A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.1.C.2025
--高新技术企业 存量贷款户数

    INSERT INTO `S70_1.1.1.C.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE --,--贷款余额/客户数/放款金额
       --COL_10 --机构名称
       )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE, --数据日期
               F.ORG_CODE AS ORG_NUM, --机构号
               'CBRC' AS SYS_NAM, --模块简称
               'S70_1' AS REP_NUM, --报表编号
               --'S70_1_1..C.2022' AS ITEM_NUM,
               'S70_1.1.1.C.2025' AS ITEM_NUM, --指标号
               T.CUST_ID AS COL_3, --客户号
               A.CUST_ID AS COL_4, --客户名称
               1 AS TOTAL_VALUE--, --贷款余额/客户数/放款金额
               --I.INST_NAME  --机构名称
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         AND A.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN CBRC_S7001_ORG_FLAT F ---机构汇总按照层级
          ON F.SUB_ORG_CODE = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
          /*LEFT JOIN CBRC_UPRR_U_BASE_INST I
            ON F.ORG_CODE =I.INST_ID*/
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND A.IF_HIGH_SALA_CORP = 'Y' --Y 是高新技术企业
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.1.C.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.1.3.F.2025
-- 信用贷款余额

    INSERT INTO `S70_1.1.3.F.2025`
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
       --'S70_2.H.2025' AS ITEM_NUM,
       'S70_1.1.3.F.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/客户数/放款金额
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
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    WHERE CUST_TYPE LIKE '%创新型%'
                    GROUP BY TRIM(CUST_NAME)) P --各企业类型清单
          ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.GUARANTY_TYP = 'D' --信用贷款判断条件
         AND P.CUST_NAME IS NOT NULL
         AND A.CORP_SCALE IN ('M', 'S', 'T')
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.3.B.2025
-- 累放金额

    INSERT INTO `S70_1.2.3.B.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_21  --战略新兴产业
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.3.B.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.DRAWDOWN_AMT * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       M3.M_NAME as COL_21  --战略新兴产业
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
           ON T.LOAN_NUM =T1.LOAN_NUM
          AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.1.G.2025
-- 不良贷款余额

    INSERT INTO `S70_1.2.1.G.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_19  --高技术制造业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.1.G.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M1.M_NAME as COL_19  --高技术制造业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
       LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID =A.CUST_ID
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON C.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类为次级、可疑、损失的贷款
         AND (nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业

             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.4.H.2025
--累放贷款年化利息收益

    INSERT INTO `S70_1.2.4.H.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_22  --知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.4.H.2025' AS ITEM_NUM,
        T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.NHSY * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
      -- I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM =T1.LOAN_NUM
          AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  T.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND nvl(T.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.1.E.2025
-- 中长期贷款余额

    INSERT INTO `S70_1.2.1.E.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_19  --高技术制造业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.1.E.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M1.M_NAME as COL_19  --高技术制造业类型
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --贷款借据信息表 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID =A.CUST_ID
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON C.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期界定范围
         AND (nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业

             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.6.A.2025
--[JLBA202507020013][20250729][石雨][于佳禾][新增1.1.6其他科技型企业取数逻辑]
    ----------------------------------------------------------------------------------------------------------
    --------------------------------------   1.1.6其他科技型企业   -------------------------------------------
    ----------------------------------------------------------------------------------------------------------
    --累放户数
    INSERT INTO `S70_1.1.6.A.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE  ,--贷款余额/客户数/放款金额
       --COL_10 , --机构名称
       COL_14  ,-- 国家技术创新示范企业
       COL_15  -- 制造业单项冠军企业
       )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.1.6.A.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE ,
              -- I.INST_NAME  AS COL_10,
               CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
                    WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
               CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
                    WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  -- 制造业单项冠军企业
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN CBRC_S7001_ORG_FLAT F ---机构汇总按照层级
          ON F.SUB_ORG_CODE = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             or A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             )
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.6.A.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.2.3.C.2025
-- 存量贷款户数

     INSERT INTO `S70_1.2.3.C.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE -- ,--贷款余额/客户数/放款金额
       --COL_10  --机构名称
        )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.2.3.C.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE --,
               --I.INST_NAME  AS COL_10
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
          LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
      -- GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.2.3.C.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.2.A.2025
--[JLBA202507020013][20250729][石雨][于佳禾][新增科技相关产业 取数逻辑]
    --============================================1.2 科技相关产业 =========================================================

    --累放户数
    INSERT INTO `S70_1.2.A.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE -- ,--贷款余额/客户数/放款金额
       --COL_10  --机构名称

        )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.2.A.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE --,
               --I.INST_NAME  AS COL_10
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
        LEFT JOIN CBRC_S7001_ORG_FLAT F ---机构汇总按照层级
          ON F.SUB_ORG_CODE = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
         LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE =I_DATADATE
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.loan_stocken_date IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (nvl(t.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(t.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(t.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.2.A.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.2.G.2025
-- 不良贷款余额

    INSERT INTO `S70_1.2.G.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_19  ,--高技术制造业类型
       COL_20  ,--高技术服务业类型
       COL_21  ,--战略性新兴产业类型
       COL_22  --知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.G.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M1.M_NAME as COL_19  ,--高技术制造业类型
       M2.M_NAME as COL_20  ,--高技术服务业类型
       M3.M_NAME as COL_21  ,--战略性新兴产业类型
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID =A.CUST_ID
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON C.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON C.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  C.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类为次级、可疑、损失的贷款
         AND (nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.4.B.2025
-- 当年累计发放贷款额
    INSERT INTO `S70_1.1.4.B.2025`
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
      -- COL_10, --机构名称
       COL_11, --五级分类
       COL_23  --贷款产品名称
               )
              SELECT 
               I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD,-- 数据条线
               'CBRC' AS SYS_NAM, --模块简称
               'S70_1' AS REP_NUM, --报表编号
               --'S70_4..B.2024' AS ITEM_NUM,
               'S70_1.1.4.B.2025' AS ITEM_NUM,
               T1.ACCT_NUM AS COL_1, --合同号
               T.LOAN_NUM AS COL_2, --贷款编号
               T.CUST_ID AS COL_3, --客户号
               A.CUST_NAM AS COL_4, --客户名称
               T.Drawdown_Amt * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/客户数/放款金额
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
      -- I.INST_NAME AS COL_10,--机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
         T1.CP_NAME AS COL_23 --贷款产品名称
        FROM /* SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户

        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
         LEFT JOIN SMTMODS_L_ACCT_LOAN T1
                  ON T.LOAN_NUM = T1.LOAN_NUM
                 AND T1.DATA_DATE = I_DATADATE
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据,后续于佳禾问监管说专精特新大型企业也要报送，苏桐与吴大为和冯启航确认一表通与east也一起修改逻辑
            -- AND P.CUST_NAME IS NOT NULL --专精特新”中小企业
         AND A.IF_SPCLED_NEW_CUST = '1'
         AND A.CORP_SCALE IN ('B', 'M', 'S', 'T')
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.6.D.2025
-- 贷款余额

    INSERT INTO `S70_1.1.6.D.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_8, --企业规模
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_14  ,-- 国家技术创新示范企业
       COL_15  -- 制造业单项冠军企业
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.1.6.D.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.LOAN_ACCT_BAL * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       A.CORP_SCALE AS COL_8, --企业规模
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
            WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
       CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
            WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  -- 制造业单项冠军企业
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN CBRC_UPRR_U_BASE_INST I
          ON T.ORG_NUM = I.INST_ID
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND (A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             or A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.D.2025
-- 贷款余额

    INSERT INTO `S70_1.D.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_12  ,-- 高新技术
       COL_13  ,-- 科技型中小企业
       COL_14  ,-- 国家技术创新示范企业
       COL_15  ,-- 制造业单项冠军企业
       COL_16  ,-- 专精特新客户
       COL_17  ,-- 专精特新小巨人企业
       COL_18  ,-- 创新型企业
       COL_19  ,-- 高技术制造业类型
       COL_20  ,-- 高技术服务业类型
       COL_21  ,-- 战略性新兴产业类型
       COL_22  -- 知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.D.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       NVL(A.CUST_NAM,B.CUST_NAM) COL_4, --客户名称
       T.LOAN_ACCT_BAL * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
      CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
               CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
                    WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13  ,-- 科技型中小企业
               CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
                    WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
               CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
                    WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  ,-- 制造业单项冠军企业
               CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
                    WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
               CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
                    WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
               CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18,  -- 创新型企业
       M1.M_NAME as COL_19  ,--高技术制造业类型
       M2.M_NAME as COL_20  ,--高技术服务业类型
       M3.M_NAME as COL_21  ,--战略性新兴产业类型
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P B
           ON T.CUST_ID =B.CUST_ID
           AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON C.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON C.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  C.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or
             (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')) or
             nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.2.G.2025
-- 不良贷款余额

    INSERT INTO `S70_1.2.2.G.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_20  --高技术服务业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.2.G.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M2.M_NAME as COL_20  --高技术服务业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON c.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类为次级、可疑、损失的贷款
         AND nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.D.2025
-- 贷款余额

    INSERT INTO `S70_1.2.D.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_19  ,--高技术制造业类型
       COL_20  ,--高技术服务业类型
       COL_21  ,--战略性新兴产业类型
       COL_22  --知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.D.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M1.M_NAME as COL_19  ,--高技术制造业类型
       M2.M_NAME as COL_20  ,--高技术服务业类型
       M3.M_NAME as COL_21  ,--战略性新兴产业类型
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID =A.CUST_ID
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON C.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON C.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  C.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND (nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.4.D.2025
-- 贷款余额

    INSERT INTO `S70_1.2.4.D.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_22  --知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.4.D.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种\
         LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  C.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
         AND SUBSTR(T.ITEM_CD, 1, 6) not IN ('130102', '130105') --转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.3.D.2025
-- 贷款余额

    INSERT INTO `S70_1.2.3.D.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_21  --战略新兴产业
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.3.D.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M3.M_NAME as COL_21  --战略新兴产业
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.E.2025
-- 中长期贷款余额

    INSERT INTO `S70_1.1.E.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_8, --企业规模
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_12  ,-- 高新技术
       COL_13  ,-- 科技型中小企业
       COL_14  ,-- 国家技术创新示范企业
       COL_15  ,-- 制造业单项冠军企业
       COL_16  ,-- 专精特新客户
       COL_17  ,-- 专精特新小巨人企业
       COL_18  -- 创新型企业

       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.1.E.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.loan_acct_bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       A.CORP_SCALE AS COL_8, --企业规模
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
       CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
            WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13  ,-- 科技型中小企业
       CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
            WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
       CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
            WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  ,-- 制造业单项冠军企业
       CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
            WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
       CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
            WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
       CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18  -- 创新型企业
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --贷款借据信息表 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种

        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期界定范围
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or
             (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')))
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.3.G.2025
-- 不良贷款余额

    INSERT INTO `S70_1.2.3.G.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_21  --战略新兴产业
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.3.G.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
      -- I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M3.M_NAME as COL_21  --战略新兴产业
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类为次级、可疑、损失的贷款
         AND t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.1.D.2025
-- 贷款余额

    INSERT INTO `S70_1.2.1.D.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_19  --高技术制造业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.1.D.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M1.M_NAME as COL_19  --高技术制造业类型
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID =A.CUST_ID
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON C.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND (nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业

             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.1.A.2025
--高新技术企业 当年累放贷款户数

    INSERT INTO `S70_1.1.1.A.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE --贷款余额/客户数/放款金额
       )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE AS ORG_NUM,
               'CBRC' AS SYS_NAM, --模块简称
               'S70_1' AS REP_NUM, --报表编号
               --'S70_1_1..A.2022' AS ITEM_NUM,
               'S70_1.1.1.A.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,--客户号
               A.CUST_NAM AS COL_4,--客户名称
               '1' AS TOTAL_VALUE --贷款余额/客户数/放款金额
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
       WHERE A.IF_HIGH_SALA_CORP = 'Y' --Y 是高新技术企业
         AND t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.1.A.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.1.2.C.2025
--END --

    --科技型中小企业 存量贷款户数

INSERT INTO `S70_1.1.2.C.2025`
  (data_date, --数据日期
   org_num, --机构号
   sys_nam, --模块简称
   rep_num, --报表编号
   item_num, --指标号
   col_3, --客户号
   col_4, --客户名称
   TOTAL_VALUE--, --贷款余额/客户数/放款金额
   --COL_10 --机构名称
   )
  SELECT 
  DISTINCT I_DATADATE AS DATA_DATE,
           F.ORG_CODE,
           'CBRC' AS SYS_NAM, --模块简称
           'S70_1' AS REP_NUM, --报表编号
           --'S70_1_2..C.2022' AS ITEM_NUM,
           'S70_1.1.2.C.2025' AS ITEM_NUM,
           T.CUST_ID as col_3, --客户号
           a.cust_nam as col_4, --客户名称
           1 as TOTAL_VALUE--,--贷款余额/客户数/放款金额
          -- I.INST_NAME AS COL_10 --机构名称
    FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
   INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
      ON A.DATA_DATE = T.DATA_DATE
     AND A.CUST_ID = T.CUST_ID
     and a.CUST_TYP <> '3' --不等于个体工商户
    left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
      on f.sub_org_code = CASE
           WHEN T.ORG_NUM LIKE '%98%' THEN
            T.ORG_NUM
           WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
            '060300'
           ELSE
            SUBSTR(T.ORG_NUM, 1, 4) || '00'
         END
     /*LEFT JOIN CBRC_UPRR_U_BASE_INST I
         ON F.ORG_CODE =I.INST_ID*/
   WHERE T.DATA_DATE = I_DATADATE
     AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
     AND T.ACCT_STS <> '3'
     AND T.CANCEL_FLG <> 'Y'
     AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
     AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
        --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
        -- AND A.CORP_SCALE IN ('S', 'M', 'T')
        --  AND A.TECH_CORP_TYPE IN ('C01', 'C02') --C01 科技型企业-科创企业  C02 科技型企业-非科创企业
     AND A.IF_ST_SMAL_CORP = '1' --是否科技中小企业
     AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 转贴现
  --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.2.C.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.2.4.E.2025
-- 中长期贷款余额

    INSERT INTO `S70_1.2.4.E.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_22  --知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.4.E.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --贷款借据信息表 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  C.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期界定范围
         AND nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
         AND SUBSTR(T.ITEM_CD, 1, 6) not IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.B.2025
-- 当年累计发放贷款额

    /*INSERT INTO `S70_1.1.B.2025`
    (DATA_DATE, ORG_NUM, LOAN_ACCT_BAL, ITEM_NUM, FLAG)
    SELECT \*+ use_hash(T,A) parallel(4) *\
     I_DATADATE AS DATA_DATE,
     T.ORG_NUM,
     SUM(T.Drawdown_Amt * TT.CCY_RATE) AS LOAN_ACCT_BAL,
     'S70_1.1.B.2025' AS ITEM_NUM,
     '2' FLAG
      FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
     INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
        ON A.DATA_DATE = I_DATADATE
       AND A.CUST_ID = T.CUST_ID
       and a.CUST_TYP <> '3' --不等于个体工商户
    LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                   FROM SMTMODS_S7001_CUST_TEMP
                  where CUST_TYPE like '%创新型企业%'
                  GROUP BY TRIM(CUST_NAME)) P5
        ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
           replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')

      LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
        ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
       AND TT.BASIC_CCY = T.CURR_CD --基准币种
       AND TT.FORWARD_CCY = 'CNY' --折算币种
     WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
       and t.CANCEL_FLG <> 'Y'
       AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
           OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
           OR (A.IF_SPCLED_NEW_CUST = '1' AND A.CORP_SCALE IN ('B','S', 'M', 'T')) --专精特新”中小企业
           OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
           OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
           OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
           or (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')) )
     GROUP BY T.ORG_NUM;

*/
    INSERT INTO `S70_1.1.B.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_8, --企业规模
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_12  ,-- 高新技术
       COL_13  ,-- 科技型中小企业
       COL_14  ,-- 国家技术创新示范企业
       COL_15  ,-- 制造业单项冠军企业
       COL_16  ,-- 专精特新客户
       COL_17  ,-- 专精特新小巨人企业
       COL_18  -- 创新型企业

       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.1.B.2025' AS ITEM_NUM, --指标号
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.DRAWDOWN_AMT * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       A.CORP_SCALE AS COL_8, --企业规模
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
               CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
                    WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13  ,-- 科技型中小企业
               CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
                    WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
               CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
                    WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  ,-- 制造业单项冠军企业
               CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
                    WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
               CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
                    WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
               CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18  -- 创新型企业
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         AND A.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    WHERE CUST_TYPE LIKE '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON REPLACE(REPLACE(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             REPLACE(REPLACE(TRIM(A.CUST_NAM), '(', '（'), ')', '）')

        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM = T1.LOAN_NUM
         AND T1.DATA_DATE = I_DATADATE
       WHERE T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
         AND T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 4) || '0101' AND
             I_DATADATE
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             OR
             (P5.CUST_NAME IS NOT NULL AND A.CORP_SCALE IN ('S', 'M', 'T')));


-- 指标: S70_1.1.1.G.2025
--高新技术企业 不良贷款余额

    INSERT INTO `S70_1.1.1.G.2025`
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
       --'S70_1_1..G.2022' AS ITEM_NUM,
       'S70_1.1.1.G.2025' AS ITEM_NUM,
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
      -- I.INST_NAME AS COL_10,--机构名称
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
         AND T.LOAN_GRADE_CD IN ('3', '4', '5') --五级分类为次级、可疑、损失的贷款
         AND A.IF_HIGH_SALA_CORP = 'Y' --Y 是高新技术企业
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --剔除转贴现;


-- 指标: S70_1.1.3.H.2025
--当年累放贷款年化利息收益
    INSERT INTO `S70_1.1.3.H.2025`
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
      -- COL_10, --机构名称
       COL_11, --五级分类
       COL_23  --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       --'S70_2.J.2025' AS ITEM_NUM,
       'S70_1.1.3.H.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM AS COL_4, --客户名称
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/客户数/放款金额
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
      -- I.INST_NAME AS COL_10,--机构名称
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
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    WHERE CUST_TYPE LIKE '%创新型%'
                    GROUP BY TRIM(CUST_NAME)) P --各企业类型清单
          ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM =T1.LOAN_NUM
         AND T1.DATA_DATE = I_DATADATE
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND P.CUST_NAME IS NOT NULL --创新型
         AND A.CORP_SCALE IN ('M', 'S', 'T')
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.3.A.2025
------------------------------------1.2.3战略性新兴产业
    --累放户数
     INSERT INTO `S70_1.2.3.A.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE -- ,--贷款余额/客户数/放款金额
       --COL_10  --机构名称
        )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.2.3.A.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE --,
               --I.INST_NAME  AS COL_10
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表

        LEFT JOIN CBRC_S7001_ORG_FLAT F ---机构汇总按照层级
          ON F.SUB_ORG_CODE = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
         LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.loan_stocken_date IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.2.3.A.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.1.6.F.2025
-- 信用贷款余额

    INSERT INTO `S70_1.1.6.F.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_8, --企业规模
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_14  ,-- 国家技术创新示范企业
       COL_15  -- 制造业单项冠军企业
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.1.6.F.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.LOAN_ACCT_BAL * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       A.CORP_SCALE AS COL_8, --企业规模
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
            WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
       CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
            WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  -- 制造业单项冠军企业
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.GUARANTY_TYP = 'D' --信用贷款判断条件
         AND (A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             or A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.2.A.2025
-------------1.2.2高技术服务业

    --累放户数
     INSERT INTO `S70_1.2.2.A.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE -- ,--贷款余额/客户数/放款金额
       --COL_10  --机构名称
        )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.2.2.A.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE --,
               --I.INST_NAME  AS COL_10
        FROM CBRC_S70_LOAN_TEMP T --贷款借据信息表

        LEFT JOIN CBRC_S7001_ORG_FLAT F ---机构汇总按照层级
          ON F.SUB_ORG_CODE = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
         LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID =A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.loan_stocken_date IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND nvl(t.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.2.2.A.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.H.2025
--累放贷款年化利息收益

    INSERT INTO `S70_1.H.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_12  ,-- 高新技术
       COL_13  ,-- 科技型中小企业
       COL_14  ,-- 国家技术创新示范企业
       COL_15  ,-- 制造业单项冠军企业
       COL_16  ,-- 专精特新客户
       COL_17  ,-- 专精特新小巨人企业
       COL_18  ,-- 创新型企业
       COL_19  ,-- 高技术制造业类型
       COL_20  ,-- 高技术服务业类型
       COL_21  ,-- 战略性新兴产业类型
       COL_22  -- 知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.H.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       NVL(A.CUST_NAM,B.CUST_NAM) COL_4, --客户名称
       T.Nhsy * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
      CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
               CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
                    WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13  ,-- 科技型中小企业
               CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
                    WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
               CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
                    WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  ,-- 制造业单项冠军企业
               CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
                    WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
               CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
                    WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
               CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18,  -- 创新型企业
       M1.M_NAME as COL_19  ,--高技术制造业类型
       M2.M_NAME as COL_20  ,--高技术服务业类型
       M3.M_NAME as COL_21  ,--战略性新兴产业类型
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
        left JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
            ON T.LOAN_NUM =T1.LOAN_NUM
            AND T1.DATA_DATE =I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P B
           ON T.CUST_ID =B.CUST_ID
           AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON t.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON t.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  T.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or
             (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')) or
             nvl(t.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(t.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(t.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.4.C.2025
-- 存量贷款户数


     INSERT INTO `S70_1.2.4.C.2025`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_3, --客户号
       COL_4, --客户名称
       TOTAL_VALUE -- ,--贷款余额/客户数/放款金额
      -- COL_10  --机构名称
        )
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               F.ORG_CODE,
               'CBRC' AS SYS_NAM,
               'S70_1' AS REP_NUM,
               'S70_1.2.4.C.2025' AS ITEM_NUM,
               T.CUST_ID AS COL_3,
               A.CUST_NAM AS COL_4,
               1 AS TOTAL_VALUE-- ,
              -- I.INST_NAME  AS COL_10
        FROM SMTMODS_L_ACCT_LOAN T --贷款借据信息表
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
         LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
         AND SUBSTR(T.ITEM_CD, 1, 6) not IN ('130102', '130105') --转贴现
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.2.4.C.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.1.6.H.2025
--累放贷款年化利息收益

    INSERT INTO `S70_1.1.6.H.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_8, --企业规模
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_14  ,-- 国家技术创新示范企业
       COL_15  -- 制造业单项冠军企业
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.1.6.H.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.NHSY * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       A.CORP_SCALE AS COL_8, --企业规模
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
            WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
       CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
            WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  -- 制造业单项冠军企业
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
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
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             or A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             )
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.2.F.2025
--科技型中小企业 信用贷款余额

    INSERT INTO `S70_1.1.2.F.2025`
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
               --'S70_1_2..F.2022' AS ITEM_NUM,
               'S70_1.1.2.F.2025' AS ITEM_NUM,
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
      -- I.INST_NAME AS COL_10,--机构名称
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
      /*  LEFT JOIN CBRC_UPRR_U_BASE_INST I
           ON T.ORG_NUM =I.INST_ID*/
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND T.GUARANTY_TYP = 'D' --信用贷款判断条件
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            -- AND A.CORP_SCALE IN ('S', 'M', 'T')
            --  AND A.TECH_CORP_TYPE IN ('C01', 'C02') --C01 科技型企业-科创企业  C02 科技型企业-非科创企业
         AND A.IF_ST_SMAL_CORP = '1' --是否科技中小企业
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') -- 转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.2.H.2025
--累放贷款年化利息收益

    INSERT INTO `S70_1.2.2.H.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_20  --高技术服务业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.2.H.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Nhsy * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       M2.M_NAME as COL_20  --高技术服务业类型
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM =T1.LOAN_NUM
          AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON t.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND nvl(t.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.1.H.2025
--累放贷款年化利息收益

    INSERT INTO `S70_1.2.1.H.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_19  --高技术制造业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.1.H.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Nhsy * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       M1.M_NAME as COL_19  --高技术制造业类型
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_ACCT_LOAN T1
          ON T.LOAN_NUM =T1.LOAN_NUM
          AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.CUST_ID =A.CUST_ID
          AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON t.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (nvl(t.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业

             )
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1.2.2.E.2025
-- 中长期贷款余额

    INSERT INTO `S70_1.2.2.E.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_20  --高技术服务业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.2.2.E.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.Loan_Acct_Bal * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
       M2.M_NAME as COL_20  --高技术服务业类型
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --贷款借据信息表 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_CUST_ALL A
           ON T.CUST_ID =A.CUST_ID
           AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON c.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期界定范围
         AND nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
      -- GROUP BY T.ORG_NUM;


-- 指标: S70_1.1.6.B.2025
-- 当年累计发放贷款额

    INSERT INTO `S70_1.1.6.B.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_8, --企业规模
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_14  ,-- 国家技术创新示范企业
       COL_15  -- 制造业单项冠军企业
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.1.6.B.2025' AS ITEM_NUM,
       T1.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       A.CUST_NAM COL_4, --客户名称
       T.DRAWDOWN_AMT * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       A.CORP_SCALE AS COL_8, --企业规模
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T1.CP_NAME AS COL_23, --贷款产品名称
       CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
            WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
       CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
            WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  -- 制造业单项冠军企业
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
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             or A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             )
       --GROUP BY T.ORG_NUM;


-- 指标: S70_1_12..A.2022
--12. 科技特色支行 家数

    INSERT INTO `S70_1_12..A.2022`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE-- ,--贷款余额/客户数/放款金额
      -- COL_10 --机构名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       '013501' AS  ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1_12..A.2022' AS ITEM_NUM,
        '1' AS TOTAL_VALUE --,
        --'吉林银行长春科技支行'
        FROM SYSTEM.DUAL;


-- 指标: S70_1.1.5.A.2025
--5. 专精特新“小巨人”企业
    ---当年累放贷款户数

     INSERT INTO   `S70_1.1.5.A.2025`
           (DATA_DATE ,--数据日期
            ORG_NUM     ,--机构号
            SYS_NAM     ,--模块简称
            REP_NUM     ,--报表编号
            ITEM_NUM  ,--指标号
            COL_3     ,--客户号
            COL_4     ,--客户名称
            TOTAL_VALUE  --   ,--贷款余额/客户数/放款金额
           -- COL_10 --机构名称
          )
      SELECT 
       DISTINCT I_DATADATE AS DATA_DATE,
       F.ORG_CODE,
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       --'S70_5..A.2024' AS ITEM_NUM,
       'S70_1.1.5.A.2025' AS ITEM_NUM,
        T.CUST_ID AS COL_3     ,--客户号
        A.CUST_NAM  AS COL_4     ,--客户名称
         1   TOTAL_VALUE --,     --贷款余额/客户数/放款金额
        --I.INST_NAME
        FROM /*SMTMODS_L_ACCT_LOAN*/ CBRC_S70_LOAN_TEMP T --贷款借据信息表
       INNER JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = I_DATADATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
      /*LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                 FROM SMTMODS_S7001_CUST_TEMP
                WHERE CUST_TYPE LIKE '%专精特新小巨人%'
                GROUP BY TRIM(CUST_NAME)) P --专精特新企业名单\制造业单项冠军名单\2022年国家技术创新示范企业名单
      ON replace(replace(TRIM(P.CUST_NAME), '(', '（'), ')', '）') =
         replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')*/
        left join CBRC_S7001_ORG_FLAT f ---机构汇总按照层级
          on f.sub_org_code = CASE
               WHEN T.ORG_NUM LIKE '%98%' THEN
                T.ORG_NUM
               WHEN T.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
             END
       WHERE t.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         and t.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --需求编号：JLBA202503050026_关于在监管集市修改科技贷款相关字段取数逻辑的需求 上线日期：2025-04-29，修改人：石雨，提出人：苏桐   修改原因：“国家技术创新示范企业”“科技型中小企业名单”“制造业单项冠军企业”“专精特新小巨人”“高新技术企业”取NGI中标识为“是”，“专精特新中小企业”取NGI系统中标识为“专精特新”且企业规模为中型、小型、微型的企业数据
            --AND P.CUST_NAME IS NOT NULL --专精特新“小巨人”企业
         AND A.HUGE_SPCLED_NEW_CORP = '1'
       --GROUP BY F.ORG_CODE;

---将明细数据加工到val
    INSERT 
    INTO `S70_1.1.5.A.2025` 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG, --标志位
       IS_TOTAL --是否参与汇总： N 不参与汇总
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       t.SYS_NAM,
       t.REP_NUM,
       T.ITEM_NUM AS ITEM_NUM,
       SUM(t.TOTAL_VALUE) AS ITEM_VAL,
       '2' AS FLAG,
       CASE
         WHEN ITEM_NUM IN ('S70_1.1.1.A.2025',
                           'S70_1.1.1.C.2025',
                           'S70_1.1.2.A.2025',
                           'S70_1.1.2.C.2025',
                           'S70_1.1.3.A.2025',
                           'S70_1.1.3.C.2025',
                           'S70_1.1.4.A.2025',
                           'S70_1.1.4.C.2025',
                           'S70_1.1.5.A.2025',
                           'S70_1.1.5.C.2025',
                           'S70_1.1.6.A.2025',
                           'S70_1.1.6.C.2025',
                           'S70_1.1.A.2025',
                           'S70_1.1.C.2025',
                           'S70_1.A.2025',
                           'S70_1.C.2025',
                           'S70_1.2.A.2025',
                           'S70_1.2.C.2025',
                           'S70_1.2.1.A.2025',
                           'S70_1.2.1.C.2025',
                           'S70_1.2.2.A.2025',
                           'S70_1.2.2.C.2025',
                           'S70_1.2.3.A.2025',
                           'S70_1.2.3.C.2025',
                           'S70_1.2.4.A.2025',
                           'S70_1.2.4.C.2025') THEN --不参与汇总
          'N'
       END IS_TOTAL
        FROM CBRC_A_REPT_DWD_S70 T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ITEM_NUM, T.ORG_NUM, T.SYS_NAM, T.REP_NUM;


-- 指标: S70_1.E.2025
-- 中长期贷款余额

    INSERT INTO `S70_1.E.2025`
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
       TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       COL_6, --放款日期
       COL_7, --原始到期日
       COL_9, --科目号
       --COL_10, --机构名称
       COL_11, --五级分类
       COL_23,  --贷款产品名称
       COL_12  ,-- 高新技术
       COL_13  ,-- 科技型中小企业
       COL_14  ,-- 国家技术创新示范企业
       COL_15  ,-- 制造业单项冠军企业
       COL_16  ,-- 专精特新客户
       COL_17  ,-- 专精特新小巨人企业
       COL_18  ,-- 创新型企业
       COL_19  ,-- 高技术制造业类型
       COL_20  ,-- 高技术服务业类型
       COL_21  ,-- 战略性新兴产业类型
       COL_22  -- 知识产权密集型产业类型
      )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       T.ORG_NUM, --机构号
       T.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S70_1' AS REP_NUM, --报表编号
       'S70_1.E.2025' AS ITEM_NUM,
       T.ACCT_NUM AS COL_1, --合同号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.CUST_ID AS COL_3, --客户号
       NVL(A.CUST_NAM,B.CUST_NAM) COL_4, --客户名称
       T.LOAN_ACCT_BAL * TT.CCY_RATE TOTAL_VALUE, --贷款余额/贷款户数/放款金额
       T.DRAWDOWN_DT AS COL_6, --放款日期
       T.MATURITY_DT AS COL_7, --原始到期日
       T.ITEM_CD AS COL_9, --科目号
       --I.INST_NAME AS COL_10, --机构名称
       CASE WHEN T.LOAN_GRADE_CD='1' THEN '正常'
            WHEN T.LOAN_GRADE_CD='2' THEN '关注'
            WHEN T.LOAN_GRADE_CD='3' THEN '次级'
            WHEN T.LOAN_GRADE_CD='4' THEN '可疑'
            WHEN T.LOAN_GRADE_CD='5' THEN '损失'
         END  AS COL_11,--五级分类
       T.CP_NAME AS COL_23, --贷款产品名称
      CASE WHEN A.IF_HIGH_SALA_CORP = 'Y' THEN '是' ELSE '否' END AS COL_12  ,-- 高新技术
               CASE WHEN A.IF_ST_SMAL_CORP = '1' THEN '是'
                    WHEN A.IF_ST_SMAL_CORP = '0' THEN '否' END AS COL_13  ,-- 科技型中小企业
               CASE WHEN A.NAT_TECH_INVT_CORP = '1' THEN '是'
                    WHEN A.NAT_TECH_INVT_CORP = '0' THEN '否' END AS COL_14  ,-- 国家技术创新示范企业
               CASE WHEN A.MNFT_SIGL_FRST_CORP = '1' THEN '是'
                    WHEN A.MNFT_SIGL_FRST_CORP = '0' THEN '否'  END COL_15  ,-- 制造业单项冠军企业
               CASE WHEN A.IF_SPCLED_NEW_CUST = '1' THEN '是'
                    WHEN A.IF_SPCLED_NEW_CUST = '0' THEN '否'  END COL_16  ,-- 专精特新客户
               CASE WHEN A.HUGE_SPCLED_NEW_CORP = '1' THEN '是'
                    WHEN A.HUGE_SPCLED_NEW_CORP = '0' THEN '否'  END COL_17  ,-- 专精特新小巨人企业
               CASE WHEN P5.CUST_NAME IS NOT NULL THEN '是' ELSE '否' END  AS COL_18,  -- 创新型企业
       M1.M_NAME as COL_19  ,--高技术制造业类型
       M2.M_NAME as COL_20  ,--高技术服务业类型
       M3.M_NAME as COL_21  ,--战略性新兴产业类型
       M4.M_NAME as COL_22  --知识产权密集型产业类型
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --贷款借据信息表 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_CUST_C A --对公客户信息表
          ON A.DATA_DATE = T.DATA_DATE
         AND A.CUST_ID = T.CUST_ID
         and a.CUST_TYP <> '3' --不等于个体工商户
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = D_DATADATE_CCY --汇率日期
         AND TT.BASIC_CCY = T.CURR_CD --基准币种
         AND TT.FORWARD_CCY = 'CNY' --折算币种

        LEFT JOIN (SELECT TRIM(CUST_NAME) CUST_NAME
                     FROM SMTMODS_S7001_CUST_TEMP
                    where CUST_TYPE like '%创新型企业%'
                    GROUP BY TRIM(CUST_NAME)) P5
          ON replace(replace(TRIM(P5.CUST_NAME), '(', '（'), ')', '）') =
             replace(replace(TRIM(A.CUST_NAM), '(', '（'), ')', '）')
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P B
           ON T.CUST_ID =B.CUST_ID
           AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
             ON C.HIGH_TECH_MNFT =M1.M_CODE
             AND M1.M_TABLECODE ='HIGH_TECH_MNFT'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M2
             ON C.HIGH_TECH_SRVE =M2.M_CODE
             AND M2.M_TABLECODE ='HIGH_TECH_SRVE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M3
            ON  T.INDUST_STG_TYPE =M3.M_CODE
            AND M3.M_TABLECODE ='INDUST_STG_TYPE'
          LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M4
            ON  C.PANT_DENS_INDU =M4.M_CODE
            AND M4.M_TABLECODE ='PANT_DENS_INDU'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_STS <> '3'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
         AND T.LOAN_ACCT_BAL > 0 --贷款余额大于0
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期界定范围
         AND (A.IF_HIGH_SALA_CORP = 'Y' -- 高新技术企业
             OR A.IF_ST_SMAL_CORP = '1' --科技型中小企业
             OR (A.IF_SPCLED_NEW_CUST = '1' AND
             A.CORP_SCALE IN ('B', 'S', 'M', 'T')) --专精特新”中小企业
             OR A.HUGE_SPCLED_NEW_CORP = '1' --专精特新“小巨人”企业
             OR A.NAT_TECH_INVT_CORP = '1' --国家技术创新示范企业
             OR A.MNFT_SIGL_FRST_CORP = '1' --制造业单项冠军企业
             or
             (P5.CUST_NAME IS NOT NULL and A.CORP_SCALE IN ('S', 'M', 'T')) or
             nvl(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业
             or nvl(C.HIGH_TECH_SRVE, '0') <> '0' --高技术服务业
             or nvl(C.PANT_DENS_INDU, '0') <> '0' --知识产权（专利）密集型产业
             or t.INDUST_STG_TYPE in
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') -- 战略新兴类型
             )
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --转贴现
       ---GROUP BY T.ORG_NUM;


