CREATE OR REPLACE PROCEDURE BSP_SP_IRS_TY_MRFSJC (IS_DATE    IN VARCHAR2,
                                                OI_RETCODE OUT INTEGER,
                                               OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_TY_MRFSJC
  -- 用途:生成接口表 IE_TY_MRFSJC  买入反售及卖出回购基础息表
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY
  --
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT      VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
  /*NUM               INTEGER;*/
  --NUM1              INTEGER;
  VS_LAST_DAY       VARCHAR2(10) DEFAULT NULL;
BEGIN
  VS_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  VS_LAST_TEXT := TO_CHAR(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1),
                          'YYYYMMDD');
  VS_LAST_DAY  := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD');
  /*VS_LAST_TEXT := TO_CHAR(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1),'YYYYMMDD');*/
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_TY_MRFSJC';

  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------
---结果表
SP_IRS_PARTITIONS(IS_DATE,'IE_TY_MRFSJC',OI_RETCODE);
EXECUTE IMMEDIATE 'TRUNCATE TABLE L_CUST_BILL_TY_TEST1';
EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_TMP_TYXX_JRJG_WY'; --add by chm 20231012
EXECUTE IMMEDIATE 'TRUNCATE TABLE TYXX_JRJG_YESTERDAY'; --add by chm 20231012
EXECUTE IMMEDIATE 'TRUNCATE TABLE TYXX_JRJG_DIF'; --add by chm 20231012

---业务补录金融机构类型代码 票据的不用补录，使用L_CUST_BILL_TY足够  add by chm 20231012-----

  ---前一天数据日期的买入返售债券同业客户和金融机构类型代码

/*    INSERT INTO TYXX_JRJG_YESTERDAY
      SELECT B.CUST_ID, A.ORGTPCODE
        FROM IE_TY_MRFSJC_YD A
        LEFT JOIN SMTMODS.L_ACCT_FUND_REPURCHASE B
          ON A.CONTRACTNUM = B.ACCT_NUM
         AND B.DATA_DATE = VS_LAST_DAY
       WHERE A.CJRQ = VS_LAST_DAY;*/--20231030wxb
    INSERT INTO TYXX_JRJG_YESTERDAY
     ---- SELECT DISTINCT B.CUST_ID, A.ORGTPCODE
     SELECT DISTINCT B.CUST_SHORT_NAME, A.ORGTPCODE  ---add  by  zy  需要用客户名
        FROM IE_TY_MRFSJC_YD A
        LEFT JOIN SMTMODS.L_ACCT_FUND_REPURCHASE B
          ON A.CONTRACTNUM = B.ACCT_NUM
         AND B.DATA_DATE = VS_LAST_DAY
       WHERE A.CJRQ = VS_LAST_DAY
       AND A.ORGTPCODE IS NOT NULL;--业务不能保证在跑批之前补录好前一天的金融机构类型代码,故加此条件，只取前一天金融机构类型代码不为空的


    COMMIT;


  ---前一天补录的同业客户金融机构代码 更新进配置表 后续债券部分关联此表，保证补录过的不用重复补录

    MERGE INTO DATACORE_TMP_TYXX_JRJG A
    USING TYXX_JRJG_YESTERDAY B
    ON (A.CUST_NAME = B.cust_id)
    WHEN MATCHED THEN
      UPDATE SET A.JRJG = B.ORGTPCODE
    WHEN NOT MATCHED THEN
      INSERT (A.CUST_ID,A.CUST_NAME, A.JRJG) VALUES ('',B.CUST_ID, B.ORGTPCODE);
    COMMIT;

  --以金融机构名称为唯一，去重

   INSERT INTO DATACORE_TMP_TYXX_JRJG_WY
     SELECT DISTINCT CUST_NAME, JRJG FROM DATACORE_TMP_TYXX_JRJG;

   COMMIT;

  -----正式逻辑处理开始-----

--L_CUST_BILL_TY表中客户号去重
  INSERT INTO L_CUST_BILL_TY_TEST1
  SELECT data_date, 
