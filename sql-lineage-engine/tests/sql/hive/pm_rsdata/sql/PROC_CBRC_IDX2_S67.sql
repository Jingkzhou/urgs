CREATE OR REPLACE PROCEDURE pm_rsdata.PROC_CBRC_IDX2_S67(II_DATADATE IN STRING --跑批日期
                                               )
/******************************
  @AUTHOR:CHENGHUIMIN
  @CREATE-DATE:20210713
  @DESCRIPTION:S67
  @MODIFICATION HISTORY:
  M0.AUTHOR-CREATE_DATE-DESCRIPTION
  m1.alter by shiyu 20230908   4.其他以房地产为抵押的贷款  修改逻辑取押品为房地产的的贷款
  m2.alter by shiyu 20231109 4.其他以房地产为抵押的贷款  结清的贷款需要判断还款时的押品是不是有效的
  m3.alter by djh 20240103“1.2 房产开发贷款”项及其子项、“1.3 商业用房购房贷款”项及其子项在原取数逻辑中剔除经营性物业贷款分类码值为02、12的贷款
  02抵押类贷款(021用途-房地产开发、022用途-装修改造、023用途-购买房屋、024用途-偿还借款、025用途-流动资金、026用途-其他)12 用途-装修改造
  m4.alter by djh 20240115  3.个人住房贷款提前还款情况  3.1部分提前还款  3.2全额提前还款
  m5 add by djh 20240201 1.5 其他房地产贷款 、1.5.1、1.5.2 其中：房地产并购贷款  纵列 其中：当月核销  其中：当月新增展期金额  其中：当月新增逾期金额
  m6 add by zy 20240729   2.1 投向房地产领域的标准化债权类资产   2.1.1 自营资金投资类   2.1.2.1 其中：房地产企业债券
  m7 20241224 shiyu 修改内容：修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
                             如果是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款在逾期时间90天以内的取逾期部分，逾期90天以上的取贷款余额

  m8 需求编号：JLBA202505140011_关于1104报表系统金融市场部报表取数逻辑变更的需求 上线日期：2025-07-29 修改人：常金磊，提出人：康立军 修改内容：调整债券、存单关联减值表的关联条件，解决关联重复问题
  m9 需求编号：JLBA202508220003_关于吉林银行资本管理系统新增1104系统S67房开贷明细数据下发功能的需求 上线日期：2025-10-16 修改人：常金磊，提出人：周丽雯 修改内容：每月月初1日内下发上月末S67房开贷明细数据到财务集市(1.2贷款情况五级分类)
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_CONTRACT_NUM_TMP
        CBRC_GUARANTY_INFO_TMP
        CBRC_L_ACCT_LOAN_PAYM_SCHED_TMP
        CBRC_L_ACCT_LOAN_PAYM_SCHED_TMP1
        CBRC_S67_DATA_COLLECT_TMP
        CBRC_S67_DATA_COLLECT_TMP_LTV
集市表： SMTMODS_L_ACCT_FUND_INVEST
         SMTMODS_L_ACCT_LOAN
         SMTMODS_L_ACCT_LOAN_EXTENDTERM
         SMTMODS_L_ACCT_LOAN_PAYM_SCHED
         SMTMODS_L_ACCT_LOAN_REALESTATE
         SMTMODS_L_ACCT_WRITE_OFF
         SMTMODS_L_AGRE_BOND_INFO
         SMTMODS_L_AGRE_GUARANTEE_CONTRACT
         SMTMODS_L_AGRE_GUARANTEE_RELATION
         SMTMODS_L_AGRE_GUARANTY_INFO
         SMTMODS_L_AGRE_GUA_RELATION
         SMTMODS_L_CUST_ALL
         SMTMODS_L_CUST_C
         SMTMODS_L_CUST_EXTERNAL_INFO
         SMTMODS_L_CUST_P
         SMTMODS_L_FIMM_FIN_PENE
         SMTMODS_L_FIMM_PRODUCT
         SMTMODS_L_FINA_ASSET_DEVALUE
         SMTMODS_L_PUBL_RATE
         SMTMODS_L_TRAN_LOAN_PAYM

  *******************************/

 IS
  V_PROCEDURE VARCHAR(50); --当前储存过程名称
  V_TAB_NAME  VARCHAR(50); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  D_DATADATE_CCY  STRING; --数据日期(日期型)YYYYMMDD
  V_STEP_ID       INTEGER; --任务号
  V_STEP_DESC     VARCHAR(500); --任务描述
  V_STEP_FLAG     INTEGER; --任务执行状态标识
  V_DATADATE_M VARCHAR(6); --数据日期(字符型)YYYY-MM
  V_ERRORCODE  VARCHAR(50); --错误编码
  V_ERRORDESC  VARCHAR(280); --错误内容
  II_STATUS    INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_MONTH_DAYS  VARCHAR(6);
  V_SYSTEM      VARCHAR(50);
  
BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID       := 0;
    V_STEP_FLAG     := 0;
    V_STEP_DESC     := '参数初始化处理';
    I_DATADATE      := II_DATADATE;
    V_DATADATE_M    := SUBSTR(I_DATADATE, 1, 6);
    V_PROCEDURE     := UPPER('PROC_CBRC_IDX2_S67');
	V_SYSTEM        := 'CBRC';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_TAB_NAME := 'CBRC_A_REPT_DWD_S67';
    D_DATADATE_CCY := I_DATADATE;

    V_MONTH_DAYS := SUBSTR(TO_CHAR(LAST_DAY(DATE(I_DATADATE, 'YYYYMMDD')), 'YYYYMMDD'),
              LENGTH(TO_CHAR(LAST_DAY(DATE(I_DATADATE, 'YYYYMMDD')),
                             'YYYYMMDD')) - 1); --逾期天数在当月内

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']S67当期数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S67_DATA_COLLECT_TMP';
  --  EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_DWD_S67';

    DELETE FROM CBRC_A_REPT_ITEM_VAL T
     WHERE T.DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND T.REP_NUM = 'S67'
       AND T.FLAG = '2';
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    /*----  ------------------------------------------------------------本期期末余额---------------------------------------------*/

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据本期期末余额情况至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --ALTER BY WJB 20220624 新增本期期末余额按资本金比例指标
    --1.2.1--->1.2.2 按资本金比例
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') AND   T1.CAPITAL_RATE > 0.4 THEN 'S67_1.2.1.2.4.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') AND   T1.CAPITAL_RATE > 0.3 THEN 'S67_1.2.1.2.3.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') AND   T1.CAPITAL_RATE > 0.2 THEN 'S67_1.2.1.2.2.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') AND   T1.CAPITAL_RATE >= 0  THEN 'S67_1.2.1.2.1.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND T1.CAPITAL_RATE > 0.45 THEN 'S67_1.2.2.4.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND  T1.CAPITAL_RATE > 0.35 THEN 'S67_1.2.2.3.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND  T1.CAPITAL_RATE >= 0.25 THEN 'S67_1.2.2.2.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND  T1.CAPITAL_RATE >= 0 THEN 'S67_1.2.2.1.A.2021'
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
             ('111', '112', '113', '114')
         AND T2.CANCEL_FLG <>'Y'  --剔除核销数据
         AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) --alter by djh 20240103 02抵押类贷款12 用途-装修改造
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') AND   T1.CAPITAL_RATE > 0.4 THEN 'S67_1.2.1.2.4.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') AND   T1.CAPITAL_RATE > 0.3 THEN 'S67_1.2.1.2.3.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') AND   T1.CAPITAL_RATE > 0.2 THEN 'S67_1.2.1.2.2.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') AND   T1.CAPITAL_RATE >= 0  THEN 'S67_1.2.1.2.1.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND T1.CAPITAL_RATE > 0.45 THEN 'S67_1.2.2.4.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND  T1.CAPITAL_RATE > 0.35 THEN 'S67_1.2.2.3.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND  T1.CAPITAL_RATE >= 0.25 THEN 'S67_1.2.2.2.A.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND  T1.CAPITAL_RATE >= 0 THEN 'S67_1.2.2.1.A.2021'
       END;
    COMMIT;

    ---1.3.2 按贷款价值比

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_GUARANTY_INFO_TMP';

    INSERT INTO CBRC_GUARANTY_INFO_TMP
      (CONTRACT_NUM, COLL_MK_VAL)
      select  A.CONTRACT_NUM, SUM(NVL(C.COLL_MK_VAL, 0)) AS ASSESS_VALUE
        FROM SMTMODS_L_AGRE_GUA_RELATION A --业务合同与担保合同对应关系表
        LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_RELATION B --担保合同与担保信息对应关系表
          ON A.GUAR_CONTRACT_NUM = B.GUAR_CONTRACT_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_GUARANTY_INFO C --抵质押物详细信息
          ON B.GUARANTEE_SERIAL_NUM = C.GUARANTEE_SERIAL_NUM
         AND C.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND UPPER(C.COLL_STATUS) = 'Y' --取有效押品
       GROUP BY A.CONTRACT_NUM;
    COMMIT;

    --取贷款LTV

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_S67_DATA_COLLECT_TMP_LTV';

    INSERT INTO CBRC_S67_DATA_COLLECT_TMP_LTV
      (DATA_DATE, ORG_NUM, PROPERTYLOAN_TYP, LOAN_ACCT_BAL_RMB, LTV,OPERL_PROP_LOAN_CLS_CD)
      select  I_DATADATE AS DATA_DATE,
             ORG_NUM, --机构号
             PROPERTYLOAN_TYP, --房地产类型
             LOAN_ACCT_BAL_RMB, --贷款余额
             CASE
               WHEN NVL(COLL_MK_VAL, 0) != 0 THEN
                LOAN_ACCT_BAL_RMB / COLL_MK_VAL --贷款余额/评估物价值
               ELSE
                1 --评估价值为0的，默认LTV为1，放入个人住房贷款LTV > 0.8 ,商业用房购房贷款LTV > 0.5中
             END LTV, --贷款价值比
             OPERL_PROP_LOAN_CLS_CD --alter by djh 20240103 经营性物业贷款分类代码
        FROM ( ---取每笔合同的贷款余额之和、评估价值
              select  T2.ORG_NUM, --机构号
                      T2.ACCT_NUM, --合同号
                      T1.PROPERTYLOAN_TYP, --房地产类型
                      T3.COLL_MK_VAL * U.CCY_RATE AS COLL_MK_VAL, --评估物价值
                      SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB, --贷款余额
                      T1.OPERL_PROP_LOAN_CLS_CD --alter by djh 20240103 经营性物业贷款分类代码
                FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
               INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
                  ON T1.LOAN_NUM = T2.LOAN_NUM
                 AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
                 AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
                 AND T1.DATA_DATE = T2.DATA_DATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON T2.DATA_DATE = U.DATA_DATE
                 AND U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = T2.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
                LEFT JOIN CBRC_GUARANTY_INFO_TMP T3 --押品信息
                  ON T2.ACCT_NUM = T3.CONTRACT_NUM
               WHERE T1.DATA_DATE = I_DATADATE
                 AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
                 AND T2.CANCEL_FLG = 'N'
                 AND LENGTHB(T2.ACCT_NUM) < 36
                 AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                     ('2011',
                      '2021',
                      '2031',
                      '2032',
                      '2033',
                      '2034',
                      '2035',
                      '2036')
         AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
               GROUP BY T2.ORG_NUM,
                         T2.ACCT_NUM,
                         T1.PROPERTYLOAN_TYP,
                         T3.COLL_MK_VAL * U.CCY_RATE,
                         T1.OPERL_PROP_LOAN_CLS_CD);
    COMMIT;

    --商用贷款LTV
    INSERT INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             ORG_NUM,
             CASE
               WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                    ('2011', '2021', '2031') AND LTV > 0.5 THEN
                'S67_1.3.2.4.A.2021' --1.3.2.4 LTV﹥50%
               WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                    ('2011', '2021', '2031') AND LTV > 0.4 THEN
                'S67_1.3.2.3.A.2021' --1.3.2.3 40%＜LTV≤50%
               WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                    ('2011', '2021', '2031') AND LTV > 0.3 THEN
                'S67_1.3.2.2.A.2021' --1.3.2.2 30%＜LTV≤40%
               WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                    ('2011', '2021', '2031') AND LTV > 0 THEN
                'S67_1.3.2.1.A.2021' --1.3.2.1 LTV≤30%
               WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                    ('2011', '2021', '2031') AND LTV = 0 THEN
                'S67_1.3.2.5.A.2021' --1.3.2.5 非抵押方式
             END AS ITEM_NUM,
             SUM(LOAN_ACCT_BAL_RMB)
        FROM CBRC_S67_DATA_COLLECT_TMP_LTV
       WHERE SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021', '2031')
       AND (SUBSTR(OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR OPERL_PROP_LOAN_CLS_CD IS NULL) --alter by djh 20240103 02抵押类贷款12 用途-装修改造
       GROUP BY ORG_NUM,
                CASE
                  WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                       ('2011', '2021', '2031') AND LTV > 0.5 THEN
                   'S67_1.3.2.4.A.2021' --1.3.2.4 LTV﹥50%
                  WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                       ('2011', '2021', '2031') AND LTV > 0.4 THEN
                   'S67_1.3.2.3.A.2021' --1.3.2.3 40%＜LTV≤50%
                  WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                       ('2011', '2021', '2031') AND LTV > 0.3 THEN
                   'S67_1.3.2.2.A.2021' --1.3.2.2 30%＜LTV≤40%
                  WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                       ('2011', '2021', '2031') AND LTV > 0 THEN
                   'S67_1.3.2.1.A.2021' --1.3.2.1 LTV≤30%
                  WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                       ('2011', '2021', '2031') AND LTV = 0 THEN
                   'S67_1.3.2.5.A.2021' --1.3.2.5 非抵押方式
                END;
    COMMIT;

    ---个人住房贷款不含商铺
    INSERT INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             ORG_NUM,
             CASE
               WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND LTV > 0.8 THEN
                'S67_1.4.2.5.A.2021' --1.4.2.5 80%＜LTV
               WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND LTV > 0.7 THEN
                'S67_1.4.2.4.A.2021' --1.4.2.4 70%＜LTV≤80%
               WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND LTV > 0.6 THEN
                'S67_1.4.2.3.A.2021' --1.4.2.3 60%＜LTV≤70%
               WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND LTV > 0.5 THEN
                'S67_1.4.2.2.A.2021' --1.4.2.2 50%＜LTV≤60%
               WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND LTV > 0 THEN
                'S67_1.4.2.1.A.2021' --1.4.2.1 LTV≤50%
               WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND LTV = 0 THEN
                'S67_1.4.2.6.A.2021'
             END ITEM_NUM,
             SUM(LOAN_ACCT_BAL_RMB)
        FROM CBRC_S67_DATA_COLLECT_TMP_LTV
       WHERE SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036')
       GROUP BY ORG_NUM,
                CASE
                  WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       LTV > 0.8 THEN
                   'S67_1.4.2.5.A.2021'
                  WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       LTV > 0.7 THEN
                   'S67_1.4.2.4.A.2021'
                  WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       LTV > 0.6 THEN
                   'S67_1.4.2.3.A.2021' --1.4.2.3 60%＜LTV≤70%
                  WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       LTV > 0.5 THEN
                   'S67_1.4.2.2.A.2021' --1.4.2.2 50%＜LTV≤60%
                  WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND LTV > 0 THEN
                   'S67_1.4.2.1.A.2021' --1.4.2.1 LTV≤50%
                  WHEN SUBSTR(PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND LTV = 0 THEN
                   'S67_1.4.2.6.A.2021'
                END;
    COMMIT;

    --1.4.3 按是否新建  数与填报不一致？需要修改L_ACCT_LOAN_REALESTATE.PROPERTYLOAN_TYP?
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035') THEN
                'S67_1.4.3.1.A.2021'
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2036') THEN
                'S67_1.4.3.2.A.2021'
             END ITEM_NUM,
             SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE --月报
         AND T2.CANCEL_FLG = 'N'
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036')
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035') THEN
                   'S67_1.4.3.1.A.2021'
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2036') THEN
                   'S67_1.4.3.2.A.2021'
                END; --个人住房贷款

    COMMIT;

    --1.4.4 按贷款利率
    --1.4.4.1 固定利率贷款
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             'S67_1.4.4.1.A.2021',
             SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036') --个人住房贷款
         AND T2.INT_RATE_TYP = 'F' --固定利率
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;

    COMMIT;
    --1.4.4.2 基于贷款市场报价利率(LPR)
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN T2.RATE_FLOAT / 1 < 0 THEN
                'S67_1.4.4.2.1.A.2021'
               WHEN T2.RATE_FLOAT / 1 = 0 THEN
                'S67_1.4.4.2.2.A.2021'
               WHEN T2.RATE_FLOAT / 1 > 0 AND T2.RATE_FLOAT / 1 < 0.6 THEN
                'S67_1.4.4.2.3.A.2021'
               WHEN T2.RATE_FLOAT / 1 = 0.6 THEN
                'S67_1.4.4.2.4.A.2021'
               WHEN T2.RATE_FLOAT / 1 > 0.6 THEN
                'S67_1.4.4.2.5.A.2021'
             END AS ITEM_NUM,
             SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE --月报
         AND T2.CANCEL_FLG = 'N'
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036') --个人住房贷款
            /*AND T2.INDUST_TRAN_FLG = '3' */ --LPR(利率类型LPR) INDUST_TRAN_FLG CHAR(1) Y 工业转型升级标识 基准利率获取方式 区分 LPR 利率 和基准率 3 LPR 利率
            --2021年口径调整 原因业务吴大为
         AND T2.INT_RATE_TYP <> 'F' ---取浮动利率
            --AND T2.BENM_INRAT_TYPE = '30' --10:基础利率 30：LRP
         AND T2.FLOAT_TYPE = 'A' --LPR
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T2.RATE_FLOAT / 1 < 0 THEN
                   'S67_1.4.4.2.1.A.2021'
                  WHEN T2.RATE_FLOAT / 1 = 0 THEN
                   'S67_1.4.4.2.2.A.2021'
                  WHEN T2.RATE_FLOAT / 1 > 0 AND T2.RATE_FLOAT / 1 < 0.6 THEN
                   'S67_1.4.4.2.3.A.2021'
                  WHEN T2.RATE_FLOAT / 1 = 0.6 THEN
                   'S67_1.4.4.2.4.A.2021'
                  WHEN T2.RATE_FLOAT / 1 > 0.6 THEN
                   'S67_1.4.4.2.5.A.2021'
                END;
    COMMIT;
    ---1.4.4.3 其他 取数应为0

    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             'S67_1.4.4.3.A.2021' AS ITEM_NUM,
             SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE --月报
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036') --个人住房贷款
            /*AND T2.INDUST_TRAN_FLG <> '3' --扣掉LPR*/ --2021年口径调整 原因业务吴大为
         AND T2.INT_RATE_TYP <> 'F' --不取固定利率
         AND T2.INT_RATE_TYP NOT LIKE 'L%' --不取浮动
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;
    COMMIT;
    --1.4.5 按建筑面积
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN T1.AREA > 144 THEN
                'S67_1.4.5.3.A.2021'
               WHEN T1.AREA > 90 THEN
                'S67_1.4.5.2.A.2021'
               ELSE
                'S67_1.4.5.1.A.2021'
             END ITEM_NUM,
             SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE --月报
         AND T2.CANCEL_FLG = 'N'
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036') --个人住房贷款
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T1.AREA > 144 THEN
                   'S67_1.4.5.3.A.2021'
                  WHEN T1.AREA > 90 THEN
                   'S67_1.4.5.2.A.2021'
                  ELSE
                   'S67_1.4.5.1.A.2021'
                END;

    COMMIT;

    ---DSR   --(本次贷款的月还款额+月物业管理费)/家庭月均收入 码表A2 A0007

    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_L_ACCT_LOAN_PAYM_SCHED_TMP1';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_L_ACCT_LOAN_PAYM_SCHED_TMP';

    --贷款还款计划表预处理  TRUNCATE TABLE CBRC_L_ACCT_LOAN_PAYM_SCHED_TMP1
    --ALTER BY WJB 20220530 计算月还款额时如果存在提前还款，则需减去还款明细表中还款方式为提前还款的总金额
    INSERT  INTO CBRC_L_ACCT_LOAN_PAYM_SCHED_TMP1
      (LOAN_NUM, OS_PPL, INTEREST)
      SELECT 
       LALPS.LOAN_NUM,
       SUM(LALPS.OS_PPL /*OS_PPL_PAID*/) AS OS_PPL,
       SUM(LALPS.INTEREST /*INT_PAID*/) AS INTEREST
        FROM SMTMODS_L_ACCT_LOAN_PAYM_SCHED LALPS --贷款还款计划信息表
       INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE LALR --房地产贷款补充信息
          ON LALR.LOAN_NUM = LALPS.LOAN_NUM
         AND LALR.DATA_DATE = I_DATADATE
       WHERE (TO_CHAR(LALPS.DUE_DATE, 'YYYYMM') = V_DATADATE_M OR
             TO_CHAR(LALPS.DUE_DATE_INT, 'YYYYMM') = V_DATADATE_M)
         AND LALPS.DATA_DATE = I_DATADATE
       GROUP BY LALPS.LOAN_NUM;
    COMMIT;

    INSERT  INTO CBRC_L_ACCT_LOAN_PAYM_SCHED_TMP
      (LOAN_NUM, OS_PPL, INTEREST)
      SELECT 
       T.LOAN_NUM,
       NVL(T.OS_PPL, 0) - NVL(T1.PAY_AMT, 0) AS OS_PPL,
       NVL(T.INTEREST, 0) - NVL(T1.PAY_INT_AMT, 0) AS PAY_INT_AMT
        FROM CBRC_L_ACCT_LOAN_PAYM_SCHED_TMP1 T
        LEFT JOIN (SELECT AA.LOAN_NUM,
                          SUM(AA.PAY_AMT) AS PAY_AMT,
                          SUM(AA.PAY_INT_AMT) AS PAY_INT_AMT
                     FROM SMTMODS_L_TRAN_LOAN_PAYM AA
                    WHERE DATA_DATE = I_DATADATE
                      AND PAY_TYPE IN ('02', '03')
                    GROUP BY AA.LOAN_NUM) T1
          ON T.LOAN_NUM = T1.LOAN_NUM;

    COMMIT;

    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN C.INCOME > 0 THEN
                CASE
                  WHEN (NVL(T3.OS_PPL, 0) + NVL(T3.INTEREST, 0) + T1.PROPERTY) /  C.INCOME > 0.5 THEN 'S67_1.4.6.3.A.2021'
                  WHEN (NVL(T3.OS_PPL, 0) + NVL(T3.INTEREST, 0) + T1.PROPERTY) /  C.INCOME > 0.3 THEN 'S67_1.4.6.2.A.2021'
                  WHEN (NVL(T3.OS_PPL, 0) + NVL(T3.INTEREST, 0) + T1.PROPERTY) / C.INCOME >= 0 THEN 'S67_1.4.6.1.A.2021'
                END
               WHEN C.INCOME = 0 THEN
                'S67_1.4.6.3.A.2021'
             END ITEM_NUM,
             SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN CBRC_L_ACCT_LOAN_PAYM_SCHED_TMP T3 --贷款还款预处理计划表
          ON T1.LOAN_NUM = T3.LOAN_NUM
       INNER JOIN SMTMODS_L_CUST_ALL A
          ON A.CUST_ID = T2.CUST_ID
         AND A.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_CUST_P C
          ON A.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036') --个人住房贷款
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
               WHEN C.INCOME > 0 THEN
                CASE
                  WHEN (NVL(T3.OS_PPL, 0) + NVL(T3.INTEREST, 0) + T1.PROPERTY) /  C.INCOME > 0.5 THEN 'S67_1.4.6.3.A.2021'
                  WHEN (NVL(T3.OS_PPL, 0) + NVL(T3.INTEREST, 0) + T1.PROPERTY) /  C.INCOME > 0.3 THEN 'S67_1.4.6.2.A.2021'
                  WHEN (NVL(T3.OS_PPL, 0) + NVL(T3.INTEREST, 0) + T1.PROPERTY) / C.INCOME >= 0 THEN 'S67_1.4.6.1.A.2021'
                END
               WHEN C.INCOME = 0 THEN
                'S67_1.4.6.3.A.2021'
             END;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    --------------------------------------------当月新发放金额--------------------------------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据当月新发放金额情况至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') THEN
          'S67_1.1.C.2021' --地产开发贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
               T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
          'S67_1.2.1.C.2021' --住房开发贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
               T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
          'S67_1.2.2.C.2021' --商业用房开发贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
               T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
          'S67_1.2.3.C.2021' --其他房产开发贷款
       END ITEM_NUM,
       SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
             ('101', '102', '103', '111', '112', '113', '114', '119')
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                       ('101', '102', '103') THEN
                   'S67_1.1.C.2021' --地产开发贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                       ('111', '112', '113') AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                        ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
                   'S67_1.2.1.C.2021' --住房开发贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                        ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
                   'S67_1.2.2.C.2021' --商业用房开发贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                        ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
                   'S67_1.2.3.C.2021' --其他房产开发贷款
                END;
    COMMIT;

    ---1.3.1 按购买主体

    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') THEN --企业、机关
                'S67_1.3.1.1.C.2021' --1.3.1.1 企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') THEN
                'S67_1.3.1.2.C.2021' --1.3.1.2 个人购买商业用房贷款
             END ITEM_NUM,
             SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021', '2031')
         AND (SUBSTR(OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR OPERL_PROP_LOAN_CLS_CD IS NULL) --alter by djh 20240103 02抵押类贷款12 用途-装修改造
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') THEN
                   'S67_1.3.1.1.C.2021' --1.3.1.1 企业购买商业用房贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') THEN
                   'S67_1.3.1.2.C.2021' --1.3.1.2 个人购买商业用房贷款
                END;
    COMMIT;

    --1.4.1 按住房套数   OWN_HOUSE 是否是首套住房 0是1否。
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN T1.OWN_HOUSE = 1 THEN
                'S67_1.4.1.1.C.2021'
               WHEN T1.OWN_HOUSE = 2 THEN --modify by djh 20211227
                'S67_1.4.1.2.C.2021'
               WHEN T1.OWN_HOUSE = 3 THEN --modify by djh 20211227
                'S67_1.4.1.3.C.2021'
             END ITEM_NUM,
             SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036') --个人住房贷款
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T1.OWN_HOUSE = 1 THEN
                   'S67_1.4.1.1.C.2021'
                  WHEN T1.OWN_HOUSE = 2 THEN --modify by djh 20211227
                   'S67_1.4.1.2.C.2021'
                  WHEN T1.OWN_HOUSE = 3 THEN --modify by djh 20211227
                   'S67_1.4.1.3.C.2021'
                END;
    COMMIT;

    --1.4.3 按是否新建  数与填报不一致？
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035') THEN
                'S67_1.4.3.1.C.2021'
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2036') THEN
                'S67_1.4.3.2.C.2021'
             END ITEM_NUM,
             SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036')
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035') THEN
                   'S67_1.4.3.1.C.2021'
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2036') THEN
                   'S67_1.4.3.2.C.2021'
                END; --个人住房贷款
    COMMIT;

    --1.4.4 按贷款利率
    --1.4.4.1 固定利率贷款
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             'S67_1.4.4.1.C.2021',
             SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036') --个人住房贷款
         AND T2.INT_RATE_TYP = 'F' --固定利率
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;
   commit;

    --1.4.4.2 基于贷款市场报价利率(LPR)
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN T2.RATE_FLOAT / 1 < 0 THEN
                'S67_1.4.4.2.1.C.2021'
               WHEN T2.RATE_FLOAT / 1 = 0 THEN
                'S67_1.4.4.2.2.C.2021'
               WHEN T2.RATE_FLOAT / 1 > 0 AND T2.RATE_FLOAT / 1 < 0.6 THEN
                'S67_1.4.4.2.3.C.2021'
               WHEN T2.RATE_FLOAT / 1 = 0.6 THEN
                'S67_1.4.4.2.4.C.2021'
               WHEN T2.RATE_FLOAT / 1 > 0.6 THEN
                'S67_1.4.4.2.5.C.2021'
             END AS ITEM_NUM,
             SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036') --个人住房贷款
         AND T2.INT_RATE_TYP <> 'F'
         AND T2.FLOAT_TYPE = 'A' --LPR
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T2.RATE_FLOAT / 1 < 0 THEN
                   'S67_1.4.4.2.1.C.2021'
                  WHEN T2.RATE_FLOAT / 1 = 0 THEN
                   'S67_1.4.4.2.2.C.2021'
                  WHEN T2.RATE_FLOAT / 1 > 0 AND T2.RATE_FLOAT / 1 < 0.6 THEN
                   'S67_1.4.4.2.3.C.2021'
                  WHEN T2.RATE_FLOAT / 1 = 0.6 THEN
                   'S67_1.4.4.2.4.C.2021'
                  WHEN T2.RATE_FLOAT / 1 > 0.6 THEN
                   'S67_1.4.4.2.5.C.2021'
                END;
commit;
    ---1.4.4.3 其他

    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             'S67_1.4.4.3.C.2021' AS ITEM_NUM,
             SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036') --个人住房贷款
            /*AND T2.INDUST_TRAN_FLG <> '3' --扣掉LPR*/
         AND T2.INT_RATE_TYP <> 'F' --不取固定利率
         AND T2.INT_RATE_TYP NOT LIKE 'L%' --不取浮动
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    COMMIT;

    ------------------------------------当月收回金额------------------------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据当月收回金额情况至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -- 1.1 地产开发贷款  1.2.1 住房开发贷款
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') THEN --地产开发贷款
                'S67_1.1.D.2021'
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113')  --住房开发贷款
               AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.D.2021'
             END ITEM_NUM,
             --SUM(T2.PAY_AMT + T2.PAY_INT_AMT) AS PAY_AMT --本金金额
             SUM(T2.PAY_AMT) AS PAY_AMT --本金金额 --alter by wjb 20220531 松原业务提出收回金额不算利息
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1 --房地产贷款补充信息
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM T2 --贷款还款明细信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
       WHERE T1.DATA_DATE = I_DATADATE
         AND SUBSTR(TO_CHAR(T2.REPAY_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND T2.DATA_DATE = TO_CHAR(REPAY_DT, 'YYYYMMDD')
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
             ('101', '102', '103', '111', '112', '113')
       GROUP BY T2.ORG_NUM,
                CASE
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') THEN --地产开发贷款
                'S67_1.1.D.2021'
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113')  --住房开发贷款
               AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.D.2021'
             END;
    COMMIT;

    --1.2.2 商业用房开发贷款 --1.2.3 其他房产开发贷款
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') THEN --商业用房开发贷款
                'S67_1.2.2.D.2021'
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') THEN --其他房产开发贷款
                'S67_1.2.3.D.2021'
             END ITEM_NUM,
             --SUM(T2.PAY_AMT + T2.PAY_INT_AMT) AS PAY_AMT --本金金额
             SUM(T2.PAY_AMT) AS PAY_AMT --本金金额 --alter by wjb 20220531 松原业务提出收回金额不算利息
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM T2 --贷款还款明细信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
      --AND T2.DATA_DATE = I_DATADATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND SUBSTR(TO_CHAR(T2.REPAY_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND T2.DATA_DATE = TO_CHAR(REPAY_DT, 'YYYYMMDD')
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114', '119')
         AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)   --alter by djh 20240103 02抵押类贷款12 用途-装修改造
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') THEN
                   'S67_1.2.2.D.2021'
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') THEN
                   'S67_1.2.3.D.2021'
                END;
    COMMIT;

    --1.3.1 按购买主体
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') THEN /*企业、机关*/  'S67_1.3.1.1.D.2021' --1.3.1.1 企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') THEN  'S67_1.3.1.2.D.2021' --1.3.1.2 个人购买商业用房贷款
             END ITEM_NUM,
             SUM(T2.PAY_AMT ) AS PAY_AMT --本金金额 --alter by wjb 20220531 松原业务人员提出不算利息
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
      --AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.DATA_DATE = TO_CHAR(REPAY_DT, 'YYYYMMDD')
         AND SUBSTR(TO_CHAR(T2.REPAY_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021', '2031')
         AND (SUBSTR(OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR OPERL_PROP_LOAN_CLS_CD IS NULL) --alter by djh 20240103 02抵押类贷款12 用途-装修改造
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') THEN 'S67_1.3.1.1.D.2021' --1.3.1.1 企业购买商业用房贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') THEN  'S67_1.3.1.2.D.2021' --1.3.1.2 个人购买商业用房贷款
                END;
    COMMIT;

    ---个人住房贷款

    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             'S67_1.4.D.2021' AS ITEM_NUM,
             --SUM(T2.PAY_AMT + T2.PAY_INT_AMT) AS PAY_AMT --本金金额 --MDF BY CHM 20210922
             SUM(T2.PAY_AMT) AS PAY_AMT --本金金额 --alter by wjb 20220531 松原业务提出收回金额不算利息
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
      --AND T1.DATA_DATE = T2.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.DATA_DATE = TO_CHAR(REPAY_DT, 'YYYYMMDD')
         AND SUBSTR(TO_CHAR(T2.REPAY_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036') --个人住房贷款
       GROUP BY T2.ORG_NUM;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    COMMIT;

    ---------------------------------------------贷款情况五级分类---------------------------------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据当月收回金额情况至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') AND T2.LOAN_GRADE_CD = '1' THEN
                'S67_1.1.F.2021' --地产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113') AND T2.LOAN_GRADE_CD = '1'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.F.2021' --住房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                    T2.LOAN_GRADE_CD = '1'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.2.F.2021' --商业用房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                    T2.LOAN_GRADE_CD = '1'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.3.F.2021' --其他房产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') AND --企业、机关
                    T2.LOAN_GRADE_CD = '1'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.1.F.2021' --企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                    T2.LOAN_GRADE_CD = '1'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.2.F.2021' --个人购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 1 AND T2.LOAN_GRADE_CD = '1' THEN
                'S67_1.4.1.1.F.2021' --1.4.1.1 第一套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 2 AND T2.LOAN_GRADE_CD = '1' THEN --MODIFY BY DJH 二套房 20211227
                'S67_1.4.1.2.F.2021' --1.4.1.2 第二套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 3 AND T2.LOAN_GRADE_CD = '1' THEN --MODIFY BY DJH  三套房及以上 20211227
                'S67_1.4.1.3.F.2021' -- 1.4.1.3 第三套房及以上
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') AND T2.LOAN_GRADE_CD = '2' THEN
                'S67_1.1.G.2021' --地产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113') AND T2.LOAN_GRADE_CD = '2'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.G.2021' --住房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                    T2.LOAN_GRADE_CD = '2'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.2.G.2021' --商业用房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                    T2.LOAN_GRADE_CD = '2'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.3.G.2021' --其他房产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') AND --企业、机关
                    T2.LOAN_GRADE_CD = '2'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.1.G.2021' --企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                    T2.LOAN_GRADE_CD = '2'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.2.G.2021' --个人购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 1 AND T2.LOAN_GRADE_CD = '2' THEN
                'S67_1.4.1.1.G.2021' --1.4.1.1 第一套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 2 AND T2.LOAN_GRADE_CD = '2' THEN --MODIFY BY DJH 二套房 20211227
                'S67_1.4.1.2.G.2021' --1.4.1.2 第二套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 3 AND T2.LOAN_GRADE_CD = '2' THEN --MODIFY BY DJH  三套房及以上 20211227
                'S67_1.4.1.3.G.2021' -- 1.4.1.3 第三套房及以上
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') AND T2.LOAN_GRADE_CD = '3' THEN
                'S67_1.1.I.2021' --地产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113') AND T2.LOAN_GRADE_CD = '3'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.I.2021' --住房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                    T2.LOAN_GRADE_CD = '3'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.2.I.2021' --商业用房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                    T2.LOAN_GRADE_CD = '3'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.3.I.2021' --其他房产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') AND --企业、机关
                    T2.LOAN_GRADE_CD = '3'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.1.I.2021' --企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                    T2.LOAN_GRADE_CD = '3'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.2.I.2021' --个人购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 1 AND T2.LOAN_GRADE_CD = '3' THEN
                'S67_1.4.1.1.I.2021' --1.4.1.1 第一套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 2 AND T2.LOAN_GRADE_CD = '3' THEN
                'S67_1.4.1.2.I.2021' --1.4.1.2 第二套房  --MODIFY BY DJH 二套房 20211227
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 3 AND T2.LOAN_GRADE_CD = '3' THEN --MODIFY BY DJH  三套房及以上 20211227
                'S67_1.4.1.3.I.2021' -- 1.4.1.3 第三套房及以上
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') AND T2.LOAN_GRADE_CD = '4' THEN
                'S67_1.1.J.2021' --地产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113') AND T2.LOAN_GRADE_CD = '4'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.J.2021' --住房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                    T2.LOAN_GRADE_CD = '4'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.2.J.2021' --商业用房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                    T2.LOAN_GRADE_CD = '4'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.3.J.2021' --其他房产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') AND --企业、机关
                    T2.LOAN_GRADE_CD = '4'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.1.J.2021' --企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                    T2.LOAN_GRADE_CD = '4'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.2.J.2021' --个人购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 1 AND T2.LOAN_GRADE_CD = '4' THEN
                'S67_1.4.1.1.J.2021' --1.4.1.1 第一套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 2 AND T2.LOAN_GRADE_CD = '4' THEN
                'S67_1.4.1.2.J.2021' --1.4.1.2 第二套房  --MODIFY BY DJH 二套房 20211227
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 3 AND T2.LOAN_GRADE_CD = '4' THEN --MODIFY BY DJH  三套房及以上 20211227
                'S67_1.4.1.3.J.2021' -- 1.4.1.3 第三套房及以上
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') AND T2.LOAN_GRADE_CD = '5' THEN
                'S67_1.1.K.2021' --地产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113') AND T2.LOAN_GRADE_CD = '5'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.K.2021' --住房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                    T2.LOAN_GRADE_CD = '5'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.2.K.2021' --商业用房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                    T2.LOAN_GRADE_CD = '5'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.3.K.2021' --其他房产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') AND --企业、机关
                    T2.LOAN_GRADE_CD = '5'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.1.K.2021' --企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                    T2.LOAN_GRADE_CD = '5'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.2.K.2021' --人购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 1 AND T2.LOAN_GRADE_CD = '5' THEN
                'S67_1.4.1.1.K.2021' --1.4.1.1 第一套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 2 AND T2.LOAN_GRADE_CD = '5' THEN
                'S67_1.4.1.2.K.2021' --1.4.1.2 第二套房  --MODIFY BY DJH 二套房 20211227
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 3 AND T2.LOAN_GRADE_CD = '5' THEN --MODIFY BY DJH  三套房及以上 20211227
                'S67_1.4.1.3.K.2021' -- 1.4.1.3 第三套房及以上
             END ITEM_NUM,
             SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
             ('101', '102', '103', '111', '112', '113', '114', '119') OR
             SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2011',
               '2021',
               '2031',
               '2032',
               '2033',
               '2034',
               '2035',
               '2036'))
       AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') AND T2.LOAN_GRADE_CD = '1' THEN
                'S67_1.1.F.2021' --地产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113') AND T2.LOAN_GRADE_CD = '1'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.F.2021' --住房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                    T2.LOAN_GRADE_CD = '1'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.2.F.2021' --商业用房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                    T2.LOAN_GRADE_CD = '1'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.3.F.2021' --其他房产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') AND --企业、机关
                    T2.LOAN_GRADE_CD = '1'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.1.F.2021' --企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                    T2.LOAN_GRADE_CD = '1'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.2.F.2021' --个人购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 1 AND T2.LOAN_GRADE_CD = '1' THEN
                'S67_1.4.1.1.F.2021' --1.4.1.1 第一套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 2 AND T2.LOAN_GRADE_CD = '1' THEN --MODIFY BY DJH 二套房 20211227
                'S67_1.4.1.2.F.2021' --1.4.1.2 第二套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 3 AND T2.LOAN_GRADE_CD = '1' THEN --MODIFY BY DJH  三套房及以上 20211227
                'S67_1.4.1.3.F.2021' -- 1.4.1.3 第三套房及以上
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') AND T2.LOAN_GRADE_CD = '2' THEN
                'S67_1.1.G.2021' --地产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113') AND T2.LOAN_GRADE_CD = '2'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.G.2021' --住房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                    T2.LOAN_GRADE_CD = '2'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.2.G.2021' --商业用房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                    T2.LOAN_GRADE_CD = '2'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.3.G.2021' --其他房产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') AND --企业、机关
                    T2.LOAN_GRADE_CD = '2'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.1.G.2021' --企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                    T2.LOAN_GRADE_CD = '2'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.2.G.2021' --个人购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 1 AND T2.LOAN_GRADE_CD = '2' THEN
                'S67_1.4.1.1.G.2021' --1.4.1.1 第一套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 2 AND T2.LOAN_GRADE_CD = '2' THEN --MODIFY BY DJH 二套房 20211227
                'S67_1.4.1.2.G.2021' --1.4.1.2 第二套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 3 AND T2.LOAN_GRADE_CD = '2' THEN --MODIFY BY DJH  三套房及以上 20211227
                'S67_1.4.1.3.G.2021' -- 1.4.1.3 第三套房及以上
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') AND T2.LOAN_GRADE_CD = '3' THEN
                'S67_1.1.I.2021' --地产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113') AND T2.LOAN_GRADE_CD = '3'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.I.2021' --住房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                    T2.LOAN_GRADE_CD = '3'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.2.I.2021' --商业用房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                    T2.LOAN_GRADE_CD = '3'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.3.I.2021' --其他房产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') AND --企业、机关
                    T2.LOAN_GRADE_CD = '3'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.1.I.2021' --企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                    T2.LOAN_GRADE_CD = '3'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.2.I.2021' --个人购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 1 AND T2.LOAN_GRADE_CD = '3' THEN
                'S67_1.4.1.1.I.2021' --1.4.1.1 第一套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 2 AND T2.LOAN_GRADE_CD = '3' THEN
                'S67_1.4.1.2.I.2021' --1.4.1.2 第二套房  --MODIFY BY DJH 二套房 20211227
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 3 AND T2.LOAN_GRADE_CD = '3' THEN --MODIFY BY DJH  三套房及以上 20211227
                'S67_1.4.1.3.I.2021' -- 1.4.1.3 第三套房及以上
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') AND T2.LOAN_GRADE_CD = '4' THEN
                'S67_1.1.J.2021' --地产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113') AND T2.LOAN_GRADE_CD = '4'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.J.2021' --住房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                    T2.LOAN_GRADE_CD = '4'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.2.J.2021' --商业用房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                    T2.LOAN_GRADE_CD = '4'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.3.J.2021' --其他房产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') AND --企业、机关
                    T2.LOAN_GRADE_CD = '4'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.1.J.2021' --企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                    T2.LOAN_GRADE_CD = '4'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.2.J.2021' --个人购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 1 AND T2.LOAN_GRADE_CD = '4' THEN
                'S67_1.4.1.1.J.2021' --1.4.1.1 第一套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 2 AND T2.LOAN_GRADE_CD = '4' THEN
                'S67_1.4.1.2.J.2021' --1.4.1.2 第二套房  --MODIFY BY DJH 二套房 20211227
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 3 AND T2.LOAN_GRADE_CD = '4' THEN --MODIFY BY DJH  三套房及以上 20211227
                'S67_1.4.1.3.J.2021' -- 1.4.1.3 第三套房及以上
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') AND T2.LOAN_GRADE_CD = '5' THEN
                'S67_1.1.K.2021' --地产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113') AND T2.LOAN_GRADE_CD = '5'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.K.2021' --住房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                    T2.LOAN_GRADE_CD = '5'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.2.K.2021' --商业用房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                    T2.LOAN_GRADE_CD = '5'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.3.K.2021' --其他房产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') AND --企业、机关
                    T2.LOAN_GRADE_CD = '5'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.1.K.2021' --企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                    T2.LOAN_GRADE_CD = '5'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.2.K.2021' --人购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 1 AND T2.LOAN_GRADE_CD = '5' THEN
                'S67_1.4.1.1.K.2021' --1.4.1.1 第一套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 2 AND T2.LOAN_GRADE_CD = '5' THEN
                'S67_1.4.1.2.K.2021' --1.4.1.2 第二套房  --MODIFY BY DJH 二套房 20211227
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    OWN_HOUSE = 3 AND T2.LOAN_GRADE_CD = '5' THEN --MODIFY BY DJH  三套房及以上 20211227
                'S67_1.4.1.3.K.2021' -- 1.4.1.3 第三套房及以上
             END;

    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    COMMIT;

    ---------------------------------展期---------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据展期情况至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') THEN
                'S67_1.1.L.2021' --地产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113')
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.L.2021' --住房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114')
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.2.L.2021' --商业用房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119')
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.3.L.2021' --其他房产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') --企业、机关
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.1.L.2021' --企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031')
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.2.L.2021' --个人购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 1 THEN
                'S67_1.4.1.1.L.2021' --个人住房贷款第一套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    (T1.OWN_HOUSE = '2') THEN
                'S67_1.4.1.2.L.2021' --个人住房贷款第二套房
             END ITEM_NUM,
             SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
             ('101', '102', '103', '111', '112', '113', '114', '119') OR
             SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2011',
               '2021',
               '2031',
               '2032',
               '2033',
               '2034',
               '2035',
               '2036'))
         AND EXTENDTERM_FLG = 'Y' --展期
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('101', '102', '103') THEN
                'S67_1.1.L.2021' --地产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                    ('111', '112', '113')
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.L.2021' --住房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114')
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.2.L.2021' --商业用房开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119')
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.3.L.2021' --其他房产开发贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') --企业、机关
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.1.L.2021' --企业购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031')
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.3.1.2.L.2021' --个人购买商业用房贷款
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    T1.OWN_HOUSE = 1 THEN
                'S67_1.4.1.1.L.2021' --个人住房贷款第一套房
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                    ('2032', '2033', '2034', '2035', '2036') AND
                    (T1.OWN_HOUSE = '2') THEN
                'S67_1.4.1.2.L.2021' --个人住房贷款第二套房
             END;
    COMMIT;

    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    COMMIT;

    ---------------------------------------------逾期---------------------------------------------
    ---只考虑贷款余额，不考虑利息 只要发生欠本欠息就计入逾期
    --填报说明：不含已展期未到期贷款 是指刨除做了展期后本金未到期且无欠息的部分
    --住房对公的部分全取贷款余额
    --个人住房逾期90天内取逾期金额，90天以上取贷款余额

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据逾期情况至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
      ---1.房地产贷款合计
      --1.1 地产开发贷款
      --1.2 房产开发贷款
      INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
        (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
        select  I_DATADATE,
               T2.ORG_NUM,
               CASE
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('101', '102', '103') AND T2.OD_DAYS > 360 THEN
                  'S67_1.1.S.2021' --地产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('111', '112', '113') AND T2.OD_DAYS > 360
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.1.S.2021' --住房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                      T2.OD_DAYS > 360
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.2.S.2021' --商业用房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                      T2.OD_DAYS > 360
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.3.S.2021' --其他房产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('101', '102', '103') AND T2.OD_DAYS > 180 THEN
                  'S67_1.1.R.2021' --地产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('111', '112', '113') AND T2.OD_DAYS > 180
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.1.R.2021' --住房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                      T2.OD_DAYS > 180
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.2.R.2021' --商业用房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                      T2.OD_DAYS > 180
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.3.R.2021' --其他房产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('101', '102', '103') AND T2.OD_DAYS > 90 THEN
                  'S67_1.1.Q.2021' --地产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('111', '112', '113') AND T2.OD_DAYS > 90
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.1.Q.2021' --住房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                      T2.OD_DAYS > 90
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.2.Q.2021' --商业用房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                      T2.OD_DAYS > 90
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.3.Q.2021' --其他房产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('101', '102', '103') AND T2.OD_DAYS > 60 THEN
                  'S67_1.1.P.2021' --地产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('111', '112', '113') AND T2.OD_DAYS > 60
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.1.P.2021' --住房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                      T2.OD_DAYS > 60
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.2.P.2021' --商业用房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                      T2.OD_DAYS > 60
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.3.P.2021' --其他房产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('101', '102', '103') AND T2.OD_DAYS > 30 THEN
                  'S67_1.1.O.2021' --地产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('111', '112', '113') AND T2.OD_DAYS > 30
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.1.O.2021' --住房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                      T2.OD_DAYS > 30
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.2.O.2021' --商业用房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                      T2.OD_DAYS > 30
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.3.O.2021' --其他房产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('101', '102', '103') AND T2.OD_DAYS > 0 THEN
                  'S67_1.1.N.2021' --地产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('111', '112', '113') AND T2.OD_DAYS > 0
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.1.N.2021' --住房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                      T2.OD_DAYS > 0
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.2.N.2021' --商业用房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                      T2.OD_DAYS > 0
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.3.N.2021' --其他房产开发贷款
               END ITEM_NUM,
               SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
          FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
         INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
            ON T1.LOAN_NUM = T2.LOAN_NUM
           AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
           AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
           AND T1.DATA_DATE = T2.DATA_DATE
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON T2.DATA_DATE = U.DATA_DATE
           AND U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = T2.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE T1.DATA_DATE = I_DATADATE
           AND T2.CANCEL_FLG = 'N'
           AND LENGTHB(T2.ACCT_NUM) < 36
           AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
           AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
               ('101', '102', '103', '111', '112', '113', '114', '119')
           AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
       AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         GROUP BY T2.ORG_NUM,
               CASE
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('101', '102', '103') AND T2.OD_DAYS > 360 THEN
                  'S67_1.1.S.2021' --地产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('111', '112', '113') AND T2.OD_DAYS > 360
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.1.S.2021' --住房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                      T2.OD_DAYS > 360
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.2.S.2021' --商业用房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                      T2.OD_DAYS > 360
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.3.S.2021' --其他房产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('101', '102', '103') AND T2.OD_DAYS > 180 THEN
                  'S67_1.1.R.2021' --地产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('111', '112', '113') AND T2.OD_DAYS > 180
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.1.R.2021' --住房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                      T2.OD_DAYS > 180
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.2.R.2021' --商业用房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                      T2.OD_DAYS > 180
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.3.R.2021' --其他房产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('101', '102', '103') AND T2.OD_DAYS > 90 THEN
                  'S67_1.1.Q.2021' --地产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('111', '112', '113') AND T2.OD_DAYS > 90
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.1.Q.2021' --住房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                      T2.OD_DAYS > 90
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.2.Q.2021' --商业用房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                      T2.OD_DAYS > 90
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.3.Q.2021' --其他房产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('101', '102', '103') AND T2.OD_DAYS > 60 THEN
                  'S67_1.1.P.2021' --地产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('111', '112', '113') AND T2.OD_DAYS > 60
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.1.P.2021' --住房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                      T2.OD_DAYS > 60
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.2.P.2021' --商业用房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                      T2.OD_DAYS > 60
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.3.P.2021' --其他房产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('101', '102', '103') AND T2.OD_DAYS > 30 THEN
                  'S67_1.1.O.2021' --地产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('111', '112', '113') AND T2.OD_DAYS > 30
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.1.O.2021' --住房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                      T2.OD_DAYS > 30
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.2.O.2021' --商业用房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                      T2.OD_DAYS > 30
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.3.O.2021' --其他房产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('101', '102', '103') AND T2.OD_DAYS > 0 THEN
                  'S67_1.1.N.2021' --地产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('111', '112', '113') AND T2.OD_DAYS > 0
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.1.N.2021' --住房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                      T2.OD_DAYS > 0
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.2.N.2021' --商业用房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                      T2.OD_DAYS > 0
                     AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                  'S67_1.2.3.N.2021' --其他房产开发贷款
               END;

      COMMIT;

    ---1.3.1 按购买主体   1.4.1 按住房套数

    --1.3.1.2 个人购买商业用房贷款\1.4 个人住房贷款
    --逾期90天以内的，按照已逾期部分的本金的余额填报；逾期90天及以上的，按照整笔贷款本金的余额填报

    --逾期大于90天取贷款余额
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
              T2.OD_DAYS > 360 AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
               T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
          'S67_1.3.1.2.S.2021' --个人购买商业用房贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND T2.OD_DAYS > 360 AND
              T1.OWN_HOUSE = 1 THEN
          'S67_1.4.1.1.S.2021' --1.4.1.1 第一套房
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND T2.OD_DAYS > 360 AND
              T1.OWN_HOUSE = 2 THEN
          'S67_1.4.1.2.S.2021' --1.4.1.2 第二套房   --MODIFY BY DJH 二套房 20211227
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND T2.OD_DAYS > 360 AND
              T1.OWN_HOUSE = 3 THEN
          'S67_1.4.1.3.S.2021' --1.4.1.3 第三套房及以上  --MODIFY BY DJH 三套房及以上 20211227
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
              T2.OD_DAYS > 180 AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
               T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
          'S67_1.3.1.2.R.2021' --个人购买商业用房贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND T2.OD_DAYS > 180 AND
              T1.OWN_HOUSE = 1 THEN
          'S67_1.4.1.1.R.2021' --1.4.1.1 第一套房
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND T2.OD_DAYS > 180 AND
              T1.OWN_HOUSE = 2 THEN
          'S67_1.4.1.2.R.2021' --1.4.1.2 第二套房 --MODIFY BY DJH 二套房 20211227
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND T2.OD_DAYS > 180 AND
              T1.OWN_HOUSE = 3 THEN
          'S67_1.4.1.3.R.2021' --1.4.1.3 第三套房及以上  --MODIFY BY DJH 三套房及以上 20211227
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
              T2.OD_DAYS > 90 AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
               T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
          'S67_1.3.1.2.Q.2021' --个人购买商业用房贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND T2.OD_DAYS > 90 AND
              T1.OWN_HOUSE = 1 THEN
          'S67_1.4.1.1.Q.2021' --1.4.1.1 第一套房
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND T2.OD_DAYS > 90 AND
              T1.OWN_HOUSE = 2 THEN
          'S67_1.4.1.2.Q.2021' --1.4.1.2 第二套房 --MODIFY BY DJH 二套房 20211227
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND T2.OD_DAYS > 90 AND
              T1.OWN_HOUSE = 3 THEN
          'S67_1.4.1.3.Q.2021' --1.4.1.3 第三套房及以上  --MODIFY BY DJH 三套房及以上 20211227
       END ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2031', '2032', '2033', '2034', '2035', '2036')
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
         AND T2.OD_DAYS > 90
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                       T2.OD_DAYS > 360 AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                        ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                   'S67_1.3.1.2.S.2021' --个人购买商业用房贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       T2.OD_DAYS > 360 AND T1.OWN_HOUSE = 1 THEN
                   'S67_1.4.1.1.S.2021' --1.4.1.1 第一套房
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       T2.OD_DAYS > 360 AND T1.OWN_HOUSE = 2 THEN
                   'S67_1.4.1.2.S.2021' --1.4.1.2 第二套房   --MODIFY BY DJH 二套房 20211227
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       T2.OD_DAYS > 360 AND T1.OWN_HOUSE = 3 THEN
                   'S67_1.4.1.3.S.2021' --1.4.1.3 第三套房及以上  --MODIFY BY DJH 三套房及以上 20211227
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                       T2.OD_DAYS > 180 AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                        ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                   'S67_1.3.1.2.R.2021' --个人购买商业用房贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       T2.OD_DAYS > 180 AND T1.OWN_HOUSE = 1 THEN
                   'S67_1.4.1.1.R.2021' --1.4.1.1 第一套房
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       T2.OD_DAYS > 180 AND T1.OWN_HOUSE = 2 THEN
                   'S67_1.4.1.2.R.2021' --1.4.1.2 第二套房 --MODIFY BY DJH 二套房 20211227
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       T2.OD_DAYS > 180 AND T1.OWN_HOUSE = 3 THEN
                   'S67_1.4.1.3.R.2021' --1.4.1.3 第三套房及以上  --MODIFY BY DJH 三套房及以上 20211227
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                       T2.OD_DAYS > 90 AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                        ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                   'S67_1.3.1.2.Q.2021' --个人购买商业用房贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       T2.OD_DAYS > 90 AND T1.OWN_HOUSE = 1 THEN
                   'S67_1.4.1.1.Q.2021' --1.4.1.1 第一套房
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       T2.OD_DAYS > 90 AND T1.OWN_HOUSE = 2 THEN
                   'S67_1.4.1.2.Q.2021' --1.4.1.2 第二套房 --MODIFY BY DJH 二套房 20211227
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       T2.OD_DAYS > 90 AND T1.OWN_HOUSE = 3 THEN
                   'S67_1.4.1.3.Q.2021' --1.4.1.3 第三套房及以上  --MODIFY BY DJH 三套房及以上 20211227
                END;

    COMMIT;

   --逾期90天以内取逾期金额
        INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
              (T2.OD_DAYS > 60 and T2.OD_DAYS <= 90) AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
               T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
          'S67_1.3.1.2.P.2021' --个人购买商业用房贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND
              (T2.OD_DAYS > 60 and T2.OD_DAYS <= 90) AND T1.OWN_HOUSE = 1 THEN
          'S67_1.4.1.1.P.2021' --1.4.1.1 第一套房
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND
              (T2.OD_DAYS > 60 and T2.OD_DAYS <= 90) AND T1.OWN_HOUSE = 2 THEN
          'S67_1.4.1.2.P.2021' --1.4.1.2 第二套房 --MODIFY BY DJH 二套房 20211227
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND
              (T2.OD_DAYS > 60 and T2.OD_DAYS <= 90) AND T1.OWN_HOUSE = 3 THEN
          'S67_1.4.1.3.P.2021' --1.4.1.3 第三套房及以上  --MODIFY BY DJH 三套房及以上 20211227
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
              (T2.OD_DAYS > 30 AND T2.OD_DAYS <= 60) AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
               T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
          'S67_1.3.1.2.O.2021' --个人购买商业用房贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND
              (T2.OD_DAYS > 30 AND T2.OD_DAYS <= 60) AND T1.OWN_HOUSE = 1 THEN
          'S67_1.4.1.1.O.2021' --1.4.1.1 第一套房
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND
              (T2.OD_DAYS > 30 AND T2.OD_DAYS <= 60) AND T1.OWN_HOUSE = 2 THEN
          'S67_1.4.1.2.O.2021' --1.4.1.2 第二套房 --MODIFY BY DJH 二套房 20211227
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND
              (T2.OD_DAYS > 30 AND T2.OD_DAYS <= 60) AND T1.OWN_HOUSE = 3 THEN
          'S67_1.4.1.3.O.2021' --1.4.1.3 第三套房及以上  --MODIFY BY DJH 三套房及以上 20211227
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
              (T2.OD_DAYS > 0 AND T2.OD_DAYS <= 30) AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
               T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
          'S67_1.3.1.2.N.2021' --个人购买商业用房贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND
              (T2.OD_DAYS > 0 AND T2.OD_DAYS <= 30) AND T1.OWN_HOUSE = 1 THEN
          'S67_1.4.1.1.N.2021' --1.4.1.1 第一套房
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND
              (T2.OD_DAYS > 0 AND T2.OD_DAYS <= 30) AND T1.OWN_HOUSE = 2 THEN
          'S67_1.4.1.2.N.2021' --1.4.1.2 第二套房 --MODIFY BY DJH 二套房 20211227
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
              ('2032', '2033', '2034', '2035', '2036') AND
              (T2.OD_DAYS > 0 AND T2.OD_DAYS <= 30) AND T1.OWN_HOUSE = 3 THEN
          'S67_1.4.1.3.N.2021' --1.4.1.3 第三套房及以上  --MODIFY BY DJH 三套房及以上 20211227
       END ITEM_NUM,
       --SUM(T2.OD_LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB

       /*alter by shiyu 20241105 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
            如果是按月分期还款的个人消费贷款本金或利息逾期 */
       sum(case when (t2.ACCT_TYP LIKE '0101%' OR t2.ACCT_TYP LIKE '0103%' OR
             t2.ACCT_TYP LIKE '0104%' OR t2.ACCT_TYP LIKE '0199%'
            ) and  t2.REPAY_TYP ='1'   --按月支付
        and  T2.PAY_TYPE in   ('01','02','10','11') --JLBA202412040012
              then t2.OD_LOAN_ACCT_BAL * U.CCY_RATE
             else t2.loan_acct_bal* U.CCY_RATE end )
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2031', '2032', '2033', '2034', '2035', '2036')
         AND T2.OD_DAYS <= 90
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                       (T2.OD_DAYS > 60 and T2.OD_DAYS <= 90) AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                        ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
                   'S67_1.3.1.2.P.2021' --个人购买商业用房贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       (T2.OD_DAYS > 60 and T2.OD_DAYS <= 90) AND
                       T1.OWN_HOUSE = 1 THEN
                   'S67_1.4.1.1.P.2021' --1.4.1.1 第一套房
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       (T2.OD_DAYS > 60 and T2.OD_DAYS <= 90) AND
                       T1.OWN_HOUSE = 2 THEN
                   'S67_1.4.1.2.P.2021' --1.4.1.2 第二套房 --MODIFY BY DJH 二套房 20211227
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       (T2.OD_DAYS > 60 and T2.OD_DAYS <= 90) AND
                       T1.OWN_HOUSE = 3 THEN
                   'S67_1.4.1.3.P.2021' --1.4.1.3 第三套房及以上  --MODIFY BY DJH 三套房及以上 20211227
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                       (T2.OD_DAYS > 30 AND T2.OD_DAYS <= 60) AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                        ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                   'S67_1.3.1.2.O.2021' --个人购买商业用房贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       (T2.OD_DAYS > 30 AND T2.OD_DAYS <= 60) AND
                       T1.OWN_HOUSE = 1 THEN
                   'S67_1.4.1.1.O.2021' --1.4.1.1 第一套房
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       (T2.OD_DAYS > 30 AND T2.OD_DAYS <= 60) AND
                       T1.OWN_HOUSE = 2 THEN
                   'S67_1.4.1.2.O.2021' --1.4.1.2 第二套房 --MODIFY BY DJH 二套房 20211227
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       (T2.OD_DAYS > 30 AND T2.OD_DAYS <= 60) AND
                       T1.OWN_HOUSE = 3 THEN
                   'S67_1.4.1.3.O.2021' --1.4.1.3 第三套房及以上  --MODIFY BY DJH 三套房及以上 20211227
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                       (T2.OD_DAYS > 0 AND T2.OD_DAYS <= 30) AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                        ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
                   'S67_1.3.1.2.N.2021' --个人购买商业用房贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       (T2.OD_DAYS > 0 AND T2.OD_DAYS <= 30) AND
                       T1.OWN_HOUSE = 1 THEN
                   'S67_1.4.1.1.N.2021' --1.4.1.1 第一套房
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       (T2.OD_DAYS > 0 AND T2.OD_DAYS <= 30) AND
                       T1.OWN_HOUSE = 2 THEN
                   'S67_1.4.1.2.N.2021' --1.4.1.2 第二套房 --MODIFY BY DJH 二套房 20211227
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                       ('2032', '2033', '2034', '2035', '2036') AND
                       (T2.OD_DAYS > 0 AND T2.OD_DAYS <= 30) AND
                       T1.OWN_HOUSE = 3 THEN
                   'S67_1.4.1.3.N.2021' --1.4.1.3 第三套房及以上  --MODIFY BY DJH 三套房及以上 20211227
                END;

    COMMIT;

    ----1.3.1.1 企业购买商业用房贷款
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN T2.OD_DAYS > 360 AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
          'S67_1.3.1.1.S.2021'
         WHEN T2.OD_DAYS > 180 AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
          'S67_1.3.1.1.R.2021'
         WHEN T2.OD_DAYS > 90 AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
          'S67_1.3.1.1.Q.2021'
         WHEN (T2.OD_DAYS > 60 and T2.OD_DAYS <= 90) AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
          'S67_1.3.1.1.P.2021'
         WHEN (T2.OD_DAYS > 30 AND T2.OD_DAYS <= 60) AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
          'S67_1.3.1.1.O.2021'
         WHEN (T2.OD_DAYS > 0 AND T2.OD_DAYS <= 30) AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
          'S67_1.3.1.1.N.2021'
       END ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021')
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T2.OD_DAYS > 360 AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                   'S67_1.3.1.1.S.2021'
                  WHEN T2.OD_DAYS > 180 AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                   'S67_1.3.1.1.R.2021'
                  WHEN T2.OD_DAYS > 90 AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                   'S67_1.3.1.1.Q.2021'
                  WHEN (T2.OD_DAYS > 60 and T2.OD_DAYS <= 90) AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                   'S67_1.3.1.1.P.2021'
                  WHEN (T2.OD_DAYS > 30 AND T2.OD_DAYS <= 60) AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                   'S67_1.3.1.1.O.2021'
                  WHEN (T2.OD_DAYS > 0 AND T2.OD_DAYS <= 30) AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                   'S67_1.3.1.1.N.2021'
                END;

     COMMIT;
    V_STEP_FLAG := 1;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_CONTRACT_NUM_TMP';

    ----4.其他以房地产为抵押的贷款
    --  注释M1
    ---房地产抵押临时表

    --注释2 ，将押品判定分为当月押品有效和贷款结清时是否有效，
    --当月押品有效
    INSERT  INTO CBRC_CONTRACT_NUM_TMP (CONTRACT_NUM)
      SELECT 
      DISTINCT A.CONTRACT_NUM
        FROM SMTMODS_L_AGRE_GUA_RELATION A --业务合同与担保合同对应关系表
        LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT B1 --   担保合同信息
          ON A.GUAR_CONTRACT_NUM = B1.GUAR_CONTRACT_NUM
         AND B1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_RELATION B --担保合同与担保信息对应关系表
          ON A.GUAR_CONTRACT_NUM = B.GUAR_CONTRACT_NUM
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_GUARANTY_INFO C --抵质押物详细信息
          ON B.GUARANTEE_SERIAL_NUM = C.GUARANTEE_SERIAL_NUM
         AND C.DATA_DATE = I_DATADATE
       WHERE A.DATA_DATE = I_DATADATE
         AND UPPER(C.COLL_STATUS) = 'Y' --押品状态取有效
         and B.GUAR_CUST_ID IS NOT NULL
         AND B.REL_STATUS = 'Y'
         AND B1.GUAR_CONTRACT_STATUS = 'Y' --担保合同有效状态
         AND (SUBSTR(C.COLL_TYP, 1, 3) IN ('B01', 'B02', 'B03'))--押品类型：B01个人住房 B02非个人住房类房产 B03土地使用权(包含土地附着物)

         ;
    COMMIT;
    --贷款结清时判断押品是否有效

     INSERT  INTO CBRC_CONTRACT_NUM_TMP (CONTRACT_NUM)
    SELECT 
      DISTINCT A.CONTRACT_NUM
        FROM SMTMODS_L_AGRE_GUA_RELATION A --业务合同与担保合同对应关系表
         INNER JOIN SMTMODS_L_ACCT_LOAN T
          ON T.ACCT_NUM =A.CONTRACT_NUM
          AND T.DATA_DATE =I_DATADATE
        LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_CONTRACT B1 --   担保合同信息
          ON A.GUAR_CONTRACT_NUM = B1.GUAR_CONTRACT_NUM
         AND B1.DATA_DATE = TO_CHAR(T.FINISH_DT,'YYYYMMDD')
        LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_RELATION B --担保合同与担保信息对应关系表
          ON A.GUAR_CONTRACT_NUM = B.GUAR_CONTRACT_NUM
         AND B.DATA_DATE =TO_CHAR(T.FINISH_DT,'YYYYMMDD')
        LEFT JOIN SMTMODS_L_AGRE_GUARANTY_INFO C --抵质押物详细信息
          ON B.GUARANTEE_SERIAL_NUM = C.GUARANTEE_SERIAL_NUM
         AND C.DATA_DATE =TO_CHAR(T.FINISH_DT,'YYYYMMDD')
       WHERE A.DATA_DATE = TO_CHAR(T.FINISH_DT,'YYYYMMDD')
         AND UPPER(C.COLL_STATUS) = 'Y' --押品状态取有效
         and B.GUAR_CUST_ID IS NOT NULL
         AND B.REL_STATUS = 'Y'
         AND B1.GUAR_CONTRACT_STATUS = 'Y' --担保合同有效状态
         AND (SUBSTR(C.COLL_TYP, 1, 3) IN ('B01', 'B02', 'B03'))--押品类型：B01个人住房 B02非个人住房类房产 B03土地使用权(包含土地附着物)
         and T.ACCT_STS = '3' --结清
         AND TO_CHAR(T.FINISH_DT,'YYYYMM')  = SUBSTR(I_DATADATE,1,6)
         AND NOT EXISTS (SELECT 1
                FROM CBRC_CONTRACT_NUM_TMP C1
               WHERE  A.CONTRACT_NUM = C1.CONTRACT_NUM)
         ;

    commit;




    --当月新发放金额
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
       SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       'S67_4..C.2021' AS ITEM_NUM,
       SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) LOAN_ACCT_BAL_RMB
        FROM  SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
       left JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
         ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
       INNER JOIN CBRC_CONTRACT_NUM_TMP C --取押品类型
          ON T2.ACCT_NUM = C.CONTRACT_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T2.DATA_DATE = I_DATADATE

         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(nvl(T1.PROPERTYLOAN_TYP,'&'), 1, 4) NOT IN
             ('2011',
              '2021',
              '2031',
              '2032',
              '2033',
              '2034',
              '2035',
              '2036') --企业、个人购买商业用房贷款、个人住房贷款
         AND SUBSTR(nvl(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN ('101', '102', '103') --地产开发贷款
         AND SUBSTR(nvl(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN
             ('111', '112', '113', '114', '119') --房产开发贷款
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;

    COMMIT;

    --当月收回金额
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
       SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       'S67_4..D.2021' AS ITEM_NUM,
       SUM(T2.PAY_AMT) AS PAY_AMT --本金金额 --alter by wjb 20220531 松原业务提出收回金额不算利息
        FROM SMTMODS_L_TRAN_LOAN_PAYM T2 ---还款表
       LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = I_DATADATE
       INNER JOIN CBRC_CONTRACT_NUM_TMP C --取押品类型
          ON T2.ACCT_NUM = C.CONTRACT_NUM

       WHERE T2.DATA_DATE = TO_CHAR(REPAY_DT, 'YYYYMMDD')
         AND SUBSTR(TO_CHAR(T2.REPAY_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 4) NOT IN
             ('2011',
              '2021',
              '2031',
              '2032',
              '2033',
              '2034',
              '2035',
              '2036') --企业、个人购买商业用房贷款、个人住房贷款
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN ('101', '102', '103') --地产开发贷款
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN
             ('111', '112', '113', '114', '119') --房产开发贷款
       GROUP BY T2.ORG_NUM;

    COMMIT;

    --五级分类
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
  SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN T2.LOAN_GRADE_CD = '1' THEN
          'S67_4..F.2021' --正常类
         WHEN T2.LOAN_GRADE_CD = '2' THEN
          'S67_4..G.2021' --关注类
         WHEN T2.LOAN_GRADE_CD = '3' THEN
          'S67_4..I.2021' --次级类
         WHEN T2.LOAN_GRADE_CD = '4' THEN
          'S67_4..J.2021' --可疑类
         WHEN T2.LOAN_GRADE_CD = '5' THEN
          'S67_4..K.2021' --损失类
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
       LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
       INNER JOIN CBRC_CONTRACT_NUM_TMP C --取押品类型
          ON T2.ACCT_NUM = C.CONTRACT_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T2.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
          AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 4) NOT IN
             ('2011',
              '2021',
              '2031',
              '2032',
              '2033',
              '2034',
              '2035',
              '2036') --企业、个人购买商业用房贷款、个人住房贷款
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN ('101', '102', '103') --地产开发贷款
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN
             ('111', '112', '113', '114', '119') --房产开发贷款
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T2.LOAN_GRADE_CD = '1' THEN
                   'S67_4..F.2021' --正常类
                  WHEN T2.LOAN_GRADE_CD = '2' THEN
                   'S67_4..G.2021' --关注类
                  WHEN T2.LOAN_GRADE_CD = '3' THEN
                   'S67_4..I.2021' --次级类
                  WHEN T2.LOAN_GRADE_CD = '4' THEN
                   'S67_4..J.2021' --可疑类
                  WHEN T2.LOAN_GRADE_CD = '5' THEN
                   'S67_4..K.2021' --损失类
                END;
    COMMIT;

    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
    SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       'S67_4..L.2021' AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM  SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
       LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
       INNER JOIN CBRC_CONTRACT_NUM_TMP C --取押品类型
          ON T2.ACCT_NUM = C.CONTRACT_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T2.DATA_DATE = I_DATADATE
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND T2.EXTENDTERM_FLG = 'Y' --展期
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 4) NOT IN
             ('2011',
              '2021',
              '2031',
              '2032',
              '2033',
              '2034',
              '2035',
              '2036') --企业、个人购买商业用房贷款、个人住房贷款
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN ('101', '102', '103') --地产开发贷款
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN
             ('111', '112', '113', '114', '119') --房产开发贷款
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;
    COMMIT;

    ---逾期
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
       SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN T2.OD_DAYS > 360 THEN
          'S67_4..S.2021' -- 逾期361天以上
         WHEN T2.OD_DAYS > 180 THEN
          'S67_4..R.2021' --逾期181-360天
         WHEN T2.OD_DAYS > 90 THEN
          'S67_4..Q.2021' ----逾期91-180天
         WHEN T2.OD_DAYS > 60 THEN
          'S67_4..P.2021' ----逾期61-90天
         WHEN T2.OD_DAYS > 30 THEN
          'S67_4..O.2021' ----逾期31-60天
         WHEN T2.OD_DAYS > 0 THEN
          'S67_4..N.2021' --逾期1-30天
       END ITEM_NUM,
       --SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
         /*alter by shiyu 20241105 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
            如果是按月分期还款的个人消费贷款本金或利息逾期 */
       sum(case when (t2.ACCT_TYP LIKE '0101%' OR t2.ACCT_TYP LIKE '0103%' OR
             t2.ACCT_TYP LIKE '0104%' OR t2.ACCT_TYP LIKE '0199%'
             )  --个人消费
             AND t2.REPAY_TYP ='1'    --按月支付
              and  T2.PAY_TYPE in   ('01','02','10','11') --JLBA202412040012
             and T2.OD_DAYS <= 90    --逾期天数小于90天
             then t2.OD_LOAN_ACCT_BAL * U.CCY_RATE
             else t2.loan_acct_bal* U.CCY_RATE end )
        FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
       LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
       INNER JOIN CBRC_CONTRACT_NUM_TMP C --取押品类型
          ON T2.ACCT_NUM = C.CONTRACT_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T2.DATA_DATE = I_DATADATE
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 4) NOT IN
             ('2011',
              '2021',
              '2031',
              '2032',
              '2033',
              '2034',
              '2035',
              '2036') --企业、个人购买商业用房贷款、个人住房贷款
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN ('101', '102', '103') --地产开发贷款
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN
             ('111', '112', '113', '114', '119') --房产开发贷款
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T2.OD_DAYS > 360 THEN
                   'S67_4..S.2021' -- 逾期361天以上
                  WHEN T2.OD_DAYS > 180 THEN
                   'S67_4..R.2021' --逾期181-360天
                  WHEN T2.OD_DAYS > 90 THEN
                   'S67_4..Q.2021' ----逾期91-180天
                  WHEN T2.OD_DAYS > 60 THEN
                   'S67_4..P.2021' ----逾期61-90天
                  WHEN T2.OD_DAYS > 30 THEN
                   'S67_4..O.2021' ----逾期31-60天
                  WHEN T2.OD_DAYS > 0 THEN
                   'S67_4..N.2021' --逾期1-30天
                END;

    COMMIT;

    -------------------------------------ADD BY DJH 20211216  保障性安居工程相关-------------------------------------
    --1.1.1  其中:保障性安居工程
    --1.2.1.1 其中：保障性住房开发贷款
    --1.5.1 其中：经营性物业贷款
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据保障性安居工程等期末余额至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --期末余额情况
    --本期
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             'S67_1.1.1.A.2021', --1.1.1其中:保障性安居工程.期末余额情况.本期
             SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE --取本期
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' --保障性安居工程
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据保障性安居工程等期末余额至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据保障性安居工程等发放与收回至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --发放与收回情况
    --当月新发放金额
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
          'S67_1.1.1.C.2021' --1.1.1其中:保障性安居工程.发放与收回情况.当月新发放金额
         WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111'
              AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
              ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
              SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
          'S67_1.2.1.1.C.2021' --1.2.1.1其中：保障性住房开发贷款.发放与收回情况.当月新发放金额
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' THEN
          'S67_1.5.1.C.2021' --1.5.1其中：经营性物业贷款.发放与收回情况.当月新发放金额
         WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%' THEN
          'S67_0_5..C.2021' --1.5.2 其中：房地产并购贷款.发放与收回情况.当月新发放金额
       END ITEM_NUM,
       SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('102', '111') OR
             SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%'))
       AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
                   'S67_1.1.1.C.2021' --1.1.1其中:保障性安居工程.发放与收回情况.当月新发放金额
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                       SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                   'S67_1.2.1.1.C.2021' --1.2.1.1其中：保障性住房开发贷款.发放与收回情况.当月新发放金额
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' THEN
                   'S67_1.5.1.C.2021' --1.5.1其中：经营性物业贷款.发放与收回情况.当月新发放金额
                  WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND
                       T2.ACCT_TYP LIKE '0203%' THEN
                   'S67_0_5..C.2021'
                END;
    COMMIT;

    --当月新收回金额
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
                'S67_1.1.1.D.2021' --1.1.1其中:保障性安居工程.发放与收回情况.当月新发放金额
               WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111'
                AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN  --alter by djh 20240103 02抵押类贷款12  用途-装修改造
                'S67_1.2.1.1.D.2021' --1.2.1.1其中：保障性住房开发贷款.发放与收回情况.当月新发放金额
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                    JYXWY_FLG = 'Y'  THEN
                'S67_1.5.1.D.2021' --1.5.1其中：经营性物业贷款.发放与收回情况.当月新发放金额
               WHEN T3.LOAN_PURPOSE_CD LIKE 'K%' AND T3.ACCT_TYP LIKE '0203%' THEN
                'S67_0_5..D.2021' --1.5.2 房地产并购贷款
             END ITEM_NUM,
             --SUM(T2.PAY_AMT + T2.PAY_INT_AMT) AS PAY_AMT --本金金额
             SUM(T2.PAY_AMT) AS PAY_AMT --本金金额 --alter by wjb 20220531 松原业务提出收回金额不算利息
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1 --房地产贷款补充信息
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM T2 --贷款还款明细信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
       INNER JOIN SMTMODS_L_ACCT_LOAN T3 --贷款借据信息表
          ON T1.LOAN_NUM = T3.LOAN_NUM
         AND T1.DATA_DATE = T3.DATA_DATE
       WHERE T1.DATA_DATE = I_DATADATE
         AND SUBSTR(TO_CHAR(T2.REPAY_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND T2.DATA_DATE = TO_CHAR(REPAY_DT, 'YYYYMMDD')
         AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('102', '111') OR
             SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR (T3.LOAN_PURPOSE_CD LIKE 'K%' AND T3.ACCT_TYP LIKE '0203%'))
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
                   'S67_1.1.1.D.2021' --1.1.1其中:保障性安居工程.发放与收回情况.当月新发放金额
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                   'S67_1.2.1.1.D.2021' --1.2.1.1其中：保障性住房开发贷款.发放与收回情况.当月新发放金额
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' THEN
                   'S67_1.5.1.D.2021' --1.5.1其中：经营性物业贷款.发放与收回情况.当月新发放金额
                  WHEN T3.LOAN_PURPOSE_CD LIKE 'K%' AND T3.ACCT_TYP LIKE '0203%' THEN
                   'S67_0_5..D.2021' --1.5.2 房地产并购贷款
                END;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据保障性安居工程等发放与收回至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据保障性安居工程等贷款五级分类情况至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --贷款五级分类情况
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
              T2.LOAN_GRADE_CD IN ('1', '2') THEN
          'S67_1.1.1.E.2021' --正常贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
              T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
          'S67_1.1.1.H.2021' --不良贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
              T2.LOAN_GRADE_CD = '1' THEN
          'S67_1.1.1.F.2021' --正常类
         WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
              T2.LOAN_GRADE_CD = '1' AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
              SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
          'S67_1.2.1.1.F.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' AND
              T2.LOAN_GRADE_CD = '1' THEN
          'S67_1.5.1.F.2021'
         WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%' AND
              T2.LOAN_GRADE_CD = '1' THEN
          'S67_0_5..F.2021' --1.5.2 房地产并购贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
              T2.LOAN_GRADE_CD = '2' THEN
          'S67_1.1.1.G.2021' --关注类
         WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
              T2.LOAN_GRADE_CD = '2' AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
              SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
          'S67_1.2.1.1.G.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' AND
              T2.LOAN_GRADE_CD = '2' THEN
          'S67_1.5.1.G.2021'
         WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%' AND
              T2.LOAN_GRADE_CD = '2' THEN
          'S67_0_5..G.2021' --1.5.2 房地产并购贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
              T2.LOAN_GRADE_CD = '3' THEN
          'S67_1.1.1.I.2021' --次级类
         WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
              T2.LOAN_GRADE_CD = '3' AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
              SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
          'S67_1.2.1.1.I.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' AND
              T2.LOAN_GRADE_CD = '3' THEN
          'S67_1.5.1.I.2021'
         WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%' AND
              T2.LOAN_GRADE_CD In ('3', '4', '5') THEN
          'S67_0_5..H.2021' --1.5.2 房地产并购贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
              T2.LOAN_GRADE_CD = '4' THEN
          'S67_1.1.1.J.2021' --可疑类
         WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
              T2.LOAN_GRADE_CD = '4' AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
              SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
          'S67_1.2.1.1.J.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' AND
              T2.LOAN_GRADE_CD = '4' THEN
          'S67_1.5.1.J.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
              T2.LOAN_GRADE_CD = '5' THEN
          'S67_1.1.1.K.2021' --损失类
         WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
              T2.LOAN_GRADE_CD = '5' AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
              SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
          'S67_1.2.1.1.K.2021'
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' AND
              T2.LOAN_GRADE_CD = '5' THEN
          'S67_1.5.1.K.2021'
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('102', '111') OR
             SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR
             (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%'))
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
                       T2.LOAN_GRADE_CD IN ('1', '2') THEN
                   'S67_1.1.1.E.2021' --正常贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
                       T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                   'S67_1.1.1.H.2021' --不良贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
                       T2.LOAN_GRADE_CD = '1' THEN
                   'S67_1.1.1.F.2021' --正常类
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                       T2.LOAN_GRADE_CD = '1' AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                       SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
                   'S67_1.2.1.1.F.2021'
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' AND T2.LOAN_GRADE_CD = '1' THEN
                   'S67_1.5.1.F.2021'
                  WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND
                       T2.ACCT_TYP LIKE '0203%' AND T2.LOAN_GRADE_CD = '1' THEN
                   'S67_0_5..F.2021' --1.5.2 房地产并购贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
                       T2.LOAN_GRADE_CD = '2' THEN
                   'S67_1.1.1.G.2021' --关注类
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                       T2.LOAN_GRADE_CD = '2' AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                       SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
                   'S67_1.2.1.1.G.2021'
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' AND T2.LOAN_GRADE_CD = '2' THEN
                   'S67_1.5.1.G.2021'
                  WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND
                       T2.ACCT_TYP LIKE '0203%' AND T2.LOAN_GRADE_CD = '2' THEN
                   'S67_0_5..G.2021' --1.5.2 房地产并购贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
                       T2.LOAN_GRADE_CD = '3' THEN
                   'S67_1.1.1.I.2021' --次级类
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                       T2.LOAN_GRADE_CD = '3' AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                       SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
                   'S67_1.2.1.1.I.2021'
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' AND T2.LOAN_GRADE_CD = '3' THEN
                   'S67_1.5.1.I.2021'
                  WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND
                       T2.ACCT_TYP LIKE '0203%' AND
                       T2.LOAN_GRADE_CD In ('3', '4', '5') THEN
                   'S67_0_5..H.2021' --1.5.2 房地产并购贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
                       T2.LOAN_GRADE_CD = '4' THEN
                   'S67_1.1.1.J.2021' --可疑类
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                       T2.LOAN_GRADE_CD = '4' AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                       SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
                   'S67_1.2.1.1.J.2021'
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' AND T2.LOAN_GRADE_CD = '4' THEN
                   'S67_1.5.1.J.2021'
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
                       T2.LOAN_GRADE_CD = '5' THEN
                   'S67_1.1.1.K.2021' --损失类
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                       T2.LOAN_GRADE_CD = '5' AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                       SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12  用途-装修改造
                   'S67_1.2.1.1.K.2021'
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' AND T2.LOAN_GRADE_CD = '5' THEN
                   'S67_1.5.1.K.2021'
                END;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据保障性安居工程等贷款五级分类情况至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据保障性安居工程等贷款展期至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --展期
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             CASE
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
                'S67_1.1.1.L.2021' --1.1.1  其中:保障性安居工程展期
               WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                'S67_1.2.1.1.L.2021' --1.2.1.1 其中：保障性住房开发贷款展期
               WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                    JYXWY_FLG = 'Y' THEN
                'S67_1.5.1.L.2021' --1.5.1 其中：经营性物业贷款展期
               WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND
                       T2.ACCT_TYP LIKE '0203%'  THEN
                'S67_0_5..L.2021' --1.5.2 房地产并购贷款
             END ITEM_NUM,
             SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('102', '111') OR
             SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%'))
         AND EXTENDTERM_FLG = 'Y' --展期
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
                   'S67_1.1.1.L.2021' --1.1.1  其中:保障性安居工程展期
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111'
                   AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD,1,2) NOT IN('02','12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN  --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                   'S67_1.2.1.1.L.2021' --1.2.1.1 其中：保障性住房开发贷款展期
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' THEN
                   'S67_1.5.1.L.2021' --1.5.1 其中：经营性物业贷款展期
                  WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND
                       T2.ACCT_TYP LIKE '0203%'  THEN
                  'S67_0_5..L.2021' --1.5.2 房地产并购贷款
                END;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据保障性安居工程等贷款展期至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据保障性安居工程等逾期情况至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --逾期情况
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
          'S67_1.1.1.M.2021' --1.1.1  其中:保障性安居工程 逾期余额
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND T2.OD_DAYS > 360 THEN
          'S67_1.1.1.S.2021' --1.1.1  其中:保障性安居工程逾期361天以上
         WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
              T2.OD_DAYS > 360 AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
              SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
          'S67_1.2.1.1.S.2021' --1.2.1.1 其中：保障性住房开发贷款361天以上
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' AND
              T2.OD_DAYS > 360 THEN
          'S67_1.5.1.S.2021' --1.5.1 其中：经营性物业贷款361天以上
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND T2.OD_DAYS > 180 THEN
          'S67_1.1.1.R.2021' --1.1.1  其中:保障性安居工程逾期181-360天
         WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
              T2.OD_DAYS > 180 AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
              SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
          'S67_1.2.1.1.R.2021' --1.2.1.1 其中：保障性住房开发贷款逾期181-360天
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' AND
              T2.OD_DAYS > 180 THEN
          'S67_1.5.1.R.2021' --1.5.1 其中：经营性物业贷款逾期181-360天
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND T2.OD_DAYS > 90 THEN
          'S67_1.1.1.Q.2021' --1.1.1  其中:保障性安居工程逾期91-180天
         WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND T2.OD_DAYS > 90 AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
              SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
          'S67_1.2.1.1.Q.2021' --1.2.1.1 其中：保障性住房开发贷款逾期91-180天
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' AND
              T2.OD_DAYS > 90 THEN
          'S67_1.5.1.Q.2021' --1.5.1 其中：经营性物业贷款逾期91-180天
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND T2.OD_DAYS > 60 THEN
          'S67_1.1.1.P.2021' --1.1.1  其中:保障性安居工程逾期61-90天
         WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND T2.OD_DAYS > 60 AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
              SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
          'S67_1.2.1.1.P.2021' --1.2.1.1 其中：保障性住房开发贷款逾期61-90天
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' AND
              T2.OD_DAYS > 60 THEN
          'S67_1.5.1.P.2021' --1.5.1 其中：经营性物业贷款逾期61-90天
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND T2.OD_DAYS > 30 THEN
          'S67_1.1.1.O.2021' --1.1.1  其中:保障性安居工程逾期31-60天
         WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND T2.OD_DAYS > 30 AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
              SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
          'S67_1.2.1.1.O.2021' --1.2.1.1 其中：保障性住房开发贷款逾期31-60天
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' AND
              T2.OD_DAYS > 30 THEN
          'S67_1.5.1.O.2021' --1.5.1 其中：经营性物业贷款逾期31-60天
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND T2.OD_DAYS > 0 THEN
          'S67_1.1.1.N.2021' --1.1.1  其中:保障性安居工程逾期1-30天
         WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND T2.OD_DAYS > 0 AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
              SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
          'S67_1.2.1.1.N.2021' --1.2.1.1 其中：保障性住房开发贷款逾期1-30天
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' AND
              T2.OD_DAYS > 0 THEN
          'S67_1.5.1.N.2021' --1.5.1 其中：经营性物业贷款逾期1-30天
         WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%' THEN
          'S67_0_5..Y.2021' --1.5.2 房地产并购贷款
         WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%' AND
              T2.OD_DAYS > 90 THEN
          'S67_0_5..S.2021' --1.5.2 房地产并购贷款 逾期91天以上
         WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%' AND
              T2.OD_DAYS > 60 THEN
          'S67_0_5..P.2021' --1.5.2 房地产并购贷款 逾期61-90天
         WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%' AND
              T2.OD_DAYS > 0 THEN
          'S67_0_5..N.2021' --1.5.2 房地产并购贷款 逾期1-60天
       END ITEM_NUM,
       ---SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        /*alter by shiyu 20241105 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
            如果是按月分期还款的个人消费贷款本金或利息逾期 */
       sum(case when (t2.ACCT_TYP LIKE '0101%' OR t2.ACCT_TYP LIKE '0103%' OR
             t2.ACCT_TYP LIKE '0104%' OR t2.ACCT_TYP LIKE '0199%'
             )
             and t2.REPAY_TYP ='1'  --按月支付
             and T2.PAY_TYPE in   ('01','02','10','11') --JLBA202412040012
             and t2.od_days <= 90
             then t2.OD_LOAN_ACCT_BAL * U.CCY_RATE
             else t2.loan_acct_bal* U.CCY_RATE end )
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('102', '111') OR
             SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR
             (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%'))
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
                   'S67_1.1.1.M.2021' --1.1.1  其中:保障性安居工程 逾期余额
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
                       T2.OD_DAYS > 360 THEN
                   'S67_1.1.1.S.2021' --1.1.1  其中:保障性安居工程逾期361天以上
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                       T2.OD_DAYS > 360 AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                       SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                   'S67_1.2.1.1.S.2021' --1.2.1.1 其中：保障性住房开发贷款361天以上
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' AND T2.OD_DAYS > 360 THEN
                   'S67_1.5.1.S.2021' --1.5.1 其中：经营性物业贷款361天以上
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
                       T2.OD_DAYS > 180 THEN
                   'S67_1.1.1.R.2021' --1.1.1  其中:保障性安居工程逾期181-360天
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                       T2.OD_DAYS > 180 AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                       SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                   'S67_1.2.1.1.R.2021' --1.2.1.1 其中：保障性住房开发贷款逾期181-360天
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' AND T2.OD_DAYS > 180 THEN
                   'S67_1.5.1.R.2021' --1.5.1 其中：经营性物业贷款逾期181-360天
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
                       T2.OD_DAYS > 90 THEN
                   'S67_1.1.1.Q.2021' --1.1.1  其中:保障性安居工程逾期91-180天
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                       T2.OD_DAYS > 90 AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                       SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                   'S67_1.2.1.1.Q.2021' --1.2.1.1 其中：保障性住房开发贷款逾期91-180天
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' AND T2.OD_DAYS > 90 THEN
                   'S67_1.5.1.Q.2021' --1.5.1 其中：经营性物业贷款逾期91-180天
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
                       T2.OD_DAYS > 60 THEN
                   'S67_1.1.1.P.2021' --1.1.1  其中:保障性安居工程逾期61-90天
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                       T2.OD_DAYS > 60 AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                       SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                   'S67_1.2.1.1.P.2021' --1.2.1.1 其中：保障性住房开发贷款逾期61-90天
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' AND T2.OD_DAYS > 60 THEN
                   'S67_1.5.1.P.2021' --1.5.1 其中：经营性物业贷款逾期61-90天
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
                       T2.OD_DAYS > 30 THEN
                   'S67_1.1.1.O.2021' --1.1.1  其中:保障性安居工程逾期31-60天
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                       T2.OD_DAYS > 30 AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                       SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                   'S67_1.2.1.1.O.2021' --1.2.1.1 其中：保障性住房开发贷款逾期31-60天
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' AND T2.OD_DAYS > 30 THEN
                   'S67_1.5.1.O.2021' --1.5.1 其中：经营性物业贷款逾期31-60天
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' AND
                       T2.OD_DAYS > 0 THEN
                   'S67_1.1.1.N.2021' --1.1.1  其中:保障性安居工程逾期1-30天
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                       T2.OD_DAYS > 0 AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                       SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN --alter by djh 20240103 02抵押类贷款12 用途-装修改造
                   'S67_1.2.1.1.N.2021' --1.2.1.1 其中：保障性住房开发贷款逾期1-30天
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                       JYXWY_FLG = 'Y' AND T2.OD_DAYS > 0 THEN
                   'S67_1.5.1.N.2021' --1.5.1 其中：经营性物业贷款逾期1-30天
                  WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND
                       T2.ACCT_TYP LIKE '0203%' THEN
                   'S67_0_5..Y.2021' --1.5.2 房地产并购贷款
                  WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND
                       T2.ACCT_TYP LIKE '0203%' AND T2.OD_DAYS > 90 THEN
                   'S67_0_5..S.2021' --1.5.2 房地产并购贷款 逾期91天以上
                  WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND
                       T2.ACCT_TYP LIKE '0203%' AND T2.OD_DAYS > 60 THEN
                   'S67_0_5..P.2021' --1.5.2 房地产并购贷款 逾期61-90天
                  WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND
                       T2.ACCT_TYP LIKE '0203%' AND T2.OD_DAYS > 0 THEN
                   'S67_0_5..N.2021' --1.5.2 房地产并购贷款 逾期1-60天
                END;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据保障性安居工程等逾期情况至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    -------------------------------------ADD BY DJH 20211216  保障性安居工程相关 -------------------------------------
    -------------------------------------ADD BY DJH 20211222  附注-------------------------------------
    -----------------------------本期-----------------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据附注本期至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --1.个人住房贷款情况
    --1.1 首套个人住房贷款首付合计
    --1.3 二套及以上个人住房贷款首付合计
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN T1.OWN_HOUSE = 0 THEN 'S67_0_1.1.A.2021' --1.1首套个人住房贷款首付合计.期末余额情况.本期
         WHEN T1.OWN_HOUSE >= 1 THEN  'S67_0_1.3.A.2021' --1.3二套及以上个人住房贷款首付合计.期末余额情况.本期
       END AS ITEM_NUM,
       SUM(T1.DOWN_PAYMENTS * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --房贷款首付
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036')
         AND T2.ACCT_STS <> '3' --结清
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T1.OWN_HOUSE = 0 THEN 'S67_0_1.1.A.2021' --1.1首套个人住房贷款首付合计.期末余额情况.本期
                  WHEN T1.OWN_HOUSE >= 1 THEN  'S67_0_1.3.A.2021' --1.3二套及以上个人住房贷款首付合计.期末余额情况.本期
                END;
    COMMIT;
    --1.2 首套个人住房贷款房屋总价合计
    --1.4 二套及以上个人住房贷款房屋总价合计
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN T1.OWN_HOUSE = 0 THEN
          'S67_0_1.2.A.2021' --1.2首套个人住房贷款房屋总价合计.期末余额情况.本期
         WHEN T1.OWN_HOUSE >= 1 THEN
          'S67_0_1.4.A.2021' --1.4二套及以上个人住房贷款房屋总价合计.期末余额情况.本期
       END ITEM_NUM,
       SUM(T1.HOUSE_VAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --贷款房屋总价
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036')
         AND T2.ACCT_STS <> '3' --结清
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T1.OWN_HOUSE = 0 THEN
                   'S67_0_1.2.A.2021' --1.2首套个人住房贷款房屋总价合计.期末余额情况.本期
                  WHEN T1.OWN_HOUSE >= 1 THEN
                   'S67_0_1.4.A.2021' --1.4二套及以上个人住房贷款房屋总价合计.期末余额情况.本期
                END;
    COMMIT;
    --1.5 个人住房贷款房地产押品市场价值合计   在上面逻辑中已开发
    --2.房产开发贷款资本金情况
    --2.1 住房开发贷款的项目资本金合计
    --2.3 商业用房开发贷款的项目资本金合计
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') OR
              T1.PROPERTYLOAN_TYP IN ('3031', '3032') THEN
          'S67_02_1.A.2021' --2.1住房开发贷款的项目资本金合计.期末余额情况.本期
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') THEN
          'S67_0_2.3.A.2021' --2.3 商业用房开发贷款的项目资本金合计.期末余额情况.本期
       END ITEM_NUM,
       SUM(T1.PROJECT_INVESTMENT * NVL(T1.CAPITAL_RATE, 0) / 100 *
           U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --房产开发项目投资金额*资本金
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND T2.ACCT_STS <> '3' --结清
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                       ('111', '112', '113') OR
                       T1.PROPERTYLOAN_TYP IN ('3031', '3032') THEN
                   'S67_02_1.A.2021' --2.1住房开发贷款的项目资本金合计.期末余额情况.本期
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') THEN
                   'S67_0_2.3.A.2021' --2.3 商业用房开发贷款的项目资本金合计.期末余额情况.本期
                END;

    COMMIT;
    --2.2 住房开发贷款的项目投资总额合计
    --2.4 商业用房开发贷款的项目投资总额合计
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') OR
              T1.PROPERTYLOAN_TYP IN ('3031', '3032') THEN
          'S67_0_2.2.A.2021' --2.2 住房开发贷款的项目投资总额合计.期末余额情况.本期
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') THEN
          'S67_0_2.4.A.2021' --2.4 商业用房开发贷款的项目投资总额合计.期末余额情况.本期
       END ITEM_NUM,
       SUM(T1.PROJECT_INVESTMENT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --房产开发项目投资金额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND T2.ACCT_STS <> '3' --结清
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                       ('111', '112', '113') OR
                       T1.PROPERTYLOAN_TYP IN ('3031', '3032') THEN
                   'S67_0_2.2.A.2021' --2.2 住房开发贷款的项目投资总额合计.期末余额情况.本期
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') THEN
                   'S67_0_2.4.A.2021' --2.4 商业用房开发贷款的项目投资总额合计.期末余额情况.本期
                END;
    --3.支持住房租赁市场发展情况
    --3.1住房租赁开发贷款
    --3.1.1 其中：市场化住房租赁开发贷款
    --3.2住房租赁经营贷款
    --3.3住房租赁消费贷款
    --3.4 其他
    --4.代销投向房地产领域的资产管理产品  暂时取不了
    --5.房地产并购贷款
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据附注本期至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    -----------------------------本期-----------------------------
    -----------------------------上年同期-------------------------
    --用初始化公式处理
    -----------------------------上年同期-------------------------
    -----------------------------发放与收回情况-------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据附注发放与收回情况至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --当月新发放金额
    --1.个人住房贷款情况
    --1.1 首套个人住房贷款首付合计
    --1.3 二套及以上个人住房贷款首付合计
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN T1.OWN_HOUSE = 0 THEN
          'S67_0_1.1.C.2021' --1.1首套个人住房贷款首付合计.发放与收回情况.当月新发放金额
         WHEN T1.OWN_HOUSE >= 1 THEN
          'S67_0_1.3.C.2021' --1.3二套及以上个人住房贷款首付合计.发放与收回情况.当月新发放金额
       END ITEM_NUM,
       SUM(T1.DOWN_PAYMENTS * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --房贷款首付
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036')
         AND T2.ACCT_STS <> '3' --结清
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) =
             V_DATADATE_M ---取当月
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T1.OWN_HOUSE = 0 THEN
                   'S67_0_1.1.C.2021' --1.1首套个人住房贷款首付合计.发放与收回情况.当月新发放金额
                  WHEN T1.OWN_HOUSE >= 1 THEN
                   'S67_0_1.3.C.2021' --1.3二套及以上个人住房贷款首付合计.发放与收回情况.当月新发放金额
                END;
    COMMIT;
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN T1.OWN_HOUSE = 0 THEN
          'S67_0_1.2.C.2021' --1.2首套个人住房贷款房屋总价合计.发放与收回情况.当月新发放金额
         WHEN T1.OWN_HOUSE >= 1 THEN
          'S67_0_1.4.C.2021' --1.4二套及以上个人住房贷款房屋总价合计.发放与收回情况.当月新发放金额
       END ITEM_NUM,
       SUM(T1.HOUSE_VAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --贷款房屋总价
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036')
         AND T2.ACCT_STS <> '3' --结清
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) =
             V_DATADATE_M ---取当月
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T1.OWN_HOUSE = 0 THEN
                   'S67_0_1.2.C.2021' --1.2首套个人住房贷款房屋总价合计.发放与收回情况.当月新发放金额
                  WHEN T1.OWN_HOUSE >= 1 THEN
                   'S67_0_1.4.C.2021' --1.4二套及以上个人住房贷款房屋总价合计.发放与收回情况.当月新发放金额
                END;
    COMMIT;
    --2.1 住房开发贷款的项目资本金合计
    --2.3 商业用房开发贷款的项目资本金合计
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') OR
              T1.PROPERTYLOAN_TYP IN ('3031', '3032') THEN
          'S67_02_1.C.2021' --2.1住房开发贷款的项目资本金合计.发放与收回情况.当月新发放金额
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') THEN
          'S67_0_2.3.C.2021' --2.3 商业用房开发贷款的项目资本金合计.发放与收回情况.当月新发放金额
       END ITEM_NUM,
       SUM(T1.PROJECT_INVESTMENT * NVL(T1.CAPITAL_RATE, 0) / 100 *
           U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --房产开发项目投资金额*资本金
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND T2.ACCT_STS <> '3' --结清
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) =
             V_DATADATE_M ---取当月
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                       ('111', '112', '113') OR
                       T1.PROPERTYLOAN_TYP IN ('3031', '3032') THEN
                   'S67_02_1.C.2021' --2.1住房开发贷款的项目资本金合计.发放与收回情况.当月新发放金额
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') THEN
                   'S67_0_2.3.C.2021' --2.3 商业用房开发贷款的项目资本金合计.发放与收回情况.当月新发放金额
                END;
    COMMIT;
    --2.2 住房开发贷款的项目投资总额合计
    --2.4 商业用房开发贷款的项目投资总额合计
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') OR
              T1.PROPERTYLOAN_TYP IN ('3031', '3032') THEN
          'S67_0_2.2.C.2021' --2.2 住房开发贷款的项目投资总额合计.发放与收回情况.当月新发放金额
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') THEN
          'S67_0_2.4.C.2021' --2.4 商业用房开发贷款的项目投资总额合计.发放与收回情况.当月新发放金额
       END ITEM_NUM,
       SUM(T1.PROJECT_INVESTMENT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --房产开发项目投资金额*资本金
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND T2.ACCT_STS <> '3' --结清
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) =
             V_DATADATE_M ---取当月
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                       ('111', '112', '113') OR
                       T1.PROPERTYLOAN_TYP IN ('3031', '3032') THEN
                   'S67_0_2.2.C.2021' --2.2 住房开发贷款的项目投资总额合计.发放与收回情况.当月新发放金额
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') THEN
                   'S67_0_2.4.C.2021' --2.4 商业用房开发贷款的项目投资总额合计.发放与收回情况.当月新发放金额
                END;
    COMMIT;

    --ALTER BY WJB 20220627 新增 S67 附注2 住房租赁融资情况 逻辑

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '附注2逻辑处理开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --20240225
    --当月新发放金额

    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' THEN
          'S67_0_3.1.C.2021' --1.1住房租赁开发贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' THEN
          'S67_0_3.2.C.2021' --1.2住房租赁经营贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' THEN
          'S67_0_3.3.C.2021' --1.4住房租赁消费贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' THEN
          'S67_02_1.3.C.2022' --1.3住房租赁购买贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' THEN
          'S67_0_3.4.C.2021' --1.5其他
       END ITEM_NUM,
       SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --放款金额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND T2.ACCT_STS <> '3' --结清
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) =
             V_DATADATE_M ---取当月
         AND SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) IN ('A', 'B', 'C', 'D', 'E')
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' THEN
                   'S67_0_3.1.C.2021' --1.1住房租赁开发贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' THEN
                   'S67_0_3.2.C.2021' --1.2住房租赁经营贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' THEN
                   'S67_0_3.3.C.2021' --1.4住房租赁消费贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' THEN
                   'S67_02_1.3.C.2022' --1.3住房租赁购买贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' THEN
                   'S67_0_3.4.C.2021' --1.5其他
                END;

    COMMIT;

    --当月收回金额

    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' THEN
          'S67_0_3.1.D.2021' --1.1住房租赁开发贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' THEN
          'S67_0_3.2.D.2021' --1.2住房租赁经营贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' THEN
          'S67_0_3.3.D.2021' --1.4住房租赁消费贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' THEN
          'S67_02_1.3.D.2022' --1.3住房租赁购买贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' THEN
          'S67_0_3.4.D.2021' --1.5其他
       END ITEM_NUM,
       --SUM(T2.PAY_AMT + T2.PAY_INT_AMT) AS PAY_AMT --本金金额
       SUM(T2.PAY_AMT) AS PAY_AMT --本金金额 --alter by wjb 20220531 松原业务提出收回金额不算利息
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1 --房地产贷款补充信息
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM T2 --贷款还款明细信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.DATA_DATE = TO_CHAR(REPAY_DT, 'YYYYMMDD')
         AND SUBSTR(TO_CHAR(T2.REPAY_DT, 'YYYYMMDD'), 1, 6) = V_DATADATE_M ---取当月
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' THEN
                   'S67_0_3.1.D.2021' --1.1住房租赁开发贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' THEN
                   'S67_0_3.2.D.2021' --1.2住房租赁经营贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' THEN
                   'S67_0_3.3.D.2021' --1.4住房租赁消费贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' THEN
                   'S67_02_1.3.D.2022' --1.3住房租赁购买贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' THEN
                   'S67_0_3.4.D.2021' --1.5其他
                END;

    COMMIT;

    --贷款五级分类情况

    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' AND
              T2.LOAN_GRADE_CD = '1' THEN --住房租赁支持贷款分类
          'S67_0_3.1.F.2021' --1.1住房租赁开发贷款 正常
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' AND
              T2.LOAN_GRADE_CD = '1' THEN
          'S67_0_3.2.F.2021' --1.2住房租赁经营贷款 正常
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' AND
              T2.LOAN_GRADE_CD = '1' THEN
          'S67_0_3.3.F.2021' --1.4住房租赁消费贷款 正常
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' AND
              T2.LOAN_GRADE_CD = '1' THEN
          'S67_02_1.3.F.2022' --1.3住房租赁购买贷款 正常
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' AND
              T2.LOAN_GRADE_CD = '1' THEN
          'S67_0_3.4.F.2021' --1.5其他  正常
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' AND
              T2.LOAN_GRADE_CD = '2' THEN
          'S67_0_3.1.G.2021' --1.1住房租赁开发贷款 关注
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' AND
              T2.LOAN_GRADE_CD = '2' THEN
          'S67_0_3.2.G.2021' --1.2住房租赁经营贷款 关注
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' AND
              T2.LOAN_GRADE_CD = '2' THEN
          'S67_0_3.3.G.2021' --1.4住房租赁消费贷款 关注
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' AND
              T2.LOAN_GRADE_CD = '2' THEN
          'S67_02_1.3.G.2022' --1.3住房租赁购买贷款 关注
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' AND
              T2.LOAN_GRADE_CD = '2' THEN
          'S67_0_3.4.G.2021' --1.5其他 关注
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' AND
              T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
          'S67_0_3.1.H.2021' --1.1住房租赁开发贷款  不良
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' AND
              T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
          'S67_0_3.2.H.2021' --1.2住房租赁经营贷款  不良
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' AND
              T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
          'S67_0_3.3.H.2021' --1.4住房租赁消费贷款  不良
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' AND
              T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
          'S67_02_1.3.H.2022' --1.3住房租赁购买贷款  不良
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' AND
              T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
          'S67_0_3.4.H.2021' --1.5其他 不良
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' AND
                       T2.LOAN_GRADE_CD = '1' THEN --住房租赁支持贷款分类
                   'S67_0_3.1.F.2021' --1.1住房租赁开发贷款 正常
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' AND
                       T2.LOAN_GRADE_CD = '1' THEN
                   'S67_0_3.2.F.2021' --1.2住房租赁经营贷款 正常
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' AND
                       T2.LOAN_GRADE_CD = '1' THEN
                   'S67_0_3.3.F.2021' --1.4住房租赁消费贷款 正常
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' AND
                       T2.LOAN_GRADE_CD = '1' THEN
                   'S67_02_1.3.F.2022' --1.3住房租赁购买贷款 正常
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' AND
                       T2.LOAN_GRADE_CD = '1' THEN
                   'S67_0_3.4.F.2021' --1.5其他  正常
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' AND
                       T2.LOAN_GRADE_CD = '2' THEN
                   'S67_0_3.1.G.2021' --1.1住房租赁开发贷款 关注
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' AND
                       T2.LOAN_GRADE_CD = '2' THEN
                   'S67_0_3.2.G.2021' --1.2住房租赁经营贷款 关注
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' AND
                       T2.LOAN_GRADE_CD = '2' THEN
                   'S67_0_3.3.G.2021' --1.4住房租赁消费贷款 关注
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' AND
                       T2.LOAN_GRADE_CD = '2' THEN
                   'S67_02_1.3.G.2022' --1.3住房租赁购买贷款 关注
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' AND
                       T2.LOAN_GRADE_CD = '2' THEN
                   'S67_0_3.4.G.2021' --1.5其他 关注
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' AND
                       T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                   'S67_0_3.1.H.2021' --1.1住房租赁开发贷款  不良
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' AND
                       T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                   'S67_0_3.2.H.2021' --1.2住房租赁经营贷款  不良
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' AND
                       T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                   'S67_0_3.3.H.2021' --1.4住房租赁消费贷款  不良
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' AND
                       T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                   'S67_02_1.3.H.2022' --1.3住房租赁购买贷款  不良
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' AND
                       T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                   'S67_0_3.4.H.2021' --1.5其他 不良
                END;

    COMMIT;

    --展期贷款

    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' THEN
          'S67_0_3.1.L.2021' --1.1住房租赁开发贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' THEN
          'S67_0_3.2.L.2021' --1.2住房租赁经营贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' THEN
          'S67_0_3.3.L.2021' --1.4住房租赁消费贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' THEN
          'S67_02_1.3.L.2022' --1.3住房租赁购买贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' THEN
          'S67_0_3.4.L.2021' --1.5其他
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND T2.EXTENDTERM_FLG = 'Y' --展期标志
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' THEN
                   'S67_0_3.1.L.2021' --1.1住房租赁开发贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' THEN
                   'S67_0_3.2.L.2021' --1.2住房租赁经营贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' THEN
                   'S67_0_3.3.L.2021' --1.4住房租赁消费贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' THEN
                   'S67_02_1.3.L.2022' --1.3住房租赁购买贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' THEN
                   'S67_0_3.4.L.2021' --1.5其他
                END;

    COMMIT;
   --其中：当月新增展期金额
   INSERT 
   INTO CBRC_S67_DATA_COLLECT_TMP 
     (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
     SELECT 
      I_DATADATE AS DATA_DATE,
      T2.ORG_NUM,
      CASE
        WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' THEN
         'S67_02_1.1.I.2024' --1.1住房租赁开发贷款
        WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' THEN
         'S67_02_1.2.I.2024' --1.2住房租赁经营贷款
        WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' THEN
         'S67_02_1.4.I.2024' --1.4住房租赁消费贷款
        WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' THEN
         'S67_02_1.3.I.2024' --1.3住房租赁购买贷款
        WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' THEN
         'S67_02_1.5.I.2024' --1.5其他
      END AS ITEM_NUM,
      SUM(XX.EXTENT_AMT * U.CCY_RATE) LOAN_ACCT_BAL_RMB --展期金额
       FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
      INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
         ON T1.LOAN_NUM = T2.LOAN_NUM
        AND T1.DATA_DATE = T2.DATA_DATE
      INNER JOIN SMTMODS_L_ACCT_LOAN_EXTENDTERM XX
         ON T1.LOAN_NUM = XX.LOAN_NUM
        AND XX.DATA_DATE = I_DATADATE
       LEFT JOIN SMTMODS_L_PUBL_RATE U
         ON T2.DATA_DATE = U.DATA_DATE
        AND U.CCY_DATE = D_DATADATE_CCY
        AND U.BASIC_CCY = T2.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE T1.DATA_DATE = I_DATADATE
        AND T2.CANCEL_FLG = 'N'
        AND LENGTHB(T2.ACCT_NUM) < 36
        AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
        AND T2.EXTENDTERM_FLG = 'Y' --展期标志
        AND SUBSTR(TO_CHAR(XX.EXTENT_START_DT, 'YYYYMMDD'), 1, 6) =
            SUBSTR(I_DATADATE, 1, 6)
        AND SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) IN ('A', 'B', 'C', 'D', 'E')
    AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
      GROUP BY T2.ORG_NUM,
               CASE
                 WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' THEN
                  'S67_02_1.1.I.2024' --1.1住房租赁开发贷款
                 WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' THEN
                  'S67_02_1.2.I.2024' --1.2住房租赁经营贷款
                 WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' THEN
                  'S67_02_1.4.I.2024' --1.4住房租赁消费贷款
                 WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' THEN
                  'S67_02_1.3.I.2024' --1.3住房租赁购买贷款
                 WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' THEN
                  'S67_02_1.5.I.2024' --1.5其他
               END;

    COMMIT;

    --贷款逾期情况 【住房对公的部分全取贷款余额】
    --1.1住房租赁开发贷款\1.2住房租赁经营贷款\1.3住房租赁购买贷款\1.5其他
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' AND T2.OD_DAYS > 90 THEN
          'S67_0_3.1.S.2021' --1.1住房租赁开发贷款 逾期91以上
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' AND T2.OD_DAYS > 90 THEN
          'S67_0_3.2.S.2021' --1.2住房租赁经营贷款 逾期91以上
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' AND T2.OD_DAYS > 90 THEN
          'S67_02_1.3.S.2022' --1.3住房租赁购买贷款 逾期91以上
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' AND T2.OD_DAYS > 90 THEN
          'S67_0_3.4.S.2021' --1.5其他  逾期91以上
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' AND T2.OD_DAYS > 60 THEN
          'S67_0_3.1.P.2021' --1.1住房租赁开发贷款 逾期61 -90
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' AND T2.OD_DAYS > 60 THEN
          'S67_0_3.2.P.2021' --1.2住房租赁经营贷款 逾期61 -90
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' AND T2.OD_DAYS > 60 THEN
          'S67_02_1.3.P.2022' --1.3住房租赁购买贷款 逾期61 -90
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' AND T2.OD_DAYS > 60 THEN
          'S67_0_3.4.P.2021' --1.5其他  逾期61 -90
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' AND T2.OD_DAYS > 0 THEN
          'S67_0_3.1.N.2021' --3.1住房租赁开发贷款 逾期1 -60
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' AND T2.OD_DAYS > 0 THEN
          'S67_0_3.2.N.2021' --3.2住房租赁经营贷款 逾期1 -60
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' AND T2.OD_DAYS > 0 THEN
          'S67_02_1.3.N.2022' --1.3住房租赁购买贷款  逾期1 -60
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' AND T2.OD_DAYS > 0 THEN
          'S67_0_3.4.N.2021' --1.5其他   逾期1 -60
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' AND
                       T2.OD_DAYS > 90 THEN
                   'S67_0_3.1.S.2021' --1.1住房租赁开发贷款 逾期91以上
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' AND
                       T2.OD_DAYS > 90 THEN
                   'S67_0_3.2.S.2021' --1.2住房租赁经营贷款 逾期91以上
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' AND
                       T2.OD_DAYS > 90 THEN
                   'S67_02_1.3.S.2022' --1.3住房租赁购买贷款 逾期91以上
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' AND
                       T2.OD_DAYS > 90 THEN
                   'S67_0_3.4.S.2021' --1.5其他  逾期91以上
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' AND
                       T2.OD_DAYS > 60 THEN
                   'S67_0_3.1.P.2021' --1.1住房租赁开发贷款 逾期61 -90
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' AND
                       T2.OD_DAYS > 60 THEN
                   'S67_0_3.2.P.2021' --1.2住房租赁经营贷款 逾期61 -90
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' AND
                       T2.OD_DAYS > 60 THEN
                   'S67_02_1.3.P.2022' --1.3住房租赁购买贷款 逾期61 -90
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' AND
                       T2.OD_DAYS > 60 THEN
                   'S67_0_3.4.P.2021' --1.5其他  逾期61 -90
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' AND
                       T2.OD_DAYS > 0 THEN
                   'S67_0_3.1.N.2021' --3.1住房租赁开发贷款 逾期1 -60
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' AND
                       T2.OD_DAYS > 0 THEN
                   'S67_0_3.2.N.2021' --3.2住房租赁经营贷款 逾期1 -60
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' AND
                       T2.OD_DAYS > 0 THEN
                   'S67_02_1.3.N.2022' --1.3住房租赁购买贷款  逾期1 -60
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' AND
                       T2.OD_DAYS > 0 THEN
                   'S67_0_3.4.N.2021' --1.5其他   逾期1 -60
                END;

    COMMIT;

    --【个人住房逾期90天内取逾期金额，90天以上取贷款余额】
    --1.4住房租赁消费贷款
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             'S67_0_3.3.S.2021' ITEM_NUM,
             SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' --住房租赁消费贷款
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
         AND T2.OD_DAYS >90
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;

    COMMIT;

    --逾期90天以内取逾期金额
    --1.4住房租赁消费贷款
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN (T2.OD_DAYS > 60 AND T2.OD_DAYS <= 90) THEN
          'S67_0_3.3.P.2021'
         WHEN (T2.OD_DAYS > 0 AND T2.OD_DAYS <= 60) THEN
          'S67_0_3.3.N.2021'
       END ITEM_NUM,
       SUM(T2.OD_LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --逾期金额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' --住房租赁消费贷款
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
         AND T2.OD_DAYS <= 90
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN (T2.OD_DAYS > 60 AND T2.OD_DAYS <= 90) THEN
                   'S67_0_3.3.P.2021'
                  WHEN (T2.OD_DAYS > 0 AND T2.OD_DAYS <= 60) THEN
                   'S67_0_3.3.N.2021'
                END;

    COMMIT;
 --其中：当月新增逾期金额
  INSERT 
  INTO CBRC_S67_DATA_COLLECT_TMP 
    (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
    SELECT 
     I_DATADATE AS DATA_DATE,
     T2.ORG_NUM,
     CASE
       WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' THEN
        'S67_02_1.1.K.2024' --1.1住房租赁开发贷款
       WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' THEN
        'S67_02_1.2.K.2024' --1.2住房租赁经营贷款
       WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' THEN
        'S67_02_1.3.K.2024' --1.3住房租赁购买贷款
       WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' THEN
        'S67_02_1.5.K.2024' --1.5其他
     END AS ITEM_NUM,
     SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
      FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
     INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
        ON T1.LOAN_NUM = T2.LOAN_NUM
       AND T1.DATA_DATE = T2.DATA_DATE
      LEFT JOIN SMTMODS_L_PUBL_RATE U
        ON T2.DATA_DATE = U.DATA_DATE
       AND U.CCY_DATE = D_DATADATE_CCY
       AND U.BASIC_CCY = T2.CURR_CD --基准币种
       AND U.FORWARD_CCY = 'CNY' --折算币种
     WHERE T1.DATA_DATE = I_DATADATE
       AND T2.CANCEL_FLG = 'N'
       AND LENGTHB(T2.ACCT_NUM) < 36
       AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
       AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
       AND T2.OD_DAYS <= V_MONTH_DAYS --逾期天数在本月内
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
     GROUP BY T2.ORG_NUM,
              CASE
                WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A' THEN
                 'S67_02_1.1.K.2024' --1.1住房租赁开发贷款
                WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B' THEN
                 'S67_02_1.2.K.2024' --1.2住房租赁经营贷款
                WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D' THEN
                 'S67_02_1.3.K.2024' --1.3住房租赁购买贷款
                WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'E' THEN
                 'S67_02_1.5.K.2024' --1.5其他
              END;

    COMMIT;
    --其中：当月新增逾期金额
    --【个人住房逾期90天内取逾期金额，90天以上取贷款余额】
    --逾期90天以内取逾期金额
    --1.4住房租赁消费贷款
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             T2.ORG_NUM,
             'S67_02_1.4.K.2024'  AS ITEM_NUM,
             SUM(T2.OD_LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --逾期金额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'C' --住房租赁消费贷款
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
         AND T2.OD_DAYS <= V_MONTH_DAYS --逾期天数在本月内
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;

    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '附注2逻辑全部处理完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


 ----------ADD BY DJH 20230417  房地产企业债券

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '3.1.1 其中：房地产企业债券.本期开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


 --3.1.1 其中：房地产企业债券 本期
 INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
   (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
   select  I_DATADATE,
          A.ORG_NUM,
          'S67_3.1.1.A.2021' AS ITEM_NUM,
          SUM(A.INV_AMT * U.CCY_RATE) AS INV_AMT --穿透后余额
     FROM SMTMODS_L_FIMM_FIN_PENE A --理财资金投资穿透信息表
    INNER JOIN SMTMODS_L_FIMM_PRODUCT B --理财产品信息表
       ON A.PRODUCT_CODE = B.PRODUCT_CODE
      AND B.DATA_DATE = I_DATADATE
     LEFT JOIN SMTMODS_L_PUBL_RATE U
       ON A.DATA_DATE = U.DATA_DATE
      AND U.CCY_DATE = D_DATADATE_CCY
      AND U.BASIC_CCY = A.CURR_CD --基准币种
      AND U.FORWARD_CCY = 'CNY' --折算币种
    WHERE  A.DATA_DATE = I_DATADATE
      AND SUBSTR(A.DATA_TYP, 1, 3) = 'A04' --资产负债类型是‘债券’,
      AND A.FDCFX_FLG = 'Y' --是否房地产企业发行是‘是’
      AND B.PROCEEDS_CHARACTER = 'c' --收益特征是‘非保本浮动收益类’,
      AND B.BANK_ISSUE_FLG = 'Y' --本行发行标识是 ‘是’
      GROUP BY A.ORG_NUM;
 COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '3.1.1 其中：房地产企业债券.本期完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  --3.1.1其中：房地产企业债券.展期

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '其中：房地产企业债券.展期开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
     (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
     select  I_DATADATE,
            A.ORG_NUM AS ORG_NUM, --机构号
            'S67_3.1.1.L.2021' AS ITEM_NUM, --指标编号
          SUM(A.INV_AMT * U.CCY_RATE) AS INV_AMT --穿透后余额
       FROM SMTMODS_L_FIMM_FIN_PENE A --理财资金投资穿透信息表
      INNER JOIN SMTMODS_L_FIMM_PRODUCT B --理财产品信息表
         ON A.PRODUCT_CODE = B.PRODUCT_CODE
        AND B.DATA_DATE = I_DATADATE
       LEFT JOIN SMTMODS_L_PUBL_RATE U
         ON A.DATA_DATE = U.DATA_DATE
        AND U.BASIC_CCY = A.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE A.DATA_DATE = I_DATADATE
        AND SUBSTR(A.DATA_TYP, 1, 3) = 'A04'
        AND B.PROCEEDS_CHARACTER = 'c'
        AND B.BANK_ISSUE_FLG = 'Y'
        AND A.FDCFX_FLG = 'Y'
        AND A.EXTENDTERM_FLG = 'Y' --展期
        GROUP BY A.ORG_NUM;

     COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '其中：房地产企业债券.展期完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  -- 3.1.1其中：房地产企业债券.逾期情况.逾期余额

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '其中：房地产企业债券.逾期余额开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

   INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
     (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
     select  I_DATADATE,
            A.ORG_NUM AS ORG_NUM, --机构号
              'S67_3.1.1.M.2021' AS ITEM_NUM, --指标编号
          SUM(A.INV_AMT * U.CCY_RATE) AS INV_AMT --穿透后余额
       FROM SMTMODS_L_FIMM_FIN_PENE A --理财资金投资穿透信息表
      INNER JOIN SMTMODS_L_FIMM_PRODUCT B --理财产品信息表
         ON A.PRODUCT_CODE = B.PRODUCT_CODE
        AND B.DATA_DATE = I_DATADATE
       LEFT JOIN SMTMODS_L_PUBL_RATE U
         ON A.DATA_DATE = U.DATA_DATE
        AND U.BASIC_CCY = A.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE A.DATA_DATE = I_DATADATE
        AND SUBSTR(A.DATA_TYP, 1, 3) = 'A04'
        AND B.PROCEEDS_CHARACTER = 'c'
        AND B.BANK_ISSUE_FLG = 'Y'
        AND A.FDCFX_FLG = 'Y'
        AND A.OD_DAYS > 0  --逾期
        GROUP BY A.ORG_NUM;
   COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '其中：房地产企业债券.逾期余额完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '其中：房地产企业债券.逾期天数开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select  I_DATADATE,
             A.ORG_NUM AS ORG_NUM, --机构号
             CASE
               WHEN A.OD_DAYS <= 30 THEN  --3.1.1其中：房地产企业债券.逾期情况.逾期1-30天
                'S67_3.1.1.N.2021'
               WHEN A.OD_DAYS <= 60 THEN --3.1.1其中：房地产企业债券.逾期情况.逾期31-60天
                'S67_3.1.1.O.2021'
               WHEN A.OD_DAYS <= 90 THEN --3.1.1其中：房地产企业债券.逾期情况.逾期61-90天
                'S67_3.1.1.P.2021'
               WHEN A.OD_DAYS <= 180 THEN --3.1.1其中：房地产企业债券.逾期情况.逾期91-180天
                'S67_3.1.1.Q.2021'
               WHEN A.OD_DAYS <= 360 THEN --3.1.1其中：房地产企业债券.逾期情况.逾期181-360天
                'S67_3.1.1.R.2021'
               WHEN A.OD_DAYS > 360 THEN --3.1.1其中：房地产企业债券.逾期情况.逾期361天以上
                'S67_3.1.1.S.2021'
             END AS ITEM_NUM, --指标编号
             SUM(A.INV_AMT * U.CCY_RATE) AS INV_AMT --穿透后余额
        FROM SMTMODS_L_FIMM_FIN_PENE A --理财资金投资穿透信息表
       INNER JOIN SMTMODS_L_FIMM_PRODUCT B --理财产品信息表
          ON A.PRODUCT_CODE = B.PRODUCT_CODE
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON A.DATA_DATE = U.DATA_DATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(A.DATA_TYP, 1, 3) = 'A04'
         AND B.PROCEEDS_CHARACTER = 'c'
         AND B.BANK_ISSUE_FLG = 'Y'
         AND A.FDCFX_FLG = 'Y'
         AND A.OD_DAYS > 0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.OD_DAYS <= 30 THEN
                   'S67_3.1.1.N.2021'
                  WHEN A.OD_DAYS <= 60 THEN
                   'S67_3.1.1.O.2021'
                  WHEN A.OD_DAYS <= 90 THEN
                   'S67_3.1.1.P.2021'
                  WHEN A.OD_DAYS <= 180 THEN
                   'S67_3.1.1.Q.2021'
                  WHEN A.OD_DAYS <= 360 THEN
                   'S67_3.1.1.R.2021'
                  WHEN A.OD_DAYS > 360 THEN
                   'S67_3.1.1.S.2021'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '其中：房地产企业债券.逾期天数完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


   ------------------------------ALTER BY DJH 20240115
   --1.1.1.1其中：棚户区改造贷款
   --1.2.1.1.1  其中：棚户区改造贷款
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.1.1.1其中：棚户区改造,1.2.1.1.1  其中：棚户区改造贷款贷款期末余额至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --期末余额情况
    --本期
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
          'S67_1.1.1.1.A.2024'
         ELSE
          'S67_1.2.1.1.1.A.2024'
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE --取本期
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND T1.PROPERTYLOAN_TYP IN ('1025', '1115') --1025  棚户区改造贷款-土地开发 1115 棚户区改造贷款-住房开发
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
                   'S67_1.1.1.1.A.2024'
                  ELSE
                   'S67_1.2.1.1.1.A.2024'
                END;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.1.1.1其中：棚户区改造,1.2.1.1.1  其中：棚户区改造贷款贷款期末余额至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.1.1.1其中：棚户区改造,1.2.1.1.1  其中：棚户区改造贷款贷款发放与收回至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --发放与收回情况
    --当月新发放金额
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
          'S67_1.1.1.1.B.2024'
         ELSE
          'S67_1.2.1.1.1.B.2024'
       END AS ITEM_NUM,
       SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND T1.PROPERTYLOAN_TYP IN ('1025', '1115') --1025  棚户区改造贷款-土地开发 1115 棚户区改造贷款-住房开发
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
                   'S67_1.1.1.1.B.2024'
                  ELSE
                   'S67_1.2.1.1.1.B.2024'
                END;
    COMMIT;

    --当月新收回金额
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
          'S67_1.1.1.1.C.2024'
         ELSE
          'S67_1.2.1.1.1.C.2024'
       END AS ITEM_NUM,
       SUM(T2.PAY_AMT) AS PAY_AMT --本金金额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1 --房地产贷款补充信息
       INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM T2 --贷款还款明细信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
       WHERE T1.DATA_DATE = I_DATADATE
         AND SUBSTR(TO_CHAR(T2.REPAY_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
         AND T2.DATA_DATE = TO_CHAR(REPAY_DT, 'YYYYMMDD')
         AND T1.PROPERTYLOAN_TYP IN ('1025', '1115') --1025  棚户区改造贷款-土地开发 1115 棚户区改造贷款-住房开发
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
                   'S67_1.1.1.1.C.2024'
                  ELSE
                   'S67_1.2.1.1.1.C.2024'
                END;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.1.1.1其中：棚户区改造,1.2.1.1.1  其中：棚户区改造贷款贷款发放与收回至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.1.1.1其中：棚户区改造,1.2.1.1.1  其中：棚户区改造贷款贷款五级分类情况至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --贷款五级分类情况
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      select 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN T1.PROPERTYLOAN_TYP = '1025' AND T2.LOAN_GRADE_CD = '1' THEN
          'S67_1.1.1.1.E.2024' --正常贷款
         WHEN T1.PROPERTYLOAN_TYP = '1025' AND T2.LOAN_GRADE_CD = '2' THEN
          'S67_1.1.1.1.F.2024' --关注贷款
         WHEN T1.PROPERTYLOAN_TYP = '1025' AND
              T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
          'S67_1.1.1.1.G.2024' --不良贷款
         WHEN T1.PROPERTYLOAN_TYP = '1115' AND T2.LOAN_GRADE_CD = '1' THEN
          'S67_1.2.1.1.1.E.2024' --正常贷款
         WHEN T1.PROPERTYLOAN_TYP = '1115' AND T2.LOAN_GRADE_CD = '2' THEN
          'S67_1.2.1.1.1.F.2024' --关注贷款
         WHEN T1.PROPERTYLOAN_TYP = '1115' AND
              T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
          'S67_1.2.1.1.1.G.2024' --不良贷款
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND T1.PROPERTYLOAN_TYP IN ('1025', '1115') --1025  棚户区改造贷款-土地开发 1115 棚户区改造贷款-住房开发
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T1.PROPERTYLOAN_TYP = '1025' AND
                       T2.LOAN_GRADE_CD = '1' THEN
                   'S67_1.1.1.1.E.2024' --正常贷款
                  WHEN T1.PROPERTYLOAN_TYP = '1025' AND
                       T2.LOAN_GRADE_CD = '2' THEN
                   'S67_1.1.1.1.F.2024' --关注贷款
                  WHEN T1.PROPERTYLOAN_TYP = '1025' AND
                       T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                   'S67_1.1.1.1.G.2024' --不良贷款
                  WHEN T1.PROPERTYLOAN_TYP = '1115' AND
                       T2.LOAN_GRADE_CD = '1' THEN
                   'S67_1.2.1.1.1.E.2024' --正常贷款
                  WHEN T1.PROPERTYLOAN_TYP = '1115' AND
                       T2.LOAN_GRADE_CD = '2' THEN
                   'S67_1.2.1.1.1.F.2024' --关注贷款
                  WHEN T1.PROPERTYLOAN_TYP = '1115' AND
                       T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                   'S67_1.2.1.1.1.G.2024' --不良贷款
                END;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.1.1.1其中：棚户区改造,1.2.1.1.1  其中：棚户区改造贷款贷款五级分类情况至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.1.1.1其中：棚户区改造,1.2.1.1.1  其中：棚户区改造贷款贷款贷款展期至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --展期
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT  I_DATADATE,
             T2.ORG_NUM,
             CASE
                  WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
                   'S67_1.1.1.1.H.2024'
                  ELSE
                   'S67_1.2.1.1.1.H.2024'
                END ITEM_NUM,
             SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND T1.PROPERTYLOAN_TYP IN ('1025', '1115') --1025  棚户区改造贷款-土地开发 1115 棚户区改造贷款-住房开发
         AND EXTENDTERM_FLG = 'Y' --展期
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
                   'S67_1.1.1.1.H.2024'
                  ELSE
                   'S67_1.2.1.1.1.H.2024'
                END;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.1.1.1其中：棚户区改造,1.2.1.1.1  其中：棚户区改造贷款贷款展期至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.1.1.1其中：棚户区改造,1.2.1.1.1  其中：棚户区改造贷款逾期至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --逾期情况
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN T1.PROPERTYLOAN_TYP = '1025'  THEN
          'S67_1.1.1.1.J.2024' --逾期贷款
         WHEN T1.PROPERTYLOAN_TYP = '1115'  THEN
          'S67_1.2.1.1.1.J.2024' --逾期贷款
         WHEN T1.PROPERTYLOAN_TYP = '1025' AND T2.OD_DAYS > 90 THEN
          'S67_1.1.1.1.N.2024' --1.1.1.1其中：棚户区改造 逾期91天以上
         WHEN T1.PROPERTYLOAN_TYP = '1115' AND T2.OD_DAYS > 90 THEN
          'S67_1.2.1.1.1.N.2024' --1.2.1.1.1  其中：棚户区改造贷款 逾期91天以上
         WHEN T1.PROPERTYLOAN_TYP = '1025' AND T2.OD_DAYS > 60 THEN
          'S67_1.1.1.1.M.2024' --1.1.1.1其中：棚户区改造 逾期61-90天
         WHEN T1.PROPERTYLOAN_TYP = '1115' AND T2.OD_DAYS > 60 THEN
          'S67_1.2.1.1.1.M.2024' --1.2.1.1.1  其中：棚户区改造贷款 逾期61-90天
         WHEN T1.PROPERTYLOAN_TYP = '1025' AND T2.OD_DAYS > 0 THEN
          'S67_1.1.1.1.L.2024' --1.1.1.1其中：棚户区改造 逾期1-60天
         WHEN T1.PROPERTYLOAN_TYP = '1115' AND T2.OD_DAYS > 0 THEN
          'S67_1.2.1.1.1.L.2024' --1.2.1.1.1  其中：棚户区改造贷款 逾期1-60天
       END ITEM_NUM,
       ---SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
      /*alter by shiyu 20241105 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
            如果是按月分期还款的个人消费贷款本金或利息逾期 */
       sum(case when (t2.ACCT_TYP LIKE '0101%' OR t2.ACCT_TYP LIKE '0103%' OR
             t2.ACCT_TYP LIKE '0104%' OR t2.ACCT_TYP LIKE '0199%'
             )
             and t2.REPAY_TYP ='1' --按月支付
             and t2.od_days <= 90
             then t2.OD_LOAN_ACCT_BAL * U.CCY_RATE
             else t2.loan_acct_bal* U.CCY_RATE end )

        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND T1.PROPERTYLOAN_TYP IN ('1025', '1115') --1025  棚户区改造贷款-土地开发 1115 棚户区改造贷款-住房开发
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T1.PROPERTYLOAN_TYP = '1025'  THEN
                   'S67_1.1.1.1.J.2024' --逾期贷款
                  WHEN T1.PROPERTYLOAN_TYP = '1115'  THEN
                   'S67_1.2.1.1.1.J.2024' --逾期贷款
                  WHEN T1.PROPERTYLOAN_TYP = '1025' AND T2.OD_DAYS > 90 THEN
                   'S67_1.1.1.1.N.2024' --1.1.1.1其中：棚户区改造 逾期91天以上
                  WHEN T1.PROPERTYLOAN_TYP = '1115' AND T2.OD_DAYS > 90 THEN
                   'S67_1.2.1.1.1.N.2024' --1.2.1.1.1  其中：棚户区改造贷款 逾期91天以上
                  WHEN T1.PROPERTYLOAN_TYP = '1025' AND T2.OD_DAYS > 60 THEN
                   'S67_1.1.1.1.M.2024' --1.1.1.1其中：棚户区改造 逾期61-90天
                  WHEN T1.PROPERTYLOAN_TYP = '1115' AND T2.OD_DAYS > 60 THEN
                   'S67_1.2.1.1.1.M.2024' --1.2.1.1.1  其中：棚户区改造贷款 逾期61-90天
                  WHEN T1.PROPERTYLOAN_TYP = '1025' AND T2.OD_DAYS > 0 THEN
                   'S67_1.1.1.1.L.2024' --1.1.1.1其中：棚户区改造 逾期1-60天
                  WHEN T1.PROPERTYLOAN_TYP = '1115' AND T2.OD_DAYS > 0 THEN
                   'S67_1.2.1.1.1.L.2024' --1.2.1.1.1  其中：棚户区改造贷款 逾期1-60天
                END;
    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.1.1.1其中：棚户区改造,1.2.1.1.1  其中：棚户区改造贷款贷款逾期至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   --5.保障性安居工程贷款合计  土地+住房+租赁+3031 其中：农村危房改造贷款 3032  其中：游牧民定居工程贷款 初始化公式处理
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据5.保障性安居工程贷款期末余额至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --期末余额情况
    --本期
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       'S67_5.A.2024' AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE --取本期
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('102', '111') OR --102  保障性安居工程土地开发贷款  111  保障性住房开发贷款
             SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2012', '2022') OR --2012  企业收购保障性住房贷款  2022 机关团体收购保障性住房贷款
             T1.PROPERTYLOAN_TYP IN ('3031', '3032') OR --3031 其中：农村危房改造贷款 3032  其中：游牧民定居工程贷款
             SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) IN ('A01', 'B01', 'D01')) --住房租赁支持贷款分类 A01 保障性租赁住房开发贷款 B01 保障性租赁住房经营贷款 D01 保障性租赁住房购买贷款
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;

    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据5.保障性安居工程贷款期末余额至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '3.个人住房贷款提前还款情况开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  --3、个人住房提前还款情况
      INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
        (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
        SELECT I_DATADATE,
               LAL.ORG_NUM,
               'S67_0_3.C.2024' AS ITEM_NUM,
               SUM(LTLP.PAY_AMT) AS ITEM_VAL
          FROM SMTMODS_L_ACCT_LOAN_REALESTATE LALR --房地产贷款补充信息
         INNER JOIN SMTMODS_L_ACCT_LOAN LAL --贷款借据信息表
            ON LALR.ACCT_NUM = LAL.ACCT_NUM
           AND LAL.DATA_DATE = I_DATADATE
         INNER JOIN (SELECT LOAN_NUM, SUM(PAY_AMT) AS PAY_AMT
                       FROM SMTMODS_L_TRAN_LOAN_PAYM
                      WHERE TRUNC(REPAY_DT, 'MM') =
                            TRUNC(I_DATADATE, 'MM') --本月还款
                        AND PAY_TYPE IN ('02', '03') --提前还款(缩期) 03 提前还款(不缩期) 01正常收回
                      GROUP BY LOAN_NUM, PAY_TYPE) LTLP --贷款还款明细信息表
            ON LALR.LOAN_NUM = LTLP.LOAN_NUM
         WHERE LALR.PROPERTYLOAN_TYP IN ('2032',
                                         '2033',
                                         '203401',
                                         '203402',
                                         '203501',
                                         '203502',
                                         '2036')
           AND LALR.DATA_DATE = I_DATADATE
           AND (LAL.LOAN_ACCT_BAL <> 0 OR LAL.LOAN_ACCT_BAL = 0)
         GROUP BY LAL.ORG_NUM;
      COMMIT;

   /* 附注：  3.个人住房贷款提前还款情况
   3.1部分提前还款
   3.2全额提前还款*/
      INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
        (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
        SELECT I_DATADATE,
               LAL.ORG_NUM,
               CASE
                 WHEN LAL.LOAN_ACCT_BAL <> 0 THEN
                  'S67_0_3.1.C.2024'
                 WHEN LAL.LOAN_ACCT_BAL = 0 THEN
                  'S67_0_3.2.C.2024'
               END AS ITEM_NUM,
               SUM(LTLP.PAY_AMT) AS ITEM_VAL
          FROM SMTMODS_L_ACCT_LOAN_REALESTATE LALR --房地产贷款补充信息
         INNER JOIN SMTMODS_L_ACCT_LOAN LAL --贷款借据信息表
            ON LALR.LOAN_NUM = LAL.LOAN_NUM
           AND LAL.DATA_DATE = I_DATADATE
         INNER JOIN (SELECT LOAN_NUM, SUM(PAY_AMT) AS PAY_AMT
                       FROM SMTMODS_L_TRAN_LOAN_PAYM
                      WHERE TRUNC(REPAY_DT, 'MM') =
                            TRUNC(I_DATADATE, 'MM') --本月还款
                        AND PAY_TYPE IN ('02', '03') --提前还款(缩期) 03 提前还款(不缩期) 01正常收回
                      GROUP BY LOAN_NUM, PAY_TYPE) LTLP --贷款还款明细信息表
            ON LALR.LOAN_NUM = LTLP.LOAN_NUM
         WHERE LALR.PROPERTYLOAN_TYP IN ('2032',
                                         '2033',
                                         '203401',
                                         '203402',
                                         '203501',
                                         '203502',
                                         '2036')
           AND LALR.DATA_DATE = I_DATADATE
         GROUP BY LAL.ORG_NUM,
                  CASE
                    WHEN LAL.LOAN_ACCT_BAL <> 0 THEN
                     'S67_0_3.1.C.2024'
                    WHEN LAL.LOAN_ACCT_BAL = 0 THEN
                     'S67_0_3.2.C.2024'
                  END;
      COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '3.个人住房贷款提前还款情况完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 --alter by djh 20240115 附注
 --1.民营房企贷款业务情况
 --1.1向民营房企发放的对公贷款

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公贷款期末余额至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --期末余额情况
    --本期
   INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
     (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
     SELECT 
      I_DATADATE AS DATA_DATE,
      T.ORG_NUM,
      'S67_0_1.1.A.2024' AS ITEM_NUM,
      SUM(t.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
       FROM SMTMODS_L_ACCT_LOAN T
      INNER JOIN SMTMODS_L_CUST_C B
         ON T.CUST_ID = B.CUST_ID
        AND B.DATA_DATE = I_DATADATE
      INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
         ON T.LOAN_NUM = T1.LOAN_NUM
        AND T1.DATA_DATE = I_DATADATE
       LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE T.DATA_DATE = I_DATADATE
        AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
        AND T.CANCEL_FLG <> 'Y'
        AND T.ACCT_STS <> '3' --账户状态不为结清
        AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
        AND T.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
        AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股
            OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行/凯旋支行   历史遗留数据 没有集团信息，默认为微型企业
        AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
        AND B.CORP_SCALE IS NOT NULL --企业规模不为空
        AND B.CORP_SCALE <> 'Z'
        AND T.LOAN_ACCT_BAL > 0
        AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') --1.1 地产开发贷款
            OR (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
            ('111', '112', '113', '114', '119')  AND
            (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
            ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) --1.2 房产开发贷款
            OR
            (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y') --1.5.1 经营性物业贷款
            OR (T.LOAN_PURPOSE_CD LIKE 'K%' AND T.ACCT_TYP LIKE '0203%')) --K 行业类别是房地产业  --0203  并购贷款 --1.5.2 房地产并购贷款
    AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
      GROUP BY T.ORG_NUM;
  COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公贷款期末余额至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公贷款发放与收回至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --发放与收回情况
    --当月新发放金额
     INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
       (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
       SELECT 
        I_DATADATE AS DATA_DATE,
        T.ORG_NUM,
        'S67_0_1.1.B.2024' AS ITEM_NUM,
         SUM(T.DRAWDOWN_AMT * U.CCY_RATE) LOAN_ACCT_BAL_RMB
         FROM SMTMODS_L_ACCT_LOAN T
        INNER JOIN SMTMODS_L_CUST_C B
           ON T.CUST_ID = B.CUST_ID
          AND B.DATA_DATE = I_DATADATE
        INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
           ON T.LOAN_NUM = T1.LOAN_NUM
          AND T1.DATA_DATE = I_DATADATE
         LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
           ON U.CCY_DATE = I_DATADATE
          AND U.BASIC_CCY = T.CURR_CD --基准币种
          AND U.FORWARD_CCY = 'CNY' --折算币种
        WHERE T.DATA_DATE = I_DATADATE
          AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
          AND T.CANCEL_FLG <> 'Y'
          AND T.ACCT_STS <> '3' --账户状态不为结清
          AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
          AND T.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
          AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股
              OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行/凯旋支行   历史遗留数据 没有集团信息，默认为微型企业
          AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
          AND B.CORP_SCALE IS NOT NULL --企业规模不为空
          AND B.CORP_SCALE <> 'Z'
          AND T.LOAN_ACCT_BAL > 0
          AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') --1.1 地产开发贷款
              OR
              (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
              ('111', '112', '113', '114', '119') AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
              ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) --1.2 房产开发贷款
              OR
              (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y') --1.5.1 经营性物业贷款
              OR (T.LOAN_PURPOSE_CD LIKE 'K%' AND T.ACCT_TYP LIKE '0203%')) --K 行业类别是房地产业  --0203  并购贷款 --1.5.2 房地产并购贷款
          AND SUBSTR(TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = ---取当月
             SUBSTR(I_DATADATE, 1, 6)
      AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
        GROUP BY T.ORG_NUM;
  COMMIT;


    --当月新收回金额
   INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
     (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
     SELECT 
      I_DATADATE AS DATA_DATE,
      T.ORG_NUM,
      'S67_0_1.1.C.2024' AS ITEM_NUM,
      SUM(T2.PAY_AMT) AS PAY_AMT --本金金额
       FROM SMTMODS_L_ACCT_LOAN T
      INNER JOIN SMTMODS_L_CUST_C B
         ON T.CUST_ID = B.CUST_ID
        AND B.DATA_DATE = I_DATADATE
      INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
         ON T.LOAN_NUM = T1.LOAN_NUM
        AND T1.DATA_DATE = I_DATADATE
      INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM T2 --贷款还款明细信息表
         ON T1.LOAN_NUM = T2.LOAN_NUM
       LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE T.DATA_DATE = I_DATADATE
        AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
        AND T.CANCEL_FLG <> 'Y'
        AND T.ACCT_STS <> '3' --账户状态不为结清
        AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
        AND T.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
        AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股
            OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行/凯旋支行   历史遗留数据 没有集团信息，默认为微型企业
        AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
        AND B.CORP_SCALE IS NOT NULL --企业规模不为空
        AND B.CORP_SCALE <> 'Z'
        AND T.LOAN_ACCT_BAL > 0
        AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') --1.1 地产开发贷款
            OR (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
            ('111', '112', '113', '114', '119')  AND
            (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
            ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) --1.2 房产开发贷款
            OR
            (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y') --1.5.1 经营性物业贷款
            OR (T.LOAN_PURPOSE_CD LIKE 'K%' AND T.ACCT_TYP LIKE '0203%')) --K 行业类别是房地产业  --0203  并购贷款 --1.5.2 房地产并购贷款
        AND SUBSTR(TO_CHAR(T2.REPAY_DT, 'YYYYMMDD'), 1, 6) = ---取当月
            SUBSTR(I_DATADATE, 1, 6)
        AND T2.DATA_DATE = TO_CHAR(REPAY_DT, 'YYYYMMDD')
    AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
      GROUP BY T.ORG_NUM;
  COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公贷款发放与收回至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公其中：当月核销至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --20240205 其中：当月核销
   INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
     (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
     SELECT 
      I_DATADATE AS DATA_DATE,
      T.ORG_NUM,
      'S67_0_1.1.D.2024' AS ITEM_NUM,
      SUM(XX.DRAWDOWN_AMT) AS PAY_AMT --本金金额
       FROM SMTMODS_L_ACCT_LOAN T
      INNER JOIN SMTMODS_L_CUST_C B
         ON T.CUST_ID = B.CUST_ID
        AND B.DATA_DATE = I_DATADATE
      INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
         ON T.LOAN_NUM = T1.LOAN_NUM
        AND T1.DATA_DATE = I_DATADATE
      INNER JOIN SMTMODS_L_ACCT_WRITE_OFF XX
         ON T.LOAN_NUM = XX.LOAN_NUM
        AND XX.DATA_DATE = I_DATADATE
       LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE T.DATA_DATE = I_DATADATE
        AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
        AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
        AND T.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
        AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股
            OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行/凯旋支行   历史遗留数据 没有集团信息，默认为微型企业
        AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
        AND B.CORP_SCALE IS NOT NULL --企业规模不为空
        AND B.CORP_SCALE <> 'Z'
        AND T.LOAN_ACCT_BAL > 0
        AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') --1.1 地产开发贷款
            OR (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
            ('111', '112', '113', '114', '119') AND
            (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
            ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) --1.2 房产开发贷款
            OR
            (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y') --1.5.1 经营性物业贷款
            OR (T.LOAN_PURPOSE_CD LIKE 'K%' AND T.ACCT_TYP LIKE '0203%')) --K 行业类别是房地产业  --0203  并购贷款 --1.5.2 房地产并购贷款
        AND SUBSTR(TO_CHAR(XX.WRITE_OFF_DATE, 'YYYYMMDD'), 1, 6) =
            SUBSTR(I_DATADATE, 1, 6)  --当月核销
        AND T.CANCEL_FLG = 'Y'
      GROUP BY T.ORG_NUM;
  COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公贷款其中：当月核销至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公贷款五级分类情况至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --贷款五级分类情况
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN T2.LOAN_GRADE_CD = '1' THEN
          'S67_0_1.1.E.2024' --正常贷款
         WHEN T2.LOAN_GRADE_CD = '2' THEN
          'S67_0_1.1.F.2024' --关注贷款
         WHEN T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
          'S67_0_1.1.G.2024' --不良贷款
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN T2
       INNER JOIN SMTMODS_L_CUST_C B
          ON T2.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
          ON T2.LOAN_NUM = T1.LOAN_NUM
         AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T2.DATA_DATE = I_DATADATE
         AND T2.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T2.CANCEL_FLG <> 'Y'
         AND T2.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T2.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股
             OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行/凯旋支行   历史遗留数据 没有集团信息，默认为微型企业
         AND SUBSTR(T2.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T2.LOAN_ACCT_BAL > 0
         AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') --1.1 地产开发贷款
             OR
             (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
             ('111', '112', '113', '114', '119') AND
             (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
             T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) --1.2 房产开发贷款
             OR
             (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y') --1.5.1 经营性物业贷款
             OR (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%')) --K 行业类别是房地产业  --0203  并购贷款 --1.5.2 房地产并购贷款
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T2.LOAN_GRADE_CD = '1' THEN
                   'S67_0_1.1.E.2024' --正常贷款
                  WHEN T2.LOAN_GRADE_CD = '2' THEN
                   'S67_0_1.1.F.2024' --关注贷款
                  WHEN T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                   'S67_0_1.1.G.2024' --不良贷款
                END;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公贷款五级分类情况至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公贷款展期至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --展期
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       'S67_0_1.1.H.2024' AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN T2
       INNER JOIN SMTMODS_L_CUST_C B
          ON T2.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
          ON T2.LOAN_NUM = T1.LOAN_NUM
         AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T2.DATA_DATE = I_DATADATE
         AND T2.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T2.CANCEL_FLG <> 'Y'
         AND T2.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T2.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股
             OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行/凯旋支行   历史遗留数据 没有集团信息，默认为微型企业
         AND SUBSTR(T2.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T2.LOAN_ACCT_BAL > 0
         AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') --1.1 地产开发贷款
             OR
             (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
             ('111', '112', '113', '114', '119')  AND
             (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
             T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) --1.2 房产开发贷款
             OR
             (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y') --1.5.1 经营性物业贷款
             OR (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%')) --K 行业类别是房地产业  --0203  并购贷款 --1.5.2 房地产并购贷款
         AND EXTENDTERM_FLG = 'Y' --展期
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;

    COMMIT;
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公贷款其中：当月新增展期金额至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   --20240205其中：当月新增展期金额
   INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
     (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
     SELECT 
      I_DATADATE AS DATA_DATE,
      T2.ORG_NUM,
      'S67_0_1.1.I.2024' AS ITEM_NUM,
      SUM(XX.EXTENT_AMT * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
       FROM SMTMODS_L_ACCT_LOAN T2
      INNER JOIN SMTMODS_L_CUST_C B
         ON T2.CUST_ID = B.CUST_ID
        AND B.DATA_DATE = I_DATADATE
      INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
         ON T2.LOAN_NUM = T1.LOAN_NUM
        AND T1.DATA_DATE = I_DATADATE
      INNER JOIN SMTMODS_L_ACCT_LOAN_EXTENDTERM XX
         ON T2.LOAN_NUM = XX.LOAN_NUM
        AND XX.DATA_DATE = I_DATADATE
       LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
         ON U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T2.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE T2.DATA_DATE = I_DATADATE
        AND T2.ACCT_TYP NOT LIKE '90%' --委托贷款
        AND T2.CANCEL_FLG <> 'Y'
        AND T2.ACCT_STS <> '3' --账户状态不为结清
        AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
        AND T2.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
        AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股
            OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行/凯旋支行   历史遗留数据 没有集团信息，默认为微型企业
        AND SUBSTR(T2.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
        AND B.CORP_SCALE IS NOT NULL --企业规模不为空
        AND B.CORP_SCALE <> 'Z'
        AND T2.LOAN_ACCT_BAL > 0
        AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') --1.1 地产开发贷款
            OR (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
            ('111', '112', '113', '114', '119') AND
            (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
            ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) --1.2 房产开发贷款
            OR
            (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y') --1.5.1 经营性物业贷款
            OR (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%')) --K 行业类别是房地产业  --0203  并购贷款 --1.5.2 房地产并购贷款
        AND EXTENDTERM_FLG = 'Y' --展期
        AND SUBSTR(TO_CHAR(XX.EXTENT_START_DT, 'YYYYMMDD'), 1, 6) =
            SUBSTR(I_DATADATE, 1, 6)
    AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
      GROUP BY T2.ORG_NUM;

   COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公贷款其中：当月新增展期金额至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公贷款展期至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公贷款逾期至CBRC_S67_DATA_COLLECT_TMP中间表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

      --逾期贷款
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       'S67_0_1.1.J.2024' ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN T2
       INNER JOIN SMTMODS_L_CUST_C B
          ON T2.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
          ON T2.LOAN_NUM = T1.LOAN_NUM
         AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T2.DATA_DATE = I_DATADATE
         AND T2.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T2.CANCEL_FLG <> 'Y'
         AND T2.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T2.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股
             OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行/凯旋支行   历史遗留数据 没有集团信息，默认为微型企业
         AND SUBSTR(T2.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T2.LOAN_ACCT_BAL > 0
         AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') --1.1 地产开发贷款
             OR
             (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
             ('111', '112', '113', '114', '119') AND
             (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
             T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) --1.2 房产开发贷款
             OR
             (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y') --1.5.1 经营性物业贷款
             OR (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%')) --K 行业类别是房地产业  --0203  并购贷款 --1.5.2 房地产并购贷款
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;
      COMMIT;

    --逾期情况
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN T2.OD_DAYS > 90 THEN
          'S67_0_1.1.N.2024' --1.1向民营房企发放的对公贷款 逾期91天以上
         WHEN T2.OD_DAYS > 60 THEN
          'S67_0_1.1.M.2024' --1.1向民营房企发放的对公贷款 逾期61-90天
         WHEN T2.OD_DAYS > 0 THEN
          'S67_0_1.1.L.2024' --1.1向民营房企发放的对公贷款 逾期1-60天
       END ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN T2
       INNER JOIN SMTMODS_L_CUST_C B
          ON T2.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
          ON T2.LOAN_NUM = T1.LOAN_NUM
         AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T2.DATA_DATE = I_DATADATE
         AND T2.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T2.CANCEL_FLG <> 'Y'
         AND T2.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T2.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股
             OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行/凯旋支行   历史遗留数据 没有集团信息，默认为微型企业
         AND SUBSTR(T2.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T2.LOAN_ACCT_BAL > 0
         AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') --1.1 地产开发贷款
             OR
             (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
             ('111', '112', '113', '114', '119')  AND
             (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
             T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) --1.2 房产开发贷款
             OR
             (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y') --1.5.1 经营性物业贷款
             OR (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%')) --K 行业类别是房地产业  --0203  并购贷款 --1.5.2 房地产并购贷款
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN T2.OD_DAYS > 90 THEN
                   'S67_0_1.1.N.2024' --1.1向民营房企发放的对公贷款 逾期91天以上
                  WHEN T2.OD_DAYS > 60 THEN
                   'S67_0_1.1.M.2024' --1.1向民营房企发放的对公贷款 逾期61-90天
                  WHEN T2.OD_DAYS > 0 THEN
                   'S67_0_1.1.L.2024' --1.1向民营房企发放的对公贷款 逾期1-60天
                END;
    COMMIT;

     --20240205其中：当月新增逾期金额
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       'S67_0_1.1.K.2024' ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN T2
       INNER JOIN SMTMODS_L_CUST_C B
          ON T2.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATADATE
       INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
          ON T2.LOAN_NUM = T1.LOAN_NUM
         AND T1.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T2.DATA_DATE = I_DATADATE
         AND T2.ACCT_TYP NOT LIKE '90%' --委托贷款
         AND T2.CANCEL_FLG <> 'Y'
         AND T2.ACCT_STS <> '3' --账户状态不为结清
         AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
         AND T2.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
         AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股
             OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行/凯旋支行   历史遗留数据 没有集团信息，默认为微型企业
         AND SUBSTR(T2.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
         AND B.CORP_SCALE IS NOT NULL --企业规模不为空
         AND B.CORP_SCALE <> 'Z'
         AND T2.LOAN_ACCT_BAL > 0
         AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') --1.1 地产开发贷款
             OR
             (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
             ('111', '112', '113', '114', '119') AND
             (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
             T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) --1.2 房产开发贷款
             OR
             (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y') --1.5.1 经营性物业贷款
             OR (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%')) --K 行业类别是房地产业  --0203  并购贷款 --1.5.2 房地产并购贷款
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
         AND T2.OD_DAYS <= V_MONTH_DAYS --逾期天数在本月内
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;
      COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '提取数据1.1向民营房企发放的对公贷款逾期至CBRC_S67_DATA_COLLECT_TMP中间表完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

/* --1.2民营房企开发项目相关的个人住房贷款
 INSERT INTO CBRC_S67_DATA_COLLECT_TMP
   (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
   SELECT \*+ parallel(8) *\
    I_DATADATE AS DATA_DATE,
    T.ORG_NUM,
    'S67_0_1.2.A.2024' AS ITEM_NUM,
    SUM(t.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
     FROM SMTMODS_L_ACCT_LOAN T
    INNER JOIN SMTMODS_L_CUST_C B
       ON T.CUST_ID = B.CUST_ID
      AND B.DATA_DATE = I_DATADATE
    INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
       ON T.LOAN_NUM = T1.LOAN_NUM
      AND T1.DATA_DATE = I_DATADATE
     LEFT JOIN SMTMODS_L_PUBL_RATE U --汇率表
       ON U.CCY_DATE = I_DATADATE
      AND U.BASIC_CCY = T.CURR_CD --基准币种
      AND U.FORWARD_CCY = 'CNY' --折算币种
    WHERE T.DATA_DATE = I_DATADATE
      AND T.ACCT_TYP NOT LIKE '90%' --委托贷款
      AND T.CANCEL_FLG <> 'Y'
      AND T.ACCT_STS <> '3' --账户状态不为结清
      AND SUBSTR(B.CUST_TYP, 1, 1) IN ('1', '0') --M2
      AND T.ACCT_TYP NOT IN ('B01', 'D01', 'E01', 'E02') -- 'E01' 个人信用卡透支        'E02' --单位信用卡透支
      AND (B.CORP_HOLD_TYPE LIKE 'C%' --私人控股
          OR B.CUST_ID = '8500054441' OR B.CUST_ID = '8000575302') --松原前郭支行/凯旋支行   历史遗留数据 没有集团信息，默认为微型企业
      AND SUBSTR(T.ITEM_CD, 1, 6) NOT IN ('130102', '130105') --刨除票据转贴现  M4
      AND B.CORP_SCALE IS NOT NULL --企业规模不为空
      AND B.CORP_SCALE <> 'Z'
      AND T.LOAN_ACCT_BAL > 0
      AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
          ('2032', '2033', '2034', '2035', '2036') --个人住房贷款
    GROUP BY T.ORG_NUM;*/


 ------第II部分 住房租赁融资情况(保障性)数据开发
 --1.1.1 其中：保障性租赁住房开发贷款
 --1.2.1 其中：保障性租赁住房经营贷款
 --1.3.1 其中：保障性租赁住房购买贷款
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '第II部分 住房租赁融资情况(保障性)处理开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   --期末余额情况
    /*INSERT \*+ APPEND*\
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT \*+PARALLEL(4)*\
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
          'S67_02_1.1.1.A.2022' --1.1.1 其中：保障性租赁住房开发贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' THEN
          'S67_02_1.2.1.A.2022' --1.2.1 其中：保障性租赁住房经营贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' THEN
          'S67_02_1.3.1.A.2022' --1.3.1 其中：保障性租赁住房购买贷款
       END ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T1.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0
         AND SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) IN ('A01', 'B01', 'D01') --住房租赁支持贷款分类
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
                   'S67_02_1.1.1.A.2022' --1.1.1 其中：保障性租赁住房开发贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' THEN
                   'S67_02_1.2.1.A.2022' --1.2.1 其中：保障性租赁住房经营贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' THEN
                   'S67_02_1.3.1.A.2022' --1.3.1 其中：保障性租赁住房购买贷款
                END;

    COMMIT;*/
    --当月新发放金额

    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
          'S67_02_1.1.1.C.2022' --1.1.1 其中：保障性租赁住房开发贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' THEN
          'S67_02_1.2.1.C.2022' --1.2.1 其中：保障性租赁住房经营贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' THEN
          'S67_02_1.3.1.C.2022' --1.3.1 其中：保障性租赁住房购买贷款
       END ITEM_NUM,
       SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --放款金额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0
         AND T2.ACCT_STS <> '3' --结清
         AND T2.LOAN_ACCT_BAL > 0 --取报告期末仍然未收回的贷款金额
         AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) =
             V_DATADATE_M ---取当月
         AND SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) IN('A01','B01','D01')--住房租赁支持贷款分类
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
                   'S67_02_1.1.1.C.2022' --1.1.1 其中：保障性租赁住房开发贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' THEN
                   'S67_02_1.2.1.C.2022' --1.2.1 其中：保障性租赁住房经营贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' THEN
                   'S67_02_1.3.1.C.2022' --1.3.1 其中：保障性租赁住房购买贷款
                END;

    COMMIT;


    --贷款五级分类情况

    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' AND
              T2.LOAN_GRADE_CD = '1' THEN --住房租赁支持贷款分类
          'S67_02_1.1.1.F.2022' --1.1.1 其中：保障性租赁住房开发贷款 五级分类 正常类
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' AND
              T2.LOAN_GRADE_CD = '1' THEN
          'S67_02_1.2.1.F.2022' --1.2.1 其中：保障性租赁住房经营贷款 五级分类 正常类
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' AND
              T2.LOAN_GRADE_CD = '1' THEN
          'S67_02_1.3.1.F.2022' --1.3.1 其中：保障性租赁住房购买贷款 五级分类 正常类
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' AND
              T2.LOAN_GRADE_CD = '2' THEN --住房租赁支持贷款分类
          'S67_02_1.1.1.G.2022' --1.1.1 其中：保障性租赁住房开发贷款 五级分类 关注类
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' AND
              T2.LOAN_GRADE_CD = '2' THEN
          'S67_02_1.2.1.G.2022' --1.2.1 其中：保障性租赁住房经营贷款 五级分类 关注类
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' AND
              T2.LOAN_GRADE_CD = '2' THEN
          'S67_02_1.3.1.G.2022' --1.3.1 其中：保障性租赁住房购买贷款 五级分类 关注类
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' AND
              T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN --住房租赁支持贷款分类
          'S67_02_1.1.1.H.2022' --1.1.1 其中：保障性租赁住房开发贷款 五级分类 不良
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' AND
              T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
          'S67_02_1.2.1.H.2022' --1.2.1 其中：保障性租赁住房经营贷款 五级分类 不良
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' AND
              T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
          'S67_02_1.3.1.H.2022' --1.3.1 其中：保障性租赁住房购买贷款 五级分类 不良
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0
         AND SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) IN ('A01', 'B01', 'D01') --住房租赁支持贷款分类
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' AND
                       T2.LOAN_GRADE_CD = '1' THEN --住房租赁支持贷款分类
                   'S67_02_1.1.1.F.2022' --1.1.1 其中：保障性租赁住房开发贷款 五级分类 正常类
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' AND
                       T2.LOAN_GRADE_CD = '1' THEN
                   'S67_02_1.2.1.F.2022' --1.2.1 其中：保障性租赁住房经营贷款 五级分类 正常类
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' AND
                       T2.LOAN_GRADE_CD = '1' THEN
                   'S67_02_1.3.1.F.2022' --1.3.1 其中：保障性租赁住房购买贷款 五级分类 正常类
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' AND
                       T2.LOAN_GRADE_CD = '2' THEN --住房租赁支持贷款分类
                   'S67_02_1.1.1.G.2022' --1.1.1 其中：保障性租赁住房开发贷款 五级分类 关注类
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' AND
                       T2.LOAN_GRADE_CD = '2' THEN
                   'S67_02_1.2.1.G.2022' --1.2.1 其中：保障性租赁住房经营贷款 五级分类 关注类
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' AND
                       T2.LOAN_GRADE_CD = '2' THEN
                   'S67_02_1.3.1.G.2022' --1.3.1 其中：保障性租赁住房购买贷款 五级分类 关注类
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' AND
                       T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN --住房租赁支持贷款分类
                   'S67_02_1.1.1.H.2022' --1.1.1 其中：保障性租赁住房开发贷款 五级分类 不良
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' AND
                       T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                   'S67_02_1.2.1.H.2022' --1.2.1 其中：保障性租赁住房经营贷款 五级分类 不良
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' AND
                       T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                   'S67_02_1.3.1.H.2022' --1.3.1 其中：保障性租赁住房购买贷款 五级分类 不良
                END;

    COMMIT;

    --展期贷款

    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
          'S67_02_1.1.1.L.2022' --1.1.1 其中：保障性租赁住房开发贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' THEN
          'S67_02_1.2.1.L.2022' --1.2.1 其中：保障性租赁住房经营贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' THEN
          'S67_02_1.3.1.L.2022' --1.3.1 其中：保障性租赁住房购买贷款
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0
         AND T2.EXTENDTERM_FLG = 'Y' --展期标志
         AND SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) IN ('A01', 'B01', 'D01') --住房租赁支持贷款分类
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
                   'S67_02_1.1.1.L.2022' --1.1.1 其中：保障性租赁住房开发贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' THEN
                   'S67_02_1.2.1.L.2022' --1.2.1 其中：保障性租赁住房经营贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' THEN
                   'S67_02_1.3.1.L.2022' --1.3.1 其中：保障性租赁住房购买贷款
                END;

    COMMIT;
    --其中：当月新增展期金额
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
          'S67_02_1.1.1.I.2024' --1.1.1 其中：保障性租赁住房开发贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' THEN
          'S67_02_1.2.1.I.2024' --1.2.1 其中：保障性租赁住房经营贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' THEN
          'S67_02_1.3.1.I.2024' --1.3.1 其中：保障性租赁住房购买贷款
       END AS ITEM_NUM,
       SUM(XX.EXTENT_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --展期金额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
       INNER JOIN SMTMODS_L_ACCT_LOAN_EXTENDTERM XX
          ON T1.LOAN_NUM = XX.LOAN_NUM
         AND XX.DATA_DATE = I_DATADATE
         AND SUBSTR(TO_CHAR(XX.EXTENT_START_DT, 'YYYYMMDD'), 1, 6) =
             SUBSTR(I_DATADATE, 1, 6)
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0
         AND T2.EXTENDTERM_FLG = 'Y' --展期标志
         AND SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) IN ('A01', 'B01', 'D01') --住房租赁支持贷款分类
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
                   'S67_02_1.1.1.I.2024' --1.1.1 其中：保障性租赁住房开发贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' THEN
                   'S67_02_1.2.1.I.2024' --1.2.1 其中：保障性租赁住房经营贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' THEN
                   'S67_02_1.3.1.I.2024' --1.3.1 其中：保障性租赁住房购买贷款
                END;

    COMMIT;
   /* --逾期贷款
    INSERT \*+ APPEND*\
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT \*+PARALLEL(4)*\
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
          'S67_02_1.1.1.Y.2022' --1.1.1 其中：保障性租赁住房开发贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' THEN
          'S67_02_1.2.1.Y.2022' --1.2.1 其中：保障性租赁住房经营贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' THEN
          'S67_02_1.3.1.Y.2022' --1.3.1 其中：保障性租赁住房购买贷款
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T1.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
         AND SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) IN ('A01', 'B01', 'D01') --住房租赁支持贷款分类
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
                   'S67_02_1.1.1.Y.2022' --1.1.1 其中：保障性租赁住房开发贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' THEN
                   'S67_02_1.2.1.Y.2022' --1.2.1 其中：保障性租赁住房经营贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' THEN
                   'S67_02_1.3.1.Y.2022' --1.3.1 其中：保障性租赁住房购买贷款
                END;

    COMMIT;*/
    --其中：当月新增逾期金额
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
          'S67_02_1.1.1.K.2024' --1.1.1 其中：保障性租赁住房开发贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' THEN
          'S67_02_1.2.1.K.2024' --1.2.1 其中：保障性租赁住房经营贷款
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' THEN
          'S67_02_1.3.1.K.2024' --1.3.1 其中：保障性租赁住房购买贷款
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
         AND T2.OD_DAYS <= V_MONTH_DAYS --逾期天数在本月内
         AND SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) IN ('A01', 'B01', 'D01') --住房租赁支持贷款分类
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
                   'S67_02_1.1.1.K.2024' --1.1.1 其中：保障性租赁住房开发贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' THEN
                   'S67_02_1.2.1.K.2024' --1.2.1 其中：保障性租赁住房经营贷款
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' THEN
                   'S67_02_1.3.1.K.2024' --1.3.1 其中：保障性租赁住房购买贷款
                END;

    COMMIT;


    --贷款逾期情况 【住房对公的部分全取贷款余额】

    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP 
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' AND T2.OD_DAYS > 90 THEN
          'S67_02_1.1.1.S.2022' --1.1.1 其中：保障性租赁住房开发贷款 逾期91天以上
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' AND T2.OD_DAYS > 90 THEN
          'S67_02_1.2.1.S.2022' --1.2.1 其中：保障性租赁住房经营贷款 逾期91天以上
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' AND T2.OD_DAYS > 90 THEN
          'S67_02_1.3.1.S.2022' --1.3.1 其中：保障性租赁住房购买贷款 逾期91天以上
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A01' AND T2.OD_DAYS > 60 THEN
          'S67_02_1.1.1.P.2022' --1.1.1 其中：保障性租赁住房开发贷款 逾期61-90天
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B01' AND T2.OD_DAYS > 60 THEN
          'S67_02_1.2.1.P.2022' --1.2.1 其中：保障性租赁住房经营贷款 逾期61-90天
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D01' AND T2.OD_DAYS > 60 THEN
          'S67_02_1.3.1.P.2022' --1.3.1 其中：保障性租赁住房购买贷款 逾期61-90天
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A01' AND T2.OD_DAYS > 0 THEN
          'S67_02_1.1.1.N.2022' --1.1.1 其中：保障性租赁住房开发贷款 逾期1-60天
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B01' AND T2.OD_DAYS > 0 THEN
          'S67_02_1.2.1.N.2022' --1.2.1 其中：保障性租赁住房经营贷款 逾期1-60天
         WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D01' AND T2.OD_DAYS > 0 THEN
          'S67_02_1.3.1.N.2022' --1.3.1 其中：保障性租赁住房购买贷款 逾期1-60天
       END AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) LOAN_ACCT_BAL_RMB --贷款余额
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
         AND SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) IN ('A01', 'B01', 'D01') --住房租赁支持贷款分类
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' AND
                       T2.OD_DAYS > 90 THEN
                   'S67_02_1.1.1.S.2022' --1.1.1 其中：保障性租赁住房开发贷款 逾期91天以上
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'B01' AND
                       T2.OD_DAYS > 90 THEN
                   'S67_02_1.2.1.S.2022' --1.2.1 其中：保障性租赁住房经营贷款 逾期91天以上
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'D01' AND
                       T2.OD_DAYS > 90 THEN
                   'S67_02_1.3.1.S.2022' --1.3.1 其中：保障性租赁住房购买贷款 逾期91天以上
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A01' AND
                       T2.OD_DAYS > 60 THEN
                   'S67_02_1.1.1.P.2022' --1.1.1 其中：保障性租赁住房开发贷款 逾期61-90天
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B01' AND
                       T2.OD_DAYS > 60 THEN
                   'S67_02_1.2.1.P.2022' --1.2.1 其中：保障性租赁住房经营贷款 逾期61-90天
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D01' AND
                       T2.OD_DAYS > 60 THEN
                   'S67_02_1.3.1.P.2022' --1.3.1 其中：保障性租赁住房购买贷款 逾期61-90天
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'A01' AND
                       T2.OD_DAYS > 0 THEN
                   'S67_02_1.1.1.N.2022' --1.1.1 其中：保障性租赁住房开发贷款 逾期1-60天
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'B01' AND
                       T2.OD_DAYS > 0 THEN
                   'S67_02_1.2.1.N.2022' --1.2.1 其中：保障性租赁住房经营贷款 逾期1-60天
                  WHEN SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) = 'D01' AND
                       T2.OD_DAYS > 0 THEN
                   'S67_02_1.3.1.N.2022' --1.3.1 其中：保障性租赁住房购买贷款 逾期1-60天
                END;

    COMMIT;


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '附注2逻辑全部处理完成';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --其中：当月核销
      INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
        (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
        SELECT 
         I_DATADATE,
         A.ORG_NUM,
         CASE
           WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') THEN
            'S67_1.1.D.2024' --1.1 地产开发贷款
           WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
            'S67_1.1.1.D.2024' --1.1.1其中:保障性安居工程
           WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
            'S67_1.1.1.1.D.2024' --1.1.1.1其中：棚户区改造贷款
           WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') AND
                (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
                 T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
            'S67_1.2.1.D.2024' -- 1.2.1住房开发贷款
           WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
            'S67_1.2.1.1.D.2024' --1.2.1.1其中：保障性住房开发贷款
           WHEN T1.PROPERTYLOAN_TYP = '1115' THEN
            'S67_1.2.1.1.1.D.2024' --1.2.1.1.1  其中：棚户区改造贷款
           WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                ('2011', '2021', '2031') THEN --企业、机关 、个人
            'S67_1.3.D.2024' --1.3 商业用房购房贷款
           WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN --个人住房贷款
                ('2032', '2033', '2034', '2035', '2036') THEN
            'S67_1.4.D.2024' --1.4 个人住房贷款
         END ITEM_NUM,
         SUM(XX.DRAWDOWN_AMT * U.CCY_RATE) LOAN_ACCT_BAL_RMB --实核贷款本金
          FROM SMTMODS_L_ACCT_LOAN A
          LEFT JOIN SMTMODS_L_CUST_ALL B
            ON A.CUST_ID = B.CUST_ID
           AND B.DATA_DATE = I_DATADATE
         INNER JOIN SMTMODS_L_ACCT_WRITE_OFF XX
            ON A.LOAN_NUM = XX.LOAN_NUM
           AND XX.DATA_DATE = I_DATADATE
           AND SUBSTR(TO_CHAR(XX.WRITE_OFF_DATE, 'YYYYMMDD'), 1, 6) =
               SUBSTR(I_DATADATE, 1, 6)
         INNER JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
            ON A.LOAN_NUM = T1.LOAN_NUM
           AND T1.DATA_DATE = I_DATADATE
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON A.DATA_DATE = U.DATA_DATE
           AND U.CCY_DATE = D_DATADATE_CCY
           AND U.BASIC_CCY = A.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE A.DATA_DATE = I_DATADATE
           AND A.CANCEL_FLG = 'Y'
         GROUP BY A.ORG_NUM,
                  CASE
                    WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                         ('101', '102', '103') THEN
                     'S67_1.1.D.2024' --1.1 地产开发贷款
                    WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
                     'S67_1.1.1.D.2024' --1.1.1其中:保障性安居工程
                    WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
                     'S67_1.1.1.1.D.2024' --1.1.1.1其中：棚户区改造贷款
                    WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                         ('111', '112', '113') AND
                         (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                          ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                     'S67_1.2.1.D.2024' -- 1.2.1住房开发贷款
                    WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                         (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                         ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                         SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
                     'S67_1.2.1.1.D.2024' --1.2.1.1其中：保障性住房开发贷款
                    WHEN T1.PROPERTYLOAN_TYP = '1115' THEN
                     'S67_1.2.1.1.1.D.2024' --1.2.1.1.1  其中：棚户区改造贷款
                    WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                         ('2011', '2021', '2031') THEN --企业、机关 、个人
                     'S67_1.3.D.2024' --1.3 商业用房购房贷款
                    WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN --个人住房贷款
                         ('2032', '2033', '2034', '2035', '2036') THEN
                     'S67_1.4.D.2024' --1.4 个人住房贷款
                  END;
    COMMIT;
    --4.其他以房地产为抵押的贷款 当月核销
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       'S67_4..D.2024' AS ITEM_NUM,
       SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) LOAN_ACCT_BAL_RMB --实核贷款本金
        FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
       INNER JOIN CBRC_CONTRACT_NUM_TMP C --以房地产为抵押的贷款
          ON T2.ACCT_NUM = C.CONTRACT_NUM
       INNER JOIN SMTMODS_L_ACCT_WRITE_OFF XX
          ON T2.LOAN_NUM = XX.LOAN_NUM
         AND XX.DATA_DATE = I_DATADATE
         AND SUBSTR(TO_CHAR(XX.WRITE_OFF_DATE, 'YYYYMMDD'), 1, 6) =
             SUBSTR(I_DATADATE, 1, 6)
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T2.DATA_DATE = I_DATADATE
         AND SUBSTR(nvl(T1.PROPERTYLOAN_TYP, '&'), 1, 4) NOT IN
             ('2011',
              '2021',
              '2031',
              '2032',
              '2033',
              '2034',
              '2035',
              '2036') --企业、个人购买商业用房贷款、个人住房贷款
         AND SUBSTR(nvl(T1.PROPERTYLOAN_TYP, '&'), 1, 3) NOT IN
             ('101', '102', '103') --地产开发贷款
         AND SUBSTR(nvl(T1.PROPERTYLOAN_TYP, '&'), 1, 3) NOT IN
             ('111', '112', '113', '114', '119') --房产开发贷款
         AND T2.CANCEL_FLG = 'Y'
       GROUP BY T2.ORG_NUM;
 COMMIT;
   -- 其中：当月新增展期金额
   INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
     (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
     SELECT 
      I_DATADATE,
      T2.ORG_NUM,
      CASE
        WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') THEN
         'S67_1.1.I.2024' --1.1 地产开发贷款
        WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
         'S67_1.1.1.I.2024' --1.1.1其中:保障性安居工程
        WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
         'S67_1.1.1.1.I.2024' --1.1.1.1其中：棚户区改造贷款
        WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') AND
             (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
         'S67_1.2.1.I.2024' --1.2.1 住房开发贷款
        WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
             (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
             T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
             SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
         'S67_1.2.1.1.I.2024' --1.2.1.1其中：保障性住房开发贷款
        WHEN T1.PROPERTYLOAN_TYP = '1115' THEN
         'S67_1.2.1.1.1.I.2024' --1.2.1.1.1  其中：棚户区改造贷款
        WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
             (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
         'S67_1.2.2.I.2024' --1.2.2 商业用房开发贷款
        WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
             (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
         'S67_1.2.3.I.2024' --1.2.3 其他房产开发贷款
        WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') --企业、机关
             AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                  ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
         'S67_1.3.1.1.I.2024' --1.3.1.1 企业购买商业用房贷款
        WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
             (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
         'S67_1.3.1.2.I.2024' --1.3.1.2 个人购买商业用房贷款
        WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036') AND T1.OWN_HOUSE = 1 THEN
         'S67_1.4.1.1.I.2024' --1.4.1.1 第一套房
        WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036') AND
             (T1.OWN_HOUSE = '2') THEN
         'S67_1.4.1.2.I.2024' --1.4.1.2 第二套房
        WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
             ('2032', '2033', '2034', '2035', '2036') AND
             (T1.OWN_HOUSE = '3') THEN
         'S67_1.4.1.3.I.2024' -- 1.4.1.3 第三套房及以上
        WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' THEN
         'S67_1.5.1.I.2024' --1.5.1 其中：经营性物业贷款展期
        WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%' THEN
         'S67_1.5.2.I.2024' --1.5.2 房地产并购贷款
      END ITEM_NUM,
      SUM(XX.EXTENT_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --展期金额
       FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
      INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
         ON T1.LOAN_NUM = T2.LOAN_NUM
        AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
        AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
        AND T1.DATA_DATE = T2.DATA_DATE
      INNER JOIN SMTMODS_L_ACCT_LOAN_EXTENDTERM XX
         ON T1.LOAN_NUM = XX.LOAN_NUM
        AND XX.DATA_DATE = I_DATADATE
        AND SUBSTR(TO_CHAR(XX.EXTENT_START_DT, 'YYYYMMDD'), 1, 6) =
            SUBSTR(I_DATADATE, 1, 6)
       LEFT JOIN SMTMODS_L_PUBL_RATE U
         ON T2.DATA_DATE = U.DATA_DATE
        AND U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T2.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE T1.DATA_DATE = I_DATADATE
        AND T2.CANCEL_FLG = 'N'
        AND LENGTHB(T2.ACCT_NUM) < 36
        AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
        AND (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
            ('101', '102', '103', '111', '112', '113', '114', '119') OR
            SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
            ('2011',
              '2021',
              '2031',
              '2032',
              '2033',
              '2034',
              '2035',
              '2036') OR
            (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y') OR
            (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%'))
        AND EXTENDTERM_FLG = 'Y' --展期
    AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
      GROUP BY T2.ORG_NUM,
               CASE
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('101', '102', '103') THEN
                  'S67_1.1.I.2024' --1.1 地产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
                  'S67_1.1.1.I.2024' --1.1.1其中:保障性安居工程
                 WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
                   'S67_1.1.1.1.I.2024' --1.1.1.1其中：棚户区改造贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                      ('111', '112', '113') AND
                      (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                  'S67_1.2.1.I.2024' --1.2.1 住房开发贷款
                 WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                      (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                      ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                      SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
                  'S67_1.2.1.1.I.2024' --1.2.1.1其中：保障性住房开发贷款
                 WHEN T1.PROPERTYLOAN_TYP = '1115' THEN
                  'S67_1.2.1.1.1.I.2024' --1.2.1.1.1  其中：棚户区改造贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                      (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                  'S67_1.2.2.I.2024' --1.2.2 商业用房开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                      (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                  'S67_1.2.3.I.2024' --1.2.3 其他房产开发贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021') --企业、机关
                      AND
                      (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                  'S67_1.3.1.1.I.2024' --1.3.1.1 企业购买商业用房贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                      (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                  'S67_1.3.1.2.I.2024' --1.3.1.2 个人购买商业用房贷款
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                      ('2032', '2033', '2034', '2035', '2036') AND
                      T1.OWN_HOUSE = 1 THEN
                  'S67_1.4.1.1.I.2024' --1.4.1.1 第一套房
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                      ('2032', '2033', '2034', '2035', '2036') AND
                      (T1.OWN_HOUSE = '2') THEN
                  'S67_1.4.1.2.I.2024' --1.4.1.2 第二套房
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                      ('2032', '2033', '2034', '2035', '2036') AND
                      (T1.OWN_HOUSE = '3') THEN
                  'S67_1.4.1.3.I.2024' -- 1.4.1.3 第三套房及以上
                 WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                      JYXWY_FLG = 'Y' THEN
                  'S67_1.5.1.I.2024' --1.5.1 其中：经营性物业贷款展期
                 WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND
                      T2.ACCT_TYP LIKE '0203%' THEN
                  'S67_1.5.2.I.2024' --1.5.2 房地产并购贷款
               END;
    COMMIT;
    --4.其他以房地产为抵押的贷款 其中：当月新增展期金额
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       'S67_4..I.2024' AS ITEM_NUM,
       SUM(XX.EXTENT_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --展期金额
        FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
       LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
       INNER JOIN SMTMODS_L_ACCT_LOAN_EXTENDTERM XX
          ON T1.LOAN_NUM = XX.LOAN_NUM
         AND XX.DATA_DATE = I_DATADATE
         AND SUBSTR(TO_CHAR(XX.EXTENT_START_DT, 'YYYYMMDD'), 1, 6) =
             SUBSTR(I_DATADATE, 1, 6)
       INNER JOIN CBRC_CONTRACT_NUM_TMP C --以房地产为抵押的贷款
          ON T2.ACCT_NUM = C.CONTRACT_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 4) NOT IN
             ('2011',
              '2021',
              '2031',
              '2032',
              '2033',
              '2034',
              '2035',
              '2036') --企业、个人购买商业用房贷款、个人住房贷款
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN ('101', '102', '103') --地产开发贷款
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN
             ('111', '112', '113', '114', '119') --房产开发贷款
         AND EXTENDTERM_FLG = 'Y' --展期
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;
 COMMIT;
 --其中：当月新增逾期金额
  --1.1 地产开发贷款
  --1.2 房产开发贷款
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       CASE
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('101', '102', '103') THEN
          'S67_1.1.K.2024' --1.1 地产开发贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
          'S67_1.1.1.K.2024' --1.1.1其中:保障性安居工程
         WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
          'S67_1.1.1.1.K.2024' --1.1.1.1其中：棚户区改造贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('111', '112', '113') AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
               T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
          'S67_1.2.1.K.2024' --1.2.1 住房开发贷款
         WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
              SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
          'S67_1.2.1.1.K.2024' --1.2.1.1其中：保障性住房开发贷款
         WHEN T1.PROPERTYLOAN_TYP = '1115' THEN
          'S67_1.2.1.1.1.K.2024' --1.2.1.1.1  其中：棚户区改造贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
               T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
          'S67_1.2.2.K.2024' --1.2.2 商业用房开发贷款
         WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
              (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
               T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
          'S67_1.2.3.K.2024' --1.2.3 其他房产开发贷款
       END ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3'
         AND T2.ACCT_TYP NOT LIKE '90%'
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
             ('101', '102', '103', '111', '112', '113', '114', '119')
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
         AND T2.OD_DAYS <= V_MONTH_DAYS --逾期天数在本月内
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM,
                CASE
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                       ('101', '102', '103') THEN
                   'S67_1.1.K.2024' --1.1 地产开发贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '102' THEN
                   'S67_1.1.1.K.2024' --1.1.1其中:保障性安居工程
                  WHEN T1.PROPERTYLOAN_TYP = '1025' THEN
                    'S67_1.1.1.1.K.2024' --1.1.1.1其中：棚户区改造贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN
                       ('111', '112', '113') AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                        ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                   'S67_1.2.1.K.2024' --1.2.1 住房开发贷款
                  WHEN (SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) = '111' AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                       ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL)) OR
                       SUBSTR(T1.HOUSE_RENT_TYP, 1, 2) = 'A01' THEN
                   'S67_1.2.1.1.K.2024' --1.2.1.1其中：保障性住房开发贷款
                  WHEN T1.PROPERTYLOAN_TYP = '1115' THEN
                   'S67_1.2.1.1.1.K.2024' --1.2.1.1.1  其中：棚户区改造贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('114') AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                        ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                   'S67_1.2.2.K.2024' --1.2.2 商业用房开发贷款
                  WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 3) IN ('119') AND
                       (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                        ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                   'S67_1.2.3.K.2024' --1.2.3 其他房产开发贷款
                END;

    COMMIT;
       --1.3.1.2 个人购买商业用房贷款\1.4 个人住房贷款
    --逾期90天以内的，按照已逾期部分的本金的余额填报；逾期90天及以上的，按照整笔贷款本金的余额填报

   --逾期90天以内取逾期金额
      INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
        (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
        SELECT 
         I_DATADATE,
         T2.ORG_NUM,
         CASE
           WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
                 T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
            'S67_1.3.1.2.K.2024' --个人购买商业用房贷款
           WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                ('2032', '2033', '2034', '2035', '2036') AND
                T1.OWN_HOUSE = 1 THEN
            'S67_1.4.1.1.K.2024' --1.4.1.1 第一套房
           WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                ('2032', '2033', '2034', '2035', '2036') AND
                T1.OWN_HOUSE = 2 THEN
            'S67_1.4.1.2.K.2024' --1.4.1.2 第二套房
           WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                ('2032', '2033', '2034', '2035', '2036') AND
                T1.OWN_HOUSE = 3 THEN
            'S67_1.4.1.3.K.2024' --1.4.1.3 第三套房及以上
         END ITEM_NUM,
         SUM(T2.OD_LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
          FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
         INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
            ON T1.LOAN_NUM = T2.LOAN_NUM
           AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
           AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
           AND T1.DATA_DATE = T2.DATA_DATE
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON T2.DATA_DATE = U.DATA_DATE
           AND U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = T2.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE T1.DATA_DATE = I_DATADATE
           AND T2.CANCEL_FLG = 'N'
           AND LENGTHB(T2.ACCT_NUM) < 36
           AND T2.LOAN_ACCT_BAL > 0
           AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
               ('2031', '2032', '2033', '2034', '2035', '2036')
           AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
           AND T2.OD_DAYS <= V_MONTH_DAYS --逾期天数在本月内
       AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         GROUP BY T2.ORG_NUM,
                  CASE
                    WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2031') AND
                         (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN
                          ('02', '12') OR T1.OPERL_PROP_LOAN_CLS_CD IS NULL) THEN
                     'S67_1.3.1.2.K.2024' --个人购买商业用房贷款
                    WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                         ('2032', '2033', '2034', '2035', '2036') AND
                         T1.OWN_HOUSE = 1 THEN
                     'S67_1.4.1.1.K.2024' --1.4.1.1 第一套房
                    WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                         ('2032', '2033', '2034', '2035', '2036') AND
                         T1.OWN_HOUSE = 2 THEN
                     'S67_1.4.1.2.K.2024' --1.4.1.2 第二套房
                    WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN
                         ('2032', '2033', '2034', '2035', '2036') AND
                         T1.OWN_HOUSE = 3 THEN
                     'S67_1.4.1.3.K.2024' --1.4.1.3 第三套房及以上
                  END;

    COMMIT;

    --1.3.1.1 企业购买商业用房贷款
    INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE,
       T2.ORG_NUM,
       'S67_1.3.1.1.K.2024' AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
       INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
         AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
         AND T1.DATA_DATE = T2.DATA_DATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(T1.PROPERTYLOAN_TYP, 1, 4) IN ('2011', '2021')
         AND (SUBSTR(T1.OPERL_PROP_LOAN_CLS_CD, 1, 2) NOT IN ('02', '12') OR
              T1.OPERL_PROP_LOAN_CLS_CD IS NULL)
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
         AND T2.OD_DAYS <= V_MONTH_DAYS --逾期天数在本月内
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;

     COMMIT;
    --1.5.1 其中：经营性物业贷款
    --1.5.2 房地产并购贷款
    --当月新增逾期金额
      INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
        (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
        SELECT 
         I_DATADATE,
         T2.ORG_NUM,
         CASE
           WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND JYXWY_FLG = 'Y' THEN
            'S67_1.5.1.K.2024' --1.5.1 其中：经营性物业贷款
           WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%' THEN
            'S67_1.5.2.K.2024' --1.5.2 房地产并购贷款
         END ITEM_NUM,
         SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
          FROM SMTMODS_L_ACCT_LOAN_REALESTATE T1
         INNER JOIN SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
            ON T1.LOAN_NUM = T2.LOAN_NUM
           AND T2.ACCT_STS <> '3' --账户状态-结清 码表A0005
           AND T2.ACCT_TYP NOT LIKE '90%' --贷款账户类型-委托贷款 码表A0004
           AND T1.DATA_DATE = T2.DATA_DATE
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON T2.DATA_DATE = U.DATA_DATE
           AND U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = T2.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE T1.DATA_DATE = I_DATADATE
           AND T2.CANCEL_FLG = 'N'
           AND LENGTHB(T2.ACCT_NUM) < 36
           AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
           AND ((SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
               JYXWY_FLG = 'Y') OR
               (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%'))
           AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
           AND T2.OD_DAYS <= V_MONTH_DAYS --逾期天数在本月内
       AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         GROUP BY T2.ORG_NUM,
                  CASE
                    WHEN SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' AND
                         JYXWY_FLG = 'Y' THEN
                     'S67_1.5.1.K.2024' --1.5.1 其中：经营性物业贷款
                    WHEN T2.LOAN_PURPOSE_CD LIKE 'K%' AND
                         T2.ACCT_TYP LIKE '0203%' THEN
                     'S67_1.5.2.K.2024' --1.5.2 房地产并购贷款
                  END;
    COMMIT;
    --4.其他以房地产为抵押的贷款 其中：当月新增逾期
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       'S67_4..K.2024' AS ITEM_NUM,
       SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
        FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
       LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
       INNER JOIN CBRC_CONTRACT_NUM_TMP C --以房地产为抵押的贷款
          ON T2.ACCT_NUM = C.CONTRACT_NUM
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T1.DATA_DATE = I_DATADATE
         AND T2.CANCEL_FLG = 'N'
         AND LENGTHB(T2.ACCT_NUM) < 36
         AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 4) NOT IN
             ('2011',
              '2021',
              '2031',
              '2032',
              '2033',
              '2034',
              '2035',
              '2036') --企业、个人购买商业用房贷款、个人住房贷款
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN ('101', '102', '103') --地产开发贷款
         AND SUBSTR(NVL(T1.PROPERTYLOAN_TYP,'&'), 1, 3) NOT IN
             ('111', '112', '113', '114', '119') --房产开发贷款
         AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
         AND T2.OD_DAYS <= V_MONTH_DAYS --逾期天数在本月内
     AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY T2.ORG_NUM;
 COMMIT;

/*房地产贷款中除去地产开发贷款、房产开发贷款、商业用房购房贷款、个人住房贷款的贷款,
包括机关团体购房贷款、企业购买住房贷款、经营性物业贷款、房地产租赁经营贷款、房地产并购贷款、房地产中介服务贷款、有产权车位的车位贷款(这个有吗)等。
以投资为目的，用于建造非自用的标准化厂房的贷款在此项统计。(这个有吗)*/
 --1.5 其他房地产贷款 期末余额情况

 --当月新发放金额
        INSERT 
        INTO CBRC_S67_DATA_COLLECT_TMP
         (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
         SELECT 
          I_DATADATE AS DATA_DATE,
          T2.ORG_NUM,
          'S67_1.5.C.2021' AS ITEM_NUM,
          SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
           FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
           LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
             ON T1.LOAN_NUM = T2.LOAN_NUM
            AND T1.DATA_DATE = T2.DATA_DATE
           LEFT JOIN SMTMODS_L_PUBL_RATE U
             ON T2.DATA_DATE = U.DATA_DATE
            AND U.CCY_DATE = I_DATADATE
            AND U.BASIC_CCY = T2.CURR_CD --基准币种
            AND U.FORWARD_CCY = 'CNY' --折算币种
          WHERE T1.DATA_DATE = I_DATADATE
            AND T2.CANCEL_FLG = 'N'
            AND LENGTHB(T2.ACCT_NUM) < 36
            AND T2.LOAN_ACCT_BAL > 0 --ALTER BY WJB 20220727 房地产补充信息表有变化，将借据状态是垫款、核销、正常销户、和核销销户的数据加了进来
            AND ((SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 3) IN ('201', '202') AND
                SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 4) NOT IN
                ('2021', '2011')) OR SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR
                (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%') OR
                (SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) IN ('B', 'D')))
            AND SUBSTR(TO_CHAR(T2.DRAWDOWN_DT, 'YYYYMMDD'), 1, 6) = V_DATADATE_M ---取当月
      AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
          GROUP BY T2.ORG_NUM;
  COMMIT;
  --当月收回金额
   INSERT  INTO CBRC_S67_DATA_COLLECT_TMP
     (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
     select 
      I_DATADATE,
      T2.ORG_NUM,
      'S67_1.5.D.2021' AS ITEM_NUM,
      SUM(T3.PAY_AMT) AS PAY_AMT --本金金额
       FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
       LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
         ON T1.LOAN_NUM = T2.LOAN_NUM
        AND T1.DATA_DATE = T2.DATA_DATE
      INNER JOIN SMTMODS_L_TRAN_LOAN_PAYM T3 --贷款还款明细信息表
         ON T1.LOAN_NUM = T3.LOAN_NUM
      WHERE T1.DATA_DATE = I_DATADATE
        AND SUBSTR(TO_CHAR(T3.REPAY_DT, 'YYYYMMDD'), 1, 6) = ---取当月
            SUBSTR(I_DATADATE, 1, 6)
        AND T2.DATA_DATE = T3.REPAY_DT
        AND ((SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 3) IN ('201', '202') AND
            SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 4) NOT IN
            ('2021', '2011')) OR SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR
            (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%') OR
            (SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) IN ('B', 'D')))
      GROUP BY T2.ORG_NUM;
    COMMIT;
    --其中：当月核销
    INSERT 
    INTO CBRC_S67_DATA_COLLECT_TMP
      (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T2.ORG_NUM,
       'S67_1.5.D.2024' AS ITEM_NUM,
       SUM(T2.DRAWDOWN_AMT * U.CCY_RATE) LOAN_ACCT_BAL_RMB --实核贷款本金
        FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
        LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
          ON T1.LOAN_NUM = T2.LOAN_NUM
         AND T1.DATA_DATE = T2.DATA_DATE
       INNER JOIN SMTMODS_L_ACCT_WRITE_OFF XX
          ON T2.LOAN_NUM = XX.LOAN_NUM
         AND XX.DATA_DATE = I_DATADATE
         AND SUBSTR(TO_CHAR(XX.WRITE_OFF_DATE, 'YYYYMMDD'), 1, 6) =
             SUBSTR(I_DATADATE, 1, 6)
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T2.DATA_DATE = U.DATA_DATE
         AND U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = T2.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE T2.DATA_DATE = I_DATADATE
         AND ((SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 3) IN
             ('201', '202') AND
             SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 4) NOT IN
             ('2021', '2011')) OR SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR
             (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%') OR
             (SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) IN ('B', 'D')))
         AND T2.CANCEL_FLG = 'Y'
       GROUP BY T2.ORG_NUM;
 COMMIT;
 --金融资产五级分类情况
      INSERT 
      INTO CBRC_S67_DATA_COLLECT_TMP
        (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
        SELECT 
         I_DATADATE AS DATA_DATE,
         T2.ORG_NUM,
         CASE
           WHEN T2.LOAN_GRADE_CD = '1' THEN
            'S67_1.5.F.2021'
           WHEN T2.LOAN_GRADE_CD = '2' THEN
            'S67_1.5.G.2021'
           WHEN T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
            'S67_1.5.H.2021'
         END AS ITEM_NUM,
         SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
          FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
            ON T1.LOAN_NUM = T2.LOAN_NUM
           AND T1.DATA_DATE = T2.DATA_DATE
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON T2.DATA_DATE = U.DATA_DATE
           AND U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = T2.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE T1.DATA_DATE = I_DATADATE
           AND T2.CANCEL_FLG = 'N'
           AND LENGTHB(T2.ACCT_NUM) < 36
           AND T2.LOAN_ACCT_BAL > 0
           AND ((SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 3) IN
               ('201', '202') AND
               SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 4) NOT IN
               ('2021', '2011')) OR
               SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR
               (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%') OR
               (SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) IN ('B', 'D')))
       AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         GROUP BY T2.ORG_NUM,
                  CASE
                    WHEN T2.LOAN_GRADE_CD = '1' THEN
                     'S67_1.5.F.2021'
                    WHEN T2.LOAN_GRADE_CD = '2' THEN
                     'S67_1.5.G.2021'
                    WHEN T2.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                     'S67_1.5.H.2021'
                  END;
 COMMIT;
     ---------展期情况
    INSERT 
      INTO CBRC_S67_DATA_COLLECT_TMP
        (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
        SELECT 
         I_DATADATE AS DATA_DATE,
         T2.ORG_NUM,
         'S67_1.5.L.2021' AS ITEM_NUM,
         SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
          FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
            ON T1.LOAN_NUM = T2.LOAN_NUM
           AND T1.DATA_DATE = T2.DATA_DATE
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON T2.DATA_DATE = U.DATA_DATE
           AND U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = T2.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE T1.DATA_DATE = I_DATADATE
           AND T2.CANCEL_FLG = 'N'
           AND LENGTHB(T2.ACCT_NUM) < 36
           AND T2.LOAN_ACCT_BAL > 0
           AND ((SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 3) IN
               ('201', '202') AND
               SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 4) NOT IN
               ('2021', '2011')) OR
               SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR
               (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%') OR
               (SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) IN ('B', 'D')))
           AND T2.EXTENDTERM_FLG = 'Y'
       AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
           GROUP BY T2.ORG_NUM; --展期
 COMMIT;
  --其中：当月新增展期金额
   INSERT 
   INTO CBRC_S67_DATA_COLLECT_TMP
     (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
     SELECT 
      I_DATADATE AS DATA_DATE,
      T2.ORG_NUM,
      'S67_1.5.I.2021' AS ITEM_NUM,
      SUM(XX.EXTENT_AMT * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB --展期金额
       FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
       LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
         ON T1.LOAN_NUM = T2.LOAN_NUM
        AND T1.DATA_DATE = T2.DATA_DATE
      INNER JOIN SMTMODS_L_ACCT_LOAN_EXTENDTERM XX
         ON T1.LOAN_NUM = XX.LOAN_NUM
        AND XX.DATA_DATE = I_DATADATE
        AND SUBSTR(TO_CHAR(XX.EXTENT_START_DT, 'YYYYMMDD'), 1, 6) =
            SUBSTR(I_DATADATE, 1, 6)
       LEFT JOIN SMTMODS_L_PUBL_RATE U
         ON T2.DATA_DATE = U.DATA_DATE
        AND U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T2.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE T1.DATA_DATE = I_DATADATE
        AND T2.CANCEL_FLG = 'N'
        AND LENGTHB(T2.ACCT_NUM) < 36
        AND T2.LOAN_ACCT_BAL > 0
        AND ((SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 3) IN ('201', '202') AND
            SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 4) NOT IN
            ('2021', '2011')) OR SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR
            (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%') OR
            (SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) IN ('B', 'D')))
        AND T2.EXTENDTERM_FLG = 'Y'
    AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
      GROUP BY T2.ORG_NUM;
   COMMIT;
  ---------贷款逾期情况
  --逾期贷款
  INSERT 
      INTO CBRC_S67_DATA_COLLECT_TMP
        (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
        SELECT 
         I_DATADATE AS DATA_DATE,
         T2.ORG_NUM,
         'S67_1.5.Y.2021' AS ITEM_NUM,
         SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
          FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
            ON T1.LOAN_NUM = T2.LOAN_NUM
           AND T1.DATA_DATE = T2.DATA_DATE
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON T2.DATA_DATE = U.DATA_DATE
           AND U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = T2.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE T1.DATA_DATE = I_DATADATE
           AND T2.CANCEL_FLG = 'N'
           AND LENGTHB(T2.ACCT_NUM) < 36
           AND T2.LOAN_ACCT_BAL > 0
           AND ((SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 3) IN
               ('201', '202') AND
               SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 4) NOT IN
               ('2021', '2011')) OR
               SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR
               (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%') OR
               (SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) IN ('B', 'D')))
           AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
       AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
           GROUP BY T2.ORG_NUM;
 COMMIT;

  --其中：当月新增逾期金额
  INSERT 
      INTO CBRC_S67_DATA_COLLECT_TMP
        (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
        SELECT 
         I_DATADATE AS DATA_DATE,
         T2.ORG_NUM,
         'S67_1.5.K.2024' AS ITEM_NUM,
         SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
          FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
          LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
            ON T1.LOAN_NUM = T2.LOAN_NUM
           AND T1.DATA_DATE = T2.DATA_DATE
          LEFT JOIN SMTMODS_L_PUBL_RATE U
            ON T2.DATA_DATE = U.DATA_DATE
           AND U.CCY_DATE = I_DATADATE
           AND U.BASIC_CCY = T2.CURR_CD --基准币种
           AND U.FORWARD_CCY = 'CNY' --折算币种
         WHERE T1.DATA_DATE = I_DATADATE
           AND T2.CANCEL_FLG = 'N'
           AND LENGTHB(T2.ACCT_NUM) < 36
           AND T2.LOAN_ACCT_BAL > 0
           AND ((SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 3) IN
               ('201', '202') AND
               SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 4) NOT IN
               ('2021', '2011')) OR
               SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR
               (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%') OR
               (SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) IN ('B', 'D')))
           AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
           AND T2.OD_DAYS <= V_MONTH_DAYS --逾期天数在本月内
       AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
           GROUP BY T2.ORG_NUM;
 COMMIT;
  --按逾期天数划分
   INSERT 
   INTO CBRC_S67_DATA_COLLECT_TMP
     (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
     SELECT 
      I_DATADATE AS DATA_DATE,
      T2.ORG_NUM,
      CASE
        WHEN T2.OD_DAYS > 90 THEN
         'S67_1.5.S.2021' --逾期91天以上
        WHEN T2.OD_DAYS > 60 THEN
         'S67_1.5.P.2021' --逾期61-90天
        WHEN T2.OD_DAYS > 0 THEN
         'S67_1.5.N.2021' --逾期1-60天
      END AS ITEM_NUM,
     -- SUM(T2.LOAN_ACCT_BAL * U.CCY_RATE) AS LOAN_ACCT_BAL_RMB
       /*alter by shiyu 20241105 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
            如果是按月分期还款的个人消费贷款本金或利息逾期 */
       sum(case when (t2.ACCT_TYP LIKE '0101%' OR t2.ACCT_TYP LIKE '0103%' OR
             t2.ACCT_TYP LIKE '0104%' OR t2.ACCT_TYP LIKE '0199%'
             )
             and t2.REPAY_TYP ='1'--按月支付
             and t2.od_days <= 90
             then t2.OD_LOAN_ACCT_BAL * U.CCY_RATE
             else t2.loan_acct_bal* U.CCY_RATE end )
       FROM SMTMODS_L_ACCT_LOAN T2 --贷款借据信息表
       LEFT JOIN SMTMODS_L_ACCT_LOAN_REALESTATE T1
         ON T1.LOAN_NUM = T2.LOAN_NUM
        AND T1.DATA_DATE = T2.DATA_DATE
       LEFT JOIN SMTMODS_L_PUBL_RATE U
         ON T2.DATA_DATE = U.DATA_DATE
        AND U.CCY_DATE = I_DATADATE
        AND U.BASIC_CCY = T2.CURR_CD --基准币种
        AND U.FORWARD_CCY = 'CNY' --折算币种
      WHERE T1.DATA_DATE = I_DATADATE
        AND T2.CANCEL_FLG = 'N'
        AND LENGTHB(T2.ACCT_NUM) < 36
        AND T2.LOAN_ACCT_BAL > 0
        AND ((SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 3) IN ('201', '202') AND
            SUBSTR(NVL(T1.PROPERTYLOAN_TYP, '&'), 1, 4) NOT IN
            ('2021', '2011')) OR SUBSTR(T1.PROPERTYLOAN_TYP, 1, 1) = '4' OR
            (T2.LOAN_PURPOSE_CD LIKE 'K%' AND T2.ACCT_TYP LIKE '0203%') OR
            (SUBSTR(T1.HOUSE_RENT_TYP, 1, 1) IN ('B', 'D')))
        AND UPPER(T2.OD_FLG) = 'Y' --逾期标志
    AND T2.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
      GROUP BY T2.ORG_NUM,
               CASE
                 WHEN T2.OD_DAYS > 90 THEN
                  'S67_1.5.S.2021' --逾期91天以上
                 WHEN T2.OD_DAYS > 60 THEN
                  'S67_1.5.P.2021' --逾期61-90天
                 WHEN T2.OD_DAYS > 0 THEN
                  'S67_1.5.N.2021' --逾期1-60天
               END;
 COMMIT;

----=================zdd  by  zy   20240729   金融市场部需求   start ========
-----按债券投资的行业分类和五级分类按余额填报
------======================================================================

----2.1 投向房地产领域的标准化债权类资产.期末余额情况   都在正常类，根据外网查询债券投资的发行方是房地产相关企业
INSERT 
INTO CBRC_S67_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
  SELECT  I_DATADATE AS DATA_DATE,
         A.ORG_NUM,
         'S67_2.1.A.2021',
         SUM(A.PRINCIPAL_BALANCE) LOAN_ACCT_BAL_RMB
    FROM SMTMODS_L_ACCT_FUND_INVEST A ---投资业务信息表
   INNER JOIN SMTMODS_L_AGRE_BOND_INFO C
      ON REPLACE(A.ACCT_NUM, 'X0003120B2700001', '041800014') = C.STOCK_CD --康星做的业务错误，X0003120B2700001，应为041800014
    -- AND A.DATA_DATE = C.DATA_DATE
     AND C.DATA_DATE = I_DATADATE
     AND C.STOCK_PRO_TYPE IN ('D04', 'D05', 'D01', 'D02') ---信用债券包括：企业债、公司债、短期融资券、中期票据、分离交易可转债、资产支持证券、次级债
     INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO B  ---客户外部信息表
      ON A.CUST_ID = B.CUST_ID   ---可以用客户号关联，原因为投资业务交易对手均会在本行开户，两张表的客户号都是ECIF客户号
     AND B.DATA_DATE = I_DATADATE
     AND B.INDS_INVEST = '7411' ---房地产行业
   WHERE A.DATA_DATE = I_DATADATE
     AND A.GL_ITEM_CODE IN ('15030103',
                            '11010101',
                            '15010103',
                            '15030101',
                            '11010103',
                            '11010102',
                            '15030102',
                            '15010101',
                            '15010102')
     AND A.DATE_SOURCESD = '债券投资'
   GROUP BY A.ORG_NUM;
COMMIT;
 ----2.1.1 自营资金投资类.期末余额情况 都在正常类，根据外网查询债券投资的发行方是房地产相关企业
 INSERT 
INTO CBRC_S67_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
  SELECT  I_DATADATE AS DATA_DATE,
         A.ORG_NUM,
         'S67_2.1.1.A.2021',
         SUM(A.PRINCIPAL_BALANCE) LOAN_ACCT_BAL_RMB
    FROM SMTMODS_L_ACCT_FUND_INVEST A ---投资业务信息表
   INNER JOIN SMTMODS_L_AGRE_BOND_INFO C
      ON REPLACE(A.ACCT_NUM, 'X0003120B2700001', '041800014') = C.STOCK_CD --康星做的业务错误，X0003120B2700001，应为041800014
    --  AND A.DATA_DATE = C.DATA_DATE
     AND C.DATA_DATE = I_DATADATE
     AND C.STOCK_PRO_TYPE IN ('D04', 'D05', 'D01', 'D02') ---信用债券包括：企业债、公司债、短期融资券、中期票据、分离交易可转债、资产支持证券、次级债
     INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO B  ---可以用客户号关联，原因为投资业务交易对手均会在本行开户，两张表的客户号都是ECIF客户号
      ON A.CUST_ID = B.CUST_ID
     AND B.DATA_DATE = I_DATADATE
     AND B.INDS_INVEST = '7411' ---房地产行业
   WHERE A.DATA_DATE = I_DATADATE
     AND A.GL_ITEM_CODE IN ('15030103',
                            '11010101',
                            '15010103',
                            '15030101',
                            '11010103',
                            '11010102',
                            '15030102',
                            '15010101',
                            '15010102')
     AND A.DATE_SOURCESD = '债券投资'
   GROUP BY A.ORG_NUM;
COMMIT;
---2.1.2.1 其中：房地产企业债券.期末余额情况 都在正常类，根据外网查询债券投资的发行方是房地产相关企业

INSERT 
INTO CBRC_S67_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
  SELECT  I_DATADATE AS DATA_DATE,
         A.ORG_NUM,
         'S67_2.1.2.1.A.2021',
         SUM(A.PRINCIPAL_BALANCE) LOAN_ACCT_BAL_RMB
    FROM SMTMODS_L_ACCT_FUND_INVEST A ---投资业务信息表
   INNER JOIN SMTMODS_L_AGRE_BOND_INFO C
      ON REPLACE(A.ACCT_NUM, 'X0003120B2700001', '041800014') = C.STOCK_CD --康星做的业务错误，X0003120B2700001，应为041800014
     AND A.DATA_DATE = C.DATA_DATE
     AND C.DATA_DATE = I_DATADATE
     AND C.STOCK_PRO_TYPE IN ('D04', 'D05', 'D01', 'D02') ---信用债券包括：企业债、公司债、短期融资券、中期票据、分离交易可转债、资产支持证券、次级债
     INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO B  ---可以用客户号关联，原因为投资业务交易对手均会在本行开户，两张表的客户号都是ECIF客户号
      ON A.CUST_ID = B.CUST_ID
     AND B.DATA_DATE = I_DATADATE
     AND B.INDS_INVEST = '7411' ---房地产行业
   WHERE A.DATA_DATE = I_DATADATE
     AND A.GL_ITEM_CODE IN ('15030103',
                            '11010101',
                            '15010103',
                            '15030101',
                            '11010103',
                            '11010102',
                            '15030102',
                            '15010101',
                            '15010102')
     AND A.DATE_SOURCESD = '债券投资'
   GROUP BY A.ORG_NUM;
COMMIT;


----2.1 投向房地产领域的标准化债权类资产.金融资产五级分类情况，根据外网查询债券投资的发行方是房地产相关企业
INSERT 
INTO CBRC_S67_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
 SELECT  
 I_DATADATE AS DATA_DATE,
         A.ORG_NUM,
         CASE WHEN D.FIVE_TIER_CLS = '01' THEN
                 'S67_2.1.F.2021'
               WHEN D.FIVE_TIER_CLS = '02' THEN
                 'S67_2.1.G.2021'
               WHEN D.FIVE_TIER_CLS = '03' THEN
                 'S67_2.1.I.2021'
               WHEN D.FIVE_TIER_CLS = '04' THEN
                 'S67_2.1.J.2021'
               WHEN D.FIVE_TIER_CLS = '05' THEN
                 'S67_2.1.K.2021'
               ELSE  'S67_2.1.F.2021'   END  ,
         SUM(A.PRINCIPAL_BALANCE) LOAN_ACCT_BAL_RMB
    FROM SMTMODS_L_ACCT_FUND_INVEST A ---投资业务信息表
   INNER JOIN SMTMODS_L_AGRE_BOND_INFO C
      ON REPLACE(A.ACCT_NUM, 'X0003120B2700001', '041800014') = C.STOCK_CD --康星做的业务错误，X0003120B2700001，应为041800014
    -- AND A.DATA_DATE = C.DATA_DATE
     AND C.DATA_DATE = I_DATADATE
     AND C.STOCK_PRO_TYPE IN ('D04', 'D05', 'D01', 'D02') ---信用债券包括：企业债、公司债、短期融资券、中期票据、分离交易可转债、资产支持证券、次级债
     INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO B
      ON A.CUST_ID = B.CUST_ID
     AND B.DATA_DATE = I_DATADATE
     AND B.INDS_INVEST = '7411' ---房地产行业
   LEFT JOIN  SMTMODS_L_FINA_ASSET_DEVALUE  D
   ON A.ACCT_NUM  =D.BIZ_NO
   AND A.ACCT_NO = D.ACCT_ID --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
   AND A.ORG_NUM  =D.RECORD_ORG
   AND A.GL_ITEM_CODE =D.PRIN_SUBJ_NO
   AND  D.DATA_DATE=I_DATADATE
   WHERE A.DATA_DATE = I_DATADATE
     AND A.GL_ITEM_CODE IN ('15030103',
                            '11010101',
                            '15010103',
                            '15030101',
                            '11010103',
                            '11010102',
                            '15030102',
                            '15010101',
                            '15010102')
     AND A.DATE_SOURCESD = '债券投资'
     GROUP  BY  A.ORG_NUM,
        CASE WHEN D.FIVE_TIER_CLS = '01' THEN
                 'S67_2.1.F.2021'
               WHEN D.FIVE_TIER_CLS = '02' THEN
                 'S67_2.1.G.2021'
               WHEN D.FIVE_TIER_CLS = '03' THEN
                 'S67_2.1.I.2021'
               WHEN D.FIVE_TIER_CLS = '04' THEN
                 'S67_2.1.J.2021'
               WHEN D.FIVE_TIER_CLS = '05' THEN
                 'S67_2.1.K.2021'
               ELSE  'S67_2.1.F.2021'   END    ;

COMMIT;
 ----2.1.1 自营资金投资类.金融资产五级分类情况，根据外网查询债券投资的发行方是房地产相关企业
 INSERT 
INTO CBRC_S67_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
  SELECT  
 I_DATADATE AS DATA_DATE,
         A.ORG_NUM,
         CASE WHEN D.FIVE_TIER_CLS = '01' THEN
                 'S67_2.1.1.F.2021'
               WHEN D.FIVE_TIER_CLS = '02' THEN
                 'S67_2.1.1.G.2021'
               WHEN D.FIVE_TIER_CLS = '03' THEN
                 'S67_2.1.1.I.2021'
               WHEN D.FIVE_TIER_CLS = '04' THEN
                'S67_2.1.1.J.2021'
               WHEN D.FIVE_TIER_CLS = '05' THEN
                'S67_2.1.1.K.2021'
               ELSE  'S67_2.1.1.F.2021'   END  ,
         SUM(A.PRINCIPAL_BALANCE) LOAN_ACCT_BAL_RMB
    FROM SMTMODS_L_ACCT_FUND_INVEST A ---投资业务信息表
   INNER JOIN SMTMODS_L_AGRE_BOND_INFO C
      ON REPLACE(A.ACCT_NUM, 'X0003120B2700001', '041800014') = C.STOCK_CD --康星做的业务错误，X0003120B2700001，应为041800014
  --   AND A.DATA_DATE = C.DATA_DATE
     AND C.DATA_DATE = I_DATADATE
     AND C.STOCK_PRO_TYPE IN ('D04', 'D05', 'D01', 'D02') ---信用债券包括：企业债、公司债、短期融资券、中期票据、分离交易可转债、资产支持证券、次级债
     INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO B
      ON A.CUST_ID = B.CUST_ID
     AND B.DATA_DATE = I_DATADATE
     AND B.INDS_INVEST = '7411' ---房地产行业
   LEFT JOIN  SMTMODS_L_FINA_ASSET_DEVALUE  D
   ON A.ACCT_NUM  =D.BIZ_NO
   AND A.ACCT_NO = D.ACCT_ID --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
   AND A.ORG_NUM  =D.RECORD_ORG
   AND A.GL_ITEM_CODE =D.PRIN_SUBJ_NO
   AND  D.DATA_DATE=I_DATADATE
   WHERE A.DATA_DATE = I_DATADATE
     AND A.GL_ITEM_CODE IN ('15030103',
                            '11010101',
                            '15010103',
                            '15030101',
                            '11010103',
                            '11010102',
                            '15030102',
                            '15010101',
                            '15010102')
     AND A.DATE_SOURCESD = '债券投资'
     GROUP  BY  A.ORG_NUM,
        CASE WHEN D.FIVE_TIER_CLS = '01' THEN
                 'S67_2.1.1.F.2021'
               WHEN D.FIVE_TIER_CLS = '02' THEN
                 'S67_2.1.1.G.2021'
               WHEN D.FIVE_TIER_CLS = '03' THEN
                 'S67_2.1.1.I.2021'
               WHEN D.FIVE_TIER_CLS = '04' THEN
                'S67_2.1.1.J.2021'
               WHEN D.FIVE_TIER_CLS = '05' THEN
                'S67_2.1.1.K.2021'
               ELSE  'S67_2.1.1.F.2021'   END     ;
COMMIT;
---2.1.2.1 其中：房地产企业债券.金融资产五级分类情况，根据外网查询债券投资的发行方是房地产相关企业

INSERT 
INTO CBRC_S67_DATA_COLLECT_TMP
  (DATA_DATE, ORG_NUM, ITEM_NUM, LOAN_ACCT_BAL_RMB)
SELECT 
 I_DATADATE AS DATA_DATE,
         A.ORG_NUM,
         CASE WHEN D.FIVE_TIER_CLS = '01' THEN
                 'S67_2.1.2.1.F.2021'
               WHEN D.FIVE_TIER_CLS = '02' THEN
                 'S67_2.1.2.1.G.2021'
               WHEN D.FIVE_TIER_CLS = '03' THEN
                 'S67_2.1.2.1.I.2021'
               WHEN D.FIVE_TIER_CLS = '04' THEN
                'S67_2.1.2.1.J.2021'
               WHEN D.FIVE_TIER_CLS = '05' THEN
                'S67_2.1.2.1.K.2021'
               ELSE 'S67_2.1.2.1.F.2021'   END  ,
         SUM(A.PRINCIPAL_BALANCE) LOAN_ACCT_BAL_RMB
    FROM SMTMODS_L_ACCT_FUND_INVEST A ---投资业务信息表
   INNER JOIN SMTMODS_L_AGRE_BOND_INFO C
      ON REPLACE(A.ACCT_NUM, 'X0003120B2700001', '041800014') = C.STOCK_CD --康星做的业务错误，X0003120B2700001，应为041800014
     AND A.DATA_DATE = C.DATA_DATE
     AND C.DATA_DATE = I_DATADATE
     AND C.STOCK_PRO_TYPE IN ('D04', 'D05', 'D01', 'D02') ---信用债券包括：企业债、公司债、短期融资券、中期票据、分离交易可转债、资产支持证券、次级债
     INNER JOIN SMTMODS_L_CUST_EXTERNAL_INFO B
   ON A.DATA_DATE = B.DATA_DATE

      AND  A.CUST_ID = B.CUST_ID
     AND B.DATA_DATE = I_DATADATE
     AND B.INDS_INVEST = '7411' ---房地产行业
   LEFT JOIN  SMTMODS_L_FINA_ASSET_DEVALUE  D
   ON A.ACCT_NUM  =D.BIZ_NO
   AND A.ACCT_NO = D.ACCT_ID --[JLBA202505140011][20250729][常金磊][康立军][解决债券、存单关联减值重复问题]
   AND A.ORG_NUM  =D.RECORD_ORG
   AND A.GL_ITEM_CODE =D.PRIN_SUBJ_NO
   AND  D.DATA_DATE=I_DATADATE
   WHERE A.DATA_DATE = I_DATADATE
     AND A.GL_ITEM_CODE IN ('15030103',
                            '11010101',
                            '15010103',
                            '15030101',
                            '11010103',
                            '11010102',
                            '15030102',
                            '15010101',
                            '15010102')
     AND A.DATE_SOURCESD = '债券投资'
     GROUP  BY  A.ORG_NUM,
       CASE WHEN D.FIVE_TIER_CLS = '01' THEN
                 'S67_2.1.2.1.F.2021'
               WHEN D.FIVE_TIER_CLS = '02' THEN
                 'S67_2.1.2.1.G.2021'
               WHEN D.FIVE_TIER_CLS = '03' THEN
                 'S67_2.1.2.1.I.2021'
               WHEN D.FIVE_TIER_CLS = '04' THEN
                'S67_2.1.2.1.J.2021'
               WHEN D.FIVE_TIER_CLS = '05' THEN
                'S67_2.1.2.1.K.2021'
               ELSE 'S67_2.1.2.1.F.2021'   END    ;
COMMIT;

 -------------------zdd  by  zy   20240729   金融市场部需求    end  ----




    --=======================================================================================================
    -------------------------------------S67数据插至目标指标表-----------------------------------------------
    --=======================================================================================================

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '产生S67指标数据，插至目标表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    /*---  ------------------所有指标插入目标表-----------------------------------  */
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值(数值型)
       FLAG --标志位
       )
      select  I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'S67' AS REP_NUM,
             T.ITEM_NUM,
             SUM(NVL(LOAN_ACCT_BAL_RMB, 0)) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S67_DATA_COLLECT_TMP T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM, T.ITEM_NUM;
    COMMIT;

   --处理金融资产五级分类情况(不良),逾期情况按逾期天数划分(逾期1-60天)(逾期91天以上)由原来拆分开，改为合并,写在初始化里面
      --处理金融资产五级分类情况(不良),逾期情况按逾期天数划分(逾期1-60天)(逾期91天以上)由原来拆分开 alter by shiyu 加工到一个指标内

INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
 select  I_DATADATE AS DATA_DATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'S67' AS REP_NUM,
             case when T.ITEM_NUM in ('S67_1.1.I.2021','S67_1.1.J.2021','S67_1.1.K.2021') then 'S67_1.1.H.2021'
                  when T.ITEM_NUM in ('S67_1.1.1.I.2021','S67_1.1.1.J.2021','S67_1.1.1.K.2021') then 'S67_1.1.1.H.2021'
                when t.item_num in ('S67_1.2.1.I.2021','S67_1.2.1.J.2021','S67_1.2.1.K.2021')  then 'S67_1.2.1.H.2021'
                when ITEM_NUM IN('S67_1.2.1.1.I.2021','S67_1.2.1.1.J.2021','S67_1.2.1.1.K.2021')   then 'S67_1.2.1.1.H.2021' 
               when ITEM_NUM IN('S67_1.2.2.I.2021','S67_1.2.2.J.2021','S67_1.2.2.K.2021')  then 'S67_1.2.2.H.2021'
               when ITEM_NUM IN('S67_1.2.3.I.2021','S67_1.2.3.J.2021','S67_1.2.3.K.2021') then 'S67_1.2.3.H.2021'
                when ITEM_NUM IN('S67_1.3.1.1.I.2021','S67_1.3.1.1.J.2021','S67_1.3.1.1.K.2021') then 'S67_1.3.1.1.H.2021'
                when ITEM_NUM IN('S67_1.3.1.2.I.2021','S67_1.3.1.2.J.2021','S67_1.3.1.2.K.2021') then 'S67_1.3.1.2.H.2021'
                when ITEM_NUM IN('S67_1.4.1.1.I.2021','S67_1.4.1.1.J.2021','S67_1.4.1.1.K.2021') then 'S67_1.4.1.1.H.2021'
                when  ITEM_NUM IN('S67_1.4.1.2.I.2021','S67_1.4.1.2.J.2021','S67_1.4.1.2.K.2021') then 'S67_1.4.1.2.H.2021'
                when ITEM_NUM IN('S67_1.4.1.3.I.2021','S67_1.4.1.3.J.2021','S67_1.4.1.3.K.2021') then 'S67_1.4.1.3.H.2021'
                when  ITEM_NUM IN('S67_1.5.I.2021','S67_1.5.J.2021','S67_1.5.K.2021') then 'S67_1.5.H.2021'  
                when  ITEM_NUM IN('S67_1.5.1.I.2021','S67_1.5.1.J.2021','S67_1.5.1.K.2021') then 'S67_1.5.1.H.2021'
                when ITEM_NUM IN('S67_0_5..I.2021','S67_0_5..J.2021','S67_0_5..K.2021') then 'S67_0_5..H.2021' 
                when   ITEM_NUM IN('S67_2.1.I.2021','S67_2.1.J.2021','S67_2.1.K.2021') then 'S67_2.1.H.2021'
                 when ITEM_NUM IN('S67_2.1.1.I.2021','S67_2.1.1.J.2021','S67_2.1.1.K.2021') then 'S67_2.1.1.H.2021'
                 when ITEM_NUM IN('S67_2.1.2.1.I.2021','S67_2.1.2.1.J.2021','S67_2.1.2.1.K.2021') then 'S67_2.1.2.1.H.2021'  
                 when ITEM_NUM IN('S67_2.1.2.2.I.2021','S67_2.1.2.2.J.2021','S67_2.1.2.2.K.2021') then 'S67_2.1.2.2.H.2021'
                 when ITEM_NUM IN('S67_2.1.2.3.I.2021','S67_2.1.2.3.J.2021','S67_2.1.2.3.K.2021') then 'S67_2.1.2.3.H.2021'
                 when ITEM_NUM IN('S67_2.2.I.2021','S67_2.2.J.2021','S67_2.2.K.2021') then 'S67_2.2.H.2021'  
                 when  ITEM_NUM IN('S67_4..I.2021','S67_4..J.2021','S67_4..K.2021') then 'S67_4..H.2021'
                 when  ITEM_NUM IN('S67_0_3.1.I.2021','S67_0_3.1.J.2021','S67_0_3.1.K.2021') then 'S67_0_3.1.H.2021'
                 when ITEM_NUM IN('S67_0_3.2.I.2021','S67_0_3.2.J.2021','S67_0_3.2.K.2021')  then 'S67_0_3.2.H.2021'
                 when ITEM_NUM IN('S67_0_3.3.I.2021','S67_0_3.3.J.2021','S67_0_3.3.K.2021')  then 'S67_0_3.3.H.2021'
                 when ITEM_NUM IN('S67_0_3.4.I.2021','S67_0_3.4.J.2021','S67_0_3.4.K.2021') then 'S67_0_3.4.H.2021'
                 when  ITEM_NUM IN('S67_1.1.N.2021','S67_1.1.O.2021')  then  'S67_1.1.N.2021'
                 when ITEM_NUM IN('S67_1.1.1.N.2021','S67_1.1.1.O.2021') then 'S67_1.1.1.N.2021'
                 when ITEM_NUM IN('S67_1.2.1.N.2021',' S67_1.2.1.O.2021') then 'S67_1.2.1.N.2021'
                 when ITEM_NUM IN('S67_1.2.1.1.N.2021','S67_1.2.1.1.O.2021') then 'S67_1.2.1.1.N.2021'
                 when ITEM_NUM IN('S67_1.2.2.N.2021','S67_1.2.2.O.2021') then 'S67_1.2.2.N.2021'
                 when ITEM_NUM IN('S67_1.2.3.N.2021','S67_1.2.3.O.2021') then 'S67_1.2.3.N.2021'
                 when ITEM_NUM IN('S67_1.3.1.1.N.2021','S67_1.3.1.1.O.2021') then 'S67_1.3.1.1.N.2021'
                 when  ITEM_NUM IN('S67_1.3.1.2.N.2021','S67_1.3.1.2.O.2021') then 'S67_1.3.1.2.N.2021'
                 when ITEM_NUM IN('S67_1.4.1.1.N.2021','S67_1.4.1.1.O.2021') then 'S67_1.4.1.1.N.2021'
                 when ITEM_NUM IN('S67_1.4.1.2.N.2021','S67_1.4.1.2.O.2021') then 'S67_1.4.1.2.N.2021'
                 when ITEM_NUM IN('S67_1.4.1.3.N.2021','S67_1.4.1.3.O.2021') then 'S67_1.4.1.3.N.2021'
                 when ITEM_NUM IN('S67_1.5.N.2021','S67_1.5.O.2021') then 'S67_1.5.N.2021'
                 when ITEM_NUM IN('S67_1.5.1.N.2021','S67_1.5.1.O.2021') then 'S67_1.5.1.N.2021'
                 when ITEM_NUM IN('S67_0_5..N.2021','S67_0_5..O.2021') then 'S67_0_5..N.2021'
                 when ITEM_NUM IN('S67_2.1.N.2021','S67_2.1.O.2021') then 'S67_2.1.N.2021'
                 when ITEM_NUM IN('S67_2.1.1.N.2021','S67_2.1.1.O.2021') then 'S67_2.1.1.N.2021'
                 when ITEM_NUM IN('S67_2.1.2.1.N.2021','S67_2.1.2.1.O.2021') then 'S67_2.1.2.1.N.2021'
                 when ITEM_NUM IN('S67_2.1.2.2.N.2021','S67_2.1.2.2.O.2021') then 'S67_2.1.2.2.N.2021'
                 when ITEM_NUM IN('S67_2.1.2.3.N.2021','S67_2.1.2.3.O.2021') then 'S67_2.1.2.3.N.2021'
                 when ITEM_NUM IN('S67_2.2.N.2021','S67_2.2.O.2021') then 'S67_2.2.N.2021'
                 when ITEM_NUM IN('S67_3..N.2021','S67_3..O.2021') then 'S67_3..N.2021'
                 when  ITEM_NUM IN('S67_3.1.N.2021','S67_3.1.O.2021') then 'S67_3.1.N.2021'
                 when ITEM_NUM IN('S67_3.1.1.N.2021','S67_3.1.1.O.2021') then 'S67_3.1.1.N.2021'
                 when  ITEM_NUM IN('S67_3.1.2.N.2021','S67_3.1.2.O.2021')  then 'S67_3.1.2.N.2021'
                 when ITEM_NUM IN('S67_3.1.3.N.2021','S67_3.1.3.O.2021') then 'S67_3.1.3.N.2021'
                 when ITEM_NUM IN('S67_3.2.N.2021','S67_3.2.O.2021') then 'S67_3.2.N.2021'
                 when ITEM_NUM IN('S67_4..N.2021','S67_4..O.2021') then 'S67_4..N.2021'
                 when ITEM_NUM IN('S67_0_1.1.L.2024','S67_0_1.1.O.2024')  then 'S67_0_1.1.L.2024'
                 when ITEM_NUM IN('S67_0_3.1.N.2021','S67_0_3.1.O.2021') then 'S67_0_3.1.N.2021'
                 when  ITEM_NUM IN('S67_0_3.2.N.2021','S67_0_3.2.O.2021') then 'S67_0_3.2.N.2021'
                 when  ITEM_NUM IN('S67_0_3.3.N.2021','S67_0_3.3.O.2021') then 'S67_0_3.3.N.2021'
                 when ITEM_NUM IN('S67_0_3.4.N.2021','S67_0_3.4.O.2021')  then 'S67_0_3.4.N.2021' 
                 when ITEM_NUM IN('S67_1.1.S.2021','S67_1.1.R.2021','S67_1.1.Q.2021') then 'S67_1.1.S.2021'
                 when ITEM_NUM IN('S67_1.1.1.S.2021','S67_1.1.1.R.2021','S67_1.1.1.Q.2021') then 'S67_1.1.1.S.2021'
                 when  ITEM_NUM IN('S67_1.2.1.S.2021','S67_1.2.1.Q.2021','S67_1.2.1.R.2021')  then 'S67_1.2.1.S.2021'
                 when ITEM_NUM IN('S67_1.2.1.1.S.2021','S67_1.2.1.1.Q.2021','S67_1.2.1.1.R.2021') then 'S67_1.2.1.1.S.2021'
                 when ITEM_NUM IN('S67_1.2.2.S.2021','S67_1.2.2.Q.2021','S67_1.2.2.R.2021') then 'S67_1.2.2.S.2021'
                 when  ITEM_NUM IN('S67_1.2.3.S.2021','S67_1.2.3.Q.2021','S67_1.2.3.R.2021') then 'S67_1.2.3.S.2021'
                 when  ITEM_NUM IN('S67_1.3.1.1.S.2021','S67_1.3.1.1.Q.2021','S67_1.3.1.1.R.2021')  then 'S67_1.3.1.1.S.2021'
                 when ITEM_NUM IN('S67_1.3.1.2.S.2021','S67_1.3.1.2.Q.2021','S67_1.3.1.2.R.2021') then 'S67_1.3.1.2.S.2021'
                 when ITEM_NUM IN('S67_1.4.1.1.S.2021','S67_1.4.1.1.Q.2021','S67_1.4.1.1.R.2021')  then 'S67_1.4.1.1.S.2021'
                 when ITEM_NUM IN('S67_1.4.1.2.S.2021','S67_1.4.1.2.Q.2021','S67_1.4.1.2.R.2021') then 'S67_1.4.1.2.S.2021'
                 when ITEM_NUM IN('S67_1.4.1.3.S.2021','S67_1.4.1.3.Q.2021','S67_1.4.1.3.R.2021')  then 'S67_1.4.1.3.S.2021'
                 when ITEM_NUM IN('S67_1.5.S.2021','S67_1.5.Q.2021','S67_1.5.R.2021')  then 'S67_1.5.S.2021'
                 when ITEM_NUM IN('S67_1.5.1.S.2021','S67_1.5.1.Q.2021''S67_1.5.1.R.2021') then 'S67_1.5.1.S.2021'  
                 when ITEM_NUM IN('S67_0_5..S.2021','S67_0_5..Q.2021','S67_0_5..R.2021') then 'S67_0_5..S.2021'
                 when ITEM_NUM IN('S67_2.1.S.2021','S67_2.1.Q.2021','S67_2.1.R.2021') then 'S67_2.1.S.2021'
                 when ITEM_NUM IN('S67_2.1.1.S.2021','S67_2.1.1.Q.2021','S67_2.1.1.R.2021') then 'S67_2.1.1.S.2021'
                 when ITEM_NUM IN('S67_2.1.2.1.S.2021','S67_2.1.2.1.Q.2021','S67_2.1.2.1.R.2021') then 'S67_2.1.2.1.S.2021'
                 when ITEM_NUM IN('S67_2.1.2.2.S.2021','S67_2.1.2.2.Q.2021','S67_2.1.2.2.R.2021') then 'S67_2.1.2.2.S.2021'
                 when  ITEM_NUM IN('S67_2.1.2.3.S.2021','S67_2.1.2.3.Q.2021','S67_2.1.2.3.R.2021') then 'S67_2.1.2.3.S.2021'
                 when ITEM_NUM IN('S67_2.2.S.2021','S67_2.2.Q.2021','S67_2.2.R.2021') then 'S67_2.2.S.2021'
                 when ITEM_NUM IN('S67_3..S.2021','S67_3..Q.2021','S67_3..R.2021') then 'S67_3..S.2021'
                 when ITEM_NUM IN('S67_3.1.S.2021','S67_3.1.Q.2021','S67_3.1.R.2021') then 'S67_3.1.S.2021'
                 when  ITEM_NUM IN('S67_3.1.1.S.2021','S67_3.1.1.Q.2021','S67_3.1.1.R.2021') then 'S67_3.1.1.S.2021'
                 when ITEM_NUM IN('S67_3.1.2.S.2021','S67_3.1.2.Q.2021','S67_3.1.2.R.2021') then 'S67_3.1.2.S.2021'
                 when ITEM_NUM IN('S67_3.1.3.S.2021','S67_3.1.3.Q.2021','S67_3.1.3.R.2021')then 'S67_3.1.3.S.2021'
                 when ITEM_NUM IN('S67_3.2.S.2021','S67_3.2.Q.2021','S67_3.2.R.2021') then 'S67_3.2.S.2021'
                 when ITEM_NUM IN('S67_4..S.2021','S67_4..Q.2021','S67_4..R.2021')  then 'S67_4..S.2021'
                 when ITEM_NUM IN('S67_0_3.1.S.2021','S67_0_3.1.Q.2021','S67_0_3.1.R.2021') then 'S67_0_3.1.S.2021'
                 when ITEM_NUM IN('S67_0_3.2.S.2021','S67_0_3.2.Q.2021','S67_0_3.2.R.2021') then 'S67_0_3.2.S.2021'
                 when ITEM_NUM IN('S67_0_3.3.S.2021','S67_0_3.3.Q.2021','S67_0_3.3.R.2021') then 'S67_0_3.3.S.2021'
                 when  ITEM_NUM IN('S67_0_3.4.S.2021','S67_0_3.4.Q.2021','S67_0_3.4.R.2021') then 'S67_0_3.4.S.2021'
                   end ITEM_NUM 
               ,
             SUM(NVL(LOAN_ACCT_BAL_RMB, 0)) AS ITEM_VAL,
             '2' AS FLAG
        FROM CBRC_S67_DATA_COLLECT_TMP T
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_NUM IS NOT NULL
       GROUP BY T.ORG_NUM, 
       case when T.ITEM_NUM in ('S67_1.1.I.2021','S67_1.1.J.2021','S67_1.1.K.2021') then 'S67_1.1.H.2021'
                  when T.ITEM_NUM in ('S67_1.1.1.I.2021','S67_1.1.1.J.2021','S67_1.1.1.K.2021') then 'S67_1.1.1.H.2021'
                when t.item_num in ('S67_1.2.1.I.2021','S67_1.2.1.J.2021','S67_1.2.1.K.2021')  then 'S67_1.2.1.H.2021'
                when ITEM_NUM IN('S67_1.2.1.1.I.2021','S67_1.2.1.1.J.2021','S67_1.2.1.1.K.2021')   then 'S67_1.2.1.1.H.2021' 
               when ITEM_NUM IN('S67_1.2.2.I.2021','S67_1.2.2.J.2021','S67_1.2.2.K.2021')  then 'S67_1.2.2.H.2021'
               when ITEM_NUM IN('S67_1.2.3.I.2021','S67_1.2.3.J.2021','S67_1.2.3.K.2021') then 'S67_1.2.3.H.2021'
                when ITEM_NUM IN('S67_1.3.1.1.I.2021','S67_1.3.1.1.J.2021','S67_1.3.1.1.K.2021') then 'S67_1.3.1.1.H.2021'
                when ITEM_NUM IN('S67_1.3.1.2.I.2021','S67_1.3.1.2.J.2021','S67_1.3.1.2.K.2021') then 'S67_1.3.1.2.H.2021'
                when ITEM_NUM IN('S67_1.4.1.1.I.2021','S67_1.4.1.1.J.2021','S67_1.4.1.1.K.2021') then 'S67_1.4.1.1.H.2021'
                when  ITEM_NUM IN('S67_1.4.1.2.I.2021','S67_1.4.1.2.J.2021','S67_1.4.1.2.K.2021') then 'S67_1.4.1.2.H.2021'
                when ITEM_NUM IN('S67_1.4.1.3.I.2021','S67_1.4.1.3.J.2021','S67_1.4.1.3.K.2021') then 'S67_1.4.1.3.H.2021'
                when  ITEM_NUM IN('S67_1.5.I.2021','S67_1.5.J.2021','S67_1.5.K.2021') then 'S67_1.5.H.2021'  
                when  ITEM_NUM IN('S67_1.5.1.I.2021','S67_1.5.1.J.2021','S67_1.5.1.K.2021') then 'S67_1.5.1.H.2021'
                when ITEM_NUM IN('S67_0_5..I.2021','S67_0_5..J.2021','S67_0_5..K.2021') then 'S67_0_5..H.2021' 
                when   ITEM_NUM IN('S67_2.1.I.2021','S67_2.1.J.2021','S67_2.1.K.2021') then 'S67_2.1.H.2021'
                 when ITEM_NUM IN('S67_2.1.1.I.2021','S67_2.1.1.J.2021','S67_2.1.1.K.2021') then 'S67_2.1.1.H.2021'
                 when ITEM_NUM IN('S67_2.1.2.1.I.2021','S67_2.1.2.1.J.2021','S67_2.1.2.1.K.2021') then 'S67_2.1.2.1.H.2021'  
                 when ITEM_NUM IN('S67_2.1.2.2.I.2021','S67_2.1.2.2.J.2021','S67_2.1.2.2.K.2021') then 'S67_2.1.2.2.H.2021'
                 when ITEM_NUM IN('S67_2.1.2.3.I.2021','S67_2.1.2.3.J.2021','S67_2.1.2.3.K.2021') then 'S67_2.1.2.3.H.2021'
                 when ITEM_NUM IN('S67_2.2.I.2021','S67_2.2.J.2021','S67_2.2.K.2021') then 'S67_2.2.H.2021'  
                 when  ITEM_NUM IN('S67_4..I.2021','S67_4..J.2021','S67_4..K.2021') then 'S67_4..H.2021'
                 when  ITEM_NUM IN('S67_0_3.1.I.2021','S67_0_3.1.J.2021','S67_0_3.1.K.2021') then 'S67_0_3.1.H.2021'
                 when ITEM_NUM IN('S67_0_3.2.I.2021','S67_0_3.2.J.2021','S67_0_3.2.K.2021')  then 'S67_0_3.2.H.2021'
                 when ITEM_NUM IN('S67_0_3.3.I.2021','S67_0_3.3.J.2021','S67_0_3.3.K.2021')  then 'S67_0_3.3.H.2021'
                 when ITEM_NUM IN('S67_0_3.4.I.2021','S67_0_3.4.J.2021','S67_0_3.4.K.2021') then 'S67_0_3.4.H.2021'
                 when  ITEM_NUM IN('S67_1.1.N.2021','S67_1.1.O.2021')  then  'S67_1.1.N.2021'
                 when ITEM_NUM IN('S67_1.1.1.N.2021','S67_1.1.1.O.2021') then 'S67_1.1.1.N.2021'
                 when ITEM_NUM IN('S67_1.2.1.N.2021',' S67_1.2.1.O.2021') then 'S67_1.2.1.N.2021'
                 when ITEM_NUM IN('S67_1.2.1.1.N.2021','S67_1.2.1.1.O.2021') then 'S67_1.2.1.1.N.2021'
                 when ITEM_NUM IN('S67_1.2.2.N.2021','S67_1.2.2.O.2021') then 'S67_1.2.2.N.2021'
                 when ITEM_NUM IN('S67_1.2.3.N.2021','S67_1.2.3.O.2021') then 'S67_1.2.3.N.2021'
                 when ITEM_NUM IN('S67_1.3.1.1.N.2021','S67_1.3.1.1.O.2021') then 'S67_1.3.1.1.N.2021'
                 when  ITEM_NUM IN('S67_1.3.1.2.N.2021','S67_1.3.1.2.O.2021') then 'S67_1.3.1.2.N.2021'
                 when ITEM_NUM IN('S67_1.4.1.1.N.2021','S67_1.4.1.1.O.2021') then 'S67_1.4.1.1.N.2021'
                 when ITEM_NUM IN('S67_1.4.1.2.N.2021','S67_1.4.1.2.O.2021') then 'S67_1.4.1.2.N.2021'
                 when ITEM_NUM IN('S67_1.4.1.3.N.2021','S67_1.4.1.3.O.2021') then 'S67_1.4.1.3.N.2021'
                 when ITEM_NUM IN('S67_1.5.N.2021','S67_1.5.O.2021') then 'S67_1.5.N.2021'
                 when ITEM_NUM IN('S67_1.5.1.N.2021','S67_1.5.1.O.2021') then 'S67_1.5.1.N.2021'
                 when ITEM_NUM IN('S67_0_5..N.2021','S67_0_5..O.2021') then 'S67_0_5..N.2021'
                 when ITEM_NUM IN('S67_2.1.N.2021','S67_2.1.O.2021') then 'S67_2.1.N.2021'
                 when ITEM_NUM IN('S67_2.1.1.N.2021','S67_2.1.1.O.2021') then 'S67_2.1.1.N.2021'
                 when ITEM_NUM IN('S67_2.1.2.1.N.2021','S67_2.1.2.1.O.2021') then 'S67_2.1.2.1.N.2021'
                 when ITEM_NUM IN('S67_2.1.2.2.N.2021','S67_2.1.2.2.O.2021') then 'S67_2.1.2.2.N.2021'
                 when ITEM_NUM IN('S67_2.1.2.3.N.2021','S67_2.1.2.3.O.2021') then 'S67_2.1.2.3.N.2021'
                 when ITEM_NUM IN('S67_2.2.N.2021','S67_2.2.O.2021') then 'S67_2.2.N.2021'
                 when ITEM_NUM IN('S67_3..N.2021','S67_3..O.2021') then 'S67_3..N.2021'
                 when  ITEM_NUM IN('S67_3.1.N.2021','S67_3.1.O.2021') then 'S67_3.1.N.2021'
                 when ITEM_NUM IN('S67_3.1.1.N.2021','S67_3.1.1.O.2021') then 'S67_3.1.1.N.2021'
                 when  ITEM_NUM IN('S67_3.1.2.N.2021','S67_3.1.2.O.2021')  then 'S67_3.1.2.N.2021'
                 when ITEM_NUM IN('S67_3.1.3.N.2021','S67_3.1.3.O.2021') then 'S67_3.1.3.N.2021'
                 when ITEM_NUM IN('S67_3.2.N.2021','S67_3.2.O.2021') then 'S67_3.2.N.2021'
                 when ITEM_NUM IN('S67_4..N.2021','S67_4..O.2021') then 'S67_4..N.2021'
                 when ITEM_NUM IN('S67_0_1.1.L.2024','S67_0_1.1.O.2024')  then 'S67_0_1.1.L.2024'
                 when ITEM_NUM IN('S67_0_3.1.N.2021','S67_0_3.1.O.2021') then 'S67_0_3.1.N.2021'
                 when  ITEM_NUM IN('S67_0_3.2.N.2021','S67_0_3.2.O.2021') then 'S67_0_3.2.N.2021'
                 when  ITEM_NUM IN('S67_0_3.3.N.2021','S67_0_3.3.O.2021') then 'S67_0_3.3.N.2021'
                 when ITEM_NUM IN('S67_0_3.4.N.2021','S67_0_3.4.O.2021')  then 'S67_0_3.4.N.2021' 
                 when ITEM_NUM IN('S67_1.1.S.2021','S67_1.1.R.2021','S67_1.1.Q.2021') then 'S67_1.1.S.2021'
                 when ITEM_NUM IN('S67_1.1.1.S.2021','S67_1.1.1.R.2021','S67_1.1.1.Q.2021') then 'S67_1.1.1.S.2021'
                 when  ITEM_NUM IN('S67_1.2.1.S.2021','S67_1.2.1.Q.2021','S67_1.2.1.R.2021')  then 'S67_1.2.1.S.2021'
                 when ITEM_NUM IN('S67_1.2.1.1.S.2021','S67_1.2.1.1.Q.2021','S67_1.2.1.1.R.2021') then 'S67_1.2.1.1.S.2021'
                 when ITEM_NUM IN('S67_1.2.2.S.2021','S67_1.2.2.Q.2021','S67_1.2.2.R.2021') then 'S67_1.2.2.S.2021'
                 when  ITEM_NUM IN('S67_1.2.3.S.2021','S67_1.2.3.Q.2021','S67_1.2.3.R.2021') then 'S67_1.2.3.S.2021'
                 when  ITEM_NUM IN('S67_1.3.1.1.S.2021','S67_1.3.1.1.Q.2021','S67_1.3.1.1.R.2021')  then 'S67_1.3.1.1.S.2021'
                 when ITEM_NUM IN('S67_1.3.1.2.S.2021','S67_1.3.1.2.Q.2021','S67_1.3.1.2.R.2021') then 'S67_1.3.1.2.S.2021'
                 when ITEM_NUM IN('S67_1.4.1.1.S.2021','S67_1.4.1.1.Q.2021','S67_1.4.1.1.R.2021')  then 'S67_1.4.1.1.S.2021'
                 when ITEM_NUM IN('S67_1.4.1.2.S.2021','S67_1.4.1.2.Q.2021','S67_1.4.1.2.R.2021') then 'S67_1.4.1.2.S.2021'
                 when ITEM_NUM IN('S67_1.4.1.3.S.2021','S67_1.4.1.3.Q.2021','S67_1.4.1.3.R.2021')  then 'S67_1.4.1.3.S.2021'
                 when ITEM_NUM IN('S67_1.5.S.2021','S67_1.5.Q.2021','S67_1.5.R.2021')  then 'S67_1.5.S.2021'
                 when ITEM_NUM IN('S67_1.5.1.S.2021','S67_1.5.1.Q.2021''S67_1.5.1.R.2021') then 'S67_1.5.1.S.2021'  
                 when ITEM_NUM IN('S67_0_5..S.2021','S67_0_5..Q.2021','S67_0_5..R.2021') then 'S67_0_5..S.2021'
                 when ITEM_NUM IN('S67_2.1.S.2021','S67_2.1.Q.2021','S67_2.1.R.2021') then 'S67_2.1.S.2021'
                 when ITEM_NUM IN('S67_2.1.1.S.2021','S67_2.1.1.Q.2021','S67_2.1.1.R.2021') then 'S67_2.1.1.S.2021'
                 when ITEM_NUM IN('S67_2.1.2.1.S.2021','S67_2.1.2.1.Q.2021','S67_2.1.2.1.R.2021') then 'S67_2.1.2.1.S.2021'
                 when ITEM_NUM IN('S67_2.1.2.2.S.2021','S67_2.1.2.2.Q.2021','S67_2.1.2.2.R.2021') then 'S67_2.1.2.2.S.2021'
                 when  ITEM_NUM IN('S67_2.1.2.3.S.2021','S67_2.1.2.3.Q.2021','S67_2.1.2.3.R.2021') then 'S67_2.1.2.3.S.2021'
                 when ITEM_NUM IN('S67_2.2.S.2021','S67_2.2.Q.2021','S67_2.2.R.2021') then 'S67_2.2.S.2021'
                 when ITEM_NUM IN('S67_3..S.2021','S67_3..Q.2021','S67_3..R.2021') then 'S67_3..S.2021'
                 when ITEM_NUM IN('S67_3.1.S.2021','S67_3.1.Q.2021','S67_3.1.R.2021') then 'S67_3.1.S.2021'
                 when  ITEM_NUM IN('S67_3.1.1.S.2021','S67_3.1.1.Q.2021','S67_3.1.1.R.2021') then 'S67_3.1.1.S.2021'
                 when ITEM_NUM IN('S67_3.1.2.S.2021','S67_3.1.2.Q.2021','S67_3.1.2.R.2021') then 'S67_3.1.2.S.2021'
                 when ITEM_NUM IN('S67_3.1.3.S.2021','S67_3.1.3.Q.2021','S67_3.1.3.R.2021')then 'S67_3.1.3.S.2021'
                 when ITEM_NUM IN('S67_3.2.S.2021','S67_3.2.Q.2021','S67_3.2.R.2021') then 'S67_3.2.S.2021'
                 when ITEM_NUM IN('S67_4..S.2021','S67_4..Q.2021','S67_4..R.2021')  then 'S67_4..S.2021'
                 when ITEM_NUM IN('S67_0_3.1.S.2021','S67_0_3.1.Q.2021','S67_0_3.1.R.2021') then 'S67_0_3.1.S.2021'
                 when ITEM_NUM IN('S67_0_3.2.S.2021','S67_0_3.2.Q.2021','S67_0_3.2.R.2021') then 'S67_0_3.2.S.2021'
                 when ITEM_NUM IN('S67_0_3.3.S.2021','S67_0_3.3.Q.2021','S67_0_3.3.R.2021') then 'S67_0_3.3.S.2021'
                 when  ITEM_NUM IN('S67_0_3.4.S.2021','S67_0_3.4.Q.2021','S67_0_3.4.R.2021') then 'S67_0_3.4.S.2021'
                   end;
                COMMIT;
   

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
   
END ;