DROP Procedure IF EXISTS `PROC_BSP_T_6_21_TZXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_21_TZXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN
/******
      程序名称  ：投资协议
      程序功能  ：加工投资协议
      目标表：T_6_21
      源表  ：
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	 /* 需求编号：JLBA202502210009 上线日期：20250415，修改人：姜俐锋，提出人：吴大为 */
	 /* 需求编号：JLBA202504060003 上线日期：20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/
	 /* 需求编号：JLBA202507090010 上线日期：20250807，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_21_TZXY';
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
	
	DELETE FROM T_6_21 WHERE F210030 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');								
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
-- 投资业务信息表	
  INSERT  INTO T_6_21  (
   F210001, -- 01.协议ID
   F210002, -- 02.机构ID
   F210003, -- 03.交易对手ID
   F210004, -- 04.交易对手名称
   F210005, -- 05.交易对手账号
   F210006, -- 06.交易对手账号行号
   F210007, -- 07.签约日期
   F210008, -- 08.生效日期
   F210009, -- 09.收益类型
   F210010, -- 10.到期日期
   F210011, -- 11.协议币种
   F210012, -- 12.协议金额
   F210013, -- 13.保证金账号
   F210014, -- 14.保证金比例
   F210015, -- 15.保证金币种
   F210016, -- 16.保证金金额
   F210017, -- 17.估值方法
   F210018, -- 18.资金来源
   F210019, -- 19.投资管理方式
   F210020, -- 20.投资标的ID
   F210021, -- 21.合同执行利率
   F210022, -- 22.含权标识
   F210023, -- 23.重点产业标识
   F210024, -- 24.经办员工ID
   F210025, -- 25.审查员工ID
   F210026, -- 26.审批员工ID
   F210027, -- 27.协议状态
   F210028, -- 28.或有负债标识
   F210029, -- 29.备注
   F210030, -- 30.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DIS_DEPT      ,
     DEPARTMENT_ID  -- 业务条线
) 
SELECT 
   T.ACCT_NUM||T.REF_NUM ,      -- 01.协议ID  -- 与8.8同步
   ORG.ORG_ID,                  -- 02.机构ID
   /*
   T1.CONT_PARTY_CODE,          -- 03.交易对手ID
   T1.CONT_PARTY_NAME,          -- 04.交易对手名称
   T1.OPPO_ACCT_NUM,            -- 05.交易对手账号
   T1.CTPY_OPEN_BANK,           -- 06.交易对手账号行号
   */
   -- T.JTDS_ID,                   -- 03.交易对手ID
   -- T.JYDSMC,                    -- 04.交易对手名称
   NVL(T.CUST_ID,C1.CUST_ID),      -- 03.交易对手ID -- 根据业务李佶阳提供的"取ECIF系统ECIF_M_CI_ORG.CUST_ID",实际上就是集市的T.CUST_ID
   NVL(T.JYDSMC,C.CUST_NAM),       -- 04.交易对手名称 -- 根据业务桑铭蔚要求空值部分用交易对手ID关联 2.0 BUG_10028620
   T.JYDSZH,                    -- 05.交易对手账号
   T.JYDSHH,                    -- 06.交易对手账号行号
   CASE WHEN INVEST_TYP <> '00'  -- 其他投资品种
       THEN TO_CHAR(TO_DATE(T.TX_DATE,'YYYYMMDD'),'YYYY-MM-DD')
       WHEN INVEST_TYP = '00'    --  债券投资 
       THEN TO_CHAR(TO_DATE(nvl(T.LATST_BUY_DT,T.TX_DATE),'YYYYMMDD'),'YYYY-MM-DD')
   END,                         -- 07.签约日期 -- [20251028][巴启威][JLBA202509280009][吴大为]: 签约日期字段取数逻辑，使用交易日期进行补充
   CASE WHEN INVEST_TYP <> '00'  -- 其他投资品种
       THEN TO_CHAR(TO_DATE(T.TX_DATE,'YYYYMMDD'),'YYYY-MM-DD')
       WHEN INVEST_TYP = '00'    --  债券投资 
       THEN TO_CHAR(TO_DATE(nvl(T.LATST_BUY_DT,T.TX_DATE),'YYYYMMDD'),'YYYY-MM-DD')
   END,                          -- 08.生效日期 -- [20251028][巴启威][JLBA202509280009][吴大为]: 生效日期 同步 签约日期口径
   '04',                        -- 09.收益类型  -- 默认04
   TO_CHAR(TO_DATE(T.MATURITY_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 10.到期日期
   T.CURR_CD,                   -- 11.协议币种
  -- T.FACE_VAL,                -- 12.协议金额
   T.FST_CRE_AMT,               -- 12.协议金额 -- [20250513][狄家卉][JLBA202504060003][吴大为]: 债券+非标投资交易方向是买入的，第一笔入账金额: 交易方向买入且金额大于0
   NULL,                        -- 13.保证金账号 -- 默认为空
   '0',                         -- 14.保证金比例 -- 默认为空，按发文没有保证金默认为0
   NULL,                        -- 15.保证金币种 -- 默认为空
   '0',                         -- 16.保证金金额 -- 默认为空，按发文没有保证金默认为0
   case 
     when T.ACCOUNTANT_TYPE IN ('1','2') then
       '01' -- 市值法
     when T.ACCOUNTANT_TYPE = '3' then
       '02' -- 成本法
   end ,                        -- 17.估值方法
   -- T1.DATE_SOURCESD,            -- 18.资金来源
   '01',                        -- 18.资金来源 -- 默认01-表内资金
   -- T.MANAGEMENT_TYPE,           -- 19.投资管理方式
   case 
     when T.ACCT_NUM in (
       'N0003100000169255',
       'N0003100000169385',
       'N0003100000169265',
       'N0003100000127485',
       'N0003100000127235',
       'N0003100000129935',
       'N0003100000120135',
       'N0003100000173675',
       'N0003100000169455',
       'N0003100000169315',
       'N0003100000169325',
       'N0003100000169485',
       'N0003100000169305',
       'N0003100000169445',
       'N0003100000169275',
       'N0003100000169365',
       'N0003100000169435',
       'N0003100000169375',
       'N0003100000080235',
       'N0003100000169395',
       'N0003100000169355',
       'N0003100000169295',
       'N0003100000169335',
       'N0003100000169285' ) then '01' -- 自主管理
     when T.ACCT_NUM in (
       'N0003100000254958',
       'N0003100000254968' ) then '02' -- 委托管理
     WHEN T.ORG_NUM ='009804' THEN 
     CASE WHEN T.GL_ITEM_CODE IN ('15010201') THEN '02' -- 委托管理
     ELSE '01' -- 自主管理
     END
     WHEN T.ORG_NUM ='009820' THEN  
     CASE WHEN T.GL_ITEM_CODE IN ('15010201') THEN '01' -- 自主管理
      WHEN T.GL_ITEM_CODE IN ('11010302','11010303') THEN '02' -- 委托管理
 END 
   end ,                        -- 19.投资管理方式 -- 参照8.8
   T.SUBJECT_CD ,               -- 20.投资标的ID
   T.REAL_INT_RAT,              -- 21.合同执行利率
   '0',                         -- 22.含权标识 -- 默认0-否
   NULL,                        -- 23.重点产业标识 -- 默认为空
   -- JBYG_ID,                     -- 24.经办员工ID 
   F.GB_CODE,  -- 24.经办员工ID
   SZYG_ID,                     -- 25.审查员工ID
   nvl(F1.GB_CODE,T.SPYG_ID),-- 26.审批员工ID
   T.ACCT_STS,                  -- 27.协议状态
   '0',                         -- 28.或有负债标识 --默认0-否
   NULL,                        -- 29.备注
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 30.采集日期
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
   T.ORG_NUM                                       , -- 机构号
   '投资业务信息表',
   case 
     when T.ORG_NUM = '009804' then '009804' -- 金融市场部
     when T.ORG_NUM = '009820' then '009820' -- 同业金融部
   end   -- 业务条线
FROM SMTMODS.L_ACCT_FUND_INVEST T -- 投资业务信息表
-- OR T.UNSTANDARD_FLG ='Y'
-- OR T6.OTHER_DEBT_TYPE IN ('A','B')
-- OR T3.ENTRUST_PRODUCT_TYPE ='04'
-- AND T7.SUBJECT_PRO_TYPE IN ('0604','0605','0699')
LEFT JOIN SMTMODS.L_CUST_C C
        ON T.CUST_ID = C.CUST_ID
        AND C.DATA_DATE = I_DATE
LEFT JOIN (select CUST_ID,CUST_NAM from (-- 金融市场部桑铭蔚  2.0 BUG_10028526 部分交易对手ID为空，通过名称关联 
   select CUST_ID,CUST_NAM,ROW_NUMBER() OVER(partition by CUST_NAM order by OPEN_DT DESC)RN from SMTMODS.L_CUST_C where DATA_DATE = I_DATE)C1 where C1.RN=1)C1
        ON T.JYDSMC = C1.CUST_NAM
LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON T.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
LEFT JOIN m_dict_codetable F
       ON T.JBYG_ID = F.L_CODE
       AND F.l_code_table_code ='C0013'
LEFT JOIN m_dict_codetable F1
       ON T.SPYG_ID = F1.L_CODE
       AND F1.l_code_table_code ='C0013'       
WHERE T.DATA_DATE = I_DATE -- 范围与8.8、7.7、4.3同步
-- AND T.INVEST_TYP IN ('04','05','12')

AND T.DATE_SOURCESD <> '基金投资' -- 按同业(金市没有基金)业务老师要求，6.21不报基金投资，8.8全报，忽略校验报错
-- AND (T.MATURITY_DATE >= I_DATE OR T.MATURITY_DATE IS NULL or T.FACE_VAL > 0 );
and T.REF_NUM <> 'TH'
-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
AND (T.MATURITY_DATE >= SUBSTR(I_DATE,1,4)||'0101' OR T.FACE_VAL > 0 );-- 应同业李佶阳要求，不判断到期日

-- 存单投资与发行信息表  
INSERT  INTO T_6_21  (
   F210001, -- 01.协议ID
   F210002, -- 02.机构ID
   F210003, -- 03.交易对手ID
   F210004, -- 04.交易对手名称
   F210005, -- 05.交易对手账号
   F210006, -- 06.交易对手账号行号
   F210007, -- 07.签约日期
   F210008, -- 08.生效日期
   F210009, -- 09.收益类型
   F210010, -- 10.到期日期
   F210011, -- 11.协议币种
   F210012, -- 12.协议金额
   F210013, -- 13.保证金账号
   F210014, -- 14.保证金比例
   F210015, -- 15.保证金币种
   F210016, -- 16.保证金金额
   F210017, -- 17.估值方法
   F210018, -- 18.资金来源
   F210019, -- 19.投资管理方式
   F210020, -- 20.投资标的ID
   F210021, -- 21.合同执行利率
   F210022, -- 22.含权标识
   F210023, -- 23.重点产业标识
   F210024, -- 24.经办员工ID
   F210025, -- 25.审查员工ID
   F210026, -- 26.审批员工ID
   F210027, -- 27.协议状态
   F210028, -- 28.或有负债标识
   F210029, -- 29.备注
   F210030, -- 30.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DIS_DEPT      ,
     DEPARTMENT_ID  -- 业务条线
		
) 
SELECT  
   T.ACCT_NUM || T.CDS_NO ,             -- 01.协议ID
   ORG.ORG_ID,              -- 02.机构ID
   /*
   T1.CONT_PARTY_CODE,      -- 03.交易对手ID
   T1.CONT_PARTY_NAME,      -- 04.交易对手名称
   T1.OPPO_ACCT_NUM,        -- 05.交易对手账号
   T1.CTPY_OPEN_BANK,       -- 06.交易对手账号行号
   */
   -- T.JTDS_ID,                   -- 03.交易对手ID
   -- T.CONT_PARTY_NAME,           -- 04.交易对手名称
   NVL(T.CUST_ID,C1.CUST_ID),                   -- 03.交易对手ID -- 根据业务李佶阳提供的"取ECIF系统ECIF_M_CI_ORG.CUST_ID",实际上就是集市的T.CUST_ID
   NVL(T.CONT_PARTY_NAME,C.CUST_NAM), -- 04.交易对手名称 -- 根据业务桑铭蔚要求空值部分用交易对手ID关联 2.0 BUG_10028620
   T.JYDSZH,                    -- 05.交易对手账号
   T.JYDSHH,                    -- 06.交易对手账号行号
   TO_CHAR(TO_DATE(T.ISSU_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 07.签约日期
   TO_CHAR(TO_DATE(T.INT_ST_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 08.生效日期
   '04',                    -- 09.收益类型  -- 默认04
   TO_CHAR(TO_DATE(T.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 10.到期日期
   T.CURR_CD,               -- 11.协议币种
  -- T.FACE_VAL,              -- 12.协议金额
   T.FST_CRE_AMT,             -- 12.协议金额 -- [20250513][狄家卉][JLBA202504060003][吴大为]: 交易方向是买入的，第一笔交易金额且大于0即入账金额
   NULL,                    -- 13.保证金账号 -- 默认为空
   '0',                     -- 14.保证金比例 -- 默认为空，按发文没有保证金默认为0
   NULL,                    -- 15.保证金币种 -- 默认为空
   '0',                     -- 16.保证金金额 -- 默认为空，按发文没有保证金默认为0
   case 
     when T.ACCOUNTANT_TYPE IN ('1','2') then
       '01' -- 市值法
     when T.ACCOUNTANT_TYPE = '3' then
       '02' -- 成本法
   end ,                    -- 17.估值方法
   -- T1.DATE_SOURCESD,        -- 18.资金来源
   '01',                    -- 18.资金来源 -- 默认01-表内资金
   -- T.TZGLFS,                -- 19.投资管理方式 -- 康星新增字段，待数仓接入
   '01'                    , -- 19.投资管理方式  -- 01-自主管理  -- 参照8.8
   T.CDS_NO ,               -- 20.投资标的ID
   T.INT_RAT,               -- 21.合同执行利率
   '0',                     -- 22.含权标识 -- 默认0-否
   NULL,                    -- 23.重点产业标识 -- 默认为空
   -- T.JBYG_ID,               -- 24.经办员工ID
   F.GB_CODE,  -- 24.经办员工ID
   nvl(F1.GB_CODE,T.SZYG_ID),  -- 25.审查员工ID
   nvl(F1.GB_CODE,T.SPYG_ID),  -- 26.审批员工ID
   T.ACCT_STS,              -- 27.协议状态
   '0',                     -- 28.或有负债标识 --默认0-否
   NULL,                    -- 29.备注
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 30.采集日期
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
   T.ORG_NUM                                       , -- 机构号
   '存单投资与发行信息表',
   case 
     when T.ORG_NUM = '009804' then '009804' -- 金融市场部
     when T.ORG_NUM = '009820' then '009820' -- 同业金融部
   end   -- 业务条线
FROM SMTMODS.L_ACCT_FUND_CDS_BAL T -- 存单投资与发行信息表
LEFT JOIN SMTMODS.L_CUST_C C
        ON T.CUST_ID = C.CUST_ID
        AND C.DATA_DATE = I_DATE
LEFT JOIN (select CUST_ID,CUST_NAM from (-- 金融市场部桑铭蔚  2.0 BUG_10028526 部分交易对手ID为空，通过名称关联 
   select CUST_ID,CUST_NAM,ROW_NUMBER() OVER(partition by CUST_NAM order by OPEN_DT DESC)RN from SMTMODS.L_CUST_C where DATA_DATE = I_DATE)C1 where C1.RN=1)C1
        ON T.CONT_PARTY_NAME = C1.CUST_NAM
LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON T.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
LEFT JOIN m_dict_codetable F
       ON T.JBYG_ID = F.L_CODE
       AND F.l_code_table_code ='C0013'
LEFT JOIN m_dict_codetable F1
       ON T.SPYG_ID = F1.L_CODE
       AND F1.l_code_table_code ='C0013'
LEFT JOIN m_dict_codetable F2
       ON T.SZYG_ID = F2.L_CODE
       AND F2.l_code_table_code ='C0013'       
LEFT JOIN SMTMODS.L_ACCT_FUND_CDS_BAL T1
       ON T.ACCT_NUM || T.CDS_NO = T1.ACCT_NUM || T1.CDS_NO
       AND T1.DATA_DATE = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') -1 ,'YYYYMMDD')
WHERE T.DATA_DATE = I_DATE
AND T.PRODUCT_PROP='A'
-- and T.FACE_VAL<>'0' -- [20250415][姜俐锋][JLBA202502210009][吴大为]:同步9.2取数条件
-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
AND ((NVL(T.ACCT_STS,'#')<>'03' AND (T.MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101' OR T.MATURITY_DT IS null)) or (T.ACCT_STS='03' and T1.ACCT_STS<>'03')); -- 范围与8.8、7.7、4.3同步

	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
	


  #4.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '财管数据插入';
	INSERT  INTO T_6_21  (
   F210001, -- 01.协议ID
   F210002, -- 02.机构ID
   F210003, -- 03.交易对手ID
   F210004, -- 04.交易对手名称
   F210005, -- 05.交易对手账号
   F210006, -- 06.交易对手账号行号
   F210007, -- 07.签约日期
   F210008, -- 08.生效日期
   F210009, -- 09.收益类型
   F210010, -- 10.到期日期
   F210011, -- 11.协议币种
   F210012, -- 12.协议金额
   F210013, -- 13.保证金账号
   F210014, -- 14.保证金比例
   F210015, -- 15.保证金币种
   F210016, -- 16.保证金金额
   F210017, -- 17.估值方法
   F210018, -- 18.资金来源
   F210019, -- 19.投资管理方式
   F210020, -- 20.投资标的ID
   F210021, -- 21.合同执行利率
   F210022, -- 22.含权标识
   F210023, -- 23.重点产业标识
   F210024, -- 24.经办员工ID
   F210025, -- 25.审查员工ID
   F210026, -- 26.审批员工ID
   F210027, -- 27.协议状态
   F210028, -- 28.或有负债标识
   F210029, -- 29.备注
   F210030, -- 30.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DEPARTMENT_ID , -- 业务条线
   DIS_DEPT
   
) select 
   F210001, -- 01.协议ID
   F210002, -- 02.机构ID
   F210003, -- 03.交易对手ID
   F210004, -- 04.交易对手名称
   F210005, -- 05.交易对手账号
   F210006, -- 06.交易对手账号行号
   F210007, -- 07.签约日期
   F210008, -- 08.生效日期
   F210009, -- 09.收益类型
   F210010, -- 10.到期日期
   F210011, -- 11.协议币种
   F210012, -- 12.协议金额
   F210013, -- 13.保证金账号
   F210014, -- 14.保证金比例
   F210015, -- 15.保证金币种
   F210016, -- 16.保证金金额
   F210017, -- 17.估值方法
   F210018, -- 18.资金来源
   F210019, -- 19.投资管理方式
   F210020, -- 20.投资标的ID
   F210021, -- 21.合同执行利率
   F210022, -- 22.含权标识
   F210023, -- 23.重点产业标识
   F210024, -- 24.经办员工ID
   F210025, -- 25.审查员工ID
   F210026, -- 26.审批员工ID
   F210027, -- 27.协议状态
   F210028, -- 28.或有负债标识
   F210029, -- 29.备注
   F210030, -- 30.采集日期
    TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 装入数据日期
   '990000'   , -- 机构号
   CASE WHEN  ywxt = '总行机关战略投资管理部' THEN  '0098ZT'
	    WHEN  ywxt = '总行机关运营管理部' THEN  '009801'
    END ,   -- 业务条线
    '财管'
from smtmods.RSF_GQ_INVESTMENT_AGREEMENT t where  t.DATA_DATE=I_DATE; 
commit ;

	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	


  #5.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = 'RPA数据插入';

-- RPA 债转股
INSERT  INTO T_6_21  (
   F210001, -- 01.协议ID
   F210002, -- 02.机构ID
   F210003, -- 03.交易对手ID
   F210004, -- 04.交易对手名称
   F210005, -- 05.交易对手账号
   F210006, -- 06.交易对手账号行号
   F210007, -- 07.签约日期
   F210008, -- 08.生效日期
   F210009, -- 09.收益类型
   F210010, -- 10.到期日期
   F210011, -- 11.协议币种
   F210012, -- 12.协议金额
   F210013, -- 13.保证金账号
   F210014, -- 14.保证金比例
   F210015, -- 15.保证金币种
   F210016, -- 16.保证金金额
   F210017, -- 17.估值方法
   F210018, -- 18.资金来源
   F210019, -- 19.投资管理方式
   F210020, -- 20.投资标的ID
   F210021, -- 21.合同执行利率
   F210022, -- 22.含权标识
   F210023, -- 23.重点产业标识
   F210024, -- 24.经办员工ID
   F210025, -- 25.审查员工ID
   F210026, -- 26.审批员工ID
   F210027, -- 27.协议状态
   F210028, -- 28.或有负债标识
   F210029, -- 29.备注
   F210030, -- 30.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号 
   DEPARTMENT_ID ,  -- 业务条线
   DIS_DEPT
) 
SELECT 
   F210001, -- 01.协议ID
   F210002, -- 02.机构ID
   F210003, -- 03.交易对手ID
   F210004, -- 04.交易对手名称
   F210005, -- 05.交易对手账号
   F210006, -- 06.交易对手账号行号
   F210007, -- 07.签约日期
   F210008, -- 08.生效日期
   SUBSTR ( F210009,INSTR(F210009,'[',1,1) + 1 , INSTR(F210009, ']',1 ) -INSTR(F210009,'[',1,1) - 1 ) AS F210009, -- 09.收益类型
   F210010, -- 10.到期日期
   SUBSTR ( F210011,INSTR(F210011,'[',1,1) + 1 , INSTR(F210011, ']',1 ) -INSTR(F210011,'[',1,1) - 1 ) AS F210011, -- 11.协议币种
   TO_NUMBER(REPLACE(F210012,',','')) AS F210012, -- 12.协议金额
   F210013, -- 13.保证金账号
   F210014, -- 14.保证金比例
   SUBSTR ( F210015,INSTR(F210015,'[',1,1) + 1 , INSTR(F210015, ']',1 ) -INSTR(F210015,'[',1,1) - 1 ) AS F210015, -- 15.保证金币种
   TO_NUMBER(REPLACE(F210016,',','')) AS F210016, -- 16.保证金金额
   SUBSTR ( F210017,INSTR(F210017,'[',1,1) + 1 , INSTR(F210017, ']',1 ) -INSTR(F210017,'[',1,1) - 1 ) AS F210017, -- 17.估值方法
   SUBSTR ( F210018,INSTR(F210018,'[',1,1) + 1 , INSTR(F210018, ']',1 ) -INSTR(F210018,'[',1,1) - 1 ) AS F210018, -- 18.资金来源
   SUBSTR ( F210019,INSTR(F210019,'[',1,1) + 1 , INSTR(F210019, ']',1 ) -INSTR(F210019,'[',1,1) - 1 ) AS F210019, -- 19.投资管理方式
   F210020, -- 20.投资标的ID
   TO_NUMBER(F210021) AS F210021, -- 21.合同执行利率
   SUBSTR ( F210022,INSTR(F210022,'[',1,1) + 1 , INSTR(F210022, ']',1 ) -INSTR(F210022,'[',1,1) - 1 ) AS F210022, -- 22.含权标识
   F210023, -- 23.重点产业标识
   F210024, -- 24.经办员工ID
   F210025, -- 25.审查员工ID
   F210026, -- 26.审批员工ID
   SUBSTR ( F210027,INSTR(F210027,'[',1,1) + 1 , INSTR(F210027, ']',1 ) -INSTR(F210027,'[',1,1) - 1 ) AS F210027, -- 27.协议状态
   SUBSTR ( F210028,INSTR(F210028,'[',1,1) + 1 , INSTR(F210028, ']',1 ) -INSTR(F210028,'[',1,1) - 1 ) AS F210028, -- 28.或有负债标识
   F210029, -- 29.备注
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS CJRQ, -- 30.采集日期
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS SJRQ, -- 装入数据日期
   '990000'   , -- 机构号 
   SUBSTR ( DEPARTMENT_ID,INSTR(DEPARTMENT_ID,'[',1,1) + 1 , INSTR(DEPARTMENT_ID, ']',1 ) -INSTR(DEPARTMENT_ID,'[',1,1) - 1 ) AS DEPARTMENT_ID ,      -- 业务条线
   '债转股'
  FROM ybt_datacore.RPAJ_6_21_TZXY A
 WHERE A.DATA_DATE =I_DATE;
 commit;

	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	
	INSERT  INTO T_6_21  (
   F210001, -- 01.协议ID
   F210002, -- 02.机构ID
   F210003, -- 03.交易对手ID
   F210004, -- 04.交易对手名称
   F210005, -- 05.交易对手账号
   F210006, -- 06.交易对手账号行号
   F210007, -- 07.签约日期
   F210008, -- 08.生效日期
   F210009, -- 09.收益类型
   F210010, -- 10.到期日期
   F210011, -- 11.协议币种
   F210012, -- 12.协议金额
   F210013, -- 13.保证金账号
   F210014, -- 14.保证金比例
   F210015, -- 15.保证金币种
   F210016, -- 16.保证金金额
   F210017, -- 17.估值方法
   F210018, -- 18.资金来源
   F210019, -- 19.投资管理方式
   F210020, -- 20.投资标的ID
   F210021, -- 21.合同执行利率
   F210022, -- 22.含权标识
   F210023, -- 23.重点产业标识
   F210024, -- 24.经办员工ID
   F210025, -- 25.审查员工ID
   F210026, -- 26.审批员工ID
   F210027, -- 27.协议状态
   F210028, -- 28.或有负债标识
   F210029, -- 29.备注
   F210030, -- 30.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号 
   DEPARTMENT_ID , -- 业务条线
   DIS_DEPT
 )
  SELECT 
   F210001, -- 01.协议ID
   F210002, -- 02.机构ID
   F210003, -- 03.交易对手ID
   F210004, -- 04.交易对手名称
   F210005, -- 05.交易对手账号
   F210006, -- 06.交易对手账号行号
   F210007, -- 07.签约日期
   F210008, -- 08.生效日期
  SUBSTR ( F210009,INSTR(F210009,'[',1,1) + 1 , INSTR(F210009, ']',1 ) -INSTR(F210009,'[',1,1) - 1 ) AS F210009, -- 09.收益类型
   F210010, -- 10.到期日期
   SUBSTR ( F210011,INSTR(F210011,'[',1,1) + 1 , INSTR(F210011, ']',1 ) -INSTR(F210011,'[',1,1) - 1 ) AS F210011, -- 11.协议币种
   TO_NUMBER(REPLACE(F210012,',','')) AS F210012, -- 12.协议金额
   F210013, -- 13.保证金账号
   F210014, -- 14.保证金比例
   SUBSTR ( F210015,INSTR(F210015,'[',1,1) + 1 , INSTR(F210015, ']',1 ) -INSTR(F210015,'[',1,1) - 1 ) AS F210015, -- 15.保证金币种
   TO_NUMBER(REPLACE(F210016,',','')) AS F210016, -- 16.保证金金额
   SUBSTR ( F210017,INSTR(F210017,'[',1,1) + 1 , INSTR(F210017, ']',1 ) -INSTR(F210017,'[',1,1) - 1 ) AS F210017, -- 17.估值方法
   SUBSTR ( F210018,INSTR(F210018,'[',1,1) + 1 , INSTR(F210018, ']',1 ) -INSTR(F210018,'[',1,1) - 1 ) AS F210018, -- 18.资金来源
   SUBSTR ( F210019,INSTR(F210019,'[',1,1) + 1 , INSTR(F210019, ']',1 ) -INSTR(F210019,'[',1,1) - 1 ) AS F210019, -- 19.投资管理方式
   F210020, -- 20.投资标的ID
   TO_NUMBER(F210021) AS F210021, -- 21.合同执行利率
   SUBSTR ( F210022,INSTR(F210022,'[',1,1) + 1 , INSTR(F210022, ']',1 ) -INSTR(F210022,'[',1,1) - 1 ) AS F210022, -- 22.含权标识
   F210023, -- 23.重点产业标识
   F210024, -- 24.经办员工ID
   F210025, -- 25.审查员工ID
   F210026, -- 26.审批员工ID
   SUBSTR ( F210027,INSTR(F210027,'[',1,1) + 1 , INSTR(F210027, ']',1 ) -INSTR(F210027,'[',1,1) - 1 ) AS F210027, -- 27.协议状态
   SUBSTR ( F210028,INSTR(F210028,'[',1,1) + 1 , INSTR(F210028, ']',1 ) -INSTR(F210028,'[',1,1) - 1 ) AS F210028, -- 28.或有负债标识
   F210029, -- 29.备注
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS CJRQ , -- 30.采集日期
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS CJRQ , -- 装入数据日期
   '009806'   , -- 机构号 
   SUBSTR ( F210031,INSTR(F210031,'[',1,1) + 1 , INSTR(F210031, ']',1 ) -INSTR(F210031,'[',1,1) - 1 ) AS F210031,  -- 业务条线
   '非标投资'
 FROM ybt_datacore.INTM_TZXYXX 
 WHERE DATA_DATE = I_DATE;
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

