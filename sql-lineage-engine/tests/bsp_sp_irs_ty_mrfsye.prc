CREATE OR REPLACE PROCEDURE BSP_SP_IRS_TY_MRFSYE(IS_DATE    IN VARCHAR2,
                                                OI_RETCODE OUT INTEGER,
                                               OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_TY_MRFSYE
  -- 用途:生成接口表 IE_TY_MRFSFS  买入反售及卖出回购余额信息表
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT 20210617
  --
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
  VS_PROCEDURE_NAME := 'SP_IRS_TY_MRFSYE';

  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------
 SP_IRS_PARTITIONS(IS_DATE,'IE_TY_MRFSYE',OI_RETCODE);

 INSERT /*+append*/ INTO IE_TY_MRFSYE NOLOGGING
    (
      DATADATE, --数据日期
      CONTRACTNUM, --业务编码
      CORPID, --内部机构号
      CUSTID, --客户号
      MONEYSYMB, --币种
      BALANCE, --余额
      CJRQ, --数据日期
      NBJGH,  --内部机构号
      REPORT_ID,  --报送ID
      BIZ_LINE_ID,  --业务条线
      VERIFY_STATUS,  --校验状态
      BSCJRQ,  --报送周期
      IRS_CORP_ID  --法人机构ID
     )
    SELECT  VS_TEXT AS DATADATE, --数据日期
            A.ACCT_NUM AS CONTRACTNUM, --业务编码
            A.ORG_NUM AS CORPID, --内部机构号
            '' AS CUSTID, --客户号
            A.CURR_CD AS MONEYSYMB, --币种
            A.BALANCE AS BALANCE, --余额
            IS_DATE, --数据日期
            A.ORG_NUM,  --内部机构号
            SYS_GUID(),  --报送ID
            '99',  --业务条线
            '',  --校验状态
            '',  --报送周期
            CASE WHEN A.ORG_NUM LIKE '51%' THEN '510000'
          WHEN A.ORG_NUM LIKE '52%' THEN '520000'
          WHEN A.ORG_NUM LIKE '53%' THEN '530000'
          WHEN A.ORG_NUM LIKE '54%' THEN '540000'
          WHEN A.ORG_NUM LIKE '55%' THEN '550000'
          WHEN A.ORG_NUM LIKE '56%' THEN '560000'
          WHEN A.ORG_NUM LIKE '57%' THEN '570000'
          WHEN A.ORG_NUM LIKE '58%' THEN '580000'
          WHEN A.ORG_NUM LIKE '59%' THEN '590000'
          WHEN A.ORG_NUM LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
    FROM SMTMODS.L_ACCT_FUND_REPURCHASE A --回购信息表
    /*INNER JOIN SMTMODS.L_CUST_ALL B  --全量客户信息表
          ON A.CUST_ID = B.CUST_ID
          AND B.DATA_DATE = IS_DATE*/
    /*INNER JOIN SMTMODS.L_CUST_C C --对公客户补充信息表
          ON A.CUST_ID = C.CUST_ID
          AND C.DATA_DATE = IS_DATE*/
    INNER JOIN SMTMODS.L_PUBL_ORG_BRA D  --机构表
           ON A.ORG_NUM = D.ORG_NUM
          AND D.DATA_DATE = IS_DATE
    WHERE A.DATA_DATE = IS_DATE
      AND SUBSTR(A.BUSI_TYPE,1,1) IN ('1','2')
      AND A.ASS_TYPE = '1'
      --AND A.DEAL_TYPE = '2'   --票据 暂时注释
      AND A.CURR_CD IN ('CNY','USD','EUR','JPY','HKD')
      --AND C.FINA_CODE_NEW IS NOT NULL    -金融机构类型代码，判断同业机构是否为金融机构
      --AND SUBSTR(C.FINA_CODE_NEW,1,1) NOT IN ('A','B')
      --AND B.INLANDORRSHORE_FLG = 'Y'    --境内外标识
      AND (A.LOAN_ACTUAL_DUE_DATE >= TO_DATE(IS_DATE,'YYYYMMDD') OR A.LOAN_ACTUAL_DUE_DATE IS NULL)
      AND D.NATION_CD = 'CHN';
    COMMIT;

    INSERT /*+append*/ INTO IE_TY_MRFSYE NOLOGGING
    (
      DATADATE, --数据日期
      CONTRACTNUM, --业务编码
      CORPID, --内部机构号
      CUSTID, --客户号
      MONEYSYMB, --币种
      BALANCE, --余额
      CJRQ, --数据日期
      NBJGH,  --内部机构号
      REPORT_ID,  --报送ID
      BIZ_LINE_ID,  --业务条线
      VERIFY_STATUS,  --校验状态
      BSCJRQ,  --报送周期
      IRS_CORP_ID  --法人机构ID
     )
    SELECT  VS_TEXT AS DATADATE, --数据日期
            A.ACCT_NUM||'_'||A.REF_NUM AS CONTRACTNUM, --业务编码
            A.ORG_NUM AS CORPID, --内部机构号
            '' AS CUSTID, --客户号
            A.CURR_CD AS MONEYSYMB, --币种
            A.BALANCE AS BALANCE, --余额
            IS_DATE, --数据日期
            A.ORG_NUM,  --内部机构号
            SYS_GUID(),  --报送ID
            '99',  --业务条线
            '',  --校验状态
            '',  --报送周期
            CASE WHEN A.ORG_NUM LIKE '51%' THEN '510000'
          WHEN A.ORG_NUM LIKE '52%' THEN '520000'
          WHEN A.ORG_NUM LIKE '53%' THEN '530000'
          WHEN A.ORG_NUM LIKE '54%' THEN '540000'
          WHEN A.ORG_NUM LIKE '55%' THEN '550000'
          WHEN A.ORG_NUM LIKE '56%' THEN '560000'
          WHEN A.ORG_NUM LIKE '57%' THEN '570000'
          WHEN A.ORG_NUM LIKE '58%' THEN '580000'
          WHEN A.ORG_NUM LIKE '59%' THEN '590000'
          WHEN A.ORG_NUM LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
    FROM SMTMODS.L_ACCT_FUND_REPURCHASE A --回购信息表
    /*INNER JOIN SMTMODS.L_CUST_ALL B  --全量客户信息表
          ON A.CUST_ID = B.CUST_ID
          AND B.DATA_DATE = IS_DATE*/
    /*INNER JOIN SMTMODS.L_CUST_C C --对公客户补充信息表
          ON A.CUST_ID = C.CUST_ID
          AND C.DATA_DATE = IS_DATE*/
    INNER JOIN SMTMODS.L_PUBL_ORG_BRA D  --机构表
           ON A.ORG_NUM = D.ORG_NUM
          AND D.DATA_DATE = IS_DATE
    WHERE A.DATA_DATE = IS_DATE
      AND SUBSTR(A.BUSI_TYPE,1,1) IN ('1','2')
      AND A.ASS_TYPE = '2'
      --AND A.DEAL_TYPE = '2'   --票据 暂时注释
      AND A.CURR_CD IN ('CNY','USD','EUR','JPY','HKD')
      --AND C.FINA_CODE_NEW IS NOT NULL    -金融机构类型代码，判断同业机构是否为金融机构
      --AND SUBSTR(C.FINA_CODE_NEW,1,1) NOT IN ('A','B')
      --AND B.INLANDORRSHORE_FLG = 'Y'    --境内外标识
      AND (A.LOAN_ACTUAL_DUE_DATE >= TO_DATE(IS_DATE,'YYYYMMDD') OR A.LOAN_ACTUAL_DUE_DATE IS NULL)
      AND D.NATION_CD = 'CHN';
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

