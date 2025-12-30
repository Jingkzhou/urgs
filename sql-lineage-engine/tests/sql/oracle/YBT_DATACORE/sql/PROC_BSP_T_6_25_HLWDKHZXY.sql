DROP Procedure IF EXISTS `PROC_BSP_T_6_25_HLWDKHZXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_25_HLWDKHZXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：表6.25互联网贷款合作协议
      程序功能  ：加工表6.25互联网贷款合作协议
      目标表：T_6_25
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
  #声明变量
  DECLARE P_DATE   		DATE;			#数据日期
  DECLARE A_DATE   		VARCHAR(10);    #数据日期
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
	SET A_DATE = SUBSTR(I_DATE,1,4) || '-' || SUBSTR(I_DATE,5,2) || '-' || SUBSTR(I_DATE,7,2);		
	SET BEG_MON_DT = SUBSTR(I_DATE,1,6) || '01';	
	SET BEG_QUAR_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY') || TRIM(TO_CHAR(QUARTER(TO_DATE(I_DATE,'YYYYMMDD')) * 3 - 2,'00')) || '01'; 
	SET BEG_YEAR_DT = SUBSTR(I_DATE,1,4) || '0101';	
    SET LAST_MON_DT = TO_CHAR(TO_DATE(BEG_MON_DT,'YYYYMMDD') - 1,'YYYYMMDD');	
    SET LAST_QUAR_DT = TO_CHAR(TO_DATE(BEG_QUAR_DT,'YYYYMMDD') - 1,'YYYYMMDD');	
    SET LAST_YEAR_DT = TO_CHAR(TO_DATE(BEG_YEAR_DT,'YYYYMMDD') - 1,'YYYYMMDD');	
	SET LAST_DT = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') - 1,'YYYYMMDD'); 			
	SET P_PROC_NAME = 'PROC_BSP_T_6_25_HLWDKHZXY';
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
	
	DELETE FROM T_6_25 WHERE F250016 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT INTO T_6_25
 (
     F250001    , -- 01 '机构ID'
     F250002    , -- 02 '协议ID'
     F250003    , -- 03 '合作方名称'
     F250004    , -- 04 '合作方证件类型'
     F250005    , -- 05 '合作方证件号码'
     F250006    , -- 06 '合作方类型'
     F250007    , -- 07 '合作方式'
     F250008    , -- 08 '提供增信的模式'
     F250009    , -- 09 '合作方注册地行政区划'
     F250010    , -- 10 '合作协议起始日期'
     F250011    , -- 11 '合作协议到期日期'
     F250012    , -- 12 '合作协议实际终止日期'
     F250013    , -- 13 '限制标识'
     F250014    , -- 14 '协议状态'
     F250015    , -- 15 '备注'
     F250016    , -- 16 '采集日期'    
     DIS_DATA_DATE,
     DIS_BANK_ID,
     DEPARTMENT_ID,
     F250017

 )
  
 WITH ACCT_INTERNET_LOAN AS
 ( SELECT J.COOP_CUST_ID,J.CREDIT_ORG_TYPE FROM     
 ( SELECT DISTINCT COOP_CUST_ID,CREDIT_ORG_TYPE, 
   ROW_NUMBER() OVER(PARTITION BY COOP_CUST_ID ORDER BY COOP_CUST_ID DESC,COOP_CUST_ID,CREDIT_ORG_TYPE) AS SEQ
 FROM  SMTMODS.L_ACCT_INTERNET_LOAN  A -- 互联网贷款业务信息表
 WHERE DATA_DATE = I_DATE
 ) J WHERE  J.SEQ= 1
 )
 
  SELECT  SUBSTR(TRIM(B.FIN_LIN_NUM ),1,11)||A.ORG_NUM AS NBJGH   , -- 01 '机构ID'
          A.COOP_AGREEN_NO AS HZXYBH , -- 02 '协议ID'
          C.COOP_CUST_NAM AS HZFMC   , -- 03 '合作方名称'
          '2010'                     , -- 04 '合作方证件类型'
          C.COOP_ID_NO AS HZFZJHM    , -- 05 '合作方证件号码'
          /* 
          CASE  WHEN C.SMALL_LOAN_COM_TYP IN ('A01','A02','A03','A04','A05','A06','A99') THEN  '03' -- '小额贷款公司'
                WHEN C.COOP_CUST_TYPE='A' AND SUBSTR(C.COOP_FIN_TYPE,1,1) IN ('C','D') THEN '01' -- '银行业金融机构'
                WHEN C.COOP_CUST_TYPE='A' AND SUBSTR(COOP_FIN_TYPE,1,1)='F' THEN '02' -- '保险公司'
                WHEN C.COOP_CUST_TYPE='B01' THEN '04' -- '融资担保公司'
                WHEN C.COOP_CUST_TYPE='C01' THEN '05' -- '电子商务公司'
                WHEN C.COOP_CUST_TYPE='C02' THEN '06' -- '非银行支付机构'
                WHEN C.COOP_CUST_TYPE='C03' THEN '07' -- '信息科技公司'
                WHEN C.COOP_CUST_TYPE IN ('B99','C99' )THEN '08' -- '其他'
                ELSE '00'  -- 无合作方
          END AS */
          
          CASE WHEN C.COOP_CUST_NAM LIKE '深圳前海微众银行股份有限公司%' THEN  '01' -- '银行业金融机构'
               WHEN C.COOP_CUST_NAM LIKE '马上消费金融股份有限公司%' THEN  '03' -- '消费金融公司'
               WHEN C.COOP_CUST_NAM LIKE '江苏苏宁银行股份有限公司%' THEN  '01' -- '银行业金融机构'
            END  AS  HZFLX   , -- 06 '合作方类型'
          CASE  WHEN LENGTH(A.COOP_TYPE)= 1 THEN
               (CASE WHEN A.COOP_TYPE='A' THEN '01' -- '营销获客'
                     WHEN A.COOP_TYPE='B' THEN '02' -- '联合贷款'
                     WHEN A.COOP_TYPE='C' THEN '03' -- '支付结算'
                     WHEN A.COOP_TYPE='E' THEN '04' -- '风险分担'
                     WHEN A.COOP_TYPE='F' THEN '05' -- '担保增信'
                     WHEN A.COOP_TYPE='G' THEN '06' -- '信息科技'
                     WHEN A.COOP_TYPE='H' THEN '07' -- '逾期清收'
                     WHEN A.COOP_TYPE='I' THEN '10' -- '其他'
                    END )
                WHEN  A.COOP_TYPE  ='共同出资' THEN '02' -- '联合贷款' 20241015
                WHEN  A.COOP_TYPE  ='其他服务' THEN '10' -- '其他' 
                ELSE '00' -- 无合作方
          END AS HZFS                  , -- 07 '合作方式'  
           
         CASE 
              WHEN D.CREDIT_ORG_TYPE = 'A' THEN '01' -- 由保证保险提供增信
              WHEN D.CREDIT_ORG_TYPE = 'B' THEN '02' -- 由信用保险提供增信
              WHEN D.CREDIT_ORG_TYPE = 'C' THEN '03' -- 由融资担保公司提供增信
              WHEN D.CREDIT_ORG_TYPE = 'Z' THEN '04' -- 由其他机构提供增信
              ELSE '00'   -- 无增信方式
              END            , -- 08 '提供增信的模式'
              
          CASE WHEN C.COOP_CODE_COUNTRY='CHN' THEN C.COOP_CODE_REGIST ELSE C.COOP_CODE_COUNTRY END XZQHDM , -- 09 '合作方注册地行政区划'
          NVL(TO_CHAR(TO_DATE(A.CONTRACT_START_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,'9999-12-31')        , -- 10 '合作协议起始日期'  
          NVL(TO_CHAR(TO_DATE(A.CONTRACT_END_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,'9999-12-31')          , -- 11 '合作协议到期日期'
          NVL(TO_CHAR(TO_DATE(A.CONTRACT_FINISH_DATE ,'YYYYMMDD'),'YYYY-MM-DD') ,'9999-12-31')      , -- 12 '合作协议实际终止日期'
          NVL(A.CREDIT_FLG,'0')               , -- 13 '限制标识'
          CASE  WHEN A.CONTRACT_STATE='B' THEN '01' -- '正常'
                WHEN A.CONTRACT_STATE='A' THEN '02' -- '待生效'
                WHEN A.CONTRACT_STATE='C' THEN '05' -- '撤销'
                WHEN A.CONTRACT_STATE='D' THEN '04' -- '终结'
                WHEN A.CONTRACT_STATE='Z' THEN '00' -- '其他'
          END AS XYZT                 , -- 14 '协议状态'
          NULL                        , -- 15 '备注' 
          TO_CHAR(P_DATE,'YYYY-MM-DD')  , -- 16 '采集日期'
          TO_CHAR(P_DATE,'YYYY-MM-DD')  , -- 16 '采集日期'
          A.ORG_NUM,
          '0098LDB', -- 零售信贷部(0098LDB)
          a.COOP_AGREEN_NO
         FROM SMTMODS.L_AGRE_COOPER_LOAN A -- 互联网贷款合作协议信息表
    LEFT JOIN VIEW_L_PUBL_ORG_BRA B -- 机构表
           ON A.ORG_NUM = B.ORG_NUM
          AND B.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_CUST_COOP_AGEN C -- 合作机构信息表
           ON A.COOP_CUST_ID = C.COOP_CUST_ID
          AND C.DATA_DATE = I_DATE
    LEFT JOIN ACCT_INTERNET_LOAN D
           ON  A.COOP_CUST_ID = D.COOP_CUST_ID 
    WHERE A.DATA_DATE = I_DATE
	-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
      AND (A.CONTRACT_FINISH_DATE >= SUBSTR(I_DATE,1,4)||'0101' OR A.CONTRACT_FINISH_DATE IS NULL)
	-- [20251009][邮件需求][吴大为][巴启威]：剔除生效日期为空及大于采集日期的互联网贷款合作协议
      AND A.CONTRACT_START_DATE IS NOT NULL AND A.CONTRACT_START_DATE <= I_DATE;
 
 
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


