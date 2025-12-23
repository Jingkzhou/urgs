CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g22(II_DATADATE IN STRING--跑批日期
                                              )
/******************************
  @author:DJH
  @create-date:20210930 
  @description:G22R
  @modification history:
  m0.author-create_date-description
  m1.需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-17，修改人：石雨，提出人：王曦若?
  alter by 石雨 20250507 同业金融部陈聪剔除少算了200303 程序问题
  需求编号：JLBA202505280011 上线日期： 2025-09-19，修改人：狄家卉，提出人：赵翰君  修改原因：关于实现1104监管报送报表自动化采集加工的需求 增加009801清算中心(国际业务部)外币折人民币业务
  
目标表：PM_RSDATA.CBRC_A_REPT_ITEM_VAL
        PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI
        PM_RSDATA.CBRC_FDM_LNAC
        PM_RSDATA.CBRC_FDM_LNAC_GL
        PM_RSDATA.CBRC_FDM_LNAC_PLEDGE_G22
        PM_RSDATA.CBRC_FDM_LNAC_PMT
        PM_RSDATA.CBRC_FDM_LNAC_PMT_G22
        PM_RSDATA.CBRC_FDM_LNAC_PMT_LX
        PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI
        PM_RSDATA.CBRC_ID_G22_ITEMDATA_NGI
        PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP
        PM_RSDATA.CBRC_L_ACCT_LOAN_PAYM_SCHED_BJ
        PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL
        PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL
        PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL
        PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL
PM_RSDATA.SMTMODS_L_ACCT_CARD_CREDIT
PM_RSDATA.SMTMODS_L_ACCT_LOAN
PM_RSDATA.SMTMODS_L_AGRE_GUARANTEE_RELATION
PM_RSDATA.SMTMODS_L_AGRE_GUARANTY_INFO
PM_RSDATA.SMTMODS_L_AGRE_GUA_RELATION
PM_RSDATA.SMTMODS_L_PUBL_RATE
PM_RSDATA.SMTMODS_V_PUB_FUND_CDS_BAL
PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL

  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE     VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE     VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  D_DATADATE_CCY STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_ERRORDESC    VARCHAR(280); --错误内容
  D_DATADATE     STRING; --数据日期(日期型)YYYYMMDD
  II_STATUS     INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    I_DATADATE     := II_DATADATE;
    V_DATADATE     := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');
    D_DATADATE_CCY := I_DATADATE;
    D_DATADATE   := I_DATADATE;
    V_SYSTEM       := 'CBRC';
    --V_PROCEDURE     := UPPER('SP_CBRC_IDX2_G22_CJL');
    V_PROCEDURE     := UPPER('PROC_CBRC_IDX2_G22');
    V_TAB_NAME     := 'PM_RSDATA.CBRC_A_REPT_ITEM_VAL';

    V_STEP_FLAG := 1;
    V_STEP_DESC := '参数初始化处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']G22当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_FDM_LNAC_PMT_G22';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_FDM_LNAC_PLEDGE_G22';-- ADD BY DJH 20220718 8.一个月内到期用于质押的存款金额 9.项目8.用于质押的有关贷款金额 临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_ID_G22_ITEMDATA_NGI';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI';

    DELETE FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI T
     WHERE T.REP_NUM = 'G22R'
       AND DATA_DATE = I_DATADATE;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '清理G22当期数据完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --====================================================
    --   G22R     1.6一个月内到期的合格贷款
    --====================================================  使用还款计划表拆分剩余期限 多币种
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据按照还款计划处理至FDM_LNAC_PMT_G22中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 --G22与G21本金处理方式不同，G21与G0102同，G22正常部分按照还款计划处理，逾期部分按照逾期本金处理,本金利息分开处理
 --正常贷款 账户按照还款计划处理
  INSERT 
  INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_G22 
    (DATA_DATE, --01数据日期
     LOAN_NUM, --02贷款编号（借据编号）
     CURR_CD, --03币种
     ITEM_CD, --04科目号
     ORG_NUM, --05机构
     ACTUAL_MATURITY_DT, --06实际到期日期
     NEXT_PAYMENT_DT, --07下次付款日
     REPAY_SEQ, --08还款期数
     ACCT_NUM, --09合同号
     ACCT_STS, --10账户状态（借据状态）
     ACCU_INT_AMT, --11应计利息
     ACCT_STATUS_1104, --12状态
     NEXT_PAYMENT, --13下次付款额
     ACCU_INT, --14还款计划应计利息
     LOAN_ACCT_BAL, --15贷款余额
     PMT_REMAIN_TERM_C, --16还款计划剩余期限
     PMT_REMAIN_TERM_C_MULT, --17还款计划单位
     LOAN_GRADE_CD, --18五级分类状态
     IDENTITY_CODE, --19标识符
     BOOK_TYPE, --20账户种类
     INT_RATE_TYP, --21利率类型
     NEXT_REPRICING_DT, --22下一利率重定价日
     BENM_INRAT_TYPE, --23基准利率类型（10基准率,30 LPR利率）
     PMT_REMAIN_TERM_D, --24下一利率重定价日剩余期限
     INRAT_RGLR_MODE --25利率调整方式
     )
    SELECT 
     T1.DATA_DATE, --01数据日期
     T1.LOAN_NUM, --02贷款编号（借据编号）
     T1.CURR_CD, --03币种
     T1.ITEM_CD, --04科目号
     T1.ORG_NUM, --05机构
     T1.ACTUAL_MATURITY_DT, --06实际到期日期
     NVL(DUE_DATE,
         T1.ACTUAL_MATURITY_DT) AS NEXT_PAYMENT_DT, --07下次付款日  如果不在还款计划表用到期日
     NVL(T2.REPAY_SEQ, 'WU'), --08还款期数
     T1.ACCT_NUM, --09合同号
     T1.ACCT_STS, --10账户状态（借据状态）
     NVL(T1.ACCU_INT_AMT, 0), --11应计利息
     '10' AS ACCT_STATUS_1104, --12逾期判定标志
     NVL(T2.OS_PPL, T1.LOAN_ACCT_BAL) AS NEXT_PAYMENT, --13下次付款额 如果不在还款计划表用当前余额
     NVL(T2.ACCU_INT, 0) AS ACCU_INT, --14还款计划应计利息
     T1.LOAN_ACCT_BAL, --15贷款余额
     NVL(DUE_DATE, T1.ACTUAL_MATURITY_DT) - D_DATADATE_CCY PMT_REMAIN_TERM_C, --16还款计划剩余期限
     'D' PMT_REMAIN_TERM_C_MULT, --17还款计划单位
     T1.LOAN_GRADE_CD, --18五级分类状态
     '1' AS IDENTITY_CODE, --19标识符
     T1.BOOK_TYPE, --20账户种类
     T1.INT_RATE_TYP, --21利率类型
     T1.NEXT_REPRICING_DT, --22下一利率重定价日
     T1.BENM_INRAT_TYPE, --23基准利率类型（10基准率,30 LPR利率）
     NVL(T1.NEXT_REPRICING_DT,
         T1.ACTUAL_MATURITY_DT) - D_DATADATE_CCY PMT_REMAIN_TERM_D, --24下一利率重定价日剩余期限
     INRAT_RGLR_MODE --25利率调整方式
      FROM PM_RSDATA.CBRC_FDM_LNAC T1
      LEFT JOIN PM_RSDATA.CBRC_L_ACCT_LOAN_PAYM_SCHED_BJ T2
        ON T1.LOAN_NUM = T2.LOAN_NUM
     WHERE T1.DATA_DATE = I_DATADATE
       AND T1.LOAN_ACCT_BAL <> 0
       AND T1.LOAN_ACCT_BAL<>T1.OD_LOAN_ACCT_BAL;--对于本金与逾期本金相等的属于全部逾期，不取还款计划，直接从逾期本金取
      /* 1）由于借据表里面网贷数据结清但仍然有还款计划，此数据还款计划表数据不取，
       2）借据表余额与还款计划表余额加和不等，导致数据不平，新信贷回复他们数据会截断，由于是核心历史数据，这种数据需要等处理结果
       此处直接以借据表借据余额为准，只要余额为0的均不取*/
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据按照还款计划处理至FDM_LNAC_PMT_G22中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --20211202逻辑修正，与G21处理不同 ：正常一个月内贷款+逾期本金到期日在一个月以内的数据逾期本金金额
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.6一个月内到期的合格贷款至ID_G22_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_ID_G22_ITEMDATA_NGI 
      (RQ, ORGNO, ITEMINDIC, ITEM, YE)
      SELECT DATA_DATE,
             ORG_NUM,
             'G22_1.6_CNY',
             '',
             SUM(CASE
                   WHEN CURR_CD = 'CNY' THEN
                    CUR_BAL
                   ELSE
                    0
                 END) AS CUR_CNY_BAL
        FROM (SELECT 
               T1.DATA_DATE,
               T1.ORG_NUM,
               T1.CURR_CD,
               SUM(T1.NEXT_PAYMENT * T2.CCY_RATE) CUR_BAL
                FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_G22 T1
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = T1.CURR_CD --基准币种
                 AND T2.FORWARD_CCY = 'CNY'
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.PMT_REMAIN_TERM_C <= 30
                 AND T1.PMT_REMAIN_TERM_C >= 1
               GROUP BY T1.DATA_DATE, T1.ORG_NUM, T1.CURR_CD
              UNION ALL
              SELECT 
               T1.DATA_DATE,
               T1.ORG_NUM,
               T1.CURR_CD,
               SUM(CASE
                     WHEN T1.OD_LOAN_ACCT_BAL > T1.LOAN_ACCT_BAL THEN --对于逾期金额大于本金余额的直接取本金余额
                      T1.LOAN_ACCT_BAL
                     ELSE
                      T1.OD_LOAN_ACCT_BAL
                   END * T2.CCY_RATE) CUR_BAL
                FROM PM_RSDATA.CBRC_FDM_LNAC T1
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = T1.CURR_CD --基准币种
                 AND T2.FORWARD_CCY = 'CNY'
               WHERE T1.DATA_DATE = I_DATADATE
                 AND ABS(P_OD_DT - D_DATADATE_CCY) <= 30 --除129贴现以外用本金到期日判定
                 AND T1.ITEM_CD NOT LIKE '1301%'
                 AND P_OD_DT IS NOT NULL
               GROUP BY T1.DATA_DATE, T1.ORG_NUM, T1.CURR_CD
              UNION ALL
              SELECT 
               T1.DATA_DATE,
               T1.ORG_NUM,
               T1.CURR_CD,
               SUM(T1.LOAN_ACCT_BAL * T2.CCY_RATE) CUR_BAL --129贴现，用逾期天数判定，贴现逾期直接取逾期本金
                FROM PM_RSDATA.CBRC_FDM_LNAC T1
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = T1.CURR_CD --基准币种
                 AND T2.FORWARD_CCY = 'CNY'
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.OD_DAYS > 0
                 AND T1.OD_DAYS <= 30
                 AND T1.ITEM_CD LIKE '1301%'
               GROUP BY T1.DATA_DATE, T1.ORG_NUM, T1.CURR_CD
              UNION ALL --ADD BY DJH 与G21相同，20220518如果逾期天数是空值或者0，但是实际到期日小于等于当前日期数据，放在次日
              SELECT 
               T1.DATA_DATE,
               T1.ORG_NUM,
               T1.CURR_CD,
               SUM(T1.LOAN_ACCT_BAL * T2.CCY_RATE) CUR_BAL
                FROM PM_RSDATA.CBRC_FDM_LNAC_PMT T1
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = T1.CURR_CD --基准币种
                 AND T2.FORWARD_CCY = 'CNY'
               WHERE T1.DATA_DATE = I_DATADATE
                 and (T1.ACCT_STATUS_1104 = '10' AND
                     T1.PMT_REMAIN_TERM_C <= 0)
               GROUP BY T1.DATA_DATE, T1.ORG_NUM, T1.CURR_CD)
       GROUP BY DATA_DATE, ORG_NUM
      UNION ALL
      SELECT DATA_DATE,
             ORG_NUM,
             'G22_1.6_ZCNY',
             '',
             SUM(CASE
                   WHEN CURR_CD <> 'CNY' THEN
                    CUR_BAL
                   ELSE
                    0
                 END) AS CUR_ZCNY_BAL
        FROM (SELECT 
               T1.DATA_DATE,
               T1.ORG_NUM,
               T1.CURR_CD,
               SUM(T1.NEXT_PAYMENT * T2.CCY_RATE) CUR_BAL
                FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_G22 T1
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = T1.CURR_CD --基准币种
                 AND T2.FORWARD_CCY = 'CNY'
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.PMT_REMAIN_TERM_C <= 30
                 AND T1.PMT_REMAIN_TERM_C >= 1
               GROUP BY T1.DATA_DATE, T1.ORG_NUM, T1.CURR_CD
              UNION ALL
              SELECT 
               T1.DATA_DATE,
               T1.ORG_NUM,
               T1.CURR_CD,
               SUM(CASE
                     WHEN T1.OD_LOAN_ACCT_BAL > T1.LOAN_ACCT_BAL THEN --对于逾期金额大于本金余额的直接取本金余额
                      T1.LOAN_ACCT_BAL
                     ELSE
                      T1.OD_LOAN_ACCT_BAL
                   END * T2.CCY_RATE) CUR_BAL
                FROM PM_RSDATA.CBRC_FDM_LNAC T1
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = T1.CURR_CD --基准币种
                 AND T2.FORWARD_CCY = 'CNY'
               WHERE T1.DATA_DATE = I_DATADATE
                 AND ABS(P_OD_DT - D_DATADATE_CCY) <= 30  --除129贴现以外用本金到期日判定
                 AND T1.ITEM_CD NOT LIKE '1301%'
                 AND P_OD_DT IS NOT NULL
               GROUP BY T1.DATA_DATE, T1.ORG_NUM, T1.CURR_CD
              UNION ALL
              SELECT 
               T1.DATA_DATE,
               T1.ORG_NUM,
               T1.CURR_CD,
               SUM(T1.LOAN_ACCT_BAL * T2.CCY_RATE) CUR_BAL --129贴现，用逾期天数判定，贴现逾期直接取逾期本金
                FROM PM_RSDATA.CBRC_FDM_LNAC T1
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = T1.CURR_CD --基准币种
                 AND T2.FORWARD_CCY = 'CNY'
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T1.OD_DAYS > 0
                 AND T1.OD_DAYS <= 30
                 AND T1.ITEM_CD LIKE '1301%'
               GROUP BY T1.DATA_DATE, T1.ORG_NUM, T1.CURR_CD
               UNION ALL --ADD BY DJH 与G21相同，20220518如果逾期天数是空值或者0，但是实际到期日小于等于当前日期数据，放在次日
              SELECT 
               T1.DATA_DATE,
               T1.ORG_NUM,
               T1.CURR_CD,
               SUM(T1.LOAN_ACCT_BAL * T2.CCY_RATE) CUR_BAL
                FROM PM_RSDATA.CBRC_FDM_LNAC_PMT T1
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                  ON T2.DATA_DATE = I_DATADATE
                 AND T2.BASIC_CCY = T1.CURR_CD --基准币种
                 AND T2.FORWARD_CCY = 'CNY'
               WHERE T1.DATA_DATE = I_DATADATE
                 and (T1.ACCT_STATUS_1104 = '10' AND
                     T1.PMT_REMAIN_TERM_C <= 0)
               GROUP BY T1.DATA_DATE, T1.ORG_NUM, T1.CURR_CD)
       GROUP BY DATA_DATE, ORG_NUM;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.6一个月内到期的合格贷款至ID_G22_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.6一个月内到期的合格贷款至G22_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE, ORGNO, 'G22R_1.6.A', NVL(sum(YE), 0)
        FROM PM_RSDATA.CBRC_ID_G22_ITEMDATA_NGI T
       WHERE ITEMINDIC = 'G22_1.6_CNY'
         AND RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;

    --modiy by djh 20241210 信用卡规则修改信用卡正常部分+逾期30天
    --[1.6 一个月内到期的合格贷款]，A列取值：逾期M0+M1数据值汇总
    INSERT INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI
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
    COMMIT;

    INSERT INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE, ORGNO, 'G22R_1.6.B', sum(YE)
        FROM PM_RSDATA.CBRC_ID_G22_ITEMDATA_NGI T
       WHERE ITEMINDIC = 'G22_1.6_ZCNY'
         AND RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.6一个月内到期的合格贷款至G22_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --====================================================
    --G22 1.5一个月内到期的应收利息及其他应收款  正常30天内数据 +逾期30天内数据
    --对于应收利息<>0的借据，应收利息+营改增挂账利息，对于应收利息=0，不取
    --====================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.5一个月内到期的应收利息及其他应收款至ID_G22_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 INSERT 
 INTO PM_RSDATA.CBRC_ID_G22_ITEMDATA_NGI 
   (RQ, ORGNO, ITEMINDIC, ITEM, YE)
   SELECT DATA_DATE,
          ORG_NUM,
          'G22_1.5_CNY',
          '',
          SUM(CASE
                WHEN CURR_CD = 'CNY' THEN
                 CUR_BAL
                ELSE
                 0
              END) AS CUR_CNY_BAL
     FROM (SELECT 
            T1.DATA_DATE,
            CASE WHEN T1.ORG_NUM  LIKE '5%' OR T1.ORG_NUM  LIKE '6%' THEN T1.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
              WHEN T1.ORG_NUM LIKE '%98%' THEN
               T1.ORG_NUM
              WHEN T1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
               '060300'
              ELSE
               SUBSTR(T1.ORG_NUM, 1, 4) || '00'
            END AS ORG_NUM,
            T1.CURR_CD,
            SUM(NVL(T1.ACCU_INT_AMT, 0) * T2.CCY_RATE) CUR_BAL,
            T1.PMT_REMAIN_TERM_C
             FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
             LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
               ON T2.DATA_DATE = I_DATADATE
              AND T2.BASIC_CCY = T1.CURR_CD --基准币种
              AND T2.FORWARD_CCY = 'CNY'
            WHERE T1.DATA_DATE = I_DATADATE
              AND T1.PMT_REMAIN_TERM_C <= 30
              AND T1.PMT_REMAIN_TERM_C >= 1
              AND T1.IDENTITY_CODE = '3'
              AND T1.ACCU_INT_AMT <> 0
            GROUP BY T1.DATA_DATE,
                     CASE WHEN T1.ORG_NUM  LIKE '5%' OR T1.ORG_NUM  LIKE '6%' THEN T1.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                       WHEN T1.ORG_NUM LIKE '%98%' THEN
                        T1.ORG_NUM
                       WHEN T1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                        '060300'
                       ELSE
                        SUBSTR(T1.ORG_NUM, 1, 4) || '00'
                     END,
                     T1.CURR_CD,
                     T1.PMT_REMAIN_TERM_C
           UNION ALL
           SELECT 
            T1.DATA_DATE,
            CASE WHEN T1.ORG_NUM  LIKE '5%' OR T1.ORG_NUM  LIKE '6%' THEN T1.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
              WHEN T1.ORG_NUM LIKE '%98%' THEN
               T1.ORG_NUM
              WHEN T1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
               '060300'
              ELSE
               SUBSTR(T1.ORG_NUM, 1, 4) || '00'
            END AS ORG_NUM,
            T1.CURR_CD,
            SUM((NVL(T1.OD_INT, 0) ) * T2.CCY_RATE),
            T1.PMT_REMAIN_TERM_C
             FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
             LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
               ON T2.DATA_DATE = I_DATADATE
              AND T2.BASIC_CCY = T1.CURR_CD --基准币种
              AND T2.FORWARD_CCY = 'CNY'
            WHERE T1.DATA_DATE = I_DATADATE
              AND T1.PMT_REMAIN_TERM_C <= 30
              AND T1.PMT_REMAIN_TERM_C >= 1
              AND T1.IDENTITY_CODE = '4'
              AND T1.OD_INT <> 0 --对于应收利息<>0的借据，应收利息+营改增挂账利息，对于应收利息=0，不取
            GROUP BY T1.DATA_DATE,
                     CASE WHEN T1.ORG_NUM  LIKE '5%' OR T1.ORG_NUM  LIKE '6%' THEN T1.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                       WHEN T1.ORG_NUM LIKE '%98%' THEN
                        T1.ORG_NUM
                       WHEN T1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                        '060300'
                       ELSE
                        SUBSTR(T1.ORG_NUM, 1, 4) || '00'
                     END,
                     T1.CURR_CD,
                     T1.PMT_REMAIN_TERM_C
           UNION ALL
           SELECT 
            I_DATADATE, ORG_NUM, T1.CURR_CD, SUM(MINUS_AMT) AS MINUS_AMT, 0
             FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP T1
            WHERE ITEM_CD LIKE '113201%'
              AND QX IN ('NEXT_YS', 'NEXT_WEEK', 'NEXT_MONTH') --与G21同取总账与明细有差值的利息，补进去
              AND MINUS_AMT <> 0
            GROUP BY I_DATADATE, ORG_NUM, T1.CURR_CD)
    GROUP BY DATA_DATE, ORG_NUM;

  COMMIT;

 INSERT 
 INTO PM_RSDATA.CBRC_ID_G22_ITEMDATA_NGI 
   (RQ, ORGNO, ITEMINDIC, ITEM, YE)
   SELECT DATA_DATE,
          ORG_NUM,
          'G22_1.5_ZCNY',
          '',
          SUM(CASE
                WHEN CURR_CD <> 'CNY' THEN
                 CUR_BAL
                ELSE
                 0
              END) AS CUR_ZCNY_BAL
     FROM (SELECT 
            T1.DATA_DATE,
            CASE WHEN T1.ORG_NUM  LIKE '5%' OR T1.ORG_NUM  LIKE '6%' THEN T1.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
              WHEN T1.ORG_NUM LIKE '%98%' THEN
               T1.ORG_NUM
              WHEN T1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
               '060300'
              ELSE
               SUBSTR(T1.ORG_NUM, 1, 4) || '00'
            END AS ORG_NUM,
            T1.CURR_CD,
            SUM(NVL(T1.ACCU_INT_AMT, 0) * T2.CCY_RATE) CUR_BAL,
            T1.PMT_REMAIN_TERM_C
             FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
             LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
               ON T2.DATA_DATE = I_DATADATE
              AND T2.BASIC_CCY = T1.CURR_CD --基准币种
              AND T2.FORWARD_CCY = 'CNY'
            WHERE T1.DATA_DATE = I_DATADATE
              AND T1.PMT_REMAIN_TERM_C <= 30
              AND T1.PMT_REMAIN_TERM_C >= 1
              AND T1.IDENTITY_CODE = '3'
              AND T1.ACCU_INT_AMT <> 0
            GROUP BY T1.DATA_DATE,
                     CASE WHEN T1.ORG_NUM  LIKE '5%' OR T1.ORG_NUM  LIKE '6%' THEN T1.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                       WHEN T1.ORG_NUM LIKE '%98%' THEN
                        T1.ORG_NUM
                       WHEN T1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                        '060300'
                       ELSE
                        SUBSTR(T1.ORG_NUM, 1, 4) || '00'
                     END,
                     T1.CURR_CD,
                     T1.PMT_REMAIN_TERM_C
           UNION ALL
           SELECT 
            T1.DATA_DATE,
            CASE WHEN T1.ORG_NUM  LIKE '5%' OR T1.ORG_NUM  LIKE '6%' THEN T1.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
              WHEN T1.ORG_NUM LIKE '%98%' THEN
               T1.ORG_NUM
              WHEN T1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
               '060300'
              ELSE
               SUBSTR(T1.ORG_NUM, 1, 4) || '00'
            END AS ORG_NUM,
            T1.CURR_CD,
            SUM((NVL(T1.OD_INT, 0) ) * T2.CCY_RATE),
            T1.PMT_REMAIN_TERM_C
             FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
             LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
               ON T2.DATA_DATE = I_DATADATE
              AND T2.BASIC_CCY = T1.CURR_CD --基准币种
              AND T2.FORWARD_CCY = 'CNY'
            WHERE T1.DATA_DATE = I_DATADATE
              AND T1.PMT_REMAIN_TERM_C <= 30
              AND T1.PMT_REMAIN_TERM_C >= 1
              AND T1.IDENTITY_CODE = '4'
              AND T1.OD_INT <> 0 --对于应收利息<>0的借据，应收利息+营改增挂账利息，对于应收利息=0，不取
            GROUP BY T1.DATA_DATE,
                     CASE WHEN T1.ORG_NUM  LIKE '5%' OR T1.ORG_NUM  LIKE '6%' THEN T1.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                       WHEN T1.ORG_NUM LIKE '%98%' THEN
                        T1.ORG_NUM
                       WHEN T1.ORG_NUM LIKE '060101' THEN --特殊机构处理 上级非截取00
                        '060300'
                       ELSE
                        SUBSTR(T1.ORG_NUM, 1, 4) || '00'
                     END,
                     T1.CURR_CD,
                     T1.PMT_REMAIN_TERM_C
           UNION ALL
           SELECT 
            I_DATADATE, ORG_NUM, T1.CURR_CD, SUM(MINUS_AMT) AS MINUS_AMT, 0
             FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP T1
            WHERE ITEM_CD = '113201'
              AND QX IN ('NEXT_YS', 'NEXT_WEEK', 'NEXT_MONTH') --与G21同取总账与明细有差值的利息，补进去
              AND MINUS_AMT <> 0
            GROUP BY I_DATADATE, ORG_NUM, T1.CURR_CD)
    GROUP BY DATA_DATE, ORG_NUM;
    COMMIT;
    ---add by chm 20231012

   --1.5一个月内到期的应收利息及其他应收款

   INSERT 
   INTO PM_RSDATA.CBRC_ID_G22_ITEMDATA_NGI 
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

   COMMIT;

    --ADD BY DJH 20240510  同业金融部 009820  1.5一个月内到期的应收利息及其他应收款
   /*拆放应收+存放应收（取存放同业活期的113211总账）+基金所有（货币基金投资利息成本）应收+同业存单应收；注意：债券基金投资没有应收*/
   INSERT 
   INTO PM_RSDATA.CBRC_ID_G22_ITEMDATA_NGI 
     (RQ, ORGNO, ITEMINDIC, ITEM, YE)
     SELECT I_DATADATE, /*'009804',*/
            ORG_NUM,
            CASE
              WHEN T.ACCT_CUR = 'CNY' THEN
               'G22_1.5_CNY'
              WHEN T.ACCT_CUR <> 'CNY' THEN -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金本金对应的应收利息
               'G22_1.5_ZCNY'
            END, --同业金融部确认后没有外币部分 G22R_1.5.A
            '',
            SUM(ACCRUAL)
       FROM (
             --存放应收（取存放同业活期的113211总账）
             SELECT ORG_NUM, ACCT_CUR, SUM(A.INTEREST_ACCURAL) AS ACCRUAL
               FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
              WHERE DATA_DATE = I_DATADATE
                AND FLAG = '01' --01(1011存放同业,1031存出保证金)
                AND A.ORG_NUM = '009820'
              GROUP BY ORG_NUM, ACCT_CUR
             UNION ALL
             --拆放应收
             SELECT /*'009804',*/
              ORG_NUM, ACCT_CUR, SUM(A.INTEREST_ACCURAL) AS ACCRUAL
               FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
              WHERE DATA_DATE = I_DATADATE
                AND FLAG = '02' -- 02(1302拆出资金)
                AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
                   --  AND ABS((A.MATUR_DATE - TO_DATE('20240331', 'YYYYMMDD')))< =30   --同业金融部确认后逾期不要
              GROUP BY ORG_NUM, ACCT_CUR
             UNION ALL
             --基金所有（货币基金投资利息成本）应收
             SELECT A.ORG_NUM, ACCT_CUR, SUM(A.INTEREST_ACCURAL) AS ACCRUAL --应收利息
               FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
              WHERE A.DATA_DATE = I_DATADATE
                AND FLAG = '06' -- 基金所有
                AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
             --(ABS((A.MATUR_DATE - TO_DATE('20240331', 'YYYYMMDD')))< =30 OR  A.REDEMPTION_TYPE='随时赎回' ) --随时赎回放到2到7日  --同业金融部确认后逾期不要
              GROUP BY A.ORG_NUM, ACCT_CUR
             /* UNION ALL
             --同业存单应收利息
               SELECT ORG_NUM,
                       SUM(A.INTEREST_ACCURAL) AS ACCRUAL
                 FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
                WHERE DATA_DATE = I_DATADATE
                  AND FLAG = '04'
                  AND A.DC_DATE <= 30
                  AND A.DC_DATE >= 1 --取待偿期一个月内   --ADD BY DJH 20240510  同业金融部 和金融市场一样，统一规则
                GROUP BY ORG_NUM*/
             ) T
      GROUP BY ORG_NUM,
               CASE
                 WHEN T.ACCT_CUR = 'CNY' THEN
                  'G22_1.5_CNY'
                 WHEN T.ACCT_CUR <> 'CNY' THEN
                  'G22_1.5_ZCNY'
               END;

   COMMIT;
 

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.5一个月内到期的应收利息及其他应收款至ID_G22_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.5一个月内到期的应收利息及其他应收款至G22_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI
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
    COMMIT;

    INSERT INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE, ORGNO, 'G22R_1.5.B', NVL(SUM(YE), 0)
        FROM PM_RSDATA.CBRC_ID_G22_ITEMDATA_NGI
       WHERE ITEMINDIC = 'G22_1.5_ZCNY'
         AND RQ = I_DATADATE
       GROUP BY ORGNO
      UNION ALL --信用卡利息外币
      SELECT I_DATADATE, '009803', 'G22R_1.5.B', sum(T1.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL T1
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.CURR_CD <> 'CNY'
         AND T1.GL_ACCOUNT = '113201'
         AND T1.ORG_NUM = '009803'
       GROUP BY T1.ORG_NUM;
    COMMIT;


         --====================================================
    --G22 1.5一个月内到期的应收利息及其他应收款  增加资管009816 取剩余期限30天（含）内中收计提表【本期累计计提中收】 ADD BY DJH 20241205数仓逻辑变更自动取数
    --====================================================
 --人民币
      INSERT INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI
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

COMMIT;
 --外币

      INSERT INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.B',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
           AND FLAG = '1'
           AND REDEMP_DATE IS NULL
            OR (REDEMP_DATE - I_DATADATE >= 1 AND
               REDEMP_DATE - I_DATADATE <= 30)
           AND A.CURR_CD <> 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
        SELECT I_DATADATE,
               A.ORG_NUM,
               'G22R_1.5.B',
               SUM(NVL(A.RECVAPAY_AMT, 0))
          FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
           AND FLAG = '1'
           AND COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL
            OR (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE >= 1 AND
               COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
               I_DATADATE <= 30)
           AND A.CURR_CD <> 'CNY'
         GROUP BY A.ORG_NUM
        UNION ALL
       SELECT I_DATADATE,
              A.ORG_NUM,
              'G22R_1.5.B' AS ITEM_NUM,
              SUM(A.DEBIT_BAL)
         FROM PM_RSDATA.CBRC_FDM_LNAC_GL A   --G21取总账数据表
        WHERE A.DATA_DATE = I_DATADATE
          AND ITEM_CD = 'G21_1.8.A'
          AND A.CURR_CD <> 'CNY'
        GROUP BY I_DATADATE, A.ORG_NUM;

COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.5一个月内到期的应收利息及其他应收款至G22_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 -------------------------------存款------------------------------------

--====================================================
    --G22 1.1现金   101库存现金
--====================================================
INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
COMMIT;
INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
COMMIT;
--====================================================
    --G22 1.2黄金   103贵金属
--====================================================
INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_1.2.A',
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
             AND A.ITEM_CD = '1431' --贵金属
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
COMMIT;
INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_1.2.B',
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
             AND A.ITEM_CD = '1431' --贵金属
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
COMMIT;
--====================================================
    --G22 1.3超额准备金存款   11002存放中央银行超额备付金存款  11002的外币折人民币有也不放在这，因为放商业银行了
--====================================================
INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
COMMIT;
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
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
COMMIT;

INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
COMMIT;
--===========================================================
    --G22   1.7一个月内到期的债券投资 add by chm 20231012
--===========================================================

  INSERT 
  INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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

  COMMIT;

--====================================================================================================
    --G22   1.8在国内外二级市场上可随时变现的证券投资（不包括项目1.7的有关项目） add by chm 20231012
--====================================================================================================

   INSERT 
   INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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

   COMMIT;


--================================================================================================
    --G22   1.9其他一个月内到期可变现的资产（剔除其中的不良资产） add by chm 20231012
--================================================================================================

     INSERT 
     INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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

     COMMIT;
   --ADD BY DJH 20240510  同业金融部
  /*同业存单投资的剩余价值，取待偿期一个月内;  已取 ，如上逻辑逻辑中含有009820
   +基金一个月内到期的（持有仓位+公允价值），随时申赎的基金都放一个月内，定开的取1个月内;
   +委外业务：科目为11010303，取账户类型是FVTPL账户的都取进来，其中中信信托2笔特殊处理按照到期日取1个月内，FVTPL账户取持有仓位+公允；*/
       INSERT 
       INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
       COMMIT;
   --ADD BY DJH 20240510  投资银行部
   --009817：存量非标业务的一个月内到期的本金+应收利息+其他应收款，剔除不良资产（次级，可疑，损失）后按剩余期限划分取值；
      INSERT 
       INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
       COMMIT;

--====================================================
    --G22   2.3一个月内到期的同业往来款项轧差后负债方净额
--====================================================
INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
COMMIT;

INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
COMMIT;

 --====================================================
    --G22 2.1活期存款   G21中3.5.2活期存款（一个月内）
--====================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据2.1活期存款至ID_G22_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
COMMIT;
INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
   COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据2.1活期存款至ID_G22_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--====================================================
    --G22 2.2一个月内到期的定期存款  G21中3.5.2活期存款（一个月内）
--====================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据2.2一个月内到期的定期存款 至ID_G22_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
COMMIT;
INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
     COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据2.2一个月内到期的定期存款 至ID_G22_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



--====================================================
    --G22 2.4一个月内到期的已发行的债券
--====================================================

INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.4.A',
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
           SUM(ACCT_BAL_RMB) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
             AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
             AND A.FLAG = '08'
           GROUP BY A.DATA_DATE, A.ORG_NUM, A.ACCT_CUR)
   GROUP BY DATA_DATE, ORG_NUM;
