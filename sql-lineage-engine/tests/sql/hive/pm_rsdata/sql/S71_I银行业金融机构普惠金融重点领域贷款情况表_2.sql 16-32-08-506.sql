-- ============================================================
-- 文件名: S71_I银行业金融机构普惠金融重点领域贷款情况表_2.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  CASE
                    WHEN T.FACILITY_AMT <= 1000000 THEN
                     'S71_I_3..F1.2018'
                    WHEN T.FACILITY_AMT > 1000000 AND
                         T.FACILITY_AMT <= 5000000 THEN
                     'S71_I_3..F2.2018'
                    WHEN T.FACILITY_AMT > 5000000 AND
                         T.FACILITY_AMT <= 10000000 THEN
                     'S71_I_3..F3.2018'
                    WHEN T.FACILITY_AMT > 10000000 AND
                         T.FACILITY_AMT <= 30000000 THEN
                     'S71_I_3..F4.2018'
                  END AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
                  CASE
                    WHEN T.OPERATE_CUST_TYPE IN ('A', '3') THEN
                     '个体工商户'
                    WHEN T.OPERATE_CUST_TYPE IN ('B') THEN
                     '小微企业主'
                    ELSE
                     '其他个人'
                  END AS COL_23
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.OPERATE_CUST_TYPE IN ('A', 'B', '3')
) q_0
INSERT INTO `S71_I_3..F2.2018` (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_23)
SELECT *
INSERT INTO `S71_I_3..F1.2018` (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_23)
SELECT *
INSERT INTO `S71_I_3..F3.2018` (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_23)
SELECT *
INSERT INTO `S71_I_3..F4.2018` (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_23)
SELECT *;

-- 指标: S71_I_1.b.A5.2025
-- 其中：单户授信1000万元（含）以下不含票据融资合计

      INSERT INTO `S71_I_1.b.A5.2025`
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
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
         COL_14)
        SELECT T.DATA_DATE,
               T.ORG_NUM,
               T.DEPARTMENTD,
               'CBRC' AS SYS_NAM,
               'S7101' AS REP_NUM,
               'S71_I_1.b.A5.2025' AS ITEM_NUM,
               T.LOAN_ACCT_BAL AS TOTAL_VALUE,
               T.CUST_ID AS COL_2,
               T.CUST_NAM AS COL_3,
               T.LOAN_NUM AS COL_4,
               T.FACILITY_AMT AS COL_6,
               T.ACCT_NUM AS COL_7,
               T.DRAWDOWN_DT AS COL_8,
               T.MATURITY_DT AS COL_9,
               T.ITEM_CD AS COL_10,
               T.DEPARTMENTD AS COL_11,
               T.CORP_SCALE AS COL_12,
               T.CP_NAME AS COL_13,
               T.LOAN_GRADE_CD AS COL_14
          FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
         WHERE DATA_DATE = I_DATADATE
           AND PHXWXQYFRDK = '是'
           AND T.LOAN_ACCT_BAL <> 0
           AND ITEM_CD NOT LIKE '1301%' --不含贴现
           AND FACILITY_AMT <= 10000000;


-- 指标: S71_I_3..D5.2021
-- 其中：单户授信1000万元（含）以下不含票据融资合计

         INSERT INTO `S71_I_3..D5.2021`
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_23)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3..D5.2021' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
                  CASE
                    WHEN T.OPERATE_CUST_TYPE IN ('A', '3') THEN
                     '个体工商户'
                    WHEN T.OPERATE_CUST_TYPE IN ('B') THEN
                     '小微企业主'
                    ELSE
                     '其他个人'
                  END AS COL_23
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND OPERATE_CUST_TYPE IN ('A', 'B', '3') --个人（A个体工商户和B小微企业主）对公（3个体工商户）
              AND FACILITY_AMT <= 10000000 --单户授信总额1000万元以下,含本数
              AND ITEM_CD NOT LIKE '1301%';


-- 指标: S71_I_4..E5.2021
-- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO `S71_I_4..E5.2021`
           (DATA_DATE,
            ORG_NUM,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3)
           SELECT I_DATADATE,
                  TT.ORG_NUM,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_4..E5.2021' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE,
                  TT.CUST_ID AS COL_2,
                  TT.CUST_NAM AS COL_3
             FROM CBRC_S7101_AMT_TMP1 TT
             LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
               ON T.CUST_ID = TT.CUST_ID
              AND T.DATA_DATE = I_DATADATE --取当月的授信金额
              AND T.FACILITY_AMT <= 10000000 --单户授信总额1000万元元以下,含本数 属于普惠型
             LEFT JOIN SMTMODS_L_CUST_P P --对私客户补充信息表
               ON P.DATA_DATE = I_DATADATE
              AND TT.CUST_ID = P.CUST_ID
            WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND TT.DATA_DATE <= I_DATADATE
              AND TT.OPERATE_CUST_TYPE = 'Z' --其他个人
              AND TT.AGREI_P_FLG = 'N' --非涉农
              AND (P.VOCATION_TYP <> 'X' OR P.VOCATION_TYP IS NULL) --ALTER BY WJB 20220128 去掉职业为军人的
              AND (P.QUALITY NOT IN ('10', '20')) --ALTER BY shiyu m9 去掉10 机关、事业单位  20 国有企业
              AND ITEM_CD NOT LIKE '1301%' --不含贴现
              AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
              AND TT.FACILITY_AMT <= 10000000
            GROUP BY TT.ORG_NUM,
                     TT.CUST_ID,
                     TT.CUST_NAM;


-- 指标: S71_I_1.a.E5.2025
-- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO `S71_I_1.a.E5.2025`
           (DATA_DATE,
            ORG_NUM,
            --DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            COL_2,
            COL_3)
           SELECT I_DATADATE,
                  TT.ORG_NUM,
                  --TT.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.a.E5.2025' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                  TT.CUST_ID AS COL_2,
                  TT.CUST_NAM AS COL_3
             FROM CBRC_S7101_AMT_TMP1 TT
             LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
               ON T.CUST_ID = TT.CUST_ID
              AND T.DATA_DATE = I_DATADATE --取当月的授信金额
              AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元元以下,含本数 属于普惠型
            WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND TT.DATA_DATE <= I_DATADATE
              AND TT.CORP_SCALE IN ('S') --小型
              AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND TT.ITEM_CD NOT LIKE '1301%' --刨除票据
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND TT.LOAN_NUM = C.LOAN_NUM)
              AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
            GROUP BY TT.ORG_NUM,
                     TT.CUST_ID,
                     TT.CUST_NAM;


-- 指标: S71_I_3.2.F.2018
-- 3.2其中：普惠型小微企业主贷款   单户授信3000万元（含）以下合计 当年累放贷款年化利息收益
         INSERT INTO `S71_I_3.2.F.2018`
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3.2.F.2018' AS ITEM_NUM,
                  T.NHSY AS COL_5,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.OPERATE_CUST_TYPE = 'B' --取小微企业住
              AND T.FACILITY_AMT <= 30000000;


