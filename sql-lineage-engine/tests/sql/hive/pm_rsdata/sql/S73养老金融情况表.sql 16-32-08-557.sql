-- ============================================================
-- 文件名: S73养老金融情况表.sql
-- 生成时间: 2025-12-18 13:53:41
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: S73.1.A
--begin01 明细需求 zhoulp20250814
    

    --户数
    INSERT INTO `S73.1.A`
      (DATA_DATE,
       ORG_NUM,
       --DATA_DEPARTMENT,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       COL_2, --字段2(客户号)
       COL_3, --字段3(客户名)
       TOTAL_VALUE --字段5(贷款余额/贷款金额/客户数/贷款收益)
       )
      SELECT I_DATADATE,
             T.ORG_NUM, --机构号
             --T.DEPARTMENTD,--数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'S73.1.A' AS ITEM_NUM,
             T.CUST_ID AS COL_2, --字段2(客户号)
             T.CUST_NAM AS COL_3, --字段3(客户名)
             1 AS TOTAL_VALUE --字段5(贷款余额/贷款金额/客户数/贷款收益)
        FROM (SELECT DISTINCT CUST_ID, ORG_NUM, CUST_NAM--, DEPARTMENTD --归属部门
                FROM CBRC_S73_LOAN_TEMP
               WHERE SUBSTR(DATA_DATE, 1, 4) = SUBSTR(I_DATADATE, 1, 4)
                 AND YL_FLAG = 'Y') T;


-- 指标: S73.9.3.C
INSERT INTO `S73.9.3.C`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN T.ORG_NUM LIKE '060101%' THEN
          '060300'
         WHEN T.ORG_NUM NOT LIKE '__98%' AND
              substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
          SUBSTR(T.ORG_NUM, 1, 4) || '00'
         ELSE
          T.ORG_NUM
       END ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.9.3.C' AS ITEM_NUM,
       SUM(T.AMT * NVL(U.CCY_RATE, 0)),
       '2'
        FROM SMTMODS_L_TRAN_FINANCE_FUND T --代理代销交易表
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
        LEFT JOIN SMTMODS_L_FIMM_PRODUCT P --理财产品信息表
          ON T.PROD_CODE = P.PRODUCT_CODE
         AND P.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON t.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       WHERE TO_CHAR(T.TRAN_DATE, 'YYYYMMDD') BETWEEN
             substr(I_DATADATE, 1, 4) || '0101' AND I_DATADATE --交易日期为本年
         AND (T.BUSINESS_TYPE IN ('2', '3', '5') or
              (T.BUSINESS_TYPE = '1' AND P.CASH_MANAGE_PRODUCT_FLG = 'N'))
         AND ((SUBSTR(C.ID_TYPE, 1, 2) = '10' AND SUBSTR(I_DATADATE, 1, 4) - case
                when func_pbocd_date_flg(SUBSTR(DECODE(C.ID_NO,
                                                          NULL,
                                                          '00000020240000',
                                                          C.ID_NO),
                                                   7,
                                                   8)) = 1 then
                 SUBSTR(DECODE(C.ID_NO, NULL, '00000020240000', C.ID_NO),
                        7,
                        4)
                else
                 SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4)
              end >= 55) OR
              (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
              SUBSTR(I_DATADATE, 1, 4) -
              SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) >= 55))
       GROUP BY CASE
                  WHEN T.ORG_NUM LIKE '060101%' THEN
                   '060300'
                  WHEN T.ORG_NUM NOT LIKE '__98%' AND
                       substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
                   SUBSTR(T.ORG_NUM, 1, 4) || '00'
                  ELSE
                   T.ORG_NUM
                END;