COMMIT;

INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.4.B',
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
           SUM(ACCT_BAL_RMB) CUR_BAL
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
           WHERE A.DATA_DATE = I_DATADATE
             AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
             AND A.FLAG = '08'
           GROUP BY A.DATA_DATE, A.ORG_NUM, A.ACCT_CUR)
   GROUP BY DATA_DATE, ORG_NUM;
COMMIT;
--====================================================
    --G22 2.5一个月内到期的应付利息和各项应付款  260应付利息
--====================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据2.5一个月内到期的应付利息和各项应付款至ID_G22_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
     COMMIT;

INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
COMMIT;
---add by chm 20231012 正回购应付利息（债券+票据）

    INSERT 
    INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
    
    COMMIT;
    

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据2.5一个月内到期的应付利息和各项应付款至ID_G22_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



--====================================================
    --G22   2.6一个月内到期的向中央银行借款
--====================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据2.6一个月内到期的向中央银行借款至ID_G22_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
     COMMIT;
   INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT DATA_DATE,
             ORG_NUM,
             'G22R_2.6.B',
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
               SUM(ACCT_BAL_RMB)  CUR_BAL
              FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
             WHERE A.DATA_DATE = I_DATADATE
               AND A.REMAIN_TERM_CODE IN ('A', 'B', 'C')
               AND A.FLAG = '02'
             GROUP BY A.DATA_DATE, A.ORG_NUM, A.ACCT_CUR)
       GROUP BY DATA_DATE, ORG_NUM;
  COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据2.6一个月内到期的向中央银行借款至ID_G22_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  --====================================================
    --G22   2.7其他一个月内到期的负债  总行层面财政性扎差负债余额+G213.7发行同业存单30天内
