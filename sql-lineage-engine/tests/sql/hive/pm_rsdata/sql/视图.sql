CREATE VIEW pm_rsdata.cbrc_g53_jg_view AS select subquery_target_41.bank_id, subquery_target_41.bank_name, subquery_target_41.bank_rel, subquery_target_41.lx from (select T.bank_id, T.bank_name, T1.BANK_REL, CASE WHEN T1.BANK_REL LIKE '06%' THEN '县辖' ELSE '市辖' END LX --延边都是县辖



  from pm_rsdata.cbrc_BANK_BASIS  T--METABASE.cbrc_BANK_BASIS@pboc_49 T



 INNER JOIN pm_rsdata.cbrc_G5306_PBOC_BANK_RELATION  T1 --METABASE.bank_relation@pboc_49



    ON T.bank_id = T1.BANK_ID



 WHERE T.bank_name LIKE '%市辖%'



union all



--县辖：



select T.bank_id,



       T.bank_name,



       CASE



         WHEN T3.BANK_REL IS NOT NULL THEN



          T3.BANK_REL



         ELSE



          T.bank_id



       END BANK_REL,



       CASE WHEN NVL(T3.BANK_REL,T.BANK_ID) LIKE '0131%' THEN '市辖' --双阳属于市辖



         WHEN NVL(T3.BANK_REL,T.BANK_ID) LIKE '1005%' THEN '市辖' --大连开发区支行是市辖



         ELSE '县辖' END LX



  from pm_rsdata.cbrc_BANK_BASIS T --metabase.cbrc_BANK_BASIS@pboc_49



 INNER JOIN pm_rsdata.cbrc_BANK_BASIS T2 --metabase.cbrc_BANK_BASIS@pboc_49



    ON T.BANK_SUPERIOR = T2.BANK_SUPERIOR



   AND T2.bank_name LIKE '%市辖%'



   and t2.bank_id <> '220100'



  LEFT JOIN --metabase.bank_relation@pboc_49



  pm_rsdata.cbrc_G5306_PBOC_BANK_RELATION T3



    ON T.bank_id = T3.BANK_ID



 WHERE T.bank_name NOT LIKE '%市辖%'



   and t.bank_id <> '201999'



UNION ALL



--公主岭，由于大集中机构里没有公主岭所以需要单独处理



select '013400', '吉林银行长春公主岭支行', '013400', '县辖' from system.dual



UNION ALL



select '012200', '吉林省长春市农安支行', '012200', '县辖' from system.dual



UNION ALL



select '012300', '吉林省长春市榆树支行', '012300', '县辖' from system.dual



UNION ALL



select '013600', '吉林省长春市德惠振兴街支行', '013600', '县辖' from system.dual ) subquery_target_41;

CREATE VIEW pm_rsdata.cbrc_v_pub_fund_invest AS SELECT DATA_DATE,

       ORG_NUM,

       ACCT_NUM,

       CUST_ID,

       INVEST_ID,

       CONTRACT_NO,

       REF_NUM,

       BOOK_TYPE,

       DEAL_TYPE,

       SUBJECT_CD,

       INVEST_TYP,

       ACCOUNTANT_TYPE,

       FIN_ASSETS_TYPE,

       IN_OFF_FLG,

       CURR_CD,

       TX_DATE,

       NVL(T1.LASTDAY, T.MATURITY_DATE) AS MATURITY_DATE,

       FACE_VAL,

       INT_ADJEST_AMT,

       MK_VAL,

       COST_HIS,

       ACCRUAL,

       REAL_INT_RAT,

       TX_REAL_INT_RAT,

       NEXT_RATE_DATE,

       REPRICE_DT,

       SECURITY_CURR,

       SECURITY_AMT,

       PREPARATION,

       GRADE,

       IS_INTEREST,

       REAL_ESTATE_FLG,

       UNSTANDARD_FLG,

       LIQUID_AMT,

       GL_ITEM_CODE,

       DURATION,

       MODIFY_TERM,

       WRITEOFF_AMT,

       WRITEOFF_DT,

       ATM,

       STORCK_OWN_REASON,

       INDUS_FUND_FACE_VAL,

       DEBT_EAUITY_FUND_FACE_VAL,

       FACILITY_NO,

       FINISH_DT,

       STOCK_MARK,

       OUTSOURCE_INVESTMENT_FLG,

       OD_FLG,

       OD_LOAN_ACCT_BAL,

       OD_INT,

       OD_DAYS,

       P_OD_DT,

       I_OD_DT,

       AGENT_ID,

       MANAGEMENT_TYPE,

       UNDERTAK_GUAR_TYPE,

       GENERALIZE_LOAN_FLG,

       SPV_PRODUCT_TYPE,

       BUSI_MAINTAIN_CHANNELS,

       USEOFUNDS,

       LOAN_PURPOSE_CD,

       FUND_USE_LOC_CD,

       LOAN_PURPOSE_AREA,

       REPO_BUSI_TYPE,

       GUARANTY_TYP,

       UNDER_DEBT_BAL,

       ISSUE_TYPE,

       UNCERTAIN_TERM_FLAG,

       PRICING_BASE_TYPE,

       IS_REPAY_OPTIONS,

       POSTION_TYPE,

       FORRIGN_ASSETS_FLG,

       PRODUCT_NAME,

       EQUITY_FLAG,

       CHECKER_NAME,

       TRADER_ID,

       PRINCIPAL_BALANCE,

       CREDIT_RISK_WEIGHT,

       DEP,

       INT_RATE_TYP,

       IS_FIRST_LOAN_FLG,

       COLLECT_AMT,

       IS_LEVEL,

       PIERCED_TYPE,

       BASE_INT_RAT,

       IS_FIRST_REPORT_LOAN_TAG,

       OPPO_CUST_ID,

       EXTENDTERM_FLG,

       STANDARDIZED_NOTE_FLG,

       OTHER_DEBT_TYPE,

       DEPARTMENTD,

       DATE_SOURCESD,

       THISMONTH_DIVIDEND_INTEREST,

       LOAN_ACCT_NUM,

       EMP_ID,

       REMARK,

       INT_NUM_DATE,

       REDISCOUNT_INTEREST,

       LOAN_ACCT_BANK,

       LOAN_ACCT_NAME,

       PAY_ACCT_NUM,

       PAY_ACCT_BANK,

       ACCT_STS,

       ACCT_STS_DESC,

       LOAN_PURPOSE_COUNTRY,

       TOTAL_INCOME,

       NVL(T1.LASTDAY, T.MATURITY_DATE) -DATA_DATE AS DC_DATE,

       COLL_AMT,

       ZD_NET_AMT,

       ACCT_BAL,

       CYCB,

       JBYG_ID,

       SZYG_ID,

       SPYG_ID,

       JXFS,

       JTDS_ID,

       JYDSMC,

       JYDSZH,

       JYDSHH,

       OD_INT_OBS,

       JJ,

       QJ,

       QTYSK,

       POWER_DAY,

       CMS_AST_TYPE,

       ACCT_NO,

       CONTRACT_NUM

  FROM pm_rsdata.SMTMODS_L_ACCT_FUND_INVEST T

  LEFT JOIN (SELECT T.HOLIDAY_DATE ,

                    MIN(T1.HOLIDAY_DATE) LASTDAY,

                    T.DATA_DATE AS DATADATE

               FROM pm_rsdata.SMTMODS_L_PUBL_HOLIDAY T

               LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE

                           FROM pm_rsdata.SMTMODS_L_PUBL_HOLIDAY T

                          WHERE T.COUNTRY = 'CHN'

                            AND T.STATE = '220000'

                            AND T.WORKING_HOLIDAY = 'W' --工作日

                         ) T1

                 ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE

                AND T.DATA_DATE = T1.DATA_DATE

              WHERE T.COUNTRY = 'CHN'

                AND T.STATE = '220000'

                AND T.WORKING_HOLIDAY = 'H' --假日

                AND T.HOLIDAY_DATE <= T.DATA_DATE

              GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1

    ON T.MATURITY_DATE = T1.HOLIDAY_DATE

   AND T.DATA_DATE = T1.DATADATE;

