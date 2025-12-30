DROP Procedure IF EXISTS `PROC_BSP_T_6_26_QTXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_26_QTXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN
/******
      程序名称  ：其他协议
      程序功能  ：加工其他协议
      目标表：T_6_26
      源表  ：
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_26_QTXY';
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
	
	DELETE FROM ybt_datacore.T_6_26 WHERE F260027 = to_char(P_DATE,'yyyy-mm-dd');
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	 
 INSERT  INTO ybt_datacore.T_6_26  (
   F260001 ,  -- 01.协议ID
   F260002 ,  -- 02.业务号码
   F260003 ,  -- 03.机构ID
   F260004 ,  -- 04.交易对手ID
   F260005 ,  -- 05.产品ID
   F260006 ,  -- 06.交易对手名称
   F260007 ,  -- 07.交易对手大类
   F260008 ,  -- 08.交易对手账号
   F260009 ,  -- 09.交易对手账号行号
   F260010 ,  -- 10.签约日期
   F260011 ,  -- 11.生效日期
   F260012 ,  -- 12.到期日期
   F260013 ,  -- 13.其他协议币种
   F260014 ,  -- 14.协议金额
   F260015 ,  -- 15.协议义务
   F260016 ,  -- 16.业务品种
   F260017 ,  -- 17.业务品种描述
   F260020 ,  -- 20.重点产业标识
   F260021 ,  -- 21.经办员工ID
   F260022 ,  -- 22.审查员工ID
   F260023 ,  -- 23.审批员工ID
   F260024 ,  -- 24.协议状态
   F260025 ,  -- 25.或有负债标识
   F260026 ,  -- 26.备注
   F260027 ,   -- 27.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID ,   -- 机构号
   DEPARTMENT_ID       -- 业务条线
    ,F260028  -- 授信ID
)
 SELECT 
    A.FX_TX_REF_NO               ,  -- 01.协议ID
	A.FX_TX_REF_NO               ,  -- 02.业务号码
	ORG.ORG_ID                   ,  -- 03.机构ID
	A.OPPO_PTY_CD                ,  -- 04.交易对手ID
	A.CP_ID                      ,  -- 05.产品ID
	A.OPPO_PTY_NAME              ,  -- 06.交易对手名称
	CASE WHEN T1.CUST_ID IS NOT NULL THEN 
          (CASE WHEN SUBSTR(T1.FINA_CODE_NEW,1,1) IN ('C','D') THEN '01'  -- 银行业金融机构
                WHEN SUBSTR(T1.FINA_CODE_NEW,1,1) = 'F' THEN '02'  -- 保险业机构
				-- 03	地方金融组织
                WHEN SUBSTR(T1.FINA_CODE_NEW,1,1) = 'G' THEN '04'  -- 交易及登记结算类机构
				WHEN SUBSTR(T1.FINA_CODE_NEW,1,1) = 'H' THEN '05'  -- 金融控股公司
				WHEN SUBSTR(T1.FINA_CODE_NEW,1,1) = 'E' THEN '06'  -- 证券业金融机构
				-- 07	第三方支付公司
				WHEN SUBSTR(T1.FINA_CODE_NEW,1,1) = 'I' THEN '08'  -- 特定目的载体
				END)
	     WHEN T2.CUST_ID IS NOT NULL THEN 
	       (CASE WHEN SUBSTR(T2.CUST_TYP,1,1) = '2' THEN '09'       -- 政府部门
		         WHEN T2.CUST_TYP = '3' THEN '11'	    -- 个人客户 个体工商户归个人客户
                 ELSE '10'	-- 公司企业客户			
                 END)
         WHEN T3.CUST_ID IS NOT NULL THEN '11'	-- 个人客户
         WHEN T4.CUST_ID IS NOT NULL AND T4.INLANDORRSHORE_FLG = 'N' THEN '12' -- 境外客户
	     ELSE '00'	 -- 其他
     END                            ,  -- 07.交易对手大类
	A.JYDSZH                     ,  -- 08.交易对手账号
	A.JYDSZHHH                   ,  -- 09.交易对手账号行号
	TO_CHAR(TO_DATE(A.QYRQ,'YYYYMMDD'),'YYYY-MM-DD') as qyrq ,  -- 10.签约日期  
	TO_CHAR(TO_DATE(A.START_DATE,'YYYYMMDD'),'YYYY-MM-DD') as sxrq ,  -- 11.生效日期
    TO_CHAR(TO_DATE(A.MATURITY_DT ,'YYYYMMDD'),'YYYY-MM-DD') as dqrq ,  -- 12.到期日期
	CASE WHEN SUBSTR(A.FX_TX_TYPE,1,1) = 'A' -- 结汇
	     THEN A.BUY_CURR_CD1
		 WHEN SUBSTR(A.FX_TX_TYPE,1,1) = 'B' -- 售汇
		 THEN A.SELL_CURR_CD1
		  END                    ,  -- 13.其他协议币种
	CASE WHEN SUBSTR(A.FX_TX_TYPE,1,1) = 'A' -- 结汇
	     THEN A.BUY_AMT1
		 WHEN SUBSTR(A.FX_TX_TYPE,1,1) = 'B' -- 售汇
		 THEN A.SELL_AMT1
		  END	                 ,  -- 14.协议金额
    '01'                           ,  -- 15.协议义务 结售汇业务默认 01 给付义务
    CASE WHEN A.FX_TX_TYPE IN ('A01','B01') THEN '05' -- 即期
	     WHEN A.FX_TX_TYPE IN ('A02','B02') THEN '01' -- 远期
	      END                    ,  -- 16.业务品种
	NULL                         ,  -- 17.业务品种描述 默认空
	NULL                         ,  -- 20.重点产业标识 默认空
	A.TRADER_ID                  ,  -- 21.经办员工ID
	A.SCYG_ID                    ,  -- 22.审查员工ID
	A.APPROVER_ID                ,  -- 23.审批员工ID
	'01'                         ,  -- 24.协议状态 默认 01 正常
	'0'                           ,  -- 25.或有负债标识 默认 0 否
	NULL					     ,  -- 26.备注
    TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')	, -- 27.采集日期
    TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')	,
    A.BRANCH_CODE,
    '0098GJ'
    ,null  -- 授信ID  2.0 zdsj h
 FROM SMTMODS.L_ACCT_EXCHANGE_INFO A -- 结售汇业务信息表
 LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON A.BRANCH_CODE = ORG.ORG_NUM
       AND ORG.DATA_DATE = I_DATE
 LEFT JOIN SMTMODS.L_CUST_BILL_TY T1
        ON A.CUST_ID = T1.CUST_ID
       AND T1.DATA_DATE = I_DATE
 LEFT JOIN SMTMODS.L_CUST_C T2
        ON A.CUST_ID = T2.CUST_ID
       AND T2.DATA_DATE = I_DATE   
 LEFT JOIN SMTMODS.L_CUST_P T3
        ON A.CUST_ID = T3.CUST_ID
       AND T3.DATA_DATE = I_DATE
 LEFT JOIN SMTMODS.L_CUST_ALL T4
        ON A.CUST_ID = T4.CUST_ID
       AND T4.DATA_DATE = I_DATE       
    WHERE A.DATA_DATE = I_DATE
      AND SUBSTR(A.FX_TX_TYPE,1,3) IN ('A01','A02','B01','B02')
	  AND (A.MATURITY_DT IS NULL OR A.MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101') -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
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


