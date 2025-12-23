-- ============================================================
-- 文件名: G01资产负债项目统计表附注3.sql
-- 生成时间: 2025-12-18 13:53:37
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: G01_3_1.6.1.C.2022
INSERT INTO `G01_3_1.6.1.C.2022`
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
       COL_9 -- 字段9(账户类型)
       )
      SELECT 
       I_DATADATE AS DATA_DATE, -- 数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       null AS DATA_DEPARTMENT, -- 数据条线
       'CBRC' AS SYS_NAM, -- 模块简称
       'G01_3' AS REP_NUM, -- 报表编号
       'G01_3_1.6.1.C.2022' AS ITEM_NUM, -- 指标号
       sum(A.DEBIT_BAL * B.CCY_RATE) AS TOTAL_VALUE, -- 汇总值
       null AS COL_1, -- 合同号
       null AS COL_2, -- 借据号
       null AS COL_3, -- 客户号
       null AS COL_4, -- 放款金额
       null AS COL_5, -- 放款日期
       null AS COL_6, -- 原始到期日期
       A.ITEM_CD AS COL_7, -- 科目号
       null AS COL_8, -- 币种
       null AS COL_9 -- 账户类型
        FROM SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('13060201',
                           '13060202',
                           '13060203',
                           '13060401',
                           '13060402',
                           '13060403') --承兑垫款，银行卡垫款
         AND A.DEBIT_BAL <> 0
       GROUP BY A.ORG_NUM, A.ITEM_CD

      UNION ALL
      SELECT 
       I_DATADATE AS DATA_DATE, -- 数据日期
       CASE
       /*WHEN ORG_NUM LIKE '%98%' THEN --同时有网点和支行的数据需要把明细汇总成支行
        ORG_NUM
       ELSE
        SUBSTR(ORG_NUM, 1, 4) || '00'*/
         WHEN A.ORG_NUM NOT LIKE '__98%' AND A.ORG_NUM NOT LIKE '5%' AND
              A.ORG_NUM NOT LIKE '6%' THEN ---20231026 由于村镇截取后会变成总行
          SUBSTR(A.ORG_NUM, 1, 4) || '00'
         ELSE
          A.ORG_NUM
       END AS ORG_NUM, --机构号
       A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
       'CBRC' AS SYS_NAM, -- 模块简称
       'G01_3' AS REP_NUM, -- 报表编号
       'G01_3_1.6.1.C.2022' AS ITEM_NUM, -- 指标号
       NVL(A.LOAN_ACCT_BAL, 0) + NVL(A.INT_ADJEST_AMT, 0) AS TOTAL_VALUE, -- 汇总值
       A.ACCT_NUM AS COL_1, -- 合同号
       A.LOAN_NUM AS COL_2, -- 借据号
       A.CUST_ID AS COL_3, -- 客户号
       A.DRAWDOWN_AMT AS COL_4, -- 放款金额
       A.DRAWDOWN_DT AS COL_5, -- 放款日期
       A.MATURITY_DT AS COL_6, -- 原始到期日期
       A.ITEM_CD AS COL_7, -- 科目号
       A.CURR_CD AS COL_8, -- 币种
       A.ACCT_TYP AS COL_9 -- 账户类型
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE --CHANGED BY LIRUITING 增加币种数据日期过滤条件             WHERE DATA_DATE = I_DATADATE
       where A.DATA_DATE = I_DATADATE
         AND A.ACCT_TYP = '090101' --融资性保函垫款
         AND A.LOAN_ACCT_BAL <> 0;


-- 指标: G01_03.2.2.7.A
-- 2.2.7个人保证金存款

       INSERT INTO `G01_03.2.2.7.A` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.7.A'  AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         AND GL_ITEM_CODE = '20110209'
       GROUP BY ORG_NUM;

INSERT INTO `G01_03.2.2.7.A` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.7.A'  AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         AND GL_ITEM_CODE = '20110210'
       GROUP BY ORG_NUM;


