CREATE OR REPLACE PROCEDURE pm_rsdata.proc_cbrc_l_acct_deposit_tmp(II_DATADATE IN STRING --跑批日期
                                             
)
/******************************
  @author:xiangxu
  @create-date:2015-09-19
  @description:对公客户信息处理（全量客户信息+对公补充信息）
  @modification history:
  m0.author-create_date-description
  
源表 : 
     L_ACCT_DEPOSIT
     L_PUBL_RATE
     L_ACCT_FUND_MMFUND
     L_CUST_C
目标表：
     CBRC_L_ACCT_DEPOSIT_TMP
     CBRC_L_ACCT_DEPOSIT_TMP2
     CBRC_L_ACCT_DEPOSIT_TMP3
     
  *******************************/
 IS
  V_SCHEMA    STRING; --当前存储过程所属的模式名
  V_SYSTEM    STRING; --系统名
  V_PROCEDURE  STRING; --当前储存过程名称
  V_TAB_NAME  STRING; --目标表名
  I_DATADATE  STRING; --数据日期(数值型)YYYYMMDD
  V_DATADATE  STRING; --数据日期(字符型)YYYY-MM-DD
  V_STEP_ID   INTEGER; --任务号
  V_STEP_DESC STRING; --任务描述
  V_STEP_FLAG STRING; --任务执行状态标识
  V_ERRORCODE     STRING; --错误编码
  V_ERRORDESC     STRING; --错误内容
  II_STATUS    INTEGER DEFAULT 0; --断点续跑时，用于识别存储过程的是否跳过1--跳过 0--不跳过
  D_DATADATE_CCY  STRING;
