DROP Procedure IF EXISTS `PROC_BSP_T_9_4_SYDJ` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_9_4_SYDJ"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN
/******
      程序名称  ：商业单据
      程序功能  ：加工商业单据
      目标表：T_9_4
      源表  ：
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
  -- JLBA202411070004_关于一表通监管数据报送系统修改逻辑的需求
  /*需求编号：JLBA202509280009 上线日期：2025-10-28，修改人：巴启威，提出人：吴大为 修改原因：关于一表通监管数据报送系统修改逻辑的需求 */
  #声明变量
  DECLARE P_DATE    DATE; #数据日期
  DECLARE P_PROC_NAME   VARCHAR(200); #存储过程名称
  DECLARE P_STATUS   INT;   #执行状态
  DECLARE P_START_DT   DATETIME; #日志开始日期
  DECLARE P_END_TIME   DATETIME; #日志结束日期
  DECLARE P_SQLCDE VARCHAR(200); #日志错误代码
  DECLARE P_STATE   VARCHAR(200); #日志状态代码
  DECLARE P_SQLMSG VARCHAR(2000); #日志详细信息
  DECLARE P_STEP_NO    INT; #日志执行步骤
  DECLARE P_DESCB   VARCHAR(200); #日志执行步骤描述
  DECLARE BEG_MON_DT  VARCHAR(8); #月初
  DECLARE BEG_QUAR_DT  VARCHAR(8); #季初
  DECLARE BEG_YEAR_DT  VARCHAR(8); #年初
  DECLARE LAST_MON_DT   VARCHAR(8); #上月末
  DECLARE LAST_QUAR_DT  VARCHAR(8); #上季末
  DECLARE LAST_YEAR_DT  VARCHAR(8); #上年末
  DECLARE LAST_DT   VARCHAR(8); #上日
  DECLARE FINISH_FLG    VARCHAR(8); #完成标志  
  #声明异常
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
   GET DIAGNOSTICS CONDITION 1 P_SQLCDE = GBASE_ERRNO,P_SQLMSG = MESSAGE_TEXT,P_STATE = RETURNED_SQLSTATE;
   SET P_STATUS = -1;
   SET P_START_DT = NOW();
   SET P_STEP_NO = P_STEP_NO + 1;
   SET P_DESCB = '程序异常';
   CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
   SET OI_RETCODE = P_STATUS; 
   SET OI_REMESSAGE = P_DESCB || ':' || P_SQLCDE || ' - ' || P_SQLMSG;
   SELECT OI_RETCODE,'|',OI_REMESSAGE; 
  END;
  
    #变量初始化
 SET P_DATE = TO_DATE(I_DATE,'YYYYMMDD'); 
 SET BEG_MON_DT = SUBSTR(I_DATE,1,6) || '01'; 
 SET BEG_QUAR_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY') || TRIM(TO_CHAR(QUARTER(TO_DATE(I_DATE,'YYYYMMDD')) * 3 - 2,'00')) || '01'; 
 SET BEG_YEAR_DT = SUBSTR(I_DATE,1,4) || '0101'; 
    SET LAST_MON_DT = TO_CHAR(TO_DATE(BEG_MON_DT,'YYYYMMDD') - 1,'YYYYMMDD'); 
    SET LAST_QUAR_DT = TO_CHAR(TO_DATE(BEG_QUAR_DT,'YYYYMMDD') - 1,'YYYYMMDD'); 
    SET LAST_YEAR_DT = TO_CHAR(TO_DATE(BEG_YEAR_DT,'YYYYMMDD') - 1,'YYYYMMDD'); 
 SET LAST_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') - 1,'YYYYMMDD');  
 SET P_PROC_NAME = 'PROC_BSP_T_9_4_SYDJ';
 SET OI_RETCODE = 0;
 SET P_STATUS = 0;
 SET P_STEP_NO = 0;
 SET OI_RETCODE = 0;
 
    #1.过程开始执行
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = '过程开始执行';
  
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB); 


    #2.清除数据
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = '清除数据';
 
 DELETE FROM YBT_DATACORE.T_9_4 WHERE J040008 = TO_CHAR(P_DATE,'YYYY-MM-DD');
 COMMIT;
 DELETE FROM YBT_DATACORE.T_9_4_TMP;
 COMMIT;
    
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = '数据插入';


 
INSERT INTO T_9_4_TMP
 
