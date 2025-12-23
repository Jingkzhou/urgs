DROP Procedure IF EXISTS `PROC_BSP_T_6_16_RZZLXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_16_RZZLXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：表6.16融资租赁协议
      程序功能  ：加工表6.16融资租赁协议
      目标表：T_6_16
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	/*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_16_RZZLXY';
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
	
	DELETE FROM T_6_16 WHERE F160028 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');										
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT INTO T_6_16
 (
     F160001   , -- 01  '协议ID'
	 F160002   , -- 02  '机构ID'
	 F160003   , -- 03  '融资租赁类型'
	 F160004   , -- 04  '融资租赁方式'
	 F160005   , -- 05  '租赁标的物'
	 F160006   , -- 06  '承租人编号'
	 F160007   , -- 07  '承租人名称'
	 F160008   , -- 08  '承租人账号'
	 F160009   , -- 09  '承租人开户行名称'
	 F160010   , -- 10  '协议币种'
	 F160011   , -- 11  '合同金额'
	 F160012   , -- 12  '合同起始日期'
	 F160013   , -- 13  '合同到期日期'
	 F160014   , -- 14  '租赁公司名称'
	 F160015   , -- 15  '租赁公司证件类型'
     F160016   , -- 16  '租赁公司证件号码'
     F160017   , -- 17  '手续费金额'
     F160018   , -- 18  '手续费币种'
     F160019   , -- 19  '保证金账号'
     F160020   , -- 20  '保证金币种'
     F160021   , -- 21  '保证金金额'
     F160022   , -- 22  '保证金比例'
     F160023   , -- 23  '重点产业标识'
     F160024   , -- 24  '经办员工ID'
     F160025   , -- 25  '审查员工ID'
     F160026   , -- 26  '审批员工ID'
     F160027   , -- 27  '备注'
     F160028   , -- 28  '采集日期'
     DIS_DATA_DATE , -- 装入数据日期
     DIS_BANK_ID   , -- 机构号
     DIS_DEPT      ,
     DEPARTMENT_ID  -- 业务条线

 )

   SELECT  
          t.LOAN_NUM                 , -- 01  '协议ID'
          ORG.ORG_ID                 , -- 02  '机构ID'
          a.LEASE_TYPE               , -- 03  '融资租赁类型'
          A.RZZLFS                   , -- 04  '融资租赁方式'
          a.SUBJECT_NAME             , -- 05  '租赁标的物'
          A.CZRBH                    , -- 06  '承租人编号'
          A.CZRMC                    , -- 07  '承租人名称'
          A.CZRZH                    , -- 08  '承租人账号'
          A.CZRKHXMC                 , -- 09  '承租人开户行名称'
          t.CURR_CD                  , -- 10  '协议币种'
          b.CONTRACT_AMT             , -- 11  '合同金额'
          TO_CHAR(TO_DATE(a.CONTRACT_START_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 12  '合同起始日期'
          TO_CHAR(TO_DATE(a.CONTRACT_MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 13  '合同到期日期'
          a.LEASE_COMPANY            , -- 14  '租赁公司名称'
          a.LEASE_ID_TYPE            , -- 15  '租赁公司证件类型'
          a.LEASE_ID_NO              , -- 16  '租赁公司证件号码'
          a.FEE_AMT                  , -- 17  '手续费金额'
          a.FEE_CURR                 , -- 18  '手续费币种'
          t.SECURITY_ACCT_NUM        , -- 19  '保证金账号'
          t.SECURITY_CURR            , -- 20  '保证金币种'
          t.SECURITY_AMT             , -- 21  '保证金金额'
          t.SECURITY_RATE            , -- 22  '保证金比例'
          NVL(INDUST_RSTRUCT_FLG,'0') || DECODE(INDUST_TRAN_FLG,'1','1','2','0','0') || REPLACE(NVL(INDUST_STG_TYPE,'0'),'#','0')
                                     , -- 23  '重点产业标识'
          T.JBYG_ID                  , -- 24  '经办员工ID'
          T.SZYG_ID                  , -- 25  '审查员工ID'
          T.SPYG_ID                  , -- 26  '审批员工ID'
          NULL                       , -- 27  '备注'
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 28  '采集日期'
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
		  T.ORG_NUM ,                                       -- 机构号
		  null,
		  ''
    FROM smtmods.L_ACCT_LOAN t -- 贷款借据信息表
    INNER JOIN smtmods.L_ACCT_LOAN_LEASE a -- 融资租赁补充信息表 -- 此表集市无加工逻辑
        ON  t.loan_num = a.loan_num
        AND a.data_date = I_DATE
    LEFT JOIN  smtmods.L_AGRE_LOAN_CONTRACT b -- 贷款合同信息表
        ON t.acct_num = b.contract_num
        AND b.data_date = I_DATE
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON T.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
    WHERE t.data_date = I_DATE  
	and ( T.ACCT_STS='1' /* 账户状态 1-正常*/ or  A.CONTRACT_MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101' ) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
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


