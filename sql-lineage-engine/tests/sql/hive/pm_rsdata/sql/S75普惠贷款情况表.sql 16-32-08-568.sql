-- ============================================================
-- 文件名: S75普惠贷款情况表.sql
-- 生成时间: 2025-12-18 13:53:41
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       CASE
         WHEN C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A') THEN
          'S75_1.1.2.E'
         WHEN P.OPERATE_CUST_TYPE IN ('B') THEN
          'S75_1.1.3.E'
       END AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
          ON P.DATA_DATE = I_DATADATE
         AND T.CUST_ID = P.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户补充信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000))
) q_0
INSERT INTO `S75_1.1.2.E` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_10,  
       COL_12,  
       COL_14,  
       COL_15,  
       COL_16)
SELECT *
INSERT INTO `S75_1.1.3.E` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_10,  
       COL_12,  
       COL_14,  
       COL_15,  
       COL_16)
SELECT *;

-- ========== 逻辑组 1: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       CASE
         WHEN T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A') THEN
          'S75_1.1.2.A'
         WHEN T.OPERATE_CUST_TYPE IN ('B') THEN
          'S75_1.1.3.A'
       END AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000))
) q_1
INSERT INTO `S75_1.1.3.A` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_10,  
       COL_12,  
       COL_14,  
       COL_15,  
       COL_16)
SELECT *
INSERT INTO `S75_1.1.2.A` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_10,  
       COL_12,  
       COL_14,  
       COL_15,  
       COL_16)
SELECT *;

-- 指标: S75_1.2.E
-- 1.2创业担保贷款  累放收益

    INSERT INTO `S75_1.2.E`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.2.E' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.UNDERTAK_GUAR_TYPE IN ('A', 'B');


-- 指标: S75_1.2.D
-- 1.2创业担保贷款  累放金额

    INSERT INTO `S75_1.2.D`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.2.D' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.UNDERTAK_GUAR_TYPE IN ('A', 'B');