-- 指标: S71_I_1.b.D0.2025
-- 1.b普惠型微型企业法人贷款  当年累放贷款额
         INSERT INTO `S71_I_1.b.D0.2025`
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.b.D0.2025' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND t.CORP_SCALE IN ('T') --微型
              AND SUBSTR(t.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND t.FACILITY_AMT <= 10000000 --授信额度1000万以下
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND T.LOAN_NUM = C.LOAN_NUM);


-- ========== 逻辑组 7: 共 4 个指标 ==========
FROM (
SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.1.A4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.1.A3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.1.A2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.1.A1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   --T.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   --T.LOAN_ACCT_BAL AS COL_5,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14,
                   T2.M_NAME AS COL_15
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON REPLACE(REPLACE(T.SNDKFL, 'P_', ''), 'C_', '') = T2.M_CODE
             WHERE DATA_DATE = I_DATADATE
               AND LOAN_ACCT_BAL <> 0
               AND PHXSNXWQYFRDK = '是'
) q_7
INSERT INTO `S71_I_1.1.A4.2018` (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
              
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
             COL_15)
SELECT *
INSERT INTO `S71_I_1.1.A2.2018` (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
              
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
             COL_15)
SELECT *
INSERT INTO `S71_I_1.1.A1.2018` (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
              
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
             COL_15)
SELECT *
INSERT INTO `S71_I_1.1.A3.2018` (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
              
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
             COL_15)
SELECT *;

-- ========== 逻辑组 8: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 CASE
                   WHEN T.FACILITY_AMT <= 1000000 THEN
                    'S71_I_3..D1.2018'
                   WHEN T.FACILITY_AMT > 1000000 AND
                        T.FACILITY_AMT <= 5000000 THEN
                    'S71_I_3..D2.2018'
                   WHEN T.FACILITY_AMT > 5000000 AND
                        T.FACILITY_AMT <= 10000000 THEN
                    'S71_I_3..D3.2018'
                   WHEN T.FACILITY_AMT > 10000000 AND
                        T.FACILITY_AMT <= 30000000 THEN
                    'S71_I_3..D4.2018'
                 END AS ITEM_NUM,
                 T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T2.M_NAME AS COL_12,
                 T.CP_NAME AS COL_13,
                 CASE
                   WHEN T.OPERATE_CUST_TYPE IN ('A', '3') THEN
                    '个体工商户'
                   WHEN T.OPERATE_CUST_TYPE IN ('B') THEN
                    '小微企业主'
                   ELSE
                    '其他个人'
                 END AS COL_23
            FROM CBRC_S7101_AMT_TMP1 T
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
              ON T.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND T.DATA_DATE <= I_DATADATE
             AND T.OPERATE_CUST_TYPE IN ('A', 'B', '3')
) q_8
INSERT INTO `S71_I_3..D2.2018` (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
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
           COL_23)
SELECT *
INSERT INTO `S71_I_3..D1.2018` (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
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
           COL_23)
SELECT *
INSERT INTO `S71_I_3..D4.2018` (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
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
           COL_23)
SELECT *
INSERT INTO `S71_I_3..D3.2018` (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
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
           COL_23)
SELECT *;

-- 指标: S71_I_1.b.C5.2025
-- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO `S71_I_1.b.C5.2025`
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
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
              COL_14)
             SELECT T.DATA_DATE,
                    T.ORG_NUM,
                    T.DEPARTMENTD,
                    'CBRC' AS SYS_NAM,
                    'S7101' AS REP_NUM,
                    'S71_I_1.b.C5.2025' AS ITEM_NUM,
                    T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                    T.CUST_ID AS COL_2,
                    T.CUST_NAM AS COL_3,
                    T.LOAN_NUM AS COL_4,
                    T.FACILITY_AMT AS COL_6,
                    T.ACCT_NUM AS COL_7,
                    T.DRAWDOWN_DT AS COL_8,
                    T.MATURITY_DT AS COL_9,
                    T.ITEM_CD AS COL_10,
                    T.DEPARTMENTD AS COL_11,
                    T.CORP_SCALE AS COL_12,
                    T.CP_NAME AS COL_13,
                    T.LOAN_GRADE_CD AS COL_14
               FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
              WHERE DATA_DATE = I_DATADATE
                AND PHXWXQYFRDK = '是'
                AND T.LOAN_ACCT_BAL <> 0
                AND LOAN_GRADE_CD IN ('次级', '可疑', '损失') --不良贷款
                AND ITEM_CD NOT LIKE '1301%' --不含贴现
                AND FACILITY_AMT <= 10000000;


-- 指标: S71_I_3.1.B5.2021
-- 其中：单户授信1000万元（含）以下不含票据融资合计
            INSERT INTO `S71_I_3.1.B5.2021`
              (DATA_DATE,
               ORG_NUM,
               SYS_NAM,
               REP_NUM,
               ITEM_NUM,
               TOTAL_VALUE,
               COL_2,
               COL_3)
              SELECT T.DATA_DATE,
                     T.ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     'S7101' AS REP_NUM,
                     'S71_I_3.1.B5.2021' AS ITEM_NUM,
                     '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                     T.CUST_ID AS COL_2,
                     T.CUST_NAM AS COL_3
                FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
               WHERE DATA_DATE = I_DATADATE
                 AND PHXGTGSHDK = '是'
                 AND T.LOAN_ACCT_BAL <> 0
                 AND ITEM_CD NOT LIKE '1301%' --不含贴现
                 AND FACILITY_AMT <= 10000000
               GROUP BY T.DATA_DATE,
                        T.ORG_NUM,
                        T.CUST_ID,
                        T.CUST_NAM;


-- 指标: S71_I_1.a.B5.2025
-- 其中：单户授信1000万元（含）以下不含票据融资合计
             INSERT INTO `S71_I_1.a.B5.2025`
            (DATA_DATE,
             ORG_NUM,
             --DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   --T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.a.B5.2025' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXXXQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000
             GROUP BY T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;


-- 指标: S71_I_1.b.A0.2025
-- 1.b普惠型微型企业法人贷款  单户授信1000万元（含）以下合计 贷款余额
      INSERT INTO `S71_I_1.b.A0.2025`
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
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
         COL_14)
        SELECT T.DATA_DATE,
               T.ORG_NUM,
               T.DEPARTMENTD,
               'CBRC' AS SYS_NAM,
               'S7101' AS REP_NUM,
               'S71_I_1.b.A0.2025' AS ITEM_NUM,
               T.LOAN_ACCT_BAL AS TOTAL_VALUE,
               T.CUST_ID AS COL_2,
               T.CUST_NAM AS COL_3,
               T.LOAN_NUM AS COL_4,
               T.FACILITY_AMT AS COL_6,
               T.ACCT_NUM AS COL_7,
               T.DRAWDOWN_DT AS COL_8,
               T.MATURITY_DT AS COL_9,
               T.ITEM_CD AS COL_10,
               T.DEPARTMENTD AS COL_11,
               T.CORP_SCALE AS COL_12,
               T.CP_NAME AS COL_13,
               T.LOAN_GRADE_CD AS COL_14
          FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
         WHERE DATA_DATE = I_DATADATE
           AND PHXWXQYFRDK = '是'
           AND T.LOAN_ACCT_BAL <> 0
           AND FACILITY_AMT <= 10000000;