CREATE VIEW pm_rsdata.cbrc_v_pub_fund_mmfund AS SELECT DATA_DATE,



       ORG_NUM,



       CUST_ID,



       ACCT_NUM,



       REF_NUM,



       BOOK_TYP,



       CURR_CD,



       ACCT_TYP,



       START_DATE,



       CASE



         WHEN T.DATE_SOURCESD LIKE '%康星%' THEN



          NVL(T1.LASTDAY, T.MATURE_DATE)



         ELSE



          T.MATURE_DATE



       END AS MATURE_DATE,



       REAL_INT_RAT,



       TX_REAL_INT_RAT,



       ACCRUAL,



       NEXT_RATE_DATE,



       REPRICE_DT,



       AMT,



       BALANCE,



       OVERDUE_P,



       OVERDUE_I,



       CBRC_GRADE,



       GUAR_AMT,



       GUAR_ACURR,



       PRE_SPE,



       SPECIAL_PREP,



       GENERAL_RESERVE,



       IS_INTEREST,



       AGENT_FLG,



       BILL_NUM,



       FOREIGN_EX_RESERVE_FLG,



       INTERBANK_DEPOSIT_FLG,



       GL_ITEM_CODE,



       ACCT_OPDATE,



       OPEN_TELLER,



       ACCT_CLDATE,



       ACCT_STS,



       LAST_TX_DATE,



       STABLE_RISK_TYPE,



       BUS_REL,



       IS_COLL_FLG,



       PLEDGE_ASSETS_TYPE,



       PLEDGE_ASSETS_VAL,



       IS_INLINE_OPTIONS,



       ADVANCE_DRAW_FLG,



       INTERBANK_TYPE,



       STOCK_PLEDGE_FLAG,



       OVERDRAFT_FLAG,



       SPECIAL_FLG,



       PRICING_BASE_TYPE,



       BREAK_EVEN_FINANCIAL,



       BUS_REL_BAL,



       OUTSOURCE_INVESTMENT_FLG,



       POC_INDEX_CODE,



       DEPOSIT_TERM_FLG,



       CALL_DEPOSIT_DATE,



       UNCERTAIN_TERM_FLAG,



       FORRIGN_ASSETS_FLG,



       PRODUCT_NAME,



       CHECKER_NAME,



       TRADER_ID,



       CREDIT_RISK_WEIGHT,



       O_ACCT_NUM,



       OTH_ACCT_TYPE,



       DEP,



       LOAN_FLG,



       DEP_ACC_CODE,



       BASE_INT_RAT,



       ACC_INT_TYPE,



       RESERVE_DEPO_TYPE,



       INT_RATE_TYP,



       LOAN_ACTUAL_DUE_DATE,



       OPEN_CHANNEL,



       REMOTE_DEP_FLG,



       DEPARTMENTD,



       DATE_SOURCESD,



       LXSZ,



       ACCT_STATE_DES,



       CURRENT_MONTH_NET_AMT,



       TOTAL_INCOME,



       INT_NUM_DATE,



       REDISCOUNT_INTEREST,



       INTEREST_ACCURED,



       COLLECT_ACCT_NO,



       TZBD_ID,



       BQTZSY,



       LJTZSY,



       JBYG_ID,



       SZYG_ID,



       SPYG_ID,



       YWMD,



       CHLB,



       OD_LOAN_ACCT_BAL,



       OD_INT_OBS,



       P_OD_DT,



       I_OD_DT,



       JYDSTYDM,



       CJDBH,



       ZD_NET_AMT



  FROM pm_rsdata.smtmods_L_ACCT_FUND_MMFUND T



  LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,



                    MIN(T1.HOLIDAY_DATE) LASTDAY,



                    T.DATA_DATE AS DATADATE



               FROM pm_rsdata.smtmods_L_PUBL_HOLIDAY T



               LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE



                           FROM pm_rsdata.smtmods_L_PUBL_HOLIDAY T



                          WHERE T.COUNTRY = 'CHN'



                            AND T.STATE = '220000'



                            AND T.WORKING_HOLIDAY = 'W' --工作日



                         ) T1



                 ON  T.DATA_DATE = T1.DATA_DATE



      AND T.HOLIDAY_DATE < T1.HOLIDAY_DATE







              WHERE T.COUNTRY = 'CHN'



                AND T.STATE = '220000'



                AND T.WORKING_HOLIDAY = 'H' --假日



                AND T.HOLIDAY_DATE <= T.DATA_DATE



      GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1



    ON T.MATURE_DATE = T1.HOLIDAY_DATE



   AND T.DATA_DATE = T1.DATADATE;

CREATE VIEW pm_rsdata.cbrc_v_pub_fund_repurchase AS SELECT DATA_DATE,



       ORG_NUM,



       CUST_ID,



       ACCT_NUM,



       FACILITY_NO,



       REF_NUM,



       BOOK_TYPE,



       CURR_CD,



       BUSI_TYPE,



       ASS_TYPE,



       SUBJECT_CD,



       DEAL_TYPE,



       ATM,



       BALANCE,



       ACCRUAL,



       NEXT_RATE_DATE,



       BEG_DT,



       NVL(T1.LASTDAY, T.END_DT) AS END_DT,



       NEXT_RATE_DT,



       GRADE,



       SECURITY_CURR,



       SECURITY_AMT,



       PRE_SPE,



       SPECIAL_PREP,



       GENERAL_RESERVE,



       IS_INTEREST,



       PLEDGE_ASSETS_TYPE,



       MOR_AMT,



       IS_COLL,



       GL_ITEM_CODE,



       NET_SETTLE_CD,



       AGREE_VAL,



       HE,



       HC,



       HFX,



       WRITEOFF_AMT,



       WRITEOFF_DT,



       REAL_INT_RAT,



       TX_REAL_INT_RAT,



       PRICING_BASE_TYPE,



       IS_REPAY_OPTIONS,



       PRODUCT_NAME,



       ACCT_CLDATE,



       OVERDUE_P,



       OVERDUE_I,



       CHECKER_NAME,



       TRADER_ID,



       CREDIT_RISK_WEIGHT,



       DEP,



       INT_RATE_TYP,



       IS_FIRST_LOAN_FLG,



       IS_FIRST_REPORT_LOAN_TAG,



       USEOFUNDS,



       ACC_INT_TYPE,



       BASE_INT_RAT,



       LOAN_ACTUAL_DUE_DATE,



       IS_SPECIAL_LOAN,



       BUSI_CHANNEL,



       DEPARTMENTD,



       DATE_SOURCESD,



       MON_INT_INCOM,



       TOTAL_INCOME,



       OUT_FUND_STATUS,



       REMARK,



       INT_NUM_DATE,



       PUR_RATE,



       PUR_INT,



       REDISCOUNT_INTEREST,



       LOAN_PURPOSE_COUNTRY,



       LOAN_PURPOSE_AREA,



       LOAN_ACCT_NUM,



       LOAN_ACCT_BANK,



       LOAN_ACCT_NAME,



       PAY_ACCT_NUM,



       PAY_ACCT_BANK,



       P_OD_DT,



       I_OD_DT,



       INTEREST_ACCURED,



       CUST_SHORT_NAME,



       NVL(T1.LASTDAY, T.END_DT) - DATA_DATE AS DC_DATE,



       DEAL_ACCT_NUM,



       JBYG_ID,



       SZYG_ID,



       SPYG_ID,



       YWMD,



       BQTZSY,



       OD_LOAN_ACCT_BAL,



       OD_INT_OBS,



       JYDSMC,



       JYDSDM,



       CONTRACT_AMT,



       VALUE_DATE







  FROM pm_rsdata.SMTMODS_L_ACCT_FUND_REPURCHASE T



  LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,



                    MIN(T1.HOLIDAY_DATE) LASTDAY,



                    T.DATA_DATE AS DATADATE



               FROM pm_rsdata.SMTMODS_L_PUBL_HOLIDAY T



               LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE



                           FROM pm_rsdata.SMTMODS_L_PUBL_HOLIDAY T



                          WHERE T.COUNTRY = 'CHN'



                            AND T.STATE = '220000'



                            AND T.WORKING_HOLIDAY = 'W' --工作日



                         ) T1



                 ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE



                AND T.DATA_DATE = T1.DATA_DATE



              WHERE T.COUNTRY = 'CHN'



                AND T.STATE = '220000'



                AND T.WORKING_HOLIDAY = 'H' --假日



                AND T.HOLIDAY_DATE <= T.DATA_DATE



              GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1



    ON T.END_DT = T1.HOLIDAY_DATE



   AND T.DATA_DATE = T1.DATADATE;

CREATE VIEW pm_rsdata.fsd_jlbank_org_info_view AS SELECT T.INST_ID,

       T.INST_NAME,

       CASE

         WHEN T.INST_LAYER = '2' AND T.INST_ID NOT LIKE '%00'/*T.PARENT_INST_ID = '019900'*/ THEN

          T.INST_ID

         ELSE

          T.PARENT_INST_ID

       END AS PARENT_INST_ID,

       CASE

         WHEN T.INST_LAYER = '2' AND T.INST_ID NOT LIKE '%00' THEN

          3

         ELSE

          T.INST_LAYER

       END AS INST_LAYER

  FROM pm_rsdata.FSD_U_BASE_INST T

 WHERE ((T.INST_ID NOT LIKE '9%' AND T.INST_ID NOT LIKE '2%') OR

       T.INST_ID = '201999');

