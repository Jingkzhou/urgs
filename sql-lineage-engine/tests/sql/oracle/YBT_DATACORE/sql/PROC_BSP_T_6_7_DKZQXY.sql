DROP Procedure IF EXISTS `PROC_BSP_T_6_7_DKZQXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_7_DKZQXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：贷款展期协议
      程序功能  ：加工贷款展期协议
      目标表：T_6_7
      源表  ：
      创建人  ：87V
      创建日期  ：20240111
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_7_DKZQXY';
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

	DELETE FROM T_6_7 WHERE F070009 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	
	COMMIT;
	
   	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);													

	
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
   INSERT  INTO T_6_7  (
       F070001 , -- 01 协议ID
       F070002 , -- 02 借据ID
       F070010 , -- 03 机构ID
       F070003 , -- 04 展期次数
       F070004 , -- 05 被展期贷款的贷款协议号
       F070005 , -- 06 展期贷款的到期日期
       F070006 , -- 07 展期贷款的贷款金额
       F070007 , -- 08 展期贷款的贷款用途
       F070008 , -- 09 展期贷款的贷款利率
       F070009 , -- 10 采集日期
       DIS_DATA_DATE,
       DIS_BANK_ID,
       DEPARTMENT_ID

       )
    SELECT  
	       B.ACCT_NUM           , -- 01 协议ID
		   B.LOAN_NUM           , -- 02 借据ID
	       SUBSTR(TRIM(C.FIN_LIN_NUM ),1,11)|| B.ORG_NUM  , -- 03 机构ID
	       A.EXTENDTERM_NUM     , -- 04 展期次数 
           A.EXTENT_ACCT_NUM    , -- 05 被展期贷款的贷款协议号
           TO_CHAR(TO_DATE(A.EXTENT_END_DT,'YYYYMMDD'),'YYYY-MM-DD')   , -- 06 展期贷款的到期日期
           A.EXTENT_AMT         , -- 07 展期贷款的贷款金额
           B.USEOFUNDS          , -- 08 展期贷款的贷款用途
           NVL(B.REAL_INT_RAT,0)    , -- 09 展期贷款的贷款利率
           TO_CHAR(P_DATE,'YYYY-MM-DD') , -- 10 采集日期
           TO_CHAR(P_DATE,'YYYY-MM-DD') , -- 10 采集日期
           B.ORG_NUM,
           CASE  
           WHEN B.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN B.DEPARTMENTD ='公司金融' OR SUBSTR(B.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN B.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN B.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(B.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(B.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END  AS TX
    FROM  SMTMODS.L_ACCT_LOAN B -- 贷款借据信息表
    LEFT JOIN SMTMODS.L_ACCT_LOAN_EXTENDTERM A -- 受托支付补充信息表
      ON A.LOAN_NUM = B.LOAN_NUM
     AND B.DATA_DATE = I_DATE
    LEFT JOIN VIEW_L_PUBL_ORG_BRA C -- 机构表
      ON B.ORG_NUM = C.ORG_NUM
     AND C.DATA_DATE = I_DATE 
   INNER JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T6 -- 贷款合同信息表
      ON B.ACCT_NUM = T6.CONTRACT_NUM
     AND T6.DATA_DATE = I_DATE   
  
   WHERE A.DATA_DATE = I_DATE
   AND B.EXTENDTERM_FLG = 'Y'
   AND (SUBSTR(B.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103')  -- 票据
        OR SUBSTR(B.ITEM_CD,1,6) IN ('130302','130301')  -- 公司贷款 , 个人贷款
        OR SUBSTR(B.ITEM_CD,1,4) IN ('1305','1306','7140')
        or B.ITEM_CD IN ('30200203','30200101') )  --  贸易融资  ,垫款  ,银团   0620_LHY 科目为个人其他委托贷款不在6.7范围内 
   AND NVL(T6.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据
   AND (B.ACCT_STS <> '3' 
        OR B.LOAN_ACCT_BAL > 0 
		-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
        OR B.FINISH_DT >= SUBSTR(I_DATE,1,4)||'0101'
        OR (B.INTERNET_LOAN_FLG = 'Y' AND B.FINISH_DT = TO_CHAR(TO_DATE(SUBSTR(I_DATE,1,4)||'0101', 'YYYYMMDD') - 1 ,'YYYYMMDD')) 
        )  
     AND NOT EXISTS(SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                WHERE A.DATA_DATE = I_DATE
                  AND A.WRITE_OFF_DATE < I_DATE
                  AND A.LOAN_NUM = B.LOAN_NUM )  
     /* AND (T6.ACCT_STS <> '2' OR
                        T6.CONTRACT_EXP_DT >= I_DATE  OR 
                        (T6.CONTRACT_EXP_DT IS NULL AND T6.CONTRACT_ORIG_MATURITY_DT >= I_DATE ))*/   -- 根据校验公式YBT_JYF07-20修改，20241015添加6.2限制条件 by 87v
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