-- 指标: S71_I_1.a.C5.2025
-- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO `S71_I_1.a.C5.2025`
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
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
              COL_14)
             SELECT T.DATA_DATE,
                    T.ORG_NUM,
                    T.DEPARTMENTD,
                    'CBRC' AS SYS_NAM,
                    'S7101' AS REP_NUM,
                    'S71_I_1.a.C5.2025' AS ITEM_NUM,
                    T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                    T.CUST_ID AS COL_2,
                    T.CUST_NAM AS COL_3,
                    T.LOAN_NUM AS COL_4,
                    T.FACILITY_AMT AS COL_6,
                    T.ACCT_NUM AS COL_7,
                    T.DRAWDOWN_DT AS COL_8,
                    T.MATURITY_DT AS COL_9,
                    T.ITEM_CD AS COL_10,
                    T.DEPARTMENTD AS COL_11,
                    T.CORP_SCALE AS COL_12,
                    T.CP_NAME AS COL_13,
                    T.LOAN_GRADE_CD AS COL_14
               FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
              WHERE DATA_DATE = I_DATADATE
                AND PHXXXQYFRDK = '是'
                AND LOAN_GRADE_CD IN ('次级', '可疑', '损失') --不良贷款
                AND ITEM_CD NOT LIKE '1301%' --不含贴现
                AND T.LOAN_ACCT_BAL <> 0
                AND FACILITY_AMT <= 10000000;


-- 指标: S71_I_3.2.D.2018
-- 3.2其中：普惠型小微企业主贷款      单户授信3000万元（含）以下合计 当年累放贷款额
         INSERT INTO `S71_I_3.2.D.2018`
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_3.2.D.2018' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.OPERATE_CUST_TYPE = 'B' --取小微企业住
              AND T.FACILITY_AMT <= 30000000;


-- 指标: S71_I_1.a.F0.2025
-- 1.a普惠型小型企业法人贷款  当年累放贷款年化利息收益
         INSERT INTO `S71_I_1.a.F0.2025`
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.a.F0.2025' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.CORP_SCALE IN ('S') --小型
              AND SUBSTR(T.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND T.FACILITY_AMT <= 10000000 --授信额度1000万以下
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND T.LOAN_NUM = C.LOAN_NUM);


-- 指标: S71_I_1..D5.2021
-- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO `S71_I_1..D5.2021`
             (DATA_DATE,
              ORG_NUM,
              DATA_DEPARTMENT,
              SYS_NAM,
              REP_NUM,
              ITEM_NUM,
              TOTAL_VALUE,
              --COL_1,
              COL_2,
              COL_3,
              COL_4,
              --COL_5,
              COL_6,
              COL_7,
              COL_8,
              COL_9,
              COL_10,
              COL_11,
              COL_12,
              COL_13)
             SELECT I_DATADATE,
                    T.ORG_NUM,
                    T.DEPARTMENTD,
                    'CBRC' AS SYS_NAM,
                    'S7101' AS REP_NUM,
                    'S71_I_1..D5.2021' AS ITEM_NUM,
                    T.LOAN_ACCT_AMT,
                    --T1.INST_NAME AS COL_1,
                    T.CUST_ID AS COL_2,
                    T.CUST_NAM AS COL_3,
                    T.LOAN_NUM AS COL_4,
                    --T.LOAN_ACCT_AMT AS COL_5,
                    T.FACILITY_AMT AS COL_6,
                    T.ACCT_NUM AS COL_7,
                    T.DRAWDOWN_DT AS COL_8,
                    T.MATURITY_DT AS COL_9,
                    T.ITEM_CD AS COL_10,
                    T.DEPARTMENTD AS COL_11,
                    T2.M_NAME AS COL_12,
                    T.CP_NAME AS COL_13
               FROM CBRC_S7101_AMT_TMP1 T
               --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
               --  ON T.ORG_NUM = T1.INST_ID
               LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
                 ON T.CORP_SCALE = T2.M_CODE
                AND T2.M_TABLECODE = 'CORP_SCALE'
              WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
                AND T.DATA_DATE <= I_DATADATE
                --AND T.LOAN_ACCT_AMT <> 0
                AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                AND T.CORP_SCALE IN ('S', 'T') --小微企业
                AND ITEM_CD NOT LIKE '1301%' --不含贴现
                AND FACILITY_AMT <= 10000000;


-- ========== 逻辑组 17: 共 2 个指标 ==========
FROM (
SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.3.A4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.3.A3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.3.A2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.3.A1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND T.LOAN_ACCT_BAL <> 0
               AND GRCYDBDK = '是'
) q_17
INSERT INTO `S71_I_3.3.A1.2018` (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
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
             COL_14)
SELECT *
INSERT INTO `S71_I_3.3.A4.2018` (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
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
             COL_14)
SELECT *;

-- 指标: S71_I_1..F5.2021
-- 其中：单户授信1000万元（含）以下不含票据融资合计

          INSERT INTO `S71_I_1..F5.2021`
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           --COL_1,
           COL_2,
           COL_3,
           COL_4,
           --COL_5,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_12,
           COL_13)
          SELECT I_DATADATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1..F5.2021' AS ITEM_NUM,
                 T.NHSY AS TOTAL_VALUE,
                 --T1.INST_NAME AS COL_1,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 --T.NHSY AS COL_5,
                 T.FACILITY_AMT  AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T2.M_NAME AS COL_12,
                 T.CP_NAME AS COL_13
            FROM CBRC_S7101_AMT_TMP1 T
            --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
            --  ON T.ORG_NUM = T1.INST_ID
            LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
              ON T.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND T.DATA_DATE <= I_DATADATE
             --AND T.NHSY <> 0
             AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
             AND T.CORP_SCALE IN ('S', 'T') --小微企业
             AND ITEM_CD NOT LIKE '1301%' --不含贴现
             AND T.FACILITY_AMT <= 10000000;


