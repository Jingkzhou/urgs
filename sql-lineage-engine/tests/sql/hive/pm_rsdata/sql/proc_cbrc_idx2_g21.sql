CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g21(II_DATADATE IN string --跑批日期
)
/******************************
  @author:DJH
  @create-date:20210930
  @description:G21
  @modification history:
  m0.author-create_date-description
  m1.djh 20240115 去掉非循环授信,循环授信、信用卡未使用额度变更,影响G2501、G2502的2.1.4.10未提取的不可无条件撤销的信用便利和流动性便利
  m2.djh 20241106 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期,逾期贷款取贷款余额；
  如果是按月分期还款的个人消费贷款本金或利息逾期,逾期贷款在逾期时间90天以内的取逾期部分,逾期90天以上的取贷款余额
  m3.需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求?上线日期：2025-05-13,修改人：石雨,提出人：王曦若?
  需求编号：JLBA202505280011 上线日期： 2025-09-19,修改人：狄家卉,提出人：赵翰君  修改原因：关于实现1104监管报送报表自动化采集加工的需求  增加009801清算中心(国际业务部)外币折人民币业务
  [JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
目标表：PM_RSDATA.CBRC_A_REPT_ITEM_VAL
        PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI
        PM_RSDATA.CBRC_FDM_LNAC
        PM_RSDATA.CBRC_FDM_LNAC_GL
        PM_RSDATA.CBRC_FDM_LNAC_PMT
        PM_RSDATA.CBRC_FDM_LNAC_PMT_BW
        PM_RSDATA.CBRC_FDM_LNAC_PMT_LX
        PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
        PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
        PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI_YB
        PM_RSDATA.CBRC_ITEM_CD_TEMP
        PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP
        PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1
        PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_ORGNUM
        PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP
        PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP_DIFF
        PM_RSDATA.CBRC_L_ACCT_LOAN_PAYM_SCHED_BJ
        PM_RSDATA.CBRC_L_ACCT_LOAN_PAYM_SCHED_LX
        PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL
        PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL
        PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL
        PM_RSDATA.CBRC_TMP_BZJ_MATUR_DATE
        PM_RSDATA.CBRC_TMP_BZJ_O_ACCT_NUM
        PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL
        PM_RSDATA.CBRC_TMP_SECURITY_OBS_LOAN
        PM_RSDATA.CBRC_TMP_SECURITY_RESULT
集市表：PM_RSDATA.SMTMODS_L_ACCT_CARD_CREDIT
        PM_RSDATA.SMTMODS_L_ACCT_DEPOSIT
        PM_RSDATA.SMTMODS_L_ACCT_FUND_BOND_ISSUE
        PM_RSDATA.SMTMODS_L_ACCT_FUND_MMFUND_PAYM_SCHED
        PM_RSDATA.SMTMODS_L_ACCT_LOAN
        PM_RSDATA.SMTMODS_L_ACCT_LOAN_PAYM_SCHED
        PM_RSDATA.SMTMODS_L_ACCT_OBS_LOAN
        PM_RSDATA.SMTMODS_L_AGRE_BOND_INFO
        PM_RSDATA.SMTMODS_L_AGRE_LOAN_CONTRACT
        PM_RSDATA.SMTMODS_L_AGRE_OTHER_SUBJECT_INFO
        PM_RSDATA.SMTMODS_L_CUST_C
        PM_RSDATA.SMTMODS_L_CUST_P
        PM_RSDATA.SMTMODS_L_FIMM_PRODUCT
        PM_RSDATA.SMTMODS_L_FIMM_PRODUCT_BAL
        PM_RSDATA.SMTMODS_L_FINA_GL
        PM_RSDATA.SMTMODS_L_PUBL_RATE
PM_RSDATA.SMTMODS_V_PUB_FUND_CDS_BAL
PM_RSDATA.CBRC_V_PUB_FUND_INVEST
PM_RSDATA.CBRC_V_PUB_FUND_MMFUND
PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE
PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL


  *******************************/
 IS
  V_SCHEMA       VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE    VARCHAR(30); --当前储存过程名称
  V_TAB_NAME     VARCHAR(30); --目标表名
  I_DATADATE     string; --数据日期(数值型)YYYYMMDD
  V_DATADATE     VARCHAR(10); --数据日期(字符型)YYYY-MM-DD
  D_DATADATE_CCY string; --数据日期(日期型)YYYYMMDD
  V_STEP_ID      INTEGER; --任务号
  V_ERRORCODE    VARCHAR(20); --错误编码
  V_STEP_DESC    VARCHAR(300); --任务描述
  V_STEP_FLAG    INTEGER; --任务执行状态标识
  V_ERRORDESC    VARCHAR(280); --错误内容
  II_STATUS      INTEGER DEFAULT 0; --断点续跑时,用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM       VARCHAR2(30);
  

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';

    I_DATADATE     := II_DATADATE;
    V_PROCEDURE    := UPPER('PROC_CBRC_IDX2_G21');
    D_DATADATE_CCY := I_DATADATE;
    V_TAB_NAME     := 'PM_RSDATA.CBRC_A_REPT_ITEM_VAL';
    V_SYSTEM 
	
  

    V_STEP_FLAG := 1;
    V_STEP_DESC := '参数初始化处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']G21当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --资产表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_FDM_LNAC ';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_FDM_LNAC_PMT';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_FDM_LNAC_PMT_LX';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_FDM_LNAC_GL';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_FDM_LNAC_PMT_BW';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_L_ACCT_LOAN_PAYM_SCHED_BJ';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_L_ACCT_LOAN_PAYM_SCHED_LX';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI_YB';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL';

    --负债表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP_DIFF'; --存款类型分组
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL'; ---存款数据分析汇总
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_SECURITY_OBS_LOAN'; --原业务及保证金账户临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_SECURITY_RESULT';--保证金最终处理结果
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_BZJ_O_ACCT_NUM';--保证金账号按账户分组数据处理
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_BZJ_MATUR_DATE';--保证金账号到期日数据处理


    EXECUTE IMMEDIATE 'TRUNCATE TABLE PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL'; --理财表


    --利息补差值
     --ITEM_CD_TEMP  科目手工映射表  需要迁移全部数据
     EXECUTE IMMEDIATE 'TRUNCATE TABLE  PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1';--科目明细差异对应补录期限
     EXECUTE IMMEDIATE 'TRUNCATE TABLE  PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP';--科目与明细差值表
     EXECUTE IMMEDIATE 'TRUNCATE TABLE  PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_ORGNUM';--轧差机构删除  add  by djh 20230809

    DELETE FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI T
     WHERE T.REP_NUM = 'G21'
       AND DATA_DATE = I_DATADATE;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '清理G21当期数据完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    V_STEP_FLAG := 1;
    V_STEP_DESC := '加工保证金存款基础业务明细数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--取保证金账户不唯一数据
 INSERT INTO PM_RSDATA.CBRC_TMP_BZJ_O_ACCT_NUM
  (O_ACCT_NUM, SHULIANG)
  SELECT O_ACCT_NUM, COUNT(*) SHULIANG
    FROM (SELECT O_ACCT_NUM,
                 D.GL_ITEM_CODE,
                 D.CUST_ID,
                 D.ACCT_NUM,
                 D.ORG_NUM,
                 D.CURR_CD,
                 D.MATUR_DATE,
                 D.ACCT_BALANCE * T2.CCY_RATE
            FROM PM_RSDATA.SMTMODS_L_ACCT_DEPOSIT D
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
              ON T2.DATA_DATE = I_DATADATE
             AND T2.BASIC_CCY = D.CURR_CD --基准币种
             AND T2.FORWARD_CCY = 'CNY'
           WHERE D.DATA_DATE = I_DATADATE
             AND D.ACCT_BALANCE > 0
             AND D.GL_ITEM_CODE IN
                 ('20110114', '20110115', '20110209', '20110210'))
   GROUP BY O_ACCT_NUM
  HAVING COUNT(*) > 1;

COMMIT;
--DEPOSIT_NUM 不同的两个账户,如果到期日也不同那么取最新
 INSERT INTO PM_RSDATA.CBRC_TMP_BZJ_MATUR_DATE
  (O_ACCT_NUM, MATUR_DATE, RN)
  SELECT *
    FROM (SELECT D.O_ACCT_NUM,
                 D.MATUR_DATE,
                 ROW_NUMBER() OVER(PARTITION BY D.O_ACCT_NUM ORDER BY D.MATUR_DATE DESC) AS RN
            FROM PM_RSDATA.SMTMODS_L_ACCT_DEPOSIT D
           INNER JOIN PM_RSDATA.CBRC_TMP_BZJ_O_ACCT_NUM K
              ON D.O_ACCT_NUM = K.O_ACCT_NUM
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
              ON T2.DATA_DATE = I_DATADATE
             AND T2.BASIC_CCY = D.CURR_CD --基准币种
             AND T2.FORWARD_CCY = 'CNY'
           WHERE D.DATA_DATE = I_DATADATE
             AND D.ACCT_BALANCE > 0
             AND D.GL_ITEM_CODE IN
                 ('20110114', '20110115', '20110209', '20110210')) T
   WHERE T.RN = 1;
COMMIT;
--保证金数据处理,如果保证金可以关联原业务,那么按照原业务划分期限,找不到原业务按照保证金本身划分期限
--存款,贷款,保证金业务币种需要转换后再处理

INSERT INTO PM_RSDATA.CBRC_TMP_SECURITY_OBS_LOAN
  (LOAN_NUM,
   SECURITY_ACCT_NUM,
   MATURITY_DT,
   DRAWDOWN_AMT,
   SECURITY_BALANCE,
   SECURITY_RATE,
   ITEM_CD,
   ORG_NUM,
   CURR_CD)
--取原业务及保证金金额
  SELECT T.LOAN_NUM,
         T.SECURITY_ACCT_NUM,
         T.ACTUAL_MATURITY_DT AS MATURITY_DT,
         T.DRAWDOWN_AMT,
         T.DRAWDOWN_AMT * T.SECURITY_RATE * T2.CCY_RATE SECURITY_AMT, --放款金额*保证金比例
         T.SECURITY_RATE,
         T.ITEM_CD,
         T.ORG_NUM,
         T.CURR_CD
    FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN T
    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
      ON T2.DATA_DATE = I_DATADATE
     AND T2.BASIC_CCY = T.CURR_CD --基准币种
     AND T2.FORWARD_CCY = 'CNY'
   WHERE T.DATA_DATE = I_DATADATE
     AND T.SECURITY_ACCT_NUM IS NOT NULL
     AND T.ACTUAL_MATURITY_DT > I_DATADATE
     AND T.SECURITY_RATE > 0
  UNION
  SELECT O.ACCT_NUM LOAN_NUM,
         O.SECURITY_ACCT_NUM,
         O.END_DT AS MATURITY_DT,
         O.BALANCE AS DRAWDOWN_AMT,
         O.BALANCE * O.SECURITY_RATE * T2.CCY_RATE SECURITY_AMT,
         O.SECURITY_RATE,
         O.GL_ITEM_CODE,
         O.ORG_NUM,
         O.CURR_CD
    FROM PM_RSDATA.SMTMODS_L_ACCT_OBS_LOAN O
    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
      ON T2.DATA_DATE = I_DATADATE
     AND T2.BASIC_CCY = O.CURR_CD --基准币种
     AND T2.FORWARD_CCY = 'CNY'
   WHERE O.DATA_DATE = I_DATADATE
     AND END_DT > I_DATADATE
     AND O.SECURITY_ACCT_NUM IS NOT NULL
     AND O.SECURITY_RATE > 0
     ;
COMMIT;

--保证金最终处理开始

INSERT INTO PM_RSDATA.CBRC_TMP_SECURITY_RESULT
  (ACCT_NUM,
   SECURITY_ACCT_NUM,
   MATURITY_DT,
   SECURITY_BALANCE,
   ITEM_CD,
   SOURCE,
   ORG_NUM,
   CURR_CD,
   LOAN_NUM,
   CUST_ID)
  SELECT M.ACCT_NUM, --保证金账号
         L.SECURITY_ACCT_NUM,
         L.MATURITY_DT, --原业务到期日
         L.SECURITY_BALANCE,
         M.GL_ITEM_CODE,
         '原业务保证金金额小于保证金账号余额',
         M.ORG_NUM,
         M.CURR_CD, --存款币种
         L.LOAN_NUM, --原业务账号
         M.CUST_ID
    FROM PM_RSDATA.CBRC_TMP_SECURITY_OBS_LOAN L
   INNER JOIN (SELECT 
                T.SECURITY_ACCT_NUM,
                D.ACCT_NUM,
                D.ORG_NUM,
                D.CUST_ID,
                D.GL_ITEM_CODE,
                D.CURR_CD
                 FROM (SELECT T.SECURITY_ACCT_NUM,
                              SUM(T.SECURITY_BALANCE) ACCT_BALANCE
                         FROM PM_RSDATA.CBRC_TMP_SECURITY_OBS_LOAN T
                        GROUP BY T.SECURITY_ACCT_NUM) T
                INNER JOIN (SELECT D.O_ACCT_NUM,
                                  D.GL_ITEM_CODE,
                                  D.CUST_ID,
                                  D.ACCT_NUM,
                                  D.ORG_NUM,
                                  D.CURR_CD,
                                  SUM(D.ACCT_BALANCE * T2.CCY_RATE) AS ACCT_BALANCE
                             FROM PM_RSDATA.SMTMODS_L_ACCT_DEPOSIT D
                             LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                               ON T2.DATA_DATE = I_DATADATE
                              AND T2.BASIC_CCY = D.CURR_CD --基准币种
                              AND T2.FORWARD_CCY = 'CNY'
                            WHERE D.DATA_DATE = I_DATADATE
                              AND D.ACCT_BALANCE > 0
                              AND D.GL_ITEM_CODE IN ('20110114','20110115','20110209','20110210')
                              GROUP BY D.O_ACCT_NUM,
                                  D.GL_ITEM_CODE,
                                  D.CUST_ID,
                                  D.ACCT_NUM,
                                  D.ORG_NUM,
                                  D.CURR_CD) D
                   ON T.SECURITY_ACCT_NUM = D.O_ACCT_NUM
                WHERE T.ACCT_BALANCE <= D.ACCT_BALANCE) M --可能存在外币数据,存款 |(原业务)表外、贷款折币后比较
      ON L.SECURITY_ACCT_NUM = M.SECURITY_ACCT_NUM;
COMMIT;

INSERT INTO PM_RSDATA.CBRC_TMP_SECURITY_RESULT
  (ACCT_NUM,
   SECURITY_ACCT_NUM,
   MATURITY_DT,
   SECURITY_BALANCE,
   ITEM_CD,
   SOURCE,
   ORG_NUM,
   CURR_CD,
   CUST_ID)
  SELECT 
   D.ACCT_NUM,
   T.SECURITY_ACCT_NUM,
   D.MATUR_DATE,
   D.ACCT_BALANCE - T.SECURITY_BALANCE SECURITY_BALANCE,
   D.GL_ITEM_CODE,
   '保证金关联原业务剩余部分',
   D.ORG_NUM,
   D.CURR_CD,
   D.CUST_ID
    FROM (SELECT R.SECURITY_ACCT_NUM,
                 SUM(R.SECURITY_BALANCE) SECURITY_BALANCE
            FROM PM_RSDATA.CBRC_TMP_SECURITY_RESULT R
           GROUP BY R.SECURITY_ACCT_NUM) T
   INNER JOIN (SELECT D.O_ACCT_NUM,
                      D.GL_ITEM_CODE,
                      D.CUST_ID,
                      D.ACCT_NUM,
                      D.ORG_NUM,
                      D.CURR_CD,
                      D.MATUR_DATE,
                      SUM(D.ACCT_BALANCE * T2.CCY_RATE) AS ACCT_BALANCE
                 FROM PM_RSDATA.SMTMODS_L_ACCT_DEPOSIT D
                 LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                   ON T2.DATA_DATE = I_DATADATE
                  AND T2.BASIC_CCY = D.CURR_CD --基准币种
                  AND T2.FORWARD_CCY = 'CNY'
                WHERE D.DATA_DATE = I_DATADATE
                  AND D.ACCT_BALANCE > 0
                  AND D.GL_ITEM_CODE IN
                      ('20110114', '20110115', '20110209', '20110210')
                  AND D.O_ACCT_NUM NOT IN
                      (SELECT O_ACCT_NUM FROM PM_RSDATA.CBRC_TMP_BZJ_O_ACCT_NUM)
                GROUP BY D.O_ACCT_NUM,
                         D.GL_ITEM_CODE,
                         D.CUST_ID,
                         D.ACCT_NUM,
                         D.ORG_NUM,
                         D.CURR_CD,
                         D.MATUR_DATE
               UNION ALL  --特殊处理
               SELECT T1.O_ACCT_NUM,
                      T1.GL_ITEM_CODE,
                      T1.CUST_ID,
                      T1.ACCT_NUM,
                      T1.ORG_NUM,
                      T1.CURR_CD,
                      T3.MATUR_DATE,
                      ACCT_BALANCE
                 FROM (SELECT D.O_ACCT_NUM,
                              D.GL_ITEM_CODE,
                              D.CUST_ID,
                              D.ACCT_NUM,
                              D.ORG_NUM,
                              D.CURR_CD,
                              SUM(D.ACCT_BALANCE * T2.CCY_RATE) AS ACCT_BALANCE
                         FROM PM_RSDATA.SMTMODS_L_ACCT_DEPOSIT D
                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                           ON T2.DATA_DATE = I_DATADATE
                          AND T2.BASIC_CCY = D.CURR_CD --基准币种
                          AND T2.FORWARD_CCY = 'CNY'
                        WHERE D.DATA_DATE = I_DATADATE
                          AND D.ACCT_BALANCE > 0
                          AND D.GL_ITEM_CODE IN
                              ('20110114', '20110115', '20110209', '20110210')
                          AND D.O_ACCT_NUM IN
                              (SELECT O_ACCT_NUM FROM PM_RSDATA.CBRC_TMP_BZJ_O_ACCT_NUM)
                        GROUP BY D.O_ACCT_NUM,
                                 D.GL_ITEM_CODE,
                                 D.CUST_ID,
                                 D.ACCT_NUM,
                                 D.ORG_NUM,
                                 D.CURR_CD) T1
                 LEFT JOIN PM_RSDATA.CBRC_TMP_BZJ_MATUR_DATE T3     --如果两笔账户有不到到期日期,那么取最新的
                   ON T1.O_ACCT_NUM = T3.O_ACCT_NUM) D
      ON T.SECURITY_ACCT_NUM = D.O_ACCT_NUM
   WHERE D.ACCT_BALANCE - T.SECURITY_BALANCE > 0;
COMMIT;

INSERT INTO PM_RSDATA.CBRC_TMP_SECURITY_RESULT
  (ACCT_NUM,
   SECURITY_ACCT_NUM,
   MATURITY_DT,
   SECURITY_BALANCE,
   ITEM_CD,
   SOURCE,
   ORG_NUM,
   CURR_CD,
   CUST_ID)
  SELECT 
   D.ACCT_NUM,
   D.O_ACCT_NUM,
   D.MATUR_DATE,
   D.ACCT_BALANCE,
   D.GL_ITEM_CODE,
   '原业务保证金大于保证金账号余额,取保证金账号余额',
   D.ORG_NUM,
   D.CURR_CD,
   D.CUST_ID
    FROM (SELECT T.SECURITY_ACCT_NUM, SUM(T.SECURITY_BALANCE) ACCT_BALANCE
            FROM PM_RSDATA.CBRC_TMP_SECURITY_OBS_LOAN T
           GROUP BY T.SECURITY_ACCT_NUM) T
   INNER JOIN (SELECT D.O_ACCT_NUM,
                      D.GL_ITEM_CODE,
                      D.CUST_ID,
                      D.ACCT_NUM,
                      D.ORG_NUM,
                      D.CURR_CD,
                      D.MATUR_DATE,
                      SUM(D.ACCT_BALANCE * T2.CCY_RATE) AS ACCT_BALANCE
                 FROM PM_RSDATA.SMTMODS_L_ACCT_DEPOSIT D
                 LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                   ON T2.DATA_DATE = I_DATADATE
                  AND T2.BASIC_CCY = D.CURR_CD --基准币种
                  AND T2.FORWARD_CCY = 'CNY'
                WHERE D.DATA_DATE = I_DATADATE
                  AND D.ACCT_BALANCE > 0
                  AND D.GL_ITEM_CODE IN
                      ('20110114', '20110115', '20110209', '20110210')
                  AND D.O_ACCT_NUM NOT IN
                      (SELECT O_ACCT_NUM FROM PM_RSDATA.CBRC_TMP_BZJ_O_ACCT_NUM)
                GROUP BY D.O_ACCT_NUM,
                         D.GL_ITEM_CODE,
                         D.CUST_ID,
                         D.ACCT_NUM,
                         D.ORG_NUM,
                         D.CURR_CD,
                         D.MATUR_DATE
               UNION ALL   -- 特殊处理
               SELECT T1.O_ACCT_NUM,
                      T1.GL_ITEM_CODE,
                      T1.CUST_ID,
                      T1.ACCT_NUM,
                      T1.ORG_NUM,
                      T1.CURR_CD,
                      T3.MATUR_DATE,
                      ACCT_BALANCE
                 FROM (SELECT D.O_ACCT_NUM,
                              D.GL_ITEM_CODE,
                              D.CUST_ID,
                              D.ACCT_NUM,
                              D.ORG_NUM,
                              D.CURR_CD,
                              SUM(D.ACCT_BALANCE * T2.CCY_RATE) AS ACCT_BALANCE
                         FROM PM_RSDATA.SMTMODS_L_ACCT_DEPOSIT D
                         LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                           ON T2.DATA_DATE = I_DATADATE
                          AND T2.BASIC_CCY = D.CURR_CD --基准币种
                          AND T2.FORWARD_CCY = 'CNY'
                        WHERE D.DATA_DATE = I_DATADATE
                          AND D.ACCT_BALANCE > 0
                          AND D.GL_ITEM_CODE IN
                              ('20110114',
                               '20110115',
                               '20110209',
                               '20110210')
                          AND D.O_ACCT_NUM IN
                              (SELECT O_ACCT_NUM FROM PM_RSDATA.CBRC_TMP_BZJ_O_ACCT_NUM)
                        GROUP BY D.O_ACCT_NUM,
                                 D.GL_ITEM_CODE,
                                 D.CUST_ID,
                                 D.ACCT_NUM,
                                 D.ORG_NUM,
                                 D.CURR_CD) T1
                 LEFT JOIN PM_RSDATA.CBRC_TMP_BZJ_MATUR_DATE T3  --如果两笔账户有不到到期日期,那么取最新的
                   ON T1.O_ACCT_NUM = T3.O_ACCT_NUM) D
      ON T.SECURITY_ACCT_NUM = D.O_ACCT_NUM
   WHERE T.ACCT_BALANCE > D.ACCT_BALANCE;

COMMIT;

INSERT INTO PM_RSDATA.CBRC_TMP_SECURITY_RESULT
  (ACCT_NUM,
   SECURITY_ACCT_NUM,
   MATURITY_DT,
   SECURITY_BALANCE,
   ITEM_CD,
   SOURCE,
   ORG_NUM,
   CURR_CD,
   CUST_ID)
  SELECT 
   D.ACCT_NUM,
   D.O_ACCT_NUM,
   D.MATUR_DATE,
   D.ACCT_BALANCE* T2.CCY_RATE,
   D.GL_ITEM_CODE,
   '关联不上原业务,或原业务到期日小于当前日期,或原业务余额等于0,取保证金账号到期日',
   D.ORG_NUM,
   D.CURR_CD,
   D.CUST_ID
    FROM PM_RSDATA.SMTMODS_L_ACCT_DEPOSIT D
    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                               ON T2.DATA_DATE = I_DATADATE
                              AND T2.BASIC_CCY = D.CURR_CD --基准币种
                              AND T2.FORWARD_CCY = 'CNY'
    LEFT JOIN (SELECT T.SECURITY_ACCT_NUM,
                      SUM(T.SECURITY_BALANCE) ACCT_BALANCE
                 FROM PM_RSDATA.CBRC_TMP_SECURITY_OBS_LOAN T
                GROUP BY T.SECURITY_ACCT_NUM) T
      ON T.SECURITY_ACCT_NUM = D.O_ACCT_NUM
   WHERE D.DATA_DATE = I_DATADATE
     AND D.ACCT_BALANCE > 0
     AND T.SECURITY_ACCT_NUM IS NULL
     AND D.GL_ITEM_CODE IN ('20110114','20110115','20110209','20110210')
     ;

COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工保证金存款基础业务明细数据完成';
    --V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    V_STEP_FLAG := 1;
    V_STEP_DESC := '加工通知存款明细数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    -- 通知存款特殊处理,其他存款正常划分期限
    --1、202,203通知存款,有通知到期日且为(1天)次日的,放到次日,其他不管1天通知,还是7天通知,都放到2-7日
    INSERT 
    INTO PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP_DIFF 
      (DATA_DATE,
       ACCT_NUM,
       ORG_NUM,
       CUST_ID,
       DEPOSIT_NUM,
       CURR_CD,
       ACCT_TYPE,
       ST_INT_DT,
       ACCT_BALANCE,
       ACCT_BALANCE_RMB,
       ACCT_BALANCE_USD,
       MATUR_DATE,
       INT_RATE_TYP,
       INT_RATE,
       NEXT_INT_REVI_DATE,
       ACCU_INT_FLG,
       ACCT_STS,
       PBOC_ACCT_NATURE_CD,
       ACCT_OPDATE,
       ACCT_CLDATE,
       AMT,
       LIMIT_TYPE,
       ACCOUNT_LIMIT,
       GL_ITEM_CODE,
       LAST_TX_DATE,
       TERM_TYPE,
       ACTUAL_TERM,
       OPEN_TELLER,
       ACCOUNT_CATA_FLG,
       SP_ACCT_TYPE,
       ENTRUST_ACCT_TYPE,
       STABLE_RISK_TYPE,
       BUS_REL,
       PLEDGE_ASSETS_TYPE,
       PLEDGE_ASSETS_VAL,
       IS_INLINE_OPTIONS,
       CALL_DEPOSIT_DATE,
       CALL_DEPOSIT_AMT,
       DEPARTMENTD,
       DATE_SOURCESD,
       ORI_TERM_CODE,
       REMAIN_TERM_CODE,
       IS_ONLINE_ABLE,
       ADVANCE_DRAW_FLG,
       C_DEPOSIT_TYP,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       ACCT_NAM,
       INTEREST_ACCURED, --应计利息
       NEXT_RATE_DATE,--下一付息日
       STABLE_DEP_TYPE,
       O_ACCT_NUM --外部账号 关联保证金,存单质押等
       )
      SELECT 
       DATA_DATE,
       ACCT_NUM,
       ORG_NUM,
       CUST_ID,
       DEPOSIT_NUM,
       CURR_CD,
       ACCT_TYPE,
       ST_INT_DT,
       NVL(A.CALL_DEPOSIT_AMT, 0) AS ACCT_BALANCE, --1天通知,通知额
       ACCT_BALANCE_RMB,
       ACCT_BALANCE_USD,
       MATUR_DATE,
       INT_RATE_TYP,
       INT_RATE,
       NEXT_INT_REVI_DATE,
       ACCU_INT_FLG,
       ACCT_STS,
       PBOC_ACCT_NATURE_CD,
       ACCT_OPDATE,
       ACCT_CLDATE,
       AMT,
       LIMIT_TYPE,
       ACCOUNT_LIMIT,
       GL_ITEM_CODE,
       LAST_TX_DATE,
       TERM_TYPE,
       ACTUAL_TERM,
       OPEN_TELLER,
       ACCOUNT_CATA_FLG,
       SP_ACCT_TYPE,
       ENTRUST_ACCT_TYPE,
       STABLE_RISK_TYPE,
       BUS_REL,
       PLEDGE_ASSETS_TYPE,
       PLEDGE_ASSETS_VAL,
       IS_INLINE_OPTIONS,
       CALL_DEPOSIT_DATE,
       CALL_DEPOSIT_AMT,
       DEPARTMENTD,
       DATE_SOURCESD,
       ORI_TERM_CODE,
        '1' AS REMAIN_TERM_CODE, -- 0401一天通知存款 0402  七天通知存款
       IS_ONLINE_ABLE,
       ADVANCE_DRAW_FLG,
       C_DEPOSIT_TYP,
       '0' AS INTEREST_ACCURAL,   --应付利息 --防止重复,此处利息置空,在第二段取数
       INTEREST_ACCURAL_ITEM,
       A.ACCT_NAM,
       '0' INTEREST_ACCURED, --应计利息 --防止重复,此处利息置空,在第二段取数
       A.NEXT_RATE_DATE, --下一付息日
       STABLE_DEP_TYPE,
       O_ACCT_NUM --外部账号
        FROM PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP A
       WHERE A.DATA_DATE = I_DATADATE
         /*AND A.ORG_NUM NOT LIKE '51%'*/ --add 刘晟典
         AND A.GL_ITEM_CODE IN ('20110205', '20110110')
         AND (A.ACCT_BALANCE <> 0 or INTEREST_ACCURAL<>0 or INTEREST_ACCURED <>0)
         AND A.CALL_DEPOSIT_DATE-D_DATADATE_CCY =1;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP_DIFF 
      (DATA_DATE,
       ACCT_NUM,
       ORG_NUM,
       CUST_ID,
       DEPOSIT_NUM,
       CURR_CD,
       ACCT_TYPE,
       ST_INT_DT,
       ACCT_BALANCE,
       ACCT_BALANCE_RMB,
       ACCT_BALANCE_USD,
       MATUR_DATE,
       INT_RATE_TYP,
       INT_RATE,
       NEXT_INT_REVI_DATE,
       ACCU_INT_FLG,
       ACCT_STS,
       PBOC_ACCT_NATURE_CD,
       ACCT_OPDATE,
       ACCT_CLDATE,
       AMT,
       LIMIT_TYPE,
       ACCOUNT_LIMIT,
       GL_ITEM_CODE,
       LAST_TX_DATE,
       TERM_TYPE,
       ACTUAL_TERM,
       OPEN_TELLER,
       ACCOUNT_CATA_FLG,
       SP_ACCT_TYPE,
       ENTRUST_ACCT_TYPE,
       STABLE_RISK_TYPE,
       BUS_REL,
       PLEDGE_ASSETS_TYPE,
       PLEDGE_ASSETS_VAL,
       IS_INLINE_OPTIONS,
       CALL_DEPOSIT_DATE,
       CALL_DEPOSIT_AMT,
       DEPARTMENTD,
       DATE_SOURCESD,
       ORI_TERM_CODE,
       REMAIN_TERM_CODE,
       IS_ONLINE_ABLE,
       ADVANCE_DRAW_FLG,
       C_DEPOSIT_TYP,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       ACCT_NAM,
       INTEREST_ACCURED, --应计利息
       NEXT_RATE_DATE, --下一付息日
       STABLE_DEP_TYPE,
       O_ACCT_NUM --外部账号 关联保证金,存单质押等
       )
      SELECT 
       DATA_DATE,
       ACCT_NUM,
       ORG_NUM,
       CUST_ID,
       DEPOSIT_NUM,
       CURR_CD,
       ACCT_TYPE,
       ST_INT_DT,
       CASE
         WHEN A.CALL_DEPOSIT_DATE - I_DATADATE = 1 THEN
          A.ACCT_BALANCE - NVL(A.CALL_DEPOSIT_AMT, 0)
         ELSE
          A.ACCT_BALANCE
       END AS ACCT_BALANCE, --1天通知剩余通知额 or 其他账户余额
       ACCT_BALANCE_RMB,
       ACCT_BALANCE_USD,
       MATUR_DATE,
       INT_RATE_TYP,
       INT_RATE,
       NEXT_INT_REVI_DATE,
       ACCU_INT_FLG,
       ACCT_STS,
       PBOC_ACCT_NATURE_CD,
       ACCT_OPDATE,
       ACCT_CLDATE,
       AMT,
       LIMIT_TYPE,
       ACCOUNT_LIMIT,
       GL_ITEM_CODE,
       LAST_TX_DATE,
       TERM_TYPE,
       ACTUAL_TERM,
       OPEN_TELLER,
       ACCOUNT_CATA_FLG,
       SP_ACCT_TYPE,
       ENTRUST_ACCT_TYPE,
       STABLE_RISK_TYPE,
       BUS_REL,
       PLEDGE_ASSETS_TYPE,
       PLEDGE_ASSETS_VAL,
       IS_INLINE_OPTIONS,
       CALL_DEPOSIT_DATE,
       CALL_DEPOSIT_AMT,
       DEPARTMENTD,
       DATE_SOURCESD,
       ORI_TERM_CODE,
       '7' AS REMAIN_TERM_CODE, -- 0401一天通知存款 0402  七天通知存款
       IS_ONLINE_ABLE,
       ADVANCE_DRAW_FLG,
       C_DEPOSIT_TYP,
       INTEREST_ACCURAL, --应付利息
       INTEREST_ACCURAL_ITEM,
       A.ACCT_NAM,
       INTEREST_ACCURED, --应计利息
       A.NEXT_RATE_DATE, --下一付息日
       STABLE_DEP_TYPE,
       O_ACCT_NUM --外部账号
        FROM PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP A
       WHERE A.DATA_DATE = I_DATADATE
         /*AND A.ORG_NUM NOT LIKE '51%'*/ -- add 刘晟典
         AND A.GL_ITEM_CODE IN ('20110205', '20110110')
         AND (A.ACCT_BALANCE <> 0 or INTEREST_ACCURAL<>0 or INTEREST_ACCURED <>0);

    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工通知存款明细数据完成';
    --V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_FLAG := 1;
    V_STEP_DESC := '加工除通知存款外其他存款明细数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


   --2、251保证金先找原业务贷款或者表外业务到期日,如果没有,找保证金业务到期日
   --处理保证金本金,利息在后面处理
