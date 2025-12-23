DROP Procedure IF EXISTS `PROC_BSP_T_7_7_TZJY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_7_7_TZJY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN

  /******
      程序名称  ：投资交易
      程序功能  ：加工投资交易
      目标表：T_7_7
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
		-- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116
		/* 需求编号：JLBA202503110010_关于金融市场部一表通7.7投资交易表报送逻辑变更的需求 上线日期：20250427，修改人：姜俐锋，提出人：徐晖 */
	   -- JLBA202505280002 上线日期：2025-06-19，修改人：巴启威  提出人：吴大为  修改原因：因一表通校验问题发现的代码逻辑调整
	   /*需求编号：JLBA202509280009 上线日期：2025-10-28，修改人：巴启威，提出人：吴大为 修改原因：关于一表通监管数据报送系统修改逻辑的需求 */
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
	SET P_PROC_NAME = 'PROC_BSP_T_7_7_TZJY';
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
	
	DELETE FROM T_7_7 WHERE G070032 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
-- 1、投资业务信息表	
	INSERT INTO T_7_7 
 (
  G070001    , -- 01 '交易ID'
  G070002    , -- 02 '交易机构ID'
  G070037    , -- 37 '协议ID'
  G070003    , -- 03 '交易机构名称'
  G070004    , -- 04 '交易账号'
  G070005    , -- 05 '投资标的ID'
  G070006    , -- 06 '交易金额'
  G070007    , -- 07 '交易方向'
  G070008    , -- 08 '币种'
  G070009    , -- 09 '数量'
  G070010    , -- 10 '单位成交净价'
  G070011    , -- 11 '单位成交全价'
  G070012    , -- 12 '资产计量方式'
  G070013    , -- 13 '科目ID'
  G070014    , -- 14 '科目名称'
  G070015    , -- 15 '交易日期'
  G070016    , -- 16 '交易时间'
  G070038    , -- 38 '交易对手ID'
  G070017    , -- 17 '交易对手名称'
  G070018    , -- 18 '交易对手大类'
  G070039    , -- 39 '交易对手小类'
  G070019    , -- 19 '交易对手评级'
  G070020    , -- 20 '交易对手评级机构'
  G070021    , -- 21 '交易对手账号行号'
  G070022    , -- 22 '交易对手账号'
  G070023    , -- 23 '交易对手账号开户行名称'
  G070024    , -- 24 '经办员工ID'
  G070025    , -- 25 '审批员工ID'
  G070026    , -- 26 '行内归属部门'
  G070027    , -- 27 '产品ID'
  G070028    , -- 28 '理财交易登记ID'
  G070029    , -- 29 '行内理财交易ID'
  G070030    , -- 30 '资金流动类型'
  G070033    , -- 33 '自营业务大类'
  G070034    , -- 34 '自营业务小类'
  G070035    , -- 35 '年化利率'
  G070036    , -- 36 '账户类型'  
  G070031    , -- 31 '备注'
  G070032    , -- 32 '采集日期'
  DIS_DATA_DATE , -- 装入数据日期
  DIS_BANK_ID   , -- 机构号
  DIS_DEPT       ,
  DEPARTMENT_ID  -- 业务条线
  
)
       SELECT 
            NVL(T.TXN_NO,T.REF_NUM)       , -- 01 '交易ID'   -- JLBA202411080004 20241217 hmc
            ORG.ORG_ID                    , -- 02 '交易机构ID'
            A.ACCT_NUM || A.REF_NUM       , -- 37 '协议ID'
            F.ORG_NAM                     , -- 03 '交易机构名称'
            A.ACCT_NUM                    , -- 04 '交易账号' 
            A.SUBJECT_CD as G070005       , -- 05 '投资标的ID'  -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
            T.AMOUNT                      , -- 06 '交易金额'
            CASE WHEN T.TRADE_DIRECT = '0' -- 结清（卖出）
                 THEN '02' -- 卖出
                 WHEN T.TRADE_DIRECT = '1' -- 发生（买入）
                 THEN '01' -- 买入
            END                           , -- 07 '交易方向'
            T.CURR_CD                     , -- 08 '币种'
            T.AMOUNT                      , -- 09 '数量'  T.SL  20241231
            T.DWCJJJ                      , -- 10 '单位成交净价'
         -- T.DEAL_PRICE                  , -- 11 '单位成交全价'
            T.AMOUNT                      , -- 11 '单位成交全价' [20251028][巴启威][JLBA202509280009][吴大为]: 单位成交全价取交易金额
            CASE WHEN A.FIN_ASSETS_TYPE = 'A' THEN '01' -- 以摊余成本计量（AC）
     			 WHEN A.FIN_ASSETS_TYPE = 'C' THEN '02' -- 以公允价值计量且其变动计入当期损益（FVTPL）
     			 WHEN A.FIN_ASSETS_TYPE = 'B' THEN '03' -- 以公允价值计量且其变动计入其他综合收益（FVTOCI）
 			     ELSE '00' -- 其他
			END                           , -- 12 '资产计量方式' JLBA202409230003 同业金融部-常城 按照8.8逻辑修改7.7  王金宝
            A.GL_ITEM_CODE                , -- 13 '科目ID' JLBA202409230003 同业金融部-常城 按照8.8逻辑修改7.7  王金宝
            D.GL_CD_NAME                  , -- 14 '科目名称'
            TO_CHAR(TO_DATE(T.TRAN_DT,'YYYYMMDD'),'YYYY-MM-DD')  , -- 15 '交易日期'
            nvl(time_format(T.TRANS_TIME,'%H:%i:%s'),'00:00:00') , -- 16 '交易时间'
		    I.CUST_ID                          , -- 38 '交易对手ID'    -- 系统没有，默认为空   -- 20240926 hmc
            T.CONT_PARTY_NAME             , -- 17 '交易对手名称' -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
            -- 20241024_zhoulp_JLBA202409030008_交易对手大类小类
            CASE WHEN M1.GB_CODE IS NOT NULL THEN M1.GB_CODE
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%银行%' THEN '01' -- [20250619][巴启威][JLBA202505280002][吴大为]：大类增加名称映射。'%银行%' 映射成对应码值01
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%财政部%' THEN '09'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%政府%'   THEN '09'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%财政厅%' THEN '09'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%财政局%' THEN '09'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%理财%公司%' THEN '01'
                 WHEN CE.CORP_PROPTY IN ('0805010100','0805010200') THEN '10' -- 国有企业
                 WHEN CE.CORP_PROPTY IN ('0805040000') THEN '10' -- 集体企业
                 WHEN CE.CORP_PROPTY IN ('0805060000') THEN '10' -- 其他企业
                 WHEN CE.CORP_PROPTY IN ('0805030100') THEN '10' -- 中外合资企业
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%有限责任公司%' THEN '10'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%股份有限公司%' THEN '10'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%基金%' THEN '06'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%集团有限公司%' THEN '10'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%有限公司%' THEN '10'
             END AS G070018 , -- 14 '交易对手大类' -- [20250619][巴启威][JLBA202505280002][吴大为]：交易对手大类小类口径按照9.2进行修改
            CASE WHEN M2.GB_CODE IS NOT NULL THEN M2.GB_CODE
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%财政部%' THEN '090501'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%政府%'   THEN '090601'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%财政厅%' THEN '090601'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%财政局%' THEN '090601'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%理财%公司%' THEN '010908'
                 WHEN CE.CORP_PROPTY IN ('0805010100','0805010200') THEN '100101' -- 国有企业
                 WHEN CE.CORP_PROPTY IN ('0805040000') THEN '100102' -- 集体企业
                 WHEN CE.CORP_PROPTY IN ('0805060000') THEN '100108' -- 其他企业
                 WHEN CE.CORP_PROPTY IN ('0805030100') THEN '100301' -- 中外合资企业
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%有限责任公司%' THEN '100105'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%股份有限公司%' THEN '100106'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%基金%' THEN '060201'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%集团有限公司%' THEN '100102'
                 WHEN NVL(T1.ISSU_ORG_NAM,T2.ISSU_ORG_NAM) LIKE '%有限公司%' THEN '100105'
             END AS G070039, -- 25 '交易对手小类' -- [20250619][巴启威][JLBA202505280002][吴大为]：交易对手大类小类口径按照9.2进行修改
            T.CTPY_RISK_RATING  as G070019          , -- 19 '交易对手评级' -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
            T.CTPY_RATING_ORG   as G070020          , -- 20 '交易对手评级机构' -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐         
            replace(replace(T.CTPY_OPEN_BANK,'(',''),')','') , -- 21 '交易对手账号行号'
            T.OPPO_ACCT_NUM               , -- 22 '交易对手账号' -- [20250427][姜俐锋][JLBA202503110010][徐晖]:修改交易对手账号取数逻辑
            T.CTPY_OPEN_BANK_NA           , -- 23 '交易对手账号开户行名称'
            G.GB_CODE , -- 24 '经办员工ID'
            G2.GB_CODE   AS G070025               , -- 25 '审批员工ID'
            CASE WHEN T.ORG_NUM = '009820' THEN '同业金融部'
                 WHEN T.ORG_NUM = '009804' THEN '金融市场部'
            END                           , -- 26 '行内归属部门'
            t.FINA_PRODUCT_CODE           , -- 27 '产品ID'
            NULL                          , -- 28 '理财交易登记ID' -- 默认为空
            NULL                          , -- 29 '行内理财交易ID' -- 默认为空
            NULL                          , -- 30 '资金流动类型' -- 默认为空
            CASE WHEN A.INVEST_TYP in ('00') THEN '12' -- 债券投资
                 WHEN A.INVEST_TYP in ('04','05','12') THEN '16' -- 资产管理产品
                 WHEN A.INVEST_TYP in ('01') THEN '14' -- 公募基金投资
                 WHEN A.INVEST_TYP in ('06') THEN '13' -- 权益类投资
                 ELSE '17' -- 其他
            END                     , -- 18 '自营业务大类'
            CASE WHEN A.INVEST_TYP = '00' AND E.STOCK_PRO_TYPE = 'A' AND E.IS_STOCK_ASSET = 'N' AND E.ISSU_ORG = 'A01' THEN '12010' -- 国债
                 WHEN A.INVEST_TYP = '00' AND E.STOCK_PRO_TYPE = 'A' AND E.IS_STOCK_ASSET = 'N' AND E.ISSU_ORG = 'A02' THEN '12020' -- 地方政府债
                 WHEN A.INVEST_TYP = '00' AND E.STOCK_PRO_TYPE = 'B' AND E.IS_STOCK_ASSET = 'N' THEN '12030' -- 央票
                 WHEN A.INVEST_TYP = '00' AND E.STOCK_PRO_TYPE = 'A' AND E.IS_STOCK_ASSET = 'N' AND E.ISSU_ORG LIKE 'C%' THEN '12040' -- 政府支持机构债
                 WHEN A.INVEST_TYP = '00' AND E.STOCK_PRO_TYPE LIKE 'C%' AND E.IS_STOCK_ASSET = 'N' AND E.ISSU_ORG = 'D02' THEN '12050' -- 政策性金融债
                 WHEN A.INVEST_TYP = '00' AND E.STOCK_PRO_TYPE LIKE 'C%' AND E.IS_STOCK_ASSET = 'N' AND E.ISSU_ORG <>'D02' THEN '12060' -- 商业性金融债
                 WHEN A.INVEST_TYP = '00' AND E.IS_STOCK_ASSET = 'N' AND E.STOCK_PRO_TYPE LIKE 'D%' THEN '12070' -- 非金融企业债券
                 WHEN A.INVEST_TYP = '00' AND E.IS_STOCK_ASSET = 'Y' AND E.STOCK_ASSET_TYPE = 'A01' THEN '12080' -- 资产支持证券（信贷资产证券化）
                 WHEN A.INVEST_TYP = '00' AND E.IS_STOCK_ASSET = 'Y' AND E.STOCK_ASSET_TYPE = 'A02' THEN '12090' -- 资产支持证券（交易所资产支持证券）
                 WHEN A.INVEST_TYP = '00' AND E.IS_STOCK_ASSET = 'Y' AND E.STOCK_ASSET_TYPE = 'A03' THEN '12100' -- 资产支持证券（资产支持票据）
                 WHEN A.INVEST_TYP = '00' AND E.STOCK_PRO_TYPE LIKE 'F%' AND E.IS_STOCK_ASSET = 'N' THEN '12110' -- 外国债券
                 WHEN A.INVEST_TYP = '00' AND E.IS_STOCK_ASSET = 'Y' AND E.STOCK_ASSET_TYPE NOT IN ('A01','A02','A03') THEN '12120' -- 其他债券投资
                 WHEN A.INVEST_TYP = '06' THEN '13010' -- 长期股权投资
                 WHEN A.INVEST_TYP = '02' THEN '13020' -- 上市股票
                 WHEN A.INVEST_TYP = '10' THEN '13030' -- 非上市股权
                 WHEN A.EQUITY_FLAG = 'Y' AND A.INVEST_TYP NOT IN ('02','06','10') THEN '13040' -- 其他权益类投资
                 WHEN A.INVEST_TYP LIKE '01%' AND c.SUBJECT_PRO_TYPE = '0102' THEN '14010' -- 债券基金
                 WHEN A.INVEST_TYP LIKE '01%' AND c.SUBJECT_PRO_TYPE = '0103' THEN '14020' -- 货币市场基金
                 WHEN A.INVEST_TYP LIKE '01%' AND c.FUNDS_TYPE = 'A03' THEN '14030' -- 股票基金
                 WHEN A.INVEST_TYP LIKE '01%' AND c.FUNDS_TYPE = 'A04' THEN '14040' -- 基金中基金
                 WHEN A.INVEST_TYP LIKE '01%' AND c.FUNDS_TYPE = 'A05' THEN '14050' -- 混合基金
                 WHEN A.INVEST_TYP LIKE '01%' AND c.FUNDS_TYPE = 'A99' THEN '14060' -- 其他公募基金投资
                 WHEN A.INVEST_TYP LIKE '01%' AND c.FUNDS_TYPE = 'B01' THEN '15010' -- 私募证券投资基金
                 WHEN A.INVEST_TYP LIKE '01%' AND c.FUNDS_TYPE = 'B02' THEN '15020' -- 私募股权投资基金
                 WHEN A.INVEST_TYP LIKE '01%' AND c.FUNDS_TYPE = 'B03' THEN '15030' -- 私募创业投资基金
                 WHEN A.INVEST_TYP LIKE '01%' AND c.FUNDS_TYPE = 'B99' THEN '15040' -- 其他私募基金投资
                 WHEN A.INVEST_TYP IN ('04','05','12') AND c.SPV_PRODUCT_TYPE = 'A' THEN '16011' -- 非保本理财投资
                 -- WHEN A.INVEST_TYP IN ('04','05','12') AND c.SPV_PRODUCT_TYPE = 'B' AND c.ENTRUST_PRODUCT_TYPE = 'A' THEN '1602' -- 信托产品（资金信托）康星无法判断信托细类
                 -- WHEN A.INVEST_TYP IN ('04','05','12') AND c.SPV_PRODUCT_TYPE = 'B' AND c.ENTRUST_PRODUCT_TYPE = 'B' THEN '1603' -- 信托产品（财产权信托）
                 WHEN A.INVEST_TYP IN ('04','05','12') AND c.SPV_PRODUCT_TYPE = 'B' AND A.ACCT_NUM IN ('N000310000025496','N000310000025495') THEN '16031' -- 信托产品（财产权信托）2笔中信信托特殊处理
                 WHEN A.INVEST_TYP IN ('04','05','12') AND c.SPV_PRODUCT_TYPE = 'B' AND A.ACCT_NUM NOT IN ('N000310000025496','N000310000025495') THEN '16021' -- 信托产品（资金信托）
                 WHEN A.INVEST_TYP IN ('04','05','12') AND c.SPV_PRODUCT_TYPE IN ('C','D','E') THEN '16041' -- 证券业资产管理产品（不含公募基金）
                 WHEN A.INVEST_TYP IN ('04','05','12') AND c.SPV_PRODUCT_TYPE = 'F' THEN '16051' -- 保险业资产管理产品
                 WHEN A.INVEST_TYP IN ('04','05','12') AND c.SPV_PRODUCT_TYPE IN ('I','Z') THEN '16061' -- 其他资产管理产品投资
                 WHEN A.OTHER_DEBT_TYPE = 'A' THEN '17010' -- 其他债权融资（其他交易平台债权融资工具）
                 WHEN A.OTHER_DEBT_TYPE = 'B' THEN '17020' -- 其他债权融资（非标转标资产）
                 WHEN A.INVEST_TYP IN ('09','99') AND (SUBSTR(c.SUBJECT_PRO_TYPE,1,2) = '09' OR (c.SUBJECT_PRO_TYPE = '99' AND c.SUBJECT_PRO_TYPE <>'9999')) AND A.OTHER_DEBT_TYPE IS NULL THEN '17030' -- 其他投资
                 ELSE '17030' -- 其他投资
            END AS YWXL                   , -- 34 '自营业务小类'
            A.REAL_INT_RAT                , -- 35 '年化利率' --康星有，资产收益率
            -- T.ACCT_TYPE                   , -- 36 '账户类型'
            CASE WHEN A.BOOK_TYPE = '2' -- 2-银行账户
                 THEN '01'   -- 01-银行账户
                 WHEN A.BOOK_TYPE = '1' -- 1-交易账户
                 THEN '02'   -- 02-交易账户
            END                           , -- 36 '账户类型'
            NULL                          , -- 31 '备注'
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 32 '采集日期'     
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
		    T.ORG_NUM                                       , -- 机构号       
		    '1',
		    CASE WHEN T.ORG_NUM = '009804' THEN '009804' -- 金融市场部
                 WHEN T.ORG_NUM = '009820' THEN '009820' -- 同业金融部
            END   -- 业务条线
           FROM SMTMODS.l_tran_fund_fx T 
          INNER JOIN SMTMODS.L_ACCT_FUND_INVEST A
             ON CASE 
            --  WHEN A.DATE_SOURCESD IN('非标投资','基金投资') THEN (T.CONTRACT_NUM = A.ACCT_NUM||A.REF_NUM)
            --  WHEN A.DATE_SOURCESD='债券投资' THEN (T.CONTRACT_NUM = A.CONTRACT_NUM  AND T.ACCT_NO = A.ACCT_NO)
                WHEN T.PRODUCT_NAME = '非标/基金还本交易' THEN  (T.CONTRACT_NUM = A.ACCT_NUM AND T.ACCT_NO=A.ACCT_NO )   -- JLBA202411080004 20241217 HMC
                WHEN T.PRODUCT_NAME = '债券/存单还本交易' THEN  (T.CONTRACT_NUM = A.ACCT_NUM||'_'||A.ACCT_NO )
                WHEN A.DATE_SOURCESD ='基金投资' THEN (T.CONTRACT_NUM = A.ACCT_NUM||A.REF_NUM) 
                WHEN A.DATE_SOURCESD IN('债券投资','非标投资') THEN (T.CONTRACT_NUM = A.CONTRACT_NUM AND T.ACCT_NO=A.ACCT_NO )  
                END  -- 数据量不大应该能执行，如果执行不动就拆成两段
            AND A.DATA_DATE = I_DATE
           LEFT JOIN SMTMODS.L_AGRE_BOND_INFO E -- 债券信息表
             ON A.GL_ITEM_CODE = E.STOCK_CD
            AND E.DATA_DATE = I_DATE 
           LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN
                      FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B1
             ON A.CUST_ID = B1.ECIF_CUST_ID
           LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                      FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B2
             ON A.CUST_ID = B2.CUST_ID
           LEFT JOIN SMTMODS.L_PUBL_ORG_BRA F
             ON T.ORG_NUM = F.ORG_NUM
            AND F.DATA_DATE = I_DATE
           LEFT JOIN SMTMODS.L_FINA_INNER D
             ON A.GL_ITEM_CODE = D.STAT_SUB_NUM 
            AND A.ORG_NUM = D.ORG_NUM
            AND D.DATA_DATE = I_DATE
           LEFT JOIN SMTMODS.L_AGRE_OTHER_SUBJECT_INFO C -- 其他标的物信息表
             ON A.SUBJECT_CD = C.SUBJECT_CD
            AND C.DATA_DATE = I_DATE
           LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
             ON T.ORG_NUM = ORG.ORG_NUM
            AND ORG.DATA_DATE = I_DATE
           LEFT JOIN M_DICT_CODETABLE G
             ON T.TRAN_TELLER = G.L_CODE
            AND G.L_CODE_TABLE_CODE ='C0013'
           LEFT JOIN M_DICT_CODETABLE G2
             ON T.APP_TELLER = G2.L_CODE
            AND G2.L_CODE_TABLE_CODE ='C0013'
		   LEFT JOIN SMTMODS.L_CUST_ALL I   -- 20240926 HMC
             ON A.CUST_ID=I.CUST_ID 
            AND I.DATA_DATE=I_DATE
            AND I.ORG_NUM NOT LIKE '5%'    
            AND I.ORG_NUM NOT LIKE '6%' 
           LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M1
             ON M1.L_CODE_TABLE_CODE = 'V0003' 
            AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M1.L_CODE
           LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M2 
             ON M2.L_CODE_TABLE_CODE = 'V0004' 
            AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M2.L_CODE
           LEFT JOIN SMTMODS.L_AGRE_BOND_INFO T1 -- [20250619][巴启威][JLBA202505280002][吴大为]：交易对手大类小类口径按照9.2进行修改
             ON A.ACCT_NUM = T1.STOCK_CD 
            AND T1.DATA_DATE = I_DATE
           LEFT JOIN SMTMODS.L_AGRE_OTHER_SUBJECT_INFO T2 -- [20250619][巴启威][JLBA202505280002][吴大为]：交易对手大类小类口径按照9.2进行修改
             ON A.ACCT_NUM = T2.SUBJECT_CD 
            AND T2.DATA_DATE = I_DATE 
           LEFT JOIN SMTMODS.L_CUST_EXTERNAL_INFO CE -- [20250619][巴启威][JLBA202505280002][吴大为]：交易对手大类小类口径按照9.2进行修改
             ON CE.DATA_DATE = I_DATE 
            AND (A.CUST_ID = CE.CUST_ID OR B2.ECIF_CUST_ID = CE.CUST_ID) 
          WHERE T.DATA_DATE = I_DATE  -- 范围与8.8、6.21、4.3同步
            AND T.TRAN_DT = I_DATE
             -- AND A.DATE_SOURCESD <> '基金投资' -- 按业务要求，不要基金投资
             -- AND T.INVEST_TYP = '00' -- 债券  不仅是债券，应该取整表
          ;
        
-- 2、存单投资与发行信息表  --取投资
INSERT INTO T_7_7 
 (
  
  G070001    , -- 01 '交易ID'
  G070002    , -- 02 '交易机构ID'
  G070037    , -- 37 '协议ID'
  G070003    , -- 03 '交易机构名称'
  G070004    , -- 04 '交易账号'
  G070005    , -- 05 '投资标的ID'
  G070006    , -- 06 '交易金额'
  G070007    , -- 07 '交易方向'
  G070008    , -- 08 '币种'
  G070009    , -- 09 '数量'
  G070010    , -- 10 '单位成交净价'
  G070011    , -- 11 '单位成交全价'
  G070012    , -- 12 '资产计量方式'
  G070013    , -- 13 '科目ID'
  G070014    , -- 14 '科目名称'
  G070015    , -- 15 '交易日期'
  G070016    , -- 16 '交易时间'
  G070038    , -- 38 '交易对手ID'
  G070017    , -- 17 '交易对手名称'
  G070018    , -- 18 '交易对手大类'
  G070039    , -- 39 '交易对手小类'
  G070019    , -- 19 '交易对手评级'
  G070020    , -- 20 '交易对手评级机构'
  G070021    , -- 21 '交易对手账号行号'
  G070022    , -- 22 '交易对手账号'
  G070023    , -- 23 '交易对手账号开户行名称'
  G070024    , -- 24 '经办员工ID'
  G070025    , -- 25 '审批员工ID'
  G070026    , -- 26 '行内归属部门'
  G070027    , -- 27 '产品ID'
  G070028    , -- 28 '理财交易登记ID'
  G070029    , -- 29 '行内理财交易ID'
  G070030    , -- 30 '资金流动类型'
  G070033    , -- 33 '自营业务大类'
  G070034    , -- 34 '自营业务小类'
  G070035    , -- 35 '年化利率'
  G070036    , -- 36 '账户类型'  
  G070031    , -- 31 '备注'
  G070032    , -- 32 '采集日期'
  DIS_DATA_DATE , -- 装入数据日期
  DIS_BANK_ID   , -- 机构号
  DIS_DEPT      ,
     DEPARTMENT_ID  -- 业务条线
  
)
    SELECT 
          NVL(T.TXN_NO,T.REF_NUM)       , -- 01 '交易ID'   -- JLBA202411080004 20241217 hmc
          ORG.ORG_ID                    , -- 02 '交易机构ID'
          A.ACCT_NUM || A.CDS_NO        , -- 37 '协议ID'
          C.ORG_NAM                     , -- 03 '交易机构名称'
          FUNC_SUBSTR(A.ACCT_NUM || A.CONT_PARTY_NAME,60), -- 04 '交易账号'
          A.CDS_NO                      , -- 05 '投资标的ID' 20250116
          T.AMOUNT                      , -- 06 '交易金额'
          CASE WHEN T.TRADE_DIRECT = '0' -- 结清（卖出）
               THEN '02' -- 卖出
               WHEN T.TRADE_DIRECT = '1' -- 发生（买入）
               THEN '01' -- 买入
          END                           , -- 07 '交易方向'
          T.CURR_CD                     , -- 08 '币种'
          T.AMOUNT                      , -- 09 '数量'  20241231T.SL
          T.DWCJJJ                      , -- 10 '单位成交净价'
       -- T.DEAL_PRICE                  , -- 11 '单位成交全价'
          T.AMOUNT                      , -- 11 '单位成交全价'[20251028][巴启威][JLBA202509280009][吴大为]: 单位成交全价取交易金额
          CASE WHEN A.ACCOUNTANT_TYPE='3' THEN '02'  ELSE '01' END  , -- 12 '资产计量方式'
          T.ITEM_CD                     , -- 13 '科目ID'
          D.GL_CD_NAME                  , -- 14 '科目名称'
          TO_CHAR(TO_DATE(T.TRAN_DT,'YYYYMMDD'),'YYYY-MM-DD')  , -- 15 '交易日期' -- 一表通校验修改  20241015 王金保
          nvl(time_format(T.TRANS_TIME,'%H:%i:%s'),'00:00:00') , -- 16 '交易时间'   ,
		  I.CUST_ID                     , -- 38 '交易对手ID'    -- 系统没有，默认为空   -- 20240926 hmc
          T.CONT_PARTY_NAME             , -- 17 '交易对手名称' -- 20241024_zhoulp_JLBA202408290021_金市需求_业务姚司桐
          -- 20241024_zhoulp_JLBA202409030008_交易对手大类小类
          CASE WHEN M1.GB_CODE IS NOT NULL THEN M1.GB_CODE
               WHEN T.CONT_PARTY_NAME LIKE '%银行%' THEN '01' -- [20250619][巴启威][JLBA202505280002][吴大为]：大类增加名称映射。'%银行%' 映射成对应码值01
               WHEN T.CONT_PARTY_NAME LIKE '%理财%公司%' THEN '01'
               WHEN T.CONT_PARTY_NAME LIKE '%基金%' THEN '06'
               WHEN T.CONT_PARTY_NAME LIKE '%财政部%' THEN '09'
               WHEN T.CONT_PARTY_NAME LIKE '%政府%'   THEN '09'
               WHEN T.CONT_PARTY_NAME LIKE '%财政厅%' THEN '09'
               WHEN T.CONT_PARTY_NAME LIKE '%财政局%' THEN '09'
               WHEN T.CONT_PARTY_NAME LIKE '%有限责任公司%' THEN '10'
               WHEN T.CONT_PARTY_NAME LIKE '%股份有限公司%' THEN '10'
               WHEN T.CONT_PARTY_NAME LIKE '%集团有限公司%' THEN '10'
               WHEN T.CONT_PARTY_NAME LIKE '%有限公司%' THEN '10'
           END AS G070018 , -- 14 '交易对手大类' -- [20250619][巴启威][JLBA202505280002][吴大为]：交易对手大类小类口径按照9.2进行修改
          CASE WHEN M2.GB_CODE IS NOT NULL THEN M2.GB_CODE
               WHEN T.CONT_PARTY_NAME LIKE '%理财%公司%' THEN '010908'
               WHEN T.CONT_PARTY_NAME LIKE '%基金%' THEN '060201'
               WHEN T.CONT_PARTY_NAME LIKE '%财政部%' THEN '090501'
               WHEN T.CONT_PARTY_NAME LIKE '%政府%'   THEN '090601'
               WHEN T.CONT_PARTY_NAME LIKE '%财政厅%' THEN '090601'
               WHEN T.CONT_PARTY_NAME LIKE '%财政局%' THEN '090601'
               WHEN T.CONT_PARTY_NAME LIKE '%有限责任公司%' THEN '100105'
               WHEN T.CONT_PARTY_NAME LIKE '%股份有限公司%' THEN '100106'
               WHEN T.CONT_PARTY_NAME LIKE '%集团有限公司%' THEN '100102'
               WHEN T.CONT_PARTY_NAME LIKE '%有限公司%' THEN '100105'
           END AS G070039, -- 25 '交易对手小类' -- [20250619][巴启威][JLBA202505280002][吴大为]：交易对手大类小类口径按照9.2进行修改
          NULL                          , -- 19 '交易对手评级'  -- 系统没有，默认为空
          NULL                          , -- 20 '交易对手评级机构'  -- 系统没有，默认为空
          replace(replace(T.CTPY_OPEN_BANK,'(',''),')','') , -- 21 '交易对手账号行号'
          T.OPPO_ACCT_NUM               , -- 22 '交易对手账号'  -- 20250427 jlf JLBA202503110010_关于金融市场部一表通7.7投资交易表报送逻辑变更的需求
          T.CTPY_OPEN_BANK_NA           , -- 23 '交易对手账号开户行名称'
          G.GB_CODE , -- 24 '经办员工ID'
          G2.GB_CODE AS G070025           , -- 25 '审批员工ID'
          '同业金融部'                  , -- 26 '行内归属部门'
          T.FINA_PRODUCT_CODE           , -- 27 '产品ID'
          NULL                          , -- 28 '理财交易登记ID' -- 默认为空
          T.REF_NUM                     , -- 29 '行内理财交易ID' -- 同业金融部康星有，行内唯一标识  ；金融市场部默认为空
          NULL                          , -- 30 '资金流动类型' -- 默认为空
          '09'                          , -- 33 '自营业务大类' -- 09-同业存单
          '09020'                       , -- 34 '自营业务小类' -- -0902持有 同业存单投资 
          A.INT_RAT                     , -- 35 '年化利率'
          CASE WHEN A.BOOK_TYPE = '2' -- 2-银行账户
               THEN '01'   -- 01-银行账户
               WHEN A.BOOK_TYPE = '1' -- 1-交易账户
               THEN '02'   -- 02-交易账户
          END                           , -- 36 '账户类型' 
          NULL                          , -- 31 '备注'
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 32 '采集日期'     
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
		  T.ORG_NUM                                       , -- 机构号  
		  '2',
		  A.ORG_NUM -- '009820'                                          -- 业务条线  -- 同业金融部
     FROM SMTMODS.L_TRAN_FUND_FX T 
    INNER JOIN SMTMODS.L_ACCT_FUND_CDS_BAL A
       ON T.CONTRACT_NUM = A.ACCT_NUM   -- 20241031 HMC 由 T.CONTRACT_NUM = A.CDS_NO改为T.CONTRACT_NUM = A.ACCT_NUM 原关联不对
      AND A.DATA_DATE = I_DATE 
     LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B1
       ON A.CUST_ID = B1.ECIF_CUST_ID
     LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B2
       ON A.CUST_ID = B2.CUST_ID
	 LEFT JOIN SMTMODS.L_PUBL_ORG_BRA C
       ON T.ORG_NUM = C.ORG_NUM
      AND C.DATA_DATE = I_DATE
     LEFT JOIN SMTMODS.L_FINA_INNER D
       ON T.ITEM_CD = D.STAT_SUB_NUM
      AND T.ORG_NUM = D.ORG_NUM
      AND D.DATA_DATE = I_DATE
     LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
       ON T.ORG_NUM = ORG.ORG_NUM
      AND ORG.DATA_DATE = I_DATE
     LEFT JOIN m_dict_codetable G
       ON T.TRAN_TELLER = G.L_CODE
      AND G.l_code_table_code ='C0013'
     LEFT JOIN m_dict_codetable G2
       ON T.APP_TELLER = G2.L_CODE
      AND G2.l_code_table_code ='C0013'
     LEFT JOIN SMTMODS.L_CUST_ALL I    -- 20240926 HMC
       ON A.CUST_ID=I.CUST_ID 
      AND I.DATA_DATE=I_DATE
      AND I.ORG_NUM NOT LIKE '5%'    
      AND I.ORG_NUM NOT LIKE '6%' 
     LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M1
       ON M1.L_CODE_TABLE_CODE = 'V0003'
      AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M1.L_CODE
     LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M2 
       ON M2.L_CODE_TABLE_CODE = 'V0004' 
      AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M2.L_CODE
    WHERE T.DATA_DATE = I_DATE AND A.PRODUCT_PROP = 'A' -- 持有 同业存单投资 -- 范围与8.8、6.21、4.3同步
      AND T.TRAN_DT = I_DATE;
     
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);	
	
 
	   
    #4.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '财管数据插入';
	
	
	INSERT INTO T_7_7 
 (
  
  G070001    , -- 01 '交易ID'
  G070002    , -- 02 '交易机构ID'
  G070037    , -- 37 '协议ID'
  G070003    , -- 03 '交易机构名称'
  G070004    , -- 04 '交易账号'
  G070005    , -- 05 '投资标的ID'
  G070006    , -- 06 '交易金额'
  G070007    , -- 07 '交易方向'
  G070008    , -- 08 '币种'
  G070009    , -- 09 '数量'
  G070010    , -- 10 '单位成交净价'
  G070011    , -- 11 '单位成交全价'
  G070012    , -- 12 '资产计量方式'
  G070013    , -- 13 '科目ID'
  G070014    , -- 14 '科目名称'
  G070015    , -- 15 '交易日期'
  G070016    , -- 16 '交易时间'
  G070038    , -- 38 '交易对手ID'
  G070017    , -- 17 '交易对手名称'
  G070018    , -- 18 '交易对手大类'
  G070039    , -- 39 '交易对手小类'
  G070019    , -- 19 '交易对手评级'
  G070020    , -- 20 '交易对手评级机构'
  G070021    , -- 21 '交易对手账号行号'
  G070022    , -- 22 '交易对手账号'
  G070023    , -- 23 '交易对手账号开户行名称'
  G070024    , -- 24 '经办员工ID'
  G070025    , -- 25 '审批员工ID'
  G070026    , -- 26 '行内归属部门'
  G070027    , -- 27 '产品ID'
  G070028    , -- 28 '理财交易登记ID'
  G070029    , -- 29 '行内理财交易ID'
  G070030    , -- 30 '资金流动类型'
  G070033    , -- 33 '自营业务大类'
  G070034    , -- 34 '自营业务小类'
  G070035    , -- 35 '年化利率'
  G070036    , -- 36 '账户类型'  
  G070031    , -- 31 '备注'
  G070032    , -- 32 '采集日期'
  DIS_DATA_DATE , -- 装入数据日期
  DIS_BANK_ID   , -- 机构号
  DEPARTMENT_ID  -- 业务条线
  
)
select 
  G070001    , -- 01 '交易ID'
  G070002    , -- 02 '交易机构ID'
  G070037    , -- 37 '协议ID'
  G070003    , -- 03 '交易机构名称'
  G070004    , -- 04 '交易账号'
  G070005    , -- 05 '投资标的ID'
  G070006    , -- 06 '交易金额'
  G070007    , -- 07 '交易方向'
  G070008    , -- 08 '币种'
  G070009    , -- 09 '数量'
  G070010    , -- 10 '单位成交净价'
  G070011    , -- 11 '单位成交全价'
  G070012    , -- 12 '资产计量方式'
  G070013    , -- 13 '科目ID'
  G070014    , -- 14 '科目名称'
  G070015    , -- 15 '交易日期'
  G070016    , -- 16 '交易时间'
  G070038    , -- 38 '交易对手ID'
  G070017    , -- 17 '交易对手名称'
  G070018    , -- 18 '交易对手大类'
  G070039    , -- 39 '交易对手小类'
  G070019    , -- 19 '交易对手评级'
  G070020    , -- 20 '交易对手评级机构'
  G070021    , -- 21 '交易对手账号行号'
  G070022    , -- 22 '交易对手账号'
  G070023    , -- 23 '交易对手账号开户行名称'
  G070024    , -- 24 '经办员工ID'
  G070025    , -- 25 '审批员工ID'
  G070026    , -- 26 '行内归属部门'
  G070027    , -- 27 '产品ID'
  G070028    , -- 28 '理财交易登记ID'
  G070029    , -- 29 '行内理财交易ID'
  G070030    , -- 30 '资金流动类型'
  G070033    , -- 33 '自营业务大类'
  G070034    , -- 34 '自营业务小类'
  G070035    , -- 35 '年化利率'
  G070036    , -- 36 '账户类型'  
  G070031    , -- 31 '备注'
  G070032    , -- 32 '采集日期'
  TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , -- 装入数据日期
  '990000'   , -- 机构号
  CASE WHEN  ywxt = '总行机关战略投资管理部' THEN  '0098ZT'
	   WHEN  ywxt = '总行机关运营管理部' THEN  '009801'
   END    -- 业务条线
FROM SMTMODS.RSF_GQ_INVESTMENT_TRANSACTIONS T WHERE  T.DATA_DATE=I_DATE; 
COMMIT;


    #4.过程结束执行
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '过程结束执行';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    SET OI_RETCODE = P_STATUS; 
    SET OI_REMESSAGE = P_DESCB;
    select OI_RETCODE,'|',OI_REMESSAGE;
END $$

