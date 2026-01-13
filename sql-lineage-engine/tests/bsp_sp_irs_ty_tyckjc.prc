CREATE OR REPLACE PROCEDURE BSP_SP_IRS_TY_TYCKJC(IS_DATE    IN VARCHAR2,
                                                OI_RETCODE OUT INTEGER,
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
  --    add 业务补录金融机构类型代码
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE      NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT           VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
  NUM               INTEGER;
  VS_LAST_DAY       VARCHAR2(10) DEFAULT NULL;
BEGIN
  VS_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  VS_LAST_TEXT := TO_CHAR(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1),
                          'YYYYMMDD');
  VS_LAST_DAY  := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD');
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_TY_TYCKJC';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------

EXECUTE IMMEDIATE'TRUNCATE TABLE CUST_TY_NEW';
EXECUTE IMMEDIATE'TRUNCATE TABLE L_CUST_BILL_TY_CKTMP';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE TX_JRJG_YESTERDAY';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE TX_JRJG_DIF';
/*INSERT INTO CUST_TY_NEW
SELECT *
  FROM (SELECT CUST_NAM,
               ID_NO,
               CUST_ID,
               ROW_NUMBER() OVER(PARTITION BY CUST_NAM, ID_NO ORDER BY CUST_ID) AS RN
          FROM SMTMODS.L_CUST_ALL A
         WHERE A.DATA_DATE = IS_DATE) A
 WHERE A.RN = '1';

COMMIT;*/
  -----业务补录金融金融机构代码-----

  ---前一天数据日期的同业客户和金融机构类型代码

  INSERT INTO TX_JRJG_YESTERDAY
    SELECT DISTINCT CUST_NAM, ORGTPCODE
      FROM (SELECT A.ACCDEPCODE,
                   B.REF_NUM,
                   B.CUST_ID,
                   C.CUST_NAM   AS CUST_NAM,
                   A.ORGTPCODE  AS ORGTPCODE
              FROM IE_TY_TYCKJC_YD A
              LEFT JOIN SMTMODS.L_ACCT_FUND_MMFUND B
                ON A.ACCDEPCODE = B.REF_NUM
               AND B.DATA_DATE = VS_LAST_DAY
               AND SUBSTR(B.GL_ITEM_CODE, '1', '4') IN ('1011', '2012')
               AND (TO_CHAR(B.MATURE_DATE, 'YYYYMMDD') >= VS_LAST_DAY OR
                   B.MATURE_DATE IS NULL)
               AND B.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
              LEFT JOIN SMTMODS.L_CUST_ALL C
                ON B.CUST_ID = C.CUST_ID
               AND C.DATA_DATE = VS_LAST_DAY
/*             WHERE A.CJRQ = VS_LAST_DAY);*/--20231030wxb
             WHERE A.CJRQ = VS_LAST_DAY
             AND A.ORGTPCODE IS NOT NULL);

  COMMIT;

  ---前一天补录的同业客户金融机构代码 更新进配置表 后续关联此表，保证补录过的不用重复补录

  MERGE INTO DATACORE_TMP_TX_JRJG A
  USING TX_JRJG_YESTERDAY B
  ON (A.CUST_ID = B.CUST_NAM)
  WHEN MATCHED THEN
    UPDATE SET A.JRJG = B.ORGTPCODE
  WHEN NOT MATCHED THEN
    INSERT (A.CUST_ID, A.JRJG) VALUES (B.CUST_NAM, B.ORGTPCODE);
  COMMIT;

  -----正式逻辑处理开始-----

INSERT INTO CUST_TY_NEW
SELECT CUST_NAM, ID_NO, CUST_ID, '1'
  FROM SMTMODS.L_CUST_ALL A
 WHERE A.DATA_DATE = IS_DATE;

COMMIT;