-- 指标: G01_03.2.1.1.B
INSERT INTO `G01_03.2.1.1.B`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             TEMP2.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.1.B' AS ITEM_NUM,
             SUM(TEMP2.ITEM_VAL),
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.1.1.B' AS ITEM_NUM,
                     SUM(A.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.CURR_CD <> 'CNY'
                 AND ITEM_CD IN ('20110201', '20110206','20110301','20110302','20110303','22410101','20080101','20090101') --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
               GROUP BY ORG_NUM) TEMP2
       GROUP BY TEMP2.ORG_NUM;

INSERT INTO `G01_03.2.1.1.B` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             /*CASE
               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END*/ ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.1.B' AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND GL_ITEM_CODE = '20110201'
         AND CURR_CD <> 'CNY'
       GROUP BY ORG_NUM;

--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款201103（财政性存款 ）]剔除个体工商户部分

 INSERT INTO `G01_03.2.1.1.B`
  (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
   SELECT 
    I_DATADATE AS DATA_DATE,
   T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.1.B' AS ITEM_NUM,
    SUM(T.ACCT_BALANCE * B.CCY_RATE)* -1  AS ITEM_VAL,
    '2' AS FLAG
     from SMTMODS_L_ACCT_DEPOSIT T
    INNER JOIN SMTMODS_L_CUST_C C
       ON T.DATA_DATE = C.DATA_DATE
      AND T.CUST_ID = C.CUST_ID
    INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
       ON T.DATA_DATE = B.DATA_DATE
      AND T.CURR_CD = B.BASIC_CCY
      AND B.FORWARD_CCY = 'CNY' --折人民币
    WHERE C.DEPOSIT_CUSTTYPE IN ('13', '14')
      AND T.GL_ITEM_CODE IN ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
      AND T.ACCT_BALANCE > 0
      AND T.CURR_CD <>'CNY'
      AND T.DATA_DATE = I_DATADATE
    GROUP BY T.ORG_NUM;

--单位协定
    INSERT INTO `G01_03.2.1.1.B` --修改从视图取个体工商户部分 LFZ 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       SUBSTR(A.ORG_NUM, 0, 4) || '00' AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       V_REP_NUM AS REP_NUM,
       'G01_03.2.1.1.B' AS ITEM_NUM,
       SUM(A.ACCT_BALANCE * B.CCY_RATE) * -1 AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_DEPOSIT A
       INNER JOIN SMTMODS_L_CUST_C C
          ON A.CUST_ID = C.CUST_ID
         AND A.DATA_DATE = C.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.CURR_CD <> 'CNY'
         AND (A.GL_ITEM_CODE LIKE '20110201%'
           or   A.GL_ITEM_CODE IN ('20110301', '20110302', '20110303', '22410101') )--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款201103（财政性存款 ）]剔除协定存款部分

         AND C.DEPOSIT_CUSTTYPE NOT IN ('13', '14')
         AND A.ACCT_TYPE IN ('0601', '0602')
       GROUP BY SUBSTR(A.ORG_NUM, 0, 4) || '00';


-- 指标: G01_3_2.5.1.A.2022
INSERT INTO `G01_3_2.5.1.A.2022`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_3_2.5.1.A.2022' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_3_2.5.1.A.2022' AS ITEM_NUM,
                     SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.CURR_CD = 'CNY'
                 AND A.ITEM_CD IN ('20120106', '20120204')
               GROUP BY A.ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;

INSERT INTO `G01_3_2.5.1.A.2022`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_3_2.5.1.A.2022' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_3_2.5.1.A.2022' AS ITEM_NUM,
                     SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.CURR_CD <> 'CNY'
                 AND A.ITEM_CD IN ('20120106', '20120204')
               GROUP BY A.ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;


-- 指标: G01_03.2.5.A.2012
--=====================================
    --   G0103 2.5其他存款
    --=====================================
   

    --LIUD MF AT 20200729 其他存款取：201_10保险公司存款+ 234010204保险业金融机构存放款项
    INSERT INTO `G01_03.2.5.A.2012`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.5.A.2012' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.5.A.2012' AS ITEM_NUM,
                     SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.CURR_CD = 'CNY'
                 AND A.ITEM_CD IN ('20120106', '20120204')
               GROUP BY A.ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;


