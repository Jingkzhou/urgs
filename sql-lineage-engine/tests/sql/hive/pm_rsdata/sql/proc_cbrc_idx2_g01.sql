CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g01(II_DATADATE  IN STRING --跑批日期
                                                 )
/****************************** 
  @author:RS
  @create-date:2016-11-06
  @description:G01
  @modification history: G01归并取科目
  m0.20161021-rs-G01
   m1.20240805  zy 完善金融市场部的相关指标
     M2.20241224 SHIY 26项27项剔除保证金科目
  --需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-27，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
  --需求编号：JLBA202504300003_关于1104报送系统实现G24、G01、G18表自动化取数的需求 上线日期：20250729 修改人：石雨 提出人：陈聪，修改内容：4. 存放同业款项、10. 拆放同业、30. 同业拆入、45. 转贷款资金、63. 生息资产、12.3其他投资及其子项
  需求编号：JLBA202505280011 上线日期：2025-09-19，修改人：狄家卉，提出人：赵翰君  修改原因：关于实现1104监管报送报表自动化采集加工的需求 增加009801清算中心(国际业务部)外币折人民币业务
  --[JLBA202507210012_关于调整财政性存款及一般性存款相关科目统计方式的相关需求][提出人：于佳禾][上线时间：20250918][修改人：石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款 , 2008国库集中收缴款项\2009国库集中支付款项 调整为单位存款 ]

目标表：CBRC_A_REPT_ITEM_VAL 
临时表：CBRC_A_REPT_ITEM_VAL_G01 --
视图表：SMTMODS_V_PUB_IDX_FINA_GL        --总账科目表
     SMTMODS_V_PUB_IDX_CK_GTGSHDQ     --个体工商户定期存款
     SMTMODS_V_PUB_IDX_CK_GTGSHHQ     --个体工商户活期存款
     SMTMODS_V_PUB_IDX_CK_GTGSHTZ     --个体工商户通知存款
集市表：SMTMODS_L_FINA_GL        --总账科目表
     SMTMODS_L_ACCT_DEPOSIT           --存款账户信息表
     SMTMODS_L_CUST_C                 --对公客户补充信息表
     SMTMODS_L_PUBL_RATE              --汇率表
     SMTMODS_L_ACCT_FUND_REPURCHASE   --回购信息表
     SMTMODS_L_CUST_EXTERNAL_INFO     --客户外部信息表
     SMTMODS_L_ACCT_FUND_INVEST       --投资业务信息表
     SMTMODS_L_AGRE_BOND_INFO B       --债券信息表
     SMTMODS_L_CUST_BILL_TY           --同业客户补充信息表
     SMTMODS_L_ACCT_FUND_MMFUND       --资金往来信息表
     
  *******************************/
 IS
  V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  INTEGER; --数据日期(数值型)YYYYMMDD
  V_STEP_ID   INT; --任务号
  V_STEP_DESC VARCHAR(300); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    STRING; --系统名
   O_STATUS STRING;
   O_STATUS_DEC STRING;


