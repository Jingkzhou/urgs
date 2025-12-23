DROP Procedure IF EXISTS `PROC_BSP_T_6_6_STZFXX` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_6_STZFXX"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：受托支付信息
      程序功能  ：加工受托支付信息
      目标表：T_6_6
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_6_STZFXX';
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

	DELETE FROM T_6_6 WHERE F060010 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	
	COMMIT;
	
   	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);													

	
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
   INSERT  INTO T_6_6  (
        F060001 , -- 01 协议ID
        F060002 , -- 02 借据ID
        F060011 , -- 03 机构ID
        F060003 , -- 04 受托支付金额
        F060004 , -- 05 受托支付日期
        F060005 , -- 06 受托支付对象账号
        F060006 , -- 07 受托支付对象户名
        F060007 , -- 08 受托支付对象行号
        F060008 , -- 09 受托支付对象行名
        F060012 , -- 10 币种
        F060009 , -- 11 备注
        F060010 , -- 12 采集日期
        DIS_DATA_DATE,
        DIS_BANK_ID,
        DEPARTMENT_ID

       )
    SELECT  
	       SUBSTR(B.ACCT_NUM,1,60)                    , -- 01 协议ID
	       B.LOAN_NUM                                 , -- 02 借据ID
		   substr(TRIM(C.FIN_LIN_NUM ),1,11)|| B.ORG_NUM    , -- 03 机构ID
		   A.DRAWDOWN_AMT                             , -- 04 受托支付金额
		   TO_CHAR(TO_DATE(A.DRAWDOWN_DT,'YYYYMMDD'),'YYYY-MM-DD')     , -- 05 受托支付日期
		   A.ACC_NO                                   , -- 06 受托支付对象账号
		   A.ACC_NAME                                 , -- 07 受托支付对象户名
		   A.BANK_NO                                  , -- 08 受托支付对象行号
		   A.BANK_NAME                                , -- 09 受托支付对象行名
		   B.CURR_CD                                  , -- 10 币种
		   B.REMARK                                   , -- 11 备注
	       TO_CHAR(P_DATE,'YYYY-MM-DD')               , -- 16 采集日期
	       TO_CHAR(P_DATE,'YYYY-MM-DD')               , -- 16 采集日期
           B.ORG_NUM,
           CASE  
           WHEN B.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN B.DEPARTMENTD ='公司金融' OR SUBSTR(B.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN B.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN B.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(B.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(B.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END AS TX
         FROM SMTMODS.L_ACCT_LOAN B -- 贷款借据信息表
        INNER JOIN SMTMODS.L_ACCT_LOAN_TRUSTEE A -- 受托支付补充信息表
           ON A.LOAN_NUM = B.LOAN_NUM
          AND A.DATA_DATE = I_DATE
         LEFT JOIN VIEW_L_PUBL_ORG_BRA C -- 机构表
           ON B.ORG_NUM = C.ORG_NUM
          AND C.DATA_DATE = I_DATE      
        WHERE B.DRAWDOWN_TYPE IN ('B','C')
          AND (B.ACCT_STS <> '3'
              OR B.LOAN_ACCT_BAL > 0 
              OR B.FINISH_DT =I_DATE)
          AND B.DATA_DATE = I_DATE
           AND NOT EXISTS(SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                WHERE A.DATA_DATE = I_DATE
                  AND A.WRITE_OFF_DATE < I_DATE 
                  AND A.LOAN_NUM = B.LOAN_NUM )
          and (B.LOAN_STOCKEN_DATE IS NULL OR B.LOAN_STOCKEN_DATE = I_DATE)  -- add by haorui 20250311 JLBA202408200012_关于新一代信贷管理系统增加不良资产收益权转让账务处理功能的需求
         AND A.DRAWDOWN_DT = I_DATE ; -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求,受托支付修改为每日增量
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


