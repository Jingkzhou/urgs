CREATE OR REPLACE PROCEDURE BSP_SP_IRS_DK_WTDKFK(IS_DATE    IN VARCHAR2,
                                                OI_RETCODE OUT INTEGER,
                                               OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_DK_WTDKFK
  -- 用途:生成接口表 IE_DK_WTDKFK 委托贷款放款表
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
  VS_PROCEDURE_NAME := 'SP_IRS_DK_WTDKFK';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);


/* EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_DK_WTDKFK_TMP1';

 INSERT INTO DATACORE_IE_DK_WTDKFK_TMP1
 SELECT DISTINCT CUST_ID
 FROM SMTMODS.L_CUST_P
 WHERE DATA_DATE =IS_DATE
 AND ORG_NUM NOT LIKE '0215%';
 COMMIT;
 INSERT INTO DATACORE_IE_DK_WTDKFK_TMP1
 SELECT DISTINCT CUST_ID
 FROM SMTMODS.L_CUST_C
 WHERE DATA_DATE =IS_DATE
 AND ORG_NUM NOT LIKE '0215%';
 COMMIT;*/


EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_L_ACCT_LOAN_WT';
--发放

INSERT INTO DATACORE_L_ACCT_LOAN_WT
  (LOAN_NUM, --贷款编号（借据编号）
   DRAWDOWN_AMT, --贷款发生额
   ACCT_NUM, --合同号
   ORG_NUM, --机构号
   CURR_CD, --币种
   SERIAL_NO, --交易流水号
   DATA_DATE --日期
   )
  SELECT A.LOAN_NUM,
         SUM(A.DRAWDOWN_AMT),
         A.ACCT_NUM,
         A.ORG_NUM,
         A.CURR_CD,
         A.LOAN_NUM || TO_CHAR(A.DRAWDOWN_DT, 'YYYYMMDD') AS SERIAL_NO,
         IS_DATE
    FROM SMTMODS.L_ACCT_LOAN A
   WHERE A.DATA_DATE = IS_DATE
     AND A.LOAN_ACCT_BAL > 0
     AND A.ITEM_CD LIKE '3020%'
     --AND A.HXRQ IS NULL
     AND A.CANCEL_FLG = 'N'
     AND A.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
     AND A.DRAWDOWN_DT = TO_DATE(IS_DATE,'YYYYMMDD') --只取当天放款
   AND A.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
     --AND A.COD_PROD <> '10301002' --个人公积金委托贷款
   GROUP BY A.LOAN_NUM, A.ACCT_NUM, A.ORG_NUM, A.CURR_CD, A.DRAWDOWN_DT;

   COMMIT;

/*--收回
   INSERT INTO DATACORE_L_ACCT_LOAN_WT
  (LOAN_NUM, --贷款编号（借据编号）
   DRAWDOWN_AMT, --贷款发生额
   ACCT_NUM, --合同号
   ORG_NUM, --机构号
   CURR_CD, --币种
   SERIAL_NO, --交易流水号
   DATA_DATE --日期
   )
     SELECT  A.LOAN_NUM,
           sum( NVL(B.PAY_AMT,0)),
           A.ACCT_NUM,
           A.ORG_NUM,
           A.CURR_CD,
           TX_NO,
           IS_DATE
  FROM L_ACCT_LOAN@super A
  INNER JOIN L_TRAN_LOAN_PAYM@super B
  ON  A.LOAN_NUM = B.LOAN_NUM
  AND B.DATA_DATE= IS_DATE
  AND B.REPAY_DT= IS_DATE
  WHERE A.DATA_DATE = IS_DATE
  --AND A.LOAN_ACCT_BAL > 0
  AND A.ITEM_CD LIKE '40602%' --委托贷款
  AND A.HXRQ IS NULL --不取核销数据
  AND A.COD_PROD <> '10301002' --个人公积金委托贷款
  AND B.PAY_AMT <> 0
  GROUP BY A.LOAN_NUM, A.ACCT_NUM, A.ORG_NUM, A.CURR_CD, TX_NO;


COMMIT;
*/

EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_DK_WTDKFK';
INSERT INTO DATACORE_IE_DK_WTDKFK
  (DATADATE, --数据日期
   LOANNUM, --贷款借据编号
   CUSTID, --借款人客户号
   TRUSTORCUSTID, --委托人客户号
   CORPID, --内部机构号
   SERIALNO, --交易流水号
   TRANSACTIONDATE, --交易日期
   MONEYSYMB, --币种
   TRANSAMT, --发生金额
   BASERATE, --基准利率
   REALRATE, --实际利率
   CJRQ, --采集日期
   NBJGH, --内部机构号
   REPORT_ID, --报送id
   BIZ_LINE_ID, --业务条线
   VERIFY_STATUS, --校验状态
   BSCJRQ --报送周期
   )
  SELECT /*+ PARALLEL(8)*/
   VS_TEXT, --数据日期
   B.LOAN_NUM, --贷款借据编号
   B.CUST_ID, --借款人客户号
   C.TRUSTOR_ID, --委托人客户号
   B.ORG_NUM, --内部机构号
   A.SERIAL_NO, --交易流水号
   TO_CHAR(B.DRAWDOWN_DT, 'YYYY-MM-DD'), --交易日期
   B.CURR_CD, --币种
   A.DRAWDOWN_AMT, --发生金额
   /*CASE WHEN   SUBSTR (B.INT_RATE_TYP,1,1) ='F'  THEN 0 --固定利率
          ELSE B.BASE_INT_RAT END, --基准利率,--基准利率*/
   T.BASE_INT_RAT, --基准利率
   B.REAL_INT_RAT, --实际利率
    IS_DATE,
   A.ORG_NUM,
   SYS_GUID(),
   '99',
   '',
   ''
    FROM DATACORE_L_ACCT_LOAN_WT A
   INNER JOIN SMTMODS.L_ACCT_LOAN B
      ON A.LOAN_NUM = B.LOAN_NUM
    LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T
    ON B.ACCT_NUM = T.CONTRACT_NUM
    AND T.DATA_DATE = IS_DATE
   LEFT JOIN SMTMODS.L_ACCT_LOAN_ENTRUST C --委托贷款补充信息表
          ON A.LOAN_NUM = C.LOAN_NUM
          AND C.DATA_DATE = IS_DATE
   WHERE B.DATA_DATE = IS_DATE
     --AND  B.ORG_NUM NOT LIKE '0215%'
     --AND EXISTS (SELECT 1 FROM DATACORE_IE_DK_WTDKFK_TMP1 F WHERE B.WTRCUSTID = F.CUST_ID )
           ;
COMMIT;

     SP_IRS_PARTITIONS_INC(IS_DATE,'IE_DK_WTDKFK',OI_RETCODE);
  INSERT INTO IE_DK_WTDKFK_INC
    (DATADATE, --数据日期
   LOANNUM, --贷款借据编号
   CUSTID, --借款人客户号
   TRUSTORCUSTID, --委托人客户号
   CORPID, --内部机构号
   SERIALNO, --交易流水号
   TRANSACTIONDATE, --交易日期
   MONEYSYMB, --币种
   TRANSAMT, --发生金额
   BASERATE, --基准利率
   REALRATE, --实际利率
   CJRQ, --采集日期
   NBJGH, --内部机构号
   BIZ_LINE_ID, --业务条线
   VERIFY_STATUS, --校验状态
   BSCJRQ, --报送周期
   DIFF_TYPE,    --增量标识
   LAST_DATA_DATE,    --上一数据时点
   IRS_CORP_ID --法人机构ID
     )
    SELECT
    DATADATE, --数据日期
   LOANNUM, --贷款借据编号
   CUSTID, --借款人客户号
   TRUSTORCUSTID, --委托人客户号
   CORPID, --内部机构号
   SERIALNO, --交易流水号
   TRANSACTIONDATE, --交易日期
   MONEYSYMB, --币种
   TRANSAMT, --发生金额
   BASERATE, --基准利率
   REALRATE, --实际利率
   CJRQ, --采集日期
   NBJGH, --内部机构号
   BIZ_LINE_ID, --业务条线
   VERIFY_STATUS, --校验状态
   BSCJRQ, --报送周期
   '1',             --增量标识
     TO_CHAR(TO_DATE(IS_DATE,'YYYYMMDD')-1,'YYYYMMDD'),   --上一数据时点
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
   FROM DATACORE_IE_DK_WTDKFK T;
   --WHERE EXISTS (SELECT 1 FROM DATACORE_IE_DK_WTDKFK_TMP1 F WHERE T.TRUSTORCUSTID = F.CUST_ID )

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

