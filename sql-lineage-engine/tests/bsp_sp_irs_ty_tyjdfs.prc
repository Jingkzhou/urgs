CREATE OR REPLACE PROCEDURE BSP_SP_IRS_TY_TYJDFS(IS_DATE     IN VARCHAR2,
                                                 OI_RETCODE  OUT INTEGER,
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
  --    需求编号：JLBA202311140009 上线日期：2025-09-19，修改人：蒿蕊，提出人：从需求  修改原因：外汇的流水号不满足业务编码的加工规则，加工后是空值，需调整；
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE      NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT           VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
  NUM               INTEGER;

BEGIN
  VS_TEXT      := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  VS_LAST_TEXT := TO_CHAR(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1),
                          'YYYYMMDD');
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_TY_TYJDFS';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------

  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_TY_TYJDFS ';

  INSERT INTO DATACORE_IE_TY_TYJDFS
    (datadate --数据日期
    ,
     contractnum --业务编码
    ,
     corpid --内部机构号
    ,
     custid --客户号
    ,
     serialno --交易流水号
    ,
     transactiondate --交易日期
    ,
     moneysymb --币种
    ,
     realrate --实际利率
    ,
     baserate ---基准利率
    ,
     transamt --发生金额
    ,
     transdirect --交易方向
     )
    SELECT VS_TEXT --数据日期
          ,
           case when substr(t.ref_num,1,1) = 'W' then--业务编码
             m.ref_num
             else
                nvl(substr(t.ref_num,0,instr(t.ref_num,'_',1)-1),t.ref_num)   --[2025-09-19] [蒿蕊] [JLBA202311140009] [从需求]外汇的流水号不满足业务编码的加工规则，加工后是空值，加nvl
             end
          ,
           t.org_num --内部机构号
          ,
           m.cust_id --客户号
          ,
             nvl(substr(t.ref_num,0,instr(t.ref_num,'_',1)-1),t.ref_num) ref_num  --交易流水号 [2025-09-19] [蒿蕊] [JLBA202311140009] [从需求]外汇的流水号不满足交易流水的加工规则，加工后是空值，加nvl
          ,
           TO_CHAR(t.TRAN_DT, 'YYYY-MM-DD') --交易日期
          ,
           t.CURR_CD --币种(买入币种)
          ,
          nvl( t.real_int_rat,m.real_int_rat) --实际利率
          ,
           '' --基准利率
          ,
           t.AMOUNT --发生金额
          ,
           t.TRADE_DIRECT --交易方向 0结清 1 发生
      FROM SMTMODS.L_TRAN_FUND_FX t left join
      SMTMODS.l_Acct_Fund_Mmfund m on t.data_date = m.data_date
      and t.contract_num = m.acct_num
    /*LEFT JOIN L_TY_CUSTID_INFO@SUPER f
    ON T.CUST_ID=F.CUST_NM*/
     WHERE  t.DATA_DATE = IS_DATE
          --and substr(ITEM_CD,'1','3') in ('241','120')
       and  substr( t.ITEM_CD, '1', '4') in
           ('2003' --拆入资金
           ,
            '1302') --拆出资金
       AND  t.AMOUNT IS NOT NULL
       and  t.AMOUNT <> 0
       and t.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
       and  TO_CHAR( t.MATURITY_DT, 'YYYYMMDD') >= IS_DATE
       and t.tran_dt = to_date(IS_DATE, 'YYYYMMDD')
    --and (t.ref_num <> 'LT2023020400011') ---源系统重复，待上游解决后去掉 20230504
    --AND T.ORG_NUM NOT LIKE '0215%'
    ;
  COMMIT;

  SP_IRS_PARTITIONS_INC(IS_DATE, 'IE_TY_TYJDFS', OI_RETCODE);

  INSERT INTO IE_TY_TYJDFS_INC
    (datadate --数据日期
    ,
     contractnum --业务编码
    ,
     corpid --内部机构号
    ,
     custid --客户号
    ,
     serialno --交易流水号
    ,
     transactiondate --交易日期
    ,
     moneysymb --币种
    ,
     realrate --实际利率
    ,
     baserate ---基准利率
    ,
     transamt --发生金额
    ,
     transdirect --交易方向
    ,
     cjrq --采集日期
    ,
     nbjgh --内部机构号
    ,
     biz_line_id --业务条线
    ,
     DIFF_TYPE --增量标识
    ,
     LAST_DATA_DATE --上一数据时点
    ,
     IRS_CORP_ID --法人机构ID
     )
    select datadate --数据日期
          ,
           contractnum --业务编码
          ,
           corpid --内部机构号
          ,
           custid --客户号
          ,
           serialno --交易流水号
          ,
           transactiondate --交易日期
          ,
           moneysymb --币种
          ,
           realrate --实际利率
          ,
           baserate ---基准利率
          ,
           transamt --发生金额
          ,
           transdirect --交易方向
          ,
           IS_DATE --采集日期
          ,
           corpid --内部机构号
          ,
           '99', --业务条线
           '1', --增量标识
           TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD'), --上一数据时点
           CASE
             WHEN CORPID LIKE '51%' THEN
              '510000'
             WHEN CORPID LIKE '52%' THEN
              '520000'
             WHEN CORPID LIKE '53%' THEN
              '530000'
             WHEN CORPID LIKE '54%' THEN
              '540000'
             WHEN CORPID LIKE '55%' THEN
              '550000'
             WHEN CORPID LIKE '56%' THEN
              '560000'
             WHEN CORPID LIKE '57%' THEN
              '570000'
             WHEN CORPID LIKE '58%' THEN
              '580000'
             WHEN CORPID LIKE '59%' THEN
              '590000'
             WHEN CORPID LIKE '60%' THEN
              '600000'
             ELSE
              '990000'
           END --法人机构ID
      from DATACORE_IE_TY_TYJDFS;
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

