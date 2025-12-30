DROP Procedure IF EXISTS `PROC_BSP_T_3_1_ZYGDJZYGLQY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_3_1_ZYGDJZYGLQY"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回code
                                        OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN

  /******
      程序名称  ：重要股东及主要关联企业
      程序功能  ：加工重要股东及主要关联企业
      目标表：T_3_1
      源表  ： 一段
      创建人  ：JLF
      创建日期  ：20240108
      版本号：V0.0.1 
  ******/
  /* 需求编号：JLBA202504060003 上线日期： 20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统取数逻辑*/
	
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
   select OI_RETCODE,'|',OI_REMESSAGE;
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
	SET P_PROC_NAME = 'PROC_BSP_T_3_1_ZYGDJZYGLQY';
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
	
	DELETE FROM T_3_1 WHERE C010017 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
	
INSERT INTO T_3_1

(
C010001    , -- 01 '关系ID'
C010002    , -- 02 '客户ID'
C010003    , -- 03 '机构ID'
C010004    , -- 04 '公司客户名称'
C010005    , -- 05 '股东/关联企业名称'
C010006    , -- 06 '实际控制人标识'
C010007    , -- 07 '股东/关联企业证件类型'
C010008    , -- 08 '股东/关联企业证件号码'
C010009    , -- 09 '登记注册代码'
C010010    , -- 10 '股东/关联企业类别'
C010011    , -- 11 '股东/关联企业国家地区'
C010012    , -- 12 '企业股东持股比例'
C010013    , -- 13 '更新信息日期'
C010014    , -- 14 '股东结构对应日期'
C010015    , -- 15 '关系类型'
C010016    , -- 16 '关系状态'
C010018    , -- 18 '关联人类别'
C010017    , -- 17 '采集日期'
DIS_DATA_DATE, -- 装入数据日期
DIS_BANK_ID,   -- 机构号
DEPARTMENT_ID, -- 业务条线
C010019        -- 股东/关联企业客户ID
)


SELECT
REPLACE(REPLACE(REGEXP_REPLACE(T.CUST_ID||T.ID_NO||T.RALATION_TYP,'~!！@#$%^&{}><''‘’“”\\/?？=+￥、《》【】|；…'),'[',''),']',''), -- 01 '关系ID'  ALTER BY WJB 20240718 一表通2.0升级 修改逻辑，客户号||关联人证件号||关联人类型
-- [20250513] [狄家卉] [JLBA202504060003][吴大为] 关系人ID拼接过程中，剔除特殊字符，特殊字符包括~!！@#$%^&[]{}><''‘’“”\\/?？=+￥、《》【】|；…	
T.CUST_ID                                                       , -- 02 '客户ID'
-- T.ORG_NUM                                                       , -- 03 '机构ID' --20240620 LDP 原逻辑为:ORG.ORG_ID
ORG.ORG_ID                                                      , -- 03 '机构ID'
T.CUST_NAME                                                     , -- 04 '公司客户名称'
T.CONTRIBUTIVE_CORP_NAM                                         , -- 05 '股东/关联企业名称'
DECODE(T.ACTR_CTRL_FLG,'1','1','0')                             , -- 06 '实际控制人标识' 1是 0否
CASE
            /* WHEN T.RELATED_TYPE = '12' AND T.ID_TYPE_TYPE2 = '2J' THEN
              '银行机构代码'
             WHEN T.RELATED_TYPE = '12' AND T.ID_TYPE_TYPE2 = '2F' THEN
              '金融许可证号'
             WHEN T.RELATED_TYPE = '12' AND T.ID_TYPE_TYPE2 = '2I' THEN
              'SWIFT编码'  */
             WHEN T.RELATED_TYPE = '11' AND T.ID_TYPE_TYPE2 = '236' THEN
              '2010'
             WHEN T.RELATED_TYPE = '11' AND T.ID_TYPE_TYPE2 = '21' THEN
              '2030'
             WHEN T.RELATED_TYPE = '11' AND T.ID_TYPE_TYPE2 = '22' THEN
              '2020'
            /* WHEN T.RELATED_TYPE = '11' AND
                  ((SUBSTR(T.ID_TYPE_TYPE2, 1, 2) = '23' AND
                  T.ID_TYPE_TYPE2 NOT IN ('236')) OR
                  T.ID_TYPE_TYPE2 = '2X1') THEN
              '公司注册证书'
             WHEN T.RELATED_TYPE = '11' AND T.ID_TYPE_TYPE2 = '2H' THEN
              '全球法人识别码' */
              WHEN T.ID_TYPE_TYPE2 ='102' THEN
               '1010' -- qm 20231118
             WHEN T.ID_TYPE_TYPE2 IN ('1X', '1XZ', '2X', '2XZ') THEN
              '1999' 
             ELSE
              '1999' 
           end /*NVL(M1.GB_CODE,M.GB_CODE)  */                        , -- 07 '股东/关联企业证件类型'    -- 0629_LHY
-- NVL(T.ID_TYPE_CODE,T.ID_TYPE_CODE2)                             , -- 08 '股东/关联企业证件号码'
T.ID_NO                                                         , -- 08 '股东/关联企业证件号码' 一表通2.0修改
T2.TYSHXYDM                                                     , -- 09 '登记注册代码'
CASE 
	 WHEN T4.CUST_TYP LIKE '2%' THEN '03'   -- 机关
	 WHEN T4.CUST_TYP = '5' THEN '04' 		-- 事业单位
	 WHEN T4.CUST_TYP = '4' THEN '05' 		-- 社会团体
	 WHEN T4.CUST_TYP = '22' THEN '08' 		-- 地方政府融资平台
	 WHEN T3.CUST_TYPE = '12' THEN '01' 	-- 金融企业
     WHEN T3.CUST_TYPE = '11' THEN '02'     -- 非金融企业
ELSE '11' -- 其他
END                                                              , -- 10 '股东/关联企业类别'	 
NVL(T.NATION_CD,'CHN')                                           , -- 11 '股东/关联企业国家地区'
T.SHR_RATIO                                                      , -- 12 '企业股东持股比例'
NVL(TO_CHAR(TO_DATE(T.INFO_UPD_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'), -- 13 '更新信息日期'
NVL(TO_CHAR(TO_DATE(T.SHR_STRT_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'), -- 14 '股东结构对应日期'
/*CASE WHEN T.ASSOCIATE_TYP = '1' THEN '0102' -- 其他持股5%以上及银行认为重要的股东
	 WHEN T.ASSOCIATE_TYP = '2' THEN '0201' -- 除本企业的股东外，直接或间接控制本企业的关联企业
	 WHEN T.ASSOCIATE_TYP = '3' THEN '0301' -- 本企业直接或间接控制的关联企业
	 WHEN T.ASSOCIATE_TYP = '4' THEN '0401' -- 直接或间接被同一控制方控制的关联企业
	 WHEN T.ASSOCIATE_TYP = '5' THEN '0506' -- 其他
	 WHEN T.ASSOCIATE_TYP_2 = '0101' THEN '0502' -- 对该企业施加重大影响的投资方
	 WHEN T.ASSOCIATE_TYP_2 = '0102' THEN '0505' -- 该企业主要投资者个人、关键管理人员或与其关系密切的家庭成员控制、共同控制或施加重大影响的其他企业
	 WHEN T.ASSOCIATE_TYP_2 = '0103' THEN '0102' -- 其他持股5%以上及银行认为重要的股东
	 WHEN T.ASSOCIATE_TYP_2 = '02'   THEN '0901' -- 供应链上下游
	 WHEN T.ASSOCIATE_TYP_2 = '0301' THEN '0501' -- 与该企业实施共同控制的投资方
	 WHEN T.ASSOCIATE_TYP_2 = '04' THEN '0902'   -- 担保关系
	 WHEN T.ASSOCIATE_TYP_2 = '05' THEN '0601'   -- 实际控制人
	 WHEN T.ASSOCIATE_TYP_2 = '0604' THEN '0802' -- 与该企业或其母公司的关键管理人员关系密切的家庭成员
	 WHEN T.ASSOCIATE_TYP_2 = '0603' THEN '0801' -- 与该企业的主要个人投资者关系密切的家庭成员
ELSE '0506' -- 其他
END 														    , -- 15 '关系类型'*/ 
/*
CASE WHEN T.ASSOCIATE_TYP_2 = '01' AND T.ASSOCIATE_CORP_TYP <> '6' THEN '0502'
     WHEN T.ASSOCIATE_TYP_2 = '01' AND T.ASSOCIATE_CORP_TYP =  '6' THEN '0801'
	 WHEN T.ASSOCIATE_TYP_2 = '02' THEN '0901'
	 WHEN T.ASSOCIATE_TYP_2 = '04' THEN '0902'
	 WHEN T.ASSOCIATE_TYP_2 = '05' THEN '0502'
	 WHEN SUBSTR(T.ASSOCIATE_TYP_2, 1, 2) = '06' THEN '0505'
	 WHEN T.ASSOCIATE_TYP_2 = '07' THEN '0401'
	 WHEN T.ASSOCIATE_TYP_2 = '08' THEN '0201'
	 WHEN T.ASSOCIATE_TYP_2 = '09' THEN '0301'
	 WHEN T.ASSOCIATE_TYP_2 = '10' THEN '0503'
	 WHEN T.ASSOCIATE_TYP_2 = '11' THEN '0504'
	 WHEN T.ASSOCIATE_TYP_2 = '0103' THEN '0102'
	 WHEN T.ASSOCIATE_TYP_2 = '0302' THEN '0506'
	 WHEN T.ASSOCIATE_TYP_2 = '99' THEN '0506'
ELSE '0506' -- 其他
END                                                             , -- 15 '关系类型' -- 20240627 LDP V2.1 与EAST同步关系类型逻辑
*/
T.RALATION_TYP                                                  , -- 15 '关系类型' YBT2.0升级修改
'01'                                                            , -- 16 '关系状态' 默认有效
CASE WHEN  T3.INLANDORRSHORE_FLG = 'N' THEN '07'  -- 境外机构
	 WHEN  T.ASSOCIATE_CORP_TYP = '6' THEN '01'   -- 自然人	
	 WHEN  T.ASSOCIATE_CORP_TYP = '1' AND T4.CORP_HOLD_TYPE LIKE 'A%' THEN '02'  -- 国有企业
	 WHEN  T.ASSOCIATE_CORP_TYP = '1' AND T4.CORP_HOLD_TYPE NOT LIKE 'A%' THEN '03' -- 民营企业
	 WHEN  T.ASSOCIATE_CORP_TYP = '3' THEN '05'   -- 事业单位
	 WHEN  T.ASSOCIATE_CORP_TYP = '4' THEN '06'   -- 社会团体
 	 WHEN  T.ASSOCIATE_CORP_TYP = '5' THEN '00'   -- 其他
ELSE  '00'   -- 其他
END,                                                              -- 18 '关联人类别'
TO_CHAR(TO_DATE(T.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD'),            -- 17 '采集日期'
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),                 -- '装入数据日期'
NVL(T.ORG_NUM,T1.ORG_NUM),                                        -- '机构号'
'0098JR',                                                         -- '业务条线  默认公司金融部'
T.CONTRIBUTIVE_CORP_ID                                            --  股东/关联企业客户ID ALTER BY WJB 20240624 一表通2.0升级 修改逻辑，取关联客户ID

    -- FROM SMTMODS.L_CUST_R_ASSOCIATE_INFO T -- 重要股东及主要关联企业
    FROM 
    (
    SELECT T.ID_TYPE_TYPE,T.DATA_DATE,T.CUST_ID,T.ID_NO,T.ASSOCIATE_TYP_2,T.ORG_NUM,T.CUST_NAME,T.CONTRIBUTIVE_CORP_NAM,T.ACTR_CTRL_FLG,T.RELATED_TYPE,T.ID_TYPE_TYPE2,T.NATION_CD,T.SHR_RATIO,T.INFO_UPD_DT,T.SHR_STRT_DT,T.ASSOCIATE_CORP_TYP,T.CONTRIBUTIVE_CORP_ID,
     GROUP_CONCAT(
     CASE WHEN T.ASSOCIATE_TYP_2 = '01' AND T.ASSOCIATE_CORP_TYP <> '6' THEN '0502'
     WHEN T.ASSOCIATE_TYP_2 = '01' AND T.ASSOCIATE_CORP_TYP =  '6' THEN '0801'
	 WHEN T.ASSOCIATE_TYP_2 = '02' THEN '0901'
	 WHEN T.ASSOCIATE_TYP_2 = '04' THEN '0902'
	 WHEN T.ASSOCIATE_TYP_2 = '05' THEN '0502'
	 WHEN SUBSTR(T.ASSOCIATE_TYP_2, 1, 2) = '06' THEN '0505'
	 WHEN T.ASSOCIATE_TYP_2 = '07' THEN '0401'
	 WHEN T.ASSOCIATE_TYP_2 = '08' THEN '0201'
	 WHEN T.ASSOCIATE_TYP_2 = '09' THEN '0301'
	 WHEN T.ASSOCIATE_TYP_2 = '10' THEN '0503'
	 WHEN T.ASSOCIATE_TYP_2 = '11' THEN '0504'
	 WHEN T.ASSOCIATE_TYP_2 = '0103' THEN '0102'
	 WHEN T.ASSOCIATE_TYP_2 = '0302' THEN '0506'
	 WHEN T.ASSOCIATE_TYP_2 = '99' THEN '0506'
     ELSE '0506' -- 其他
     END ORDER BY CUST_ID SEPARATOR ';') AS RALATION_TYP 
    FROM SMTMODS.L_CUST_R_ASSOCIATE_INFO T -- 重要股东及主要关联企业
   WHERE T.DATA_DATE = I_DATE 
     AND T.RELATION_STATUS = '1' -- 20240722 2.0升级修改
   GROUP BY T.ID_TYPE_TYPE,T.DATA_DATE,T.CUST_ID,T.ID_NO,T.ASSOCIATE_TYP_2,T.ORG_NUM,T.CUST_NAME,T.CONTRIBUTIVE_CORP_NAM,T.ACTR_CTRL_FLG,T.RELATED_TYPE,T.ID_TYPE_TYPE2,T.NATION_CD,T.SHR_RATIO,T.INFO_UPD_DT,T.SHR_STRT_DT,T.ASSOCIATE_CORP_TYP,T.CONTRIBUTIVE_CORP_ID
    ) T -- ALTER BY WJB 20240718 一表通2.0升级修改：同一企业的同一关系人存在多种关系时，需合并上报；
    LEFT JOIN M_DICT_CODETABLE M -- 码值表
      ON T.ID_TYPE_TYPE2 = M.L_CODE     
     AND M.L_CODE_TABLE_CODE = 'C0001' 
    LEFT JOIN M_DICT_CODETABLE M1 -- 码值表
      ON T.ID_TYPE_TYPE = M1.L_CODE    
     AND M1.L_CODE_TABLE_CODE = 'C0001'
    INNER JOIN SMTMODS.L_CUST_ALL T1 -- 全量客户信息表 -- 不取同业客户
      ON T.CUST_ID = T1.CUST_ID
     AND T1.DATA_DATE = I_DATE
     AND T1.CUST_STS <> 'C' -- YBT2.0升级修改 不取已注销的客户
     AND SUBSTR(T1.ORG_NUM,1,1) NOT IN ('5','6') -- 20240722 2.0修改
    INNER JOIN SMTMODS.L_CUST_C T2 -- 对公客户信息表 -- 不取个体工商户
      ON T.CUST_ID = T2.CUST_ID
     AND T2.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_CUST_ALL T3 -- 全量客户信息表 -- 取关系人信息
      ON T3.CUST_ID = T.CONTRIBUTIVE_CORP_ID
     AND T3.DATA_DATE = I_DATE
     AND T3.CUST_STS <> 'C' -- YBT2.0升级修改 不取已注销的客户
     AND SUBSTR(T3.ORG_NUM,1,1) NOT IN ('5','6') -- 20240722 2.0修改
    LEFT JOIN SMTMODS.L_CUST_C T4 -- 对公客户信息表 -- 取关系人信息
      ON T4.CUST_ID = T.CONTRIBUTIVE_CORP_ID
     AND T4.DATA_DATE = I_DATE
    LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
      -- ON T.ORG_NUM = ORG.ORG_NUM -- 20240620 LDP 原逻辑为:NVL(T.ORG_NUM,T1.ORG_NUM) = ORG.ORG_NUM
      ON NVL(T.ORG_NUM,T1.ORG_NUM) = ORG.ORG_NUM 
     AND ORG.DATA_DATE = I_DATE
   WHERE T.DATA_DATE = I_DATE
     AND T.SHR_RATIO > '5'
     AND T2.CUST_TYP NOT IN ('3') -- 不取个体工商户
     AND T1.CUST_TYPE NOT IN ('12') -- 不取同业客户
     AND
     (
     EXISTS (SELECT 1 FROM YBT_DATACORE.T_4_3 A WHERE A.D030015 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  AND A.D030003 = T.CUST_ID) 
	 OR
	 EXISTS (SELECT 1 FROM YBT_DATACORE.T_8_13 B WHERE B.H130023 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AND B.H130002 = T.CUST_ID)
	  ) -- 只报送在分户账和授信情况表中的客户
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

