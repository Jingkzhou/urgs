DROP Procedure IF EXISTS `PROC_BSP_T_6_11_XYZXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_11_XYZXY"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回CODE
                                        OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
)
BEGIN

  /******
      程序名称  ：信用证协议
      程序功能  ：加工信用证协议
      目标表：T_6_11
      源表  ：
      创建人  ：87V
      创建日期  ：20240112
      版本号：V0.0.1 
  ******/
	-- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311
	/*需求编号：JLBA202504160004   上线日期：20250708，修改人：姜俐锋，提出人：吴大为 关于吉林银行修改单一客户授信逻辑的需求*/
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_11_XYZXY';
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

	DELETE FROM T_6_11 WHERE F110038 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	
   	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);													
		
	
	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
   INSERT INTO T_6_11  (
          F110001  , -- 01 协议ID
          F110002  , -- 02 业务号码
          F110003  , -- 03 机构ID
          F110004  , -- 04 客户ID
          F110005  , -- 05 产品ID
          F110006  , -- 06 信用证种类
          F110007  , -- 07 信用证ID
          F110008  , -- 08 协议币种
          F110009  , -- 09 开证金额
          F110010  , -- 10 开证日期
          F110011  , -- 11 到期日期
          F110012  , -- 12 支付类型
          F110013  , -- 13 远期天数
          F110014  , -- 14 垫款利率
          F110015  , -- 15 贸易合同编号
          F110016  , -- 16 货品名称
          F110017  , -- 17 贸易合同金额
          F110018  , -- 18 合同贸易背景
          F110019  , -- 19 申请人国家代码
          F110020  , -- 20 受益人名称
          F110021  , -- 21 受益人国家地区
          F110022  , -- 22 受益人开户行名称
          F110023  , -- 23 重点产业标识
          F110024  , -- 24 代开信用证标识
          F110025  , -- 25 代开信用证的申请行的行名
          F110026  , -- 26 支付期限
          F110027  , -- 27 手续费币种
          F110028  , -- 28 手续费金额
          F110029  , -- 29 保证金账号
          F110030  , -- 30 保证金币种
          F110031  , -- 31 保证金金额
          F110032  , -- 32 保证金比例
          F110033  , -- 33 经办员工ID
          F110034  , -- 34 审查员工ID
          F110035  , -- 35 审批员工ID
          F110036  , -- 36 备注
          F110037  , -- 37 受益人开户行账号
          F110038  , -- 38 采集日期
          DIS_DATA_DATE , -- 装入数据日期
          DIS_BANK_ID   , -- 机构号
          DIS_DEPT      ,
          DEPARTMENT_ID , -- 业务条线
          F110039, -- 绿色融资类型
          F110040
       )
 SELECT  
      T1.ACCT_NO   AS  F110001      , -- 01 协议ID
	  T1.ACCT_NO   AS  F110002      , -- 02 业务号码
	  ORG.ORG_ID   AS  F110003      , -- 03 机构ID
	  T1.CUST_ID   AS  F110004      , -- 04 客户ID
	  T5.CP_ID     AS  F110005      , -- 05 产品ID -- 新增字段
	  CASE 
	    WHEN T2.LETT_TYPE ='国内信用证' THEN  '01'
	    WHEN T2.LETT_TYPE ='国际信用证' THEN '02'
	  --  WHEN T2.LETT_TYPE ='备用信用证' THEN  '03'
	  END          AS  F110006      , -- 06 信用证种类
	  T2.LC_NBR    AS  F110007      , -- 07 信用证ID
	  T1.CURR_CD   AS  F110008      , -- 08 协议币种
	  T3.LETT_AMT  AS  F110009      , -- 09 开证金额
	  TO_CHAR(TO_DATE(T1.BUSINESS_DT,'YYYYMMDD'),'YYYY-MM-DD') AS F110010, -- 10 开证日期
	  TO_CHAR(TO_DATE(T1.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD') AS F110011, -- 11 到期日期
	  CASE 
	    WHEN T3.LETT_PAY_TYPE ='即期支付' THEN '01' -- 即期付款
	    WHEN T3.LETT_PAY_TYPE ='远期支付' THEN '02' -- 延期付款
	  END          AS  F110012      , -- 12 支付类型
	  NVL(T2.YQTS,0)  AS  F110013   , -- 13 远期天数  -- 新增字段
	  CASE WHEN T1.MONEYADVANCED_FLG = 'Y' THEN T4.REAL_INT_RAT 
	  ELSE NULL
	   END            AS  F110014   , -- 14 垫款利率
	  T3.TRAD_CON_NUM AS  F110015   , -- 15 贸易合同编号
	  T3.GOODS_DESCRIOTION AS F110016, -- 16 货品名称
	  T1.TRAN_AMT     AS  F110017   , -- 17 贸易合同金额
	  T1.TRADE_CONT_BACK AS F110018 , -- 18 合同贸易背景
	  -- T1.NATION_CD                  , -- 19 申请人国家代码
	  CA.NATION_CD    AS  F110019   , -- 19 申请人国家代码
	  SUBSTR(T1.BENE_CUST_NAME,1,200) AS  F110020, -- 20 受益人名称
	  T1.BENE_CUST_NATION AS F110021   , -- 21 受益人国家地区
	  T1.BENE_CUST_OPEN_BANK AS F110022, -- 22 受益人开户行名称
	  NVL(T4.INDUST_RSTRUCT_FLG,'0') || DECODE(T4.INDUST_TRAN_FLG,'1','1','2','0','0') || REPLACE(NVL(T4.INDUST_STG_TYPE,'0'),'#','0') AS F110023, -- 23 重点产业标识
	  -- T2.DKXYZBS                    , -- 24 代开信用证标识  -- 新增字段
  	  '0'             AS  F110024   , -- 24 代开信用证标识  -- 默认 0-否
	  -- T2.DKSQHHM                    , -- 25 代开信用证的申请行的行名  -- 新增字段
      NULL            AS  F110025   , -- 25 代开信用证的申请行的行名  -- 默认空
	  -- T2.DKSQHHM                    , -- 25 代开信用证的申请行的行名  -- 新增字段
	  T2.LC_PAY_TERM  AS  F110026   , -- 26 支付期限
	  'CNY'           AS  F110027   , -- 27 手续费币种   -- 信贷反馈手续费币种默认都是人民币 
	  nvl(T1.COST_AMOUNT,0)  AS  F110028   , -- 28 手续费金额
	  T1.SECURITY_ACCT_NUM  AS  F110029, -- 29 保证金账号
	  T1.SECURITY_CURR AS  F110030  , -- 30 保证金币种
	  T1.SECURITY_AMT  AS  F110031  , -- 31 保证金金额
	  T1.SECURITY_RATE AS  F110032  , -- 32 保证金比例
	  CASE WHEN T1.JBYG_ID= 'wd012601' THEN '自动'  -- 网贷崔永哲：虚拟操作员号 有一段时间业务流程里面没有客户经理编号 就直接塞这个操作号了，与苏桐确认，默认为自动
           ELSE NVL(T1.JBYG_ID,'自动')
           END AS  F110033          , -- 33 经办员工ID  -- 新增字段 大为哥与国际业务部确认，为空置为 自动
	  NVL(T1.SZYG_ID,'自动')        , -- 34 审查员工ID  -- 新增字段 大为哥与国际业务部确认，为空置为 自动
	  NVL(T1.SPYG_ID,'自动')        , -- 35 审批员工ID  -- 新增字段 大为哥与国际业务部确认，为空置为 自动
	  NULL             AS  F110036  , -- 36 备注
	  T1.BENE_CUST_ACC AS  F110037  , -- 37 受益人开户行账号
	  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS  F110038, -- 38 采集日期
      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
	  T1.ORG_NUM                                      , -- 机构号
	  '1',
      '0098GJ',                                     -- 业务条线    -- 国际业务（贸易金融）部
      T6.GB_CODE    AS  F110039, -- 40 绿色融资类型,
      -- G.FACILITY_NO AS  F110040  -- 授信ID 20250311  
      T5.FACILITY_NO AS  F110040  -- 授信ID -- [20250708][姜俐锋][JLBA202504160004][吴大为]：修改取数方案直接从修改后合同表中授信号
      FROM SMTMODS.L_ACCT_OBS_LOAN T1  -- 贷款表外信息表
      LEFT JOIN SMTMODS.L_ACCT_OBS_LOAN_LC T2 -- 信用证业务补充信息  --李晓东：信用证补充信息中我看只取了信用证的数据，没看见保函的
        ON T1.ACCT_NO = T2.CONTRACT_NUM
       AND T2.DATA_DATE = I_DATE
     INNER JOIN SMTMODS.L_CUST_ALL CA
        ON T1.CUST_ID = CA.CUST_ID
       AND CA.DATA_DATE = I_DATE
	  LEFT JOIN SMTMODS.L_ACCT_TRAD_FIN T3 -- 贸易融资补充信息
        ON T1.ACCT_NO = T3.ACCT_NUM
       AND T3.DATA_DATE = I_DATE   	  
	  LEFT JOIN SMTMODS.L_ACCT_LOAN T4
     	ON T1.ACCT_NO = T4.ACCT_NUM  
	   AND T4.DATA_DATE = I_DATE   	  	
	   AND T4.ACCT_TYP_DESC = '信用证垫款'
      LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T5 -- 贷款合同信息表
        ON T1.ACCT_NO = T5.CONTRACT_NUM
       AND T5.DATA_DATE = I_DATE
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON T1.ORG_NUM = ORG.ORG_NUM
       AND ORG.DATA_DATE = I_DATE
      LEFT JOIN M_DICT_CODETABLE T6              
        ON T6.L_CODE = T1.GREE_LOAN
       AND T6.L_CODE_TABLE_CODE = 'C0098'  
    /*LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G  -- 20250311 新增关联取授信额度  -- [20250708][姜俐锋][JLBA202504160004][吴大为]：修改取数方案直接从修改后合同表中授信号
        ON T1.CUST_ID = G.CUST_ID
       AND G.FACILITY_TYP IN ('2','4')     
       AND G.DATA_DATE  = I_DATE */       
     WHERE T1.DATA_DATE = I_DATE -- 此处条件与表8.2代码同步
      -- AND T1.ACCT_TYP NOT IN ('111','112')
       AND SUBSTR(T1.GL_ITEM_CODE,1,4) = ('7010') -- 开出信用证    EAST的BSP_SP_EAST5_IE_009_BHYXYZB是保函与信用证，包括了一表通的6.11和6.12
       AND (
          (T1.BUSI_STATUS = '02' /*02-正常*/ AND T1.ACCT_STS = '1' /*1-有效*/ )  
	   OR 
	   -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
	     T1.MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101'
           )
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


