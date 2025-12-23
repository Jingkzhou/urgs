-- ============================================================
-- 文件名: G01_I(a) 表外业务情况表.sql
-- 生成时间: 2025-12-18 13:53:37
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 2 个指标 ==========
FROM (
SELECT 
     I_DATADATE AS DATA_DATE,
     CASE
       WHEN T.ORG_NUM LIKE '060101%' THEN
        '060300'
  
       WHEN T.ORG_NUM NOT LIKE '__98%' AND T.ORG_NUM NOT LIKE '5%' AND
            T.ORG_NUM NOT LIKE '6%' THEN ---20231026 由于村镇截取后会变成总行
        SUBSTR(T.ORG_NUM, 1, 4) || '00'
       ELSE
        T.ORG_NUM
     END,
     'CBRC' AS SYS_NAM,
     'G01_1' AS REP_NUM,
     CASE
       WHEN P.BANK_ISSUE_FLG = 'N' --代销理财
        THEN
        'G01_I_1.20.5.B.2023'
       WHEN P.BANK_ISSUE_FLG = 'Y' --自营理财
        THEN
        'G01_I_1.20.6.B.2023'
     END AS ITEM_NUM,
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
     WHERE T.TRAN_DATE BETWEEN
           substr(I_DATADATE, 1, 4) || '0101' AND I_DATADATE
       AND BUSINESS_TYPE = '1' --理财产品
       AND T.PROD_CODE NOT IN ('9B31009C',
                               '2301YO002B',
                               '90318011',
                               '91318017',
                               '9B310025',
                               '9B310061',
                               '9B31010E',
                               '9B31013G',
                               '9B31021A',
                               '9B31022A',
                               '9B31023B',
                               '9B31024B',
                               '9B31025B',
                               '9TTL001Y',
                               '9TTL002Y',
                               '9TTL003Y',
                               '9TTL004Y',
                               '9TTL005Y',
                               '9TTL006Y',
                               '9TTL007Y',
                               '9TTL008Y',
                               '9TTL009Y',
                               '9TTL010Y',
                               '9TTL011Y',
                               '9TTL012Y',
                               '9TTL013Y',
                               '9TTL014Y',
                               '9TTL015Y',
                               '9TTL016Y',
                               '9TTL017Y',
                               '9TTL018Y',
                               '9TTL019Y',
                               '9TTL020Y',
                               '9TTL021Y',
                               '9TTL022Y',
                               '9TTL023Y',
                               '9TTL024Y',
                               '9TTL025Y',
                               '9TTL026Y',
                               '9TTL027Y',
                               '9TTL028C',
                               '9TTL029Y',
                               '9TTL030Y',
                               '9TTL031Y',
                               '9TTL032Y',
                               '9TTL033Y',
                               '9TTL033Z',
                               '9TTL034Y',
                               '9TTL034Z',
                               '9TTL035Y') --现金管理类产品
       AND P.CASH_MANAGE_PRODUCT_FLG = 'N'
     GROUP BY CASE
                WHEN T.ORG_NUM LIKE '060101%' THEN
                 '060300'
                WHEN T.ORG_NUM NOT LIKE '__98%' AND T.ORG_NUM NOT LIKE '5%' AND
                     T.ORG_NUM NOT LIKE '6%' THEN ---20231026 由于村镇截取后会变成总行
                 SUBSTR(T.ORG_NUM, 1, 4) || '00'
                ELSE
                 T.ORG_NUM
              END,
              CASE
                WHEN P.BANK_ISSUE_FLG = 'N' --代销理财
                 THEN
                 'G01_I_1.20.5.B.2023'
                WHEN P.BANK_ISSUE_FLG = 'Y' --自营理财
                 THEN
                 'G01_I_1.20.6.B.2023'
              END
) q_0
INSERT INTO `G01_I_1.20.5.B.2023` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *
INSERT INTO `G01_I_1.20.6.B.2023` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *;

