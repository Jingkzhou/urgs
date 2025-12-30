DROP Procedure IF EXISTS `PROC_BSP_T_8_17_HKJH` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_17_HKJH"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：还款计划
      程序功能  ：加工还款计划表
      目标表：T_8_17
      源表  ：
      创建人  ：87v
      创建日期  ：20240509
      版本号：V0.0.1 
  ******/
	
  #声明变量
  DECLARE P_DATE   		DATE;			#数据日期
  DECLARE A_DATE   		VARCHAR(10);    #数据日期
  DECLARE P_PROC_NAME  	VARCHAR(200);	#存储过程名称
  DECLARE P_STATUS  	INT;  			#执行状态
  DECLARE P_START_DT  	DATETIME;		#日志开始日期
  DECLARE P_END_TIME  	DATETIME;		#日志结束日期
  DECLARE P_SQLCDE		VARCHAR(200);	#日志错误代码
  DECLARE P_STATE  		VARCHAR(200);	#日志状态代码
  DECLARE P_SQLMSG		VARCHAR(2000);	#日志详细信息
  DECLARE P_STEP_NO   	INT;			#日志执行步骤
  DECLARE P_DESCB  		VARCHAR(200);	#日志执行步骤描述
  DECLARE BEG_MON_DT 	VARCHAR(8);		#月初
  DECLARE BEG_QUAR_DT 	VARCHAR(8);		#季初
  DECLARE BEG_YEAR_DT 	VARCHAR(8);		#年初
  DECLARE LAST_MON_DT  	VARCHAR(8);		#上月末
  DECLARE LAST_QUAR_DT  VARCHAR(8);		#上季末
  DECLARE LAST_YEAR_DT  VARCHAR(8);		#上年末
  DECLARE LAST_DT  		VARCHAR(8);		#上日
  DECLARE FINISH_FLG    VARCHAR(8);		#完成标志  
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
   select OI_RETCODE,'|',OI_REMESSAGE;
  END;
  
    #变量初始化
	SET P_DATE = TO_DATE(I_DATE,'YYYYMMDD');	
	SET A_DATE = SUBSTR(I_DATE,1,4) || '-' || SUBSTR(I_DATE,5,2) || '-' || SUBSTR(I_DATE,7,2);		
	SET BEG_MON_DT = SUBSTR(I_DATE,1,6) || '01';	
	SET BEG_QUAR_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY') || TRIM(TO_CHAR(QUARTER(TO_DATE(I_DATE,'YYYYMMDD')) * 3 - 2,'00')) || '01'; 
	SET BEG_YEAR_DT = SUBSTR(I_DATE,1,4) || '0101';	
    SET LAST_MON_DT = TO_CHAR(TO_DATE(BEG_MON_DT,'YYYYMMDD') - 1,'YYYYMMDD');	
    SET LAST_QUAR_DT = TO_CHAR(TO_DATE(BEG_QUAR_DT,'YYYYMMDD') - 1,'YYYYMMDD');	
    SET LAST_YEAR_DT = TO_CHAR(TO_DATE(BEG_YEAR_DT,'YYYYMMDD') - 1,'YYYYMMDD');	
	SET LAST_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') - 1,'YYYYMMDD'); 			
	SET P_PROC_NAME = 'PROC_BSP_T_8_17_HKJH';
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
	
	DELETE FROM ybt_datacore.T_8_17 WHERE H170024 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT INTO ybt_datacore.T_8_17
   (
    H170001  , -- 01 '协议ID'
    H170002  , -- 02 '细分资产ID'
    H170003  , -- 03 '机构ID'
    H170004  , -- 04 '期数'
    H170005  , -- 05 '本金到期日'
    H170006  , -- 06 '应还本金'
    H170007  , -- 07 '实还本金'
    H170008  , -- 08 '利息到期日'
    H170009  , -- 09 '应还利息'
    H170010  , -- 10 '实还利息'
    H170011  , -- 11 '应计利息'
    H170024  , -- 12 '数据日期'
    DIS_DATA_DATE,
    DIS_BANK_ID   -- 机构号
   )
 
        SELECT 
		   T1.ACCT_NUM                                                  , -- 01 '协议ID'
           T1.LOAN_NUM                                                  , -- 02 '细分资产ID'
           ORG.ORG_ID                                                   , -- 03 '机构ID'
           T1.REPAY_SEQ                                                 , -- 04 '期数'
           TO_CHAR(TO_DATE(T1.DUE_DATE,'YYYYMMDD'),'YYYY-MM-DD')        , -- 05 '本金到期日'
           T1.OS_PPL                                                    , -- 06 '应还本金'
           T1.OS_PPL_PAID                                               , -- 07 '实还本金'
           TO_CHAR(TO_DATE(T1.DUE_DATE_INT,'YYYYMMDD'),'YYYY-MM-DD')    , -- 08 '利息到期日'
	       T1.INTEREST                                                  , -- 09 '应还利息'
           T1.INT_PAID                                                  , -- 10 '实还利息'
           T1.ACCU_INT                                                  , -- 11 '应计利息'
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')             , -- 12 '数据日期'
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')             ,
           T1.ORG_NUM
		   
      FROM SMTMODS.L_ACCT_LOAN_PAYM_SCHED T1 -- 贷款还款计划信息表

      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
             ON T1.ORG_NUM = ORG.ORG_NUM
            AND ORG.DATA_DATE = I_DATE

     WHERE T1.DATA_DATE = I_DATE
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
    select OI_RETCODE,'|',OI_REMESSAGE;
END $$

