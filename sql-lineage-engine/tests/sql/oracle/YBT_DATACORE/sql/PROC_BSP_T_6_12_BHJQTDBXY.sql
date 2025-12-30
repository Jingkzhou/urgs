DROP Procedure IF EXISTS `PROC_BSP_T_6_12_BHJQTDBXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_12_BHJQTDBXY"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回code
                                        OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN

  /******
      程序名称  ：保函及其他担保协议
      程序功能  ：加工保函及其他担保协议
      目标表：T_6_12
      源表  ：
      创建人  ：87v
      创建日期  ：20240112
      版本号：V0.0.1 
  ******/
 /*需求编号：JLBA202504060003 上线日期： 20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_12_BHJQTDBXY';
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

	DELETE FROM T_6_12 WHERE F120028 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
   	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);													
		
	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
   INSERT INTO T_6_12  (
       F120001 , -- 01 协议ID
       F120002 , -- 02 业务号码
       F120003 , -- 03 机构ID
       F120004 , -- 04 客户ID
       F120005 , -- 05 保函类型
       F120006 , -- 06 科目ID
       F120007 , -- 07 科目名称
       F120009 , -- 09 保函金额
       F120010 , -- 10 协议币种
       F120011 , -- 11 合同贸易背景
       F120032 , -- 32 业务类型
       F120012 , -- 12 重点产业标识
       F120013 , -- 13 生效日期
       F120014 , -- 14 到期日期
       F120015 , -- 15 保证金账号
       F120016 , -- 16 保证金币种
       F120017 , -- 17 保证金金额
       F120018 , -- 18 保证金比例
       F120019 , -- 19 手续费金额
       F120020 , -- 20 手续费币种
       F120021 , -- 21 受益人名称
       F120022 , -- 22 受益人国家地区
       F120030 , -- 30 受益人开户行账号
       F120031 , -- 31 受益人开户行名称
       F120023 , -- 23 待支付金额
       F120024 , -- 24 经办员工ID
       F120025 , -- 25 审查员工ID
       F120026 , -- 26 审批员工ID
       F120029 , -- 29 担保协议状态
       F120027 , -- 27 备注
       F120028 , -- 28 采集日期
       DIS_DATA_DATE , -- 装入数据日期
       DIS_BANK_ID   , -- 机构号
       DIS_DEPT      ,
       DEPARTMENT_ID ,-- 业务条线
       F120033
       )
 SELECT  
      T3.CONTRACT_NUM                   , -- 01 协议ID
      T1.ACCT_NUM                       , -- 02 业务号码
      ORG.ORG_ID                        , -- 03 机构ID
      T1.CUST_ID                        , -- 04 客户ID
      case
        when T1.BHLX='02' then '01' -- 履约保函
        when T1.BHLX='04' then '02' -- 预付款保函
        when T1.BHLX='01' then '03' -- 投标保函
        when T1.BHLX='07' then '04' -- 维修保函
       -- when T1.BHLX='  ' then '05' -- 预留金保函
        when T1.BHLX='13' then '06' -- 海关风险保证金保函
       -- when T1.BHLX='  ' then '07' -- 进口预付款保函
       -- when T1.BHLX='  ' then '08' -- 经营租赁保函
        when T1.BHLX='19' then '08' -- 借款保函
        when T1.BHLX='11' then '09' -- 租赁保函
        when T1.BHLX='22' then '10' -- 透支保函
        when T1.BHLX='23' then '11' -- 延期付款保函
        when T1.BHLX in('18','20') then '12' -- 其他  -- 业务老师那璐：“融资保函和其他非融资性保函”选项对应到一表通“其他”中
        else '12' -- 其他  --目前发现一笔08-质量保函映射到其他
      end                               , -- 05 保函类型

      /*  
  1）“09-借款保函”→“08-借款保函”；
  2）“10-租赁保函” → “09-租赁保函”；
  3）“11-透支保函” → “10-透支保函”；
  4）“12-延期付款保函” → “11-延期付款保函”；
  5）“13-其他” → “12-其他”；
      */
      
      T1.GL_ITEM_CODE                   , -- 06 科目ID
      T2.GL_CD_NAME                     , -- 07 科目名称
      T1.TRAN_AMT                       , -- 09 保函金额
      T1.CURR_CD                        , -- 10 协议币种
      T1.TRADE_CONT_BACK                , -- 11 合同贸易背景
      CASE WHEN T1.ACCT_TYP='121' THEN '01' -- 融资性保函
           WHEN T1.ACCT_TYP='211' THEN '02' -- 非融资性保函
           END                               , -- 32 业务类型
      NVL(T1.INDUST_RSTRUCT_FLG,'0') || DECODE(T1.INDUST_TRAN_FLG,'1','1','2','0','0') || REPLACE(NVL(T1.INDUST_STG_TYPE,'0'),'#','0')       , -- 12 重点产业标识  --保函不适用，默认为空
      TO_CHAR(TO_DATE(T3.CONTRACT_SIGN_DT,'YYYYMMDD'),'YYYY-MM-DD') , -- 13 生效日期 合同签订日期立即生效
      TO_CHAR(TO_DATE(T1.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD') , -- 14 到期日期
      T1.SECURITY_ACCT_NUM              , -- 15 保证金账号
      T1.SECURITY_CURR                  , -- 16 保证金币种
      T1.SECURITY_AMT                   , -- 17 保证金金额
      T1.SECURITY_RATE                  , -- 18 保证金比例
      nvl(T1.COST_AMOUNT,0)             , -- 19 手续费金额
      T1.COST_CURR_CD                   , -- 20 手续费币种
      SUBSTR(T1.BENE_CUST_NAME,1,200)   , -- 21 受益人名称
      T1.BENE_CUST_NATION               , -- 22 受益人国家地区
      T1.BENE_CUST_ACC                  , -- 30 受益人开户行账号
      T1.BENE_CUST_OPEN_BANK            , -- 31 受益人开户行名称
      T1.UNPAID_AMT                     , -- 23 待支付金额
      nvl(T3.JBYG_ID,'自动')            , -- 24 经办员工ID
      T3.SCYG_ID                        , -- 25 审查员工ID
      nvl(T3.SPYG_ID,'自动')            , -- 26 审批员工ID
      T1.BUSI_STATUS                    , -- 29 担保协议状态
      NULL                              , -- 27 备注
      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 28 采集日期
      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
	  T1.ORG_NUM                                      , -- 机构号
	  NULL,
	  CASE WHEN T1.CURR_CD='CNY' THEN '0098JR'
	  ELSE '0098GJ' END , -- 条线    -- 保函（国际业务部），卖断式转贴现（金融市场部）
      D.FACILITY_NO    -- [20250513] [狄家卉] [JLBA202504060003][吴大为]   授信使用客户号关联取授信表授信编号
      FROM SMTMODS.L_ACCT_OBS_LOAN T1  -- 贷款表外信息表
      INNER JOIN SMTMODS.L_FINA_INNER T2
        ON T1.GL_ITEM_CODE = T2.STAT_SUB_NUM
        AND T1.ORG_NUM = T2.ORG_NUM
       AND T2.DATA_DATE = I_DATE
      INNER JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T3 -- 贷款合同信息表  --取合同审批人
        ON T1.ACCT_NO = T3.CONTRACT_NUM
       AND T3.DATA_DATE = I_DATE 
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON T1.ORG_NUM = ORG.ORG_NUM
       AND ORG.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_AGRE_CREDITLINE D  -- [20250513] [狄家卉] [JLBA202504060003][吴大为]   授信使用客户号关联取授信表授信编号
        ON T1.CUST_ID = D.CUST_ID
       AND D.DATA_DATE = I_DATE 
     WHERE T1.DATA_DATE = I_DATE
       -- AND T1.ACCT_TYP NOT IN ('111','112') -- 账户类型  111-银行承兑汇票  112-商业承兑汇票
       -- and T1.GL_ITEM_CODE in ('70400101','70400102') -- 70400101-应收开出国内融资保函  70400102-应收开出国内非融资保函
        AND T1.ACCT_TYP IN ('121','211') -- 账户类型  121-融资性保函;211-非融资性保函
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
   select OI_RETCODE,'|',OI_REMESSAGE;
END $$


