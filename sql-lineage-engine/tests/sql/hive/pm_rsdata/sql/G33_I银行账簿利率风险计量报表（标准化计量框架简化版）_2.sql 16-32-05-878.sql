-- ============================================================
-- 文件名: G33_I银行账簿利率风险计量报表（标准化计量框架简化版）_2.sql
-- 生成时间: 2025-12-18 13:53:40
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: G33_1_2.1.2.F.2019
INSERT 
    INTO `G33_1_2.1.2.F.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.F.2019' ITEM_NUM,
       SUM(T.AMOUNT_F) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.1.2.F.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.F.2019' ITEM_NUM,
       SUM(T.AMOUNT_F) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_1_2.1.3.K.2019
INSERT 
    INTO `G33_1_2.1.3.K.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.K.2019' ITEM_NUM,
       SUM(T.AMOUNT_K) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.1.3.K.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.K.2019' ITEM_NUM,
       SUM(T.AMOUNT_K) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_1_2.1.3.N.2019
INSERT 
    INTO `G33_1_2.1.3.N.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.N.2019' ITEM_NUM,
       SUM(T.AMOUNT_N) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.1.3.N.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.N.2019' ITEM_NUM,
       SUM(T.AMOUNT_N) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_1_2.4.I.2019
INSERT 
    INTO `G33_1_2.4.I.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.I.2019' ITEM_NUM,
       SUM(T.AMOUNT_I) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.4.I.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.I.2019' ITEM_NUM,
       SUM(T.AMOUNT_I) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_I_1_1.2.Q
INSERT 
   INTO `G33_I_1_1.2.Q` 
     (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
     SELECT 
      I_DATADATE AS DATA_DATE,
      ORGNO,
      CASE
        WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
         'G33_I_1_1.1.Q'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
         'G33_I_1_1.2.Q'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
         'G33_I_1_1.4.Q'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
         'G33_1_2_1.1.Q'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
         'G33_1_2_1.4.Q'
      END ITEM_NUM,
      SUM(T.AMOUNT_Q) AS CUR_BAL
       FROM CBRC_ID_G3301_ITEMDATA_NGI T
      WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                'G33_I_1_1.2',
                                'G33_I_1_1.4',
                                'G33_1_2_1.1',
                                'G33_1_2_1.4')
        AND T.RQ = I_DATADATE
      GROUP BY ORGNO,
               CASE
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                  'G33_I_1_1.1.Q'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                  'G33_I_1_1.2.Q'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                  'G33_I_1_1.4.Q'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                  'G33_1_2_1.1.Q'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                  'G33_1_2_1.4.Q'
               END;

INSERT 
   INTO `G33_I_1_1.2.Q` 
     (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
     SELECT 
      I_DATADATE AS DATA_DATE,
      ORGNO,
      CASE
        WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
         'G33_I_1_1.1.Q'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
         'G33_I_1_1.2.Q'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
         'G33_I_1_1.4.Q'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
         'G33_1_2_1.1.Q'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
         'G33_1_2_1.4.Q'
      END ITEM_NUM,
      SUM(T.AMOUNT_Q) AS CUR_BAL
       FROM CBRC_ID_G3301_ITEMDATA_NGI T
      WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                'G33_I_1_1.2',
                                'G33_I_1_1.4',
                                'G33_1_2_1.1',
                                'G33_1_2_1.4')
        AND T.RQ = I_DATADATE
      GROUP BY ORGNO,
               CASE
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                  'G33_I_1_1.1.Q'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                  'G33_I_1_1.2.Q'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                  'G33_I_1_1.4.Q'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                  'G33_1_2_1.1.Q'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                  'G33_1_2_1.4.Q'
               END;


-- 指标: G33_I_1.3.P
INSERT 
    INTO `G33_I_1.3.P` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.P'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.P'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.P'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.P'
       END ITEM_NUM,
       SUM(T.AMOUNT_P) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO `G33_I_1.3.P` 
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
          COL_7,
          COL_12)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12 --客户号
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          WHERE T1.FLAG = '01' --零售
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

INSERT 
       INTO `G33_I_1.3.P` 
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
          COL_7,
          COL_12,
          COL_13,
          COL_14)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12, --客户号
          T2.M_NAME AS COL_13, --企业规模
          FACILITY_AMT AS COL_14 --授信额度
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          LEFT JOIN A_REPT_DWD_MAPPING T2
            ON T1.CORP_SCALE = T2.M_CODE
            AND T2.M_TABLECODE = 'CORP_SCALE'
          WHERE T1.FLAG = '02' --小微企业授信1000万以下
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       --金融市场部 转贴现
       -- 小型企业：03、微型企业：04
        INSERT 
        INTO `G33_I_1.3.P` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE <= 1 THEN
              'G33_I_1.3.B'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 2 AND 30 THEN
              'G33_I_1.3.C'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 31 AND 90 THEN
              'G33_I_1.3.D'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 91 AND 180 THEN
              'G33_I_1.3.E'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 181 AND 270 THEN
              'G33_I_1.3.F'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 271 AND 360 THEN
              'G33_I_1.3.G'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 361 AND 540 THEN
              'G33_I_1.3.H'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 541 AND 720 THEN
              'G33_I_1.3.I'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 721 AND 1080 THEN
              'G33_I_1.3.J'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1081 AND 1440 THEN
              'G33_I_1.3.K'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1441 AND 1800 THEN
              'G33_I_1.3.L'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
              'G33_I_1.3.M'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
              'G33_I_1.3.N'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
              'G33_I_1.3.O'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
              'G33_I_1.3.P'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
              'G33_I_1.3.Q'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 10 + 1 AND
                  360 * 15 THEN
              'G33_I_1.3.R'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 15 + 1 AND
                  360 * 20 THEN
              'G33_I_1.3.S'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE > 360 * 20 THEN
              'G33_I_1.3.T'
           END AS ITEM_NUM,
           T.LOAN_ACCT_BAL AS TOTAL_VALUE,
           T.LOAN_NUM AS COL1, --贷款编号
           T.CURR_CD AS COL2, --币种
           T.ITEM_CD AS COL3, --科目
           TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYY-MM-DD') AS COL4, --到期日（日期）
           T.ACCT_NUM AS COL6, --贷款合同编号
           NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
           CASE
             WHEN T.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8, --五级分类
           CASE
             WHEN T3.CORP_SIZE = '01' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '02' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '03' THEN
              '小型企业'
             WHEN T3.CORP_SIZE = '04' THEN
              '微型企业'
           END AS COL_13 --企业规模
            FROM CBRC_FDM_LNAC T
           INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                         FROM L_CUST_BILL_TY T
                        WHERE T.DATA_DATE = I_DATADATE) T2
              ON T.CUST_ID = T2.CUST_ID
           INNER JOIN L_CUST_EXTERNAL_INFO T3
              ON T2.LEGAL_TYSHXYDM = T3.USCD
             AND T3.DATA_DATE = I_DATADATE
            LEFT JOIN L_PUBL_RATE TT
              ON TT.DATA_DATE = T.DATA_DATE
             AND TT.BASIC_CCY = T.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
            LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                              MIN(T1.HOLIDAY_DATE) LASTDAY,
                              T.DATA_DATE AS DATADATE
                         FROM L_PUBL_HOLIDAY T
                         LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                     FROM L_PUBL_HOLIDAY T
                                    WHERE T.COUNTRY = 'CHN'
                                      AND T.STATE = '220000'
                                      AND T.WORKING_HOLIDAY = 'W' --工作日
                                   ) T1
                           ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                          AND T.DATA_DATE = T1.DATA_DATE
                        WHERE T.COUNTRY = 'CHN'
                          AND T.STATE = '220000'
                          AND T.WORKING_HOLIDAY = 'H' --假日
                          AND T.HOLIDAY_DATE <= I_DATADATE
                        GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
              ON T.MATURITY_DT = T1.HOLIDAY_DATE
             AND T.DATA_DATE = T1.DATADATE
           WHERE T.DATA_DATE = I_DATADATE
             AND T.ACCT_TYP NOT LIKE '90%'
             AND T.LOAN_ACCT_BAL <> 0
             AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
             AND T3.CORP_SIZE IN ('03', '04');

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

      INSERT 
      INTO `G33_I_1.3.P` 
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
         COL_7,
         COL_12)
        SELECT 
         I_DATADATE,
         T1.ORG_NUM,
         T1.DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
         END AS ITEM_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4' THEN
            NVL(T1.OD_INT, 0)
           WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
            T1.ACCU_INT_AMT
         END AS TOTAL_VALUE, --贷款余额
         T1.LOAN_NUM AS COL1, --贷款编号
         T1.CURR_CD AS COL2, --币种
         T1.ITEM_CD AS COL3, --科目
         T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
         CUST_ID AS COL_12 --客户号
          FROM CBRC_FDM_LNAC_PMT_LX_Q T1
         WHERE T1.FLAG = '01' --零售利息
           AND T1.ORG_NUM <> '009804'
           AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

INSERT 
        INTO `G33_I_1.3.P` 
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
           COL_7,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
          END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           T1.CUST_ID AS COL_12, --客户号
           T2.M_NAME AS COL_13, --企业规模
           T1.FACILITY_AMT COL_14 --授信额度
            FROM CBRC_FDM_LNAC_PMT_LX_Q T1
            LEFT JOIN A_REPT_DWD_MAPPING T2
              ON T1.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T1.FLAG = '02' --小微企业1000万以下利息
             AND T1.ORG_NUM <> '009804'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.1.3.N
INSERT 
    INTO `G33_I_1.1.3.N` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_I_1.1.3.N' ITEM_NUM,
       SUM(T.AMOUNT_N) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.1.3.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.N` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_1_2.4.K.2019
INSERT 
    INTO `G33_1_2.4.K.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.K.2019' ITEM_NUM,
       SUM(T.AMOUNT_K) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.4.K.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.K.2019' ITEM_NUM,
       SUM(T.AMOUNT_K) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_1_2.1.3.1.G.2019
INSERT 
    INTO `G33_1_2.1.3.1.G.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.G.2019' ITEM_NUM,
       SUM(T.AMOUNT_G) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.1.3.1.G.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.G.2019' ITEM_NUM,
       SUM(T.AMOUNT_G) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_I_1.4.Q
INSERT 
    INTO `G33_I_1.4.Q` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.Q'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.Q'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.Q'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.Q'
       END ITEM_NUM,
       SUM(T.AMOUNT_Q) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

       -- 大型企业：01、中型企业
       INSERT 
       INTO `G33_I_1.4.Q` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
         SELECT 
          I_DATADATE,
          T.ORG_NUM,
          T.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE <= 1 THEN
             'G33_I_1.4.B'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 2 AND 30 THEN
             'G33_I_1.4.C'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 31 AND 90 THEN
             'G33_I_1.4.D'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 91 AND 180 THEN
             'G33_I_1.4.E'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 181 AND 270 THEN
             'G33_I_1.4.F'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 271 AND 360 THEN
             'G33_I_1.4.G'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 361 AND 540 THEN
             'G33_I_1.4.H'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 541 AND 720 THEN
             'G33_I_1.4.I'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 721 AND 1080 THEN
             'G33_I_1.4.J'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1081 AND 1440 THEN
             'G33_I_1.4.K'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1441 AND 1800 THEN
             'G33_I_1.4.L'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
             'G33_I_1.4.M'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
             'G33_I_1.4.N'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
             'G33_I_1.4.O'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
             'G33_I_1.4.P'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
             'G33_I_1.4.Q'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
             'G33_I_1.4.R'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
             'G33_I_1.4.S'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE > 360 * 20 THEN
             'G33_I_1.4.T'
          END AS ITEM_NUM,
          T.LOAN_ACCT_BAL AS TOTAL_VALUE,
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYYMMDD') AS COL4, --到期日（日期）
          T.ACCT_NUM AS COL6, --贷款合同编号
          NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
          CASE
            WHEN T.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T3.CORP_SIZE = '01' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '02' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '03' THEN
             '小型企业'
            WHEN T3.CORP_SIZE = '04' THEN
             '微型企业'
          END AS COL_13 --企业规模
           FROM CBRC_FDM_LNAC T
          INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                        FROM L_CUST_BILL_TY T
                       WHERE T.DATA_DATE = I_DATADATE) T2
             ON T.CUST_ID = T2.CUST_ID
          INNER JOIN L_CUST_EXTERNAL_INFO T3
             ON T2.LEGAL_TYSHXYDM = T3.USCD
            AND T3.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                             MIN(T1.HOLIDAY_DATE) LASTDAY,
                             T.DATA_DATE AS DATADATE
                        FROM L_PUBL_HOLIDAY T
                        LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                    FROM L_PUBL_HOLIDAY T
                                   WHERE T.COUNTRY = 'CHN'
                                     AND T.STATE = '220000'
                                     AND T.WORKING_HOLIDAY = 'W' --工作日
                                  ) T1
                          ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                         AND T.DATA_DATE = T1.DATA_DATE
                       WHERE T.COUNTRY = 'CHN'
                         AND T.STATE = '220000'
                         AND T.WORKING_HOLIDAY = 'H' --假日
                         AND T.HOLIDAY_DATE <= I_DATADATE
                       GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
             ON T.MATURITY_DT = T1.HOLIDAY_DATE
            AND T.DATA_DATE = T1.DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
            AND T3.CORP_SIZE IN ('01', '02');

--===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    -- 1.3 具备提前还款权的固定利率批发类贷款
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.Q` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                  (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '1') or
                  (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN cbrc_fdm_lnac_pmt_bj_q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有本金数据
             AND T.CURR_CD = 'CNY'
             AND T.ORG_NUM <> '009804'
             AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.Q` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN cbrc_fdm_lnac_pmt_lx T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN CBRC_FDM_LNAC_PMT_LX_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有利息数据
             AND T.CURR_CD = 'CNY'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_1_2.1.3.1.E.2019
INSERT 
    INTO `G33_1_2.1.3.1.E.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.E.2019' ITEM_NUM,
       SUM(T.AMOUNT_E) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.1.3.1.E.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.E.2019' ITEM_NUM,
       SUM(T.AMOUNT_E) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_I_1_1.2.M
INSERT 
   INTO `G33_I_1_1.2.M` 
     (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
     SELECT 
      I_DATADATE AS DATA_DATE,
      ORGNO,
      CASE
        WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
         'G33_I_1_1.1.M'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
         'G33_I_1_1.2.M'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
         'G33_I_1_1.4.M'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
         'G33_1_2_1.1.M'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
         'G33_1_2_1.4.M'
      END ITEM_NUM,
      SUM(T.AMOUNT_M) AS CUR_BAL
       FROM CBRC_ID_G3301_ITEMDATA_NGI T
      WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                'G33_I_1_1.2',
                                'G33_I_1_1.4',
                                'G33_1_2_1.1',
                                'G33_1_2_1.4')
        AND T.RQ = I_DATADATE
      GROUP BY ORGNO,
               CASE
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                  'G33_I_1_1.1.M'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                  'G33_I_1_1.2.M'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                  'G33_I_1_1.4.M'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                  'G33_1_2_1.1.M'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                  'G33_1_2_1.4.M'
               END;

INSERT 
   INTO `G33_I_1_1.2.M` 
     (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
     SELECT 
      I_DATADATE AS DATA_DATE,
      ORGNO,
      CASE
        WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
         'G33_I_1_1.1.M'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
         'G33_I_1_1.2.M'
        WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
         'G33_I_1_1.4.M'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
         'G33_1_2_1.1.M'
        WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
         'G33_1_2_1.4.M'
      END ITEM_NUM,
      SUM(T.AMOUNT_M) AS CUR_BAL
       FROM CBRC_ID_G3301_ITEMDATA_NGI T
      WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                'G33_I_1_1.2',
                                'G33_I_1_1.4',
                                'G33_1_2_1.1',
                                'G33_1_2_1.4')
        AND T.RQ = I_DATADATE
      GROUP BY ORGNO,
               CASE
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                  'G33_I_1_1.1.M'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                  'G33_I_1_1.2.M'
                 WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                  'G33_I_1_1.4.M'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                  'G33_1_2_1.1.M'
                 WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                  'G33_1_2_1.4.M'
               END;


-- 指标: G33_I_1.1.3.D
INSERT 
    INTO `G33_I_1.1.3.D` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_I_1.1.3.D' ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.1.3.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.D` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_1_2.1.3.1.M.2019
INSERT 
    INTO `G33_1_2.1.3.1.M.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.M.2019' ITEM_NUM,
       SUM(T.AMOUNT_M) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.1.3.1.M.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.M.2019' ITEM_NUM,
       SUM(T.AMOUNT_M) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_1_2.1.3.C.2019
INSERT 
    INTO `G33_1_2.1.3.C.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.C.2019' ITEM_NUM,
       SUM(T.AMOUNT_C) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.1.3.C.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.C.2019' ITEM_NUM,
       SUM(T.AMOUNT_C) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_1_2.4.F.2019
INSERT 
    INTO `G33_1_2.4.F.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.F.2019' ITEM_NUM,
       SUM(T.AMOUNT_F) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.4.F.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.F.2019' ITEM_NUM,
       SUM(T.AMOUNT_F) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_1_2.1.3.L.2019
INSERT 
    INTO `G33_1_2.1.3.L.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.L.2019' ITEM_NUM,
       SUM(T.AMOUNT_L) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.1.3.L.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.L.2019' ITEM_NUM,
       SUM(T.AMOUNT_L) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_I_1.1.3.2.G
INSERT 
    INTO `G33_I_1.1.3.2.G` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.G'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.G'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.G'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.G'
       END ITEM_NUM,
       SUM(T.AMOUNT_G) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO `G33_I_1.1.3.2.G` 
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
                COL_10)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
                 FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '1'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账'))--add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO `G33_I_1.1.3.2.G` 
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
                COL_11)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD')  AS COL_11--下一利率重定价日
                 FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '3'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;

