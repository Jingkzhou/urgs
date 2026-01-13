CREATE OR REPLACE PROCEDURE BSP_SP_IRS_TY_TYCKFS(IS_DATE    IN VARCHAR2,
                                                OI_RETCODE OUT INTEGER,
                                               OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_FTY_FTYDWDKJCXXB
  -- 用途:生成接口表 JS_201_CLGRDK 存量个人贷款信息
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT 20200819
  --    MOD BY YANLINGBO AT 20200819
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE      NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT           VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
  NUM               INTEGER;

BEGIN
  VS_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  VS_LAST_TEXT := TO_CHAR(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1),'YYYYMMDD');
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_TY_TYCKFS';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------

EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_TY_TYCKFS ';

INSERT INTO  DATACORE_IE_TY_TYCKFS
(
datadate         --数据日期
,accdepcode       --存款账户编码
,corpid           --内部机构号
,custid           --客户号
,serialno         --交易流水号
,transactiondate  --交易日期
,moneysymb        --币种
,realrate         --实际利率
,baserate         --基准利率
,transamt         --发生金额
,transdirect      --交易方向
)
SELECT
VS_TEXT            --数据日期
,A.ref_num           --存款账户编码
, A.org_num           --内部机构号
,A.Cust_Id                --客户号    20240909  新增同业客户号取数
, T.ref_num           --交易流水号
,VS_TEXT       --交易日期                 --20230106    交易表存在时点问题，将交易日期默认数据日期
, T.CURR_CD            --币种(买入币种)
, T.real_int_rat     --实际利率
,''               --基准利率
, T.AMOUNT              --发生金额
, T.TRADE_DIRECT            --交易方向 0结清 1 发生
FROM SMTMODS.L_TRAN_FUND_FX t
LEFT JOIN SMTMODS.L_ACCT_FUND_MMFUND A
ON T.CONTRACT_NUM = A.ACCT_NUM
AND A.DATA_DATE = IS_DATE
WHERE T.DATA_DATE=IS_DATE
--AND substr(item_cd,'1','3') in ('114','234')
--AND substr(item_cd,'1','3') in ('114','234')
/*AND substr(item_cd,'1','4') in ('1011'   --存放同业
                               ,'2012')  --同业存放*/
AND (T.ITEM_CD LIKE '101102%'        --存放同业定期款项
  OR T.ITEM_CD LIKE '201202%'      --同业存放定期款项
  OR T.ITEM_CD LIKE '201203%')     --同业保证金存款
AND T.AMOUNT IS NOT NULL
and T.AMOUNT<>0
and T.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
--AND (TO_CHAR(T.MATURITY_DT,'YYYYMMDD') >=IS_DATE OR T.MATURITY_DT IS NULL )
AND (TO_CHAR(A.MATURE_DATE,'YYYYMMDD') >=IS_DATE OR A.MATURE_DATE IS NULL ) --MDF BY 20230809 同基础表保持一致，避免校验不通过
--AND T.ORG_NUM NOT LIKE '0215%'
AND T.TRADE_TYPE2_DESC NOT LIKE '%结息%'   --add by haorui 20250107 JLBF202412130001
AND T.TRADE_TYPE2_DESC NOT LIKE '%利息%'   --add by haorui 20250107 JLBF202412130001
;

COMMIT;

INSERT INTO  DATACORE_IE_TY_TYCKFS
(
datadate         --数据日期
,accdepcode       --存款账户编码
,corpid           --内部机构号
,custid           --客户号
,serialno         --交易流水号
,transactiondate  --交易日期
,moneysymb        --币种
,realrate         --实际利率
,baserate         --基准利率
,transamt         --发生金额
,transdirect      --交易方向
)
SELECT
VS_TEXT            --数据日期
,A.ACCT_NUM           --存款账户编码
,'510001'           --内部机构号
,A.Cust_Id                --客户号    20240909  新增同业客户号取数
, T.ref_num           --交易流水号
,VS_TEXT       --交易日期               --20230106    交易表存在时点问题，将交易日期默认数据日期
, T.CURR_CD            --币种(买入币种)
, T.real_int_rat     --实际利率
,''               --基准利率
, T.AMOUNT              --发生金额
, T.TRADE_DIRECT            --交易方向 0结清 1 发生
FROM SMTMODS.L_TRAN_FUND_FX t
LEFT JOIN SMTMODS.L_ACCT_FUND_MMFUND A
ON T.CONTRACT_NUM = A.ACCT_NUM
AND A.DATA_DATE = IS_DATE
WHERE  T.DATA_DATE=IS_DATE
--AND substr(item_cd,'1','3') in ('114','234')
/*AND substr(item_cd,'1','4') in ('1011'   --存放同业
                               ,'2012')  --同业存放*/
