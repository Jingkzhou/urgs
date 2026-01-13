CREATE OR REPLACE PROCEDURE BSP_SP_IRS_PJ_PJTXYE(IS_DATE    IN VARCHAR2,
                                                OI_RETCODE OUT INTEGER,
                                               OI_RETCODE2 OUT VARCHAR2) AS
  ------------------------------------------------------------------------------------------------------
  -- 程序名
  --    SP_IRS_PJ_PJTXYE
  -- 用途:生成接口表 JS_201_CLGRDK 存量个人贷款信息
  -- 参数
  --    IS_DATE 输入变量，传入跑批日期
  --    OI_RETCODE 输出变量，用来标识存储过程执行过程中是否出现异常
  --    CAEATE BY USER AT 20200819
  --    MOD BY YANLINGBO AT 20200819
  ------------------------------------------------------------------------------------------------------

  VI_ERRORCODE      NUMBER DEFAULT 0; --数值型  异常代码
  VS_TEXT           VARCHAR2(500) DEFAULT NULL; --字符型  过程描述
  /*VS_LAST_TEXT      VARCHAR2(10) DEFAULT NULL; --字符型  过程描述*/
  VS_OWNER          VARCHAR2(32) DEFAULT NULL; --字符型  存储过程调用用户
  VS_PROCEDURE_NAME VARCHAR2(32) DEFAULT NULL; --字符型  存储过程名称
  VS_STEP           VARCHAR2(10); --存储过程执行步骤标志
/*  NUM               INTEGER;*/
  VS_LAST_TEXT      VARCHAR2(500) DEFAULT NULL; --字符型  过程描述

BEGIN
   VS_TEXT:= TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD'), 'YYYY-MM-DD');
  /*VS_LAST_TEXT := TO_CHAR(LAST_DAY(ADD_MONTHS(TO_DATE(IS_DATE, 'YYYYMMDD'), -1)),'YYYYMMDD'); --上月月末*/
  VS_LAST_TEXT := TO_CHAR(TO_DATE(IS_DATE, 'YYYYMMDD')-1, 'YYYYMMDD');
  -- 记录日志使用
  SELECT T.USERNAME INTO VS_OWNER FROM SYS.USER_USERS T;
  VS_PROCEDURE_NAME := 'SP_IRS_PJ_PJTXYE';
  -- 开始日志
  VS_STEP := 'START';
  SP_IRS_LOG(VS_PROCEDURE_NAME, VS_STEP, VI_ERRORCODE, IS_DATE, IS_DATE);
  -------------------------------------------------------------------------
  /*--删除当天日志
 DELETE FROM RUN_STEP_LOG WHERE TAB_NAME = 'IE_PJ_PJTXYE' and to_char(RUN_TIME,'yyyymmdd')=to_char(sysdate,'yyyymmdd');
  COMMIT;*/
 --创建分区
 /*SELECT COUNT(1)
    INTO NUM
    FROM USER_TAB_PARTITIONS
   WHERE TABLE_NAME = 'IE_PJ_PJTXYE'
     AND PARTITION_NAME = 'IE_PJ_PJTXYE_' || IS_DATE;*/

/*  --如果没有建立分区，则增加分区
  IF (NUM = 0) THEN
    EXECUTE IMMEDIATE 'ALTER TABLE datacore.IRS_GRDKYEXXB ADD PARTITION IRS_GRDKYEXXB_' ||
                      IS_DATE || ' VALUES (' || IS_DATE || ')';
  END IF;

  EXECUTE IMMEDIATE 'ALTER TABLE datacore.IRS_GRDKYEXXB TRUNCATE PARTITION IRS_GRDKYEXXB_' ||
                    IS_DATE;
*/

  /*INSERT INTO RUN_STEP_LOG VALUES (1, 'IE_PJ_PJTXYE', '', SYSDATE);
  COMMIT;*/


