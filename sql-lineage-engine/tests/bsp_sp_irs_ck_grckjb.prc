CREATE OR REPLACE PROCEDURE BSP_SP_IRS_CK_GRCKJB(IS_DATE     IN VARCHAR2,
                                                                  OI_RETCODE  OUT INTEGER,
                                                                  OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_CK_GRCKJB
  -- 用途:生成个人存款基本信息表
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  -- 版本
  --    高铭言 20210520
  -- 版权
  --     中软融鑫
  --需求编号：数据维护单 上线日期：2025-12-17，修改人：蒿蕊 提出人：黄俊铭 修改原因：个体工商户判断优先以NGI客户类型为准，非NGI客户则根据柜面存款人类别判断
  ------------------------------------------------------------------------------------------------------
  VI_ERRORCODE      NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT           VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(40) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(30); --存储过程执行步骤标志
  VS_15_DATE        VARCHAR2(30);
  VS_YES_DATE       VARCHAR2(30);

BEGIN
  VS_TEXT     := IS_DATE;
  VS_15_DATE  := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 16, 'YYYYMMDD');
  VS_YES_DATE := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD');
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_CK_GRCKJB';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);
  --------------------------------------------------------------------------------------------------------------

  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_CK_GRCKJB';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_CK_GRCKJB_TMP2';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_CK_GRCKJB_TMP3';

  --插入当天存款余额为0，但是有发生额的账户
  INSERT INTO DATACORE_IE_CK_GRCKJB_TMP2
    SELECT /*+ USE_HASH(A,B,C,E) PARALLEL(8)*/
     TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD') --数据日期
    ,
     A.ACCT_NUM --存款账户编码
    ,
     A.DEPOSIT_NUM --存款序号
    ,
     A.ORG_NUM --内部机构号
    ,
     A.CUST_ID --客户号
    ,
     CASE
       WHEN A.ACCT_TYPE = '0401' THEN
        'D031' --一天通知
       WHEN A.ACCT_TYPE = '0402' THEN
        'D032' --七天通知
       WHEN E.ACCT_TYP = '111' THEN
        'D061' --银行承兑汇票保证金存款
       WHEN E.ACCT_TYP like '31%' THEN
        'D062' --信用证保证金存款
       WHEN E.ACCT_TYP IN ('121', '211') THEN
        'D063' --保函保证金存款
       WHEN (E.ACCT_TYP IN ('511', '521', '522', '523', '531') OR
            A.GL_ITEM_CODE in ('20110114', '20110115')) THEN
        'D069' --其他保证金存款                   --modify by gmy 20220520 增加保证金存款
       WHEN A.GL_ITEM_CODE IN ('20110101', '20110201') THEN
        'D013' --活期储蓄存款
       WHEN A.GL_ITEM_CODE = '20110103' THEN
        'D0141' --定期整存整取存款
       WHEN A.GL_ITEM_CODE IN
            ('20110104', '20110105', '20110108', '20110109') THEN
        'D0149' --其他定期储蓄存款
       WHEN A.GL_ITEM_CODE = '20110102' THEN
        'D02' --定活两便存款
       WHEN A.GL_ITEM_CODE = '20110111' THEN
        'D091' --信用卡存款(不存在准贷记卡存款，全部为贷记卡存款)
     END AS PROD_TYPE,
     TO_CHAR(A.ACCT_OPDATE, 'YYYY-MM-DD') --起始日期
    ,
     CASE
       WHEN A.ACCT_TYPE = '0401' AND A.MATUR_DATE IS NULL THEN
        '1999-01-01'
       WHEN A.ACCT_TYPE = '0402' AND A.MATUR_DATE IS NULL THEN
        '1999-01-07'
       ELSE
        TO_CHAR(A.MATUR_DATE, 'YYYY-MM-DD')
     END --到期日期
    ,
     TO_CHAR(A.ACCT_CLDATE, 'YYYY-MM-DD') --实际终止日期
    ,
     CASE

       WHEN (A.ACCT_TYPE = '0500'
        /*OR A.GL_ITEM_CODE IN ('20110114') OR (A.ACCT_TYPE NOT IN ('0401','0402') AND E.ACCT_TYP IN ('111','121','211','311','312','511','521','522','523','531'))*/) THEN
        '01' --活期    --20231211  wxb  活期账户类型0500    20240906 个人活期保证金存款'20110114',单位活期保证金存款'20110209'给活期
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 60 THEN
        '16' --5年以上
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 60 THEN
        '15' --5年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 36 THEN
        '14' --3年-5年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 36 THEN
        '13' --3年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 24 THEN
        '12' --2年-3年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 24 THEN
        '11' --2年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 12 THEN
        '10' --1年-2年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 12 THEN
        '09' --1年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 6 THEN
        '08' --6-12个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 6 THEN
        '07' --6个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 3 THEN
        '06' --3-6个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 3 THEN
        '05' --3
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 1 THEN
        '04' --1-3个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 1 THEN
        '03' --1个月
       ELSE
        '02'
     END AS TERM_TYPE --存款期限类型
    ,
     'TR07' --定价基准类型
    ,
     CASE
       WHEN SUBSTR(A.INT_RATE_TYP, 1, 1) = 'F' THEN
        'RF01' --固定
       WHEN SUBSTR(A.INT_RATE_TYP, 1, 1) = 'L' THEN
        'RF02' --浮动
       ELSE
        ''
     END --利率类型
    ,
     NVL(A.INT_RATE, 0) AS REALRATE --实际利率
    ,
     NVL(A.Pboc_Base_Rate, 0) AS BASERATE --基准利率
    ,
     '99' --利率浮动频率
    ,
     '' --保底收益率
    ,
     '' --最高收益率
    ,
     CASE
       WHEN A.OPEN_CHANNEL IN ('01', '04') THEN
        '01'
       WHEN A.OPEN_CHANNEL IN ('02', '03', '05') THEN
        '02'
       WHEN A.OPEN_CHANNEL = '06' THEN
        '03'
       ELSE
        '99'
     END AS BUSICHANNEL --开户渠道
    ,
     'N' --异地存款标志
    ,

     CASE
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_BALANCE * B.CCY_RATE >= '3000000' THEN
        'A' --大额存款
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_BALANCE * B.CCY_RATE < '3000000' THEN
        'B' --小额存款
       ELSE
        ''
     END AS ACCT_BALANCE_FLAG,
     A.ACCT_TYPE --账户类型
    ,
     A.ST_INT_DT AS ST_INT_DT2 --起息日期
    ,
     A.MATUR_DATE AS MATUR_DATE2, --到期日期
     TO_CHAR(A.ACCT_CLDATE, 'YYYY-MM-DD'), --销户日期
     A.GL_ITEM_CODE, --科目
     A.POC_INDEX_CODE -- 产品编码
      FROM SMTMODS.L_ACCT_DEPOSIT A --存款账户信息表
     INNER JOIN SMTMODS.L_PUBL_RATE B --汇率表
        ON A.CURR_CD = B.BASIC_CCY --账户币种
       AND B.CCY_DATE = TO_DATE(IS_DATE, 'yyyymmdd') --汇率日期
       AND A.DATA_DATE = B.DATA_DATE
       AND B.FORWARD_CCY = 'USD' --折算币种
      LEFT JOIN SMTMODS.L_CUST_P C
        ON A.CUST_ID = C.CUST_ID
       AND A.DATA_DATE = C.DATA_DATE
      LEFT JOIN SMTMODS.L_ACCT_OBS_LOAN E
        ON A.ACCT_NUM = E.SECURITY_ACCT_NUM
       AND A.DATA_DATE = E.DATA_DATE --modify by gmy 20220520 增加与表外表的关联
     WHERE (A.GL_ITEM_CODE = '20110101' --个人活期存款
           OR A.GL_ITEM_CODE LIKE '20110111%' --个人信用卡存款
           OR A.GL_ITEM_CODE = '20110103' --个人整存整取定期储蓄存款
           OR A.GL_ITEM_CODE = '20110104' --个人零存整取定期储蓄存款
           OR A.GL_ITEM_CODE = '20110105' --个人存本取息定期储蓄存款
           OR A.GL_ITEM_CODE = '20110108' --个人教育储蓄存款
           OR A.GL_ITEM_CODE = '20110109' --个人其他定期储蓄存款
           OR A.GL_ITEM_CODE = '20110102' --个人定活两便存款
           OR A.GL_ITEM_CODE = '20110114' --个人活期保证金存款
           OR A.GL_ITEM_CODE = '20110115' --个人定期保证金存款
           OR A.GL_ITEM_CODE LIKE '20110110%' --个人通知存款
           OR
           (A.GL_ITEM_CODE LIKE '20110201%' AND C.OPERATE_CUST_TYPE = 'A')) --单位活期存款
       AND A.ACCT_BALANCE = 0
       AND A.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
       AND A.DATA_DATE = IS_DATE;

  COMMIT;

  --插入当天存款余额为0，但是有发生额的账户（个体工商户）
  INSERT INTO DATACORE_IE_CK_GRCKJB_TMP2
    SELECT /*+ USE_HASH(A,B,C,D,E) PARALLEL(8)*/
     TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD') --数据日期
    ,
     A.ACCT_NUM --存款账户编码
    ,
     A.DEPOSIT_NUM --存款序号
    ,
     A.ORG_NUM --内部机构号
    ,
     A.CUST_ID --客户号
    ,
     CASE
       WHEN A.ACCT_TYPE = '0401' THEN
        'D031' --一天通知
       WHEN A.ACCT_TYPE = '0402' THEN
        'D032' --七天通知
       WHEN E.ACCT_TYP = '111' THEN
        'D061' --银行承兑汇票保证金存款
       WHEN E.ACCT_TYP like '31%' THEN
        'D062' --信用证保证金存款
       WHEN E.ACCT_TYP IN ('121', '211') THEN
        'D063' --保函保证金存款
       WHEN (E.ACCT_TYP IN ('511', '521', '522', '523', '531') OR
            A.GL_ITEM_CODE in ('20110114', '20110115','20110209', '20110210')) THEN
        'D069' --其他保证金存款                   --modify by gmy 20220520 增加保证金存款   20240906 新增个体工商户的单位保证金存款
       WHEN A.GL_ITEM_CODE IN ('20110101', '20110201') THEN
        'D013' --活期储蓄存款
       WHEN A.GL_ITEM_CODE = '20110103' THEN
        'D0141' --定期整存整取存款
       WHEN A.GL_ITEM_CODE IN
            ('20110104', '20110105', '20110108', '20110109') THEN
        'D0149' --其他定期储蓄存款
       WHEN A.GL_ITEM_CODE = '20110102' THEN
        'D02' --定活两便存款
       WHEN A.GL_ITEM_CODE = '20110111' THEN
        'D091' --信用卡存款(不存在准贷记卡存款，全部为贷记卡存款)
	   WHEN A.GL_ITEM_CODE = '20110202' THEN  'D0141' --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]新增个体工商户的单位一般定期存款
     END AS PROD_TYPE,
     TO_CHAR(A.ACCT_OPDATE, 'YYYY-MM-DD') --起始日期
    ,
     CASE
       WHEN A.ACCT_TYPE = '0401' AND A.MATUR_DATE IS NULL THEN
        '1999-01-01'
       WHEN A.ACCT_TYPE = '0402' AND A.MATUR_DATE IS NULL THEN
        '1999-01-07'
       ELSE
        TO_CHAR(A.MATUR_DATE, 'YYYY-MM-DD')
     END --到期日期
    ,
     TO_CHAR(A.ACCT_CLDATE, 'YYYY-MM-DD') --实际终止日期
    ,
     CASE
     /*       WHEN A.ACCT_TYPE = '00' THEN
     '01' --活期*/
       WHEN (A.ACCT_TYPE = '0500'
        /*OR A.GL_ITEM_CODE IN ('20110209') OR (A.ACCT_TYPE NOT IN ('0401','0402') AND E.ACCT_TYP IN ('111','121','211','311','312','511','521','522','523','531'))*/) THEN
        '01' --活期    --20231211  wxb  活期账户类型0500    20240906 个人活期保证金存款'20110114',单位活期保证金存款'20110209'给活期
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 60 THEN
        '16' --5年以上
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 60 THEN
        '15' --5年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 36 THEN
        '14' --3年-5年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 36 THEN
        '13' --3年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 24 THEN
        '12' --2年-3年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 24 THEN
        '11' --2年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 12 THEN
        '10' --1年-2年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 12 THEN
        '09' --1年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 6 THEN
        '08' --6-12个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 6 THEN
        '07' --6个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 3 THEN
        '06' --3-6个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 3 THEN
        '05' --3
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 1 THEN
        '04' --1-3个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 1 THEN
        '03' --1个月
       ELSE
        '02'
     END AS TERM_TYPE --存款期限类型
    ,
     'TR07' --定价基准类型
    ,
     CASE
       WHEN SUBSTR(A.INT_RATE_TYP, 1, 1) = 'F' THEN
        'RF01' --固定
       WHEN SUBSTR(A.INT_RATE_TYP, 1, 1) = 'L' THEN
        'RF02' --浮动
       ELSE
        ''
     END --利率类型
    ,
     NVL(A.INT_RATE, 0) AS REALRATE --实际利率
    ,

     NVL(A.Pboc_Base_Rate, 0) AS BASERATE --基准利率
    ,
     '99' --利率浮动频率
    ,
     '' --保底收益率
    ,
     '' --最高收益率
    ,
     CASE
       WHEN A.OPEN_CHANNEL IN ('01', '04') THEN
        '01'
       WHEN A.OPEN_CHANNEL IN ('02', '03', '05') THEN
        '02'
       WHEN A.OPEN_CHANNEL = '06' THEN
        '03'
       ELSE
        '99'
     END AS BUSICHANNEL --开户渠道
    ,
     'N' --异地存款标志
    ,

     CASE
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_BALANCE * B.CCY_RATE >= '3000000' THEN
        'A' --大额存款
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_BALANCE * B.CCY_RATE < '3000000' THEN
        'B' --小额存款
       ELSE
        ''
     END AS ACCT_BALANCE_FLAG,
     A.ACCT_TYPE --账户类型
    ,
     A.ST_INT_DT as ST_INT_DT2 --起息日期
    ,
     A.MATUR_DATE as MATUR_DATE2, --到期日期
     TO_CHAR(A.ACCT_CLDATE, 'YYYY-MM-DD'), --销户日期
     A.GL_ITEM_CODE, --科目号
     A.POC_INDEX_CODE -- 产品编码
      FROM SMTMODS.L_ACCT_DEPOSIT A --存款账户信息表
     INNER JOIN SMTMODS.L_PUBL_RATE B --汇率表
        ON A.CURR_CD = B.BASIC_CCY --账户币种
       AND B.CCY_DATE = TO_DATE(IS_DATE, 'yyyymmdd') --汇率日期
       AND A.DATA_DATE = B.DATA_DATE
       AND B.FORWARD_CCY = 'USD' --折算币种
     INNER JOIN SMTMODS.L_CUST_C C
        ON A.CUST_ID = C.CUST_ID
       AND A.DATA_DATE = C.DATA_DATE
       AND (C.IS_NGI_CUST ='1' AND NVL(C.CUST_TYP,'0') = '3' --个体工商户                    --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]若是NGI客户标识则以NIG客户类型判断
	       OR NVL(C.IS_NGI_CUST,'0')='0' AND NVL(C.DEPOSIT_CUSTTYPE,'0') IN ('13','14')      --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]非NGI客户通过存款人类型判断
           )
      LEFT JOIN DATACORE_IE_CK_GRCKJB_TMP3 D
        ON A.ACCT_NUM = D.COD_ACCT_NO
      LEFT JOIN SMTMODS.L_ACCT_OBS_LOAN E
        ON A.ACCT_NUM = E.SECURITY_ACCT_NUM
       AND A.DATA_DATE = E.DATA_DATE --modify by gmy 20220520 增加与表外表的关联
     WHERE (A.GL_ITEM_CODE LIKE '20110201%'
           OR A.GL_ITEM_CODE LIKE '20110209%' --单位活期保证金存款
		   OR A.GL_ITEM_CODE LIKE '20110202%' --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]新增个体工商户的单位一般定期存款
		   OR A.GL_ITEM_CODE LIKE '20110205%' --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]新增个体工商户的单位通知存款
           OR A.GL_ITEM_CODE LIKE '20110210%') --单位定期保证金存款   20240906  新增个体工商户的单位保证金存款
       AND A.ACCT_BALANCE = 0
       AND A.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
       AND A.DATA_DATE = IS_DATE;

  COMMIT;

  INSERT INTO DATACORE_IE_CK_GRCKJB
    SELECT /*+parallel(8)*/
     *
      FROM DATACORE_IE_CK_GRCKJB_TMP2 A
     WHERE EXISTS (SELECT 1
              FROM SMTMODS.L_TRAN_TX T --交易信息表
             WHERE T.CUST_ID = A.CUST_ID
               and t.PAYMENT_PROPERTY is null --交易过滤掉支付使用数据
               and t.PAYMENT_ORDER is null --交易过滤掉支付使用数据
               AND T.ACCOUNT_CODE = A.ACCT_NUM
               AND T.DATA_DATE = IS_DATE);

  COMMIT;

  ---存款大于0
  INSERT INTO DATACORE_IE_CK_GRCKJB
    SELECT /*+ USE_HASH(A,B,C,E) PARALLEL(8)*/
     TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD') --数据日期
    ,
     A.ACCT_NUM --存款账户编码
    ,
     A.DEPOSIT_NUM --存款序号
    ,
     A.ORG_NUM --内部机构号
    ,
     A.CUST_ID --客户号
    ,
     CASE
       WHEN A.ACCT_TYPE = '0401' THEN
        'D031' --一天通知
       WHEN A.ACCT_TYPE = '0402' THEN
        'D032' --七天通知
       WHEN E.ACCT_TYP = '111' THEN
        'D061' --银行承兑汇票保证金存款
       WHEN E.ACCT_TYP like '31%' THEN
        'D062' --信用证保证金存款
       WHEN E.ACCT_TYP IN ('121', '211') THEN
        'D063' --保函保证金存款
       WHEN (E.ACCT_TYP IN ('511', '521', '522', '523', '531') OR
            A.GL_ITEM_CODE in ('20110114', '20110115')) THEN
        'D069' --其他保证金存款                   --modify by gmy 20220520 增加保证金存款
       WHEN A.GL_ITEM_CODE IN ('20110101', '20110201') THEN
        'D013' --活期储蓄存款
       WHEN A.GL_ITEM_CODE = '20110103' THEN
        'D0141' --定期整存整取存款
       WHEN A.GL_ITEM_CODE IN
            ('20110104', '20110105', '20110108', '20110109') THEN
        'D0149' --其他定期储蓄存款
       WHEN A.GL_ITEM_CODE = '20110102' THEN
        'D02' --定活两便存款
       WHEN A.GL_ITEM_CODE = '20110111' THEN
        'D091' --信用卡存款(不存在准贷记卡存款，全部为贷记卡存款)
     END AS PROD_TYPE,
     TO_CHAR(A.ACCT_OPDATE, 'YYYY-MM-DD') --起始日期
    ,
     CASE
       WHEN A.ACCT_TYPE = '0401' AND A.MATUR_DATE IS NULL THEN
        '1999-01-01'
       WHEN A.ACCT_TYPE = '0402' AND A.MATUR_DATE IS NULL THEN
        '1999-01-07'
       ELSE
        TO_CHAR(A.MATUR_DATE, 'YYYY-MM-DD')
     END --到期日期
    ,
     TO_CHAR(A.ACCT_CLDATE, 'YYYY-MM-DD') --实际终止日期
    ,
     CASE

       WHEN (A.ACCT_TYPE = '0500'
        /*OR A.GL_ITEM_CODE IN ('20110114') OR (A.ACCT_TYPE NOT IN ('0401','0402') AND E.ACCT_TYP IN ('111','121','211','311','312','511','521','522','523','531'))*/) THEN
        '01' --活期    --20231211  wxb  活期账户类型0500    20240906 个人活期保证金存款'20110114',单位活期保证金存款'20110209'给活期
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 60 THEN
        '16' --5年以上
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 60 THEN
        '15' --5年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 36 THEN
        '14' --3年-5年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 36 THEN
        '13' --3年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 24 THEN
        '12' --2年-3年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 24 THEN
        '11' --2年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 12 THEN
        '10' --1年-2年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 12 THEN
        '09' --1年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 6 THEN
        '08' --6-12个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 6 THEN
        '07' --6个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 3 THEN
        '06' --3-6个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 3 THEN
        '05' --3
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 1 THEN
        '04' --1-3个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 1 THEN
        '03' --1个月
       ELSE
        '02'
     END AS TERM_TYPE --存款期限类型
    ,
     'TR07' --定价基准类型
    ,
     CASE
       WHEN SUBSTR(A.INT_RATE_TYP, 1, 1) = 'F' THEN
        'RF01' --固定
       WHEN SUBSTR(A.INT_RATE_TYP, 1, 1) = 'L' THEN
        'RF02' --浮动
       ELSE
        ''
     END --利率类型
    ,
     NVL(A.INT_RATE, 0) AS REALRATE --实际利率
    ,

     NVL(A.Pboc_Base_Rate, 0) AS BASERATE --基准利率
    ,
     '99' --利率浮动频率
    ,
     '' --保底收益率
    ,
     '' --最高收益率
    ,
     CASE
       WHEN A.OPEN_CHANNEL IN ('01', '04') THEN
        '01'
       WHEN A.OPEN_CHANNEL IN ('02', '03', '05') THEN
        '02'
       WHEN A.OPEN_CHANNEL = '06' THEN
        '03'
       ELSE
        '99'
     END AS BUSICHANNEL --开户渠道
    ,
     'N' --异地存款标志
    ,

     CASE
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_BALANCE * B.CCY_RATE >= '3000000' THEN
        'A' --大额存款
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_BALANCE * B.CCY_RATE < '3000000' THEN
        'B' --小额存款
       ELSE
        ''
     END AS ACCT_BALANCE_FLAG,
     A.ACCT_TYPE --账户类型
    ,
     A.ST_INT_DT as ST_INT_DT2 --起息日期
    ,
     A.MATUR_DATE AS MATUR_DATE2, --到期日期
     TO_CHAR(A.ACCT_CLDATE, 'YYYY-MM-DD'), --销户日期
     A.GL_ITEM_CODE,
     A.POC_INDEX_CODE -- 产品编码
      FROM SMTMODS.L_ACCT_DEPOSIT A --存款账户信息表
     INNER JOIN SMTMODS.L_PUBL_RATE B --汇率表
        ON A.CURR_CD = B.BASIC_CCY --账户币种
       AND B.CCY_DATE = TO_DATE(IS_DATE, 'yyyymmdd') --汇率日期
       AND A.DATA_DATE = B.DATA_DATE
       AND B.FORWARD_CCY = 'USD' --折算币种
      LEFT JOIN SMTMODS.L_CUST_P C
        ON A.CUST_ID = C.CUST_ID
       AND A.DATA_DATE = C.DATA_DATE
      LEFT JOIN SMTMODS.L_ACCT_OBS_LOAN E
        ON A.ACCT_NUM = E.SECURITY_ACCT_NUM
       AND A.DATA_DATE = E.DATA_DATE --modify by gmy 20220520 增加与表外表进行关联
     WHERE (A.GL_ITEM_CODE = '20110101' --个人活期存款
           OR A.GL_ITEM_CODE LIKE '20110111%' --个人信用卡存款
           OR A.GL_ITEM_CODE = '20110103' --个人整存整取定期储蓄存款
           OR A.GL_ITEM_CODE = '20110104' --个人零存整取定期储蓄存款
           OR A.GL_ITEM_CODE = '20110105' --个人存本取息定期储蓄存款
           OR A.GL_ITEM_CODE = '20110108' --个人教育储蓄存款
           OR A.GL_ITEM_CODE = '20110109' --个人其他定期储蓄存款
           OR A.GL_ITEM_CODE = '20110102' --个人定活两便存款
           OR A.GL_ITEM_CODE = '20110114' --个人活期保证金存款
           OR A.GL_ITEM_CODE = '20110115' --个人定期保证金存款
           OR A.GL_ITEM_CODE LIKE '20110110%' --个人通知存款
           OR
           (A.GL_ITEM_CODE LIKE '20110201%' AND C.OPERATE_CUST_TYPE = 'A')) --单位活期存款
       AND A.ACCT_BALANCE > 0
       AND A.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
       AND A.DATA_DATE = IS_DATE;

  COMMIT;

  --存款大于0，个体工商户
  INSERT INTO DATACORE_IE_CK_GRCKJB
    SELECT /*+ USE_HASH(A,B,C,E) PARALLEL(8)*/
     TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD') --数据日期
    ,
     A.ACCT_NUM --存款账户编码
    ,
     A.DEPOSIT_NUM --存款序号
    ,
     A.ORG_NUM --内部机构号
    ,
     A.CUST_ID --客户号
    ,
     CASE
       WHEN A.ACCT_TYPE = '0401' THEN
        'D031' --一天通知
       WHEN A.ACCT_TYPE = '0402' THEN
        'D032' --七天通知
       WHEN E.ACCT_TYP = '111' THEN
        'D061' --银行承兑汇票保证金存款
       WHEN E.ACCT_TYP like '31%' THEN
        'D062' --信用证保证金存款
       WHEN E.ACCT_TYP IN ('121', '211') THEN
        'D063' --保函保证金存款
       WHEN (E.ACCT_TYP IN ('511', '521', '522', '523', '531') OR
            A.GL_ITEM_CODE in ('20110114', '20110115','20110209', '20110210')) THEN
        'D069' --其他保证金存款                   --modify by gmy 20220520 增加保证金存款   20240906 新增个体工商户的单位保证金存款
       WHEN A.GL_ITEM_CODE IN ('20110101', '20110201') THEN
        'D013' --活期储蓄存款
       WHEN A.GL_ITEM_CODE = '20110103' THEN
        'D0141' --定期整存整取存款
       WHEN A.GL_ITEM_CODE IN
            ('20110104', '20110105', '20110108', '20110109') THEN
        'D0149' --其他定期储蓄存款
       WHEN A.GL_ITEM_CODE = '20110102' THEN
        'D02' --定活两便存款
       WHEN A.GL_ITEM_CODE = '20110111' THEN
        'D091' --信用卡存款(不存在准贷记卡存款，全部为贷记卡存款)
	   WHEN A.GL_ITEM_CODE = '20110202' THEN  'D0141' --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]新增个体工商户的单位一般定期存款
     END AS PROD_TYPE,
     TO_CHAR(A.ACCT_OPDATE, 'YYYY-MM-DD') --起始日期
    ,
     CASE
       WHEN A.ACCT_TYPE = '0401' AND A.MATUR_DATE IS NULL THEN
        '1999-01-01'
       WHEN A.ACCT_TYPE = '0402' AND A.MATUR_DATE IS NULL THEN
        '1999-01-07'
       ELSE
        TO_CHAR(A.MATUR_DATE, 'YYYY-MM-DD')
     END --到期日期
    ,
     TO_CHAR(A.ACCT_CLDATE, 'YYYY-MM-DD') --实际终止日期
    ,
     CASE
       WHEN (A.ACCT_TYPE = '0500'
        /*OR A.GL_ITEM_CODE IN ('20110209') OR (A.ACCT_TYPE NOT IN ('0401','0402') AND E.ACCT_TYP IN ('111','121','211','311','312','511','521','522','523','531'))*/) THEN
        '01' --活期    --20231211  wxb  活期账户类型0500     20240906 个人活期保证金存款'20110114',单位活期保证金存款'20110209'给活期
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 60 THEN
        '16' --5年以上
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 60 THEN
        '15' --5年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 36 THEN
        '14' --3年-5年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 36 THEN
        '13' --3年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 24 THEN
        '12' --2年-3年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 24 THEN
        '11' --2年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 12 THEN
        '10' --1年-2年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 12 THEN
        '09' --1年
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 6 THEN
        '08' --6-12个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 6 THEN
        '07' --6个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 3 THEN
        '06' --3-6个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 3 THEN
        '05' --3
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) > 1 THEN
        '04' --1-3个月
       WHEN MONTHS_BETWEEN(A.MATUR_DATE, A.ST_INT_DT) = 1 THEN
        '03' --1个月
       ELSE
        '02'
     END AS TERM_TYPE --存款期限类型
    ,
     'TR07' --定价基准类型
    ,
     CASE
       WHEN SUBSTR(A.INT_RATE_TYP, 1, 1) = 'F' THEN
        'RF01' --固定
       WHEN SUBSTR(A.INT_RATE_TYP, 1, 1) = 'L' THEN
        'RF02' --浮动
       ELSE
        ''
     END --利率类型
    ,
     NVL(A.INT_RATE, 0) AS REALRATE --实际利率
    ,

     NVL(A.Pboc_Base_Rate, 0) AS BASERATE --基准利率
    ,
     '99' --利率浮动频率
    ,
     '' --保底收益率
    ,
     '' --最高收益率
    ,
     CASE
       WHEN A.OPEN_CHANNEL IN ('01', '04') THEN
        '01'
       WHEN A.OPEN_CHANNEL IN ('02', '03', '05') THEN
        '02'
       WHEN A.OPEN_CHANNEL = '06' THEN
        '03'
       ELSE
        '99'
     END AS BUSICHANNEL --开户渠道
    ,
     'N' --异地存款标志
    ,

     CASE
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_BALANCE * B.CCY_RATE >= '3000000' THEN
        'A' --大额存款
       WHEN A.CURR_CD <> 'CNY' --币种为外币
            AND A.ACCT_BALANCE * B.CCY_RATE < '3000000' THEN
        'B' --小额存款
       ELSE
        ''
     END AS ACCT_BALANCE_FLAG,
     A.ACCT_TYPE --账户类型
    ,
     A.ST_INT_DT as ST_INT_DT2 --起息日期
    ,
     A.MATUR_DATE AS MATUR_DATE2, --到期日期
     TO_CHAR(A.ACCT_CLDATE, 'YYYY-MM-DD'), --销户日期
     A.GL_ITEM_CODE,
     A.POC_INDEX_CODE --产品编码
      FROM SMTMODS.L_ACCT_DEPOSIT A --存款账户信息表
     INNER JOIN SMTMODS.L_PUBL_RATE B --汇率表
        ON A.CURR_CD = B.BASIC_CCY --账户币种
       AND B.CCY_DATE = TO_DATE(IS_DATE, 'yyyymmdd') --汇率日期
       AND A.DATA_DATE = B.DATA_DATE
       AND B.FORWARD_CCY = 'USD' --折算币种
     INNER JOIN SMTMODS.L_CUST_C C
        ON A.CUST_ID = C.CUST_ID
       AND A.DATA_DATE = C.DATA_DATE
       AND (C.IS_NGI_CUST ='1' AND NVL(C.CUST_TYP,'0') = '3' --个体工商户                    --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]若是NGI客户标识则以NIG客户类型判断
	        OR NVL(C.IS_NGI_CUST,'0')='0' AND NVL(C.DEPOSIT_CUSTTYPE,'0') IN ('13','14')     --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]非NGI客户通过存款人类型判断
           )
      LEFT JOIN SMTMODS.L_ACCT_OBS_LOAN E
        ON A.ACCT_NUM = E.SECURITY_ACCT_NUM
       AND A.DATA_DATE = E.DATA_DATE --modify by gmy 20220520 增加与表外表的关联
     WHERE (A.GL_ITEM_CODE LIKE '20110201%'
           OR A.GL_ITEM_CODE LIKE '20110209%' --单位活期保证金存款
		   OR A.GL_ITEM_CODE LIKE '20110202%' --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]新增个体工商户的单位一般定期存款
		   OR A.GL_ITEM_CODE LIKE '20110205%' --[2025-12-17] [蒿蕊][数据维护单][黄俊铭]新增个体工商户的单位通知存款
           OR A.GL_ITEM_CODE LIKE '20110210%') --单位定期保证金存款   20240906 新增个体工商户的单位保证金存款
       AND A.ACCT_BALANCE > 0
       AND A.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
       AND A.DATA_DATE = IS_DATE;

  COMMIT;

  --清除目标表中分区数据
  SP_IRS_PARTITIONS(IS_DATE, 'IE_CK_GRCKJC', OI_RETCODE);

  --向目标表插入数据
  INSERT INTO IE_CK_GRCKJC
    (DATADATE --数据日期
    ,
     ACCDEPCODE --存款账户编码
    ,
     DEPAGRSEQNO --存款序号
    ,
     CORPID --内部机构号
    ,
     CUSTID --客户号
    ,
     DEPPRODUCTTYPE --存款产品类别
    ,
     CONBGNDATE --起始日期
    ,
     CONDUEDATE --到期日期
    ,
     ACTUALDUEDATE --实际终止日期
    ,
     DEPTERMTYPE --存款期限类型
    ,
     PRICINGTYPE --定价基准类型
    ,
     RATETYPE --利率类型
    ,
     REALRATE --实际利率
    ,
     BASERATE --基准利率
    ,
     FLOATFREQ --利率浮动频率
    ,
     LOWESTYIELDRATE --保底收益率
    ,
     HIGHESTYIELDRATE --最高收益率
    ,
     BUSICHANNEL --开户渠道
    ,
     REMOTEDEPFLG --异地存款标志
    ,
     AMTDEPFLG --大小额标志
    ,
     CJRQ --采集日期
    ,
     NBJGH --内部机构号
    ,
     BIZ_LINE_ID --业务条线
    ,
     IRS_CORP_ID --法人机构ID
     )
    SELECT /*+ USE_HASH(A,B,C,E) PARALLEL(8)*/
     A.DATA_DATE, --数据日期
     A.ACCT_NUM, --存款账户编码
     A.DEPOSIT_NUM, --存款序号
     A.ORG_NUM, --内部机构号
     A.CUST_ID, --客户号
     /* CASE
      WHEN A.PROD_TYPE IN ('D012', 'D0141', 'D0149', 'D031', 'D032') AND
             ( (A.END_DATE IS NOT NULL AND A.DATA_DATE >= A.END_DATE) OR (A.END_DATE IS NULL AND A.DATA_DATE > A.MATUR_DATE) )
             AND
             ( (A.END_DATE IS NOT NULL AND A.DATA_DATE >= A.END_DATE) OR (A.END_DATE IS NULL AND A.DATA_DATE > A.MATUR_DATE) )
             AND
             (CASE WHEN A.DATA_DATE = A.MATUR_DATE THEN  F.INT_RATE
                   ELSE A.INT_RATE END) <= 0.55
             AND
              (CASE WHEN A.DATA_DATE = A.MATUR_DATE  THEN F.PBOC_BASE_RATE --ADF BY 20230824 黄俊铭口径，当天到期的存款，人行基准利率取昨天
                   WHEN A.GL_ITEM_CODE IN ('20110110','20110205') AND A.ACCT_CLDATE = A.DATA_DATE THEN  F.PBOC_BASE_RATE --ADF BY 20230829 黄俊铭口径，通知存款当天销户，取昨天的人行基准利率
                   ELSE A.BASE_RATE END) <= 0.55 THEN
           'D013'
      ELSE
     A.PROD_TYPE END, --存款产品类别 20240221增加判断*/
     CASE
       WHEN T.CURR_CD = 'CNY' AND A.PROD_TYPE IN ('D012', 'D0141', 'D0149', 'D031', 'D032') AND
            ((A.END_DATE IS NOT NULL AND A.DATA_DATE >= A.END_DATE) OR
            (A.END_DATE IS NULL AND A.DATA_DATE > A.MATUR_DATE)) AND
            ((A.END_DATE IS NOT NULL AND A.DATA_DATE >= A.END_DATE) OR
            (A.END_DATE IS NULL AND A.DATA_DATE > A.MATUR_DATE)) AND
            (CASE
              WHEN A.DATA_DATE = A.MATUR_DATE THEN
               F.INT_RATE
              ELSE
               A.INT_RATE
            END) <= 0.55 AND (CASE
              WHEN A.DATA_DATE = A.MATUR_DATE THEN
               F.PBOC_BASE_RATE --ADF BY 20230824 黄俊铭口径，当天到期的存款，人行基准利率取昨天
              WHEN A.GL_ITEM_CODE IN ('20110110', '20110205') AND
                   A.ACCT_CLDATE = A.DATA_DATE THEN
               F.PBOC_BASE_RATE --ADF BY 20230829 黄俊铭口径，通知存款当天销户，取昨天的人行基准利率
              ELSE
               A.BASE_RATE
            END) <= 0.55 THEN
        'D013'
       WHEN A.POC_INDEX_CODE = '01010055' AND A.BASE_RATE IN (0.35) ---add   by   20240715  zy  修改收益型个人智能通知存款的产品类别
        THEN
        'D013'
       ELSE
        A.PROD_TYPE
     END, --存款产品类别 20240221增加判断  MATUR_DATE 到期日   END_DATE 实际终止日期

     A.ST_INT_DT, --起始日期
     CASE
       WHEN A.MATUR_DATE = '1900-12-31' THEN
        ''
       ELSE
        A.MATUR_DATE
     END, --到期日期               --20230106     存在到期日为19001231数据不满足校验规则，给空值
     A.END_DATE, --实际终止日期
     CASE
       WHEN A.ACCT_TYPE = '0500' THEN
        '01'
       WHEN T.GL_ITEM_CODE IN('20110209','20110114') and A.PROD_TYPE in ('D061','D062','D063','D069') THEN
         '01'                 --20240906 个人活期保证金存款'20110114',单位活期保证金存款'20110209'给活期
       WHEN T.CURR_CD = 'CNY' AND A.PROD_TYPE IN ('D012', 'D0141', 'D0149', 'D031', 'D032') AND
            ((A.END_DATE IS NOT NULL AND A.DATA_DATE >= A.END_DATE) OR
            (A.END_DATE IS NULL AND A.DATA_DATE > A.MATUR_DATE)) AND
            (CASE
              WHEN A.DATA_DATE = A.MATUR_DATE THEN
               F.INT_RATE
              ELSE
               A.INT_RATE
            END) < = 0.55 AND (CASE
              WHEN A.DATA_DATE = A.MATUR_DATE THEN
               F.PBOC_BASE_RATE --ADF BY 20230824 黄俊铭口径，当天到期的存款，人行基准利率取昨天
              WHEN A.GL_ITEM_CODE IN ('20110110', '20110205') AND
                   A.ACCT_CLDATE = A.DATA_DATE THEN
               F.PBOC_BASE_RATE --ADF BY 20230829 黄俊铭口径，通知存款当天销户，取昨天的人行基准利率
              ELSE
               A.BASE_RATE
            END) < = 0.55 -- 同步20240221存款产品类别判断
        THEN
        '01'
       WHEN A.POC_INDEX_CODE = '01010055' AND A.BASE_RATE IN (0.35) ---add   by   20240715  zy  修改收益型个人智能通知存款的产品类别
        THEN
        '01' --活期    --20231211  wxb  活期账户类型0500
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) > 60 THEN
        '16' --5年以上
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) = 60 THEN
        '15' --5年
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) > 36 THEN
        '14' --3年-5年
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) = 36 THEN
        '13' --3年
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) > 24 THEN
        '12' --2年-3年
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) = 24 THEN
        '11' --2年
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) > 12 THEN
        '10' --1年-2年
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) = 12 THEN
        '09' --1年
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) > 6 THEN
        '08' --6-12个月
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) = 6 THEN
        '07' --6个月
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) > 3 THEN
        '06' --3-6个月
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) = 3 THEN
        '05' --3
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) > 1 THEN
        '04' --1-3个月
       WHEN ROUND(MONTHS_BETWEEN(TO_DATE(A.MATUR_DATE, 'YYYY-MM-DD'),
                                 A.ST_INT_DT2)) = 1 THEN
        '03' --1个月
       ELSE
        '02'
     END AS DEPTERMTYPE, --存款期限类型  定期存款对应的存款期限类型增加四舍五入后匹配相应的存款期限 20240220
     A.DJJZ_TYPE, --定价基准类型
     A.INT_RATE_TYP, --利率类型
     CASE
       WHEN A.DATA_DATE = A.MATUR_DATE THEN
        F.INT_RATE
       ELSE
        A.INT_RATE
     END AS INT_RATE, --实际利率
     CASE

       WHEN A.DATA_DATE = A.MATUR_DATE THEN
        F.PBOC_BASE_RATE --ADF BY 20230824 黄俊铭口径，当天到期的存款，人行基准利率取昨天

       WHEN A.GL_ITEM_CODE IN ('20110110', '20110205') AND
            A.ACCT_CLDATE = A.DATA_DATE THEN
        F.PBOC_BASE_RATE --ADF BY 20230829 黄俊铭口径，通知存款当天销户，取昨天的人行基准利率
       ELSE
        A.BASE_RATE
     END AS BASE_RATE, --基准利率
     CASE
       WHEN A.INT_RATE_TYP = 'RF01' THEN
        '' -- 存款利率类型为RF01-固定利率时，利率浮动频率字段应为空值 20240220
       ELSE
        A.LLFD_RATE
     END, --利率浮动频率
     A.GUARANTEED_RETURN_RATE, --保底收益率
     A.MAX_YILED_RATE, --最高收益率
     A.OPEN_CHANNEL, --开户渠道
     A.REMOTE_DEPOSIT_FLAG, --异地存款标志
     A.ACCT_BALANCE_FLAG, --大小额标志
     IS_DATE, --采集日期
     A.ORG_NUM, --内部机构号
     '99', --业务条线
     CASE
       WHEN A.ORG_NUM LIKE '51%' THEN
        '510000'
       WHEN A.ORG_NUM LIKE '52%' THEN
        '520000'
       WHEN A.ORG_NUM LIKE '53%' THEN
        '530000'
       WHEN A.ORG_NUM LIKE '54%' THEN
        '540000'
       WHEN A.ORG_NUM LIKE '55%' THEN
        '550000'
       WHEN A.ORG_NUM LIKE '56%' THEN
        '560000'
       WHEN A.ORG_NUM LIKE '57%' THEN
        '570000'
       WHEN A.ORG_NUM LIKE '58%' THEN
        '580000'
       WHEN A.ORG_NUM LIKE '59%' THEN
        '590000'
       WHEN A.ORG_NUM LIKE '60%' THEN
        '600000'
       ELSE
        '990000'
     END --法人机构ID
      FROM DATACORE_IE_CK_GRCKJB A

      LEFT JOIN ACCT_RATE B
        ON A.ACCT_NUM = B.COD_ACCT_NO
      LEFT JOIN DATACORE_IE_CK_GRCKJB_TMP3 D
        ON A.ACCT_NUM = D.COD_ACCT_NO
      LEFT JOIN SMTMODS.L_ACCT_DEPOSIT F ---定期当天到期取定期利率，实际到期是到期日字段的前一天，到期日字段是系统到期日。
        ON A.ACCT_NUM = F.ACCT_NUM
       AND F.DATA_DATE = VS_YES_DATE
      LEFT JOIN SMTMODS.L_ACCT_DEPOSIT T ---判断存款科目为20110209单位活期保证金存款(个体工商户)、20110114的明细，将存款期限类型给到-01活期
        ON A.ACCT_NUM = T.ACCT_NUM
       AND A.DEPOSIT_NUM = T.DEPOSIT_NUM
       AND T.DATA_DATE = IS_DATE

     WHERE A.ACCT_NUM NOT IN ('9020790501000013_1', '9019800217000015_1'); ---ADD BY 20230818 特殊处理，内部户有奖储蓄和信用卡，基准利率为0.刨除
  commit;
  ---特殊处理，待上游处理完毕，删除
  UPDATE IE_CK_GRCKJC T
     SET BASERATE = '0.35000'
   WHERE T.ACCDEPCODE IN ('150031533800051_2',
                          '150031533800135_2',
                          '207242236100011_2',
                          '102378505600046_2',
                          '205973431200022_2',
                          '202458342300015_1',
                          '201746025700019_2',
                          '200207463100031_1',
                          '891310471300014_2',
                          '891608396600015_3',
                          '200893483700023_2',
                          '200746760700033_2')
     AND REALRATE = '0.25000'
     AND CJRQ = IS_DATE;
  COMMIT;

  ----------------------------------------------------------------------------------------------------------------
  OI_RETCODE := 0; --设置异常状态为0 成功状态
  --返回中文描述
  OI_RETCODE2 := '成功!';
  -- 结束日志
  VS_STEP := 'END';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);

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
    SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);
END;
/

