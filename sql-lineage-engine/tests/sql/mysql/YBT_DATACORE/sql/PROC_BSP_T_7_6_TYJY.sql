DROP Procedure IF EXISTS `PROC_BSP_T_7_6_TYJY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_7_6_TYJY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：同业交易
      程序功能  ：加工同业交易
      目标表：T_7_6
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
 -- JLBA202501260004_关于一表通监管报送系统(同业金融部)同业交易表交易对手账号行号取值逻辑变更的需求_20250225
 -- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311
 /* 需求编号：JLBA202502210009 上线日期：20250415，修改人：姜俐锋，提出人：吴大为 
  * 需求编号：JLBA202504060003 上线日期：20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求 */
 /* 需求编号：JLBA202507250003 上线日期：2025-09-09，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统修改取数逻辑的需求*/
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
	SET P_PROC_NAME = 'PROC_BSP_T_7_6_TYJY';
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
	
	DELETE FROM T_7_6 WHERE G060023 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');										
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '插入回购信息表';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	
### 1、回购信息表
 INSERT INTO T_7_6 
 (
  G060001   , -- 01 '交易ID'
  G060002   , -- 02 '同业业务ID'
  G060003   , -- 03 '交易机构ID'
  G060004   , -- 04 '交易机构名称'
  G060005   , -- 05 '交易账号'
  G060006   , -- 06 '交易金额'
  G060007   , -- 07 '交易方向'
  G060008   , -- 08 '币种'
  G060009   , -- 09 '交易日期'
  G060010   , -- 10 '交易时间'
  G060011   , -- 11 '科目ID'
  G060012   , -- 12 '科目名称'
  G060024   , -- 24 '交易对手ID'
  G060013   , -- 13 '交易对手名称'
  G060014   , -- 14 '交易对手大类'
  G060025   , -- 25 '交易对手小类' 
  G060015   , -- 15 '交易对手评级'
  G060016   , -- 16 '交易对手评级机构'
  G060017   , -- 17 '交易对手账号行号'
  G060018   , -- 18 '交易对手账号'
  G060019   , -- 19 '交易对手账号开户行名称'
  G060020   , -- 20 '是否为“调整后存贷比口径”的调整项'
  G060021   , -- 21 '经办员工ID'
  G060022   , -- 22 '审批员工ID'
  G060026   , -- 26 '自营业务大类'
  G060027   , -- 27 '自营业务小类'
  G060028   , -- 28 '账户类型'
  G060029   , -- 29 '账户余额'
  G060030   , -- 30 '账户交易类型'
  G060031   , -- 31 '交易摘要'
  G060032   , -- 32 '客户备注'
  G060033   , -- 33 '冲补抹标志'
  G060034   , -- 34 '现转标志'
  G060035   , -- 35 '交易渠道'
  G060036   , -- 36 'IP 地址'
  G060037   , -- 37 'MAC地址'
  G060038   , -- 38 '外部账号（交易介质号）'
  G060023   , -- 23 '采集日期' 
  DIS_DATA_DATE , -- 装入数据日期
  DIS_BANK_ID   , -- 机构号
  DIS_DEPT      ,
  DEPARTMENT_ID  -- 业务条线
     )
  
     SELECT 
           NVL(T.TXN_NO,T.REF_NUM) ,
           -- T.REF_NUM                   , -- 01 '交易ID'  -- JLBA202411080004 20241217 HMC
           A.ACCT_NUM || A.REF_NUM     , -- 02 '同业业务ID'
           ORG.ORG_ID                  , -- 03 '交易机构ID'
           ORG.ORG_NAM                 , -- 04 '交易机构名称'
           T.REF_NUM  AS JYZH          , -- 05 '交易账号'
           T.AMOUNT                    , -- 06 '交易金额'
           CASE 
            WHEN T.ITEM_CD LIKE '1%' AND T.TRADE_DIRECT = '0' -- 结清（卖出）
              THEN '02' -- 卖出
            WHEN T.ITEM_CD LIKE '1%' AND T.TRADE_DIRECT = '1' -- 发生（买入）   --考虑资产、负债业务，资产端可以用现在的逻辑，业务发生（金额增加）买入，业务到期（金额减少）卖出；
              THEN '01' -- 买入
            WHEN T.ITEM_CD LIKE '2%' AND T.TRADE_DIRECT = '0' -- 结清（买入）
              THEN '01' -- 买入
            WHEN T.ITEM_CD LIKE '2%' AND T.TRADE_DIRECT = '1' -- 发生（卖出） --考虑资产、负债业务， 负债端采用现有相反逻辑，业务发生（金额增加）卖出，业务到期（金额减少）买入
              THEN '02' -- 卖出
           END                         , -- 07 '交易方向'
           T.CURR_CD                   , -- 08 '币种'
           TO_CHAR(TO_DATE(T.TRAN_DT,'YYYYMMDD'),'YYYY-MM-DD')  , -- 09 '交易日期'
           NVL(TIME_FORMAT(T.TRANS_TIME,'%H:%I:%S'),'00:00:00') , -- 10 '交易时间'
           T.ITEM_CD                   , -- 11 '科目ID'
           D.GL_CD_NAME                , -- 12 '科目名称'
           -- T.CONT_PARTY_CODE           , -- 24 '交易对手ID'
           T2.CUST_ID, -- 24 '交易对手ID'     -- 20240926 HMC   
           --  T.CONT_PARTY_NAME           , -- 13 '交易对手名称'
           T2.CUST_NAM                   , -- 13 '交易对手名称' -- 20241024_ZHOULP_JLBA202408290021_金市需求_业务姚司桐
           -- B.FINA_CODE_NEW             , -- 14 '交易对手大类'
           -- B.FINA_CODE_NEW             , -- 25 '交易对手小类' 
           /*NULL                        , -- 14 '交易对手大类'
           NULL                        , -- 25 '交易对手小类' */
           -- 20241024_ZHOULP_JLBA202409030008_交易对手大类小类
           CASE WHEN M1.GB_CODE IS NOT NULL THEN M1.GB_CODE
           WHEN T2.CUST_NAM LIKE '%理财%公司%' THEN '01' END AS G060014 , -- 14 '交易对手大类'
           CASE WHEN M2.GB_CODE IS NOT NULL THEN M2.GB_CODE
           WHEN T2.CUST_NAM LIKE '%理财%公司%' THEN '010908' END AS G060025, -- 25 '交易对手小类'
           T.CTPY_RISK_RATING          , -- 15 '交易对手评级'
           T.CTPY_RATING_ORG           , -- 16 '交易对手评级机构'
           SUBSTR(T.CTPY_OPEN_BANK,1,12)            , -- 17 '交易对手账号行号'
           T.OPPO_ACCT_NUM             , -- 18 '交易对手账号'
           T.CTPY_OPEN_BANK_NA         , -- 19 '交易对手账号开户行名称'
           '01'                        , -- 20 '是否为“调整后存贷比口径”的调整项'  -- 默认01-否
           -- T.TRAN_TELLER               , -- 21 '经办员工ID'
           G.GB_CODE                   , -- 21 '经办员工ID'
           G1.GB_CODE                  , -- 22 '审批员工ID'
           CASE 
             WHEN A.BUSI_TYPE LIKE '1%' THEN  '01' -- 买入返售
             WHEN A.BUSI_TYPE LIKE '2%' THEN  '02' -- 卖出回购
           END                         , -- 26 '自营业务大类' 
           T1.GB_CODE                  , -- 27 '自营业务小类'
           CASE       
                  WHEN A.BOOK_TYPE = '2' -- 2-银行账户
                 THEN '01'   -- 01-银行账户
                  WHEN A.BOOK_TYPE = '1' -- 1-交易账户
                 THEN '02'   -- 02-交易账户
           END                         , -- 28 '账户类型'
           A.BALANCE                   , -- 29 '账户余额'
           '01'                        , -- 30 '账户交易类型' -- 默认 01-转账
           T.SUMMARY                   , -- 31 '交易摘要'
           NULL                        , -- 32 '客户备注' -- 默认为空
           CASE 
             WHEN T.TRAN_STS='A' THEN '01'  -- 正常
             WHEN T.TRAN_STS IN('B','C','D') THEN '02' -- 冲补抹
           END                         , -- 33 '冲补抹标志'
           -- T.TRADE_MARK                , -- 34 '现转标志'
           '02'                        , -- 34 '现转标志' -- 默认 02-转账
           T.CHANNEL                   , -- 35 '交易渠道'
           NULL                        , -- 36 'IP 地址' -- 默认为空
           NULL                        , -- 37 'MAC地址' -- 默认为空
           A.ACCT_NUM                  , -- 38 '外部账号（交易介质号）'
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 23 '采集日期'   
           TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
       T.ORG_NUM                                       , -- 机构号
       '回购',
       CASE 
            WHEN T.ORG_NUM = '009804' THEN '009804' -- 金融市场部
            WHEN T.ORG_NUM = '009820' THEN '009820' -- 同业金融部
           END   -- 业务条线
    FROM SMTMODS.L_TRAN_FUND_FX T 
   INNER JOIN SMTMODS.L_ACCT_FUND_REPURCHASE A
      ON T.CONTRACT_NUM = A.ACCT_NUM
     AND A.DATA_DATE = I_DATE
    LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B1
      ON A.CUST_ID = B1.ECIF_CUST_ID
    LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B2
      ON A.CUST_ID = B2.CUST_ID
    LEFT JOIN SMTMODS.L_FINA_INNER D
      ON T.ITEM_CD = D.STAT_SUB_NUM
     AND T.ORG_NUM = D.ORG_NUM
     AND D.DATA_DATE = I_DATE
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
      ON T.ORG_NUM = ORG.ORG_NUM
     AND ORG.DATA_DATE = I_DATE
    LEFT JOIN M_DICT_CODETABLE G  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 映射康兴员工号
      ON T.TRAN_TELLER = G.L_CODE
     AND G.L_CODE_TABLE_CODE ='C0013'
    LEFT JOIN M_DICT_CODETABLE G1  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 映射康兴审批员工号
      ON T.APP_TELLER = G1.L_CODE
     AND G1.L_CODE_TABLE_CODE ='C0013'
    LEFT JOIN M_DICT_CODETABLE T1  -- 20240614 修改
      ON T.ITEM_CD = T1.L_CODE
     AND T1.L_CODE_TABLE_CODE = 'C0002'    -- 自营业务小类
    LEFT JOIN SMTMODS.L_CUST_ALL T2  
      ON A.CUST_ID=T2.CUST_ID
     AND T2.DATA_DATE=I_DATE
     AND T2.ORG_NUM NOT LIKE '5%'    
     AND T2.ORG_NUM NOT LIKE '6%'
    LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M1 
      ON M1.L_CODE_TABLE_CODE = 'V0003' 
     AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M1.L_CODE
    LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M2 
      ON M2.L_CODE_TABLE_CODE = 'V0004' 
     AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M2.L_CODE
   WHERE T.DATA_DATE = I_DATE
     AND SUBSTR(A.BUSI_TYPE,1,1) IN ('1','2') -- 1-买入返售 ;2-卖出回购
     AND A.ASS_TYPE IN ('1','2','3') -- 1-债券 2-商业汇票 3-其他票据-- 票据报到6_14票据再贴现里面 20240618因流动性指标 将票据放开
     AND (((A.ACCT_CLDATE > I_DATE OR A.ACCT_CLDATE IS NULL) AND A.BALANCE > 0) OR (A.ACCT_CLDATE = I_DATE AND A.BALANCE = 0) OR A.ACCRUAL <> 0) -- 与4.3，7.6同步  ALTER BY DJH 20240719 有利息无本金数据也加进来
     AND  A.END_DT>=I_DATE -- 9.2TONGBU 
     AND T.AMOUNT <> 0  --   -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 资金交易信息表中不取 开户 且交易金额为0的流水
     ;
     
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '插入资金往来信息表';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	
    ##   2.1、资金往来信息表  -- 资金交易信息表
INSERT INTO T_7_6 
 (
  G060001   , -- 01 '交易ID'
  G060002   , -- 02 '同业业务ID'
  G060003   , -- 03 '交易机构ID'
  G060004   , -- 04 '交易机构名称'
  G060005   , -- 05 '交易账号'
  G060006   , -- 06 '交易金额'
  G060007   , -- 07 '交易方向'
  G060008   , -- 08 '币种'
  G060009   , -- 09 '交易日期'
  G060010   , -- 10 '交易时间'
  G060011   , -- 11 '科目ID'
  G060012   , -- 12 '科目名称'
  G060024   , -- 24 '交易对手ID'
  G060013   , -- 13 '交易对手名称'
  G060014   , -- 14 '交易对手大类'
  G060025   , -- 25 '交易对手小类' 
  G060015   , -- 15 '交易对手评级'
  G060016   , -- 16 '交易对手评级机构'
  G060017   , -- 17 '交易对手账号行号'
  G060018   , -- 18 '交易对手账号'
  G060019   , -- 19 '交易对手账号开户行名称'
  G060020   , -- 20 '是否为“调整后存贷比口径”的调整项'
  G060021   , -- 21 '经办员工ID'
  G060022   , -- 22 '审批员工ID'
  G060026   , -- 26 '自营业务大类'
  G060027   , -- 27 '自营业务小类'
  G060028   , -- 28 '账户类型'
  G060029   , -- 29 '账户余额'
  G060030   , -- 30 '账户交易类型'
  G060031   , -- 31 '交易摘要'
  G060032   , -- 32 '客户备注'
  G060033   , -- 33 '冲补抹标志'
  G060034   , -- 34 '现转标志'
  G060035   , -- 35 '交易渠道'
  G060036   , -- 36 'IP 地址'
  G060037   , -- 37 'MAC地址'
  G060038   , -- 38 '外部账号（交易介质号）'
  G060023   , -- 23 '采集日期' 
  DIS_DATA_DATE , -- 装入数据日期
  DIS_BANK_ID   , -- 机构号
  DIS_DEPT      ,
  DEPARTMENT_ID  -- 业务条线
)
    SELECT 
        --   T.REF_NUM || A.REF_NUM      , -- 01 '交易ID'   -- 为了唯一 
          NVL(T.TXN_NO,T.REF_NUM || A.REF_NUM) AS G060001,               -- JLBA202411080004 20241217 HMC
          A.ACCT_NUM || A.REF_NUM     , -- 02 '同业业务ID'
          ORG.ORG_ID                  , -- 03 '交易机构ID'
          ORG.ORG_NAM                 , -- 04 '交易机构名称'
          T.REF_NUM  AS JYZH          , -- 05 '交易账号'
          T.AMOUNT                    , -- 06 '交易金额'
          CASE 
            WHEN T.ITEM_CD LIKE '1%' AND T.TRADE_DIRECT = '0' -- 结清（卖出）
              THEN '01' -- 买入
            WHEN T.ITEM_CD LIKE '1%' AND T.TRADE_DIRECT = '1' -- 发生（买入）   --考虑资产、负债业务，资产端可以用现在的逻辑，业务发生（金额增加）买入，业务到期（金额减少）卖出；
              THEN '02' -- 卖出
            WHEN T.ITEM_CD LIKE '2%' AND T.TRADE_DIRECT = '0' -- 结清（卖出）
              THEN '02' -- 卖出
            WHEN T.ITEM_CD LIKE '2%' AND T.TRADE_DIRECT = '1' -- 发生（买入） --考虑资产、负债业务， 负债端采用现有相反逻辑，业务发生（金额增加）卖出，业务到期（金额减少）买入
              THEN '01' -- 买入
           END                        , -- 07 '交易方向' -- 逻辑与描述不符，但按业务测试，这个逻辑是对的
          T.CURR_CD                   , -- 08 '币种'
          TO_CHAR(TO_DATE(T.TRAN_DT,'YYYYMMDD'),'YYYY-MM-DD')  , -- 09 '交易日期'
          NVL(TIME_FORMAT(T.TRANS_TIME,'%H:%I:%S'),'00:00:00') , -- 10 '交易时间'
          T.ITEM_CD                   , -- 11 '科目ID'
          D.GL_CD_NAME                , -- 12 '科目名称'
         -- T.CONT_PARTY_CODE           , -- 24 '交易对手ID'
          NVL(T3.CUST_ID,T4.CUST_ID),                   -- 24 '交易对手ID'  -- 20240926 HMC
          --  T.CONT_PARTY_NAME           , -- 13 '交易对手名称'
          NVL(T3.CUST_NAM,T4.CUST_NAM)                  , -- 13 '交易对手名称' -- 20241024_ZHOULP_JLBA202408290021_金市需求_业务姚司桐
          -- B.FINA_CODE_NEW             , -- 14 '交易对手大类'
          -- B.FINA_CODE_NEW             , -- 25 '交易对手小类' 
           /*NULL                        , -- 14 '交易对手大类'
           NULL                        , -- 25 '交易对手小类' */
          -- 20241024_ZHOULP_JLBA202409030008_交易对手大类小类
          CASE
           WHEN T.CUST_ID LIKE '2999%' THEN
             '01'  -- [20250513] [狄家卉] [JLBA202504060003][吴大为] 交易对手id开头是“2999”为我行内部户，默认交易对手大类为01-银行业金融机构
           WHEN M1.GB_CODE IS NOT NULL THEN
              M1.GB_CODE
           WHEN M3.GB_CODE IS NOT NULL THEN
              M3.GB_CODE 
           WHEN T3.CUST_NAM LIKE '%理财%公司%' THEN
             '01'
           END AS G060014 , -- 14 '交易对手大类'
           CASE WHEN M2.GB_CODE IS NOT NULL THEN M2.GB_CODE
                WHEN M4.GB_CODE IS NOT NULL THEN M4.GB_CODE
                WHEN T3.CUST_NAM LIKE '%理财%公司%' THEN '010908' END AS G060025, -- 25 '交易对手小类'
          T.CTPY_RISK_RATING          , -- 15 '交易对手评级'
          T.CTPY_RATING_ORG           , -- 16 '交易对手评级机构' 20250225
          CASE WHEN T.PRODUCT_NAME IS NULL THEN ORG.BANK_CD
               ELSE SUBSTR(T.CTPY_OPEN_BANK,1,12)  
                END AS G060017, -- 17 '交易对手账号行号'  [JLBA202507250003][20250909][巴启威]:交易对手开户行行号， 根据交易对手开户行名称逻辑，进行补充 
          CASE WHEN T.PRODUCT_NAME IS NULL THEN A.DEP_ACC_CODE
               ELSE T.OPPO_ACCT_NUM    
                END AS G060018, -- 18 '交易对手账号'  20250225
          CASE WHEN T.PRODUCT_NAME IS NULL THEN ORG.ORG_NAM
               ELSE T.CTPY_OPEN_BANK_NA    
                END AS G060019, -- 19 '交易对手账号开户行名称' 20250225
          '01'                        , -- 20 '是否为“调整后存贷比口径”的调整项'  -- 经同业金融部确认，默认01-否
         -- T.TRAN_TELLER               , -- 21 '经办员工ID'
          CASE WHEN T.PRODUCT_NAME IS NULL THEN NVL(T.TRAN_TELLER ,'自动')
           ELSE G.GB_CODE 
           END AS G060021            , -- 21 '经办员工ID' 20250311 核心流水T.PRODUCT_NAME 为空
          CASE WHEN T.PRODUCT_NAME IS NULL THEN NVL(T.APP_TELLER ,'自动')
           ELSE G1.GB_CODE       
           END AS G060022            , -- 22 '审批员工ID' 20250311
          CASE 
           WHEN SUBSTR(A.GL_ITEM_CODE, '1', '4') = '2003' AND A.ACCT_TYP = '20201' THEN '03' -- 拆入
           WHEN A.GL_ITEM_CODE = '20030105' THEN '03'                                        -- 拆入
           WHEN SUBSTR(A.GL_ITEM_CODE, '1', '4') = '1302' AND A.ACCT_TYP = '10201' THEN '04' -- 拆出
           WHEN SUBSTR(A.ACCT_TYP,1,3)  IN ('105','205') THEN '05'                           -- 同业借款
           WHEN A.GL_ITEM_CODE = '13020104' THEN '05'                                        -- 同业借款
           WHEN A.GL_ITEM_CODE IN ('20030102','20030106') THEN '05'                          -- 同业借款
           WHEN SUBSTR(A.GL_ITEM_CODE, '1', '4') IN ('1011','1031')  THEN '07'               -- 存放同业
           WHEN SUBSTR(A.GL_ITEM_CODE, '1', '4') = '2012' THEN '08'                          -- 同业存放
           WHEN SUBSTR(A.GL_ITEM_CODE, '1', '4') = '2004' THEN '11'                          -- 其他
          END                          , -- 26 '自营业务大类'
          T2.GB_CODE       , -- 27 '自营业务小类'
          -- T.ACCT_TYPE                 , -- 28 '账户类型'
          '01'                        , -- 28 '账户类型'  -- 经同业金融部确认，默认为01-银行账户
          A.BALANCE                   , -- 29 '账户余额'
          '01'                        , -- 30 '账户交易类型' -- 经同业金融部确认，默认01-转账
          -- T.SUMMARY                   , -- 31 '交易摘要'
          NULL                        , -- 31 '交易摘要' -- 经同业金融部确认，默认空
          NULL                        , -- 32 '客户备注' -- 经同业金融部确认，默认空
          CASE 
             WHEN T.TRAN_STS='A' THEN '01'  -- 正常
             WHEN T.TRAN_STS IN('B','C','D') THEN '02' -- 冲补抹
           END                         , -- 33 '冲补抹标志'
          -- T.TRADE_MARK                , -- 34 '现转标志'
          '02'                        , -- 34 '现转标志' -- 经同业金融部确认，默认02-转账
          -- T.CHANNEL                   , -- 35 '交易渠道'
          '01'                        , -- 35 '交易渠道' -- 经同业金融部确认，默认01-柜面
          NULL                        , -- 36 'IP 地址' -- 经同业金融部确认，默认空
          NULL                        , -- 37 'MAC地址' -- 经同业金融部确认，默认空
          A.ACCT_NUM                  , -- 38 '外部账号（交易介质号）'
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 23 '采集日期'   
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
          T.ORG_NUM                                       , -- 机构号  
          -- A.DATE_SOURCESD||'1' 
          '资金往来' AS DIS_DEPT,  -- 20241031  HMC 为了转换自营资金表和EAST康兴数据一致去掉新核心同业流水数据
          CASE   
            WHEN T.ORG_NUM = '009804' THEN '009804' -- 金融市场部
            WHEN T.ORG_NUM = '009820' THEN '009820' -- 同业金融部
            WHEN T.CURR_CD <> 'CNY' THEN '0098GJ' -- 国际业务（贸易金融）部
            WHEN SUBSTR(T.ITEM_CD,1,4) = '2004' THEN '0098PH' -- 普惠
            WHEN SUBSTR(T.ITEM_CD,1,4) IN ('1011','1031','2003','2012') THEN '009820' -- 同业金融部    
          END   -- 业务条线
    FROM SMTMODS.L_TRAN_FUND_FX T 
   INNER JOIN -- SMTMODS.L_ACCT_FUND_MMFUND A
       (SELECT * FROM SMTMODS.L_ACCT_FUND_MMFUND T
      WHERE T.DATA_DATE = I_DATE
      AND (((T.ACCT_CLDATE > I_DATE OR T.ACCT_CLDATE IS NULL) AND T.BALANCE > 0) 
           OR (T.ACCT_CLDATE = I_DATE AND T.BALANCE = 0)
           OR T.ACCRUAL <> 0)  -- 与4.3，7.6同步 ALTER BY DJH 20240719 有利息无本金数据也加进来
      AND (SUBSTR(T.GL_ITEM_CODE, '1', '4') = '2003'-- 拆入
           OR T.GL_ITEM_CODE = '20030105'            -- 拆入
           OR ( SUBSTR(T.GL_ITEM_CODE, '1', '4') = '1302' AND T.ACCT_TYP = '10201')  -- 拆出
           OR T.GL_ITEM_CODE IN ('13020102','13020104','13020106','20030102','20030104','20030106')-- 同业借入  同业借出
           OR T.GL_ITEM_CODE LIKE '101101%'OR T.GL_ITEM_CODE LIKE '101102%' OR T.GL_ITEM_CODE LIKE '1031%' -- 存放同业活期和存放同业定期
           OR SUBSTR(T.GL_ITEM_CODE, '1', '4') = '2012'   -- 同业存放
           OR T.GL_ITEM_CODE = '20040101' -- 向央行借款
           ) -- 同步9.2
      AND T.MATURE_DATE >= I_DATE  
      ) A -- 校验ID JYG06-45 JLBA202411070004  20241212
     -- ON T. REF_NUM = A.REF_NUM
      ON T.CONTRACT_NUM = A.ACCT_NUM
     AND A.DATA_DATE = I_DATE 
    LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B1
      ON T.CUST_ID = B1.ECIF_CUST_ID  -- [20250513] [狄家卉] [JLBA202504060003][吴大为] A.CUST_ID改用T.CUST_ID 关联 B1 B1 T3表
    LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B2
      ON T.CUST_ID = B2.CUST_ID       -- [20250513] [狄家卉] [JLBA202504060003][吴大为] A.CUST_ID改用 T.CUST_ID 关联 B1 B1 T3表
    LEFT JOIN SMTMODS.L_FINA_INNER D
      ON T.ITEM_CD = D.STAT_SUB_NUM
     AND T.ORG_NUM = D.ORG_NUM
     AND D.DATA_DATE = I_DATE
    LEFT JOIN SMTMODS.L_ACCT_INNER T1  -- 内部分户账 
      ON A.ACCT_NUM=T1.ACCT_NUM 
     AND T1.DATA_DATE = I_DATE
     AND T1.ACCT_NAME='吉林银行股份有限公司支小再贷款' 
    LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
      ON T.ORG_NUM = ORG.ORG_NUM
     AND ORG.DATA_DATE = I_DATE
    LEFT JOIN M_DICT_CODETABLE G
      ON T.TRAN_TELLER = G.L_CODE
     AND G.L_CODE_TABLE_CODE ='C0013'
    LEFT JOIN M_DICT_CODETABLE G1
      ON T.APP_TELLER = G1.L_CODE
     AND G1.L_CODE_TABLE_CODE ='C0013'
    LEFT JOIN M_DICT_CODETABLE T2  -- 20240614 修改
      ON T.ITEM_CD = T2.L_CODE
     AND T2.L_CODE_TABLE_CODE = 'C0002' -- 自营业务小类
    LEFT JOIN SMTMODS.L_CUST_ALL T3  -- 20240926 HMC
      ON T.CUST_ID=T3.CUST_ID    
     AND T3.DATA_DATE=I_DATE
     AND T3.ORG_NUM NOT LIKE '5%'    
     AND T3.ORG_NUM NOT LIKE '6%' 
     LEFT JOIN SMTMODS.L_CUST_ALL T4  
      ON A.CUST_ID=T4.CUST_ID      -- [20250513] [狄家卉] [JLBA202504060003][吴大为] A.CUST_ID补充 T.CUST_ID 关联
     AND T4.DATA_DATE=I_DATE
     AND T4.ORG_NUM NOT LIKE '5%'    
     AND T4.ORG_NUM NOT LIKE '6%' 
    LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M1 
      ON M1.L_CODE_TABLE_CODE = 'V0003' 
      AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M1.L_CODE
    LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M2 
      ON M2.L_CODE_TABLE_CODE = 'V0004' 
     AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M2.L_CODE
     LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B3
      ON A.CUST_ID = B3.CUST_ID     
       LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M3
      ON M3.L_CODE_TABLE_CODE = 'V0003' 
      AND B3.DEPT_TYPE = M3.L_CODE
    LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M4
      ON M4.L_CODE_TABLE_CODE = 'V0004' 
     AND B3.DEPT_TYPE = M4.L_CODE
   WHERE T.DATA_DATE = I_DATE
     AND T.TRAN_DT = I_DATE -- 资金交易时全量数据，应该加上交易日期。但是加上这个条件就没数据了，为了测试先注释掉
     ;
          
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '插入资金往来信息表';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
	
 

    #6.过程结束执行
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '过程结束执行';
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    SET OI_RETCODE = P_STATUS; 
    SET OI_REMESSAGE = P_DESCB;
    SELECT OI_RETCODE,'|',OI_REMESSAGE;
END $$

