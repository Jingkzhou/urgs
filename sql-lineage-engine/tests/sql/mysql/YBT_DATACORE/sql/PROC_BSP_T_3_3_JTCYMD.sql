DROP Procedure IF EXISTS `PROC_BSP_T_3_3_JTCYMD` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_3_3_JTCYMD"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回CODE
                                        OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
)
BEGIN

  /******
      程序名称  ：集团成员名单
      程序功能  ：加工集团成员名单
      目标表：T_3_3
      源表  ：两段 集团和供应链
      创建人  ：JLF
      创建日期  ：20240105
      版本号：V0.0.1 
  ******/
	-- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116
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
	SET P_PROC_NAME = 'PROC_BSP_T_3_3_JTCYMD';
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
	
	DELETE FROM T_3_3 WHERE C030010 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';

INSERT  INTO T_3_3
(
C030001 , -- 01 '关系ID'
C030002 , -- 02 '成员ID'
C030003 , -- 03 '成员企业名称'
C030004 , -- 04 '成员统一社会信用代码'
C030005 , -- 05 '成员类型'
C030006 , -- 06 '登记注册代码'
C030007 , -- 07 '集团ID'
C030008 , -- 08 '机构ID'
C030009 , -- 09 '关系状态'
C030010 , -- 10 '采集日期'
DIS_DATA_DATE, -- 装入数据日期
DIS_BANK_ID,   -- 机构号
DEPARTMENT_ID       -- 业务条线
)