CREATE VIEW pm_rsdata.pisa_v_bank_relation_datacore AS select a.BANK_ID,a.BANK_REL,a.TOTAL_TYPE from (SELECT '220400' AS BANK_ID,



       '030300' AS BANK_REL,



       '100' AS TOTAL_TYPE  --撤并机构上游没有变更



  



UNION ALL



SELECT '220600' AS BANK_ID,



       '091400' AS BANK_REL,



       '100' AS TOTAL_TYPE   --撤并机构上游没有变更



 



UNION ALL



SELECT '990000' AS BANK_ID,



       '999999' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '51000000' AS BANK_ID,



       '51999999' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '52000000' AS BANK_ID,



       '52999999' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '53000000' AS BANK_ID,



       '53999999' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '54000000' AS BANK_ID,



       '54999999' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '55000000' AS BANK_ID,



       '55999999' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '56000000' AS BANK_ID,



       '56999999' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '57000000' AS BANK_ID,



       '57999999' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '58000000' AS BANK_ID,



       '58999999' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '59000000' AS BANK_ID,



       '59999999' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '60000000' AS BANK_ID,



       '60999999' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '51000000' AS BANK_ID,



       '510000' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '52000000' AS BANK_ID,



       '520000' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '53000000' AS BANK_ID,



       '530000' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '54000000' AS BANK_ID,



       '540000' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '55000000' AS BANK_ID,



       '550000' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '56000000' AS BANK_ID,



       '560000' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '57000000' AS BANK_ID,



       '570000' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '58000000' AS BANK_ID,



       '580000' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '59000000' AS BANK_ID,



       '590000' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



SELECT '60000000' AS BANK_ID,



       '600000' AS BANK_REL,



       '100' AS TOTAL_TYPE







UNION ALL



/*SELECT T.PARENT_INST_ID AS BANK_ID,



       T.INST_ID AS BANK_REL,



       '100' AS TOTAL_TYPE



  FROM PISA_U_BASE_INST T



 WHERE T.INST_ID LIKE '2%'



   AND T.INST_ID <> '201999'*/



   SELECT T.PARENT_INST_ID AS BANK_ID,



       T.INST_ID AS BANK_REL,



       '100' AS TOTAL_TYPE



  FROM pm_rsdata.PISA_U_BASE_INST T



 WHERE (T.INST_ID LIKE '2%' OR T.INST_ID LIKE '512%' OR



       T.INST_ID LIKE '523%' OR T.INST_ID LIKE '532%' OR



       T.INST_ID LIKE '542%' OR T.INST_ID LIKE '551%' OR



       T.INST_ID LIKE '561%' OR T.INST_ID LIKE '572%' OR



       T.INST_ID LIKE '582%' OR T.INST_ID LIKE '592%' OR



       T.INST_ID LIKE '602%')



   AND T.INST_ID <> '201999'







UNION ALL



SELECT DECODE(SUBSTR(T.INST_ID, 0, 2),



              '00',



              '220100',



              '01',



              '220100',



              '02',



              '220200',



              '07',



              '220300',



              '03',



              '220400',



              '04',



              '220500',



              '09',



              '220600',



              '05',



              '220700',



              '08',



              '220800',



              '06',



              '222400',



              '11',



              '210100',



              '10',



              '210200',



              '88',



              '220100',



              '13',



              '220100',



              '51',



              '51220200', -----51220200代表磐石村镇吉林市



              '52',



              '52321000',  -----52321000代表江都村镇扬州市



              '53',



              '53220200',  -----53220200代表舒兰村镇吉林市



              '54',



              '54220100',  -----54220100代表双阳村镇长春市



              '55',



              '55130900',  -----55130900代表沧县村镇沧州市



              '56',



              '56131000',  -----56131000代表江永清村镇廊坊市



              '57',



              '57222400',  -----57222400代表珲春村镇延边州



              '58',



              '58220300', -----58222400代表双辽村镇四平市



              '59',



              '59220400' ,-----59220400代表东丰村镇辽源市



              '60',



              '60220200' -----60220200代表蛟河村镇吉林市



              ) AS BANK_ID,



       T.INST_ID AS BANK_REL,



       '100' AS TOTAL_TYPE



  FROM pm_rsdata.PISA_U_BASE_INST T



 WHERE (T.INST_LAYER = '3' and



       t.inst_id not in ('013401', '013402', '013403', '013493')) --人行要求公主岭支行数据仍然汇总到四平分行，暂不汇总到长春分行



    OR (T.INST_ID NOT LIKE '%00' AND T.INST_LAYER = '2')



    union all



  select '220300' BANK_ID,--人行要求公主岭支行数据仍然汇总到四平分行



  i.inst_id as BANK_REL,



  '100' AS TOTAL_TYPE







   from pm_rsdata.PISA_U_BASE_INST i   where i.inst_id in('013401','013402','013403','013493') ) a;

CREATE VIEW pm_rsdata.smtmods_v_l_publ_org_bra AS SELECT







         t1.ORG_NUM AS ORG_NUM,







         t1.DATA_DATE AS DATA_DATE,







         t1.ORG_NAM AS ORG_NAM,







         COALESCE(TRIM( t1.FIN_LIN_NUM ),  TRIM( t2.FIN_LIN_NUM ),  TRIM( t3.FIN_LIN_NUM )) AS FIN_LIN_NUM,







         COALESCE( t1.BANK_CD, t2.BANK_CD, t3.BANK_CD) AS BANK_CD,







         CONCAT( substr( COALESCE( t1.FIN_LIN_NUM, t2.FIN_LIN_NUM, t3.FIN_LIN_NUM ), 1, 11 ), t1.ORG_NUM ) AS ORG_ID







    FROM pm_rsdata.smtmods_l_publ_org_bra t1







            LEFT JOIN pm_rsdata.smtmods_l_publ_org_bra t2 







              ON t1.UP_ORG_NUM = t2.ORG_NUM 







             AND t2.DATA_DATE = t1.DATA_DATE 







            LEFT JOIN pm_rsdata.smtmods_l_publ_org_bra t3







              ON t2.UP_ORG_NUM = t3.ORG_NUM







             AND t3.DATA_DATE = t1.DATA_DATE 







   WHERE t1.ORG_NUM <> '999999';

CREATE VIEW pm_rsdata.smtmods_v_pub_fund_cds_bal AS SELECT DATA_DATE,



       ORG_NUM,



       ACCT_NUM,



       CONT_PARTY_CODE,



       CDS_NO,



       BOOK_TYPE,



       PRODUCT_PROP,



       STOCK_NAM,



       STOCK_PRO_TYPE,



       CURR_CD,



       FACE_VAL,



       INTEREST_RECEIVABLE,



       INTEREST_PAYABLE,



       ISSU_DT,



       INT_ST_DT,



       NVL(T1.LASTDAY, T.MATURITY_DT) AS MATURITY_DT,



       MK_VAL,



       GL_ITEM_CODE,



       GRADE,



       PRICING_BASE_TYPE,



       DEPOSIT_TRANSFER_TYPE,



       RESERVE,



       ACCT_SAFE_BAL,



       STABLE_RISK_TYPE,



       DURATION,



       MODIFY_TERM,



       OPEN_TELLER,



       ACCT_CLDATE,



       ACCT_STS,



       LAST_TX_DATE,



       AMT,



       STAT_SUB_ID,



       INT_RAT,



       MMF_FLG,



       IS_INLINE_OPTIONS,



       DEAL_TYPE,



       POSTION_TYPE,



       REPRICE_DT,



       SUBJECT_CD,



       OVERDUE_P,



       OVERDUE_I,



       CHECKER_NAME,



       TRADER_ID,



       PRINCIPAL_BALANCE,



       CREDIT_RISK_WEIGHT,



       DEP,



       NEXT_RATE_DATE,



       IS_INTEREST,



       ISSUE_INLAND_FLG,



       RESERVE_DEPO_TYPE,



       BOOK_VALUE,



       DEP_AGR_CODE,



       DEPARTMENTD,



       DATE_SOURCESD,



       ACCT_STATE_DESC,



       CURRENT_MONTH_NET_AMT,



       TOTAL_INCOME,



       CONT_PARTY_NAME,



       CONT_PARTY_TYPE,



       INTEREST_ACCURED,



       REAL_MATURITY_DT,



       NVL(T1.LASTDAY, T.MATURITY_DT) - DATA_DATE AS DC_DATE,



       CP_ID,



       BQTZSY,



       CYCB,



       JBYG_ID,



       SZYG_ID,



       SPYG_ID,



       ACCOUNTANT_TYPE,



       TZGLFS,



       JTDS_ID,



       JYDSZH,



       JYDSHH,



       OD_LOAN_ACCT_BAL,



       OD_INT_OBS,



       P_OD_DT,



       I_OD_DT,



       JJ,



       QJ,



       CUST_ID,



       FIN_ASSETS_TYPE,



       COLL_AMT



  FROM pm_rsdata.smtmods_L_ACCT_FUND_CDS_BAL T



  LEFT JOIN (SELECT T.HOLIDAY_DATE HOLIDAY_DATE,



                    MIN(T1.HOLIDAY_DATE) LASTDAY,



                    T.DATA_DATE AS DATADATE



               FROM pm_rsdata.smtmods_L_PUBL_HOLIDAY T



               LEFT JOIN (SELECT T.HOLIDAY_DATE, T.DATA_DATE



                           FROM pm_rsdata.smtmods_L_PUBL_HOLIDAY T



                          WHERE T.COUNTRY = 'CHN'



                            AND T.STATE = '220000'



                            AND T.WORKING_HOLIDAY = 'W' --工作日



                         ) T1



                 ON T.HOLIDAY_DATE < T1.HOLIDAY_DATE



                AND T.DATA_DATE = T1.DATA_DATE



              WHERE T.COUNTRY = 'CHN'



                AND T.STATE = '220000'



                AND T.WORKING_HOLIDAY = 'H' --假日



                AND T.HOLIDAY_DATE <= T.DATA_DATE



              GROUP BY T.HOLIDAY_DATE, T.DATA_DATE) T1



    ON T.MATURITY_DT = T1.HOLIDAY_DATE



   AND T.DATA_DATE = T1.DATADATE;