----------------------------------按照正常重定价日处理
   -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO `G33_I_1.1.3.2.G` 
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
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.2.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.2.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.1.3.2.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
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
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND (T1.BENM_INRAT_TYPE = 'A' OR
                (T1.BENM_INRAT_TYPE = '#' AND
                T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
            AND T1.NEXT_PAYMENT <>0;

--133应收利息  应计利息+应收利息
    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.1.3.2.G` 
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
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.2.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.2.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.2.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM cbrc_fdm_lnac_pmt_lx T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND (T1.BENM_INRAT_TYPE = 'A' OR
                 (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --分项指标转换   此处插入利息轧差项目，其他在A_REPT_DWD_G3301明细中处理
    /* 1.1.3.1 其中：以贷款市场报价利率（LPR）为定价基础的人民币浮动利率贷款
    1.1.3.2 其中：以人民银行基准利率为定价基础的浮动利率贷款
    1.2 具备提前还款权的固定利率零售类贷款
    1.3 具备提前还款权的固定利率批发类贷款*/
      INSERT 
      INTO `G33_I_1.1.3.2.G` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE)
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.B' ITEM_NUM,
         SUM(T.AMOUNT_B) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_B <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.C' ITEM_NUM,
         SUM(T.AMOUNT_C) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_C <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.D' ITEM_NUM,
         SUM(T.AMOUNT_D) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_D <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.E' ITEM_NUM,
         SUM(T.AMOUNT_E) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_E <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.F' ITEM_NUM,
         SUM(T.AMOUNT_F) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_F <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.G' ITEM_NUM,
         SUM(T.AMOUNT_G) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_G <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.H' ITEM_NUM,
         SUM(T.AMOUNT_H) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_H <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.I' ITEM_NUM,
         SUM(T.AMOUNT_I) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_I <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.J' ITEM_NUM,
         SUM(T.AMOUNT_J) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_J <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.K' ITEM_NUM,
         SUM(T.AMOUNT_K) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_K <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.L' ITEM_NUM,
         SUM(T.AMOUNT_L) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_L <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.M' ITEM_NUM,
         SUM(T.AMOUNT_M) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_M <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.N' ITEM_NUM,
         SUM(T.AMOUNT_N) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_N <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.O' ITEM_NUM,
         SUM(T.AMOUNT_O) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_O <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.P' ITEM_NUM,
         SUM(T.AMOUNT_P) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_P <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.Q' ITEM_NUM,
         SUM(T.AMOUNT_Q) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_Q <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.R' ITEM_NUM,
         SUM(T.AMOUNT_R) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_R <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.S' ITEM_NUM,
         SUM(T.AMOUNT_S) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_S <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.T' ITEM_NUM,
         SUM(T.AMOUNT_T) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_T <> 0
         GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.2.G` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_1_2.1.3.1.D.2019
INSERT 
    INTO `G33_1_2.1.3.1.D.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.D.2019' ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.1.3.1.D.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.D.2019' ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_1_2.1.3.1.H.2019
INSERT 
    INTO `G33_1_2.1.3.1.H.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.H.2019' ITEM_NUM,
       SUM(T.AMOUNT_H) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.1.3.1.H.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.H.2019' ITEM_NUM,
       SUM(T.AMOUNT_H) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_I_1.1.3.K
INSERT 
    INTO `G33_I_1.1.3.K` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_I_1.1.3.K' ITEM_NUM,
       SUM(T.AMOUNT_K) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.1.3.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.K` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.1.3.G
INSERT 
    INTO `G33_I_1.1.3.G` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_I_1.1.3.G' ITEM_NUM,
       SUM(T.AMOUNT_G) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.1.3.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.G` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.1.3.2.L
INSERT 
    INTO `G33_I_1.1.3.2.L` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.L'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.L'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.L'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.L'
       END ITEM_NUM,
       SUM(T.AMOUNT_L) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO `G33_I_1.1.3.2.L` 
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
                COL_10)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
                 FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '1'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账'))--add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO `G33_I_1.1.3.2.L` 
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
                COL_11)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD')  AS COL_11--下一利率重定价日
                 FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '3'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;

----------------------------------按照正常重定价日处理
   -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO `G33_I_1.1.3.2.L` 
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
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.2.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.2.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.1.3.2.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
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
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND (T1.BENM_INRAT_TYPE = 'A' OR
                (T1.BENM_INRAT_TYPE = '#' AND
                T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
            AND T1.NEXT_PAYMENT <>0;

--133应收利息  应计利息+应收利息
    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.1.3.2.L` 
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
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.2.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.2.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.2.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM cbrc_fdm_lnac_pmt_lx T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND (T1.BENM_INRAT_TYPE = 'A' OR
                 (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --分项指标转换   此处插入利息轧差项目，其他在A_REPT_DWD_G3301明细中处理
    /* 1.1.3.1 其中：以贷款市场报价利率（LPR）为定价基础的人民币浮动利率贷款
    1.1.3.2 其中：以人民银行基准利率为定价基础的浮动利率贷款
    1.2 具备提前还款权的固定利率零售类贷款
    1.3 具备提前还款权的固定利率批发类贷款*/
      INSERT 
      INTO `G33_I_1.1.3.2.L` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE)
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.B' ITEM_NUM,
         SUM(T.AMOUNT_B) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_B <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.C' ITEM_NUM,
         SUM(T.AMOUNT_C) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_C <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.D' ITEM_NUM,
         SUM(T.AMOUNT_D) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_D <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.E' ITEM_NUM,
         SUM(T.AMOUNT_E) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_E <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.F' ITEM_NUM,
         SUM(T.AMOUNT_F) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_F <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.G' ITEM_NUM,
         SUM(T.AMOUNT_G) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_G <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.H' ITEM_NUM,
         SUM(T.AMOUNT_H) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_H <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.I' ITEM_NUM,
         SUM(T.AMOUNT_I) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_I <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.J' ITEM_NUM,
         SUM(T.AMOUNT_J) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_J <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.K' ITEM_NUM,
         SUM(T.AMOUNT_K) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_K <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.L' ITEM_NUM,
         SUM(T.AMOUNT_L) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_L <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.M' ITEM_NUM,
         SUM(T.AMOUNT_M) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_M <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.N' ITEM_NUM,
         SUM(T.AMOUNT_N) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_N <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.O' ITEM_NUM,
         SUM(T.AMOUNT_O) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_O <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.P' ITEM_NUM,
         SUM(T.AMOUNT_P) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_P <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.Q' ITEM_NUM,
         SUM(T.AMOUNT_Q) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_Q <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.R' ITEM_NUM,
         SUM(T.AMOUNT_R) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_R <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.S' ITEM_NUM,
         SUM(T.AMOUNT_S) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_S <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.T' ITEM_NUM,
         SUM(T.AMOUNT_T) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_T <> 0
         GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.2.L` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1_1.2.J
INSERT 
    INTO `G33_I_1_1.2.J` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.J'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.J'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.J'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.J'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.J'
       END ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.J'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.J'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.J'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.J'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.J'
                END;

INSERT 
    INTO `G33_I_1_1.2.J` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.J'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.J'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.J'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.J'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.J'
       END ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.J'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.J'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.J'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.J'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.J'
                END;


-- 指标: G33_I_1.3.O
INSERT 
    INTO `G33_I_1.3.O` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.O'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.O'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.O'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.O'
       END ITEM_NUM,
       SUM(T.AMOUNT_O) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO `G33_I_1.3.O` 
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
          COL_7,
          COL_12)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12 --客户号
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          WHERE T1.FLAG = '01' --零售
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

INSERT 
       INTO `G33_I_1.3.O` 
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
          COL_7,
          COL_12,
          COL_13,
          COL_14)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12, --客户号
          T2.M_NAME AS COL_13, --企业规模
          FACILITY_AMT AS COL_14 --授信额度
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          LEFT JOIN A_REPT_DWD_MAPPING T2
            ON T1.CORP_SCALE = T2.M_CODE
            AND T2.M_TABLECODE = 'CORP_SCALE'
          WHERE T1.FLAG = '02' --小微企业授信1000万以下
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       --金融市场部 转贴现
       -- 小型企业：03、微型企业：04
        INSERT 
        INTO `G33_I_1.3.O` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE <= 1 THEN
              'G33_I_1.3.B'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 2 AND 30 THEN
              'G33_I_1.3.C'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 31 AND 90 THEN
              'G33_I_1.3.D'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 91 AND 180 THEN
              'G33_I_1.3.E'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 181 AND 270 THEN
              'G33_I_1.3.F'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 271 AND 360 THEN
              'G33_I_1.3.G'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 361 AND 540 THEN
              'G33_I_1.3.H'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 541 AND 720 THEN
              'G33_I_1.3.I'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 721 AND 1080 THEN
              'G33_I_1.3.J'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1081 AND 1440 THEN
              'G33_I_1.3.K'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1441 AND 1800 THEN
              'G33_I_1.3.L'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
              'G33_I_1.3.M'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
              'G33_I_1.3.N'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
              'G33_I_1.3.O'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
              'G33_I_1.3.P'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
              'G33_I_1.3.Q'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 10 + 1 AND
                  360 * 15 THEN
              'G33_I_1.3.R'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 15 + 1 AND
                  360 * 20 THEN
              'G33_I_1.3.S'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE > 360 * 20 THEN
              'G33_I_1.3.T'
           END AS ITEM_NUM,
           T.LOAN_ACCT_BAL AS TOTAL_VALUE,
           T.LOAN_NUM AS COL1, --贷款编号
           T.CURR_CD AS COL2, --币种
           T.ITEM_CD AS COL3, --科目
           TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYY-MM-DD') AS COL4, --到期日（日期）
           T.ACCT_NUM AS COL6, --贷款合同编号
           NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
           CASE
             WHEN T.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8, --五级分类
           CASE
             WHEN T3.CORP_SIZE = '01' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '02' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '03' THEN
              '小型企业'
             WHEN T3.CORP_SIZE = '04' THEN
              '微型企业'
           END AS COL_13 --企业规模
            FROM CBRC_FDM_LNAC T
           INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                         FROM L_CUST_BILL_TY T
                        WHERE T.DATA_DATE = I_DATADATE) T2
              ON T.CUST_ID = T2.CUST_ID
           INNER JOIN L_CUST_EXTERNAL_INFO T3
              ON T2.LEGAL_TYSHXYDM = T3.USCD
             AND T3.DATA_DATE = I_DATADATE
            LEFT JOIN L_PUBL_RATE TT
              ON TT.DATA_DATE = T.DATA_DATE
             AND TT.BASIC_CCY = T.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
            LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                              MIN(T1.HOLIDAY_DATE) LASTDAY,
                              T.DATA_DATE AS DATADATE
                         FROM L_PUBL_HOLIDAY T
                         LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                     FROM L_PUBL_HOLIDAY T
                                    WHERE T.COUNTRY = 'CHN'
                                      AND T.STATE = '220000'
                                      AND T.WORKING_HOLIDAY = 'W' --工作日
                                   ) T1
                           ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                          AND T.DATA_DATE = T1.DATA_DATE
                        WHERE T.COUNTRY = 'CHN'
                          AND T.STATE = '220000'
                          AND T.WORKING_HOLIDAY = 'H' --假日
                          AND T.HOLIDAY_DATE <= I_DATADATE
                        GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
              ON T.MATURITY_DT = T1.HOLIDAY_DATE
             AND T.DATA_DATE = T1.DATADATE
           WHERE T.DATA_DATE = I_DATADATE
             AND T.ACCT_TYP NOT LIKE '90%'
             AND T.LOAN_ACCT_BAL <> 0
             AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
             AND T3.CORP_SIZE IN ('03', '04');

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

      INSERT 
      INTO `G33_I_1.3.O` 
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
         COL_7,
         COL_12)
        SELECT 
         I_DATADATE,
         T1.ORG_NUM,
         T1.DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
         END AS ITEM_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4' THEN
            NVL(T1.OD_INT, 0)
           WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
            T1.ACCU_INT_AMT
         END AS TOTAL_VALUE, --贷款余额
         T1.LOAN_NUM AS COL1, --贷款编号
         T1.CURR_CD AS COL2, --币种
         T1.ITEM_CD AS COL3, --科目
         T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
         CUST_ID AS COL_12 --客户号
          FROM CBRC_FDM_LNAC_PMT_LX_Q T1
         WHERE T1.FLAG = '01' --零售利息
           AND T1.ORG_NUM <> '009804'
           AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

INSERT 
        INTO `G33_I_1.3.O` 
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
           COL_7,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
          END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           T1.CUST_ID AS COL_12, --客户号
           T2.M_NAME AS COL_13, --企业规模
           T1.FACILITY_AMT COL_14 --授信额度
            FROM CBRC_FDM_LNAC_PMT_LX_Q T1
            LEFT JOIN A_REPT_DWD_MAPPING T2
              ON T1.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T1.FLAG = '02' --小微企业1000万以下利息
             AND T1.ORG_NUM <> '009804'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.1.3.1.I
INSERT 
    INTO `G33_I_1.1.3.1.I` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.I'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.I'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.I'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.I'
       END ITEM_NUM,
       SUM(T.AMOUNT_I) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

INSERT 
           INTO `G33_I_1.1.3.1.I` 
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
              COL_10)
             SELECT 
             I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.1.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.1.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
               FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '1'
                AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
                AND T1.NEXT_PAYMENT <>0;

INSERT 
           INTO `G33_I_1.1.3.1.I` 
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
              COL_11)
             SELECT 
             I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.1.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.1.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL11--下一利率重定价日
               FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '3'
                AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
                AND T1.NEXT_PAYMENT <>0;

INSERT 
       INTO `G33_I_1.1.3.1.I` 
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
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.1.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.1.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
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
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
            AND T1.NEXT_PAYMENT <>0;

