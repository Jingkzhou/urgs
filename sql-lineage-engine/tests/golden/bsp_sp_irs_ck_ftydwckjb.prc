CREATE OR REPLACE PROCEDURE BSP_SP_IRS_CK_FTYDWCKJB(IS_DATE     IN VARCHAR2,
                                                    OI_RETCODE  OUT INTEGER,
                                                    OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_FTY_FTYDWCKJB
  -- 用途:生成非同业单位存款基础信息表
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  -- 版本
  --    高铭言 20210520
  -- 版权
  --     中软融鑫
  --需求编号：JLBA202504180011 上线日期：2025-05-27，修改人：蒿蕊，提出人：黄俊铭  修改原因：D1092取2005；D1095取2010；D1011取2008和2009；
  --需求编号：JLBA202507210012 上线日期：2025-12-11，修改人：蒿蕊，提出人：王铣    修改原因：2011吸收存款列入一般存款统计
  --需求编号：数据维护单       上线日期：2025-12-17，修改人：蒿蕊  提出人：黄俊铭  修改原因：个体工商户判断优先以NGI客户类型为准，非NGI客户则根据柜面存款人类别判断
  ------------------------------------------------------------------------------------------------------
  VI_ERRORCODE      NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT           VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(40) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(30); --存储过程执行步骤标志
  NUM               INTEGER;
  NEXTDATE          VARCHAR2(8);
  OLDDATE           VARCHAR2(8); --清除历史数据用  20161215 add
  NUM_OLD           INTEGER; --清除历史数据用  20161215 add
  VS_YES_DATE       VARCHAR2(30);
BEGIN
  VS_TEXT := IS_DATE;
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_CK_FTYDWCKJB';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);
  NEXTDATE    := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') + 1, 'YYYYMMDD');
  OLDDATE     := TO_CHAR(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -12) + 1,
                         'YYYYMMDD'); --月初第一天  20151215 add
  VS_YES_DATE := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD');

  --------------------------------------------------------------------------------------------------------------

  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_CK_FTYDWCKJB';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE L_ACCT_OBS_LOAN_TEST';
  --EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_CK_FTYDWCKJB_TMP1';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_CK_FTYDWCKJB_TMP2';

  /*  INSERT INTO DATACORE_IE_CK_FTYDWCKJB_TMP1
      SELECT DISTINCT CUST_ID
        FROM SMTMODS.L_CUST_P
       WHERE DATA_DATE = IS_DATE
         AND ORG_NUM NOT LIKE '0215%';
    COMMIT;
    INSERT INTO DATACORE_IE_CK_FTYDWCKJB_TMP1
      SELECT DISTINCT CUST_ID
        FROM SMTMODS.L_CUST_C
       WHERE DATA_DATE = IS_DATE
         AND ORG_NUM NOT LIKE '0215%';
    COMMIT;
  */
  /*  --区分协定户还是结算户存款 (A.COD_MC_ACCT_NO --结算账户,A.COD_AGMT_SUB_ACCT_NO --协定账户)
  INSERT INTO IE_CK_FTYDWCKJB_XIEDING
    SELECT A.COD_MC_ACCT_NO, A.COD_AGMT_SUB_ACCT_NO
      FROM FCR_XFACE_SUB_ACCT_ADDNL_DTLS@ODS A
     WHERE A.FLG_AGREEMENT_DEPOSIT = 'Y'
       AND A.COD_AGMT_SUB_ACCT_NO IS NOT NULL
       AND A.ODS_DATA_DATE = IS_DATE;*/

  --贷款表外表中保证金账号存在重复数据，进行去重
  INSERT INTO L_ACCT_OBS_LOAN_TEST
    SELECT T.DATA_DATE, T.SECURITY_ACCT_NUM, T.ACCT_NUM, T.ACCT_TYP
      FROM (SELECT A.DATA_DATE,
                   A.SECURITY_ACCT_NUM,
                   A.ACCT_NUM,
                   A.ACCT_TYP,
                   ROW_NUMBER() OVER(PARTITION BY A.SECURITY_ACCT_NUM ORDER BY A.ACCT_NUM DESC) RN
              FROM SMTMODS.L_ACCT_OBS_LOAN A
             WHERE A.DATA_DATE = IS_DATE) T
     WHERE RN = 1;

  INSERT INTO DATACORE_IE_CK_FTYDWCKJB
    SELECT /*+ USE_HASH(A,B,C,D,E) PARALLEL(8)*/
     TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD') --数据日期
    ,
     A.ACCT_NUM --存款账户编码
    ,
     A.DEPOSIT_NUM --存款序号
    ,
     A.ORG_NUM --内部机构号
    ,
     A.CUST_ID --客户号
     --,D01：普通存款
    ,
     CASE
       WHEN A.ACCT_TYPE = '0601' THEN /* AND T.COD_AGMT_SUB_ACCT_NO IS NULL THEN*/
        'D051' --结算户存款
       WHEN A.ACCT_TYPE = '0602' THEN /* AND T.COD_AGMT_SUB_ACCT_NO IS NOT NULL THEN*/
        'D052' --协定户存款
       WHEN A.ACCT_TYPE = '0401' THEN
        'D031' --一天通知
       WHEN A.ACCT_TYPE = '0402' THEN
        'D032' --七天通知
       WHEN D.ACCT_TYP = '111' THEN
        'D061' --银行承兑汇票保证金存款
       WHEN D.ACCT_TYP like '31%' THEN
        'D062' --信用证保证金存款
       WHEN D.ACCT_TYP IN ('121', '211') THEN
        'D063' --保函保证金存款
       WHEN (D.ACCT_TYP IN ('511', '521', '522', '523', '531') OR
            A.GL_ITEM_CODE in ('20110209', '20110210')) THEN
        'D069' --其他保证金存款
       WHEN A.GL_ITEM_CODE LIKE '20110201%' THEN
        'D011' --单位活期存款
       WHEN A.GL_ITEM_CODE IN ('20110202', '20110203') THEN
        'D012' --单位定期存款
       WHEN A.GL_ITEM_CODE = '20110204' THEN
        'D04' --协议存款
       WHEN A.GL_ITEM_CODE IN ('20110207' /*, '21903'*/) THEN
        'D08' --结构性存款
       WHEN A.GL_ITEM_CODE = '20110701' OR A.GL_ITEM_CODE LIKE '2010%' THEN    --[2025-05-27] [蒿蕊] [JLBA202504180011] 黄俊铭]D1095增加取2010国库定期存款
        'D1095' --国库定期存款
	   WHEN A.GL_ITEM_CODE LIKE '2005%' THEN 'D1092'     --[2025-05-27] [蒿蕊] [JLBA202504180011] 黄俊铭]D1092：待结算财政款项取2005财政性存款
	   WHEN  A.GL_ITEM_CODE LIKE '2008%'
			 OR A.GL_ITEM_CODE LIKE '2009%' THEN 'D1011'     --[2025-05-27] [蒿蕊] [JLBA202504180011] 黄俊铭]D1011财政库款取2008和2009
	   --[2025-12-11] [蒿蕊] [JLBA202507210012] [黄俊铭]增加201103科目，其中资产负债指标代码01020019归到D1094、01020015归到D1093、01020018归到D1091、201103科目下非01020019、01020015、01020018归到D1091 start
	   WHEN A.GL_ITEM_CODE LIKE '201103%' AND POC_INDEX_CODE='01020019' THEN 'D1094'
	   WHEN A.GL_ITEM_CODE LIKE '201103%' AND POC_INDEX_CODE='01020015' THEN 'D1093'
	   WHEN A.GL_ITEM_CODE LIKE '201103%' AND POC_INDEX_CODE NOT IN ('01020019','01020015') THEN 'D1091'
	   --[2025-12-11] [蒿蕊] [JLBA202507210012] [黄俊铭]增加201103科目，其中资产负债指标代码01020019归到D1094、01020015归到D1093、01020018归到D1091、201103科目下非01020019、01020015、01020018归到D1091 end
     END AS PROD_TYPE,
     A.AGREEMENT_TYPE --协议存款类型
    ,
     TO_CHAR(A.ACCT_OPDATE, 'YYYY-MM-DD') --起始日期
    ,
     CASE
       WHEN A.ACCT_TYPE = '0401' AND A.MATUR_DATE IS NULL THEN
        '1999-01-01'
       WHEN A.ACCT_TYPE = '0402' AND A.MATUR_DATE IS NULL THEN
        '1999-01-07'
       ELSE
        TO_CHAR(A.MATUR_DATE, 'YYYY-MM-DD')
     END --到期日期
    ,
     TO_CHAR(A.ACCT_CLDATE, 'YYYY-MM-DD') --实际终止日期
    ,
     '' AS TERM_TYPE --存款期限类型
    ,
     'TR07' --定价基准类型
    ,
     CASE
       WHEN A.INT_RATE_TYP = 'F' THEN
        'RF01'
       WHEN A.INT_RATE_TYP = 'L' THEN
        'RF02'
     END --利率类型
    ,
     CASE
       WHEN A.ACCT_TYPE LIKE '03%' THEN
        A.TIME_DEMAND_DEP_RATE
       WHEN A.ACCT_TYPE = '0602' THEN
        NVL(A.INT_RATE, 0)
     --ELSE NVL(A.INT_RATE,0)+NVL(A.DEP_FLO_INT_RATE,0)+NVL(A.PROD_FLO_INT_RATE,0)
       ELSE
        NVL(A.INT_RATE, 0)
     END AS REALRATE, --实际利率
     /*CASE
       WHEN A.ACCT_TYPE LIKE '03%' THEN
        A.TIME_DEMAND_DEP_RATE
       WHEN A.ACCT_TYPE = '0602' THEN
        NVL(A.INT_RATE, 0)
     --ELSE NVL(A.INT_RATE,0)+NVL(A.DEP_FLO_INT_RATE,0)+NVL(A.PROD_FLO_INT_RATE,0)
       ELSE
        NVL(A.BASE_RATE, 0)
     END AS BASERATE, --基准利率*/
     NVL(A.PBOC_BASE_RATE, 0) AS BASERATE, --基准利率  MDF BY 20230816
     '99' --利率浮动频率
    ,
     '' --保底收益率
    ,
     '' --最高收益率
    ,
     CASE
       WHEN A.OPEN_CHANNEL IN ('01', '04') THEN
        '01'
       WHEN A.OPEN_CHANNEL IN ('02', '03', '05') THEN
        '02'
       WHEN A.OPEN_CHANNEL = '06' THEN
        '03'
       ELSE
        '99'
     END AS BUSICHANNEL --开户渠道
    ,
     'N' --异地存款标志
    ,
     /*CASE
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_TYPE = '0600' --协定存款
            AND A.ACCT_BALANCE * B.CCY_RATE >= '3000000' THEN
        'A' --大额存款
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.GL_ITEM_CODE = '21101' --活期
            AND A.ACCT_BALANCE * B.CCY_RATE >= '3000000' THEN
        'A' --大额存款
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_TYPE = '0600' --协定存款
            AND A.ACCT_BALANCE * B.CCY_RATE < '3000000' THEN
        'B' --小额存款
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.GL_ITEM_CODE = '21101' --活期
            AND A.ACCT_BALANCE * B.CCY_RATE < '3000000' THEN
        'B' --小额存款
       ELSE
        ''
     END AS ACCT_BALANCE_FLAG*/
     CASE
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_BALANCE * B.CCY_RATE >= '3000000' THEN
        'A' --大额存款
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_BALANCE * B.CCY_RATE < '3000000' THEN
        'B' --小额存款
       ELSE
        ''
     END AS ACCT_BALANCE_FLAG,
     A.ACCT_TYPE --账户类型
    ,
     A.ST_INT_DT as ST_INT_DT2 --起息日期
    ,
     A.MATUR_DATE AS MATUR_DATE2, --到期日期
     TO_CHAR(A.ACCT_CLDATE, 'YYYY-MM-DD'), --销户日期
     A.GL_ITEM_CODE --科目
      FROM SMTMODS.L_ACCT_DEPOSIT A --存款账户信息表
     INNER JOIN SMTMODS.L_PUBL_RATE B --汇率表
        ON A.CURR_CD = B.BASIC_CCY --账户币种
       AND B.CCY_DATE = TO_DATE(IS_DATE, 'yyyymmdd') --汇率日期
       AND A.DATA_DATE = B.DATA_DATE
       AND B.FORWARD_CCY = 'USD' --折算币种
      LEFT JOIN SMTMODS.L_CUST_P C
        ON A.CUST_ID = C.CUST_ID
       AND A.DATA_DATE = C.DATA_DATE
      LEFT JOIN L_ACCT_OBS_LOAN_TEST D
        ON A.ACCT_NUM = D.SECURITY_ACCT_NUM
       AND A.DATA_DATE = D.DATA_DATE
    /* LEFT JOIN IE_CK_FTYDWCKJB_XIEDING T
    ON A.ACCT_NUM = T.COD_AGMT_SUB_ACCT_NO*/
     INNER JOIN SMTMODS.L_CUST_C E
        ON A.CUST_ID = E.CUST_ID
       AND A.DATA_DATE = E.DATA_DATE
	   AND (E.IS_NGI_CUST ='1' AND NVL(E.CUST_TYP,'0') <> '3' --个体工商户                    --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]若是NGI客户标识则以NIG客户类型判断
	        OR NVL(E.IS_NGI_CUST,'0')='0' AND NVL(E.DEPOSIT_CUSTTYPE,'0') NOT IN ('13','14')  --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]非NGI客户通过存款人类型判断
           )
     WHERE /*(A.GL_ITEM_CODE LIKE '20501%' OR A.GL_ITEM_CODE LIKE '20502%' OR
                   A.GL_ITEM_CODE LIKE '20503%' OR A.GL_ITEM_CODE LIKE '206%' OR
                   A.GL_ITEM_CODE LIKE '21901%' OR A.GL_ITEM_CODE LIKE '21903%' OR
                   A.GL_ITEM_CODE LIKE '202%' OR A.GL_ITEM_CODE LIKE '25102%' OR
                   A.GL_ITEM_CODE LIKE '201%')*/
     (A.GL_ITEM_CODE LIKE '20110202%' --单位一般定期存款
     OR A.GL_ITEM_CODE LIKE '20110203%' --单位大额可转让定期存单
     OR A.GL_ITEM_CODE LIKE '20110204%' --单位协议存款
     OR A.GL_ITEM_CODE LIKE '201107%' --国库定期存款
     OR A.GL_ITEM_CODE LIKE '20110207%' --单位结构性存款
     /*OR B.GL_ITEM_CODE LIKE '21903%'*/
     OR A.GL_ITEM_CODE LIKE '20110205%' --单位通知存款
     OR A.GL_ITEM_CODE LIKE '20110209%' --单位活期保证金存款
     OR A.GL_ITEM_CODE LIKE '20110210%' --单位定期保证金存款
     OR A.GL_ITEM_CODE LIKE '20110201%' --单位活期存款
	 /*[2025-05-27] [蒿蕊] [JLBA202504180011] [黄俊铭]D1092：待结算财政款项取2005财政性存款 D1095增加取2010国库定期存款 D1011取2008和2009 START*/ 
	 OR A.GL_ITEM_CODE LIKE '2005%'     
	 OR A.GL_ITEM_CODE LIKE '2010%'    
	 OR A.GL_ITEM_CODE LIKE '2008%'
	 OR A.GL_ITEM_CODE LIKE '2009%'
	 /*[2025-05-27] [蒿蕊] [JLBA202504180011] [黄俊铭]D1092：待结算财政款项取2005财政性存款 D1095增加取2010国库定期存款 D1011取2008和2009 end */
	 OR A.GL_ITEM_CODE LIKE '201103%' --[2025-12-11] [蒿蕊] [JLBA202507210012] [黄俊铭]增加201103科目
	 )
     AND (C.OPERATE_CUST_TYPE IS NULL OR C.OPERATE_CUST_TYPE <> 'A')
     AND A.ACCT_BALANCE > 0
     AND A.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
     AND A.DATA_DATE = IS_DATE;
  --WHERE A.DATA_DATE = '20210430'
  COMMIT;

  INSERT INTO DATACORE_IE_CK_FTYDWCKJB_TMP2
    SELECT /*+ USE_HASH(A,B,C,D,E) PARALLEL(8)*/
     TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD') --数据日期
    ,
     A.ACCT_NUM --存款账户编码
    ,
     A.DEPOSIT_NUM --存款序号
    ,
     A.ORG_NUM --内部机构号
    ,
     A.CUST_ID --客户号
     --,D01：普通存款
    ,
     CASE
       WHEN A.ACCT_TYPE = '0601' THEN /* AND T.COD_AGMT_SUB_ACCT_NO IS NULL THEN*/
        'D051' --结算户存款
       WHEN A.ACCT_TYPE = '0602' THEN /* AND T.COD_AGMT_SUB_ACCT_NO IS NOT NULL THEN*/
        'D052' --协定户存款
       WHEN A.ACCT_TYPE = '0401' THEN
        'D031' --一天通知
       WHEN A.ACCT_TYPE = '0402' THEN
        'D032' --七天通知
       WHEN D.ACCT_TYP = '111' THEN
        'D061' --银行承兑汇票保证金存款
       WHEN D.ACCT_TYP like '31%' THEN
        'D062' --信用证保证金存款
       WHEN D.ACCT_TYP IN ('121', '211') THEN
        'D063' --保函保证金存款
       WHEN (D.ACCT_TYP IN ('511', '521', '522', '523', '531') OR
            A.GL_ITEM_CODE in ('20110209', '20110210')) THEN
        'D069' --其他保证金存款
       WHEN A.GL_ITEM_CODE LIKE '20110201%' THEN
        'D011' --单位活期存款
       WHEN A.GL_ITEM_CODE IN ('20110202', '20110203') THEN
        'D012' --单位定期存款
       WHEN A.GL_ITEM_CODE = '20110204' THEN
        'D04' --协议存款
       WHEN A.GL_ITEM_CODE IN ('20110207' /*, '21903'*/) THEN
        'D08' --结构性存款
       WHEN A.GL_ITEM_CODE = '20110701' OR A.GL_ITEM_CODE LIKE '2010%' THEN    --[2025-05-27] [蒿蕊] [JLBA202504180011] 黄俊铭]D1095增加取2010国库定期存款
        'D1095' --国库定期存款
	   WHEN A.GL_ITEM_CODE LIKE '2005%' THEN 'D1092'     --[2025-05-27] [蒿蕊] [JLBA202504180011] 黄俊铭]D1092：待结算财政款项取2005财政性存款
	   WHEN  A.GL_ITEM_CODE LIKE '2008%'
			 OR A.GL_ITEM_CODE LIKE '2009%' THEN 'D1011'     --[2025-05-27] [蒿蕊] [JLBA202504180011] 黄俊铭]D1011财政库款取2008和2009
	   --[2025-12-11] [蒿蕊] [JLBA202507210012] [黄俊铭]增加201103科目，其中资产负债指标代码01020019归到D1094、01020015归到D1093、01020018归到D1091、201103科目下非01020019、01020015、01020018归到D1091 start
	   WHEN A.GL_ITEM_CODE LIKE '201103%' AND POC_INDEX_CODE='01020019' THEN 'D1094'
	   WHEN A.GL_ITEM_CODE LIKE '201103%' AND POC_INDEX_CODE='01020015' THEN 'D1093'
	   WHEN A.GL_ITEM_CODE LIKE '201103%' AND POC_INDEX_CODE NOT IN ('01020019','01020015') THEN 'D1091'
	   --[2025-12-11] [蒿蕊] [JLBA202507210012] [黄俊铭]增加201103科目，其中资产负债指标代码01020019归到D1094、01020015归到D1093、01020018归到D1091、201103科目下非01020019、01020015、01020018归到D1091 end
     END AS PROD_TYPE,
     A.AGREEMENT_TYPE --协议存款类型
    ,
     TO_CHAR(A.ACCT_OPDATE, 'YYYY-MM-DD') --起始日期
    ,
     CASE
       WHEN A.ACCT_TYPE = '0401' AND A.MATUR_DATE IS NULL THEN
        '1999-01-01'
       WHEN A.ACCT_TYPE = '0402' AND A.MATUR_DATE IS NULL THEN
        '1999-01-07'
       ELSE
        TO_CHAR(A.MATUR_DATE, 'YYYY-MM-DD')
     END --到期日期
    ,
     TO_CHAR(A.ACCT_CLDATE, 'YYYY-MM-DD') --实际终止日期
    ,
     '' AS TERM_TYPE --存款期限类型
    ,
     'TR07' --定价基准类型
    ,
     CASE
       WHEN A.INT_RATE_TYP = 'F' THEN
        'RF01'
       WHEN A.INT_RATE_TYP = 'L' THEN
        'RF02'
     END --利率类型
    ,
     CASE
       WHEN A.ACCT_TYPE LIKE '03%' THEN
        A.TIME_DEMAND_DEP_RATE
       WHEN A.ACCT_TYPE = '0602' THEN
        NVL(A.INT_RATE, 0)
     --ELSE NVL(A.INT_RATE,0)+NVL(A.DEP_FLO_INT_RATE,0)+NVL(A.PROD_FLO_INT_RATE,0)
       ELSE
        NVL(A.INT_RATE, 0)
     END AS REALRATE, --实际利率
     /*CASE
       WHEN A.ACCT_TYPE LIKE '03%' THEN
        A.TIME_DEMAND_DEP_RATE
       WHEN A.ACCT_TYPE = '0602' THEN
        NVL(A.INT_RATE, 0)
     --ELSE NVL(A.INT_RATE,0)+NVL(A.DEP_FLO_INT_RATE,0)+NVL(A.PROD_FLO_INT_RATE,0)
       ELSE
        NVL(A.BASE_RATE, 0)
     END AS BASERATE --基准利率*/
     NVL(A.PBOC_BASE_RATE, 0) --基准利率 MDF BY 20230816
    ,
     '99' --利率浮动频率
    ,
     '' --保底收益率
    ,
     '' --最高收益率
    ,
     CASE
       WHEN A.OPEN_CHANNEL IN ('01', '04') THEN
        '01'
       WHEN A.OPEN_CHANNEL IN ('02', '03', '05') THEN
        '02'
       WHEN A.OPEN_CHANNEL = '06' THEN
        '03'
       ELSE
        '99'
     END AS BUSICHANNEL --开户渠道
    ,
     'N' --异地存款标志
    ,
     /*CASE
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_TYPE = '0600' --协定存款
            AND A.ACCT_BALANCE * B.CCY_RATE >= '3000000' THEN
        'A' --大额存款
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.GL_ITEM_CODE = '21101' --活期
            AND A.ACCT_BALANCE * B.CCY_RATE >= '3000000' THEN
        'A' --大额存款
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_TYPE = '0600' --协定存款
            AND A.ACCT_BALANCE * B.CCY_RATE < '3000000' THEN
        'B' --小额存款
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.GL_ITEM_CODE = '21101' --活期
            AND A.ACCT_BALANCE * B.CCY_RATE < '3000000' THEN
        'B' --小额存款
       ELSE
        ''
     END AS ACCT_BALANCE_FLAG*/
     CASE
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_BALANCE * B.CCY_RATE >= '3000000' THEN
        'A' --大额存款
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_BALANCE * B.CCY_RATE < '3000000' THEN
        'B' --小额存款
       ELSE
        ''
     END AS ACCT_BALANCE_FLAG,
     A.ACCT_TYPE --账户类型
    ,
     A.ST_INT_DT as ST_INT_DT2 --起息日期
    ,
     A.MATUR_DATE as MATUR_DATE2 --到期日期
    ,
     TO_CHAR(A.ACCT_CLDATE, 'YYYY-MM-DD'), --销户日期
     A.GL_ITEM_CODE --科目号
      FROM SMTMODS.L_ACCT_DEPOSIT A --存款账户信息表
     INNER JOIN SMTMODS.L_PUBL_RATE B --汇率表
        ON A.CURR_CD = B.BASIC_CCY --账户币种
       AND B.CCY_DATE = TO_DATE(IS_DATE, 'yyyymmdd') --汇率日期
       AND A.DATA_DATE = B.DATA_DATE
       AND B.FORWARD_CCY = 'USD' --折算币种
      LEFT JOIN SMTMODS.L_CUST_P C
        ON A.CUST_ID = C.CUST_ID
       AND A.DATA_DATE = C.DATA_DATE
      LEFT JOIN L_ACCT_OBS_LOAN_TEST D
        ON A.ACCT_NUM = D.SECURITY_ACCT_NUM
       AND A.DATA_DATE = D.DATA_DATE
    /*LEFT JOIN IE_CK_FTYDWCKJB_XIEDING T
    ON A.ACCT_NUM = T.COD_AGMT_SUB_ACCT_NO*/
     INNER JOIN SMTMODS.L_CUST_C E
        ON A.CUST_ID = E.CUST_ID
       AND A.DATA_DATE = E.DATA_DATE
       AND (E.IS_NGI_CUST ='1' AND NVL(E.CUST_TYP,'0') <> '3' --个体工商户                    --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]若是NGI客户标识则以NIG客户类型判断
	        OR NVL(E.IS_NGI_CUST,'0')='0' AND NVL(E.DEPOSIT_CUSTTYPE,'0') NOT IN ('13','14')  --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]非NGI客户通过存款人类型判断
           )			                                                       
     WHERE /*(A.GL_ITEM_CODE LIKE '20501%' OR A.GL_ITEM_CODE LIKE '20502%' OR
                   A.GL_ITEM_CODE LIKE '20503%' OR A.GL_ITEM_CODE LIKE '206%' OR
                   A.GL_ITEM_CODE LIKE '21901%' OR A.GL_ITEM_CODE LIKE '21903%' OR
                   A.GL_ITEM_CODE LIKE '202%' OR A.GL_ITEM_CODE LIKE '25102%' OR
                   A.GL_ITEM_CODE LIKE '201%')*/
     (A.GL_ITEM_CODE LIKE '20110202%' --单位一般定期存款
     OR A.GL_ITEM_CODE LIKE '20110203%' --单位大额可转让定期存单
     OR A.GL_ITEM_CODE LIKE '20110204%' --单位协议存款
     OR A.GL_ITEM_CODE LIKE '201107%' --国库定期存款
     OR A.GL_ITEM_CODE LIKE '20110207%' --单位结构性存款
     /*OR B.GL_ITEM_CODE LIKE '21903%'*/
     OR A.GL_ITEM_CODE LIKE '20110205%' --单位通知存款
     OR A.GL_ITEM_CODE LIKE '20110209%' --单位活期保证金存款
     OR A.GL_ITEM_CODE LIKE '20110210%' --单位定期保证金存款
     OR A.GL_ITEM_CODE LIKE '20110201%' --单位活期存款
	 /*[2025-05-27] [蒿蕊] [JLBA202504180011] [黄俊铭]D1092：待结算财政款项取2005财政性存款 D1095增加取2010国库定期存款 D1011取2008和2009 START*/ 
	 OR A.GL_ITEM_CODE LIKE '2005%'     
	 OR A.GL_ITEM_CODE LIKE '2010%'    
	 OR A.GL_ITEM_CODE LIKE '2008%'
	 OR A.GL_ITEM_CODE LIKE '2009%'
	 /*[2025-05-27] [蒿蕊] [JLBA202504180011] [黄俊铭]D1092：待结算财政款项取2005财政性存款 D1095增加取2010国库定期存款 D1011取2008和2009 end */
	 OR A.GL_ITEM_CODE LIKE '201103%' --[2025-12-11] [蒿蕊] [JLBA202507210012] [黄俊铭]增加201103科目
	 )
     AND (C.OPERATE_CUST_TYPE IS NULL OR C.OPERATE_CUST_TYPE <> 'A')
     AND A.ACCT_BALANCE = 0
     AND A.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
     AND A.DATA_DATE = IS_DATE;

  COMMIT;

  INSERT INTO DATACORE_IE_CK_FTYDWCKJB
    SELECT *
      FROM DATACORE_IE_CK_FTYDWCKJB_TMP2 A
     WHERE EXISTS (SELECT 1
              FROM SMTMODS.L_TRAN_TX T
             WHERE T.CUST_ID = A.CUST_ID
               AND T.ACCOUNT_CODE = A.ACCT_NUM
               AND T.DATA_DATE = IS_DATE
               and t.PAYMENT_PROPERTY is null --交易过滤掉支付使用数据
               and t.PAYMENT_ORDER is null --交易过滤掉支付使用数据
            );

  COMMIT;

  --为了加快查询速度，重建索引
  --EXECUTE IMMEDIATE 'ALTER INDEX 索引名 REBUILD';

  --清除目标表中分区数据
  SP_IRS_PARTITIONS(IS_DATE, 'IE_CK_DWCKJC', OI_RETCODE);

  --向目标表插入数据
  INSERT INTO IE_CK_DWCKJC
    (DATADATE --数据日期
    ,
     ACCDEPCODE --存款账户编码
    ,
     DEPAGRSEQNO --存款序号
    ,
     CORPID --内部机构号
    ,
     CUSTID --客户号
    ,
     DEPPRODUCTTYPE --存款产品类别
    ,
     AGREEDEPOTYPE --协议存款类型
    ,
     CONBGNDATE --起始日期
    ,
     CONDUEDATE --到期日期
    ,
     ACTUALDUEDATE --实际终止日期
    ,
     DEPTERMTYPE --存款期限类型
    ,
     PRICINGTYPE --定价基准类型
    ,
     RATETYPE --利率类型
    ,
     REALRATE --实际利率
    ,
     BASERATE --基准利率
    ,
     FLOATFREQ --利率浮动频率
    ,
     LOWESTYIELDRATE --保底收益率
    ,
     HIGHESTYIELDRATE --最高收益率
    ,
     BUSICHANNEL --开户渠道
    ,
     REMOTEDEPFLG --异地存款标志
    ,
     AMTDEPFLG --大小额标志
    ,
     CJRQ --采集日期
    ,
     NBJGH --内部机构号
    ,
     BIZ_LINE_ID --业务条线
    ,
     IRS_CORP_ID --法人机构ID
     )
    SELECT A.DATA_DATE, --数据日期
           A.ACCT_NUM, --存款账户编码
           A.DEPOSIT_NUM, --存款序号
           A.ORG_NUM, --内部机构号
           A.CUST_ID, --客户号
           CASE
            WHEN T.CURR_CD = 'CNY' AND A.PROD_TYPE IN ('D012', 'D0141', 'D0149', 'D031', 'D032') AND
                 ( (A.END_DATE IS NOT NULL AND A.DATA_DATE >= A.END_DATE) OR (A.END_DATE IS NULL AND A.DATA_DATE > A.MATUR_DATE) )
                 AND
                 (CASE WHEN A.DATA_DATE = A.MATUR_DATE THEN F.INT_RATE ELSE A.INT_RATE END) < =0.55 ---add  by   zy  解决村镇问题 黄俊铭给了“=”口径
                 AND
                 (CASE WHEN A.DATA_DATE = A.MATUR_DATE THEN F.PBOC_BASE_RATE
                       WHEN A.GL_ITEM_CODE IN ('20110110', '20110205') AND A.ACCT_CLDATE = A.DATA_DATE THEN F.PBOC_BASE_RATE
                       ELSE A.BASE_RATE END) <= 0.55 THEN
                 'D011'
            ELSE
           A.PROD_TYPE END, --存款产品类别 20240221增加判断
           A.AGREEMENT_TYPE, --协议存款类型
           A.ST_INT_DT, --起始日期
           A.MATUR_DATE, --到期日期
           A.END_DATE, --实际终止日期
           CASE
             /*WHEN A.ACCT_TYPE = '00' THEN



                     '01' --活期*/
             WHEN A.ACCT_TYPE = '0500' OR A.PROD_TYPE = 'D011' OR
                 (T.GL_ITEM_CODE = '20110209' and A.PROD_TYPE in ('D061','D062','D063','D069')) OR    --20240906 单位活期保证金存款期限为活期
                 (T.CURR_CD = 'CNY' AND A.PROD_TYPE IN ('D012', 'D0141', 'D0149', 'D031', 'D032') AND
               ( (A.END_DATE IS NOT NULL AND A.DATA_DATE >= A.END_DATE) OR (A.END_DATE IS NULL AND A.DATA_DATE > A.MATUR_DATE) )
               AND
             (CASE WHEN A.DATA_DATE = A.MATUR_DATE THEN F.INT_RATE ELSE A.INT_RATE END) < =0.55 ---add  by   zy  解决村镇问题 黄俊铭给了“=”口径
               AND
             (CASE WHEN A.DATA_DATE = A.MATUR_DATE THEN F.PBOC_BASE_RATE
                       WHEN A.GL_ITEM_CODE IN ('20110110', '20110205') AND A.ACCT_CLDATE = A.DATA_DATE THEN F.PBOC_BASE_RATE
                       ELSE A.BASE_RATE END) <= 0.55
      ) THEN    --存款产品类别为D011时,存款期限类型为01活期 mdf 20240220 同步20240221存款产品类别判断    --20231211  wxb  活期账户类型0500
     '01' --活期
      WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) > 60 THEN
              '16' --5年以上
             WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) = 60 THEN
              '15' --5年
             WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) > 36 THEN
              '14' --3年-5年
             WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) = 36 THEN
              '13' --3年
             WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) > 24 THEN
              '12' --2年-3年
             WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) = 24 THEN
              '11' --2年
             WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) > 12 THEN
              '10' --1年-2年
             WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) = 12 THEN
              '09' --1年
             WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) > 6 THEN
              '08' --6-12个月
             WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) = 6 THEN
              '07' --6个月
             WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) > 3 THEN
              '06' --3-6个月
             WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) = 3 THEN
              '05' --3
             WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) > 1 THEN
              '04' --1-3个月
             WHEN MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2) = 1 THEN
              '03' --1个月
             ELSE
              '02'
           END AS DEPTERMTYPE, --存款期限类型
           A.DJJZ_TYPE, --定价基准类型
           A.INT_RATE_TYP, --利率类型
           /* A.INT_RATE, --实际利率
           A.BASE_RATE, --基准利率*/
           CASE
             WHEN A.DATA_DATE = A.MATUR_DATE THEN
              F.INT_RATE
             ELSE
              A.INT_RATE
           END AS INT_RATE, --实际利率
           CASE
             WHEN A.DATA_DATE = A.MATUR_DATE THEN
              F.PBOC_BASE_RATE
             WHEN A.GL_ITEM_CODE IN ('20110110', '20110205') AND
                  A.ACCT_CLDATE = A.DATA_DATE THEN
              F.PBOC_BASE_RATE --ADF BY 20230829 黄俊铭口径，通知存款当天销户，取昨天的人行基准利率
             ELSE
              A.BASE_RATE
           END AS BASE_RATE, --基准利率
           CASE WHEN A.INT_RATE_TYP = 'RF01' THEN ''
             ELSE A.LLFD_RATE
               END            , --利率浮动频率  存款利率类型字段为RF01-固定利率时，利率浮动频率字段应为空值 20240220
           A.GUARANTEED_RETURN_RATE, --保底收益率
           A.MAX_YILED_RATE, --最高收益率
           A.OPEN_CHANNEL, --开户渠道
           A.REMOTE_DEPOSIT_FLAG, --异地存款标志
           A.ACCT_BALANCE_FLAG, --大小额标志
           IS_DATE, --采集日期
           A.ORG_NUM, --内部机构号
           '99', --业务条线
     CASE WHEN  A.ORG_NUM LIKE '51%' THEN '510000'
          WHEN  A.ORG_NUM LIKE '52%' THEN '520000'
          WHEN  A.ORG_NUM LIKE '53%' THEN '530000'
          WHEN  A.ORG_NUM LIKE '54%' THEN '540000'
          WHEN  A.ORG_NUM LIKE '55%' THEN '550000'
          WHEN  A.ORG_NUM LIKE '56%' THEN '560000'
          WHEN  A.ORG_NUM LIKE '57%' THEN '570000'
          WHEN  A.ORG_NUM LIKE '58%' THEN '580000'
          WHEN  A.ORG_NUM LIKE '59%' THEN '590000'
          WHEN  A.ORG_NUM LIKE '60%' THEN '600000'
           ELSE '990000' END --法人机构ID
      FROM DATACORE_IE_CK_FTYDWCKJB A
      left join smtmods.l_acct_deposit f ---定期当天到期取定期利率，实际到期是到期日字段的前一天，到期日字段是系统到期日。
        on a.acct_num = f.acct_num
       and a.deposit_num = f.deposit_num
       and f.data_date = VS_YES_DATE
      left join smtmods.l_acct_deposit T ---判断存款科目为20110209单位活期保证金存款的明细，将存款期限类型给到-01活期
        on a.acct_num = T.acct_num
       and a.deposit_num = T.deposit_num
       and T.data_date = IS_DATE;

  /*INNER JOIN DATACORE_IE_CK_FTYDWCKJB_TMP1 B
     ON A.CUST_ID = B.CUST_ID
  WHERE A.ORG_NUM NOT LIKE '0215%'*/

  COMMIT;

  UPDATE IE_CK_DWCKJC
     SET BASERATE = '1.35000'
   WHERE cjrq = VS_TEXT
     AND REALRATE = '1.25000'
     AND ACCDEPCODE = '8916662601000001_1';
  --待维护单ok，此段注释掉

  COMMIT;

  ----------------------------------------------------------------------------------------------------------------
  OI_RETCODE := 0; --设置异常状态为0 成功状态

  --返回中文描述
  OI_RETCODE2 := '成功!';

  -- 结束日志
  VS_STEP := 'END';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);

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

