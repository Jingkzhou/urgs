-- ============================================================
-- 文件名: G01资产负债项目统计表附注2.sql
-- 生成时间: 2025-12-18 13:53:37
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 5 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE, -- 数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
       'CBRC' AS SYS_NAM, -- 模块简称
       'G01_2' AS REP_NUM, -- 报表编号
       CASE
         WHEN LOAN_GRADE_CD = '1' OR LOAN_GRADE_CD IS NULL THEN
          'G01_2_1.1.C'
         WHEN LOAN_GRADE_CD = '2' THEN
          'G01_2_1.2.C'
         WHEN LOAN_GRADE_CD = '3' THEN
          'G01_2_1.3.C'
         WHEN LOAN_GRADE_CD = '4' THEN
          'G01_2_1.4.C'
         WHEN LOAN_GRADE_CD = '5' THEN
          'G01_2_1.5.C'
       END AS ITEM_NUM, -- 指标号
       A.LOAN_ACCT_BAL * NVL(U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
       A.ACCT_NUM AS COL_1, -- 合同号
       A.LOAN_NUM AS COL_2, -- 借据号
       A.CUST_ID AS COL_3, -- 客户号
       A.DRAWDOWN_AMT AS COL_4, -- 放款金额
       A.DRAWDOWN_DT AS COL_5, -- 放款日期
       A.MATURITY_DT AS COL_6, -- 原始到期日期
       A.ITEM_CD AS COL_7, -- 科目号
       A.CURR_CD AS COL_8, -- 币种
       A.ACCT_TYP AS COL_9, -- 账户类型
       A.LOAN_GRADE_CD AS COL_10 -- 五级分类代码
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = a.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
       WHERE A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND A.ACCT_STS <> '3'
         and a.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.LOAN_ACCT_BAL <> 0;

INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (ORG_NUM, --机构号
       ITEM_NUM, --报表类型
       ITEM_VAL --指标值
       )

      --买断式转贴现数据
      SELECT ORG_NUM AS ORG_NUM,
             CASE
               WHEN GRADE = '1' OR GRADE IS NULL THEN
                'G01_2_1.1.C'
               WHEN GRADE = '2' THEN
                'G01_2_1.2.C'
               WHEN GRADE = '3' THEN
                'G01_2_1.3.C'
               WHEN GRADE = '4' THEN
                'G01_2_1.4.C'
               WHEN GRADE = '5' THEN
                'G01_2_1.5.C'
             END AS ITEM_NUM,
             sum(NVL(FACE_VAL * u.ccy_rate, 0) ) AS ITEM_VAL
        FROM SMTMODS_L_ACCT_FUND_INVEST A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = a.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
       WHERE A.INVEST_TYP = '11' --买断式转贴现
         AND A.DATA_DATE = I_DATADATE
       group by a.org_num, a.GRADE
      UNION ALL
      --信用卡数据
      --alter by 20240224 shiyu  JLBA202412040012
      SELECT '009803' AS ORG_NUM,
             case
               when LXQKQS >= 7 then
                'G01_2_1.5.C'
               when LXQKQS between 5 and 6 then
                'G01_2_1.4.C'
               when LXQKQS = 4 then
                'G01_2_1.3.C'
               when LXQKQS between 1 and 3 then
                'G01_2_1.2.C'
               else
                'G01_2_1.1.C'
             end as ITEM_NUM,
             SUM((T.M0 + T.M1 + T.M2 + T.M3 + T.M4 + T.M5 + T.M6 + T.M6_UP) *
                 R.CCY_RATE) as ITEM_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
       group by case
                  when LXQKQS >= 7 then
                   'G01_2_1.5.C'
                  when LXQKQS between 5 and 6 then
                   'G01_2_1.4.C'
                  when LXQKQS = 4 then
                   'G01_2_1.3.C'
                  when LXQKQS between 1 and 3 then
                   'G01_2_1.2.C'
                  else
                   'G01_2_1.1.C'
                end
) q_0
INSERT INTO `G01_2_1.4.C` (DATA_DATE,  
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
INSERT INTO `G01_2_1.3.C` (DATA_DATE,  
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
INSERT INTO `G01_2_1.5.C` (DATA_DATE,  
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
INSERT INTO `G01_2_1.1.C` (DATA_DATE,  
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
INSERT INTO `G01_2_1.2.C` (DATA_DATE,  
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

-- 指标: G01_2_2.A.2016
------------------------------------------------------------------------------------------------------------------------------------------------
    /*      以下逻辑处理逾期贷款总数 逻辑    指标编号  G01_2_2.A.2016        */

    INSERT INTO `G01_2_2.A.2016`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       COL_1, -- 字段1(合同号)
       COL_2, -- 字段2(借据号)
       COL_3, -- 字段3(客户号)
       COL_4, -- 字段4(放款金额)
       COL_5, -- 字段5(放款日期)
       COL_6, -- 字段6(原始到期日期)
       COL_7, -- 字段7(科目号)
       COL_8, -- 字段8(币种)
       COL_9, -- 字段9(账户类型)
       COL_10, -- 字段10(五级分类代码)
       COL_11 -- 字段11(逾期天数)
       )
      SELECT 
       I_DATADATE AS DATA_DATE, -- 数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
       'CBRC' AS SYS_NAM, -- 模块简称
       'G01_2' AS REP_NUM, -- 报表编号
       'G01_2_2.A.2016' AS ITEM_NUM, -- 指标号
       A.LOAN_ACCT_BAL * NVL(U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
       A.ACCT_NUM AS COL_1, -- 合同号
       A.LOAN_NUM AS COL_2, -- 借据号
       A.CUST_ID AS COL_3, -- 客户号
       A.DRAWDOWN_AMT AS COL_4, -- 放款金额
       A.DRAWDOWN_DT AS COL_5, -- 放款日期
       A.MATURITY_DT AS COL_6, -- 原始到期日期
       A.ITEM_CD AS COL_7, -- 科目号
       A.CURR_CD AS COL_8, -- 币种
       A.ACCT_TYP AS COL_9, -- 账户类型
       A.LOAN_GRADE_CD AS COL_10, -- 五级分类代码
       A.OD_DAYs AS COL_11 -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN a
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = a.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYs <= 90
         and OD_DAYs > 0
         AND OD_FLG = 'Y'
            -- AND VERSION_CBRC = 'CBRC'
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND a.DATA_DATE = I_DATADATE
         AND ORG_NUM <> '009803'
         AND (ACCT_TYP NOT LIKE '0101%' AND ACCT_TYP NOT LIKE '0103%' AND
             ACCT_TYP NOT LIKE '0104%' AND ACCT_TYP NOT LIKE '0199%' AND
             ACCT_TYP not in ('E01', 'E02') and ACCT_TYP NOT LIKE '90%' /*ACCT_TYP <> 'E01'*/
             ) --20170826MANAN
         and a.item_cd not like '130105%'
         and a.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
            --and A.DATE_SOURCESD NOT IN ('10301057','10301059')   --ALTER BY ZYH 20210706 10301057|10301059:吉林银行众享贷贷款 这种贷款在2019年已全部结清，新信贷不承接结清旧数据
         AND A.LOAN_ACCT_BAL <> 0;

INSERT INTO `G01_2_2.A.2016`
      (ORG_NUM, --机构号
       ITEM_NUM, --报表类型
       ITEM_VAL --指标值
       )

      --信用卡逾期调整alter by 20240224 shiyu  JLBA202412040012
      select '009803' ORG_NUM,
             'G01_2_2.A.2016' as ITEM_NUM,
             SUM((NVL(T.M0, 0) + nvl(T.M1, 0) + nvl(T.M2, 0) + nvl(T.M3, 0) +
                 nvl(T.M4, 0) + nvl(T.M5, 0) + nvl(T.M6, 0) +
                 nvl(T.M6_UP, 0)) * R.CCY_RATE)

             as ITEM_VAL
        from SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and T.LXQKQS > 0;

INSERT INTO `G01_2_2.A.2016`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       COL_1, -- 字段1(合同号)
       COL_2, -- 字段2(借据号)
       COL_3, -- 字段3(客户号)
       COL_4, -- 字段4(放款金额)
       COL_5, -- 字段5(放款日期)
       COL_6, -- 字段6(原始到期日期)
       COL_7, -- 字段7(科目号)
       COL_8, -- 字段8(币种)
       COL_9, -- 字段9(账户类型)
       COL_10, -- 字段10(五级分类代码)
       COL_11, -- 字段11(逾期天数)
       COL_12, -- 字段12(还款方式)
       COL_13 -- 字段13(还款方式_2)
       )
      SELECT 
       I_DATADATE AS DATA_DATE, -- 数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
       'CBRC' AS SYS_NAM, -- 模块简称
       'G01_2' AS REP_NUM, -- 报表编号
       'G01_2_2.A.2016' AS ITEM_NUM, -- 指标号
       /*alter by shiyu 20241105 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
       如果是按月分期还款的个人消费贷款本金或利息逾期 */
       case
       -- alter by 20240224 shiyu  JLBA202412040012
         when A.PAY_TYPE in ('01', '02', '10', '11') and A.REPAY_TYP = '1' then --还款方式为按月
          A.OD_LOAN_ACCT_BAL * U.CCY_RATE
         else
          A.LOAN_ACCT_BAL * U.CCY_RATE
       end AS TOTAL_VALUE, -- 汇总值
       A.ACCT_NUM AS COL_1, -- 合同号
       A.LOAN_NUM AS COL_2, -- 借据号
       A.CUST_ID AS COL_3, -- 客户号
       A.DRAWDOWN_AMT AS COL_4, -- 放款金额
       A.DRAWDOWN_DT AS COL_5, -- 放款日期
       A.MATURITY_DT AS COL_6, -- 原始到期日期
       A.ITEM_CD AS COL_7, -- 科目号
       A.CURR_CD AS COL_8, -- 币种
       A.ACCT_TYP AS COL_9, -- 账户类型
       A.LOAN_GRADE_CD AS COL_10, -- 五级分类代码
       A.OD_DAYs AS COL_11, -- 逾期天数
       A.PAY_TYPE AS COL_12, -- 还款方式
       A.REPAY_TYP AS COL_13 -- 还款方式_2
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = a.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYs > 0
         and OD_DAYs <= 90
         AND OD_FLG = 'Y'
            --AND VERSION_CBRC = 'CBRC'
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND (ACCT_TYP LIKE '0101%' OR ACCT_TYP LIKE '0103%' OR
             ACCT_TYP LIKE '0104%' OR ACCT_TYP LIKE '0199%') /*OR ACCT_TYP = 'E01'*/
         and ACCT_TYP NOT LIKE '90%'
            --and A.DATE_SOURCESD NOT IN ('10301057', '10301059') --ALTER BY ZYH 20210706 10301057|10301059:吉林银行众享贷贷款 这种贷款在2019年已全部结清，新信贷不承接结清旧数据
         and a.item_cd not like '130105%'
         AND ORG_NUM <> '009803'
         and a.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.LOAN_ACCT_BAL <> 0;

INSERT INTO `G01_2_2.A.2016`
    (DATA_DATE, -- 数据日期
     ORG_NUM, -- 机构号
     DATA_DEPARTMENT, -- 数据条线
     SYS_NAM, -- 模块简称
     REP_NUM, -- 报表编号
     ITEM_NUM, -- 指标号
     TOTAL_VALUE, -- 汇总值
     COL_1, -- 字段1(合同号)
     COL_2, -- 字段2(借据号)
     COL_3, -- 字段3(客户号)
     COL_4, -- 字段4(放款金额)
     COL_5, -- 字段5(放款日期)
     COL_6, -- 字段6(原始到期日期)
     COL_7, -- 字段7(科目号)
     COL_8, -- 字段8(币种)
     COL_9, -- 字段9(账户类型)
     COL_10,  -- 字段10(五级分类代码)
     COL_11   -- 字段11(逾期天数)
     )
    SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     'G01_2' AS REP_NUM, -- 报表编号
     'G01_2_2.A.2016' AS ITEM_NUM, -- 指标号
     A.LOAN_ACCT_BAL * U.CCY_RATE  AS TOTAL_VALUE, -- 汇总值
     A.ACCT_NUM AS COL_1, -- 合同号
     A.LOAN_NUM AS COL_2, -- 借据号
     A.CUST_ID AS COL_3, -- 客户号
     A.DRAWDOWN_AMT AS COL_4, -- 放款金额
     A.DRAWDOWN_DT AS COL_5, -- 放款日期
     A.MATURITY_DT AS COL_6, -- 原始到期日期
     A.ITEM_CD AS COL_7, -- 科目号
     A.CURR_CD AS COL_8, -- 币种
     A.ACCT_TYP AS COL_9, -- 账户类型
     A.LOAN_GRADE_CD AS COL_10, -- 五级分类代码
     A.OD_DAYs AS COL_11 -- 逾期天数
     FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = a.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
       WHERE A.OD_FLG = 'Y'
         AND A.DATA_DATE = I_DATADATE
         AND (A.OD_DAYS > 90 or a.od_days is null)
         AND A.LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         and A.ACCT_STS <> '3'
         AND A.ACCT_TYP NOT LIKE '90%'
         and a.CANCEL_FLG <> 'Y'
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       AND A.LOAN_ACCT_BAL <> 0;


-- 指标: G01_2_2.1.A.2016
/* 以上逻辑处理逾期贷款总数 逻辑  完成   指标编号  G01_2_2.A.2016        */
    ------------------------------------------------------------------------------------------------------------------------------------------------

    /* 以下 处理 90天以上逾期贷款 逻辑 */
    INSERT INTO `G01_2_2.1.A.2016`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       COL_1, -- 字段1(合同号)
       COL_2, -- 字段2(借据号)
       COL_3, -- 字段3(客户号)
       COL_4, -- 字段4(放款金额)
       COL_5, -- 字段5(放款日期)
       COL_6, -- 字段6(原始到期日期)
       COL_7, -- 字段7(科目号)
       COL_8, -- 字段8(币种)
       COL_9, -- 字段9(账户类型)
       COL_10, -- 字段10(五级分类代码)
       COL_11 -- 字段11(逾期天数)
       )
      SELECT 
       I_DATADATE AS DATA_DATE, -- 数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
       'CBRC' AS SYS_NAM, -- 模块简称
       'G01_2' AS REP_NUM, -- 报表编号
       'G01_2_2.1.A.2016' AS ITEM_NUM, -- 指标号
       A.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, -- 汇总值
       A.ACCT_NUM AS COL_1, -- 合同号
       A.LOAN_NUM AS COL_2, -- 借据号
       A.CUST_ID AS COL_3, -- 客户号
       A.DRAWDOWN_AMT AS COL_4, -- 放款金额
       A.DRAWDOWN_DT AS COL_5, -- 放款日期
       A.MATURITY_DT AS COL_6, -- 原始到期日期
       A.ITEM_CD AS COL_7, -- 科目号
       A.CURR_CD AS COL_8, -- 币种
       A.ACCT_TYP AS COL_9, -- 账户类型
       A.LOAN_GRADE_CD AS COL_10, -- 五级分类代码
       A.OD_DAYs AS COL_11 -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = a.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
       WHERE A.OD_FLG = 'Y'
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND ORG_NUM <> '009803'
         AND (A.OD_DAYS > 90 or a.od_days is null)
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         and a.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.LOAN_ACCT_BAL <> 0;

INSERT INTO `G01_2_2.1.A.2016`
      (ORG_NUM, --机构号
       ITEM_NUM, --报表类型
       ITEM_VAL --指标值
       )

      -- alter by 20240224 shiyu  JLBA202412040012
      select '009803' ORG_NUM,
             'G01_2_2.1.A.2016' as ITEM_NUM,
             SUM((NVL(T.M0, 0) + nvl(T.M1, 0) + nvl(T.M2, 0) + nvl(T.M3, 0) +
                 nvl(T.M4, 0) + nvl(T.M5, 0) + nvl(T.M6, 0) +
                 nvl(T.M6_UP, 0)) * R.CCY_RATE)

             as ITEM_VAL
        from SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE R -- 汇率表
          ON R.DATA_DATE = T.DATA_DATE
         AND R.BASIC_CCY = 'CNY'
         AND R.FORWARD_CCY = T.CURR_CD
       WHERE T.DATA_DATE = I_DATADATE
         and T.LXQKQS > 3;


-- 指标: G01_2_2.1.A.2020
/*  2.1逾期60天以上贷款*/

    INSERT INTO `G01_2_2.1.A.2020`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       COL_1, -- 字段1(合同号)
       COL_2, -- 字段2(借据号)
       COL_3, -- 字段3(客户号)
       COL_4, -- 字段4(放款金额)
       COL_5, -- 字段5(放款日期)
       COL_6, -- 字段6(原始到期日期)
       COL_7, -- 字段7(科目号)
       COL_8, -- 字段8(币种)
       COL_9, -- 字段9(账户类型)
       COL_10, -- 字段10(五级分类代码)
       COL_11, -- 字段11(逾期天数)
       COL_12, -- 字段12(还款方式)
       COL_13 -- 字段13(还款方式_2)
       )
      SELECT 
       I_DATADATE AS DATA_DATE, -- 数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
       'CBRC' AS SYS_NAM, -- 模块简称
       'G01_2' AS REP_NUM, -- 报表编号
       'G01_2_2.1.A.2020' AS ITEM_NUM, -- 指标号
       -- 20200529 modify ljp 个人消费 还款方式 是 一次还本 取 贷款余额 否则 取 本金逾期金额
       case
       -- alter by 20240224 shiyu  JLBA202412040012
         when A.REPAY_TYP = '1' and A.PAY_TYPE in ('01', '02', '10', '11') then --还款方式不为按月
          A.OD_LOAN_ACCT_BAL * U.CCY_RATE
         else
          A.LOAN_ACCT_BAL * U.CCY_RATE
       end AS TOTAL_VALUE, -- 汇总值
       A.ACCT_NUM AS COL_1, -- 合同号
       A.LOAN_NUM AS COL_2, -- 借据号
       A.CUST_ID AS COL_3, -- 客户号
       A.DRAWDOWN_AMT AS COL_4, -- 放款金额
       A.DRAWDOWN_DT AS COL_5, -- 放款日期
       A.MATURITY_DT AS COL_6, -- 原始到期日期
       A.ITEM_CD AS COL_7, -- 科目号
       A.CURR_CD AS COL_8, -- 币种
       A.ACCT_TYP AS COL_9, -- 账户类型
       A.LOAN_GRADE_CD AS COL_10, -- 五级分类代码
       A.OD_DAYs AS COL_11, -- 逾期天数
       A.PAY_TYPE AS COL_12, -- 还款方式
       A.REPAY_TYP AS COL_13 -- 还款方式_2
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = a.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYs > 60
         and OD_DAYs <= 90
         AND OD_FLG = 'Y'
            --AND VERSION_CBRC = 'CBRC'
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND (ACCT_TYP LIKE '0101%' OR ACCT_TYP LIKE '0103%' OR
             ACCT_TYP LIKE '0104%' OR ACCT_TYP LIKE '0199%' /*OR ACCT_TYP = 'E01'*/
             )
         and ACCT_TYP NOT LIKE '90%'
            --and A.DATE_SOURCESD NOT IN ('10301057', '10301059')  --ALTER BY ZYH 20210706 10301057|10301059:吉林银行众享贷贷款 这种贷款在2019年已全部结清，新信贷不承接结清旧数据
         AND ORG_NUM <> '009803'
         and a.item_cd not like '130105%'
         and a.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.LOAN_ACCT_BAL <> 0;

INSERT INTO `G01_2_2.1.A.2020`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       COL_1, -- 字段1(合同号)
       COL_2, -- 字段2(借据号)
       COL_3, -- 字段3(客户号)
       COL_4, -- 字段4(放款金额)
       COL_5, -- 字段5(放款日期)
       COL_6, -- 字段6(原始到期日期)
       COL_7, -- 字段7(科目号)
       COL_8, -- 字段8(币种)
       COL_9, -- 字段9(账户类型)
       COL_10, -- 字段10(五级分类代码)
       COL_11, -- 字段11(逾期天数)
       COL_12, -- 字段12(还款方式)
       COL_13 -- 字段13(还款方式_2)
       )
      SELECT 
       I_DATADATE AS DATA_DATE, -- 数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
       'CBRC' AS SYS_NAM, -- 模块简称
       'G01_2' AS REP_NUM, -- 报表编号
       'G01_2_2.1.A.2020' AS ITEM_NUM, -- 指标号
       A.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, -- 汇总值
       A.ACCT_NUM AS COL_1, -- 合同号
       A.LOAN_NUM AS COL_2, -- 借据号
       A.CUST_ID AS COL_3, -- 客户号
       A.DRAWDOWN_AMT AS COL_4, -- 放款金额
       A.DRAWDOWN_DT AS COL_5, -- 放款日期
       A.MATURITY_DT AS COL_6, -- 原始到期日期
       A.ITEM_CD AS COL_7, -- 科目号
       A.CURR_CD AS COL_8, -- 币种
       A.ACCT_TYP AS COL_9, -- 账户类型
       A.LOAN_GRADE_CD AS COL_10, -- 五级分类代码
       A.OD_DAYs AS COL_11, -- 逾期天数
       A.PAY_TYPE AS COL_12, -- 还款方式
       A.REPAY_TYP AS COL_13 -- 还款方式_2
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = a.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYs > 60
         and OD_DAYs <= 90
         AND OD_FLG = 'Y'
            --AND VERSION_CBRC = 'CBRC'
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND (ACCT_TYP NOT LIKE '0101%' AND ACCT_TYP NOT LIKE '0103%' AND
             ACCT_TYP NOT LIKE '0104%' AND ACCT_TYP NOT LIKE '0199%' AND
             ACCT_TYP <> 'E01' AND ACCT_TYP <> 'E02' and
             ACCT_TYP NOT LIKE '90%')
            --and A.DATE_SOURCESD NOT IN ('10301057', '10301059')  --ALTER BY ZYH 20210706 10301057|10301059:吉林银行众享贷贷款 这种贷款在2019年已全部结清，新信贷不承接结清旧数据
         AND ORG_NUM <> '009803'
         and a.item_cd not like '130105%'
         AND A.LOAN_ACCT_BAL <> 0;

INSERT INTO `G01_2_2.1.A.2020`
      (DATA_DATE, -- 数据日期
       ORG_NUM, -- 机构号
       DATA_DEPARTMENT, -- 数据条线
       SYS_NAM, -- 模块简称
       REP_NUM, -- 报表编号
       ITEM_NUM, -- 指标号
       TOTAL_VALUE, -- 汇总值
       COL_1, -- 字段1(合同号)
       COL_2, -- 字段2(借据号)
       COL_3, -- 字段3(客户号)
       COL_4, -- 字段4(放款金额)
       COL_5, -- 字段5(放款日期)
       COL_6, -- 字段6(原始到期日期)
       COL_7, -- 字段7(科目号)
       COL_8, -- 字段8(币种)
       COL_9, -- 字段9(账户类型)
       COL_10, -- 字段10(五级分类代码)
       COL_11 -- 字段11(逾期天数)
       )
      SELECT 
       I_DATADATE AS DATA_DATE, -- 数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
       'CBRC' AS SYS_NAM, -- 模块简称
       'G01_2' AS REP_NUM, -- 报表编号
       'G01_2_2.1.A.2020' AS ITEM_NUM, -- 指标号
       A.LOAN_ACCT_BAL * U.CCY_RATE AS TOTAL_VALUE, -- 汇总值
       A.ACCT_NUM AS COL_1, -- 合同号
       A.LOAN_NUM AS COL_2, -- 借据号
       A.CUST_ID AS COL_3, -- 客户号
       A.DRAWDOWN_AMT AS COL_4, -- 放款金额
       A.DRAWDOWN_DT AS COL_5, -- 放款日期
       A.MATURITY_DT AS COL_6, -- 原始到期日期
       A.ITEM_CD AS COL_7, -- 科目号
       A.CURR_CD AS COL_8, -- 币种
       A.ACCT_TYP AS COL_9, -- 账户类型
       A.LOAN_GRADE_CD AS COL_10, -- 五级分类代码
       A.OD_DAYs AS COL_11 -- 逾期天数
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = a.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
       WHERE A.OD_FLG = 'Y'
         AND A.ACCT_TYP NOT LIKE '90%'
         AND A.DATA_DATE = I_DATADATE
         AND ORG_NUM <> '009803'
         AND (A.OD_DAYS > 90 or a.od_days is null)
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         and a.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
         AND A.LOAN_ACCT_BAL <> 0;

INSERT INTO `G01_2_2.1.A.2020`
      (ORG_NUM, --机构号
       ITEM_NUM, --报表类型
       ITEM_VAL --指标值
       )

      -- alter by 20240224 shiyu  JLBA202412040012
      SELECT '009803' AS ORG_NUM,
             'G01_2_2.1.A.2020' AS ITEM_NUM,
             SUM((NVL(T.M0, 0) + nvl(T.M1, 0) + nvl(T.M2, 0) + nvl(T.M3, 0) +
                 nvl(T.M4, 0) + nvl(T.M5, 0) + nvl(T.M6, 0) +
                 nvl(T.M6_UP, 0)) * U.CCY_RATE)

             as ITEM_VAL
        FROM SMTMODS_L_ACCT_CARD_CREDIT T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
       WHERE T.DATA_DATE = I_DATADATE
            --AND GRADE_CD IN ('3', '4', '5')
            -- AND T.ORG_NUM = '009803'
         AND T.LXQKQS > 2;


