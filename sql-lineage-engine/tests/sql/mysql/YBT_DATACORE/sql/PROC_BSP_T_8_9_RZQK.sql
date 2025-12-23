DROP Procedure IF EXISTS `PROC_BSP_T_8_9_RZQK` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_9_RZQK"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN
/******
      程序名称  ：融资情况
      程序功能  ：加工融资情况
      目标表：T_8_9
      源表  ：
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	-- JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：因一表通校验问题发现的代码逻辑调整
	 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
	/*需求编号：JLBA202509280009 上线日期：2025-10-28，修改人：巴启威，提出人：吴大为 修改原因：关于一表通监管数据报送系统修改逻辑的需求 */
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
	SET P_PROC_NAME = 'PROC_BSP_T_8_9_RZQK';
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
	
	DELETE FROM T_8_9 WHERE H090010 = to_char(P_DATE,'yyyy-mm-dd');										
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';

-- 存单投资与发行信息表  取存单发行
 INSERT  INTO T_8_9  (
   H090001,  -- 01.融资业务ID
   H090002,  -- 02.产品ID
   H090011,  -- 11.机构ID
   H090003,  -- 03.融资工具类型
   H090004,  -- 04.融资工具子类型
   H090012,  -- 12.科目ID
   H090013,  -- 13.成本类型
   H090014,  -- 14.成本总额
   H090005,  -- 05.合同金额
   H090006,  -- 06.币种
   H090007,  -- 07.融资余额
   H090008,  -- 08.合同执行利率
   H090009,  -- 09.担保协议ID
   H090015,  -- 15.生效日期
   H090016,  -- 16.到期日期
   H090010,  -- 10.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DIS_DEPT      ,
   DEPARTMENT_ID , -- 业务条线
   H090017       , -- 17.同业ID
   H090018       , -- 18.股权托管比例
   H090019       , -- 19.托管机构名称
   H090020       , -- 20.融资标的ID
   H090021         -- 21.发行国家地区
 ) 