-- ========== 逻辑组 5: 共 2 个指标 ==========
FROM (
SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     'G01_3' AS REP_NUM, -- 报表编号
     CASE
       WHEN MONTHS_BETWEEN(A.MATURITY_DT, A.DRAWDOWN_DT) > 12 THEN
        'G01_03.1.2.A' --中长期
       ELSE
        'G01_03.1.1.A' --短期
     END AS ITEM_NUM, -- 指标号
     A.LOAN_ACCT_BAL AS TOTAL_VALUE, -- 汇总值
     A.ACCT_NUM AS COL_1, -- 合同号
     A.LOAN_NUM AS COL_2, -- 借据号
     A.CUST_ID AS COL_3, -- 客户号
     A.DRAWDOWN_AMT AS COL_4, -- 放款金额
     A.DRAWDOWN_DT as COL_5, -- 放款日期
     A.MATURITY_DT AS COL_6, -- 原始到期日期
     A.ITEM_CD AS COL_7, -- 科目号
     A.CURR_CD AS COL_8, -- 币种
     A.ACCT_TYP AS COL_9 -- 账户类型
      FROM SMTMODS_V_PUB_IDX_DK_YSDQRJJ A --ALTER BY WJB 20220621 原始到日期逻辑修改，从此视图取。
     WHERE A.DATA_DATE = I_DATADATE
       AND SUBSTR(A.ITEM_CD, 1, 4) = '1303' --普通贷款，垫款 --20211102 LXA 修改G0103贷款不包含垫款
       AND A.CURR_CD = 'CNY'
       AND A.LOAN_ACCT_BAL <> 0
    union all
    SELECT I_DATADATE AS DATA_DATE, -- 数据日期
           A.ORG_NUM AS ORG_NUM, --机构号
           null AS DATA_DEPARTMENT, -- 数据条线
           'CBRC' AS SYS_NAM, -- 模块简称
           'G01_3' AS REP_NUM, -- 报表编号
           'G01_03.1.1.A' AS ITEM_NUM, -- 指标号
           SUM(A.DEBIT_BAL) AS TOTAL_VALUE, -- 汇总值
           null AS COL_1, -- 合同号
           null AS COL_2, -- 借据号
           null AS COL_3, -- 客户号
           null AS COL_4, -- 放款金额
           null AS COL_5, -- 放款日期
           null AS COL_6, -- 原始到期日期
           A.ITEM_CD AS COL_7, -- 科目号
           A.CURR_CD AS COL_8, -- 币种
           null AS COL_9 -- 账户类型
      FROM SMTMODS_V_PUB_IDX_FINA_GL A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ITEM_CD IN ('13030301', '13030302', '13030303')
       AND A.ORG_NUM = '009803'
       AND A.CURR_CD = 'CNY'
     GROUP BY 'G01_03.1.1.A', A.ORG_NUM, A.ITEM_CD, A.CURR_CD --20211102 LXA ADD 信用卡数据
) q_5
INSERT INTO `G01_03.1.2.A` (DATA_DATE,  
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
INSERT INTO `G01_03.1.1.A` (DATA_DATE,  
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

-- 指标: G01_03.2.2.2.B
INSERT INTO `G01_03.2.2.2.B`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.2.B' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.2.2.B' AS ITEM_NUM,
                     SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL A
               INNER JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.CURR_CD <> 'CNY'
                 AND A.ITEM_CD IN ('20110103',
                                   '20110104',
                                   '20110105',
                                   '20110106',
                                   '20110107',
                                   '20110108',
                                   '20110109',
                                   '20110113')
               GROUP BY A.ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;

INSERT INTO `G01_03.2.2.2.B` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             /*CASE
               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END*/ ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.2.B' AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD <> 'CNY'
       GROUP BY ORG_NUM;


-- 指标: G01_03.2.5.B.2012
INSERT INTO `G01_03.2.5.B.2012`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.5.B.2012' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.5.B.2012' AS ITEM_NUM,
                     SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL A
                LEFT JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.CURR_CD <> 'CNY'
                 AND A.ITEM_CD IN ('20120106', '20120204')
               GROUP BY A.ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;


-- 指标: G01_03.2.1.6.A
INSERT INTO `G01_03.2.1.6.A` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.6.A'  AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         AND GL_ITEM_CODE = '20110209'
       GROUP BY ORG_NUM;

--2.1.6单位保证金存款


        INSERT INTO `G01_03.2.1.6.A` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.6.A'  AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         AND GL_ITEM_CODE = '20110210'
       GROUP BY ORG_NUM;


-- 指标: G01_03.2.2.2.A
--=====================================
    --   G0103 2.1.4个人定期存款
    --=====================================
    INSERT INTO `G01_03.2.2.2.A`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.2.A' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.2.2.A' AS ITEM_NUM,
                     SUM(CREDIT_BAL) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
                 AND ITEM_CD IN ('20110103',
                                 '20110104',
                                 '20110105',
                                 '20110106',
                                 '20110107',
                                 '20110108',
                                 '20110109',
                                 '20110113')
               GROUP BY ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;

INSERT INTO `G01_03.2.2.2.A` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             /*CASE
               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END*/ ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.2.A' AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
       GROUP BY ORG_NUM;


-- 指标: G01_03.2.2.4.A
--=====================================
    --   G0103 2.2.4 个人通知存款
    --=====================================
    --新增 改为视图过滤个体工商户部分 lfz 20220614

    INSERT INTO `G01_03.2.2.4.A`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.4.A' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.2.4.A' AS ITEM_NUM,
                     CREDIT_BAL AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
                 AND ITEM_CD = '20110110') TEMP --个人通知存款
       GROUP BY TEMP.ORG_NUM;

INSERT INTO `G01_03.2.2.4.A` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             /*CASE
               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END */ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.4.A' AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
       GROUP BY ORG_NUM;


-- ========== 逻辑组 11: 共 2 个指标 ==========
FROM (
SELECT 
      I_DATADATE AS DATA_DATE, -- 数据日期
      A.ORG_NUM AS ORG_NUM, --机构号
      A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
      'CBRC' AS SYS_NAM, -- 模块简称
      'G01_3' AS REP_NUM, -- 报表编号
      CASE
        WHEN T3.PROD_FLAG = 'N' THEN
         'G01_3_1.4.1.A.2023' --1.4.1境内贸易融资
        WHEN T3.PROD_FLAG = 'Y' THEN
         'G01_3_1.4.2.A.2023'
      END --    1.4.2跨境贸易融资
      AS ITEM_NUM, -- 指标号
      A.LOAN_ACCT_BAL * B.CCY_RATE AS TOTAL_VALUE, -- 汇总值
      A.ACCT_NUM AS COL_1, -- 合同号
      A.LOAN_NUM AS COL_2, -- 借据号
      A.CUST_ID AS COL_3, -- 客户号
      A.DRAWDOWN_AMT AS COL_4, -- 放款金额
      A.DRAWDOWN_DT AS COL_5, -- 放款日期
      A.MATURITY_DT AS COL_6, -- 原始到期日期
      A.ITEM_CD AS COL_7, -- 科目号
      A.CURR_CD AS COL_8, -- 币种
      A.ACCT_TYP AS COL_9 -- 账户类型
       FROM SMTMODS_L_ACCT_LOAN A
       LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT T2
         ON A.DATA_DATE = T2.DATA_DATE
        AND A.ACCT_NUM = T2.CONTRACT_NUM
       LEFT JOIN (select PROD_NAME, PROD_FLAG
                    from CBRC_MYRZ_PROD_INFO
                   GROUP BY PROD_NAME, PROD_FLAG) T3
         ON TRIM(T2.PROD_NAME) = TRIM(T3.PROD_NAME)
       LEFT JOIN SMTMODS_L_PUBL_RATE B
         ON A.DATA_DATE = B.DATA_DATE
        AND A.CURR_CD = B.BASIC_CCY
        AND B.FORWARD_CCY = 'CNY'
      WHERE A.DATA_DATE = I_DATADATE
        AND A.ITEM_CD LIKE '1305%' --贸易融资
        AND A.ACCT_STS <> '3'
        AND A.LOAN_ACCT_BAL <> 0
        AND A.CURR_CD = 'CNY'
) q_11
INSERT INTO `G01_3_1.4.1.A.2023` (DATA_DATE,  
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
INSERT INTO `G01_3_1.4.2.A.2023` (DATA_DATE,  
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

-- 指标: G01_03.2.1.4.A
--=====================================
    --   G0103 2.1.4单位协议存款
    --=====================================
    INSERT INTO `G01_03.2.1.4.A`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.4.A' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.1.4.A' AS ITEM_NUM,
                     CREDIT_BAL AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
                 AND ITEM_CD = '20110204'
              UNION ALL
              SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.1.4.A' AS ITEM_NUM,
                     CREDIT_BAL AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
                 AND ITEM_CD = '20110211'
              UNION ALL
              SELECT 
               I_DATADATE AS DATA_DATE,
               /*ORG_NUM*/
               SUBSTR(ORG_NUM, 0, 4) || '00' AS ORG_NUM, --LIUD MF AT 20191014 减去从明细取的数据，但机构给支行，与从总账取的数据做合并。
               'CBRC' AS SYS_NAM,
               V_REP_NUM AS REP_NUM,
               'G01_03.2.1.4.A' AS ITEM_NUM,
               SUM(ACCT_BALANCE) * -1 AS ITEM_VAL,
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_DEPOSIT A
               INNER JOIN CBRC_JL_ACCT_MISCODE_MAPPING2 T2
                  ON A.DATA_DATE = T2.DATA_DATE
                 AND A.ACCT_NUM = T2.COD_PROD_MNEM_CUST
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.CURR_CD = 'CNY'
                 AND A.GL_ITEM_CODE LIKE '20110204%'
               GROUP BY /*A.ORG_NUM*/ SUBSTR(ORG_NUM, 0, 4) || '00') TEMP
       GROUP BY TEMP.ORG_NUM;


-- 指标: G01_03.2.1.2.B
INSERT INTO `G01_03.2.1.2.B`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.2.B' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.1.2.B' AS ITEM_NUM,
                     SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL A
               INNER JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.CURR_CD <> 'CNY'
                 AND A.ITEM_CD IN ('20110202', '20110203', '20110208')
               GROUP BY A.ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;

INSERT INTO `G01_03.2.1.2.B` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             /*CASE
               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM*/
             ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.2.B' AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD <> 'CNY'
       GROUP BY ORG_NUM;


-- 指标: G01_3_1.4.2.B.2023
INSERT INTO `G01_3_1.4.2.B.2023`
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
       COL_9 -- 字段9(账户类型)
       )
      SELECT 
       I_DATADATE AS DATA_DATE, -- 数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
       'CBRC' AS SYS_NAM, -- 模块简称
       'G01_3' AS REP_NUM, -- 报表编号
       CASE
         WHEN T3.PROD_FLAG = 'N' THEN
          'G01_3_1.4.1.B.2023' --1.4.1境内贸易融资
         WHEN T3.PROD_FLAG = 'Y' THEN
          'G01_3_1.4.2.B.2023'
       END --    1.4.2跨境贸易融资
       AS ITEM_NUM, -- 指标号
       A.LOAN_ACCT_BAL * B.CCY_RATE AS TOTAL_VALUE, -- 汇总值
       A.ACCT_NUM AS COL_1, -- 合同号
       A.LOAN_NUM AS COL_2, -- 借据号
       A.CUST_ID AS COL_3, -- 客户号
       A.DRAWDOWN_AMT AS COL_4, -- 放款金额
       A.DRAWDOWN_DT AS COL_5, -- 放款日期
       A.MATURITY_DT AS COL_6, -- 原始到期日期
       A.ITEM_CD AS COL_7, -- 科目号
       A.CURR_CD AS COL_8, -- 币种
       A.ACCT_TYP AS COL_9 -- 账户类型
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_AGRE_LOAN_CONTRACT T2
          ON A.DATA_DATE = T2.DATA_DATE
         AND A.ACCT_NUM = T2.CONTRACT_NUM
        LEFT JOIN (select PROD_NAME, PROD_FLAG
                     from CBRC_MYRZ_PROD_INFO
                    GROUP BY PROD_NAME, PROD_FLAG) T3
          ON TRIM(T2.PROD_NAME) = TRIM(T3.PROD_NAME)
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD LIKE '1305%' --贸易融资
         AND A.ACCT_STS <> '3'
         AND A.LOAN_ACCT_BAL <> 0
         AND A.CURR_CD <> 'CNY';


-- 指标: G01_03.2.1.4.B
INSERT INTO `G01_03.2.1.4.B`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.4.B' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.1.4.B' AS ITEM_NUM,
                     SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL A
               INNER JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.CURR_CD <> 'CNY'
                 AND A.ITEM_CD IN ('20110204', '20110211')
               GROUP BY A.ORG_NUM
              UNION ALL
              SELECT 
               I_DATADATE AS DATA_DATE,
               ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               V_REP_NUM AS REP_NUM,
               'G01_03.2.1.4.B' AS ITEM_NUM,
               SUM(ACCT_BALANCE * B.CCY_RATE) * -1 AS ITEM_VAL,
               '2' AS FLAG
                FROM SMTMODS_L_ACCT_DEPOSIT A
               INNER JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               INNER JOIN CBRC_JL_ACCT_MISCODE_MAPPING2 T2
                  ON A.DATA_DATE = T2.DATA_DATE
                 AND A.ACCT_NUM = T2.COD_PROD_MNEM_CUST
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.CURR_CD <> 'CNY'
                 AND A.GL_ITEM_CODE LIKE '20110204%'
               GROUP BY A.ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;


-- 指标: G01_03.2.2.1.A
--=====================================
    --   G0103 2.2.1 个人活期存款
    --=====================================
    --新增 改为视图过滤个体工商户部分 lfz 20220614

    

    INSERT INTO `G01_03.2.2.1.A`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.1.A' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.2.1.A' AS ITEM_NUM,
                     CREDIT_BAL AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
                 AND ITEM_CD IN ('20110101', '20110111','22410102') --[JLBA202507210012][石雨][修改内容：修改内容：22410102个人久悬未取款属于活期存款]
                 ) TEMP --个人活期
       GROUP BY TEMP.ORG_NUM;

