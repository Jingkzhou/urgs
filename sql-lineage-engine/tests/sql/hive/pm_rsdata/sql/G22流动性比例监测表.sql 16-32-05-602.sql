-- ============================================================
-- 文件名: G22流动性比例监测表.sql
-- 生成时间: 2025-12-18 13:53:39
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: G22R_2.5.A
INSERT 
INTO `G22R_2.5.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.5.A',
         SUM(CASE
               WHEN CURR_CD = 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
             WHEN A.ORG_NUM LIKE '%98%' THEN
              A.ORG_NUM
             WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
              '060300'
             ELSE
              SUBSTR(A.ORG_NUM, 1, 4) || '00'
           END AS ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(NVL(INTEREST_ACCURED, 0) + NVL(INTEREST_ACCURAL, 0)) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
                -- AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
             AND (A.MATUR_DATE_ACCURED IS NULL OR
                 A.MATUR_DATE_ACCURED - I_DATADATE <= 30)
             AND A.ORG_NUM <> '009804' --ADD BY CHM 20231012
           GROUP BY A.DATA_DATE,
                    CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                      WHEN A.ORG_NUM LIKE '%98%' THEN
                       A.ORG_NUM
                      WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                       '060300'
                      ELSE
                       SUBSTR(A.ORG_NUM, 1, 4) || '00'
                    END,
                    A.ACCT_CUR
          UNION ALL
          SELECT 
           I_DATADATE, ORG_NUM, T.CURR_CD, SUM(MINUS_AMT) AS MINUS_AMT
            FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP T
           WHERE ITEM_CD LIKE '2231%'
             AND QX IN ('NEXT_YS', 'NEXT_WEEK', 'NEXT_MONTH') --与G21同取总账与明细有差值的利息，补进去
             AND MINUS_AMT <> 0
             AND T.ORG_NUM <> '009804' --ADD BY CHM 20231012
           GROUP BY I_DATADATE, ORG_NUM, T.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;

---add by chm 20231012 正回购应付利息（债券+票据）

    INSERT 
    INTO `G22R_2.5.A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.ORG_NUM = '009804' THEN  -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 原有009804金融市场部只有2111卖出回购本金对应的应付利息
                'G22R_2.5.A'
               ELSE
                'G22R_2.5.B'  -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务2003拆入资金、2111卖出回购本金对应的应付利息
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL a
       WHERE DATA_DATE = I_DATADATE
         AND FLAG IN ('05', '07')
         AND A.ORG_NUM IN ('009804', '009801')
         AND A.MATUR_DATE - I_DATADATE <= 30
         AND A.MATUR_DATE - I_DATADATE >= 1
       GROUP BY A.ORG_NUM;

