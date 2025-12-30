DROP Procedure IF EXISTS `PROC_BSP_T_2_7_SDSHXXB` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_2_7_SDSHXXB"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回code
                                        OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN

  /******
      程序名称  ：收单商户信息
      程序功能  ：加工收单商户信息
      目标表：T_2_7
      源表  ： 一段
      创建人  ：WJB
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
 /* 需求编号：JLBA202502210009 上线日期：20250415，修改人：姜俐锋，提出人：吴大为 */
 /* 需求编号：JLBA202504060003 上线日期：20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/
 /* 需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
 
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
	SET P_PROC_NAME = 'PROC_BSP_T_2_7_SDSHXXB';
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
	
	DELETE FROM T_2_7 WHERE B070017 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';

INSERT  INTO T_2_7
(
B070001 , -- 01 商户ID
B070002 , -- 02 客户ID
B070003 , -- 03 机构ID
B070004 , -- 04 商户名称
B070005 , -- 05 是否为POS机特约商户
B070006 , -- 06 终端号
B070007 , -- 07 商户类别码
B070008 , -- 08 商户类别码名称
B070009 , -- 09 清算卡号或账号
B070010 , -- 10 清算账号类型
B070011 , -- 11 清算账户名称
B070012 , -- 12 清算账号开户行名称
B070013 , -- 13 商户起效日期
B070014 , -- 14 商户失效日期
B070015 , -- 15 商户地区
B070016 , -- 16 商户状态
B070017 , -- 17 采集日期
DIS_DATA_DATE, -- 装入数据日期
DIS_BANK_ID,   -- 机构号
DEPARTMENT_ID       -- 业务条线
)

	 SELECT T1.MERCHANT_NBR  AS B070001 , -- 01 商户ID
			T1.CUST_ID       AS B070002 , -- 02   客户ID
			ORG.ORG_ID       AS B070003 , -- 03   机构ID
			T1.MERCHANT_NAME AS B070004 , -- 04   商户名称
			CASE WHEN T1.POS_MERCHANT_FLG = 'Y' THEN '1' -- 是
			ELSE '0' -- 否
            END              AS B070005 , -- 05 是否为POS机特约商户
			CASE WHEN T2.EQUIPMENT_NBR IS NOT NULL AND T2.TERMINAL_NO <> '0000000' THEN T2.TERMINAL_NO -- 取设备状态为有效的
            ELSE NULL -- 设备无效 终端号为空  -- 0625_LHY ''改为null
            END              AS B070006 , -- 06 终端号
			REPLACE(T1.MCC,'、','') AS B070007 , -- 07   商户类别码
			REGEXP_REPLACE(T1.MCC_DEC,'[-、 /\<>?？;-]','') AS B070008,  -- 08   商户类别码名称
			T2.COLLECT_ACCT_NO      AS B070009 , -- 09   清算卡号或账号
			CASE WHEN (T2.COLLECT_ACCT_TYPE = 'D' OR T1.CUST_ID IS NULL ) THEN '04' -- 他行对公结算账户    [20250415][姜俐锋][JLBA202502210009][吴大为]:关联不上我行核心账户的业务，清算账号类型为：04-他行对公结算账户
                 WHEN T2.COLLECT_ACCT_TYPE = 'A' THEN '01' -- 本行卡
                 WHEN T2.COLLECT_ACCT_TYPE = 'B' THEN '02' -- 本行对公结算账户
                 WHEN T2.COLLECT_ACCT_TYPE = 'C' THEN '03' -- 他行卡
            ELSE '00' -- 其他
            END                     AS B070010    , -- 10 清算账号类型
			T2.COLLECT_ACCT_NAME    AS B070011    , -- 11   清算账户名称
			T2.COLLECT_ACCT_BANK    AS B070012    , -- 12   清算账号开户行名称
			NVL(TO_CHAR(TO_DATE(T1.EFFECTIVE_DATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') AS B070013 , -- 13   商户起效日期
			NVL(TO_CHAR(TO_DATE(T1.EXPIRATION_DATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31')AS B070014 , -- 14   商户失效日期
			T1.MERCHANT_REGION      AS B070015    , -- 15   商户地区
			CASE WHEN T1.MERCHANT_STS = 'A' THEN '启用'
			     WHEN T1.MERCHANT_STS = 'N' THEN '禁用'
			     WHEN T1.MERCHANT_STS = 'C' THEN '初始化'
			     WHEN T1.MERCHANT_STS = 'U' THEN '注销'
            ELSE '无效'
            END                     AS B070016    , -- 16 商户状态   -- [20250513][狄家卉][JLBA202504060003][吴大为]:修改商户状态按照有效、禁用、无效进行分等类
            TO_CHAR(TO_DATE(T1.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD'),        -- 17 采集日期
			TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),              --  '装入数据日期'
            T1.ORG_NUM,                                                    --  '机构号'
            '009821'                                                       --  '业务条线  默认个人金融部'
     FROM SMTMODS.L_PUBL_MERCHANT T1 -- 收单商户信息表
     LEFT JOIN
     (
    SELECT T.MERCHANT_NBR,T1.EQUIPMENT_NBR,T.TERMINAL_NO,T.COLLECT_ACCT_NO,T.COLLECT_ACCT_TYPE,T.COLLECT_ACCT_NAME,T.COLLECT_ACCT_BANK
     FROM SMTMODS.L_PUBL_TAG_END_MERCHANT T -- 商户终端信息表
     LEFT JOIN SMTMODS.L_PUBL_EQUIPMENT T1 -- 自助设备信息表
       ON T.TERMINAL_NO = T1.EQUIPMENT_NBR -- 终端号
      AND T1.DATA_DATE = I_DATE
      AND T1.EQUIPMENT_STS IN ('A','N')  -- 设备状态取 A 启用和  N 禁用 
    WHERE T.DATA_DATE = I_DATE
      AND T.ACCT_CATEGORY = 'SETTLE'   -- 只取结算户
      ) T2 -- 临时表T2 用于取该商户的终端类型为pos的终端号
       ON T1.MERCHANT_NBR = T2.MERCHANT_NBR -- 商户id
     LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
       ON T1.ORG_NUM = ORG.ORG_NUM
      AND ORG.DATA_DATE = I_DATE
    WHERE T1.DATA_DATE = I_DATE
      -- AND T1.EXPIRATION_DATE IS NULL -- 失效日期为空
      -- AND (T1.EXPIRATION_DATE IS null or T1.EXPIRATION_DATE = I_DATE ) -- 失效日期为空  
      -- AND T1.MERCHANT_STS IN ('A','N')  -- 商户状态取 A 有效和  N 禁用
     and (
     (T1.EXPIRATION_DATE IS null AND T1.MERCHANT_STS IN ('A','N'))
	 -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
         OR (T1.EXPIRATION_DATE >= SUBSTR(I_DATE,1,4)||'0101' and T1.MERCHANT_STS IN ('A','N','U'))
     ) 
       ;
       
    DELETE FROM T_2_7 WHERE B070017 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AND B070005 = '1' AND (B070006 IS NULL OR B070006 ='');

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