-- 指标: S71_I_1.b.D5.2025
-- 其中：单户授信1000万元（含）以下不含票据融资合计

         INSERT INTO `S71_I_1.b.D5.2025`
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.b.D5.2025' AS ITEM_NUM,
                  T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND T.CORP_SCALE IN ('T') --小型
              AND SUBSTR(T.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
              AND T.ITEM_CD NOT LIKE '1301%' --刨除票据
              AND T.FACILITY_AMT <= 10000000 --授信额度1000万以下
              AND NOT EXISTS
            (SELECT 1
                     FROM CBRC_S7101_AMT_TMP1 C
                    WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                          OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                      AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                      AND C.AGREI_P_FLG = 'Y' ---涉农标志
                      AND C.CORP_SCALE IN ('S', 'T') --小微企业
                      AND T.LOAN_NUM = C.LOAN_NUM);


-- 指标: S71_I_3.3.1.B1.2018
-- 3.3.1其中：残疾人创业担保贷款    贷款余额户数
          INSERT INTO `S71_I_3.3.1.B1.2018`
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.3.1.B4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.3.1.B3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.3.1.B2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.3.1.B1.2018'
                   END AS ITEM_NUM,
                   '1' AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND CJRCYDBDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
             GROUP BY T.SXFW,
                      T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;


-- 指标: S71_I_7.C.2025
INSERT INTO `S71_I_7.C.2025`
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_14)
           SELECT T.DATA_DATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_7.C.2025' AS ITEM_NUM,
                  T.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  NVL(C.CUST_NAM, P.CUST_NAM) AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T2.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T3.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
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
                  END AS COL_14
             FROM SMTMODS_L_ACCT_LOAN T
             LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
               ON TT.CCY_DATE = I_DATADATE
              AND TT.BASIC_CCY = T.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
             LEFT JOIN SMTMODS_L_CUST_C C --对公表 取小微企业
               ON T.CUST_ID = C.CUST_ID
              AND C.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_L_CUST_P P --对私表 取个体工商户&小微企业主
               ON T.CUST_ID = P.CUST_ID
              AND P.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX T2 --授信额度
               ON T.CUST_ID = T2.CUST_ID
              AND T2.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
               ON C.CORP_SCALE = T3.M_CODE
            WHERE T.DATA_DATE = I_DATADATE
              AND T.ACCT_STS <> '3'
              AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
              AND T.ITEM_CD NOT LIKE '1301%' ---刨除票据
              AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
              AND T.LOAN_ACCT_BAL <> 0
              AND T.LOAN_GRADE_CD IN ('3', '4', '5');


-- 指标: S71_I_3.2.B5.2021
-- 其中：单户授信1000万元（含）以下不含票据融资合计
            INSERT INTO `S71_I_3.2.B5.2021`
              (DATA_DATE,
               ORG_NUM,
               SYS_NAM,
               REP_NUM,
               ITEM_NUM,
               TOTAL_VALUE,
               COL_2,
               COL_3)
              SELECT T.DATA_DATE,
                     T.ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     'S7101' AS REP_NUM,
                     'S71_I_3.2.B5.2021' AS ITEM_NUM,
                     '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                     T.CUST_ID AS COL_2,
                     T.CUST_NAM AS COL_3
                FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
               WHERE DATA_DATE = I_DATADATE
                 AND PHXXWQYZDK = '是'
                 AND ITEM_CD NOT LIKE '1301%' --不含贴现
                 AND FACILITY_AMT <= 10000000
               GROUP BY T.DATA_DATE,
                        T.ORG_NUM,
                        T.CUST_ID,
                        T.CUST_NAM;


-- 指标: S71_I_7.A.2025
INSERT INTO `S71_I_7.A.2025`
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_14)
           SELECT T.DATA_DATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_7.A.2025' AS ITEM_NUM,
                  T.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  NVL(C.CUST_NAM, P.CUST_NAM) AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T2.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T3.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
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
                  END AS COL_14
             FROM SMTMODS_L_ACCT_LOAN T
             LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
               ON TT.CCY_DATE = I_DATADATE
              AND TT.BASIC_CCY = T.CURR_CD
              AND TT.FORWARD_CCY = 'CNY'
             LEFT JOIN SMTMODS_L_CUST_C C --对公表 取小微企业
               ON T.CUST_ID = C.CUST_ID
              AND C.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_L_CUST_P P --对私表 取个体工商户&小微企业主
               ON T.CUST_ID = P.CUST_ID
              AND P.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX T2 --授信额度
               ON T.CUST_ID = T2.CUST_ID
              AND T2.DATA_DATE = I_DATADATE
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
               ON C.CORP_SCALE = T3.M_CODE
              AND T3.M_TABLECODE='CORP_SCALE'
            WHERE T.DATA_DATE = I_DATADATE
              AND T.ACCT_STS <> '3'
              AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
              AND T.ITEM_CD NOT LIKE '1301%' ---刨除票据
              AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
              AND T.LOAN_ACCT_BAL <> 0;


-- 指标: S71_I_1.5.E.2018
INSERT INTO `S71_I_1.5.E.2018`
          (DATA_DATE,
           ORG_NUM,
           --DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           --COL_1,
           COL_2,
           COL_3 )
          SELECT I_DATADATE,
                 TT.ORG_NUM,
                 --TT.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1.5.E.2018' AS ITEM_NUM,
                 '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                 --T1.INST_NAME AS COL_1,
                 TT.CUST_ID AS COL_2,
                 TT.CUST_NAM AS COL_3
            FROM CBRC_S7101_AMT_TMP1 TT
            --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
            --  ON TT.ORG_NUM = T1.INST_ID
            LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
              ON T.CUST_ID = TT.CUST_ID
             AND T.DATA_DATE = I_DATADATE --取当月的授信金额
             AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
           WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND TT.DATA_DATE <= I_DATADATE
             AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
             AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000
             AND TT.CORP_SCALE IN ('S', 'T') --小微企业
             AND TT.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志
             AND TT.AGREI_P_FLG = 'Y' ---涉农标志
           GROUP BY --T1.INST_NAME,
                    TT.ORG_NUM,
                    TT.CUST_ID,
                    TT.CUST_NAM;


-- 指标: S71_I_6.3.D5.2022
-- 其中：单户授信1000万元（含）以下不含票据融资合计
            INSERT INTO `S71_I_6.3.D5.2022`
              (DATA_DATE,
               ORG_NUM,
               DATA_DEPARTMENT,
               SYS_NAM,
               REP_NUM,
               ITEM_NUM,
               TOTAL_VALUE,
               COL_2,
               COL_3,
               COL_4,
               COL_6,
               COL_7,
               COL_8,
               COL_9,
               COL_10,
               COL_11,
               COL_13)
              SELECT I_DATADATE,
                     T.ORG_NUM,
                     T.DEPARTMENTD,
                     'CBRC' AS SYS_NAM,
                     'S7101' AS REP_NUM,
                     'S71_I_6.3.D5.2022' AS ITEM_NUM,
                     T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                     T.CUST_ID AS COL_2,
                     T.CUST_NAM AS COL_3,
                     T.LOAN_NUM AS COL_4,
                     T.FACILITY_AMT AS COL_6,
                     T.ACCT_NUM AS COL_7,
                     T.DRAWDOWN_DT AS COL_8,
                     T.MATURITY_DT AS COL_9,
                     T.ITEM_CD AS COL_10,
                     T.DEPARTMENTD AS COL_11,
                     T.CP_NAME AS COL_13
                FROM CBRC_S7101_AMT_TMP1 T
               WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
                 AND T.DATA_DATE <= I_DATADATE
                 AND (SUBSTR(T.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                     AND T.CORP_SCALE IN ('S', 'T') OR --小微企业
                     T.OPERATE_CUST_TYPE IN ('A', 'B', '3')) --个人（A个体工商户和B小微企业主）对公（3个体工商户）
                 AND T.LOAN_KIND_CD = '6'
                 AND ITEM_CD NOT LIKE '1301%' --不含贴现
                 AND FACILITY_AMT <= 10000000;


-- 指标: S71_I_1.b.C0.2025
-- 1.b普惠型微型企业法人贷款 不良贷款余额
          INSERT INTO `S71_I_1.b.C0.2025`
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
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
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.b.C0.2025' AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXWXQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失') --不良贷款
               AND FACILITY_AMT <= 10000000;