org_num, 
cust_id, 
legal_name, 
fina_org_code, 
fina_code_new, 
fina_org_name, 
capital_amt, 
borrower_register_addr, 
tyshxydm, 
organizationcode, 
ecif_cust_id, 
legal_flag, 
legal_tyshxydm, 
cbrc_code, 
nation_cd, 
org_area, 
aswift_code, 
cust_bank_cd, 
corp_scale, 
corp_hold_type, 
bussines_type, 
fina_olic_num, 
cus_risk_lev, 
cust_short_name, 
rn

    FROM (SELECT A.*,
                 ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN    ---add  by  zy  将 cust_id  换成 ecif_cust_id
            FROM SMTMODS.L_CUST_BILL_TY A
           WHERE A.DATA_DATE = IS_DATE) B
   WHERE B.RN = '1';

  COMMIT;

 ---当前数据日期新增的需要业务补录的买入返售债券业务的同业客户及金融机构类型代码 add by chm 20231012

  INSERT INTO TYXX_JRJG_DIF
 -- SELECT DISTINCT A.CUST_ID, N.JRJG   
  SELECT DISTINCT A.CUST_SHORT_NAME, N.JRJG --- MDF BY ZY  将 cust_id  换成  CUST_SHORT_NAME
    FROM SMTMODS.L_ACCT_FUND_REPURCHASE A --回购信息表
   INNER JOIN SMTMODS.L_PUBL_ORG_BRA D --机构表
      ON A.ORG_NUM = D.ORG_NUM
     AND D.DATA_DATE = IS_DATE
    LEFT JOIN DATACORE_TMP_TYXX_JRJG_WY N
     --- ON A.CUST_ID = N.CUST_NAME --MDF BY CHM 20231012 减少运维补录，债券的CUST_ID只取上游，数值为中文
      ON A.CUST_SHORT_NAME = N.CUST_NAME --MDF BY ZY  将 cust_id  换成  CUST_SHORT_NAME
   WHERE A.DATA_DATE = IS_DATE
     AND SUBSTR(A.BUSI_TYPE, 1, 1) IN ('1', '2')
     AND A.ASS_TYPE = '1'
     AND A.CURR_CD IN ('CNY', 'USD', 'EUR', 'JPY', 'HKD')
     AND (A.LOAN_ACTUAL_DUE_DATE >= TO_DATE( IS_DATE, 'YYYYMMDD') OR
         A.LOAN_ACTUAL_DUE_DATE IS NULL)
     AND D.NATION_CD = 'CHN'
     AND NOT EXISTS( SELECT 1 FROM DATACORE_TMP_TYXX_JRJG_WY B WHERE A.CUST_SHORT_NAME = B.CUST_NAME）
  MINUS
  SELECT *
    FROM TYXX_JRJG_YESTERDAY ;

  COMMIT;

  INSERT /*+append*/ INTO IE_TY_MRFSJC NOLOGGING
    (
      DATADATE, --数据日期
      CORPID, --内部机构号
      CUSTID, --客户号
      ORGTPCODE, --金融机构类型代码
      CONTRACTNUM, --业务编码
      REPOBUSITYPE, --回购业务类型
      SUBJECTTYPE, --标的物类型
      STARTDATE, --起始日期
      MATUREDATE, --到期日期
      ACTUALDUEDATE, --实际终止日期
      REPOTERMTYPE, --回购期限类型
      FINAPRICINGTYPE, --借贷定价基准类型
      RATETYPE, --利率类型
      REALRATE, --实际利率
      BASERATE, --基准利率
      INTRATEMETH, --计息方式
      FLOATFREQ, --利率浮动频率
      CJRQ, --数据日期
      NBJGH,  --内部机构号
      REPORT_ID,  --报送ID
      BIZ_LINE_ID,  --业务条线
      VERIFY_STATUS,  --校验状态
      BSCJRQ,  --报送周期
      IRS_CORP_ID  --法人机构ID
     )
    SELECT  VS_TEXT AS DATADATE, --数据日期
            A.ORG_NUM AS CORPID, --内部机构号
            /*'' AS CUSTID, --客户号*/
           CASE
             WHEN T.CUST_ID IS NOT NULL THEN
              T.CUST_ID
             ELSE
              ''
               END AS CUST_ID, --客户号   add by chm 20231012 业务手动补录金融机构类型代码

            N.JRJG AS ORGTPCODE, --金融机构类型代码
            A.ACCT_NUM AS CONTRACTNUM, --业务编码
            CASE WHEN A.BUSI_TYPE = '101' THEN 'A02'
                 WHEN A.BUSI_TYPE = '102' THEN 'A01'
                 WHEN A.BUSI_TYPE = '201' THEN 'B02'
                 WHEN A.BUSI_TYPE = '202' THEN 'B01'
            END AS REPOBUSITYPE, --回购业务类型
            CASE WHEN A.ASS_TYPE = '1' THEN '01'
                 WHEN A.ASS_TYPE IN ('2','3') THEN '02'
                 WHEN E.SUBJECT_PRO_TYPE IN ('0901','0902') THEN '03'
                 WHEN (E.SUBJECT_PRO_TYPE LIKE '02%' OR E.SUBJECT_PRO_TYPE = '06') THEN '04'
                 WHEN E.SUBJECT_PRO_TYPE = '9903' THEN '05'
                 ELSE '09'
            END AS SUBJECTTYPE, --标的物类型
            TO_CHAR(A.BEG_DT,'YYYY-MM-DD') AS STARTDATE, --起始日期
            TO_CHAR(A.END_DT,'YYYY-MM-DD') AS MATUREDATE, --到期日期
            TO_CHAR(A.LOAN_ACTUAL_DUE_DATE,'YYYY-MM-DD') AS ACTUALDUEDATE, --实际终止日期
            CASE WHEN A.END_DT-A.BEG_DT = 1 THEN '01'
                 WHEN A.END_DT-A.BEG_DT = 7  THEN '02'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 0 AND MONTHS_BETWEEN(A.END_DT,A.BEG_DT) <= 1 AND A.END_DT-A.BEG_DT <> 1 AND A.END_DT-A.BEG_DT <> 7) THEN '03'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 1 AND MONTHS_BETWEEN(A.END_DT,A.BEG_DT) <= 3) THEN '04'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 3 AND MONTHS_BETWEEN(A.END_DT,A.BEG_DT) <= 6) THEN '05'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 6 AND MONTHS_BETWEEN(A.END_DT,A.BEG_DT) <= 12) THEN '06'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 12 AND MONTHS_BETWEEN(A.END_DT,A.BEG_DT) <= 24) THEN '07'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 24 AND MONTHS_BETWEEN(A.END_DT,A.BEG_DT) <= 36) THEN '08'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 36) THEN '09'
            END AS REPOTERMTYPE, --回购期限类型
            CASE WHEN A.PRICING_BASE_TYPE = 'A01' THEN 'TR01'
                 WHEN A.PRICING_BASE_TYPE = 'A0201' THEN 'TR04'
                 WHEN A.PRICING_BASE_TYPE = 'A0202' THEN 'TR05'
                 WHEN A.PRICING_BASE_TYPE = 'A0203' THEN 'TR06'
                 WHEN A.PRICING_BASE_TYPE = 'C' THEN 'TR07'
                 WHEN A.PRICING_BASE_TYPE = 'D' THEN 'TR08'
                 WHEN A.PRICING_BASE_TYPE = 'B01' THEN 'TR09'
                 WHEN A.PRICING_BASE_TYPE = 'B02' THEN 'TR10'
                 WHEN A.PRICING_BASE_TYPE = 'E' THEN 'TR11'
                 WHEN A.PRICING_BASE_TYPE = 'Z01' THEN 'TR02'
                 WHEN A.PRICING_BASE_TYPE = 'Z02' THEN 'TR03'
                 ELSE 'TR99'
            END AS FINAPRICINGTYPE, --借贷定价基准类型

            'RF01' AS RATETYPE, --利率类型  (生产逻辑默认为RF01，与生产一致进行修改)
            A.REAL_INT_RAT AS REALRATE, --实际利率
            '' AS BASERATE, --基准利率
            CASE WHEN A.ACC_INT_TYPE = '1' THEN '01'
                 WHEN A.ACC_INT_TYPE = '2' THEN '02'
                 WHEN A.ACC_INT_TYPE = '3' THEN '03'
                 WHEN A.ACC_INT_TYPE = '4' THEN '04'
                 WHEN A.ACC_INT_TYPE = '5' THEN '05'
                 ELSE '99'
            END AS INTRATEMETH, --计息方式
            CASE WHEN A.INT_RATE_TYP = 'L0' THEN '01'
                 WHEN A.INT_RATE_TYP = 'L1' THEN '02'
                 WHEN A.INT_RATE_TYP = 'L2' THEN '03'
                 WHEN A.INT_RATE_TYP = 'L3' THEN '04'
                 WHEN A.INT_RATE_TYP = 'L4' THEN '05'
                 WHEN A.INT_RATE_TYP = 'L5' THEN '06'
                 WHEN A.INT_RATE_TYP = 'L9' THEN '99'
            END AS FLOATFREQ, --利率浮动频率
            IS_DATE, --数据日期
            A.ORG_NUM,  --内部机构号
            SYS_GUID(),  --报送ID
            '99',  --业务条线
            '',  --校验状态
            '',  --报送周期
            CASE WHEN  A.ORG_NUM LIKE '51%' THEN '510000'
          WHEN  A.ORG_NUM LIKE '52%' THEN '520000'
          WHEN  A.ORG_NUM LIKE '53%' THEN '530000'
          WHEN  A.ORG_NUM LIKE '54%' THEN '540000'
          WHEN  A.ORG_NUM LIKE '55%' THEN '550000'
          WHEN  A.ORG_NUM LIKE '56%' THEN '560000'
          WHEN  A.ORG_NUM LIKE '57%' THEN '570000'
          WHEN  A.ORG_NUM LIKE '58%' THEN '580000'
          WHEN  A.ORG_NUM LIKE '59%' THEN '590000'
          WHEN  A.ORG_NUM LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
    FROM SMTMODS.L_ACCT_FUND_REPURCHASE A --回购信息表

    INNER JOIN SMTMODS.L_PUBL_ORG_BRA D  --机构表
           ON A.ORG_NUM = D.ORG_NUM
          AND D.DATA_DATE = IS_DATE
    LEFT  JOIN SMTMODS.L_AGRE_OTHER_SUBJECT_INFO E --其他标的物信息表
          ON A.SUBJECT_CD = E.SUBJECT_CD
          AND E.DATA_DATE = IS_DATE
    /*LEFT JOIN DATACORE_TMP_TYXX_JRJG N
         ON A.ACCT_NUM=N.CUST_ID*/
    LEFT JOIN DATACORE_TMP_TYXX_JRJG_WY N
       ---  ON A.CUST_ID = N.CUST_NAME   --MDF BY CHM 20231012 减少运维补录，债券的cust_id只取上游，数值为中文
          ON A.CUST_SHORT_NAME = N.CUST_NAME   ----MDF BY ZY  将 cust_id  换成  CUST_SHORT_NAME
    LEFT JOIN TYXX_JRJG_DIF T  --ADD BY CHM 20231012
         ON A.CUST_SHORT_NAME = T.CUST_ID  ----MDF BY ZY  将 cust_id  换成  CUST_SHORT_NAME
    WHERE A.DATA_DATE = IS_DATE
      AND SUBSTR(A.BUSI_TYPE,1,1) IN ('1','2')
      AND A.ASS_TYPE = '1'

      AND A.CURR_CD IN ('CNY','USD','EUR','JPY','HKD')

      AND (A.LOAN_ACTUAL_DUE_DATE >= TO_DATE(IS_DATE,'YYYYMMDD') OR A.LOAN_ACTUAL_DUE_DATE IS NULL)
      AND D.NATION_CD = 'CHN';

    COMMIT;

