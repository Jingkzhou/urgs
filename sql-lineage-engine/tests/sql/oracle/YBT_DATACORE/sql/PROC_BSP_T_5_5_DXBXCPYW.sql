DROP Procedure IF EXISTS `PROC_BSP_T_5_5_DXBXCPYW` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_5_5_DXBXCPYW"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回code
                                        OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN

  /******
      程序名称  ：代销保险产品业务
      程序功能  ：加工代销保险产品业务
      目标表：T_5_5
      源表  ：
      创建人  ：87v
      创建日期  ：20240110
      版本号：V0.0.1 
  --需求编号：JLBA202401110001 上线日期：2025-07-24，修改人：蒿蕊，提出人：从需求 修改原因：调整险种映射关系
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
	SET P_PROC_NAME = 'PROC_BSP_T_5_5_DXBXCPYW';
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
	
	DELETE FROM T_5_5 WHERE E050010 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
    CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
   INSERT  INTO T_5_5  (
     E050001 , -- 01  产品 ID
     E050002 , -- 02  机构 ID
     E050003 , -- 03  产品名称
     E050004 , -- 04  产品编号
     E050005 , -- 05  保险公司名称
     E050006 , -- 06  险种子类型代码
     E050007 , -- 07  附加险产品编号
     E050008 , -- 08  附加险名称
     E050009 , -- 09  备注
     E050010 , -- 10  采集日期
     DIS_DATA_DATE , -- 装入数据日期
     DIS_BANK_ID   ,   -- 机构号
     DIS_DEPT,
     DEPARTMENT_ID -- 业务条线
     
       )
     SELECT 
      distinct 
       T1.PROD_CODE          , -- 01  产品 ID
       CASE WHEN T1.ORG_NUM ='009804' THEN 'B0302H22201009804'
            ELSE 'B0302H22201009823' END  AS E050002, -- 02  机构 ID 20250507 吴大为老师提供口径修改 jlf
       -- ORG.ORG_ID            
       T1.PROD_NAME          , -- 03  产品名称
       T1.PROD_CODE          , -- 04  产品编号
       T1.ISSUER_NAME        , -- 05  保险公司名称
       -- T1.XZZLXDM            , -- 06  险种子类型代码
	   case -- when T1.XZZLXDM = '1' then '1002'	-- 分红寿险 [2025-07-24] [蒿蕊] [JLBA202401110001] [从需求]注释，业务重新提供映射关系
            -- when T1.XZZLXDM = '9' then '2004'	-- 保证保险 [2025-07-24] [蒿蕊] [JLBA202401110001] [从需求]注释，业务重新提供映射关系
            when T1.XZZLXDM = '3' then '1003'	-- 投资连结保险
            when T1.XZZLXDM = '4' then '1006'	-- 健康保险
            when T1.XZZLXDM = '5' then '1005'	-- 年金保险
            -- when T1.XZZLXDM = '2' then '1004'	-- 万能保险 [2025-07-24] [蒿蕊] [JLBA202401110001] [从需求]注释，业务重新提供映射关系
	        when T1.XZZLXDM IN ('6','7') THEN '2005' -- 其他保险 [2025-07-24] [蒿蕊] [JLBA202401110001] [从需求]去掉码值8，业务重新提供映射关系
			when T1.XZZLXDM IN ('1','2','8','9') THEN '1001' -- 普通寿险 [2025-07-24] [蒿蕊] [JLBA202401110001] [从需求]经业务老师陈开泰、朱玉轩老师、大为哥确认映射关系调整\
			-- [2025-07-24] [蒿蕊] [JLBA202401110001] [从需求]新增险种A-E
			WHEN T1.XZZLXDM = 'A' THEN '1007'   -- 意外伤害保险   
			WHEN T1.XZZLXDM IN ('B','C') THEN '1001' -- 普通寿险
			WHEN T1.XZZLXDM IN ('D','E') THEN '1006' -- 健康保险
			ELSE '2005'
       END 					 , -- 06     险种子类型代码
       T1.FJXCPBH            , -- 07  附加险产品编号
       T1.FJXMC              , -- 08  附加险名称
       NULL                  , -- 09  备注
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 10  采集日期
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
	   CASE WHEN T1.ORG_NUM ='009804' THEN '009804'
            ELSE '009823' END          ,                           -- 机构号 20250507 吴大为老师提供口径修改 jlf
	   null,
	  CASE WHEN T1.ORG_NUM ='009804' THEN '009804'
           ELSE '009823' END -- 财富管理部20250507
      FROM SMTMODS.L_PROD_AGENCY_PRODUCT T1
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON T1.ORG_NUM = ORG.ORG_NUM
       AND ORG.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_AGRE_PROD_AGENCY A  -- 代理代销协议表  -- JLBA202411180016 20241217
        ON T1.PROD_CODE =A.DLCP_ID
       AND A.DATA_DATE= I_DATE 
     WHERE T1.DATA_DATE = I_DATE
       AND (T1.ESTAB_DATE <= I_DATE OR A.QYRQ<= I_DATE)  -- JLBA202411180016 20241217
	   AND (T1.ISSUER_NAME like '%保险%'  OR T1.PROD_NAME LIKE '%保%险%')
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

