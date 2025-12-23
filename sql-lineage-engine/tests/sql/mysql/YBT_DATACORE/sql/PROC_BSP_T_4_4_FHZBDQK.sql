DROP Procedure IF EXISTS `PROC_BSP_T_4_4_FHZBDQK` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_4_4_FHZBDQK"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT,-- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN

  /******
      程序名称  ：分户账变动情况
      程序功能  ：加工分户账变动情况
      目标表：T_4_4
      源表  ：
      创建人  ：87v
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	 -- JLBA202411070004_关于一表通监管数据报送系统修改逻辑的需求
	 /*需求编号：JLBA202507300010 上线日期：2025-09-29，修改人：姜俐锋，提出人：信贷新增产品 修改原因：关于新一代信贷管理系统新增线上微贷板块的需求 */
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
   select OI_RETCODE,'|',OI_REMESSAGE;
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
	SET P_PROC_NAME = 'PROC_BSP_T_4_4_FHZBDQK';
	SET OI_RETCODE = 0;
	SET P_STATUS = 0;
	SET P_STEP_NO = 0;
	
    #1.过程开始执行
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '过程开始执行';
				 
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);								

    #2.清除数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '清除数据';
	
	DELETE FROM ybt_datacore.T_4_4 WHERE D040013 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
  

    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '存款分户账数据插入';
	
	
	INSERT  INTO T_4_4  (
	    D040001  , -- 01 分户账号
        D040002  , -- 02 机构ID
        D040003  , -- 03 会计日期
        D040004  , -- 04 币种
        D040005  , -- 05 期初借方余额
        D040006  , -- 06 期初贷方余额
        D040007  , -- 07 本期借方发生额
        D040008  , -- 08 本期贷方发生额
        D040009  , -- 09 期末借方余额
        D040010  , -- 10 期末贷方余额
        D040011  , -- 11 应收利息
        D040012  , -- 12 应付利息
        D040014  , -- 13 钞汇类别
        D040013  , -- 14 采集日期
        DIS_DATA_DATE,
        DIS_BANK_ID ,   -- 机构号
	    DEPARTMENT_ID ,      -- 业务条线
	    DIS_DEPT
	)
	SELECT 
	     T1.ACCT_NUM                                      , -- 01 分户账号
		 CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN 'B0302H22201009803'
            ELSE ORG.ORG_ID
             END                                         , -- 02 机构ID
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 03 会计日期
		 T1.CURR_CD                                      , -- 04 币种
		 '0'                                             , -- 05 期初借方余额
		 SUM(NVL(T2.ACCT_BALANCE,0))                     , -- 06 期初贷方余额
		 '0'                                             , -- 07 本期借方发生额
		 SUM(NVL((T1.ACCT_BALANCE - NVL(T2.ACCT_BALANCE,0)),0)) , -- 08 本期贷方发生额
		 '0'                                             , -- 09 期末借方余额
		 SUM(NVL(T1.ACCT_BALANCE,0))                                  , -- 10 期末贷方余额
		 '0'                                             , -- 11 应收利息
		 SUM(CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '0' 
		      ELSE NVL(T1.INTEREST_ACCURED, 0) + NVL(T1.INTEREST_ACCURAL, 0) 
		       END)                                        , -- 12 应付利息 信用卡溢缴款不计息
		 CASE WHEN T1.ACCOUNT_CATA_FLG = '2' THEN '01' -- 钞
	          WHEN T1.ACCOUNT_CATA_FLG = '3' THEN '02' -- 汇
			  WHEN T1.ACCOUNT_CATA_FLG = '4' THEN '03' -- 可钞可汇
	      END                                             , -- 13 钞汇类别
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 14 采集日期
         TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
         CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '009803'
	        ELSE T1.ORG_NUM
	         END,                                                   --  '机构号'
		 '009806' ,                                                 -- 业务条线  默认计划财务部
		 '存款分户账'
		 FROM SMTMODS.L_ACCT_DEPOSIT T1
         LEFT JOIN SMTMODS.L_ACCT_DEPOSIT T2 -- 关联前一天，取期初余额
		        ON T1.ACCT_NUM = T2.ACCT_NUM
		       AND T1.DEPOSIT_NUM = T2.DEPOSIT_NUM 
			   AND T2.DATA_DATE = LAST_DT
		 LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
                ON T1.ORG_NUM = ORG.ORG_NUM
               AND ORG.DATA_DATE = I_DATE	    
		 WHERE T1.DATA_DATE = I_DATE
           AND (T1.ACCT_CLDATE >= I_DATE
		        OR (T1.ACCT_CLDATE IS NULL AND  T1.ACCT_BALANCE > 0 ) --  JLBA202411070004 YBT_JYD04-40 20241212
		        OR T1.ACCT_BALANCE > 0)
	       AND T1.GL_ITEM_CODE NOT LIKE  '2012%' -- 同业存放在资金往来部分插入
	       AND SUBSTR(T1.GL_ITEM_CODE,1,6) <>  '224101'  -- 久悬 
	       AND T1.GL_ITEM_CODE IS NOT NULL 
	       GROUP BY T1.ACCT_NUM                                      , -- 01 分户账号
		 CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN 'B0302H22201009803'
            ELSE ORG.ORG_ID
             END                                       , -- 02 机构ID
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 03 会计日期
		 T1.CURR_CD                                       , -- 04 币种
		 CASE WHEN T1.ACCOUNT_CATA_FLG = '2' THEN '01' -- 钞
	          WHEN T1.ACCOUNT_CATA_FLG = '3' THEN '02' -- 汇
			  WHEN T1.ACCOUNT_CATA_FLG = '4' THEN '03' -- 可钞可汇
	      END                                             , -- 13 钞汇类别
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 14 采集日期
         TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
         CASE WHEN T1.GL_ITEM_CODE = '20110111' THEN '009803'
	        ELSE T1.ORG_NUM
	         END
		   ;
 
    COMMIT;

	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	

    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '贷款分户账数据插入';
	
	
	INSERT  INTO T_4_4  (
	    D040001  , -- 01 分户账号
        D040002  , -- 02 机构ID
        D040003  , -- 03 会计日期
        D040004  , -- 04 币种
        D040005  , -- 05 期初借方余额
        D040006  , -- 06 期初贷方余额
        D040007  , -- 07 本期借方发生额
        D040008  , -- 08 本期贷方发生额
        D040009  , -- 09 期末借方余额
        D040010  , -- 10 期末贷方余额
        D040011  , -- 11 应收利息
        D040012  , -- 12 应付利息
        D040014  , -- 13 钞汇类别
        D040013  , -- 14 采集日期
        DIS_DATA_DATE,
        DIS_BANK_ID ,   -- 机构号
	    DEPARTMENT_ID ,      -- 业务条线
	    DIS_DEPT
	)
	SELECT 
	     -- T1.LOAN_NUM
         CASE WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130104','130102','130105') THEN SUBSTR(T1.ACCT_NUM || NVL(T1.DRAFT_RNG,''),1,60)  
              ELSE T1.LOAN_NUM
              END AS LOAN_NUM               , -- 01 分户账号
		 ORG.ORG_ID                                       , -- 02 机构ID
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 03 会计日期
		 T1.CURR_CD                                       , -- 04 币种
		 NVL(T2.LOAN_ACCT_BAL,0)                                 , -- 05 期初借方余额
		 '0'                                             , -- 06 期初贷方余额
		 NVL((T1.LOAN_ACCT_BAL - NVL(T2.LOAN_ACCT_BAL,0)),0)              , -- 07 本期借方发生额
		 '0'                                             , -- 08 本期贷方发生额
		 NVL(T1.LOAN_ACCT_BAL,0)                                 , -- 09 期末借方余额
		 '0'                                             , -- 10 期末贷方余额
		 NVL((T1.ACCU_INT_AMT + T1.OD_INT),0), -- 11 应收利息   ADD BY DJH 20240627 增加应计利息
		 '0'                                             , -- 12 应付利息
		 CASE WHEN SUBSTR(T1.ITEM_CD,1,4) = '1305' AND T1.CURR_CD NOT IN('CNY','BWB') THEN '02'  -- 贸易融资科目为 汇
		      ELSE NULL
		       END                                        , -- 13 钞汇类别
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 14 采集日期
         TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
         T1.ORG_NUM,                                                   --  '机构号'
		 '009806'  ,                                                        -- 业务条线  默认计划财务部
         '贷款分户账'
		 FROM SMTMODS.L_ACCT_LOAN T1 
		 
         LEFT JOIN SMTMODS.L_ACCT_LOAN T2 -- 关联前一天，取期初余额
		        ON T1.LOAN_NUM = T2.LOAN_NUM
			   AND T2.DATA_DATE = LAST_DT
			   
		 LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T3 -- 贷款合同信息表
                ON T1.ACCT_NUM = T3.CONTRACT_NUM
               AND T3.DATA_DATE = I_DATE
		 LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
                ON T1.ORG_NUM = ORG.ORG_NUM
               AND ORG.DATA_DATE = I_DATE	
         WHERE T1.DATA_DATE = I_DATE
          AND (T1.ACCT_STS <>'3' OR
               T1.LOAN_ACCT_BAL > 0 OR
               T1.FINISH_DT = I_DATE OR
              (T1.INTERNET_LOAN_FLG = 'Y' AND T1.FINISH_DT = (TRUNC(TO_DATE(I_DATE, 'YYYYMMDD'), 'MM') - 1))OR 
              (T1.CP_ID ='DK001000100041' AND T1.FINISH_DT = (TRUNC(TO_DATE(I_DATE, 'YYYYMMDD'), 'MM') - 1))  -- [20250929][姜俐锋][JLBA202507300010][信贷新增产品]: 同网贷部分数据处理方
              ) 
          AND NVL(T3.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据
          AND NOT EXISTS(
              SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                WHERE A.DATA_DATE = I_DATE
                  AND A.WRITE_OFF_DATE <= I_DATE
                  AND A.LOAN_NUM = T1.LOAN_NUM
                 )
		   ;
 
    COMMIT;

	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	

   #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '资金往来分户账数据插入';
	
	
	INSERT  INTO T_4_4  (
	    D040001  , -- 01 分户账号
        D040002  , -- 02 机构ID
        D040003  , -- 03 会计日期
        D040004  , -- 04 币种
        D040005  , -- 05 期初借方余额
        D040006  , -- 06 期初贷方余额
        D040007  , -- 07 本期借方发生额
        D040008  , -- 08 本期贷方发生额
        D040009  , -- 09 期末借方余额
        D040010  , -- 10 期末贷方余额
        D040011  , -- 11 应收利息
        D040012  , -- 12 应付利息
        D040014  , -- 13 钞汇类别
        D040013  , -- 14 采集日期
        DIS_DATA_DATE,
        DIS_BANK_ID ,   -- 机构号
	    DEPARTMENT_ID ,      -- 业务条线
	    DIS_DEPT
	)
	SELECT 
	     T1.ACCT_NUM                                      , -- 01 分户账号
		 ORG.ORG_ID                                       , -- 02 机构ID
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 03 会计日期
		 T1.CURR_CD                                       , -- 04 币种
		 CASE WHEN SUBSTR(T2.GL_ITEM_CODE,1,1) = '1' THEN NVL(T2.BALANCE,0)
		      ELSE '0'
		       END                                        , -- 05 期初借方余额
		 CASE WHEN SUBSTR(T2.GL_ITEM_CODE,1,1) = '2' THEN NVL(T2.BALANCE,0)
		      ELSE '0'
		       END                                        , -- 06 期初贷方余额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '1' THEN NVL((T1.BALANCE - NVL(T2.BALANCE,0)),0)
		      ELSE '0'
		       END                                        , -- 07 本期借方发生额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '2' THEN NVL((T1.BALANCE - NVL(T2.BALANCE,0)),0)
		      ELSE '0'
		       END                                        , -- 08 本期贷方发生额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '1' THEN NVL(T1.BALANCE,0)
		      ELSE '0'
		       END                                        , -- 09 期末借方余额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '2' THEN NVL(T1.BALANCE,0)
		      ELSE '0'
		       END                                        , -- 10 期末贷方余额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '1' THEN NVL(T1.ACCRUAL,0)  
		      ELSE '0'
		      END                                         , -- 11 应收利息     ADD BY DJH 20240627 增加应收利息
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '2' THEN NVL(T1.ACCRUAL,0) 
		      ELSE '0'
		      END                                       , -- 12 应付利息         ADD BY DJH 20240627 增加应付利息
		 '02'                                             , -- 13 钞汇类别  资金往来默认汇
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 14 采集日期
         TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
         T1.ORG_NUM,                                                   --  '机构号'
		 '009806',                                                     -- 业务条线  默认计划财务部
		 '资金往来分户账'
	    FROM SMTMODS.L_ACCT_FUND_MMFUND T1
	    LEFT JOIN SMTMODS.L_ACCT_FUND_MMFUND T2  -- 关联前一天，取期初余额
               ON T1.ACCT_NUM = T2.ACCT_NUM
              AND T2.DATA_DATE = LAST_DT 
        LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
               ON T1.ORG_NUM = ORG.ORG_NUM
              AND ORG.DATA_DATE = I_DATE
            WHERE T1.DATA_DATE = I_DATE
              AND (((T1.ACCT_CLDATE > I_DATE OR T1.ACCT_CLDATE IS null) AND T1.BALANCE > 0) or (T1.ACCT_CLDATE = I_DATE and T1.BALANCE = 0) or T1.ACCRUAL <> 0) -- 与8.7同步 alter by djh 20240719 有利息无本金数据也加进来
	     ;
 
    COMMIT;

	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
	
	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '表外业务分户账数据插入'; 
	
	INSERT  INTO T_4_4  (
	    D040001  , -- 01 分户账号
        D040002  , -- 02 机构ID
        D040003  , -- 03 会计日期
        D040004  , -- 04 币种
        D040005  , -- 05 期初借方余额
        D040006  , -- 06 期初贷方余额
        D040007  , -- 07 本期借方发生额
        D040008  , -- 08 本期贷方发生额
        D040009  , -- 09 期末借方余额
        D040010  , -- 10 期末贷方余额
        D040011  , -- 11 应收利息
        D040012  , -- 12 应付利息
        D040014  , -- 13 钞汇类别
        D040013  , -- 14 采集日期
        DIS_DATA_DATE,
        DIS_BANK_ID ,   -- 机构号
	    DEPARTMENT_ID,      -- 业务条线
	    DIS_DEPT
       	)
	 SELECT 
	      T1.ACCT_NUM                                      , -- 01 分户账号
	      ORG.ORG_ID                                       , -- 02 机构ID
	      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 03 会计日期
	      T1.CURR_CD                                       , -- 04 币种
	      CASE WHEN T2.GL_ITEM_CODE IN ('70300101','70300301','7010')  -- 贷款承诺、商票保贴承诺、信用证
	              THEN NVL(T2.BALANCE,0)
	              ELSE '0'
	            END                                        , -- 05 期初借方余额
	      CASE WHEN T2.GL_ITEM_CODE IN ('70400101','70400102','70200101','7010')  -- 融资保函、非融资保函、银行承兑汇票、信用证
	              THEN NVL(T2.BALANCE,0)
	              ELSE '0'
	            END                                        , -- 06 期初贷方余额
	      CASE WHEN T1.GL_ITEM_CODE IN ('70300101','70300301','7010')  -- 贷款承诺、商票保贴承诺、信用证
	              THEN NVL((T1.BALANCE - NVL(T2.BALANCE,0)),0) 
	              ELSE '0'
	            END                                        , -- 07 本期借方发生额
	      CASE WHEN T1.GL_ITEM_CODE IN ('70400101','70400102','70200101','7010')  -- 融资保函、非融资保函、银行承兑汇票、信用证
	              THEN NVL((T1.BALANCE - NVL(T2.BALANCE,0)),0) 
	              ELSE '0'
	            END                                        , -- 08 本期贷方发生额
	      CASE WHEN T1.GL_ITEM_CODE IN ('70300101','70300301','7010')  -- 贷款承诺、商票保贴承诺、信用证
	              THEN NVL(T1.BALANCE,0) 
	              ELSE '0'
	            END                                        , -- 09 期末借方余额
	      CASE WHEN T1.GL_ITEM_CODE IN ('70400101','70400102','70200101','7010')  -- 融资保函、非融资保函、银行承兑汇票、信用证
	              THEN NVL(T1.BALANCE,0)
	              ELSE '0'
	            END                                        , -- 10 期末贷方余额
	      '0'                                             , -- 11 应收利息
	      '0'                                             , -- 12 应付利息
	      CASE WHEN T1.CURR_CD NOT IN('CNY','BWB') THEN '02' 
	      ELSE NULL          
	       END                                             , -- 13 钞汇类别
	      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 14 采集日期
         TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
         T1.ORG_NUM,                                                   --  '机构号'
		 '009806',                                                     -- 业务条线  默认计划财务部
		 '表外业务分户账'
		     FROM SMTMODS.L_ACCT_OBS_LOAN T1
	    LEFT JOIN SMTMODS.L_ACCT_OBS_LOAN T2  -- 关联前一天，取期初余额
               ON T1.ACCT_NUM = T2.ACCT_NUM
              AND T2.DATA_DATE = LAST_DT 
        LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
               ON T1.ORG_NUM = ORG.ORG_NUM
              AND ORG.DATA_DATE = I_DATE
            WHERE T1.DATA_DATE = I_DATE
              AND (T1.MATURITY_DT >= I_DATE OR T1.MATURITY_DT IS NULL OR T1.BALANCE > 0 )
             ;
             
     COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	

	 
	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '信用卡分户账数据插入';
	
	INSERT  INTO T_4_4  (
	    D040001  , -- 01 分户账号
        D040002  , -- 02 机构ID
        D040003  , -- 03 会计日期
        D040004  , -- 04 币种
        D040005  , -- 05 期初借方余额
        D040006  , -- 06 期初贷方余额
        D040007  , -- 07 本期借方发生额
        D040008  , -- 08 本期贷方发生额
        D040009  , -- 09 期末借方余额
        D040010  , -- 10 期末贷方余额
        D040011  , -- 11 应收利息
        D040012  , -- 12 应付利息
        D040014  , -- 13 钞汇类别
        D040013  , -- 14 采集日期
        DIS_DATA_DATE,
        DIS_BANK_ID ,   -- 机构号
	    DEPARTMENT_ID,      -- 业务条线
	    DIS_DEPT
       	)
	 SELECT 
	      T1.ACCT_NUM                                      , -- 01 分户账号
	      'B0302H22201009803'                                       , -- 02 机构ID
	      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 03 会计日期
	      T1.CURR_CD                                       , -- 04 币种
	      NVL(T2.M0,0)                                            , -- 05 期初借方余额
	      '0'                                             , -- 06 期初贷方余额
	      NVL((T1.M0 - NVL(T2.M0,0)),0)                                    , -- 07 本期借方发生额
	      '0'                                             , -- 08 本期贷方发生额
	      NVL(T1.M0,0)                                            , -- 09 期末借方余额
	      '0'                                             , -- 10 期末贷方余额
	      NVL(T1.INTAMT,0)                                        , -- 11 应收利息
	      '0'                                             , -- 12 应付利息
	      NULL                                             , -- 13 钞汇类别
	      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 14 采集日期
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
          '009803',                                                   --  '机构号'
		  '009806',                                                         -- 业务条线  默认计划财务部            
		  '信用卡分户账1'
	         FROM SMTMODS.L_ACCT_CARD_CREDIT T1
	    LEFT JOIN SMTMODS.L_ACCT_CARD_CREDIT T2  -- 关联前一天，取期初余额
               ON T1.ACCT_NUM = T2.ACCT_NUM
              AND T2.DATA_DATE = LAST_DT 
        LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
               ON T1.ORG_NUM = ORG.ORG_NUM
              AND ORG.DATA_DATE = I_DATE
            WHERE T1.DATA_DATE = I_DATE
	          AND (T1.ACCT_CLDATE >= I_DATE OR T1.ACCT_CLDATE IS NULL)
	-- add by haorui 20241119 JLBA202410090008信用卡收益权转让 start	          
			  and (T1.DEALDATE = I_DATE OR T1.DEALDATE ='00000000')
    UNION ALL 
	 SELECT 
	      T1.ACCT_NUM                                      , -- 01 分户账号
	      'B0302H22201009803'                                       , -- 02 机构ID
	      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 03 会计日期
	      T1.CURR_CD                                       , -- 04 币种
	      NVL(T2.M0,0)                                            , -- 05 期初借方余额
	      '0'                                             , -- 06 期初贷方余额
	      NVL((T1.M0 - NVL(T2.M0,0)),0)                                    , -- 07 本期借方发生额
	      '0'                                             , -- 08 本期贷方发生额
	      NVL(T1.M0,0)                                            , -- 09 期末借方余额
	      '0'                                             , -- 10 期末贷方余额
	      NVL(T1.INTAMT,0)                                        , -- 11 应收利息
	      '0'                                             , -- 12 应付利息
	      NULL                                             , -- 13 钞汇类别
	      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 14 采集日期
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
          '009803',                                                   --  '机构号'
		 '009806',                                                          -- 业务条线  默认计划财务部 
		 '信用卡分户账2'
	         FROM SMTMODS.L_ACCT_CARD_CREDIT T1
	    LEFT JOIN SMTMODS.L_ACCT_DEPOSIT T3
		  ON T1.DATA_DATE = T3.DATA_DATE
		  AND T1.ACCT_NUM = T3.ACCT_NUM
		  AND T3.GL_ITEM_CODE ='20110111'
	    LEFT JOIN SMTMODS.L_ACCT_DEPOSIT T4
		  ON T1.ACCT_NUM = T4.ACCT_NUM
		  AND T4.DATA_DATE = LAST_DT
		  AND T4.GL_ITEM_CODE ='20110111'
	    LEFT JOIN SMTMODS.L_ACCT_CARD_CREDIT T2  -- 关联前一天，取期初余额
               ON T1.ACCT_NUM = T2.ACCT_NUM
              AND T2.DATA_DATE = LAST_DT 
        LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
               ON T1.ORG_NUM = ORG.ORG_NUM
              AND ORG.DATA_DATE = I_DATE
            WHERE T1.DATA_DATE = I_DATE
	          AND (T1.ACCT_CLDATE >= I_DATE OR T1.ACCT_CLDATE IS NULL)
			  AND T1.DEALDATE <> '00000000'
			  and (T4.ACCT_NUM is not null or T4.ACCT_NUM is null and t3.acct_num is not NULL)  -- 前一天有溢款款 或 前一天无溢缴款当天有溢缴款
	 -- add by haorui 20241119 JLBA202410090008信用卡收益权转让 end			  
	           ;
             
     COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '投资业务分户账数据插入';
	
	INSERT  INTO T_4_4  (
	    D040001  , -- 01 分户账号
        D040002  , -- 02 机构ID
        D040003  , -- 03 会计日期
        D040004  , -- 04 币种
        D040005  , -- 05 期初借方余额
        D040006  , -- 06 期初贷方余额
        D040007  , -- 07 本期借方发生额
        D040008  , -- 08 本期贷方发生额
        D040009  , -- 09 期末借方余额
        D040010  , -- 10 期末贷方余额
        D040011  , -- 11 应收利息
        D040012  , -- 12 应付利息
        D040014  , -- 13 钞汇类别
        D040013  , -- 14 采集日期
        DIS_DATA_DATE,
        DIS_BANK_ID ,   -- 机构号
	    DEPARTMENT_ID,      -- 业务条线
	    DIS_DEPT
       	)
	 SELECT 
	      T1.ACCT_NUM||T1.REF_NUM                                      , -- 01 分户账号
	      ORG.ORG_ID                                       , -- 02 机构ID
	      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 03 会计日期
	      T1.CURR_CD                                       , -- 04 币种
	      NVL(T2.FACE_VAL,0)                                      , -- 05 期初借方余额
	      '0'                                             , -- 06 期初贷方余额
	      NVL(T1.FACE_VAL - NVL(T2.FACE_VAL,0),0)                        , -- 07 本期借方发生额
	      '0'                                             , -- 08 本期贷方发生额
	      NVL(T1.FACE_VAL,0)                              , -- 09 期末借方余额
	       '0'                                            , -- 10 期末贷方余额
	      case when T1.ORG_NUM='009817' then NVL(T1.ACCRUAL,0) + nvl(T1.QTYSK,0) 
	           else  
	           NVL(T1.ACCRUAL,0)
	      end, -- 11 应收利息    ADD BY DJH 20240627 增加应收利息    20240718并补充投资银行部其他应收款    
	      '0'                                             , -- 12 应付利息
	      NULL                                             , -- 13 钞汇类别
	      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 14 采集日期
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
          T1.ORG_NUM,                                                   --  '机构号'
		 '009806',                                                         -- 业务条线  默认计划财务部     
		  '投资业务分户账'
       FROM SMTMODS.L_ACCT_FUND_INVEST T1  
	     LEFT JOIN SMTMODS.L_ACCT_FUND_INVEST T2  -- 关联前一天，取期初余额
                ON T1.ACCT_NUM = T2.ACCT_NUM
               AND T2.DATA_DATE = LAST_DT   
         LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
                ON T1.ORG_NUM = ORG.ORG_NUM
               AND ORG.DATA_DATE = I_DATE
             WHERE T1.DATA_DATE = I_DATE
            --   AND (T1.MATURITY_DATE >= I_DATE OR T1.MATURITY_DATE IS NULL  OR T1.FACE_VAL > 0 )
			 AND (T1.MATURITY_DATE = I_DATE OR T1.FACE_VAL > 0) -- 应同业李佶阳要求，不判断到期日JLBA202411070004 YBT_JYD04-40 20241212
             ;
             
     COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	 #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '同业存单数据插入';
	
	
	INSERT  INTO T_4_4  (
	    D040001  , -- 01 分户账号
        D040002  , -- 02 机构ID
        D040003  , -- 03 会计日期
        D040004  , -- 04 币种
        D040005  , -- 05 期初借方余额
        D040006  , -- 06 期初贷方余额
        D040007  , -- 07 本期借方发生额
        D040008  , -- 08 本期贷方发生额
        D040009  , -- 09 期末借方余额
        D040010  , -- 10 期末贷方余额
        D040011  , -- 11 应收利息
        D040012  , -- 12 应付利息
        D040014  , -- 13 钞汇类别
        D040013  , -- 14 采集日期
        DIS_DATA_DATE,
        DIS_BANK_ID ,   -- 机构号
	    DEPARTMENT_ID,       -- 业务条线
	    DIS_DEPT
	)
	SELECT 
	      T1.ACCT_NUM || T1.CDS_NO,
	     -- FUNC_SUBSTR(T.ACCT_NUM || T.CONT_PARTY_NAME,60),  -- T1.ACCT_NUM||T1.CONT_PARTY_NAME , -- 01 分户账号  ALTER BY DJH 关联修改
		 ORG.ORG_ID                                       , -- 02 机构ID
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 03 会计日期
		 T1.CURR_CD                                       , -- 04 币种
		 CASE WHEN SUBSTR(T2.GL_ITEM_CODE,1,1) = '1' THEN NVL(T2.FACE_VAL,0)
		      ELSE '0'
		       END                                        , -- 05 期初借方余额
		 CASE WHEN SUBSTR(T2.GL_ITEM_CODE,1,1) = '2' THEN NVL(T2.FACE_VAL,0)
		      ELSE '0'
		       END                                     , -- 06 期初贷方余额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '1' THEN NVL((T1.FACE_VAL - NVL(T2.FACE_VAL,0)),0)
		      ELSE '0'
		       END                                        , -- 07 本期借方发生额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '2' THEN NVL((T1.FACE_VAL - NVL(T2.FACE_VAL,0)),0)
		      ELSE '0'
		       END                                        , -- 08 本期贷方发生额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '1' THEN NVL(T1.FACE_VAL,0)
		      ELSE '0'
		       END                                        , -- 09 期末借方余额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '2' THEN NVL(T1.FACE_VAL,0)
		      ELSE '0'
		       END                                        , -- 10 期末贷方余额
		 NVL(T1.INTEREST_RECEIVABLE,0)                    , -- 11 应收利息
		 NVL(T1.INTEREST_PAYABLE,0)                      , -- 12 应付利息
		 '02'                                             , -- 13 钞汇类别 
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 14 采集日期
         TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
         T1.ORG_NUM,                                                   --  '机构号'
		 '009806' ,                                                         -- 业务条线  默认计划财务部
		 '同业存单分户账'
	    FROM SMTMODS.L_ACCT_FUND_CDS_BAL T1
	    LEFT JOIN SMTMODS.L_ACCT_FUND_CDS_BAL T2  -- 关联前一天，取期初余额
              -- ON T1.ACCT_NUM = T2.ACCT_NUM
               ON T2.ACCT_NUM || T2.CDS_NO = T1.ACCT_NUM || T1.CDS_NO  -- JLBA202411070004 YBT_JYD04-40 20241212
              and T1.CUST_ID = T2.CUST_ID -- [20250625][巴启威]：需要增加交易对手客户ID关联，否则数据存在重复 
              AND T2.DATA_DATE = LAST_DT 
        LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
               ON T1.ORG_NUM = ORG.ORG_NUM
              AND ORG.DATA_DATE = I_DATE
            WHERE T1.DATA_DATE = I_DATE
            --  AND (T1.ACCT_CLDATE >= I_DATE OR T1.ACCT_CLDATE IS NULL)
            AND ((NVL(T1.ACCT_STS,'#')<>'03' AND (T1.MATURITY_DT >= I_DATE OR T1.MATURITY_DT IS null)) or (T1.ACCT_STS='03' and T2.ACCT_STS<>'03')); -- JLBA202411070004 YBT_JYD04-40 20241212
  
    COMMIT;

	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
 #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '买入返售卖出回购数据插入';
	
	
	INSERT  INTO T_4_4  (
	    D040001  , -- 01 分户账号
        D040002  , -- 02 机构ID
        D040003  , -- 03 会计日期
        D040004  , -- 04 币种
        D040005  , -- 05 期初借方余额
        D040006  , -- 06 期初贷方余额
        D040007  , -- 07 本期借方发生额
        D040008  , -- 08 本期贷方发生额
        D040009  , -- 09 期末借方余额
        D040010  , -- 10 期末贷方余额
        D040011  , -- 11 应收利息
        D040012  , -- 12 应付利息
        D040014  , -- 13 钞汇类别
        D040013  , -- 14 采集日期
        DIS_DATA_DATE,
        DIS_BANK_ID ,   -- 机构号
	    DEPARTMENT_ID,      -- 业务条线
	    DIS_DEPT
	)
	SELECT 
	     T1.ACCT_NUM                                      , -- 01 分户账号
		 ORG.ORG_ID                                       , -- 02 机构ID
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 03 会计日期
		 T1.CURR_CD                                       , -- 04 币种
		 CASE WHEN SUBSTR(T2.GL_ITEM_CODE,1,1) = '1' THEN NVL(T2.BALANCE,0)
		      ELSE '0'
		       END                                        , -- 05 期初借方余额
		 CASE WHEN SUBSTR(T2.GL_ITEM_CODE,1,1) = '2' THEN NVL(T2.BALANCE,0)
		      ELSE '0'
		       END                                        , -- 06 期初贷方余额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '1' THEN NVL((T1.BALANCE - NVL(T2.BALANCE,0)),0)
		      ELSE '0'
		       END                                        , -- 07 本期借方发生额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '2' THEN NVL((T1.BALANCE - NVL(T2.BALANCE,0)),0)
		      ELSE '0'
		       END                                        , -- 08 本期贷方发生额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '1' THEN NVL(T1.BALANCE,0)
		      ELSE '0'
		       END                                        , -- 09 期末借方余额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '2' THEN NVL(T1.BALANCE,0)
		      ELSE '0'
		       END                                        , -- 10 期末贷方余额
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '1' THEN NVL(T1.ACCRUAL,0)   
		      ELSE '0'
               END                                  		 , -- 11 应收利息    modiy BY DJH 20240627 修改应收利息
		 CASE WHEN SUBSTR(T1.GL_ITEM_CODE,1,1) = '2' THEN NVL(T1.ACCRUAL,0)  
		      ELSE '0'
               END                                        , -- 12 应付利息   modiy BY DJH 20240627 修改应付利息
		 '02'                                             , -- 13 钞汇类别 
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 14 采集日期
         TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
         T1.ORG_NUM,                                                   --  '机构号'
		 '009806' ,                                                        -- 业务条线  默认计划财务部
		 '买入返售卖出回购'
	    FROM SMTMODS.L_ACCT_FUND_REPURCHASE T1
	    LEFT JOIN SMTMODS.L_ACCT_FUND_REPURCHASE T2  -- 关联前一天，取期初余额
               ON T1.ACCT_NUM = T2.ACCT_NUM
              AND T2.DATA_DATE = LAST_DT 
        LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
               ON T1.ORG_NUM = ORG.ORG_NUM
              AND ORG.DATA_DATE = I_DATE
            WHERE T1.DATA_DATE = I_DATE
            --  AND (T1.ACCT_CLDATE > I_DATE OR T1.ACCT_CLDATE IS NULL or T1.BALANCE > 0 or (T1.ACCT_CLDATE = I_DATE and T1.BALANCE = 0)) 
	          AND (((T1.ACCT_CLDATE > I_DATE OR T1.ACCT_CLDATE IS NULL) AND T1.BALANCE > 0) OR (T1.ACCT_CLDATE = I_DATE AND T1.BALANCE = 0)) -- 与8.7同步  20241212
            ;
 
    COMMIT;

	
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	 #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '债券发行数据插入';
	
	
	INSERT  INTO T_4_4  (
	    D040001  , -- 01 分户账号
        D040002  , -- 02 机构ID
        D040003  , -- 03 会计日期
        D040004  , -- 04 币种
        D040005  , -- 05 期初借方余额
        D040006  , -- 06 期初贷方余额
        D040007  , -- 07 本期借方发生额
        D040008  , -- 08 本期贷方发生额
        D040009  , -- 09 期末借方余额
        D040010  , -- 10 期末贷方余额
        D040011  , -- 11 应收利息
        D040012  , -- 12 应付利息
        D040014  , -- 13 钞汇类别
        D040013  , -- 14 采集日期
        DIS_DATA_DATE,
        DIS_BANK_ID ,   -- 机构号
	    DEPARTMENT_ID,       -- 业务条线
	    DIS_DEPT
	)
	SELECT 
	     T1.ACCT_NUM||T1.REF_NUM                          , -- 01 分户账号
		 ORG.ORG_ID                                       , -- 02 机构ID
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 03 会计日期
		 T1.CURR_CD                                       , -- 04 币种
		 '0'                                              , -- 05 期初借方余额
		 NVL(T2.FACE_VAL,0)                               , -- 06 期初贷方余额
		 '0'                                              , -- 07 本期借方发生额
		 NVL((T1.FACE_VAL - NVL(T2.FACE_VAL,0)),0)        , -- 08 本期贷方发生额
		 '0'                                              , -- 09 期末借方余额
		 NVL(T1.FACE_VAL,0)                               , -- 10 期末贷方余额
		 '0'                                               , -- 11 应收利息
		 NVL(T1.ACCRUAL,0)                                , -- 12 应付利息
		 '02'                                             , -- 13 钞汇类别 
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 14 采集日期
         TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
         T1.ORG_NUM,                                                   --  '机构号'
		 '009806' ,                                                       -- 业务条线  默认计划财务部
		 '债券发行'
	    FROM SMTMODS.L_ACCT_FUND_BOND_ISSUE T1
	    LEFT JOIN SMTMODS.L_ACCT_FUND_BOND_ISSUE T2  -- 关联前一天，取期初余额
               ON T1.ACCT_NUM = T2.ACCT_NUM
              AND T2.DATA_DATE = LAST_DT 
        LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
               ON T1.ORG_NUM = ORG.ORG_NUM
              AND ORG.DATA_DATE = I_DATE
            WHERE T1.DATA_DATE = I_DATE
			  AND T1.GL_ITEM_CODE IS NOT NULL
              AND (T1.MATURITY_DATE >= I_DATE OR T1.MATURITY_DATE IS NULL OR T1.FACE_VAL > 0)
	     ;
 
    COMMIT;

	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	

	
  #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '内部分户账数据插入';
	
	
	INSERT  INTO ybt_datacore.T_4_4  (
	    D040001  , -- 01 分户账号
        D040002  , -- 02 机构ID
        D040003  , -- 03 会计日期
        D040004  , -- 04 币种
        D040005  , -- 05 期初借方余额
        D040006  , -- 06 期初贷方余额
        D040007  , -- 07 本期借方发生额
        D040008  , -- 08 本期贷方发生额
        D040009  , -- 09 期末借方余额
        D040010  , -- 10 期末贷方余额
        D040011  , -- 11 应收利息
        D040012  , -- 12 应付利息
        D040014  , -- 13 钞汇类别
        D040013  , -- 14 采集日期
        DIS_DATA_DATE,
        DIS_BANK_ID ,   -- 机构号
	    DEPARTMENT_ID ,      -- 业务条线
	    DIS_DEPT
	)
	SELECT 
	     T1.ACCT_NUM                                      , -- 01 分户账号
		 ORG.ORG_ID                                       , -- 02 机构ID
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 03 会计日期
		 T1.CURR_CD                                       , -- 04 币种
		 NVL(T2.DEBIT_BAL,0) * -1                                     , -- 05 期初借方余额
		 NVL(T2.CREDIT_BAL,0)                                   , -- 06 期初贷方余额
		 NVL((T1.DEBIT_BAL - NVL(T2.DEBIT_BAL,0)),0) * -1                      , -- 07 本期借方发生额
		 NVL((T1.CREDIT_BAL - NVL(T2.CREDIT_BAL,0)),0)                     , -- 08 本期贷方发生额
		 NVL(T1.DEBIT_BAL,0) * -1                                    , -- 09 期末借方余额
		 NVL(T1.CREDIT_BAL,0)                                     , -- 10 期末贷方余额
		 '0'                                             , -- 11 应收利息
		 '0'                                             , -- 12 应付利息
		 CASE WHEN T1.CURR_CD = 'CNY' THEN NULL
		      ELSE '02'
		       END                                        , -- 13 钞汇类别
		 TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 14 采集日期
         TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
         T1.ORG_NUM,                                                   --  '机构号'
		 '009806' ,                                                         -- 业务条线  默认计划财务部
		 '内部分户账'
		 FROM SMTMODS.L_ACCT_INNER T1
         LEFT JOIN SMTMODS.L_ACCT_INNER T2 -- 关联前一天内部账，取期初余额
		        ON T1.ACCT_NUM = T2.ACCT_NUM
			   AND T2.DATA_DATE = LAST_DT
		 LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
                ON T1.ORG_NUM = ORG.ORG_NUM
               AND ORG.DATA_DATE = I_DATE	   
		 WHERE T1.DATA_DATE = I_DATE
		   AND T1.ITEM_ID NOT LIKE '9%'
           AND T1.ACCT_NUM NOT LIKE T1.O_ACCT_NUM||T1.ITEM_ID||'%'
           AND (SUBSTR(T1.ACCT_STATE,1,1)<>'C' OR T1.CLOSE_DATE = I_DATE)
           AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_PUBL_ORG_BRA B WHERE B.ORG_NUM = T1.ORG_NUM 
                                   AND B.ORG_NAM LIKE '%村镇%'
                                   AND B.DATA_DATE = I_DATE)
           AND NOT EXISTS (SELECT 1 FROM ybt_datacore.T_4_4 A WHERE A.D040001 = T1.ACCT_NUM 
                           AND A.D040013 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'))
           AND T1.ORG_NUM <> '999999'
           and T1.ACCT_NUM not in ('9019800217000015_1')  -- [2025-03-27] [周敬坤] [邮件需求][吴大为] 为重点指标数据不重复    内部账不报送信用卡溢缴款内部账账号

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

