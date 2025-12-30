DROP Procedure IF EXISTS `PROC_BSP_T_6_14_PJZTXXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_14_PJZTXXY"(IN I_DATE VARCHAR(8),
                                        OUT OI_RETCODE   INT,-- 返回CODE
                                        OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
)
BEGIN

  /******
      程序名称  ：表6.14票据转贴现协议
      程序功能  ：加工表6.14票据转贴现协议
      目标表：T_6_14 
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	 -- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311
  /* 需求编号：JLBA202502210009 上线日期：20250415，修改人：姜俐锋，提出人：吴大为 */
  /* 需求编号：JLBA202504060003 上线日期： 20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/
  /*需求编号：JLBA202504160004   上线日期：20250627，修改人：姜俐锋，提出人：吴大为 关于吉林银行修改单一客户授信逻辑的需求*/
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
   SELECT OI_RETCODE,'|',OI_REMESSAGE;
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_14_PJZTXXY';
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
	
	DELETE FROM T_6_14 WHERE F140035 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');										
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);

	#参照EAST5_DATACORE.BSP_SP_EAST5_IE_005_PJZTXB共5段
		
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '1、转贴现卖断（贴现转出）';	

INSERT INTO T_6_14
 (
    F140001    , -- 01 '协议ID'
	F140002    , -- 02 '机构ID'
	F140003    , -- 03 '票据号码'
	F140004    , -- 04 '票据类型'
	F140005    , -- 05 '协议币种'
	F140006    , -- 06 '票面金额'
	F140007    , -- 07 '票据签发日期'
	F140008    , -- 08 '票据到期日期'
	F140009    , -- 09 '出票人名称'
	F140010    , -- 10 '承兑人名称'
	F140011    , -- 11 '贴现人名称'
	F140012    , -- 12 '贴现日期'
	F140013    , -- 13 '交易方向'
	F140014    , -- 14 '转贴现类型'
	F140015    , -- 15 '科目ID'
    F140016    , -- 16 '科目名称'
    F140017    , -- 17 '转贴现日期'
    F140018    , -- 18 '转贴现金额'
    F140019    , -- 19 '转贴现计息天数'
    F140020    , -- 20 '转贴现利率'
    F140021    , -- 21 '转贴现利息'
    F140022    , -- 22 '回购日期'
    F140023    , -- 23 '回购金额'
    F140024    , -- 24 '回购利率'
    F140025    , -- 25 '回购利息'
    F140026    , -- 26 '交易对手名称'
    F140027    , -- 27 '交易对手账号行号'
    F140028    , -- 28 '重点产业标识'
	F140029    , -- 29 '经办员工ID'
    F140030    , -- 30 '审查员工ID'
    F140031    , -- 31 '审批员工ID'
    F140032    , -- 32 '或有负债标识'
    F140033    , -- 33 '票据状态'
    F140034    , -- 34 '备注'
    F140035    , -- 35 '采集日期'
    DIS_DATA_DATE   , -- 装入数据日期
    DIS_BANK_ID     , -- 机构号
    DIS_DEPT        ,
    DEPARTMENT_ID , -- 业务条线
    F140036, -- 授信ID
    F140037-- 借据ID
 )
SELECT      SUBSTR(D.ACCT_NUM || NVL(D.DRAFT_RNG,''),1,60)   , -- 01 '协议ID'    -- 合同号||子票区间   
            -- E.CONTRACT_NO        , -- 01 '协议ID'     
            ORG.ORG_ID           , -- 02 '机构ID'
            D.DRAFT_NBR || NVL(D.DRAFT_RNG,'')          , -- 03 '票据号码'
            CASE WHEN B.BILL_TYPE='1' THEN '01' -- 银行承兑汇票
                 WHEN B.BILL_TYPE='2' THEN '02' -- 商业承兑汇票
            END                  , -- 04 '票据类型'
            B.CURR_CD            , -- 05 '协议币种'
            D.DRAWDOWN_AMT       , -- 06 '票面金额'  -- [20250415][姜俐锋][JLBA202502210009][吴大为]:  与east确认 取放款金额
            -- D.LOAN_ACCT_BAL      , -- 06 '票面金额'
            TO_CHAR(TO_DATE(B.OPEN_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 07 '票据签发日期'
            TO_CHAR(TO_DATE(B.MATU_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 08 '票据到期日期'
            B.AFF_NAME           , -- 09 '出票人名称'
            B.PAY_BANK_NAME      , -- 10 '承兑人名称'
            -- B.RECE_NAME          , -- 11 '贴现人名称'
            B.DISCOUNT_APP_NAME          , -- 11 '贴现人名称'  一表通转EAST 20240627 LMH
            -- TO_CHAR(TO_DATE(NVL(B.DISCOUNT_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD'), -- 12 '贴现日期'
            NVL(DDD.DISCOUNT_DATE,'9999-12-31'), -- 12 '贴现日期' -- JLBA202412200001 20250116 王金保修改 修改一表通6.14 贴现日期，参考EAST分段式区间
            '02'                 , -- 13 '交易方向'  --按EAST取 02-卖出
            '02'                 , -- 14 '转贴现类型'--按EAST取 02-转贴现卖断
            D.ITEM_CD            , -- 15 '科目ID'
            F.GL_CD_NAME         , -- 16 '科目名称' 
            TO_CHAR(TO_DATE(NVL(D.DRAWDOWN_DT,'99991231'),'YYYYMMDD'),'YYYY-MM-DD'), -- 17 '转贴现日期'
            ROUND(A.PAY_AMT, 2)  , -- 18 '转贴现金额' 20240621 LDP V1.0 与EAST逻辑同步,原为 D.DRAWDOWN_AMT
            D.INT_NUM_DATE       , -- 19 '转贴现计息天数'
            D.REAL_INT_RAT       , -- 20 '转贴现利率'
            D.DISCOUNT_INTEREST  , -- 21 '转贴现利息'
            '9999-12-31'         , -- 22 '回购日期'  --按EAST赋空值
            NULL                 , -- 23 '回购金额'  --按EAST赋空值
            NULL                 , -- 24 '回购利率'  --按EAST赋空值
            NULL                 , -- 25 '回购利息'  --按EAST赋空值
           -- LCA.CUST_NAM           , -- 26 '交易对手名称'
           -- NVL(E.CUST_BANK_CD,E.SWIFT_CODE), -- 27 '交易对手账号行号'
            C.FINA_ORG_NAME      , -- 26 '交易对手名称'
            C.CUST_BANK_CD       , -- 27 '交易对手账号行号'
            NULL                 , -- 28 '重点产业标识' -- 默认为空
            D.JBYG_ID            , -- 29 '经办员工ID'  -- 新增字段
            D.SZYG_ID            , -- 30 '审查员工ID'  -- 新增字段
            D.SPYG_ID            , -- 31 '审批员工ID'  -- 新增字段
            '1'                  , -- 32 或有负债标识       -- 默认1-是
            '02'                 , -- 33 '票据状态'  [20250513][狄家卉][JLBA202504060003][吴大为]: 票据状态修改为卖断
           -- B.DRAFT_STATUS       ,   -- 33 '票据状态'  0627 WWK
           -- '2、转贴现卖断（贴现转出）'                 , -- 34 '备注'
            NULL                       ,-- 34 '备注'         0626WWK
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 49 采集日期
	        TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
	        A.ORG_NUM                  , -- 机构号
	        '1、转贴现卖断（贴现转出）',
	        '009804' ,                                         -- 业务条线  -- 金融市场部
	         NVL(E.FACILITY_NO,G.FACILITY_NO) , --  授信ID  2.0 ZDSJ H -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐
	         SUBSTR(D.ACCT_NUM || NVL(D.DRAFT_RNG,''),1,60)  -- 授信ID 2.0 ZDSJ H
    FROM SMTMODS.L_TRAN_LOAN_PAYM A -- 贷款还款明细信息表
    LEFT JOIN SMTMODS.L_ACCT_LOAN D -- 贷款借据信息表
      ON A.LOAN_NUM = D.LOAN_NUM
     AND D.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_AGRE_BILL_INFO B -- 商业汇票票面信息表
      ON D.DRAFT_NBR = B.BILL_NUM
     AND B.DATA_DATE = I_DATE
    LEFT JOIN (SELECT DISTINCT BILL_NUM,ACCT_NUM,DISCOUNT_DATE
                 FROM SMTMODS.L_AGRE_BILL_CONTRACT A -- 票据合同信息表
                WHERE DATA_DATE = I_DATE ) DDD	-- JLBA202412200001 20250116 王金保修改 修改一表通6.14 贴现日期，参考EAST分段式区间
      ON DDD.BILL_NUM||DDD.ACCT_NUM=D.DRAFT_NBR||D.DRAFT_RNG
    LEFT JOIN SMTMODS.L_AGRE_BILL_CONTRACT E -- 票据合同信息表  -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐
      ON D.ACCT_NUM = E.BILL_NUM
     AND D.DRAFT_RNG= E.ACCT_NUM
     AND E.DATA_DATE = I_DATE
     AND E.TRADE_DIRECT ='TDD02' -- 卖出
     AND E.ACCOUNT_STATUS = '02'
    LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') C
      ON D.CUST_ID =C.CUST_ID
     AND C.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_FINA_INNER F   -- 内部科目对照表
      ON D.ITEM_CD = F.STAT_SUB_NUM
     AND A.ORG_NUM = F.ORG_NUM
     AND F.DATA_DATE = I_DATE  
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
      ON A.ORG_NUM = ORG.ORG_NUM
     AND ORG.DATA_DATE = I_DATE
   LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G  -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐  -- 刘洋：商票取出票人授信
      ON B.AFF_CODE = G.CUST_ID
     AND G.FACILITY_TYP IN ('2','4')
     AND G.DATA_DATE = I_DATE 
   WHERE A.DATA_DATE = I_DATE
     AND A.BILL_TRANS_FLG = 'Y'; -- 买断式转贴现转出标志
      -- AND TRUNC(A.REPAY_DT,'MM') = TRUNC(D_DATADATE,'MM')

   CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
   
	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '2、转贴现卖断（转贴现买断后转出）';

INSERT INTO T_6_14
 (
    F140001    , -- 01 '协议ID'
	F140002    , -- 02 '机构ID'
	F140003    , -- 03 '票据号码'
	F140004    , -- 04 '票据类型'
	F140005    , -- 05 '协议币种'
	F140006    , -- 06 '票面金额'
	F140007    , -- 07 '票据签发日期'
	F140008    , -- 08 '票据到期日期'
	F140009    , -- 09 '出票人名称'
	F140010    , -- 10 '承兑人名称'
	F140011    , -- 11 '贴现人名称'
	F140012    , -- 12 '贴现日期'
	F140013    , -- 13 '交易方向'
	F140014    , -- 14 '转贴现类型'
	F140015    , -- 15 '科目ID'
    F140016    , -- 16 '科目名称'
    F140017    , -- 17 '转贴现日期'
    F140018    , -- 18 '转贴现金额'
    F140019    , -- 19 '转贴现计息天数'
    F140020    , -- 20 '转贴现利率'
    F140021    , -- 21 '转贴现利息'
    F140022    , -- 22 '回购日期'
    F140023    , -- 23 '回购金额'
    F140024    , -- 24 '回购利率'
    F140025    , -- 25 '回购利息'
    F140026    , -- 26 '交易对手名称'
    F140027    , -- 27 '交易对手账号行号'
    F140028    , -- 28 '重点产业标识'
	F140029    , -- 29 '经办员工ID'
    F140030    , -- 30 '审查员工ID'
    F140031    , -- 31 '审批员工ID'
    F140032    , -- 32 '或有负债标识'
    F140033    , -- 33 '票据状态'
    F140034    , -- 34 '备注'
    F140035    , -- 35 '采集日期'
    DIS_DATA_DATE , -- 装入数据日期
    DIS_BANK_ID   , -- 机构号
    DIS_DEPT      ,
    DEPARTMENT_ID , -- 业务条线
     F140036, -- 授信ID
    F140037-- 借据ID
 )
SELECT      SUBSTR(LA.ACCT_NUM  || NVL(LA.DRAFT_RNG,''),1,60) , -- 01 '协议ID'    -- 合同号||子票区间   
            -- E.CONTRACT_NO        , -- 01 '协议ID'   
            ORG.ORG_ID            , -- 02 '机构ID'
            LA.DRAFT_NBR || NVL(LA.DRAFT_RNG,'')          , -- 03 '票据号码'
            CASE WHEN D.BILL_TYPE='1' THEN '01' -- 银行承兑汇票
                 WHEN D.BILL_TYPE='2' THEN '02' -- 商业承兑汇票
            END                  , -- 04 '票据类型'
            D.CURR_CD            , -- 05 '协议币种'
            D.AMOUNT             , -- 06 '票面金额'
            TO_CHAR(TO_DATE(D.OPEN_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 07 '票据签发日期'
            TO_CHAR(TO_DATE(D.MATU_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 08 '票据到期日期'
            D.AFF_NAME           , -- 09 '出票人名称'
            D.PAY_BANK_NAME      , -- 10 '承兑人名称'
           -- D.RECE_NAME          , -- 11 '贴现人名称'
            D.DISCOUNT_APP_NAME          , -- 11 '贴现人名称' 一表通转EAST 20240627 LMH
            -- TO_CHAR(TO_DATE(NVL(D.DISCOUNT_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD'), -- 12 '贴现日期'
            NVL(DDD.DISCOUNT_DATE,'9999-12-31'), -- 12 '贴现日期' -- JLBA202412200001 20250116 王金保修改 修改一表通6.14 贴现日期，参考EAST分段式区间
            '02'                 , -- 13 '交易方向'  --按EAST取 02-卖出
            '02'                 , -- 14 '转贴现类型'--按EAST取 02-转贴现卖断
            LA.ITEM_CD            , -- 15 '科目ID'
            F.GL_CD_NAME         , -- 16 '科目名称'
            TO_CHAR(TO_DATE(NVL(LA.DRAWDOWN_DT,'99991231'),'YYYYMMDD'),'YYYY-MM-DD'), -- 17 '转贴现日期'
            A.AMOUNT              , -- 18 '转贴现金额' 20240621 LDP V1.0 与EAST逻辑同步,原为 LA.DRAWDOWN_AMT
           -- LA.INT_NUM_DATE       , -- 19 '转贴现计息天数'
            TO_DATE(D.MATU_DATE,'YYYYMMDD') - TO_DATE(A.TRAN_DT,'YYYYMMDD')       , -- 19 '转贴现计息天数' -- 20240624 LDP V1.1 与EAST逻辑同步 原为 LA.INT_NUM_DATE
            LA.REAL_INT_RAT       , -- 20 '转贴现利率'
            LA.DISCOUNT_INTEREST  , -- 21 '转贴现利息'
            '9999-12-31'         , -- 22 '回购日期'  --按EAST赋空值
            NULL                 , -- 23 '回购金额'  --按EAST赋空值
            NULL                 , -- 24 '回购利率'  --按EAST赋空值
            NULL                 , -- 25 '回购利息'  --按EAST赋空值
           -- LCA.CUST_NAM           , -- 26 '交易对手名称'
           -- NVL(E.CUST_BANK_CD,E.SWIFT_CODE), -- 27 '交易对手账号行号'
            C.FINA_ORG_NAME      , -- 26 '交易对手名称'
            C.CUST_BANK_CD       , -- 27 '交易对手账号行号'
            NULL                 , -- 28 '重点产业标识' -- 默认为空
            LA.JBYG_ID           , -- 29 '经办员工ID'  -- 新增字段
            LA.SZYG_ID           , -- 30 '审查员工ID'  -- 新增字段
            LA.SPYG_ID           , -- 31 '审批员工ID'  -- 新增字段
            '0'                  , -- 32 或有负债标识 -- 默认0-否
            '02'                 , -- 33 '票据状态'  [20250513][狄家卉][JLBA202504060003][吴大为]: 票据状态修改为卖断
           -- D.DRAFT_STATUS       ,  -- 33 '票据状态'  0627 WWK
            NULL                 , -- 34 '备注'
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 49 采集日期
	        TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
	        A.ORG_NUM                  , -- 机构号
	        '2、转贴现卖断（转贴现买断后转出）',
	        '009804',                                          -- 业务条线  -- 金融市场部
	        -- NVL(E.FACILITY_NO,G.FACILITY_NO) , --  授信ID  2.0 ZDSJ H -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐
	        NVL(G.FACILITY_NO,G1.FACILITY_NO) , --  授信ID  -- [20250627][姜俐锋][JLBA202504160004][吴大为]:修改授信ID取数逻辑
            SUBSTR(LA.ACCT_NUM  || NVL(LA.DRAFT_RNG,''),1,60) --    借据ID 2.0 ZDSJ H
    FROM SMTMODS.L_TRAN_FUND_FX A -- 资金交易信息表
    LEFT JOIN SMTMODS.L_AGRE_BILL_INFO D -- 商业汇票票面信息表
      ON A.CONTRACT_NUM = D.BILL_NUM
     AND D.DATA_DATE = I_DATE
    LEFT JOIN (SELECT DISTINCT BILL_NUM,ACCT_NUM,DISCOUNT_DATE
              FROM SMTMODS.L_AGRE_BILL_CONTRACT A -- 票据合同信息表
             WHERE DATA_DATE = I_DATE ) DDD	-- JLBA202412200001 20250116 王金保修改 修改一表通6.14 贴现日期，参考EAST分段式区间
      ON DDD.BILL_NUM||DDD.ACCT_NUM=A.CONTRACT_NUM||A.DRAFT_RNG
    LEFT JOIN SMTMODS.L_ACCT_LOAN LA -- 贷款借据信息表
      ON A.CONTRACT_NUM = LA.ACCT_NUM
     AND A.DRAFT_RNG = LA.DRAFT_RNG
     AND LA.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_AGRE_BILL_CONTRACT E -- 票据合同信息表  -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐
      ON LA.ACCT_NUM = E.BILL_NUM
     AND LA.DRAFT_RNG= E.ACCT_NUM
     AND E.DATA_DATE = I_DATE
     AND E.TRADE_DIRECT ='TDD02' -- 卖出
     AND E.ACCOUNT_STATUS = '02'
	LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                 FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') C
      ON LA.CUST_ID =C.CUST_ID
     AND C.DATA_DATE = I_DATE	  
    LEFT JOIN SMTMODS.L_FINA_INNER F   -- 内部科目对照表
      ON LA.ITEM_CD = F.STAT_SUB_NUM
     AND A.ORG_NUM = F.ORG_NUM
     AND F.DATA_DATE = I_DATE 
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
      ON A.ORG_NUM = ORG.ORG_NUM
     AND ORG.DATA_DATE = I_DATE
   LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G  -- [20250627][姜俐锋][JLBA202504160004][吴大为]:修改授信ID取数逻辑
      ON D.AFF_CODE = G.CUST_ID
     AND G.FACILITY_TYP IN ('2','4')
     AND G.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G1 -- [20250627][姜俐锋][JLBA202504160004][吴大为]:修改授信ID取数逻辑
      ON D.pay_cusid = G1.CUST_ID 
     AND G1.DATA_DATE = I_DATE  
  /* LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G  -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐  -- 刘洋：商票取出票人授信
      ON D.AFF_CODE = G.CUST_ID
     AND G.FACILITY_TYP IN ('2','4')
     AND G.DATA_DATE = I_DATE */
   WHERE A.DATA_DATE = I_DATE
     AND A.TRADE_DIRECT = '0' -- 结清
     AND A.BUSI_TYPE = 'I'
     AND (LA.ACCT_STS <> '3' OR -- 贷款核销修改：保留贷款核销数据 20211028 WQJ
          LA.LOAN_ACCT_BAL > 0 OR  
		  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
          LA.FINISH_DT BETWEEN TO_DATE(SUBSTR(I_DATE, 1, 4) || '0101', 'YYYYMMDD') AND TO_DATE(I_DATE, 'YYYYMMDD'));

    CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    
    SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '3、票据转贴现';
	
 INSERT INTO T_6_14
 (
    F140001    , -- 01 '协议ID'
	F140002    , -- 02 '机构ID'
	F140003    , -- 03 '票据号码'
	F140004    , -- 04 '票据类型'
	F140005    , -- 05 '协议币种'
	F140006    , -- 06 '票面金额'
	F140007    , -- 07 '票据签发日期'
	F140008    , -- 08 '票据到期日期'
	F140009    , -- 09 '出票人名称'
	F140010    , -- 10 '承兑人名称'
	F140011    , -- 11 '贴现人名称'
	F140012    , -- 12 '贴现日期'
	F140013    , -- 13 '交易方向'
	F140014    , -- 14 '转贴现类型'
	F140015    , -- 15 '科目ID'
    F140016    , -- 16 '科目名称'
    F140017    , -- 17 '转贴现日期'
    F140018    , -- 18 '转贴现金额'
    F140019    , -- 19 '转贴现计息天数'
    F140020    , -- 20 '转贴现利率'
    F140021    , -- 21 '转贴现利息'
    F140022    , -- 22 '回购日期'
    F140023    , -- 23 '回购金额'
    F140024    , -- 24 '回购利率'
    F140025    , -- 25 '回购利息'
    F140026    , -- 26 '交易对手名称'
    F140027    , -- 27 '交易对手账号行号'
    F140028    , -- 28 '重点产业标识'
	F140029    , -- 29 '经办员工ID'
    F140030    , -- 30 '审查员工ID'
    F140031    , -- 31 '审批员工ID'
    F140032    , -- 32 '或有负债标识'
    F140033    , -- 33 '票据状态'
    F140034    , -- 34 '备注'
    F140035    , -- 35 '采集日期'
    DIS_DATA_DATE , -- 装入数据日期
    DIS_BANK_ID   , -- 机构号
    DIS_DEPT      ,
    DEPARTMENT_ID,  -- 业务条线
    F140036, -- 授信ID
    F140037-- 借据ID
 )
SELECT      'Z'||SUBSTR(A.ACCT_NUM || NVL(A.DRAFT_RNG,''),1,60), -- 01 '协议ID'  -- 合同号||子票区间   -- [20250513] [狄家卉] [JLBA202504060003][吴大为] 异常数据均为 一笔票据转贴现，一笔转贴现卖断（转贴现买断后转出），协议号加字母“Z”
            -- E.CONTRACT_NO        , -- 01 '协议ID'
            ORG.ORG_ID           , -- 02 '机构ID'
            A.DRAFT_NBR || NVL(A.DRAFT_RNG,'')          , -- 03 '票据号码' 
            CASE WHEN B.PAY_BANK_TYPE='B' THEN '03' -- 财务公司承兑汇票
                 WHEN B.BILL_TYPE='1' THEN '01' -- 银行承兑汇票
                 WHEN B.BILL_TYPE='2' THEN '02' -- 商业承兑汇票
            END AS PJLX          , -- 04 '票据类型'
            B.CURR_CD            , -- 05 '协议币种'
            A.DRAWDOWN_AMT       , -- 06 '票面金额'  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 与east确认 取放款金额
            -- A.LOAN_ACCT_BAL      , -- 06 '票面金额'
            TO_CHAR(TO_DATE(B.OPEN_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 07 '票据签发日期'
            TO_CHAR(TO_DATE(B.MATU_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 08 '票据到期日期'
            B.AFF_NAME           , -- 09 '出票人名称'
            B.PAY_BANK_NAME      , -- 10 '承兑人名称'
           -- B.RECE_NAME          , -- 11 '贴现人名称'
            B.DISCOUNT_APP_NAME          , -- 11 '贴现人名称'  --一表通转EAST 20240627 LMH
            -- TO_CHAR(TO_DATE(NVL(B.DISCOUNT_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD'), -- 12 '贴现日期'
            NVL(DDD.DISCOUNT_DATE,'9999-12-31'), -- 12 '贴现日期' -- JLBA202412200001 20250116 王金保修改 修改一表通6.14 贴现日期，参考EAST分段式区间
            '01'                 , -- 13 '交易方向'  --按EAST取 01-买入
            '01'                 , -- 14 '转贴现类型'--按EAST取 01-转贴现买断
            A.ITEM_CD            , -- 15 '科目ID'
            F.GL_CD_NAME         , -- 16 '科目名称'
            TO_CHAR(TO_DATE(NVL(A.DRAWDOWN_DT,'99991231'),'YYYYMMDD'),'YYYY-MM-DD'), -- 17 '转贴现日期'
            A.DRAWDOWN_AMT       , -- 18 '转贴现金额'
            A.INT_NUM_DATE       , -- 19 '转贴现计息天数'
            A.REAL_INT_RAT       , -- 20 '转贴现利率'
            A.DISCOUNT_INTEREST  , -- 21 '转贴现利息'
            '9999-12-31'         , -- 22 '回购日期'  --按EAST赋空值
            NULL                 , -- 23 '回购金额'  --按EAST赋空值
            NULL                 , -- 24 '回购利率'  --按EAST赋空值
            NULL                 , -- 25 '回购利息'  --按EAST赋空值
            C.FINA_ORG_NAME      , -- 26 '交易对手名称'
            C.CUST_BANK_CD       , -- 27 '交易对手账号行号'
            NULL                 , -- 28 '重点产业标识' -- 默认为空
            -- T.STAFF_NUM          , -- 29 '经办员工ID'
            A.JBYG_ID            , -- 29 '经办员工ID'  -- 新增字段
            A.SZYG_ID            , -- 30 '审查员工ID'  -- 新增字段
            A.SPYG_ID            , -- 31 '审批员工ID'  -- 新增字段
            '0'                  , -- 32 '或有负债标识'  -- 默认0-否
            CASE 
            WHEN A.ACCT_STS <> '3' THEN  
            '01'                   -- 正常
            WHEN A.ACCT_STS = '3' AND A.LOAN_ACCT_BAL = 0 and substr(A.MATURITY_DT,1,4) = substr(I_DATE,1,4) THEN 
            '03'                   -- 解付
            END                  , -- 33 '票据状态' [20250513][狄家卉][JLBA202504060003][吴大为]: 判断票据状态 正常，解付，（终结是做撤销,解付正常到期）：余额为0，[JLBA202507090010]到期日为当年，其余为正常
          --  B.DRAFT_STATUS        , -- '票据状态'    0627  WWK
           -- '1、票据转贴现'        , -- 34 '备注'
            NULL                ,-- 34 '备注'   0626WWK
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 49 采集日期
	        TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
	        A.ORG_NUM                  , -- 机构号
	        '3、票据转贴现',
 		    '009804' ,                                         -- 业务条线  -- 金融市场部 
	        -- NVL(E.FACILITY_NO,G.FACILITY_NO) ,  --  授信ID  20250311 2.0 ZDSJ H -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐
	         NVL(G.FACILITY_NO,G1.FACILITY_NO) ,  --  授信ID
 		    SUBSTR(A.ACCT_NUM  || NVL(A.DRAFT_RNG,''),1,60)-- 借据ID 2.0 ZDSJ H
    FROM SMTMODS.L_ACCT_LOAN A -- 借据表
   INNER JOIN SMTMODS.L_AGRE_BILL_INFO B -- 商业汇票票面信息表
      ON A.DRAFT_NBR = B.BILL_NUM
     AND B.DATA_DATE = I_DATE
    LEFT JOIN (SELECT DISTINCT BILL_NUM,ACCT_NUM,DISCOUNT_DATE
                  FROM SMTMODS.L_AGRE_BILL_CONTRACT A -- 票据合同信息表
                 WHERE DATA_DATE = I_DATE ) DDD	  -- 票据合同信息表   ADD WANGC 20241217 
      ON DDD.BILL_NUM||DDD.ACCT_NUM=A.DRAFT_NBR||A.DRAFT_RNG -- JLBA202412200001 20250116 王金保修改 修改一表通6.14 贴现日期，参考EAST分段式区间
    LEFT JOIN SMTMODS.L_AGRE_BILL_CONTRACT E -- 票据合同信息表  -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐
      ON A.ACCT_NUM = E.BILL_NUM
     AND A.DRAFT_RNG= E.ACCT_NUM
     AND E.DATA_DATE = I_DATE
            -- AND E.BUSI_DATE = I_DATE
     AND E.TRADE_DIRECT ='TDD01' -- 买入
     AND E.ACCOUNT_STATUS = '02'
    LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') C
      ON A.CUST_ID =C.CUST_ID
     AND C.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_FINA_INNER F   -- 内部科目对照表
      ON A.ITEM_CD = F.STAT_SUB_NUM
     AND A.ORG_NUM = F.ORG_NUM
     AND F.DATA_DATE = I_DATE  
    LEFT JOIN SMTMODS.L_ACCT_OBS_LOAN T
      ON A.ACCT_NUM=T.ACCT_NO
     AND T.DATA_DATE = I_DATE 
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
      ON A.ORG_NUM = ORG.ORG_NUM
     AND ORG.DATA_DATE = I_DATE    
    LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G  -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐  -- 刘洋：商票取出票人授信
      ON B.AFF_CODE = G.CUST_ID
     AND G.FACILITY_TYP IN ('2','4')
     AND G.DATA_DATE = I_DATE 
    LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G1 -- [20250627][姜俐锋][JLBA202504160004][吴大为]:修改授信ID取数逻辑
      ON b.pay_cusid = G1.CUST_ID 
     AND G1.DATA_DATE = I_DATE 
   WHERE A.DATA_DATE = I_DATE
     AND SUBSTR(A.ITEM_CD,1,6) IN ('130102','130105')
     AND (A.ACCT_STS <> '3' OR
          A.LOAN_ACCT_BAL > 0 OR
          SUBSTR(A.FINISH_DT,1,4) = SUBSTR(I_DATE,1,4) ) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求:结清日期取当年
     AND NOT EXISTS (SELECT 1 FROM YBT_DATACORE.T_6_14 T1 WHERE T1.DIS_DATA_DATE = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AND SUBSTR(A.ACCT_NUM || NVL(A.DRAFT_RNG,''),1,60) = T1.F140001 and  ORG.ORG_ID= T1.F140002);
	 -- [20250513][狄家卉][JLBA202504060003][吴大为]:  按照协议ID，机构ID判断条件，已经做卖断不在此段，即报送不在第一二段存在
	 
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '4、回购';
	
 INSERT INTO T_6_14
 (
    F140001    , -- 01 '协议ID'
	F140002    , -- 02 '机构ID'
	F140003    , -- 03 '票据号码'
	F140004    , -- 04 '票据类型'
	F140005    , -- 05 '协议币种'
	F140006    , -- 06 '票面金额'
	F140007    , -- 07 '票据签发日期'
	F140008    , -- 08 '票据到期日期'
	F140009    , -- 09 '出票人名称'
	F140010    , -- 10 '承兑人名称'
	F140011    , -- 11 '贴现人名称'
	F140012    , -- 12 '贴现日期'
	F140013    , -- 13 '交易方向'
	F140014    , -- 14 '转贴现类型'
	F140015    , -- 15 '科目ID'
    F140016    , -- 16 '科目名称'
    F140017    , -- 17 '转贴现日期'
    F140018    , -- 18 '转贴现金额'
    F140019    , -- 19 '转贴现计息天数'
    F140020    , -- 20 '转贴现利率'
    F140021    , -- 21 '转贴现利息'
    F140022    , -- 22 '回购日期'
    F140023    , -- 23 '回购金额'
    F140024    , -- 24 '回购利率'
    F140025    , -- 25 '回购利息'
    F140026    , -- 26 '交易对手名称'
    F140027    , -- 27 '交易对手账号行号'
    F140028    , -- 28 '重点产业标识'
	F140029    , -- 29 '经办员工ID'
    F140030    , -- 30 '审查员工ID'
    F140031    , -- 31 '审批员工ID'
    F140032    , -- 32 '或有负债标识'
    F140033    , -- 33 '票据状态'
    F140034    , -- 34 '备注'
    F140035    , -- 35 '采集日期'
    DIS_DATA_DATE , -- 装入数据日期
    DIS_BANK_ID   , -- 机构号
    DIS_DEPT      ,
    DEPARTMENT_ID,  -- 业务条线
    F140036 ,-- 授信ID
    F140037-- 借据ID
 )
SELECT  
          SUBSTR(A.ACCT_NUM || B.BILL_NUM,1,60) AS F140001  , -- 01 '协议ID'    -- 合同号||票号    
	      ORG.ORG_ID    AS F140002 , -- 02 机构ID
	      B.BILL_NUM    AS F140003 , -- 03 票据号码
	      CASE WHEN B.BILL_TYPE='1' THEN '01' -- 银行承兑汇票
              WHEN B.BILL_TYPE='2' THEN '02' -- 商业承兑汇票
              END       AS F140004 , -- 04 票据类型
          B.CURR_CD     AS F140005 , -- 05 协议币种
	      B.AMOUNT      AS F140006 , -- 06 票面金额
	      TO_CHAR(TO_DATE(B.OPEN_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS F140007 , -- 07 票据签发日期
	      TO_CHAR(TO_DATE(B.MATU_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS F140008 , -- 08 票据到期日期
	      B.AFF_NAME    AS F140009               , -- 09 出票人名称
	      B.PAY_BANK_NAME  AS F140010            , -- 10 承兑人名称
	      B.DISCOUNT_APP_NAME AS F140011         , -- 11 贴现人名称
	      -- TO_CHAR(TO_DATE(NVL(B.DISCOUNT_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD'), -- 12 贴现日期
	      NVL(DDD.DISCOUNT_DATE,'9999-12-31'), -- 12 '贴现日期' -- JLBA202412200001 20250116 王金保修改 修改一表通6.14 贴现日期，参考EAST分段式区间
	      CASE WHEN SUBSTR(A.BUSI_TYPE,1,3) IN ('101','102') THEN '01' -- 买入
              WHEN SUBSTR(A.BUSI_TYPE,1,3) IN ('201','202') THEN '02' -- 卖出
              END            AS F140013        , -- 13 交易方向
	      CASE WHEN A.BUSI_TYPE='201' THEN '03' -- 质押式回购正回购
              WHEN A.BUSI_TYPE='101' THEN '04' -- 质押式回购逆回购
              WHEN A.BUSI_TYPE='202' THEN '05' -- 买断式回购正回购
              WHEN A.BUSI_TYPE='102' THEN '06' -- 买断式回购逆回购
              END             AS F140014        , -- 14 转贴现类型
	      A.GL_ITEM_CODE      AS F140015        , -- 15 科目ID
          F.GL_CD_NAME        AS F140016        , -- 16 科目名称
          TO_CHAR(TO_DATE(NVL(A.BEG_DT,'99991231'),'YYYYMMDD'),'YYYY-MM-DD') AS F140017, -- 17 转贴现日期
	      A.ATM               AS F140018        , -- 18 转贴现金额
	      A.INT_NUM_DATE      AS F140019        , -- 19 转贴现计息天数
	      A.REAL_INT_RAT      AS F140020        , -- 20 转贴现利率
	      A.REDISCOUNT_INTEREST AS F140021      , -- 21 转贴现利息
	      TO_CHAR(TO_DATE(NVL(A.END_DT,'99991231'),'YYYYMMDD'),'YYYY-MM-DD') AS F140022, -- 22 回购日期
	      A.AGREE_VAL         AS F140023        , -- 23 回购金额
	      A.PUR_RATE          AS F140024        , -- 24 回购利率
	      A.PUR_INT           AS F140025        , -- 25 回购利息
	      D.FINA_ORG_NAME     AS F140026        , -- 26 交易对手名称
	      -- NVL(E.CUST_BANK_CD,E.SWIFT_CODE)                           , -- 27 交易对手账号行号
          D.CUST_BANK_CD      AS F140027        , -- 27 '交易对手账号行号'
	      NULL                AS F140028        , -- 28 '重点产业标识' -- 默认为空
	      A.JBYG_ID           AS F140029        , -- 29 经办员工ID
          A.SZYG_ID           AS F140030        , -- 30 审查员工ID
	      A.SPYG_ID           AS F140031        , -- 31 审批员工ID
	      '0'                 AS F140032        , -- 32 或有负债标识 -- 默认0-否
           /*CASE 
           WHEN SUBSTR(A.BUSI_TYPE,1,3) IN ('101','102') THEN '01' -- 买入 -- 正常
           WHEN SUBSTR(A.BUSI_TYPE,1,3) IN ('201','202') THEN '02' -- 卖出 -- 卖断
            END                        , -- 33 '票据状态'*/
	      B.DRAFT_STATUS      AS F140033        , -- 33 '票据状态'     0628 WWK
	      NULL                AS F140034        , -- 34 备注
	      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), --  采集日期
	      TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
	      A.ORG_NUM                  , -- 机构号
	      '4、回购',
          '009804' ,                                       -- 业务条线  -- 金融市场部	
          NVL(E.FACILITY_NO,G.FACILITY_NO) AS F140036, --  授信ID  2.0 ZDSJ H -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐
          SUBSTR(A.ACCT_NUM || B.BILL_NUM,1,60) AS F140037 --    借据ID 2.0 ZDSJ H
     FROM SMTMODS.L_ACCT_FUND_REPURCHASE A -- 回购信息表
    INNER JOIN SMTMODS.L_AGRE_BILL_INFO B -- 商业汇票票面信息表
       ON A.SUBJECT_CD = B.BILL_NUM
      AND B.DATA_DATE = I_DATE
    INNER JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                  FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') D -- 全量客户信息表
       ON A.CUST_ID = D.CUST_ID
      AND D.DATA_DATE = I_DATE
     LEFT JOIN SMTMODS.L_AGRE_BILL_CONTRACT E -- 票据合同信息表  -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐
       ON A.ACCT_NUM = E.BILL_NUM
      AND E.DATA_DATE = I_DATE
      AND E.TRADE_DIRECT =(CASE WHEN SUBSTR(A.BUSI_TYPE,1,3) IN ('101','102') THEN 'TDD01' -- 买入
                                WHEN SUBSTR(A.BUSI_TYPE,1,3) IN ('201','202') THEN 'TDD02' -- 卖出
                                END)
      AND E.ACCOUNT_STATUS = '02'
     LEFT JOIN SMTMODS.L_FINA_INNER F
       ON A.GL_ITEM_CODE = F.STAT_SUB_NUM
      AND A.ORG_NUM = F.ORG_NUM
      AND F.DATA_DATE = I_DATE
     LEFT JOIN (SELECT DISTINCT BILL_NUM,ACCT_NUM,DISCOUNT_DATE
                  FROM SMTMODS.L_AGRE_BILL_CONTRACT A -- 票据合同信息表
                 WHERE DATA_DATE = I_DATE ) DDD	-- JLBA202412200001 20250116 王金保修改 修改一表通6.14 贴现日期，参考EAST分段式区间
       ON DDD.BILL_NUM||DDD.ACCT_NUM=A.SUBJECT_CD||A.DRAFT_RNG
     LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
       ON A.ORG_NUM = ORG.ORG_NUM
      AND ORG.DATA_DATE = I_DATE
     LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G  -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐  -- 刘洋：商票取出票人授信
       ON B.AFF_CODE = G.CUST_ID
      AND G.FACILITY_TYP IN ('2','4')
      AND G.DATA_DATE = I_DATE
    WHERE A.DATA_DATE = I_DATE
      AND SUBSTR(A.BUSI_TYPE,1,1) IN ('1','2') -- 1-买入返售 ;2-卖出回购
      AND A.ASS_TYPE = '2' -- 2-商业汇票  -- 债券报到8_7同业里面
      AND (A.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101' OR A.BALANCE > 0) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
       ; 

       CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);		

    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '5、再贴现';

 INSERT INTO T_6_14
 (
    F140001    , -- 01 '协议ID'
	F140002    , -- 02 '机构ID'
	F140003    , -- 03 '票据号码'
	F140004    , -- 04 '票据类型'
	F140005    , -- 05 '协议币种'
	F140006    , -- 06 '票面金额'
	F140007    , -- 07 '票据签发日期'
	F140008    , -- 08 '票据到期日期'
	F140009    , -- 09 '出票人名称'
	F140010    , -- 10 '承兑人名称'
	F140011    , -- 11 '贴现人名称'
	F140012    , -- 12 '贴现日期'
	F140013    , -- 13 '交易方向'
	F140014    , -- 14 '转贴现类型'
	F140015    , -- 15 '科目ID'
    F140016    , -- 16 '科目名称'
    F140017    , -- 17 '转贴现日期'
    F140018    , -- 18 '转贴现金额'
    F140019    , -- 19 '转贴现计息天数'
    F140020    , -- 20 '转贴现利率'
    F140021    , -- 21 '转贴现利息'
    F140022    , -- 22 '回购日期'
    F140023    , -- 23 '回购金额'
    F140024    , -- 24 '回购利率'
    F140025    , -- 25 '回购利息'
    F140026    , -- 26 '交易对手名称'
    F140027    , -- 27 '交易对手账号行号'
    F140028    , -- 28 '重点产业标识'
	F140029    , -- 29 '经办员工ID'
    F140030    , -- 30 '审查员工ID'
    F140031    , -- 31 '审批员工ID'
    F140032    , -- 32 '或有负债标识'
    F140033    , -- 33 '票据状态'
    F140034    , -- 34 '备注'
    F140035    , -- 35 '采集日期'
    DIS_DATA_DATE , -- 装入数据日期
    DIS_BANK_ID   , -- 机构号
    DIS_DEPT      ,
    DEPARTMENT_ID,  -- 业务条线
    F140036 ,-- 授信ID
    F140037-- 借据ID
 )
 SELECT  
         SUBSTR(A.ACCT_NUM || B.BILL_NUM,1,60) AS F140001 , -- 01 '协议ID'    -- 合同号||票号    
         -- E.CONTRACT_NO        , -- 01 '协议ID'   
	     ORG.ORG_ID     AS F140002 , -- 02 机构ID
	     B.BILL_NUM     AS F140003 , -- 03 票据号码
	     CASE WHEN B.BILL_TYPE='1' THEN '01' -- 银行承兑汇票
              WHEN B.BILL_TYPE='2' THEN '02' -- 商业承兑汇票
               END      AS F140004 , -- 04 票据类型
         B.CURR_CD      AS F140005 , -- 05 协议币种
	     B.AMOUNT       AS F140006 , -- 06 票面金额
	     TO_CHAR(TO_DATE(B.OPEN_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS F140007, -- 07 票据签发日期
	     TO_CHAR(TO_DATE(B.MATU_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS F140008, -- 08 票据到期日期
	     B.AFF_NAME     AS F140009 , -- 09 出票人名称
	     B.PAY_BANK_NAME AS F140010, -- 10 承兑人名称
	     B.DISCOUNT_APP_NAME AS F140011, -- 11 贴现人名称
	     -- TO_CHAR(TO_DATE(NVL(B.DISCOUNT_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD'), -- 12 贴现日期
	     TO_CHAR(TO_DATE(NVL(DDD.DISCOUNT_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD') AS F140012 , -- 12 贴现日期
         '02'            AS F140013     , -- 13 '交易方向'  --按EAST取 02-卖出
	     -- '09'             , -- 14 转贴现类型  --按EAST取 09-再贴现
	     '07'            AS F140014     , -- 14 转贴现类型  --按EAST取 09-再贴现  2.0ZDSJ H
	     A.GL_ITEM_CODE  AS F140015     , -- 15 科目ID
         F.GL_CD_NAME    AS F140016     , -- 16 科目名称
 	     TO_CHAR(TO_DATE(NVL(A.START_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD') AS F140017, -- 17 转贴现日期
	     A.AMT  * (CASE WHEN B.CURR_CD = A.CURR_CD THEN 1
                        WHEN B.CURR_CD <>'CNY' AND A.CURR_CD = 'CNY' THEN 1/U.CCY_RATE
                        WHEN B.CURR_CD <>'CNY' AND A.CURR_CD <>'CNY' THEN 1*U1.CCY_RATE/U.CCY_RATE
                        WHEN B.CURR_CD = 'CNY' AND A.CURR_CD <>'CNY' THEN 1*U1.CCY_RATE
                   END)  AS F140018            , -- 18 转贴现金额
	     A.INT_NUM_DATE  AS F140019            , -- 19 转贴现计息天数
	     A.REAL_INT_RAT  AS F140020            , -- 20 转贴现利率
	     A.REDISCOUNT_INTEREST       
                 *(CASE WHEN B.CURR_CD = A.CURR_CD THEN 1
                        WHEN B.CURR_CD <>'CNY' AND A.CURR_CD = 'CNY' THEN 1/U.CCY_RATE
                        WHEN B.CURR_CD <>'CNY' AND A.CURR_CD <>'CNY' THEN 1*U1.CCY_RATE/U.CCY_RATE
                        WHEN B.CURR_CD = 'CNY' AND A.CURR_CD <>'CNY' THEN 1*U1.CCY_RATE
                   END)  AS F140021            , -- 21 转贴现利息
	     '9999-12-31'    AS F140022            , -- 22 回购日期  --按EAST取 99991231
	     NULL            AS F140023            , -- 23 回购金额  --按EAST赋空值
	     NULL            AS F140024            , -- 24 回购利率  --按EAST赋空值
	     NULL            AS F140025            , -- 25 回购利息  --按EAST赋空值
	     D.FINA_ORG_NAME AS F140026            , -- 26 交易对手名称
	     -- NVL(E.CUST_BANK_CD,E.SWIFT_CODE)                           , -- 27 交易对手账号行号
	     D.CUST_BANK_CD  AS F140027            , -- 27 '交易对手账号行号'
	     NULL            AS F140028            , -- 28 '重点产业标识'
	     A.JBYG_ID       AS F140029            , -- 29 '经办员工ID'  -- 新增字段
         A.SZYG_ID       AS F140030            , -- 30 '审查员工ID'  -- 新增字段
         A.SPYG_ID       AS F140031            , -- 31 '审批员工ID'  -- 新增字段
	     '0'             AS F140032            , -- 32 或有负债标识 -- 默认0-否
	     -- '02'                                  , -- 33 '票据状态'  -- 卖断
	     B.DRAFT_STATUS  AS F140033            , -- '票据状态'    0627  WWK
	     NULL            AS F140034            , -- 34 备注
	     TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 49 采集日期
	     TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
	     A.ORG_NUM                             , -- 机构号
	     '5、再贴现',
	     '009804'  ,                                        -- 业务条线  -- 金融市场部
	     NVL(E.FACILITY_NO,G.FACILITY_NO) AS F140036, --  授信ID  2.0 ZDSJ H -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐
	     SUBSTR(A.ACCT_NUM || B.BILL_NUM,1,60) AS F140037 --    借据ID 2.0 ZDSJ H
    FROM SMTMODS.L_ACCT_FUND_MMFUND A -- 资金往来信息表
    LEFT JOIN SMTMODS.L_AGRE_BILL_INFO B -- 商业汇票票面信息表
      ON A.BILL_NUM = B.BILL_NUM
     AND B.DATA_DATE = I_DATE
   INNER JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') D -- 全量客户信息表
      ON A.CUST_ID = D.CUST_ID
     AND D.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_AGRE_BILL_CONTRACT E -- 票据合同信息表  -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐
      ON A.ACCT_NUM = E.BILL_NUM
           -- AND A.BILL_NUM= NVL(REPLACE(E.ACCT_NUM,'-',NULL),E.BILL_NUM)
     AND E.DATA_DATE = I_DATE
           -- AND E.BUSI_DATE = I_DATE
     AND E.TRADE_DIRECT ='TDD02' -- 卖出
     AND E.ACCOUNT_STATUS = '02'
    LEFT JOIN SMTMODS.L_PUBL_RATE U -- 银行挂牌汇率表
      ON U.BASIC_CCY = B.CURR_CD -- 基准币种
     AND U.CCY_DATE = I_DATE
     AND U.FORWARD_CCY='CNY'
    LEFT JOIN SMTMODS.L_PUBL_RATE U1 -- 银行挂牌汇率表
      ON U1.BASIC_CCY = B.CURR_CD -- 基准币种
     AND U1.CCY_DATE = I_DATE
     AND U1.FORWARD_CCY='CNY'
    LEFT JOIN SMTMODS.L_FINA_INNER F   -- 内部科目对照表
      ON A.GL_ITEM_CODE = F.STAT_SUB_NUM
     AND A.ORG_NUM = F.ORG_NUM
     AND F.DATA_DATE = I_DATE
    LEFT JOIN (SELECT DISTINCT BILL_NUM,ACCT_NUM,DISCOUNT_DATE
                 FROM SMTMODS.L_AGRE_BILL_CONTRACT A -- 票据合同信息表
                WHERE DATA_DATE = I_DATE ) DDD	-- JLBA202412200001 20250116 王金保修改 修改一表通6.14 贴现日期，参考EAST分段式区间
      ON DDD.BILL_NUM||DDD.ACCT_NUM=A.BILL_NUM||A.DRAFT_RNG
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
      ON A.ORG_NUM = ORG.ORG_NUM
     AND ORG.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G  -- 20250116_ZHOULP_JLBA202408290021_金市需求二阶段_业务姚司桐  -- 刘洋：商票取出票人授信
      ON B.AFF_CODE = G.CUST_ID
     AND G.FACILITY_TYP IN ('2','4')
     AND G.DATA_DATE = I_DATE
   WHERE A.DATA_DATE = I_DATE
     AND A.ACCT_TYP IN ('20303','20304')
     AND (A.ACCT_CLDATE >= SUBSTR(I_DATE,1,4)||'0101' OR A.BALANCE > 0) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
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

