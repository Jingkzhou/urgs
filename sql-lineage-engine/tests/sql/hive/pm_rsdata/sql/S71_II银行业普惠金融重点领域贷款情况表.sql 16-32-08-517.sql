-- ============================================================
-- 文件名: S71_II银行业普惠金融重点领域贷款情况表.sql
-- 生成时间: 2025-12-18 13:53:41
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: S7102_1.2.3.1.C.2024
--不良贷款

    INSERT INTO 
    `S7102_1.2.3.1.C.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.3.1.C.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         and TT.GUARANTY_TYP = 'D' --信用贷款
         AND TT.LOAN_GRADE_CD IN ('3', '4', '5');


-- 指标: S7102_2.2.C0
---新增-- 2.2其中：普惠型农民专业合作社贷款 不良贷款余额  --ADD BY zxy 20220217
    INSERT INTO 
    `S7102_2.2.C0` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.2.C0' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         AND LOAN_GRADE_CD IN ('3', '4', '5');


-- ========== 逻辑组 2: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.4.A3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.4.A2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.4.A1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /* V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /* V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         and a.guaranty_typ = 'D' --信用贷款
         AND A.LOAN_STOCKEN_DATE IS NULL
) q_2
INSERT INTO `S7102_1.1.4.A1.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.1.4.A3.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.1.4.A2.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- 指标: S7102_1.1.4.1.C2.2024
--不良贷款
    INSERT INTO 
    `S7102_1.1.4.1.C2.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.4.1.C3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.4.1.C2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.4.1.C1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             P.CUST_NAM AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_CUST_P P
          ON P.CUST_ID = A.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         and a.guaranty_typ = 'D' --信用贷款
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
         AND A.LOAN_STOCKEN_DATE IS NULL;


-- ========== 逻辑组 4: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.3.B3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.3.B2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.3.B1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /* V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.3.B3'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.3.B2'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.3.B1'
                END,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM
) q_4
INSERT INTO `S7102_1.3.B2` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.3.B1` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.3.B3` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *;

-- 指标: S7102_3.C.2025
INSERT INTO 
    `S7102_3.C.2025` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.C.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 10000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.LOAN_GRADE_CD IN ('3', '4', '5');


-- 指标: S7102_3.A.2025
----2025年新增制度指标
    --3.单户授信1000万元（含）以下的农户经营贷款
    INSERT INTO 
    `S7102_3.A.2025` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.A.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 10000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL;


-- ========== 逻辑组 7: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             ORG.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.4.C3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.4.C2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.4.C1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /* V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         and a.guaranty_typ = 'D' --信用贷款
         AND A.LOAN_STOCKEN_DATE IS NULL
) q_7
INSERT INTO `S7102_1.1.4.C3.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.1.4.C1.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.1.4.C2.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- 指标: S7102_2.B0
-------------新增-------------2其中：普惠型涉农小微企业法人贷款 贷款余额户数  --ADD BY zxy 20220217

    INSERT INTO 
    `S7102_2.B0` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.B0' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.DATA_DATE = I_DATADATE
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAME, TT.ORG_NAM;


-- ========== 逻辑组 9: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.3.A3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.3.A2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.3.A1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL
) q_9
INSERT INTO `S7102_1.3.A2` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.3.A3` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.3.A1` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- 指标: S7102_2.C4
-----新增----2.普惠型涉农小微企业法人贷款-----单户授信1000万元（含）以下不含票据融资合计（不良贷款余额）----add by zxy 20220221
    INSERT INTO 
    `S7102_2.C4` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.C4' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
         AND TT.ITEM_CD NOT LIKE '129%';