--同业客户补充信息表去重   add by chm 20230615
INSERT INTO L_CUST_BILL_TY_CKTMP
SELECT
  data_date              ,
  org_num               ,
  cust_id                ,
  legal_name             ,
  fina_org_code          ,
  fina_code_new          ,
  fina_org_name          ,
  capital_amt            ,
  borrower_register_addr ,
  tyshxydm               ,
  organizationcode       ,
  ecif_cust_id           ,
  legal_flag             ,
  legal_tyshxydm         ,
  cbrc_code              ,
  nation_cd              ,
  org_area               ,
  aswift_code            ,
  cust_bank_cd           ,
  corp_scale             ,
  corp_hold_type         ,
  bussines_type          ,
  fina_olic_num          ,
  cus_risk_lev           ,
  cust_short_name        ,
  rn

  FROM (SELECT A.*,
               ROW_NUMBER() OVER(PARTITION BY A.FINA_ORG_NAME ORDER BY A.CUST_ID) RN
          FROM SMTMODS.L_CUST_BILL_TY A
         WHERE A.DATA_DATE = IS_DATE ) B
 WHERE B.RN = '1';

 COMMIT ;

EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_TY_TYCKJC ';
INSERT INTO  DATACORE_IE_TY_TYCKJC
    (datadate --数据日期
    ,
     corpid --内部机构号
    ,
     custid --客户号
    ,
     orgtpcode --金融机构类型代码
    ,
     accdepcode --存款账户编码
    ,
     finadeptype --存放业务类型
    ,
     startdate --起始日期
    ,
     maturedate --到期日期
    ,
     deptermtype --存款期限类型
    ,
     pricingtype --定价基准类型
    ,
     ratetype --利率类型
    ,
     realrate --实际利率
    ,
     baserate --基准利率
    ,
     floatfreq --利率浮动频率
    ,
     cust_name --客户名称    --20240909  新增客户名称字段，代替之前的客户号字段保存交易对手客户名称
     )

SELECT /*+ USE_HASH(T,A) PARALLEL(8)*/
VS_TEXT    --数据日期
    ,
     T.org_num --内部机构号
     /*,CASE WHEN T.CUST_ID = '6000884761' THEN '江西银行股份有限公司'
     WHEN T.CUST_ID = '8913394106' THEN '江西银行股份有限公司'
       ELSE NVL(A.CUST_NAM,T.CUST_ID) END  --客户号*/,
     T.CUST_ID --客户号     --20240909    NR表加工需要客户号，对数据进行提取，此前这个字段存的是交易对手客户名称
     --,t.CPTYS_SHORT_NAME  --客户号（交易对手客户名）
    ,
     '' --金融机构类型代码
    ,
    ref_num   --存款账户编码
/*,CASE WHEN gl_item_code like '11401%' THEN 'A021'         --存放同业活期款项
      WHEN gl_item_code like '11402%' THEN 'A022'         --存放同业定期款项
      WHEN gl_item_code like '23401%' THEN 'A011'         --同业存放活期款项
      WHEN gl_item_code like '23402%' THEN 'A012'         --同业存放定期款项
      WHEN gl_item_code like '23403%' AND mature_date IS NOT NULL THEN 'A012'
      WHEN gl_item_code like '23403%' AND gl_item_code IS NULL THEN 'A011'
     ELSE NULL  END  --存放业务类型*/,
     CASE
       WHEN gl_item_code like '101101%' THEN
        'A021' --存放同业活期款项
       WHEN gl_item_code like '101102%' THEN
        'A022' --存放同业定期款项
       WHEN gl_item_code like '201201%' THEN
        'A011' --同业存放活期款项
       WHEN gl_item_code like '201202%' THEN
        'A012' --同业存放定期款项
       WHEN gl_item_code like '250202%' AND mature_date IS NOT NULL THEN
        'A012' --发行同业存单
       WHEN gl_item_code like '250202%' AND gl_item_code IS NULL THEN
        'A011'
       ELSE
        NULL
     END --存放业务类型
    ,
     TO_CHAR(start_date, 'YYYY-MM-DD') --起始日期
    ,
     CASE
       WHEN TO_CHAR(mature_date, 'YYYYMMDD') = '99991231' THEN
        ''
       ELSE
        TO_CHAR(mature_date, 'YYYY-MM-DD')
     END --到期日期
    ,
     CASE
       WHEN mature_date IS NULL THEN
        ''
       ELSE
        TO_CHAR(months_between(mature_date, start_date))
     END --存款期限类型
    ,
     'TR99' --定价基准类型
    ,
     'RF01' --利率类型
    ,
     real_int_rat --实际利率
    ,
     '' --基准利率
    ,
     '' --利率浮动频率

    ,NVL(A.CUST_NAM, T.CUST_ID) --客户名称  20240909  新增客户名称字段，代替之前的客户号字段保存交易对手客户名称