-- 指标: G01_I_1.13.2.A.2016
-- G01_I_1.13.2.A.2016
  INSERT INTO `G01_I_1.13.2.A.2016`
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
     COL_9 -- 字段9(委托人客户类型)
     )
    SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     V_REP_NUM AS REP_NUM, -- 报表编号
     'G01_I_1.13.2.A.2016' AS ITEM_NUM, -- 指标号
     A.LOAN_ACCT_BAL * NVL(U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
     A.ACCT_NUM AS COL_1, -- 合同号
     A.LOAN_NUM AS COL_2, -- 借据号
     A.CUST_ID AS COL_3, -- 客户号
     A.DRAWDOWN_AMT AS COL_4, -- 放款金额
     A.DRAWDOWN_DT AS COL_5, -- 放款日期
     A.MATURITY_DT AS COL_6, -- 原始到期日期
     A.ITEM_CD AS COL_7, -- 科目号
     A.CURR_CD AS COL_8, -- 币种
     B.TRUSTOR_TYPE AS COL_9 -- 委托人客户类型
      FROM SMTMODS_L_ACCT_LOAN A
      LEFT JOIN SMTMODS_L_ACCT_LOAN_ENTRUST B
        ON B.DATA_DATE = I_DATADATE
       AND A.LOAN_NUM = B.LOAN_NUM
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON A.DATA_DATE = U.DATA_DATE
       AND U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
     WHERE A.DATA_DATE = I_DATADATE
       AND A.CANCEL_FLG = 'N'
       AND A.ACCT_STS <> '3'
       AND LENGTHB(A.ACCT_NUM) < 36
       AND A.LOAN_ACCT_BAL <> 0
       AND SUBSTR(B.TRUSTOR_TYPE, 1, 1) = '1' --金融机构委托贷款基金
       AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       AND A.LOAN_ACCT_BAL <> 0;


-- 指标: G01_I_1.12..A.2016
V_STEP_DESC := 'G01_I_1.12..A.2016';

V_STEP_DESC := 'G01_I_1.12..A.2016';

--ADD BY DJH 20230417 代理投融资服务类  13.发行理财产品
    INSERT INTO `G01_I_1.12..A.2016`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)

      SELECT 
       I_DATADATE,
       A.ORG_NUM AS ORG_NUM, --机构号
       'CBRC',
       V_REP_NUM,
       'G01_I_1.12..A.2016' AS ITEM_NUM,
       SUM(END_PROD_AMT_CNY),
       '2' FLAG
        FROM SMTMODS_L_FIMM_PRODUCT_BAL A
       INNER JOIN SMTMODS_L_FIMM_PRODUCT B
          ON B.DATA_DATE = I_DATADATE
         AND A.PRODUCT_CODE = B.PRODUCT_CODE
         AND B.PROCEEDS_CHARACTER = 'c' --收益特征是非保本浮动收益类
         AND B.PRODUCT_END_DATE IS NOT NULL --产品实际终止日期不为空
         AND B.BANK_ISSUE_FLG = 'Y' --只统计本行发行的，若本行代销的他行发行的理财产品不纳入统计
       WHERE A.DATA_DATE = I_DATADATE
       GROUP BY A.ORG_NUM;


-- 指标: G01_I_1.12..B.2016
--ADD BY DJH 20230417 代理投融资服务类  13.发行理财产品 银行收益（年初至报告期末数）合计
    --6021贷方余额+6051贷方余额
    INSERT INTO `G01_I_1.12..B.2016`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)

      SELECT 
       I_DATADATE,
       T.ORG_NUM AS ORG_NUM, --机构号
       'CBRC',
       V_REP_NUM,
       'G01_I_1.12..B.2016' AS ITEM_NUM,
       SUM(T.CREDIT_BAL * U.CCY_RATE),
       '2' FLAG
        FROM SMTMODS_L_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD IN ('6021', '6051')
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;