-- 指标: S71_I_3.1.E.2018
--3.1其中：普惠型个体工商户贷款  单户授信3000万元（含）以下合计 当年累放贷款户数
          INSERT INTO `S71_I_3.1.E.2018`
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT I_DATADATE,
                   TT.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_3.1.E.2018' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                   TT.CUST_ID AS COL_2,
                   TT.CUST_NAM AS COL_3
              FROM CBRC_S7101_AMT_TMP1 TT
              LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
                ON T.CUST_ID = TT.CUST_ID
               AND T.DATA_DATE = I_DATADATE --取当月的授信金额
               AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
             WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND TT.DATA_DATE <= I_DATADATE
               AND TT.OPERATE_CUST_TYPE IN ('A', '3') --对私是：A,对公是：3 --取个体工商户
               AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 30000000
             GROUP BY TT.ORG_NUM,
                      TT.CUST_ID,
                      TT.CUST_NAM;


-- 指标: S71_I_1..E5.2021
-- 其中：单户授信1000万元（含）以下不含票据融资合计
         INSERT INTO `S71_I_1..E5.2021`
           (DATA_DATE,
            ORG_NUM,
            --DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
            --COL_1,
            COL_2,
            COL_3)
           SELECT I_DATADATE,
                  TT.ORG_NUM,
                  --TT.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1..E5.2021' AS ITEM_NUM,
                  '1' AS TOTAL_VALUE, --为了统计户数,定义字段5(默认为1,分组后客户不重复,就是1户,结果统计SUM值
                  --T1.INST_NAME AS COL_1,
                  TT.CUST_ID AS COL_2,
                  TT.CUST_NAM AS COL_3
             FROM CBRC_S7101_AMT_TMP1 TT
             --LEFT JOIN CBRC_DATACORE.UPRR_U_BASE_INST T1
             --  ON TT.ORG_NUM = T1.INST_ID
             LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
               ON T.CUST_ID = TT.CUST_ID
              AND T.DATA_DATE = I_DATADATE --取当月的授信金额
              AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元元以下,含本数 属于普惠型
            WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND TT.DATA_DATE <= I_DATADATE
              AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND TT.CORP_SCALE IN ('S', 'T') --小微企业
              AND ITEM_CD NOT LIKE '1301%' --不含贴现
              --AND TT.LOAN_ACCT_AMT <> 0
              AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
            GROUP BY --T1.INST_NAME,
                     TT.ORG_NUM,
                     TT.CUST_ID,
                     TT.CUST_NAM;


-- 指标: S71_I_6.3.B5.2022
-- 其中：单户授信1000万元（含）以下不含票据融资合计
            INSERT INTO `S71_I_6.3.B5.2022`
              (DATA_DATE,
               ORG_NUM,
               SYS_NAM,
               REP_NUM,
               ITEM_NUM,
               TOTAL_VALUE,
               COL_2,
               COL_3)
              SELECT T.DATA_DATE,
                     T.ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     'S7101' AS REP_NUM,
                     'S71_I_6.3.B5.2022' AS ITEM_NUM,
                     '1' AS TOTAL_VALUE,
                     T.CUST_ID AS COL_2,
                     T.CUST_NAM AS COL_3
                FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
               WHERE DATA_DATE = I_DATADATE
                 AND XWQYWHBXD = '是'
                 AND T.LOAN_ACCT_BAL <> 0
                 AND ITEM_CD NOT LIKE '1301%' --不含贴现
                 AND FACILITY_AMT <= 10000000
               GROUP BY T.DATA_DATE,
                        T.ORG_NUM,
                        T.CUST_ID,
                        T.CUST_NAM;


-- 指标: S71_I_2..B5.2021
-- 其中：单户授信1000万元（含）以下不含票据融资合计
             INSERT INTO `S71_I_2..B5.2021`
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_2..B5.2021' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXQTZZDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000
             GROUP BY T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;


-- 指标: S71_I_1.b.E0.2025
-- 1.b普惠型微型企业法人贷款  当年累放贷款户数
        INSERT INTO `S71_I_1.b.E0.2025`
          (DATA_DATE,
           ORG_NUM,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3)
          SELECT I_DATADATE,
                 TT.ORG_NUM,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1.b.E0.2025' AS ITEM_NUM,
                 '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计SUM值
                 TT.CUST_ID AS COL_2,
                 TT.CUST_NAM AS COL_3
            FROM CBRC_S7101_AMT_TMP1 TT
            LEFT JOIN CBRC_S7101_CREDITLINE_LJ T --授信加工临时表
              ON T.CUST_ID = TT.CUST_ID
             AND T.DATA_DATE = I_DATADATE --取当月的授信金额
             AND T.FACILITY_AMT <= 30000000 --单户授信总额3000万元以下,含本数 属于普惠型
           WHERE TT.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
             AND TT.DATA_DATE <= I_DATADATE
             AND TT.CORP_SCALE IN ('T') --微型
             AND SUBSTR(TT.CUST_TYP, 0, 1) IN ('1', '0') -- 企业规模中含事业单位、民办非企业贷款
             AND NOT EXISTS
           (SELECT 1
                    FROM CBRC_S7101_AMT_TMP1 C
                   WHERE (C.COOP_LAON_FLAG = 'Y' --农民合作社贷款标志 --ADDED BY YHY 20211221
                         OR RUR_COLL_ECO_ORG_LOAN_FLG = 'Y')
                     AND SUBSTR(C.CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                     AND C.AGREI_P_FLG = 'Y' ---涉农标志
                     AND C.CORP_SCALE IN ('S', 'T') --小微企业
                     AND TT.LOAN_NUM = C.LOAN_NUM)
             AND NVL(T.FACILITY_AMT, TT.FACILITY_AMT) <= 10000000
           GROUP BY TT.ORG_NUM,
                    TT.CUST_ID,
                    TT.CUST_NAM;


-- 指标: S71_I_7.1.A.2025
INSERT INTO `S71_I_7.1.A.2025`
         (DATA_DATE,
          ORG_NUM,
          DATA_DEPARTMENT,
          SYS_NAM,
          REP_NUM,
          ITEM_NUM,
          TOTAL_VALUE,
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
          COL_14)
         SELECT T.DATA_DATE,
                T.ORG_NUM,
                T.DEPARTMENTD,
                'CBRC' AS SYS_NAM,
                'S7101' AS REP_NUM,
                'S71_I_7.1.A.2025' AS ITEM_NUM,
                T.LOAN_ACCT_BAL * TT.CCY_RATE AS TOTAL_VALUE,
                T.CUST_ID AS COL_2,
                NVL(C.CUST_NAM, P.CUST_NAM) AS COL_3,
                T.LOAN_NUM AS COL_4,
                T2.FACILITY_AMT AS COL_6,
                T.ACCT_NUM AS COL_7,
                T.DRAWDOWN_DT AS COL_8,
                T.MATURITY_DT AS COL_9,
                T.ITEM_CD AS COL_10,
                T.DEPARTMENTD AS COL_11,
                T3.M_NAME AS COL_12,
                T.CP_NAME AS COL_13,
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
                END AS COL_14
           FROM SMTMODS_L_ACCT_LOAN T
           LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
             ON TT.CCY_DATE = I_DATADATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN SMTMODS_L_CUST_C C --对公表 取小微企业
             ON T.CUST_ID = C.CUST_ID
            AND C.DATA_DATE = I_DATADATE
           LEFT JOIN SMTMODS_L_CUST_P P --对私表 取个体工商户&小微企业主
             ON T.CUST_ID = P.CUST_ID
            AND P.DATA_DATE = I_DATADATE
           LEFT JOIN SMTMODS_V_PUB_IDX_SX_PHJRDKSX T2 --授信额度
             ON T.CUST_ID = T2.CUST_ID
            AND T2.DATA_DATE = I_DATADATE
           LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T3
             ON C.CORP_SCALE = T3.M_CODE
           LEFT JOIN (SELECT *
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
             ON T.LOAN_NUM = F.LOAN_NUM
            AND F.DATA_DATE = I_DATADATE
           LEFT JOIN CBRC_S7101_CREDITLINE_HZ Z
             ON T.CUST_ID = Z.CUST_ID
            AND Z.DATA_DATE = I_DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_STS <> '3'
            AND T.ACCT_TYP NOT LIKE '90%' --不含委托贷款
            AND T.ITEM_CD NOT LIKE '1301%' ---刨除票据
            AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B') --创业担保
            AND T.LOAN_ACCT_BAL <> 0
            AND ((NOT EXISTS (SELECT 1
                                FROM SMTMODS_L_CUST_C C1
                               WHERE C1.DATA_DATE = I_DATADATE
                                 AND C1.CUST_ID = T.CUST_ID
                                 AND C1.CORP_SCALE IN ('S', 'T') --小型 微型
                                 AND SUBSTR(C1.CUST_TYP, 0, 1) IN ('1', '0') -- 企业
                              ) --非小型微型企业
                 AND C.CUST_TYP <> '3' AND
                 P.OPERATE_CUST_TYPE NOT IN ('A', 'B') --非个体工商户、小微企业主
                 AND F.LOAN_NUM IS NULL --非农户
                ) OR ((((C.CUST_TYP <> '3' OR
                P.OPERATE_CUST_TYPE NOT IN ('A', 'B')) --个体工商户、小微企业主
                OR (C.CORP_SCALE IN ('S', 'T') /* 小型 微型*/
                AND SUBSTR(C.CUST_TYP, 0, 1) IN ('1', '0')) --小型微型企业
                ) AND Z.FACILITY_AMT > 10000000 /*授信总额1000万元以上*/
                ) OR (F.LOAN_NUM IS NOT NULL --非农户
                AND Z.FACILITY_AMT > 5000000 /*单户授信总额500万元以上*/
                )));


-- 指标: S71_I_3.3.1.A1.2018
-- 3.3.1其中：残疾人创业担保贷款     贷款余额
          INSERT INTO `S71_I_3.3.1.A1.2018`
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
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
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_3.3.1.A4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_3.3.1.A3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_3.3.1.A2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_3.3.1.A1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND T.LOAN_ACCT_BAL <> 0
               AND CJRCYDBDK = '是';


-- 指标: S71_I_4..C5.2021
-- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO `S71_I_4..C5.2021`
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_13,
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_4..C5.2021' AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXQTGRJYXDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失')--不良贷款
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000;


-- 指标: S71_I_1.5.C2.2018
INSERT INTO `S71_I_1.5.C2.2018`
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
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
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.5.C4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.5.C3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.5.C2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.5.C1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXNMZYHZSDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失');


-- 指标: S71_I_7.F.2025
INSERT INTO `S71_I_7.F.2025`
               (DATA_DATE,
                ORG_NUM,
                DATA_DEPARTMENT,
                SYS_NAM,
                REP_NUM,
                ITEM_NUM,
                TOTAL_VALUE,
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
                COL_13)
               SELECT I_DATADATE,
                      T.ORG_NUM,
                      T.DEPARTMENTD,
                      'CBRC' AS SYS_NAM,
                      'S7101' AS REP_NUM,
                      'S71_I_7.F.2025' AS ITEM_NUM,
                      T.NHSY * TT.CCY_RATE AS TOTAL_VALUE,
                      T.CUST_ID AS COL_2,
                      T.CUST_NAM AS COL_3,
                      T.LOAN_NUM AS COL_4,
                      T.FACILITY_AMT AS COL_6,
                      T.ACCT_NUM AS COL_7,
                      T.DRAWDOWN_DT AS COL_8,
                      T.MATURITY_DT AS COL_9,
                      T.ITEM_CD AS COL_10,
                      T.DEPARTMENTD AS COL_11,
                      T2.M_NAME AS COL_12,
                      T.CP_NAME AS COL_13
                 FROM CBRC_S7101_UNDERTAK_GUAR_INFO T
                 LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
                   ON T.CORP_SCALE = T2.M_CODE
                  AND T2.M_TABLECODE = 'CORP_SCALE'
                 LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
                   ON TT.CCY_DATE = I_DATADATE
                  AND TT.BASIC_CCY = T.CURR_CD
                  AND TT.FORWARD_CCY = 'CNY';


-- 指标: S71_I_1.4.B5.2025
-- 其中：单户授信1000万元（含）以下不含票据融资合计
        INSERT INTO `S71_I_1.4.B5.2025`
          (DATA_DATE,
           ORG_NUM,
           --DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 --T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_1.4.B5.2025' AS ITEM_NUM,
                 '1' AS TOTAL_VALUE, --为了统计户数,定义字段5默认为1,分组后客户不重复,就是1户,结果统计sum值
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3
            FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
           WHERE DATA_DATE = I_DATADATE
             AND PHXXWQYFRZCQDK = '是'
             AND T.LOAN_ACCT_BAL <> 0
             AND ITEM_CD NOT LIKE '1301%' --不含贴现
             AND FACILITY_AMT <= 10000000
           GROUP BY T.DATA_DATE,
                    T.ORG_NUM,
                    T.CUST_ID,
                    T.CUST_NAM;


-- ========== 逻辑组 38: 共 2 个指标 ==========
FROM (
SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_1.2.C4.2025'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_1.2.C3.2025'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_1.2.C2.2025'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_1.2.C1.2025'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14,
                   DECODE(IF_TECH_CORP_TYPE,'1','是','否') AS COL_16,
                   DECODE(IF_HIGH_SALA_CORP,'Y','是','否') AS COL_17,
                   DECODE(IF_GJJSCXSFQY,'Y','是','否') AS COL_18,
                   DECODE(IF_ZCYDXGJQY,'Y','是','否') AS COL_19,
                   DECODE(IF_ZJTXKH,'Y','是','否') AS COL_20,
                   DECODE(IF_ZJTXXJRQY,'Y','是','否') AS COL_21,
                   DECODE(IF_CXXQY,'Y','是','否') AS COL_22
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
             WHERE DATA_DATE = I_DATADATE
               AND PHXKCXWQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失')
) q_38
INSERT INTO `S71_I_1.2.C3.2025` (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
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
             COL_16,
             COL_17,
             COL_18,
             COL_19,
             COL_20,
             COL_21,
             COL_22)
SELECT *
INSERT INTO `S71_I_1.2.C2.2025` (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
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
             COL_16,
             COL_17,
             COL_18,
             COL_19,
             COL_20,
             COL_21,
             COL_22)
SELECT *;

-- 指标: S71_I_1.a.A0.2025
-- 1.a普惠型小型企业法人贷款  单户授信1000万元（含）以下合计 贷款余额
      INSERT INTO `S71_I_1.a.A0.2025`
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE,
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
         COL_14)
        SELECT T.DATA_DATE,
               T.ORG_NUM,
               T.DEPARTMENTD,
               'CBRC' AS SYS_NAM,
               'S7101' AS REP_NUM,
               'S71_I_1.a.A0.2025' AS ITEM_NUM,
               T.LOAN_ACCT_BAL AS TOTAL_VALUE,
               T.CUST_ID AS COL_2,
               T.CUST_NAM AS COL_3,
               T.LOAN_NUM AS COL_4,
               T.FACILITY_AMT AS COL_6,
               T.ACCT_NUM AS COL_7,
               T.DRAWDOWN_DT AS COL_8,
               T.MATURITY_DT AS COL_9,
               T.ITEM_CD AS COL_10,
               T.DEPARTMENTD AS COL_11,
               T.CORP_SCALE AS COL_12,
               T.CP_NAME AS COL_13,
               T.LOAN_GRADE_CD AS COL_14
          FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
         WHERE DATA_DATE = I_DATADATE
           AND PHXXXQYFRDK = '是'
           AND T.LOAN_ACCT_BAL <> 0
           AND FACILITY_AMT <= 10000000;


-- 指标: S71_I_1.1.C5.2022
-- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO `S71_I_1.1.C5.2022`
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             --COL_1,
             COL_2,
             COL_3,
             COL_4,
             --COL_5,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_12,
             COL_13,
             COL_14,
             COL_15)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.1.C5.2022' AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   --T.INST_NAME AS COL_1,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   --T.LOAN_ACCT_BAL AS COL_5,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14,
                   T2.M_NAME AS COL_15
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON REPLACE(REPLACE(T.SNDKFL, 'P_', ''), 'C_', '') = T2.M_CODE
             WHERE DATA_DATE = I_DATADATE
               AND PHXSNXWQYFRDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失')--不良贷款
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000;


-- 指标: S71_I_1.2.D.2025
INSERT INTO `S71_I_1.2.D.2025`
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
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
             COL_16,
             COL_17,
             COL_18,
             COL_19,
             COL_20,
             COL_21,
             COL_22)
            SELECT I_DATADATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_1.2.D.2025' AS ITEM_NUM,
                   T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T2.M_NAME AS COL_12,
                   T.CP_NAME AS COL_13,
                   DECODE(TECH_CORP_TYPE,'1','是','否') AS COL_16,
                   DECODE(IF_HIGH_SALA_CORP,'Y','是','否') AS COL_17,
                   DECODE(IF_GJJSCXSFQY,'Y','是','否') AS COL_18,
                   DECODE(IF_ZCYDXGJQY,'Y','是','否') AS COL_19,
                   DECODE(IF_ZJTXKH,'Y','是','否') AS COL_20,
                   DECODE(IF_ZJTXXJRQY,'Y','是','否') AS COL_21,
                   DECODE(IF_CXXQY,'Y','是','否') AS COL_22
              FROM CBRC_S7101_AMT_TMP1 T
              LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
             WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND T.DATA_DATE <= I_DATADATE
               AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
               AND T.CORP_SCALE IN ('S', 'T') --小微企业
               AND (TECH_CORP_TYPE = '1' --科技型企业类型
                   OR IF_HIGH_SALA_CORP = 'Y' --是否高新技术
                   OR IF_GJJSCXSFQY = 'Y' --是否国家技术创新示范企业
                   OR IF_ZCYDXGJQY = 'Y' --是否制造业单项冠军企业
                   OR IF_ZJTXKH = 'Y' --是否专精特新客户
                   OR IF_ZJTXXJRQY = 'Y' --是否专精特新小巨人企业
                   OR IF_CXXQY = 'Y' --创新型企业
                   );


