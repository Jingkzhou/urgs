CREATE OR REPLACE PROCEDURE BSP_SP_IRS_PJ_PJTXFS(IS_DATE    IN VARCHAR2,
                                                OI_RETCODE OUT INTEGER,
                                               OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_PJ_PJTXFS
  -- 用途:生成接口表 IE_PJ_PJTXFS  个人客户客户基础信息
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT 20210528
  --
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT      VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  --VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
  /*NUM               INTEGER;*/
  --NUM1              INTEGER;
BEGIN
  VS_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  --VS_LAST_TEXT := TO_CHAR(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1),'YYYYMMDD');
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_PJ_PJTXFS';

  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------
/*EXECUTE IMMEDIATE 'TRUNCATE TABLE IE_PJ_PJTXFS_TMP1';
INSERT INTO IE_PJ_PJTXFS_TMP1
 SELECT DISTINCT CUST_ID
 FROM SMTMODS.L_CUST_P
 WHERE DATA_DATE =IS_DATE
 AND ORG_NUM NOT LIKE '0215%';
 COMMIT;
 INSERT INTO IE_PJ_PJTXFS_TMP1
 SELECT DISTINCT CUST_ID
 FROM SMTMODS.L_CUST_C
 WHERE DATA_DATE =IS_DATE
 AND ORG_NUM NOT LIKE '0215%';
 COMMIT;*/

--EXECUTE IMMEDIATE 'TRUNCATE TABLE CUST_0215_NEW';


/*INSERT INTO CUST_0215_NEW
  SELECT A.CUST_ID
    FROM SMTMODS.L_CUST_P A
   WHERE A.ORG_NUM IS NOT NULL
     AND A.DATA_DATE = IS_DATE;
COMMIT;

INSERT INTO CUST_0215_NEW
  SELECT A.CUST_ID
    FROM SMTMODS.L_CUST_C A
   WHERE A.ORG_NUM IS NOT NULL
     AND A.DATA_DATE = IS_DATE;
COMMIT;*/

--重复买入卖出的票，取借据表中最新的一条数据    20241204
EXECUTE IMMEDIATE 'TRUNCATE TABLE L_ACCT_LOAN_NEW';

INSERT INTO L_ACCT_LOAN_NEW
  SELECT *
    FROM (SELECT A.ORG_NUM,
                 A.CUST_ID,
                 A.ACCT_NUM,
                 A.LOAN_NUM,
                 A.CURR_CD,
                 A.REAL_INT_RAT,
                 A.ITEM_CD,
                 A.LOAN_ACCT_BAL,
                 A.DRAFT_RNG,
                 ROW_NUMBER() OVER(PARTITION BY A.ACCT_NUM, A.DRAFT_RNG,A.ITEM_CD ORDER BY TO_CHAR(A.DRAWDOWN_DT,'yyyymmdd') DESC) RN
            FROM SMTMODS.L_ACCT_LOAN A WHERE A.DATA_DATE = IS_DATE
            AND A.ITEM_CD in ('13010101','13010104','13010401','13010405','13010201','13010204','13010501','13010505')) B
   WHERE B.RN = '1';

COMMIT;

SP_IRS_PARTITIONS_INC(IS_DATE,'IE_PJ_PJTXFS',OI_RETCODE);


 VS_STEP := '贴现';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);

