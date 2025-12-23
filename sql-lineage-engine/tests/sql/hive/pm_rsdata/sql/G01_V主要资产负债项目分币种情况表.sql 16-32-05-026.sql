-- ============================================================
-- 文件名: G01_V主要资产负债项目分币种情况表.sql
-- 生成时间: 2025-12-18 13:53:37
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G01_5' AS REP_NUM, --报表编号
       CASE CURR_CD
         WHEN 'USD' THEN
          'G01_5_11..A.2023'
         WHEN 'EUR' THEN
          'G01_5_11..B.2023'
         WHEN 'JPY' THEN
          'G01_5_11..C.2023'
         WHEN 'HKD' THEN
          'G01_5_11..D.2023'
         WHEN 'GBP' THEN
          'G01_5_11..E.2023'
       END AS ITEM_NUM, --指标号
       SUM(ITEM_VAL) AS ITEM_VAL, --指标值
       '1' AS FLAG
  FROM (
        ---预付账款
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('1123')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        UNION ALL
        --3打头（轧差）
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE
                      WHEN (A.DEBIT_BAL - A.CREDIT_BAL) > 0 THEN
                       ((A.DEBIT_BAL - A.CREDIT_BAL) * B.CCY_RATE)
                      ELSE
                       0
                    END) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('300101',
                             '300102',
                             '300103',
                             '300104',
                             '300105',
                             '300106',
                             '300107',
                             '300108',
                             '300109',
                             '300199',
                             '3002',
                             '3003',
                             '3007',--alter by 石雨 20250427 JLBA202504180011
                             '3004',
                             '3005',
                             '3006',
                             '3101',
                             '3500')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        UNION ALL
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL > 0 THEN
                   ITEM_VAL
                  ELSE
                   0
                END AS ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD = '3020' THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD = '3010' THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN ('3020', '3010')
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        UNION ALL
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL > 0 THEN
                   ITEM_VAL
                  ELSE
                   0
                END AS ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD = '3040' THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD = '3030' THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN ('3040', '3030')
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        UNION ALL
        ---待处理财产损溢
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM((A.DEBIT_BAL - A.CREDIT_BAL) * B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('1901')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        --利息调整利息调整及贴现公允价值变动
        UNION ALL
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM((A.DEBIT_BAL - A.CREDIT_BAL) * B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('13010102',
                             '13010105',
                             '13010202',
                             '13010205',
                             '13010302',
                             '13010402',
                             '13010406',
                             '13010502',
                             '13010506',
                             '13030102',
                             '13030202',
                             '13030302',
                             '13050102',
                             '13060102',
                             '13060202',
                             '13060302',
                             '13060402',
                             '13060502',
                             '13010404',
                             '13010408',
                             '13010504',
                             '13010508')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        --代理业务资产-负责
        UNION ALL
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL > 0 THEN
                   ITEM_VAL
                  ELSE
                   0
                END ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD IN ('1321') THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD = '2314' THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN ('1321', '2314')
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        UNION ALL
        --同业存单
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE
                      WHEN A.ITEM_CD IN
                           ('11010105', '11020105', '15010105', '15030105') THEN
                       A.DEBIT_BAL * B.CCY_RATE
                      WHEN A.ITEM_CD IN ('11010205',
                                         '11020205',
                                         '15010305',
                                         '15010505',
                                         '15030305',
                                         '15030505',
                                         '15030705') THEN
                       (A.DEBIT_BAL - A.CREDIT_BAL) * B.CCY_RATE
                    END) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('11010105',
                             '11020105',
                             '15010105',
                             '15030105',
                             '11010205',
                             '11020205',
                             '15010305',
                             '15010505',
                             '15030305',
                             '15030505',
                             '15030705')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        --投资性房地产
        UNION ALL
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE
                      WHEN A.ITEM_CD IN ('1521') THEN
                       A.DEBIT_BAL * B.CCY_RATE
                      WHEN A.ITEM_CD IN ('1522') THEN
                       (-1 * A.CREDIT_BAL) * B.CCY_RATE
                    END) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('1521', '1522')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        --财政差
        UNION ALL
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL > 0 THEN
                   ITEM_VAL
                  ELSE
                   0
                END ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD IN ('100303') THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD IN
                                   (/*'201103', */'201104', '201105', '201106' --[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款,原逻辑中剔除]
                                   ,'2005'/*,'2008','2009'*/ -- 修改内容：调整代理国库业务会计科目_20250513
                                     ) THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN
                        ('100303', /*'201103',*/ '201104', '201105', '201106'--[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款,原逻辑中剔除]
                        ,'2005'/*,'2008','2009'*/ -- 修改内容：调整代理国库业务会计科目_20250513
                           )
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        UNION ALL
        --合同资产--使用权资产--继续涉入资产
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE
                      WHEN A.ITEM_CD IN ('1607', '1518') THEN
                       (A.DEBIT_BAL - A.CREDIT_BAL) * B.CCY_RATE
                      WHEN A.ITEM_CD = '1609' THEN
                       A.DEBIT_BAL * B.CCY_RATE
                      WHEN A.ITEM_CD = '1610' THEN
                       A.CREDIT_BAL * B.CCY_RATE
                    END) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('1607', '1609', '1610', '1518')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
          union all
      SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(a.DEBIT_BAL*B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('1431','1132','1221','1801','1606','1604','1701','1441','1811')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
      union all
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(-1 * A.CREDIT_BAL*B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('1221','1702')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
  ---福费廷公允价值变动13010304 借-贷
          union all
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM((A.DEBIT_BAL - A.CREDIT_BAL)*B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('13010304')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD

         )
 GROUP BY ORG_NUM,
          CASE CURR_CD
            WHEN 'USD' THEN
             'G01_5_11..A.2023'
            WHEN 'EUR' THEN
             'G01_5_11..B.2023'
            WHEN 'JPY' THEN
             'G01_5_11..C.2023'
            WHEN 'HKD' THEN
             'G01_5_11..D.2023'
            WHEN 'GBP' THEN
             'G01_5_11..E.2023'
          END;

--------------------------------------------------------------------------

    --插入实际表
INSERT INTO `__INDICATOR_PLACEHOLDER__`
  (DATA_DATE, -- 数据日期
   ORG_NUM, --机构号
   SYS_NAM, --模块简称
   REP_NUM, --报表编号
   ITEM_NUM, --指标号
   ITEM_VAL, --指标值
   FLAG, --标志位
   IS_TOTAL)
  SELECT I_DATADATE AS DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         SUM(ITEM_VAL), --指标值
         FLAG, --标志位
         CASE
           WHEN ITEM_NUM IN ('G01_5_21..A.2023',
                  'G01_5_24..C.2023',
                  'G01_5_11..B.2023',
                  'G01_5_11..A.2023',
                  'G01_5_11..D.2023',
                  'G01_5_21..B.2023',
                  'G01_5_21..C.2023',
                  'G01_5_11..C.2023',
                  'G01_5_21..D.2023',
                  'G01_5_21..E.2023',
                  'G01_5_24..B.2023',
                  'G01_5_24..A.2023',
                  'G01_5_11..E.2023',
                  'G01_5_24..D.2023',
                  'G01_5_24..E.2023') THEN --MODI BY DJH 20230509不参与汇总
            'N'
         END IS_TOTAL
    FROM CBRC_TMP_G0105_A_REPT_ITEM_VAL
   GROUP BY ORG_NUM, --机构号
            SYS_NAM, --模块简称
            REP_NUM, --报表编号
            ITEM_NUM, --指标号
            FLAG --标志位
) q_0
INSERT INTO `G01_5_11..C.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_11..D.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_11..A.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_11..E.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_11..B.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 1: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_3..A.2023'
               WHEN 'EUR' THEN
                'G01_5_3..B.2023'
               WHEN 'JPY' THEN
                'G01_5_3..C.2023'
               WHEN 'HKD' THEN
                'G01_5_3..D.2023'
               WHEN 'GBP' THEN
                'G01_5_3..E.2023'
             END AS ITEM_NUM, --指标号
             SUM(A.DEBIT_BAL * B.CCY_RATE),
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         AND A.ITEM_CD IN ('1011', '1031')
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_3..A.2023'
               WHEN 'EUR' THEN
                'G01_5_3..B.2023'
               WHEN 'JPY' THEN
                'G01_5_3..C.2023'
               WHEN 'HKD' THEN
                'G01_5_3..D.2023'
               WHEN 'GBP' THEN
                'G01_5_3..E.2023'
             END
) q_1
INSERT INTO `G01_5_3..C.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_3..E.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_3..D.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_3..B.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_3..A.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 2: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END AS ITEM_NUM,
             SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
            --AND ITEM_CD in ('203','211','215','217','21902','22002')
         AND ITEM_CD IN ('20110110',
                         '20110101',
                         '20110102',
                         '20110103',
                         '20110104',
                         '20110105',
                         '20110106',
                         '20110107',
                         '20110108',
                         '20110109',
                         '20110111',
                         '20110112',
                         '20110113'
                         ,'22410102' --个人久悬未取款--[JLBA202507210012][石雨][修改内容：224101久悬未取款属于活期存款]
                         )
      /*  ('203', '211', '215', '217', '21902', '22002'\*,'201_13'*\) --lrt 20170927  -- 修改201_13科目从视图过滤 lfz 20220614*/ --老核心科目
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END;

INSERT INTO `__INDICATOR_PLACEHOLDER__` -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             CASE
       /*      WHEN ORG_NUM NOT LIKE '__98%' THEN
              SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END;

INSERT INTO `__INDICATOR_PLACEHOLDER__` -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             CASE
             /*  WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END;

INSERT INTO `__INDICATOR_PLACEHOLDER__` -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             CASE
              /* WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END;

INSERT INTO `__INDICATOR_PLACEHOLDER__` --
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
   SELECT I_DATADATE AS DATA_DATE,
             CASE
/*               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN T.ORG_NUM NOT LIKE '__98%' AND T.ORG_NUM NOT LIKE '5%' AND T.ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
               ELSE
                T.ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END AS ITEM_NUM,
    SUM(T.ACCT_BALANCE * B.CCY_RATE)  AS ITEM_VAL,
    '1' AS FLAG
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
        AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
    GROUP BY CASE
/*               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN T.ORG_NUM NOT LIKE '__98%' AND T.ORG_NUM NOT LIKE '5%' AND T.ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
               ELSE
                T.ORG_NUM
             END,CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_15..A.2023'
               WHEN 'EUR' THEN
                'G01_5_15..B.2023'
               WHEN 'JPY' THEN
                'G01_5_15..C.2023'
               WHEN 'HKD' THEN
                'G01_5_15..D.2023'
               WHEN 'GBP' THEN
                'G01_5_15..E.2023'
               END
) q_2
INSERT INTO `G01_5_15..D.2023` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *
INSERT INTO `G01_5_15..B.2023` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *
INSERT INTO `G01_5_15..E.2023` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *
INSERT INTO `G01_5_15..A.2023` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *
INSERT INTO `G01_5_15..C.2023` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *;

-- ========== 逻辑组 3: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G01_5' AS REP_NUM, --报表编号
       CASE CURR_CD
         WHEN 'USD' THEN
          'G01_5_21..A.2023'
         WHEN 'EUR' THEN
          'G01_5_21..B.2023'
         WHEN 'JPY' THEN
          'G01_5_21..C.2023'
         WHEN 'HKD' THEN
          'G01_5_21..D.2023'
         WHEN 'GBP' THEN
          'G01_5_21..E.2023'
       END AS ITEM_NUM, --指标号
       SUM(ITEM_VAL) AS ITEM_VAL, --指标值
       '1' AS FLAG
  FROM (
        --资金清算应付款
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE
                      WHEN (A.CREDIT_BAL - A.DEBIT_BAL) > 0 THEN
                       ((A.CREDIT_BAL - A.DEBIT_BAL) * B.CCY_RATE)
                      ELSE
                       0
                    END) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('2240')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        union all
        --向央行借款  贴现负债  开出本票  交易性金融负债 指定为以公允价值计量且其变动计入损益的金融负债
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(A.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('20040202', '2021', '2015', '2101', '2102')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        --同业存单
        union all
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM((A.CREDIT_BAL - A.DEBIT_BAL) * B.CCY_RATE) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('25020102', '250202')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        union all
        ---代理业务负责-资产
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL < 0 THEN
                   -1 * ITEM_VAL
                  ELSE
                   0
                END AS ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD = '1321' THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD = '2314' THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN ('1321', '2314')
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        union all
        ------------------------------------
        --3头轧差
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE
                      WHEN (A.DEBIT_BAL - A.CREDIT_BAL) < 0 THEN
                       -1 * ((A.DEBIT_BAL - A.CREDIT_BAL) * B.CCY_RATE)
                      ELSE
                       0
                    END) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('300101',
                             '300102',
                             '300103',
                             '300104',
                             '300105',
                             '300106',
                             '300107',
                             '300108',
                             '300109',
                             '300199',
                             '3002',
                             '3003',
                             '3007', --alter by 石雨 JLBA202504180011
                             '3004',
                             '3005',
                             '3006',
                             '3101',
                             '3500')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
        UNION ALL
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL < 0 THEN
                   -1 * ITEM_VAL
                  ELSE
                   0
                END AS ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD = '3020' THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD = '3010' THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN ('3020', '3010')
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        UNION ALL
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL < 0 THEN
                   -1 * ITEM_VAL
                  ELSE
                   0
                END AS ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD = '3040' THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD = '3030' THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN ('3040', '3030')
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        -----
        union all
        SELECT DATA_DATE,
                ORG_NUM,
                CURR_CD,
                CASE
                  WHEN ITEM_VAL < 0 THEN
                   -1 * ITEM_VAL
                  ELSE
                   0
                END ITEM_VAL
          FROM (SELECT I_DATADATE AS DATA_DATE,
                        ORG_NUM,
                        CURR_CD,
                        SUM(CASE
                              WHEN A.ITEM_CD IN ('100303') THEN
                               A.DEBIT_BAL * B.CCY_RATE
                              WHEN A.ITEM_CD IN
                                   (/*'201103',*/ '201104', '201105', '201106' --[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款,原逻辑中剔除]
                                   ,'2005'/*,'2008','2009'*/ -- 修改内容：调整代理国库业务会计科目_20250513
                                   ) THEN
                               -1 * A.CREDIT_BAL * B.CCY_RATE
                            END) AS ITEM_VAL --指标值
                   FROM SMTMODS_L_FINA_GL A
                   LEFT JOIN SMTMODS_L_PUBL_RATE B
                     ON B.DATA_DATE = I_DATADATE
                    AND A.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE A.DATA_DATE = I_DATADATE
                    AND A.ITEM_CD IN
                        ('100303', /*'201103', */'201104', '201105', '201106'--[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款,原逻辑中剔除]
                        ,'2005'/*,'2008','2009'*/ -- 修改内容：调整代理国库业务会计科目_20250513
                        )
                    AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
                  GROUP BY A.ORG_NUM, CURR_CD)
        union all
        ---合同负债 --继续涉入负债 --租赁负债 --衍生工具
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(case
                      when A.ITEM_CD IN ('2505', '2504', '3101') then
                       A.CREDIT_BAL * B.CCY_RATE
                      when A.ITEM_CD = '2503' then

                       (A.CREDIT_BAL - A.DEBIT_BAL) * B.CCY_RATE
                    end) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('2505', '2504', '3101', '2503')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
         UNION ALL
        SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM(CASE WHEN A.ITEM_CD IN ('2014','2221') THEN (A.CREDIT_BAL-

                a.DEBIT_BAL) *B.CCY_RATE
                  ELSE A.CREDIT_BAL *B.CCY_RATE END ) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('2014','2013','20110114','20110115','20110209','20110210','2231','2221','2211','2232','2241','2401','2801','2901')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD
         UNION ALL
         SELECT I_DATADATE AS DATA_DATE,
                ORG_NUM,
                CURR_CD,
                SUM( A.CREDIT_BAL *B.CCY_RATE *-1 ) AS ITEM_VAL --指标值
          FROM SMTMODS_L_FINA_GL A
          LEFT JOIN SMTMODS_L_PUBL_RATE B
            ON B.DATA_DATE = I_DATADATE
           AND A.CURR_CD = B.BASIC_CCY
           AND B.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND A.ITEM_CD IN ('201103','2008','2009','224101')
           AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         GROUP BY A.ORG_NUM, CURR_CD

         )
 group by ORG_NUM,
          CASE CURR_CD
            WHEN 'USD' THEN
             'G01_5_21..A.2023'
            WHEN 'EUR' THEN
             'G01_5_21..B.2023'
            WHEN 'JPY' THEN
             'G01_5_21..C.2023'
            WHEN 'HKD' THEN
             'G01_5_21..D.2023'
            WHEN 'GBP' THEN
             'G01_5_21..E.2023'
          END;