CREATE VIEW pm_rsdata.smtmods_v_pub_idx_ck_gtgshdq AS SELECT  T.ACCT_NUM,

        O_ACCT_NUM,

        T.INTEREST_ACCURED,

        T.ORG_NUM,

        t.acct_balance , 

        t.acct_balance  * B.CCY_RATE as acct_balance_rmb,

        t.data_date,

        t.curr_cd,

        T.GL_ITEM_CODE,

        T.MATUR_DATE,

        T.ST_INT_DT,

        T.INTEREST_ACCURAL,

        T.CUST_ID,

        T.INTEREST_ACCURAL_ITEM

  from pm_rsdata.smtmods_l_acct_deposit t

       inner join pm_rsdata.smtmods_l_cust_c c

          on t.data_date = c.data_date

         and t.cust_id = c.cust_id

      INNER JOIN pm_rsdata.smtmods_L_PUBL_RATE B --汇率表

                  ON T.DATA_DATE = B.DATA_DATE

                 AND T.CURR_CD = B.BASIC_CCY

                 AND B.FORWARD_CCY = 'CNY' --折人民币

       where c.deposit_custtype in ('13', '14')

         and t.gl_item_code IN ('20110202','20110203','20110204','20110211','20110208','20110210')--20231101 mdf by lxa 修改个体工商户相关口径

         AND T.ACCT_BALANCE > 0;

CREATE VIEW pm_rsdata.smtmods_v_pub_idx_ck_gtgshhq AS SELECT  T.ACCT_NUM,

         T.INTEREST_ACCURED,

         O_ACCT_NUM,

         T.ORG_NUM,

         t.acct_balance , 

         t.acct_balance  * B.CCY_RATE as acct_balance_rmb,

         t.data_date,

         t.curr_cd,

         T.GL_ITEM_CODE,

         t.INTEREST_ACCURAL, 

         T.CUST_ID,

         T.INTEREST_ACCURAL_ITEM

  from pm_rsdata.smtmods_l_acct_deposit t

       inner join pm_rsdata.smtmods_l_cust_c c

          on t.data_date = c.data_date

         and t.cust_id = c.cust_id

      INNER JOIN pm_rsdata.smtmods_L_PUBL_RATE B --汇率表

                  ON T.DATA_DATE = B.DATA_DATE

                 AND T.CURR_CD = B.BASIC_CCY

                 AND B.FORWARD_CCY = 'CNY' --折人民币

       where c.deposit_custtype in ('13', '14')

         and t.gl_item_code in ('20110201','20110209')--20231101 mdf by lxa 修改个体工商户相关口径

         AND T.ACCT_BALANCE > 0;

CREATE VIEW pm_rsdata.smtmods_v_pub_idx_ck_gtgshtz AS SELECT 



 T.ACCT_NUM,



 O_ACCT_NUM,



 T.INTEREST_ACCURED,



 T.ORG_NUM,



 t.acct_balance,



 t.acct_balance * B.CCY_RATE as acct_balance_rmb,



 t.data_date,



 t.curr_cd,



 T.GL_ITEM_CODE,



 T.MATUR_DATE,



 T.ST_INT_DT,



 T.INTEREST_ACCURAL,



 T.CUST_ID,



 T.INTEREST_ACCURAL_ITEM



  from pm_rsdata.smtmods_l_acct_deposit t



 inner join pm_rsdata.smtmods_l_cust_c c



    on t.data_date = c.data_date



   and t.cust_id = c.cust_id



 INNER JOIN pm_rsdata.smtmods_L_PUBL_RATE B --汇率表



    ON T.DATA_DATE = B.DATA_DATE



   AND T.CURR_CD = B.BASIC_CCY



   AND B.FORWARD_CCY = 'CNY' --折人民币



 where c.deposit_custtype in ('13', '14')



   and t.gl_item_code like '20110205%'



   AND T.ACCT_BALANCE > 0;

CREATE VIEW pm_rsdata.smtmods_v_pub_idx_dk_dgsndk AS select  T.ACCT_NUM,



       T.LOAN_NUM,



       T.DATA_DATE,



       T.CUST_ID,



       T.ORG_NUM,



       T.LOAN_ACCT_BAL,



       T.LOAN_ACCT_BAL * b.ccy_rate AS LOAN_ACCT_BAL_RMB,



       T.CURR_CD,



       F.SNDKFL,



       F.IF_CT_UA,



       F.AGR_USE_ADDL







  from pm_rsdata.SMTMODS_l_acct_loan t



 inner join pm_rsdata.SMTMODS_l_acct_loan_farming f



    on t.data_date = f.data_date



   and t.loan_num = f.loan_num



 INNER JOIN pm_rsdata.SMTMODS_L_PUBL_RATE B --汇率表



    ON T.DATA_DATE = B.DATA_DATE



   AND T.CURR_CD = B.BASIC_CCY



   AND B.FORWARD_CCY = 'CNY' --折人民币



  inner join pm_rsdata.SMTMODS_l_cust_c c



    on t.data_date = c.data_date



   and t.cust_id = c.cust_id



   and c.CUST_TYP <> '3';

CREATE VIEW pm_rsdata.smtmods_v_pub_idx_dk_grsndk AS select  T.ACCT_NUM,



       T.LOAN_NUM,



       T.DATA_DATE,



       T.CUST_ID,



       T.ORG_NUM,



       T.LOAN_ACCT_BAL,



       T.LOAN_ACCT_BAL * b.ccy_rate AS LOAN_ACCT_BAL_RMB,



       T.CURR_CD,



       f.SNDKFL,



       F.IF_CT_UA,



       F.AGR_USE_ADDL



  from pm_rsdata.smtmods_l_acct_loan t



 inner join pm_rsdata.smtmods_l_acct_loan_farming f



    on t.data_date = f.data_date



   and t.loan_num = f.loan_num



 INNER JOIN pm_rsdata.smtmods_L_PUBL_RATE B --汇率表



    ON T.DATA_DATE = B.DATA_DATE



   AND T.CURR_CD = B.BASIC_CCY



   AND B.FORWARD_CCY = 'CNY' --折人民币



  inner join pm_rsdata.smtmods_l_cust_p p



    on t.data_date = p.data_date



   and t.cust_id = p.cust_id



   and p.OPERATE_CUST_TYPE <> 'A';

CREATE VIEW pm_rsdata.smtmods_v_pub_idx_dk_gtgshsndk AS select  T.ACCT_NUM,



       T.LOAN_NUM,



       T.DATA_DATE,



       T.CUST_ID,



       T.ORG_NUM,



       T.LOAN_ACCT_BAL,



       T.LOAN_ACCT_BAL * b.ccy_rate AS LOAN_ACCT_BAL_RMB,



       T.CURR_CD,



       CASE



         WHEN P.CUST_ID IS NOT NULL THEN



          F.SNDKFL



         ELSE



          M.P_SNDKFL



       END AS SNDKFL,



       F.IF_CT_UA,



       F.AGR_USE_ADDL



  from pm_rsdata.smtmods_l_acct_loan t



 inner join pm_rsdata.smtmods_l_acct_loan_farming f



    on t.data_date = f.data_date



   and t.loan_num = f.loan_num



 INNER JOIN pm_rsdata.smtmods_L_PUBL_RATE B --汇率表



    ON T.DATA_DATE = B.DATA_DATE



   AND T.CURR_CD = B.BASIC_CCY



   AND B.FORWARD_CCY = 'CNY' --折人民币



  left join pm_rsdata.smtmods_m_index_sndk_mapping m



    on f.sndkfl = m.c_sndkfl --获取对公个体工商户涉农贷款分类转为个人涉农贷款分类



  left join pm_rsdata.smtmods_l_cust_p p



    on t.data_date = p.data_date



   and t.cust_id = p.cust_id



   and p.OPERATE_CUST_TYPE = 'A'



  left join pm_rsdata.smtmods_l_cust_c c



    on t.data_date = c.data_date



   and t.cust_id = c.cust_id



   and c.CUST_TYP = '3'



 where (p.cust_id is not null or c.cust_id is not null);

CREATE VIEW pm_rsdata.smtmods_v_pub_idx_dk_xfsx AS SELECT  DATA_DATE ,CUST_ID ,SUM(FACILITY_AMT) FACILITY_AMT FROM (



    SELECT  T.DATA_DATE ,T.CUST_ID, SUM(T.FACILITY_AMT) FACILITY_AMT



      FROM pm_rsdata.smtmods_L_AGRE_CREDITLINE T



     WHERE  T.FACILITY_STS = 'Y'



       AND T.FACILITY_BUSI_TYP IN ('11','12')



       AND NOT EXISTS ( SELECT 1



         FROM pm_rsdata.smtmods_L_AGRE_LOAN_CONTRACT C



       INNER JOIN (



                   SELECT T.DATA_DATE, T.ACCT_NUM



                     FROM pm_rsdata.smtmods_L_ACCT_LOAN T



                    WHERE  (SUBSTR(T.ACCT_TYP, 1, 4)  IN ('0101') --剔除个人住房 个人汽车消费



                      OR  T.ACCT_TYP = '010301')



                      and t.LOAN_ACCT_BAL <>0



                      GROUP BY  T.DATA_DATE, T.ACCT_NUM



                     ) T1



          ON C.CONTRACT_NUM = T1.ACCT_NUM



          AND C.DATA_DATE =T1.DATA_DATE



       WHERE  C.ACCT_STS = '1' --取有效合同



         AND T.FACILITY_NO =C.CONTRACT_NUM



         AND T.DATA_DATE =C.DATA_DATE



       GROUP BY C.CUST_ID,C.DATA_DATE



        )



       GROUP BY T.CUST_ID,T.DATA_DATE



       ) subquery_target_939 



       GROUP BY DATA_DATE ,CUST_ID;