INSERT 
        INTO `G33_I_1.1.3.1.I` 
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
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.1.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.1.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.1.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM cbrc_fdm_lnac_pmt_lx T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.1.I` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.4.J
INSERT 
    INTO `G33_I_1.4.J` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.J'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.J'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.J'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.J'
       END ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

       -- 大型企业：01、中型企业
       INSERT 
       INTO `G33_I_1.4.J` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
         SELECT 
          I_DATADATE,
          T.ORG_NUM,
          T.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE <= 1 THEN
             'G33_I_1.4.B'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 2 AND 30 THEN
             'G33_I_1.4.C'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 31 AND 90 THEN
             'G33_I_1.4.D'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 91 AND 180 THEN
             'G33_I_1.4.E'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 181 AND 270 THEN
             'G33_I_1.4.F'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 271 AND 360 THEN
             'G33_I_1.4.G'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 361 AND 540 THEN
             'G33_I_1.4.H'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 541 AND 720 THEN
             'G33_I_1.4.I'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 721 AND 1080 THEN
             'G33_I_1.4.J'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1081 AND 1440 THEN
             'G33_I_1.4.K'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1441 AND 1800 THEN
             'G33_I_1.4.L'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
             'G33_I_1.4.M'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
             'G33_I_1.4.N'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
             'G33_I_1.4.O'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
             'G33_I_1.4.P'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
             'G33_I_1.4.Q'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
             'G33_I_1.4.R'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
             'G33_I_1.4.S'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE > 360 * 20 THEN
             'G33_I_1.4.T'
          END AS ITEM_NUM,
          T.LOAN_ACCT_BAL AS TOTAL_VALUE,
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYYMMDD') AS COL4, --到期日（日期）
          T.ACCT_NUM AS COL6, --贷款合同编号
          NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
          CASE
            WHEN T.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T3.CORP_SIZE = '01' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '02' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '03' THEN
             '小型企业'
            WHEN T3.CORP_SIZE = '04' THEN
             '微型企业'
          END AS COL_13 --企业规模
           FROM CBRC_FDM_LNAC T
          INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                        FROM L_CUST_BILL_TY T
                       WHERE T.DATA_DATE = I_DATADATE) T2
             ON T.CUST_ID = T2.CUST_ID
          INNER JOIN L_CUST_EXTERNAL_INFO T3
             ON T2.LEGAL_TYSHXYDM = T3.USCD
            AND T3.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                             MIN(T1.HOLIDAY_DATE) LASTDAY,
                             T.DATA_DATE AS DATADATE
                        FROM L_PUBL_HOLIDAY T
                        LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                    FROM L_PUBL_HOLIDAY T
                                   WHERE T.COUNTRY = 'CHN'
                                     AND T.STATE = '220000'
                                     AND T.WORKING_HOLIDAY = 'W' --工作日
                                  ) T1
                          ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                         AND T.DATA_DATE = T1.DATA_DATE
                       WHERE T.COUNTRY = 'CHN'
                         AND T.STATE = '220000'
                         AND T.WORKING_HOLIDAY = 'H' --假日
                         AND T.HOLIDAY_DATE <= I_DATADATE
                       GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
             ON T.MATURITY_DT = T1.HOLIDAY_DATE
            AND T.DATA_DATE = T1.DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
            AND T3.CORP_SIZE IN ('01', '02');

--===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    -- 1.3 具备提前还款权的固定利率批发类贷款
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.J` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                  (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '1') or
                  (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN cbrc_fdm_lnac_pmt_bj_q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有本金数据
             AND T.CURR_CD = 'CNY'
             AND T.ORG_NUM <> '009804'
             AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.J` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN cbrc_fdm_lnac_pmt_lx T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN CBRC_FDM_LNAC_PMT_LX_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有利息数据
             AND T.CURR_CD = 'CNY'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.3.K
INSERT 
    INTO `G33_I_1.3.K` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.K'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.K'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.K'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.K'
       END ITEM_NUM,
       SUM(T.AMOUNT_K) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO `G33_I_1.3.K` 
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
          COL_7,
          COL_12)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12 --客户号
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          WHERE T1.FLAG = '01' --零售
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

INSERT 
       INTO `G33_I_1.3.K` 
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
          COL_7,
          COL_12,
          COL_13,
          COL_14)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12, --客户号
          T2.M_NAME AS COL_13, --企业规模
          FACILITY_AMT AS COL_14 --授信额度
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          LEFT JOIN A_REPT_DWD_MAPPING T2
            ON T1.CORP_SCALE = T2.M_CODE
            AND T2.M_TABLECODE = 'CORP_SCALE'
          WHERE T1.FLAG = '02' --小微企业授信1000万以下
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       --金融市场部 转贴现
       -- 小型企业：03、微型企业：04
        INSERT 
        INTO `G33_I_1.3.K` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE <= 1 THEN
              'G33_I_1.3.B'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 2 AND 30 THEN
              'G33_I_1.3.C'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 31 AND 90 THEN
              'G33_I_1.3.D'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 91 AND 180 THEN
              'G33_I_1.3.E'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 181 AND 270 THEN
              'G33_I_1.3.F'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 271 AND 360 THEN
              'G33_I_1.3.G'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 361 AND 540 THEN
              'G33_I_1.3.H'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 541 AND 720 THEN
              'G33_I_1.3.I'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 721 AND 1080 THEN
              'G33_I_1.3.J'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1081 AND 1440 THEN
              'G33_I_1.3.K'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1441 AND 1800 THEN
              'G33_I_1.3.L'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
              'G33_I_1.3.M'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
              'G33_I_1.3.N'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
              'G33_I_1.3.O'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
              'G33_I_1.3.P'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
              'G33_I_1.3.Q'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 10 + 1 AND
                  360 * 15 THEN
              'G33_I_1.3.R'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 15 + 1 AND
                  360 * 20 THEN
              'G33_I_1.3.S'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE > 360 * 20 THEN
              'G33_I_1.3.T'
           END AS ITEM_NUM,
           T.LOAN_ACCT_BAL AS TOTAL_VALUE,
           T.LOAN_NUM AS COL1, --贷款编号
           T.CURR_CD AS COL2, --币种
           T.ITEM_CD AS COL3, --科目
           TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYY-MM-DD') AS COL4, --到期日（日期）
           T.ACCT_NUM AS COL6, --贷款合同编号
           NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
           CASE
             WHEN T.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8, --五级分类
           CASE
             WHEN T3.CORP_SIZE = '01' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '02' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '03' THEN
              '小型企业'
             WHEN T3.CORP_SIZE = '04' THEN
              '微型企业'
           END AS COL_13 --企业规模
            FROM CBRC_FDM_LNAC T
           INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                         FROM L_CUST_BILL_TY T
                        WHERE T.DATA_DATE = I_DATADATE) T2
              ON T.CUST_ID = T2.CUST_ID
           INNER JOIN L_CUST_EXTERNAL_INFO T3
              ON T2.LEGAL_TYSHXYDM = T3.USCD
             AND T3.DATA_DATE = I_DATADATE
            LEFT JOIN L_PUBL_RATE TT
              ON TT.DATA_DATE = T.DATA_DATE
             AND TT.BASIC_CCY = T.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
            LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                              MIN(T1.HOLIDAY_DATE) LASTDAY,
                              T.DATA_DATE AS DATADATE
                         FROM L_PUBL_HOLIDAY T
                         LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                     FROM L_PUBL_HOLIDAY T
                                    WHERE T.COUNTRY = 'CHN'
                                      AND T.STATE = '220000'
                                      AND T.WORKING_HOLIDAY = 'W' --工作日
                                   ) T1
                           ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                          AND T.DATA_DATE = T1.DATA_DATE
                        WHERE T.COUNTRY = 'CHN'
                          AND T.STATE = '220000'
                          AND T.WORKING_HOLIDAY = 'H' --假日
                          AND T.HOLIDAY_DATE <= I_DATADATE
                        GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
              ON T.MATURITY_DT = T1.HOLIDAY_DATE
             AND T.DATA_DATE = T1.DATADATE
           WHERE T.DATA_DATE = I_DATADATE
             AND T.ACCT_TYP NOT LIKE '90%'
             AND T.LOAN_ACCT_BAL <> 0
             AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
             AND T3.CORP_SIZE IN ('03', '04');

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

      INSERT 
      INTO `G33_I_1.3.K` 
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
         COL_7,
         COL_12)
        SELECT 
         I_DATADATE,
         T1.ORG_NUM,
         T1.DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
         END AS ITEM_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4' THEN
            NVL(T1.OD_INT, 0)
           WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
            T1.ACCU_INT_AMT
         END AS TOTAL_VALUE, --贷款余额
         T1.LOAN_NUM AS COL1, --贷款编号
         T1.CURR_CD AS COL2, --币种
         T1.ITEM_CD AS COL3, --科目
         T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
         CUST_ID AS COL_12 --客户号
          FROM CBRC_FDM_LNAC_PMT_LX_Q T1
         WHERE T1.FLAG = '01' --零售利息
           AND T1.ORG_NUM <> '009804'
           AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

INSERT 
        INTO `G33_I_1.3.K` 
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
           COL_7,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
          END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           T1.CUST_ID AS COL_12, --客户号
           T2.M_NAME AS COL_13, --企业规模
           T1.FACILITY_AMT COL_14 --授信额度
            FROM CBRC_FDM_LNAC_PMT_LX_Q T1
            LEFT JOIN A_REPT_DWD_MAPPING T2
              ON T1.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T1.FLAG = '02' --小微企业1000万以下利息
             AND T1.ORG_NUM <> '009804'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.4.D
INSERT 
    INTO `G33_I_1.4.D` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.D'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.D'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.D'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.D'
       END ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

       -- 大型企业：01、中型企业
       INSERT 
       INTO `G33_I_1.4.D` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
         SELECT 
          I_DATADATE,
          T.ORG_NUM,
          T.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE <= 1 THEN
             'G33_I_1.4.B'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 2 AND 30 THEN
             'G33_I_1.4.C'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 31 AND 90 THEN
             'G33_I_1.4.D'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 91 AND 180 THEN
             'G33_I_1.4.E'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 181 AND 270 THEN
             'G33_I_1.4.F'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 271 AND 360 THEN
             'G33_I_1.4.G'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 361 AND 540 THEN
             'G33_I_1.4.H'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 541 AND 720 THEN
             'G33_I_1.4.I'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 721 AND 1080 THEN
             'G33_I_1.4.J'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1081 AND 1440 THEN
             'G33_I_1.4.K'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1441 AND 1800 THEN
             'G33_I_1.4.L'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
             'G33_I_1.4.M'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
             'G33_I_1.4.N'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
             'G33_I_1.4.O'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
             'G33_I_1.4.P'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
             'G33_I_1.4.Q'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
             'G33_I_1.4.R'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
             'G33_I_1.4.S'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE > 360 * 20 THEN
             'G33_I_1.4.T'
          END AS ITEM_NUM,
          T.LOAN_ACCT_BAL AS TOTAL_VALUE,
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYYMMDD') AS COL4, --到期日（日期）
          T.ACCT_NUM AS COL6, --贷款合同编号
          NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
          CASE
            WHEN T.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T3.CORP_SIZE = '01' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '02' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '03' THEN
             '小型企业'
            WHEN T3.CORP_SIZE = '04' THEN
             '微型企业'
          END AS COL_13 --企业规模
           FROM CBRC_FDM_LNAC T
          INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                        FROM L_CUST_BILL_TY T
                       WHERE T.DATA_DATE = I_DATADATE) T2
             ON T.CUST_ID = T2.CUST_ID
          INNER JOIN L_CUST_EXTERNAL_INFO T3
             ON T2.LEGAL_TYSHXYDM = T3.USCD
            AND T3.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                             MIN(T1.HOLIDAY_DATE) LASTDAY,
                             T.DATA_DATE AS DATADATE
                        FROM L_PUBL_HOLIDAY T
                        LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                    FROM L_PUBL_HOLIDAY T
                                   WHERE T.COUNTRY = 'CHN'
                                     AND T.STATE = '220000'
                                     AND T.WORKING_HOLIDAY = 'W' --工作日
                                  ) T1
                          ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                         AND T.DATA_DATE = T1.DATA_DATE
                       WHERE T.COUNTRY = 'CHN'
                         AND T.STATE = '220000'
                         AND T.WORKING_HOLIDAY = 'H' --假日
                         AND T.HOLIDAY_DATE <= I_DATADATE
                       GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
             ON T.MATURITY_DT = T1.HOLIDAY_DATE
            AND T.DATA_DATE = T1.DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
            AND T3.CORP_SIZE IN ('01', '02');

--===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    -- 1.3 具备提前还款权的固定利率批发类贷款
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.D` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                  (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '1') or
                  (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN cbrc_fdm_lnac_pmt_bj_q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有本金数据
             AND T.CURR_CD = 'CNY'
             AND T.ORG_NUM <> '009804'
             AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.D` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN cbrc_fdm_lnac_pmt_lx T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN CBRC_FDM_LNAC_PMT_LX_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有利息数据
             AND T.CURR_CD = 'CNY'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.1.3.M
INSERT 
    INTO `G33_I_1.1.3.M` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_I_1.1.3.M' ITEM_NUM,
       SUM(T.AMOUNT_M) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.1.3.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.M` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.4.H
INSERT 
    INTO `G33_I_1.4.H` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.H'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.H'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.H'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.H'
       END ITEM_NUM,
       SUM(T.AMOUNT_H) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

       -- 大型企业：01、中型企业
       INSERT 
       INTO `G33_I_1.4.H` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
         SELECT 
          I_DATADATE,
          T.ORG_NUM,
          T.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE <= 1 THEN
             'G33_I_1.4.B'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 2 AND 30 THEN
             'G33_I_1.4.C'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 31 AND 90 THEN
             'G33_I_1.4.D'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 91 AND 180 THEN
             'G33_I_1.4.E'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 181 AND 270 THEN
             'G33_I_1.4.F'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 271 AND 360 THEN
             'G33_I_1.4.G'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 361 AND 540 THEN
             'G33_I_1.4.H'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 541 AND 720 THEN
             'G33_I_1.4.I'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 721 AND 1080 THEN
             'G33_I_1.4.J'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1081 AND 1440 THEN
             'G33_I_1.4.K'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1441 AND 1800 THEN
             'G33_I_1.4.L'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
             'G33_I_1.4.M'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
             'G33_I_1.4.N'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
             'G33_I_1.4.O'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
             'G33_I_1.4.P'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
             'G33_I_1.4.Q'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
             'G33_I_1.4.R'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
             'G33_I_1.4.S'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE > 360 * 20 THEN
             'G33_I_1.4.T'
          END AS ITEM_NUM,
          T.LOAN_ACCT_BAL AS TOTAL_VALUE,
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYYMMDD') AS COL4, --到期日（日期）
          T.ACCT_NUM AS COL6, --贷款合同编号
          NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
          CASE
            WHEN T.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T3.CORP_SIZE = '01' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '02' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '03' THEN
             '小型企业'
            WHEN T3.CORP_SIZE = '04' THEN
             '微型企业'
          END AS COL_13 --企业规模
           FROM CBRC_FDM_LNAC T
          INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                        FROM L_CUST_BILL_TY T
                       WHERE T.DATA_DATE = I_DATADATE) T2
             ON T.CUST_ID = T2.CUST_ID
          INNER JOIN L_CUST_EXTERNAL_INFO T3
             ON T2.LEGAL_TYSHXYDM = T3.USCD
            AND T3.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                             MIN(T1.HOLIDAY_DATE) LASTDAY,
                             T.DATA_DATE AS DATADATE
                        FROM L_PUBL_HOLIDAY T
                        LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                    FROM L_PUBL_HOLIDAY T
                                   WHERE T.COUNTRY = 'CHN'
                                     AND T.STATE = '220000'
                                     AND T.WORKING_HOLIDAY = 'W' --工作日
                                  ) T1
                          ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                         AND T.DATA_DATE = T1.DATA_DATE
                       WHERE T.COUNTRY = 'CHN'
                         AND T.STATE = '220000'
                         AND T.WORKING_HOLIDAY = 'H' --假日
                         AND T.HOLIDAY_DATE <= I_DATADATE
                       GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
             ON T.MATURITY_DT = T1.HOLIDAY_DATE
            AND T.DATA_DATE = T1.DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
            AND T3.CORP_SIZE IN ('01', '02');

--===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    -- 1.3 具备提前还款权的固定利率批发类贷款
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.H` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                  (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '1') or
                  (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN cbrc_fdm_lnac_pmt_bj_q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有本金数据
             AND T.CURR_CD = 'CNY'
             AND T.ORG_NUM <> '009804'
             AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.H` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN cbrc_fdm_lnac_pmt_lx T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN CBRC_FDM_LNAC_PMT_LX_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有利息数据
             AND T.CURR_CD = 'CNY'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.1.3.B
