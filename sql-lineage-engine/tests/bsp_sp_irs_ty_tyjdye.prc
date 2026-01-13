CREATE OR REPLACE PROCEDURE BSP_SP_IRS_TY_TYJDYE(IS_DATE     IN VARCHAR2,
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
  VS_PROCEDURE_NAME := 'SP_IRS_TY_TYJDYE';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------

  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_TY_TYJDYE ';

  INSERT INTO DATACORE_IE_TY_TYJDYE
    (datadate --数据日期
    ,
     contractnum --业务编码
    ,
     corpid --内部机构号
    ,
     custid --客户号
    ,
     moneysymb --币种
    ,
     balance --余额
     )
    SELECT VS_TEXT --数据日期
          ,
           ref_num --业务编码
          ,
           org_num --内部机构号
          ,
           CUST_ID --客户号
          ,
           CURR_CD --币种
          ,
           balance --余额
      FROM SMTMODS.L_ACCT_FUND_MMFUND t
     WHERE DATA_DATE = IS_DATE
          --and substr(T.gl_item_code,'1','3') in ('241','120')
       and substr(T.gl_item_code, '1', '4') in
           ('2003' --拆入资金
           ,
            '1302') --拆出资金
       and (TO_CHAR(mature_date, 'YYYYMMDD') >= IS_DATE

           or ref_num in
           (select ref_num
                  FROM SMTMODS.L_TRAN_FUND_FX t
                /*LEFT JOIN L_TY_CUSTID_INFO@SUPER f
                ON T.CUST_ID=F.CUST_NM*/
                 WHERE DATA_DATE = IS_DATE
                      --and substr(ITEM_CD,'1','3') in ('241','120')
                   and substr(ITEM_CD, '1', '4') in
                       ('2003' --拆入资金
                       ,
                        '1302') --拆出资金
                   AND AMOUNT IS NOT NULL
                   and AMOUNT <> 0
                   and CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
                   and TO_CHAR(MATURITY_DT, 'YYYYMMDD') >= IS_DATE
                   and t.tran_dt = to_date(IS_DATE, 'YYYYMMDD')))
       and CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
    --AND T.ORG_NUM NOT LIKE '0215%'
    ;
  --AND DATE_SOURCESD = '2';  临时注释20211012
  COMMIT;

  SP_IRS_PARTITIONS(IS_DATE, 'IE_TY_TYJDYE', OI_RETCODE);
  INSERT INTO IE_TY_TYJDYE
    (datadate --数据日期
    ,
     contractnum --业务编码
    ,
     corpid --内部机构号
    ,
     custid --客户号
    ,
     moneysymb --币种
    ,
     balance --余额
    ,
     cjrq --采集日期
    ,
     nbjgh --内部机构号
    ,
     biz_line_id --业务条线
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
           moneysymb --币种
          ,
           balance --余额
          ,
           IS_DATE --采集日期
          ,
           corpid --内部机构号
          ,
           '99' --业务条线
          ,
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
      from DATACORE_IE_TY_TYJDYE;
  COMMIT;

  ---待上游修改后，去掉 20230504
  update IE_TY_TYJDYE a
     set contractnum = 'LT2023032100088'
   where cjrq = IS_DATE
     and contractnum = 'LT2023020400011';

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