SELECT T1.CUST_GROUP_NO||T1.GROUP_MEM_NO,
                                 -- 01 '关系ID'
       T1.GROUP_MEM_NO,          -- 02 '成员ID'
       T1.GROUP_MEM_NAM,         -- 03 '成员企业名称'
       T3.TYSHXYDM, 		     -- 04 '成员统一社会信用代码'
       CASE WHEN T1.MEM_TYP = '1' THEN '01' -- 核心成员
            WHEN T1.MEM_TYP = '2' THEN '02' -- 一般成员
       END,                      -- 05 '成员类型'
       -- NVL(T1.REGISTER_NBR,T3.TYSHXYDM),   -- 06 '登记注册代码'
       CASE  WHEN  A.ID_TYPE = '22' /*营业执照（工商注册号）*/ 
             THEN  A.ID_NO  -- 20250116
             ELSE  NVL(T1.REGISTER_NBR,T3.TYSHXYDM) 
       END,     				 -- 06 '登记注册代码'   -- 20250311
       T2.CUST_GROUP_NO,         -- 07 '集团ID'
       ORG.ORG_ID,               -- 08 '机构ID'
       '01',                     -- 09 '关系状态' 坤哥：默认有效 01 
       TO_CHAR(TO_DATE(T1.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD')       ,-- 10 '采集日期'
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),             --    '装入数据日期'
	   NVL(T1.ORG_NUM,T2.ORG_NUM),                                   --    '机构号'
	   '0098JR'                                                      --     业务条线  默认公司金融部
  FROM SMTMODS.L_CUST_C_GROUP_MEM T1 -- 集团成员信息
  LEFT JOIN SMTMODS.L_CUST_C_GROUP_INFO T2 -- 集团客户信息表
    ON T1.CUST_GROUP_NO = T2.CUST_GROUP_NO
   AND T2.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_CUST_C T3 -- 全量客户信息表
    ON T1.GROUP_MEM_NO = T3.CUST_ID
   AND T3.DATA_DATE = I_DATE
  LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
    ON NVL(T1.ORG_NUM,T3.ORG_NUM) = ORG.ORG_NUM
   AND ORG.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_CUST_ALL A  -- 20250311  YBT_JYC03-10
    ON T1.GROUP_MEM_NO = A.CUST_ID
    AND A.DATA_DATE = I_DATE
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
 )  TT -- 临时表用于满足        -- 1、集团下只有一个成员，成员为个人名，则该集团不报送删除
                          -- 2、集团下既有对公客户，又有个人名客户作为成员，则按单一法人报送，个人名客户删除
						  -- 3、集团下只有一个成员，成员为对公客户，则按照集团报送
    ON T1.CUST_GROUP_NO = TT.CUST_GROUP_NO
 WHERE T1.DATA_DATE = I_DATE
   AND T3.CUST_TYP NOT IN ('3') -- 不取个体工商户
   AND 
   (
   EXISTS (SELECT 1 FROM YBT_DATACORE.T_4_3 A WHERE A.D030015 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') 
   AND A.D030003 = T1.GROUP_MEM_NO) 
   OR 
  -- EXISTS (SELECT 1 FROM YBT_DATACORE.T_8_13 B WHERE B.H130023 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') 
  -- AND B.H130002 = T1.GROUP_MEM_NO
   EXISTS (SELECT 1 FROM SMTMODS.L_AGRE_CREDITLINE B WHERE B.DATA_DATE = I_DATE AND B.CUST_ID = T1.GROUP_MEM_NO)  -- [20250520][巴启威]:与2.2保持一致，使用L层授信表框定范围
   ) -- 只报送在分户账和授信情况表中的客户
	;
	
 CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	
 
-- 数管部吴大为：去除供应链，只要集团。
 /*
    #4.供应链插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '供应链插入数据';

INSERT  INTO T_3_3
(
C030001 , -- 01 '关系ID'
C030002 , -- 02 '成员ID'
C030003 , -- 03 '成员企业名称'
C030004 , -- 04 '成员统一社会信用代码'
C030005 , -- 05 '成员类型'
C030006 , -- 06 '登记注册代码'
C030007 , -- 07 '集团ID'
C030008 , -- 08 '机构ID'
C030009 , -- 09 '关系状态'
C030010 , -- 10 '采集日期'
DIS_DATA_DATE, -- 装入数据日期
DIS_BANK_ID,   -- 机构号
DEPARTMENT_ID       -- 业务条线
)

SELECT T1.SPLY_CHAIN_FINA_CD||T1.CUST_ID,        
                                 -- 01 '关系ID'
       T1.CUST_ID,               -- 02 '成员ID'
       T1.CUST_NAME,             -- 03 '成员企业名称'
       T4.TYSHXYDM, 		     -- 04 '成员统一社会信用代码'
       CASE WHEN T1.SPLY_CHAIN_FINA_CORE_FLG = 'Y' THEN '01' -- 核心成员
            WHEN T1.SPLY_CHAIN_FINA_CORE_FLG = 'N' THEN '02' -- 一般成员
       END       ,               -- 05 '成员类型'
       NVL(T3.REGISTER_NBR,T4.TYSHXYDM), -- 06 '登记注册代码'
       T1.SPLY_CHAIN_FINA_CD,    -- 07 '集团ID'
       ORG.ORG_ID,               -- 08 '机构ID'
       '01',                     -- 09 '关系状态' 坤哥： 默认有效
       TO_CHAR(TO_DATE(T1.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,-- 10 '采集日期'
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),             --  '装入数据日期'
	   T1.ORG_NUM,                                                   --  '机构号'
	   '0098JR'                                                      --   业务条线  默认公司金融部

  FROM SMTMODS.L_CUST_SUPLY_CHAIN T1 -- 供应链融资及经济依存客户信息
  LEFT JOIN SMTMODS.L_CUST_C_GROUP_MEM T3 -- 集团成员信息
    ON T1.CUST_ID = T3.GROUP_MEM_NO
   AND T3.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_CUST_C T4 -- 全量客户信息表
    ON T1.CUST_ID = T4.CUST_ID
   AND T4.DATA_DATE = I_DATE
  LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构表
    ON NVL(T1.ORG_NUM,T4.ORG_NUM) = ORG.ORG_NUM
   AND ORG.DATA_DATE = I_DATE
 WHERE T1.DATA_DATE = I_DATE
  AND
  (
  EXISTS (SELECT 1 FROM YBT_DATACORE.T_4_3 A WHERE A.D030015 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  AND A.D030003 = T1.CUST_ID) 
  OR 
  EXISTS (SELECT 1 FROM YBT_DATACORE.T_8_13 B WHERE B.H130023 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AND B.H130002 = T1.CUST_ID)
  ) -- 只报送在分户账和授信情况表中的客户 
   ;

 
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
	*/
 
    #4.过程结束执行
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '过程结束执行';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
   SET OI_RETCODE = P_STATUS; 
   SET OI_REMESSAGE = P_DESCB;
   SELECT OI_RETCODE,'|',OI_REMESSAGE;
END $$