INSERT INTO `G01_03.2.2.1.A` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             /*CASE
         WHEN ORG_NUM LIKE '060101%' THEN
          '060300'
         WHEN ORG_NUM NOT LIKE '__98%' THEN
          SUBSTR(ORG_NUM, 1, 4) || '00'
         ELSE
          ORG_NUM
       END*/ ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.1.A' AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND GL_ITEM_CODE = '20110201'
         AND CURR_CD = 'CNY'
       GROUP BY /*CASE
         WHEN ORG_NUM LIKE '060101%' THEN
          '060300'
         WHEN ORG_NUM NOT LIKE '__98%' THEN
          SUBSTR(ORG_NUM, 1, 4) || '00'
         ELSE
          ORG_NUM
       END*/ORG_NUM;

--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款201103（财政性存款 ）]剔除个体工商户部分

 INSERT INTO `G01_03.2.2.1.A`
  (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
   SELECT 
    I_DATADATE AS DATA_DATE,
   T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.1.A' AS ITEM_NUM,
    SUM(T.ACCT_BALANCE * B.CCY_RATE)   AS ITEM_VAL,
    '2' AS FLAG
     from SMTMODS_L_ACCT_DEPOSIT T
    INNER JOIN SMTMODS_L_CUST_C C
       ON T.DATA_DATE = C.DATA_DATE
      AND T.CUST_ID = C.CUST_ID
    INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
       ON T.DATA_DATE = B.DATA_DATE
      AND T.CURR_CD = B.BASIC_CCY
      AND B.FORWARD_CCY = 'CNY' --折人民币
    WHERE C.DEPOSIT_CUSTTYPE IN ('13', '14')
      AND T.GL_ITEM_CODE IN ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
      AND T.ACCT_BALANCE > 0
      AND T.CURR_CD ='CNY'
      AND T.DATA_DATE = I_DATADATE
    GROUP BY T.ORG_NUM;


-- 指标: G01_03.2.1.1.A
--=====================================
    --   G0103 2.1.1单位活期存款
    --=====================================


     ---2.1.1单位活期存款
    INSERT INTO `G01_03.2.1.1.A`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             TEMP1.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.1.A' AS ITEM_NUM,
             SUM(TEMP1.ITEM_VAL),
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.1.1.A' AS ITEM_NUM,
                     SUM(CREDIT_BAL) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
                 AND ITEM_CD IN ('20110201', '20110206','20110301','20110302','20110303','22410101','20080101','20090101') --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
               GROUP BY ORG_NUM) TEMP1
       GROUP BY TEMP1.ORG_NUM;

