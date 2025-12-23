-- ============================================================
-- 文件名: G03各项资产减值损失准备情况表.sql
-- 生成时间: 2025-12-18 13:53:37
-- 说明: 采用 CTE (WITH) 聚合去重模式生成，大幅减小血缘解析压力
-- ============================================================

-- 指标: G03_15..A
INSERT INTO `G03_15..A`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G03' AS REP_NUM, --报表编号
       'G03_15..A' AS ITEM_NUM, --指标号
       SUM(NVL(M.CREDIT_BAL, 0)) AS AMT,
       '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL M
       WHERE M.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
         AND M.ITEM_CD IN ('123101', --ALTER BY WJB 20221216 对应老科目 13402
                           '1512', --ALTER BY WJB 20221216 对应老科目 147
                           '1442', --ALTER BY WJB 20221216 对应老科目 150
                           '160301', --ALTER BY WJB 20221216 对应老科目 15306
                           '160501', --ALTER BY WJB 20221216 对应老科目 15403
                           '160801', --ALTER BY WJB 20221216 对应老科目 15502
                           '161101', --ALTER BY WJB 20221216 对应老科目 15603
                           '170301', --ALTER BY WJB 20221216 对应老科目 16103
                           '171201', --ALTER BY WJB 20221216 对应老科目 16402
                           '1523', --ALTER BY WJB 20221216 对应老科目 17204
                           '2801') --ALTER BY WJB 20221216 对应老科目 280
         AND M.CURR_CD IN ('CNY', 'ZCNY')
       GROUP BY ORG_NUM;


-- 指标: G03_1..G
--注释2：
  
    INSERT INTO `G03_1..G`
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
             'G03' AS REP_NUM, --报表编号
             'G03_1..G' AS ITEM_NUM, --指标号
             SUM(T1.CREDIT_BAL * T2.CCY_RATE) AS ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('130401',
                            '130402',
                            '130403',
                            '130404',
                            '130405',
                            '130406',
                            '40030215',
                            '40030216',
                            '40030217')
       GROUP BY ORG_NUM;


-- 指标: G03_15..B
INSERT INTO `G03_15..B`
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
             'G03' AS REP_NUM, --报表编号
             'G03_15..B' AS ITEM_NUM, --指标号
             sum(T1.DEBIT_BAL * T2.CCY_RATE) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('67020210', '6701', '670208', '670299') --modify by djh
     
       GROUP BY ORG_NUM;


-- 指标: G03_14..G
INSERT INTO `G03_14..G`
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
             'G03' AS REP_NUM, --报表编号
             'G03_14..G' AS ITEM_NUM, --指标号
             SUM(T1.CREDIT_BAL * T2.CCY_RATE) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN
             ('40030208', '40030209', '40030210', '40030211', '40030221')
       GROUP BY ORG_NUM;


-- 指标: G03_15..G
INSERT INTO `G03_15..G`
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
             'G03' AS REP_NUM, --报表编号
             'G03_15..G' AS ITEM_NUM, --指标号
             SUM(T1.CREDIT_BAL * T2.CCY_RATE) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('1231',
                            '1442',
                            '1603',
                            '1605',
                            '1608',
                            '1611',
                            '1703',
                            '1712',
                            '1523',
                            '1482',
                            --'1502',--注释m1
                            '1512',
                            '280102')
       GROUP BY ORG_NUM;


