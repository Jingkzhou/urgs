-- ============================================================
-- 文件名: S47新型农村金融机构经营情况统计表.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: S47_1_5..A
--5.实收注册资本
    INSERT INTO `S47_1_5..A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_5..A' AS ITEM_NUM,
             A.CREDIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '4001'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');

--11.6.票据贴现及转贴现金额（万元）
    INSERT INTO `S47_1_5..A`
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_PER_NUM AS REP_NUM,
             'S47_1_5..A' AS ITEM_NUM,
             A.DEBIT_BAL AS ITEM_VAL,
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1301'
         AND A.CURR_CD = 'BWB'
         AND SUBSTR(A.ORG_NUM, 1, 1) IN ('5', '6');


