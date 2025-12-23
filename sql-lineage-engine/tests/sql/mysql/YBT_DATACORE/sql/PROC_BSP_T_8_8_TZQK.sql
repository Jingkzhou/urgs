DROP Procedure IF EXISTS `PROC_BSP_T_8_8_TZQK` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_8_8_TZQK"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：投资情况
      程序功能  ：加工投资情况
      目标表：T_8_8
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	 --  JLBA202411070004_关于一表通监管数据报送系统修改逻辑的需求 20241212
	 /*需求编号：JLBA202505270010   上线日期：20250729，修改人：姜俐锋，提出人：吴大为 关于一表通监管数据报送系统新增投资业务指标的需求*/	
      /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
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
	SET P_PROC_NAME = 'PROC_BSP_T_8_8_TZQK';
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
	
	DELETE FROM T_8_8 WHERE H080017 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ;									
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
 
-- 1、投资业务信息表
      -- 细类：
      -- 私募通过L_AGRE_OTHER_SUBJECT_INFO特殊目的载体产品分类判断 
      -- 其中05理财产品投资映射到细类对应的是0502	非保本理财   映射为1601 
      -- G31 按类别	2.1长期股权投资
      -- 2.2上市股票（剔除已计入2.1的部分）
      -- 2.3非上市股权（剔除已计入2.1的部分）
      -- 2.4其他权益类投资
      -- 属于权益类投资，009820同业金融部有股权投资，目前没有接入模型 
INSERT INTO T_8_8
 (
   H080001    , -- 01 '投资标的ID'
   H080002    , -- 02 '投资产品名称'
   H080003    , -- 03 '交易机构ID'
   H080004    , -- 04 '协议ID'
   H080005    , -- 05 '交易账号'
   H080006    , -- 06 '账户类型'
   H080007    , -- 07 '产品ID'
   H080008    , -- 08 '科目ID'
   H080009    , -- 09 '科目名称'
   H080010    , -- 10 '投资管理方式'
   H080011    , -- 11 '投资余额'
   H080012    , -- 12 '投资标的币种'
   H080013    , -- 13 '本期投资收益'
   H080014    , -- 14 '累计投资收益'
   H080015    , -- 15 '持有成本'
   H080016    , -- 16 '担保协议ID'	
   H080018    , -- 18 '自营业务大类'
   H080019    , -- 19 '自营业务小类' 
   H080017    , -- 17 '采集日期'
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DIS_DEPT      ,
   DEPARTMENT_ID ,-- 业务条线
   H080020    , -- 20 '基础资产逾期金额'
   H080021    , -- 21 '资产会计计量方式类别'
   H080022    , -- 22 '持有非底层资产产生的间接负债余额'
   CUSTOMER_TYPE_FBZZQZCBZ  ,-- 	非标准债权资产标志   -- [20250729][姜俐锋][JLBA202505270010][吴大为]:新增投资重点指标判断字段
   CUSTOMER_TYPE_YDFBBS     ,-- 	异地非标标识   -- [20250729][姜俐锋][JLBA202505270010][吴大为]:新增投资重点指标判断字段
   CUSTOMER_TYPE_DVO1ZE     ,-- 	DV01总额   -- [20250729][姜俐锋][JLBA202505270010][吴大为]:新增投资重点指标判断字段
   CUSTOMER_TYPE_JQZE       ,-- 	久期总额   -- [20250729][姜俐锋][JLBA202505270010][吴大为]:新增投资重点指标判断字段
   CUSTOMER_TYPE_JQZE2       ,-- 	久期总额   -- [20250729][姜俐锋][JLBA202505270010][吴大为]:新增投资重点指标判断字段
   CUSTOMER_TYPE_DFZFRZ
 ) 

 SELECT 
      T.SUBJECT_CD           AS H080001 , -- 01 '投资标的ID'
      NVL(A.STOCK_NAM,B.GL_CD_NAME) AS H080002, -- 02 '投资产品名称' -- 参考EAST
      ORG.ORG_ID             AS H080003 , -- 03 '交易机构ID'
      T.ACCT_NUM||T.REF_NUM  AS H080004 , -- 04 '协议ID'  -- 与6.21同步
      T.ACCT_NUM||T.REF_NUM  AS H080005 , -- 05 '交易账号' -- 与4.3的D030002一致，4.3的D030002要求唯一，所以拼接
      CASE WHEN T.BOOK_TYPE='1' THEN '02' -- 交易账户
           WHEN T.BOOK_TYPE='2' THEN '01' -- 银行账户
           END               AS H080006 , -- 06 '账户类型'
      T.SUBJECT_CD           AS H080007 , -- 07 '产品ID'
      T.GL_ITEM_CODE         AS H080008 , -- 08 '科目ID'
      B.GL_CD_NAME           AS H080009 , -- 09 '科目名称' 
      CASE WHEN T.ORG_NUM ='009804' THEN  CASE WHEN T.GL_ITEM_CODE IN ('15010201') THEN '02' -- 委托管理
                                               ELSE '01' -- 自主管理
                                               END
           WHEN T.ORG_NUM ='009820' THEN  CASE WHEN T.GL_ITEM_CODE IN ('15010201') THEN '01' -- 自主管理
                                               WHEN T.GL_ITEM_CODE IN ('11010302','11010303') THEN '02' -- 委托管理
                                               END 
           END               AS H080010 , -- 10 '投资管理方式'