INSERT /*+append*/ INTO IE_TY_MRFSJC NOLOGGING
    (
      DATADATE, --数据日期
      CORPID, --内部机构号
      CUSTID, --客户号
      ORGTPCODE, --金融机构类型代码
      CONTRACTNUM, --业务编码
      REPOBUSITYPE, --回购业务类型
      SUBJECTTYPE, --标的物类型
      STARTDATE, --起始日期
      MATUREDATE, --到期日期
      ACTUALDUEDATE, --实际终止日期
      REPOTERMTYPE, --回购期限类型
      FINAPRICINGTYPE, --借贷定价基准类型
      RATETYPE, --利率类型
      REALRATE, --实际利率
      BASERATE, --基准利率
      INTRATEMETH, --计息方式
      FLOATFREQ, --利率浮动频率
      CJRQ, --数据日期
      NBJGH,  --内部机构号
      REPORT_ID,  --报送ID
      BIZ_LINE_ID,  --业务条线
      VERIFY_STATUS,  --校验状态
      BSCJRQ,  --报送周期
      IRS_CORP_ID  --法人机构ID
     )
    SELECT  VS_TEXT AS DATADATE, --数据日期
            A.ORG_NUM AS CORPID, --内部机构号
            '' AS CUSTID, --客户号


            NVL(TRIM(Z.FINA_CODE_NEW),N.JRJG)AS ORGTPCODE, --N.JRJG AS ORGTPCODE, --金融机构类型代码  MDF BY CHM 20230309
            A.ACCT_NUM||'_'||A.REF_NUM AS CONTRACTNUM, --业务编码
            CASE WHEN A.BUSI_TYPE = '101' THEN 'A02'
                 WHEN A.BUSI_TYPE = '102' THEN 'A01'
                 WHEN A.BUSI_TYPE = '201' THEN 'B02'
                 WHEN A.BUSI_TYPE = '202' THEN 'B01'
            END AS REPOBUSITYPE, --回购业务类型
            CASE WHEN A.ASS_TYPE = '1' THEN '01'
                 WHEN A.ASS_TYPE IN ('2','3') THEN '02'
                 WHEN E.SUBJECT_PRO_TYPE IN ('0901','0902') THEN '03'
                 WHEN (E.SUBJECT_PRO_TYPE LIKE '02%' OR E.SUBJECT_PRO_TYPE = '06') THEN '04'
                 WHEN E.SUBJECT_PRO_TYPE = '9903' THEN '05'
                 ELSE '09'
            END AS SUBJECTTYPE, --标的物类型
            TO_CHAR(A.BEG_DT,'YYYY-MM-DD') AS STARTDATE, --起始日期
            TO_CHAR(A.END_DT,'YYYY-MM-DD') AS MATUREDATE, --到期日期
            TO_CHAR(A.LOAN_ACTUAL_DUE_DATE,'YYYY-MM-DD') AS ACTUALDUEDATE, --实际终止日期
            CASE WHEN A.END_DT-A.BEG_DT = 1 THEN '01'
                 WHEN A.END_DT-A.BEG_DT = 7  THEN '02'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 0 AND MONTHS_BETWEEN(A.END_DT,A.BEG_DT) <= 1 AND A.END_DT-A.BEG_DT <> 1 AND A.END_DT-A.BEG_DT <> 7) THEN '03'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 1 AND MONTHS_BETWEEN(A.END_DT,A.BEG_DT) <= 3) THEN '04'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 3 AND MONTHS_BETWEEN(A.END_DT,A.BEG_DT) <= 6) THEN '05'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 6 AND MONTHS_BETWEEN(A.END_DT,A.BEG_DT) <= 12) THEN '06'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 12 AND MONTHS_BETWEEN(A.END_DT,A.BEG_DT) <= 24) THEN '07'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 24 AND MONTHS_BETWEEN(A.END_DT,A.BEG_DT) <= 36) THEN '08'
                 WHEN (MONTHS_BETWEEN(A.END_DT,A.BEG_DT) > 36) THEN '09'
            END AS REPOTERMTYPE, --回购期限类型
            CASE WHEN A.PRICING_BASE_TYPE = 'A01' THEN 'TR01'
                 WHEN A.PRICING_BASE_TYPE = 'A0201' THEN 'TR04'
                 WHEN A.PRICING_BASE_TYPE = 'A0202' THEN 'TR05'
                 WHEN A.PRICING_BASE_TYPE = 'A0203' THEN 'TR06'
                 WHEN A.PRICING_BASE_TYPE = 'C' THEN 'TR07'
                 WHEN A.PRICING_BASE_TYPE = 'D' THEN 'TR08'
                 WHEN A.PRICING_BASE_TYPE = 'B01' THEN 'TR09'
                 WHEN A.PRICING_BASE_TYPE = 'B02' THEN 'TR10'
                 WHEN A.PRICING_BASE_TYPE = 'E' THEN 'TR11'
                 WHEN A.PRICING_BASE_TYPE = 'Z01' THEN 'TR02'
                 WHEN A.PRICING_BASE_TYPE = 'Z02' THEN 'TR03'
                 ELSE 'TR99'
            END AS FINAPRICINGTYPE, --借贷定价基准类型

            'RF01' AS RATETYPE, --利率类型  (生产逻辑默认为RF01，与生产一致进行修改)
            A.REAL_INT_RAT * 100 AS REALRATE, --实际利率
            '' AS BASERATE, --基准利率
            CASE WHEN A.ACC_INT_TYPE = '1' THEN '01'
                 WHEN A.ACC_INT_TYPE = '2' THEN '02'
                 WHEN A.ACC_INT_TYPE = '3' THEN '03'
                 WHEN A.ACC_INT_TYPE = '4' THEN '04'
                 WHEN A.ACC_INT_TYPE = '5' THEN '05'
                 ELSE '99'
            END AS INTRATEMETH, --计息方式
            CASE WHEN A.INT_RATE_TYP = 'L0' THEN '01'
                 WHEN A.INT_RATE_TYP = 'L1' THEN '02'
                 WHEN A.INT_RATE_TYP = 'L2' THEN '03'
                 WHEN A.INT_RATE_TYP = 'L3' THEN '04'
                 WHEN A.INT_RATE_TYP = 'L4' THEN '05'
                 WHEN A.INT_RATE_TYP = 'L5' THEN '06'
                 WHEN A.INT_RATE_TYP = 'L9' THEN '99'
            END AS FLOATFREQ, --利率浮动频率
            IS_DATE, --数据日期
            A.ORG_NUM,  --内部机构号
            SYS_GUID(),  --报送ID
            '99',  --业务条线
            '',  --校验状态
            '',  --报送周期
            CASE WHEN  A.ORG_NUM LIKE '51%' THEN '510000'
          WHEN  A.ORG_NUM LIKE '52%' THEN '520000'
          WHEN  A.ORG_NUM LIKE '53%' THEN '530000'
          WHEN  A.ORG_NUM LIKE '54%' THEN '540000'
          WHEN  A.ORG_NUM LIKE '55%' THEN '550000'
          WHEN  A.ORG_NUM LIKE '56%' THEN '560000'
          WHEN  A.ORG_NUM LIKE '57%' THEN '570000'
          WHEN  A.ORG_NUM LIKE '58%' THEN '580000'
          WHEN  A.ORG_NUM LIKE '59%' THEN '590000'
          WHEN  A.ORG_NUM LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
    FROM SMTMODS.L_ACCT_FUND_REPURCHASE A --回购信息表

    INNER JOIN SMTMODS.L_PUBL_ORG_BRA D  --机构表
           ON A.ORG_NUM = D.ORG_NUM
          AND D.DATA_DATE = IS_DATE
    LEFT  JOIN SMTMODS.L_AGRE_OTHER_SUBJECT_INFO E --其他标的物信息表
          ON A.SUBJECT_CD = E.SUBJECT_CD
          AND E.DATA_DATE = IS_DATE
    LEFT JOIN DATACORE_TMP_TYXX_JRJG N
         ON A.ACCT_NUM||'_'||A.REF_NUM=N.CUST_ID
    LEFT JOIN L_CUST_BILL_TY_TEST1 Z  --MDF BY CHM 20230309
        ON A.CUST_ID = Z.CUST_ID
        AND Z.DATA_DATE = IS_DATE
    WHERE A.DATA_DATE = IS_DATE
      AND SUBSTR(A.BUSI_TYPE,1,1) IN ('1','2')
      AND A.ASS_TYPE = '2'

      AND A.CURR_CD IN ('CNY','USD','EUR','JPY','HKD')

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