-- 指标: G03_13..A
INSERT INTO `G03_13..A`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G03' AS REP_NUM, --报表编号
       'G03_13..A' AS ITEM_NUM, --指标号
       SUM(NVL(M.CREDIT_BAL, 0)) AS AMT,
       '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL M
       WHERE M.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
         AND M.ITEM_CD IN ('130701', --ALTER BY WJB 20221216 对应老科目 121
                           '130407', --ALTER BY WJB 20221216 对应老科目 13401
                           '10130101', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130102', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130103', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130104', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130105', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130106', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130107', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130108', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130109', --ALTER BY WJB 20221216 对应老科目 13403
                           '12319901', --ALTER BY WJB 20221216 对应老科目 13403
                           '130408', --ALTER BY WJB 20221216 对应老科目 13404
                           '10130201', --ALTER BY WJB 20221216 对应老科目 13405
                           '10130202', --ALTER BY WJB 20221216 对应老科目 13406
                           '13070301', --ALTER BY WJB 20221216 对应老科目 13407
                           '13070302', --ALTER BY WJB 20221216 对应老科目 13408
                           '11120101', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120301', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120201', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120102', --ALTER BY WJB 20221216 对应老科目 14004
                           '11129901', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120103', --ALTER BY WJB 20221216 对应老科目 14005
                           '11120302', --ALTER BY WJB 20221216 对应老科目 14005
                           '11120202', --ALTER BY WJB 20221216 对应老科目 14005
                           '11120104', --ALTER BY WJB 20221216 对应老科目 14005
                           '11129902', --ALTER BY WJB 20221216 对应老科目 14005
                           '150201', --ALTER BY WJB 20221216 对应老科目 14307
                           '150202', --ALTER BY WJB 20221216 对应老科目 14308
                           '150203', --ALTER BY WJB 20221216 对应老科目 14309
                           '150204') --ALTER BY WJB 20221216 对应老科目 14310
         AND M.CURR_CD IN ('CNY', 'ZCNY')
         AND ORG_NUM <> '009820' ---add by  zy   20240819
       GROUP BY ORG_NUM;

------------add  by   zy   start  同业金融部反馈新增科目 新增的科目其他机构也有数据，因此先拆出----
    INSERT INTO `G03_13..A`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G03' AS REP_NUM, --报表编号
       'G03_13..A' AS ITEM_NUM, --指标号
       SUM(NVL(M.CREDIT_BAL, 0)) AS AMT,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL M
       WHERE M.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
         AND M.ITEM_CD IN ('130701', --ALTER BY WJB 20221216 对应老科目 121
                           '130407', --ALTER BY WJB 20221216 对应老科目 13401
                           '10130101', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130102', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130103', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130104', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130105', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130106', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130107', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130108', --ALTER BY WJB 20221216 对应老科目 13403
                           '10130109', --ALTER BY WJB 20221216 对应老科目 13403
                           '12319901', --ALTER BY WJB 20221216 对应老科目 13403
                           '130408', --ALTER BY WJB 20221216 对应老科目 13404
                           '10130201', --ALTER BY WJB 20221216 对应老科目 13405
                           '10130202', --ALTER BY WJB 20221216 对应老科目 13406
                           '13070301', --ALTER BY WJB 20221216 对应老科目 13407
                           '13070302', --ALTER BY WJB 20221216 对应老科目 13408
                           '11120101', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120301', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120201', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120102', --ALTER BY WJB 20221216 对应老科目 14004
                           '11129901', --ALTER BY WJB 20221216 对应老科目 14004
                           '11120103', --ALTER BY WJB 20221216 对应老科目 14005
                           '11120302', --ALTER BY WJB 20221216 对应老科目 14005
                           '11120202', --ALTER BY WJB 20221216 对应老科目 14005
                           '11120104', --ALTER BY WJB 20221216 对应老科目 14005
                           '11129902', --ALTER BY WJB 20221216 对应老科目 14005
                           '150201', --ALTER BY WJB 20221216 对应老科目 14307
                           '150202', --ALTER BY WJB 20221216 对应老科目 14308
                           '150203', --ALTER BY WJB 20221216 对应老科目 14309
                           '150204', --ALTER BY WJB 20221216 对应老科目 14310
                           '10130110', --ALTER BY ZY  20240819 同业金融部反馈新增科目
                           '10130111', --ALTER BY ZY  20240819 同业金融部反馈新增科目
                           '10130401', --ALTER BY ZY  20240819 同业金融部反馈新增科目
                           '10130402', --ALTER BY ZY  20240819 同业金融部反馈新增科目
                           '10130301' --ALTER BY ZY  20240819 同业金融部反馈新增科目
                           )
         AND M.CURR_CD IN ('CNY', 'ZCNY')
         AND ORG_NUM = '009820' ---add by  zy   20240819
       GROUP BY ORG_NUM;


-- 指标: G03_14..B
INSERT INTO `G03_14..B`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G03' AS REP_NUM, --报表编号
       'G03_14..B' AS ITEM_NUM, --指标号
       sum(T1.DEBIT_BAL * T2.CCY_RATE) ITEM_VAL,
       '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('670207')
       GROUP BY ORG_NUM;


