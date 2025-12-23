DROP Procedure IF EXISTS `PROC_BSP_T_6_18_WTDKXY` ;

DELIMITER $$

CREATE DEFINER="ybt_datacore"@"%" PROCEDURE "PROC_BSP_T_6_18_WTDKXY"(IN I_DATE VARCHAR(8),
                                         OUT OI_RETCODE   INT, -- 返回CODE
                                         OUT OI_REMESSAGE VARCHAR -- 返回MESSAGE
                                         )
BEGIN

  /******
      程序名称  ：表6.18委托贷款协议
      程序功能  ：加工表6.18委托贷款协议
      目标表：T_6_18
      源表  ：
      创建人  ：JLF
      创建日期  ：20240109
      版本号：V0.0.1 
  ******/
	 /*需求编号：JLBA202507090010 上线日期：2025-08-07，修改人：巴启威，提出人：吴大为  修改原因：关于一表通监管数据报送系统调整失效数据保留时间的需求*/
	 /*需求编号：JLBA202507300010 上线日期：2025-09-29，修改人：姜俐锋，提出人：信贷新增产品 修改原因：关于新一代信贷管理系统新增线上微贷板块的需求 */
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
	SET P_PROC_NAME = 'PROC_BSP_T_6_18_WTDKXY';
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
	
	DELETE FROM T_6_18 WHERE F180025 = TO_CHAR(P_DATE,'YYYY-MM-DD') ;
	
	COMMIT;
   														
	CALL PROC_ETL_JOB_LOG(P_DATE,P_PROC_NAME,P_STATUS,P_START_DT,NOW(),P_SQLCDE,P_STATE,P_SQLMSG,P_STEP_NO,P_DESCB);
    
    #3.插入数据
	SET P_START_DT = NOW();
	SET P_STEP_NO = P_STEP_NO + 1;
	SET P_DESCB = '数据插入';
	
 INSERT INTO T_6_18
 (
    F180001   , -- 01 '协议ID' 
	F180002   , -- 02 '机构ID'
	F180003   , -- 03 '委托贷款类型'
	F180004   , -- 04 '委托客户ID'
	F180005   , -- 05 '委托客户账号'
	F180006   , -- 06 '委托客户账号开户行名称'
	F180007   , -- 07 '协议金额'
	F180008   , -- 08 '协议币种'
	F180009   , -- 09 '收息标识'
	F180010   , -- 10 '生效日期'
	F180011   , -- 11 '到期日期'
	F180012   , -- 12 '借据ID'
	F180013   , -- 13 '借款人ID'
	F180014   , -- 14 '借款人名称'
	F180026   , -- 26 '借款人账号'
    F180027   , -- 27 '借款人开户行名称' 
    F180015   , -- 15 '协议状态' 
    F180016   , -- 16 '科目ID' 
    F180017   , -- 17 '科目名称' 
    F180018   , -- 18 '重点产业标识' 
    F180019   , -- 19 '经办员工ID' 
    F180020   , -- 20 '审查员工ID' 
    F180021   , -- 21 '审批员工ID' 
    F180022   , -- 22 '备注' 
    F180023   , -- 23 '手续费币种' 
    F180024   , -- 24 '手续费金额' 
    F180025   , -- 25 '采集日期'	
    DIS_DATA_DATE,
    DIS_BANK_ID,
    DEPARTMENT_ID,
    F180028)
  
  SELECT
      T.ACCT_NUM AS XDHTH , -- 01 '协议ID'
      SUBSTR(TRIM(T1.FIN_LIN_NUM ),1,11)||T.ORG_NUM  AS NBJGH  , -- 02 '机构ID'
      CASE WHEN T2.ENTRUST_LOAN_TYPE = '9011' THEN '01' -- 现金管理项下委托贷款
            WHEN T.ITEM_CD='30200202' THEN '03' -- 公积金贷款
           ELSE '02' -- 一般委托贷款
      END AS WTDKLX       , -- 03 '委托贷款类型'
      T2.TRUSTOR_ID       , -- 04 '委托客户ID'
      T2.ENTRUST_ACCT     , -- 05 '委托客户账号'
      T8.ORG_NAM        , -- 06 '委托客户账号开户行名称'   一表通转EAST 20240617 LMH  /*T2.WTJJKHXMC */ 
      T.DRAWDOWN_AMT      , -- 07 '协议金额'
      T.CURR_CD           , -- 08 '协议币种'
      '0'                 , -- 09 '收息标识'
      TO_CHAR(TO_DATE(T7.CONTRACT_EFF_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 10 '生效日期'
      TO_CHAR(TO_DATE(T.MATURITY_DT,'YYYYMMDD'),'YYYY-MM-DD'), -- 11 '到期日期'
      T.LOAN_NUM          , -- 12 '借据ID'
      T.CUST_ID           , -- 13 '借款人ID'
      T4.CUST_NAM         , -- 14 '借款人名称'
      T.LOAN_ACCT_NUM     , -- 26 '借款人账号'
      T.LOAN_ACCT_BANK    , -- 27 '借款人开户行名称'
      CASE  
           WHEN T.ACCT_STS IN ( '1','2' ) THEN '01' -- '正常'
           WHEN T.ACCT_STS = '3' THEN '04' -- '逾期'
           WHEN T.ACCT_STS = '9' THEN '00' -- '其它' 
      END AS DKZT         , -- 15 '协议状态'
      T.ITEM_CD           , -- 16 '科目ID'
      T9.GL_CD_NAME       , -- 17 '科目名称'
      NVL(T.INDUST_RSTRUCT_FLG,'0') || DECODE(T.INDUST_TRAN_FLG,'1','1','2','0','0') || REPLACE(NVL(T.INDUST_STG_TYPE,'0'),'#','0') , -- 18 '重点产业标识'
      T.EMP_ID            , -- 19 '经办员工ID' [20251028][巴启威][JLBA202509280009][吴大为]: 委托贷款协议无审批流，经办员工取客户经理
      '自动'              , -- 20 '审查员工ID' [20251028][巴启威][JLBA202509280009][吴大为]: 委托贷款协议无审批流，默认自动
      '自动'              , -- 21 '审批员工ID' [20251028][巴启威][JLBA202509280009][吴大为]: 委托贷款协议无审批流，默认自动
      NULL                , -- 22 '备注'
      T2.FEE_CURR_CD      , -- 23 '手续费币种'
      T2.FEE_AMT          , -- 24 '手续费金额'
      TO_CHAR(P_DATE,'YYYY-MM-DD')  , -- 25 '采集日期'           
      TO_CHAR(P_DATE,'YYYY-MM-DD')  , -- 25 '采集日期' 
      T.ORG_NUM,
      CASE  
           WHEN T.DEPARTMENTD ='信用卡' THEN '009803' -- 吉林银行总行卡部(信用卡中心管理)(009803)
           WHEN T.DEPARTMENTD ='公司金融' OR SUBSTR(T.ITEM_CD,1,6) IN ('130601','130602') THEN '0098JR' -- 公司金融部(0098JR)
           WHEN T.DEPARTMENTD ='个人信贷' THEN '0098LDB' -- 零售信贷部(0098LDB)
           WHEN T.DEPARTMENTD ='普惠金融' THEN '0098PH' -- 普惠金融部(0098PH)
           WHEN SUBSTR(T.ITEM_CD,1,6)= '130603' THEN '0098GJ' -- 国际业务（贸易金融）部(0098GJ)
           WHEN SUBSTR(T.ITEM_CD,1,6) IN ('130101','130102','130104','130105','130103') THEN '009804' -- 吉林银行金融市场部(009804)
           END AS TX,
        T7.FACILITY_NO   
  FROM V_PUB_IDX_DK_ZQDQRJJ T -- 贷款借据信息表
  LEFT JOIN VIEW_L_PUBL_ORG_BRA T1  -- 机构表
    ON T.ORG_NUM = T1.ORG_NUM
   AND T1.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_ACCT_LOAN_ENTRUST T2 -- 委托贷款补充信息
    ON T.LOAN_NUM = T2.LOAN_NUM
   AND T2.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_CUST_ALL T3 -- 全量客户信息表
    ON T2.TRUSTOR_ID = T3.CUST_ID
   AND T3.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_CUST_ALL T4 -- 全量客户信息表
    ON T.CUST_ID = T4.CUST_ID
   AND T4.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T6 -- 机构表
    ON T.ORG_NUM = T6.ORG_NUM
   AND T6.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_AGRE_LOAN_CONTRACT T7 -- 贷款合同信息表
    ON T.ACCT_NUM = T7.CONTRACT_NUM
   AND T7.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_PUBL_ORG_BRA T8 -- 机构表   
    ON T7.ORG_NUM = T8.ORG_NUM
   AND T8.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_FINA_INNER T9 -- 内部科目对照表
    ON  T.ITEM_CD = T9.STAT_SUB_NUM
   AND T1.ORG_NUM = T9.ORG_NUM
   AND T9.DATA_DATE = I_DATE
  LEFT JOIN SMTMODS.L_PUBL_RATE U
    ON T.CURR_CD = U.BASIC_CCY
   AND U.DATA_DATE = I_DATE
   AND U.FORWARD_CCY = 'CNY' -- 折人民币
  LEFT JOIN (SELECT DISTINCT
                    LOAN_NUM,
                    WRITE_OFF_DATE -- 核销日期
               FROM SMTMODS.L_ACCT_WRITE_OFF  -- 贷款核销
              WHERE DATA_DATE=I_DATE) T10
   ON T.LOAN_NUM=T10.LOAN_NUM
 WHERE T.ACCT_TYP LIKE '90%'
   AND T.DATA_DATE = I_DATE
    AND NVL(T7.PROD_NAME,'##') NOT IN ('个人遗留贷款无本产品','公司遗留贷款无本产品') -- 剔除无本有息历史数据  
    AND SUBSTR(T.ITEM_CD,1,4) IN ('3010','3020','3030','3040')
	-- [20250807][巴启威][JLBA202507090010][吴大为]: 关于一表通监管数据报送系统调整失效数据保留时间的需求
    AND  ((T.CANCEL_FLG = 'Y' AND SUBSTR(T10.WRITE_OFF_DATE,1,4) = SUBSTR(I_DATE,1,4) )  -- 核销日期在本年
	          OR T.ACCT_STS <> '3'  
              OR T.LOAN_ACCT_BAL > 0   
              OR T.FINISH_DT >= SUBSTR(I_DATE,1,4)||'0101' 
              OR (T.INTERNET_LOAN_FLG = 'Y' AND T.FINISH_DT >= TO_CHAR(TO_DATE((SUBSTR(I_DATE,1,4)||'0101') ,'YYYYMMDD') - 1,'YYYYMMDD'))  -- 互联网贷款数据晚一天下发
              OR (T7.CP_ID='DK001000100041' AND T.FINISH_DT >= TO_CHAR(TO_DATE((SUBSTR(I_DATE,1,4)||'0101') ,'YYYYMMDD') - 1,'YYYYMMDD')) -- [20250929][姜俐锋][JLBA202507300010][信贷新增产品]: 同网贷部分数据处理方式
              ) 
	and (T.LOAN_STOCKEN_DATE is null or T.LOAN_STOCKEN_DATE=I_DATE) ;-- add by haorui 20250311 JLBA202408200012 LOAN_STOCKEN_DATE
          
 COMMIT; 
	
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