-- 指标: S75_1.1.1.A
--1.1.1单户授信小于1000万元的小微企业贷款  贷款余额
    INSERT INTO `S75_1.1.1.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.1.A' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0') OR
              T.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              T.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微

             );


-- 指标: S75_1.1.1.B
--1.1.1单户授信小于1000万元的小微企业贷款  贷款户数
    INSERT INTO `S75_1.1.1.B`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益
       )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               'S75' AS REP_NUM,
               'S75_1.1.1.B' AS ITEM_NUM,
               T.CUST_ID AS COL_2, --客户号
               C.CUST_NAM AS COL_3, --客户名
               '1' AS TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0') OR
              T.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              T.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微

             );


-- 指标: S75_1.1.1.E
-- 1.1.1单户授信小于1000万元的小微企业贷款 累放收益

    INSERT INTO `S75_1.1.1.E`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.1.E' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
          ON P.DATA_DATE = I_DATADATE
         AND T.CUST_ID = P.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户补充信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') OR
              C.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              C.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微

             );


-- 指标: S75_1.1.D
--1.1普惠重点领域贷款 累放金额

    INSERT INTO `S75_1.1.D`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.D' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
          ON P.DATA_DATE = I_DATADATE
         AND T.CUST_ID = P.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户补充信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') OR
              C.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              C.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(F.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')));


-- ========== 逻辑组 8: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       CASE
         WHEN T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A') THEN
          'S75_1.1.2.C'
         WHEN T.OPERATE_CUST_TYPE IN ('B') THEN
          'S75_1.1.3.C'
       END AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000))
         AND T.LOAN_GRADE_CD IN ('3', '4', '5')
) q_8
INSERT INTO `S75_1.1.3.C` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_10,  
       COL_12,  
       COL_14,  
       COL_15,  
       COL_16)
SELECT *
INSERT INTO `S75_1.1.2.C` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_10,  
       COL_12,  
       COL_14,  
       COL_15,  
       COL_16)
SELECT *;

-- 指标: S75_1.E
-- 1.普惠贷款 累放收益

    INSERT INTO `S75_1.E`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.E' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
          ON P.DATA_DATE = I_DATADATE
         AND T.CUST_ID = P.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户补充信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') OR
              C.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              C.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(F.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')) or
              t.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
             );


-- 指标: S75_1.1.4.B
--1.1.4单户授信小于500万元的农户经营性贷款 贷款户数

    INSERT INTO `S75_1.1.4.B`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益

       )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               'S75' AS REP_NUM,
               'S75_1.1.4.B' AS ITEM_NUM,
               T.CUST_ID AS COL_2, --客户号
               C.CUST_NAM AS COL_3, --客户名
               '1' AS TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
             AND T.FACILITY_AMT <= 5000000 AND
             SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103'));


-- 指标: S75_1.1.4.D
----1.1.4单户授信小于500万元的农户经营性贷款 累放金额

    INSERT INTO `S75_1.1.4.D`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.4.D' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE ( --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(F.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')));


-- 指标: S75_1.D
-- 1.普惠贷款 累放金额

    INSERT INTO `S75_1.D`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.D' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
          ON P.DATA_DATE = I_DATADATE
         AND T.CUST_ID = P.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户补充信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') OR
              C.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              C.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(F.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')) or
              t.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
             );


-- 指标: S75_1.1.B
--1.1普惠重点领域贷款  贷款户数

    INSERT INTO `S75_1.1.B`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益

       )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               'S75' AS REP_NUM,
               'S75_1.1.B' AS ITEM_NUM,
               T.CUST_ID AS COL_2, --客户号
               C.CUST_NAM AS COL_3, --客户名
               '1' AS TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益

        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0') OR
              T.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              T.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')));


-- 指标: S75_1.C
--1.普惠贷款 不良贷款

    INSERT INTO `S75_1.C`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.C' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_GRADE_CD IN ('3', '4', '5');


-- 指标: S75_1.1.E
-- --1.1普惠重点领域贷款 累放收益

    INSERT INTO `S75_1.1.E`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.E' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
          ON P.DATA_DATE = I_DATADATE
         AND T.CUST_ID = P.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户补充信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') OR
              C.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              C.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(F.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')));


-- 指标: S75_1.2.B
--1.2创业担保贷款贷款户数

    INSERT INTO `S75_1.2.B`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益
       )
      SELECT 
      distinct I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               'S75' AS REP_NUM,
               'S75_1.2.B' AS ITEM_NUM,
               T.CUST_ID AS COL_2, --客户号
               C.CUST_NAM AS COL_3, --客户名
               '1' AS TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益

        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B');


-- 指标: S75_1.1.1.D
-- 1.1.1单户授信小于1000万元的小微企业贷款 累放金额

    INSERT INTO `S75_1.1.1.D`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.1.D' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
          ON P.DATA_DATE = I_DATADATE
         AND T.CUST_ID = P.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户补充信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(C.CUST_TYP, 1, 1) IN ('1', '0') OR
              C.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              C.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微

             );


-- 指标: S75_1.1.1.C
--1.1.1单户授信小于1000万元的小微企业贷款  不良贷款
    INSERT INTO `S75_1.1.1.C`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.1.C' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0') OR
              T.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              T.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
             )
         AND T.LOAN_GRADE_CD IN ('3', '4', '5');


-- 指标: S75_1.1.C
--1.1普惠重点领域贷款  不良贷款

    INSERT INTO `S75_1.1.C`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.C' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0') OR
              T.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              T.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')))
         AND T.LOAN_GRADE_CD IN ('3', '4', '5');


-- 指标: S75_1.2.C
--1.2创业担保贷款  不良贷款

    INSERT INTO `S75_1.2.C`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.2.C' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
         AND T.LOAN_GRADE_CD IN ('3', '4', '5');


-- 指标: S75_1.1.4.C
--1.1.4单户授信小于500万元的农户经营性贷款  不良贷款

    INSERT INTO `S75_1.1.4.C`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.4.C' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
             AND T.FACILITY_AMT <= 5000000 AND
             SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103'))
         AND T.LOAN_GRADE_CD IN ('3', '4', '5');


-- ========== 逻辑组 22: 共 2 个指标 ==========
FROM (
SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               'S75' AS REP_NUM,
               CASE
                 WHEN T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A') THEN
                  'S75_1.1.2.B'
                 WHEN T.OPERATE_CUST_TYPE IN ('B') THEN
                  'S75_1.1.3.B'
               END AS ITEM_NUM,
               T.CUST_ID AS COL_2, --客户号
               C.CUST_NAM AS COL_3, --客户名
               '1' AS TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益

        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE

       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000))
) q_22
INSERT INTO `S75_1.1.2.B` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       TOTAL_VALUE)
SELECT *
INSERT INTO `S75_1.1.3.B` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       TOTAL_VALUE)
SELECT *;

-- 指标: S75_1.B
--1.普惠贷款 贷款户数

    INSERT INTO `S75_1.B`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益

       )
      SELECT 
      DISTINCT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               'S75' AS REP_NUM,
               'S75_1.B' AS ITEM_NUM,
               T.CUST_ID AS COL_2, --客户号
               C.CUST_NAM AS COL_3, --客户名
               '1' AS TOTAL_VALUE --贷款余额/贷款金额/客户数/贷款收益
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE;


-- 指标: S75_1.2.A
--1.2创业担保贷款 贷款余额

    INSERT INTO `S75_1.2.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.2.A' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B');


