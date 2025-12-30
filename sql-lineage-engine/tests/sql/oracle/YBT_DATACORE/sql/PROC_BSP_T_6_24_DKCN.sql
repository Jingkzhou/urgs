DROP Procedure IF EXISTS `PROC_BSP_T_6_24_DKCN` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_24_DKCN"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：贷款承诺
      程序功能  ：加工贷款承诺
      目标表：T_6_24
      源表  ：
      创建人  ：JLF
      创建日期  ：20240108
      版本号：V0.0.1 
  ******/
 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/	
 /*需求编号：JLBA202509280009 上线日期：2025-10-28，修改人：巴启威，提出人：吴大为 修改原因：关于一表通监管数据报送系统修改逻辑的需求 */
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_24_DKCN';
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
	
	DELETE FROM T_6_24 WHERE F240018 = TO_CHAR(P_DATE,'YYYY-MM-DD');
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT  INTO T_6_24  
            (
            F240001,   --  01'协议ID'
            F240002,   --  02'业务号码'
            F240003,   --  03'机构ID'
            F240004,   --  04'客户ID'
            F240005,   --  05'业务额度'
            F240006,   --  06'币种'
            F240007,   --  07'承诺类型'
            F240008,   --  08'科目ID'
            F240009,   --  09'科目名称'
            F240010,   --  10'未使用的额度'
            F240011,   --  11'起始日期'
            F240012,   --  12'到期日期'
            F240013,   --  13'协议状态'
            F240014,   --  14'重点产业标识'
            F240015,   --  15'经办员工ID'
            F240016,   --  16'审查员工ID'
            F240017,   --  17'审批员工ID'
            F240018,   --  18'采集日期'
            DIS_DATA_DATE,
            DIS_BANK_ID,
            DEPARTMENT_ID ,
            F240019
           )
           
     SELECT  
           T.ACCT_NO        ,     --  01'协议ID'     
           T.ACCT_NUM       ,     --  02'业务号码'
           SUBSTR(TRIM(C.FIN_LIN_NUM ),1,11)||T.ORG_NUM   ,     --  03'机构ID'
           T.CUST_ID     ,     --  04'客户ID'
           T.BALANCE , -- NVL(A.FACILITY_AMT,0),     --  05'业务额度'
           T.CURR_CD     ,     --  06'币种'
           CASE WHEN  T.GL_ITEM_CODE ='70300101' THEN '01'
                WHEN  T.GL_ITEM_CODE ='70300201' THEN '02'
                ELSE '03'
                END      ,  --  07'承诺类型'
           T.GL_ITEM_CODE,     --  08'科目ID'
           B.GL_CD_NAME  ,     --  09'科目名称'
           T.BALANCE  ,  --  10'未使用的额度'  授信额度 - 已使用授信额度
           TO_CHAR(TO_DATE(T.BUSINESS_DT,'YYYYMMDD'),'YYYY-MM-DD') , --  11'起始日期'
           TO_CHAR(TO_DATE(T.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD') , --  12'到期日期'
           CASE 
            WHEN T.BUSI_STATUS = '01' THEN  '02' -- 待生效
           	WHEN T.BUSI_STATUS = '02' THEN  '01' -- 正常
           	WHEN T.BUSI_STATUS = '03' THEN  '06' -- 无效
            WHEN T.BUSI_STATUS = '05' THEN  '05' -- 撤销
           	WHEN T.BUSI_STATUS = '06' THEN  '04' -- 终止
           	WHEN T.BUSI_STATUS = '00' THEN  '00' -- 其他
           END                ,     --  13'协议状态'
           NVL(D.INDUST_RSTRUCT_FLG,'0') || DECODE(D.INDUST_TRAN_FLG,'1','1','2','0','0') || REPLACE(NVL(D.INDUST_STG_TYPE,'0'),'#','0')
                              ,     --  14'重点产业标识'
           coalesce(T.JBYG_ID,T.STAFF_NUM)       ,   --  15'经办员工ID' [20251028][巴启威][JLBA202509280009][吴大为]: 贷款承诺协议无审批流，经办员工取客户经理
           '自动'             ,     --  16'审查员工ID'[20251028][巴启威][JLBA202509280009][吴大为]: 贷款承诺协议无审批流，默认自动
           '自动'             ,     --  17'审批员工ID'[20251028][巴启威][JLBA202509280009][吴大为]: 贷款承诺协议无审批流，默认自动
           TO_CHAR(P_DATE,'YYYY-MM-DD') , --  18'采集日期'
           TO_CHAR(P_DATE,'YYYY-MM-DD') , --  18'采集日期'
           T.ORG_NUM,
           CASE WHEN T.DEPARTMENTD= '普惠金融' THEN '0098PH'  
                WHEN T.DEPARTMENTD= '公司金融'  THEN '0098JR' 
                ELSE '0098JR' 
                END  AS DEPARTMENT_ID ,
        --  a.FACILITY_NO 
          T.ACCT_NO
     FROM SMTMODS.L_ACCT_OBS_LOAN T -- 表外
     LEFT JOIN SMTMODS.L_AGRE_CREDITLINE A  -- 授信额度表
       ON T.FACILITY_NO=A.FACILITY_NO
      AND A.DATA_DATE = I_DATE
     LEFT JOIN  SMTMODS.L_FINA_INNER B
       ON T.GL_ITEM_CODE =B.STAT_SUB_NUM
      AND B.DATA_DATE = I_DATE
      AND B.ORG_NUM='990000' 
     LEFT JOIN VIEW_L_PUBL_ORG_BRA C -- 机构表
       ON T.ORG_NUM = C.ORG_NUM
      AND C.DATA_DATE = I_DATE 
     LEFT JOIN SMTMODS.L_ACCT_LOAN D
       ON T.ACCT_NO=D.ACCT_NUM
      AND D.DATA_DATE=I_DATE
    WHERE T.DATA_DATE = I_DATE
      AND SUBSTR(T.ACCT_TYP,1,1) = '5'
      AND (t.ACCT_STS = '1'
	      OR (t.ACCT_STS = '2' AND substr(T.MATURITY_DT,1,4)= SUBSTR(I_DATE,1,4)) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
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