-- 指标: S71_I_4..A5.2021
-- 其中：单户授信1000万元（含）以下不含票据融资合计

        INSERT INTO `S71_I_4..A5.2021`
          (DATA_DATE,
           ORG_NUM,
           DATA_DEPARTMENT,
           SYS_NAM,
           REP_NUM,
           ITEM_NUM,
           TOTAL_VALUE,
           COL_2,
           COL_3,
           COL_4,
           COL_6,
           COL_7,
           COL_8,
           COL_9,
           COL_10,
           COL_11,
           COL_13,
           COL_14)
          SELECT T.DATA_DATE,
                 T.ORG_NUM,
                 T.DEPARTMENTD,
                 'CBRC' AS SYS_NAM,
                 'S7101' AS REP_NUM,
                 'S71_I_4..A5.2021' AS ITEM_NUM,
                 T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                 T.CUST_ID AS COL_2,
                 T.CUST_NAM AS COL_3,
                 T.LOAN_NUM AS COL_4,
                 T.FACILITY_AMT AS COL_6,
                 T.ACCT_NUM AS COL_7,
                 T.DRAWDOWN_DT AS COL_8,
                 T.MATURITY_DT AS COL_9,
                 T.ITEM_CD AS COL_10,
                 T.DEPARTMENTD AS COL_11,
                 T.CP_NAME AS COL_13,
                 T.LOAN_GRADE_CD AS COL_14
            FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
           WHERE DATA_DATE = I_DATADATE
             AND PHXQTGRJYXDK = '是'
             AND T.LOAN_ACCT_BAL <> 0
             AND ITEM_CD NOT LIKE '1301%' --不含贴现
             AND FACILITY_AMT <= 10000000;


