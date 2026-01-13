CREATE OR REPLACE PROCEDURE BSP_SP_IRS_TY_TYJDJC(IS_DATE    IN VARCHAR2,
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
  --    需求编号：JLBA202311140009 上线日期：2025-09-19，修改人：蒿蕊，提出人：从需求  修改原因：新增借贷业务类型映射关系；
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
  VS_PROCEDURE_NAME := 'SP_IRS_TY_TYJDJC';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------

EXECUTE IMMEDIATE'TRUNCATE TABLE CUST_TY';
EXECUTE IMMEDIATE'TRUNCATE TABLE L_CUST_BILL_TY_TMP';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE TX_JRJG_YESTERDAY_JD';
  EXECUTE IMMEDIATE 'TRUNCATE TABLE TX_JRJG_DIF_JD';
  -----业务补录金融金融机构代码-----

  ---前一天数据日期的同业客户和金融机构类型代码

  INSERT INTO TX_JRJG_YESTERDAY_JD
    SELECT DISTINCT NVL(CUST_NAM, CUST_ID), ORGTPCODE
      FROM (SELECT A.CONTRACTNUM,
                   B.REF_NUM,
                   B.CUST_ID     AS CUST_ID,
                   C.CUST_NAM    AS CUST_NAM,
                   A.ORGTPCODE   AS ORGTPCODE
              FROM IE_TY_TYJDJC_YD A
              LEFT JOIN SMTMODS.L_ACCT_FUND_MMFUND B
                ON A.CONTRACTNUM = B.REF_NUM
               AND B.DATA_DATE = VS_LAST_DAY
               AND SUBSTR(B.GL_ITEM_CODE, '1', '4') IN ('2003', '1302')
               AND (TO_CHAR(B.MATURE_DATE, 'YYYYMMDD') >= VS_LAST_DAY OR
                   B.MATURE_DATE IS NULL)
               AND B.CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
              LEFT JOIN SMTMODS.L_CUST_ALL C
                ON B.CUST_ID = C.CUST_ID
               AND C.DATA_DATE = VS_LAST_DAY
             /*WHERE A.CJRQ = VS_LAST_DAY);*/--20231030wxb
             WHERE A.CJRQ = VS_LAST_DAY
             AND A.ORGTPCODE IS NOT NULL);
  COMMIT;

  ---前一天补录的同业客户金融机构代码 更新进配置表 后续关联此表，保证补录过的不用重复补录

  MERGE INTO DATACORE_TMP_TX_JRJG_JD A
  USING TX_JRJG_YESTERDAY_JD B
  ON (A.CUST_ID = B.CUST_NAM)
  WHEN MATCHED THEN
    UPDATE SET A.JRJG = B.ORGTPCODE
  WHEN NOT MATCHED THEN
    INSERT (A.CUST_ID, A.JRJG) VALUES (B.CUST_NAM, B.ORGTPCODE);
  COMMIT;

  -----正式逻辑处理开始-----

/*INSERT INTO CUST_TY
SELECT *
  FROM (SELECT CUST_NAM,
               ID_NO,
               CUST_ID,
               ROW_NUMBER() OVER(PARTITION BY CUST_NAM, ID_NO ORDER BY CUST_NAM, ID_NO) AS RN
          FROM SMTMODS.L_CUST_ALL A
         WHERE A.DATA_DATE = IS_DATE) A
 WHERE A.RN = '1';*/    ---add  by  zy  20240606 mmfund表的客户号已经补全了

 --同业客户补充信息表去重   add by chm 20230615
INSERT INTO L_CUST_BILL_TY_TMP
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
               ROW_NUMBER() OVER(PARTITION BY A.FINA_ORG_NAME ORDER BY A.CUST_ID) RN
          FROM SMTMODS.L_CUST_BILL_TY A
         WHERE A.DATA_DATE = IS_DATE ) B
 WHERE B.RN = '1';

 COMMIT ;

EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_TY_TYJDJC ';

INSERT INTO  DATACORE_IE_TY_TYJDJC
(datadate --数据日期
    ,
     corpid --内部机构号
    ,
     custid --客户号
    ,
     orgtpcode --金融机构类型代码
    ,
     contractnum --业务编码
    ,
     finaloantype --借贷业务类型
    ,
     startdate --起始日期
    ,
     maturedate --到期日期
    ,
     actualduedate --实际终止日期
    ,
     finatermtype --同业借贷期限类型
    ,
     ratetype --利率类型
    ,
     realrate --实际利率
    ,
     finapricingtype --借贷定价基准类型
    ,
     baserate --基准利率
    ,
     intratemeth --计息方式
    ,
     floatfreq --利率浮动频率
    ,
     CUST_NAME
     )
SELECT /*+ USE_HASH(T,A,B) PARALLEL(8)*/
VS_TEXT--数据日期
    ,
     T.ORG_NUM --内部机构号
    ,
     T.CUST_ID --客户号  add  by  zy  mmfund 已经补了全量客户号  20240909 新增同业客户号取数
    ,
     '' --金融机构类型代码
    ,
     ref_num contractnum --业务编码