CREATE VIEW pm_rsdata.smtmods_v_pub_idx_dk_ysdqrjj AS select 



 t.data_date,



 t.acct_num,



 t.loan_num,



 t.book_type,



 t.acct_typ,



 t.cust_id,



 t.curr_cd,



 t.acct_sts,



 t.org_num,



 t.drawdown_dt,



 t.drawdown_amt,



 case



   when t.EXTENDTERM_FLG = 'Y' then



    t.MATURITY_DT



   when t.MATURITY_DT_BEFORE is not null then



    t.MATURITY_DT_BEFORE



   else



    t.MATURITY_DT



 end maturity_dt,



 t.finish_dt,



 t.fund_use_loc_cd,



 t.loan_grade_cd,



 t.loan_purpose_cd,



 t.actual_maturity_dt,



 t.int_rate_typ,



 t.base_int_rat,



 t.drawdown_base_int_rat,



 t.real_int_rat,



 t.drawdown_real_int_rat,



 t.rate_float,



 t.loan_acct_bal,



 t.loan_acct_bal * b.ccy_rate AS loan_acct_bal_rmb,



 t.guaranty_typ,



 t.loan_buy_int,



 t.in_drawdown_dt,



 t.od_flg,



 t.extendterm_flg,



 t.loan_kind_cd,



 t.loan_business_typ,



 t.onlending_usage,



 t.resched_flg,



 t.loan_resched_dt,



 t.orig_acct_no,



 t.od_loan_acct_bal,



 t.od_int,



 t.od_int_obs,



 t.security_amt,



 t.ppl_repay_freq,



 t.int_repay_freq,



 t.od_days,



 t.p_od_dt,



 t.i_od_dt,



 t.loan_acct_num,



 t.pay_acct_num,



 t.repay_typ,



 t.draft_nbr,



 t.item_cd,



 t.independence_pay_amt,



 t.entrust_pay_amt,



 t.accu_int_flg,



 t.accu_int_amt,



 t.general_reserve,



 t.sp_prov_amt,



 t.special_prov_amt,



 t.useofunds,



 t.indust_rstruct_flg,



 t.indust_tran_flg,



 t.indust_stg_type,



 t.low_risk_flag,



 t.name,



 t.emp_id,



 t.security_rate,



 t.security_curr,



 t.security_acct_num,



 t.loan_fhz_num,



 t.repay_channel,



 t.next_int_pay_dt,



 t.next_repricing_dt,



 t.loan_stocken_date,



 t.loan_capitalize_typ,



 t.lyl_detail,



 t.loan_spp_typ,



 t.accu_comp_int,



 t.comp_int_amt,



 t.comp_int_flg,



 t.jobless_typ,



 t.entrust_purpose_cd,



 t.int_adjest_amt,



 t.housmort_loan_typ,



 t.bill_tran_typ,



 t.pay_cusid,



 t.year_int_incom,



 t.contracted_guar_typ,



 t.farmer_house_guar_typ,



 t.contracted_land_typ,



 t.farmer_house_typ,



 t.append_date,



 t.pricing_base_type,



 t.poverty_alle,



 t.corp_code,



 t.linkage_type,



 t.linkage_mode,



 t.oversea_ann_loan_flag,



 t.orig_term_type,



 t.orig_term,



 t.loan_purpose_area,



 t.poc_index_code,



 t.cancel_flg,



 t.gur_mort_flg,



 t.agent_id,



 t.drawdown_type,



 t.value_date,



 t.repay_term_num,



 t.current_term_num,



 t.cumulate_term_num,



 t.consecute_term_num,



 t.undertak_guar_type,



 t.generalize_loan_flg,



 t.campus_consu_loan_flg,



 t.tax_related_flg,



 t.renew_flg,



 t.busi_maintain_channels,



 t.green_loan_type,



 t.is_repay_options,



 t.poverty_loan_flg,



 t.loan_account_type,



 t.float_type,



 t.loan_sell_int,



 t.business_nam,



 t.plat_flg,



 t.is_first_loan_tag,



 t.repay_flg,



 t.is_first_report_loan_tag,



 t.comp_int_typ,



 t.ass_sec_pro_type,



 t.resched_end_dt,



 t.circle_loan_flg,



 t.int_rate_2019,



 t.non_compense_bal_rmb,



 t.loan_purpose_country,



 t.internet_loan_flg,



 t.loan_sts,



 t.int_rate_typ2,



 t.busi_channel,



 t.consump_scen_flg,



 t.analog_crecard_flg,



 t.loan_ratio,



 t.departmentd,



 t.date_sourcesd,



 t.pay_type,



 t.od_int_ygz,



 t.remark,



 t.loan_acct_bank,



 t.loan_acct_name,



 t.int_num_date,



 t.discount_interest,



 t.acct_sts_desc,



 t.acct_typ_desc,



 t.pay_acct_bank,



 t.green_loan_flg,



 t.loan_num_old,



 t.repay_typ_desc,



 t.int_repay_freq_desc,



 t.drawdown_type_new,



 t.loan_purpose_country_new,



 t.defit_inrat,



 t.maturity_dt_before,



 t.Pension_Industry,



 t.Digital_Economy_Industry,



 T.GREEN_CREDIT_USAGE,



 t.cp_id,



 t.cp_name,



 t.jbyg_id,

 

 t.HIGH_TECH_MNFT ,



 t.HIGH_TECH_SRVE ,



 t.PANT_DENS_INDU 



  from pm_rsdata.smtmods_l_acct_loan t



 INNER JOIN pm_rsdata.smtmods_L_PUBL_RATE B --汇率表



    ON T.DATA_DATE = B.DATA_DATE



   AND T.CURR_CD = B.BASIC_CCY



   AND B.FORWARD_CCY = 'CNY';

