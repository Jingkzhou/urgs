DROP Procedure IF EXISTS `PROC_BSP_T_7_12_RZJY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_7_12_RZJY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回code
                                         OUT OI_REMESSAGE VARCHAR -- 返回message
                                         )
BEGIN
/******
      程序名称  ：融资交易
      程序功能  ：加工融资交易
      目标表：T_7_12
      源表  ：
      创建人  ：LZ
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
		-- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311
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
	SET P_PROC_NAME = 'PROC_BSP_T_7_12_RZJY';
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
	
	DELETE FROM T_7_12 WHERE G120031 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');												
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';

-- 存单投资与发行信息表  取存单发行
 INSERT INTO T_7_12 (
   G120001,  -- 01.交易ID
   G120002,  -- 02.机构ID
   G120003,  -- 03.交易对手ID
   G120004,  -- 04.融资业务ID
   G120005,  -- 05.交易对手名称
   G120006,  -- 06.交易对手账号
   G120007,  -- 07.交易对手账号行号
   G120008,  -- 08.交易对手大类
   G120009,  -- 09.交易对手小类
   G120010,  -- 10.交易对手评级
   G120011,  -- 11.交易对手评级机构
   G120012,  -- 12.交易对手开户行名
   G120013,  -- 13.本方清算账号
   G120014,  -- 14.产品名称
   G120015,  -- 15.交易方向
   G120016,  -- 16.账户类型
   G120017,  -- 17.交易日期
   G120018,  -- 18.生效日期
   G120019,  -- 19.到期日期
   G120020,  -- 20.交易币种
   G120021,  -- 21.交易金额
   G120022,  -- 22.对应融资产品ID
   G120023,  -- 23.融资工具类型
   G120024,  -- 24.融资工具子类型
   G120025,  -- 25.押品类型
   G120026,  -- 26.经办员工ID
   G120027,  -- 27.审查员工ID
   G120028,  -- 28.审批员工ID
   G120029,  -- 29.或有负债标识
   G120030,  -- 30.备注
   G120031,  -- 31.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DIS_DEPT       ,
     DEPARTMENT_ID  -- 业务条线
) 
     SELECT 
           -- T.REF_NUM                     , -- 01 '交易ID'
            NVL(T.TXN_NO,T.REF_NUM),              -- JLBA202411080004 20241217 HMC
            ORG.ORG_ID                    , -- 02 '交易机构ID'
            -- T.CONT_PARTY_CODE             , -- 03 '交易对手ID'
			I.CUST_ID, -- 03 '交易对手ID' 
            -- A.ACCT_NUM || A.CDS_NO        , -- 04 '融资业务ID'
            -- FUNC_SUBSTR(A.ACCT_NUM || A.CONT_PARTY_NAME,60) ,-- 01 '融资业务ID' -- 账号拼交易对手名称 参照4.3,应与8.9同步   按常城要求截取60位
			A.RZYW_ID ,  -- 04 '融资业务ID'
            T.CONT_PARTY_NAME             , -- 05 '交易对手名称'
            T.OPPO_ACCT_NUM               , -- 06 '交易对手账号'
            T.CTPY_OPEN_BANK              , -- 07 '交易对手账号行号'
            /*A.CONT_PARTY_TYPE             , -- 08 '交易对手大类'
            A.CONT_PARTY_TYPE             , -- 09 '交易对手小类'*/
            -- 20241024_ZHOULP_JLBA202409030008_交易对手大类小类
            M1.GB_CODE                    , -- 08 '交易对手大类'
            M2.GB_CODE                    , -- 09 '交易对手小类'
            T.CTPY_RISK_RATING            , -- 10 '交易对手评级'
            T.CTPY_RATING_ORG             , -- 11 '交易对手评级机构'
            T.CTPY_OPEN_BANK_NA           , -- 12 '交易对手开户行名'
            -- T.INNER_SETTLE_ACCNUM         , -- 13 '本方清算账号'
            '9019801014070300003'         , -- 13 '本方清算账号'  -- 同业金融部默认9019801014070300003
            A.STOCK_NAM                   , -- 14 '产品名称'
            CASE 
              WHEN T.TRADE_DIRECT = '0' -- 0-结清（卖出）
                 THEN '01'   -- 01-买入
              WHEN T.TRADE_DIRECT = '1' -- 1-发生（买入）
                 THEN '02'   -- 02-卖出
            END                           , -- 15 '交易方向'
           /*  CASE 
              WHEN T.ACCT_TYPE = '2' -- 2-银行账户
                 THEN '01'   -- 01-银行账户
              WHEN T.ACCT_TYPE = '1' -- 1-交易账户
                 THEN '02'   -- 02-交易账户
            END                           , -- 16 '账户类型' */ 
			 CASE                                       -- 20240926 HMC
              WHEN A.BOOK_TYPE = '2' -- 2-银行账户
                 THEN '01'   -- 01-银行账户
              WHEN A.BOOK_TYPE = '1' -- 1-交易账户
                 THEN '02'   -- 02-交易账户
            END                           , -- 16 '账户类型'
            TO_CHAR(TO_DATE(T.TRAN_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 17 '交易日期'
           -- TO_CHAR(TO_DATE(A.INT_ST_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 18 '生效日期'
		    -- TO_CHAR(TO_DATE(A.SXRQ,'YYYYMMDD'),'YYYY-MM-DD'), -- 18 '生效日期'  20240926 HMC
		    TO_CHAR(TO_DATE(T.TRAN_DT,'YYYYMMDD'),'YYYY-MM-DD'),-- 18 '生效日期' 与大为哥确认 交易日期与生效日期相同，生效日期意为融资到账日期 20241115
            TO_CHAR(TO_DATE(NVL(A.MATURITY_DT,'99991231'),'YYYYMMDD'),'YYYY-MM-DD'), -- 19 '到期日期'
            T.CURR_CD                     , -- 20 '交易币种'
            T.AMOUNT                      , -- 21 '交易金额'
            A.CDS_NO                      , -- 22 '对应融资产品ID'
            '01'                          , -- 23 '融资工具类型'  -- 存单
            '012'                         , -- 24 '融资工具子类型' -- 同业存单
            NULL                          , -- 25 '押品类型' -- 默认空值
            M3.GB_CODE                    , -- 26 '经办员工ID'
            M4.GB_CODE                    , -- 27 '审查员工ID'
            M5.GB_CODE                    , -- 28 '审批员工ID'
            '1'                           , -- 29 '或有负债标识'  -- 表外取1-是  表内取0-否
            NULL                          , -- 30 '备注'
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 31 '采集日期'    
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
		    T.ORG_NUM                                       , -- 机构号
		  --  NULL,
		   T.PRODUCT_NAME,   -- 一表通自营资金转EAST排除核心流水 -- JLBA202411080004 20241217 HMC
		    CASE 
              WHEN T.ORG_NUM = '009804' THEN '009804' -- 金融市场部
              WHEN T.ORG_NUM = '009820' THEN '009820' -- 同业金融部
            END   -- 业务条线
   FROM SMTMODS.L_TRAN_FUND_FX T -- 资金交易信息表
 INNER JOIN SMTMODS.L_ACCT_FUND_CDS_BAL A -- 存单投资与发行信息表
        ON T.CONTRACT_NUM = A.CDS_NO
		AND  T.CONT_PARTY_NAME=A.CONT_PARTY_NAME  
        -- 这几个条件分别都试过了，都没数据
        -- ON T. REF_NUM = A.CDS_NO
        -- ON T. REF_NUM = A.ACCT_NUM
        -- ON T. CONTRACT_NUM = A.ACCT_NUM
        AND A.DATA_DATE = I_DATE 
  LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.ECIF_CUST_ID ORDER BY A.ECIF_CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B1
    ON A.CUST_ID = B1.ECIF_CUST_ID
  LEFT JOIN (SELECT * FROM (SELECT A.*,ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
                   FROM SMTMODS.L_CUST_BILL_TY A WHERE A.DATA_DATE = I_DATE) B WHERE B.RN = '1') B2
    ON A.CUST_ID = B2.CUST_ID
  LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
    ON T.ORG_NUM = ORG.ORG_NUM
   AND ORG.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_CUST_ALL I   
    ON  A.CUST_ID=I.CUST_ID AND 
       I.DATA_DATE=I_DATE
         AND T.ORG_NUM NOT LIKE '5%'    
         AND T.ORG_NUM NOT LIKE '6%'
  LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M1 
    ON M1.L_CODE_TABLE_CODE = 'V0003' 
   AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M1.L_CODE
  LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M2 
    ON M2.L_CODE_TABLE_CODE = 'V0004' 
   AND NVL(B1.DEPT_TYPE,B2.DEPT_TYPE) = M2.L_CODE
  LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M3 
    ON M3.L_CODE_TABLE_CODE = 'C0013' 
   AND A.JBYG_ID = M3.L_CODE   
  LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M4 
    ON M4.L_CODE_TABLE_CODE = 'C0013' 
   AND A.SZYG_ID = M4.L_CODE 
  LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M5 
    ON M4.L_CODE_TABLE_CODE = 'C0013' 
   AND A.SPYG_ID = M5.L_CODE   
 WHERE T.DATA_DATE = I_DATE
   AND A.PRODUCT_PROP = 'B';-- 同业存单发行
       
 -- ADD BY WJB 20240708 一表通2.0升级：补充开发大额存单，转股协议存款 ('20110211' 转股协议存款 ,'20110113' 发行个人大额存单 ,'20110208' 发行单位大额存单)

 INSERT INTO T_7_12 (
   G120001,  -- 01.交易ID
   G120002,  -- 02.机构ID
   G120003,  -- 03.交易对手ID
   G120004,  -- 04.融资业务ID
   G120005,  -- 05.交易对手名称
   G120006,  -- 06.交易对手账号
   G120007,  -- 07.交易对手账号行号
   G120008,  -- 08.交易对手大类
   G120009,  -- 09.交易对手小类
   G120010,  -- 10.交易对手评级
   G120011,  -- 11.交易对手评级机构
   G120012,  -- 12.交易对手开户行名
   G120013,  -- 13.本方清算账号
   G120014,  -- 14.产品名称
   G120015,  -- 15.交易方向
   G120016,  -- 16.账户类型
   G120017,  -- 17.交易日期
   G120018,  -- 18.生效日期
   G120019,  -- 19.到期日期
   G120020,  -- 20.交易币种
   G120021,  -- 21.交易金额
   G120022,  -- 22.对应融资产品ID
   G120023,  -- 23.融资工具类型
   G120024,  -- 24.融资工具子类型
   G120025,  -- 25.押品类型
   G120026,  -- 26.经办员工ID
   G120027,  -- 27.审查员工ID
   G120028,  -- 28.审批员工ID
   G120029,  -- 29.或有负债标识
   G120030,  -- 30.备注
   G120031,  -- 31.采集日期
   DIS_DATA_DATE , -- 装入数据日期
   DIS_BANK_ID   , -- 机构号
   DIS_DEPT      ,
   DEPARTMENT_ID   -- 业务条线
) 
     SELECT 
            T.REFERENCE_NUM               , -- 01 '交易ID'
            ORG.ORG_ID                    , -- 02 '交易机构ID'
            -- T.OPPO_ACCT_NUM               , -- 03 '交易对手ID'
			I.CUST_ID, -- 03 '交易对手ID'
            -- T.ACCOUNT_CODE || T.OPPO_ACCT_NAM ,-- 04 '融资业务ID' -- 账号拼交易对手名称 参照4.3,应与8.9同步
            T.ACCOUNT_CODE                ,-- 04 '融资业务ID' -- 账号拼交易对手名称 参照4.3,应与8.9同步
            T.OPPO_ACCT_NAM               , -- 05 '交易对手名称'
            SUBSTR(T.OPPO_ACCT_NUM,1,30)  , -- 06 '交易对手账号'
            T2.BANK_CD                    , -- 07 '交易对手账号行号' -- [20251028][巴启威][JLBA202509280009][吴大为]: 发行大额存单部分，交易对手账号均为我行账号，通过关联账户表，补充交易对手账号行号
            -- 20241024_ZHOULP_JLBA202409030008_交易对手大类小类
            M1.GB_CODE                    , -- 08 '交易对手大类'
            M2.GB_CODE                    , -- 09 '交易对手小类'

            ''                            , -- 10 '交易对手评级'
            ''                            , -- 11 '交易对手评级机构'
            T.OPPO_ORG_NAM                , -- 12 '交易对手开户行名'
            '9019801014070300003'         , -- 13 '本方清算账号'  -- 同业金融部默认9019801014070300003
            T.TRAN_CODE_DESCRIBE          , -- 14 '产品名称'
            CASE 
              WHEN T.CD_TYPE = '1' -- 0-结清（卖出）
                 THEN '01'   -- 01-买入
              WHEN T.CD_TYPE = '2' -- 1-发生（买入）
                 THEN '02'   -- 02-卖出
            END                           , -- 15 '交易方向'
            /*CASE 
              WHEN T.ACCT_TYPE = '2' -- 2-银行账户
                 THEN '01'   -- 01-银行账户
              WHEN T.ACCT_TYPE = '1' -- 1-交易账户
                 THEN '02'   -- 02-交易账户
            END                           , -- 16 '账户类型'  
            */
            '02',  -- 02-交易账户                         , -- 16 '账户类型' 
            -- T.TRAN_DT                     , -- 17 '交易日期'
            TO_CHAR(TO_DATE(T.TX_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 17 '交易日期'
            -- TO_CHAR(TO_DATE(A.ACCT_OPDATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 18 '生效日期' 
            TO_CHAR(TO_DATE(T.TX_DT,'YYYYMMDD'),'YYYY-MM-DD'),-- 18 '生效日期' 与大为哥确认 交易日期与生效日期相同，生效日期意为融资到账日期 20241115
            TO_CHAR(TO_DATE(NVL(A.MATUR_DATE,'99991231'),'YYYYMMDD'),'YYYY-MM-DD'), -- 19 '到期日期'
            T.CURRENCY                    , -- 20 '交易币种'
            T.TRANS_AMT                   , -- 21 '交易金额'
            A.POC_INDEX_CODE              , -- 22 '对应融资产品ID'  暂无该字段  MODIFY 20241227
            '01'                          , -- 23 '融资工具类型'  -- 存单
            '011'                         , -- 24 '融资工具子类型' -- 同业存单
            NULL                          , -- 25 '押品类型' -- 默认空值
            '自动'                         , -- 26 '经办员工ID' [20251028][巴启威][JLBA202509280009][吴大为]: 默认为自动
            '自动'                         , -- 27 '审查员工ID' [20251028][巴启威][JLBA202509280009][吴大为]: 默认为自动
            '自动'                         , -- 28 '审批员工ID' [20251028][巴启威][JLBA202509280009][吴大为]: 默认为自动
            '0'                          , -- 29 '或有负债标识'  -- 表外取1-是  表内取0-否
            NULL                           , -- 30 '备注'
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 31 '采集日期'    
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'), -- 装入数据日期
		    T.ORG_NUM                                       , -- 机构号
		    NULL,		     		    
 		    CASE 
               WHEN T.ORG_NUM = '009804' THEN '009804' -- 金融市场部
               WHEN T.ORG_NUM = '009820' THEN '009820' -- 同业金融部
             END   -- 业务条线
    FROM SMTMODS.L_TRAN_TX T -- 交易信息表
      INNER JOIN SMTMODS.L_ACCT_DEPOSIT A -- 存款账户信息表
        ON T. ACCOUNT_CODE = A.ACCT_NUM
        AND A.DATA_DATE = I_DATE
      LEFT JOIN YBT_DATACORE.VIEW_L_PUBL_ORG_BRA ORG
        ON T.ORG_NUM = ORG.ORG_NUM
        AND ORG.DATA_DATE = I_DATE
		LEFT JOIN ( SELECT  * FROM (SELECT T.*,ROW_NUMBER() OVER(PARTITION BY T.ID_NO ORDER BY T.CUST_ID) RN
                   FROM SMTMODS.L_CUST_ALL T WHERE T.DATA_DATE=I_DATE AND T.ORG_NUM NOT LIKE '5%' AND 
      T.ORG_NUM NOT LIKE '6%' AND T.CUST_STS<>'C') B WHERE B.RN = '1' ) I   
      ON  T.COUNTPTY_IDENTI=I.ID_NO
      LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M1 
        ON M1.L_CODE_TABLE_CODE = 'V0003' 
       AND I.DEPT_TYPE = M1.L_CODE   -- 国民经济部门分类
      LEFT JOIN YBT_DATACORE.M_DICT_CODETABLE M2 
        ON M2.L_CODE_TABLE_CODE = 'V0004' 
       AND I.DEPT_TYPE = M2.L_CODE   -- 国民经济部门分类
      -- [20251028][巴启威][JLBA202509280009][吴大为]: 增加关联表 t1 t2, 用来获取 交易对手账号行号
      LEFT JOIN SMTMODS.L_ACCT_DEPOSIT t1
            ON t1.acct_num = T.OPPO_ACCT_NUM
            AND t1.DATA_DATE= I_DATE
      LEFT JOIN SMTMODS.L_PUBL_ORG_BRA t2
             ON t1.ORG_NUM = t2.ORG_NUM
            AND T2.DATA_DATE = I_DATE 
     WHERE T.DATA_DATE = I_DATE
       AND A.GL_ITEM_CODE IN ('20110211','20110113','20110208') -- ('20110211' 转股协议存款 ,'20110113' 发行个人大额存单 ,'20110208' 发行单位大额存单)
       AND A.ACCT_BALANCE <> '0'
       AND T.TRAN_CODE_DESCRIBE NOT IN  ('利息结息','冲正-利息结息','冲正-大额存单支取','利息结息入账') -- MODIFY 20241227 
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