SELECT 
   -- T.ACCT_NUM || T.CDS_NO || nvl(T.CONT_PARTY_CODE,'') , -- 01 '融资业务ID'
   FUNC_SUBSTR(T.ACCT_NUM || T.CONT_PARTY_NAME,60) ,-- 01 '融资业务ID' -- 账号拼交易对手名称 参照4.3,应与7.12同步   按常城要求截取60位
   T.CP_ID                 , -- 02 '产品ID'
   ORG.ORG_ID              , -- 11 '机构ID'
   '01'                    , -- 03 '融资工具类型'  -- 存单
   '012'                   , -- 04 '融资工具子类型' -- 同业存单  
   T.GL_ITEM_CODE          , -- 12 '科目ID'
   '01'                    , -- 13 '成本类型' --  经同业金融部确认，默认01-固定成本
   T.CYCB                  , -- 14 '成本总额'
   T.FACE_VAL              , -- 05 '合同金额'
   T.CURR_CD               , -- 06 '币种'
   T.PRINCIPAL_BALANCE     , -- 07 '融资余额'
   T.INT_RAT               , -- 08 '合同执行利率'
   NULL                    , -- 09 '担保协议ID'  -- 经同业金融部确认，默认空值
   TO_CHAR(TO_DATE(T.INT_ST_DT,'YYYYMMDD'),'YYYY-MM-DD')             , -- 15 '生效日期'
   TO_CHAR(TO_DATE(T.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD')           , -- 16 '到期日期'
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 10 '采集日期'
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
   T.ORG_NUM                                       , -- 机构号
   NULL,
   CASE 
     WHEN T.ORG_NUM = '009804' THEN '009804' -- 金融市场部
     WHEN T.ORG_NUM = '009820' THEN '009820' -- 同业金融部
   END                                              , -- 业务条线
   T.CUST_ID                                        , -- 17 同业ID
   NULL                                             , -- 18 股权托管比例
   NULL                                             , -- 19 托管机构名称
   T.CDS_NO                                         , -- 20.融资标的ID
   'CHN'                                              -- 21 发行国家地区
 FROM SMTMODS.L_ACCT_FUND_CDS_BAL T  -- 存单投资与发行信息表
 LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON T.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
 WHERE T.DATA_DATE=I_DATE 
   AND T.PRODUCT_PROP = 'B'
   -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
   and (T.PRINCIPAL_BALANCE<>0 or T.MATURITY_DT is null or T.MATURITY_DT='' or T.MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101' );  -- 同业存单发行;
 
 -- ADD BY WJB 20240708 一表通2.0升级：补充开发大额存单，转股协议存款 ('20110211' 转股协议存款 ,'20110113' 发行个人大额存单 ,'20110208' 发行单位大额存单)

 INSERT  INTO T_8_9  (
   H090001,  -- 01.融资业务ID
   H090002,  -- 02.产品ID
   H090011,  -- 11.机构ID
   H090003,  -- 03.融资工具类型
   H090004,  -- 04.融资工具子类型
   H090012,  -- 12.科目ID
   H090013,  -- 13.成本类型
   H090014,  -- 14.成本总额
   H090005,  -- 05.合同金额
   H090006,  -- 06.币种
   H090007,  -- 07.融资余额
   H090008,  -- 08.合同执行利率
   H090009,  -- 09.担保协议ID
   H090015,  -- 15.生效日期
   H090016,  -- 16.到期日期
   H090010,  -- 10.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DIS_DEPT      ,
   DEPARTMENT_ID , -- 业务条线
   H090017       , -- 17.同业ID
   H090018       , -- 18.股权托管比例
   H090019       , -- 19.托管机构名称
   H090020       , -- 20.融资标的ID
   H090021         -- 21.发行国家地区
 ) 
SELECT 
   -- T.ACCT_NUM || T.CDS_NO || nvl(T.CONT_PARTY_CODE,'') , -- 01 '融资业务ID'
   -- T.ACCT_NUM || T.CONT_PARTY_NAME ,-- 01 '融资业务ID' -- 账号拼交易对手名称 参照4.3,应与7.12同步
   T.ACCT_NUM              , -- 01 '融资业务ID'
   -- T.CP_ID                 , -- 02 '产品ID'
   T.POC_INDEX_CODE                      , -- 02 '产品ID'
   ORG.ORG_ID              , -- 11 '机构ID'
   CASE 
     WHEN T.GL_ITEM_CODE='20110211' THEN '07'-- 转股协议存款           -- 其他具有固定期限的融资工具
     WHEN T.GL_ITEM_CODE='20110113' THEN '01'-- 发行个人大额存单 -- 存单
     WHEN T.GL_ITEM_CODE='20110208' THEN '01'-- 发行单位大额存单 -- 存单
   END                     , -- 03 '融资工具类型'
   CASE 
     WHEN T.GL_ITEM_CODE='20110211' THEN '071'-- 转股协议存款           -- 其他具有固定期限的融资工具
     WHEN T.GL_ITEM_CODE='20110113' THEN '011'-- 发行个人大额存单 -- 大额存单
     WHEN T.GL_ITEM_CODE='20110208' THEN '011'-- 发行单位大额存单 -- 同业存单   -- [2023-03-21] [jlf] [邮件修改][吴大为]8.9融资情况表融资工具子类型映射关系，将单位大额存款由“012-同业存单”调整至“011-大额存单”。
   END                     , -- 04 '融资工具子类型'
   T.GL_ITEM_CODE          , -- 12 '科目ID'
   '01'                    , -- 13 '成本类型' --  经同业金融部确认，默认01-固定成本
   T.OPEN_ACCT_AMT         , -- 14 '成本总额'
   -- T.OPEN_ACCT_AMT        , -- 05 '合同金额' 
   T.FST_CRE_AMT           , -- 05 '合同金额'  -- [20250619][巴启威][JLBA202505280002][吴大为]：开户金额可为0，取第一笔入账交易金额
   T.CURR_CD               , -- 06 '币种'
   T.ACCT_BALANCE          , -- 07 '融资余额'
   T.INT_RATE              , -- 08 '合同执行利率'
   NULL                    , -- 09 '担保协议ID'  -- 经同业金融部确认，默认空值
   TO_CHAR(TO_DATE(T.ST_INT_DT,'YYYYMMDD'),'YYYY-MM-DD')             , -- 15 '生效日期'
   TO_CHAR(TO_DATE(T.MATUR_DATE,'YYYYMMDD'),'YYYY-MM-DD')            , -- 16 '到期日期'
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 10 '采集日期'
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
   T.ORG_NUM                                       , -- 机构号
   NULL,
   /*CASE 
     WHEN T.ORG_NUM = '009804' THEN '009804' -- 金融市场部
     WHEN T.ORG_NUM = '009820' THEN '009820' -- 同业金融部
   END                                              , -- 业务条线
   */
   T.ORG_NUM                                        , -- 业务条线
   T.CUST_ID                                        , -- 17 同业ID
   NULL                                             , -- 18 股权托管比例
   NULL                                             , -- 19 托管机构名称
   T.ACCT_NUM                                       , -- 20.融资标的ID
   'CHN'                                              -- 21 发行国家地区
  FROM SMTMODS.L_ACCT_DEPOSIT T -- 存款账户信息表
  LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
    ON T.ORG_NUM = ORG.ORG_NUM
   AND ORG.DATA_DATE = I_DATE
 WHERE T.DATA_DATE=I_DATE
   AND T.GL_ITEM_CODE IN ('20110211','20110113','20110208') -- ('20110211' 转股协议存款 ,'20110113' 发行个人大额存单 ,'20110208' 发行单位大额存单)
   AND (T.ACCT_BALANCE <> '0'  -- 同业存单发行
  -- [20251028][巴启威][JLBA202509280009][吴大为]:增加销户日期范围判断,同步9.2口径
       OR NVL(T.ACCT_CLDATE,T.MATUR_DATE) >= SUBSTR(I_DATE,1,4)||'0101') -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
   ;
	
 --  [20250619][巴启威][JLBA202505280002][吴大为]：新增债券发行部分逻辑
 
    INSERT INTO T_8_9
 (
   H090001,  -- 01.融资业务ID
   H090002,  -- 02.产品ID
   H090011,  -- 11.机构ID
   H090003,  -- 03.融资工具类型
   H090004,  -- 04.融资工具子类型
   H090012,  -- 12.科目ID
   H090013,  -- 13.成本类型
   H090014,  -- 14.成本总额
   H090005,  -- 05.合同金额
   H090006,  -- 06.币种
   H090007,  -- 07.融资余额
   H090008,  -- 08.合同执行利率
   H090009,  -- 09.担保协议ID
   H090015,  -- 15.生效日期
   H090016,  -- 16.到期日期
   H090010,  -- 10.采集日期
   H090017, -- 17.同业ID
   H090018, -- 18.股权托管比例
   H090019, -- 19.托管机构名称
   H090020, -- 20.融资标的ID
   H090021, -- 21.发行国家地区
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DIS_DEPT      ,
   DEPARTMENT_ID   -- 业务条线
 )
 SELECT 
       A.ACCT_NUM||A.REF_NUM  AS H090001, -- 融资业务ID
       A.SUBJECT_CD           AS H090002, -- 产品ID
       ORG.ORG_ID             AS H090011, -- 机构ID
       '04'                   AS H090003, -- 融资工具类型 -- 次级债券
       '041'                  AS H090004, -- 融资工具子类型 -- 二级资本债
       A.GL_ITEM_CODE         AS H090012, -- 科目ID
       '01'                   AS H090013, -- 成本类型 -- 01-固定成本
       A.FACE_VAL             AS H090014, -- 成本总额
       A.FACE_VAL             AS H090005, -- 合同金额
       A.CURR_CD              AS H090006, -- 币种
       A.FACE_VAL             AS H090007, -- 融资余额
       CASE WHEN ACCT_NUM='9250200002593015' THEN 2.57
            WHEN ACCT_NUM='9019827201000055' THEN 4                  
            WHEN ACCT_NUM='9250200002533422' THEN 2.85
            END               AS H090008, -- 合同执行利率  -- 吴大为20250624邮件提出修改  姜俐锋：9250200002593015 利率2.57  9019827201000055利率4 9250200002533422利率2.85
       NULL                   AS H090009, -- 担保协议ID
       TO_CHAR(TO_DATE(A.INT_ST_DT,'YYYYMMDD'),'YYYY-MM-DD') AS H090015, -- 生效日期
       NVL(TO_CHAR(TO_DATE(A.MATURITY_DATE,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') AS H090016, -- 到期日期
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H090010, -- 采集日期
       A.CUST_ID              AS H090017, -- 同业ID
       NULL                   AS H090018, -- 股权托管比例
       NULL                   AS H090019, -- 托管机构名称
       A.ACCT_NUM||A.REF_NUM  AS H090020, -- 融资标的ID
       'CHN'                  AS H090021, -- 发行国家地区
       TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE , -- 装入数据日期
       A.ORG_NUM              AS DIS_BANK_ID , -- 机构号
       '债券发行'             AS DIS_DEPT ,
       '009806'               AS DEPARTMENT_ID   -- 业务条线 
  FROM SMTMODS.L_ACCT_FUND_BOND_ISSUE A  -- 债券发行
  LEFT JOIN SMTMODS.L_FINA_INNER B
    ON A.GL_ITEM_CODE = B.STAT_SUB_NUM
   AND A.ORG_NUM = B.ORG_NUM
   AND B.DATA_DATE = I_DATE
  LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
    ON A.ORG_NUM = ORG.ORG_NUM
   AND ORG.DATA_DATE = I_DATE
 WHERE A.DATA_DATE = I_DATE
   AND SUBSTR(A.GL_ITEM_CODE, 1, 4) = '2502'
   AND ( A.FACE_VAL <> 0 
       OR A.MATURITY_DATE >= SUBSTR(I_DATE,1,4)||'0101' -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
	   );
   COMMIT ;
   
   
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