--       CASE WHEN T.INVEST_TYP = '01' OR (T.ACCOUNTANT_TYPE = '1' AND T.GL_ITEM_CODE = '11010303') THEN T.FACE_VAL + NVL(T.MK_VAL,0)   -- MODI BY DJH 20240715  (1)投资业务品种: 01基金投资     (2)委外投资取账户类型是FVTPL的且科目为11010303 取持有仓位+公允价值 
--            WHEN (T.ACCOUNTANT_TYPE = '3' AND C.SUBJECT_CD IS NOT NULL) OR  T.ORG_NUM='009817' THEN T.FACE_VAL  -- MODI BY DJH 20240715  所有AC账户（去掉债券部分）  + 投行
--            ELSE T.PRINCIPAL_BALANCE  -- 债券取剩余本金 
--            END               AS H080011 , -- 11 '投资余额'  
      CASE WHEN T.INVEST_TYP = '01' OR ( (T.ACCOUNTANT_TYPE = '1' OR (T.DATE_SOURCESD ='非标投资' AND T.ACCOUNTANT_TYPE IS NULL) )AND T.GL_ITEM_CODE = '11010303') THEN T.FACE_VAL + NVL(T.MK_VAL,0)   -- MODI BY DJH 20240715  (1)投资业务品种: 01基金投资     (2)委外投资取账户类型是FVTPL的且科目为11010303 取持有仓位+公允价值 
           WHEN (T.ACCOUNTANT_TYPE = '3' AND C.SUBJECT_CD IS NOT NULL) OR  T.ORG_NUM='009817' THEN T.FACE_VAL  -- MODI BY DJH 20240715  所有AC账户（去掉债券部分）  + 投行
           ELSE T.PRINCIPAL_BALANCE  -- 债券取剩余本金 
           END   AS H080011 , -- 11 '投资余额'  
      T.CURR_CD              AS H080012 , -- 12 '投资标的币种'
      NVL(T.THISMONTH_DIVIDEND_INTEREST,0) AS H080013 , -- 13 '本期投资收益'
      NVL(T.TOTAL_INCOME,0)  AS H080014 , -- 14 '累计投资收益'
      CASE WHEN T.ACCOUNTANT_TYPE IN ('2','3') THEN NVL(T.ACCT_BAL,0) 
           WHEN T.ACCOUNTANT_TYPE ='1' THEN NVL(T.CYCB,0)
           END               AS H080015 , -- 15 '持有成本'  -- 新增字段 009804刘洋口径：持有至到期和可供出售金融资产，取债券投资明细表中的持有仓位；交易性金融资产取债券投资明细表中的净价成本
      NULL                   AS H080016 , -- 16 '担保协议ID'  -- 经同业金融部确认，默认空值
      CASE WHEN T.INVEST_TYP IN ('00') THEN '12' -- 债券投资
           WHEN T.INVEST_TYP IN ('04','05','12') THEN '16' -- 资产管理产品
           WHEN T.INVEST_TYP IN ('01') THEN '14' -- 公募基金投资
           WHEN T.INVEST_TYP IN ('06') THEN '13' -- 权益类投资
           ELSE '17' -- 其他
           END               AS H080018 , -- 18 '自营业务大类'
      CASE WHEN T.INVEST_TYP = '00' AND A.STOCK_PRO_TYPE = 'A' AND A.IS_STOCK_ASSET = 'N' AND A.ISSU_ORG = 'A01' THEN '12010' -- 国债
           WHEN T.INVEST_TYP = '00' AND A.STOCK_PRO_TYPE = 'A' AND A.IS_STOCK_ASSET = 'N' AND A.ISSU_ORG = 'A02' THEN '12020' -- 地方政府债
           WHEN T.INVEST_TYP = '00' AND A.STOCK_PRO_TYPE = 'B' AND A.IS_STOCK_ASSET = 'N' THEN '12030' -- 央票
           WHEN T.INVEST_TYP = '00' AND A.STOCK_PRO_TYPE = 'A' AND A.IS_STOCK_ASSET = 'N' AND A.ISSU_ORG LIKE 'C%' THEN '12040' -- 政府支持机构债
           WHEN T.INVEST_TYP = '00' AND A.STOCK_PRO_TYPE LIKE 'C%' AND A.IS_STOCK_ASSET = 'N' AND A.ISSU_ORG = 'D02' THEN '12050' -- 政策性金融债
           WHEN T.INVEST_TYP = '00' AND A.STOCK_PRO_TYPE LIKE 'C%' AND A.IS_STOCK_ASSET = 'N' AND A.ISSU_ORG <>'D02' THEN '12060' -- 商业性金融债
           WHEN T.INVEST_TYP = '00' AND A.IS_STOCK_ASSET = 'N' AND A.STOCK_PRO_TYPE LIKE 'D%' THEN '12070' -- 非金融企业债券
           WHEN T.INVEST_TYP = '00' AND A.IS_STOCK_ASSET = 'Y' AND A.STOCK_ASSET_TYPE = 'A01' THEN '12080' -- 资产支持证券（信贷资产证券化）
           WHEN T.INVEST_TYP = '00' AND A.IS_STOCK_ASSET = 'Y' AND A.STOCK_ASSET_TYPE = 'A02' THEN '12090' -- 资产支持证券（交易所资产支持证券）
           WHEN T.INVEST_TYP = '00' AND A.IS_STOCK_ASSET = 'Y' AND A.STOCK_ASSET_TYPE = 'A03' THEN '12100' -- 资产支持证券（资产支持票据）
           WHEN T.INVEST_TYP = '00' AND A.STOCK_PRO_TYPE LIKE 'F%' AND A.IS_STOCK_ASSET = 'N' THEN '12110' -- 外国债券
           WHEN T.INVEST_TYP = '00' AND A.IS_STOCK_ASSET = 'Y' AND A.STOCK_ASSET_TYPE NOT IN ('A01','A02','A03') THEN '12120' -- 其他债券投资
           WHEN T.INVEST_TYP = '06' THEN '13010' -- 长期股权投资
           WHEN T.INVEST_TYP = '02' THEN '13020' -- 上市股票
           WHEN T.INVEST_TYP = '10' THEN '13030' -- 非上市股权
           WHEN T.EQUITY_FLAG = 'Y' AND T.INVEST_TYP NOT IN ('02','06','10') THEN '13040' -- 其他权益类投资
           WHEN T.INVEST_TYP LIKE '01%' AND C.SUBJECT_PRO_TYPE = '0102' THEN '14010' -- 债券基金
           WHEN T.INVEST_TYP LIKE '01%' AND C.SUBJECT_PRO_TYPE = '0103' THEN '14020' -- 货币市场基金
           WHEN T.INVEST_TYP LIKE '01%' AND C.FUNDS_TYPE = 'A03' THEN '14030' -- 股票基金
           WHEN T.INVEST_TYP LIKE '01%' AND C.FUNDS_TYPE = 'A04' THEN '14040' -- 基金中基金
           WHEN T.INVEST_TYP LIKE '01%' AND C.FUNDS_TYPE = 'A05' THEN '14050' -- 混合基金
           WHEN T.INVEST_TYP LIKE '01%' AND C.FUNDS_TYPE = 'A99' THEN '14060' -- 其他公募基金投资
           WHEN T.INVEST_TYP LIKE '01%' AND C.FUNDS_TYPE = 'B01' THEN '15010' -- 私募证券投资基金
           WHEN T.INVEST_TYP LIKE '01%' AND C.FUNDS_TYPE = 'B02' THEN '15020' -- 私募股权投资基金
           WHEN T.INVEST_TYP LIKE '01%' AND C.FUNDS_TYPE = 'B03' THEN '15030' -- 私募创业投资基金
           WHEN T.INVEST_TYP LIKE '01%' AND C.FUNDS_TYPE = 'B99' THEN '15040' -- 其他私募基金投资
           WHEN T.INVEST_TYP IN ('04','05','12') AND C.SPV_PRODUCT_TYPE = 'A' THEN '16011' -- 非保本理财投资
           WHEN T.INVEST_TYP IN ('04','05','12') AND C.SPV_PRODUCT_TYPE = 'B' AND T.ACCT_NUM IN ('N000310000025496','N000310000025495') THEN '16031' -- 信托产品（财产权信托）2笔中信信托特殊处理
           WHEN T.INVEST_TYP IN ('04','05','12') AND C.SPV_PRODUCT_TYPE = 'B' AND T.ACCT_NUM NOT IN ('N000310000025496','N000310000025495') THEN '16021' -- 信托产品（资金信托）
           WHEN T.INVEST_TYP IN ('04','05','12') AND C.SPV_PRODUCT_TYPE IN ('C','D','E') THEN '16041' -- 证券业资产管理产品（不含公募基金）              
           WHEN T.INVEST_TYP IN ('04','05','12') AND C.SPV_PRODUCT_TYPE = 'F' THEN '16051' -- 保险业资产管理产品
           WHEN T.INVEST_TYP IN ('04','05','12') AND C.SPV_PRODUCT_TYPE IN ('I','Z') THEN '16061' -- 其他资产管理产品投资
           WHEN T.OTHER_DEBT_TYPE = 'A' THEN '17010' -- 其他债权融资（其他交易平台债权融资工具）
           WHEN T.OTHER_DEBT_TYPE = 'B' THEN '17020' -- 其他债权融资（非标转标资产）
           WHEN T.INVEST_TYP IN ('09','99') AND (SUBSTR(C.SUBJECT_PRO_TYPE,1,2) = '09' OR (C.SUBJECT_PRO_TYPE = '99' AND C.SUBJECT_PRO_TYPE <>'9999')) AND T.OTHER_DEBT_TYPE IS NULL THEN '17030' -- 其他投资
           ELSE '17030' -- 其他投资
           END               AS H080019 , -- 19 '自营业务小类' 
      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H080017 , -- 17 '采集日期'
      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE , -- 装入数据日期
      T.ORG_NUM                                        AS DIS_BANK_ID , -- 机构号
      '投资'                                           AS DIS_DEPT ,
      CASE WHEN T.ORG_NUM = '009804' THEN '009804' -- 金融市场部
           WHEN T.ORG_NUM = '009820' THEN '009820' -- 同业金融部
           END                                         AS DEPARTMENT_ID ,   -- 业务条线
      T.OD_LOAN_ACCT_BAL                               AS H080020 , -- 20 '基础资产逾期金额'
      CASE WHEN T.FIN_ASSETS_TYPE = 'A' THEN '01' -- 以摊余成本计量（AC）
           WHEN T.FIN_ASSETS_TYPE = 'C' THEN '02' -- 以公允价值计量且其变动计入当期损益（FVTPL）
           WHEN T.FIN_ASSETS_TYPE = 'B' THEN '03' -- 以公允价值计量且其变动计入其他综合收益（FVTOCI）
           END                                         AS H080021 ,     -- 21 '资产会计计量方式类别'
      0                                                AS H080022 ,     -- 22 '持有非底层资产产生的间接负债余额'
      NVL(T.UN_STD_CLAIM_AST_FLAG,'N')                 AS CUSTOMER_TYPE_FBZZQZCBZ ,   -- 非标准债权资产标志  -- [20250729][姜俐锋][JLBA202505270010][吴大为]:新增投资重点指标判断字段
      NVL(T.CROSS_REGIONAL_AST_FLAG,'N')               AS CUSTOMER_TYPE_YDFBBS ,      -- 异地非标标识   -- [20250729][姜俐锋][JLBA202505270010][吴大为]:新增投资重点指标判断字段
      T.DV01                                           AS CUSTOMER_TYPE_DVO1ZE ,      -- DV01总额   -- [20250729][姜俐锋][JLBA202505270010][吴大为]:新增投资重点指标判断字段
      D.DURAN1                                         AS CUSTOMER_TYPE_JQZE   ,      -- 久期总额   -- [20250729][姜俐锋][JLBA202505270010][吴大为]:新增投资重点指标判断字段
      D.DURAN2                                         AS CUSTOMER_TYPE_JQZE2  ,      -- 久期总额   -- [20250729][姜俐锋][JLBA202505270010][吴大为]:新增投资重点指标判断字段
      T.DFZFRZPTBS                                     AS CUSTOMER_TYPE_DFZFRZ        -- 地方政府融资平台标识   -- [20250729][姜俐锋][JLBA202505270010][吴大为]:新增投资重点指标判断字段
      FROM SMTMODS.L_ACCT_FUND_INVEST T  -- 投资业务信息表
 LEFT JOIN SMTMODS.L_AGRE_BOND_INFO A -- 债券信息表
   ON T.SUBJECT_CD = A.STOCK_CD
  AND A.DATA_DATE = I_DATE
 LEFT JOIN SMTMODS.L_FINA_INNER B  -- 内部科目对照表
   ON T.GL_ITEM_CODE = B.STAT_SUB_NUM
  AND T.ORG_NUM = B.ORG_NUM
  AND B.DATA_DATE = I_DATE
 LEFT JOIN SMTMODS.L_AGRE_OTHER_SUBJECT_INFO C -- 其他标的物信息表
   ON T.SUBJECT_CD = C.SUBJECT_CD
  AND C.DATA_DATE = I_DATE
 LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
   ON T.ORG_NUM = ORG.ORG_NUM
  AND ORG.DATA_DATE = I_DATE
 LEFT JOIN (SELECT  A.BOND_CD ,sum(OVRFLWG_PRC_CORR_DURAN*OVRFLWG_FULL_PRC_MKT_VAL)  AS DURAN1, sum(OVRFLWG_FULL_PRC_MKT_VAL) AS DURAN2
              FROM SMTMODS.L_TRAN_EV_OVRFLWG_PRFT_LOSS A -- 折溢摊损益表
             WHERE A.DATA_DATE = I_DATE
               AND A.TXN_PORTF LIKE '%现券-FVTPL%'
               AND A.TXN_PORTF NOT LIKE '%现券-FVTPL-投组7%'
               AND A.MKT_FOUR  NOT LIKE '%一级市场投资%'
               GROUP BY A.BOND_CD) D       -- [20250729][姜俐锋][JLBA202505270010][吴大为]:用于计算久期总额  （每支债券的折溢摊价格修正久期*折溢摊全价市值）的合计数/上述债券折溢摊全价市值的合计数
   ON A.STOCK_CD = D.BOND_CD
