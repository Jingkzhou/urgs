DROP Procedure IF EXISTS `PROC_BSP_T_6_3_XMDKXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_3_XMDKXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：项目贷款协议
      程序功能  ：加工项目贷款协议
      目标表：T_6_3
      源表  ：
      创建人  ：JLF
      创建日期  ：20240105
      版本号：V0.0.1 
  ******/
 	-- JLBA202411070004_关于一表通监管数据报送系统修改逻辑的需求 20241212
 	-- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116
 	-- JLBA202501140003_关于一表通监管数据报送系统变更项目贷款协议报表取数逻辑的需求_20250225
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_3_XMDKXY';
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
	
	DELETE FROM T_6_3 WHERE F030021 = TO_CHAR(P_DATE,'YYYY-MM-DD');
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
      INSERT INTO T_6_3  (
             F030001,   -- 01'机构ID'
             F030002,   -- 02'协议ID'
             F030003,   -- 03'项目类型'
             F030004,   -- 04'项目名称'
             F030005,   -- 05'项目总投资'
             F030006,   -- 06'项目资本金'
             F030007,   -- 07'批文文号'
             F030008,   -- 08'立项批文'
             F030009,   -- 09'土地使用证编号'
             F030010,   -- 10'土地使用证日期'
             F030011,   -- 11'用地规划许可证编号'
             F030012,   -- 12'用地规划许可证日期'
             F030013,   -- 13'施工许可证编号'
             F030014,   -- 14'施工许可证日期'
             F030015,   -- 15'工程规划许可证编号'
             F030016,   -- 16'工程规划许可证日期'
             F030017,   -- 17'其他许可证'
             F030018,   -- 18'其他许可证编号'
             F030019,   -- 19'开工日期'
             F030020,   -- 20'备注'
             F030021,   -- 21'采集日期'
             DIS_DATA_DATE,
             DIS_BANK_ID,
             DEPARTMENT_ID ,
             F030022
             )
 
    WITH LOAN_JJJ AS (         
        SELECT A.ACCT_NUM,
           A.LOAN_PURPOSE_CD,  
            CASE  
           WHEN A.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN (A.DEPARTMENTD ='公司金融' OR SUBSTR(A.ITEM_CD,1,6) IN ('130601','130602')) THEN '0098JR' -- 公司金融部(0098JR)
           WHEN A.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN A.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(A.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(A.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           ELSE '009804'
           END AS TX,
           ROW_NUMBER() OVER(PARTITION BY A.ACCT_NUM ORDER BY A.USEOFUNDS DESC) AS NUM
      FROM SMTMODS.L_ACCT_LOAN A
      LEFT JOIN (SELECT DISTINCT LOAN_NUM  , WRITE_OFF_DATE -- 核销日期
      FROM SMTMODS.L_ACCT_WRITE_OFF  -- 贷款核销
     WHERE DATA_DATE=I_DATE )T12
        ON A.LOAN_NUM=T12.LOAN_NUM
     WHERE A.DATA_DATE=I_DATE
       AND ((A.CANCEL_FLG = 'Y' 
             AND T12.WRITE_OFF_DATE >= SUBSTR(I_DATE,1,4)||'0101' ) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
             OR A.ACCT_STS <> '3'
			 -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
             OR A.LOAN_ACCT_BAL > 0 and (A.LOAN_STOCKEN_DATE IS NULL OR A.LOAN_STOCKEN_DATE >= SUBSTR(I_DATE,1,4)||'0101')   -- add by haorui 20250311 JLBA202408200012_关于新一代信贷管理系统增加不良资产收益权转让账务处理功能的需求-
             OR A.FINISH_DT = I_DATE)),
     ACCT_PROJECT AS       -- 20250225
       ( SELECT  T1.DATA_DATE          
         ,T1.ACCT_NUM           
         ,T1.PROJECT_NAME       
         ,T1.PROJECT_TYPE       
         ,T1.PROJ_INVES         
         ,T1.CAPITAL          
         ,T1.PLAN_PERMIT_NUMBER 
         ,T1.CON_LAND_PER_NUM   
         ,T1.ENV_ASS_PER_NUM        
         ,T1.SILK_ROAD_PRO_FLAG 
         ,T1.DEPARTMENTD        
         ,T1.DATE_SOURCESD      
         ,T1.PROJECT_TYPE_DESC  
         ,MAX(T1.APROVEL_NUMBER) AS APROVEL_NUMBER     --   '批文文号'
         ,MAX(T1.PROJECT_APROVAL) AS PROJECT_APROVAL    --   '立项批文'     
         ,GROUP_CONCAT(T1.LAND_PER_NUM SEPARATOR  ';') AS LAND_PER_NUM        --   '土地使用证编号
         ,GROUP_CONCAT(TO_CHAR(TO_DATE(T1.LAND_PER_DATE,'YYYYMMDD'),'YYYY-MM-DD') SEPARATOR  ';') AS LAND_PER_DATE       --   '土地使用证日期'
         ,GROUP_CONCAT(T1.LAND_PLAN_PER_NUM  SEPARATOR  ';') AS LAND_PLAN_PER_NUM   --   '用地规划许可证编号'
         ,GROUP_CONCAT(TO_CHAR(TO_DATE(T1.LAND_PLAN_PER_DATE,'YYYYMMDD'),'YYYY-MM-DD') SEPARATOR ';') AS LAND_PLAN_PER_DATE  --   '用地规划许可证日期'
         ,GROUP_CONCAT(T1.BUIL_PER_NUM SEPARATOR  ';') AS BUIL_PER_NUM        --   '施工许可证编号'
         ,GROUP_CONCAT(TO_CHAR(TO_DATE(T1.BUIL_PER_DATE,'YYYYMMDD'),'YYYY-MM-DD') SEPARATOR  ';') AS BUIL_PER_DATE       --   '施工许可证日期'
         ,GROUP_CONCAT(T1.BUIL_PLAN_PER_NUM  SEPARATOR ';') AS BUIL_PLAN_PER_NUM   --   '工程规划许可证编号'
         ,GROUP_CONCAT(TO_CHAR(TO_DATE(T1.BUIL_PLAN_PER_DATE,'YYYYMMDD'),'YYYY-MM-DD') SEPARATOR  ';') AS BUIL_PLAN_PER_DATE  --   '工程规划许可证日期' 
         ,MAX(TO_CHAR(TO_DATE(T1.BEG_DATE,'YYYYMMDD'),'YYYY-MM-DD')) AS BEG_DATE  --   '开工日期  
         ,GROUP_CONCAT(T1.OTHER_PER  SEPARATOR  ';') AS OTHER_PER          
         ,GROUP_CONCAT(T1.OTHER_PER_NUM  SEPARATOR  ';') AS OTHER_PER_NUM  
   FROM (SELECT DISTINCT T1.* FROM  SMTMODS.L_ACCT_PROJECT T1 -- 项目贷款信息表	
          WHERE T1.DATA_DATE=I_DATE) T1 
 GROUP BY T1.DATA_DATE          
         ,T1.ACCT_NUM           
         ,T1.PROJECT_NAME       
         ,T1.PROJECT_TYPE       
         ,T1.PROJ_INVES         
         ,T1.CAPITAL          
         ,T1.PLAN_PERMIT_NUMBER 
         ,T1.CON_LAND_PER_NUM   
         ,T1.ENV_ASS_PER_NUM       
         ,T1.SILK_ROAD_PRO_FLAG 
         ,T1.DEPARTMENTD        
         ,T1.DATE_SOURCESD      
         ,T1.PROJECT_TYPE_DESC  )      
             
  
  SELECT   B.ORG_ID AS F030001,   -- 1 机构ID
           T1.ACCT_NUM F030002,   -- 2 协议ID
           CASE 
           WHEN T2.CP_ID ='DK001000300001' AND (SUBSTR(A.LOAN_PURPOSE_CD,1,1) IN  ('D','G','N') OR SUBSTR(A.LOAN_PURPOSE_CD,1,3) ='E48') THEN '01' -- 基础设施建设项目
           WHEN T2.CP_ID IN ('DK001000300002','DK001000300004','DK001000300001') AND SUBSTR(A.LOAN_PURPOSE_CD,1,1) = 'K' THEN '02' -- 房地产项目
           WHEN T2.CP_ID = 'DK001000300001' AND SUBSTR(A.LOAN_PURPOSE_CD,1,1) = 'M' THEN '04' -- 科技开发项目     
           WHEN T2.CP_ID = 'DK001001300001' THEN '05' -- 并购贷款          
           WHEN T2.CP_ID = 'DK001000300001' THEN '00' -- 00 其他 
           ELSE '00' -- 00 其他 
           END AS F030003 ,  -- 20250225
           SUBSTR(T1.PROJECT_NAME, 1, 30) AS F030004, -- 4项目名称
           T1.PROJ_INVES * 10000 AS F030005, -- 5项目总投资 
           NVL(T1.CAPITAL,0) *10000 AS F030006, -- 6项目资本金 
           T1.APROVEL_NUMBER AS F030007, -- 7批文文号
           T1.PROJECT_APROVAL AS F030008, -- 8立项批文              
           substr(T1.LAND_PER_NUM,1,200) AS F030009, -- 9土地使用证编号
           NVL(T1.LAND_PER_DATE,'9999-12-31') AS F030010, -- 10土地使用证日期 
           substr(T1.LAND_PLAN_PER_NUM,1,200) AS F030011, -- 11用地规划许可证编号
           NVL(T1.LAND_PLAN_PER_DATE,'9999-12-31') AS F030012, -- 12用地规划许可证日期 
           substr(T1.BUIL_PER_NUM,1,200) AS F030013, -- 13施工许可证编号  
           NVL(T1.BUIL_PER_DATE,'9999-12-31') AS F030014,  -- 14施工许可证日期  
           substr(T1.BUIL_PLAN_PER_NUM,1,200) AS F030015, -- 15工程规划许可证编号
           NVL(T1.BUIL_PLAN_PER_DATE,'9999-12-31') AS F030016, -- 16工程规划许可证日期  
           NULL AS F030017,   -- 17'其他许可证'
           NULL AS F030018,   -- 18'其他许可证编号'
           T1.BEG_DATE  AS F030019, -- 19开工日期
           NULL AS F030020, -- 20备注
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),   -- 21 采集日期
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
           T2.ORG_NUM,
           A.TX,
           T2.CURR_CD
      FROM ACCT_PROJECT T1 -- 项目贷款信息表
     INNER JOIN (SELECT * FROM LOAN_JJJ WHERE NUM = 1) A
        ON T1.ACCT_NUM = A.ACCT_NUM
      LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T2 -- 贷款合同信息表
        ON T1.ACCT_NUM = T2.CONTRACT_NUM
       AND T2.DATA_DATE = I_DATE
      LEFT JOIN VIEW_L_PUBL_ORG_BRA B -- 机构表
        ON T2.ORG_NUM = B.ORG_NUM
       AND B.DATA_DATE = I_DATE
     WHERE (T2.ACCT_STS ='1' OR 
            T2.ACCT_STS ='2' AND T2.CONTRACT_EXP_DT >= SUBSTR(I_DATE,1,4)||'0101' )  ;  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
  
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