--总项指标汇总：1.1.3 贷款
    INSERT 
    INTO `G33_I_1.1.3.B` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_I_1.1.3.B' ITEM_NUM,
       SUM(T.AMOUNT_B) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.1.3.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.B` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.4.B
--分项指标转换
    /* 1.1.3.1 其中：以贷款市场报价利率（LPR）为定价基础的人民币浮动利率贷款
    1.1.3.2 其中：以人民银行基准利率为定价基础的浮动利率贷款
    1.2 具备提前还款权的固定利率零售类贷款
    1.3 具备提前还款权的固定利率批发类贷款*/
    INSERT 
    INTO `G33_I_1.4.B` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.B'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.B'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.B'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.B'
       END ITEM_NUM,
       SUM(T.AMOUNT_B) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

       -- 大型企业：01、中型企业
       INSERT 
       INTO `G33_I_1.4.B` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
         SELECT 
          I_DATADATE,
          T.ORG_NUM,
          T.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE <= 1 THEN
             'G33_I_1.4.B'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 2 AND 30 THEN
             'G33_I_1.4.C'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 31 AND 90 THEN
             'G33_I_1.4.D'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 91 AND 180 THEN
             'G33_I_1.4.E'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 181 AND 270 THEN
             'G33_I_1.4.F'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 271 AND 360 THEN
             'G33_I_1.4.G'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 361 AND 540 THEN
             'G33_I_1.4.H'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 541 AND 720 THEN
             'G33_I_1.4.I'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 721 AND 1080 THEN
             'G33_I_1.4.J'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1081 AND 1440 THEN
             'G33_I_1.4.K'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1441 AND 1800 THEN
             'G33_I_1.4.L'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
             'G33_I_1.4.M'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
             'G33_I_1.4.N'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
             'G33_I_1.4.O'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
             'G33_I_1.4.P'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
             'G33_I_1.4.Q'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
             'G33_I_1.4.R'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
             'G33_I_1.4.S'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE > 360 * 20 THEN
             'G33_I_1.4.T'
          END AS ITEM_NUM,
          T.LOAN_ACCT_BAL AS TOTAL_VALUE,
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYYMMDD') AS COL4, --到期日（日期）
          T.ACCT_NUM AS COL6, --贷款合同编号
          NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
          CASE
            WHEN T.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T3.CORP_SIZE = '01' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '02' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '03' THEN
             '小型企业'
            WHEN T3.CORP_SIZE = '04' THEN
             '微型企业'
          END AS COL_13 --企业规模
           FROM CBRC_FDM_LNAC T
          INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                        FROM L_CUST_BILL_TY T
                       WHERE T.DATA_DATE = I_DATADATE) T2
             ON T.CUST_ID = T2.CUST_ID
          INNER JOIN L_CUST_EXTERNAL_INFO T3
             ON T2.LEGAL_TYSHXYDM = T3.USCD
            AND T3.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                             MIN(T1.HOLIDAY_DATE) LASTDAY,
                             T.DATA_DATE AS DATADATE
                        FROM L_PUBL_HOLIDAY T
                        LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                    FROM L_PUBL_HOLIDAY T
                                   WHERE T.COUNTRY = 'CHN'
                                     AND T.STATE = '220000'
                                     AND T.WORKING_HOLIDAY = 'W' --工作日
                                  ) T1
                          ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                         AND T.DATA_DATE = T1.DATA_DATE
                       WHERE T.COUNTRY = 'CHN'
                         AND T.STATE = '220000'
                         AND T.WORKING_HOLIDAY = 'H' --假日
                         AND T.HOLIDAY_DATE <= I_DATADATE
                       GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
             ON T.MATURITY_DT = T1.HOLIDAY_DATE
            AND T.DATA_DATE = T1.DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
            AND T3.CORP_SIZE IN ('01', '02');

--===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    -- 1.3 具备提前还款权的固定利率批发类贷款
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.B` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                  (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '1') or
                  (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN cbrc_fdm_lnac_pmt_bj_q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有本金数据
             AND T.CURR_CD = 'CNY'
             AND T.ORG_NUM <> '009804'
             AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.B` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN cbrc_fdm_lnac_pmt_lx T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN CBRC_FDM_LNAC_PMT_LX_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有利息数据
             AND T.CURR_CD = 'CNY'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.1.3.2.H
INSERT 
    INTO `G33_I_1.1.3.2.H` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.H'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.H'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.H'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.H'
       END ITEM_NUM,
       SUM(T.AMOUNT_H) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO `G33_I_1.1.3.2.H` 
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
                COL_10)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
                 FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '1'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账'))--add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO `G33_I_1.1.3.2.H` 
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
                COL_11)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD')  AS COL_11--下一利率重定价日
                 FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '3'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;

----------------------------------按照正常重定价日处理
   -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO `G33_I_1.1.3.2.H` 
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
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.2.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.2.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.1.3.2.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
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
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND (T1.BENM_INRAT_TYPE = 'A' OR
                (T1.BENM_INRAT_TYPE = '#' AND
                T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
            AND T1.NEXT_PAYMENT <>0;

--133应收利息  应计利息+应收利息
    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.1.3.2.H` 
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
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.2.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.2.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.2.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM cbrc_fdm_lnac_pmt_lx T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND (T1.BENM_INRAT_TYPE = 'A' OR
                 (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --分项指标转换   此处插入利息轧差项目，其他在A_REPT_DWD_G3301明细中处理
    /* 1.1.3.1 其中：以贷款市场报价利率（LPR）为定价基础的人民币浮动利率贷款
    1.1.3.2 其中：以人民银行基准利率为定价基础的浮动利率贷款
    1.2 具备提前还款权的固定利率零售类贷款
    1.3 具备提前还款权的固定利率批发类贷款*/
      INSERT 
      INTO `G33_I_1.1.3.2.H` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE)
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.B' ITEM_NUM,
         SUM(T.AMOUNT_B) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_B <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.C' ITEM_NUM,
         SUM(T.AMOUNT_C) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_C <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.D' ITEM_NUM,
         SUM(T.AMOUNT_D) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_D <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.E' ITEM_NUM,
         SUM(T.AMOUNT_E) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_E <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.F' ITEM_NUM,
         SUM(T.AMOUNT_F) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_F <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.G' ITEM_NUM,
         SUM(T.AMOUNT_G) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_G <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.H' ITEM_NUM,
         SUM(T.AMOUNT_H) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_H <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.I' ITEM_NUM,
         SUM(T.AMOUNT_I) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_I <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.J' ITEM_NUM,
         SUM(T.AMOUNT_J) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_J <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.K' ITEM_NUM,
         SUM(T.AMOUNT_K) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_K <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.L' ITEM_NUM,
         SUM(T.AMOUNT_L) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_L <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.M' ITEM_NUM,
         SUM(T.AMOUNT_M) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_M <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.N' ITEM_NUM,
         SUM(T.AMOUNT_N) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_N <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.O' ITEM_NUM,
         SUM(T.AMOUNT_O) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_O <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.P' ITEM_NUM,
         SUM(T.AMOUNT_P) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_P <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.Q' ITEM_NUM,
         SUM(T.AMOUNT_Q) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_Q <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.R' ITEM_NUM,
         SUM(T.AMOUNT_R) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_R <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.S' ITEM_NUM,
         SUM(T.AMOUNT_S) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_S <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.T' ITEM_NUM,
         SUM(T.AMOUNT_T) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_T <> 0
         GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.2.H` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.1.3.L
INSERT 
    INTO `G33_I_1.1.3.L` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_I_1.1.3.L' ITEM_NUM,
       SUM(T.AMOUNT_L) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.1.3.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.L` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.1.3.J
INSERT 
    INTO `G33_I_1.1.3.J` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_I_1.1.3.J' ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.1.3.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.J` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_1_2.3.B.2019
--2.3 可提前支取的定期零售类存款
   INSERT 
    INTO `G33_1_2.3.B.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.B.2019' ITEM_NUM,
       SUM(T.AMOUNT_B) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

--2.3 可提前支取的定期零售类存款
   INSERT 
    INTO `G33_1_2.3.B.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.3.B.2019' ITEM_NUM,
       SUM(T.AMOUNT_B) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.3'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_1_2.1.3.1.B.2019
--2.1.3 定期存款 =2.1.3.1 其中：以人民银行基准利率为定价基础的存款
   INSERT 
    INTO `G33_1_2.1.3.1.B.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.B.2019' ITEM_NUM,
       SUM(T.AMOUNT_B) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

--2.1.3 定期存款 =2.1.3.1 其中：以人民银行基准利率为定价基础的存款
   INSERT 
    INTO `G33_1_2.1.3.1.B.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.B.2019' ITEM_NUM,
       SUM(T.AMOUNT_B) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_I_1.4.K
INSERT 
    INTO `G33_I_1.4.K` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.K'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.K'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.K'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.K'
       END ITEM_NUM,
       SUM(T.AMOUNT_K) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

       -- 大型企业：01、中型企业
       INSERT 
       INTO `G33_I_1.4.K` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
         SELECT 
          I_DATADATE,
          T.ORG_NUM,
          T.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE <= 1 THEN
             'G33_I_1.4.B'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 2 AND 30 THEN
             'G33_I_1.4.C'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 31 AND 90 THEN
             'G33_I_1.4.D'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 91 AND 180 THEN
             'G33_I_1.4.E'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 181 AND 270 THEN
             'G33_I_1.4.F'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 271 AND 360 THEN
             'G33_I_1.4.G'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 361 AND 540 THEN
             'G33_I_1.4.H'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 541 AND 720 THEN
             'G33_I_1.4.I'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 721 AND 1080 THEN
             'G33_I_1.4.J'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1081 AND 1440 THEN
             'G33_I_1.4.K'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1441 AND 1800 THEN
             'G33_I_1.4.L'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
             'G33_I_1.4.M'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
             'G33_I_1.4.N'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
             'G33_I_1.4.O'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
             'G33_I_1.4.P'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
             'G33_I_1.4.Q'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
             'G33_I_1.4.R'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
             'G33_I_1.4.S'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE > 360 * 20 THEN
             'G33_I_1.4.T'
          END AS ITEM_NUM,
          T.LOAN_ACCT_BAL AS TOTAL_VALUE,
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYYMMDD') AS COL4, --到期日（日期）
          T.ACCT_NUM AS COL6, --贷款合同编号
          NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
          CASE
            WHEN T.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T3.CORP_SIZE = '01' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '02' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '03' THEN
             '小型企业'
            WHEN T3.CORP_SIZE = '04' THEN
             '微型企业'
          END AS COL_13 --企业规模
           FROM CBRC_FDM_LNAC T
          INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                        FROM L_CUST_BILL_TY T
                       WHERE T.DATA_DATE = I_DATADATE) T2
             ON T.CUST_ID = T2.CUST_ID
          INNER JOIN L_CUST_EXTERNAL_INFO T3
             ON T2.LEGAL_TYSHXYDM = T3.USCD
            AND T3.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                             MIN(T1.HOLIDAY_DATE) LASTDAY,
                             T.DATA_DATE AS DATADATE
                        FROM L_PUBL_HOLIDAY T
                        LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                    FROM L_PUBL_HOLIDAY T
                                   WHERE T.COUNTRY = 'CHN'
                                     AND T.STATE = '220000'
                                     AND T.WORKING_HOLIDAY = 'W' --工作日
                                  ) T1
                          ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                         AND T.DATA_DATE = T1.DATA_DATE
                       WHERE T.COUNTRY = 'CHN'
                         AND T.STATE = '220000'
                         AND T.WORKING_HOLIDAY = 'H' --假日
                         AND T.HOLIDAY_DATE <= I_DATADATE
                       GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
             ON T.MATURITY_DT = T1.HOLIDAY_DATE
            AND T.DATA_DATE = T1.DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
            AND T3.CORP_SIZE IN ('01', '02');

--===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    -- 1.3 具备提前还款权的固定利率批发类贷款
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.K` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                  (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '1') or
                  (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN cbrc_fdm_lnac_pmt_bj_q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有本金数据
             AND T.CURR_CD = 'CNY'
             AND T.ORG_NUM <> '009804'
             AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.K` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN cbrc_fdm_lnac_pmt_lx T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN CBRC_FDM_LNAC_PMT_LX_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有利息数据
             AND T.CURR_CD = 'CNY'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_1_2.4.C.2019
INSERT 
    INTO `G33_1_2.4.C.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.C.2019' ITEM_NUM,
       SUM(T.AMOUNT_C) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.4.C.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.4.C.2019' ITEM_NUM,
       SUM(T.AMOUNT_C) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.4'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_1_2.1.3.1.J.2019
INSERT 
    INTO `G33_1_2.1.3.1.J.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.J.2019' ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.1.3.1.J.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.1.J.2019' ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_1_2.1.3.D.2019
INSERT 
    INTO `G33_1_2.1.3.D.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.D.2019' ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.1.3.D.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.3.D.2019' ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.3.1'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


-- 指标: G33_I_1.1.3.1.H
INSERT 
    INTO `G33_I_1.1.3.1.H` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.H'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.H'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.H'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.H'
       END ITEM_NUM,
       SUM(T.AMOUNT_H) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

INSERT 
           INTO `G33_I_1.1.3.1.H` 
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
              COL_10)
             SELECT 
             I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.1.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.1.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
               FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '1'
                AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
                AND T1.NEXT_PAYMENT <>0;

INSERT 
           INTO `G33_I_1.1.3.1.H` 
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
              COL_11)
             SELECT 
             I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.1.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.1.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL11--下一利率重定价日
               FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '3'
                AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
                AND T1.NEXT_PAYMENT <>0;

INSERT 
       INTO `G33_I_1.1.3.1.H` 
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
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.1.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.1.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
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
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
            AND T1.NEXT_PAYMENT <>0;

INSERT 
        INTO `G33_I_1.1.3.1.H` 
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
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.1.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.1.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.1.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM cbrc_fdm_lnac_pmt_lx T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.1.H` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.1.3.C
INSERT 
    INTO `G33_I_1.1.3.C` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_I_1.1.3.C' ITEM_NUM,
       SUM(T.AMOUNT_C) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.1.3.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.C` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.4.C
INSERT 
    INTO `G33_I_1.4.C` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.C'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.C'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.C'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.C'
       END ITEM_NUM,
       SUM(T.AMOUNT_C) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

       -- 大型企业：01、中型企业
       INSERT 
       INTO `G33_I_1.4.C` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
         SELECT 
          I_DATADATE,
          T.ORG_NUM,
          T.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE <= 1 THEN
             'G33_I_1.4.B'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 2 AND 30 THEN
             'G33_I_1.4.C'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 31 AND 90 THEN
             'G33_I_1.4.D'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 91 AND 180 THEN
             'G33_I_1.4.E'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 181 AND 270 THEN
             'G33_I_1.4.F'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 271 AND 360 THEN
             'G33_I_1.4.G'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 361 AND 540 THEN
             'G33_I_1.4.H'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 541 AND 720 THEN
             'G33_I_1.4.I'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 721 AND 1080 THEN
             'G33_I_1.4.J'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1081 AND 1440 THEN
             'G33_I_1.4.K'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1441 AND 1800 THEN
             'G33_I_1.4.L'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
             'G33_I_1.4.M'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
             'G33_I_1.4.N'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
             'G33_I_1.4.O'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
             'G33_I_1.4.P'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
             'G33_I_1.4.Q'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
             'G33_I_1.4.R'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
             'G33_I_1.4.S'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE > 360 * 20 THEN
             'G33_I_1.4.T'
          END AS ITEM_NUM,
          T.LOAN_ACCT_BAL AS TOTAL_VALUE,
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYYMMDD') AS COL4, --到期日（日期）
          T.ACCT_NUM AS COL6, --贷款合同编号
          NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
          CASE
            WHEN T.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T3.CORP_SIZE = '01' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '02' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '03' THEN
             '小型企业'
            WHEN T3.CORP_SIZE = '04' THEN
             '微型企业'
          END AS COL_13 --企业规模
           FROM CBRC_FDM_LNAC T
          INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                        FROM L_CUST_BILL_TY T
                       WHERE T.DATA_DATE = I_DATADATE) T2
             ON T.CUST_ID = T2.CUST_ID
          INNER JOIN L_CUST_EXTERNAL_INFO T3
             ON T2.LEGAL_TYSHXYDM = T3.USCD
            AND T3.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                             MIN(T1.HOLIDAY_DATE) LASTDAY,
                             T.DATA_DATE AS DATADATE
                        FROM L_PUBL_HOLIDAY T
                        LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                    FROM L_PUBL_HOLIDAY T
                                   WHERE T.COUNTRY = 'CHN'
                                     AND T.STATE = '220000'
                                     AND T.WORKING_HOLIDAY = 'W' --工作日
                                  ) T1
                          ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                         AND T.DATA_DATE = T1.DATA_DATE
                       WHERE T.COUNTRY = 'CHN'
                         AND T.STATE = '220000'
                         AND T.WORKING_HOLIDAY = 'H' --假日
                         AND T.HOLIDAY_DATE <= I_DATADATE
                       GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
             ON T.MATURITY_DT = T1.HOLIDAY_DATE
            AND T.DATA_DATE = T1.DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
            AND T3.CORP_SIZE IN ('01', '02');

--===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    -- 1.3 具备提前还款权的固定利率批发类贷款
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.C` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                  (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '1') or
                  (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN cbrc_fdm_lnac_pmt_bj_q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有本金数据
             AND T.CURR_CD = 'CNY'
             AND T.ORG_NUM <> '009804'
             AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.C` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN cbrc_fdm_lnac_pmt_lx T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN CBRC_FDM_LNAC_PMT_LX_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有利息数据
             AND T.CURR_CD = 'CNY'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.4.P
INSERT 
    INTO `G33_I_1.4.P` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.P'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.P'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.P'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.P'
       END ITEM_NUM,
       SUM(T.AMOUNT_P) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

       -- 大型企业：01、中型企业
       INSERT 
       INTO `G33_I_1.4.P` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
         SELECT 
          I_DATADATE,
          T.ORG_NUM,
          T.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE <= 1 THEN
             'G33_I_1.4.B'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 2 AND 30 THEN
             'G33_I_1.4.C'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 31 AND 90 THEN
             'G33_I_1.4.D'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 91 AND 180 THEN
             'G33_I_1.4.E'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 181 AND 270 THEN
             'G33_I_1.4.F'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 271 AND 360 THEN
             'G33_I_1.4.G'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 361 AND 540 THEN
             'G33_I_1.4.H'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 541 AND 720 THEN
             'G33_I_1.4.I'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 721 AND 1080 THEN
             'G33_I_1.4.J'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1081 AND 1440 THEN
             'G33_I_1.4.K'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1441 AND 1800 THEN
             'G33_I_1.4.L'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
             'G33_I_1.4.M'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
             'G33_I_1.4.N'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
             'G33_I_1.4.O'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
             'G33_I_1.4.P'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
             'G33_I_1.4.Q'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
             'G33_I_1.4.R'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
             'G33_I_1.4.S'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE > 360 * 20 THEN
             'G33_I_1.4.T'
          END AS ITEM_NUM,
          T.LOAN_ACCT_BAL AS TOTAL_VALUE,
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYYMMDD') AS COL4, --到期日（日期）
          T.ACCT_NUM AS COL6, --贷款合同编号
          NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
          CASE
            WHEN T.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T3.CORP_SIZE = '01' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '02' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '03' THEN
             '小型企业'
            WHEN T3.CORP_SIZE = '04' THEN
             '微型企业'
          END AS COL_13 --企业规模
           FROM CBRC_FDM_LNAC T
          INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                        FROM L_CUST_BILL_TY T
                       WHERE T.DATA_DATE = I_DATADATE) T2
             ON T.CUST_ID = T2.CUST_ID
          INNER JOIN L_CUST_EXTERNAL_INFO T3
             ON T2.LEGAL_TYSHXYDM = T3.USCD
            AND T3.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                             MIN(T1.HOLIDAY_DATE) LASTDAY,
                             T.DATA_DATE AS DATADATE
                        FROM L_PUBL_HOLIDAY T
                        LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                    FROM L_PUBL_HOLIDAY T
                                   WHERE T.COUNTRY = 'CHN'
                                     AND T.STATE = '220000'
                                     AND T.WORKING_HOLIDAY = 'W' --工作日
                                  ) T1
                          ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                         AND T.DATA_DATE = T1.DATA_DATE
                       WHERE T.COUNTRY = 'CHN'
                         AND T.STATE = '220000'
                         AND T.WORKING_HOLIDAY = 'H' --假日
                         AND T.HOLIDAY_DATE <= I_DATADATE
                       GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
             ON T.MATURITY_DT = T1.HOLIDAY_DATE
            AND T.DATA_DATE = T1.DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
            AND T3.CORP_SIZE IN ('01', '02');

--===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    -- 1.3 具备提前还款权的固定利率批发类贷款
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.P` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                  (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '1') or
                  (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN cbrc_fdm_lnac_pmt_bj_q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有本金数据
             AND T.CURR_CD = 'CNY'
             AND T.ORG_NUM <> '009804'
             AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.P` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN cbrc_fdm_lnac_pmt_lx T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN CBRC_FDM_LNAC_PMT_LX_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有利息数据
             AND T.CURR_CD = 'CNY'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.4.N
INSERT 
    INTO `G33_I_1.4.N` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.N'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.N'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.N'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.N'
       END ITEM_NUM,
       SUM(T.AMOUNT_N) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

       -- 大型企业：01、中型企业
       INSERT 
       INTO `G33_I_1.4.N` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
         SELECT 
          I_DATADATE,
          T.ORG_NUM,
          T.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE <= 1 THEN
             'G33_I_1.4.B'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 2 AND 30 THEN
             'G33_I_1.4.C'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 31 AND 90 THEN
             'G33_I_1.4.D'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 91 AND 180 THEN
             'G33_I_1.4.E'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 181 AND 270 THEN
             'G33_I_1.4.F'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 271 AND 360 THEN
             'G33_I_1.4.G'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 361 AND 540 THEN
             'G33_I_1.4.H'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 541 AND 720 THEN
             'G33_I_1.4.I'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 721 AND 1080 THEN
             'G33_I_1.4.J'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1081 AND 1440 THEN
             'G33_I_1.4.K'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1441 AND 1800 THEN
             'G33_I_1.4.L'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
             'G33_I_1.4.M'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
             'G33_I_1.4.N'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
             'G33_I_1.4.O'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
             'G33_I_1.4.P'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
             'G33_I_1.4.Q'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
             'G33_I_1.4.R'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
             'G33_I_1.4.S'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE > 360 * 20 THEN
             'G33_I_1.4.T'
          END AS ITEM_NUM,
          T.LOAN_ACCT_BAL AS TOTAL_VALUE,
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYYMMDD') AS COL4, --到期日（日期）
          T.ACCT_NUM AS COL6, --贷款合同编号
          NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
          CASE
            WHEN T.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T3.CORP_SIZE = '01' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '02' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '03' THEN
             '小型企业'
            WHEN T3.CORP_SIZE = '04' THEN
             '微型企业'
          END AS COL_13 --企业规模
           FROM CBRC_FDM_LNAC T
          INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                        FROM L_CUST_BILL_TY T
                       WHERE T.DATA_DATE = I_DATADATE) T2
             ON T.CUST_ID = T2.CUST_ID
          INNER JOIN L_CUST_EXTERNAL_INFO T3
             ON T2.LEGAL_TYSHXYDM = T3.USCD
            AND T3.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                             MIN(T1.HOLIDAY_DATE) LASTDAY,
                             T.DATA_DATE AS DATADATE
                        FROM L_PUBL_HOLIDAY T
                        LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                    FROM L_PUBL_HOLIDAY T
                                   WHERE T.COUNTRY = 'CHN'
                                     AND T.STATE = '220000'
                                     AND T.WORKING_HOLIDAY = 'W' --工作日
                                  ) T1
                          ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                         AND T.DATA_DATE = T1.DATA_DATE
                       WHERE T.COUNTRY = 'CHN'
                         AND T.STATE = '220000'
                         AND T.WORKING_HOLIDAY = 'H' --假日
                         AND T.HOLIDAY_DATE <= I_DATADATE
                       GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
             ON T.MATURITY_DT = T1.HOLIDAY_DATE
            AND T.DATA_DATE = T1.DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
            AND T3.CORP_SIZE IN ('01', '02');

--===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    -- 1.3 具备提前还款权的固定利率批发类贷款
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.N` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                  (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '1') or
                  (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN cbrc_fdm_lnac_pmt_bj_q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有本金数据
             AND T.CURR_CD = 'CNY'
             AND T.ORG_NUM <> '009804'
             AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.N` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN cbrc_fdm_lnac_pmt_lx T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN CBRC_FDM_LNAC_PMT_LX_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有利息数据
             AND T.CURR_CD = 'CNY'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.1.3.1.J
INSERT 
    INTO `G33_I_1.1.3.1.J` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.J'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.J'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.J'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.J'
       END ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

INSERT 
           INTO `G33_I_1.1.3.1.J` 
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
              COL_10)
             SELECT 
             I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.1.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.1.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
               FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '1'
                AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
                AND T1.NEXT_PAYMENT <>0;

INSERT 
           INTO `G33_I_1.1.3.1.J` 
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
              COL_11)
             SELECT 
             I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.1.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.1.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL11--下一利率重定价日
               FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '3'
                AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
                AND T1.NEXT_PAYMENT <>0;

INSERT 
       INTO `G33_I_1.1.3.1.J` 
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
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.1.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.1.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
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
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
            AND T1.NEXT_PAYMENT <>0;

INSERT 
        INTO `G33_I_1.1.3.1.J` 
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
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.1.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.1.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.1.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM cbrc_fdm_lnac_pmt_lx T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.1.J` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.3.T
INSERT 
    INTO `G33_I_1.3.T` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.T'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.T'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.T'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.T'
       END ITEM_NUM,
       SUM(T.AMOUNT_T) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO `G33_I_1.3.T` 
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
          COL_7,
          COL_12)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12 --客户号
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          WHERE T1.FLAG = '01' --零售
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

INSERT 
       INTO `G33_I_1.3.T` 
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
          COL_7,
          COL_12,
          COL_13,
          COL_14)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12, --客户号
          T2.M_NAME AS COL_13, --企业规模
          FACILITY_AMT AS COL_14 --授信额度
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          LEFT JOIN A_REPT_DWD_MAPPING T2
            ON T1.CORP_SCALE = T2.M_CODE
            AND T2.M_TABLECODE = 'CORP_SCALE'
          WHERE T1.FLAG = '02' --小微企业授信1000万以下
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       --金融市场部 转贴现
       -- 小型企业：03、微型企业：04
        INSERT 
        INTO `G33_I_1.3.T` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE <= 1 THEN
              'G33_I_1.3.B'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 2 AND 30 THEN
              'G33_I_1.3.C'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 31 AND 90 THEN
              'G33_I_1.3.D'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 91 AND 180 THEN
              'G33_I_1.3.E'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 181 AND 270 THEN
              'G33_I_1.3.F'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 271 AND 360 THEN
              'G33_I_1.3.G'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 361 AND 540 THEN
              'G33_I_1.3.H'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 541 AND 720 THEN
              'G33_I_1.3.I'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 721 AND 1080 THEN
              'G33_I_1.3.J'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1081 AND 1440 THEN
              'G33_I_1.3.K'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1441 AND 1800 THEN
              'G33_I_1.3.L'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
              'G33_I_1.3.M'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
              'G33_I_1.3.N'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
              'G33_I_1.3.O'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
              'G33_I_1.3.P'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
              'G33_I_1.3.Q'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 10 + 1 AND
                  360 * 15 THEN
              'G33_I_1.3.R'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 15 + 1 AND
                  360 * 20 THEN
              'G33_I_1.3.S'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE > 360 * 20 THEN
              'G33_I_1.3.T'
           END AS ITEM_NUM,
           T.LOAN_ACCT_BAL AS TOTAL_VALUE,
           T.LOAN_NUM AS COL1, --贷款编号
           T.CURR_CD AS COL2, --币种
           T.ITEM_CD AS COL3, --科目
           TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYY-MM-DD') AS COL4, --到期日（日期）
           T.ACCT_NUM AS COL6, --贷款合同编号
           NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
           CASE
             WHEN T.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8, --五级分类
           CASE
             WHEN T3.CORP_SIZE = '01' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '02' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '03' THEN
              '小型企业'
             WHEN T3.CORP_SIZE = '04' THEN
              '微型企业'
           END AS COL_13 --企业规模
            FROM CBRC_FDM_LNAC T
           INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                         FROM L_CUST_BILL_TY T
                        WHERE T.DATA_DATE = I_DATADATE) T2
              ON T.CUST_ID = T2.CUST_ID
           INNER JOIN L_CUST_EXTERNAL_INFO T3
              ON T2.LEGAL_TYSHXYDM = T3.USCD
             AND T3.DATA_DATE = I_DATADATE
            LEFT JOIN L_PUBL_RATE TT
              ON TT.DATA_DATE = T.DATA_DATE
             AND TT.BASIC_CCY = T.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
            LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                              MIN(T1.HOLIDAY_DATE) LASTDAY,
                              T.DATA_DATE AS DATADATE
                         FROM L_PUBL_HOLIDAY T
                         LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                     FROM L_PUBL_HOLIDAY T
                                    WHERE T.COUNTRY = 'CHN'
                                      AND T.STATE = '220000'
                                      AND T.WORKING_HOLIDAY = 'W' --工作日
                                   ) T1
                           ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                          AND T.DATA_DATE = T1.DATA_DATE
                        WHERE T.COUNTRY = 'CHN'
                          AND T.STATE = '220000'
                          AND T.WORKING_HOLIDAY = 'H' --假日
                          AND T.HOLIDAY_DATE <= I_DATADATE
                        GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
              ON T.MATURITY_DT = T1.HOLIDAY_DATE
             AND T.DATA_DATE = T1.DATADATE
           WHERE T.DATA_DATE = I_DATADATE
             AND T.ACCT_TYP NOT LIKE '90%'
             AND T.LOAN_ACCT_BAL <> 0
             AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
             AND T3.CORP_SIZE IN ('03', '04');

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

      INSERT 
      INTO `G33_I_1.3.T` 
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
         COL_7,
         COL_12)
        SELECT 
         I_DATADATE,
         T1.ORG_NUM,
         T1.DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
         END AS ITEM_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4' THEN
            NVL(T1.OD_INT, 0)
           WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
            T1.ACCU_INT_AMT
         END AS TOTAL_VALUE, --贷款余额
         T1.LOAN_NUM AS COL1, --贷款编号
         T1.CURR_CD AS COL2, --币种
         T1.ITEM_CD AS COL3, --科目
         T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
         CUST_ID AS COL_12 --客户号
          FROM CBRC_FDM_LNAC_PMT_LX_Q T1
         WHERE T1.FLAG = '01' --零售利息
           AND T1.ORG_NUM <> '009804'
           AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

