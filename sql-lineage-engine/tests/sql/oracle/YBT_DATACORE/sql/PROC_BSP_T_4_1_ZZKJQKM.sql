DROP Procedure IF EXISTS `PROC_BSP_T_4_1_ZZKJQKM` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_4_1_ZZKJQKM"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回code
                                        OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN
 
  /******
      程序名称  ：总账会计全科目
      程序功能  ：加工总账会计全科目
      目标表：T_4_1
      源表  ：
      创建人  ：87v
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	-- JLBA202411070004_关于一表通监管数据报送系统修改逻辑的需求
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
	SET P_PROC_NAME = 'PROC_BSP_T_4_1_ZZKJQKM';
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
	
	DELETE FROM T_4_1 WHERE D010012 =  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
		
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.2插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '总账数据';
	
    INSERT  INTO T_4_1  (
       D010001   , -- 01 机构ID
       D010002   , -- 02 科目ID
       D010003   , -- 03 期初借方余额
       D010004   , -- 04 期初贷方余额
       D010005   , -- 05 本期借方发生额
       D010006   , -- 06 本期贷方发生额
       D010007   , -- 07 期末借方余额
       D010008   , -- 08 期末贷方余额
       D010009   , -- 09 币种
       D010010   , -- 10 会计日期
       D010011   , -- 11 报表周期
       D010012   , -- 12 采集日期
	   DIS_DATA_DATE, -- 装入数据日期
	   DIS_BANK_ID,   -- 机构号
       DIS_DEPT,
       DEPARTMENT_ID
       )
   SELECT    substr(TRIM(T3.FIN_LIN_NUM),1,11) || T1.ORG_NUM                , -- 01 机构ID
             T2.STAT_SUB_NUM           , -- 02 科目ID
             NVL(TA.DEBIT_BAL, 0)      , -- 03 期初借方余额
             NVL(TA.CREDIT_BAL, 0)     , -- 04 期初贷方余额
             NVL(T1.DEBIT_D_AMT,0)     , -- 05 本期借方发生额
   		     NVL(T1.CREDIT_D_AMT,0)    , -- 06 本期贷方发生额
   		     NVL(T1.DEBIT_BAL,0)       , -- 07 期末借方余额
   		     NVL(T1.CREDIT_BAL,0)      , -- 08 期末贷方余额
   		     T1.CURR_CD                , -- 09 币种
   		     TO_CHAR(TO_DATE(T1.ACCTOUNT_DT,'YYYYMMDD'),'YYYY-MM-DD')            , -- 10 会计日期
   		     '01'                    , -- 11 报表周期'日报'
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 12 采集日期
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), 
             T1.ORG_NUM,
             '',
             '009806'
         FROM SMTMODS.L_FINA_GL T1   -- 20240101
         LEFT JOIN SMTMODS.L_FINA_GL TA  -- 20231231
           ON   T1.ORG_NUM = TA.ORG_NUM
          AND T1.ITEM_CD = TA.ITEM_CD
          AND T1.CURR_CD = TA.CURR_CD
		  AND TA.DATA_DATE= TO_CHAR(TO_DATE(I_DATE, 'YYYYMMDD') - 1, 'YYYYMMDD')-- 20240627 LDP V1.0 总账科目表(上一日)
         INNER JOIN SMTMODS.L_FINA_INNER T2
            ON T1.ITEM_CD = T2.STAT_SUB_NUM
           AND T1.ORG_NUM=T2.ORG_NUM
           AND T2.DATA_DATE = I_DATE
      -- LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T3
         INNER JOIN  
       ( SELECT * FROM SMTMODS.L_PUBL_ORG_BRA T1
            WHERE T1.DATA_DATE = I_DATE
              AND T1.ORG_NUM<>'999999' AND T1.ORG_NUM NOT LIKE '5%' AND T1.ORG_NUM NOT LIKE '6%' AND T1.ORG_NUM NOT LIKE '7%' AND  T1.ORG_NAM NOT  LIKE  '%村镇%' 
              AND T1.ORG_NUM NOT IN ('120000','120100','120101','021203','020206','021305','020212','021407','020214','021204','020204', '010312','010624','010625','010627','010911','012512')-- 集团不报
              AND T1.BUSI_STATE <> '04' ) T3  -- JLBA202411070004_20241212 与1.1范围一致
           ON T1.ORG_NUM = T3.ORG_NUM
          AND T3.DATA_DATE = I_DATE
       WHERE T1.DATA_DATE = I_DATE
          AND T1.ORG_NUM NOT IN ('222222', '333333', '444444', '555555','999999')
          AND ((T1.DEBIT_D_AMT<>0 OR  T1.CREDIT_D_AMT<>0) -- 本期发生额<>0
               OR (T1.DEBIT_BAL<>0 OR T1.CREDIT_BAL<>0 ) -- 余额<>0
              )
          AND T1.CURR_CD not in('BWB','USY','CFC','UCY')  
          and t1.ITEM_CD not like '9%' -- 剔除配平科目，与4.2保持一致
          ;
    
       COMMIT;
    
       
  INSERT  INTO T_4_1  (
       D010001   , -- 01 机构ID
       D010002   , -- 02 科目ID
       D010003   , -- 03 期初借方余额
       D010004   , -- 04 期初贷方余额
       D010005   , -- 05 本期借方发生额
       D010006   , -- 06 本期贷方发生额
       D010007   , -- 07 期末借方余额
       D010008   , -- 08 期末贷方余额
       D010009   , -- 09 币种
       D010010   , -- 10 会计日期
       D010011   , -- 11 报表周期
       D010012   , -- 12 采集日期
	   DIS_DATA_DATE, -- 装入数据日期
	   DIS_BANK_ID,   -- 机构号
       DIS_DEPT,
       DEPARTMENT_ID
       )
        SELECT   
             SUBSTR(TRIM(T3.FIN_LIN_NUM),1,11) || T1.ORG_NUM   , -- 01 机构ID
             T2.STAT_SUB_NUM           , -- 02 科目ID
             NVL(TA.DEBIT_BAL, 0)      , -- 03 期初借方余额
             NVL(TA.CREDIT_BAL, 0)     , -- 04 期初贷方余额
             NVL(T1.DEBIT_M_AMT,0)     , -- 05 本期借方发生额
   		     NVL(T1.CREDIT_M_AMT,0)    , -- 06 本期贷方发生额
   		     NVL(T1.DEBIT_BAL,0)       , -- 07 期末借方余额
   		     NVL(T1.CREDIT_BAL,0)      , -- 08 期末贷方余额
   		     T1.CURR_CD                , -- 09 币种
   		     TO_CHAR(TO_DATE(T1.ACCTOUNT_DT,'YYYYMMDD'),'YYYY-MM-DD')            , -- 10 会计日期
   		     '02'                    , -- 11 报表周期'月报'
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 12 采集日期
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), 
             T1.ORG_NUM,
             '',
             '009806'
          FROM SMTMODS.L_FINA_GL T1   -- 20240101
          LEFT JOIN SMTMODS.L_FINA_GL TA  -- 20231231
            ON T1.ORG_NUM = TA.ORG_NUM
           AND T1.ITEM_CD = TA.ITEM_CD
           AND T1.CURR_CD = TA.CURR_CD
		   AND TA.DATA_DATE = TO_CHAR(TRUNC(TO_DATE(I_DATE,'YYYYMMDD'),'MM') -1,'YYYYMMDD')  -- 20240627 LDP V1.0 总账科目表(上一月)
         INNER JOIN SMTMODS.L_FINA_INNER T2
            ON T1.ITEM_CD = T2.STAT_SUB_NUM
           AND T1.ORG_NUM=T2.ORG_NUM
           AND T2.DATA_DATE = I_DATE
       --  LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T3
         INNER JOIN  
       ( SELECT * FROM SMTMODS.L_PUBL_ORG_BRA T1
            WHERE T1.DATA_DATE = I_DATE
              AND T1.ORG_NUM<>'999999' AND T1.ORG_NUM NOT LIKE '5%' AND T1.ORG_NUM NOT LIKE '6%' AND T1.ORG_NUM NOT LIKE '7%' AND  T1.ORG_NAM NOT  LIKE  '%村镇%' 
              AND T1.ORG_NUM NOT IN ('120000','120100','120101','021203','020206','021305','020212','021407','020214','021204','020204', '010312','010624','010625','010627','010911','012512')-- 集团不报
              AND T1.BUSI_STATE <> '04' ) T3  -- JLBA202411070004_20241212 与1.1范围一致
          ON T1.ORG_NUM = T3.ORG_NUM
          AND T3.DATA_DATE = I_DATE
       WHERE T1.DATA_DATE = I_DATE
          AND I_DATE = TO_CHAR(LAST_DAY(I_DATE),'YYYYMMDD')
          AND T1.ORG_NUM NOT IN ('222222', '333333', '444444', '555555','999999')
          AND ((T1.DEBIT_M_AMT<>0 OR  T1.CREDIT_M_AMT<>0) -- 本期发生额<>0
               OR (T1.DEBIT_BAL<>0 OR T1.CREDIT_BAL<>0 ) )-- 余额<>0
           AND T1.CURR_CD NOT IN('BWB','USY','CFC','UCY')
          and t1.ITEM_CD not like '9%' -- 剔除配平科目，与4.2保持一致
          ;
   COMMIT;  

           
        INSERT  INTO T_4_1  (
       D010001   , -- 01 机构ID
       D010002   , -- 02 科目ID
       D010003   , -- 03 期初借方余额
       D010004   , -- 04 期初贷方余额
       D010005   , -- 05 本期借方发生额
       D010006   , -- 06 本期贷方发生额
       D010007   , -- 07 期末借方余额
       D010008   , -- 08 期末贷方余额
       D010009   , -- 09 币种
       D010010   , -- 10 会计日期
       D010011   , -- 11 报表周期
       D010012   , -- 12 采集日期
	   DIS_DATA_DATE, -- 装入数据日期
	   DIS_BANK_ID,   -- 机构号
       DIS_DEPT,
       DEPARTMENT_ID
       )    
            SELECT 
             SUBSTR(TRIM(T3.FIN_LIN_NUM),1,11) || T1.ORG_NUM   , -- 01 机构ID
             T2.STAT_SUB_NUM           , -- 02 科目ID
             NVL(TA.DEBIT_BAL, 0)      , -- 03 期初借方余额
             NVL(TA.CREDIT_BAL, 0)     , -- 04 期初贷方余额
             NVL(T1.DEBIT_Q_AMT,0)     , -- 05 本期借方发生额
   		     NVL(T1.CREDIT_Q_AMT,0)    , -- 06 本期贷方发生额
   		     NVL(T1.DEBIT_BAL,0)       , -- 07 期末借方余额
   		     NVL(T1.CREDIT_BAL,0)      , -- 08 期末贷方余额
   		     T1.CURR_CD                , -- 09 币种
   		     TO_CHAR(TO_DATE(T1.ACCTOUNT_DT,'YYYYMMDD'),'YYYY-MM-DD')            , -- 10 会计日期
   		     '03'                    , -- 11 报表周期'季报'
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 12 采集日期
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), 
             T1.ORG_NUM,
             '',
             '009806'
         FROM SMTMODS.L_FINA_GL T1   -- 20240101
         LEFT JOIN SMTMODS.L_FINA_GL TA  -- 20231231
           ON T1.ORG_NUM = TA.ORG_NUM
          AND T1.ITEM_CD = TA.ITEM_CD
          AND T1.CURR_CD = TA.CURR_CD
		  AND TA.DATA_DATE = TO_CHAR(ADD_MONTHS(TRUNC(TO_DATE(I_DATE,'YYYYMMDD'),'MM'),-2)-1,'YYYYMMDD')  -- 20240627 LDP V1.0 总账科目表(上一季)
        INNER JOIN SMTMODS.L_FINA_INNER T2
           ON T1.ITEM_CD = T2.STAT_SUB_NUM
          AND T1.ORG_NUM=T2.ORG_NUM
          AND T2.DATA_DATE = I_DATE
       --  LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T3
        INNER JOIN  
        ( SELECT * FROM SMTMODS.L_PUBL_ORG_BRA T1
            WHERE T1.DATA_DATE = I_DATE
              AND T1.ORG_NUM<>'999999' AND T1.ORG_NUM NOT LIKE '5%' AND T1.ORG_NUM NOT LIKE '6%' AND T1.ORG_NUM NOT LIKE '7%' AND  T1.ORG_NAM NOT  LIKE  '%村镇%' 
              AND T1.ORG_NUM NOT IN ('120000','120100','120101','021203','020206','021305','020212','021407','020214','021204','020204', '010312','010624','010625','010627','010911','012512')-- 集团不报
              AND T1.BUSI_STATE <> '04' ) T3  -- JLBA202411070004_20241212 与1.1范围一致
           ON T1.ORG_NUM = T3.ORG_NUM
          AND T3.DATA_DATE = I_DATE
       WHERE T1.DATA_DATE = I_DATE
          AND SUBSTR(I_DATE, 5, 4) IN ('0331', '0630', '0930', '1231')
          AND T1.ORG_NUM NOT IN ('222222', '333333', '444444', '555555','999999')
          AND ((T1.DEBIT_Q_AMT<>0 OR  T1.CREDIT_Q_AMT<>0) -- 本期发生额<>0
               OR (T1.DEBIT_BAL<>0 OR T1.CREDIT_BAL<>0 ) )-- 余额<>0
           AND T1.CURR_CD NOT IN('BWB','USY','CFC','UCY')
          and t1.ITEM_CD not like '9%' -- 剔除配平科目，与4.2保持一致
          ;
   COMMIT;  
           
         INSERT  INTO T_4_1  (
       D010001   , -- 01 机构ID
       D010002   , -- 02 科目ID
       D010003   , -- 03 期初借方余额
       D010004   , -- 04 期初贷方余额
       D010005   , -- 05 本期借方发生额
       D010006   , -- 06 本期贷方发生额
       D010007   , -- 07 期末借方余额
       D010008   , -- 08 期末贷方余额
       D010009   , -- 09 币种
       D010010   , -- 10 会计日期
       D010011   , -- 11 报表周期
       D010012   , -- 12 采集日期
	   DIS_DATA_DATE, -- 装入数据日期
	   DIS_BANK_ID,   -- 机构号
       DIS_DEPT,
       DEPARTMENT_ID
       )      
            SELECT    SUBSTR(TRIM(T3.FIN_LIN_NUM),1,11) || T1.ORG_NUM   , -- 01 机构ID
             T2.STAT_SUB_NUM           , -- 02 科目ID
             NVL(TA.DEBIT_BAL, 0)      , -- 03 期初借方余额
             NVL(TA.CREDIT_BAL, 0)     , -- 04 期初贷方余额
             NVL(T1.DEBIT_H_Y_AMT,0)     , -- 05 本期借方发生额
   		     NVL(T1.CREDIT_H_Y_AMT,0)    , -- 06 本期贷方发生额
   		     NVL(T1.DEBIT_BAL,0)       , -- 07 期末借方余额
   		     NVL(T1.CREDIT_BAL,0)      , -- 08 期末贷方余额
   		     T1.CURR_CD                , -- 09 币种
   		     TO_CHAR(TO_DATE(T1.ACCTOUNT_DT,'YYYYMMDD'),'YYYY-MM-DD')            , -- 10 会计日期
   		     '04'                    , -- 11 报表周期'半年报'
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 12 采集日期
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), 
             T1.ORG_NUM,
             '',
             '009806'
         FROM SMTMODS.L_FINA_GL T1   -- 20240101
         LEFT JOIN SMTMODS.L_FINA_GL TA  -- 20231231
           ON T1.ORG_NUM = TA.ORG_NUM
          AND T1.ITEM_CD = TA.ITEM_CD
          AND T1.CURR_CD = TA.CURR_CD
		  AND TA.DATA_DATE = TO_CHAR(ADD_MONTHS(TRUNC(TO_DATE(I_DATE,'YYYYMMDD'),'MM'),-5)-1,'YYYYMMDD')   -- 20240627 LDP V1.0 总账科目表(上一半年)
        INNER JOIN SMTMODS.L_FINA_INNER T2
           ON T1.ITEM_CD = T2.STAT_SUB_NUM
          AND T1.ORG_NUM=T2.ORG_NUM
          AND T2.DATA_DATE = I_DATE
       --  LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T3
        INNER JOIN  
       ( SELECT * FROM SMTMODS.L_PUBL_ORG_BRA T1
            WHERE T1.DATA_DATE = I_DATE
              AND T1.ORG_NUM<>'999999' AND T1.ORG_NUM NOT LIKE '5%' AND T1.ORG_NUM NOT LIKE '6%' AND T1.ORG_NUM NOT LIKE '7%' AND  T1.ORG_NAM NOT  LIKE  '%村镇%' 
              AND T1.ORG_NUM NOT IN ('120000','120100','120101','021203','020206','021305','020212','021407','020214','021204','020204', '010312','010624','010625','010627','010911','012512')-- 集团不报
              AND T1.BUSI_STATE <> '04' ) T3  -- JLBA202411070004_20241212 与1.1范围一致
           ON T1.ORG_NUM = T3.ORG_NUM
          AND T3.DATA_DATE = I_DATE
       WHERE T1.DATA_DATE = I_DATE
          AND SUBSTR(I_DATE, 5, 4) IN ( '0630','1231')
          AND T1.ORG_NUM NOT IN ('222222', '333333', '444444', '555555','999999')
          AND ((T1.DEBIT_H_Y_AMT<>0 OR  T1.CREDIT_H_Y_AMT<>0) -- 本期发生额<>0
               OR (T1.DEBIT_BAL<>0 OR T1.CREDIT_BAL<>0 ) )-- 余额<>0
           AND T1.CURR_CD NOT IN('BWB','USY','CFC','UCY')
          and t1.ITEM_CD not like '9%' -- 剔除配平科目，与4.2保持一致
          ;  
          COMMIT;  
          
  INSERT  INTO T_4_1  (
       D010001   , -- 01 机构ID
       D010002   , -- 02 科目ID
       D010003   , -- 03 期初借方余额
       D010004   , -- 04 期初贷方余额
       D010005   , -- 05 本期借方发生额
       D010006   , -- 06 本期贷方发生额
       D010007   , -- 07 期末借方余额
       D010008   , -- 08 期末贷方余额
       D010009   , -- 09 币种
       D010010   , -- 10 会计日期
       D010011   , -- 11 报表周期
       D010012   , -- 12 采集日期
	   DIS_DATA_DATE, -- 装入数据日期
	   DIS_BANK_ID,   -- 机构号
       DIS_DEPT,
       DEPARTMENT_ID
       ) 
            SELECT    
             SUBSTR(TRIM(T3.FIN_LIN_NUM),1,11) || T1.ORG_NUM   , -- 01 机构ID
             T2.STAT_SUB_NUM           , -- 02 科目ID
             NVL(TA.DEBIT_BAL, 0)      , -- 03 期初借方余额
             NVL(TA.CREDIT_BAL, 0)     , -- 04 期初贷方余额
             NVL(T1.DEBIT_Y_AMT,0)     , -- 05 本期借方发生额
   		     NVL(T1.CREDIT_Y_AMT,0)    , -- 06 本期贷方发生额
   		     NVL(T1.DEBIT_BAL,0)       , -- 07 期末借方余额
   		     NVL(T1.CREDIT_BAL,0)      , -- 08 期末贷方余额
   		     T1.CURR_CD                , -- 09 币种
   		     TO_CHAR(TO_DATE(T1.ACCTOUNT_DT,'YYYYMMDD'),'YYYY-MM-DD')            , -- 10 会计日期
   		     '05'                    , -- 11 报表周期'年报'
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 12 采集日期
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), 
             T1.ORG_NUM,
             '',
             '009806'
         FROM SMTMODS.L_FINA_GL T1   -- 20240101
         LEFT JOIN SMTMODS.L_FINA_GL TA  -- 20231231
           ON T1.ORG_NUM = TA.ORG_NUM
          AND T1.ITEM_CD = TA.ITEM_CD
          AND T1.CURR_CD = TA.CURR_CD
		  AND TA.DATA_DATE = TO_CHAR(ADD_MONTHS(TRUNC(TO_DATE(I_DATE,'YYYYMMDD'),'MM'),-11)-1,'YYYYMMDD')  -- 20240627 LDP V1.0 总账科目表(上一年)
        INNER JOIN SMTMODS.L_FINA_INNER T2
           ON T1.ITEM_CD = T2.STAT_SUB_NUM
          AND T1.ORG_NUM=T2.ORG_NUM
          AND T2.DATA_DATE = I_DATE
       --  LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T3
         INNER JOIN  
       ( SELECT * FROM SMTMODS.L_PUBL_ORG_BRA T1
            WHERE T1.DATA_DATE = I_DATE
              AND T1.ORG_NUM<>'999999' AND T1.ORG_NUM NOT LIKE '5%' AND T1.ORG_NUM NOT LIKE '6%' AND T1.ORG_NUM NOT LIKE '7%' AND  T1.ORG_NAM NOT  LIKE  '%村镇%' 
              AND T1.ORG_NUM NOT IN ('120000','120100','120101','021203','020206','021305','020212','021407','020214','021204','020204', '010312','010624','010625','010627','010911','012512')-- 集团不报
              AND T1.BUSI_STATE <> '04' ) T3  -- JLBA202411070004_20241212 与1.1范围一致
          ON T1.ORG_NUM = T3.ORG_NUM
          AND T3.DATA_DATE = I_DATE
       WHERE T1.DATA_DATE = I_DATE
          AND SUBSTR(I_DATE, 5, 4) ='1231' 
          AND T1.ORG_NUM NOT IN ('222222', '333333', '444444', '555555','999999')
          AND ((T1.DEBIT_Y_AMT<>0 OR  T1.DEBIT_Y_AMT<>0) -- 本期发生额<>0
               OR (T1.DEBIT_BAL<>0 OR T1.CREDIT_BAL<>0 ) )-- 余额<>0
           AND T1.CURR_CD NOT IN('BWB','USY','CFC','UCY')
          and t1.ITEM_CD not like '9%' -- 剔除配平科目，与4.2保持一致
          ;  
      COMMIT;        
	
	
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
   
    #3.3插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '本外币合计';
 
   INSERT  INTO T_4_1  (
       D010001   , -- 01 机构ID
       D010002   , -- 02 科目ID
       D010003   , -- 03 期初借方余额
       D010004   , -- 04 期初贷方余额
       D010005   , -- 05 本期借方发生额
       D010006   , -- 06 本期贷方发生额
       D010007   , -- 07 期末借方余额
       D010008   , -- 08 期末贷方余额
       D010009   , -- 09 币种
       D010010   , -- 10 会计日期
       D010011   , -- 11 报表周期
       D010012 ,    -- 12 采集日期
       DIS_DATA_DATE, -- 装入数据日期
	   DIS_BANK_ID,   -- 机构号
       DIS_DEPT,
       DEPARTMENT_ID
       )
      SELECT    T1.D010001                , -- 01 机构ID
           T1.D010002                , -- 02 科目ID
           ROUND(SUM(CASE
                       WHEN T2.CONVERT_TYP = 'M' THEN
                        T1.D010003 * T2.CCY_RATE
                       WHEN T2.CONVERT_TYP = 'D' THEN
                        T1.D010003 / T2.CCY_RATE
                     END),
                 2) , -- 03 期初借方余额
           ROUND(SUM(CASE
                       WHEN T2.CONVERT_TYP = 'M' THEN
                        T1.D010004 * T2.CCY_RATE
                       WHEN T2.CONVERT_TYP = 'D' THEN
                        T1.D010004 / T2.CCY_RATE
                     END),
                 2) , -- 04 期初贷方余额
           ROUND(SUM(CASE
                       WHEN T2.CONVERT_TYP = 'M' THEN
                        T1.D010005 * T2.CCY_RATE
                       WHEN T2.CONVERT_TYP = 'D' THEN
                        T1.D010003 / T2.CCY_RATE
                     END),
                 2) , -- 05 本期借方发生额
           ROUND(SUM(CASE
                       WHEN T2.CONVERT_TYP = 'M' THEN
                        T1.D010006 * T2.CCY_RATE
                       WHEN T2.CONVERT_TYP = 'D' THEN
                        T1.D010003 / T2.CCY_RATE
                     END),
                 2) , -- 06 本期贷方发生额
           ROUND(SUM(CASE
                       WHEN T2.CONVERT_TYP = 'M' THEN
                        T1.D010007 * T2.CCY_RATE
                       WHEN T2.CONVERT_TYP = 'D' THEN
                        T1.D010003 / T2.CCY_RATE
                     END),
                 2) , -- 07 期末借方余额
           ROUND(SUM(CASE
                       WHEN T2.CONVERT_TYP = 'M' THEN
                        T1.D010008 * T2.CCY_RATE
                       WHEN T2.CONVERT_TYP = 'D' THEN
                        T1.D010003 / T2.CCY_RATE
                     END),
                 2) , -- 08 期末贷方余额

           'BWB' , -- 09 币种
           T1.D010010   , -- 10 会计日期
           T1.D010011   , -- 11 报表周期
           T1.D010012  ,   -- 12 采集日期
           T1.DIS_DATA_DATE, -- 装入数据日期
	       T1.DIS_BANK_ID,   -- 机构号
           '',
           '009806'
      FROM T_4_1 T1
    LEFT JOIN SMTMODS.L_PUBL_RATE T2
        ON T1.D010009 = T2.BASIC_CCY
       AND T2.FORWARD_CCY = 'CNY' 
       AND T1.D010010 = TO_CHAR(TO_DATE(T2.CCY_DATE,'YYYYMMDD'),'YYYY-MM-DD')
  WHERE T1.D010012 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  
     GROUP BY T1.D010001,
              T1.D010002,
			  'BWB' ,
			  T1.D010010,
			  T1.D010011,
			  T1.D010012,
			  T1.DIS_DATA_DATE, -- 装入数据日期
	          T1.DIS_BANK_ID   -- 机构号
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