--------------------------------------------------------------------------

    --插入实际表
INSERT INTO `__INDICATOR_PLACEHOLDER__`
  (DATA_DATE, -- 数据日期
   ORG_NUM, --机构号
   SYS_NAM, --模块简称
   REP_NUM, --报表编号
   ITEM_NUM, --指标号
   ITEM_VAL, --指标值
   FLAG, --标志位
   IS_TOTAL)
  SELECT I_DATADATE AS DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         SUM(ITEM_VAL), --指标值
         FLAG, --标志位
         CASE
           WHEN ITEM_NUM IN ('G01_5_21..A.2023',
                  'G01_5_24..C.2023',
                  'G01_5_11..B.2023',
                  'G01_5_11..A.2023',
                  'G01_5_11..D.2023',
                  'G01_5_21..B.2023',
                  'G01_5_21..C.2023',
                  'G01_5_11..C.2023',
                  'G01_5_21..D.2023',
                  'G01_5_21..E.2023',
                  'G01_5_24..B.2023',
                  'G01_5_24..A.2023',
                  'G01_5_11..E.2023',
                  'G01_5_24..D.2023',
                  'G01_5_24..E.2023') THEN --MODI BY DJH 20230509不参与汇总
            'N'
         END IS_TOTAL
    FROM CBRC_TMP_G0105_A_REPT_ITEM_VAL
   GROUP BY ORG_NUM, --机构号
            SYS_NAM, --模块简称
            REP_NUM, --报表编号
            ITEM_NUM, --指标号
            FLAG --标志位
) q_3
INSERT INTO `G01_5_21..C.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_21..E.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_21..D.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_21..A.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_21..B.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 4: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_5..A.2023'
               WHEN 'EUR' THEN
                'G01_5_5..B.2023'
               WHEN 'JPY' THEN
                'G01_5_5..C.2023'
               WHEN 'HKD' THEN
                'G01_5_5..D.2023'
               WHEN 'GBP' THEN
                'G01_5_5..E.2023'
             END AS ITEM_NUM, --指标号
             SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1305'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_5..A.2023'
               WHEN 'EUR' THEN
                'G01_5_5..B.2023'
               WHEN 'JPY' THEN
                'G01_5_5..C.2023'
               WHEN 'HKD' THEN
                'G01_5_5..D.2023'
               WHEN 'GBP' THEN
                'G01_5_5..E.2023'
             END
) q_4
INSERT INTO `G01_5_5..A.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_5..B.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 5: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G01_5' AS REP_NUM, --报表编号
       CASE CURR_CD
         WHEN 'USD' THEN
          'G01_5_24..A.2023'
         WHEN 'EUR' THEN
          'G01_5_24..B.2023'
         WHEN 'JPY' THEN
          'G01_5_24..C.2023'
         WHEN 'HKD' THEN
          'G01_5_24..D.2023'
         WHEN 'GBP' THEN
          'G01_5_24..E.2023'
       END AS ITEM_NUM, --指标号
       SUM(case
             when A.ITEM_CD IN ('4001', '4002', '4101', '4102') THEN
              A.CREDIT_BAL
             WHEN A.ITEM_CD IN ('4003',
                                '4104',
                                '6011',
                                '6012',
                                '6021',
                                '6051',
                                '6061',
                                '6101',
                                '6111',
                                '6115',
                                '6116',
                                '6117',
                                '6301',
                                '6402',
                                '6403',
                                '6411',
                                '6412',
                                '6421',
                                '6601',
                                '6701',
                                '6702',
                                '6711',
                                '6801',
                                '6901') THEN
              (A.CREDIT_BAL - A.DEBIT_BAL)
           END

           * B.CCY_RATE) AS ITEM_VAL, --指标值
       '1' AS FLAG
  FROM SMTMODS_L_FINA_GL A
  LEFT JOIN SMTMODS_L_PUBL_RATE B
    ON B.DATA_DATE = I_DATADATE
   AND A.CURR_CD = B.BASIC_CCY
   AND B.FORWARD_CCY = 'CNY'
 WHERE A.DATA_DATE = I_DATADATE
   AND A.ITEM_CD IN ('4001',
                     '4002',
                     '4101',
                     '4102',
                     '4003',
                     '4104',
                     '6011',
                     '6012',
                     '6021',
                     '6051',
                     '6061',
                     '6101',
                     '6111',
                     '6115',
                     '6116',
                     '6117',
                     '6301',
                     '6402',
                     '6403',
                     '6411',
                     '6412',
                     '6421',
                     '6601',
                     '6701',
                     '6702',
                     '6711',
                     '6801',
                     '6901')
   AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
 GROUP BY A.ORG_NUM,
          CASE CURR_CD
         WHEN 'USD' THEN
          'G01_5_24..A.2023'
         WHEN 'EUR' THEN
          'G01_5_24..B.2023'
         WHEN 'JPY' THEN
          'G01_5_24..C.2023'
         WHEN 'HKD' THEN
          'G01_5_24..D.2023'
         WHEN 'GBP' THEN
          'G01_5_24..E.2023'
       END;