--====================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据2.7其他一个月内到期的负债至ID_G22_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
COMMIT;

INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE,
         ORG_NUM,
         'G22R_2.7.B',
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
          SELECT 
           I_DATADATE, A.ORG_NUM, A.CURR_CD, sum(A.DEBIT_BAL) CUR_BAL
            FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
           WHERE A.DATA_DATE = I_DATADATE
             AND ITEM_CD = '3.8.B'
           GROUP BY I_DATADATE, A.ORG_NUM, A.CURR_CD)
   GROUP BY DATA_DATE, ORG_NUM;
COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据2.7其他一个月内到期的负债至ID_G22_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 -------------------------------存款------------------------------------
--  ADD BY DJH 20220718 8.一个月内到期用于质押的存款金额 9.项目8.用于质押的有关贷款金额 明细
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据一个月内到期用于质押的存款金额、贷款金额明细至FDM_LNAC_PLEDGE_G22中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT 
INTO PM_RSDATA.CBRC_FDM_LNAC_PLEDGE_G22 
  (LOAN_NUM,
   ORG_NUM,
   CURR_CD,
   LOAN_ACCT_BAL,
   ACTUAL_MATURITY_DT,
   CONTRACT_NUM,
   ORG_NO,
   COLL_CCY,
   DEP_AMT,
   DEP_MATURITY)
  SELECT 
   T1.LOAN_NUM, --贷款编号
   T1.ORG_NUM, --贷款机构
   T1.CURR_CD, --贷款币种
   SUM(T1.LOAN_ACCT_BAL * T3.CCY_RATE) AS LOAN_ACCT_BAL, --贷款余额,
   T1.ACTUAL_MATURITY_DT, --贷款实际到期日
   TM.CONTRACT_NUM, --业务合同号
   TM.ORG_NUM, --存单机构
   TM.COLL_CCY, --存单币种
   TM.DEP_AMT, --存单金额
   TM.DEP_MATURITY --存单到期日
    FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN T1
    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T3
      ON T3.DATA_DATE = I_DATADATE
     AND T3.BASIC_CCY = T1.CURR_CD
     AND T3.FORWARD_CCY = 'CNY'
   INNER JOIN (SELECT T2.CONTRACT_NUM AS CONTRACT_NUM,
                      SUM(NVL(T4.DEP_AMT * T6.CCY_RATE, 0)) AS DEP_AMT, --本行存单
                      T4.DEP_MATURITY,
                      T4.ORG_NUM,
                      T4.COLL_CCY
                 FROM PM_RSDATA.SMTMODS_L_AGRE_GUA_RELATION T2
                INNER JOIN PM_RSDATA.SMTMODS_L_AGRE_GUARANTEE_RELATION T3
                   ON T2.GUAR_CONTRACT_NUM = T3.GUAR_CONTRACT_NUM
                  AND T3.DATA_DATE = I_DATADATE
                INNER JOIN PM_RSDATA.SMTMODS_L_AGRE_GUARANTY_INFO T4
                   ON T3.GUARANTEE_SERIAL_NUM = T4.GUARANTEE_SERIAL_NUM
                  AND T4.DATA_DATE = I_DATADATE
                  AND T4.COLL_TYP = 'A0201' --本行存单
                 LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T6
                   ON T6.DATA_DATE = I_DATADATE
                  AND T6.BASIC_CCY = T3.CURR_CD --担保物折币
                  AND T6.FORWARD_CCY = 'CNY'
                WHERE T2.DATA_DATE = I_DATADATE
                  /*AND T2.ORG_NUM NOT LIKE '51%'
                  AND T4.ORG_NUM NOT LIKE '51%'*/
                  AND T4.DEP_MATURITY - I_DATADATE <= 30
                  AND T4.DEP_MATURITY - I_DATADATE >= 1
                  AND T4.DEP_AMT <> 0
                  AND COLL_STATUS='Y'--有效
                GROUP BY T2.CONTRACT_NUM,
                         T4.DEP_MATURITY,
                         T4.ORG_NUM,
                         T4.COLL_CCY) TM
      ON T1.ACCT_NUM = TM.CONTRACT_NUM
   WHERE T1.DATA_DATE = I_DATADATE
     AND T1.CANCEL_FLG = 'N'
     /*AND T1.ORG_NUM NOT LIKE '51%'*/
     AND ACTUAL_MATURITY_DT - I_DATADATE <= 30
     AND ACTUAL_MATURITY_DT - I_DATADATE >= 1
     AND T1.LOAN_ACCT_BAL <> 0
     AND T1.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
   GROUP BY T1.LOAN_NUM,
            T1.ORG_NUM,
            T1.CURR_CD,
            T1.ACTUAL_MATURITY_DT,
            TM.CONTRACT_NUM,
            TM.ORG_NUM,
            TM.COLL_CCY,
            TM.DEP_AMT,
            TM.DEP_MATURITY;
COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据一个月内到期用于质押的存款金额、贷款金额明细至FDM_LNAC_PLEDGE_G22中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--====================================================
    --G22   8.一个月内到期用于质押的存款金额
--====================================================
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据8.一个月内到期用于质押的存款金额至G22_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
COMMIT;

INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE, ORG_NUM, 'G22R_8..B', CUR_BAL
    FROM (SELECT 
           I_DATADATE AS DATA_DATE,
           A.ORG_NO AS ORG_NUM,
           A.COLL_CCY AS CURR_CD,
           SUM(DEP_AMT) CUR_BAL
            FROM PM_RSDATA.CBRC_FDM_LNAC_PLEDGE_G22 A
           WHERE COLL_CCY <> 'CNY'
           GROUP BY A.ORG_NO, A.COLL_CCY);
COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据8.一个月内到期用于质押的存款金额至G22_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--====================================================
    --G22   9.项目8.用于质押的有关贷款金额
--====================================================
 V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据9.项目8.用于质押的有关贷款金额至G22_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
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
COMMIT;
INSERT 
INTO PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI 
  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
  SELECT DATA_DATE, ORG_NUM, 'G22R_9..B', CUR_BAL AS CUR_CNY_BAL
    FROM (SELECT 
           I_DATADATE AS DATA_DATE,
           A.ORG_NUM,
           A.CURR_CD AS CURR_CD,
           SUM(LOAN_ACCT_BAL) CUR_BAL
            FROM PM_RSDATA.CBRC_FDM_LNAC_PLEDGE_G22 A
           WHERE CURR_CD <> 'CNY'
           GROUP BY A.ORG_NUM, A.CURR_CD);
COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据9.项目8.用于质押的有关贷款金额至G22_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据G22数据插至A_REPT_ITEM_VAL_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值
       FLAG, --标志位
       B_CURR_CD)
      SELECT I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G22R' AS REP_NUM,
             ITEM_NUM,
             SUM(T.ITEM_VAL) AS ITEM_VAL,
             '2' AS FLAG,
             CASE
               WHEN ITEM_NUM LIKE '%A' THEN
                'CNY'
               ELSE
                'FCY'
             END AS B_CURR_CD
        FROM PM_RSDATA.CBRC_G22_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM, T.ITEM_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据G22数据插至A_REPT_ITEM_VAL_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

-------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据G22的A_REPT_ITEM_VAL_NGI至1104目标表A_REPT_ITEM_VAL';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND T.REP_NUM = 'G22R';
    COMMIT;
    INSERT INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD)
      SELECT DATA_DATE,
             ORG_NUM,
             SYS_NAM,
             REP_NUM,
             ITEM_NUM,
             ITEM_VAL,
             ITEM_VAL_V,
             FLAG,
             B_CURR_CD
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.REP_NUM = 'G22R';
COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据G22的A_REPT_ITEM_VAL_NGI至1104目标表A_REPT_ITEM_VAL完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DBMS_OUTPUT.PUT_LINE('O_STATUS=0');
    DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=完成'); 
    ------------------------------------------------------------------

  END IF;

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
   
END proc_cbrc_idx2_g22