-- 指标: S73.9.1.A
--9.1存款
    INSERT INTO `S73.9.1.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.9.1.A' AS ITEM_NUM,
       COUNT(*) AS LOAN_ACCT_BAL_RMB,
       '2'
        FROM (SELECT A.ORG_NUM, A.CUST_ID
                FROM SMTMODS_L_ACCT_DEPOSIT A
               INNER JOIN SMTMODS_L_CUST_P C
                  ON A.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE TT
                  ON TT.DATA_DATE = A.DATA_DATE
                 AND TT.BASIC_CCY = A.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                  AND ( A.GL_ITEM_CODE LIKE '201101%' --个人贷款
            OR A.GL_ITEM_CODE LIKE '224101%' ) --[JLBA202507210012][石雨][修改内容：修改内容：新增22410102个人久悬未取款]
                 AND A.ACCT_BALANCE <> 0
                 AND A.ACCT_STS NOT LIKE 'C%'
                 AND ((SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                     SUBSTR(I_DATADATE, 1, 4) - case
                       when func_pbocd_date_flg(SUBSTR(DECODE(C.ID_NO,
                                                                 NULL,
                                                                 '00000020240000',
                                                                 C.ID_NO),
                                                          7,
                                                          8)) = 1 then
                        SUBSTR(DECODE(C.ID_NO,
                                      NULL,
                                      '00000020240000',
                                      C.ID_NO),
                               7,
                               4)
                       else
                        SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4)
                     end >= 55) OR
                     (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                     SUBSTR(I_DATADATE, 1, 4) -
                     SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) >= 55))
               GROUP BY A.ORG_NUM, A.CUST_ID) A
       GROUP BY A.ORG_NUM;


-- 指标: S73.9.3.A
INSERT INTO `S73.9.3.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN T.ORG_NUM LIKE '060101%' THEN
          '060300'
         WHEN T.ORG_NUM NOT LIKE '__98%' AND
              substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
          SUBSTR(T.ORG_NUM, 1, 4) || '00'
         ELSE
          T.ORG_NUM
       END ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.9.3.A' AS ITEM_NUM,
       count(*),
       '2'
        FROM (SELECT T.ORG_NUM, T.CUST_ID
                FROM SMTMODS_L_TRAN_FINANCE_FUND T --代理代销交易表
                LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = T.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT P --理财产品信息表
                  ON T.PROD_CODE = P.PRODUCT_CODE
                 AND P.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_CUST_P C
                  ON t.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
               WHERE TO_CHAR(T.TRAN_DATE, 'YYYYMMDD') BETWEEN
                     substr(I_DATADATE, 1, 4) || '0101' AND I_DATADATE --交易日期为本年
                 AND (T.BUSINESS_TYPE IN ('2', '3', '5') or
                      (T.BUSINESS_TYPE = '1' AND
                      P.CASH_MANAGE_PRODUCT_FLG = 'N'))
                 AND ((SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                      SUBSTR(I_DATADATE, 1, 4) - case
                        when func_pbocd_date_flg(SUBSTR(DECODE(C.ID_NO,
                                                                  NULL,
                                                                  '00000020240000',
                                                                  C.ID_NO),
                                                           7,
                                                           8)) = 1 then
                         SUBSTR(DECODE(C.ID_NO,
                                       NULL,
                                       '00000020240000',
                                       C.ID_NO),
                                7,
                                4)
                        else
                         SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4)
                      end >= 55) OR
                      (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                      SUBSTR(I_DATADATE, 1, 4) -
                      SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) >= 55))
               GROUP BY T.ORG_NUM, T.CUST_ID) T
       GROUP BY CASE
                  WHEN T.ORG_NUM LIKE '060101%' THEN
                   '060300'
                  WHEN T.ORG_NUM NOT LIKE '__98%' AND
                       substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
                   SUBSTR(T.ORG_NUM, 1, 4) || '00'
                  ELSE
                   T.ORG_NUM
                END;