-- ========== 逻辑组 4: 共 3 个指标 ==========
FROM (
SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN T.ORG_NUM LIKE '060101%' THEN
          '060300'
         WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND
              ORG_NUM NOT LIKE '6%' THEN ---20231026 由于村镇截取后会变成总行
          SUBSTR(ORG_NUM, 1, 4) || '00'
         ELSE
          T.ORG_NUM
       END AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01_1' AS REP_NUM,
       CASE
         WHEN BUSINESS_TYPE = '3' --信托计划
          THEN
          'G01_I_1.15.2.A.2016'
         WHEN BUSINESS_TYPE = '5' --保险产品
          THEN
          'G01_I_1.15.4.A.2016'
         WHEN T.BUSINESS_TYPE = '2' --基金
          THEN
          'G01_I_1.15.5.A.2016'
   
       END AS ITEM_NUM,
       SUM(T.AMT * NVL(U.CCY_RATE, 0)),
       '2'
        FROM SMTMODS_L_TRAN_FINANCE_FUND T --代理代销交易表
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.TRAN_DATE BETWEEN
             substr(I_DATADATE, 1, 4) || '0101' AND I_DATADATE --交易日期为本年
       GROUP BY CASE
                  WHEN T.ORG_NUM LIKE '060101%' THEN
                   '060300'
          
                  WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND
                       ORG_NUM NOT LIKE '6%' THEN ---20231026 由于村镇截取后会变成总行
                   SUBSTR(ORG_NUM, 1, 4) || '00'
                  ELSE
                   T.ORG_NUM
                END,
                CASE
                  WHEN BUSINESS_TYPE = '3' --信托计划
                   THEN
                   'G01_I_1.15.2.A.2016'
                  WHEN BUSINESS_TYPE = '5' --保险产品
                   THEN
                   'G01_I_1.15.4.A.2016'
                  WHEN T.BUSINESS_TYPE = '2' --基金
                   THEN
                   'G01_I_1.15.5.A.2016'
           
                END
) q_4
INSERT INTO `G01_I_1.15.2.A.2016` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *
INSERT INTO `G01_I_1.15.5.A.2016` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *
INSERT INTO `G01_I_1.15.4.A.2016` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *;

-- 指标: G01_1a_16..C.2023
INSERT INTO `G01_1a_16..C.2023`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
       SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC',
             'G01_1',
             'G01_1a_16..C.2023',
             SUM(T.CREDIT_BAL * U.CCY_RATE),
             '2' FLAG
        FROM SMTMODS_L_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD in ('60210405')
         AND T.DATA_DATE = I_DATADATE
         AND T.CREDIT_BAL <> 0
       GROUP BY T.ORG_NUM;


-- 指标: G01_1a_22.1.B.2023
--22.1代理收取款项 代理客户收取款项的业务 取全年的发生额
    --将当月发生的交易金额总和插入到临时表G0101_TEMP中
    INSERT INTO `G01_1a_22.1.B.2023`
      (DATA_DATE, MONTH_DATE, ITEM_NUM, ITEM_VAL, ORG_NUM)
      SELECT
       I_DATADATE,
       SUBSTR(I_DATADATE, 1, 6),
       'G01_1a_22.1.B.2023',
       SUM(T.TRANS_AMT),
       T.ORG_NUM
        FROM SMTMODS_L_TRAN_TX T
       WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 6) || '01' AND I_DATADATE
         AND T.TRAN_STS <> 'B' --alter by wjb 20230915 根据业务口径，不取冲正交易；
         AND T.TRANS_PURPOSE IN ('B03', 'B0301', 'B0302', 'B0303', 'B0304', 'B0305')
       GROUP BY T.ORG_NUM;

--将临时表中本年的交易插到val表里 G01_1a_22.1.B.2023
    INSERT INTO `G01_1a_22.1.B.2023`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)

      SELECT I_DATADATE,
             ORG_NUM,
             'CBRC',
             V_REP_NUM,
             'G01_1a_22.1.B.2023',
             SUM(ITEM_VAL),
             '2' FLAG
        FROM cbrc_G0101_TEMP T
       WHERE DATA_DATE <= I_DATADATE
         and substr(data_date,1,4) = SUBSTR(I_DATADATE, 1, 4)
         AND ITEM_NUM = 'G01_1a_22.1.B.2023'
       GROUP BY T.ORG_NUM;


-- 指标: G01_1a_22.2.B.2023
--add by wjb 20240105 G01_1a_22.1.B.2023
    INSERT INTO `G01_1a_22.2.B.2023`
      (DATA_DATE, MONTH_DATE, ITEM_NUM, ITEM_VAL, ORG_NUM)
      SELECT 
       I_DATADATE,
       SUBSTR(I_DATADATE, 1, 6),
       'G01_1a_22.2.B.2023',
       SUM(CASE
             WHEN TRAN_CODE_DESCRIBE LIKE '%划回%' THEN
              T.TRANS_AMT * -1
             ELSE
              T.TRANS_AMT
           END),
       T.ORG_NUM
        FROM SMTMODS_L_TRAN_TX T
       WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 1, 6) || '01' AND I_DATADATE
         AND T.CD_TYPE = '2' -- alter by wjb 20230915 根据业务反馈的测试结果，确定代发业务只取借贷标志为贷的
         AND T.OPPO_ORG_NUM NOT LIKE '5%' -- alter by wjb 20230919 根据业务反馈的测试结果，只取交易对手机构为吉林银行的，不要磐石的。
         AND T.OPPO_ORG_NUM NOT LIKE '6%' -- BY CH 20231031
         AND T.TRAN_CODE NOT IN ('JT10', 'CRET', 'DRET')
         AND T.TRAN_CODE_DESCRIBE NOT IN  ('冲正-跨行转账', '冲正-批量代发工资')
         and T.TRAN_CODE_DESCRIBE NOT LIKE '%跨行%'
         AND T.TRANS_PURPOSE IN ('B04',
                                 'B0401',
                                 'B040101',
                                 'B040102',
                                 'B040103',
                                 'B040104',
                                 'B040105',
                                 'B040106',
                                 'B040107',
                                 'B0402')
       GROUP BY T.ORG_NUM;