-- 指标: S71_I_1.3.F.2018
INSERT INTO `S71_I_1.3.F.2018`
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_13)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.3.F.2018' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND T.CORP_SCALE IN ('S', 'T') --小微企业
              AND T.UNDERTAK_GUAR_TYPE IN ('A', 'B');


-- 指标: S71_I_1.2.F.2025
INSERT INTO `S71_I_1.2.F.2025`
           (DATA_DATE,
            ORG_NUM,
            DATA_DEPARTMENT,
            SYS_NAM,
            REP_NUM,
            ITEM_NUM,
            TOTAL_VALUE,
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
            COL_16,
            COL_17,
            COL_18,
            COL_19,
            COL_20,
            COL_21,
            COL_22)
           SELECT I_DATADATE,
                  T.ORG_NUM,
                  T.DEPARTMENTD,
                  'CBRC' AS SYS_NAM,
                  'S7101' AS REP_NUM,
                  'S71_I_1.2.F.2025' AS ITEM_NUM,
                  T.NHSY AS TOTAL_VALUE,
                  T.CUST_ID AS COL_2,
                  T.CUST_NAM AS COL_3,
                  T.LOAN_NUM AS COL_4,
                  T.FACILITY_AMT AS COL_6,
                  T.ACCT_NUM AS COL_7,
                  T.DRAWDOWN_DT AS COL_8,
                  T.MATURITY_DT AS COL_9,
                  T.ITEM_CD AS COL_10,
                  T.DEPARTMENTD AS COL_11,
                  T2.M_NAME AS COL_12,
                  T.CP_NAME AS COL_13,
                  DECODE(TECH_CORP_TYPE, '1', '是', '否') AS COL_16,
                  DECODE(IF_HIGH_SALA_CORP, 'Y', '是', '否') AS COL_17,
                  DECODE(IF_GJJSCXSFQY, 'Y', '是', '否') AS COL_18,
                  DECODE(IF_ZCYDXGJQY, 'Y', '是', '否') AS COL_19,
                  DECODE(IF_ZJTXKH, 'Y', '是', '否') AS COL_20,
                  DECODE(IF_ZJTXXJRQY, 'Y', '是', '否') AS COL_21,
                  DECODE(IF_CXXQY, 'Y', '是', '否') AS COL_22
             FROM CBRC_S7101_AMT_TMP1 T
             LEFT JOIN SMTMODS_A_REPT_DWD_MAPPING T2
               ON T.CORP_SCALE = T2.M_CODE
              AND T2.M_TABLECODE = 'CORP_SCALE'
            WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
              AND T.DATA_DATE <= I_DATADATE
              AND SUBSTR(CUST_TYP, 0, 1) IN ('0', '1') -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
              AND T.CORP_SCALE IN ('S', 'T') --小微企业
              AND (TECH_CORP_TYPE = '1' --科技型企业类型
                  OR IF_HIGH_SALA_CORP = 'Y' --是否高新技术
                  OR IF_GJJSCXSFQY = 'Y' --是否国家技术创新示范企业
                  OR IF_ZCYDXGJQY = 'Y' --是否制造业单项冠军企业
                  OR IF_ZJTXKH = 'Y' --是否专精特新客户
                  OR IF_ZJTXXJRQY = 'Y' --是否专精特新小巨人企业
                  OR IF_CXXQY = 'Y' --创新型企业
                  );


