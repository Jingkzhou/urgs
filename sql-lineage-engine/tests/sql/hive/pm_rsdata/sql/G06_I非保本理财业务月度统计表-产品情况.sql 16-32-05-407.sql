-- ============================================================
-- 文件名: G06_I非保本理财业务月度统计表-产品情况.sql
-- 生成时间: 2025-12-18 13:53:37
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: G06_1_1.3.H.2017
------------------------------------------------------------------------------------------------------

    --JLBA202409260002_关于1104系统完善表外理财业务报表的相关需求
    --删除1.按募集方式划分（1.1 公募理财产品、1.2 私募理财产品、1.3 合 计）H列 本期银行端实现收益总额 不使用理财传过来的数据，单独取数
     DELETE FROM CBRC_G06_1_CONFIG_TMP T
     WHERE T.ITEM_NUM IN ('G06_1_1.1.H.2017',
                          'G06_1_1.2.H.2017',
                          'G06_1_1.3.H.2017',
                          'G06_1_2.1.H.2017',
                          'G06_1_2.2.H.2017',
                          'G06_1_2.3.H.2017',
                          'G06_1_2.4.H.2017',
                          'G06_1_2.5.H.2017');

INSERT INTO `G06_1_1.3.H.2017`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE,'009816','CBRC','G06_1','G06_1_1.3.H.2017',SUM(ITEM_VAL),'2'
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM = '009816'
         AND T.ITEM_NUM IN ('G06_1_1.2.H.2017','G06_1_1.1.H.2017');


-- 指标: G06_1_1.2.H.2017
------------------------------------------------------------------------------------------------------

    --JLBA202409260002_关于1104系统完善表外理财业务报表的相关需求
    --删除1.按募集方式划分（1.1 公募理财产品、1.2 私募理财产品、1.3 合 计）H列 本期银行端实现收益总额 不使用理财传过来的数据，单独取数
     DELETE FROM CBRC_G06_1_CONFIG_TMP T
     WHERE T.ITEM_NUM IN ('G06_1_1.1.H.2017',
                          'G06_1_1.2.H.2017',
                          'G06_1_1.3.H.2017',
                          'G06_1_2.1.H.2017',
                          'G06_1_2.2.H.2017',
                          'G06_1_2.3.H.2017',
                          'G06_1_2.4.H.2017',
                          'G06_1_2.5.H.2017');

INSERT INTO `G06_1_1.2.H.2017`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE,'009816','CBRC','G06_1','G06_1_1.2.H.2017',SUM(LJYHDSY),'2'
        FROM (SELECT T.PRODUCT_CODE AS PRODUCT_CODE,
                     NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0) AS LJYHDSY -- 累计实现银行端收益
                FROM SMTMODS_L_FIMM_PRODUCT_BAL T
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT A
                  ON A.PRODUCT_CODE = T.PRODUCT_CODE
                 AND A.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT_BAL T1
                  ON T.PRODUCT_CODE = T1.PRODUCT_CODE
                 AND T1.DATA_DATE = LAST_DATA
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.DATE_SOURCESD <> 'ZGXT'
                 AND A.COLLECT_TYP = '2' -- 募集方式 1：公募 2：私募
                 AND NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0) <> 0);

INSERT INTO `G06_1_1.2.H.2017`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE,'009816','CBRC','G06_1','G06_1_1.3.H.2017',SUM(ITEM_VAL),'2'
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM = '009816'
         AND T.ITEM_NUM IN ('G06_1_1.2.H.2017','G06_1_1.1.H.2017');


-- 指标: G06_1_2.5.H.2017
------------------------------------------------------------------------------------------------------

    --JLBA202409260002_关于1104系统完善表外理财业务报表的相关需求
    --删除1.按募集方式划分（1.1 公募理财产品、1.2 私募理财产品、1.3 合 计）H列 本期银行端实现收益总额 不使用理财传过来的数据，单独取数
     DELETE FROM CBRC_G06_1_CONFIG_TMP T
     WHERE T.ITEM_NUM IN ('G06_1_1.1.H.2017',
                          'G06_1_1.2.H.2017',
                          'G06_1_1.3.H.2017',
                          'G06_1_2.1.H.2017',
                          'G06_1_2.2.H.2017',
                          'G06_1_2.3.H.2017',
                          'G06_1_2.4.H.2017',
                          'G06_1_2.5.H.2017');