--------------------------------------------------------------------------

    --插入实际表
INSERT INTO `__INDICATOR_PLACEHOLDER__`
  (DATA_DATE, -- 数据日期
   ORG_NUM, --机构号
   SYS_NAM, --模块简称
   REP_NUM, --报表编号
   ITEM_NUM, --指标号
   ITEM_VAL, --指标值
   FLAG, --标志位
   IS_TOTAL)
  SELECT I_DATADATE AS DATA_DATE, --数据日期
         ORG_NUM, --机构号
         SYS_NAM, --模块简称
         REP_NUM, --报表编号
         ITEM_NUM, --指标号
         SUM(ITEM_VAL), --指标值
         FLAG, --标志位
         CASE
           WHEN ITEM_NUM IN ('G01_5_21..A.2023',
                  'G01_5_24..C.2023',
                  'G01_5_11..B.2023',
                  'G01_5_11..A.2023',
                  'G01_5_11..D.2023',
                  'G01_5_21..B.2023',
                  'G01_5_21..C.2023',
                  'G01_5_11..C.2023',
                  'G01_5_21..D.2023',
                  'G01_5_21..E.2023',
                  'G01_5_24..B.2023',
                  'G01_5_24..A.2023',
                  'G01_5_11..E.2023',
                  'G01_5_24..D.2023',
                  'G01_5_24..E.2023') THEN --MODI BY DJH 20230509不参与汇总
            'N'
         END IS_TOTAL
    FROM CBRC_TMP_G0105_A_REPT_ITEM_VAL
   GROUP BY ORG_NUM, --机构号
            SYS_NAM, --模块简称
            REP_NUM, --报表编号
            ITEM_NUM, --指标号
            FLAG --标志位
) q_5
INSERT INTO `G01_5_24..A.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_24..B.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_24..C.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_24..D.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_24..E.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 6: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_2..A.2023'
               WHEN 'EUR' THEN
                'G01_5_2..B.2023'
               WHEN 'JPY' THEN
                'G01_5_2..C.2023'
               WHEN 'HKD' THEN
                'G01_5_2..D.2023'
               WHEN 'GBP' THEN
                 'G01_5_2..E.2023'
             END AS ITEM_NUM, --指标号
             SUM(CASE
                   WHEN ITEM_CD IN ( '100303','100304') THEN
                    -A.DEBIT_BAL * B.CCY_RATE
                   ELSE
                    A.DEBIT_BAL * B.CCY_RATE
                 END) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('1003', '100303','100304')
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_2..A.2023'
               WHEN 'EUR' THEN
                'G01_5_2..B.2023'
               WHEN 'JPY' THEN
                'G01_5_2..C.2023'
               WHEN 'HKD' THEN
                'G01_5_2..D.2023'
               WHEN 'GBP' THEN
                 'G01_5_2..E.2023'
             END
) q_6
INSERT INTO `G01_5_2..D.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_2..A.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 7: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_12..A.2023'
               WHEN 'EUR' THEN
                'G01_5_12..B.2023'
               WHEN 'JPY' THEN
                'G01_5_12..C.2023'
               WHEN 'HKD' THEN
                'G01_5_12..D.2023'
               WHEN 'GBP' THEN
                'G01_5_12..E.2023'
               END AS ITEM_NUM, --指标号
             SUM(A.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('1013','1112','1231','1304','1307','1442','1482','1502','1512','1523','1603','1605','1608','1611','1703','1712')
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_12..A.2023'
               WHEN 'EUR' THEN
                'G01_5_12..B.2023'
               WHEN 'JPY' THEN
                'G01_5_12..C.2023'
               WHEN 'HKD' THEN
                'G01_5_12..D.2023'
               WHEN 'GBP' THEN
                'G01_5_12..E.2023'
               END
) q_7
INSERT INTO `G01_5_12..A.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_12..B.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_12..C.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_12..E.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_12..D.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 8: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_19..A.2023'
               WHEN 'EUR' THEN
                'G01_5_19..B.2023'
               WHEN 'JPY' THEN
                'G01_5_19..C.2023'
               WHEN 'HKD' THEN
                'G01_5_19..D.2023'
               WHEN 'GBP' THEN
                'G01_5_19..E.2023'
               END AS ITEM_NUM, --指标号
             SUM( A.CREDIT_BAL * B.CCY_RATE ) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD ='2111'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_19..A.2023'
               WHEN 'EUR' THEN
                'G01_5_19..B.2023'
               WHEN 'JPY' THEN
                'G01_5_19..C.2023'
               WHEN 'HKD' THEN
                'G01_5_19..D.2023'
               WHEN 'GBP' THEN
                'G01_5_19..E.2023'
               END
) q_8
INSERT INTO `G01_5_19..B.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_19..A.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 9: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_1..A.2023'
               WHEN 'EUR' THEN
                'G01_5_1..B.2023'
               WHEN 'JPY' THEN
                'G01_5_1..C.2023'
               WHEN 'HKD' THEN
                'G01_5_1..D.2023'
               WHEN 'GBP' THEN
                'G01_5_1..E.2023'
             END AS ITEM_NUM, --指标号
             SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1001'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_1..A.2023'
               WHEN 'EUR' THEN
                'G01_5_1..B.2023'
               WHEN 'JPY' THEN
                'G01_5_1..C.2023'
               WHEN 'HKD' THEN
                'G01_5_1..D.2023'
               WHEN 'GBP' THEN
                'G01_5_1..E.2023'
             END
) q_9
INSERT INTO `G01_5_1..A.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_1..E.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_1..D.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_1..B.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_1..C.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 10: 共 4 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_17..A.2023'
               WHEN 'EUR' THEN
                'G01_5_17..B.2023'
               WHEN 'JPY' THEN
                'G01_5_17..C.2023'
               WHEN 'HKD' THEN
                'G01_5_17..D.2023'
               WHEN 'GBP' THEN
                'G01_5_17..E.2023'
               END AS ITEM_NUM, --指标号
             SUM(CASE ITEM_CD
                   WHEN '2012' THEN
                    A.CREDIT_BAL * B.CCY_RATE
                   ELSE

                    -1 * A.CREDIT_BAL * B.CCY_RATE
                 END) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('2012', '20120106','20120204')
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_17..A.2023'
               WHEN 'EUR' THEN
                'G01_5_17..B.2023'
               WHEN 'JPY' THEN
                'G01_5_17..C.2023'
               WHEN 'HKD' THEN
                'G01_5_17..D.2023'
               WHEN 'GBP' THEN
                'G01_5_17..E.2023'
               END
) q_10
INSERT INTO `G01_5_17..D.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_17..A.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_17..B.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_17..C.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- 指标: G01_5_9..A.2023
INSERT INTO `G01_5_9..A.2023`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_9..A.2023'
               WHEN 'EUR' THEN
                'G01_5_9..B.2023'
               WHEN 'JPY' THEN
                'G01_5_9..C.2023'
               WHEN 'HKD' THEN
                'G01_5_9..D.2023'
               WHEN 'GBP' THEN
                'G01_5_9..E.2023'
               END AS ITEM_NUM, --指标号
             SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD ='1111'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_9..A.2023'
               WHEN 'EUR' THEN
                'G01_5_9..B.2023'
               WHEN 'JPY' THEN
                'G01_5_9..C.2023'
               WHEN 'HKD' THEN
                'G01_5_9..D.2023'
               WHEN 'GBP' THEN
                'G01_5_9..E.2023'
               END;


