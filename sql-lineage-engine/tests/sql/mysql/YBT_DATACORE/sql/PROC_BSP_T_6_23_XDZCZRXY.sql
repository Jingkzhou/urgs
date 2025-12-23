DROP Procedure IF EXISTS `PROC_BSP_T_6_23_XDZCZRXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_23_XDZCZRXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：信贷资产转让协议
      程序功能  ：加工信贷资产转让协议
      目标表：T_6_23
      源表  ：
      创建人  ：JLF
      创建日期  ：20240108
      版本号：V0.0.1 
  ******/
	-- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_23_XDZCZRXY';
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
	
	DELETE FROM T_6_23 WHERE F230032 = TO_CHAR(P_DATE,'YYYY-MM-DD');
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT  INTO T_6_23  
             (
             F230001  , -- 01'协议ID'
             F230002  , -- 02'机构ID'
             F230003  , -- 03'交易对手ID'
             F230004  , -- 04'交易对手名称'
             F230005  , -- 05'交易对手账号'
             F230006  , -- 06'交易对手账号行号'
             F230007  , -- 07'交易对手已支付金额'
             F230008  , -- 08'转让价款入账账号'
             F230009  , -- 09'转让价款入账账户名称'
             F230010  , -- 10'签约日期'
             F230011  , -- 11'生效日期'
             F230012  , -- 12'到期日期'
             F230013  , -- 13'协议币种'
             F230014  , -- 14'协议金额'
             F230015  , -- 15'交易资产类型'
             F230016  , -- 16'转让涉及业务本金总额'
             F230017  , -- 17'转让涉及业务利息总额'
             F230018  , -- 18'转让涉及业务笔数'
             F230019  , -- 19'保证金金额'
             F230020  , -- 20'保证金币种'
             F230021  , -- 21'保证金比例'
             F230022  , -- 22'转让交易平台'
             F230023  , -- 23'在银登中心登记标识'
             F230024  , -- 24'资产转让方向'
             F230025  , -- 25'资产转让方式'
             F230026  , -- 26'经办员工ID'
             F230027  , -- 27'审查员工ID'
             F230028  , -- 28'审批员工ID'
             F230029  , -- 29'协议状态'
             F230030  , -- 30'或有负债标识'
             F230031  , -- 31'备注'
             F230032  , -- 32'采集日期'
             DIS_DATA_DATE,
             DIS_BANK_ID,
             DEPARTMENT_ID ,
             F230033
            
            )
      SELECT    
            T.TRANS_CON_NUM               AS F230001  , -- 01'协议ID'
            SUBSTR(TRIM(T1.FIN_LIN_NUM ),1,11)||T.ORG_NUM   AS F230002, -- 02'机构ID'
            T.OPPO_PTY_CD                 AS F230003  , -- 03'交易对手ID'
            T.OPPO_PTY_NAME               AS F230004  , -- 04'交易对手名称'
            T.OPPO_PTY_ACCT_NUM           AS F230005  , -- 05'交易对手账号'
            T.OPPO_PTY_BANK_CD            AS F230006  , -- 06'交易对手账号行号'
            T.PAID_AMT                    AS F230007  , -- 07'交易对手已支付金额'
            T.ENTER_ACCT_BANK_NUM         AS F230008  , -- 08'转让价款入账账号'
            T.ENTER_ACCT_BANK_NAME        AS F230009  , -- 09'转让价款入账账户名称'
             TO_CHAR(TO_DATE(T.TRANS_CON_BGN_DATE,'YYYYMMDD'),'YYYY-MM-DD')  AS F230010  , -- 10'签约日期'
              NULL                        AS F230011  , -- 11'生效日期'
            TO_CHAR(TO_DATE(T.TRANS_CON_DUE_DATE,'YYYYMMDD'),'YYYY-MM-DD')   AS F230012  , -- 12'到期日期'
            T.CURR_CD                     AS F230013  , -- 13'协议币种'
            T.TRANS_CON_AMT               AS F230014  , -- 14'协议金额'
            '01'                          AS F230015  , -- 15'交易资产类型'
            T.TRANS_LOAN_AMT              AS F230016  , -- 16'转让涉及业务本金总额'
            T.TRANS_LOAN_INT              AS F230017  , -- 17'转让涉及业务利息总额'
            COUNT(T.TRANS_CON_NUM )       AS F230018  , -- 18'转让涉及业务笔数'
            -- T.SECURITY_ACCT_NUM           AS F230019  , -- 19'保证金金额'
            -- T.SECURITY_CURR               AS F230020  , -- 20'保证金币种'
            -- T.SECURITY_RATE               AS F230021  , -- 21'保证金比例'
            0                             AS F230019  , -- 19'保证金金额' 20250311
            'CNY'                         AS F230020  , -- 20'保证金币种' 20250311
            0                             AS F230021  , -- 21'保证金比例' 20250311
            -- T.TRADE_PLATFORM_TYP_ADD     
            '04'                          AS F230022  , -- 22'转让交易平台'
            CASE WHEN 
             T.LOAN_SCALE_FACTOR_DESC IN ('01','03','00') THEN '1'
             ELSE '0'
             END                          AS F230023  , -- 23'在银登中心登记标识'  01 03 00
            '02'                          AS F230024  , -- 24'资产转让方向'
            -- T.LOAN_SCALE_FACTOR_DESC       
            '01'                          AS F230025  , -- 25'资产转让方式' 从NGI取，如果没有可以开发。
            T.JBYG_ID                     AS F230026  , -- 26'经办员工ID'
            T.SZYG_ID                     AS F230027  , -- 27'审查员工ID'
            T.SPYG_ID                     AS F230028  , -- 28'审批员工ID'
			CASE WHEN T.CONTRACT_STS = 'B' THEN '01'  -- 正常
			     WHEN T.CONTRACT_STS = 'A' THEN '02'  -- 待生效
			                             -- '03'  -- 中止     码值暂无映射
			     WHEN T.CONTRACT_STS = 'D' THEN '04'  -- 终止
			     WHEN T.CONTRACT_STS = 'C' THEN '05'  -- 撤销
                                         -- '06'  -- 无效     码值暂无映射
                 WHEN T.CONTRACT_STS = 'Z' THEN '00'  -- 其他
                  END AS F230029  , -- 29'协议状态'
            '0'                           AS F230030  , -- 30'或有负债标识'
            NULL                          AS F230031  , -- 31'备注'
            TO_CHAR(P_DATE,'YYYY-MM-DD')  AS F230032  , -- 32'采集日期'
            TO_CHAR(P_DATE,'YYYY-MM-DD')  AS DIS_DATA_DATE  , -- 32'采集日期'
            T.ORG_NUM                     AS DIS_BANK_ID ,
            '009808'                      AS DEPARTMENT_ID ,    -- 资产保全部(009808)
             TO_CHAR(TO_DATE(T.JYDSZZRQ,'YYYYMMDD'),'YYYY-MM-DD') AS F230033
       FROM SMTMODS.L_ACCT_TRANSFER T  -- 信贷资产转让表(信贷资产变动因素表)
       LEFT JOIN VIEW_L_PUBL_ORG_BRA T1 -- 机构表
         ON T.ORG_NUM = T1.ORG_NUM
        AND T1.DATA_DATE = I_DATE
      WHERE SUBSTR(T.DATA_DATE,1,4) = SUBSTR(I_DATE,1,4) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
       -- AND T.TX_TYPE = '信贷资产转让'
       AND T.TX_TYPE NOT LIKE '行内机构划转%'
        GROUP BY  T.TRANS_CON_NUM                 , -- 01'协议ID'
            SUBSTR(TRIM(T1.FIN_LIN_NUM ),1,11)||T.ORG_NUM       , -- 02'机构ID'
            T.OPPO_PTY_CD                   , -- 03'交易对手ID'
            T.OPPO_PTY_NAME                 , -- 04'交易对手名称'
            T.OPPO_PTY_ACCT_NUM             , -- 05'交易对手账号'
            T.OPPO_PTY_BANK_CD              , -- 06'交易对手账号行号'
            T.PAID_AMT                      , -- 07'交易对手已支付金额'
            T.ENTER_ACCT_BANK_NUM           , -- 08'转让价款入账账号'
            T.ENTER_ACCT_BANK_NAME          , -- 09'转让价款入账账户名称'
            T.TRANS_CON_BGN_DATE            , -- 10'签约日期'
            T.TRANS_CON_BGN_DATE            , -- 11'生效日期'
            T.TRANS_CON_DUE_DATE            , -- 12'到期日期'
            T.CURR_CD                       , -- 13'协议币种'
            T.TRANS_CON_AMT                 , -- 14'协议金额'
            T.TRANS_LOAN_AMT                , -- 16'转让涉及业务本金总额'
            T.TRANS_LOAN_INT                , -- 17'转让涉及业务利息总额'
            -- T.SECURITY_ACCT_NUM             , -- 19'保证金金额'
            -- T.SECURITY_CURR                 , -- 20'保证金币种'
            -- T.SECURITY_RATE                 , -- 21'保证金比例'
            -- T.TRADE_PLATFORM_TYP_ADD        , -- 22'转让交易平台'
            T.ZYDZXDJBS                     , -- 23'在银登中心登记标识'
            T.LOAN_SCALE_FACTOR_DESC        , -- 25'资产转让方式' 从NGI取，如果没有可以开发。
            T.JBYG_ID                       , -- 26'经办员工ID'
            T.SZYG_ID                       , -- 27'审查员工ID'
            T.SPYG_ID                       , -- 28'审批员工ID'
            T.CONTRACT_STS                  , -- 29'协议状态'
            T.ORG_NUM,
            TO_CHAR(TO_DATE(JYDSZZRQ,'YYYYMMDD'),'YYYY-MM-DD')
            ;
 COMMIT;
	
-- CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB) T_6_23_SYQZR;		
    #4.过程结束执行
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '过程结束执行';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    SET OI_RETCODE = P_STATUS; 
    SET OI_REMESSAGE = P_DESCB;
    SELECT OI_RETCODE,'|',OI_REMESSAGE;
END $$