WHERE T.DATA_DATE = I_DATE  -- 范围与6.21、4.3、7.7同步
  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
  AND (T.MATURITY_DATE >= SUBSTR(I_DATE,1,4)||'0101' OR T.FACE_VAL > 0)-- 应同业李佶阳要求，不判断到期日
  AND SUBSTR(T.GL_ITEM_CODE,1,4) IN(-- 避免以后有其他不报送的投资交易进到投资业务信息表，此处框定一下范围
                                   '1101', -- 交易性金融资产
                                   '1501', -- 债权投资
                                   '1503') -- 其他债权投资
--   AND(T.DATE_SOURCESD='债券投资'-- 现券
--       OR (T.GL_ITEM_CODE IN ('11010302','11010303','15010201') AND T.DATE_SOURCESD<>'债券投资'AND T.ORG_NUM='009820') -- 公募基金11010302、私募没有、信托11010303、资管11010303、理财11010303
--       )
   AND(T.DATE_SOURCESD='债券投资'-- 现券
      OR (T.GL_ITEM_CODE IN ('11010302','11010303','15010201') AND T.DATE_SOURCESD<>'债券投资'
   --   AND T.ORG_NUM='009820'
      ) -- 公募基金11010302、私募没有、信托11010303、资管11010303、理财11010303
      ) 
       and  T.ORG_NUM <> '009817'  -- JLBA202507090010 投管数据补录不在此逻辑报送
       ; -- 20241015