INSERT 
INTO `G22R_2.5.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.5.A',
         SUM(CASE
               WHEN CURR_CD = 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
             WHEN A.ORG_NUM LIKE '%98%' THEN
              A.ORG_NUM
             WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
              '060300'
             ELSE
              SUBSTR(A.ORG_NUM, 1, 4) || '00'
           END AS ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(NVL(INTEREST_ACCURED, 0) + NVL(INTEREST_ACCURAL, 0)) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
                -- AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
             AND (A.MATUR_DATE_ACCURED IS NULL OR
                 A.MATUR_DATE_ACCURED - I_DATADATE <= 30)
             AND A.ORG_NUM <> '009804' --ADD BY CHM 20231012
           GROUP BY A.DATA_DATE,
                    CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                      WHEN A.ORG_NUM LIKE '%98%' THEN
                       A.ORG_NUM
                      WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                       '060300'
                      ELSE
                       SUBSTR(A.ORG_NUM, 1, 4) || '00'
                    END,
                    A.ACCT_CUR
          UNION ALL
          SELECT 
           I_DATADATE, ORG_NUM, T.CURR_CD, SUM(MINUS_AMT) AS MINUS_AMT
            FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP T
           WHERE ITEM_CD LIKE '2231%'
             AND QX IN ('NEXT_YS', 'NEXT_WEEK', 'NEXT_MONTH') --与G21同取总账与明细有差值的利息，补进去
             AND MINUS_AMT <> 0
             AND T.ORG_NUM <> '009804' --ADD BY CHM 20231012
           GROUP BY I_DATADATE, ORG_NUM, T.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;

---add by chm 20231012 正回购应付利息（债券+票据）

    INSERT 
    INTO `G22R_2.5.A` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.ORG_NUM = '009804' THEN  -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 原有009804金融市场部只有2111卖出回购本金对应的应付利息
                'G22R_2.5.A'
               ELSE
                'G22R_2.5.B'  -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务2003拆入资金、2111卖出回购本金对应的应付利息
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL a
       WHERE DATA_DATE = I_DATADATE
         AND FLAG IN ('05', '07')
         AND A.ORG_NUM IN ('009804', '009801')
         AND A.MATUR_DATE - I_DATADATE <= 30
         AND A.MATUR_DATE - I_DATADATE >= 1
       GROUP BY A.ORG_NUM;


-- 指标: G22R_1.3.A
--====================================================
    --G22 1.3超额准备金存款   11002存放中央银行超额备付金存款  11002的外币折人民币有也不放在这，因为放商业银行了
--====================================================
INSERT 
INTO `G22R_1.3.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_1.3.A',
         SUM(CASE
               WHEN CURR_CD = 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           A.ORG_NUM,
           A.CURR_CD,
           sum(A.DEBIT_BAL * B.CCY_RATE) CUR_BAL
            FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
              ON A.DATA_DATE = B.DATA_DATE
             AND A.CURR_CD = B.BASIC_CCY
             AND B.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
             AND A.ITEM_CD = '10030201' --库存现金
             AND A.DEBIT_BAL <> 0
             AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
             AND A.ORG_NUM NOT LIKE '%0000' --去掉分行，汇总时不需要
             AND A.ORG_NUM NOT IN (/*'510000',*/ --磐石吉银村镇银行
                                   '222222', --东盛除双阳汇总
                                   '333333', --新双阳
                                   '444444', --净月潭除双阳
                                   '555555') --长春分行（除双阳、榆树、农安）
           GROUP BY A.DATA_DATE, A.ORG_NUM, A.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;

--====================================================
    --G22 1.3超额准备金存款   11002存放中央银行超额备付金存款  11002的外币折人民币有也不放在这，因为放商业银行了
--====================================================
INSERT 
INTO `G22R_1.3.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_1.3.A',
         SUM(CASE
               WHEN CURR_CD = 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           A.ORG_NUM,
           A.CURR_CD,
           sum(A.DEBIT_BAL * B.CCY_RATE) CUR_BAL
            FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
              ON A.DATA_DATE = B.DATA_DATE
             AND A.CURR_CD = B.BASIC_CCY
             AND B.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
             AND A.ITEM_CD = '10030201' --库存现金
             AND A.DEBIT_BAL <> 0
             AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
             AND A.ORG_NUM NOT LIKE '%0000' --去掉分行，汇总时不需要
             AND A.ORG_NUM NOT IN (/*'510000',*/ --磐石吉银村镇银行
                                   '222222', --东盛除双阳汇总
                                   '333333', --新双阳
                                   '444444', --净月潭除双阳
                                   '555555') --长春分行（除双阳、榆树、农安）
           GROUP BY A.DATA_DATE, A.ORG_NUM, A.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;


-- 指标: G22R_1.6.A
INSERT INTO `G22R_1.6.A`
      SELECT I_DATADATE, ORGNO, 'G22R_1.6.A', NVL(sum(YE), 0)
        FROM PM_RSDATA.CBRC_ID_G22_ITEMDATA_NGI T
       WHERE ITEMINDIC = 'G22_1.6_CNY'
         AND RQ = I_DATADATE
       GROUP BY ORGNO;

--modiy by djh 20241210 信用卡规则修改信用卡正常部分+逾期30天
    --[1.6 一个月内到期的合格贷款]，A列取值：逾期M0+M1数据值汇总
    INSERT INTO `G22R_1.6.A`
      SELECT I_DATADATE, A.ORG_NUM, 'G22R_1.6.A', sum(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A --信用卡正常部分
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD='1.6.A'
       GROUP BY I_DATADATE, A.ORG_NUM, ITEM_CD
      UNION ALL
      SELECT I_DATADATE,
             '009803',
             'G22R_1.6.A',
             SUM(NVL(M0, 0) + NVL(T.M1, 0) + NVL(T.M2, 0) + NVL(T.M3, 0) + NVL(T.M4, 0) +
                 NVL(T.M5, 0) + NVL(T.M6, 0) + NVL(T.M6_UP, 0))
        FROM PM_RSDATA.SMTMODS_L_ACCT_CARD_CREDIT T
       WHERE T.DATA_DATE = I_DATADATE
         AND LXQKQS <=1;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
            INSERT 
            INTO `G22R_1.6.A` 
              (DATA_DATE,
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
               COL_8)
              SELECT
               T1.DATA_DATE,
               T1.ORG_NUM,
               T1.DATA_DEPARTMENT,
               'CBRC' AS SYS_NAM,
               'G22R' REP_NUM,
               CASE
                 WHEN T1.CURR_CD = 'CNY' THEN
                  'G22R_1.6.A'
                 ELSE
                  'G22R_1.6.B'
               END AS ITEM_NUM,
               T1.NEXT_PAYMENT * T2.CCY_RATE AS TOTAL_VALUE,
               T1.LOAN_NUM AS COL1, --贷款编号
               T1.CURR_CD AS COL2, --币种
               T1.ITEM_CD AS COL3, --科目
               TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
               TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --（到期日）还款计划本金到期日/没有还款计划按照贷款实际到期日
               T1.ACCT_NUM AS COL6, --贷款合同编号
               T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
               CASE
                 WHEN T1.LOAN_GRADE_CD = '1' THEN
                  '正常'
                 WHEN T1.LOAN_GRADE_CD = '2' THEN
                  '关注'
                 WHEN T1.LOAN_GRADE_CD = '3' THEN
                  '次级'
                 WHEN T1.LOAN_GRADE_CD = '4' THEN
                  '可疑'
                 WHEN T1.LOAN_GRADE_CD = '5' THEN
                  '损失'
               END AS COL8 --五级分类
                FROM CBRC_FDM_LNAC_PMT_G22 T1
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = T1.CURR_CD
                 AND T2.FORWARD_CCY = 'CNY'
                 AND T1.NEXT_PAYMENT <> 0
                 AND T1.PMT_REMAIN_TERM_C <= 30
                 AND T1.PMT_REMAIN_TERM_C >= 1;

--ADD BY DJH 与G21相同，20220518如果逾期天数是空值或者0，但是实际到期日小于等于当前日期数据，放在次日
            INSERT 
            INTO `G22R_1.6.A` 
              (DATA_DATE,
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
               COL_8)
              SELECT T1.DATA_DATE,
                     T1.ORG_NUM,
                     T1.DATA_DEPARTMENT,
                     'CBRC' AS SYS_NAM,
                     'G22R' REP_NUM,
                     CASE
                       WHEN T1.CURR_CD = 'CNY' THEN
                        'G22R_1.6.A'
                       ELSE
                        'G22R_1.6.B'
                     END AS ITEM_NUM,
                     T1.LOAN_ACCT_BAL * T2.CCY_RATE AS TOTAL_VALUE,
                     T1.LOAN_NUM AS COL1, --贷款编号
                     T1.CURR_CD AS COL2, --币种
                     T1.ITEM_CD AS COL3, --科目
                     TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                     TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --（到期日）还款计划本金到期日/没有还款计划按照贷款实际到期日
                     T1.ACCT_NUM AS COL6, --贷款合同编号
                     T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
                     CASE
                       WHEN T1.LOAN_GRADE_CD = '1' THEN
                        '正常'
                       WHEN T1.LOAN_GRADE_CD = '2' THEN
                        '关注'
                       WHEN T1.LOAN_GRADE_CD = '3' THEN
                        '次级'
                       WHEN T1.LOAN_GRADE_CD = '4' THEN
                        '可疑'
                       WHEN T1.LOAN_GRADE_CD = '5' THEN
                        '损失'
                     END AS COL8 --五级分类
                FROM PM_RSDATA.CBRC_FDM_LNAC_PMT T1
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = T1.CURR_CD --基准币种
                 AND T2.FORWARD_CCY = 'CNY'
               WHERE T1.DATA_DATE = I_DATADATE
                 AND (T1.ACCT_STATUS_1104 = '10' AND
                     T1.PMT_REMAIN_TERM_C <= 0)
                 AND T1.LOAN_ACCT_BAL <> 0;

INSERT 
            INTO `G22R_1.6.A` 
              (DATA_DATE,
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
               COL_10,
               COL_11)
              SELECT T1.DATA_DATE,
                     T1.ORG_NUM,
                     T1.DATA_DEPARTMENT,
                     'CBRC' AS SYS_NAM,
                     'G22R' REP_NUM,
                     CASE
                       WHEN T1.CURR_CD = 'CNY' THEN
                        'G22R_1.6.A'
                       ELSE
                        'G22R_1.6.B'
                     END AS ITEM_NUM,
                     CASE
                       WHEN T1.OD_LOAN_ACCT_BAL > T1.LOAN_ACCT_BAL THEN --对于逾期金额大于本金余额的直接取本金余额
                        T1.LOAN_ACCT_BAL
                       ELSE
                        T1.OD_LOAN_ACCT_BAL
                     END * T2.CCY_RATE AS TOTAL_VALUE,
                     T1.LOAN_NUM AS COL1, --贷款编号
                     T1.CURR_CD AS COL2, --币种
                     T1.ITEM_CD AS COL3, --科目
                     TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                     '' AS COL5, --本金逾期日期
                     T1.ACCT_NUM AS COL6, --贷款合同编号
                     '' AS COL7, --剩余期限（天数）
                     CASE
                       WHEN T1.LOAN_GRADE_CD = '1' THEN
                        '正常'
                       WHEN T1.LOAN_GRADE_CD = '2' THEN
                        '关注'
                       WHEN T1.LOAN_GRADE_CD = '3' THEN
                        '次级'
                       WHEN T1.LOAN_GRADE_CD = '4' THEN
                        '可疑'
                       WHEN T1.LOAN_GRADE_CD = '5' THEN
                        '损失'
                     END AS COL8, --五级分类
                     TO_CHAR(T1.P_OD_DT, 'YYYY-MM-DD') AS COL9, --本金逾期日期
                     TO_CHAR(T1.I_OD_DT, 'YYYY-MM-DD') AS COL10, --利息逾期日期
                     P_OD_DT - I_DATADATE AS COL11 --逾期天数
                FROM PM_RSDATA.CBRC_FDM_LNAC T1
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = T1.CURR_CD --基准币种
                 AND T2.FORWARD_CCY = 'CNY'
               WHERE T1.DATA_DATE = I_DATADATE
                 AND ABS(P_OD_DT - I_DATADATE) <= 30 --除129贴现以外用本金到期日判定
                 AND T1.ITEM_CD NOT LIKE '1301%'
                 AND P_OD_DT IS NOT NULL
                 AND ((T1.OD_LOAN_ACCT_BAL > T1.LOAN_ACCT_BAL AND
                     T1.OD_LOAN_ACCT_BAL IS NOT NULL) OR
                     T1.OD_LOAN_ACCT_BAL > 0);

INSERT 
            INTO `G22R_1.6.A` 
              (DATA_DATE,
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
               COL_10,
               COL_11)
              SELECT 
               T1.DATA_DATE,
               T1.ORG_NUM,
               T1.DATA_DEPARTMENT,
               'CBRC' AS SYS_NAM,
               'G22R' REP_NUM,
               CASE
                 WHEN T1.CURR_CD = 'CNY' THEN
                  'G22R_1.6.A'
                 ELSE
                  'G22R_1.6.B'
               END AS ITEM_NUM,
               T1.LOAN_ACCT_BAL * T2.CCY_RATE AS TOTAL_VALUE, --129贴现，用逾期天数判定，贴现逾期直接取逾期本金
               T1.LOAN_NUM AS COL1, --贷款编号
               T1.CURR_CD AS COL2, --币种
               T1.ITEM_CD AS COL3, --科目
               TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
               '' AS COL5, --本金逾期日期
               T1.ACCT_NUM AS COL6, --贷款合同编号
               '' AS COL7, --剩余期限（天数）
               CASE
                 WHEN T1.LOAN_GRADE_CD = '1' THEN
                  '正常'
                 WHEN T1.LOAN_GRADE_CD = '2' THEN
                  '关注'
                 WHEN T1.LOAN_GRADE_CD = '3' THEN
                  '次级'
                 WHEN T1.LOAN_GRADE_CD = '4' THEN
                  '可疑'
                 WHEN T1.LOAN_GRADE_CD = '5' THEN
                  '损失'
               END AS COL8, --五级分类
               TO_CHAR(T1.P_OD_DT, 'YYYY-MM-DD') AS COL9, --本金逾期日期
               TO_CHAR(T1.I_OD_DT, 'YYYY-MM-DD') AS COL10, --利息逾期日期
               T1.OD_DAYS AS COL11 --逾期天数
                FROM PM_RSDATA.CBRC_FDM_LNAC T1
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = T1.CURR_CD --基准币种
                 AND T2.FORWARD_CCY = 'CNY'
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.OD_DAYS > 0
                 AND T1.OD_DAYS <= 30
                 AND T1.ITEM_CD LIKE '1301%'
                 AND T1.LOAN_ACCT_BAL <> 0;

--modiy by djh 20241210 信用卡规则修改信用卡正常部分+逾期30天
    --[1.6 一个月内到期的合格贷款]，A列取值：逾期M0+M1数据值汇总
    INSERT INTO `G22R_1.6.A`
      SELECT I_DATADATE, A.ORG_NUM, 'G22R_1.6.A', sum(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A --信用卡正常部分
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD='1.6.A'
       GROUP BY I_DATADATE, A.ORG_NUM, ITEM_CD
      UNION ALL
      SELECT I_DATADATE,
             '009803',
             'G22R_1.6.A',
             SUM(NVL(M0, 0) + NVL(T.M1, 0) + NVL(T.M2, 0) + NVL(T.M3, 0) + NVL(T.M4, 0) +
                 NVL(T.M5, 0) + NVL(T.M6, 0) + NVL(T.M6_UP, 0))
        FROM PM_RSDATA.SMTMODS_L_ACCT_CARD_CREDIT T
       WHERE T.DATA_DATE = I_DATADATE
         AND LXQKQS <=1;


-- 指标: G22R_1.7.A
--===========================================================
    --G22   1.7一个月内到期的债券投资 add by chm 20231012
--===========================================================

  INSERT 
  INTO `G22R_1.7.A` 
    (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
           A.ORG_NUM,
           'G22R_1.7.A',
           SUM(A.PRINCIPAL_BALANCE_CNY)
      FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.INVEST_TYP = '00' --债券
       AND A.DC_DATE <= 30
       AND A.DC_DATE >= 1
     GROUP BY A.ORG_NUM;

--===========================================================
    --G22   1.7一个月内到期的债券投资 add by chm 20231012
--===========================================================

  INSERT 
  INTO `G22R_1.7.A` 
    (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
           A.ORG_NUM,
           'G22R_1.7.A',
           SUM(A.PRINCIPAL_BALANCE_CNY)
      FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
     WHERE A.DATA_DATE = I_DATADATE
       AND A.INVEST_TYP = '00' --债券
       AND A.DC_DATE <= 30
       AND A.DC_DATE >= 1
     GROUP BY A.ORG_NUM;


-- 指标: G22R_2.3.B
INSERT 
INTO `G22R_2.3.B` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE,
         B.ORG_NUM,
         'G22R_2.3.B',
         B.ACCT_BAL_RMB AS CUR_CNY_BAL
    FROM (SELECT ORG_NUM, SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
                 FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL
                WHERE DATA_DATE = I_DATADATE
                  AND ACCT_CUR <> 'CNY'    --[2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务2003拆入资金、2111卖出回购本金进此项
                  AND FLAG IN ('03', '04', '05', '07')   
                  AND GL_ITEM_CODE <> '20120204' --保险业金融机构存放款项放到3.5.1定期存款
                  AND GL_ITEM_CODE <> '20120106' --保险业金融机构存放款项放到3.5.2活期存款
                  AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
                GROUP BY ORG_NUM) B;

INSERT 
INTO `G22R_2.3.B` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE,
         B.ORG_NUM,
         'G22R_2.3.B',
         B.ACCT_BAL_RMB AS CUR_CNY_BAL
    FROM (SELECT ORG_NUM, SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
                 FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL
                WHERE DATA_DATE = I_DATADATE
                  AND ACCT_CUR <> 'CNY'    --[2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务2003拆入资金、2111卖出回购本金进此项
                  AND FLAG IN ('03', '04', '05', '07')   
                  AND GL_ITEM_CODE <> '20120204' --保险业金融机构存放款项放到3.5.1定期存款
                  AND GL_ITEM_CODE <> '20120106' --保险业金融机构存放款项放到3.5.2活期存款
                  AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
                GROUP BY ORG_NUM) B;


-- 指标: G22R_1.4.B
INSERT 
INTO `G22R_1.4.B` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE,
         A.ORG_NUM,
         'G22R_1.4.B',
         ACCT_BAL_RMB AS ITEM_VAL
    FROM (SELECT ORG_NUM, SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL
           WHERE DATA_DATE = I_DATADATE
             AND ACCT_CUR <> 'CNY'  --[2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆放同业、1111买入返售资产本金进此项
             AND FLAG IN ('01', '02', '03')
             AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
           GROUP BY ORG_NUM) A;

INSERT 
INTO `G22R_1.4.B` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE,
         A.ORG_NUM,
         'G22R_1.4.B',
         ACCT_BAL_RMB AS ITEM_VAL
    FROM (SELECT ORG_NUM, SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL
           WHERE DATA_DATE = I_DATADATE
             AND ACCT_CUR <> 'CNY'  --[2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆放同业、1111买入返售资产本金进此项
             AND FLAG IN ('01', '02', '03')
             AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
           GROUP BY ORG_NUM) A;


-- 指标: G22R_1.5.A
---add by chm 20231012

   --1.5一个月内到期的应收利息及其他应收款

   INSERT 
   INTO `G22R_1.5.A` 
     (RQ, ORGNO, ITEMINDIC, ITEM, YE)
     SELECT I_DATADATE, /*'009804',*/
            ORG_NUM,
            CASE
              WHEN T.ACCT_CUR = 'CNY' THEN
               'G22_1.5_CNY'
              WHEN T.ACCT_CUR <> 'CNY' THEN  -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1111买入返售本金以及应收利息
               'G22_1.5_ZCNY'
            END,
            '',
            SUM(ACCRUAL)
       FROM (
             --买入返售应收利息
             SELECT /*'009804',*/
              ORG_NUM,
               ACCT_CUR,
               'G22R_1.5.A' AS ITEM_NUM,
               SUM(A.INTEREST_ACCURAL) AS ACCRUAL
               FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
              WHERE DATA_DATE = I_DATADATE
                AND FLAG = '03'
                AND A.MATUR_DATE - I_DATADATE <= 30
                AND A.MATUR_DATE - I_DATADATE >= 1
              GROUP BY ORG_NUM, ACCT_CUR
             UNION ALL
             --债券应收利息
             SELECT A.ORG_NUM,
                     CURR_CD,
                     'G22R_1.5.A' AS ITEM_NUM,
                     SUM(A.ACCRUAL_CNY) AS ACCRUAL --应收利息
               FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
              WHERE A.DATA_DATE = I_DATADATE
                AND A.INVEST_TYP = '00' --债券
                AND A.DC_DATE <= 30
                AND A.DC_DATE >= 1
              GROUP BY A.ORG_NUM, CURR_CD
             UNION ALL
             --同业存单应收利息
             SELECT ORG_NUM,
                     ACCT_CUR,
                     'G22R_1.5.A' AS ITEM_NUM,
                     SUM(A.INTEREST_ACCURAL) AS ACCRUAL
               FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
              WHERE DATA_DATE = I_DATADATE
                AND FLAG = '04'
                   -- AND A.ORG_NUM = '009804' --ADD BY DJH 20240510  同业金融部 和金融市场一样，统一规则
                AND A.DC_DATE <= 30
                AND A.DC_DATE >= 1
             /*  AND A.MATUR_DATE - TO_DATE(I_DATADATE, 'YYYYMMDD') <= 30
             AND A.MATUR_DATE - TO_DATE(I_DATADATE, 'YYYYMMDD') >= 1*/
              GROUP BY ORG_NUM, ACCT_CUR) T
      GROUP BY ORG_NUM,
               CASE
                 WHEN T.ACCT_CUR = 'CNY' THEN
                  'G22_1.5_CNY'
                 WHEN T.ACCT_CUR <> 'CNY' THEN
                  'G22_1.5_ZCNY'
               END;

INSERT INTO `G22R_1.5.A`
    SELECT I_DATADATE, ORGNO, 'G22R_1.5.A', NVL(SUM(YE), 0)
      FROM PM_RSDATA.CBRC_ID_G22_ITEMDATA_NGI
     WHERE ITEMINDIC = 'G22_1.5_CNY'
       AND RQ = I_DATADATE
     GROUP BY ORGNO
    UNION ALL --信用卡利息人民币    信用卡全部为应收逾期利息，因此直接取和G21一样
    SELECT I_DATADATE, '009803', 'G22R_1.5.A', sum(T1.DEBIT_BAL)
      FROM PM_RSDATA.CBRC_FDM_LNAC_GL T1
     WHERE T1.DATA_DATE = I_DATADATE
       AND T1.CURR_CD = 'CNY'
       AND T1.GL_ACCOUNT = '113201'
       AND T1.ORG_NUM = '009803';

--====================================================
    --G22 1.5一个月内到期的应收利息及其他应收款  增加资管009816 取剩余期限30天（含）内中收计提表【本期累计计提中收】 ADD BY DJH 20241205数仓逻辑变更自动取数
    --====================================================
 --人民币
      INSERT INTO `G22R_1.5.A`
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.A',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
           AND FLAG = '1'
           AND REDEMP_DATE IS NULL
            OR (REDEMP_DATE - I_DATADATE >= 1 AND
               REDEMP_DATE - I_DATADATE <= 30)
           AND A.CURR_CD = 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.A',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
           AND FLAG = '1'
           AND COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL
            OR (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE >= 1 AND
               COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE <= 30)
           AND A.CURR_CD = 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
       SELECT I_DATADATE,
              A.ORG_NUM,
              'G22R_1.5.A' AS ITEM_NUM,
              SUM(A.DEBIT_BAL)
         FROM PM_RSDATA.CBRC_FDM_LNAC_GL A   --G21取总账数据表
        WHERE A.DATA_DATE = I_DATADATE
          AND ITEM_CD = 'G21_1.8.A'
          AND A.CURR_CD = 'CNY'
        GROUP BY I_DATADATE, A.ORG_NUM;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
              INSERT 
          INTO `G22R_1.5.A` 
            (DATA_DATE,
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
             COL_8)
            SELECT
             T1.DATA_DATE,
             CASE
               WHEN T1.ORG_NUM LIKE '5%' OR T1.ORG_NUM LIKE '6%' THEN
                T1.ORG_NUM
               WHEN T1.ORG_NUM LIKE '%98%' THEN
                T1.ORG_NUM
               WHEN t1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T1.ORG_NUM, 1, 4) || '00'
             END as ORGNO,
             T1.DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             'G22R' REP_NUM,
             CASE
               WHEN T1.CURR_CD = 'CNY' THEN
                'G22R_1.5.A'
               ELSE
                'G22R_1.5.B'
             END AS ITEM_NUM,
             NVL(T1.ACCU_INT_AMT, 0) * T2.CCY_RATE AS TOTAL_VALUE, --正常贷款贷款表应计利息
             T1.LOAN_NUM AS COL1, --贷款编号
             T1.CURR_CD AS COL2, --币种
             CASE
               WHEN T1.ITEM_CD IN ('13030101', '13030103') THEN
                '11320102'
               WHEN T1.ITEM_CD IN ('13030201', '13030203') THEN
                '11320104'
               WHEN T1.ITEM_CD IN ('13050101', '13050103') THEN
                '11320106'
               WHEN T1.ITEM_CD IN ('13060101', '13060103') THEN
                '11320108'
               WHEN T1.ITEM_CD IN ('13060201', '13060203') THEN
                '11320110'
               WHEN T1.ITEM_CD IN ('13060301', '13060303') THEN
                '11320112'
               WHEN T1.ITEM_CD IN ('13060501', '13060503') THEN
                '11320116'
               ELSE
                T1.ITEM_CD
             END AS COL3, --本金对应应计利息科目
             TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
             TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
             T1.ACCT_NUM AS COL6, --贷款合同编号
             T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
             CASE
               WHEN T1.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN T1.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN T1.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN T1.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN T1.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL8 --五级分类
              FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
              LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                ON T2.DATA_DATE = I_DATADATE
               AND T2.BASIC_CCY = T1.CURR_CD --基准币种
               AND T2.FORWARD_CCY = 'CNY'
             WHERE T1.DATA_DATE = I_DATADATE
               AND T1.PMT_REMAIN_TERM_C <= 30
               AND T1.PMT_REMAIN_TERM_C >= 1
               AND T1.IDENTITY_CODE = '3'
               AND T1.ACCU_INT_AMT <> 0;

INSERT 
          INTO `G22R_1.5.A` 
            (DATA_DATE,
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
             COL_8)
            SELECT 
             T1.DATA_DATE,
             CASE
               WHEN T1.ORG_NUM LIKE '5%' OR T1.ORG_NUM LIKE '6%' THEN
                T1.ORG_NUM
               WHEN T1.ORG_NUM LIKE '%98%' THEN
                T1.ORG_NUM
               WHEN t1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(T1.ORG_NUM, 1, 4) || '00'
             END as ORGNO,
             T1.DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             'G22R' REP_NUM,
             CASE
               WHEN T1.CURR_CD = 'CNY' THEN
                'G22R_1.5.A'
               ELSE
                'G22R_1.5.B'
             END AS ITEM_NUM,
             NVL(T1.OD_INT, 0) * T2.CCY_RATE AS TOTAL_VALUE, --正常贷款贷款表应计利息
             T1.LOAN_NUM AS COL1, --贷款编号
             T1.CURR_CD AS COL2, --币种
             CASE
               WHEN T1.ITEM_CD IN ('13030101', '13030103') THEN
                '11320102'
               WHEN T1.ITEM_CD IN ('13030201', '13030203') THEN
                '11320104'
               WHEN T1.ITEM_CD IN ('13050101', '13050103') THEN
                '11320106'
               WHEN T1.ITEM_CD IN ('13060101', '13060103') THEN
                '11320108'
               WHEN T1.ITEM_CD IN ('13060201', '13060203') THEN
                '11320110'
               WHEN T1.ITEM_CD IN ('13060301', '13060303') THEN
                '11320112'
               WHEN T1.ITEM_CD IN ('13060501', '13060503') THEN
                '11320116'
               ELSE
                T1.ITEM_CD
             END AS COL3, --本金对应应计利息科目
             TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
             TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --（到期日）还款计划利息到期日/没有还款计划的利息取下月21号 D_DATADATE_CCY + 21
             T1.ACCT_NUM AS COL6, --贷款合同编号
             T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
             CASE
               WHEN T1.LOAN_GRADE_CD = '1' THEN
                '正常'
               WHEN T1.LOAN_GRADE_CD = '2' THEN
                '关注'
               WHEN T1.LOAN_GRADE_CD = '3' THEN
                '次级'
               WHEN T1.LOAN_GRADE_CD = '4' THEN
                '可疑'
               WHEN T1.LOAN_GRADE_CD = '5' THEN
                '损失'
             END AS COL8 --五级分类
              FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
              LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                ON T2.DATA_DATE = I_DATADATE
               AND T2.BASIC_CCY = T1.CURR_CD --基准币种
               AND T2.FORWARD_CCY = 'CNY'
             WHERE T1.DATA_DATE = I_DATADATE
               AND T1.PMT_REMAIN_TERM_C <= 30
               AND T1.PMT_REMAIN_TERM_C >= 1
               AND T1.IDENTITY_CODE = '4'
               AND T1.OD_INT <> 0;

--补充1132应收利息轧差，条线为空值
          INSERT  INTO `G22R_1.5.A` 
            (DATA_DATE,
             ORG_NUM,
             DATA_DEPARTMENT,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             TOTAL_VALUE)
            SELECT 
             I_DATADATE,
             B.ORG_NUM,
             '' AS DATA_DEPARTMENT,
             'CBRC' AS SYS_NAM,
             'G22R' REP_NUM,
             CASE
               WHEN B.CURR_CD = 'CNY' THEN
                'G22R_1.5.A'
               ELSE
                'G22R_1.5.B'
             END ITEM_NUM,
             SUM(MINUS_AMT) AS TOTAL_VALUE
              FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP B
             WHERE MINUS_AMT <> 0
               AND ITEM_CD = '113201'
               AND QX IN ('NEXT_YS', 'NEXT_WEEK', 'NEXT_MONTH') --与G21同取总账与明细有差值的利息，补进去
             GROUP BY B.ORG_NUM,B.CURR_CD;

---add by chm 20231012

   --1.5一个月内到期的应收利息及其他应收款

   INSERT
   INTO `G22R_1.5.A` 
     (RQ, ORGNO, ITEMINDIC, ITEM, YE)
     SELECT I_DATADATE, /*'009804',*/
            ORG_NUM,
            CASE
              WHEN T.ACCT_CUR = 'CNY' THEN
               'G22_1.5_CNY'
              WHEN T.ACCT_CUR <> 'CNY' THEN  -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1111买入返售本金以及应收利息
               'G22_1.5_ZCNY'
            END,
            '',
            SUM(ACCRUAL)
       FROM (
             --买入返售应收利息
             SELECT /*'009804',*/
              ORG_NUM,
               ACCT_CUR,
               'G22R_1.5.A' AS ITEM_NUM,
               SUM(A.INTEREST_ACCURAL) AS ACCRUAL
               FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
              WHERE DATA_DATE = I_DATADATE
                AND FLAG = '03'
                AND A.MATUR_DATE - I_DATADATE <= 30
                AND A.MATUR_DATE - I_DATADATE >= 1
              GROUP BY ORG_NUM, ACCT_CUR
             UNION ALL
             --债券应收利息
             SELECT A.ORG_NUM,
                     CURR_CD,
                     'G22R_1.5.A' AS ITEM_NUM,
                     SUM(A.ACCRUAL_CNY) AS ACCRUAL --应收利息
               FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
              WHERE A.DATA_DATE = I_DATADATE
                AND A.INVEST_TYP = '00' --债券
                AND A.DC_DATE <= 30
                AND A.DC_DATE >= 1
              GROUP BY A.ORG_NUM, CURR_CD
             UNION ALL
             --同业存单应收利息
             SELECT ORG_NUM,
                     ACCT_CUR,
                     'G22R_1.5.A' AS ITEM_NUM,
                     SUM(A.INTEREST_ACCURAL) AS ACCRUAL
               FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
              WHERE DATA_DATE = I_DATADATE
                AND FLAG = '04'
                   -- AND A.ORG_NUM = '009804' --ADD BY DJH 20240510  同业金融部 和金融市场一样，统一规则
                AND A.DC_DATE <= 30
                AND A.DC_DATE >= 1
             /*  AND A.MATUR_DATE - TO_DATE(I_DATADATE, 'YYYYMMDD') <= 30
             AND A.MATUR_DATE - TO_DATE(I_DATADATE, 'YYYYMMDD') >= 1*/
              GROUP BY ORG_NUM, ACCT_CUR) T
      GROUP BY ORG_NUM,
               CASE
                 WHEN T.ACCT_CUR = 'CNY' THEN
                  'G22_1.5_CNY'
                 WHEN T.ACCT_CUR <> 'CNY' THEN
                  'G22_1.5_ZCNY'
               END;

INSERT INTO `G22R_1.5.A`
    SELECT I_DATADATE, ORGNO, 'G22R_1.5.A', NVL(SUM(YE), 0)
      FROM CBRC_ID_G22_ITEMDATA_NGI
     WHERE ITEMINDIC = 'G22_1.5_CNY'
       AND RQ = I_DATADATE
     GROUP BY ORGNO
    UNION ALL --信用卡利息人民币    信用卡全部为应收逾期利息，因此直接取和G21一样
    SELECT I_DATADATE, '009803', 'G22R_1.5.A', sum(T1.DEBIT_BAL)
      FROM PM_RSDATA.CBRC_FDM_LNAC_GL T1
     WHERE T1.DATA_DATE = I_DATADATE
       AND T1.CURR_CD = 'CNY'
       AND T1.GL_ACCOUNT = '113201'
       AND T1.ORG_NUM = '009803';

--====================================================
    --G22 1.5一个月内到期的应收利息及其他应收款  增加资管009816 取剩余期限30天（含）内中收计提表【本期累计计提中收】 ADD BY DJH 20241205数仓逻辑变更自动取数
    --====================================================
 --人民币
      INSERT INTO `G22R_1.5.A`
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.A',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
           AND FLAG = '1'
           AND REDEMP_DATE IS NULL
            OR (REDEMP_DATE - I_DATADATE >= 1 AND
               REDEMP_DATE - I_DATADATE <= 30)
           AND A.CURR_CD = 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.A',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
           AND FLAG = '1'
           AND COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL
            OR (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE >= 1 AND
               COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE <= 30)
           AND A.CURR_CD = 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
       SELECT I_DATADATE,
              A.ORG_NUM,
              'G22R_1.5.A' AS ITEM_NUM,
              SUM(A.DEBIT_BAL)
         FROM PM_RSDATA.CBRC_FDM_LNAC_GL A   --G21取总账数据表
        WHERE A.DATA_DATE = I_DATADATE
          AND ITEM_CD = 'G21_1.8.A'
          AND A.CURR_CD = 'CNY'
        GROUP BY I_DATADATE, A.ORG_NUM;

----ADD BY DJH 20241205,数仓逻辑变更自动取数  2.2.2.6.3其他借款和现金流入  取值中收计提表中剩余期限一个月数据【本期累计计提中收】 ,同G22
 INSERT 
 INTO `G22R_1.5.A` 
   (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
   SELECT I_DATADATE AS DATA_DATE,
          B.ORG_NUM,
          'G25_1_1.2.2.2.6.3.A.2014' ITEM_NUM, --折算前
          SUM(B.ITEM_VAL) --期末产品余额折人民币
     FROM CBRC_g22_data_collect_tmp_ngi B
    WHERE B.ITEM_NUM IN ('G22R_1.5.A',
                         'G22R_1.5.B')
    AND ORG_NUM NOT IN('009804','009820') --ADD BY CHM 金融市场部 G2501 G25_1_1.2.2.2.6.3.A.2014 同G22 G22R_1.5.A口径不一致  --ADD BY DJH 20240510 同业金融部 同G22 G22R_1.5.A口径不一致
    GROUP BY B.ORG_NUM;

----ADD BY DJH 20241205，数仓逻辑变更自动取数  2.2.2.6.3其他借款和现金流入  取值中收计提表中剩余期限一个月数据【本期累计计提中收】 ，同G22
 INSERT 
 INTO `G22R_1.5.A` 
   (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
   SELECT I_DATADATE AS DATA_DATE,
          B.ORG_NUM,
          'G25_1_1.2.2.2.6.3.A.2014' ITEM_NUM, --折算前
          SUM(B.ITEM_VAL) --期末产品余额折人民币
     FROM CBRC_g22_data_collect_tmp_ngi B
    WHERE B.ITEM_NUM IN ('G22R_1.5.A',
                         'G22R_1.5.B')
    AND ORG_NUM NOT IN('009804','009820') --ADD BY CHM 金融市场部 G2501 G25_1_1.2.2.2.6.3.A.2014 同G22 G22R_1.5.A口径不一致  --ADD BY DJH 20240510 同业金融部 同G22 G22R_1.5.A口径不一致
    GROUP BY B.ORG_NUM
    union  all 
    SELECT I_DATADATE AS DATA_DATE,
          B.ORG_NUM,
          'G25_1_1.2.2.2.6.3.A.2014' ITEM_NUM, --折算前
          SUM(nvl(B.TOTAL_VALUE,0)) --期末产品余额折人民币
     FROM CBRC_A_REPT_DWD_G22 B
    WHERE B.ITEM_NUM IN ('G22R_1.5.A',
                         'G22R_1.5.B')
    AND ORG_NUM NOT IN('009804','009820') 
    GROUP BY B.ORG_NUM;


-- 指标: G22R_2.6.A
INSERT 
INTO `G22R_2.6.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT DATA_DATE,
           ORG_NUM,
           'G22R_2.6.A',
           SUM(CASE
                 WHEN CURR_CD = 'CNY' THEN
                  CUR_BAL
                 ELSE
                  0
               END) AS CUR_CNY_BAL
      FROM (SELECT
             A.DATA_DATE,
             A.ORG_NUM,
             A.ACCT_CUR AS CURR_CD,
              SUM(ACCT_BAL_RMB)  CUR_BAL
              FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
             WHERE A.DATA_DATE = I_DATADATE
               AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
               AND A.FLAG = '02'
             GROUP BY A.DATA_DATE, A.ORG_NUM, A.ACCT_CUR)
     GROUP BY DATA_DATE, ORG_NUM;

INSERT 
INTO `G22R_2.6.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT DATA_DATE,
           ORG_NUM,
           'G22R_2.6.A',
           SUM(CASE
                 WHEN CURR_CD = 'CNY' THEN
                  CUR_BAL
                 ELSE
                  0
               END) AS CUR_CNY_BAL
      FROM (SELECT
             A.DATA_DATE,
             A.ORG_NUM,
             A.ACCT_CUR AS CURR_CD,
              SUM(ACCT_BAL_RMB)  CUR_BAL
              FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
             WHERE A.DATA_DATE = I_DATADATE
               AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
               AND A.FLAG = '02'
             GROUP BY A.DATA_DATE, A.ORG_NUM, A.ACCT_CUR)
     GROUP BY DATA_DATE, ORG_NUM;


-- 指标: G22R_2.7.A
INSERT 
INTO `G22R_2.7.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.7.A',
         SUM(CASE
               WHEN CURR_CD = 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
             WHEN A.ORG_NUM LIKE '%98%' THEN
              A.ORG_NUM
             WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
              '060300'
             ELSE
              SUBSTR(A.ORG_NUM, 1, 4) || '00'
           END ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(ACCT_BAL_RMB) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
             AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
             --AND A.FLAG = '06'
             AND A.FLAG IN ('06','10') --同业金融部增加转贷款
           GROUP BY A.DATA_DATE,
                    CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                      WHEN A.ORG_NUM LIKE '%98%' THEN
                       A.ORG_NUM
                       WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                       '060300'
                      ELSE
                       SUBSTR(A.ORG_NUM, 1, 4) || '00'
                    END,
                    A.ACCT_CUR
          UNION ALL
          SELECT I_DATADATE, A.ORG_NUM, A.CURR_CD, sum(A.DEBIT_BAL) CUR_BAL
            FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
           WHERE A.DATA_DATE = I_DATADATE
             AND ITEM_CD = '3.8.B'
           GROUP BY I_DATADATE, A.ORG_NUM, A.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;

INSERT 
INTO `G22R_2.7.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.7.A',
         SUM(CASE
               WHEN CURR_CD = 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
             WHEN A.ORG_NUM LIKE '%98%' THEN
              A.ORG_NUM
             WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
              '060300'
             ELSE
              SUBSTR(A.ORG_NUM, 1, 4) || '00'
           END ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(ACCT_BAL_RMB) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
             AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
             --AND A.FLAG = '06'
             AND A.FLAG IN ('06','10') --同业金融部增加转贷款
           GROUP BY A.DATA_DATE,
                    CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                      WHEN A.ORG_NUM LIKE '%98%' THEN
                       A.ORG_NUM
                       WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                       '060300'
                      ELSE
                       SUBSTR(A.ORG_NUM, 1, 4) || '00'
                    END,
                    A.ACCT_CUR
          UNION ALL
          SELECT I_DATADATE, A.ORG_NUM, A.CURR_CD, sum(A.DEBIT_BAL) CUR_BAL
            FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
           WHERE A.DATA_DATE = I_DATADATE
             AND ITEM_CD = '3.8.B'
           GROUP BY I_DATADATE, A.ORG_NUM, A.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;


-- 指标: G22R_2.5.B
INSERT 
INTO `G22R_2.5.B` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.5.B',
         SUM(CASE
               WHEN CURR_CD <> 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
             WHEN A.ORG_NUM LIKE '%98%' THEN
              A.ORG_NUM
             WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
              '060300'
             ELSE
              SUBSTR(A.ORG_NUM, 1, 4) || '00'
           END AS ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(NVL(INTEREST_ACCURED, 0) + NVL(INTEREST_ACCURAL, 0)) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
                -- AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
                -- AND (A.ACCT_TYP <> '9999' or A.ACCT_TYP is null) --虚拟账户应计利息放在3.9没有确定到期日的负债
             AND (A.MATUR_DATE_ACCURED IS NULL OR
                 A.MATUR_DATE_ACCURED - I_DATADATE <= 30)
           GROUP BY A.DATA_DATE,
                    CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                      WHEN A.ORG_NUM LIKE '%98%' THEN
                       A.ORG_NUM
                      WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                       '060300'
                      ELSE
                       SUBSTR(A.ORG_NUM, 1, 4) || '00'
                    END,
                    A.ACCT_CUR
          UNION ALL
          SELECT 
           I_DATADATE, ORG_NUM, T.CURR_CD, SUM(MINUS_AMT) AS MINUS_AMT
            FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP T
           WHERE ITEM_CD LIKE '2231%'
             AND QX IN ('NEXT_YS', 'NEXT_WEEK', 'NEXT_MONTH') --与G21同取总账与明细有差值的利息，补进去
             AND MINUS_AMT <> 0
           GROUP BY I_DATADATE, ORG_NUM, T.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;

---add by chm 20231012 正回购应付利息（债券+票据）

    INSERT 
    INTO `G22R_2.5.B` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.ORG_NUM = '009804' THEN  -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 原有009804金融市场部只有2111卖出回购本金对应的应付利息
                'G22R_2.5.A'
               ELSE
                'G22R_2.5.B'  -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务2003拆入资金、2111卖出回购本金对应的应付利息
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL a
       WHERE DATA_DATE = I_DATADATE
         AND FLAG IN ('05', '07')
         AND A.ORG_NUM IN ('009804', '009801')
         AND A.MATUR_DATE - I_DATADATE <= 30
         AND A.MATUR_DATE - I_DATADATE >= 1
       GROUP BY A.ORG_NUM;

INSERT 
INTO `G22R_2.5.B` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.5.B',
         SUM(CASE
               WHEN CURR_CD <> 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
             WHEN A.ORG_NUM LIKE '%98%' THEN
              A.ORG_NUM
             WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
              '060300'
             ELSE
              SUBSTR(A.ORG_NUM, 1, 4) || '00'
           END AS ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(NVL(INTEREST_ACCURED, 0) + NVL(INTEREST_ACCURAL, 0)) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
                -- AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
                -- AND (A.ACCT_TYP <> '9999' or A.ACCT_TYP is null) --虚拟账户应计利息放在3.9没有确定到期日的负债
             AND (A.MATUR_DATE_ACCURED IS NULL OR
                 A.MATUR_DATE_ACCURED - I_DATADATE <= 30)
           GROUP BY A.DATA_DATE,
                    CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                      WHEN A.ORG_NUM LIKE '%98%' THEN
                       A.ORG_NUM
                      WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                       '060300'
                      ELSE
                       SUBSTR(A.ORG_NUM, 1, 4) || '00'
                    END,
                    A.ACCT_CUR
          UNION ALL
          SELECT 
           I_DATADATE, ORG_NUM, T.CURR_CD, SUM(MINUS_AMT) AS MINUS_AMT
            FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP T
           WHERE ITEM_CD LIKE '2231%'
             AND QX IN ('NEXT_YS', 'NEXT_WEEK', 'NEXT_MONTH') --与G21同取总账与明细有差值的利息，补进去
             AND MINUS_AMT <> 0
           GROUP BY I_DATADATE, ORG_NUM, T.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;

---add by chm 20231012 正回购应付利息（债券+票据）

    INSERT 
    INTO `G22R_2.5.B` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.ORG_NUM = '009804' THEN  -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 原有009804金融市场部只有2111卖出回购本金对应的应付利息
                'G22R_2.5.A'
               ELSE
                'G22R_2.5.B'  -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务2003拆入资金、2111卖出回购本金对应的应付利息
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL a
       WHERE DATA_DATE = I_DATADATE
         AND FLAG IN ('05', '07')
         AND A.ORG_NUM IN ('009804', '009801')
         AND A.MATUR_DATE - I_DATADATE <= 30
         AND A.MATUR_DATE - I_DATADATE >= 1
       GROUP BY A.ORG_NUM;


-- 指标: G22R_1.9.A
--================================================================================================
    --G22   1.9其他一个月内到期可变现的资产（剔除其中的不良资产） add by chm 20231012
--================================================================================================

     INSERT 
     INTO `G22R_1.9.A` 
       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
       SELECT I_DATADATE AS DATA_DATE,
              A.ORG_NUM,
              'G22R_1.9.A',
              SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
         FROM PM_RSDATA.SMTMODS_V_PUB_FUND_CDS_BAL A
         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
           ON TT.CCY_DATE = I_DATADATE
          AND TT.BASIC_CCY = A.CURR_CD
          AND TT.FORWARD_CCY = 'CNY'
        WHERE A.DATA_DATE = I_DATADATE
          AND STOCK_PRO_TYPE = 'A' --同业存单
          AND PRODUCT_PROP = 'A' --持有
          AND A.DC_DATE <= 30
          AND A.DC_DATE >= 1
          --AND A.ORG_NUM = '009804' --吴大为，放开该条件
        GROUP BY A.ORG_NUM;

+委外业务：科目为11010303，取账户类型是FVTPL账户的都取进来，其中中信信托2笔特殊处理按照到期日取1个月内，FVTPL账户取持有仓位+公允；*/
       INSERT 
       INTO `G22R_1.9.A` 
        (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT I_DATADATE,
                ORG_NUM,
                'G22R_1.9.A', --同业金融部确认后没有外币部分
                SUM(ACCT_BAL_RMB)
           FROM (--基金
                 SELECT A.ORG_NUM, SUM(A.ACCT_BAL_RMB) ACCT_BAL_RMB
                   FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
                  WHERE A.DATA_DATE = I_DATADATE
                    AND FLAG = '06' -- 基金所有
                    AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
                 --(ABS((A.MATUR_DATE - TO_DATE('20240331', 'YYYYMMDD')))< =30 OR  A.REDEMPTION_TYPE='随时赎回' ) --随时赎回放到2到7日  --同业金融部确认后逾期不要
                  GROUP BY A.ORG_NUM
                 UNION ALL
                 --委外投资
                 SELECT A.ORG_NUM, SUM(A.ACCT_BAL_RMB) ACCT_BAL_RMB
                   FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
                  WHERE A.DATA_DATE = I_DATADATE
                    AND FLAG = '07' -- 委外投资
                    AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
                    AND A.ACCT_NUM  IN ('N000310000025496', 'N000310000025495')
                  GROUP BY A.ORG_NUM
                 --中信信托2笔特殊处理按照到期日取1个月内
                 UNION ALL
                 SELECT A.ORG_NUM, SUM(A.ACCT_BAL_RMB) ACCT_BAL_RMB
                   FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
                  WHERE A.DATA_DATE = I_DATADATE
                    AND FLAG = '07' -- 委外投资
                    AND A.ACCT_NUM NOT  IN ('N000310000025496', 'N000310000025495')
                  GROUP BY A.ORG_NUM)
          GROUP BY ORG_NUM;

--ADD BY DJH 20240510  投资银行部
   --009817：存量非标业务的一个月内到期的本金+应收利息+其他应收款，剔除不良资产（次级，可疑，损失）后按剩余期限划分取值；
      INSERT 
       INTO `G22R_1.9.A` 
         (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT I_DATADATE,
                ORG_NUM,
                'G22R_1.9.A',
                SUM(ACCT_BAL_RMB)
           FROM (SELECT A.ORG_NUM, SUM(A.ACCT_BAL_RMB) ACCT_BAL_RMB
                   FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
                  WHERE A.DATA_DATE = I_DATADATE
                    AND FLAG = '09'
                    AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
                    AND A.GRADE NOT IN ('3','4','5')
                  GROUP BY A.ORG_NUM)
          GROUP BY ORG_NUM;

--================================================================================================
    --G22   1.9其他一个月内到期可变现的资产（剔除其中的不良资产） add by chm 20231012
--================================================================================================

     INSERT 
     INTO `G22R_1.9.A` 
       (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
       SELECT I_DATADATE AS DATA_DATE,
              A.ORG_NUM,
              'G22R_1.9.A',
              SUM(A.PRINCIPAL_BALANCE * TT.CCY_RATE)
         FROM PM_RSDATA.SMTMODS_V_PUB_FUND_CDS_BAL A
         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
           ON TT.CCY_DATE = I_DATADATE
          AND TT.BASIC_CCY = A.CURR_CD
          AND TT.FORWARD_CCY = 'CNY'
        WHERE A.DATA_DATE = I_DATADATE
          AND STOCK_PRO_TYPE = 'A' --同业存单
          AND PRODUCT_PROP = 'A' --持有
          AND A.DC_DATE <= 30
          AND A.DC_DATE >= 1
          --AND A.ORG_NUM = '009804' --吴大为，放开该条件
        GROUP BY A.ORG_NUM;

+委外业务：科目为11010303，取账户类型是FVTPL账户的都取进来，其中中信信托2笔特殊处理按照到期日取1个月内，FVTPL账户取持有仓位+公允；*/
       INSERT 
       INTO `G22R_1.9.A` 
        (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT I_DATADATE,
                ORG_NUM,
                'G22R_1.9.A', --同业金融部确认后没有外币部分
                SUM(ACCT_BAL_RMB)
           FROM (--基金
                 SELECT A.ORG_NUM, SUM(A.ACCT_BAL_RMB) ACCT_BAL_RMB
                   FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
                  WHERE A.DATA_DATE = I_DATADATE
                    AND FLAG = '06' -- 基金所有
                    AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
                 --(ABS((A.MATUR_DATE - TO_DATE('20240331', 'YYYYMMDD')))< =30 OR  A.REDEMPTION_TYPE='随时赎回' ) --随时赎回放到2到7日  --同业金融部确认后逾期不要
                  GROUP BY A.ORG_NUM
                 UNION ALL
                 --委外投资
                 SELECT A.ORG_NUM, SUM(A.ACCT_BAL_RMB) ACCT_BAL_RMB
                   FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
                  WHERE A.DATA_DATE = I_DATADATE
                    AND FLAG = '07' -- 委外投资
                    AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
                    AND A.ACCT_NUM  IN ('N000310000025496', 'N000310000025495')
                  GROUP BY A.ORG_NUM
                 --中信信托2笔特殊处理按照到期日取1个月内
                 UNION ALL
                 SELECT A.ORG_NUM, SUM(A.ACCT_BAL_RMB) ACCT_BAL_RMB
                   FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
                  WHERE A.DATA_DATE = I_DATADATE
                    AND FLAG = '07' -- 委外投资
                    AND A.ACCT_NUM NOT  IN ('N000310000025496', 'N000310000025495')
                  GROUP BY A.ORG_NUM)
          GROUP BY ORG_NUM;

--ADD BY DJH 20240510  投资银行部
   --009817：存量非标业务的一个月内到期的本金+应收利息+其他应收款，剔除不良资产（次级，可疑，损失）后按剩余期限划分取值；
      INSERT 
       INTO `G22R_1.9.A` 
         (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
         SELECT I_DATADATE,
                ORG_NUM,
                'G22R_1.9.A',
                SUM(ACCT_BAL_RMB)
           FROM (SELECT A.ORG_NUM, SUM(A.ACCT_BAL_RMB) ACCT_BAL_RMB
                   FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
                  WHERE A.DATA_DATE = I_DATADATE
                    AND FLAG = '09'
                    AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
                    AND A.GRADE NOT IN ('3','4','5')
                  GROUP BY A.ORG_NUM)
          GROUP BY ORG_NUM;


-- 指标: G22R_2.2.B
INSERT 
INTO `G22R_2.2.B` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.2.B',
         SUM(CASE
               WHEN CURR_CD <> 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
             WHEN A.ORG_NUM LIKE '%98%' THEN
              A.ORG_NUM
             WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
               '060300'
             ELSE
              SUBSTR(A.ORG_NUM, 1, 4) || '00'
           END ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(A.ACCT_BAL_RMB) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
             AND (A.GL_ITEM_CODE IN
                 ('20110205', '20110110', '20110202','20110203','20110204','20110211', '20110701', '20110103','20110104','20110105','20110106','20110107',
                 '20110108','20110109', '20110208','20110113', '20110114','20110115','20110209','20110210') OR
                 A.GL_ITEM_CODE LIKE '2010%'  --ALTER BY 石雨 20250527 JLBA202504180011
                OR  A.GL_ITEM_CODE = '20120204')
             AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
           GROUP BY A.DATA_DATE,
                    CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                      WHEN A.ORG_NUM LIKE '%98%' THEN
                       A.ORG_NUM
                       WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                        '060300'
                      ELSE
                       SUBSTR(A.ORG_NUM, 1, 4) || '00'
                    END,
                    A.ACCT_CUR
          UNION ALL
          SELECT I_DATADATE, A.ORG_NUM, A.CURR_CD, sum(A.DEBIT_BAL) CUR_BAL
            FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
           WHERE A.DATA_DATE = I_DATADATE
                --AND A.ITEM_CD ='11003'
             AND ITEM_CD = '3.5.1.A'
           GROUP BY I_DATADATE, A.ORG_NUM, A.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;

INSERT 
INTO `G22R_2.2.B` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.2.B',
         SUM(CASE
               WHEN CURR_CD <> 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
             WHEN A.ORG_NUM LIKE '%98%' THEN
              A.ORG_NUM
             WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
               '060300'
             ELSE
              SUBSTR(A.ORG_NUM, 1, 4) || '00'
           END ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(A.ACCT_BAL_RMB) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
             AND (A.GL_ITEM_CODE IN
                 ('20110205', '20110110', '20110202','20110203','20110204','20110211', '20110701', '20110103','20110104','20110105','20110106','20110107',
                 '20110108','20110109', '20110208','20110113', '20110114','20110115','20110209','20110210') OR
                 A.GL_ITEM_CODE LIKE '2010%'  --ALTER BY 石雨 20250527 JLBA202504180011
                OR  A.GL_ITEM_CODE = '20120204')
             AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
           GROUP BY A.DATA_DATE,
                    CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                      WHEN A.ORG_NUM LIKE '%98%' THEN
                       A.ORG_NUM
                       WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                        '060300'
                      ELSE
                       SUBSTR(A.ORG_NUM, 1, 4) || '00'
                    END,
                    A.ACCT_CUR
          UNION ALL
          SELECT I_DATADATE, A.ORG_NUM, A.CURR_CD, sum(A.DEBIT_BAL) CUR_BAL
            FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
           WHERE A.DATA_DATE = I_DATADATE
                --AND A.ITEM_CD ='11003'
             AND ITEM_CD = '3.5.1.A'
           GROUP BY I_DATADATE, A.ORG_NUM, A.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;


-- 指标: G22R_1.1.B
INSERT 
INTO `G22R_1.1.B` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_1.1.B',
         SUM(CASE
               WHEN CURR_CD <> 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           A.ORG_NUM,
           A.CURR_CD,
           sum(A.DEBIT_BAL * B.CCY_RATE) CUR_BAL
            FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
              ON A.DATA_DATE = B.DATA_DATE
             AND A.CURR_CD = B.BASIC_CCY
             AND B.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
             AND A.ITEM_CD = '1001' --库存现金
             AND A.DEBIT_BAL <> 0
             AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
             AND A.ORG_NUM NOT LIKE '%0000' --去掉分行，汇总时不需要
             AND A.ORG_NUM NOT IN (/*'510000',*/ --磐石吉银村镇银行
                                   '222222', --东盛除双阳汇总
                                   '333333', --新双阳
                                   '444444', --净月潭除双阳
                                   '555555') --长春分行（除双阳、榆树、农安）
           GROUP BY A.DATA_DATE, A.ORG_NUM, A.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;

INSERT 
INTO `G22R_1.1.B` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_1.1.B',
         SUM(CASE
               WHEN CURR_CD <> 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           A.ORG_NUM,
           A.CURR_CD,
           sum(A.DEBIT_BAL * B.CCY_RATE) CUR_BAL
            FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
              ON A.DATA_DATE = B.DATA_DATE
             AND A.CURR_CD = B.BASIC_CCY
             AND B.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
             AND A.ITEM_CD = '1001' --库存现金
             AND A.DEBIT_BAL <> 0
             AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
             AND A.ORG_NUM NOT LIKE '%0000' --去掉分行，汇总时不需要
             AND A.ORG_NUM NOT IN (/*'510000',*/ --磐石吉银村镇银行
                                   '222222', --东盛除双阳汇总
                                   '333333', --新双阳
                                   '444444', --净月潭除双阳
                                   '555555') --长春分行（除双阳、榆树、农安）
           GROUP BY A.DATA_DATE, A.ORG_NUM, A.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;


-- 指标: G22R_2.1.B
INSERT 
INTO `G22R_2.1.B` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.1.B',
         SUM(CASE
               WHEN CURR_CD <> 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           A.ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(A.ACCT_BAL_RMB) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
             AND (A.GL_ITEM_CODE IN
                 ('20110201', '20110101','20110102', '20110111', '20110206', '20130101','20130201','20130301', '20140101','20140201','20140301') OR
                 A.GL_ITEM_CODE = '20120106'
                  or a.gl_item_code in ('22410101','22410102','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]

                 )
           GROUP BY A.DATA_DATE, A.ORG_NUM, A.ACCT_CUR)
   GROUP BY DATA_DATE, ORG_NUM;

INSERT 
INTO `G22R_2.1.B` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.1.B',
         SUM(CASE
               WHEN CURR_CD <> 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           A.ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(A.ACCT_BAL_RMB) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
             AND (A.GL_ITEM_CODE IN
                 ('20110201', '20110101','20110102', '20110111', '20110206', '20130101','20130201','20130301', '20140101','20140201','20140301') OR
                 A.GL_ITEM_CODE = '20120106'
                  or a.gl_item_code in ('22410101','22410102','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]

                 )
           GROUP BY A.DATA_DATE, A.ORG_NUM, A.ACCT_CUR)
   GROUP BY DATA_DATE, ORG_NUM;


-- 指标: G22R_2.1.A
INSERT 
INTO `G22R_2.1.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.1.A',
         SUM(CASE
               WHEN CURR_CD = 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           A.ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(A.ACCT_BAL_RMB) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
             AND (A.GL_ITEM_CODE IN
                 ('20110201', '20110101','20110102', '20110111', '20110206', '20130101','20130201','20130301', '20140101','20140201','20140301') OR
                 A.GL_ITEM_CODE = '20120106'
                  or a.gl_item_code in ('22410101','22410102','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
                 )
           GROUP BY A.DATA_DATE, A.ORG_NUM, A.ACCT_CUR)
   GROUP BY DATA_DATE, ORG_NUM;

INSERT 
INTO `G22R_2.1.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.1.A',
         SUM(CASE
               WHEN CURR_CD = 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           A.ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(A.ACCT_BAL_RMB) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
             AND (A.GL_ITEM_CODE IN
                 ('20110201', '20110101','20110102', '20110111', '20110206', '20130101','20130201','20130301', '20140101','20140201','20140301') OR
                 A.GL_ITEM_CODE = '20120106'
                  or a.gl_item_code in ('22410101','22410102','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
                 )
           GROUP BY A.DATA_DATE, A.ORG_NUM, A.ACCT_CUR)
   GROUP BY DATA_DATE, ORG_NUM;


-- 指标: G22R_2.3.A
--====================================================
    --G22   2.3一个月内到期的同业往来款项轧差后负债方净额
--====================================================
INSERT 
INTO `G22R_2.3.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE,
         B.ORG_NUM,
         'G22R_2.3.A',
         B.ACCT_BAL_RMB AS CUR_CNY_BAL
    FROM (SELECT ORG_NUM, SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
                 FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL
                WHERE DATA_DATE = I_DATADATE
                  AND ACCT_CUR = 'CNY'
                  AND FLAG IN ('03', '04', '05', '07','10')  --alter by 石雨 20250507 同业金融部陈聪剔除少算了200303
                  AND GL_ITEM_CODE <> '20120204' --保险业金融机构存放款项放到3.5.1定期存款
                  AND GL_ITEM_CODE <> '20120106' --保险业金融机构存放款项放到3.5.2活期存款
                  AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
                GROUP BY ORG_NUM) B;

--====================================================
    --G22   2.3一个月内到期的同业往来款项轧差后负债方净额
--====================================================
INSERT 
INTO `G22R_2.3.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE,
         B.ORG_NUM,
         'G22R_2.3.A',
         B.ACCT_BAL_RMB AS CUR_CNY_BAL
    FROM (SELECT ORG_NUM, SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
                 FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL
                WHERE DATA_DATE = I_DATADATE
                  AND ACCT_CUR = 'CNY'
                  AND FLAG IN ('03', '04', '05', '07','10')  --alter by 石雨 20250507 同业金融部陈聪剔除少算了200303
                  AND GL_ITEM_CODE <> '20120204' --保险业金融机构存放款项放到3.5.1定期存款
                  AND GL_ITEM_CODE <> '20120106' --保险业金融机构存放款项放到3.5.2活期存款
                  AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
                GROUP BY ORG_NUM) B;


-- 指标: G22R_8..A
INSERT 
INTO `G22R_8..A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE, ORG_NUM, 'G22R_8..A', CUR_BAL
    FROM (SELECT 
           I_DATADATE AS DATA_DATE,
           A.ORG_NO AS ORG_NUM,
           A.COLL_CCY AS CURR_CD,
           SUM(DEP_AMT) CUR_BAL
            FROM PM_RSDATA.CBRC_FDM_LNAC_PLEDGE_G22 A
           WHERE COLL_CCY = 'CNY'
           GROUP BY A.ORG_NO, A.COLL_CCY);

INSERT 
INTO `G22R_8..A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE, ORG_NUM, 'G22R_8..A', CUR_BAL
    FROM (SELECT 
           I_DATADATE AS DATA_DATE,
           A.ORG_NO AS ORG_NUM,
           A.COLL_CCY AS CURR_CD,
           SUM(DEP_AMT) CUR_BAL
            FROM CBRC_FDM_LNAC_PLEDGE_G22 A
           WHERE COLL_CCY = 'CNY'
           GROUP BY A.ORG_NO, A.COLL_CCY);


-- 指标: G22R_1.1.A
-------------------------------存款------------------------------------

--====================================================
    --G22 1.1现金   101库存现金
--====================================================
INSERT 
INTO `G22R_1.1.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_1.1.A',
         SUM(CASE
               WHEN CURR_CD = 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           A.ORG_NUM,
           A.CURR_CD,
           sum(A.DEBIT_BAL * B.CCY_RATE) CUR_BAL
            FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
              ON A.DATA_DATE = B.DATA_DATE
             AND A.CURR_CD = B.BASIC_CCY
             AND B.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
             AND A.ITEM_CD = '1001' --库存现金
             AND A.DEBIT_BAL <> 0
             AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
             AND A.ORG_NUM NOT LIKE '%0000' --去掉分行，汇总时不需要
             AND A.ORG_NUM NOT IN (/*'510000',*/ --磐石吉银村镇银行
                                   '222222', --东盛除双阳汇总
                                   '333333', --新双阳
                                   '444444', --净月潭除双阳
                                   '555555') --长春分行（除双阳、榆树、农安）
           GROUP BY A.DATA_DATE, A.ORG_NUM, A.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;

-------------------------------存款------------------------------------

--====================================================
    --G22 1.1现金   101库存现金
--====================================================
INSERT 
INTO `G22R_1.1.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_1.1.A',
         SUM(CASE
               WHEN CURR_CD = 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           A.ORG_NUM,
           A.CURR_CD,
           sum(A.DEBIT_BAL * B.CCY_RATE) CUR_BAL
            FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
              ON A.DATA_DATE = B.DATA_DATE
             AND A.CURR_CD = B.BASIC_CCY
             AND B.FORWARD_CCY = 'CNY'
           WHERE A.DATA_DATE = I_DATADATE
             AND A.ITEM_CD = '1001' --库存现金
             AND A.DEBIT_BAL <> 0
             AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
             AND A.ORG_NUM NOT LIKE '%0000' --去掉分行，汇总时不需要
             AND A.ORG_NUM NOT IN (/*'510000',*/ --磐石吉银村镇银行
                                   '222222', --东盛除双阳汇总
                                   '333333', --新双阳
                                   '444444', --净月潭除双阳
                                   '555555') --长春分行（除双阳、榆树、农安）
           GROUP BY A.DATA_DATE, A.ORG_NUM, A.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;


-- 指标: G22R_9..A
INSERT 
INTO `G22R_9..A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE, ORG_NUM, 'G22R_9..A', CUR_BAL
    FROM (SELECT 
           I_DATADATE AS DATA_DATE,
           A.ORG_NUM,
           A.CURR_CD AS CURR_CD,
           SUM(LOAN_ACCT_BAL) CUR_BAL
            FROM PM_RSDATA.CBRC_FDM_LNAC_PLEDGE_G22 A
           WHERE CURR_CD = 'CNY'
           GROUP BY A.ORG_NUM, A.CURR_CD);

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
            INSERT 
            INTO `G22R_9..A` 
              (DATA_DATE,
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
               COL_8)
              SELECT I_DATADATE,
                     T1.ORG_NUM,
                     T1.DATA_DEPARTMENT, --数据条线
                     'CBRC' AS SYS_NAM,
                     'G22R' REP_NUM,
                     CASE
                       WHEN T1.CURR_CD = 'CNY' THEN
                        'G22R_9..A'
                       ELSE
                        'G22R_9..B'
                     END AS ITEM_NUM,
                     LOAN_ACCT_BAL AS TOTAL_VALUE, --贷款余额
                     T1.LOAN_NUM AS COL_1,--贷款编号
                     T1.CURR_CD AS COL2, --币种
                     T1.ACTUAL_MATURITY_DT AS COL4, --贷款实际到期日
                     T1.CONTRACT_NUM AS COL6, --贷款合同编号
                     T1.ORG_NO AS COL9, --存单机构
                     T1.COLL_CCY AS COL10,--存单币种
                     T1.DEP_AMT AS COL11,--存单金额
                     T1.DEP_MATURITY AS COL12 --存单到期日
                FROM CBRC_FDM_LNAC_PLEDGE_G22 T1
                WHERE LOAN_ACCT_BAL <> 0;


-- 指标: G22R_2.2.A
INSERT 
INTO `G22R_2.2.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.2.A',
         SUM(CASE
               WHEN CURR_CD = 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
             WHEN A.ORG_NUM LIKE '%98%' THEN
              A.ORG_NUM
             WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                 '060300'
             ELSE
              SUBSTR(A.ORG_NUM, 1, 4) || '00'
           END ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(A.ACCT_BAL_RMB) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
             AND (A.GL_ITEM_CODE IN
                 ('20110205', '20110110', '20110202','20110203','20110204','20110211', '20110701', '20110103','20110104','20110105','20110106','20110107',
                 '20110108','20110109', '20110208','20110113', '20110114','20110115','20110209','20110210') OR
                 A.GL_ITEM_CODE LIKE '2010%'  --ALTER BY 石雨 20250527 JLBA202504180011
                OR  A.GL_ITEM_CODE = '20120204')
             AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
           GROUP BY A.DATA_DATE,
                    CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                      WHEN A.ORG_NUM LIKE '%98%' THEN
                       A.ORG_NUM
                       WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                       '060300'
                      ELSE
                       SUBSTR(A.ORG_NUM, 1, 4) || '00'
                    END,
                    A.ACCT_CUR
          UNION ALL
          SELECT I_DATADATE, A.ORG_NUM, A.CURR_CD, sum(A.DEBIT_BAL) CUR_BAL
            FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
           WHERE A.DATA_DATE = I_DATADATE
                --AND A.ITEM_CD ='11003'
             AND ITEM_CD = '3.5.1.A'
           GROUP BY I_DATADATE, A.ORG_NUM, A.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;

INSERT 
INTO `G22R_2.2.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.2.A',
         SUM(CASE
               WHEN CURR_CD = 'CNY' THEN
                CUR_BAL
               ELSE
                0
             END) AS CUR_CNY_BAL
    FROM (SELECT 
           A.DATA_DATE,
           CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
             WHEN A.ORG_NUM LIKE '%98%' THEN
              A.ORG_NUM
             WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                 '060300'
             ELSE
              SUBSTR(A.ORG_NUM, 1, 4) || '00'
           END ORG_NUM,
           A.ACCT_CUR AS CURR_CD,
           SUM(A.ACCT_BAL_RMB) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
             AND (A.GL_ITEM_CODE IN
                 ('20110205', '20110110', '20110202','20110203','20110204','20110211', '20110701', '20110103','20110104','20110105','20110106','20110107',
                 '20110108','20110109', '20110208','20110113', '20110114','20110115','20110209','20110210') OR
                 A.GL_ITEM_CODE LIKE '2010%'  --ALTER BY 石雨 20250527 JLBA202504180011
                OR  A.GL_ITEM_CODE = '20120204')
             AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
           GROUP BY A.DATA_DATE,
                    CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                      WHEN A.ORG_NUM LIKE '%98%' THEN
                       A.ORG_NUM
                       WHEN A.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                       '060300'
                      ELSE
                       SUBSTR(A.ORG_NUM, 1, 4) || '00'
                    END,
                    A.ACCT_CUR
          UNION ALL
          SELECT I_DATADATE, A.ORG_NUM, A.CURR_CD, sum(A.DEBIT_BAL) CUR_BAL
            FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
           WHERE A.DATA_DATE = I_DATADATE
                --AND A.ITEM_CD ='11003'
             AND ITEM_CD = '3.5.1.A'
           GROUP BY I_DATADATE, A.ORG_NUM, A.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;


-- 指标: G22R_1.8.A
--====================================================================================================
    --G22   1.8在国内外二级市场上可随时变现的证券投资（不包括项目1.7的有关项目） add by chm 20231012
--====================================================================================================

   INSERT 
   INTO `G22R_1.8.A` 
     (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
     SELECT I_DATADATE AS DATA_DATE,
            A.ORG_NUM,
            'G22R_1.8.A',
            SUM(A.ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                A.ACCT_BAL_CNY)
       FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
      WHERE A.DATA_DATE = I_DATADATE
        AND ACCT_BAL_CNY <> 0   --JLBA202411080004
        AND A.INVEST_TYP = '00' --债券
        AND A.DC_DATE > 30
      GROUP BY A.ORG_NUM;

--====================================================================================================
    --G22   1.8在国内外二级市场上可随时变现的证券投资（不包括项目1.7的有关项目） add by chm 20231012
--====================================================================================================

   INSERT 
   INTO `G22R_1.8.A` 
     (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
     SELECT I_DATADATE AS DATA_DATE,
            A.ORG_NUM,
            'G22R_1.8.A',
            SUM(A.ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                A.ACCT_BAL_CNY)
       FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
      WHERE A.DATA_DATE = I_DATADATE
        AND ACCT_BAL_CNY <> 0   --JLBA202411080004
        AND A.INVEST_TYP = '00' --债券
        AND A.DC_DATE > 30
      GROUP BY A.ORG_NUM;


-- 指标: G22R_1.4.A
--====================================================
    --G22 1.4一个月内到期的同业往来款项轧差后资产方净额 需要每个机构层级进行轧差，公式实现
--====================================================
/*30天内到期的同业资产方与负债方扎差，判断余额方向 在资产方
资产方：
1.3存放同业款项
1.4拆放同业
1.5.1买入返售资产（不含非金融机构)
负债方：
3.2同业存放款项
3.3同业拆入
3.4卖出回购款项（不含非金融机构）*/
INSERT 
INTO `G22R_1.4.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE,
         A.ORG_NUM,
         'G22R_1.4.A',
         ACCT_BAL_RMB AS ITEM_VAL
    FROM (SELECT ORG_NUM, SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL
           WHERE DATA_DATE = I_DATADATE
             AND ACCT_CUR = 'CNY'
             AND FLAG IN ('01', '02', '03')
             AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
           GROUP BY ORG_NUM) A;

--====================================================
    --G22 1.4一个月内到期的同业往来款项轧差后资产方净额 需要每个机构层级进行轧差，公式实现
--====================================================
/*30天内到期的同业资产方与负债方扎差，判断余额方向 在资产方
资产方：
1.3存放同业款项
1.4拆放同业
1.5.1买入返售资产（不含非金融机构)
负债方：
3.2同业存放款项
3.3同业拆入
3.4卖出回购款项（不含非金融机构）*/
INSERT 
INTO `G22R_1.4.A` 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT I_DATADATE,
         A.ORG_NUM,
         'G22R_1.4.A',
         ACCT_BAL_RMB AS ITEM_VAL
    FROM (SELECT ORG_NUM, SUM(ACCT_BAL_RMB) ACCT_BAL_RMB
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL
           WHERE DATA_DATE = I_DATADATE
             AND ACCT_CUR = 'CNY'
             AND FLAG IN ('01', '02', '03')
             AND REMAIN_TERM_CODE IN ('A', 'B', 'C')
           GROUP BY ORG_NUM) A;