SELECT A.LOAN_NUM , A.LETT_CODE FROM SMTMODS.L_ACCT_TRAD_FIN A -- 贸易融资补充信息 
INNER JOIN  SMTMODS.L_ACCT_LOAN T -- 贷款借据信息表
ON A.LOAN_NUM = T.LOAN_NUM
AND T.DATA_DATE = I_DATE
WHERE A.DATA_DATE = I_DATE
AND T.MATURITY_DT >= I_DATE 
UNION ALL 
SELECT A.LOAN_NUM, A.LETT_CODE  FROM SMTMODS.L_ACCT_TRAD_FIN A -- 贸易融资补充信息 
INNER JOIN SMTMODS.L_ACCT_OBS_LOAN T -- 贷款表外信息表
ON A.ACCT_NUM = T.ACCT_NO
AND T.DATA_DATE = I_DATE
WHERE A.DATA_DATE = I_DATE 
AND T.MATURITY_DT >= I_DATE ;
COMMIT ;
 
 INSERT  INTO YBT_DATACORE.T_9_4  (
   J040001, -- 01.单据
   J040002, -- 02.机构
   J040003, -- 03.开票人客户
   J040004, -- 04.商业单据币种
   J040005, -- 05.商业单据金额
   J040006, -- 06.商业单据种类
   J040007, -- 07.备注
   J040008,  -- 08.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID,
   DEPARTMENT_ID  
) 


 SELECT 
case when T.VOUCHER_NUMBER is null then 
(CASE WHEN  REGEXP_LIKE( A.LOAN_NUM ,'^[0-9]+$')  ='1' THEN 'JLBS'||A.LOAN_NUM
 ELSE A.LOAN_NUM
 end)
 else T.VOUCHER_NUMBER 
 end AS LOAN_NUM, -- 01 单据ID 
SUBSTR(TRIM(nvl(B.FIN_LIN_NUM,'B0302H222010001') ),1,11)||T.ORG_NUM , -- 02 机构ID
 NULL , -- 03 开票人客户ID
 t.CON_CURR_CD, -- 04 商业单据币种
 T.VOUCHER_AMT, -- 05 商业发票金额
 CASE 
   WHEN T.VOUCHER_TYPE IN ('发票','发票、报关单、承保情况通知书') THEN  '01' -- 商业发票
   WHEN T.VOUCHER_TYPE IN ('增值税发票','增值税电子专用发票','增值税电子发票','增值税电子普通发票') THEN  '02' -- 02-增值税发票
   WHEN T.VOUCHER_TYPE ='货物单据' THEN  '11' -- 02-增值税发票
   WHEN T.VOUCHER_TYPE IN ('产品销售合同'
                            ,'合同'
                            ,'合同/发票'
                            ,'合同发票'
                            ,'合同发票报关单'
                            ,'合同发票提单'
                            ,'工程承包合同'
                            ,'投标合同'
                            ,'电子增值税专用发票'
                            ,'货物合同'
                            ,'贸易合同') THEN '00'
                            ELSE '00'
                            END , -- 06 商业单据种类
 t.REMARK , -- 07 备注
 TO_CHAR(P_DATE,'YYYY-MM-DD'),
 TO_CHAR(P_DATE,'YYYY-MM-DD'),
 A.ORG_NUM,
 '0098GJ'