INSERT 
        INTO `G33_I_1.3.T` 
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
           COL_7,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
          END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           T1.CUST_ID AS COL_12, --客户号
           T2.M_NAME AS COL_13, --企业规模
           T1.FACILITY_AMT COL_14 --授信额度
            FROM CBRC_FDM_LNAC_PMT_LX_Q T1
            LEFT JOIN A_REPT_DWD_MAPPING T2
              ON T1.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T1.FLAG = '02' --小微企业1000万以下利息
             AND T1.ORG_NUM <> '009804'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.4.R
INSERT 
    INTO `G33_I_1.4.R` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.R'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.R'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.R'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.R'
       END ITEM_NUM,
       SUM(T.AMOUNT_R) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

       -- 大型企业：01、中型企业
       INSERT 
       INTO `G33_I_1.4.R` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
         SELECT 
          I_DATADATE,
          T.ORG_NUM,
          T.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE <= 1 THEN
             'G33_I_1.4.B'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 2 AND 30 THEN
             'G33_I_1.4.C'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 31 AND 90 THEN
             'G33_I_1.4.D'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 91 AND 180 THEN
             'G33_I_1.4.E'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 181 AND 270 THEN
             'G33_I_1.4.F'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 271 AND 360 THEN
             'G33_I_1.4.G'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 361 AND 540 THEN
             'G33_I_1.4.H'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 541 AND 720 THEN
             'G33_I_1.4.I'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 721 AND 1080 THEN
             'G33_I_1.4.J'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1081 AND 1440 THEN
             'G33_I_1.4.K'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1441 AND 1800 THEN
             'G33_I_1.4.L'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
             'G33_I_1.4.M'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
             'G33_I_1.4.N'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
             'G33_I_1.4.O'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
             'G33_I_1.4.P'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
             'G33_I_1.4.Q'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
             'G33_I_1.4.R'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
             'G33_I_1.4.S'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE > 360 * 20 THEN
             'G33_I_1.4.T'
          END AS ITEM_NUM,
          T.LOAN_ACCT_BAL AS TOTAL_VALUE,
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYYMMDD') AS COL4, --到期日（日期）
          T.ACCT_NUM AS COL6, --贷款合同编号
          NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
          CASE
            WHEN T.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T3.CORP_SIZE = '01' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '02' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '03' THEN
             '小型企业'
            WHEN T3.CORP_SIZE = '04' THEN
             '微型企业'
          END AS COL_13 --企业规模
           FROM CBRC_FDM_LNAC T
          INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                        FROM L_CUST_BILL_TY T
                       WHERE T.DATA_DATE = I_DATADATE) T2
             ON T.CUST_ID = T2.CUST_ID
          INNER JOIN L_CUST_EXTERNAL_INFO T3
             ON T2.LEGAL_TYSHXYDM = T3.USCD
            AND T3.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                             MIN(T1.HOLIDAY_DATE) LASTDAY,
                             T.DATA_DATE AS DATADATE
                        FROM L_PUBL_HOLIDAY T
                        LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                    FROM L_PUBL_HOLIDAY T
                                   WHERE T.COUNTRY = 'CHN'
                                     AND T.STATE = '220000'
                                     AND T.WORKING_HOLIDAY = 'W' --工作日
                                  ) T1
                          ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                         AND T.DATA_DATE = T1.DATA_DATE
                       WHERE T.COUNTRY = 'CHN'
                         AND T.STATE = '220000'
                         AND T.WORKING_HOLIDAY = 'H' --假日
                         AND T.HOLIDAY_DATE <= I_DATADATE
                       GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
             ON T.MATURITY_DT = T1.HOLIDAY_DATE
            AND T.DATA_DATE = T1.DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
            AND T3.CORP_SIZE IN ('01', '02');

--===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    -- 1.3 具备提前还款权的固定利率批发类贷款
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.R` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                  (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '1') or
                  (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN cbrc_fdm_lnac_pmt_bj_q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有本金数据
             AND T.CURR_CD = 'CNY'
             AND T.ORG_NUM <> '009804'
             AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.R` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN cbrc_fdm_lnac_pmt_lx T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN CBRC_FDM_LNAC_PMT_LX_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有利息数据
             AND T.CURR_CD = 'CNY'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.3.J
INSERT 
    INTO `G33_I_1.3.J` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.J'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.J'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.J'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.J'
       END ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO `G33_I_1.3.J` 
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
          COL_7,
          COL_12)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12 --客户号
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          WHERE T1.FLAG = '01' --零售
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

INSERT 
       INTO `G33_I_1.3.J` 
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
          COL_7,
          COL_12,
          COL_13,
          COL_14)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12, --客户号
          T2.M_NAME AS COL_13, --企业规模
          FACILITY_AMT AS COL_14 --授信额度
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          LEFT JOIN A_REPT_DWD_MAPPING T2
            ON T1.CORP_SCALE = T2.M_CODE
            AND T2.M_TABLECODE = 'CORP_SCALE'
          WHERE T1.FLAG = '02' --小微企业授信1000万以下
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       --金融市场部 转贴现
       -- 小型企业：03、微型企业：04
        INSERT 
        INTO `G33_I_1.3.J` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE <= 1 THEN
              'G33_I_1.3.B'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 2 AND 30 THEN
              'G33_I_1.3.C'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 31 AND 90 THEN
              'G33_I_1.3.D'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 91 AND 180 THEN
              'G33_I_1.3.E'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 181 AND 270 THEN
              'G33_I_1.3.F'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 271 AND 360 THEN
              'G33_I_1.3.G'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 361 AND 540 THEN
              'G33_I_1.3.H'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 541 AND 720 THEN
              'G33_I_1.3.I'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 721 AND 1080 THEN
              'G33_I_1.3.J'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1081 AND 1440 THEN
              'G33_I_1.3.K'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1441 AND 1800 THEN
              'G33_I_1.3.L'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
              'G33_I_1.3.M'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
              'G33_I_1.3.N'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
              'G33_I_1.3.O'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
              'G33_I_1.3.P'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
              'G33_I_1.3.Q'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 10 + 1 AND
                  360 * 15 THEN
              'G33_I_1.3.R'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 15 + 1 AND
                  360 * 20 THEN
              'G33_I_1.3.S'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE > 360 * 20 THEN
              'G33_I_1.3.T'
           END AS ITEM_NUM,
           T.LOAN_ACCT_BAL AS TOTAL_VALUE,
           T.LOAN_NUM AS COL1, --贷款编号
           T.CURR_CD AS COL2, --币种
           T.ITEM_CD AS COL3, --科目
           TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYY-MM-DD') AS COL4, --到期日（日期）
           T.ACCT_NUM AS COL6, --贷款合同编号
           NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
           CASE
             WHEN T.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8, --五级分类
           CASE
             WHEN T3.CORP_SIZE = '01' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '02' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '03' THEN
              '小型企业'
             WHEN T3.CORP_SIZE = '04' THEN
              '微型企业'
           END AS COL_13 --企业规模
            FROM CBRC_FDM_LNAC T
           INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                         FROM L_CUST_BILL_TY T
                        WHERE T.DATA_DATE = I_DATADATE) T2
              ON T.CUST_ID = T2.CUST_ID
           INNER JOIN L_CUST_EXTERNAL_INFO T3
              ON T2.LEGAL_TYSHXYDM = T3.USCD
             AND T3.DATA_DATE = I_DATADATE
            LEFT JOIN L_PUBL_RATE TT
              ON TT.DATA_DATE = T.DATA_DATE
             AND TT.BASIC_CCY = T.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
            LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                              MIN(T1.HOLIDAY_DATE) LASTDAY,
                              T.DATA_DATE AS DATADATE
                         FROM L_PUBL_HOLIDAY T
                         LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                     FROM L_PUBL_HOLIDAY T
                                    WHERE T.COUNTRY = 'CHN'
                                      AND T.STATE = '220000'
                                      AND T.WORKING_HOLIDAY = 'W' --工作日
                                   ) T1
                           ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                          AND T.DATA_DATE = T1.DATA_DATE
                        WHERE T.COUNTRY = 'CHN'
                          AND T.STATE = '220000'
                          AND T.WORKING_HOLIDAY = 'H' --假日
                          AND T.HOLIDAY_DATE <= I_DATADATE
                        GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
              ON T.MATURITY_DT = T1.HOLIDAY_DATE
             AND T.DATA_DATE = T1.DATADATE
           WHERE T.DATA_DATE = I_DATADATE
             AND T.ACCT_TYP NOT LIKE '90%'
             AND T.LOAN_ACCT_BAL <> 0
             AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
             AND T3.CORP_SIZE IN ('03', '04');

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

      INSERT 
      INTO `G33_I_1.3.J` 
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
         COL_7,
         COL_12)
        SELECT 
         I_DATADATE,
         T1.ORG_NUM,
         T1.DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
         END AS ITEM_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4' THEN
            NVL(T1.OD_INT, 0)
           WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
            T1.ACCU_INT_AMT
         END AS TOTAL_VALUE, --贷款余额
         T1.LOAN_NUM AS COL1, --贷款编号
         T1.CURR_CD AS COL2, --币种
         T1.ITEM_CD AS COL3, --科目
         T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
         CUST_ID AS COL_12 --客户号
          FROM CBRC_FDM_LNAC_PMT_LX_Q T1
         WHERE T1.FLAG = '01' --零售利息
           AND T1.ORG_NUM <> '009804'
           AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