BEGIN
  IF II_STATUS=0 THEN
    V_STEP_ID   := 0;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '参数初始化处理';
    I_DATADATE := II_DATADATE;
    V_SYSTEM  := 'CBRC';
    V_PROCEDURE := UPPER('PROC_CBRC_L_CUST_C_TMP');
    D_DATADATE_CCY := II_DATADATE ;

    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID,  V_ERRORCODE,  V_STEP_DESC,  II_DATADATE);

    V_TAB_NAME := 'CBRC_L_ACCT_DEPOSIT_TMP';
  
  
    V_STEP_ID   := 1;
    V_STEP_FLAG := 0;
    V_STEP_DESC := '清理 [' || V_TAB_NAME || ']表历史数据';
    sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,  V_ERRORCODE,  V_STEP_DESC,  II_DATADATE);
    
    
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP');
    EXECUTE IMMEDIATE ('TRUNCATE TABLE PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP2');

    DELETE FROM PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP3
      WHERE DATA_DATE = I_DATADATE;
    COMMIT;
    
    

  
    V_STEP_ID   := 2;
    V_STEP_DESC := '处理存款账户信息表_临时表';
    V_STEP_FLAG := 0;
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE, V_STEP_ID,  V_ERRORCODE,  V_STEP_DESC,  II_DATADATE);


  
    INSERT  INTO PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP 
      ( DATA_DATE, --1数据日期
       ACCT_NUM, --2账号
       ORG_NUM, --3机构号
       CUST_ID, --4客户号
       DEPOSIT_NUM, --5存单号
       CURR_CD, --6账户币种
       ACCT_TYPE, --7账户类型
       ST_INT_DT, --8起息日期
       ACCT_BALANCE, --9账户余额
       ACCT_BALANCE_RMB, --10账户余额_人民币
       ACCT_BALANCE_USD, --11账户余额_美元
       MATUR_DATE, --12到期日
       INT_RATE_TYP, --13利率类型
       INT_RATE, --14利率
       NEXT_INT_REVI_DATE, --15下一利率重定价日
       ACCU_INT_FLG, --16计息标志
       ACCT_STS, --17账户状态
       PBOC_ACCT_NATURE_CD, --18人行账户属性
       ACCT_OPDATE, --19开户日期
       ACCT_CLDATE, --20销户日期
       AMT, --21业务发生金额
       LIMIT_TYPE, --22限额类型
       ACCOUNT_LIMIT, --23账户限额
       GL_ITEM_CODE, --24科目号
       LAST_TX_DATE, --25上次动户日期
       TERM_TYPE, --26期限类型
       ACTUAL_TERM, --27实际期限
       OPEN_TELLER, --28开户柜员号
       ACCOUNT_CATA_FLG, --29钞汇标志
       SP_ACCT_TYPE, --30专项存款类型
       ENTRUST_ACCT_TYPE, --31委托贷款基金细类
       STABLE_RISK_TYPE, --32存款稳定性分类
       BUS_REL, --33是否具有业务关系
       PLEDGE_ASSETS_TYPE, --34担保品风险分类
       PLEDGE_ASSETS_VAL, --35担保品市场价值
       IS_INLINE_OPTIONS, --36是否内嵌提前到期期权
       CALL_DEPOSIT_DATE, --37通知取款日期
       CALL_DEPOSIT_AMT, --38通知取款金额
       DEPARTMENTD, --39归属部门
       DATE_SOURCESD, --40数据来源
       ORI_TERM_CODE, --41存款原始期限
       REMAIN_TERM_CODE, --42存款剩余期限
       IS_ONLINE_ABLE, --43是否网上支付账户
       ADVANCE_DRAW_FLG, --44是否可提前支取
       C_DEPOSIT_TYP, --45单位存款类型
       INTEREST_ACCURAL, --46应付利息
       INTEREST_ACCURAL_ITEM,--47应付利息科目
       ACCT_NAM, --48账户名称
       INTEREST_ACCURED,--49应计利息
       NEXT_RATE_DATE, --50下一付息日
       STABLE_DEP_TYPE,--51稳定存款分类
       O_ACCT_NUM--52外部账号
       )
      SELECT  
             I_DATADATE AS DATA_DATE, --1数据日期
             ACCT_NUM, --2账号
             ORG_NUM, --3机构号
             CUST_ID, --4客户号
             DEPOSIT_NUM, --5存单号
             CURR_CD, --6账户币种
             ACCT_TYPE, --7账户类型
             ST_INT_DT, --8起息日期
             ACCT_BALANCE, --9账户余额
             T.ACCT_BALANCE * U.CCY_RATE, --10账户余额 (折人民币)
             T.ACCT_BALANCE * V.CCY_RATE, --11账户余额 (折美元)
             MATUR_DATE, --12到期日
             INT_RATE_TYP, --13利率类型
             INT_RATE, --14利率
             NEXT_INT_REVI_DATE, --15下一利率重定价日
             ACCU_INT_FLG, --16计息标志
             ACCT_STS, --17账户状态
             PBOC_ACCT_NATURE_CD, --18人行账户属性
             ACCT_OPDATE, --19开户日期
             ACCT_CLDATE, --20销户日期
             AMT, --21业务发生金额
             LIMIT_TYPE, --22限额类型
             ACCOUNT_LIMIT, --23账户限额
             GL_ITEM_CODE, --24科目号
             LAST_TX_DATE, --25上次动户日期
             TERM_TYPE, --26期限类型
             ACTUAL_TERM, --27实际期限
             OPEN_TELLER, --28开户柜员号
             ACCOUNT_CATA_FLG, --29钞汇标志
             SP_ACCT_TYPE, --30专项存款类型
             ENTRUST_ACCT_TYPE, --31委托贷款基金细类
             STABLE_RISK_TYPE, --32存款稳定性分类
             BUS_REL, --33是否具有业务关系
             PLEDGE_ASSETS_TYPE, --34担保品风险分类
             PLEDGE_ASSETS_VAL, --35担保品市场价值
             IS_INLINE_OPTIONS, --36是否内嵌提前到期期权
             CALL_DEPOSIT_DATE, --37通知取款日期
             CALL_DEPOSIT_AMT, --38通知取款金额
             T.DEPARTMENTD, --39归属部门
             T.DATE_SOURCESD, --40数据来源
             CASE
               WHEN MATUR_DATE IS NOT NULL AND ST_INT_DT IS NOT NULL THEN
                TRUNC(MONTHS_BETWEEN(date(MATUR_DATE), date(ST_INT_DT)), 1)
             END, --41存款原始期限
             CASE
               WHEN MATUR_DATE IS NOT NULL THEN
                MATUR_DATE - I_DATADATE
             END, --42存款剩余期限
             T.IS_ONLINE_ABLE, --43是否网上支付账户
             T.ADVANCE_DRAW_FLG, --44是否可提前支取
             T.C_DEPOSIT_TYPE, --45单位存款类型
             T.INTEREST_ACCURAL, --46应付利息
             T.INTEREST_ACCURAL_ITEM,--47应付利息科目
             T.ACCT_NAM, --48账户名称
             T.INTEREST_ACCURED,--49应计利息
             T.NEXT_RATE_DATE, --50下一付息日
             T.STABLE_DEP_TYPE,--51稳定存款分类
             T.O_ACCT_NUM --52外部账号，关联保证金 账号
        FROM PM_RSDATA.SMTMODS_L_ACCT_DEPOSIT T
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U
          ON U.CCY_DATE = D_DATADATE_CCY
         AND U.BASIC_CCY = T.CURR_CD --基准币种
         AND U.FORWARD_CCY = 'CNY' --折算币种
         AND U.DATA_DATE = I_DATADATE --chaged by liruiting 增加利率表数据日期
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE V
          ON V.CCY_DATE = D_DATADATE_CCY
         AND V.BASIC_CCY = T.CURR_CD --基准币种
         AND V.FORWARD_CCY = 'USD' --折算币种
         AND V.DATA_DATE = I_DATADATE --chaged by liruiting 增加利率表数据日期
       WHERE T.DATA_DATE = I_DATADATE;

    COMMIT;

     V_STEP_ID   := 3;
    V_STEP_DESC := '处理存款账户信息表_机构每日存款余额';
    V_STEP_FLAG := 0;
	sp_rsbp_etl_log(V_SYSTEM,V_PROCEDURE, V_STEP_ID,  V_ERRORCODE,  V_STEP_DESC,  II_DATADATE);
 
	--1
    INSERT INTO PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP2
      (ORG_NUM, --机构号
       ACCT_BALANCE_RMB, --存放存款余额(RMB)
       ACCT_BALANCE --存放存款余额(原币)
       )
      SELECT  
             T.ORG_NUM AS ORG_NUM, --机构号
             SUM(T.ACCT_BALANCE_RMB) AS ACCT_BALANCE_RMB, --存放存款余额(RMB)
             SUM(T.ACCT_BALANCE) ACCT_BALANCE --存放存款余额(原币)
        FROM PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP T
       WHERE SUBSTR(T.ACCT_TYPE, 1, 2) IN ('05', '06', '08')
             AND T.ACCT_BALANCE > 0
       GROUP BY T.ORG_NUM;

    COMMIT;

    --2
    INSERT INTO PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP2
      (ORG_NUM, --机构号
       ACCT_BALANCE_RMB, --存放存款余额(RMB)
       ACCT_BALANCE --存放存款余额(原币)
       )
      SELECT
            
             T.ORG_NUM AS ORG_NUM, --机构号
             SUM(T.ACCT_BALANCE_RMB) AS ACCT_BALANCE_RMB, --存放存款余额(RMB)
             SUM(T.ACCT_BALANCE) ACCT_BALANCE --存放存款余额(原币)
        FROM PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP T
       WHERE SUBSTR(T.ACCT_TYPE, 1, 2) IN ('07')
             AND T.MATUR_DATE IS NULL
             AND T.ACCT_BALANCE > 0
       GROUP BY T.ORG_NUM;

    COMMIT;
    --3
  
    INSERT INTO PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP2
      (ORG_NUM, --机构号
       ACCT_BALANCE_RMB, --存放存款余额(RMB)
       ACCT_BALANCE --存放存款余额(原币)
       )
      SELECT  
             A.ORG_NUM,
             SUM(A.BALANCE * U.CCY_RATE) AS ACCT_BALANCE_RMB,
             SUM(A.BALANCE) AS ACCT_BALANCE
        FROM PM_RSDATA.SMTMODS_L_ACCT_FUND_MMFUND A
       INNER JOIN PM_RSDATA.SMTMODS_L_CUST_C B ON B.DATA_DATE = I_DATADATE
                                AND A.CUST_ID = B.CUST_ID
        LEFT JOIN PM_RSDATA.SMTMODS_L_PUBL_RATE U ON U.CCY_DATE = A.DATA_DATE
                                   AND U.BASIC_CCY = A.CURR_CD --基准币种
                                   AND U.FORWARD_CCY = 'CNY' --折算币种
       WHERE A.DATA_DATE = I_DATADATE
             AND A.ACCT_TYP LIKE '201%'
             AND A.ACCT_TYP <> '20107'
             AND A.MATURE_DATE IS NULL
             AND (B.FINA_CODE LIKE 'F%' OR B.FINA_CODE = 'H00000' OR A.FOREIGN_EX_RESERVE_FLG = 'Y')
       GROUP BY A.ORG_NUM;

    COMMIT;
  
    --汇总
    INSERT INTO PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP3
      (DATA_DATE, --数据日期
       ORG_NUM, --机构号
       ACCT_BALANCE_RMB, --存放存款余额(RMB)
       ACCT_BALANCE --存放存款余额(原币)
       )
      SELECT  
             I_DATADATE AS DATA_DATE, --数据日期
             T.ORG_NUM AS ORG_NUM, --机构号
             SUM(T.ACCT_BALANCE_RMB) AS ACCT_BALANCE_RMB, --存放存款余额(RMB)
             SUM(T.ACCT_BALANCE) ACCT_BALANCE --存放存款余额(原币)
        FROM PM_RSDATA.CBRC_L_ACCT_DEPOSIT_TMP2 T
       GROUP BY T.ORG_NUM;

    COMMIT;

    V_STEP_DESC := V_PROCEDURE || '的业务逻辑全部处理完成';
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
				
    DBMS_OUTPUT.PUT_LINE('O_STATUS=0');
    DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=完成'); 
    ------------------------------------------------------------------

  END IF;

EXCEPTION
  WHEN OTHERS THEN
    V_ERRORCODE := SQLCODE;
    V_ERRORDESC := SUBSTR(SQLERRM, 1, 280);
    V_STEP_DESC := '发生异常。详细信息为，' || TO_CHAR(SQLCODE) ||
                   SUBSTR(SQLERRM, 1, 280);
				   
    DBMS_OUTPUT.PUT_LINE('O_STATUS=-1');
    DBMS_OUTPUT.PUT_LINE('O_STATUS_DEC=失败'); 
    --记录异常信息
    SP_RSBP_ETL_LOG(V_SYSTEM,V_PROCEDURE,
                V_STEP_ID,
                V_ERRORCODE,
                V_STEP_DESC,
                II_DATADATE);
     ROLLBACK;
   
END proc_cbrc_l_acct_deposit_tmp