FROM SMTMODS.L_ACCT_FUND_MMFUND  t
/*LEFT JOIN SMTMODS.L_TY_CUSTID_INFO f
ON T.CUST_ID=F.CUST_NM*/
LEFT JOIN CUST_TY_NEW A
ON (T.CUST_ID = A.CUST_ID OR T.CUST_ID = A.ID_NO)
WHERE T.DATA_DATE=IS_DATE
--AND substr(gl_item_code,'1','3') in ('114','234')
AND substr(gl_item_code,'1','4') in ('1011','2012')
/*AND (substr(gl_item_code,'1','4') in ('1011')   --存放同业
     OR substr(gl_item_code,'1','6') in ('201202','201203'))--同业存放*/
AND TO_CHAR(mature_date,'YYYYMMDD') >=IS_DATE  --modify by haorui 20241219 删除OR mature_date IS NULL 卡掉历史无效数据（5条）
AND T.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
--AND T.REF_NUM <> '41038441'
--AND T.ACCT_STS NOT LIKE 'D%'
--AND T.ORG_NUM NOT LIKE '0215%'
;
COMMIT;
/*
INSERT INTO  DATACORE_IE_TY_TYCKJC
    (datadate --数据日期
    ,
     corpid --内部机构号
    ,
     custid --客户号
    ,
     orgtpcode --金融机构类型代码
    ,
     accdepcode --存款账户编码
    ,
     finadeptype --存放业务类型
    ,
     startdate --起始日期
    ,
     maturedate --到期日期
    ,
     deptermtype --存款期限类型
    ,
     pricingtype --定价基准类型
    ,
     ratetype --利率类型
    ,
     realrate --实际利率
    ,
     baserate --基准利率
    ,
     floatfreq --利率浮动频率
     )
    SELECT \*+ USE_HASH(T,A) PARALLEL(8)*\
     VS_TEXT --数据日期
    ,
     '510001' --内部机构号
    ,
     NVL(A.CUST_NAM, T.CUST_ID) --客户号
     --,t.CPTYS_SHORT_NAME  --客户号（交易对手客户名）
    ,
     'C07' --金融机构类型代码
    ,
     ACCT_NUM --存款账户编码
\*,CASE WHEN gl_item_code like '11401%' THEN 'A021'         --存放同业活期款项
      WHEN gl_item_code like '11402%' THEN 'A022'         --存放同业定期款项
      WHEN gl_item_code like '23401%' THEN 'A011'         --同业存放活期款项
      WHEN gl_item_code like '23402%' THEN 'A012'         --同业存放定期款项
      WHEN gl_item_code like '23403%' AND mature_date IS NOT NULL THEN 'A012'
      WHEN gl_item_code like '23403%' AND gl_item_code IS NULL THEN 'A011'
     ELSE NULL  END  --存放业务类型*\,
     CASE
       WHEN gl_item_code like '101101%' THEN
        'A011' --存放同业活期款项
       WHEN gl_item_code like '101102%' THEN
        'A022' --存放同业定期款项
       WHEN gl_item_code like '201201%' THEN
        'A021' --同业存放活期款项
       WHEN gl_item_code like '201202%' THEN
        'A022' --同业存放定期款项
       WHEN gl_item_code like '250202%' AND mature_date IS NOT NULL THEN
        'A022' --发行同业存单
       WHEN gl_item_code like '250202%' AND gl_item_code IS NULL THEN
        'A021'
       ELSE
        NULL
     END --存放业务类型
    ,
     TO_CHAR(start_date, 'YYYY-MM-DD') --起始日期
    ,
     CASE
       WHEN TO_CHAR(mature_date, 'YYYYMMDD') = '99991231' THEN
        ''
       ELSE
        TO_CHAR(mature_date, 'YYYY-MM-DD')
    END--到期日期
    ,
     CASE
       WHEN mature_date IS NULL OR
            TO_CHAR(T.MATURE_DATE, 'YYYYMMDD') = '99991231' THEN
        ''
       ELSE
        TO_CHAR(months_between(mature_date, start_date))
     END --存款期限类型
    ,
     'TR99' --定价基准类型
    ,
     'RF01' --利率类型
    ,
     real_int_rat --实际利率
    ,
     '' --基准利率
    ,
     '' --利率浮动频率
FROM SMTMODS.L_ACCT_FUND_MMFUND  t

LEFT JOIN CUST_TY_NEW A
ON (T.CUST_ID = A.CUST_ID OR T.CUST_ID = A.ID_NO)
WHERE T.DATA_DATE=IS_DATE
AND substr(gl_item_code,'1','4') in ('1011','2012')

AND (TO_CHAR(mature_date,'YYYYMMDD') >=IS_DATE OR
mature_date IS NULL )
AND T.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
\*AND T.ACCT_NUM IN('60599235000000437_1')*\
--20231109wxb根据需求删除AND T.ACCT_NUM IN('60599235000000437_1')这个条件

;
COMMIT;*/--20231120wxb上面的逻辑可以出磐石的数据

  ----当前数据日期新增的同业存款业务的客户及金融机构类型代码 add by chm 20231012

  INSERT INTO TX_JRJG_DIF
    SELECT DISTINCT CUST_NAM, ORGTPCODE
      FROM (SELECT A.CUST_NAME AS CUST_NAM, --客户号      --将之前从cust_id取数以及相关的关联条件改为cust_name
                   NVL(NVL(B.JRJG, TRIM(C.FINA_CODE_NEW)), A.ORGTPCODE) AS ORGTPCODE, --金融机构类型代码
                   ACCDEPCODE --存款账户编码
              FROM DATACORE_IE_TY_TYCKJC A
              LEFT JOIN DATACORE_TMP_TX_JRJG B
                ON A.CUST_NAME = B.CUST_ID
              LEFT JOIN L_CUST_BILL_TY_CKTMP C
                ON A.CUST_NAME = C.FINA_ORG_NAME
             WHERE /*A.CORPID NOT LIKE '5100%'
               AND*/ A.DATADATE = VS_TEXT
               AND NOT EXISTS (SELECT 1
                      FROM L_CUST_BILL_TY_CKTMP B
                     WHERE A.CUST_NAME = B.FINA_ORG_NAME)
               AND NOT EXISTS (SELECT 1
                      FROM DATACORE_TMP_TX_JRJG B
                     WHERE A.CUST_NAME = B.CUST_ID))
    MINUS
    SELECT *
      FROM TX_JRJG_YESTERDAY;

  COMMIT;
 SP_IRS_PARTITIONS(IS_DATE,'IE_TY_TYCKJC',OI_RETCODE);