-- ========== 逻辑组 11: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN A.FACILITY_AMT > 1000000 THEN
                'S7102_1.F3'
               WHEN A.FACILITY_AMT > 100000 THEN
                'S7102_1.F2'
               WHEN A.FACILITY_AMT <= 100000 THEN
                'S7102_1.F1'
             END AS ITEM_NUM, --指标号
             A.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             A.CUST_NAM AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.NHSY AS TOTAL_VALUE, -- (年化收益)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             A.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             A.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             A.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             A.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             A.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 A
) q_11
INSERT INTO `S7102_1.F1` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.F3` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.F2` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- ========== 逻辑组 12: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE, --数据日期
       A.ORG_NUM, --机构号
       A.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S7102' AS REP_NUM, --报表编号
       CASE
         WHEN A.FACILITY_AMT > 1000000 THEN
          'S7102_1.D3'
         WHEN A.FACILITY_AMT > 100000 THEN
          'S7102_1.D2'
         WHEN A.FACILITY_AMT <= 100000 THEN
          'S7102_1.D1'
       END AS ITEM_NUM, --指标号
       A.ORG_NAM AS COL_1, --机构名
       A.CUST_ID AS COL_2, -- (客户号)
       A.CUST_NAM AS COL_3, -- (客户名)
       A.LOAN_NUM AS COL_4, -- (贷款编号)
       A.DRAWDOWN_AMT AS TOTAL_VALUE, -- (贷款余额)
       A.ACCT_NUM AS COL_6, -- (贷款合同编号)
       A.FACILITY_AMT AS COL_7, -- (授信额度)
       A.DRAWDOWN_DT AS COL_8, -- (放款日期)
       A.MATURITY_DT AS COL_9, -- (原始到期日)
       A.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
       A.CORP_SCALE AS COL_11, -- 字段11(企业规模)
       A.ITEM_CD AS COL_12, -- 字段12(科目号)
       A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
       A.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
       A.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
       --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
       A.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
       A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 A
) q_12
INSERT INTO `S7102_1.D2` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.D3` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.D1` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- 指标: S7102_2..A.2024
--不良贷款

    --2.粮食重点领域贷款( 粮食重点领域贷款+ 农田基本建设贷款)
    INSERT INTO 
    `S7102_2..A.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       --COL_7,
       COL_8,
       COL_9,
       --COL_10,
       --COL_11,
       COL_12,
       COL_13,
       --COL_14,
       COL_15,
       --COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2..A.2024' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.LOAN_ACCT_BAL * B.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             --T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             --T.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             --T.CORP_SCALE_NAM    AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD     AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             --T.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             '' AS COL_15, -- 字段15(涉农贷款分类)
             --T.GUARANTY_TYP_NAM  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY' --折人民币
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON T.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --贷款账户类型去除委托贷款
         AND T.ACCT_STS <> 3 --账户状态非注销
         AND T.CANCEL_FLG = 'N' --核销标识为否
         AND T.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND T.LOAN_ACCT_BAL <> 0
         AND LENGTH(T.ACCT_NUM) < 36
         AND (substr(T.LOAN_PURPOSE_CD, 1, 4) in
             ('A011', 'C131', 'C262', 'C263', 'C357') or
             substr(T.LOAN_PURPOSE_CD, 1, 5) in
             ('A0121',
               'A0123',
               'A0511',
               'A0512',
               'A0513',
               'C1391',
               'C1392',
               'C1431',
               'F5111',
               'F5112',
               'F5121',
               'F5221',
               'G5951'))
      UNION ALL
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2..A.2024' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             C.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.LOAN_ACCT_BAL * B.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             --T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             --T.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             --T.CORP_SCALE_NAM    AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD     AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             --T.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --T.GUARANTY_TYP_NAM  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F
          ON T.DATA_DATE = F.DATA_DATE
         AND T.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY' --折人民币
       INNER JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
         AND C.CUST_TYP <> '3'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON T.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --贷款账户类型去除委托贷款
         AND T.ACCT_STS <> 3 --账户状态非注销
         AND T.CANCEL_FLG = 'N' --核销标识为否
         AND SUBSTR(F.SNDKFL, 0, 7) in
             ('C_10201', 'C_20201', 'C_30201', 'C_40201')
         AND T.LOAN_STOCKEN_DATE IS NULL;


-- ========== 逻辑组 14: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.C3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.2.C2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.C1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)

        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /* V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND (P.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款
             OR C.CUST_TYP = '3')
         AND A.LOAN_STOCKEN_DATE IS NULL
) q_14
INSERT INTO `S7102_1.2.C2` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.2.C3` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.2.C1` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- ========== 逻辑组 15: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN A.FACILITY_AMT > 1000000 THEN
                'S7102_1.E3'
               WHEN A.FACILITY_AMT > 100000 THEN
                'S7102_1.E2'
               WHEN A.FACILITY_AMT <= 100000 THEN
                'S7102_1.E1'
             END AS ITEM_NUM, --指标号
             A.ORG_NAM AS COL_1, --字段1(机构名)
             A.CUST_ID AS COL_2, --字段2(客户号)
             A.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 A
       GROUP BY ORG_NUM,
                CASE
                  WHEN A.FACILITY_AMT > 1000000 THEN
                   'S7102_1.E3'
                  WHEN A.FACILITY_AMT > 100000 THEN
                   'S7102_1.E2'
                  WHEN A.FACILITY_AMT <= 100000 THEN
                   'S7102_1.E1'
                END,
                A.CUST_ID,
                A.CUST_NAM,
                A.ORG_NAM
) q_15
INSERT INTO `S7102_1.E1` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.E2` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.E3` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *;

-- ========== 逻辑组 16: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.3.C3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.3.C2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.3.C1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*     V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
) q_16
INSERT INTO `S7102_1.3.C2` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.3.C1` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- ========== 逻辑组 17: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.4.1.A3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.4.1.A2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.4.1.A1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             P.CUST_NAM AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_CUST_P P
          ON P.CUST_ID = A.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.GUARANTY_TYP = 'D' --信用贷款
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
         AND A.LOAN_STOCKEN_DATE IS NULL
) q_17
INSERT INTO `S7102_1.1.4.1.A1.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.1.4.1.A2.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.1.4.1.A3.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       COL_17,
       COL_18)
SELECT *;

-- 指标: S71_II_1.1.E.2018
----当年累放贷款户数 --ADD BY YHY 20211214

    INSERT INTO 
    `S71_II_1.1.E.2018` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S71_II_1.1.E.2018', --指标号
             T.ORG_NAM AS COL_1, --字段1(机构名)
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 T
        LEFT JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON T.LOAN_NUM = R.LOAN_NUM
         AND T.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE <> 'A01'
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
       GROUP BY T.ORG_NUM, T.CUST_ID, T.ORG_NAM, T.CUST_NAM;


-- 指标: S7102_1.1.4.1.E.2024
---当年累放户数

    INSERT INTO 
    `S7102_1.1.4.1.E.2024` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.4.1.E.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --字段1(机构名)
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
       WHERE T.GUARANTY_TYP = 'D' --信用贷款
       GROUP BY T.ORG_NUM, T.CUST_ID, T.CUST_NAM, T.ORG_NAM;


-- 指标: S71_II_1.1.F.2018
----当年累放贷款年化收益 --ADD BY YHY 20211214

    INSERT INTO 
    `S71_II_1.1.F.2018` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S71_II_1.1.F.2018', --指标号
             A.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             A.CUST_NAM AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.NHSY AS TOTAL_VALUE, -- (年化收益)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             A.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             A.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             A.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             A.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             A.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 A
        LEFT JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE <> 'A01'
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A';


-- 指标: S7102_1.1.4.1.D.2024
--当年累计放款金额

    INSERT INTO 
    `S7102_1.1.4.1.D.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.4.1.D.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.DRAWDOWN_AMT AS TOTAL_VALUE, -- (放款金额)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
       WHERE T.GUARANTY_TYP = 'D';


-- ========== 逻辑组 22: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S71_II_1.1.B3.2018'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S71_II_1.1.B2.2018'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S71_II_1.1.B1.2018'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             P.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                T.CUST_ID,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S71_II_1.1.B3.2018'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S71_II_1.1.B2.2018'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S71_II_1.1.B1.2018'
                END,
                ORG.ORG_NAM,
                P.CUST_NAM
) q_22
INSERT INTO `S71_II_1.1.B2.2018` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S71_II_1.1.B1.2018` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S71_II_1.1.B3.2018` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *;

-- 指标: S7102_1.2.4.C.2024
--不良贷款

    INSERT INTO 
    `S7102_1.2.4.C.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.4.C.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND MONTHS_BETWEEN(tt.MATURITY_DT, tt.DRAWDOWN_DT) > 12
         AND TT.LOAN_GRADE_CD IN ('3', '4', '5');


-- 指标: S7102_2.F0
---------新增----2普惠型涉农小微企业法人贷款  当年累放贷款年化利息收益  --ADD BY zxy 20220217

    INSERT INTO 
    `S7102_2.F0` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.F0' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.NHSY AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)

        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 10000000
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.CORP_SCALE IN ('S', 'T');


-- 指标: S7102_1.3.1.C1
-- 1.3.1 其中：扶贫小额信贷 不良贷款余额
    INSERT INTO 
    `S7102_1.3.1.C1` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.3.1.C3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.3.1.C2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.3.1.C1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /* V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*  V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND A.DRAWDOWN_AMT <= 50000 --放款金额小于50000
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) <= 36 --三年以内
         AND A.GUARANTY_TYP = 'D' --担保方式D  信用
         AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE;


-- 指标: S7102_1.1.5.F.2024
--当年累放贷款收益

    INSERT INTO 
    `S7102_1.1.5.F.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.5.F.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.NHSY AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       WHERE MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12;