--将临时表中本年的交易插到val表里 G01_1a_22.2.B.2023
    INSERT INTO `G01_1a_22.2.B.2023`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)

      SELECT I_DATADATE,
             ORG_NUM,
             'CBRC',
             V_REP_NUM,
             'G01_1a_22.2.B.2023',
             SUM(ITEM_VAL),
             '2' FLAG
        FROM cbrc_G0101_TEMP T
       WHERE DATA_DATE <= I_DATADATE
         and substr(data_date,1,4) = SUBSTR(I_DATADATE, 1, 4)
         AND ITEM_NUM = 'G01_1a_22.2.B.2023'
       GROUP BY T.ORG_NUM;


-- 指标: G01_I_1.9..A.2016
V_STEP_DESC := 'G01_I_1.9..A.2016';

--取法二：卡部业务给的逻辑，循环信用额度 - （1220301 + 1220303 + 1360401借方余额）
    INSERT INTO `G01_I_1.9..A.2016`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)

      SELECT 
       I_DATADATE,
       '009803' AS ORG_NUM, --机构号
       'CBRC',
       V_REP_NUM,
       'G01_I_1.9..A.2016' AS ITEM_NUM,
       SUM(CASE
             WHEN A.QUANTUM_CCY = 'CNY' THEN
              A.QUANTUM
             ELSE
              A.QUANTUM * NVL(U.CCY_RATE, 0)
           END),
       '2' FLAG
        FROM SMTMODS_L_AGRE_CARD_CREDIT A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.QUANTUM_CCY --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
      UNION
      SELECT 
       I_DATADATE,
       '009803' AS ORG_NUM, --机构号
       'CBRC',
       V_REP_NUM,
       'G01_I_1.9..A.2016' AS ITEM_NUM,
       -SUM(T.DEBIT_BAL * CCY_RATE),
       '2'
        FROM SMTMODS_L_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM = '009803'
         AND T.ITEM_CD IN ('13030301', '13030303', '13060401');


-- 指标: G01_I_1.13.3.1.A.2016
V_STEP_DESC := 'G01_I_1.13.3.1.A.2016';

INSERT INTO `G01_I_1.13.3.1.A.2016`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE,
       A.ORG_NUM AS ORG_NUM, --机构号
       'CBRC',
       V_REP_NUM,
       'G01_I_1.13.3.1.A.2016' AS ITEM_NUM,
       SUM(A.ACCT_BALANCE * NVL(U.CCY_RATE, 0)),
       '2' FLAG
        FROM SMTMODS_L_ACCT_DEPOSIT A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ACCT_NUM IN ('7330140601000020_1', '60505406010000163_1')
       GROUP BY A.ORG_NUM;