INSERT INTO  IE_TY_TYCKJC
    (datadate --数据日期
    ,
     corpid --内部机构号
    ,
     custid --客户号
    ,
     orgtpcode --金融机构类型代码
    ,
     accdepcode --存款账户编码
    ,
     finadeptype --存放业务类型
    ,
     startdate --起始日期
    ,
     maturedate --到期日期
    ,
     deptermtype --存款期限类型
    ,
     pricingtype --定价基准类型
    ,
     ratetype --利率类型
    ,
     realrate --实际利率
    ,
     baserate --基准利率
    ,
     floatfreq --利率浮动频率
    ,
     cjrq --采集日期
    ,
     nbjgh --内部机构号
    ,
     biz_line_id --业务条线
    ,
     IRS_CORP_ID --法人机构ID
     )

   SELECT DATADATE --数据日期
          ,
           CORPID --内部机构号
          ,
           A.CUSTID --客户号   add by chm 20231012 业务手动补录金融机构类型代码   20240909    NR表加工需要客户号，对数据进行提取，此前这个字段存的是交易对手客户名称
          ,
           CASE
             WHEN D.CUST_NAM IS NOT NULL THEN
              '空'
             ELSE
              NVL(NVL(B.JRJG, TRIM(C.FINA_CODE_NEW)), A.ORGTPCODE)
           END --金融机构类型代码 MDF BY CHM 20231012
          ,
           ACCDEPCODE --存款账户编码
          ,
           FINADEPTYPE --存放业务类型
          ,
           STARTDATE --起始日期
          ,
           MATUREDATE --到期日期
          ,
           CASE
             WHEN (DEPTERMTYPE = '' OR DEPTERMTYPE IS NULL OR FINADEPTYPE = 'A011' OR FINADEPTYPE = 'A021') THEN   -- 存放业务类型为A011或A021活期存放时，存款期限类型为01活期 mdf 20240220
              '01'
             WHEN DEPTERMTYPE < 1 THEN
              '02'
             WHEN DEPTERMTYPE = '1' THEN
              '03'
             WHEN DEPTERMTYPE < 3 THEN
              '04'
             WHEN DEPTERMTYPE = '3' THEN
              '05'
             WHEN DEPTERMTYPE < 6 THEN
              '06'
             WHEN DEPTERMTYPE = '6' THEN
              '07'
             WHEN DEPTERMTYPE < 12 THEN
              '08'
             WHEN DEPTERMTYPE = '12' THEN
              '09'
             WHEN DEPTERMTYPE < 24 THEN
              '10'
             WHEN DEPTERMTYPE = '24' THEN
              '11'
             WHEN DEPTERMTYPE < 36 THEN
              '12'
             WHEN DEPTERMTYPE = '36' THEN
              '13'
             WHEN DEPTERMTYPE < 60 THEN
              '14'
             WHEN DEPTERMTYPE = '60' THEN
              '15'
             WHEN DEPTERMTYPE > 60 THEN
              '16'
             ELSE
              NULL
           END --存款期限类型
          ,
           PRICINGTYPE --定价基准类型
          ,
           RATETYPE --利率类型
          ,
           REALRATE --实际利率
          ,
           BASERATE --基准利率
          ,
           '' --利率浮动频率
          ,
           IS_DATE --采集日期
          ,
           CORPID --内部机构号
          ,
           '99' --业务条线