--提取数据-贴现
--旧票，直接关联
INSERT INTO  IE_PJ_PJTXFS_INC
(DATADATE,                     --1数据日期
 CORPID,               --2内部机构号
 CUSTID,               --3客户号
 CONTRACTNUM,           --4业务编码
 SERIALNO,             --5交易流水号
 MONEYSYMB,            --6币种
 TRANSACTIONDATE,      --7交易日期
 TRANSAMT,             --8发生金额
 REALRATE,             --9贴现利率
 TRANSDIRECT,          --10交易方向
 CJRQ,                 --11采集日期
 NBJGH,                --12内部机构号
 BIZ_LINE_ID,          --13业务条线
 VERIFY_STATUS,        --14校验状态
 BSCJRQ ,
 DIFF_TYPE,    --增量标识
     LAST_DATA_DATE,    --上一数据时点
     IRS_CORP_ID        --法人机构ID
)
SELECT   /*+ USE_HASH(D,A,B,C) PARALLEL(8)*/    VS_TEXT AS DATADATE, --数据日期
            A.ORG_NUM AS CORPID, --内部机构号
            A.CUST_ID AS CUSTID, --客户号
            A.LOAN_NUM AS CONTRACTNUM, --业务编码
            --D.CONTRACT_NUM||D.REF_NUM AS SERIALNO, --交易流水号
            D.REF_NUM AS SERIALNO, --交易流水号
            A.CURR_CD AS MONEYSYMB, --币种
            TO_CHAR(D.TRAN_DT,'YYYY-MM-DD') AS TRANSACTIONDATE, --交易日期
            D.AMOUNT AS TRANSAMT, --发生金额
            A.REAL_INT_RAT AS REALRATE, --贴现利率
            CASE WHEN D.TRADE_DIRECT = '1' THEN '1' ELSE '0' END AS TRANSDIRECT, --交易方向
       IS_DATE, --11采集日期
       A.ORG_NUM, --12内部机构号
       '99', --13业务条线
       '', --14校验状态
       '',
       '1' , --增量标识
       TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD'), --上一数据时点
       CASE WHEN  B.ORG_NUM LIKE '51%' THEN '510000'
          WHEN  B.ORG_NUM LIKE '52%' THEN '520000'
          WHEN  B.ORG_NUM LIKE '53%' THEN '530000'
          WHEN  B.ORG_NUM LIKE '54%' THEN '540000'
          WHEN  B.ORG_NUM LIKE '55%' THEN '550000'
          WHEN  B.ORG_NUM LIKE '56%' THEN '560000'
          WHEN  B.ORG_NUM LIKE '57%' THEN '570000'
          WHEN  B.ORG_NUM LIKE '58%' THEN '580000'
          WHEN  B.ORG_NUM LIKE '59%' THEN '590000'
          WHEN  B.ORG_NUM LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
  FROM SMTMODS.L_TRAN_FUND_FX D --交易信息表
    LEFT JOIN L_ACCT_LOAN_NEW A  --贷款借据信息表
           ON D.CONTRACT_NUM = A.ACCT_NUM    --MDF BY GMY 20241010
           --ON D.REF_NUM = A.LOAN_NUM   ---MDF BY CHM 20230427
          --AND A.DATA_DATE = IS_DATE
           AND D.Item_Cd = A.Item_Cd
           AND (A.ITEM_CD in ('13010101','13010104')
           OR A.ITEM_CD in ('13010401','13010405'))
    INNER JOIN SMTMODS.L_PUBL_ORG_BRA B  --机构表
           ON A.ORG_NUM = B.ORG_NUM
          AND B.DATA_DATE = IS_DATE
    /*INNER JOIN SMTMODS.L_CUST_ALL C  --全量客户信息表
          ON A.CUST_ID = C.CUST_ID
          AND C.DATA_DATE = IS_DATE*/
    /*INNER JOIN CUST_0215_NEW E
          ON A.CUST_ID = E.CUST_ID*/
    WHERE D.TRAN_DT = TO_DATE(IS_DATE,'YYYYMMDD')
      --AND SUBSTR(A.ACCT_TYP,1,4) = '0301'
      AND (D.ITEM_CD in ('13010101','13010104')
       OR D.ITEM_CD in ('13010401','13010405'))    --20240906  修改贴现取数范围
      AND A.CURR_CD IN ('CNY','USD','EUR','JPY','HKD')
      AND B.NATION_CD = 'CHN'
      --AND A.LOAN_ACCT_BAL > 0
      AND D.AMOUNT > 0     --20241219  发生额取大于0的数据
      AND D.DRAFT_RNG IS NULL;
     -- AND C.INLANDORRSHORE_FLG = 'Y';
      --AND D.SETTL_INTEREST_FLG <> 'Y';

  COMMIT;


