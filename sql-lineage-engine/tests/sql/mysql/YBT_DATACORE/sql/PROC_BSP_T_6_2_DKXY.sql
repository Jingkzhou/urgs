DROP Procedure IF EXISTS `PROC_BSP_T_6_2_DKXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_2_DKXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：贷款协议
      程序功能  ：加工贷款协议
      目标表：T_6_2
      源表  ：
      创建人  ：87V
      创建日期  ：20240110 
      版本号：V0.0.1 
  ******/
 --  JLBA202411070004_关于一表通监管数据报送系统修改逻辑的需求	
 -- JLBA202412200001_关于一表通监管数据报送系统修改逻辑及转EAST脚本的需求_20250116
 /*需求编号：JLBA202504060003 上线日期：20250513，修改人：狄家卉，提出人：吴大为    关于一表通监管数据报送系统、EAST报送系统修改取数逻辑的需求*/
 /*需求编号：JLBA202504160004   上线日期：20250708，修改人：姜俐锋，提出人：吴大为 关于吉林银行修改单一客户授信逻辑的需求*/	
 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_2_DKXY';
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
	
	DELETE FROM T_6_2 WHERE F020063 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
	
	COMMIT;
   														
    
    #3插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
	
    INSERT  INTO T_6_2 
      (
       F020001  , -- 01 协议ID
       F020002  , -- 02 机构ID
       F020003  , -- 03 客户ID
       F020005  , -- 04 合同名称
       F020006  , -- 05 产品ID
       F020007  , -- 06 协议币种
       F020008  , -- 07 贷款金额
       F020010  , -- 08 贷款用途
       F020048  , -- 09 贷款协议起始日期
       F020049  , -- 10 贷款协议到期日期
       F020057  , -- 11 经办员工ID
       F020058  , -- 12 管户员工ID
       F020059  , -- 13 审查员工ID
       F020060  , -- 14 审批员工ID
       F020061  , -- 15 协议状态
       F020062  , -- 16 备注
       F020063  , -- 17 采集日期
       DIS_DATA_DATE ,
       DIS_BANK_ID,
       DEPARTMENT_ID ,
       F020064  , -- '授信ID',
       F020065  , --  '担保方式',
       F020066 ,-- '信贷业务种类'
       DIS_DEPT
       )
  
       WITH ACCT_LOAN AS 
      (  SELECT DISTINCT
              T1.ACCT_NUM ,
              T1.USEOFUNDS , 
              T1.ITEM_CD,
              T1.ACCT_TYP,
              T1.ACCT_STS ,
              T1.FINISH_DT,
              T1.DEPARTMENTD,
              T1.GRXFDKYT,
              T1.DRAWDOWN_DT,  -- 20250311
              CASE  
           WHEN T1.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T1.DEPARTMENTD ='公司金融' OR SUBSTR(T1.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T1.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T1.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T1.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
                      ELSE   '009804'
           END AS TX, 
           T1.LOAN_ACCT_BAL,
           NVL(T8.DYZJDRLH, T1.EMP_ID) AS EMP_ID,    -- 一表通转EAST LMH
           ROW_NUMBER() OVER(PARTITION BY T1.ACCT_NUM ORDER BY T1.USEOFUNDS,T1.EMP_ID) AS NUM
         FROM SMTMODS.L_ACCT_LOAN T1
         LEFT JOIN SMTMODS.L_ACCT_WRITE_OFF T7  -- 核销
           ON T7.LOAN_NUM=T1.LOAN_NUM
          AND T7.DATA_DATE = I_DATE
          AND T7.WRITE_OFF_DATE = I_DATE
         LEFT JOIN  SMTMODS.L_ACCT_TRANSFER T8  
           ON T8.LOAN_NUM=T1.LOAN_NUM
          AND T8.DATA_DATE = I_DATE
          AND T8.TRANS_DATE = I_DATE 
         LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T2 -- 贷款合同信息表 
           ON T2.CONTRACT_NUM = T1.ACCT_NUM
          AND T2.DATA_DATE = I_DATE
         LEFT JOIN GYH_YSGX_DHCC_TMP T8
           ON T1.EMP_ID = T8.LXTH
          AND T8.LXTHSSJGMC <> '资产保全部'
        WHERE T1.DATA_DATE = I_DATE   
          AND (T1.ACCT_STS <> '3'    --  [20250513][巴启威][JLBA202504060003][吴大为]: 同步6.27条件
            OR T1.LOAN_ACCT_BAL > 0 
			-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
            OR T1.FINISH_DT >= SUBSTR(I_DATE,1,4)||'0101'
            OR (T2.INTERNET_LOAN_TAG = 'Y' AND T1.FINISH_DT >= TO_CHAR(TO_DATE(SUBSTR(I_DATE,1,4)||'0101', 'YYYYMMDD') - 1,'YYYYMMDD')) )
          AND (T1.LOAN_STOCKEN_DATE IS NULL OR T1.LOAN_STOCKEN_DATE >= SUBSTR(I_DATE,1,4)||'0101') --  [20250513][巴启威][JLBA202504060003][吴大为]:  同步6.27条件
          AND (SUBSTR(T1.ITEM_CD,1,6) IN ('130302','130301','302001','302002','130103')  -- 公司贷款 , 个人贷款,委托公司贷款 ,委托个人贷款,  福费廷
           OR  SUBSTR(T1.ITEM_CD,1,4) IN ('1305','7140')  --  贸易融资  ,银团
           OR T1.ITEM_CD LIKE '1306%' -- 加垫款部分  -- JLBA202411070004  20241128
           ) )
   
   SELECT 
          T6.CONTRACT_NUM  AS F020001, -- 01 协议ID
          SUBSTR(TRIM(T2.FIN_LIN_NUM ),1,11)||T6.ORG_NUM AS F020002   , -- 02 机构ID
          T6.CUST_ID AS F020003         , -- 03 客户ID
          T6.CONTRACT_NAME  AS F020005  , -- 04 合同名称
          CASE WHEN T6.ACCT_TYP IN ('030101','030102') THEN 'DN0090001'
          ELSE T6.CP_ID   
          END AS  F020006 , -- 05 产品ID
          T6.CURR_CD   AS F020007         , -- 06 协议币种
          T6.CONTRACT_AMT  AS F020008     , -- 07 贷款金额
          T1.USEOFUNDS    AS F020009      , -- 08 贷款用途
          CASE WHEN SUBSTR(T1.ITEM_CD,1,4) = '1306' then TO_CHAR(TO_DATE(T1.DRAWDOWN_DT,'YYYYMMDD'),'YYYY-MM-DD')   -- [20250513][狄家卉][JLBA202504060003][吴大为]: 垫款  贷款协议起始日、贷款协议到期日取该笔票据形成垫款日子， 垫款发放日到期日修改成一个
               ELSE NVL(TO_CHAR(TO_DATE(T6.CONTRACT_EFF_DT,'YYYYMMDD'),'YYYY-MM-DD') ,TO_CHAR(TO_DATE(T1.DRAWDOWN_DT,'YYYYMMDD'),'YYYY-MM-DD')) 
               END AS F020048, -- 09 贷款协议起始日期 -- 20250311 
          CASE WHEN SUBSTR(T1.ITEM_CD,1,4) = '1306' then TO_CHAR(TO_DATE(T1.DRAWDOWN_DT,'YYYYMMDD'),'YYYY-MM-DD') -- [20250513][狄家卉][JLBA202504060003][吴大为]: 垫款  贷款协议起始日、贷款协议到期日取该笔票据形成垫款日子， 垫款发放日到期日修改成一个
               WHEN T6.CONTRACT_EFF_DT IS NULL THEN  NVL(TO_CHAR(TO_DATE(T6.CONTRACT_EXP_DT,'YYYYMMDD'),'YYYY-MM-DD') ,TO_CHAR(TO_DATE(T6.CONTRACT_ORIG_MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD') )
               ELSE TO_CHAR(TO_DATE(T6.CONTRACT_ORIG_MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD') 
               END AS F020049 , -- 10 贷款协议到期日期    
          CASE WHEN T6.JBYG_ID= 'WD012601' THEN '自动'  -- 网贷崔永哲：虚拟操作员号 有一段时间业务流程里面没有客户经理编号 就直接塞这个操作号了，与苏桐确认，默认为自动
          ELSE  NVL(T6.JBYG_ID ,T6.STAFF_NUM)
          END         AS F020057          , -- 11 经办员工ID           , -- 11 经办员工ID
          T1.EMP_ID   AS F020058          , -- 12 管户员工ID 一表通转EAST LMH
          T6.SCYG_ID  AS F020059          , -- 13 审查员工ID
          T6.SPYG_ID  AS F020060          , -- 14 审批员工ID
          CASE WHEN T6.ACCT_STS_SUB = 'A' THEN '02'
               WHEN T6.ACCT_STS_SUB = 'B' THEN '01'
               WHEN T6.ACCT_STS_SUB = 'C' THEN '05'
               WHEN T6.ACCT_STS_SUB = 'D' THEN '04'
               WHEN T6.ACCT_STS_SUB = 'Z' THEN '00'
           END        AS F020061          , -- 15 协议状态      
          /**CASE 
            WHEN T6.ACCT_STS = '1'  THEN '01'
            WHEN T6.ACCT_STS = '2'  THEN '04'      -- 同步EAST逻辑 将06状态改为04
            END **/
          NULL   AS F020016   ,-- T6.REMARK            , -- 16 备注 
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS F020063,    -- 17 采集日期
          TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
          T6.ORG_NUM,
          T1.TX,
         /*CASE WHEN P.CUST_ID IS NOT NULL THEN T6.CONTRACT_NUM 
         ELSE NVL(T3.FACILITY_NO,T6.FACILITY_NO)
         END  AS F020064,*/
         NVL(G.FACILITY_NO, T6.FACILITY_NO) AS F020064,  -- [20250708][姜俐锋][JLBA202504160004][吴大为]：修改取数方案支取修改后合同表中授信号
         CASE WHEN T6.MAIN_GUARANTY_TYP = 'A' AND T6.QTDBFS1 IS NULL AND T6.QTDBFS2 IS NULL THEN '01' -- 	质押贷款 
              WHEN T6.MAIN_GUARANTY_TYP = 'B' AND T6.QTDBFS1 IS NULL AND T6.QTDBFS2 IS NULL THEN '02' -- 	抵押贷款
              WHEN T6.MAIN_GUARANTY_TYP = 'C' AND T6.QTDBFS1 IS NULL AND T6.QTDBFS2 IS NULL THEN '03' -- 	保证贷款
              WHEN T6.MAIN_GUARANTY_TYP = 'D' AND T6.QTDBFS1 IS NULL AND T6.QTDBFS2 IS NULL THEN '04' -- 	信用贷款
              WHEN T6.MAIN_GUARANTY_TYP = 'B' AND T6.QTDBFS1 = 'A'   AND T6.QTDBFS2 IS NULL THEN '05' -- 	抵押+质押+其他
              WHEN T6.MAIN_GUARANTY_TYP = 'B' AND (T6.QTDBFS1 = 'C' OR  T6.QTDBFS1='00') THEN '06' -- 	抵押+保证（或信用）
              WHEN T6.MAIN_GUARANTY_TYP = 'A' AND (T6.QTDBFS1 = 'C' OR  T6.QTDBFS1='00') THEN '06' -- 	抵押+保证（或信用）
              WHEN T6.MAIN_GUARANTY_TYP = 'C' AND  T6.QTDBFS1='00'  THEN '06' -- 	抵押+保证（或信用）
           ELSE '00'
           END AS F020065,
        CASE
         WHEN T1.ACCT_TYP LIKE '0202%' THEN
          '01' -- 流动资金贷款
         WHEN T1.ACCT_TYP LIKE '0801%' THEN
          '02' -- 法人账户透支
         WHEN Q.ACCT_NUM IS NOT NULL AND T6.SYNDICATEDLOAN_FLG='Y'  THEN  
          '04' -- 项目贷款（银团）
         WHEN T1.ACCT_TYP LIKE '0201%' THEN   -- 05，03执行顺序调换 0619_LHY
          '05' -- 一般固定资产贷款
         WHEN Q.ACCT_NUM IS NOT NULL THEN 
          '03' -- 项目贷款 
         WHEN T1.ACCT_TYP LIKE '0101%' THEN   -- 20241015
          '07' --  7 住房按揭贷款（非公转商）
         WHEN T1.ACCT_TYP LIKE '010201' THEN
          '08' -- 个人经营性商用房贷款
          --  9 个人消费性商用房贷款
         WHEN T1.ACCT_TYP LIKE '0104%' THEN
          '11' -- 助学贷款
         WHEN (T1.ACCT_TYP LIKE '0102%' AND T1.ACCT_TYP NOT LIKE '010201%') /**OR L.CP_ID = 'GJ0100001000005'**/ THEN   -- 0619 EAST该条数据为其他_个人贷款 LHY
          '13' -- 个人经营性贷款
         WHEN T1.ACCT_TYP ='010301' THEN -- 20241015
          '10' -- 个人汽车贷款
         WHEN T1.ACCT_TYP IN  ('010399','019999','010302') THEN -- 20241015
         '12' -- 个人消费贷款
         WHEN SUBSTR(T1.ITEM_CD, 1, 6) IN ('130101', '130104') THEN
          '14' -- 票据贴现
         WHEN T1.ITEM_CD LIKE '130105%' THEN
          '15' -- 买断式转贴现
         WHEN (T1.ACCT_TYP LIKE '04%' OR SUBSTR(T1.ITEM_CD, 1, 6)='130103')  THEN -- 20240408 新增范围
          '16' -- 贸易融资业务
         WHEN T1.ACCT_TYP LIKE '05%' THEN
          '17' -- 融资租赁业务
         WHEN T1.ACCT_TYP LIKE '09%' THEN
          '18' -- 垫款
         WHEN T1.ACCT_TYP LIKE '90%' THEN
          '19' -- 委托贷款
         WHEN T1.ACCT_TYP = '0399' THEN
          '20' -- 买断式其他票据类资产
         ELSE
          '00' -- 其他
       END AS F020066 , -- 66信贷业务种类 
       1
         FROM SMTMODS.L_AGRE_LOAN_CONTRACT T6  -- 贷款合同信息表
         LEFT JOIN (SELECT * FROM  ACCT_LOAN WHERE NUM = 1 )T1 -- 贷款借据信息表
           ON T1.ACCT_NUM = T6.CONTRACT_NUM
         LEFT JOIN VIEW_L_PUBL_ORG_BRA T2 -- 机构表
           ON T6.ORG_NUM = T2.ORG_NUM
          AND T2.DATA_DATE = I_DATE
         LEFT JOIN SMTMODS.L_PUBL_RATE U -- 汇率表
           ON U.CCY_DATE = I_DATE
          AND U.BASIC_CCY = T6.CURR_CD -- 基准币种
          AND U.FORWARD_CCY='CNY' 
         LEFT JOIN (SELECT DISTINCT  ACCT_NUM FROM SMTMODS.L_ACCT_PROJECT
                    WHERE DATA_DATE = I_DATE) Q -- 项目贷款信息表
           ON T1.ACCT_NUM = Q.ACCT_NUM  
         LEFT JOIN SMTMODS.L_CUST_P P -- 个人客户信息表
           ON T6.CUST_ID = P.CUST_ID
          AND P.DATA_DATE = I_DATE  
         LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G  -- JLBA202409120001 20241128 新增关联取授信额度 
           ON T6.CUST_ID = G.CUST_ID  
          AND G.FACILITY_TYP ='3' 
          AND G.DATA_DATE  = I_DATE 
       /*  LEFT JOIN  -- [20250708][姜俐锋][JLBA202504160004][吴大为]：修改取数方案直接从修改后合同表中授信号
             (SELECT T3.CUST_ID,T3.FACILITY_NO,
                    ROW_NUMBER() OVER(PARTITION BY T3.CUST_ID ORDER BY T3.FACILITY_NO DESC) AS RN
               FROM SMTMODS.L_AGRE_CREDITLINE T3 -- 授信额度表 
              WHERE T3.DATA_DATE = I_DATE ) T3
           ON T6.CUST_ID = T3.CUST_ID
          AND T3.RN = 1*/
        WHERE T6.DATA_DATE = I_DATE
       --  AND T6.ACCT_TYP NOT LIKE '09%'
          AND NVL(T6.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据
          AND (T6.CONTRACT_EFF_DT <= I_DATE  OR T6.CONTRACT_EFF_DT IS NULL ) -- 因校验公式YBT_JYF02-104 剔除合同生效日期大于数据日期的贷款合同 87V
          AND (T6.DATE_SOURCESD NOT IN ('保函','信用证','商票保贴','银承','贷款承诺') OR T1.ITEM_CD LIKE '1306%') -- 去除表外业务保留垫款部分
          AND (T6.ACCT_STS ='1' OR 
		  -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
              (T6.ACCT_STS ='2' AND T6.CONTRACT_EXP_DT >= SUBSTR(I_DATE,1,4)||'0101') OR 
              (T6.INTERNET_LOAN_TAG = 'Y' AND T6.CONTRACT_EXP_DT >= TO_CHAR(TO_DATE((SUBSTR(I_DATE,1,4)||'0101') ,'YYYYMMDD') - 1,'YYYYMMDD') ) OR
               T1.ITEM_CD LIKE '1306%') -- 20250311
     -- 20250116 业务同意修改报送范围：生效及当日结清数据，口径：如果NGI贷款合同表.CTRT_STAS =生效 应全部取，如果合同状态CTRT_STAS = 42 结清 提前结清日期ADVANCE_END_DATE ，如果没有取【其项下所有借据的最大结清日期】、【合同到期日】二者的更大值   与跑批数据日期对比 取当日结清 
    ; 
             
 COMMIT ;
               #3插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '票据数据插入';
           
    
       
     INSERT  INTO T_6_2 
      (
       F020001  , -- 01 协议ID
       F020002  , -- 02 机构ID
       F020003  , -- 03 客户ID
       F020005  , -- 04 合同名称
       F020006  , -- 05 产品ID
       F020007  , -- 06 协议币种
       F020008  , -- 07 贷款金额
       F020010  , -- 08 贷款用途
       F020048  , -- 09 贷款协议起始日期
       F020049  , -- 10 贷款协议到期日期
       F020057  , -- 11 经办员工ID
       F020058  , -- 12 管户员工ID
       F020059  , -- 13 审查员工ID
       F020060  , -- 14 审批员工ID
       F020061  , -- 15 协议状态
       F020062  , -- 16 备注
       F020063  , -- 17 采集日期
       DIS_DATA_DATE ,
       DIS_BANK_ID,
       DEPARTMENT_ID ,
       F020064  , -- '授信ID',
       F020065  , --  '担保方式',
       F020066  , -- '信贷业务种类'
       DIS_DEPT
       )
       
  SELECT /*+APPEND PARALLEL(8)*/ 
              CASE WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130104','130102','130105') THEN  SUBSTR(T1.ACCT_NUM || NVL(T1.DRAFT_RNG,''),1,60) 
              -- WHEN T1.ITEM_CD LIKE '1306%' THEN T1.LOAN_NUM
                   ELSE T1.ACCT_NUM  
                   END AS F020001, -- 01 协议ID
              T2.ORG_ID AS F020002 ,-- 02 机构ID
              NVL(TY.ECIF_CUST_ID  ,T1.CUST_ID ) AS F020003, -- 03 客户ID 20250116
              CASE WHEN T3.CONTRACT_NAME IS NULL THEN (CASE WHEN SUBSTR(T1.ITEM_CD, 1, 6) IN ('130101', '130104') THEN '票据直贴'
                                                            WHEN SUBSTR(T1.ITEM_CD, 1, 6) IN ('130102', '130105') THEN '票据转贴'
                                                             END)
                   ELSE T3.CONTRACT_NAME
                   END AS F020005, -- 合同名称    20241015
              CASE WHEN T1.ACCT_TYP IN ('030101','030102') THEN 'DN0090001'
                   ELSE NULL  
                   END AS F020006, -- 05 产品ID    , -- 05 产品ID
              T1.CURR_CD AS F020007 ,-- 06 协议币种
              T1.DRAWDOWN_AMT AS F020008, -- 07 贷款金额
              T1.USEOFUNDS AS F020009  , -- 08 贷款用途
              TO_CHAR(TO_DATE(T1.DRAWDOWN_DT,'YYYYMMDD'),'YYYY-MM-DD') AS F020048 , -- 09 贷款协议起始日期
              TO_CHAR(TO_DATE(T1.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD') AS F020049, -- 10 贷款协议到期日期
              T1.JBYG_ID AS F020057, -- '经办员工ID',
              NVL(T8.DYZJDRLH, T1.EMP_ID) AS F020058 , -- '管户员工ID',  一表通转EAST LMH
              T1.SZYG_ID AS F020059 , -- '审查员工ID',
              T1.SPYG_ID AS F020060 , -- '审批员工ID', 
              CASE WHEN T3.ACCT_STS_SUB = 'A' THEN  '02' -- '未生效'
                   WHEN T3.ACCT_STS_SUB = 'B' OR T1.FINISH_DT IS NULL THEN '01' -- '有效'
                   WHEN T3.ACCT_STS_SUB = 'C' THEN '05' -- '撤销'
                   WHEN T3.ACCT_STS_SUB = 'D' OR T1.FINISH_DT IS NOT NULL THEN '04'  -- '终结'
                   WHEN T3.ACCT_STS_SUB = 'Z' THEN '00'
                   END AS F020061 , -- 15 协议状态
              NULL AS F020062 , -- 16 备注
              TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD') AS F020063,    -- 17 采集日期
              TO_CHAR(TO_DATE(I_DATE,'YYYYMMDD'),'YYYY-MM-DD'),
              T1.ORG_NUM  ,
              CASE WHEN T1.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
                   WHEN T1.DEPARTMENTD ='公司金融' OR SUBSTR(T1.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
                   WHEN T1.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
                   WHEN T1.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
                   WHEN SUBSTR(T1.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
                   WHEN SUBSTR(T1.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
                   END AS TX ,
              G.FACILITY_NO AS F020064, -- 授信ID  -- [20250708][姜俐锋][JLBA202504160004][吴大为]：票据部分取授信表
              CASE WHEN T3.MAIN_GUARANTY_TYP = 'A' AND T3.QTDBFS1 IS NULL AND T3.QTDBFS2 IS NULL THEN '01' -- 	质押贷款 
                   WHEN T3.MAIN_GUARANTY_TYP = 'B' AND T3.QTDBFS1 IS NULL AND T3.QTDBFS2 IS NULL THEN '02' -- 	抵押贷款
                   WHEN T3.MAIN_GUARANTY_TYP = 'C' AND T3.QTDBFS1 IS NULL AND T3.QTDBFS2 IS NULL THEN '03' -- 	保证贷款
                   WHEN T3.MAIN_GUARANTY_TYP = 'D' AND T3.QTDBFS1 IS NULL AND T3.QTDBFS2 IS NULL THEN '04' -- 	信用贷款
                   WHEN T3.MAIN_GUARANTY_TYP = 'B' AND T3.QTDBFS1 = 'A'   AND T3.QTDBFS2 IS NULL THEN '05' -- 	抵押+质押+其他
                   WHEN T3.MAIN_GUARANTY_TYP = 'B' AND (T3.QTDBFS1 = 'C' OR  T3.QTDBFS1='00') THEN '06' -- 	抵押+保证（或信用）
                   WHEN T3.MAIN_GUARANTY_TYP = 'A' AND (T3.QTDBFS1 = 'C' OR  T3.QTDBFS1='00') THEN '06' -- 	抵押+保证（或信用）
                   WHEN T3.MAIN_GUARANTY_TYP = 'C' AND  T3.QTDBFS1='00'  THEN '06' -- 	抵押+保证（或信用）
                   ELSE '00'
                    END  AS F020065,
              CASE WHEN T1.ACCT_TYP LIKE '0202%' THEN
                    '01' -- 流动资金贷款
                   WHEN T1.ACCT_TYP LIKE '0801%' THEN
                    '02' -- 法人账户透支
                   WHEN D.ACCT_NUM IS NOT NULL AND T3.SYNDICATEDLOAN_FLG='Y'  THEN  
                    '04' -- 项目贷款（银团）
                   WHEN T1.ACCT_TYP LIKE '0201%' THEN   -- 05，03执行顺序调换 0619_LHY
                    '05' -- 一般固定资产贷款
                   WHEN D.ACCT_NUM IS NOT NULL THEN 
                    '03' -- 项目贷款 
                   WHEN T1.ACCT_TYP = '010101' THEN
                    '07' --  7 住房按揭贷款（非公转商）
                   WHEN T1.ACCT_TYP LIKE '010201' THEN
                    '08' -- 个人经营性商用房贷款
                    --  9 个人消费性商用房贷款
                   WHEN T1.ACCT_TYP LIKE '0104%' THEN
                    '11' -- 助学贷款
                   WHEN (T1.ACCT_TYP LIKE '0102%' AND T1.ACCT_TYP NOT LIKE '010201%') /**OR L.CP_ID = 'GJ0100001000005'**/ THEN   -- 0619 EAST该条数据为其他_个人贷款 LHY
                    '13' -- 个人经营性贷款
                   WHEN T1.ACCT_TYP LIKE '010301%' OR (T1.DEPARTMENTD ='个人信贷' AND T1.GRXFDKYT ='05')  THEN
                    '10' -- 个人汽车贷款
                   -- WHEN T1.ACCT_TYP LIKE '0103%' OR (T1.DEPARTMENTD ='个人信贷' AND T1.ACCT_TYP ='019999' AND L.CP_ID <> 'GJ0100001000005')  THEN -- 线下吉房贷(经营)	GJ0100001000005
                   WHEN T1.ACCT_TYP LIKE '010399%' THEN  -- 0618_LHY
                    '12' -- 个人消费贷款
                   WHEN SUBSTR(T1.ITEM_CD, 1, 6) IN ('130101', '130104') THEN
                    '14' -- 票据贴现
                   WHEN T1.ITEM_CD LIKE '130105%' THEN
                    '15' -- 买断式转贴现
                   WHEN (T1.ACCT_TYP LIKE '04%' OR
                        SUBSTR(T1.ITEM_CD, 1, 6)='130103') -- 20240408 新增范围
                        THEN
                    '16' -- 贸易融资业务
                   WHEN T1.ACCT_TYP LIKE '05%' THEN
                    '17' -- 融资租赁业务
                   WHEN T1.ACCT_TYP LIKE '09%' THEN
                    '18' -- 垫款
                   WHEN T1.ACCT_TYP LIKE '90%' THEN
                    '19' -- 委托贷款
                   WHEN T1.ACCT_TYP = '0399' THEN
                    '20' -- 买断式其他票据类资产
                   WHEN T1.ACCT_TYP LIKE '010302%' THEN
                    '21'  -- 其他-互联网贷款    0618_LHY
                   ELSE
                    '00' -- 其他
                   END AS F020066,  -- 25信贷业务种类 
                   2        
      FROM (SELECT E.ACCT_NUM,
                   E.LOAN_NUM,
                   E.DRAFT_RNG,
                   E.CUST_ID,
                   E.ORG_NUM,
                   E.ACCT_TYP,
                   E.DATE_SOURCESD,
                   E.CURR_CD,
                   SUM(E.DRAWDOWN_AMT) AS DRAWDOWN_AMT,
                   E.DRAWDOWN_DT,
                   E.INT_RATE_TYP,
                   E.BASE_INT_RAT,
                   E.REAL_INT_RAT,
                   E.GUARANTY_TYP,
                   E.ACCT_TYP_DESC,
                   E.EMP_ID,
                   E.FINISH_DT,
                   E.MATURITY_DT,
                   E.ACTUAL_MATURITY_DT,
                   E.ITEM_CD,
                   E.USEOFUNDS,
                   E.DATA_DATE,
                   E.CANCEL_FLG,
                   E.INDEPENDENCE_PAY_AMT,
                   E.ENTRUST_PAY_AMT,
                   E.DRAWDOWN_TYPE,
                   E.GRXFDKYT,
                   E.ACCT_STS,
                   E.DEPARTMENTD,
                   E.LOAN_ACCT_BAL, --  沈祺 20230221 添加 配合WHERE条件将账户状态判断改成余额判断
                   E.OD_INT_OBS, --  沈祺 20230221 添加 配合WHERE条件将账户状态判断改成余额判断
                   E.LOAN_STS,
                   E.JBYG_ID  , -- '经办员工ID',
                   E.DRAFT_NBR  ,  
                   E.SZYG_ID  , -- '审查员工ID',
                   E.SPYG_ID    -- '审批员工ID',
              FROM  V_PUB_IDX_DK_ZQDQRJJ E
             WHERE E.DATA_DATE = I_DATE 
               AND SUBSTR(E.ITEM_CD, 1, 6) IN ('130101', '130102', '130104', '130105') 
               AND (E.ACCT_STS <> '3'
                 OR E.LOAN_ACCT_BAL > 0 
                 OR E.FINISH_DT >= SUBSTR(I_DATE,1,4)||'0101' ) -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
             GROUP BY E.ACCT_NUM,
                      E.LOAN_NUM,
                      E.DRAFT_RNG,
                      E.CUST_ID,
                      E.ORG_NUM,
                      E.DATE_SOURCESD,
                      E.CURR_CD,
                      E.DRAWDOWN_DT,
                      E.REAL_INT_RAT,
                      E.INT_RATE_TYP,
                      E.BASE_INT_RAT,
                      E.GUARANTY_TYP,
                      E.EMP_ID,
                      E.ACCT_TYP_DESC,
                      E.FINISH_DT,
                      E.MATURITY_DT,
                      E.ACCT_TYP,
                      E.ACTUAL_MATURITY_DT,
                      E.ITEM_CD,
                      E.USEOFUNDS,
                      E.DATA_DATE,
                      E.CANCEL_FLG,
                      E.DRAWDOWN_TYPE, -- 放款方式
                      E.ENTRUST_PAY_AMT, -- 受托支付金额
                      E.INDEPENDENCE_PAY_AMT,
                      E.ACCT_STS,
                      E.DEPARTMENTD,
                      E.LOAN_ACCT_BAL, 
                      E.LOAN_STS ,
                      E.GRXFDKYT,
                      E.JBYG_ID  , -- '经办员工ID',
                      E.DRAFT_NBR  , 
                      E.SZYG_ID  , -- '审查员工ID',
                      E.SPYG_ID  ,  -- '审批员工ID',
                      E.OD_INT_OBS  
            ) T1 -- 自主支付余额
      LEFT JOIN VIEW_L_PUBL_ORG_BRA T2
        ON T1.ORG_NUM = T2.ORG_NUM
       AND T2.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T3 -- 贷款合同信息表
        ON T3.DATA_DATE = I_DATE
       AND T1.ACCT_NUM = T3.CONTRACT_NUM
      LEFT JOIN SMTMODS.L_CUST_ALL T5
        ON T1.CUST_ID = T5.CUST_ID
       AND T5.DATA_DATE = I_DATE
      LEFT JOIN (SELECT DISTINCT DATA_DATE, CUST_ID, FINA_ORG_NAME,ECIF_CUST_ID
                   FROM SMTMODS.L_CUST_BILL_TY
                  WHERE DATA_DATE = I_DATE) TY  -- 20250116
        ON T1.CUST_ID = TY.CUST_ID
       AND TY.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_ACCT_PROJECT D -- 项目贷款信息表
        ON T3.CONTRACT_NUM = D.ACCT_NUM
       AND D.DATA_DATE = I_DATE
      LEFT JOIN SMTMODS.L_AGRE_BILL_INFO B -- 商业汇票票面信息表
        ON T1.DRAFT_NBR = B.BILL_NUM
       AND B.DATA_DATE =  I_DATE 
      LEFT JOIN SMTMODS.L_AGRE_CREDITLINE G  -- JLBA202409120001 20241128 新增关联取授信额度 
        ON T1.CUST_ID = G.CUST_ID  
       AND G.DATA_DATE  = I_DATE 
      LEFT JOIN GYH_YSGX_DHCC_TMP T8
        ON T1.EMP_ID = T8.LXTH
       AND T8.LXTHSSJGMC <> '资产保全部' 
     WHERE T1.DATA_DATE = I_DATE
       AND (T1.ACCT_STS <> '3' OR
            T1.LOAN_ACCT_BAL > 0 OR
            T1.FINISH_DT >= SUBSTR(I_DATE,1,4)||'0101' OR -- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求 
            T1.FINISH_DT IS NULL);
      COMMIT ;   
        
        
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


