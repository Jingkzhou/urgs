-- ============================================================
-- 文件名: G01资产负债项目统计表附注9.sql
-- 生成时间: 2025-12-18 13:53:37
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- ========== 逻辑组 0: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_9_4..B' AS ITEM_NUM, --指标号
             SUM(T.DEBIT_BAL * LPR.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM 
        SMTMODS_V_PUB_IDX_FINA_GL t
        LEFT JOIN SMTMODS_L_PUBL_RATE LPR
          ON LPR.DATA_DATE = I_DATADATE
         AND T.CURR_CD = LPR.BASIC_CCY
       WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND
             I_DATADATE
         AND T.CURR_CD in ('JPY', 'USD', 'EUR', 'HKD') --<> 'CNY'
         AND LPR.FORWARD_CCY = 'CNY'
         AND ITEM_CD IN ('13030101', /*'129'*/
                         '13030102',
                         '13030103',
                         '13030201',
                         '13030202',
                         '13030203',
                         '13030301',
                         '13030302',
                         '13030303',
                         '13050101',
                         '13050102',
                         '13050103',
                         '13060101',
                         '13060102',
                         '13060103',
                         '13060201',
                         '13060202',
                         '13060203',
                         '13060301',
                         '13060302',
                         '13060303',
                         '13060401',
                         '13060402',
                         '13060403',
                         '13060501',
                         '13060502',
                         '13060503',
                         '13010101', --以摊余成本计量的银行承兑汇票贴现面值
                         '13010103', --以摊余成本计量的银行承兑汇票贴现已减值
                         '13010104', --以摊余成本计量的商业承兑汇票贴现面值
                         '13010106', --以摊余成本计量的商业承兑汇票贴现已减值
                         '13010201', --以摊余成本计量的银行承兑汇票转贴现面值
                         '13010203', --以摊余成本计量的银行承兑汇票转贴现已减值
                         '13010204', --以摊余成本计量的商业承兑汇票转贴现面值
                         '13010206', --以摊余成本计量的商业承兑汇票转贴现已减值
                         '13010301', --买入外币票据面值
                         '13010303', --买入外币票据已减值
                        /* '1290401', --以摊余成本计量的自承自贴转贴现面值
                         '1290403', --以摊余成本计量的自承自贴转贴现已减值*/
                         '13010401', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现面值
                         '13010403', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现已减值
                         '13010405', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现面值
                         '13010407', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现已减值
                         '13010501', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现面值
                         '13010503', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现已减值
                         '13010505', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现面值
                         '13010507' --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现已减值
          /*               '1290701', --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现面值
                         '1290703'*/) --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现已减值
       GROUP BY I_DATADATE, ORG_NUM, V_REP_NUM
      --除了日元、美元、欧元、港币以外的币种 需要转美元后，再转人民币，乘以月末最后一天汇率
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_9_4..B' AS ITEM_NUM, --指标号
             SUM(USD_TMP.ITEM_VAL * L1.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT ORG_NUM AS ORG_NUM, --机构号
                     SUM(T.DEBIT_BAL * LPR.CCY_RATE) AS ITEM_VAL, --指标值
                     'USD' AS CURR_CD --币种
                FROM 
                SMTMODS_V_PUB_IDX_FINA_GL T
                LEFT JOIN SMTMODS_L_PUBL_RATE LPR
                  ON LPR.DATA_DATE = I_DATADATE
                 AND T.CURR_CD = LPR.BASIC_CCY
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND
                     I_DATADATE
                 AND T.CURR_CD not in ('JPY', 'USD', 'EUR', 'HKD', 'CNY','BWB')
                 AND LPR.FORWARD_CCY = 'USD'
                 AND ITEM_CD IN ('13030101', /*'129'*/
                         '13030102',
                         '13030103',
                         '13030201',
                         '13030202',
                         '13030203',
                         '13030301',
                         '13030302',
                         '13030303',
                         '13050101',
                         '13050102',
                         '13050103',
                         '13060101',
                         '13060102',
                         '13060103',
                         '13060201',
                         '13060202',
                         '13060203',
                         '13060301',
                         '13060302',
                         '13060303',
                         '13060401',
                         '13060402',
                         '13060403',
                         '13060501',
                         '13060502',
                         '13060503',
                         '13010101', --以摊余成本计量的银行承兑汇票贴现面值
                         '13010103', --以摊余成本计量的银行承兑汇票贴现已减值
                         '13010104', --以摊余成本计量的商业承兑汇票贴现面值
                         '13010106', --以摊余成本计量的商业承兑汇票贴现已减值
                         '13010201', --以摊余成本计量的银行承兑汇票转贴现面值
                         '13010203', --以摊余成本计量的银行承兑汇票转贴现已减值
                         '13010204', --以摊余成本计量的商业承兑汇票转贴现面值
                         '13010206', --以摊余成本计量的商业承兑汇票转贴现已减值
                         '13010301', --买入外币票据面值
                         '13010303', --买入外币票据已减值
                        /* '1290401', --以摊余成本计量的自承自贴转贴现面值
                         '1290403', --以摊余成本计量的自承自贴转贴现已减值*/
                         '13010401', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现面值
                         '13010403', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现已减值
                         '13010405', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现面值
                         '13010407', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现已减值
                         '13010501', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现面值
                         '13010503', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现已减值
                         '13010505', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现面值
                         '13010507' --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现已减值
          /*               '1290701', --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现面值
                         '1290703'*/) --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现已减值
               GROUP BY ORG_NUM) USD_TMP
        LEFT JOIN SMTMODS_L_PUBL_RATE L1
          ON L1.DATA_DATE = I_DATADATE
         AND USD_TMP.CURR_CD = L1.BASIC_CCY
       WHERE L1.FORWARD_CCY = 'CNY'
       GROUP BY ORG_NUM, V_REP_NUM, I_DATADATE
) q_0
INSERT INTO `G01_9_4..B` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_9_4..B` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 1: 共 3 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM, --机构号
             A.SYS_NAM, --模块简称
             A.REP_NUM, --模块简称
             'G01_9_11.C.2016' AS ITEM_NUM, --指标号
             CASE
               WHEN substr(I_DATADATE, 5, 2) in ('03', '06', '09', '12') then
                (VAL1 -
                least(VAL2,
                       VAL3 *
                       (1 + ((VAL4 - VAL5) / VAL5) + ((VAL6 - VAL7) / VAL7) +
                       ((VAL8 - VAL9) / VAL9) + ((VAL10 - VAL11) / VAL11)))) --待确认
               else
                (VAL1 - VAL2) / VAL2
             end AS ITEM_VAL, --指标值
             A.FLAG --标志位
        FROM (SELECT SUM(ITEM_VAL) VAL2, ORG_NUM, REP_NUM, SYS_NAM, FLAG
                FROM CBRC_A_REPT_ITEM_VAL
               WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                 AND DATA_DATE = I_DATADATE
               GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) A
       INNER JOIN (SELECT SUM(ITEM_VAL) VAL1, ORG_NUM, SYS_NAM, REP_NUM
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_1..A', 'G01_9_1..B')
                      AND replace(DATA_DATE, '-', '') = I_DATADATE
                    GROUP BY ORG_NUM, SYS_NAM, REP_NUM) B
          ON A.ORG_NUM = B.ORG_NUM
         AND A.REP_NUM = B.REP_NUM
         AND A.SYS_NAM = B.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL3,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -1),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C3
          ON A.ORG_NUM = C3.ORG_NUM
         AND A.REP_NUM = C3.REP_NUM
         AND A.SYS_NAM = C3.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL4,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -3),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C4
          ON A.ORG_NUM = C4.ORG_NUM
         AND A.REP_NUM = C4.REP_NUM
         AND A.SYS_NAM = C4.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL5,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -4),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C5
          ON A.ORG_NUM = C5.ORG_NUM
         AND A.REP_NUM = C5.REP_NUM
         AND A.SYS_NAM = C5.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL6,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -6),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C6
          ON A.ORG_NUM = C6.ORG_NUM
         AND A.REP_NUM = C6.REP_NUM
         AND A.SYS_NAM = C6.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL7,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -7),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C7
          ON A.ORG_NUM = C7.ORG_NUM
         AND A.REP_NUM = C7.REP_NUM
         AND A.SYS_NAM = C7.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL8,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -9),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C8
          ON A.ORG_NUM = C8.ORG_NUM
         AND A.REP_NUM = C8.REP_NUM
         AND A.SYS_NAM = C8.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL9,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -10),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C9
          ON A.ORG_NUM = C9.ORG_NUM
         AND A.REP_NUM = C9.REP_NUM
         AND A.SYS_NAM = C9.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL10,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -12),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C10
          ON A.ORG_NUM = C10.ORG_NUM
         AND A.REP_NUM = C10.REP_NUM
         AND A.SYS_NAM = C10.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL11,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -13),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C11
          ON A.ORG_NUM = C11.ORG_NUM
         AND A.REP_NUM = C11.REP_NUM
         AND A.SYS_NAM = C11.SYS_NAM
) q_1
INSERT INTO `G01_9_11.C.2016` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_9_1..A` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_9_1..B` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 2: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_9_2..B' AS ITEM_NUM, --指标号
             SUM(T.CREDIT_BAL * LPR.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM  SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE LPR
          ON LPR.DATA_DATE = I_DATADATE
         AND T.CURR_CD = LPR.BASIC_CCY
       WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND I_DATADATE
         AND T.CURR_CD in ('JPY', 'USD', 'EUR', 'HKD') --<> 'CNY'
         AND LPR.FORWARD_CCY = 'CNY'
         AND ITEM_CD IN ('20110201',
                         '20110205',
                         '20110202',
                         '20110203',
                         '20110204',
                         '20110211',
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
                         '20110206',
                         '20130101',
                         '20130201',
                         '20130301',
                         '20140101',
                         '20140201',
                         '20140301',
                         '20110114',
                         '20110115',
                         '20110209',
                         '20110210',
                         '20110110',
                         '20110208',
                         '20110113',
                         '20110701',
                         '20100101',-- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
                         '20110207',
                         '20110112',
                         '22410101','20110301','20110302','20110303','22410102','20080101','20090101' ,--[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款 22410102个人久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
                         '20120106',--保险业金融机构存放款项
                         '20120204') --保险业金融机构存放款项
       GROUP BY I_DATADATE, ORG_NUM, V_REP_NUM
      --除了日元、美元、欧元、港币以外的币种 需要转美元后，再转人民币，乘以月末最后一天汇率
      UNION ALL
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_9_2..B' AS ITEM_NUM, --指标号
             SUM(USD_TMP.ITEM_VAL * L1.CCY_RATE) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM (SELECT ORG_NUM AS ORG_NUM, --机构号
                     SUM(T.CREDIT_BAL * LPR.CCY_RATE) AS ITEM_VAL, --指标值
                     'USD' AS CURR_CD --币种
                FROM 
                SMTMODS_V_PUB_IDX_FINA_GL T
                LEFT JOIN SMTMODS_L_PUBL_RATE LPR
                  ON LPR.DATA_DATE = I_DATADATE
                 AND T.CURR_CD = LPR.BASIC_CCY
               WHERE T.DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND
                     I_DATADATE
                 AND T.CURR_CD not in ('JPY', 'USD', 'EUR', 'HKD', 'CNY','BWB')
                 AND LPR.FORWARD_CCY = 'USD'
                 AND ITEM_CD IN ('20110201',
                         '20110205',
                         '20110202',
                         '20110203',
                         '20110204',
                         '20110211',
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
                         '20110206',
                         '20130101',
                         '20130201',
                         '20130301',
                         '20140101',
                         '20140201',
                         '20140301',
                         '20110114',
                         '20110115',
                         '20110209',
                         '20110210',
                         '20110110',
                         '20110208',
                         '20110113',
                         '20110701',
                         '20100101',-- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
                         '20110207',
                         '20110112',
                         '22410101','20110301','20110302','20110303','22410102' ,'20080101','20090101',--[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款 22410102个人久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
                         '20120106',--保险业金融机构存放款项
                         '20120204') --保险业金融机构存放款项
               GROUP BY ORG_NUM) USD_TMP
        LEFT JOIN SMTMODS_L_PUBL_RATE L1
          ON L1.DATA_DATE = I_DATADATE
         AND USD_TMP.CURR_CD = L1.BASIC_CCY
       WHERE L1.FORWARD_CCY = 'CNY'
       GROUP BY ORG_NUM, V_REP_NUM, I_DATADATE;

--==================================================
    --   G0109 11.存款偏离度
    --==================================================
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    

      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM, --机构号
             A.SYS_NAM, --模块简称
             A.REP_NUM, --模块简称
             'G01_9_11.C.2016' AS ITEM_NUM, --指标号
             CASE
               WHEN substr(I_DATADATE, 5, 2) in ('03', '06', '09', '12') then
                (VAL1 -
                least(VAL2,
                       VAL3 *
                       (1 + ((VAL4 - VAL5) / VAL5) + ((VAL6 - VAL7) / VAL7) +
                       ((VAL8 - VAL9) / VAL9) + ((VAL10 - VAL11) / VAL11)))) --待确认
               else
                (VAL1 - VAL2) / VAL2
             end AS ITEM_VAL, --指标值
             A.FLAG --标志位
        FROM (SELECT SUM(ITEM_VAL) VAL2, ORG_NUM, REP_NUM, SYS_NAM, FLAG
                FROM CBRC_A_REPT_ITEM_VAL
               WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                 AND DATA_DATE = I_DATADATE
               GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) A
       INNER JOIN (SELECT SUM(ITEM_VAL) VAL1, ORG_NUM, SYS_NAM, REP_NUM
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_1..A', 'G01_9_1..B')
                      AND replace(DATA_DATE, '-', '') = I_DATADATE
                    GROUP BY ORG_NUM, SYS_NAM, REP_NUM) B
          ON A.ORG_NUM = B.ORG_NUM
         AND A.REP_NUM = B.REP_NUM
         AND A.SYS_NAM = B.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL3,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -1),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C3
          ON A.ORG_NUM = C3.ORG_NUM
         AND A.REP_NUM = C3.REP_NUM
         AND A.SYS_NAM = C3.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL4,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -3),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C4
          ON A.ORG_NUM = C4.ORG_NUM
         AND A.REP_NUM = C4.REP_NUM
         AND A.SYS_NAM = C4.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL5,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -4),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C5
          ON A.ORG_NUM = C5.ORG_NUM
         AND A.REP_NUM = C5.REP_NUM
         AND A.SYS_NAM = C5.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL6,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -6),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C6
          ON A.ORG_NUM = C6.ORG_NUM
         AND A.REP_NUM = C6.REP_NUM
         AND A.SYS_NAM = C6.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL7,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -7),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C7
          ON A.ORG_NUM = C7.ORG_NUM
         AND A.REP_NUM = C7.REP_NUM
         AND A.SYS_NAM = C7.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL8,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -9),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C8
          ON A.ORG_NUM = C8.ORG_NUM
         AND A.REP_NUM = C8.REP_NUM
         AND A.SYS_NAM = C8.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL9,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -10),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C9
          ON A.ORG_NUM = C9.ORG_NUM
         AND A.REP_NUM = C9.REP_NUM
         AND A.SYS_NAM = C9.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL10,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -12),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C10
          ON A.ORG_NUM = C10.ORG_NUM
         AND A.REP_NUM = C10.REP_NUM
         AND A.SYS_NAM = C10.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL11,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -13),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C11
          ON A.ORG_NUM = C11.ORG_NUM
         AND A.REP_NUM = C11.REP_NUM
         AND A.SYS_NAM = C11.SYS_NAM
) q_2
INSERT INTO `G01_9_2..B` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_9_2..B` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