-- ========== 逻辑组 10: 共 2 个指标 ==========
FROM (
SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     V_REP_NUM AS REP_NUM, -- 报表编号
     CASE
       WHEN ACCT_TYP IN ('121', '122', '221') THEN
        'G01_I_1.3.1.A.2016'
        
       WHEN ACCT_TYP = '511' THEN
        'G01_I_1.7..A.2016'
       WHEN ACCT_TYP IN ('521', '522', '523', '531') THEN
        'G01_I_1.8..A.2016'
     END AS ITEM_NUM, -- 指标号
     A.BALANCE * U.CCY_RATE AS TOTAL_VALUE, -- 汇总值
     A.MATURITY_DT AS COL_1, -- 到期日期
     A.BUSINESS_DT AS COL_2, -- 业务发生日期
     A.CUST_ID AS COL_3, -- 客户号
     A.ACCT_NUM AS COL_4, -- 账号
     A.ACCT_NO AS COL_5, -- 合同号
     A.GL_ITEM_CODE AS COL_6, -- 科目号
     A.ACCT_TYP AS COL_7 -- 账户类型
      FROM SMTMODS_L_ACCT_OBS_LOAN A
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON A.DATA_DATE = U.DATA_DATE
       AND U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
     WHERE (A.ACCT_TYP IN ('121', '122', '221', '211', '212') OR
           A.ACCT_TYP LIKE '6%')
       AND A.DATA_DATE = I_DATADATE
       AND A.BALANCE <> 0
) q_10
INSERT INTO `G01_I_1.7..A.2016` (DATA_DATE,  
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
     COL_7)
SELECT *
INSERT INTO `G01_I_1.3.1.A.2016` (DATA_DATE,  
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
     COL_7)
SELECT *;

-- 指标: G01_I_1.13.3.A.2016
-- G01_I_1.13.3.A.2016
  INSERT INTO `G01_I_1.13.3.A.2016`
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
     COL_9 -- 字段9(委托人客户类型)
     )
    SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     A.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     V_REP_NUM AS REP_NUM, -- 报表编号
     'G01_I_1.13.3.A.2016' AS ITEM_NUM, -- 指标号
     A.LOAN_ACCT_BAL * NVL(U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
     A.ACCT_NUM AS COL_1, -- 合同号
     A.LOAN_NUM AS COL_2, -- 借据号
     A.CUST_ID AS COL_3, -- 客户号
     A.DRAWDOWN_AMT AS COL_4, -- 放款金额
     A.DRAWDOWN_DT AS COL_5, -- 放款日期
     A.MATURITY_DT AS COL_6, -- 原始到期日期
     A.ITEM_CD AS COL_7, -- 科目号
     A.CURR_CD AS COL_8, -- 币种
     B.TRUSTOR_TYPE AS COL_9 -- 委托人客户类型
      FROM SMTMODS_L_ACCT_LOAN A
     INNER JOIN SMTMODS_L_ACCT_LOAN_ENTRUST B
        ON B.DATA_DATE = I_DATADATE
       AND A.LOAN_NUM = B.LOAN_NUM
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON A.DATA_DATE = U.DATA_DATE
       AND U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
     WHERE A.DATA_DATE = I_DATADATE
       AND A.CANCEL_FLG = 'N'
       AND LENGTHB(A.ACCT_NUM) < 36
       AND A.LOAN_ACCT_BAL <> 0
       AND SUBSTR(B.TRUSTOR_TYPE, 1, 1) = '2' --非金融机构委托贷款基金
       AND A.LOAN_STOCKEN_DATE IS NULL --add by haorui 20250311 JLBA202408200012 资产未转让
       AND A.LOAN_ACCT_BAL <> 0;

-- G01_I_1.13.3.A.2016
  INSERT INTO `G01_I_1.13.3.A.2016`
    (DATA_DATE, -- 数据日期
     ORG_NUM, -- 机构号
     DATA_DEPARTMENT, -- 数据条线
     SYS_NAM, -- 模块简称
     REP_NUM, -- 报表编号
     ITEM_NUM, -- 指标号
     TOTAL_VALUE, -- 汇总值
     COL_7, -- 字段7(科目号)
     COL_8 -- 字段8(币种)
     )
    SELECT 
     I_DATADATE AS DATA_DATE, -- 数据日期
     A.ORG_NUM AS ORG_NUM, --机构号
     '' AS DATA_DEPARTMENT, -- 数据条线
     'CBRC' AS SYS_NAM, -- 模块简称
     V_REP_NUM AS REP_NUM, -- 报表编号
     'G01_I_1.13.3.A.2016' AS ITEM_NUM, -- 指标号
     A.DEBIT_BAL * NVL(U.CCY_RATE, 0) AS TOTAL_VALUE, -- 汇总值
     A.ITEM_CD AS COL_7, -- 科目号
     A.CURR_CD AS COL_8 -- 币种
      FROM SMTMODS_L_FINA_GL A
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON A.DATA_DATE = U.DATA_DATE
       AND U.CCY_DATE = I_DATADATE
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ITEM_CD = '30200201'
       AND A.ORG_NUM LIKE '%01'
       AND A.DEBIT_BAL <> 0;


-- ========== 逻辑组 12: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, -- 数据日期
           T.ORG_NUM AS ORG_NUM, --机构号
           T.DEPARTMENTD AS DATA_DEPARTMENT, -- 数据条线
           'CBRC' AS SYS_NAM, -- 模块简称
           V_REP_NUM AS REP_NUM, -- 报表编号
           CASE T.ORIG_TERM
             WHEN '1Y' THEN
              'G01_I_1.2.1.A.2016'
             WHEN '1YA' THEN
              'G01_I_1.2.2.A.2016'
           END AS ITEM_NUM, -- 指标号
           T.BALANCE_RMB AS TOTAL_VALUE, -- 汇总值
           T.MATURITY_DT AS COL_1, -- 到期日期
           T.BUSINESS_DT AS COL_2, -- 业务发生日期
           T.CUST_ID AS COL_3, -- 客户号
           T.ACCT_NUM AS COL_4, -- 账号
           T.ACCT_NO AS COL_5, -- 合同号
           T.GL_ITEM_CODE AS COL_6 -- 科目号
      FROM (SELECT 
             CASE
               WHEN A.MATURITY_DT - A.BUSINESS_DT <= 366 THEN --与吴大伟确认一年以366天计算
                '1Y'
               ELSE
                '1YA'
             END AS ORIG_TERM,
             A.ORG_NUM AS ORG_NUM,
             A.BALANCE * U.CCY_RATE AS BALANCE_RMB,
             TO_CHAR(A.MATURITY_DT,'YYYYMMDD') AS MATURITY_DT,
             TO_CHAR(A.BUSINESS_DT,'YYYYMMDD') AS BUSINESS_DT,
             A.CUST_ID AS CUST_ID,
             A.ACCT_NUM AS ACCT_NUM,
             A.ACCT_NO AS ACCT_NO,
             A.GL_ITEM_CODE AS GL_ITEM_CODE,
             A.DEPARTMENTD AS DEPARTMENTD
              FROM SMTMODS_L_ACCT_OBS_LOAN A
              LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
                ON A.DATA_DATE = U.DATA_DATE
               AND U.CCY_DATE = I_DATADATE
               AND U.BASIC_CCY = A.CURR_CD --基准币种
               AND U.FORWARD_CCY = 'CNY' --折算币种
             WHERE A.ACCT_TYP LIKE '31%'
               AND A.DATA_DATE = I_DATADATE) T
     WHERE T.ORIG_TERM IN ('1Y', '1YA')
       AND T.BALANCE_RMB <> 0
) q_12
INSERT INTO `G01_I_1.2.2.A.2016` (DATA_DATE,  
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
     COL_6)
