DROP Procedure IF EXISTS `PROC_BSP_T_6_9_XYKXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_9_XYKXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：信用卡协议
      程序功能  ：加工信用卡协议
      目标表：T_6_9
      源表  ：
      创建人  ：87v
      创建日期  ：20240111
      版本号：V0.0.1 
  ******/
  /* 需求编号：JLBA202502200003 上线日期：20250415，修改人：姜俐锋，提出人：李逊昂,吴大为 
                     修改原因：  去掉信用卡核销数据*/
  -- JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：因一表通校验问题发现的代码逻辑调整
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_9_XYKXY';
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

	DELETE FROM T_6_9 WHERE F090036 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
   	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);													
		
	
	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
   INSERT INTO T_6_9  (
               F090001  , -- 01 协议ID
               F090002  , -- 02 机构ID
               F090003  , -- 03 客户ID
               F090004  , -- 04 产品ID
               F090037  , -- 37 信用卡账号
               F090005  , -- 05 发卡合作机构
               F090006  , -- 06 发卡合作机构代码
               F090007  , -- 07 卡号
               F090008  , -- 08 发卡渠道
               F090009  , -- 09 准贷记卡标识
               F090010  , -- 10 个人卡标识
               F090011  , -- 11 员工卡标识
               F090012  , -- 12 主卡号
               F090013  , -- 13 附属卡标识
               F090014  , -- 14 年费标识
               F090015  , -- 15 快捷支付标识
               F090016  , -- 16 网络支付标识
               F090017  , -- 17 主要担保方式
               F090018  , -- 18 总授信额度上限
               F090019  , -- 19 本币信用额度
               F090020  , -- 20 外币信用额度
               F090021  , -- 21 外币币种
               F090022  , -- 22 本币现金支取额度
               F090023  , -- 23 外币现金支取额度
               F090024  , -- 24 受理日期
               F090025  , -- 25 交易账单日期
               F090026  , -- 26 最迟还款天数
               F090027  , -- 27 开卡日期
               F090028  , -- 28 开卡经办员工ID
               F090029  , -- 29 卡状态
               F090030  , -- 30 异常标识
               F090031  , -- 31 限制措施
               F090032  , -- 32 销卡日期
               F090033  , -- 33 销卡经办员工ID
               F090034  , -- 34 卡片级别
               F090035  , -- 35 担保说明
               F090036  , -- 36 采集日期
               DIS_DATA_DATE , -- 装入数据日期
               DIS_BANK_ID   ,   -- 机构号
               DIS_DEPT,
               DEPARTMENT_ID ,   -- 业务条线
               F090038           -- 授信ID
       )
 SELECT    
      T2.CARD_NO                       , -- 01 协议ID  -- 校验规则要求唯一
	  'B0302H22201009803'              , -- 02 机构ID
      T2.CUST_ID                       , -- 03 客户ID -- ALTER BY WJB 20240704  客户号取卡表的
	  T2.CP_ID                         , -- 04 产品ID -- 新增字段
	  T1.ACCT_NUM                      , -- 37 信用卡账号 
	  t2.COOPERATION_NAME              , -- 05 发卡合作机构  -- 20240626 修改
	  T2.COOPERATION_ID                , -- 06 发卡合作机构代码 -- 业务提供
	  T2.CARD_NO                       , -- 07 卡号
	  -- T2.CARD_CHANNEL                  , -- 08 发卡渠道
	  CASE WHEN T2.CARD_CHANNEL = 'A' THEN '01' -- 银行网点       
	       WHEN T2.CARD_CHANNEL = 'B' THEN '02' -- 银行卡中心直销
	       WHEN T2.CARD_CHANNEL = 'C' THEN '03' -- 银行官方网站（含网银渠道）
	       WHEN T2.CARD_CHANNEL = 'D' THEN '04' -- 手机终端（银行APP）
	       WHEN T2.CARD_CHANNEL = 'E' THEN '06' -- 第三方机构引流
	       ELSE '00' -- 其他 
	  END , -- 08 发卡渠道  银数修改
	  CASE 
	   WHEN T2.CARDKIND = '3' THEN '1'
        ELSE '0' -- 1-是 ；0-否
       END              	           , -- 09 准贷记卡标识
	  CASE 
	   WHEN T2.C_CREDIT_CARD_FLG = 'Y' THEN '0'
        ELSE '1' -- 1-是 ；0-否
       END                      		, -- 10 个人卡标识
	  case 
	   when T6.ID_NUM is not null then '1'
	    else '0' -- 1-是 ；0-否
	   end                              , -- 11 员工卡标识
	  T2.MAIN_CARD_NO              		, -- 12 主卡号
	  CASE
	   WHEN T2.MAIN_ADDITIONAL_FLG = 'B' THEN '1'    
        ELSE '0'
       END                                , -- 13 附属卡标识
	  CASE 
	   WHEN T2.YFEE_FLG = '1' THEN '1'
	    ELSE '0'
		END                               , -- 14 年费标识  -- 根据业务提供映射获取
	  CASE 
	    WHEN T2.QUICK_PAY_FLG = 'Y' THEN '1'
		 ELSE '0'
		END                               , -- 15 快捷支付标识
	  CASE 
	    WHEN T2.NET_PAY_FLG = 'Y' THEN '1'
		 ELSE '0'
		END                               , -- 16 网络支付标识
	  '04'                                , -- 17 主要担保方式  -- 默认04-信用
	  T1.QUANTUM_CNY                      , -- 18 总授信额度上限
	  T1.QUANTUM_CNY                      , -- 19 本币信用额度  -- 新增字段
	  NVL(T1.QUANTUM_FCY,0)                      , -- 20 外币信用额度 20240629 按照银数修改
	  T1.WBBZ                             , -- 21 外币币种 20240627  按照银数修改
	  T1.CASH_LIM_L_CURR_B                , -- 22 本币现金支取额度
	  T1.CASH_LIM_L_CURR_W                , -- 23 外币现金支取额度
	  TO_CHAR(TO_DATE(T2.ACCEPT_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 24 受理日期
	  TO_CHAR(TO_DATE(T1.NEXT_BILL_DATE,'YYYYMMDD'),'DD'), -- 25 交易账单日期
	  T1.ZCHKTS                           , -- 26 最迟还款天数    -- 新增字段
	  CASE WHEN T2.USE_DATE > I_DATE THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')
	       ELSE TO_CHAR(TO_DATE(T2.USE_DATE,'YYYYMMDD'),'YYYY-MM-DD')
	        END , -- 27 开卡日期 [20250619][巴启威][JLBA202505280002][吴大为]：信用卡部分数据日切时点问题，李逊昂反馈目前只能一表通做一下日期判断处理，开卡日期大于数据日期取数据日期
	  T2.OPEN_EMP_ID                      , -- 28 开卡经办员工ID
	  CASE 
	    WHEN NVL(T2.CARDSTAT,'1') NOT IN('T','Q') AND T2.USE_DATE = '99991231' THEN  '05' -- 未激活
 	    WHEN NVL(T2.CARDSTAT,'1') NOT IN('T','Q') AND T2.USE_DATE <> '99991231' AND T2.USE_DATE > I_DATE THEN '05' -- 未激活
	    WHEN T2.CARDSTAT IS NULL THEN '01' -- 正常 -- 20240705 WJB 
 	    WHEN T2.CARDSTAT IN ('W','D') THEN '02' -- 冻结
	    WHEN T2.CARDSTAT = 'L' THEN '04' -- 挂失
	    WHEN T2.CARDSTAT = 'A' THEN '05' -- 未激活
	    WHEN T2.CARDSTAT IN('T','Q') THEN '06' -- 注销
	    WHEN T2.CARDSTAT = 'U' THEN '07' -- 睡眠 
 	    ELSE '00' -- 其他
      END                                 , -- 29 卡状态 -- 逻辑来自业务李逊昂
      
      CASE
        WHEN T2.ABNORMAL_MEASURE = 'A' THEN '01' -- 盗刷
        WHEN T2.ABNORMAL_MEASURE = 'B' THEN '02' -- 套现
        WHEN T2.ABNORMAL_MEASURE = 'C' THEN '03' -- 用于投资
        WHEN T2.ABNORMAL_MEASURE = 'D' THEN '04' -- 流向房地产
        WHEN T2.ABNORMAL_MEASURE = 'E' THEN '05' -- 用于生产经营
        WHEN T2.ABNORMAL_MEASURE = 'Z' THEN '06' -- 其他
        ELSE '00' -- 逻辑来自业务李逊昂
        -- 00	无异常状态  -- 待集市加工之后，将ELSE定义为 00
        END                               , -- 30 异常标识
      CASE
        WHEN T2.LIMIT_MEASURE = 'A' THEN '01' -- 警告
        WHEN T2.LIMIT_MEASURE = 'B' THEN '02' -- 降额
        WHEN T2.LIMIT_MEASURE = 'C' THEN '03' -- 止付
        WHEN T2.LIMIT_MEASURE = 'D' THEN '04' -- 提前还款
        WHEN T2.LIMIT_MEASURE = 'Z' THEN '05' -- 其他
        ELSE '00'	 
      END          , -- 31 限制措施 -- 业务李逊昂确认
      CASE WHEN T2.CARDSTAT IN('T','Q','C') AND T2.ACCT_CLDATE > I_DATE THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') 
      ELSE TO_CHAR(TO_DATE(NVL(T2.ACCT_CLDATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD') END             , -- 32 销卡日期  20240627 按照银数修改
	  T2.CLOSE_EMP_ID                     , -- 33 销卡经办员工ID
	  T2.CARD_LEVEL                       , -- 34 卡片级别
	  NULL                                , -- 35 担保说明  -- 默认空值
	  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 36 采集日期
      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 装入数据日期
	  '009803'                                         , -- 机构号
	  null,
	  '009803'    ,                                       -- 信用卡中心
	  T1.ACCT_NUM                                        -- 授信ID  ALTER BY WJB 20240624 一表通2.0升级 修改逻辑，参考授信表授信ID
      FROM SMTMODS.L_ACCT_CARD_CREDIT T1 -- 信用卡账户信息表
     INNER JOIN SMTMODS.L_ACCT_CARD_ACCT_RELATION T7 -- 卡基本信息和卡账户信息对应关系表
        ON T1.ACCT_NUM = T7.ACCT_NUM -- 账户表卡号不全，需要通过关系表关联卡表
       AND T7.DATA_DATE = I_DATE
     INNER JOIN SMTMODS.L_AGRE_CARD_INFO T2 -- 卡基本信息表
        ON T7.CARD_NO = T2.CARD_NO 
       AND T2.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_AGRE_CARD_CREDITLINE T3 -- 信用卡授信额度补充信息表
        ON T1.ACCT_NUM = T3.ACCT_NUM
       AND T3.DATA_DATE = I_DATE 
      LEFT JOIN SMTMODS.L_CARD_PRODUCT T4
        ON T2.CP_ID = T4.CP_ID
       AND T4.DATA_DATE = I_DATE 
	  LEFT JOIN SMTMODS.L_CUST_P T5 -- 个人客户信息表
	    ON T1.CUST_ID = T5.CUST_ID	  
	   AND T5.DATA_DATE = I_DATE
	  LEFT JOIN SMTMODS.L_PUBL_RATE R -- 汇率表
        ON R.DATA_DATE = I_DATE
       AND R.BASIC_CCY = 'CNY'
       AND R.FORWARD_CCY = T1.QUANTUM_CCY
	  LEFT JOIN SMTMODS.L_PUBL_EMP T6 -- 员工表
	    ON T5.ID_NO = T6.ID_NUM
	   AND T5.ID_TYPE='102' 
	   AND T6.ID_TYPE='102'
	   AND T6.DATA_DATE = I_DATE
     WHERE T1.DATA_DATE = I_DATE
	   AND T2.CARDKIND ='2' -- 2-贷记卡  -- 发文没提已销卡的不报，并且此表报送销卡日期字段，所以应包含已销卡账户，此处不用卡其他条件了
	-- add by haorui 20241119 JLBA202410090008信用卡收益权转让 start
	   AND (T1.DEALDATE = I_DATE OR T1.DEALDATE ='00000000') 
	   AND (T1.EDSQRQ <= I_DATE OR T1.EDSQRQ IS NULL ) -- YBT_JYF09-93 20250421 同步8.13[吴大为]: 合同起始日大于采集日期，去掉，不取数了
	   AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_ACCT_WRITE_OFF W WHERE W.DATA_DATE = I_DATE AND W.DATE_SOURCESD ='信用卡核销' AND T1.ACCT_NUM=W.ACCT_NUM) -- [20250415][姜俐锋][JLBA202502200003][李逊昂,吴大为]: 去掉核销部分  

	UNION ALL
	SELECT    
		  T2.CARD_NO                       , -- 01 协议ID  -- 校验规则要求唯一
		  'B0302H22201009803'              , -- 02 机构ID
			  T2.CUST_ID                       , -- 03 客户ID -- ALTER BY WJB 20240704  客户号取卡表的
		  T2.CP_ID                         , -- 04 产品ID -- 新增字段
		  T1.ACCT_NUM                      , -- 37 信用卡账号
		  t2.COOPERATION_NAME              , -- 05 发卡合作机构  -- 20240626 修改
		  T2.COOPERATION_ID                , -- 06 发卡合作机构代码 -- 业务提供
		  T2.CARD_NO                       , -- 07 卡号
		  CASE WHEN T2.CARD_CHANNEL = 'A' THEN '01' -- 银行网点       
			   WHEN T2.CARD_CHANNEL = 'B' THEN '02' -- 银行卡中心直销
			   WHEN T2.CARD_CHANNEL = 'C' THEN '03' -- 银行官方网站（含网银渠道）
			   WHEN T2.CARD_CHANNEL = 'D' THEN '04' -- 手机终端（银行APP）
			   WHEN T2.CARD_CHANNEL = 'E' THEN '06' -- 第三方机构引流
			   ELSE '00' -- 其他 
		  END , -- 08 发卡渠道  银数修改
		  CASE 
		   WHEN T2.CARDKIND = '3' THEN '1'
			ELSE '0' -- 1-是 ；0-否
		   END              	           , -- 09 准贷记卡标识
		  CASE 
		   WHEN T2.C_CREDIT_CARD_FLG = 'Y' THEN '0'
			ELSE '1' -- 1-是 ；0-否
		   END                      		, -- 10 个人卡标识
		  case 
		   when T6.ID_NUM is not null then '1'
			else '0' -- 1-是 ；0-否
		   end                              , -- 11 员工卡标识
		  T2.MAIN_CARD_NO              		, -- 12 主卡号
		  CASE
		   WHEN T2.MAIN_ADDITIONAL_FLG = 'B' THEN '1'    
			ELSE '0'
		   END                                , -- 13 附属卡标识
		  CASE 
		   WHEN T2.YFEE_FLG = '1' THEN '1'
			ELSE '0'
			END                               , -- 14 年费标识  -- 根据业务提供映射获取
		  CASE 
			WHEN T2.QUICK_PAY_FLG = 'Y' THEN '1'
			 ELSE '0'
			END                               , -- 15 快捷支付标识
		  CASE 
			WHEN T2.NET_PAY_FLG = 'Y' THEN '1'
			 ELSE '0'
			END                               , -- 16 网络支付标识
		  '04'                                , -- 17 主要担保方式  -- 默认04-信用
		  T1.QUANTUM_CNY                      , -- 18 总授信额度上限
		  T1.QUANTUM_CNY                      , -- 19 本币信用额度  -- 新增字段
		  NVL(T1.QUANTUM_FCY,0)                      , -- 20 外币信用额度 20240629 按照银数修改
		  T1.WBBZ                             , -- 21 外币币种 20240627  按照银数修改
		  T1.CASH_LIM_L_CURR_B                , -- 22 本币现金支取额度
		  T1.CASH_LIM_L_CURR_W                , -- 23 外币现金支取额度
		  TO_CHAR(TO_DATE(T2.ACCEPT_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 24 受理日期
		  TO_CHAR(TO_DATE(T1.NEXT_BILL_DATE,'YYYYMMDD'),'DD'), -- 25 交易账单日期
		  T1.ZCHKTS                           , -- 26 最迟还款天数    -- 新增字段
		  TO_CHAR(TO_DATE(T2.USE_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 27 开卡日期
		  T2.OPEN_EMP_ID                      , -- 28 开卡经办员工ID
		  case 
			when NVL(T2.CARDSTAT,'1') not IN('T','Q') and T2.USE_DATE = '99991231' then  '05' -- 未激活
			when NVL(T2.CARDSTAT,'1') not IN('T','Q') and T2.USE_DATE <> '99991231' and T2.USE_DATE > I_DATE then '05' -- 未激活
			when T2.CARDSTAT is null then '01' -- 正常 -- 20240705 wjb 
			when T2.CARDSTAT IN ('W','D') then '02' -- 冻结
			when T2.CARDSTAT = 'L' then '04' -- 挂失
			when T2.CARDSTAT = 'A' then '05' -- 未激活
			when T2.CARDSTAT IN('T','Q') then '06' -- 注销
			when T2.CARDSTAT = 'U' then '07' -- 睡眠 				
			else '00' -- 其他
		  end                                 , -- 29 卡状态 -- 逻辑来自业务李逊昂
		  
		  case
			when T2.ABNORMAL_MEASURE = 'A' then '01' -- 盗刷
			when T2.ABNORMAL_MEASURE = 'B' then '02' -- 套现
			when T2.ABNORMAL_MEASURE = 'C' then '03' -- 用于投资
			when T2.ABNORMAL_MEASURE = 'D' then '04' -- 流向房地产
			when T2.ABNORMAL_MEASURE = 'E' then '05' -- 用于生产经营
			when T2.ABNORMAL_MEASURE = 'Z' then '06' -- 其他
			else '00' -- 逻辑来自业务李逊昂
			end                               , -- 30 异常标识
		  case
			when T2.LIMIT_MEASURE = 'A' then '01' -- 警告
			when T2.LIMIT_MEASURE = 'B' then '02' -- 降额
			when T2.LIMIT_MEASURE = 'C' then '03' -- 止付
			when T2.LIMIT_MEASURE = 'D' then '04' -- 提前还款
			when T2.LIMIT_MEASURE = 'Z' then '05' -- 其他
			else '00'	 
		  end          , -- 31 限制措施 -- 业务李逊昂确认
		  CASE WHEN T2.CARDSTAT IN('T','Q','C') AND T2.ACCT_CLDATE > I_DATE THEN TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') 
		  ELSE TO_CHAR(TO_DATE(NVL(T2.ACCT_CLDATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD') END             , -- 32 销卡日期  20240627 按照银数修改
		  T2.CLOSE_EMP_ID                     , -- 33 销卡经办员工ID
		  T2.CARD_LEVEL                       , -- 34 卡片级别
		  NULL                                , -- 35 担保说明  -- 默认空值
		  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 36 采集日期
		  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 装入数据日期
		  '009803'                                         , -- 机构号
		  null,
		  '009803'    ,                                       -- 信用卡中心
		  T1.ACCT_NUM                                        -- 授信ID  ALTER BY WJB 20240624 一表通2.0升级 修改逻辑，参考授信表授信ID
      FROM SMTMODS.L_ACCT_CARD_CREDIT T1 -- 信用卡账户信息表
     INNER JOIN SMTMODS.L_ACCT_CARD_ACCT_RELATION T7 -- 卡基本信息和卡账户信息对应关系表
        ON T1.ACCT_NUM = T7.ACCT_NUM -- 账户表卡号不全，需要通过关系表关联卡表
       AND T7.DATA_DATE = I_DATE
     INNER JOIN SMTMODS.L_AGRE_CARD_INFO T2 -- 卡基本信息表
        ON T7.CARD_NO = T2.CARD_NO 
       AND T2.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_ACCT_DEPOSIT DT1
        ON T1.DATA_DATE = DT1.DATA_DATE
	   AND T1.ACCT_NUM = DT1.ACCT_NUM
	   AND DT1.GL_ITEM_CODE ='20110111'
	  LEFT JOIN SMTMODS.L_ACCT_DEPOSIT DT2
	    ON T1.ACCT_NUM = DT2.ACCT_NUM
	   AND DT2.DATA_DATE = LAST_DT
	   AND DT2.GL_ITEM_CODE ='20110111'
      LEFT JOIN SMTMODS.L_AGRE_CARD_CREDITLINE T3 -- 信用卡授信额度补充信息表
        ON T1.ACCT_NUM = T3.ACCT_NUM
       AND T3.DATA_DATE = I_DATE 
      LEFT JOIN SMTMODS.L_CARD_PRODUCT T4
        ON T2.CP_ID = T4.CP_ID
       AND T4.DATA_DATE = I_DATE 
	  LEFT JOIN SMTMODS.L_CUST_P T5 -- 个人客户信息表
	    ON T1.CUST_ID = T5.CUST_ID	  
	   AND T5.DATA_DATE = I_DATE
	  LEFT JOIN SMTMODS.L_PUBL_RATE R -- 汇率表
        ON R.DATA_DATE = I_DATE
       AND R.BASIC_CCY = 'CNY'
       AND R.FORWARD_CCY = T1.QUANTUM_CCY
	  LEFT JOIN SMTMODS.L_PUBL_EMP T6 -- 员工表
	    ON T5.ID_NO = T6.ID_NUM
	   AND T5.ID_TYPE='102' 
	   AND T6.ID_TYPE='102'
	   AND T6.DATA_DATE = I_DATE
     WHERE T1.DATA_DATE = I_DATE
	   AND T2.CARDKIND ='2' -- 2-贷记卡  -- 发文没提已销卡的不报，并且此表报送销卡日期字段，所以应包含已销卡账户，此处不用卡其他条件了
	   AND T1.DEALDATE <>'00000000'   
	   AND (T1.EDSQRQ <= I_DATE OR T1.EDSQRQ IS NULL ) -- YBT_JYF09-93 20250421 同步8.13[吴大为]: 合同起始日大于采集日期，去掉，不取数了
       AND (DT2.ACCT_NUM is not null or DT2.ACCT_NUM is null and DT1.acct_num is not NULL)  -- 前一天有溢款款 或 前一天无溢缴款当有有溢缴款
	   -- add by haorui 20241119 JLBA202410090008信用卡收益权转让 end
	   AND NOT EXISTS (SELECT 1 FROM SMTMODS.L_ACCT_WRITE_OFF W WHERE W.DATA_DATE = I_DATE AND W.DATE_SOURCESD ='信用卡核销' AND T1.ACCT_NUM=W.ACCT_NUM) -- [20250415][姜俐锋][JLBA202502200003][李逊昂,吴大为]:  去掉核销部分  

     ;
	   
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

