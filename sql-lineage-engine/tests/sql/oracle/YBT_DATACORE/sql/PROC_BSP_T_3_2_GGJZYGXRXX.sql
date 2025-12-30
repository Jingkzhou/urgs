DROP Procedure IF EXISTS `PROC_BSP_T_3_2_GGJZYGXRXX` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_3_2_GGJZYGXRXX"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回CODE
                                        OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
)
BEGIN

  /******
      程序名称  ：表3.2高管及重要关系人信息
      程序功能  ：表3.2高管及重要关系人信息
      目标表：T_3_2
      源表  ：一段   不报送个体工商户和同业客户
      创建人  ：JLF
      创建日期  ：20240105
      版本号：V0.0.1 
  ******/
	-- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311	
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
	SET P_PROC_NAME = 'PROC_BSP_T_3_2_GGJZYGXRXX';
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
	
	DELETE FROM T_3_2 WHERE C020014 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ;
	   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
INSERT INTO T_3_2  (

C020001,   -- 01'关系ID'
C020002,   -- 02'客户ID'
C020003,   -- 03'机构ID'
C020004,   -- 04'关系人姓名'
C020005,   -- 05'关系人证件类型'
C020006,   -- 06'关系人证件号码'
C020007,   -- 07'证件签发日期'
C020008,   -- 08'证件到期日期'
C020009,   -- 09'关系类型'
C020010,   -- 10'关系人类别'
C020011,   -- 11'关系人国家地区'
C020012,   -- 12'更新信息日期'
C020013,   -- 13'关系状态'
C020015,   -- 15'关联人类别'
C020014,   -- 14'采集日期'
DIS_DATA_DATE, -- 装入数据日期
DIS_BANK_ID,   -- 机构号
DEPARTMENT_ID, -- 业务条线
C020016        -- 关系人客户ID
)

SELECT 
T.RN||SUBSTR(HEX(T.CUST_ID||NVL(T.ID_NO,SUBSTR(HEX(T.EVP_NAM),1,18))||T.RALATION_TYP),1,62) ,  -- 01 关系ID 20250311 SUBSTR(HEX(T.ID_NO),1,10)
T.CUST_ID,                -- 02 客户ID
ORG.ORG_ID,               -- 03 机构ID
T.EVP_NAM,                -- 04 关系人姓名
CASE
             WHEN T.P_ID_TYPE = '0' THEN
              '1010'
             WHEN T.P_ID_TYPE = '1' THEN
              '1040'
             WHEN T.P_ID_TYPE LIKE '2%' THEN
              '1050'
             WHEN T.P_ID_TYPE = '3' THEN
              '1022'
             WHEN T.P_ID_TYPE = '4' THEN
              '1021'
             WHEN SUBSTR(T.P_ID_TYPE, 1, 1) IN ('5', '6', '8') OR
                  T.P_ID_TYPE = 'X03' THEN
              '1070'
             WHEN T.P_ID_TYPE = '7' THEN
              '1011'
             WHEN T.P_ID_TYPE = '9' THEN
              '1032'
             WHEN T.P_ID_TYPE = 'X02' THEN
              '1060'
             WHEN T.P_ID_TYPE = 'X01' THEN
              '1023'
             WHEN T.P_ID_TYPE IN ('A', 'B', 'C', 'X05', 'X06') THEN
              '1999' 
             WHEN T.P_ID_TYPE = 'X04' THEN
              '1999' 
           END/*M.GB_CODE*/ ,                -- 05 关系人证件类型  -- 0629_LHY
