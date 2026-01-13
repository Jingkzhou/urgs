CREATE OR REPLACE PROCEDURE BSP_SP_IRS_DK_FTYDWDKJC(IS_DATE     IN VARCHAR2,
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
  --需求编号：JLBA202502100001 上线日期：2025-03-27，修改人：蒿蕊，提出人：黄俊铭
  --         修改原因：调整个人网上消费贷款的贷款产品类别
  --需求编号：无需求 上线日期：2025-06-26，修改人：蒿蕊 提出人：黄俊铭 修改原因：调整基准利率规则
  --需求编号：JLBA202510230006 上线日期：2025-12-04，修改人：蒿蕊 提出人：黄俊铭 修改原因：修改生产缺陷添加贷款账户类型是04贸易融资的转码
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT      VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  --VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志

BEGIN
  VS_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  --VS_LAST_TEXT := TO_CHAR(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1),'YYYYMMDD');
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_DK_FTYDWDKJC';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------
  /* EXECUTE IMMEDIATE 'TRUNCATE TABLE IE_DK_DWDKJC_TMP1';

  INSERT INTO IE_DK_DWDKJC_TMP1
  SELECT DISTINCT CUST_ID
  FROM SMTMODS.L_CUST_P
  WHERE DATA_DATE =IS_DATE
  AND ORG_NUM NOT LIKE '0215%';
  COMMIT;
  INSERT INTO IE_DK_DWDKJC_TMP1
  SELECT DISTINCT CUST_ID
  FROM SMTMODS.L_CUST_C
  WHERE DATA_DATE =IS_DATE
  AND ORG_NUM NOT LIKE '0215%';
  COMMIT;*/

  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_DK_FTYDWDKJC ';
  INSERT INTO DATACORE_IE_DK_FTYDWDKJC
    (DATA_DATE --数据日期
    ,
     ACCT_NUM --贷款合同编码
    ,
     LOAN_NUM --贷款借据编号
    ,
     PRODUCT_TYPE --贷款产品类别
    ,
     CUST_ID --客户号
    ,
     ORG_NUM --内部机构号
    ,
     LOAN_GRANT_DATE --贷款发放日期
    ,
     LOAN_DUE_DATE --原始到期日期
    ,
     FINISH_DT --实际终止日期
    ,
     LOAN_DATE_TYPE --贷款期限类型
    ,
     INT_RATE_TYP --利率类型
    ,
     PRI_BENCH_MARK --定价基准类型
    ,
     BASE_INT_RAT --基准利率
    ,
     REAL_INT_RAT --实际利率
    ,
     LLFD --利率浮动频率
    ,
     LOAN_PURPOSE_CD --贷款实际投向
    ,
     dkblqd --贷款办理渠道
    ,
     CZBL --出资比例
     )
    SELECT /*+ USE_HASH(T,C) PARALLEL(8)*/
     VS_TEXT,
     T.ACCT_NUM --贷款合同编码
    ,
     T.LOAN_NUM --贷款借据编号
    ,
     CASE
       WHEN T.ACCT_TYP LIKE '0101%' THEN
        'F0211'
       WHEN T.ACCT_TYP = '010301' THEN
        'F0212'
       WHEN T.ACCT_TYP IN ('010402', '010403', '010404') THEN
        'F02131'
       WHEN T.ACCT_TYP IN ('010401', '010405', '010499') THEN
        'F02132'
       WHEN T.ACCT_TYP IN ('010399','010302') THEN  --[2025-03-27] [蒿蕊] [JLBA202502100001] 黄俊铭]调整个人网上消费贷款的贷款产品类别
        'F0219'
       WHEN (T.ACCT_TYP = '0202' OR T.ACCT_TYP LIKE '0102%' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'A')) THEN
        'F022'
       WHEN (T.ACCT_TYP LIKE '0201%' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'B')) THEN
        'F023'
       WHEN T.ACCT_TYP = '0801' THEN
        'F041'
       WHEN (T.ACCT_TYP LIKE '0401%' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'D')) THEN
        'F081'
       WHEN (T.ACCT_TYP LIKE '0402%' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'E')) THEN
        'F082'
	   WHEN T.ACCT_TYP = '04' AND D.INLANDORRSHORE_FLG = 'Y' THEN 'F082'  --[2025-12-04] [蒿蕊] [JLBA202510230006][黄俊铭]添加贷款账户类型是贸易融资的转码,贷款账户类型是贸易融资并且是境内客户报F082：国内贸易融资
	   WHEN T.ACCT_TYP = '04' AND D.INLANDORRSHORE_FLG = 'N' THEN 'F081'  --[2025-12-04] [蒿蕊] [JLBA202510230006][黄俊铭]添加贷款账户类型是贸易融资的转码,贷款账户类型是贸易融资并且是境外客户报F081：国外贸易融资
       WHEN T.ACCT_TYP = '05' THEN
        'F09'
       WHEN (T.ACCT_TYP = '0203' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'C')) THEN
        'F12'
       WHEN T.ACCT_TYP = '0903' THEN
        'F051'
       WHEN (T.ACCT_TYP LIKE '0901%' OR T.ACCT_TYP = '0902') THEN
        'F052'
       WHEN T.ACCT_TYP LIKE '0904%' THEN
        'F053'
       WHEN SUBSTR(T.ACCT_TYP, 1, 4) IN ('0905', '0999') THEN
        'F059'
       ELSE
        'F99'
     END AS LOANPRODUCTTYPE --贷款产品类别
    ,
     T.CUST_ID --客户号
    ,
     T.ORG_NUM --内部机构号
    ,
     TO_CHAR(T.DRAWDOWN_DT, 'YYYY-MM-DD') --贷款发放日期  'yyyy-mm-dd'
    ,
     TO_CHAR(T.MATURITY_DT, 'YYYY-MM-DD') --原始到期日期    'yyyy-mm-dd'
    ,
     TO_CHAR(T.FINISH_DT, 'YYYY-MM-DD') --实际终止日期        'yyyy-mm-dd'
    ,
     months_between(T.MATURITY_DT, T.DRAWDOWN_DT) LOAN_DATE_TYPE --贷款期限类型
    ,
     CASE
       WHEN SUBSTR(T.INT_RATE_TYP, 1, 1) = 'F' THEN
        'RF01' --固定
       WHEN SUBSTR(T.INT_RATE_TYP, 1, 1) = 'L' THEN
        'RF02' --浮动
       ELSE
        ''
     END --利率类型
    ,
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
     END AS PRICINGTYPE --定价基准类型
    , /*CASE WHEN   SUBSTR (T.INT_RATE_TYP,1,1) ='F'  THEN 0 --固定利率
               ELSE T.BASE_INT_RAT END --基准利率*/
     CASE WHEN T.BASE_INT_RAT >= T.REAL_INT_RAT OR T.BASE_INT_RAT=0 OR T.BASE_INT_RAT IS NULL THEN A.BASE_INT_RAT
        ELSE T.BASE_INT_RAT
     END
    , --基准利率 --[2025-06-26] [蒿蕊] [无需求] [黄俊铭]由取合同表利率改为当借据表基准利率大于等于实际利率或借据表基准利率为0或空时取合同表利率，否则取借据表.基准利率
     T.REAL_INT_RAT --实际利率
    ,
     CASE
       WHEN SUBSTR(T.INT_RATE_TYP, 1, 1) = 'F' THEN
        '' --固定利率
       WHEN MONTHS_BETWEEN(T.MATURITY_DT, T.DRAWDOWN_DT) <= '12' and T.INT_RATE_TYP = 'L5'
          THEN '03'  --20250324 存在贷款期限类型为一年以内，但是利率浮动频率为按年的，给到按月
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
     END --其他--利率浮动频率
    ,
     CASE
       WHEN T.LOAN_NUM = '20220901038855001' THEN
        'G595'
       ELSE
        SUBSTRB(T.LOAN_PURPOSE_CD, 1, 4)
     END LOAN_PURPOSE_CD --贷款实际投向           --此借据贷款投向存在问题，与业务与客户经理确认进行修改
    ,
     T.BUSI_CHANNEL --贷款办理渠道  L层没有对应字段，对产品以及数据来源进行判断
    ,
     '100' --出资比例
      FROM SMTMODS.L_ACCT_LOAN T
      LEFT JOIN SMTMODS.L_ACCT_LOAN T1 
        ON T.LOAN_NUM=T1.LOAN_NUM
       AND T1.DATA_DATE=TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1),'YYYYMMDD')
       --关联前一天数据，取前一天贷款余额大于0当天等于0的
      LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT A
        ON T.ACCT_NUM = A.CONTRACT_NUM
       AND A.DATA_DATE = IS_DATE 
     INNER JOIN SMTMODS.L_CUST_C C
        ON T.CUST_ID = C.CUST_ID
       AND C.DATA_DATE = IS_DATE
       AND C.CUST_TYP <> '3'
	 INNER JOIN SMTMODS.L_CUST_ALL D  --[2025-12-04] [蒿蕊] [JLBA202510230006]贷款产品类别是04贸易融资时无法区分国内外，按客户的境内境外标志判断
	    ON T.CUST_ID = D.CUST_ID
	   AND D.DATA_DATE = T.DATA_DATE
    --AND C.DATE_SOURCESD = 'CMS'
    /*LEFT JOIN (SELECT DISTINCT BUSINESSCODE,
                                 PRODUCT_TYPE,
                                 PRODUCT_TYPE_SG
                               FROM L_PBOCD_PROD_MAPPING@SUPER) M
    ON T.ACCT_NUM = M.BUSINESSCODE*/
     WHERE T.DATA_DATE = IS_DATE
       AND (T.LOAN_ACCT_BAL > 0 OR
           (T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = IS_DATE) OR
           (T.LOAN_ACCT_BAL=0 AND T1.LOAN_ACCT_BAL>0) )
          --  存在之前放款当天结清的数据，贷款余额为0 20231207wxb
          --  MD BY GMY 20230420 存在当天放款当天结清的数据，贷款余额为0，用放款金额与放款日期判断是否当天放款
       AND T.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
       AND (SUBSTR(T.ITEM_CD, 1, 4) IN ('1303', '1305') or
           T.ACCT_TYP LIKE '09%') -- 20210913 L_ACCT_LOAN增加产品代码字段，不需要关联产品代码表
          --AND T.COD_PROD NOT IN ('99999001', '99999002') --历史遗留客户
          --AND T.HXRQ IS NULL --去掉核销数据
       AND T.CANCEL_FLG = 'N'
     AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
    --AND T.CUST_NUM IS NOT NULL   --20210913 客户表中没有区分是否为信贷系统数据，但是在贷款L_ACCT_LOAN中新增信贷客户字段
    ;

  SP_IRS_PARTITIONS(IS_DATE, 'IE_DK_DWDKJC', OI_RETCODE);
  INSERT INTO IE_DK_DWDKJC
    (datadate --数据日期
    ,
     contractnum --贷款合同编码
    ,
     loannum --贷款借据编号
    ,
     loanproducttype --贷款产品类别
    ,
     custid --客户号
    ,
     corpid --内部机构号
    ,
     drawdowndt --贷款发放日期
    ,
     maturitydt --原始到期日期
    ,
     actualduedate --实际终止日期
    ,
     loantermtype --贷款期限类型
    ,
     ratetype --利率类型
    ,
     pricingtype --定价基准类型
    ,
     baserate --基准利率
    ,
     realrate --实际利率
    ,
     floatfreq --利率浮动频率
    ,
     LOANPURPOSECD --贷款实际投向
    ,
     busichannel --贷款办理渠道
    ,
     loanratio --出资比例
    ,
     cjrq --采集日期
    ,
     nbjgh --内部机构号
    ,
     biz_line_id --业务条线
    ,
     IRS_CORP_ID --法人机构ID
     )
    SELECT VS_TEXT,
           ACCT_NUM --贷款合同编码
          ,
           LOAN_NUM --贷款借据编号
          ,
           PRODUCT_TYPE --贷款产品类别
          ,
           CUST_ID --客户号
          ,
           ORG_NUM --内部机构号
          ,
           LOAN_GRANT_DATE --贷款发放日期
          ,
           LOAN_DUE_DATE --原始到期日期
          ,
           FINISH_DT --实际终止日期
          ,
           CASE
             WHEN LOAN_DATE_TYPE < 3 THEN
              '01'
             WHEN LOAN_DATE_TYPE = 3 THEN
              '02'
             WHEN LOAN_DATE_TYPE < 6 THEN
              '03'
             WHEN LOAN_DATE_TYPE = 6 THEN
              '04'
             WHEN LOAN_DATE_TYPE < 12 THEN
              '05'
             WHEN LOAN_DATE_TYPE = 12 THEN
              '06'
             WHEN LOAN_DATE_TYPE <= 36 THEN
              '07'
             WHEN LOAN_DATE_TYPE <= 60 THEN
              '08'
             WHEN LOAN_DATE_TYPE <= 120 THEN
              '09'
             WHEN LOAN_DATE_TYPE <= 240 THEN
              '10'
             WHEN LOAN_DATE_TYPE <= 360 THEN
              '11'
             WHEN LOAN_DATE_TYPE > 360 THEN
              '12'
             ELSE
              ''
           END LOAN_DATE_TYPE --贷款期限类型
          ,
           INT_RATE_TYP --利率类型
          ,
           PRI_BENCH_MARK --定价基准类型
          ,
           BASE_INT_RAT --基准利率
          ,
           REAL_INT_RAT --实际利率
          ,
           LLFD --利率浮动频率
          ,
           LOAN_PURPOSE_CD --贷款实际投向
          ,
           T.DKBLQD --贷款办理渠道
          ,
           '100' --出资比例
          ,
           IS_DATE --采集日期
          ,
           ORG_NUM --内部机构号
          ,
           '99',
           CASE WHEN  T.ORG_NUM LIKE '51%' THEN '510000'
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
      FROM DATACORE_IE_DK_FTYDWDKJC T
     where /*ORG_NUM NOT LIKE '0215%'
         and*/
     T.CUST_ID not IN ('8410028844',
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
                       '8500081236',
                       '8915832313',
                       '8915242461',
                       '8912668640',
                       '8911953837',
                       '8915587103',
                       '8915998116',
                       '8916156576')
    /*AND EXISTS
    (SELECT 1 FROM IE_DK_DWDKJC_TMP1 C WHERE T.CUST_ID = C.CUST_ID)*/
    ;

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