INSERT INTO `G01_03.2.1.1.A` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
       SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.1.A' AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND GL_ITEM_CODE = '20110201'
         AND CURR_CD = 'CNY'
       GROUP BY ORG_NUM;

--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款201103（财政性存款 ）]剔除个体工商户部分

 INSERT INTO `G01_03.2.1.1.A`
  (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
   SELECT 
    I_DATADATE AS DATA_DATE,
   T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.1.A' AS ITEM_NUM,
    SUM(T.ACCT_BALANCE * B.CCY_RATE)* -1  AS ITEM_VAL,
    '2' AS FLAG
     from SMTMODS_L_ACCT_DEPOSIT T
    INNER JOIN SMTMODS_L_CUST_C C
       ON T.DATA_DATE = C.DATA_DATE
      AND T.CUST_ID = C.CUST_ID
    INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
       ON T.DATA_DATE = B.DATA_DATE
      AND T.CURR_CD = B.BASIC_CCY
      AND B.FORWARD_CCY = 'CNY' --折人民币
    where c.deposit_custtype in ('13', '14')
      and t.gl_item_code IN ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
      AND T.ACCT_BALANCE > 0
      AND T.CURR_CD ='CNY'
      AND T.DATA_DATE = I_DATADATE
    GROUP BY T.ORG_NUM;

--2.1.1单位活期存款 减去单位协定
    INSERT INTO `G01_03.2.1.1.A`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,

       T.ORG_NUM,
       'CBRC' AS SYS_NAM,
       V_REP_NUM AS REP_NUM,
       'G01_03.2.1.1.A' AS ITEM_NUM,
       SUM(ACCT_BALANCE) * -1 AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_DEPOSIT T
       INNER JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
       INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY' --折人民币
       WHERE T.DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         AND (GL_ITEM_CODE LIKE '20110201%'
          or   t.gl_item_code IN ('20110301', '20110302', '20110303', '22410101') )--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款201103（财政性存款 ）]剔除协定存款部分
         AND C.DEPOSIT_CUSTTYPE NOT IN ('13', '14')
         AND ACCT_TYPE IN ('0601', '0602')
       GROUP BY T.ORG_NUM;


