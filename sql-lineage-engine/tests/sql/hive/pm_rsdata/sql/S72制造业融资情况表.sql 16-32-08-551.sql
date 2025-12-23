-- ============================================================
-- 文件名: S72制造业融资情况表.sql
-- 生成时间: 2025-12-18 13:53:41
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: S72_3.A
--制造业合计

    

      INSERT INTO `S72_3.A`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         --DATA_DEPARTMENT, --数据条线
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         TOTAL_VALUE, --汇总值
         COL_1 --客户编号
         )
        SELECT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               --T.DEPARTMENTD AS DATA_DEPARTMENT,
               'CBRC' AS SYS_NAM,
               V_REP_NUM AS REP_NUM,
               'S72_3.A' AS ITEM_NUM, --指标号
               '1' AS TOTAL_VALUE, --汇总值
               T.CUST_ID AS COL_1 --客户号
          FROM SMTMODS_L_ACCT_LOAN T
         WHERE T.DATA_DATE = I_DATADATE
           AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 0, 4)
              --AND T.LOAN_ACCT_BAL > 0  20210520 ZHOUJINGKUN  本年发放不应该判断余额是否大于0
           AND T.LOAN_PURPOSE_CD LIKE 'C%'
           AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
           AND FUND_USE_LOC_CD = 'I'
           AND (ACCT_TYP NOT LIKE '01%' OR ACCT_TYP LIKE '0102%')
           AND T.ACCT_TYP NOT LIKE '90%'
           AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
           AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
           AND T.CANCEL_FLG <> 'Y'
           AND T.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
         GROUP BY T.ORG_NUM, /*T.DEPARTMENTD,*/ T.CUST_ID;


