DROP Procedure IF EXISTS `PROC_BSP_T_3_6_GTZWR` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_3_6_GTZWR"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回code
                                        OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN
/******
      程序名称  ：共同债务人
      程序功能  ：加工共同债务人
      目标表：T_3_6
      源表  ：一段
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	
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
	SET P_PROC_NAME = 'PROC_BSP_T_3_6_GTZWR';
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
	
	DELETE FROM T_3_6 WHERE C060009 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';

INSERT INTO T_3_6 
(
   C060001, -- 01.关系ID
   C060002, -- 02.机构ID
   C060003, -- 03.共同债务人名称
   C060004, -- 04.共同债务人证件类型
   C060005, -- 05.共同债务人证件号码
   C060006, -- 06.借款人ID
   C060007, -- 07.借据ID
   C060008, -- 08.关系状态
   C060009, -- 09.采集日期
   DIS_DATA_DATE, -- 装入数据日期
   DIS_BANK_ID,   -- 机构号
   DEPARTMENT_ID       -- 业务条线
)
   SELECT 
   T.LOAN_NUM||T.GTZWRZJHM       	, -- 01.关系ID
   ORG.ORG_ID        				, -- 02.机构ID
   T.GTZWRMC        				, -- 03.共同债务人名称
   M.GB_CODE     					, -- 04.共同债务人证件类型
   T.GTZWRZJHM      				, -- 05.共同债务人证件号码
   T.CUST_ID        				, -- 06.借款人ID
   T.LOAN_NUM       				, -- 07.借据ID
   '01'              				, -- 08.关系状态 01 有效 02 无效  默认有效
   TO_CHAR(TO_DATE(T.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,       -- 09.采集日期
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),             --  '装入数据日期'
   T2.ORG_NUM,                                                   --  '机构号'
   '0098LDB'                                                     --   业务条线  默认零售信贷部
    FROM SMTMODS.L_CUST_JOINT_DEBTOR T -- 共同债务人信息表 
   INNER JOIN SMTMODS.L_ACCT_LOAN T2 -- 贷款借据信息表
      ON T.LOAN_NUM = T2.LOAN_NUM
     AND T2.DATA_DATE = I_DATE
   INNER JOIN SMTMODS.L_CUST_P T3 -- 对私客户补充信息表
      ON T.CUST_ID = T3.CUST_ID
     AND T3.DATA_DATE = I_DATE
    LEFT JOIN M_DICT_CODETABLE M -- 码值表 取证件类型
      ON T.GTZWRZJLX = M.L_CODE
     AND M.L_CODE_TABLE_CODE = 'C0001'
    LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构视图
  	  ON T2.ORG_NUM = ORG.ORG_NUM
     AND ORG.DATA_DATE = I_DATE
   WHERE T.DATA_DATE = I_DATE
     AND T2.OD_FLG = 'Y' -- 逾期标志为是的
     AND T2.OD_DAYS >= '90' -- 逾期天数大于等于90天的
      AND NOT EXISTS(SELECT A.LOAN_NUM,A.WRITE_OFF_DATE -- 核销日期
                FROM SMTMODS.L_ACCT_WRITE_OFF A -- 贷款核销
                WHERE A.DATA_DATE = I_DATE
                  AND A.WRITE_OFF_DATE < I_DATE 
                  AND A.LOAN_NUM = T2.LOAN_NUM ) -- 剔除已核销的借据，与8.1范围一致，20241115 87v
	  AND (T2.LOAN_STOCKEN_DATE = I_DATE or T2.LOAN_STOCKEN_DATE is null)  -- add by haorui 20250311 JLBA202408200012_关于新一代信贷管理系统增加不良资产收益权转让账务处理功能的需求
     ;
     
INSERT INTO T_3_6 
(
   C060001, 				-- 01.关系ID
   C060002, 				-- 02.机构ID
   C060003, 				-- 03.共同债务人名称
   C060004, 				-- 04.共同债务人证件类型
   C060005, 				-- 05.共同债务人证件号码
   C060006, 				-- 06.借款人ID
   C060007, 				-- 07.借据ID
   C060008, 				-- 08.关系状态
   C060009, 				-- 09.采集日期
   DIS_DATA_DATE,			-- 装入数据日期
   DIS_BANK_ID,   			-- 机构号
   DEPARTMENT_ID        -- 业务条线
)
   SELECT 
   T1.LOAN_NUM||T3.RE_CUST_ID       	, -- 01.关系ID
   ORG.ORG_ID        					, -- 02.机构ID
   NVL(T3.RE_CUST_NAME,T4.CUST_NAM)    	, -- 03.共同债务人名称
   M.GB_CODE     						, -- 04.共同债务人证件类型
   NVL(T3.ID_NO,T4.ID_NO)			   	, -- 05.共同债务人证件号码
   T1.CUST_ID        					, -- 06.借款人ID
   T1.LOAN_NUM       					, -- 07.借据ID
   '01'              					, -- 08.关系状态 01 有效 02 无效  默认有效
   TO_CHAR(TO_DATE(T1.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,      --  '采集日期'
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),         --  '装入数据日期'
   T2.ORG_NUM,                                                   --  '机构号'
   '0098LDB'                                                     --  '业务条线  默认零售信贷部'
    FROM SMTMODS.L_ACCT_LOAN T1 -- 贷款借据信息表
   INNER JOIN SMTMODS.L_CUST_P T2 -- 对私客户补充信息表
      ON T1.CUST_ID = T2.CUST_ID
     AND T2.DATA_DATE = I_DATE
   INNER JOIN SMTMODS.L_CUST_R_RELATED_P T3 -- 个人客户关系人信息
      ON T1.CUST_ID = T3.CUST_ID
     AND T3.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_CUST_ALL T4 -- 全量客户信息表
      ON T3.RE_CUST_ID = T4.CUST_ID
     AND T4.DATA_DATE = I_DATE
    LEFT JOIN M_DICT_CODETABLE M -- 码值表 取证件类型
      ON T4.ID_TYPE = M.L_CODE
     AND M.L_CODE_TABLE_CODE = 'C0001'
    LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构视图
  	  ON T1.ORG_NUM = ORG.ORG_NUM
     AND ORG.DATA_DATE = I_DATE
   WHERE T1.DATA_DATE = I_DATE
     AND T3.RE_CUST_TYP = '1' -- '1' 配偶
     AND T1.OD_FLG = 'Y'  -- 逾期标志为是的
     AND T1.OD_DAYS >= '90' -- 逾期天数大于90天的
     AND T1.ACCT_STS <> '3' -- 不取结清的借据
     AND T1.LOAN_ACCT_BAL <> '0' -- 不取贷款余额为0的借据
     AND T1.CANCEL_FLG = 'N' -- 不取核销的借据
     AND T1.LOAN_STOCKEN_DATE IS NULL    -- add by haorui 20250311 JLBA202408200012 资产未转让
     AND T1.INTERNET_LOAN_FLG = 'N' -- 不取互联网贷款
     AND T3.RELA_STS = '1' -- 关系状态为有效的
     AND T2.MARRIAGE_TYP IN ('20','21','22','23')-- 20	 已婚  21	 初婚  22	 再婚  23	 复婚
     AND T3.ID_NO NOT IN (SELECT GTZWRZJHM FROM SMTMODS.L_CUST_JOINT_DEBTOR WHERE DATA_DATE = I_DATE)
     ;
     
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