CREATE VIEW pm_rsdata.smtmods_v_pub_idx_dk_zqdqrjj AS SELECT T.DATA_DATE AS DATA_DATE,



       T.ACCT_NUM AS ACCT_NUM,



       T.LOAN_NUM AS LOAN_NUM,



       T.BOOK_TYPE AS BOOK_TYPE,



       T.ACCT_TYP AS ACCT_TYP,



       T.CUST_ID AS CUST_ID,



       T.CURR_CD AS CURR_CD,



       T.ACCT_STS AS ACCT_STS,



       T.ORG_NUM AS ORG_NUM,



       T.DRAWDOWN_DT AS DRAWDOWN_DT,



       T.DRAWDOWN_AMT AS DRAWDOWN_AMT,



       T.MATURITY_DT AS MATURITY_DT,



       T.FINISH_DT AS FINISH_DT,



       T.FUND_USE_LOC_CD AS FUND_USE_LOC_CD,



       T.LOAN_GRADE_CD AS LOAN_GRADE_CD,



       T.LOAN_PURPOSE_CD AS LOAN_PURPOSE_CD,



       CASE WHEN (T.EXTENDTERM_FLG = 'Y') THEN COALESCE(T3.SJDQR,T2.EXTENT_END_DT, T.MATURITY_DT)



         ELSE  T.MATURITY_DT



       END  AS ACTUAL_MATURITY_DT,



       T.INT_RATE_TYP AS INT_RATE_TYP,



       T.BASE_INT_RAT AS BASE_INT_RAT,



       T.DRAWDOWN_BASE_INT_RAT AS DRAWDOWN_BASE_INT_RAT,



       T.REAL_INT_RAT AS REAL_INT_RAT,



       T.DRAWDOWN_REAL_INT_RAT AS DRAWDOWN_REAL_INT_RAT,



       T.RATE_FLOAT AS RATE_FLOAT,



       T.LOAN_ACCT_BAL AS LOAN_ACCT_BAL,



       (T.LOAN_ACCT_BAL * B.CCY_RATE) AS LOAN_ACCT_BAL_RMB,



       T.GUARANTY_TYP AS GUARANTY_TYP,



       T.LOAN_BUY_INT AS LOAN_BUY_INT,



       T.IN_DRAWDOWN_DT AS IN_DRAWDOWN_DT,



       T.OD_FLG AS OD_FLG,



       T.EXTENDTERM_FLG AS EXTENDTERM_FLG,



       T.LOAN_KIND_CD AS LOAN_KIND_CD,



       T.LOAN_BUSINESS_TYP AS LOAN_BUSINESS_TYP,



       T.ONLENDING_USAGE AS ONLENDING_USAGE,



       T.RESCHED_FLG AS RESCHED_FLG,



       T.LOAN_RESCHED_DT AS LOAN_RESCHED_DT,



       T.ORIG_ACCT_NO AS ORIG_ACCT_NO,



       T.OD_LOAN_ACCT_BAL AS OD_LOAN_ACCT_BAL,



       T.OD_INT AS OD_INT,



       T.OD_INT_OBS AS OD_INT_OBS,



       T.SECURITY_AMT AS SECURITY_AMT,



       T.PPL_REPAY_FREQ AS PPL_REPAY_FREQ,



       T.INT_REPAY_FREQ AS INT_REPAY_FREQ,



       T.OD_DAYS AS OD_DAYS,



       T.P_OD_DT AS P_OD_DT,



       T.I_OD_DT AS I_OD_DT,



       T.LOAN_ACCT_NUM AS LOAN_ACCT_NUM,



       T.PAY_ACCT_NUM AS PAY_ACCT_NUM,



       T.REPAY_TYP AS REPAY_TYP,



       T.DRAFT_NBR AS DRAFT_NBR,



       T.ITEM_CD AS ITEM_CD,



       T.INDEPENDENCE_PAY_AMT AS INDEPENDENCE_PAY_AMT,



       T.ENTRUST_PAY_AMT AS ENTRUST_PAY_AMT,



       T.ACCU_INT_FLG AS ACCU_INT_FLG,



       T.ACCU_INT_AMT AS ACCU_INT_AMT,



       T.GENERAL_RESERVE AS GENERAL_RESERVE,



       T.SP_PROV_AMT AS SP_PROV_AMT,



       T.SPECIAL_PROV_AMT AS SPECIAL_PROV_AMT,



       T.USEOFUNDS AS USEOFUNDS,



       T.INDUST_RSTRUCT_FLG AS INDUST_RSTRUCT_FLG,



       T.INDUST_TRAN_FLG AS INDUST_TRAN_FLG,



       T.INDUST_STG_TYPE AS INDUST_STG_TYPE,



       T.LOW_RISK_FLAG AS LOW_RISK_FLAG,



       T.NAME AS NAME,



       T.EMP_ID AS EMP_ID,



       T.SECURITY_RATE AS SECURITY_RATE,



       T.SECURITY_CURR AS SECURITY_CURR,



       T.SECURITY_ACCT_NUM AS SECURITY_ACCT_NUM,



       T.LOAN_FHZ_NUM AS LOAN_FHZ_NUM,



       T.REPAY_CHANNEL AS REPAY_CHANNEL,



       T.NEXT_INT_PAY_DT AS NEXT_INT_PAY_DT,



       T.NEXT_REPRICING_DT AS NEXT_REPRICING_DT,



       T.LOAN_STOCKEN_DATE AS LOAN_STOCKEN_DATE,



       T.LOAN_CAPITALIZE_TYP AS LOAN_CAPITALIZE_TYP,



       T.LYL_DETAIL AS LYL_DETAIL,



       T.LOAN_SPP_TYP AS LOAN_SPP_TYP,



       T.ACCU_COMP_INT AS ACCU_COMP_INT,



       T.COMP_INT_AMT AS COMP_INT_AMT,



       T.COMP_INT_FLG AS COMP_INT_FLG,



       T.JOBLESS_TYP AS JOBLESS_TYP,



       T.ENTRUST_PURPOSE_CD AS ENTRUST_PURPOSE_CD,



       T.INT_ADJEST_AMT AS INT_ADJEST_AMT,



       T.HOUSMORT_LOAN_TYP AS HOUSMORT_LOAN_TYP,



       T.BILL_TRAN_TYP AS BILL_TRAN_TYP,



       T.PAY_CUSID AS PAY_CUSID,



       T.YEAR_INT_INCOM AS YEAR_INT_INCOM,



       T.CONTRACTED_GUAR_TYP AS CONTRACTED_GUAR_TYP,



       T.FARMER_HOUSE_GUAR_TYP AS FARMER_HOUSE_GUAR_TYP,



       T.CONTRACTED_LAND_TYP AS CONTRACTED_LAND_TYP,



       T.FARMER_HOUSE_TYP AS FARMER_HOUSE_TYP,



       T.APPEND_DATE AS APPEND_DATE,



       T.PRICING_BASE_TYPE AS PRICING_BASE_TYPE,



       T.POVERTY_ALLE AS POVERTY_ALLE,



       T.CORP_CODE AS CORP_CODE,



       T.LINKAGE_TYPE AS LINKAGE_TYPE,



       T.LINKAGE_MODE AS LINKAGE_MODE,



       T.OVERSEA_ANN_LOAN_FLAG AS OVERSEA_ANN_LOAN_FLAG,



       T.ORIG_TERM_TYPE AS ORIG_TERM_TYPE,



       T.ORIG_TERM AS ORIG_TERM,



       T.LOAN_PURPOSE_AREA AS LOAN_PURPOSE_AREA,



       T.POC_INDEX_CODE AS POC_INDEX_CODE,



       T.CANCEL_FLG AS CANCEL_FLG,



       T.GUR_MORT_FLG AS GUR_MORT_FLG,



       T.AGENT_ID AS AGENT_ID,



       T.DRAWDOWN_TYPE AS DRAWDOWN_TYPE,



       T.VALUE_DATE AS VALUE_DATE,



       T.REPAY_TERM_NUM AS REPAY_TERM_NUM,



       T.CURRENT_TERM_NUM AS CURRENT_TERM_NUM,



       T.CUMULATE_TERM_NUM AS CUMULATE_TERM_NUM,



       T.CONSECUTE_TERM_NUM AS CONSECUTE_TERM_NUM,



       T.UNDERTAK_GUAR_TYPE AS UNDERTAK_GUAR_TYPE,



       T.GENERALIZE_LOAN_FLG AS GENERALIZE_LOAN_FLG,



       T.CAMPUS_CONSU_LOAN_FLG AS CAMPUS_CONSU_LOAN_FLG,



       T.TAX_RELATED_FLG AS TAX_RELATED_FLG,



       T.RENEW_FLG AS RENEW_FLG,



       T.BUSI_MAINTAIN_CHANNELS AS BUSI_MAINTAIN_CHANNELS,



       T.GREEN_LOAN_TYPE AS GREEN_LOAN_TYPE,



       T.IS_REPAY_OPTIONS AS IS_REPAY_OPTIONS,



       T.POVERTY_LOAN_FLG AS POVERTY_LOAN_FLG,



       T.LOAN_ACCOUNT_TYPE AS LOAN_ACCOUNT_TYPE,



       T.FLOAT_TYPE AS FLOAT_TYPE,



       T.LOAN_SELL_INT AS LOAN_SELL_INT,



       T.BUSINESS_NAM AS BUSINESS_NAM,



       T.PLAT_FLG AS PLAT_FLG,



       T.IS_FIRST_LOAN_TAG AS IS_FIRST_LOAN_TAG,



       T.REPAY_FLG AS REPAY_FLG,



       T.IS_FIRST_REPORT_LOAN_TAG AS IS_FIRST_REPORT_LOAN_TAG,



       T.COMP_INT_TYP AS COMP_INT_TYP,



       T.ASS_SEC_PRO_TYPE AS ASS_SEC_PRO_TYPE,



       T.RESCHED_END_DT AS RESCHED_END_DT,



       T.CIRCLE_LOAN_FLG AS CIRCLE_LOAN_FLG,



       T.INT_RATE_2019 AS INT_RATE_2019,



       T.NON_COMPENSE_BAL_RMB AS NON_COMPENSE_BAL_RMB,



       T.LOAN_PURPOSE_COUNTRY AS LOAN_PURPOSE_COUNTRY,



       T.INTERNET_LOAN_FLG AS INTERNET_LOAN_FLG,



       T.LOAN_STS AS LOAN_STS,



       T.INT_RATE_TYP2 AS INT_RATE_TYP2,



       T.BUSI_CHANNEL AS BUSI_CHANNEL,



       T.CONSUMP_SCEN_FLG AS CONSUMP_SCEN_FLG,



       T.ANALOG_CRECARD_FLG AS ANALOG_CRECARD_FLG,



       T.LOAN_RATIO AS LOAN_RATIO,



       T.DEPARTMENTD AS DEPARTMENTD,



       T.DATE_SOURCESD AS DATE_SOURCESD,



       T.PAY_TYPE AS PAY_TYPE,



       T.OD_INT_YGZ AS OD_INT_YGZ,



       T.REMARK AS REMARK,



       T.LOAN_ACCT_BANK AS LOAN_ACCT_BANK,



       T.LOAN_ACCT_NAME AS LOAN_ACCT_NAME,



       T.INT_NUM_DATE AS INT_NUM_DATE,



       T.DISCOUNT_INTEREST AS DISCOUNT_INTEREST,



       T.ACCT_STS_DESC AS ACCT_STS_DESC,



       T.ACCT_TYP_DESC AS ACCT_TYP_DESC,



       T.PAY_ACCT_BANK AS PAY_ACCT_BANK,



       T.GREEN_LOAN_FLG AS GREEN_LOAN_FLG,



       T.LOAN_NUM_OLD AS LOAN_NUM_OLD,



       T.REPAY_TYP_DESC AS REPAY_TYP_DESC,



       T.INT_REPAY_FREQ_DESC AS INT_REPAY_FREQ_DESC,



       T.DRAWDOWN_TYPE_NEW AS DRAWDOWN_TYPE_NEW,



       T.LOAN_PURPOSE_COUNTRY_NEW AS LOAN_PURPOSE_COUNTRY_NEW,



       T.DEFIT_INRAT AS DEFIT_INRAT,



       T.MATURITY_DT_BEFORE AS MATURITY_DT_BEFORE,



       T2.LOAN_NUM AS JJ,



       T.JBYG_ID AS JBYG_ID,



       T.SZYG_ID AS SZYG_ID,



       T.SPYG_ID AS SPYG_ID,



       T.DRAFT_RNG AS DRAFT_RNG,



       T.GRXFDKYT AS GRXFDKYT



  FROM pm_rsdata.smtmods_L_ACCT_LOAN T 



  LEFT JOIN pm_rsdata.smtmods_L_PUBL_RATE B



    ON T.DATA_DATE = B.DATA_DATE  



   AND T.CURR_CD = B.BASIC_CCY  



   AND B.FORWARD_CCY = 'CNY' 



  LEFT JOIN  (SELECT T1.DATA_DATE AS DATA_DATE,



                 T1.ACCT_NUM AS ACCT_NUM,



                 T1.LOAN_NUM AS LOAN_NUM,



                 T1.EXTENDTERM_NUM AS EXTENDTERM_NUM,



                 T1.ORG_NUM AS ORG_NUM,



                 T1.CUST_ID AS CUST_ID,



                 T1.EXTENT_AMT AS EXTENT_AMT,



                 T1.EXTENT_START_DT AS EXTENT_START_DT,



                 T1.EXTENT_END_DT AS EXTENT_END_DT,



                 T1.EXTENT_LOAN_NUM AS EXTENT_LOAN_NUM,



                 T1.EXTENT_ACCT_NUM AS EXTENT_ACCT_NUM,



                 T1.INT_RATE_TYP AS INT_RATE_TYP,



                 T1.EXTENT_DATE_RAT AS EXTENT_DATE_RAT,



                 T1.RATE_FLOAT_POINTS AS RATE_FLOAT_POINTS,



                 T1.TARDE_TELLER_CD AS TARDE_TELLER_CD,



                 T1.AUTH_TELLER_CD AS AUTH_TELLER_CD,



                 T1.INT_RATE_TYP2 AS INT_RATE_TYP2,



                 T1.DEPARTMENTD AS DEPARTMENTD,



                 T1.DATE_SOURCESD AS DATE_SOURCESD,



                 ROW_NUMBER() OVER(PARTITION BY T1.LOAN_NUM, T1.DATA_DATE ORDER BY T1.EXTENDTERM_NUM DESC) AS RN



            FROM pm_rsdata.smtmods_L_ACCT_LOAN_EXTENDTERM T1) T2



        ON T.LOAN_NUM = T2.LOAN_NUM



       AND T2.DATA_DATE = T.DATA_DATE



       AND T2.RN = 1 



      LEFT JOIN pm_rsdata.ZQDQR_SG T3



        ON T.LOAN_NUM = T3.JJBH;

