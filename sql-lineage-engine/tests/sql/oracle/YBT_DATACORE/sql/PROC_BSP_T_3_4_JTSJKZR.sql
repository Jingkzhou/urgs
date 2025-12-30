DROP Procedure IF EXISTS `PROC_BSP_T_3_4_JTSJKZR` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_3_4_JTSJKZR"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回code
                                        OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN

  /******
      程序名称  ：集团实际控制人
      程序功能  ：加工集团实际控制人
      目标表：T_3_4
      源表  ：两段 集团和供应链
      创建人  ：JLF
      创建日期  ：20240105
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
	SET P_PROC_NAME = 'PROC_BSP_T_3_4_JTSJKZR';
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
	
	DELETE FROM T_3_4 WHERE C040011 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '集团数据插入';

/*
INSERT  INTO T_3_4  (

C040001  ,-- 01'关系ID'
C040002  ,-- 02'集团ID'
C040003  ,-- 03'机构ID'
C040004  ,-- 04'实际控制人名称'
C040005  ,-- 05'实际控制人类别'
C040006  ,-- 06'实际控制人国家地区'
C040007  ,-- 07'实际控制人证件类型'
C040008  ,-- 08'实际控制人证件号码'
C040009  ,-- 09'登记注册代码'
C040010  ,-- 10'关系状态'
C040011  ,-- 11'采集日期'
DIS_DATA_DATE, -- 装入数据日期
DIS_BANK_ID,   -- 机构号
DEPARTMENT_ID       -- 业务条线

)

SELECT
T.CUST_GROUP_NO ||T.GROUP_MEM_NO    ,-- 01'关系ID'
T.CUST_GROUP_NO       				,-- 02'集团ID'
ORG.ORG_ID            				,-- 03'机构ID'
T.GROUP_MEM_NAM              		,-- 04'实际控制人名称'
CASE WHEN T2.CUST_TYP LIKE '2%' THEN '03' -- 机关
     WHEN T2.CUST_TYP = '5' THEN '04' -- 事业单位
     WHEN T2.CUST_TYP = '4' THEN '05' -- 社会团体
     WHEN T2.CUST_TYP = '22' THEN '08' -- 地方政府融资平台
     WHEN T1.CUST_TYPE = '11' THEN '02' -- 非金融企业
     WHEN T1.CUST_TYPE = '12' THEN '01' -- 金融企业
     WHEN T1.CUST_TYPE = '00' THEN '06' -- 自然人     
ELSE '11' -- 其他
END                                 ,-- 05'实际控制人类别'
T1.NATION_CD            			,-- 06'实际控制人国家地区'
M.GB_CODE              				,-- 07'实际控制人证件类型'
T1.ID_NO                     		,-- 08'实际控制人证件号码'
NVL(T.REGISTER_NBR,T1.ID_NO)       	,-- 09'登记注册代码'
'01'                 				,-- 10'关系状态' 默认有效
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),             --  '采集日期'
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),             --  '装入数据日期'
T3.ORG_NUM,                                                   --  '机构号'
'0098JR'                                                      --   业务条线  默认公司金融部
  FROM SMTMODS.L_CUST_C_GROUP_MEM T -- 集团成员信息表
 INNER JOIN SMTMODS.L_CUST_R_ASSOCIATE_INFO T3 -- 重要股东及主要关联企业
    ON T.GROUP_MEM_NO = T3.CUST_ID
   AND T3.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_CUST_ALL T1 -- 全量客户信息表
    ON T.GROUP_MEM_NO = T1.CUST_ID
   AND T1.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_CUST_C T2 -- 对公客户信息表
    ON T.GROUP_MEM_NO = T2.CUST_ID
   AND T2.DATA_DATE = I_DATE
  LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
    ON NVL(T1.ORG_NUM,T3.ORG_NUM) = ORG.ORG_NUM
   AND ORG.DATA_DATE = I_DATE
  LEFT JOIN M_DICT_CODETABLE M -- 码值表
    ON NVL(T1.ID_TYPE,T2.ID_TYPE) = M.L_CODE
   AND M.L_CODE_TABLE_CODE = 'C0001'
 INNER JOIN
 (
 SELECT T.CUST_GROUP_NO
   FROM SMTMODS.L_CUST_C_GROUP_MEM T
  INNER JOIN SMTMODS.L_CUST_C C
     ON T.GROUP_MEM_NO = C.CUST_ID
    AND C.DATA_DATE = I_DATE
    AND C.CUST_TYP <> '3'
  WHERE T.DATA_DATE = I_DATE
  GROUP BY T.CUST_GROUP_NO
 HAVING COUNT(1) > 1
  )  TT -- 临时表用于满足                                             1、集团下只有一个成员，成员为个人名，则该集团不报送删除
                              --         2、集团下既有对公客户，又有个人名客户作为成员，则按单一法人报送，个人名客户删除
	    					  --         3、集团下只有一个成员，成员为对公客户，则按照集团报送
    ON T.CUST_GROUP_NO = TT.CUST_GROUP_NO
 WHERE T.DATA_DATE = I_DATE
   AND T.GROUP_FLAG = 'Y' -- 取集团实际控制人
   AND T3.ASSOCIATE_TYP_2 = '05' -- 实际控制人
   ;
*/  
  