-- 指标: G03_1..B
--ALTER BY WJB 20221110 根据松原李姐提供的新核心科目映射关系，修改取数逻辑
    INSERT INTO `G03_1..B`
      (data_date,
       org_num,
       sys_nam,
       rep_num,
       item_num,
       item_val,
       item_val_v,
       flag,
       b_curr_cd,
       is_total)
      SELECT I_DATADATE, --时间
             T.ORG_NUM, --机构号
             'CBRC', --模块简称
             'G03', --科目编号
             'G03_1..B', --指标名称
             SUM(T.DEBIT_BAL * U.CCY_RATE), --金额
             '',
             '1' AS FLAG, --标志位
             'CNY' --币种
            ,
             ''
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
       WHERE T.ITEM_CD IN ('67020101',
                           '67020102',
                           '67020103',
                           '67020105',
                           '67020104',
                           '67020106') --'670201' modify by djh
         AND T.DATA_DATE = I_DATADATE
       GROUP BY T.ORG_NUM;


-- 指标: G03_13..G
INSERT INTO `G03_13..G`
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
             'G03' AS REP_NUM, --报表编号
             'G03_13..G' AS ITEM_NUM, --指标号
             SUM(T1.CREDIT_BAL * T2.CCY_RATE) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
            --ALTER BY WJB 20221119 根据新老科目映射 对比过总账表新老科目余额后更新
            --注释M1:按照业务提供新口径---1013;


-- 指标: G03_14..A
INSERT INTO `G03_14..A`
      (DATA_DATE, -- 数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G03' AS REP_NUM, --报表编号
       'G03_14..A' AS ITEM_NUM, --指标号
       SUM(NVL(M.CREDIT_BAL, 0)) AS AMT,
       '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL M
       WHERE M.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
         AND M.ITEM_CD IN
             ('40030208', '40030209', '40030210', '40030211', '40030221') --alter by  20241224 m3
         AND M.CURR_CD IN ('CNY', 'ZCNY')
       GROUP BY ORG_NUM;


-- 指标: G03_13..B
--------------add  by  zy  end
  
    INSERT INTO `G03_13..B`
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
             'G03' AS REP_NUM, --报表编号
             'G03_13..B' AS ITEM_NUM, --指标号
             SUM(CASE
                   WHEN ITEM_CD = '67020210' THEN
                    -T1.DEBIT_BAL * T2.CCY_RATE
                   ELSE
                    T1.DEBIT_BAL * T2.CCY_RATE
                 END) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T2
          ON T1.CURR_CD = T2.BASIC_CCY
         AND T2.FORWARD_CCY = 'CNY'
         AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ITEM_CD IN ('67020210',
                            '670206',
                            '670205',
                            '67020401',
                            '67020402',
                            '67020403',
                            '67020404',
                            '67020407',
                            '67020405',
                            '67020406',
                            '670299',
                            --ALTER BY WJB 20221216 以下是原53102老科目 以上科目对应的钱与老科目一致
                            '67020107',
                            '67020108',
                            '67020109',
                            '67020110',
                            '67020111',
                            '67020112',
                            '67020113',
                            '67020114',
                            '67020115',
                            '670202',
                            '670203',
                            '67020408',
                            '67020409')
       GROUP BY ORG_NUM;


-- 指标: G03_1..A
INSERT INTO `G03_1..A`
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             V_REP_NUM AS REP_NUM,
             'G03_1..A' AS ITEM_NUM,
             SUM(T.CREDIT_BAL * U.CCY_RATE) ITEM_VAL,
             '1' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = SUBSTR(I_DATADATE, 1, 4) - 1 || '1231'
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY'
      
      --ALTER BY WJB 20230302 该指标取上年末的期末余额
       WHERE T.ITEM_CD IN ('130401',
                           '130402',
                           '130403',
                           '130404',
                           '130405',
                           '130406',
                           '40030215',
                           '40030216',
                           '40030217')
            --ALTER BY WJB 20221216
         AND T.DATA_DATE = substr(I_DATADATE, 1, 4) - 1 || '1231'
       GROUP BY ORG_NUM;