--新票，关联子票区间
INSERT INTO  IE_PJ_PJTXFS_INC
(DATADATE,                     --1数据日期
 CORPID,               --2内部机构号
 CUSTID,               --3客户号
 CONTRACTNUM,           --4业务编码
 SERIALNO,             --5交易流水号
 MONEYSYMB,            --6币种
 TRANSACTIONDATE,      --7交易日期
 TRANSAMT,             --8发生金额
 REALRATE,             --9贴现利率
 TRANSDIRECT,          --10交易方向
 CJRQ,                 --11采集日期
 NBJGH,                --12内部机构号
 BIZ_LINE_ID,          --13业务条线
 VERIFY_STATUS,        --14校验状态
 BSCJRQ ,
 DIFF_TYPE,    --增量标识
     LAST_DATA_DATE,    --上一数据时点
     IRS_CORP_ID        --法人机构ID
)
SELECT   /*+ USE_HASH(D,A,B,C) PARALLEL(8)*/    VS_TEXT AS DATADATE, --数据日期
            A.ORG_NUM AS CORPID, --内部机构号
            A.CUST_ID AS CUSTID, --客户号
            A.LOAN_NUM AS CONTRACTNUM, --业务编码
            --D.CONTRACT_NUM||D.REF_NUM AS SERIALNO, --交易流水号
            D.REF_NUM AS SERIALNO, --交易流水号
            A.CURR_CD AS MONEYSYMB, --币种
            TO_CHAR(D.TRAN_DT,'YYYY-MM-DD') AS TRANSACTIONDATE, --交易日期
            D.AMOUNT AS TRANSAMT, --发生金额
            A.REAL_INT_RAT AS REALRATE, --贴现利率
            CASE WHEN D.TRADE_DIRECT = '1' THEN '1' ELSE '0' END AS TRANSDIRECT, --交易方向
       IS_DATE, --11采集日期
       A.ORG_NUM, --12内部机构号
       '99', --13业务条线
       '', --14校验状态
       '',
       '1' , --增量标识
       TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD'), --上一数据时点
       CASE WHEN  B.ORG_NUM LIKE '51%' THEN '510000'
          WHEN  B.ORG_NUM LIKE '52%' THEN '520000'
          WHEN  B.ORG_NUM LIKE '53%' THEN '530000'
          WHEN  B.ORG_NUM LIKE '54%' THEN '540000'
          WHEN  B.ORG_NUM LIKE '55%' THEN '550000'
          WHEN  B.ORG_NUM LIKE '56%' THEN '560000'
          WHEN  B.ORG_NUM LIKE '57%' THEN '570000'
          WHEN  B.ORG_NUM LIKE '58%' THEN '580000'
          WHEN  B.ORG_NUM LIKE '59%' THEN '590000'
          WHEN  B.ORG_NUM LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
  FROM SMTMODS.L_TRAN_FUND_FX D --交易信息表
    LEFT JOIN L_ACCT_LOAN_NEW A  --贷款借据信息表
           ON D.CONTRACT_NUM = A.ACCT_NUM
           AND D.DRAFT_RNG = A.DRAFT_RNG   --关联子票区间    --MDF BY GMY 20241010
           --ON D.REF_NUM = A.LOAN_NUM   ---MDF BY CHM 20230427
          --AND A.DATA_DATE = IS_DATE
           AND D.Item_Cd = A.Item_Cd
           AND (A.ITEM_CD in ('13010101','13010104')
           OR A.ITEM_CD in ('13010401','13010405'))       --MDF BY GMY 20250103
    INNER JOIN SMTMODS.L_PUBL_ORG_BRA B  --机构表
           ON A.ORG_NUM = B.ORG_NUM
          AND B.DATA_DATE = IS_DATE
    /*INNER JOIN SMTMODS.L_CUST_ALL C  --全量客户信息表
          ON A.CUST_ID = C.CUST_ID
          AND C.DATA_DATE = IS_DATE*/
    /*INNER JOIN CUST_0215_NEW E
          ON A.CUST_ID = E.CUST_ID*/
    WHERE D.TRAN_DT = TO_DATE(IS_DATE,'YYYYMMDD')
      --AND SUBSTR(A.ACCT_TYP,1,4) = '0301'
      AND (A.ITEM_CD in ('13010101','13010104')
       OR A.ITEM_CD in ('13010401','13010405'))    --20240906  修改贴现取数范围
      AND A.CURR_CD IN ('CNY','USD','EUR','JPY','HKD')
      AND B.NATION_CD = 'CHN'
      --AND A.LOAN_ACCT_BAL > 0              ----MDF BY GMY 20250103
      AND D.AMOUNT > 0     --20241219  发生额取大于0的数据
      AND D.DRAFT_RNG IS NOT NULL;
     -- AND C.INLANDORRSHORE_FLG = 'Y';
      --AND D.SETTL_INTEREST_FLG <> 'Y';

  COMMIT;


  VS_STEP := '转贴现转入';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);