/*  EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_PJ_PJTXYE_TMP1';
INSERT INTO DATACORE_IE_PJ_PJTXYE_TMP1
 SELECT DISTINCT CUST_ID
 FROM SMTMODS.L_CUST_P
 WHERE DATA_DATE =IS_DATE
 AND ORG_NUM NOT LIKE '0215%';
 COMMIT;
 INSERT INTO DATACORE_IE_PJ_PJTXYE_TMP1
 SELECT DISTINCT CUST_ID
 FROM SMTMODS.L_CUST_C
 WHERE DATA_DATE =IS_DATE
 AND ORG_NUM NOT LIKE '0215%';
 COMMIT;*/

 EXECUTE IMMEDIATE 'TRUNCATE TABLE DATACORE_IE_PJ_PJTXYE';
 EXECUTE IMMEDIATE 'TRUNCATE TABLE L_ACCT_LOAN_LAST2';


--前一天的借据表信息
INSERT INTO L_ACCT_LOAN_LAST2
  SELECT /* +parallel(8)*/
   data_date, 
acct_num, 
loan_num, 
book_type, 
acct_typ, 
cust_id, 
curr_cd, 
acct_sts, 
org_num, 
drawdown_dt, 
drawdown_amt, 
maturity_dt, 
finish_dt, 
fund_use_loc_cd, 
loan_grade_cd, 
loan_purpose_cd, 
actual_maturity_dt, 
int_rate_typ, 
base_int_rat, 
drawdown_base_int_rat, 
real_int_rat, 
drawdown_real_int_rat, 
rate_float, 
loan_acct_bal, 
guaranty_typ, 
loan_buy_int, 
in_drawdown_dt, 
od_flg, 
extendterm_flg, 
loan_kind_cd, 
loan_business_typ, 
onlending_usage, 
resched_flg, 
loan_resched_dt, 
orig_acct_no, 
od_loan_acct_bal, 
od_int, 
od_int_obs, 
security_amt, 
ppl_repay_freq, 
int_repay_freq, 
od_days, 
p_od_dt, 
i_od_dt, 
loan_acct_num, 
pay_acct_num, 
repay_typ, 
draft_nbr, 
item_cd, 
independence_pay_amt, 
entrust_pay_amt, 
accu_int_flg, 
accu_int_amt, 
general_reserve, 
sp_prov_amt, 
special_prov_amt, 
useofunds, 
indust_rstruct_flg, 
indust_tran_flg, 
indust_stg_type, 
low_risk_flag, 
name, 
emp_id, 
security_rate, 
security_curr, 
security_acct_num, 
loan_fhz_num, 
repay_channel, 
next_int_pay_dt, 
next_repricing_dt, 
loan_stocken_date, 
loan_capitalize_typ, 
lyl_detail, 
loan_spp_typ, 
accu_comp_int, 
comp_int_amt, 
comp_int_flg, 
jobless_typ, 
entrust_purpose_cd, 
int_adjest_amt, 
housmort_loan_typ, 
bill_tran_typ, 
pay_cusid, 
year_int_incom, 
contracted_guar_typ, 
farmer_house_guar_typ, 
contracted_land_typ, 
farmer_house_typ, 
append_date, 
pricing_base_type, 
poverty_alle, 
corp_code, 
linkage_type, 
linkage_mode, 
oversea_ann_loan_flag, 
orig_term_type, 
orig_term, 
loan_purpose_area, 
poc_index_code, 
cancel_flg, 
gur_mort_flg, 
agent_id, 
drawdown_type, 
value_date, 
repay_term_num, 
current_term_num, 
cumulate_term_num, 
consecute_term_num, 
undertak_guar_type, 
generalize_loan_flg, 
campus_consu_loan_flg, 
tax_related_flg, 
renew_flg, 
busi_maintain_channels, 
green_loan_type, 
is_repay_options, 
poverty_loan_flg, 
loan_account_type, 
float_type, 
loan_sell_int, 
business_nam, 
plat_flg, 
is_first_loan_tag, 
repay_flg, 
is_first_report_loan_tag, 
comp_int_typ, 
ass_sec_pro_type, 
resched_end_dt, 
circle_loan_flg, 
int_rate_2019, 
non_compense_bal_rmb, 
loan_purpose_country, 
internet_loan_flg, 
loan_sts, 
int_rate_typ2, 
busi_channel, 
consump_scen_flg, 
analog_crecard_flg, 
loan_ratio, 
departmentd, 
date_sourcesd, 
pay_type, 
od_int_ygz, 
remark, 
loan_acct_bank, 
loan_acct_name, 
int_num_date, 
discount_interest, 
acct_sts_desc, 
acct_typ_desc, 
pay_acct_bank, 
green_loan_flg, 
loan_num_old, 
repay_typ_desc, 
int_repay_freq_desc, 
drawdown_type_new, 
loan_purpose_country_new, 
defit_inrat, 
maturity_dt_before, 
draft_rng, 
mk_val, 
reprice_period, 
jbyg_id, 
szyg_id, 
spyg_id, 
fxll, 
czcs, 
fksj, 
jxfs, 
sqy_id, 
czb, 
grxfdkyt, 
if_ct_ua, 
city_type, 
qtdbfs1, 
qtdbfs2, 
hzf_security_rate, 
hzf_security_curr, 
hzf_security_acct_num
    FROM SMTMODS.L_ACCT_LOAN T
   where t.data_date = VS_LAST_TEXT
     and (ITEM_CD IN ('13010101', '13010104') --以摊余成本计量的贴现
         OR ITEM_CD IN ('13010401', '13010405') --以公允价值计量变动计入权益的贴现
         OR ITEM_CD IN ('13010201', '13010204') --以摊余成本计量的转贴现
         OR ITEM_CD IN ('13010501', '13010505'));



  INSERT INTO DATACORE_IE_PJ_PJTXYE
  (
         datadate,           --1数据日期
         corpid,             --2内部机构号
         custid,             --3客户号
         contractnum,        --4业务编码
         moneysymb,          --5币种
         balance            --6余额

 )
   SELECT T.DATA_DATE, --数据日期
   T.ORG_NUM, --机构号
       T.CUST_ID, --客户号
       T.LOAN_NUM, --贷款编号  （业务编码）
       T.CURR_CD, --币种
       T.LOAN_ACCT_BAL --贷款余额
  FROM SMTMODS.L_ACCT_LOAN T
  LEFT JOIN L_ACCT_LOAN_LAST2 D
  ON T.LOAN_NUM = D.LOAN_NUM
  /*INNER JOIN DATACORE_IE_PJ_PJTXYE_TMP1 T1
        ON T.CUST_ID=T1.CUST_ID
*/
  /*INNER JOIN CUST_0215 E
          ON T.CUST_ID = E.CUST_ID*/
    WHERE T.DATA_DATE=IS_DATE
    --AND T.ORG_NUM NOT LIKE '0215%'
    --and item_cd in ('12901', '12905', '12902', '12906')
    AND (T.ITEM_CD IN ('13010101','13010104')       --以摊余成本计量的贴现
    OR T.ITEM_CD IN ('13010401','13010405')       --以公允价值计量变动计入权益的贴现
    OR T.ITEM_CD IN ('13010201','13010204')       --以摊余成本计量的转贴现
    OR T.ITEM_CD IN ('13010501','13010505'))       --以公允价值计量变动计入权益的转贴现    20240906  修改取数范围
   -- AND (T.LOAN_ACCT_BAL > 0 OR TO_CHAR(T.FINISH_DT,'YYYYMMDD') = IS_DATE)
    AND ((T.LOAN_ACCT_BAL > 0 AND (TO_CHAR(T.FINISH_DT,'YYYYMMDD') IS NULL OR TO_CHAR(T.FINISH_DT,'YYYYMMDD') > IS_DATE))
    OR ( TO_CHAR(T.DRAWDOWN_DT, 'YYYY-MM-DD')= VS_TEXT AND T.LOAN_ACCT_BAL = 0)) --add by chm 20230428 取入当天发生但余额为0的贴现，由于时点问题，有放款，未进余额
    --AND T.LOAN_ACCT_BAL > 0
    ;

