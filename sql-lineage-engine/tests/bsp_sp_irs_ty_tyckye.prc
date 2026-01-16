CREATE OR REPLACE PROCEDURE BSP_SP_IRS_TY_TYCKYE(IS_DATE    IN VARCHAR2,
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
  VS_PROCEDURE_NAME := 'SP_IRS_TY_TYCKYE';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------

EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_TY_TYCKYE ';

INSERT INTO  DATACORE_IE_TY_TYCKYE
(
datadate --数据日期
,accdepcode --存款账户编码
,corpid  --内部机构号
,custid  --客户号
,MONEYSYMB  --币种
,BALANCE    --余额
)
SELECT
VS_TEXT    --数据日期
,ref_num   --存款账户编码
,org_num   --内部机构号
,T.CUST_ID        --客户号    20240909  新增同业客户号取数
,CURR_CD   --币种
,BALANCE   --余额
FROM SMTMODS.L_ACCT_FUND_MMFUND t
/*LEFT JOIN L_TY_CUSTID_INFO@SUPER f
ON T.CUST_ID=F.CUST_NM*/
WHERE DATA_DATE=IS_DATE
--AND substr(gl_item_code,'1','3') in ('114','234')
AND substr(gl_item_code,'1','4') in ('1011','2012')
/*AND (substr(gl_item_code,'1','4') in ('1011')   --存放同业
     OR substr(gl_item_code,'1','6') in ('201202','201203'))--同业存放*/

--AND (TO_CHAR(mature_date,'YYYYMMDD') >=IS_DATE OR mature_date IS NULL )
AND TO_CHAR(mature_date,'YYYYMMDD') >=IS_DATE  --modify by haorui 删除OR mature_date IS NULL 卡掉历史无效数据
AND CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
--AND T.ORG_NUM NOT LIKE '0215%'
;
COMMIT;

/*INSERT INTO  DATACORE_IE_TY_TYCKYE
(
datadate --数据日期
,accdepcode --存款账户编码
,corpid  --内部机构号
,custid  --客户号
,MONEYSYMB  --币种
,BALANCE    --余额
)
SELECT
VS_TEXT    --数据日期
,ACCT_NUM   --存款账户编码
,'510001'   --内部机构号
,''        --客户号
,CURR_CD   --币种
,BALANCE   --余额
FROM SMTMODS.L_ACCT_FUND_MMFUND t
\*LEFT JOIN L_TY_CUSTID_INFO@SUPER f
ON T.CUST_ID=F.CUST_NM*\
WHERE DATA_DATE=IS_DATE
--AND substr(gl_item_code,'1','3') in ('114','234')
AND substr(gl_item_code,'1','4') in ('1011','2012')
\*AND (substr(gl_item_code,'1','4') in ('1011')   --存放同业
     OR substr(gl_item_code,'1','6') in ('201202','201203'))--同业存放*\
AND (TO_CHAR(mature_date,'YYYYMMDD') >=IS_DATE OR mature_date IS NULL )
AND CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
--AND T.ACCT_NUM IN('5010200000024026','2011200000000018')
\*AND T.ACCT_NUM IN('60599235000000437_1')*\
--20231109王晓彬AND T.ACCT_NUM IN('60599235000000437_1')删除这个条件
;
COMMIT;*/

 SP_IRS_PARTITIONS(IS_DATE,'IE_TY_TYCKYE',OI_RETCODE);


INSERT INTO  IE_TY_TYCKYE
(datadate --数据日期
,accdepcode --存款账户编码
,corpid  --内部机构号
,custid  --客户号
,MONEYSYMB   --币种
,BALANCE    --余额
,cjrq  --采集日期
,nbjgh --内部机构号
,biz_line_id --业务条线
,IRS_CORP_ID --法人机构ID
)
select
datadate --数据日期
,accdepcode --存款账户编码
,corpid  --内部机构号
,custid  --客户号
,MONEYSYMB --币种
,BALANCE   --余额
,IS_DATE  --采集日期
,corpid --内部机构号
,'99' --业务条线
,CASE WHEN A.CORPID LIKE '51%' THEN '510000'
          WHEN A.CORPID LIKE '52%' THEN '520000'
          WHEN A.CORPID LIKE '53%' THEN '530000'
          WHEN A.CORPID LIKE '54%' THEN '540000'
          WHEN A.CORPID LIKE '55%' THEN '550000'
          WHEN A.CORPID LIKE '56%' THEN '560000'
          WHEN A.CORPID LIKE '57%' THEN '570000'
          WHEN A.CORPID LIKE '58%' THEN '580000'
          WHEN A.CORPID LIKE '59%' THEN '590000'
          WHEN A.CORPID LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
from DATACORE_IE_TY_TYCKYE A
--WHERE A.CORPID NOT LIKE '5100%'
WHERE A.CORPID NOT IN ('550005','550013')--add by wxb 20240221 沧县这两个机构已撤并
;

COMMIT;
/*
INSERT INTO  IE_TY_TYCKYE
(datadate --数据日期
,accdepcode --存款账户编码
,corpid  --内部机构号
,custid  --客户号
,MONEYSYMB   --币种
,BALANCE    --余额
,cjrq  --采集日期
,nbjgh --内部机构号
,biz_line_id --业务条线
,IRS_CORP_ID --法人机构ID
)
select
datadate --数据日期
,accdepcode --存款账户编码
,corpid  --内部机构号
,custid  --客户号
,MONEYSYMB --币种
,BALANCE   --余额
,IS_DATE  --采集日期
,corpid --内部机构号
,'99' --业务条线
,'510000'  --法人机构ID
from DATACORE_IE_TY_TYCKYE A
WHERE A.CORPID LIKE '5100%'
\* AND A.ACCDEPCODE = '60599235000000437_1'*\ ;
--20231109wxb 根据需求删除这个条件AND A.ACCDEPCODE = '60599235000000437_1

COMMIT;*/
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