-- ========== 逻辑组 27: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE, --数据日期
       A.ORG_NUM, --机构号
       A.DEPARTMENTD,--数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S7102' AS REP_NUM, --报表编号
       CASE
         WHEN T.FACILITY_AMT > 1000000 THEN
          'S7102_1.A3'
         WHEN T.FACILITY_AMT > 100000 THEN
          'S7102_1.A2'
         WHEN T.FACILITY_AMT <= 100000 THEN
          'S7102_1.A1'
       END AS ITEM_NUM, --指标号
       A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
       ORG.ORG_NAM AS COL_1, --机构名
       T.CUST_ID AS COL_2, -- (客户号)
       NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
       A.LOAN_NUM AS COL_4, -- (贷款编号)
       A.ACCT_NUM AS COL_6, -- (贷款合同编号)
       T.FACILITY_AMT AS COL_7, -- (授信额度)
       A.DRAWDOWN_DT AS COL_8, -- (放款日期)
       A.MATURITY_DT AS COL_9, -- (原始到期日)
       CASE
         WHEN P.OPERATE_CUST_TYPE = 'A' THEN
          '个体工商户'
         WHEN P.OPERATE_CUST_TYPE = 'B' THEN
          '小微企业主'
         WHEN C.CUST_TYP = '3' THEN
          '个体工商户'
         ELSE
          '其他个人'
       END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_11, -- 字段11(企业规模)
       A.ITEM_CD AS COL_12, -- 字段12(科目号)
       A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
       END AS COL_14, -- 字段14(五级分类)
       T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
       --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
       CASE
         WHEN A.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN A.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN A.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN A.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN A.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN A.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN A.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN A.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN A.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN A.GUARANTY_TYP = 'Z' THEN
          '其他'
       END AS COL_17, -- 字段17(贷款担保方式)
       A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL
) q_27
INSERT INTO `S7102_1.A2` (DATA_DATE,
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
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.A3` (DATA_DATE,
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
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.A1` (DATA_DATE,
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
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- 指标: S7102_1.2.E
--合计  1.2其中：普惠型农户个体工商户和农户小微企业主贷款 当年累放贷款户数
    INSERT INTO 
    `S7102_1.2.E` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.E', --指标号
             T.ORG_NAM AS COL_1, --字段1(机构名)
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 T
        LEFT JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE P.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款
          OR C.CUST_TYP = '3'
       GROUP BY T.ORG_NUM, T.CUST_ID, T.ORG_NAM, T.CUST_NAM;


-- ========== 逻辑组 29: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S71_II_1.1.C3.2018'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S71_II_1.1.C2.2018'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S71_II_1.1.C1.2018'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             P.CUST_NAM AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /* V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
         AND A.LOAN_STOCKEN_DATE IS NULL
) q_29
INSERT INTO `S71_II_1.1.C2.2018` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
        
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S71_II_1.1.C3.2018` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
        
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- 指标: S71_II_1.1.D.2018
----当年累放贷款额 --ADD BY YHY 20211214

    INSERT INTO 
    `S71_II_1.1.D.2018` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S71_II_1.1.D.2018' AS ITEM_NUM, --指标号
             A.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             A.CUST_NAM AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.DRAWDOWN_AMT AS TOTAL_VALUE, -- (年化收益)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             A.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             A.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             A.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             A.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             A.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 A
        LEFT JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE <> 'A01'
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A';


-- 指标: S7102_2.B4
-----新增----2.普惠型涉农小微企业法人贷款-----单户授信1000万元（含）以下不含票据融资合计（贷款余额户数）----add by zxy 20220221
    INSERT INTO 
    `S7102_2.B4` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.B4' AS ITEM_NUM,
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.DATA_DATE = I_DATADATE
         AND TT.ITEM_CD NOT LIKE '129%' --刨除票据
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAME, TT.ORG_NAM;


-- ========== 逻辑组 32: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S71_II_1.1.A3.2018'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S71_II_1.1.A2.2018'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S71_II_1.1.A1.2018'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*       V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND T.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
         AND A.LOAN_STOCKEN_DATE IS NULL
) q_32
INSERT INTO `S71_II_1.1.A1.2018` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S71_II_1.1.A2.2018` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S71_II_1.1.A3.2018` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- 指标: S7102_2.2.A0
-- 新增  2.2其中：普惠型农民专业合作社贷款--ADD BY zxy 20220217
    INSERT INTO 
    `S7102_2.2.A0` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.2.A0' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y';


-- 指标: S7102_1.2.4.A.2024
-- 1.2.4其中：中长期普惠型涉农小微企业法人贷款

    --贷款余额

    INSERT INTO 
    `S7102_1.2.4.A.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.4.A.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND MONTHS_BETWEEN(tt.MATURITY_DT, tt.DRAWDOWN_DT) > 12;


-- 指标: S7102_3.1.B.2025
---
    INSERT INTO 
    `S7102_3.1.B.2025` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.1.B.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = A.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = A.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 10000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B'))
       GROUP BY A.ORG_NUM,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;


-- ========== 逻辑组 36: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.5.A3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.5.A2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.5.A1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12
) q_36
INSERT INTO `S7102_1.1.5.A3.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.1.5.A2.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.1.5.A1.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- ========== 逻辑组 37: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.5.B3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.5.B2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.5.B1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12 --中长期贷款
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.1.5.B3.2024'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.1.5.B2.2024'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.1.5.B1.2024'
                END,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM
) q_37
INSERT INTO `S7102_1.1.5.B3.2024` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.1.5.B2.2024` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.1.5.B1.2024` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *;

-- 指标: S7102_1.2.3.C.2024
--不良贷款

    INSERT INTO 
    `S7102_1.2.3.C.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.3.C.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         and TT.GUARANTY_TYP = 'D' --信用贷款
         AND TT.LOAN_GRADE_CD IN ('3', '4', '5');


-- ========== 逻辑组 39: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.4.1.B3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.4.1.B2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.4.1.B1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             P.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM

       INNER JOIN SMTMODS_L_CUST_P P --alter by shiyu 20220224 农户贷款
          ON P.CUST_ID = A.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.GUARANTY_TYP = 'D' --信用贷款
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.1.4.1.B3.2024'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.1.4.1.B2.2024'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.1.4.1.B1.2024'
                END,
                T.CUST_ID,
                P.CUST_NAM,
                ORG.ORG_NAM
) q_39
INSERT INTO `S7102_1.1.4.1.B2.2024` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.1.4.1.B1.2024` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.1.4.1.B3.2024` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *;

-- ========== 逻辑组 40: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.4.B3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.4.B2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.4.B1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*   V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.GUARANTY_TYP = 'D' --信用贷款
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.1.4.B3.2024'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.1.4.B2.2024'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.1.4.B1.2024'
                END,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM
) q_40
INSERT INTO `S7102_1.1.4.B1.2024` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.1.4.B3.2024` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.1.4.B2.2024` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *;