INSERT 
INTO PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP_DIFF 
  (DATA_DATE,
   ACCT_NUM,
   ORG_NUM,
   CURR_CD,
   ACCT_BALANCE,
   ACCT_BALANCE_RMB,
   MATUR_DATE,
   GL_ITEM_CODE,
   REMAIN_TERM_CODE,
   O_ACCT_NUM, --外部账号 关联保证金,存单质押等
   cust_id
   )
  SELECT 
   I_DATADATE,
   ACCT_NUM, --保证金账号
   ORG_NUM,
   CURR_CD,
   SECURITY_BALANCE,
   SECURITY_BALANCE,
   MATURITY_DT,
   A.ITEM_CD AS GL_ITEM_CODE,
   CASE
     WHEN MATURITY_DT IS NOT NULL THEN
      MATURITY_DT - I_DATADATE
   END AS REMAIN_TERM_CODE, --存款剩余期限代码
   SECURITY_ACCT_NUM,
   A.CUST_ID
    FROM PM_RSDATA.CBRC_TMP_SECURITY_RESULT A;
     /*WHERE  A.ORG_NUM NOT LIKE '51%';*/ -- add 刘晟典
    COMMIT;



   --3、除通知存款,保证金存款外其他存款
    INSERT 
    INTO PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP_DIFF 
      (DATA_DATE,
       ACCT_NUM,
       ORG_NUM,
       CUST_ID,
       DEPOSIT_NUM,
       CURR_CD,
       ACCT_TYPE,
       ST_INT_DT,
       ACCT_BALANCE,
       ACCT_BALANCE_RMB,
       ACCT_BALANCE_USD,
       MATUR_DATE,
       INT_RATE_TYP,
       INT_RATE,
       NEXT_INT_REVI_DATE,
       ACCU_INT_FLG,
       ACCT_STS,
       PBOC_ACCT_NATURE_CD,
       ACCT_OPDATE,
       ACCT_CLDATE,
       AMT,
       LIMIT_TYPE,
       ACCOUNT_LIMIT,
       GL_ITEM_CODE,
       LAST_TX_DATE,
       TERM_TYPE,
       ACTUAL_TERM,
       OPEN_TELLER,
       ACCOUNT_CATA_FLG,
       SP_ACCT_TYPE,
       ENTRUST_ACCT_TYPE,
       STABLE_RISK_TYPE,
       BUS_REL,
       PLEDGE_ASSETS_TYPE,
       PLEDGE_ASSETS_VAL,
       IS_INLINE_OPTIONS,
       CALL_DEPOSIT_DATE,
       CALL_DEPOSIT_AMT,
       DEPARTMENTD,
       DATE_SOURCESD,
       ORI_TERM_CODE,
       REMAIN_TERM_CODE,
       IS_ONLINE_ABLE,
       ADVANCE_DRAW_FLG,
       C_DEPOSIT_TYP,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       ACCT_NAM,
       INTEREST_ACCURED, --应计利息
       NEXT_RATE_DATE, --下一付息日
       STABLE_DEP_TYPE,--稳定存款分类
       O_ACCT_NUM --外部账号 关联保证金,存单质押等
       )
      SELECT 
       DATA_DATE,
       ACCT_NUM,
       A.ORG_NUM,
       CUST_ID,
       DEPOSIT_NUM,
       CURR_CD,
       ACCT_TYPE,
       ST_INT_DT,
       ACCT_BALANCE, --正常余额
       ACCT_BALANCE_RMB,
       ACCT_BALANCE_USD,
       MATUR_DATE,
       INT_RATE_TYP,
       INT_RATE,
       NEXT_INT_REVI_DATE,
       ACCU_INT_FLG,
       ACCT_STS,
       PBOC_ACCT_NATURE_CD,
       ACCT_OPDATE,
       ACCT_CLDATE,
       AMT,
       LIMIT_TYPE,
       ACCOUNT_LIMIT,
       GL_ITEM_CODE,
       LAST_TX_DATE,
       TERM_TYPE,
       ACTUAL_TERM,
       OPEN_TELLER,
       ACCOUNT_CATA_FLG,
       SP_ACCT_TYPE,
       ENTRUST_ACCT_TYPE,
       STABLE_RISK_TYPE,
       BUS_REL,
       PLEDGE_ASSETS_TYPE,
       PLEDGE_ASSETS_VAL,
       IS_INLINE_OPTIONS,
       CALL_DEPOSIT_DATE,
       CALL_DEPOSIT_AMT,
       DEPARTMENTD,
       DATE_SOURCESD,
       ORI_TERM_CODE,
       REMAIN_TERM_CODE, --正常期限
       IS_ONLINE_ABLE,
       ADVANCE_DRAW_FLG,
       C_DEPOSIT_TYP,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       A.ACCT_NAM,
       INTEREST_ACCURED, --应计利息
       A.NEXT_RATE_DATE, --下一付息日
       STABLE_DEP_TYPE,--稳定存款分类
       O_ACCT_NUM --外部账号 关联保证金,存单质押等
        FROM PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP A
       WHERE A.DATA_DATE = I_DATADATE
         /*AND A.ORG_NUM NOT LIKE '51%'*/ -- add 刘晟典
         AND A.GL_ITEM_CODE NOT IN( '20110205' -- 202
                                    ,'20110110' -- 203
                                    ,'20110114','20110115','20110209','20110210' -- 251 -- UPDATE BY WANGKUI 20221118
                                    );
    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '加工除通知存款外其他存款明细数据';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取TMP_A_CBRC_DEPOSIT_BAL存款基础逻辑部分1';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --利息总体处理思路
    --1、应计利息处理规则,应付利息处理规则：属于应付未付：活期利息每个季度的20号,定期利息跟本金走,特殊情况不考虑在内
    --活期利息期限  即,1,2月 季度放在3月20号,3,4,5月,季度6月20号,6,7,8月,季度放在9月20号,9,10,11月,季度放在12月20号,12月在下一年3月20号

    --正常存款+3.2同业存放款项
    --3.2.1定期存放 23402同业存放定期款项 2340499其他金融机构保证金存款 234040102银行业存款类金融机构定期保证金存款
    --3.2.2活期存放  23401同业存放活期款项  234040101银行业存款类金融机构活期保证金存款
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ACCT_TYP, --账户类型
       ACCT_CUR, --账户币种
       ACCT_BAL, --账户余额
       ACCT_BAL_RMB, --账户余额_人民币
       TYPE_ENT, --客户实体类型
       FINA_CODE, --金融机构代码类型
       STABLE_RISK_TYPE, --存款稳定性分类
       REMAIN_TERM_CODE, --存款剩余期限代码
       IS_INLINE_OPTIONS, --是否内嵌提前到期期权
       ADVANCE_DRAW_FLG, --是否可提前支取
       BUS_REL, --是否具有业务关系
       FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       INTEREST_ACCURAL, --应付利息
       INTEREST_ACCURAL_ITEM, --应付利息科目
       CUST_ID, --客户号
       ACCT_NAM, --账户名称
       MATUR_DATE, --到期日
       ACCT_NUM, --账号
       INTEREST_ACCURED, --应计利息
       MATUR_DATE_ACCURED, --应计利息到期日
       STABLE_DEP_TYPE, --稳定存款分类
       O_ACCT_NUM, --外部账号 关联保证金,存单质押等
       REMAIN_TERM_CODE_QX)
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.ORG_NUM AS ORG_NUM, --机构号
       A.ACCT_TYPE AS ACCT_TYP, --账户类型
       A.CURR_CD AS ACCT_CUR, --账户币种
       A.ACCT_BALANCE, --账户余额
       CASE
         WHEN A.GL_ITEM_CODE IN ('20110114','20110115','20110209','20110210') THEN
          A.ACCT_BALANCE
         ELSE
          A.ACCT_BALANCE * CCY_RATE
       END, --账户余额  ADD BY DJH 20220621 注意251保证金本金余额按照原业务拆分且已折币,此处不需要折币
       NULL AS TYPE_ENT, --客户实体类型
       NULL AS FINA_CODE, --金融机构代码类型
       A.STABLE_RISK_TYPE, --存款稳定性分类
       CASE
         WHEN A.REMAIN_TERM_CODE IS NULL OR A.REMAIN_TERM_CODE <= 1 THEN --到期日空值,期限<=0,期限=1
          'A'
         WHEN REMAIN_TERM_CODE BETWEEN 2 AND 7 THEN
          'B' --2日至7日
         WHEN REMAIN_TERM_CODE BETWEEN 8 AND 30 THEN
          'C' --8日至30日
         WHEN REMAIN_TERM_CODE BETWEEN 31 AND 90 THEN
          'D' --31日至90日
         WHEN REMAIN_TERM_CODE BETWEEN 91 AND 360 THEN
          'E' --91日至1年
         WHEN REMAIN_TERM_CODE BETWEEN 361 AND 360 * 5 THEN
          'F' --1年至5年
         WHEN REMAIN_TERM_CODE BETWEEN (360 * 5 + 1) AND 360 * 10 THEN
          'G' --5年至10年
         WHEN REMAIN_TERM_CODE > 360 * 10 THEN
          'H' --10年以上
       END AS REMAIN_TERM_CODE, --存款剩余期限代码,
       A.IS_INLINE_OPTIONS, --是否内嵌提前到期期权
       A.ADVANCE_DRAW_FLG, --是否可提前支取
       A.BUS_REL, --是否具有业务关系
       CASE
         WHEN SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201202' or
              A.GL_ITEM_CODE IN ('20120307','20120308') or A.GL_ITEM_CODE IN ('20120302','20120303','20120304','20120305','20120306') THEN
          '03' --同业定期存放
         WHEN SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201201' or
              A.GL_ITEM_CODE = '20120301' THEN
          '04' --同业活期存放
         ELSE
          '01' --正常存款
       END AS FLAG, --数据标识,
       GL_ITEM_CODE, --科目号
       NVL(A.INTEREST_ACCURAL, 0) * CCY_RATE INTEREST_ACCURAL, --应付利息
       A.INTEREST_ACCURAL_ITEM, --应付利息科目
       A.CUST_ID AS CUST_ID,
       A.ACCT_NAM,
       A.MATUR_DATE,
       ACCT_NUM,
       NVL(A.INTEREST_ACCURED, 0) * CCY_RATE AS INTEREST_ACCURED, --应计利息
       CASE
         WHEN SUBSTR(I_DATADATE, 5, 2) IN ('01', '02') AND
              (SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201201' OR --同业活期科目
               A.GL_ITEM_CODE = '20120301' OR
               (A.GL_ITEM_CODE  IN --各项存款活期科目
                ('20110201', '20110101','20110102', '20110111', '20110206', '20130101','20130201','20130301','20140101','20140201','20140301') OR
                A.GL_ITEM_CODE = '20120106')
                or a.gl_item_code in ('22410101','22410102','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]

                ) THEN
          SUBSTR(I_DATADATE, 1, 4) || '0320'
         WHEN SUBSTR(I_DATADATE, 5, 2) IN ('03','04', '05') AND
              (SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201201' or --同业活期科目
               A.GL_ITEM_CODE = '20120301' OR
               A.GL_ITEM_CODE  IN --各项存款活期科目
                ('20110201', '20110101','20110102', '20110111', '20110206', '20130101','20130201','20130301','20140101','20140201','20140301') OR
                A.GL_ITEM_CODE = '20120106'
                 or a.gl_item_code in ('22410101','22410102','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
                ) THEN
          SUBSTR(I_DATADATE, 1, 4) || '0620'
         WHEN SUBSTR(I_DATADATE, 5, 2) IN ('06','07', '08') AND
              (SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201201' or --同业活期科目
               A.GL_ITEM_CODE = '20120301' OR
               A.GL_ITEM_CODE IN --各项存款活期科目
                ('20110201', '20110101','20110102', '20110111', '20110206', '20130101','20130201','20130301','20140101','20140201','20140301') OR
                A.GL_ITEM_CODE = '20120106'
                or a.gl_item_code in ('22410101','22410102','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
                ) THEN
          SUBSTR(I_DATADATE, 1, 4) || '0920'
         WHEN SUBSTR(I_DATADATE, 5, 2) IN ( '09','10', '11') AND
              (SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201201' or --同业活期科目
               A.GL_ITEM_CODE = '20120301' OR
               A.GL_ITEM_CODE  IN --各项存款活期科目
                ('20110201', '20110101','20110102', '20110111', '20110206', '20130101','20130201','20130301','20140101','20140201','20140301') OR
                A.GL_ITEM_CODE = '20120106'
                 or a.gl_item_code in ('22410101','22410102','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
            ) THEN
          SUBSTR(I_DATADATE, 1, 4) || '1220' --同业存放活期、各项存款活期按照每个季度20日付息
         WHEN SUBSTR(I_DATADATE, 5, 2)  ='12' AND  --下一年的3月20号
              (SUBSTR(A.GL_ITEM_CODE, 1, 6) = '201201' or --同业活期科目
               A.GL_ITEM_CODE = '20120301' OR
               A.GL_ITEM_CODE  IN --各项存款活期科目
                ('20110201', '20110101','20110102', '20110111', '20110206', '20130101','20130201','20130301','20140101','20140201','20140301') OR
                A.GL_ITEM_CODE = '20120106'
                 or a.gl_item_code in ('22410101','22410102','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
                ) THEN
           SUBSTR(TO_CHAR(ADD_MONTHS(DATE(I_DATADATE, 'YYYYMMDD'),1), 'YYYYMMDD') ,1, 4) || '0320' --同业存放活期、各项存款活期按照每个季度20日付息
         ELSE
          A.MATUR_DATE --下一付息日 --同业存放定期、各项存款的
       END AS MATUR_DATE_ACCURED, --应计利息到期日
       STABLE_DEP_TYPE, --稳定存款分类
       O_ACCT_NUM, --外部账号 关联保证金,存单质押等
       A.REMAIN_TERM_CODE
        FROM PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP_DIFF A
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       WHERE ---A.GL_ITEM_CODE NOT LIKE '4%'
       A.GL_ITEM_CODE NOT LIKE '3%'
         AND (SUBSTR(A.GL_ITEM_CODE, 1, 6) NOT IN (/*'201103',*/'201104','201105','201106')--[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款,原逻辑中剔除]
           OR SUBSTR(A.GL_ITEM_CODE, 1, 4) NOT IN ('2005'/*,'2008','2009'*/) )-- 修改内容：调整代理国库业务会计科目_20250513
           ;
         /*AND A.ORG_NUM NOT LIKE '51%';*/
 --财政性去掉,都在3.8有确定到期日资产处理
    --A.GL_ITEM_CODE NOT LIKE '234%' --234科目资金表和存款表都有数据,不从资金表中取数,从存款表出数,利息也从此处出
 COMMIT;


      --251利息  把251本金余额变成0,只是取利息
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ACCT_TYP, --账户类型
       ACCT_CUR, --账户币种
       ACCT_BAL, --账户余额
       ACCT_BAL_RMB, --账户余额_人民币
       TYPE_ENT, --客户实体类型
       FINA_CODE, --金融机构代码类型
       STABLE_RISK_TYPE, --存款稳定性分类
       REMAIN_TERM_CODE, --存款剩余期限代码
       IS_INLINE_OPTIONS, --是否内嵌提前到期期权
       ADVANCE_DRAW_FLG, --是否可提前支取
       BUS_REL, --是否具有业务关系
       FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       INTEREST_ACCURAL, --应付利息
       INTEREST_ACCURAL_ITEM, --应付利息科目
       CUST_ID, --客户号
       ACCT_NAM, --账户名称
       MATUR_DATE, --到期日
       ACCT_NUM, --账号
       INTEREST_ACCURED, --应计利息
       MATUR_DATE_ACCURED, --应计利息到期日
       STABLE_DEP_TYPE, --稳定存款分类
       O_ACCT_NUM --外部账号 关联保证金,存单质押等
       )
      SELECT 
             A.DATA_DATE, --数据日期
             ORG_NUM, --机构号
             A.ACCT_TYPE AS ACCT_TYP, --账户类型
             A.CURR_CD  AS ACCT_CUR, --账户币种
             0 AS ACCT_BAL, --账户余额
             0 AS ACCT_BAL_RMB, --账户余额_人民币
             NULL AS TYPE_ENT, --客户实体类型
             NULL AS FINA_CODE, --金融机构代码类型
             STABLE_RISK_TYPE, --存款稳定性分类
             NULL AS  REMAIN_TERM_CODE, --存款剩余期限代码
             IS_INLINE_OPTIONS, --是否内嵌提前到期期权
             ADVANCE_DRAW_FLG, --是否可提前支取
             BUS_REL, --是否具有业务关系
             '01' FLAG, --数据标识
             GL_ITEM_CODE, --科目号
             NVL(INTEREST_ACCURAL,0)* CCY_RATE, --应付利息
             INTEREST_ACCURAL_ITEM, --应付利息科目
             CUST_ID, --客户号
             ACCT_NAM, --账户名称
             MATUR_DATE, --到期日
             ACCT_NUM, --账号
             NVL(INTEREST_ACCURED,0)* CCY_RATE, --应计利息
             A.MATUR_DATE AS MATUR_DATE_ACCURED, --应计利息到期日
             STABLE_DEP_TYPE, --稳定存款分类
             O_ACCT_NUM --外部账号 关联保证金,存单质押等
        FROM PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP A
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         /*AND A.ORG_NUM NOT LIKE '51%'*/ -- add 刘晟典
         AND A.GL_ITEM_CODE IN ('20110114','20110115','20110209','20110210');
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取TMP_A_CBRC_DEPOSIT_BAL存款基础逻辑部分1完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取TMP_A_CBRC_DEPOSIT_BAL存款基础逻辑部分2';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --3.1向中央银行借
    --23101借入央行款项 23105中期借贷便利  2310201再贴现-面值   23103特殊目的工具贷款 23104常备借贷便利
    --去掉了2310202利息调整
    -- 3.3同业拆入    241 拆入资金
    --[2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务2003拆入资金本金以及应付利息,余额有小于0部分
  INSERT 
  INTO PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL 
    (DATA_DATE, --数据日期
     ORG_NUM, --机构号
     ACCT_TYP, --账户类型
     ACCT_CUR, --账户币种
     ACCT_BAL, --账户余额
     ACCT_BAL_RMB, --账户余额_人民币
     TYPE_ENT, --客户实体类型
     FINA_CODE, --金融机构代码类型
     STABLE_RISK_TYPE, --存款稳定性分类
     REMAIN_TERM_CODE, --存款剩余期限代码
     IS_INLINE_OPTIONS, --是否内嵌提前到期期权
     ADVANCE_DRAW_FLG, --是否可提前支取
     BUS_REL, --是否具有业务关系
     FLAG, --数据标识
     GL_ITEM_CODE, --科目号
     INTEREST_ACCURAL, --应付利息
     INTEREST_ACCURAL_ITEM, --应付利息科目
     CUST_ID, --账户名称
     MATUR_DATE, --到期日
     ACCT_NUM, --账号
     INTEREST_ACCURED, --应计利息
     MATUR_DATE_ACCURED, --应计利息到期日
     O_ACCT_NUM, --外部账号 关联保证金,存单质押等
     REMAIN_TERM_CODE_QX,
     BOOK_TYPE)
    SELECT 
     I_DATADATE AS DATA_DATE, --数据日期
     ORG_NUM, --机构号
     ACCT_TYP AS ACCT_TYP, --账户类型
     CURR_CD AS ACCT_CUR, --账户币种
     A.BALANCE AS ACCT_BAL, --账户余额
     A.BALANCE * CCY_RATE AS ACCT_BAL_RMB, --账户余额_人民币
     NULL AS TYPE_ENT, --客户实体类型
     NULL AS FINA_CODE, --金融机构代码类型
     STABLE_RISK_TYPE, --存款稳定性分类

     CASE
       WHEN A.MATURE_DATE IS NULL OR A.MATURE_DATE - D_DATADATE_CCY <= 1 THEN --到期日空值,期限<=0,期限=1
        'A'
       WHEN A.MATURE_DATE - D_DATADATE_CCY BETWEEN 2 AND 7 THEN
        'B' --2日至7日
       WHEN A.MATURE_DATE - D_DATADATE_CCY BETWEEN 8 AND 30 THEN
        'C' --8日至30日
       WHEN A.MATURE_DATE - D_DATADATE_CCY BETWEEN 31 AND 90 THEN
        'D' --31日至90日
       WHEN A.MATURE_DATE - D_DATADATE_CCY BETWEEN 91 AND 360 THEN
        'E' --91日至1年
       WHEN A.MATURE_DATE - D_DATADATE_CCY BETWEEN 361 AND 360 * 5 THEN
        'F' --1年至5年
       WHEN A.MATURE_DATE - D_DATADATE_CCY BETWEEN (360 * 5 + 1) AND
            360 * 10 THEN
        'G' --5年至10年
       WHEN A.MATURE_DATE - D_DATADATE_CCY > 360 * 10 THEN
        'H' --10年以上
     END AS REMAIN_TERM_CODE, --存款剩余期限代码
     IS_INLINE_OPTIONS, --是否内嵌提前到期期权
     ADVANCE_DRAW_FLG, --是否可提前支取
     BUS_REL, --是否具有业务关系
     CASE
       WHEN SUBSTR(A.GL_ITEM_CODE, 1, 4) = '2004' THEN
        '02'
       WHEN SUBSTR(A.GL_ITEM_CODE, 1, 6) = '200303' THEN
        '10' --转贷款
       WHEN SUBSTR(A.GL_ITEM_CODE, 1, 4) = '2003' THEN
        '05' --同业拆入
     END AS FLAG, --数据标识
     GL_ITEM_CODE, --科目号
     NVL(ACCRUAL, 0) * CCY_RATE AS INTEREST_ACCURAL, --应付利息
     NULL AS INTEREST_ACCURAL_ITEM, --应付利息科目
     CUST_ID, --账户名称
     A.MATURE_DATE, --到期日
     ACCT_NUM, --账号
     NVL(A.INTEREST_ACCURED, 0) * CCY_RATE AS INTEREST_ACCURAL, --应计利息
     A.MATURE_DATE, --本金到期日即应计利息到期日
     O_ACCT_NUM, --外部账号 关联保证金,存单质押等
     A.MATURE_DATE - D_DATADATE_CCY,
     A.BOOK_TYP AS BOOK_TYPE
      FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A --资金往来信息
      LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = D_DATADATE_CCY
       AND U.BASIC_CCY = A.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
     WHERE A.DATA_DATE = I_DATADATE
       AND (SUBSTR(A.GL_ITEM_CODE, 1, 4) = '2004' OR
           SUBSTR(A.GL_ITEM_CODE, 1, 4) = '2003')
       AND A.GL_ITEM_CODE NOT IN ('20040202' /*, '20040101', '20040501'*/);
  --add by djh 20230216 20040101借入央行款项 20040501中期借贷便利
  /*AND A.ORG_NUM NOT LIKE '51%';*/ -- add 刘晟典
  --由于23101借入央行款项 23105中期借贷便利 明细没有到期日,没有可以放的期限,因此先去掉,等后期改造后可以再取

    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取TMP_A_CBRC_DEPOSIT_BAL存款基础逻辑部分2完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取TMP_A_CBRC_DEPOSIT_BAL存款基础逻辑部分3';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --modify by djh 20230220 FACE_VAL  账面余额,取票面金额与总账本金科目核对
    -- principal_balance 剩余本金 =科目 本金余额+利息调整借方-利息调整贷方+公允价值借方-公允价值贷方（实际余额）
    --3.7发行同业存单  2340301同业存单款项-面值
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ACCT_TYP, --账户类型
       ACCT_CUR, --账户币种
       ACCT_BAL, --账户余额
       ACCT_BAL_RMB, --账户余额_人民币
       TYPE_ENT, --客户实体类型
       FINA_CODE, --金融机构代码类型
       STABLE_RISK_TYPE, --存款稳定性分类
       REMAIN_TERM_CODE, --存款剩余期限代码
       IS_INLINE_OPTIONS, --是否内嵌提前到期期权
       ADVANCE_DRAW_FLG, --是否可提前支取
       BUS_REL, --是否具有业务关系
       FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       INTEREST_ACCURAL, --应付利息
       INTEREST_ACCURAL_ITEM, --应付利息科目
       CUST_ID, --账户名称
       MATUR_DATE, --到期日
       ACCT_NUM, --账号
       INTEREST_ACCURED, --应计利息
       MATUR_DATE_ACCURED, --应计利息到期日
       O_ACCT_NUM, --外部账号 关联保证金,存单质押等
       REMAIN_TERM_CODE_QX,
       CYCB,
       BOOK_TYPE)-- ADD BY DJH 20240510  同业金融部 009820
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM, --机构号
       NULL AS ACCT_TYP, --业务类型
       CURR_CD AS ACCT_CUR, --账户币种
       A.FACE_VAL AS ACCT_BAL, --账户余额 --A.PRINCIPAL_BALANCE
       A.FACE_VAL * U.CCY_RATE AS ACCT_BAL_RMB, --账户余额_人民币  --剩余本金A.PRINCIPAL_BALANCE
       NULL AS TYPE_ENT, --客户实体类型
       NULL AS FINA_CODE, --金融机构代码类型
       NULL STABLE_RISK_TYPE, --存款稳定性分类
       CASE
         WHEN A.MATURITY_DT IS NULL OR A.MATURITY_DT - D_DATADATE_CCY <= 1 THEN --到期日空值,期限<=0,期限=1
          'A'
         WHEN A.MATURITY_DT - D_DATADATE_CCY BETWEEN 2 AND 7 THEN
          'B' --2日至7日
         WHEN A.MATURITY_DT - D_DATADATE_CCY BETWEEN 8 AND 30 THEN
          'C' --8日至30日
         WHEN A.MATURITY_DT - D_DATADATE_CCY BETWEEN 31 AND 90 THEN
          'D' --31日至90日
         WHEN A.MATURITY_DT - D_DATADATE_CCY BETWEEN 91 AND 360 THEN
          'E' --91日至1年
         WHEN A.MATURITY_DT - D_DATADATE_CCY BETWEEN 361 AND 360 * 5 THEN
          'F' --1年至5年
         WHEN A.MATURITY_DT - D_DATADATE_CCY BETWEEN (360 * 5 + 1) AND
              360 * 10 THEN
          'G' --5年至10年
         WHEN A.MATURITY_DT - D_DATADATE_CCY > 360 * 10 THEN
          'H' --10年以上
       END AS REMAIN_TERM_CODE, --存款剩余期限代码
       NULL IS_INLINE_OPTIONS, --是否内嵌提前到期期权
       NULL ADVANCE_DRAW_FLG, --是否可提前支取
       NULL BUS_REL, --是否具有业务关系
       '06' AS FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       NVL(INTEREST_PAYABLE, 0) * CCY_RATE AS INTEREST_ACCURAL, --应付利息
       NULL AS INTEREST_ACCURAL_ITEM, --应付利息科目
       A.CONT_PARTY_CODE, --交易对手编号
       A.MATURITY_DT, --到期日
       ACCT_NUM, --账号
       NVL(A.INTEREST_ACCURED, 0) * CCY_RATE AS INTEREST_ACCURED, --应计利息
       A.MATURITY_DT, --本金到期日即应计利息到期日
       NULL  AS O_ACCT_NUM, --外部账号 关联保证金,存单质押等
       A.MATURITY_DT - D_DATADATE_CCY,
       NVL(CYCB, 0) * CCY_RATE,  --ADD BY DJH 20240510  同业金融部 009820   --利息调整  CYCB资产方的叫持有成本,负债方的利息调整   台账表中【利息收益（即利息调整）】 用于G2502
       A.BOOK_TYPE AS BOOK_TYPE
        FROM PM_RSDATA.SMTMODS_V_PUB_FUND_CDS_BAL A --存单投资与发行信息表
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.MATURITY_DT >=
             to_char(TRUNC(DATE(I_DATADATE, 'YYYY-MM-DD'), 'MM'),'YYYYMMDD') --当月月初,才可以与业务状况表核对
         AND A.PRODUCT_PROP = 'B' --A持有,B发行同业存单
         AND A.STOCK_PRO_TYPE = 'A';--A同业存单,B大额存单
         /*AND A.ORG_NUM NOT LIKE '51%';*/

    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取TMP_A_CBRC_DEPOSIT_BAL存款基础逻辑部分3完成';
    --V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取TMP_A_CBRC_DEPOSIT_BAL存款基础逻辑部分4';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /*3.4卖出回购款项（不含非金融机构）
    3.4.1与金融机构的交易
    3.4.2与央行的交易*/
    --  [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务2111卖出回购本金以及应付利息 ,余额有小于0部分
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ACCT_TYP, --账户类型
       ACCT_CUR, --账户币种
       ACCT_BAL, --账户余额
       ACCT_BAL_RMB, --账户余额_人民币
       TYPE_ENT, --客户实体类型
       FINA_CODE, --金融机构代码类型
       STABLE_RISK_TYPE, --存款稳定性分类
       REMAIN_TERM_CODE, --存款剩余期限代码
       IS_INLINE_OPTIONS, --是否内嵌提前到期期权
       ADVANCE_DRAW_FLG, --是否可提前支取
       BUS_REL, --是否具有业务关系
       FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       INTEREST_ACCURAL, --应付利息
       INTEREST_ACCURAL_ITEM, --应付利息科目
       CUST_ID, --账户名称
       MATUR_DATE, --到期日
       ACCT_NUM, --账号
       INTEREST_ACCURED, --应计利息
       MATUR_DATE_ACCURED, --应计利息到期日
       O_ACCT_NUM, --外部账号 关联保证金,存单质押等
       REMAIN_TERM_CODE_QX,
       BOOK_TYPE)
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM, --机构号
       BUSI_TYPE AS ACCT_TYP, --业务类型
       CURR_CD AS ACCT_CUR, --账户币种
       A.BALANCE AS ACCT_BAL, --账户余额
       A.BALANCE * CCY_RATE AS ACCT_BAL_RMB, --账户余额_人民币
       NULL AS TYPE_ENT, --客户实体类型
       NULL AS FINA_CODE, --金融机构代码类型
       NULL STABLE_RISK_TYPE, --存款稳定性分类
       CASE
            WHEN (A.END_DT - I_DATADATE) / 360 > 10 THEN
             'H' ---10年以上
            WHEN (A.END_DT - I_DATADATE) / 360 > 5 THEN
             'G' --5-10年
            WHEN A.END_DT - I_DATADATE > 360 THEN
             'F' --1-5年
            WHEN A.END_DT - I_DATADATE > 90 THEN
             'E'
            WHEN A.END_DT - I_DATADATE > 30 THEN
             'D'
            WHEN A.END_DT - I_DATADATE > 7 THEN
             'C'
            WHEN A.END_DT - I_DATADATE > 1 THEN
             'B'
            WHEN A.END_DT IS NULL OR (A.END_DT - I_DATADATE = 1 ) THEN
             'A'
          END AS REMAIN_TERM_CODE, --存款剩余期限代码
       NULL IS_INLINE_OPTIONS, --是否内嵌提前到期期权
       NULL ADVANCE_DRAW_FLG, --是否可提前支取
       NULL BUS_REL, --是否具有业务关系
       '07' AS FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       NVL(ACCRUAL, 0) * CCY_RATE AS INTEREST_ACCURAL, --应付利息
       '223112' AS INTEREST_ACCURAL_ITEM, --应付利息科目
       CUST_ID, --客户号
       A.END_DT, --到期日
       ACCT_NUM, --账号
       NVL(A.INTEREST_ACCURED, 0) * CCY_RATE AS INTEREST_ACCURED, --应计利息
       A.END_DT, --本金到期日即应计利息到期日
       NULL AS O_ACCT_NUM, --外部账号 关联保证金,存单质押等
       A.END_DT - D_DATADATE_CCY,
       A.BOOK_TYPE AS BOOK_TYPE
        FROM PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE A --回购信息表
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.GL_ITEM_CODE, 1, 4) IN ('2111' /*, '140'*/)
         AND A.BALANCE <> 0;

         /*AND A.ORG_NUM NOT LIKE '51%';*/ --add 刘晟典
    /* AND A.BUSI_TYPE IN ('201', '202') --业务类型：201质押式卖出回购 202买断式卖出回购
    AND A.ASS_TYPE IN ('1', '3')*/
    --1债券 3票据
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取TMP_A_CBRC_DEPOSIT_BAL存款基础逻辑部分4完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取TMP_A_CBRC_DEPOSIT_BAL存款基础逻辑部分5';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --3.6发行债券
    --272应付债券
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ACCT_TYP, --账户类型
       ACCT_CUR, --账户币种
       ACCT_BAL, --账户余额
       ACCT_BAL_RMB, --账户余额_人民币
       TYPE_ENT, --客户实体类型
       FINA_CODE, --金融机构代码类型
       STABLE_RISK_TYPE, --存款稳定性分类
       REMAIN_TERM_CODE, --存款剩余期限代码
       IS_INLINE_OPTIONS, --是否内嵌提前到期期权
       ADVANCE_DRAW_FLG, --是否可提前支取
       BUS_REL, --是否具有业务关系
       FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       INTEREST_ACCURAL, --应付利息
       INTEREST_ACCURAL_ITEM, --应付利息科目
       CUST_ID, --账户名称
       MATUR_DATE, --到期日
       ACCT_NUM, --账号
       INTEREST_ACCURED, --应计利息
       MATUR_DATE_ACCURED, --应计利息到期日
       REMAIN_TERM_CODE_QX,
       BOOK_TYPE)
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM, --机构号
       NULL AS ACCT_TYP, --业务类型
       CURR_CD AS ACCT_CUR, --账户币种
       A.FACE_VAL AS ACCT_BAL, --账户余额
       A.FACE_VAL * CCY_RATE AS ACCT_BAL_RMB, --账户余额_人民币
       NULL AS TYPE_ENT, --客户实体类型
       NULL AS FINA_CODE, --金融机构代码类型
       NULL STABLE_RISK_TYPE, --存款稳定性分类
       CASE
         WHEN A.MATURITY_DATE IS NULL OR
              A.MATURITY_DATE - D_DATADATE_CCY <= 1 THEN --到期日空值,期限<=0,期限=1
          'A'
         WHEN A.MATURITY_DATE - D_DATADATE_CCY BETWEEN 2 AND 7 THEN
          'B' --2日至7日
         WHEN A.MATURITY_DATE - D_DATADATE_CCY BETWEEN 8 AND 30 THEN
          'C' --8日至30日
         WHEN A.MATURITY_DATE - D_DATADATE_CCY BETWEEN 31 AND 90 THEN
          'D' --31日至90日
         WHEN A.MATURITY_DATE - D_DATADATE_CCY BETWEEN 91 AND 360 THEN
          'E' --91日至1年
         WHEN A.MATURITY_DATE - D_DATADATE_CCY BETWEEN 361 AND 360 * 5 THEN
          'F' --1年至5年
         WHEN A.MATURITY_DATE - D_DATADATE_CCY BETWEEN (360 * 5 + 1) AND
              360 * 10 THEN
          'G' --5年至10年
         WHEN A.MATURITY_DATE - D_DATADATE_CCY > 360 * 10 THEN
          'H' --10年以上
       END AS REMAIN_TERM_CODE, --存款剩余期限代码
       NULL IS_INLINE_OPTIONS, --是否内嵌提前到期期权
       NULL ADVANCE_DRAW_FLG, --是否可提前支取
       NULL BUS_REL, --是否具有业务关系
       '08' AS FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       0 AS INTEREST_ACCURAL, --应付利息
       NULL AS INTEREST_ACCURAL_ITEM, --应付利息科目
       CUST_ID, --客户号
       A.MATURITY_DATE, --到期日
       ACCT_NUM, --账号
       /*A.INTEREST_ACCURED * CCY_RATE*/
       NVL(ACCRUAL, 0)  AS INTEREST_ACCURED, --应计利息  --260债券整个应计和应付暂时没有做区分
       A.NEXT_RATE_DATE, --下一付息日 [以上都按照本金到期日来,只有债券特殊按照下一付息日]
       A.MATURITY_DATE - D_DATADATE_CCY,
       A.BOOK_TYPE AS BOOK_TYPE
        FROM PM_RSDATA.SMTMODS_L_ACCT_FUND_BOND_ISSUE A --债券发行
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.GL_ITEM_CODE, 1, 4) = '2502';
         /*AND A.ORG_NUM NOT LIKE '51%';*/ -- add 刘晟典
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取TMP_A_CBRC_DEPOSIT_BAL存款基础逻辑部分5完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取存款总账部分取数至FDM_LNAC_GL中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --总账取数汇总 23101借入央行款项23105中期借贷便利 ,放在次日,20220505由于没有明细数据,大为哥暂停不取总账
    /* INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
      (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      SELECT I_DATADATE,
             A.ORG_NUM AS ORG_NUM,
             '3.1.A',--G21_3.1.A
             sum(A.CREDIT_BAL * B.CCY_RATE),
             A.CURR_CD,
             A.ITEM_CD
        FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A --信用卡逾期
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.CURR_CD<>'BWB'--本外币合计去掉
         AND A.ITEM_CD IN('23101','23105')--23105中期借贷便利
         AND A.ORG_NUM NOT LIKE '%0000' --去掉分行,汇总时不需要
         AND A.ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                               '021500', --磐石吉银村镇银行
                               '222222', --东盛除双阳汇总
                               '333333', --新双阳
                               '444444', --净月潭除双阳
                               '555555') --长春分行（除双阳、榆树、农安）
       GROUP BY A.CURR_CD, A.ITEM_CD,A.ORG_NUM;
    COMMIT; */
    -----3.5.1其中：定期存款 '21510'其他定期储蓄存款（含有奖储蓄）没有到期日放次日
    --21510?有奖储蓄??注意从总账取和明细取会重复的问题,还有到期日原先为空,新核心默认为20991231
   /* INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
      (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      SELECT I_DATADATE,
             A.ORG_NUM AS ORG_NUM,
             '3.5.1.A',
             sum(A.CREDIT_BAL * B.CCY_RATE),
             A.CURR_CD,
             A.ITEM_CD
        FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '20110109' --'21510'其他定期储蓄存款（含有奖储蓄）
         AND A.CURR_CD <> 'BWB' --本外币合计去掉
         AND A.ORG_NUM NOT LIKE '%0000' --去掉分行,汇总时不需要
         AND A.ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                               '510000', --磐石吉银村镇银行
                               '222222', --东盛除双阳汇总
                               '333333', --新双阳
                               '444444', --净月潭除双阳
                               '555555') --长春分行（除双阳、榆树、农安）
       GROUP BY A.CURR_CD, A.ITEM_CD, A.ORG_NUM;
    COMMIT;*/

    --3.8其他有确定到期日的负债
    --11003与221,222,223,225扎差负债方 260应付利息 ,跟着本金到期日跟走
    INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
      (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      SELECT I_DATADATE,
             COALESCE(FA.ORG_UNIT_ID, FB.ORG_UNIT_ID) AS ORG_NUM,
             '3.8.B',
             CASE
               WHEN COALESCE(FB.CUR_BAL, 0) - COALESCE(FA.CUR_BAL, 0) >= 0 THEN
                COALESCE(FB.CUR_BAL, 0) - COALESCE(FA.CUR_BAL, 0)
               ELSE
                0
             END,
             COALESCE(FA.ISO_CURRENCY_CD, FB.ISO_CURRENCY_CD),
             '201103' AS ITEM_CD
        FROM (SELECT A.DATA_DATE AS AS_OF_DATE,
                     A.ORG_NUM AS ORG_UNIT_ID,
                     A.CURR_CD AS ISO_CURRENCY_CD,
                     SUM(ABS(COALESCE(DEBIT_BAL * B.CCY_RATE, 0) -
                             COALESCE(CREDIT_BAL * B.CCY_RATE, 0))) AS CUR_BAL
                FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND ITEM_CD = '10030301'
                 AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
                 AND ORG_NUM NOT LIKE '%0000'
                 AND ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                                     /*'510000',*/ --磐石吉银村镇银行
                                     '222222', --东盛除双阳汇总
                                     '333333', --新双阳
                                     '444444', --净月潭除双阳
                                     '555555') --长春分行（除双阳、榆树、农安）
               GROUP BY A.DATA_DATE, A.ORG_NUM, A.CURR_CD) FA
        FULL OUTER JOIN (SELECT A.DATA_DATE AS AS_OF_DATE,
                                A.ORG_NUM AS ORG_UNIT_ID,
                                A.CURR_CD AS ISO_CURRENCY_CD,
                                SUM(ABS(COALESCE(CREDIT_BAL * B.CCY_RATE, 0) -
                                        COALESCE(DEBIT_BAL * B.CCY_RATE, 0))) AS CUR_BAL  --ADD BY DJH 20230718
                           FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                           LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                             ON A.DATA_DATE = B.DATA_DATE
                            AND A.CURR_CD = B.BASIC_CCY
                            AND B.FORWARD_CCY = 'CNY'
                          WHERE A.DATA_DATE = I_DATADATE
                            AND (ITEM_CD IN (/*'20110301','20110302','20110303',*/ '20110401', '20110501','20110502','20110503','20110504', '20110601')--[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款,原逻辑中剔除]
                                OR (ITEM_CD) in (/*'2008',*/'2005'/*,'2009'*/)) -- 修改内容：调整代理国库业务会计科目_20250527
                            AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
                            AND ORG_NUM NOT LIKE '%0000'
                            AND ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                                               /* '510000',*/ --磐石吉银村镇银行
                                                '222222', --东盛除双阳汇总
                                                '333333', --新双阳
                                                '444444', --净月潭除双阳
                                                '555555') --长春分行（除双阳、榆树、农安）
                          GROUP BY A.DATA_DATE, A.ORG_NUM, A.CURR_CD) FB
          ON FA.AS_OF_DATE = FB.AS_OF_DATE
         AND FA.ORG_UNIT_ID = FB.ORG_UNIT_ID
         AND FA.ISO_CURRENCY_CD = FB.ISO_CURRENCY_CD;
    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取存款总账部分取数至FDM_LNAC_GL中间表完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取TMP_A_CBRC_LOAN_BAL贷款基础逻辑部分';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金本金以及应收利息,余额有小于0部分
      INSERT 
      INTO PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL 
        (DATA_DATE,
         ORG_NUM,
         ACCT_TYP,
         ACCT_CUR,
         ACCT_BAL,
         ACCT_BAL_RMB,
         REMAIN_TERM_CODE,
         FLAG,
         GL_ITEM_CODE,
         INTEREST_ACCURAL,
         INTEREST_ACCURAL_ITEM,
         CUST_ID,
         MATUR_DATE,
         ACCT_NUM,
         INTEREST_ACCURED,
         MATUR_DATE_ACCURED,
         BOOK_TYPE)
        SELECT 
         I_DATADATE AS DATA_DATE,
         A.ORG_NUM,
         A.ACCT_TYP,
         A.CURR_CD,
         A.BALANCE,
         A.BALANCE * TT.CCY_RATE,
         CASE
           WHEN A.MATURE_DATE - D_DATADATE_CCY < 1 THEN
            'Y' --逾期
           WHEN A.MATURE_DATE IS NULL OR A.MATURE_DATE - D_DATADATE_CCY = 1 OR
                SUBSTR(A.GL_ITEM_CODE, 1, 6) = 101101 OR
                A.GL_ITEM_CODE = '10310101' THEN --同业活期,保证金活期放次日
            'A' --次日
           WHEN A.MATURE_DATE - D_DATADATE_CCY BETWEEN 2 AND 7 THEN
            'B' --2日至7日
           WHEN A.MATURE_DATE - D_DATADATE_CCY BETWEEN 8 AND 30 THEN
            'C' --8日至30日
           WHEN A.MATURE_DATE - D_DATADATE_CCY BETWEEN 31 AND 90 THEN
            'D' --31日至90日
           WHEN A.MATURE_DATE - D_DATADATE_CCY BETWEEN 91 AND 360 THEN
            'E' --91日至1年
           WHEN A.MATURE_DATE - D_DATADATE_CCY BETWEEN 361 AND 360 * 5 THEN
            'F' --1年至5年
           WHEN A.MATURE_DATE - D_DATADATE_CCY BETWEEN (360 * 5 + 1) AND 360 * 10 THEN
            'G' --5年至10年
           WHEN A.MATURE_DATE - D_DATADATE_CCY > 360 * 10 THEN
            'H' --10年以上
         END AS REMAIN_TERM_CODE,
         CASE
           WHEN SUBSTR(A.GL_ITEM_CODE, 1, 4) IN ('1011', '1031') THEN --114(存放同业)、 117(存出保证金)
            '01'
           WHEN SUBSTR(A.GL_ITEM_CODE, 1, 4) = '1302' THEN --120(拆出资金)
            '02'
         END,
         A.GL_ITEM_CODE,
         NVL(ACCRUAL, 0) * CCY_RATE AS INTEREST_ACCURAL, --应收利息
         NULL AS INTEREST_ACCURAL_ITEM, --应付利息科目
         CUST_ID, --客户号
         A.MATURE_DATE, --到期日
         ACCT_NUM, --账号
         NVL(A.INTEREST_ACCURED, 0) * CCY_RATE AS INTEREST_ACCURED, --应计利息
         A.NEXT_RATE_DATE,
         A.BOOK_TYP AS BOOK_TYPE
          FROM PM_RSDATA.CBRC_V_PUB_FUND_MMFUND A --资金往来
          LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
            ON TT.CCY_DATE = I_DATADATE
           AND TT.BASIC_CCY = A.CURR_CD
           AND TT.FORWARD_CCY = 'CNY'
         WHERE A.DATA_DATE = I_DATADATE
           AND (A.BALANCE <> 0 OR ACCRUAL <> 0) --余额不为0  modify BY DJH 20240510  同业金融部
           AND SUBSTR(A.GL_ITEM_CODE, 1, 4) IN ('1011', '1031', '1302');

     COMMIT;


   ---取金融市场部买入返售本金及应收 买入返售业务在金融市场部 add by chm 20230727
   --  [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 009801清算中心外币业务1111买入返售本金以及应收利息,余额有小于0部分
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL 
      (DATA_DATE,
       ORG_NUM,
       ACCT_TYP,
       ACCT_CUR,
       ACCT_BAL,
       ACCT_BAL_RMB,
       REMAIN_TERM_CODE,
       FLAG,
       GL_ITEM_CODE,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       CUST_ID,
       MATUR_DATE,
       ACCT_NUM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED,
       BOOK_TYPE,
       DC_DATE)--ADD BY DJH 20230907 待偿期
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       A.BUSI_TYPE, --业务类型
       A.CURR_CD,
       A.BALANCE,
       A.BALANCE * TT.CCY_RATE,
       CASE
         WHEN A.END_DT < I_DATADATE THEN
          'Y' --逾期
         WHEN (A.END_DT - I_DATADATE) / 360 > 10 THEN
          'H' ---10年以上
         WHEN (A.END_DT - I_DATADATE) / 360 > 5 THEN
          'G' --5-10年
         WHEN A.END_DT - I_DATADATE > 360 THEN
          'F' --1-5年
         WHEN A.END_DT - I_DATADATE > 90 THEN
          'E'
         WHEN A.END_DT - I_DATADATE > 30 THEN
          'D'
         WHEN A.END_DT - I_DATADATE > 7 THEN
          'C'
         WHEN A.END_DT - I_DATADATE > 1 THEN
          'B' --交易账户都放2-7日,银行账户按照待偿期划分
         WHEN A.END_DT IS NULL OR
              (A.END_DT - I_DATADATE = 1) THEN
          'A' --次日
       END AS REMAIN_TERM_CODE, --存款剩余期限代码
       '03' AS FLAG,
       A.GL_ITEM_CODE,
       NVL(ACCRUAL, 0) * CCY_RATE AS INTEREST_ACCURAL, --应收利息
       NULL AS INTEREST_ACCURAL_ITEM, --应付利息科目
       CUST_ID, --客户号
       A.END_DT, --到期日
       ACCT_NUM, --账号
       NVL(A.INTEREST_ACCURED, 0) * CCY_RATE AS INTEREST_ACCURED, --应计利息
       A.NEXT_RATE_DATE,
       A.BOOK_TYPE AS BOOK_TYPE,
       DC_DATE--ADD BY DJH 20230907 待偿期
        FROM PM_RSDATA.CBRC_V_PUB_FUND_REPURCHASE A --回购信息
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.BALANCE <> 0 --余额不为0
         AND SUBSTR(A.GL_ITEM_CODE, 1, 4) = '1111'; --买入返售金融资产


       COMMIT;

 --1.8持有同业存单 141、142、143、145中同业存单部分 该处注释,按照金融市场部口径出同业存单,同业金融部口径同金融市场部,同业存单业务只有2个部门有
   /*INSERT \*+ APPEND *\
   INTO PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL 
     (DATA_DATE,
      ORG_NUM,
      ACCT_TYP,
      ACCT_CUR,
      ACCT_BAL,
      ACCT_BAL_RMB,
      REMAIN_TERM_CODE,
      FLAG,
      GL_ITEM_CODE,
      INTEREST_ACCURAL,
      INTEREST_ACCURAL_ITEM,
      CUST_ID,
      MATUR_DATE,
      ACCT_NUM,
      INTEREST_ACCURED,
      MATUR_DATE_ACCURED)
     SELECT \*+parallel(4)*\
      I_DATADATE AS DATA_DATE, --数据日期
      ORG_NUM, --机构号
      NULL AS ACCT_TYP, --业务类型
      CURR_CD AS ACCT_CUR, --账户币种
      A.PRINCIPAL_BALANCE AS ACCT_BAL, --净值
      A.PRINCIPAL_BALANCE * U.CCY_RATE AS ACCT_BAL_RMB, --净值
      CASE
        WHEN A.MATURITY_DT IS NULL OR A.MATURITY_DT - D_DATADATE_CCY <= 1 THEN --到期日空值,期限<=0,期限=1
         'A'
        WHEN A.MATURITY_DT - D_DATADATE_CCY BETWEEN 2 AND 7 THEN
         'B' --2日至7日
        WHEN A.MATURITY_DT - D_DATADATE_CCY BETWEEN 8 AND 30 THEN
         'C' --8日至30日
        WHEN A.MATURITY_DT - D_DATADATE_CCY BETWEEN 31 AND 90 THEN
         'D' --31日至90日
        WHEN A.MATURITY_DT - D_DATADATE_CCY BETWEEN 91 AND 360 THEN
         'E' --91日至1年
        WHEN A.MATURITY_DT - D_DATADATE_CCY BETWEEN 361 AND 360 * 5 THEN
         'F' --1年至5年
        WHEN A.MATURITY_DT - D_DATADATE_CCY BETWEEN (360 * 5 + 1) AND
             360 * 10 THEN
         'G' --5年至10年
        WHEN A.MATURITY_DT - D_DATADATE_CCY > 360 * 10 THEN
         'H' --10年以上
      END AS REMAIN_TERM_CODE, --存款剩余期限代码
      '04' AS FLAG, --数据标识
      GL_ITEM_CODE, --科目号
      NVL(INTEREST_RECEIVABLE, 0) * CCY_RATE AS INTEREST_ACCURAL, --应收利息
      NULL AS INTEREST_ACCURAL_ITEM, --应付利息科目
      A.CONT_PARTY_CODE, --交易对手编号
      A.MATURITY_DT, --到期日
      ACCT_NUM, --账号
      NVL(A.INTEREST_ACCURED, 0) * CCY_RATE AS INTEREST_ACCURED, --应计利息
      A.NEXT_RATE_DATE
       FROM L_ACCT_FUND_CDS_BAL A --存单投资与发行信息表
       LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = D_DATADATE_CCY
        AND U.BASIC_CCY = A.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE A.DATA_DATE = I_DATADATE
        AND SUBSTR(A.GL_ITEM_CODE, 1, 4) IN ('1101', '1102', '1501', '1503') --同业存单
        AND A.FACE_VAL <> 0
        --AND A.ORG_NUM NOT LIKE '51%'
        AND A.ORG_NUM <> '009804'; ---009804金融市场部取数口径不同于此,单独加工,故刨除 mdf by chm 20230727;
    COMMIT;*/


     ---取金融市场部持有同业存单   add by chm 20230727
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL 
      (DATA_DATE,
       ORG_NUM,
       ACCT_TYP,
       ACCT_CUR,
       ACCT_BAL,
       ACCT_BAL_RMB,
       REMAIN_TERM_CODE,
       FLAG,
       GL_ITEM_CODE,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       CUST_ID,
       MATUR_DATE,
       ACCT_NUM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED,
       BOOK_TYPE,--ADD BY DJH 20230907 增加账户种类
       DC_DATE)--ADD BY DJH 20230907 待偿期
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM, --机构号
       NULL AS ACCT_TYP, --业务类型
       CURR_CD AS ACCT_CUR, --账户币种
       A.PRINCIPAL_BALANCE AS ACCT_BAL, --净值
       A.PRINCIPAL_BALANCE * U.CCY_RATE AS ACCT_BAL_RMB, --净值
       CASE
         WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN
          'Y' --逾期
         WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
          'H' ---10年以上
         WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
          'G' --5-10年
         WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
          'F' --1-5年
         WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
          'E'
         WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
          'D'
         WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
          'C'
         WHEN BOOK_TYPE = '1' OR (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
          'B' --交易账户都放2-7日,银行账户按照待偿期划分
         WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
          'A' --次日
       END AS REMAIN_TERM_CODE, --存款剩余期限代码
       '04' AS FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       NVL(INTEREST_RECEIVABLE, 0) * CCY_RATE AS INTEREST_ACCURAL, --应收利息
       NULL AS INTEREST_ACCURAL_ITEM, --应付利息科目
       A.CONT_PARTY_CODE, --交易对手编号
       A.MATURITY_DT, --到期日
       ACCT_NUM, --账号
       NVL(A.INTEREST_ACCURED, 0) * CCY_RATE AS INTEREST_ACCURED, --应计利息
       A.NEXT_RATE_DATE,
       A.BOOK_TYPE, --ADD BY DJH 20230907 增加账户种类
       A.DC_DATE --ADD BY DJH 20230907 待偿期
        FROM PM_RSDATA.SMTMODS_V_PUB_FUND_CDS_BAL A --存单投资与发行信息表
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND STOCK_PRO_TYPE = 'A' --同业存单
         AND PRODUCT_PROP = 'A' --持有
         AND A.FACE_VAL <> 0
         --AND A.ORG_NUM = '009804';
         --AND A.ORG_NUM NOT LIKE '51%'
   ;


    COMMIT;

    ---取金融市场部债券投资  债券投资业务在金融市场部  add by chm 20230727
    ---债券应收利息的逾期差1991,后续汇总需特殊处理

    INSERT 
    INTO PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL 
      (DATA_DATE,
       ORG_NUM,
       ACCT_TYP,
       ACCT_CUR,
       ACCT_BAL,
       ACCT_BAL_RMB,
       REMAIN_TERM_CODE,
       FLAG,
       GL_ITEM_CODE,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       CUST_ID,
       MATUR_DATE,
       ACCT_NUM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED,
       BOOK_TYPE)
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.ORG_NUM, --机构号
       NULL AS ACCT_TYP, --业务类型
       A.CURR_CD AS ACCT_CUR, --账户币种
       A.PRINCIPAL_BALANCE AS ACCT_BAL, --净值
       A.PRINCIPAL_BALANCE * U.CCY_RATE AS ACCT_BAL_RMB, --净值
       CASE
         WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN --8090
          'Y'
         WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
          'H' ---10年以上
         WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
          'G' --5-10年
         WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
          'F' --1-5年
         WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
          'E'
         WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
          'D'
         WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
          'C'
         WHEN BOOK_TYPE = '1' OR (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
          'B' --交易账户都放2-7日,银行账户按照待偿期划分
         WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
          'A'
       END AS REMAIN_TERM_CODE, --存款剩余期限代码
       '05' AS FLAG, --数据标识
       GL_ITEM_CODE, --科目号
       NVL(ACCRUAL, 0) * CCY_RATE AS INTEREST_ACCURAL, --应收利息
       NULL AS INTEREST_ACCURAL_ITEM, --应付利息科目
       NULL, --交易对手编号
       A.MATURITY_DATE, --到期日
       ACCT_NUM, --账号
       NULL AS INTEREST_ACCURED, --应计利息
       NULL,
       A.BOOK_TYPE AS BOOK_TYPE
        FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST A
       INNER JOIN PM_RSDATA.SMTMODS_L_AGRE_BOND_INFO B --债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'; --债券

    COMMIT;

  -- ADD BY DJH 20240510  同业金融部
  --基金（债券基金+货币基金）随时申赎的放到2-7日,取持有仓位+公允价值;  剩余的定开（康星系统有标识,为剩余的债券基金投资）按照剩余期限划分,取持有仓位；
  --基金的随时申赎的应收放2-7日（货币基金有应收）;
   INSERT 
   INTO PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL 
     (DATA_DATE,
      ORG_NUM,
      ACCT_TYP,
      ACCT_CUR,
      ACCT_BAL,
      ACCT_BAL_RMB,
      REMAIN_TERM_CODE,
      FLAG,
      GL_ITEM_CODE,
      INTEREST_ACCURAL,
      INTEREST_ACCURAL_ITEM,
      CUST_ID,
      MATUR_DATE,
      ACCT_NUM,
      INTEREST_ACCURED,
      MATUR_DATE_ACCURED,
      BOOK_TYPE,
      REDEMPTION_TYPE -- ADD BY DJH 20240510  同业金融部 基金赎回类型
      )
     SELECT 
      I_DATADATE AS DATA_DATE, --数据日期
      D.ORG_NUM, --机构号
      D.INVEST_TYP||'_'||C.SUBJECT_PRO_TYPE  AS ACCT_TYP, --业务类型   投资业务品种_标的产品分类
      D.CURR_CD AS ACCT_CUR, --账户币种
      D.FACE_VAL AS ACCT_BAL, --净值
      D.FACE_VAL * U.CCY_RATE + D.MK_VAL * U.CCY_RATE AS ACCT_BAL_RMB, --净价成本 --FACE_VAL持有仓位+利息调整  MK_VAL公允价值
      CASE
        WHEN C.REDEMPTION_TYPE = '定期赎回' AND   -- 基金赎回类型: 随时赎回 ,定期赎回
             D.MATURITY_DATE < I_DATADATE THEN
         'Y'
        WHEN C.REDEMPTION_TYPE = '定期赎回' AND
             (D.MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
         'H' ---10年以上
        WHEN C.REDEMPTION_TYPE = '定期赎回' AND
             (D.MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
         'G' --5-10年
        WHEN C.REDEMPTION_TYPE = '定期赎回' AND
             D.MATURITY_DATE - I_DATADATE > 360 THEN
         'F' --1-5年
        WHEN C.REDEMPTION_TYPE = '定期赎回' AND
             D.MATURITY_DATE - I_DATADATE > 90 THEN
         'E'
        WHEN C.REDEMPTION_TYPE = '定期赎回' AND
             D.MATURITY_DATE - I_DATADATE > 30 THEN
         'D'
        WHEN C.REDEMPTION_TYPE = '定期赎回' AND
             D.MATURITY_DATE - I_DATADATE > 7 THEN
         'C'
        WHEN C.REDEMPTION_TYPE = '随时赎回' OR
             D.MATURITY_DATE - I_DATADATE > 1 THEN
         'B'
        WHEN C.REDEMPTION_TYPE = '定期赎回' AND
             (D.MATURITY_DATE - I_DATADATE = 1 OR
             D.MATURITY_DATE - I_DATADATE = 0) THEN
         'A'
      END AS REMAIN_TERM_CODE, --剩余期限代码
      '06' AS FLAG, --数据标识  【基金】
      GL_ITEM_CODE, --科目号
      NVL(ACCRUAL, 0) * CCY_RATE AS INTEREST_ACCURAL, --应收利息(利息成本)
      NULL AS INTEREST_ACCURAL_ITEM, --应付利息科目
      NULL, --交易对手编号
      D.MATURITY_DATE, --到期日
      D.SUBJECT_CD, --账号
      NULL AS INTEREST_ACCURED, --应计利息
      NULL,
      D.BOOK_TYPE AS BOOK_TYPE,
      REDEMPTION_TYPE  -- ADD BY DJH 20240510  同业金融部 基金赎回类型
       FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST  D --投资业务信息表
      INNER JOIN PM_RSDATA.SMTMODS_L_AGRE_OTHER_SUBJECT_INFO C -- 其他标的物信息表
         ON D.SUBJECT_CD = C.SUBJECT_CD
        AND C.DATA_DATE = I_DATADATE
       LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = D.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
        AND U.DATA_DATE = I_DATADATE
      WHERE D.DATA_DATE = I_DATADATE
        AND D.INVEST_TYP = '01' --投资业务品种(INVEST_TYP): 01基金投资   标的产品分类(SUBJECT_PRO_TYPE) : 0102  债券型基金 0103  货币市场共同基金
        AND (D.FACE_VAL <> 0 or D.MK_VAL <> 0 OR ACCRUAL <> 0);

    COMMIT;
    ---- ADD BY DJH 20240510  同业金融部
    --委外投资取账户类型是FVTPL的且科目为11010303的持有仓位+公允价值都放到2-7日,其中中信信托2笔特殊处理按照剩余期限360天划分持有仓位+公允价值;
   INSERT 
   INTO PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL 
     (DATA_DATE,
      ORG_NUM,
      ACCT_TYP,
      ACCT_CUR,
      ACCT_BAL,
      ACCT_BAL_RMB,
      REMAIN_TERM_CODE,
      FLAG,
      GL_ITEM_CODE,
      INTEREST_ACCURAL,
      INTEREST_ACCURAL_ITEM,
      CUST_ID,
      MATUR_DATE,
      ACCT_NUM,
      INTEREST_ACCURED,
      MATUR_DATE_ACCURED,
      BOOK_TYPE)
     SELECT 
      I_DATADATE AS DATA_DATE, --数据日期
      D.ORG_NUM, --机构号
      D.INVEST_TYP||'_'||C.SUBJECT_PRO_TYPE  AS ACCT_TYP, --业务类型   投资业务品种_标的产品分类
      D.CURR_CD AS ACCT_CUR, --账户币种
      D.FACE_VAL AS ACCT_BAL, --净值
      D.FACE_VAL * U.CCY_RATE + D.MK_VAL * U.CCY_RATE AS ACCT_BAL_RMB, --剩余本金 --PRINCIPAL_BALANCE持有仓位 MK_VAL公允价值
      CASE
        WHEN D.SUBJECT_CD IN ('N000310000025496', 'N000310000025495') AND
             D.MATURITY_DATE < I_DATADATE THEN
         'Y'
        WHEN D.SUBJECT_CD IN ('N000310000025496', 'N000310000025495') AND
             (D.MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
         'H' ---10年以上
        WHEN D.SUBJECT_CD IN ('N000310000025496', 'N000310000025495') AND
             (D.MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
         'G' --5-10年
        WHEN D.SUBJECT_CD IN ('N000310000025496', 'N000310000025495') AND
             D.MATURITY_DATE - I_DATADATE > 360 THEN
         'F' --1-5年
        WHEN D.SUBJECT_CD IN ('N000310000025496', 'N000310000025495') AND
             D.MATURITY_DATE - I_DATADATE > 90 THEN
         'E'
        WHEN D.SUBJECT_CD IN ('N000310000025496', 'N000310000025495') AND
             D.MATURITY_DATE - I_DATADATE > 30 THEN
         'D'
        WHEN D.SUBJECT_CD IN ('N000310000025496', 'N000310000025495') AND
             D.MATURITY_DATE - I_DATADATE > 7 THEN
         'C'
        WHEN D.MATURITY_DATE - I_DATADATE > 1 THEN
         'B'
        WHEN D.SUBJECT_CD IN ('N000310000025496', 'N000310000025495') AND
             (D.MATURITY_DATE - I_DATADATE = 1 OR
             D.MATURITY_DATE - I_DATADATE = 0) THEN
         'A'
      END AS REMAIN_TERM_CODE, --剩余期限代码
      '07' AS FLAG, --数据标识  【委外投资】
      GL_ITEM_CODE, --科目号
      0 AS INTEREST_ACCURAL, --应收利息(委外投资无利息)
      NULL AS INTEREST_ACCURAL_ITEM, --应付利息科目
      NULL, --交易对手编号
      D.MATURITY_DATE, --到期日
      D.SUBJECT_CD, --账号
      NULL AS INTEREST_ACCURED, --应计利息
      NULL,
      D.BOOK_TYPE AS BOOK_TYPE
       FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST D --投资业务信息表
      INNER JOIN PM_RSDATA.SMTMODS_L_AGRE_OTHER_SUBJECT_INFO C -- 其他标的物信息表
         ON D.SUBJECT_CD = C.SUBJECT_CD
        AND C.DATA_DATE = I_DATADATE
       LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = D.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
        AND U.DATA_DATE = I_DATADATE
      WHERE D.DATA_DATE = I_DATADATE
        AND D.ACCOUNTANT_TYPE = '1' --1 交易类   FVTPL账户
        AND D.GL_ITEM_CODE = '11010303' --交易性特定目的载体投资投资成本
        AND (D.FACE_VAL <> 0 or D.MK_VAL <> 0);

  /*投资业务品种(INVEST_TYP): 04 信托产品投资  标的产品分类(SUBJECT_PRO_TYPE) 04   信托产品
  投资业务品种(INVEST_TYP): 12 资产管理产品    标的产品分类(SUBJECT_PRO_TYPE):0604  证券业金融机构资产管理计划
  */
      COMMIT;
    ---- ADD BY DJH 20240510  同业金融部
    /* 所有AC账户,按剩余期限划分取持有仓位,其中2笔华创证券有限责任公司的到期日特殊处理成2028/11/30处理后划分；
     其中3笔AC账户的特殊处理,取持有仓位（中国华阳经贸集团有限公司,方正证券股份有限公司,东吴基金管理公司）放逾期；*/
    INSERT 
    INTO PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL 
      (DATA_DATE,
       ORG_NUM,
       ACCT_TYP,
       ACCT_CUR,
       ACCT_BAL,
       ACCT_BAL_RMB,
       REMAIN_TERM_CODE,
       FLAG,
       GL_ITEM_CODE,
       INTEREST_ACCURAL,
       INTEREST_ACCURAL_ITEM,
       CUST_ID,
       MATUR_DATE,
       ACCT_NUM,
       INTEREST_ACCURED,
       MATUR_DATE_ACCURED,
       BOOK_TYPE)
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       D.ORG_NUM, --机构号
       D.INVEST_TYP || '_' || C.SUBJECT_PRO_TYPE AS ACCT_TYP, --业务类型   投资业务品种_标的产品分类
       D.CURR_CD AS ACCT_CUR, --账户币种
       D.FACE_VAL AS ACCT_BAL, --净值
       D.FACE_VAL * U.CCY_RATE  AS ACCT_BAL_RMB, --剩余本金 --PRINCIPAL_BALANCE持有仓位 MK_VAL公允价值
       CASE
         WHEN D.SUBJECT_CD IN
              ('N000310000012993', 'N000310000008023', 'N000310000012013') OR
              (CASE
                WHEN D.SUBJECT_CD IN ('N000310000017366', 'N000310000017367') THEN
                 DATE('20281130', 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD') --特殊处理成2028/11/30
                ELSE
                 DATE(D.MATURITY_DATE, 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
              END) < 0 THEN
          'Y' --逾期
         WHEN (CASE
                WHEN D.SUBJECT_CD IN ('N000310000017366', 'N000310000017367') THEN
                  DATE('20281130', 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
                ELSE
                 DATE(D.MATURITY_DATE, 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
              END) / 360 > 10 THEN
          'H' ---10年以上
         WHEN (CASE
                WHEN D.SUBJECT_CD IN ('N000310000017366', 'N000310000017367') THEN
                 DATE('20281130', 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
                ELSE
                 DATE(D.MATURITY_DATE, 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
              END) / 360 > 5 THEN
          'G' --5-10年
         WHEN (CASE
                WHEN D.SUBJECT_CD IN ('N000310000017366', 'N000310000017367') THEN
                 DATE('20281130', 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
                ELSE
                DATE(D.MATURITY_DATE, 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
              END) > 360 THEN
          'F' --1-5年
         WHEN (CASE
                WHEN D.SUBJECT_CD IN ('N000310000017366', 'N000310000017367') THEN
                 DATE('20281130', 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
                ELSE
                 DATE(D.MATURITY_DATE, 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
              END) > 90 THEN
          'E'
         WHEN (CASE
                WHEN D.SUBJECT_CD IN ('N000310000017366', 'N000310000017367') THEN
                 DATE('20281130', 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
                ELSE
                 DATE(D.MATURITY_DATE, 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
              END) > 30 THEN
          'D'
         WHEN (CASE
                WHEN D.SUBJECT_CD IN ('N000310000017366', 'N000310000017367') THEN
                 DATE('20281130', 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
                ELSE
                 DATE(D.MATURITY_DATE, 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
              END) > 7 THEN
          'C'
         WHEN (CASE
                WHEN D.SUBJECT_CD IN ('N000310000017366', 'N000310000017367') THEN
                 DATE('20281130', 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
                ELSE
                 DATE(D.MATURITY_DATE, 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
              END) > 1 THEN
          'B'
         WHEN ((CASE
                WHEN D.SUBJECT_CD IN ('N000310000017366', 'N000310000017367') THEN
                 DATE('20281130', 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
                ELSE
                 DATE(D.MATURITY_DATE, 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
              END) = 1 OR (CASE
                WHEN D.SUBJECT_CD IN ('N000310000017366', 'N000310000017367') THEN
                 DATE('20281130', 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
                ELSE
                 DATE(D.MATURITY_DATE, 'YYYYMMDD') - DATE(I_DATADATE, 'YYYYMMDD')
              END) = 0) THEN
          'A'
       END AS REMAIN_TERM_CODE, --剩余期限代码
       '08' AS FLAG, --数据标识  【AC账户】
       GL_ITEM_CODE, --科目号
       ACCRUAL * U.CCY_RATE AS INTEREST_ACCURAL, --应收利息
       NULL AS INTEREST_ACCURAL_ITEM, --应付利息科目
       NULL, --交易对手编号
       CASE
         WHEN D.SUBJECT_CD IN ('N000310000017366', 'N000310000017367') THEN
          '20281130'
         ELSE
          D.MATURITY_DATE
       END, --到期日
       D.SUBJECT_CD, --账号
       NULL AS INTEREST_ACCURED, --应计利息
       NULL,
       D.BOOK_TYPE AS BOOK_TYPE
        FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST D --投资业务信息表
       INNER JOIN PM_RSDATA.SMTMODS_L_AGRE_OTHER_SUBJECT_INFO C -- 其他标的物信息表
          ON D.SUBJECT_CD = C.SUBJECT_CD
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = D.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE
       WHERE D.DATA_DATE = I_DATADATE
         AND D.ACCOUNTANT_TYPE = '3'; --所有AC账户
        -- AND D.ORG_NUM = '009820'
        /*投资业务品种(INVEST_TYP): 04 信托产品投资  标的产品分类(SUBJECT_PRO_TYPE) 04   信托产品
         投资业务品种(INVEST_TYP): 12 资产管理产品    标的产品分类(SUBJECT_PRO_TYPE):0604  证券业金融机构资产管理计划
         投资业务品种(INVEST_TYP): 99 其它投资        标的产品分类(SUBJECT_PRO_TYPE):99  其他*/
 COMMIT;
    ---- ADD BY DJH 20240510投资银行部  009817机构存量的非标本金按剩余期限划分
  INSERT 
  INTO PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL 
    (DATA_DATE,
     ORG_NUM,
     ACCT_TYP,
     ACCT_CUR,
     ACCT_BAL,
     ACCT_BAL_RMB,
     REMAIN_TERM_CODE,
     FLAG,
     GL_ITEM_CODE,
     INTEREST_ACCURAL,
     INTEREST_ACCURAL_ITEM,
     CUST_ID,
     MATUR_DATE,
     ACCT_NUM,
     INTEREST_ACCURED,
     MATUR_DATE_ACCURED,
     BOOK_TYPE,
     QTYSK,  -- ADD BY DJH 20240510  投资银行部 其他应收款
     GRADE) --ADD BY DJH 20240510  投资银行部 五级分类
    SELECT 
     I_DATADATE AS DATA_DATE, --数据日期
     D.ORG_NUM, --机构号
     D.INVEST_TYP || '_' || C.SUBJECT_PRO_TYPE AS ACCT_TYP, --业务类型   投资业务品种_标的产品分类
     D.CURR_CD AS ACCT_CUR, --账户币种
     D.FACE_VAL AS ACCT_BAL, --净值
     D.FACE_VAL * U.CCY_RATE  AS ACCT_BAL_RMB, --净价成本 --FACE_VAL持有仓位+利息调整
     CASE
       WHEN D.MATURITY_DATE < I_DATADATE THEN
        'Y'
       WHEN (D.MATURITY_DATE - I_DATADATE ) / 360 > 10 THEN
        'H' ---10年以上
       WHEN (D.MATURITY_DATE - I_DATADATE ) / 360 > 5 THEN
        'G' --5-10年
       WHEN D.MATURITY_DATE - I_DATADATE > 360 THEN
        'F' --1-5年
       WHEN D.MATURITY_DATE - I_DATADATE > 90 THEN
        'E'
       WHEN D.MATURITY_DATE - I_DATADATE > 30 THEN
        'D'
       WHEN D.MATURITY_DATE - I_DATADATE > 7 THEN
        'C'
       WHEN D.MATURITY_DATE - I_DATADATE > 1 THEN
        'B'
       WHEN (D.MATURITY_DATE - I_DATADATE = 1 OR
            D.MATURITY_DATE - I_DATADATE = 0) THEN
        'A'
     END AS REMAIN_TERM_CODE, --剩余期限代码
     '09' AS FLAG, --数据标识  【存量的非标】
     GL_ITEM_CODE, --科目号
     NVL(ACCRUAL, 0) * CCY_RATE AS INTEREST_ACCURAL, --应收利息
     NULL AS INTEREST_ACCURAL_ITEM, --应付利息科目
     NULL, --交易对手编号
     D.MATURITY_DATE, --到期日
     ACCT_NUM, --账号
     NULL AS INTEREST_ACCURED, --应计利息
     NULL,
     D.BOOK_TYPE AS BOOK_TYPE,
     NVL(QTYSK, 0) * CCY_RATE  AS QTYSK,  -- ADD BY DJH 20240510  投资银行部 其他应收款
     GRADE --ADD BY DJH 20240510  投资银行部 五级分类
      FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST D --投资业务信息表
     INNER JOIN PM_RSDATA.SMTMODS_L_AGRE_OTHER_SUBJECT_INFO C -- 其他标的物信息表
        ON D.ACCT_NUM = C.SUBJECT_CD
       AND C.DATA_DATE = I_DATADATE
      LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
        ON U.CCY_DATE = I_DATADATE --正式使用替换为 TO_DATE('20240331', 'YYYYMMDD')
       AND U.BASIC_CCY = D.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
       AND U.DATA_DATE = I_DATADATE
     WHERE D.DATA_DATE = I_DATADATE
       AND D.ORG_NUM = '009817';

       /*投资业务品种(INVEST_TYP): 04 信托产品投资  标的产品分类(SUBJECT_PRO_TYPE) 04   信托产品
      投资业务品种(INVEST_TYP): 12 资产管理产品    标的产品分类(SUBJECT_PRO_TYPE):0604  证券业金融机构资产管理计划*/
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取TMP_A_CBRC_LOAN_BAL贷款基础逻辑部分完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取正常贷款账户按照借据表处理至FDM_LNAC中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --明细表 G21,G22,G2501,G2502数据均出自此表
    --正常贷款
    INSERT 
    INTO PM_RSDATA.CBRC_FDM_LNAC  --贷款现金流整合
      (DATA_DATE, --01数据日期
       ACCT_NUM, --02合同号
       LOAN_NUM, --03贷款编号（借据编号）
       CURR_CD, --04币种
       ACCT_STS, --05账户状态（借据状态）
       ORG_NUM, --06机构号
       DRAWDOWN_DT, --07放款日期
       DRAWDOWN_AMT, --08放款金额
       MATURITY_DT, --09原始到期日期
       FINISH_DT, --10结清日期
       LOAN_GRADE_CD, --11五级分类代码
       ACTUAL_MATURITY_DT, --12实际到期日期
       BASE_INT_RAT, --13基准利率
       REAL_INT_RAT, --14实际利率
       LOAN_ACCT_BAL, --15贷款余额
       OD_FLG, --16逾期标志
       EXTENDTERM_FLG, --17展期标志
       OD_LOAN_ACCT_BAL, --18逾期贷款余额
       OD_INT, --19逾期利息
       PAY_TYPE, --20还款方式
       OD_DAYS, --21逾期天数
       P_OD_DT, --22本金逾期日期
       I_OD_DT, --23利息逾期日期
       ITEM_CD, --24科目号
       ACCU_INT_AMT, --25应计利息
       ACCT_STATUS_1104, --36 G21,G22, G22,G2502逾期判定标志
       CUST_ID, --27客户号
       ACCT_TYP, --28账户类型
       BOOK_TYPE, --29账户种类
       INT_RATE_TYP, --30利率类型
       NEXT_REPRICING_DT, --31下一利率重定价日
       BENM_INRAT_TYPE, --32基准利率类型（10基准率,30 LPR利率）
       INRAT_RGLR_MODE, --33利率调整方式
       OD_INT_YGZ, --34营改增挂账利息
       DATE_SOURCESD--35数据来源
       )
      SELECT 
       DATA_DATE, --01数据日期
       ACCT_NUM, --02合同号
       LOAN_NUM, --03贷款编号（借据编号）
       CURR_CD, --04币种
       ACCT_STS, --05账户状态（借据状态）
       ORG_NUM, --06机构号
       DRAWDOWN_DT, --07放款日期
       DRAWDOWN_AMT, --08放款金额
       t1.MATURITY_DT, --09原始到期日期
       FINISH_DT, --10结清日期
       LOAN_GRADE_CD, --11五级分类代码
       ACTUAL_MATURITY_DT, --12实际到期日期
       BASE_INT_RAT, --13基准利率
       REAL_INT_RAT, --14实际利率
       LOAN_ACCT_BAL, --15贷款余额
       OD_FLG, --16逾期标志
       EXTENDTERM_FLG, --17展期标志
       OD_LOAN_ACCT_BAL, --18逾期贷款余额
       OD_INT, --19逾期利息
       PAY_TYPE, --20还款方式
       OD_DAYS, --21逾期天数
       P_OD_DT, --22本金逾期日期
       I_OD_DT, --23利息逾期日期
       /*DECODE(T1.ITEM_CD,
              '13030101',
              '130301',
              '13030103',---add by djh 20220920  NGI-1-贷款台账-WD 网贷来源的数据都记在1220103科目上,因此增加科目映射
              '130301',---add by djh 20220920
              '13030201',
              '130302',
              '13050101',
              '1305',
              '13060101',
              '130601',
              '13060201',
              '130602',
              '13060301',
              '130603',
              '13060301',
              '130603',
              '13060501',
              '130605',
              T1.ITEM_CD --129 默认原来
              )*/
             T1.ITEM_CD , --24科目号
       ACCU_INT_AMT, --25应计利息
       CASE
         WHEN OD_DAYS = 0 OR OD_DAYS IS NULL THEN
          '10' --正常
         WHEN OD_DAYS > 0 AND LOAN_ACCT_BAL = OD_LOAN_ACCT_BAL THEN --逾期金额和逾期本金一样,判定为全部逾期
          '30'
         WHEN OD_DAYS > 0 AND OD_DAYS <= 30 AND
              (ACCT_TYP LIKE '0101%' OR ACCT_TYP LIKE '0103%' OR --个人消费贷款（01个人贷款去掉0102个人经营性贷款）
              ACCT_TYP LIKE '0104%' OR ACCT_TYP LIKE '0199%') AND
              T1.REPAY_TYP ='1' and  T1.PAY_TYPE in   ('01','02','10','11') THEN   --m2 按月JLBA202412040012
          '15' --逾期小于30天
         WHEN OD_DAYS > 30 AND OD_DAYS <= 90 AND
              (ACCT_TYP LIKE '0101%' OR ACCT_TYP LIKE '0103%' OR --个人消费贷款（01个人贷款去掉0102个人经营性贷款） 1104 G0102报表 个人消费逾期判定规则
              ACCT_TYP LIKE '0104%' OR ACCT_TYP LIKE '0199%') AND
              T1.REPAY_TYP ='1' and  T1.PAY_TYPE in   ('01','02','10','11') THEN --m2 按月JLBA202412040012
          '20' --逾期小于90天
         ELSE
          '30' --个人消费贷款逾期大于90天 以及（除了个人消费贷款的）其他还款方式均算逾期本金
       END AS ACCT_STATUS_1104, --26 G21,G22, G2501,G2502逾期判定标志
       CUST_ID, --27客户号
       ACCT_TYP, --28 账户类型
       BOOK_TYPE, --29账户种类
       INT_RATE_TYP, --30利率类型 F固定,L开头浮动
       T1.NEXT_REPRICING_DT AS NEXT_REPRICING_DT, --31下一利率重定价日
       T1.FLOAT_TYPE, --32基准利率类型（B基准率,A LPR利率,#其他）
       NULL INRAT_RGLR_MODE, --33利率调整方式
       OD_INT_YGZ, --34营改增挂账利息
       T1.DATE_SOURCESD --35数据来源
        FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN T1
       WHERE T1.DATA_DATE = I_DATADATE
            --  AND T1.LOAN_ACCT_BAL <> 0 --取借据余额不为0  不可以,因为有借据余额为0,但是仍有利息在计的情况
         AND (T1.ITEM_CD LIKE '1303%' OR T1.ITEM_CD LIKE '1305%' OR
             T1.ITEM_CD LIKE '1306%' OR T1.ITEM_CD LIKE '1301%')
         AND T1.ORG_NUM <> '009803'
         AND T1.CANCEL_FLG = 'N'
     AND T1.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
     ;
         /*AND T1.ORG_NUM NOT LIKE '51%';*/

    COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取正常贷款账户按照借据表处理至FDM_LNAC中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '处理还款计划表到至L_ACCT_LOAN_PAYM_SCHED_BJ临时表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_L_ACCT_LOAN_PAYM_SCHED_BJ 
      (DATA_DATE,
       ACCT_NUM,
       LOAN_NUM,
       ORG_NUM,
       REPAY_SEQ,
       DUE_DATE,
       OS_PPL,
       OS_PPL_PAID,
       DUE_DATE_INT,
       INTEREST,
       INT_PAID,
       ACCU_INT,
       DEPARTMENTD,
       DATE_SOURCESD)
      SELECT 
       DATA_DATE,
       ACCT_NUM,
       LOAN_NUM,
       ORG_NUM,
       REPAY_SEQ,
       DUE_DATE,
       OS_PPL,
       OS_PPL_PAID,
       DUE_DATE_INT,
       INTEREST,
       INT_PAID,
       ACCU_INT,
       DEPARTMENTD,
       DATE_SOURCESD
        FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN_PAYM_SCHED T1
       WHERE DATA_DATE = I_DATADATE
         AND DUE_DATE > D_DATADATE_CCY;--20250808
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '处理还款计划表到至L_ACCT_LOAN_PAYM_SCHED_BJ临时表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取正常贷款账户按照还款计划处理至FDM_LNAC_PMT中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --正常贷款 账户按照还款计划处理
    INSERT 
    INTO PM_RSDATA.CBRC_FDM_LNAC_PMT 
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
       INRAT_RGLR_MODE, --25利率调整方式
       DATE_SOURCESD--26数据来源
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
       T1.ACCT_STATUS_1104, --12逾期判定标志
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
       NVL(T1.NEXT_REPRICING_DT,T1.ACTUAL_MATURITY_DT) - D_DATADATE_CCY PMT_REMAIN_TERM_D, --24下一利率重定价日剩余期限
       INRAT_RGLR_MODE, --25利率调整方式
       T1.DATE_SOURCESD--26数据来源
        FROM PM_RSDATA.CBRC_FDM_LNAC T1
        LEFT JOIN PM_RSDATA.CBRC_L_ACCT_LOAN_PAYM_SCHED_BJ T2
          ON T1.LOAN_NUM = T2.LOAN_NUM
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ACCT_STATUS_1104 <> '30' --逾期数据,直接取借据表余额,所以此处剔除
         AND T1.LOAN_ACCT_BAL <> 0;
    /* add by djh 20211104 1）由于借据表里面网贷数据结清但仍然有还款计划,此数据还款计划表数据不取,
    2）借据表余额与还款计划表余额加和不等,导致数据不平,新信贷回复他们数据会截断,由于是核心历史数据,这种数据需要等处理结果
    此处直接以借据表借据余额为准,只要余额为0的均不取*/
    COMMIT;
   V_STEP_FLAG := 1;
    V_STEP_DESC := '提取正常贷款账户按照还款计划处理至FDM_LNAC_PMT中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据逾期贷款账户至FDM_LNAC_PMT中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --逾期贷款账户直接放入
    INSERT 
    INTO PM_RSDATA.CBRC_FDM_LNAC_PMT 
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
       LOAN_ACCT_BAL, --14贷款余额
       PMT_REMAIN_TERM_C, --15还款计划剩余期限
       PMT_REMAIN_TERM_C_MULT, --16还款计划单位
       LOAN_GRADE_CD, --17五级分类状态
       IDENTITY_CODE, --18标识符
       OD_INT, --19逾期利息
       BOOK_TYPE, --20账户种类
       INT_RATE_TYP, --21利率类型
       NEXT_REPRICING_DT, --22下一利率重定价日
       BENM_INRAT_TYPE, --23基准利率类型（10基准率,30 LPR利率）
       PMT_REMAIN_TERM_D, --24下一利率重定价日剩余期限
       INRAT_RGLR_MODE, --25利率调整方式
       DATE_SOURCESD--26数据来源
       )
      SELECT
       DATA_DATE, --01数据日期
       T1.LOAN_NUM, --02贷款编号（借据编号）
       T1.CURR_CD, --03币种
       T1.ITEM_CD, --04科目号
       T1.ORG_NUM, --05机构
       T1.ACTUAL_MATURITY_DT, --06实际到期日期
       T1.P_OD_DT AS NEXT_PAYMENT_DT, --07下次付款日 即本金逾期日期
       'YUQI' AS REPAY_SEQ, --08还款期数 逾期的话直接标识为‘YUQI’
       T1.ACCT_NUM, --09合同号
       T1.ACCT_STS, --10账户状态（借据状态）
       T1.ACCU_INT_AMT, --11应计利息
       T1.ACCT_STATUS_1104, --12状态
       CASE
         WHEN T1.ACCT_STATUS_1104 <> '30' THEN
          OD_LOAN_ACCT_BAL
         ELSE
          T1.LOAN_ACCT_BAL
       END AS NEXT_PAYMENT, --13下次付款额 个人消费贷款逾期大于90天 以及（除了个人消费贷款的）其他还款方式均算逾期本金
       T1.LOAN_ACCT_BAL, --14贷款余额
       OD_DAYS AS PMT_REMAIN_TERM_C, --15还款计划剩余期限  逾期直接取逾期天数
       'D' PMT_REMAIN_TERM_C_MULT, --16还款计划单位
       T1.LOAN_GRADE_CD, --17五级分类状态
       '2' AS IDENTITY_CODE, --18标识符
       NVL(T1.OD_INT, 0), --19逾期利息
       T1.BOOK_TYPE, --20账户种类
       T1.INT_RATE_TYP, --21利率类型
       T1.NEXT_REPRICING_DT, --22下一利率重定价日
       T1.BENM_INRAT_TYPE, --23基准利率类型（10基准率,30 LPR利率）
       NVL(T1.NEXT_REPRICING_DT, T1.ACTUAL_MATURITY_DT) - D_DATADATE_CCY PMT_REMAIN_TERM_D, --24下一利率重定价日剩余期限
       INRAT_RGLR_MODE, --25利率调整方式
       T1.DATE_SOURCESD--26数据来源
        FROM PM_RSDATA.CBRC_FDM_LNAC T1
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ACCT_STATUS_1104 <> '10'; --不包括正常数据的所有逾期,逾期账户插入
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据逾期贷款账户至FDM_LNAC_PMT中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '处理还款计划表到至L_ACCT_LOAN_PAYM_SCHED_LX临时表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_L_ACCT_LOAN_PAYM_SCHED_LX 
      (DATA_DATE,
       LOAN_NUM,
       ORG_NUM,
       REPAY_SEQ,
       DUE_DATE,
       OS_PPL,
       OS_PPL_PAID,
       DUE_DATE_INT,
       INTEREST,
       INT_PAID,
       ACCU_INT,
       DEPARTMENTD,
       DATE_SOURCESD)
      SELECT DATA_DATE,
             LOAN_NUM,
             ORG_NUM,
             REPAY_SEQ,
             DUE_DATE,
             OS_PPL,
             OS_PPL_PAID,
             DUE_DATE_INT,
             INTEREST,
             INT_PAID,
             ACCU_INT,
             DEPARTMENTD,
             DATE_SOURCESD
        FROM (SELECT
               DATA_DATE,
               LOAN_NUM,
               ORG_NUM,
               REPAY_SEQ,
               DUE_DATE,
               OS_PPL,
               OS_PPL_PAID,
               DUE_DATE_INT,
               INTEREST,
               INT_PAID,
               ACCU_INT,
               DEPARTMENTD,
               DATE_SOURCESD,
               ROW_NUMBER() OVER(PARTITION BY LOAN_NUM ORDER BY DUE_DATE_INT) RN
                FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN_PAYM_SCHED T1
               WHERE DATA_DATE = I_DATADATE
                 AND DUE_DATE_INT > D_DATADATE_CCY)
       WHERE RN = 1; --取还款计划表的下一还款利息日期;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '处理还款计划表到至L_ACCT_LOAN_PAYM_SCHED_LX临时表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据133应计利息至FDM_LNAC_PMT_LX中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --133应计利息单独处理
/*      利息逻辑与本金逻辑不同,对于已经状态为 '30' 的应计利息,
    1）只要是逾期90天以内包含90即（<=90）,正常这笔贷款的应计利息仍然取,逾期利息正常放逾期
    2）但是如果超过90,即（>90）,信贷会处理13301科目为表外,即非应计,也就是应计利息,逾期利息两个字段都为0
    */

    INSERT 
    INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_LX 
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
       ACCT_STATUS_1104, --12逾期判定标识
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
       /*OD_INT_YGZ, --24营改增挂账利息*/
       DATE_SOURCESD --25数据来源
       )
      SELECT 
       T1.DATA_DATE, --01数据日期
       T1.LOAN_NUM, --02贷款编号（借据编号）
       T1.CURR_CD, --03币种
       T1.ITEM_CD, --04科目号
       T1.ORG_NUM, --05机构
       T1.ACTUAL_MATURITY_DT, --06实际到期日期
       NVL(T2.DUE_DATE_INT, D_DATADATE_CCY + 21) AS NEXT_PAYMENT_DT, --07下次付款日
       NVL(T2.REPAY_SEQ, 'WU'), --08还款期数
       T1.ACCT_NUM, --09合同号
       T1.ACCT_STS, --10账户状态（借据状态）
       NVL(T1.ACCU_INT_AMT, 0), --11应计利息
       T1.ACCT_STATUS_1104, --12状态
       NVL(T2.OS_PPL, T1.LOAN_ACCT_BAL) AS NEXT_PAYMENT, --13下次付款额
       NVL(T2.ACCU_INT, 0) AS ACCU_INT, --14还款计划应计利息
       T1.LOAN_ACCT_BAL, --15贷款余额
       NVL(T2.DUE_DATE_INT, D_DATADATE_CCY + 21) - D_DATADATE_CCY AS PMT_REMAIN_TERM_C, --16还款计划剩余期限 没有还款计划的利息取下月21号
       'D' AS PMT_REMAIN_TERM_C_MULT, --17还款计划单位
       T1.LOAN_GRADE_CD, --18五级分类状态
       '3' AS IDENTITY_CODE, --19标识符
       T1.BOOK_TYPE, --20账户种类
       T1.INT_RATE_TYP, --21利率类型
       T1.NEXT_REPRICING_DT, --22下一利率重定价日
       T1.BENM_INRAT_TYPE, --23基准利率类型（10基准率,30 LPR利率）
      /* CASE
         WHEN T1.ACCT_STATUS_1104 = '10' THEN
          NVL(T1.OD_INT_YGZ, 0)
         ELSE
          0
       END,*/ --24没有逾期天数,算作正常数据的营改增挂账利息要取出来,放在利息的G21逾期利息
       T1.DATE_SOURCESD --25数据来源
        FROM PM_RSDATA.CBRC_FDM_LNAC T1
        LEFT JOIN PM_RSDATA.CBRC_L_ACCT_LOAN_PAYM_SCHED_LX T2
          ON T1.LOAN_NUM = T2.LOAN_NUM
       WHERE T1.DATA_DATE = I_DATADATE;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据133应计利息至FDM_LNAC_PMT_LX中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   
   V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取133逾期利息直接放入至FDM_LNAC_PMT_LX中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --逾期利息直接放入
    INSERT 
    INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_LX 
      (DATA_DATE, --01数据日期
       LOAN_NUM, --02贷款编号（借据编号）
       CURR_CD, --03币种
       ITEM_CD, --04科目号
       ORG_NUM, --05机构
       ACTUAL_MATURITY_DT, --06实际到期日期
       NEXT_PAYMENT_DT, --07利息逾期日期
       REPAY_SEQ, --08还款期数
       ACCT_NUM, --09合同号
       ACCT_STS, --10账户状态（借据状态）
       ACCU_INT_AMT, --11应计利息
       ACCT_STATUS_1104, --12状态
       NEXT_PAYMENT, --13下次付款额
       LOAN_ACCT_BAL, --14贷款余额
       PMT_REMAIN_TERM_C, --15利息逾期天数
       PMT_REMAIN_TERM_C_MULT, --16利息逾期天数单位
       LOAN_GRADE_CD, --17五级分类状态
       IDENTITY_CODE, --18标识符
       OD_INT, --19逾期利息
       BOOK_TYPE, --20账户种类
       INT_RATE_TYP, --21利率类型
       NEXT_REPRICING_DT, --22下一利率重定价日
       BENM_INRAT_TYPE, --23基准利率类型（10基准率,30 LPR利率
       OD_INT_YGZ, --24营改增挂账利息
       DATE_SOURCESD--25数据来源
       )
      SELECT 
       DATA_DATE, --01数据日期
       T1.LOAN_NUM, --02贷款编号（借据编号）
       T1.CURR_CD, --03币种
       T1.ITEM_CD, --04科目号
       T1.ORG_NUM, --05机构
       T1.ACTUAL_MATURITY_DT, --06实际到期日期
       T1.I_OD_DT AS NEXT_PAYMENT_DT, --07利息逾期日期
       'YUQI' AS REPAY_SEQ, --08逾期标识
       T1.ACCT_NUM, --09合同号
       T1.ACCT_STS, --10账户状态（借据状态）
       T1.ACCU_INT_AMT, --11应计利息
       T1.ACCT_STATUS_1104, --12状态
       CASE
         WHEN T1.ACCT_STATUS_1104 <> '30' THEN
          OD_LOAN_ACCT_BAL
         ELSE
          T1.LOAN_ACCT_BAL
       END AS NEXT_PAYMENT, --13下次付款额
       T1.LOAN_ACCT_BAL, --14贷款余额
       OD_DAYS AS PMT_REMAIN_TERM_C, --15利息逾期天数
       'D' PMT_REMAIN_TERM_C_MULT, --16利息逾期天数单位
       T1.LOAN_GRADE_CD, --17五级分类状态
       '4' AS IDENTITY_CODE, --18标识符
       NVL(T1.OD_INT, 0), --19逾期利息
       T1.BOOK_TYPE, --20账户种类
       T1.INT_RATE_TYP, --21利率类型
       T1.NEXT_REPRICING_DT, --22下一利率重定价日
       T1.BENM_INRAT_TYPE, --23基准利率类型（10基准率,30 LPR利率）
       NVL(T1.OD_INT_YGZ, 0), --24营改增挂账利息
       T1.DATE_SOURCESD --25数据来源
        FROM PM_RSDATA.CBRC_FDM_LNAC T1
       WHERE T1.DATA_DATE = I_DATADATE
         /*AND T1.ACCT_STATUS_1104 <> '10'*/;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取133逾期利息直接放入至FDM_LNAC_PMT_LX中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.6各项贷款至ID_G21_ITEMDATA_NGI_YB中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --G21 *1.6各项贷款*  使用还款计划表拆分剩余期限  原币种
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI_YB 
      (RQ,
       ORGNO,
       SUBJECT,
       CURR_CD,
       NEXT_YS,
       NEXT_WEEK,
       NEXT_MONTH,
       NEXT_QUARTER,
       NEXT_YEAR,
       NEXT_FIVE,
       NEXT_TEN,
       MORE_TEN,
       YQ,
       LOCAL_STATION)
      SELECT 
       I_DATADATE,
       T1.ORG_NUM,
       T1.ITEM_CD,
       T1.CURR_CD,
       SUM(CASE --ADD BY DJH 20220518如果逾期天数是空值或者0,但是实际到期日小于等于当前日期数据,放在次日
             WHEN (T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '1') or (T1.ACCT_STATUS_1104='10'AND T1.PMT_REMAIN_TERM_C <=0) THEN
              T1.NEXT_PAYMENT
             ELSE
              0
           END) AS NEXT_DAY,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT
             ELSE
              0
           END) AS NEXT_WEEK,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT
             ELSE
              0
           END) AS NEXT_MONTH,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT
             ELSE
              0
           END) AS NEXT_QUARTER,

       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT
             ELSE
              0
           END) AS NEXT_YEAR,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 360 * 5 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT
             ELSE
              0
           END) AS NEXT_FIVE,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND 360 * 10 AND
                  T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT
             ELSE
              0
           END) AS NEXT_TEN,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 AND T1.IDENTITY_CODE = '1' THEN
              T1.NEXT_PAYMENT
             ELSE
              0
           END) AS MORE_TEN,
       SUM(CASE
             WHEN T1.IDENTITY_CODE = '2' THEN
              T1.NEXT_PAYMENT
             ELSE
              0
           END) AS YQ,
       '1.6_1'
        FROM PM_RSDATA.CBRC_FDM_LNAC_PMT T1
       WHERE T1.DATA_DATE = I_DATADATE
       GROUP BY I_DATADATE, T1.ORG_NUM, T1.ITEM_CD, T1.CURR_CD;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.6各项贷款至ID_G21_ITEMDATA_NGI_YB中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.6各项贷款折币后至ID_G21_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --G21 *1.6各项贷款*  使用还款计划表拆分剩余期限  人民币
    INSERT 
    INTO PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI 
      (RQ,
       ORGNO,
       SUBJECT,
       NEXT_YS,
       NEXT_WEEK,
       NEXT_MONTH,
       NEXT_QUARTER,
       NEXT_YEAR,
       NEXT_FIVE,
       NEXT_TEN,
       MORE_TEN,
       YQ,
       LOCAL_STATION)
      SELECT 
       RQ,
       ORGNO,
       SUBJECT,
       SUM(NEXT_YS * T2.CCY_RATE),
       SUM(NEXT_WEEK * T2.CCY_RATE),
       SUM(NEXT_MONTH * T2.CCY_RATE),
       SUM(NEXT_QUARTER * T2.CCY_RATE),
       SUM(NEXT_YEAR * T2.CCY_RATE),
       SUM(NEXT_FIVE * T2.CCY_RATE),
       SUM(NEXT_TEN * T2.CCY_RATE),
       SUM(MORE_TEN * T2.CCY_RATE),
       SUM(YQ * T2.CCY_RATE),
       LOCAL_STATION
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI_YB T1
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD
         AND T2.FORWARD_CCY = 'CNY'
       GROUP BY RQ, T1.ORGNO, T1.SUBJECT, LOCAL_STATION;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.6各项贷款折币后至ID_G21_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.9其他有确定到期日的资产至ID_G21_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI 
      (RQ,
       ORGNO,
       SUBJECT,
       NEXT_YS,
       NEXT_WEEK,
       NEXT_MONTH,
       NEXT_QUARTER,
       NEXT_YEAR,
       NEXT_FIVE,
       NEXT_TEN,
       MORE_TEN,
       YQ,
       LOCAL_STATION)
      SELECT 
       I_DATADATE,
       T1.ORG_NUM,
       CASE WHEN T1.ITEM_CD IN('13030101','13030103')
            THEN '11320102'
            WHEN T1.ITEM_CD IN('13030201','13030203')
            THEN '11320104'
            WHEN T1.ITEM_CD IN('13050101','13050103')
            THEN '11320106'
            WHEN T1.ITEM_CD IN('13060101','13060103')
            THEN '11320108'
            WHEN T1.ITEM_CD IN('13060201','13060203')
            THEN '11320110'
            WHEN T1.ITEM_CD IN('13060301','13060303')
            THEN '11320112'
            WHEN T1.ITEM_CD IN('13060501','13060503')
            THEN '11320116'
            ELSE
              T1.ITEM_CD
          END,      --本金对应应计利息科目
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_DAY,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_WEEK,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_MONTH,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_QUARTER,

       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_YEAR,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 360 * 5 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_FIVE,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND 360 * 10 AND
                  T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_TEN,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 AND T1.IDENTITY_CODE = '3' THEN
              T1.ACCU_INT_AMT * T2.CCY_RATE
             ELSE
              0
           END) AS MORE_TEN,
       SUM(CASE
             WHEN T1.IDENTITY_CODE = '4' THEN
              (NVL(T1.OD_INT, 0)) * T2.CCY_RATE --逾期利息包括应收利息+营改增挂账利息,营改增挂账利息废弃
             ELSE
              0
           END) YQ,
       '1.8_1'
        FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
       GROUP BY I_DATADATE, T1.ORG_NUM, T1.ITEM_CD;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.9其他有确定到期日的资产至ID_G21_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取表外至FDM_LNAC_PMT_BW中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

     -- ALTER BY DJH  20240115 信用卡未使用额度
    --第一部分：个人： 【循环贷款】合同金额-借据余额
    --循环贷款,只有 普通贷款&贸易融资贷款&保理贷款有   委托贷款和表外贷款没有这个概念
    INSERT 
    INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_BW 
      (DATA_DATE, --01数据日期
       CURR_CD, --02币种
       ITEM_CD, --03科目号
       ORG_NUM, --04机构
       ACTUAL_MATURITY_DT, --05实际到期日期
       ACCT_NUM, --06合同号
       NEXT_PAYMENT, --07未使用贷款额度
       PMT_REMAIN_TERM_C, --08剩余期限
       PMT_REMAIN_TERM_C_MULT, --09还款计划单位
       IDENTITY_CODE, --10标识符
       CORP_SCALE, --11客户规模
       CUST_ID) --12客户ID
      SELECT 
       T1.DATA_DATE, --01数据日期
       T1.CURR_CD, --02币种
       '60302_G25' AS ITEM_CD, --03科目号
       T1.ORG_NUM, --04机构
       T1.CONTRACT_ORIG_MATURITY_DT AS ACTUAL_MATURITY_DT, --05实际到期日期
       T1.CONTRACT_NUM, --06合同号
       /* CASE
       WHEN T3.CIRCLE_LOAN_FLG = 'Y' THEN*/
       CASE
         WHEN T1.CONTRACT_AMT - NVL(T3.LOAN_ACCT_BAL, 0) < 0 THEN
          0
         ELSE
          T1.CONTRACT_AMT - NVL(T3.LOAN_ACCT_BAL, 0)
       END AS NEXT_PAYMENT, --07未使用贷款额度
       T1.CONTRACT_ORIG_MATURITY_DT - D_DATADATE_CCY PMT_REMAIN_TERM_C, --08剩余期限
       'D' PMT_REMAIN_TERM_C_MULT, --09剩余期限单位
       '1' AS IDENTITY_CODE, --10标识符
       'P' AS CORP_SCALE, --11客户规模
       T1.CUST_ID --12客户ID
        FROM PM_RSDATA.SMTMODS_L_AGRE_LOAN_CONTRACT T1
       INNER JOIN PM_RSDATA.SMTMODS_L_CUST_P T2
          ON T1.CUST_ID = T2.CUST_ID
         AND T2.DATA_DATE = I_DATADATE
       LEFT JOIN (SELECT ACCT_NUM,
                          SUM(LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                     FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN
                    WHERE DATA_DATE = I_DATADATE
                      AND CANCEL_FLG = 'N' --非核销 moidfy by djh 20240102
            AND LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
                    GROUP BY ACCT_NUM) T3
          ON T1.CONTRACT_NUM = T3.ACCT_NUM
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ACCT_STS = '1' --合同为有效合同
         AND T1.DATE_SOURCESD IN ('普通贷款', '贸易融资', '保理')
         AND T1.IF_CYCL='Y'; --只是取循环贷款
    COMMIT;
  -- 第二部分：【循环贷款】合同金额-借据余额
     INSERT 
    INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_BW 
      (DATA_DATE, --01数据日期
       CURR_CD, --02币种
       ITEM_CD, --03科目号
       ORG_NUM, --04机构
       ACTUAL_MATURITY_DT, --05实际到期日期
       ACCT_NUM, --06合同号
       NEXT_PAYMENT, --07未使用贷款额度
       PMT_REMAIN_TERM_C, --08剩余期限
       PMT_REMAIN_TERM_C_MULT, --09还款计划单位
       IDENTITY_CODE, --10标识符
       CORP_SCALE, --11客户规模
       CUST_ID) --12客户ID
      SELECT
       T1.DATA_DATE, --01数据日期
       T1.CURR_CD, --02币种
       '60302_G25' AS ITEM_CD, --03科目号
       T1.ORG_NUM, --04机构
       T1.CONTRACT_ORIG_MATURITY_DT AS ACTUAL_MATURITY_DT, --05实际到期日期
       T1.CONTRACT_NUM, --06合同号
       CASE
         WHEN T1.CONTRACT_AMT - NVL(T3.LOAN_ACCT_BAL, 0) < 0 THEN
          0
         ELSE
          T1.CONTRACT_AMT - NVL(T3.LOAN_ACCT_BAL, 0)
       END AS NEXT_PAYMENT, --07未使用贷款额度
       T1.CONTRACT_ORIG_MATURITY_DT - D_DATADATE_CCY PMT_REMAIN_TERM_C, --08剩余期限
      'D' PMT_REMAIN_TERM_C_MULT, --09剩余期限单位
       '2' AS IDENTITY_CODE, --10标识符
       CASE
         WHEN T2.CORP_SCALE = 'Z' OR T2.CORP_SCALE IS NULL THEN
          '9'
         ELSE
          T2.CORP_SCALE
       END AS CORP_SCALE, --11客户规模  如果为空值默认为9 ”其他“
       T1.CUST_ID --12客户ID
        FROM PM_RSDATA.SMTMODS_L_AGRE_LOAN_CONTRACT T1
       INNER JOIN PM_RSDATA.SMTMODS_L_CUST_C T2
          ON T1.CUST_ID = T2.CUST_ID
         AND T2.DATA_DATE = I_DATADATE
         AND T2.CUST_TYP <> '3' --ADD BY 20230530  剔除吉商树贷授信
       LEFT JOIN (SELECT ACCT_NUM,
                         SUM(LOAN_ACCT_BAL) AS LOAN_ACCT_BAL
                     FROM PM_RSDATA.SMTMODS_L_ACCT_LOAN
                    WHERE DATA_DATE = I_DATADATE
                      AND CANCEL_FLG = 'N' --非核销 moidfy by djh 20240102
            AND LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
                    GROUP BY ACCT_NUM) T3
          ON T1.CONTRACT_NUM = T3.ACCT_NUM
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.ACCT_STS = '1' --合同为有效合同
         AND T1.DATE_SOURCESD IN ('普通贷款', '贸易融资', '保理')
         AND T1.IF_CYCL='Y'; --只是取循环贷款
    COMMIT;

    -- 对私：602银行承兑汇票 601开出信用证 612保函  603整个 60301可撤销承诺/60303商票保贴/60302不可撤销贷款承诺 取余额
    INSERT 
    INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_BW 
      (DATA_DATE, --01数据日期
       CURR_CD, --02币种
       ITEM_CD, --03科目号
       ORG_NUM, --04机构
       ACTUAL_MATURITY_DT, --05实际到期日期
       ACCT_NUM, --06账号
       NEXT_PAYMENT, --07余额
       PMT_REMAIN_TERM_C, --08剩余期限
       PMT_REMAIN_TERM_C_MULT, --09单位
       LOAN_GRADE_CD, --10五级分类状态
       IDENTITY_CODE, --11标识符
       CORP_SCALE, --12客户规模
       CUST_ID) --13客户ID
      SELECT 
       T1.DATA_DATE, --01数据日期
       T1.CURR_CD, --02币种
       T1.GL_ITEM_CODE, --03科目号
       T1.ORG_NUM, --04机构
       MATURITY_DT AS ACTUAL_MATURITY_DT, --05实际到期日期
       T1.ACCT_NUM, --06账号
       NVL(T1.BALANCE, 0) AS NEXT_PAYMENT, --07余额
       T1.MATURITY_DT - D_DATADATE_CCY PMT_REMAIN_TERM_C, --08剩余期限
       'D' PMT_REMAIN_TERM_C_MULT, --09剩余期限单位
       T1.LOAN_GRADE_CD, --10五级分类状态
       '3' AS IDENTITY_CODE, --11标识符
       'P' AS CORP_SCALE, --12客户规模
       T1.CUST_ID --13客户ID
        FROM PM_RSDATA.SMTMODS_L_ACCT_OBS_LOAN T1
       INNER JOIN PM_RSDATA.SMTMODS_L_CUST_P T2
          ON T1.CUST_ID = T2.CUST_ID
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND SUBSTR(T1.GL_ITEM_CODE, 1, 4) IN ('7010', '7030', '7020', '7040'); --科目位数不同取前三位
    COMMIT;

    -- 对公：602银行承兑汇票 601开出信用证 612保函  603整个 60301可撤销承诺/60303商票保贴/60302不可撤销贷款承诺 取余额
    INSERT 
    INTO PM_RSDATA.CBRC_FDM_LNAC_PMT_BW 
      (DATA_DATE, --01数据日期
       CURR_CD, --02币种
       ITEM_CD, --03科目号
       ORG_NUM, --04机构
       ACTUAL_MATURITY_DT, --05实际到期日期
       ACCT_NUM, --06账号
       NEXT_PAYMENT, --07余额
       PMT_REMAIN_TERM_C, --08剩余期限
       PMT_REMAIN_TERM_C_MULT, --09剩余期限单位
       LOAN_GRADE_CD, --10五级分类状态
       IDENTITY_CODE, --11标识符
       CORP_SCALE, --12客户规模
       CUST_ID) --13客户ID
      SELECT 
       T1.DATA_DATE, --01数据日期
       T1.CURR_CD, --02币种
       T1.GL_ITEM_CODE, --03科目号
       T1.ORG_NUM, --04机构
       MATURITY_DT AS ACTUAL_MATURITY_DT, --05实际到期日期
       T1.ACCT_NUM, --06账号
       NVL(T1.BALANCE, 0) AS NEXT_PAYMENT, --07余额
       T1.MATURITY_DT - D_DATADATE_CCY PMT_REMAIN_TERM_C, --08剩余期限
       'D' PMT_REMAIN_TERM_C_MULT, --09剩余期限单位
       T1.LOAN_GRADE_CD, --10五级分类状态
       '4' AS IDENTITY_CODE, --11标识符
       CASE
         WHEN T2.CORP_SCALE = 'Z' OR T2.CORP_SCALE IS NULL THEN
          '9'
         ELSE
          T2.CORP_SCALE
       END AS CORP_SCALE, --12客户规模  如果为空值默认为9 ”其他“
       T1.CUST_ID --13客户ID
        FROM PM_RSDATA.SMTMODS_L_ACCT_OBS_LOAN T1
       INNER JOIN PM_RSDATA.SMTMODS_L_CUST_C T2
          ON T1.CUST_ID = T2.CUST_ID
         AND T2.DATA_DATE = I_DATADATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND SUBSTR(T1.GL_ITEM_CODE, 1, 4) IN ('7010', '7030', '7020', '7040'); --科目位数不同取前三位
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取表外至FDM_LNAC_PMT_BW中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取附注：主要表外业务情况至ID_G21_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --12.发行的银行承兑汇票
    --13.发行的跟单信用证
    --14.发行的保函
    INSERT  INTO PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI 
      (RQ,
       ORGNO,
       SUBJECT,
       NEXT_YS,
       NEXT_WEEK,
       NEXT_MONTH,
       NEXT_QUARTER,
       NEXT_YEAR,
       NEXT_FIVE,
       NEXT_TEN,
       MORE_TEN,
       YQ,
       LOCAL_STATION)
      SELECT 
  I_DATADATE,
  T1.ORG_NUM,
  T1.ITEM_CD,
  SUM(CASE WHEN T1.PMT_REMAIN_TERM_C = 1 THEN  T1.NEXT_PAYMENT * T2.CCY_RATE ELSE  0  END) AS NEXT_DAY,
  SUM(CASE WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 THEN T1.NEXT_PAYMENT * T2.CCY_RATE ELSE  0 END) AS NEXT_WEEK,
  SUM(CASE  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 THEN T1.NEXT_PAYMENT * T2.CCY_RATE ELSE 0  END) AS NEXT_MONTH,
  SUM(CASE WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 THEN T1.NEXT_PAYMENT * T2.CCY_RATE ELSE 0  END) AS NEXT_QUARTER,
  SUM(CASE  WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 THEN T1.NEXT_PAYMENT * T2.CCY_RATE ELSE 0  END) AS NEXT_YEAR,
  SUM(CASE  WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND 360 * 10 THEN T1.NEXT_PAYMENT * T2.CCY_RATE ELSE  0 END) AS NEXT_FIVE,
  SUM(CASE  WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND 360 * 10 THEN T1.NEXT_PAYMENT * T2.CCY_RATE ELSE  0 END) AS NEXT_TEN,
  SUM(CASE  WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 THEN T1.NEXT_PAYMENT * T2.CCY_RATE  ELSE 0   END) AS MORE_TEN,
  SUM(CASE WHEN T1.PMT_REMAIN_TERM_C <= 0 THEN T1.NEXT_PAYMENT * T2.CCY_RATE  ELSE  0  END) AS YQ,
  CASE
    WHEN T1.ITEM_CD LIKE '7020%' THEN '5.1_1'
    WHEN T1.ITEM_CD LIKE '7010%' THEN '5.1_2'
    ELSE '5.1_3'
  END AS LOCAL_STATION
FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_BW T1
LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
  ON T2.DATA_DATE = I_DATADATE
 AND T2.BASIC_CCY = T1.CURR_CD
 AND T2.FORWARD_CCY = 'CNY'
WHERE T1.DATA_DATE = I_DATADATE
  AND SUBSTR(T1.ITEM_CD, 1, 4) IN ('7010', '7020', '7040')
GROUP BY I_DATADATE, T1.ORG_NUM, T1.ITEM_CD;
    COMMIT;

      INSERT 
    INTO PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI 
      (RQ,
       ORGNO,
       SUBJECT,
       NEXT_YS,
       NEXT_WEEK,
       NEXT_MONTH,
       NEXT_QUARTER,
       NEXT_YEAR,
       NEXT_FIVE,
       NEXT_TEN,
       MORE_TEN,
       YQ,
       LOCAL_STATION)
      --15.提供的贷款承诺（不可无条件撤销）
      SELECT 
       I_DATADATE,
       T1.ORG_NUM,
       T1.ITEM_CD,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C = 1 THEN
              T1.NEXT_PAYMENT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_DAY,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 2 AND 7 THEN
              T1.NEXT_PAYMENT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_WEEK,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 8 AND 30 THEN
              T1.NEXT_PAYMENT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_MONTH,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 31 AND 90 THEN
              T1.NEXT_PAYMENT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_QUARTER,

       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 91 AND 360 THEN
              T1.NEXT_PAYMENT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_YEAR,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN 361 AND 360 * 5 THEN
              T1.NEXT_PAYMENT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_FIVE,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C BETWEEN (360 * 5 + 1) AND 360 * 10 THEN
              T1.NEXT_PAYMENT * T2.CCY_RATE
             ELSE
              0
           END) AS NEXT_TEN,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C > 360 * 10 THEN
              T1.NEXT_PAYMENT * T2.CCY_RATE
             ELSE
              0
           END) AS MORE_TEN,
       SUM(CASE
             WHEN T1.PMT_REMAIN_TERM_C <= 0 THEN
              T1.NEXT_PAYMENT * T2.CCY_RATE
             ELSE
              0
           END) YQ,
       '5.1_4'
        FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_BW T1
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = T1.CURR_CD
         AND T2.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.IDENTITY_CODE IN ('3', '4')
         AND T1.ITEM_CD = '70300201' --60302 不可撤销的贷款承诺
       GROUP BY I_DATADATE, T1.ORG_NUM, T1.ITEM_CD;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取附注：主要表外业务情况至ID_G21_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取总账取数汇总至FDM_LNAC_GL中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --总账取数汇总
--modiy by djh 20241210 修改正常信用卡部分
/*(1)1.6各项贷款A列取：逾期M0数据汇总;
(2)1.6各项贷款J列取值：业务状况表科目（1303+1306-13060402）值汇总减逾期M0数据汇总;*/

  INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
    SELECT I_DATADATE AS DATA_DATE ,
           '009803' AS ORG_NUM,
           '1.6.A' AS ITEM_CD,
           SUM((NVL(M0, 0) + NVL(M1, 0) + NVL(M2, 0) + NVL(M3, 0) +
               NVL(M4, 0) + NVL(M5, 0) + NVL(M6, 0) + NVL(M6_UP, 0)) *
               B.CCY_RATE) AS  DEBIT_BAL,
           NULL AS CURR_CD,
           NULL AS GL_ACCOUNT
      FROM PM_RSDATA.SMTMODS_L_ACCT_CARD_CREDIT T
      LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
        ON T.DATA_DATE = B.DATA_DATE
       AND T.CURR_CD = B.BASIC_CCY
       AND B.FORWARD_CCY = 'CNY'
     WHERE T.DATA_DATE = I_DATADATE
       AND T.LXQKQS = 0 --正常(连续欠款期数为0)
       ;
COMMIT;
     INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
 --modiy by djh 20241210 修改逾期逻辑,科目扣减正常(连续欠款期数为0)
    SELECT I_DATADATE,
           '009803' AS ORG_NUM,
           '1.6.H',
           Z.Z_TOAL - F.F_TOTAL,
           NULL,
           NULL
      FROM (SELECT sum(A.DEBIT_BAL * B.CCY_RATE) Z_TOAL
              FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A --信用卡逾期
              LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                ON A.DATA_DATE = B.DATA_DATE
               AND A.CURR_CD = B.BASIC_CCY
               AND B.FORWARD_CCY = 'CNY'
             WHERE A.DATA_DATE = I_DATADATE
               AND A.ORG_NUM = '009803'
               AND A.ITEM_CD IN
                   ('13030301', '13030303', '13060401', '13060403')
               AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
            ) Z
      LEFT JOIN (SELECT SUM((NVL(M0, 0) + NVL(M1, 0) + NVL(M2, 0) +
                            NVL(M3, 0) + NVL(M4, 0) + NVL(M5, 0) +
                            NVL(M6, 0) + NVL(M6_UP, 0)) * B.CCY_RATE) F_TOTAL
                   FROM PM_RSDATA.SMTMODS_L_ACCT_CARD_CREDIT T
                   LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                     ON T.DATA_DATE = B.DATA_DATE
                    AND T.CURR_CD = B.BASIC_CCY
                    AND B.FORWARD_CCY = 'CNY'
                  WHERE T.DATA_DATE = I_DATADATE
                    AND T.LXQKQS = 0)  F --正常(连续欠款期数为0)
        ON 1 = 1;
COMMIT;
     INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
    SELECT I_DATADATE,
           A.ORG_NUM,
           '1.8.A',
           sum(A.DEBIT_BAL * B.CCY_RATE),
           A.CURR_CD,
           A.ITEM_CD
      FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
      LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
        ON A.DATA_DATE = B.DATA_DATE
       AND A.CURR_CD = B.BASIC_CCY
       AND B.FORWARD_CCY = 'CNY'
     WHERE A.DATA_DATE = I_DATADATE
       AND A.ITEM_CD = '14310101'
       AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
       AND A.ORG_NUM NOT LIKE '%0000' --去掉分行,汇总时不需要
       AND A.ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                             /*'510000',*/ --磐石吉银村镇银行
                             '222222', --东盛除双阳汇总
                             '333333', --新双阳
                             '444444', --净月潭除双阳
                             '555555') --长春分行（除双阳、榆树、农安）
     GROUP BY A.ORG_NUM, A.CURR_CD, A.ITEM_CD
   ;COMMIT;

    INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      SELECT I_DATADATE,
             COALESCE(FA.ORG_UNIT_ID, FB.ORG_UNIT_ID) AS ORG_NUM,
             '1.8.B',
             CASE
               WHEN COALESCE(FA.CUR_BAL, 0) - COALESCE(FB.CUR_BAL, 0) >= 0 THEN
                COALESCE(FA.CUR_BAL, 0) - COALESCE(FB.CUR_BAL, 0)
               ELSE
                0
             END,
             COALESCE(FA.ISO_CURRENCY_CD, FB.ISO_CURRENCY_CD),
            --- '11003' AS ITEM_CD
             '100303' AS ITEM_CD
        FROM (SELECT A.DATA_DATE AS AS_OF_DATE,
                     A.ORG_NUM AS ORG_UNIT_ID,
                     A.CURR_CD AS ISO_CURRENCY_CD,
                     SUM(ABS(COALESCE(DEBIT_BAL * B.CCY_RATE, 0) -
                             COALESCE(CREDIT_BAL * B.CCY_RATE, 0))) AS CUR_BAL
                FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND ITEM_CD = '10030301'
                 AND ORG_NUM NOT LIKE '%0000'
                 AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
                 AND ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                                     /*'510000',*/ --磐石吉银村镇银行
                                     '222222', --东盛除双阳汇总
                                     '333333', --新双阳
                                     '444444', --净月潭除双阳
                                     '555555') --长春分行（除双阳、榆树、农安）
               GROUP BY A.DATA_DATE, A.ORG_NUM, A.CURR_CD) FA
        FULL OUTER JOIN (SELECT A.DATA_DATE AS AS_OF_DATE,
                                A.ORG_NUM AS ORG_UNIT_ID,
                                A.CURR_CD AS ISO_CURRENCY_CD,
                                SUM(ABS(COALESCE(CREDIT_BAL * B.CCY_RATE, 0) -
                                        COALESCE(DEBIT_BAL * B.CCY_RATE, 0))) AS CUR_BAL --ADD BY DJH 20230718
                           FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
                           LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
                             ON A.DATA_DATE = B.DATA_DATE
                            AND A.CURR_CD = B.BASIC_CCY
                            AND B.FORWARD_CCY = 'CNY'
                          WHERE A.DATA_DATE = I_DATADATE
                            AND (ITEM_CD IN (/*'20110301','20110302','20110303',*/ '20110401', '20110501','20110502','20110503','20110504', '20110601'--[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款,原逻辑中剔除]
                                           )
                                     OR ITEM_CD in (/*'2008',*/'2005'/*,'2009'*/) -- 修改内容：调整代理国库业务会计科目_20250527
                                           )
                            AND ORG_NUM NOT LIKE '%0000'
                            AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
                            AND ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                                                /*'510000',*/ --磐石吉银村镇银行
                                                '222222', --东盛除双阳汇总
                                                '333333', --新双阳
                                                '444444', --净月潭除双阳
                                                '555555') --长春分行（除双阳、榆树、农安）
                          GROUP BY A.DATA_DATE, A.ORG_NUM, A.CURR_CD) FB
          ON FA.AS_OF_DATE = FB.AS_OF_DATE
         AND FA.ORG_UNIT_ID = FB.ORG_UNIT_ID
         AND FA.ISO_CURRENCY_CD = FB.ISO_CURRENCY_CD
   ;
COMMIT;

      INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      SELECT I_DATADATE,
             '009803',
             '1.8.H',
             SUM(DEBIT_BAL * B.CCY_RATE) - SUM(CREDIT_BAL * B.CCY_RATE),
             A.CURR_CD,
             A.ITEM_CD
        FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD ='113201' --信用卡利息 放在逾期
         AND A.ORG_NUM = '009803'
         AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
       GROUP BY ORG_NUM, A.CURR_CD, A.ITEM_CD
;COMMIT;

       INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      --从1104总账出数GXH_SP_L_FINA_GL,因此先跑此过程,已在调度里面
      SELECT I_DATADATE,
             ORG_NUM,
             '1.9.G',
             SUM(ITEM_VAL),
             B_CURR_CD,
            -- '139' AS ITEM_CD
             '1221' AS ITEM_CD
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
       WHERE REP_NUM = 'G01'
         AND T.DATA_DATE = I_DATADATE
         AND t.ITEM_NUM LIKE 'G01_11..%'
         AND T.ITEM_NUM NOT LIKE '%C'
       GROUP BY ORG_NUM, B_CURR_CD
;
COMMIT;
      INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      SELECT I_DATADATE,
             ORG_NUM,
             '1.9.G',
             SUM(ITEM_VAL),
             B_CURR_CD,
           --  '162' AS ITEM_CD
             '1801' AS ITEM_CD
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
       WHERE REP_NUM = 'G01'
         AND T.DATA_DATE = I_DATADATE
         and t.ITEM_NUM LIKE 'G01_14..%'
         AND T.ITEM_NUM NOT LIKE '%C'
       GROUP BY ORG_NUM, B_CURR_CD
    ;
COMMIT;
      INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      --151减去152
      SELECT I_DATADATE,
             ORG_NUM,
             '1.9.G',
             NVL(SUM(CASE
                       WHEN t.ITEM_NUM LIKE 'G01_15..%' THEN
                        ITEM_VAL
                     END),
                 0) - NVL(SUM(CASE
                                WHEN t.ITEM_NUM LIKE 'G01_16..%' THEN
                                 ITEM_VAL
                              END),
                          0) AS TOTAL_BAL,
             B_CURR_CD,
             '151_152' AS ITEM_CD
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
       WHERE REP_NUM = 'G01'
         AND T.DATA_DATE = I_DATADATE
         and (t.ITEM_NUM LIKE 'G01_15..%' OR t.ITEM_NUM LIKE 'G01_16..%')
         AND T.ITEM_NUM NOT LIKE '%C'
       GROUP BY ORG_NUM, B_CURR_CD
     ;
COMMIT;
      INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      SELECT I_DATADATE,
             ORG_NUM,
             '1.9.G',
             SUM(ITEM_VAL),
             B_CURR_CD,
           ---  '153' AS ITEM_CD
             '1606' AS ITEM_CD
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
       WHERE REP_NUM = 'G01'
         AND T.DATA_DATE = I_DATADATE
         and t.ITEM_NUM LIKE 'G01_18..%'
         AND T.ITEM_NUM NOT LIKE '%C'
       GROUP BY ORG_NUM, B_CURR_CD
   ;
COMMIT;
      INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      SELECT I_DATADATE,
             ORG_NUM,
             '1.9.G',
             SUM(ITEM_VAL),
             B_CURR_CD,
           --  '154' AS ITEM_CD
             '1604' AS ITEM_CD
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
       WHERE REP_NUM = 'G01'
         AND T.DATA_DATE = I_DATADATE
         and t.ITEM_NUM LIKE 'G01_19..%'
         AND T.ITEM_NUM NOT LIKE '%C'
       GROUP BY ORG_NUM, B_CURR_CD
    ;
COMMIT;
      INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      SELECT I_DATADATE,
             ORG_NUM,
             '1.9.G',
             SUM(ITEM_VAL),
             B_CURR_CD,
             '161' AS ITEM_CD
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
       WHERE REP_NUM = 'G01'
         AND T.DATA_DATE = I_DATADATE
         and t.ITEM_NUM LIKE 'G01_20..%'
         AND T.ITEM_NUM NOT LIKE '%C'
       GROUP BY ORG_NUM, B_CURR_CD
 ;
COMMIT;
      INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      SELECT I_DATADATE,
             ORG_NUM,
             '1.9.G',
             SUM(ITEM_VAL),
             B_CURR_CD,
            --- '149' AS ITEM_CD
             '1441' AS ITEM_CD
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
       WHERE REP_NUM = 'G01'
         AND T.DATA_DATE = I_DATADATE
         and t.ITEM_NUM LIKE 'G01_21..%'
         AND T.ITEM_NUM NOT LIKE '%C'
       GROUP BY ORG_NUM, B_CURR_CD
     ;
COMMIT;
      INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      SELECT I_DATADATE,
             ORG_NUM,
             '1.9.G',
             SUM(ITEM_VAL),
             B_CURR_CD,
            --- '173' AS ITEM_CD
             '1811' AS ITEM_CD
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
       WHERE REP_NUM = 'G01'
         AND T.DATA_DATE = I_DATADATE
         and t.ITEM_NUM LIKE 'G01_22..%'
         AND T.ITEM_NUM NOT LIKE '%C'
       GROUP BY ORG_NUM, B_CURR_CD
     ;
COMMIT;
      INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      SELECT I_DATADATE,
             ORG_NUM,      --ADD BY DJH 20240510  投资银行部  已有009817数据
             '1.9.G',
             -1 * SUM(ITEM_VAL),
             B_CURR_CD,
             '998' AS ITEM_CD --减值
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
       WHERE REP_NUM = 'G01'
         AND T.DATA_DATE = I_DATADATE
         AND t.ITEM_NUM LIKE 'G01_24..%'
         AND T.ITEM_NUM NOT LIKE '%C'
       GROUP BY ORG_NUM, B_CURR_CD
  ;
COMMIT;
      INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
    (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
      --先跑GXH_SP_L_FINA_GL_NGI 总账的汇总逻辑  此处数据为了出G21 1.10其他没有确定到期日的资产数据,根据大为哥提供口径保持和G01扣减后一致
      SELECT I_DATADATE,
             ORG_NUM,
             '1.9.G',
             SUM(ITEM_VAL),
             B_CURR_CD,
             '999' AS ITEM_CD
        FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI T
       WHERE REP_NUM = 'G01'
         AND T.DATA_DATE = I_DATADATE
         AND t.ITEM_NUM LIKE 'G01_23..%'
         AND ITEM_NUM NOT LIKE '%C'
       GROUP BY ORG_NUM, B_CURR_CD;
    COMMIT;

    --ADD BY DJH 20230718 资管次日数据
     INSERT INTO PM_RSDATA.CBRC_FDM_LNAC_GL
      (DATA_DATE, ORG_NUM, ITEM_CD, DEBIT_BAL, CURR_CD, GL_ACCOUNT)
       SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_1.8.A',
             SUM(DEBIT_BAL * B.CCY_RATE) AS DEBIT_BAL,
             A.CURR_CD,
             A.ITEM_CD
        FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND ITEM_CD = '12210201' --jrsj垫资款 即 应收业务周转金 一直放次日
         AND ORG_NUM = '009816'
         AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
       GROUP BY A.ORG_NUM,A.CURR_CD, A.ITEM_CD;

      COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取总账取数汇总至FDM_LNAC_GL中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.6各项贷款至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI 
      SELECT I_DATADATE, ORGNO, '1.6.A', SUM(NEXT_YS)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI --PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE SUBJECT NOT LIKE '1306%'
         AND LOCAL_STATION = '1.6_1'
         AND RQ = I_DATADATE
       GROUP BY ORGNO
      UNION ALL
      SELECT I_DATADATE, A.ORG_NUM, ITEM_CD, sum(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A --信用卡逾期
       WHERE A.DATA_DATE = I_DATADATE
            --AND A.ITEM_CD = '13604'
         AND ITEM_CD = '1.6.A'
       GROUP BY I_DATADATE, A.ORG_NUM, ITEM_CD;

    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI 
      SELECT I_DATADATE, ORGNO, '1.6.B', SUM(NEXT_WEEK)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE SUBJECT NOT LIKE '1306%'
         AND LOCAL_STATION = '1.6_1'
         AND RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE, ORGNO, '1.6.C', SUM(NEXT_MONTH)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE SUBJECT NOT LIKE '1306%'
         AND LOCAL_STATION = '1.6_1'
         AND RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE, ORGNO, '1.6.D', SUM(NEXT_QUARTER)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE SUBJECT NOT LIKE '1306%'
         AND LOCAL_STATION = '1.6_1'
         AND RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE, ORGNO, '1.6.E', SUM(NEXT_YEAR)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE SUBJECT NOT LIKE '1306%'
         AND LOCAL_STATION = '1.6_1'
         AND RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE, ORGNO, '1.6.F', SUM(NEXT_FIVE)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE SUBJECT NOT LIKE '1306%'
         AND LOCAL_STATION = '1.6_1'
         AND RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE, ORGNO, '1.6.M', SUM(NEXT_TEN)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE SUBJECT NOT LIKE '1306%'
         AND LOCAL_STATION = '1.6_1'
         AND RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE, ORGNO, '1.6.N', SUM(MORE_TEN)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE SUBJECT NOT LIKE '1306%'
         AND LOCAL_STATION = '1.6_1'
         AND RQ = I_DATADATE
       GROUP BY ORGNO;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE, A.ORGNO, '1.6.H', SUM(A.YQ)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI A --逾期部分全部放这里
       WHERE A.RQ = I_DATADATE
         AND LOCAL_STATION = '1.6_1'
       GROUP BY A.ORGNO
      UNION ALL
      SELECT I_DATADATE, A.ORG_NUM, ITEM_CD, sum(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
            -- AND A.ITEM_CD = '12203' --信用卡
         AND ITEM_CD = '1.6.H'
       GROUP BY I_DATADATE, A.ORG_NUM, ITEM_CD;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.6各项贷款至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.8其他有确定到期日的资产至ID_G21_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             CASE WHEN T1.ORGNO  LIKE '5%' OR T1.ORGNO  LIKE '6%' THEN T1.ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN T1.ORGNO LIKE '%98%' THEN
                   T1.ORGNO
                    WHEN t1.ORGNO LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(T1.ORGNO, 1, 4) || '00'
                END as ORGNO,
             '1.8.A',
             SUM(NEXT_YS)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI T1
       WHERE LOCAL_STATION = '1.8_1'
            /* AND (SUBJECT in ('133010102', '133010202', '133010302') OR
            SUBJECT LIKE '129%')*/ --20211203  djh 所有利息（包括垫款）按照正常期限拆分,以下同
         AND RQ = I_DATADATE
       GROUP BY CASE WHEN T1.ORGNO  LIKE '5%' OR T1.ORGNO  LIKE '6%' THEN T1.ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN T1.ORGNO LIKE '%98%' THEN
                   T1.ORGNO
                    WHEN t1.ORGNO LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(T1.ORGNO, 1, 4) || '00'
                END
      UNION ALL
      SELECT I_DATADATE, A.ORG_NUM, ITEM_CD, sum(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
            -- AND A.ITEM_CD ='103'
         AND ITEM_CD = '1.8.A'
       GROUP BY I_DATADATE, A.ORG_NUM, ITEM_CD;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             CASE WHEN T1.ORGNO  LIKE '5%' OR T1.ORGNO  LIKE '6%' THEN T1.ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN T1.ORGNO LIKE '%98%' THEN
                   T1.ORGNO
                    WHEN t1.ORGNO LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(T1.ORGNO, 1, 4) || '00'
                END as ORGNO,
             '1.8.B',
             SUM(NEXT_WEEK)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI T1
       WHERE LOCAL_STATION = '1.8_1'
         AND RQ = I_DATADATE
       GROUP BY CASE WHEN T1.ORGNO  LIKE '5%' OR T1.ORGNO  LIKE '6%' THEN T1.ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN T1.ORGNO LIKE '%98%' THEN
                   T1.ORGNO
                    WHEN t1.ORGNO LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(T1.ORGNO, 1, 4) || '00'
                END
      UNION ALL
      SELECT I_DATADATE, A.ORG_NUM, ITEM_CD, sum(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
            --AND A.ITEM_CD ='11003'
         AND ITEM_CD = '1.8.B'
       GROUP BY I_DATADATE, A.ORG_NUM, ITEM_CD;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN ORGNO LIKE '%98%' THEN
                ORGNO
               WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(ORGNO, 1, 4) || '00'
             END AS ORGNO,  --MODI BY DJH 20230509
             '1.8.C',
             SUM(NEXT_MONTH)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION = '1.8_1'
         AND RQ = I_DATADATE
       GROUP BY CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN ORGNO LIKE '%98%' THEN
                ORGNO
               WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(ORGNO, 1, 4) || '00'
             END;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN ORGNO LIKE '%98%' THEN
                ORGNO
               WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(ORGNO, 1, 4) || '00'
             END AS ORGNO, --MODI BY DJH 20230509
             '1.8.D',
             SUM(NEXT_QUARTER)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION = '1.8_1'
         AND RQ = I_DATADATE
       GROUP BY CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN ORGNO LIKE '%98%' THEN
                   ORGNO
                  WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(ORGNO, 1, 4) || '00'
                END;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN ORGNO LIKE '%98%' THEN
                ORGNO
               WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(ORGNO, 1, 4) || '00'
             END AS ORGNO,
             '1.8.E',
             SUM(NEXT_YEAR)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION = '1.8_1'
         AND RQ = I_DATADATE
       GROUP BY CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN ORGNO LIKE '%98%' THEN
                   ORGNO
                  WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(ORGNO, 1, 4) || '00'
                END;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN ORGNO LIKE '%98%' THEN
                ORGNO
               WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(ORGNO, 1, 4) || '00'
             END AS ORGNO,
             '1.8.F',
             SUM(NEXT_FIVE)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION = '1.8_1'
         AND RQ = I_DATADATE
       GROUP BY CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN ORGNO LIKE '%98%' THEN
                   ORGNO
                  WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(ORGNO, 1, 4) || '00'
                END;
    COMMIT;

INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN ORGNO LIKE '%98%' THEN
                ORGNO
               WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(ORGNO, 1, 4) || '00'
             END AS ORGNO,
             '1.8.M',
             SUM(NEXT_TEN)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION = '1.8_1'
         AND RQ = I_DATADATE
       GROUP BY CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN ORGNO LIKE '%98%' THEN
                   ORGNO
                  WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(ORGNO, 1, 4) || '00'
                END;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN ORGNO LIKE '%98%' THEN
                ORGNO
               WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(ORGNO, 1, 4) || '00'
             END AS ORGNO,
             '1.8.N',
             SUM(MORE_TEN)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION = '1.8_1'
         AND RQ = I_DATADATE
       GROUP BY CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN ORGNO LIKE '%98%' THEN
                   ORGNO
                  WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(ORGNO, 1, 4) || '00'
                END;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN ORGNO LIKE '%98%' THEN
                ORGNO
               WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                '060300'
               ELSE
                SUBSTR(ORGNO, 1, 4) || '00'
             END AS ORGNO,
             '1.8.H',
             SUM(YQ)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION = '1.8_1'
         AND RQ = I_DATADATE
       GROUP BY CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN ORGNO LIKE '%98%' THEN
                   ORGNO
                  WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(ORGNO, 1, 4) || '00'
                END
      UNION ALL
      SELECT I_DATADATE, A.ORG_NUM, ITEM_CD, sum(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
            --AND A.ITEM_CD ='13301'
         AND ITEM_CD = '1.8.H' --逾期利息
       GROUP BY I_DATADATE, A.ORG_NUM, ITEM_CD;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.8其他有确定到期日的资产至ID_G21_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.10其他没有确定到期日的资产至ID_G21_ITEMDATA_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE, A.ORG_NUM, ITEM_CD, sum(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND ITEM_CD = '1.9.G'
       GROUP BY I_DATADATE, A.ORG_NUM, ITEM_CD;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.10其他没有确定到期日的资产至ID_G21_ITEMDATA_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /* ==========================================================================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据附注：主要表外业务情况至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             ORGNO,
             DECODE(LOCAL_STATION,
                    '5.1_1',
                    '12..A',
                    '5.1_2',
                    '13..A',
                    '5.1_3',
                    '14..A',
                    '5.1_4',
                    '15..A'),
             SUM(NVL(NEXT_YS, 0) + NVL(YQ, 0)) AS NEXT_YS
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION IN ('5.1_1', '5.1_2', '5.1_3', '5.1_4')
         AND RQ = I_DATADATE
       GROUP BY ORGNO,
                DECODE(LOCAL_STATION,
                       '5.1_1',
                       '12..A',
                       '5.1_2',
                       '13..A',
                       '5.1_3',
                       '14..A',
                       '5.1_4',
                       '15..A');
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             ORGNO,
             DECODE(LOCAL_STATION,
                    '5.1_1',
                    '12..B',
                    '5.1_2',
                    '13..B',
                    '5.1_3',
                    '14..B',
                    '5.1_4',
                    '15..B'),
             SUM(NEXT_WEEK)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION IN ('5.1_1', '5.1_2', '5.1_3', '5.1_4')
       GROUP BY ORGNO,
                DECODE(LOCAL_STATION,
                       '5.1_1',
                       '12..B',
                       '5.1_2',
                       '13..B',
                       '5.1_3',
                       '14..B',
                       '5.1_4',
                       '15..B');
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             ORGNO,
             DECODE(LOCAL_STATION,
                    '5.1_1',
                    '12..C',
                    '5.1_2',
                    '13..C',
                    '5.1_3',
                    '14..C',
                    '5.1_4',
                    '15..C'),
             SUM(NEXT_MONTH)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION IN ('5.1_1', '5.1_2', '5.1_3', '5.1_4')
         AND RQ = I_DATADATE
       GROUP BY ORGNO,
                DECODE(LOCAL_STATION,
                       '5.1_1',
                       '12..C',
                       '5.1_2',
                       '13..C',
                       '5.1_3',
                       '14..C',
                       '5.1_4',
                       '15..C');
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             ORGNO,
             DECODE(LOCAL_STATION,
                    '5.1_1',
                    '12..D',
                    '5.1_2',
                    '13..D',
                    '5.1_3',
                    '14..D',
                    '5.1_4',
                    '15..D'),
             SUM(NEXT_QUARTER)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION IN ('5.1_1', '5.1_2', '5.1_3', '5.1_4')
         AND RQ = I_DATADATE
       GROUP BY ORGNO,
                DECODE(LOCAL_STATION,
                       '5.1_1',
                       '12..D',
                       '5.1_2',
                       '13..D',
                       '5.1_3',
                       '14..D',
                       '5.1_4',
                       '15..D');
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             ORGNO,
             DECODE(LOCAL_STATION,
                    '5.1_1',
                    '12..E',
                    '5.1_2',
                    '13..E',
                    '5.1_3',
                    '14..E',
                    '5.1_4',
                    '15..E'),
             SUM(NEXT_YEAR)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION IN ('5.1_1', '5.1_2', '5.1_3', '5.1_4')
         AND RQ = I_DATADATE
       GROUP BY ORGNO,
                DECODE(LOCAL_STATION,
                       '5.1_1',
                       '12..E',
                       '5.1_2',
                       '13..E',
                       '5.1_3',
                       '14..E',
                       '5.1_4',
                       '15..E');
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             ORGNO,
             DECODE(LOCAL_STATION,
                    '5.1_1',
                    '12..F',
                    '5.1_2',
                    '13..F',
                    '5.1_3',
                    '14..F',
                    '5.1_4',
                    '15..F'),
             SUM(NEXT_FIVE)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION IN ('5.1_1', '5.1_2', '5.1_3', '5.1_4')
         AND RQ = I_DATADATE
       GROUP BY ORGNO,
                DECODE(LOCAL_STATION,
                       '5.1_1',
                       '12..F',
                       '5.1_2',
                       '13..F',
                       '5.1_3',
                       '14..F',
                       '5.1_4',
                       '15..F');
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             ORGNO,
             DECODE(LOCAL_STATION,
                    '5.1_1',
                    '12..G1',
                    '5.1_2',
                    '13..G1',
                    '5.1_3',
                    '14..G1',
                    '5.1_4',
                    '15..G1'),
             SUM(NEXT_TEN)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION IN ('5.1_1', '5.1_2', '5.1_3', '5.1_4')
         AND RQ = I_DATADATE
       GROUP BY ORGNO,
                DECODE(LOCAL_STATION,
                       '5.1_1',
                       '12..G1',
                       '5.1_2',
                       '13..G1',
                       '5.1_3',
                       '14..G1',
                       '5.1_4',
                       '15..G1');
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      SELECT I_DATADATE,
             ORGNO,
             DECODE(LOCAL_STATION,
                    '5.1_1',
                    '12..H1',
                    '5.1_2',
                    '13..H1',
                    '5.1_3',
                    '14..H1',
                    '5.1_4',
                    '15..H1'),
             SUM(MORE_TEN)
        FROM PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI
       WHERE LOCAL_STATION IN ('5.1_1', '5.1_2', '5.1_3', '5.1_4')
         AND RQ = I_DATADATE
       GROUP BY ORGNO,
                DECODE(LOCAL_STATION,
                       '5.1_1',
                       '12..H1',
                       '5.1_2',
                       '13..H1',
                       '5.1_3',
                       '14..H1',
                       '5.1_4',
                       '15..H1');
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据附注：主要表外业务情况至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   /*======================================================1.1现金==========================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.1现金至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM AS ORG_NUM,
             'G21_1.1.A',
             sum(A.DEBIT_BAL * B.CCY_RATE)
        FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD = '1001' --库存现金
         AND A.DEBIT_BAL <> 0
         AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
         AND A.ORG_NUM NOT LIKE '%0000' --去掉分行,汇总时不需要
         AND A.ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                               /*'510000',*/ --磐石吉银村镇银行
                               '222222', --东盛除双阳汇总
                               '333333', --新双阳
                               '444444', --净月潭除双阳
                               '555555') --长春分行（除双阳、榆树、农安）
       GROUP BY A.ORG_NUM;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.1现金至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /*======================================================1.2存放中央银行款项==========================================================*/
     V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.2存放中央银行款项至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --11002(存放中央银行超额备付金存款)次日,其他放未定期限
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM AS ORG_NUM,
             CASE
               WHEN A.ITEM_CD = '10030201' THEN
                'G21_1.2.A' --次日
               ELSE
                'G21_1.2.G' --未定期限
             END ITEM_NUM,
             sum(A.DEBIT_BAL * B.CCY_RATE)
        FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL A
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('10030101', '10030102', '10030201', '10030401')
         AND A.DEBIT_BAL <> 0
         AND A.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
         AND A.ORG_NUM NOT LIKE '%0000' --去掉分行,汇总时不需要
         AND A.ORG_NUM NOT IN ('019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                               /*'510000',*/ --磐石吉银村镇银行
                               '222222', --东盛除双阳汇总
                               '333333', --新双阳
                               '444444', --净月潭除双阳
                               '555555') --长春分行（除双阳、榆树、农安）
       GROUP BY A.ORG_NUM, A.ITEM_CD;
      COMMIT;

     V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.2存放中央银行款项至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /*======================================================1.3存放同业款项==========================================================*/
   V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.3存放同业款项至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --114(存放同业)、 117(存出保证金)
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.3.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.3.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.3.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.3.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.3.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.3.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.3.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.3.A'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.3.H.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
          AND A.FLAG='01'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.3.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.3.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.3.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.3.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.3.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.3.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.3.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.3.A'
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.3.H.2018'
                END;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.3存放同业款项至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /*======================================================1.4拆放同业==========================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.4拆放同业至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   --120(拆出资金)
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.4.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.4.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.4.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.4.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.4.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.4.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.4.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.4.A'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.4.H.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
          AND A.FLAG='02'
           GROUP BY A.ORG_NUM,
            CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.4.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.4.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.4.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.4.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.4.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.4.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.4.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.4.A'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.4.H.2018'
             END;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.4拆放同业至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /*======================================================1.5买入返售资产（不含非金融机构）==========================================================*/
    /*======================================================1.5.1与金融机构的交易==========================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数：1.5买入返售资产（不含非金融机构）至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /*140扣除减值准备,即：
    14001 买入返售债券
    14002 买入返售贷款
    14003 买入返售票据
    14099 买入返售其他金融资产*/
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.5.1.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.5.1.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.5.1.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.5.1.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.5.1.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.5.1.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.5.1.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.5.1.A.2018'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.5.1.H.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG='03'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.5.1.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.5.1.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.5.1.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.5.1.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.5.1.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.5.1.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.5.1.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.5.1.A.2018'
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.5.1.H.2018'
                END;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据: 1.5买入返售资产（不含非金融机构）至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*======================================================1.8持有同业存单==========================================================*/

        V_STEP_ID   := V_STEP_ID + 1;
        V_STEP_DESC := '提取数据：1.8持有同业存单至G21_DATA_COLLECT_TMP_NGI中间表';
        V_STEP_FLAG := 0;
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);


    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A.2018'
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A.2018'
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H.2018'
                END;

        V_STEP_FLAG := 1;
        V_STEP_DESC := '提取数据：1.8持有同业存单至G21_DATA_COLLECT_TMP_NGI中间表完成';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                    V_STEP_ID,
                    V_ERRORCODE,
                    V_STEP_DESC,
                    II_DATADATE);
    /* =================================1.7.1债券 金融市场部 add by chm 20230727=========================================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.7.1债券至TMP_A_CBRC_BOND_BAL中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --加工投资分析表 流动性报表债券部分使用
    INSERT INTO PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL
      (DATA_DATE,
       ORG_NUM,
       BOOK_TYPE,
       CURR_CD,
       ACCOUNTANT_TYPE,
       INVEST_TYP,
       DC_DATE,
       MATURITY_DATE,
       PRINCIPAL_BALANCE,
       PRINCIPAL_BALANCE_CNY,
       ACCT_BAL,
       ACCT_BAL_CNY,
       COLL_AMT,
       COLL_AMT_CNY,
       ZD_NET_AMT,
       ZD_NET_AMT_CNY,
       ACCRUAL,
       ACCRUAL_CNY,
       STOCK_CD,
       STOCK_NAM,
       ISSU_ORG,
       STOCK_PRO_TYPE,
       APPRAISE_TYPE,
       GL_ITEM_CODE

       )
      SELECT A.DATA_DATE,
             A.ORG_NUM, --机构号
             A.BOOK_TYPE, --账户种类
             A.CURR_CD, --币种
             A.ACCOUNTANT_TYPE, --会计分类
             A.INVEST_TYP, --投资业务品种
             A.DC_DATE, --代偿期
             A.MATURITY_DATE, --到期日
             A.PRINCIPAL_BALANCE, --剩余本金
             A.PRINCIPAL_BALANCE * TT.CCY_RATE, --剩余本金人民币
             A.ACCT_BAL, --持有仓位
             A.ACCT_BAL * TT.CCY_RATE, --持有仓位人民币
             A.COLL_AMT, --质押面额
             A.COLL_AMT * TT.CCY_RATE, --质押面额人民币
             A.ZD_NET_AMT, --中登净价金额
             A.ZD_NET_AMT * TT.CCY_RATE, --中登净价金额人民币
             A.ACCRUAL, --应收利息
             A.ACCRUAL * TT.CCY_RATE, --应收利息人民币
             B.STOCK_CD, --债券编号
             B.STOCK_NAM, --产品名称
             B.ISSU_ORG, --发行主体类型
             B.STOCK_PRO_TYPE, --产品分类
             B.APPRAISE_TYPE, --债券评级
             A.GL_ITEM_CODE --科目
        FROM PM_RSDATA.CBRC_V_PUB_FUND_INVEST A
        LEFT JOIN PM_RSDATA.SMTMODS_L_AGRE_BOND_INFO B --债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE TT
          ON TT.CCY_DATE = I_DATADATE
         AND TT.BASIC_CCY = A.CURR_CD
         AND TT.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.7.1债券投资至TMP_A_CBRC_BOND_BAL中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---- 取 1.7.1债券投资
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.7.1债券至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN (BOOK_TYPE = '2' and A.DC_DATE < 0) OR
                    STOCK_NAM = '18华阳经贸CP001' THEN
                'G21_1.7.1.H.2018'
               WHEN BOOK_TYPE = '2' and A.DC_DATE / 360 > 10 AND
                    STOCK_NAM <> '18华阳经贸CP001' THEN
                'G21_1.7.1.H1.2018' ---10年以上
               WHEN BOOK_TYPE = '2' and A.DC_DATE / 360 > 5 THEN
                'G21_1.7.1.G1.2018' --5-10年
               WHEN BOOK_TYPE = '2' and A.DC_DATE > 360 THEN
                'G21_1.7.1.F.2018' --1-5年
               WHEN BOOK_TYPE = '2' and A.DC_DATE > 90 THEN
                'G21_1.7.1.E.2018'
               WHEN BOOK_TYPE = '2' and A.DC_DATE > 30 THEN
                'G21_1.7.1.D.2018'
               WHEN BOOK_TYPE = '2' and A.DC_DATE > 7 THEN
                'G21_1.7.1.C.2018'
               WHEN BOOK_TYPE = '1' or (BOOK_TYPE = '2' and A.DC_DATE > 1) THEN
                'G21_1.7.1.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
               WHEN BOOK_TYPE = '2' and (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                'G21_1.7.1.A.2018'
             END AS ITEM_NUM,
             SUM(PRINCIPAL_BALANCE_CNY)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A --债券投资分析表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (BOOK_TYPE = '2' and A.DC_DATE < 0) OR
                       STOCK_NAM = '18华阳经贸CP001' THEN
                   'G21_1.7.1.H.2018'
                  WHEN BOOK_TYPE = '2' and A.DC_DATE / 360 > 10 AND
                       STOCK_NAM <> '18华阳经贸CP001' THEN
                   'G21_1.7.1.H1.2018' ---10年以上
                  WHEN BOOK_TYPE = '2' and A.DC_DATE / 360 > 5 THEN
                   'G21_1.7.1.G1.2018' --5-10年
                  WHEN BOOK_TYPE = '2' and A.DC_DATE > 360 THEN
                   'G21_1.7.1.F.2018' --1-5年
                  WHEN BOOK_TYPE = '2' and A.DC_DATE > 90 THEN
                   'G21_1.7.1.E.2018'
                  WHEN BOOK_TYPE = '2' and A.DC_DATE > 30 THEN
                   'G21_1.7.1.D.2018'
                  WHEN BOOK_TYPE = '2' and A.DC_DATE > 7 THEN
                   'G21_1.7.1.C.2018'
                  WHEN BOOK_TYPE = '1' or
                       (BOOK_TYPE = '2' and A.DC_DATE > 1) THEN
                   'G21_1.7.1.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
                  WHEN BOOK_TYPE = '2' and (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                   'G21_1.7.1.A.2018'
                END;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.7.1债券至G21_DATA_COLLECT_TMP_NGI完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---加工1.7.1.1 其中：符合1级HQLA定义
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.7.1.1 其中：符合1级HQLA定义至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN
                'G21_1.7.1.1.H.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
                'G21_1.7.1.1.H1.2018' ---10年以上
               WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
                'G21_1.7.1.1.G1.2018' --5-10年
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
                'G21_1.7.1.1.F.2018' --1-5年
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
                'G21_1.7.1.1.E.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
                'G21_1.7.1.1.D.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
                'G21_1.7.1.1.C.2018'
               WHEN BOOK_TYPE = '1' OR (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
                'G21_1.7.1.1.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
               WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                'G21_1.7.1.1.A.2018'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN A.ACCOUNTANT_TYPE = '2' AND A.BOOK_TYPE = 1 THEN
                    (A.PRINCIPAL_BALANCE_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                    ACCT_BAL_CNY)
                   ELSE
                    (ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                    ACCT_BAL_CNY)
                 END) AS AMT ---中登净价金额*可用面额/持有仓位
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A --债券投资分析表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND ACCT_BAL_CNY <> 0
         AND ((A.ISSU_ORG = 'D02' AND A.STOCK_PRO_TYPE LIKE 'C%') OR
             (A.ISSU_ORG = 'A01' AND A.STOCK_PRO_TYPE = 'A')) --政策银行债 , 国债
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN
                   'G21_1.7.1.1.H.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
                   'G21_1.7.1.1.H1.2018' ---10年以上
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
                   'G21_1.7.1.1.G1.2018' --5-10年
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
                   'G21_1.7.1.1.F.2018' --1-5年
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
                   'G21_1.7.1.1.E.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
                   'G21_1.7.1.1.D.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
                   'G21_1.7.1.1.C.2018'
                  WHEN BOOK_TYPE = '1' OR
                       (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
                   'G21_1.7.1.1.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
                  WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                   'G21_1.7.1.1.A.2018'
                END;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.7.1.1 其中：符合1级HQLA定义至G21_DATA_COLLECT_TMP_NGI完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---加工1.7.1.2 其中：符合2A级HQLA定义
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.7.1.2 其中：符合2A级HQLA定义至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN
                'G21_1.7.1.2.H.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
                'G21_1.7.1.2.H1.2018' ---10年以上
               WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
                'G21_1.7.1.2.G1.2018' --5-10年
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
                'G21_1.7.1.2.F.2018' --1-5年
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
                'G21_1.7.1.2.E.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
                'G21_1.7.1.2.D.2018'
               WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
                'G21_1.7.1.2.C.2018'
               WHEN BOOK_TYPE = '1' OR (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
                'G21_1.7.1.2.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
               WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                'G21_1.7.1.2.A.2018'
             END AS ITEM_NUM,
             SUM(CASE
                   WHEN A.ACCOUNTANT_TYPE = '2' AND A.BOOK_TYPE = 1 THEN
                    (A.PRINCIPAL_BALANCE_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                    A.ACCT_BAL_CNY)
                   ELSE
                    (A.ZD_NET_AMT_CNY * (A.ACCT_BAL_CNY - A.COLL_AMT_CNY) /
                    A.ACCT_BAL_CNY)
                 END) AS AMT ---中登净价金额*可用面额/持有仓位
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A --债券投资分析表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00'
         AND ACCT_BAL_CNY <> 0
         AND ((A.STOCK_PRO_TYPE = 'A' AND A.ISSU_ORG = 'A02') OR --地方政府债
             (A.APPRAISE_TYPE IN ('1', '2', '3', '4') AND --信用评级是>=AA的债券
             A.STOCK_PRO_TYPE IN ('D01', 'D02', 'D04', 'D05')) --超短期融资券,短期融资券,公司债,企业债,中期票据 且信用评级是AA的债券
             OR A.STOCK_CD IN ('032000573', '032001060')) --20四平城投PPN001  20四平城投PPN002 RPA取数没有债券评级,此处特殊处理
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE < 0 THEN
                   'G21_1.7.1.2.H.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 10 THEN
                   'G21_1.7.1.2.H1.2018' ---10年以上
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE / 360 > 5 THEN
                   'G21_1.7.1.2.G1.2018' --5-10年
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 360 THEN
                   'G21_1.7.1.2.F.2018' --1-5年
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 90 THEN
                   'G21_1.7.1.2.E.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 30 THEN
                   'G21_1.7.1.2.D.2018'
                  WHEN BOOK_TYPE = '2' AND A.DC_DATE > 7 THEN
                   'G21_1.7.1.2.C.2018'
                  WHEN BOOK_TYPE = '1' OR
                       (BOOK_TYPE = '2' AND A.DC_DATE > 1) THEN
                   'G21_1.7.1.2.B.2018' --交易账户都放2-7日,银行账户按照待偿期划分
                  WHEN BOOK_TYPE = '2' AND (A.DC_DATE = 1 OR A.DC_DATE = 0) THEN
                   'G21_1.7.1.2.A.2018'
                END;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.7.1.2 其中：符合2A级HQLA定义至G21_DATA_COLLECT_TMP_NGI完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---加工1.7.3其他
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.7.3其他至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009804',
             CASE
               WHEN A.MATURITY_DATE < I_DATADATE THEN
                'G21_1.7.3.H.2018'
               WHEN (A.MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
                'G21_1.7.3.H1.2018' ---10年以上
               WHEN (A.MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_1.7.3.G1.2018' --5-10年
               WHEN A.MATURITY_DATE - I_DATADATE > 360 THEN
                'G21_1.7.3.F.2018' --1-5年
               WHEN A.MATURITY_DATE - I_DATADATE > 90 THEN
                'G21_1.7.3.E.2018'
               WHEN A.MATURITY_DATE - I_DATADATE > 30 THEN
                'G21_1.7.3.D.2018'
               WHEN A.MATURITY_DATE - I_DATADATE > 7 THEN
                'G21_1.7.3.C.2018'
               WHEN A.MATURITY_DATE - I_DATADATE > 1 THEN
                'G21_1.7.3.B.2018'
               WHEN (A.MATURITY_DATE - I_DATADATE = 1 OR
                    A.MATURITY_DATE - I_DATADATE = 0) THEN
                'G21_1.7.3.A.2018'
             END AS ITEM_NUM,
             SUM(A.PRINCIPAL_BALANCE_CNY)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_BOND_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.GL_ITEM_CODE = '15010201' --业务口径：债权投资特定目的载体投资投资成本,目前就国民信托一笔
         AND A.ORG_NUM = '009804'
       GROUP BY CASE
                  WHEN A.MATURITY_DATE < I_DATADATE THEN
                   'G21_1.7.3.H.2018'
                  WHEN (A.MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
                   'G21_1.7.3.H1.2018' ---10年以上
                  WHEN (A.MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_1.7.3.G1.2018' --5-10年
                  WHEN A.MATURITY_DATE - I_DATADATE > 360 THEN
                   'G21_1.7.3.F.2018' --1-5年
                  WHEN A.MATURITY_DATE - I_DATADATE > 90 THEN
                   'G21_1.7.3.E.2018'
                  WHEN A.MATURITY_DATE - I_DATADATE > 30 THEN
                   'G21_1.7.3.D.2018'
                  WHEN A.MATURITY_DATE - I_DATADATE > 7 THEN
                   'G21_1.7.3.C.2018'
                  WHEN A.MATURITY_DATE - I_DATADATE > 1 THEN
                   'G21_1.7.3.B.2018'
                  WHEN (A.MATURITY_DATE - I_DATADATE = 1 OR
                       A.MATURITY_DATE - I_DATADATE = 0) THEN
                   'G21_1.7.3.A.2018'
                END;

    COMMIT;

    --ADD BY DJH 20240510  同业金融部
      /*基金（债券基金+货币基金）随时申赎的放到2-7日,取持有仓位+公允价值;
      委外投资取账户类型是FVTPL的且科目为11010303的持有仓位+公允价值都放到2-7日,其中中信信托2笔特殊处理按照剩余期限360天划分持有仓位+公允价值;
      剩余的定开（康星系统有标识,为剩余的债券基金投资）按照剩余期限划分,取持有仓位；
      所有AC账户,按剩余期限划分取持有仓位,其中2笔华创证券有限责任公司的到期日特殊处理成2028/11/30处理后划分；
      其中3笔AC账户的特殊处理,取持有仓位（中国华阳经贸集团有限公司,方正证券股份有限公司,东吴基金管理公司）放逾期；*/

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009820',
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.7.3.H.2018'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.7.3.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.7.3.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.7.3.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.7.3.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.7.3.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.7.3.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.7.3.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.7.3.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG IN (/*'01', '02', '04',*/ '06', '07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资) 08(AC账户)
         AND A.ORG_NUM = '009820'
       GROUP BY CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.7.3.H.2018'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.7.3.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.7.3.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.7.3.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.7.3.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.7.3.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.7.3.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.7.3.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.7.3.A.2018'
                END;

    COMMIT;
   --ADD BY DJH 20240510
    --009817机构存量的非标本金按剩余期限划分
     INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.7.3.H.2018'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.7.3.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.7.3.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.7.3.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.7.3.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.7.3.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.7.3.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.7.3.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.7.3.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG ='09' --投资银行
       GROUP BY ORG_NUM,CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.7.3.H.2018'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.7.3.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.7.3.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.7.3.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.7.3.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.7.3.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.7.3.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.7.3.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.7.3.A.2018'
                END;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.7.3其他至G21_DATA_COLLECT_TMP_NGI完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /* =================================1.9其他有确定到期日的资产 金融市场部 add by chm 20230727=========================================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：1.9其他有确定到期日的资产至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ---1.9其他有确定到期日的资产 : 买入返售应收利息+同业存单应收利息+债券投资应收利息
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1111买入返售本金对应的应收利息
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '03' --买入返售
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04' --同业存单
      --AND ORG_NUM = '009804'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;
    COMMIT;

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(INTEREST_ACCURAL) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '05' --债券投资
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

    COMMIT;
 --ADD BY DJH 20240510  同业金融部
        /*基金的随时申赎的应收放2-7日（货币基金有应收）;
        同业存单交易账簿应收利息放2-7日,其他按照到期日划分剩余期限;
        特殊处理应收按剩余期限划分（AC账户的中国华阳经贸集团有限公司,方正证券股份有限公司,东吴基金管理公司）;
        同业拆出应收按剩余期限划分;
        存放同业活期应收放次日;
        所有AC账户（除3笔特殊账户）,按剩余期限划分取应收利息,其中2笔华创证券有限责任公司的到期日特殊处理成2028/11/30处理后划分；
        +140万+63.32万(固定值)--固定值放逾期
        G01的11.其他应收款009820机构放逾期；*/

     --ADD BY DJH 20240510  金融市场部 拆放同业利息补充进来
     -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金本金对应的应收利息
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                'G21_1.8.H'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_1.8.N' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_1.8.M' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_1.8.F' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_1.8.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_1.8.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_1.8.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_1.8.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_1.8.A'
             END AS ITEM_NUM,
             SUM(A.INTEREST_ACCURAL)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG IN ('01', '02' /*, '04'*/, '06', '07', '08') ----01(1011存放同业,1031存出保证金)  02(1302拆出资金) 04(同业存单) 06(基金）07(委外投资) 08(AC账户)  已在金融市场取数
        -- AND A.ORG_NUM IN ('009820', '009804')
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'Y' THEN
                   'G21_1.8.H'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_1.8.N' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_1.8.M' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_1.8.F' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_1.8.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_1.8.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_1.8.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_1.8.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_1.8.A'
                END;

    COMMIT;
    --ADD BY DJH 20240510  同业金融部
    INSERT
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009820' AS ORG_NUM,
             'G21_1.8.H' AS ITEM_NUM,
             T.CREDIT_BAL
        FROM PM_RSDATA.SMTMODS_L_FINA_GL T
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'BWB'
         AND ITEM_CD IN ('12310101') -- 12310101 其他应收款坏账准备固定值放逾期 63.32万
         AND T.ORG_NUM = '009820';
     COMMIT;
    --ADD BY DJH 20240510  同业金融部
    INSERT
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             '009820' AS ORG_NUM, --只有009820
             'G21_1.8.H' AS ITEM_NUM,
             1400000 AS ITEM_VAL --140万固定值放逾期
        FROM SYSTEM.DUAL;
    COMMIT;
    --ADD BY DJH 20240510  投资银行部
    --009817机构存量的非标的应收利息+其他应收款按剩余期限划分


    INSERT INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI  (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
    SELECT I_DATADATE AS DATA_DATE,
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN 'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN 'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN 'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN 'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN 'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN 'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN 'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN 'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR  T1.PLA_MATURITY_DATE - I_DATADATE = 0  THEN
              'G21_1.8.A'
           END ITEM_NUM,
           SUM(T.INTEREST_ACCURAL+T.QTYSK)
      FROM PM_RSDATA.CBRC_TMP_A_CBRC_LOAN_BAL T
      LEFT JOIN (SELECT Q.ACCT_NUM,
                        Q.PLA_MATURITY_DATE,
                        ROW_NUMBER() OVER(PARTITION BY Q.ACCT_NUM ORDER BY Q.PLA_MATURITY_DATE) RN
                   FROM PM_RSDATA.SMTMODS_L_ACCT_FUND_MMFUND_PAYM_SCHED Q
                  WHERE Q.DATA_DATE = I_DATADATE
                    AND DATA_SOURCE = '投行业务'
                    AND Q.PLA_MATURITY_DATE > I_DATADATE
                 ) T1
        ON T.ACCT_NUM = T1.ACCT_NUM
       AND T1.RN = 1
     WHERE T.DATA_DATE = I_DATADATE
       AND T.FLAG = '09'
       --由于与投行业务沟通后发现利息的期限无法准确划分 故 该报表的第1.9项,除去逾期部分其余不在系统取数,业务手填
       AND (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE)
     GROUP BY
            T.ORG_NUM,
            CASE
             WHEN (T1.PLA_MATURITY_DATE IS NULL OR T1.PLA_MATURITY_DATE < I_DATADATE) THEN
              'G21_1.8.H' --Y
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 10 THEN
              'G21_1.8.N' ---10年以上
             WHEN (T1.PLA_MATURITY_DATE - I_DATADATE) / 360 > 5 THEN
              'G21_1.8.M' --5-10年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 360 THEN
              'G21_1.8.F' --1-5年
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 90 THEN
              'G21_1.8.E'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 30 THEN
              'G21_1.8.D'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 7 THEN
              'G21_1.8.C'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE > 1 THEN
              'G21_1.8.B'
             WHEN T1.PLA_MATURITY_DATE - I_DATADATE = 1 OR
                  T1.PLA_MATURITY_DATE - I_DATADATE = 0 THEN
              'G21_1.8.A'
           END  ;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.9其他有确定到期日的资产至G21_DATA_COLLECT_TMP_NGI完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：260科目与明细数据差异插至ITEM_MINUS_AMT_TEMP1中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--260开始

 --计算 260科目与明细数据差异
INSERT INTO PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1
  (ORG_NUM, MINUS_AMT, ITEM_CD, CURR_CD)
  SELECT NVL(P.ORG_NUM, A.ORG_NUM),
         NVL(P.CREDIT_BAL, 0) - NVL(A.AMT, 0) MINUS_AMT,
         '2231',
         NVL(P.CURR_CD, A.CURR_CD)
    FROM (SELECT G.ORG_NUM,
                 SUM(G.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL,
                 G.CURR_CD
            FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL G
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
              ON T2.DATA_DATE = I_DATADATE
             AND T2.BASIC_CCY = G.CURR_CD
             AND T2.FORWARD_CCY = 'CNY'
           INNER JOIN PM_RSDATA.CBRC_ITEM_CD_TEMP TEMP
              ON G.ITEM_CD = TEMP.ITEM_CD
           WHERE G.CREDIT_BAL <> 0
             AND G.ITEM_CD LIKE '2231%'
             AND G.DATA_DATE = I_DATADATE
             AND G.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
             AND G.ORG_NUM NOT LIKE '%0000' --去掉分行,汇总时不需要
             AND G.ORG_NUM NOT IN ('009803', --信用卡从明细出,此处不做差值
                                   '019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                                   --'510000', --磐石吉银村镇银行
                                   '222222', --东盛除双阳汇总
                                   '333333', --新双阳
                                   '444444', --净月潭除双阳
                                   '555555') --长春分行（除双阳、榆树、农安）
           GROUP BY G.ORG_NUM, G.CURR_CD) P
    FULL JOIN (SELECT 
                CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                   WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00' --支行
                END ORG_NUM,
                /*SUM(NVL(INTEREST_ACCURED, 0) + NVL(INTEREST_ACCURAL, 0)) AS AMT,*/
                SUM(CASE WHEN ORG_NUM = '009804' THEN NVL(INTEREST_ACCURAL, 0)
                         /* WHEN ORG_NUM = '009804' AND A.FLAG = '07' THEN
                           NVL(INTEREST_ACCURAL, 0)
                          WHEN ORG_NUM = '009804' AND A.FLAG <> '07' THEN
                           0*/
                          ELSE
                           NVL(INTEREST_ACCURED, 0) + NVL(INTEREST_ACCURAL, 0)
                        END) AS AMT, --mdf by chm 金融市场部只取应付利息,不取应计利息
                ACCT_CUR AS CURR_CD
                 FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                GROUP BY CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                           WHEN A.ORG_NUM LIKE '%98%' THEN
                            A.ORG_NUM
                             WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                                '060300'
                           ELSE
                            SUBSTR(A.ORG_NUM, 1, 4) || '00'
                         END,
                         A.ACCT_CUR) A
      ON A.ORG_NUM = P.ORG_NUM
     AND P.CURR_CD = A.CURR_CD;
COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：260科目与明细数据差异插至ITEM_MINUS_AMT_TEMP1中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   --add by djh  20230809差值机构与总账机构做比对,如果差值机构比总账多,说明总账此机构余额为0,明细有余额,
--处理方法： 那么需要把明细此机构利息都修改为0,防止倒减为负数,分摊某个期限时候,出现期限错位,目的更新TMP_A_CBRC_DEPOSIT_BAL表
INSERT INTO PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_ORGNUM
  (ORG_NUM)
  SELECT  a.org_num FROM (SELECT T.ORG_NUM
    FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1 T
   WHERE T.MINUS_AMT < 0
     AND T.ITEM_CD = '2231') a 
LEFT JOIN (SELECT DISTINCT G.ORG_NUM
    FROM PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL G
    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
      ON T2.DATA_DATE = I_DATADATE
     AND T2.BASIC_CCY = G.CURR_CD
     AND T2.FORWARD_CCY = 'CNY'
   INNER JOIN PM_RSDATA.CBRC_ITEM_CD_TEMP TEMP
      ON G.ITEM_CD = TEMP.ITEM_CD
   WHERE G.CREDIT_BAL <> 0
     AND G.ITEM_CD LIKE '2231%'
     AND G.DATA_DATE = I_DATADATE
     AND G.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
     AND G.ORG_NUM NOT LIKE '%0000' --去掉分行,汇总时不需要
     AND G.ORG_NUM NOT IN ('009803', --信用卡从明细出,此处不做差值
                           '019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                           --'510000', --磐石吉银村镇银行
                           '222222', --东盛除双阳汇总
                           '333333', --新双阳
                           '444444', --净月潭除双阳
                           '555555') --长春分行（除双阳、榆树、农安）
     AND G.ORG_NUM IN (SELECT ORG_NUM FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1)
  ) b
   ON a.ORG_NUM =b.ORG_NUM 
WHERE b.org_num IS NULL 
; --在差值范围内机构
COMMIT;
--建立临时表处理利息,处理利息后,再用
   
UPDATE PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL
   SET INTEREST_ACCURAL = 0, INTEREST_ACCURED = 0
 WHERE ORG_NUM IN (SELECT ORG_NUM FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_ORGNUM);

COMMIT;

UPDATE PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1 t
   SET MINUS_AMT = 0
 WHERE T.MINUS_AMT < 0
   AND T.ITEM_CD LIKE '2231%'
   AND ORG_NUM IN (SELECT ORG_NUM FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1_ORGNUM);

COMMIT;

 /* =================================3.1向中央银行借款=========================================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：3.1向中央银行借款至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN A.ORG_NUM LIKE '%98%' THEN
                A.ORG_NUM
               WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
               ELSE
                SUBSTR(A.ORG_NUM, 1, 4) || '00'
             END,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.1.H1.2018'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.1.G1.2018'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.1.F.2018'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.1.E'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.1.D'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.1.C'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.1.B'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.1.A'
             END AS ITEM_NUM,
             SUM(ACCT_BAL_RMB) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '02'
       GROUP BY CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                   WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.1.H1.2018'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.1.G1.2018'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.1.F.2018'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.1.E'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.1.D'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.1.C'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.1.B'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.1.A'
                END;
    /*UNION ALL
      SELECT I_DATADATE, A.ORG_NUM, 'G21_3.1.A' AS ITEM_NUM, sum(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
            --AND A.ITEM_CD ='11003'
         AND ITEM_CD = '3.1.A'
       GROUP BY I_DATADATE, A.ORG_NUM;
    */
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：3.1向中央银行借款至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /* =================================3.2同业存放款项=========================================================================*/
    /* =================================3.2.1定期存放=========================================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：3.2同业存放款项至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    ----同业存放定期
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.2.1.H1.2020' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.2.1.G1.2020' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.2.1.F.2020' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.2.1.E.2020'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.2.1.D.2020'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.2.1.C.2020'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.2.1.B.2020'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.2.1.A.2020' ---逾期放次日
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS BALANCE_CNY
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '03'
         AND A.GL_ITEM_CODE <> '20120204' --保险业金融机构存放款项放到3.5.1定期存款
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.2.1.H1.2020' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.2.1.G1.2020' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.2.1.F.2020' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.2.1.E.2020'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.2.1.D.2020'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.2.1.C.2020'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.2.1.B.2020'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.2.1.A.2020' ---逾期放次日
                END;
    COMMIT;
    /* =================================3.2.2活期存放=========================================================================*/

    ----同业存放 活期
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             'G21_3.2.2.A.2020' AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB)
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '04'
         AND A.GL_ITEM_CODE <> '20120106' --保险业金融机构存放款项放到3.5.2活期存款
       GROUP BY A.ORG_NUM;

    COMMIT;
    
  V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：3.2同业存放款项至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /* =================================3.3同业拆入=========================================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：3.3同业拆入至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.3.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.3.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.3.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.3.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.3.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.3.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.3.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.3.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS BALANCE_CNY
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '05'
         AND A.ACCT_BAL_RMB <> 0 --余额不为0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.3.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.3.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.3.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.3.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.3.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.3.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.3.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.3.A.2018'
                END;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：3.3同业拆入至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /*=================================3.4.1与金融机构的交易==========================================================*/

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：3.4.1与金融机构的交易至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.4.1.H1.2018' ---10年以上
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.4.1.G1.2018' --5-10年
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.4.1.F.2018' --1-5年
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.4.1.E.2018'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.4.1.D.2018'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.4.1.C.2018'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.4.1.B.2018'
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.4.1.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS BALANCE_CNY
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '07'
         AND A.ACCT_BAL_RMB <> 0 --余额不为0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.4.1.H1.2018' ---10年以上
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.4.1.G1.2018' --5-10年
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.4.1.F.2018' --1-5年
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.4.1.E.2018'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.4.1.D.2018'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.4.1.C.2018'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.4.1.B.2018'
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.4.1.A.2018'
                END;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：3.4.1与金融机构的交易至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /* =================================3.5各项存款=========================================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：3.5.1定期存款至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --  3.5.1定期存款    202、203、205、206、215、220、2340204、251,219结构性存款
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             CASE WHEN  A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN A.ORG_NUM LIKE '%98%' THEN
                A.ORG_NUM
               WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
               ELSE
                SUBSTR(A.ORG_NUM, 1, 4) || '00'
             END,
             CASE
               WHEN A.REMAIN_TERM_CODE = 'A' THEN
                'G21_3.5.1.A'
               WHEN A.REMAIN_TERM_CODE = 'B' THEN
                'G21_3.5.1.B'
               WHEN A.REMAIN_TERM_CODE = 'C' THEN
                'G21_3.5.1.C'
               WHEN A.REMAIN_TERM_CODE = 'D' THEN
                'G21_3.5.1.D'
               WHEN A.REMAIN_TERM_CODE = 'E' THEN
                'G21_3.5.1.E'
               WHEN A.REMAIN_TERM_CODE = 'F' THEN
                'G21_3.5.1.F.2018'
               WHEN A.REMAIN_TERM_CODE = 'G' THEN
                'G21_3.5.1.G1.2018'
               WHEN A.REMAIN_TERM_CODE = 'H' THEN
                'G21_3.5.1.H1.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款余额分析表（客户）
       WHERE A.DATA_DATE = I_DATADATE
         AND ( A.GL_ITEM_CODE IN
             ('20110205', '20110110', '20110202','20110203','20110204','20110211', '20110701', '20110103','20110104','20110105','20110106',
             '20110107','20110108','20110109', '20110208','20110113', '20110114','20110115','20110209','20110210','20110207','20110112') OR
             A.GL_ITEM_CODE = '20120204'
              OR A.GL_ITEM_CODE LIKE '2010%'  --ALTER BY 石雨 JLBA202504180011
             )
       GROUP BY CASE  WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                  WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN A.REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.5.1.A'
                  WHEN A.REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.5.1.B'
                  WHEN A.REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.5.1.C'
                  WHEN A.REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.5.1.D'
                  WHEN A.REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.5.1.E'
                  WHEN A.REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.5.1.F.2018'
                  WHEN A.REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.5.1.G1.2018'
                  WHEN A.REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.5.1.H1.2018'
                END;
     /* UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_3.5.1.A' AS ITEM_NUM,
             sum(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
            --AND A.ITEM_CD ='11003'
         AND ITEM_CD = '3.5.1.A'
       GROUP BY I_DATADATE, A.ORG_NUM;*/
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：3.5.1定期存款至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /* =================================3.5.2活期存款=========================================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：3.5.2活期存款至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --  3.5.2活期存款    201、211、217、218、234010204、243、244
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_3.5.2.A' AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款账户信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND (A.GL_ITEM_CODE  IN
             ('20110201', '20110101', '20110102','20110111', '20110206', '20130101','20130201','20130301', '20140101','20140201','20140301') OR
             A.GL_ITEM_CODE = '20120106'
             or a.gl_item_code in ('22410101','22410102','20110301','20110302','20110303','20080101','20090101')--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]
             )
       GROUP BY A.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：3.5.2活期存款至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /* =================================3.6发行债券 =========================================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：3.6发行债券至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'H' THEN
                'G21_3.6.H1.2018'
               WHEN REMAIN_TERM_CODE = 'G' THEN
                'G21_3.6.G1.2018'
               WHEN REMAIN_TERM_CODE = 'F' THEN
                'G21_3.6.F.2018'
               WHEN REMAIN_TERM_CODE = 'E' THEN
                'G21_3.6.E.2018'
               WHEN REMAIN_TERM_CODE = 'D' THEN
                'G21_3.6.D.2018'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G21_3.6.C.2018'
               WHEN REMAIN_TERM_CODE = 'B' THEN
                'G21_3.6.B.2018'
               WHEN REMAIN_TERM_CODE = 'A' THEN
                'G21_3.6.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款账户信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '08'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.6.H1.2018'
                  WHEN REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.6.G1.2018'
                  WHEN REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.6.F.2018'
                  WHEN REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.6.E.2018'
                  WHEN REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.6.D.2018'
                  WHEN REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.6.C.2018'
                  WHEN REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.6.B.2018'
                  WHEN REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.6.A.2018'
                END;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：3.6发行债券至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /* =================================3.7发行同业存单=========================================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：3.7发行同业存单至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --2340301同业存单款项-面值
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN REMAIN_TERM_CODE = 'H' THEN
                'G21_3.7.H1.2018'
               WHEN REMAIN_TERM_CODE = 'G' THEN
                'G21_3.7.G1.2018'
               WHEN REMAIN_TERM_CODE = 'F' THEN
                'G21_3.7.F.2018'
               WHEN REMAIN_TERM_CODE = 'E' THEN
                'G21_3.7.E.2018'
               WHEN REMAIN_TERM_CODE = 'D' THEN
                'G21_3.7.D.2018'
               WHEN REMAIN_TERM_CODE = 'C' THEN
                'G21_3.7.C.2018'
               WHEN REMAIN_TERM_CODE = 'B' THEN
                'G21_3.7.B.2018'
               WHEN REMAIN_TERM_CODE = 'A' THEN
                'G21_3.7.A.2018'
             END AS ITEM_NUM,
             SUM(A.ACCT_BAL_RMB) AS ITEM_VAL
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A --存款账户信息表
       WHERE A.DATA_DATE = I_DATADATE
         AND A.FLAG = '06'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN REMAIN_TERM_CODE = 'H' THEN
                   'G21_3.7.H1.2018'
                  WHEN REMAIN_TERM_CODE = 'G' THEN
                   'G21_3.7.G1.2018'
                  WHEN REMAIN_TERM_CODE = 'F' THEN
                   'G21_3.7.F.2018'
                  WHEN REMAIN_TERM_CODE = 'E' THEN
                   'G21_3.7.E.2018'
                  WHEN REMAIN_TERM_CODE = 'D' THEN
                   'G21_3.7.D.2018'
                  WHEN REMAIN_TERM_CODE = 'C' THEN
                   'G21_3.7.C.2018'
                  WHEN REMAIN_TERM_CODE = 'B' THEN
                   'G21_3.7.B.2018'
                  WHEN REMAIN_TERM_CODE = 'A' THEN
                   'G21_3.7.A.2018'
                END;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：3.7发行同业存单至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
      
     /* =================================3.8其他有确定到期日的负债=========================================================================*/
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：3.8其他有确定到期日的负债至G21_DATA_COLLECT_TMP_NGI中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --11003与221,222,223,225扎差负债方 260应付利息

    --其中的260应计利息处理
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
               WHEN A.ORG_NUM LIKE '%98%' THEN
                A.ORG_NUM
              WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
               ELSE
                SUBSTR(A.ORG_NUM, 1, 4) || '00'
             END,
             CASE
               WHEN (A.MATUR_DATE_ACCURED - I_DATADATE) / 360 > 10 THEN
                'G21_3.8.H1.2018'
               WHEN (A.MATUR_DATE_ACCURED - I_DATADATE) / 360 > 5 THEN
                'G21_3.8.G1.2018'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 360 THEN
                'G21_3.8.F.2018'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 90 THEN
                'G21_3.8.E'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 30 THEN
                'G21_3.8.D'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 7 THEN
                'G21_3.8.C'
               WHEN A.MATUR_DATE_ACCURED - I_DATADATE > 1 THEN
                'G21_3.8.B'
               WHEN (A.MATUR_DATE_ACCURED IS NULL OR A.MATUR_DATE_ACCURED - I_DATADATE <=1) THEN
                'G21_3.8.A'
             END AS ITEM_NUM,
             --SUM(NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0))  AS ITEM_VAL
             SUM(CASE
                    WHEN A.ORG_NUM = '009820' AND A.FLAG = '10' THEN NVL(ACCT_BAL_RMB,0) + NVL(INTEREST_ACCURAL, 0)
                    WHEN A.ORG_NUM IN ('009804','009801') AND A.FLAG IN ('05','07') THEN NVL(INTEREST_ACCURAL, 0)
                    ELSE NVL(INTEREST_ACCURED,0)+NVL(INTEREST_ACCURAL,0)
                 END) AS ITEM_VAL-- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君]增加009801清算中心外币业务2003拆入资金、2111卖出回购本金对应的应付利息
        FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
       WHERE A.DATA_DATE = I_DATADATE
        -- AND A.ORG_NUM <> '009804' --ADD BY CHM 金融市场部口径不一,单独处理
        -- AND (A.ACCT_TYP <> '9999' or A.ACCT_TYP is null) --虚拟账户应计利息放在3.9没有确定到期日的负债
       GROUP BY CASE WHEN A.ORG_NUM  LIKE '5%' OR A.ORG_NUM  LIKE '6%' THEN A.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                  WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00'
                END,
                CASE
                  WHEN (A.MATUR_DATE_ACCURED -
                       I_DATADATE) / 360 > 10 THEN
                   'G21_3.8.H1.2018'
                  WHEN (A.MATUR_DATE_ACCURED -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_3.8.G1.2018'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 360 THEN
                   'G21_3.8.F.2018'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 90 THEN
                   'G21_3.8.E'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 30 THEN
                   'G21_3.8.D'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 7 THEN
                   'G21_3.8.C'
                  WHEN A.MATUR_DATE_ACCURED -
                       I_DATADATE > 1 THEN
                   'G21_3.8.B'
                  WHEN (A.MATUR_DATE_ACCURED IS NULL OR A.MATUR_DATE_ACCURED - I_DATADATE <=1) THEN
                   'G21_3.8.A'
                END
      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_3.8.B' AS ITEM_NUM,
             sum(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
            --AND A.ITEM_CD ='11003'
         AND ITEM_CD = '3.8.B'
       GROUP BY I_DATADATE, A.ORG_NUM;


     COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：3.8其他有确定到期日的负债至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /* =================================3.9没有确定到期日的负债=========================================================================*/
    --初始化和归并公式都做,G01-从3.1到3.8项总值
    --260中无确定到期日的利息
    --应计利息虚拟数据
    --26008 向中央银行借款应付利息
    --2601501 应付债券利息
    --26099 其他应付利息


    /* =================================理财临时表=========================================================================*/

 --理财公共临时表 ,G21,G2501,G2502理财部分可以共用
INSERT INTO PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL
  (ORG_NUM,
   PRODUCT_CODE,
   PRODUCT_END_DATE,
   INTENDING_END_DATE,
   PROCEEDS_CHARACTER,
   BANK_ISSUE_FLG,
   OPER_TYPE,
   REDEMP_DATE,
   CURR_CD,
   END_PROD_AMT,
   END_PROD_AMT_CNY,
   ROLL_PERIOD,
   RECVAPAY_AMT,--应收应付金额 --ADD BY DJH 20230718
   FLAG)
--理财
  SELECT B.ORG_NUM,
         A.PRODUCT_CODE, --产品代码
         A.PRODUCT_END_DATE, --产品实际终止日期
         A.INTENDING_END_DATE, --产品预计终止日期
         A.PROCEEDS_CHARACTER, --收益特征
         A.BANK_ISSUE_FLG, --本行发行标志
         A.OPER_TYPE, --运行方式
         A.REDEMP_DATE, --最近开放赎回日期
         B.CURR_CD, --币种
         B.END_PROD_AMT, --期末产品余额
         B.END_PROD_AMT_CNY, --期末产品余额折人民币
         A.ROLL_PERIOD, --开放式产品滚动(或开发赎回)周期‘
         B.RECVAPAY_AMT * T2.CCY_RATE AS RECVAPAY_AMT,--应收应付金额 --ADD BY DJH 20230718
         '1' FLAG --理财部分
    FROM PM_RSDATA.SMTMODS_L_FIMM_PRODUCT A
   INNER JOIN PM_RSDATA.SMTMODS_L_FIMM_PRODUCT_BAL B
      ON B.DATA_DATE = I_DATADATE
     AND A.PRODUCT_CODE = B.PRODUCT_CODE
     AND A.PROCEEDS_CHARACTER = 'c' --收益特征是非保本浮动收益类
     AND A.BANK_ISSUE_FLG = 'Y' --只统计本行发行的,若本行代销的他行发行的理财产品不纳入统计
    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
          ON T2.DATA_DATE = I_DATADATE
         AND T2.BASIC_CCY = B.CURR_CD
         AND T2.FORWARD_CCY = 'CNY'
   WHERE A.DATA_DATE = I_DATADATE;
     --AND B.END_PROD_AMT_CNY <> 0  --ADD BY DJH 20230718
COMMIT;

--表外  G2501/G2502会用
INSERT INTO PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL
  (ORG_NUM,END_PROD_AMT_CNY, FLAG)
  SELECT A.ORG_NUM,
         A.BALANCE * U.CCY_RATE - NVL(A.SECURITY_AMT,0) * W.CCY_RATE AS COLLECT_VAL, --余额减保证金金额
         '2' FLAG --表外
    FROM PM_RSDATA.SMTMODS_L_ACCT_OBS_LOAN A
    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
      ON U.CCY_DATE = D_DATADATE_CCY
     AND U.BASIC_CCY = A.CURR_CD
     AND U.FORWARD_CCY = 'CNY'
    LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE W
      ON W.CCY_DATE = D_DATADATE_CCY
     AND W.BASIC_CCY = A.SECURITY_CURR
     AND W.FORWARD_CCY = 'CNY'
   WHERE A.DATA_DATE = I_DATADATE
     AND A.CREDIT_COMMIT_FLAG = 'N' --剔除信用卡承诺,因为G0101、A3304等表外业务表都有单独统计信用卡承诺的项是从信用卡补充信息表取数,此处为了避免重复,将信用卡承诺剔除。
     AND A.ACCT_TYP LIKE '6%';

  COMMIT;

    /* =================================16.1发行的非保本理财产品(封闭式)=========================================================================*/
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：16.1发行的非保本理财产品(封闭式)至G21_DATA_COLLECT_TMP_NGI中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                'G21_16.1.H.2021'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 5 THEN
                'G21_16.1.G1.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 360 THEN
                'G21_16.1.F.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 90 THEN
                'G21_16.1.E.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 30 THEN
                'G21_16.1.D.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 7 THEN
                'G21_16.1.C.2021'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 1 THEN
                'G21_16.1.B.2021'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                    COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE <= 1) THEN
                'G21_16.1.A.2021'
             END,
             SUM(A.END_PROD_AMT_CNY)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
         WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
          AND FLAG='1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 10 THEN
                   'G21_16.1.H.2021'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_16.1.G1.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 360 THEN
                   'G21_16.1.F.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 90 THEN
                   'G21_16.1.E.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 30 THEN
                   'G21_16.1.D.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 7 THEN
                   'G21_16.1.C.2021'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 1 THEN
                   'G21_16.1.B.2021'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                       COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE <= 1) THEN
                   'G21_16.1.A.2021'
                END;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：16.1发行的非保本理财产品(封闭式)至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /* =================================16.1发行的非保本理财产品(开放式)=========================================================================*/
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：16.2发行的非保本理财产品(开放式)至G21_DATA_COLLECT_TMP_NGI中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                'G21_16.2.H.2021'
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_16.2.G1.2021'
               WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                'G21_16.2.F.2021'
               WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                'G21_16.2.E.2021'
               WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                'G21_16.2.D.2021'
               WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                'G21_16.2.C.2021'
               WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                'G21_16.2.B.2021'
               WHEN (REDEMP_DATE IS NULL OR
                    REDEMP_DATE - I_DATADATE <= 1) THEN
                'G21_16.2.A.2021'
             END,
             /* CASE
               WHEN ROLL_PERIOD / 360 > 10 THEN --开放式产品滚动(或开发赎回)周期‘
                'G21_16.2.H.2021'
               WHEN ROLL_PERIOD / 360 > 5 THEN
                'G21_16.2.G.2021'
               WHEN ROLL_PERIOD > 360 THEN
                'G21_16.2.F.2021'
               WHEN ROLL_PERIOD > 90 THEN
                'G21_16.2.E.2021'
               WHEN ROLL_PERIOD > 30 THEN
                'G21_16.2.D.2021'
               WHEN ROLL_PERIOD > 7 THEN
                'G21_16.2.C.2021'
               WHEN ROLL_PERIOD > 1 THEN
                'G21_16.2.B.2021'
               WHEN (ROLL_PERIOD IS NULL OR ROLL_PERIOD < = 1) THEN
                'G21_16.2.A.2021'
             END,*/
             SUM(A.END_PROD_AMT_CNY)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                   'G21_16.2.H.2021'
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_16.2.G1.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                   'G21_16.2.F.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                   'G21_16.2.E.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                   'G21_16.2.D.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                   'G21_16.2.C.2021'
                  WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                   'G21_16.2.B.2021'
                  WHEN (REDEMP_DATE IS NULL OR
                       REDEMP_DATE - I_DATADATE <= 1) THEN
                   'G21_16.2.A.2021'
                END;
   COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：16.2发行的非保本理财产品(开放式)至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   --ADD BY DJH 20230718
      /* =================================1.9其他有确定到期日的资产(封闭式) 009816资管部数据=========================================================================*/
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.9其他有确定到期日的资产(封闭式)至G21_DATA_COLLECT_TMP_NGI中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                'G21_1.8.N'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                    COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                    I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '1%' --运行方式是封闭式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 10 THEN --产品实际终止日期,产品预计终止日期
                   'G21_1.8.N'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) IS NULL OR
                       COALESCE(A.PRODUCT_END_DATE, A.INTENDING_END_DATE) -
                       I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END
      UNION ALL
      SELECT I_DATADATE,
             A.ORG_NUM,
             'G21_1.8.A' AS ITEM_NUM,
             SUM(A.DEBIT_BAL)
        FROM PM_RSDATA.CBRC_FDM_LNAC_GL A
       WHERE A.DATA_DATE = I_DATADATE
         AND ITEM_CD = 'G21_1.8.A'
       GROUP BY I_DATADATE, A.ORG_NUM;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.9其他有确定到期日的资产(封闭式)至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /* =================================1.9其他有确定到期日的资产(开放式) 009816资管部数据=========================================================================*/
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.9其他有确定到期日的资产(开放式)至G21_DATA_COLLECT_TMP_NGI中间表';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT 
    INTO PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI
      (DATA_DATE, ORG_NUM, ITEM_NUM, ITEM_VAL)
      SELECT I_DATADATE,
             A.ORG_NUM,
             CASE
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                'G21_1.8.N'
               WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                'G21_1.8.M'
               WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                'G21_1.8.F'
               WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                'G21_1.8.E'
               WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                'G21_1.8.D'
               WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                'G21_1.8.C'
               WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                'G21_1.8.B'
               WHEN (REDEMP_DATE IS NULL OR
                    REDEMP_DATE - I_DATADATE <= 1) THEN
                'G21_1.8.A'
             END,
             SUM(A.RECVAPAY_AMT)
        FROM PM_RSDATA.CBRC_TMP_FIMM_PRODUCT_BAL A
       WHERE A.OPER_TYPE LIKE '2%' --运行方式是开放式
         AND FLAG = '1'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 10 THEN --最近开放赎回日期
                   'G21_1.8.N'
                  WHEN (REDEMP_DATE - I_DATADATE) / 360 > 5 THEN
                   'G21_1.8.M'
                  WHEN REDEMP_DATE - I_DATADATE > 360 THEN
                   'G21_1.8.F'
                  WHEN REDEMP_DATE - I_DATADATE > 90 THEN
                   'G21_1.8.E'
                  WHEN REDEMP_DATE - I_DATADATE > 30 THEN
                   'G21_1.8.D'
                  WHEN REDEMP_DATE - I_DATADATE > 7 THEN
                   'G21_1.8.C'
                  WHEN REDEMP_DATE - I_DATADATE > 1 THEN
                   'G21_1.8.B'
                  WHEN (REDEMP_DATE IS NULL OR
                       REDEMP_DATE - I_DATADATE <= 1) THEN
                   'G21_1.8.A'
                END;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：1.9其他有确定到期日的资产(开放式)至G21_DATA_COLLECT_TMP_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   /* =================================插入结果表=========================================================================*/


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据G21数据插至PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI中间表';
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
             'G21' AS REP_NUM,
             CASE
               WHEN T.ITEM_NUM = '1.6.A' THEN
                'G21_1.6.A'
               WHEN T.ITEM_NUM = '1.6.B' THEN
                'G21_1.6.B'
               WHEN T.ITEM_NUM = '1.6.C' THEN
                'G21_1.6.C'
               WHEN T.ITEM_NUM = '1.6.D' THEN
                'G21_1.6.D'
               WHEN T.ITEM_NUM = '1.6.E' THEN
                'G21_1.6.E'
               WHEN T.ITEM_NUM = '1.6.F' THEN
                'G21_1.6.F'
               WHEN T.ITEM_NUM = '1.6.H' THEN
                'G21_1.6.H'
               WHEN T.ITEM_NUM = '1.6.M' THEN
                'G21_1.6.M'
               WHEN T.ITEM_NUM = '1.6.N' THEN
                'G21_1.6.N'

               WHEN T.ITEM_NUM = '1.8.A' THEN
                'G21_1.8.A'
               WHEN T.ITEM_NUM = '1.8.B' THEN
                'G21_1.8.B'
               WHEN T.ITEM_NUM = '1.8.C' THEN
                'G21_1.8.C'
               WHEN T.ITEM_NUM = '1.8.D' THEN
                'G21_1.8.D'
               WHEN T.ITEM_NUM = '1.8.E' THEN
                'G21_1.8.E'
               WHEN T.ITEM_NUM = '1.8.F' THEN
                'G21_1.8.F'
               WHEN T.ITEM_NUM = '1.8.H' THEN
                'G21_1.8.H'
               WHEN T.ITEM_NUM = '1.8.M' THEN
                'G21_1.8.M'
               WHEN T.ITEM_NUM = '1.8.N' THEN
                'G21_1.8.N'

               WHEN T.ITEM_NUM = '1.9.G' THEN
                'G21_1.9.G'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_4.1.A'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_4.1.B'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_4.1.C'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_4.1.D'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_4.1.E'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_4.1.F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_4.1.G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_4.1.H1.2018'

               WHEN T.ITEM_NUM = '12..A' THEN
                'G21_12..A.2018'
               WHEN T.ITEM_NUM = '12..B' THEN
                'G21_12..B.2018'
               WHEN T.ITEM_NUM = '12..C' THEN
                'G21_12..C.2018'
               WHEN T.ITEM_NUM = '12..D' THEN
                'G21_12..D.2018'
               WHEN T.ITEM_NUM = '12..E' THEN
                'G21_12..E.2018'
               WHEN T.ITEM_NUM = '12..F' THEN
                'G21_12..F.2018'
               WHEN T.ITEM_NUM = '12..G1' THEN
                'G21_12..G1.2018'
               WHEN T.ITEM_NUM = '12..H1' THEN
                'G21_12..H1.2018'

               WHEN T.ITEM_NUM = '13..A' THEN
                'G21_13..A.2018'
               WHEN T.ITEM_NUM = '13..B' THEN
                'G21_13..B.2018'
               WHEN T.ITEM_NUM = '13..C' THEN
                'G21_13..C.2018'
               WHEN T.ITEM_NUM = '13..D' THEN
                'G21_13..D.2018'
               WHEN T.ITEM_NUM = '13..E' THEN
                'G21_13..E.2018'
               WHEN T.ITEM_NUM = '13..F' THEN
                'G21_13..F.2018'
               WHEN T.ITEM_NUM = '13..G1' THEN
                'G21_13..G1.2018'
               WHEN T.ITEM_NUM = '13..H1' THEN
                'G21_13..H1.2018'

               WHEN T.ITEM_NUM = '14..A' THEN
                'G21_14..A.2018'
               WHEN T.ITEM_NUM = '14..B' THEN
                'G21_14..B.2018'
               WHEN T.ITEM_NUM = '14..C' THEN
                'G21_14..C.2018'
               WHEN T.ITEM_NUM = '14..D' THEN
                'G21_14..D.2018'
               WHEN T.ITEM_NUM = '14..E' THEN
                'G21_14..E.2018'
               WHEN T.ITEM_NUM = '14..F' THEN
                'G21_14..F.2018'
               WHEN T.ITEM_NUM = '14..G1' THEN
                'G21_14..G1.2018'
               WHEN T.ITEM_NUM = '14..H1' THEN
                'G21_14..H1.2018'

               WHEN T.ITEM_NUM = '15..A' THEN
                'G21_15..A.2018'
               WHEN T.ITEM_NUM = '15..B' THEN
                'G21_15..B.2018'
               WHEN T.ITEM_NUM = '15..C' THEN
                'G21_15..C.2018'
               WHEN T.ITEM_NUM = '15..D' THEN
                'G21_15..D.2018'
               WHEN T.ITEM_NUM = '15..E' THEN
                'G21_15..E.2018'
               WHEN T.ITEM_NUM = '15..F' THEN
                'G21_15..F.2018'
               WHEN T.ITEM_NUM = '15..G1' THEN
                'G21_15..G1.2018'
               WHEN T.ITEM_NUM = '15..H1' THEN
                'G21_15..H1.2018'
               ELSE
                T.ITEM_NUM --存款,其他
             END AS ITEM_NUM,
             /*SUM(T.ITEM_VAL) AS ITEM_VAL,*/
             SUM(CASE
                   WHEN ITEM_NUM = 'G21_1.8.H' AND ORG_NUM = '009804' THEN
                    ITEM_VAL
                   ELSE
                    T.ITEM_VAL
                 END) AS ITEM_VAL,
             CASE
               WHEN T.ITEM_NUM = '1.9.G' THEN -- 1.10其他没有确定到期日资产不汇总,直接出总账数据
                '1'
               ELSE
                '2'
             END AS FLAG,
             'ALL' AS B_CURR_CD
        FROM PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI T
       WHERE TRIM(T.DATA_DATE) = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM,
                T.ITEM_NUM,
                CASE
                  WHEN T.ITEM_NUM = '1.6.A' THEN
                   'G21_1.6.A'
                  WHEN T.ITEM_NUM = '1.6.B' THEN
                   'G21_1.6.B'
                  WHEN T.ITEM_NUM = '1.6.C' THEN
                   'G21_1.6.C'
                  WHEN T.ITEM_NUM = '1.6.D' THEN
                   'G21_1.6.D'
                  WHEN T.ITEM_NUM = '1.6.E' THEN
                   'G21_1.6.E'
                  WHEN T.ITEM_NUM = '1.6.F' THEN
                   'G21_1.6.F'
                  WHEN T.ITEM_NUM = '1.6.H' THEN
                   'G21_1.6.H'
                  WHEN T.ITEM_NUM = '1.6.M' THEN
                   'G21_1.6.M'
                  WHEN T.ITEM_NUM = '1.6.N' THEN
                   'G21_1.6.N'

                  WHEN T.ITEM_NUM = '1.8.A' THEN
                   'G21_1.8.A'
                  WHEN T.ITEM_NUM = '1.8.B' THEN
                   'G21_1.8.B'
                  WHEN T.ITEM_NUM = '1.8.C' THEN
                   'G21_1.8.C'
                  WHEN T.ITEM_NUM = '1.8.D' THEN
                   'G21_1.8.D'
                  WHEN T.ITEM_NUM = '1.8.E' THEN
                   'G21_1.8.E'
                  WHEN T.ITEM_NUM = '1.8.F' THEN
                   'G21_1.8.F'
                  WHEN T.ITEM_NUM = '1.8.H' THEN
                   'G21_1.8.H'
                  WHEN T.ITEM_NUM = '1.8.M' THEN
                   'G21_1.8.M'
                  WHEN T.ITEM_NUM = '1.8.N' THEN
                   'G21_1.8.N'

                  WHEN T.ITEM_NUM = '1.9.G' THEN
                   'G21_1.9.G'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_4.1.A'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_4.1.B'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_4.1.C'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_4.1.D'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_4.1.E'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_4.1.F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_4.1.G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_4.1.H1.2018'

                  WHEN T.ITEM_NUM = '12..A' THEN
                   'G21_12..A.2018'
                  WHEN T.ITEM_NUM = '12..B' THEN
                   'G21_12..B.2018'
                  WHEN T.ITEM_NUM = '12..C' THEN
                   'G21_12..C.2018'
                  WHEN T.ITEM_NUM = '12..D' THEN
                   'G21_12..D.2018'
                  WHEN T.ITEM_NUM = '12..E' THEN
                   'G21_12..E.2018'
                  WHEN T.ITEM_NUM = '12..F' THEN
                   'G21_12..F.2018'
                  WHEN T.ITEM_NUM = '12..G1' THEN
                   'G21_12..G1.2018'
                  WHEN T.ITEM_NUM = '12..H1' THEN
                   'G21_12..H1.2018'

                  WHEN T.ITEM_NUM = '13..A' THEN
                   'G21_13..A.2018'
                  WHEN T.ITEM_NUM = '13..B' THEN
                   'G21_13..B.2018'
                  WHEN T.ITEM_NUM = '13..C' THEN
                   'G21_13..C.2018'
                  WHEN T.ITEM_NUM = '13..D' THEN
                   'G21_13..D.2018'
                  WHEN T.ITEM_NUM = '13..E' THEN
                   'G21_13..E.2018'
                  WHEN T.ITEM_NUM = '13..F' THEN
                   'G21_13..F.2018'
                  WHEN T.ITEM_NUM = '13..G1' THEN
                   'G21_13..G1.2018'
                  WHEN T.ITEM_NUM = '13..H1' THEN
                   'G21_13..H1.2018'

                  WHEN T.ITEM_NUM = '14..A' THEN
                   'G21_14..A.2018'
                  WHEN T.ITEM_NUM = '14..B' THEN
                   'G21_14..B.2018'
                  WHEN T.ITEM_NUM = '14..C' THEN
                   'G21_14..C.2018'
                  WHEN T.ITEM_NUM = '14..D' THEN
                   'G21_14..D.2018'
                  WHEN T.ITEM_NUM = '14..E' THEN
                   'G21_14..E.2018'
                  WHEN T.ITEM_NUM = '14..F' THEN
                   'G21_14..F.2018'
                  WHEN T.ITEM_NUM = '14..G1' THEN
                   'G21_14..G1.2018'
                  WHEN T.ITEM_NUM = '14..H1' THEN
                   'G21_14..H1.2018'

                  WHEN T.ITEM_NUM = '15..A' THEN
                   'G21_15..A.2018'
                  WHEN T.ITEM_NUM = '15..B' THEN
                   'G21_15..B.2018'
                  WHEN T.ITEM_NUM = '15..C' THEN
                   'G21_15..C.2018'
                  WHEN T.ITEM_NUM = '15..D' THEN
                   'G21_15..D.2018'
                  WHEN T.ITEM_NUM = '15..E' THEN
                   'G21_15..E.2018'
                  WHEN T.ITEM_NUM = '15..F' THEN
                   'G21_15..F.2018'
                  WHEN T.ITEM_NUM = '15..G1' THEN
                   'G21_15..G1.2018'
                  WHEN T.ITEM_NUM = '15..H1' THEN
                   'G21_15..H1.2018'
                  ELSE
                   T.ITEM_NUM --存款
                END;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据G21数据插至PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：计算133与总账差值利息数据插至ITEM_MINUS_AMT_TEMP1中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--计算133与总账差值
INSERT INTO PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1
  (ORG_NUM, MINUS_AMT, ITEM_CD, CURR_CD)
  SELECT NVL(P.ORG_NUM, A.ORG_NUM),
         NVL(P.DEBIT_BAL, 0) - NVL(A.AMT, 0) MINUS_AMT,
         '113201',
         NVL(P.CURR_CD, A.CURR_CD)
    FROM (SELECT G.ORG_NUM,
                 SUM(G.DEBIT_BAL * T2.CCY_RATE) DEBIT_BAL,
                 G.CURR_CD
            FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL G
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
              ON T2.DATA_DATE = I_DATADATE
             AND T2.BASIC_CCY = G.CURR_CD
             AND T2.FORWARD_CCY = 'CNY'
           INNER JOIN PM_RSDATA.CBRC_ITEM_CD_TEMP TEMP
              ON G.ITEM_CD = TEMP.ITEM_CD
           WHERE G.DEBIT_BAL <> 0
             AND (G.ITEM_CD LIKE '113201%' OR G.ITEM_CD LIKE '113202%' OR G.ITEM_CD LIKE '113203%')
             AND G.DATA_DATE = I_DATADATE
             AND G.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
             AND G.ORG_NUM NOT LIKE '%0000' --去掉分行,汇总时不需要
             AND G.ORG_NUM NOT IN ('009803', --信用卡从明细出,此处不做差值
                                   '019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                                   /*'510000',*/ --磐石吉银村镇银行
                                   '222222', --东盛除双阳汇总
                                   '333333', --新双阳
                                   '444444', --净月潭除双阳
                                   '555555') --长春分行（除双阳、榆树、农安）
           GROUP BY G.ORG_NUM, G.CURR_CD) P
    FULL JOIN (SELECT
                CASE WHEN T1.ORG_NUM  LIKE '5%' OR T1.ORG_NUM  LIKE '6%' THEN T1.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                  WHEN T1.ORG_NUM LIKE '%98%' THEN
                   T1.ORG_NUM
                    WHEN t1.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(T1.ORG_NUM, 1, 4) || '00'
                END AS ORG_NUM,
                T1.CURR_CD,
                SUM(CASE
                      WHEN T1.IDENTITY_CODE = '3' THEN
                       T1.ACCU_INT_AMT * T2.CCY_RATE
                      ELSE
                       0
                    END) + SUM(NVL(T1.OD_INT, 0) * T2.CCY_RATE)  AS AMT --营改增挂账利息废弃
                 FROM PM_RSDATA.CBRC_FDM_LNAC_PMT_LX T1
                 LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
                   ON T2.DATA_DATE = I_DATADATE
                  AND T2.BASIC_CCY = T1.CURR_CD
                  AND T2.FORWARD_CCY = 'CNY'
                WHERE T1.DATA_DATE = I_DATADATE
                  AND T1.IDENTITY_CODE IN ('3', '4')
                GROUP BY CASE WHEN T1.ORG_NUM  LIKE '5%' OR T1.ORG_NUM  LIKE '6%' THEN T1.ORG_NUM  --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                           WHEN T1.ORG_NUM LIKE '%98%' THEN
                            T1.ORG_NUM
                             WHEN t1.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                               '060300'
                           ELSE
                            SUBSTR(T1.ORG_NUM, 1, 4) || '00'
                         END,
                         T1.CURR_CD) A
      ON A.ORG_NUM = P.ORG_NUM
     AND P.CURR_CD = A.CURR_CD;
COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：计算133与总账差值利息数据插至ITEM_MINUS_AMT_TEMP1中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：计算13301科目数比明细数据大的数据插至ITEM_MINUS_AMT_TEMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--计算 13301科目数比明细数据大的
INSERT INTO
 PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP (
ORG_NUM ,
MINUS_AMT ,
ITEM_CD ,
CURR_CD,
QX
)

SELECT T.ORG_NUM,
       CASE
         WHEN A.ITEM_NUM = 'NEXT_YS' THEN
          SUM(T.MINUS_AMT * (1 / 360))
         WHEN A.ITEM_NUM = 'NEXT_WEEK' THEN
          SUM(T.MINUS_AMT * (6 / 360))
         WHEN A.ITEM_NUM = 'NEXT_MONTH' THEN
          SUM(T.MINUS_AMT * (23 / 360))
         WHEN A.ITEM_NUM = 'NEXT_QUARTER' THEN
          SUM(T.MINUS_AMT * (60 / 360))
         WHEN A.ITEM_NUM = 'NEXT_YEAR' THEN
          SUM(T.MINUS_AMT * (270 / 360))
       END AMT
       ,113201,T.CURR_CD,A.ITEM_NUM
  FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1 T
 INNER JOIN (SELECT 'NEXT_YS' ITEM_NUM
               FROM SYSTEM.DUAL
             UNION ALL
             SELECT 'NEXT_WEEK' ITEM_NUM
               FROM SYSTEM.DUAL
             UNION ALL
             SELECT 'NEXT_MONTH' ITEM_NUM
               FROM SYSTEM.DUAL
             UNION ALL
             SELECT 'NEXT_QUARTER' ITEM_NUM
               FROM SYSTEM.DUAL
             UNION ALL
             SELECT 'NEXT_YEAR' ITEM_NUM
               FROM SYSTEM.DUAL) A
    ON 1 = 1
 WHERE T.ITEM_CD =  '113201'
 --T.ITEM_CD = '13301'
/* (T.ITEM_CD like  '113201%'  OR
 T.ITEM_CD like  '113202%'  OR
 T.ITEM_CD like  '113203%' )*/
   AND T.MINUS_AMT > 0
 GROUP BY T.ORG_NUM,A.ITEM_NUM,T.CURR_CD;
 COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：计算13301科目数比明细数据大的数据插至ITEM_MINUS_AMT_TEMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：计算13301科目数比明细数据小的数据插至ITEM_MINUS_AMT_TEMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 --计算 13301科目数比明细数据小的


INSERT INTO PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP
  (ORG_NUM, MINUS_AMT, ITEM_CD, CURR_CD, QX)
  SELECT C.ORGNO, TEMP.MINUS_AMT, TEMP.ITEM_CD, TEMP.CURR_CD, C.lx
    FROM (SELECT B.ORGNO, B.lx
            FROM (SELECT A.ORGNO, A.lx,SUM(AMT) AMT,ROW_NUMBER() OVER(PARTITION BY A.ORGNO ORDER BY SUM(AMT) DESC) AS RN
                    FROM (select  CASE WHEN ORGNO  LIKE '5%' OR ORGNO  LIKE '6%' THEN ORGNO --BY CH 20231110  原有逻辑,会过滤掉村镇机构
                                   WHEN ORGNO LIKE '%98%' THEN
                                    ORGNO
                                   WHEN ORGNO LIKE '060101' THEN --特殊机构处理 上级非截取00
                                    '060300'
                                   ELSE
                                    SUBSTR(ORGNO, 1, 4) || '00' --支行
                                 END AS ORGNO , (amt) ,lx from (                              
select   ORGNO, RQ, NEXT_YS AMT ,SUBJECT,'NEXT_YS' lx from  PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI WHERE LOCAL_STATION = '1.8_1'  --次日
    union all
select   ORGNO, RQ, NEXT_WEEK AMT ,SUBJECT,'NEXT_WEEK' lx from  PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI WHERE LOCAL_STATION = '1.8_1'  -- 2日至7日
     union all
select   ORGNO, RQ, NEXT_MONTH AMT ,SUBJECT,'NEXT_MONTH'lx  from  PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI WHERE LOCAL_STATION = '1.8_1'  --8日至30日
         union all
select   ORGNO, RQ, NEXT_QUARTER AMT ,SUBJECT,'NEXT_QUARTER'lx from  PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI WHERE LOCAL_STATION = '1.8_1'   --31日至90日
         union all
select   ORGNO, RQ, NEXT_YEAR AMT ,SUBJECT,'NEXT_YEAR'lx from  PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI  WHERE LOCAL_STATION = '1.8_1'   --91日至1年
    union all
select   ORGNO, RQ, NEXT_FIVE AMT ,SUBJECT,'NEXT_FIVE'lx from  PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI WHERE LOCAL_STATION = '1.8_1'   --1年至5年
    union all 
select   ORGNO, RQ, NEXT_TEN AMT ,SUBJECT,'NEXT_TEN'lx from  PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI WHERE LOCAL_STATION = '1.8_1'   --5年至10年
    union all 
 select   ORGNO, RQ, MORE_TEN AMT ,SUBJECT,'MORE_TEN'lx from  PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI WHERE LOCAL_STATION = '1.8_1'   --10年以上
    union all 
     select   ORGNO, RQ, YQ AMT ,SUBJECT,'YQ' lx from  PM_RSDATA.CBRC_ID_G21_ITEMDATA_NGI WHERE LOCAL_STATION = '1.8_1'    --逾期 
    )) A WHERE A.AMT > 0  GROUP BY A.lx, A.ORGNO) B --djh 20220722
           WHERE B.RN = 1) C
   INNER JOIN PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1 TEMP
      ON C.ORGNO = TEMP.ORG_NUM
     AND TEMP.MINUS_AMT < 0
     AND TEMP.ITEM_CD = '113201';
 COMMIT;
 

--133处理完成
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：计算13301科目数比明细数据小的数据插至ITEM_MINUS_AMT_TEMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


 /*   V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：260科目与明细数据差异插至ITEM_MINUS_AMT_TEMP1中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

--260开始

 --计算 260科目与明细数据差异
INSERT INTO PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1
  (ORG_NUM, MINUS_AMT, ITEM_CD, CURR_CD)
  SELECT NVL(P.ORG_NUM, A.ORG_NUM),
         NVL(P.CREDIT_BAL, 0) - NVL(A.AMT, 0) MINUS_AMT,
         '2231',
         NVL(P.CURR_CD, A.CURR_CD)
    FROM (SELECT G.ORG_NUM,
                 SUM(G.CREDIT_BAL * T2.CCY_RATE) CREDIT_BAL,
                 G.CURR_CD
            FROM  PM_RSDATA.SMTMODS_V_PUB_IDX_FINA_GL G
            LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE T2
              ON T2.DATA_DATE = I_DATADATE
             AND T2.BASIC_CCY = G.CURR_CD
             AND T2.FORWARD_CCY = 'CNY'
           INNER JOIN ITEM_CD_TEMP TEMP
              ON G.ITEM_CD = TEMP.ITEM_CD
           WHERE G.CREDIT_BAL <> 0
             AND G.ITEM_CD LIKE '2231%'
             AND G.DATA_DATE = I_DATADATE
             AND G.CURR_CD NOT IN ('BWB', 'USY', 'CFC') --本外币合计 折币的去掉
             AND G.ORG_NUM NOT LIKE '%0000' --去掉分行,汇总时不需要
             AND G.ORG_NUM NOT IN ('009803', --信用卡从明细出,此处不做差值
                                   '019899', --金融市场总部,因为包含了金融市场部等其它几个机构,汇总时会导致机构重复
                                  -- '510000', --磐石吉银村镇银行
                                   '222222', --东盛除双阳汇总
                                   '333333', --新双阳
                                   '444444', --净月潭除双阳
                                   '555555') --长春分行（除双阳、榆树、农安）
           GROUP BY G.ORG_NUM, G.CURR_CD) P
    FULL JOIN (SELECT \*+PARALLEL(A,4)*\
                CASE
                  WHEN A.ORG_NUM LIKE '%98%' THEN
                   A.ORG_NUM
                   WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                   '060300'
                  ELSE
                   SUBSTR(A.ORG_NUM, 1, 4) || '00' --支行
                END ORG_NUM,
                SUM(NVL(INTEREST_ACCURED, 0) + NVL(INTEREST_ACCURAL, 0)) AS AMT,
                ACCT_CUR AS CURR_CD
                 FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
                GROUP BY CASE
                           WHEN A.ORG_NUM LIKE '%98%' THEN
                            A.ORG_NUM
                             WHEN A.ORG_NUM LIKE '060101' THEN   --特殊机构处理 上级非截取00
                                '060300'
                           ELSE
                            SUBSTR(A.ORG_NUM, 1, 4) || '00'
                         END,
                         A.ACCT_CUR) A
      ON A.ORG_NUM = P.ORG_NUM
     AND P.CURR_CD = A.CURR_CD;
COMMIT;
*/
--明细虚拟账户应计利息,用总账倒减差值分摊
/*INSERT INTO PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1
  (ORG_NUM, MINUS_AMT, ITEM_CD, CURR_CD)

  SELECT P.ORG_NUM, P.ITEM_VAL AS MINUS_AMT, '2231', P.CURR_CD
    FROM (SELECT \*+PARALLEL(A,4)*\
           CASE
             WHEN A.ORG_NUM LIKE '%98%' THEN
              A.ORG_NUM
             ELSE
              SUBSTR(A.ORG_NUM, 1, 4) || '00'
           END ORG_NUM,
           SUM(NVL(INTEREST_ACCURED, 0) + NVL(INTEREST_ACCURAL, 0)) AS ITEM_VAL,
           ACCT_CUR AS CURR_CD
            FROM PM_RSDATA.CBRC_TMP_A_CBRC_DEPOSIT_BAL A
           WHERE A.ACCT_TYP = '9999' -- ADD BY DJH 明细去掉虚拟账户应计利息,用总账倒减差值分摊
           GROUP BY CASE
                      WHEN A.ORG_NUM LIKE '%98%' THEN
                       A.ORG_NUM
                      ELSE
                       SUBSTR(A.ORG_NUM, 1, 4) || '00'
                    END,
                    A.ACCT_CUR) P;

COMMIT;*/

   /* V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：260科目与明细数据差异插至ITEM_MINUS_AMT_TEMP1中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
*/


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：260科目数比明细数据大的数据插至ITEM_MINUS_AMT_TEMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--计算 260科目数比明细数据大的


INSERT INTO
 PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP (
ORG_NUM ,
MINUS_AMT ,
ITEM_CD ,
CURR_CD,
QX
)

SELECT T.ORG_NUM,
       CASE
         WHEN A.ITEM_NUM = 'NEXT_YS' THEN
          SUM(T.MINUS_AMT * (1 / 360))
         WHEN A.ITEM_NUM = 'NEXT_WEEK' THEN
          SUM(T.MINUS_AMT * (6 / 360))
         WHEN A.ITEM_NUM = 'NEXT_MONTH' THEN
          SUM(T.MINUS_AMT * (23 / 360))
         WHEN A.ITEM_NUM = 'NEXT_QUARTER' THEN
          SUM(T.MINUS_AMT * (60 / 360))
         WHEN A.ITEM_NUM = 'NEXT_YEAR' THEN
          SUM(T.MINUS_AMT * (270 / 360))
       END AMT
       ,T.ITEM_CD,T.CURR_CD,A.ITEM_NUM
  FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1 T
 INNER JOIN (SELECT 'NEXT_YS' ITEM_NUM
               FROM SYSTEM.DUAL
             UNION ALL
             SELECT 'NEXT_WEEK' ITEM_NUM
               FROM SYSTEM.DUAL
             UNION ALL
             SELECT 'NEXT_MONTH' ITEM_NUM
               FROM SYSTEM.DUAL
             UNION ALL
             SELECT 'NEXT_QUARTER' ITEM_NUM
               FROM SYSTEM.DUAL
             UNION ALL
             SELECT 'NEXT_YEAR' ITEM_NUM
               FROM SYSTEM.DUAL) A
    ON 1 = 1
 WHERE T.ITEM_CD = '2231'
   AND T.MINUS_AMT > 0
 GROUP BY T.ORG_NUM,A.ITEM_NUM,T.CURR_CD,T.ITEM_CD;
 COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：260科目数比明细数据大的数据插至ITEM_MINUS_AMT_TEMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据：260科目数比明细数据小的数据插至ITEM_MINUS_AMT_TEMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
INSERT INTO
 PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP (
ORG_NUM ,
MINUS_AMT ,
ITEM_CD ,
CURR_CD,
QX
)
SELECT C.ORG_NUM, TEMP.MINUS_AMT, TEMP.ITEM_CD, TEMP.CURR_CD, C.QX
  FROM ( SELECT A.ORG_NUM,A.QX
         FROM (SELECT CASE
                        WHEN T.ITEM_NUM = 'G21_3.8.A' THEN
                         'NEXT_YS'
                        WHEN T.ITEM_NUM = 'G21_3.8.B' THEN
                         'NEXT_WEEK'
                        WHEN T.ITEM_NUM = 'G21_3.8.C' THEN
                         'NEXT_MONTH'
                        WHEN T.ITEM_NUM = 'G21_3.8.D' THEN
                         'NEXT_QUARTER'
                        WHEN T.ITEM_NUM = 'G21_3.8.E' THEN
                         'NEXT_YEAR'
                        WHEN T.ITEM_NUM = 'G21_3.8.F.2018' THEN
                         'NEXT_FIVE'
                        WHEN T.ITEM_NUM = 'G21_3.8.G1.2018' THEN
                         'NEXT_TEN'
                        WHEN T.ITEM_NUM = 'G21_3.8.H1.2018' THEN
                         'MORE_TEN'
                      END QX,
                      T.ORG_NUM, --在3.8已经处理成支行了,直接关联
                      SUM(T.ITEM_VAL) ITEM_VAL,
                      ROW_NUMBER() OVER(PARTITION BY T.ORG_NUM ORDER BY SUM(T.ITEM_VAL) DESC) AS RN
                 FROM PM_RSDATA.CBRC_G21_DATA_COLLECT_TMP_NGI T
                WHERE T.ITEM_NUM LIKE 'G21_3.8%'
                GROUP BY ITEM_NUM, T.ORG_NUM) A
        WHERE A.RN = 1) C
 INNER JOIN PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP1 TEMP
    ON C.ORG_NUM = TEMP.ORG_NUM
   AND TEMP.MINUS_AMT < 0
   AND TEMP.ITEM_CD = '2231';
 COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据：260科目数比明细数据小的数据插至ITEM_MINUS_AMT_TEMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据G21的PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI至1104目标表PM_RSDATA.CBRC_A_REPT_ITEM_VAL';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



   DELETE FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND T.REP_NUM = 'G21';

    COMMIT;
--处理133,260利息 不足的数据,与总账找齐

INSERT 
    INTO PM_RSDATA.CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       IS_TOTAL)
SELECT I_DATADATE,
       ORG_NUM,
       SYS_NAM,
       REP_NUM,
       ITEM_NUM,
       SUM(ITEM_VAL) AS ITEM_VAL,
       ITEM_VAL_V,
       FLAG,
       B_CURR_CD,
       CASE
           WHEN ITEM_NUM = 'G21_1.9.G' THEN  --ADD BY DJH 20230509 里面有轧差不参与汇总
            'N'
         END IS_TOTAL
  FROM (SELECT 
         A.ORG_NUM,
         SYS_NAM,
         REP_NUM,
         ITEM_NUM,
         NVL(A.ITEM_VAL, 0) AS ITEM_VAL,
         ITEM_VAL_V,
         FLAG,
         B_CURR_CD
          FROM PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI A
         WHERE A.DATA_DATE = I_DATADATE
           AND A.REP_NUM = 'G21'
        UNION ALL
        SELECT 
         B.ORG_NUM,
         'CBRC' AS SYS_NAM,
         'G21' REP_NUM,
         CASE
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YS' THEN
            'G21_1.8.A'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_WEEK' THEN
            'G21_1.8.B'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_MONTH' THEN
            'G21_1.8.C'
           WHEN ITEM_CD =  '113201' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_1.8.D'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_YEAR' THEN
            'G21_1.8.E'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_FIVE' THEN
            'G21_1.8.F'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'NEXT_TEN' THEN
            'G21_1.8.M'
           WHEN ITEM_CD =  '113201'  AND B.QX = 'MORE_TEN' THEN
            'G21_1.8.N'
           WHEN ITEM_CD =  '113201' AND B.QX = 'YQ' THEN
            'G21_1.8.H'
           WHEN  ITEM_CD = '2231' AND B.QX = 'NEXT_YS' THEN
            'G21_3.8.A'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_WEEK' THEN
            'G21_3.8.B'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_MONTH' THEN
            'G21_3.8.C'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_QUARTER' THEN
            'G21_3.8.D'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_YEAR' THEN
            'G21_3.8.E'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_FIVE' THEN
            'G21_3.8.F.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'NEXT_TEN' THEN
            'G21_3.8.G1.2018'
           WHEN ITEM_CD = '2231' AND B.QX = 'MORE_TEN' THEN
            'G21_3.8.H1.2018'
         END ITEM_NUM,
         SUM(MINUS_AMT) AS MINUS_AMT,
         NULL ITEM_VAL_V,
         '2' AS FLAG,
         'ALL' CURR_CD
          FROM PM_RSDATA.CBRC_ITEM_MINUS_AMT_TEMP B
         WHERE MINUS_AMT <> 0
         GROUP BY B.ORG_NUM, ITEM_CD,QX)
 GROUP BY ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL_V, FLAG, B_CURR_CD;

COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据G21的PM_RSDATA.CBRC_A_REPT_ITEM_VAL_NGI至1104目标表PM_RSDATA.CBRC_A_REPT_ITEM_VAL完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := V_PROCEDURE || '的业务逻辑全部处理完成';
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
    V_STEP_DESC := '发生异常。详细信息为,' || TO_CHAR(SQLCODE) ||
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
   
END proc_cbrc_idx2_g21