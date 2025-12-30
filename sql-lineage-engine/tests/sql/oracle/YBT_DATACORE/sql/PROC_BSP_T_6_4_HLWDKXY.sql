DROP Procedure IF EXISTS `PROC_BSP_T_6_4_HLWDKXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_4_HLWDKXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：互联网贷款协议
      程序功能  ：加工互联网贷款协议
      目标表：T_6_4
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_4_HLWDKXY';
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
	
	DELETE FROM T_6_4 WHERE F040016 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	
	COMMIT;
   														
    
    #3插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
   INSERT  INTO T_6_4  (
         F040001 , -- 01 机构ID
         F040002 , -- 02 协议ID
         F040003 , -- 03 借据ID
         F040004 , -- 04 合作协议ID
         F040005 , -- 05 业务模式
         F040006 , -- 06 合作方负有担保责任的金额
         F040007 , -- 07 合作方出资发放贷款金额
         F040008 , -- 08 本机构出资发放贷款金额
         F040009 , -- 09 客户数据授权书编号
         F040010 , -- 10 授权生效日期
         F040011 , -- 11 授权终止日期
         F040012 , -- 12 提供部分风险评价服务合作机构名称
         F040013 , -- 13 提供担保增信合作机构名称
         F040015 , -- 14 备注
         F040016 ,  -- 15 采集日期
         DIS_DATA_DATE,
         DIS_BANK_ID,
         DEPARTMENT_ID 
        )
          SELECT 
             SUBSTR(TRIM(T4.FIN_LIN_NUM),1,11)|| T1.ORG_NUM   , -- 01 机构ID
		     T1.ACCT_NUM                        , -- 02 协议ID
		     T1.LOAN_NUM                        , -- 03 借据ID
		     T1.COOP_AGREEN_NO                  , -- 04 合作协议ID
		     CASE 
               WHEN T1.COOP_TYPE ='B'   -- 共同出资
               AND  T3.ORG_ROLE ='A'  -- 主要作为资金提供方
               THEN '01' --  本机构主要作为资金提供方共同出资发放贷款
               WHEN T1.COOP_TYPE ='B'   -- 共同出资
               AND  T3.ORG_ROLE ='B'  -- 主要作为信息提供方
               THEN '02' --  本机构主要作为信息提供方共同出资发放贷款
               ELSE NULL  -- 03	银行单独出资合作发放互联网贷款
             END                                , -- 05 业务模式
		     CASE WHEN t1.ACCT_NUM IS NOT NULL  then 
                 CASE WHEN T2.CURR_CD = 'CNY' AND T1.CURR_CD = 'CNY' THEN T1.TOTAL_LOAN_BAL/0.7*0.3
                      WHEN T2.CURR_CD <>'CNY' AND T1.CURR_CD = 'CNY' THEN T1.TOTAL_LOAN_BAL/0.7*0.3 /U.CCY_RATE
                      WHEN T2.CURR_CD <>'CNY' AND T1.CURR_CD <>'CNY' THEN T1.TOTAL_LOAN_BAL/0.7*0.3 *U1.CCY_RATE /U.CCY_RATE
                      WHEN T2.CURR_CD = 'CNY' AND T1.CURR_CD <>'CNY' THEN T1.TOTAL_LOAN_BAL/0.7*0.3 *U1.CCY_RATE
                       END   
              ELSE
              0 end  AS COOPER_LIABLE_AMT     , -- 06合作方负有担保责任的金额       east逻辑同步ybt
		     T2.CONTRACT_AMT / 0.7 * 0.3        , -- 07 合作方出资发放贷款金额
		     T2.CONTRACT_AMT                    , -- 08 本机构出资发放贷款金额
		     T2.CONTRACT_NUM                    , -- 09 客户数据授权书编号
		     TO_CHAR(TO_DATE(T2.CONTRACT_EFF_DT,'YYYYMMDD'),'YYYY-MM-DD')   , -- 10 授权生效日期
		     NVL(TO_CHAR(TO_DATE(T2.CONTRACT_EXP_DT,'YYYYMMDD'),'YYYY-MM-DD') ,'9999-12-31')  , -- 11 授权终止日期
		     CASE WHEN T1.CREDIT_ORG_TYPE='C' THEN T1.FXFWJGMC ELSE NULL END , -- 12 提供部分风险评价服务合作机构名称
             CASE 
              WHEN C.COOP_CUST_NAM LIKE '马上消费金融股%'  THEN  '陕西昊悦融资担保有限公司'
              WHEN C.COOP_CUST_NAM LIKE '深圳前海微众银行%'THEN  NULL 
              WHEN C.COOP_CUST_NAM LIKE '江苏苏宁银行%' THEN '众安在线财产保险股份有限公司'
               END AS TGDBZXHZJGMC, -- 13 提供担保增信合作机构名称
		     T1.REMARKS                         , -- 14 备注
		     TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,   -- 15 采集日期
		     TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,   -- 15 采集日期
             T1.ORG_NUM,
            CASE  
            WHEN T5.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
            WHEN T5.DEPARTMENTD ='公司金融' OR SUBSTR(T5.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
            WHEN T5.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
            WHEN T5.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
            WHEN SUBSTR(T5.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
            WHEN SUBSTR(T5.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
            END AS TX
       FROM SMTMODS.L_ACCT_INTERNET_LOAN T1 -- 互联网贷款业务信息表
	  INNER JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T2 -- 贷款合同信息表
	     ON T1.ACCT_NUM = T2.CONTRACT_NUM
        AND T2.DATA_DATE = I_DATE
       LEFT JOIN SMTMODS.L_REC_CUST_INTERNET_LOAN T3
         ON T1.CUST_ID=T3.CUST_ID
        AND T3.DATA_DATE = I_DATE
        and t1.COOP_CUST_ID= t3.COOP_CUST_ID 
       LEFT JOIN VIEW_L_PUBL_ORG_BRA T4 -- 机构表
         ON T1.ORG_NUM = T4.ORG_NUM
        AND T4.DATA_DATE = I_DATE
       LEFT JOIN SMTMODS.L_ACCT_LOAN T5 -- 机构表
         ON T1.LOAN_NUM = T5.LOAN_NUM 
        AND t5.DATA_DATE = I_DATE
       LEFT JOIN SMTMODS.L_PUBL_RATE  U
         ON U.BASIC_CCY = T1.CURR_CD -- 基准币种
        AND U.CCY_DATE = I_DATE
        AND U.FORWARD_CCY='CNY'   
       LEFT JOIN SMTMODS.L_PUBL_RATE  U1
         ON U1.BASIC_CCY = T2.CURR_CD -- 基准币种
        AND U1.CCY_DATE = I_DATE
        AND U1.FORWARD_CCY='CNY'
       LEFT JOIN SMTMODS.L_AGRE_COOPER_LOAN A 
         ON t1.COOP_AGREEN_NO = a.COOP_AGREEN_NO
        AND a.DATA_DATE= I_DATE 
       LEFT JOIN SMTMODS.L_CUST_COOP_AGEN C -- 合作机构信息表
         ON A.COOP_CUST_ID = C.COOP_CUST_ID
        AND C.DATA_DATE = I_DATE 
      WHERE T1.DATA_DATE = I_DATE 
        and T2.INTERNET_LOAN_TAG = 'Y'    -- east逻辑同步ybt
        AND NVL(T2.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据
        AND  (T5.ACCT_STS <> '3'
              OR T5.LOAN_ACCT_BAL > 0 
			  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
              OR (T5.FINISH_DT  >= SUBSTR(I_DATE,1,4)||'0101' )
              OR (T2.INTERNET_LOAN_TAG = 'Y' AND T5.FINISH_DT =  TO_CHAR(TO_DATE( SUBSTR(I_DATE,1,4)||'0101' , 'YYYYMMDD')  - 1,'YYYYMMDD') ) --  同步east逻辑
              ) 
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