SELECT *
INSERT INTO `G01_I_1.2.1.A.2016` (DATA_DATE,  
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
     COL_6)
SELECT *;

-- 指标: G01_I_1.4..A.2016
------M6 金融市场部需求：4.信用风险仍在银行的销售与购买协议  口径：票据买断式卖断业务，票据票面到期日没有到期的余额  add  by   zy  start ------

 INSERT INTO `G01_I_1.4..A.2016`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
  SELECT 
       I_DATADATE ,
       A.ORG_NUM AS ORG_NUM, --机构号
       'CBRC',
       V_REP_NUM,
      'G01_I_1.4..A.2016'  AS ITEM_NUM,
       SUM(A.AMOUNT * U.CCY_RATE),
       '2' FLAG
        FROM SMTMODS_L_AGRE_BILL_CONTRACT  A
        INNER  JOIN   SMTMODS_L_AGRE_BILL_INFO   B
          ON  A.BILL_NUM  =B.BILL_NUM
         AND  B.DATA_DATE  =I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON A.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = B.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
           AND  B.MATU_DATE > I_DATADATE      ---未到期的
           AND A.BUSI_TYPE ='BT01'  ---转贴现
           AND A.STATUS ='2'   ---卖出结束
           group  by  A.ORG_NUM;


-- 指标: G01_1a_17..C.2023
INSERT INTO `G01_1a_17..C.2023`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)

      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC',
             V_REP_NUM,
             'G01_1a_17..C.2023',
             SUM(T.CREDIT_BAL * U.CCY_RATE),
             '2' FLAG
        FROM SMTMODS_L_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD = '60210417'
         AND T.DATA_DATE = I_DATADATE
         AND T.CREDIT_BAL <> 0
       GROUP BY T.ORG_NUM;


