-- ============================================================
-- 文件名: S63_I大中小微型企业贷款情况表_2.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: S63_I_9.2.F.2022
--9.2循环贷户数  个人经营性
    INSERT INTO `S63_I_9.2.F.2022`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_10 --  字段10（机构名称）
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'S63_I_9.2.F.2022' AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             T.cust_id AS COL_3, -- 字段3（客户号）
             A.CUST_NAM AS COL_4, -- 字段4（客户名称）
             1 AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
             null AS COL_10 --  字段10（机构名称）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_ALL A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
        
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND T.CANCEL_FLG <> 'Y'
         AND T.ACCT_STS <> '3'
         AND T.CIRCLE_LOAN_FLG = 'Y' -- 是否循环
         AND T.LOAN_ACCT_BAL <> 0
         AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM,T.cust_id,A.CUST_NAM,null;


-- 指标: S63_I_13.F.2024
--9.1贸易融资  个人经营性
     INSERT INTO `S63_I_13.F.2024`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT B.DATA_DATE, --数据日期
             B.ORG_NUM, --机构号
             'S63_I_13.F.2024' AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             B.ACCT_NUM AS COL_1, -- 字段1（合同号）
             B.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
             B.CUST_ID AS COL_3, -- 字段3（客户号）
             NVL(C.CUST_NAM,A.CUST_NAM) AS COL_4, -- 字段4（客户名称）
             (B.LOAN_ACCT_BAL * R.CCY_RATE)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       B.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       B.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       B.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       B.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN B.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN B.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN B.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN B.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN B.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       B.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
               WHEN A.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3' THEN --其中：个体工商户贷款
                'S63_I_13.G.2024'
               WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
                'S63_I_13.H.2024'
             END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ B -- 借据表
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON B.DATA_DATE = R.DATA_DATE
         AND B.CURR_CD = R.BASIC_CCY
         AND R.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P A
          ON B.DATA_DATE = A.DATA_DATE
         AND B.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C
          ON B.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = B.DATA_DATE
       WHERE B.DATA_DATE = I_DATADATE
         AND SUBSTR(B.ITEM_CD, 1, 4) = '1305' --贸易融资
         AND B.ACCT_TYP LIKE '0102%' --个人经营性
         AND B.ACCT_TYP <> '90'
         AND B.CANCEL_FLG = 'N'
         AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- 指标: S63_I_13.G.2024
--9.1贸易融资  个人经营性
     INSERT INTO `S63_I_13.G.2024`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12, --  字段12（业务条线）
       COL_18
       )
      SELECT B.DATA_DATE, --数据日期
             B.ORG_NUM, --机构号
             'S63_I_13.F.2024' AS ITEM_NUM,
             'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
             B.ACCT_NUM AS COL_1, -- 字段1（合同号）
             B.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
             B.CUST_ID AS COL_3, -- 字段3（客户号）
             NVL(C.CUST_NAM,A.CUST_NAM) AS COL_4, -- 字段4（客户名称）
             (B.LOAN_ACCT_BAL * R.CCY_RATE)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       B.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       B.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       B.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       B.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN B.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN B.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN B.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN B.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN B.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       B.DEPARTMENTD AS COL_12, --  字段12（业务条线）
       CASE
               WHEN A.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3' THEN --其中：个体工商户贷款
                'S63_I_13.G.2024'
               WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
                'S63_I_13.H.2024'
             END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ B -- 借据表
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON B.DATA_DATE = R.DATA_DATE
         AND B.CURR_CD = R.BASIC_CCY
         AND R.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P A
          ON B.DATA_DATE = A.DATA_DATE
         AND B.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C
          ON B.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = B.DATA_DATE
       WHERE B.DATA_DATE = I_DATADATE
         AND SUBSTR(B.ITEM_CD, 1, 4) = '1305' --贸易融资
         AND B.ACCT_TYP LIKE '0102%' --个人经营性
         AND B.ACCT_TYP <> '90'
         AND B.CANCEL_FLG = 'N'
         AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;