FROM SMTMODS.L_TRANS_BACK_INFO T -- 交易背景信息表
INNER JOIN SMTMODS.L_ACCT_TRAD_FIN A -- 贸易融资补充信息 
ON T.CONTRACT_NUM = A.LOAN_NUM  -- 保函的业务编号关联贸易融资的借据号
AND T.DATA_DATE = A.DATA_DATE
INNER JOIN VIEW_L_PUBL_ORG_BRA B -- 机构表
ON T.ORG_NUM = B.ORG_NUM
AND B.DATA_DATE = I_DATE
WHERE T.DATA_DATE = I_DATE
AND T.BUSINESS_TYPE = '02' 
-- AND  T.COLL_DATE =  I_DATE ;
-- [20251028][巴启威][JLBA202509280009][吴大为]: 当年的失效数据全年报送
 AND SUBSTR(T.COLL_DATE,1,4)= SUBSTR(I_DATE,1,4);

   COMMIT;
  
  
  
 INSERT  INTO YBT_DATACORE.T_9_4  (
   J040001, -- 01.单据
   J040002, -- 02.机构
   J040003, -- 03.开票人客户
   J040004, -- 04.商业单据币种
   J040005, -- 05.商业单据金额
   J040006, -- 06.商业单据种类
   J040007, -- 07.备注
   J040008,  -- 08.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID,
   DEPARTMENT_ID  
) 


 
 SELECT 
 case when T.VOUCHER_NUMBER is null then 
(CASE WHEN  REGEXP_LIKE( A.LOAN_NUM ,'^[0-9]+$')  ='1' THEN 'JLBS'||A.LOAN_NUM
 ELSE A.LOAN_NUM
 end)
 else T.VOUCHER_NUMBER  || T.CONTRACT_NUM  -- JLBA202411070004 YBT_JYJ04-4 20241212
 end AS LOAN_NUM, -- 01 单据ID  
 SUBSTR(TRIM(nvl(B.FIN_LIN_NUM,'B0302H222010001')),1,11)||T.ORG_NUM , -- 02 机构ID
 NULL , -- 03 开票人客户ID
 t.CON_CURR_CD, -- 04 商业单据币种
 T.VOUCHER_AMT, -- 05 商业发票金额
 CASE 
   WHEN T.VOUCHER_TYPE IN ('发票','发票、报关单、承保情况通知书') THEN  '01' -- 商业发票
   WHEN T.VOUCHER_TYPE IN ('增值税发票','增值税电子专用发票','增值税电子发票','增值税电子普通发票') THEN  '02' -- 02-增值税发票
   WHEN T.VOUCHER_TYPE ='货物单据' THEN  '11' -- 02-增值税发票
   WHEN T.VOUCHER_TYPE IN ('产品销售合同'
                            ,'合同'
                            ,'合同/发票'
                            ,'合同发票'
                            ,'合同发票报关单'
                            ,'合同发票提单'
                            ,'工程承包合同'
                            ,'投标合同'
                            ,'电子增值税专用发票'
                            ,'货物合同'
                            ,'贸易合同') THEN '00'
                            ELSE '00'
                            END , -- 06 商业单据种类
 t.REMARK , -- 07 备注
 TO_CHAR(P_DATE,'YYYY-MM-DD'),
 TO_CHAR(P_DATE,'YYYY-MM-DD'),
 A.ORG_NUM,
 '0098GJ'
FROM SMTMODS.L_TRANS_BACK_INFO T -- 交易背景信息表
INNER JOIN SMTMODS.L_ACCT_TRAD_FIN A -- 贸易融资补充信息 
ON  T.CONTRACT_NUM = A.LETT_CODE  -- 交易背景的信用证的业务编号关联贸易融资的信用证编号
AND T.DATA_DATE = A.DATA_DATE
INNER JOIN VIEW_L_PUBL_ORG_BRA B -- 机构表
ON T.ORG_NUM = B.ORG_NUM
AND B.DATA_DATE = I_DATE
WHERE T.DATA_DATE = I_DATE
AND T.BUSINESS_TYPE = '03'
-- [20251028][巴启威][JLBA202509280009][吴大为]: 当年的失效数据全年报送
 AND SUBSTR(T.COLL_DATE,1,4)= SUBSTR(I_DATE,1,4);


    COMMIT;
    
  
  
 INSERT  INTO YBT_DATACORE.T_9_4  (
   J040001, -- 01.单据
   J040002, -- 02.机构
   J040003, -- 03.开票人客户
   J040004, -- 04.商业单据币种
   J040005, -- 05.商业单据金额
   J040006, -- 06.商业单据种类
   J040007, -- 07.备注
   J040008,  -- 08.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID,
   DEPARTMENT_ID  
) 
     
    
 SELECT 
