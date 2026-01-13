CREATE OR REPLACE PROCEDURE BSP_SP_IRS_DK_GRDKFK(IS_DATE     IN VARCHAR2,
                                                 OI_RETCODE  OUT INTEGER,
                                                 OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_DK_GRDKFK
  -- 用途:生成接口表 JS_201_CLGRDK 存量个人贷款信息
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT 20200819
  --    MOD BY YANLINGBO AT 20200819
  --需求编号：无需求           上线日期：2025-09-29，修改人：蒿蕊，提出人：黄俊铭  修改原因：调整基准利率规则
  --需求编号：JLBA202507300010 上线日期：2025-09-29，修改人：蒿蕊，提出人：从需求  修改原因：添加普惠贷（个人经营贷款）取T+2放款逻辑
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT      VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  --VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
  --VS_FIRST          VARCHAR2(10) DEFAULT NULL; --字符型  过程描述

BEGIN
  VS_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  --VS_LAST_TEXT := TO_CHAR(LAST_DAY(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1)),'YYYYMMDD'); --上月月末
  --VS_FIRST := substr(to_char(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1),'yyyymmdd'),1,6)||'01';--上月月初

  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_DK_GRDKFK';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------

  /*  --冲账交易信息
  EXECUTE IMMEDIATE 'TRUNCATE TABLE IRS_GR_GRDKFKXXB_TMP2';
  INSERT INTO IRS_GR_GRDKFKXXB_TMP2
    SELECT DISTINCT FX.REF_TXN_NO_ORG
      FROM FCR_XFACE_ADDL_DETAILS_TXNLOG@ODS FX
     WHERE FX.ODS_DATA_DATE = IS_DATE
       AND FX.TYP_ACCT_NO = 'LN'
       AND FX.REF_TXN_NO_ORG IS NOT NULL;
  COMMIT;*/

  --优化临时表
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IRS_GR_GRDKFKXXB_TMP3';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IRS_GR_GRDKFK_TEMP';

  insert into DATACORE_IRS_GR_GRDKFK_TEMP
    select /*+ PARALLEL(8)*/
     T.LOAN_NUM --贷款借据编号
    ,
     T.CUST_ID --客户号
    ,
     T.ORG_NUM --内部机构号
    ,
     T.DRAWDOWN_DT --交易日期
    ,
     T.CURR_CD --币种
    ,
     T.DRAWDOWN_AMT --放款金额
    ,
     T.INT_RATE_TYP,
	 CASE WHEN T.BASE_INT_RAT >= T.REAL_INT_RAT OR T.BASE_INT_RAT=0 OR T.BASE_INT_RAT IS NULL THEN A.BASE_INT_RAT
        ELSE T.BASE_INT_RAT
     END , --基准利率 --[2025-09-29] [蒿蕊] [无需求] [黄俊铭]由取合同表利率改为当借据表基准利率大于等于实际利率或借据表基准利率为0或空时取合同表利率，否则取借据表.基准利率
     T.REAL_INT_RAT --实际利率
      FROM SMTMODS.L_ACCT_LOAN T
      LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT A
        ON T.ACCT_NUM = A.CONTRACT_NUM
       AND A.DATA_DATE = IS_DATE
     WHERE T.DATA_DATE = IS_DATE
       AND (T.LOAN_ACCT_BAL > 0 OR
           (T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = IS_DATE) --  MD BY GMY 20230420 存在当天放款当天结清的数据，贷款余额为0，用放款金额与放款日期判断是否当天放款
          OR (T.INTERNET_LOAN_FLG = 'Y' AND T.LOAN_ACCT_BAL > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')) ----modify by 87v : 互联网贷款数据晚一天下发，昨天数据今天取
          OR (T.INTERNET_LOAN_FLG = 'Y' AND T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')) ----modify by 87v : 互联网贷款数据晚一天下发，昨天数据今天取
		  OR T.CP_ID = 'DK001000100041' AND (T.LOAN_ACCT_BAL > 0 OR T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0) AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')  --[2025-09-29] [蒿蕊][JLBA202507300010][从需求]普惠贷取T+2放款数据
          )
       AND T.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
       AND (SUBSTR(T.ITEM_CD, 1, 4) IN ('1303', '1305') or
           T.ACCT_TYP LIKE '09%') --122贷款科目。包含个体工商户对公贷款，个体工商户贸易融资贷款
          -- 20210913 L_ACCT_LOAN增加产品代码字段，不需要关联产品代码表
       AND T.cancel_flg = 'N'
     AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
    --AND T.COD_PROD NOT IN ('99999001', '99999002')
    ;
  commit;

  INSERT /*+ APPEND*/
  INTO DATACORE_IRS_GR_GRDKFKXXB_TMP3 NOLOGGIING
    SELECT /* +parallel(8)*/
     *
      FROM DATACORE_IRS_GR_GRDKFK_TEMP T
     WHERE EXISTS (SELECT 1
              FROM L_CUST_P_TMP F
             WHERE T.CUST_ID = F.CUST_ID
            --AND ORG_NUM NOT LIKE '0215%'
            );

  COMMIT;

  INSERT /*+ APPEND*/
  INTO DATACORE_IRS_GR_GRDKFKXXB_TMP3 NOLOGGIING
    SELECT *
      FROM (SELECT /* +PARALLEL(8)*/
             *
              FROM DATACORE_IRS_GR_GRDKFK_TEMP T
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
                                 '8500081236',
                                 '8915832313',
                                 '8915242461',
                                 '8912668640',
                                 '8911953837',
                                 '8915587103',
                                 '8915998116',
                                 '8916156576')) A
     WHERE NOT EXISTS (SELECT 1
              FROM DATACORE_IRS_GR_GRDKFKXXB_TMP3 B
             WHERE A.CUST_ID = B.CUST_ID);

  COMMIT;

  insert into DATACORE_IRS_GR_GRDKFKXXB_TMP3
    select /*+ PARALLEL(8)*/
     T.LOAN_NUM --贷款借据编号
    ,
     T.CUST_ID --客户号
    ,
     T.ORG_NUM --内部机构号
    ,
     T.DRAWDOWN_DT --交易日期
    ,
     T.CURR_CD --币种
    ,
     T.DRAWDOWN_AMT --放款金额
    ,
     T.INT_RATE_TYP,
     A.BASE_INT_RAT,
     T.REAL_INT_RAT --实际利率
      FROM SMTMODS.L_ACCT_LOAN T
      LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT A
        ON T.ACCT_NUM = A.CONTRACT_NUM
       AND A.DATA_DATE = IS_DATE
     WHERE T.DATA_DATE = IS_DATE
       AND (T.LOAN_ACCT_BAL > 0 OR
           (T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = IS_DATE)
           OR (T.INTERNET_LOAN_FLG = 'Y' AND T.LOAN_ACCT_BAL > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')) ----modify by 87v : 互联网贷款数据晚一天下发，昨天数据今天取
         OR (T.INTERNET_LOAN_FLG = 'Y' AND T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0 AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')) ----modify by 87v : 互联网贷款数据晚一天下发，昨天数据今天取
		   OR T.CP_ID = 'DK001000100041' AND (T.LOAN_ACCT_BAL > 0 OR T.LOAN_ACCT_BAL = '0' AND T.DRAWDOWN_AMT > 0) AND
           TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')  --[2025-09-29] [蒿蕊][JLBA202507300010][从需求]普惠贷取T+2放款数据
          )
          --  MD BY GMY 20230420 存在当天放款当天结清的数据，贷款余额为0，用放款金额与放款日期判断是否当天放款
       AND T.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
       AND (SUBSTR(T.ITEM_CD, 1, 4) IN ('1303', '1305') or
           T.ACCT_TYP LIKE '09%') --122贷款科目。包含个体工商户对公贷款，个体工商户贸易融资贷款
          -- 20210913 L_ACCT_LOAN增加产品代码字段，不需要关联产品代码表
       AND T.cancel_flg = 'N'
     AND T.LOAN_STOCKEN_DATE IS NULL    --add by haorui 20250311 JLBA202408200012 资产未转让
          --AND T.COD_PROD NOT IN ('99999001', '99999002')
       AND (exists (select 1
                      from SMTMODS.L_CUST_C f
                     where t.cust_id = f.CUST_ID
                       AND F.DATA_DATE = IS_DATE
                          --and ORG_NUM not like '0215%'
                       and F.CUST_TYP = '3'))
    --AND TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = IS_DATE --取当日放款数据
    ;
  commit;

  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_DK_GRDKFK';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IRS_GR_GRDKFKXXB_TMP1';

  INSERT INTO DATACORE_IRS_GR_GRDKFKXXB_TMP1
    (DATA_DATE --数据日期
    ,
     LOAN_NUM --贷款借据编号
    ,
     CUST_ID --客户号
    ,
     ORG_NUM --内部机构号
    ,
     REF_TXN_NO --交易流水号
    ,
     DRAWDOWN_DT --交易日期
    ,
     CURR_CD --币种
    ,
     HAPPENED_BAL --发生金额
    ,
     BASE_INT_RAT --基准利率
    ,
     REAL_INT_RAT --实际利率
     )
    SELECT /*+ PARALLEL(8)*/
     VS_TEXT --数据日期
    ,
     T.LOAN_NUM --贷款借据编号
    ,
     T.CUST_ID --客户号
    ,
     T.ORG_NUM --内部机构号
    ,
     T.LOAN_NUM || 01 --交易流水号
    ,
     TO_CHAR(T.DRAWDOWN_DT, 'YYYY-MM-DD') --交易日期
    ,
     T.CURR_CD --币种
    ,
     T.DRAWDOWN_AMT --放款金额
    ,
     /*CASE
       WHEN SUBSTR(T.INT_RATE_TYP, 1, 1) = 'F' THEN
        0 --固定利率
       ELSE
        T.BASE_INT_RAT
     END --基准利率*/
     T.BASE_INT_RAT --基准利率
    ,
     T.REAL_INT_RAT --实际利率
      FROM DATACORE_IRS_GR_GRDKFKXXB_TMP3 T
    LEFT JOIN SMTMODS.L_ACCT_LOAN T1
     ON T.LOAN_NUM = T1.LOAN_NUM
    AND T1.DATA_DATE = IS_DATE
     WHERE T.DRAWDOWN_DT = TO_DATE(IS_DATE, 'YYYYMMDD') --放款日期
     OR (T1.INTERNET_LOAN_FLG = 'Y' AND
         TO_CHAR(T.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')) ----modify by 87v : 互联网贷款数据晚一天下发，昨天数据今天取)
	 OR T1.CP_ID = 'DK001000100041' AND 
           TO_CHAR(T1.DRAWDOWN_DT, 'YYYYMMDD') = TO_CHAR((TRUNC(TO_DATE(IS_DATE, 'YYYYMMDD'), 'DD') - 1), 'YYYYMMDD')  --[2025-09-29] [蒿蕊][JLBA202507300010][从需求]普惠贷取T+2放款数据
    --AND TRIM(T1.TRAN_CODE) = 'LOAN000801'

    ;
  COMMIT;
  insert into DATACORE_IE_DK_GRDKFK
    select /*+ PARALLEL(8)*/
    distinct *
      from DATACORE_IRS_GR_GRDKFKXXB_TMP1;
  commit;
  /*--流水号为空的
  INSERT INTO IE_DK_GRDKFK
    (DATA_DATE --数据日期
    ,
     LOAN_NUM --贷款借据编号
    ,
     CUST_ID --客户号
    ,
     ORG_NUM --内部机构号
    ,
     REF_TXN_NO --交易流水号
    ,
     DRAWDOWN_DT --交易日期
    ,
     CURR_CD --币种
    ,
     HAPPENED_BAL --发生金额
    ,
     BASE_INT_RAT --基准利率
    ,
     REAL_INT_RAT --实际利率
     )
    SELECT \*+ PARALLEL(8)*\
     VS_TEXT --数据日期
    ,
     LOAN_NUM --贷款借据编号
    ,
     CUST_ID --客户号
    ,
     ORG_NUM --内部机构号
    ,
     NVL(A.REF_TXN_NO, FS.FKRQ || FS.JJBH) --交易流水号
    ,
     TO_CHAR(DRAWDOWN_DT, 'YYYY-MM-DD') --交易日期
    ,
     CURR_CD --币种
    ,
     SUM(DRAWDOWN_AMT) --放款金额
    ,
     CASE
       WHEN SUBSTR(T.INT_RATE_TYP, 1, 1) = 'F' THEN
        0 --固定利率
       ELSE
        T.BASE_INT_RAT
     END --基准利率
    ,
     REAL_INT_RAT --实际利率
      FROM DATACORE_IRS_GR_GRDKFKXXB_TMP3 T
     INNER JOIN L_PBOCD_DKFS@SUPER FS
        ON T.LOAN_NUM = FS.JJBH --贷款借据编号
       AND FS.DATA_DATE = IS_DATE
       AND FS.SERIAL_NO IS NULL
       AND FS.FLAG NOT IN ('2', '3', '0', '4') --只取放款
      LEFT JOIN (SELECT AGREE.COD_APP_ID, TXLOG.REF_TXN_NO
                   FROM FCR_AC_AGREEMENT_DTLS@ODS AGREE
                  INNER JOIN FCR_XFACE_ADDL_DETAILS_TXNLOG@ODS TXLOG
                     ON AGREE.COD_ACCT_NO = TXLOG.COD_ACCT_NO --贷款借据编号
                    AND TXLOG.TYP_ACCT_NO = 'LN'
                    AND TXLOG.FLG_DR_CR = 'D'
                    AND TXLOG.ODS_DATA_DATE = IS_DATE
                    AND TXLOG.REF_TXN_NO_ORG IS NULL --交易机构
                    AND TXLOG.REF_TXN_NO NOT IN
                        (SELECT REF_TXN_NO_ORG FROM IRS_GR_GRDKFKXXB_TMP2) --剔除冲账交易
                  WHERE AGREE.ODS_DATA_DATE = IS_DATE) A
        ON T.LOAN_NUM = A.COD_APP_ID
     WHERE NOT EXISTS (SELECT 1
              FROM DATACORE_IE_DK_GRDKFK JS2
             WHERE A.REF_TXN_NO = JS2.REF_TXN_NO)
     GROUP BY LOAN_NUM --贷款借据编号
             ,
              CUST_ID --客户号
             ,
              ORG_NUM --内部机构号
             ,
              NVL(A.REF_TXN_NO, FS.FKRQ || FS.JJBH) --交易流水号
             ,
              TO_CHAR(DRAWDOWN_DT, 'YYYY-MM-DD') --交易日期
             ,
              CURR_CD --币种
             ,
              CASE
                WHEN SUBSTR(T.INT_RATE_TYP, 1, 1) = 'F' THEN
                 0 --固定利率
                ELSE
                 T.BASE_INT_RAT
              END --基准利率
             ,
              REAL_INT_RAT --实际利率
    ;
  COMMIT;*/
  SP_IRS_PARTITIONS_INC(IS_DATE, 'IE_DK_GRDKFK', OI_RETCODE);

  INSERT INTO IE_DK_GRDKFK_INC
    (datadate --数据日期
    ,
     loannum --贷款借据编号
    ,
     custid --客户号
    ,
     corpid --内部机构号
    ,
     serialno --交易流水号
    ,
     transactiondate --交易日期
    ,
     moneysymb --币种
    ,
     transamt --发生金额
    ,
     baserate --基准利率
    ,
     realrate --实际利率
    ,
     cjrq --采集日期
    ,
     nbjgh --内部机构号
    ,
     biz_line_id, --业务条线
     DIFF_TYPE, --增量标识
     LAST_DATA_DATE, --上一数据时点
     IRS_CORP_ID --法人机构ID
     )
    SELECT /*+ PARALLEL(8)*/
     VS_TEXT --数据日期
    ,
     LOAN_NUM --贷款借据编号
    ,
     CUST_ID --客户号
    ,
     ORG_NUM --内部机构号
    ,
     REF_TXN_NO --交易流水号
    ,
     DRAWDOWN_DT --交易日期
    ,
     trim(CURR_CD) --币种
    ,
     HAPPENED_BAL --发生金额
    ,
     BASE_INT_RAT --基准利率
    ,
     REAL_INT_RAT --实际利率
    ,
     IS_DATE --采集日期
    ,
     ORG_NUM --内部机构号
    ,
     '99', --业务条线
     '1', --增量标识
     TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD'), --上一数据时点
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
      FROM DATACORE_IE_DK_GRDKFK t
    /*where ORG_NUM NOT LIKE '0215%'*/
    ;
  COMMIT;

  -------------------------------------------------------------------------
  OI_RETCODE := 0; --设置成功状态为0
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

