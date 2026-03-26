CREATE OR REPLACE PROCEDURE BSP_SP_IRS_DK_GRDKYE(IS_DATE    IN VARCHAR2,
                                                OI_RETCODE OUT INTEGER,
                                               OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_DK_GRDKYE
  -- 用途:生成接口表 JS_201_CLGRDK 存量个人贷款信息
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT 20200819
  --    MOD BY YANLINGBO AT 20200819
  --需求编号：JLBA202507300010 上线日期：2025-09-29，修改人：蒿蕊，提出人：从需求  修改原因：添加普惠贷（个人经营贷款）取T+2放款逻辑
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE      NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT           VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  --VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志

BEGIN
  VS_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  --VS_LAST_TEXT := TO_CHAR(LAST_DAY(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1)),'YYYYMMDD'); --上月月末
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_DK_GRDKYE';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------

 EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_DK_GRDKYE';
 EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_DK_GRDKYE_TEMP';



 INSERT  INTO DATACORE_IE_DK_GRDKYE_TEMP
    ( DATA_DATE --数据日期
     ,LOAN_NUM  --贷款借据编号
     ,CUST_ID   --客户号
     ,ORG_NUM   --内部机构号
     ,CURR_CD   --币种
     ,LOAN_ACCT_BAL --贷款余额
     )
    SELECT /*+ PARALLEL(8)*/
      VS_TEXT --数据日期
     ,T.LOAN_NUM  --贷款借据编号
     ,T.CUST_ID   --客户号
     ,T.ORG_NUM   --内部机构号
     ,T.CURR_CD   --币种
     ,T.LOAN_ACCT_BAL --贷款余额
    FROM  SMTMODS.L_ACCT_LOAN T
    LEFT JOIN SMTMODS.L_ACCT_LOAN T1 
    ON T.LOAN_NUM=T1.LOAN_NUM
    AND T1.DATA_DATE=TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1),'YYYYMMDD')
    --关联前一天数据，取前一天贷款余额大于0当天等于0的
    /*LEFT JOIN (SELECT DISTINCT BUSINESSCODE,
                                 PRODUCT_TYPE
                               FROM L_PBOCD_PROD_MAPPING@SUPER) M
    ON T.ACCT_NUM = M.BUSINESSCODE*/
    WHERE T.DATA_DATE=IS_DATE
      AND (T.LOAN_ACCT_BAL > 0 OR
           (T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = IS_DATE)
           OR (T.LOAN_ACCT_BAL=0 AND T1.LOAN_ACCT_BAL>0)
           OR (T.INTERNET_LOAN_FLG = 'Y' AND T.LOAN_ACCT_BAL > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')) ----modify by 87v : 互联网贷款数据晚一天下发，昨天数据今天取
         OR (T.INTERNET_LOAN_FLG = 'Y' AND T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')) ----modify by 87v : 互联网贷款数据晚一天下发，昨天数据今天取
		   OR T.CP_ID = 'DK001000100041' AND (T.LOAN_ACCT_BAL > 0 OR T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0) AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')  --[2025-09-29] [蒿蕊][JLBA202507300010][从需求]普惠贷取T+2放款数据
          )
          --  存在之前放款当天结清的数据，贷款余额为0 20231207wxb
          --  MD BY GMY 20230420 存在当天放款当天结清的数据，贷款余额为0，用放款金额与放款日期判断是否当天放款
      AND T.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
      AND (SUBSTR(T.ITEM_CD, 1, 4) IN ('1303', '1305') or T.ACCT_TYP LIKE '09%') --122贷款科目。包含个体工商户对公贷款，个体工商户贸易融资贷款
      -- 20210913 L_ACCT_LOAN增加产品代码字段，不需要关联产品代码表
      --AND T.COD_PROD NOT IN ('99999001', '99999002') --历史遗留客户
      --AND T.HXRQ IS NULL
      AND T.CANCEL_FLG = 'N'
    AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
      ;

COMMIT;

INSERT /*+ APPEND*/INTO DATACORE_IE_DK_GRDKYE NOLOGGIING
  SELECT /* +parallel(8)*/  *
    FROM DATACORE_IE_DK_GRDKYE_TEMP T
   WHERE EXISTS
          (SELECT 1
             FROM L_CUST_P_TMP F
            WHERE T.CUST_ID = F.CUST_ID
           --AND ORG_NUM NOT LIKE '0215%'
           ) ;

     COMMIT;

INSERT /*+ APPEND*/INTO DATACORE_IE_DK_GRDKYE NOLOGGIING
SELECT *
  FROM (SELECT /* +PARALLEL(8)*/
         *
          FROM DATACORE_IE_DK_GRDKYE_TEMP T
         WHERE T.CUST_ID IN ('8410028844',
                             '8410028856',
                             '8410028857',
                             '8410028859',
                             '8410029031',
                             '8410029515',
                             '8410031272',
                             '8410031486',
                             '8410031509',
                             '8500042583',
                             '8500044403',
                             '8500060972',
                             '8500062533',
                             '8500071419',
                             '8500071486',
                             '8500071842',
                             '8500078626',
                             '8500078995',
                             '8500081236')) A
 WHERE NOT EXISTS
 (SELECT 1 FROM DATACORE_IE_DK_GRDKYE B WHERE A.CUST_ID = B.CUST_ID);

     COMMIT;

INSERT  INTO DATACORE_IE_DK_GRDKYE
    ( DATA_DATE --数据日期
     ,LOAN_NUM  --贷款借据编号
     ,CUST_ID   --客户号
     ,ORG_NUM   --内部机构号
     ,CURR_CD   --币种
     ,LOAN_ACCT_BAL --贷款余额
     )
    SELECT /*+ PARALLEL(8)*/
      VS_TEXT --数据日期
     ,T.LOAN_NUM  --贷款借据编号
     ,T.CUST_ID   --客户号
     ,T.ORG_NUM   --内部机构号
     ,T.CURR_CD   --币种
     ,T.LOAN_ACCT_BAL --贷款余额
    FROM  SMTMODS.L_ACCT_LOAN T
    LEFT JOIN SMTMODS.L_ACCT_LOAN T1 
    ON T.LOAN_NUM=T1.LOAN_NUM
    AND T1.DATA_DATE=TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1),'YYYYMMDD')
    --关联前一天数据，取前一天贷款余额大于0当天等于0的
    /*LEFT JOIN (SELECT DISTINCT BUSINESSCODE,
                                 PRODUCT_TYPE
                               FROM L_PBOCD_PROD_MAPPING@SUPER) M
    ON T.ACCT_NUM = M.BUSINESSCODE*/
    WHERE T.DATA_DATE=IS_DATE
      AND (T.LOAN_ACCT_BAL > 0 OR
           (T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = IS_DATE)
           OR (T.LOAN_ACCT_BAL=0 AND T1.LOAN_ACCT_BAL>0)
           OR (T.INTERNET_LOAN_FLG = 'Y' AND T.LOAN_ACCT_BAL > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')) ----modify by 87v : 互联网贷款数据晚一天下发，昨天数据今天取
         OR (T.INTERNET_LOAN_FLG = 'Y' AND T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')) ----modify by 87v : 互联网贷款数据晚一天下发，昨天数据今天取
		   OR T.CP_ID = 'DK001000100041' AND (T.LOAN_ACCT_BAL > 0 OR T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0) AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')  --[2025-09-29] [蒿蕊][JLBA202507300010][从需求]普惠贷取T+2放款数据
          )
          --  存在之前放款当天结清的数据，贷款余额为0 20231207wxb
          --  MD BY GMY 20230420 存在当天放款当天结清的数据，贷款余额为0，用放款金额与放款日期判断是否当天放款
      AND T.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
      AND (SUBSTR(T.ITEM_CD, 1, 4) IN ('1303', '1305') or T.ACCT_TYP LIKE '09%') --122贷款科目。包含个体工商户对公贷款，个体工商户贸易融资贷款
      -- 20210913 L_ACCT_LOAN增加产品代码字段，不需要关联产品代码表
      --AND T.COD_PROD NOT IN ('99999001', '99999002') --历史遗留客户
      --AND T.HXRQ IS NULL
      AND T.CANCEL_FLG = 'N'
    AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
      AND exists (select 1 from SMTMODS.L_CUST_C f where t.cust_id=f.CUST_ID AND F.DATA_DATE=IS_DATE
                           --and ORG_NUM  not like '0215%'
                           AND F.CUST_TYP = '3');

COMMIT;

  SP_IRS_PARTITIONS(IS_DATE,'IE_DK_GRDKYE',OI_RETCODE);

  INSERT  INTO IE_DK_GRDKYE
    (  datadate  --数据日期
      ,loannum --贷款借据编号
      ,custid  --客户号
      ,corpid  --内部机构号
      ,moneysymb --币种
      ,balance --贷款余额
      ,cjrq  --采集日期
      ,nbjgh --内部机构号
      ,biz_line_id --业务条线
      ,IRS_CORP_ID --法人机构ID
     )
    SELECT /*+ PARALLEL(8)*/
      VS_TEXT --数据日期
     ,T.LOAN_NUM  --贷款借据编号
     ,T.CUST_ID   --客户号
     ,T.ORG_NUM   --内部机构号
     ,T.CURR_CD   --币种
     ,T.LOAN_ACCT_BAL --贷款余额
     ,IS_DATE
     ,T.ORG_NUM
     ,'99'
     ,CASE WHEN  T.ORG_NUM LIKE '51%' THEN '510000'
          WHEN  T.ORG_NUM LIKE '52%' THEN '520000'
          WHEN  T.ORG_NUM LIKE '53%' THEN '530000'
          WHEN  T.ORG_NUM LIKE '54%' THEN '540000'
          WHEN  T.ORG_NUM LIKE '55%' THEN '550000'
          WHEN  T.ORG_NUM LIKE '56%' THEN '560000'
          WHEN  T.ORG_NUM LIKE '57%' THEN '570000'
          WHEN  T.ORG_NUM LIKE '58%' THEN '580000'
          WHEN  T.ORG_NUM LIKE '59%' THEN '590000'
          WHEN  T.ORG_NUM LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
    FROM DATACORE_IE_DK_GRDKYE T
   /* where ORG_NUM NOT LIKE '0215%'*/
      ;

  --核心数据问题，暂时对数据进行处理
  update IE_DK_GRDKYE a set a.custid ='8923501420' where a.cjrq = IS_DATE and a.custid = '2073792758' and a.corpid like '5100%';

  commit;
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