case when T.VOUCHER_NUMBER is null then 
(CASE WHEN  REGEXP_LIKE( A.LOAN_NUM ,'^[0-9]+$')  ='1' THEN 'JLBS'||A.LOAN_NUM
 ELSE A.LOAN_NUM
 end)
 else T.VOUCHER_NUMBER ||A.LOAN_NUM
 end AS LOAN_NUM, -- 01 单据ID  
 SUBSTR(TRIM(nvl(B.FIN_LIN_NUM,'B0302H222010001') ),1,11)||T.ORG_NUM , -- 02 机构ID
 NULL , -- 03 开票人客户ID
 t.CON_CURR_CD, -- 04 商业单据币种
 T.VOUCHER_AMT, -- 05 商业发票金额
 CASE 
   WHEN T.VOUCHER_TYPE IN ('发票','发票、报关单、承保情况通知书') THEN  '01' -- 商业发票
   WHEN T.VOUCHER_TYPE IN ('增值税发票','增值税电子专用发票','增值税电子发票','增值税电子普通发票') THEN  '02' -- 02-增值税发票
   WHEN T.VOUCHER_TYPE ='货物单据' THEN  '11' -- 02-增值税发票
   WHEN T.VOUCHER_TYPE IN ('产品销售合同'
                            ,'合同'
                            ,'合同/发票'
                            ,'合同发票'
                            ,'合同发票报关单'
                            ,'合同发票提单'
                            ,'工程承包合同'
                            ,'投标合同'
                            ,'电子增值税专用发票'
                            ,'货物合同'
                            ,'贸易合同') THEN '00'
                            ELSE '00'
                            END , -- 06 商业单据种类
 t.REMARK , -- 07 备注
 TO_CHAR(P_DATE,'YYYY-MM-DD'),
 TO_CHAR(P_DATE,'YYYY-MM-DD'),
 A.ORG_NUM,
 '0098GJ'
FROM SMTMODS.L_TRANS_BACK_INFO T -- 交易背景信息表
INNER JOIN SMTMODS.L_ACCT_TRAD_FIN A -- 贸易融资补充信息 
ON  T.CONTRACT_NUM = A.ACCT_NUM
AND T.DATA_DATE = A.DATA_DATE
INNER JOIN VIEW_L_PUBL_ORG_BRA B -- 机构表
ON T.ORG_NUM = B.ORG_NUM
AND B.DATA_DATE = I_DATE
WHERE T.DATA_DATE = I_DATE
AND T.BUSINESS_TYPE = '00'
-- [20251028][巴启威][JLBA202509280009][吴大为]: 当年的失效数据全年报送
 AND SUBSTR(T.COLL_DATE,1,4)= SUBSTR(I_DATE,1,4)
;
 
    COMMIT;
    
  INSERT  INTO YBT_DATACORE.T_9_4  (
   J040001, -- 01.单据
   J040002, -- 02.机构
   J040003, -- 03.开票人客户
   J040004, -- 04.商业单据币种
   J040005, -- 05.商业单据金额
   J040006, -- 06.商业单据种类
   J040007, -- 07.备注
   J040008,  -- 08.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID,
   DEPARTMENT_ID  
)    
    
    SELECT 