-- 指标: S72_7..A
--制造业合计
    INSERT INTO `S72_7..A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'S72_7..A' AS ITEM_NUM,
             A.BALANCE * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             A.CUST_ID AS COL_1, --客户号
             A.ACCT_NUM AS COL_2, --账号
             A.ACCT_NO AS COL_3, --贷款合同编码
             A.BUSINESS_DT AS COL_4, --业务发生日期
             A.MATURITY_DT AS COL_5, --到期日期
             A.GL_ITEM_CODE AS COL_6 -- 科目号
        FROM SMTMODS_L_ACCT_OBS_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP = '111' --银行承兑汇票
         AND B.CUST_TYP LIKE '1%' --对公客户分类 企业
         AND B.CORP_BUSINSESS_TYPE LIKE 'C%';


-- ========== 逻辑组 2: 共 13 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             CASE
               WHEN C.HIGH_TECH_MNFT = 'C01' THEN --医药制造业
                CASE
                  WHEN T.GUARANTY_TYP LIKE 'D%' THEN
                   'S72_1.2.1.B1'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN
                   'S72_1.2.2.B1'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                   'S72_1.2.3.B1'
                  WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
                   'S72_1.2.4.B1'
                END
               WHEN C.HIGH_TECH_MNFT = 'C02' THEN --2.航空、航天器及设备制造业
                CASE
                  WHEN T.GUARANTY_TYP LIKE 'D%' THEN
                   'S72_1.2.1.B2'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN
                   'S72_1.2.2.B2'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                   'S72_1.2.3.B2'
                  WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
                   'S72_1.2.4.B2'
                END
               WHEN C.HIGH_TECH_MNFT = 'C03' THEN --3.电子及通信设备制造业
                CASE
                  WHEN T.GUARANTY_TYP LIKE 'D%' THEN
                   'S72_1.2.1.B3'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN
                   'S72_1.2.2.B3'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                   'S72_1.2.3.B3'
                  WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
                   'S72_1.2.4.B3'
                END
               WHEN C.HIGH_TECH_MNFT = 'C04' THEN --4.计算机及办公设备制造业
                CASE
                  WHEN T.GUARANTY_TYP LIKE 'D%' THEN
                   'S72_1.2.1.B4'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN
                   'S72_1.2.2.B4'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                   'S72_1.2.3.B4'
                  WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
                   'S72_1.2.4.B4'
                END
               WHEN C.HIGH_TECH_MNFT = 'C05' THEN --5.医疗仪器设备及仪器仪表制造业
                CASE
                  WHEN T.GUARANTY_TYP LIKE 'D%' THEN
                   'S72_1.2.1.B5'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN
                   'S72_1.2.2.B5'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                   'S72_1.2.3.B5'
                  WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
                   'S72_1.2.4.B5'
                END
               WHEN C.HIGH_TECH_MNFT = 'C06' THEN --6.信息化学品制造业
                CASE
                  WHEN T.GUARANTY_TYP LIKE 'D%' THEN
                   'S72_1.2.1.B6'
                  WHEN T.GUARANTY_TYP LIKE 'C%' THEN
                   'S72_1.2.2.B6'
                  WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN
                   'S72_1.2.3.B6'
                  WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
                   'S72_1.2.4.B6'
                END
               ELSE
                GUARANTY_TYP || 'GUARANTY_TYP'
             END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             T.LOAN_NUM AS COL_2, --贷款编号
             T.ACCT_NUM AS COL_3, --贷款合同编码
             T.DRAWDOWN_DT AS COL_4, --放款日期
             T.MATURITY_DT AS COL_5, --原始到期日
             T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
             T.ITEM_CD AS COL_7, -- 科目号
             T.CP_NAME AS COL_8, -- 产品名称
             CASE
               WHEN T.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN T.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN T.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN T.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN T.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN T.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN T.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN T.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN T.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN T.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_9 --担保方式
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
            
         AND NVL(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业  ALTER BY SHIYU 20241028
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND T.FUND_USE_LOC_CD = 'I'
         AND (T.ACCT_TYP NOT LIKE '01%' OR T.ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL
) q_2
INSERT INTO `S72_1.2.2.B1` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.1.B2` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.3.B1` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.2.B2` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.1.B4` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.2.B3` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.2.B5` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.1.B5` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.3.B3` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.3.B5` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.3.B2` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.1.B1` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.1.B3` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *;

-- ========== 逻辑组 3: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             CASE
               WHEN T.LOAN_GRADE_CD = 1 THEN
                'S72_1.1.1.A'
               WHEN T.LOAN_GRADE_CD = 2 THEN
                'S72_1.1.2.A'
               WHEN T.LOAN_GRADE_CD = 3 THEN
                'S72_1.1.3.A'
               WHEN T.LOAN_GRADE_CD = 4 THEN
                'S72_1.1.4.A'
               WHEN T.LOAN_GRADE_CD = 5 THEN
                'S72_1.1.5.A'
             END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             T.LOAN_NUM AS COL_2, --贷款编号
             T.ACCT_NUM AS COL_3, --贷款合同编码
             T.DRAWDOWN_DT AS COL_4, --放款日期
             T.MATURITY_DT AS COL_5, --原始到期日
             T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
             T.ITEM_CD AS COL_7, -- 科目号
             T.CP_NAME AS COL_8, -- 产品名称
             T.LOAN_GRADE_CD AS COL_9 --贷款五级分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = T.CURR_CD
         AND U.DATA_DATE = I_DATADATE
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
         AND T.LOAN_PURPOSE_CD LIKE 'C%'
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND FUND_USE_LOC_CD = 'I'
         AND (ACCT_TYP NOT LIKE '01%' OR ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.ITEM_CD NOT LIKE '130102%' --过滤以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL
) q_3
INSERT INTO `S72_1.1.1.A` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.3.A` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.2.A` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.5.A` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.4.A` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *;

-- ========== 逻辑组 4: 共 5 个指标 ==========
FROM (
SELECT
      
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD AS DATA_DEPARTMENT,
       'CBRC' AS SYS_NAM,
       V_REP_NUM AS REP_NUM,
       CASE

         WHEN ct.HIGH_TECH_MNFT = 'C01' THEN --医药制造业
          'S72_1.5.1.B1'
         WHEN ct.HIGH_TECH_MNFT = 'C02' THEN --2.航空、航天器及设备制造业
          'S72_1.5.1.B2'
         WHEN ct.HIGH_TECH_MNFT = 'C03' THEN --3.电子及通信设备制造业
          'S72_1.5.1.B3'
         WHEN ct.HIGH_TECH_MNFT = 'C04' THEN --4.计算机及办公设备制造业
          'S72_1.5.1.B4'
         WHEN ct.HIGH_TECH_MNFT = 'C05' THEN --5.医疗仪器设备及仪器仪表制造业
          'S72_1.5.1.B5'
         WHEN ct.HIGH_TECH_MNFT = 'C06' THEN --6.信息化学品制造业
          'S72_1.5.1.B6'
       END AS ITEM_NUM,
       T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
       T.CUST_ID AS COL_1, --客户号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.ACCT_NUM AS COL_3, --贷款合同编码
       T.DRAWDOWN_DT AS COL_4, --放款日期
       T.MATURITY_DT AS COL_5, --原始到期日
       T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
       T.ITEM_CD AS COL_7, -- 科目号
       T.CP_NAME AS COL_8, -- 产品名称
       C.CORP_SCALE AS COL_9, --企业规模
       CASE
         WHEN LCP.OPERATE_CUST_TYPE = 'A' THEN
          '个体工商户'
         WHEN LCP.OPERATE_CUST_TYPE = 'B' THEN
          '小微企业主'
         WHEN C.CUST_TYP = '3' THEN
          '个体工商户'
         ELSE
          '其他个人'
       END AS COL_10 --客户类别
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = T.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_P LCP
          ON T.CUST_ID = LCP.CUST_ID
         AND LCP.DATA_DATE = T.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = T.DATA_DATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT CT
          ON T.ACCT_NUM = CT.CONTRACT_NUM
         AND CT.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
            --AND A.CUST_TYPE LIKE '1%'  20210408  ZHOUJINGKUN  问题： 缺少小微企业主，个体工商户  解决方法：去掉客户大类 1% 判断对公户条件
         AND T.ACCT_TYP NOT IN ('B01', 'D01')
         AND (C.CORP_SCALE = 'S' --小型企业
             OR C.CORP_SCALE = 'T' --微型企业
             OR (T.ACCT_TYP LIKE '0102%' AND
             (LCP.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3')) --个体工商户
             OR (T.ACCT_TYP LIKE '0102%' AND LCP.OPERATE_CUST_TYPE = 'B') --小微企业主
             )
         AND T.ACCT_TYP NOT LIKE '90%' --20210519 ZHOUJINGKUN  添加排除委托贷款标识
         AND T.LOAN_PURPOSE_CD LIKE 'C%'
        
         AND NVL(CT.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业 --ALTER BY SHIYU 20241028
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL
) q_4
INSERT INTO `S72_1.5.1.B2` (DATA_DATE,  
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
       COL_8,
       COL_9,
       COL_10)
SELECT *
INSERT INTO `S72_1.5.1.B3` (DATA_DATE,  
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
       COL_8,
       COL_9,
       COL_10)
SELECT *
INSERT INTO `S72_1.5.1.B5` (DATA_DATE,  
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
       COL_8,
       COL_9,
       COL_10)
SELECT *
INSERT INTO `S72_1.5.1.B1` (DATA_DATE,  
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
       COL_8,
       COL_9,
       COL_10)
SELECT *
INSERT INTO `S72_1.5.1.B4` (DATA_DATE,  
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
       COL_8,
       COL_9,
       COL_10)
SELECT *;

-- ========== 逻辑组 5: 共 12 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             CASE
               WHEN 
                C.HIGH_TECH_MNFT = 'C01' THEN --医药制造业
                CASE
                  WHEN LOAN_GRADE_CD = 1 THEN
                   'S72_1.1.1.B1'
                  WHEN LOAN_GRADE_CD = 2 THEN
                   'S72_1.1.2.B1'
                  WHEN LOAN_GRADE_CD = 3 THEN
                   'S72_1.1.3.B1'
                  WHEN LOAN_GRADE_CD = 4 THEN
                   'S72_1.1.4.B1'
                  WHEN LOAN_GRADE_CD = 5 THEN
                   'S72_1.1.5.B1'
                END
               WHEN 
                C.HIGH_TECH_MNFT = 'C02' THEN --2.航空、航天器及设备制造业
                CASE
                  WHEN LOAN_GRADE_CD = 1 THEN
                   'S72_1.1.1.B2'
                  WHEN LOAN_GRADE_CD = 2 THEN
                   'S72_1.1.2.B2'
                  WHEN LOAN_GRADE_CD = 3 THEN
                   'S72_1.1.3.B2'
                  WHEN LOAN_GRADE_CD = 4 THEN
                   'S72_1.1.4.B2'
                  WHEN LOAN_GRADE_CD = 5 THEN
                   'S72_1.1.5.B2'
                END
               WHEN 
                C.HIGH_TECH_MNFT = 'C03' THEN --3.电子及通信设备制造业
                CASE
                  WHEN LOAN_GRADE_CD = 1 THEN
                   'S72_1.1.1.B3'
                  WHEN LOAN_GRADE_CD = 2 THEN
                   'S72_1.1.2.B3'
                  WHEN LOAN_GRADE_CD = 3 THEN
                   'S72_1.1.3.B3'
                  WHEN LOAN_GRADE_CD = 4 THEN
                   'S72_1.1.4.B3'
                  WHEN LOAN_GRADE_CD = 5 THEN
                   'S72_1.1.5.B3'
                END
               WHEN 
                C.HIGH_TECH_MNFT = 'C04' THEN --4.计算机及办公设备制造业
                CASE
                  WHEN LOAN_GRADE_CD = 1 THEN
                   'S72_1.1.1.B4'
                  WHEN LOAN_GRADE_CD = 2 THEN
                   'S72_1.1.2.B4'
                  WHEN LOAN_GRADE_CD = 3 THEN
                   'S72_1.1.3.B4'
                  WHEN LOAN_GRADE_CD = 4 THEN
                   'S72_1.1.4.B4'
                  WHEN LOAN_GRADE_CD = 5 THEN
                   'S72_1.1.5.B4'
                END
               WHEN 
                C.HIGH_TECH_MNFT = 'C05' THEN --5.医疗仪器设备及仪器仪表制造业
                CASE
                  WHEN LOAN_GRADE_CD = 1 THEN
                   'S72_1.1.1.B5'
                  WHEN LOAN_GRADE_CD = 2 THEN
                   'S72_1.1.2.B5'
                  WHEN LOAN_GRADE_CD = 3 THEN
                   'S72_1.1.3.B5'
                  WHEN LOAN_GRADE_CD = 4 THEN
                   'S72_1.1.4.B5'
                  WHEN LOAN_GRADE_CD = 5 THEN
                   'S72_1.1.5.B5'
                END
               WHEN 
                C.HIGH_TECH_MNFT = 'C06' THEN --6.信息化学品制造业
                CASE
                  WHEN LOAN_GRADE_CD = 1 THEN
                   'S72_1.1.1.B6'
                  WHEN LOAN_GRADE_CD = 2 THEN
                   'S72_1.1.2.B6'
                  WHEN LOAN_GRADE_CD = 3 THEN
                   'S72_1.1.3.B6'
                  WHEN LOAN_GRADE_CD = 4 THEN
                   'S72_1.1.4.B6'
                  WHEN LOAN_GRADE_CD = 5 THEN
                   'S72_1.1.5.B6'
                END
               ELSE
           
                C.HIGH_TECH_MNFT || 'loan_purpose_cd'
             END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             T.LOAN_NUM AS COL_2, --贷款编号
             T.ACCT_NUM AS COL_3, --贷款合同编码
             T.DRAWDOWN_DT AS COL_4, --放款日期
             T.MATURITY_DT AS COL_5, --原始到期日
             T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
             T.ITEM_CD AS COL_7, -- 科目号
             T.CP_NAME AS COL_8, -- 产品名称
             T.LOAN_GRADE_CD AS COL_9 --贷款五级分类
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --以公允价值计量变动计入权益的转贴现
            
         AND NVL(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业  --ALTER BY SHIYU 20241028
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND T.FUND_USE_LOC_CD = 'I'
         AND (T.ACCT_TYP NOT LIKE '01%' OR T.ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL
) q_5
INSERT INTO `S72_1.1.1.B3` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.1.B5` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.3.B3` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.1.B1` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.5.B1` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.5.B5` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.2.B3` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.2.B4` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.4.B1` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.1.B2` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.2.B1` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.1.4.B5` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *;

