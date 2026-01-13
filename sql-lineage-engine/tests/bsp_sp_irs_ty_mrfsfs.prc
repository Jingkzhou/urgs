CREATE OR REPLACE PROCEDURE BSP_SP_IRS_TY_MRFSFS(IS_DATE    IN VARCHAR2,
                                                OI_RETCODE OUT INTEGER,
                                               OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_TY_MRTXFS
  -- 用途:生成接口表 IE_PJ_PJTXFS  买入反售及卖出回购发生额信息表
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT 20210617
  --
  --需求编号：无需求 上线日期：2025-10-23，修改人：蒿蕊，提出人：黄俊铭  修改原因：多券交割但未到期交易未完全结束，交易金额是空，此场景不报送
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT      VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
 /* VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述*/
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
  /*NUM               INTEGER;*/
  --NUM1              INTEGER;
BEGIN
  VS_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  /*VS_LAST_TEXT := TO_CHAR(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1),'YYYYMMDD');*/
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_TY_MRFSFS';

  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------

SP_IRS_PARTITIONS_INC(IS_DATE,'IE_TY_MRFSFS',OI_RETCODE);


INSERT /*+append*/ INTO IE_TY_MRFSFS_INC NOLOGGING
    (
      DATADATE, --数据日期
      CONTRACTNUM, --业务编码
      CORPID, --内部机构号
      CUSTID, --客户号
      SERIALNO, --交易流水号
      MONEYSYMB, --币种
      TRANSACTIONDATE, --交易日期
      TRANSAMT, --发生金额
      REALRATE, --实际利率
      BASERATE, --基准利率
      TRANSDIRECT, --交易方向
      CJRQ, --采集日期
      NBJGH, --内部机构号
      BIZ_LINE_ID, --业务条线
      VERIFY_STATUS, --校验状态
      BSCJRQ,--报送周期
      DIFF_TYPE, --增量标识（差异类型：1-新增，2-删除，3-相同，4-差异）
      LAST_DATA_DATE,--上一数据节点
      IRS_CORP_ID   --法人机构ID
     )
    SELECT  VS_TEXT AS DATADATE, --数据日期
            E.ACCT_NUM AS CONTRACTNUM, --业务编码
            E.ORG_NUM AS CORPID, --内部机构号
            '' AS CUSTID, --客户号
            A.REF_NUM AS SERIALNO, --交易流水号
            A.CURR_CD AS MONEYSYMB, --币种
            TO_CHAR(A.TRAN_DT,'YYYY-MM-DD') AS TRANSACTIONDATE, --交易日期
            A.AMOUNT AS TRANSAMT, --发生金额
            A.REAL_INT_RAT AS REALRATE, --实际利率
            A.BASE_INT_RAT AS BASERATE, --基准利率
            A.TRADE_DIRECT AS TRANSDIRECT, --交易方向
       IS_DATE ,                            --11采集日期
       E.ORG_NUM ORG_NUM,                           --12内部机构号
       '99',                               --13业务条线
       '',                                 --14校验状态
       '',                                  --15报送日期
       '1',             --增量标识（差异类型：1-新增，2-删除，3-相同，4-差异）
     TO_CHAR(TO_DATE(IS_DATE,'YYYYMMDD')-1,'YYYYMMDD'),   --上一数据时点
     CASE WHEN  E.ORG_NUM LIKE '51%' THEN '510000'
          WHEN  E.ORG_NUM LIKE '52%' THEN '520000'
          WHEN  E.ORG_NUM LIKE '53%' THEN '530000'
          WHEN  E.ORG_NUM LIKE '54%' THEN '540000'
          WHEN  E.ORG_NUM LIKE '55%' THEN '550000'
          WHEN  E.ORG_NUM LIKE '56%' THEN '560000'
          WHEN  E.ORG_NUM LIKE '57%' THEN '570000'
          WHEN  E.ORG_NUM LIKE '58%' THEN '580000'
          WHEN  E.ORG_NUM LIKE '59%' THEN '590000'
          WHEN  E.ORG_NUM LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
  FROM SMTMODS.L_TRAN_FUND_FX A --资金交易信息表
    LEFT  JOIN SMTMODS.L_ACCT_FUND_REPURCHASE E --回购信息表
          ON A.Contract_Num = E.ACCT_NUM
          AND E.DATA_DATE = IS_DATE
    /*INNER JOIN SMTMODS.L_CUST_ALL B  --全量客户信息表
          ON E.CUST_ID = B.CUST_ID
          AND B.DATA_DATE = IS_DATE
    LEFT  JOIN SMTMODS.L_CUST_C C --对公客户补充信息表
          ON E.CUST_ID = C.CUST_ID
          AND C.DATA_DATE = IS_DATE*/
    INNER JOIN SMTMODS.L_PUBL_ORG_BRA D  --机构表
           ON E.ORG_NUM = D.ORG_NUM
          AND D.DATA_DATE = IS_DATE
    WHERE A.TRAN_DT = TO_DATE(IS_DATE,'YYYYMMDD')
      AND SUBSTR(E.BUSI_TYPE,1,1) IN ('1','2')
      AND E.ASS_TYPE = '1'
      --AND E.DEAL_TYPE = '2'   暂时注释
      AND A.CURR_CD IN ('CNY','USD','EUR','JPY','HKD')
      /*AND C.FINA_CODE_NEW IS NOT NULL
      AND SUBSTR(C.FINA_CODE_NEW,1,1) NOT IN ('A','B')
      AND B.INLANDORRSHORE_FLG = 'Y'*/
      AND D.NATION_CD = 'CHN'
      AND A.AMOUNT <> 0;  --[2025-10-23] [蒿蕊] [无需求] [黄俊铭]多券交割但未到期交易未完全结束，交易金额是空，此场景不报送
      --AND A.INTEREST_FLAG <> 'Y'  --判断是否为利息

   COMMIT;

  ---原逻辑回退，20230727 ，数仓在资金交易流水表中加买入反售票据流水后代码回退
INSERT /*+append*/ INTO IE_TY_MRFSFS_INC NOLOGGING
    (
      DATADATE, --数据日期
      CONTRACTNUM, --业务编码
      CORPID, --内部机构号
      CUSTID, --客户号
      SERIALNO, --交易流水号
      MONEYSYMB, --币种
      TRANSACTIONDATE, --交易日期
      TRANSAMT, --发生金额
      REALRATE, --实际利率
      BASERATE, --基准利率
      TRANSDIRECT, --交易方向
      CJRQ, --采集日期
      NBJGH, --内部机构号
      BIZ_LINE_ID, --业务条线
      VERIFY_STATUS, --校验状态
      BSCJRQ,--报送周期
      DIFF_TYPE, --增量标识（差异类型：1-新增，2-删除，3-相同，4-差异）
      LAST_DATA_DATE,--上一数据节点
      IRS_CORP_ID   --法人机构ID
     )
 /* SELECT VS_TEXT AS DATADATE, --数据日期
           E.ACCT_NUM || '_' || E.REF_NUM AS CONTRACTNUM, --业务编码
           E.ORG_NUM AS CORPID, --内部机构号
           '' AS CUSTID, --客户号
           A.REF_NUM AS SERIALNO, --交易流水号
           A.CURR_CD AS MONEYSYMB, --币种
           TO_CHAR(A.TRAN_DT, 'YYYY-MM-DD') AS TRANSACTIONDATE, --交易日期
           A.AMOUNT AS TRANSAMT, --发生金额
           A.REAL_INT_RAT AS REALRATE, --实际利率
           A.BASE_INT_RAT AS BASERATE, --基准利率
           A.TRADE_DIRECT AS TRANSDIRECT, --交易方向
           IS_DATE, --11采集日期
           E.ORG_NUM ORG_NUM, --12内部机构号
           '99', --13业务条线
           '', --14校验状态
           '', --15报送日期
           '1', --增量标识（差异类型：1-新增，2-删除，3-相同，4-差异）
           TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD'), --上一数据时点
           CASE
             WHEN E.ORG_NUM LIKE '51%' THEN
              '510000'
             ELSE
              '990000'
           END --法人机构ID
      FROM SMTMODS.L_TRAN_FUND_FX A --资金交易信息表
      LEFT JOIN SMTMODS.L_ACCT_FUND_REPURCHASE E --回购信息表
        ON A.Contract_Num = E.SUBJECT_CD
       AND E.DATA_DATE = IS_DATE
     INNER JOIN SMTMODS.L_PUBL_ORG_BRA D --机构表
        ON E.ORG_NUM = D.ORG_NUM
       AND D.DATA_DATE = IS_DATE
     WHERE A.TRAN_DT = TO_DATE(IS_DATE, 'YYYYMMDD')
       AND SUBSTR(E.BUSI_TYPE, 1, 1) IN ('1', '2')
       AND E.ASS_TYPE = '2'
          --AND E.DEAL_TYPE = '2'   暂时注释
       AND A.CURR_CD IN ('CNY', 'USD', 'EUR', 'JPY', 'HKD')
       AND D.NATION_CD = 'CHN';

  COMMIT;*/

---买入反售票据发生，资金交易数仓在开发，暂时先用业务表做流水，待数仓上线后调整 20230629
     SELECT VS_TEXT AS DATADATE, --数据日期
         E.ACCT_NUM || '_' || E.REF_NUM AS CONTRACTNUM, --业务编码  金数上线后，REF_NUM=ACCT_NUM的值使用E.ACCT_NUM || '_' || E.SUBJECT_CD
         E.ORG_NUM AS CORPID, --内部机构号
         '' AS CUSTID, --客户号
         E.REF_NUM AS SERIALNO, --交易流水号
         E.CURR_CD AS MONEYSYMB, --币种
         TO_CHAR(to_date(IS_DATE,'yyyymmdd'), 'YYYY-MM-DD') AS TRANSACTIONDATE, --交易日期
         E.BALANCE AS TRANSAMT, --发生金额
/*         E.REAL_INT_RAT AS REALRATE, --实际利率*/
         E.REAL_INT_RAT * 100 AS REALRATE, --实际利率20231030wxb
         '' AS BASERATE, --基准利率
         E.TRANS_TYPE AS TRANSDIRECT, --交易方向
         IS_DATE, --11采集日期
         E.ORG_NUM ORG_NUM, --12内部机构号
         '99', --13业务条线
         '', --14校验状态
         '', --15报送日期
         '1', --增量标识（差异类型：1-新增，2-删除，3-相同，4-差异）
         TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD'), --上一数据时点
         CASE WHEN  E.ORG_NUM LIKE '51%' THEN '510000'
          WHEN  E.ORG_NUM LIKE '52%' THEN '520000'
          WHEN  E.ORG_NUM LIKE '53%' THEN '530000'
          WHEN  E.ORG_NUM LIKE '54%' THEN '540000'
          WHEN  E.ORG_NUM LIKE '55%' THEN '550000'
          WHEN  E.ORG_NUM LIKE '56%' THEN '560000'
          WHEN  E.ORG_NUM LIKE '57%' THEN '570000'
          WHEN  E.ORG_NUM LIKE '58%' THEN '580000'
          WHEN  E.ORG_NUM LIKE '59%' THEN '590000'
          WHEN  E.ORG_NUM LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
             FROM (SELECT '1' AS TRANS_TYPE,
                          ORG_NUM,
                          CUST_ID,
                          ACCT_NUM,
                          GL_ITEM_CODE,
                          BEG_DT,
                          END_DT,
                          REAL_INT_RAT,
                          BASE_INT_RAT,
                          CURR_CD,
                          REF_NUM,
                          SUM(ATM) AS BALANCE
                     FROM SMTMODS.L_ACCT_FUND_REPURCHASE T
                    WHERE T.DATA_DATE = IS_DATE
                      AND T.GL_ITEM_CODE IN ('111102', '211102') --票据卖出回购  211102  票据买入返售  111102
                      AND TO_CHAR(T.BEG_DT, 'yyyy-mm-dd') = VS_TEXT --发生
                     AND SUBSTR(T.BUSI_TYPE, 1, 1) IN ('1', '2')
                      AND T.ASS_TYPE = '2'
                      AND T.CURR_CD IN ('CNY', 'USD', 'EUR', 'JPY', 'HKD')
                    GROUP BY ORG_NUM,
                             CUST_ID,
                             ACCT_NUM,
                             GL_ITEM_CODE,
                             BEG_DT,
                             END_DT,
                             REAL_INT_RAT,
                             BASE_INT_RAT,
                             CURR_CD,
                             REF_NUM
                   UNION
                   SELECT '0' AS TRANS_TYPE,
                          ORG_NUM,
                          CUST_ID,
                          ACCT_NUM,
                          GL_ITEM_CODE,
                          BEG_DT,
                          END_DT,
                          REAL_INT_RAT,
                          BASE_INT_RAT,
                          CURR_CD,
                          REF_NUM,
                          SUM(ATM) AS BALANCE
                     FROM SMTMODS.L_ACCT_FUND_REPURCHASE T
                    WHERE T.DATA_DATE = IS_DATE
                      AND T.GL_ITEM_CODE IN ('111102', '211102') --票据卖出回购  211102  票据买入返售  111102
                      AND TO_CHAR(T.END_DT, 'yyyy-mm-dd') = VS_TEXT --收回
                     AND SUBSTR(T.BUSI_TYPE, 1, 1) IN ('1', '2')
                      AND T.ASS_TYPE = '2'
                      AND T.CURR_CD IN ('CNY', 'USD', 'EUR', 'JPY', 'HKD')
                    GROUP BY ORG_NUM,
                             CUST_ID,
                             ACCT_NUM,
                             GL_ITEM_CODE,
                             BEG_DT,
                             END_DT,
                             REAL_INT_RAT,
                             BASE_INT_RAT,
                             CURR_CD,
                             REF_NUM) E
            INNER JOIN SMTMODS.L_PUBL_ORG_BRA D --机构表
              ON E.ORG_NUM = D.ORG_NUM
              AND D.DATA_DATE = IS_DATE
            WHERE D.NATION_CD = 'CHN';



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