case when T.VOUCHER_NUMBER is null then 
(CASE WHEN  REGEXP_LIKE( A.LOAN_NUM ,'^[0-9]+$')  ='1' THEN 'JLBS'||A.LOAN_NUM
 ELSE A.LOAN_NUM
 end)
 else T.VOUCHER_NUMBER || A.LOAN_NUM
 end AS LOAN_NUM, -- 01 单据ID 
 SUBSTR(TRIM(nvl(C.FIN_LIN_NUM,'B0302H222010001') ),1,11)||T.ORG_NUM , -- 02 机构ID
 NULL , -- 03 开票人客户ID
 t.CON_CURR_CD, -- 04 商业单据币种
 T.VOUCHER_AMT, -- 05 商业发票金额
 CASE 
   WHEN T.VOUCHER_TYPE IN ('发票','发票、报关单、承保情况通知书') THEN  '01' -- 商业发票
   WHEN T.VOUCHER_TYPE IN ('增值税发票','增值税电子专用发票','增值税电子发票','增值税电子普通发票') THEN  '02' -- 02-增值税发票
   WHEN T.VOUCHER_TYPE ='货物单据' THEN  '11' -- 02-增值税发票
   WHEN T.VOUCHER_TYPE IN ('产品销售合同'
                            ,'合同'
                            ,'合同/发票'
                            ,'合同发票'
                            ,'合同发票报关单'
                            ,'合同发票提单'
                            ,'工程承包合同'
                            ,'投标合同'
                            ,'电子增值税专用发票'
                            ,'货物合同'
                            ,'贸易合同') THEN '00'
                            ELSE '00'
                            END , -- 06 商业单据种类
 t.REMARK , -- 07 备注
 TO_CHAR(P_DATE,'YYYY-MM-DD'),
 TO_CHAR(P_DATE,'YYYY-MM-DD'),
 A.ORG_NUM,
 '0098GJ'  
    FROM SMTMODS.L_TRANS_BACK_INFO T -- 交易背景信息表
INNER JOIN SMTMODS.L_ACCT_LOAN B
ON T.CONTRACT_NUM = B.ACCT_NUM
AND B.DATA_DATE = I_DATE
INNER JOIN SMTMODS.L_ACCT_TRAD_FIN A -- 贸易融资补充信息 
ON B.LOAN_NUM = A.LOAN_NUM    -- 交易背景的信用证的业务编号关联贸易融资的信用证编号
AND T.DATA_DATE = A.DATA_DATE 
INNER JOIN VIEW_L_PUBL_ORG_BRA C -- 机构表
ON T.ORG_NUM = C.ORG_NUM
AND C.DATA_DATE = I_DATE
WHERE T.DATA_DATE = I_DATE
AND T.BUSINESS_TYPE = '00' -- 保理
-- [20251028][巴启威][JLBA202509280009][吴大为]: 当年的失效数据全年报送
AND SUBSTR(T.COLL_DATE,1,4)= SUBSTR(I_DATE,1,4)
AND NOT EXISTS (
SELECT 1 FROM 
SMTMODS.L_TRANS_BACK_INFO C -- 交易背景信息表
INNER JOIN SMTMODS.L_ACCT_TRAD_FIN D -- 贸易融资补充信息 
ON  C.CONTRACT_NUM = D.ACCT_NUM   -- 交易背景的信用证的业务编号关联贸易融资的信用证编号
AND C.DATA_DATE = D.DATA_DATE  
WHERE C.DATA_DATE = I_DATE
AND C.BUSINESS_TYPE = '00' 
AND T.CONTRACT_NUM = C.CONTRACT_NUM
)-- 保理  
 ;
 
     COMMIT;


 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB); 


    #4.过程结束执行
 SET P_START_DT = NOW();
 SET P_STEP_NO = P_STEP_NO + 1;
 SET P_DESCB = '过程结束执行';
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    SET OI_RETCODE = P_STATUS; 
    SET OI_REMESSAGE = P_DESCB;
    SELECT OI_RETCODE,'|',OI_REMESSAGE;


END $$

