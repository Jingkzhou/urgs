DROP Procedure IF EXISTS `PROC_BSP_T_6_5_YTDKXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_5_YTDKXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：银团贷款协议
      程序功能  ：加工银团贷款协议
      目标表：T_6_5
      源表  ：
      创建人  ：87V
      创建日期  ：20240110
      版本号：V0.0.1 
  ******/
	 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
  #声明变量
  DECLARE P_DATE   		DATE;			#数据日期
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_5_YTDKXY';
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
	
	TRUNCATE TABLE TMP_6_5_YTDK;
	DELETE FROM T_6_5 WHERE F050014 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	
	COMMIT;
	
   	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);													
    
	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '临时表插入数据';
	
	INSERT INTO TMP_6_5_YTDK
    (ACCT_NUM, -- 合同号
     DRAWDOWN_AMT -- 放款金额
     )
    SELECT T2.ACCT_NUM AS ACCT_NUM, SUM(T2.DRAWDOWN_AMT) AS DRAWDOWN_AMT
      FROM SMTMODS.L_ACCT_LOAN T2 -- 贷款借据信息表
     WHERE T2.DATA_DATE = I_DATE
       AND EXISTS (SELECT 1
              FROM SMTMODS.L_AGRE_LOAN_CONTRACT T1 -- 贷款合同信息表
             WHERE T1.CONTRACT_NUM = T2.ACCT_NUM
               AND T1.DATA_DATE = I_DATE)
     GROUP BY T2.ACCT_NUM
	 ;
	  COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
   INSERT  INTO T_6_5  (
        F050001 , -- 01 协议ID
        F050016 , -- 02 机构ID
        F050002 , -- 03 牵头行行名
        F050003 , -- 04 牵头行行号
        F050004 , -- 05 参加行行名
        F050005 , -- 06 参加行行号
        F050006 , -- 07 代理行行名
        F050007 , -- 08 代理行行号
        F050008 , -- 09 银团成员类型
        F050009 , -- 10 银团贷款总金额
        F050010 , -- 11 承担贷款金额
        F050011 , -- 12 已发放银团贷款金额
        F050012 , -- 13 已发放银团贷款余额
        F050015 , -- 14 已发放承担银团贷款金额
        F050013 , -- 15 备注
        F050014 , -- 16 采集日期
        DIS_DATA_DATE,
        DIS_BANK_ID,
        DEPARTMENT_ID ,
        F050017
       )
    SELECT  
        T1.CONTRACT_NUM                         , -- 01 协议ID
        SUBSTR(TRIM(T5.FIN_LIN_NUM ),1,11)||T1.ORG_NUM  , -- 02 机构ID
		T2.HOST_BANK_NAME                       , -- 03 牵头行行名
		T2.HOST_BANK_CODE                       , -- 04 牵头行行号
		T6.ORG_NAM                              , -- 05 参加行行名
        T6.ACCOUNTBANK                          , -- 06 参加行行号
		T2.AGEN_BANK_NAME                       , -- 07 代理行行名
		T2.AGEN_BANK_CODE                       , -- 08 代理行行号
		CASE 
		 WHEN T1.CP_ID = 'DK001000500001' THEN '01'
		 WHEN T1.CP_ID = 'DK001000500002' THEN '03'
		END AS CYLX                             , -- 09 银团成员类型 
		T2.APPLY_AMT                            , -- 10 银团贷款总金额
		nvl(T2.ASSUMES_AMT ,t1.CONTRACT_AMT)    , -- 11 承担贷款金额
		T2.DROWDOWN_AMT                         , -- 12 已发放银团贷款金额
		T2.APPLY_AMT - T2.DROWDOWN_AMT          , -- 13 已发放银团贷款余额
		T3.DRAWDOWN_AMT                         , -- 14 已发放承担银团贷款金额
		T1.REMARK                               , -- 15 备注
		TO_CHAR(TO_DATE(T1.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 16 采集日期
		TO_CHAR(TO_DATE(T1.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 16 采集日期
		T1.ORG_NUM ,
		'0098JR' , -- 公司金融部(0098JR)
		t1.CURR_CD
    FROM SMTMODS.L_AGRE_LOAN_CONTRACT T1 -- 贷款合同信息表
      LEFT JOIN SMTMODS.L_AGRE_LOAN_SYNDICATEDLOAN T2 -- 银团贷款补充信息表
        ON T1.CONTRACT_NUM = T2.CONTRACT_NUM
       AND T2.DATA_DATE = I_DATE
      LEFT JOIN TMP_6_5_YTDK T3 -- 贷款借据信息表(临时表)
        ON T1.CONTRACT_NUM = T3.ACCT_NUM
      LEFT JOIN VIEW_L_PUBL_ORG_BRA T5 -- 机构表
        ON T1.ORG_NUM = T5.ORG_NUM
       AND T5.DATA_DATE = I_DATE     
     LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T6 -- 机构表 
        ON T1.ORG_NUM = T6.ORG_NUM
       AND T6.DATA_DATE = I_DATE 
     WHERE T1.SYNDICATEDLOAN_FLG = 'Y'
       AND T1.DATA_DATE = I_DATE
       AND (T1.ACCT_STS_SUB<>'D' OR -- 终结
           T1.CONTRACT_EXP_DT >= SUBSTR(I_DATE,1,4)||'0101' ) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
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