CREATE VIEW pm_rsdata.smtmods_v_pub_idx_fina_gl AS SELECT



 T.DATA_DATE



,T.ACCTOUNT_DT



,T.ORG_NUM



,T.ITEM_CD



,T.PRODUCT_CD



,T.CURR_CD



,T.ORIG_CURR_CD



,T.CREDIT_D_AMT



,T.CREDIT_M_AMT



,T.CREDIT_Q_AMT



,T.CREDIT_H_Y_AMT



,T.CREDIT_Y_AMT



,T.CREDIT_BAL



,T.DEBIT_D_AMT



,T.DEBIT_M_AMT



,T.DEBIT_Q_AMT



,T.DEBIT_H_Y_AMT



,T.DEBIT_Y_AMT



,T.DEBIT_BAL



,T.DISCOUNTED_FLG



,T.SUM_LEVEL_FLG



,T.DEPARTMENTD



,T.DATE_SOURCESD



,T.CREDIT_BAL_PRE



,T.DEBIT_BAL_PER



FROM pm_rsdata.SMTMODS_L_FINA_GL T



WHERE T.ORG_NUM LIKE '%00' 



OR T.ORG_NUM LIKE '%98%' 



OR  T.ORG_NUM LIKE '5%' 



OR  T.ORG_NUM LIKE '6%';

CREATE VIEW pm_rsdata.smtmods_v_pub_idx_sx_phjrdksx AS SELECT     CUST_ID, FACILITY_AMT, DATA_DATE FROM



         pm_rsdata.SMTMODS_AGRE_CREDITLINE_INFO;

CREATE VIEW pm_rsdata.smtmods_view_l_publ_org_bra AS SELECT



         t1.ORG_NUM AS ORG_NUM,



         t1.DATA_DATE AS DATA_DATE,



         t1.ORG_NAM AS ORG_NAM,



         COALESCE(TRIM( t1.FIN_LIN_NUM ),  TRIM( t2.FIN_LIN_NUM ),  TRIM( t3.FIN_LIN_NUM )) AS FIN_LIN_NUM,



         COALESCE( t1.BANK_CD, t2.BANK_CD, t3.BANK_CD) AS BANK_CD,



         CONCAT( substr( COALESCE( t1.FIN_LIN_NUM, t2.FIN_LIN_NUM, t3.FIN_LIN_NUM ), 1, 11 ), t1.ORG_NUM ) AS ORG_ID



    FROM pm_rsdata.smtmods_l_publ_org_bra t1



            LEFT JOIN pm_rsdata.smtmods_l_publ_org_bra t2 



              ON t1.UP_ORG_NUM = t2.ORG_NUM 



             AND t2.DATA_DATE = t1.DATA_DATE 



            LEFT JOIN pm_rsdata.smtmods_l_publ_org_bra t3



              ON t2.UP_ORG_NUM = t3.ORG_NUM



             AND t3.DATA_DATE = t1.DATA_DATE 



   WHERE t1.ORG_NUM <> '999999';

CREATE VIEW pm_rsdata.v_pisa_bank_relation_datacore AS select * from (SELECT '220400' AS BANK_ID,

       '030300' AS BANK_REL,

       '100' AS TOTAL_TYPE  --撤并机构上游没有变更

  

UNION ALL

SELECT '220600' AS BANK_ID,

       '091400' AS BANK_REL,

       '100' AS TOTAL_TYPE   --撤并机构上游没有变更

 

UNION ALL

SELECT '990000' AS BANK_ID,

       '999999' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '51000000' AS BANK_ID,

       '51999999' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '52000000' AS BANK_ID,

       '52999999' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '53000000' AS BANK_ID,

       '53999999' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '54000000' AS BANK_ID,

       '54999999' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '55000000' AS BANK_ID,

       '55999999' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '56000000' AS BANK_ID,

       '56999999' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '57000000' AS BANK_ID,

       '57999999' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '58000000' AS BANK_ID,

       '58999999' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '59000000' AS BANK_ID,

       '59999999' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '60000000' AS BANK_ID,

       '60999999' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '51000000' AS BANK_ID,

       '510000' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '52000000' AS BANK_ID,

       '520000' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '53000000' AS BANK_ID,

       '530000' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '54000000' AS BANK_ID,

       '540000' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '55000000' AS BANK_ID,

       '550000' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '56000000' AS BANK_ID,

       '560000' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '57000000' AS BANK_ID,

       '570000' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '58000000' AS BANK_ID,

       '580000' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '59000000' AS BANK_ID,

       '590000' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

SELECT '60000000' AS BANK_ID,

       '600000' AS BANK_REL,

       '100' AS TOTAL_TYPE



UNION ALL

/*SELECT T.PARENT_INST_ID AS BANK_ID,

       T.INST_ID AS BANK_REL,

       '100' AS TOTAL_TYPE

  FROM PISA_U_BASE_INST T

 WHERE T.INST_ID LIKE '2%'

   AND T.INST_ID <> '201999'*/

   SELECT T.PARENT_INST_ID AS BANK_ID,

       T.INST_ID AS BANK_REL,

       '100' AS TOTAL_TYPE

  FROM pm_rsdata.PISA_U_BASE_INST T

 WHERE (T.INST_ID LIKE '2%' OR T.INST_ID LIKE '512%' OR

       T.INST_ID LIKE '523%' OR T.INST_ID LIKE '532%' OR

       T.INST_ID LIKE '542%' OR T.INST_ID LIKE '551%' OR

       T.INST_ID LIKE '561%' OR T.INST_ID LIKE '572%' OR

       T.INST_ID LIKE '582%' OR T.INST_ID LIKE '592%' OR

       T.INST_ID LIKE '602%')

   AND T.INST_ID <> '201999'



UNION ALL

SELECT DECODE(SUBSTR(T.INST_ID, 0, 2),

              '00',

              '220100',

              '01',

              '220100',

              '02',

              '220200',

              '07',

              '220300',

              '03',

              '220400',

              '04',

              '220500',

              '09',

              '220600',

              '05',

              '220700',

              '08',

              '220800',

              '06',

              '222400',

              '11',

              '210100',

              '10',

              '210200',

              '88',

              '220100',

              '13',

              '220100',

              '51',

              '51220200', -----51220200代表磐石村镇吉林市

              '52',

              '52321000',  -----52321000代表江都村镇扬州市

              '53',

              '53220200',  -----53220200代表舒兰村镇吉林市

              '54',

              '54220100',  -----54220100代表双阳村镇长春市

              '55',

              '55130900',  -----55130900代表沧县村镇沧州市

              '56',

              '56131000',  -----56131000代表江永清村镇廊坊市

              '57',

              '57222400',  -----57222400代表珲春村镇延边州

              '58',

              '58220300', -----58222400代表双辽村镇四平市

              '59',

              '59220400' ,-----59220400代表东丰村镇辽源市

              '60',

              '60220200' -----60220200代表蛟河村镇吉林市

              ) AS BANK_ID,

       T.INST_ID AS BANK_REL,

       '100' AS TOTAL_TYPE

  FROM pm_rsdata.PISA_U_BASE_INST T

 WHERE (T.INST_LAYER = '3' and

       t.inst_id not in ('013401', '013402', '013403', '013493')) --人行要求公主岭支行数据仍然汇总到四平分行，暂不汇总到长春分行

    OR (T.INST_ID NOT LIKE '%00' AND T.INST_LAYER = '2')

    union all

  select '220300' BANK_ID,--人行要求公主岭支行数据仍然汇总到四平分行

  i.inst_id as BANK_REL,

  '100' AS TOTAL_TYPE



   from pm_rsdata.PISA_U_BASE_INST i   where i.inst_id in('013401','013402','013403','013493') ) subquery_target_156;