-- JLBA202412200001 20250116 王金保修改 同步east逻辑
INSERT  INTO T_3_4  (
C040001  ,-- 01'关系ID'
C040002  ,-- 02'集团ID'
C040003  ,-- 03'机构ID'
C040004  ,-- 04'实际控制人名称'
C040005  ,-- 05'实际控制人类别'
C040006  ,-- 06'实际控制人国家地区'
C040007  ,-- 07'实际控制人证件类型'
C040008  ,-- 08'实际控制人证件号码'
C040009  ,-- 09'登记注册代码'
C040010  ,-- 10'关系状态'
C040011  ,-- 11'采集日期'
DIS_DATA_DATE, -- 12装入数据日期
DIS_BANK_ID,   -- 13机构号
DEPARTMENT_ID  -- 14业务条线
)
SELECT
SUBSTR(T.CUST_GROUP_NO ||HEX(T3.ACTR_CTRL),1,32)||SUBSTR(T.CUST_GROUP_NO ||HEX(T3.ACTR_CTRL),-1,32),-- 01'关系ID'
T.CUST_GROUP_NO       				,-- 02'集团ID'
ORG.ORG_ID            				,-- 03'机构ID'
T3.ACTR_CTRL                		,-- 04'实际控制人名称'
CASE WHEN T3.ACTL_CTRLER_TYPE_ITEM = '01' THEN '01' -- 金融企业
     WHEN T3.ACTL_CTRLER_TYPE_ITEM = '02' THEN '02' -- 非金融企业
     WHEN T3.ACTL_CTRLER_TYPE_ITEM = '03' THEN '03' -- 机关
     WHEN T3.ACTL_CTRLER_TYPE_ITEM = '04' THEN '04' -- 事业单位
     WHEN T3.ACTL_CTRLER_TYPE_ITEM = '05' THEN '05' -- 社会团体
     WHEN T3.ACTL_CTRLER_TYPE_ITEM = '06' THEN '06' -- 自然人
     WHEN T3.ACTL_CTRLER_TYPE_ITEM = '07' THEN '07' -- 中央汇金、全国社保及基本养老保险基金、外管局下属的投资公司
     WHEN T3.ACTL_CTRLER_TYPE_ITEM = '08' THEN '08' -- 地方政府融资平台
     WHEN T3.ACTL_CTRLER_TYPE_ITEM = '09' THEN '09' -- 政府投资基金
     WHEN T3.ACTL_CTRLER_TYPE_ITEM = '10' THEN '10' -- 特定目的载体
     WHEN T3.ACTL_CTRLER_TYPE_ITEM = '11' THEN '11' -- 其他
     ELSE '11' -- 其他
END                                 ,-- 05'实际控制人类别'
NVL(T3.SJKZRGJDQ,'CHN')    			,-- 06'实际控制人国家地区'
M.GB_CODE              				,-- 07'实际控制人证件类型'
T3.SJKZRZJHM                   		,-- 08'实际控制人证件号码'
T3.DJZCDM       		            ,-- 09'登记注册代码'
'01'                 				,-- 10'关系状态' 默认有效
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),             --  '采集日期'
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),             --  '装入数据日期'
T.ORG_NUM,                                                    --  '机构号'
'0098JR'                                                      --  '业务条线'  默认公司金融部
  FROM SMTMODS.L_CUST_C_GROUP_INFO T -- 集团客户信息表
 INNER JOIN SMTMODS.L_CUST_C_GROUP_CONTROL T3 -- 集团客户实际控制人信息表
    ON T.CUST_GROUP_NO = T3.CUST_GROUP_NO
   AND T3.DATA_DATE = I_DATE
   and T3.GXZT ='01' -- 01有效 02失效
  LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
    ON NVL(T.ORG_NUM,T3.ORG_NUM) = ORG.ORG_NUM
   AND ORG.DATA_DATE = I_DATE
  LEFT JOIN M_DICT_CODETABLE M -- 码值表
    ON T3.SJKZRZJLX = M.L_CODE
   AND M.L_CODE_TABLE_CODE = 'V0006' -- V0006 新增的实际控制人证件类型码值
 INNER JOIN
 (
 SELECT T.CUST_GROUP_NO
   FROM SMTMODS.L_CUST_C_GROUP_MEM T -- 集团成员信息表
  INNER JOIN SMTMODS.L_CUST_C C
     ON T.GROUP_MEM_NO = C.CUST_ID
    AND C.DATA_DATE = I_DATE
    AND C.CUST_TYP <> '3'
  WHERE T.DATA_DATE = I_DATE
  GROUP BY T.CUST_GROUP_NO
 HAVING COUNT(1) > 1
  )  TT -- 临时表用于满足               --         1、集团下只有一个成员，成员为个人名，则该集团不报送删除
                              --         2、集团下既有对公客户，又有个人名客户作为成员，则按单一法人报送，个人名客户删除
	    					  --         3、集团下只有一个成员，成员为对公客户，则按照集团报送
    ON T.CUST_GROUP_NO = TT.CUST_GROUP_NO
 WHERE T.DATA_DATE = I_DATE;

 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);		