COMMIT;


--20250121 存在周末票据结清的情况，余额在周一才会变为0，将结清数据的余额默认为0
INSERT INTO DATACORE_IE_PJ_PJTXYE
  (
         datadate,           --1数据日期
         corpid,             --2内部机构号
         custid,             --3客户号
         contractnum,        --4业务编码
         moneysymb,          --5币种
         balance            --6余额

 )
   SELECT T.DATA_DATE, --数据日期
   T.ORG_NUM, --机构号
       T.CUST_ID, --客户号
       T.LOAN_NUM, --贷款编号  （业务编码）
       T.CURR_CD, --币种
       --T.LOAN_ACCT_BAL --贷款余额
       '0' --贷款余额
  FROM SMTMODS.L_ACCT_LOAN T
  LEFT JOIN L_ACCT_LOAN_LAST2 D
  ON T.LOAN_NUM = D.LOAN_NUM
  /*INNER JOIN DATACORE_IE_PJ_PJTXYE_TMP1 T1
        ON T.CUST_ID=T1.CUST_ID
*/
  /*INNER JOIN CUST_0215 E
          ON T.CUST_ID = E.CUST_ID*/
    WHERE T.DATA_DATE=IS_DATE
    --AND T.ORG_NUM NOT LIKE '0215%'
    --and item_cd in ('12901', '12905', '12902', '12906')
    AND (T.ITEM_CD IN ('13010101','13010104')       --以摊余成本计量的贴现
    OR T.ITEM_CD IN ('13010401','13010405')       --以公允价值计量变动计入权益的贴现
    OR T.ITEM_CD IN ('13010201','13010204')       --以摊余成本计量的转贴现
    OR T.ITEM_CD IN ('13010501','13010505'))       --以公允价值计量变动计入权益的转贴现    20240906  修改取数范围
   -- AND (T.LOAN_ACCT_BAL > 0 OR TO_CHAR(T.FINISH_DT,'YYYYMMDD') = IS_DATE)
    AND TO_CHAR(T.FINISH_DT,'YYYYMMDD') = IS_DATE OR ((TO_CHAR(T.FINISH_DT,'YYYYMMDD') IS NULL OR TO_CHAR(T.FINISH_DT,'YYYYMMDD') > IS_DATE)
    AND T.LOAN_ACCT_BAL = 0 AND D.LOAN_ACCT_BAL <> 0   --20241016   结清余额为0，但是没有结清日期，对比前一天的余额
    AND T.ACCT_STS = '3')    --账户状态为结清
    --AND T.LOAN_ACCT_BAL > 0
    ;