-- AND T.DATE_SOURCESD <> '基金投资' -- 按同业(金市没有基金)业务老师要求，6.21不报基金投资，8.8全报，忽略校验报错
-- AND (T.MATURITY_DATE >= I_DATE OR T.MATURITY_DATE IS NULL  or T.FACE_VAL > 0)
-- AND T.INVEST_TYP = '00' -- 债券  不仅是债券，应该取整表
 
      
COMMIT;

-- 2、存单投资与发行信息表
INSERT INTO T_8_8
 ( H080001    , -- 01 '投资标的ID'
   H080002    , -- 02 '投资产品名称'
   H080003    , -- 03 '交易机构ID'
   H080004    , -- 04 '协议ID'
   H080005    , -- 05 '交易账号'
   H080006    , -- 06 '账户类型'
   H080007    , -- 07 '产品ID'
   H080008    , -- 08 '科目ID'
   H080009    , -- 09 '科目名称'
   H080010    , -- 10 '投资管理方式'
   H080011    , -- 11 '投资余额'
   H080012    , -- 12 '投资标的币种'
   H080013    , -- 13 '本期投资收益'
   H080014    , -- 14 '累计投资收益'
   H080015    , -- 15 '持有成本'
   H080016    , -- 16 '担保协议ID'	
   H080018    , -- 18 '自营业务大类'
   H080019    , -- 19 '自营业务小类' 
   H080017    , -- 17 '采集日期'
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DIS_DEPT      ,
   DEPARTMENT_ID , -- 业务条线
   H080020    , -- 20 '基础资产逾期金额'
   H080021    , -- 21 '资产会计计量方式类别'
   H080022      -- 22 '持有非底层资产产生的间接负债余额'
 )
  SELECT 
         T.CDS_NO               AS H080001  , -- 01 '投资标的ID'=
         NVL(A.SUBJECT_NAM,B.GL_CD_NAME) AS H080002 , -- 02 '投资产品名称' -- 参考EAST
         ORG.ORG_ID             AS H080003  , -- 03 '交易机构ID'
         T.ACCT_NUM || T.CDS_NO AS H080004 , -- 04 '协议ID'=
         T.ACCT_NUM || T.CDS_NO AS H080005 , -- 05 '交易账号' 
         CASE WHEN T.BOOK_TYPE='1' THEN '02' -- 交易账户
              WHEN T.BOOK_TYPE='2' THEN '01' -- 银行账户
              END               AS H080006 , -- 06 '账户类型'
         T.CP_ID                AS H080007 , -- 07 '产品ID' -- 新增字段
         T.GL_ITEM_CODE         AS H080008 , -- 08 '科目ID'
         B.GL_CD_NAME           AS H080009 , -- 09 '科目名称'
         '01'                   AS H080010 , -- 10 '投资管理方式' -- 01-自主管理
         T.PRINCIPAL_BALANCE    AS H080011 , -- 11 '投资余额'
         T.CURR_CD              AS H080012 , -- 12 '投资标的币种'
         NVL(T.BQTZSY,0)        AS H080013 , -- 13 '本期投资收益' -- 新增字段
         NVL(T.TOTAL_INCOME,0)  AS H080014 , -- 14 '累计投资收益'
         NVL(T.CYCB,0)          AS H080015 , -- 15 '持有成本'
         NULL                   AS H080016 , -- 16 '担保协议ID'  -- 经同业金融部确认，默认空值
         '09'                   AS H080018 , -- 18 '自营业务大类' -- 09-同业存单
         '09020'                AS H080019 , -- 19 '自营业务小类'  -- 持有 同业存单投资 
         TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H080017 , -- 17 '采集日期'
         TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE , -- 装入数据日期
         T.ORG_NUM                                        AS DIS_BANK_ID , -- 机构号
         '存单投资与发行'        AS DIS_DEPT ,     
         CASE WHEN T.ORG_NUM = '009804' THEN '009804' -- 金融市场部
              WHEN T.ORG_NUM = '009820' THEN '009820' -- 同业金融部
              END               AS DEPARTMENT_ID ,   -- 业务条线
         T.OVERDUE_P            AS H080020 , -- 20 '基础资产逾期金额'
         CASE WHEN T.FIN_ASSETS_TYPE = 'A' THEN '01' -- 以摊余成本计量（AC）
              WHEN T.FIN_ASSETS_TYPE = 'C' THEN '02' -- 以公允价值计量且其变动计入当期损益（FVTPL）
              WHEN T.FIN_ASSETS_TYPE = 'B' THEN '03' -- 以公允价值计量且其变动计入其他综合收益（FVTOCI）
              END               AS H080021 ,     -- 21 '资产会计计量方式类别'
              0                 AS H080022-- 22 '持有非底层资产产生的间接负债余额'
    FROM SMTMODS.L_ACCT_FUND_CDS_BAL T  -- 存单投资与发行信息表
    LEFT JOIN SMTMODS.L_AGRE_OTHER_SUBJECT_INFO A
      ON T.CDS_NO=A.SUBJECT_CD
     AND A.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_FINA_INNER B
      ON T.GL_ITEM_CODE = B.STAT_SUB_NUM
     AND T.ORG_NUM = B.ORG_NUM
     AND B.DATA_DATE = I_DATE
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
      ON T.ORG_NUM = ORG.ORG_NUM
     AND ORG.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_ACCT_FUND_CDS_BAL T1
      ON T.ACCT_NUM || T.CDS_NO = T1.ACCT_NUM || T1.CDS_NO
     AND T1.DATA_DATE = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD') -1 ,'YYYYMMDD')      
   WHERE T.DATA_DATE=I_DATE
     AND T.PRODUCT_PROP = 'A'
     -- AND T.FACE_VAL<>'0' --  JLBA202411070004  20241212
     -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
     AND ((NVL(T.ACCT_STS,'#')<>'03' AND (T.MATURITY_DT >= SUBSTR(I_DATE,1,4)||'0101' OR T.MATURITY_DT IS NULL)) OR (T.ACCT_STS='03' AND T1.ACCT_STS<>'03'));-- 范围与6.21、4.3、7.7同步.
     
     COMMIT;
     
    #4.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '财管数据插入';
 
