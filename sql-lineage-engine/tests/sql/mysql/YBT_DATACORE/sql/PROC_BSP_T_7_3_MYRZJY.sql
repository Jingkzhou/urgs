DROP Procedure IF EXISTS `PROC_BSP_T_7_3_MYRZJY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_7_3_MYRZJY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：贸易融资交易
      程序功能  ：加工贸易融资交易
      目标表：T_7_3
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
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
	SET P_PROC_NAME = 'PROC_BSP_T_7_3_MYRZJY';
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
	
	DELETE FROM T_7_3 WHERE G030018 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
     INSERT  INTO T_7_3  
          (
    	   G030001  , -- 01 '交易ID'
           G030002  , -- 02 '协议ID'
           G030003  , -- 03 '分户账号'
           G030004  , -- 04 '客户ID'
           G030005  , -- 05 '交易机构ID'
           G030006  , -- 06 '核心交易日期'
           G030007  , -- 07 '核心交易时间'
           G030008  , -- 08 '交易类型'
           G030009  , -- 09 '交易金额'
           G030010  , -- 10 '币种'
           G030011  , -- 11 '业务余额'
           G030012  , -- 12 '对方账号'
           G030013  , -- 13 '对方户名'
           G030014  , -- 14 '对方账号行号'
           G030015  , -- 15 '对方行名'
           G030016  , -- 16 '经办员工ID'
           G030017  , -- 17 '授权员工ID'
           G030018  , -- 18 '采集日期'
           DIS_DATA_DATE,
           DIS_BANK_ID,
           DEPARTMENT_ID,
           DIS_DEPT
          )
    
     SELECT
         T1.LOAN_NUM        , -- 01 '交易ID'
         T1.ACCT_NUM        , -- 02 '协议ID'
        -- T1.LOAN_FHZ_NUM    ,-- 03 '分户账号'
         T1.LOAN_NUM        ,-- 03 '分户账号'
         T1.CUST_ID         , -- 04 '客户ID'
         SUBSTR(TRIM(C.FIN_LIN_NUM ),1,11)||T1.ORG_NUM  ,-- 05 '交易机构ID'
         TO_CHAR(TO_DATE(T1.DRAWDOWN_DT,'YYYYMMDD'),'YYYY-MM-DD')  , -- 06 '核心交易日期'
         -- T1.FKSJ            , -- 07 '核心交易时间'
         SUBSTR( T1.FKSJ , 1, 2) || ':' || SUBSTR( T1.FKSJ , 3, 2) || ':' ||SUBSTR( T1.FKSJ, 5, 2) AS JYSJ   , -- 07 '核心交易时间' 20241015
         '01'               , -- 08 '交易类型' 
         T1.DRAWDOWN_AMT    , -- 09 '交易金额'
         T1.CURR_CD         , -- 10 '币种'
         T1.LOAN_ACCT_BAL + T1.OD_LOAN_ACCT_BAL   , -- 11 '业务余额' 
         T1.LOAN_ACCT_NUM   , -- 12 '对方账号'
         B.CUST_NAM         , -- 13 '对方户名'
         CASE
             WHEN T1.ORG_NUM = '009808' THEN '313241066661'
             ELSE C.BANK_CD 
           END AS DFXH      , -- 14 '对方账号行号'
         CASE
             WHEN T1.ORG_NUM = '009808' THEN '吉林银行股份有限公司'
             ELSE C.ORG_NAM 
           END AS DFXM      , -- 15 '对方行名'
         t1.JBYG_ID         , -- 16 '经办员工ID'
         nvl(t1.SPYG_ID,'自动')       , -- 17 '授权员工ID'
         TO_CHAR(P_DATE,'YYYY-MM-DD') , -- 18 '采集日期'
         TO_CHAR(P_DATE,'YYYY-MM-DD') , -- 18 '采集日期'
         T1.ORG_NUM,
         CASE  
           WHEN T1.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T1.DEPARTMENTD ='公司金融' OR SUBSTR(T1.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T1.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T1.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T1.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END AS TX,
         '当天放款'
       FROM SMTMODS.L_ACCT_LOAN T1 -- 贷款借据信息表
       INNER JOIN SMTMODS.L_CUST_ALL B -- 全量客户信息表
          ON T1.CUST_ID = B.CUST_ID
         AND B.DATA_DATE = I_DATE
       INNER JOIN VIEW_L_PUBL_ORG_BRA C -- 机构表
          ON T1.ORG_NUM = C.ORG_NUM
         AND C.DATA_DATE = I_DATE
       WHERE T1.DATA_DATE = I_DATE
           AND T1.ITEM_CD LIKE '1305%' -- 贸易融资
           AND T1.DRAWDOWN_DT = I_DATE  -- 当天放款
           AND NOT EXISTS(SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                WHERE A.DATA_DATE = I_DATE
                  AND A.WRITE_OFF_DATE < I_DATE
                  AND A.LOAN_NUM = T1.LOAN_NUM
                 )
           and (T1.LOAN_STOCKEN_DATE IS NULL or T1.LOAN_STOCKEN_DATE = I_DATE)  ; -- add by haorui 20250311 JLBA202408200012 信贷不良资产收益权转让
   
    COMMIT;
   
    
  #4.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
    
      INSERT  INTO T_7_3  
          (
    	   G030001  , -- 01 '交易ID'
           G030002  , -- 02 '协议ID'
           G030003  , -- 03 '分户账号'
           G030004  , -- 04 '客户ID'
           G030005  , -- 05 '交易机构ID'
           G030006  , -- 06 '核心交易日期'
           G030007  , -- 07 '核心交易时间'
           G030008  , -- 08 '交易类型'
           G030009  , -- 09 '交易金额'
           G030010  , -- 10 '币种'
           G030011  , -- 11 '业务余额'
           G030012  , -- 12 '对方账号'
           G030013  , -- 13 '对方户名'
           G030014  , -- 14 '对方账号行号'
           G030015  , -- 15 '对方行名'
           G030016  , -- 16 '经办员工ID'
           G030017  , -- 17 '授权员工ID'
           G030018  , -- 18 '采集日期'
           DIS_DATA_DATE,
           DIS_BANK_ID,
           DEPARTMENT_ID,
           DIS_DEPT
          )
    SELECT 
         T.TX_NO            , -- 01 '交易ID'
         T1.ACCT_NUM        , -- 02 '协议ID'
       --  T1.LOAN_FHZ_NUM    ,-- 03 '分户账号'
         T1.LOAN_NUM        ,-- 03 '分户账号'
         T1.CUST_ID         , -- 04 '客户ID'
         SUBSTR(TRIM(C.FIN_LIN_NUM ),1,11)||T1.ORG_NUM  ,-- 05 '交易机构ID'
         TO_CHAR(TO_DATE(T.REPAY_DT,'YYYYMMDD'),'YYYY-MM-DD')  , -- 06 '核心交易日期'
         -- T.HKSJ             , -- 07 '核心交易时间'
         SUBSTR( T.HKSJ, 1, 2) || ':' || SUBSTR( T.HKSJ , 3, 2) || ':' ||SUBSTR(T.HKSJ, 5, 2)   AS jysj    , -- 07 '核心交易时间' 20241015
         '02'               , -- 08 '交易类型' 
         T.PAY_AMT          , -- 09 '交易金额'
         T1.CURR_CD         , -- 10 '币种'
         T1.LOAN_ACCT_BAL + T1.OD_LOAN_ACCT_BAL AS ZHYE   , -- 11 '业务余额' 
         T1.PAY_ACCT_NUM    , -- 12 '对方账号'
         B.CUST_NAM         , -- 13 '对方户名'
         CASE
             WHEN T1.ORG_NUM = '009808' THEN '313241066661'
             ELSE C.BANK_CD 
           END AS DFXH      , -- 14 '对方账号行号'
         CASE
             WHEN T1.ORG_NUM = '009808' THEN '吉林银行股份有限公司'
             ELSE C.ORG_NAM 
           END AS DFXM      , -- 15 '对方行名'
         t1.JBYG_ID         , -- 16 '经办员工ID'
         nvl(t1.SPYG_ID,'自动')       , -- 17 '授权员工ID'
         TO_CHAR(P_DATE,'YYYY-MM-DD') ,  -- 18 '采集日期'
         TO_CHAR(P_DATE,'YYYY-MM-DD') , -- 18 '采集日期'
         T1.ORG_NUM,
         CASE  
           WHEN T1.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T1.DEPARTMENTD ='公司金融' OR SUBSTR(T1.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T1.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T1.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T1.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END AS TX,
         '当天收回本金'  
      FROM SMTMODS.L_TRAN_LOAN_PAYM T -- 贷款还款明细信息表
     INNER JOIN SMTMODS.L_ACCT_LOAN T1 -- 贷款借据信息表
        ON T.LOAN_NUM = T1.LOAN_NUM
       AND T1.DATA_DATE = I_DATE
     INNER JOIN SMTMODS.L_CUST_ALL B -- 全量客户信息表
        ON T1.CUST_ID = B.CUST_ID
       AND B.DATA_DATE = I_DATE
     INNER JOIN SMTMODS.L_PUBL_ORG_BRA C -- 机构表
        ON T.ORG_NUM = C.ORG_NUM
       AND C.DATA_DATE = I_DATE
     WHERE T1.DATA_DATE = I_DATE
           AND T1.ITEM_CD LIKE '1305%' -- 贸易融资
           AND T.REPAY_DT = I_DATE
           AND T.PAY_AMT > 0
           AND NOT EXISTS(SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                WHERE A.DATA_DATE = I_DATE
                  AND A.WRITE_OFF_DATE < I_DATE
                  AND A.LOAN_NUM = T1.LOAN_NUM
                 )  -- 当天收回
       and (T1.LOAN_STOCKEN_DATE IS NULL or T1.LOAN_STOCKEN_DATE = I_DATE)  -- add by haorui 20250311 JLBA202408200012 信贷不良资产收益权转让
       ;
       COMMIT;
       
     
  #5.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';      
       
         INSERT  INTO T_7_3  
          (
    	   G030001  , -- 01 '交易ID'
           G030002  , -- 02 '协议ID'
           G030003  , -- 03 '分户账号'
           G030004  , -- 04 '客户ID'
           G030005  , -- 05 '交易机构ID'
           G030006  , -- 06 '核心交易日期'
           G030007  , -- 07 '核心交易时间'
           G030008  , -- 08 '交易类型'
           G030009  , -- 09 '交易金额'
           G030010  , -- 10 '币种'
           G030011  , -- 11 '业务余额'
           G030012  , -- 12 '对方账号'
           G030013  , -- 13 '对方户名'
           G030014  , -- 14 '对方账号行号'
           G030015  , -- 15 '对方行名'
           G030016  , -- 16 '经办员工ID'
           G030017  , -- 17 '授权员工ID'
           G030018  , -- 18 '采集日期'
           DIS_DATA_DATE,
           DIS_BANK_ID,
           DEPARTMENT_ID,
           DIS_DEPT
          )
       
      SELECT 
         T.TX_NO            , -- 01 '交易ID'
         T1.ACCT_NUM        , -- 02 '协议ID'
         -- T1.LOAN_FHZ_NUM    ,-- 03 '分户账号'
         T1.LOAN_NUM        ,-- 03 '分户账号'
         T1.CUST_ID         , -- 04 '客户ID'
         SUBSTR(TRIM(C.FIN_LIN_NUM ),1,11)||T1.ORG_NUM  ,-- 05 '交易机构ID'
         TO_CHAR(TO_DATE(T.REPAY_DT,'YYYYMMDD'),'YYYY-MM-DD')  , -- 06 '核心交易日期'
         -- T.HKSJ             , -- 07 '核心交易时间'
         SUBSTR( T.HKSJ, 1, 2) || ':' || SUBSTR( T.HKSJ , 3, 2) || ':' ||SUBSTR(T.HKSJ, 5, 2)   AS jysj  , -- 07 '核心交易时间' 20241015
         '03'               , -- 08 '交易类型' 
         T.PAY_INT_AMT          , -- 09 '交易金额'
         T1.CURR_CD         , -- 10 '币种'
         T1.LOAN_ACCT_BAL + T1.OD_LOAN_ACCT_BAL AS ZHYE   , -- 11 '业务余额' 
         T1.PAY_ACCT_NUM    , -- 12 '对方账号'
         B.CUST_NAM         , -- 13 '对方户名'
         CASE
             WHEN T1.ORG_NUM = '009808' THEN '313241066661'
             ELSE C.BANK_CD 
           END AS DFXH      , -- 14 '对方账号行号'
         CASE
             WHEN T1.ORG_NUM = '009808' THEN '吉林银行股份有限公司'
             ELSE C.ORG_NAM 
           END AS DFXM      , -- 15 '对方行名'
         t1.JBYG_ID         , -- 16 '经办员工ID'
         nvl(t1.SPYG_ID,'自动')         , -- 17 '授权员工ID'
         TO_CHAR(P_DATE,'YYYY-MM-DD') ,  -- 18 '采集日期'
         TO_CHAR(P_DATE,'YYYY-MM-DD') , -- 18 '采集日期'
         T1.ORG_NUM,
         CASE  
           WHEN T1.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T1.DEPARTMENTD ='公司金融' OR SUBSTR(T1.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T1.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T1.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T1.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END AS TX,
           '当天收回利息'
      FROM SMTMODS.L_TRAN_LOAN_PAYM T -- 贷款还款明细信息表
     INNER JOIN SMTMODS.L_ACCT_LOAN T1 -- 贷款借据信息表
        ON T.LOAN_NUM = T1.LOAN_NUM
       AND T1.DATA_DATE = I_DATE
     INNER JOIN SMTMODS.L_CUST_ALL B -- 全量客户信息表
        ON T1.CUST_ID = B.CUST_ID
       AND B.DATA_DATE = I_DATE
     INNER JOIN SMTMODS.L_PUBL_ORG_BRA C -- 机构表
        ON T.ORG_NUM = C.ORG_NUM
       AND C.DATA_DATE = I_DATE
     WHERE T1.DATA_DATE = I_DATE
           AND T1.ITEM_CD LIKE '1305%' -- 贸易融资
           AND T.REPAY_DT = I_DATE  -- 当天收回
           AND T.PAY_INT_AMT > 0
           AND NOT EXISTS(SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                WHERE A.DATA_DATE = I_DATE
                  AND A.WRITE_OFF_DATE < I_DATE
                  AND A.LOAN_NUM = T1.LOAN_NUM
                 )
           and (T1.LOAN_STOCKEN_DATE IS NULL or T1.LOAN_STOCKEN_DATE = I_DATE)  -- add by haorui 20250311 JLBA202408200012 信贷不良资产收益权转让
           ;
 
     COMMIT;
    
     
     
      INSERT  INTO T_7_3  
          (
    	   G030001  , -- 01 '交易ID'
           G030002  , -- 02 '协议ID'
           G030003  , -- 03 '分户账号'
           G030004  , -- 04 '客户ID'
           G030005  , -- 05 '交易机构ID'
           G030006  , -- 06 '核心交易日期'
           G030007  , -- 07 '核心交易时间'
           G030008  , -- 08 '交易类型'
           G030009  , -- 09 '交易金额'
           G030010  , -- 10 '币种'
           G030011  , -- 11 '业务余额'
           G030012  , -- 12 '对方账号'
           G030013  , -- 13 '对方户名'
           G030014  , -- 14 '对方账号行号'
           G030015  , -- 15 '对方行名'
           G030016  , -- 16 '经办员工ID'
           G030017  , -- 17 '授权员工ID'
           G030018  , -- 18 '采集日期'
           DIS_DATA_DATE,
           DIS_BANK_ID,
           DEPARTMENT_ID,
           DIS_DEPT
          )
      SELECT 
         T1.LOAN_NUM || D.WRITE_OFF_DATE    , -- 01 '交易ID'
         T1.ACCT_NUM        , -- 02 '协议ID'
        -- T1.LOAN_FHZ_NUM    ,-- 03 '分户账号'
         T1.LOAN_NUM        ,-- 03 '分户账号'
         T1.CUST_ID         , -- 04 '客户ID'
         SUBSTR(TRIM(C.FIN_LIN_NUM ),1,11)||T1.ORG_NUM  ,-- 05 '交易机构ID'
         TO_CHAR(TO_DATE(D.WRITE_OFF_DATE,'YYYYMMDD'),'YYYY-MM-DD')  , -- 06 '核心交易日期'
         -- T1.FKSJ            , -- 07 '核心交易时间'
         SUBSTR( T1.FKSJ , 1, 2) || ':' || SUBSTR( T1.FKSJ , 3, 2) || ':' ||SUBSTR( T1.FKSJ, 5, 2) AS JYSJ  , -- 07 '核心交易时间' 20241015
         '04'               , -- 08 '交易类型' 
         D.DRAWDOWN_AMT + D.ACCRUAL + D.ACCRUAL_OBS  , -- 09 '交易金额'
         T1.CURR_CD         , -- 10 '币种'
         T1.LOAN_ACCT_BAL + T1.OD_LOAN_ACCT_BAL   , -- 11 '业务余额' 
         NULL    , -- 12 '对方账号'
         NULL    , -- 13 '对方户名'
         NULL    , -- 14 '对方账号行号'
         NULL    , -- 15 '对方行名'
         t1.JBYG_ID         , -- 16 '经办员工ID'
         nvl(t1.SPYG_ID,'自动')       , -- 17 '授权员工ID'
         TO_CHAR(P_DATE,'YYYY-MM-DD') , -- 18 '采集日期'
         TO_CHAR(P_DATE,'YYYY-MM-DD') , -- 18 '采集日期'
         T1.ORG_NUM,
         CASE  
           WHEN T1.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T1.DEPARTMENTD ='公司金融' OR SUBSTR(T1.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T1.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T1.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T1.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END AS TX,
           '当天销户'
      FROM SMTMODS.L_ACCT_LOAN T1 -- 贷款借据信息表 
     INNER JOIN SMTMODS.L_CUST_ALL B -- 全量客户信息表
        ON T1.CUST_ID = B.CUST_ID
       AND B.DATA_DATE = I_DATE
     INNER JOIN SMTMODS.L_PUBL_ORG_BRA C -- 机构表
        ON T1.ORG_NUM = C.ORG_NUM
       AND C.DATA_DATE = I_DATE
     INNER JOIN SMTMODS.L_ACCT_WRITE_OFF D -- 贷款核销
        ON D.LOAN_NUM=T1.LOAN_NUM
       AND T1.DATA_DATE=D.DATA_DATE
     WHERE T1.DATA_DATE = I_DATE
           AND T1.ITEM_CD LIKE '1305%' -- 贸易融资
           AND D.WRITE_OFF_DATE = I_DATE; -- 当天销户
           COMMIT;   
    
        INSERT  INTO T_7_3  
          (
    	   G030001  , -- 01 '交易ID'
           G030002  , -- 02 '协议ID'
           G030003  , -- 03 '分户账号'
           G030004  , -- 04 '客户ID'
           G030005  , -- 05 '交易机构ID'
           G030006  , -- 06 '核心交易日期'
           G030007  , -- 07 '核心交易时间'
           G030008  , -- 08 '交易类型'
           G030009  , -- 09 '交易金额'
           G030010  , -- 10 '币种'
           G030011  , -- 11 '业务余额'
           G030012  , -- 12 '对方账号'
           G030013  , -- 13 '对方户名'
           G030014  , -- 14 '对方账号行号'
           G030015  , -- 15 '对方行名'
           G030016  , -- 16 '经办员工ID'
           G030017  , -- 17 '授权员工ID'
           G030018  , -- 18 '采集日期'
           DIS_DATA_DATE,
           DIS_BANK_ID,
           DEPARTMENT_ID,
           DIS_DEPT
          )    
        SELECT 
         T1.LOAN_NUM || D.TRANS_DATE    , -- 01 '交易ID'
         T1.ACCT_NUM        , -- 02 '协议ID'
      --   T1.LOAN_FHZ_NUM    ,-- 03 '分户账号'
         T1.LOAN_NUM        ,-- 03 '分户账号'
         T1.CUST_ID         , -- 04 '客户ID'
         SUBSTR(TRIM(C.FIN_LIN_NUM ),1,11)||T1.ORG_NUM  ,-- 05 '交易机构ID'
         TO_CHAR(TO_DATE(D.TRANS_DATE,'YYYYMMDD'),'YYYY-MM-DD')  , -- 06 '核心交易日期'
         -- T1.FKSJ            , -- 07 '核心交易时间'
         SUBSTR( T1.FKSJ , 1, 2) || ':' || SUBSTR( T1.FKSJ , 3, 2) || ':' ||SUBSTR( T1.FKSJ, 5, 2) AS JYSJ ,-- 07 '核心交易时间' 20241015
         '04'               , -- 08 '交易类型' 
         D.PAID_AMT         , -- 09 '交易金额'
         T1.CURR_CD         , -- 10 '币种'
         T1.LOAN_ACCT_BAL + T1.OD_LOAN_ACCT_BAL  AS YWYE , -- 11 '业务余额' 
         T1.PAY_ACCT_NUM    , -- 12 '对方账号'
         B.CUST_NAM   , -- 13 '对方户名'
         C.BANK_CD     , -- 14 '对方账号行号'
         C.ORG_NAM   , -- 15 '对方行名' 
         t1.JBYG_ID         , -- 16 '经办员工ID'
         nvl(t1.SPYG_ID,'自动')       , -- 17 '授权员工ID'
         TO_CHAR(P_DATE,'YYYY-MM-DD') , -- 18 '采集日期'
         TO_CHAR(P_DATE,'YYYY-MM-DD') , -- 18 '采集日期'
         T1.ORG_NUM,
         CASE  
           WHEN T1.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T1.DEPARTMENTD ='公司金融' OR SUBSTR(T1.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T1.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T1.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T1.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END AS TX,
           '当天转让'
      FROM SMTMODS.L_ACCT_LOAN T1 -- 贷款借据信息表 
     INNER JOIN SMTMODS.L_CUST_ALL B -- 全量客户信息表
        ON T1.CUST_ID = B.CUST_ID
       AND B.DATA_DATE = I_DATE
     INNER JOIN SMTMODS.L_PUBL_ORG_BRA C -- 机构表
        ON T1.ORG_NUM = C.ORG_NUM
       AND C.DATA_DATE = I_DATE
     INNER JOIN SMTMODS.L_ACCT_TRANSFER D    -- 信贷转让
        ON D.LOAN_NUM=T1.LOAN_NUM
       AND T1.DATA_DATE=D.DATA_DATE
     WHERE T1.DATA_DATE = I_DATE
       AND T1.ITEM_CD LIKE '1305%' -- 贸易融资
       AND D.TRANS_DATE = I_DATE ; -- 当天转让
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