,CASE WHEN A.CORPID LIKE '51%' THEN '510000'
          WHEN A.CORPID LIKE '52%' THEN '520000'
          WHEN A.CORPID LIKE '53%' THEN '530000'
          WHEN A.CORPID LIKE '54%' THEN '540000'
          WHEN A.CORPID LIKE '55%' THEN '550000'
          WHEN A.CORPID LIKE '56%' THEN '560000'
          WHEN A.CORPID LIKE '57%' THEN '570000'
          WHEN A.CORPID LIKE '58%' THEN '580000'
          WHEN A.CORPID LIKE '59%' THEN '590000'
          WHEN A.CORPID LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
FROM DATACORE_IE_TY_TYCKJC A
LEFT JOIN DATACORE_TMP_TX_JRJG B
       ON A.CUST_NAME=B.CUST_ID
LEFT JOIN L_CUST_BILL_TY_CKTMP C  --add by chm 20230615 减少金融机构类型代码手动补录
 ON A.CUST_NAME = C.FINA_ORG_NAME
      LEFT JOIN TX_JRJG_DIF D --ADD BY CHM 20231012 新增同业客户，呈现在应用端，业务手动补录金融机构类型代码
        ON A.CUST_NAME = D.CUST_NAM
  --WHERE A.CORPID NOT LIKE '5100%';
  WHERE A.CORPID NOT IN ('550005','550013')--add by wxb 20240221 沧县这两个机构已撤并
  ;
COMMIT;