INSERT INTO T_8_8
 (
   H080001    , -- 01 '投资标的ID'
   H080002    , -- 02 '投资产品名称'
   H080003    , -- 03 '交易机构ID'
   H080004    , -- 04 '协议ID'
   H080005    , -- 05 '交易账号'
   H080006    , -- 06 '账户类型'
   H080007    , -- 07 '产品ID'
   H080008    , -- 08 '科目ID'
   H080009    , -- 09 '科目名称'
   H080010    , -- 10 '投资管理方式'
   H080011    , -- 11 '投资余额'
   H080012    , -- 12 '投资标的币种'
   H080013    , -- 13 '本期投资收益'
   H080014    , -- 14 '累计投资收益'
   H080015    , -- 15 '持有成本'
   H080016    , -- 16 '担保协议ID'	
   H080018    , -- 18 '自营业务大类'
   H080019    , -- 19 '自营业务小类' 
   H080017    , -- 17 '采集日期'
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DEPARTMENT_ID , -- 业务条线
   H080020    , -- 20 '基础资产逾期金额'
   H080021    , -- 21 '资产会计计量方式类别'
   H080022    ,  -- 22 '持有非底层资产产生的间接负债余额'
   H080023	  , -- 23  '绿色融资类型'
   DIS_DEPT )
   
 SELECT  
   H080001    , -- 01 '投资标的ID'
   H080002    , -- 02 '投资产品名称'
   H080003    , -- 03 '交易机构ID'
   H080004    , -- 04 '协议ID'
   H080005    , -- 05 '交易账号'
   H080006    , -- 06 '账户类型'
   H080007    , -- 07 '产品ID'
   H080008    , -- 08 '科目ID'
   H080009    , -- 09 '科目名称'
   H080010    , -- 10 '投资管理方式'
   H080011    , -- 11 '投资余额'
   H080012    , -- 12 '投资标的币种'
   H080013    , -- 13 '本期投资收益'
   H080014    , -- 14 '累计投资收益'
   H080015    , -- 15 '持有成本'
   H080016    , -- 16 '担保协议ID'	
   H080018    , -- 18 '自营业务大类'
   H080019    , -- 19 '自营业务小类' 
   H080017    , -- 17 '采集日期'
    TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 装入数据日期
   '990000'   , -- 机构号
   CASE WHEN  YWXT = '总行机关战略投资管理部' THEN  '0098ZT'
	    WHEN  YWXT = '总行机关运营管理部' THEN  '009801'
    END       , -- 业务条线
   H080020	  ,
   H080021	  ,
   H080022	  ,
   H080023	  , -- 23  '绿色融资类型'
   3
  FROM SMTMODS.RSF_GQ_INVESTMENT_SITUATION T 
 WHERE T.DATA_DATE=I_DATE;
 COMMIT;

	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);		

    #4.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = 'RPA数据插入';

 -- RPA 债转股
 INSERT INTO T_8_8
 (
   H080001    , -- 01 '投资标的ID'
   H080002    , -- 02 '投资产品名称'
   H080003    , -- 03 '交易机构ID'
   H080004    , -- 04 '协议ID'
   H080005    , -- 05 '交易账号'
   H080006    , -- 06 '账户类型'
   H080007    , -- 07 '产品ID'
   H080008    , -- 08 '科目ID'
   H080009    , -- 09 '科目名称'
   H080010    , -- 10 '投资管理方式'
   H080011    , -- 11 '投资余额'
   H080012    , -- 12 '投资标的币种'
   H080013    , -- 13 '本期投资收益'
   H080014    , -- 14 '累计投资收益'
   H080015    , -- 15 '持有成本'
   H080016    , -- 16 '担保协议ID'	
   H080018    , -- 18 '自营业务大类'
   H080019    , -- 19 '自营业务小类' 
   H080017    , -- 17 '采集日期'
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号 
   DEPARTMENT_ID ,-- 业务条线
   H080020    , -- 20 '基础资产逾期金额'
   H080021    , -- 21 '资产会计计量方式类别'
   H080022    , -- 22 '持有非底层资产产生的间接负债余额'
   DIS_DEPT
 )
 SELECT  
   H080001    , -- 01 '投资标的ID'
   H080002    , -- 02 '投资产品名称'
   H080003    , -- 03 '交易机构ID'
   H080004    , -- 04 '协议ID'
   H080005    , -- 05 '交易账号'
   SUBSTR (H080006,INSTR(H080006,'[',1,1) + 1 , INSTR(H080006, ']',1 ) -INSTR(H080006,'[',1,1) - 1 ) AS H080006    , -- 06 '账户类型'
   H080007    , -- 07 '产品ID'
   H080008    , -- 08 '科目ID'
   H080009    , -- 09 '科目名称'
   SUBSTR (H080010,INSTR(H080010,'[',1,1) + 1 , INSTR(H080010, ']',1 ) -INSTR(H080010,'[',1,1) - 1 ) AS H080010    , -- 10 '投资管理方式'
   TO_NUMBER(REPLACE(H080011,',','')) AS H080011    , -- 11 '投资余额'
   SUBSTR (H080012,INSTR(H080012,'[',1,1) + 1 , INSTR(H080012, ']',1 ) -INSTR(H080012,'[',1,1) - 1 ) AS H080012    , -- 12 '投资标的币种'
   TO_NUMBER(REPLACE(H080013,',','')) AS H080013    , -- 13 '本期投资收益'
   TO_NUMBER(REPLACE(H080014,',','')) AS H080014    , -- 14 '累计投资收益'
   TO_NUMBER(REPLACE(H080015,',','')) AS H080015    , -- 15 '持有成本'
   H080016    , -- 16 '担保协议ID'	
   SUBSTR (H080018,INSTR(H080018,'[',1,1) + 1 , INSTR(H080018, ']',1 ) -INSTR(H080018,'[',1,1) - 1 ) AS H080018    , -- 18 '自营业务大类'
   H080019    , -- 19 '自营业务小类' 
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H130023, -- 23 '采集日期'
   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 装入数据日期
   '990000'   , -- 机构号 
   SUBSTR ( DEPARTMENT_ID,INSTR(DEPARTMENT_ID,'[',1,1) + 1 , INSTR(DEPARTMENT_ID, ']',1 ) -INSTR(DEPARTMENT_ID,'[',1,1) - 1 ) AS DEPARTMENT_ID  ,-- 业务条线
   TO_NUMBER(REPLACE(H080020,',','')) AS H080020    , -- 20 '基础资产逾期金额'
   SUBSTR ( H080021,INSTR(H080021,'[',1,1) + 1 , INSTR(H080021, ']',1 ) -INSTR(H080021,'[',1,1) - 1 ) as H080021    , -- 21 '资产会计计量方式类别'
   H080022   , -- 22 '持有非底层资产产生的间接负债余额'
   4
   FROM ybt_datacore.RPAJ_8_8_TZQK A
   WHERE A.DATA_DATE =I_DATE; 
   COMMIT;
	
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);		

	 -- 投管
 INSERT INTO T_8_8
 (
   H080001    , -- 01 '投资标的ID'
   H080002    , -- 02 '投资产品名称'
   H080003    , -- 03 '交易机构ID'
   H080004    , -- 04 '协议ID'
   H080005    , -- 05 '交易账号'
   H080006    , -- 06 '账户类型'
   H080007    , -- 07 '产品ID'
   H080008    , -- 08 '科目ID'
   H080009    , -- 09 '科目名称'
   H080010    , -- 10 '投资管理方式'
   H080011    , -- 11 '投资余额'
   H080012    , -- 12 '投资标的币种'
   H080013    , -- 13 '本期投资收益'
   H080014    , -- 14 '累计投资收益'
   H080015    , -- 15 '持有成本'
   H080016    , -- 16 '担保协议ID'	
   H080018    , -- 18 '自营业务大类'
   H080019    , -- 19 '自营业务小类' 
   H080017    , -- 17 '采集日期'
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号 
   DEPARTMENT_ID ,-- 业务条线
   H080020    , -- 20 '基础资产逾期金额'
   H080021    , -- 21 '资产会计计量方式类别'
   H080022      -- 22 '持有非底层资产产生的间接负债余额'
 )
 SELECT 
   H080001    , -- 01 '投资标的ID'
   H080002    , -- 02 '投资产品名称'
   H080003    , -- 03 '交易机构ID'
   H080004    , -- 04 '协议ID'
   H080005    , -- 05 '交易账号'
   SUBSTR (H080006,INSTR(H080006,'[',1,1) + 1 , INSTR(H080006, ']',1 ) -INSTR(H080006,'[',1,1) - 1 ) AS H080006    , -- 06 '账户类型'
   H080007    , -- 07 '产品ID'
   H080008    , -- 08 '科目ID'
   H080009    , -- 09 '科目名称'
   SUBSTR (H080010,INSTR(H080010,'[',1,1) + 1 , INSTR(H080010, ']',1 ) -INSTR(H080010,'[',1,1) - 1 ) AS H080010    , -- 10 '投资管理方式'
   TO_NUMBER(REPLACE(H080011,',','')) AS H080011    , -- 11 '投资余额'
   SUBSTR (H080012,INSTR(H080012,'[',1,1) + 1 , INSTR(H080012, ']',1 ) -INSTR(H080012,'[',1,1) - 1 ) AS H080012    , -- 12 '投资标的币种'
   TO_NUMBER(REPLACE(H080013,',','')) AS H080013    , -- 13 '本期投资收益'
   TO_NUMBER(REPLACE(H080014,',','')) AS H080014    , -- 14 '累计投资收益'
   TO_NUMBER(REPLACE(H080015,',','')) AS H080015    , -- 15 '持有成本'
   H080016    , -- 16 '担保协议ID'	
   SUBSTR (H080018,INSTR(H080018,'[',1,1) + 1 , INSTR(H080018, ']',1 ) -INSTR(H080018,'[',1,1) - 1 ) AS H080018    , -- 18 '自营业务大类'
   H080019    , -- 19 '自营业务小类' 
   TO_CHAR(TO_DATE( I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS H130023, -- 23 '采集日期'
   TO_CHAR(TO_DATE( I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS DIS_DATA_DATE, -- 装入数据日期
   '009806'   , -- 机构号 
   SUBSTR ( H080024,INSTR(H080024,'[',1,1) + 1 , INSTR(H080024, ']',1 ) -INSTR(H080024,'[',1,1) - 1 ) AS DEPARTMENT_ID  ,-- 业务条线
   TO_NUMBER(REPLACE(H080020,',','')) AS H080020    , -- 20 '基础资产逾期金额'
   SUBSTR ( H080021 ,INSTR(H080021 ,'[',1,1) + 1 , INSTR(H080021 , ']',1 ) -INSTR(H080021 ,'[',1,1) - 1 ) AS H080021  , -- 21 '资产会计计量方式类别'
   H080022      -- 22 '持有非底层资产产生的间接负债余额' 
 FROM ybt_datacore.INTM_TZQK T 
 WHERE T.DATA_DATE=  I_DATE;
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


