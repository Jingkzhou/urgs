CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_check_result(II_DATADATE IN STRING --跑批日期
                                              ) AS
 /*------------------------------------------------------------------------------------------------------
  -- 程序名：SP_CHECK_RESULT
  -- 程序功能：G21存款贷款本金，利息以及与G0102表间逻辑结果校验数据
  -- 目标表：PM_RSDATA.CBRC_CHECK_DATA ,PM_RSDATA.CBRC_CHECK_DATA_RESULT
  -- 创建日期：20220908
  -- 创建人：djh
  -- 版本号：V0.0.1
  -- 调度频率：日调度  0
  -- 参数：
  -- IS_DATE 输入变量，传入跑批日期
  -- OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  -- mdf by djh 20231115 去掉村镇机构核对,调整金融市场部，同业金融部利息
  ----????需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求?上线日期：2025-05-27，修改人：石雨，提出人：王曦若?，修改内容：调整代理国库业务会计科目
  -- 需求编号：无 上线日期： 2025-09-19，修改人：狄家卉，提出人：无  修改原因：总账与分户账进行核对，增加总账部分差异
  -- [JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]

结果表：PM_RSDATA.CBRC_CHECK_DATA
     PM_RSDATA.CBRC_CHECK_DATA_RESULT
     PM_RSDATA.CBRC_CHECK_DATA_RESULT_FINAL
临时表：PM_RSDATA.CBRC_CHECK_DATA_DEAL
核对原数据表：PM_RSDATA.CBRC_A_REPT_ITEM_RESULT
视图 ： PM_RSDATA.CBRC_V_PUB_FUND_INVEST
     PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL
集市表：
     PM_RSDATA.SMTMODS_L_PUBL_RATE
     PM_RSDATA.SMTMODS_L_FIMM_PRODUCT
     PM_RSDATA.SMTMODS_L_FIMM_PRODUCT_BAL
     PM_RSDATA.SMTMODS_L_FINA_GL
     PM_RSDATA.SMTMODS_L_AGRE_OTHER_SUBJECT_INFO
     PM_RSDATA.SMTMODS_L_ACCT_FUND_MMFUND_PAYM_SCHED
     PM_RSDATA.SMTMODS_L_ACCT_LOAN
     PM_RSDATA.SMTMODS_ZF_ITEM_CD_MAPPING
     PM_RSDATA.SMTMODS_L_ACCT_LOAN_PAYM_SCHED

     

     
     
   -----------------------------------------------------------------------------------------------------------------------------   */                                              
  V_SCHEMA            VARCHAR2(10); --当前存储过程所属的模式名
  V_PROCEDURE         VARCHAR(30); --当前储存过程名称
  V_STEP_ID           INTEGER; --任务号
  V_STEP_DESC         VARCHAR(4000); --任务描述
  V_STEP_FLAG         INTEGER; --任务执行状态标识
  V_ERRORCODE         VARCHAR(20); --错误编码
  V_ERRORDESC         VARCHAR(280); --错误内容
  IS_DATE             VARCHAR2(10); --数据日期(数值型)YYYYMMDD
  V_COUNT             NUMBER(10) default 0;
  OI_REMESSAGE_LIST   VARCHAR2(4000);
  V_SYSTEM            VARCHAR2(10);
  O_STATUS_DEC        VARCHAR(4000);
  O_STATUS            INTEGER;
BEGIN

  
  
  V_PROCEDURE := 'PBOC_CBRC_CHECK_RESULT';
  IS_DATE     := II_DATADATE;
  -- 开始日志
  V_STEP_ID   := 1;
  V_STEP_FLAG := 0;
  V_STEP_DESC := '删除表数据处理开始';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

  --[2025-09-19] [狄家卉]  增加总账部分差异
  DELETE FROM PM_RSDATA.CBRC_CHECK_DATA_DEAL A WHERE A.DT_DATE = IS_DATE;
  COMMIT;

  DELETE FROM PM_RSDATA.CBRC_CHECK_DATA A WHERE A.DT_DATE = IS_DATE;
  COMMIT;

  DELETE FROM PM_RSDATA.CBRC_CHECK_DATA_RESULT A WHERE A.DT_DATE = IS_DATE;
  COMMIT;
  
  --[2025-11-19] [狄家卉] 增加一个结果表，为了过滤结果表中宽限期引起不平的数据
  DELETE FROM PM_RSDATA.CBRC_CHECK_DATA_RESULT_FINAL A WHERE A.DT_DATE = IS_DATE;
   
  COMMIT;

  V_STEP_FLAG := 1;
  V_STEP_DESC := '删除表数据处理完成';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

---------------------------------------------------------贷款 ---------------------------------------------------------

  V_STEP_ID   := V_STEP_ID + 1;
  V_STEP_FLAG := 0;
  V_STEP_DESC := 'G21的1.6各项贷款与总账校验开始';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

  -- G21的 1.6各项贷款 与总账校验
  INSERT  INTO PM_RSDATA.CBRC_CHECK_DATA 
    (DT_DATE, --校验日期
     CHECK_TPYE, --校验类型
     BALANCE1, --校验表1值
     BALANCE2, --校验表2值
     BALANCE, --差异
     REMARK,--备注
     FLAG)
    SELECT  IS_DATE,
           'G21 1.6各项贷款 = 贷款+贴现+信用卡',
           SUM(G21),
           SUM(ZZ),
           SUM(G21) - SUM(ZZ),
           '1104系统与总账校验',
           '01' AS FLAG
      FROM (SELECT ROUND(SUM(T.ITEM_VAL)) G21, 0 ZZ
              FROM PM_RSDATA.CBRC_A_REPT_ITEM_RESULT T
             WHERE REPLACE(DATA_DATE, '-', '') = IS_DATE
               AND T.REP_NUM = 'G21'
               AND T.ITEM_NUM LIKE 'G21_1.6%'
               AND T.ORG_NUM = '990000'
            UNION ALL
            SELECT 0 G21, ROUND(SUM(BAL)) ZZ
              FROM (SELECT '贷款', SUM(T.DEBIT_BAL * B.CCY_RATE) AS BAL --借方余额
                      FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL T
                      LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                        ON T.DATA_DATE = B.DATA_DATE
                       AND T.CURR_CD = B.BASIC_CCY
                       AND B.FORWARD_CCY = 'CNY'
                     WHERE T.DATA_DATE = IS_DATE
                       AND T.ORG_NUM = '990000'
                       AND T.ITEM_CD IN ('130301', '130302', '1305')
                    UNION ALL
                    SELECT '总账',
                           SUM(CASE
                                 WHEN T.ITEM_CD = '1306' THEN
                                  T.DEBIT_BAL * B.CCY_RATE --借方余额
                                 ELSE
                                  0
                               END) - SUM(CASE
                                            WHEN T.ITEM_CD = '13060402' THEN
                                             T.DEBIT_BAL * B.CCY_RATE --13604  银行卡垫款

                                            ELSE
                                             0
                                          END) AS BAL
                      FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL T
                      LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                        ON T.DATA_DATE = B.DATA_DATE
                       AND T.CURR_CD = B.BASIC_CCY
                       AND B.FORWARD_CCY = 'CNY'
                     WHERE T.DATA_DATE = IS_DATE
                       AND T.ORG_NUM = '990000'
                       AND T.ITEM_CD IN ('1306', '13060402')
                    --129贴现资产减掉公允价值变动
                    UNION ALL
                    SELECT '贴现',
                           SUM(CASE
                                 WHEN T.ITEM_CD = '1301' THEN -- 129贴现资产
                                  T.DEBIT_BAL * B.CCY_RATE
                                 ELSE
                                  0
                               END) - SUM(CASE
                                            WHEN T.ITEM_CD IN ('13010404',
                                                               '13010504',
                                                               '13010408',
                                                               '13010508',
                                                               '13010304') THEN --公允价值变动
                                             T.DEBIT_BAL * B.CCY_RATE
                                            ELSE
                                             0
                                          END) AS BAL
                      FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL T
                      LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                        ON T.DATA_DATE = B.DATA_DATE
                       AND T.CURR_CD = B.BASIC_CCY
                       AND B.FORWARD_CCY = 'CNY'
                     WHERE T.DATA_DATE = IS_DATE
                       AND T.ORG_NUM = '990000'
                       AND T.ITEM_CD IN ('1301',
                                         '13010404',
                                         '13010504',
                                         '13010408',
                                         '13010508',
                                         '13010304') --add by djh 资管 20230808
                    --信用卡
                    UNION ALL
                    SELECT '信用卡', SUM(T.DEBIT_BAL * B.CCY_RATE) AS BAL
                      FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL T
                      LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                        ON T.DATA_DATE = B.DATA_DATE
                       AND T.CURR_CD = B.BASIC_CCY
                       AND B.FORWARD_CCY = 'CNY'
                     WHERE T.DATA_DATE = IS_DATE
                       AND T.ORG_NUM = '990000'
                       AND T.ITEM_CD IN (/*'130604',*/ '130303')))
    HAVING SUM(G21) - SUM(ZZ) <> 0;
  COMMIT;

  V_STEP_FLAG := 1;
  V_STEP_DESC := 'G21的1.6各项贷款与总账校验完成';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