-- 指标: S73.8.C
INSERT INTO `S73.8.C`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN T.ORG_NUM LIKE '060101%' THEN
          '060300'
         WHEN T.ORG_NUM NOT LIKE '__98%' AND
              substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
          SUBSTR(T.ORG_NUM, 1, 4) || '00'
         ELSE
          T.ORG_NUM
       END ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.8.C' AS ITEM_NUM,
       SUM(T.AMT * NVL(U.CCY_RATE, 0)),
       '2'
        FROM SMTMODS_L_TRAN_FINANCE_FUND T --代理代销交易表
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE TO_CHAR(T.TRAN_DATE, 'YYYYMMDD') BETWEEN
             substr(I_DATADATE, 1, 4) || '0101' AND I_DATADATE --交易日期为本年
         AND T.PROD_CODE IN ('006861', '006862')
       GROUP BY CASE
                  WHEN T.ORG_NUM LIKE '060101%' THEN
                   '060300'
                  WHEN T.ORG_NUM NOT LIKE '__98%' AND
                       substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
                   SUBSTR(T.ORG_NUM, 1, 4) || '00'
                  ELSE
                   T.ORG_NUM
                END;


-- 指标: S73.1.F
--begin03 明细需求 zhoulp20250814
   

    --收益
    INSERT INTO `S73.1.F`
      (data_date,
       org_num,
       DATA_DEPARTMENT,--数据条线
       sys_nam,
       rep_num,
       item_num,
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_7, --字段7(放款日期)
       COL_8, --字段8(原始借据到期日期)
       COL_14, --字段14（贷款投向）
       COL_15 --字段15（养老产业贷款类型）
       )
      SELECT I_DATADATE,
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,--数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'S73.1.F' AS ITEM_NUM,
             T.CUST_ID AS col_2, --字段2(客户号)
             T.CUST_NAM AS col_3, --字段3(客户名)
             T.LOAN_NUM AS col_4, --字段4(贷款编号)
             T.NHSY * TT.CCY_RATE AS TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
             T.DRAWDOWN_DT AS COL_7, --字段7(放款日期)
             T.MATURITY_DT AS COL_8, --字段8(原始借据到期日期)
             T.LOAN_PURPOSE_CD AS COL_15, --字段15(贷款投向)
             T.PENSION_INDUSTRY AS COL_15 --字段15（养老产业贷款类型）
        FROM CBRC_S73_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY';


-- 指标: S73.9.1.B
INSERT INTO `S73.9.1.B`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.9.1.B' AS ITEM_NUM,
       SUM(A.ACCT_BALANCE * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
       '2'
        FROM SMTMODS_L_ACCT_DEPOSIT A
       INNER JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
          AND ( A.GL_ITEM_CODE LIKE '201101%' --个人贷款
            OR A.GL_ITEM_CODE LIKE '224101%' ) --[JLBA202507210012][石雨][修改内容：修改内容：新增22410102个人久悬未取款]
         AND A.ACCT_BALANCE <> 0
         AND A.ACCT_STS NOT LIKE 'C%'
         AND ((SUBSTR(C.ID_TYPE, 1, 2) = '10' AND SUBSTR(I_DATADATE, 1, 4) - case
               when func_pbocd_date_flg(SUBSTR(DECODE(C.ID_NO,
                                                         NULL,
                                                         '00000020240000',
                                                         C.ID_NO),
                                                  7,
                                                  8)) = 1 then
                SUBSTR(DECODE(C.ID_NO, NULL, '00000020240000', C.ID_NO),
                       7,
                       4)
               else
                SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4)
             end >= 55) OR
             (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
             SUBSTR(I_DATADATE, 1, 4) -
             SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) >= 55))
       GROUP BY A.ORG_NUM;


-- 指标: S73.1.B
--begin02 明细需求 zhoulp20250814
    

    --累放
    INSERT INTO `S73.1.B`
      (data_date,
       org_num,
       DATA_DEPARTMENT,
       sys_nam,
       rep_num,
       item_num,
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_7, --字段7(放款日期)
       COL_8, --字段8(原始借据到期日期)
       COL_14, --字段14（贷款投向）
       COL_15 --字段15（养老产业贷款类型）
       )
      SELECT I_DATADATE,
             T.ORG_NUM, --机构号
             T.DEPARTMENTD,--数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'S73.1.B' AS ITEM_NUM,
             T.CUST_ID AS col_2, --字段2(客户号)
             T.CUST_NAM AS col_3, --字段3(客户名)
             T.LOAN_NUM AS col_4, --字段4(贷款编号)
             T.LOAN_ACCT_AMT * TT.CCY_RATE AS TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
             T.DRAWDOWN_DT AS COL_7, --字段7(放款日期)
             T.MATURITY_DT AS COL_8, --字段8(原始借据到期日期)
             T.LOAN_PURPOSE_CD AS COL_15, --字段15(贷款投向)
             T.PENSION_INDUSTRY AS COL_15 --字段15（养老产业贷款类型）
        FROM CBRC_S73_LOAN_TEMP T
        LEFT JOIN SMTMODS_L_PUBL_RATE TT --汇率表
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = T.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE T.YL_FLAG = 'Y';