--通过这段逻辑给业务查询交易对手名称
/*


select * from DATACORE_IE_TY_TYCKJC a where a.cust_id = '';




SELECT    a.custid,CASE
             WHEN D.CUST_NAM IS NOT NULL THEN
              D.CUST_NAM
             ELSE
              ''
           END AS CUST_ID --客户号   add by chm 20231012 业务手动补录金融机构类型代码
FROM DATACORE_IE_TY_TYCKJC A
LEFT JOIN DATACORE_TMP_TX_JRJG B
       ON A.CUST_NAME=B.CUST_ID
LEFT JOIN L_CUST_BILL_TY_CKTMP C  --add by chm 20230615 减少金融机构类型代码手动补录
 ON A.CUST_NAME = C.FINA_ORG_NAME
      LEFT JOIN TX_JRJG_DIF D --ADD BY CHM 20231012 新增同业客户，呈现在应用端，业务手动补录金融机构类型代码
        ON A.CUST_NAME = D.CUST_NAM
  WHERE A.CORPID NOT IN ('550005','550013')--add by wxb 20240221 沧县这两个机构已撤并
  and a.custid = ''
  ;*/




/*
 \* INSERT INTO IE_TY_TYCKJC
    (datadate --数据日期
    ,
     corpid --内部机构号
    ,
     custid --客户号
    ,
     orgtpcode --金融机构类型代码
    ,
     accdepcode --存款账户编码
    ,
     finadeptype --存放业务类型
    ,
     startdate --起始日期
    ,
     maturedate --到期日期
    ,
     deptermtype --存款期限类型
    ,
     pricingtype --定价基准类型
    ,
     ratetype --利率类型
    ,
     realrate --实际利率
    ,
     baserate --基准利率
    ,
     floatfreq --利率浮动频率
    ,
     cjrq --采集日期
    ,
     nbjgh --内部机构号
    ,
     biz_line_id --业务条线
    ,
     IRS_CORP_ID --法人机构ID
     )
SELECT DATADATE --数据日期
          ,
           CORPID --内部机构号
          ,
           '' --客户号
          ,
           CASE
             WHEN B.JRJG IS NOT NULL THEN
              B.JRJG
             ELSE
              A.ORGTPCODE
           END --金融机构类型代码
          ,
           ACCDEPCODE --存款账户编码
          ,
           FINADEPTYPE --存放业务类型
          ,
           STARTDATE --起始日期
          ,
           MATUREDATE --到期日期
          ,
           CASE
             WHEN (DEPTERMTYPE = '' OR DEPTERMTYPE IS NULL OR FINADEPTYPE = 'A011' OR FINADEPTYPE = 'A021') THEN -- 存放业务类型为A011或A021活期存放时，存款期限类型为01活期 mdf 20240220
              '01'
             WHEN DEPTERMTYPE < 1 THEN
              '02'
             WHEN DEPTERMTYPE = '1' THEN
              '03'
             WHEN DEPTERMTYPE < 3 THEN
              '04'
             WHEN DEPTERMTYPE = '3' THEN
              '05'
             WHEN DEPTERMTYPE < 6 THEN
              '06'
             WHEN DEPTERMTYPE = '6' THEN
              '07'
             WHEN DEPTERMTYPE < 12 THEN
              '08'
             WHEN DEPTERMTYPE = '12' THEN
              '09'
             WHEN DEPTERMTYPE < 24 THEN
              '10'
             WHEN DEPTERMTYPE = '24' THEN
              '11'
             WHEN DEPTERMTYPE < 36 THEN
              '12'
             WHEN DEPTERMTYPE = '36' THEN
              '13'
             WHEN DEPTERMTYPE < 60 THEN
              '14'
             WHEN DEPTERMTYPE = '60' THEN
              '15'
             WHEN DEPTERMTYPE > 60 THEN
              '16'
             ELSE
              NULL
           END --存款期限类型
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
           IS_DATE --采集日期
          ,
           CORPID --内部机构号
          ,
           '99' --业务条线
          ,
           '510000' --法人机构ID
FROM DATACORE_IE_TY_TYCKJC A
LEFT JOIN DATACORE_TMP_TX_JRJG B
       ON A.CUSTID=B.CUST_ID
WHERE A.CORPID LIKE '5100%'*\
 \*AND A.ACCDEPCODE = '60599235000000437_1'*\ ;
 --20231109wxb根据需求删除这个条件AND A.ACCDEPCODE = '60599235000000437_1'
\*COMMIT;*\*/
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

    SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);
END;
/