--提取数据-转贴现转入
--旧票，直接关联
INSERT INTO  IE_PJ_PJTXFS_INC
(DATADATE,                     --1数据日期
 CORPID,               --2内部机构号
 CUSTID,               --3客户号
 CONTRACTNUM,           --4业务编码
 SERIALNO,             --5交易流水号
 MONEYSYMB,            --6币种
 TRANSACTIONDATE,      --7交易日期
 TRANSAMT,             --8发生金额
 REALRATE,             --9贴现利率
 TRANSDIRECT,          --10交易方向
 CJRQ,                 --11采集日期
 NBJGH,                --12内部机构号
 BIZ_LINE_ID,          --13业务条线
 VERIFY_STATUS,        --14校验状态
 BSCJRQ ,
 DIFF_TYPE,    --增量标识
     LAST_DATA_DATE,    --上一数据时点
     IRS_CORP_ID        --法人机构ID
)
SELECT  /*+ USE_HASH(A,B,C,D) PARALLEL(8)*/     VS_TEXT AS DATADATE, --数据日期
            B.ORG_NUM AS CORPID, --内部机构号
            B.CUST_ID AS CUSTID, --客户号
            --A.CONTRACT_NUM AS CONTRACTNUM, --业务编码
            B.Loan_Num AS CONTRACTNUM, --业务编码
            A.REF_NUM AS SERIALNO, --交易流水号
            B.CURR_CD AS MONEYSYMB, --币种
            TO_CHAR(A.TRAN_DT,'YYYY-MM-DD') AS TRANSACTIONDATE, --交易日期
            A.AMOUNT AS TRANSAMT, --发生金额
            B.REAL_INT_RAT AS REALRATE, --贴现利率
            A.TRADE_DIRECT AS TRANSDIRECT, --交易方向
       IS_DATE, --11采集日期
       B.ORG_NUM, --12内部机构号
       '99', --13业务条线
       '', --14校验状态
       '',
       '1' , --增量标识
       TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD'), --上一数据时点
       CASE WHEN  B.ORG_NUM LIKE '51%' THEN '510000'
          WHEN  B.ORG_NUM LIKE '52%' THEN '520000'
          WHEN  B.ORG_NUM LIKE '53%' THEN '530000'
          WHEN  B.ORG_NUM LIKE '54%' THEN '540000'
          WHEN  B.ORG_NUM LIKE '55%' THEN '550000'
          WHEN  B.ORG_NUM LIKE '56%' THEN '560000'
          WHEN  B.ORG_NUM LIKE '57%' THEN '570000'
          WHEN  B.ORG_NUM LIKE '58%' THEN '580000'
          WHEN  B.ORG_NUM LIKE '59%' THEN '590000'
          WHEN  B.ORG_NUM LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
  FROM SMTMODS.L_TRAN_FUND_FX A --资金交易信息表
    LEFT JOIN L_ACCT_LOAN_NEW B  --投资业务信息表
           ON A.CONTRACT_NUM = B.ACCT_NUM     --MDF BY GMY 20241010
           --ON A.REF_NUM = B.LOAN_NUM   ---MDF BY CHM 20230427
          --AND B.DATA_DATE = IS_DATE
           AND A.Item_Cd = B.Item_Cd
           AND (B.ITEM_CD in ('13010201','13010204')       --以摊余成本计量的转贴现
           OR B.ITEM_CD in ('13010501','13010505'))       --以公允价值计量变动计入权益的转贴现  ----MDF BY GMY 20250103
    INNER JOIN SMTMODS.L_PUBL_ORG_BRA C  --机构表
           ON B.ORG_NUM = C.ORG_NUM
          AND C.DATA_DATE = IS_DATE
    /*INNER JOIN SMTMODS.L_CUST_ALL D  --全量客户信息表
          ON B.CUST_ID = D.CUST_ID
          AND D.DATA_DATE = IS_DATE*/
    /*INNER JOIN CUST_0215_NEW E
          ON B.CUST_ID = E.CUST_ID*/
    WHERE A.TRAN_DT = TO_DATE(IS_DATE,'YYYYMMDD')
      --AND B.ITEM_CD IN ('12902','12906')
      AND (A.ITEM_CD in ('13010201','13010204')       --以摊余成本计量的转贴现
       OR A.ITEM_CD in ('13010501','13010505'))       --以公允价值计量变动计入权益的转贴现    20240906  修改转贴现取数范围
      AND B.CURR_CD IN ('CNY','USD','EUR','JPY','HKD')
      AND C.NATION_CD = 'CHN'
      AND A.DRAFT_RNG IS NULL;
     -- AND D.INLANDORRSHORE_FLG = 'Y' --境外做票据业务，需要注册境内机构，所以票据系统不区分境内境外，默认境内，信用证等业务有境外
     --AND A.INTEREST_FLAG <> 'Y'; ---上游流水是拿账户信息反做的流水，只有本金流水

  COMMIT;