-- 指标: S73.1.D
--begin05 明细需求 zhoulp20250814
    

    --中长期
    INSERT INTO `S73.1.D`
      (data_date,
       org_num,
       DATA_DEPARTMENT,--数据条线
       sys_nam,
       rep_num,
       item_num,
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_6, --字段6(贷款合同编号)
       COL_7, --字段7(放款日期)
       COL_8, --字段8(原始借据到期日期)
       COL_15 --字段15（养老产业贷款类型）
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,--数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'S73.1.D' AS ITEM_NUM,
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
             A.ACCT_NUM AS col_6, --字段6(贷款合同编号)
             A.DRAWDOWN_DT AS COL_7, --字段7(放款日期)
             A.MATURITY_DT AS COL_8, --字段8(原始借据到期日期)
             CASE
               WHEN A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%' THEN
                A.PENSION_INDUSTRY
               ELSE
                D.PENSION_INDUSTRY
             END AS COL_15 --字段15（养老产业贷款类型）
        FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
         AND SUBSTR(D.PENSION_INDUSTRY, 1, 2) IN
             ('01',
              '02',
              '03',
              '04',
              '05',
              '06',
              '07',
              '08',
              '09',
              '10',
              '11',
              '12')
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND
             D.PENSION_INDUSTRY IS NOT NULL) OR
             ((ITEM_CD LIKE '130101%' OR ITEM_CD LIKE '130104%') AND
             SUBSTR(A.PENSION_INDUSTRY, 1, 2) IN
             ('01',
                '02',
                '03',
                '04',
                '05',
                '06',
                '07',
                '08',
                '09',
                '10',
                '11',
                '12')))
         AND MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12 --中长期;


