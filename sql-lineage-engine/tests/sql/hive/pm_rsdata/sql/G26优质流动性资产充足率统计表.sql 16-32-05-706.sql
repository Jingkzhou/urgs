-- ============================================================
-- 文件名: G26优质流动性资产充足率统计表.sql
-- 生成时间: 2025-12-18 13:53:39
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: G26_2.1.1.A.2018
--2.1.1 储蓄存款  ---和 G01 保持一致
   INSERT INTO `G26_2.1.1.A.2018`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT  I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'G26_2.1.1.A.2018' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG
        FROM (SELECT  I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.1.A.2018' AS ITEM_NUM,
                     SUM(CREDIT_BAL) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
                 AND ITEM_CD IN ('201101','22410102') --[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
               GROUP BY ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;

INSERT INTO `G26_2.1.1.A.2018`  -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
               SELECT  I_DATADATE AS DATA_DATE,
                      ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.1.A.2018' AS ITEM_NUM,
                     SUM(ACCT_BALANCE_RMB)  ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ  --个体工商户定期存款
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
               GROUP BY ORG_NUM;

INSERT INTO `G26_2.1.1.A.2018`  -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)

              SELECT  I_DATADATE AS DATA_DATE,
                      ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.1.A.2018' AS ITEM_NUM,
                     SUM(ACCT_BALANCE_RMB)  AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ  --个体工商户活期存款
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
               GROUP BY ORG_NUM;

INSERT INTO `G26_2.1.1.A.2018`  -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
              SELECT  I_DATADATE AS DATA_DATE,
                      ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.1.A.2018' AS ITEM_NUM,
                     SUM(ACCT_BALANCE_RMB)  AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
               GROUP BY ORG_NUM;

INSERT INTO `G26_2.1.1.A.2018`
   (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
   SELECT 
    I_DATADATE AS DATA_DATE,
    T.ORG_NUM,
    'CBRC' AS SYS_NAM,
    'G01' AS REP_NUM,
    'G26_2.1.1.A.2018' AS ITEM_NUM,
    SUM(T.ACCT_BALANCE * B.CCY_RATE)  AS ITEM_VAL,
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
      AND T.DATA_DATE = I_DATADATE
    GROUP BY T.ORG_NUM;


-- 指标: G26_2.1.2.A.2018
-- 2.1.2 对公存款  ---总数和 G01保持一致
    INSERT INTO `G26_2.1.2.A.2018`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
           SELECT   I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.2.A.2018' AS ITEM_NUM,
                     SUM(CREDIT_BAL) AS ITEM_VAL,
                     '2' AS FLAG
                --FROM SMTMODS_L_FINA_GL
                FROM SMTMODS_V_PUB_IDX_FINA_GL
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
                 AND ITEM_CD IN ('201102','22410101','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款）调整为 一般单位活期存款]
               GROUP BY ORG_NUM;

INSERT INTO `G26_2.1.2.A.2018`  -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
              SELECT  I_DATADATE AS DATA_DATE,
                      ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.2.A.2018' AS ITEM_NUM,
                     SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ  --个体工商户定期存款
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
               GROUP BY ORG_NUM;

INSERT INTO `G26_2.1.2.A.2018`  -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
              SELECT 
                     I_DATADATE AS DATA_DATE,
                      ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.2.A.2018' AS ITEM_NUM,
                     SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ  --个体工商户活期存款
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
               GROUP BY ORG_NUM;

INSERT INTO `G26_2.1.2.A.2018`  -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
              SELECT  I_DATADATE AS DATA_DATE,
                      ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     V_PER_NUM AS REP_NUM,
                     'G26_2.1.2.A.2018' AS ITEM_NUM,
                     SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
               GROUP BY ORG_NUM;

INSERT INTO `G26_2.1.2.A.2018`
   (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
   SELECT 
    I_DATADATE AS DATA_DATE,
    T.ORG_NUM,
    'CBRC' AS SYS_NAM,
    'G01' AS REP_NUM,
    'G26_2.1.2.A.2018' AS ITEM_NUM,
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
      AND T.DATA_DATE = I_DATADATE
    GROUP BY T.ORG_NUM;