T.ID_NO,                  -- 06 关系人证件号码
NVL(TO_CHAR(TO_DATE(T.PSPT_ISSU_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'),
                          -- 07 证件签发日期
NVL(TO_CHAR(TO_DATE(T.PSPT_EXP_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'),
                          -- 08 证件到期日期
T.RALATION_TYP ,          -- 09 关系类型
CASE 
     WHEN T2.CORP_HOLD_TYPE LIKE 'A%' THEN '0202' -- 国有控股企业
     WHEN T1.CUST_TYPE='11' THEN '0102'  -- 境内非银行金融机构
     WHEN T1.CUST_TYPE='12' THEN '0101'  -- 境内银行业金融机构
     WHEN T1.CUST_TYPE='12' AND T1.INLANDORRSHORE_FLG='Y' THEN '0103' -- 境外银行
     WHEN T1.CUST_TYPE='11' AND T1.INLANDORRSHORE_FLG='Y' THEN '0104' -- 境外非银行金融机构
     WHEN T2.BUSSINES_TYPE='151' THEN '0201' -- 国有独资企业
     WHEN T2.CUST_TYP LIKE '2%' THEN '0301'  -- 机关
     WHEN T2.CUST_TYP='5' THEN '0401'        -- 事业单位
     WHEN T2.CUST_TYP='4' THEN '0501'        -- 社会团体
     WHEN T2.CUST_TYP='99' THEN '1102'       -- 以上未列明的其他主体
     -- WHEN T1.TAX_FLAG = '01' THEN '0601' 	 -- 自然人（中国公民）
     WHEN NVL(T1.TAX_FLAG,'01')='01' AND T1.CUST_TYPE='00' THEN '0601' -- 自然人（中国公民） 20240722 2.0修改
     WHEN T1.TAX_FLAG = '02' THEN '0602' 	 -- 自然人（非中国公民）
     ELSE '1102' -- 以上未列明的其他主体   20240722 2.0升级修改
END     ,                 -- 10 关系人类别
T1.NATION_CD,             -- 11 关系人国家地区
NVL(TO_CHAR(TO_DATE(T.INFO_UPD_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31'),
                          -- 12 更新信息日期
'01',                     -- 13 关系状态  默认01有效
CASE WHEN T2.CORP_HOLD_TYPE LIKE 'A%' THEN '02' -- 国有企业
     WHEN T2.CUST_TYP LIKE '2%' THEN '04' -- 政府机关
     WHEN T2.CUST_TYP = '5' THEN '05' -- 事业单位
     WHEN T2.CUST_TYP = '4' THEN '06' -- 社会团体
	 WHEN T1.INLANDORRSHORE_FLG = 'N' THEN '07' -- 境外机构
	 WHEN (T2.CUST_TYP IN ('0','13','14','6','7','8') OR T2.CUST_TYP LIKE '9%')  THEN '00' -- 其他
	 WHEN T1.CUST_TYPE = '00' THEN '01' -- 自然人
	 WHEN T1.CUST_ID IS NULL THEN '00' -- 其他
ELSE '03' -- 民营企业
END,                                                          -- 15 关联人类别
TO_CHAR(TO_DATE(T.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD'),        -- 14 '采集日期'
TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),             --    '装入数据日期'
NVL(T.ORG_NUM,T3.ORG_NUM),                                    --    '机构号'
'0098JR' ,                                                    --    '业务条线  默认公司金融部'
T1.CUST_ID                                                    -- 关系人客户ID ALTER BY WJB 20240624 一表通2.0升级 填报关系人的客户ID。填写要求同客户ID。关系人如果不是本行客户，则为空。
FROM 
 ( SELECT T.P_ID_TYPE,
          T.DATA_DATE,
          T.CUST_ID,
          T.ORG_NUM,
          T.EVP_NAM,
          T.CUST_ID_TYPE,
          T.ID_NO,
          T.INFO_UPD_DT ,
          T.PSPT_ISSU_DT ,
          T.PSPT_EXP_DT ,
          T.RELATION_STATUS ,
          -- MAX(T.INFO_UPD_DT) AS INFO_UPD_DT,
          -- MIN(T.PSPT_ISSU_DT) AS PSPT_ISSU_DT,
          -- MAX(T.PSPT_EXP_DT) AS PSPT_EXP_DT,
          -- MIN(T.RELATION_STATUS) AS RELATION_STATUS,
          GROUP_CONCAT(
          CASE WHEN T.RALATION_TYP = '0' THEN '0601'
          WHEN T.RALATION_TYP = '1'  THEN '0702'
          WHEN T.RALATION_TYP = '10' THEN '0902'
	      WHEN T.RALATION_TYP = '12' THEN '0801'
	      WHEN T.RALATION_TYP = '0'  THEN '0802'
	      WHEN T.RALATION_TYP = '2'  THEN '0704'
	      WHEN T.RALATION_TYP = '3'  THEN '0705'
	      WHEN T.RALATION_TYP = '4'  THEN '0703'
	      WHEN T.RALATION_TYP = '4'  THEN '0703'
	      WHEN T.RALATION_TYP = '5'  THEN '0701'
	      WHEN T.RALATION_TYP LIKE '6%'    THEN '0602'
	      WHEN T.RALATION_TYP IN ('9','7') THEN '0506'
          END ORDER BY CUST_ID SEPARATOR ';') AS RALATION_TYP ,
          ROW_NUMBER() OVER(PARTITION BY T.CUST_ID ORDER BY T.INFO_UPD_DT DESC) AS RN
    FROM SMTMODS.L_CUST_R_SENIORMANAGER T -- -- 高管及主要关系人信息表
   WHERE T.DATA_DATE = I_DATE
     AND SUBSTR(T.ORG_NUM,1,1) NOT IN ('5','6') -- 20240722 2.0修改
   GROUP BY T.P_ID_TYPE,
            T.DATA_DATE,
            T.CUST_ID,
            T.ORG_NUM,
            T.EVP_NAM,
            T.CUST_ID_TYPE,
            T.ID_NO,
            T.INFO_UPD_DT ,
            T.PSPT_ISSU_DT ,
            T.PSPT_EXP_DT ,
            T.RELATION_STATUS ) T -- 高管及主要关系人信息表临时表 用于计算同一公司项下同一个关系人多条关系类型 合并成一条记录   20250311
 LEFT JOIN 
(SELECT T1.*, 
 ROW_NUMBER() OVER(PARTITION BY T1.ID_NO ORDER BY T1.CUST_ID DESC) AS RN
 FROM SMTMODS.L_CUST_ALL T1 -- 全量客户信息表
 WHERE T1.DATA_DATE = I_DATE)  T1
   ON T.ID_NO = T1.ID_NO 
  AND T1.RN = 1 -- 20250311
  AND T1.ID_NO <> '1'
  AND SUBSTR(T1.ORG_NUM,1,1) NOT IN ('5','6') -- 20240722 2.0修改
  AND T1.CUST_STS <> 'C' -- YBT2.0升级修改 不取已注销的客户
 LEFT JOIN M_DICT_CODETABLE M -- 码值表
   ON T1.ID_TYPE = M.L_CODE
  AND M.L_CODE_TABLE_CODE = 'C0001'
 LEFT JOIN 
 (SELECT T1.*, 
 ROW_NUMBER() OVER(PARTITION BY T1.ID_NO ORDER BY T1.CUST_ID DESC) AS RN
 FROM SMTMODS.L_CUST_C T1 -- 全量客户信息表
 WHERE T1.DATA_DATE = I_DATE) T2 -- 对公客户信息表
   ON T1.ID_NO = T2.ID_NO
  AND T2.ID_NO <> '1'
  AND T2.RN = 1 -- 20250311
  AND SUBSTR(T2.ORG_NUM,1,1) NOT IN ('5','6') -- 20240722 2.0修改
 LEFT JOIN SMTMODS.L_CUST_ALL T3
   ON T3.CUST_ID = T.CUST_ID
  AND T3.DATA_DATE = I_DATE
  AND SUBSTR(T3.ORG_NUM,1,1) NOT IN ('5','6') -- 20240722 2.0修改
  AND T3.CUST_STS <> 'C' -- YBT2.0升级修改 不取已注销的客户
 LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
   ON NVL(T3.ORG_NUM,T.ORG_NUM) = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
WHERE T.DATA_DATE = I_DATE
  AND NVL(T2.CUST_TYP,0) NOT IN ('3') -- BA:不取个体工商户
  AND NVL(T1.CUST_TYPE,0) NOT IN ('12') -- BA: 不取同业客户
  AND 
  (EXISTS (SELECT 1 FROM YBT_DATACORE.T_4_3 A WHERE A.D030015 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AND A.D030003 = T.CUST_ID)
   OR 
   EXISTS (SELECT 1 FROM YBT_DATACORE.T_8_13 B WHERE B.H130023 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AND B.H130002 = T.CUST_ID)) -- 只报送在分户账和授信情况表中的客户
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

