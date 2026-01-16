CREATE OR REPLACE PROCEDURE BSP_SP_IRS_DK_WTDKYE(IS_DATE    IN VARCHAR2,
                                                OI_RETCODE OUT INTEGER,
                                               OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_DK_WTDKYE
  -- 用途:生成接口表 IE_DK_WTDKYE 委托贷款余额表
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT 20210524 chm
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE      NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT           VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  --VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
  --NUM               INTEGER;

BEGIN
  VS_TEXT      := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  --VS_LAST_TEXT := TO_CHAR(LAST_DAY(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'),-1)),'YYYYMMDD'); --上月月末
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_DK_WTDKYE';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);

/* EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_DK_WTDKYE_TMP1';
 INSERT INTO  DATACORE_IE_DK_WTDKYE_TMP1
 SELECT DISTINCT CUST_ID
 FROM SMTMODS.L_CUST_P
 WHERE DATA_DATE =IS_DATE
 AND ORG_NUM NOT LIKE '0215%';
 COMMIT;
 INSERT INTO DATACORE_IE_DK_WTDKYE_TMP1
 SELECT DISTINCT CUST_ID
 FROM SMTMODS.L_CUST_C
 WHERE DATA_DATE =IS_DATE
 AND ORG_NUM NOT LIKE '0215%';
 COMMIT;*/




  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_DK_WTDKYE';
INSERT INTO DATACORE_IE_DK_WTDKYE
  (DATADATE, --数据日期
   LOANNUM, --贷款借据编号
   CUSTID, --借款人客户号
   TRUSTORCUSTID, --委托人客户号
   CORPID, --内部机构号
   MONEYSYMB, --币种
   BALANCE, --贷款余额
   CJRQ, --
   NBJGH, --内部机构号
   BIZ_LINE_ID, --业务条线
   VERIFY_STATUS, --校验状态
   BSCJRQ --报送周期
   )
  SELECT /*+ PARALLEL(8)*/
   VS_TEXT,
   T.LOAN_NUM, --委托贷款拮据编码
   T.CUST_ID, --借款人客户号
   B.TRUSTOR_ID, --委托人客户号
   T.ORG_NUM, --机构号
   t.CURR_CD, --币种
   T.LOAN_ACCT_BAL, --贷款余额
   IS_DATE,
   T.ORG_NUM,
   '99',
   '',
   ''
    FROM SMTMODS.L_ACCT_LOAN T
    LEFT JOIN SMTMODS.L_ACCT_LOAN T1 
        ON T.LOAN_NUM=T1.LOAN_NUM
       AND T1.DATA_DATE=TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1),'YYYYMMDD')
       --关联前一天数据，取前一天贷款余额大于0当天等于0的
    LEFT JOIN SMTMODS.L_ACCT_LOAN_ENTRUST B --委托贷款补充信息表
          ON B.DATA_DATE = IS_DATE
          AND T.LOAN_NUM = B.LOAN_NUM
   WHERE T.DATA_DATE = IS_DATE
     AND (T.LOAN_ACCT_BAL > 0 OR   (T.LOAN_ACCT_BAL=0 AND T1.LOAN_ACCT_BAL>0 ))
     --  存在之前放款当天结清的数据，贷款余额为0 20231207wxb
     AND T.ITEM_CD LIKE '3020%' --委托贷款
     --AND T.HXRQ IS NULL--不取核销数据
     AND T.CANCEL_FLG = 'N'
   AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
     --AND T.COD_PROD <> '10301002' --个人公积金委托贷款
     --AND T.ORG_NUM NOT LIKE '0215%'
     AND T.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
     --AND EXISTS (SELECT 1 FROM DATACORE_IE_DK_WTDKYE_TMP1 F WHERE B.TRUSTOR_ID = F.CUST_ID )
     ;
COMMIT;

     SP_IRS_PARTITIONS(IS_DATE,'IE_DK_WTDKYE',OI_RETCODE);
  INSERT INTO IE_DK_WTDKYE
    (DATADATE,--数据日期
     LOANNUM,--贷款借据编号
     CUSTID,--借款人客户号
     TRUSTORCUSTID,--委托人客户号
     CORPID,--内部机构号
     MONEYSYMB,--币种
     BALANCE,--贷款余额
     CJRQ,--
     NBJGH,--内部机构号
     REPORT_ID,--报送id
     BIZ_LINE_ID,--业务条线
     VERIFY_STATUS,--校验状态
     BSCJRQ,--报送周期
     IRS_CORP_ID  --法人机构ID
     )
    SELECT /*+ PARALLEL(8)*/
    DATADATE,--数据日期
     LOANNUM,--贷款借据编号
     CUSTID,--借款人客户号
     TRUSTORCUSTID,--委托人客户号
     CORPID,--内部机构号
     MONEYSYMB,--币种
     BALANCE,--贷款余额
     CJRQ,--
     NBJGH,--内部机构号
     REPORT_ID,--报送id
     BIZ_LINE_ID,--业务条线
     VERIFY_STATUS,--校验状态
     BSCJRQ,--报送周期
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
      FROM DATACORE_IE_DK_WTDKYE T
      --WHERE  T.DATADATE = IS_DATE
      ;
COMMIT;
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