-- 指标: S75_1.1.4.A
--1.1.4单户授信小于500万元的农户经营性贷款 贷款余额

    INSERT INTO `S75_1.1.4.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.4.A' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
             AND T.FACILITY_AMT <= 5000000 AND
             SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103'));


-- 指标: S75_1.A
-----------------------------------------------------加工指标逻辑-----------------------------------------

    --1.普惠贷款 贷款余额

    INSERT INTO `S75_1.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.A' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE;


-- 指标: S75_1.1.4.E
----1.1.4单户授信小于500万元的农户经营性贷款 累放收益

    INSERT INTO `S75_1.1.4.E`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.4.E' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE ( --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(F.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103')));


-- ========== 逻辑组 28: 共 2 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       CASE
         WHEN C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A') THEN
          'S75_1.1.2.D'
         WHEN P.OPERATE_CUST_TYPE IN ('B') THEN
          'S75_1.1.3.D'
       END AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
          ON P.DATA_DATE = I_DATADATE
         AND T.CUST_ID = P.CUST_ID
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户补充信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
        LEFT JOIN CBRC_S75_SNDK_TEMP F
          ON F.DATA_DATE = I_DATADATE
         AND T.LOAN_NUM = F.LOAN_NUM
       WHERE ( --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000))
) q_28
INSERT INTO `S75_1.1.3.D` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_10,  
       COL_12,  
       COL_14,  
       COL_15,  
       COL_16)
SELECT *
INSERT INTO `S75_1.1.2.D` (DATA_DATE,  
       ORG_NUM,  
       DATA_DEPARTMENT,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       COL_2,  
       COL_3,  
       COL_4,  
       TOTAL_VALUE,  
       COL_6,  
       COL_7,  
       COL_8,  
       COL_10,  
       COL_12,  
       COL_14,  
       COL_15,  
       COL_16)
SELECT *;

-- 指标: S75_1.1.A
--1.1普惠重点领域贷款  贷款余额

    INSERT INTO `S75_1.1.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       COL_2, --客户号
       COL_3, --客户名
       COL_4, --贷款编号
       TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       COL_6, --贷款合同
       COL_7, --放款日期
       COL_8, --原始到期日
       COL_10, --企业规模
       COL_12, --五级分类
       COL_14, --贷款投向
       COL_15, --授信额度
       COL_16 --贷款产品名称
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD, --数据条线
       'CBRC' AS SYS_NAM,
       'S75' AS REP_NUM,
       'S75_1.1.A' AS ITEM_NUM,
       T.CUST_ID AS COL_2, --客户号
       C.CUST_NAM AS COL_3, --客户名
       T.LOAN_NUM AS COL_4, --贷款编号
       T.LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额/贷款金额/客户数/贷款收益
       A.ACCT_NUM AS COL_6, --贷款合同编号
       T.DRAWDOWN_DT AS COL_7, --放款日期
       T.MATURITY_DT AS COL_8, --原始到期日
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_10, --企业规模
       CASE
         WHEN A.LOAN_GRADE_CD = '1' THEN
          '正常'
         WHEN A.LOAN_GRADE_CD = '2' THEN
          '关注'
         WHEN A.LOAN_GRADE_CD = '3' THEN
          '次级'
         WHEN A.LOAN_GRADE_CD = '4' THEN
          '可疑'
         WHEN A.LOAN_GRADE_CD = '5' THEN
          '损失'
       END AS COL_12, --五级分类
       A.LOAN_PURPOSE_CD AS COL_14, --贷款投向
       T.FACILITY_AMT AS COL_15, --授信额度
       A.CP_NAME AS COL_16 --贷款产品名称
        FROM CBRC_S75_LOAN_BAL T
        LEFT JOIN SMTMODS_L_ACCT_LOAN A -- 借据表
          ON A.LOAN_NUM = T.LOAN_NUM
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND (
             --单户授信小于1000万元的小微企业贷款
              ((SUBSTR(T.CUST_TYP, 1, 1) IN ('1', '0') OR
              T.CUST_TYP LIKE '91%') AND --[JLBA202507020013][20250729][石雨][于佳禾][新增民办非企业]
              T.CORP_SCALE IN ('S', 'T') AND T.FACILITY_AMT <= 10000000) --小微
              OR --单户授信小于1000万元的个体工商户小微企业主
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND (T.CUST_TYP = '3' OR T.OPERATE_CUST_TYPE IN ('A', 'B')) AND
              T.FACILITY_AMT <= 10000000) or --单户授信小于500万元的农户经营性贷款
              ((T.ACCT_TYP LIKE '0102%' --个人经营性标识
              OR (SUBSTR(T.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
              AND T.ITEM_CD LIKE '1305%')) --个体工商户贸易融资
              AND T.FACILITY_AMT <= 5000000 AND
              SUBSTR(T.SNDKFL, 1, 5) IN ('P_101', 'P_102', 'P_103'))

             );