BEGIN
  IF II_STATUS = 0 THEN
    V_STEP_ID   := 0;
    V_STEP_DESC := '参数初始化处理';
     sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE,V_STEP_ID,V_ERRORCODE,V_STEP_DESC,II_DATADATE);

    I_DATADATE := II_DATADATE;

    V_SYSTEM  := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G01');
    V_TAB_NAME  := 'G01';

    V_STEP_ID   := 1;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
    sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE,V_STEP_ID, V_ERRORCODE,V_STEP_DESC,II_DATADATE);
    ------------------------------------------------------------------------------------------------------

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND ITEM_NUM IN ('G01_26..A',
                        'G01_26..B',
                        'G01_27..A',
                        'G01_27..B',
                        'G01_30.1.A.2016',
                        'G01_30.1.B.2016',
                        'G01_30.6.A.2016',
                        'G01_30.6.B.2016',
                        'G01_13.1.A.2016',
                        'G01_13.2.A.2016',
                        'G01_13.3.A.2016',
                        'G01_13.4.A.2016',
                        'G01_13.5.A.2016',
                        'G01_13.8.A.2016',
                        'G01_13.1.B.2016',
                        'G01_13.2.B.2016',
                        'G01_13.3.B.2016',
                        'G01_13.4.B.2016',
                        'G01_13.5.B.2016',
                        'G01_13.8.B.2016',
                        'G01_13.1.C.2016',
                        'G01_13.2.C.2016',
                        'G01_13.3.C.2016',
                        'G01_13.4.C.2016',
                        'G01_13.5.C.2016',
                        'G01_13.8.C.2016',
                        'G01_31.1.A.2016',
                        'G01_31.2.A.2016',
                        'G01_31.3.A.2016',
                        'G01_31.4.A.2016',
                        'G01_31.5.A.2016',
                        'G01_31.8.A.2016',
                        'G01_31.1.B.2016',
                        'G01_31.2.B.2016',
                        'G01_31.3.B.2016',
                        'G01_31.4.B.2016',
                        'G01_31.5.B.2016',
                        'G01_31.8.B.2016',
                        'G01_31.1.C.2016',
                        'G01_31.2.C.2016',
                        'G01_31.3.C.2016',
                        'G01_31.4.C.2016',
                        'G01_31.5.C.2016',
                        'G01_31.8.C.2016',
                        'G01_12.1a.C.2021',
                        'G01_12.1b.C.2021',
                        'G01_12.1c.C.2021',
                        'G01_12.1d.C.2021',
                        'G01_12.1e.C.2021',
                        'G01_12.1.A', -- add by  zy  start
                        'G01_12.1.B',
                        --  'G01_12.3.A', -- modify by djh 20250319
                        --  'G01_12.3.B',
                        'G01_30.4.A.2016',
                        'G01_30.5.A.2016',
                        'G01_30.2.A.2016',
                        'G01_30.1.A.2016',
                        'G01_30.3.A.2016',
                        'G01_30.4.B.2016',
                        'G01_30.5.B.2016',
                        'G01_30.2.B.2016',
                        'G01_30.1.B.2016',
                        'G01_30.3.B.2016',
                        'G01_63.A.2024',
                        'G01_63.B.2024',
                        'G01_64.A.2024',
                        'G01_64.B.2024') -- zdd  by  zy   end   )
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = 'G01';
    --AND FLAG = '1';   lrt 20170927
    COMMIT;

    -- modify by djh 20250319 由于此表 12.3其他，G01_12.3有从PROC_L_FINA_GL出数，删除非投行数据
    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND ITEM_NUM IN ('G01_12.3.A', 'G01_12.3.B')
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = 'G01'
       AND ORG_NUM <> '009817';

    --清除临时表数据
    --alter by shiyu 20230608 新建临时表处理个体工商户存款机构转换问题，优化程序
    EXECUTE IMMEDIATE 'TRUNCATE TABLE CBRC_A_REPT_ITEM_VAL_G01';
   
    V_STEP_ID   := V_STEP_ID +1;
    V_STEP_DESC := 'G01_26..A 逻辑处理开始';
    sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE,V_STEP_ID, V_ERRORCODE,V_STEP_DESC,II_DATADATE);
  
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_26..A' AS ITEM_NUM,
       SUM(CREDIT_BAL) AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         AND ITEM_CD IN ('20110201',
                         '20110205',
                         '20110202',
                         '20110203',
                         '20110204',
                         '20110211', -- 转股协议存款 原逻辑没有
                         '20110701',
                         '20110206',
                         '20110207',
                         '20110208',
                         '20120106',
                         '20120204',
                         '20100101' -- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
                        ,
                         '20110301',
                         '20110302',
                         '20110303' --[JLBA202507210012][石雨][20250918][修改内容：201103（财政性存款 ）调整为 一般单位活期存款]
                        ,
                         '22410101' --单位久悬未取款--[JLBA202507210012][石雨][20250918][修改内容：224101久悬未取款属于活期存款]
                        ,
                         '20080101',
                         '20090101' --[JLBA202507210012][石雨][20250918][修改内容：2008 2009调整为单位存款]
                         )

       GROUP BY ORG_NUM;
    COMMIT;
  
   INSERT INTO CBRC_A_REPT_ITEM_VAL_G01 -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_26..A' AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         and gl_item_code <> '20110210' --剔除单位定期保证金存款
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01 -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_26..A' AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         AND GL_ITEM_CODE <> '20110209'
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01 -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_26..A' AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
       GROUP BY ORG_NUM;
    COMMIT;

    --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]剔除个体工商户部分

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_26..A' AS ITEM_NUM,
       SUM(T.ACCT_BALANCE * B.CCY_RATE) * -1 AS ITEM_VAL,
       '2' AS FLAG
        from SMTMODS_L_ACCT_DEPOSIT T
       INNER JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
       INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY' --折人民币
       where c.deposit_custtype in ('13', '14')
         and t.gl_item_code IN
             ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
         AND T.ACCT_BALANCE > 0
         AND T.DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
       GROUP BY T.ORG_NUM;
    COMMIT;

   V_STEP_ID   := V_STEP_ID +1;
   V_STEP_DESC := 'G01_26..B 逻辑处理开始';
   sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);

   INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_26..B' AS ITEM_NUM,
       SUM(ITEM_VAL) AS ITEM_VAL,
       '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     'G01' AS REP_NUM,
                     'G01_26..B' AS ITEM_NUM,
                     SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL A
               INNER JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.CURR_CD <> 'CNY'
                 AND A.ITEM_CD IN ('20110201',
                                   '20110205',
                                   '20110202',
                                   '20110203',
                                   '20110204',
                                   '20110211', -- 转股协议存款 原逻辑没有
                                   '20110701',
                                   '20110206',
                                   '20110207',
                                   '20110208',
                                   '20120106',
                                   '20120204',
                                   '20100101' -- 需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13，修改人：巴启威，提出人：王曦若 ，修改内容：调整代理国库业务会计科目
                                  ,
                                   '20110301',
                                   '20110302',
                                   '20110303' --[JLBA202507210012][石雨][修改内容：201103（财政性存款 ）调整为 一般单位活期存款]
                                  ,
                                   '22410101' --单位久悬未取款--[JLBA202507210012][石雨][修改内容：224101久悬未取款属于活期存款]
                                  ,
                                   '20080101',
                                   '20090101' --[JLBA202507210012][石雨][20250918][修改内容：2008 2009调整为单位存款]
                                   )
              /*('201', '202', '205', '206', '218', '21901', '22001','234010204','2340204')*/ --老核心科目
               GROUP BY A.ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;
    COMMIT;

   INSERT INTO CBRC_A_REPT_ITEM_VAL_G01 -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_26..B' AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD <> 'CNY'
         and gl_item_code <> '20110210' --剔除单位定期保证金存款
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01 -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_26..B' AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD <> 'CNY'
         AND GL_ITEM_CODE <> '20110209'
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01 -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_26..B' AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) * -1 AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD <> 'CNY'
       GROUP BY ORG_NUM;
    COMMIT;

    --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]剔除个体工商户部分

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_26..B' AS ITEM_NUM,
       SUM(T.ACCT_BALANCE * B.CCY_RATE) * -1 AS ITEM_VAL,
       '2' AS FLAG
        from SMTMODS_L_ACCT_DEPOSIT T
       INNER JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
       INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY' --折人民币
       where c.deposit_custtype in ('13', '14')
         and t.gl_item_code IN
             ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
         AND T.ACCT_BALANCE > 0
         AND T.DATA_DATE = I_DATADATE
         AND CURR_CD <> 'CNY'
       GROUP BY T.ORG_NUM;
    COMMIT;

    V_STEP_ID   := V_STEP_ID +1;
    V_STEP_DESC := 'G01_27..A 逻辑处理开始';
    sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_27..A' AS ITEM_NUM,
       SUM(ITEM_VAL) AS ITEM_VAL,
       '2' AS FLAG
        FROM (SELECT
               I_DATADATE AS DATA_DATE,
               ORG_NUM AS ORG_NUM,
               'CBRC' AS SYS_NAM,
               'G01' AS REP_NUM,
               'G01_27..A' AS ITEM_NUM,
               SUM(CREDIT_BAL) AS ITEM_VAL,
               '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL
               WHERE DATA_DATE = I_DATADATE
                 AND CURR_CD = 'CNY'
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
                                 '20110113',
                                 '22410102' --个人久悬未取款--[JLBA202507210012][石雨][修改内容：224101久悬未取款属于活期存款]

                                 )
               GROUP BY ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01 -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_27..A' AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         and gl_item_code <> '20110210' --剔除单位定期保证金存款
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01 -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)

      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_27..A' AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
         AND gl_item_code <> '20110209' --剔除单位活期保证金存款
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01 -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_27..A' AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
       GROUP BY ORG_NUM;
    COMMIT;

    --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]剔除个体工商户部分

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_27..A' AS ITEM_NUM,
       SUM(T.ACCT_BALANCE * B.CCY_RATE) AS ITEM_VAL,
       '2' AS FLAG
        from SMTMODS_L_ACCT_DEPOSIT T
       INNER JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
       INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY' --折人民币
       where c.deposit_custtype in ('13', '14')
         and t.gl_item_code IN
             ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
         AND T.ACCT_BALANCE > 0
         AND T.DATA_DATE = I_DATADATE
         AND CURR_CD = 'CNY'
       GROUP BY T.ORG_NUM;
    COMMIT;

   V_STEP_ID   := V_STEP_ID+1;
   V_STEP_DESC := 'G01_27..B 逻辑处理开始';
   sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);

   INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)

      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_27..B' AS ITEM_NUM,
       SUM(ITEM_VAL) AS ITEM_VAL,
       '2' AS FLAG
        FROM (SELECT I_DATADATE AS DATA_DATE,
                     ORG_NUM AS ORG_NUM,
                     'CBRC' AS SYS_NAM,
                     'G01' AS REP_NUM,
                     'G01_27..B' AS ITEM_NUM,
                     SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL A
               INNER JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.CURR_CD <> 'CNY'
                 AND A.ITEM_CD IN ('20110110',
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
                                   '20110113',
                                   '22410102' --个人久悬未取款--[JLBA202507210012][石雨][修改内容：224101久悬未取款属于活期存款]

                                   )
         
               GROUP BY A.ORG_NUM) TEMP
       GROUP BY TEMP.ORG_NUM;
    COMMIT;

   

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01 -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_27..B' AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ --个体工商户定期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD <> 'CNY'
         and gl_item_code <> '20110210' --剔除单位定期保证金存款
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01 -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_27..B' AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ --个体工商户活期存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD <> 'CNY'
         AND gl_item_code <> '20110209' --剔除单位活期保证金存款
       GROUP BY ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01 -- 修改从视图过滤个体工商户部分 lfz 20220614
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_27..B' AS ITEM_NUM,
       SUM(ACCT_BALANCE_RMB) AS ITEM_VAL,
       '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ --个体工商户通知存款
       WHERE DATA_DATE = I_DATADATE
         AND CURR_CD <> 'CNY'
       GROUP BY ORG_NUM;
    COMMIT;

    --[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款 ）调整为 一般单位活期存款]剔除个体工商户部分

    INSERT INTO CBRC_A_REPT_ITEM_VAL_G01
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       T.ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_27..B' AS ITEM_NUM,
       SUM(T.ACCT_BALANCE * B.CCY_RATE) AS ITEM_VAL,
       '2' AS FLAG
        from SMTMODS_L_ACCT_DEPOSIT T
       INNER JOIN SMTMODS_L_CUST_C C
          ON T.DATA_DATE = C.DATA_DATE
         AND T.CUST_ID = C.CUST_ID
       INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY' --折人民币
       where c.deposit_custtype in ('13', '14')
         and t.gl_item_code IN
             ('20110301', '20110302', '20110303', '22410101') --201104 一般单位活期  22410101单位久悬未取款
         AND T.ACCT_BALANCE > 0
         AND T.DATA_DATE = I_DATADATE
         AND CURR_CD <> 'CNY'
       GROUP BY T.ORG_NUM;
    COMMIT;
   
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             CASE
               WHEN ORG_NUM LIKE '5%' OR ORG_NUM LIKE '6%' THEN
                ORG_NUM
               WHEN ORG_NUM LIKE '060101%' THEN
                '060300'
               WHEN ORG_NUM NOT LIKE '__98%' THEN
                SUBSTR(ORG_NUM, 1, 4) || '00'
               ELSE
                ORG_NUM
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             ITEM_NUM,
             SUM(ITEM_VAL),
             '2' AS FLAG
        FROM CBRC_A_REPT_ITEM_VAL_G01
       GROUP BY ITEM_NUM,
                CASE
                  WHEN ORG_NUM LIKE '5%' OR ORG_NUM LIKE '6%' THEN
                   ORG_NUM
                  WHEN ORG_NUM LIKE '060101%' THEN
                   '060300'
                  WHEN ORG_NUM NOT LIKE '__98%' THEN
                   SUBSTR(ORG_NUM, 1, 4) || '00'
                  ELSE
                   ORG_NUM
                END;

    COMMIT; 

   V_STEP_ID   := V_STEP_ID +1;
   V_STEP_DESC := 'G01_30.1.A.2016-G01_30.6.B.2016 逻辑处理开始';
   sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       '009801' AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       CASE
         WHEN ITEM_CD IN ('20030101', '20030103') AND A.CURR_CD = 'CNY' THEN
          'G01_30.1.A.2016'
         WHEN ITEM_CD IN ('20030101', '20030103') AND A.CURR_CD <> 'CNY' THEN
          'G01_30.1.B.2016'
         WHEN ITEM_CD = '20030201' AND A.CURR_CD = 'CNY' THEN
          'G01_30.6.A.2016'
         WHEN ITEM_CD = '20030201' AND A.CURR_CD <> 'CNY' THEN
          'G01_30.6.B.2016'
       END AS ITEM_NUM,
       SUM(A.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL,
       '2' AS FLAG
      --FROM SMTMODS_L_FINA_GL
        FROM SMTMODS_V_PUB_IDX_FINA_GL A
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('20030101', '20030103', '20030201')
         AND A.ORG_NUM = '009801'
       GROUP BY CASE
                  WHEN ITEM_CD IN ('20030101', '20030103') AND
                       A.CURR_CD = 'CNY' THEN
                   'G01_30.1.A.2016'
                  WHEN ITEM_CD IN ('20030101', '20030103') AND
                       A.CURR_CD <> 'CNY' THEN
                   'G01_30.1.B.2016'
                  WHEN ITEM_CD = '20030201' AND A.CURR_CD = 'CNY' THEN
                   'G01_30.6.A.2016'
                  WHEN ITEM_CD = '20030201' AND A.CURR_CD <> 'CNY' THEN
                   'G01_30.6.B.2016'
                END;
    COMMIT;

    V_STEP_ID   := V_STEP_ID+1;
    V_STEP_DESC := '买入返售人民币/外币折人民币/本外币合计 逻辑处理开始';
    sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);
    
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             CASE
               WHEN A.JYDSMC LIKE '%农村信用%' THEN
                'G01_13.2.A.2016' ---农村信用社分类：13.2境内其他银行业金融机构
               WHEN A.IS_PRODUCT = 'Y' THEN
                'G01_13.5.A.2016' ---产品户分类：13.5境内其他金融机构
               WHEN ORG_TYPE_SCLS IN ('F01',
                                      'F02',
                                      'F03',
                                      'F04',
                                      'F05',
                                      'F06',
                                      'F07',
                                      'F08',
                                      'F09',
                                      'F10') THEN
                'G01_13.4.A.2016' --境内保险业金融机构
               WHEN ORG_TYPE_SCLS IN ('H01',
                                      'H02',
                                      'I',
                                      'I01',
                                      'I02',
                                      'I03',
                                      'I04',
                                      'I05',
                                      'I06',
                                      'I07',
                                      'I08',
                                      'I09') THEN
                'G01_13.5.A.2016' --境内其他金融机构
               WHEN ORG_TYPE_SCLS IN ('C01',
                                      'C0101',
                                      'C0102',
                                      'C0103',
                                      'C06',
                                      'C07',
                                      'C08',
                                      'C09',
                                      'C10',
                                      'C11',
                                      'D01',
                                      'D0201',
                                      'D0202',
                                      'D03',
                                      'D04',
                                      'D05',
                                      'D06',
                                      'D07') THEN
                'G01_13.2.A.2016' -- 境内其他银行业金融机构
               WHEN ORG_TYPE_SCLS IN ('C02',
                                      'C03',
                                      'C04',
                                      'C05',
                                      'C12',
                                      'C1201',
                                      'C1202',
                                      'C13',
                                      'C14') THEN
                'G01_13.1.A.2016' --境内商业银行
               WHEN ORG_TYPE_SCLS IN ('E01',
                                      'E02',
                                      'E03',
                                      'E04',
                                      'E05',
                                      'E06',
                                      'E07',
                                      'E08',
                                      'E09') THEN
                'G01_13.3.A.2016' --- 境内证券业金融机构
               WHEN ORG_TYPE_SCLS IN ('A01', 'A02') THEN
                'G01_13.8.A.2016' --中央银行
             END AS FINA_TYP,
             SUM(A.BALANCE * U.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_REPURCHASE A ---回购信息表
        LEFT JOIN SMTMODS_L_CUST_EXTERNAL_INFO FR ---客户外部信息表
          ON A.DATA_DATE = FR.DATA_DATE
         AND A.CUST_ID = FR.CUST_ID
         AND FR.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
       WHERE A.GL_ITEM_CODE IN ('111101') --债券买入返售??111101?
         AND A.DATA_DATE = I_DATADATE
         AND A.CURR_CD = 'CNY'
         AND A.BALANCE > 0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.JYDSMC LIKE '%农村信用%' THEN
                   'G01_13.2.A.2016' ---农村信用社分类：13.2境内其他银行业金融机构
                  WHEN A.IS_PRODUCT = 'Y' THEN
                   'G01_13.5.A.2016' ---产品户分类：13.5境内其他金融机构
                  WHEN ORG_TYPE_SCLS IN ('F01',
                                         'F02',
                                         'F03',
                                         'F04',
                                         'F05',
                                         'F06',
                                         'F07',
                                         'F08',
                                         'F09',
                                         'F10') THEN
                   'G01_13.4.A.2016' --境内保险业金融机构
                  WHEN ORG_TYPE_SCLS IN ('H01',
                                         'H02',
                                         'I',
                                         'I01',
                                         'I02',
                                         'I03',
                                         'I04',
                                         'I05',
                                         'I06',
                                         'I07',
                                         'I08',
                                         'I09') THEN
                   'G01_13.5.A.2016' --境内其他金融机构
                  WHEN ORG_TYPE_SCLS IN ('C01',
                                         'C0101',
                                         'C0102',
                                         'C0103',
                                         'C06',
                                         'C07',
                                         'C08',
                                         'C09',
                                         'C10',
                                         'C11',
                                         'D01',
                                         'D0201',
                                         'D0202',
                                         'D03',
                                         'D04',
                                         'D05',
                                         'D06',
                                         'D07') THEN
                   'G01_13.2.A.2016' -- 境内其他银行业金融机构
                  WHEN ORG_TYPE_SCLS IN ('C02',
                                         'C03',
                                         'C04',
                                         'C05',
                                         'C12',
                                         'C1201',
                                         'C1202',
                                         'C13',
                                         'C14') THEN
                   'G01_13.1.A.2016' --境内商业银行
                  WHEN ORG_TYPE_SCLS IN ('E01',
                                         'E02',
                                         'E03',
                                         'E04',
                                         'E05',
                                         'E06',
                                         'E07',
                                         'E08',
                                         'E09') THEN
                   'G01_13.3.A.2016' --- 境内证券业金融机构
                  WHEN ORG_TYPE_SCLS IN ('A01', 'A02') THEN
                   'G01_13.8.A.2016' --中央银行
                END;

    COMMIT;

    ---外币折人民币
    -- [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1111买入返售本金
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             CASE
               WHEN A.JYDSMC LIKE '%农村信用%' THEN
                'G01_13.2.B.2016'
               WHEN A.IS_PRODUCT = 'Y' THEN
                'G01_13.5.B.2016' ---产品户分类：13.5境内其他金融机构
               WHEN ORG_TYPE_SCLS IN ('F01',
                                      'F02',
                                      'F03',
                                      'F04',
                                      'F05',
                                      'F06',
                                      'F07',
                                      'F08',
                                      'F09',
                                      'F10') THEN
                'G01_13.4.B.2016' --境内保险业金融机构
               WHEN ORG_TYPE_SCLS IN ('H01',
                                      'H02',
                                      'I',
                                      'I01',
                                      'I02',
                                      'I03',
                                      'I04',
                                      'I05',
                                      'I06',
                                      'I07',
                                      'I08',
                                      'I09') THEN
                'G01_13.5.B.2016' --境内其他金融机构
               WHEN ORG_TYPE_SCLS IN ('C01',
                                      'C0101',
                                      'C0102',
                                      'C0103',
                                      'C06',
                                      'C07',
                                      'C08',
                                      'C09',
                                      'C10',
                                      'C11',
                                      'D01',
                                      'D0201',
                                      'D0202',
                                      'D03',
                                      'D04',
                                      'D05',
                                      'D06',
                                      'D07') THEN
                'G01_13.2.B.2016' -- 境内其他银行业金融机构
               WHEN ORG_TYPE_SCLS IN ('C02',
                                      'C03',
                                      'C04',
                                      'C05',
                                      'C12',
                                      'C1201',
                                      'C1202',
                                      'C13',
                                      'C14') THEN
                'G01_13.1.B.2016' --境内商业银行
               WHEN ORG_TYPE_SCLS IN ('E01',
                                      'E02',
                                      'E03',
                                      'E04',
                                      'E05',
                                      'E06',
                                      'E07',
                                      'E08',
                                      'E09') THEN
                'G01_13.3.B.2016' --- 境内证券业金融机构
               WHEN ORG_TYPE_SCLS IN ('A01', 'A02') THEN
                'G01_13.8.B.2016' --中央银行
             END AS FINA_TYP,
             SUM(A.BALANCE * U.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_REPURCHASE A ---回购信息表
        LEFT JOIN SMTMODS_L_CUST_EXTERNAL_INFO FR ---客户外部信息表
          ON A.DATA_DATE = FR.DATA_DATE
         AND A.CUST_ID = FR.CUST_ID
         AND FR.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
       WHERE SUBSTR(A.GL_ITEM_CODE, 1, 6) IN ('111101') --债券买入返售111101
         AND A.DATA_DATE = I_DATADATE
         AND A.CURR_CD <> 'CNY'
         AND A.BALANCE <> 0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.JYDSMC LIKE '%农村信用%' THEN
                   'G01_13.2.B.2016'
                  WHEN A.IS_PRODUCT = 'Y' THEN
                   'G01_13.5.B.2016'
                  WHEN ORG_TYPE_SCLS IN ('F01',
                                         'F02',
                                         'F03',
                                         'F04',
                                         'F05',
                                         'F06',
                                         'F07',
                                         'F08',
                                         'F09',
                                         'F10') THEN
                   'G01_13.4.B.2016' --境内保险业金融机构
                  WHEN ORG_TYPE_SCLS IN ('H01',
                                         'H02',
                                         'I',
                                         'I01',
                                         'I02',
                                         'I03',
                                         'I04',
                                         'I05',
                                         'I06',
                                         'I07',
                                         'I08',
                                         'I09') THEN
                   'G01_13.5.B.2016' --境内其他金融机构
                  WHEN ORG_TYPE_SCLS IN ('C01',
                                         'C0101',
                                         'C0102',
                                         'C0103',
                                         'C06',
                                         'C07',
                                         'C08',
                                         'C09',
                                         'C10',
                                         'C11',
                                         'D01',
                                         'D0201',
                                         'D0202',
                                         'D03',
                                         'D04',
                                         'D05',
                                         'D06',
                                         'D07') THEN
                   'G01_13.2.B.2016' -- 境内其他银行业金融机构
                  WHEN ORG_TYPE_SCLS IN ('C02',
                                         'C03',
                                         'C04',
                                         'C05',
                                         'C12',
                                         'C1201',
                                         'C1202',
                                         'C13',
                                         'C14') THEN
                   'G01_13.1.B.2016' --境内商业银行
                  WHEN ORG_TYPE_SCLS IN ('E01',
                                         'E02',
                                         'E03',
                                         'E04',
                                         'E05',
                                         'E06',
                                         'E07',
                                         'E08',
                                         'E09') THEN
                   'G01_13.3.B.2016' --- 境内证券业金融机构
                  WHEN ORG_TYPE_SCLS IN ('A01', 'A02') THEN
                   'G01_13.8.B.2016' --中央银行
                END;

    COMMIT;

     V_STEP_ID   := V_STEP_ID+1;
    V_STEP_DESC := '卖出回购人民币/外币折人民币/本外币合计 逻辑处理开始';
    sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);
    
    -----add   by   zy   m1.20240805   人民币
    /*   31.卖出回购款项
    31.1境内商业银行
    31.2境内其他银行业金融机构
    31.3境内证券业金融机构
    31.4境内保险业金融机构
    31.5境内其他金融机构
    31.6境外金融机构
    31.7境内外非金融机构
    31.8中央银行 */

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             CASE
               WHEN A.JYDSMC LIKE '%农村信用%' THEN
                'G01_31.2.A.2016'
               WHEN A.IS_PRODUCT = 'Y' THEN
                'G01_31.5.A.2016' --产品户：境内其他金融机构
               WHEN ORG_TYPE_SCLS IN ('F01',
                                      'F02',
                                      'F03',
                                      'F04',
                                      'F05',
                                      'F06',
                                      'F07',
                                      'F08',
                                      'F09',
                                      'F10') THEN
                'G01_31.4.A.2016' --境内保险业金融机构
               WHEN ORG_TYPE_SCLS IN ('H01',
                                      'H02',
                                      'I',
                                      'I01',
                                      'I02',
                                      'I03',
                                      'I04',
                                      'I05',
                                      'I06',
                                      'I07',
                                      'I08',
                                      'I09') THEN
                'G01_31.5.A.2016' --境内其他金融机构
               WHEN ORG_TYPE_SCLS IN ('C01',
                                      'C0101',
                                      'C0102',
                                      'C0103',
                                      'C06',
                                      'C07',
                                      'C08',
                                      'C09',
                                      'C10',
                                      'C11',
                                      'D01',
                                      'D0201',
                                      'D0202',
                                      'D03',
                                      'D04',
                                      'D05',
                                      'D06',
                                      'D07') THEN
                'G01_31.2.A.2016' -- 境内其他银行业金融机构
               WHEN ORG_TYPE_SCLS IN ('C02',
                                      'C03',
                                      'C04',
                                      'C05',
                                      'C12',
                                      'C1201',
                                      'C1202',
                                      'C13',
                                      'C14') THEN
                'G01_31.1.A.2016' --境内商业银行
               WHEN ORG_TYPE_SCLS IN ('E01',
                                      'E02',
                                      'E03',
                                      'E04',
                                      'E05',
                                      'E06',
                                      'E07',
                                      'E08',
                                      'E09') THEN
                'G01_31.3.A.2016' --- 境内证券业金融机构
               WHEN ORG_TYPE_SCLS IN ('A01', 'A02') THEN
                'G01_31.8.A.2016' --中央银行
             END AS FINA_TYP,
             SUM(A.BALANCE * U.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_REPURCHASE A ---回购信息表
        LEFT JOIN SMTMODS_L_CUST_EXTERNAL_INFO FR ---客户外部信息表
          ON A.DATA_DATE = FR.DATA_DATE
         AND A.CUST_ID = FR.CUST_ID
         AND FR.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
       WHERE A.GL_ITEM_CODE IN ('211101') --债券卖出回购  211101
         AND A.DATA_DATE = I_DATADATE
         AND A.CURR_CD = 'CNY'
         AND A.BALANCE > 0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.JYDSMC LIKE '%农村信用%' THEN
                   'G01_31.2.A.2016'
                  WHEN A.IS_PRODUCT = 'Y' THEN
                   'G01_31.5.A.2016'
                  WHEN ORG_TYPE_SCLS IN ('F01',
                                         'F02',
                                         'F03',
                                         'F04',
                                         'F05',
                                         'F06',
                                         'F07',
                                         'F08',
                                         'F09',
                                         'F10') THEN
                   'G01_31.4.A.2016' --境内保险业金融机构
                  WHEN ORG_TYPE_SCLS IN ('H01',
                                         'H02',
                                         'I',
                                         'I01',
                                         'I02',
                                         'I03',
                                         'I04',
                                         'I05',
                                         'I06',
                                         'I07',
                                         'I08',
                                         'I09') THEN
                   'G01_31.5.A.2016' --境内其他金融机构
                  WHEN ORG_TYPE_SCLS IN ('C01',
                                         'C0101',
                                         'C0102',
                                         'C0103',
                                         'C06',
                                         'C07',
                                         'C08',
                                         'C09',
                                         'C10',
                                         'C11',
                                         'D01',
                                         'D0201',
                                         'D0202',
                                         'D03',
                                         'D04',
                                         'D05',
                                         'D06',
                                         'D07') THEN
                   'G01_31.2.A.2016' -- 境内其他银行业金融机构
                  WHEN ORG_TYPE_SCLS IN ('C02',
                                         'C03',
                                         'C04',
                                         'C05',
                                         'C12',
                                         'C1201',
                                         'C1202',
                                         'C13',
                                         'C14') THEN
                   'G01_31.1.A.2016' --境内商业银行
                  WHEN ORG_TYPE_SCLS IN ('E01',
                                         'E02',
                                         'E03',
                                         'E04',
                                         'E05',
                                         'E06',
                                         'E07',
                                         'E08',
                                         'E09') THEN
                   'G01_31.3.A.2016' --- 境内证券业金融机构
                  WHEN ORG_TYPE_SCLS IN ('A01', 'A02') THEN
                   'G01_31.8.A.2016' --中央银行
                END;

    COMMIT;

    ---外币折人民币
    --  [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务2111卖出回购本金
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             CASE
               WHEN A.JYDSMC LIKE '%农村信用%' THEN
                'G01_31.2.B.2016'
               WHEN A.IS_PRODUCT = 'Y' THEN
                'G01_31.5.B.2016'
               WHEN ORG_TYPE_SCLS IN ('F01',
                                      'F02',
                                      'F03',
                                      'F04',
                                      'F05',
                                      'F06',
                                      'F07',
                                      'F08',
                                      'F09',
                                      'F10') THEN
                'G01_31.4.B.2016' --境内保险业金融机构
               WHEN ORG_TYPE_SCLS IN ('H01',
                                      'H02',
                                      'I',
                                      'I01',
                                      'I02',
                                      'I03',
                                      'I04',
                                      'I05',
                                      'I06',
                                      'I07',
                                      'I08',
                                      'I09') THEN
                'G01_31.5.B.2016' --境内其他金融机构
               WHEN ORG_TYPE_SCLS IN ('C01',
                                      'C0101',
                                      'C0102',
                                      'C0103',
                                      'C06',
                                      'C07',
                                      'C08',
                                      'C09',
                                      'C10',
                                      'C11',
                                      'D01',
                                      'D0201',
                                      'D0202',
                                      'D03',
                                      'D04',
                                      'D05',
                                      'D06',
                                      'D07') THEN
                'G01_31.2.B.2016' -- 境内其他银行业金融机构
               WHEN ORG_TYPE_SCLS IN ('C02',
                                      'C03',
                                      'C04',
                                      'C05',
                                      'C12',
                                      'C1201',
                                      'C1202',
                                      'C13',
                                      'C14') THEN
                'G01_31.1.B.2016' --境内商业银行
               WHEN ORG_TYPE_SCLS IN ('E01',
                                      'E02',
                                      'E03',
                                      'E04',
                                      'E05',
                                      'E06',
                                      'E07',
                                      'E08',
                                      'E09') THEN
                'G01_31.3.B.2016' --- 境内证券业金融机构
               WHEN ORG_TYPE_SCLS IN ('A01', 'A02') THEN
                'G01_31.8.B.2016' --中央银行
             END AS FINA_TYP,
             SUM(A.BALANCE * U.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_REPURCHASE A ---回购信息表
        LEFT JOIN SMTMODS_L_CUST_EXTERNAL_INFO FR ---客户外部信息表
          ON A.CUST_ID = FR.CUST_ID
         AND A.DATA_DATE = FR.DATA_DATE
         AND FR.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD
         AND U.FORWARD_CCY = 'CNY'
         AND U.DATA_DATE = I_DATADATE
       WHERE SUBSTR(A.GL_ITEM_CODE, 1, 6) IN ('211101') --债券卖出回购  211101
         AND A.DATA_DATE = I_DATADATE
         AND A.CURR_CD <> 'CNY'
         AND A.BALANCE <> 0
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN A.JYDSMC LIKE '%农村信用%' THEN
                   'G01_31.2.B.2016'
                  WHEN A.IS_PRODUCT = 'Y' THEN
                   'G01_31.5.B.2016'
                  WHEN ORG_TYPE_SCLS IN ('F01',
                                         'F02',
                                         'F03',
                                         'F04',
                                         'F05',
                                         'F06',
                                         'F07',
                                         'F08',
                                         'F09',
                                         'F10') THEN
                   'G01_31.4.B.2016' --境内保险业金融机构
                  WHEN ORG_TYPE_SCLS IN ('H01',
                                         'H02',
                                         'I',
                                         'I01',
                                         'I02',
                                         'I03',
                                         'I04',
                                         'I05',
                                         'I06',
                                         'I07',
                                         'I08',
                                         'I09') THEN
                   'G01_31.5.B.2016' --境内其他金融机构
                  WHEN ORG_TYPE_SCLS IN ('C01',
                                         'C0101',
                                         'C0102',
                                         'C0103',
                                         'C06',
                                         'C07',
                                         'C08',
                                         'C09',
                                         'C10',
                                         'C11',
                                         'D01',
                                         'D0201',
                                         'D0202',
                                         'D03',
                                         'D04',
                                         'D05',
                                         'D06',
                                         'D07') THEN
                   'G01_31.2.B.2016' -- 境内其他银行业金融机构
                  WHEN ORG_TYPE_SCLS IN ('C02',
                                         'C03',
                                         'C04',
                                         'C05',
                                         'C12',
                                         'C1201',
                                         'C1202',
                                         'C13',
                                         'C14') THEN
                   'G01_31.1.B.2016' --境内商业银行
                  WHEN ORG_TYPE_SCLS IN ('E01',
                                         'E02',
                                         'E03',
                                         'E04',
                                         'E05',
                                         'E06',
                                         'E07',
                                         'E08',
                                         'E09') THEN
                   'G01_31.3.B.2016' -- 境内证券业金融机构
                  WHEN ORG_TYPE_SCLS IN ('A01', 'A02') THEN
                   'G01_31.8.B.2016' --中央银行
                END;

    COMMIT;
    ----  add   by   zy  start   20240806  009804机构

    V_STEP_FLAG := V_STEP_FLAG+1;
    V_STEP_DESC := '30.同业拆入人民币/外币折人民币/本外币合计逻辑处理开始 ';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);

    --20250902 常金磊 009804口径存在问题，业务康立军确认口径与同业金融部一致  以下逻辑去除 同步至同业金融部取数部分
    
    V_STEP_FLAG := V_STEP_FLAG+1;
    V_STEP_DESC := '附注项目12.1a国债-12.1e非金融企业债 逻辑处理开始';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM AS ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       CASE
         WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A01' THEN --产品分类,发行主体类型,资产证券化分类,发行主体境内境外标志
          'G01_12.1a.C.2021' --12.1a 国债.本外币合计
         WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02' THEN
          'G01_12.1b.C.2021' --12.1b 地方政府债.本外币合计
         WHEN (SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'B' AND B.ISSU_ORG = 'D01') OR
              (B.STOCK_PRO_TYPE LIKE 'C%' AND B.ISSU_ORG = 'D02') OR
              (SUBSTR(B.STOCK_PRO_TYPE, 1, 1) IN ('C', 'D') AND
              B.ISSU_ORG LIKE 'B%') THEN
          'G01_12.1c.C.2021' --12.1c 央行票据、政府机构债券和政策性金融债.本外币合计
         WHEN B.STOCK_PRO_TYPE LIKE 'C%' AND
              B.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07') THEN
          'G01_12.1d.C.2021' --12.1d 商业性金融债.本外币合计
         WHEN SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND B.ISSU_ORG LIKE 'C%' THEN
          'G01_12.1e.C.2021' --12.1e 非金融企业债.本外币合计
       END ITEM_NUM,
       SUM(NVL(A.Principal_Balance, 0) * U.CCY_RATE) AS ITEM_VALUE, --账面余额
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
       INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
          ON A.SUBJECT_CD = B.STOCK_CD
         AND B.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = I_DATADATE
         AND U.BASIC_CCY = A.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '00' ---投资业务品种
         AND B.STOCK_ASSET_TYPE IS NULL
         AND B.ISSUER_INLAND_FLG = 'Y'
       GROUP BY A.ORG_NUM,
                CASE
                  WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A01' THEN --产品分类,发行主体类型,资产证券化分类,发行主体境内境外标志
                   'G01_12.1a.C.2021' --12.1a 国债.本外币合计
                  WHEN B.STOCK_PRO_TYPE = 'A' AND B.ISSU_ORG = 'A02' THEN
                   'G01_12.1b.C.2021' --12.1b 地方政府债.本外币合计
                  WHEN (SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'B' AND
                       B.ISSU_ORG = 'D01') OR
                       (B.STOCK_PRO_TYPE LIKE 'C%' AND B.ISSU_ORG = 'D02') OR
                       (SUBSTR(B.STOCK_PRO_TYPE, 1, 1) IN ('C', 'D') AND
                       B.ISSU_ORG LIKE 'B%') THEN
                   'G01_12.1c.C.2021' --12.1c 央行票据、政府机构债券和政策性金融债.本外币合计
                  WHEN B.STOCK_PRO_TYPE LIKE 'C%' AND
                       B.ISSU_ORG IN ('D03', 'D04', 'D05', 'D06', 'D07') THEN
                   'G01_12.1d.C.2021' --12.1d 商业性金融债.本外币合计
                  WHEN SUBSTR(B.STOCK_PRO_TYPE, 1, 1) = 'D' AND
                       B.ISSU_ORG LIKE 'C%' THEN
                   'G01_12.1e.C.2021' --12.1e 非金融企业债.本外币合计
                END; 
    COMMIT;

    V_STEP_FLAG := V_STEP_FLAG+1;
    V_STEP_DESC := '63. 生息资产.数据特殊加工';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);
    --alter by shiyu 20240227
    /*
       总行口径:G01的3.存放中央银行款项+4.存放同业款项+6.贷款+7.贸易融资+8.贴现及买断式转贴现+10.拆放同业+12.3其他+13.买入返售资产+12.1债券+23.4投资同业存单-12.3.1其中：长期股权投资-卡垫款130604借方；--生产已取数规则
    刨除掉:除长期股权投资以外的股权投资（核心），业务手工账；--业务手动调整，不同于12.3.1其中：长期股权投资；
    同业的拆出资金42万（写死，固定值，历史问题）写死到机构，20万写到四平，22万是松原；--对生产规则补充开发；
    刨除交易性账户(110101借+110102借+110103借+110104借 -110102贷-110104贷+150102借（该科目只取009820机构）)；--交易性账户，对生产规则补充开发
    刨除债券投资逾期90天以上的债券投资；--对生产规则补充开发
       */

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             'G01_63.A.2024' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2'
        FROM (SELECT A.ORG_NUM,
                     SUM(NVL(A.PRINCIPAL_BALANCE, 0) * U.CCY_RATE) ITEM_VAL
                FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
               INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
                  ON A.SUBJECT_CD = B.STOCK_CD
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.INVEST_TYP = '00' ---投资业务品种
                 AND B.STOCK_ASSET_TYPE IS NULL
                 AND B.ISSUER_INLAND_FLG = 'Y'
                 AND A.DC_DATE < 0
                 AND ABS(A.DC_DATE) > 90
                 AND A.CURR_CD = 'CNY'
               GROUP BY A.ORG_NUM
              UNION ALL
              SELECT '070000' ORG_NUM, 200000 ITEM_VAL
                FROM system.DUAL
              UNION ALL
              SELECT '050000' ORG_NUM, 220000 ITEM_VAL
                FROM system.DUAL
              UNION ALL
              SELECT A.ORG_NUM,
                     SUM(CASE
                           WHEN A.ORG_NUM = '009820' THEN
                            CASE
                              WHEN A.ITEM_CD IN ('110102', '110104') THEN
                               A.DEBIT_BAL - A.CREDIT_BAL
                              WHEN A.ITEM_CD IN ('110101', '110103', '150102') THEN
                               A.DEBIT_BAL
                            END * B.CCY_RATE
                           WHEN A.ORG_NUM = '009804' THEN
                            CASE
                              WHEN A.ITEM_CD IN ('110102', '110104') THEN
                               A.DEBIT_BAL - A.CREDIT_BAL
                              WHEN A.ITEM_CD IN ('110101', '110103') THEN
                               A.DEBIT_BAL
                              ELSE
                               0
                            END * B.CCY_RATE
                         END) AS ITEM_VAL
                FROM SMTMODS_L_FINA_GL A
               INNER JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ITEM_CD IN
                     ('110101', '110102', '110103', '110104', '150102')
                 AND A.ORG_NUM IN ('009820', '009804')
                 AND A.CURR_CD = 'CNY'
               GROUP BY A.ORG_NUM
              UNION ALL
              SELECT A.ORG_NUM,
                     NVL(A.PRINCIPAL_BALANCE, 0) * U.CCY_RATE AS ITEM_VAL
                FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.SUBJECT_CD = 'X0003120B2700001' --18华阳经贸CP001 特殊处理
              )
       GROUP BY ORG_NUM;
    COMMIT;
 
       INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)

      SELECT I_DATADATE AS DATA_DATE,
             ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             'G01_63.B.2024' AS ITEM_NUM,
             SUM(ITEM_VAL) AS ITEM_VAL,
             '2'
        FROM (SELECT A.ORG_NUM,
                     SUM(NVL(A.PRINCIPAL_BALANCE, 0) * U.CCY_RATE) ITEM_VAL
                FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
               INNER JOIN SMTMODS_L_AGRE_BOND_INFO B -- 债券信息表
                  ON A.SUBJECT_CD = B.STOCK_CD
                 AND B.DATA_DATE = I_DATADATE
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY = 'CNY' --折算币种
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.INVEST_TYP = '00' ---投资业务品种
                 AND B.STOCK_ASSET_TYPE IS NULL
                 AND B.ISSUER_INLAND_FLG = 'Y'
                 AND A.DC_DATE < 0
                 AND ABS(A.DC_DATE) > 90
                 AND A.CURR_CD <> 'CNY'
               GROUP BY A.ORG_NUM
              UNION ALL
              SELECT A.ORG_NUM,
                     SUM(CASE
                           WHEN A.ORG_NUM = '009820' THEN
                            CASE
                              WHEN A.ITEM_CD IN ('110102', '110104') THEN
                               A.DEBIT_BAL - A.CREDIT_BAL
                              WHEN A.ITEM_CD IN ('110101', '110103', '150102') THEN
                               A.DEBIT_BAL
                            END * B.CCY_RATE
                           WHEN A.ORG_NUM = '009804' THEN
                            CASE
                              WHEN A.ITEM_CD IN ('110102', '110104') THEN
                               A.DEBIT_BAL - A.CREDIT_BAL
                              WHEN A.ITEM_CD IN ('110101', '110103') THEN
                               A.DEBIT_BAL
                              ELSE
                               0
                            END * B.CCY_RATE
                         END) AS ITEM_VAL
                FROM SMTMODS_L_FINA_GL A
               INNER JOIN SMTMODS_L_PUBL_RATE B
                  ON A.DATA_DATE = B.DATA_DATE
                 AND A.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY <> 'CNY'
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.ITEM_CD IN
                     ('110101', '110102', '110103', '110104', '150102')
                 AND A.ORG_NUM IN ('009820', '009804')
                 AND A.CURR_CD <> 'CNY'
               GROUP BY A.ORG_NUM
              UNION ALL
              SELECT A.ORG_NUM,
                     NVL(A.PRINCIPAL_BALANCE, 0) * U.CCY_RATE AS ITEM_VAL
                FROM SMTMODS_L_ACCT_FUND_INVEST A --投资业务信息表
                LEFT JOIN SMTMODS_L_PUBL_RATE U
                  ON U.CCY_DATE = I_DATADATE
                 AND U.BASIC_CCY = A.CURR_CD --基准币种
                 AND U.FORWARD_CCY <> 'CNY' --折算币种
               WHERE A.DATA_DATE = I_DATADATE
                 AND A.SUBJECT_CD = 'X0003120B2700001' --18华阳经贸CP001 特殊处理
              )
       GROUP by ORG_NUM;
    COMMIT;

    ---64. 付息负债全行刨除：刨除:20110111贷方个人信用卡存款 --对生产规则补充开发

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             'G01_64.A.2024' AS ITEM_NUM,
             SUM(A.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
             '2'
        FROM SMTMODS_L_FINA_GL A
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('20110111')
         AND A.CURR_CD = 'CNY'
       GROUP BY A.ORG_NUM;
    commit;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             A.ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             'G01_64.B.2024' AS ITEM_NUM,
             SUM(A.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL,
             '2'
        FROM SMTMODS_L_FINA_GL A
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.ITEM_CD IN ('20110111')
         AND A.CURR_CD <> 'CNY'
       GROUP BY A.ORG_NUM;
    commit;
    --------------================zdd     by   zy   20240805  金融市场部需求  start  ==============

    ----------------G01_12.1.A  投资.债券  人民币
    V_STEP_FLAG := V_STEP_FLAG+1;
    V_STEP_DESC := 'G01_12.1.A投资.债券人民币  ';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      select
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_12.1.A' AS ITEM_NUM,
       SUM(A.PRINCIPAL_BALANCE * B.CCY_RATE) AS ITEM_VAL,
       '2'
        FROM SMTMODS_L_ACCT_FUND_INVEST A ---投资业务信息表
        LEFT JOIN SMTMODS_L_AGRE_BOND_INFO C
          ON A.ACCT_NUM = C.STOCK_CD
         AND A.DATA_DATE = C.DATA_DATE
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.DATE_SOURCESD = '债券投资'
       GROUP BY A.ORG_NUM;
    COMMIT;

    ------------G01_12.1.B    投资.债券  外币折人民币
    V_STEP_FLAG := V_STEP_FLAG+1;
    V_STEP_DESC := 'G01_12.1.B投资.债券外币折人民币 ';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      select 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_12.1.B' AS ITEM_NUM,
       SUM(A.PRINCIPAL_BALANCE * B.CCY_RATE) AS ITEM_VAL,
       '2'
        FROM SMTMODS_L_ACCT_FUND_INVEST A ---投资业务信息表
        LEFT JOIN SMTMODS_L_AGRE_BOND_INFO C
          ON A.ACCT_NUM = C.STOCK_CD
         AND A.DATA_DATE = C.DATA_DATE
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.DATE_SOURCESD = '债券投资'
         AND A.CURR_CD <> 'CNY' ---外币
       GROUP BY A.ORG_NUM;
    COMMIT;

    ------------G01_12.3.A   投资.其他  人民币

    V_STEP_ID   := V_STEP_ID +1;
    V_STEP_DESC := 'G01_12.3.A投资.其他.人民币  ';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      select 
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_12.3.A' AS ITEM_NUM,
       SUM(A.PRINCIPAL_BALANCE * B.CCY_RATE) AS ITEM_VAL,
       '2'
        FROM SMTMODS_L_ACCT_FUND_INVEST A ---投资业务信息表
        LEFT JOIN SMTMODS_L_AGRE_BOND_INFO C
          ON A.ACCT_NUM = C.STOCK_CD
         AND A.DATA_DATE = C.DATA_DATE
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '04'
         AND A.ORG_NUM = '009804' ---后续其他机构有需求，需要放开机构条件
       GROUP BY A.ORG_NUM;
    COMMIT;

    --------------G01_12.3.B    投资.其他  外币折人民币

    V_STEP_ID   := V_STEP_ID +1;
    V_STEP_DESC := 'G01_12.3.B投资.其他.外币折人民币 ';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      select
       I_DATADATE AS DATA_DATE,
       A.ORG_NUM,
       'CBRC' AS SYS_NAM,
       'G01' AS REP_NUM,
       'G01_12.3.B' AS ITEM_NUM,
       SUM(A.PRINCIPAL_BALANCE * B.CCY_RATE) AS ITEM_VAL,
       '2'
        FROM SMTMODS_L_ACCT_FUND_INVEST A ---投资业务信息表
        LEFT JOIN SMTMODS_L_AGRE_BOND_INFO C
          ON A.ACCT_NUM = C.STOCK_CD
         AND A.DATA_DATE = C.DATA_DATE
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND A.INVEST_TYP = '04'
         AND A.ORG_NUM = '009804' ---后续其他机构有需求，需要放开机构条件
         AND A.CURR_CD <> 'CNY' ---外币
       GROUP BY A.ORG_NUM;
    COMMIT;

    -------------- zdd     by   zy   20240805  end  -----------
   
    -------------add 20250729 by shiyu JLBA202504300003 新增同业金融部009820 取数规则---------------------

    --删除同业数据指标

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND ITEM_NUM IN ('G01_30.4.A.2016',
                        'G01_30.5.A.2016',
                        'G01_30.2.A.2016',
                        'G01_30.1.A.2016',
                        'G01_30.3.A.2016',
                        'G01_30.4.B.2016',
                        'G01_30.5.B.2016',
                        'G01_30.2.B.2016',
                        'G01_30.1.B.2016',
                        'G01_30.3.B.2016',
                        'G01_4.4.A.2016',
                        'G01_4.5.A.2016',
                        'G01_4.2.A.2016',
                        'G01_4.1.A.2016',
                        'G01_4.3.A.2016',
                        'G01_4.4.B.2016',
                        'G01_4.5.B.2016',
                        'G01_4.2.B.2016',
                        'G01_4.1.B.2016',
                        'G01_4.3.B.2016',
                        'G01_10.4.A.2016',
                        'G01_10.5.A.2016',
                        'G01_10.2.A.2016',
                        'G01_10.1.A.2016',
                        'G01_10.3.A.2016',
                        'G01_10.4.B.2016',
                        'G01_10.5.B.2016',
                        'G01_10.2.B.2016',
                        'G01_10.1.B.2016',
                        'G01_10.3.B.2016',
                        'G01_12.3.A',
                        'G01_12.3.B',
                        'G01_30..A',
                        'G01_30..B',
                        'G01_63.A.009820',
                        'G01_63.B.009820')
       AND SYS_NAM = 'CBRC'
       AND REP_NUM = 'G01'
       AND ORG_NUM IN ('009820', '009801', '009804'); --20250902 常金磊 原009804口径存在问题，业务康立军确认口径与同业金融部一致
    COMMIT;

    --4. 存放同业款项

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             T1.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             CASE
               WHEN T1.ACCT_NUM IN ('9019804011150000162_1',
                                    '9019804011150000118_1',
                                    '9019811401000041_1',
                                    '9101100002591333_1',
                                    '9101100001017720_1',
                                    '9019811401000801_1',
                                    '9019811401001021_1') THEN
                'G01_4.1.A.2016'
               WHEN T1.ACCT_NUM = '9019811401000861_1' THEN
                'G01_4.2.A.2016'
               WHEN T1.ACCT_NUM IN
                    ('9019804011390200001_1', '9019800117000016_1') THEN
                'G01_4.3.A.2016'

               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6811',
                     'J6812',
                     'J6813',
                     'J6814',
                     'J6820',
                     'J6830',
                     'J6840',
                     'J6851',
                     'J6852',
                     'J6853',
                     'J6860',
                     'J6870',
                     'J6890') OR
                    T3.ORG_TYPE_SCLS IN ('F01',
                                         'F02',
                                         'F03',
                                         'F04',
                                         'F05',
                                         'F06',
                                         'F07',
                                         'F08',
                                         'F09',
                                         'F10') THEN
                'G01_4.4.A.2016' -- 境内保险业金融机构
               WHEN T3.ORG_TYPE_SCLS IN ('H01',
                                         'H02',
                                         'I',
                                         'I01',
                                         'I02',
                                         'I03',
                                         'I04',
                                         'I05',
                                         'I06',
                                         'I07',
                                         'I08',
                                         'I09') THEN
                'G01_4.5.A.2016' -- 境内其他金融机构
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6622',
                     'J6623',
                     'J6624',
                     'J6629',
                     'J6631',
                     'J6632',
                     'J6634',
                     'J6635',
                     'J6636',
                     'J6911',
                     'J6950',
                     'J6991') OR
                    T3.ORG_TYPE_SCLS IN ('C01',
                                         'C0101',
                                         'C0102',
                                         'C0103',
                                         'C06',
                                         'C07',
                                         'C08',
                                         'C09',
                                         'C10',
                                         'C11',
                                         'D01',
                                         'D02',
                                         'D0201',
                                         'D0202',
                                         'D03',
                                         'D04',
                                         'D05',
                                         'D06',
                                         'D07') THEN
                'G01_4.2.A.2016' -- 境内其他银行业金融机构
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) =
                    'J6621' OR
                    T3.ORG_TYPE_SCLS IN ('C02',
                                         'C03',
                                         'C04',
                                         'C05',
                                         'C12',
                                         'C1201',
                                         'C1202',
                                         'C13',
                                         'C14') THEN
                'G01_4.1.A.2016' -- 境内商业银行
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6711',
                     'J6712',
                     'J6720',
                     'J6731',
                     'J6732',
                     'J6739',
                     'J6741',
                     'J6749',
                     'J6750',
                     'J6760') OR
                    T3.ORG_TYPE_SCLS IN ('E01',
                                         'E02',
                                         'E03',
                                         'E04',
                                         'E05',
                                         'E06',
                                         'E07',
                                         'E07',
                                         'E09') THEN
                'G01_4.3.A.2016' -- 境内证券业金融机构
             END FINA_TYP,
             SUM(T1.BALANCE * U.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_MMFUND T1
        LEFT JOIN (SELECT A.*,
                          ROW_NUMBER() OVER(PARTITION BY A.TYSHXYDM ORDER BY A.ECIF_CUST_ID) RN
                     FROM SMTMODS_L_CUST_BILL_TY A
                    WHERE A.DATA_DATE = I_DATADATE) T2
          ON T1.JYDSTYDM = T2.TYSHXYDM
         AND T2.RN = 1
         AND T2.FINA_CODE_NEW <> 'Z'
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T1.DATA_DATE = U.DATA_DATE
         AND T1.CURR_CD = U.BASIC_CCY
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN (SELECT B.*,
                          ROW_NUMBER() OVER(PARTITION BY USCD ORDER BY CUST_ID) RN
                     FROM SMTMODS_L_CUST_EXTERNAL_INFO B
                    WHERE DATA_DATE = I_DATADATE
                      AND USCD IS NOT NULL) T3
          ON T1.JYDSTYDM = T3.USCD
         AND T3.RN = 1
        LEFT JOIN SMTMODS_L_CUST_C C --根据交易对手代码找ecif客户号,根据客户的行业类型区分金融机构分类，ecif取不到的在根据万德发行人信息表进行补充
          ON NVL(T2.ECIF_CUST_ID, T3.CUST_ID) = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT CC.*,
                          ROW_NUMBER() OVER(PARTITION BY CC.ID_NO ORDER BY CC.OPEN_DT DESC) RN
                     FROM SMTMODS_L_CUST_C CC
                    WHERE CC.DATA_DATE = I_DATADATE) CC
          ON T1.jydstydm = CC.ID_NO
         AND CC.RN = 1
       WHERE T1.DATA_DATE = I_DATADATE
         AND (T1.GL_ITEM_CODE LIKE '1031%' OR T1.GL_ITEM_CODE LIKE '1011%')
         AND T1.BALANCE <> 0
         AND T1.CURR_CD = 'CNY'
         AND T1.ORG_NUM = '009820'
       GROUP BY T1.ORG_NUM,
                CASE
                  WHEN T1.ACCT_NUM IN ('9019804011150000162_1',
                                       '9019804011150000118_1',
                                       '9019811401000041_1',
                                       '9101100002591333_1',
                                       '9101100001017720_1',
                                       '9019811401000801_1',
                                       '9019811401001021_1') THEN
                   'G01_4.1.A.2016'
                  WHEN T1.ACCT_NUM = '9019811401000861_1' THEN
                   'G01_4.2.A.2016'
                  WHEN T1.ACCT_NUM IN
                       ('9019804011390200001_1', '9019800117000016_1') THEN
                   'G01_4.3.A.2016'
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6811',
                        'J6812',
                        'J6813',
                        'J6814',
                        'J6820',
                        'J6830',
                        'J6840',
                        'J6851',
                        'J6852',
                        'J6853',
                        'J6860',
                        'J6870',
                        'J6890') OR
                       T3.ORG_TYPE_SCLS IN ('F01',
                                            'F02',
                                            'F03',
                                            'F04',
                                            'F05',
                                            'F06',
                                            'F07',
                                            'F08',
                                            'F09',
                                            'F10') THEN
                   'G01_4.4.A.2016' -- 境内保险业金融机构
                  WHEN T3.ORG_TYPE_SCLS IN ('H01',
                                            'H02',
                                            'I',
                                            'I01',
                                            'I02',
                                            'I03',
                                            'I04',
                                            'I05',
                                            'I06',
                                            'I07',
                                            'I08',
                                            'I09') THEN
                   'G01_4.5.A.2016' -- 境内其他金融机构
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6622',
                        'J6623',
                        'J6624',
                        'J6629',
                        'J6631',
                        'J6632',
                        'J6634',
                        'J6635',
                        'J6636',
                        'J6911',
                        'J6950',
                        'J6991') OR
                       T3.ORG_TYPE_SCLS IN ('C01',
                                            'C0101',
                                            'C0102',
                                            'C0103',
                                            'C06',
                                            'C07',
                                            'C08',
                                            'C09',
                                            'C10',
                                            'C11',
                                            'D01',
                                            'D02',
                                            'D0201',
                                            'D0202',
                                            'D03',
                                            'D04',
                                            'D05',
                                            'D06',
                                            'D07') THEN
                   'G01_4.2.A.2016' -- 境内其他银行业金融机构
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) =
                       'J6621' OR
                       T3.ORG_TYPE_SCLS IN ('C02',
                                            'C03',
                                            'C04',
                                            'C05',
                                            'C12',
                                            'C1201',
                                            'C1202',
                                            'C13',
                                            'C14') THEN
                   'G01_4.1.A.2016' -- 境内商业银行
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6711',
                        'J6712',
                        'J6720',
                        'J6731',
                        'J6732',
                        'J6739',
                        'J6741',
                        'J6749',
                        'J6750',
                        'J6760') OR
                       T3.ORG_TYPE_SCLS IN ('E01',
                                            'E02',
                                            'E03',
                                            'E04',
                                            'E05',
                                            'E06',
                                            'E07',
                                            'E07',
                                            'E09') THEN
                   'G01_4.3.A.2016' -- 境内证券业金融机构
                END;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             T1.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             CASE
               WHEN T1.ACCT_NUM IN ('9019804011150000162_1',
                                    '9019804011150000118_1',
                                    '9019811401000041_1',
                                    '9101100002591333_1',
                                    '9101100001017720_1',
                                    '9019811401000801_1',
                                    '9019811401001021_1') THEN
                'G01_4.1.B.2016'
               WHEN T1.ACCT_NUM = '9019811401000861_1' THEN
                'G01_4.2.B.2016'
               WHEN T1.ACCT_NUM IN
                    ('9019804011390200001_1', '9019800117000016_1') THEN
                'G01_4.3.B.2016'
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6811',
                     'J6812',
                     'J6813',
                     'J6814',
                     'J6820',
                     'J6830',
                     'J6840',
                     'J6851',
                     'J6852',
                     'J6853',
                     'J6860',
                     'J6870',
                     'J6890') OR
                    T3.ORG_TYPE_SCLS IN ('F01',
                                         'F02',
                                         'F03',
                                         'F04',
                                         'F05',
                                         'F06',
                                         'F07',
                                         'F08',
                                         'F09',
                                         'F10') THEN
                'G01_4.4.B.2016' -- 境内保险业金融机构
               WHEN T3.ORG_TYPE_SCLS IN ('H01',
                                         'H02',
                                         'I',
                                         'I01',
                                         'I02',
                                         'I03',
                                         'I04',
                                         'I05',
                                         'I06',
                                         'I07',
                                         'I08',
                                         'I09') THEN
                'G01_4.5.B.2016' -- 境内其他金融机构
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6622',
                     'J6623',
                     'J6624',
                     'J6629',
                     'J6631',
                     'J6632',
                     'J6634',
                     'J6635',
                     'J6636',
                     'J6911',
                     'J6950',
                     'J6991') OR
                    T3.ORG_TYPE_SCLS IN ('C01',
                                         'C0101',
                                         'C0102',
                                         'C0103',
                                         'C06',
                                         'C07',
                                         'C08',
                                         'C09',
                                         'C10',
                                         'C11',
                                         'D01',
                                         'D02',
                                         'D0201',
                                         'D0202',
                                         'D03',
                                         'D04',
                                         'D05',
                                         'D06',
                                         'D07') THEN
                'G01_4.2.B.2016' -- 境内其他银行业金融机构
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) =
                    'J6621' OR
                    T3.ORG_TYPE_SCLS IN ('C02',
                                         'C03',
                                         'C04',
                                         'C05',
                                         'C12',
                                         'C1201',
                                         'C1202',
                                         'C13',
                                         'C14') THEN
                'G01_4.1.B.2016' -- 境内商业银行
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6711',
                     'J6712',
                     'J6720',
                     'J6731',
                     'J6732',
                     'J6739',
                     'J6741',
                     'J6749',
                     'J6750',
                     'J6760') OR
                    T3.ORG_TYPE_SCLS IN ('E01',
                                         'E02',
                                         'E03',
                                         'E04',
                                         'E05',
                                         'E06',
                                         'E07',
                                         'E07',
                                         'E09') THEN
                'G01_4.3.B.2016' -- 境内证券业金融机构
             END FINA_TYP,
             SUM(T1.BALANCE * U.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_MMFUND T1
        LEFT JOIN (SELECT A.*,
                          ROW_NUMBER() OVER(PARTITION BY A.TYSHXYDM ORDER BY A.ECIF_CUST_ID) RN
                     FROM SMTMODS_L_CUST_BILL_TY A
                    WHERE A.DATA_DATE = I_DATADATE) T2
          ON T1.JYDSTYDM = T2.TYSHXYDM
         AND T2.RN = 1
         AND T2.FINA_CODE_NEW <> 'Z'
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T1.DATA_DATE = U.DATA_DATE
         AND T1.CURR_CD = U.BASIC_CCY
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN (SELECT B.*,
                          ROW_NUMBER() OVER(PARTITION BY USCD ORDER BY CUST_ID) RN
                     FROM SMTMODS_L_CUST_EXTERNAL_INFO B
                    WHERE DATA_DATE = I_DATADATE
                      AND USCD IS NOT NULL) T3
          ON T1.JYDSTYDM = T3.USCD
         AND T3.RN = 1
        LEFT JOIN SMTMODS_L_CUST_C C --根据交易对手代码找ecif客户号,根据客户的行业类型区分金融机构分类，ecif取不到的在根据万德发行人信息表进行补充
          ON NVL(T2.ECIF_CUST_ID, T3.CUST_ID) = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT CC.*,
                          ROW_NUMBER() OVER(PARTITION BY CC.ID_NO ORDER BY CC.OPEN_DT DESC) RN
                     FROM SMTMODS_L_CUST_C CC
                    WHERE CC.DATA_DATE = I_DATADATE) CC
          ON T1.jydstydm = CC.ID_NO
         AND CC.RN = 1
       WHERE T1.DATA_DATE = I_DATADATE
         AND (T1.GL_ITEM_CODE LIKE '1031%' OR T1.GL_ITEM_CODE LIKE '1011%')
         AND T1.BALANCE <> 0
         AND T1.CURR_CD <> 'CNY'
         AND T1.ORG_NUM = '009820'
       GROUP BY T1.ORG_NUM,
                CASE
                  WHEN T1.ACCT_NUM IN ('9019804011150000162_1',
                                       '9019804011150000118_1',
                                       '9019811401000041_1',
                                       '9101100002591333_1',
                                       '9101100001017720_1',
                                       '9019811401000801_1',
                                       '9019811401001021_1') THEN
                   'G01_4.1.B.2016'
                  WHEN T1.ACCT_NUM = '9019811401000861_1' THEN
                   'G01_4.2.B.2016'
                  WHEN T1.ACCT_NUM IN
                       ('9019804011390200001_1', '9019800117000016_1') THEN
                   'G01_4.3.B.2016'
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6811',
                        'J6812',
                        'J6813',
                        'J6814',
                        'J6820',
                        'J6830',
                        'J6840',
                        'J6851',
                        'J6852',
                        'J6853',
                        'J6860',
                        'J6870',
                        'J6890') OR
                       T3.ORG_TYPE_SCLS IN ('F01',
                                            'F02',
                                            'F03',
                                            'F04',
                                            'F05',
                                            'F06',
                                            'F07',
                                            'F08',
                                            'F09',
                                            'F10') THEN
                   'G01_4.4.B.2016' -- 境内保险业金融机构
                  WHEN T3.ORG_TYPE_SCLS IN ('H01',
                                            'H02',
                                            'I',
                                            'I01',
                                            'I02',
                                            'I03',
                                            'I04',
                                            'I05',
                                            'I06',
                                            'I07',
                                            'I08',
                                            'I09') THEN
                   'G01_4.5.B.2016' -- 境内其他金融机构
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6622',
                        'J6623',
                        'J6624',
                        'J6629',
                        'J6631',
                        'J6632',
                        'J6634',
                        'J6635',
                        'J6636',
                        'J6911',
                        'J6950',
                        'J6991') OR
                       T3.ORG_TYPE_SCLS IN ('C01',
                                            'C0101',
                                            'C0102',
                                            'C0103',
                                            'C06',
                                            'C07',
                                            'C08',
                                            'C09',
                                            'C10',
                                            'C11',
                                            'D01',
                                            'D02',
                                            'D0201',
                                            'D0202',
                                            'D03',
                                            'D04',
                                            'D05',
                                            'D06',
                                            'D07') THEN
                   'G01_4.2.B.2016' -- 境内其他银行业金融机构
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) =
                       'J6621' OR
                       T3.ORG_TYPE_SCLS IN ('C02',
                                            'C03',
                                            'C04',
                                            'C05',
                                            'C12',
                                            'C1201',
                                            'C1202',
                                            'C13',
                                            'C14') THEN
                   'G01_4.1.B.2016' -- 境内商业银行
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6711',
                        'J6712',
                        'J6720',
                        'J6731',
                        'J6732',
                        'J6739',
                        'J6741',
                        'J6749',
                        'J6750',
                        'J6760') OR
                       T3.ORG_TYPE_SCLS IN ('E01',
                                            'E02',
                                            'E03',
                                            'E04',
                                            'E05',
                                            'E06',
                                            'E07',
                                            'E07',
                                            'E09') THEN
                   'G01_4.3.B.2016' -- 境内证券业金融机构
                END;
    COMMIT;

    --10. 拆放同业
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             T1.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             CASE
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6811',
                     'J6812',
                     'J6813',
                     'J6814',
                     'J6820',
                     'J6830',
                     'J6840',
                     'J6851',
                     'J6852',
                     'J6853',
                     'J6860',
                     'J6870',
                     'J6890') OR
                    T3.ORG_TYPE_SCLS IN ('F01',
                                         'F02',
                                         'F03',
                                         'F04',
                                         'F05',
                                         'F06',
                                         'F07',
                                         'F08',
                                         'F09',
                                         'F10') THEN
                'G01_10.4.A.2016' -- 境内保险业金融机构
               WHEN T3.ORG_TYPE_SCLS IN ('H01',
                                         'H02',
                                         'I',
                                         'I01',
                                         'I02',
                                         'I03',
                                         'I04',
                                         'I05',
                                         'I06',
                                         'I07',
                                         'I08',
                                         'I09') THEN
                'G01_10.5.A.2016' -- 境内其他金融机构
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6622',
                     'J6623',
                     'J6624',
                     'J6629',
                     'J6631',
                     'J6632',
                     'J6634',
                     'J6635',
                     'J6636',
                     'J6911',
                     'J6950',
                     'J6991') OR
                    T3.ORG_TYPE_SCLS IN ('C01',
                                         'C0101',
                                         'C0102',
                                         'C0103',
                                         'C06',
                                         'C07',
                                         'C08',
                                         'C09',
                                         'C10',
                                         'C11',
                                         'D01',
                                         'D02',
                                         'D0201',
                                         'D0202',
                                         'D03',
                                         'D04',
                                         'D05',
                                         'D06',
                                         'D07') THEN
                'G01_10.2.A.2016' -- 境内其他银行业金融机构
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) =
                    'J6621' OR
                    T3.ORG_TYPE_SCLS IN ('C02',
                                         'C03',
                                         'C04',
                                         'C05',
                                         'C12',
                                         'C1201',
                                         'C1202',
                                         'C13',
                                         'C14') THEN
                'G01_10.1.A.2016' -- 境内商业银行
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6711',
                     'J6712',
                     'J6720',
                     'J6731',
                     'J6732',
                     'J6739',
                     'J6741',
                     'J6749',
                     'J6750',
                     'J6760') OR
                    T3.ORG_TYPE_SCLS IN ('E01',
                                         'E02',
                                         'E03',
                                         'E04',
                                         'E05',
                                         'E06',
                                         'E07',
                                         'E07',
                                         'E09') THEN
                'G01_10.3.A.2016' -- 境内证券业金融机构
             END FINA_TYP, --根据交易对手代码找ecif客户号,根据客户的行业类型区分金融机构分类，ecif取不到的在根据万德发行人信息表进行补充
             SUM(T1.BALANCE * U.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_MMFUND T1
        LEFT JOIN (SELECT A.*,
                          ROW_NUMBER() OVER(PARTITION BY A.TYSHXYDM ORDER BY A.ECIF_CUST_ID) RN
                     FROM SMTMODS_L_CUST_BILL_TY A
                    WHERE A.DATA_DATE = I_DATADATE) T2
          ON T1.JYDSTYDM = T2.TYSHXYDM
         AND T2.RN = 1
         AND T2.FINA_CODE_NEW <> 'Z'
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T1.DATA_DATE = U.DATA_DATE
         AND T1.CURR_CD = U.BASIC_CCY
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN (SELECT B.*,
                          ROW_NUMBER() OVER(PARTITION BY USCD ORDER BY CUST_ID) RN
                     FROM SMTMODS_L_CUST_EXTERNAL_INFO B
                    WHERE DATA_DATE = I_DATADATE
                      AND USCD IS NOT NULL) T3
          ON T1.JYDSTYDM = T3.USCD
         AND T3.RN = 1
        LEFT JOIN SMTMODS_L_CUST_C C
          ON NVL(T2.ECIF_CUST_ID, T3.CUST_ID) = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT CC.*,
                          ROW_NUMBER() OVER(PARTITION BY CC.ID_NO ORDER BY CC.OPEN_DT DESC) RN
                     FROM SMTMODS_L_CUST_C CC
                    WHERE CC.DATA_DATE = I_DATADATE) CC
          ON T1.jydstydm = CC.ID_NO
         AND CC.RN = 1
       WHERE T1.DATA_DATE = I_DATADATE
         AND (T1.GL_ITEM_CODE LIKE '1302%')
         AND T1.BALANCE <> 0
            --  AND T1.CURR_CD = 'CNY'
         AND T1.ORG_NUM IN ('009820', '009804') --20250902 常金磊 原009804口径存在问题，业务康立军确认口径与同业金融部一致
       GROUP BY T1.ORG_NUM,
                CASE
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6811',
                        'J6812',
                        'J6813',
                        'J6814',
                        'J6820',
                        'J6830',
                        'J6840',
                        'J6851',
                        'J6852',
                        'J6853',
                        'J6860',
                        'J6870',
                        'J6890') OR
                       T3.ORG_TYPE_SCLS IN ('F01',
                                            'F02',
                                            'F03',
                                            'F04',
                                            'F05',
                                            'F06',
                                            'F07',
                                            'F08',
                                            'F09',
                                            'F10') THEN
                   'G01_10.4.A.2016' -- 境内保险业金融机构
                  WHEN T3.ORG_TYPE_SCLS IN ('H01',
                                            'H02',
                                            'I',
                                            'I01',
                                            'I02',
                                            'I03',
                                            'I04',
                                            'I05',
                                            'I06',
                                            'I07',
                                            'I08',
                                            'I09') THEN
                   'G01_10.5.A.2016' -- 境内其他金融机构
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6622',
                        'J6623',
                        'J6624',
                        'J6629',
                        'J6631',
                        'J6632',
                        'J6634',
                        'J6635',
                        'J6636',
                        'J6911',
                        'J6950',
                        'J6991') OR
                       T3.ORG_TYPE_SCLS IN ('C01',
                                            'C0101',
                                            'C0102',
                                            'C0103',
                                            'C06',
                                            'C07',
                                            'C08',
                                            'C09',
                                            'C10',
                                            'C11',
                                            'D01',
                                            'D02',
                                            'D0201',
                                            'D0202',
                                            'D03',
                                            'D04',
                                            'D05',
                                            'D06',
                                            'D07') THEN
                   'G01_10.2.A.2016' -- 境内其他银行业金融机构
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) =
                       'J6621' OR
                       T3.ORG_TYPE_SCLS IN ('C02',
                                            'C03',
                                            'C04',
                                            'C05',
                                            'C12',
                                            'C1201',
                                            'C1202',
                                            'C13',
                                            'C14') THEN
                   'G01_10.1.A.2016' -- 境内商业银行
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6711',
                        'J6712',
                        'J6720',
                        'J6731',
                        'J6732',
                        'J6739',
                        'J6741',
                        'J6749',
                        'J6750',
                        'J6760') OR
                       T3.ORG_TYPE_SCLS IN ('E01',
                                            'E02',
                                            'E03',
                                            'E04',
                                            'E05',
                                            'E06',
                                            'E07',
                                            'E07',
                                            'E09') THEN
                   'G01_10.3.A.2016' -- 境内证券业金融机构
                END;
    COMMIT;

    --  [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务1302拆出资金本金
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             T1.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             CASE
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6811',
                     'J6812',
                     'J6813',
                     'J6814',
                     'J6820',
                     'J6830',
                     'J6840',
                     'J6851',
                     'J6852',
                     'J6853',
                     'J6860',
                     'J6870',
                     'J6890') OR
                    T3.ORG_TYPE_SCLS IN ('F01',
                                         'F02',
                                         'F03',
                                         'F04',
                                         'F05',
                                         'F06',
                                         'F07',
                                         'F08',
                                         'F09',
                                         'F10') THEN
                'G01_10.4.B.2016' -- 境内保险业金融机构
               WHEN T3.ORG_TYPE_SCLS IN ('H01',
                                         'H02',
                                         'I',
                                         'I01',
                                         'I02',
                                         'I03',
                                         'I04',
                                         'I05',
                                         'I06',
                                         'I07',
                                         'I08',
                                         'I09') THEN
                'G01_10.5.B.2016' -- 境内其他金融机构
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6622',
                     'J6623',
                     'J6624',
                     'J6629',
                     'J6631',
                     'J6632',
                     'J6634',
                     'J6635',
                     'J6636',
                     'J6911',
                     'J6950',
                     'J6991') OR
                    T3.ORG_TYPE_SCLS IN ('C01',
                                         'C0101',
                                         'C0102',
                                         'C0103',
                                         'C06',
                                         'C07',
                                         'C08',
                                         'C09',
                                         'C10',
                                         'C11',
                                         'D01',
                                         'D02',
                                         'D0201',
                                         'D0202',
                                         'D03',
                                         'D04',
                                         'D05',
                                         'D06',
                                         'D07') THEN
                'G01_10.2.B.2016' -- 境内其他银行业金融机构
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) =
                    'J6621' OR
                    T3.ORG_TYPE_SCLS IN ('C02',
                                         'C03',
                                         'C04',
                                         'C05',
                                         'C12',
                                         'C1201',
                                         'C1202',
                                         'C13',
                                         'C14') THEN
                'G01_10.1.B.2016' -- 境内商业银行
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6711',
                     'J6712',
                     'J6720',
                     'J6731',
                     'J6732',
                     'J6739',
                     'J6741',
                     'J6749',
                     'J6750',
                     'J6760') OR
                    T3.ORG_TYPE_SCLS IN ('E01',
                                         'E02',
                                         'E03',
                                         'E04',
                                         'E05',
                                         'E06',
                                         'E07',
                                         'E07',
                                         'E09') THEN
                'G01_10.3.B.2016' -- 境内证券业金融机构
             END FINA_TYP,
             SUM(T1.BALANCE * U.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_MMFUND T1
        LEFT JOIN (SELECT A.*,
                          ROW_NUMBER() OVER(PARTITION BY A.TYSHXYDM ORDER BY A.ECIF_CUST_ID) RN
                     FROM SMTMODS_L_CUST_BILL_TY A
                    WHERE A.DATA_DATE = I_DATADATE) T2
          ON T1.JYDSTYDM = T2.TYSHXYDM
         AND T2.RN = 1
         AND T2.FINA_CODE_NEW <> 'Z'
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T1.DATA_DATE = U.DATA_DATE
         AND T1.CURR_CD = U.BASIC_CCY
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN (SELECT B.*,
                          ROW_NUMBER() OVER(PARTITION BY USCD ORDER BY CUST_ID) RN
                     FROM SMTMODS_L_CUST_EXTERNAL_INFO B
                    WHERE DATA_DATE = I_DATADATE
                      AND USCD IS NOT NULL) T3
          ON T1.JYDSTYDM = T3.USCD
         AND T3.RN = 1
        LEFT JOIN SMTMODS_L_CUST_C C --根据交易对手代码找ecif客户号,根据客户的行业类型区分金融机构分类，ecif取不到的在根据万德发行人信息表进行补充
          ON NVL(T2.ECIF_CUST_ID, T3.CUST_ID) = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT CC.*,
                          ROW_NUMBER() OVER(PARTITION BY CC.ID_NO ORDER BY CC.OPEN_DT DESC) RN
                     FROM SMTMODS_L_CUST_C CC
                    WHERE CC.DATA_DATE = I_DATADATE) CC
          ON T1.jydstydm = CC.ID_NO
         AND CC.RN = 1
       WHERE T1.DATA_DATE = I_DATADATE
         AND (T1.GL_ITEM_CODE LIKE '1302%')
         AND T1.BALANCE <> 0
         AND T1.CURR_CD <> 'CNY'
         AND T1.ORG_NUM IN ('009820', '009801', '009804') --20250902 常金磊 原009804口径存在问题，业务康立军确认口径与同业金融部一致
       GROUP BY T1.ORG_NUM,
                CASE
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6811',
                        'J6812',
                        'J6813',
                        'J6814',
                        'J6820',
                        'J6830',
                        'J6840',
                        'J6851',
                        'J6852',
                        'J6853',
                        'J6860',
                        'J6870',
                        'J6890') OR
                       T3.ORG_TYPE_SCLS IN ('F01',
                                            'F02',
                                            'F03',
                                            'F04',
                                            'F05',
                                            'F06',
                                            'F07',
                                            'F08',
                                            'F09',
                                            'F10') THEN
                   'G01_10.4.B.2016' -- 境内保险业金融机构
                  WHEN T3.ORG_TYPE_SCLS IN ('H01',
                                            'H02',
                                            'I',
                                            'I01',
                                            'I02',
                                            'I03',
                                            'I04',
                                            'I05',
                                            'I06',
                                            'I07',
                                            'I08',
                                            'I09') THEN
                   'G01_10.5.B.2016' -- 境内其他金融机构
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6622',
                        'J6623',
                        'J6624',
                        'J6629',
                        'J6631',
                        'J6632',
                        'J6634',
                        'J6635',
                        'J6636',
                        'J6911',
                        'J6950',
                        'J6991') OR
                       T3.ORG_TYPE_SCLS IN ('C01',
                                            'C0101',
                                            'C0102',
                                            'C0103',
                                            'C06',
                                            'C07',
                                            'C08',
                                            'C09',
                                            'C10',
                                            'C11',
                                            'D01',
                                            'D02',
                                            'D0201',
                                            'D0202',
                                            'D03',
                                            'D04',
                                            'D05',
                                            'D06',
                                            'D07') THEN
                   'G01_10.2.B.2016' -- 境内其他银行业金融机构
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) =
                       'J6621' OR
                       T3.ORG_TYPE_SCLS IN ('C02',
                                            'C03',
                                            'C04',
                                            'C05',
                                            'C12',
                                            'C1201',
                                            'C1202',
                                            'C13',
                                            'C14') THEN
                   'G01_10.1.B.2016' -- 境内商业银行
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6711',
                        'J6712',
                        'J6720',
                        'J6731',
                        'J6732',
                        'J6739',
                        'J6741',
                        'J6749',
                        'J6750',
                        'J6760') OR
                       T3.ORG_TYPE_SCLS IN ('E01',
                                            'E02',
                                            'E03',
                                            'E04',
                                            'E05',
                                            'E06',
                                            'E07',
                                            'E07',
                                            'E09') THEN
                   'G01_10.3.B.2016' -- 境内证券业金融机构
                END;
    COMMIT;

    ---30. 同业拆入

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             T1.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             CASE
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6811',
                     'J6812',
                     'J6813',
                     'J6814',
                     'J6820',
                     'J6830',
                     'J6840',
                     'J6851',
                     'J6852',
                     'J6853',
                     'J6860',
                     'J6870',
                     'J6890') OR
                    T3.ORG_TYPE_SCLS IN ('F01',
                                         'F02',
                                         'F03',
                                         'F04',
                                         'F05',
                                         'F06',
                                         'F07',
                                         'F08',
                                         'F09',
                                         'F10') THEN
                'G01_30.4.A.2016' -- 境内保险业金融机构
               WHEN T3.ORG_TYPE_SCLS IN ('H01',
                                         'H02',
                                         'I',
                                         'I01',
                                         'I02',
                                         'I03',
                                         'I04',
                                         'I05',
                                         'I06',
                                         'I07',
                                         'I08',
                                         'I09') THEN
                'G01_30.5.A.2016' -- 境内其他金融机构
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6622',
                     'J6623',
                     'J6624',
                     'J6629',
                     'J6631',
                     'J6632',
                     'J6634',
                     'J6635',
                     'J6636',
                     'J6911',
                     'J6950',
                     'J6991') OR
                    T3.ORG_TYPE_SCLS IN ('C01',
                                         'C0101',
                                         'C0102',
                                         'C0103',
                                         'C06',
                                         'C07',
                                         'C08',
                                         'C09',
                                         'C10',
                                         'C11',
                                         'D01',
                                         'D02',
                                         'D0201',
                                         'D0202',
                                         'D03',
                                         'D04',
                                         'D05',
                                         'D06',
                                         'D07') THEN
                'G01_30.2.A.2016' -- 境内其他银行业金融机构
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) =
                    'J6621' OR
                    T3.ORG_TYPE_SCLS IN ('C02',
                                         'C03',
                                         'C04',
                                         'C05',
                                         'C12',
                                         'C1201',
                                         'C1202',
                                         'C13',
                                         'C14') THEN
                'G01_30.1.A.2016' -- 境内商业银行
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6711',
                     'J6712',
                     'J6720',
                     'J6731',
                     'J6732',
                     'J6739',
                     'J6741',
                     'J6749',
                     'J6750',
                     'J6760') OR
                    T3.ORG_TYPE_SCLS IN ('E01',
                                         'E02',
                                         'E03',
                                         'E04',
                                         'E05',
                                         'E06',
                                         'E07',
                                         'E07',
                                         'E09') THEN
                'G01_30.3.A.2016' -- 境内证券业金融机构
             END FINA_TYP,
             SUM(T1.BALANCE * U.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_MMFUND T1
        LEFT JOIN (SELECT A.*,
                          ROW_NUMBER() OVER(PARTITION BY A.TYSHXYDM ORDER BY A.ECIF_CUST_ID) RN
                     FROM SMTMODS_L_CUST_BILL_TY A
                    WHERE A.DATA_DATE = I_DATADATE) T2
          ON T1.JYDSTYDM = T2.TYSHXYDM
         AND T2.RN = 1
         AND T2.FINA_CODE_NEW <> 'Z'
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T1.DATA_DATE = U.DATA_DATE
         AND T1.CURR_CD = U.BASIC_CCY
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN (SELECT B.*,
                          ROW_NUMBER() OVER(PARTITION BY USCD ORDER BY CUST_ID) RN
                     FROM SMTMODS_L_CUST_EXTERNAL_INFO B
                    WHERE DATA_DATE = I_DATADATE
                      AND USCD IS NOT NULL) T3
          ON T1.JYDSTYDM = T3.USCD
         AND T3.RN = 1
        LEFT JOIN SMTMODS_L_CUST_C C --根据交易对手代码找ecif客户号,根据客户的行业类型区分金融机构分类，ecif取不到的在根据万德发行人信息表进行补充
          ON NVL(T2.ECIF_CUST_ID, T3.CUST_ID) = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT CC.*,
                          ROW_NUMBER() OVER(PARTITION BY CC.ID_NO ORDER BY CC.OPEN_DT DESC) RN
                     FROM SMTMODS_L_CUST_C CC
                    WHERE CC.DATA_DATE = I_DATADATE) CC
          ON T1.jydstydm = CC.ID_NO
         AND CC.RN = 1
       WHERE T1.DATA_DATE = I_DATADATE
         AND (T1.GL_ITEM_CODE LIKE '200301%')
         AND T1.BALANCE <> 0
         AND T1.CURR_CD = 'CNY'
         AND T1.ORG_NUM IN ('009820', '009804') --20250902 常金磊 原009804口径存在问题，业务康立军确认口径与同业金融部一致
       GROUP BY T1.ORG_NUM,
                CASE
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6811',
                        'J6812',
                        'J6813',
                        'J6814',
                        'J6820',
                        'J6830',
                        'J6840',
                        'J6851',
                        'J6852',
                        'J6853',
                        'J6860',
                        'J6870',
                        'J6890') OR
                       T3.ORG_TYPE_SCLS IN ('F01',
                                            'F02',
                                            'F03',
                                            'F04',
                                            'F05',
                                            'F06',
                                            'F07',
                                            'F08',
                                            'F09',
                                            'F10') THEN
                   'G01_30.4.A.2016' -- 境内保险业金融机构
                  WHEN T3.ORG_TYPE_SCLS IN ('H01',
                                            'H02',
                                            'I',
                                            'I01',
                                            'I02',
                                            'I03',
                                            'I04',
                                            'I05',
                                            'I06',
                                            'I07',
                                            'I08',
                                            'I09') THEN
                   'G01_30.5.A.2016' -- 境内其他金融机构
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6622',
                        'J6623',
                        'J6624',
                        'J6629',
                        'J6631',
                        'J6632',
                        'J6634',
                        'J6635',
                        'J6636',
                        'J6911',
                        'J6950',
                        'J6991') OR
                       T3.ORG_TYPE_SCLS IN ('C01',
                                            'C0101',
                                            'C0102',
                                            'C0103',
                                            'C06',
                                            'C07',
                                            'C08',
                                            'C09',
                                            'C10',
                                            'C11',
                                            'D01',
                                            'D02',
                                            'D0201',
                                            'D0202',
                                            'D03',
                                            'D04',
                                            'D05',
                                            'D06',
                                            'D07') THEN
                   'G01_30.2.A.2016' -- 境内其他银行业金融机构
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) =
                       'J6621' OR
                       T3.ORG_TYPE_SCLS IN ('C02',
                                            'C03',
                                            'C04',
                                            'C05',
                                            'C12',
                                            'C1201',
                                            'C1202',
                                            'C13',
                                            'C14') THEN
                   'G01_30.1.A.2016' -- 境内商业银行
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6711',
                        'J6712',
                        'J6720',
                        'J6731',
                        'J6732',
                        'J6739',
                        'J6741',
                        'J6749',
                        'J6750',
                        'J6760') OR
                       T3.ORG_TYPE_SCLS IN ('E01',
                                            'E02',
                                            'E03',
                                            'E04',
                                            'E05',
                                            'E06',
                                            'E07',
                                            'E07',
                                            'E09') THEN
                   'G01_30.3.A.2016' -- 境内证券业金融机构
                END;
    COMMIT;

    --  [2025-09-19] [狄家卉] [JLBA202505280011][赵翰君] 增加009801清算中心外币业务2003拆入资金
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             T1.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             CASE
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6811',
                     'J6812',
                     'J6813',
                     'J6814',
                     'J6820',
                     'J6830',
                     'J6840',
                     'J6851',
                     'J6852',
                     'J6853',
                     'J6860',
                     'J6870',
                     'J6890') OR
                    T3.ORG_TYPE_SCLS IN ('F01',
                                         'F02',
                                         'F03',
                                         'F04',
                                         'F05',
                                         'F06',
                                         'F07',
                                         'F08',
                                         'F09',
                                         'F10') THEN
                'G01_30.4.B.2016' -- 境内保险业金融机构
               WHEN T3.ORG_TYPE_SCLS IN ('H01',
                                         'H02',
                                         'I',
                                         'I01',
                                         'I02',
                                         'I03',
                                         'I04',
                                         'I05',
                                         'I06',
                                         'I07',
                                         'I08',
                                         'I09') THEN
                'G01_30.5.B.2016' -- 境内其他金融机构
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6622',
                     'J6623',
                     'J6624',
                     'J6629',
                     'J6631',
                     'J6632',
                     'J6634',
                     'J6635',
                     'J6636',
                     'J6911',
                     'J6950',
                     'J6991') OR
                    T3.ORG_TYPE_SCLS IN ('C01',
                                         'C0101',
                                         'C0102',
                                         'C0103',
                                         'C06',
                                         'C07',
                                         'C08',
                                         'C09',
                                         'C10',
                                         'C11',
                                         'D01',
                                         'D02',
                                         'D0201',
                                         'D0202',
                                         'D03',
                                         'D04',
                                         'D05',
                                         'D06',
                                         'D07') THEN
                'G01_30.2.B.2016' -- 境内其他银行业金融机构
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) =
                    'J6621' OR
                    T3.ORG_TYPE_SCLS IN ('C02',
                                         'C03',
                                         'C04',
                                         'C05',
                                         'C12',
                                         'C1201',
                                         'C1202',
                                         'C13',
                                         'C14') THEN
                'G01_30.1.B.2016' -- 境内商业银行
               WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                    ('J6711',
                     'J6712',
                     'J6720',
                     'J6731',
                     'J6732',
                     'J6739',
                     'J6741',
                     'J6749',
                     'J6750',
                     'J6760') OR
                    T3.ORG_TYPE_SCLS IN ('E01',
                                         'E02',
                                         'E03',
                                         'E04',
                                         'E05',
                                         'E06',
                                         'E07',
                                         'E07',
                                         'E09') THEN
                'G01_30.3.B.2016' -- 境内证券业金融机构
             END FINA_TYP,
             SUM(T1.BALANCE * U.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_ACCT_FUND_MMFUND T1
        LEFT JOIN (SELECT A.*,
                          ROW_NUMBER() OVER(PARTITION BY A.TYSHXYDM ORDER BY A.ECIF_CUST_ID) RN
                     FROM SMTMODS_L_CUST_BILL_TY A
                    WHERE A.DATA_DATE = I_DATADATE) T2
          ON T1.JYDSTYDM = T2.TYSHXYDM
         AND T2.RN = 1
         AND T2.FINA_CODE_NEW <> 'Z'
        LEFT JOIN SMTMODS_L_PUBL_RATE U
          ON T1.DATA_DATE = U.DATA_DATE
         AND T1.CURR_CD = U.BASIC_CCY
         AND U.FORWARD_CCY = 'CNY'
        LEFT JOIN (SELECT B.*,
                          ROW_NUMBER() OVER(PARTITION BY USCD ORDER BY CUST_ID) RN
                     FROM SMTMODS_L_CUST_EXTERNAL_INFO B
                    WHERE DATA_DATE = I_DATADATE
                      AND USCD IS NOT NULL) T3
          ON T1.JYDSTYDM = T3.USCD
         AND T3.RN = 1
        LEFT JOIN SMTMODS_L_CUST_C C --根据交易对手代码找ecif客户号,根据客户的行业类型区分金融机构分类，ecif取不到的在根据万德发行人信息表进行补充
          ON NVL(T2.ECIF_CUST_ID, T3.CUST_ID) = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
        LEFT JOIN (SELECT CC.*,
                          ROW_NUMBER() OVER(PARTITION BY CC.ID_NO ORDER BY CC.OPEN_DT DESC) RN
                     FROM SMTMODS_L_CUST_C CC
                    WHERE CC.DATA_DATE = I_DATADATE) CC
          ON T1.jydstydm = CC.ID_NO
         AND CC.RN = 1
       WHERE T1.DATA_DATE = I_DATADATE
         AND (T1.GL_ITEM_CODE LIKE '200301%')
         AND T1.BALANCE <> 0
         AND T1.CURR_CD <> 'CNY'
         AND T1.ORG_NUM IN ('009820', '009801', '009804') --20250902 常金磊 原009804口径存在问题，业务康立军确认口径与同业金融部一致
       GROUP BY T1.ORG_NUM,
                CASE
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6811',
                        'J6812',
                        'J6813',
                        'J6814',
                        'J6820',
                        'J6830',
                        'J6840',
                        'J6851',
                        'J6852',
                        'J6853',
                        'J6860',
                        'J6870',
                        'J6890') OR
                       T3.ORG_TYPE_SCLS IN ('F01',
                                            'F02',
                                            'F03',
                                            'F04',
                                            'F05',
                                            'F06',
                                            'F07',
                                            'F08',
                                            'F09',
                                            'F10') THEN
                   'G01_30.4.B.2016' -- 境内保险业金融机构
                  WHEN T3.ORG_TYPE_SCLS IN ('H01',
                                            'H02',
                                            'I',
                                            'I01',
                                            'I02',
                                            'I03',
                                            'I04',
                                            'I05',
                                            'I06',
                                            'I07',
                                            'I08',
                                            'I09') THEN
                   'G01_30.5.B.2016' -- 境内其他金融机构
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6622',
                        'J6623',
                        'J6624',
                        'J6629',
                        'J6631',
                        'J6632',
                        'J6634',
                        'J6635',
                        'J6636',
                        'J6911',
                        'J6950',
                        'J6991') OR
                       T3.ORG_TYPE_SCLS IN ('C01',
                                            'C0101',
                                            'C0102',
                                            'C0103',
                                            'C06',
                                            'C07',
                                            'C08',
                                            'C09',
                                            'C10',
                                            'C11',
                                            'D01',
                                            'D02',
                                            'D0201',
                                            'D0202',
                                            'D03',
                                            'D04',
                                            'D05',
                                            'D06',
                                            'D07') THEN
                   'G01_30.2.B.2016' -- 境内其他银行业金融机构
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) =
                       'J6621' OR
                       T3.ORG_TYPE_SCLS IN ('C02',
                                            'C03',
                                            'C04',
                                            'C05',
                                            'C12',
                                            'C1201',
                                            'C1202',
                                            'C13',
                                            'C14') THEN
                   'G01_30.1.B.2016' -- 境内商业银行
                  WHEN NVL(C.CORP_BUSINSESS_TYPE, CC.CORP_BUSINSESS_TYPE) IN
                       ('J6711',
                        'J6712',
                        'J6720',
                        'J6731',
                        'J6732',
                        'J6739',
                        'J6741',
                        'J6749',
                        'J6750',
                        'J6760') OR
                       T3.ORG_TYPE_SCLS IN ('E01',
                                            'E02',
                                            'E03',
                                            'E04',
                                            'E05',
                                            'E06',
                                            'E07',
                                            'E07',
                                            'E09') THEN
                   'G01_30.3.B.2016' -- 境内证券业金融机构
                END;
    COMMIT;

    ----取数逻辑机构009820，科目110103借方-110103贷方+110104借方-110104贷方+150102借方-150102贷方（期末数）
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             G.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             'G01_12.3.A' FINA_TYP,
             SUM((G.DEBIT_BAL - G.CREDIT_BAL) * B.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL G
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON G.DATA_DATE = B.DATA_DATE
         AND G.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD IN ('110103', '110104', '150102')
         AND G.ORG_NUM = '009820'
         AND G.CURR_CD = 'CNY'
       GROUP BY G.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             G.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             'G01_12.3.B' FINA_TYP,
             SUM((G.DEBIT_BAL - G.CREDIT_BAL) * B.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL G
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON G.DATA_DATE = B.DATA_DATE
         AND G.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD IN ('110103', '110104', '150102')
         AND G.ORG_NUM = '009820'
         AND G.CURR_CD <> 'CNY'
       GROUP BY G.ORG_NUM;
    COMMIT;

    ---同业拆入取机构009820.科目200301贷方期末数

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             G.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             'G01_30..A' FINA_TYP,
             SUM(G.CREDIT_BAL * B.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL G
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON G.DATA_DATE = B.DATA_DATE
         AND G.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD IN ('200301')
         AND G.ORG_NUM = '009820'
         AND G.CURR_CD = 'CNY'
       GROUP BY G.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             G.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             'G01_30..B' FINA_TYP,
             SUM(G.CREDIT_BAL * B.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL G
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON G.DATA_DATE = B.DATA_DATE
         AND G.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD IN ('200301')
         AND G.ORG_NUM = '009820'
         AND G.CURR_CD <> 'CNY'
       GROUP BY G.ORG_NUM;
    COMMIT;

    ---生息资产 机构009820，科目1011借方+1031借方+1302借方+15030105借方-15030305贷方-15030705贷方
    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             G.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             'G01_63.A.009820' FINA_TYP,
             SUM(CASE
                   WHEN G.ITEM_CD IN ('1011', '1031', '1302', '15030105') THEN
                    G.DEBIT_BAL
                   WHEN G.ITEM_CD IN ('15030305', '15030705') THEN
                    G.CREDIT_BAL
                 END * B.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL G
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON G.DATA_DATE = B.DATA_DATE
         AND G.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD IN
             ('1011', '1031', '1302', '15030105', '15030305', '15030705')
         AND G.ORG_NUM = '009820'
         AND G.CURR_CD = 'CNY'
       GROUP BY G.ORG_NUM;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL
      (DATA_DATE, ORG_NUM, SYS_NAM, REP_NUM, ITEM_NUM, ITEM_VAL, FLAG)
      SELECT I_DATADATE AS DATA_DATE,
             G.ORG_NUM AS ORG_NUM,
             'CBRC' AS SYS_NAM,
             'G01' AS REP_NUM,
             'G01_63.B.009820' FINA_TYP,
             SUM(CASE
                   WHEN G.ITEM_CD IN ('1011', '1031', '1302', '15030105') THEN
                    G.DEBIT_BAL
                   WHEN G.ITEM_CD IN ('15030305', '15030705') THEN
                    G.CREDIT_BAL
                 END * B.CCY_RATE),
             '2' AS FLAG
        FROM SMTMODS_L_FINA_GL G
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON G.DATA_DATE = B.DATA_DATE
         AND G.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE G.DATA_DATE = I_DATADATE
         AND G.ITEM_CD IN
             ('1011', '1031', '1302', '15030105', '15030305', '15030705')
         AND G.ORG_NUM = '009820'
         AND G.CURR_CD <> 'CNY'
       GROUP BY G.ORG_NUM;
    COMMIT;    

    V_STEP_FLAG := V_STEP_FLAG+1;
    V_STEP_DESC := 'G01 逻辑处理完成';
    sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,V_ERRORCODE, V_STEP_DESC,II_DATADATE);

  END IF;

 

 DBMS_OUTPUT.PUT_LINE('O_STATUS=0');
DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=完成'); 
  ------------------------------------------------------------------------------------------------------
EXCEPTION
  WHEN OTHERS THEN
    V_ERRORCODE  := sqlcode();
    V_ERRORDESC  := sqlerrm();
    V_STEP_DESC  := '发生异常。详细信息为，' || TO_CHAR(V_ERRORCODE) ||SUBSTR(V_ERRORDESC, 1, 280);
    V_STEP_FLAG  := -1;
   
 
    --记录异常信息
     SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
    ROLLBACK;
 
END proc_cbrc_idx2_g01;
