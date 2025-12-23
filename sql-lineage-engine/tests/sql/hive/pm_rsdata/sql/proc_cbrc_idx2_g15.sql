CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g15(II_DATADATE IN STRING --跑批日期
)
/******************************
  @AUTHOR:DAIJUN
  @CREATE-DATE:2015-09-23
  @DESCRIPTION:G15
  @MODIFICATION HISTORY:
  M0.20220228-DJH-G15
  【表内授信】债券投资、
  【表外授信】不可撤销的承诺及或有负债
  【表内外授信】保证金、银行存单、国债
  MO.20220714 -DJH
  1、一个客户证件对应多个客户id
  2、增加报告期内最高风险额（净额）
  3、数据源去重复
  m1 取消dblink 替换落地表  WORK.CBRC_GLFRXXB@WORK  替换成 CBRC_GLFRXXB
       WORK.CBRC_GLRXXB@WORK 替换成 CBRC_GLRXXB
  M2.20230418 -DJH 机构树网点级，关联时CBRC_TM_L_ORG_FLAT不进行00处理
  M3.djh 20241106 修改个人消费贷款逾期的规则：如果不是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款取贷款余额；
  如果是按月分期还款的个人消费贷款本金或利息逾期，逾期贷款在逾期时间90天以内的取逾期部分，逾期90天以上的取贷款余额
  
目标表：CBRC_A_REPT_ITEM_VAL
临时表：CBRC_G15_TEMP
     CBRC_G15_TEMP1
     CBRC_TM_A_REPT_ITEM_VAL
     CBRC_TM_A_REPT_ITEM_VAL_T
     CBRC_TM_CBRC_G15_TEMP
     CBRC_TM_CBRC_G15_TEMP1
     CBRC_TM_L_ACCT_NONFINANCIAL_TEMP
     CBRC_TM_L_ACCT_OBS_TEMP
     CBRC_TM_L_ACCT_UNUSED_TEMP
     CBRC_TM_L_ACCT_YQ_TEMP
     CBRC_TM_L_ORG_FLAT
码值表：CBRC_GLFRXXB  --依赖前台业务补录从应用数据库回抽
     CBRC_GLRXXB   --依赖前台业务补录从应用数据库回抽
     CBRC_G15      --从应用数据库回抽填报数据上季度G15
依赖表：CBRC_UPRR_U_BASE_INST
集市表：SMTMODS_L_ACCT_FUND_INVEST
     SMTMODS_L_ACCT_LOAN
     SMTMODS_L_ACCT_OBS_LOAN
     SMTMODS_L_AGRE_BOND_INFO
     SMTMODS_L_AGRE_GUARANTEE_RELATION
     SMTMODS_L_AGRE_GUARANTY_INFO
     SMTMODS_L_AGRE_GUA_RELATION
     SMTMODS_L_AGRE_LOAN_CONTRACT
     SMTMODS_L_CUST_ALL
     SMTMODS_L_CUST_C
     SMTMODS_L_CUST_P
     SMTMODS_L_FIMM_FIN_PENE
     SMTMODS_L_FIMM_PRODUCT
     SMTMODS_L_PUBL_RATE
  *******************************/
 IS
  --V_SCHEMA VARCHAR2(10); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  V_PER_NUM   VARCHAR(30); --报表编号
  V_DATADATE  VARCHAR2(10);
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR(30);

BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    V_PER_NUM   := 'G15';
    I_DATADATE  := II_DATADATE;
    V_DATADATE     := TO_CHAR(DATE(I_DATADATE, 'YYYYMMDD'), 'YYYY-MM-DD');
    V_TAB_NAME :='G15';
    V_SYSTEM    := 'CBRC';
    V_PROCEDURE  := UPPER('PROC_CBRC_IDX2_G15');
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = V_PER_NUM
       AND FLAG = '1'; --不需要汇总，本表自行汇总
    COMMIT;


    --最大十家自然人或法人关联方明细
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TM_CBRC_G15_TEMP';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_G15_TEMP';
    --明细业务中间临时表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TM_L_ACCT_UNUSED_TEMP';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TM_L_ACCT_OBS_TEMP';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TM_L_ACCT_YQ_TEMP';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TM_L_ACCT_NONFINANCIAL_TEMP';

    --取最大十家关联集团明细
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TM_CBRC_G15_TEMP1';
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_G15_TEMP1';

    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TM_A_REPT_ITEM_VAL'; --净额比较中间表
    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TM_A_REPT_ITEM_VAL_T'; --净额比较中间表

    EXECUTE IMMEDIATE 'TRUNCATE TABLE  CBRC_TM_L_ORG_FLAT'; --ADD BY DJH 20230113处理机构，进行汇总

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '处理机构层级汇总';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --递归找到所有上级
    FOR DBANK IN (SELECT INST_ID FROM CBRC_UPRR_U_BASE_INST) LOOP
     INSERT INTO CBRC_TM_L_ORG_FLAT
       (ORG_CODE, SUB_ORG_CODE)
       SELECT DISTINCT PARENT_INST_ID, INST_ID
         FROM (SELECT PARENT_INST_ID, DBANK.INST_ID AS INST_ID
                 FROM CBRC_UPRR_U_BASE_INST
                WHERE PARENT_INST_ID IS NOT NULL
                START WITH INST_ID = DBANK.INST_ID
               CONNECT BY PRIOR PARENT_INST_ID = INST_ID
               UNION ALL
               SELECT DBANK.INST_ID, DBANK.INST_ID
                 FROM SYSTEM.DUAL);
         COMMIT;
      END LOOP;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '处理机构层级汇总完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
---------------------------------------------------------------------------------------------------
 ----最大十家自然人或法人关联方
---------------------------------------------------------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '最大十家自然人：获取法人（股东）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 ---ADD BY CHM 20211223

    --取法人&自然人信息

  INSERT INTO CBRC_TM_CBRC_G15_TEMP
    (ID_NO, ID_NAME, DDATE, FLAG)
    SELECT DISTINCT TRIM(C.PV_STR) AS ID_NO,
                   '' /*TRIM(B.PV_STR)*/ AS ID_NAME,
                    I_DATADATE,
                    '1' AS FLAG
      FROM  CBRC_GLFRXXB A
     INNER JOIN  CBRC_GLFRXXB B
        ON A.ROW_NUM = B.ROW_NUM
       AND A.DDATE = B.DDATE
       AND B.COL_NUM = '3'
     INNER JOIN  CBRC_GLFRXXB C
        ON A.ROW_NUM = C.ROW_NUM
       AND A.DDATE = C.DDATE
       AND C.COL_NUM = '6'
      LEFT JOIN  CBRC_GLFRXXB D   --ADD BY DJH 20230719 取对我行持股超过5%以上的 ，取左关联
        ON A.ROW_NUM = D.ROW_NUM
       AND A.DDATE = D.DDATE
       AND D.COL_NUM = '7'
     WHERE TRIM(A.PV_STR) = '是'
       AND A.COL_NUM = '5.000000'
       AND A.DDATE = V_DATADATE ---法人 只取主要股东的法人
       AND (D.PV_STR <> '否' OR D.PV_STR IS NULL)

    UNION ALL
   SELECT DISTINCT TRIM(G.PV_STR) AS ID_NO,
                   ''  AS CUST_NAME,
                   I_DATADATE,
                   '2' AS FLAG
     FROM  CBRC_GLRXXB G
    INNER JOIN  CBRC_GLRXXB GG
       ON G.ROW_NUM = GG.ROW_NUM
      AND G.DDATE = GG.DDATE
      AND GG.COL_NUM = 2

    WHERE G.DDATE = V_DATADATE
      AND G.COL_NUM = 4
      AND (LENGTH(TRIM(G.PV_STR)) = 18 OR LENGTH(TRIM(G.PV_STR)) = 10);---10 是香港身份证
     -- AND (D.PV_STR <> '否' OR D.PV_STR IS NULL);

  COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '最大十家自然人：获取法人（股东）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '不可撤销的承诺及或有负债处理开始';
    V_STEP_FLAG := 0;
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
   /*    【表外授信】
    1、不可撤销的承诺(去掉可撤销贷款承诺，商票保贴)
    2、循环授信额度同G2501授信未使用额度（循环授信额度）*/
  INSERT 
  INTO CBRC_TM_L_ACCT_UNUSED_TEMP 
    (CUST_ID, UNUSED_AMT, DATA_DATE, FLAG, ORG_NUM, ACCT_NUM)
    SELECT 
     L.CUST_ID,
     SUM(L.BALANCE),
     I_DATADATE,
     '1' AS FLAG,
     L.ORG_NUM,
     ACCT_NUM
      FROM SMTMODS_L_ACCT_OBS_LOAN L
     WHERE L.DATA_DATE = I_DATADATE
       AND L.BALANCE <> 0 ---ADD BY CHM 20220104
       AND L.GL_ITEM_CODE NOT IN ('70300101', '70300301')
     GROUP BY L.CUST_ID, L.ORG_NUM, ACCT_NUM; --去掉（可撤销贷款承、商票保贴）
  COMMIT;

  --个人： 【循环贷款】合同金额-借据余额 ---1
  --循环贷款，只有 普通贷款&贸易融资贷款&保理贷款有   委托贷款和表外贷款没有这个概念
  INSERT 
  INTO CBRC_TM_L_ACCT_UNUSED_TEMP 
    (CUST_ID, UNUSED_AMT, DATA_DATE, FLAG, ORG_NUM)
    SELECT 
     T1.CUST_ID,
     SUM(CASE
           WHEN T1.CONTRACT_AMT - NVL(T3.LOAN_ACCT_BAL, 0) < 0 THEN
            0
           ELSE
            T1.CONTRACT_AMT - NVL(T3.LOAN_ACCT_BAL, 0)
         END) AS UNUSED_AMT, --07未使用贷款额度
     I_DATADATE,
     '2' AS FLAG,
     T1.ORG_NUM
      FROM SMTMODS_L_AGRE_LOAN_CONTRACT T1
     INNER JOIN SMTMODS_L_CUST_P T2
        ON T1.CUST_ID = T2.CUST_ID
       AND T2.DATA_DATE = I_DATADATE
      LEFT JOIN (SELECT ACCT_NUM,
                        DATA_DATE,
                        SUM(LOAN_ACCT_BAL) AS LOAN_ACCT_BAL,
                        SUM(DRAWDOWN_AMT) AS DRAWDOWN_AMT
                   FROM SMTMODS_L_ACCT_LOAN
                  WHERE DATA_DATE = I_DATADATE
                    AND CANCEL_FLG = 'N'
                    AND LENGTHB(ACCT_NUM) < 36
          AND LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
                  GROUP BY ACCT_NUM, DATA_DATE) T3
        ON T1.CONTRACT_NUM = T3.ACCT_NUM
       AND T3.DATA_DATE = I_DATADATE
     WHERE T1.DATA_DATE = I_DATADATE
       AND T1.ACCT_STS = '1' --合同为有效合同
       AND T1.IF_CYCL = 'Y' --循环授信额度
       AND T1.Date_Sourcesd  NOT IN ('委托贷款',
                                  '信用证',
                                  '银承',
                                  '保函','贷款承诺','商票保贴') --委托贷款、表外贷款的去掉
     GROUP BY T1.CUST_ID, T1.ORG_NUM