/*,CASE WHEN substr(gl_item_code,'1','3')='120' THEN 'B01'
  WHEN substr(gl_item_code,'1','3')='241' AND ACCT_TYP='20501' THEN 'B02'  --同业借入
  WHEN substr(gl_item_code,'1','3')='241' AND ACCT_TYP ='10201' THEN 'A01'  --拆出
  WHEN substr(gl_item_code,'1','3')='241' AND ACCT_TYP='20201' THEN 'A02'   --拆入
     END --借贷业务类型*/,
     CASE
       WHEN substr(gl_item_code, '1', '4') = '1302' THEN
        'B01' --拆出资金
       WHEN substr(gl_item_code, '1', '4') = '2003' AND ACCT_TYP like '205%' THEN
        'B02' --同业借入
     --WHEN substr(gl_item_code,'1','4')='2003' AND ACCT_TYP ='10201' THEN 'A01'  --拆出
       WHEN substr(gl_item_code, '1', '4') = '1302' AND ACCT_TYP = '10201' THEN
        'A01' --拆放
       WHEN substr(gl_item_code, '1', '4') = '2003' AND ACCT_TYP = '20201' THEN
        'A02' --拆入
	   WHEN substr(gl_item_code, '1', '4') = '2003' AND ACCT_TYP = '10501' THEN 'B01' --借出同业 [2025-09-19] [蒿蕊] [JLBA202311140009] [从需求]增加业务类型为10501的映射
 END --借贷业务类型
    ,
     to_char(start_date, 'yyyy-mm-dd') --起始日期
    ,
     to_char(mature_date, 'yyyy-mm-dd') --到期日期
    ,
     to_char(LOAN_ACTUAL_DUE_DATE, 'yyyy-mm-dd') --实际终止日期
    ,
     CASE
       WHEN mature_date IS NULL THEN
        ''
       ELSE
        TO_CHAR(months_between(mature_date, start_date))
     END --存款期限类型
    ,
     'RF01' --利率类型
    ,
     real_int_rat --实际利率
    ,
     'TR99' --定价基准类型
    ,
     '' --基准利率
    ,
     '99' --计息方式
    ,
     '' --利率浮动频率
    , NVL(A.CUST_NAM, T.CUST_ID)  --客户名称
FROM SMTMODS.L_ACCT_FUND_MMFUND T
LEFT JOIN SMTMODS.L_CUST_ALL A
on t.cust_id  =a.cust_id
and   A.DATA_DATE = IS_DATE
/*LEFT JOIN CUST_TY A
ON T.CUST_ID = A.CUST_ID
LEFT JOIN CUST_TY B
ON T.CUST_ID = B.ID_NO*/
WHERE T.DATA_DATE=IS_DATE
--and substr(T.gl_item_code,'1','3') in ('241','120')
      and substr(T.gl_item_code, '1', '4') in
           ('2003' --拆入资金
           ,
            '1302') --拆出资金
and

(TO_CHAR(mature_date, 'YYYYMMDD') >= IS_DATE

           or ref_num in
           (select ref_num
                  FROM SMTMODS.L_TRAN_FUND_FX t
                /*LEFT JOIN L_TY_CUSTID_INFO@SUPER f
                ON T.CUST_ID=F.CUST_NM*/
                 WHERE DATA_DATE = IS_DATE
                      --and substr(ITEM_CD,'1','3') in ('241','120')
                   and substr(ITEM_CD, '1', '4') in
                       ('2003' --拆入资金
                       ,
                        '1302') --拆出资金
                   AND AMOUNT IS NOT NULL
                   and AMOUNT <> 0
                   and CURR_CD IN ('CNY', 'USD', 'JPY', 'EUR', 'HKD')
                   and TO_CHAR(MATURITY_DT, 'YYYYMMDD') >= IS_DATE
                   and t.tran_dt = to_date(IS_DATE, 'YYYYMMDD')))

and T.CURR_CD IN ('CNY','USD','JPY','EUR','HKD')
--AND T.ORG_NUM NOT LIKE '0215%'
;
  COMMIT;

  ----当前数据日期新增的同业存款业务的客户及金融机构类型代码  且在同业客户信息表也取不到的同业客户 add by chm 20231012

  INSERT INTO TX_JRJG_DIF_JD
    SELECT DISTINCT CUST_NAM, ORGTPCODE
      FROM (SELECT A.CUST_NAME AS CUST_NAM, --客户号
                   NVL(NVL(B.JRJG, TRIM(C.FINA_CODE_NEW)), A.ORGTPCODE) AS ORGTPCODE, --金融机构类型代码
                   CONTRACTNUM --业务编码
              FROM DATACORE_IE_TY_TYJDJC A
              LEFT JOIN DATACORE_TMP_TX_JRJG_JD B
                ON A.CUST_NAME = B.CUST_ID
              LEFT JOIN L_CUST_BILL_TY_TMP C
                ON A.CUST_NAME = C.FINA_ORG_NAME
             WHERE A.CORPID NOT LIKE '5100%'
               AND A.DATADATE = VS_TEXT
               AND NOT EXISTS (SELECT 1
                      FROM L_CUST_BILL_TY_TMP B
                     WHERE A.CUST_NAME = B.FINA_ORG_NAME)
               AND NOT EXISTS (SELECT 1
                      FROM DATACORE_TMP_TX_JRJG_JD B
                     WHERE A.CUST_NAME = B.CUST_ID))
    MINUS
    SELECT *
      FROM TX_JRJG_YESTERDAY_JD;

   COMMIT;