-- 指标: G01_03.2.2.1.B
INSERT INTO `G01_03.2.2.1.B`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.1.B' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.2.1.B' AS ITEM_NUM,
                     SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL A
               INNER JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.CURR_CD <> 'CNY'
                 AND A.ITEM_CD IN ('20110101', '20110111') --个人活期
               GROUP BY ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;

INSERT INTO `G01_03.2.2.1.B` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             /*CASE
               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END*/ ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.1.B' AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND GL_ITEM_CODE = '20110201'
         AND CURR_CD <> 'CNY'
       GROUP BY ORG_NUM;

--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款201103（财政性存款 ）]剔除个体工商户部分

 INSERT INTO `G01_03.2.2.1.B`
  (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
   SELECT 
    I_DATADATE AS DATA_DATE,
   T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.2.1.B' AS ITEM_NUM,
    SUM(T.ACCT_BALANCE * B.CCY_RATE)   AS ITEM_VAL,
    '2' AS FLAG
     FROM SMTMODS_L_ACCT_DEPOSIT T
    INNER JOIN SMTMODS_L_CUST_C C
       ON T.DATA_DATE = C.DATA_DATE
      AND T.CUST_ID = C.CUST_ID
    INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
       ON T.DATA_DATE = B.DATA_DATE
      AND T.CURR_CD = B.BASIC_CCY
      AND B.FORWARD_CCY = 'CNY' --折人民币
    WHERE C.DEPOSIT_CUSTTYPE IN ('13', '14')
      AND T.GL_ITEM_CODE IN ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
      AND T.ACCT_BALANCE > 0
      AND T.CURR_CD <>'CNY'
      AND T.DATA_DATE = I_DATADATE
    GROUP BY T.ORG_NUM;


-- 指标: G01_03.2.1.3.A
--=====================================
    --   G0103 2.1.3单位通知存款
    --=====================================

    INSERT INTO `G01_03.2.1.3.A`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.3.A' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.1.3.A' AS ITEM_NUM,
                     CREDIT_BAL AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
                 AND ITEM_CD = '20110205') TEMP --单位通知
       GROUP BY TEMP.ORG_NUM;