INSERT INTO `G06_1_2.5.H.2017`
        (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
        SELECT I_DATADATE,
               '009816',
               'CBRC',
               'G06_1',
               'G06_1_2.5.H.2017',
               SUM(ITEM_VAL),
               '2'
          FROM CBRC_A_REPT_ITEM_VAL T
         WHERE T.DATA_DATE = I_DATADATE
           AND T.ORG_NUM = '009816'
           AND T.ITEM_NUM IN ('G06_1_2.1.H.2017',
                              'G06_1_2.2.H.2017',
                              'G06_1_2.3.H.2017',
                              'G06_1_2.4.H.2017');


-- 指标: G06_1_1.1.H.2017
------------------------------------------------------------------------------------------------------

    --JLBA202409260002_关于1104系统完善表外理财业务报表的相关需求
    --删除1.按募集方式划分（1.1 公募理财产品、1.2 私募理财产品、1.3 合 计）H列 本期银行端实现收益总额 不使用理财传过来的数据，单独取数
     DELETE FROM CBRC_G06_1_CONFIG_TMP T
     WHERE T.ITEM_NUM IN ('G06_1_1.1.H.2017',
                          'G06_1_1.2.H.2017',
                          'G06_1_1.3.H.2017',
                          'G06_1_2.1.H.2017',
                          'G06_1_2.2.H.2017',
                          'G06_1_2.3.H.2017',
                          'G06_1_2.4.H.2017',
                          'G06_1_2.5.H.2017');

INSERT INTO `G06_1_1.1.H.2017`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE,'009816','CBRC','G06_1','G06_1_1.1.H.2017',SUM(LJYHDSY),'2'
        FROM (SELECT T.PRODUCT_CODE AS PRODUCT_CODE,
                      CASE
                        WHEN SUBSTR(I_DATADATE,5,4) = '0131' THEN NVL(T.YHDSY, 0)
                        ELSE  NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0)
                      END AS LJYHDSY -- 累计实现银行端收益
                FROM SMTMODS_L_FIMM_PRODUCT_BAL T
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT A
                  ON A.PRODUCT_CODE = T.PRODUCT_CODE
                 AND A.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT_BAL T1
                  ON T.PRODUCT_CODE = T1.PRODUCT_CODE
                 AND T1.DATA_DATE = LAST_DATA
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.DATE_SOURCESD <> 'ZGXT'
                 AND A.COLLECT_TYP = '1' -- 募集方式 1：公募 2：私募
                 AND T.PRODUCT_CODE <> '60211401'
                 AND NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0) <> 0
              UNION ALL
              SELECT T.PRODUCT_CODE AS PRODUCT_CODE,
                     CASE
                        WHEN SUBSTR(I_DATADATE,5,4) = '0131' THEN NVL(T.YHDSY, 0)
                        ELSE  NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0)
                      END AS LJYHDSY -- 累计实现银行端收益
                FROM SMTMODS_L_FIMM_PRODUCT_BAL T
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT A
                  ON A.PRODUCT_CODE = T.PRODUCT_CODE
                 AND A.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT_BAL T1
                  ON T.PRODUCT_CODE = T1.PRODUCT_CODE
                 AND T1.DATA_DATE = LAST_DATA
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.DATE_SOURCESD <> 'ZGXT'
                 AND T.PRODUCT_CODE = '60211401' --固定取数在公募基金
                 AND NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0) <> 0);

INSERT INTO `G06_1_1.1.H.2017`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE,'009816','CBRC','G06_1','G06_1_1.3.H.2017',SUM(ITEM_VAL),'2'
        FROM CBRC_A_REPT_ITEM_VAL T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM = '009816'
         AND T.ITEM_NUM IN ('G06_1_1.2.H.2017','G06_1_1.1.H.2017');


-- 指标: G06_1_2.1.H.2017
------------------------------------------------------------------------------------------------------

    --JLBA202409260002_关于1104系统完善表外理财业务报表的相关需求
    --删除1.按募集方式划分（1.1 公募理财产品、1.2 私募理财产品、1.3 合 计）H列 本期银行端实现收益总额 不使用理财传过来的数据，单独取数
     DELETE FROM CBRC_G06_1_CONFIG_TMP T
     WHERE T.ITEM_NUM IN ('G06_1_1.1.H.2017',
                          'G06_1_1.2.H.2017',
                          'G06_1_1.3.H.2017',
                          'G06_1_2.1.H.2017',
                          'G06_1_2.2.H.2017',
                          'G06_1_2.3.H.2017',
                          'G06_1_2.4.H.2017',
                          'G06_1_2.5.H.2017');