-- 指标: S71_I_6.1.B5.2022
-- 其中：单户授信1000万元（含）以下不含票据融资合计
          INSERT INTO `S71_I_6.1.B5.2022`
            (DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_6.1.B5.2022' AS ITEM_NUM,
                   '1' AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND XWQYXYKD = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000
             GROUP BY T.DATA_DATE,
                      T.ORG_NUM,
                      T.CUST_ID,
                      T.CUST_NAM;


-- 指标: S71_I_6.2.D5.2022
-- 其中：单户授信1000万元（含）以下不含票据融资合计

          INSERT INTO `S71_I_6.2.D5.2022`
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
             COL_2,
             COL_3,
             COL_4,
             COL_6,
             COL_7,
             COL_8,
             COL_9,
             COL_10,
             COL_11,
             COL_13)
            SELECT I_DATADATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_6.2.D5.2022' AS ITEM_NUM,
                   T.LOAN_ACCT_AMT AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CP_NAME AS COL_13
              FROM CBRC_S7101_AMT_TMP1 T
             WHERE T.DATA_DATE >= SUBSTR(I_DATADATE, 1, 4) || '0101'
               AND T.DATA_DATE <= I_DATADATE
               AND ((SUBSTR(T.CUST_TYP, 0, 1) IN ('0', '1') AND -- 取企业 20210922  MDF BY CHM  企业规模中含事业单位、民办非企业贷款
                   T.CORP_SCALE IN ('S', 'T')) --小微企业
                OR T.OPERATE_CUST_TYPE IN ('A', 'B', '3')) --个人（A个体工商户和B小微企业主）对公（3个体工商户）
               AND MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) > 12
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000;


-- 指标: S71_I_2..C5.2021
-- 其中：单户授信1000万元（含）以下不含票据融资合计

           INSERT INTO `S71_I_2..C5.2021`
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
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
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   'S71_I_2..C5.2021' AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXQTZZDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失')--不良贷款
               AND ITEM_CD NOT LIKE '1301%' --不含贴现
               AND FACILITY_AMT <= 10000000;


-- 指标: S71_I_2..C2.2018
-- 2.普惠型其它组织贷款 不良贷款余额
          INSERT INTO `S71_I_2..C2.2018`
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE,
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
             COL_14)
            SELECT T.DATA_DATE,
                   T.ORG_NUM,
                   T.DEPARTMENTD,
                   'CBRC' AS SYS_NAM,
                   'S7101' AS REP_NUM,
                   CASE
                     WHEN T.SXFW = '单户授信1000-3000万元（含）' THEN
                      'S71_I_2..C4.2018'
                     WHEN T.SXFW = '单户授信500-1000万元（含）' THEN
                      'S71_I_2..C3.2018'
                     WHEN T.SXFW = '单户授信100-500万元（含）' THEN
                      'S71_I_2..C2.2018'
                     WHEN T.SXFW = '单户授信100万元（含）以下' THEN
                      'S71_I_2..C1.2018'
                   END AS ITEM_NUM,
                   T.LOAN_ACCT_BAL AS TOTAL_VALUE,
                   T.CUST_ID AS COL_2,
                   T.CUST_NAM AS COL_3,
                   T.LOAN_NUM AS COL_4,
                   T.FACILITY_AMT AS COL_6,
                   T.ACCT_NUM AS COL_7,
                   T.DRAWDOWN_DT AS COL_8,
                   T.MATURITY_DT AS COL_9,
                   T.ITEM_CD AS COL_10,
                   T.DEPARTMENTD AS COL_11,
                   T.CORP_SCALE AS COL_12,
                   T.CP_NAME AS COL_13,
                   T.LOAN_GRADE_CD AS COL_14
              FROM SMTMODS_L_V_PUB_IDX_DK_PHJRDK T
             WHERE DATA_DATE = I_DATADATE
               AND PHXQTZZDK = '是'
               AND T.LOAN_ACCT_BAL <> 0
               AND LOAN_GRADE_CD IN ('次级', '可疑', '损失');