-- ========== 逻辑组 3: 共 2 个指标 ==========
FROM (
SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_9_2..A' AS ITEM_NUM, --指标号
             SUM(CREDIT_BAL) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM   SMTMODS_V_PUB_IDX_FINA_GL
       WHERE DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND  I_DATADATE
         AND CURR_CD = 'CNY'
         AND ITEM_CD IN ('20110201',
                         '20110205',
                         '20110202',
                         '20110203',
                         '20110204',
                         '20110211',
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
                         '20110206',
                         '20130101',
                         '20130201',
                         '20130301',
                         '20140101',
                         '20140201',
                         '20140301',
                         '20110114',
                         '20110115',
                         '20110209',
                         '20110210',
                         '20110110',
                         '20110208',
                         '20110113',
                         '20110701',
                         '20100101',-- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
                         '20110207',
                         '20110112',
                         '22410101','20110301','20110302','20110303','22410102','20080101','20090101' ,--[JLBA202507210012][石雨][修改内容：22410101单位久悬未取款 22410102个人久悬未取款、201103（财政性存款）调整为 一般单位活期存款]
                         '20120106',--保险业金融机构存放款项
                         '20120204') --保险业金融机构存放款项
       GROUP BY I_DATADATE, ORG_NUM, V_REP_NUM;

--==================================================
    --   G0109 11.存款偏离度
    --==================================================
    INSERT INTO `__INDICATOR_PLACEHOLDER__`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
    

      SELECT I_DATADATE AS DATA_DATE, --数据日期
             A.ORG_NUM, --机构号
             A.SYS_NAM, --模块简称
             A.REP_NUM, --模块简称
             'G01_9_11.C.2016' AS ITEM_NUM, --指标号
             CASE
               WHEN substr(I_DATADATE, 5, 2) in ('03', '06', '09', '12') then
                (VAL1 -
                least(VAL2,
                       VAL3 *
                       (1 + ((VAL4 - VAL5) / VAL5) + ((VAL6 - VAL7) / VAL7) +
                       ((VAL8 - VAL9) / VAL9) + ((VAL10 - VAL11) / VAL11)))) --待确认
               else
                (VAL1 - VAL2) / VAL2
             end AS ITEM_VAL, --指标值
             A.FLAG --标志位
        FROM (SELECT SUM(ITEM_VAL) VAL2, ORG_NUM, REP_NUM, SYS_NAM, FLAG
                FROM CBRC_A_REPT_ITEM_VAL
               WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                 AND DATA_DATE = I_DATADATE
               GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) A
       INNER JOIN (SELECT SUM(ITEM_VAL) VAL1, ORG_NUM, SYS_NAM, REP_NUM
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_1..A', 'G01_9_1..B')
                      AND replace(DATA_DATE, '-', '') = I_DATADATE
                    GROUP BY ORG_NUM, SYS_NAM, REP_NUM) B
          ON A.ORG_NUM = B.ORG_NUM
         AND A.REP_NUM = B.REP_NUM
         AND A.SYS_NAM = B.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL3,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -1),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C3
          ON A.ORG_NUM = C3.ORG_NUM
         AND A.REP_NUM = C3.REP_NUM
         AND A.SYS_NAM = C3.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL4,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -3),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C4
          ON A.ORG_NUM = C4.ORG_NUM
         AND A.REP_NUM = C4.REP_NUM
         AND A.SYS_NAM = C4.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL5,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -4),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C5
          ON A.ORG_NUM = C5.ORG_NUM
         AND A.REP_NUM = C5.REP_NUM
         AND A.SYS_NAM = C5.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL6,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -6),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C6
          ON A.ORG_NUM = C6.ORG_NUM
         AND A.REP_NUM = C6.REP_NUM
         AND A.SYS_NAM = C6.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL7,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -7),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C7
          ON A.ORG_NUM = C7.ORG_NUM
         AND A.REP_NUM = C7.REP_NUM
         AND A.SYS_NAM = C7.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL8,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -9),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C8
          ON A.ORG_NUM = C8.ORG_NUM
         AND A.REP_NUM = C8.REP_NUM
         AND A.SYS_NAM = C8.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL9,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -10),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C9
          ON A.ORG_NUM = C9.ORG_NUM
         AND A.REP_NUM = C9.REP_NUM
         AND A.SYS_NAM = C9.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL10,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -12),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C10
          ON A.ORG_NUM = C10.ORG_NUM
         AND A.REP_NUM = C10.REP_NUM
         AND A.SYS_NAM = C10.SYS_NAM
        LEFT JOIN (SELECT SUM(ITEM_VAL) VAL11,
                          ORG_NUM,
                          REP_NUM,
                          SYS_NAM,
                          FLAG
                     FROM CBRC_A_REPT_ITEM_VAL
                    WHERE ITEM_NUM IN ('G01_9_2..A', 'G01_9_2..B')
                      AND DATA_DATE =
                          to_char(add_months(date(I_DATADATE, 'yyyymmdd'),
                                             -13),
                                  'yyyymmdd')
                    GROUP BY ORG_NUM, REP_NUM, SYS_NAM, FLAG) C11
          ON A.ORG_NUM = C11.ORG_NUM
         AND A.REP_NUM = C11.REP_NUM
         AND A.SYS_NAM = C11.SYS_NAM
) q_3
INSERT INTO `G01_9_2..A` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_9_2..A` (DATA_DATE,  
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
             V_REP_NUM AS REP_NUM, --报表编号
             'G01_9_4..A' AS ITEM_NUM, --指标号
             SUM(DEBIT_BAL) AS ITEM_VAL, --指标值
             '2' AS FLAG
        FROM 
        SMTMODS_V_PUB_IDX_FINA_GL
       WHERE DATA_DATE BETWEEN SUBSTR(I_DATADATE, 0, 6) || '01' AND
             I_DATADATE
         AND CURR_CD = 'CNY'
         AND ITEM_CD IN ('13030101', /*'129'*/
                         '13030102',
                         '13030103',
                         '13030201',
                         '13030202',
                         '13030203',
                         '13030301',
                         '13030302',
                         '13030303',
                         '13050101',
                         '13050102',
                         '13050103',
                         '13060101',
                         '13060102',
                         '13060103',
                         '13060201',
                         '13060202',
                         '13060203',
                         '13060301',
                         '13060302',
                         '13060303',
                         '13060401',
                         '13060402',
                         '13060403',
                         '13060501',
                         '13060502',
                         '13060503',
                         '13010101', --以摊余成本计量的银行承兑汇票贴现面值
                         '13010103', --以摊余成本计量的银行承兑汇票贴现已减值
                         '13010104', --以摊余成本计量的商业承兑汇票贴现面值
                         '13010106', --以摊余成本计量的商业承兑汇票贴现已减值
                         '13010201', --以摊余成本计量的银行承兑汇票转贴现面值
                         '13010203', --以摊余成本计量的银行承兑汇票转贴现已减值
                         '13010204', --以摊余成本计量的商业承兑汇票转贴现面值
                         '13010206', --以摊余成本计量的商业承兑汇票转贴现已减值
                         '13010301', --买入外币票据面值
                         '13010303', --买入外币票据已减值
                        /* '1290401', --以摊余成本计量的自承自贴转贴现面值
                         '1290403', --以摊余成本计量的自承自贴转贴现已减值*/
                         '13010401', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现面值
                         '13010403', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票贴现已减值
                         '13010405', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现面值
                         '13010407', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票贴现已减值
                         '13010501', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现面值
                         '13010503', --以公允价值计量且其变动计入其他综合收益的银行承兑汇票转贴现已减值
                         '13010505', --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现面值
                         '13010507' --以公允价值计量且其变动计入其他综合收益的商业承兑汇票转贴现已减值
          /*               '1290701', --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现面值
                         '1290703'*/) --以公允价值计量且其变动计入其他综合收益的自承自贴转贴现已减值
       GROUP BY I_DATADATE, ORG_NUM, V_REP_NUM
) q_4
INSERT INTO `G01_9_4..A` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *
INSERT INTO `G01_9_4..A` (DATA_DATE,  
       ORG_NUM,  
       SYS_NAM,  
       REP_NUM,  
       ITEM_NUM,  
       ITEM_VAL,  
       FLAG)
SELECT *;