INSERT 
        INTO `G33_I_1.3.J` 
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
           COL_7,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
          END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           T1.CUST_ID AS COL_12, --客户号
           T2.M_NAME AS COL_13, --企业规模
           T1.FACILITY_AMT COL_14 --授信额度
            FROM CBRC_FDM_LNAC_PMT_LX_Q T1
            LEFT JOIN A_REPT_DWD_MAPPING T2
              ON T1.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T1.FLAG = '02' --小微企业1000万以下利息
             AND T1.ORG_NUM <> '009804'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.1.3.2.S
INSERT 
    INTO `G33_I_1.1.3.2.S` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.S'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.S'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.S'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.S'
       END ITEM_NUM,
       SUM(T.AMOUNT_S) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO `G33_I_1.1.3.2.S` 
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
                COL_10)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
                 FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '1'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账'))--add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO `G33_I_1.1.3.2.S` 
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
                COL_11)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD')  AS COL_11--下一利率重定价日
                 FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '3'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;

----------------------------------按照正常重定价日处理
   -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO `G33_I_1.1.3.2.S` 
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
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.2.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.2.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.1.3.2.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
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
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND (T1.BENM_INRAT_TYPE = 'A' OR
                (T1.BENM_INRAT_TYPE = '#' AND
                T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
            AND T1.NEXT_PAYMENT <>0;

--133应收利息  应计利息+应收利息
    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.1.3.2.S` 
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
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.2.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.2.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.2.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM cbrc_fdm_lnac_pmt_lx T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND (T1.BENM_INRAT_TYPE = 'A' OR
                 (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --分项指标转换   此处插入利息轧差项目，其他在A_REPT_DWD_G3301明细中处理
    /* 1.1.3.1 其中：以贷款市场报价利率（LPR）为定价基础的人民币浮动利率贷款
    1.1.3.2 其中：以人民银行基准利率为定价基础的浮动利率贷款
    1.2 具备提前还款权的固定利率零售类贷款
    1.3 具备提前还款权的固定利率批发类贷款*/
      INSERT 
      INTO `G33_I_1.1.3.2.S` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE)
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.B' ITEM_NUM,
         SUM(T.AMOUNT_B) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_B <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.C' ITEM_NUM,
         SUM(T.AMOUNT_C) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_C <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.D' ITEM_NUM,
         SUM(T.AMOUNT_D) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_D <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.E' ITEM_NUM,
         SUM(T.AMOUNT_E) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_E <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.F' ITEM_NUM,
         SUM(T.AMOUNT_F) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_F <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.G' ITEM_NUM,
         SUM(T.AMOUNT_G) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_G <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.H' ITEM_NUM,
         SUM(T.AMOUNT_H) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_H <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.I' ITEM_NUM,
         SUM(T.AMOUNT_I) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_I <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.J' ITEM_NUM,
         SUM(T.AMOUNT_J) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_J <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.K' ITEM_NUM,
         SUM(T.AMOUNT_K) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_K <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.L' ITEM_NUM,
         SUM(T.AMOUNT_L) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_L <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.M' ITEM_NUM,
         SUM(T.AMOUNT_M) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_M <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.N' ITEM_NUM,
         SUM(T.AMOUNT_N) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_N <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.O' ITEM_NUM,
         SUM(T.AMOUNT_O) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_O <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.P' ITEM_NUM,
         SUM(T.AMOUNT_P) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_P <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.Q' ITEM_NUM,
         SUM(T.AMOUNT_Q) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_Q <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.R' ITEM_NUM,
         SUM(T.AMOUNT_R) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_R <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.S' ITEM_NUM,
         SUM(T.AMOUNT_S) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_S <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.T' ITEM_NUM,
         SUM(T.AMOUNT_T) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_T <> 0
         GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.2.S` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.1.3.T
INSERT 
    INTO `G33_I_1.1.3.T` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_I_1.1.3.T' ITEM_NUM,
       SUM(T.AMOUNT_T) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.1.3.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.T` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.4.I
INSERT 
    INTO `G33_I_1.4.I` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.I'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.I'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.I'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.I'
       END ITEM_NUM,
       SUM(T.AMOUNT_I) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

       -- 大型企业：01、中型企业
       INSERT 
       INTO `G33_I_1.4.I` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
         SELECT 
          I_DATADATE,
          T.ORG_NUM,
          T.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE <= 1 THEN
             'G33_I_1.4.B'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 2 AND 30 THEN
             'G33_I_1.4.C'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 31 AND 90 THEN
             'G33_I_1.4.D'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 91 AND 180 THEN
             'G33_I_1.4.E'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 181 AND 270 THEN
             'G33_I_1.4.F'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 271 AND 360 THEN
             'G33_I_1.4.G'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 361 AND 540 THEN
             'G33_I_1.4.H'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 541 AND 720 THEN
             'G33_I_1.4.I'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 721 AND 1080 THEN
             'G33_I_1.4.J'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1081 AND 1440 THEN
             'G33_I_1.4.K'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1441 AND 1800 THEN
             'G33_I_1.4.L'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
             'G33_I_1.4.M'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
             'G33_I_1.4.N'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
             'G33_I_1.4.O'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
             'G33_I_1.4.P'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
             'G33_I_1.4.Q'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
             'G33_I_1.4.R'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
             'G33_I_1.4.S'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE > 360 * 20 THEN
             'G33_I_1.4.T'
          END AS ITEM_NUM,
          T.LOAN_ACCT_BAL AS TOTAL_VALUE,
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYYMMDD') AS COL4, --到期日（日期）
          T.ACCT_NUM AS COL6, --贷款合同编号
          NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
          CASE
            WHEN T.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T3.CORP_SIZE = '01' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '02' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '03' THEN
             '小型企业'
            WHEN T3.CORP_SIZE = '04' THEN
             '微型企业'
          END AS COL_13 --企业规模
           FROM CBRC_FDM_LNAC T
          INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                        FROM L_CUST_BILL_TY T
                       WHERE T.DATA_DATE = I_DATADATE) T2
             ON T.CUST_ID = T2.CUST_ID
          INNER JOIN L_CUST_EXTERNAL_INFO T3
             ON T2.LEGAL_TYSHXYDM = T3.USCD
            AND T3.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                             MIN(T1.HOLIDAY_DATE) LASTDAY,
                             T.DATA_DATE AS DATADATE
                        FROM L_PUBL_HOLIDAY T
                        LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                    FROM L_PUBL_HOLIDAY T
                                   WHERE T.COUNTRY = 'CHN'
                                     AND T.STATE = '220000'
                                     AND T.WORKING_HOLIDAY = 'W' --工作日
                                  ) T1
                          ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                         AND T.DATA_DATE = T1.DATA_DATE
                       WHERE T.COUNTRY = 'CHN'
                         AND T.STATE = '220000'
                         AND T.WORKING_HOLIDAY = 'H' --假日
                         AND T.HOLIDAY_DATE <= I_DATADATE
                       GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
             ON T.MATURITY_DT = T1.HOLIDAY_DATE
            AND T.DATA_DATE = T1.DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
            AND T3.CORP_SIZE IN ('01', '02');

--===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    -- 1.3 具备提前还款权的固定利率批发类贷款
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.I` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                  (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '1') or
                  (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN cbrc_fdm_lnac_pmt_bj_q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有本金数据
             AND T.CURR_CD = 'CNY'
             AND T.ORG_NUM <> '009804'
             AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.I` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN cbrc_fdm_lnac_pmt_lx T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN CBRC_FDM_LNAC_PMT_LX_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有利息数据
             AND T.CURR_CD = 'CNY'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.1.3.O
INSERT 
    INTO `G33_I_1.1.3.O` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_I_1.1.3.O' ITEM_NUM,
       SUM(T.AMOUNT_O) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.1.3.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.O` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.1.3.2.F
INSERT 
    INTO `G33_I_1.1.3.2.F` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.F'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.F'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.F'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.F'
       END ITEM_NUM,
       SUM(T.AMOUNT_F) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO `G33_I_1.1.3.2.F` 
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
                COL_10)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
                 FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '1'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账'))--add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO `G33_I_1.1.3.2.F` 
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
                COL_11)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD')  AS COL_11--下一利率重定价日
                 FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '3'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;

----------------------------------按照正常重定价日处理
   -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO `G33_I_1.1.3.2.F` 
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
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.2.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.2.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.1.3.2.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
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
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND (T1.BENM_INRAT_TYPE = 'A' OR
                (T1.BENM_INRAT_TYPE = '#' AND
                T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
            AND T1.NEXT_PAYMENT <>0;

--133应收利息  应计利息+应收利息
    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.1.3.2.F` 
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
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.2.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.2.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.2.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM cbrc_fdm_lnac_pmt_lx T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND (T1.BENM_INRAT_TYPE = 'A' OR
                 (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --分项指标转换   此处插入利息轧差项目，其他在A_REPT_DWD_G3301明细中处理
    /* 1.1.3.1 其中：以贷款市场报价利率（LPR）为定价基础的人民币浮动利率贷款
    1.1.3.2 其中：以人民银行基准利率为定价基础的浮动利率贷款
    1.2 具备提前还款权的固定利率零售类贷款
    1.3 具备提前还款权的固定利率批发类贷款*/
      INSERT 
      INTO `G33_I_1.1.3.2.F` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE)
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.B' ITEM_NUM,
         SUM(T.AMOUNT_B) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_B <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.C' ITEM_NUM,
         SUM(T.AMOUNT_C) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_C <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.D' ITEM_NUM,
         SUM(T.AMOUNT_D) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_D <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.E' ITEM_NUM,
         SUM(T.AMOUNT_E) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_E <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.F' ITEM_NUM,
         SUM(T.AMOUNT_F) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_F <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.G' ITEM_NUM,
         SUM(T.AMOUNT_G) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_G <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.H' ITEM_NUM,
         SUM(T.AMOUNT_H) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_H <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.I' ITEM_NUM,
         SUM(T.AMOUNT_I) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_I <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.J' ITEM_NUM,
         SUM(T.AMOUNT_J) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_J <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.K' ITEM_NUM,
         SUM(T.AMOUNT_K) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_K <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.L' ITEM_NUM,
         SUM(T.AMOUNT_L) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_L <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.M' ITEM_NUM,
         SUM(T.AMOUNT_M) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_M <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.N' ITEM_NUM,
         SUM(T.AMOUNT_N) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_N <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.O' ITEM_NUM,
         SUM(T.AMOUNT_O) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_O <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.P' ITEM_NUM,
         SUM(T.AMOUNT_P) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_P <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.Q' ITEM_NUM,
         SUM(T.AMOUNT_Q) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_Q <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.R' ITEM_NUM,
         SUM(T.AMOUNT_R) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_R <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.S' ITEM_NUM,
         SUM(T.AMOUNT_S) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_S <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.T' ITEM_NUM,
         SUM(T.AMOUNT_T) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_T <> 0
         GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.2.F` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.1.3.P
INSERT 
    INTO `G33_I_1.1.3.P` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_I_1.1.3.P' ITEM_NUM,
       SUM(T.AMOUNT_P) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.1.3.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.P` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1_1.2.I
INSERT 
    INTO `G33_I_1_1.2.I` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.I'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.I'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.I'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.I'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.I'
       END ITEM_NUM,
       SUM(T.AMOUNT_I) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.I'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.I'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.I'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.I'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.I'
                END;

INSERT 
    INTO `G33_I_1_1.2.I` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
          'G33_I_1_1.1.I'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
          'G33_I_1_1.2.I'
         WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
          'G33_I_1_1.4.I'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
          'G33_1_2_1.1.I'
         WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
          'G33_1_2_1.4.I'
       END ITEM_NUM,
       SUM(T.AMOUNT_I) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN ('G33_I_1_1.1',
                                 'G33_I_1_1.2',
                                 'G33_I_1_1.4',
                                 'G33_1_2_1.1',
                                 'G33_1_2_1.4')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO,
                CASE
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.1' THEN
                   'G33_I_1_1.1.I'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.2' THEN
                   'G33_I_1_1.2.I'
                  WHEN T.LOCAL_STATION = 'G33_I_1_1.4' THEN
                   'G33_I_1_1.4.I'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.1' THEN
                   'G33_1_2_1.1.I'
                  WHEN T.LOCAL_STATION = 'G33_1_2_1.4' THEN
                   'G33_1_2_1.4.I'
                END;


-- 指标: G33_I_1.1.3.S
INSERT 
    INTO `G33_I_1.1.3.S` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_I_1.1.3.S' ITEM_NUM,
       SUM(T.AMOUNT_S) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.1.3.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.S` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.1.3.2.J
INSERT 
    INTO `G33_I_1.1.3.2.J` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.J'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.J'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.J'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.J'
       END ITEM_NUM,
       SUM(T.AMOUNT_J) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO `G33_I_1.1.3.2.J` 
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
                COL_10)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
                 FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '1'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账'))--add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
             INSERT 
             INTO `G33_I_1.1.3.2.J` 
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
                COL_11)
               SELECT 
                I_DATADATE,
                T1.ORG_NUM,
                T1.DATA_DEPARTMENT, --数据条线
                'CBRC' AS SYS_NAM,
                'G33' REP_NUM,
                CASE
                  WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                       (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                   'G33_I_1.1.3.2.B'
                  WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                       T1.IDENTITY_CODE = '1') or
                       (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                   'G33_I_1.1.3.2.C'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND   --1个月-3个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.D'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND  --3个月-6个月（含）
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.E'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND  --6个月-9个月(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.F'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND  --9个月-1年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.G'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND  --1年-1.5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.H'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND  --1.5年-2年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.I'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.J'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND  --3年-4年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.K'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.L'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.M'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.N'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.O'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.P'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.Q'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.R'
                  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND  --15年-20年(含)
                       T1.IDENTITY_CODE = '1' THEN
                   'G33_I_1.1.3.2.S'
                  WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN  --20年以上
                   'G33_I_1.1.3.2.T'
                END AS ITEM_NUM,
                T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
                T1.LOAN_NUM AS COL1, --贷款编号
                T1.CURR_CD AS COL2, --币种
                T1.ITEM_CD AS COL3, --科目
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
                TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
                END AS COL8, --五级分类
                CASE
                  WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                   'LPR'
                  WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                   '基准利率'
                  WHEN T1.BENM_INRAT_TYPE = '#' THEN
                   '其他利率'
                END AS COL9, --参考利率类型
                TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD')  AS COL_11--下一利率重定价日
                 FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
                WHERE FLAG = '3'
                  AND (T1.BENM_INRAT_TYPE = 'A' OR
                      (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
                  AND T1.NEXT_PAYMENT <>0;

----------------------------------按照正常重定价日处理
   -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO `G33_I_1.1.3.2.J` 
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
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.2.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.2.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.2.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.1.3.2.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
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
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND (T1.BENM_INRAT_TYPE = 'A' OR
                (T1.BENM_INRAT_TYPE = '#' AND
                T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
            AND T1.NEXT_PAYMENT <>0;

--133应收利息  应计利息+应收利息
    -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.1.3.2.J` 
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
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.2.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.2.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.2.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.2.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM cbrc_fdm_lnac_pmt_lx T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND (T1.BENM_INRAT_TYPE = 'A' OR
                 (T1.BENM_INRAT_TYPE = '#' AND T1.DATE_SOURCESD = 'NGI-2-垫款台账')) --add by djh 20220613  BENM_INRAT_TYPE为#的即空值且数据来源为垫款数据，那么就放在 LPR利率
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --分项指标转换   此处插入利息轧差项目，其他在A_REPT_DWD_G3301明细中处理
    /* 1.1.3.1 其中：以贷款市场报价利率（LPR）为定价基础的人民币浮动利率贷款
    1.1.3.2 其中：以人民银行基准利率为定价基础的浮动利率贷款
    1.2 具备提前还款权的固定利率零售类贷款
    1.3 具备提前还款权的固定利率批发类贷款*/
      INSERT 
      INTO `G33_I_1.1.3.2.J` 
        (DATA_DATE,
         ORG_NUM,
         DATA_DEPARTMENT,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         TOTAL_VALUE)
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.B' ITEM_NUM,
         SUM(T.AMOUNT_B) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_B <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.C' ITEM_NUM,
         SUM(T.AMOUNT_C) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_C <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.D' ITEM_NUM,
         SUM(T.AMOUNT_D) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_D <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.E' ITEM_NUM,
         SUM(T.AMOUNT_E) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_E <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.F' ITEM_NUM,
         SUM(T.AMOUNT_F) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_F <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.G' ITEM_NUM,
         SUM(T.AMOUNT_G) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_G <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.H' ITEM_NUM,
         SUM(T.AMOUNT_H) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_H <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.I' ITEM_NUM,
         SUM(T.AMOUNT_I) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_I <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.J' ITEM_NUM,
         SUM(T.AMOUNT_J) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_J <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.K' ITEM_NUM,
         SUM(T.AMOUNT_K) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_K <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.L' ITEM_NUM,
         SUM(T.AMOUNT_L) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_L <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.M' ITEM_NUM,
         SUM(T.AMOUNT_M) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_M <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.N' ITEM_NUM,
         SUM(T.AMOUNT_N) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_N <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.O' ITEM_NUM,
         SUM(T.AMOUNT_O) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_O <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.P' ITEM_NUM,
         SUM(T.AMOUNT_P) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_P <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.Q' ITEM_NUM,
         SUM(T.AMOUNT_Q) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_Q <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.R' ITEM_NUM,
         SUM(T.AMOUNT_R) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_R <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.S' ITEM_NUM,
         SUM(T.AMOUNT_S) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_S <> 0
         GROUP BY ORGNO
        UNION ALL
        SELECT 
         I_DATADATE,
         T.ORGNO,
         '' AS DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         'G33_I_1.1.3.2.T' ITEM_NUM,
         SUM(T.AMOUNT_T) AS CUR_BAL
          FROM CBRC_ID_G3301_ITEMDATA_NGI T
         WHERE T.LOCAL_STATION = 'G33_I_1.1.3.1'
           AND T.RQ = I_DATADATE
           AND T.AMOUNT_T <> 0
         GROUP BY ORGNO;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.2.J` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.1.3.1.N
INSERT 
    INTO `G33_I_1.1.3.1.N` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.N'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.N'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.N'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.N'
       END ITEM_NUM,
       SUM(T.AMOUNT_N) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

INSERT 
           INTO `G33_I_1.1.3.1.N` 
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
              COL_10)
             SELECT 
             I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.1.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.1.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
               FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '1'
                AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
                AND T1.NEXT_PAYMENT <>0;

INSERT 
           INTO `G33_I_1.1.3.1.N` 
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
              COL_11)
             SELECT 
             I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.1.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.1.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL11--下一利率重定价日
               FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '3'
                AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
                AND T1.NEXT_PAYMENT <>0;

INSERT 
       INTO `G33_I_1.1.3.1.N` 
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
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.1.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.1.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
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
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
            AND T1.NEXT_PAYMENT <>0;

INSERT 
        INTO `G33_I_1.1.3.1.N` 
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
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.1.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.1.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.1.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM cbrc_fdm_lnac_pmt_lx T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.1.N` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.3.S
INSERT 
    INTO `G33_I_1.3.S` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.S'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.S'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.S'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.S'
       END ITEM_NUM,
       SUM(T.AMOUNT_S) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO `G33_I_1.3.S` 
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
          COL_7,
          COL_12)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12 --客户号
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          WHERE T1.FLAG = '01' --零售
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

INSERT 
       INTO `G33_I_1.3.S` 
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
          COL_7,
          COL_12,
          COL_13,
          COL_14)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12, --客户号
          T2.M_NAME AS COL_13, --企业规模
          FACILITY_AMT AS COL_14 --授信额度
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          LEFT JOIN A_REPT_DWD_MAPPING T2
            ON T1.CORP_SCALE = T2.M_CODE
            AND T2.M_TABLECODE = 'CORP_SCALE'
          WHERE T1.FLAG = '02' --小微企业授信1000万以下
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       --金融市场部 转贴现
       -- 小型企业：03、微型企业：04
        INSERT 
        INTO `G33_I_1.3.S` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE <= 1 THEN
              'G33_I_1.3.B'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 2 AND 30 THEN
              'G33_I_1.3.C'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 31 AND 90 THEN
              'G33_I_1.3.D'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 91 AND 180 THEN
              'G33_I_1.3.E'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 181 AND 270 THEN
              'G33_I_1.3.F'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 271 AND 360 THEN
              'G33_I_1.3.G'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 361 AND 540 THEN
              'G33_I_1.3.H'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 541 AND 720 THEN
              'G33_I_1.3.I'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 721 AND 1080 THEN
              'G33_I_1.3.J'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1081 AND 1440 THEN
              'G33_I_1.3.K'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1441 AND 1800 THEN
              'G33_I_1.3.L'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
              'G33_I_1.3.M'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
              'G33_I_1.3.N'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
              'G33_I_1.3.O'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
              'G33_I_1.3.P'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
              'G33_I_1.3.Q'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 10 + 1 AND
                  360 * 15 THEN
              'G33_I_1.3.R'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 15 + 1 AND
                  360 * 20 THEN
              'G33_I_1.3.S'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE > 360 * 20 THEN
              'G33_I_1.3.T'
           END AS ITEM_NUM,
           T.LOAN_ACCT_BAL AS TOTAL_VALUE,
           T.LOAN_NUM AS COL1, --贷款编号
           T.CURR_CD AS COL2, --币种
           T.ITEM_CD AS COL3, --科目
           TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYY-MM-DD') AS COL4, --到期日（日期）
           T.ACCT_NUM AS COL6, --贷款合同编号
           NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
           CASE
             WHEN T.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8, --五级分类
           CASE
             WHEN T3.CORP_SIZE = '01' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '02' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '03' THEN
              '小型企业'
             WHEN T3.CORP_SIZE = '04' THEN
              '微型企业'
           END AS COL_13 --企业规模
            FROM CBRC_FDM_LNAC T
           INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                         FROM L_CUST_BILL_TY T
                        WHERE T.DATA_DATE = I_DATADATE) T2
              ON T.CUST_ID = T2.CUST_ID
           INNER JOIN L_CUST_EXTERNAL_INFO T3
              ON T2.LEGAL_TYSHXYDM = T3.USCD
             AND T3.DATA_DATE = I_DATADATE
            LEFT JOIN L_PUBL_RATE TT
              ON TT.DATA_DATE = T.DATA_DATE
             AND TT.BASIC_CCY = T.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
            LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                              MIN(T1.HOLIDAY_DATE) LASTDAY,
                              T.DATA_DATE AS DATADATE
                         FROM L_PUBL_HOLIDAY T
                         LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                     FROM L_PUBL_HOLIDAY T
                                    WHERE T.COUNTRY = 'CHN'
                                      AND T.STATE = '220000'
                                      AND T.WORKING_HOLIDAY = 'W' --工作日
                                   ) T1
                           ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                          AND T.DATA_DATE = T1.DATA_DATE
                        WHERE T.COUNTRY = 'CHN'
                          AND T.STATE = '220000'
                          AND T.WORKING_HOLIDAY = 'H' --假日
                          AND T.HOLIDAY_DATE <= I_DATADATE
                        GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
              ON T.MATURITY_DT = T1.HOLIDAY_DATE
             AND T.DATA_DATE = T1.DATADATE
           WHERE T.DATA_DATE = I_DATADATE
             AND T.ACCT_TYP NOT LIKE '90%'
             AND T.LOAN_ACCT_BAL <> 0
             AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
             AND T3.CORP_SIZE IN ('03', '04');

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

      INSERT 
      INTO `G33_I_1.3.S` 
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
         COL_7,
         COL_12)
        SELECT 
         I_DATADATE,
         T1.ORG_NUM,
         T1.DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
         END AS ITEM_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4' THEN
            NVL(T1.OD_INT, 0)
           WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
            T1.ACCU_INT_AMT
         END AS TOTAL_VALUE, --贷款余额
         T1.LOAN_NUM AS COL1, --贷款编号
         T1.CURR_CD AS COL2, --币种
         T1.ITEM_CD AS COL3, --科目
         T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
         CUST_ID AS COL_12 --客户号
          FROM CBRC_FDM_LNAC_PMT_LX_Q T1
         WHERE T1.FLAG = '01' --零售利息
           AND T1.ORG_NUM <> '009804'
           AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

INSERT 
        INTO `G33_I_1.3.S` 
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
           COL_7,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
          END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           T1.CUST_ID AS COL_12, --客户号
           T2.M_NAME AS COL_13, --企业规模
           T1.FACILITY_AMT COL_14 --授信额度
            FROM CBRC_FDM_LNAC_PMT_LX_Q T1
            LEFT JOIN A_REPT_DWD_MAPPING T2
              ON T1.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T1.FLAG = '02' --小微企业1000万以下利息
             AND T1.ORG_NUM <> '009804'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.3.E
INSERT 
    INTO `G33_I_1.3.E` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.E'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.E'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.E'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.E'
       END ITEM_NUM,
       SUM(T.AMOUNT_E) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       INSERT 
       INTO `G33_I_1.3.E` 
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
          COL_7,
          COL_12)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12 --客户号
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          WHERE T1.FLAG = '01' --零售
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

INSERT 
       INTO `G33_I_1.3.E` 
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
          COL_7,
          COL_12,
          COL_13,
          COL_14)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.3.B'
            WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.3.C'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.D'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.E'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.F'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.G'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.H'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.I'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.J'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.K'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.L'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.M'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.N'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.O'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.P'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.Q'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.R'
            WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.3.S'
            WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
             'G33_I_1.3.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
          CUST_ID AS COL_12, --客户号
          T2.M_NAME AS COL_13, --企业规模
          FACILITY_AMT AS COL_14 --授信额度
           FROM cbrc_fdm_lnac_pmt_bj_q T1
          LEFT JOIN A_REPT_DWD_MAPPING T2
            ON T1.CORP_SCALE = T2.M_CODE
            AND T2.M_TABLECODE = 'CORP_SCALE'
          WHERE T1.FLAG = '02' --小微企业授信1000万以下
            AND T1.ORG_NUM <> '009804'
            AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
       --金融市场部 转贴现
       -- 小型企业：03、微型企业：04
        INSERT 
        INTO `G33_I_1.3.E` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE <= 1 THEN
              'G33_I_1.3.B'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 2 AND 30 THEN
              'G33_I_1.3.C'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 31 AND 90 THEN
              'G33_I_1.3.D'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 91 AND 180 THEN
              'G33_I_1.3.E'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 181 AND 270 THEN
              'G33_I_1.3.F'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 271 AND 360 THEN
              'G33_I_1.3.G'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 361 AND 540 THEN
              'G33_I_1.3.H'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 541 AND 720 THEN
              'G33_I_1.3.I'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 721 AND 1080 THEN
              'G33_I_1.3.J'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1081 AND 1440 THEN
              'G33_I_1.3.K'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1441 AND 1800 THEN
              'G33_I_1.3.L'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
              'G33_I_1.3.M'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
              'G33_I_1.3.N'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
              'G33_I_1.3.O'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
              'G33_I_1.3.P'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
              'G33_I_1.3.Q'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 10 + 1 AND
                  360 * 15 THEN
              'G33_I_1.3.R'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE BETWEEN 360 * 15 + 1 AND
                  360 * 20 THEN
              'G33_I_1.3.S'
             WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                  I_DATADATE > 360 * 20 THEN
              'G33_I_1.3.T'
           END AS ITEM_NUM,
           T.LOAN_ACCT_BAL AS TOTAL_VALUE,
           T.LOAN_NUM AS COL1, --贷款编号
           T.CURR_CD AS COL2, --币种
           T.ITEM_CD AS COL3, --科目
           TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYY-MM-DD') AS COL4, --到期日（日期）
           T.ACCT_NUM AS COL6, --贷款合同编号
           NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
           CASE
             WHEN T.LOAN_GRADE_CD = '1' THEN
              '正常'
             WHEN T.LOAN_GRADE_CD = '2' THEN
              '关注'
             WHEN T.LOAN_GRADE_CD = '3' THEN
              '次级'
             WHEN T.LOAN_GRADE_CD = '4' THEN
              '可疑'
             WHEN T.LOAN_GRADE_CD = '5' THEN
              '损失'
           END AS COL8, --五级分类
           CASE
             WHEN T3.CORP_SIZE = '01' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '02' THEN
              '中型企业'
             WHEN T3.CORP_SIZE = '03' THEN
              '小型企业'
             WHEN T3.CORP_SIZE = '04' THEN
              '微型企业'
           END AS COL_13 --企业规模
            FROM CBRC_FDM_LNAC T
           INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                         FROM L_CUST_BILL_TY T
                        WHERE T.DATA_DATE = I_DATADATE) T2
              ON T.CUST_ID = T2.CUST_ID
           INNER JOIN L_CUST_EXTERNAL_INFO T3
              ON T2.LEGAL_TYSHXYDM = T3.USCD
             AND T3.DATA_DATE = I_DATADATE
            LEFT JOIN L_PUBL_RATE TT
              ON TT.DATA_DATE = T.DATA_DATE
             AND TT.BASIC_CCY = T.CURR_CD
             AND TT.FORWARD_CCY = 'CNY'
            LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                              MIN(T1.HOLIDAY_DATE) LASTDAY,
                              T.DATA_DATE AS DATADATE
                         FROM L_PUBL_HOLIDAY T
                         LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                     FROM L_PUBL_HOLIDAY T
                                    WHERE T.COUNTRY = 'CHN'
                                      AND T.STATE = '220000'
                                      AND T.WORKING_HOLIDAY = 'W' --工作日
                                   ) T1
                           ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                          AND T.DATA_DATE = T1.DATA_DATE
                        WHERE T.COUNTRY = 'CHN'
                          AND T.STATE = '220000'
                          AND T.WORKING_HOLIDAY = 'H' --假日
                          AND T.HOLIDAY_DATE <= I_DATADATE
                        GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
              ON T.MATURITY_DT = T1.HOLIDAY_DATE
             AND T.DATA_DATE = T1.DATADATE
           WHERE T.DATA_DATE = I_DATADATE
             AND T.ACCT_TYP NOT LIKE '90%'
             AND T.LOAN_ACCT_BAL <> 0
             AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
             AND T3.CORP_SIZE IN ('03', '04');

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

      INSERT 
      INTO `G33_I_1.3.E` 
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
         COL_7,
         COL_12)
        SELECT 
         I_DATADATE,
         T1.ORG_NUM,
         T1.DATA_DEPARTMENT, --数据条线
         'CBRC' AS SYS_NAM,
         'G33' REP_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
         END AS ITEM_NUM,
         CASE
           WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4' THEN
            NVL(T1.OD_INT, 0)
           WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
            T1.ACCU_INT_AMT
         END AS TOTAL_VALUE, --贷款余额
         T1.LOAN_NUM AS COL1, --贷款编号
         T1.CURR_CD AS COL2, --币种
         T1.ITEM_CD AS COL3, --科目
         T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
         CUST_ID AS COL_12 --客户号
          FROM CBRC_FDM_LNAC_PMT_LX_Q T1
         WHERE T1.FLAG = '01' --零售利息
           AND T1.ORG_NUM <> '009804'
           AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

INSERT 
        INTO `G33_I_1.3.E` 
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
           COL_7,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
           WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
            'G33_I_1.3.B'
           WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                T1.IDENTITY_CODE = '3') or
                (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
            'G33_I_1.3.C'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.D'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.E'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.F'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.G'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.H'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.I'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.J'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.K'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.L'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.M'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.N'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.O'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.P'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.Q'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.R'
           WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                T1.IDENTITY_CODE = '3' THEN
            'G33_I_1.3.S'
           WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
            'G33_I_1.3.T'
          END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数） 还款计划利息到期日/没有还款计划的利息取下月21号D_DATADATE_CCY + 21
           T1.CUST_ID AS COL_12, --客户号
           T2.M_NAME AS COL_13, --企业规模
           T1.FACILITY_AMT COL_14 --授信额度
            FROM CBRC_FDM_LNAC_PMT_LX_Q T1
            LEFT JOIN A_REPT_DWD_MAPPING T2
              ON T1.CORP_SCALE = T2.M_CODE
             AND T2.M_TABLECODE = 'CORP_SCALE'
           WHERE T1.FLAG = '02' --小微企业1000万以下利息
             AND T1.ORG_NUM <> '009804'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_I_1.1.3.1.K
INSERT 
    INTO `G33_I_1.1.3.1.K` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.K'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.K'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.K'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.K'
       END ITEM_NUM,
       SUM(T.AMOUNT_K) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

INSERT 
           INTO `G33_I_1.1.3.1.K` 
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
              COL_10)
             SELECT 
             I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.1.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.1.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               REPRICE_PERIOD AS  COL_10 --重定价周期_核算端
               FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '1'
                AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
                AND T1.NEXT_PAYMENT <>0;

INSERT 
           INTO `G33_I_1.1.3.1.K` 
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
              COL_11)
             SELECT 
             I_DATADATE,
              T1.ORG_NUM,
              T1.DATA_DEPARTMENT, --数据条线
              'CBRC' AS SYS_NAM,
              'G33' REP_NUM,
              CASE
                WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                     (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
                 'G33_I_1.1.3.1.B'
                WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND
                     T1.IDENTITY_CODE = '1') or
                     (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
                 'G33_I_1.1.3.1.C'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.D'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.E'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.F'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.G'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.H'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.I'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.J'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.K'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.L'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.M'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.N'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.O'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.P'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.Q'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.R'
                WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                     T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.S'
                WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
                 'G33_I_1.1.3.1.T'
              END AS ITEM_NUM,
              T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
              T1.LOAN_NUM AS COL1, --贷款编号
              T1.CURR_CD AS COL2, --币种
              T1.ITEM_CD AS COL3, --科目
              TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
              TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
              END AS COL8, --五级分类
              CASE
                WHEN T1.BENM_INRAT_TYPE = 'A' THEN
                 'LPR'
                WHEN T1.BENM_INRAT_TYPE = 'B' THEN
                 '基准利率'
                WHEN T1.BENM_INRAT_TYPE = '#' THEN
                 '其他利率'
              END AS COL9, --参考利率类型
               TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL11--下一利率重定价日
               FROM CBRC_FDM_LNAC_PMT_LLCDJR T1
              WHERE FLAG = '3'
                AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
                AND T1.NEXT_PAYMENT <>0;

INSERT 
       INTO `G33_I_1.1.3.1.K` 
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
          COL_11)
         SELECT 
          I_DATADATE,
          T1.ORG_NUM,
          T1.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN (T1.PMT_REMAIN_TERM_D = 1 AND T1.IDENTITY_CODE = '1') OR
                 (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
             'G33_I_1.1.3.1.B'
            WHEN (T1.PMT_REMAIN_TERM_D BETWEEN 2 AND 30 AND
                 T1.IDENTITY_CODE = '1') or
                 (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
             'G33_I_1.1.3.1.C'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 31 AND 90 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.D'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 91 AND 180 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.E'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 181 AND 270 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.F'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 271 AND 360 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.G'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 361 AND 540 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.H'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 541 AND 720 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.I'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 721 AND 1080 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.J'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1081 AND 1440 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.K'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1441 AND 1800 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.L'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 1801 AND 360 * 6 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.M'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 6 + 1 AND 360 * 7 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.N'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 7 + 1 AND 360 * 8 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.O'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 8 + 1 AND 360 * 9 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.P'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 9 + 1 AND 360 * 10 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.Q'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 10 + 1 AND 360 * 15 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.R'
            WHEN T1.PMT_REMAIN_TERM_D BETWEEN 360 * 15 + 1 AND 360 * 20 AND
                 T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.S'
            WHEN T1.PMT_REMAIN_TERM_D > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN
             'G33_I_1.1.3.1.T'
          END AS ITEM_NUM,
          T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
          T1.LOAN_NUM AS COL1, --贷款编号
          T1.CURR_CD AS COL2, --币种
          T1.ITEM_CD AS COL3, --科目
          TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
          TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
          T1.ACCT_NUM AS COL6, --贷款合同编号
          CASE
            WHEN (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0 OR
                 T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN
             T1.PMT_REMAIN_TERM_C
            WHEN T1.PMT_REMAIN_TERM_D >= 1 AND T1.IDENTITY_CODE = '1' THEN
             T1.PMT_REMAIN_TERM_D
          END AS COL7, --剩余期限（天数）
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
          CASE
            WHEN T1.BENM_INRAT_TYPE = 'A' THEN
             'LPR'
            WHEN T1.BENM_INRAT_TYPE = 'B' THEN
             '基准利率'
            WHEN T1.BENM_INRAT_TYPE = '#' THEN
             '其他利率'
          END AS COL9, --参考利率类型
          TO_CHAR(NEXT_REPRICING_DT, 'YYYY-MM-DD') AS COL_11 --下一利率重定价日
           FROM CBRC_FDM_LNAC_PMT T1
          WHERE T1.DATA_DATE = I_DATADATE
            AND T1.BOOK_TYPE = '2' --账户种类  1  交易账户  2  银行账户
            AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
            AND T1.CURR_CD = 'CNY'
            AND T1.NEXT_REPRICING_DT IS NOT NULL
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') > I_DATADATE
            AND TO_CHAR(T1.NEXT_REPRICING_DT, 'YYYYMMDD') <=
                TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYYMMDD') --20231215 利率重定价日小于实际到期日，其他在下面处理
            AND T1.LOAN_NUM NOT IN
                (SELECT LOAN_NUM
                   FROM CBRC_FDM_LNAC_PMT_LLCDJR
                  WHERE FLAG IN ('1', '2', '3'))
            AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
            AND T1.NEXT_PAYMENT <>0;

INSERT 
        INTO `G33_I_1.1.3.1.K` 
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
           COL_9)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --浮动利率,应计利息按还款计划表下一还款日
              'G33_I_1.1.3.1.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.1.3.1.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.1.3.1.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.1.3.1.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           TO_CHAR(T1.ACTUAL_MATURITY_DT, 'YYYY-MM-DD') AS COL4, --贷款实际到期日
           TO_CHAR(T1.NEXT_PAYMENT_DT, 'YYYY-MM-DD') AS COL5, --下次付款日
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
           END AS COL8, --五级分类
           CASE
             WHEN T1.BENM_INRAT_TYPE = 'A' THEN
              'LPR'
             WHEN T1.BENM_INRAT_TYPE = 'B' THEN
              '基准利率'
             WHEN T1.BENM_INRAT_TYPE = '#' THEN
              '其他利率'
           END AS COL9 --参考利率类型
            FROM cbrc_fdm_lnac_pmt_lx T1
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP LIKE 'L%' --利率类型  F固定利率 L都是浮动利率  O 其他类型
             AND T1.CURR_CD = 'CNY'
             AND T1.BENM_INRAT_TYPE = 'B' --基准利率类型（B基准率,A LPR利率,#空值）
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
    --总项指标汇总：1.1.3 贷款
        INSERT 
        INTO `G33_I_1.1.3.1.K` 
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
           COL_11,
           COL_12,
           COL_13,
           COL_14)
          SELECT 
           I_DATADATE,
           T.ORG_NUM,
           T.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.B', 'G33_I_1.1.3.2.B', 'G33_I_1.1.3.3.B') THEN
              'G33_I_1.1.3.B'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.C', 'G33_I_1.1.3.2.C', 'G33_I_1.1.3.3.C') THEN
              'G33_I_1.1.3.C'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.D', 'G33_I_1.1.3.2.D', 'G33_I_1.1.3.3.D') THEN
              'G33_I_1.1.3.D'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.E', 'G33_I_1.1.3.2.E', 'G33_I_1.1.3.3.E') THEN
              'G33_I_1.1.3.E'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.F', 'G33_I_1.1.3.2.F', 'G33_I_1.1.3.3.F') THEN
              'G33_I_1.1.3.F'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.G', 'G33_I_1.1.3.2.G', 'G33_I_1.1.3.3.G') THEN
              'G33_I_1.1.3.G'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.H', 'G33_I_1.1.3.2.H', 'G33_I_1.1.3.3.H') THEN
              'G33_I_1.1.3.H'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.I', 'G33_I_1.1.3.2.I', 'G33_I_1.1.3.3.I') THEN
              'G33_I_1.1.3.I'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.J', 'G33_I_1.1.3.2.J', 'G33_I_1.1.3.3.J') THEN
              'G33_I_1.1.3.J'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.K', 'G33_I_1.1.3.2.K', 'G33_I_1.1.3.3.K') THEN
              'G33_I_1.1.3.K'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.L', 'G33_I_1.1.3.2.L', 'G33_I_1.1.3.3.L') THEN
              'G33_I_1.1.3.L'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.M', 'G33_I_1.1.3.2.M', 'G33_I_1.1.3.3.M') THEN
              'G33_I_1.1.3.M'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.N', 'G33_I_1.1.3.2.N', 'G33_I_1.1.3.3.N') THEN
              'G33_I_1.1.3.N'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.O', 'G33_I_1.1.3.2.O', 'G33_I_1.1.3.3.O') THEN
              'G33_I_1.1.3.O'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.P', 'G33_I_1.1.3.2.P', 'G33_I_1.1.3.3.P') THEN
              'G33_I_1.1.3.P'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.Q', 'G33_I_1.1.3.2.Q', 'G33_I_1.1.3.3.Q') THEN
              'G33_I_1.1.3.Q'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.R', 'G33_I_1.1.3.2.R', 'G33_I_1.1.3.3.R') THEN
              'G33_I_1.1.3.R'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.S', 'G33_I_1.1.3.2.S', 'G33_I_1.1.3.3.S') THEN
              'G33_I_1.1.3.S'
             WHEN ITEM_NUM IN
                  ('G33_I_1.1.3.1.T', 'G33_I_1.1.3.2.T', 'G33_I_1.1.3.3.T') THEN --20年以上
              'G33_I_1.1.3.T'
           END AS ITEM_NUM,
           TOTAL_VALUE, --贷款余额
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
           COL_11,
           COL_12,
           COL_13,
           COL_14
            FROM CBRC_A_REPT_DWD_G3301 T
           WHERE (T.ITEM_NUM LIKE 'G33_I_1.1.3.1%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.2%' OR
                 T.ITEM_NUM LIKE 'G33_I_1.1.3.3%');


-- 指标: G33_I_1.4.O
INSERT 
    INTO `G33_I_1.4.O` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       CASE
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.1' THEN
          'G33_I_1.1.3.2.O'
         WHEN T.LOCAL_STATION = 'G33_I_1.1.3.2' THEN
          'G33_I_1.1.3.1.O'
         WHEN T.LOCAL_STATION = 'G33_I_1.2' THEN
          'G33_I_1.3.O'
         WHEN T.LOCAL_STATION = 'G33_I_1.3' THEN
          'G33_I_1.4.O'
       END ITEM_NUM,
       SUM(T.AMOUNT_O) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION IN
             ('G33_I_1.1.3.1', 'G33_I_1.1.3.2', 'G33_I_1.2', 'G33_I_1.3')
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO, T.LOCAL_STATION;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]

       -- 大型企业：01、中型企业
       INSERT 
       INTO `G33_I_1.4.O` 
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
           COL_6,
           COL_7,
           COL_8,
           COL_13)
         SELECT 
          I_DATADATE,
          T.ORG_NUM,
          T.DATA_DEPARTMENT, --数据条线
          'CBRC' AS SYS_NAM,
          'G33' REP_NUM,
          CASE
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE <= 1 THEN
             'G33_I_1.4.B'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 2 AND 30 THEN
             'G33_I_1.4.C'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 31 AND 90 THEN
             'G33_I_1.4.D'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 91 AND 180 THEN
             'G33_I_1.4.E'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 181 AND 270 THEN
             'G33_I_1.4.F'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 271 AND 360 THEN
             'G33_I_1.4.G'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 361 AND 540 THEN
             'G33_I_1.4.H'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 541 AND 720 THEN
             'G33_I_1.4.I'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 721 AND 1080 THEN
             'G33_I_1.4.J'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1081 AND 1440 THEN
             'G33_I_1.4.K'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1441 AND 1800 THEN
             'G33_I_1.4.L'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 1801 AND 360 * 6 THEN
             'G33_I_1.4.M'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 6 + 1 AND 360 * 7 THEN
             'G33_I_1.4.N'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 7 + 1 AND 360 * 8 THEN
             'G33_I_1.4.O'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 8 + 1 AND 360 * 9 THEN
             'G33_I_1.4.P'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 9 + 1 AND 360 * 10 THEN
             'G33_I_1.4.Q'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 10 + 1 AND 360 * 15 THEN
             'G33_I_1.4.R'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE BETWEEN 360 * 15 + 1 AND 360 * 20 THEN
             'G33_I_1.4.S'
            WHEN NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) -
                 I_DATADATE > 360 * 20 THEN
             'G33_I_1.4.T'
          END AS ITEM_NUM,
          T.LOAN_ACCT_BAL AS TOTAL_VALUE,
          T.LOAN_NUM AS COL1, --贷款编号
          T.CURR_CD AS COL2, --币种
          T.ITEM_CD AS COL3, --科目
          TO_CHAR(NVL(T1.HOLIDAY_DATE, T.MATURITY_DT), 'YYYYMMDD') AS COL4, --到期日（日期）
          T.ACCT_NUM AS COL6, --贷款合同编号
          NVL(T1.HOLIDAY_DATE, T.MATURITY_DT) - I_DATADATE AS COL7, --剩余期限（天数）
          CASE
            WHEN T.LOAN_GRADE_CD = '1' THEN
             '正常'
            WHEN T.LOAN_GRADE_CD = '2' THEN
             '关注'
            WHEN T.LOAN_GRADE_CD = '3' THEN
             '次级'
            WHEN T.LOAN_GRADE_CD = '4' THEN
             '可疑'
            WHEN T.LOAN_GRADE_CD = '5' THEN
             '损失'
          END AS COL8, --五级分类
          CASE
            WHEN T3.CORP_SIZE = '01' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '02' THEN
             '中型企业'
            WHEN T3.CORP_SIZE = '03' THEN
             '小型企业'
            WHEN T3.CORP_SIZE = '04' THEN
             '微型企业'
          END AS COL_13 --企业规模
           FROM CBRC_FDM_LNAC T
          INNER JOIN (SELECT DISTINCT CUST_ID, LEGAL_TYSHXYDM
                        FROM L_CUST_BILL_TY T
                       WHERE T.DATA_DATE = I_DATADATE) T2
             ON T.CUST_ID = T2.CUST_ID
          INNER JOIN L_CUST_EXTERNAL_INFO T3
             ON T2.LEGAL_TYSHXYDM = T3.USCD
            AND T3.DATA_DATE = I_DATADATE
           LEFT JOIN L_PUBL_RATE TT
             ON TT.DATA_DATE = T.DATA_DATE
            AND TT.BASIC_CCY = T.CURR_CD
            AND TT.FORWARD_CCY = 'CNY'
           LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,
                             MIN(T1.HOLIDAY_DATE) LASTDAY,
                             T.DATA_DATE AS DATADATE
                        FROM L_PUBL_HOLIDAY T
                        LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE
                                    FROM L_PUBL_HOLIDAY T
                                   WHERE T.COUNTRY = 'CHN'
                                     AND T.STATE = '220000'
                                     AND T.WORKING_HOLIDAY = 'W' --工作日
                                  ) T1
                          ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE
                         AND T.DATA_DATE = T1.DATA_DATE
                       WHERE T.COUNTRY = 'CHN'
                         AND T.STATE = '220000'
                         AND T.WORKING_HOLIDAY = 'H' --假日
                         AND T.HOLIDAY_DATE <= I_DATADATE
                       GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1
             ON T.MATURITY_DT = T1.HOLIDAY_DATE
            AND T.DATA_DATE = T1.DATADATE
          WHERE T.DATA_DATE = I_DATADATE
            AND T.ACCT_TYP NOT LIKE '90%'
            AND T.LOAN_ACCT_BAL <> 0
            AND SUBSTR(T.ITEM_CD, 1, 6) IN ('130102', '130105') --买断式转贴现
            AND T3.CORP_SIZE IN ('01', '02');

--===============================================  1.2 具备提前还款权的固定利率零售类贷款  零售+小微企业授信额度1000万 ，其他都放在1.3==============================================
    --===============================================  1.3 具备提前还款权的固定利率批发类贷款 ==============================================

    -- 1.3 具备提前还款权的固定利率批发类贷款
     -- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.O` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') OR
                  (T1.ACCT_STATUS_1104 = '10' AND T1.PMT_REMAIN_TERM_C <= 0) THEN --浮动利率,正常贷款  下一利率重定价日剩余期限
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '1') or
                  (T1.IDENTITY_CODE = '2' AND T1.PMT_REMAIN_TERM_C <= 90) THEN --逾期90天内放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '1' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '1' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           T1.NEXT_PAYMENT AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN CBRC_FDM_LNAC_PMT T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN cbrc_fdm_lnac_pmt_bj_q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有本金数据
             AND T.CURR_CD = 'CNY'
             AND T.ORG_NUM <> '009804'
             AND T1.NEXT_PAYMENT <>0;

-- [2025-12-26] [狄家卉] [JLBA202503070010][统一监管报送平台升级]
        INSERT 
        INTO `G33_I_1.4.O` 
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
           COL_7,
           COL_12)
          SELECT 
           I_DATADATE,
           T1.ORG_NUM,
           T1.DATA_DEPARTMENT, --数据条线
           'CBRC' AS SYS_NAM,
           'G33' REP_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN --应计利息
              'G33_I_1.4.B'
             WHEN (T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 30 AND T1.IDENTITY_CODE = '3') or
                  (T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4') THEN --逾期90天内利息放在隔夜-一个月（含）
              'G33_I_1.4.C'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND --1个月-3个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.D'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 180 AND --3个月-6个月（含）
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.E'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 181 AND 270 AND --6个月-9个月(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.F'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 271 AND 360 AND --9个月-1年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.G'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 540 AND --1年-1.5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.H'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 541 AND 720 AND --1.5年-2年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.I'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 721 AND 1080 AND --2年-3年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.J'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1081 AND 1440 AND --3年-4年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.K'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1441 AND 1800 AND --4年-5年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.L'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 1801 AND 360 * 6 AND --5年-6年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.M'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 6 + 1 AND 360 * 7 AND --6年-7年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.N'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 7 + 1 AND 360 * 8 AND --7年-8年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.O'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 8 + 1 AND 360 * 9 AND --8年-9年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.P'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 9 + 1 AND 360 * 10 AND --9年-10年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.Q'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 10 + 1 AND 360 * 15 AND --10年-15年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.R'
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 360 * 15 + 1 AND 360 * 20 AND --15年-20年(含)
                  T1.IDENTITY_CODE = '3' THEN
              'G33_I_1.4.S'
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 20 AND T1.IDENTITY_CODE = '3' THEN --20年以上
              'G33_I_1.4.T'
           END AS ITEM_NUM,
           CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 90 AND T1.PMT_REMAIN_TERM_C >= 1 AND
                  T1.IDENTITY_CODE = '4' THEN
              NVL(T1.OD_INT, 0)
             WHEN T1.PMT_REMAIN_TERM_C >= 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT
           END AS TOTAL_VALUE, --贷款余额
           T1.LOAN_NUM AS COL1, --贷款编号
           T1.CURR_CD AS COL2, --币种
           T1.ITEM_CD AS COL3, --科目
           T1.PMT_REMAIN_TERM_C AS COL7, --剩余期限（天数）
           T.CUST_ID AS COL_12 --客户号
            FROM CBRC_FDM_LNAC T
           INNER JOIN cbrc_fdm_lnac_pmt_lx T1
              ON T.LOAN_NUM = T1.LOAN_NUM
             AND T.DATA_DATE = T1.DATA_DATE
            LEFT JOIN CBRC_FDM_LNAC_PMT_LX_Q T3
              ON T.LOAN_NUM = T3.LOAN_NUM
             AND T.DATA_DATE = T3.DATA_DATE
           WHERE T1.DATA_DATE = I_DATADATE
             AND T1.BOOK_TYPE = '2'
             AND T1.INT_RATE_TYP = 'F'
             AND T3.LOAN_NUM IS NULL --取除了零售和小微企业1000万以下以外所有利息数据
             AND T.CURR_CD = 'CNY'
             AND (T1.OD_INT <>0 OR T1.ACCU_INT_AMT <>0);


-- 指标: G33_1_2.1.2.D.2019
INSERT 
    INTO `G33_1_2.1.2.D.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.D.2019' ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;

INSERT 
    INTO `G33_1_2.1.2.D.2019` 
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORGNO,
       'G33_1_2.1.2.D.2019' ITEM_NUM,
       SUM(T.AMOUNT_D) AS CUR_BAL
        FROM CBRC_ID_G3301_ITEMDATA_NGI T
       WHERE T.LOCAL_STATION ='G33_1_2.1.2'
         AND T.RQ = I_DATADATE
       GROUP BY ORGNO;