;
COMMIT;
--个人： 【循环贷款】合同金额-借据余额 ---2
  --循环贷款，只有 普通贷款&贸易融资贷款&保理贷款有   委托贷款和表外贷款没有这个概念
INSERT 
  INTO CBRC_TM_L_ACCT_UNUSED_TEMP 
    (CUST_ID, UNUSED_AMT, DATA_DATE, FLAG, ORG_NUM)
SELECT 
     T1.CUST_ID,
     SUM(CASE
           WHEN T1.CONTRACT_AMT - NVL(T3.LOAN_ACCT_BAL, 0) < 0 THEN
            0
           ELSE
            T1.CONTRACT_AMT - NVL(T3.LOAN_ACCT_BAL, 0)
         END) AS UNUSED_AMT, --07未使用贷款额度
     I_DATADATE,
     '2' AS FLAG,
     T1.ORG_NUM
      FROM SMTMODS_L_AGRE_LOAN_CONTRACT T1
     INNER JOIN SMTMODS_L_CUST_C T2
        ON T1.CUST_ID = T2.CUST_ID
       AND T2.DATA_DATE = I_DATADATE
      LEFT JOIN (SELECT ACCT_NUM,
                        DATA_DATE,
                        SUM(LOAN_ACCT_BAL) AS LOAN_ACCT_BAL,
                        SUM(DRAWDOWN_AMT) AS DRAWDOWN_AMT
                   FROM SMTMODS_L_ACCT_LOAN
                  WHERE DATA_DATE = I_DATADATE
                    AND CANCEL_FLG = 'N'  --是否核销
                    AND LENGTHB(ACCT_NUM) < 36
          AND LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
                  GROUP BY ACCT_NUM, DATA_DATE) T3
        ON T1.CONTRACT_NUM = T3.ACCT_NUM
       AND T3.DATA_DATE = I_DATADATE
     WHERE T1.DATA_DATE = I_DATADATE
       AND T2.CUST_TYP='3'
       AND T2.CUST_ID<>'8915053186'
       AND T1.ACCT_STS = '1' --合同为有效合同
       AND T1.IF_CYCL = 'Y' --循环授信额度
       AND T1.DEPARTMENTD NOT IN ('委托贷款',  '信用证',  '银承', '保函','贷款承诺','商票保贴')
     GROUP BY T1.CUST_ID, T1.ORG_NUM;
  COMMIT;
  --对公：未使用授信额度=总额度-已使用授信额度

 /* 2单一法人授信  4集团成员/供应链融资成员授信 ,
  其他不需要取都是由这两个汇总上去的，同业没有取，具体应该3同业客户授信信贷有问题，是补录数据*/
  --AND FACILITY_STS='Y' 不需要限制是否有效

    V_STEP_FLAG := 1;
    V_STEP_DESC := '不可撤销的承诺及或有负债预处理结束';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '本行非保本理财产品进行的授信开始';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
      -----------------------------ADD BY DJH 20230418 表外授信 本行非保本理财产品进行的授信
      --  【表外授信】本行非保本理财产品进行的授信   穿透底层资产原则
  INSERT 
  INTO CBRC_TM_L_ACCT_NONFINANCIAL_TEMP 
    (CUST_ID, NONFINANCIAL_AMT, DATA_DATE, FLAG, ORG_NUM)
    SELECT A.CUST_ID AS CUST_ID, --证件号
           SUM(NVL(A.INV_AMT, 0) * C.CCY_RATE) AS NONFINANCIAL_PRODUCT_RMB, --本行非保本理财产品进行的授信
           A.DATA_DATE,
           '3' AS FLAG,
           A.ORG_NUM
      FROM SMTMODS_L_FIMM_FIN_PENE A
     INNER JOIN SMTMODS_L_FIMM_PRODUCT B
        ON B.DATA_DATE = I_DATADATE
       AND A.PRODUCT_CODE = B.PRODUCT_CODE
       AND B.PROCEEDS_CHARACTER = 'c' --收益特征是非保本浮动收益类
       AND B.BANK_ISSUE_FLG = 'Y' --只统计本行发行的，若本行代销的他行发行的理财产品不纳入统计
      LEFT JOIN SMTMODS_L_PUBL_RATE C
        ON C.DATA_DATE = I_DATADATE
       AND C.BASIC_CCY = A.CURR_CD --表外保证金折币
       AND C.FORWARD_CCY = 'CNY'
     WHERE A.DATA_DATE = I_DATADATE
       AND A.INV_AMT <> 0
     GROUP BY A.CUST_ID, A.DATA_DATE, A.ORG_NUM;

     COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '本行非保本理财产品进行的授信结束';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '表内外授信合计保证金、银行存单、国债 预处理开始';
    V_STEP_FLAG := 0;
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --处理时候，如果担保余额大于贷款余额，那么取贷款余额，否则取担保余额（其实就是不能大于借据余额）
    --表内授信
    INSERT 
    INTO CBRC_TM_L_ACCT_OBS_TEMP 
      (CUST_ID, SECURITY_AMT, DATA_DATE, FLAG,LOAN_NUM)
      SELECT 
       T1.CUST_ID,
       SUM(NVL(T1.SECURITY_AMT * T3.CCY_RATE, 0) + NVL(TM.DEP_AMT, 0) +
           NVL(TM.COLL_BILL_AMOUNT, 0)) AS SECURITY_AMT,
       I_DATADATE,
       '1' AS FLAG,
       T1.LOAN_NUM --贷款编号
        FROM SMTMODS_L_ACCT_LOAN T1
        LEFT JOIN SMTMODS_L_PUBL_RATE T3
          ON T3.DATA_DATE = I_DATADATE
         AND T3.BASIC_CCY = T1.SECURITY_CURR --表外保证金折币
         AND T3.FORWARD_CCY = 'CNY'
        LEFT JOIN (SELECT T2.CONTRACT_NUM,
                          SUM(NVL(T4.DEP_AMT * T6.CCY_RATE, 0)) AS DEP_AMT, --本行存单
                          SUM(NVL(T5.COLL_BILL_AMOUNT * T6.CCY_RATE, 0)) AS COLL_BILL_AMOUNT --国债
                     FROM SMTMODS_L_AGRE_GUA_RELATION T2
                     LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_RELATION T3
                       ON T2.GUAR_CONTRACT_NUM = T3.GUAR_CONTRACT_NUM
                      AND T3.DATA_DATE = I_DATADATE
                     LEFT JOIN SMTMODS_L_AGRE_GUARANTY_INFO T4
                       ON T3.GUARANTEE_SERIAL_NUM = T4.GUARANTEE_SERIAL_NUM
                      AND T4.DATA_DATE = I_DATADATE
                      AND T4.COLL_TYP='A0201' --  是否本行存单(Y是 N否)
                    --  AND T4.COLL_STATUS='Y' --押品状态为有效
                     LEFT JOIN SMTMODS_L_AGRE_GUARANTY_INFO T5
                       ON T3.GUARANTEE_SERIAL_NUM = T5.GUARANTEE_SERIAL_NUM
                      AND T5.DATA_DATE = I_DATADATE
                      AND T5.COLL_TYP IN ('A0602', 'A0603')
                   --   AND T5.COLL_STATUS='Y' --押品状态为有效
                     LEFT JOIN SMTMODS_L_PUBL_RATE T6
                       ON T6.DATA_DATE = I_DATADATE
                      AND T6.BASIC_CCY = T3.CURR_CD --担保物折币
                      AND T6.FORWARD_CCY = 'CNY'
                    WHERE T2.DATA_DATE = I_DATADATE
                    GROUP BY T2.CONTRACT_NUM) TM --押品类型为 A0602一级国家及地区的国债 A0603二级国家及地区的国债
          ON T1.ACCT_NUM = TM.CONTRACT_NUM
       WHERE T1.DATA_DATE = I_DATADATE
         AND T1.CANCEL_FLG = 'N'
         AND LENGTHB(T1.ACCT_NUM) < 36
     AND T1.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
       GROUP BY T1.CUST_ID,T1.LOAN_NUM;

    COMMIT;
    --表外授信
     INSERT 
     INTO CBRC_TM_L_ACCT_OBS_TEMP 
       (CUST_ID, SECURITY_AMT, DATA_DATE,FLAG,LOAN_NUM)
       SELECT 
        T1.CUST_ID,
        SUM(NVL(T1.SECURITY_AMT * T3.CCY_RATE, 0) + NVL(TM.DEP_AMT, 0) +
            NVL(TM.COLL_BILL_AMOUNT, 0))AS SECURITY_AMT,
        I_DATADATE,
        '2' AS FLAG,
        T1.ACCT_NUM  --表外账号
         FROM SMTMODS_L_ACCT_OBS_LOAN T1
         LEFT JOIN SMTMODS_L_PUBL_RATE T3
           ON T3.DATA_DATE = I_DATADATE
          AND T3.BASIC_CCY = T1.SECURITY_CURR --表外保证金折币
          AND T3.FORWARD_CCY = 'CNY'
         LEFT JOIN (SELECT T2.CONTRACT_NUM,
                           SUM(NVL(T4.DEP_AMT * T6.CCY_RATE, 0)) AS DEP_AMT, --本行存单
                           SUM(NVL(T5.COLL_BILL_AMOUNT * T6.CCY_RATE, 0)) AS COLL_BILL_AMOUNT --国债
                      FROM SMTMODS_L_AGRE_GUA_RELATION T2
                      LEFT JOIN SMTMODS_L_AGRE_GUARANTEE_RELATION T3
                        ON T2.GUAR_CONTRACT_NUM = T3.GUAR_CONTRACT_NUM
                       AND T3.DATA_DATE = I_DATADATE
                      LEFT JOIN SMTMODS_L_AGRE_GUARANTY_INFO T4
                        ON T3.GUARANTEE_SERIAL_NUM = T4.GUARANTEE_SERIAL_NUM
                       AND T4.DATA_DATE = I_DATADATE
                       AND T4.COLL_TYP='A0201' --  是否本行存单(Y是 N否)
                      -- AND T4.COLL_STATUS='Y' --押品状态为有效
                      LEFT JOIN SMTMODS_L_AGRE_GUARANTY_INFO T5
                        ON T3.GUARANTEE_SERIAL_NUM = T5.GUARANTEE_SERIAL_NUM
                       AND T5.DATA_DATE = I_DATADATE
                       AND T5.COLL_TYP IN ('A0602', 'A0603')
                      -- AND T5.COLL_STATUS='Y' --押品状态为有效
                      LEFT JOIN SMTMODS_L_PUBL_RATE T6
                        ON T6.DATA_DATE = I_DATADATE
                       AND T6.BASIC_CCY = T3.CURR_CD --担保物折币
                       AND T6.FORWARD_CCY = 'CNY'
                     WHERE T2.DATA_DATE = I_DATADATE
                     GROUP BY T2.CONTRACT_NUM) TM --押品类型为 A0602一级国家及地区的国债 A0603二级国家及地区的国债
           ON T1.ACCT_NUM = TM.CONTRACT_NUM
        WHERE T1.DATA_DATE = I_DATADATE
        GROUP BY T1.CUST_ID,T1.ACCT_NUM ;
     COMMIT;
              --AND (T1.GL_ITEM_CODE = 601 OR T1.GL_ITEM_CODE LIKE '612%');

    V_STEP_FLAG := 1;
    V_STEP_DESC := '表内外授信合计保证金、银行存单、国债预处理结束';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_DESC := '附注：逾期贷款金额预处理开始';
    V_STEP_FLAG := 0;
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    --逾期贷款预处理  处理方式同G0102
    --个人经营性
    --个人消费 还款方式 是 一次还本 取 贷款余额 否则 取 本金逾期金额

     --个人经营性 逾期<90天
    INSERT
    INTO CBRC_TM_L_ACCT_YQ_TEMP 
      (DATA_DATE, ORG_NUM, CUST_ID, LOAN_ACCT_BAL,FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       A.CUST_ID,
       SUM(NVL(LOAN_ACCT_BAL, 0) * U.CCY_RATE) AS LOAN_ACCT_BAL,
       '1' AS FLAG
        FROM  SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYS <= 90
         AND OD_DAYS > 0
         AND OD_FLG = 'Y'
         AND A.CANCEL_FLG = 'N' AND LENGTHB(A.ACCT_NUM) < 36
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND ORG_NUM <> '009803'
         AND ACCT_TYP LIKE '0102%' --个人经营性
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
       GROUP BY ORG_NUM, A.CUST_ID;
     COMMIT;
  --个人消费 逾期<90天 还款方式 是 一次还本 取 贷款余额 否则 取 本金逾期金额

    INSERT 
    INTO CBRC_TM_L_ACCT_YQ_TEMP 
      (DATA_DATE, ORG_NUM, CUST_ID, LOAN_ACCT_BAL,FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       A.CUST_ID,
       SUM(CASE
             WHEN  a.REPAY_TYP ='1' and  a.PAY_TYPE in   ('01','02','10','11')  THEN --JLBA202412040012按月分期还款的个人消费贷款本金或利息逾期，逾期贷款在逾期时间90天以内的取逾期部分，逾期90天以上的取贷款余额
              OD_LOAN_ACCT_BAL * U.CCY_RATE
             ELSE
              LOAN_ACCT_BAL * U.CCY_RATE
           END) AS LOAN_ACCT_BAL,
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYS > 0
         AND OD_DAYS <= 90
         AND OD_FLG = 'Y'
         AND A.CANCEL_FLG = 'N' AND LENGTHB(A.ACCT_NUM) < 36
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND ACCT_TYP NOT LIKE '0102%' --除个人经营性以外所有
         AND ACCT_TYP LIKE '01%' --个人贷款
         AND ORG_NUM <> '009803'
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
       GROUP BY ORG_NUM, A.CUST_ID;
     COMMIT;

  --个人经营性、个人消费逾期>90天
    INSERT 
    INTO CBRC_TM_L_ACCT_YQ_TEMP 
      (DATA_DATE, ORG_NUM, CUST_ID, LOAN_ACCT_BAL,FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       A.CUST_ID,
       SUM(NVL(LOAN_ACCT_BAL, 0) * U.CCY_RATE) AS LOAN_ACCT_BAL,
       '3' AS FLAG
        FROM SMTMODS_L_ACCT_LOAN A
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.DATA_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE OD_DAYS > 90
         AND OD_FLG = 'Y'
         AND A.CANCEL_FLG = 'N' AND LENGTHB(A.ACCT_NUM) < 36
         AND LOAN_GRADE_CD IN ('1', '2', '3', '4', '5')
         AND A.DATA_DATE = I_DATADATE
         AND ORG_NUM <> '009803'
         AND ACCT_TYP LIKE '01%' --个人贷款
     AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
       GROUP BY ORG_NUM, A.CUST_ID;
     COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '附注：逾期贷款金额预处理结束';
        SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 --------------------------------------------------------------------------------------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '获取最大十家自然人或法人关联方开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
  /* modify by djh 20220713 G15处理原来数据+信用卡
   一个客户证件对应多个客户id，处理方式统一按照证件号处理业务对应数据，最后关联客户名称
   */

     ---支行排序  净额排序：表内外授信扣除保证金、银行存单、国债后的净额

    INSERT INTO CBRC_G15_TEMP

      SELECT T2.ORG_NUM,
             '' AS CUST_NAME,
             '' AS CUST_ID,
             T2.ID_NO,
             T2.CO1,
             T2.CO2,
             T2.CO3,
             T2.CO4,
             T2.CO5,
             T2.CO6,
             T2.CO7,
             T2.SEQ_NO, --序号
             T2.CO8
        FROM (SELECT T1.*,
                     ROW_NUMBER() OVER(PARTITION BY T1.ORG_NUM ORDER BY T1.CO7 DESC, T1.ORG_NUM, T1.ID_NO) AS SEQ_NO
                FROM ( -- 由于同一个客户在不同机构发生业务 在上级机构排序时也会按照两笔计算 但实际是同一个人 所以在此处再分组归并为一条
                      SELECT T.ORG_NUM AS ORG_NUM,
                             T.ID_NO,
                             SUM(CO1) CO1, --表内授信（各项贷款）
                             SUM(CO2) CO2, --表内授信（债券投资账面余额）
                             SUM(CO3) CO3, --表外授信（不可撤销的承诺及或有负债）
                             SUM(CO4) CO4, --表内外授信合计（保证金、银行存单、国债 ）
                             SUM(CO5) CO5, --附注：不良贷款余额
                             SUM(CO5) CO6, -- 附注：逾期贷款金额
                             SUM(CO1) + SUM(CO2) + SUM(CO3) + SUM(CO8) - SUM(CO4) CO7, --净额
                             SUM(CO8) CO8 --本行非保本理财产品进行的授信

                        FROM (SELECT B.ORG_CODE AS ORG_NUM,
                                     -- T.CUST_NAME,
                                     -- T.CUST_ID,
                                     T.ID_NO,
                                     SUM(CO1) CO1, --表内授信（各项贷款）
                                     SUM(CO2) CO2, --表内授信（债券投资账面余额）
                                     SUM(CO3) CO3, --表外授信（不可撤销的承诺及或有负债）
                                     SUM(CO4) CO4, --表内外授信合计（保证金、银行存单、国债 ）
                                     SUM(CO5) CO5, --附注：不良贷款余额
                                     SUM(CO5) CO6, -- 附注：逾期贷款金额
                                     SUM(CO1) + SUM(CO2) + SUM(CO3) + SUM(CO8) -
                                     SUM(CO4) CO7, --净额,
                                     SUM(CO8) CO8 --本行非保本理财产品进行的授信
                                FROM (SELECT 
                                       L.ORG_NUM,
                                       L.CUST_ID,
                                       G.ID_NO,
                                       G.ID_NAME AS CUST_NAME,
                                       SUM(L.LOAN_ACCT_BAL) AS CO1, --贷款余额
                                       0 AS CO2, --表内授信（债券投资账面余额）
                                       0 AS CO3, --表外授信（不可撤销的承诺及或有负债）
                                       SUM(CASE
                                             WHEN L.LOAN_ACCT_BAL <
                                                  NVL(K.SECURITY_AMT, 0) THEN
                                              L.LOAN_ACCT_BAL
                                             ELSE
                                              NVL(K.SECURITY_AMT, 0)
                                           END) AS CO4, --表内外授信合计（保证金、银行存单、国债 ）
                                       SUM(CASE
                                             WHEN L.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                                              L.LOAN_ACCT_BAL
                                             ELSE
                                              0
                                           END) CO5, --附注：不良贷款余额
                                       0 AS CO6, -- 附注：逾期贷款金额
                                       0 AS CO8 --本行非保本理财产品进行的授信
                                        FROM CBRC_TM_CBRC_G15_TEMP G
                                       INNER JOIN SMTMODS_L_CUST_ALL A
                                          ON G.ID_NO = A.ID_NO
                                         AND A.DATA_DATE = G.DDATE
                                       INNER JOIN SMTMODS_L_ACCT_LOAN L
                                          ON A.CUST_ID = L.CUST_ID
                                         AND L.DATA_DATE = A.DATA_DATE
                                         AND L.LOAN_ACCT_BAL <> 0 ---ADD BY CHM 20220104
                                         AND L.ACCT_TYP NOT LIKE '90%' --剔除委托贷款业务 add by shiyu 20220706
                                        LEFT JOIN CBRC_TM_L_ACCT_OBS_TEMP K
                                          ON L.LOAN_NUM = K.LOAN_NUM
                                         AND L.DATA_DATE = K.DATA_DATE
                                         AND K.FLAG = '1' --表内抵押物（保证金、银行存单、国债 ）
                                       WHERE A.DATA_DATE = I_DATADATE
                                         AND L.CANCEL_FLG = 'N'
                                         AND LENGTHB(L.ACCT_NUM) < 36
                     AND L.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
                                       GROUP BY L.CUST_ID,
                                                L.ORG_NUM,
                                                G.ID_NO,
                                                G.ID_NAME
                                      UNION ALL
                                      SELECT 
                                       CASE
                                         WHEN T1.STOCK_PRO_TYPE LIKE 'D%' THEN
                                          '009817'
                                         ELSE
                                          L.ORG_NUM
                                       END AS ORG_NUM, --与金市、投行确认 非金融企业债虽然归属在金市 但应该由投行报送 所以在此处特殊处理机构
                                       L.CUST_ID,
                                       G.ID_NO,
                                       G.ID_NAME AS CUST_NAME,
                                       0 AS CO1, --贷款余额
                                       SUM(L.FACE_VAL) AS CO2, --表内授信（债券投资账面余额）
                                       0 AS CO3, --表外授信（不可撤销的承诺及或有负债）
                                       0 AS CO4, --表内外授信合计（保证金、银行存单、国债 ）
                                       0 AS CO5, --附注：不良贷款余额
                                       0 AS CO6, -- 附注：逾期贷款金额
                                       0 AS CO8 --本行非保本理财产品进行的授信
                                        FROM CBRC_TM_CBRC_G15_TEMP G
                                       INNER JOIN SMTMODS_L_CUST_ALL A
                                          ON G.ID_NO = A.ID_NO
                                         AND A.DATA_DATE = G.DDATE
                                       INNER JOIN SMTMODS_L_ACCT_FUND_INVEST L
                                          ON A.CUST_ID = L.CUST_ID
                                         AND L.DATA_DATE = A.DATA_DATE
                                         AND L.FACE_VAL <> 0
                                         AND L.INVEST_TYP = '00' --投资业务品种  00 债券投资
                                       INNER JOIN SMTMODS_L_AGRE_BOND_INFO T1
                                          ON L.SUBJECT_CD = T1.STOCK_CD
                                         AND T1.DATA_DATE = I_DATADATE
                                       WHERE A.DATA_DATE = I_DATADATE
                                       GROUP BY L.CUST_ID,
                                                CASE
                                                  WHEN T1.STOCK_PRO_TYPE LIKE 'D%' THEN
                                                   '009817'
                                                  ELSE
                                                   L.ORG_NUM
                                                END,
                                                G.ID_NO,
                                                G.ID_NAME
                                      UNION ALL
                                      SELECT 
                                       L.ORG_NUM,
                                       L.CUST_ID,
                                       G.ID_NO,
                                       G.ID_NAME AS CUST_NAME,
                                       0 AS CO1, --贷款余额
                                       0 AS CO2, --表内授信（债券投资账面余额）
                                       SUM(L.UNUSED_AMT) AS CO3, --表外授信（不可撤销的承诺及或有负债）
                                       SUM(CASE
                                             WHEN L.UNUSED_AMT < NVL(K.SECURITY_AMT, 0) THEN
                                              L.UNUSED_AMT
                                             ELSE
                                              NVL(K.SECURITY_AMT, 0)
                                           END) AS CO4, --表外授信合计（保证金、银行存单、国债 ）
                                       0 AS CO5, --附注：不良贷款余额
                                       0 AS CO6, -- 附注：逾期贷款金额
                                       0 AS CO8 --本行非保本理财产品进行的授信
                                        FROM CBRC_TM_CBRC_G15_TEMP G
                                       INNER JOIN SMTMODS_L_CUST_ALL A
                                          ON G.ID_NO = A.ID_NO
                                         AND A.DATA_DATE = G.DDATE
                                       INNER JOIN CBRC_TM_L_ACCT_UNUSED_TEMP L
                                          ON A.CUST_ID = L.CUST_ID
                                         AND L.DATA_DATE = A.DATA_DATE
                                         AND L.UNUSED_AMT <> 0
                                        LEFT JOIN CBRC_TM_L_ACCT_OBS_TEMP K
                                          ON L.ACCT_NUM = K.LOAN_NUM
                                         AND L.DATA_DATE = K.DATA_DATE
                                         AND K.FLAG = '2' --表外抵押物（保证金、银行存单、国债 ）
                                      -- AND K.SECURITY_AMT<>0
                                       WHERE A.DATA_DATE = I_DATADATE
                                       GROUP BY L.CUST_ID,
                                                L.ORG_NUM,
                                                G.ID_NO,
                                                G.ID_NAME
                                      UNION ALL
                                      SELECT 
                                       L.ORG_NUM,
                                       L.CUST_ID,
                                       G.ID_NO,
                                       G.ID_NAME AS CUST_NAME,
                                       0 AS CO1,
                                       0 AS CO2, --表内授信（债券投资账面余额）
                                       0 AS CO3, --表外授信（不可撤销的承诺及或有负债）
                                       0 AS CO4, --表内外授信合计（保证金、银行存单、国债 ）
                                       0 AS CO5, --附注：不良贷款余额
                                       SUM(L.LOAN_ACCT_BAL) AS CO6, -- 附注：逾期贷款金额
                                       0 AS CO8 --本行非保本理财产品进行的授信
                                        FROM CBRC_TM_CBRC_G15_TEMP G
                                       INNER JOIN SMTMODS_L_CUST_ALL A
                                          ON G.ID_NO = A.ID_NO
                                         AND A.DATA_DATE = G.DDATE
                                       INNER JOIN CBRC_TM_L_ACCT_YQ_TEMP L
                                          ON A.CUST_ID = L.CUST_ID
                                         AND A.DATA_DATE = L.DATA_DATE
                                         AND L.LOAN_ACCT_BAL <> 0
                                       WHERE A.DATA_DATE = I_DATADATE
                                       GROUP BY L.CUST_ID,
                                                L.ORG_NUM,
                                                G.ID_NO,
                                                G.ID_NAME
                                      UNION ALL
                                      SELECT 
                                       L.ORG_NUM,
                                       L.CUST_ID,
                                       G.ID_NO,
                                       G.ID_NAME AS CUST_NAME,
                                       0 AS CO1,
                                       0 AS CO2, --表内授信（债券投资账面余额）
                                       0 AS CO3, --表外授信（不可撤销的承诺及或有负债）
                                       0 AS CO4, --表内外授信合计（保证金、银行存单、国债 ）
                                       0 AS CO5, --附注：不良贷款余额
                                       0 AS CO6, -- 附注：逾期贷款金额,
                                       SUM(NONFINANCIAL_AMT) AS CO8 --本行非保本理财产品进行的授信
                                        FROM CBRC_TM_CBRC_G15_TEMP G
                                     
                                       INNER JOIN CBRC_TM_L_ACCT_NONFINANCIAL_TEMP L
                                          ON G.ID_NO = L.CUST_ID
                                         AND G.DDATE = L.DATA_DATE
                                       WHERE G.DDATE = I_DATADATE
                                       GROUP BY L.CUST_ID,
                                                L.ORG_NUM,
                                                G.ID_NO,
                                                G.ID_NAME) T
                               INNER JOIN CBRC_TM_L_ORG_FLAT B
                                  ON 
                               T.ORG_NUM = B.SUB_ORG_CODE
                               GROUP BY B.ORG_CODE, T.ID_NO) T
                       GROUP BY T.ORG_NUM, T.ID_NO) T1) T2;
    COMMIT;


--用证件号关联全量客户表，更新名称
MERGE INTO CBRC_G15_TEMP T
USING (SELECT CUST_NAM, ID_NO
         FROM (SELECT 
                CUST_NAM,
                ID_NO,
                ROW_NUMBER() OVER(PARTITION BY ID_NO ORDER BY CUST_NAM DESC) AS RN
                 FROM SMTMODS_L_CUST_ALL --存在一个证件号对应多个客户名称，排序后取一个，与信用卡规则保持一致（SP_TOPN_G15_019803）
                WHERE DATA_DATE = I_DATADATE)
        WHERE RN = 1) T2
ON (T.ID_NO = T2.ID_NO)
WHEN MATCHED THEN
  UPDATE SET T.CUST_NAME = T2.CUST_NAM;
COMMIT;

    --最大十家自然人或法人关联方        关联方名称
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_1_B'
               WHEN T.SEQ_NO = '2' THEN
                'G15_2_B'
               WHEN T.SEQ_NO = '3' THEN
                'G15_3_B'
               WHEN T.SEQ_NO = '4' THEN
                'G15_4_B'
               WHEN T.SEQ_NO = '5' THEN
                'G15_5_B'
               WHEN T.SEQ_NO = '6' THEN
                'G15_6_B'
               WHEN T.SEQ_NO = '7' THEN
                'G15_7_B'
               WHEN T.SEQ_NO = '8' THEN
                'G15_8_B'
               WHEN T.SEQ_NO = '9' THEN
                'G15_9_B'
               WHEN T.SEQ_NO = '10' THEN
                'G15_10_B'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             T.CUST_NAME AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --最大十家自然人或法人关联方        客户代码
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_1_C'
               WHEN T.SEQ_NO = '2' THEN
                'G15_2_C'
               WHEN T.SEQ_NO = '3' THEN
                'G15_3_C'
               WHEN T.SEQ_NO = '4' THEN
                'G15_4_C'
               WHEN T.SEQ_NO = '5' THEN
                'G15_5_C'
               WHEN T.SEQ_NO = '6' THEN
                'G15_6_C'
               WHEN T.SEQ_NO = '7' THEN
                'G15_7_C'
               WHEN T.SEQ_NO = '8' THEN
                'G15_8_C'
               WHEN T.SEQ_NO = '9' THEN
                'G15_9_C'
               WHEN T.SEQ_NO = '10' THEN
                'G15_10_C'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             T.ID_NO AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --最大十家自然人或法人关联方        关联方类型

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_1_D'
               WHEN T.SEQ_NO = '2' THEN
                'G15_2_D'
               WHEN T.SEQ_NO = '3' THEN
                'G15_3_D'
               WHEN T.SEQ_NO = '4' THEN
                'G15_4_D'
               WHEN T.SEQ_NO = '5' THEN
                'G15_5_D'
               WHEN T.SEQ_NO = '6' THEN
                'G15_6_D'
               WHEN T.SEQ_NO = '7' THEN
                'G15_7_D'
               WHEN T.SEQ_NO = '8' THEN
                'G15_8_D'
               WHEN T.SEQ_NO = '9' THEN
                'G15_9_D'
               WHEN T.SEQ_NO = '10' THEN
                'G15_10_D'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             DECODE(T1.FLAG, '1', '关联法人', '关联自然人') AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP T
        LEFT JOIN CBRC_TM_CBRC_G15_TEMP T1
          ON T.ID_NO = T1.ID_NO
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --最大十家自然人或法人关联方        各项贷款

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_1_H'
               WHEN T.SEQ_NO = '2' THEN
                'G15_2_H'
               WHEN T.SEQ_NO = '3' THEN
                'G15_3_H'
               WHEN T.SEQ_NO = '4' THEN
                'G15_4_H'
               WHEN T.SEQ_NO = '5' THEN
                'G15_5_H'
               WHEN T.SEQ_NO = '6' THEN
                'G15_6_H'
               WHEN T.SEQ_NO = '7' THEN
                'G15_7_H'
               WHEN T.SEQ_NO = '8' THEN
                'G15_8_H'
               WHEN T.SEQ_NO = '9' THEN
                'G15_9_H'
               WHEN T.SEQ_NO = '10' THEN
                'G15_10_H'
             END AS ITEM_NUM,
             T.CO1 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --最大十家自然人或法人关联方 债券投资
        INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_1_I'
               WHEN T.SEQ_NO = '2' THEN
                'G15_2_I'
               WHEN T.SEQ_NO = '3' THEN
                'G15_3_I'
               WHEN T.SEQ_NO = '4' THEN
                'G15_4_I'
               WHEN T.SEQ_NO = '5' THEN
                'G15_5_I'
               WHEN T.SEQ_NO = '6' THEN
                'G15_6_I'
               WHEN T.SEQ_NO = '7' THEN
                'G15_7_I'
               WHEN T.SEQ_NO = '8' THEN
                'G15_8_I'
               WHEN T.SEQ_NO = '9' THEN
                'G15_9_I'
               WHEN T.SEQ_NO = '10' THEN
                'G15_10_I'
             END AS ITEM_NUM,
             T.CO2 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --最大十家自然人或法人关联方        不可撤销的承诺及或有负债

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_1_L'
               WHEN T.SEQ_NO = '2' THEN
                'G15_2_L'
               WHEN T.SEQ_NO = '3' THEN
                'G15_3_L'
               WHEN T.SEQ_NO = '4' THEN
                'G15_4_L'
               WHEN T.SEQ_NO = '5' THEN
                'G15_5_L'
               WHEN T.SEQ_NO = '6' THEN
                'G15_6_L'
               WHEN T.SEQ_NO = '7' THEN
                'G15_7_L'
               WHEN T.SEQ_NO = '8' THEN
                'G15_8_L'
               WHEN T.SEQ_NO = '9' THEN
                'G15_9_L'
               WHEN T.SEQ_NO = '10' THEN
                'G15_10_L'
             END AS ITEM_NUM,
             T.CO3 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;
  --最大十家自然人或法人关联方  本行非保本理财产品进行的授信 ADD BY DJH 20230425

 INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_1_M'
               WHEN T.SEQ_NO = '2' THEN
                'G15_2_M'
               WHEN T.SEQ_NO = '3' THEN
                'G15_3_M'
               WHEN T.SEQ_NO = '4' THEN
                'G15_4_M'
               WHEN T.SEQ_NO = '5' THEN
                'G15_5_M'
               WHEN T.SEQ_NO = '6' THEN
                'G15_6_M'
               WHEN T.SEQ_NO = '7' THEN
                'G15_7_M'
               WHEN T.SEQ_NO = '8' THEN
                'G15_8_M'
               WHEN T.SEQ_NO = '9' THEN
                'G15_9_M'
               WHEN T.SEQ_NO = '10' THEN
                'G15_10_M'
             END AS ITEM_NUM,
             T.CO8 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --最大十家自然人或法人关联方        保证金、银行存单、国债

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位 出现在
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_1_P'
               WHEN T.SEQ_NO = '2' THEN
                'G15_2_P'
               WHEN T.SEQ_NO = '3' THEN
                'G15_3_P'
               WHEN T.SEQ_NO = '4' THEN
                'G15_4_P'
               WHEN T.SEQ_NO = '5' THEN
                'G15_5_P'
               WHEN T.SEQ_NO = '6' THEN
                'G15_6_P'
               WHEN T.SEQ_NO = '7' THEN
                'G15_7_P'
               WHEN T.SEQ_NO = '8' THEN
                'G15_8_P'
               WHEN T.SEQ_NO = '9' THEN
                'G15_9_P'
               WHEN T.SEQ_NO = '10' THEN
                'G15_10_P'
             END AS ITEM_NUM,
             T.CO4 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;
     -- 最大十家自然人或法人关联方 附注：不良贷款余额

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位 出现在
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_1_R'
               WHEN T.SEQ_NO = '2' THEN
                'G15_2_R'
               WHEN T.SEQ_NO = '3' THEN
                'G15_3_R'
               WHEN T.SEQ_NO = '4' THEN
                'G15_4_R'
               WHEN T.SEQ_NO = '5' THEN
                'G15_5_R'
               WHEN T.SEQ_NO = '6' THEN
                'G15_6_R'
               WHEN T.SEQ_NO = '7' THEN
                'G15_7_R'
               WHEN T.SEQ_NO = '8' THEN
                'G15_8_R'
               WHEN T.SEQ_NO = '9' THEN
                'G15_9_R'
               WHEN T.SEQ_NO = '10' THEN
                'G15_10_R'
             END AS ITEM_NUM,
             T.CO5 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

     -- 最大十家自然人或法人关联方 附注：逾期贷款金额
       INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位 出现在
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_1_S'
               WHEN T.SEQ_NO = '2' THEN
                'G15_2_S'
               WHEN T.SEQ_NO = '3' THEN
                'G15_3_S'
               WHEN T.SEQ_NO = '4' THEN
                'G15_4_S'
               WHEN T.SEQ_NO = '5' THEN
                'G15_5_S'
               WHEN T.SEQ_NO = '6' THEN
                'G15_6_S'
               WHEN T.SEQ_NO = '7' THEN
                'G15_7_S'
               WHEN T.SEQ_NO = '8' THEN
                'G15_8_S'
               WHEN T.SEQ_NO = '9' THEN
                'G15_9_S'
               WHEN T.SEQ_NO = '10' THEN
                'G15_10_S'
             END AS ITEM_NUM,
             T.CO6 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;



    V_STEP_FLAG := 1;
    V_STEP_DESC := '获取最大十家自然人或法人关联方完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '获取最大十家自然人或法人关联集团报告期内最高风险额（净额）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --报告期内最高风险额（净额）以本季度为基准，上季度与本季度比哪个大取哪一个
    --本季度
      INSERT INTO CBRC_TM_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG, --标志位
       ID_NO --证件号
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_1_F'
               WHEN T.SEQ_NO = '2' THEN
                'G15_2_F'
               WHEN T.SEQ_NO = '3' THEN
                'G15_3_F'
               WHEN T.SEQ_NO = '4' THEN
                'G15_4_F'
               WHEN T.SEQ_NO = '5' THEN
                'G15_5_F'
               WHEN T.SEQ_NO = '6' THEN
                'G15_6_F'
               WHEN T.SEQ_NO = '7' THEN
                'G15_7_F'
               WHEN T.SEQ_NO = '8' THEN
                'G15_8_F'
               WHEN T.SEQ_NO = '9' THEN
                'G15_9_F'
               WHEN T.SEQ_NO = '10' THEN
                'G15_10_F'
             END AS ITEM_NUM,
             T.CO7 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG,
             ID_NO
        FROM CBRC_G15_TEMP T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '获取最大十家自然人或法人关联集团报告期内最高风险额（净额）完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '获取最大十家自然人或法人关联上季度与本季度差值比较';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, --数据日期
     ORG_NUM, --机构号
     SYS_NAM, --模块简称
     REP_NUM, --报表编号
     ITEM_NUM, --指标号
     ITEM_VAL, --指标值（数值型）
     ITEM_VAL_V, --指标值（字符型）
     FLAG --标志位
     )

---RESULT取本期，本季度
WITH TEMP_G15_BQ AS
 (SELECT ORG_NUM,
         ITEM_NUM,
         ITEM_VAL,
         ITEM_VAL_V AS ID_NAME, --此行取名字
         ID_NO --另外一列取取身份证
    FROM CBRC_TM_A_REPT_ITEM_VAL A
   WHERE A.DATA_DATE = I_DATADATE),

---WORK取数,上季度
TEMP_G15_SQ AS
 (SELECT ROW_NUM,
         ORG_NUM,
         MAX(ID_NAME) ID_NAME,
         MAX(ID_NO) AS ID_NO,
         MAX(ITEM_NUM) AS ITEM_NUM,
         MAX(PV) AS PV
    FROM (SELECT CASE
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '8' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '9' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '10' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '11' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '12' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '13' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '14' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '15' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '16' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '17' THEN
                    A.PV_STR
                 END AS ID_NAME,
                 CASE
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '8' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '9' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '10' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '11' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '12' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '13' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '14' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '15' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '16' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '17' THEN
                    A.PV_STR
                 END AS ID_NO,
                 CASE
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '8' THEN
                    'G15_1_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '9' THEN
                    'G15_2_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '10' THEN
                    'G15_3_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '11' THEN
                    'G15_4_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '12' THEN
                    'G15_5_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '13' THEN
                    'G15_6_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '14' THEN
                    'G15_7_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '15' THEN
                    'G15_8_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '16' THEN
                    'G15_9_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '17' THEN
                    'G15_10_F'
                 END AS ITEM_NUM,
                 CASE
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '8' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '9' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '10' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '11' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '12' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '13' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '14' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '15' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '16' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '17' THEN
                    A.PV
                 END AS PV,
                 A.ROW_NUM AS ROW_NUM,
                 A.DBANK_ID AS ORG_NUM
            FROM CBRC_G15 A   --DATAX 落地表
           WHERE REPLACE(A.DDATE,'-','')= TO_CHAR(LAST_DAY(ADD_MONTHS(DATE(I_DATADATE), -3)),'YYYYMMDD')   --上季度末
             AND A.COL_NUM IN ('3', '4', '16')
           --  AND DBANK_ID = '100000'
             AND ROW_NUM BETWEEN 8 AND 17)
   GROUP BY ROW_NUM,ORG_NUM
   ORDER BY ROW_NUM)

SELECT I_DATADATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G15' AS REP_NUM,
       A.ITEM_NUM AS ITEM_NUM,
       CASE
         WHEN NVL(A.ITEM_VAL, 0) > NVL(B.PV, 0) THEN
          NVL(A.ITEM_VAL, 0)
         ELSE
          NVL(B.PV, 0)
       END AS ITEM_VAL,
       '' AS ITEM_VAL_V,
       '1' AS FLAG /*,
       A.ID_NO,
       A.ID_NAME,
       NVL(A.ITEM_VAL, 0),
       NVL(B.PV, 0) */
  FROM TEMP_G15_BQ A
  LEFT JOIN TEMP_G15_SQ B
    ON A.ORG_NUM = B.ORG_NUM
   AND A.ID_NO = B.ID_NO;
COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '获取最大十家自然人或法人关联上季度与本季度差值比较完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

 ---------------------------------------------------------------------------------------------------
  ----最大十家关联集团
 ---------------------------------------------------------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '最大十家集团：获取自然人及集团子公司（法人）明细信息开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);


 INSERT INTO CBRC_TM_CBRC_G15_TEMP1
  (ID_NO, ID_NAME,ID_NAME_M,DDATE,FLAG,ID_ROW_NO)
  SELECT DISTINCT TRIM(C.PV_STR) AS ID_NO,  --法人ID
                  TRIM(B.PV_STR) AS  ID_NAME,--TRIM(B.PV_STR) AS ID_NAME, 不取法人，取法人对应集团名称
                  TRIM(D.PV_STR) AS ID_NAME_M, --法人对应集团名称，数据分组时真正用的名称
                  I_DATADATE,
                  '1' AS FLAG, --法人有对应集团
                  ''  AS ID_ROW_NO --法人有对应集团ID 后面做更新,数据分组时真正用的ID
    FROM  CBRC_GLFRXXB A
   INNER JOIN  CBRC_GLFRXXB B
      ON A.ROW_NUM = B.ROW_NUM
     AND A.DDATE = B.DDATE
     AND B.COL_NUM = '3'
   INNER JOIN  CBRC_GLFRXXB C
      ON A.ROW_NUM = C.ROW_NUM
     AND A.DDATE = C.DDATE
     AND C.COL_NUM = '6'
   INNER JOIN  CBRC_GLFRXXB D
      ON A.ROW_NUM = D.ROW_NUM
     AND A.DDATE = D.DDATE
     AND D.COL_NUM = '4'
   WHERE A.COL_NUM = '5.000000'
     AND A.DDATE = V_DATADATE
     AND TRIM(D.PV_STR) <> '无';
     COMMIT;
    -- AND (TRIM(D.PV_STR) <>'0.0' OR TRIM(D.PV_STR) <> '无' )
  INSERT INTO CBRC_TM_CBRC_G15_TEMP1
  (ID_NO, ID_NAME,ID_NAME_M,DDATE,FLAG,ID_ROW_NO)
   SELECT DISTINCT TRIM(C.PV_STR) AS ID_NO,  --法人ID
                  ''/*TRIM(B.PV_STR)*/ AS ID_NAME, --法人名称
                  ''/*TRIM(D.PV_STR)*/ AS ID_NAME_M,--法人对应集团名称,但是这个都是'0.0' 数据分组时真正用的名称
                  I_DATADATE,
                  '2' AS FLAG, --法人无对应集团
                  TRIM(C.PV_STR) AS ID_ROW_NO --法人ID,数据分组时真正用的ID
    FROM  CBRC_GLFRXXB A
   INNER JOIN  CBRC_GLFRXXB B
      ON A.ROW_NUM = B.ROW_NUM
     AND A.DDATE = B.DDATE
     AND B.COL_NUM = '3'
   INNER JOIN  CBRC_GLFRXXB C
      ON A.ROW_NUM = C.ROW_NUM
     AND A.DDATE = C.DDATE
     AND C.COL_NUM = '6'
   INNER JOIN  CBRC_GLFRXXB D
      ON A.ROW_NUM = D.ROW_NUM
     AND A.DDATE = D.DDATE
     AND D.COL_NUM = '4'
   WHERE A.COL_NUM = '5.000000'
     AND A.DDATE = V_DATADATE ---法人
     AND TRIM(D.PV_STR) IN (/*'0.0' ,*/ '无');

     COMMIT;
  INSERT INTO CBRC_TM_CBRC_G15_TEMP1
  (ID_NO, ID_NAME,ID_NAME_M,DDATE,FLAG,ID_ROW_NO)
  SELECT DISTINCT TRIM(G.PV_STR) AS ID_NO, --自然人ID
                 '' AS CUST_NAME,--自然人名称
                 '' /*TRIM(GG.PV_STR)*/ AS ID_NAME_M,--数据分组时真正用的名称
                  I_DATADATE,
                  '3' AS FLAG, --自然人
                  TRIM(G.PV_STR) AS ID_ROW_NO --自然人ID,数据分组时真正用的ID
    FROM  CBRC_GLRXXB G
   INNER JOIN  CBRC_GLRXXB GG
      ON G.ROW_NUM = GG.ROW_NUM
     AND G.DDATE = GG.DDATE
     AND GG.COL_NUM = 2
   WHERE G.DDATE = V_DATADATE --自然人
     AND G.COL_NUM = 4
     AND (LENGTH(TRIM(G.PV_STR)) = 18 OR LENGTH(TRIM(G.PV_STR)) = 10); ---10 是香港身份证

COMMIT;

--更新法人有对应集团ID_ROW_NO 字段
MERGE INTO CBRC_TM_CBRC_G15_TEMP1 A
USING (SELECT A.ID_NO, A.ID_NAME_M
         FROM CBRC_TM_CBRC_G15_TEMP1 A
        INNER JOIN (SELECT DISTINCT ID_NAME_M
                     FROM CBRC_TM_CBRC_G15_TEMP1
                    WHERE FLAG = '1') B
           ON A.ID_NAME = B.ID_NAME_M AND A.FLAG = '1') B
ON (A.ID_NAME_M = B.ID_NAME_M )
WHEN MATCHED THEN
  UPDATE SET A.ID_ROW_NO = B.ID_NO;
COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '最大十家集团：获取自然人及集团子公司（法人）明细信息完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--------------------------------------------------------------------------------------
    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '获取最大十家关联集团开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
 ---关联集团   法人&自然人排序

    INSERT INTO CBRC_G15_TEMP1
        SELECT T2.ORG_NUM,
           '' AS CUST_NAME,
           '' AS CUST_ID,
           T2.ID_NO,
           T2.CO1,
           T2.CO2,
           T2.CO3,
           T2.CO4,
           T2.CO5,
           T2.CO6,
           T2.CO7,
           T2.SEQ_NO, --序号
           T2.CO8
      FROM (SELECT T1.*,
                   ROW_NUMBER() OVER(PARTITION BY T1.ORG_NUM ORDER BY T1.CO7 DESC, T1.ORG_NUM, T1.ID_NO) AS SEQ_NO
              FROM (
                  -- 由于同一个客户在不同机构发生业务 在上级机构排序时也会按照两笔计算 但实际是同一个人 所以在此处再分组归并为一条
                 SELECT T.ORG_NUM AS ORG_NUM,
                        T.ID_NO,
                        SUM(CO1) CO1, --表内授信（各项贷款）
                        SUM(CO2) CO2, --表内授信（债券投资账面余额）
                        SUM(CO3) CO3, --表外授信（不可撤销的承诺及或有负债）
                        SUM(CO4) CO4, --表内外授信合计（保证金、银行存单、国债 ）
                        SUM(CO5) CO5, --附注：不良贷款余额
                        SUM(CO5) CO6, -- 附注：逾期贷款金额
                        SUM(CO1) + SUM(CO2) + SUM(CO3) + SUM(CO8) - SUM(CO4) CO7, --净额
                        SUM(CO8) CO8 --本行非保本理财产品进行的授信

                  FROM (
                        SELECT B.ORG_CODE AS ORG_NUM,
                                   --  T.CUST_NAME,
                                   --  T.CUST_ID,
                                     T.ID_NO,
                                     SUM(CO1) CO1,--表内授信（各项贷款）
                                     SUM(CO2) CO2,--表内授信（债券投资账面余额）
                                     SUM(CO3) CO3,--表外授信（不可撤销的承诺及或有负债）
                                     SUM(CO4) CO4,--表内外授信合计（保证金、银行存单、国债 ）
                                     SUM(CO5) CO5,--附注：不良贷款余额
                                     SUM(CO5) CO6,-- 附注：逾期贷款金额
                                     SUM(CO1) + SUM(CO2) + SUM(CO3)+ SUM(CO8) -SUM(CO4) CO7, --净额
                                     SUM(CO8) CO8--本行非保本理财产品进行的授信
                                FROM (SELECT 
                                       L.ORG_NUM,
                                       '' AS CUST_ID,
                                       G.ID_ROW_NO AS ID_NO,
                                       G.ID_NAME_M AS CUST_NAME,
                                        SUM(L.LOAN_ACCT_BAL) AS CO1, --贷款余额
                                       0 AS CO2, --表内授信（债券投资账面余额）
                                       0 AS CO3, --表外授信（不可撤销的承诺及或有负债）
                                       SUM(CASE
                                             WHEN L.LOAN_ACCT_BAL < NVL(K.SECURITY_AMT, 0) THEN
                                              L.LOAN_ACCT_BAL
                                             ELSE
                                              NVL(K.SECURITY_AMT, 0)
                                           END) AS CO4, --表内外授信合计（保证金、银行存单、国债 ）
                                       SUM(CASE
                                         WHEN L.LOAN_GRADE_CD IN ('3', '4', '5') THEN
                                         L.LOAN_ACCT_BAL
                                         ELSE
                                          0
                                       END) CO5,--附注：不良贷款余额
                                       0 AS CO6,-- 附注：逾期贷款金额
                                       0 AS CO8 --本行非保本理财产品进行的授信
                                        FROM CBRC_TM_CBRC_G15_TEMP1 G
                                       INNER JOIN SMTMODS_L_CUST_ALL A
                                          ON G.ID_NO = A.ID_NO
                                         AND A.DATA_DATE = G.DDATE
                                       INNER JOIN SMTMODS_L_ACCT_LOAN L
                                          ON A.CUST_ID = L.CUST_ID
                                         AND L.DATA_DATE = A.DATA_DATE
                                         AND L.LOAN_ACCT_BAL <> 0 ---ADD BY CHM 20220104
                                         and l.acct_typ not like '90%' --add shiyu 剔除委托贷款
                                       LEFT  JOIN CBRC_TM_L_ACCT_OBS_TEMP K
                                          ON L.LOAN_NUM = K.LOAN_NUM
                                         AND L.DATA_DATE = K.DATA_DATE
                                         AND K.FLAG='1' --表内抵押物（保证金、银行存单、国债 ）
                                       WHERE A.DATA_DATE = I_DATADATE
                                       AND L.CANCEL_FLG = 'N' AND LENGTHB(L.ACCT_NUM) < 36
                     AND L.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 剔除资产转让借据
                                       GROUP BY /*L.CUST_ID,*/ L.ORG_NUM, G.ID_ROW_NO, G.ID_NAME_M
                                      UNION ALL
                                      SELECT 
                                       CASE
                                         WHEN T1.STOCK_PRO_TYPE LIKE 'D%' THEN '009817'
                                         ELSE L.ORG_NUM
                                       END AS ORG_NUM, --与金市、投行确认 非金融企业债虽然归属在金市 但应该由投行报送 所以在此处特殊处理机构
                                       '' AS CUST_ID,
                                       G.ID_ROW_NO AS ID_NO,
                                       G.ID_NAME_M AS CUST_NAME,
                                       0 AS CO1, --贷款余额
                                       SUM(L.FACE_VAL) AS CO2, --表内授信（债券投资账面余额）
                                       0 AS CO3, --表外授信（不可撤销的承诺及或有负债）
                                       0 AS CO4, --表内外授信合计（保证金、银行存单、国债 ）
                                       0 AS CO5,--附注：不良贷款余额
                                       0 AS CO6,-- 附注：逾期贷款金额
                                       0 AS CO8 --本行非保本理财产品进行的授信
                                        FROM CBRC_TM_CBRC_G15_TEMP1 G
                                       INNER JOIN SMTMODS_L_CUST_ALL A
                                          ON G.ID_NO = A.ID_NO
                                         AND A.DATA_DATE = G.DDATE
                                       INNER JOIN SMTMODS_L_ACCT_FUND_INVEST L
                                          ON A.CUST_ID = L.CUST_ID
                                         AND L.DATA_DATE = A.DATA_DATE
                                         AND L.FACE_VAL <> 0
                                         AND L.INVEST_TYP = '00' --投资业务品种  00 债券投资
                                       INNER JOIN SMTMODS_L_AGRE_BOND_INFO T1
                                          ON L.SUBJECT_CD = T1.STOCK_CD
                                         AND T1.DATA_DATE = I_DATADATE
                                       WHERE A.DATA_DATE = I_DATADATE
                                       GROUP BY /*L.CUST_ID,*/ CASE WHEN T1.STOCK_PRO_TYPE LIKE 'D%' THEN '009817' ELSE L.ORG_NUM END,G.ID_ROW_NO,G.ID_NAME_M
                                      UNION ALL
                                      SELECT 
                                       L.ORG_NUM,
                                       '' AS CUST_ID,
                                       G.ID_ROW_NO AS ID_NO,
                                       G.ID_NAME_M AS CUST_NAME,
                                        0 AS CO1, --贷款余额
                                       0 AS CO2, --表内授信（债券投资账面余额）
                                       SUM(L.UNUSED_AMT) AS CO3, --表外授信（不可撤销的承诺及或有负债）
                                       SUM(CASE
                                             WHEN L.UNUSED_AMT < NVL(K.SECURITY_AMT, 0) THEN
                                              L.UNUSED_AMT
                                             ELSE
                                              NVL(K.SECURITY_AMT, 0)
                                           END) AS CO4, --表外授信合计（保证金、银行存单、国债 ）
                                       0 AS CO5,--附注：不良贷款余额
                                       0 AS CO6,-- 附注：逾期贷款金额
                                       0 AS CO8 --本行非保本理财产品进行的授信
                                        FROM CBRC_TM_CBRC_G15_TEMP1 G
                                       INNER JOIN SMTMODS_L_CUST_ALL A
                                          ON G.ID_NO = A.ID_NO
                                         AND A.DATA_DATE = G.DDATE
                                       INNER JOIN  CBRC_TM_L_ACCT_UNUSED_TEMP L
                                          ON A.CUST_ID = L.CUST_ID
                                         AND L.DATA_DATE = A.DATA_DATE
                                         AND L.UNUSED_AMT <> 0
                                       LEFT JOIN CBRC_TM_L_ACCT_OBS_TEMP K
                                          ON L.ACCT_NUM = K.LOAN_NUM
                                         AND L.DATA_DATE = K.DATA_DATE
                                         AND K.FLAG='2' --表外抵押物（保证金、银行存单、国债 ）
                                        -- AND K.SECURITY_AMT<>0
                                       WHERE A.DATA_DATE = I_DATADATE
                                       GROUP BY /*L.CUST_ID,*/ L.ORG_NUM, G.ID_ROW_NO, G.ID_NAME_M
                                      UNION ALL
                                      SELECT 
                                       L.ORG_NUM,
                                       '' AS CUST_ID,
                                       G.ID_ROW_NO AS ID_NO,
                                       G.ID_NAME_M AS CUST_NAME,
                                       0 AS CO1,
                                       0 AS CO2, --表内授信（债券投资账面余额）
                                       0 AS CO3, --表外授信（不可撤销的承诺及或有负债）
                                       0 AS CO4, --表内外授信合计（保证金、银行存单、国债 ）
                                       0 AS CO5, --附注：不良贷款余额
                                       SUM(L.LOAN_ACCT_BAL) AS CO6,-- 附注：逾期贷款金额
                                       0 AS CO8 --本行非保本理财产品进行的授信
                                        FROM CBRC_TM_CBRC_G15_TEMP1 G
                                       INNER JOIN SMTMODS_L_CUST_ALL A
                                          ON G.ID_NO = A.ID_NO
                                         AND A.DATA_DATE = G.DDATE
                                       INNER JOIN CBRC_TM_L_ACCT_YQ_TEMP L
                                          ON A.CUST_ID = L.CUST_ID
                                         AND A.DATA_DATE = L.DATA_DATE
                                         AND L.LOAN_ACCT_BAL<>0
                                       WHERE A.DATA_DATE = I_DATADATE
                                       GROUP BY /*L.CUST_ID,*/ L.ORG_NUM, G.ID_ROW_NO, G.ID_NAME_M
                                      UNION ALL
                                      SELECT 
                                       L.ORG_NUM,
                                       L.CUST_ID,
                                       G.ID_NO,
                                       G.ID_NAME AS CUST_NAME,
                                       0 AS CO1,
                                       0 AS CO2, --表内授信（债券投资账面余额）
                                       0 AS CO3, --表外授信（不可撤销的承诺及或有负债）
                                       0 AS CO4, --表内外授信合计（保证金、银行存单、国债 ）
                                       0 AS CO5, --附注：不良贷款余额
                                       0 AS CO6, -- 附注：逾期贷款金额,
                                       SUM(NONFINANCIAL_AMT)  AS CO8 --本行非保本理财产品进行的授信
                                        FROM CBRC_TM_CBRC_G15_TEMP1 G
                                     
                                        INNER JOIN CBRC_TM_L_ACCT_NONFINANCIAL_TEMP L
                                          ON G.ID_NO = L.CUST_ID
                                         AND G.DDATE = L.DATA_DATE
                                       WHERE G.DDATE = I_DATADATE
                                       GROUP BY L.CUST_ID, L.ORG_NUM, G.ID_NO, G.ID_NAME) T
                               INNER JOIN CBRC_TM_L_ORG_FLAT B
                                  ON T.ORG_NUM = B.SUB_ORG_CODE
                               GROUP BY B.ORG_CODE, T.CUST_ID, T.ID_NO, T.CUST_NAME) T
                 GROUP BY T.ORG_NUM, T.ID_NO) T1) T2;
  COMMIT;

  --用证件号关联全量客户表，更新名称
MERGE INTO CBRC_G15_TEMP1 T
USING (SELECT CUST_NAM, ID_NO
         FROM (SELECT 
                CUST_NAM,
                ID_NO,
                ROW_NUMBER() OVER(PARTITION BY ID_NO ORDER BY CUST_NAM DESC) AS RN
                 FROM SMTMODS_L_CUST_ALL --存在一个证件号对应多个客户名称，排序后取一个，与信用卡规则保持一致（SP_TOPN_G15_019803）
                WHERE DATA_DATE = I_DATADATE)
        WHERE RN = 1) T2
ON (T.ID_NO = T2.ID_NO)
WHEN MATCHED THEN
  UPDATE SET T.CUST_NAME = T2.CUST_NAM;
COMMIT;

--最大十家关联集团            客户名称
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_G1_B'
               WHEN T.SEQ_NO = '2' THEN
                'G15_G2_B'
               WHEN T.SEQ_NO = '3' THEN
                'G15_G3_B'
               WHEN T.SEQ_NO = '4' THEN
                'G15_G4_B'
               WHEN T.SEQ_NO = '5' THEN
                'G15_G5_B'
               WHEN T.SEQ_NO = '6' THEN
                'G15_G6_B'
               WHEN T.SEQ_NO = '7' THEN
                'G15_G7_B'
               WHEN T.SEQ_NO = '8' THEN
                'G15_G8_B'
               WHEN T.SEQ_NO = '9' THEN
                'G15_G9_B'
               WHEN T.SEQ_NO = '10' THEN
                'G15_G10_B'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             T.CUST_NAME AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --最大十家关联集团        客户代码
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_G1_C'
               WHEN T.SEQ_NO = '2' THEN
                'G15_G2_C'
               WHEN T.SEQ_NO = '3' THEN
                'G15_G3_C'
               WHEN T.SEQ_NO = '4' THEN
                'G15_G4_C'
               WHEN T.SEQ_NO = '5' THEN
                'G15_G5_C'
               WHEN T.SEQ_NO = '6' THEN
                'G15_G6_C'
               WHEN T.SEQ_NO = '7' THEN
                'G15_G7_C'
               WHEN T.SEQ_NO = '8' THEN
                'G15_G8_C'
               WHEN T.SEQ_NO = '9' THEN
                'G15_G9_C'
               WHEN T.SEQ_NO = '10' THEN
                'G15_G10_C'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             T.ID_NO AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --最大十家关联集团        关联方类型
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_G1_D'
               WHEN T.SEQ_NO = '2' THEN
                'G15_G2_D'
               WHEN T.SEQ_NO = '3' THEN
                'G15_G3_D'
               WHEN T.SEQ_NO = '4' THEN
                'G15_G4_D'
               WHEN T.SEQ_NO = '5' THEN
                'G15_G5_D'
               WHEN T.SEQ_NO = '6' THEN
                'G15_G6_D'
               WHEN T.SEQ_NO = '7' THEN
                'G15_G7_D'
               WHEN T.SEQ_NO = '8' THEN
                'G15_G8_D'
               WHEN T.SEQ_NO = '9' THEN
                'G15_G9_D'
               WHEN T.SEQ_NO = '10' THEN
                'G15_G10_D'
             END AS ITEM_NUM,
             0 AS ITEM_VAL,
             '关联集团' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --最大十家关联集团        各项贷款
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_G1_H'
               WHEN T.SEQ_NO = '2' THEN
                'G15_G2_H'
               WHEN T.SEQ_NO = '3' THEN
                'G15_G3_H'
               WHEN T.SEQ_NO = '4' THEN
                'G15_G4_H'
               WHEN T.SEQ_NO = '5' THEN
                'G15_G5_H'
               WHEN T.SEQ_NO = '6' THEN
                'G15_G6_H'
               WHEN T.SEQ_NO = '7' THEN
                'G15_G7_H'
               WHEN T.SEQ_NO = '8' THEN
                'G15_G8_H'
               WHEN T.SEQ_NO = '9' THEN
                'G15_G9_H'
               WHEN T.SEQ_NO = '10' THEN
                'G15_G10_H'
             END AS ITEM_NUM,
             T.CO1 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

     --最大十家关联集团        债券投资
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_G1_I'
               WHEN T.SEQ_NO = '2' THEN
                'G15_G2_I'
               WHEN T.SEQ_NO = '3' THEN
                'G15_G3_I'
               WHEN T.SEQ_NO = '4' THEN
                'G15_G4_I'
               WHEN T.SEQ_NO = '5' THEN
                'G15_G5_I'
               WHEN T.SEQ_NO = '6' THEN
                'G15_G6_I'
               WHEN T.SEQ_NO = '7' THEN
                'G15_G7_I'
               WHEN T.SEQ_NO = '8' THEN
                'G15_G8_I'
               WHEN T.SEQ_NO = '9' THEN
                'G15_G9_I'
               WHEN T.SEQ_NO = '10' THEN
                'G15_G10_I'
             END AS ITEM_NUM,
             T.CO2 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       WHERE T.SEQ_NO <= 10;

    COMMIT;

    --最大十家关联集团        不可撤销的承诺及或有负债
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_G1_L'
               WHEN T.SEQ_NO = '2' THEN
                'G15_G2_L'
               WHEN T.SEQ_NO = '3' THEN
                'G15_G3_L'
               WHEN T.SEQ_NO = '4' THEN
                'G15_G4_L'
               WHEN T.SEQ_NO = '5' THEN
                'G15_G5_L'
               WHEN T.SEQ_NO = '6' THEN
                'G15_G6_L'
               WHEN T.SEQ_NO = '7' THEN
                'G15_G7_L'
               WHEN T.SEQ_NO = '8' THEN
                'G15_G8_L'
               WHEN T.SEQ_NO = '9' THEN
                'G15_G9_L'
               WHEN T.SEQ_NO = '10' THEN
                'G15_G10_L'
             END AS ITEM_NUM,
             T.CO3 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       WHERE T.SEQ_NO <= 10;
    COMMIT;


--最大十家自然人或法人关联方  本行非保本理财产品进行的授信 ADD BY DJH 20230425

 INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_G1_M'
               WHEN T.SEQ_NO = '2' THEN
                'G15_G2_M'
               WHEN T.SEQ_NO = '3' THEN
                'G15_G3_M'
               WHEN T.SEQ_NO = '4' THEN
                'G15_G4_M'
               WHEN T.SEQ_NO = '5' THEN
                'G15_G5_M'
               WHEN T.SEQ_NO = '6' THEN
                'G15_G6_M'
               WHEN T.SEQ_NO = '7' THEN
                'G15_G7_M'
               WHEN T.SEQ_NO = '8' THEN
                'G15_G8_M'
               WHEN T.SEQ_NO = '9' THEN
                'G15_G9_M'
               WHEN T.SEQ_NO = '10' THEN
                'G15_G10_M'
             END AS ITEM_NUM,
             T.CO8 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    --最大十家关联集团        保证金、银行存单、国债
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位 出现在
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_G1_P'
               WHEN T.SEQ_NO = '2' THEN
                'G15_G2_P'
               WHEN T.SEQ_NO = '3' THEN
                'G15_G3_P'
               WHEN T.SEQ_NO = '4' THEN
                'G15_G4_P'
               WHEN T.SEQ_NO = '5' THEN
                'G15_G5_P'
               WHEN T.SEQ_NO = '6' THEN
                'G15_G6_P'
               WHEN T.SEQ_NO = '7' THEN
                'G15_G7_P'
               WHEN T.SEQ_NO = '8' THEN
                'G15_G8_P'
               WHEN T.SEQ_NO = '9' THEN
                'G15_G9_P'
               WHEN T.SEQ_NO = '10' THEN
                'G15_G10_P'
             END AS ITEM_NUM,
             T.CO4 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

     --最大十家关联集团        附注：不良贷款余额
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位 出现在
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_G1_R'
               WHEN T.SEQ_NO = '2' THEN
                'G15_G2_R'
               WHEN T.SEQ_NO = '3' THEN
                'G15_G3_R'
               WHEN T.SEQ_NO = '4' THEN
                'G15_G4_R'
               WHEN T.SEQ_NO = '5' THEN
                'G15_G5_R'
               WHEN T.SEQ_NO = '6' THEN
                'G15_G6_R'
               WHEN T.SEQ_NO = '7' THEN
                'G15_G7_R'
               WHEN T.SEQ_NO = '8' THEN
                'G15_G8_R'
               WHEN T.SEQ_NO = '9' THEN
                'G15_G9_R'
               WHEN T.SEQ_NO = '10' THEN
                'G15_G10_R'
             END AS ITEM_NUM,
             T.CO5 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       WHERE T.SEQ_NO <= 10;

    COMMIT;

     --最大十家关联集团        附注：逾期贷款金额
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位 出现在
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_G1_S'
               WHEN T.SEQ_NO = '2' THEN
                'G15_G2_S'
               WHEN T.SEQ_NO = '3' THEN
                'G15_G3_S'
               WHEN T.SEQ_NO = '4' THEN
                'G15_G4_S'
               WHEN T.SEQ_NO = '5' THEN
                'G15_G5_S'
               WHEN T.SEQ_NO = '6' THEN
                'G15_G6_S'
               WHEN T.SEQ_NO = '7' THEN
                'G15_G7_S'
               WHEN T.SEQ_NO = '8' THEN
                'G15_G8_S'
               WHEN T.SEQ_NO = '9' THEN
                'G15_G9_S'
               WHEN T.SEQ_NO = '10' THEN
                'G15_G10_S'
             END AS ITEM_NUM,
             T.CO6 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       WHERE T.SEQ_NO <= 10;


    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '获取最大十家关联集团完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);



    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '获取最大十家关联集团报告期内最高风险额（净额）';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    --报告期内最高风险额（净额）以本季度为基准，上季度与本季度比哪个大取哪一个
    --本季度
      INSERT INTO CBRC_TM_A_REPT_ITEM_VAL_T
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG, --标志位
       ID_NO
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             CASE
               WHEN T.SEQ_NO = '1' THEN
                'G15_G1_F'
               WHEN T.SEQ_NO = '2' THEN
                'G15_G2_F'
               WHEN T.SEQ_NO = '3' THEN
                'G15_G3_F'
               WHEN T.SEQ_NO = '4' THEN
                'G15_G4_F'
               WHEN T.SEQ_NO = '5' THEN
                'G15_G5_F'
               WHEN T.SEQ_NO = '6' THEN
                'G15_G6_F'
               WHEN T.SEQ_NO = '7' THEN
                'G15_G7_F'
               WHEN T.SEQ_NO = '8' THEN
                'G15_G8_F'
               WHEN T.SEQ_NO = '9' THEN
                'G15_G9_F'
               WHEN T.SEQ_NO = '10' THEN
                'G15_G10_F'
             END AS ITEM_NUM,
             T.CO7 AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG,
             ID_NO
        FROM CBRC_G15_TEMP1 T
       WHERE T.SEQ_NO <= 10;
    COMMIT;

    V_STEP_FLAG := 1;
    V_STEP_DESC := '获取最大十家关联集团报告期内最高风险额（净额）完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '获取最大十家关联集团关联上季度与本季度差值比较';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

  INSERT INTO CBRC_A_REPT_ITEM_VAL
    (DATA_DATE, --数据日期
     ORG_NUM, --机构号
     SYS_NAM, --模块简称
     REP_NUM, --报表编号
     ITEM_NUM, --指标号
     ITEM_VAL, --指标值（数值型）
     ITEM_VAL_V, --指标值（字符型）
     FLAG --标志位
     )
 WITH TEMP_G15_BQ_T AS
  (SELECT ORG_NUM,
          ITEM_NUM,
          ITEM_VAL,
          ITEM_VAL_V AS ID_NAME, --此行取名字
          ID_NO --另外一列取取身份证
     FROM CBRC_TM_A_REPT_ITEM_VAL_T A
    WHERE A.DATA_DATE = I_DATADATE),

---WORK取数,上季度
TEMP_G15_SQ_T AS
 (SELECT ROW_NUM,
         ORG_NUM,
         MAX(ID_NAME) ID_NAME,
         MAX(ID_NO) AS ID_NO,
         MAX(ITEM_NUM) AS ITEM_NUM,
         MAX(PV) AS PV
    FROM (SELECT CASE
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '19' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '20' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '21' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '22' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '23' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '24' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '25' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '26' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '27' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '3' AND A.ROW_NUM = '28' THEN
                    A.PV_STR
                 END AS ID_NAME,
                 CASE
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '19' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '20' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '21' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '22' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '23' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '24' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '25' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '26' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '27' THEN
                    A.PV_STR
                   WHEN A.COL_NUM = '4' AND A.ROW_NUM = '28' THEN
                    A.PV_STR
                 END AS ID_NO,
                 CASE
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '19' THEN
                    'G15_G1_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '20' THEN
                    'G15_G2_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '21' THEN
                    'G15_G3_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '22' THEN
                    'G15_G4_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '23' THEN
                    'G15_G5_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '24' THEN
                    'G15_G6_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '25' THEN
                    'G15_G7_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '26' THEN
                    'G15_G8_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '27' THEN
                    'G15_G9_F'
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '28' THEN
                    'G15_G10_F'
                 END AS ITEM_NUM,
                 CASE
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '19' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '20' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '21' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '22' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '23' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '24' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '25' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '26' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '27' THEN
                    A.PV
                   WHEN A.COL_NUM = '16' AND A.ROW_NUM = '28' THEN
                    A.PV
                 END AS PV,
                 A.ROW_NUM AS ROW_NUM,
                 A.DBANK_ID AS ORG_NUM
            FROM CBRC_G15 A   --DATAX 落地表
           WHERE REPLACE(A.DDATE,'-','') =TO_CHAR(LAST_DAY(ADD_MONTHS(DATE(I_DATADATE), -3)),'YYYYMMDD')  --上季度末
             AND A.COL_NUM IN ('3', '4', '16')
           --  AND DBANK_ID = '100000'
             AND ROW_NUM BETWEEN 19 AND 28)
   GROUP BY ROW_NUM,ORG_NUM
   ORDER BY ROW_NUM)

SELECT I_DATADATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G15' AS REP_NUM,
       A.ITEM_NUM AS ITEM_NUM,
       CASE
         WHEN NVL(A.ITEM_VAL, 0) > NVL(B.PV, 0) THEN
          NVL(A.ITEM_VAL, 0)
         ELSE
          NVL(B.PV, 0)
       END AS ITEM_VAL,
       '' AS ITEM_VAL_V,
       '1' AS FLAG /*,
       A.ID_NO,
       A.ID_NAME,
       NVL(A.ITEM_VAL, 0),
       NVL(B.PV, 0) */
  FROM TEMP_G15_BQ_T A
  LEFT JOIN TEMP_G15_SQ_T B
    ON A.ORG_NUM = B.ORG_NUM
   AND A.ID_NO = B.ID_NO/*
   where A.ORG_NUM='100000'*/;

COMMIT;
  

    V_STEP_FLAG := 1;
    V_STEP_DESC := '获取最大十家关联集团关联上季度与本季度差值比较完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

-------------------------------------------------------------------------------------------

    V_STEP_ID   := V_STEP_ID + 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '获取全部关联方开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
--全部关联方与最大十家关联集团范围一样，它是一个总值

    --全部关联方   表内外授信净额
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位 出现在
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             'G15_II.1.A' AS ITEM_NUM,
             SUM(CO7) AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       GROUP BY T.ORG_NUM;
    COMMIT;

    --全部关联方   保证金、银行存单、国债
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位 出现在
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             'G15_II.1.C'  AS ITEM_NUM,
             SUM(CO4) AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       GROUP BY T.ORG_NUM;
    COMMIT;

    --全部关联方   附注：不良贷款余额

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位 出现在
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             'G15_II.1.E'  AS ITEM_NUM,
             SUM(CO5) AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       GROUP BY T.ORG_NUM;

    COMMIT;

    --全部关联方   附注：逾期贷款金额


    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       ITEM_VAL_V, --指标值（字符型）
       FLAG --标志位 出现在
       )
      SELECT I_DATADATE,
             T.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G15' AS REP_NUM,
             'G15_II.1.F' AS ITEM_NUM,
             SUM(CO6) AS ITEM_VAL,
             '' AS ITEM_VAL_V,
             '1' AS FLAG
        FROM CBRC_G15_TEMP1 T
       GROUP BY T.ORG_NUM;


    COMMIT;


    V_STEP_FLAG := 1;
    V_STEP_DESC := '获取全部关联方完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

      UPDATE CBRC_A_REPT_ITEM_VAL
       SET IS_TOTAL = 'N'
      WHERE DATA_DATE = I_DATADATE
       AND REP_NUM = 'G15';

      COMMIT;
   -------------------------------------------------------------------------------------------
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
   
END proc_cbrc_idx2_g15