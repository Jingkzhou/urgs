DROP Procedure IF EXISTS `PROC_BSP_T_3_7_GRKHGXR` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_3_7_GRKHGXR"(IN I_DATE VARCHAR(8),
                                          OUT OI_RETCODE   INT,-- 返回code
                                          OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN

  /******
      程序名称  ：表3.7个人客户关系人
      程序功能  ：加工表3.7个人客户关系人
      目标表：T_3_7
      源表  ：两段  个人客户 和 保证人 
      创建人  ：WJB
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
	SET P_PROC_NAME = 'PROC_BSP_T_3_7_GRKHGXR';
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
	
	DELETE FROM T_3_7 WHERE C070011 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 DELETE FROM T_3_7_TEMP1;

	
INSERT  INTO T_3_7_TEMP1 (
 
 C070001    , -- 01'关系ID'
 C070002    , -- 02'机构ID'
 C070003    , -- 03'个人ID'
 C070004    , -- 04'社会关系'
 C070005    , -- 05'关系人ID'
 C070006    , -- 06'关系人姓名'
 C070007    , -- 07'关系人证件类型'
 C070008    , -- 08'关系人证件号码'
 C070009    , -- 09'建立关系日期'
 C070010    , -- 10'解除关系日期'
 C070011    , -- 11'采集日期'
 DIS_DATA_DATE, -- 装入数据日期
 DIS_BANK_ID,   -- 机构号
 DEPARTMENT_ID    
 
)

 SELECT    T1.CUST_ID||T1.RE_CUST_ID||T1.RE_CUST_TYP AS C070001,     -- 01'关系ID'
           -- T1.ORG_NUM AS C070002,                       	         -- 02'机构ID'  ORG.ORG_ID
           ORG.ORG_ID,                                               -- 02'机构ID'
           T1.CUST_ID AS C070003,                                    -- 03'个人ID'
           T1.RE_CUST_TYP AS C070004,                              	 -- 04'社会关系'
           T1.RE_CUST_ID AS C070005,                                 -- 05'关系人ID'
           T1.RE_CUST_NAME AS C070006,                               -- 06'关系人姓名'
           M.GB_CODE AS C070007,                                     -- 07'关系人证件类型'
           T3.ID_NO AS C070008,                                      -- 08'关系人证件号码'
           NVL(TO_CHAR(TO_DATE(T1.JLGXRQ,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') AS C070009, -- 09 '建立关系日期'
           '9999-12-31' AS C070010,                                                          -- 10 '解除关系日期' 默认9999-12-31 
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS C070011,                -- 11 '采集日期'
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE,                -- 12 '装入数据日期'
		   T1.ORG_NUM AS DIS_BANK_ID,                                                        -- 13 '机构号'
		   ROW_NUMBER() OVER(PARTITION BY T1.CUST_ID,T1.RE_CUST_ID ORDER BY  decode(t1.RE_CUST_TYP,0,9) desc  ) AS RN
                            
       FROM SMTMODS.L_CUST_R_RELATED_P T1 -- 个人客户关系人信息 
       LEFT JOIN SMTMODS.L_CUST_ALL T3 -- 全量客户信息表
         ON T1.RE_CUST_ID = T3.CUST_ID
        AND T3.DATA_DATE = I_DATE
       LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构视图
  	     ON T1.ORG_NUM = ORG.ORG_NUM
 		AND ORG.DATA_DATE = I_DATE
 	   LEFT JOIN M_DICT_CODETABLE M -- 码值表
   	     ON T1.P_ID_TYPE = M.L_CODE
  	    AND M.L_CODE_TABLE_CODE = 'C0001'
      WHERE T1.DATA_DATE = I_DATE
        AND T1.RE_CUST_TYP <> '6' -- 保证人数据在第二段加工
        AND NVL(T1.CUST_ID,'@')<>NVL(T1.RE_CUST_ID,'@') -- 本人为本人担保的关系不报送
        AND 
        (
        EXISTS (SELECT 1 FROM YBT_DATACORE.T_4_3 A WHERE A.D030015 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  AND A.D030003 = T1.CUST_ID) 
		OR 
		EXISTS (SELECT 1 FROM YBT_DATACORE.T_8_13 B WHERE B.H130023 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AND B.H130002 = T1.CUST_ID)
		) -- 只报送在分户账和授信情况表中存在的客户
	    ;
	    COMMIT;
	
 INSERT  INTO T_3_7(
 
 C070001    , -- 01'关系ID'
 C070002    , -- 02'机构ID'
 C070003    , -- 03'个人ID'
 C070004    , -- 04'社会关系'
 C070005    , -- 05'关系人ID'
 C070006    , -- 06'关系人姓名'
 C070007    , -- 07'关系人证件类型'
 C070008    , -- 08'关系人证件号码'
 C070009    , -- 09'建立关系日期'
 C070010    , -- 10'解除关系日期'
 C070011    , -- 11'采集日期'
 DIS_DATA_DATE, -- 装入数据日期
 DIS_BANK_ID,   -- 机构号
 DEPARTMENT_ID       -- 业务条线
)
   
 SELECT 
 T1.C070001    , -- 01'关系ID'
 T1.C070002    , -- 02'机构ID'
 T1.C070003    , -- 03'个人ID'
 CASE WHEN T1.C070004='1' THEN '01' -- 配偶
      WHEN T1.C070004='3' THEN '02' -- 子女
      WHEN T1.C070004='2' THEN '03' -- 父母
      ELSE '00' -- 其他  
       END  , -- 04'社会关系'
 T1.C070005    , -- 05'关系人ID'
 T1.C070006    , -- 06'关系人姓名'
 T1.C070007    , -- 07'关系人证件类型'
 T1.C070008    , -- 08'关系人证件号码'
 T1.C070009    , -- 09'建立关系日期'
 T1.C070010    , -- 10'解除关系日期'
 T1.C070011    , -- 11'采集日期'
 T1.DIS_DATA_DATE, -- 装入数据日期
 T1.DIS_BANK_ID,   -- 机构号
 '0098LDB' AS DIS_DEPARTMENT_ID   -- 业务条线 
FROM T_3_7_TEMP1 T1
WHERE t1.C070011 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')
	AND DEPARTMENT_ID ='1';
 	    COMMIT;

     
    #4.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '保证人数据插入';
 
 DELETE FROM T_3_7_TEMP;

 INSERT  INTO T_3_7_TEMP (
 
 C070001    , -- 01'关系ID'
 C070002    , -- 02'机构ID'
 C070003    , -- 03'个人ID'
 C070004    , -- 04'社会关系'
 C070005    , -- 05'关系人ID'
 C070006    , -- 06'关系人姓名'
 C070007    , -- 07'关系人证件类型'
 C070008    , -- 08'关系人证件号码'
 C070009    , -- 09'建立关系日期'
 C070010    , -- 10'解除关系日期'
 C070011    , -- 11'采集日期'
 DIS_DATA_DATE, -- 装入数据日期
 DIS_BANK_ID,   -- 机构号
 DIS_DEPARTMENT_ID       -- 业务条线
)

SELECT
      T2.CUST_ID||T4.GUAR_CUST_ID AS C070001,   -- 关系ID
      ORG.ORG_ID AS C070002,                    -- 机构ID
      T2.CUST_ID AS C070003,                    -- 个人ID
      '00' AS C070004,                          -- 社会关系 默认  '00' 其他
      T4.GUAR_CUST_ID AS C070005,               -- 关系人ID
      T5.CUST_NAM AS C070006,                   -- 关系人姓名
      M.GB_CODE AS C070007,                     -- 关系人证件类型
      T5.ID_NO AS C070008,                      -- 关系人证件号码
      NVL(TO_CHAR(TO_DATE(T1.GUAR_CONTRACT_START_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') AS C070009,     --  建立关系日期
      -- NVL(TO_CHAR(TO_DATE(T1.GUAR_CONTRACT_END_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31')   AS C070010,     --  解除关系日期
      CASE WHEN T1.GUAR_CONTRACT_END_DT > I_DATE THEN '9999-12-31'
       ELSE NVL(TO_CHAR(TO_DATE(T1.GUAR_CONTRACT_END_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') 
       END AS C070010,     --  解除关系日期  YBT_JYC07-25
      TO_CHAR(TO_DATE(T1.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS C070011,                                    --  采集日期
      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE,	     						    --  装入数据日期
      T2.ORG_NUM AS DIS_BANK_ID,                                           	 							    --  机构号
      '0098LDB' AS DIS_DEPARTMENT_ID     	 			                                           		    --  业务条线  默认零售信贷部
      FROM SMTMODS.L_AGRE_GUARANTEE_CONTRACT T1 -- 担保合同信息
     INNER JOIN SMTMODS.L_CUST_P T2 -- 对私客户信息
        ON T1.GUARTED_CUST_ID = T2.CUST_ID
       AND T2.DATA_DATE = I_DATE
      LEFT JOIN VIEW_L_PUBL_ORG_BRA ORG -- 机构视图
  	    ON T2.ORG_NUM = ORG.ORG_NUM
 	   AND ORG.DATA_DATE = I_DATE
	  LEFT JOIN
      (
      SELECT A.DATA_DATE,A.GUAR_CONTRACT_NUM,A.GUAR_CUST_ID,A.REL_STATUS,COUNT(*) 
        FROM SMTMODS.L_AGRE_GUARANTEE_RELATION A -- 担保合同与担保信息对应关系表
       WHERE A.DATA_DATE = I_DATE AND A.REL_STATUS <> 'N' 
       GROUP BY A.DATA_DATE,A.GUAR_CONTRACT_NUM,A.GUAR_CUST_ID,A.REL_STATUS
       ) T4 -- 担保合同与担保信息对应关系表   同一个担保合同下同一个客户号有多条担保物信息的 合为一条记录 作为一个关系人报送
        ON T1.GUAR_CONTRACT_NUM = T4.GUAR_CONTRACT_NUM	  
	   AND T4.DATA_DATE = I_DATE
	  LEFT JOIN SMTMODS.L_CUST_ALL T5 -- 全量客户信息表
	    ON T5.CUST_ID = T4.GUAR_CUST_ID
	   AND T5.DATA_DATE = I_DATE
      LEFT JOIN M_DICT_CODETABLE M -- 码值表
   	    ON T5.ID_TYPE = M.L_CODE
  	   AND M.L_CODE_TABLE_CODE = 'C0001'
	 WHERE T1.DATA_DATE = I_DATE
	   AND T4.REL_STATUS='Y' -- 关联状态为有效
	   AND NVL(T1.GUARTED_CUST_ID,'@')<>NVL(T4.GUAR_CUST_ID,'@') -- 本人为本人担保的关系不报送
	   AND (T1.GUAR_CONTRACT_START_DT <= I_DATE OR T1.GUAR_CONTRACT_START_DT IS NULL) -- YBT_JYC07-22 20250421 同步6.8取关系生效日期小于等于数据日期
       AND
      (
        EXISTS (SELECT 1 FROM YBT_DATACORE.T_4_3 A WHERE A.D030015 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')  AND A.D030003 = T2.CUST_ID) 
		OR 
		EXISTS (SELECT 1 FROM YBT_DATACORE.T_8_13 B WHERE B.H130023 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AND B.H130002 = T2.CUST_ID)
	   ) -- 只报送在分户账和授信情况表中存在的客户
       ;
    COMMIT;
INSERT  INTO T_3_7(
 
 C070001    , -- 01'关系ID'
 C070002    , -- 02'机构ID'
 C070003    , -- 03'个人ID'
 C070004    , -- 04'社会关系'
 C070005    , -- 05'关系人ID'
 C070006    , -- 06'关系人姓名'
 C070007    , -- 07'关系人证件类型'
 C070008    , -- 08'关系人证件号码'
 C070009    , -- 09'建立关系日期'
 C070010    , -- 10'解除关系日期'
 C070011    , -- 11'采集日期'
 DIS_DATA_DATE, -- 装入数据日期
 DIS_BANK_ID,   -- 机构号
 DEPARTMENT_ID       -- 业务条线
)
SELECT C070001,
       C070002,
       C070003,
       C070004,
       C070005,
       C070006,
       C070007,
       C070008,
       MIN(C070009),
       MAX(C070010),
       C070011,
       DIS_DATA_DATE,
       DIS_BANK_ID,
       DIS_DEPARTMENT_ID
  FROM T_3_7_TEMP T
  WHERE NOT EXISTS (SELECT 1 FROM T_3_7_TEMP1 T1 WHERE t1.C070011 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AND T.C070003||T.C070005=T1.C070003||T1.C070005) 
 GROUP BY C070001,
          C070002,
          C070003,
          C070004,
          C070005,
          C070006,
          C070007,
          C070008,
          C070011,
          DIS_DATA_DATE,
          DIS_BANK_ID,
          DIS_DEPARTMENT_ID; 
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