V_STEP_ID   := V_STEP_ID + 1;
  V_STEP_FLAG := 0;
  V_STEP_DESC := 'G21的 1.9其他有确定到期日的资产与总账校验开始';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);
  -- G21的 1.9其他有确定到期日的资产与总账校验
INSERT  INTO PM_RSDATA.CBRC_CHECK_DATA 
  (DT_DATE, --校验日期
   CHECK_TPYE, --校验类型
   BALANCE1, --校验表1值
   BALANCE2, --校验表2值
   BALANCE, --差异
   REMARK, --备注
   FLAG)
  SELECT  IS_DATE,
         'G21 1.9其他有确定到期日的资产 = 利息（应计利息+应收利息【包含营改增挂账利息】））+贵金属+财政性轧差',
         SUM(G21),
         SUM(ZZ),
         SUM(G21) - SUM(ZZ),
         '1104系统与总账校验',
         '02' AS FLAG
    FROM (SELECT ROUND(SUM(T.ITEM_VAL)) G21, 0 ZZ
            FROM PM_RSDATA.CBRC_A_REPT_ITEM_RESULT T
           WHERE REPLACE(DATA_DATE, '-', '') = IS_DATE
             AND T.REP_NUM = 'G21'
             AND T.ITEM_NUM LIKE 'G21_1.8%'
             AND T.ITEM_NUM NOT LIKE 'G21_1.8%2018' --防止1.8持有同业存单的数据进来
             AND T.ORG_NUM = '990000'
          UNION ALL
          SELECT 0 G21, ROUND(SUM(DEBIT_BAL)) ZZ
            FROM (SELECT '利息' AS ITEM,
                         SUM(A.DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL,
                         0 AS CREDIT_BAL
                    FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                      ON A.DATA_DATE = B.DATA_DATE
                     AND A.CURR_CD = B.BASIC_CCY
                     AND B.FORWARD_CCY = 'CNY'
                   WHERE A.DATA_DATE = IS_DATE
                     AND A.ITEM_CD IN ('113201', '113202', '113203') ---add by djh
                     AND A.ORG_NUM = '990000'
                  UNION ALL
                  --贵金属
                  SELECT '贵金属',
                         SUM(A.DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL,
                         0 AS CREDIT_BAL
                    FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                      ON A.DATA_DATE = B.DATA_DATE
                     AND A.CURR_CD = B.BASIC_CCY
                     AND B.FORWARD_CCY = 'CNY'
                   WHERE A.DATA_DATE = IS_DATE
                     AND A.ITEM_CD = '1431'
                     AND A.ORG_NUM = '990000'
                  UNION ALL
                  --财政性轧差
                  SELECT '财政性轧差',
                         SUM(A.DEBIT_BAL) AS DEBIT_BAL,
                         0 AS CREDIT_BAL
                    FROM (SELECT IS_DATE,
                                 COALESCE(FA.ORG_UNIT_ID, FB.ORG_UNIT_ID) AS ORG_NUM,
                                 '1.8.B',
                                 CASE
                                   WHEN COALESCE(FA.CUR_BAL, 0) -
                                        COALESCE(FB.CUR_BAL, 0) >= 0 THEN
                                    COALESCE(FA.CUR_BAL, 0) -
                                    COALESCE(FB.CUR_BAL, 0)
                                   ELSE
                                    0
                                 END DEBIT_BAL,
                                 COALESCE(FA.ISO_CURRENCY_CD,
                                          FB.ISO_CURRENCY_CD),
                                 '100303' AS ITEM_CD
                            FROM (SELECT A.DATA_DATE AS AS_OF_DATE,
                                         A.ORG_NUM AS ORG_UNIT_ID,
                                         A.CURR_CD AS ISO_CURRENCY_CD,
                                         SUM(ABS(COALESCE(DEBIT_BAL *
                                                          B.CCY_RATE,
                                                          0) -
                                                 COALESCE(CREDIT_BAL *
                                                          B.CCY_RATE,
                                                          0))) AS CUR_BAL
                                    FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                                    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                                      ON A.DATA_DATE = B.DATA_DATE
                                     AND A.CURR_CD = B.BASIC_CCY
                                     AND B.FORWARD_CCY = 'CNY'
                                   WHERE A.DATA_DATE = IS_DATE
                                     AND ITEM_CD = '100303'
                                     AND ORG_NUM NOT LIKE '%0000'
                                     AND A.ORG_NUM NOT LIKE '5%'
                                     AND A.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇
                                     AND ORG_NUM NOT IN
                                         ( /*'510000',*/ --磐石吉银村镇银行
                                          '222222', --东盛除双阳汇总
                                          '333333', --新双阳
                                          '444444', --净月潭除双阳
                                          '555555') --长春分行（除双阳、榆树、农安）
                                   GROUP BY A.DATA_DATE, A.ORG_NUM, A.CURR_CD) FA
                            FULL OUTER JOIN (SELECT A.DATA_DATE AS AS_OF_DATE,
                                                   A.ORG_NUM AS ORG_UNIT_ID,
                                                   A.CURR_CD AS ISO_CURRENCY_CD,
                                                   SUM(ABS(COALESCE(CREDIT_BAL,
                                                                    0) -
                                                           COALESCE(DEBIT_BAL,
                                                                    0))) AS CUR_BAL
                                              FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                                              LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                                                ON A.DATA_DATE = B.DATA_DATE
                                               AND A.CURR_CD = B.BASIC_CCY
                                               AND B.FORWARD_CCY = 'CNY'
                                             WHERE A.DATA_DATE = IS_DATE
                                               AND ITEM_CD IN
                                                   (--'201103', --[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款，原逻辑中剔除]
                                                    '201104',
                                                    '201105',
                                                    '201106',
                                                    '2005' --alter by 20250527 国库存款科目新增
                                                   /* '2008',
                                                    '2009'*/)
                                               AND ORG_NUM NOT LIKE '%0000'
                                               AND A.ORG_NUM NOT LIKE '5%'
                                               AND A.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇
                                               AND ORG_NUM NOT IN
                                                   ( /*'510000',*/ --磐石吉银村镇银行
                                                    '222222', --东盛除双阳汇总
                                                    '333333', --新双阳
                                                    '444444', --净月潭除双阳
                                                    '555555') --长春分行（除双阳、榆树、农安）
                                             GROUP BY A.DATA_DATE,
                                                      A.ORG_NUM,
                                                      A.CURR_CD) FB
                              ON FA.AS_OF_DATE = FB.AS_OF_DATE
                             AND FA.ORG_UNIT_ID = FB.ORG_UNIT_ID
                             AND FA.ISO_CURRENCY_CD = FB.ISO_CURRENCY_CD) A
                  --add by djh 资管 20230808
                  UNION ALL
                  SELECT '资管利息数据',
                         SUM(B.RECVAPAY_AMT * T2.CCY_RATE) AS DEBIT_BAL,
                         0 AS CREDIT_BAL
                    FROM PM_RSDATA.SMTMODS_L_FIMM_PRODUCT A
                   INNER JOIN PM_RSDATA.SMTMODS_L_FIMM_PRODUCT_BAL B
                      ON B.DATA_DATE = IS_DATE
                     AND A.PRODUCT_CODE = B.PRODUCT_CODE
                     AND A.PROCEEDS_CHARACTER = 'c' --收益特征是非保本浮动收益类
                     AND A.BANK_ISSUE_FLG = 'Y' --只统计本行发行的，若本行代销的他行发行的理财产品不纳入统计
                    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                      ON T2.DATA_DATE = IS_DATE
                     AND T2.BASIC_CCY = B.CURR_CD
                     AND T2.FORWARD_CCY = 'CNY'
                     AND A.ORG_NUM NOT LIKE '5%'
                     AND A.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇
                   WHERE A.DATA_DATE = IS_DATE
                  UNION ALL
                  SELECT '资管垫资款',
                         SUM(DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL,
                         0 AS CREDIT_BAL
                    FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                      ON A.DATA_DATE = B.DATA_DATE
                     AND A.CURR_CD = B.BASIC_CCY
                     AND B.FORWARD_CCY = 'CNY'
                   WHERE A.DATA_DATE = IS_DATE
                     AND ITEM_CD = '12210201' --jrsj垫资款 即 应收业务周转金 一直放次日
                     AND ORG_NUM = '009816'
                     AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
                  UNION ALL
                  --add by djh 金融市场部 20231115
                  SELECT '金融市场部应收利息',
                         SUM(T.DEBIT_BAL * B.CCY_RATE) - 19910000 AS DEBIT_BAL, --[2025-09-19] [狄家卉]  债券逾期特殊处理19910000元 ，总账比明细多
                         0 AS CREDIT_BAL
                    FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL T
                    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                      ON T.DATA_DATE = B.DATA_DATE
                     AND T.CURR_CD = B.BASIC_CCY
                     AND B.FORWARD_CCY = 'CNY'
                   WHERE T.DATA_DATE = IS_DATE
                     AND T.ORG_NUM = '009804'
                     AND T.ITEM_CD IN
                         ('113205', '113207', '113208', '113209') --113205交易性债券投资应收应计利息、 113207债权投资债券应收利息 、113208其他债权投资债券应收利息，113209买入返售金融资产应收利息
                     AND T.CURR_CD NOT IN ('BWB', 'USY', 'CFC')
                  --add by djh 同业金融部 20231115
                  UNION ALL
                  SELECT '同业金融部应收利息',
                         SUM(T.DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL,
                         0 AS CREDIT_BAL
                    FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL T
                    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                      ON T.DATA_DATE = B.DATA_DATE
                     AND T.CURR_CD = B.BASIC_CCY
                     AND B.FORWARD_CCY = 'CNY'
                   WHERE T.DATA_DATE = IS_DATE
                     AND T.ORG_NUM = '009820' --同业金融部
                     AND T.ITEM_CD = '11320504' --同业金融部的同业存单均放在交易性债券投资应计利息
                     AND T.CURR_CD NOT IN ('BWB', 'USY', 'CFC')
                  --[2025-09-19] [狄家卉] 增加总账部分差异
                  /*1011存放同业对应113211存放同业应收利息 （01【1011存放同业】）
                  1031存出保证金对应113212存出保证金应收利息 （01【1031存出保证金】）
                  */
                  UNION ALL
                  SELECT '同业金融部应收利息',
                         SUM(T.DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL,
                         0 AS CREDIT_BAL
                    FROM PM_RSDATA.SMTMODS_L_FINA_GL T
                    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                      ON T.DATA_DATE = B.DATA_DATE
                     AND T.CURR_CD = B.BASIC_CCY
                     AND B.FORWARD_CCY = 'CNY'
                   WHERE T.DATA_DATE = IS_DATE
                     AND T.ORG_NUM = '990000'
                     AND T.ITEM_CD IN ('113211', '113212')
                     AND T.CURR_CD NOT IN ('BWB', 'USY', 'CFC')

                  /*1302拆出资金对应113204拆出资金应收利息 （02【1302拆出资金】）
                  11010302交易性基金投资成本对应的113205交易性金融资产应收利息（06【基金】）
                  15010201债权投资特定目的载体投资投资成本对应的113207债权投资应收利息（08【AC账户】） 包含了140万固定值放逾期
                  11010303 交易性特定目的载体投资投资成本（07【委外投资】）  无利息
                  */
                  UNION ALL
                  SELECT '同业金融部应收利息',
                         SUM(T.DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL,
                         0 AS CREDIT_BAL
                    FROM PM_RSDATA.SMTMODS_L_FINA_GL T
                    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                      ON T.DATA_DATE = B.DATA_DATE
                     AND T.CURR_CD = B.BASIC_CCY
                     AND B.FORWARD_CCY = 'CNY'
                   WHERE T.DATA_DATE = IS_DATE
                     AND T.ORG_NUM = '009820'
                     AND T.ITEM_CD IN ('113204', '113205', '113207')
                     AND T.CURR_CD NOT IN ('BWB', 'USY', 'CFC')
                  UNION ALL
                  SELECT '同业金融部应收利息',
                         SUM(T.CREDIT_BAL) AS DEBIT_BAL,
                         0 AS CREDIT_BAL
                    FROM PM_RSDATA.SMTMODS_L_FINA_GL T
                   WHERE DATA_DATE = IS_DATE
                     AND CURR_CD = 'BWB'
                     AND ITEM_CD IN ('12310101') -- 12310101 其他应收款坏账准备固定值放逾期 63.32万
                     AND T.ORG_NUM = '009820'
                  UNION ALL
                  SELECT '投资银行部应收利息',
                         SUM(ACCRUAL + QTYSK) AS DEBIT_BAL,
                         0 AS CREDIT_BAL
                    FROM (select D.DATA_DATE,D.ACCT_NUM,D.ACCRUAL,D.QTYSK
                            FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST D --投资业务信息表
                           INNER JOIN PM_RSDATA.SMTMODS_L_AGRE_OTHER_SUBJECT_INFO C -- 其他标的物信息表
                              ON D.ACCT_NUM = C.SUBJECT_CD
                             AND C.DATA_DATE = IS_DATE
                            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
                              ON U.CCY_DATE =IS_DATE
                             AND U.BASIC_CCY = D.CURR_CD --基准币种
                             AND U.FORWARD_CCY = 'CNY' --折算币种
                             AND U.DATA_DATE = IS_DATE
                           WHERE D.DATA_DATE = IS_DATE
                             AND D.ORG_NUM = '009817') T
                    LEFT JOIN (SELECT Q.ACCT_NUM,
                                     Q.PLA_MATURITY_DATE,
                                     ROW_NUMBER() OVER(PARTITION BY Q.ACCT_NUM ORDER BY Q.PLA_MATURITY_DATE) RN
                                FROM PM_RSDATA.SMTMODS_L_ACCT_FUND_MMFUND_PAYM_SCHED Q
                               WHERE Q.DATA_DATE = IS_DATE
                                 AND DATA_SOURCE = '投行业务'
                                 AND Q.PLA_MATURITY_DATE > IS_DATE) T1
                      ON T.ACCT_NUM = T1.ACCT_NUM
                     AND T1.RN = 1
                   WHERE T.DATA_DATE = IS_DATE
                        --AND T.FLAG = '09'
                        --由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第1.9项,除去逾期部分其余不在系统取数，业务手填
                     AND (T1.PLA_MATURITY_DATE IS NULL OR
                         T1.PLA_MATURITY_DATE < IS_DATE)
                  --[2025-09-19] [狄家卉]  增加总账部分差异
                  ))
  HAVING SUM(G21) - SUM(ZZ) <> 0;
  COMMIT;

  V_STEP_FLAG := 1;
  V_STEP_DESC := 'G21的 1.9其他有确定到期日的资产与总账校验完成';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);
---------------------------------------------------------贷款 ---------------------------------------------------------
---------------------------------------------------------存款 ---------------------------------------------------------

  V_STEP_ID   := V_STEP_ID + 1;
  V_STEP_FLAG := 0;
  V_STEP_DESC := 'G21的 3.5各项存款与总账校验开始';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);
--G21 3.5各项存款
INSERT  INTO PM_RSDATA.CBRC_CHECK_DATA 
  (DT_DATE, --校验日期
   CHECK_TPYE, --校验类型
   BALANCE1, --校验表1值
   BALANCE2, --校验表2值
   BALANCE, --差异
   REMARK,--备注
   FLAG)
  SELECT  IS_DATE,
         'G21 3.5各项存款',
         SUM(G21),
         SUM(ZZ),
         SUM(G21) - SUM(ZZ),
         '1104系统与总账校验',
         '03' AS FLAG
    FROM (SELECT ROUND(SUM(T.ITEM_VAL)) G21, 0 ZZ
            FROM PM_RSDATA.CBRC_A_REPT_ITEM_RESULT T
           WHERE REPLACE(DATA_DATE, '-', '') = IS_DATE
             AND T.REP_NUM = 'G21'
             AND (T.ITEM_NUM LIKE 'G21_3.5.1%' OR
                  T.ITEM_NUM LIKE 'G21_3.5.2%')
             AND T.ORG_NUM = '990000'
          UNION ALL
          SELECT 0 G21, SUM(T.CREDIT_BAL* B.CCY_RATE  - T.DEBIT_BAL* B.CCY_RATE) AS ZZ --add by djh
            FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL T
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
              ON T.DATA_DATE = B.DATA_DATE
             AND T.CURR_CD = B.BASIC_CCY
             AND B.FORWARD_CCY = 'CNY'
           WHERE T.DATA_DATE = IS_DATE
             AND T.ORG_NUM = '990000'
             AND (T.ITEM_CD IN ('20110205',
                                '20110110',
                                '20110202',
                                '20110203',
                                '20110204',
                                '20110211',
                                '201107',
                                '2010',  --alter by 20250527 JLBA202504180011
                                '20110103',
                                '20110104',
                                '20110105',
                                '20110106',
                                '20110107',
                                '20110108',
                                '20110109',
                                '20110208',
                                '20110113',
                                '20110114',
                                '20110115',
                                '20110209',
                                '20110210',
                                '20110207',
                                '20110112',
                                '20110201',
                                '20110101',
                                '20110102',
                                '20110111',
                                '20110206',
                                '2013',
                                '2014',
                                 '2008','2009','201103','224101'--[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款，原逻辑中剔除]
                                ) OR
                 T.ITEM_CD IN ('20120204', '20120106'))
             and T.CREDIT_BAL <> 0
             AND T.CURR_CD <> 'BWB')
  HAVING SUM(G21) - SUM(ZZ) <> 0;
COMMIT;
  V_STEP_FLAG := 1;
  V_STEP_DESC := 'G21的 3.5各项存款与总账校验完成';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);


  V_STEP_ID   := V_STEP_ID + 1;
  V_STEP_FLAG := 0;
  V_STEP_DESC := 'G21的 3.8其他有确定到期日的负债与总账校验开始';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

--G21 3.8其他有确定到期日的负债

INSERT  INTO PM_RSDATA.CBRC_CHECK_DATA 
  (DT_DATE, --校验日期
   CHECK_TPYE, --校验类型
   BALANCE1, --校验表1值
   BALANCE2, --校验表2值
   BALANCE, --差异
   REMARK, --备注
   FLAG)
  SELECT  IS_DATE,
         'G21 3.8其他有确定到期日的负债',
         SUM(G21),
         SUM(ZZ),
         SUM(G21) - SUM(ZZ),
         '1104系统与总账校验',
         '04' AS FLAG
    FROM (SELECT ROUND(SUM(T.ITEM_VAL)) G21, 0 ZZ
            FROM PM_RSDATA.CBRC_A_REPT_ITEM_RESULT T
           WHERE REPLACE(DATA_DATE, '-', '') = IS_DATE
             AND T.REP_NUM = 'G21'
             AND T.ITEM_NUM LIKE 'G21_3.8%'
             AND T.ITEM_NUM <> 'G21_3.8.G'
             AND T.ORG_NUM = '990000'
          UNION ALL
          SELECT 0 G21,
                 SUM(CASE
                       WHEN T.ITEM_CD = '2231' THEN -- 260应付利息
                        T.CREDIT_BAL * B.CCY_RATE
                       ELSE
                        0
                     END) - SUM(CASE WHEN T.ITEM_CD ='22311301' THEN -- [2025-09-19] [狄家卉] 明细中没有，但是总账有,康哥手工把2101交易性金融负债本金业务卖空，产生22311301的交易性金融负债应付利息放在【3.9其他没有确定到期日的负债】
                                T.CREDIT_BAL * B.CCY_RATE  --[2025-09-19] [狄家卉] 由于本金在G21表没有地方放，因此利息也去掉比对
                             ELSE
                              0
                           END) AS ZZ
            FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL T
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
              ON T.DATA_DATE = B.DATA_DATE
             AND T.CURR_CD = B.BASIC_CCY
             AND B.FORWARD_CCY = 'CNY'
           WHERE T.DATA_DATE = IS_DATE
             AND T.ORG_NUM = '990000'
             AND T.ITEM_CD IN ('2231','22311301' /*, '223108', '223199'*/)
             and T.CREDIT_BAL <> 0
             AND T.CURR_CD <> 'BWB'
          UNION ALL
          SELECT 0, SUM(A.DEBIT_BAL) AS ZZ --财政性轧差负债方
            FROM (SELECT IS_DATE,
                         COALESCE(FA.ORG_UNIT_ID, FB.ORG_UNIT_ID) AS ORG_NUM,
                         '3.8.B',
                         CASE
                           WHEN COALESCE(FB.CUR_BAL, 0) -
                                COALESCE(FA.CUR_BAL, 0) >= 0 THEN
                            COALESCE(FB.CUR_BAL, 0) - COALESCE(FA.CUR_BAL, 0)
                           ELSE
                            0
                         END DEBIT_BAL,
                         COALESCE(FA.ISO_CURRENCY_CD, FB.ISO_CURRENCY_CD),
                         '201103' AS ITEM_CD
                    FROM (SELECT A.DATA_DATE AS AS_OF_DATE,
                                 A.ORG_NUM AS ORG_UNIT_ID,
                                 A.CURR_CD AS ISO_CURRENCY_CD,
                                 SUM(ABS(COALESCE(DEBIT_BAL * B.CCY_RATE, 0) -
                                         COALESCE(CREDIT_BAL * B.CCY_RATE, 0))) AS CUR_BAL
                            FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                              ON A.DATA_DATE = B.DATA_DATE
                             AND A.CURR_CD = B.BASIC_CCY
                             AND B.FORWARD_CCY = 'CNY'
                           WHERE A.DATA_DATE = IS_DATE
                             AND ITEM_CD = '100303'
                             AND A.CURR_CD <> 'BWB' --本外币合计去掉
                             AND ORG_NUM NOT LIKE '%0000'
                             AND A.ORG_NUM NOT LIKE '5%'
                             AND A.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇
                             AND ORG_NUM NOT IN ( /*'510000',*/ --磐石吉银村镇银行
                                                 '222222', --东盛除双阳汇总
                                                 '333333', --新双阳
                                                 '444444', --净月潭除双阳
                                                 '555555') --长春分行（除双阳、榆树、农安）
                           GROUP BY A.DATA_DATE, A.ORG_NUM, A.CURR_CD) FA
                    FULL OUTER JOIN (SELECT A.DATA_DATE AS AS_OF_DATE,
                                           A.ORG_NUM AS ORG_UNIT_ID,
                                           A.CURR_CD AS ISO_CURRENCY_CD,
                                           SUM(ABS(COALESCE(CREDIT_BAL, 0) -
                                                   COALESCE(DEBIT_BAL, 0))) AS CUR_BAL
                                      FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                                      LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                                        ON A.DATA_DATE = B.DATA_DATE
                                       AND A.CURR_CD = B.BASIC_CCY
                                       AND B.FORWARD_CCY = 'CNY'
                                     WHERE A.DATA_DATE = IS_DATE
                                       AND ITEM_CD IN (--'201103',[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款，原逻辑中剔除]
                                                       '201104',
                                                       '201105',
                                                       '201106',
                                                       '2005'/*,
                                                       '2008',
                                                       '2009'*/ --alter by 20250527 国库存款科目新增  --[JLBA202507210012][石雨][修改内容：2008 2009，原逻辑中剔除属于单位存款]
                                                       )
                                       AND A.CURR_CD <> 'BWB' --本外币合计去掉
                                       AND ORG_NUM NOT LIKE '%0000'
                                       AND A.ORG_NUM NOT LIKE '5%'
                                       AND A.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇
                                       AND ORG_NUM NOT IN
                                           ( /*'510000',*/ --磐石吉银村镇银行
                                            '222222', --东盛除双阳汇总
                                            '333333', --新双阳
                                            '444444', --净月潭除双阳
                                            '555555') --长春分行（除双阳、榆树、农安）
                                     GROUP BY A.DATA_DATE,
                                              A.ORG_NUM,
                                              A.CURR_CD) FB
                      ON FA.AS_OF_DATE = FB.AS_OF_DATE
                     AND FA.ORG_UNIT_ID = FB.ORG_UNIT_ID
                     AND FA.ISO_CURRENCY_CD = FB.ISO_CURRENCY_CD) A
          UNION ALL
          --[2025-09-19] [狄家卉]  200303转贷款 本金+利息均放到3.8项 ，上面已放利息，因此此处补充本金部分
          SELECT 0, SUM(T.CREDIT_BAL * B.CCY_RATE) AS ZZ
            FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL T
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
              ON T.DATA_DATE = B.DATA_DATE
             AND T.CURR_CD = B.BASIC_CCY
             AND B.FORWARD_CCY = 'CNY'
           WHERE T.DATA_DATE = IS_DATE
             AND T.CREDIT_BAL <> 0
             AND T.CURR_CD <> 'BWB'
             AND T.ORG_NUM = '009820'
             AND T.ITEM_CD = '200303'
           )
  HAVING SUM(G21) - SUM(ZZ) <> 0;
COMMIT;

  V_STEP_FLAG := 1;
  V_STEP_DESC := 'G21的 3.8其他有确定到期日的负债与总账校验完成';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);
---------------------------------------------------------存款 ---------------------------------------------------------
  V_STEP_ID   := V_STEP_ID + 1;
  V_STEP_FLAG := 0;
  V_STEP_DESC := 'G21贷款合计与G0102各项贷款合计校验开始';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);
  -- G21的 G0102各项贷款合计校验
INSERT   INTO PM_RSDATA.CBRC_CHECK_DATA 
  (DT_DATE, --校验日期
   CHECK_TPYE, --校验类型
   BALANCE1, --校验表1值
   BALANCE2, --校验表2值
   BALANCE, --差异
   REMARK, --备注
   FLAG)
  SELECT  DATA_DATE,
        CHECK_NAME,
        G21,
        G0102,
        DIFFERENCE,
        SYSTEM_CHECK,
        FLAG  FROM 
       (SELECT 
          IS_DATE AS DATA_DATE,
           'G21贷款合计与G0102各项贷款合计校验' AS CHECK_NAME,
           SUM(G21) AS G21,
           SUM(G0102) AS G0102,
           SUM(G21) - SUM(G0102) AS DIFFERENCE,
           '1104系统表间校验' AS SYSTEM_CHECK,
           '05' AS FLAG
       FROM  (SELECT ROUND(SUM(T.ITEM_VAL)) G0102, 0 G21
              FROM PM_RSDATA.CBRC_A_REPT_ITEM_RESULT T
             WHERE REPLACE(DATA_DATE, '-', '') = IS_DATE
               AND ITEM_NUM = 'G01_2_2.A.2016'
               AND ORG_NUM = '990000'
            UNION ALL
            SELECT 0 G0102, ROUND(SUM(T.ITEM_VAL)) G21
              FROM PM_RSDATA.CBRC_A_REPT_ITEM_RESULT T
             WHERE REPLACE(DATA_DATE, '-', '') = IS_DATE
               AND T.REP_NUM = 'G21'
               AND T.ITEM_NUM LIKE 'G21_1.6.H'
               AND T.ORG_NUM = '990000')
             GROUP BY  DATA_DATE, CHECK_NAME, SYSTEM_CHECK, FLAG ) T 
WHERE G21 - G0102 <> 0;

  COMMIT;

  V_STEP_FLAG := 1;
  V_STEP_DESC := 'G21贷款合计与G0102各项贷款合计校验完成';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

  V_STEP_ID   := V_STEP_ID + 1;
  V_STEP_FLAG := 0;
  V_STEP_DESC := 'G21逾期贷款与G0102逾期贷款校验开始';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);
  -- G21的 G0102逾期贷款校验
  INSERT  INTO PM_RSDATA.CBRC_CHECK_DATA 
    (DT_DATE, --校验日期
     CHECK_TPYE, --校验类型
     BALANCE1, --校验表1值
     BALANCE2, --校验表2值
     BALANCE, --差异
     REMARK,--备注
     FLAG)
    SELECT  IS_DATE,
           'G0102 逾期贷款 = G21逾期贷款',
           SUM(G0102),
           SUM(G21),
           SUM(G0102) - SUM(G21),
           '1104系统表间校验',
           '06' AS FLAG
      FROM (SELECT ROUND(SUM(T.ITEM_VAL)) G0102, 0 G21
              FROM PM_RSDATA.CBRC_A_REPT_ITEM_RESULT T
             WHERE REPLACE(DATA_DATE, '-', '') = IS_DATE
               AND ITEM_NUM = 'G01_2_2.A.2016'
               AND ORG_NUM = '990000'
            UNION ALL
            SELECT 0 G0102, ROUND(SUM(T.ITEM_VAL)) G21
              FROM PM_RSDATA.CBRC_A_REPT_ITEM_RESULT T
             WHERE REPLACE(DATA_DATE, '-', '') = IS_DATE
               AND T.REP_NUM = 'G21'
               AND T.ITEM_NUM LIKE 'G21_1.6.H'
               AND T.ORG_NUM = '990000')
    HAVING SUM(G0102) - SUM(G21) <> 0;
  COMMIT;

  V_STEP_FLAG := 1;
  V_STEP_DESC := 'G21逾期贷款与G0102逾期贷款校验完成';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);


  V_STEP_ID   := V_STEP_ID + 1;
  V_STEP_FLAG := 0;
  V_STEP_DESC := '特殊处理校验开始';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);
 --[2025-09-19] [狄家卉]  增加总账部分差异
