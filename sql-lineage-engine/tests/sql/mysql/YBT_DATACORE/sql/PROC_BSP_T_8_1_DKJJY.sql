DROP Procedure IF EXISTS `PROC_BSP_T_8_1_DKJJY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_1_DKJJY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：贷款借据
      程序功能  ：加工贷款借据
      目标表：T_8_1
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
	 /*需求编号：JLBA202507300010 上线日期：2025-09-29，修改人：姜俐锋，提出人：信贷新增产品 修改原因：关于新一代信贷管理系统新增线上微贷板块的需求 */
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
   SELECT OI_RETCODE,'|',OI_REMESSAGE;
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
	SET P_PROC_NAME = 'PROC_BSP_T_8_1_DKJJY';
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
	
	DELETE FROM T_8_1 WHERE H010029 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT INTO T_8_1
 ( 
       H010001   , -- 01 '借据ID'
	   H010010   , -- 10 '借款余额'
	   H010019   , -- 19 '贷款状态'
	   H010020   , -- 20 '减值准备'
	   H010021   , -- 21 '贷款利率'
	   H010025   , -- 25 '贷款逾期标识'
	   H010029   , -- 29 '采集日期'
	   DIS_DATA_DATE,
       DIS_BANK_ID,
       DEPARTMENT_ID
	   
)
  SELECT 
        -- T.LOAN_NUM            , -- 01 '借据ID'
        CASE WHEN SUBSTR(t.ITEM_CD, 1, 6) in ('130101', '130102', '130104', '130105') THEN SUBSTR(t.ACCT_NUM || NVL(t.DRAFT_RNG,''),1,60)
             ELSE T.LOAN_NUM
             END AS H010001        , -- 01 '借据ID'   20250311
        T.LOAN_ACCT_BAL       , -- 10 '借款余额'
        CASE WHEN T.ACCT_STS = '1' THEN '01'  -- 正常
             WHEN T.ACCT_STS = '2' THEN '05'  -- 逾期   
             WHEN T.ACCT_STS = '3' THEN '04'  -- 结清
             WHEN T.ACCT_STS = '9' THEN '06'  -- 其他
			 WHEN T.LOAN_STOCKEN_DATE IS NOT NULL THEN '03'  -- 转让 add by haorui 20250311 JLBA202408200012 信贷不良资产收益权转让
             END              , -- 19 '贷款状态' 缺  核销 转让
        T.GENERAL_RESERVE     , -- 20 '减值准备'
        T.REAL_INT_RAT        , -- 21 '贷款利率'
        CASE 
         WHEN (T.OD_FLG = 'Y' OR T.ACCT_STS ='2') THEN '1'
         WHEN T.OD_FLG = 'N' THEN '0'
          ELSE '0'
          END , -- 25 '贷款逾期标识'
        TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 29 '采集日期'
        TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 29 '采集日期'
        T.ORG_NUM,
        CASE  
           WHEN T.DEPARTMENTD ='信用卡' THEN '0098KG' -- 吉林银行总行卡部(信用卡中心管理)(0098KG)
           WHEN (T.DEPARTMENTD ='公司金融' OR SUBSTR(T.ITEM_CD,1,6) IN ('130601','130602')) THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB) 
           WHEN T.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END AS TX
         FROM SMTMODS.L_ACCT_LOAN T 
         LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T6 -- 贷款合同信息表
           ON T.ACCT_NUM = T6.CONTRACT_NUM
          AND T6.DATA_DATE = I_DATE
        WHERE T.DATA_DATE = I_DATE
		-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
        AND  (T.ACCT_STS <> '3'  
              OR T.LOAN_ACCT_BAL > 0   
              OR  T.FINISH_DT  >= SUBSTR(I_DATE,1,4)||'0101' 
              OR (T.INTERNET_LOAN_FLG = 'Y' AND T.FINISH_DT >= TO_CHAR(TO_DATE(SUBSTR(I_DATE,1,4)||'0101','YYYYMMDD')-1,'YYYYMMDD'))   -- 互联网贷款数据晚一天下发，上月末数据当月取
              OR (T.CP_ID='DK001000100041' AND T.FINISH_DT >= TO_CHAR(TO_DATE(SUBSTR(I_DATE,1,4)||'0101','YYYYMMDD')-1,'YYYYMMDD')) -- [20250929][姜俐锋][JLBA202507300010][信贷新增产品]: 同网贷部分数据处理方式
              )
       AND NOT EXISTS(SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                WHERE A.DATA_DATE = I_DATE
                  AND A.WRITE_OFF_DATE < I_DATE 
                  AND A.LOAN_NUM = T.LOAN_NUM )
        AND NVL(T6.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据   
		-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
        and (T.LOAN_STOCKEN_DATE IS NULL OR T.LOAN_STOCKEN_DATE >= SUBSTR(I_DATE,1,4)||'0101' )   -- add by haorui 20250311 JLBA202408200012 资产未转让
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

