CREATE OR REPLACE PROCEDURE BSP_SP_IRS_DK_WTDKJC(IS_DATE     IN VARCHAR2,
                                                 OI_RETCODE  OUT INTEGER,
                                                 OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_DK_WTDKJC
  -- 用途:生成接口表 IRS_DK_WTDKJC 全量-委托贷款基础信息表
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT 20210524 chm

  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT      VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  --VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
  --NUM               INTEGER;

BEGIN
  VS_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  --VS_LAST_TEXT := TO_CHAR(LAST_DAY(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'),-1)),'YYYYMMDD'); --上月月末
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_DK_WTDKJC';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);

  /* EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_DK_WTDKJC_TMP1';
  INSERT INTO  DATACORE_IE_DK_WTDKJC_TMP1
  SELECT DISTINCT CUST_ID
  FROM SMTMODS.L_CUST_P
  WHERE DATA_DATE =IS_DATE
  AND ORG_NUM NOT LIKE '0215%';
  COMMIT;
  INSERT INTO DATACORE_IE_DK_WTDKJC_TMP1
  SELECT DISTINCT CUST_ID
  FROM SMTMODS.L_CUST_C
  WHERE DATA_DATE =IS_DATE
  AND ORG_NUM NOT LIKE '0215%';
  COMMIT;*/

  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_DK_WTDKJC';
  INSERT INTO DATACORE_IE_DK_WTDKJC
    (DATADATE, --数据日期
     CONTRACTNUM, --贷款合同编码
     LOANNUM, --贷款借据编号
     CUSTID, --借款人客户号
     TRUSTORCUSTID, --委托人客户号
     CORPID, --内部机构号
     DRAWDOWNDT, --贷款发放日期
     MATURITYDT, --原始到期日期
     ACTUALDUEDATE, --实际终止日期
     LOANTERMTYPE, --贷款期限类型
     RATETYPE, --利率类型
     PRICINGTYPE, --定价基准类型
     BASERATE, --基准利率
     REALRATE, --实际利率
     FLOATFREQ, --利率浮动频率
     LOANPURPOSECD, --贷款实际投向
     CJRQ, --采集日期
     NBJGH, --内部机构号
     BIZ_LINE_ID, --业务条线
     VERIFY_STATUS, --校验状态
     BSCJRQ --报送周期
     )
    SELECT VS_TEXT,
           T.ACCT_NUM, --贷款合同编码
           T.LOAN_NUM, --委托贷款拮据编码
           T.CUST_ID, --借款人客户号
           B.TRUSTOR_ID, --委托人客户号
           T.ORG_NUM, --机构号
           TO_CHAR(T.DRAWDOWN_DT, 'YYYY-MM-DD'), --委托贷款发放日期
           TO_CHAR(T.MATURITY_DT, 'YYYY-MM-DD'), --委托贷款到期日期
           TO_CHAR(T.FINISH_DT, 'YYYY-MM-DD'), --委托贷款实际到期日期
           months_between(T.MATURITY_DT, T.DRAWDOWN_DT), --贷款期限类型
           CASE
             WHEN T.INT_RATE_TYP = 'F' THEN
              'RF01'
             ELSE
              'RF02'
           END INT_RATE_TYPE, -- 利率类型
           CASE
             WHEN T.PRICING_BASE_TYPE = 'A01' THEN
              'TR01'
             WHEN T.PRICING_BASE_TYPE = 'A0201' THEN
              'TR02'
             WHEN T.PRICING_BASE_TYPE = 'A0202' THEN
              'TR03'
             WHEN T.PRICING_BASE_TYPE = 'A0203' THEN
              'TR04'
             WHEN T.PRICING_BASE_TYPE = 'C' THEN
              'TR05'
             WHEN T.PRICING_BASE_TYPE = 'D' THEN
              'TR06'
             WHEN T.PRICING_BASE_TYPE = 'B01' THEN
              'TR07'
             WHEN T.PRICING_BASE_TYPE = 'B02' THEN
              'TR08'
             WHEN T.PRICING_BASE_TYPE = 'E' THEN
              'TR09'
             ELSE
              'TR99'
           END AS PRICINGTYPE, --定价基准类型
           /*  CASE WHEN   SUBSTR (T.INT_RATE_TYP,1,1) ='F'  THEN 0 --固定利率
           ELSE T.BASE_INT_RAT END, --基准利率*/
           A.BASE_INT_RAT, --基准利率
           T.REAL_INT_RAT, --实际利率
           CASE
             WHEN SUBSTR(T.INT_RATE_TYP, 1, 1) = 'F' THEN
              '' --固定利率
             WHEN T.INT_RATE_TYP = 'L0' THEN
              '01' --浮动利率-按日
             WHEN T.INT_RATE_TYP = 'L1' THEN
              '02' --浮动利率-按周
             WHEN T.INT_RATE_TYP = 'L2' THEN
              '03' --浮动利率-按月
             WHEN T.INT_RATE_TYP = 'L3' THEN
              '04' --浮动利率-按季
             WHEN T.INT_RATE_TYP = 'L4' THEN
              '05' --浮动利率-按半年
             WHEN T.INT_RATE_TYP = 'L5' THEN
              '06' --浮动利率-按年
             ELSE
              '99'
           END, --其他--利率浮动频率  --利率浮动频率
           CASE
             WHEN T.LOAN_PURPOSE_CD = '#' THEN
              ''
             ELSE
              SUBSTRB(T.LOAN_PURPOSE_CD, 1, 4)
           END, --贷款实际投向
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
      LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT A
        ON T.ACCT_NUM = A.CONTRACT_NUM
       AND A.DATA_DATE = IS_DATE
      LEFT JOIN SMTMODS.L_ACCT_LOAN_ENTRUST B --委托贷款补充信息表
        ON B.DATA_DATE = IS_DATE
       AND T.LOAN_NUM = B.LOAN_NUM
     WHERE T.DATA_DATE = IS_DATE
       AND (T.LOAN_ACCT_BAL > 0 OR (T.LOAN_ACCT_BAL=0 AND T1.LOAN_ACCT_BAL>0))
          --  存在之前放款当天结清的数据，贷款余额为0 20231207wxb
       AND T.ITEM_CD LIKE '3020%' --委托贷款
          --AND T.HXRQ IS NULL--不取核销数据
       AND T.CANCEL_FLG = 'N'
          --AND T.COD_PROD <> '10301002'--个人公积金委托贷款
          --AND T.ORG_NUM NOT LIKE '0215%'
       AND T.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
     AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
    --AND EXISTS (SELECT 1 FROM DATACORE_IE_DK_WTDKJC_TMP1 F WHERE B.TRUSTOR_ID = F.CUST_ID )
    ;
  COMMIT;

  SP_IRS_PARTITIONS(IS_DATE, 'IE_DK_WTDKJC', OI_RETCODE);
  INSERT INTO IE_DK_WTDKJC
    (DATADATE, --数据日期
     CONTRACTNUM, --贷款合同编码
     LOANNUM, --贷款借据编号
     CUSTID, --借款人客户号
     TRUSTORCUSTID, --委托人客户号
     CORPID, --内部机构号
     DRAWDOWNDT, --贷款发放日期
     MATURITYDT, --原始到期日期
     ACTUALDUEDATE, --实际终止日期
     LOANTERMTYPE, --贷款期限类型
     RATETYPE, --利率类型
     PRICINGTYPE, --定价基准类型
     BASERATE, --基准利率
     REALRATE, --实际利率
     FLOATFREQ, --利率浮动频率
     LOANPURPOSECD, --贷款实际投向
     CJRQ, --采集日期
     NBJGH, --内部机构号
     -- REPORT_ID, --报送id
     BIZ_LINE_ID, --业务条线
     VERIFY_STATUS, --校验状态
     BSCJRQ, --报送周期
     IRS_CORP_ID --法人机构ID
     )
    SELECT DATADATE, --数据日期
           CONTRACTNUM, --贷款合同编码
           LOANNUM, --贷款借据编号
           CUSTID, --借款人客户号
           TRUSTORCUSTID, --委托人客户号
           CORPID, --内部机构号
           DRAWDOWNDT, --贷款发放日期
           MATURITYDT, --原始到期日期
           ACTUALDUEDATE, --实际终止日期
           CASE
             WHEN LOANTERMTYPE < 3 THEN
              '01'
             WHEN LOANTERMTYPE = 3 THEN
              '02'
             WHEN LOANTERMTYPE < 6 THEN
              '03'
             WHEN LOANTERMTYPE = 6 THEN
              '04'
             WHEN LOANTERMTYPE < 12 THEN
              '05'
             WHEN LOANTERMTYPE < 12 THEN
              '06'
             WHEN LOANTERMTYPE <= 36 THEN
              '07'
             WHEN LOANTERMTYPE <= 60 THEN
              '08'
             WHEN LOANTERMTYPE <= 120 THEN
              '09'
             WHEN LOANTERMTYPE <= 240 THEN
              '10'
             WHEN LOANTERMTYPE <= 360 THEN
              '11'
             WHEN LOANTERMTYPE > 360 THEN
              '12'
             ELSE
              ''
           END LOANTERMTYPE, --贷款期限类型
           RATETYPE, --利率类型
           PRICINGTYPE, --定价基准类型
           BASERATE, --基准利率
           REALRATE, --实际利率
           FLOATFREQ, --利率浮动频率
           LOANPURPOSECD, --贷款实际投向
           CJRQ, --采集日期
           NBJGH, --内部机构号
           --REPORT_ID, --报送id
           BIZ_LINE_ID, --业务条线
           VERIFY_STATUS, --校验状态
           BSCJRQ, --报送周期
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
      FROM DATACORE_IE_DK_WTDKJC T
    --WHERE T.DATADATE = IS_DATE
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