-- ========== 逻辑组 12: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_7..A.2023'
               WHEN 'EUR' THEN
                'G01_5_7..B.2023'
               WHEN 'JPY' THEN
                'G01_5_7..C.2023'
               WHEN 'HKD' THEN
                'G01_5_7..D.2023'
               WHEN 'GBP' THEN
                'G01_5_7..E.2023'
             END AS ITEM_NUM, --指标号
             SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD ='1302'
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY A.ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_7..A.2023'
               WHEN 'EUR' THEN
                'G01_5_7..B.2023'
               WHEN 'JPY' THEN
                'G01_5_7..C.2023'
               WHEN 'HKD' THEN
                'G01_5_7..D.2023'
               WHEN 'GBP' THEN
                'G01_5_7..E.2023'
             END
) q_12
INSERT INTO `G01_5_7..B.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_7..A.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 13: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G01_5' AS REP_NUM, --报表编号
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END AS ITEM_NUM,
             SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_L_FINA_GL A
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON B.DATA_DATE = I_DATADATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
         AND ITEM_CD IN ('20110201',
                         '20110205',
                         '20110202',
                         '20110203',
                         '20110204',
                         '20110211', -- 转股协议存款 原逻辑没有
                         '20110701',
                         '2010', --alter by 20250527 修改国库存款科目
                         '20110206',
                         '20110207',
                         '20110208',
                         '20120106',
                         '20120204'
                          ,'20110301','20110302','20110303' --[JLBA202507210012][石雨][20250918][修改内容：201103（财政性存款 ）调整为 一般单位活期存款]
                         ,'22410101' --单位久悬未取款--[JLBA202507210012][石雨][20250918][修改内容：224101久悬未取款属于活期存款]
                         ,'20080101','20090101' --[JLBA202507210012][石雨][20250918]
                         )
      /*('201', '202', '205', '206', '218', '21901', '22001','234010204','2340204')*/ --老核心科目
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END;

INSERT INTO `__INDICATOR_PLACEHOLDER__` -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             CASE
               /*WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END;

INSERT INTO `__INDICATOR_PLACEHOLDER__` -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             CASE
              /* WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END;

INSERT INTO `__INDICATOR_PLACEHOLDER__` -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             CASE
/*               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN ORG_NUM NOT LIKE '__98%' AND ORG_NUM NOT LIKE '5%' AND ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END AS ITEM_NUM,
             SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
       GROUP BY ORG_NUM,
                CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END;

--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]剔除个体工商户部分

    INSERT INTO `__INDICATOR_PLACEHOLDER__` --
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
   SELECT I_DATADATE AS DATA_DATE,
             CASE
/*               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN T.ORG_NUM NOT LIKE '__98%' AND T.ORG_NUM NOT LIKE '5%' AND T.ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
               ELSE
                T.ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01_5' AS REP_NUM,
             CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END AS ITEM_NUM,
    SUM(T.ACCT_BALANCE * B.CCY_RATE) * -1 AS ITEM_VAL,
    '1' AS FLAG
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
        AND CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD','GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
    GROUP BY CASE
/*               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'*/
          WHEN T.ORG_NUM NOT LIKE '__98%' AND T.ORG_NUM NOT LIKE '5%' AND T.ORG_NUM NOT LIKE '6%'  THEN ---20231026 由于村镇截取后会变成总行
                SUBSTR(T.ORG_NUM, 1, 4) || '00'
               ELSE
                T.ORG_NUM
             END,CASE CURR_CD
               WHEN 'USD' THEN
                'G01_5_14..A.2023'
               WHEN 'EUR' THEN
                'G01_5_14..B.2023'
               WHEN 'JPY' THEN
                'G01_5_14..C.2023'
               WHEN 'HKD' THEN
                'G01_5_14..D.2023'
               WHEN 'GBP' THEN
                'G01_5_14..E.2023'
               END
) q_13
INSERT INTO `G01_5_14..B.2023` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *
INSERT INTO `G01_5_14..D.2023` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *
INSERT INTO `G01_5_14..C.2023` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *
INSERT INTO `G01_5_14..A.2023` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *
INSERT INTO `G01_5_14..E.2023` (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
SELECT *;

-- ========== 逻辑组 14: 共 5 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G01_5' AS REP_NUM, --报表编号
       CASE CURR_CD
         WHEN 'USD' THEN
          'G01_5_8..A.2023'
         WHEN 'EUR' THEN
          'G01_5_8..B.2023'
         WHEN 'JPY' THEN
          'G01_5_8..C.2023'
         WHEN 'HKD' THEN
          'G01_5_8..D.2023'
         WHEN 'GBP' THEN
          'G01_5_8..E.2023'
       END AS ITEM_NUM, --指标号
       SUM(
           CASE
             WHEN A.ITEM_CD IN ('1101', '1102', '1501', '1503', '1504', '1511') THEN
              (A.DEBIT_BAL - A.CREDIT_BAL)
             WHEN A.ITEM_CD IN ('11010105', '11020105', '15010105', '15030105') THEN
              A.DEBIT_BAL * -1
             WHEN A.ITEM_CD IN ('11010205',
                                '11020205',
                                '15010305',
                                '15010505',
                                '15030305',
                                '15030505',
                                '15030705') THEN
              (A.DEBIT_BAL - A.CREDIT_BAL)
           END * B.CCY_RATE) AS ITEM_VAL, --指标值
       '1' AS FLAG
  FROM SMTMODS_L_FINA_GL A
  LEFT JOIN SMTMODS_L_PUBL_RATE B
    ON B.DATA_DATE = I_DATADATE
   AND A.CURR_CD = B.BASIC_CCY
   AND B.FORWARD_CCY = 'CNY'
 WHERE A.DATA_DATE = I_DATADATE
   AND A.ITEM_CD IN ('1101',
                     '1102',
                     '1501',
                     '1503',
                     '1504',
                     '1511',
                     '11010105',
                     '11020105',
                     '15010105',
                     '15030105',
                     '11010205',
                     '11020205',
                     '15010305',
                     '15010505',
                     '15030305',
                     '15030505',
                     '15030705')
   AND A.CURR_CD IN ('USD', 'EUR', 'JPY', 'HKD', 'GBP') --USD-美元 EUR-欧元 JPY-日元 HKD-香港元 GBP-英镑
 GROUP BY A.ORG_NUM,
          CASE CURR_CD
            WHEN 'USD' THEN
             'G01_5_8..A.2023'
            WHEN 'EUR' THEN
             'G01_5_8..B.2023'
            WHEN 'JPY' THEN
             'G01_5_8..C.2023'
            WHEN 'HKD' THEN
             'G01_5_8..D.2023'
            WHEN 'GBP' THEN
             'G01_5_8..E.2023'
          END
) q_14
INSERT INTO `G01_5_8..E.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_8..C.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_8..A.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_8..B.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_5_8..D.2023` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