INSERT INTO `G01_03.2.1.3.A` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             /*CASE
               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END*/ ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.3.A' AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
       GROUP BY ORG_NUM;


-- 指标: G01_3_1.6.3.C.2022
INSERT INTO `G01_3_1.6.3.C.2022`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_3_1.6.3.C.2022' AS ITEM_NUM,
             sum(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('13060301',
                           '13060302',
                           '13060303',
                           '13060501',
                           '13060502',
                           '13060503') --信用证垫款,其他垫款
       GROUP BY ORG_NUM;


-- 指标: G01_3_1.6.1.1.C.2022
INSERT INTO `G01_3_1.6.1.1.C.2022`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_3_1.6.1.1.C.2022' AS ITEM_NUM,
             sum(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('13060201', '13060202', '13060203') --承兑垫款
       GROUP BY ORG_NUM;


-- 指标: G01_03.2.1.5.A
--=====================================
    --   G0103 2.1.5单位协定存款
    --=====================================
    --本币
    INSERT INTO `G01_03.2.1.5.A`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       V_REP_NUM AS REP_NUM,
       'G01_03.2.1.5.A' AS ITEM_NUM,
       SUM(ACCT_BALANCE * B.CCY_RATE) AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_DEPOSIT T
       INNER JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
       INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY' --折人民币
       WHERE T.DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         AND (t.GL_ITEM_CODE LIKE '20110201%'
          or   t.gl_item_code IN ('20110301', '20110302', '20110303', '22410101') )--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款201103（财政性存款 ）]剔除协定存款部分
         AND C.DEPOSIT_CUSTTYPE NOT IN ('13', '14')
         AND ACCT_TYPE IN ('0601', '0602')
       GROUP BY T.ORG_NUM;


-- 指标: G01_03.2.1.2.A
--=====================================
    --   G0103 2.1.4单位定期存款
    --=====================================
  
    --    2.1.2单位定期存款
    INSERT INTO `G01_03.2.1.2.A`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.2.A' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_REP_NUM AS REP_NUM,
                     'G01_03.2.1.2.A' AS ITEM_NUM,
                     SUM(CREDIT_BAL) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
                 AND ITEM_CD IN ('20110202', '20110203', '20110208') --单位一般定期存款,单位大额可转让定期存单,发行单位大额存单
               GROUP BY ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;

-- 2.1.2单位定期存款 减去个体工商户部分
    INSERT INTO `G01_03.2.1.2.A` --修改从视图取个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             /*CASE
               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM*/ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G01_03.2.1.2.A' AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
       GROUP BY ORG_NUM;