AND ( T.ITEM_CD LIKE '101102%'        --存放同业定期款项
  OR  T.ITEM_CD LIKE '201202%'      --同业存放定期款项
  OR  T.ITEM_CD LIKE '201203%')     --同业保证金存款
AND T. AMOUNT IS NOT NULL
and  T.AMOUNT<>0
and  T.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
--AND (TO_CHAR( T.MATURITY_DT,'YYYYMMDD') >=IS_DATE OR  T.MATURITY_DT IS NULL )
AND (TO_CHAR( A.MATURE_DATE,'YYYYMMDD') >=IS_DATE OR  A.MATURE_DATE IS NULL ) --MDF BY 20230809
AND T.CONTRACT_NUM IN ('5010200000024026','2011200000000018')
AND T.TRADE_TYPE2_DESC NOT LIKE '%结息%'  --add by haorui 20250107 JLBF202412130001
AND T.TRADE_TYPE2_DESC NOT LIKE '%利息%'  --add by haorui 20250107 JLBF202412130001
;

COMMIT;

SP_IRS_PARTITIONS_INC(IS_DATE,'IE_TY_TYCKFS',OI_RETCODE);

INSERT INTO  IE_TY_TYCKFS_INC
(datadate         --数据日期
,accdepcode       --存款账户编码
,corpid           --内部机构号
,custid           --客户号
,serialno         --交易流水号
,transactiondate  --交易日期
,moneysymb        --币种
,realrate         --实际利率
,baserate         --基准利率
,transamt         --发生金额
,transdirect      --交易方向
,cjrq  --采集日期
,nbjgh --内部机构号
,biz_line_id, --业务条线
DIFF_TYPE,    --增量标识
     LAST_DATA_DATE,    --上一数据时点
     IRS_CORP_ID        --法人机构ID
)
select
datadate         --数据日期
,accdepcode       --存款账户编码
,corpid           --内部机构号
,custid           --客户号
,serialno         --交易流水号
,transactiondate  --交易日期
,moneysymb        --币种
,realrate         --实际利率
,baserate         --基准利率
,transamt         --发生金额
,transdirect      --交易方向
,IS_DATE  --采集日期
,corpid --内部机构号
,'99', --业务条线
 '1',             --增量标识
     TO_CHAR(TO_DATE(IS_DATE,'YYYYMMDD')-1,'YYYYMMDD'),   --上一数据时点
     CASE WHEN  A.CORPID LIKE '51%' THEN '510000'
          WHEN  A.CORPID LIKE '52%' THEN '520000'
          WHEN  A.CORPID LIKE '53%' THEN '530000'
          WHEN  A.CORPID LIKE '54%' THEN '540000'
          WHEN  A.CORPID LIKE '55%' THEN '550000'
          WHEN  A.CORPID LIKE '56%' THEN '560000'
          WHEN  A.CORPID LIKE '57%' THEN '570000'
          WHEN  A.CORPID LIKE '58%' THEN '580000'
          WHEN  A.CORPID LIKE '59%' THEN '590000'
          WHEN  A.CORPID LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
from DATACORE_IE_TY_TYCKFS A
--WHERE A.CORPID NOT LIKE '5100%'
;
COMMIT;

COMMIT;

INSERT INTO  IE_TY_TYCKFS_INC
(datadate         --数据日期
,accdepcode       --存款账户编码
,corpid           --内部机构号
,custid           --客户号
,serialno         --交易流水号
,transactiondate  --交易日期
,moneysymb        --币种
,realrate         --实际利率
,baserate         --基准利率
,transamt         --发生金额
,transdirect      --交易方向
,cjrq  --采集日期
,nbjgh --内部机构号
,biz_line_id, --业务条线
DIFF_TYPE,    --增量标识
     LAST_DATA_DATE,    --上一数据时点
     IRS_CORP_ID        --法人机构ID
)
select
datadate         --数据日期
,accdepcode       --存款账户编码
,corpid           --内部机构号
,custid           --客户号
,serialno         --交易流水号
,transactiondate  --交易日期
,moneysymb        --币种
,realrate         --实际利率
,baserate         --基准利率
,transamt         --发生金额
,transdirect      --交易方向
,IS_DATE  --采集日期
,corpid --内部机构号
,'99', --业务条线
 '1',             --增量标识
     TO_CHAR(TO_DATE(IS_DATE,'YYYYMMDD')-1,'YYYYMMDD'),   --上一数据时点
              '510000'--法人机构ID
from DATACORE_IE_TY_TYCKFS A
WHERE A.CORPID LIKE '5100%'
 AND A.ACCDEPCODE = '60599235000000437_1' ;
  -------------------------------------------------------------------------
  OI_RETCODE := 0; --设置异常状态为0 成功状态
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
    --插入日志表，记录错误
    --返回中文描述

    OI_RETCODE2 := SUBSTR(SQLERRM, 1, 200);
    SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
END;
/

