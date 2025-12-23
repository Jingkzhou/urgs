CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_idx2_g5306(II_DATADATE IN STRING --跑批日期
                                               ) IS
  /******************************
  @AUTHOR:
  @CREATE-DATE:20220228
  @DESCRIPTION:G5306
 --需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-27,修改人：石雨,提出人：王曦若 ,修改内容：调整代理国库业务会计科目
 
目标表：CBRC_A_REPT_ITEM_VAL
码值表：CBRC_L_POORHOUSEHOLD
视图表：CBRC_G53_JG_VIEW
     SMTMODS_V_PUB_IDX_CK_GTGSHDQ
     SMTMODS_V_PUB_IDX_CK_GTGSHHQ
     SMTMODS_V_PUB_IDX_CK_GTGSHTZ
     SMTMODS_V_PUB_IDX_FINA_GL
集市表：SMTMODS_L_ACCT_DEPOSIT
     SMTMODS_L_ACCT_LOAN
     SMTMODS_L_CUST_ALL
     SMTMODS_L_CUST_C
     SMTMODS_L_PUBL_RATE



  *******************************/
  V_SCHEMA    VARCHAR2(30); --当前存储过程所属的模式名
  V_PROCEDURE VARCHAR(30); --当前储存过程名称
  V_TAB_NAME  VARCHAR(30); --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC VARCHAR(4000); --任务描述
  V_STEP_FLAG INTEGER; --任务执行状态标识
  V_ERRORCODE VARCHAR(20); --错误编码
  V_ERRORDESC VARCHAR(280); --错误内容
  V_PER_NUM   VARCHAR(30); --报表编号
  II_STATUS   INTEGER DEFAULT 0; --断点续跑时,用于识别存储过程的是否跳过1--跳过 0--不跳过
  V_SYSTEM    VARCHAR2(30);
  
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

    V_PER_NUM  := 'G53_6';
    V_TAB_NAME := 'G53_6';
    I_DATADATE := II_DATADATE;
    V_SYSTEM   := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_IDX2_G5306');

    -----------------------------------------------------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    DELETE FROM CBRC_A_REPT_ITEM_VAL
     WHERE DATA_DATE = I_DATADATE
       AND REP_NUM = V_PER_NUM
       AND SYS_NAM = 'CBRC'
       AND FLAG = '2';
    COMMIT;

 

    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);

    -------------------------------1.1县域地区,2.1城市地区  各项存款--------------------------

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '县域地区,城市地区各项存款  逻辑处理开始';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             CASE
               WHEN A.LX = '县辖' AND SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN
                'G53_6.1.1.G'
               WHEN A.LX = '县辖' AND
                    SUBSTR(T.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                'G53_6.1.1.H'
               WHEN (A.LX = '市辖' OR LX IS NULL) AND
                    SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN
                'G53_6.2.1.G'
               WHEN (A.LX = '市辖' OR LX IS NULL) AND
                    SUBSTR(T.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                'G53_6.2.1.H'
             END AS ITEM_NUM, --指标号
             --SUM(T.CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标号
             --2014科目取借-贷 20230217 shiyu
             SUM(CASE
                   WHEN T.ITEM_CD = '2014' THEN
                    (T.CREDIT_BAL - T.DEBIT_BAL) * B.CCY_RATE

                   ELSE
                    T.CREDIT_BAL * B.CCY_RATE
                 END) AS ITEM_VAL, --指标号
             '2' AS FLAG
        FROM SMTMODS_V_PUB_IDX_FINA_GL T --20221025  解决总账添加网点后  数据翻倍问题
        LEFT JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) A
          ON T.ORG_NUM = BANK_REL
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM NOT LIKE '%0000'
         AND T.ITEM_CD IN ('20110201',
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
                           '2013',
                           '2014',
                           '20110114',
                           '20110115',
                           '20110209',
                           '20110210',
                           '20110110',
                           '20110208',
                           '20110113',
                           '201107',
                           ----    需求编号：JLBA202504180011_关于吉林银行交易级总账系统调整代理国库业务会计科目及核算规则的需求 上线日期：2025-05-13,修改人：石雨,提出人：王曦若 ,修改内容：调整代理国库业务会计科目
                           '2010' ,   --国库定期存款
                           '20110207',
                           '20110112',
                           '20120106',
                           '20120204'
                            ,'22410101','20110301','20110302','20110303','22410102','20080101','20090101'--[JLBA202507210012][石雨][修改内容：修改内容：224101久悬未取款属于活期存款、201103（财政性存款）调整为 一般单位活期存款]
                           ) --同G01,61各项存款
       GROUP BY ORG_NUM,
                CASE
                  WHEN A.LX = '县辖' AND
                       SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN
                   'G53_6.1.1.G'
                  WHEN A.LX = '县辖' AND
                       SUBSTR(T.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                   'G53_6.1.1.H'
                  WHEN (A.LX = '市辖' OR LX IS NULL) AND
                       SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN
                   'G53_6.2.1.G'
                  WHEN (A.LX = '市辖' OR LX IS NULL) AND
                       SUBSTR(T.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                   'G53_6.2.1.H'
                END;

    COMMIT;

    -------------------------------1.1.1县域地区,2.1.1城市地区储蓄存款----------------------------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '县域地区储蓄存款  逻辑处理开始';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             ITEM_NUM AS ITEM_NUM, --指标号
             sum(ITEM_VAL) AS ITEM_VAL, --指标值（数值型）
             '2' AS FLAG --标志位
        FROM (SELECT I_DATADATE AS DATA_DATE, --数据日期
                     CASE
                       WHEN T.ORG_NUM LIKE '0601%' THEN
                        '060300'
                       WHEN SUBSTR(T.ORG_NUM, 3, 2) LIKE '98' THEN
                        T.ORG_NUM
                       ELSE
                        SUBSTR(T.ORG_NUM, 0, 4) || '00'
                     END AS ORG_NUM, --机构号
                     'CBRC' AS SYS_NAM, --模块简称
                     'G53_6' AS REP_NUM, --报表编号
                     CASE
                       WHEN LX = '县辖' AND
                            SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                        'G53_6.1.1.1.G'
                       WHEN LX = '县辖' AND
                            SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN
                        'G53_6.1.1.1.H'
                       WHEN (LX = '市辖' OR LX IS NULL) AND
                            SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN
                        'G53_6.2.1.1.G'
                       WHEN (LX = '市辖' OR LX IS NULL) AND
                            SUBSTR(T.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                        'G53_6.2.1.1.H'
                     END AS ITEM_NUM, --指标号
                     SUM(CREDIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标号
                     '2' AS FLAG
                FROM SMTMODS_V_PUB_IDX_FINA_GL T --20221025  解决总账添加网点后  数据翻倍问题
                LEFT JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) A
                  ON case
                       when t.org_num like '0601%' then
                        '060300'
                       when SUBSTR(T.ORG_NUM, 3, 2) like '98' then
                        t.org_num
                       else
                        SUBSTR(T.ORG_NUM, 0, 4) || '00'
                     end = A.BANK_REL
               INNER JOIN SMTMODS_L_PUBL_RATE B
                  ON T.DATA_DATE = B.DATA_DATE
                 AND T.CURR_CD = B.BASIC_CCY
                 AND B.FORWARD_CCY = 'CNY'
               WHERE T.DATA_DATE = I_DATADATE
                 AND T.ITEM_CD IN ('20110110',
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
                                   '20110113' /*, '201_13'*/
                                    ,'22410102'  --[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
                                   )
                 AND T.ORG_NUM NOT LIKE '%0000'
               GROUP BY CASE
                          WHEN T.ORG_NUM LIKE '0601%' THEN
                           '060300'
                          WHEN SUBSTR(T.ORG_NUM, 3, 2) LIKE '98' THEN
                           T.ORG_NUM
                          ELSE
                           SUBSTR(T.ORG_NUM, 0, 4) || '00'
                        END,
                        CASE
                          WHEN LX = '县辖' AND
                               SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                           'G53_6.1.1.1.G'
                          WHEN LX = '县辖' AND
                               SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN
                           'G53_6.1.1.1.H'
                          WHEN (LX = '市辖' OR LX IS NULL) AND
                               SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN
                           'G53_6.2.1.1.G'
                          WHEN (LX = '市辖' OR LX IS NULL) AND
                               SUBSTR(T.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                           'G53_6.2.1.1.H'
                        END) TEMP
       GROUP BY TEMP.ORG_NUM, TEMP.ITEM_NUM;
    COMMIT;

    
    INSERT INTO CBRC_A_REPT_ITEM_VAL  --新增个体工商户部分 lfz 20220614
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             --SUBSTR(ORG_NUM, 0, 4) || '00' AS ORG_NUM, --机构号
             CASE
               WHEN ORG_NUM LIKE '0601%' THEN
                '060300'
               WHEN SUBSTR(ORG_NUM, 3, 2) LIKE '98' THEN
                ORG_NUM
               ELSE
                SUBSTR(ORG_NUM, 0, 4) || '00'
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             CASE
               WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                'G53_6.1.1.1.G'
               WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN
                'G53_6.1.1.1.H'
               WHEN (LX = '市辖' OR LX IS NULL) AND
                    SUBSTR(A.ORG_NUM, 0, 2) IN ('10', '11') THEN
                'G53_6.2.1.1.G'
               WHEN (LX = '市辖' OR LX IS NULL) AND
                    SUBSTR(A.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                'G53_6.2.1.1.H'
             END AS ITEM_NUM, --指标号
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL, --指标值（数值型）
             '2' AS FLAG --标志位
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHHQ A --个体工商户活期存款
        LEFT JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) C
      --ON SUBSTR(A.ORG_NUM, 0, 4) = SUBSTR(C.BANK_REL, 0, 4)
          ON case
               when A.org_num like '0601%' then
                '060300'
               when SUBSTR(A.ORG_NUM, 3, 2) like '98' then
                A.org_num
               else
                SUBSTR(A.ORG_NUM, 0, 4) || '00'
             end = C.BANK_REL
       WHERE A.DATA_DATE = I_DATADATE
            AND GL_ITEM_CODE <> '20110209' --alter by 20250318 剔除个人公积金部分
       GROUP BY CASE
                  WHEN ORG_NUM LIKE '0601%' THEN
                   '060300'
                  WHEN SUBSTR(ORG_NUM, 3, 2) LIKE '98' THEN
                   ORG_NUM
                  ELSE
                   SUBSTR(ORG_NUM, 0, 4) || '00'
                END,
                CASE
                  WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                   'G53_6.1.1.1.G'
                  WHEN LX = '县辖' AND
                       SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN
                   'G53_6.1.1.1.H'
                  WHEN (LX = '市辖' OR LX IS NULL) AND
                       SUBSTR(A.ORG_NUM, 0, 2) IN ('10', '11') THEN
                   'G53_6.2.1.1.G'
                  WHEN (LX = '市辖' OR LX IS NULL) AND
                       SUBSTR(A.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                   'G53_6.2.1.1.H'
                END;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL  --新增个体工商户部分 lfz 20220614
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             --SUBSTR(ORG_NUM, 0, 4) || '00' AS ORG_NUM, --机构号
             CASE
               WHEN ORG_NUM LIKE '0601%' THEN
                '060300'
               WHEN SUBSTR(ORG_NUM, 3, 2) LIKE '98' THEN
                ORG_NUM
               ELSE
                SUBSTR(ORG_NUM, 0, 4) || '00'
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             CASE
               WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                'G53_6.1.1.1.G'
               WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN
                'G53_6.1.1.1.H'
               WHEN (LX = '市辖' OR LX IS NULL) AND
                    SUBSTR(A.ORG_NUM, 0, 2) IN ('10', '11') THEN
                'G53_6.2.1.1.G'
               WHEN (LX = '市辖' OR LX IS NULL) AND
                    SUBSTR(A.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                'G53_6.2.1.1.H'
             END AS ITEM_NUM, --指标号
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL, --指标值（数值型）
             '2' AS FLAG --标志位
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHDQ A --个体工商户定期存款
        LEFT JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) C
      --ON SUBSTR(A.ORG_NUM, 0, 4) = SUBSTR(C.BANK_REL, 0, 4)
          ON case
               when A.org_num like '0601%' then
                '060300'
               when SUBSTR(A.ORG_NUM, 3, 2) like '98' then
                A.org_num
               else
                SUBSTR(A.ORG_NUM, 0, 4) || '00'
             end = C.BANK_REL
       WHERE A.DATA_DATE = I_DATADATE
        and a.gl_item_code <> '20110210' --剔除单位定期保证金存款  --alter by shiyu  20250318
       GROUP BY CASE
                  WHEN ORG_NUM LIKE '0601%' THEN
                   '060300'
                  WHEN SUBSTR(ORG_NUM, 3, 2) LIKE '98' THEN
                   ORG_NUM
                  ELSE
                   SUBSTR(ORG_NUM, 0, 4) || '00'
                END,
                CASE
                  WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                   'G53_6.1.1.1.G'
                  WHEN LX = '县辖' AND
                       SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN
                   'G53_6.1.1.1.H'
                  WHEN (LX = '市辖' OR LX IS NULL) AND
                       SUBSTR(A.ORG_NUM, 0, 2) IN ('10', '11') THEN
                   'G53_6.2.1.1.G'
                  WHEN (LX = '市辖' OR LX IS NULL) AND
                       SUBSTR(A.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                   'G53_6.2.1.1.H'
                END;
    COMMIT;

    INSERT INTO CBRC_A_REPT_ITEM_VAL  --新增个体工商户部分 lfz 20220614
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             --SUBSTR(ORG_NUM, 0, 4) || '00' AS ORG_NUM, --机构号
             CASE
               WHEN ORG_NUM LIKE '0601%' THEN
                '060300'
               WHEN SUBSTR(ORG_NUM, 3, 2) LIKE '98' THEN
                ORG_NUM
               ELSE
                SUBSTR(ORG_NUM, 0, 4) || '00'
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             CASE
               WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                'G53_6.1.1.1.G'
               WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN
                'G53_6.1.1.1.H'
               WHEN (LX = '市辖' OR LX IS NULL) AND
                    SUBSTR(A.ORG_NUM, 0, 2) IN ('10', '11') THEN
                'G53_6.2.1.1.G'
               WHEN (LX = '市辖' OR LX IS NULL) AND
                    SUBSTR(A.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                'G53_6.2.1.1.H'
             END AS ITEM_NUM, --指标号
             SUM(ACCT_BALANCE_RMB) AS ITEM_VAL, --指标值（数值型）
             '2' AS FLAG --标志位
        FROM SMTMODS_V_PUB_IDX_CK_GTGSHTZ A --个体工商户通知存款
        LEFT JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) C
      --ON SUBSTR(A.ORG_NUM, 0, 4) = SUBSTR(C.BANK_REL, 0, 4)
          ON case
               when A.org_num like '0601%' then
                '060300'
               when SUBSTR(A.ORG_NUM, 3, 2) like '98' then
                A.org_num
               else
                SUBSTR(A.ORG_NUM, 0, 4) || '00'
             end = C.BANK_REL
       WHERE A.DATA_DATE = I_DATADATE
       GROUP BY CASE
                  WHEN ORG_NUM LIKE '0601%' THEN
                   '060300'
                  WHEN SUBSTR(ORG_NUM, 3, 2) LIKE '98' THEN
                   ORG_NUM
                  ELSE
                   SUBSTR(ORG_NUM, 0, 4) || '00'
                END,
                CASE
                  WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                   'G53_6.1.1.1.G'
                  WHEN LX = '县辖' AND
                       SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN
                   'G53_6.1.1.1.H'
                  WHEN (LX = '市辖' OR LX IS NULL) AND
                       SUBSTR(A.ORG_NUM, 0, 2) IN ('10', '11') THEN
                   'G53_6.2.1.1.G'
                  WHEN (LX = '市辖' OR LX IS NULL) AND
                       SUBSTR(A.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                   'G53_6.2.1.1.H'
                END;
    COMMIT;
    
    
      --[JLBA202507210012][石雨][修改内容：224101久悬未取款属于活期存款、201103（财政性存款）调整为 一般单位活期存款]
     INSERT INTO CBRC_A_REPT_ITEM_VAL  --新增个体工商户部分 lfz 20220614
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             --SUBSTR(ORG_NUM, 0, 4) || '00' AS ORG_NUM, --机构号
             CASE
               WHEN T.ORG_NUM LIKE '0601%' THEN
                '060300'
               WHEN SUBSTR(T.ORG_NUM, 3, 2) LIKE '98' THEN
                T.ORG_NUM
               ELSE
                SUBSTR(T.ORG_NUM, 0, 4) || '00'
             END AS ORG_NUM,
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             CASE
               WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                'G53_6.1.1.1.G'
               WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN
                'G53_6.1.1.1.H'
               WHEN (LX = '市辖' OR LX IS NULL) AND
                    SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN
                'G53_6.2.1.1.G'
               WHEN (LX = '市辖' OR LX IS NULL) AND
                    SUBSTR(T.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                'G53_6.2.1.1.H'
             END AS ITEM_NUM, --指标号
    SUM(T.ACCT_BALANCE * B.CCY_RATE)   AS ITEM_VAL,
    '2' AS FLAG
     from SMTMODS_L_ACCT_DEPOSIT T
    INNER JOIN SMTMODS_L_CUST_C C
       ON T.DATA_DATE = C.DATA_DATE
      AND T.CUST_ID = C.CUST_ID
    INNER JOIN SMTMODS_L_PUBL_RATE B --汇率表
       ON T.DATA_DATE = B.DATA_DATE
      AND T.CURR_CD = B.BASIC_CCY
      AND B.FORWARD_CCY = 'CNY' --折人民币
      LEFT JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) C1
      --ON SUBSTR(A.ORG_NUM, 0, 4) = SUBSTR(C.BANK_REL, 0, 4)
          ON case
               when T.org_num like '0601%' then
                '060300'
               when SUBSTR(T.ORG_NUM, 3, 2) like '98' then
                T.org_num
               else
                SUBSTR(T.ORG_NUM, 0, 4) || '00'
             end = C1.BANK_REL
    where c.deposit_custtype in ('13', '14')
      and t.gl_item_code IN ('20110301', '20110302', '20110303', '22410101','20080101','20090101') --201104 一般单位活期  22410101单位久悬未取款
      AND T.ACCT_BALANCE > 0
      AND T.DATA_DATE = I_DATADATE
    GROUP BY CASE
               WHEN T.ORG_NUM LIKE '0601%' THEN
                '060300'
               WHEN SUBSTR(T.ORG_NUM, 3, 2) LIKE '98' THEN
                T.ORG_NUM
               ELSE
                SUBSTR(T.ORG_NUM, 0, 4) || '00'
             END,CASE
               WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                'G53_6.1.1.1.G'
               WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN
                'G53_6.1.1.1.H'
               WHEN (LX = '市辖' OR LX IS NULL) AND
                    SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN
                'G53_6.2.1.1.G'
               WHEN (LX = '市辖' OR LX IS NULL) AND
                    SUBSTR(T.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                'G53_6.2.1.1.H'
             END;
    
    COMMIT;
    

    -------------------------------1.1.1.1其中：已脱贫人口存款-----------------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '已脱贫人口存款 逻辑处理开始';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.BANK_REL AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G53_6' AS REP_NUM, --报表编号
       CASE
         WHEN SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN
          'G53_6.1.1.1.1.G'
         ELSE
          'G53_6.1.1.1.1.H'
       END AS ITEM_NUM, --指标号
       SUM(ACCT_BALANCE * CCY_RATE) AS ITEM_VAL, --指标值（数值型）
       '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_DEPOSIT T
       INNER JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) A
      --ON SUBSTR(T.ORG_NUM, 0, 4) = SUBSTR(A.BANK_REL, 0, 4)
          ON case
               when t.org_num like '0601%' then
                '060300'
               when SUBSTR(T.ORG_NUM, 3, 2) like '98' then
                t.org_num
               else
                SUBSTR(T.ORG_NUM, 0, 4) || '00'
             end = A.BANK_REL
         AND LX = '县辖'
       INNER JOIN SMTMODS_L_CUST_ALL C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       INNER JOIN CBRC_L_POORHOUSEHOLD P --已脱贫人口名单
          ON C.ID_NO = P.COL_12
         and p.path like 'D:\zjk\贫困户名录%'
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'

       WHERE T.DATA_DATE = I_DATADATE
         AND (T.GL_ITEM_CODE IN ('20110110',
                                 '20110101',
                                 '20110102',
                                 '20110103',
                                 '20110104',
                                 '20110105',
                                 '20110106',
                                 '20110107',
                                 '20110108',
                                 '20110109',
                                 '20110111'
                                  ,'22410102' --[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
                                 ) OR
             T.GL_ITEM_CODE IN ('20110112', '20110113')) --储蓄存款
       GROUP BY A.BANK_REL,
                CASE
                  WHEN SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN
                   'G53_6.1.1.1.1.G'
                  ELSE
                   'G53_6.1.1.1.1.H'
                END;
    COMMIT;

    --------------------------------------------1.1.1.1.a已脱贫人口存款户数.境内小计

    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '已脱贫人口存款户数 逻辑处理开始';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.BANK_REL AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G53_6' AS REP_NUM, --报表编号
       'G53_6.1.1.1.1.a.AG' AS ITEM_NUM, --指标号
       COUNT(T.ACCT_NUM) AS ITEM_VAL, --指标值（数值型）
       '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_DEPOSIT T
       INNER JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) A
      --ON SUBSTR(T.ORG_NUM, 0, 4) = SUBSTR(A.BANK_REL, 0, 4)
          ON case
               when t.org_num like '0601%' then
                '060300'
               when SUBSTR(T.ORG_NUM, 3, 2) like '98' then
                t.org_num
               else
                SUBSTR(T.ORG_NUM, 0, 4) || '00'
             end = A.BANK_REL
         AND LX = '县辖'
       INNER JOIN SMTMODS_L_CUST_ALL C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       INNER JOIN CBRC_L_POORHOUSEHOLD P --已脱贫人口名单
          ON C.ID_NO = P.COL_12
         and p.path like 'D:\zjk\贫困户名录%'
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND (T.GL_ITEM_CODE IN ('20110110',
                                 '20110101',
                                 '20110102',
                                 '20110103',
                                 '20110104',
                                 '20110105',
                                 '20110106',
                                 '20110107',
                                 '20110108',
                                 '20110109',
                                 '20110111'
                                   ,'22410102' --[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
                                 ) OR
             T.GL_ITEM_CODE IN ('20110112', '20110113'))
       GROUP BY A.BANK_REL;
    COMMIT;

    -------------------------------1.1.1.2 其中：边缘易致贫人口存款
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '边缘易致贫人口存款 逻辑处理开始';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.BANK_REL AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G53_6' AS REP_NUM, --报表编号
       CASE
         WHEN SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
          'G53_6.1.1.1.2.G'
         ELSE
          'G53_6.1.1.1.2.H'
       END AS ITEM_NUM, --指标号
       sum(ACCT_BALANCE * B.CCY_RATE) AS ITEM_VAL, --指标值（数值型）
       '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_DEPOSIT T
       INNER JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) A
      --ON SUBSTR(T.ORG_NUM, 0, 4) = SUBSTR(A.BANK_REL, 0, 4)
          ON case
               when t.org_num like '0601%' then
                '060300'
               when SUBSTR(T.ORG_NUM, 3, 2) like '98' then
                t.org_num
               else
                SUBSTR(T.ORG_NUM, 0, 4) || '00'
             end = A.BANK_REL
         AND LX = '县辖'
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       INNER JOIN SMTMODS_L_CUST_ALL C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       INNER JOIN CBRC_L_POORHOUSEHOLD p --边缘易致贫
          ON C.ID_NO = P.COL_11
         and p.path like 'D:\zjk\编外户\%'
       WHERE T.DATA_DATE = I_DATADATE
         AND (T.GL_ITEM_CODE IN ('20110110',
                                 '20110101',
                                 '20110102',
                                 '20110103',
                                 '20110104',
                                 '20110105',
                                 '20110106',
                                 '20110107',
                                 '20110108',
                                 '20110109',
                                 '20110111'
                                ,'22410102' --[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
                                 ) OR
             T.GL_ITEM_CODE IN ('20110112', '20110113'))
       GROUP BY A.BANK_REL,
                CASE
                  WHEN SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                   'G53_6.1.1.1.2.G'
                  ELSE
                   'G53_6.1.1.1.2.H'
                END;
    COMMIT;

    ------------------------1.1.1.2 a 边缘易致贫人口存款户数-------------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '边缘易致贫人口存款户数 逻辑处理开始';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.BANK_REL AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G53_6' AS REP_NUM, --报表编号
       'G53_6.1.1.1.2.a.AG' AS ITEM_NUM, --指标号
       COUNT(T.ACCT_NUM) AS ITEM_VAL, --指标值（数值型）
       '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_DEPOSIT T
       INNER JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) A
      --ON SUBSTR(T.ORG_NUM, 0, 4) = SUBSTR(A.BANK_REL, 0, 4)
          on case
               when t.org_num like '0601%' then
                '060300'
               when SUBSTR(T.ORG_NUM, 3, 2) like '98' then
                t.org_num
               else
                SUBSTR(T.ORG_NUM, 0, 4) || '00'
             end = A.BANK_REL
         AND LX = '县辖'
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       INNER JOIN SMTMODS_L_CUST_ALL C
          ON T.CUST_ID = C.CUST_ID
         AND C.DATA_DATE = I_DATADATE
       INNER JOIN CBRC_L_POORHOUSEHOLD p --边缘易致贫
          ON C.ID_NO = P.COL_11
         and p.path like 'D:\zjk\编外户\%'
       WHERE T.DATA_DATE = I_DATADATE
         AND (T.GL_ITEM_CODE IN ('20110110',
                                 '20110101',
                                 '20110102',
                                 '20110103',
                                 '20110104',
                                 '20110105',
                                 '20110106',
                                 '20110107',
                                 '20110108',
                                 '20110109',
                                 '20110111'
                                   ,'22410102' --[JLBA202507210012][石雨][修改内容：22410102个人久悬未取款]
                                 ) OR
             T.GL_ITEM_CODE IN ('20110112', '20110113'))
       GROUP BY A.BANK_REL;
    COMMIT;

    ---------------------------1.1.2已脱贫县域存款------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '已脱贫县域存款 逻辑处理开始';

    INSERT 
    INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G53_6' AS REP_NUM, --报表编号
       'G53_6.1.1.2.H' AS ITEM_NUM, --指标号
       SUM(ACCT_BALANCE * B.CCY_RATE) AS ITEM_VAL, --指标号
       '2' AS FLAG
        FROM SMTMODS_L_ACCT_DEPOSIT T
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
            /*AND (SUBSTR(T.GL_ITEM_CODE,1,3) IN ('203', '211', '215', '217')
            OR GL_ITEM_CODE IN ('21902', '22002', '201_13'))*/
         AND ACCT_BALANCE > 0
         AND SUBSTR(T.ORG_NUM, 1, 4) IN ('0805', '0806', '0913') --已脱贫县包括：大安县,靖宇县,通榆县
       GROUP BY ORG_NUM;

    COMMIT;

    ------------------------------1.2县域,2.2城市地区 各项贷款---------------------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '县域,城市地区 各项贷款 逻辑处理开始';

    INSERT 
    INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       ORG_NUM AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G53_6' AS REP_NUM, --报表编号
       CASE
         WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
          'G53_6.1.2.G'
         WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN
          'G53_6.1.2.H'
         WHEN (LX = '市辖' OR LX IS NULL) AND
              SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN
          'G53_6.2.2.G'
         WHEN (LX = '市辖' OR LX IS NULL) AND
              SUBSTR(T.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
          'G53_6.2.2.H'
       END AS ITEM_NUM, --指标号

       SUM(T.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值（数值型）
       '2' AS FLAG --标志位
      --FROM L_FINA_GL T
        FROM SMTMODS_V_PUB_IDX_FINA_GL T --20221025  解决总账添加网点后  数据翻倍问题
        LEFT JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) A
          ON T.ORG_NUM = A.BANK_REL
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM NOT LIKE '%0000'
         AND T.ITEM_CD IN
             ('1303',
              '1305',
              '1306',
              /* '1290403',*/
              '13010401',
              '13010403',
              '13010405',
              '13010407',
              '13010501',
              '13010503',
              '13010505',
              '13010507',
              /* '1290701',
              '1290703',*/
              '13010101',
              '13010103',
              '13010104',
              '13010106',
              '13010201',
              '13010203',
              '13010204',
              '13010206',
              '13010301',
              '13010303' /*,
                                                                                   '1290401'*/)

       GROUP BY ORG_NUM,
                CASE
                  WHEN LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                   'G53_6.1.2.G'
                  WHEN LX = '县辖' AND
                       SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN
                   'G53_6.1.2.H'
                  WHEN (LX = '市辖' OR LX IS NULL) AND
                       SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN
                   'G53_6.2.2.G'
                  WHEN (LX = '市辖' OR LX IS NULL) AND
                       SUBSTR(T.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN
                   'G53_6.2.2.H'
                END;
    COMMIT;
    -----------------1.2.1县域,2.2.1 城市地区 个人贷款------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '县域,城市地区 个人贷款 逻辑处理开始';

    --校验关系 [1.2.1AG]+[2.2.1AG]=G05__[1.A]个人贷款+G05__[2.A]个人经营性贷款 = 《G01_VII》[2.21.A]+ 《S63_III》[1.G]
    --普通贷款
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
    I_DATADATE AS DATA_DATE, -- 数据日期
    CASE 
        WHEN T.ORG_NUM LIKE '0601%' THEN '060300'
        WHEN SUBSTR(T.ORG_NUM, 3, 2) LIKE '98' THEN T.ORG_NUM
        ELSE SUBSTR(T.ORG_NUM, 0, 4) || '00' 
    END AS ORG_NUM,
    'CBRC' AS SYS_NAM, -- 模块简称
    'G53_6' AS REP_NUM, -- 报表编号
    CASE
        WHEN A.LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN 'G53_6.1.2.1.G'
        WHEN A.LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN 'G53_6.1.2.1.H'
        WHEN (A.LX = '市辖' OR A.LX IS NULL) AND SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN 'G53_6.2.2.1.G'
        WHEN (A.LX = '市辖' OR A.LX IS NULL) AND SUBSTR(T.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN 'G53_6.2.2.1.H'
    END AS ITEM_NUM, -- 指标号
    SUM(NVL(T.LOAN_ACCT_BAL, 0) * B.CCY_RATE) AS ITEM_VAL, -- 指标值（数值型）
    '2' AS FLAG -- 标志位
FROM 
    SMTMODS_L_ACCT_LOAN T
LEFT JOIN 
    (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) A
ON 
    CASE 
        WHEN T.ORG_NUM LIKE '0601%' THEN '060300'
        WHEN SUBSTR(T.ORG_NUM, 3, 2) LIKE '98' THEN T.ORG_NUM
        ELSE SUBSTR(T.ORG_NUM, 0, 4) || '00' 
    END = A.BANK_REL
LEFT JOIN 
    SMTMODS_L_PUBL_RATE B
ON 
    T.DATA_DATE = B.DATA_DATE
    AND T.CURR_CD = B.BASIC_CCY
    AND B.FORWARD_CCY = 'CNY'
WHERE 
    T.DATA_DATE = I_DATADATE
    AND T.ACCT_TYP LIKE '01%' -- 个人贷款
    AND T.CANCEL_FLG <> 'Y'
    AND T.LOAN_STOCKEN_DATE IS NULL -- add by haorui 20250311 JLBA202408200012 资产未转让
GROUP BY 
    CASE 
        WHEN T.ORG_NUM LIKE '0601%' THEN '060300'
        WHEN SUBSTR(T.ORG_NUM, 3, 2) LIKE '98' THEN T.ORG_NUM
        ELSE SUBSTR(T.ORG_NUM, 0, 4) || '00' 
    END,
    CASE
        WHEN A.LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN 'G53_6.1.2.1.G'
        WHEN A.LX = '县辖' AND SUBSTR(BANK_REL, 0, 2) NOT IN ('10', '11') THEN 'G53_6.1.2.1.H'
        WHEN (A.LX = '市辖' OR A.LX IS NULL) AND SUBSTR(T.ORG_NUM, 0, 2) IN ('10', '11') THEN 'G53_6.2.2.1.G'
        WHEN (A.LX = '市辖' OR A.LX IS NULL) AND SUBSTR(T.ORG_NUM, 0, 2) NOT IN ('10', '11') THEN 'G53_6.2.2.1.H'
    END;
    COMMIT;

    --信用卡贷款
    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             '009803' AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             'G53_6.1.2.1.H' AS ITEM_NUM, --指标号
             SUM(T.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值（数值型）
             '2' AS FLAG --标志位
      --FROM L_FINA_GL T
        FROM SMTMODS_V_PUB_IDX_FINA_GL T --20221025  解决总账添加网点后  数据翻倍问题
       INNER JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) A
          ON T.ORG_NUM = A.BANK_REL
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ITEM_CD IN ('130303', '130604')
         AND T.ORG_NUM = '009803';
    COMMIT;

    ---------------------------1.2.2已脱贫县域贷款------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '已脱贫县域贷款 逻辑处理开始';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             'G53_6.1.2.2.H' AS ITEM_NUM, --指标号
             SUM(T.DEBIT_BAL * B.CCY_RATE) AS ITEM_VAL, --指标值（数值型）
             '2' AS FLAG --标志位
      --FROM L_FINA_GL T
        FROM SMTMODS_V_PUB_IDX_FINA_GL T --20221025  解决总账添加网点后  数据翻倍问题
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND T.ORG_NUM IN ('080500', '080600', '091300') --大安县,靖宇县,通榆县
         AND T.ITEM_CD IN
             ('1303',
              '1305',
              '1306',
              /* '1290403',*/
              '13010401',
              '13010403',
              '13010405',
              '13010407',
              '13010501',
              '13010503',
              '13010505',
              '13010507',
              /* '1290701',
              '1290703',*/
              '13010101',
              '13010103',
              '13010104',
              '13010106',
              '13010201',
              '13010203',
              '13010204',
              '13010206',
              '13010301',
              '13010303' /*,
                                                                                   '1290401'*/)

       GROUP BY ORG_NUM;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '已脱贫县域贷款  逻辑处理完成';

    -------------------1.2.4县域农林牧渔业贷款-----------------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '县域农林牧渔业贷款 逻辑处理开始';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             B1.BANK_REL AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             CASE
               WHEN SUBSTR(b1.BANK_REL, 0, 2) IN ('10', '11') THEN 'G53_6.1.2.4.G'
               ELSE 'G53_6.1.2.4.H'
             END AS ITEM_NUM, --指标号
             SUM(NVL(T.LOAN_ACCT_BAL, 0) * B.CCY_RATE) AS ITEM_VAL, --指标值（数值型）
             '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) B1
          ON SUBSTR(T.ORG_NUM, 0, 4) = SUBSTR(B1.BANK_REL, 0, 4)
         AND LX = '县辖'
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE LOAN_PURPOSE_CD LIKE 'A%' --农林牧渔业
         AND (ACCT_TYP NOT LIKE '01%' OR ACCT_TYP LIKE '0102%') --对公贷款及个人经营性
         AND ACCT_TYP NOT LIKE '90%' --剔除委托贷款
         AND T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY B1.BANK_REL,
                CASE
                  WHEN SUBSTR(b1.BANK_REL, 0, 2) IN ('10', '11') THEN
                   'G53_6.1.2.4.G'
                  ELSE
                   'G53_6.1.2.4.H'
                END;

    COMMIT;

    ------------------1.2.5-县域制造业贷款---------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '县域制造业贷款- 逻辑处理开始';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             B1.BANK_REL AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             CASE
               WHEN SUBSTR(b1.BANK_REL, 0, 2) IN ('10', '11') THEN
                'G53_6.1.2.5.G'
               ELSE
                'G53_6.1.2.5.H'
             END AS ITEM_NUM, --指标号
             SUM(NVL(T.LOAN_ACCT_BAL, 0) * B.CCY_RATE) AS ITEM_VAL, --指标值（数值型）
             '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) B1
      --ON SUBSTR(T.ORG_NUM, 0, 4) = SUBSTR(B.BANK_REL, 0, 4)
          on case
               when t.org_num like '0601%' then
                '060300'
               when SUBSTR(T.ORG_NUM, 3, 2) like '98' then
                t.org_num
               else
                SUBSTR(T.ORG_NUM, 0, 4) || '00'
             end = b1.BANK_REL
         AND LX = '县辖'
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE LOAN_PURPOSE_CD LIKE 'C%' --制造业
         AND (ACCT_TYP NOT LIKE '01%' OR ACCT_TYP LIKE '0102%') --对公贷款及个人经营性
         AND ACCT_TYP NOT LIKE '90%' --剔除委托贷款
         AND T.DATA_DATE = I_DATADATE
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       GROUP BY B1.BANK_REL,CASE WHEN SUBSTR(b1.BANK_REL, 0, 2) IN('10', '11') THEN 'G53_6.1.2.5.G' ELSE 'G53_6.1.2.5.H' END;
    COMMIT;

    -------------------1.2.1.1 其中：已脱贫人口贷款----------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '已脱贫人口贷款 逻辑处理开始';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.BANK_REL AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G53_6' AS REP_NUM, --报表编号
       CASE
         WHEN SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
          'G53_6.1.2.1.1.G'
         ELSE
          'G53_6.1.2.1.1.H'
       END AS ITEM_NUM, --指标号
       SUM(NVL(T.LOAN_ACCT_BAL, 0) * B.CCY_RATE) AS ITEM_VAL, --指标值（数值型）
       '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL L
          ON T.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       INNER JOIN CBRC_L_POORHOUSEHOLD P --已脱贫人口名单
          ON L.ID_NO = P.COL_12
         and p.path like 'D:\zjk\贫困户名录%'
       INNER JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) A
          ON case
               when t.org_num like '0601%' then
                '060300'
               when SUBSTR(T.ORG_NUM, 3, 2) like '98' then
                t.org_num
               else
                SUBSTR(T.ORG_NUM, 0, 4) || '00'
             end = a.BANK_REL
         AND LX = '县辖'
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY A.BANK_REL,
                CASE
                  WHEN SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                   'G53_6.1.2.1.1.G'
                  ELSE
                   'G53_6.1.2.1.1.H'
                END;

    COMMIT;

    ------------------- 1.2.1.1.a 已脱贫人口贷款户数----------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '已脱贫人口贷款户数 逻辑处理开始';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 

       I_DATADATE AS DATA_DATE, --数据日期
       A.BANK_REL AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G53_6' AS REP_NUM, --报表编号
       'G53_6.1.2.1.1.a.AG' AS ITEM_NUM, --指标号
       COUNT(T.LOAN_NUM) AS ITEM_VAL, --指标值（数值型）
       '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL L
          ON T.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       INNER JOIN CBRC_L_POORHOUSEHOLD P --已脱贫人口名单
          ON L.ID_NO = P.COL_12
         and p.path like 'D:\zjk\贫困户名录%'
       INNER JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) A
      --ON SUBSTR(T.ORG_NUM, 0, 4) = SUBSTR(A.BANK_REL, 0, 4)
          on case
               when t.org_num like '0601%' then
                '060300'
               when SUBSTR(T.ORG_NUM, 3, 2) like '98' then
                t.org_num
               else
                SUBSTR(T.ORG_NUM, 0, 4) || '00'
             end = A.BANK_REL
         AND LX = '县辖'
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY A.BANK_REL;

    COMMIT;

    ------------------1.2.1.2 其中：边缘易致贫人口贷款---------   -------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := ' 边缘易致贫人口贷款 逻辑处理开始';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.BANK_REL AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G53_6' AS REP_NUM, --报表编号
       CASE
         WHEN SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
          'G53_6.1.2.1.2.G'
         ELSE
          'G53_6.1.2.1.2.H'
       END AS ITEM_NUM, --指标号
       SUM(NVL(T.LOAN_ACCT_BAL, 0) * B.CCY_RATE) AS ITEM_VAL, --指标值（数值型）
       '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL L
          ON T.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       INNER JOIN CBRC_L_POORHOUSEHOLD p --边缘易致贫
          ON L.ID_NO = P.COL_11
         and p.path like 'D:\zjk\编外户\%'
       INNER JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) A
          ON SUBSTR(T.ORG_NUM, 0, 4) = SUBSTR(A.BANK_REL, 0, 4)
         AND LX = '县辖'
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY A.BANK_REL,
                CASE
                  WHEN SUBSTR(BANK_REL, 0, 2) IN ('10', '11') THEN
                   'G53_6.1.2.1.2.G'
                  ELSE
                   'G53_6.1.2.1.2.H'
                END;
    COMMIT;

    ------------------1.2.1.2.a  边缘易致贫人口贷款户数---------   -------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := ' 边缘易致贫人口贷款户数 逻辑处理开始';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT 
       I_DATADATE AS DATA_DATE, --数据日期
       A.BANK_REL AS ORG_NUM, --机构号
       'CBRC' AS SYS_NAM, --模块简称
       'G53_6' AS REP_NUM, --报表编号
       'G53_6.1.2.1.2.a.AG' AS ITEM_NUM, --指标号
       COUNT(T.LOAN_NUM) AS ITEM_VAL, --指标值（数值型）
       '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_LOAN T
       INNER JOIN SMTMODS_L_CUST_ALL L
          ON T.CUST_ID = L.CUST_ID
         AND L.DATA_DATE = I_DATADATE
       INNER JOIN CBRC_L_POORHOUSEHOLD p --边缘易致贫
          ON L.ID_NO = P.COL_11
         and p.path like 'D:\zjk\编外户\%'
       INNER JOIN (SELECT DISTINCT BANK_REL, LX FROM CBRC_G53_JG_VIEW) A
          ON SUBSTR(T.ORG_NUM, 0, 4) = SUBSTR(A.BANK_REL, 0, 4)
         AND LX = '县辖'
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
       GROUP BY A.BANK_REL;
    COMMIT;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '边缘易致贫人口贷款户数  逻辑处理完成';

    ---------------------附注：3.1.1已脱贫地区贷款累放贷款额----------------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '已脱贫地区贷款累放贷款额';

    -- 新增附注部分 lfz 20220628

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             'G53_6.3.1.1.A' AS ITEM_NUM, --指标号
             SUM(A.DRAWDOWN_AMT * B.CCY_RATE) AS ITEM_VAL, --指标值（数值型）
             '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(ORG_NUM, 1, 4) IN ('0805', '0806', '0913')
         AND DRAWDOWN_DT BETWEEN to_char(TRUNC(DATE(I_DATADATE, 'yyyymmdd'), 'yyyy'),'yyyymmdd') AND  I_DATADATE
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND ACCT_TYP NOT LIKE '90%' --剔除委托贷款
       GROUP BY ORG_NUM;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '已脱贫地区贷款累放贷款额  逻辑处理完成';

    ---------------------附注：3.2.1已脱贫地区贷款累计年化利息收益----------------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '已脱贫地区贷款累计年化利息收益';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             'G53_6.3.2.1.A' AS ITEM_NUM, --指标号
             SUM((A.DRAWDOWN_AMT * B.CCY_RATE) * REAL_INT_RAT / 100) AS ITEM_VAL, --指标值（数值型）
             '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_LOAN A
       INNER JOIN SMTMODS_L_PUBL_RATE B
          ON A.DATA_DATE = B.DATA_DATE
         AND A.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE A.DATA_DATE = I_DATADATE
         AND SUBSTR(ORG_NUM, 1, 4) IN ('0805', '0806', '0913')
         AND DRAWDOWN_DT BETWEEN to_char(TRUNC(DATE(I_DATADATE, 'yyyymmdd'), 'yyyy'),'yyyymmdd') AND  I_DATADATE
         AND A.CANCEL_FLG <> 'Y'
         AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND ACCT_TYP NOT LIKE '90%' --剔除委托贷款
       GROUP BY ORG_NUM;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '已脱贫地区贷款累计年化利息收益  逻辑处理完成';

    ---------------------附注：3.3.1已脱贫地区农、林、牧、渔业贷款----------------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '已脱贫地区农、林、牧、渔业贷款';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             'G53_6.3.3.1.A' AS ITEM_NUM, --指标号
             SUM(NVL(T.LOAN_ACCT_BAL, 0) * B.CCY_RATE) AS ITEM_VAL, --指标值（数值型）
             '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND LOAN_PURPOSE_CD LIKE 'A%' --农林牧渔业
         AND SUBSTR(T.ORG_NUM, 1, 4) IN ('0805', '0806', '0913')
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND ACCT_TYP NOT LIKE '90%' --剔除委托贷款
       GROUP BY T.ORG_NUM;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '已脱贫地区农、林、牧、渔业贷款  逻辑处理完成';

    ---------------------附注：3.4.1已脱贫地区制造业贷款----------------------------
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '已脱贫地区农、林、牧、渔业贷款';

    INSERT INTO CBRC_A_REPT_ITEM_VAL 
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       SYS_NAM, --模块简称
       REP_NUM, --报表编号
       ITEM_NUM, --指标号
       ITEM_VAL, --指标值（数值型）
       FLAG --标志位
       )
      SELECT I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             'CBRC' AS SYS_NAM, --模块简称
             'G53_6' AS REP_NUM, --报表编号
             'G53_6.3.4.1.A' AS ITEM_NUM, --指标号
             SUM(NVL(T.LOAN_ACCT_BAL, 0) * B.CCY_RATE) AS ITEM_VAL, --指标值（数值型）
             '2' AS FLAG --标志位
        FROM SMTMODS_L_ACCT_LOAN T
        LEFT JOIN SMTMODS_L_PUBL_RATE B
          ON T.DATA_DATE = B.DATA_DATE
         AND T.CURR_CD = B.BASIC_CCY
         AND B.FORWARD_CCY = 'CNY'
       WHERE T.DATA_DATE = I_DATADATE
         AND LOAN_PURPOSE_CD LIKE 'C%' -- 制造业
         AND SUBSTR(T.ORG_NUM, 1, 4) IN ('0805', '0806', '0913')
         AND T.CANCEL_FLG <> 'Y'
         AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
         AND ACCT_TYP NOT LIKE '90%' --剔除委托贷款
       GROUP BY T.ORG_NUM;

    COMMIT;
    V_STEP_FLAG := 1;
    V_STEP_DESC := '已脱贫地区制造业贷款  逻辑处理完成';

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
   
END proc_cbrc_idx2_g5306