-- 指标: S73.9.2.A
--9.2贷款
    INSERT INTO `S73.9.2.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.9.2.A' AS ITEM_NUM,
       COUNT(*) AS LOAN_ACCT_BAL_RMB,
       '2'
        FROM (SELECT A.ORG_NUM, A.CUST_ID
                FROM SMTMODS_L_ACCT_LOAN A
                LEFT JOIN SMTMODS_L_CUST_P C
                  ON A.CUST_ID = C.CUST_ID
                 AND C.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE TT
                  ON TT.DATA_DATE = A.DATA_DATE
                 AND TT.BASIC_CCY = A.CURR_CD
                 AND TT.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ACCT_TYP LIKE '01%' --个人贷款
                 AND A.CANCEL_FLG = 'N'
                 AND LENGTHB(A.ACCT_NUM) < 36
                 AND A.LOAN_ACCT_BAL <> 0
                 AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
                 AND ((SUBSTR(C.ID_TYPE, 1, 2) = '10' AND
                     SUBSTR(I_DATADATE, 1, 4) - case
                       when func_pbocd_date_flg(SUBSTR(DECODE(C.ID_NO,
                                                                 NULL,
                                                                 '00000020240000',
                                                                 C.ID_NO),
                                                          7,
                                                          8)) = 1 then
                        SUBSTR(DECODE(C.ID_NO,
                                      NULL,
                                      '00000020240000',
                                      C.ID_NO),
                               7,
                               4)
                       else
                        SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4)
                     end >= 55) OR
                     (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
                     SUBSTR(I_DATADATE, 1, 4) -
                     SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) >= 55))
               GROUP BY A.ORG_NUM, A.CUST_ID) A
       GROUP BY A.ORG_NUM;


-- 指标: S73.1.E
--begin06 明细需求 zhoulp20250814
    

    --不良贷款
    INSERT INTO `S73.1.E`
      (data_date,
       org_num,
       DATA_DEPARTMENT,--数据条线
       sys_nam,
       rep_num,
       item_num,
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_6, --字段6(贷款合同编号)
       COL_7, --字段7(放款日期)
       COL_8, --字段8(原始借据到期日期)
       COL_9, --字段9(五级分类)
       COL_15 --字段15（养老产业贷款类型）
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,--数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'S73.1.E' AS ITEM_NUM,
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
             A.ACCT_NUM AS col_6, --字段6(贷款合同编号)
             A.DRAWDOWN_DT AS COL_7, --字段7(放款日期)
             A.MATURITY_DT AS COL_8, --字段8(原始借据到期日期)
             A.LOAN_GRADE_CD AS COL_9, --字段9(五级分类)
             CASE
               WHEN A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%' THEN
                A.PENSION_INDUSTRY
               ELSE
                D.PENSION_INDUSTRY
             END AS COL_15 --字段15（养老产业贷款类型）
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
         AND SUBSTR(D.PENSION_INDUSTRY, 1, 2) IN
             ('01',
              '02',
              '03',
              '04',
              '05',
              '06',
              '07',
              '08',
              '09',
              '10',
              '11',
              '12')
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND
             D.PENSION_INDUSTRY IS NOT NULL) OR
             ((ITEM_CD LIKE '130101%' OR ITEM_CD LIKE '130104%') AND
             SUBSTR(A.PENSION_INDUSTRY, 1, 2) IN
             ('01',
                '02',
                '03',
                '04',
                '05',
                '06',
                '07',
                '08',
                '09',
                '10',
                '11',
                '12')))
         AND A.LOAN_GRADE_CD IN ('3', '4', '5') --不良贷款;


-- 指标: S73.8.A
--8.代销养老金融产品
    INSERT INTO `S73.8.A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN T.ORG_NUM LIKE '060101%' THEN
          '060300'
         WHEN T.ORG_NUM NOT LIKE '__98%' AND
              substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
          SUBSTR(T.ORG_NUM, 1, 4) || '00'
         ELSE
          T.ORG_NUM
       END ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.8.A' AS ITEM_NUM,
       COUNT(*),
       '2'
        FROM (SELECT T.ORG_NUM, T.CUST_ID
                FROM SMTMODS_L_TRAN_FINANCE_FUND T --代理代销交易表
                LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = T.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE TO_CHAR(T.TRAN_DATE, 'YYYYMMDD') BETWEEN
                     substr(I_DATADATE, 1, 4) || '0101' AND I_DATADATE --交易日期为本年
                 AND T.PROD_CODE IN ('006861', '006862')
               GROUP BY T.ORG_NUM, T.CUST_ID) T
       GROUP BY CASE
                  WHEN T.ORG_NUM LIKE '060101%' THEN
                   '060300'
                  WHEN T.ORG_NUM NOT LIKE '__98%' AND
                       substr(T.ORG_NUM, 1, 1) not in ('5', '6', '7') THEN
                   SUBSTR(T.ORG_NUM, 1, 4) || '00'
                  ELSE
                   T.ORG_NUM
                END;


