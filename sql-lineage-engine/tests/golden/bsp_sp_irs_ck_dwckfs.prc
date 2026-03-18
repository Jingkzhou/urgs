CREATE OR REPLACE PROCEDURE BSP_SP_IRS_CK_DWCKFS(IS_DATE     IN VARCHAR2,
                                                 OI_RETCODE  OUT INTEGER,
                                                 OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IE_CK_DWCKFS
  -- 用途:非同业单位存款发生额信息表（不含活期存款、协定存款）
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT
  --    MOD BY
  --需求编号：JLBA202504180011 上线日期：2025-05-27，修改人：蒿蕊，提出人：黄俊铭 修改原因：D1092取2005；D1095取2010；D1011取2008和2009；
  --需求编号：JLBA202507210012 上线日期：2025-12-11，修改人：蒿蕊，提出人：王铣   修改原因：增加201103科目，其中资产负债指标代码01020019归到D1094、01020015归到D1093、01020018归到D1091、201103科目下非01020019、01020015、01020018归到D1091
  --需求编号：数据维护单       上线日期：2025-12-17，修改人：蒿蕊  提出人：黄俊铭 修改原因：个体工商户判断优先以NGI客户类型为准，非NGI客户则根据柜面存款人类别判断
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE      NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT           VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
  VS_FIRST          VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  NUM               INTEGER;
  VS_YES_DATE       VARCHAR2(30);

BEGIN
  VS_TEXT      := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  VS_LAST_TEXT := TO_CHAR(LAST_DAY(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'),
                                              -1)),
                          'YYYYMMDD'); --上月月末
  VS_FIRST     := TO_CHAR(TO_DATE(SUBSTR(IS_DATE, 1, 6) || '01', 'YYYYMMDD'),
                          'YYYYMMDD'); --本月月初
  VS_YES_DATE  := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD');

  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IE_CK_DWCKFS';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------
  /*  --删除当天日志
   DELETE FROM RUN_STEP_LOG WHERE TAB_NAME = 'IE_CK_DWCKFS' AND TO_CHAR(RUN_TIME,'YYYYMMDD')=TO_CHAR(SYSDATE,'YYYYMMDD');
    COMMIT;
   --创建分区
   SELECT COUNT(1)
      INTO NUM
      FROM USER_TAB_PARTITIONS
     WHERE TABLE_NAME = 'IE_CK_DWCKFS'
       AND PARTITION_NAME = 'IE_CK_DWCKFS_' || IS_DATE;
  */
  --如果没有建立分区，则增加分区
  /*  IF (NUM = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE DATACORE.IE_CK_DWCKFS ADD PARTITION IE_CK_DWCKFS_' ||
                      IS_DATE || ' VALUES (' || IS_DATE || ')';
  END IF;

  EXECUTE IMMEDIATE 'ALTER TABLE DATACORE.IE_CK_DWCKFS TRUNCATE PARTITION IE_CK_DWCKFS_' ||
                    IS_DATE;


  INSERT INTO RUN_STEP_LOG VALUES (1, 'IE_CK_DWCKFS', '', SYSDATE);
  COMMIT;*/

  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_CK_DWCKFS_INC';
  --EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_CK_DWCKFS_INC_TMP1';
  EXECUTE IMMEDIATE 'ANALYZE  TABLE DATACORE_IE_CK_DWCKFS_INC COMPUTE STATISTICS';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_CK_DWCKFS_INC_TMP2';

  /* INSERT INTO DATACORE_IE_CK_DWCKFS_INC_TMP1
  SELECT DISTINCT CUST_ID
  FROM SMTMODS.L_CUST_P
  WHERE DATA_DATE =IS_DATE
  AND ORG_NUM NOT LIKE '0215%';
  COMMIT;
  INSERT INTO DATACORE_IE_CK_DWCKFS_INC_TMP1
  SELECT DISTINCT CUST_ID
  FROM SMTMODS.L_CUST_C
  WHERE DATA_DATE =IS_DATE
  AND ORG_NUM NOT LIKE '0215%';
  COMMIT;*/

  INSERT INTO DATACORE_IE_CK_DWCKFS_INC_TMP2
    (DATADATE, --数据日期
     ACCDEPCODE, --存款账户编码
     DEPAGRSEQNO, --存款序号
     CORPID, --内部机构号
     CUSTID, --客户号
     SERIALNO, --交易流水号
     TRANSACTIONDATE, --交易日期
     REALRATE, --实际利率
     BASERATE, --基准利率
     MONEYSYMB, --币种
     TRANSAMT, --发生金额
     TRANSCHANNEL, --交易渠道
     TRANSDIRECT, --交易方向
     AMTDEPFLG, --大小额标志
     CJRQ, --采集日期
     NBJGH, --内部机构号
     BIZ_LINE_ID, --业务条线
     DIFF_TYPE, --增量标识
     LAST_DATA_DATE, --上一数据时点
     MATUR_DATE, --到期日期
     ACCT_CLDATE, --销户日期
     GL_ITEM_CODE --科目号
     )
    SELECT /*+ USE_HASH(T,B,F,A,C) PARALLEL(8)*/
     VS_TEXT, --数据日期
     T.ACCOUNT_CODE, --存款账户编码
     B.DEPOSIT_NUM, --存款序号  C..100  存款吸收机构内部自行设置的，用于标识同一存款账户下不同笔存款的唯一编码。
     B.ORG_NUM, --内部机构号  C..30  金融机构自定义的唯一标识该笔业务经办机构（总行或分支机构）的内部编号。
     T.CUST_ID, --客户号  C..30  金融机构自定义的唯一标识该客户的内部编号。
     T.REFERENCE_NUM, --交易流水号  C..60  此笔交易在金融机构内部的唯一编码。
     VS_TEXT, --交易日期  C10  交易实际发生日期。                      --存在时点问题，将交易日期给到数据日期
     --CASE WHEN B.ACCT_TYPE = '0602' THEN B.INT_RATE
     --ELSE NVL(B.INT_RATE,0)+NVL(B.DEP_FLO_INT_RATE,0)+NVL(B.PROD_FLO_INT_RATE,0) END, --8基准利率  D10.5  交易发生时对应的最近一期LPR、存款基准利率、LIBOR、SHIBOR等基准利率值。
     --NVL(B.Base_Rate,0), --8基准利率  D10.5  交易发生时对应的最近一期LPR、存款基准利率、LIBOR、SHIBOR等基准利率值。
     --CASE WHEN B.ACCT_TYPE = '0602' THEN B.INT_RATE
     --ELSE NVL(B.INT_RATE,0)+NVL(B.DEP_FLO_INT_RATE,0)+NVL(B.PROD_FLO_INT_RATE,0) END AS REALRATE , --9实际利率  D10.5  交易发生时实际执行的年利率水平。
     --NVL(B.INT_RATE,0), --9实际利率  D10.5  交易发生时实际执行的年利率水平
     NVL(B.INT_RATE, 0), --8实际利率
     NVL(B.PBOC_BASE_RATE, 0), --9基准利率
     T.CURRENCY, --币种  C3  交易的币种。
     ABS(T.TRANS_AMT), --发生金额  D20.2  交易实际发生金额。
     DECODE(T.CHANNEL,
            '01',
            '01', --01：柜台
            '04',
            '02', --02：ATM机
            '02',
            '03', --03：网银
            '03',
            '04', --04：手机银行
            '99' --99：其他
            ), --交易渠道  C2  标识该笔交易的交易渠道，包括柜面、ATM机、网银、手机银行、电话交易、其他。
     CASE
       WHEN T.TRANS_INCOME_TYPE = '1' THEN
        '1'
       ELSE
        '0'
     END AS TRANSDIRECT, --交易方向  C1  用来标记该笔交易是转入（用1表示）还是转出（用0表示）。
     /*CASE
       WHEN T.CURRENCY <> 'CNY' AND T.RECEIPT_PAYMENT_TAG = '01' --币种为外币,交易方向为转入
            AND T.AMOUNT_USD >= '3000000' THEN
        'A' --大额存款
       WHEN T.CURRENCY <> 'CNY' AND T.RECEIPT_PAYMENT_TAG = '01' --币种为外币，交易方向为转入
            AND T.AMOUNT_USD < '3000000' THEN
        'B' --小额存款
       ELSE
        ''
     END AS ACCT_BALANCE_FLAG, --C1  指单笔存款发生额是否大于等于300万美元或其他等值外币。*/
     CASE
       WHEN T.CURRENCY <> 'CNY' AND T.TRANS_INCOME_TYPE = '1' AND
            T.TRANS_AMT * F.CCY_RATE >= 3000000 THEN
        'A'
       WHEN T.CURRENCY <> 'CNY' AND T.TRANS_INCOME_TYPE = '1' AND
            T.TRANS_AMT * F.CCY_RATE < 3000000 THEN
        'B'
     END AS AMTDEPFLG, --大小额标志
     IS_DATE CJRQ, --采集日期
     B.ORG_NUM NBJGH, --内部机构号
     '99' BIZ_LINE_ID, --业务条线
     '1', --增量标识
     TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD') ， --上一数据时点
     to_char(b.MATUR_DATE, 'YYYY-MM-DD'), --到期日期
     to_char(b.ACCT_CLDATE, 'YYYY-MM-DD'), --销户日期
     b.GL_ITEM_CODE --科目号
      FROM SMTMODS.L_TRAN_TX T
     INNER JOIN SMTMODS.L_ACCT_DEPOSIT B
        ON T.CUST_ID = B.CUST_ID
       AND T.ACCOUNT_CODE = B.ACCT_NUM
       AND T.DATA_DATE = B.DATA_DATE
          --AND B.ORG_NUM NOT LIKE '0215%'
       AND B.DEPOSIT_NUM = '1'
      LEFT JOIN SMTMODS.L_PUBL_RATE F --汇率表
        ON T.CURRENCY = F.BASIC_CCY
       AND T.TX_DT = F.CCY_DATE
       AND F.FORWARD_CCY = 'USD'
       AND F.CONVERT_TYP = 'M'
     INNER JOIN SMTMODS.L_CUST_C A
        ON A.CUST_ID = T.CUST_ID
       AND A.DATA_DATE = T.DATA_DATE
       AND (A.IS_NGI_CUST ='1' AND NVL(A.CUST_TYP,'0') <> '3' --个体工商户       --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]若是NGI客户标识则以NIG客户类型判断
	        OR NVL(A.IS_NGI_CUST,'0')='0' AND NVL(A.DEPOSIT_CUSTTYPE,'0') NOT IN ('13','14')
           )			                                              --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]非NGI客户通过存款人类型判断
    /*LEFT JOIN SMTMODS.L_EV_CORE_TXN_ENTRY_EVENT C   --剔除手续费
     ON T.KEY_TRANS_NO = C.EVENT_NO
    AND T.TRANS_AMT = C.TXN_AMT
    AND (CASE WHEN T.CD_TYPE = '1' THEN 'C' ELSE 'D' END) = C.DEBIT_OR_CRDT_INDEX*/
      LEFT JOIN SMTMODS.L_EV_CORE_TXN_ENTRY_EVENT C
        ON T.REFERENCE_NUM = C.EVENT_NO
       AND T.KEY_TRANS_NO = C.TXN_UNIQ_REF_NO
       AND (C.SUBJ_NO LIKE '6021%' OR C.SUBJ_NO LIKE '6421%' OR
           C.SUBJ_NO = '30050404') --20230103  剔除手续费科目
       AND T.DATA_DATE = C.DATA_DATE
     WHERE /*(B.GL_ITEM_CODE LIKE '20501%' OR B.GL_ITEM_CODE LIKE '20502%' OR
                   B.GL_ITEM_CODE LIKE '20503%' OR B.GL_ITEM_CODE LIKE '206%' OR
                   B.GL_ITEM_CODE LIKE '21901%' OR B.GL_ITEM_CODE LIKE '21903%' OR
                   B.GL_ITEM_CODE LIKE '202%' OR B.GL_ITEM_CODE LIKE '25102%')*/
     (B.GL_ITEM_CODE LIKE '20110202%' --单位一般定期存款
     OR B.GL_ITEM_CODE LIKE '20110203%' --单位大额可转让定期存单
     OR B.GL_ITEM_CODE LIKE '20110204%' --单位协议存款
     OR B.GL_ITEM_CODE LIKE '201107%' --国库定期存款
     OR B.GL_ITEM_CODE LIKE '20110207%' --单位结构性存款
     /*OR B.GL_ITEM_CODE LIKE '21903%'*/
     --OR B.GL_ITEM_CODE LIKE '20110205%'     --单位通知存款
     --OR B.GL_ITEM_CODE LIKE '20110209%'--单位活期保证金存款        --20221228  业务要求将活期保证金进行筛选
     OR B.GL_ITEM_CODE LIKE '20110210%' --单位定期保证金存款
     OR (B.GL_ITEM_CODE LIKE '20110205%' AND
     B.POC_INDEX_CODE NOT IN ('01020022', '01020023')) --单位通知存款
	  /*[2025-05-27] [蒿蕊] [JLBA202504180011] [黄俊铭]D1092：待结算财政款项取2005财政性存款 D1095增加取2010国库定期存款 D1011取2008和2009 START*/ 
	 OR B.GL_ITEM_CODE LIKE '2005%'     
	 OR B.GL_ITEM_CODE LIKE '2010%'    
	 OR B.GL_ITEM_CODE LIKE '2008%'
	 OR B.GL_ITEM_CODE LIKE '2009%'
	 /*[2025-05-27] [蒿蕊] [JLBA202504180011] [黄俊铭]D1092：待结算财政款项取2005财政性存款 D1095增加取2010国库定期存款 D1011取2008和2009 end */
	 OR B.GL_ITEM_CODE LIKE '201103%' --[2025-12-11] [蒿蕊] [JLBA202507210012] [黄俊铭]增加201103科目
	 )
     AND T.DATA_DATE = IS_DATE
     AND ABS(T.TRANS_AMT) > 0
     AND T.PAYMENT_PROPERTY IS NULL --交易过滤掉支付使用数据
     AND T.PAYMENT_ORDER IS NULL --交易过滤掉支付使用数据
     AND T.CURRENCY IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
     AND T.TRAN_STS <> 'B'
    --AND T.SUMMARY NOT IN ('受托支付转账')
     AND C.SUBJ_NO IS NULL
   AND T.TRAN_CODE_DESCRIBE NOT LIKE '%结息%' --add by haorui JLBF202412130001
   AND T.TRAN_CODE_DESCRIBE NOT LIKE '%利息%' --add by haorui JLBF202412130001
   ;

  COMMIT;

  INSERT INTO DATACORE_IE_CK_DWCKFS_INC_TMP2
    (DATADATE, --数据日期
     ACCDEPCODE, --存款账户编码
     DEPAGRSEQNO, --存款序号
     CORPID, --内部机构号
     CUSTID, --客户号
     SERIALNO, --交易流水号
     TRANSACTIONDATE, --交易日期
     REALRATE, --实际利率
     BASERATE, --基准利率
     MONEYSYMB, --币种
     TRANSAMT, --发生金额
     TRANSCHANNEL, --交易渠道
     TRANSDIRECT, --交易方向
     AMTDEPFLG, --大小额标志
     CJRQ, --采集日期
     NBJGH, --内部机构号
     BIZ_LINE_ID, --业务条线
     DIFF_TYPE, --增量标识
     LAST_DATA_DATE, --上一数据时点
     MATUR_DATE, --到期日期
     ACCT_CLDATE, --销户日期
     GL_ITEM_CODE --科目号
     )
    SELECT /*+ USE_HASH(T,B,F,A,C) PARALLEL(8)*/
     VS_TEXT, --数据日期
     T.ACCOUNT_CODE, --存款账户编码
     B.DEPOSIT_NUM, --存款序号  C..100  存款吸收机构内部自行设置的，用于标识同一存款账户下不同笔存款的唯一编码。
     B.ORG_NUM, --内部机构号  C..30  金融机构自定义的唯一标识该笔业务经办机构（总行或分支机构）的内部编号。
     T.CUST_ID, --客户号  C..30  金融机构自定义的唯一标识该客户的内部编号。
     T.REFERENCE_NUM, --交易流水号  C..60  此笔交易在金融机构内部的唯一编码。
     VS_TEXT, --交易日期  C10  交易实际发生日期。                      --存在时点问题，将交易日期给到数据日期
     --CASE WHEN B.ACCT_TYPE = '0602' THEN B.INT_RATE
     --ELSE NVL(B.INT_RATE,0)+NVL(B.DEP_FLO_INT_RATE,0)+NVL(B.PROD_FLO_INT_RATE,0) END, --8基准利率  D10.5  交易发生时对应的最近一期LPR、存款基准利率、LIBOR、SHIBOR等基准利率值。
     --NVL(B.Base_Rate,0), --8基准利率  D10.5  交易发生时对应的最近一期LPR、存款基准利率、LIBOR、SHIBOR等基准利率值。
     --CASE WHEN B.ACCT_TYPE = '0602' THEN B.INT_RATE
     --ELSE NVL(B.INT_RATE,0)+NVL(B.DEP_FLO_INT_RATE,0)+NVL(B.PROD_FLO_INT_RATE,0) END AS REALRATE , --9实际利率  D10.5  交易发生时实际执行的年利率水平。
     --NVL(B.INT_RATE,0), --9实际利率  D10.5  交易发生时实际执行的年利率水平。
     NVL(B.INT_RATE, 0), --8实际利率
     NVL(B.PBOC_BASE_RATE, 0), --9基准利率
     T.CURRENCY, --币种  C3  交易的币种。
     ABS(T.TRANS_AMT), --发生金额  D20.2  交易实际发生金额。
     DECODE(T.CHANNEL,
            '01',
            '01', --01：柜台
            '04',
            '02', --02：ATM机
            '02',
            '03', --03：网银
            '03',
            '04', --04：手机银行
            '99' --99：其他
            ), --交易渠道  C2  标识该笔交易的交易渠道，包括柜面、ATM机、网银、手机银行、电话交易、其他。
     CASE
       WHEN T.TRANS_INCOME_TYPE = '1' THEN
        '1'
       ELSE
        '0'
     END AS TRANSDIRECT, --交易方向  C1  用来标记该笔交易是转入（用1表示）还是转出（用0表示）。
     /*CASE
       WHEN T.CURRENCY <> 'CNY' AND T.RECEIPT_PAYMENT_TAG = '01' --币种为外币,交易方向为转入
            AND T.AMOUNT_USD >= '3000000' THEN
        'A' --大额存款
       WHEN T.CURRENCY <> 'CNY' AND T.RECEIPT_PAYMENT_TAG = '01' --币种为外币，交易方向为转入
            AND T.AMOUNT_USD < '3000000' THEN
        'B' --小额存款
       ELSE
        ''
     END AS ACCT_BALANCE_FLAG, --C1  指单笔存款发生额是否大于等于300万美元或其他等值外币。*/
     CASE
       WHEN T.CURRENCY <> 'CNY' AND T.TRANS_INCOME_TYPE = '1' AND
            T.TRANS_AMT * F.CCY_RATE >= 3000000 THEN
        'A'
       WHEN T.CURRENCY <> 'CNY' AND T.TRANS_INCOME_TYPE = '1' AND
            T.TRANS_AMT * F.CCY_RATE < 3000000 THEN
        'B'
     END AS AMTDEPFLG, --大小额标志
     IS_DATE CJRQ, --采集日期
     B.ORG_NUM NBJGH, --内部机构号
     '99' BIZ_LINE_ID, --业务条线
     '1', --增量标识
     TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD'), --上一数据时点
     to_char(b.MATUR_DATE, 'YYYY-MM-DD'), --到期日期
     to_char(b.ACCT_CLDATE, 'YYYY-MM-DD'), --销户日期
     b.GL_ITEM_CODE --科目号
      FROM SMTMODS.L_TRAN_TX T
     INNER JOIN SMTMODS.L_ACCT_DEPOSIT B
        ON T.CUST_ID = B.CUST_ID
       AND T.ACCOUNT_CODE = B.ACCT_NUM
       AND T.DATA_DATE = B.DATA_DATE
          --AND B.ORG_NUM NOT LIKE '0215%'
       AND B.ACCT_STS <> 'D'
       AND B.DEPOSIT_NUM = '1'
       AND B.POC_INDEX_CODE IN ('01020022', '01020023')
       AND B.GL_ITEM_CODE LIKE '20110205%'
      LEFT JOIN SMTMODS.L_PUBL_RATE F --汇率表
        ON T.CURRENCY = F.BASIC_CCY
       AND T.TX_DT = F.CCY_DATE
       AND F.FORWARD_CCY = 'USD'
       AND F.CONVERT_TYP = 'M'
     INNER JOIN SMTMODS.L_CUST_C A
        ON A.CUST_ID = T.CUST_ID
       AND A.DATA_DATE = T.DATA_DATE
	   AND (A.IS_NGI_CUST ='1' AND NVL(A.CUST_TYP,'0') <> '3' --个体工商户       --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]若是NGI客户标识则以NIG客户类型判断
	        OR NVL(A.IS_NGI_CUST,'0')='0' AND NVL(A.DEPOSIT_CUSTTYPE,'0') NOT IN ('13','14')
           )			                                              --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]非NGI客户通过存款人类型判断
    /*LEFT JOIN SMTMODS.L_EV_CORE_TXN_ENTRY_EVENT C   --剔除手续费
     ON T.KEY_TRANS_NO = C.EVENT_NO
    AND T.TRANS_AMT = C.TXN_AMT
    AND (CASE WHEN T.CD_TYPE = '1' THEN 'C' ELSE 'D' END) = C.DEBIT_OR_CRDT_INDEX*/
      LEFT JOIN SMTMODS.L_EV_CORE_TXN_ENTRY_EVENT C
        ON T.REFERENCE_NUM = C.EVENT_NO
       AND T.KEY_TRANS_NO = C.TXN_UNIQ_REF_NO
       AND (C.SUBJ_NO LIKE '6021%' OR C.SUBJ_NO LIKE '6421%' OR
           C.SUBJ_NO = '30050404') --20230103  剔除手续费科目
       AND T.DATA_DATE = C.DATA_DATE
     WHERE /*(B.GL_ITEM_CODE LIKE '20501%' OR B.GL_ITEM_CODE LIKE '20502%' OR
                   B.GL_ITEM_CODE LIKE '20503%' OR B.GL_ITEM_CODE LIKE '206%' OR
                   B.GL_ITEM_CODE LIKE '21901%' OR B.GL_ITEM_CODE LIKE '21903%' OR
                   B.GL_ITEM_CODE LIKE '202%' OR B.GL_ITEM_CODE LIKE '25102%')*/
     B.GL_ITEM_CODE LIKE '20110205%' --单位定期保证金存款
     AND T.DATA_DATE = IS_DATE
     AND ABS(T.TRANS_AMT) > 0
     AND T.PAYMENT_PROPERTY IS NULL --交易过滤掉支付使用数据
     AND T.PAYMENT_ORDER IS NULL --交易过滤掉支付使用数据
     AND T.CURRENCY IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
     AND T.TRAN_STS <> 'B'
    --AND T.SUMMARY NOT IN ('受托支付转账')
     AND C.SUBJ_NO IS NULL
     AND (T.TRAN_CODE_DESCRIBE NOT LIKE '%结息%' OR
     T.TRAN_CODE_DESCRIBE NOT LIKE '%利息%');

  COMMIT;
  --单位活期存款要剔除个体工商户的数据                  --20221228  业务要求将活期存款进行筛选
  /*INSERT INTO DATACORE_IE_CK_DWCKFS_INC_TMP2
    (DATADATE, --数据日期
     ACCDEPCODE, --存款账户编码
     DEPAGRSEQNO, --存款序号
     CORPID, --内部机构号
     CUSTID, --客户号
     SERIALNO, --交易流水号
     TRANSACTIONDATE, --交易日期
     REALRATE, --实际利率
     BASERATE, --基准利率
     MONEYSYMB, --币种
     TRANSAMT, --发生金额
     TRANSCHANNEL, --交易渠道
     TRANSDIRECT, --交易方向
     AMTDEPFLG, --大小额标志
     CJRQ, --采集日期
     NBJGH, --内部机构号
     BIZ_LINE_ID, --业务条线
     DIFF_TYPE,    --增量标识
     LAST_DATA_DATE    --上一数据时点
     )
    SELECT \*+ USE_HASH(T,B,F,A,C) PARALLEL(8)*\VS_TEXT, --数据日期
           T.ACCOUNT_CODE, --存款账户编码
           B.DEPOSIT_NUM, --存款序号  C..100  存款吸收机构内部自行设置的，用于标识同一存款账户下不同笔存款的唯一编码。
           B.ORG_NUM, --内部机构号  C..30  金融机构自定义的唯一标识该笔业务经办机构（总行或分支机构）的内部编号。
           T.CUST_ID, --客户号  C..30  金融机构自定义的唯一标识该客户的内部编号。
           T.REFERENCE_NUM, --交易流水号  C..60  此笔交易在金融机构内部的唯一编码。
           TO_CHAR(T.TX_DT, 'yyyy-mm-dd'), --交易日期  C10  交易实际发生日期。
           --CASE WHEN B.ACCT_TYPE = '0602' THEN B.INT_RATE
             --ELSE NVL(B.INT_RATE,0)+NVL(B.DEP_FLO_INT_RATE,0)+NVL(B.PROD_FLO_INT_RATE,0) END, --8基准利率  D10.5  交易发生时对应的最近一期LPR、存款基准利率、LIBOR、SHIBOR等基准利率值。
           NVL(B.INT_RATE,0), --8基准利率  D10.5  交易发生时对应的最近一期LPR、存款基准利率、LIBOR、SHIBOR等基准利率值。
           --CASE WHEN B.ACCT_TYPE = '0602' THEN B.INT_RATE
             --ELSE NVL(B.INT_RATE,0)+NVL(B.DEP_FLO_INT_RATE,0)+NVL(B.PROD_FLO_INT_RATE,0) END AS REALRATE , --9实际利率  D10.5  交易发生时实际执行的年利率水平。
           NVL(B.INT_RATE,0), --9实际利率  D10.5  交易发生时实际执行的年利率水平。
           T.CURRENCY, --币种  C3  交易的币种。
           ABS(T.TRANS_AMT), --发生金额  D20.2  交易实际发生金额。
            DECODE(T.CHANNEL,
                  '01',
                  '01', --01：柜台
                  '04',
                  '02', --02：ATM机
                  '02',
                  '03', --03：网银
                  '03',
                  '04', --04：手机银行
                  '99' --99：其他
                  ), --交易渠道  C2  标识该笔交易的交易渠道，包括柜面、ATM机、网银、手机银行、电话交易、其他。
           CASE WHEN T.TRANS_INCOME_TYPE = '1' THEN '1'
                 ELSE '0'
            END AS TRANSDIRECT, --交易方向  C1  用来标记该笔交易是转入（用1表示）还是转出（用0表示）。
           \*CASE
             WHEN T.CURRENCY <> 'CNY' AND T.RECEIPT_PAYMENT_TAG = '01' --币种为外币,交易方向为转入
                  AND T.AMOUNT_USD >= '3000000' THEN
              'A' --大额存款
             WHEN T.CURRENCY <> 'CNY' AND T.RECEIPT_PAYMENT_TAG = '01' --币种为外币，交易方向为转入
                  AND T.AMOUNT_USD < '3000000' THEN
              'B' --小额存款
             ELSE
              ''
           END AS ACCT_BALANCE_FLAG, --C1  指单笔存款发生额是否大于等于300万美元或其他等值外币。*\
           CASE WHEN T.CURRENCY <> 'CNY' AND T.TRANS_INCOME_TYPE = '1' AND  T.TRANS_AMT * F.CCY_RATE >= 3000000 THEN 'A'
                 WHEN T.CURRENCY <> 'CNY' AND T.TRANS_INCOME_TYPE = '1' AND  T.TRANS_AMT * F.CCY_RATE < 3000000 THEN 'B'
            END AS AMTDEPFLG, --大小额标志
           IS_DATE CJRQ, --采集日期
           B.ORG_NUM NBJGH, --内部机构号
           '99' BIZ_LINE_ID, --业务条线
           '1',             --增量标识
           TO_CHAR(TO_DATE(IS_DATE,'YYYYMMDD')-1,'YYYYMMDD')   --上一数据时点
      FROM SMTMODS.L_TRAN_TX T
      INNER JOIN SMTMODS.L_ACCT_DEPOSIT B
        ON T.CUST_ID = B.CUST_ID
        AND T.ACCOUNT_CODE = B.ACCT_NUM
        AND T.DATA_DATE = B.DATA_DATE
        --AND B.ORG_NUM NOT LIKE '0215%'
        AND B.DEPOSIT_NUM = '1'
        LEFT JOIN SMTMODS.L_PUBL_RATE F  --汇率表
          ON T.CURRENCY = F.BASIC_CCY
          AND T.TX_DT = F.CCY_DATE
          AND F.FORWARD_CCY = 'USD'
          AND F.CONVERT_TYP = 'M'
          INNER JOIN SMTMODS.L_CUST_C A
         ON A.CUST_ID = T.CUST_ID
         AND A.DATA_DATE = T.DATA_DATE
         AND A.CUST_TYP <> '3'   --个体工商户
         \*LEFT JOIN SMTMODS.L_EV_CORE_TXN_ENTRY_EVENT C   --剔除手续费
               ON T.KEY_TRANS_NO = C.EVENT_NO
              AND T.TRANS_AMT = C.TXN_AMT
              AND (CASE WHEN T.CD_TYPE = '1' THEN 'C' ELSE 'D' END) = C.DEBIT_OR_CRDT_INDEX*\
          LEFT JOIN SMTMODS.L_EV_CORE_TXN_ENTRY_EVENT C
          ON T.REFERENCE_NUM = C.EVENT_NO
          AND T.KEY_TRANS_NO = C.TXN_UNIQ_REF_NO
          AND T.DATA_DATE = C.DATA_DATE
     WHERE --B.GL_ITEM_CODE LIKE '201%' --单位活期存款
           B.GL_ITEM_CODE LIKE '20110201%' --单位活期存款
       AND T.DATA_DATE = IS_DATE --定活期标志
       AND ABS(T.TRANS_AMT) > 0
       AND T.PAYMENT_PROPERTY IS NULL--交易过滤掉支付使用数据
       AND T.PAYMENT_ORDER IS NULL  --交易过滤掉支付使用数据
       AND T.CURRENCY IN ('CNY','USD','JPY','EUR','HKD')
       AND T.TRAN_STS <> 'B'
       --AND T.SUMMARY NOT IN ('受托支付转账')
       AND C.SUBJ_NO IS NULL;

  COMMIT;*/

  INSERT INTO DATACORE_IE_CK_DWCKFS_INC
    SELECT *
      FROM DATACORE_IE_CK_DWCKFS_INC_TMP2 T
     WHERE NOT EXISTS (SELECT 1
              FROM SMTMODS.L_CUST_P A
             WHERE T.CUSTID = A.CUST_ID
               AND A.OPERATE_CUST_TYPE = 'A' --个体工商户
               AND A.DATA_DATE = IS_DATE);

  COMMIT;

  ----删除目标表数据
  SP_IRS_PARTITIONS_INC(IS_DATE, 'IE_CK_DWCKFS', OI_RETCODE);
  --EXECUTE IMMEDIATE 'ANALYZE TABLE IRS.DATACORE_IE_CK_DWCKFS_INC COMPUTE STATISTICS';

  ----将数据插入目标表
  INSERT INTO IE_CK_DWCKFS_INC
    (DATADATE, --数据日期
     ACCDEPCODE, --存款账户编码
     DEPAGRSEQNO, --存款序号
     CORPID, --内部机构号
     CUSTID, --客户号
     SERIALNO, --交易流水号
     TRANSACTIONDATE, --交易日期
     REALRATE, --实际利率
     BASERATE, --基准利率
     MONEYSYMB, --币种
     TRANSAMT, --发生金额
     TRANSCHANNEL, --交易渠道
     TRANSDIRECT, --交易方向
     AMTDEPFLG, --大小额标志
     CJRQ, --采集日期
     NBJGH, --内部机构号
     BIZ_LINE_ID, --业务条线
     DIFF_TYPE, --增量标识
     LAST_DATA_DATE, --上一数据时点
     IRS_CORP_ID --法人机构ID
     )
    SELECT /*+PARALLEL(8)*/
     T.DATADATE, --数据日期
     T.ACCDEPCODE, --存款账户编码
     T.DEPAGRSEQNO, --存款序号
     T.CORPID, --内部机构号
     T.CUSTID, --客户号
     T.SERIALNO, --交易流水号
     T.TRANSACTIONDATE, --交易日期
     /*T.REALRATE, --实际利率
     T.BASERATE, --基准利率*/
     CASE
       WHEN T.DATADATE = T.MATUR_DATE THEN
        F.INT_RATE
       ELSE
        T.REALRATE
     END AS INT_RATE, --实际利率
     CASE
       WHEN T.DATADATE = T.MATUR_DATE THEN --MDF BY 20230824 黄俊铭口径，到期日期等于数据日期，取昨天人行基准利率
        F.PBOC_BASE_RATE
       WHEN t.GL_ITEM_CODE IN ('20110110', '20110205') AND
            t.ACCT_CLDATE = t.datadate THEN
        F.PBOC_BASE_RATE --ADF BY 20230829 黄俊铭口径，通知存款当天销户，取昨天的人行基准利率
       ELSE
        T.BASERATE
     END AS BASE_RATE, --基准利率
     T.MONEYSYMB, --币种
     T.TRANSAMT, --发生金额
     T.TRANSCHANNEL, --交易渠道
     T.TRANSDIRECT, --交易方向
     T.AMTDEPFLG, --大小额标志
     T.CJRQ, --采集日期
     T.NBJGH, --内部机构号
     T.BIZ_LINE_ID, --业务条线
     t.DIFF_TYPE, --增量标识
     t.LAST_DATA_DATE, --上一数据时点
     CASE WHEN  T.CORPID LIKE '51%' THEN '510000'
          WHEN  T.CORPID LIKE '52%' THEN '520000'
          WHEN  T.CORPID LIKE '53%' THEN '530000'
          WHEN  T.CORPID LIKE '54%' THEN '540000'
          WHEN  T.CORPID LIKE '55%' THEN '550000'
          WHEN  T.CORPID LIKE '56%' THEN '560000'
          WHEN  T.CORPID LIKE '57%' THEN '570000'
          WHEN  T.CORPID LIKE '58%' THEN '580000'
          WHEN  T.CORPID LIKE '59%' THEN '590000'
          WHEN  T.CORPID LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
      FROM DATACORE_IE_CK_DWCKFS_INC T
      left join smtmods.l_acct_deposit f ---定期当天到期取定期利率，实际到期是到期日字段的前一天，到期日字段是系统到期日。
        on t.ACCDEPCODE = f.ACCT_NUM
       and t.depagrseqno = f.deposit_num
       and f.data_date = VS_YES_DATE;

  /*INNER JOIN DATACORE_IE_CK_DWCKFS_INC_TMP1 B
  ON T.CUSTID = B.CUST_ID
  WHERE T.CORPID NOT LIKE '0215%'*/

  COMMIT;

  -------------------------------------------------------------------------
  OI_RETCODE := 0; --设置成功状态为0

  --返回中文描述
  OI_RETCODE2 := '成功!';

  /*COMMIT; --非特殊处理只能在最后一次提交*/
  -- 结束日志
  VS_STEP := 'END';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
EXCEPTION
  WHEN OTHERS THEN
    --如果出现异常
    VI_ERRORCODE := SQLCODE; --设置异常代码
    VS_TEXT      := VS_STEP || '|' || IS_DATE || '|' ||
                    SUBSTR(SQLERRM, 1, 200); --设置异常描述
    ROLLBACK; --数据回滚
    OI_RETCODE := -1; --设置异常状态为-1

    --返回中文描述

    OI_RETCODE2 := SUBSTR(SQLERRM, 1, 200);

    --插入日志表，记录错误
    SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);
END;
/