CREATE VIEW pm_rsdata.v_pub_check002 AS SELECT /* PARALLEL(8) USE_HASH(T,T1,T2,K) leading(T)*/

 NVL(T1.DATA_DATE, T2.DATA_DATE) DATA_DATE,

 NVL(T.ITEM_CD_UP, T2.ITEM_CD_UP) AS ITEM_NO,

 NVL(SUM(CASE

       WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '2004' THEN

          T1.CREDIT_BAL * K.CCY_RATE

       WHEN T1.ITEM_CD LIKE '1%' THEN

         (T1.DEBIT_BAL - T1.CREDIT_BAL) * K.CCY_RATE

       ELSE

         (T1.CREDIT_BAL - T1.DEBIT_BAL) * K.CCY_RATE

     END),

     0) ZZ_BALANCE,

 NVL(SUM(T2.FHZ_BALANCE * K.CCY_RATE),0) AS FHZ_BALANCE, --借方余额

 NVL(SUM(CASE

       WHEN SUBSTR(T1.ITEM_CD, 1, 4) = '2004' THEN

          T1.CREDIT_BAL * K.CCY_RATE

       WHEN T1.ITEM_CD LIKE '1%' THEN

         (T1.DEBIT_BAL - T1.CREDIT_BAL) * K.CCY_RATE

       ELSE

         (T1.CREDIT_BAL - T1.DEBIT_BAL) * K.CCY_RATE

     END),

     0) - NVL(SUM(T2.FHZ_BALANCE * K.CCY_RATE), 0) AS MINUS_BALANCE

  FROM pm_rsdata.ZF_ITEM_CD_MAPPING T

  LEFT JOIN pm_rsdata.L_FINA_GL T1

    ON T.ITEM_CD = T1.ITEM_CD

  LEFT JOIN (SELECT SUM(T.BALANCE) AS FHZ_BALANCE,

                    T.GL_ITEM_CODE AS ITEM_CD,

                    T.DATA_DATE,

                    T.CURR_CD,

                    SUBSTR(T.GL_ITEM_CODE, 1, 4) AS ITEM_CD_UP

               FROM pm_rsdata.L_ACCT_FUND_MMFUND T --贷款借据表

              INNER JOIN (SELECT ITEM_CD

                           FROM pm_rsdata.ZF_ITEM_CD_MAPPING

                          WHERE FLAG = '2'

                            AND SIGN = '01') T1

                 ON T.GL_ITEM_CODE = T1.ITEM_CD

             --WHERE T.ORG_NUM NOT LIKE '51%'

               WHERE T.ORG_NUM NOT LIKE '5%' AND  T.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇

                AND T.BALANCE <> 0 --modi by djh 20230221 有余额小于0数据，由于有账户能透支

                AND T.GL_ITEM_CODE NOT LIKE '2012%' --从存款账户表出数

              GROUP BY T.GL_ITEM_CODE, T.DATA_DATE,SUBSTR(T.GL_ITEM_CODE, 1, 4),

                       T.CURR_CD) T2

    ON T.ITEM_CD = T2.ITEM_CD

   AND T1.DATA_DATE = T2.DATA_DATE

   AND T1.CURR_CD = T2.CURR_CD

 LEFT JOIN pm_rsdata.L_PUBL_RATE K --汇率表

    ON T1.DATA_DATE = K.DATA_DATE

   AND T1.CURR_CD = K.BASIC_CCY

   AND K.FORWARD_CCY = 'CNY' --折人民币

 WHERE T1.CURR_CD <> 'BWB'

   AND (T1.CREDIT_BAL <> 0 or T1.DEBIT_BAL <> 0)

   AND T.FLAG = '2'

   AND T.SIGN = '01'

   AND T1.ORG_NUM = '990000'

   AND T1.ITEM_CD NOT LIKE '2012%' --从存款账户表出数

 GROUP BY  NVL(T.ITEM_CD_UP, T2.ITEM_CD_UP) , NVL(T1.DATA_DATE, T2.DATA_DATE);

CREATE VIEW pm_rsdata.v_pub_check015 AS SELECT  A.DATA_DATE,

 NVL(A.ITEM_CD_UP, B.ITEM_CD_UP) AS ITEM_NO,

 NVL(A.ZZ_BALANCE,0) AS ZZ_BALANCE,

 NVL(B.FHZ_BALANCE,0) AS FHZ_BALANCE,

 NVL(A.ZZ_BALANCE,0)-NVL(B.FHZ_BALANCE,0) AS MINUS_BALANCE FROM pm_rsdata.V_PUB_CHECK015_1 A

FULL JOIN pm_rsdata.V_PUB_CHECK015_2 B

ON A.DATA_DATE=B.DATA_DATE

AND A.ITEM_CD_UP=B.ITEM_CD_UP;

CREATE VIEW pm_rsdata.v_pub_check015_1 AS SELECT /* PARALLEL(8) USE_HASH(T1,T,K) leading(T)*/

 T1.DATA_DATE AS DATA_DATE,

 SUBSTR(T.ITEM_CD_UP, 1, 4) AS ITEM_CD_UP,

 SUM(T1.DEBIT_BAL * K.CCY_RATE) ZZ_BALANCE

  FROM pm_rsdata.L_FINA_GL T1

  LEFT JOIN pm_rsdata.ZF_ITEM_CD_MAPPING T

    ON T.ITEM_CD = T1.ITEM_CD

  LEFT JOIN pm_rsdata.L_PUBL_RATE K --汇率表

    ON T1.DATA_DATE = K.DATA_DATE

   AND T1.CURR_CD = K.BASIC_CCY

   AND K.FORWARD_CCY = 'CNY' --折人民币

 WHERE T1.CURR_CD <> 'BWB'

    AND T1.DEBIT_BAL <> 0

    AND T1.ORG_NUM NOT LIKE '%00'

    AND T1.ORG_NUM NOT LIKE '5%'

    AND T1.ORG_NUM NOT LIKE '6%'

    AND T1.ORG_NUM <> '999999'

   AND T.FLAG = '6'

   AND T.SIGN = '02'

   AND T.ITEM_CD NOT IN ('11320113', '11320114')

   AND T.ITEM_NAME LIKE '%应计%'

 GROUP BY T1.DATA_DATE, SUBSTR(T.ITEM_CD_UP, 1, 4);

CREATE VIEW pm_rsdata.v_pub_check015_2 AS SELECT /* PARALLEL(8)*/

 SUM(T.ACCU_INT_AMT * B.CCY_RATE) AS FHZ_BALANCE, --OD_INT_YGZ营改增挂账利息废弃

 '1132' AS ITEM_CD_UP,

 T.DATA_DATE

  FROM pm_rsdata.L_ACCT_LOAN T --贷款借据表

 INNER JOIN (SELECT ITEM_CD

               FROM pm_rsdata.ZF_ITEM_CD_MAPPING

              WHERE FLAG = '1'

                AND SIGN = '01') T1

    ON T.ITEM_CD = T1.ITEM_CD

  LEFT JOIN pm_rsdata.L_PUBL_RATE B --汇率表

    ON T.DATA_DATE = B.DATA_DATE

   AND T.CURR_CD = B.BASIC_CCY

   AND B.FORWARD_CCY = 'CNY' --折人民币

-- WHERE T.ORG_NUM NOT LIKE '51%'

 WHERE T.ORG_NUM NOT LIKE '5%'

   AND T.ORG_NUM NOT LIKE '6%' --ADD BY DJH20231115去掉村镇

   AND ACCU_INT_AMT <> 0

 GROUP BY T.DATA_DATE;

CREATE VIEW pm_rsdata.v_pub_idx_sx_phjrdksx AS SELECT     CUST_ID, FACILITY_AMT, DATA_DATE FROM

         pm_rsdata.AGRE_CREDITLINE_INFO;