-- ========== 逻辑组 41: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.A3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.2.A2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.A1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND (P.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款
             OR C.CUST_TYP = '3')
         AND A.LOAN_STOCKEN_DATE IS NULL
) q_41
INSERT INTO `S7102_1.2.A3` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.2.A1` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.2.A2` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- 指标: S7102_3.1.C.2025
----
    INSERT INTO 
    `S7102_3.1.C.2025` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.1.C.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = A.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = A.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 10000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B'))
         AND A.LOAN_GRADE_CD IN ('3', '4', '5');


-- ========== 逻辑组 43: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.B3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.B2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.B1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.B3'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.B2'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.B1'
                END,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM
) q_43
INSERT INTO `S7102_1.B2` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.B1` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.B3` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *;

-- 指标: S7102_1.3.1.A1
--1.3.1 其中：扶贫小额信贷 贷款余额
    INSERT INTO 
    `S7102_1.3.1.A1` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.3.1.A3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.3.1.A2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.3.1.A1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /*V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE

       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND A.DRAWDOWN_AMT <= 50000 --放款金额小于50000
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) <= 36 --三年以内
         AND A.GUARANTY_TYP = 'D' --担保方式D  信用
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE;


-- 指标: S7102_1.1.4.F.2024
--当年累放贷款收益

    INSERT INTO 
    `S7102_1.1.4.F.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.4.F.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.NHSY AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       WHERE T.GUARANTY_TYP = 'D';


-- 指标: S7102_2.A4
-----新增----2.普惠型涉农小微企业法人贷款-----单户授信1000万元（含）以下不含票据融资合计（贷款余额）----add by zxy 20220221
    INSERT INTO 
    `S7102_2.A4` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.A4' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.ITEM_CD NOT LIKE '129%';


-- 指标: S7102_2.F4
---------新增-------2.普惠型涉农小微企业法人贷款 单户授信1000万元（含）以下不含票据融资合计（当年累放贷款年化利息收益）--ADD BY zxy 20220221

    INSERT INTO 
    `S7102_2.F4` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             ORG.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.F4' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.NHSY AS TOTAL_VALUE, -- (年化收益)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND TT.FACILITY_AMT <= 10000000
         AND TT.CORP_SCALE IN ('S', 'T')
         AND ITEM_CD NOT LIKE '1301%' --刨除票据
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1');


-- 指标: S7102_3.1.D.2025
--累放金额
    INSERT INTO 
    `S7102_3.1.D.2025` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.1.D.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.DRAWDOWN_AMT * TT.CCY_RATE AS TOTAL_VALUE, -- (累放金额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2_TEMP A
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON C.CUST_ID = A.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       where A.FACILITY_AMT <= 10000000
         AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B'));


-- 指标: S7102_3.1.E.2025
--累放户数

    INSERT INTO 
    `S7102_3.1.E.2025` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.1.E.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             A.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2_TEMP A
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON C.CUST_ID = A.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       where A.FACILITY_AMT <= 10000000
         AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B'))
       GROUP BY A.ORG_NUM,
                A.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;


-- ========== 逻辑组 50: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.2.B3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.2.B2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.2.B1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /* V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND (P.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款
             OR C.CUST_TYP = '3')
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.2.B3'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.2.B2'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.2.B1'
                END,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM
) q_50
INSERT INTO `S7102_1.2.B2` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.2.B3` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *
INSERT INTO `S7102_1.2.B1` (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
SELECT *;

-- 指标: S7102_1.2.3.A.2024
--1.2.3其中：信用类普惠型涉农小微企业法人贷款

    --贷款余额

    INSERT INTO 
    `S7102_1.2.3.A.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.3.A.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         and TT.GUARANTY_TYP = 'D';


-- ========== 逻辑组 52: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE, --数据日期
       A.ORG_NUM, --机构号
       A.DEPARTMENTD,-- 数据条线
       'CBRC' AS SYS_NAM, --模块简称
       'S7102' AS REP_NUM, --报表编号
       CASE
         WHEN T.FACILITY_AMT > 1000000 THEN
          'S7102_1.C3'
         WHEN T.FACILITY_AMT > 100000 THEN
          'S7102_1.C2'
         WHEN T.FACILITY_AMT <= 100000 THEN
          'S7102_1.C1'
       END AS ITEM_NUM, --指标号
       ORG.ORG_NAM AS COL_1, --机构名
       T.CUST_ID AS COL_2, -- (客户号)
       NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
       A.LOAN_NUM AS COL_4, -- (贷款编号)
       A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
       A.ACCT_NUM AS COL_6, -- (贷款合同编号)
       T.FACILITY_AMT AS COL_7, -- (授信额度)
       A.DRAWDOWN_DT AS COL_8, -- (放款日期)
       A.MATURITY_DT AS COL_9, -- (原始到期日)
       CASE
         WHEN P.OPERATE_CUST_TYPE = 'A' THEN
          '个体工商户'
         WHEN P.OPERATE_CUST_TYPE = 'B' THEN
          '小微企业主'
         WHEN C.CUST_TYP = '3' THEN
          '个体工商户'
         ELSE
          '其他个人'
       END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
       CASE
         WHEN C.CORP_SCALE = 'B' THEN
          '大型'
         WHEN C.CORP_SCALE = 'M' THEN
          '中型'
         WHEN C.CORP_SCALE = 'S' THEN
          '小型'
         WHEN C.CORP_SCALE = 'T' THEN
          '微型'
       END AS COL_11, -- 字段11(企业规模)
       A.ITEM_CD AS COL_12, -- 字段12(科目号)
       A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
       END AS COL_14, -- 字段14(五级分类)
       T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
       --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
       CASE
         WHEN A.GUARANTY_TYP = 'A' THEN
          '质押贷款'
         WHEN A.GUARANTY_TYP = 'B' THEN
          '抵押贷款'
         WHEN A.GUARANTY_TYP = 'B01' THEN
          '房地产抵押贷款'
         WHEN A.GUARANTY_TYP = 'B99' THEN
          '其他抵押贷款'
         WHEN A.GUARANTY_TYP = 'C' THEN
          '保证贷款'
         WHEN A.GUARANTY_TYP = 'C01' THEN
          '联保贷款'
         WHEN A.GUARANTY_TYP = 'C99' THEN
          '其他保证贷款'
         WHEN A.GUARANTY_TYP = 'D' THEN
          '信用/免担保贷款'
         WHEN A.GUARANTY_TYP = 'E' THEN
          '组合担保'
         WHEN A.GUARANTY_TYP = 'Z' THEN
          '其他'
       END AS COL_17, -- 字段17(贷款担保方式)
       A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND A.CANCEL_FLG <> 'Y'
         AND LOAN_GRADE_CD IN ('3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL
) q_52
INSERT INTO `S7102_1.C1` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.C2` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.C3` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- ========== 逻辑组 53: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
             ORG.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.1.5.C3.2024'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.1.5.C2.2024'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.1.5.C1.2024'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款需求JLBA202412270003_一期
                   /* V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款需求JLBA202412270003_一期
                   /*   V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款
         AND T.FACILITY_AMT <= 5000000
         and A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12
) q_53
INSERT INTO `S7102_1.1.5.C2.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *
INSERT INTO `S7102_1.1.5.C3.2024` (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
        
       COL_17,
       COL_18)
SELECT *;

-- 指标: S7102_2.2.B0
---新增-- 2.2其中：普惠型农民专业合作社贷款  贷款余额户数  --ADD BY zxy 20220217
    INSERT INTO 
    `S7102_2.2.B0` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.2.B0' AS ITEM_NUM,
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         AND TT.DATA_DATE = I_DATADATE
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAME, TT.ORG_NAM;


-- 指标: S7102_1.1.5.D.2024
--当年累计放款金额

    INSERT INTO 
    `S7102_1.1.5.D.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.5.D.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.DRAWDOWN_AMT AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       WHERE MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12;


-- 指标: S7102_2.E0
-------------新增----------2普惠型涉农小微企业法人贷款  当年累放贷款户数  --ADD BY zxy 20220217

    INSERT INTO 
    `S7102_2.E0` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.E0' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN CBRC_S7102_TEMP1_LJ T --授信加工临时表
          ON T.CUST_ID = TT.CUST_ID
         AND T.DATA_DATE = I_DATADATE --取当月的授信金额
         AND T.FACILITY_AMT <= 10000000 --单户授信总额1000万元以下，含本数 属于普惠型
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       INNER JOIN --L_ACCT_LOAN_FARMING F --涉农贷款补充
      /* ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
      --20250327 修改内容：1104涉农贷款修改与大集中保持一致
       (SELECT t.LOAN_NUM, t.SNDKFL, t.IF_CT_UA, t.AGR_USE_ADDL
          FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
         WHERE T.DATA_DATE = I_DATADATE
           AND SUBSTR(T.SNDKFL, 1, 5) IN
               ('P_101', 'P_102', 'P_103', 'P_201')
        UNION ALL
        SELECT t.LOAN_NUM, t.SNDKFL, t.IF_CT_UA, t.AGR_USE_ADDL
          FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
         WHERE T.DATA_DATE = I_DATADATE
           AND SUBSTR(T.SNDKFL, 1, 5) IN
               ('P_101', 'P_102', 'P_103', 'P_201')
        UNION ALL
        SELECT A.LOAN_NUM, A.SNDKFL, A.IF_CT_UA, A.AGR_USE_ADDL
          FROM SMTMODS_V_PUB_IDX_DK_DGSNDK A --对公涉农
          LEFT JOIN SMTMODS_L_ACCT_LOAN B
            ON A.LOAN_NUM = B.LOAN_NUM
           AND A.DATA_DATE = B.DATA_DATE
         WHERE A.DATA_DATE = I_DATADATE
           AND (A.SNDKFL LIKE 'C_301%' OR SUBSTR(A.SNDKFL, 0, 5) = 'C_401' OR
               A.SNDKFL LIKE 'C_1%' or SUBSTR(A.SNDKFL, 0, 3) = 'C_2' OR
               ((A.SNDKFL LIKE 'C_402%' or A.SNDKFL LIKE 'C_302%') AND
               (CASE
                 WHEN SUBSTR(A.SNDKFL, 0, 7) IN ('C_40202', 'C_30202') AND
                      (NVL(A.AGR_USE_ADDL, '#') IN ('05') OR
                       NVL(B.LOAN_PURPOSE_CD, '#') IN ('A0514', 'A0523')) THEN
                  1
                 ELSE
                  0
               END) = 0))) F
          ON TT.LOAN_NUM = F.LOAN_NUM
       WHERE SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') --  企业规模中含事业单位、民办非企业贷款
         and NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000 --单户授信总额1000万元以下
         AND TT.FACILITY_AMT <= 10000000
         AND TT.CORP_SCALE IN ('S', 'T')
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAM, ORG.ORG_NAM;


-- 指标: S7102_2.C0
-------------新增----------------2.普惠型涉农小微企业法人贷款 不良贷款余额  --ADD BY zxy 20220217
    INSERT INTO 
    `S7102_2.C0` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.C0' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.LOAN_GRADE_CD IN ('3', '4', '5');


-- 指标: S7102_2.A0
----------新增------------2.普惠型涉农小微企业法人贷款 （单户授信1000万元（含）以下合计）  --ADD BY zxy 20220217

    --  2.普惠型涉农小微企业法人贷款 贷款余额
    INSERT INTO 
    `S7102_2.A0` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.A0' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0');


-- 指标: S7102_1.3.F
--合计 当年累放贷款年化收益

    INSERT INTO 
    `S7102_1.3.F` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.3.F', --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.NHSY AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON T.LOAN_NUM = R.LOAN_NUM
         AND T.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01';


-- 指标: S7102_3.D.2025
--累放金额
    INSERT INTO 
    `S7102_3.D.2025` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.D.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.DRAWDOWN_AMT AS TOTAL_VALUE, -- (累放金额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2_TEMP A
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = A.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
       where A.FACILITY_AMT <= 10000000;


-- 指标: S7102_2.E4
---------新增-------2.普惠型涉农小微企业法人贷款 单户授信1000万元（含）以下不含票据融资合计（当年累放贷款额）  --ADD BY zxy 20220221

    INSERT INTO 
    `S7102_2.E4` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.E4' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN CBRC_S7102_TEMP1_LJ T --授信加工临时表
          ON T.CUST_ID = TT.CUST_ID
         AND T.DATA_DATE = I_DATADATE --取当月的授信金额
         AND T.FACILITY_AMT <= 10000000 --单户授信总额1000万元以下，含本数 属于普惠型
         AND ITEM_CD NOT LIKE '1301%' --刨除票据
       INNER JOIN -- L_ACCT_LOAN_FARMING F --涉农贷款补充
      /*ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
      --20250327 修改内容：1104涉农贷款修改与大集中保持一致
       (SELECT t.LOAN_NUM, t.SNDKFL, t.IF_CT_UA, t.AGR_USE_ADDL
          FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
         WHERE T.DATA_DATE = I_DATADATE
           AND SUBSTR(T.SNDKFL, 1, 5) IN
               ('P_101', 'P_102', 'P_103', 'P_201')
        UNION ALL
        SELECT t.LOAN_NUM, t.SNDKFL, t.IF_CT_UA, t.AGR_USE_ADDL
          FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
         WHERE T.DATA_DATE = I_DATADATE
           AND SUBSTR(T.SNDKFL, 1, 5) IN
               ('P_101', 'P_102', 'P_103', 'P_201')
        UNION ALL
        SELECT A.LOAN_NUM, A.SNDKFL, A.IF_CT_UA, A.AGR_USE_ADDL
          FROM SMTMODS_V_PUB_IDX_DK_DGSNDK A --对公涉农
          LEFT JOIN SMTMODS_L_ACCT_LOAN B
            ON A.LOAN_NUM = B.LOAN_NUM
           AND A.DATA_DATE = B.DATA_DATE
         WHERE A.DATA_DATE = I_DATADATE
           AND (A.SNDKFL LIKE 'C_301%' OR SUBSTR(A.SNDKFL, 0, 5) = 'C_401' OR
               A.SNDKFL LIKE 'C_1%' or SUBSTR(A.SNDKFL, 0, 3) = 'C_2' OR
               ((A.SNDKFL LIKE 'C_402%' or A.SNDKFL LIKE 'C_302%') AND
               (CASE
                 WHEN SUBSTR(A.SNDKFL, 0, 7) IN ('C_40202', 'C_30202') AND
                      (NVL(A.AGR_USE_ADDL, '#') IN ('05') OR
                       NVL(B.LOAN_PURPOSE_CD, '#') IN ('A0514', 'A0523')) THEN
                  1
                 ELSE
                  0
               END) = 0))) F
          ON TT.LOAN_NUM = F.LOAN_NUM
       WHERE SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') --  企业规模中含事业单位、民办非企业贷款
         and NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000 --单户授信总额1000万元以下
         AND TT.FACILITY_AMT <= 10000000
         AND TT.CORP_SCALE IN ('S', 'T')
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAM, ORG.ORG_NAM;


-- 指标: S7102_2.1.A.2024
--2.1农田基本建设贷款

    INSERT INTO 
    `S7102_2.1.A.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       --COL_7,
       COL_8,
       COL_9,
       --COL_10,
       --COL_11,
       COL_12,
       COL_13,
       --COL_14,
       COL_15,
       --COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.1.A.2024' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             C.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.LOAN_ACCT_BAL * B.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             --T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             --T.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             --T.CORP_SCALE_NAM    AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD     AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             --T.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --T.GUARANTY_TYP_NAM  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_ACCT_LOAN_FARMING F
      /* ACCT_LOAN_FARMING_FULL F --涉农贷款补充 add by zy 铺底+发生*/
          ON T.DATA_DATE = F.DATA_DATE
         AND T.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY' --折人民币
       INNER JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
         AND C.CUST_TYP <> '3'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON T.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ACCT_TYP NOT LIKE '90%' --贷款账户类型去除委托贷款
         AND T.ACCT_STS <> 3 --账户状态非注销
         AND T.CANCEL_FLG = 'N' --核销标识为否
         AND SUBSTR(F.SNDKFL, 0, 7) in
             ('C_10201', 'C_20201', 'C_30201', 'C_40201')
         AND T.LOAN_STOCKEN_DATE IS NULL;