-- ========== 逻辑组 6: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             CASE
               WHEN C.HIGH_TECH_MNFT = 'C01' THEN --医药制造业
                'S72_1.4.1.B1'
               WHEN C.HIGH_TECH_MNFT = 'C02' THEN --2.航空、航天器及设备制造业
                'S72_1.4.1.B2'
               WHEN C.HIGH_TECH_MNFT = 'C03' THEN --3.电子及通信设备制造业
                'S72_1.4.1.B3'
               WHEN C.HIGH_TECH_MNFT = 'C04' THEN --4.计算机及办公设备制造业
                'S72_1.4.1.B4'
               WHEN C.HIGH_TECH_MNFT = 'C05' THEN --5.医疗仪器设备及仪器仪表制造业
                'S72_1.4.1.B5'
               WHEN C.HIGH_TECH_MNFT = 'C06' THEN --6.信息化学品制造业
                'S72_1.4.1.B6'
             END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             T.LOAN_NUM AS COL_2, --贷款编号
             T.ACCT_NUM AS COL_3, --贷款合同编码
             T.DRAWDOWN_DT AS COL_4, --放款日期
             T.MATURITY_DT AS COL_5, --原始到期日
             T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
             T.ITEM_CD AS COL_7, -- 科目号
             T.CP_NAME AS COL_8 -- 产品名称
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
            -- AND T.MATURITY_DT - T.DRAWDOWN_DT > 365
            ---M1注释
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12
            
         AND NVL(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业 --ALTER BY SHIYU 20241028
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND FUND_USE_LOC_CD = 'I'
         AND (T.ACCT_TYP NOT LIKE '01%' OR T.ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL
) q_6
INSERT INTO `S72_1.4.1.B1` (DATA_DATE,  
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
SELECT *
INSERT INTO `S72_1.4.1.B5` (DATA_DATE,  
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
SELECT *
INSERT INTO `S72_1.4.1.B3` (DATA_DATE,  
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
SELECT *
INSERT INTO `S72_1.4.1.B2` (DATA_DATE,  
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
SELECT *;

-- 指标: S72_1.3.1.1.A
INSERT INTO `S72_1.3.1.1.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'S72_1.3.1.1.A' AS ITEM_NUM,
             T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             T.LOAN_NUM AS COL_2, --贷款编号
             T.ACCT_NUM AS COL_3, --贷款合同编码
             T.DRAWDOWN_DT AS COL_4, --放款日期
             T.MATURITY_DT AS COL_5, --原始到期日
             T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
             T.ITEM_CD AS COL_7, -- 科目号
             T.CP_NAME AS COL_8, -- 产品名称
             T.OD_DAYS AS COL_9 -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
         AND T.OD_FLG = 'Y'
         AND T.LOAN_PURPOSE_CD LIKE 'C%'
         AND T.OD_DAYS > 60
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND FUND_USE_LOC_CD = 'I'
         AND (ACCT_TYP NOT LIKE '01%' OR ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S72_10..A
--制造业合计

    INSERT INTO `S72_10..A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'S72_10..A' AS ITEM_NUM,
             A.BALANCE * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             A.CUST_ID AS COL_1, --客户号
             A.ACCT_NUM AS COL_2, --账号
             A.ACCT_NO AS COL_3, --贷款合同编码
             A.BUSINESS_DT AS COL_4, --业务发生日期
             A.MATURITY_DT AS COL_5, --到期日期
             A.GL_ITEM_CODE AS COL_6 -- 科目号
        FROM SMTMODS_L_ACCT_OBS_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP IN ('531') --有条件撤销的贷款承诺
         AND B.CUST_TYP LIKE '1%' --对公客户分类 企业
         AND B.CORP_BUSINSESS_TYPE LIKE 'C%';


-- ========== 逻辑组 9: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             CASE

               WHEN C.HIGH_TECH_MNFT = 'C01' THEN --医药制造业
                'S72_1.3.1.B1'
               WHEN C.HIGH_TECH_MNFT = 'C02' THEN --2.航空、航天器及设备制造业
                'S72_1.3.1.B2'
               WHEN C.HIGH_TECH_MNFT = 'C03' THEN --3.电子及通信设备制造业
                'S72_1.3.1.B3'
               WHEN C.HIGH_TECH_MNFT = 'C04' THEN --4.计算机及办公设备制造业
                'S72_1.3.1.B4'
               WHEN C.HIGH_TECH_MNFT = 'C05' THEN --5.医疗仪器设备及仪器仪表制造业
                'S72_1.3.1.B5'
               WHEN C.HIGH_TECH_MNFT = 'C06' THEN --6.信息化学品制造业
                'S72_1.3.1.B6'
             END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             T.LOAN_NUM AS COL_2, --贷款编号
             T.ACCT_NUM AS COL_3, --贷款合同编码
             T.DRAWDOWN_DT AS COL_4, --放款日期
             T.MATURITY_DT AS COL_5, --原始到期日
             T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
             T.ITEM_CD AS COL_7, -- 科目号
             T.CP_NAME AS COL_8, -- 产品名称
             T.OD_DAYS AS COL_9 -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.OD_FLG = 'Y'
         AND NVL(C.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业 --ALTER BY 20241028
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND T.FUND_USE_LOC_CD = 'I'
         AND (T.ACCT_TYP NOT LIKE '01%' OR T.ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL
) q_9
INSERT INTO `S72_1.3.1.B1` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.3.1.B3` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.3.1.B5` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *;

-- 指标: S72_4.1.A
--制造业合计

    
      INSERT INTO `S72_4.1.A`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         DATA_DEPARTMENT, --数据条线
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         TOTAL_VALUE, --汇总值
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_5,
         COL_6,
         COL_7,
         COL_8)
        SELECT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD AS DATA_DEPARTMENT,
               'CBRC' AS SYS_NAM,
               V_REP_NUM AS REP_NUM,
               'S72_4.1.A' AS ITEM_NUM,
               T.DRAWDOWN_AMT * U.CCY_RATE AS TOTAL_VALUE, --汇总值
               T.CUST_ID AS COL_1, --客户号
               T.LOAN_NUM AS COL_2, --贷款编号
               T.ACCT_NUM AS COL_3, --贷款合同编码
               T.DRAWDOWN_DT AS COL_4, --放款日期
               T.MATURITY_DT AS COL_5, --原始到期日
               T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
               T.ITEM_CD AS COL_7, -- 科目号
               T.CP_NAME AS COL_8 -- 产品名称
          FROM SMTMODS_L_ACCT_LOAN T
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.DATA_DATE = I_DATADATE
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE T.DATA_DATE = I_DATADATE
           AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 0, 4)
              -- AND T.LOAN_ACCT_BAL > 0 20210520 ZHOUJINGKUN  本年发放不应该判断余额是否大于0
           AND T.LOAN_PURPOSE_CD LIKE 'C%'
           AND T.GUARANTY_TYP LIKE 'D%'
           AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
           AND FUND_USE_LOC_CD = 'I'
           AND (ACCT_TYP NOT LIKE '01%' OR ACCT_TYP LIKE '0102%')
           AND T.ACCT_TYP NOT LIKE '90%'
           AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
           AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
           AND T.CANCEL_FLG <> 'Y'
           AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S72_7..B
--高技术制造业合计

    INSERT INTO `S72_7..B`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'S72_7..B' AS ITEM_NUM,
             A.BALANCE * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             A.CUST_ID AS COL_1, --客户号
             A.ACCT_NUM AS COL_2, --账号
             A.ACCT_NO AS COL_3, --贷款合同编码
             A.BUSINESS_DT AS COL_4, --业务发生日期
             A.MATURITY_DT AS COL_5, --到期日期
             A.GL_ITEM_CODE AS COL_6 -- 科目号
        FROM SMTMODS_L_ACCT_OBS_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT CT
          ON A.ACCT_NUM = ct.contract_num
         and ct.data_date = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP = '111' --银行承兑汇票
         AND B.CUST_TYP LIKE '1%' --对公客户分类 企业
         AND B.CORP_BUSINSESS_TYPE IN ('C2710',
                                       'C2720',
                                       'C2730',
                                       'C2740',
                                       'C2750',
                                       'C2761',
                                       'C2762',
                                       'C2770',
                                       'C2780',
                                       'C3741',
                                       'C3742',
                                       'C3743',
                                       'C3744',
                                       'C3749',
                                       'C4343',
                                       'C3562',
                                       'C3563',
                                       'C3569',
                                       'C3832',
                                       'C3833',
                                       'C3841',
                                       'C3921',
                                       'C3922',
                                       'C3940',
                                       'C3931',
                                       'C3932',
                                       'C3933',
                                       'C3934',
                                       'C3939',
                                       'C3951',
                                       'C3952',
                                       'C3953',
                                       'C3971',
                                       'C3972',
                                       'C3973',
                                       'C3974',
                                       'C3975',
                                       'C3976',
                                       'C3979',
                                       'C3981',
                                       'C3982',
                                       'C3983',
                                       'C3984',
                                       'C3985',
                                       'C3989',
                                       'C3961',
                                       'C3962',
                                       'C3963',
                                       'C3969',
                                       'C3990',
                                       'C3911',
                                       'C3912',
                                       'C3913',
                                       'C3914',
                                       'C3915',
                                       'C3919',
                                       'C3474',
                                       'C3475',
                                       'C3581',
                                       'C3582',
                                       'C3583',
                                       'C3584',
                                       'C3585',
                                       'C3586',
                                       'C3589',
                                       'C4011',
                                       'C4012',
                                       'C4013',
                                       'C4014',
                                       'C4015',
                                       'C4016',
                                       'C4019',
                                       'C4021',
                                       'C4022',
                                       'C4023',
                                       'C4024',
                                       'C4025',
                                       'C4026',
                                       'C4027',
                                       'C4028',
                                       'C4029',
                                       'C4040',
                                       'C4090',
                                       'C2664',
                                       'C2665');


-- 指标: S72_4.1.B
--高技术制造业合计
    
      INSERT INTO `S72_4.1.B`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         DATA_DEPARTMENT, --数据条线
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         TOTAL_VALUE, --汇总值
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_5,
         COL_6,
         COL_7,
         COL_8)
        SELECT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD AS DATA_DEPARTMENT,
               'CBRC' AS SYS_NAM,
               V_REP_NUM AS REP_NUM,
               'S72_4.1.B' AS ITEM_NUM,
               T.DRAWDOWN_AMT * U.CCY_RATE AS TOTAL_VALUE, --汇总值
               T.CUST_ID AS COL_1, --客户号
               T.LOAN_NUM AS COL_2, --贷款编号
               T.ACCT_NUM AS COL_3, --贷款合同编码
               T.DRAWDOWN_DT AS COL_4, --放款日期
               T.MATURITY_DT AS COL_5, --原始到期日
               T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
               T.ITEM_CD AS COL_7, -- 科目号
               T.CP_NAME AS COL_8 -- 产品名称
          FROM SMTMODS_L_ACCT_LOAN T
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.DATA_DATE = I_DATADATE
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
          LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT CT
            ON T.ACCT_NUM = CT.CONTRACT_NUM
           AND CT.DATA_DATE = I_DATADATE
         WHERE T.DATA_DATE = I_DATADATE
           AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 0, 4)
              --  AND T.LOAN_ACCT_BAL > 0  20210520 ZHOUJINGKUN  本年发放不应该判断余额是否大于0
           AND T.GUARANTY_TYP LIKE 'D%'
              
           AND NVL(CT.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业 --ALTER BY SHIYU 20241028
           AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
           AND FUND_USE_LOC_CD = 'I'
           AND (T.ACCT_TYP NOT LIKE '01%' OR T.ACCT_TYP LIKE '0102%')
           AND T.ACCT_TYP NOT LIKE '90%'
           AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
           AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
           AND T.CANCEL_FLG <> 'Y'
           AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S72_8..A
--制造业合计

    INSERT INTO `S72_8..A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'S72_8..A' AS ITEM_NUM,
             A.BALANCE * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             A.CUST_ID AS COL_1, --客户号
             A.ACCT_NUM AS COL_2, --账号
             A.ACCT_NO AS COL_3, --贷款合同编码
             A.BUSINESS_DT AS COL_4, --业务发生日期
             A.MATURITY_DT AS COL_5, --到期日期
             A.GL_ITEM_CODE AS COL_6 -- 科目号
        FROM SMTMODS_L_ACCT_OBS_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP LIKE '31%' --信用证
         AND B.CUST_TYP LIKE '1%' --对公客户分类 企业
         AND B.CORP_BUSINSESS_TYPE LIKE 'C%';


-- ========== 逻辑组 14: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             CASE
               WHEN T.GUARANTY_TYP LIKE 'D%' THEN
                'S72_1.2.1.A'
               WHEN T.GUARANTY_TYP LIKE 'C%' THEN
                'S72_1.2.2.A'
               WHEN SUBSTR(T.GUARANTY_TYP, 1, 1) IN ('A', 'B') THEN --SHIYU 20210927 截取前一位为抵质押
                'S72_1.2.3.A'
               WHEN T.ACCT_TYP IN ('C01', '030101', '030102') THEN
                'S72_1.2.4.A'
             END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             T.LOAN_NUM AS COL_2, --贷款编号
             T.ACCT_NUM AS COL_3, --贷款合同编码
             T.DRAWDOWN_DT AS COL_4, --放款日期
             T.MATURITY_DT AS COL_5, --原始到期日
             T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
             T.ITEM_CD AS COL_7, -- 科目号
             T.CP_NAME AS COL_8, -- 产品名称
             CASE
               WHEN T.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN T.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN T.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN T.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN T.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN T.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN T.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN T.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN T.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN T.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_9 --担保方式
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
         AND T.LOAN_PURPOSE_CD LIKE 'C%'
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND FUND_USE_LOC_CD = 'I'
         AND (ACCT_TYP NOT LIKE '01%' OR ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.ITEM_CD NOT LIKE '130102%' -- 以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL
) q_14
INSERT INTO `S72_1.2.3.A` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.2.A` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.1.A` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *
INSERT INTO `S72_1.2.4.A` (DATA_DATE,  
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
       COL_8,
       COL_9)
SELECT *;

-- 指标: S72_4.A
--制造业合计

    
      INSERT INTO `S72_4.A`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         DATA_DEPARTMENT, --数据条线
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         TOTAL_VALUE, --汇总值
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_5,
         COL_6,
         COL_7,
         COL_8)
        SELECT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD AS DATA_DEPARTMENT,
               'CBRC' AS SYS_NAM,
               V_REP_NUM AS REP_NUM,
               'S72_4.A' AS ITEM_NUM,
               T.DRAWDOWN_AMT * U.CCY_RATE AS TOTAL_VALUE, --汇总值
               T.CUST_ID AS COL_1, --客户号
               T.LOAN_NUM AS COL_2, --贷款编号
               T.ACCT_NUM AS COL_3, --贷款合同编码
               T.DRAWDOWN_DT AS COL_4, --放款日期
               T.MATURITY_DT AS COL_5, --原始到期日
               T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
               T.ITEM_CD AS COL_7, -- 科目号
               T.CP_NAME AS COL_8 -- 产品名称
          FROM SMTMODS_L_ACCT_LOAN T
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.DATA_DATE = I_DATADATE
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE T.DATA_DATE = I_DATADATE
           AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 0, 4)
              -- AND T.LOAN_ACCT_BAL > 0  20210520 ZHOUJINGKUN  本年发放不应该判断余额是否大于0
           AND T.LOAN_PURPOSE_CD LIKE 'C%'
           AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
           AND FUND_USE_LOC_CD = 'I'
           AND (ACCT_TYP NOT LIKE '01%' OR ACCT_TYP LIKE '0102%')
           AND T.ACCT_TYP NOT LIKE '90%'
           AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
           AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
           AND T.CANCEL_FLG <> 'Y'
           AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S72_6.A
--制造业合计
    
      INSERT INTO `S72_6.A`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         DATA_DEPARTMENT, --数据条线
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         TOTAL_VALUE, --汇总值
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_5,
         COL_6,
         COL_7,
         COL_8,
         COL_9)
        SELECT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD AS DATA_DEPARTMENT,
               'CBRC' AS SYS_NAM,
               V_REP_NUM AS REP_NUM,
               'S72_6.A' AS ITEM_NUM,
               T.DRAWDOWN_AMT * U.CCY_RATE * REAL_INT_RAT / 100 AS TOTAL_VALUE, --汇总值
               T.CUST_ID AS COL_1, --客户号
               T.LOAN_NUM AS COL_2, --贷款编号
               T.ACCT_NUM AS COL_3, --贷款合同编码
               T.DRAWDOWN_DT AS COL_4, --放款日期
               T.MATURITY_DT AS COL_5, --原始到期日
               T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
               T.ITEM_CD AS COL_7, -- 科目号
               T.CP_NAME AS COL_8, -- 产品名称
               T.LOAN_GRADE_CD AS COL_9 --贷款五级分类
          FROM SMTMODS_L_ACCT_LOAN T
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.DATA_DATE = I_DATADATE
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE T.DATA_DATE = I_DATADATE
           AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 0, 4)
              -- AND T.LOAN_ACCT_BAL > 0 20210520 ZHOUJINGKUN  本年发放不应该判断余额是否大于0
           AND T.LOAN_PURPOSE_CD LIKE 'C%'
           AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
           AND FUND_USE_LOC_CD = 'I'
           AND (ACCT_TYP NOT LIKE '01%' OR ACCT_TYP LIKE '0102%')
           AND T.ACCT_TYP NOT LIKE '90%'
           AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
           AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
           AND T.CANCEL_FLG <> 'Y'
           AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S72_2.B
INSERT INTO `S72_2.B`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       --DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1 --客户编号
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             --T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'S72_2.B' AS ITEM_NUM, --指标号
             '1' AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1 --客户号
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = T.CURR_CD
         AND U.DATA_DATE = I_DATADATE
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT CT
          ON T.ACCT_NUM = CT.CONTRACT_NUM
         AND CT.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
         AND T.LOAN_PURPOSE_CD LIKE 'C%'
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND T.FUND_USE_LOC_CD = 'I'
         AND (T.ACCT_TYP NOT LIKE '01%' OR T.ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
         AND NVL(CT.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业 --ALTER BY SHIYU 20241028
            
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM, /*T.DEPARTMENTD,*/ T.CUST_ID;


-- 指标: S72_4.B
--高技术制造业合计

    
      INSERT INTO `S72_4.B`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         DATA_DEPARTMENT, --数据条线
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         TOTAL_VALUE, --汇总值
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_5,
         COL_6,
         COL_7,
         COL_8)
        SELECT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD AS DATA_DEPARTMENT,
               'CBRC' AS SYS_NAM,
               V_REP_NUM AS REP_NUM,
               'S72_4.B' AS ITEM_NUM,
               T.DRAWDOWN_AMT * U.CCY_RATE AS TOTAL_VALUE, --汇总值
               T.CUST_ID AS COL_1, --客户号
               T.LOAN_NUM AS COL_2, --贷款编号
               T.ACCT_NUM AS COL_3, --贷款合同编码
               T.DRAWDOWN_DT AS COL_4, --放款日期
               T.MATURITY_DT AS COL_5, --原始到期日
               T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
               T.ITEM_CD AS COL_7, -- 科目号
               T.CP_NAME AS COL_8 -- 产品名称
          FROM SMTMODS_L_ACCT_LOAN T
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.DATA_DATE = I_DATADATE
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
          LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT CT
            ON T.ACCT_NUM = CT.CONTRACT_NUM
           AND CT.DATA_DATE = I_DATADATE
         WHERE T.DATA_DATE = I_DATADATE
           AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 0, 4)
              --AND T.LOAN_ACCT_BAL > 0  20210520 ZHOUJINGKUN  本年发放不应该判断余额是否大于0
             
           AND NVL(CT.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业 --ALTER BY SHIYU 20241028
           AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
           AND FUND_USE_LOC_CD = 'I'
           AND (T.ACCT_TYP NOT LIKE '01%' OR T.ACCT_TYP LIKE '0102%')
           AND T.ACCT_TYP NOT LIKE '90%'
           AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
           AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
           AND T.CANCEL_FLG <> 'Y'
           AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S72_8..B
--高技术制造业合计

    INSERT INTO `S72_8..B`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'S72_8..B' AS ITEM_NUM,
             A.BALANCE * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             A.CUST_ID AS COL_1, --客户号
             A.ACCT_NUM AS COL_2, --账号
             A.ACCT_NO AS COL_3, --贷款合同编码
             A.BUSINESS_DT AS COL_4, --业务发生日期
             A.MATURITY_DT AS COL_5, --到期日期
             A.GL_ITEM_CODE AS COL_6 -- 科目号
        FROM SMTMODS_L_ACCT_OBS_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT CT
          ON A.ACCT_NUM = ct.contract_num
         and ct.data_date = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP LIKE '31%' --信用证
         AND B.CUST_TYP LIKE '1%' --对公客户分类 企业
            -- and NVL(CT.HIGH_TECH_MNFT,'0') <>'0'  --高技术制造业 --alter by shiyu 20241028
         AND B.CORP_BUSINSESS_TYPE IN ('C2710',
                                       'C2720',
                                       'C2730',
                                       'C2740',
                                       'C2750',
                                       'C2761',
                                       'C2762',
                                       'C2770',
                                       'C2780',
                                       'C3741',
                                       'C3742',
                                       'C3743',
                                       'C3744',
                                       'C3749',
                                       'C4343',
                                       'C3562',
                                       'C3563',
                                       'C3569',
                                       'C3832',
                                       'C3833',
                                       'C3841',
                                       'C3921',
                                       'C3922',
                                       'C3940',
                                       'C3931',
                                       'C3932',
                                       'C3933',
                                       'C3934',
                                       'C3939',
                                       'C3951',
                                       'C3952',
                                       'C3953',
                                       'C3971',
                                       'C3972',
                                       'C3973',
                                       'C3974',
                                       'C3975',
                                       'C3976',
                                       'C3979',
                                       'C3981',
                                       'C3982',
                                       'C3983',
                                       'C3984',
                                       'C3985',
                                       'C3989',
                                       'C3961',
                                       'C3962',
                                       'C3963',
                                       'C3969',
                                       'C3990',
                                       'C3911',
                                       'C3912',
                                       'C3913',
                                       'C3914',
                                       'C3915',
                                       'C3919',
                                       'C3474',
                                       'C3475',
                                       'C3581',
                                       'C3582',
                                       'C3583',
                                       'C3584',
                                       'C3585',
                                       'C3586',
                                       'C3589',
                                       'C4011',
                                       'C4012',
                                       'C4013',
                                       'C4014',
                                       'C4015',
                                       'C4016',
                                       'C4019',
                                       'C4021',
                                       'C4022',
                                       'C4023',
                                       'C4024',
                                       'C4025',
                                       'C4026',
                                       'C4027',
                                       'C4028',
                                       'C4029',
                                       'C4040',
                                       'C4090',
                                       'C2664',
                                       'C2665');


-- 指标: S72_1.5.1.A
--制造业合计
    INSERT INTO `S72_1.5.1.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10)
      SELECT
      
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       T.DEPARTMENTD AS DATA_DEPARTMENT,
       'CBRC' AS SYS_NAM,
       V_REP_NUM AS REP_NUM,
       'S72_1.5.1.A' AS ITEM_NUM,
       T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
       T.CUST_ID AS COL_1, --客户号
       T.LOAN_NUM AS COL_2, --贷款编号
       T.ACCT_NUM AS COL_3, --贷款合同编码
       T.DRAWDOWN_DT AS COL_4, --放款日期
       T.MATURITY_DT AS COL_5, --原始到期日
       T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
       T.ITEM_CD AS COL_7, -- 科目号
       T.CP_NAME AS COL_8, -- 产品名称
       C.CORP_SCALE AS COL_9, --企业规模
       CASE
         WHEN LCP.OPERATE_CUST_TYPE = 'A' THEN
          '个体工商户'
         WHEN LCP.OPERATE_CUST_TYPE = 'B' THEN
          '小微企业主'
         WHEN C.CUST_TYP = '3' THEN
          '个体工商户'
         ELSE
          '其他个人'
       END AS COL_10 --客户类别
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_CUST_C C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = T.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_P LCP
          ON T.CUST_ID = LCP.CUST_ID
         AND LCP.DATA_DATE = T.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = T.DATA_DATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
            -- AND A.CUST_TYPE LIKE '1%'   20210408  ZHOUJINGKUN  问题： 缺少小微企业主，个体工商户  解决方法：去掉客户大类 1% 判断对公户条件         AND T.ACCT_TYP NOT IN ('B01', 'D01')
         AND (C.CORP_SCALE = 'S' --小型企业
             OR C.CORP_SCALE = 'T' --微型企业
             OR (T.ACCT_TYP LIKE '0102%' AND
             (LCP.OPERATE_CUST_TYPE = 'A' OR C.CUST_TYP = '3')) --个体工商户
             OR (T.ACCT_TYP LIKE '0102%' AND LCP.OPERATE_CUST_TYPE = 'B') --小微企业主
             )
         AND T.ACCT_TYP NOT LIKE '90%' --20210519 ZHOUJINGKUN  添加排除委托贷款标识
         AND T.LOAN_PURPOSE_CD LIKE 'C%'
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S72_1.4.1.A
INSERT INTO `S72_1.4.1.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'S72_1.4.1.A' AS ITEM_NUM,
             T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             T.LOAN_NUM AS COL_2, --贷款编号
             T.ACCT_NUM AS COL_3, --贷款合同编码
             T.DRAWDOWN_DT AS COL_4, --放款日期
             T.MATURITY_DT AS COL_5, --原始到期日
             T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
             T.ITEM_CD AS COL_7, -- 科目号
             T.CP_NAME AS COL_8 -- 产品名称
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ T --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
         AND T.LOAN_PURPOSE_CD LIKE 'C%'
            --AND T.MATURITY_DT - T.DRAWDOWN_DT > 365
            ---M1注释
         AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND FUND_USE_LOC_CD = 'I'
         AND (ACCT_TYP NOT LIKE '01%' OR ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S72_1.3.1.2.B1
INSERT INTO `S72_1.3.1.2.B1`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9)
      select I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             CASE

               WHEN
                C.HIGH_TECH_MNFT = 'C01' THEN --医药制造业
                'S72_1.3.1.2.B1'
               WHEN 
                C.HIGH_TECH_MNFT = 'C02' THEN --2.航空、航天器及设备制造业
                'S72_1.3.1.2.B2'
               WHEN 
                C.HIGH_TECH_MNFT = 'C03' THEN --3.电子及通信设备制造业
                'S72_1.3.1.2.B3'
               WHEN 
                C.HIGH_TECH_MNFT = 'C04' THEN --4.计算机及办公设备制造业
                'S72_1.3.1.2.B4'
               WHEN 
                C.HIGH_TECH_MNFT = 'C05' THEN --5.医疗仪器设备及仪器仪表制造业
                'S72_1.3.1.2.B5'
               WHEN 
                C.HIGH_TECH_MNFT = 'C06' THEN --6.信息化学品制造业
                'S72_1.3.1.2.B6'
             END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             T.LOAN_NUM AS COL_2, --贷款编号
             T.ACCT_NUM AS COL_3, --贷款合同编码
             T.DRAWDOWN_DT AS COL_4, --放款日期
             T.MATURITY_DT AS COL_5, --原始到期日
             T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
             T.ITEM_CD AS COL_7, -- 科目号
             T.CP_NAME AS COL_8, -- 产品名称
             T.OD_DAYS AS COL_9 -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.OD_FLG = 'Y'
         AND T.LOAN_ACCT_BAL > 0
         AND T.OD_DAYS > 90
           
         AND NVL(C.HIGH_TECH_MNFT, '0') <> '0'
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND FUND_USE_LOC_CD = 'I'
         AND (T.ACCT_TYP NOT LIKE '01%' OR T.ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S72_2.A
--制造业合计
    INSERT INTO `S72_2.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       --DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1 --客户编号
       )
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             --T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'S72_2.A' AS ITEM_NUM, --指标号
             '1' AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1 --客户号
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.BASIC_CCY = T.CURR_CD
         AND U.DATA_DATE = I_DATADATE
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
         AND T.LOAN_PURPOSE_CD LIKE 'C%'
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND FUND_USE_LOC_CD = 'I'
         AND (ACCT_TYP NOT LIKE '01%' OR ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
       GROUP BY T.ORG_NUM, /*T.DEPARTMENTD,*/ T.CUST_ID;


-- 指标: S72_6.B
--高技术制造业合计
   
      INSERT INTO `S72_6.B`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         DATA_DEPARTMENT, --数据条线
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         TOTAL_VALUE, --汇总值
         COL_1,
         COL_2,
         COL_3,
         COL_4,
         COL_5,
         COL_6,
         COL_7,
         COL_8,
         COL_9)
        SELECT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               T.DEPARTMENTD AS DATA_DEPARTMENT,
               'CBRC' AS SYS_NAM,
               V_REP_NUM AS REP_NUM,
               'S72_6.B' AS ITEM_NUM,
               T.DRAWDOWN_AMT * U.CCY_RATE * REAL_INT_RAT / 100 AS TOTAL_VALUE, --汇总值
               T.CUST_ID AS COL_1, --客户号
               T.LOAN_NUM AS COL_2, --贷款编号
               T.ACCT_NUM AS COL_3, --贷款合同编码
               T.DRAWDOWN_DT AS COL_4, --放款日期
               T.MATURITY_DT AS COL_5, --原始到期日
               T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
               T.ITEM_CD AS COL_7, -- 科目号
               T.CP_NAME AS COL_8, -- 产品名称
               T.LOAN_GRADE_CD AS COL_9 --贷款五级分类
          FROM SMTMODS_L_ACCT_LOAN T
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON U.DATA_DATE = I_DATADATE
           AND U.BASIC_CCY = T.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
          LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT CT
            ON T.ACCT_NUM = CT.CONTRACT_NUM
           AND CT.DATA_DATE = I_DATADATE
         WHERE T.DATA_DATE = I_DATADATE
           AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 0, 4)
              --     AND T.LOAN_ACCT_BAL > 0 20210520 ZHOUJINGKUN  本年发放不应该判断余额是否大于0
              
           AND NVL(CT.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业 --ALTER BY SHIYU 20241028
           AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
           AND T.FUND_USE_LOC_CD = 'I'
           AND (T.ACCT_TYP NOT LIKE '01%' OR T.ACCT_TYP LIKE '0102%')
           AND T.ACCT_TYP NOT LIKE '90%'
           AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
           AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
           AND T.CANCEL_FLG <> 'Y'
           AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S72_9..A
--制造业合计
    INSERT INTO `S72_9..A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'S72_9..A' AS ITEM_NUM,
             A.BALANCE * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             A.CUST_ID AS COL_1, --客户号
             A.ACCT_NUM AS COL_2, --账号
             A.ACCT_NO AS COL_3, --贷款合同编码
             A.BUSINESS_DT AS COL_4, --业务发生日期
             A.MATURITY_DT AS COL_5, --到期日期
             A.GL_ITEM_CODE AS COL_6 -- 科目号
        FROM SMTMODS_L_ACCT_OBS_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP IN ('121', '211') --保函
         AND B.CUST_TYP LIKE '1%' --对公客户分类 企业
         AND B.CORP_BUSINSESS_TYPE LIKE 'C%';


-- 指标: S72_1.3.1.A
--制造业合计

    INSERT INTO `S72_1.3.1.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'S72_1.3.1.A' AS ITEM_NUM,
             T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             T.LOAN_NUM AS COL_2, --贷款编号
             T.ACCT_NUM AS COL_3, --贷款合同编码
             T.DRAWDOWN_DT AS COL_4, --放款日期
             T.MATURITY_DT AS COL_5, --原始到期日
             T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
             T.ITEM_CD AS COL_7, -- 科目号
             T.CP_NAME AS COL_8, -- 产品名称
             T.OD_DAYS AS COL_9 -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
         AND T.OD_FLG = 'Y'
         AND T.LOAN_PURPOSE_CD LIKE 'C%'
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND FUND_USE_LOC_CD = 'I'
         AND (ACCT_TYP NOT LIKE '01%' OR ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S72_1.3.1.2.A
INSERT INTO `S72_1.3.1.2.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'S72_1.3.1.2.A' AS ITEM_NUM,
             T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             T.LOAN_NUM AS COL_2, --贷款编号
             T.ACCT_NUM AS COL_3, --贷款合同编码
             T.DRAWDOWN_DT AS COL_4, --放款日期
             T.MATURITY_DT AS COL_5, --原始到期日
             T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
             T.ITEM_CD AS COL_7, -- 科目号
             T.CP_NAME AS COL_8, -- 产品名称
             T.OD_DAYS AS COL_9 -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.LOAN_ACCT_BAL > 0
         AND T.OD_FLG = 'Y'
         AND T.LOAN_PURPOSE_CD LIKE 'C%'
         AND T.OD_DAYS > 90
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND FUND_USE_LOC_CD = 'I'
         AND (ACCT_TYP NOT LIKE '01%' OR ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S72_9..B
--高技术制造业合计

    INSERT INTO `S72_9..B`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             A.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'S72_9..B' AS ITEM_NUM,
             A.BALANCE * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             A.CUST_ID AS COL_1, --客户号
             A.ACCT_NUM AS COL_2, --账号
             A.ACCT_NO AS COL_3, --贷款合同编码
             A.BUSINESS_DT AS COL_4, --业务发生日期
             A.MATURITY_DT AS COL_5, --到期日期
             A.GL_ITEM_CODE AS COL_6 -- 科目号
        FROM SMTMODS_L_ACCT_OBS_LOAN A
        LEFT JOIN SMTMODS_L_CUST_C B
          ON A.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT CT
          ON A.ACCT_NUM = ct.contract_num
         and ct.data_date = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP IN ('121', '211') --保函
         AND B.CUST_TYP LIKE '1%' --对公客户分类 企业
            -- and NVL(CT.HIGH_TECH_MNFT,'0') <>'0'  --高技术制造业 --alter by shiyu 20241028
         AND B.CORP_BUSINSESS_TYPE IN ('C2710',
                                       'C2720',
                                       'C2730',
                                       'C2740',
                                       'C2750',
                                       'C2761',
                                       'C2762',
                                       'C2770',
                                       'C2780',
                                       'C3741',
                                       'C3742',
                                       'C3743',
                                       'C3744',
                                       'C3749',
                                       'C4343',
                                       'C3562',
                                       'C3563',
                                       'C3569',
                                       'C3832',
                                       'C3833',
                                       'C3841',
                                       'C3921',
                                       'C3922',
                                       'C3940',
                                       'C3931',
                                       'C3932',
                                       'C3933',
                                       'C3934',
                                       'C3939',
                                       'C3951',
                                       'C3952',
                                       'C3953',
                                       'C3971',
                                       'C3972',
                                       'C3973',
                                       'C3974',
                                       'C3975',
                                       'C3976',
                                       'C3979',
                                       'C3981',
                                       'C3982',
                                       'C3983',
                                       'C3984',
                                       'C3985',
                                       'C3989',
                                       'C3961',
                                       'C3962',
                                       'C3963',
                                       'C3969',
                                       'C3990',
                                       'C3911',
                                       'C3912',
                                       'C3913',
                                       'C3914',
                                       'C3915',
                                       'C3919',
                                       'C3474',
                                       'C3475',
                                       'C3581',
                                       'C3582',
                                       'C3583',
                                       'C3584',
                                       'C3585',
                                       'C3586',
                                       'C3589',
                                       'C4011',
                                       'C4012',
                                       'C4013',
                                       'C4014',
                                       'C4015',
                                       'C4016',
                                       'C4019',
                                       'C4021',
                                       'C4022',
                                       'C4023',
                                       'C4024',
                                       'C4025',
                                       'C4026',
                                       'C4027',
                                       'C4028',
                                       'C4029',
                                       'C4040',
                                       'C4090',
                                       'C2664',
                                       'C2665');


-- 指标: S72_3.B
--高技术制造业合计

    
      INSERT INTO `S72_3.B`
        (DATA_DATE, --数据日期
         ORG_NUM, --机构号
         --DATA_DEPARTMENT, --数据条线
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         TOTAL_VALUE, --汇总值
         COL_1 --客户编号
         )
        SELECT I_DATADATE AS DATA_DATE,
               T.ORG_NUM AS ORG_NUM,
               --T.DEPARTMENTD AS DATA_DEPARTMENT,
               'CBRC' AS SYS_NAM,
               V_REP_NUM AS REP_NUM,
               'S72_3.B' AS ITEM_NUM, --指标号
               '1' AS TOTAL_VALUE, --汇总值
               T.CUST_ID AS COL_1 --客户号
          FROM SMTMODS_L_ACCT_LOAN T
          LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT CT
            ON T.ACCT_NUM = CT.CONTRACT_NUM
           AND CT.DATA_DATE = I_DATADATE
         WHERE T.DATA_DATE = I_DATADATE
           AND TO_CHAR(T.DRAWDOWN_DT, 'YYYY') = SUBSTR(I_DATADATE, 0, 4)
              -- AND T.LOAN_ACCT_BAL > 0     20210520 ZHOUJINGKUN  本年发放不应该判断余额是否大于0
              
           AND NVL(CT.HIGH_TECH_MNFT, '0') <> '0' --高技术制造业 --ALTER BY SHIYU 20241028
           AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
           AND FUND_USE_LOC_CD = 'I'
           AND (T.ACCT_TYP NOT LIKE '01%' OR T.ACCT_TYP LIKE '0102%')
           AND T.ACCT_TYP NOT LIKE '90%'
           AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
           AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
           AND T.CANCEL_FLG <> 'Y'
           AND T.LOAN_STOCKEN_DATE IS NULL --ADD BY HAORUI 20250311 JLBA202408200012 资产未转让
         GROUP BY T.ORG_NUM, /*T.DEPARTMENTD,*/ T.CUST_ID;


-- 指标: S72_1.3.1.1.B1
INSERT INTO `S72_1.3.1.1.B1`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       DATA_DEPARTMENT, --数据条线
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       TOTAL_VALUE, --汇总值
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       COL_5,
       COL_6,
       COL_7,
       COL_8,
       COL_9)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM AS ORG_NUM,
             T.DEPARTMENTD AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             CASE
               WHEN 
                C.HIGH_TECH_MNFT = 'C01' THEN --医药制造业
                'S72_1.3.1.1.B1'
               WHEN 
                C.HIGH_TECH_MNFT = 'C02' THEN --2.航空、航天器及设备制造业
                'S72_1.3.1.1.B2'
               WHEN
                C.HIGH_TECH_MNFT = 'C03' THEN --3.电子及通信设备制造业
                'S72_1.3.1.1.B3'
               WHEN 
                C.HIGH_TECH_MNFT = 'C04' THEN --4.计算机及办公设备制造业
                'S72_1.3.1.1.B4'
               WHEN 
                C.HIGH_TECH_MNFT = 'C05' THEN --5.医疗仪器设备及仪器仪表制造业
                'S72_1.3.1.1.B5'
               WHEN /* T.loan_purpose_cd IN ('C2664', 'C2665')*/
                C.HIGH_TECH_MNFT = 'C06' THEN --6.信息化学品制造业
                'S72_1.3.1.1.B6'
             END AS ITEM_NUM,
             T.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, --汇总值
             T.CUST_ID AS COL_1, --客户号
             T.LOAN_NUM AS COL_2, --贷款编号
             T.ACCT_NUM AS COL_3, --贷款合同编码
             T.DRAWDOWN_DT AS COL_4, --放款日期
             T.MATURITY_DT AS COL_5, --原始到期日
             T.LOAN_PURPOSE_CD AS COL_6, -- 贷款投向
             T.ITEM_CD AS COL_7, -- 科目号
             T.CP_NAME AS COL_8, -- 产品名称
             T.OD_DAYS AS COL_9 -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT C
          ON T.ACCT_NUM = C.CONTRACT_NUM
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.OD_FLG = 'Y'
         AND T.LOAN_ACCT_BAL > 0
         AND T.OD_DAYS > 60
            
         AND NVL(C.HIGH_TECH_MNFT, '0') <> '0'
         AND T.ACCT_TYP NOT IN ('C01', 'D01', 'E01', 'E02')
         AND FUND_USE_LOC_CD = 'I'
         AND (T.ACCT_TYP NOT LIKE '01%' OR T.ACCT_TYP LIKE '0102%')
         AND T.ACCT_TYP NOT LIKE '90%'
         AND T.ITEM_CD NOT LIKE '130102%' --以摊余成本计量的转贴现
         AND T.ITEM_CD NOT LIKE '130105%' --过滤以公允价值计量变动计入权益的转贴现
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL;