-- ========== 逻辑组 15: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE, --数据日期
         A.ORG_NUM, --机构号
         --A.SYS_NAM, --模块简称
         B.SYS_NAM, --模块简称    --shiwenbo by 20170407-sysnam 修改模块简称判断，因为CAR为3位，模块简称为4位char型
         A.REPORT_NAM, --报表编号
         A.ITEM_CD, --指标号
         A.B_CURR_CD, --报表要求的币种
         A.INDEX_VAL, --指标值(数值型)
         B.CONF_FLG, --标志位：1-总账、2-明细、3-归并、9-个性化
         CASE
           WHEN A.ITEM_CD IN ('G01_47..B',
                              'G01_47..A',
                              'G01_23..B',
                              'G01_23..A',
                              'G01_23..C',
                              'G01_1.3.A.091231',
                              'G01_1.4.A.091231',
                              'G01_1_2.3.A',
                              'G01_I_1.1..A.2016',
                              'G01_I_1.3.2.A.2016') THEN
            'N'
         END AS IS_TOTAL
    FROM CBRC_A_REPT_ITEM_VAL_TMP A
   INNER JOIN CBRC_A_REPT_ITEM_CONF B
      ON --A.SYS_NAM = B.SYS_NAM
   TRIM(A.SYS_NAM) = B.SYS_NAM --模块简称  --shiwenbo by 20170407-sysnam 修改模块简称判断，因为CAR为3位，模块简称为4位char型
   AND A.ITEM_CD = B.ITEM_NUM --统计科目编号
   AND B.USE_FLG = 'Y' --是否启用
   AND B.CONF_FLG = '1'
) q_15
INSERT INTO `G01_I_1.3.2.A.2016` (DATA_DATE,  
   ORG_NUM,  
   SYS_NAM,  
   REP_NUM,  
   ITEM_NUM,  
   B_CURR_CD,  
   ITEM_VAL,  
   FLAG,  
   IS_TOTAL)
SELECT *
INSERT INTO `G01_I_1.1..A.2016` (DATA_DATE,  
   ORG_NUM,  
   SYS_NAM,  
   REP_NUM,  
   ITEM_NUM,  
   B_CURR_CD,  
   ITEM_VAL,  
   FLAG,  
   IS_TOTAL)
SELECT *;

-- 指标: G01_1a_17..B.2023
------M6 金融市场部需求：17.代理发行和承销债券.发生额 1019800.00  口径：承销债券承销买入发生额、所产生的手续费收入 add  by   zy  start ------

INSERT INTO `G01_1a_17..B.2023`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
  SELECT 
       I_DATADATE ,
       A.ORG_NUM AS ORG_NUM, --机构号
       'CBRC',
       V_REP_NUM,
      'G01_1a_17..B.2023'  AS ITEM_NUM,
       SUM(A.ACCT_AMOUNT ), ---当时票面金额，不是实际支付的票面金额=票面金额+利息
       '2' FLAG
  FROM SMTMODS_L_TRAN_FUND_FX A
 WHERE SUBSTR(A.TRAN_DT,1,4) =  SUBSTR(I_DATADATE,1,4)
   AND PRODUCT_NAME = '债券投资交易'
   AND TRADE_TYPE_UNDERWRIT = '0' --承销买入
   AND A.ITEM_CD <> '21010101' -- 交易性政府债券投资成本
   GROUP  BY  A.ORG_NUM;


-- 指标: G01_I_1.15..B.2016
CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g0101(II_DATADATE  IN STRING --跑批日期
                                                 
                                                   )
