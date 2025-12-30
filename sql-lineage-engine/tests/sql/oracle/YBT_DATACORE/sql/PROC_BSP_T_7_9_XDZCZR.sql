DROP Procedure IF EXISTS `PROC_BSP_T_7_9_XDZCZR` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_7_9_XDZCZR"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：表7.9信贷资产转让
      程序功能  ：加工表7.9信贷资产转让
      目标表：T_7_3
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	-- JLBA202409120001_关于一表通监管数据报送系统修改逻辑的需求_二期 20241128	
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
	SET P_PROC_NAME = 'PROC_BSP_T_7_9_XDZCZR';
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
	
	DELETE FROM T_7_9 WHERE G090018 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT  INTO T_7_9  
 (
  G090001  ,  -- 01 '协议ID'
  G090002  ,  -- 02 '机构ID'
  G090003  ,  -- 03 '借据ID'
  G090004  ,  -- 04 '转让价款入账账号'
  G090005  ,  -- 05 '资产转让方向'
  G090006  ,  -- 06 '资产转让方式'
  G090007  ,  -- 07 '转让贷款本金总额'
  G090008  ,  -- 08 '转让贷款利息总额'
  G090009  ,  -- 09 '资产类型'
  G090010  ,  -- 10 '核心交易日期'
  G090011  ,  -- 11 '核心交易时间'
  G090012  ,  -- 12 '对方账号'
  G090013  ,  -- 13 '对方户名'
  G090014  ,  -- 14 '对方账号行号'
  G090015  ,  -- 15 '对方行名'
  G090016  ,  -- 16 '币种'
  G090017  ,  -- 17 '交易对手已支付金额'
  G090018  ,  -- 18 '采集日期'
  DIS_DATA_DATE,
  DIS_BANK_ID,
  DEPARTMENT_ID 

)

 WITH L_ACCT_TRANSFER_TMP AS
     (SELECT A.*,
             ROW_NUMBER() OVER(PARTITION BY A.TRANS_CON_NUM ORDER BY A.TRANS_LOAN_AMT DESC) AS RN
        FROM SMTMODS.L_ACCT_TRANSFER A -- 信贷资产变动因素表
       WHERE A.DATA_DATE = I_DATE -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求,7.9调整为每日增量
	     AND A.TRANS_DATE = I_DATE
	    -- substr(a.DATA_DATE,1,4) = substr(I_DATE,1,4) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求,7.9调整为每日增量
         AND A.TX_TYPE NOT LIKE '行内机构划转%' )-- JLBA202409120001 20241128 与6.23一致
      -- TRANS_DATE = I_DATE
      -- AND (A.TRANS_CON_DUE_DATE = I_DATE ) OR A.TRANS_CON_DUE_DATE=TO_DATE('99991231','YYYYMMDD'))
              
    SELECT                       
    T1.TRANS_CON_NUM ,                                                              -- 01 '协议ID'
    T2.ORG_ID AS NBJGH,                       -- 02 '机构ID'
    B.LOAN_NUM ,                                                                    -- 03 '借据ID'
    T1.ENTER_ACCT_BANK_NUM ,                                                        -- 04 '转让价款入账账号'
    CASE WHEN T1.LOAN_TRAN_FLG = 'A' THEN '02' -- '转出'                                    
         WHEN T1.LOAN_TRAN_FLG = 'B' THEN '01' -- '转入'                                    
          END AS ZCZRFX,                                                            -- 05 '资产转让方向'
    CASE WHEN T1.LOAN_SCALE_FACTOR IN ('D' ,'E') THEN '01' --  '直接转让'                   
          WHEN T1.LOAN_SCALE_FACTOR = 'A' THEN '02' -- '信贷资产证券化'                    
          WHEN T1.LOAN_SCALE_FACTOR = 'F' THEN '03' -- 信贷资产收益权转让'           
          ELSE  '04'                     
           END AS ZCZRFS,                                                           -- 06 '资产转让方式'
    B.TRANS_LOAN_AMT AS ZRDKBJZE ,                                                  -- 07 '转让贷款本金总额'
    B.TRANS_LOAN_DATE AS ZRDKLXZE ,                                                 -- 08 '转让贷款利息总额'
    CASE
       WHEN SUBSTR(T3.ITEM_CD,1,6) = '130301' THEN '01' -- 个人贷款 ,             
       WHEN SUBSTR(T3.ITEM_CD,1,6) = '130302' THEN '02' -- 公司贷款
       END   AS ZCLX  ,                                                             -- 09 '资产类型'
    TO_CHAR(TO_DATE(T1.HXJYRQ,'YYYYMMDD'),'YYYY-MM-DD'),                                                                     -- 10 '核心交易日期'
    T1.HXJYSJ ,                                                                     -- 11 '核心交易时间'
    T1.OPPO_PTY_ACCT_NUM  ,                                                         -- 12 '对方账号'
    -- T1.OPPO_PTY_ACCT_NAME ,                                                         -- 13 '对方户名'
    T1.OPPO_PTY_NAME ,                                                              -- 13 '对方户名'JLBA202409120001 20241128
    T1.OPPO_PTY_BANK_CD   ,                                                         -- 14 '对方账号行号'
    T1.OPPO_PTY_BANK_NAME ,                                                         -- 15 '对方行名'
    T1.CURR_CD  ,                                                                   -- 16 '币种'
    T1.PAID_AMT ,                                                                   -- 17 '交易对手已支付金额'
    TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),                               -- 18 '采集日期'
    TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),                               -- 18 '采集日期'
    T1.ORG_NUM,
    CASE  
     WHEN T3.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
     WHEN T3.DEPARTMENTD ='公司金融' OR SUBSTR(T3.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
     WHEN T3.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
     WHEN T3.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
     WHEN SUBSTR(T3.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
     WHEN SUBSTR(T3.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
      END AS TX 
    FROM L_ACCT_TRANSFER_TMP T1 -- 信贷资产变动因素表_临时表
   INNER JOIN SMTMODS.L_ACCT_TRANSFER_RELATION B
      ON T1.TRANS_CON_NUM = B.TRANS_CON_NUM
     AND T1.DATA_DATE = b.DATA_DATE
   INNER JOIN SMTMODS.L_ACCT_LOAN T3 
      ON T3.LOAN_NUM =B.LOAN_NUM
     AND T3.DATA_DATE = I_DATE
   INNER JOIN VIEW_L_PUBL_ORG_BRA T2 -- 机构表
      ON T3.ORG_NUM = T2.ORG_NUM
     AND T2.DATA_DATE = I_DATE
   WHERE T1.RN = 1 ;
	   
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