SP_IRS_PARTITIONS(IS_DATE,'IE_PJ_PJTXYE',OI_RETCODE);
    INSERT INTO IE_PJ_PJTXYE
  (
    DATADATE,   --1数据日期
    CORPID,     --2内部机构号
    CUSTID,     --3客户号
    CONTRACTNUM,   --4业务编码
    MONEYSYMB,     --5币种
    BALANCE,       --6余额
    CJRQ,          --7采集日期
    NBJGH,         --8内部机构号
    /*REPORT_ID,     --9报送ID*/
    BIZ_LINE_ID,   --10业务条线
    VERIFY_STATUS, --11校验状态
    BSCJRQ,        --12报送周期
    IRS_CORP_ID    --13法人机构ID
    )
    SELECT VS_TEXT AS DATADATE,           --1数据日期
           CORPID,             --2内部机构号
           CUSTID,             --3客户号
           CONTRACTNUM,        --4业务编码
           MONEYSYMB,          --5币种
           BALANCE,            --6余额
           IS_DATE AS CJRQ,    --7采集日期
           CORPID AS NBJGH,    --8内部机构号
           '99' AS BIZ_LINE_ID, --10业务条线
           '' AS VERIFY_STATUS, --11校验状态
           '' AS  BSCJRQ,       --12报送周期
           CASE WHEN  CORPID LIKE '51%' THEN '510000'
          WHEN  CORPID LIKE '52%' THEN '520000'
          WHEN  CORPID LIKE '53%' THEN '530000'
          WHEN  CORPID LIKE '54%' THEN '540000'
          WHEN  CORPID LIKE '55%' THEN '550000'
          WHEN  CORPID LIKE '56%' THEN '560000'
          WHEN  CORPID LIKE '57%' THEN '570000'
          WHEN  CORPID LIKE '58%' THEN '580000'
          WHEN  CORPID LIKE '59%' THEN '590000'
          WHEN  CORPID LIKE '60%' THEN '600000'
           ELSE '990000' END  --法人机构ID
     FROM IRS_DATACORE.DATACORE_IE_PJ_PJTXYE
     WHERE DATADATE = IS_DATE ;
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