-- 指标: S7102_1.1.4.E.2024
---当年累放户数

    INSERT INTO 
    `S7102_1.1.4.E.2024` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.4.E.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --字段1(机构名)
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 T
       WHERE T.GUARANTY_TYP = 'D' --信用贷款
       GROUP BY ORG_NUM, T.CUST_ID, T.CUST_NAM, T.ORG_NAM;


-- 指标: S7102_1.2.F
--合计  1.2其中：普惠型农户个体工商户和农户小微企业主贷款 当年累放贷款年化收益

    INSERT INTO 
    `S7102_1.2.F` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.F', --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.NHSY AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
        LEFT JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE P.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款
          OR C.CUST_TYP = '3';


-- 指标: S7102_3.E.2025
--累放户数

    INSERT INTO 
    `S7102_3.E.2025` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.E.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             A.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2_TEMP A
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = A.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
       where A.FACILITY_AMT <= 10000000
       GROUP BY A.ORG_NUM,
                A.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;


-- 指标: S7102_3.F.2025
--累放收益
    INSERT INTO 
    `S7102_3.F.2025` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.F.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.NHSY AS TOTAL_VALUE, -- (累放金额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2_TEMP A
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = A.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       where A.FACILITY_AMT <= 10000000;


-- 指标: S7102_1.1.4.D.2024
--当年累计放款金额

    INSERT INTO 
    `S7102_1.1.4.D.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.4.D.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.DRAWDOWN_AMT AS TOTAL_VALUE, -- (放款金额)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       WHERE T.GUARANTY_TYP = 'D';


-- 指标: S7102_2.D4
---------新增-------2.普惠型涉农小微企业法人贷款 单户授信1000万元（含）以下不含票据融资合计（当年累放贷款额）  --ADD BY zxy 20220221

    INSERT INTO 
    `S7102_2.D4` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.D4' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_AMT AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 10000000
         AND ITEM_CD NOT LIKE '1301%' --刨除票据
         AND TT.CORP_SCALE IN ('S', 'T')
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1');


-- 指标: S7102_2.D0
---shiyu 20220621 与S7101取数一致。
    --与S7101用同一张临时表，客户属性用最新客户表数据，非放款时数据

    -----------新增-----------------2.普惠型涉农小微企业法人贷款 当年累放贷款额  --ADD BY zxy 20220217

    INSERT INTO 
    `S7102_2.D0` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_11,
       COL_12,
       COL_15)
      SELECT I_DATADATE, --数据日期
             TT.ORG_NUM, --机构号
             TT.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_2.D0' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAM AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_AMT AS TOTAL_VALUE, -- (累放金额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN TT.CORP_SCALE = 'B' THEN
                '大型'
               WHEN TT.CORP_SCALE = 'M' THEN
                '中型'
               WHEN TT.CORP_SCALE = 'S' THEN
                '小型'
               WHEN TT.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             T3.M_NAME AS COL_15 -- 字段15(涉农贷款分类)
        FROM cbrc_s7101_amt_tmp1 TT
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(TT.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON TT.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       WHERE AGREI_P_FLG = 'Y' --取涉农
         AND FACILITY_AMT <= 10000000
         AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.CORP_SCALE IN ('S', 'T');


-- 指标: S7102_1.1.5.E.2024
---当年累放户数

    INSERT INTO 
    `S7102_1.1.5.E.2024` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.5.E.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --字段1(机构名)
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 T
       WHERE MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12 --中长期贷款
       GROUP BY ORG_NUM, T.CUST_ID, T.CUST_NAM, T.ORG_NAM;


-- 指标: S7102_3.1.F.2025
--累放收益
    INSERT INTO 
    `S7102_3.1.F.2025` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.1.F.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             A.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.NHSY * TT.CCY_RATE AS TOTAL_VALUE, -- (累放金额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             A.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                '个体工商户'
               WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                '小微企业主'
               WHEN C.CUST_TYP = '3' THEN
                '个体工商户'
               ELSE
                '其他个人'
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2_TEMP A
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON C.CUST_ID = A.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       where A.FACILITY_AMT <= 10000000
         AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B'));


-- 指标: S7102_1.3.1.B1
-- 1.3.1 其中：扶贫小额信贷 贷款余额户数
    INSERT INTO 
    `S7102_1.3.1.B1` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             CASE
               WHEN T.FACILITY_AMT > 1000000 THEN
                'S7102_1.3.1.B3'
               WHEN T.FACILITY_AMT > 100000 THEN
                'S7102_1.3.1.B2'
               WHEN T.FACILITY_AMT <= 100000 THEN
                'S7102_1.3.1.B1'
             END AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --借据信息 --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                   /*V_PUB_IDX_DK_GRSNDK_1104  T --个人涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                   /* V_PUB_IDX_DK_GTGSHSNDK_1104 T --个体工商户涉农贷款 add by zy 铺底+发生*/
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON A.LOAN_NUM = R.LOAN_NUM
         AND A.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.LOAN_ACCT_BAL > 0
         AND A.DATA_DATE = I_DATADATE
         AND A.DRAWDOWN_AMT <= 50000 --放款金额小于50000
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) <= 36 --三年以内
         AND A.GUARANTY_TYP = 'D' --担保方式D  信用
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 5000000
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN T.FACILITY_AMT > 1000000 THEN
                   'S7102_1.3.1.B3'
                  WHEN T.FACILITY_AMT > 100000 THEN
                   'S7102_1.3.1.B2'
                  WHEN T.FACILITY_AMT <= 100000 THEN
                   'S7102_1.3.1.B1'
                END,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;


-- 指标: S7102_1.1.4.1.F.2024
--当年累放贷款收益

    INSERT INTO 
    `S7102_1.1.4.1.F.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.1.4.1.F.2024' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.NHSY AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
         AND P.CONTRACT_FARMER_TYPE = 'A' --承包方农户类型
       WHERE T.GUARANTY_TYP = 'D';


-- 指标: S7102_1.2.3.1.B.2024
--贷款户数

    INSERT INTO 
    `S7102_1.2.3.1.B.2024` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.3.1.B.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         and TT.GUARANTY_TYP = 'D' --信用贷款
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAME, TT.ORG_NAM;


-- 指标: S7102_1.2.4.B.2024
--贷款户数

    INSERT INTO 
    `S7102_1.2.4.B.2024` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.4.B.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.DATA_DATE = I_DATADATE
         AND MONTHS_BETWEEN(tt.MATURITY_DT, tt.DRAWDOWN_DT) > 12
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAME, TT.ORG_NAM;


-- 指标: S7102_1.2.D
----------------------------------农户个体工商户加工逻辑
    --BEGIN
    --合计  1.2其中：普惠型农户个体工商户和农户小微企业主贷款 当年累放贷款余额

    INSERT INTO 
    `S7102_1.2.D` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.D' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.DRAWDOWN_AMT AS TOTAL_VALUE, -- (放款金额)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
        LEFT JOIN SMTMODS_L_CUST_P P --个人客户信息
          ON T.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE P.OPERATE_CUST_TYPE IN ('A', 'B') --个体工商户贷款
          OR C.CUST_TYP = '3';


-- 指标: S7102_1.3.E
--合计 当年累放贷款户数

    INSERT INTO 
    `S7102_1.3.E` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             T.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.3.E', --指标号
             T.ORG_NAM AS COL_1, --字段1(机构名)
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON T.LOAN_NUM = R.LOAN_NUM
         AND T.DATA_DATE = R.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01' --建档立卡贫困人口贷款，包括未脱贫&返贫
       GROUP BY ORG_NUM, T.CUST_ID, T.CUST_NAM, T.ORG_NAM;


-- 指标: S7102_1.2.3.B.2024
--信用贷款

    --贷款户数

    INSERT INTO 
    `S7102_1.2.3.B.2024` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.3.B.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --字段1(机构名)
             TT.CUST_ID AS COL_2, --字段2(客户号)
             TT.CUST_NAME AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.DATA_DATE = I_DATADATE
         AND TT.GUARANTY_TYP = 'D' --信用贷款
       GROUP BY TT.ORG_NUM, TT.CUST_ID, TT.CUST_NAME, TT.ORG_NAM;


-- 指标: S7102_1.2.3.1.A.2024
--不良贷款

    --1.2.3.1其中：信用类普惠型农民专业合作社贷款

    -- 贷款余额

    INSERT INTO 
    `S7102_1.2.3.1.A.2024` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.2.3.1.A.2024' AS ITEM_NUM, --指标号
             TT.ORG_NAM AS COL_1, --机构名
             TT.CUST_ID AS COL_2, -- (客户号)
             TT.CUST_NAME AS COL_3, -- (客户名)
             TT.LOAN_NUM AS COL_4, -- (贷款编号)
             TT.LOAN_ACCT_BAL AS TOTAL_VALUE, -- (贷款余额)
             TT.ACCT_NUM AS COL_6, -- (贷款合同编号)
             TT.FACILITY_AMT AS COL_7, -- (授信额度)
             TT.DRAWDOWN_DT AS COL_8, -- (放款日期)
             TT.MATURITY_DT AS COL_9, -- (原始到期日)
             TT.CUST_TYPE_NAM AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             TT.CORP_SCALE_NAM AS COL_11, -- 字段11(企业规模)
             TT.ITEM_CD AS COL_12, -- 字段12(科目号)
             TT.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             TT.LOAN_GRADE_CD_NAM AS COL_14, -- 字段14(五级分类)
             TT.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             TT.GUARANTY_TYP_NAM AS COL_17, -- 字段17(贷款担保方式)
             TT.LOAN_PURPOSE_CD  AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_BAL_TMP1 TT
       WHERE TT.DATA_DATE = I_DATADATE
         AND TT.AGREI_P_FLG = 'Y' --涉农标志
         AND TT.CORP_SCALE IN ('S', 'T') --小微企业
         AND SUBSTR(TT.CUST_TYPE, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
         AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
         and TT.GUARANTY_TYP = 'D';


-- 指标: S7102_3.1.A.2025
------3.1其中：农户个体工商户和农户小微企业主贷款

    INSERT INTO 
    `S7102_3.1.A.2025` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.1.A.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, -- (客户名)
             A.LOAN_NUM AS COL_4, -- (贷款编号)
             A.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE, -- (贷款余额)
             A.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             A.DRAWDOWN_DT AS COL_8, -- (放款日期)
             A.MATURITY_DT AS COL_9, -- (原始到期日)
             CASE
               WHEN (A.ACCT_TYP LIKE '0102%' --个人经营性标识
                    OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
                    AND A.ITEM_CD LIKE '1305%')) THEN
                CASE
                  WHEN P.OPERATE_CUST_TYPE = 'A' THEN
                   '个体工商户'
                  WHEN P.OPERATE_CUST_TYPE = 'B' THEN
                   '小微企业主'
                  WHEN C.CUST_TYP = '3' THEN
                   '个体工商户'
                  ELSE
                   '其他个人'
                END
             END AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             CASE
               WHEN C.CORP_SCALE = 'B' THEN
                '大型'
               WHEN C.CORP_SCALE = 'M' THEN
                '中型'
               WHEN C.CORP_SCALE = 'S' THEN
                '小型'
               WHEN C.CORP_SCALE = 'T' THEN
                '微型'
             END AS COL_11, -- 字段11(企业规模)
             A.ITEM_CD AS COL_12, -- 字段12(科目号)
             A.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
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
             END AS COL_14, -- 字段14(五级分类)
             T3.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             CASE
               WHEN A.GUARANTY_TYP = 'A' THEN
                '质押贷款'
               WHEN A.GUARANTY_TYP = 'B' THEN
                '抵押贷款'
               WHEN A.GUARANTY_TYP = 'B01' THEN
                '房地产抵押贷款'
               WHEN A.GUARANTY_TYP = 'B99' THEN
                '其他抵押贷款'
               WHEN A.GUARANTY_TYP = 'C' THEN
                '保证贷款'
               WHEN A.GUARANTY_TYP = 'C01' THEN
                '联保贷款'
               WHEN A.GUARANTY_TYP = 'C99' THEN
                '其他保证贷款'
               WHEN A.GUARANTY_TYP = 'D' THEN
                '信用/免担保贷款'
               WHEN A.GUARANTY_TYP = 'E' THEN
                '组合担保'
               WHEN A.GUARANTY_TYP = 'Z' THEN
                '其他'
             END AS COL_17, -- 字段17(贷款担保方式)
             A.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = A.DATA_DATE
        LEFT JOIN SMTMODS_L_CUST_P P
          ON A.CUST_ID = P.CUST_ID
         AND P.DATA_DATE = A.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
          ON REPLACE(REPLACE(F.SNDKFL, 'P_', ''), 'C_', '') = T3.M_CODE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 10000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND (C.CUST_TYP = '3' OR P.OPERATE_CUST_TYPE IN ('A', 'B'));


-- 指标: S7102_1.3.D
--合计 当年累放贷款余额

    INSERT INTO 
    `S7102_1.3.D` 
      (DATA_DATE,
       ORG_NUM,
       DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       COL_4,
       TOTAL_VALUE,
       COL_6,
       COL_7,
       COL_8,
       COL_9,
       COL_10,
       COL_11,
       COL_12,
       COL_13,
       COL_14,
       COL_15,
       --COL_16,
       COL_17,
       COL_18)
      SELECT I_DATADATE, --数据日期
             ORG_NUM, --机构号
             T.DEPARTMENTD,-- 数据条线
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_1.3.D' AS ITEM_NUM, --指标号
             T.ORG_NAM AS COL_1, --机构名
             T.CUST_ID AS COL_2, -- (客户号)
             T.CUST_NAM AS COL_3, -- (客户名)
             T.LOAN_NUM AS COL_4, -- (贷款编号)
             T.DRAWDOWN_AMT AS TOTAL_VALUE, -- (年化收益)
             T.ACCT_NUM AS COL_6, -- (贷款合同编号)
             T.FACILITY_AMT AS COL_7, -- (授信额度)
             T.DRAWDOWN_DT AS COL_8, -- (放款日期)
             T.MATURITY_DT AS COL_9, -- (原始到期日)
             T.CUST_TYPE AS COL_10, -- 字段10(个人客户类型（个体工商户 小微企业主 其他个人）)
             T.CORP_SCALE AS COL_11, -- 字段11(企业规模)
             T.ITEM_CD AS COL_12, -- 字段12(科目号)
             T.DEPARTMENTD AS COL_13, -- 字段13(业务条线)
             T.LOAN_GRADE_CD AS COL_14, -- 字段14(五级分类)
             T.M_NAME AS COL_15, -- 字段15(涉农贷款分类)
             --AS COL_16,-- 字段16(经营性贷款标识（-1是0否）)
             T.GUARANTY_TYPNA  AS COL_17, -- 字段17(贷款担保方式)
             T.LOAN_PURPOSE_CD AS COL_18 -- 字段18(贷款投向)
        FROM CBRC_S7102_TEMP2 T
       INNER JOIN SMTMODS_L_ACCT_POVERTY_RELIF R --精准扶贫补充信息表
          ON T.LOAN_NUM = R.LOAN_NUM
         AND R.DATA_DATE = T.DATA_DATE
         AND R.POV_RE_LOAN_TYPE = 'A01';


-- 指标: S7102_3.B.2025
INSERT INTO 
    `S7102_3.B.2025` 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_1,
       COL_2,
       COL_3,
       TOTAL_VALUE)
      SELECT I_DATADATE, --数据日期
             A.ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'S7102' AS REP_NUM, --报表编号
             'S7102_3.B.2025' AS ITEM_NUM, --指标号
             ORG.ORG_NAM AS COL_1, --机构名称
             T.CUST_ID AS COL_2, --字段2(客户号)
             NVL(P.CUST_NAM, C.CUST_NAM) AS COL_3, --字段3(客户名)
             '1' AS TOTAL_VALUE --字段5(客户数)
        FROM CBRC_S7102_TEMP1 T
       INNER JOIN SMTMODS_L_ACCT_LOAN A --借据信息
          ON T.CUST_ID = A.CUST_ID
         AND A.DATA_DATE = I_DATADATE
       INNER JOIN (SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GRSNDK T --个人涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')
                   UNION ALL
                   SELECT *
                     FROM SMTMODS_V_PUB_IDX_DK_GTGSHSNDK T --个体工商户涉农贷款
                    WHERE T.DATA_DATE = I_DATADATE
                      AND SUBSTR(T.SNDKFL, 1, 5) IN
                          ('P_101', 'P_102', 'P_103')) F --农户贷款
          ON A.LOAN_NUM = F.LOAN_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = T.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         and TT.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_PUBL_ORG_BRA ORG
          ON A.ORG_NUM = ORG.ORG_NUM
         AND ORG.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P P --对公客户信息表
          ON P.CUST_ID = T.CUST_ID
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_C C --对公客户信息表
          ON C.CUST_ID = T.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE (A.ACCT_TYP LIKE '0102%' --个人经营性标识
             OR (SUBSTR(A.ACCT_TYP, 1, 4) = '0199' -- 0199 其他个人贷款
             AND A.ITEM_CD LIKE '1305%')) --个体工商户贸易融资  ZHOUJINGKUN 20210412
         AND A.DATA_DATE = I_DATADATE
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5') --贷款五级分类
         AND T.FACILITY_AMT <= 10000000
         and A.CANCEL_FLG <> 'Y'
         AND A.ACCT_TYP NOT LIKE '90%' --不含委托贷款 --alter by 剔除委托贷款 shiyu  20220224
         AND T.DATA_DATE = I_DATADATE
         AND A.LOAN_ACCT_BAL > 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY A.ORG_NUM,
                T.CUST_ID,
                NVL(P.CUST_NAM, C.CUST_NAM),
                ORG.ORG_NAM;