/******************************  
  @AUTHOR:FANXIAOYU
  @CREATE-DATE:2015-09-19
  @DESCRIPTION:G0101
  @MODIFICATION HISTORY:
  M0.20150919-FANXIAOYU-G0101
  m1.shiyu 20220628 跟单信用证一年以内366天
  M2 ADD SHIYU 15项代理代销业务
  M3 ALTER 13.3.1其中：公积金委托贷款 指标G01_I_1.13.3.1.A.2016
      逻辑改为按公积金账户取存款 '2001800000000521', '2001800000000786'
  M4 公积金委托贷款由科目取数据，新科目30200201公积金委托贷款
   M6 金融市场部需求：4.信用风险仍在银行的销售与购买协议 , 17.代理发行和承销债券.发生额
    M7 代理代销业务银行收益（年初至报告期末数）合计 指标  'G01_I_1.15..B.2016'  add by wty
    M8 新制度升级需求，修改20代理代销业务银行收益及16.代理交易 收益从科目取
 
 目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_G0101_TEMP 
     CBRC_A_REPT_DWD_G0101
码值表：CBRC_PUB_DATA_G0101   --表中没数据不确定这个表是否是用到了
视图表：SMTMODS_V_PUB_IDX_FINA_GL            --总账科目表
集市表：SMTMODS_L_FINA_GL                    --总账科目表
        SMTMODS_L_PUBL_RATE               --汇率表
        SMTMODS_L_ACCT_OBS_LOAN           --贷款表外信息表
        SMTMODS_L_AGRE_BILL_CONTRACT      --票据合同信息表
        SMTMODS_L_AGRE_BILL_INFO          --商业汇票票面信息表
        SMTMODS_L_AGRE_CARD_CREDIT        --信用卡授信额度补充信息表
        SMTMODS_L_FIMM_PRODUCT_BAL        --理财产品份额余额表
        SMTMODS_L_FIMM_PRODUCT            --理财产品信息表
        SMTMODS_L_ACCT_LOAN_ENTRUST       --委托贷款补充信息
        SMTMODS_L_ACCT_LOAN               --贷款借据信息表
        SMTMODS_L_ACCT_DEPOSIT            --存款账户信息表
        SMTMODS_L_ACCT_DERIVE_DETAIL_INFO --衍生合约信息表
        SMTMODS_L_CUST_ALL                --全量客户信息表
        SMTMODS_L_TRAN_FINANCE_FUND       --代理代销交易表
        SMTMODS_L_FIMM_PRODUCT            --理财产品信息表
        SMTMODS_L_TRAN_TX                 --交易信息表
        SMTMODS_L_TRAN_FUND_FX            --资金交易信息表
    
  *******************************/
 IS
  V_PROCEDURE VARCHAR(30);

------M6 金融市场部需求：17.代理发行和承销债券.发生额   口径： 承销债券承销买入发生额、所产生的手续费收入  add  by   zy  end  ------

------M7 代理代销业务银行收益（年初至报告期末数）合计 指标  'G01_I_1.15..B.2016'  20241212 add by wty-------

    V_STEP_ID   := '33';

--代理代销业务收益”指标增加取数规则为“60210401贷方+60210404贷方+60210418贷方+60210420贷方”合计；

       INSERT INTO `G01_I_1.15..B.2016`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
       SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC',
             'G01_1',
             'G01_I_1.15..B.2016',
             SUM(T.CREDIT_BAL * U.CCY_RATE),
             '2' FLAG
        FROM SMTMODS_L_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       WHERE T.ITEM_CD in ('60210401','60210404','60210418','60210420')
         AND T.DATA_DATE = I_DATADATE
         AND T.CREDIT_BAL <> 0
       GROUP BY T.ORG_NUM;


-- 指标: G01_I_1.16.2.B.2024
--ALTER BY shiyu 20240219 新增贵金属

    INSERT INTO `G01_I_1.16.2.B.2024`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       CASE
         WHEN T.ORG_NUM LIKE '060101%' THEN
          '060300'
     
         WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND
              ORG_NUM NOT LIKE '6%' THEN ---20231026 由于村镇截取后会变成总行
          SUBSTR(ORG_NUM, 1, 4) || '00'
         ELSE
          T.ORG_NUM
       END AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01_1' AS REP_NUM,
       'G01_I_1.16.2.B.2024' AS ITEM_NUM,
       SUM(T.AMT * NVL(U.CCY_RATE, 0)),
       '2'
        FROM SMTMODS_L_TRAN_FINANCE_FUND T --代理代销交易表
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T.TRAN_DATE BETWEEN
             substr(I_DATADATE, 1, 4) || '0101' AND I_DATADATE --交易日期为本年
        and T.BUSINESS_TYPE = '6' --贵金属
       GROUP BY CASE
                  WHEN T.ORG_NUM LIKE '060101%' THEN
                   '060300'
                  WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND
                       ORG_NUM NOT LIKE '6%' THEN ---20231026 由于村镇截取后会变成总行
                   SUBSTR(ORG_NUM, 1, 4) || '00'
                  ELSE
                   T.ORG_NUM
                END;