-- 指标: S73.9.2.B
INSERT INTO `S73.9.2.B`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'CBRC' AS SYS_NAM, --模块简称
       'S73' AS REP_NUM, --报表编号
       'S73.9.2.B' AS ITEM_NUM,
       SUM(A.LOAN_ACCT_BAL * TT.CCY_RATE) AS LOAN_ACCT_BAL_RMB,
       '2'
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE TT
          ON TT.DATA_DATE = A.DATA_DATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP LIKE '01%' --个人贷款
         AND A.CANCEL_FLG = 'N'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.LOAN_ACCT_BAL <> 0
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
         AND ((SUBSTR(C.ID_TYPE, 1, 2) = '10' AND SUBSTR(I_DATADATE, 1, 4) - case
               when func_pbocd_date_flg(SUBSTR(DECODE(C.ID_NO,
                                                         NULL,
                                                         '00000020240000',
                                                         C.ID_NO),
                                                  7,
                                                  8)) = 1 then
                SUBSTR(DECODE(C.ID_NO, NULL, '00000020240000', C.ID_NO),
                       7,
                       4)
               else
                SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4)
             end >= 55) OR
             (SUBSTR(C.ID_TYPE, 1, 2) <> '10' AND
             SUBSTR(I_DATADATE, 1, 4) -
             SUBSTR(TO_CHAR(C.BIRTH_DT, 'YYYYMMDD'), 1, 4) >= 55))
       GROUP BY A.ORG_NUM;


-- 指标: S73.1.C
--begin04 明细需求 zhoulp20250814
   

    --贷款余额
    INSERT INTO `S73.1.C`
      (data_date,
       org_num,
       DATA_DEPARTMENT,--数据条线
       sys_nam,
       rep_num,
       item_num,
       col_2, --字段2(客户号)
       col_3, --字段3(客户名)
       col_4, --字段4(贷款编号)
       TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
       COL_6, --字段6(贷款合同编号)
       COL_7, --字段7(放款日期)
       COL_8, --字段8(原始借据到期日期)
       COL_15 --字段15（养老产业贷款类型）
       )
      SELECT I_DATADATE,
             A.ORG_NUM, --机构号
             A.DEPARTMENTD,--数据条线
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'S73.1.C' AS ITEM_NUM,
             A.CUST_ID AS col_2, --字段2(客户号)
             L.CUST_NAM AS col_3, --字段3(客户名)
             A.LOAN_NUM AS col_4, --字段4(贷款编号)
             NVL(A.LOAN_ACCT_BAL * B.CCY_RATE, 0) +
             NVL(A.INT_ADJEST_AMT * B.CCY_RATE, 0) AS TOTAL_VALUE, --字段5(贷款余额/贷款金额/客户数/贷款收益)
             A.ACCT_NUM AS col_6, --字段6(贷款合同编号)
             A.DRAWDOWN_DT AS COL_7, --字段7(放款日期)
             A.MATURITY_DT AS COL_8, --字段8(原始借据到期日期)
             CASE
               WHEN A.ITEM_CD LIKE '130101%' OR A.ITEM_CD LIKE '130104%' THEN
                A.PENSION_INDUSTRY
               ELSE
                D.PENSION_INDUSTRY
             END AS COL_15 --字段15（养老产业贷款类型）

        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND B.CCY_DATE = D_DATADATE_CCY
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT D
          ON D.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM = D.CONTRACT_NUM
         AND SUBSTR(D.PENSION_INDUSTRY, 1, 2) IN
             ('01',
              '02',
              '03',
              '04',
              '05',
              '06',
              '07',
              '08',
              '09',
              '10',
              '11',
              '12')
        LEFT JOIN SMTMODS_L_CUST_ALL L
          ON A.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       WHERE A.FUND_USE_LOC_CD = 'I'
         AND LENGTHB(A.ACCT_NUM) < 36
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         AND A.CANCEL_FLG = 'N'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250228 JLBA202408200012 资产未转让
            --AND A.LOAN_PURPOSE_CD IN ('Q8514', 'Q8416') --Q8514老年人、残疾人养护服务  Q8416疗养院
         AND (((A.ACCT_TYP NOT LIKE '01%' OR A.ACCT_TYP LIKE '0102%') AND
             A.ACCT_TYP NOT LIKE '0301%' AND
             D.PENSION_INDUSTRY IS NOT NULL) OR
             ((ITEM_CD LIKE '130101%' OR ITEM_CD LIKE '130104%') AND
             SUBSTR(A.PENSION_INDUSTRY, 1, 2) IN
             ('01',
                '02',
                '03',
                '04',
                '05',
                '06',
                '07',
                '08',
                '09',
                '10',
                '11',
                '12')));