SP_IRS_PARTITIONS(IS_DATE,'IE_TY_TYJDJC',OI_RETCODE);

INSERT INTO  IE_TY_TYJDJC
    (datadate --数据日期
    ,
     corpid --内部机构号
    ,
     custid --客户号
    ,
     orgtpcode --金融机构类型代码
    ,
     contractnum --业务编码
    ,
     finaloantype --借贷业务类型
    ,
     startdate --起始日期
    ,
     maturedate --到期日期
    ,
     actualduedate --实际终止日期
    ,
     finatermtype --同业借贷期限类型
    ,
     ratetype --利率类型
    ,
     realrate --实际利率
    ,
     finapricingtype --借贷定价基准类型
    ,
     baserate --基准利率
    ,
     intratemeth --计息方式
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

    select datadate --数据日期
          ,
           corpid --内部机构号
          ,
           a.CUSTID --客户号   add by chm 20231012 业务手动补录金融机构类型代码  20240909    NR表加工需要客户号，对数据进行提取，此前这个字段存的是交易对手客户名称
          ,
           CASE
             WHEN D.CUST_NAM IS NOT NULL THEN
              '空'
             ELSE
              NVL(B.JRJG, TRIM(C.FINA_CODE_NEW))
           END --金融机构类型代码 MDF BY CHM 20231012
          ,
           contractnum --业务编码
          ,
           finaloantype --借贷业务类型
          ,
           startdate --起始日期
          ,
           maturedate --到期日期
          ,
           actualduedate --实际终止日期
          ,
           CASE
             WHEN finatermtype < 1 then
              '01'
             WHEN finatermtype = '1' then
              '02'
             WHEN finatermtype < 3 then
              '03'
             WHEN finatermtype = '3' then
              '04'
             WHEN finatermtype < 6 then
              '05'
             WHEN finatermtype = '6' then
              '06'
             WHEN finatermtype < 12 then
              '07'
             WHEN finatermtype = '12' then
              '08'
             WHEN finatermtype < 24 then
              '09'
             WHEN finatermtype = '24' then
              '10'
             WHEN finatermtype < 36 then
              '11'
             WHEN finatermtype = '36' then
              '12'
             WHEN finatermtype < 60 then
              '13'
             WHEN finatermtype = '60' then
              '14'
             WHEN finatermtype > 60 then
              '15'
             ELSE
              NULL
           END --同业借贷期限类型
          ,
           ratetype --利率类型
          ,
           realrate --实际利率
          ,
           finapricingtype --借贷定价基准类型
          ,
           baserate --基准利率
          ,
           intratemeth --计息方式
          ,
           floatfreq --利率浮动频率
          ,
           IS_DATE --采集日期
          ,
           corpid --内部机构号
          ,
           '99' --业务条线
,CASE WHEN CORPID LIKE '51%' THEN '510000'
          WHEN CORPID LIKE '52%' THEN '520000'
          WHEN CORPID LIKE '53%' THEN '530000'
          WHEN CORPID LIKE '54%' THEN '540000'
          WHEN CORPID LIKE '55%' THEN '550000'
          WHEN CORPID LIKE '56%' THEN '560000'
          WHEN CORPID LIKE '57%' THEN '570000'
          WHEN CORPID LIKE '58%' THEN '580000'
          WHEN CORPID LIKE '59%' THEN '590000'
          WHEN CORPID LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
from DATACORE_IE_TY_TYJDJC a
      LEFT JOIN DATACORE_TMP_TX_JRJG_JD B
       ON A.CUST_NAME=B.CUST_ID
LEFT JOIN L_CUST_BILL_TY_TMP C  --ADD BY CHM 20230615  同业拆借业务表客户号值是交易对手名称
 ON A.CUST_NAME = C.FINA_ORG_NAME
      LEFT JOIN TX_JRJG_DIF_JD D --ADD BY CHM 20231012 新增同业客户，呈现在应用端，业务手动补录金融机构类型代码
        ON A.CUST_NAME = D.CUST_NAM ;

COMMIT;

---待上游修改后，去掉 20230504
update ie_ty_tyjdjc a
     set contractnum = 'LT2023032100088'
     where cjrq = IS_DATE
     and contractnum = 'LT2023020400011';

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
    SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, VS_TEXT, IS_DATE);
END;
/