-- 数管部吴大为：去除供应链，只要集团。 
 /*
  #4.供应链数据插入
  SET P_START_DT = NOW();
  SET P_STEP_NO = P_STEP_NO + 1;
  SET P_DESCB = '供应链数据插入';
	
INSERT  INTO T_3_4  (

C040001  ,-- 01'关系ID'
C040002  ,-- 02'集团ID'
C040003  ,-- 03'机构ID'
C040004  ,-- 04'实际控制人名称'
C040005  ,-- 05'实际控制人类别'
C040006  ,-- 06'实际控制人国家地区'
C040007  ,-- 07'实际控制人证件类型'
C040008  ,-- 08'实际控制人证件号码'
C040009  ,-- 09'登记注册代码'
C040010  ,-- 10'关系状态'
C040011  ,-- 11'采集日期'
DIS_DATA_DATE, -- 装入数据日期
DIS_BANK_ID,   -- 机构号
DEPARTMENT_ID       -- 业务条线
)

SELECT 
T.SPLY_CHAIN_FINA_CD ||T1.GROUP_MEM_NO
                                    ,-- 01'关系ID'
T.SPLY_CHAIN_FINA_CD   				,-- 02'集团ID'
ORG.ORG_ID            				,-- 03'机构ID'
C.CUST_NAM          				,-- 04'实际控制人名称'
CASE WHEN T3.CUST_TYPE='12' THEN '01'
     WHEN T3.CUST_TYPE='11' THEN '02'
     WHEN C.CUST_TYP LIKE '2%' THEN '03'
     WHEN C.CUST_TYP ='5'  THEN '04'
     WHEN C.CUST_TYP ='4'  THEN '05'
     WHEN C.CUST_TYP IN ('7','8','93')  THEN '07'
     WHEN C.CUST_TYP IN ('97','99')  THEN '11'
END 				                ,-- 05'实际控制人类别'
C.NATION_CD           				,-- 06'实际控制人国家地区'
C.ID_TYPE              				,-- 07'实际控制人证件类型'
C.ID_NO              				,-- 08'实际控制人证件号码'
T1.REGISTER_NBR     				,-- 09'登记注册代码'
T1.GXZT               				,-- 10'关系状态'
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),             -- 11'采集日期'
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),             --  '装入数据日期'
T.ORG_NUM,                                                    --  '机构号'
'0098JR'                                                      --  '业务条线  默认公司金融部'
  FROM SMTMODS.L_CUST_SUPLY_CHAIN T -- 供应链融资及经济依存客户信息
  LEFT JOIN SMTMODS.L_CUST_C_GROUP_MEM T1 -- 集团成员信息表
    ON T.SPLY_CHAIN_FINA_CD = T1.CUST_GROUP_NO
   AND T1.DATA_DATE = I_DATE
  LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
    ON T.ORG_NUM = ORG.ORG_NUM
   AND ORG.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_CUST_C C -- 对公客户信息表
    ON T.CUST_ID = C.CUST_ID
   AND C.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_CUST_ALL T3 -- 全量客户信息表
    ON T.CUST_ID = T3.CUST_ID
   AND T3.DATA_DATE = I_DATE
 WHERE T.DATA_DATE = I_DATE
   AND T.SPLY_CHAIN_FINA_CORE_FLG = 'Y';
  
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
*/

    #5.过程结束执行
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '过程结束执行';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
   SET OI_RETCODE = P_STATUS; 
   SET OI_REMESSAGE = P_DESCB;
   select OI_RETCODE,'|',OI_REMESSAGE;
END $$