--9.1贸易融资 个体工商户、小微企业主
    INSERT INTO `S63_I_13.G.2024`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 --  字段12（业务条线）
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             CASE
               WHEN A.OPERATE_CUST_TYPE = 'A' OR B.CUST_TYP = '3' THEN --其中：个体工商户贷款
                'S63_I_13.G.2024'
               WHEN A.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
                'S63_I_13.H.2024'
             END AS ITEM_NUM,
       'CBRC' AS SYS_NAM,
       'S6301' AS REP_NUM,
       t.ACCT_NUM AS COL_1, -- 字段1（合同号）
       t.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       t.CUST_ID AS COL_3, -- 字段3（客户号）
       NVL(A.CUST_NAM,B.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (T.LOAN_ACCT_BAL * U.CCY_RATE)  AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       t.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       t.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       t.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       t.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN t.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN t.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN t.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN t.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN t.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
       A.DEPARTMENTD AS COL_12 --  字段12（业务条线）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T
        LEFT JOIN SMTMODS_L_CUST_P A
          ON T.DATA_DATE = A.DATA_DATE
         AND T.CUST_ID = A.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C B
          ON T.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = T.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND SUBSTR(T.ITEM_CD, 1, 4) = '1305' --贸易融资
         AND T.ACCT_TYP LIKE '0102%' --个人经营性
         AND (A.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款、小微企业主贷款
             OR B.CUST_TYP = '3')
         AND T.ACCT_TYP <> '90'
         AND T.CANCEL_FLG = 'N'
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让;


-- 指标: S63_I_11.F.2024
--11.战略性新兴产业贷款  个人经营性
     INSERT INTO `S63_I_11.F.2024`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       ITEM_NUM, -- ,-- 指标号
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       COL_1, -- 字段1（合同号）
       COL_2, -- 字段2（贷款编号）
       COL_3, -- 字段3（客户号）
       COL_4, -- 字段4（客户名称）
       COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       COL_6, -- 字段6,-- (放款日期)
       COL_7, -- 字段7（原始到期日）
       COL_9, -- 字段9（科目号）
       COL_10, --  字段10（机构名称）
       COL_22, --  字段22（贷款产品名称）
       COL_11, --  字段11（五级分类）
       COL_12 ,--  字段12（业务条线）
       COL_13 , --贷款投向
       COL_21,  --战略新兴类型
       COL_18
       )
      SELECT B.DATA_DATE, --数据日期
             B.ORG_NUM, --机构号
             'S63_I_11.F.2024' AS ITEM_NUM,
              'CBRC' AS SYS_NAM,
             'S6301' AS REP_NUM,
       B.ACCT_NUM AS COL_1, -- 字段1（合同号）
       B.LOAN_NUM AS COL_2, -- 字段2（贷款编号）
       B.CUST_ID AS COL_3, -- 字段3（客户号）
       nvl(P.CUST_NAM,C1.CUST_NAM) AS COL_4, -- 字段4（客户名称）
       (B.LOAN_ACCT_BAL * R.CCY_RATE) AS COL_5, -- 字段5（贷款余额/客户数/放款金额/收益）
       B.DRAWDOWN_DT AS COL_6, -- 字段6,-- (放款日期)
       B.MATURITY_DT AS COL_7, -- 字段7（原始到期日）
       B.ITEM_CD AS COL_9, -- 字段9（科目号）
       null AS COL_10, --  字段10（机构名称）
       B.CP_NAME AS COL_22, --  字段22（贷款产品名称）
       CASE
         WHEN B.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN B.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN B.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN B.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN B.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_11, --  字段11（五级分类）
        B.DEPARTMENTD AS COL_12, --  字段12（业务条线）
        B.LOAN_PURPOSE_CD , --贷款投向
        M1.M_NAME,
        CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' OR C1.CUST_TYP = '3' THEN --其中：个体工商户贷款
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN --其中：小微企业主贷款
                '小微企业主'
              WHEN P.OPERATE_CUST_TYPE = 'Z' THEN --其中：小微企业主贷款
                '其他个人'
             END
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ B -- 借据表
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON B.DATA_DATE = R.DATA_DATE
         AND B.CURR_CD = R.BASIC_CCY
         AND R.FORWARD_CCY = 'CNY'
       LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C
          ON  (B.LOAN_PURPOSE_CD = C.LOAN_PURPOSE_CD AND
             B.INDUST_STG_TYPE = C.COLUMN_OODE)     --贷款投向在相应G19投向表中
        
        LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C11
            ON (SUBSTR(B.LOAN_PURPOSE_CD, 1, 4) = C11.LOAN_PURPOSE_CD AND
             B.INDUST_STG_TYPE = C11.COLUMN_OODE)
        LEFT JOIN (SELECT LOAN_PURPOSE_CD,
                          DECODE(COLUMN_OODE,'C','1','D','2','E','3', 'F','4','G','5','H','6','I','7','J','8','K','9') AS COLUMN_OODE
                     FROM CBRC_INTO_FIELD_INDEX
                    WHERE COLUMN_OODE NOT IN ('B', 'L')
                      AND LOAN_PURPOSE_CD NOT IN ( 'C30' )--非金属矿物制品业【去掉,会取重复】
                      AND LOAN_PURPOSE_CD NOT IN ( 'Q841') --医院【去掉,会取重复】
                   ) C22
            ON   (SUBSTR(B.LOAN_PURPOSE_CD, 1, 3) = C22.LOAN_PURPOSE_CD AND
             B.INDUST_STG_TYPE = C22.COLUMN_OODE )  
         LEFT JOIN SMTMODS_L_CUST_P P
          ON B.DATA_DATE = P.DATA_DATE
         AND B.CUST_ID = P.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C1
          ON B.CUST_ID = C1.CUST_ID
         AND B.DATA_DATE = C1.DATA_DATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING M1
          ON M1.M_CODE =B.INDUST_STG_TYPE
          AND  M_TABLECODE ='INDUST_STG_TYPE'
       WHERE B.DATA_DATE = I_DATADATE
         AND B.INDUST_STG_TYPE IN
             ('1', '2', '3', '4', '5', '6', '7', '8', '9') --战略性新兴产业领域包含节能环保、新一代信息技术、生物、高端装备制造、新能源、新材料、新能源汽车、数字创意、相关服务九类
         AND B.ACCT_TYP LIKE '0102%' --个人经营性
         AND B.ACCT_TYP <> '90'
         AND B.CANCEL_FLG = 'N'
         AND SUBSTR(B.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --m14  不含转贴现
         AND B.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
          AND (C.LOAN_PURPOSE_CD IS NOT NULL OR C11.LOAN_PURPOSE_CD  IS NOT NULL  OR C22.LOAN_PURPOSE_CD  IS NOT NULL );