--新票，关联子票区间
INSERT INTO  IE_PJ_PJTXFS_INC
(DATADATE,                     --1数据日期
 CORPID,               --2内部机构号
 CUSTID,               --3客户号
 CONTRACTNUM,           --4业务编码
 SERIALNO,             --5交易流水号
 MONEYSYMB,            --6币种
 TRANSACTIONDATE,      --7交易日期
 TRANSAMT,             --8发生金额
 REALRATE,             --9贴现利率
 TRANSDIRECT,          --10交易方向
 CJRQ,                 --11采集日期
 NBJGH,                --12内部机构号
 BIZ_LINE_ID,          --13业务条线
 VERIFY_STATUS,        --14校验状态
 BSCJRQ ,
 DIFF_TYPE,    --增量标识
     LAST_DATA_DATE,    --上一数据时点
     IRS_CORP_ID        --法人机构ID
)
SELECT  /*+ USE_HASH(A,B,C,D) PARALLEL(8)*/     VS_TEXT AS DATADATE, --数据日期
            B.ORG_NUM AS CORPID, --内部机构号
            B.CUST_ID AS CUSTID, --客户号
            --A.CONTRACT_NUM AS CONTRACTNUM, --业务编码
            B.Loan_Num AS CONTRACTNUM, --业务编码
            A.REF_NUM AS SERIALNO, --交易流水号
            B.CURR_CD AS MONEYSYMB, --币种
            TO_CHAR(A.TRAN_DT,'YYYY-MM-DD') AS TRANSACTIONDATE, --交易日期
            A.AMOUNT AS TRANSAMT, --发生金额
            B.REAL_INT_RAT AS REALRATE, --贴现利率
            A.TRADE_DIRECT AS TRANSDIRECT, --交易方向
       IS_DATE, --11采集日期
       B.ORG_NUM, --12内部机构号
       '99', --13业务条线
       '', --14校验状态
       '',
       '1' , --增量标识
       TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD'), --上一数据时点
       CASE WHEN  B.ORG_NUM LIKE '51%' THEN '510000'
          WHEN  B.ORG_NUM LIKE '52%' THEN '520000'
          WHEN  B.ORG_NUM LIKE '53%' THEN '530000'
          WHEN  B.ORG_NUM LIKE '54%' THEN '540000'
          WHEN  B.ORG_NUM LIKE '55%' THEN '550000'
          WHEN  B.ORG_NUM LIKE '56%' THEN '560000'
          WHEN  B.ORG_NUM LIKE '57%' THEN '570000'
          WHEN  B.ORG_NUM LIKE '58%' THEN '580000'
          WHEN  B.ORG_NUM LIKE '59%' THEN '590000'
          WHEN  B.ORG_NUM LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
  FROM SMTMODS.L_TRAN_FUND_FX A --资金交易信息表
    LEFT JOIN L_ACCT_LOAN_NEW B  --投资业务信息表
           ON A.CONTRACT_NUM = B.ACCT_NUM
           AND A.DRAFT_RNG = B.DRAFT_RNG   --关联子票区间    --MDF BY GMY 20241010
           --ON A.REF_NUM = B.LOAN_NUM   ---MDF BY CHM 20230427
          --AND B.DATA_DATE = IS_DATE
           AND A.Item_Cd = B.Item_Cd
           AND (B.ITEM_CD in ('13010201','13010204')       --以摊余成本计量的转贴现
           OR B.ITEM_CD in ('13010501','13010505'))       --以公允价值计量变动计入权益的转贴现   ----MDF BY GMY 20250103
    INNER JOIN SMTMODS.L_PUBL_ORG_BRA C  --机构表
           ON B.ORG_NUM = C.ORG_NUM
          AND C.DATA_DATE = IS_DATE
    /*INNER JOIN SMTMODS.L_CUST_ALL D  --全量客户信息表
          ON B.CUST_ID = D.CUST_ID
          AND D.DATA_DATE = IS_DATE*/
    /*INNER JOIN CUST_0215_NEW E
          ON B.CUST_ID = E.CUST_ID*/
    WHERE A.TRAN_DT = TO_DATE(IS_DATE,'YYYYMMDD')
      --AND B.ITEM_CD IN ('12902','12906')
      AND (A.ITEM_CD in ('13010201','13010204')       --以摊余成本计量的转贴现
       OR A.ITEM_CD in ('13010501','13010505'))       --以公允价值计量变动计入权益的转贴现    20240906  修改转贴现取数范围
      AND B.CURR_CD IN ('CNY','USD','EUR','JPY','HKD')
      AND C.NATION_CD = 'CHN'
      AND A.DRAFT_RNG IS NOT NULL;
     -- AND D.INLANDORRSHORE_FLG = 'Y' --境外做票据业务，需要注册境内机构，所以票据系统不区分境内境外，默认境内，信用证等业务有境外
     --AND A.INTEREST_FLAG <> 'Y'; ---上游流水是拿账户信息反做的流水，只有本金流水

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

    --返回中文描述

    OI_RETCODE2 := SUBSTR(SQLERRM, 1, 200);

    --插入日志表，记录错误
    SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
END;
/

