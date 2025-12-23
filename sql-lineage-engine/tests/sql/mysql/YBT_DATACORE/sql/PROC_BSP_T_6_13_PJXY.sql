DROP Procedure IF EXISTS `PROC_BSP_T_6_13_PJXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_13_PJXY"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回CODE
                                        OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
)
BEGIN

  /******
      程序名称  ：票据协议
      程序功能  ：加工票据协议
      目标表：T_6_12
      源表  ：
      创建人  ：87V
      创建日期  ：20240112
      版本号：V0.0.1 
  ******/
	-- JLBA202409120001_关于一表通监管数据报送系统修改逻辑的需求_二期 20241128 JLF
	-- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116
	-- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311
	/* 需求编号：JLBA202504060003 上线日期： 20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_13_PJXY';
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

	DELETE FROM T_6_13 WHERE F130049 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');	
   	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);													
	
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '2、直贴';
   INSERT INTO T_6_13  (
             F130001 , -- 01 协议ID
             F130002 , -- 02 业务号码
             F130003 , -- 03 机构ID
             F130004 , -- 04 客户ID
             F130005 , -- 05 出票人名称
             F130006 , -- 06 收款人名称
             F130007 , -- 07 承兑人名称
             F130008 , -- 08 业务类型
             F130009 , -- 09 科目ID
             F130010 , -- 10 科目名称
             F130011 , -- 11 收款人账号
             F130012 , -- 12 收款人开户行名称
             F130013 , -- 13 出票人账号
             F130014 , -- 14 出票人开户行名称
             F130015 , -- 15 票据类型
             F130016 , -- 16 票据号码
             F130017 , -- 17 电票标识
             F130018 , -- 18 重点产业标识
             F130019 , -- 19 协议币种
             F130020 , -- 20 票面金额
             F130021 , -- 21 保证金账号
             F130022 , -- 22 保证金币种
             F130023 , -- 23 保证金金额
             F130024 , -- 24 保证金比例
             F130025 , -- 25 在本行贴现标识
             F130026 , -- 26 贴现客户名称
             F130027 , -- 27 贴现人账号
             F130028 , -- 28 贴现人开户行名称
             F130029 , -- 29 贴现金额
             F130030 , -- 30 贴现日期
             F130031 , -- 31 贴现计息天数
             F130032 , -- 32 贴现利率
             F130033 , -- 33 贴现利息
             F130034 , -- 34 其他费用币种
             F130035 , -- 35 其他费用金额
             F130036 , -- 36 票据签发日期
             F130037 , -- 37 票据到期日期
             F130038 , -- 38 对应的承兑业务协议号
             F130039 , -- 39 代签承兑汇票标识
             F130040 , -- 40 代签承兑汇票的申请行的行名
             F130041 , -- 41 代签承兑汇票的开票行的行名
             F130042 , -- 42 经办员工ID
             F130043 , -- 43 审查员工ID
             F130044 , -- 44 审批员工ID
             F130045 , -- 45 或有负债标识
             F130046 , -- 46 贸易背景
             F130047 , -- 47 票据状态
             F130048 , -- 48 备注
             F130049 , -- 49 采集日期
             DIS_DATA_DATE , -- 装入数据日期
             DIS_BANK_ID   , -- 机构号
             DIS_DEPT      ,
             DEPARTMENT_ID , -- 业务条线
             F130050,    -- 绿色融资类型
             F130051,   -- 授信ID
             F130052    -- 借据ID
       )
   SELECT    
          -- A.ACCT_NUM || A.LOAN_NUM       , -- 01 协议ID  -- 唯一
           SUBSTR(A.ACCT_NUM || NVL(A.DRAFT_RNG,''),1,60) , -- 01 协议ID 
           A.LOAN_NUM                     , -- 02 业务号码
           ORG.ORG_ID                     , -- 03 机构ID
           A.CUST_ID                      , -- 04 客户ID
           B.AFF_NAME                     , -- 05 出票人名称
           B.RECE_NAME                    , -- 06 收款人名称
           B.PAY_BANK_NAME                , -- 07 承兑人名称
           '02'                           , -- 08 业务类型  02-直贴
		   A.ITEM_CD                      , -- 09 科目ID
		   D.GL_CD_NAME                   , -- 10 科目名称
		   B.RECE_ACCT_NUM                , -- 11 收款人账号
           B.RECE_BANK_NAME               , -- 12 收款人开户行名称
           B.AFF_ACCT_NUM                 , -- 13 出票人账号
           B.AFF_ACCT_BANK                , -- 14 出票人开户行名称
           CASE WHEN B.BILL_TYPE='1' THEN '01' -- 银行承兑汇票
                 WHEN B.BILL_TYPE='2' THEN '02' -- 商业承兑汇票
            END                           , -- 15 票据类型
		   B.BILL_NUM                     , -- 16 票据号码
		   CASE
		   WHEN B.IS_P_BILL = 'Y' THEN
            '0' -- 纸票
           ELSE
            '1' -- 电票
           END                            , -- 17 电票标识
		   '0'|| DECODE(A.INDUST_TRAN_FLG,'1','1','2','0','0') || REPLACE(NVL(A.INDUST_STG_TYPE,'0'),'#','0'), -- 18 重点产业标识  
		   --  [20250513][狄家卉][JLBA202504060003][吴大为]: 第一位：默认'0'第二位：取贷款借据表INDUST_TRAN_FLG[工业企业技术改造升级标识]，为空记作'0'第三位：取 贷款借据表INDUST_STG_TYPE[战略新兴产业类型]， 如果码值不在1-9或空，记作'0'
		   B.CURR_CD                      , -- 19 协议币种
		   B.AMOUNT                       , -- 20 票面金额
		   /*
		   E.SECURITY_ACCT_NUM            , -- 21 保证金账号
           E.SECURITY_CURR                , -- 22 保证金币种
           E.SECURITY_AMT                 , -- 23 保证金金额
           E.SECURITY_RATE                , -- 24 保证金比例
           */
		   NULL                           , -- 21   保证金账号 --默认空
           NULL                           , -- 22 保证金币种 --默认空
           0                              , -- 23 保证金金额 --默认空 默认0
           0                              , -- 24 保证金比例 --默认空默认0
           DECODE(B.SELF_DISCOUNT_FLG,'Y','1','N','0'), -- 25 在本行贴现标识  
           B.RECE_NAME                    , -- 26 贴现客户名称
           B.RECE_ACCT_NUM                , -- 27 贴现人账号
           B.RECE_BANK_CODE               , -- 28 贴现人开户行名称
           -- A.DRAWDOWN_AMT
           A.LOAN_ACCT_BAL 
            *(CASE WHEN B.CURR_CD = A.CURR_CD THEN 1
                   WHEN B.CURR_CD <>'CNY' AND A.CURR_CD = 'CNY' THEN 1/U.CCY_RATE
                   WHEN B.CURR_CD <>'CNY' AND A.CURR_CD <>'CNY' THEN 1*U1.CCY_RATE/U.CCY_RATE
                   WHEN B.CURR_CD = 'CNY' AND A.CURR_CD <>'CNY' THEN 1*U1.CCY_RATE
              END)                        , -- 29 贴现金额
		   TO_CHAR(TO_DATE(NVL(A.DRAWDOWN_DT,'99991231'),'YYYYMMDD'),'YYYY-MM-DD'), -- 30 贴现日期
		   A.INT_NUM_DATE                 , -- 31 贴现计息天数
           A.REAL_INT_RAT                 , -- 32 贴现利率
		   A.DISCOUNT_INTEREST
            *(CASE WHEN B.CURR_CD = A.CURR_CD THEN 1
                   WHEN B.CURR_CD <>'CNY' AND A.CURR_CD = 'CNY' THEN 1/U.CCY_RATE
                   WHEN B.CURR_CD <>'CNY' AND A.CURR_CD <>'CNY' THEN 1*U1.CCY_RATE/U.CCY_RATE
                   WHEN B.CURR_CD = 'CNY' AND A.CURR_CD <>'CNY' THEN 1*U1.CCY_RATE
              END)                        , -- 33 贴现利息
		   E.EXTRA_COST_CURR_CD           , -- 34 其他费用币种
           E.EXTRA_COST_AMOUNT            , -- 35 其他费用金额
           TO_CHAR(TO_DATE(B.OPEN_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 36 票据签发日期
           TO_CHAR(TO_DATE(B.MATU_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 37 票据到期日期
		   E.ACCT_NO                      , -- 38 对应的承兑业务协议号  -- BA:非我行承兑的，承兑协议号可为空
           CASE WHEN E.ACCT_NO IS NOT NULL 
             THEN '0' 
           ELSE 
             NULL 
           END                            , -- 39 代签承兑汇票标识 -- 默认空值  --按校验规则38非空时39非空，BA定默认0
           NULL                           , -- 40 代签承兑汇票的申请行的行名  -- 默认空值
           NULL                           , -- 41 代签承兑汇票的开票行的行名  -- 默认空值
           A.JBYG_ID                      , -- 42 经办员工ID -- 新增字段
		   A.SZYG_ID                      , -- 43 审查员工ID -- 新增字段
           A.SPYG_ID                      , -- 44 审批员工ID -- 新增字段           
           '0'                            , -- 45 或有负债标识 -- 默认0-否
		   E.TRADE_CONT_BACK              , -- 46 贸易背景
         --  '01'                          , -- 47 票据状态  -- 只有正常状态
         --  B.DRAFT_STATUS                 ,  -- 票据状态    0627 WWK
           CASE 
              WHEN B.DRAFT_STATUS IN ('01','02','03','04','05') THEN 
                B.DRAFT_STATUS
              ELSE 
                '00' -- 其他
            END                           , -- 47 票据状态
           CASE WHEN B.DRAFT_STATUS = '00' THEN  'F130047:' ||B.DRAFT_STATUS_DESC
              WHEN B.DRAFT_STATUS IN ('01','02','03','04','05') THEN NULL
              ELSE 'F130047:' ||M.L_CODE_NAME||'_1' END, -- 48 备注      字段逻辑修改0614，原逻辑为NULL                           , -- 48 备注
		   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 49 采集日期
		   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
		   A.ORG_NUM                                       , -- 机构号
		   '直贴',
           '009804'                                          -- 业务条线  -- 金融市场部
           ,F.GB_CODE   -- 绿色融资类型 -- 2.0 ZDSJ H
          -- ,COALESCE (G.FACILITY_NO ,G1.FACILITY_NO,G2.FACILITY_NO)  -- 授信ID  -- JLBA202409120001 20241128 原为NULL
           ,nvl(G.FACILITY_NO,G1.FACILITY_NO) -- [20250708][姜俐锋][JLBA202504160004][吴大为]： 修改授信ID 取数逻辑
           ,SUBSTR(A.ACCT_NUM || NVL(A.DRAFT_RNG,''),1,60)  -- 借据ID 20250311
         FROM SMTMODS.L_ACCT_LOAN A -- 贷款借据信息表
    LEFT JOIN SMTMODS.L_AGRE_BILL_INFO B -- 商业汇票票面信息表
           ON A.DRAFT_NBR = B.BILL_NUM
          AND B.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_PUBL_RATE U -- 汇率表
           ON U.CCY_DATE = I_DATE
          AND U.BASIC_CCY = B.CURR_CD -- 基准币种
          AND U.FORWARD_CCY = 'CNY'
    LEFT JOIN SMTMODS.L_PUBL_RATE U1 -- 汇率表
           ON U1.CCY_DATE = I_DATE
          AND U1.BASIC_CCY = A.CURR_CD -- 基准币种
          AND U1.FORWARD_CCY ='CNY'
    LEFT JOIN SMTMODS.L_FINA_INNER D
	       ON A.ITEM_CD = D.STAT_SUB_NUM
	      AND A.ORG_NUM = D.ORG_NUM
		  AND D.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_ACCT_OBS_LOAN E
	       ON A.DRAFT_NBR = E.ACCT_NUM
		  AND E.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_CUST_ALL LCA
           ON A.CUST_ID = LCA.CUST_ID
          AND LCA.DATA_DATE = I_DATE
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
           ON A.ORG_NUM = ORG.ORG_NUM
          AND ORG.DATA_DATE = I_DATE
    LEFT JOIN M_DICT_CODETABLE M -- 码表    备注字段使用0614
           ON M.L_CODE = B.DRAFT_STATUS
          AND M.L_CODE_TABLE_CODE = 'A0237'   
    LEFT JOIN SMTMODS.L_AGRE_BILL_INFO B1 -- 商业汇票票面信息表
           ON B.BILL_NUM = B1.BILL_NUM
          AND B1.DATA_DATE = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') -1 ,'YYYYMMDD')       
    LEFT JOIN M_DICT_CODETABLE F                -- 2.0 ZDSJ H
           ON F.L_CODE = A.GREEN_LOAN_TYPE
          AND F.L_CODE_TABLE_CODE = 'C0098' 
    LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G1  -- [20250708][姜俐锋][JLBA202504160004][吴大为]：票据类授信先取票号补齐部分授信id
           ON A.LOAN_NUM = G1.FACILITY_NO
          AND G1.DATA_DATE =I_DATE
    LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G   -- [20250708][姜俐锋][JLBA202504160004][吴大为]：票据类授信NGI有授信部分取对应授信id
           ON A.CUST_ID = G.CUST_ID  
          AND G.DATA_DATE =I_DATE
          AND G1.FACILITY_NO  IS NULL 
          AND G.FACILITY_TYP <> '1' 
          AND G.FACILITY_NO=A.LOAN_NUM -- [20250813][巴启威]：关联后重复，增加关联条件
   /* LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G  -- JLBA202409120001 20241128 新增关联取授信额度
           ON A.CUST_ID = G.CUST_ID
          AND G.FACILITY_TYP IN ('2','4')     
          AND G.DATA_DATE  = I_DATE
    LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G1   -- 20250116
           ON B.AFF_CODE = G1.CUST_ID
          AND G1.FACILITY_TYP IN ('2','4')     
          AND G1.DATA_DATE  = I_DATE       
    LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G2 
           ON B.PAY_CUSID = G2.CUST_ID
          AND G2.FACILITY_TYP = '3'
          AND G2.DATA_DATE  = I_DATE    */  
   WHERE A.DATA_DATE = I_DATE
     AND SUBSTR(A.ITEM_CD,1,6) IN('130101','130104')
     AND (A.ACCT_STS <> '3' OR 
          A.LOAN_ACCT_BAL > 0 OR 
          A.FINISH_DT >= SUBSTR(I_DATE,1,4)||'0101' ) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
     AND (B.DRAFT_STATUS NOT IN ('05','03') 
          OR (B1.DRAFT_STATUS NOT IN ('05','03') AND B.DRAFT_STATUS IN ('05','03')));  
          
          
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
   	
   	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '3、承兑';	
		INSERT INTO T_6_13  (
             F130001 , -- 01 协议ID
             F130002 , -- 02 业务号码
             F130003 , -- 03 机构ID
             F130004 , -- 04 客户ID
             F130005 , -- 05 出票人名称
             F130006 , -- 06 收款人名称
             F130007 , -- 07 承兑人名称
             F130008 , -- 08 业务类型
             F130009 , -- 09 科目ID
             F130010 , -- 10 科目名称
             F130011 , -- 11 收款人账号
             F130012 , -- 12 收款人开户行名称
             F130013 , -- 13 出票人账号
             F130014 , -- 14 出票人开户行名称
             F130015 , -- 15 票据类型
             F130016 , -- 16 票据号码
             F130017 , -- 17 电票标识
             F130018 , -- 18 重点产业标识
             F130019 , -- 19 协议币种
             F130020 , -- 20 票面金额
             F130021 , -- 21 保证金账号
             F130022 , -- 22 保证金币种
             F130023 , -- 23 保证金金额
             F130024 , -- 24 保证金比例
             F130025 , -- 25 在本行贴现标识
             F130026 , -- 26 贴现客户名称
             F130027 , -- 27 贴现人账号
             F130028 , -- 28 贴现人开户行名称
             F130029 , -- 29 贴现金额
             F130030 , -- 30 贴现日期
             F130031 , -- 31 贴现计息天数
             F130032 , -- 32 贴现利率
             F130033 , -- 33 贴现利息
             F130034 , -- 34 其他费用币种
             F130035 , -- 35 其他费用金额
             F130036 , -- 36 票据签发日期
             F130037 , -- 37 票据到期日期
             F130038 , -- 38 对应的承兑业务协议号
             F130039 , -- 39 代签承兑汇票标识
             F130040 , -- 40 代签承兑汇票的申请行的行名
             F130041 , -- 41 代签承兑汇票的开票行的行名
             F130042 , -- 42 经办员工ID
             F130043 , -- 43 审查员工ID
             F130044 , -- 44 审批员工ID
             F130045 , -- 45 或有负债标识
             F130046 , -- 46 贸易背景
             F130047 , -- 47 票据状态
             F130048 , -- 48 备注
             F130049 , -- 49 采集日期
             DIS_DATA_DATE , -- 装入数据日期
             DIS_BANK_ID   , -- 机构号
             DIS_DEPT      ,
             DEPARTMENT_ID , -- 业务条线
             F130050,    -- 绿色融资类型
             F130051,   -- 授信ID
             F130052    -- 借据ID
       )
   SELECT    
          -- A.ACCT_NO || A.ACCT_NUM        , -- 01 协议ID  -- 唯一
          -- SUBSTR(A.ACCT_NUM || NVL(A.DRAFT_RNG,''),1,60) , -- 01 协议ID 
           A.ACCT_NUM                     , -- 01 协议ID 
           A.ACCT_NUM                     , -- 02 业务号码
           ORG.ORG_ID                     , -- 03 机构ID
           A.CUST_ID                      , -- 04 客户ID
           B.AFF_NAME                     , -- 05 出票人名称
           B.RECE_NAME                    , -- 06 收款人名称
           B.PAY_BANK_NAME                , -- 07 承兑人名称
           '01'                           , -- 08 业务类型  01-承兑
		   A.GL_ITEM_CODE                 , -- 09 科目ID
		   D.GL_CD_NAME                   , -- 10 科目名称
		   B.RECE_ACCT_NUM                , -- 11 收款人账号
           B.RECE_BANK_NAME               , -- 12 收款人开户行名称
           B.AFF_ACCT_NUM                 , -- 13 出票人账号
           B.AFF_ACCT_BANK                , -- 14 出票人开户行名称
           CASE WHEN B.BILL_TYPE='1' THEN '01' -- 银行承兑汇票
                WHEN B.BILL_TYPE='2' THEN '02' -- 商业承兑汇票
            END                           , -- 15 票据类型
		   B.BILL_NUM                     , -- 16 票据号码
		   CASE WHEN B.IS_P_BILL = 'Y' THEN '0' -- 纸票
           ELSE'1' -- 电票
           END                            , -- 17 电票标识
		   -- NULL                           , -- 18 重点产业标识 -- 没有投向，默认空值
		   NVL(A.INDUST_RSTRUCT_FLG,'0') || DECODE(A.INDUST_TRAN_FLG,'1','1','2','0','0') || REPLACE(NVL(A.INDUST_STG_TYPE,'0'),'#','0'), -- 18 重点产业标识
		   B.CURR_CD                      , -- 19 协议币种 
		   A.BALANCE                      , -- 20 票面金额  --  JLBA202409120001 20241212 根据1104取值 放款金额 原为B.AMOUNT  
		   A.SECURITY_ACCT_NUM            , -- 21 保证金账号
           A.SECURITY_CURR                , -- 22 保证金币种
           -- NVL(A.SECURITY_AMT,0)          , -- 23 保证金金额
           NVL(B.AMOUNT * A.SECURITY_RATE * U1.CCY_RATE,0) , -- 23 保证金金额
           NVL(A.SECURITY_RATE,0)*100     , -- 24 保证金比例
           DECODE(B.SELF_DISCOUNT_FLG,'Y','1','N','0') , -- 25 在本行贴现标识     EAST逻辑修改0612
           -- '0'                            , -- 25 在本行贴现标识  --贴现在直贴模块报送，这里默认0-否
           NULL                           , -- 26 贴现客户名称
           NULL                           , -- 27 贴现人账号
           NULL                           , -- 28 贴现人开户行名称
           NULL                           , -- 29 贴现金额  -- 承兑不涉及，置空
		   '9999-12-31'                   , -- 30 贴现日期 -- 承兑不涉及，取默认值99991231
		   NULL                           , -- 31 贴现计息天数 -- 承兑不涉及，置空
           NULL                           , -- 32 贴现利率 -- 承兑不涉及，置空
		   NULL                           , -- 33 贴现利息 -- 承兑不涉及，置空
		   A.EXTRA_COST_CURR_CD           , -- 34 其他费用币种
           A.EXTRA_COST_AMOUNT            , -- 35 其他费用金额
           TO_CHAR(TO_DATE(B.OPEN_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 36 票据签发日期
           TO_CHAR(TO_DATE(B.MATU_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 37 票据到期日期
		   A.ACCT_NO                      , -- 38 对应的承兑业务协议号
           CASE WHEN A.ACCT_NO IS NOT NULL THEN '0' 
                ELSE NULL 
                END                            , -- 39 代签承兑汇票标识 -- 默认空值  --按校验规则38非空时39非空，BA定默认0
           NULL                           , -- 40 代签承兑汇票的申请行的行名 -- 默认空值
           NULL                           , -- 41 代签承兑汇票的开票行的行名 -- 默认空值
		   A.JBYG_ID                      , -- 42 经办员工ID -- 新增字段
		   A.SZYG_ID                      , -- 43 审查员工ID -- 新增字段
           A.SPYG_ID                      , -- 44 审批员工ID -- 新增字段
           '0'                            , -- 45 或有负债标识 -- 默认0-否
		   A.TRADE_CONT_BACK              , -- 46 贸易背景
           CASE WHEN A.BALANCE = 0 THEN '03' -- 03-解付[JLBA202507090010]余额为0，票据已解付
                WHEN B.DRAFT_STATUS IN ('01','02','03','04','05') THEN B.DRAFT_STATUS
                ELSE '00' -- 其他
                END                           , -- 47 票据状态  -- 正常 垫款  核销
           CASE WHEN B.DRAFT_STATUS = '00' THEN  'F130047:' ||B.DRAFT_STATUS_DESC
                WHEN B.DRAFT_STATUS IN ('01','02','03','04','05') THEN NULL
                ELSE 'F130047:' ||M.L_CODE_NAME||'_2' END, -- 48 备注      字段逻辑修改0614，原逻辑为NULL
		   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 49 采集日期
		   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
		   A.ORG_NUM                                       , -- 机构号
		   '承兑',
		   '0098JR'                                          -- 业务条线  -- 金融市场部
		   ,F.GB_CODE   -- 绿色融资类型
           -- ,COALESCE (G.FACILITY_NO,G2.FACILITY_NO)  -- 授信ID  -- JLBA202409120001 20241128 原为NULL ,G1.FACILITY_NO
           ,A.FACILITY_NO -- [20250708][姜俐锋][JLBA202504160004][吴大为]： 直取合同部分授信
		   ,A.ACCT_NUM     -- 借据ID  20250311
     FROM SMTMODS.L_ACCT_OBS_LOAN A
LEFT JOIN SMTMODS.L_AGRE_BILL_INFO B
       ON A.ACCT_NUM = B.BILL_NUM
      AND B.DATA_DATE = I_DATE
LEFT JOIN SMTMODS.L_FINA_INNER D
	   ON A.GL_ITEM_CODE = D.STAT_SUB_NUM
	  AND A.ORG_NUM = D.ORG_NUM
      AND D.DATA_DATE = I_DATE
LEFT JOIN SMTMODS.L_PUBL_RATE U -- 汇率表
       ON U.CCY_DATE = I_DATE
      AND U.BASIC_CCY = B.CURR_CD -- 基准币种
      AND U.FORWARD_CCY = 'CNY'
LEFT JOIN SMTMODS.L_PUBL_RATE U1 -- 汇率表
       ON U1.CCY_DATE = I_DATE
      AND U1.BASIC_CCY = A.CURR_CD -- 基准币种
      AND U1.FORWARD_CCY ='CNY'
LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
       ON A.ORG_NUM = ORG.ORG_NUM
      AND ORG.DATA_DATE = I_DATE
LEFT JOIN M_DICT_CODETABLE M -- 码表    备注字段使用0614
       ON M.L_CODE = B.DRAFT_STATUS
      AND M.L_CODE_TABLE_CODE = 'A0237'    
LEFT JOIN SMTMODS.L_AGRE_BILL_INFO B1 -- 商业汇票票面信息表
       ON B.BILL_NUM = B1.BILL_NUM
      AND B1.DATA_DATE = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') -1 ,'YYYYMMDD')         
LEFT JOIN M_DICT_CODETABLE F                 -- 2.0 ZDSJ H
       ON F.L_CODE = A.GREE_LOAN
      AND F.L_CODE_TABLE_CODE = 'C0098'  
/*LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G  -- JLBA202409120001 20241128 新增关联取授信额度
       ON A.CUST_ID = G.CUST_ID
      AND G.FACILITY_TYP = '2'  
      AND G.DATA_DATE  = I_DATE
LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G1  -- 20250116
       ON B.AFF_CODE = G1.CUST_ID
      AND G1.FACILITY_TYP ='4'     
      AND G1.DATA_DATE  = I_DATE       
LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G2 
       ON B.PAY_CUSID = G2.CUST_ID
      AND G2.FACILITY_TYP = '3'
      AND G2.DATA_DATE  = I_DATE */
    WHERE A.DATA_DATE = I_DATE
      AND A.ACCT_TYP = '111'  -- 20250311
      AND ACCT_STS = '1'
      -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
      -- AND A.BALANCE > 0 -- 20241231
      AND (A.MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101' OR A.BALANCE <> 0) -- JLBA202411070004 20241212
      AND (B.DRAFT_STATUS NOT IN ('05','03') OR (B1.DRAFT_STATUS NOT IN ('05','03') AND B.DRAFT_STATUS IN ('05','03'))) 
      
   -- AND PAY_BANK_NAME LIKE '吉林银行%'
   AND NOT EXISTS
 (SELECT 1 FROM YBT_DATACORE.T_6_13 T
     WHERE T.F130001 = A.ACCT_NUM
     AND T.F130049 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')); 

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