--就是FLAG='02'的明细机构级差异数据
-- 1.9其他有确定到期日的资产取值所有利息，由于贷款与总账轧差需要汇总至00结尾机构，但是其他业务还是原末级例如01结尾的，
--RESULT汇总时，会冲掉00结尾数据，导致数据缺失，在此比对出差值后插入逻辑，抵消此差异
INSERT    INTO PM_RSDATA.CBRC_CHECK_DATA_DEAL 
  (DT_DATE, --校验日期
   CHECK_TPYE, --校验类型
   BALANCE1, --校验表1值
   BALANCE2, --校验表2值
   BALANCE, --差异
   REMARK, --备注
   FLAG,
   ORG_NUM)--机构
  SELECT IS_DATE,
         '1.9其他有确定到期日的资产抵消利息',
         A.ITEM_VAL AS BALANCE1, --G21汇总后机构
         B.ITEM_VAL AS BALANCE2, --总账机构
         NVL(A.ITEM_VAL, 0) - NVL(B.ITEM_VAL, 0) AS BALANCE,
         '特殊处理' AS REMARK, --1104系统与总账校验
         '07' AS FLAG,
         'G21机构：'||NVL(A.ORG_NUM,'空')|| '  ' || '总账机构：'|| NVL(B.ORG_NUM,'空') AS ORG_NUM --  G21汇总后机构拼接总账机构
    FROM (SELECT T.ORG_NUM, ROUND(SUM(T.ITEM_VAL)) ITEM_VAL
            FROM PM_RSDATA.CBRC_A_REPT_ITEM_RESULT T
           WHERE REPLACE(DATA_DATE, '-', '') = IS_DATE
             AND T.REP_NUM = 'G21'
             AND T.ITEM_NUM LIKE 'G21_1.8%'
             AND T.ITEM_NUM NOT LIKE 'G21_1.8%2018' --防止1.8持有同业存单的数据进来
             AND T.ORG_NUM IN
                 (SELECT TT.INST_ID
                    FROM CBRC_UPRR_U_BASE_INST TT
                   WHERE TT.PARENT_INST_ID IN ('010000',
                                               '020000',
                                               '030000',
                                               '040000',
                                               '050000',
                                               '060000',
                                               '070000',
                                               '080000',
                                               '090000',
                                               '100000',
                                               '110000'))  --找到分行所有下级进行核对
             AND T.ITEM_VAL <> 0
           GROUP BY T.ORG_NUM) A
    FULL JOIN (SELECT KK.ORG_NUM, ROUND(SUM(DEBIT_BAL)) ITEM_VAL
                 FROM (SELECT A.ORG_NUM,
                              SUM(A.DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL
                         FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                           ON A.DATA_DATE = B.DATA_DATE
                          AND A.CURR_CD = B.BASIC_CCY
                          AND B.FORWARD_CCY = 'CNY'
                        WHERE A.DATA_DATE = IS_DATE
                          AND A.ITEM_CD IN ('113201', '113202', '113203') ---ADD BY DJH
                          AND A.ORG_NUM NOT LIKE '%0000'
                          AND A.ORG_NUM NOT LIKE '5%'
                          AND A.ORG_NUM NOT LIKE '6%'
                        GROUP BY A.ORG_NUM
                       UNION ALL
                       --财政性轧差
                       SELECT --6864642.75
                        ORG_NUM, SUM(A.DEBIT_BAL) AS DEBIT_BAL
                         FROM (SELECT IS_DATE,
                                      COALESCE(FA.ORG_UNIT_ID, FB.ORG_UNIT_ID) AS ORG_NUM,
                                      '1.8.B',
                                      CASE
                                        WHEN COALESCE(FA.CUR_BAL, 0) -
                                             COALESCE(FB.CUR_BAL, 0) >= 0 THEN
                                         COALESCE(FA.CUR_BAL, 0) -
                                         COALESCE(FB.CUR_BAL, 0)
                                        ELSE
                                         0
                                      END DEBIT_BAL,
                                      COALESCE(FA.ISO_CURRENCY_CD,
                                               FB.ISO_CURRENCY_CD),
                                      '100303' AS ITEM_CD
                                 FROM (SELECT A.DATA_DATE AS AS_OF_DATE,
                                              A.ORG_NUM AS ORG_UNIT_ID,
                                              A.CURR_CD AS ISO_CURRENCY_CD,
                                              SUM(ABS(COALESCE(DEBIT_BAL *
                                                               B.CCY_RATE,
                                                               0) -
                                                      COALESCE(CREDIT_BAL *
                                                               B.CCY_RATE,
                                                               0))) AS CUR_BAL
                                         FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                                           ON A.DATA_DATE = B.DATA_DATE
                                          AND A.CURR_CD = B.BASIC_CCY
                                          AND B.FORWARD_CCY = 'CNY'
                                        WHERE A.DATA_DATE = IS_DATE
                                          AND ITEM_CD = '100303'
                                          AND ORG_NUM NOT LIKE '%0000'
                                          AND A.ORG_NUM NOT LIKE '5%'
                                          AND A.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇
                                          AND ORG_NUM NOT IN
                                              ( /*'510000',*/ --磐石吉银村镇银行
                                               '222222', --东盛除双阳汇总
                                               '333333', --新双阳
                                               '444444', --净月潭除双阳
                                               '555555') --长春分行（除双阳、榆树、农安）
                                        GROUP BY A.DATA_DATE,
                                                 A.ORG_NUM,
                                                 A.CURR_CD) FA
                                 FULL OUTER JOIN (SELECT A.DATA_DATE AS AS_OF_DATE,
                                                        A.ORG_NUM AS ORG_UNIT_ID,
                                                        A.CURR_CD AS ISO_CURRENCY_CD,
                                                        SUM(ABS(COALESCE(CREDIT_BAL,
                                                                         0) -
                                                                COALESCE(DEBIT_BAL,
                                                                         0))) AS CUR_BAL
                                                   FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                                                   LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                                                     ON A.DATA_DATE =B.DATA_DATE
                                                    AND A.CURR_CD =B.BASIC_CCY
                                                    AND B.FORWARD_CCY = 'CNY'
                                                  WHERE A.DATA_DATE =IS_DATE
                                                    AND ITEM_CD IN
                                                        ('201103',
                                                         '201104',
                                                         '201105',
                                                         '201106',
                                                         '2005', --ALTER BY 20250527 国库存款科目新增
                                                         '2008',
                                                         '2009')
                                                    AND ORG_NUM NOT LIKE
                                                        '%0000'
                                                    AND A.ORG_NUM NOT LIKE '5%'
                                                    AND A.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇
                                                    AND ORG_NUM NOT IN
                                                        ( /*'510000',*/ --磐石吉银村镇银行
                                                         '222222', --东盛除双阳汇总
                                                         '333333', --新双阳
                                                         '444444', --净月潭除双阳
                                                         '555555') --长春分行（除双阳、榆树、农安）
                                                  GROUP BY A.DATA_DATE,
                                                           A.ORG_NUM,
                                                           A.CURR_CD) FB
                                   ON FA.AS_OF_DATE = FB.AS_OF_DATE
                                  AND FA.ORG_UNIT_ID = FB.ORG_UNIT_ID
                                  AND FA.ISO_CURRENCY_CD = FB.ISO_CURRENCY_CD) A
                        WHERE A.DEBIT_BAL <> 0
                        GROUP BY ORG_NUM
                       --ADD BY DJH 资管 20230808
                       UNION ALL
                       SELECT '009816' AS ORG_NUM,
                              SUM(B.RECVAPAY_AMT * T2.CCY_RATE) AS DEBIT_BAL
                         FROM PM_RSDATA.SMTMODS_L_FIMM_PRODUCT A
                        INNER JOIN PM_RSDATA.SMTMODS_L_FIMM_PRODUCT_BAL B
                           ON B.DATA_DATE = IS_DATE
                          AND A.PRODUCT_CODE = B.PRODUCT_CODE
                          AND A.PROCEEDS_CHARACTER = 'C' --收益特征是非保本浮动收益类
                          AND A.BANK_ISSUE_FLG = 'Y' --只统计本行发行的，若本行代销的他行发行的理财产品不纳入统计
                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                           ON T2.DATA_DATE = IS_DATE
                          AND T2.BASIC_CCY = B.CURR_CD
                          AND T2.FORWARD_CCY = 'CNY'
                          AND A.ORG_NUM NOT LIKE '5%'
                          AND A.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇
                        WHERE A.DATA_DATE = IS_DATE
                       UNION ALL
                       SELECT '009816' AS ORG_NUM,
                              SUM(DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL
                         FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                           ON A.DATA_DATE = B.DATA_DATE
                          AND A.CURR_CD = B.BASIC_CCY
                          AND B.FORWARD_CCY = 'CNY'
                        WHERE A.DATA_DATE = IS_DATE
                          AND ITEM_CD = '12210201' --JRSJ垫资款 即 应收业务周转金 一直放次日
                          AND ORG_NUM = '009816'
                          AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
                       UNION ALL
                       --ADD BY DJH 金融市场部 20231115
                       SELECT '009804' AS ORG_NUM,
                              SUM(T.DEBIT_BAL * B.CCY_RATE) - 19910000 AS DEBIT_BAL --[2025-09-19] [狄家卉]  债券逾期特殊处理19910000元 ，总账比明细多
                         FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL T
                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                           ON T.DATA_DATE = B.DATA_DATE
                          AND T.CURR_CD = B.BASIC_CCY
                          AND B.FORWARD_CCY = 'CNY'
                        WHERE T.DATA_DATE = IS_DATE
                          AND T.ORG_NUM = '009804'
                          AND T.ITEM_CD IN
                              ('113205', '113207', '113208', '113209') --113205交易性债券投资应收应计利息、 113207债权投资债券应收利息 、113208其他债权投资债券应收利息，113209买入返售金融资产应收利息
                          AND T.CURR_CD NOT IN ('BWB', 'USY', 'CFC')
                       --ADD BY DJH 同业金融部 20231115
                       UNION ALL
                       SELECT '009820' AS ORG_NUM,
                              SUM(T.DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL
                         FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL T
                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                           ON T.DATA_DATE = B.DATA_DATE
                          AND T.CURR_CD = B.BASIC_CCY
                          AND B.FORWARD_CCY = 'CNY'
                        WHERE T.DATA_DATE = IS_DATE
                          AND T.ORG_NUM = '009820' --同业金融部
                          AND T.ITEM_CD = '11320504' --同业金融部的同业存单均放在交易性债券投资应计利息
                          AND T.CURR_CD NOT IN ('BWB', 'USY', 'CFC')
                       --[2025-09-19] [狄家卉] 增加总账部分差异
                       /*1011存放同业对应113211存放同业应收利息 （01【1011存放同业】）
                       1031存出保证金对应113212存出保证金应收利息 （01【1031存出保证金】）
                       */
                       UNION ALL --283952.958779
                       SELECT A.ORG_NUM,
                              SUM(A.DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL
                         FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                           ON A.DATA_DATE = B.DATA_DATE
                          AND A.CURR_CD = B.BASIC_CCY
                          AND B.FORWARD_CCY = 'CNY'
                        WHERE A.DATA_DATE = IS_DATE
                          AND A.ORG_NUM NOT LIKE '%0000'
                          AND A.ORG_NUM <> '999999'
                          AND A.ORG_NUM NOT LIKE '5%'
                          AND A.ORG_NUM NOT LIKE '6%'
                          AND A.ITEM_CD IN ('113211', '113212')
                          AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC')
                        GROUP BY A.ORG_NUM

                       /*1302拆出资金对应113204拆出资金应收利息 （02【1302拆出资金】）
                       11010302交易性基金投资成本对应的113205交易性金融资产应收利息（06【基金】）
                       15010201债权投资特定目的载体投资投资成本对应的113207债权投资应收利息（08【AC账户】）
                       11010303 交易性特定目的载体投资投资成本（07【委外投资】）  无利息
                       */
                       UNION ALL
                       SELECT '009820' AS ORG_NUM,
                              SUM(T.DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL
                         FROM PM_RSDATA.SMTMODS_L_FINA_GL T
                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                           ON T.DATA_DATE = B.DATA_DATE
                          AND T.CURR_CD = B.BASIC_CCY
                          AND B.FORWARD_CCY = 'CNY'
                        WHERE T.DATA_DATE = IS_DATE
                          AND T.ORG_NUM = '009820'
                          AND T.ITEM_CD IN ('113204', '113205', '113207')
                          AND T.CURR_CD NOT IN ('BWB', 'USY', 'CFC')
                       UNION ALL
                       SELECT '009820' AS ORG_NUM,
                              SUM(T.CREDIT_BAL) AS DEBIT_BAL
                         FROM PM_RSDATA.SMTMODS_L_FINA_GL T
                        WHERE DATA_DATE = IS_DATE
                          AND CURR_CD = 'BWB'
                          AND ITEM_CD IN ('12310101') -- 12310101 其他应收款坏账准备固定值放逾期 63.32万
                          AND T.ORG_NUM = '009820'
                       UNION ALL
                       SELECT '009817' AS ORG_NUM,
                              SUM(ACCRUAL + QTYSK) AS DEBIT_BAL
                         FROM (SELECT D.DATA_DATE,
                                      D.ACCT_NUM,
                                      D.ACCRUAL,
                                      D.QTYSK
                                 FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST D --投资业务信息表
                                INNER JOIN PM_RSDATA.SMTMODS_L_AGRE_OTHER_SUBJECT_INFO C -- 其他标的物信息表
                                   ON D.ACCT_NUM = C.SUBJECT_CD
                                  AND C.DATA_DATE = IS_DATE
                                 LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
                                   ON U.CCY_DATE =IS_DATE
                                  AND U.BASIC_CCY = D.CURR_CD --基准币种
                                  AND U.FORWARD_CCY = 'CNY' --折算币种
                                  AND U.DATA_DATE = IS_DATE
                                WHERE D.DATA_DATE = IS_DATE
                                  AND D.ORG_NUM = '009817') T
                         LEFT JOIN (SELECT Q.ACCT_NUM,
                                          Q.PLA_MATURITY_DATE,
                                          ROW_NUMBER() OVER(PARTITION BY Q.ACCT_NUM ORDER BY Q.PLA_MATURITY_DATE) RN
                                     FROM PM_RSDATA.SMTMODS_L_ACCT_FUND_MMFUND_PAYM_SCHED Q
                                    WHERE Q.DATA_DATE = IS_DATE
                                      AND DATA_SOURCE = '投行业务'
                                      AND Q.PLA_MATURITY_DATE > IS_DATE) T1
                           ON T.ACCT_NUM = T1.ACCT_NUM
                          AND T1.RN = 1
                        WHERE T.DATA_DATE = IS_DATE
                             --AND T.FLAG = '09'
                             --由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第1.9项,除去逾期部分其余不在系统取数，业务手填
                          AND (T1.PLA_MATURITY_DATE IS NULL OR  T1.PLA_MATURITY_DATE < IS_DATE)
                       --[2025-09-19] [狄家卉]  增加总账部分差异
                       ) KK
                GROUP BY KK.ORG_NUM) B
      ON NVL(A.ORG_NUM, '9999999') = NVL(B.ORG_NUM, '9999999')
   WHERE NVL(A.ITEM_VAL, 0) <> NVL(B.ITEM_VAL, 0);

COMMIT;

INSERT  INTO PM_RSDATA.CBRC_CHECK_DATA 
  (DT_DATE, --校验日期
   CHECK_TPYE, --校验类型
   BALANCE1, --校验表1值
   BALANCE2, --校验表2值
   BALANCE, --差异
   REMARK, --备注
   FLAG)
  SELECT IS_DATE,
         CHECK_TPYE,
         SUM(BALANCE1) AS BALANCE1,
         SUM(BALANCE2) AS BALANCE2,
         SUM(BALANCE) AS BALANCE,
         REMARK,
         FLAG
    FROM PM_RSDATA.CBRC_CHECK_DATA_DEAL
   WHERE DT_DATE = IS_DATE
   GROUP BY CHECK_TPYE, REMARK, FLAG;

COMMIT;

 V_STEP_FLAG := 1;
  V_STEP_DESC := '特殊处理校验完成';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

  V_STEP_ID   := V_STEP_ID + 1;
  V_STEP_FLAG := 0;
  V_STEP_DESC := '插入CBRC_CHECK_DATA_RESULT开始';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);
--设置差值可接受范围
INSERT  INTO PM_RSDATA.CBRC_CHECK_DATA_RESULT 
  (DT_DATE, --校验日期
   CHECK_TPYE, --校验类型
   BALANCE1, --校验表1值
   BALANCE2, --校验表2值
   BALANCE, --差异
   REMARK, --备注
   FLAG)
/*  SELECT DT_DATE, CHECK_TPYE, BALANCE1, BALANCE2, BALANCE, REMARK, FLAG
 FROM PM_RSDATA.CBRC_CHECK_DATA T
WHERE DT_DATE = IS_DATE
  AND T.FLAG = '01'
  AND ABS(BALANCE) > 1*/
--add by DJH 20230928 补数据
--获取总分校验中ck_000001 贷款和还款计划表余额核对 结果值 与RESULT结果表进行校验
  SELECT  DT_DATE,
         CHECK_TPYE,
         BALANCE1,
         BALANCE2,
         ABS(ABS(BALANCE) - ABS(BALANCE_MINUS)) AS BALANCE,
         REMARK,
         FLAG
    FROM PM_RSDATA.CBRC_CHECK_DATA T
    LEFT JOIN ( --add by DJH 20231115 补数据
               SELECT ROUND(ABS(SUM(A.LOAN_TOTAL - B.LOAN_TOTAL))) AS BALANCE_MINUS
                 FROM (SELECT
                         LOAN_NUM,
                         SUM(LOAN_ACCT_BAL) - SUM(OD_LOAN_ACCT_BAL) AS LOAN_TOTAL
                          FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN T
                         INNER JOIN (SELECT ITEM_CD
                                      FROM SMTMODS_ZF_ITEM_CD_MAPPING
                                     WHERE FLAG = '1'
                                       AND SIGN = '01') T1
                            ON T.ITEM_CD = T1.ITEM_CD
                         WHERE DATA_DATE = IS_DATE
                              -- AND T.ORG_NUM NOT LIKE '51%'
                           AND T.ORG_NUM NOT LIKE '5%'
                           AND T.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇
                           AND LOAN_ACCT_BAL <> 0
                           AND T.ACCT_TYP = '010302' --MODY BY DJH 20231009网上消费贷款不平去掉
                         GROUP BY LOAN_NUM) A
                 LEFT JOIN (SELECT 
                             LOAN_NUM, SUM(OS_PPL) AS LOAN_TOTAL
                              FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN_PAYM_SCHED T
                             WHERE DATA_DATE = IS_DATE
                               AND DUE_DATE > IS_DATE
                                  --AND ORG_NUM NOT LIKE '51%'
                               AND T.ORG_NUM NOT LIKE '5%'
                               AND T.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇
                             GROUP BY LOAN_NUM) B
                   ON A.LOAN_NUM = B.LOAN_NUM
                WHERE A.LOAN_TOTAL <> B.LOAN_TOTAL HAVING
                ABS(SUM(A.LOAN_TOTAL - B.LOAN_TOTAL)) > 1
               /*SELECT ROUND(ABS(BALANCE_MINUS))+1 BALANCE_MINUS
                FROM (SELECT T.CHECK_ITEM,
                             T.SYS_DATE,
                             T.BALANCE_MINUS,
                             ROW_NUMBER() OVER(PARTITION BY CHECK_ITEM ORDER BY SYS_DATE DESC) RN
                        FROM ZF_DATA_LOG T
                       WHERE T.DATA_DATE = IS_DATE
                         AND T.CHECK_ITEM = 'ck_000001') --获取总分校验中ck_000001 贷款和还款计划表余额核对 结果值
               WHERE RN = 1*/
               )
      ON 1 = 1
   WHERE DT_DATE = IS_DATE
     AND T.FLAG = '01'
     AND ABS(ABS(BALANCE) - ABS(BALANCE_MINUS)) > 10
  UNION ALL
  SELECT DT_DATE, CHECK_TPYE, BALANCE1, BALANCE2, BALANCE, REMARK, FLAG
    FROM PM_RSDATA.CBRC_CHECK_DATA T
   WHERE DT_DATE = IS_DATE
     AND T.FLAG = '03' --[2025-09-19] [狄家卉]  增加总账部分差异
     AND ABS(BALANCE) > 1
  UNION ALL
  SELECT DT_DATE, CHECK_TPYE, BALANCE1, BALANCE2, BALANCE, REMARK, FLAG
    FROM PM_RSDATA.CBRC_CHECK_DATA T
   WHERE DT_DATE = IS_DATE
     AND T.FLAG IN ('04', '06')
     AND ABS(BALANCE) > 1
  UNION ALL --[2025-09-19] [狄家卉]  增加总账部分差异
  SELECT A.DT_DATE,
         A.CHECK_TPYE,
         A.BALANCE1,
         A.BALANCE2,
         CASE
           WHEN ABS(A.BALANCE - B.BALANCE) > 10 THEN --超过设定范围显示原差异值，否则显示差异
            A.BALANCE
           ELSE
            ABS(A.BALANCE - B.BALANCE)
         END AS BALANCE,
         A.REMARK,
         A.FLAG
    FROM (SELECT DT_DATE,
                 CHECK_TPYE,
                 BALANCE1,
                 BALANCE2,
                 ABS(BALANCE) AS BALANCE,
                 REMARK,
                 FLAG
            FROM PM_RSDATA.CBRC_CHECK_DATA T
           WHERE DT_DATE = IS_DATE
             AND T.FLAG = '02') A --1.9其他有确定到期日的资产
    FULL JOIN (SELECT DT_DATE,
                      CHECK_TPYE,
                      BALANCE1,
                      BALANCE2,
                      ABS(BALANCE) AS BALANCE,
                      REMARK,
                      FLAG
                 FROM PM_RSDATA.CBRC_CHECK_DATA T
                WHERE DT_DATE = IS_DATE
                  AND T.FLAG = '07') B --1.9其他有确定到期日的资产抵消利息
      ON 1 = 1
   WHERE ABS(A.BALANCE - B.BALANCE) > 10;

 COMMIT;

/*判断一下G21 1.6各项贷款 与 G21贷款合计与G0102各项贷款合计校验  差值
1、如果一致说明是还款计划表与借据表有差异引起的
2、如果不一致说明G21与G0102有差异，需要分析原因*/

INSERT  INTO PM_RSDATA.CBRC_CHECK_DATA_RESULT 
  (DT_DATE, --校验日期
   CHECK_TPYE, --校验类型
   BALANCE1, --校验表1值
   BALANCE2, --校验表2值
   BALANCE, --差异
   REMARK, --备注
   FLAG)
  SELECT T.DT_DATE,
         T.CHECK_TPYE,
         T.BALANCE1,
         T.BALANCE2,
         ABS(ABS(T.BALANCE) - ABS(BALANCE_MINUS)) AS BALANCE,
         T.REMARK,
         T.FLAG
    FROM PM_RSDATA.CBRC_CHECK_DATA T
   INNER JOIN (SELECT SUM(CASE
                            WHEN T.FLAG = '01' THEN
                             BALANCE
                            ELSE
                             -1 * BALANCE
                          END) AS BALANCE
                 FROM PM_RSDATA.CBRC_CHECK_DATA T
                WHERE DT_DATE = IS_DATE
                  AND T.FLAG IN ('01', '05')) T1
      ON 1 = 1
    LEFT JOIN ( --add by DJH 20231115 补数据
               SELECT ROUND(ABS(SUM(A.LOAN_TOTAL - B.LOAN_TOTAL)))  AS BALANCE_MINUS
                 FROM (SELECT 
                         LOAN_NUM,
                         SUM(LOAN_ACCT_BAL) - SUM(OD_LOAN_ACCT_BAL) AS LOAN_TOTAL
                          FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN T
                         INNER JOIN (SELECT ITEM_CD
                                      FROM SMTMODS_ZF_ITEM_CD_MAPPING
                                     WHERE FLAG = '1'
                                       AND SIGN = '01') T1
                            ON T.ITEM_CD = T1.ITEM_CD
                         WHERE DATA_DATE = IS_DATE
                              -- AND T.ORG_NUM NOT LIKE '51%'
                           AND T.ORG_NUM NOT LIKE '5%'
                           AND T.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇
                           AND LOAN_ACCT_BAL <> 0
                           AND T.ACCT_TYP = '010302' --MODY BY DJH 20231009网上消费贷款不平去掉
                         GROUP BY LOAN_NUM) A
                 LEFT JOIN (SELECT 
                             LOAN_NUM, SUM(OS_PPL) AS LOAN_TOTAL
                              FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN_PAYM_SCHED T
                             WHERE DATA_DATE = IS_DATE
                               AND DUE_DATE > IS_DATE
                                  --AND ORG_NUM NOT LIKE '51%'
                               AND T.ORG_NUM NOT LIKE '5%'
                               AND T.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇
                             GROUP BY LOAN_NUM) B
                   ON A.LOAN_NUM = B.LOAN_NUM
                WHERE A.LOAN_TOTAL <> B.LOAN_TOTAL HAVING
                ABS(SUM(A.LOAN_TOTAL - B.LOAN_TOTAL)) > 1
               /*SELECT ROUND(ABS(BALANCE_MINUS))+1 BALANCE_MINUS
                FROM (SELECT T.CHECK_ITEM,
                             T.SYS_DATE,
                             T.BALANCE_MINUS,
                             ROW_NUMBER() OVER(PARTITION BY CHECK_ITEM ORDER BY SYS_DATE DESC) RN
                        FROM ZF_DATA_LOG T
                       WHERE T.DATA_DATE = IS_DATE
                         AND T.CHECK_ITEM = 'ck_000001') --获取总分校验中ck_000001 贷款和还款计划表余额核对 结果值
               WHERE RN = 1*/
               ) T2
      ON 1 = 1
   WHERE T.DT_DATE = IS_DATE
     AND T.FLAG = '05'
        -- AND T1.BALANCE<>0
     AND ABS(ABS(T.BALANCE) - ABS(BALANCE_MINUS)) > 10;

  COMMIT;

--[2025-11-19] [狄家卉] 处理 PM_RSDATA.CBRC_CHECK_DATA_RESULT 中，01与05如果差值相同，即宽限期引起问题，此处相同就进行相减，为0，可进行正常跑批
INSERT INTO PM_RSDATA.CBRC_CHECK_DATA_RESULT_FINAL
  (DT_DATE, CHECK_TPYE, BALANCE1, BALANCE2, BALANCE, REMARK, FLAG, ORG_NUM)
  SELECT DT_DATE,
         CHECK_TPYE,
         BALANCE1,
         BALANCE2,
         BALANCE,
         REMARK,
         FLAG,
         ORG_NUM
    FROM PM_RSDATA.CBRC_CHECK_DATA_RESULT
   WHERE DT_DATE = IS_DATE
     AND FLAG IN ('02', '03', '04', '06')
  UNION ALL
  SELECT DT_DATE,
         CHECK_TPYE,
         BALANCE1,
         BALANCE2,
         BALANCE,
         REMARK,
         FLAG,
         ORG_NUM
    FROM PM_RSDATA.CBRC_CHECK_DATA_RESULT A
    LEFT JOIN (SELECT SUM(CASE
                            WHEN T.FLAG = '01' THEN
                             ABS(BALANCE)
                            ELSE
                             -1 * ABS(BALANCE)
                          END) AS BALANCE_MINUS
                 FROM PM_RSDATA.CBRC_CHECK_DATA_RESULT T
                WHERE T.DT_DATE = IS_DATE
                  AND T.FLAG IN ('01', '05'))
     ON 1=1
   WHERE A.DT_DATE = IS_DATE
     AND A.FLAG IN ('01', '05')
     AND BALANCE_MINUS > 0; -- 只有差值不为0时，进行插入结果表
  
  V_STEP_FLAG := 1;
  V_STEP_DESC := '插入CBRC_CHECK_DATA_RESULT完成';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

  V_STEP_ID   := V_STEP_ID + 1;
  V_STEP_FLAG := 0;
  V_STEP_DESC := '判断校验结果余额开始';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);
--每次初始化，防止数值还是上面结果出数
 V_COUNT := 0;
 OI_REMESSAGE_LIST := '';

 SELECT COUNT(1) INTO V_COUNT FROM PM_RSDATA.CBRC_CHECK_DATA_RESULT_FINAL WHERE DT_DATE = IS_DATE;

  IF V_COUNT > 0 THEN
    
    DBMS_OUTPUT.PUT_LINE('O_STATUS=-1');
    
 --返回拼装科目不平信息
 SELECT  GROUP_CONCAT(CHECK_TPYE ||' 值1：'|| ROUND(BALANCE1,2) ||' 值2：'|| ROUND(BALANCE2,2) ||' 差值：'|| ROUND(BALANCE,2), '; ')   INTO  OI_REMESSAGE_LIST  FROM PM_RSDATA.CBRC_CHECK_DATA_RESULT_FINAL WHERE DT_DATE = IS_DATE;

  DBMS_OUTPUT.PUT_LINE(OI_REMESSAGE_LIST);

  O_STATUS_DEC :=O_STATUS_DEC || ';' ||OI_REMESSAGE_LIST ;

   DBMS_OUTPUT.PUT_LINE(O_STATUS_DEC); 

   --去掉开头结尾的逗号，并去掉中间多余逗号
   --OI_REMESSAGE := TRIM(BOTH ',' FROM REGEXP_REPLACE(OI_REMESSAGE,'[.,.]{1,}',',')) || '科目不平';
   --增加结果提示信息，以便运维查看及维护
  O_STATUS_DEC := 'CBRC_CHECK_DATA_RESULT_FINAL结果表校验不平 :' || LTRIM(RTRIM(REGEXP_REPLACE(O_STATUS_DEC, '[.;.]+', ';'), ';'), ';');

COMMIT;

  V_STEP_FLAG := 1;
  V_STEP_DESC := '校验结果余额异常返回';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);
    RETURN;
 ELSE 

    DBMS_OUTPUT.PUT_LINE('O_STATUS=0');
    DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=完成'); 

  END IF;

  V_STEP_FLAG := 1;
  V_STEP_DESC := '判断校验结果余额完成';
  SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
              V_STEP_ID,
              V_ERRORCODE,
              V_STEP_DESC,
              II_DATADATE);

  
  -----  下发数据成功标志

EXCEPTION
  WHEN OTHERS THEN
    V_ERRORCODE := SQLCODE;
    V_ERRORDESC := SUBSTR(SQLERRM, 1, 280);
    V_STEP_DESC := '发生异常。详细信息为，' || TO_CHAR(SQLCODE) ||
                   SUBSTR(SQLERRM, 1, 280);
				   
    DBMS_OUTPUT.PUT_LINE('O_STATUS=-1');
    DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=失败'); 
    --记录异常信息
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ROLLBACK;
END proc_cbrc_check_result;
