DROP Procedure IF EXISTS `PROC_BSP_T_6_8_DBXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_8_DBXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：担保协议
      程序功能  ：加工担保协议
      目标表：T_6_8V
       业务范围  ： 表内、保函、信用证、银承，主合同有效切担保合同有效
      创建人  ：87V
      创建日期  ：20240111
      版本号：V0.0.1 
  ******/
	-- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116
	-- JLBA202501240018_关于一表通监管数据报送系统变更的需求_20250311
    /* 需求编号：JLBA202502210009 上线日期：20250415，修改人：姜俐锋，提出人：吴大为 */
    /* 需求编号：JLBA202504060003 上线日期：20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/
    /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
	/*需求编号：JLBA202507250003  上线日期：2025-09-09，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统修改取数逻辑的需求*/
	/*需求编号：JLBA202507300010 上线日期：2025-09-29，修改人：姜俐锋，提出人：信贷新增产品 修改原因：关于新一代信贷管理系统新增线上微贷板块的需求 */
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
   SELECT OI_RETCODE,'|',OI_REMESSAGE;		
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_8_DBXY';
	-- SET I_FLAG = 0;
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
 
	
    DELETE FROM TMP_6_8_CONTRACT;
    COMMIT;
    DELETE FROM TMP_6_8_FINREPINFO;
    COMMIT;
	DELETE FROM T_6_8 WHERE F080025 = TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD');
	COMMIT;
	
   	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);													

	
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '临时表数据插入';
	
	INSERT INTO TMP_6_8_CONTRACT
    (GUAR_CONTRACT_NUM, -- 担保合同号
     DBHTFX ,-- 担保合同方向
     DIS_DEPT
     )
    SELECT 
      DISTINCT 
      T3.GUAR_CONTRACT_NUM ,
      '01' AS FX , -- 表内 接受担保
      CASE WHEN T2.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T2.DEPARTMENTD ='公司金融' OR SUBSTR(T2.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T2.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T2.DEPARTMENTD ='普惠金融' THEN '0098PH'  -- 普惠金融部(0098PH)
           WHEN SUBSTR(T2.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T2.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           ELSE '009804'
           END AS DEPT
      FROM SMTMODS.L_AGRE_LOAN_CONTRACT T1 -- 贷款合同信息表
      INNER JOIN SMTMODS.L_ACCT_LOAN T2     -- 贷款借据表
        ON T1.CONTRACT_NUM = T2.ACCT_NUM
       AND T2.DATA_DATE = I_DATE
     INNER JOIN SMTMODS.L_AGRE_GUA_RELATION T3
        ON T1.CONTRACT_NUM = T3.CONTRACT_NUM
       AND T3.DATA_DATE = I_DATE
       AND T3.REL_STATUS = 'Y'-- [20250513] [狄家卉] [JLBA202504060003][吴大为]关联状态REL_STATUS为N，即引用类型代码为3解除引用，对应的担保合同也不需要报送了
     INNER JOIN SMTMODS.L_AGRE_GUARANTEE_RELATION T4
        ON T3.GUAR_CONTRACT_NUM = T4.GUAR_CONTRACT_NUM
       AND T4.DATA_DATE = I_DATE
     WHERE T1.DATA_DATE = I_DATE 
      -- AND T2.ACCT_STS <> '3'
	  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
      AND (T1.ACCT_STS='1' OR (T2.CANCEL_FLG = 'Y' AND   T1.CONTRACT_EXP_DT >= SUBSTR(I_DATE,1,4)||'0101') OR (T2.CANCEL_FLG = 'N' AND   T1.CONTRACT_EXP_DT  IS NULL AND (T2.LOAN_STOCKEN_DATE IS NULL OR T2.LOAN_STOCKEN_DATE >= SUBSTR(I_DATE,1,4)||'0101' ) )    -- add by haorui 20250311 JLBA202408200012 资产未转让
		   ) 
    UNION 
     SELECT DISTINCT 
     T3.GUAR_CONTRACT_NUM ,
     '02' AS FX ,-- 表外 出具担保
      CASE WHEN T1.DEPARTMENTD= '普惠金融' THEN '0098PH'  
           WHEN (T1.DEPARTMENTD= '公司金融' OR T1.DEPARTMENTD IS NULL ) THEN '0098JR' 
      END  AS DEPT
      FROM SMTMODS.L_ACCT_OBS_LOAN T1 -- 贷款表外信息表
     INNER JOIN SMTMODS.L_AGRE_GUA_RELATION T3 -- 业务合同与担保合同对应关系表
        ON T1.ACCT_NO = T3.CONTRACT_NUM
       AND T3.DATA_DATE = I_DATE
       AND T3.REL_STATUS = 'Y'-- [20250513] [狄家卉] [JLBA202504060003][吴大为]关联状态REL_STATUS为N，即引用类型代码为3解除引用，对应的担保合同也不需要报送了
     INNER JOIN SMTMODS.L_AGRE_GUARANTEE_RELATION T4 -- 担保合同与担保信息对应关系表
        ON T3.GUAR_CONTRACT_NUM = T4.GUAR_CONTRACT_NUM
       AND T4.DATA_DATE = I_DATE
     WHERE T1.DATA_DATE = I_DATE
       AND T3.CONTRACT_NUM_TYPE LIKE 'B%'
       -- AND T1.BUSI_STATUS='02'
       	AND T1.ACCT_STS = '1';
    COMMIT;
 
    
    INSERT INTO TMP_6_8_FINREPINFO
    (CUST_ID, -- 担保合同号
     CURR_CD ,
     DBRJZC   
     )
SELECT 
T.CUST_ID,
T.CURR_CD,
SUM (CASE WHEN ID_CODE = '9130' THEN ID_VAL
          WHEN ID_CODE = '9152' THEN - ID_VAL 
          END ) AS JINE
 FROM SMTMODS.L_CUST_C_FINREPINFO T
INNER JOIN (SELECT MAX (REPORT_YEAR) AS REPORT_YEAR,CUST_ID 
              FROM SMTMODS.L_CUST_C_FINREPINFO 
             WHERE DATA_DATE = I_DATE
               AND REPORT_TYP ='10'  
               AND ID_CODE IN ('9130' ,'9152')
             GROUP BY CUST_ID) A
   ON T.REPORT_YEAR = A.REPORT_YEAR
  AND T.CUST_ID =A.CUST_ID
WHERE DATA_DATE = I_DATE
  AND REPORT_TYP ='10'
  AND ID_CODE IN ('9130' ,'9152')
GROUP BY T.CUST_ID, T.CURR_CD; --  -- 20250415 [20250415][姜俐锋][JLBA202502210009][吴大为]: 取客户最新一期财报的数据 

    COMMIT;
    
		CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);			
	
	#3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
   INSERT  INTO T_6_8  (
           F080001  , -- 01 协议ID
           F080002  , -- 02 机构ID
           F080003  , -- 03 被担保协议ID
           F080004  , -- 04 担保类型
           F080005  , -- 05 担保合同方向
           F080006  , -- 06 被担保业务类型
           F080007  , -- 07 担保合同类型
           F080008  , -- 08 担保人类别
           F080009  , -- 09 担保人名称
           F080010  , -- 10 担保人证件类型
           F080011  , -- 11 担保人证件号码
           F080012  , -- 12 签约日期
           F080013  , -- 13 生效日期
           F080014  , -- 14 到期日期
           F080015  , -- 15 协议金额
           F080016  , -- 16 协议币种
           F080017  , -- 17 担保人净资产币种
           F080018  , -- 18 担保人净资产
           F080019  , -- 19 协议状态
           F080020  , -- 20 经办员工ID 
           F080021  , -- 21 审查员工ID
           F080022  , -- 22 审批员工ID
           F080023  , -- 23 或有负债标识
           F080024  , -- 24 备注
           F080025  , -- 25 采集日期
           DIS_DATA_DATE,
           DIS_BANK_ID,
           DEPARTMENT_ID,
           F080026,-- 担保人类型
           F080027,
           DIS_DEPT -- 担保人担保能力上限
       )
           
       
 SELECT    
     T1.GUAR_CONTRACT_NUM                     , -- 01 协议ID
     SUBSTR(TRIM(B.FIN_LIN_NUM ),1,11)||T1.ORG_NUM  , -- 02 机构ID 
     T3.CONTRACT_NUM                          , -- 03 被担保协议ID
     CASE 
             WHEN T1.GUAR_TYP='A0101' THEN '01'  -- 抵押
             WHEN T1.GUAR_TYP='B0101' THEN '02'  -- 质押
             WHEN T1.GUAR_TYP='C0101' THEN '03'  -- 单人保证
             WHEN T1.GUAR_TYP='C0201' THEN '04'  -- 多人保证
             WHEN T1.GUAR_TYP='C0301' THEN '05'  -- 多人联保
             WHEN T1.GUAR_TYP='C0302' THEN '07'  -- 混合
             WHEN T1.GUAR_TYP='C0401' THEN '06'  -- 多人分保
        END                                       , -- 04 担保类型
     '01'                                         , -- 05 担保合同方向 
     CASE   WHEN T3.CONTRACT_NUM_TYPE = 'A'   THEN '01' -- '表内信贷'
            WHEN T3.CONTRACT_NUM_TYPE = 'B01' THEN '02' -- '承兑汇票'
            WHEN T3.CONTRACT_NUM_TYPE = 'B02' THEN '03' -- '保函'
            WHEN T3.CONTRACT_NUM_TYPE = 'B03' THEN '04' -- '信用证'
            WHEN T3.CONTRACT_NUM_TYPE = 'B04' THEN '05' -- '贷款承诺'
            WHEN T3.CONTRACT_NUM_TYPE = 'B05' THEN '06' -- '委托贷款'
            WHEN T3.CONTRACT_NUM_TYPE = 'C'   THEN '07' -- '自营投资'
            WHEN T3.CONTRACT_NUM_TYPE = 'Z'   THEN '08' -- '其他'
            END                                  , -- 06 被担保业务类型
    CASE    WHEN T1.GUAR_CONTRACT_TYP ='A' THEN '01'
            WHEN T1.GUAR_CONTRACT_TYP ='B' THEN '02'
            END                                    , -- 07 担保合同类型
    CASE    WHEN T4.GUARANTEE_TYPE  = '00' THEN '02' -- '个人'
            WHEN T4.GUARANTEE_TYPE <> '00' THEN '01' -- '对公'    
            ELSE '03' -- '其他'
            END                                    , -- 08 担保人类别
     T4.GUARANTEE_NAME                             , -- 09 担保人名称
	 NVL(E.GB_CODE,F.GB_CODE)                      , -- 10 担保人证件类型
     CASE WHEN T4.GUARANTEE_TYPE = '12' THEN T4.GUARANTEE_FINA_NO
                 ELSE T4.GUARANTEE_ID_NO
            END			                             , -- 11 担保人证件号码
	-- TO_CHAR(TO_DATE(NVL(T1.GUAR_CONTRACT_SIGN_DT,T3.GUAR_START_DT),'YYYYMMDD'),'YYYY-MM-DD')  , -- 12 签约日期
    TO_CHAR(TO_DATE(COALESCE(T1.GUAR_CONTRACT_START_DT,T3.GUAR_START_DT,C.CONTRACT_EFF_DT),'YYYYMMDD'),'YYYY-MM-DD')  , -- 12 签约日期   -- 20250415 [20250415][姜俐锋][JLBA202502210009][吴大为]: 经李德超老师确认，CTRT_SIGN_DATE字段前台页面未启用，从逻辑中剔除，应取CONT_EFF_DATE，CTRT_SIGN_DATE字段
    TO_CHAR(TO_DATE(NVL(T3.GUAR_START_DT,C.CONTRACT_EFF_DT),'YYYYMMDD'),'YYYY-MM-DD')  , -- 13 生效日期   -- 20250415 [20250415][姜俐锋][JLBA202502210009][吴大为]:合同签订日期空取贷款合同生效日期
    CASE WHEN T3.GUAR_CONT_TYPE_CD='01' then '9999-12-31' -- [20250513] [狄家卉] [JLBA202504060003][吴大为] 一般担保合同，信贷系统没有到期日，到期日期的默认值9999-12-31
         ELSE  NVL(TO_CHAR(TO_DATE(NVL(T3.GUAR_EXPIRY_DT,C.CONTRACT_ORIG_MATURITY_DT),'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') 
    END                                              , -- 14 到期日期
    T1.GURA_CONTRACT_AMT                             , -- 15 协议金额
    T1.CURR_CD                                       , -- 16 协议币种
    /*CASE WHEN  A.DIS_DEPT = '0098JR' THEN  G.CURR_CD      
     ELSE NULL 
     END*/
     NVL(G.CURR_CD,'CNY')   AS   JZC_CURR_CD                , -- 17 担保人净资产币种   -- 20250415 [20250415][姜俐锋][JLBA202502210009][吴大为]:币种为空默认为 人民币 
    /*CASE WHEN  A.DIS_DEPT = '0098JR' THEN  G.DBRJZC      
     ELSE NULL 
     END*/
     G.DBRJZC  AS  DBRJZC                                   , -- 18 担保人净资产
	CASE WHEN T1.GUAR_CONTRACT_STATUS  ='Y' THEN '01'
	     WHEN T1.GUAR_CONTRACT_STATUS  ='N' THEN '04'   
	     END                                                , -- 19 协议状态												   
    CASE WHEN nvl(T1.JBYG_ID,C.JBYG_ID)='wd012601' THEN '自动'  -- 网贷崔永哲：虚拟操作员号 有一段时间业务流程里面没有客户经理编号 就直接塞这个操作号了，与苏桐确认，默认为自动
	     ELSE COALESCE(T1.JBYG_ID,C.JBYG_ID,T1.EMP_ID,C.STAFF_NUM )
	     END AS F080020 , -- 20 经办员工ID 
	NVL(T1.SCYG_ID,C.SCYG_ID)                               , -- 21 审查员工ID
    CASE WHEN C.CP_ID IN ('GX0120003000023','GX0120003000024') then '自动'    -- [20250513] [狄家卉] [JLBA202504060003][吴大为] GX0120003000023 吉享贷、GX0120003000024 吉用贷两个贷款产品空默认给自动
         ELSE
         COALESCE(T1.SPYG_ID,H.AUTHO_NAME,C.SPYG_ID)         
         END                                           , -- 22 审批员工ID  
    CASE WHEN A.DBHTFX ='02' THEN '1'
         WHEN A.DBHTFX ='01' THEN '0'
         END                                           , -- 23 或有负债标识 
    'A'                                                , -- 24 备注
	TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')   ,   -- 25 采集日期
    TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD')   ,   -- 25 采集日期
    T1.ORG_NUM,
    A.DIS_DEPT,
    CASE WHEN L.GOV_FLG = 'Y' THEN  '01'
    ELSE '02'
    END  AS DBRLX ,  -- 担保人类型  20250311
    T4.DBRDBNLSX ,  -- 担保人担保能力上限
    'A'
      FROM SMTMODS.L_AGRE_GUARANTEE_CONTRACT T1 -- 担保合同信息
      LEFT JOIN VIEW_L_PUBL_ORG_BRA T2
        ON T1.ORG_NUM = T2.ORG_NUM -- 机构表
       AND T2.DATA_DATE = I_DATE
	   
     INNER JOIN SMTMODS.L_AGRE_GUA_RELATION T3 -- 业务合同和担保合同对应关系表
        ON T1.GUAR_CONTRACT_NUM = T3.GUAR_CONTRACT_NUM
       AND T3.DATA_DATE = I_DATE
       AND T3.REL_STATUS = 'Y'-- [20250513] [狄家卉] [JLBA202504060003][吴大为]关联状态REL_STATUS为N，即引用类型代码为3解除引用，对应的担保合同也不需要报送了
	  LEFT JOIN SMTMODS.L_AGRE_GUARANTEE_RELATION T4 -- 担保合同与担保信息对应关系表
        ON T1.GUAR_CONTRACT_NUM = T4.GUAR_CONTRACT_NUM	  
	   AND T4.DATA_DATE = I_DATE
	   AND T4.REL_STATUS='Y'   -- 0627_LHY
	  LEFT JOIN SMTMODS.L_CUST_R_GUARANTY T5 -- 担保人信息表 
	    ON T4.GUAR_CUST_ID = T5.CUST_ID
	   AND T5.DATA_DATE = I_DATE
     INNER JOIN TMP_6_8_CONTRACT A -- 筛选合同表中存在的数据
        ON T1.GUAR_CONTRACT_NUM = A.GUAR_CONTRACT_NUM
      LEFT JOIN VIEW_L_PUBL_ORG_BRA B -- 机构表
        ON T1.ORG_NUM = B.ORG_NUM
       AND B.DATA_DATE = I_DATE       
	  LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT C  -- 贷款合同信息表 
        ON T3.CONTRACT_NUM=C.CONTRACT_NUM  
	   AND C.DATA_DATE = I_DATE
	  LEFT JOIN  SMTMODS.L_CUST_ALL D
        ON T4.GUAR_CUST_ID=D.CUST_ID
       AND D.DATA_DATE=I_DATE
      LEFT JOIN M_DICT_CODETABLE E
        ON T4.GUARANTEE_ID_TPYE=E.L_CODE
       AND E.L_CODE_TABLE_CODE='C0001'
      LEFT JOIN M_DICT_CODETABLE F
        ON D.ID_TYPE=F.L_CODE
       AND F.L_CODE_TABLE_CODE='C0001'
      LEFT JOIN TMP_6_8_FINREPINFO G
       -- ON G.CUST_ID = T4.GUAR_CUST_ID
        ON G.CUST_ID = T5.CUST_ID
      LEFT JOIN SMTMODS.L_AGRE_CREDITLINE H  -- 授信额度表     
        ON C.FACILITY_NO = H.FACILITY_NO
       AND H.DATA_DATE = I_DATE       
      LEFT JOIN FINANCE_COMPANY_LIST L -- 2.0 ZDSJ H
        ON TRIM(T4.GUARANTEE_NAME) = TRIM(L.COMPANY_NAME)
     WHERE T1.DATA_DATE = I_DATE
       AND T1.GUAR_CONTRACT_STATUS = 'Y'
       AND T1.GURA_CONTRACT_AMT <>0 -- 担保金额不允许为0
       AND (T1.GUAR_TYP NOT IN ('A0101','B0101') OR T1.GUAR_TYP IS NULL )
       AND (C.CONTRACT_EFF_DT <= I_DATE  OR C.CONTRACT_EFF_DT IS NULL ) --  [20250415][姜俐锋][JLBA202502210009][吴大为]: 一表通所有使用的担保合同和贷款合同，生效日期大于当前日期的，过滤掉
       AND (T3.GUAR_START_DT <= I_DATE  OR  T3.GUAR_START_DT IS NULL )  --  [20250415][姜俐锋][JLBA202502210009][吴大为]:一表通所有使用的担保合同和贷款合同，生效日期大于当前日期的，过滤掉
       AND T1.GUAR_TYP<>'D' -- [20250513][狄家卉][JLBA202504060003][吴大为]: (剔除信用保理)非担保类业务
       ; 
   
    
       COMMIT;

	   
     -- 如担保类型为低质押，填押品所有权人信息
     INSERT  INTO T_6_8  (
           F080001  , -- 01 协议ID
           F080002  , -- 02 机构ID
           F080003  , -- 03 被担保协议ID
           F080004  , -- 04 担保类型
           F080005  , -- 05 担保合同方向
           F080006  , -- 06 被担保业务类型
           F080007  , -- 07 担保合同类型
           F080008  , -- 08 担保人类别
           F080009  , -- 09 担保人名称
           F080010  , -- 10 担保人证件类型
           F080011  , -- 11 担保人证件号码
           F080012  , -- 12 签约日期
           F080013  , -- 13 生效日期
           F080014  , -- 14 到期日期
           F080015  , -- 15 协议金额
           F080016  , -- 16 协议币种
           F080017  , -- 17 担保人净资产币种
           F080018  , -- 18 担保人净资产
           F080019  , -- 19 协议状态
           F080020  , -- 20 经办员工ID 
           F080021  , -- 21 审查员工ID
           F080022  , -- 22 审批员工ID
           F080023  , -- 23 或有负债标识
           F080024  , -- 24 备注
           F080025  , -- 25 采集日期
           DIS_DATA_DATE,
           DIS_BANK_ID,
           DEPARTMENT_ID ,
           F080026,  -- 担保人类型
           F080027, --  担保人担保能力上限
           DIS_DEPT

       )   
   SELECT    
       T1.GUAR_CONTRACT_NUM                      , -- 01 协议ID
       SUBSTR(TRIM(B.FIN_LIN_NUM ),1,11) ||T1.ORG_NUM  , -- 02 机构ID 
       T3.CONTRACT_NUM                           , -- 03 被担保协议ID
       CASE 
             WHEN T1.GUAR_TYP='A0101' THEN '01'  -- 抵押
             WHEN T1.GUAR_TYP='B0101' THEN '02'  -- 质押
             WHEN T1.GUAR_TYP='C0101' THEN '03'  -- 单人保证
             WHEN T1.GUAR_TYP='C0201' THEN '04'  -- 多人保证
             WHEN T1.GUAR_TYP='C0301' THEN '05'  -- 多人联保
             WHEN T1.GUAR_TYP='C0302' THEN '07'  -- 混合
             WHEN T1.GUAR_TYP='C0401' THEN '06'  -- 多人分保
        END                                       , -- 04 担保类型
       '01'                                       , -- 05 担保合同方向 
        CASE 
	         WHEN T3.CONTRACT_NUM_TYPE = 'A'   THEN '01' -- '表内信贷'
             WHEN T3.CONTRACT_NUM_TYPE = 'B01' THEN '02' -- '承兑汇票'
             WHEN T3.CONTRACT_NUM_TYPE = 'B02' THEN '03' -- '保函'
             WHEN T3.CONTRACT_NUM_TYPE = 'B03' THEN '04' -- '信用证'
             WHEN T3.CONTRACT_NUM_TYPE = 'B04' THEN '05' -- '贷款承诺'
             WHEN T3.CONTRACT_NUM_TYPE = 'B05' THEN '06' -- '委托贷款'
             WHEN T3.CONTRACT_NUM_TYPE = 'C'   THEN '07' -- '自营投资'
             WHEN T3.CONTRACT_NUM_TYPE = 'Z'   THEN '08' -- '其他'
              END                                  , -- 06 被担保业务类型
       CASE WHEN T1.GUAR_CONTRACT_TYP ='A' THEN '01'
            WHEN T1.GUAR_CONTRACT_TYP ='B' THEN '02'
            END                                    , -- 07 担保合同类型
       CASE 
	        WHEN T7.CUST_TYPE  = '00' THEN '02' -- '个人'
            WHEN T7.CUST_TYPE <> '00' THEN '01' -- '对公' 
            ELSE '03'    
              END                                  , -- 08 担保人类别
       COALESCE (T7.CUST_NAM ,t8.CUST_NAM ,T4.GUARANTEE_NAME ) AS  DBRMC    , -- 09 担保人名称 [JLBA202507250003][20250909][巴启威]:补充取数
       COALESCE (E.GB_CODE,F.GB_CODE, T4.GUARANTEE_ID_TPYE ) AS  ZJLX     , -- 10 担保人证件类型
       COALESCE ( T7.ID_NO,T4.GUARANTEE_ID_NO) AS ZJHM  , -- 11 担保人证件号码
       -- TO_CHAR(TO_DATE(NVL(T1.GUAR_CONTRACT_SIGN_DT,T3.GUAR_START_DT),'YYYYMMDD'),'YYYY-MM-DD')  , -- 12 签约日期
       TO_CHAR(TO_DATE(NVL(T1.GUAR_CONTRACT_START_DT,T3.GUAR_START_DT),'YYYYMMDD'),'YYYY-MM-DD')  , -- 12 签约日期 [20250415][姜俐锋][JLBA202502210009][吴大为]:经李德超老师确认，CTRT_SIGN_DATE字段前台页面未启用，从逻辑中剔除，应取CONT_EFF_DATE，CTRT_SIGN_DATE字段
       TO_CHAR(TO_DATE(T3.GUAR_START_DT,'YYYYMMDD'),'YYYY-MM-DD')  , -- 13 生效日期
       CASE WHEN T3.GUAR_CONT_TYPE_CD='01' then '9999-12-31' -- [20250513] [狄家卉] [JLBA202504060003][吴大为] 一般担保合同，信贷系统没有到期日，到期日期的默认值9999-12-31
         ELSE  NVL(TO_CHAR(TO_DATE(NVL(T3.GUAR_EXPIRY_DT,C.CONTRACT_ORIG_MATURITY_DT),'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31')
       end                                         , -- 14 到期日期
       T1.GURA_CONTRACT_AMT                        , -- 15 协议金额
       T1.CURR_CD                                  , -- 16 协议币种
       NVL(G.CURR_CD,'CNY')                        , -- 17 担保人净资产币种 20250415 [20250415][姜俐锋][JLBA202502210009][吴大为]:币种为空默认为 人民币 
       G.DBRJZC                                    , -- 18 担保人净资产
	   CASE WHEN T1.GUAR_CONTRACT_STATUS  ='Y' THEN '01'
	        WHEN T1.GUAR_CONTRACT_STATUS  ='N' THEN '04'   
	        END  AS F080019                        , -- 19 协议状态		
	   CASE WHEN nvl(T1.JBYG_ID,C.JBYG_ID)='wd012601' THEN '自动'  -- 网贷崔永哲：虚拟操作员号 有一段时间业务流程里面没有客户经理编号 就直接塞这个操作号了，与苏桐确认，默认为自动
	        ELSE  COALESCE(T1.JBYG_ID,C.JBYG_ID,T1.EMP_ID,C.STAFF_NUM)
	        END AS F080020                         , -- 20 经办员工ID 
	   NVL(T1.SCYG_ID,C.SCYG_ID	)                               , -- 21 审查员工ID
       CASE WHEN C.CP_ID IN ('GX0120003000023','GX0120003000024') then '自动'    -- [20250513] [狄家卉] [JLBA202504060003][吴大为] GX0120003000023 吉享贷、GX0120003000024 吉用贷两个贷款产品空默认给自动
            ELSE COALESCE(T1.SPYG_ID,D.AUTHO_NAME,C.SPYG_ID) 
            END, -- 22 审批员工ID
       CASE WHEN A.DBHTFX ='02' THEN '1'  -- '是'
            WHEN A.DBHTFX ='01' THEN '0'  -- '否'
            END                                    , -- 23 或有负债标识 
       'B'                                         , -- 24 备注
	   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 25 采集日期
	   TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 25 采集日期
	   T1.ORG_NUM,
	   A.DIS_DEPT ,
  	   CASE WHEN L.GOV_FLG = 'Y' THEN  '01'
       ELSE '02'
       END AS DBRLX   ,  -- 担保人类型  20250311
       T4.DBRDBNLSX,   -- 担保人担保能力上限
       'B'
      FROM SMTMODS.L_AGRE_GUARANTEE_CONTRACT T1 -- 担保合同信息
      LEFT JOIN VIEW_L_PUBL_ORG_BRA T2
        ON T1.ORG_NUM = T2.ORG_NUM -- 机构表
       AND T2.DATA_DATE = I_DATE
	   
      INNER JOIN SMTMODS.L_AGRE_GUA_RELATION T3 -- 业务合同和担保合同对应关系表
        ON T1.GUAR_CONTRACT_NUM = T3.GUAR_CONTRACT_NUM
       AND T3.DATA_DATE = I_DATE
	   AND T3.REL_STATUS = 'Y'-- [20250513] [狄家卉] [JLBA202504060003][吴大为]关联状态REL_STATUS为N，即引用类型代码为3解除引用，对应的担保合同也不需要报送了
	  LEFT JOIN ( SELECT ROW_NUMBER() OVER(PARTITION BY T4.GUAR_CONTRACT_NUM,T4.GUAR_CONTRACT_NUM,T4.GUAR_CUST_ID ORDER BY t4.GUARANTEE_ID_NO desc) AS rn  -- [20250415][姜俐锋][JLBA202502210009][吴大为]: 增加分组字段 
                  ,T4.GUAR_CONTRACT_NUM
                  ,T4.GUAR_CUST_ID
                  ,T4.GUARANTEE_ID_NO
                  ,T4.GUARANTEE_ID_TPYE
                  ,T4.REL_STATUS
                  ,T4.DBRLX
                  ,T4.DBRDBNLSX
                  ,T4.GUARANTEE_NAME   -- 2.0 ZDSJ H
                 FROM SMTMODS.L_AGRE_GUARANTEE_RELATION T4 -- 担保合同与担保信息对应关系表
                WHERE T4.DATA_DATE = I_DATE
                  AND T4.REL_STATUS='Y'   -- [20250415][姜俐锋][JLBA202502210009][吴大为]:将条件在担保合同与担保信息对应关系表
                  ) T4  
        ON T1.GUAR_CONTRACT_NUM = T4.GUAR_CONTRACT_NUM	  
 	   AND t4.rn = 1
      LEFT JOIN SMTMODS.L_CUST_R_GUARANTY T5 -- 担保人信息表 
	    ON T4.GUAR_CUST_ID = T5.CUST_ID
	   AND T5.DATA_DATE = I_DATE
	   
	  LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT C  -- 贷款合同信息表 
        ON T3.CONTRACT_NUM = C.CONTRACT_NUM  
	   AND C.DATA_DATE = I_DATE
	   
	  LEFT JOIN SMTMODS.L_CUST_ALL T7 
	    ON T4.GUAR_CUST_ID=T7.CUST_ID
	   AND T7.DATA_DATE = I_DATE  
	 LEFT JOIN SMTMODS.L_CUST_ALL T8 
	    ON C.CUST_ID=T8.CUST_ID -- [JLBA202507250003][20250909][巴启威]:补充关联条件
	   AND T8.DATA_DATE = I_DATE    
	  LEFT JOIN SMTMODS.L_AGRE_CREDITLINE D  -- 授信额度表     
        ON C.FACILITY_NO = D.FACILITY_NO
       AND D.DATA_DATE = I_DATE 
	   
	  LEFT JOIN M_DICT_CODETABLE E
        ON T4.GUARANTEE_ID_TPYE = E.L_CODE
       AND E.L_CODE_TABLE_CODE='C0001' 
       
      LEFT JOIN M_DICT_CODETABLE F
        ON T7.ID_TYPE=F.L_CODE
       AND F.L_CODE_TABLE_CODE='C0001' 
             
      LEFT JOIN TMP_6_8_FINREPINFO G
    --    ON G.CUST_ID = T4.GUAR_CUST_ID 
        ON G.CUST_ID = T5.CUST_ID 
       
     INNER JOIN TMP_6_8_CONTRACT A -- 筛选合同表中存在的数据
        ON T1.GUAR_CONTRACT_NUM = A.GUAR_CONTRACT_NUM
        
     INNER JOIN VIEW_L_PUBL_ORG_BRA B -- 机构表
        ON T1.ORG_NUM = B.ORG_NUM
       AND B.DATA_DATE = I_DATE     
      LEFT JOIN FINANCE_COMPANY_LIST L -- 2.0 ZDSJ H
        ON TRIM(T4.GUARANTEE_NAME) = TRIM(L.COMPANY_NAME)
     WHERE T1.DATA_DATE = I_DATE
       AND T1.GUAR_CONTRACT_STATUS = 'Y'
       AND T1.GURA_CONTRACT_AMT <>0 -- 担保金额不允许为0
      -- AND T4.REL_STATUS='Y'
       AND T1.GUAR_TYP IN ('A0101','B0101')
       AND (C.CONTRACT_EFF_DT <= I_DATE  OR C.CONTRACT_EFF_DT IS NULL ) --   [20250415][姜俐锋][JLBA202502210009][吴大为]:一表通所有使用的担保合同和贷款合同，生效日期大于当前日期的，过滤掉
       AND (T3.GUAR_START_DT <= I_DATE  OR  T3.GUAR_START_DT IS NULL )  --   [20250415][姜俐锋][JLBA202502210009][吴大为]:一表通所有使用的担保合同和贷款合同，生效日期大于当前日期的，过滤掉
       ;
    
       COMMIT;
  -- 回购信息表 20250313 吴大为 老师指示去掉 回购部分
  /*
  INSERT  INTO T_6_8  (
           F080001  , -- 01 协议ID
           F080002  , -- 02 机构ID
           F080003  , -- 03 被担保协议ID
           F080004  , -- 04 担保类型
           F080005  , -- 05 担保合同方向
           F080006  , -- 06 被担保业务类型
           F080007  , -- 07 担保合同类型
           F080008  , -- 08 担保人类别
           F080009  , -- 09 担保人名称
           F080010  , -- 10 担保人证件类型
           F080011  , -- 11 担保人证件号码
           F080012  , -- 12 签约日期
           F080013  , -- 13 生效日期
           F080014  , -- 14 到期日期
           F080015  , -- 15 协议金额
           F080016  , -- 16 协议币种
           F080017  , -- 17 担保人净资产币种
           F080018  , -- 18 担保人净资产
           F080019  , -- 19 协议状态
           F080020  , -- 20 经办员工ID 
           F080021  , -- 21 审查员工ID
           F080022  , -- 22 审批员工ID
           F080023  , -- 23 或有负债标识
           F080024  , -- 24 备注
           F080025  , -- 25 采集日期
           DIS_DATA_DATE,
           DIS_BANK_ID,
           DEPARTMENT_ID ,
           F080026,  -- 担保人类型
           F080027, --  担保人担保能力上限
           DIS_DEPT

       )   
       
      SELECT  
        A.DEAL_ACCT_NUM  , -- 01协议ID
        'B0302H22201009804'    , -- 02机构ID
        A.DEAL_ACCT_NUM  , -- 03被担保协议ID
        '02'        , -- 04担保类型
        '01'        , -- 05担保合同方向
        '07'        , -- 06被担保业务类型
        '01'        , -- 07担保合同类型
        '01'        , -- 08担保人类别
        -- NVL(E.FINA_ORG_NAME ,A.CUST_ID ), -- 09担保人名称
        NVL(E.FINA_ORG_NAME ,T7.CUST_NAM ), -- 09担保人名称-- 20241024_ZHOULP_JLBA202408290021_金市需求_业务姚司桐
        '2010'      , -- 10担保人证件类型  
        NVL(E.TYSHXYDM,T7.ID_NO) AS ZJHM   , -- 11担保人证件号码
        TO_CHAR(TO_DATE(A.BEG_DT,'YYYYMMDD'),'YYYY-MM-DD')  , -- 12 签约日期
        TO_CHAR(TO_DATE(A.BEG_DT,'YYYYMMDD'),'YYYY-MM-DD')  , -- 13 生效日期
        NVL(TO_CHAR(TO_DATE(A.END_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') , -- 14 到期日期 
        -- A.BALANCE   , -- 15协议金额
        A.CONTRACT_AMT , -- 15协议金额
        A.CURR_CD   , -- 16协议币种
        A.GUAR_NET_ASSETS_CURR AS F080017   , -- 17担保人净资产币种  -- 20241024_ZHOULP_JLBA202408290021_金市需求_业务姚司桐
        A.GUAR_NET_ASSETS AS F080018        , -- 18担保人净资产  -- 20241024_ZHOULP_JLBA202408290021_金市需求_业务姚司桐
        CASE WHEN A.BALANCE > 0 THEN '01' -- 正常
        ELSE '04'
        END         ,-- 19协议状态
        NVL(F.GB_CODE,'自动')   ,-- 20经办员工ID
        G.GB_CODE   ,-- 21审查员工ID
        H.GB_CODE   ,-- 22审批员工ID
        '0'        ,-- 23或有负债标识
        'C'        ,-- 24备注
	    TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 25 采集日期
	    TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 25 采集日期
        '009804' ,
        '009804', -- 吉林银行金融市场部(009804)
        '02',  -- 担保人类型 20250311
         NULL, --  担保人担保能力上限
         'C'
      FROM SMTMODS.L_ACCT_FUND_REPURCHASE A -- 回购信息表  
      /*LEFT JOIN SMTMODS.L_AGRE_REPURCHASE_GUARANTY_INFO B -- 回购抵质押物详细信息
        ON A.ACCT_NUM =  B.ACCT_NUM
       AND A.DATA_DATE=B.DATA_DATE*/
     /* LEFT JOIN (SELECT *
      FROM (SELECT A.*,
                 ROW_NUMBER() OVER(PARTITION BY A.CUST_ID ORDER BY A.CUST_ID) RN
             FROM SMTMODS.L_CUST_BILL_TY A
             WHERE A.DATA_DATE = I_DATE) B
     WHERE B.RN = '1') E 
       ON  A.CUST_ID = E.CUST_ID
      LEFT JOIN SMTMODS.L_CUST_ALL T7 
	    ON A.CUST_ID=T7.CUST_ID
	   AND T7.DATA_DATE = I_DATE   
       
      LEFT JOIN M_DICT_CODETABLE F
       ON A.JBYG_ID = F.L_CODE
       AND F.L_CODE_TABLE_CODE ='C0013'
       LEFT JOIN M_DICT_CODETABLE G
       ON A.SZYG_ID = G.L_CODE
       AND G.L_CODE_TABLE_CODE ='C0013'
       LEFT JOIN M_DICT_CODETABLE H
       ON A.SPYG_ID = H.L_CODE
       AND H.L_CODE_TABLE_CODE ='C0013'
     WHERE A.DATA_DATE = I_DATE
       AND A.BUSI_TYPE LIKE '1%' 
       AND A.DATE_SOURCESD ='质押式买入返售';
       -- AND B.ACCT_NUM IS NOT NULL 
    
       COMMIT; 
   */
       -- 保证金 2.0 ZDSJ H
         INSERT  INTO T_6_8  (
           F080001  , -- 01 协议ID
           F080002  , -- 02 机构ID
           F080003  , -- 03 被担保协议ID
           F080004  , -- 04 担保类型
           F080005  , -- 05 担保合同方向
           F080006  , -- 06 被担保业务类型
           F080007  , -- 07 担保合同类型
           F080008  , -- 08 担保人类别
           F080009  , -- 09 担保人名称
           F080010  , -- 10 担保人证件类型
           F080011  , -- 11 担保人证件号码
           F080012  , -- 12 签约日期
           F080013  , -- 13 生效日期
           F080014  , -- 14 到期日期
           F080015  , -- 15 协议金额
           F080016  , -- 16 协议币种
           F080017  , -- 17 担保人净资产币种
           F080018  , -- 18 担保人净资产
           F080019  , -- 19 协议状态
           F080020  , -- 20 经办员工ID 
           F080021  , -- 21 审查员工ID
           F080022  , -- 22 审批员工ID
           F080023  , -- 23 或有负债标识
           F080024  , -- 24 备注
           F080025  , -- 25 采集日期
           DIS_DATA_DATE,
           DIS_BANK_ID,
           DEPARTMENT_ID ,
           F080026,  -- 担保人类型
           F080027 --  担保人担保能力上限
       )   
SELECT       'BZJ'||'_'||T.CONTRACT_NUM ,-- 01 协议ID
             SUBSTR(TRIM(T1.FIN_LIN_NUM ),1,11)||T.ORG_NUM  , -- 02 机构ID 
             T.CONTRACT_NUM, -- 03 被担保协议ID
             '02', -- 04 担保类型
             '01', -- 05 担保合同方向
             CASE WHEN T2.ACCT_TYP LIKE '01%'OR T2.ACCT_TYP LIKE '02%' OR T2.ACCT_TYP LIKE '03%'OR  T2.ACCT_TYP LIKE '04%'
                       OR T2.ACCT_TYP ='0801' OR T2.ACCT_TYP LIKE '09%' THEN '01'
                  WHEN T2.ACCT_TYP ='90'THEN '06'
                  WHEN T4.ACCT_TYP IN ('111','112')THEN '02'
                  WHEN T4.ACCT_TYP IN ('121','211')THEN '03'
                  WHEN T4.ACCT_TYP IN ('212','311','312')THEN '04'
                  WHEN T4.ACCT_TYP  LIKE '5%' THEN '05'
                  ELSE '08'END ,-- 06 被担保业务类型
                  '01',-- 07 担保合同类型
             CASE WHEN T5.CUST_TYPE  = '00' THEN '02' -- '个人'
                  WHEN T5.CUST_TYPE <> '00' THEN '01' -- '对公' 
                  ELSE '03'    
                  END                       , -- 08 担保人类别
             T5.CUST_NAM                    , -- 09 担保人名称
             F.GB_CODE                      , -- 10 担保人证件类型
             T5.ID_NO                       , -- 11 担保人证件号码
             TO_CHAR(TO_DATE(NVL(T.CONTRACT_SIGN_DT,t.CONTRACT_EFF_DT),'YYYYMMDD'),'YYYY-MM-DD') , -- 12 签约日期 20250415 [20250415][姜俐锋][JLBA202502210009][吴大为]:合同签订日期空取贷款合同生效日期
             TO_CHAR(TO_DATE(T.CONTRACT_EFF_DT,'YYYYMMDD'),'YYYY-MM-DD')  , -- 13 生效日期
             -- TO_CHAR(TO_DATE(T.CONTRACT_ORIG_MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD')  ,-- 14 到期日期
             NVL(TO_CHAR(TO_DATE(T.CONTRACT_ORIG_MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') , -- 14 到期日期 JLBA202412260005 20250106 王金保修改 保证金部分到期日期为空时默认99991231
             T.CONTRACT_AMT * DECODE( T.SECURITY_RATE,0,1,T.SECURITY_RATE) * T3.CCY_RATE ,-- 15 协议金额  20250116
             T.SECURITY_CURR,-- 16 协议币种
             NVL(G.CURR_CD,'CNY'),-- 17 担保人净资产币种   [20250415][姜俐锋][JLBA202502210009][吴大为]: 币种为空默认为 人民币 
             G.DBRJZC , -- 18 担保人净资产
             CASE
                 WHEN T.ACCT_STS_SUB='B' THEN '01'  -- 有效
                 WHEN T.ACCT_STS_SUB='A' THEN '02' -- 待生效
                 WHEN T.ACCT_STS_SUB='D' THEN '04' -- 终结
                 WHEN T.ACCT_STS_SUB='C' THEN '05'  -- 撤销
                 WHEN T.ACCT_STS_SUB='Z' THEN '00'  -- 其他
                 END,
             T.JBYG_ID, -- 20 经办员工ID   ZJK UPDATE 20241204 原因应该取合同经办员工不应该取合同号
             T.SCYG_ID, -- 21 审查员工ID   ZJK UPDATE 20241204 原因应该取合同审查员工不应该取合同号  
             T.SPYG_ID,-- 22 审批员工ID    ZJK UPDATE 20241204 原因应该取合同审批员工不应该取合同号
             CASE WHEN T4.ACCT_NO  IS NOT NULL THEN '1'
                  WHEN T2.ACCT_NUM IS NOT NULL THEN '0'
                     END    , -- 23 或有负债标识 
             'E1',                                    -- 24 备注
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 25 采集日期
             TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , 
             T.ORG_NUM,
             CASE WHEN (T2.ACCT_NUM IS NOT NULL) THEN 
             CASE WHEN T2.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
             WHEN T2.DEPARTMENTD ='公司金融' OR SUBSTR(T2.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
             WHEN T2.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
             WHEN T2.DEPARTMENTD ='普惠金融' THEN '0098PH'  -- 普惠金融部(0098PH)
             WHEN SUBSTR(T2.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
             WHEN SUBSTR(T2.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
             ELSE '009804' END
             WHEN (T4.ACCT_NO IS NOT NULL )THEN 
             CASE WHEN T4.DEPARTMENTD= '普惠金融' THEN '0098PH'  
             WHEN (T4.DEPARTMENTD= '公司金融' OR T4.DEPARTMENTD IS NULL ) THEN '0098JR' 
             END 
             END  AS DEPARTMENT_ID,
             CASE WHEN L.GOV_FLG = 'Y' THEN  '01'
             ELSE '02'
             END AS DBRLX   ,  -- 担保人类型  20250311,  
             NULL     --  担保人担保能力上限
       FROM SMTMODS.L_AGRE_LOAN_CONTRACT T 
       LEFT JOIN (SELECT * FROM ( SELECT T.O_ACCT_NUM,T.DEPOSIT_NUM,T.CUST_ID,
                                 ROW_NUMBER() OVER(PARTITION BY T.O_ACCT_NUM ORDER BY T.DEPOSIT_NUM) AS NUM
                                 FROM  SMTMODS.L_ACCT_DEPOSIT T  WHERE T.DATA_DATE=I_DATE)T1  WHERE T1.NUM=1 ) D
	     ON T.SECURITY_ACCT_NUM = D.O_ACCT_NUM
	   LEFT JOIN VIEW_L_PUBL_ORG_BRA T1 -- 机构表
         ON T.ORG_NUM = T1.ORG_NUM
        AND T1.DATA_DATE = I_DATE 
	   LEFT JOIN SMTMODS.L_PUBL_RATE T3
         ON T3.DATA_DATE = I_DATE
        AND T3.BASIC_CCY = T.SECURITY_CURR -- 基准币种
        AND T3.FORWARD_CCY = 'CNY'
	   LEFT JOIN  SMTMODS.L_CUST_ALL T5
         -- ON T5.CUST_ID=D.CUST_ID
         ON T5.CUST_ID=T.CUST_ID -- 20241024_ZHOULP_JLBA202408290021_金市需求_业务姚司桐
        AND T5.DATA_DATE=I_DATE
	   LEFT JOIN M_DICT_CODETABLE F
         ON T5.ID_TYPE=F.L_CODE
        AND F.L_CODE_TABLE_CODE= 'C0012'
       LEFT JOIN (SELECT * FROM (SELECT T.ACCT_NUM,T.DEPARTMENTD,T.ITEM_CD,T.ACCT_TYP,
                                  ROW_NUMBER() OVER(PARTITION BY T.ACCT_NUM ORDER BY T.LOAN_NUM) AS NUM
                                  FROM  SMTMODS.L_ACCT_LOAN T  WHERE T.DATA_DATE=I_DATE)T1  WHERE T1.NUM=1 ) T2 
         ON T.CONTRACT_NUM=T2.ACCT_NUM
       LEFT JOIN (SELECT * FROM (SELECT T.ACCT_NO,T.DEPARTMENTD,T.ACCT_TYP,
                                 ROW_NUMBER() OVER(PARTITION BY T.ACCT_NO ORDER BY T.ACCT_NUM) AS NUM
                                 FROM SMTMODS.L_ACCT_OBS_LOAN T  WHERE T.DATA_DATE=I_DATE)T1  WHERE T1.NUM=1 ) T4
         ON T.CONTRACT_NUM=T4.ACCT_NO
         
       LEFT JOIN FINANCE_COMPANY_LIST L -- 20250225
         ON TRIM( T5.CUST_NAM ) = TRIM(L.COMPANY_NAME)    
       LEFT JOIN TMP_6_8_FINREPINFO G
         ON T.CUST_ID = G.CUST_ID   
	  WHERE T.DATA_DATE=I_DATE 
	    AND T.SECURITY_ACCT_NUM IS NOT NULL 
	    -- AND T.ACCT_STS='1' 
	    AND T.CONTRACT_AMT<>0 
	    AND (T.CONTRACT_EFF_DT <= I_DATE  OR T.CONTRACT_EFF_DT IS NULL ) --   [20250415][姜俐锋][JLBA202502210009][吴大为]:.一表通所有使用的担保合同和贷款合同，生效日期大于当前日期的，过滤掉
        AND (T.ACCT_STS ='1' OR 
		-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
            (T.ACCT_STS ='2' AND T.CONTRACT_EXP_DT >= SUBSTR(I_DATE,1,4)||'0101' ) OR 
            (T.INTERNET_LOAN_TAG = 'Y' AND T.CONTRACT_EXP_DT >= TO_CHAR(TO_DATE(SUBSTR(I_DATE,1,4)||'0101' ,'YYYYMMDD') - 1,'YYYYMMDD')) or --  [20250415][姜俐锋][JLBA202502210009][吴大为]: 与6.2条件同步
	        (T.CP_ID ='DK001000100041' AND T.CONTRACT_EXP_DT >= TO_CHAR(TO_DATE((SUBSTR(I_DATE,1,4)||'0101') ,'YYYYMMDD') - 1,'YYYYMMDD')) -- [20250929][姜俐锋][JLBA202507300010][信贷新增产品]: 同网贷部分数据处理方式
            )
	  UNION ALL                                  -- 2.0ZDSJ H
   SELECT   'BZJ'||'_'||T.CONTRACT_NUM ,-- 01 协议ID
            SUBSTR(TRIM(T1.FIN_LIN_NUM ),1,11)||T.ORG_NUM  , -- 02 机构ID 
            T.CONTRACT_NUM, -- 03 被担保协议ID
            '02', -- 04 担保类型
            '01', -- 05 担保合同方向
            CASE WHEN T2.ACCT_TYP LIKE '01%'OR T2.ACCT_TYP LIKE '02%' OR T2.ACCT_TYP LIKE '03%'OR  T2.ACCT_TYP LIKE '04%'
                   OR T2.ACCT_TYP ='0801' OR T2.ACCT_TYP LIKE '09%' THEN '01'
                 WHEN T2.ACCT_TYP ='90'THEN '06'
                 WHEN T4.ACCT_TYP IN ('111','112')THEN '02'
                 WHEN T4.ACCT_TYP IN ('121','211')THEN '03'
                 WHEN T4.ACCT_TYP IN ('212','311','312')THEN '04'
                 WHEN T4.ACCT_TYP  LIKE '5%' THEN '05'
                 ELSE '08'END ,-- 06 被担保业务类型
              '01',-- 07 担保合同类型
            CASE 
                WHEN T5.CUST_TYPE  = '00' THEN '02' -- '个人'
                WHEN T5.CUST_TYPE <> '00' THEN '01' -- '对公' 
                ELSE '03'    
                END                        , -- 08 担保人类别
            T5.CUST_NAM                    , -- 09 担保人名称
            F.GB_CODE                      , -- 10 担保人证件类型
            T5.ID_NO                       , -- 11 担保人证件号码
            TO_CHAR(TO_DATE(NVL(T.CONTRACT_SIGN_DT,t.CONTRACT_EFF_DT),'YYYYMMDD'),'YYYY-MM-DD') , -- 12 签约日期20250415 [20250415][姜俐锋][JLBA202502210009][吴大为]:合同签订日期空取贷款合同生效日期
            TO_CHAR(TO_DATE(T.CONTRACT_EFF_DT,'YYYYMMDD'),'YYYY-MM-DD') , -- 13 生效日期
            -- TO_CHAR(TO_DATE(T.CONTRACT_ORIG_MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD')  ,-- 14 到期日期
            NVL(TO_CHAR(TO_DATE(T.CONTRACT_ORIG_MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD'),'9999-12-31') ,-- 14 到期日期 JLBA202412260005 20250106 王金保修改 保证金部分到期日期为空时默认99991231
            T.CONTRACT_AMT * DECODE( T.HZF_SECURITY_RATE,0,1, T.HZF_SECURITY_RATE) * T3.CCY_RATE ,-- 15 协议金额 20250116
            T.HZF_SECURITY_CURR,-- 16 协议币种 
            NVL(G.CURR_CD,'CNY'),-- 17 担保人净资产币种   [20250415][姜俐锋][JLBA202502210009][吴大为]: 币种为空默认为 人民币 
            G.DBRJZC , -- 18 担保人净资产
            CASE
               WHEN T.ACCT_STS_SUB='B' THEN '01'  -- 有效
               WHEN T.ACCT_STS_SUB='A' THEN '02' -- 待生效
               WHEN T.ACCT_STS_SUB='D' THEN '04' -- 终结
               WHEN T.ACCT_STS_SUB='C' THEN '05'  -- 撤销
               WHEN T.ACCT_STS_SUB='Z' THEN '00'  -- 其他
               END,
            T.JBYG_ID, -- 20 经办员工ID   ZJK UPDATE 20241204 原因应该取合同经办员工不应该取合同号
            T.SCYG_ID, -- 21 审查员工ID   ZJK UPDATE 20241204 原因应该取合同审查员工不应该取合同号  
            T.SPYG_ID,-- 22 审批员工ID    ZJK UPDATE 20241204 原因应该取合同审批员工不应该取合同号
            CASE WHEN T4.ACCT_NO  IS NOT NULL THEN '1'
                 WHEN T2.ACCT_NUM IS NOT NULL THEN '0'
                 END    , -- 23 或有负债标识 
            'E2',                                    -- 24 备注
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') ,  -- 25 采集日期
            TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') , 
            T.ORG_NUM,
            CASE WHEN (T2.ACCT_NUM IS NOT NULL) THEN 
            CASE WHEN T2.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
            WHEN T2.DEPARTMENTD ='公司金融' OR SUBSTR(T2.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
            WHEN T2.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
            WHEN T2.DEPARTMENTD ='普惠金融' THEN '0098PH'  -- 普惠金融部(0098PH)
            WHEN SUBSTR(T2.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
            WHEN SUBSTR(T2.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
            ELSE '009804' END
            WHEN (T4.ACCT_NO IS NOT NULL )THEN 
            CASE WHEN T4.DEPARTMENTD= '普惠金融' THEN '0098PH'  
            WHEN (T4.DEPARTMENTD= '公司金融' OR T4.DEPARTMENTD IS NULL ) THEN '0098JR' 
            END 
            END AS DEPARTMENT_ID,
            CASE WHEN L.GOV_FLG = 'Y' THEN  '01'
            ELSE '02'
            END AS DBRLX   ,  -- 担保人类型  20250311,  
            NULL    --  担保人担保能力上限
       FROM SMTMODS.L_AGRE_LOAN_CONTRACT T 
       LEFT JOIN (SELECT * FROM ( SELECT T.O_ACCT_NUM,T.DEPOSIT_NUM,T.CUST_ID,
                                  ROW_NUMBER() OVER(PARTITION BY T.O_ACCT_NUM ORDER BY T.DEPOSIT_NUM) AS NUM
                                  FROM  SMTMODS.L_ACCT_DEPOSIT T  WHERE T.DATA_DATE=I_DATE)T1  WHERE T1.NUM=1 ) D
	     ON T.HZF_SECURITY_ACCT_NUM = D.O_ACCT_NUM
	   LEFT JOIN VIEW_L_PUBL_ORG_BRA T1 -- 机构表
         ON T.ORG_NUM = T1.ORG_NUM
        AND T1.DATA_DATE = I_DATE 
	   LEFT JOIN SMTMODS.L_PUBL_RATE T3
         ON T3.DATA_DATE = I_DATE
        AND T3.BASIC_CCY = T.HZF_SECURITY_CURR -- 基准币种
        AND T3.FORWARD_CCY = 'CNY'
	   LEFT JOIN SMTMODS.L_CUST_ALL T5 
         ON T5.CUST_ID=T.CUST_ID -- 20241024_ZHOULP_JLBA202408290021_金市需求_业务姚司桐
        AND T5.DATA_DATE=I_DATE
	   LEFT JOIN M_DICT_CODETABLE F
         ON T5.ID_TYPE=F.L_CODE
        AND F.L_CODE_TABLE_CODE= 'C0012'
       LEFT JOIN (SELECT * FROM (SELECT T.ACCT_NUM,T.DEPARTMENTD,T.ITEM_CD,T.ACCT_TYP,
                                  ROW_NUMBER() OVER(PARTITION BY T.ACCT_NUM ORDER BY T.LOAN_NUM) AS NUM
                                  FROM SMTMODS.L_ACCT_LOAN T  WHERE T.DATA_DATE=I_DATE)T1  WHERE T1.NUM=1 ) T2 
         ON T.CONTRACT_NUM=T2.ACCT_NUM
       LEFT JOIN (SELECT * FROM (SELECT T.ACCT_NO,T.DEPARTMENTD,T.ACCT_TYP,
                                  ROW_NUMBER() OVER(PARTITION BY T.ACCT_NO ORDER BY T.ACCT_NUM) AS NUM
                                  FROM SMTMODS.L_ACCT_OBS_LOAN T  WHERE T.DATA_DATE=I_DATE)T1  WHERE T1.NUM=1 ) T4
         ON T.CONTRACT_NUM=T4.ACCT_NO
       LEFT JOIN FINANCE_COMPANY_LIST L -- 20250225
         ON TRIM( T5.CUST_NAM ) = TRIM(L.COMPANY_NAME)    
       LEFT JOIN TMP_6_8_FINREPINFO G
         ON T.CUST_ID = G.CUST_ID     
	  WHERE T.DATA_DATE=I_DATE 
	    AND T.HZF_SECURITY_ACCT_NUM IS NOT NULL 
	    -- AND T.ACCT_STS='1' 
	    AND T.CONTRACT_AMT<>0
	    AND (T.CONTRACT_EFF_DT <= I_DATE  OR T.CONTRACT_EFF_DT IS NULL ) --   [20250415][姜俐锋][JLBA202502210009][吴大为]: .一表通所有使用的担保合同和贷款合同，生效日期大于当前日期的，过滤掉
        AND (T.ACCT_STS ='1' OR 
		-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
            (T.ACCT_STS ='2' AND T.CONTRACT_EXP_DT >= SUBSTR(I_DATE,1,4)||'0101' ) OR 
            (T.INTERNET_LOAN_TAG = 'Y' AND T.CONTRACT_EXP_DT >= TO_CHAR(TO_DATE(SUBSTR(I_DATE,1,4)||'0101' ,'YYYYMMDD') - 1,'YYYYMMDD')) or --  [20250415][姜俐锋][JLBA202502210009][吴大为]: 与6.2条件同步
	        (T.CP_ID ='DK001000100041' AND T.CONTRACT_EXP_DT >= TO_CHAR(TO_DATE((SUBSTR(I_DATE,1,4)||'0101') ,'YYYYMMDD') - 1,'YYYYMMDD')) -- [20250929][姜俐锋][JLBA202507300010][信贷新增产品]: 同网贷部分数据处理方式
            );
    
	  
       
       
       
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