-- 2.按投资性质划分  2.1 固定收益类  2.2 权益类   2.3 商品及金融衍生品类   2.4 混合类  本期银行端实现收益总额
   /* 理财产品类型 A 固定收益类 B 权益类  C 商品及金融衍生品类 D 混合类  E 表内*/
    -- 2.5合计=ROUND(业务状况表6021本期发生额贷方/10000,2)

    INSERT INTO `G06_1_2.1.H.2017`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE,
             '009816',
             'CBRC',
             'G06_1',
             CASE
               WHEN PRODUCT_TYPE = 'A' THEN
                'G06_1_2.1.H.2017'
               WHEN PRODUCT_TYPE = 'B' THEN
                'G06_1_2.2.H.2017'
               WHEN PRODUCT_TYPE = 'C' THEN
                'G06_1_2.3.H.2017'
               WHEN PRODUCT_TYPE = 'D' THEN
                'G06_1_2.4.H.2017'
             END,
             SUM(LJYHDSY),
             '2'
        FROM (SELECT A.PRODUCT_TYPE,
                     T.PRODUCT_CODE AS PRODUCT_CODE,
                     CASE
                        WHEN SUBSTR(I_DATADATE,5,4) = '0131' THEN NVL(T.YHDSY, 0)
                        ELSE  NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0)
                      END AS LJYHDSY -- 累计实现银行端收益
                FROM SMTMODS_L_FIMM_PRODUCT_BAL T
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT A
                  ON A.PRODUCT_CODE = T.PRODUCT_CODE
                 AND A.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT_BAL T1
                  ON T.PRODUCT_CODE = T1.PRODUCT_CODE
                 AND T1.DATA_DATE = LAST_DATA
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.DATE_SOURCESD <> 'ZGXT'
                 AND T.PRODUCT_CODE <> '60211401'
                 AND NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0) <> 0
              UNION ALL
              SELECT 'A' AS PRODUCT_TYPE,
                     T.PRODUCT_CODE AS PRODUCT_CODE,
                     CASE
                        WHEN SUBSTR(I_DATADATE,5,4) = '0131' THEN NVL(T.YHDSY, 0)
                        ELSE  NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0)
                      END AS LJYHDSY -- 虚拟产品60211401累计实现银行端收益
                FROM SMTMODS_L_FIMM_PRODUCT_BAL T
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT A
                  ON A.PRODUCT_CODE = T.PRODUCT_CODE
                 AND A.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_FIMM_PRODUCT_BAL T1
                  ON T.PRODUCT_CODE = T1.PRODUCT_CODE
                 AND T1.DATA_DATE = LAST_DATA
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.DATE_SOURCESD <> 'ZGXT'
                 AND T.PRODUCT_CODE = '60211401'
                 AND NVL(T.YHDSY, 0) - NVL(T1.YHDSY, 0) <> 0)
       GROUP BY CASE
                  WHEN PRODUCT_TYPE = 'A' THEN
                   'G06_1_2.1.H.2017'
                  WHEN PRODUCT_TYPE = 'B' THEN
                   'G06_1_2.2.H.2017'
                  WHEN PRODUCT_TYPE = 'C' THEN
                   'G06_1_2.3.H.2017'
                  WHEN PRODUCT_TYPE = 'D' THEN
                   'G06_1_2.4.H.2017'
                END;

INSERT INTO `G06_1_2.1.H.2017`
        (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
        SELECT I_DATADATE,
               '009816',
               'CBRC',
               'G06_1',
               'G06_1_2.5.H.2017',
               SUM(ITEM_VAL),
               '2'
          FROM CBRC_A_REPT_ITEM_VAL T
         WHERE T.DATA_DATE = I_DATADATE
           AND T.ORG_NUM = '009816'
           AND T.ITEM_NUM IN ('G06_1_2.1.H.2017',
                              'G06_1_2.2.H.2017',
                              'G06_1_2.3.H.2017',
                              'G06_1_2.4.H.2017');


