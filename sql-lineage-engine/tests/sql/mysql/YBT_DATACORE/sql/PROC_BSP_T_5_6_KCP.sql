DROP Procedure IF EXISTS `PROC_BSP_T_5_6_KCP` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_5_6_KCP"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回code
                                        OUT OI_REMESSAGE VARCHAR -- 返回message
)
BEGIN
/******
      程序名称  ：卡产品
      程序功能  ：加工卡产品
      目标表：T_5_6
      源表  ：
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
-- JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：因一表通校验问题发现的代码逻辑调整	
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
	SET P_PROC_NAME = 'PROC_BSP_T_5_6_KCP';
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
	
	DELETE FROM T_5_6 WHERE E060017 = to_char(P_DATE,'yyyy-mm-dd');
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
   #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '信用卡数据插入';
	
  INSERT  INTO T_5_6  (
   E060001, -- 01.产品
   E060002, -- 02.机构
   E060003, -- 03.产品名称
   E060004, -- 04.产品编号
   E060005, -- 05.卡组织代码
   E060006, -- 06.卡类型
   E060007, -- 07.卡介质类型代码
   E060008, -- 08.允许取现类型
   E060009, -- 09.允许转出标识
   E060010, -- 10.收取费用标识
   E060011, -- 11.政策功能标识
   E060012, -- 12.虚拟卡标识
   E060013, -- 13.联名卡标识
   E060014, -- 14.联名单位
   E060015, -- 15.联名单位代码
   E060016, -- 16.备注
   E060017,  -- 17.采集日期
   DIS_DATA_DATE,
   DIS_BANK_ID,   -- 机构号
   DEPARTMENT_ID       -- 业务条线
) 
 SELECT 
    A.CP_ID              , -- 01.产品
    -- 'B0302H22201009803'             , -- 02.机构ID
    'B0302H22201990000'  , -- 02.机构ID
    A.CPMC               , -- 03.产品名称
    A.CPBH               , -- 04.产品编号
    CASE WHEN UPPER(A.CPMC) LIKE '%VISA%' THEN '01'
         ELSE '04'
          END            , -- 05.卡组织代码
    '02'                 , -- 06.卡类型 信用卡
    '04'                 , -- 07.卡介质类型代码
    CASE WHEN UPPER(A.CPMC) LIKE '%VISA%' THEN '03'
         ELSE '04'
          END              , -- 08.允许取现类型
    '1'                  , -- 09.允许转出标识
    A.SQFYBS             , -- 10.收取费用标识
    '0'                  , -- 11.政策功能标识
    CASE WHEN A.XNKBS = '1'  THEN '02'  -- 虚拟卡
         ELSE '01' -- 实体卡
         END            , -- 12.虚拟卡标识
    /*
    CASE WHEN B.L_CODE IS NOT NULL THEN '1'
         ELSE '0'
          END            , -- 13.联名卡标识 取上期业务补录数据
          */
    CASE WHEN A.LMKBS='Y' THEN '1' -- 是
         ELSE '0' -- 否
          END               , -- 13.联名卡标识 20240627修改  按照银数逻辑修改
    -- B.GB_CODE_NAME       , -- 14.联名单位 取上期业务补录数据
    A.LMDW               , -- 14.联名单位 20240627修改  按照银数逻辑修改
    -- B.GB_CODE            , -- 15.联名单位代码 取上期业务补录数据
    A.LMDWDM             , -- 15.联名单位代码 20240627修改  按照银数逻辑修改
    A.BZ                 , -- 16.备注
    TO_CHAR(TO_DATE(A.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 17.采集日期
    TO_CHAR(TO_DATE(A.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
    A.ORG_NUM,
    '009803'                --   业务条线  默认信用卡中心
    FROM SMTMODS.L_CARD_PRODUCT A 
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON A.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
    /*left join YBT_DATACORE.M_DICT_CODETABLE B
        on A.CP_ID=B.L_CODE
        and B.L_CODE_TABLE_CODE='C0011'*/
    WHERE A.DATA_DATE = I_DATE and A.KLX='02'
    ;


  
    COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);		

	    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '借记卡数据插入';
	
 INSERT  INTO T_5_6  (
   E060001, -- 01.产品
   E060002, -- 02.机构
   E060003, -- 03.产品名称
   E060004, -- 04.产品编号
   E060005, -- 05.卡组织代码
   E060006, -- 06.卡类型
   E060007, -- 07.卡介质类型代码
   E060008, -- 08.允许取现类型
   E060009, -- 09.允许转出标识
   E060010, -- 10.收取费用标识
   E060011, -- 11.政策功能标识
   E060012, -- 12.虚拟卡标识
   E060013, -- 13.联名卡标识
   E060014, -- 14.联名单位
   E060015, -- 15.联名单位代码
   E060016, -- 16.备注
   E060017,  -- 17.采集日期
   DIS_DATA_DATE,   -- 17.采集日期
   DIS_BANK_ID,   -- 机构号
   DEPARTMENT_ID       -- 业务条线
) 
 SELECT 
    A.CP_ID              , -- 01.产品
    'B0302H22201990000'  , -- 02.机构ID -- [20250619][巴启威][JLBA202505280002][吴大为]：原包含村镇名称的产品，在总行下仍保存原产品ID,也需要报送
    A.CPMC               , -- 03.产品名称
    A.CPBH               , -- 04.产品编号
    '04'                 , -- 05.卡组织代码 默认银联
    '01'                 , -- 06.卡类型 借记卡
    CASE WHEN A.CPMC LIKE '%磁条%' THEN '01' 
         ELSE A.KJZLXDM
          END            , -- 07.卡介质类型代码
    '04'                 , -- 08.允许取现类型 默认境内外均可取
    '1'                  , -- 09.允许转出标识
    '0'                  , -- 10.收取费用标识
    '0'                  , -- 11.政策功能标识
    CASE WHEN A.cp_id = '42000' THEN '03' -- 单位结算卡默认 03 混合
         WHEN A.XNKBS = '1' THEN '02'  -- 虚拟卡
         ELSE '01' -- 实体卡
          END           , -- 12.虚拟卡标识
    CASE WHEN A.LMKBS='Y' THEN '1' -- 是
         ELSE '0' -- 否
          END             , -- 13.联名卡标识 
    A.LMDW                    , -- 14.联名单位
    A.LMDWDM                  , -- 15.联名单位代码
    A.BZ                      , -- 16.备注
    TO_CHAR(TO_DATE(A.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 17.采集日期
    TO_CHAR(TO_DATE(A.DATA_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,
    '990000'                  , -- [20250619][巴启威][JLBA202505280002][吴大为]：原包含村镇名称的产品，在总行下仍保存原产品ID,也需要报送
    '009821'                                                      --   业务条线  默认个人金融部 
    FROM SMTMODS.L_CARD_PRODUCT A 
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON A.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
    /*    left join YBT_DATACORE.M_DICT_CODETABLE B
        on SUBSTR(A.CPMC,1,5) = B.L_CODE_NAME
        and B.L_CODE_TABLE_CODE='C0011'
        and B.L_CODE_NAME like '环球100%' */
    WHERE A.DATA_DATE = I_DATE and A.KLX='01'
    ;

  
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

