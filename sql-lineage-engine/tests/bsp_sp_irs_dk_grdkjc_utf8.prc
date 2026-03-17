CREATE OR REPLACE PROCEDURE BSP_SP_IRS_DK_GRDKJC(IS_DATE    IN VARCHAR2,
                                                OI_RETCODE OUT INTEGER,
                                                OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_GR_GRDKJCXXB
  -- 用途:生成接口表 JS_201_CLGRDK 存量个人贷款信息
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT 20200819
  --    MOD BY YANLINGBO AT 20200819
  --需求编号：JLBA202502100001 上线日期：2025-03-27，修改人：蒿蕊，提出人：黄俊铭
  --         修改原因：调整个人网上消费贷款的贷款产品类别
  --需求编号：无需求 上线日期：2025-06-26，修改人：蒿蕊 提出人：黄俊铭 修改原因：调整基准利率规则
  --需求编号：JLBA202507300010 上线日期：2025-09-29，修改人：蒿蕊，提出人：从需求  修改原因：添加普惠贷（个人经营贷款）取T+2放款逻辑
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT      VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  --VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志

BEGIN
  VS_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  --VS_LAST_TEXT := TO_CHAR(LAST_DAY(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1)),'YYYYMMDD'); --上月月末
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_DK_GRDKJC';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------

  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_DK_GRDKJC';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_DK_GRDKJC_TEMP';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE L_CUST_P_TMP';

  INSERT/*+ append */ INTO DATACORE_IE_DK_GRDKJC_TEMP nologging
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
     LVFDPL --利率浮动频率
    ,
     DKBLQD --贷款办理渠道
    ,
     YWXFCJ --有无消费场景
    ,
     CZBL --出资比例
     )
    SELECT /*+ USE_HASH(T,F) PARALLEL(8)*/
     VS_TEXT,
     T.ACCT_NUM --贷款合同编码
    ,
     T.LOAN_NUM --贷款借据编号
    ,
     CASE
       WHEN T.ACCT_TYP LIKE '0401%' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'D') OR (T.ITEM_CD LIKE '1305%' AND T.CURR_CD <> 'CNY') THEN
        'F081'
       WHEN T.ACCT_TYP LIKE '0402%' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'E') OR (T.ITEM_CD LIKE '1305%' AND T.CURR_CD = 'CNY') THEN
        'F082'
       WHEN T.ACCT_TYP LIKE '0101%' THEN
        'F0211'
       WHEN T.ACCT_TYP = '010301' THEN
        'F0212'
       WHEN T.ACCT_TYP IN ('010402', '010403', '010404') THEN
        'F02131'
       WHEN T.ACCT_TYP IN ('010401', '010405', '010499') THEN
        'F02132'
       WHEN T.ACCT_TYP IN ('010399','019999','010302') THEN  --[2025-03-27] [蒿蕊] [JLBA202502100001] 黄俊铭]调整个人网上消费贷款的贷款产品类别
        'F0219'
       WHEN T.ACCT_TYP = '0202' OR T.ACCT_TYP LIKE '0102%' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'A') THEN
        'F022'
       WHEN T.ACCT_TYP LIKE '0201%' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'B') THEN
        'F023'
       WHEN T.ACCT_TYP = '0801' THEN
        'F041'
       WHEN T.ACCT_TYP = '05' THEN
        'F09'
       WHEN T.ACCT_TYP = '0203' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'C') THEN
        'F12'
       WHEN T.ACCT_TYP = '0903' THEN
        'F051'
       WHEN T.ACCT_TYP LIKE '0901%' OR T.ACCT_TYP = '0902' THEN
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
     months_between(T.MATURITY_DT, T.DRAWDOWN_DT) LOAN_DATE_TYPE  --贷款期限类型
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
    ,
     /*CASE
       WHEN SUBSTR(T.INT_RATE_TYP, 1, 1) = 'F' THEN
        0 --固定利率
       ELSE
        T.BASE_INT_RAT
     END --基准利率*/
     CASE WHEN T.BASE_INT_RAT >= T.REAL_INT_RAT OR T.BASE_INT_RAT=0 OR T.BASE_INT_RAT IS NULL THEN A.BASE_INT_RAT
        ELSE T.BASE_INT_RAT
     END  --基准利率 --[2025-06-26] [蒿蕊] [无需求] [黄俊铭]由取合同表利率改为当借据表基准利率大于等于实际利率或借据表基准利率为0或空时取合同表利率，否则取借据表.基准利率
    ,
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
     T.BUSI_CHANNEL --贷款办理渠道  L层没有对应字段，对产品以及数据来源进行判断
    ,
     CASE
       WHEN (T.USEOFUNDS IS NOT NULL AND T.USEOFUNDS <> '#') THEN
        'Y'
       ELSE
        'N'
     END --有无消费场景  L层没有对应字段，改为从贷款用途进行判断
    ,
     CASE WHEN T.INTERNET_LOAN_FLG = 'Y' THEN '70'
       ELSE '100'  END --出资比例
      FROM SMTMODS.L_ACCT_LOAN T
    /*LEFT JOIN (SELECT DISTINCT BUSINESSCODE,
                                 PRODUCT_TYPE
                               FROM L_PBOCD_PROD_MAPPING@SUPER) M
    ON T.ACCT_NUM = M.BUSINESSCODE*/
    LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT A
    ON T.ACCT_NUM = A.CONTRACT_NUM
    AND A.DATA_DATE = IS_DATE
    LEFT JOIN SMTMODS.L_ACCT_LOAN T1
    ON T.LOAN_NUM=T1.LOAN_NUM
    AND T1.DATA_DATE=TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1),'YYYYMMDD')
    --关联前一天数据，取前一天贷款余额大于0当天等于0的
     WHERE T.DATA_DATE = IS_DATE
      AND  (T.LOAN_ACCT_BAL > 0 OR
           (T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = IS_DATE) OR
           (T.LOAN_ACCT_BAL=0 AND T1.LOAN_ACCT_BAL>0)
           OR (T.INTERNET_LOAN_FLG = 'Y' AND T.LOAN_ACCT_BAL > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')) ----modify by 87v : 互联网贷款数据晚一天下发，昨天数据今天取
         OR (T.INTERNET_LOAN_FLG = 'Y' AND T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')) ----modify by 87v : 互联网贷款数据晚一天下发，昨天数据今天取
		   OR T.CP_ID = 'DK001000100041' AND (T.LOAN_ACCT_BAL > 0 OR T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0) AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')  --[2025-09-29] [蒿蕊][JLBA202507300010][从需求]普惠贷取T+2放款数据
          )
          --  存在之前放款当天结清的数据，贷款余额为0 20231207wxb
          --  MD BY GMY 20230420 存在当天放款当天结清的数据，贷款余额为0，用放款金额与放款日期判断是否当天放款
       AND T.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD') --（需要报送人民币 美元 日元 欧元 港币）
       AND (SUBSTR(T.ITEM_CD, 1, 4) IN ('1303', '1305') or
           T.ACCT_TYP LIKE '09%') --122贷款科目。包含个体工商户对公贷款，个体工商户贸易融资贷款
          -- 20210913 L_ACCT_LOAN增加产品代码字段，不需要关联产品代码表
          --AND T.COD_PROD NOT IN ('99999001', '99999002') --历史遗留客户
          --AND T.HXRQ IS NULL
       AND T.CANCEL_FLG = 'N'
     AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
     ;
  COMMIT;

INSERT /*+ APPEND*/INTO L_CUST_P_TMP NOLOGING
SELECT /* +parallel(8)*/  A.CUST_ID FROM SMTMODS.L_CUST_P A WHERE A.DATA_DATE = IS_DATE;

COMMIT;

INSERT /*+ APPEND*/INTO DATACORE_IE_DK_GRDKJC NOLOGGIING
  SELECT /* +parallel(8)*/  *
    FROM DATACORE_IE_DK_GRDKJC_TEMP T
   WHERE EXISTS
          (SELECT 1
             FROM L_CUST_P_TMP F
            WHERE T.CUST_ID = F.CUST_ID
           --AND ORG_NUM NOT LIKE '0215%'
           ) ;

     COMMIT;

INSERT /*+ APPEND*/INTO DATACORE_IE_DK_GRDKJC NOLOGGIING
SELECT *
  FROM (SELECT /* +PARALLEL(8)*/
         *
          FROM DATACORE_IE_DK_GRDKJC_TEMP T
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
 (SELECT 1 FROM DATACORE_IE_DK_GRDKJC B WHERE A.CUST_ID = B.CUST_ID);

     COMMIT;

INSERT/*+ append*/ INTO DATACORE_IE_DK_GRDKJC nologging
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
     LVFDPL --利率浮动频率
    ,
     DKBLQD --贷款办理渠道
    ,
     YWXFCJ --有无消费场景
    ,
     CZBL --出资比例
     )
    SELECT /*+ USE_HASH(T,F) PARALLEL(8)*/
     VS_TEXT,
     T.ACCT_NUM --贷款合同编码
    ,
     T.LOAN_NUM --贷款借据编号
    ,
     CASE
       WHEN T.ACCT_TYP LIKE '0401%' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'D') OR (T.ITEM_CD LIKE '1305%' AND T.CURR_CD <> 'CNY') THEN
        'F081'
       WHEN T.ACCT_TYP LIKE '0402%' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'E') OR (T.ITEM_CD LIKE '1305%' AND T.CURR_CD = 'CNY') THEN
        'F082'
       WHEN T.ACCT_TYP LIKE '0101%' THEN
        'F0211'
       WHEN T.ACCT_TYP = '010301' THEN
        'F0212'
       WHEN T.ACCT_TYP IN ('010402', '010403', '010404') THEN
        'F02131'
       WHEN T.ACCT_TYP IN ('010401', '010405', '010499') THEN
        'F02132'
       WHEN T.ACCT_TYP IN ('010399','019999','010302') THEN --[2025-03-27] [蒿蕊] [JLBA202502100001] 黄俊铭]调整个人网上消费贷款的贷款产品类别
        'F0219'
       WHEN T.ACCT_TYP = '0202' OR T.ACCT_TYP LIKE '0102%' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'A') THEN
        'F022'
       WHEN T.ACCT_TYP LIKE '0201%' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'B') THEN
        'F023'
       WHEN T.ACCT_TYP = '0801' THEN
        'F041'
       WHEN T.ACCT_TYP = '05' THEN
        'F09'
       WHEN T.ACCT_TYP = '0203' OR
            (T.ACCT_TYP = '070101' AND T.ONLENDING_USAGE = 'C') THEN
        'F12'
       WHEN T.ACCT_TYP = '0903' THEN
        'F051'
       WHEN T.ACCT_TYP LIKE '0901%' OR T.ACCT_TYP = '0902' THEN
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
    ,
     /*CASE
       WHEN SUBSTR(T.INT_RATE_TYP, 1, 1) = 'F' THEN
        0 --固定利率
       ELSE
        T.BASE_INT_RAT
     END --基准利率*/
     CASE WHEN T.BASE_INT_RAT >= T.REAL_INT_RAT OR T.BASE_INT_RAT=0 OR T.BASE_INT_RAT IS NULL THEN A.BASE_INT_RAT
        ELSE T.BASE_INT_RAT
     END --基准利率 --[2025-06-26] [蒿蕊] [无需求] [黄俊铭]由取合同表利率改为当借据表基准利率大于等于实际利率或借据表基准利率为0或空时取合同表利率，否则取借据表.基准利率
    ,
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
     T.BUSI_CHANNEL --贷款办理渠道  L层没有对应字段，对产品以及数据来源进行判断
    ,
     CASE
       WHEN (T.USEOFUNDS IS NOT NULL AND T.USEOFUNDS <> '#') THEN
        'Y'
       ELSE
        'N'
     END --有无消费场景  L层没有对应字段，改为从贷款用途进行判断
    ,
      CASE WHEN T.INTERNET_LOAN_FLG = 'Y' THEN '70'
       ELSE '100'  END --出资比例
      FROM SMTMODS.L_ACCT_LOAN T
      LEFT JOIN SMTMODS.L_ACCT_LOAN T1
        ON T.LOAN_NUM=T1.LOAN_NUM
       AND T1.DATA_DATE=TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1),'YYYYMMDD')
       --关联前一天数据，取前一天贷款余额大于0当天等于0的
    LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT A
    ON T.ACCT_NUM = A.CONTRACT_NUM
    AND A.DATA_DATE = IS_DATE
     WHERE T.DATA_DATE = IS_DATE
      AND (T.LOAN_ACCT_BAL > 0 OR
           (T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = IS_DATE) OR
           (T.LOAN_ACCT_BAL=0 AND T1.LOAN_ACCT_BAL>0)
           OR (T.INTERNET_LOAN_FLG = 'Y' AND T.LOAN_ACCT_BAL > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')) ----modify by 87v : 互联网贷款数据晚一天下发，昨天数据今天取
         OR (T.INTERNET_LOAN_FLG = 'Y' AND T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')) ----modify by 87v : 互联网贷款数据晚一天下发，昨天数据今天取
		 OR T.CP_ID = 'DK001000100041' AND (T.LOAN_ACCT_BAL > 0 OR T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0) AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')  --[2025-09-29] [蒿蕊][JLBA202507300010][从需求]普惠贷取T+2放款数据
          )
          --  存在之前放款当天结清的数据，贷款余额为0 20231207wxb
          --  MD BY GMY 20230420 存在当天放款当天结清的数据，贷款余额为0，用放款金额与放款日期判断是否当天放款
       AND T.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD') --（需要报送人民币 美元 日元 欧元 港币）
       AND (SUBSTR(T.ITEM_CD, 1, 4) IN ('1303', '1305') or
           T.ACCT_TYP LIKE '09%') --122贷款科目。包含个体工商户对公贷款，个体工商户贸易融资贷款
          -- 20210913 L_ACCT_LOAN增加产品代码字段，不需要关联产品代码表
          --AND T.COD_PROD NOT IN ('99999001', '99999002') --历史遗留客户
          --AND T.HXRQ IS NULL
       AND T.CANCEL_FLG = 'N'
     AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
       AND exists (select 1
                      from SMTMODS.L_CUST_C f
                     where t.cust_id = f.CUST_ID
                       AND F.DATA_DATE = IS_DATE
                       --and ORG_NUM not like '0215%'
                       AND F.CUST_TYP = '3');

    COMMIT;

  SP_IRS_PARTITIONS(IS_DATE, 'IE_DK_GRDKJC', OI_RETCODE);

  INSERT/*+ APPEND*/ INTO IE_DK_GRDKJC NOLOGGING
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
     busichannel --贷款办理渠道
    ,
     consumpscenflg --有无消费场景
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
    SELECT/*+ PARALLEL(8)*/ DATA_DATE,
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
           LOAN_GRANT_DATE --贷款发放日期  'yyyy-mm-dd'
          ,
           LOAN_DUE_DATE --原始到期日期    'yyyy-mm-dd'
          ,
           FINISH_DT --实际终止日期        'yyyy-mm-dd'
          ,
           CASE
             WHEN t.LOAN_DATE_TYPE < 3 THEN
              '01'
             WHEN t.LOAN_DATE_TYPE = 3 THEN
              '02'
             WHEN t.LOAN_DATE_TYPE < 6 THEN
              '03'
             WHEN t.LOAN_DATE_TYPE = 6 THEN
              '04'
             WHEN t.LOAN_DATE_TYPE < 12 THEN
              '05'
             WHEN t.LOAN_DATE_TYPE = 12 THEN
              '06'
             WHEN t.LOAN_DATE_TYPE <= 36 THEN
              '07'
             WHEN t.LOAN_DATE_TYPE <= 60 THEN
              '08'
             WHEN t.LOAN_DATE_TYPE <= 120 THEN
              '09'
             WHEN t.LOAN_DATE_TYPE <= 240 THEN
              '10'
             WHEN t.LOAN_DATE_TYPE <= 360 THEN
              '11'
             WHEN t.LOAN_DATE_TYPE > 360 THEN
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
           LVFDPL --利率浮动频率
          ,
           DKBLQD --贷款办理渠道
          ,
           YWXFCJ --有无消费场景
          ,
           CZBL --出资比例
          ,
           IS_DATE --采集日期
          ,
           ORG_NUM --内部机构号
          ,
           '99'
          ,
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
      FROM DATACORE_IE_DK_GRDKJC T
     /*where ORG_NUM NOT LIKE '0215%'*/;
  COMMIT;

  --核心数据问题，暂时对数据进行处理
  update IE_DK_GRDKJC a set a.custid ='8923501420' where a.cjrq = IS_DATE and a.custid = '2073792758' and a.corpid like '5100%';

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

